local spellInfos = {
    ["fire"] = 
        {
            {words = "Focus"}, {words = "Lightning"},
            {words = "Bomb"}, {words = "Clock"}, {words = "Thunderbolt"}, {words = "Meteor"},
            {words = "Striker"}, {words = "Overload"}, {words = "Explosion"}, {words = "Voltage"}, {words = "Thunderstorm"}, {words = "Discharge"}, {words = "Conflagration"}
        },

    ["water"] = 
        {
            -- Dobras de nome novo ja entram na lista ensinada pelos Mentores
            -- (pago com gold ou 1 bender scroll). "Wave" e' a Water Wave da
            -- spellbar (por dentro continua "whip", ver getFoldSlot) e
            -- "IceSpikes" e' a Water IceSpikes.
            {words = "Wave"}, {words = "IceSpikes"},
           {words = "BloodControl"},
            {words = "Punch"}, {words = "Dragon"}, {words = "Rain"}, {words = "Bubbles"}, {words = "Protect"},
            {words = "Icebolt"}, {words = "Flow"}, {words = "IceGolem"}, {words = "Tsunami"}, {words = "Clock"}, {words = "Blizzard"}, {words = "BloodBending"}
        },

    ["air"] = 
        {
            {words = "Suffocation"}, {words = "Hurricane"},
            {words = "Tempest"}, {words = "Windblast"}, {words = "Tornado"}, {words = "Barrier"}, {words = "Trap"}, 
            {words = "Doom"}, {words = "Bomb"}, {words = "Windstorm"}, {words = "Stormcall"}, {words = "Vortex"}, {words = "Deflection"}
        },

    ["earth"] = 
        {
           {words = "Control"}, {words = "Leech"},
            {words = "Smash"}, {words = "Ingrain"}, {words = "Fists"}, {words = "Arena"}, {words = "Curse"},
            {words = "Quake"}, {words = "Cataclysm"}, {words = "Aura"}, {words = "Armor"}, {words = "Lavaball"}, {words = "Metalwall"}
        }
}

-- Nome exibido da dobra: o MESMO nome que a spellbar mostra, lido direto da
-- spells.xml (ex: words "Icebolt" -> "Water IceBolt", "Wave" -> "Water Wave").
-- Assim o tutor ensina a dobra pelo nome que o jogador ve em jogo e o texto
-- acompanha qualquer rename futuro automaticamente.
function getFoldDisplayName(element, words)
    local info = getInstantSpellInfo(element.." "..words)
    if type(info) == "table" and info.name then
        return info.name
    end

    return element.." "..words
end

-- Ordem canonica da spellbar (a mesma dos arquivos 199-ServerToDll.lua).
local foldSlotTables = {
    fire = fireSpells,
    water = waterSpells,
    air = airSpells,
    earth = earthSpells
}

-- Nome interno -> palavra usada na lista ensinada. A dobra de level 1 da agua
-- aparece como "Water Wave" na spellbar, mas por dentro segue "whip" (chaves
-- de exaustao, som e pasta continuam as antigas).
local foldWordAliases = {
    water = {wave = "whip"}
}

-- Slot da dobra na spellbar, achado pelo NOME (nao pela posicao na lista
-- ensinada): assim a lista do NPC pode crescer/reordenar sem bagunçar os
-- marcadores "NPC" que o client recebe via "#j#<slot>;".
function getFoldSlot(element, words)
    local list = foldSlotTables[element]
    if type(list) ~= "table" then
        return nil
    end

    local word = words:lower()
    local alias = foldWordAliases[element] and foldWordAliases[element][word]
    if alias then
        word = alias
    end

    local target = (element..word):lower()
    for x = 1, #list do
        if list[x]:lower() == target then
            return x
        end
    end

    return nil
end

function getHasBuyAll(cid)
    local element = getPlayerElement(cid)
    local string = "#j#1;"
    if type(element) ~= "string" or not spellInfos[element] then
        return string
    end

    for x = 1, #spellInfos[element] do
        if hasFoldIsBuy(cid, element.." "..spellInfos[element][x].words:lower()) then
            local slot = getFoldSlot(element, spellInfos[element][x].words)
            if slot then
                string = string.."#j#"..slot..";"
            end
        end
    end

    return string
end

function refreshBuySpells(cid)
    local string = getHasBuyAll(cid)
    doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, string)
end

function hasFoldIsBuy(cid, words)
    return getPlayerStorageValue(cid, "hasBuy"..words) == 1
end

function setFoldBuy(cid, words)
    return doPlayerSetStorageValue(cid, "hasBuy"..words, 1)
end

function getFoldPrice(cid, words)
    local element = getPlayerElement(cid)
    local spells, words = spellInfos[element], words:lower()

    for x = 1, #spells do
        if spells[x].words:lower() == words then
            local info = getInstantSpellInfo(element.." "..words)
            local price = (1150*info.level)

            if getPlayerPremiumDays(cid) > 0 then --Desconto de 20%
                price = price-(price*0.2)
                price = math.ceil(price)
            end
            return price
        end
    end

    return false
end

function getListLearnFold(cid, organized, displayName)
    local level, element, string = getPlayerLevel(cid), getPlayerElement(cid), ""
    local spells, names = spellInfos[element], {}

    for x = 1, #spells do
        if not hasFoldIsBuy(cid, element.." "..spells[x].words:lower()) then
            if level >= getInstantSpellInfo(element.." "..spells[x].words).level then
                -- displayName = true: mostra "Water IceBolt" em vez de "Icebolt"
                local word = displayName and getFoldDisplayName(element, spells[x].words) or spells[x].words
                if not organized then
                    if string == "" then
                        string = word
                    else
                        string = string..", "..word
                    end
                else
                    table.insert(names, word)
                end
            end
        end
    end

    if not organized then
        return string
    else
        return orgazineStrings(names)
    end
end

local cf = {
id = 13848
}
local theStones = {12686, 12688, 12689, 12687}
function canBuyUltimateFold(cid, words, sequencia)
    local level, element = getPlayerLevel(cid), getPlayerElement(cid)
    local spells, words = spellInfos[element], words:lower()

    for x = 1, #spells do
        if spells[x].words:lower() == words then
            local info = getInstantSpellInfo(element.." "..words)

            if not hasFoldIsBuy(cid, element.." "..words) then
                if level >= info.level then
                    local reqStones = 2
					-- A ultima dobra da lista e' a "ultimate" (5 stones); as demais pedem 2.
					if sequencia == #spells or spells[x].words:lower() == spells[#spells].words:lower() then
						reqStones = 5
					end
					if (doPlayerRemoveItem(cid, theStones[getPlayerVocation(cid)], reqStones)) then
						setFoldBuy(cid, element.." "..words)

                        if spells[x].var then
                            setFoldBuy(cid, element.." "..spells[x].var:lower())
                        end

                        local foldName = getFoldDisplayName(element, spells[x].words)
                        sendBlueMessage(cid, getLangString(cid, "You've unlocked "..foldName.."!", "Voc� aprendeu a usar a dobra "..foldName.."!"))
                        refreshBuySpells(cid)
                        return true
                    else
                        return {"You don't have what takes to learn this bend.", "Voc� n�o tem o necess�rio para aprender esta dobra."}
                    end
                else
                    return {"Sorry, you need be level "..info.level.." or more to learn this bend.", "Desculpe, voc� precisa ter level "..info.level.." ou mais para aprender esta dobra."}
                end
            else
                return {"Sorry, you already learned this bend.", "Desculpe, voc� j� aprendeu essa dobra."}
            end

            break
        end
    end

    print("Error in canBuyFold in fold: "..words)
end

function canBuyFold(cid, words, tipo)
    local level, element = getPlayerLevel(cid), getPlayerElement(cid)
    local spells, words = spellInfos[element], words:lower()

    for x = 1, #spells do
        if spells[x].words:lower() == words then
            local info = getInstantSpellInfo(element.." "..words)

            if not hasFoldIsBuy(cid, element.." "..words) then
                if level >= info.level then
                    local price = getFoldPrice(cid, words)
					if (tipo == 1 and doPlayerRemoveMoney(cid, price)) or (tipo == 2 and doPlayerRemoveItem(cid, cf.id, 1)) then
                   -- if (tipo == 1 and x+1 < #spells and doPlayerRemoveMoney(cid, price)) or (tipo == 2 and x+1 < #spells and doPlayerRemoveItem(cid, cf.id, 1)) or (tipo == 2 and x < #spells and doPlayerRemoveItem(cid, cf.id, 2)) or (tipo == 2 and doPlayerRemoveItem(cid, cf.id, 3)) then
                        setFoldBuy(cid, element.." "..words)

                        if spells[x].var then
                            setFoldBuy(cid, element.." "..spells[x].var:lower())
                        end

                        local foldName = getFoldDisplayName(element, spells[x].words)
                        sendBlueMessage(cid, getLangString(cid, "You've unlocked "..foldName..".", "Voc� aprendeu a usar a dobra "..foldName.."."))
                        refreshBuySpells(cid)
                        return true
                    else
                        return {"You don't have money to learn this fold.", "Voc� n�o tem dinheiro ou bender scroll para aprender essa dobra."}
                    end
                else
                    return {"Sorry, you need be level "..info.level.." or more to buy this fold.", "Desculpe, voc� precisa ter level "..info.level.." ou mais para comprar essa dobra."}
                end
            else
                return {"Sorry, you already bought this fold.", "Desculpe, voc� j� comprou essa dobra."}
            end

            break
        end
    end

    print("Error in canBuyFold in fold: "..words)
end