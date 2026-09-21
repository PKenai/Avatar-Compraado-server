-- ============================================================================
-- PIX (Buy Coins / doacao) - LADO SERVIDOR
-- ----------------------------------------------------------------------------
-- Protocolo: extended opcode 120 + JSON, falado com o modulo do client
-- modules/game_pix (o botao "Buy Coins" da loja nova tambem abre ele).
--
-- INSTALACAO (ja feita neste datapack):
--   1. data/creaturescripts/creaturescripts.xml:
--        <event type="extendedopcode" name="GamePixExtended" event="script"
--               value="game_pix.lua"/>
--   2. data/creaturescripts/scripts/loginLogout/login.lua (onLogin):
--        registerCreatureEvent(cid, "GamePixExtended")
--   3. data/talkactions/talkactions.xml (comandos da staff):
--        <talkaction log="yes" words="!pixconfirm" access="5" event="script" value="pixAdmin.lua"/>
--        <talkaction log="yes" words="!pixpending" access="5" event="script" value="pixAdmin.lua"/>
--   4. Banco: rodar Controles de uso/MARKET/pix_orders.sql (cria a tabela).
--   5. Client: modules/game_pix + data/images/topbuttons/pix_icon.png
--
-- COMO FUNCIONA
--   O SERVIDOR e' a fonte da verdade: ele cria o pedido (tabela pix_orders),
--   calcula os coins pelo valor, gera o codigo PIX e so' credita os pontos
--   quando o pedido estiver com status 'paid'. O client so' mostra o codigo,
--   copia para a area de transferencia e pergunta o status de tempo em tempo -
--   ele nao pode "afirmar" que pagou.
--
--   O pagamento pode ser confirmado de tres formas:
--     a) staff: !pixconfirm <txid> <valor recebido>   (util sem gateway)
--     b) SQL:   UPDATE pix_orders SET status='paid' WHERE txid='...';
--     c) gateway (Mercado Pago) -> webhook do pix_mercadopago.php marca 'paid'
--   Nos tres casos quem credita e' a varredura deste script (a cada 20s), que
--   tambem avisa na hora quem estiver online.
--
-- SEGURANCA (o que o jogador NAO consegue fazer)
--   * Creditos so' saem de pedido com status 'paid' NO BANCO. Nenhuma mensagem
--     do client muda status: quem marca 'paid' e' o webhook do gateway (com o
--     valor conferido), o !pixconfirm da staff (access 5) ou um UPDATE no SQL.
--   * O valor da cobranca e' sempre o do pedido gravado no banco - o client
--     nao pode pagar menos e receber coins de um valor maior (o webhook compara
--     transaction_amount com value_cents antes de marcar como pago).
--   * 'check' e 'cancel' so' funcionam no txid da propria conta (sem espiar
--     saldo de terceiros) e 'check' tem limite de 1 a cada 3s.
--   * 'create' tem limite de tempo e de pedidos abertos (anti-spam de banco:
--     quem mandar pacote na mao tambem entra nesse limite).
--
-- O que AINDA depende de voce: no modo local (sem gateway) o QR e' um Pix
-- estatico - o banco nao amarra o txid ao pagamento. Entao, antes do
-- !pixconfirm, confira no extrato que o valor que chegou bate com o valor que
-- o !pixpending mostra. Com gateway configurado isso deixa de ser manual.
--
-- ============================================================================
-- COLOQUE A API DO MERCADO PAGO AQUI
-- ----------------------------------------------------------------------------
-- Este engine NAO tem cliente HTTP em Lua (nao existe HTTP.post, io.popen nem
-- curl exposto), entao quem fala com o Mercado Pago e' o arquivo
--     Controles de uso/MARKET/pix_mercadopago.php
-- hospedado junto do seu site. Aqui voce so' aponta para ele:
--
--     PIX_GATEWAY_URL = "https://SEUSITE.com/pix_mercadopago.php"
--
-- O access token do Mercado Pago (o "COLOQUE A API DO MERCADO PAGO AQUI" de
-- verdade) fica dentro do pix_mercadopago.php, junto com o token do webhook.
-- Enquanto PIX_GATEWAY_URL estiver vazio, o servidor gera o proprio BR Code
-- (copia e cola) com a chave PIX abaixo e a confirmacao fica no !pixconfirm,
-- direto no SQL (UPDATE... status='paid') ou no webhook do gateway.
-- ============================================================================

local CODE_GAMEPIX = 120 -- 103 e' da pesca (opcode.lua): nao reaproveitar

-- ----------------------------------------------------------------------------
-- Configuracao do recebedor (chave estatica PIX)
-- ----------------------------------------------------------------------------
local PIX_KEY = "COLOQUE-SUA-CHAVE-PIX-AQUI" -- CPF/CNPJ (so digitos), e-mail, telefone (+55...) ou chave aleatoria
local PIX_RECEIVER_NAME = "AVATAR"           -- campo 59 do BR Code (max 25, sem acento)
local PIX_CITY = "SAO PAULO"                 -- campo 60 do BR Code (max 15, sem acento)

local PIX_GATEWAY_URL = "https://smitten-macaw-aluminum.ngrok-free.dev/pix_mercadopago.php"
-- Token secreto compartilhado com o pix_mercadopago.php ($GAME_TOKEN).
-- O client manda este token no header X-Game-Token ao buscar o QR.
-- Deve ser identico ao $GAME_TOKEN do PHP.
local PIX_JSON_TOKEN = "avatar-pix-2026"

-- ----------------------------------------------------------------------------
-- Configuracao da conversao valor -> coins
-- ----------------------------------------------------------------------------
local COINS_PER_REAL = 1  -- R$ 1,00 = 1 coin
local MIN_VALUE = 0.10    -- valor minimo de uma doacao, em reais
local MAX_VALUE = 2000    -- trava de seguranca

-- Bonus por faixa de valor. Hoje todas as faixas sao 1.0 (nenhum bonus, igual
-- ao applyBonus do modulo antigo). Para dar bonus, troque os numeros - o valor
-- doado continua o mesmo, muda so' quantos coins entram.
--   exemplo: 100 -> 1.10  = 10% a mais a partir de R$ 100
local BONUS_BY_VALUE = {
    [5] = 1.0,
    [100] = 1.0,
    [200] = 1.0,
    [300] = 1.0,
    [500] = 1.0,
}

local ORDER_EXPIRATION_MINUTES = 30 -- depois disso o pedido pendente expira
local POLL_INTERVAL = 20 * 1000     -- varredura de pagamentos confirmados
local CHECK_MIN_INTERVAL = 3        -- anti-flood do action "check" (segundos)
local CREATE_MIN_INTERVAL = 10      -- anti-flood do action "create" (segundos)
-- 1 = uma conta nunca tem dois Pix abertos ao mesmo tempo: evita encher a
-- tabela e evita o jogador pedir pra confirmar 2 pedidos com UM pagamento so'.
local MAX_PENDING_PER_ACCOUNT = 1

-- Anti-flood de opcode: max N pacotes por segundo por conexao (cid)
-- Evita que alguem mande pacotes fabricados em loop apos se logar.
local OPCODE_MAX_PER_SECOND = 3

-- Tamanho maximo do buffer JSON aceito pelo servidor (em bytes).
-- Evita ataques de payload gigante.
local MAX_BUFFER_BYTES = 512

local GATEWAY_ONLINE = PIX_GATEWAY_URL ~= ""

local pollEvent = nil
local lastCheck = {}
local lastCreate = {}
local lastCreateIp = {}
local opcodeFlood = {} -- [cid] = { count, reset }
local waitingOrders = {} -- [accountId] = txid (ultimo pedido pedido por aquele login)

-- ============================================================================
-- Helpers
-- ============================================================================
local function resultNumber(resultId, column)
    if result.getNumber then
        return result.getNumber(resultId, column)
    end
    return result.getDataInt(resultId, column)
end

local function resultString(resultId, column)
    if result.getString then
        return result.getString(resultId, column)
    end
    return result.getDataString(resultId, column)
end

local function freeResult(resultId)
    if result.free then
        return result.free(resultId)
    end
    return result.freeResult(resultId)
end

local function storeQuery(query)
    if db.storeQuery then
        return db.storeQuery(query)
    end
    return db.getResult(query)
end

local function send(cid, payload)
    local ok, encoded = pcall(json.encode, payload)
    if not ok then
        print("[Pix] falha ao serializar resposta:", encoded)
        return
    end
    doSendPlayerExtendedOpcode(cid, CODE_GAMEPIX, encoded)
end

local function fail(cid, message)
    send(cid, { action = "pix", stage = "error", message = message })
end

local function getPoints(accountId)
    local resultId = storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. accountId)
    if not resultId then
        return 0
    end
    local points = resultNumber(resultId, "premium_points") or 0
    freeResult(resultId)
    return points
end

local function formatValue(cents)
    return string.format("%.2f", cents / 100)
end

local function coinsFor(valueInReais)
    local multiplier = 1.0
    for minimum, bonus in pairs(BONUS_BY_VALUE) do
        if valueInReais >= minimum and bonus > multiplier then
            multiplier = bonus
        end
    end
    return math.max(1, math.floor(valueInReais * COINS_PER_REAL * multiplier))
end

-- ============================================================================
-- BR Code (PIX copia e cola) - EMV QRCPS-MPM
-- ============================================================================
local function stripAccents(text)
    -- deixamos apenas o que o BR Code aceita: ASCII imprimivel, sem acento
    local replacements = {
        ["Á"] = "A", ["À"] = "A", ["Â"] = "A", ["Ã"] = "A", ["Ä"] = "A",
        ["É"] = "E", ["È"] = "E", ["Ê"] = "E", ["Ë"] = "E",
        ["Í"] = "I", ["Ì"] = "I", ["Î"] = "I", ["Ï"] = "I",
        ["Ó"] = "O", ["Ò"] = "O", ["Ô"] = "O", ["Õ"] = "O", ["Ö"] = "O",
        ["Ú"] = "U", ["Ù"] = "U", ["Û"] = "U", ["Ü"] = "U",
        ["Ç"] = "C", ["Ñ"] = "N",
        ["á"] = "A", ["à"] = "A", ["â"] = "A", ["ã"] = "A", ["ä"] = "A",
        ["é"] = "E", ["è"] = "E", ["ê"] = "E", ["ë"] = "E",
        ["í"] = "I", ["ì"] = "I", ["î"] = "I", ["ï"] = "I",
        ["ó"] = "O", ["ò"] = "O", ["ô"] = "O", ["õ"] = "O", ["ö"] = "O",
        ["ú"] = "U", ["ù"] = "U", ["û"] = "U", ["ü"] = "U",
        ["ç"] = "C", ["ñ"] = "N",
    }

    text = text:gsub("[%z\1-\127\194-\244][\128-\191]*", function(char)
        return replacements[char] or char
    end)
    text = text:gsub("[^%w ]", "")
    return text:upper()
end

local function emvField(id, value)
    return id .. string.format("%02d", #value) .. value
end

local function crc16(payload)
    local crc = 0xFFFF
    for i = 1, #payload do
        crc = bit.bxor(crc, string.byte(payload, i) * 256)
        for _ = 1, 8 do
            if bit.band(crc, 0x8000) ~= 0 then
                crc = bit.band(bit.bxor(bit.lshift(crc, 1), 0x1021), 0xFFFF)
            else
                crc = bit.band(bit.lshift(crc, 1), 0xFFFF)
            end
        end
    end
    return string.format("%04X", crc)
end

local function buildPixPayload(amountCents, txid)
    local key = PIX_KEY
    local gui = emvField("00", "br.gov.bcb.pix") .. emvField("01", key)
    local amount = formatValue(amountCents)

    local payload = emvField("00", "01")
        .. emvField("26", gui)
        .. emvField("52", "0000")
        .. emvField("53", "986")
        .. emvField("54", amount)
        .. emvField("58", "BR")
        .. emvField("59", stripAccents(PIX_RECEIVER_NAME):sub(1, 25))
        .. emvField("60", stripAccents(PIX_CITY):sub(1, 15))
        .. emvField("62", emvField("05", txid))

    return payload .. "6304" .. crc16(payload .. "6304")
end

-- ============================================================================
-- Pedidos (tabela pix_orders)
-- ============================================================================
local function getOrder(txid)
    local resultId = storeQuery(
        "SELECT * FROM `pix_orders` WHERE `txid` = " .. db.escapeString(txid) .. " LIMIT 1"
    )
    if not resultId then
        return nil
    end

    local order = {
        txid = resultString(resultId, "txid"),
        account_id = resultNumber(resultId, "account_id"),
        player_id = resultNumber(resultId, "player_id"),
        player_name = resultString(resultId, "player_name"),
        payer_name = resultString(resultId, "payer_name"),
        value_cents = resultNumber(resultId, "value_cents"),
        coins = resultNumber(resultId, "coins"),
        status = resultString(resultId, "status"),
        payload = resultString(resultId, "payload"),
        gateway_id = resultString(resultId, "gateway_id"),
    }
    freeResult(resultId)
    return order
end

local function newTxid(cid)
    -- EMV aceita ate 25 caracteres alfanumericos no campo 62-05.
    -- O sufixo aleatorio evita colisao de dois pedidos no mesmo segundo (a
    -- coluna txid e' UNIQUE: sem isso o segundo INSERT falharia e o jogador
    -- receberia o codigo do pedido anterior).
    for _ = 1, 5 do
        local txid = string.format("PIX%d%d%d", getPlayerGUID(cid), os.time(), math.random(10, 99)):sub(1, 25)
        if not getOrder(txid) then
            return txid
        end
    end

    return string.format("PIX%d%d%d", getPlayerGUID(cid), os.time(), math.random(1000, 9999)):sub(1, 25)
end

local function countPendingOrders(accountId)
    local resultId = storeQuery(
        "SELECT COUNT(*) AS `total` FROM `pix_orders` WHERE `account_id` = " .. accountId ..
        " AND `status` = 'pending'"
    )
    if not resultId then
        return 0
    end

    local total = resultNumber(resultId, "total") or 0
    freeResult(resultId)
    return total
end

local function createOrder(cid, payerName, valueInReais)
    local accountId = getPlayerAccountId(cid)
    local valueCents = math.floor(valueInReais * 100 + 0.5)
    local coins = coinsFor(valueInReais)
    local txid = newTxid(cid)
    local payload = buildPixPayload(valueCents, txid)

    -- teto de pedidos abertos: cancela os mais antigos pra conta nao acumular
    local open = countPendingOrders(accountId)
    if open >= MAX_PENDING_PER_ACCOUNT then
        db.query("UPDATE `pix_orders` SET `status` = 'canceled' WHERE `account_id` = " .. accountId ..
            " AND `status` = 'pending' ORDER BY `id` ASC LIMIT " .. (open - MAX_PENDING_PER_ACCOUNT + 1))
    end

    db.query(string.format(
        "INSERT INTO `pix_orders` (`txid`, `account_id`, `player_id`, `player_name`, `payer_name`, " ..
        "`value_cents`, `coins`, `payload`, `status`, `created`) VALUES ('%s', %d, %d, %s, %s, %d, %d, %s, 'pending', NOW())",
        txid,
        accountId,
        getPlayerGUID(cid),
        db.escapeString(getCreatureName(cid)),
        db.escapeString(payerName),
        valueCents,
        coins,
        db.escapeString(payload)
    ))

    -- confere se o pedido entrou mesmo (tabela pix_orders criada?)
    if not getOrder(txid) then
        print("[Pix] ERRO: nao consegui gravar em pix_orders. Rode " ..
            "Controles de uso/MARKET/pix_orders.sql no banco do servidor.")
        return nil
    end

    waitingOrders[accountId] = txid

    return {
        txid = txid,
        value_cents = valueCents,
        coins = coins,
        payload = payload,
        canceledPrevious = open > 0,
    }
end

local function creditOrder(order, source)
    -- Dupla checagem antes de somar pontos:
    --   antes  -> tem que estar 'paid' (se ja' estiver 'delivered', nao credita
    --            de novo: e' o caso de dois callers pedindo ao mesmo tempo);
    --   depois -> tem que ter virado 'delivered' (a linha que a gente mudou).
    local before = getOrder(order.txid)
    if not before or before.status ~= "paid" then
        return false
    end

    db.query(string.format(
        "UPDATE `pix_orders` SET `status` = 'delivered', `paid_at` = IFNULL(`paid_at`, NOW()) " ..
        "WHERE `txid` = '%s' AND `status` = 'paid'", order.txid
    ))

    local check = getOrder(order.txid)
    if not check or check.status ~= "delivered" then
        return false
    end

    db.query("UPDATE `accounts` SET `premium_points` = `premium_points` + " .. order.coins ..
        " WHERE `id` = " .. order.account_id)

    print(string.format(
        "[Pix] %s: %s (+%d coins, R$ %s) - conta %d, pedido %s",
        source or "confirmado", order.player_name or "?", order.coins,
        formatValue(order.value_cents), order.account_id, order.txid
    ))

    -- avisa quem estiver online nessa conta (o saldo aparece na hora)
    local points = getPoints(order.account_id)
    for _, pid in ipairs(getPlayersOnline()) do
        if getPlayerAccountId(pid) == order.account_id then
            send(pid, {
                action = "pix",
                stage = "paid",
                txid = order.txid,
                coins = order.coins,
                points = points,
            })
            doPlayerSendTextMessage(pid, MESSAGE_EVENT_ADVANCE,
                string.format("Pagamento Pix confirmado! +%d coins (saldo: %d).", order.coins, points))
        end
    end

    return true
end

-- Exportado tambem para o !pixconfirm (data/talkactions/scripts/pixAdmin.lua).
-- `receivedValue` e' o valor que a staff viu chegar no extrato: se vier
-- preenchido e nao bater com o pedido, nada e' creditado.
function gamePixMarkPaid(txid, receivedValue)
    local order = getOrder(txid)
    if not order then
        return false, "pedido nao encontrado"
    end

    if receivedValue ~= nil and receivedValue ~= "" then
        local received = tonumber(receivedValue)
        local expected = order.value_cents / 100
        if not received then
            return false, "valor recebido invalido"
        end
        if math.abs(received - expected) > 0.009 then
            return false, string.format("o valor informado (R$ %.2f) nao bate com o pedido %s (R$ %.2f)",
                received, order.txid, expected)
        end
    end

    if order.status == "delivered" then
        return false, "pedido ja' foi creditado"
    end

    if order.status == "pending" then
        db.query("UPDATE `pix_orders` SET `status` = 'paid', `paid_at` = NOW() WHERE `txid` = '" ..
            order.txid .. "' AND `status` = 'pending'")
    end

    order = getOrder(txid)
    if not creditOrder(order, "staff") then
        return false, "nao foi possivel creditar"
    end

    return true, order
end

function gamePixPendingOrders()
    local list = {}
    local resultId = storeQuery(
        "SELECT `txid`, `player_name`, `value_cents`, `coins`, `created`, " ..
        "TIMESTAMPDIFF(MINUTE, `created`, NOW()) AS `age` FROM `pix_orders` " ..
        "WHERE `status` = 'pending' ORDER BY `id` ASC LIMIT 20"
    )
    if not resultId then
        return list
    end

    repeat
        list[#list + 1] = {
            txid = resultString(resultId, "txid"),
            player_name = resultString(resultId, "player_name"),
            value = formatValue(resultNumber(resultId, "value_cents") or 0),
            coins = resultNumber(resultId, "coins") or 0,
            age = resultNumber(resultId, "age") or 0,
        }
    until not result.next(resultId)

    freeResult(resultId)
    return list
end

-- ============================================================================
-- Varredura: credita o que o gateway/staff marcou como pago
-- ============================================================================
local function scanPaidOrders()
    local resultId = storeQuery(
        "SELECT `txid` FROM `pix_orders` WHERE `status` = 'paid' ORDER BY `id` ASC LIMIT 50"
    )
    if resultId then
        local pending = {}
        repeat
            pending[#pending + 1] = resultString(resultId, "txid")
        until not result.next(resultId)
        freeResult(resultId)

        for _, txid in ipairs(pending) do
            local order = getOrder(txid)
            if order then
                creditOrder(order, "gateway")
            end
        end
    end

    db.query(string.format(
        "UPDATE `pix_orders` SET `status` = 'expired' WHERE `status` = 'pending' " ..
        "AND `created` < DATE_SUB(NOW(), INTERVAL %d MINUTE)", ORDER_EXPIRATION_MINUTES
    ))

    pollEvent = addEvent(scanPaidOrders, POLL_INTERVAL)
end

local function startPoller()
    if pollEvent then
        return
    end
    pollEvent = addEvent(scanPaidOrders, POLL_INTERVAL)
end

-- Limpeza periodica de tabelas em memoria para evitar memory leak em
-- servidores que rodam por muitos dias sem reiniciar.
local function cleanupMemory()
    local now = os.time()
    -- Remove entradas de IP cuja janela ja expirou
    for ip, data in pairs(lastCreateIp) do
        if now > data.reset then
            lastCreateIp[ip] = nil
        end
    end
    -- Remove entradas de check de jogadores offline
    for cid, ts in pairs(lastCheck) do
        if now - ts > 120 then
            lastCheck[cid] = nil
        end
    end
    -- Remove entradas de flood de opcode de jogadores offline
    for cid, data in pairs(opcodeFlood) do
        if now > data.reset + 5 then
            opcodeFlood[cid] = nil
        end
    end
    addEvent(cleanupMemory, 5 * 60 * 1000) -- repete a cada 5 minutos
end
addEvent(cleanupMemory, 5 * 60 * 1000)

-- ============================================================================
-- Acoes do client
-- ============================================================================
local function actionCreate(cid, data)
    local gateway = GATEWAY_ONLINE

    local payerName = ""
    if type(data) == "table" then
        payerName = tostring(data.name or "") .. " " .. tostring(data.lastname or "")
    end
    -- Normaliza espacos e remove caracteres suspeitos (apenas letras, espacos e hifens)
    payerName = payerName:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    payerName = payerName:gsub("[^%a%s%-]", "") -- remove digitos e simbolos
    if payerName == "" or #payerName < 4 or #payerName > 60 then
        return fail(cid, "Digite um nome e sobrenome validos (apenas letras, sem numeros).")
    end
    -- Rejeita payerName com menos de 2 palavras (precisa de nome + sobrenome)
    local wordCount = 0
    for _ in payerName:gmatch("%S+") do
        wordCount = wordCount + 1
    end
    if wordCount < 2 then
        return fail(cid, "Informe o nome E o sobrenome.")
    end

    -- anti-spam: cada conta so' gera um pedido a cada CREATE_MIN_INTERVAL s
    local accountId = getPlayerAccountId(cid)
    local now = os.time()
    if lastCreate[accountId] and now - lastCreate[accountId] < CREATE_MIN_INTERVAL then
        return fail(cid, string.format("Aguarde %d segundos para gerar outro Pix.",
            CREATE_MIN_INTERVAL - (now - lastCreate[accountId])))
    end

    -- anti-spam por IP: maximo 4 pedidos a cada 60 segundos por conexao/IP
    local playerIp = tostring(getPlayerIp(cid) or 0)
    if not lastCreateIp[playerIp] or now > lastCreateIp[playerIp].reset then
        lastCreateIp[playerIp] = { count = 1, reset = now + 60 }
    else
        lastCreateIp[playerIp].count = lastCreateIp[playerIp].count + 1
        if lastCreateIp[playerIp].count > 4 then
            return fail(cid, "Muitas tentativas de doacao a partir do mesmo IP. Aguarde 1 minuto.")
        end
    end

    local value = tonumber(data and data.value)
    if not value or value ~= value or value <= 0 then
        return fail(cid, "Informe um valor valido para a doacao.")
    end

    -- Arredonda para 2 casas decimais (evita problemas de ponto flutuante)
    value = math.floor(value * 100 + 0.5) / 100

    if value < MIN_VALUE then
        return fail(cid, string.format("O valor minimo e' R$ %.2f.", MIN_VALUE))
    end

    if value > MAX_VALUE then
        return fail(cid, string.format("O valor maximo e' R$ %d. Fale com a administracao.", MAX_VALUE))
    end

    local order = createOrder(cid, payerName, value)
    if not order then
        return fail(cid, "Nao foi possivel criar o pedido agora. Tente novamente ou fale com a administracao.")
    end

    lastCreate[accountId] = now

    send(cid, {
        action = "pix",
        stage = "charge",
        txid = order.txid,
        payload = order.payload,
        value = formatValue(order.value_cents),
        coins = order.coins,
        canceledPrevious = order.canceledPrevious or false,
        expires = ORDER_EXPIRATION_MINUTES,
        -- se o gateway estiver configurado, o client busca o QR diretamente
        checkoutUrl = gateway and PIX_GATEWAY_URL or "",
        -- token que o client deve mandar no header X-Game-Token ao chamar o PHP
        jsonToken = gateway and PIX_JSON_TOKEN or "",
        qrImage = "", -- o gateway pode devolver um PNG base64; por aqui vem vazio
    })
end

local function actionCheck(cid, data)
    local txid = type(data) == "table" and tostring(data.txid or "") or ""
    if txid == "" then
        txid = waitingOrders[getPlayerAccountId(cid)] or ""
    end
    if txid == "" then
        return fail(cid, "Pedido nao informado.")
    end

    local now = os.time()
    if lastCheck[cid] and now - lastCheck[cid] < CHECK_MIN_INTERVAL then
        return false
    end
    lastCheck[cid] = now

    local order = getOrder(txid)
    -- so' o dono do pedido consulta (e a mensagem e' a mesma pra nao revelar
    -- que o txid de outra pessoa existe)
    if not order or order.account_id ~= getPlayerAccountId(cid) then
        return fail(cid, "Pedido nao encontrado.")
    end

    if order.status == "paid" then
        creditOrder(order, "gateway")
        order = getOrder(txid)
    end

    if order.status == "delivered" then
        return send(cid, {
            action = "pix",
            stage = "paid",
            txid = order.txid,
            coins = order.coins,
            points = getPoints(order.account_id),
        })
    end

    if order.status == "canceled" or order.status == "expired" then
        waitingOrders[order.account_id] = nil
        return send(cid, { action = "pix", stage = order.status, txid = order.txid })
    end

    send(cid, { action = "pix", stage = "pending", txid = order.txid })
end

local function actionCancel(cid, data)
    local txid = type(data) == "table" and tostring(data.txid or "") or ""
    if txid == "" then
        return false
    end

    local order = getOrder(txid)
    if not order or order.account_id ~= getPlayerAccountId(cid) then
        return false
    end

    -- so' cancela o que ainda nao foi pago
    db.query("UPDATE `pix_orders` SET `status` = 'canceled' WHERE `txid` = '" .. order.txid ..
        "' AND `status` = 'pending'")
    waitingOrders[order.account_id] = nil

    send(cid, { action = "pix", stage = "canceled", txid = order.txid })
    return true
end

function onExtendedOpcode(cid, opcode, buffer)
    if opcode ~= CODE_GAMEPIX then
        return false
    end

    if type(buffer) ~= "string" or buffer == "" then
        return false
    end

    -- Limite de tamanho: rejeita buffers gigantes (previne DoS de payload)
    if #buffer > MAX_BUFFER_BYTES then
        return false
    end

    -- Anti-flood de opcode: max OPCODE_MAX_PER_SECOND pacotes/s por conexao
    local now = os.time()
    if not opcodeFlood[cid] or now > opcodeFlood[cid].reset then
        opcodeFlood[cid] = { count = 1, reset = now + 1 }
    else
        opcodeFlood[cid].count = opcodeFlood[cid].count + 1
        if opcodeFlood[cid].count > OPCODE_MAX_PER_SECOND then
            return false
        end
    end

    local decoded, request = pcall(json.decode, buffer)
    if not decoded or type(request) ~= "table" then
        return false
    end

    startPoller()

    local action = request.action
    if action == "create" then
        actionCreate(cid, request.data or request)
    elseif action == "check" then
        actionCheck(cid, request.data or request)
    elseif action == "cancel" then
        actionCancel(cid, request.data or request)
    else
        return false
    end

    return true
end
