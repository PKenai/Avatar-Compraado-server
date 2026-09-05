-- ============================================================
-- WEAPON PROFICIENCY SYSTEM - TFS 1.1 Server-Side
-- ============================================================
-- Sistema de Maestria e Proficiencia de Armas adaptado para TFS 1.1.
-- Gerencia progresso de XP, niveis de maestria, selecao de perks e bônus.
-- Comunica-se com o client via Extended Opcode 188.
-- ============================================================

WeaponProficiency = {}

-- Carrega JSON caso nao esteja disponivel
if type(json) ~= "table" then
    dofile(getDataDir() .. "lib/json.lua")
end

-- Configuracao de Opcodes e Storages
WEAPON_PROFICIENCY_OPCODE = 188
local STORAGE_PROFICIENCY_DATA = 89200
local STORAGE_ACTIVE_WEAPON_ID = 89201

-- Categorias de Armas (compativel com os filtros do client)
WeaponProficiency.Categories = {
    Axes = 17,
    Clubs = 18,
    DistanceWeapons = 19,
    Swords = 20,
    WandsRods = 21,
    FistWeapons = 27
}

-- Requisitos de Experiencia por Nivel (Niveis 1 a 7)
WeaponProficiency.LevelExperience = {
    [0] = 0,
    [1] = 15694800,
    [2] = 129389800,
    [3] = 441084800,
    [4] = 1050779800,
    [5] = 2058474800,
    [6] = 3564169800,
    [7] = 8469559800
}

WeaponProficiency.MAX_LEVEL = 7

-- Lista de IDs de Luvas do servidor (Fist Weapons)
WeaponProficiency.GloveIds = {
    19098, 19100, 19102, 19104, 19106, 19108, 19110, 19112,
    19114, 19116, 19118, 19120, 19122, 19124, 19126, 19128,
    19130, 19132, 19134, 19136, 19138, 19140, 19142, 19144,
    19146, 19148, 19150, 19152
}

-- Definicao dos Perks por Nivel (3 opcoes por nivel)
-- Observacao estrita: magias e efeitos de Pyromancer usam elemento Pyro e nao Fire.
WeaponProficiency.Perks = {
    [1] = {
        {
            name = "Precision Strike",
            description = "Aumenta a chance de acerto critico em +2%.",
            icon = "precision",
            iconSource = "icons-0",
            iconClip = "256 0 64 64",
            bonus = {critChance = 2}
        },
        {
            name = "Vitality Siphon",
            description = "Concede +1% de chance de roubo de vida (5% de conversao).",
            icon = "life_leech",
            iconSource = "icons-0",
            iconClip = "640 0 64 64",
            bonus = {lifeLeechChance = 1, lifeLeechAmount = 5}
        },
        {
            name = "Pyro Sparks",
            description = "Aumenta o dano do elemento Pyro em +3%.",
            icon = "pyro_sparks",
            iconSource = "icons-2",
            iconClip = "0 0 64 64",
            bonus = {pyroDamage = 3}
        }
    },
    [2] = {
        {
            name = "Fierce Momentum",
            description = "Aumenta o dano fisico base da arma em +3%.",
            icon = "momentum",
            iconSource = "icons-4",
            iconClip = "0 0 64 64",
            bonus = {physicalDamage = 3}
        },
        {
            name = "Mental Stream",
            description = "Concede +1% de chance de roubo de mana (5% de conversao).",
            icon = "mana_leech",
            iconSource = "icons-0",
            iconClip = "704 0 64 64",
            bonus = {manaLeechChance = 1, manaLeechAmount = 5}
        },
        {
            name = "Pyro Infusion",
            description = "Aumenta o dano do elemento Pyro em +5%.",
            icon = "pyro_infusion",
            iconSource = "icons-2",
            iconClip = "64 0 64 64",
            bonus = {pyroDamage = 5}
        }
    },
    [3] = {
        {
            name = "Devastating Impact",
            description = "Aumenta o dano critico adicional em +5%.",
            icon = "critical_damage",
            iconSource = "icons-0",
            iconClip = "448 0 64 64",
            bonus = {critDamage = 5}
        },
        {
            name = "Stalwart Guard",
            description = "Reduz todo o dano recebido em 2%.",
            icon = "defense",
            iconSource = "icons-0",
            iconClip = "128 0 64 64",
            bonus = {damageReduction = 2}
        },
        {
            name = "Pyro Burst",
            description = "Aumenta o dano de magias Pyro em +7%.",
            icon = "pyro_burst",
            iconSource = "icons-1",
            iconClip = "0 0 64 64",
            bonus = {pyroDamage = 7}
        }
    },
    [4] = {
        {
            name = "Weapon Mastery",
            description = "Aumenta a pericia de combate da arma em +2 de skill.",
            icon = "skill_boost",
            iconSource = "icons-7",
            iconClip = "0 0 64 64",
            bonus = {skillBoost = 2}
        },
        {
            name = "Swift Recovery",
            description = "Restaura 100 de Vida e 50 de Mana ao derrotar um monstro.",
            icon = "recovery",
            iconSource = "icons-0",
            iconClip = "896 0 64 64",
            bonus = {hpOnKill = 100, mpOnKill = 50}
        },
        {
            name = "Pyro Flare",
            description = "Aumenta a chance de critico elemental Pyro em +5%.",
            icon = "pyro_flare",
            iconSource = "icons-2",
            iconClip = "128 0 64 64",
            bonus = {pyroCritChance = 5}
        }
    },
    [5] = {
        {
            name = "Lethal Edge",
            description = "Aumenta +3% de chance de critico e +10% de dano critico.",
            icon = "lethal",
            iconSource = "icons-0",
            iconClip = "384 0 64 64",
            bonus = {critChance = 3, critDamage = 10}
        },
        {
            name = "Vampiric Embrace",
            description = "Aumenta em +2% as chances de roubo de vida e roubo de mana.",
            icon = "vampiric",
            iconSource = "icons-0",
            iconClip = "768 0 64 64",
            bonus = {lifeLeechChance = 2, manaLeechChance = 2}
        },
        {
            name = "Pyro Cataclysm",
            description = "Aumenta o dano elemental Pyro em +10%.",
            icon = "pyro_cataclysm",
            iconSource = "icons-1",
            iconClip = "64 0 64 64",
            bonus = {pyroDamage = 10}
        }
    },
    [6] = {
        {
            name = "Titan Force",
            description = "Concede +4 de skill de combate e +5% de dano fisico.",
            icon = "titan",
            iconSource = "icons-4",
            iconClip = "64 0 64 64",
            bonus = {skillBoost = 4, physicalDamage = 5}
        },
        {
            name = "Iron Will",
            description = "Reduz o dano recebido em 4% e aumenta a vida maxima em +5%.",
            icon = "iron_will",
            iconSource = "icons-0",
            iconClip = "192 0 64 64",
            bonus = {damageReduction = 4, maxHpPercent = 5}
        },
        {
            name = "Pyro Mastery",
            description = "Aumenta o dano Pyro em +15% e +10% no dano de magias Pyro.",
            icon = "pyro_mastery",
            iconSource = "icons-1",
            iconClip = "128 0 64 64",
            bonus = {pyroDamage = 15, pyroSpellDamage = 10}
        }
    },
    [7] = {
        {
            name = "Supreme Champion",
            description = "Concede +5% Crit Chance, +20% Crit Damage e +5 de Weapon Skill.",
            icon = "supreme",
            iconSource = "icons-0",
            iconClip = "1344 0 64 64",
            bonus = {critChance = 5, critDamage = 20, skillBoost = 5}
        },
        {
            name = "Eternal Vigor",
            description = "Concede +3% Life Leech, +3% Mana Leech e +5% de reducao de dano.",
            icon = "eternal",
            iconSource = "icons-0",
            iconClip = "960 0 64 64",
            bonus = {lifeLeechChance = 3, manaLeechChance = 3, damageReduction = 5}
        },
        {
            name = "Pyro Ascension",
            description = "Concede +25% de dano Pyro e chance de queimar com chamas Pyro.",
            icon = "pyro_ascension",
            iconSource = "icons-1",
            iconClip = "192 0 64 64",
            bonus = {pyroDamage = 25, pyroBurn = true}
        }
    }
}

-- ============================================================
-- TEMAS DE PERKS POR LUVA (per-glove perk themes)
-- ============================================================
-- Cada luva pode ter sua propria arvore de perks, focada em um
-- tema (critico, regeneracao, vampirismo, tanque, poder, hibrido).
-- A arvore exibida no client e escolhida por WeaponProficiency.GloveTheme.
-- Bonus suportados: critChance, critDamage, physicalDamage, skillBoost,
-- damageReduction, hpOnKill, mpOnKill, lifeLeechChance/Amount, manaLeechChance/Amount.
-- Cada coluna tem 7 valores (nivel 1 a 7).

WeaponProficiency.Themes = {
    -- Foco em acerto critico
    crit = {
        columns = {
            { id = "critChance",      label = "Critical Precision", desc = "Increases critical hit chance by +%d%%.",            values = {2, 3, 4, 5, 6, 8, 10},    icon = "icons-0", clip = "256 0 64 64" },
            { id = "critDamage",      label = "Critical Impact",    desc = "Increases critical extra damage by +%d%%.",           values = {5, 8, 12, 16, 22, 28, 35}, icon = "icons-0", clip = "448 0 64 64" },
            { id = "physicalDamage",  label = "Deadly Momentum",    desc = "Increases physical damage by +%d%%.",                 values = {2, 3, 4, 5, 7, 9, 12},     icon = "icons-0", clip = "0 0 64 64" }
        }
    },
    -- Foco em regeneracao (vida e mana ao abater)
    regen = {
        columns = {
            { id = "hpOnKill",        label = "Vital Recovery",     desc = "Restores %d hit points when you kill a monster.",    values = {15, 30, 50, 75, 100, 140, 180}, icon = "icons-0", clip = "896 0 64 64" },
            { id = "mpOnKill",        label = "Mental Recovery",    desc = "Restores %d mana when you kill a monster.",          values = {10, 20, 35, 50, 70, 95, 120},   icon = "icons-0", clip = "960 0 64 64" },
            { id = "lifeLeechChance", label = "Life Leech",         desc = "+%d%% chance to leech %d%% of damage as health.",    values = {1, 1, 2, 2, 3, 3, 4},          secondary = {id = "lifeLeechAmount", values = {5, 6, 7, 8, 9, 10, 12}}, icon = "icons-0", clip = "640 0 64 64" }
        }
    },
    -- Foco em roubo de vida e mana
    vampire = {
        columns = {
            { id = "lifeLeechChance", label = "Blood Siphon",       desc = "+%d%% chance to leech %d%% of damage as health.",    values = {1, 2, 2, 3, 3, 4, 5},          secondary = {id = "lifeLeechAmount", values = {6, 7, 8, 9, 10, 11, 13}}, icon = "icons-0", clip = "640 0 64 64" },
            { id = "manaLeechChance", label = "Mana Siphon",        desc = "+%d%% chance to leech %d%% of damage as mana.",      values = {1, 1, 2, 2, 3, 3, 4},          secondary = {id = "manaLeechAmount", values = {6, 7, 8, 9, 10, 11, 13}}, icon = "icons-0", clip = "704 0 64 64" },
            { id = "critChance",      label = "Predator's Eye",     desc = "Increases critical hit chance by +%d%%.",            values = {1, 2, 2, 3, 3, 4, 5},          icon = "icons-0", clip = "256 0 64 64" }
        }
    },
    -- Foco em resistencia / tank
    tank = {
        columns = {
            { id = "damageReduction", label = "Iron Skin",          desc = "Reduces all damage taken by %d%%.",                  values = {1, 2, 3, 4, 5, 7, 10},         icon = "icons-0", clip = "128 0 64 64" },
            { id = "hpOnKill",        label = "Second Wind",        desc = "Restores %d hit points when you kill a monster.",    values = {30, 50, 80, 110, 150, 200, 260}, icon = "icons-0", clip = "896 0 64 64" },
            { id = "skillBoost",      label = "Stalwart Skill",     desc = "Grants +%d weapon skill, increasing your strikes.",  values = {1, 2, 3, 4, 5, 7, 9},           icon = "icons-7", clip = "0 0 64 64" }
        }
    },
    -- Foco em dano bruto
    power = {
        columns = {
            { id = "physicalDamage",  label = "Raw Power",          desc = "Increases physical damage by +%d%%.",                values = {3, 4, 6, 8, 10, 13, 16},       icon = "icons-0", clip = "0 0 64 64" },
            { id = "skillBoost",      label = "Weapon Mastery",     desc = "Grants +%d weapon skill, increasing your strikes.",  values = {1, 2, 3, 4, 5, 7, 9},           icon = "icons-7", clip = "0 0 64 64" },
            { id = "critDamage",      label = "Lethal Blow",        desc = "Increases critical extra damage by +%d%%.",           values = {5, 8, 12, 16, 22, 28, 35},     icon = "icons-0", clip = "448 0 64 64" }
        }
    },
    -- Tema hibrido (mistura equilibrada)
    balanced = {
        columns = {
            { id = "critChance",      label = "Balanced Strikes",   desc = "Increases critical hit chance by +%d%%.",            values = {1, 2, 2, 3, 3, 4, 5},          icon = "icons-0", clip = "256 0 64 64" },
            { id = "lifeLeechChance", label = "Balanced Leech",     desc = "+%d%% chance to leech %d%% of damage as health.",    values = {1, 1, 2, 2, 3, 3, 4},          secondary = {id = "lifeLeechAmount", values = {5, 6, 7, 8, 9, 10, 11}}, icon = "icons-0", clip = "640 0 64 64" },
            { id = "damageReduction", label = "Balanced Guard",     desc = "Reduces all damage taken by %d%%.",                  values = {1, 1, 2, 2, 3, 4, 5},          icon = "icons-0", clip = "128 0 64 64" }
        }
    }
}

-- Mapa: ID da luva -> tema de perks
WeaponProficiency.GloveTheme = {
    [19098] = "regen",    -- Simple Glove
    [19100] = "regen",    -- Sticky Glove
    [19102] = "vampire",  -- Funeral Glove
    [19104] = "crit",     -- Red Pincer Glove
    [19106] = "regen",    -- Ladybug Glove
    [19108] = "crit",     -- Beast Gloves
    [19110] = "vampire",  -- Woven Gloves
    [19112] = "vampire",  -- Queen's Gloves
    [19114] = "crit",     -- Web Gloves
    [19116] = "tank",     -- Mud Gloves
    [19118] = "vampire",  -- Gleaming Gloves
    [19120] = "crit",     -- Royal Gloves
    [19122] = "balanced", -- Metallic Gloves
    [19124] = "balanced", -- Slimy Gloves
    [19126] = "balanced", -- Grey Leather Gloves
    [19128] = "balanced", -- Earth Gloves
    [19130] = "regen",    -- Nature Gloves
    [19132] = "balanced", -- Butcher Gloves
    [19134] = "tank",     -- Tough Gloves
    [19136] = "power",    -- Rebellion Gloves
    [19138] = "balanced", -- Marine Gloves
    [19140] = "power",    -- Courage Gloves
    [19142] = "balanced", -- Hermit's Gloves
    [19144] = "power",    -- Knowledge Gloves
    [19146] = "power",    -- Dark Fold Gloves
    [19148] = "balanced", -- Desert Gloves
    [19150] = "tank",     -- Boulder Gloves
    [19152] = "balanced"  -- Lost Knowledge Gloves
}

WeaponProficiency.ThemeTrees = {}

-- Monta a arvore completa (7 niveis x 3 perks) de um tema
function WeaponProficiency.buildThemeTree(themeKey)
    local theme = WeaponProficiency.Themes[themeKey]
    if not theme then
        return nil
    end

    local tree = {}
    for lvl = 1, WeaponProficiency.MAX_LEVEL do
        tree[lvl] = {}
        for col = 1, 3 do
            local c = theme.columns[col]
            if c then
                local v = c.values[lvl]
                local bonus = { [c.id] = v }
                if c.secondary then
                    bonus[c.secondary.id] = c.secondary.values[lvl]
                end

                local description
                if c.secondary then
                    description = string.format(c.desc, v, c.secondary.values[lvl])
                else
                    description = string.format(c.desc, v)
                end

                tree[lvl][col] = {
                    name = c.label,
                    description = description,
                    icon = c.label:lower():gsub("[^%w]", "_"),
                    iconSource = c.icon,
                    iconClip = c.clip,
                    bonus = bonus
                }
            end
        end
    end
    return tree
end

-- Retorna a arvore de perks de uma arma (tema proprio ou a padrao)
function WeaponProficiency.getPerksForWeapon(itemId)
    local themeKey = WeaponProficiency.GloveTheme[itemId]
    if themeKey then
        if not WeaponProficiency.ThemeTrees[themeKey] then
            WeaponProficiency.ThemeTrees[themeKey] = WeaponProficiency.buildThemeTree(themeKey)
        end
        return WeaponProficiency.ThemeTrees[themeKey]
    end
    return WeaponProficiency.Perks
end

-- Remove campos internos (bonus/icon) que o client nao usa, reduzindo o payload
function WeaponProficiency.stripForClient(tree)
    if not tree then
        return tree
    end
    local stripped = {}
    for lvl, cols in pairs(tree) do
        stripped[lvl] = {}
        for idx, perk in pairs(cols) do
            stripped[lvl][idx] = {
                name = perk.name,
                description = perk.description,
                iconSource = perk.iconSource,
                iconClip = perk.iconClip
            }
        end
    end
    return stripped
end

-- Pre-monta as arvores de todos os temas
for themeKey in pairs(WeaponProficiency.Themes) do
    WeaponProficiency.ThemeTrees[themeKey] = WeaponProficiency.buildThemeTree(themeKey)
end

-- ============================================================
-- PERSISTENCIA E UTILITARIOS
-- ============================================================

-- Carrega a tabela de proficiencias do jogador
function WeaponProficiency.loadPlayerData(cid)
    local raw = getPlayerStorageValue(cid, STORAGE_PROFICIENCY_DATA)
    if type(raw) == "string" and #raw > 0 and raw:sub(1, 1) == "{" then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == "table" then
            return data
        end
    end
    return {}
end

-- Salva a tabela de proficiencias do jogador
function WeaponProficiency.savePlayerData(cid, data)
    local ok, encoded = pcall(json.encode, data)
    if ok and type(encoded) == "string" then
        setPlayerStorageValue(cid, STORAGE_PROFICIENCY_DATA, encoded)
    end
end

-- Determina a categoria e se um item e uma arma valida
function WeaponProficiency.getWeaponInfo(itemId)
    if not itemId or itemId <= 0 then
        return nil
    end

    local info = getItemInfo(itemId)
    if not info or type(info) ~= "table" then
        return nil
    end

    local weaponType = info.weaponType
    local category = nil

    if weaponType == WEAPON_SWORD then
        category = WeaponProficiency.Categories.Swords
    elseif weaponType == WEAPON_CLUB then
        category = WeaponProficiency.Categories.Clubs
    elseif weaponType == WEAPON_AXE then
        category = WeaponProficiency.Categories.Axes
    elseif weaponType == WEAPON_DIST or (WEAPON_DISTANCE and weaponType == WEAPON_DISTANCE) or weaponType == 4 then
        category = WeaponProficiency.Categories.DistanceWeapons
    elseif weaponType == WEAPON_WAND or weaponType == 7 then
        category = WeaponProficiency.Categories.WandsRods
    else
        -- Checagem para luvas / fist weapons customizadas
        local itemName = (info.name or getItemNameById(itemId) or ""):lower()
        if itemName:find("luva") or itemName:find("glove") or itemName:find("fist") or weaponType == WEAPON_FIST or weaponType == 6 then
            category = WeaponProficiency.Categories.FistWeapons
        end
    end

    if not category then
        return nil
    end

    local cId = 0
    local it = ItemType(itemId)
    if it and it.getClientId then
        cId = it:getClientId()
    end
    if not cId or cId == 0 then
        cId = info.clientId or 0
    end

    local itemName = info.name or getItemNameById(itemId) or "Weapon"

    return {
        id = itemId,
        clientId = cId,
        name = itemName,
        category = category
    }
end

-- Obtem a arma atualmente equipada pelo jogador (mão esquerda ou direita)
function WeaponProficiency.getEquippedWeapon(cid)
    local leftItem = getPlayerSlotItem(cid, CONST_SLOT_LEFT)
    if leftItem and leftItem.itemid > 0 then
        local info = WeaponProficiency.getWeaponInfo(leftItem.itemid)
        if info then
            info.slot = CONST_SLOT_LEFT
            return info
        end
    end

    local rightItem = getPlayerSlotItem(cid, CONST_SLOT_RIGHT)
    if rightItem and rightItem.itemid > 0 then
        local info = WeaponProficiency.getWeaponInfo(rightItem.itemid)
        if info then
            info.slot = CONST_SLOT_RIGHT
            return info
        end
    end

    return nil
end

-- Calcula o nivel baseado na experiencia acumulada
function WeaponProficiency.getLevelByExperience(exp)
    exp = exp or 0
    local level = 0
    for lvl = 1, WeaponProficiency.MAX_LEVEL do
        if exp >= WeaponProficiency.LevelExperience[lvl] then
            level = lvl
        else
            break
        end
    end
    return level
end

-- Obtem os dados de proficiencia de uma arma especifica para o jogador
function WeaponProficiency.getWeaponProficiency(cid, weaponId)
    local allData = WeaponProficiency.loadPlayerData(cid)
    local key = tostring(weaponId)
    if not allData[key] then
        allData[key] = {
            exp = 0,
            level = 0,
            perks = {} -- [level] = perkIndex (1, 2 ou 3)
        }
    end
    return allData[key], allData
end

-- ============================================================
-- PROGRESSAO E EXPERIENCIA
-- ============================================================

-- Adiciona experiencia na arma atualmente equipada
function WeaponProficiency.addWeaponExperience(cid, expGained)
    if not isPlayer(cid) or expGained <= 0 then
        return false
    end

    local equipped = WeaponProficiency.getEquippedWeapon(cid)
    if not equipped then
        return false
    end

    local prof, allData = WeaponProficiency.getWeaponProficiency(cid, equipped.id)
    local oldLevel = WeaponProficiency.getLevelByExperience(prof.exp)
    prof.exp = prof.exp + expGained
    local newLevel = WeaponProficiency.getLevelByExperience(prof.exp)
    prof.level = newLevel

    allData[tostring(equipped.id)] = prof
    WeaponProficiency.savePlayerData(cid, allData)

    -- Notifica avanco de nivel de maestria
    if newLevel > oldLevel then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, 
            string.format("[Weapon Proficiency] Sua maestria com %s subiu para o Nivel %d! Novos perks disponiveis.", 
            equipped.name, newLevel))
        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_GREEN)
    end

    -- Sincroniza dados com o client
    WeaponProficiency.sendData(cid)
    return true
end

-- ============================================================
-- SELECAO DE PERKS
-- ============================================================

-- Seleciona um perk para um nivel especifico
function WeaponProficiency.selectPerk(cid, level, perkIndex)
    if not isPlayer(cid) then
        return false, "Jogador invalido."
    end

    level = tonumber(level)
    perkIndex = tonumber(perkIndex)

    if not level or level < 1 or level > WeaponProficiency.MAX_LEVEL then
        return false, "Nivel de perk invalido."
    end

    if not perkIndex or perkIndex < 1 or perkIndex > 3 then
        return false, "Opcao de perk invalida."
    end

    local equipped = WeaponProficiency.getEquippedWeapon(cid)
    if not equipped then
        return false, "Equipe uma arma primeiro para configurar seus perks de proficiencia."
    end

    local prof, allData = WeaponProficiency.getWeaponProficiency(cid, equipped.id)
    local currentLevel = WeaponProficiency.getLevelByExperience(prof.exp)

    if currentLevel < level then
        return false, string.format("Voce precisa atingir o Nivel %d de maestria com esta arma para desbloquear este perk.", level)
    end

    prof.perks[tostring(level)] = perkIndex
    allData[tostring(equipped.id)] = prof
    WeaponProficiency.savePlayerData(cid, allData)

    local perks = WeaponProficiency.getPerksForWeapon(equipped.id)
    local perkDef = perks[level] and perks[level][perkIndex]
    local perkName = perkDef and perkDef.name or "Perk"
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, 
        string.format("[Weapon Proficiency] Perk ativado: %s (Nivel %d)", perkName, level))
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)

    WeaponProficiency.sendData(cid)
    return true, "Perk selecionado com sucesso!"
end

-- ============================================================
-- BONUS EM COMBATE
-- ============================================================

-- Retorna a soma de todos os bonus ativos da arma equipada
function WeaponProficiency.getActiveBonuses(cid)
    local bonuses = {
        critChance = 0,
        critDamage = 0,
        lifeLeechChance = 0,
        lifeLeechAmount = 0,
        manaLeechChance = 0,
        manaLeechAmount = 0,
        pyroDamage = 0,
        pyroCritChance = 0,
        pyroSpellDamage = 0,
        physicalDamage = 0,
        skillBoost = 0,
        damageReduction = 0,
        hpOnKill = 0,
        mpOnKill = 0,
        maxHpPercent = 0,
        pyroBurn = false
    }

    if not isPlayer(cid) then
        return bonuses
    end

    local equipped = WeaponProficiency.getEquippedWeapon(cid)
    if not equipped then
        return bonuses
    end

    local prof = WeaponProficiency.getWeaponProficiency(cid, equipped.id)
    local currentLevel = WeaponProficiency.getLevelByExperience(prof.exp)

    local perks = WeaponProficiency.getPerksForWeapon(equipped.id)
    for lvl = 1, currentLevel do
        local perkIndex = prof.perks[tostring(lvl)]
        if perkIndex and perks[lvl] and perks[lvl][perkIndex] then
            local perkBonus = perks[lvl][perkIndex].bonus
            for k, v in pairs(perkBonus) do
                if type(v) == "number" then
                    bonuses[k] = (bonuses[k] or 0) + v
                elseif type(v) == "boolean" then
                    bonuses[k] = v
                end
            end
        end
    end

    return bonuses
end

-- ============================================================
-- COMUNICACAO VIA EXTENDED OPCODE (188)
-- ============================================================

-- Envia estado completo de proficiencia para o client
function WeaponProficiency.sendData(cid)
    if not isPlayer(cid) then
        return
    end

    local equipped = WeaponProficiency.getEquippedWeapon(cid)
    local equippedPayload = nil

    if equipped then
        local prof = WeaponProficiency.getWeaponProficiency(cid, equipped.id)
        local currentLevel = WeaponProficiency.getLevelByExperience(prof.exp)
        local minExp = WeaponProficiency.LevelExperience[currentLevel] or 0
        local nextLevel = math.min(currentLevel + 1, WeaponProficiency.MAX_LEVEL)
        local maxExp = WeaponProficiency.LevelExperience[nextLevel] or minExp

        local percent = 100
        if currentLevel < WeaponProficiency.MAX_LEVEL and maxExp > minExp then
            local currentProgress = prof.exp - minExp
            local totalNeeded = maxExp - minExp
            percent = math.floor((currentProgress / totalNeeded) * 100)
            percent = math.max(0, math.min(100, percent))
        end

        local perksPayload = {}
        if prof.perks then
            for k, v in pairs(prof.perks) do
                perksPayload[tostring(k)] = v
            end
        end

        equippedPayload = {
            spriteId = equipped.clientId, -- Usando ItemType(id):getClientId() da regra
            name = equipped.name,
            category = equipped.category,
            level = currentLevel,
            maxLevel = WeaponProficiency.MAX_LEVEL,
            exp = prof.exp,
            minExp = minExp,
            maxExp = maxExp,
            percent = percent,
            perks = perksPayload
        }
    end

    -- Lista de todas as armas para o catalogo do client (todas as luvas)
    local weaponsPayload = {}
    local playerData = WeaponProficiency.loadPlayerData(cid)

    for _, itemId in ipairs(WeaponProficiency.GloveIds) do
        local winfo = WeaponProficiency.getWeaponInfo(itemId)
        if winfo then
            local prof = playerData[tostring(itemId)] or {exp = 0, level = 0, perks = {}}
            local lvl = WeaponProficiency.getLevelByExperience(prof.exp)
            local minExp = WeaponProficiency.LevelExperience[lvl] or 0
            local nextLvl = math.min(lvl + 1, WeaponProficiency.MAX_LEVEL)
            local maxExp = WeaponProficiency.LevelExperience[nextLvl] or minExp
            local percent = 100
            if lvl < WeaponProficiency.MAX_LEVEL and maxExp > minExp then
                local curP = prof.exp - minExp
                local totN = maxExp - minExp
                percent = math.floor((curP / totN) * 100)
                percent = math.max(0, math.min(100, percent))
            end

            local perksMap = {}
            if prof.perks then
                for pk, pv in pairs(prof.perks) do
                    perksMap[tostring(pk)] = pv
                end
            end

            table.insert(weaponsPayload, {
                id = itemId,
                clientId = winfo.clientId, -- ItemType(id):getClientId() da regra
                name = winfo.name,
                category = winfo.category,
                level = lvl,
                maxLevel = WeaponProficiency.MAX_LEVEL,
                exp = prof.exp,
                minExp = minExp,
                maxExp = maxExp,
                percent = percent,
                perks = perksMap
            })
        end
    end

    -- Se a arma atualmente equipada nao for uma das luvas padrao, inclui tambem
    if equipped then
        local found = false
        for _, w in ipairs(weaponsPayload) do
            if w.id == equipped.id then
                found = true
                break
            end
        end
        if not found then
            table.insert(weaponsPayload, 1, equippedPayload)
        end
    end

    local levelExpPayload = {}
    for lvl = 1, WeaponProficiency.MAX_LEVEL do
        table.insert(levelExpPayload, WeaponProficiency.LevelExperience[lvl] or 0)
    end

    local themesPayload = {}
    for themeKey, tree in pairs(WeaponProficiency.ThemeTrees) do
        themesPayload[themeKey] = WeaponProficiency.stripForClient(tree)
    end

    -- json.lua do TFS nao aceita chaves numericas esparsas; converte para string
    local weaponThemePayload = {}
    for itemId, themeKey in pairs(WeaponProficiency.GloveTheme) do
        weaponThemePayload[tostring(itemId)] = themeKey
    end

    local payload = {
        action = "sync",
        equipped = equippedPayload,
        weapons = weaponsPayload,
        maxLevel = WeaponProficiency.MAX_LEVEL,
        perksDefinition = WeaponProficiency.stripForClient(equipped and WeaponProficiency.getPerksForWeapon(equipped.id) or WeaponProficiency.Perks),
        themes = themesPayload,
        weaponTheme = weaponThemePayload,
        levelExp = levelExpPayload
    }

    local ok, jsonStr = pcall(json.encode, payload)
    if ok then
        doSendPlayerExtendedOpcode(cid, WEAPON_PROFICIENCY_OPCODE, jsonStr)
    else
        print(string.format("[WeaponProficiency] Erro ao codificar JSON para cid %s: %s", tostring(cid), tostring(jsonStr)))
    end
end

-- Handler de comandos recebidos pelo Extended Opcode
function WeaponProficiency.onOpcode(cid, buffer)
    if not isPlayer(cid) then
        return false
    end

    local ok, data = pcall(json.decode, buffer)
    if not ok or type(data) ~= "table" then
        -- Suporta requisicao em texto simples
        if buffer == "get" or buffer == "open" then
            WeaponProficiency.sendData(cid)
            return true
        end
        return false
    end

    local action = data.action

    if action == "request" or action == "get" or action == "open" then
        WeaponProficiency.sendData(cid)
        return true

    elseif action == "selectPerk" then
        local level = data.level
        local perkIndex = data.perkIndex
        local success, msg = WeaponProficiency.selectPerk(cid, level, perkIndex)
        
        local resp = {
            action = "selectResult",
            success = success,
            message = msg
        }
        doSendPlayerExtendedOpcode(cid, WEAPON_PROFICIENCY_OPCODE, json.encode(resp))
        return true
    end

    return false
end
