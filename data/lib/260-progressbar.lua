--[[
    ProgressBar Helper Library
    
    Exibe uma barra de progresso acima da criatura para todos que estão no campo de visão.
    
    Uso:
        -- Exibe a progressbar por 3 segundos, da esquerda pra direita (ltr = true)
        doCreatureSendProgressbar(cid, 3000, true)
        
        -- Exibe a progressbar por 5 segundos, da direita pra esquerda (ltr = false)
        doCreatureSendProgressbar(cid, 5000, false)
        
        -- Para/cancela a progressbar (duration = 0)
        doCreatureSendProgressbar(cid, 0, true)
        
    Exemplos de uso em spells:
        -- Antes de um cast (warning visual de 2s antes do dano)
        doCreatureSendProgressbar(cid, 2000, true)
        addEvent(function()
            -- dano aqui depois do warning
        end, 2000)
        
    Callbacks disponíveis no client (Lua do OTClient):
        creature:onProgressBarStart(duration, ltr)  -- disparado ao iniciar
        creature:onProgressBarUpdate(percent, duration, ltr)  -- disparado a cada 50ms
]]--

-- Wrapper conveniente com validação
function sendProgressbar(cid, duration, leftToRight)
    if not isCreature(cid) then
        return false
    end
    leftToRight = leftToRight ~= false  -- default: true
    return doCreatureSendProgressbar(cid, duration, leftToRight)
end
