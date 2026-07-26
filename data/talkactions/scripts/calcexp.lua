local rateHps = {
[100] = 0.7,
[150] = 0.65,
[200] = 0.6,
[250] = 0.55,
[300] = 0.5,
[475] = 0.475,
[550] = 0.45,
[700] = 0.4,
[850] = 0.35,
[1000] = 0.3,
[1500] = 0.275,
[2000] = 0.25,
[2500] = 0.225,
[3000] = 0.2,
[4000] = 0.185,
[5000] = 0.17,
[7500] = 0.16,
[10000] = 0.15,
[15000] = 0.14,
[20000] = 0.13,
[1000000] = 0.13
}
local numbers ={100, 150, 200, 250, 300, 475, 550, 700, 850, 1000, 1500, 2000, 2500, 3000, 4000, 5000, 7500, 10000, 15000, 20000, 1000000}
function onSay(cid, words, param, channel)
	local numero = tonumber(param) 
	if not numero then return true end
	for i = 1, #numbers do 
		if numero <= numbers[i] then 
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, math.ceil(numero*rateHps[numbers[i]]*18))
			break;
		end 
	end
	return true
end