enableLiveCasting = true
unmountPlayerInPz = true

serverInTest = false
noDamageToPartyMembers = 1

accountManager = true
namelockManager = true
newPlayerChooseVoc = true
newPlayerSpawnPosX = 500
newPlayerSpawnPosY = 500
newPlayerSpawnPosZ = 7
newPlayerTownId = 2
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
protectionLevel = 50
pvpTileIgnoreLevelAndVocationProtection = true
pzLocked = 1 * 60 * 1000
huntingDuration = 1 * 1000
criticalHitChance = 0
criticalHitMultiplier = 1.15
displayCriticalHitNotify = true
removeWeaponAmmunition = true
removeWeaponCharges = true
removeRuneCharges = true
whiteSkullTime = 15 * 60 * 1000
noDamageToSameLookfeet = false
showHealthChange = true
showManaChange = false
showHealthChangeForMonsters = false
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
ip = "127.0.0.1"
bindOnlyGlobalAddress = true
loginPort = 9191
gamePort = "9192"
loginTries = 10
retryTimeout = 5 * 1000
loginTimeout = 60 * 1000
maxPlayers = 1000
motd = "Welcome to fantastic world of Avatar!"
displayOnOrOffAtCharlist = false
onePlayerOnlinePerAccount = false
allowClones = 0
serverName = "Raava"
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
canOnlyRopePlayers = true

mapName = "forgotten.otbm"
mapAuthor = "Naldo"
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

useMounts = true
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

ghostModeInvisibleEffect = false
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

experienceStages = true
rateExperience = 1.0
rateExperienceFromPlayers = 0
rateSkill = 2
rateMagic = 0.0
rateLoot = 100

rateLootPercent = 2.0 


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


globalSaveEnabled = false
globalSaveHour = 7
globalSaveMinute = 0
shutdownAtGlobalSave = true
cleanMapAtGlobalSave = false
closeInstanceOnShutdown = true

deSpawnRange = 2
deSpawnRadius = 50
monsterSpawnWalkback = true
allowBlockSpawn = true

maxPlayerSummons = 1
teleportAllSummons = true
teleportPlayerSummons = true

statusPort = 9194
ownerName = "Tibia Avatar"
ownerEmail = "otavatartibia@gmail.com"
url = "tibiaavatar.com"
location = "Brazil"
displayGamemastersWithOnlineCommand = false

disableLuaErrors = false
displayPlayersLogging = true
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