-- ============================================================================
-- Comandos da staff para o PIX (doacao / Buy Coins)
-- ----------------------------------------------------------------------------
--   !pixpending                    lista os pedidos ainda pendentes
--   !pixconfirm <txid> <valor>     credita o pedido, mas SO' se o valor que
--                                  voce digitou bater com o valor do pedido
--
-- O valor e' obrigatorio de proposito: no modo local (sem gateway) o Pix e'
-- estatico, ou seja, o banco nao amarra o txid ao pagamento. Obrigar a digitar
-- o valor que chegou no extrato e' o que impede alguem de mostrar um comprovante
-- antigo (ou pago em outro valor) e receber coins por ele.
--
-- As funcoes usadas aqui vem de data/creaturescripts/scripts/game_pix.lua
-- (carregado no boot junto com os creaturescripts).
-- ============================================================================

local function reply(cid, text)
    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, text)
end

function onSay(cid, words, param, channel)
    if getPlayerGroupId(cid) < 5 then
        reply(cid, "Voce nao tem permissao para usar este comando.")
        return true
    end

    param = (param or ""):gsub("^%s*(.-)%s*$", "%1")

    if words == "!pixpending" then
        local list = gamePixPendingOrders()
        if #list == 0 then
            reply(cid, "Nenhum pedido de Pix pendente.")
            return true
        end

        reply(cid, string.format("%d pedido(s) pendente(s):", #list))
        for _, order in ipairs(list) do
            reply(cid, string.format("  %s | %s | R$ %s = %d coins | %d min",
                order.txid, order.player_name, order.value, order.coins, order.age))
        end
        return true
    end

    -- !pixconfirm <txid> <valor>
    local txid, value = param:match("^(%S+)%s*(%S*)$")

    if not txid then
        reply(cid, "Use: !pixconfirm <txid> <valor recebido>   (veja os pendentes com !pixpending)")
        return true
    end

    if not value or value == "" then
        reply(cid, "Confira no extrato primeiro. Para creditar:")
        reply(cid, "  !pixconfirm " .. txid .. " <valor que chegou>")
        reply(cid, "Sem o valor o pedido NAO e' creditado (protecao contra comprovante repetido).")
        return true
    end

    local ok, result = gamePixMarkPaid(txid, value)
    if not ok then
        reply(cid, "Falha ao confirmar: " .. tostring(result))
        return true
    end

    reply(cid, string.format("Pedido %s confirmado: %s pagou R$ %s e recebeu %d coins.",
        result.txid, result.player_name, string.format("%.2f", result.value_cents / 100), result.coins))
    return true
end
