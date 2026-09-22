-- ============================================================================
-- LUZ DO MUNDO (o client nao tem mais valor chumbado na source)
--
--   worldLightLevel:
--     0   = usa o ciclo dia/noite normal do servidor (default antigo)
--     40  = noite fechada (minimo aceito)
--     96  = penumbra: tudo visivel, sempre escuro  <-- usado no client novo
--     250 = dia claro (maximo aceito)
--
--   Qualquer valor acima de 0 CONGELA a luz: o ciclo dia/noite para de mexer
--   nela e o mundo fica sempre nesse nivel. O talkaction /worldlight <nivel>
--   continua funcionando pra testar ao vivo (dura ate' o proximo restart).
--
--   worldLightColor: cor da luz (215 = branco levemente quente).
--
--   Atencao: o client so' obedece isso se ele nao tiver a penumbra chumbada -
--   nesta versao o Item::draw nao ilumina mais e as magias iluminam.
-- ============================================================================
worldLightLevel = 200
worldLightColor = 215

enableLiveCasting = true
unmountPlayerInPz = true

serverInTest = false
noDamageToPartyMembers = 1

accountManager = true
namelockManager = true
newPlayerChooseVoc = true
newPlayerSpawnPosX = 505
newPlayerSpawnPosY = 342
newPlayerSpawnPosZ = 7
newPlayerTownId = 1
newPlayerLevel = 8
newPlayerMagicLevel = 0
generateAccountNumber = false
generateAccountSalt = false

useRookSystem = false
rookTownId = 1
rookLevelToGetRooked = 5
rookLevelToLeaveRook = 8

useFragHandler = true
fragsToRedSkull = 5
redSkullLength = 5 * 8 * 60 * 60
fragTime = 8 * 60 * 60
fragsToBanishment = fragsToRedSkull+9999
banKillLength = 7 * 24 * 60 * 60
useBlackSkull = false

notationsToBan = 3
warningsToFinalBan = 4
warningsToDeletion = 5
banLength = 7 * 24 * 60 * 60
killsBanLength = 1 * 24 * 60 * 60
finalBanLength = 30 * 24 * 60 * 60
ipBanLength = 1 * 24 * 60 * 60
allowedMaxSizePackets = 20

worldType = "open"
protectionLevel = 5
pvpTileIgnoreLevelAndVocationProtection = true
pzLocked = 1 * 60 * 1000
huntingDuration = 1 * 1000
criticalHitChance = 1
criticalHitMultiplier = 1.30
displayCriticalHitNotify = true
removeWeaponAmmunition = true
removeWeaponCharges = true
-- HIT BASICO DO JOGADOR: false = jogador NAO bate com arma/punho (todo dano vem
-- de spells/bending). Monstros continuam atacando normalmente. Tambem trava as
-- skills fist/club/sword/axe/distance de subirem pro jogador.
playerBasicAttack = false
removeRuneCharges = true
whiteSkullTime = 15 * 60 * 1000
noDamageToSameLookfeet = false
showHealthChange = true
showManaChange = false
showHealthChangeForMonsters = true
showManaChangeForMonsters = false
fieldOwnershipDuration = 5 * 1000
stopAttackingAtExit = false
loginProtectionPeriod = 5 * 1000
deathLostPercent = 6
stairhopDelay = 0.5 * 1000
pushCreatureDelay = 0.5 * 1000
deathContainerId = 1987
gainExperienceColor = 215
addManaSpentInPvPZone = true
recoverManaAfterDeathInPvPZone = false
squareColor = 0
allowFightback = true
fistBaseAttack = 7
useFairfightReduction = false
optionalWarAttackableAlly = false

worldId = 0
-- IP que o servidor anuncia no login (e no status XML). Nesta maquina o unico
-- adaptador e' 89.213.41.202, entao e' esse que o client precisa usar.
-- Com bindOnlyGlobalAddress = false o engine ainda binda loopback + IPs locais,
-- ou seja 127.0.0.1 continua funcionando pra quem joga do proprio host.
ip = "89.213.41.202"
bindOnlyGlobalAddress = false
fullMapOnLogin = false
-- Envia o effect id dos magic effects com 2 bytes (0-65535) no lugar de 1 byte
-- (0-255). Use SOMENTE se o seu client tiver a feature OTC 'GameMagicEffectU16'
-- habilitada (g_game.enableFeature(GameMagicEffectU16)) - se o client nao tiver,
-- todos os effects quebram. Habilita effects custom acima de 255 (ex.: 183+).
magicEffectU16 = true
-- Envia quem causou cada magic effect (opcode 72) junto do effect, pro client
-- conseguir separar a opacidade em Self bend / Others bend / Monsters bend.
-- Precisa de um client que entenda o opcode 72 (o oficial deste projeto).
-- Effects sem origem (do proprio motor) vao com 0.
-- Desligue se algum client antigo for jogar, senao os effects dele quebram.
magicEffectSource = true
loginPort = 9191
gamePort = "9192"
loginTries = 10
retryTimeout = 5 * 1000
loginTimeout = 60 * 1000
maxPlayers = 1000
motd = "Welcome to Avatar Eclipse!"
displayOnOrOffAtCharlist = false
onePlayerOnlinePerAccount = false
allowClones = 0
serverName = "Avatar Eclipse"
loginMessageEN = "Welcome to the amazing world of Avatar, enjoy!"
loginMessagePT = "Seja bem-vindo ao fantastico mundo de Avatar!"
statusTimeout = 1 * 5 * 1000
replaceKickOnLogin = true
forceSlowConnectionsToDisconnect = false
loginOnlyWithLoginServer = false
premiumPlayerSkipWaitList = true
packetsPerSecond = 50

rsaPrime1 = "12279057324098068547540485178818637280302654601754437063470340454185720291237821432013079408880214394550210693071193216029519025330861649080272470174987527"
rsaPrime2 = "11820993038806600074715798302257204344006010224361321454734586379088710024808570690447456505019946952067367455511779202734158468284858222689047746399005877"
rsaPublic = "65537"
rsaModulus = "145150651151270466484779919781568812250201875212284230137168501189839458887373507732812873500545439343350792465372778666985818022861514964617895776320631654596449465324099038384692053272779586962267710456835672119883134177743573901310535581143694244349508718386785205908159997953997910264735418591383674696179"
rsaPrivate = "81787741973451878882920378987347194695751328987277904855354355737040016140392890940343833142013549354887438609659977884469113446575675185214606332727593341943803134933621105738588457727520714785117526175249052287585734466904984757715903378516015572122319454028431774597113879173028222057047543224219276054017"

--sqlType = "mysql"
sqlType = "mysql"
sqlHost = "127.0.0.1"
sqlPort = 3306
sqlUser = "root"
sqlPass = ""
sqlDatabase = "avatar"
sqlFile = "schemas/otxserver.s3db"
sqlKeepAlive = 0
mysqlReadTimeout = 0
mysqlWriteTimeout = 0
mysqlReconnectionAttempts = 3
encryptionType = "sha1"

deathListEnabled = true
deathListRequiredTime = 1 * 60 * 1000
deathAssistCount = 1
maxDeathRecords = 5
multipleNames = false

externalGuildWarsManagement = false
ingameGuildManagement = true
levelToFormGuild = 20
premiumDaysToFormGuild = 1
guildNameMinLength = 4
guildNameMaxLength = 20

buyableAndSellableHouses = true
houseNeedPremium = true
bedsRequirePremium = false
levelToBuyHouse = 40
housesPerAccount = 1
houseRentAsPrice = false
housePriceAsRent = false
housePriceEachSquare = 6000
houseSkipInitialRent = true
houseRentPeriod = "weekly"
houseCleanOld = 0
guildHalls = false
houseProtection = true

timeBetweenActions = 500
timeBetweenExActions = 500
timeBetweenCustomActions = 100
hotkeyAimbotEnabled = true
tibiaClassicSlots = true
canOnlyRopePlayers = false

mapName = "forgotten.otbm"
mapAuthor = "Sirius"
randomizeTiles = false
storeTrash = true
cleanProtectedZones = true

mailboxDisabledTowns = ""
mailMaxAttempts = 20
mailBlockPeriod = 60 * 60 * 1000
mailAttemptsFadeTime = 10 * 60 * 1000

daemonize = false
defaultPriority = "high"
niceLevel = 5
serviceThreads = 1
coresUsed = "-1"

startupDatabaseOptimization = true
updatePremiumStateAtStartup = true
confirmOutdatedVersion = true
skipItemsVersionCheck = false

formulaLevel = 1.0
formulaMagic = 1.0
bufferMutedOnSpellFailure = false
spellNameInsteadOfWords = true
emoteSpells = true
unifiedSpells = true
enableCooldowns = false

allowChangeOutfit = true
allowChangeColors = true
allowChangeAddons = true
disableOutfitsForPrivilegedPlayers = false
addonsOnlyPremium = true

dataDirectory = "data/"
logsDirectory = "data/logs/"
bankSystem = true
promptExceptionTracerErrorBox = true
maximumDoorLevel = 500
maxMessageBuffer = 4
logPlayersStatements = true
tradeLimit = 100
useCapacity = true
playerFollowExhaust = 300

-- MONTARIA DESATIVADA: com false o servidor nao manda a lista de montarias
-- pro client (a janela/aba de montaria fica vazia) e o engine nao oferece
-- montaria. O gate final continua sendo o evento "mount" em
-- data/creaturescripts/scripts/onMount.lua (retorna false sempre).
useMounts = false
unmountPlayerInPz = true

defaultDepotSizePremium = 2000
defaultDepotSize = 2000

separateVipListPerCharacter = true
vipListDefaultLimit = 100
vipListDefaultPremiumLimit = 100

houseDataStorage = "binary"
saveGlobalStorage = true
storePlayerDirection = false
savePlayerData = true

checkCorpseOwner = false
monsterLootMessage = 0
monsterLootMessageType = 29

ghostModeInvisibleEffect = true
ghostModeSpellEffects = true

idleWarningTime = 13 * 60 * 1000
idleKickTime = 14 * 60 * 1000
reportsExpirationAfterReads = 1
playerQueryDeepness = -1
tileLimit = 0
protectionTileLimit = 0
houseTileLimit = 0

freePremium = false
premiumForPromotion = true

blessings = true
blessingOnlyPremium = false
blessingReductionBase = 30
blessingReductionDecrement = 5
eachBlessReduction = 8
pvpBlessingThreshold = 40
fairFightTimeRange = 60

experienceStages = false
rateExperience = 200
rateExperienceFromPlayers = 0.3
rateSkill = 1
rateMagic = 1
rateLoot = 0.1

rateLootPercent = 0.1


rateSpawnMin = 1
rateSpawnMax = 1

rateMonsterHealth = 1.0
rateMonsterMana = 1.0
rateMonsterAttack = 1.0
rateMonsterDefense = 1.0

minLevelThresholdForKilledPlayer = 0.9
maxLevelThresholdForKilledPlayer = 1.1

rateStaminaLoss = 2
rateStaminaGain = 3
rateStaminaThresholdGain = 4
staminaRatingLimitTop = 40 * 60
staminaRatingLimitBottom = 14 * 60
staminaLootLimit = 14 * 60
rateStaminaAboveNormal = 1
rateStaminaUnderNormal = 0.5
staminaThresholdOnlyPremium = false

experienceShareRadiusX = 35
experienceShareRadiusY = 35
experienceShareRadiusZ = 1
experienceShareLevelDifference = 2 / 3
extraPartyExperienceLimit = 20
extraPartyExperiencePercent = 50
experienceShareActivity = 2 * 60 * 1000


globalSaveEnabled = true
globalSaveHour = 7
globalSaveMinute = 0
shutdownAtGlobalSave = false
cleanMapAtGlobalSave = false
closeInstanceOnShutdown = false

deSpawnRange = 2
deSpawnRadius = 50
monsterSpawnWalkback = true
allowBlockSpawn = false

maxPlayerSummons = 1
teleportAllSummons = true
teleportPlayerSummons = true

statusPort = 9194
ownerName = "Sirius"
ownerEmail = "otavatartibia@gmail.com"
url = "tibiaavatar.com"
location = "Brazil"
displayGamemastersWithOnlineCommand = false

disableLuaErrors = false
-- Loga "<nome> has logged in/out." no console do servidor (player.cpp).
-- false silencia esses avisos de entrada/saida.
displayPlayersLogging = false

-- DIAGNOSTICO DE PARALISIA (conditionTrace)
-- Ligado: toda CONDITION_PARALYZE que chega num player imprime no console a
-- linha [COND-TRACE] com o que a condition faz (ticks/speedDelta/formula), a
-- velocidade do momento e o stack trace nativo de quem a aplicou - precisa do
-- .pdb ao lado do .exe para sair com o nome das funcoes.
-- DESLIGUE (false) quando terminar o diagnostico: e' log de debug.
conditionTrace = true
prefixChannelLogs = ""
runFile = ""
outputLog = ""
truncateLogOnStartup = false

managerPort = 9195
managerLogs = true
managerPassword = ""
managerLocalhostOnly = true
managerConnectionsLimit = 1

adminPort = 9195
adminLogs = true
adminPassword = ""
adminLocalhostOnly = true
adminConnectionsLimit = 1
adminRequireLogin = true
adminEncryption = ""
adminEncryptionData = ""
-- =========================================================================
--  ARVORES DE RECOMPENSA (tronco brilhante)
-- =========================================================================
--  Arvores do mapa que podem virar um tronco brilhante com recompensa.
--  O servidor procura esses ids enquanto carrega o mapa, entao basta editar
--  a lista aqui e reiniciar o server: nao precisa mexer no mapa nem
--  recompilar nada.
--
--  Um tronco, ao dar use, entrega o premio e some. A arvore original volta
--  quando nao tiver nenhum player no raio configurado abaixo.
rewardTreeIds = {2700, 2708, 2701, 2703, 2704, 2705, 2707}

rewardTreeChance        = 60  -- 1 em cada N arvores do mapa vira tronco (~24 troncos no mapa inteiro;
                                --  andando na mata o player cruza ~1 tronco a cada 5 min)
rewardTreeCrystalChance = 300   -- entre os troncos, 1 em VALOR POSTO é o de crystal coin
rewardTreeRespawnRadius = 12    -- tiles sem player pra arvore original voltar
rewardTreeMinDistance   = 100   -- tiles minimos entre dois troncos (0 = desligado; alto demais = menos troncos)
rewardTreeReroll        = true -- a arvore volta original (true = pode sortear de novo)
rewardTreeMaintain      = true  -- repoe troncos com o tempo (senao o estoque acaba)
rewardTreeRefillSeconds = 600   -- de quanto em quanto tempo tenta repor (segundos)
rewardTreeEffect        = 207    -- efeito de magia ao abrir/aparecer (0 = nenhum)
rewardTreeSendText      = false -- mensagem pro player ao achar o premio (silencioso)
rewardTreeVerbose       = false -- prints do console do server (silencioso)
