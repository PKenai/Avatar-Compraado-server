-- Smart Ping System
-- Shift + Right Click para marcar localização para party members

local pingEffect = 56 -- Effect ID que aparece
local pingDuration = 3000 -- Duração do ping em milissegundos (3 segundos)
local pingCooldown = 1000 -- Cooldown entre pings (1 segundo)
local PING_OPCODE = 100 -- Extended opcode para ping system

-- Storage para cooldown
local STORAGE_PING_COOLDOWN = 45000

-- Função para enviar ping para todos da party
local function sendPingToParty(player, position)
    local party = player:getParty()
    
    if not party then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You need to be in a party to use ping.")
        return false
    end
    
    -- Verifica cooldown (usando os.time() em segundos)
    local lastPing = player:getStorageValue(STORAGE_PING_COOLDOWN)
    local currentTime = os.time()
    
    if lastPing > 0 and (currentTime - lastPing) < (pingCooldown / 1000) then
        return false
    end
    
    -- Atualiza cooldown
    player:setStorageValue(STORAGE_PING_COOLDOWN, currentTime)
    
    -- Pega todos membros da party
    local members = {}
    local leader = party:getLeader()
    table.insert(members, leader)
    
    for _, member in ipairs(party:getMembers()) do
        table.insert(members, member)
    end
    
    -- Envia efeito e mensagem para todos os membros
    local playerName = player:getName()
    
    for _, member in ipairs(members) do
        -- Envia efeito visual
        position:sendMagicEffect(pingEffect, member)
        
        -- Mensagem informando quem fez o ping
        member:sendTextMessage(MESSAGE_EVENT_ADVANCE, playerName .. " marked this location!")
    end
    
    return true
end

-- CreatureEvent para receber extended opcode do cliente
local pingEvent = CreatureEvent("SmartPing")

function pingEvent.onExtendedOpcode(player, opcode, buffer)
    if opcode == PING_OPCODE then
        -- Parse da posição enviada pelo cliente (formato: "x,y,z")
        local coords = string.split(buffer, ",")
        if #coords == 3 then
            local position = Position(tonumber(coords[1]), tonumber(coords[2]), tonumber(coords[3]))
            sendPingToParty(player, position)
        end
        return true
    end
    return false
end

pingEvent:type("extendedopcode")
pingEvent:register()

-- Registra o evento para todos os players ao fazer login
local pingLogin = CreatureEvent("SmartPingLogin")

function pingLogin.onLogin(player)
    player:registerEvent("SmartPing")
    return true
end

pingLogin:register()

