--[[
    *Lib dedicada a toda comunica��o entre servidor e otc, via OPCODES.
    -- OpcodesOcupados: 
        SERVER RECEBE: 1 (language), 2 (refresh_spells)
        SERVER ENVIA: 1, 2 (sendRefresh_spells)
]]--

sendOpCode = doSendPlayerExtendedOpcode

function refreshSpellsFunc(cid)
    if not isPlayer(cid) then
        return
    end
    local element = getPlayerElement(cid)
    if type(element) ~= "string" then
        return
    end
    local cds = sendAllCdToClient(cid, element, true)
    if type(cds) ~= "string" then
        cds = ""
    end
    local payload = "#v#"..getPlayerVocation(cid)..";"..cds
    doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, payload)
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
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, getLangString(cid, "WARNING! Your client is out of date, it is extremely important that you download the version v5.2 on our website.", "ATEN��O! O seu client est� desatualizado, � de extrema import�ncia que voc� fa�a o download da vers�o v5.2 em nosso website."))
    end
end
