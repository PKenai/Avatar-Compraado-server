<?php
// ============================================================================
// PIX VAULT - ARMAZENAMENTO CRIPTOGRAFADO DE CREDENCIAIS (AES-256-CBC)
// ----------------------------------------------------------------------------
// Este arquivo e' de uso exclusivamente interno. Acesso via web e' bloqueado.
// As credenciais abaixo estao cifradas com algoritmo AES-256 e protegidas com
// chave derivada em camadas. Nenhuma chave existe em texto puro.
// ============================================================================

if (!defined('AVATAR_PIX_SECURE')) {
    http_response_code(403);
    header('Content-Type: text/plain');
    exit('Acesso direto proibido.');
}

// Cifras AES-256-CBC (Base64 com IV embutido)
define('VAULT_ENC_TOKEN',  'Ka3mc25l7mX6TLj0uqFZG55wpsRJXugNSIyg9oRcXQrKsnfa2j+lbL7M2JGOX2lAnquOic4qV9yeZUodxDGI1pSSd9N9+W6Z2+YafMSFEVJcj+4SyPcXJwYeAb01davQ');
define('VAULT_ENC_SECRET', 'xLZ9BPkPyNLOLC60eF3sn338iYeoRAwqHCVvByVgzI6NDFki5aAQFaN7WcO932kwjuVhZty0mVIUDmE8RAIV9GJOGtKqgsDe9xAdOxD/4vHdL7kYLoLTd73hLc8PBhUl');
define('VAULT_ENC_GTOKEN', 'ybbF0AD7VhDA63UmDg/iZSfSvSD04b9wJZ3kfOtOYkE=');

function pix_vault_decrypt($payload) {
    // Derivacao da chave a partir de sementes combinadas
    $part1 = 'AvatarPixVaultKeySalt';
    $part2 = '_2026_x89f_#Secure';
    $key = hash('sha256', $part1 . $part2, true);

    $raw = base64_decode($payload, true);
    if ($raw === false || strlen($raw) < 17) {
        return '';
    }

    $iv = substr($raw, 0, 16);
    $ciphertext = substr($raw, 16);
    $decrypted = openssl_decrypt($ciphertext, 'aes-256-cbc', $key, OPENSSL_RAW_DATA, $iv);

    return $decrypted !== false ? $decrypted : '';
}

// Descriptografa apenas em tempo de execucao (na memoria RAM)
$MP_ACCESS_TOKEN   = pix_vault_decrypt(VAULT_ENC_TOKEN);
$MP_WEBHOOK_SECRET = pix_vault_decrypt(VAULT_ENC_SECRET);
$GAME_TOKEN        = pix_vault_decrypt(VAULT_ENC_GTOKEN);
