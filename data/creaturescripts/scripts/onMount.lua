-- ============================================================================
-- MONTARIA DESATIVADA
-- ----------------------------------------------------------------------------
-- Este e' o portao unico da montaria no servidor: Player::setMounted() dispara
-- o evento "mount" e QUALQUER script que retorne false cancela a montaria -
-- o engine sai ANTES de marcar mounted, de aplicar o outfit da montaria e de
-- somar o speed dela. Retornando false sempre nao existe caminho para montar
-- (nem botao do client, nem atalho, nem item, nem outfit).
--
-- O que NAO e' bloqueado aqui: DESMONTAR. O dismount e' outro evento
-- (executeDismount) e segue liberado - e' justamente o que tira do modo
-- montado quem ficou preso montado antes (o estado "mounted" + lookMount e'
-- salvo no banco, ver iologindata.cpp).
--
-- Para religar: devolver o retorno antigo (CONDITION_OUTFIT -> false) e
-- reativar o botao/atalho no client (modules/game_interface/interface.otmod).
-- ============================================================================
function onMount(cid, mountId)
	return false
end