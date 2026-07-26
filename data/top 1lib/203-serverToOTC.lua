--[[
    *Lib dedicada a toda comunicação entre servidor e otc, via OPCODES.
    -- OpcodesOcupados: 
        SERVER RECEBE: 1 (language), 2 (refresh_spells)
        SERVER ENVIA: 1, 2 (sendRefresh_spells)
]]--

sendOpCode = doSendPlayerExtendedOpcode

function refreshSpellsFunc(cid)
    local string = "#v#"..getPlayerVocation(cid)..";"..sendAllCdToClient(cid, getPlayerElement(cid), true)
    doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, string)
    refreshBuySpells(cid)
end

onReceiveOpCode = {}

onReceiveOpCode[1] = function(cid, opcode, buffer) 
    if buffer == "pt" then
        setLang(cid, PT)
    else
        setLang(cid, EN)
    end
end

onReceiveOpCode[2] = function(cid, opcode, buffer)
    refreshSpellsFunc(cid)
end

onReceiveOpCode[3] = function(cid, opcode, buffer)
    local version = buffer

    if version ~= clientVersion.."true" then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, getLangString(cid, "WARNING! Your client is out of date, it is extremely important that you download the version v5.2 on our website.", "ATENÇÃO! O seu client está desatualizado, é de extrema importância que você faça o download da versão v5.2 em nosso website."))
    end
end
