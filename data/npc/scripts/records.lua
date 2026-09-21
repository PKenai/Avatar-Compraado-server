local miniGames = {"Zumbi Snake", "Shooting The Bird", "Kill The Beast Easy", 
"Kill The Beast Medium", "Find The Doll", "Death Arena", "All Mini Games"}

local miniGamesInfo = {
    {consulta = "DESC", another = "bodies"}, {consulta = "DESC", another = "birds"},
    {consulta = "ASC", another = "seconds"}, {consulta = "ASC", another = "seconds"},
    {consulta = "ASC", another = "seconds"}, {consulta = "DESC", another = "gold coins"},
    {consulta = "DESC", another = ""}

}

local function doPlayerReceiveRewards(cid, rank)
    if rank == "global" then
        setMiniGameRank(cid, "All Mini Games", os.date("%d")..os.date("%m")..os.date("%y"))
        setPlayerStorageValue(cid, "challengeGlobalNpcLockeFinish", 1)
    end
end

local npcGen = newNpc("recordsNpc")

npcGen:setFuncStart(function(cid)
    local playerPos, lang = getThingPos(cid), getLang(cid)

    if getThingfromPos({x=playerPos.x, y=playerPos.y, z=playerPos.z, stackpos = 0}).itemid ~= 12707 then
        npcGen:say("Please enter my room first.", "Please enter my room first.", lang)
        return false
    end

    npcGen:say("Hello "..getCreatureName(cid).."! I've written down on my blackboards all the RECORDS of every mini game. I also have some CHALLENGES available.", "Hello "..getCreatureName(cid).."! I've written down on my blackboards all the RECORDS of every mini game. I also have some CHALLENGES available.", lang)
    return true
end)

npcGen:addOptionInNpc("help", {"I don't need your help, thanks.", "I don't need your help, thanks."})
npcGen:addOptionInNpc("records", {"You want to see the records of which mini-game, I've records of: "..orgazineStrings(miniGames)..".", "You want to see the records of which mini-game, I've records of: "..orgazineStrings(miniGames).."."})
npcGen:addOptionInNpc("challenge", {"Sorry, I don't have any challenge right now.", "Sorry, I don't have any challenge right now."})

function onCreatureSay(cid, type, msg)
    local msg = msg:lower()
    npcGen:onSay(cid, type, msg, 
    function(stage)
        if stage == 1 then
            for x = 1, #miniGames do
                if msgcontains(msg, string.lower(miniGames[x])) then
                    npcGen:say("You want to see GLOBAL records or your PERSONAL records, of this game?", "You want to see GLOBAL records or your PERSONAL records, of this game?")
                    npcGen:setStorage("getMinigame", x)
                    npcGen:setStage(2)
                    return true
                end
            end

        elseif stage == 2 then
            if msgcontains(msg, "personal") or msgcontains(msg, "individual") then
                npcGen:say("Let me look ... Here, read this part of blackboard.", "Let me look ... Here, read this part of blackboard.")
                getMiniGameRank(cid, miniGames[npcGen:getStorage("getMinigame")], miniGamesInfo[npcGen:getStorage("getMinigame")].consulta, miniGamesInfo[npcGen:getStorage("getMinigame")].another, true)
            elseif msgcontains(msg, "global") then
                npcGen:say("Huuum, see this blackboard, please.", "Huuum, see this blackboard, please.")
                getMiniGameRank(cid, miniGames[npcGen:getStorage("getMinigame")], miniGamesInfo[npcGen:getStorage("getMinigame")].consulta, miniGamesInfo[npcGen:getStorage("getMinigame")].another)
            else
                npcGen:say("Sorry, I didn't understand what you wanna.", "Sorry, I didn't understand what you wanna.")
            end
            npcGen:setStage(1)
        end

        return true
    end)
end

function onThink()
    npcGen:onThink()
end

function onCreatureDisappear(cid, pos)
    npcGen:onDisappear(cid, pos)
end