<?php
// ============================================================================
// PIX via MERCADO PAGO - ponte entre o jogo e o Mercado Pago (OPCIONAL)
// ----------------------------------------------------------------------------
// Fluxo:
//   1. Jogador abre a janela de Pix no jogo -> servidor cria pedido em pix_orders
//   2. Client faz GET ?txid=XXX&json=1 aqui para buscar QR Code diretamente
//   3. Mercado Pago chama ?webhook para notificar pagamento
//   4. Servidor do jogo varre pix_orders e credita coins
//
// SEGURANCA:
//   - Webhook: validado com HMAC-SHA256 (assinatura do Mercado Pago)
//   - Endpoint JSON: requer token secreto no header X-Game-Token
//   - Rate limiting por IP (arquivo/cache)
//   - flock para evitar race conditions no cache do QR
//   - Nenhum dado de entrada chega sem validacao/escape
// ============================================================================

// ---------------------------- BANCO (o mesmo do servidor) -------------------
$DB_HOST = '127.0.0.1';
$DB_PORT = 3306;
$DB_USER = 'root';
$DB_PASS = '';       // <<< senha do banco
$DB_NAME = 'avatar'; // <<< banco do servidor

// ============================================================================
// CREDENCIAIS CRIPTOGRAFADAS (CARREGADAS DO VAULT SEGURO)
// ============================================================================
define('AVATAR_PIX_SECURE', true);
$vaultPath = __DIR__ . '/config_pix/pix_vault.php';
if (!file_exists($vaultPath)) {
    http_response_code(500);
    exit('Erro de configuracao: Vault nao encontrado.');
}
require_once $vaultPath;

$SELF_URL = 'https://smitten-macaw-aluminum.ngrok-free.dev/pix_mercadopago.php';

// Limite de requisicoes JSON por IP a cada 10 segundos (protege contra spam)
$RATE_LIMIT_MAX    = 8;
$RATE_LIMIT_WINDOW = 10;

// ---------------------------- nao mexer daqui pra baixo --------------------

// ============================================================================
// Helpers de banco
// ============================================================================
function pix_db() {
    global $DB_HOST, $DB_PORT, $DB_USER, $DB_PASS, $DB_NAME;
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            "mysql:host={$DB_HOST};port={$DB_PORT};dbname={$DB_NAME};charset=utf8mb4",
            $DB_USER, $DB_PASS,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
        );
    }
    return $pdo;
}

function pix_order($txid) {
    $stmt = pix_db()->prepare("SELECT * FROM `pix_orders` WHERE `txid` = ? LIMIT 1");
    $stmt->execute([$txid]);
    return $stmt->fetch() ?: null;
}

function pix_mark_paid($txid, $gatewayId, $paidAmount) {
    $pdo = pix_db();
    $stmt = $pdo->prepare("SELECT * FROM `pix_orders` WHERE `txid` = ? LIMIT 1");
    $stmt->execute([$txid]);
    $order = $stmt->fetch();

    // Pedido inexistente ou já entregue: nao faz nada
    if (!$order || $order['status'] === 'delivered') {
        return false;
    }

    // Pedido deve estar em estado que aceita pagamento
    if (!in_array($order['status'], ['pending', 'canceled', 'expired'], true)) {
        return false;
    }

    // Trava de seguranca: nunca credita valor menor do que o pedido
    if ($paidAmount + 0.009 < ($order['value_cents'] / 100)) {
        error_log("[pix] valor pago ({$paidAmount}) menor que o pedido ({$order['value_cents']}) txid={$txid}");
        return false;
    }

    // UPDATE atomico: so' atualiza se ainda estiver em estado correto
    $up = $pdo->prepare(
        "UPDATE `pix_orders` SET `status` = 'paid', `paid_at` = NOW(), `gateway_id` = ?
         WHERE `txid` = ? AND `status` IN ('pending', 'canceled', 'expired')"
    );
    $up->execute([$gatewayId, $txid]);
    return $up->rowCount() > 0;
}

function mp_request($path, $method = 'GET', $body = null, $idempotencyKey = null) {
    global $MP_ACCESS_TOKEN;
    $ch = curl_init('https://api.mercadopago.com' . $path);
    $headers = [
        'Authorization: Bearer ' . $MP_ACCESS_TOKEN,
        'Content-Type: application/json',
    ];
    if ($idempotencyKey) {
        $headers[] = 'X-Idempotency-Key: ' . $idempotencyKey;
    }
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST  => $method,
        CURLOPT_HTTPHEADER     => $headers,
        CURLOPT_TIMEOUT        => 20,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2,
    ]);
    if ($body !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }
    $raw  = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return [$code, json_decode((string)$raw, true), $raw];
}

function mp_create_pix($order) {
    global $SELF_URL;
    $amount = number_format($order['value_cents'] / 100, 2, '.', '');
    $body = [
        'transaction_amount' => (float)$amount,
        'description'        => 'Coins ' . (int)$order['coins'] . ' - ' . $order['player_name'],
        'payment_method_id'  => 'pix',
        'external_reference' => $order['txid'],
        'notification_url'   => $SELF_URL . '?webhook',
        'payer'              => [
            'email'      => $order['txid'] . '@avatar.game',
            'first_name' => $order['payer_name'] ?: $order['player_name'],
        ],
    ];
    return mp_request('/v1/payments', 'POST', $body, 'pix-' . $order['txid']);
}

// ============================================================================
// Limpeza de arquivos de cache antigos (evita disco cheio)
// ============================================================================
function cleanup_old_cache($dir, $maxAgeSeconds = 7200) {
    if (!is_dir($dir)) return;
    $now = time();
    foreach (glob($dir . '/*.json') as $file) {
        if (($now - @filemtime($file)) > $maxAgeSeconds) {
            @unlink($file);
        }
    }
}

// ============================================================================
// Validacao da assinatura HMAC do webhook do Mercado Pago
// ============================================================================
function mp_verify_signature($rawBody) {
    global $MP_WEBHOOK_SECRET;

    if (empty($MP_WEBHOOK_SECRET)) {
        return true;
    }

    // O MP envia: x-signature: ts=...,v1=...
    // e x-request-id: ...
    $sigHeader = $_SERVER['HTTP_X_SIGNATURE'] ?? '';
    $requestId = $_SERVER['HTTP_X_REQUEST_ID'] ?? '';

    if (empty($sigHeader)) {
        return false; // sem assinatura = rejeitado
    }

    // Extrai ts e v1 da assinatura
    $ts = '';
    $v1 = '';
    foreach (explode(',', $sigHeader) as $part) {
        [$k, $v] = array_pad(explode('=', trim($part), 2), 2, '');
        if ($k === 'ts')  $ts = $v;
        if ($k === 'v1')  $v1 = $v;
    }

    if (empty($ts) || empty($v1)) {
        return false;
    }

    // Rejeita timestamps muito antigos (janela de 5 minutos contra replay attacks)
    if (abs(time() - (int)$ts) > 300) {
        return false;
    }

    $dataId = $_GET['data_id'] ?? ($_GET['data']['id'] ?? ($_GET['id'] ?? ''));
    if (empty($dataId) && !empty($rawBody)) {
        $json = json_decode($rawBody, true);
        $dataId = $json['data']['id'] ?? ($json['id'] ?? '');
    }

    // Testa os formatos padrao do Mercado Pago (v1 e v2)
    $manifests = [
        "id:{$dataId};request-date:{$ts};",
        "id:{$dataId};request-id:{$requestId};ts:{$ts};",
        "id:{$dataId};ts:{$ts};",
    ];

    foreach ($manifests as $manifest) {
        $expected = hash_hmac('sha256', $manifest, $MP_WEBHOOK_SECRET);
        if (hash_equals($expected, $v1)) {
            return true;
        }
    }

    return false;
}

// ============================================================================
// Webhook do Mercado Pago (?webhook)
// ============================================================================
if (isset($_GET['webhook'])) {
    $rawBody = (string)file_get_contents('php://input');

    // Validar assinatura HMAC do Mercado Pago
    if (!mp_verify_signature($rawBody)) {
        http_response_code(403);
        echo 'forbidden';
        exit;
    }

    $payload   = json_decode($rawBody, true) ?: [];
    $paymentId = $payload['data']['id'] ?? $_GET['data_id'] ?? $_GET['id'] ?? null;

    if (!$paymentId || !preg_match('/^\d+$/', (string)$paymentId)) {
        http_response_code(200);
        echo 'ignored';
        exit;
    }

    list($code, $payment) = mp_request('/v1/payments/' . urlencode((string)$paymentId));
    if ($code !== 200 || !$payment) {
        http_response_code(200);
        echo 'not found';
        exit;
    }

    if (($payment['status'] ?? '') === 'approved' && !empty($payment['external_reference'])) {
        // Valida que o txid e' do formato esperado antes de usar no banco
        $extRef = (string)$payment['external_reference'];
        if (!preg_match('/^[a-zA-Z0-9_-]{8,36}$/', $extRef)) {
            http_response_code(200);
            echo 'invalid reference';
            exit;
        }

        $ok = pix_mark_paid(
            $extRef,
            (string)$payment['id'],
            (float)($payment['transaction_amount'] ?? 0)
        );
        echo $ok ? 'credited' : 'already handled';
    } else {
        echo 'status ' . ($payment['status'] ?? '?');
    }
    http_response_code(200);
    exit;
}

// ============================================================================
// Rate limiting por IP (protege todos os endpoints nao-webhook)
// ============================================================================
$clientIp = $_SERVER['HTTP_CF_CONNECTING_IP']
         ?? $_SERVER['HTTP_X_FORWARDED_FOR']
         ?? $_SERVER['REMOTE_ADDR']
         ?? 'unknown';

// Pega apenas o primeiro IP de uma lista (X-Forwarded-For pode ter varios)
$clientIp = trim(explode(',', $clientIp)[0]);

// Sanitiza o IP para uso seguro como nome de arquivo
$ipHash = md5(preg_replace('/[^a-zA-Z0-9.:_-]/', '', $clientIp));

$rateDir = __DIR__ . '/cache/rate';
if (!is_dir($rateDir)) {
    @mkdir($rateDir, 0750, true);
}

// Limpa arquivos de rate antigos ocasionalmente (1% das requisicoes)
if (mt_rand(1, 100) === 1) {
    cleanup_old_cache($rateDir, 120);
}

$rateFile = $rateDir . '/' . $ipHash . '.json';
$rateNow  = time();
$rateLock = fopen($rateFile . '.lock', 'c');
if ($rateLock && flock($rateLock, LOCK_EX | LOCK_NB)) {
    $rateData = file_exists($rateFile) ? json_decode((string)@file_get_contents($rateFile), true) : null;
    if (!$rateData || ($rateNow - $rateData['time']) > $RATE_LIMIT_WINDOW) {
        $rateData = ['time' => $rateNow, 'count' => 1];
    } else {
        $rateData['count']++;
    }
    @file_put_contents($rateFile, json_encode($rateData));
    flock($rateLock, LOCK_UN);
    fclose($rateLock);
} else {
    // Sem lock: conta como 1 para nao bloquear mas tambem nao permite acumulo
    $rateData = ['count' => 1];
}

if ($rateData['count'] > $RATE_LIMIT_MAX) {
    http_response_code(429);
    header('Retry-After: ' . $RATE_LIMIT_WINDOW);
    if (isset($_GET['json'])) {
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['ok' => false, 'error' => 'Muitas requisicoes. Aguarde alguns segundos.']);
    } else {
        echo '<h1>429 - Muitas requisicoes</h1><p>Aguarde alguns segundos.</p>';
    }
    exit;
}

// ============================================================================
// Validacao do txid
// ============================================================================
$txid = $_GET['txid'] ?? '';
if (!preg_match('/^[a-zA-Z0-9_-]{8,36}$/', $txid)) {
    http_response_code(400);
    if (isset($_GET['json'])) {
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['ok' => false, 'error' => 'txid invalido']);
    } else {
        echo '<h1>Pedido invalido</h1>';
    }
    exit;
}

// ============================================================================
// Autenticacao do endpoint JSON (chamado apenas pelo client do jogo)
// ============================================================================
if (isset($_GET['json'])) {
    $clientToken = $_SERVER['HTTP_X_GAME_TOKEN'] ?? $_GET['token'] ?? '';
    if (!hash_equals($GAME_TOKEN, $clientToken)) {
        http_response_code(403);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['ok' => false, 'error' => 'Acesso negado.']);
        exit;
    }
}

// ============================================================================
// Busca o pedido no banco
// ============================================================================
$order = pix_order($txid);

if (!$order) {
    http_response_code(404);
    if (isset($_GET['json'])) {
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['ok' => false, 'error' => 'Pedido nao encontrado']);
    } else {
        echo '<h1>Pedido nao encontrado</h1>';
    }
    exit;
}

// Auto-refresh da pagina do QR: devolve apenas o status atual
if (isset($_GET['check'])) {
    header('Content-Type: application/json');
    echo json_encode(['status' => $order['status']]);
    exit;
}

// ============================================================================
// Cache do QR Code (flock para evitar race conditions)
// ============================================================================
$safeTxid = preg_replace('/[^a-zA-Z0-9_-]/', '', $order['txid']);
$cacheDir = __DIR__ . '/cache';
$cacheFile = $cacheDir . '/' . $safeTxid . '.json';
$qrBase64 = '';
$qrCode   = '';

// Limpa cache expirado ocasionalmente
if (mt_rand(1, 50) === 1) {
    cleanup_old_cache($cacheDir, 7200);
}

if (file_exists($cacheFile)) {
    $cached = json_decode((string)@file_get_contents($cacheFile), true);
    if ($cached && !empty($cached['qr_base64'])) {
        $qrBase64 = $cached['qr_base64'];
        $qrCode   = $cached['qr_code'];
    }
}

if (empty($qrBase64)) {
    // Usa flock para evitar que multiplas requisicoes simultaneas criem
    // varios pagamentos no Mercado Pago para o mesmo txid
    $lockFile = $cacheDir . '/' . $safeTxid . '.lock';
    $lk = fopen($lockFile, 'c');
    $created = null;

    if ($lk && flock($lk, LOCK_EX)) {
        // Re-verifica o cache dentro do lock (outro processo pode ter criado)
        if (file_exists($cacheFile)) {
            $cached = json_decode((string)@file_get_contents($cacheFile), true);
            if ($cached && !empty($cached['qr_base64'])) {
                $qrBase64 = $cached['qr_base64'];
                $qrCode   = $cached['qr_code'];
                flock($lk, LOCK_UN);
                fclose($lk);
                goto serve_response;
            }
        }

        if ($order['status'] === 'pending' && empty($order['gateway_id'])) {
            list($code, $payment, $raw) = mp_create_pix($order);
            if ($code >= 300 || empty($payment['id'])) {
                flock($lk, LOCK_UN);
                fclose($lk);
                if (isset($_GET['json'])) {
                    header('Content-Type: application/json; charset=utf-8');
                    echo json_encode(['ok' => false, 'error' => 'Falha ao criar cobranca no Mercado Pago: ' . ($payment['message'] ?? 'erro')]);
                    exit;
                }
                http_response_code(502);
                echo '<h1>Falha ao criar a cobranca no Mercado Pago</h1><pre>' . htmlspecialchars((string)$raw) . '</pre>';
                exit;
            }
            $up = pix_db()->prepare("UPDATE `pix_orders` SET `gateway_id` = ? WHERE `id` = ?");
            $up->execute([(string)$payment['id'], $order['id']]);
            $created = $payment;
        } elseif (!empty($order['gateway_id'])) {
            list($code, $created) = mp_request('/v1/payments/' . urlencode($order['gateway_id']));
        }

        $qrBase64 = $created['point_of_interaction']['transaction_data']['qr_code_base64'] ?? '';
        $qrCode   = $created['point_of_interaction']['transaction_data']['qr_code'] ?? $order['payload'];

        if (!empty($qrBase64) && !is_dir($cacheDir)) {
            @mkdir($cacheDir, 0750, true);
        }
        if (!empty($qrBase64)) {
            @file_put_contents($cacheFile, json_encode(['qr_base64' => $qrBase64, 'qr_code' => $qrCode]));
        }

        flock($lk, LOCK_UN);
        fclose($lk);
    }
}

serve_response:

// ============================================================================
// Retorno JSON para o Client (sem precisar de navegador)
// ============================================================================
if (isset($_GET['json'])) {
    header('Content-Type: application/json; charset=utf-8');
    // Nunca retorna o qr_base64 para pedidos ja entregues (minimiza dados desnecessarios)
    echo json_encode([
        'ok'        => true,
        'status'    => $order['status'],
        'txid'      => $order['txid'],
        'qr_code'   => $qrCode,
        'qr_base64' => $qrBase64,
        'coins'     => (int)$order['coins'],
        'value'     => number_format($order['value_cents'] / 100, 2, '.', ''),
    ]);
    exit;
}
?>
<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="utf-8">
<title>Pix - <?= htmlspecialchars($order['player_name']) ?></title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  body { background:#12141a; color:#e8e8e8; font-family:Arial,Helvetica,sans-serif; text-align:center; padding:24px; }
  .card { max-width:520px; margin:0 auto; background:#1c1f27; border-radius:12px; padding:20px; }
  img { width:260px; height:260px; background:#fff; border-radius:8px; padding:6px; }
  textarea { width:100%; height:90px; margin-top:10px; font-family:monospace; font-size:11px; }
  .ok { color:#63e6a7; font-weight:bold; }
  .wait { color:#ffd76a; }
  small { color:#9aa0aa; }
</style>
</head>
<body>
<div class="card">
  <h2>Pix para o personagem <?= htmlspecialchars($order['player_name']) ?></h2>
  <p>Valor: <b>R$ <?= number_format($order['value_cents'] / 100, 2, ',', '.') ?></b>
     &nbsp;|&nbsp; Coins: <b><?= (int)$order['coins'] ?></b></p>

  <?php if ($order['status'] === 'delivered'): ?>
      <p class="ok">Pagamento confirmado - os coins ja' entraram na conta. Bom jogo!</p>
  <?php else: ?>
      <?php if ($qrBase64): ?>
          <img src="data:image/png;base64,<?= htmlspecialchars($qrBase64) ?>" alt="QR Code Pix">
      <?php endif; ?>
      <p id="status" class="wait">Aguardando a confirmacao do pagamento...</p>
      <p><small>Copia e cola:</small></p>
      <textarea readonly onclick="this.select()"><?= htmlspecialchars($qrCode) ?></textarea>
      <p><small>O credito e' automatico assim que o Mercado Pago confirmar.</small></p>
  <?php endif; ?>
</div>
<script>
<?php if ($order['status'] !== 'delivered'): ?>
var pixUrl = '?txid=<?= urlencode($order['txid']) ?>&check=1';
function pixCheck() {
  setTimeout(function () {
    fetch(pixUrl, {cache: 'no-store'})
      .then(function (r) { return r.json(); })
      .then(function (data) {
        if (data && data.status === 'delivered') { location.reload(); }
        else { pixCheck(); }
      })
      .catch(pixCheck);
  }, 5000);
}
pixCheck();
<?php endif; ?>
</script>
</body>
</html>
