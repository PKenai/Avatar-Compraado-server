-- ============================================================================
-- HIGHSCORES in-game - lado servidor
-- ----------------------------------------------------------------------------
-- Protocolo: extended opcode 73, o mesmo que o modulo do client
-- (modules/game_highscore) usa. O client manda um JSON de pedido e este script
-- responde com o JSON da pagina atual.
--
-- INSTALACAO (ja feita neste datapack):
--   1. data/creaturescripts/creaturescripts.xml:
--        <event type="extendedopcode" name="HighscoreExtended" event="script"
--               value="highscores.lua"/>
--   2. data/creaturescripts/scripts/loginLogout/login.lua (onLogin):
--        registerCreatureEvent(cid, "HighscoreExtended")
--   3. Client: modules/game_highscore + data/images/topbuttons/highscore.png
--
-- SCHEMA DESTE SERVIDOR (diferente do script de referencia do pacote)
--   * players.skill_sword/skill_axe/... NAO existem aqui: as skills ficam na
--     tabela player_skills (player_id, skillid, value), com skillid =
--     SKILL_FIST..SKILL_FISHING (0..6 - ver data/lib/000-constant.lua).
--     Por isso as categorias de skill fazem LEFT JOIN em player_skills.
--   * magia = players.maglevel; level/experiencia = players.level/experience.
--   * staff fora da tabela: players.group_id < 2 (data/XML/groups.xml:
--     1 = Player, 2+ = tutor/gamemaster/god).
--   * personagens deletados: players.deleted = 0.
--   * online vem da propria coluna players.online (o login/logout mantem ela).
-- ============================================================================

local EXT_OP = 73
local DEFAULT_PER_PAGE = 10
local MAX_PER_PAGE = 50
local STAFF_GROUP_ID = 2 -- group_id < 2 = jogador comum
local MAX_VOCATION = 8

-- Categoria enviada pelo client -> skillid em player_skills.
-- Client: 0 Level | 1 Sword | 2 Axe | 3 Club | 4 Distance | 5 Shielding
--         6 Magic Level | 7 Fishing
-- player_skills: 0 Fist | 1 Club | 2 Sword | 3 Axe | 4 Distance | 5 Shield |
--                6 Fishing
local SKILL_ID_BY_CATEGORY = {
    [1] = 2, -- Sword
    [2] = 3, -- Axe
    [3] = 1, -- Club
    [4] = 4, -- Distance
    [5] = 5, -- Shielding
    [7] = 6, -- Fishing
}

local APPEARANCE_COLUMNS = "`name`, `vocation`, `level`, `looktype`, `lookhead`, " ..
    "`lookbody`, `looklegs`, `lookfeet`, `lookaddons`"

-- ----------------------------------------------------------------------------
-- Helpers do layer de banco (aceita os dois nomes usados neste engine)
-- ----------------------------------------------------------------------------
local function getNumber(resultId, column)
    if result.getNumber then
        return result.getNumber(resultId, column)
    end
    return result.getDataInt(resultId, column)
end

local function getString(resultId, column)
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

-- ----------------------------------------------------------------------------
-- Pedido do client
-- ----------------------------------------------------------------------------
local function sanitizeVocations(vocations)
    local values = {}
    if type(vocations) == "table" then
        for _, vocation in ipairs(vocations) do
            vocation = tonumber(vocation)
            if vocation and vocation >= 0 and vocation <= MAX_VOCATION and not values[vocation] then
                values[vocation] = vocation
            end
        end
    end

    if not next(values) then
        for i = 0, MAX_VOCATION do
            values[i] = i
        end
    end

    return table.concat(values, ",")
end

local function buildWhere(vocations)
    return "`deleted` = 0 AND `group_id` < " .. STAFF_GROUP_ID ..
        " AND `vocation` IN (" .. vocations .. ")"
end

local function countEntries(vocations)
    local resultId = storeQuery("SELECT COUNT(*) AS `total` FROM `players` WHERE " .. buildWhere(vocations))
    if not resultId then
        return 0
    end

    local total = getNumber(resultId, "total") or 0
    freeResult(resultId)
    return total
end

-- Monta a query da pagina. `category` decide a coluna de score:
--   0 = experiencia (a janela mostra o level), 6 = magia, resto = skill.
local function buildScoresQuery(category, vocations, offset, perPage)
    local from, scoreColumn, orderBy

    if category == 0 then
        from = "`players`"
        scoreColumn = "`experience`"
        orderBy = "`experience` DESC, `level` DESC, `name` ASC"
    elseif category == 6 then
        from = "`players`"
        scoreColumn = "`maglevel`"
        orderBy = "`maglevel` DESC, `experience` DESC, `name` ASC"
    else
        local skillId = SKILL_ID_BY_CATEGORY[category]
        if not skillId then
            return nil
        end

        from = "`players` LEFT JOIN `player_skills` ON `player_skills`.`player_id` = `players`.`id` " ..
            "AND `player_skills`.`skillid` = " .. skillId
        scoreColumn = "COALESCE(`player_skills`.`value`, 0)"
        orderBy = scoreColumn .. " DESC, `experience` DESC, `name` ASC"
    end

    return ([[
        SELECT %s, %s AS `score`, `online`
        FROM %s
        WHERE %s
        ORDER BY %s
        LIMIT %d,%d
    ]]):format(APPEARANCE_COLUMNS, scoreColumn, from, buildWhere(vocations), orderBy, offset, perPage)
end

local function fetchRows(category, vocations, offset, perPage)
    local rows = {}
    local query = buildScoresQuery(category, vocations, offset, perPage)
    if not query then
        return rows
    end

    local resultId = storeQuery(query)
    if not resultId then
        return rows
    end

    repeat
        rows[#rows + 1] = {
            rank = offset + #rows + 1,
            name = getString(resultId, "name"),
            vocation = getNumber(resultId, "vocation"),
            level = getNumber(resultId, "level"),
            experience = getNumber(resultId, "score"),
            online = getNumber(resultId, "online"),
            lookType = getNumber(resultId, "looktype"),
            lookHead = getNumber(resultId, "lookhead"),
            lookBody = getNumber(resultId, "lookbody"),
            lookLegs = getNumber(resultId, "looklegs"),
            lookFeet = getNumber(resultId, "lookfeet"),
            lookAddons = getNumber(resultId, "lookaddons"),
            wingsId = 0,
            auraId = 0,
            shaderId = 0,
        }
    until not result.next(resultId)

    freeResult(resultId)
    return rows
end

-- ----------------------------------------------------------------------------
-- Opcode
-- ----------------------------------------------------------------------------
local function sendHighscorePage(cid, category, page, perPage, vocations)
    local totalRows = countEntries(vocations)
    local totalPages = math.max(1, math.ceil(totalRows / perPage))
    page = math.min(math.max(1, page), totalPages)
    local offset = (page - 1) * perPage

    local rows = fetchRows(category, vocations, offset, perPage)

    local payload = {
        action = "highscore",
        category = category,
        page = page,
        pages = totalPages,
        data = rows,
    }

    local encoded = json.encode(payload)
    doSendPlayerExtendedOpcode(cid, EXT_OP, encoded)
end

function onExtendedOpcode(cid, opcode, buffer)
    if opcode ~= EXT_OP then
        return false
    end

    if not isPlayer(cid) or type(buffer) ~= "string" or buffer == "" then
        return false
    end

    local decoded, request = pcall(json.decode, buffer)
    if not decoded or type(request) ~= "table" then
        return false
    end

    local category = tonumber(request.category) or 0
    if category < 0 or category > 7 then
        return false
    end

    local page = math.max(1, tonumber(request.page) or 1)
    local perPage = math.max(1, math.min(MAX_PER_PAGE, tonumber(request.entriesPerPage) or DEFAULT_PER_PAGE))
    local vocations = sanitizeVocations(request.vocations)

    local ok, err = pcall(sendHighscorePage, cid, category, page, perPage, vocations)
    if not ok then
        print("[Highscores] erro ao montar a pagina:", err)
    end

    return true
end
