

function onSay(cid, words, param, channel)
	local texto = param
	if type(texto) ~= "string" then 
		return true
	elseif exhaustion.check(cid, "reportCd") then 
		doPlayerSendTextMessage(cid, 22, getLangString(cid, "Anti-Spam: Please, only one report per minute.", "Por favor, para evitar spam, envie somente um report por minuto. Caso queira reportar mais de um jogador, liste todos em um mesmo report."))
		return true 
	end 
	exhaustion.set(cid, "reportCd", 60)
	local pos = getCreaturePosition(cid)
	local reportFinal = os.date("%b %d %X", os.time()) .. " " .. getCreatureName(cid).." (X: "..pos.x..", Y: "..pos.y..", Z: "..pos.z.."): ".. texto
	table.insert(reportsEnviados, reportFinal)
	if #reportsEnviados > 20 then 
		table.remove(reportsEnviados, reportsEnviados[1])
	end 
	local adms = {"Lorent", "Otto", "Odin"}
	for i = 1, #adms do 
		if getPlayerByNameWildcard(adms[i]) then 
			doPlayerSendTextMessage(getPlayerByNameWildcard(adms[i]), MESSAGE_STATUS_CONSOLE_BLUE, reportFinal)
		end 
	end 
  return true
end