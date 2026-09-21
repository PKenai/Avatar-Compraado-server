local npcGen = newNpc("guildsNpc")

npcGen:setFuncStart(function(cid)
    local guild, lang = getPlayerGuildId(cid), getLang(cid)

    if(not guild or getPlayerGuildLevel(cid) < GUILDLEVEL_LEADER) then
        npcGen:say("Sorry, I only speak with leaders of guilds.", "Sorry, I only speak with leaders of guilds.", lang)
        return false
    end


    npcGen:say("Hello "..getCreatureName(cid).." with me you can start a WAR with another guild, or see other OPTIONS.",
    "Hello "..getCreatureName(cid).." with me you can start a WAR with another guild, or see other OPTIONS.")
    return true

end)

npcGen:addOptionInNpc("options", {"With me you can START WAR with another guild, ACCEPT WAR, VIWER INVITES, CANCEL WAR.", 
"With me you can START WAR with another guild, ACCEPT WAR, VIWER INVITES, CANCEL WAR."})


function onCreatureSay(cid, type, msg)
    local msg = msg:lower()
    npcGen:onSay(cid, type, msg, 
    function(stage)
        if stage == 1 then

            if msgcontains(msg, "start war") or msgcontains(msg, "accept war") then
                
            end
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