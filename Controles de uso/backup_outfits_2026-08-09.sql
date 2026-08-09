-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: 127.0.0.1    Database: avatar
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `player_storage`
--

DROP TABLE IF EXISTS `player_storage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_storage` (
  `player_id` int(11) NOT NULL,
  `key` varchar(32) NOT NULL DEFAULT '0',
  `value` text NOT NULL,
  UNIQUE KEY `player_id_2` (`player_id`,`key`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_storage_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_storage`
--

LOCK TABLES `player_storage` WRITE;
/*!40000 ALTER TABLE `player_storage` DISABLE KEYS */;
INSERT INTO `player_storage` VALUES (2,'10001501','65539'),(2,'10001502','131075'),(2,'10001503','196611'),(2,'10001504','262147'),(2,'10001505','327683'),(2,'10001506','393219'),(2,'10001507','458755'),(2,'10001508','524291'),(2,'10001509','589827'),(2,'10001510','655363'),(2,'10001511','720899'),(2,'10001512','786435'),(2,'10001513','851971'),(2,'10001514','917507'),(2,'10001515','983043'),(2,'10001516','1048579'),(2,'10001517','1114115'),(2,'10001518','1179651'),(2,'10001519','1245187'),(2,'10001520','1310723'),(2,'10001521','1376259'),(2,'10001522','1441795'),(2,'10001523','1507331'),(2,'10001524','1572867'),(2,'10001525','1638403'),(2,'10001526','1703939'),(2,'10001527','1769475'),(2,'10001528','1835011'),(2,'10001529','1900547'),(2,'10001530','1966083'),(2,'10001531','2031619'),(2,'10001532','2162691'),(2,'10001533','2228227'),(2,'10001534','2293763'),(2,'10001535','2359299'),(2,'10001536','2424835'),(2,'10001537','2490371'),(2,'10001538','2555907'),(2,'10001539','2621443'),(2,'10001540','2686979'),(2,'10001541','2752515'),(2,'10001542','2818051'),(2,'10001543','2883587'),(2,'1150001','1786259976'),(2,'188100','150'),(2,'40250','1'),(2,'42001','1'),(2,'45001','2'),(2,'45002','0'),(2,'45003','1'),(2,'45900','1'),(2,'87654','-1'),(2,'920009','1'),(2,'920101','1'),(2,'920102','1'),(2,'920103','1'),(2,'9701','0'),(2,'9702','0'),(2,'9703','0'),(2,'9704','0'),(2,'9705','0'),(2,'9706','0'),(2,'9707','0'),(2,'9708','0'),(2,'9709','0'),(2,'9710','0'),(2,'9711','0'),(2,'9712','0'),(2,'9713','0'),(2,'9714','0'),(2,'9715','0'),(2,'9716','0'),(2,'9717','0'),(2,'9718','0'),(2,'9719','0'),(2,'9720','0'),(2,'9721','0'),(2,'9722','0'),(2,'9723','0'),(2,'9724','0'),(2,'9725','0'),(2,'9726','0'),(2,'9727','0'),(2,'9728','0'),(2,'9729','0'),(2,'9730','0'),(2,'9731','0'),(2,'9740','1786244760'),(2,'9741','8'),(2,'9999','1786240808'),(2,'AirBarrierReduction','1786040925'),(2,'appaDestX','-1'),(2,'appaDestY','-1'),(2,'appaDestZ','-1'),(2,'appaFlying','-1'),(2,'appaLookAddons','0'),(2,'appaLookBody','114'),(2,'appaLookFeet','0'),(2,'appaLookHead','115'),(2,'appaLookLegs','68'),(2,'appaLookType','1152'),(2,'appaLookTypeEx','0'),(2,'appaPhase','-1'),(2,'appaSaved','-1'),(2,'autolootdesativo','1'),(2,'BendReflection','1786040917'),(2,'bloodKills','0'),(2,'bombermanActiveBombs','0'),(2,'bombermanArena','-1'),(2,'bombermanBombSize','1'),(2,'bombermanInMatch','-1'),(2,'bombermanInQueue','-1'),(2,'bombermanKick','0'),(2,'bombermanMatchStart','-1'),(2,'bombermanMaxBombs','1'),(2,'bombermanOutfitAddons','0'),(2,'bombermanOutfitBody','0'),(2,'bombermanOutfitEx','0'),(2,'bombermanOutfitFeet','0'),(2,'bombermanOutfitHead','0'),(2,'bombermanOutfitLegs','0'),(2,'bombermanOutfitMount','0'),(2,'bombermanOutfitType','0'),(2,'bombermanPartner','-1'),(2,'bombermanSavedSpeed','0'),(2,'bombermanSpeed','1'),(2,'cantEarthArmor','1786236512'),(2,'canturecover','1786256632'),(2,'currentCid','268446600'),(2,'currentFold','water jump'),(2,'DailyHunt_Claimed_2','0'),(2,'DailyHunt_Claimed_5','0'),(2,'DailyHunt_Day','dy780'),(2,'DailyHunt_Kill_1','0'),(2,'DailyHunt_Kill_2','0'),(2,'DailyHunt_Kill_3','0'),(2,'DailyHunt_Kill_4','0'),(2,'DailyHunt_Kill_5','0'),(2,'DailyHunt_Monster_1','slick water elemental'),(2,'DailyHunt_Monster_2','pirate marauder'),(2,'DailyHunt_Monster_3','midnight panther'),(2,'DailyHunt_Monster_4','rotworm queen'),(2,'DailyHunt_Monster_5','blazing fire elemental'),(2,'dailyTaskColdown','1786034356'),(2,'debuffValue','20'),(2,'defMsg','1785161755'),(2,'earthArmorActive','1785063233'),(2,'entroumontado','-1'),(2,'exaustedairball','1785687634'),(2,'exaustedairbarrier','1785161807'),(2,'exaustedairboost','1785531689'),(2,'exaustedairburst','1785687633'),(2,'exaustedairdeflection','1785161846'),(2,'exaustedairdoom','1785161805'),(2,'exaustedairfan','1785687631'),(2,'exaustedairforce','1785531680'),(2,'exaustedairgale','1785687633'),(2,'exaustedairgust','1785531677'),(2,'exaustedairjump','1785416140'),(2,'exaustedairrecover','1785687607'),(2,'exaustedairrun','1786232199'),(2,'exaustedairstormcall','1785161793'),(2,'exaustedairtrap','1785161778'),(2,'exaustedairvortex','1785161812'),(2,'exaustedairwindstorm','1785161788'),(2,'exaustedairwings','1785687629'),(2,'exaustedeartharena','1785063265'),(2,'exaustedeartharmor','1785063294'),(2,'exaustedearthaura','1785063265'),(2,'exaustedearthcataclysm','1785063263'),(2,'exaustedearthcollapse','1786130652'),(2,'exaustedearthcrush','1786049956'),(2,'exaustedearthcurse','1785788241'),(2,'exaustedearthfists','1785063225'),(2,'exaustedearthfury','1786235069'),(2,'exaustedearthgrowth','1785788266'),(2,'exaustedearthingrain','1785063255'),(2,'exaustedearthjump','1785788256'),(2,'exaustedearthlavaball','1785063294'),(2,'exaustedearthleech','1786236512'),(2,'exaustedearthpetrify','1786235073'),(2,'exaustedearthpull','1786235063'),(2,'exaustedearthpunch','1786035275'),(2,'exaustedearthquake','1785063259'),(2,'exaustedearthrecover','1786049956'),(2,'exaustedearthrock','1786049958'),(2,'exaustedearthsmash','1785063216'),(2,'exaustedearthtrack','1785788300'),(2,'exaustedfirebolt','1785468599'),(2,'exaustedfirebomb','1786040928'),(2,'exaustedfirecannon','1786040964'),(2,'exaustedfireclock','1786040954'),(2,'exaustedfireconflagration','1786041008'),(2,'exaustedfiredischarge','1786040974'),(2,'exaustedfireexplosion','1786040949'),(2,'exaustedfirefocus','1786041014'),(2,'exaustedfireimpulse','1785242932'),(2,'exaustedfirejump','1785707208'),(2,'exaustedfirekick','1786049975'),(2,'exaustedfirelightning','1785468606'),(2,'exaustedfiremeteor','1786041008'),(2,'exaustedfireoverload','1786040971'),(2,'exaustedfirerecover','1786235549'),(2,'exaustedfireres','1786040828'),(2,'exaustedfireskyfall','1786049999'),(2,'exaustedfirestar','1786040796'),(2,'exaustedfirestriker','1786040974'),(2,'exaustedfirethunderbolt','1785468612'),(2,'exaustedfirethunderstorm','1786040978'),(2,'exaustedfirevoltage','1785468726'),(2,'exaustedfirewhip','1786040827'),(2,'exaustedfirewrath','1785468616'),(2,'exaustedwaterblizzard','1785153335'),(2,'exaustedwaterbloodBending','1785153372'),(2,'exaustedwaterbloodControl','1785153337'),(2,'exaustedwaterbubbles','1785153272'),(2,'exaustedwatercannon','1786240987'),(2,'exaustedwaterclock','1785153320'),(2,'exaustedwaterexplosion','1786240971'),(2,'exaustedwaterflow','1785162064'),(2,'exaustedwaterheal','1786256635'),(2,'exaustedwatericeGolem','1785150308'),(2,'exaustedwatericeSpikes','1786240961'),(2,'exaustedwaterjump','1786256656'),(2,'exaustedwaterprotect','1785162096'),(2,'exaustedwaterpunch','1785153254'),(2,'exaustedwaterrain','1785153301'),(2,'exaustedwaterrecover','1786256632'),(2,'exaustedwaterregen','1785788430'),(2,'exaustedwaterres','1785788396'),(2,'exaustedwatershards','1786240984'),(2,'exaustedwatersurf','1785788448'),(2,'exaustedwatertsunami','1785153316'),(2,'exaustedwaterwhip','1786256629'),(2,'expBeforeDie','-1'),(2,'fireclockTime','1786040936'),(2,'fireoverPower','0'),(2,'firstPendentes','1'),(2,'getAwnserAntiBot','-1'),(2,'getCompletedDailydy10','0'),(2,'getCompletedDailydy100','0'),(2,'getCompletedDailydy110','0'),(2,'getCompletedDailydy120','0'),(2,'getCompletedDailydy130','0'),(2,'getCompletedDailydy140','0'),(2,'getCompletedDailydy150','0'),(2,'getCompletedDailydy160','0'),(2,'getCompletedDailydy170','0'),(2,'getCompletedDailydy180','0'),(2,'getCompletedDailydy190','0'),(2,'getCompletedDailydy200','0'),(2,'getCompletedDailydy210','0'),(2,'getCompletedDailydy220','0'),(2,'getCompletedDailydy230','0'),(2,'getCompletedDailydy240','0'),(2,'getCompletedDailydy250','0'),(2,'getCompletedDailydy260','0'),(2,'getCompletedDailydy270','0'),(2,'getCompletedDailydy280','0'),(2,'getCompletedDailydy290','0'),(2,'getCompletedDailydy300','0'),(2,'getCompletedDailydy310','0'),(2,'getCompletedDailydy320','0'),(2,'getCompletedDailydy330','0'),(2,'getCompletedDailydy340','0'),(2,'getCompletedDailydy350','0'),(2,'getCompletedDailydy360','0'),(2,'getCompletedDailydy370','0'),(2,'getCompletedDailydy380','0'),(2,'getCompletedDailydy390','0'),(2,'getCompletedDailydy400','0'),(2,'getCompletedDailydy410','0'),(2,'getCompletedDailydy430','0'),(2,'getCompletedDailydy440','0'),(2,'getCompletedDailydy450','0'),(2,'getCompletedDailydy460','0'),(2,'getCompletedDailydy470','0'),(2,'getCompletedDailydy480','0'),(2,'getCompletedDailydy490','0'),(2,'getCompletedDailydy500','0'),(2,'getCompletedDailydy510','0'),(2,'getCompletedDailydy520','0'),(2,'getCompletedDailydy530','0'),(2,'getCompletedDailydy540','0'),(2,'getCompletedDailydy550','0'),(2,'getCompletedDailydy560','0'),(2,'getCompletedDailydy570','0'),(2,'getCompletedDailydy610','0'),(2,'getCompletedDailydy620','0'),(2,'getCompletedDailydy630','0'),(2,'getCompletedDailydy660','0'),(2,'getCompletedDailydy670','0'),(2,'getCompletedDailydy680','0'),(2,'getCompletedDailydy690','0'),(2,'getCompletedDailydy700','0'),(2,'getCompletedDailydy710','0'),(2,'getCompletedDailydy720','0'),(2,'getCompletedDailydy730','0'),(2,'getCompletedDailydy740','0'),(2,'getCompletedDailydy750','0'),(2,'getCompletedDailydy760','0'),(2,'getCompletedDailydy770','0'),(2,'getCompletedDailydy80','0'),(2,'getCompletedDailydy90','0'),(2,'getDailyCountdy10','0'),(2,'getDailyDificultdy10','extreme'),(2,'getPlayerLang','isEnglish'),(2,'getPointsInDodge','0'),(2,'healthvalue','6'),(2,'isAvatar','0'),(2,'isInDailyTask','0'),(2,'jamudouroupa','1'),(2,'jumpdebuff','1786256648'),(2,'lastGlobalSaveLogin','6'),(2,'lightning1328517','-1'),(2,'marketCheck','1786260006'),(2,'npodedeslogar','1786259981'),(2,'nuncaUsouArmor','1'),(2,'nuncaUsouWaterHeal','1'),(2,'onMoveFlyPosX','505'),(2,'onMoveFlyPosY','353'),(2,'onMoveFlyPosZ','7'),(2,'pendentes','0'),(2,'playerCanMoveDirection','0'),(2,'playerCantDown','-1'),(2,'playerHasGetInitialItens','1'),(2,'playerHasTotalAbsorve','1785162035'),(2,'playerOnAir','-1'),(2,'questChests25472','1'),(2,'questChests25479','1'),(2,'questChests25485','1'),(2,'spiritualTotem_18196','1'),(2,'startedWithMana','1'),(2,'TimeDailyDois','0'),(2,'TimeDailyQuatro','0'),(2,'TimeDailyTres','0'),(2,'TimeDailyUm','0'),(2,'timeLogin','1786259976'),(3,'10001501','1048579'),(3,'10001502','1114115'),(3,'10001503','1179651'),(3,'10001504','1245187'),(3,'10001505','1310723'),(3,'10001506','1572867'),(3,'10001507','1835011'),(3,'10001508','2490371'),(3,'10001509','2555907'),(3,'10001510','2621443'),(3,'10001511','2883587'),(3,'1150001','1786254912'),(3,'188100','20'),(3,'42001','1'),(3,'9701','0'),(3,'9702','0'),(3,'9703','0'),(3,'9704','0'),(3,'9705','0'),(3,'9706','0'),(3,'9707','0'),(3,'9708','0'),(3,'9709','0'),(3,'9710','0'),(3,'9711','0'),(3,'9712','0'),(3,'9713','0'),(3,'9714','0'),(3,'9715','0'),(3,'9716','0'),(3,'9717','0'),(3,'9718','0'),(3,'9719','0'),(3,'9720','0'),(3,'9721','0'),(3,'9722','0'),(3,'9723','0'),(3,'9724','0'),(3,'9725','0'),(3,'9726','0'),(3,'9727','0'),(3,'9728','0'),(3,'9729','0'),(3,'9730','0'),(3,'9731','0'),(3,'9740','1786241309'),(3,'9741','8'),(3,'9999','1786069901'),(3,'AirBarrierReduction','1786241353'),(3,'antiloop','-1'),(3,'autolootdesativo','1'),(3,'avatarAtkExh','1786241354'),(3,'AvatarMode','1786241353'),(3,'avatarProtec','1786241378'),(3,'bendvalue','21'),(3,'bombermanInQueue','-1'),(3,'cantEarthArmor','1786241350'),(3,'canturecover','1786241349'),(3,'currentCid','268446603'),(3,'currentFold','earth urecover'),(3,'DailyHunt_Claimed_2','0'),(3,'DailyHunt_Claimed_5','0'),(3,'DailyHunt_Day','dy770'),(3,'DailyHunt_Kill_1','0'),(3,'DailyHunt_Kill_2','0'),(3,'DailyHunt_Kill_3','0'),(3,'DailyHunt_Kill_4','0'),(3,'DailyHunt_Kill_5','0'),(3,'DailyHunt_Monster_1','slick water elemental'),(3,'DailyHunt_Monster_2','pirate marauder'),(3,'DailyHunt_Monster_3','midnight panther'),(3,'DailyHunt_Monster_4','rotworm queen'),(3,'DailyHunt_Monster_5','blazing fire elemental'),(3,'dailyTaskColdown','1786059330'),(3,'dodgevalue','0'),(3,'entroumontado','-1'),(3,'exaustedearthcrush','1786237145'),(3,'exaustedearthgrowth','1786237156'),(3,'exaustedearthjump','1786237111'),(3,'exaustedearthleech','1786241350'),(3,'exaustedearthpunch','1786241345'),(3,'exaustedearthrecover','1786241389'),(3,'exaustedearthrock','1786241348'),(3,'expBeforeDie','-1'),(3,'getAwnserAntiBot','-1'),(3,'getCompletedDailydy110','0'),(3,'getCompletedDailydy130','0'),(3,'getCompletedDailydy160','0'),(3,'getCompletedDailydy170','0'),(3,'getCompletedDailydy180','0'),(3,'getCompletedDailydy280','0'),(3,'getCompletedDailydy290','0'),(3,'getCompletedDailydy370','0'),(3,'getCompletedDailydy390','0'),(3,'getCompletedDailydy410','0'),(3,'getCompletedDailydy420','0'),(3,'getCompletedDailydy430','0'),(3,'getCompletedDailydy440','0'),(3,'getCompletedDailydy560','0'),(3,'getCompletedDailydy680','0'),(3,'getCompletedDailydy690','0'),(3,'getCompletedDailydy720','0'),(3,'getCompletedDailydy750','0'),(3,'getCompletedDailydy760','0'),(3,'getCompletedDailydy80','0'),(3,'getPlayerLang','isEnglish'),(3,'getPointsInDodge','0'),(3,'getTurnMsgPoints','1'),(3,'hasBuyearth leech','1'),(3,'hasPassiveDeathActive','1786239653'),(3,'healthvalue','2'),(3,'isAvatar','1'),(3,'isInDailyTask','0'),(3,'jamudouroupa','1'),(3,'knockoutAttackers',''),(3,'knockoutOldLevel','19'),(3,'lastGlobalSaveLogin','6'),(3,'lastHit','1073752975'),(3,'marketCheck','1786254919'),(3,'morreuD','-1'),(3,'npodedeslogar','1786254917'),(3,'onMoveFlyPosX','513'),(3,'onMoveFlyPosY','360'),(3,'onMoveFlyPosZ','7'),(3,'pendentes','0'),(3,'playerCanMoveDirection','0'),(3,'playerCantDown','-1'),(3,'playerHasGetInitialItens','1'),(3,'playerHasStun','1786236659'),(3,'playerOnAir','-1'),(3,'playerWithBless','-1'),(3,'speedvalue','0'),(3,'spiritualTotem_18193','1'),(3,'startedWithMana','1'),(3,'taskInCourse1','2'),(3,'taskInCourse1npcName','Don Corleone'),(3,'taskInCourse2','1'),(3,'taskInCourse27','1'),(3,'taskInCourse27npcName','Don Corleone'),(3,'taskInCourse2npcName','Don Corleone'),(3,'taskInCourse4','1'),(3,'taskInCourse48','1'),(3,'taskInCourse48npcName','Don Corleone'),(3,'taskInCourse49','1'),(3,'taskInCourse49npcName','Don Corleone'),(3,'taskInCourse4npcName','Don Corleone'),(3,'taskInCourse90','1'),(3,'taskInCourse90npcName','Don Corleone'),(3,'taskInCourse91','1'),(3,'taskInCourse91npcName','Don Corleone'),(3,'taskInCourseGetMonsters1','25'),(3,'TimeDailyDois','0'),(3,'TimeDailyQuatro','0'),(3,'TimeDailyTres','0'),(3,'TimeDailyUm','0'),(3,'timeLogin','1786254912'),(4,'10001501','65539'),(4,'10001502','131075'),(4,'10001503','196611'),(4,'10001504','262147'),(4,'10001505','327683'),(4,'10001506','1376259'),(4,'10001507','1638403'),(4,'10001508','1900547'),(4,'10001509','1966083'),(4,'10001510','2031619'),(4,'10001511','2686979'),(4,'1150001','1786256705'),(4,'188100','14'),(4,'42001','1'),(4,'9701','0'),(4,'9702','0'),(4,'9703','0'),(4,'9704','0'),(4,'9705','0'),(4,'9706','0'),(4,'9707','0'),(4,'9708','0'),(4,'9709','0'),(4,'9710','0'),(4,'9711','0'),(4,'9712','0'),(4,'9713','0'),(4,'9714','0'),(4,'9715','0'),(4,'9716','0'),(4,'9717','0'),(4,'9718','0'),(4,'9719','0'),(4,'9720','0'),(4,'9721','0'),(4,'9722','0'),(4,'9723','0'),(4,'9724','0'),(4,'9725','0'),(4,'9726','0'),(4,'9727','0'),(4,'9728','0'),(4,'9729','0'),(4,'9730','0'),(4,'9731','0'),(4,'9740','1786174847'),(4,'9741','8'),(4,'autolootdesativo','1'),(4,'bombermanInQueue','-1'),(4,'canturecover','1786174871'),(4,'currentCid','268446601'),(4,'currentFold','fire recover'),(4,'DailyHunt_Claimed_2','0'),(4,'DailyHunt_Claimed_5','0'),(4,'DailyHunt_Day','dy780'),(4,'DailyHunt_Kill_1','0'),(4,'DailyHunt_Kill_2','0'),(4,'DailyHunt_Kill_3','0'),(4,'DailyHunt_Kill_4','0'),(4,'DailyHunt_Kill_5','0'),(4,'DailyHunt_Monster_1','fire elemental'),(4,'DailyHunt_Monster_2','ice golem'),(4,'DailyHunt_Monster_3','panda'),(4,'DailyHunt_Monster_4','massive water elemental'),(4,'DailyHunt_Monster_5','slime summon'),(4,'dailyTaskColdown','1786174847'),(4,'exaustedfirekick','1786174869'),(4,'exaustedfirerecover','1786174871'),(4,'exaustedfireskyfall','1785884876'),(4,'expBeforeDie','-1'),(4,'fireoverPower','1786175145'),(4,'firstPendentes','1'),(4,'getAwnserAntiBot','-1'),(4,'getCompletedDailydy570','0'),(4,'getCompletedDailydy580','0'),(4,'getCompletedDailydy590','0'),(4,'getCompletedDailydy600','0'),(4,'getCompletedDailydy610','0'),(4,'getCompletedDailydy730','0'),(4,'getPlayerLang','isEnglish'),(4,'getPointsInDodge','0'),(4,'getTurnMsgPoints','1'),(4,'hasPassiveDeathActive','1786185825'),(4,'isAvatar','0'),(4,'isInDailyTask','0'),(4,'knockoutAttackers',''),(4,'knockoutOldLevel','14'),(4,'lastGlobalSaveLogin','6'),(4,'lastHit','1073752983'),(4,'marketCheck','1786256794'),(4,'morreuD','-1'),(4,'npodedeslogar','1786256693'),(4,'onMoveFlyPosX','509'),(4,'onMoveFlyPosY','360'),(4,'onMoveFlyPosZ','7'),(4,'pendentes','7'),(4,'playerCanMoveDirection','0'),(4,'playerHasGetInitialItens','1'),(4,'playerOnAir','-1'),(4,'playerWithBless','-1'),(4,'startedWithMana','1'),(4,'taskInCourse1','1'),(4,'taskInCourse1npcName','Don Corleone'),(4,'taskInCourse48','1'),(4,'taskInCourse48npcName','Don Corleone'),(4,'taskInCourse90','1'),(4,'taskInCourse90npcName','Don Corleone'),(4,'taskInCourse91','1'),(4,'taskInCourse91npcName','Don Corleone'),(4,'TimeDailyDois','0'),(4,'TimeDailyQuatro','0'),(4,'TimeDailyTres','0'),(4,'TimeDailyUm','0'),(4,'timeLogin','1786256688'),(5,'10001501','720899'),(5,'10001502','786435'),(5,'10001503','851971'),(5,'10001504','917507'),(5,'10001505','983043'),(5,'10001506','1507331'),(5,'10001507','1769475'),(5,'10001508','2293763'),(5,'10001509','2359299'),(5,'10001510','2424835'),(5,'10001511','2818051'),(5,'10001512','3407872'),(5,'10001513','3473408'),(5,'1150001','1786260143'),(5,'188100','19'),(5,'42001','1'),(5,'9701','0'),(5,'9702','0'),(5,'9703','0'),(5,'9704','0'),(5,'9705','0'),(5,'9706','0'),(5,'9707','0'),(5,'9708','0'),(5,'9709','0'),(5,'9710','0'),(5,'9711','0'),(5,'9712','0'),(5,'9713','0'),(5,'9714','0'),(5,'9715','0'),(5,'9716','0'),(5,'9717','0'),(5,'9718','0'),(5,'9719','0'),(5,'9720','0'),(5,'9721','0'),(5,'9722','0'),(5,'9723','0'),(5,'9724','0'),(5,'9725','0'),(5,'9726','0'),(5,'9727','0'),(5,'9728','0'),(5,'9729','0'),(5,'9730','0'),(5,'9731','0'),(5,'9740','1786241108'),(5,'9741','8'),(5,'autolootdesativo','1'),(5,'bendvalue','10'),(5,'bombermanActiveBombs','0'),(5,'bombermanArena','-1'),(5,'bombermanBombSize','1'),(5,'bombermanInMatch','-1'),(5,'bombermanInQueue','-1'),(5,'bombermanKick','0'),(5,'bombermanMatchStart','-1'),(5,'bombermanMaxBombs','1'),(5,'bombermanOutfitAddons','0'),(5,'bombermanOutfitBody','0'),(5,'bombermanOutfitEx','0'),(5,'bombermanOutfitFeet','0'),(5,'bombermanOutfitHead','0'),(5,'bombermanOutfitLegs','0'),(5,'bombermanOutfitMount','0'),(5,'bombermanOutfitType','0'),(5,'bombermanPartner','-1'),(5,'bombermanSavedSpeed','0'),(5,'bombermanSpeed','1'),(5,'bombermanSpeedDelta','0'),(5,'canturecover','1786260128'),(5,'currentCid','268446601'),(5,'currentFold','air burst'),(5,'DailyHunt_Claimed_2','0'),(5,'DailyHunt_Claimed_5','0'),(5,'DailyHunt_Day','dy780'),(5,'DailyHunt_Kill_1','0'),(5,'DailyHunt_Kill_2','0'),(5,'DailyHunt_Kill_3','0'),(5,'DailyHunt_Kill_4','0'),(5,'DailyHunt_Kill_5','0'),(5,'DailyHunt_Monster_1','slick water elemental'),(5,'DailyHunt_Monster_2','pirate marauder'),(5,'DailyHunt_Monster_3','midnight panther'),(5,'DailyHunt_Monster_4','rotworm queen'),(5,'DailyHunt_Monster_5','blazing fire elemental'),(5,'dailyTaskColdown','1786142222'),(5,'entroumontado','-1'),(5,'exaustedairball','1786260130'),(5,'exaustedairburst','1786260127'),(5,'exaustedairrecover','1786260128'),(5,'exaustedairrun','1786230472'),(5,'expBeforeDie','-1'),(5,'firstPendentes','1'),(5,'getAwnserAntiBot','-1'),(5,'getCompletedDailydy570','0'),(5,'getCompletedDailydy580','0'),(5,'getCompletedDailydy590','0'),(5,'getCompletedDailydy600','0'),(5,'getCompletedDailydy610','0'),(5,'getCompletedDailydy720','0'),(5,'getCompletedDailydy750','0'),(5,'getCompletedDailydy760','0'),(5,'getPlayerLang','isEnglish'),(5,'getPointsInDodge','0'),(5,'getTurnMsgPoints','1'),(5,'hasPassiveDeathActive','1786251915'),(5,'isAvatar','0'),(5,'isInDailyTask','0'),(5,'jamudouroupa','1'),(5,'knockoutAttackers',''),(5,'knockoutOldLevel','14'),(5,'lastGlobalSaveLogin','6'),(5,'lastHit','1073746774'),(5,'marketCheck','1786260162'),(5,'morreuD','-1'),(5,'npodedeslogar','1786260000'),(5,'onMoveFlyPosX','509'),(5,'onMoveFlyPosY','360'),(5,'onMoveFlyPosZ','7'),(5,'pendentes','2'),(5,'playerCanMoveDirection','0'),(5,'playerHasGetInitialItens','1'),(5,'playerOnAir','-1'),(5,'playerWithBless','-1'),(5,'startedWithMana','1'),(5,'stopDashs','1785874840'),(5,'taskInCourse1','1'),(5,'taskInCourse1npcName','Don Corleone'),(5,'taskInCourse2','1'),(5,'taskInCourse27','1'),(5,'taskInCourse27npcName','Don Corleone'),(5,'taskInCourse2npcName','Don Corleone'),(5,'taskInCourse48','1'),(5,'taskInCourse48npcName','Don Corleone'),(5,'taskInCourse49','1'),(5,'taskInCourse49npcName','Don Corleone'),(5,'taskInCourse90','1'),(5,'taskInCourse90npcName','Don Corleone'),(5,'taskInCourse91','1'),(5,'taskInCourse91npcName','Don Corleone'),(5,'taskInCourseGetMonsters1','7'),(5,'TimeDailyDois','0'),(5,'TimeDailyQuatro','0'),(5,'TimeDailyTres','0'),(5,'TimeDailyUm','0'),(5,'timeLogin','1786259995'),(6,'10001501','65539'),(6,'10001502','131075'),(6,'10001503','196611'),(6,'10001504','262147'),(6,'10001505','327683'),(6,'10001506','1376259'),(6,'10001507','1638403'),(6,'10001508','1900547'),(6,'10001509','1966083'),(6,'10001510','2031619'),(6,'10001511','2686979'),(6,'188100','27'),(6,'42001','1'),(6,'9701','0'),(6,'9702','0'),(6,'9703','0'),(6,'9704','0'),(6,'9705','0'),(6,'9706','0'),(6,'9707','0'),(6,'9708','0'),(6,'9709','0'),(6,'9710','0'),(6,'9711','0'),(6,'9712','0'),(6,'9713','0'),(6,'9714','0'),(6,'9715','0'),(6,'9716','0'),(6,'9717','0'),(6,'9718','0'),(6,'9719','0'),(6,'9720','0'),(6,'9721','0'),(6,'9722','0'),(6,'9723','0'),(6,'9724','0'),(6,'9725','0'),(6,'9726','0'),(6,'9727','0'),(6,'9728','0'),(6,'9729','0'),(6,'9730','0'),(6,'9731','0'),(6,'9740','1786219803'),(6,'9741','8'),(6,'autolootdesativo','1'),(6,'bendvalue','19'),(6,'bombermanActiveBombs','0'),(6,'bombermanArena','-1'),(6,'bombermanBombSize','1'),(6,'bombermanInMatch','-1'),(6,'bombermanInQueue','-1'),(6,'bombermanKick','0'),(6,'bombermanMaxBombs','1'),(6,'bombermanSpeed','1'),(6,'bombermanSpeedDelta','0'),(6,'canturecover','1786220184'),(6,'currentCid','268446607'),(6,'currentFold','fire recover'),(6,'DailyHunt_Claimed_2','0'),(6,'DailyHunt_Claimed_5','0'),(6,'DailyHunt_Day','dy750'),(6,'DailyHunt_Kill_1','0'),(6,'DailyHunt_Kill_2','0'),(6,'DailyHunt_Kill_3','0'),(6,'DailyHunt_Kill_4','0'),(6,'DailyHunt_Kill_5','0'),(6,'DailyHunt_Monster_1','orc rider'),(6,'DailyHunt_Monster_2','ethern'),(6,'DailyHunt_Monster_3','rat'),(6,'DailyHunt_Monster_4','grimeleech'),(6,'DailyHunt_Monster_5','marsh stalker'),(6,'dailyTaskColdown','1786070249'),(6,'entroumontado','-1'),(6,'exaustedfirebolt','1786220082'),(6,'exaustedfireimpulse','1786220062'),(6,'exaustedfirekick','1786220181'),(6,'exaustedfirerecover','1786220184'),(6,'exaustedfireskyfall','1786220170'),(6,'exaustedfirewhip','1786074050'),(6,'expBeforeDie','274060'),(6,'fireoverPower','1786220379'),(6,'firstPendentes','1'),(6,'getAwnserAntiBot','-1'),(6,'getCompletedDailydy690','0'),(6,'getCompletedDailydy700','0'),(6,'getCompletedDailydy720','0'),(6,'getCompletedDailydy750','0'),(6,'getPlayerLang','isEnglish'),(6,'getPointsInDodge','0'),(6,'getTurnMsgPoints','1'),(6,'hasPassiveDeathActive','1786231059'),(6,'isAvatar','0'),(6,'isInDailyTask','0'),(6,'jamudouroupa','1'),(6,'knockoutAttackers',''),(6,'knockoutOldLevel','27'),(6,'lastGlobalSaveLogin','6'),(6,'lastHit','1073753127'),(6,'marketCheck','1786220269'),(6,'morreuD','1'),(6,'npodedeslogar','1786219808'),(6,'onMoveFlyPosX','459'),(6,'onMoveFlyPosY','303'),(6,'onMoveFlyPosZ','9'),(6,'pendentes','1'),(6,'playerCanMoveDirection','0'),(6,'playerHasGetInitialItens','1'),(6,'playerOnAir','-1'),(6,'playerWithBless','-1'),(6,'questChests25455','1'),(6,'startedWithMana','1'),(6,'taskInCourse1','2'),(6,'taskInCourse12','1'),(6,'taskInCourse12npcName','Don Corleone'),(6,'taskInCourse1npcName','Don Corleone'),(6,'taskInCourse2','1'),(6,'taskInCourse27','1'),(6,'taskInCourse27npcName','Don Corleone'),(6,'taskInCourse28','1'),(6,'taskInCourse28npcName','Don Corleone'),(6,'taskInCourse2npcName','Don Corleone'),(6,'taskInCourse3','1'),(6,'taskInCourse3npcName','Don Corleone'),(6,'taskInCourse4','1'),(6,'taskInCourse40','1'),(6,'taskInCourse40npcName','Don Corleone'),(6,'taskInCourse48','1'),(6,'taskInCourse48npcName','Don Corleone'),(6,'taskInCourse49','1'),(6,'taskInCourse49npcName','Don Corleone'),(6,'taskInCourse4npcName','Don Corleone'),(6,'taskInCourse7','1'),(6,'taskInCourse7npcName','Don Corleone'),(6,'taskInCourse90','1'),(6,'taskInCourse90npcName','Don Corleone'),(6,'taskInCourse91','1'),(6,'taskInCourse91npcName','Don Corleone'),(6,'taskInCourseGetMonsters1','25'),(6,'taskInCourseGetMonsters2','12'),(6,'taskInCourseGetMonsters4','4'),(6,'TimeDailyDois','0'),(6,'TimeDailyQuatro','0'),(6,'TimeDailyTres','0'),(6,'TimeDailyUm','0'),(6,'timeLogin','1786219803');
/*!40000 ALTER TABLE `player_storage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `players`
--

DROP TABLE IF EXISTS `players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `group_id` int(11) NOT NULL DEFAULT 1,
  `account_id` int(11) NOT NULL DEFAULT 0,
  `level` int(11) NOT NULL DEFAULT 1,
  `vocation` int(11) NOT NULL DEFAULT 0,
  `health` int(11) NOT NULL DEFAULT 150,
  `healthmax` int(11) NOT NULL DEFAULT 150,
  `experience` bigint(20) unsigned NOT NULL DEFAULT 0,
  `lookbody` int(11) NOT NULL DEFAULT 0,
  `lookfeet` int(11) NOT NULL DEFAULT 0,
  `lookhead` int(11) NOT NULL DEFAULT 0,
  `looklegs` int(11) NOT NULL DEFAULT 0,
  `looktype` int(11) NOT NULL DEFAULT 136,
  `lookaddons` int(11) NOT NULL DEFAULT 0,
  `lookmount` int(11) NOT NULL DEFAULT 0,
  `maglevel` int(11) NOT NULL DEFAULT 0,
  `mana` int(11) NOT NULL DEFAULT 0,
  `manamax` int(11) NOT NULL DEFAULT 0,
  `manaspent` bigint(20) unsigned NOT NULL DEFAULT 0,
  `soul` int(10) unsigned NOT NULL DEFAULT 0,
  `town_id` int(11) NOT NULL DEFAULT 0,
  `posx` int(11) NOT NULL DEFAULT 0,
  `posy` int(11) NOT NULL DEFAULT 0,
  `posz` int(11) NOT NULL DEFAULT 0,
  `conditions` blob NOT NULL,
  `cap` int(11) NOT NULL DEFAULT 0,
  `sex` int(11) NOT NULL DEFAULT 0,
  `lastlogin` bigint(20) unsigned NOT NULL DEFAULT 0,
  `lastip` int(10) unsigned NOT NULL DEFAULT 0,
  `save` tinyint(1) NOT NULL DEFAULT 1,
  `skull` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `skulltime` int(11) NOT NULL DEFAULT 0,
  `rank_id` int(11) NOT NULL DEFAULT 0,
  `guildnick` varchar(255) NOT NULL DEFAULT '',
  `lastlogout` bigint(20) unsigned NOT NULL DEFAULT 0,
  `blessings` tinyint(2) NOT NULL DEFAULT 0,
  `pvp_blessing` tinyint(1) NOT NULL DEFAULT 0,
  `balance` bigint(20) unsigned NOT NULL DEFAULT 0,
  `stamina` bigint(20) unsigned NOT NULL DEFAULT 151200000 COMMENT 'stored in miliseconds',
  `direction` int(11) NOT NULL DEFAULT 2,
  `loss_experience` int(11) NOT NULL DEFAULT 100,
  `loss_mana` int(11) NOT NULL DEFAULT 100,
  `loss_skills` int(11) NOT NULL DEFAULT 100,
  `loss_containers` int(11) NOT NULL DEFAULT 100,
  `loss_items` int(11) NOT NULL DEFAULT 100,
  `premend` int(11) NOT NULL DEFAULT 0 COMMENT 'NOT IN USE BY THE SERVER',
  `online` tinyint(1) NOT NULL DEFAULT 0,
  `marriage` int(10) unsigned NOT NULL DEFAULT 0,
  `promotion` int(11) NOT NULL DEFAULT 0,
  `deleted` int(11) NOT NULL DEFAULT 0,
  `description` varchar(255) NOT NULL DEFAULT '',
  `auction_balance` bigint(20) NOT NULL DEFAULT 0,
  `broadcasting` tinyint(4) DEFAULT 0,
  `cast` tinyint(4) NOT NULL DEFAULT 0,
  `castDescription` varchar(255) NOT NULL,
  `castViewers` int(11) NOT NULL DEFAULT 0,
  `comment` text NOT NULL,
  `created` int(11) NOT NULL DEFAULT 0,
  `fragTime` int(11) NOT NULL DEFAULT 0,
  `hide_char` int(11) NOT NULL DEFAULT 0,
  `ip` varchar(17) NOT NULL DEFAULT '0',
  `nick_verify` int(11) NOT NULL DEFAULT 0,
  `offlinetraining_skill` int(11) NOT NULL DEFAULT -1,
  `offlinetraining_time` smallint(5) unsigned NOT NULL DEFAULT 43200,
  `old_name` varchar(255) NOT NULL DEFAULT '',
  `questpromotion` int(11) NOT NULL DEFAULT 0,
  `rep` int(11) NOT NULL DEFAULT 0,
  `resets` int(11) DEFAULT 0,
  `show_bars` tinyint(4) NOT NULL DEFAULT 1,
  `show_eq` tinyint(4) NOT NULL DEFAULT 1,
  `show_outfit` tinyint(4) NOT NULL DEFAULT 1,
  `show_quests` tinyint(4) NOT NULL DEFAULT 1,
  `show_skills` tinyint(4) NOT NULL DEFAULT 1,
  `stars` int(11) NOT NULL DEFAULT 0,
  `timeOnline` int(11) NOT NULL DEFAULT 0,
  `viewers` int(1) DEFAULT 0,
  `worldtransfer` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`,`deleted`),
  KEY `account_id` (`account_id`),
  KEY `group_id` (`group_id`),
  KEY `online` (`online`),
  KEY `deleted` (`deleted`),
  CONSTRAINT `players_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `players`
--

LOCK TABLES `players` WRITE;
/*!40000 ALTER TABLE `players` DISABLE KEYS */;
INSERT INTO `players` VALUES (1,'Account Manager',0,1,1,1,0,150,150,0,0,0,0,0,110,0,0,0,0,0,0,0,0,853,921,7,'',400,0,1786240201,16777343,0,0,0,0,'',0,0,0,0,201660000,0,100,100,100,100,100,0,0,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,0,1,1,1,1,1,0,2147483647,0,0),(2,'Sirius',0,6,2,150,3,4910,4910,54105865,114,0,115,68,1150,0,0,6,0,845,143,100,2,505,353,7,'\0 \0\0ÿÿÿÿ¸.\0\Z\0\0\0\0\0\0\0\0è\0\0\0\0\0Ð\0\0\0\0\0þ',750,1,1786259976,16777343,1,4,0,0,'',1786259995,0,0,0,151200000,2,60,100,100,100,0,0,0,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,0,1,1,1,1,1,0,3297177,0,0),(3,'Terrinha',0,1,2,60,4,2010,2010,3331078,114,0,115,68,1152,0,0,32,73,395,28989,100,2,513,360,7,'\0 \0\0ÿÿÿÿÈº\0\Z\0\0\0\0\0\0\0\0è\0\0\0\0\0Ð\0\0\0\0\0þ',1000,1,1786254912,16777343,1,4,0,0,'',1786254915,0,0,0,151200000,2,60,100,100,100,0,0,0,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,1,1,1,1,1,1,0,1784877942,0,0),(4,'Pansa Beifong',0,1,2,13,1,500,500,28151,114,0,115,68,1153,0,0,0,160,160,0,100,1,509,360,7,'',875,0,1786256688,16777343,1,4,0,0,'',1786256784,0,0,0,151200000,2,60,100,100,100,0,0,0,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,0,1,1,1,1,1,0,5985,0,0),(5,'Explainer',0,1,2,15,3,560,560,39342,114,0,115,68,1224,0,0,40,170,170,45877,100,1,509,360,7,'\0\0\0ÿÿÿÿ Œ\0\0\Z\0\0\0\0\0\0\0\0þ\0@\0\0ÿÿÿÿ Œ\0\0\Z\0\0\0\0\0\0\0\0\0\0\0ÀÔ\0þ\0 \0\0ÿÿÿÿÐ$\0\Z\0\0\0\0\0\0\0\0è\0\0\0\0\0Ð\0\0\0\0\0þ',925,1,1786259995,16777343,1,4,0,0,'',1786260154,0,0,0,151174000,2,60,100,100,100,0,0,1,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,0,1,1,1,1,1,0,15904,0,0),(6,'Barbiezinha milgrau',0,1,2,26,1,890,890,260154,114,0,115,68,1153,0,0,19,225,225,0,100,1,505,342,7,'',1200,0,1786219803,16777343,1,4,0,0,'',1786220263,0,0,0,151052000,2,60,100,100,0,0,0,0,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,1,1,1,1,1,1,0,5025,0,0);
/*!40000 ALTER TABLE `players` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `oncreate_players`
AFTER INSERT
ON `players`
FOR EACH ROW
BEGIN
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 0, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 1, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 2, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 3, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 4, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 5, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 6, 10);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `ondelete_players`
BEFORE DELETE
ON `players`
FOR EACH ROW
BEGIN
	DELETE FROM `bans` WHERE `type` IN (2, 5) AND `value` = OLD.`id`;
	UPDATE `houses` SET `owner` = 0 WHERE `owner` = OLD.`id`;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-08-09  4:30:00
