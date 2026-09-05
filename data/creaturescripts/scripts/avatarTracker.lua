-- ============================================================================
-- AVATAR TRACKER (icone do Avatar no minimapa dos participantes do BR)
-- ----------------------------------------------------------------------------
-- Mostra, no minimapa de cada participante do Battle Royale, onde esta o
-- Avatar da arena (batata quente). Usa o MESMO protocolo/canal do party HUD
-- (opcode 160 + json) mas com o tipo proprio "avatar", renderizado no client
-- com o icone icons/Avatar.png (mods/game_partyIcons).
--
-- Regras:
--   * so mostra durante uma rodada viva no estado "hotpotato" (avatar existe);
--   * so para quem esta participando da rodada (brParticipant == 1);
--   * o proprio avatar nao recebe o proprio marcador;
--   * quem sai do evento (eliminado / teleportado para fora / rodada acabou)
--     perde o marcador no proximo tick (server manda active=false).
--
-- Protocolo (client -> mods/game_partyIcons/icons.lua):
--   {type="avatar", active=true,  player={name, pos}}  -> cria/move o icone
--   {type="avatar", active=false}                      -> remove o icone
--
-- Arquitetura igual ao partyUpdate.lua: cada jogador tem o proprio think
-- (~1s), estado local em tabelas Lua, updates so quando algo mudou + heartbeat.
-- ============================================================================

dofile(getDataDir() .. "lib/battleRoyale.lua")

local OPCODE_AVATAR = 160

local active = {}     -- cid -> true: viewer esta com o marcador visivel
local lastViewerPos = {}  -- cid -> pos do viewer (recenter quando ele anda)
local lastAvatar = {} -- cid -> {name=, x=, y=, z=} ultimo avatar enviado
local tickCount = {}  -- cid -> contador (heartbeat)

local HEARTBEAT_EVERY = 5

local function safeJson(data)
    local ok, res = pcall(json.encode, data)
    if ok and type(res) == "string" then
        return res
    end
    return nil
end

local function sendAvatar(cid, data)
    if not isPlayer(cid) then
        return
    end
    local payload = safeJson(data)
    if payload then
        doSendPlayerExtendedOpcode(cid, OPCODE_AVATAR, payload)
    end
end

-- Manda remover o marcador (se ainda estava ativo) e zera o estado do viewer.
local function clearMarker(cid)
    if active[cid] then
        sendAvatar(cid, {type = "avatar", active = false})
    end
    active[cid] = nil
    lastViewerPos[cid] = nil
    lastAvatar[cid] = nil
    tickCount[cid] = nil
end

function onThink(cid)
    if not isPlayer(cid) then
        return true
    end

    local avatarCid = BattleRoyale.getArenaAvatarCid()
    local isIn = BattleRoyale.isParticipant(cid)

    -- mostra apenas para participante, com um avatar existente, que nao seja
    -- o proprio avatar (ele ja sabe onde esta).
    local show = isIn and avatarCid and isPlayer(avatarCid) and avatarCid ~= cid

    if not show then
        if active[cid] then
            clearMarker(cid)
        end
        return true
    end

    local avatarPos = getThingPos(avatarCid)
    local viewerPos = getThingPos(cid)
    local name = getCreatureName(avatarCid)

    local prev = lastAvatar[cid]
    local vPrev = lastViewerPos[cid]
    tickCount[cid] = (tickCount[cid] or 0) + 1

    -- envia quando o avatar andou, quando o viewer andou (recenter do minimapa)
    -- ou no heartbeat (recupera mensagens perdidas).
    local changed = not prev
        or prev.name ~= name
        or prev.x ~= avatarPos.x
        or prev.y ~= avatarPos.y
        or prev.z ~= avatarPos.z
        or not vPrev
        or vPrev.x ~= viewerPos.x
        or vPrev.y ~= viewerPos.y
        or vPrev.z ~= viewerPos.z

    if changed or (tickCount[cid] % HEARTBEAT_EVERY) == 0 then
        sendAvatar(cid, {
            type = "avatar",
            active = true,
            player = {name = name, pos = avatarPos}
        })
        active[cid] = true
        lastAvatar[cid] = {name = name, x = avatarPos.x, y = avatarPos.y, z = avatarPos.z}
        lastViewerPos[cid] = {x = viewerPos.x, y = viewerPos.y, z = viewerPos.z}
    end

    return true
end

function onLogout(cid)
    active[cid] = nil
    lastViewerPos[cid] = nil
    lastAvatar[cid] = nil
    tickCount[cid] = nil
    return true
end
