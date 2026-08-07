-- Tutorial do primeiro login: o SERVIDOR decide.
-- No PRIMEIRO login do personagem, grava a storage como concluido
-- e envia um push (extended opcode 220, buffer "open") para o client
-- abrir o tutorial. Em qualquer login seguinte a storage ja esta
-- marcada, entao nada e enviado: o tutorial aparece UMA unica vez,
-- para sempre, independente de o jogador ter fechado antes do fim.
--
-- Registro em data/creaturescripts/creaturescripts.xml:
--   <event type="login" name="FirstLogin" event="script" value="loginLogout/firstlogin.lua"/>

local STORAGE_FIRSTLOGIN = 42001
local OPCODE_FIRSTLOGIN  = 220

function onLogin(cid)
    if getPlayerStorageValue(cid, STORAGE_FIRSTLOGIN) ~= 1 then
        setPlayerStorageValue(cid, STORAGE_FIRSTLOGIN, 1)
        doSendPlayerExtendedOpcode(cid, OPCODE_FIRSTLOGIN, "open")
    end
    return true
end
