function onCreatureAppear(cid)
    return true
end

function onCreatureDisappear(cid)
    return true
end

function onCreatureSay(cid, type, msg)
        local msg = string.lower(msg)

        if (msgcontains(msg, "hi") or msgcontains(msg, "oi")) and getDistanceToCreature(cid) < 3 then
            selfSay("The city gates are very strong, but if someone or something open them, we will be here to protect you.")
        elseif msgcontains(msg, "help") and getDistanceToCreature(cid) < 3 then
            selfSay("I don't need help, I have help of the all city army.")
        end
        
        return false
end

function onThink()
    return true
end