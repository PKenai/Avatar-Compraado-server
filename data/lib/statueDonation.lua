--[[
================================================================================
  STATUE DONATION - lado SERVIDOR
  Module do client: modules/statue_donation  (extended opcode 121)
--------------------------------------------------------------------------------
  O QUE E
  - 4 nacoes (Fire Nation / Water Tribe / Air Nomads / Earth Kingdom). Cada uma
    tem um POOL em gold. O player doa pra nacao que quiser (nao precisa ser da
    nacao dele) e a barra do card mostra o progresso.
  - Quando o pool de uma nacao bate a meta (150.000 gold), a nacao ganha
    +5% de DANO (so' contra MONSTROS) por 12 HORAS, para os players DAQUELA
    nacao. O pool zera e so' volta a encher quando o bonus terminar.
  - 2 abas globais, que valem pra TODO o servidor:
      Experience - pool de 350.000 gold -> +5% de exp por 8h
      Potions    - pool de 400.000 gold -> +15% de CURA das potions por 8h
    (a antiga aba "Skill", que acelerava o ganho de skill/magic level, foi
     trocada por esta - o ganho de ML nao desce mais por aqui.)
    REGRA DAS ABAS: IGUAL a das nacoes. O player doa o quanto quiser, o pool
    vai enchendo com a doacao de todo mundo e a bencao ativa quando o pool bate
    a meta; o que passar da meta nao e' cobrado nem guardado. Com a bencao
    ativa o pool nao aceita mais nada - so' volta a encher quando ela terminar.

  O QUE ATRAVESSA UM SAVE / RESTART DO SERVIDOR
  - `pool` e `bonus_until` sao gravados no banco a cada mudanca. O relogio e'
    o os.time() unix (nao um contador de uptime), entao tanto o pool acumulado
    quanto a bencao ativa - com o tempo que falta - sobrevivem ao save, ao
    restart e ao crash. Um player que entra depois continua vendo o buff.
  - Os ICONES nao ficam presos no player: sao derivados desse estado e
    reaplicados no login, no relogin, ao abrir a estatua e, de minuto em
    minuto, pelo reconcile (StatueDonation.sweep) de quem esta' online. Ou
    seja: icone perdido (morte limpa os buffs do creature, client fechado no
    meio, /reload) volta sozinho, e icone que nao vale mais e' removido.
  - O ESTADO (pools + o que esta' ativo) tambem e' empurrado no login/relogin
    (StatueDonation.sendState), e o client ainda pode PEDI-LO quando abre a
    janela (opcode 121, action "open"). O client so' confia no que o servidor
    manda: abrir a janela de novo nunca mostra pool/bencao de uma sessao antiga.
  - O dinheiro sai do inventario e, se faltar, do BANCO.
  - Quem manda e' o servidor: o client so' pede ("donate <nacao> <valor>") e o
    servidor valida valor, saldo, meta e estado. Nenhum numero vindo do client
    define preco - o custo das abas globais tambem e' do servidor.

  ONDE O ESTADO VIVE
  - Tabela `statue_donation` (name, pool, bonus_until, updated) - uma linha por
    chave: fire/water/air/earth/exp/potion. Escrita a cada mudanca (nao fica
    so' na memoria: crash do servidor nao perde doacao).
  - bonus_until = timestamp unix do fim do bonus (0 = inativo).
  - ATENCAO: a engine cria UM lua_State por categoria de script e cada um carrega
    data/lib inteiro (actions, creatureevent, globalevent, talkaction, spells,
    movement, weapons, npc...). Ou seja: esta lib vive em VARIAS copias, uma por
    interface, e cada copia tem o seu proprio `state`/`shown`. O banco e' a unica
    memoria compartilhada entre elas, por isso o estado e' RELIDO do banco
    (cache curto de CONFIG.stateTtl segundos, e leitura forcada antes de doar,
    abrir a estatua, logar, reconciliar e no comando de staff). Guardar o estado
    pra sempre - como era antes - deixava a copia do ACTIONS (uso da estatua)
    congelada no retrato do primeiro uso: ela escondia o icone do buff e mandava
    "not blessed" pro client enquanto a copia do CREATURESCRIPTS (opcode 121) ja'
    sabia da bencao ativa.
  - Nao ha lock entre as copias: cada uma escreve o valor que leu e reconstruiu
    (pool + doacao). Como as escritas sao sincronas e o tique/uso releem antes de
    agir, a corrida so' existe entre dois pedidos no mesmo instante - a mesma
    janela que ja' existia antes (dois players doando no mesmo segundo).

  BUFFS (barra de buffs em cima da tela)
  - Usa o sistema de buffs do servidor (doCreatureAddBuffWithTime + opcode 100).
    Os ids 13..18 existem no `src/buff.h` deste datapack (BUFF_LAST = 19), mas
    dependem do BINARIO recompilado: se o .exe rodando for antigo, o
    registerBuffType devolve false e a lib cai sozinha no caminho alternativo,
    mandando o MESMO JSON que o C++ manda no opcode 100 (mesmo icone, mesmo
    timer). Depois de recompilar, o buff passa a ser o oficial - e o engine
    passa a responder doCreatureHasBuff, que e' o que o reconcile usa pra saber
    se o icone ja' esta' aplicado.
  - A REMOCAO nunca depende do engine: hideBuff manda o "remove" do opcode 100
    sempre, inclusive no modo nativo. O engine so' manda o remove pra quem
    realmente tem o buff, e o client pode estar com o icone sem o servidor
    saber (relog do caminho cru, /reload) - o client ignora remove de id que
    ele nao tem.

  ATIVACAO UNICA (ativar 2x tem o efeito de 1x)
  - A bencao nasce de um UPDATE CONDICIONAL no banco (activate): consumir o pool
    e gravar o fim do ciclo acontecem na MESMA query, que so' muda a linha de
    quem encontra `bonus_until` vencido E o pool cheio. Quem chegar depois -
    segunda copia da lib (a engine tem um lua_State por interface, cada um com a
    sua memoria), clique repetido, doacao validada em cima de estado velho,
    staff/PHP/outro servidor mexendo na mesma base - nao muda nada: nao existe
    segunda ativacao, o pool e' consumido uma vez e a duracao continua sendo UM
    ciclo (nunca 2x o tempo, nunca o bonus dobrado).
  - O credito da doacao tambem e' atomico (`pool` = `pool` + valor) e com a mesma
    guarda: se a bencao comecou entre a leitura e o credito, o ouro NAO entra num
    ciclo fechado - ele VOLTA pro player (inventario e banco, como saiu) com
    recado na tela. Nada e' cobrado sem entrar no pool.
  - Quem venceu a corrida e' quem, relendo o banco, ve exatamente o `until_` que
    escreveu: so' o vencedor anuncia e reaplica os icones. (Dois pedidos no MESMO
    segundo podem se achar vencedores e o broadcast sair em dobro - e' cosmetico:
    o ciclo gravado e' um, do primeiro, e o pool foi consumido uma vez.)
  - A EXPIRACAO (checkExpired) tambem e' UPDATE condicional, e so' zera
    `bonus_until`: ela nao reescreve o pool, entao nao apaga doacao que chegou
    enquanto o tique rodava.

  INSTALACAO (ja feita neste datapack)
  1) data/lib/statueDonation.lua                      (este arquivo)
  2) data/actions/actions.xml                         (action da estatua)
  3) data/creaturescripts/creaturescripts.xml         (opcode + combate)
  4) loginLogout/login.lua (registerCreatureEvent + StatueDonation.onLogin) e
     loginLogout/onReLogin.lua (re-aplica os buffs)
  5) data/creaturescripts/scripts/idle.lua            (bonus de exp global)
  6) Tabela: Controles de uso/MARKET/statue_donation.sql (a lib tambem tenta
     CREATE TABLE IF NOT EXISTS, mas o ideal e' rodar o .sql uma vez)
  7) Client: modules/statue_donation + data/images/buffs/statue_*.png
  8) data/talkactions/scripts/resetstatue.lua + talkactions.xml  (!resetstatue)
================================================================================
]]

StatueDonation = StatueDonation or {}

local CONFIG = {
    opcode      = 121,
    tableName   = "statue_donation",

    -- nacoes
    goal         = 150000,  -- gold por ciclo
    nationHours  = 12,      -- duracao do bonus de dano
    nationDamage = 5,       -- % de dano contra monstros

    -- abas globais (servidor todo). `*Cost` e' a META do pool (como o `goal`
    -- das nacoes): o pool enche com a soma das doacoes e a bencao ativa quando
    -- bate a meta (ver doGlobalPurchase).
    expCost    = 350000,
    expHours   = 8,
    expBonus   = 5,         -- % de exp
    potionCost  = 400000,
    potionHours = 8,
    potionBonus = 15,       -- % de cura extra das potions (HP)

    -- travas
    minDonation = 1,
    maxDonation = 100000000, -- 100kk por pedido (anti-overflow / digito errado)
    cooldown    = 1,         -- segundos entre pedidos do mesmo player

    -- Validade do cache em memoria do estado (segundos). A engine tem UM
    -- lua_State por categoria de script, cada um carregando data/lib inteiro:
    -- esta lib vive em VARIAS copias (uma por interface), cada uma com o seu
    -- proprio `state`. O banco e' a unica memoria compartilhada, entao relemos
    -- ele de tempos em tempos para as copias concordarem (ver dbLoad).
    stateTtl    = 3,

    broadcast = true,
}

-- icon = arquivo em data/images/buffs/ (icone do buff que aparece em cima)
-- image = caminho que o client usa no card da janela
local NATIONS = {
    { key = "fire",  label = "Fire Nation",   element = "fire",  buffId = 13,
      icon = "statue_fire",  border = "frame-2-orange",  image = "/images/game/emblems/emblem_fire",  color = "#ff7a45" },
    { key = "water", label = "Water Tribe",   element = "water", buffId = 14,
      icon = "statue_water", border = "frame-7-blue",    image = "/images/game/emblems/emblem_water", color = "#4fc3ff" },
    { key = "air",   label = "Air Nomads",    element = "air",   buffId = 15,
      icon = "statue_air",   border = "frame-6-sky",     image = "/images/game/emblems/emblem_air",   color = "#bfe9ff" },
    { key = "earth", label = "Earth Kingdom", element = "earth", buffId = 16,
      icon = "statue_earth", border = "frame-9-jade",    image = "/images/game/emblems/emblem_earth", color = "#9ede7c" },
}

local GLOBALS = {
    { key = "exp",   label = "Experience", buffId = 17, cost = CONFIG.expCost,   hours = CONFIG.expHours,   bonus = CONFIG.expBonus,
      detail = "experience from creatures",
      icon = "statue_exp",   border = "frame-2-gold",    image = "/images/buffs/exp_scroll",  color = "#ffe9a3" },
    -- Aba das potions: ocupa a posicao/buffId da antiga aba "Skill", entao o
    -- client nao precisa de mudanca de codigo (nome, preco e descricao vem
    -- todos do estado que o servidor manda).
    -- icon = data/images/buffs/potion.png (icone do buff na barra de cima) e
    -- image = o mesmo desenho no card da janela - igual a aba EXP, que usa o
    -- exp_scroll nos dois lugares.
    { key = "potion", label = "Potions",   buffId = 18, cost = CONFIG.potionCost, hours = CONFIG.potionHours, bonus = CONFIG.potionBonus,
      detail = "potion healing",
      icon = "potion", border = "frame-2-magenta", image = "/images/buffs/potion", color = "#e7a6ff" },
}

-- Todas as chaves do sistema (nacoes + globais)
local KEYS = {}
local NATION_BY_KEY = {}
local NATION_BY_ELEMENT = {}
local GLOBAL_BY_KEY = {}
local BUFF_INFO = {} -- buffId -> {id, name, description, icon, border}

for _, n in ipairs(NATIONS) do
    KEYS[n.key] = n
    NATION_BY_KEY[n.key] = n
    NATION_BY_ELEMENT[n.element] = n
    BUFF_INFO[n.buffId] = {
        id = n.buffId,
        name = n.label .. " Blessing",
        description = "+" .. CONFIG.nationDamage .. "% damage against monsters for " .. CONFIG.nationHours .. " hours.",
        icon = n.icon,
        border = n.border,
    }
end
for _, g in ipairs(GLOBALS) do
    KEYS[g.key] = g
    GLOBAL_BY_KEY[g.key] = g
    BUFF_INFO[g.buffId] = {
        id = g.buffId,
        name = g.label .. " Blessing",
        description = "+" .. g.bonus .. "% " .. g.detail .. " for " .. g.hours .. " hours (whole server).",
        icon = g.icon,
        border = g.border,
    }
end

-- ============================================================================
-- Estado em memoria (cache da tabela)
-- ============================================================================
local state = {}       -- key -> { pool = 0, until_ = 0 }
local stateStamp = 0   -- os.time() da ultima leitura do banco (cache curto)
local schemaReady = false -- CREATE TABLE/INSERT IGNORE ja' rodaram nesta copia
local dbReady = false
local dbLastTry = nil
local dbWarned = false
local tickStarted = false

local function now()
    return os.time()
end

local function getState(key)
    local s = state[key]
    if not s then
        s = { pool = 0, until_ = 0 }
        state[key] = s
    end
    return s
end

-- ============================================================================
-- Banco de dados
-- ============================================================================
local function ensureRow(key)
    db.executeQuery("INSERT IGNORE INTO `" .. CONFIG.tableName ..
        "` (`name`, `pool`, `bonus_until`, `updated`) VALUES (" ..
        db.escapeString(key) .. ", 0, 0, " .. now() .. ");")
end

-- Le o estado do banco. Se falhar (banco fora, tabela sem permissao), tenta de
-- novo a cada 30s - nunca fica marcado como "quebrado pra sempre".
--
-- `force` = ignora o cache curto. Usado por quem precisa do numero EXATO agora:
-- doacao, uso da estatua, login, reconcile do tique e comandos de staff.
--
-- POR QUE RELER O BANCO (e nao guardar o estado pra sempre): a engine cria um
-- lua_State por categoria de script e CADA UM roda `data/lib` inteiro no seu
-- initState() (actions, creatureevent, globalevent, talkaction, spells...).
-- Esta lib existe em varias copias - uma por interface - e cada copia tem o seu
-- proprio `state`. Antes cada copia lia o banco UMA vez e nunca mais: a copia do
-- ACTIONS (usar a estatua) ficava com o retrato do primeiro uso e, depois de uma
-- bencao ativada pela copia do CREATURESCRIPTS (opcode 121), ela continuava
-- achando a nacao desativada - escondia o icone do buff (hideBuff) e mandava pro
-- client um estado "not blessed" enquanto o icone ja' estava ativo. Reler o banco
-- (unica memoria compartilhada entre as interfaces) faz todas as copias
-- concordarem; o cache de CONFIG.stateTtl segundos evita query por acesso (os
-- getters de bonus rodam em combate).
local function dbLoad(force)
    local t = now()
    if not force and dbReady and stateStamp ~= 0 and (t - stateStamp) < CONFIG.stateTtl then
        return true
    end
    if not dbReady and dbLastTry and (t - dbLastTry) < 30 then
        return false
    end
    dbLastTry = t

    -- Schema so' uma vez por copia: reler o estado nao precisa repetir isto.
    if not schemaReady then
        db.executeQuery("CREATE TABLE IF NOT EXISTS `" .. CONFIG.tableName .. "` (" ..
            "`name` VARCHAR(16) NOT NULL, " ..
            "`pool` BIGINT UNSIGNED NOT NULL DEFAULT 0, " ..
            "`bonus_until` BIGINT UNSIGNED NOT NULL DEFAULT 0, " ..
            "`updated` BIGINT NOT NULL DEFAULT 0, " ..
            "PRIMARY KEY (`name`)) ENGINE = InnoDB;")
    end

    local res = db.getResult("SELECT `name`, `pool`, `bonus_until` FROM `" .. CONFIG.tableName .. "`;")
    if not res or res:getID() == -1 then
        if not dbWarned then
            dbWarned = true
            print("[StatueDonation] AVISO: nao consegui ler `" .. CONFIG.tableName ..
                "`. Rode Controles de uso/MARKET/statue_donation.sql no banco.")
        end
        return false
    end

    local loaded = {}
    repeat
        local name = res:getDataString("name")
        if name and name ~= "" then
            loaded[name] = {
                pool = tonumber(res:getDataLong("pool")) or 0,
                until_ = tonumber(res:getDataLong("bonus_until")) or 0,
            }
        end
    until not res:next()
    res:free()

    -- O banco manda: troca a memoria inteira. As escritas daqui sao sincronas
    -- (neste datapack db.executeQuery e' db.query), entao apos um dbSave o banco
    -- ja' contem o que esta' na memoria e nada local se perde nesta troca.
    state = loaded

    local missing = {}
    for key in pairs(KEYS) do
        if not loaded[key] then
            table.insert(missing, key)
        end
        getState(key) -- cria a entrada zerada de quem faltar
    end
    if not schemaReady or #missing > 0 then
        for _, key in ipairs(missing) do
            ensureRow(key)
        end
        schemaReady = true
    end

    -- Sem print de sucesso: o console so' fala quando da' erro (o AVISO abaixo
    -- continua, uma vez por falha).
    stateStamp = t
    dbReady = true
    dbWarned = false
    return true
end

local function dbSave(key)
    if not dbReady then
        return
    end
    local s = getState(key)
    db.executeQuery("UPDATE `" .. CONFIG.tableName .. "` SET `pool` = " .. math.floor(s.pool) ..
        ", `bonus_until` = " .. math.floor(s.until_) ..
        ", `updated` = " .. now() ..
        " WHERE `name` = " .. db.escapeString(key) .. ";")
    -- Memoria e banco estao iguais: renova o cache para os getters de bonus nao
    -- dispararem uma leitura que acabaria de trazer o mesmo (e para quem escreveu
    -- nunca ver o proprio valor voltar atras por um cache vencido).
    stateStamp = now()
end

-- ============================================================================
-- Helpers
-- ============================================================================
-- Elemento do player. NAO usa getPlayerElement(): aquela funcao faz
-- elements[vocation] e devolve nil para as vocacoes PROMOVIDAS (5..8 = fire
-- lord / tribal chief / air monk / dai li). Aqui a conta fecha nas 8:
-- (voc-1)%4 -> 1 fire, 2 water, 3 air, 4 earth.
local function elementOf(cid)
    if not isPlayer(cid) then
        return nil
    end
    local voc = tonumber(getPlayerVocation(cid))
    if not voc or voc < 1 then
        return nil
    end
    local base = ((voc - 1) % 4) + 1
    local nation = NATIONS[base]
    return nation and nation.element or nil
end
StatueDonation.elementOf = elementOf

local function formatTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return hours .. "h " .. (mins < 10 and "0" or "") .. mins .. "m"
    end
    local secs = seconds % 60
    return mins .. "m " .. (secs < 10 and "0" or "") .. secs .. "s"
end
StatueDonation.formatTime = formatTime

-- Le o cache curto antes de responder (no maximo CONFIG.stateTtl segundos de
-- atraso). Sem isto uma copia desta lib que nunca passou por dbLoad nesta
-- interface - idle.lua (exp) e fullPotion.lua (cura) perguntam o bonus - diria
-- "inativo" para sempre.
local function isActive(key)
    dbLoad()
    return getState(key).until_ > now()
end
StatueDonation.isActive = isActive

function StatueDonation.isNationActive(element)
    local nation = element and NATION_BY_ELEMENT[element]
    return nation ~= nil and isActive(nation.key)
end
StatueDonation.isNationBonusActive = StatueDonation.isNationActive

-- Fracao de bonus para o checkExpRates (idle.lua): 0.05 ou 0
function StatueDonation.getExpBonus()
    dbLoad()
    if isActive("exp") then
        return CONFIG.expBonus / 100
    end
    return 0
end

function StatueDonation.getNationDamageBonus()
    return CONFIG.nationDamage
end

-- ============================================================================
-- Gold (inventario primeiro, banco depois)
-- ============================================================================
local function playerTotalGold(cid)
    local money = tonumber(getPlayerMoney(cid)) or 0
    local bank = 0
    if type(getPlayerBankBalance) == "function" then
        bank = tonumber(getPlayerBankBalance(cid)) or 0
    end
    return math.floor(money), math.floor(bank)
end

-- Tira `amount` do player (inventario e/ou banco). Confere o total ANTES de
-- tirar: nunca cobra metade e falha no meio.
local function takeGold(cid, amount)
    amount = math.floor(amount)
    if amount <= 0 then
        return false
    end

    local money, bank = playerTotalGold(cid)
    if money + bank < amount then
        return false
    end

    local fromMoney = math.min(money, amount)
    local fromBank = amount - fromMoney

    if fromMoney > 0 and not doPlayerRemoveMoney(cid, fromMoney) then
        return false
    end
    if fromBank > 0 and not doPlayerSetBalance(cid, bank - fromBank) then
        -- devolve o que ja' saiu do inventario
        doPlayerAddMoney(cid, fromMoney)
        return false
    end

    -- Devolve o split pra quem chamou poder mostrar o recibo: "donatei 100k e
    -- ativou" sem saber que o resto saiu do BANCO era exatamente a duvida.
    return true, fromMoney, fromBank
end

-- Desfaz um takeGold (mesmo split: devolve o que saiu do inventario pro
-- inventario e o que saiu do banco pro banco). Usado quando o credito no pool
-- nao entra - o ouro nunca fica num limbo entre o player e um ciclo fechado.
local function refundGold(cid, fromMoney, fromBank)
    if not isPlayer(cid) then
        return
    end
    fromMoney = math.floor(tonumber(fromMoney) or 0)
    fromBank = math.floor(tonumber(fromBank) or 0)
    if fromMoney > 0 then
        doPlayerAddMoney(cid, fromMoney)
    end
    if fromBank > 0 and type(getPlayerBankBalance) == "function" and type(doPlayerSetBalance) == "function" then
        doPlayerSetBalance(cid, (tonumber(getPlayerBankBalance(cid)) or 0) + fromBank)
    end
end

-- ============================================================================
-- Buffs (barra de cima da tela)
-- ============================================================================
local buffRegistered = {}

local function registerBuffs()
    local missing = {}
    for id, info in pairs(BUFF_INFO) do
        -- ticks = -1: o tempo real vem do addBuffWithTime (login / ativacao)
        local ok = false
        pcall(function()
            ok = registerBuffType(id, info.name, info.description, info.icon, info.border,
                false, 1, -1, false, false) == true
        end)
        buffRegistered[id] = ok
        if not ok then
            table.insert(missing, tostring(id))
        end
    end

    if #missing > 0 then
        -- Acontece no build atual (BUFF_LAST = 13, em src/buff.h). Todo o
        -- sistema funciona igual: os icones vao pelo opcode 100 na mao.
        print("[StatueDonation] build sem os ids de buff " .. table.concat(missing, ", ") ..
            " - usando envio direto no opcode 100. Recompile (build.bat) pra ter o buff oficial.")
    end
end

local function sendRawBuff(cid, info, ms)
    doSendPlayerExtendedOpcode(cid, 100, json.encode({
        action = "add",
        data = {
            id = info.id,
            name = info.name,
            description = info.description,
            icon = info.icon,
            border = info.border,
            stacks = 1,
            ticks = math.floor(ms),
            -- o client faz (endTime - server_time*1000): endTime em ms
            endTime = (now() + math.floor(ms / 1000)) * 1000,
            server_time = now(),
            debuff = false,
        },
    }))
end

local function sendRawBuffRemove(cid, info)
    doSendPlayerExtendedOpcode(cid, 100, json.encode({
        action = "remove",
        data = { id = info.id, debuff = false },
    }))
end

-- Quem ja' esta' com o icone (cid -> buffId -> true). Serve pro caminho
-- "cru" (opcode 100), onde o engine nao sabe responder se o player tem o buff:
-- sem isso o reconcile de 60s reenviaria o icone toda vez (piscando no client).
-- No modo nativo quem manda e' doCreatureHasBuff (fonte real), com este mapa
-- so' como reserva.
local shown = {}

local function hasBuffNow(cid, buffId)
    if buffRegistered[buffId] and type(doCreatureHasBuff) == "function" then
        local ok, value = pcall(doCreatureHasBuff, cid, buffId)
        if ok then
            return value == true
        end
    end
    return (shown[cid] and shown[cid][buffId]) == true
end

local function showBuff(cid, buffId, ms, force)
    if not isPlayer(cid) or ms <= 0 then
        return
    end
    local info = BUFF_INFO[buffId]
    if not info then
        return
    end
    -- `force` = o client acabou de nascer (login, relogin): a barra de buffs
    -- comecou vazia, entao reenvia mesmo que o servidor ja' tenha o icone.
    if not force and hasBuffNow(cid, buffId) then
        return
    end
    if buffRegistered[buffId] then
        doCreatureAddBuffWithTime(cid, buffId, ms)
    else
        sendRawBuff(cid, info, ms)
    end
    shown[cid] = shown[cid] or {}
    shown[cid][buffId] = true
end

local function hideBuff(cid, buffId)
    if not isPlayer(cid) then
        return
    end
    local info = BUFF_INFO[buffId]
    if not info then
        return
    end
    if buffRegistered[buffId] then
        doCreatureRemoveBuff(cid, buffId)
    end
    -- O "remove" do opcode 100 vai SEMPRE (inclusive no modo nativo): e' o
    -- unico jeito de garantir que o icone saia do client de quem "pegou de
    -- alguma forma" - o engine so' manda esse pacote pra quem realmente tem o
    -- buff no creature, e o icone pode existir so' no client (relog do caminho
    -- cru, /reload, troca de modo cru<->nativo). O client ignora remove de id
    -- que ele nao tem (modules/game_buffs: if buffWidget then destroy()).
    sendRawBuffRemove(cid, info)
    if shown[cid] then
        shown[cid][buffId] = nil
    end
end

-- ============================================================================
-- Estado pro client
-- ============================================================================
local function buildState(cid)
    local nations, globals = {}, {}
    for _, n in ipairs(NATIONS) do
        local s = getState(n.key)
        table.insert(nations, {
            key = n.key,
            label = n.label,
            image = n.image,
            color = n.color,
            element = n.element,
            pool = math.floor(s.pool),
            goal = CONFIG.goal,
            until_ = math.floor(s.until_),
        })
    end
    for _, g in ipairs(GLOBALS) do
        local s = getState(g.key)
        table.insert(globals, {
            key = g.key,
            label = g.label,
            image = g.image,
            color = g.color,
            cost = g.cost,      -- meta do pool (o client mostra "cost gold")
            goal = g.cost,
            pool = math.floor(s.pool),
            hours = g.hours,
            bonus = g.bonus,
            detail = g.detail,
            until_ = math.floor(s.until_),
        })
    end

    local money, bank = playerTotalGold(cid)
    return {
        serverTime = now(),
        goal = CONFIG.goal,
        minDonation = CONFIG.minDonation,
        nationHours = CONFIG.nationHours,
        nationDamage = CONFIG.nationDamage,
        nations = nations,
        globals = globals,
        money = money,
        bank = bank,
        element = elementOf(cid),
        buffMode = buffRegistered[13] and "native" or "raw",
    }
end

-- isOpen = true manda action "open" (o client ABRE a janela). Sem ele,
-- action "state" e' so' atualizacao: quem estiver com a janela aberta ve' o
-- numero novo, quem nao estiver nao recebe janela na cara (doacao de outro
-- player avisa a todos pelo broadcast, nao abrindo a tela de ninguem).
function StatueDonation.sendState(cid, isOpen)
    if not isPlayer(cid) then
        return
    end
    doSendPlayerExtendedOpcode(cid, CONFIG.opcode, json.encode({
        action = isOpen and "open" or "state",
        data = buildState(cid),
    }))
end

local function sendMsg(cid, msgType, msg)
    if not isPlayer(cid) then
        return
    end
    doSendPlayerExtendedOpcode(cid, CONFIG.opcode, json.encode({ action = "msg", data = { type = msgType, msg = msg } }))
end

-- ============================================================================
-- Aplicacao dos bonus
-- ============================================================================
-- Buffs que este player deveria estar vendo agora (login, relogin, uso da
-- estatua e reconcile). Idempotente: tambem REMOVE o que nao vale mais.
-- `force = true` reenvia o icone mesmo que o servidor ja' o tenha - e' o que
-- login/relogin usam, porque nessa hora o client recarregou a barra de buffs
-- vazia (e um cid pode ter sido reaproveitado por outro personagem).
function StatueDonation.applyBuffs(cid, force)
    if not isPlayer(cid) then
        return
    end

    local element = elementOf(cid)
    for _, n in ipairs(NATIONS) do
        local left = getState(n.key).until_ - now()
        if element == n.element and left > 0 then
            showBuff(cid, n.buffId, left * 1000, force)
        else
            hideBuff(cid, n.buffId)
        end
    end

    for _, g in ipairs(GLOBALS) do
        local left = getState(g.key).until_ - now()
        if left > 0 then
            showBuff(cid, g.buffId, left * 1000, force)
        else
            hideBuff(cid, g.buffId)
        end
    end
end

-- Reconcile de quem esta' online: reaplica o icone que sumiu (morte chama
-- Creature::clearBuffs, client fechado no meio da bencao, /reload, restart do
-- servidor) e tira o que nao vale mais. Roda no tique de 60s - e' esta passada
-- que faz a bencao "sobreviver" ao save sem depender de relog nem de abrir a
-- estatua. Nao passa por dinheiro nenhum: quem manda e' o estado do banco.
function StatueDonation.sweep()
    if not dbLoad(true) then
        return 0
    end

    local online = {}
    local touched = 0
    for _, pid in ipairs(getPlayersOnline()) do
        if isPlayer(pid) then
            online[pid] = true
            touched = touched + 1
            pcall(StatueDonation.applyBuffs, pid, false)
        end
    end

    -- cid e' reaproveitado por outro personagem: nao guardar quem ja' saiu
    for cid in pairs(shown) do
        if not online[cid] then
            shown[cid] = nil
        end
    end
    return touched
end

local function refreshEveryone(key)
    local entry = KEYS[key]
    if not entry then
        return
    end
    local left = getState(key).until_ - now()
    for _, pid in ipairs(getPlayersOnline()) do
        if isPlayer(pid) then
            -- force = true: a bencao ACABOU de ligar, entao o icone tem que
            -- aparecer pra todo mundo com o tempo cheio (mesmo se o client
            -- estivesse com um icone velho/phantasma daquele id).
            if GLOBAL_BY_KEY[key] then
                showBuff(pid, entry.buffId, left * 1000, true)
            elseif elementOf(pid) == entry.element then
                showBuff(pid, entry.buffId, left * 1000, true)
            end
            StatueDonation.sendState(pid)
        end
    end
end

-- Tira o buff daquela chave de TODO mundo que esta' online, sem olhar se o
-- banco considera a bencao ativa: quem manda aqui e' o reset da staff (um
-- icone fantasma pode existir no client sem o servidor saber). Devolve quantos
-- players online foram atingidos; quem esta' offline perde o icone no proximo
-- login/relogin, porque applyBuffs manda o "remove" de todas as chaves da
-- estatua que nao valem mais.
local function hideEveryone(key)
    local entry = KEYS[key]
    if not entry then
        return 0
    end
    local touched = 0
    for _, pid in ipairs(getPlayersOnline()) do
        if isPlayer(pid) then
            hideBuff(pid, entry.buffId)
            StatueDonation.sendState(pid)
            touched = touched + 1
        end
    end
    return touched
end

local function broadcast(text)
    if CONFIG.broadcast then
        doBroadcastMessage(text, MESSAGE_STATUS_CONSOLE_BLUE)
    end
end

-- O engine nao tem rate de "potion": quem cura potion pergunta o multiplicador
-- aqui. Quem usa: data/actions/scripts/bloodRoom/fullPotion.lua (heal()), que
-- e' o onUse de TODA potion de HP do servidor (7618, 7588, 8473, 13366-13368,
-- 15014).
--
-- 1.0 inativo / 1.15 com a aba Potions ativa. Aplicado ANTES do healcut
-- (healcut_hooks.lua reduz o valor final na metade quando o player esta' com
-- Grievous Wounds) - ou seja, o debuff continua cortando a cura ja' aumentada.
function StatueDonation.getPotionHealMultiplier()
    dbLoad()
    if isActive("potion") then
        return 1.0 + (CONFIG.potionBonus / 100)
    end
    return 1.0
end

-- ============================================================================
-- Compra / doacao
-- ============================================================================
-- Credito ATOMICO de doacao no pool: quem soma e' o banco (`pool` = `pool` +
-- valor), nao a memoria. Alem de nao perder a doacao de quem doou no mesmo
-- instante, a guarda `bonus_until <= t` recusa credito num ciclo JA' ativo.
-- Devolve false quando o credito nao entrou (a bencao comecou no meio do
-- caminho) - quem chama devolve o ouro pro player.
local function poolCredit(key, amount)
    if not dbReady then
        return false
    end
    amount = math.floor(amount)
    local t = now()
    -- `before` sai da leitura FRESCA de quem chama (doacao/compra): serve pra
    -- conferir depois que o valor entrou mesmo - e nao confiar so' no UPDATE ter
    -- rodado (linha apagada por fora, reset da staff no meio do caminho).
    local before = getState(key).pool

    db.executeQuery("UPDATE `" .. CONFIG.tableName .. "` SET `pool` = `pool` + " .. amount ..
        ", `updated` = " .. t ..
        " WHERE `name` = " .. db.escapeString(key) .. " AND `bonus_until` <= " .. t .. ";")
    dbLoad(true)

    local s = getState(key)
    if s.until_ > t then
        return false -- a bencao comecou no meio do caminho: o credito nao entra
    end
    return s.pool >= before + amount
end

-- Abre UM ciclo novo de `key`. Consome a meta do pool e grava o fim da bencao
-- numa unica query, ja' com as duas condicoes no WHERE:
--   bonus_until <= t  -> nao existe ciclo aberto (nao soma em cima de um ativo)
--   pool >= cost      -> a meta foi batida de verdade
-- A segunda chamada (outra copia da lib, clique repetido, staff, outro servidor)
-- nao encontra a linha na condicao e NAO escreve nada: o pool e' consumido uma
-- vez e a duracao continua sendo um ciclo. Devolve true so' pro vencedor - que
-- e' quem, relendo o banco, ve exatamente o `until_` que escreveu (so' ele
-- anuncia e reaplica os icones).
local function activate(key, cost, seconds)
    if not dbReady then
        return false
    end

    local t = now()
    local newUntil = t + seconds

    db.executeQuery("UPDATE `" .. CONFIG.tableName .. "` SET " ..
        "`pool` = `pool` - " .. math.floor(cost) .. ", " ..
        "`bonus_until` = " .. newUntil .. ", " ..
        "`updated` = " .. t ..
        " WHERE `name` = " .. db.escapeString(key) ..
        " AND `bonus_until` <= " .. t ..
        " AND `pool` >= " .. math.floor(cost) .. ";")

    -- O banco e' a fonte da verdade - inclusive quando NAO fomos nos que
    -- ativamos (a linha ja' estava com o ciclo aberto por outra ponta).
    dbLoad(true)
    return getState(key).until_ == newUntil
end

local function activateNation(nation)
    if not activate(nation.key, CONFIG.goal, CONFIG.nationHours * 3600) then
        return false
    end

    broadcast(nation.label .. " has been blessed! +" .. CONFIG.nationDamage ..
        "% damage against monsters for " .. CONFIG.nationHours .. " hours for every " .. nation.label .. " member.")
    refreshEveryone(nation.key)
    return true
end

local function activateGlobal(g)
    -- a meta e' consumida da pool (na nacao tambem e' assim): o excedente de uma
    -- doacao que passou da meta nao ficou no pool, entao aqui nao sobra troco
    if not activate(g.key, g.cost, g.hours * 3600) then
        return false
    end

    broadcast("The whole server received +" .. g.bonus .. "% " .. g.detail ..
        " for " .. g.hours .. " hours!")
    refreshEveryone(g.key)
    return true
end

local function doNationDonation(cid, nation, amount)
    -- Leitura FORCADA antes de decidir qualquer coisa: "ja' abencoada?" e
    -- "quanto falta?" nao podem sair do cache curto (CONFIG.stateTtl segundos).
    -- Era por esse buraco que uma doacao validava em cima de um retrato velho e
    -- acabava ativando um ciclo que JA' tinha comecado.
    if not dbLoad(true) then
        sendMsg(cid, "error", "Statue Donation is temporarily unavailable (database).")
        return
    end
    local s = getState(nation.key)

    if s.until_ > now() then
        sendMsg(cid, "error", nation.label .. " is already blessed (" .. formatTime(s.until_ - now()) ..
            " left). The pool can only be filled again after the blessing ends.")
        return
    end

    -- (as ABAS globais tem pool e usam a mesma regra: ver doGlobalPurchase)

    if amount < CONFIG.minDonation then
        sendMsg(cid, "error", "The minimum donation is " .. CONFIG.minDonation .. " gold.")
        return
    end
    if amount > CONFIG.maxDonation then
        sendMsg(cid, "error", "That amount is too high (max " .. CONFIG.maxDonation .. " gold per donation).")
        return
    end

    local missing = CONFIG.goal - s.pool
    if missing <= 0 then
        -- Pool cheio sem ciclo aberto (ex.: staff zerou so' a bencao): fecha o
        -- ciclo em vez de recusar. Quem decide e' o UPDATE condicional - se
        -- outra ponta ativar primeiro, aqui nao se escreve nada.
        activateNation(nation)
        sendMsg(cid, "info", "The pool is already complete.")
        return
    end
    -- nunca cobra mais do que falta: o que passar disso nao e' descontado
    local paid = math.min(amount, missing)

    local ok, fromMoney, fromBank = takeGold(cid, paid)
    if not ok then
        local money, bank = playerTotalGold(cid)
        sendMsg(cid, "error", "You don't have " .. paid .. " gold. You have " .. (money + bank) ..
            " (backpack + bank).")
        return
    end

    -- Credito atomico no pool. Se a bencao comecou entre a leitura acima e este
    -- UPDATE, o credito nao entra num ciclo fechado: o ouro VOLTA pro player em
    -- vez de virar credito fantasma (`paid` nunca fica fora do pool).
    if not poolCredit(nation.key, paid) then
        refundGold(cid, fromMoney, fromBank)
        sendMsg(cid, "info", nation.label .. " was blessed right now - nothing was charged " ..
            "(your " .. paid .. " gold is back).")
        return
    end
    s = getState(nation.key)

    -- O que passar da meta NAO e' cobrado nem guardado pro proximo ciclo.
    local extra = ""
    if paid < amount then
        extra = " You typed " .. amount .. ", but only " .. paid .. " was missing: " ..
            (amount - paid) .. " was NOT charged."
    end

    if s.pool >= CONFIG.goal then
        doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "You donated " .. paid .. " gold to " .. nation.label ..
            " and completed the pool (" .. fromMoney .. " backpack + " .. fromBank .. " bank)." .. extra)
        activateNation(nation)
    else
        doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "You donated " .. paid .. " gold to " .. nation.label ..
            ". (" .. math.floor(s.pool) .. "/" .. CONFIG.goal .. " - " .. fromMoney .. " backpack + " .. fromBank .. " bank)" .. extra)
        StatueDonation.sendState(cid)
    end
end

-- Doacao pra aba global. MESMA REGRA DAS NACOES: a aba tem POOL (a meta e'
-- `g.cost`), o player doa o quanto quiser, o pool vai enchendo com a doacao de
-- todo mundo e a bencao ativa pra TODO o servidor quando o pool bate a meta.
-- O que passar da meta nao e' cobrado nem guardado; com a bencao ativa o pool
-- nao aceita mais nada (so' volta a encher quando ela terminar).
-- `amount` = o que o client mandou. Sem valor, o pedido e' recusado (nao da'
-- pra adivinhar quanto o player quis doar).
local function doGlobalPurchase(cid, g, amount)
    -- Mesma leitura forcada da doacao de nacao: a decisao (ja' ativa? quanto
    -- falta?) sai do banco, nunca do cache curto.
    if not dbLoad(true) then
        sendMsg(cid, "error", "Statue Donation is temporarily unavailable (database).")
        return
    end
    local s = getState(g.key)

    -- guarda contra timestamp absurdo (base antiga / relogio errado)
    if s.until_ > now() + 365 * 24 * 3600 then
        s.until_ = 0
        dbSave(g.key)
    end

    if s.until_ > now() then
        sendMsg(cid, "info", g.label .. " blessing is already active (" .. formatTime(s.until_ - now()) ..
            " left). The pool can only be filled again after the blessing ends - nothing was charged.")
        return
    end

    local typed = tonumber(amount)
    if not typed then
        sendMsg(cid, "error", "Type how much gold you want to donate.")
        return
    end
    typed = math.floor(typed)

    if typed < CONFIG.minDonation then
        sendMsg(cid, "error", "The minimum donation is " .. CONFIG.minDonation .. " gold.")
        return
    end
    if typed > CONFIG.maxDonation then
        sendMsg(cid, "error", "That amount is too high (max " .. CONFIG.maxDonation .. " gold per donation).")
        return
    end

    local missing = g.cost - s.pool
    if missing <= 0 then
        -- Pool cheio sem ciclo aberto: fecha o ciclo (o UPDATE condicional
        -- garante que isso acontece uma vez so').
        activateGlobal(g)
        sendMsg(cid, "info", "The pool is already complete.")
        return
    end
    -- nunca cobra mais do que falta: o que passar disso nao e' descontado
    local paid = math.min(typed, missing)

    local ok, fromMoney, fromBank = takeGold(cid, paid)
    if not ok then
        local money, bank = playerTotalGold(cid)
        sendMsg(cid, "error", "You don't have " .. paid .. " gold. You have " .. (money + bank) ..
            " (backpack + bank).")
        return
    end

    -- Credito atomico + guarda de ciclo: se a bencao comecou no meio do
    -- caminho, o ouro volta pro player (nunca fica cobrado fora do pool).
    if not poolCredit(g.key, paid) then
        refundGold(cid, fromMoney, fromBank)
        sendMsg(cid, "info", g.label .. " was activated right now - nothing was charged " ..
            "(your " .. paid .. " gold is back).")
        return
    end
    s = getState(g.key)

    -- O que passar da meta NAO e' cobrado nem guardado pro proximo ciclo.
    local extra = ""
    if paid < typed then
        extra = " You typed " .. typed .. ", but only " .. paid .. " was missing: " ..
            (typed - paid) .. " was NOT charged."
    end

    -- Recibo com o split: deixa claro de onde saiu o ouro (pack/banco).
    if s.pool >= g.cost then
        doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "You donated " .. paid .. " gold to the " .. g.label ..
            " pool and completed it (" .. fromMoney .. " backpack + " .. fromBank .. " bank)." .. extra)
        activateGlobal(g)
    else
        doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "You donated " .. paid .. " gold to the " .. g.label ..
            " pool. (" .. math.floor(s.pool) .. "/" .. g.cost .. " - " .. fromMoney .. " backpack + " ..
            fromBank .. " bank)" .. extra)
        doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, (g.cost - math.floor(s.pool)) ..
            " gold left for the whole server to get the " .. g.label .. " blessing.")
        StatueDonation.sendState(cid)
    end
end

local function hasCooldown(cid)
    if type(exhaustion) ~= "table" or type(exhaustion.check) ~= "function" then
        return false
    end
    if exhaustion.check(cid, "statueDonation") then
        return true
    end
    exhaustion.set(cid, "statueDonation", CONFIG.cooldown)
    return false
end

-- ============================================================================
-- Admin (!resetstatue)
-- ============================================================================
-- Zera pool e/ou encerra bencao SEM passar por dinheiro. Quem chama e' a staff,
-- por data/talkactions/scripts/resetstatue.lua - nada aqui confere saldo.
--
--   what = "pool" | "blessing" | "all"   (omisso = "all")
--
-- Encerrar a bencao (what = blessing|all) TIRA o buff de todos: de quem esta'
-- online na hora e, pra quem esta' offline, no proximo login/relogin - o icone
-- e' derivado do estado (bonus_until = 0), e applyBuffs manda o "remove" de
-- todas as chaves da estatua que nao valem mais.
--
-- Devolve false + motivo (chave invalida / banco fora) ou true + o que mudou,
-- pro comando montar o recibo.
function StatueDonation.resetKey(key, what)
    local entry = KEYS[key]
    if not entry then
        return false, "chave desconhecida"
    end

    what = what or "all"
    if what ~= "pool" and what ~= "blessing" and what ~= "all" then
        return false, "opcao invalida (use pool, blessing ou all)"
    end

    if not dbLoad(true) then
        return false, "banco fora do ar - NADA foi alterado"
    end

    local s = getState(key)
    local info = {
        key = key,
        label = entry.label,
        kind = GLOBAL_BY_KEY[key] and "global" or "nation",
        poolBefore = math.floor(s.pool),
        poolAfter = math.floor(s.pool),
        leftBefore = math.max(0, s.until_ - now()),
        wasActive = s.until_ > now(),
    }

    -- UPDATE pontual, nunca a linha inteira: zerar o pool nao pode escrever de
    -- volta um `bonus_until` que a memoria leu antes de uma ativacao, e encerrar
    -- a bencao nao pode apagar uma doacao que chegou no meio do comando.
    local t = now()
    if what ~= "blessing" then
        db.executeQuery("UPDATE `" .. CONFIG.tableName .. "` SET `pool` = 0, `updated` = " .. t ..
            " WHERE `name` = " .. db.escapeString(key) .. ";")
        info.poolAfter = 0
    end
    if what ~= "pool" then
        db.executeQuery("UPDATE `" .. CONFIG.tableName .. "` SET `bonus_until` = 0, `updated` = " .. t ..
            " WHERE `name` = " .. db.escapeString(key) .. ";")
    end

    dbLoad(true)
    info.activeAfter = isActive(key)

    if what ~= "pool" then
        -- Encerrou a bencao: tira o buff de TODOS os online, mesmo que o banco
        -- ja' a considerasse expirada (drift de icone) - e e' o que reseta o
        -- que os players "pegaram de alguma forma". O resto (offline) cai no
        -- login/relogin, porque o estado novo nao reativa nada.
        info.removed = hideEveryone(key)
    else
        -- So' zerou o pool: a bencao (se houver) continua de pe' e o buff nao e'
        -- tocado. Todo mundo recebe o estado novo pra janela aberta parar de
        -- mostrar o pool antigo.
        for _, pid in ipairs(getPlayersOnline()) do
            if isPlayer(pid) then
                StatueDonation.sendState(pid)
            end
        end
    end

    return true, info
end

-- Estado de tudo (nacoes + abas, na mesma ordem da janela). Usado pelo
-- !resetstatue sem parametro e pra validar as chaves digitadas.
function StatueDonation.adminList()
    if not dbLoad(true) then
        return nil, "banco fora do ar"
    end

    local out = {}
    for _, n in ipairs(NATIONS) do
        local s = getState(n.key)
        table.insert(out, {
            key = n.key, label = n.label, kind = "nation",
            pool = math.floor(s.pool), goal = CONFIG.goal,
            until_ = math.floor(s.until_), left = math.max(0, s.until_ - now()),
        })
    end
    for _, g in ipairs(GLOBALS) do
        local s = getState(g.key)
        table.insert(out, {
            key = g.key, label = g.label, kind = "global",
            cost = g.cost, goal = g.cost, hours = g.hours,
            pool = math.floor(s.pool),
            until_ = math.floor(s.until_), left = math.max(0, s.until_ - now()),
        })
    end
    return out
end

-- ============================================================================
-- Entradas no jogo
-- ============================================================================
function StatueDonation.openWindow(cid)
    if not isPlayer(cid) then
        return false
    end
    -- force: usar a estatua mostra o estado real (o cache curto pode ser de
    -- antes de uma bencao ativada por outra interface).
    if not dbLoad(true) then
        doPlayerSendCancel(cid, "The statue is silent. (database offline)")
        return false
    end
    StatueDonation.applyBuffs(cid)
    StatueDonation.sendState(cid, true)
    return true
end

function StatueDonation.onOpcode(cid, buffer)
    if not isPlayer(cid) then
        return false
    end
    -- force: doar/comprar tem que validar pool, meta e saldo com o numero exato
    -- do banco (e "open" tem que responder o estado real, nao o cache vencido).
    if not dbLoad(true) then
        sendMsg(cid, "error", "Statue Donation is temporarily unavailable (database).")
        return true
    end

    local ok, decoded = pcall(json.decode, buffer)
    if not ok or type(decoded) ~= "table" then
        return false
    end

    local action = decoded.action
    local data = decoded.data or {}

    if action == "open" then
        StatueDonation.applyBuffs(cid)
        StatueDonation.sendState(cid, true)
        return true
    end

    if action ~= "donate" then
        return false
    end

    if hasCooldown(cid) then
        return true
    end

    local target = tostring(data.target or "")

    local nation = NATION_BY_KEY[target]
    if nation then
        local amount = tonumber(data.amount)
        if not amount then
            sendMsg(cid, "error", "Type how much gold you want to donate.")
            return true
        end
        doNationDonation(cid, nation, math.floor(amount))
        return true
    end

    local g = GLOBAL_BY_KEY[target]
    if g then
        doGlobalPurchase(cid, g, data.amount)
        return true
    end

    sendMsg(cid, "error", "Invalid target.")
    return true
end

-- Acao da estatua (registrada por ACTIONID em data/actions/actions.xml)
function StatueDonation.onUseStatue(cid, item, fromPosition, itemEx, toPosition)
    if not isPlayer(cid) then
        return false
    end
    StatueDonation.openWindow(cid)
    doSendMagicEffect(getThingPos(cid), CONST_ME_MAGIC_BLUE)
    return true
end

function StatueDonation.onLogin(cid)
    if not dbLoad(true) then
        return
    end
    -- O client acabou de abrir: a barra de buffs dele esta' vazia. Zera o mapa
    -- desta sessao (o cid pode ter sido reaproveitado por outro personagem) e
    -- reenvia os icones que valem - e, principalmente, manda o "remove" de tudo
    -- que NAO vale mais (bencao resetada/terminada enquanto ele estava fora).
    shown[cid] = nil
    StatueDonation.applyBuffs(cid, true)
    -- Manda o estado da estatua tambem: quem reloga nao fica com a janela
    -- mostrando o pool/bencao da sessao anterior (o client guarda o ultimo
    -- estado recebido, e sem isto ele so' acerta quando abre a estatua de novo).
    StatueDonation.sendState(cid)
end

-- ============================================================================
-- Expiracao
-- ============================================================================
-- Encerra o ciclo de `key` que venceu. A escrita e' condicional e NAO toca no
-- pool: `bonus_until = 0` so' entra na linha que ainda estava expirada, entao
-- encerrar duas vezes (ou encerrar em cima de uma doacao que acabou de chegar)
-- nao apaga pool nenhum. O timeout de 60s nao e' a fonte da verdade: quem diz
-- que a bencao acabou e' `until_ <= agora`, em todo lugar (`isActive`); este
-- aqui so' normaliza o banco e cuida do icone/anuncio.
local function expire(key, text)
    if not dbReady then
        return false
    end
    local t = now()
    local s = getState(key)
    if not (s.until_ > 0 and s.until_ <= t) then
        return false
    end

    db.executeQuery("UPDATE `" .. CONFIG.tableName .. "` SET `bonus_until` = 0, `updated` = " .. t ..
        " WHERE `name` = " .. db.escapeString(key) ..
        " AND `bonus_until` > 0 AND `bonus_until` <= " .. t .. ";")
    dbLoad(true)

    hideEveryone(key)
    broadcast(text)
    return true
end

function StatueDonation.checkExpired()
    -- Reler antes: expiracao e' decisao do BANCO, nao do cache - quem chama isto
    -- (o tique) pode estar com a memoria de um minuto atras.
    if not dbLoad(true) then
        return
    end
    for _, n in ipairs(NATIONS) do
        expire(n.key, n.label .. "'s blessing has ended. Donate again to fill the pool!")
    end
    for _, g in ipairs(GLOBALS) do
        expire(g.key, "The " .. string.lower(g.label) .. " blessing has ended.")
    end
end

-- ============================================================================
-- Boot: registra os buffs (nao toca no banco - isso e' lazy, no primeiro uso)
-- ============================================================================
registerBuffs()

local function statueTick()
    -- force: o tique e' o momento de reconciliar com o banco (bencao ativada por
    -- outra interface, expirada, resetada pela staff...).
    if dbLoad(true) then
        pcall(StatueDonation.checkExpired)
        -- Depois de expirar/resetar, reconcilia: quem deveria estar com o icone
        -- (bencao viva no banco) recebe de volta, quem nao deveria perde. E' o
        -- que mantem a bencao de pe' depois de um save/restart e de uma morte.
        pcall(StatueDonation.sweep)
    end
    addEvent(statueTick, 60000)
end

if type(addEvent) == "function" then
    addEvent(statueTick, 60000)
end

return StatueDonation
