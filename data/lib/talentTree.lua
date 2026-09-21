-- ============================================================
-- TALENT TREE SYSTEM - TFS Server-Side
-- ============================================================
-- Sistema de arvore de talentos por vocation.
-- Vocations: 1/5=Fire, 2/6=Water, 3/7=Air, 4/8=Earth
-- Ganha 1 ponto a partir do level 50 e a cada 25 leveis.
-- Comunicacao via Extended Opcode 222.
-- ============================================================

TalentTree = {}

-- Carrega JSON caso nao esteja disponivel
if type(json) ~= "table" then
    dofile(getDataDir() .. "lib/json.lua")
end

-- Carrega o sistema de passivas
if type(TalentPassives) ~= "table" then
    dofile(getDataDir() .. "lib/talentPassives.lua")
end

-- ============================================================
-- CONFIGURACAO
-- ============================================================

local TALENT_OPCODE      = 222
local STORAGE_POINTS     = 50000  -- pontos disponiveis
local STORAGE_LEARNED    = 50001  -- JSON dos talentos aprendidos
local STORAGE_LAST_LEVEL = 50002  -- ultimo level em que ganhou pontos

-- subId do ConditionAttributes usado pelos bonus de atributo (hp/mana/magic
-- level/shielding). TEM que ser diferente de 0: com subId 0 esse condition se
-- mistura com o de qualquer outro sistema que use CONDITION_ATTRIBUTES (pocoes,
-- comidas, ingrain...) e, como ConditionAttributes::addCondition() SUBSTITUI os
-- stats do condition existente (endCondition + memcpy), um apagava o outro.
local ATTR_SUBID         = 4242

local FIRST_POINT_LEVEL  = 50     -- primeiro ponto no level 50
local LEVEL_STEP         = 25     -- 1 ponto a cada 25 leveis adicionais

local RESET_GOLD_PER_TALENT = 5000  -- 5k por talento aprendido

-- Requisito de level por fila (row de baixo pra cima: 1=50 ... 5=200)
TalentTree.RowLevelReq = {
    [1] = 50,
    [2] = 75,
    [3] = 100,
    [4] = 150,
    [5] = 200,
}

-- Mapeamento de vocation para arvore (base + promoted)
local VOC_TREE = {
    [1] = "fire",   [5] = "fire",
    [2] = "water",  [6] = "water",
    [3] = "air",    [7] = "air",
    [4] = "earth",  [8] = "earth",
}

-- ============================================================
-- DEFINICAO DAS ARVORES DE TALENTOS
-- ============================================================

TalentTree.Talents = {

    -- ========================================================
    -- FIRE BENDER TREE (IDs 1-15)
    -- Col 1: Burn Passive & Power (Row 1-5)
    -- Col 2: CDR (Row 1-5, 6% cada = 30% max)
    -- Col 3: Flame Barrier / Armor (Row 1-5)
    -- ========================================================

    -- Col 1: Burn & Power
    [1] = {
        name   = "Scorching Touch I",
        desc   = "Attacks may burn the target for 0.5% max HP/s for 5s (20s CD, does not stack).",
        tree   = "fire",
        row    = 1, col = 1,
        req    = {},
        cost   = 1,
        effect = { type = "burnrank", value = 1 }
    },
    [2] = {
        name   = "Cauterize",
        desc   = "Increases your Magic Level by 3.",
        tree   = "fire",
        row    = 2, col = 1,
        req    = {1},
        cost   = 1,
        effect = { type = "magiclevel", value = 3 }
    },
    [3] = {
        name   = "Scorching Touch II",
        desc   = "Upgrades burn to deal 1.0% max HP/s for 5s (20s CD, does not stack).",
        tree   = "fire",
        row    = 3, col = 1,
        req    = {2},
        cost   = 1,
        effect = { type = "burnrank", value = 2 }
    },
    [4] = {
        name   = "Blazing Soul",
        desc   = "Increases your Magic Level by 5 and maximum Mana by 200.",
        tree   = "fire",
        row    = 4, col = 1,
        req    = {3},
        cost   = 1,
        -- mana vai no proprio efeito: antes era 200 fixo dentro do
        -- applySingleEffect, o que ignorava o valor do talento
        effect = { type = "grandarcane", value = 5, mana = 200 }
    },
    [5] = {
        name   = "Pyromancer's Dominance",
        desc   = "Increases your spell/bending damage by 10%.",
        tree   = "fire",
        row    = 5, col = 1,
        req    = {4},
        cost   = 1,
        effect = { type = "benddmg", value = 10 }
    },

    -- Col 2: CDR (Fire)
    [6] = {
        name   = "Swift Flames I",
        desc   = "Reduces your spell cooldowns by 6%.",
        tree   = "fire",
        row    = 1, col = 2,
        req    = {},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [7] = {
        name   = "Swift Flames II",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 12%).",
        tree   = "fire",
        row    = 2, col = 2,
        req    = {6},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [8] = {
        name   = "Swift Flames III",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 18%).",
        tree   = "fire",
        row    = 3, col = 2,
        req    = {7},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [9] = {
        name   = "Swift Flames IV",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 24%).",
        tree   = "fire",
        row    = 4, col = 2,
        req    = {8},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [10] = {
        name   = "Swift Flames V",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 30%).",
        tree   = "fire",
        row    = 5, col = 2,
        req    = {9},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },

    -- Col 3: Flame Barrier / Defense
    [11] = {
        name   = "Flame Barrier I",
        desc   = "Increases your maximum Health by 70.",
        tree   = "fire",
        row    = 1, col = 3,
        req    = {},
        cost   = 1,
        effect = { type = "maxhp", value = 70 }
    },
    [12] = {
        name   = "Molten Armor",
        desc   = "Increases your damage reduction armor by 4%.",
        tree   = "fire",
        row    = 2, col = 3,
        req    = {11},
        cost   = 1,
        effect = { type = "armor", value = 4 }
    },
    [13] = {
        name   = "Flame Barrier II",
        desc   = "Increases your maximum Health by 130.",
        tree   = "fire",
        row    = 3, col = 3,
        req    = {12},
        cost   = 1,
        effect = { type = "maxhp", value = 130 }
    },
    [14] = {
        name   = "Ash Shield",
        desc   = "Increases your damage reduction armor by 6%.",
        tree   = "fire",
        row    = 4, col = 3,
        req    = {13},
        cost   = 1,
        effect = { type = "armor", value = 6 }
    },
    [15] = {
        name   = "Inferno Bastion",
        desc   = "Increases your maximum Health by 220 and armor by 5%.",
        tree   = "fire",
        row    = 5, col = 3,
        req    = {14},
        cost   = 1,
        effect = { { type = "maxhp", value = 220 }, { type = "armor", value = 5 } }
    },

    -- ========================================================
    -- WATER BENDER TREE (IDs 21-35)
    -- Col 1: Heal Crit / Suporte (Exclui Col 3)
    -- Col 2: CDR (Row 1-5, 6% cada = 30% max)
    -- Col 3: Dano de Agua (Exclui Col 1)
    -- ========================================================

    -- Col 1: Suporte (Heal Crit)
    [21] = {
        name   = "Healing Waters I",
        desc   = "Your heals on allies have a 10% chance to critically heal for 50% more (no self-heal).",
        tree   = "water",
        row    = 1, col = 1,
        req    = {},
        cost   = 1,
        excludes = {31, 32, 33, 34, 35},
        effect = { type = "healcrit", value = 10 }
    },
    [22] = {
        name   = "Purifying Stream",
        desc   = "Increases your Magic Level by 3 and maximum Mana by 150.",
        tree   = "water",
        row    = 2, col = 1,
        req    = {21},
        cost   = 1,
        excludes = {31, 32, 33, 34, 35},
        effect = { type = "grandarcane", value = 3, mana = 150 }
    },
    [23] = {
        name   = "Healing Waters II",
        desc   = "Increases your ally healing critical chance to 20%.",
        tree   = "water",
        row    = 3, col = 1,
        req    = {22},
        cost   = 1,
        excludes = {31, 32, 33, 34, 35},
        effect = { type = "healcrit", value = 10 }
    },
    [24] = {
        name   = "Healing Waters III",
        desc   = "Increases your ally healing critical chance to 30%.",
        tree   = "water",
        row    = 4, col = 1,
        req    = {23},
        cost   = 1,
        excludes = {31, 32, 33, 34, 35},
        effect = { type = "healcrit", value = 10 }
    },
    [25] = {
        name   = "Ocean's Blessing",
        desc   = "Increases your maximum Health by 250.",
        tree   = "water",
        row    = 5, col = 1,
        req    = {24},
        cost   = 1,
        excludes = {31, 32, 33, 34, 35},
        effect = { type = "maxhp", value = 250 }
    },

    -- Col 2: CDR (Water)
    [26] = {
        name   = "Tidal Flow I",
        desc   = "Reduces your spell cooldowns by 6%.",
        tree   = "water",
        row    = 1, col = 2,
        req    = {},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [27] = {
        name   = "Tidal Flow II",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 12%).",
        tree   = "water",
        row    = 2, col = 2,
        req    = {26},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [28] = {
        name   = "Tidal Flow III",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 18%).",
        tree   = "water",
        row    = 3, col = 2,
        req    = {27},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [29] = {
        name   = "Tidal Flow IV",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 24%).",
        tree   = "water",
        row    = 4, col = 2,
        req    = {28},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [30] = {
        name   = "Tidal Flow V",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 30%).",
        tree   = "water",
        row    = 5, col = 2,
        req    = {29},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },

    -- Col 3: Dano de Agua (Water Offense)
    [31] = {
        name   = "Crushing Wave I",
        desc   = "Increases your spell/bending damage by 4%.",
        tree   = "water",
        row    = 1, col = 3,
        req    = {},
        cost   = 1,
        excludes = {21, 22, 23, 24, 25},
        effect = { type = "benddmg", value = 4 }
    },
    [32] = {
        name   = "Riptide",
        desc   = "Increases your Magic Level by 3.",
        tree   = "water",
        row    = 2, col = 3,
        req    = {31},
        cost   = 1,
        excludes = {21, 22, 23, 24, 25},
        effect = { type = "magiclevel", value = 3 }
    },
    [33] = {
        name   = "Crushing Wave II",
        desc   = "Increases your spell/bending damage by 6%.",
        tree   = "water",
        row    = 3, col = 3,
        req    = {32},
        cost   = 1,
        excludes = {21, 22, 23, 24, 25},
        effect = { type = "benddmg", value = 6 }
    },
    [34] = {
        name   = "Undertow Surge",
        desc   = "Increases your Magic Level by 5 and maximum Mana by 200.",
        tree   = "water",
        row    = 4, col = 3,
        req    = {33},
        cost   = 1,
        excludes = {21, 22, 23, 24, 25},
        effect = { type = "grandarcane", value = 5, mana = 200 }
    },
    [35] = {
        name   = "Abyssal Dominance",
        desc   = "Increases your spell/bending damage by 10% and maximum Health by 150.",
        tree   = "water",
        row    = 5, col = 3,
        req    = {34},
        cost   = 1,
        excludes = {21, 22, 23, 24, 25},
        effect = { { type = "benddmg", value = 10 }, { type = "maxhp", value = 150 } }
    },

    -- ========================================================
    -- AIR BENDER TREE (IDs 41-55)
    -- Col 1: Evasion / Esquiva de TODO Dano (Row 1-5)
    -- Col 2: CDR (Row 1-5, 6% cada = 30% max)
    -- Col 3: Dano de Ar (Air Offense)
    -- ========================================================

    -- Col 1: Esquiva
    [41] = {
        name   = "Gale Reflex I",
        desc   = "Grants a 5% chance to completely evade any incoming damage.",
        tree   = "air",
        row    = 1, col = 1,
        req    = {},
        cost   = 1,
        effect = { type = "dodge", value = 5 }
    },
    [42] = {
        name   = "Zephyr Stride",
        desc   = "Increases your Speed by 20.",
        tree   = "air",
        row    = 2, col = 1,
        req    = {41},
        cost   = 1,
        effect = { type = "speed", value = 20 }
    },
    [43] = {
        name   = "Gale Reflex II",
        desc   = "Increases your evasion chance to 10% total.",
        tree   = "air",
        row    = 3, col = 1,
        req    = {42},
        cost   = 1,
        effect = { type = "dodge", value = 5 }
    },
    [44] = {
        name   = "Wind Veil",
        desc   = "Increases your maximum Health by 120 and Speed by 15.",
        tree   = "air",
        row    = 4, col = 1,
        req    = {43},
        cost   = 1,
        effect = { { type = "maxhp", value = 120 }, { type = "speed", value = 15 } }
    },
    [45] = {
        name   = "Eye of the Hurricane",
        desc   = "Increases your Speed by 35 and armor by 5%.",
        tree   = "air",
        row    = 5, col = 1,
        req    = {44},
        cost   = 1,
        effect = { { type = "speed", value = 35 }, { type = "armor", value = 5 } }
    },

    -- Col 2: CDR (Air)
    [46] = {
        name   = "Wind Step I",
        desc   = "Reduces your spell cooldowns by 6%.",
        tree   = "air",
        row    = 1, col = 2,
        req    = {},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [47] = {
        name   = "Wind Step II",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 12%).",
        tree   = "air",
        row    = 2, col = 2,
        req    = {46},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [48] = {
        name   = "Wind Step III",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 18%).",
        tree   = "air",
        row    = 3, col = 2,
        req    = {47},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [49] = {
        name   = "Wind Step IV",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 24%).",
        tree   = "air",
        row    = 4, col = 2,
        req    = {48},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [50] = {
        name   = "Wind Step V",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 30%).",
        tree   = "air",
        row    = 5, col = 2,
        req    = {49},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },

    -- Col 3: Dano de Ar
    [51] = {
        name   = "Razor Wind I",
        desc   = "Increases your spell/bending damage by 4%.",
        tree   = "air",
        row    = 1, col = 3,
        req    = {},
        cost   = 1,
        effect = { type = "benddmg", value = 4 }
    },
    [52] = {
        name   = "Gust Surge",
        desc   = "Increases your Magic Level by 3.",
        tree   = "air",
        row    = 2, col = 3,
        req    = {51},
        cost   = 1,
        effect = { type = "magiclevel", value = 3 }
    },
    [53] = {
        name   = "Razor Wind II",
        desc   = "Increases your spell/bending damage by 6%.",
        tree   = "air",
        row    = 3, col = 3,
        req    = {52},
        cost   = 1,
        effect = { type = "benddmg", value = 6 }
    },
    [54] = {
        name   = "Tempest Force",
        desc   = "Increases your Magic Level by 5 and maximum Mana by 150.",
        tree   = "air",
        row    = 4, col = 3,
        req    = {53},
        cost   = 1,
        effect = { type = "grandarcane", value = 5, mana = 150 }
    },
    [55] = {
        name   = "Storm Unleashed",
        desc   = "Increases your spell/bending damage by 10%.",
        tree   = "air",
        row    = 5, col = 3,
        req    = {54},
        cost   = 1,
        effect = { type = "benddmg", value = 10 }
    },

    -- ========================================================
    -- EARTH BENDER TREE (IDs 61-75)
    -- Col 1: Tank (HP + Armor + Shielding) - Exclui Col 3
    -- Col 2: CDR (Row 1-5, 6% cada = 30% max)
    -- Col 3: Dano (25% mais vantajoso em atributos) - Exclui Col 1
    -- ========================================================

    -- Col 1: Tank Path
    [61] = {
        name   = "Iron Fortress I",
        desc   = "Increases your maximum Health by 100.",
        tree   = "earth",
        row    = 1, col = 1,
        req    = {},
        cost   = 1,
        excludes = {71, 72, 73, 74, 75},
        effect = { type = "maxhp", value = 100 }
    },
    [62] = {
        name   = "Stone Barrier",
        desc   = "Increases your Shielding skill by 5.",
        tree   = "earth",
        row    = 2, col = 1,
        req    = {61},
        cost   = 1,
        excludes = {71, 72, 73, 74, 75},
        effect = { type = "shielding", value = 5 }
    },
    [63] = {
        name   = "Iron Fortress II",
        desc   = "Increases your damage reduction armor by 5%.",
        tree   = "earth",
        row    = 3, col = 1,
        req    = {62},
        cost   = 1,
        excludes = {71, 72, 73, 74, 75},
        effect = { type = "armor", value = 5 }
    },
    [64] = {
        name   = "Bedrock Skin",
        desc   = "Increases your maximum Health by 180 and Shielding skill by 4.",
        tree   = "earth",
        row    = 4, col = 1,
        req    = {63},
        cost   = 1,
        excludes = {71, 72, 73, 74, 75},
        effect = { { type = "maxhp", value = 180 }, { type = "shielding", value = 4 } }
    },
    [65] = {
        name   = "Mountain's Heart",
        desc   = "Pinnacle of defense: +8% armor and +8 Shielding skill.",
        tree   = "earth",
        row    = 5, col = 1,
        req    = {64},
        cost   = 1,
        excludes = {71, 72, 73, 74, 75},
        effect = { { type = "armor", value = 8 }, { type = "shielding", value = 8 } }
    },

    -- Col 2: CDR (Earth)
    [66] = {
        name   = "Stone Wall I",
        desc   = "Reduces your spell cooldowns by 6%.",
        tree   = "earth",
        row    = 1, col = 2,
        req    = {},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [67] = {
        name   = "Stone Wall II",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 12%).",
        tree   = "earth",
        row    = 2, col = 2,
        req    = {66},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [68] = {
        name   = "Stone Wall III",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 18%).",
        tree   = "earth",
        row    = 3, col = 2,
        req    = {67},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [69] = {
        name   = "Stone Wall IV",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 24%).",
        tree   = "earth",
        row    = 4, col = 2,
        req    = {68},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },
    [70] = {
        name   = "Stone Wall V",
        desc   = "Reduces your spell cooldowns by an additional 6% (total 30%).",
        tree   = "earth",
        row    = 5, col = 2,
        req    = {69},
        cost   = 1,
        effect = { type = "cooldownreduction", value = 6 }
    },

    -- Col 3: Damage Path (25% mais vantajoso em atributos)
    [71] = {
        name   = "Seismic Force I",
        desc   = "Increases your spell/bending damage by 6% and Magic Level by 3.",
        tree   = "earth",
        row    = 1, col = 3,
        req    = {},
        cost   = 1,
        excludes = {61, 62, 63, 64, 65},
        effect = { { type = "benddmg", value = 6 }, { type = "magiclevel", value = 3 } }
    },
    [72] = {
        name   = "Tectonic Strike",
        desc   = "Increases your Magic Level by 4.",
        tree   = "earth",
        row    = 2, col = 3,
        req    = {71},
        cost   = 1,
        excludes = {61, 62, 63, 64, 65},
        effect = { type = "magiclevel", value = 4 }
    },
    [73] = {
        name   = "Seismic Force II",
        desc   = "Increases your spell/bending damage by 8%.",
        tree   = "earth",
        row    = 3, col = 3,
        req    = {72},
        cost   = 1,
        excludes = {61, 62, 63, 64, 65},
        effect = { type = "benddmg", value = 8 }
    },
    [74] = {
        name   = "Earth Crusher",
        desc   = "Increases your Magic Level by 6 and maximum Mana by 200.",
        tree   = "earth",
        row    = 4, col = 3,
        req    = {73},
        cost   = 1,
        excludes = {61, 62, 63, 64, 65},
        effect = { type = "grandarcane", value = 6, mana = 200 }
    },
    [75] = {
        name   = "Titan's Wrath",
        desc   = "Master offensive talent: +12% damage and +100 maximum Health.",
        tree   = "earth",
        row    = 5, col = 3,
        req    = {74},
        cost   = 1,
        excludes = {61, 62, 63, 64, 65},
        effect = { type = "benddmg", value = 12 }
    },
}

-- ============================================================
-- HELPERS DE STORAGE
-- ============================================================

function TalentTree.getLearnedTalents(cid)
    local raw = getPlayerStorageValue(cid, STORAGE_LEARNED)
    if type(raw) ~= "string" or raw == "" or raw == "-1" then
        return {}
    end
    local ok, tbl = pcall(json.decode, raw)
    if ok and type(tbl) == "table" then
        -- Valida que todos os IDs sao numeros validos da arvore
        local clean = {}
        for _, id in ipairs(tbl) do
            if type(id) == "number" and TalentTree.Talents[id] then
                clean[#clean + 1] = id
            end
        end
        -- Se o resultado limpado difere do original, corrige a storage
        if #clean ~= #tbl then
            TalentTree.saveLearnedTalents(cid, clean)
        end
        return clean
    end
    -- Storage corrompida: limpa
    setPlayerStorageValue(cid, STORAGE_LEARNED, "")
    return {}
end

function TalentTree.saveLearnedTalents(cid, learned)
    local ok, encoded = pcall(json.encode, learned)
    if ok then
        setPlayerStorageValue(cid, STORAGE_LEARNED, encoded)
    end
end

function TalentTree.getAvailablePoints(cid)
    local pts = getPlayerStorageValue(cid, STORAGE_POINTS)
    if type(pts) ~= "number" or pts < 0 then return 0 end
    return pts
end

function TalentTree.setAvailablePoints(cid, pts)
    setPlayerStorageValue(cid, STORAGE_POINTS, math.max(0, pts))
end

function TalentTree.isLearned(learned, talentId)
    for _, id in ipairs(learned) do
        if id == talentId then return true end
    end
    return false
end

-- ============================================================
-- APLICAR / REMOVER EFEITO DE UM TALENTO
-- ============================================================

-- ============================================================
-- VELOCIDADE: so' o pedaco dos TALENTOS (fonte "talents")
-- ------------------------------------------------------------
-- doChangeSpeed deste fork e ADITIVO (varSpeed += delta) e o varSpeed e' um
-- acumulador COMPARTILHADO: conditions de haste/paralise e slows temporarios
-- de spell escrevem nele tambem.
--
-- O rebuild antigo montava a velocidade total e chamava
-- doChangeSpeed(desired - cur) - ou seja, APAGAVA o pedaco das conditions.
-- A partir dai' era so' perder a corrida: quando o condition terminasse, o
-- engine subtraia o delta dele de novo e o personagem ficava abaixo da base
-- (servidor cancela a walk = "paralisado") ate' o proximo rebuild.
--
-- Agora os talentos sao uma fonte em PlayerSpeed (data/lib/248-playerSpeed.lua):
-- so' a diferenca do proprio valor de talento e' aplicada, montaria/agilidade
-- tem as fontes delas e o que e' temporario (haste, slow, bomberman) fica
-- intocado no acumulador.
-- ============================================================
function TalentTree.rebuildSpeed(cid)
    if not isPlayer(cid) then return end

    local bonus = 0
    for _, id in ipairs(TalentTree.getLearnedTalents(cid)) do
        local talent = TalentTree.Talents[id]
        if talent and type(talent.effect) == "table" then
            local list = talent.effect
            if type(list.type) == "string" then list = { list } end
            for _, eff in ipairs(list) do
                if eff.type == "speed" and type(eff.value) == "number" then
                    bonus = bonus + eff.value
                end
            end
        end
    end

    -- Agilidade e montaria continuam vindo de PlayerSpeed.refreshFromStorages
    -- (chamada no login/relogin), cada uma como sua propria fonte.
    if type(PlayerSpeed) == "table" and PlayerSpeed.setSource then
        PlayerSpeed.setSource(cid, "talents", bonus)
    else
        -- Sem a lib, NAO cai pro comportamento antigo (que apagava o delta dos
        -- outros): avisa e para. Barulhento de proposito.
        print("[TalentTree] PlayerSpeed nao carregou; bonus de velocidade dos talentos nao aplicado.")
    end
end

-- ----------------------------------------------------------------------------
-- BONUS DE ATRIBUTO: um unico ConditionAttributes para TODOS os talentos
-- ----------------------------------------------------------------------------
-- Antes cada talento de hp/mana/magic level/shielding criava o seu proprio
-- ConditionAttributes. Todos usam CONDITIONID_COMBAT + subId 0, entao o segundo
-- talento caia no merge de ConditionAttributes::addCondition(), que chama
-- endCondition() (tirando os stats do condition anterior) e depois copia os
-- novos por cima: com mais de um talento do mesmo tipo, so' o ultimo valia
-- (ex: +70 e +130 de HP davam +130 em vez de +200). Pior: o merge tambem
-- acontecia com conditions de OUTROS sistemas (pocao/mastermind, carrot cake,
-- ingrain, demonic candy ball...), que usam o mesmo condition id/subId -
-- qualquer um dos dois lados apagava os stats do outro.
--
-- Agora os valores sao somados e aplicados num unico condition com subId
-- proprio: aplicar de novo SUBSTITUI o anterior (nunca acumula) e o que os
-- outros sistemas fazem nao mexe mais nos talentos (nem o contrario).
local TALENT_ATTR_EFFECTS = {
    maxhp      = "hp",
    maxmana    = "mana",
    magiclevel = "ml",
    shielding  = "shield",
}

local function eachEffect(talent, fn)
    local list = talent and talent.effect
    if type(list) ~= "table" then return end
    if type(list.type) == "string" then list = { list } end
    for _, eff in ipairs(list) do
        if type(eff) == "table" and type(eff.type) == "string" then
            fn(eff)
        end
    end
end

local function firstEffectType(talent)
    local found = ""
    eachEffect(talent, function(eff)
        if found == "" then found = eff.type end
    end)
    return found
end

-- Tira o condition de atributos dos talentos (idempotente)
function TalentTree.clearAttributes(cid)
    if not isPlayer(cid) then return end
    doRemoveCondition(cid, CONDITION_ATTRIBUTES, ATTR_SUBID)
end

-- Reconstroi o condition unico a partir dos talentos aprendidos. Roda no login,
-- no learn e no reset: e' sempre "tira o antigo e poe o total de agora", entao
-- nunca acumula nem deixa valor pendurado de uma sessao anterior (relog sem
-- deslogar reaproveita o MESMO objeto de Player: os conditions antigos
-- continuam la' quando o script roda de novo).
function TalentTree.applyAttributes(cid)
    if not isPlayer(cid) then return end

    TalentTree.clearAttributes(cid)

    local acc = { hp = 0, mana = 0, ml = 0, shield = 0 }
    for _, id in ipairs(TalentTree.getLearnedTalents(cid)) do
        local talent = TalentTree.Talents[id]
        eachEffect(talent, function(eff)
            local key = TALENT_ATTR_EFFECTS[eff.type]
            if key then
                acc[key] = acc[key] + (tonumber(eff.value) or 0)
            elseif eff.type == "grandarcane" then
                acc.ml   = acc.ml + (tonumber(eff.value) or 0)
                acc.mana = acc.mana + (tonumber(eff.mana) or 200)
            end
        end)
    end

    if (acc.hp + acc.mana + acc.ml + acc.shield) <= 0 then return end

    -- ATENCAO ao 4o/3o argumento = false abaixo: esta condition nasce AQUI, em
    -- tempo de jogo, e vai pro m_tempConditionMap. Sem o false, o
    -- setConditionParam/doAddCondition procuram no mapa de CARGA
    -- (getConditionObject(id, loaded=true)) e o uid colide: nos dois mapas o
    -- contador comeca do zero, entao o uid 1 daqui e' o uid 1 da carga - que e'
    -- a paralyzeCondition de data/lib/050-function.lua:1566. Resultado: o
    -- talento nao dava os atributos e ainda aplicava uma PARALISE de -0.9 da
    -- base com ticks=-1 (infinita, so' saia com relogin).
    local cond = createConditionObject(CONDITION_ATTRIBUTES, -1, false, ATTR_SUBID)
    if not cond then return end
    setConditionParam(cond, CONDITION_PARAM_TICKS, -1, false)
    if acc.hp     > 0 then setConditionParam(cond, CONDITION_PARAM_STAT_MAXHEALTH, acc.hp, false) end
    if acc.mana   > 0 then setConditionParam(cond, CONDITION_PARAM_STAT_MAXMANA, acc.mana, false) end
    if acc.ml     > 0 then setConditionParam(cond, CONDITION_PARAM_STAT_MAGICLEVEL, acc.ml, false) end
    if acc.shield > 0 then setConditionParam(cond, CONDITION_PARAM_SKILL_SHIELD, acc.shield, false) end
    doAddCondition(cid, cond, false)
end

-- Aplica/remove UM efeito simples. Speed e' tratada a parte (rebuildSpeed) e os
-- bonus de atributo tambem (TalentTree.applyAttributes) - os que sobram aqui sao
-- storages e passivas.
local function applySingleEffect(cid, effect, remove)
    local mult = remove and -1 or 1
    local t = effect.type

    if t == "armor" then
        local cur = getPlayerStorageValue(cid, "talentArmorBonus")
        if type(cur) ~= "number" or cur < 0 then cur = 0 end
        setPlayerStorageValue(cid, "talentArmorBonus", cur + (effect.value * mult))

    elseif t == "benddmg" then
        local cur = getPlayerStorageValue(cid, "talentBendDmgBonus")
        if type(cur) ~= "number" or cur < 0 then cur = 0 end
        setPlayerStorageValue(cid, "talentBendDmgBonus", cur + (effect.value * mult))

    elseif t == "cooldownreduction" or t == "dodge" or t == "burnrank" or t == "healcrit" then
        TalentPassives.applyEffect(cid, t, effect.value, remove)
    end
end

-- Aplica/remove os efeitos de um talento. talent.effect pode ser uma tabela
-- unica OU um array de efeitos (ex: talento 44 "Wind Veil" = maxhp + speed).
-- Speed nunca e adicionada/removida como delta solto: sempre reconstruida.
local function applyTalentEffect(cid, talent, remove)
    local effectList = talent.effect
    if type(effectList) ~= "table" then return end
    if type(effectList.type) == "string" then
        effectList = { effectList }
    end

    local hasSpeed = false
    for _, eff in ipairs(effectList) do
        if eff and eff.type == "speed" then hasSpeed = true end
    end
    if hasSpeed then
        TalentTree.rebuildSpeed(cid)
    end

    for _, eff in ipairs(effectList) do
        -- atributos (maxhp/maxmana/magiclevel/shielding/grandarcane) NAO passam
        -- por aqui: eles sao somados e aplicados de uma vez por applyAttributes
        if eff and eff.type ~= "speed" and not TALENT_ATTR_EFFECTS[eff.type]
           and eff.type ~= "grandarcane" then
            applySingleEffect(cid, eff, remove)
        end
    end
end

-- ============================================================
-- REAPLICA TODOS OS TALENTOS NO LOGIN
-- ============================================================

function TalentTree.reapplyAll(cid)
    local learned = TalentTree.getLearnedTalents(cid)
    setPlayerStorageValue(cid, "talentBendDmgBonus", 0)
    setPlayerStorageValue(cid, "talentArmorBonus", 0)
    TalentPassives.resetAll(cid)
    for _, id in ipairs(learned) do
        local talent = TalentTree.Talents[id]
        if talent then
            applyTalentEffect(cid, talent, false)
        end
    end
    -- um unico condition com o TOTAL de hp/mana/magic level/shielding
    TalentTree.applyAttributes(cid)
    -- Auto-recuperacao: corrige qualquer speed corrompida na sessao anterior
    TalentTree.rebuildSpeed(cid)
end

-- ============================================================
-- SINCRONIZAR PONTOS PELO LEVEL ATUAL
-- Calcula quantos pontos o player deveria ter ganho ate o level
-- atual, subtrai os gastos, e corrige a storage.
-- ============================================================

function TalentTree.calcTotalPointsByLevel(level)
    if level < FIRST_POINT_LEVEL then return 0 end
    -- 1 ponto no level 50, depois +1 a cada LEVEL_STEP
    local count = 0
    local lv = FIRST_POINT_LEVEL
    while lv <= level do
        count = count + 1
        lv = lv + LEVEL_STEP
    end
    return count
end

function TalentTree.syncPoints(cid)
    if not isPlayer(cid) then return end
    local level       = getPlayerLevel(cid)
    local totalEarned = TalentTree.calcTotalPointsByLevel(level)

    -- Conta quantos pontos foram gastos (talentos aprendidos)
    local learned    = TalentTree.getLearnedTalents(cid)
    local totalSpent = 0
    for _, id in ipairs(learned) do
        local talent = TalentTree.Talents[id]
        if talent then
            totalSpent = totalSpent + (talent.cost or 1)
        end
    end

    -- Deteccao de adulteracao: pontos disponiveis + gastos > total ganho pelo level
    local storedPoints = getPlayerStorageValue(cid, STORAGE_POINTS)
    if type(storedPoints) ~= "number" or storedPoints < 0 then
        storedPoints = 0
    end

    local totalClaimed = storedPoints + totalSpent
    if totalClaimed > totalEarned then
        -- Inconsistencia detectada: reseta talentos e recalcula do zero
        print(string.format("[TalentTree] INTEGRITY FAIL for cid=%d: claimed=%d > earned=%d. Resetting.",
            cid, totalClaimed, totalEarned))
        setPlayerStorageValue(cid, STORAGE_LEARNED, "")
        setPlayerStorageValue(cid, "talentBendDmgBonus", 0)
        setPlayerStorageValue(cid, "talentArmorBonus", 0)
        TalentPassives.resetAll(cid)
        TalentTree.clearAttributes(cid)
        TalentTree.rebuildSpeed(cid)
        -- Recalcula com zero gastos
        totalSpent = 0
    end

    local correct = math.max(0, totalEarned - totalSpent)
    TalentTree.setAvailablePoints(cid, correct)
    setPlayerStorageValue(cid, STORAGE_LAST_LEVEL, level)
end

-- ============================================================
-- GANHAR PONTOS POR LEVEL (Lv 50 primeiro, depois +1 a cada 25 lv)
-- ============================================================

function TalentTree.onLevelUp(cid, newLevel)
    if not isPlayer(cid) then return end
    local lastAwarded = getPlayerStorageValue(cid, STORAGE_LAST_LEVEL)
    if type(lastAwarded) ~= "number" or lastAwarded < 0 then
        lastAwarded = 0
    end

    local gained = 0
    local startLv = math.max(FIRST_POINT_LEVEL, lastAwarded + 1)
    for lv = startLv, newLevel do
        if (lv - FIRST_POINT_LEVEL) % LEVEL_STEP == 0 then
            gained = gained + 1
        end
    end

    if gained > 0 then
        local cur = TalentTree.getAvailablePoints(cid)
        TalentTree.setAvailablePoints(cid, cur + gained)
        setPlayerStorageValue(cid, STORAGE_LAST_LEVEL, newLevel)
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
            string.format("[Talent Tree] You gained %d talent point(s)! Total: %d.", gained, cur + gained))
    else
        setPlayerStorageValue(cid, STORAGE_LAST_LEVEL, newLevel)
    end
end

-- ============================================================
-- ENVIAR DADOS AO CLIENT
-- ============================================================

function TalentTree.sendData(cid)
    if not isPlayer(cid) then return end

    -- Garante que os pontos estao sincronizados com o level atual
    TalentTree.syncPoints(cid)

    local learned = TalentTree.getLearnedTalents(cid)
    local points  = TalentTree.getAvailablePoints(cid)

    local voc     = getPlayerVocation(cid)
    local vocTree = VOC_TREE[voc] or "fire"

    local talentList = {}
    for id, talent in pairs(TalentTree.Talents) do
        if talent.tree == vocTree then
            talentList[#talentList + 1] = {
                id         = id,
                learned    = TalentTree.isLearned(learned, id),
                name       = talent.name,
                desc       = talent.desc,
                tree       = talent.tree,
                row        = talent.row,
                col        = talent.col,
                req        = talent.req,
                cost       = talent.cost,
                excludes   = talent.excludes or {},
                minLevel   = talent.minLevel or (TalentTree.RowLevelReq[talent.row] or 1),
                effectType = firstEffectType(talent),
            }
        end
    end

    local level     = getPlayerLevel(cid)
    local resetCost = (level > 50) and (RESET_GOLD_PER_TALENT * #learned) or 0

    local ok, encoded = pcall(json.encode, {
        action     = "data",
        points     = points,
        level      = level,
        vocTree    = vocTree,
        talents    = talentList,
        resetCost  = resetCost,
        learnedCnt = #learned,
    })

    if ok then
        doSendPlayerExtendedOpcode(cid, TALENT_OPCODE, encoded)
    end
end

-- ============================================================
-- APRENDER UM TALENTO
-- ============================================================

function TalentTree.learnTalent(cid, talentId)
    if not isPlayer(cid) then return end

    local talent = TalentTree.Talents[talentId]
    if not talent then
        doSendPlayerExtendedOpcode(cid, TALENT_OPCODE, json.encode({
            action = "error", msg = "Unknown talent."
        }))
        return
    end

    local voc     = getPlayerVocation(cid)
    local vocTree = VOC_TREE[voc] or "fire"
    if talent.tree ~= vocTree then
        doSendPlayerExtendedOpcode(cid, TALENT_OPCODE, json.encode({
            action = "error", msg = "This talent does not belong to your vocation."
        }))
        return
    end

    -- Verifica level minimo da row
    local minLevel = talent.minLevel or (TalentTree.RowLevelReq[talent.row] or 1)
    if getPlayerLevel(cid) < minLevel then
        doSendPlayerExtendedOpcode(cid, TALENT_OPCODE, json.encode({
            action = "error", msg = string.format("You must be at least level %d to learn this talent.", minLevel)
        }))
        return
    end

    -- Sincroniza pontos ANTES de checar disponibilidade
    TalentTree.syncPoints(cid)

    local learned = TalentTree.getLearnedTalents(cid)

    -- Ja aprendeu
    if TalentTree.isLearned(learned, talentId) then
        doSendPlayerExtendedOpcode(cid, TALENT_OPCODE, json.encode({
            action = "error", msg = "Talent already learned."
        }))
        return
    end

    -- Verifica exclusoes mutuas
    if talent.excludes then
        for _, exId in ipairs(talent.excludes) do
            if TalentTree.isLearned(learned, exId) then
                doSendPlayerExtendedOpcode(cid, TALENT_OPCODE, json.encode({
                    action = "error", msg = "You have already chosen the opposite path. Reset your talents to change."
                }))
                return
            end
        end
    end

    -- Verifica requisitos (Requires)
    for _, reqId in ipairs(talent.req or {}) do
        if not TalentTree.isLearned(learned, reqId) then
            doSendPlayerExtendedOpcode(cid, TALENT_OPCODE, json.encode({
                action = "error", msg = "You must learn the required talent first."
            }))
            return
        end
    end

    -- Verifica pontos
    local pts = TalentTree.getAvailablePoints(cid)
    if pts < talent.cost then
        doSendPlayerExtendedOpcode(cid, TALENT_OPCODE, json.encode({
            action = "error", msg = string.format("Not enough talent points. Need %d, have %d.", talent.cost, pts)
        }))
        return
    end

    learned[#learned + 1] = talentId
    TalentTree.saveLearnedTalents(cid, learned)
    TalentTree.setAvailablePoints(cid, pts - talent.cost)
    applyTalentEffect(cid, talent, false)
    -- o talento novo entra no condition unico de atributos
    TalentTree.applyAttributes(cid)

    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
        string.format("[Talent Tree] You learned \"%s\"!", talent.name))

    TalentTree.sendData(cid)
end

-- ============================================================
-- RESETAR TALENTOS
-- ============================================================

function TalentTree.resetTalents(cid)
    if not isPlayer(cid) then return end

    local level   = getPlayerLevel(cid)
    local learned = TalentTree.getLearnedTalents(cid)

    -- Custo: 5000 gold por talento aprendido (so acima do level 50)
    local resetCost = 0
    if level > 50 then
        resetCost = RESET_GOLD_PER_TALENT * #learned
    end

    if resetCost > 0 then
        if getPlayerMoney(cid) < resetCost then
            doSendPlayerExtendedOpcode(cid, TALENT_OPCODE, json.encode({
                action = "error",
                msg    = string.format("Resetting talents costs %d gold (%d talent(s) x 5,000g). You don't have enough.",
                    resetCost, #learned)
            }))
            return
        end
        doPlayerRemoveMoney(cid, resetCost)
    end

    -- Limpa tudo (incluindo o condition de atributos: sem isso o +hp/+ml dos
    -- talentos continuava valendo depois do reset ate' dar relog)
    setPlayerStorageValue(cid, STORAGE_LEARNED, "")
    setPlayerStorageValue(cid, "talentBendDmgBonus", 0)
    setPlayerStorageValue(cid, "talentArmorBonus", 0)
    TalentPassives.resetAll(cid)
    TalentTree.clearAttributes(cid)

    -- Reconstroi a velocidade sem os bonus de talento (nunca remover delta as cegas)
    TalentTree.rebuildSpeed(cid)

    -- Recalcula pontos do zero baseado no level (sem gastos)
    local totalEarned = TalentTree.calcTotalPointsByLevel(level)
    TalentTree.setAvailablePoints(cid, totalEarned)
    setPlayerStorageValue(cid, STORAGE_LAST_LEVEL, level)

    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
        string.format("[Talent Tree] Your talents have been reset. %d point(s) available.", totalEarned))

    TalentTree.sendData(cid)
end

-- ============================================================
-- HANDLER DO OPCODE 222 (chamado pelo opcode.lua)
-- ============================================================

function TalentTree.onOpcode(cid, buffer)
    if not isPlayer(cid) then return end

    local ok, data = pcall(json.decode, buffer)
    if not ok or type(data) ~= "table" then
        TalentTree.sendData(cid)
        return
    end

    if data.action == "request" then
        TalentTree.sendData(cid)
    elseif data.action == "costinfo" then
        -- Retorna o custo atual de reset para o client exibir no dialogo
        local learned   = TalentTree.getLearnedTalents(cid)
        local level     = getPlayerLevel(cid)
        local resetCost = (level > 50) and (RESET_GOLD_PER_TALENT * #learned) or 0
        local ok2, enc = pcall(json.encode, {
            action    = "costinfo",
            resetCost = resetCost,
            learned   = #learned,
        })
        if ok2 then
            doSendPlayerExtendedOpcode(cid, TALENT_OPCODE, enc)
        end
    elseif data.action == "learn" then
        TalentTree.learnTalent(cid, tonumber(data.talentId))
    elseif data.action == "reset" then
        TalentTree.resetTalents(cid)
    end
end
