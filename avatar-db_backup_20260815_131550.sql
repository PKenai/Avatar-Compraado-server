-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: avatar
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
-- Table structure for table `account_ban_history`
--

DROP TABLE IF EXISTS `account_ban_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `account_ban_history` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `banned_at` bigint(20) NOT NULL,
  `expired_at` bigint(20) NOT NULL,
  `banned_by` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `account_id` (`account_id`),
  KEY `banned_by` (`banned_by`),
  CONSTRAINT `account_ban_history_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `account_ban_history_ibfk_2` FOREIGN KEY (`banned_by`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account_ban_history`
--

LOCK TABLES `account_ban_history` WRITE;
/*!40000 ALTER TABLE `account_ban_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `account_ban_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `account_bans`
--

DROP TABLE IF EXISTS `account_bans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `account_bans` (
  `account_id` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `banned_at` bigint(20) NOT NULL,
  `expires_at` bigint(20) NOT NULL,
  `banned_by` int(11) NOT NULL,
  PRIMARY KEY (`account_id`),
  KEY `banned_by` (`banned_by`),
  CONSTRAINT `account_bans_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `account_bans_ibfk_2` FOREIGN KEY (`banned_by`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account_bans`
--

LOCK TABLES `account_bans` WRITE;
/*!40000 ALTER TABLE `account_bans` DISABLE KEYS */;
/*!40000 ALTER TABLE `account_bans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `account_storage`
--

DROP TABLE IF EXISTS `account_storage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `account_storage` (
  `account_id` int(11) NOT NULL,
  `key` int(10) unsigned NOT NULL,
  `value` int(11) NOT NULL,
  PRIMARY KEY (`account_id`,`key`),
  CONSTRAINT `account_storage_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account_storage`
--

LOCK TABLES `account_storage` WRITE;
/*!40000 ALTER TABLE `account_storage` DISABLE KEYS */;
/*!40000 ALTER TABLE `account_storage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `account_viplist`
--

DROP TABLE IF EXISTS `account_viplist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `account_viplist` (
  `account_id` int(11) NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `player_id` int(11) NOT NULL,
  `description` varchar(128) NOT NULL,
  `icon` int(11) unsigned NOT NULL,
  `notify` tinyint(1) NOT NULL,
  UNIQUE KEY `account_id_2` (`account_id`,`player_id`),
  KEY `account_id` (`account_id`),
  KEY `player_id` (`player_id`),
  KEY `world_id` (`world_id`),
  CONSTRAINT `account_viplist_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `account_viplist_ibfk_2` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account_viplist`
--

LOCK TABLES `account_viplist` WRITE;
/*!40000 ALTER TABLE `account_viplist` DISABLE KEYS */;
/*!40000 ALTER TABLE `account_viplist` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `accounts`
--

DROP TABLE IF EXISTS `accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL DEFAULT '',
  `password` varchar(255) NOT NULL,
  `secret` char(16) DEFAULT NULL,
  `type` int(11) NOT NULL DEFAULT 1,
  `premium_ends_at` int(10) unsigned NOT NULL DEFAULT 0,
  `salt` varchar(40) NOT NULL DEFAULT '',
  `premdays` int(11) NOT NULL DEFAULT 0,
  `lastday` int(10) unsigned NOT NULL DEFAULT 0,
  `email` varchar(255) NOT NULL DEFAULT '',
  `key` varchar(32) NOT NULL DEFAULT '0',
  `blocked` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'internal usage',
  `warnings` int(11) NOT NULL DEFAULT 0,
  `group_id` int(11) NOT NULL DEFAULT 1,
  `premium_points` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accounts`
--

LOCK TABLES `accounts` WRITE;
/*!40000 ALTER TABLE `accounts` DISABLE KEYS */;
INSERT INTO `accounts` VALUES (1,'1','356a192b7913b04c54574d18c28d46e6395428ab',NULL,1,0,'',65535,0,'','0',0,0,1,0),(2,'12','40bd001563085fc35165329ea1ff5c5ecbdbbeef',NULL,1,0,'',358,1786746038,'','0',0,0,1,9790);
/*!40000 ALTER TABLE `accounts` ENABLE KEYS */;
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
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `ondelete_accounts`
BEFORE DELETE
ON `accounts`
FOR EACH ROW
BEGIN
	DELETE FROM `bans` WHERE `type` IN (3, 4) AND `value` = OLD.`id`;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `accounts_friends`
--

DROP TABLE IF EXISTS `accounts_friends`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accounts_friends` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_name` varchar(32) NOT NULL,
  `account_ref` varchar(32) DEFAULT NULL,
  `time` int(11) NOT NULL,
  `ativado_time` int(11) NOT NULL DEFAULT 0,
  `resgatado` smallint(1) NOT NULL DEFAULT 0,
  `premio_resgatado` varchar(20) DEFAULT NULL,
  `time_resgatado` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accounts_friends`
--

LOCK TABLES `accounts_friends` WRITE;
/*!40000 ALTER TABLE `accounts_friends` DISABLE KEYS */;
/*!40000 ALTER TABLE `accounts_friends` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `accounts_message`
--

DROP TABLE IF EXISTS `accounts_message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accounts_message` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account` varchar(25) NOT NULL,
  `time` int(11) NOT NULL,
  `autor` varchar(25) NOT NULL,
  `mensagem` text NOT NULL,
  `nivel` int(11) DEFAULT 0,
  `read` int(11) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accounts_message`
--

LOCK TABLES `accounts_message` WRITE;
/*!40000 ALTER TABLE `accounts_message` DISABLE KEYS */;
/*!40000 ALTER TABLE `accounts_message` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `accounts_pacotes`
--

DROP TABLE IF EXISTS `accounts_pacotes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accounts_pacotes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `id_pacote` int(11) NOT NULL,
  `account` varchar(20) NOT NULL,
  `required` int(11) NOT NULL,
  `recompensa` int(11) NOT NULL,
  `type` varchar(20) NOT NULL,
  `cupom` varchar(20) DEFAULT NULL,
  `time` varchar(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accounts_pacotes`
--

LOCK TABLES `accounts_pacotes` WRITE;
/*!40000 ALTER TABLE `accounts_pacotes` DISABLE KEYS */;
/*!40000 ALTER TABLE `accounts_pacotes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auction_system`
--

DROP TABLE IF EXISTS `auction_system`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auction_system` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `player` int(10) unsigned NOT NULL,
  `item_id` int(10) unsigned NOT NULL,
  `item_name` varchar(255) DEFAULT NULL,
  `count` int(10) unsigned NOT NULL DEFAULT 1,
  `desc` varchar(255) DEFAULT NULL,
  `cost` bigint(20) unsigned NOT NULL DEFAULT 0,
  `date` int(10) unsigned NOT NULL,
  `expired` tinyint(1) NOT NULL DEFAULT 0,
  `world_id` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auction_system`
--

LOCK TABLES `auction_system` WRITE;
/*!40000 ALTER TABLE `auction_system` DISABLE KEYS */;
INSERT INTO `auction_system` VALUES (6,2,2487,'crown armor',1,'You see a crown armor (Arm:13).\nIt weighs 99.00 oz.',1000,1786240805,0,0);
/*!40000 ALTER TABLE `auction_system` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `avatar_privates_keys`
--

DROP TABLE IF EXISTS `avatar_privates_keys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `avatar_privates_keys` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(255) NOT NULL,
  `date` int(11) NOT NULL,
  `atived` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `avatar_privates_keys`
--

LOCK TABLES `avatar_privates_keys` WRITE;
/*!40000 ALTER TABLE `avatar_privates_keys` DISABLE KEYS */;
/*!40000 ALTER TABLE `avatar_privates_keys` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bans`
--

DROP TABLE IF EXISTS `bans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bans` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` tinyint(1) NOT NULL COMMENT '1 - ip, 2 - player, 3 - account, 4 - notation',
  `value` int(10) unsigned NOT NULL COMMENT 'ip - ip address, player - player_id, account - account_id, notation - account_id',
  `param` int(10) unsigned NOT NULL COMMENT 'ip - mask, player - type (1 - report, 2 - lock, 3 - ban), account - player, notation - player',
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `expires` int(11) NOT NULL DEFAULT -1,
  `added` int(10) unsigned NOT NULL,
  `admin_id` int(10) unsigned NOT NULL DEFAULT 0,
  `comment` text NOT NULL,
  PRIMARY KEY (`id`),
  KEY `type` (`type`,`value`),
  KEY `active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bans`
--

LOCK TABLES `bans` WRITE;
/*!40000 ALTER TABLE `bans` DISABLE KEYS */;
/*!40000 ALTER TABLE `bans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bbclientes`
--

DROP TABLE IF EXISTS `bbclientes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bbclientes` (
  `account` varchar(15) NOT NULL,
  `data` varchar(10) NOT NULL,
  `hora` varchar(10) NOT NULL,
  `valor` varchar(10) NOT NULL,
  `dados` varchar(120) NOT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bbclientes`
--

LOCK TABLES `bbclientes` WRITE;
/*!40000 ALTER TABLE `bbclientes` DISABLE KEYS */;
/*!40000 ALTER TABLE `bbclientes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ci_sessions`
--

DROP TABLE IF EXISTS `ci_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ci_sessions` (
  `session_id` varchar(40) NOT NULL DEFAULT '0',
  `ip_address` varchar(45) NOT NULL DEFAULT '0',
  `user_agent` varchar(120) NOT NULL,
  `last_activity` int(10) unsigned NOT NULL DEFAULT 0,
  `user_data` text NOT NULL,
  PRIMARY KEY (`session_id`),
  KEY `last_activity_idx` (`last_activity`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ci_sessions`
--

LOCK TABLES `ci_sessions` WRITE;
/*!40000 ALTER TABLE `ci_sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `ci_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deaths_record`
--

DROP TABLE IF EXISTS `deaths_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `deaths_record` (
  `name` varchar(255) NOT NULL,
  `id` int(11) NOT NULL DEFAULT 1,
  `expLost` int(11) NOT NULL DEFAULT 1,
  `date` int(11) NOT NULL DEFAULT 0,
  `monsterName` varchar(255) NOT NULL,
  `used` int(11) NOT NULL DEFAULT 0,
  `bless` int(11) NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deaths_record`
--

LOCK TABLES `deaths_record` WRITE;
/*!40000 ALTER TABLE `deaths_record` DISABLE KEYS */;
INSERT INTO `deaths_record` VALUES ('Terrinha',3,2913,1784883807,'unknow',0,0),('Terrinha',3,2913,1785043997,'unknow',0,0),('Terrinha',3,2739,1785044040,'unknow',0,0),('Terrinha',3,2673,1785336336,'unknow',0,0),('Terrinha',3,3238,1785336405,'unknow',0,0),('Terrinha',3,4146,1785336549,'unknow',0,0),('Terrinha',3,6270,1785551785,'unknow',0,0),('Terrinha',3,5943,1785793068,'unknow',0,0),('Terrinha',3,5586,1785793118,'unknow',0,0),('Terrinha',3,5586,1786059330,'unknow',0,0),('Barbiezinha milgrau',6,252,1786070463,'unknow',0,0),('Barbiezinha milgrau',6,4411,1786071177,'unknow',0,0),('Barbiezinha milgrau',6,4531,1786071413,'unknow',0,0),('Explainer',5,5641,1786142291,'unknow',0,0),('Explainer',5,5641,1786142356,'unknow',0,0),('Explainer',5,5302,1786142424,'unknow',0,0),('Explainer',5,4984,1786142813,'unknow',0,0),('Explainer',5,4984,1786143186,'unknow',0,0),('Explainer',5,4685,1786143234,'unknow',0,0),('Explainer',5,4685,1786143560,'unknow',0,0),('Explainer',5,4404,1786143607,'unknow',0,0),('Explainer',5,4404,1786144128,'unknow',0,0),('Explainer',5,4140,1786144150,'unknow',0,0),('Explainer',5,4140,1786144205,'unknow',0,0),('Explainer',5,3892,1786144236,'unknow',0,0),('Explainer',5,3892,1786144379,'unknow',0,0),('Explainer',5,3658,1786144393,'unknow',0,0),('Explainer',5,3658,1786144554,'unknow',0,0),('Explainer',5,3439,1786144842,'unknow',0,0),('Explainer',5,3232,1786144869,'unknow',0,0),('Explainer',5,3232,1786145058,'unknow',0,0),('Explainer',5,3038,1786145093,'unknow',0,0),('Explainer',5,2856,1786145119,'unknow',0,0),('Explainer',5,2685,1786145131,'unknow',0,0),('Explainer',5,2524,1786145155,'unknow',0,0),('Explainer',5,2372,1786146528,'unknow',0,0),('Explainer',5,2230,1786156947,'unknow',0,0),('Explainer',5,2230,1786157489,'unknow',0,0),('Terrinha',3,5251,1786228866,'unknow',0,0),('Explainer',5,2096,1786252151,'unknow',0,0),('Pansa Beifong',4,1796,1786253256,'unknow',0,0),('Pansa Beifong',4,16684,1786483149,'unknow',0,0),('Pansa Beifong',4,16684,1786483685,'unknow',0,0),('Pansa Beifong',4,16684,1786483968,'unknow',0,0),('Pansa Beifong',4,16684,1786484308,'unknow',0,0),('Pansa Beifong',4,16684,1786487739,'unknow',0,0),('Pansa Beifong',4,16684,1786487971,'unknow',0,0),('Pansa Beifong',4,16684,1786496089,'unknow',0,0),('Barbiezinha milgrau',6,13906,1786500227,'unknow',0,0),('Barbiezinha milgrau',6,13906,1786500365,'unknow',0,0),('Pansa Beifong',4,108822,1786598996,'unknow',0,0),('Pansa Beifong',4,56818,1786605234,'unknow',0,1),('Pansa Beifong',4,108822,1786605276,'unknow',0,0),('Mahito',2,1732590324,1786740144,'unknow',0,1),('Mahito',2,152,1786740296,'unknow',0,1),('Mahito',2,216,1786740360,'unknow',0,1),('Mahito',2,283,1786740427,'unknow',0,1),('Mahito',2,330,1786740474,'unknow',0,1),('Mahito',2,313,1786740787,'unknow',0,1),('Mahito',2,163,1786740950,'unknow',0,1),('Mahito',2,390,1786741340,'unknow',0,1),('Mahito',2,291,1786741631,'unknow',0,1),('Mahito',2,709,1786742340,'unknow',0,1),('Mahito',2,2959,1786745299,'unknow',0,1),('Mahito',2,216,1786745515,'unknow',0,1),('Mahito',2,332,1786745847,'unknow',0,1),('Mahito',2,71,1786745918,'unknow',0,1),('Mahito',2,306,1786746224,'unknow',0,1),('Mahito',2,617,1786746841,'unknow',0,1),('Mahito',2,384,1786747225,'unknow',0,1),('Mahito',2,1414,1786748639,'unknow',0,1),('Mahito',2,72,1786748711,'unknow',0,1),('Mahito',2,480,1786749191,'unknow',0,1),('Mahito',2,209,1786749400,'unknow',0,1),('Mahito',2,234,1786749634,'unknow',0,1),('Mahito',2,444,1786750078,'unknow',0,1),('Mahito',2,4516,1786754150,'unknow',0,1),('Mahito',2,150,1786754300,'unknow',0,1),('Mahito',2,89,1786754389,'unknow',0,1);
/*!40000 ALTER TABLE `deaths_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deaths_record_touse`
--

DROP TABLE IF EXISTS `deaths_record_touse`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `deaths_record_touse` (
  `id` int(11) NOT NULL DEFAULT 1,
  `expLost` int(11) NOT NULL DEFAULT 1,
  `bless` int(11) NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deaths_record_touse`
--

LOCK TABLES `deaths_record_touse` WRITE;
/*!40000 ALTER TABLE `deaths_record_touse` DISABLE KEYS */;
/*!40000 ALTER TABLE `deaths_record_touse` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `environment_killers`
--

DROP TABLE IF EXISTS `environment_killers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `environment_killers` (
  `kill_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  KEY `kill_id` (`kill_id`),
  CONSTRAINT `environment_killers_ibfk_1` FOREIGN KEY (`kill_id`) REFERENCES `killers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `environment_killers`
--

LOCK TABLES `environment_killers` WRITE;
/*!40000 ALTER TABLE `environment_killers` DISABLE KEYS */;
INSERT INTO `environment_killers` VALUES (1,'a rotworm'),(2,'a black knight'),(3,'a rotworm'),(4,'a clawed rotworm'),(5,'a clawed rotworm'),(6,'a rotworm'),(7,'a gargoyle'),(8,'a dragon'),(9,'a rotworm'),(10,'a dragon'),(11,'a Zuko\'s disciple'),(12,'a rotworm queen'),(13,'a cyclops smith'),(14,'a cyclops'),(15,'a cyclops smith'),(16,'a cyclops smith'),(17,'a fire elemental'),(18,'a fire elemental'),(19,'a demon'),(20,'a demon'),(21,'a demon'),(22,'a fire elemental'),(23,'a demon'),(24,'a demon'),(25,'a demon'),(26,'a demon'),(27,'a demon'),(28,'a fire elemental'),(29,'a gozzler'),(30,'a dragon'),(31,'a cyclops'),(32,'a nomad'),(33,'a Zuko\'s disciple'),(34,'a cyclops'),(35,'a cyclops drone'),(36,'a dragon'),(37,'a demon'),(38,'a silencer'),(39,'a vexclaw'),(40,'a minotaur hunter'),(41,'a minotaur amazon'),(42,'a terra beetle'),(43,'an abelha de barro'),(44,'a joaninha da terra'),(45,'an abelha de barro'),(46,'a joaninha da terra'),(47,'a leao de ba sin se'),(48,'a leao de ba sin se'),(49,'a pica-pau da terra'),(50,'a pica-pau da terra');
/*!40000 ALTER TABLE `environment_killers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gamesrank`
--

DROP TABLE IF EXISTS `gamesrank`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gamesrank` (
  `name` varchar(255) NOT NULL,
  `points` int(11) NOT NULL DEFAULT 1,
  `game` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gamesrank`
--

LOCK TABLES `gamesrank` WRITE;
/*!40000 ALTER TABLE `gamesrank` DISABLE KEYS */;
/*!40000 ALTER TABLE `gamesrank` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `global_storage`
--

DROP TABLE IF EXISTS `global_storage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `global_storage` (
  `key` varchar(32) NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `value` text NOT NULL,
  UNIQUE KEY `key` (`key`,`world_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `global_storage`
--

LOCK TABLES `global_storage` WRITE;
/*!40000 ALTER TABLE `global_storage` DISABLE KEYS */;
INSERT INTO `global_storage` VALUES ('391895',0,'0'),('56304',0,'0'),('57301',0,'5'),('57302',0,'0'),('73991',0,'3'),('bmBlock1_1',0,'14790297'),('bmBlock1_10',0,'14790387'),('bmBlock1_100',0,'14840357'),('bmBlock1_101',0,'14840377'),('bmBlock1_102',0,'14840397'),('bmBlock1_103',0,'14840417'),('bmBlock1_104',0,'14840437'),('bmBlock1_105',0,'14840457'),('bmBlock1_106',0,'14840477'),('bmBlock1_107',0,'14840497'),('bmBlock1_108',0,'14840517'),('bmBlock1_109',0,'14850277'),('bmBlock1_11',0,'14790397'),('bmBlock1_110',0,'14850287'),('bmBlock1_111',0,'14850297'),('bmBlock1_112',0,'14850307'),('bmBlock1_113',0,'14850317'),('bmBlock1_114',0,'14850327'),('bmBlock1_115',0,'14850337'),('bmBlock1_116',0,'14850347'),('bmBlock1_117',0,'14850357'),('bmBlock1_118',0,'14850367'),('bmBlock1_119',0,'14850377'),('bmBlock1_12',0,'14790407'),('bmBlock1_120',0,'14850387'),('bmBlock1_121',0,'14850397'),('bmBlock1_122',0,'14850407'),('bmBlock1_123',0,'14850417'),('bmBlock1_124',0,'14850427'),('bmBlock1_125',0,'14850437'),('bmBlock1_126',0,'14850447'),('bmBlock1_127',0,'14850457'),('bmBlock1_128',0,'14850467'),('bmBlock1_129',0,'14850477'),('bmBlock1_13',0,'14790417'),('bmBlock1_130',0,'14850487'),('bmBlock1_131',0,'14850497'),('bmBlock1_132',0,'14850507'),('bmBlock1_133',0,'14850517'),('bmBlock1_134',0,'14860277'),('bmBlock1_135',0,'14860297'),('bmBlock1_136',0,'14860317'),('bmBlock1_137',0,'14860337'),('bmBlock1_138',0,'14860357'),('bmBlock1_139',0,'14860377'),('bmBlock1_14',0,'14790427'),('bmBlock1_140',0,'14860397'),('bmBlock1_141',0,'14860417'),('bmBlock1_142',0,'14860437'),('bmBlock1_143',0,'14860457'),('bmBlock1_144',0,'14860477'),('bmBlock1_145',0,'14860497'),('bmBlock1_146',0,'14860517'),('bmBlock1_147',0,'14870277'),('bmBlock1_148',0,'14870287'),('bmBlock1_149',0,'14870297'),('bmBlock1_15',0,'14790437'),('bmBlock1_150',0,'14870307'),('bmBlock1_151',0,'14870317'),('bmBlock1_152',0,'14870327'),('bmBlock1_153',0,'14870337'),('bmBlock1_154',0,'14870347'),('bmBlock1_155',0,'14870357'),('bmBlock1_156',0,'14870367'),('bmBlock1_157',0,'14870377'),('bmBlock1_158',0,'14870387'),('bmBlock1_159',0,'14870397'),('bmBlock1_16',0,'14790447'),('bmBlock1_160',0,'14870407'),('bmBlock1_161',0,'14870417'),('bmBlock1_162',0,'14870427'),('bmBlock1_163',0,'14870437'),('bmBlock1_164',0,'14870447'),('bmBlock1_165',0,'14870457'),('bmBlock1_166',0,'14870467'),('bmBlock1_167',0,'14870477'),('bmBlock1_168',0,'14870487'),('bmBlock1_169',0,'14870497'),('bmBlock1_17',0,'14790457'),('bmBlock1_170',0,'14870507'),('bmBlock1_171',0,'14870517'),('bmBlock1_172',0,'14880277'),('bmBlock1_173',0,'14880297'),('bmBlock1_174',0,'14880317'),('bmBlock1_175',0,'14880337'),('bmBlock1_176',0,'14880357'),('bmBlock1_177',0,'14880377'),('bmBlock1_178',0,'14880397'),('bmBlock1_179',0,'14880417'),('bmBlock1_18',0,'14790467'),('bmBlock1_180',0,'14880437'),('bmBlock1_181',0,'14880457'),('bmBlock1_182',0,'14880477'),('bmBlock1_183',0,'14880497'),('bmBlock1_184',0,'14880517'),('bmBlock1_185',0,'14890277'),('bmBlock1_186',0,'14890287'),('bmBlock1_187',0,'14890297'),('bmBlock1_188',0,'14890307'),('bmBlock1_189',0,'14890317'),('bmBlock1_19',0,'14790477'),('bmBlock1_190',0,'14890327'),('bmBlock1_191',0,'14890337'),('bmBlock1_192',0,'14890347'),('bmBlock1_193',0,'14890357'),('bmBlock1_194',0,'14890367'),('bmBlock1_195',0,'14890377'),('bmBlock1_196',0,'14890387'),('bmBlock1_197',0,'14890397'),('bmBlock1_198',0,'14890407'),('bmBlock1_199',0,'14890417'),('bmBlock1_2',0,'14790307'),('bmBlock1_20',0,'14790487'),('bmBlock1_200',0,'14890427'),('bmBlock1_201',0,'14890437'),('bmBlock1_202',0,'14890447'),('bmBlock1_203',0,'14890457'),('bmBlock1_204',0,'14890467'),('bmBlock1_205',0,'14890477'),('bmBlock1_206',0,'14890487'),('bmBlock1_207',0,'14890497'),('bmBlock1_208',0,'14890507'),('bmBlock1_209',0,'14890517'),('bmBlock1_21',0,'14790497'),('bmBlock1_210',0,'14900277'),('bmBlock1_211',0,'14900297'),('bmBlock1_212',0,'14900317'),('bmBlock1_213',0,'14900337'),('bmBlock1_214',0,'14900357'),('bmBlock1_215',0,'14900377'),('bmBlock1_216',0,'14900397'),('bmBlock1_217',0,'14900417'),('bmBlock1_218',0,'14900437'),('bmBlock1_219',0,'14900457'),('bmBlock1_22',0,'14800297'),('bmBlock1_220',0,'14900477'),('bmBlock1_221',0,'14900497'),('bmBlock1_222',0,'14900517'),('bmBlock1_223',0,'14910277'),('bmBlock1_224',0,'14910287'),('bmBlock1_225',0,'14910297'),('bmBlock1_226',0,'14910307'),('bmBlock1_227',0,'14910317'),('bmBlock1_228',0,'14910327'),('bmBlock1_229',0,'14910337'),('bmBlock1_23',0,'14800317'),('bmBlock1_230',0,'14910347'),('bmBlock1_231',0,'14910357'),('bmBlock1_232',0,'14910367'),('bmBlock1_233',0,'14910377'),('bmBlock1_234',0,'14910387'),('bmBlock1_235',0,'14910397'),('bmBlock1_236',0,'14910407'),('bmBlock1_237',0,'14910417'),('bmBlock1_238',0,'14910427'),('bmBlock1_239',0,'14910437'),('bmBlock1_24',0,'14800337'),('bmBlock1_240',0,'14910447'),('bmBlock1_241',0,'14910457'),('bmBlock1_242',0,'14910467'),('bmBlock1_243',0,'14910477'),('bmBlock1_244',0,'14910487'),('bmBlock1_245',0,'14910497'),('bmBlock1_246',0,'14910507'),('bmBlock1_247',0,'14910517'),('bmBlock1_248',0,'14920277'),('bmBlock1_249',0,'14920297'),('bmBlock1_25',0,'14800357'),('bmBlock1_250',0,'14920317'),('bmBlock1_251',0,'14920337'),('bmBlock1_252',0,'14920357'),('bmBlock1_253',0,'14920377'),('bmBlock1_254',0,'14920397'),('bmBlock1_255',0,'14920417'),('bmBlock1_256',0,'14920437'),('bmBlock1_257',0,'14920457'),('bmBlock1_258',0,'14920477'),('bmBlock1_259',0,'14920497'),('bmBlock1_26',0,'14800377'),('bmBlock1_260',0,'14920517'),('bmBlock1_261',0,'14930277'),('bmBlock1_262',0,'14930287'),('bmBlock1_263',0,'14930297'),('bmBlock1_264',0,'14930307'),('bmBlock1_265',0,'14930317'),('bmBlock1_266',0,'14930327'),('bmBlock1_267',0,'14930337'),('bmBlock1_268',0,'14930347'),('bmBlock1_269',0,'14930357'),('bmBlock1_27',0,'14800397'),('bmBlock1_270',0,'14930367'),('bmBlock1_271',0,'14930377'),('bmBlock1_272',0,'14930387'),('bmBlock1_273',0,'14930397'),('bmBlock1_274',0,'14930407'),('bmBlock1_275',0,'14930417'),('bmBlock1_276',0,'14930427'),('bmBlock1_277',0,'14930437'),('bmBlock1_278',0,'14930447'),('bmBlock1_279',0,'14930457'),('bmBlock1_28',0,'14800417'),('bmBlock1_280',0,'14930467'),('bmBlock1_281',0,'14930477'),('bmBlock1_282',0,'14930487'),('bmBlock1_283',0,'14930497'),('bmBlock1_284',0,'14930507'),('bmBlock1_285',0,'14930517'),('bmBlock1_286',0,'14940277'),('bmBlock1_287',0,'14940297'),('bmBlock1_288',0,'14940317'),('bmBlock1_289',0,'14940337'),('bmBlock1_29',0,'14800437'),('bmBlock1_290',0,'14940357'),('bmBlock1_291',0,'14940377'),('bmBlock1_292',0,'14940397'),('bmBlock1_293',0,'14940417'),('bmBlock1_294',0,'14940437'),('bmBlock1_295',0,'14940457'),('bmBlock1_296',0,'14940477'),('bmBlock1_297',0,'14940497'),('bmBlock1_298',0,'14940517'),('bmBlock1_299',0,'14950277'),('bmBlock1_3',0,'14790317'),('bmBlock1_30',0,'14800457'),('bmBlock1_300',0,'14950287'),('bmBlock1_301',0,'14950297'),('bmBlock1_302',0,'14950307'),('bmBlock1_303',0,'14950317'),('bmBlock1_304',0,'14950327'),('bmBlock1_305',0,'14950337'),('bmBlock1_306',0,'14950347'),('bmBlock1_307',0,'14950357'),('bmBlock1_308',0,'14950367'),('bmBlock1_309',0,'14950377'),('bmBlock1_31',0,'14800477'),('bmBlock1_310',0,'14950387'),('bmBlock1_311',0,'14950397'),('bmBlock1_312',0,'14950407'),('bmBlock1_313',0,'14950417'),('bmBlock1_314',0,'14950427'),('bmBlock1_315',0,'14950437'),('bmBlock1_316',0,'14950447'),('bmBlock1_317',0,'14950457'),('bmBlock1_318',0,'14950467'),('bmBlock1_319',0,'14950477'),('bmBlock1_32',0,'14800497'),('bmBlock1_320',0,'14950487'),('bmBlock1_321',0,'14950497'),('bmBlock1_322',0,'14950507'),('bmBlock1_323',0,'14950517'),('bmBlock1_324',0,'14960277'),('bmBlock1_325',0,'14960297'),('bmBlock1_326',0,'14960317'),('bmBlock1_327',0,'14960337'),('bmBlock1_328',0,'14960357'),('bmBlock1_329',0,'14960377'),('bmBlock1_33',0,'14810277'),('bmBlock1_330',0,'14960397'),('bmBlock1_331',0,'14960417'),('bmBlock1_332',0,'14960437'),('bmBlock1_333',0,'14960457'),('bmBlock1_334',0,'14960477'),('bmBlock1_335',0,'14960497'),('bmBlock1_336',0,'14960517'),('bmBlock1_337',0,'14970277'),('bmBlock1_338',0,'14970287'),('bmBlock1_339',0,'14970297'),('bmBlock1_34',0,'14810287'),('bmBlock1_340',0,'14970307'),('bmBlock1_341',0,'14970317'),('bmBlock1_342',0,'14970327'),('bmBlock1_343',0,'14970337'),('bmBlock1_344',0,'14970347'),('bmBlock1_345',0,'14970357'),('bmBlock1_346',0,'14970367'),('bmBlock1_347',0,'14970377'),('bmBlock1_348',0,'14970387'),('bmBlock1_349',0,'14970397'),('bmBlock1_35',0,'14810297'),('bmBlock1_350',0,'14970407'),('bmBlock1_351',0,'14970417'),('bmBlock1_352',0,'14970427'),('bmBlock1_353',0,'14970437'),('bmBlock1_354',0,'14970447'),('bmBlock1_355',0,'14970457'),('bmBlock1_356',0,'14970467'),('bmBlock1_357',0,'14970477'),('bmBlock1_358',0,'14970487'),('bmBlock1_359',0,'14970497'),('bmBlock1_36',0,'14810307'),('bmBlock1_360',0,'14970507'),('bmBlock1_361',0,'14970517'),('bmBlock1_362',0,'14980277'),('bmBlock1_363',0,'14980297'),('bmBlock1_364',0,'14980317'),('bmBlock1_365',0,'14980337'),('bmBlock1_366',0,'14980357'),('bmBlock1_367',0,'14980377'),('bmBlock1_368',0,'14980397'),('bmBlock1_369',0,'14980417'),('bmBlock1_37',0,'14810317'),('bmBlock1_370',0,'14980437'),('bmBlock1_371',0,'14980457'),('bmBlock1_372',0,'14980477'),('bmBlock1_373',0,'14980497'),('bmBlock1_374',0,'14980517'),('bmBlock1_375',0,'14990277'),('bmBlock1_376',0,'14990287'),('bmBlock1_377',0,'14990297'),('bmBlock1_378',0,'14990307'),('bmBlock1_379',0,'14990317'),('bmBlock1_38',0,'14810327'),('bmBlock1_380',0,'14990327'),('bmBlock1_381',0,'14990337'),('bmBlock1_382',0,'14990347'),('bmBlock1_383',0,'14990357'),('bmBlock1_384',0,'14990367'),('bmBlock1_385',0,'14990377'),('bmBlock1_386',0,'14990387'),('bmBlock1_387',0,'14990397'),('bmBlock1_388',0,'14990407'),('bmBlock1_389',0,'14990417'),('bmBlock1_39',0,'14810337'),('bmBlock1_390',0,'14990427'),('bmBlock1_391',0,'14990437'),('bmBlock1_392',0,'14990447'),('bmBlock1_393',0,'14990457'),('bmBlock1_394',0,'14990467'),('bmBlock1_395',0,'14990477'),('bmBlock1_396',0,'14990487'),('bmBlock1_397',0,'14990497'),('bmBlock1_398',0,'14990507'),('bmBlock1_399',0,'14990517'),('bmBlock1_4',0,'14790327'),('bmBlock1_40',0,'14810347'),('bmBlock1_400',0,'15000277'),('bmBlock1_401',0,'15000297'),('bmBlock1_402',0,'15000317'),('bmBlock1_403',0,'15000337'),('bmBlock1_404',0,'15000357'),('bmBlock1_405',0,'15000377'),('bmBlock1_406',0,'15000397'),('bmBlock1_407',0,'15000417'),('bmBlock1_408',0,'15000437'),('bmBlock1_409',0,'15000457'),('bmBlock1_41',0,'14810357'),('bmBlock1_410',0,'15000477'),('bmBlock1_411',0,'15000497'),('bmBlock1_412',0,'15000517'),('bmBlock1_413',0,'15010277'),('bmBlock1_414',0,'15010287'),('bmBlock1_415',0,'15010297'),('bmBlock1_416',0,'15010307'),('bmBlock1_417',0,'15010317'),('bmBlock1_418',0,'15010327'),('bmBlock1_419',0,'15010337'),('bmBlock1_42',0,'14810367'),('bmBlock1_420',0,'15010347'),('bmBlock1_421',0,'15010357'),('bmBlock1_422',0,'15010367'),('bmBlock1_423',0,'15010377'),('bmBlock1_424',0,'15010387'),('bmBlock1_425',0,'15010397'),('bmBlock1_426',0,'15010407'),('bmBlock1_427',0,'15010417'),('bmBlock1_428',0,'15010427'),('bmBlock1_429',0,'15010437'),('bmBlock1_43',0,'14810377'),('bmBlock1_430',0,'15010447'),('bmBlock1_431',0,'15010457'),('bmBlock1_432',0,'15010467'),('bmBlock1_433',0,'15010477'),('bmBlock1_434',0,'15010487'),('bmBlock1_435',0,'15010497'),('bmBlock1_436',0,'15010507'),('bmBlock1_437',0,'15010517'),('bmBlock1_438',0,'15020277'),('bmBlock1_439',0,'15020297'),('bmBlock1_44',0,'14810387'),('bmBlock1_440',0,'15020317'),('bmBlock1_441',0,'15020337'),('bmBlock1_442',0,'15020357'),('bmBlock1_443',0,'15020377'),('bmBlock1_444',0,'15020397'),('bmBlock1_445',0,'15020417'),('bmBlock1_446',0,'15020437'),('bmBlock1_447',0,'15020457'),('bmBlock1_448',0,'15020477'),('bmBlock1_449',0,'15020497'),('bmBlock1_45',0,'14810397'),('bmBlock1_450',0,'15020517'),('bmBlock1_451',0,'15030277'),('bmBlock1_452',0,'15030287'),('bmBlock1_453',0,'15030297'),('bmBlock1_454',0,'15030307'),('bmBlock1_455',0,'15030317'),('bmBlock1_456',0,'15030327'),('bmBlock1_457',0,'15030337'),('bmBlock1_458',0,'15030347'),('bmBlock1_459',0,'15030357'),('bmBlock1_46',0,'14810407'),('bmBlock1_460',0,'15030367'),('bmBlock1_461',0,'15030377'),('bmBlock1_462',0,'15030387'),('bmBlock1_463',0,'15030397'),('bmBlock1_464',0,'15030407'),('bmBlock1_465',0,'15030417'),('bmBlock1_466',0,'15030427'),('bmBlock1_467',0,'15030437'),('bmBlock1_468',0,'15030447'),('bmBlock1_469',0,'15030457'),('bmBlock1_47',0,'14810417'),('bmBlock1_470',0,'15030467'),('bmBlock1_471',0,'15030477'),('bmBlock1_472',0,'15030487'),('bmBlock1_473',0,'15030497'),('bmBlock1_474',0,'15030507'),('bmBlock1_475',0,'15030517'),('bmBlock1_476',0,'15040277'),('bmBlock1_477',0,'15040297'),('bmBlock1_478',0,'15040317'),('bmBlock1_479',0,'15040337'),('bmBlock1_48',0,'14810427'),('bmBlock1_480',0,'15040357'),('bmBlock1_481',0,'15040377'),('bmBlock1_482',0,'15040397'),('bmBlock1_483',0,'15040417'),('bmBlock1_484',0,'15040437'),('bmBlock1_485',0,'15040457'),('bmBlock1_486',0,'15040477'),('bmBlock1_487',0,'15040497'),('bmBlock1_488',0,'15040517'),('bmBlock1_489',0,'15050297'),('bmBlock1_49',0,'14810437'),('bmBlock1_490',0,'15050307'),('bmBlock1_491',0,'15050317'),('bmBlock1_492',0,'15050327'),('bmBlock1_493',0,'15050337'),('bmBlock1_494',0,'15050347'),('bmBlock1_495',0,'15050357'),('bmBlock1_496',0,'15050367'),('bmBlock1_497',0,'15050377'),('bmBlock1_498',0,'15050387'),('bmBlock1_499',0,'15050397'),('bmBlock1_5',0,'14790337'),('bmBlock1_50',0,'14810447'),('bmBlock1_500',0,'15050407'),('bmBlock1_501',0,'15050417'),('bmBlock1_502',0,'15050427'),('bmBlock1_503',0,'15050437'),('bmBlock1_504',0,'15050447'),('bmBlock1_505',0,'15050457'),('bmBlock1_506',0,'15050467'),('bmBlock1_507',0,'15050477'),('bmBlock1_508',0,'15050487'),('bmBlock1_509',0,'15050497'),('bmBlock1_51',0,'14810457'),('bmBlock1_510',0,'15060297'),('bmBlock1_511',0,'15060317'),('bmBlock1_512',0,'15060337'),('bmBlock1_513',0,'15060357'),('bmBlock1_514',0,'15060377'),('bmBlock1_515',0,'15060397'),('bmBlock1_516',0,'15060417'),('bmBlock1_517',0,'15060437'),('bmBlock1_518',0,'15060457'),('bmBlock1_519',0,'15060477'),('bmBlock1_52',0,'14810467'),('bmBlock1_520',0,'15060497'),('bmBlock1_53',0,'14810477'),('bmBlock1_54',0,'14810487'),('bmBlock1_55',0,'14810497'),('bmBlock1_56',0,'14810507'),('bmBlock1_57',0,'14810517'),('bmBlock1_58',0,'14820277'),('bmBlock1_59',0,'14820297'),('bmBlock1_6',0,'14790347'),('bmBlock1_60',0,'14820317'),('bmBlock1_61',0,'14820337'),('bmBlock1_62',0,'14820357'),('bmBlock1_63',0,'14820377'),('bmBlock1_64',0,'14820397'),('bmBlock1_65',0,'14820417'),('bmBlock1_66',0,'14820437'),('bmBlock1_67',0,'14820457'),('bmBlock1_68',0,'14820477'),('bmBlock1_69',0,'14820497'),('bmBlock1_7',0,'14790357'),('bmBlock1_70',0,'14820517'),('bmBlock1_71',0,'14830277'),('bmBlock1_72',0,'14830287'),('bmBlock1_73',0,'14830297'),('bmBlock1_74',0,'14830307'),('bmBlock1_75',0,'14830317'),('bmBlock1_76',0,'14830327'),('bmBlock1_77',0,'14830337'),('bmBlock1_78',0,'14830347'),('bmBlock1_79',0,'14830357'),('bmBlock1_8',0,'14790367'),('bmBlock1_80',0,'14830367'),('bmBlock1_81',0,'14830377'),('bmBlock1_82',0,'14830387'),('bmBlock1_83',0,'14830397'),('bmBlock1_84',0,'14830407'),('bmBlock1_85',0,'14830417'),('bmBlock1_86',0,'14830427'),('bmBlock1_87',0,'14830437'),('bmBlock1_88',0,'14830447'),('bmBlock1_89',0,'14830457'),('bmBlock1_9',0,'14790377'),('bmBlock1_90',0,'14830467'),('bmBlock1_91',0,'14830477'),('bmBlock1_92',0,'14830487'),('bmBlock1_93',0,'14830497'),('bmBlock1_94',0,'14830507'),('bmBlock1_95',0,'14830517'),('bmBlock1_96',0,'14840277'),('bmBlock1_97',0,'14840297'),('bmBlock1_98',0,'14840317'),('bmBlock1_99',0,'14840337'),('bmBlock2_1',0,'15480307'),('bmBlock2_10',0,'15480397'),('bmBlock2_100',0,'15530367'),('bmBlock2_101',0,'15530387'),('bmBlock2_102',0,'15530407'),('bmBlock2_103',0,'15530427'),('bmBlock2_104',0,'15530447'),('bmBlock2_105',0,'15530467'),('bmBlock2_106',0,'15530487'),('bmBlock2_107',0,'15530507'),('bmBlock2_108',0,'15530527'),('bmBlock2_109',0,'15540287'),('bmBlock2_11',0,'15480407'),('bmBlock2_110',0,'15540297'),('bmBlock2_111',0,'15540307'),('bmBlock2_112',0,'15540317'),('bmBlock2_113',0,'15540327'),('bmBlock2_114',0,'15540337'),('bmBlock2_115',0,'15540347'),('bmBlock2_116',0,'15540357'),('bmBlock2_117',0,'15540367'),('bmBlock2_118',0,'15540377'),('bmBlock2_119',0,'15540387'),('bmBlock2_12',0,'15480417'),('bmBlock2_120',0,'15540397'),('bmBlock2_121',0,'15540407'),('bmBlock2_122',0,'15540417'),('bmBlock2_123',0,'15540427'),('bmBlock2_124',0,'15540437'),('bmBlock2_125',0,'15540447'),('bmBlock2_126',0,'15540457'),('bmBlock2_127',0,'15540467'),('bmBlock2_128',0,'15540477'),('bmBlock2_129',0,'15540487'),('bmBlock2_13',0,'15480427'),('bmBlock2_130',0,'15540497'),('bmBlock2_131',0,'15540507'),('bmBlock2_132',0,'15540517'),('bmBlock2_133',0,'15540527'),('bmBlock2_134',0,'15550287'),('bmBlock2_135',0,'15550307'),('bmBlock2_136',0,'15550327'),('bmBlock2_137',0,'15550347'),('bmBlock2_138',0,'15550367'),('bmBlock2_139',0,'15550387'),('bmBlock2_14',0,'15480437'),('bmBlock2_140',0,'15550407'),('bmBlock2_141',0,'15550427'),('bmBlock2_142',0,'15550447'),('bmBlock2_143',0,'15550467'),('bmBlock2_144',0,'15550487'),('bmBlock2_145',0,'15550507'),('bmBlock2_146',0,'15550527'),('bmBlock2_147',0,'15560287'),('bmBlock2_148',0,'15560297'),('bmBlock2_149',0,'15560307'),('bmBlock2_15',0,'15480447'),('bmBlock2_150',0,'15560317'),('bmBlock2_151',0,'15560327'),('bmBlock2_152',0,'15560337'),('bmBlock2_153',0,'15560347'),('bmBlock2_154',0,'15560357'),('bmBlock2_155',0,'15560367'),('bmBlock2_156',0,'15560377'),('bmBlock2_157',0,'15560387'),('bmBlock2_158',0,'15560397'),('bmBlock2_159',0,'15560407'),('bmBlock2_16',0,'15480457'),('bmBlock2_160',0,'15560417'),('bmBlock2_161',0,'15560427'),('bmBlock2_162',0,'15560437'),('bmBlock2_163',0,'15560447'),('bmBlock2_164',0,'15560457'),('bmBlock2_165',0,'15560467'),('bmBlock2_166',0,'15560477'),('bmBlock2_167',0,'15560487'),('bmBlock2_168',0,'15560497'),('bmBlock2_169',0,'15560507'),('bmBlock2_17',0,'15480467'),('bmBlock2_170',0,'15560517'),('bmBlock2_171',0,'15560527'),('bmBlock2_172',0,'15570287'),('bmBlock2_173',0,'15570307'),('bmBlock2_174',0,'15570327'),('bmBlock2_175',0,'15570347'),('bmBlock2_176',0,'15570367'),('bmBlock2_177',0,'15570387'),('bmBlock2_178',0,'15570407'),('bmBlock2_179',0,'15570427'),('bmBlock2_18',0,'15480477'),('bmBlock2_180',0,'15570447'),('bmBlock2_181',0,'15570467'),('bmBlock2_182',0,'15570487'),('bmBlock2_183',0,'15570507'),('bmBlock2_184',0,'15570527'),('bmBlock2_185',0,'15580287'),('bmBlock2_186',0,'15580297'),('bmBlock2_187',0,'15580307'),('bmBlock2_188',0,'15580317'),('bmBlock2_189',0,'15580327'),('bmBlock2_19',0,'15480487'),('bmBlock2_190',0,'15580337'),('bmBlock2_191',0,'15580347'),('bmBlock2_192',0,'15580357'),('bmBlock2_193',0,'15580367'),('bmBlock2_194',0,'15580377'),('bmBlock2_195',0,'15580387'),('bmBlock2_196',0,'15580397'),('bmBlock2_197',0,'15580407'),('bmBlock2_198',0,'15580417'),('bmBlock2_199',0,'15580427'),('bmBlock2_2',0,'15480317'),('bmBlock2_20',0,'15480497'),('bmBlock2_200',0,'15580437'),('bmBlock2_201',0,'15580447'),('bmBlock2_202',0,'15580457'),('bmBlock2_203',0,'15580467'),('bmBlock2_204',0,'15580477'),('bmBlock2_205',0,'15580487'),('bmBlock2_206',0,'15580497'),('bmBlock2_207',0,'15580507'),('bmBlock2_208',0,'15580517'),('bmBlock2_209',0,'15580527'),('bmBlock2_21',0,'15480507'),('bmBlock2_210',0,'15590287'),('bmBlock2_211',0,'15590307'),('bmBlock2_212',0,'15590327'),('bmBlock2_213',0,'15590347'),('bmBlock2_214',0,'15590367'),('bmBlock2_215',0,'15590387'),('bmBlock2_216',0,'15590407'),('bmBlock2_217',0,'15590427'),('bmBlock2_218',0,'15590447'),('bmBlock2_219',0,'15590467'),('bmBlock2_22',0,'15490307'),('bmBlock2_220',0,'15590487'),('bmBlock2_221',0,'15590507'),('bmBlock2_222',0,'15590527'),('bmBlock2_223',0,'15600287'),('bmBlock2_224',0,'15600297'),('bmBlock2_225',0,'15600307'),('bmBlock2_226',0,'15600317'),('bmBlock2_227',0,'15600327'),('bmBlock2_228',0,'15600337'),('bmBlock2_229',0,'15600347'),('bmBlock2_23',0,'15490327'),('bmBlock2_230',0,'15600357'),('bmBlock2_231',0,'15600367'),('bmBlock2_232',0,'15600377'),('bmBlock2_233',0,'15600387'),('bmBlock2_234',0,'15600397'),('bmBlock2_235',0,'15600407'),('bmBlock2_236',0,'15600417'),('bmBlock2_237',0,'15600427'),('bmBlock2_238',0,'15600437'),('bmBlock2_239',0,'15600447'),('bmBlock2_24',0,'15490347'),('bmBlock2_240',0,'15600457'),('bmBlock2_241',0,'15600467'),('bmBlock2_242',0,'15600477'),('bmBlock2_243',0,'15600487'),('bmBlock2_244',0,'15600497'),('bmBlock2_245',0,'15600507'),('bmBlock2_246',0,'15600517'),('bmBlock2_247',0,'15600527'),('bmBlock2_248',0,'15610287'),('bmBlock2_249',0,'15610307'),('bmBlock2_25',0,'15490367'),('bmBlock2_250',0,'15610327'),('bmBlock2_251',0,'15610347'),('bmBlock2_252',0,'15610367'),('bmBlock2_253',0,'15610387'),('bmBlock2_254',0,'15610407'),('bmBlock2_255',0,'15610427'),('bmBlock2_256',0,'15610447'),('bmBlock2_257',0,'15610467'),('bmBlock2_258',0,'15610487'),('bmBlock2_259',0,'15610507'),('bmBlock2_26',0,'15490387'),('bmBlock2_260',0,'15610527'),('bmBlock2_261',0,'15620287'),('bmBlock2_262',0,'15620297'),('bmBlock2_263',0,'15620307'),('bmBlock2_264',0,'15620317'),('bmBlock2_265',0,'15620327'),('bmBlock2_266',0,'15620337'),('bmBlock2_267',0,'15620347'),('bmBlock2_268',0,'15620357'),('bmBlock2_269',0,'15620367'),('bmBlock2_27',0,'15490407'),('bmBlock2_270',0,'15620377'),('bmBlock2_271',0,'15620387'),('bmBlock2_272',0,'15620397'),('bmBlock2_273',0,'15620407'),('bmBlock2_274',0,'15620417'),('bmBlock2_275',0,'15620427'),('bmBlock2_276',0,'15620437'),('bmBlock2_277',0,'15620447'),('bmBlock2_278',0,'15620457'),('bmBlock2_279',0,'15620467'),('bmBlock2_28',0,'15490427'),('bmBlock2_280',0,'15620477'),('bmBlock2_281',0,'15620487'),('bmBlock2_282',0,'15620497'),('bmBlock2_283',0,'15620507'),('bmBlock2_284',0,'15620517'),('bmBlock2_285',0,'15620527'),('bmBlock2_286',0,'15630287'),('bmBlock2_287',0,'15630307'),('bmBlock2_288',0,'15630327'),('bmBlock2_289',0,'15630347'),('bmBlock2_29',0,'15490447'),('bmBlock2_290',0,'15630367'),('bmBlock2_291',0,'15630387'),('bmBlock2_292',0,'15630407'),('bmBlock2_293',0,'15630427'),('bmBlock2_294',0,'15630447'),('bmBlock2_295',0,'15630467'),('bmBlock2_296',0,'15630487'),('bmBlock2_297',0,'15630507'),('bmBlock2_298',0,'15630527'),('bmBlock2_299',0,'15640287'),('bmBlock2_3',0,'15480327'),('bmBlock2_30',0,'15490467'),('bmBlock2_300',0,'15640297'),('bmBlock2_301',0,'15640307'),('bmBlock2_302',0,'15640317'),('bmBlock2_303',0,'15640327'),('bmBlock2_304',0,'15640337'),('bmBlock2_305',0,'15640347'),('bmBlock2_306',0,'15640357'),('bmBlock2_307',0,'15640367'),('bmBlock2_308',0,'15640377'),('bmBlock2_309',0,'15640387'),('bmBlock2_31',0,'15490487'),('bmBlock2_310',0,'15640397'),('bmBlock2_311',0,'15640407'),('bmBlock2_312',0,'15640417'),('bmBlock2_313',0,'15640427'),('bmBlock2_314',0,'15640437'),('bmBlock2_315',0,'15640447'),('bmBlock2_316',0,'15640457'),('bmBlock2_317',0,'15640467'),('bmBlock2_318',0,'15640477'),('bmBlock2_319',0,'15640487'),('bmBlock2_32',0,'15490507'),('bmBlock2_320',0,'15640497'),('bmBlock2_321',0,'15640507'),('bmBlock2_322',0,'15640517'),('bmBlock2_323',0,'15640527'),('bmBlock2_324',0,'15650287'),('bmBlock2_325',0,'15650307'),('bmBlock2_326',0,'15650327'),('bmBlock2_327',0,'15650347'),('bmBlock2_328',0,'15650367'),('bmBlock2_329',0,'15650387'),('bmBlock2_33',0,'15500287'),('bmBlock2_330',0,'15650407'),('bmBlock2_331',0,'15650427'),('bmBlock2_332',0,'15650447'),('bmBlock2_333',0,'15650467'),('bmBlock2_334',0,'15650487'),('bmBlock2_335',0,'15650507'),('bmBlock2_336',0,'15650527'),('bmBlock2_337',0,'15660287'),('bmBlock2_338',0,'15660297'),('bmBlock2_339',0,'15660307'),('bmBlock2_34',0,'15500297'),('bmBlock2_340',0,'15660317'),('bmBlock2_341',0,'15660327'),('bmBlock2_342',0,'15660337'),('bmBlock2_343',0,'15660347'),('bmBlock2_344',0,'15660357'),('bmBlock2_345',0,'15660367'),('bmBlock2_346',0,'15660377'),('bmBlock2_347',0,'15660387'),('bmBlock2_348',0,'15660397'),('bmBlock2_349',0,'15660407'),('bmBlock2_35',0,'15500307'),('bmBlock2_350',0,'15660417'),('bmBlock2_351',0,'15660427'),('bmBlock2_352',0,'15660437'),('bmBlock2_353',0,'15660447'),('bmBlock2_354',0,'15660457'),('bmBlock2_355',0,'15660467'),('bmBlock2_356',0,'15660477'),('bmBlock2_357',0,'15660487'),('bmBlock2_358',0,'15660497'),('bmBlock2_359',0,'15660507'),('bmBlock2_36',0,'15500317'),('bmBlock2_360',0,'15660517'),('bmBlock2_361',0,'15660527'),('bmBlock2_362',0,'15670287'),('bmBlock2_363',0,'15670307'),('bmBlock2_364',0,'15670327'),('bmBlock2_365',0,'15670347'),('bmBlock2_366',0,'15670367'),('bmBlock2_367',0,'15670387'),('bmBlock2_368',0,'15670407'),('bmBlock2_369',0,'15670427'),('bmBlock2_37',0,'15500327'),('bmBlock2_370',0,'15670447'),('bmBlock2_371',0,'15670467'),('bmBlock2_372',0,'15670487'),('bmBlock2_373',0,'15670507'),('bmBlock2_374',0,'15670527'),('bmBlock2_375',0,'15680287'),('bmBlock2_376',0,'15680297'),('bmBlock2_377',0,'15680307'),('bmBlock2_378',0,'15680317'),('bmBlock2_379',0,'15680327'),('bmBlock2_38',0,'15500337'),('bmBlock2_380',0,'15680337'),('bmBlock2_381',0,'15680347'),('bmBlock2_382',0,'15680357'),('bmBlock2_383',0,'15680367'),('bmBlock2_384',0,'15680377'),('bmBlock2_385',0,'15680387'),('bmBlock2_386',0,'15680397'),('bmBlock2_387',0,'15680407'),('bmBlock2_388',0,'15680417'),('bmBlock2_389',0,'15680427'),('bmBlock2_39',0,'15500347'),('bmBlock2_390',0,'15680437'),('bmBlock2_391',0,'15680447'),('bmBlock2_392',0,'15680457'),('bmBlock2_393',0,'15680467'),('bmBlock2_394',0,'15680477'),('bmBlock2_395',0,'15680487'),('bmBlock2_396',0,'15680497'),('bmBlock2_397',0,'15680507'),('bmBlock2_398',0,'15680517'),('bmBlock2_399',0,'15680527'),('bmBlock2_4',0,'15480337'),('bmBlock2_40',0,'15500357'),('bmBlock2_400',0,'15690287'),('bmBlock2_401',0,'15690307'),('bmBlock2_402',0,'15690327'),('bmBlock2_403',0,'15690347'),('bmBlock2_404',0,'15690367'),('bmBlock2_405',0,'15690387'),('bmBlock2_406',0,'15690407'),('bmBlock2_407',0,'15690427'),('bmBlock2_408',0,'15690447'),('bmBlock2_409',0,'15690467'),('bmBlock2_41',0,'15500367'),('bmBlock2_410',0,'15690487'),('bmBlock2_411',0,'15690507'),('bmBlock2_412',0,'15690527'),('bmBlock2_413',0,'15700287'),('bmBlock2_414',0,'15700297'),('bmBlock2_415',0,'15700307'),('bmBlock2_416',0,'15700317'),('bmBlock2_417',0,'15700327'),('bmBlock2_418',0,'15700337'),('bmBlock2_419',0,'15700347'),('bmBlock2_42',0,'15500377'),('bmBlock2_420',0,'15700357'),('bmBlock2_421',0,'15700367'),('bmBlock2_422',0,'15700377'),('bmBlock2_423',0,'15700387'),('bmBlock2_424',0,'15700397'),('bmBlock2_425',0,'15700407'),('bmBlock2_426',0,'15700417'),('bmBlock2_427',0,'15700427'),('bmBlock2_428',0,'15700437'),('bmBlock2_429',0,'15700447'),('bmBlock2_43',0,'15500387'),('bmBlock2_430',0,'15700457'),('bmBlock2_431',0,'15700467'),('bmBlock2_432',0,'15700477'),('bmBlock2_433',0,'15700487'),('bmBlock2_434',0,'15700497'),('bmBlock2_435',0,'15700507'),('bmBlock2_436',0,'15700517'),('bmBlock2_437',0,'15700527'),('bmBlock2_438',0,'15710287'),('bmBlock2_439',0,'15710307'),('bmBlock2_44',0,'15500397'),('bmBlock2_440',0,'15710327'),('bmBlock2_441',0,'15710347'),('bmBlock2_442',0,'15710367'),('bmBlock2_443',0,'15710387'),('bmBlock2_444',0,'15710407'),('bmBlock2_445',0,'15710427'),('bmBlock2_446',0,'15710447'),('bmBlock2_447',0,'15710467'),('bmBlock2_448',0,'15710487'),('bmBlock2_449',0,'15710507'),('bmBlock2_45',0,'15500407'),('bmBlock2_450',0,'15710527'),('bmBlock2_451',0,'15720287'),('bmBlock2_452',0,'15720297'),('bmBlock2_453',0,'15720307'),('bmBlock2_454',0,'15720317'),('bmBlock2_455',0,'15720327'),('bmBlock2_456',0,'15720337'),('bmBlock2_457',0,'15720347'),('bmBlock2_458',0,'15720357'),('bmBlock2_459',0,'15720367'),('bmBlock2_46',0,'15500417'),('bmBlock2_460',0,'15720377'),('bmBlock2_461',0,'15720387'),('bmBlock2_462',0,'15720397'),('bmBlock2_463',0,'15720407'),('bmBlock2_464',0,'15720417'),('bmBlock2_465',0,'15720427'),('bmBlock2_466',0,'15720437'),('bmBlock2_467',0,'15720447'),('bmBlock2_468',0,'15720457'),('bmBlock2_469',0,'15720467'),('bmBlock2_47',0,'15500427'),('bmBlock2_470',0,'15720477'),('bmBlock2_471',0,'15720487'),('bmBlock2_472',0,'15720497'),('bmBlock2_473',0,'15720507'),('bmBlock2_474',0,'15720517'),('bmBlock2_475',0,'15720527'),('bmBlock2_476',0,'15730287'),('bmBlock2_477',0,'15730307'),('bmBlock2_478',0,'15730327'),('bmBlock2_479',0,'15730347'),('bmBlock2_48',0,'15500437'),('bmBlock2_480',0,'15730367'),('bmBlock2_481',0,'15730387'),('bmBlock2_482',0,'15730407'),('bmBlock2_483',0,'15730427'),('bmBlock2_484',0,'15730447'),('bmBlock2_485',0,'15730467'),('bmBlock2_486',0,'15730487'),('bmBlock2_487',0,'15730507'),('bmBlock2_488',0,'15730527'),('bmBlock2_489',0,'15740307'),('bmBlock2_49',0,'15500447'),('bmBlock2_490',0,'15740317'),('bmBlock2_491',0,'15740327'),('bmBlock2_492',0,'15740337'),('bmBlock2_493',0,'15740347'),('bmBlock2_494',0,'15740357'),('bmBlock2_495',0,'15740367'),('bmBlock2_496',0,'15740377'),('bmBlock2_497',0,'15740387'),('bmBlock2_498',0,'15740397'),('bmBlock2_499',0,'15740407'),('bmBlock2_5',0,'15480347'),('bmBlock2_50',0,'15500457'),('bmBlock2_500',0,'15740417'),('bmBlock2_501',0,'15740427'),('bmBlock2_502',0,'15740437'),('bmBlock2_503',0,'15740447'),('bmBlock2_504',0,'15740457'),('bmBlock2_505',0,'15740467'),('bmBlock2_506',0,'15740477'),('bmBlock2_507',0,'15740487'),('bmBlock2_508',0,'15740497'),('bmBlock2_509',0,'15740507'),('bmBlock2_51',0,'15500467'),('bmBlock2_510',0,'15750307'),('bmBlock2_511',0,'15750327'),('bmBlock2_512',0,'15750347'),('bmBlock2_513',0,'15750367'),('bmBlock2_514',0,'15750387'),('bmBlock2_515',0,'15750407'),('bmBlock2_516',0,'15750427'),('bmBlock2_517',0,'15750447'),('bmBlock2_518',0,'15750467'),('bmBlock2_519',0,'15750487'),('bmBlock2_52',0,'15500477'),('bmBlock2_520',0,'15750507'),('bmBlock2_53',0,'15500487'),('bmBlock2_54',0,'15500497'),('bmBlock2_55',0,'15500507'),('bmBlock2_56',0,'15500517'),('bmBlock2_57',0,'15500527'),('bmBlock2_58',0,'15510287'),('bmBlock2_59',0,'15510307'),('bmBlock2_6',0,'15480357'),('bmBlock2_60',0,'15510327'),('bmBlock2_61',0,'15510347'),('bmBlock2_62',0,'15510367'),('bmBlock2_63',0,'15510387'),('bmBlock2_64',0,'15510407'),('bmBlock2_65',0,'15510427'),('bmBlock2_66',0,'15510447'),('bmBlock2_67',0,'15510467'),('bmBlock2_68',0,'15510487'),('bmBlock2_69',0,'15510507'),('bmBlock2_7',0,'15480367'),('bmBlock2_70',0,'15510527'),('bmBlock2_71',0,'15520287'),('bmBlock2_72',0,'15520297'),('bmBlock2_73',0,'15520307'),('bmBlock2_74',0,'15520317'),('bmBlock2_75',0,'15520327'),('bmBlock2_76',0,'15520337'),('bmBlock2_77',0,'15520347'),('bmBlock2_78',0,'15520357'),('bmBlock2_79',0,'15520367'),('bmBlock2_8',0,'15480377'),('bmBlock2_80',0,'15520377'),('bmBlock2_81',0,'15520387'),('bmBlock2_82',0,'15520397'),('bmBlock2_83',0,'15520407'),('bmBlock2_84',0,'15520417'),('bmBlock2_85',0,'15520427'),('bmBlock2_86',0,'15520437'),('bmBlock2_87',0,'15520447'),('bmBlock2_88',0,'15520457'),('bmBlock2_89',0,'15520467'),('bmBlock2_9',0,'15480387'),('bmBlock2_90',0,'15520477'),('bmBlock2_91',0,'15520487'),('bmBlock2_92',0,'15520497'),('bmBlock2_93',0,'15520507'),('bmBlock2_94',0,'15520517'),('bmBlock2_95',0,'15520527'),('bmBlock2_96',0,'15530287'),('bmBlock2_97',0,'15530307'),('bmBlock2_98',0,'15530327'),('bmBlock2_99',0,'15530347'),('bmBlock3_1',0,'14810847'),('bmBlock3_10',0,'14810937'),('bmBlock3_100',0,'14860907'),('bmBlock3_101',0,'14860927'),('bmBlock3_102',0,'14860947'),('bmBlock3_103',0,'14860967'),('bmBlock3_104',0,'14860987'),('bmBlock3_105',0,'14861007'),('bmBlock3_106',0,'14861027'),('bmBlock3_107',0,'14861047'),('bmBlock3_108',0,'14861067'),('bmBlock3_109',0,'14870827'),('bmBlock3_11',0,'14810947'),('bmBlock3_110',0,'14870837'),('bmBlock3_111',0,'14870847'),('bmBlock3_112',0,'14870857'),('bmBlock3_113',0,'14870867'),('bmBlock3_114',0,'14870877'),('bmBlock3_115',0,'14870887'),('bmBlock3_116',0,'14870897'),('bmBlock3_117',0,'14870907'),('bmBlock3_118',0,'14870917'),('bmBlock3_119',0,'14870927'),('bmBlock3_12',0,'14810957'),('bmBlock3_120',0,'14870937'),('bmBlock3_121',0,'14870947'),('bmBlock3_122',0,'14870957'),('bmBlock3_123',0,'14870967'),('bmBlock3_124',0,'14870977'),('bmBlock3_125',0,'14870987'),('bmBlock3_126',0,'14870997'),('bmBlock3_127',0,'14871007'),('bmBlock3_128',0,'14871017'),('bmBlock3_129',0,'14871027'),('bmBlock3_13',0,'14810967'),('bmBlock3_130',0,'14871037'),('bmBlock3_131',0,'14871047'),('bmBlock3_132',0,'14871057'),('bmBlock3_133',0,'14871067'),('bmBlock3_134',0,'14880827'),('bmBlock3_135',0,'14880847'),('bmBlock3_136',0,'14880867'),('bmBlock3_137',0,'14880887'),('bmBlock3_138',0,'14880907'),('bmBlock3_139',0,'14880927'),('bmBlock3_14',0,'14810977'),('bmBlock3_140',0,'14880947'),('bmBlock3_141',0,'14880967'),('bmBlock3_142',0,'14880987'),('bmBlock3_143',0,'14881007'),('bmBlock3_144',0,'14881027'),('bmBlock3_145',0,'14881047'),('bmBlock3_146',0,'14881067'),('bmBlock3_147',0,'14890827'),('bmBlock3_148',0,'14890837'),('bmBlock3_149',0,'14890847'),('bmBlock3_15',0,'14810987'),('bmBlock3_150',0,'14890857'),('bmBlock3_151',0,'14890867'),('bmBlock3_152',0,'14890877'),('bmBlock3_153',0,'14890887'),('bmBlock3_154',0,'14890897'),('bmBlock3_155',0,'14890907'),('bmBlock3_156',0,'14890917'),('bmBlock3_157',0,'14890927'),('bmBlock3_158',0,'14890937'),('bmBlock3_159',0,'14890947'),('bmBlock3_16',0,'14810997'),('bmBlock3_160',0,'14890957'),('bmBlock3_161',0,'14890967'),('bmBlock3_162',0,'14890977'),('bmBlock3_163',0,'14890987'),('bmBlock3_164',0,'14890997'),('bmBlock3_165',0,'14891007'),('bmBlock3_166',0,'14891017'),('bmBlock3_167',0,'14891027'),('bmBlock3_168',0,'14891037'),('bmBlock3_169',0,'14891047'),('bmBlock3_17',0,'14811007'),('bmBlock3_170',0,'14891057'),('bmBlock3_171',0,'14891067'),('bmBlock3_172',0,'14900827'),('bmBlock3_173',0,'14900847'),('bmBlock3_174',0,'14900867'),('bmBlock3_175',0,'14900887'),('bmBlock3_176',0,'14900907'),('bmBlock3_177',0,'14900927'),('bmBlock3_178',0,'14900947'),('bmBlock3_179',0,'14900967'),('bmBlock3_18',0,'14811017'),('bmBlock3_180',0,'14900987'),('bmBlock3_181',0,'14901007'),('bmBlock3_182',0,'14901027'),('bmBlock3_183',0,'14901047'),('bmBlock3_184',0,'14901067'),('bmBlock3_185',0,'14910827'),('bmBlock3_186',0,'14910837'),('bmBlock3_187',0,'14910847'),('bmBlock3_188',0,'14910857'),('bmBlock3_189',0,'14910867'),('bmBlock3_19',0,'14811027'),('bmBlock3_190',0,'14910877'),('bmBlock3_191',0,'14910887'),('bmBlock3_192',0,'14910897'),('bmBlock3_193',0,'14910907'),('bmBlock3_194',0,'14910917'),('bmBlock3_195',0,'14910927'),('bmBlock3_196',0,'14910937'),('bmBlock3_197',0,'14910947'),('bmBlock3_198',0,'14910957'),('bmBlock3_199',0,'14910967'),('bmBlock3_2',0,'14810857'),('bmBlock3_20',0,'14811037'),('bmBlock3_200',0,'14910977'),('bmBlock3_201',0,'14910987'),('bmBlock3_202',0,'14910997'),('bmBlock3_203',0,'14911007'),('bmBlock3_204',0,'14911017'),('bmBlock3_205',0,'14911027'),('bmBlock3_206',0,'14911037'),('bmBlock3_207',0,'14911047'),('bmBlock3_208',0,'14911057'),('bmBlock3_209',0,'14911067'),('bmBlock3_21',0,'14811047'),('bmBlock3_210',0,'14920827'),('bmBlock3_211',0,'14920847'),('bmBlock3_212',0,'14920867'),('bmBlock3_213',0,'14920887'),('bmBlock3_214',0,'14920907'),('bmBlock3_215',0,'14920927'),('bmBlock3_216',0,'14920947'),('bmBlock3_217',0,'14920967'),('bmBlock3_218',0,'14920987'),('bmBlock3_219',0,'14921007'),('bmBlock3_22',0,'14820847'),('bmBlock3_220',0,'14921027'),('bmBlock3_221',0,'14921047'),('bmBlock3_222',0,'14921067'),('bmBlock3_223',0,'14930827'),('bmBlock3_224',0,'14930837'),('bmBlock3_225',0,'14930847'),('bmBlock3_226',0,'14930857'),('bmBlock3_227',0,'14930867'),('bmBlock3_228',0,'14930877'),('bmBlock3_229',0,'14930887'),('bmBlock3_23',0,'14820867'),('bmBlock3_230',0,'14930897'),('bmBlock3_231',0,'14930907'),('bmBlock3_232',0,'14930917'),('bmBlock3_233',0,'14930927'),('bmBlock3_234',0,'14930937'),('bmBlock3_235',0,'14930947'),('bmBlock3_236',0,'14930957'),('bmBlock3_237',0,'14930967'),('bmBlock3_238',0,'14930977'),('bmBlock3_239',0,'14930987'),('bmBlock3_24',0,'14820887'),('bmBlock3_240',0,'14930997'),('bmBlock3_241',0,'14931007'),('bmBlock3_242',0,'14931017'),('bmBlock3_243',0,'14931027'),('bmBlock3_244',0,'14931037'),('bmBlock3_245',0,'14931047'),('bmBlock3_246',0,'14931057'),('bmBlock3_247',0,'14931067'),('bmBlock3_248',0,'14940827'),('bmBlock3_249',0,'14940847'),('bmBlock3_25',0,'14820907'),('bmBlock3_250',0,'14940867'),('bmBlock3_251',0,'14940887'),('bmBlock3_252',0,'14940907'),('bmBlock3_253',0,'14940927'),('bmBlock3_254',0,'14940947'),('bmBlock3_255',0,'14940967'),('bmBlock3_256',0,'14940987'),('bmBlock3_257',0,'14941007'),('bmBlock3_258',0,'14941027'),('bmBlock3_259',0,'14941047'),('bmBlock3_26',0,'14820927'),('bmBlock3_260',0,'14941067'),('bmBlock3_261',0,'14950827'),('bmBlock3_262',0,'14950837'),('bmBlock3_263',0,'14950847'),('bmBlock3_264',0,'14950857'),('bmBlock3_265',0,'14950867'),('bmBlock3_266',0,'14950877'),('bmBlock3_267',0,'14950887'),('bmBlock3_268',0,'14950897'),('bmBlock3_269',0,'14950907'),('bmBlock3_27',0,'14820947'),('bmBlock3_270',0,'14950917'),('bmBlock3_271',0,'14950927'),('bmBlock3_272',0,'14950937'),('bmBlock3_273',0,'14950947'),('bmBlock3_274',0,'14950957'),('bmBlock3_275',0,'14950967'),('bmBlock3_276',0,'14950977'),('bmBlock3_277',0,'14950987'),('bmBlock3_278',0,'14950997'),('bmBlock3_279',0,'14951007'),('bmBlock3_28',0,'14820967'),('bmBlock3_280',0,'14951017'),('bmBlock3_281',0,'14951027'),('bmBlock3_282',0,'14951037'),('bmBlock3_283',0,'14951047'),('bmBlock3_284',0,'14951057'),('bmBlock3_285',0,'14951067'),('bmBlock3_286',0,'14960827'),('bmBlock3_287',0,'14960847'),('bmBlock3_288',0,'14960867'),('bmBlock3_289',0,'14960887'),('bmBlock3_29',0,'14820987'),('bmBlock3_290',0,'14960907'),('bmBlock3_291',0,'14960927'),('bmBlock3_292',0,'14960947'),('bmBlock3_293',0,'14960967'),('bmBlock3_294',0,'14960987'),('bmBlock3_295',0,'14961007'),('bmBlock3_296',0,'14961027'),('bmBlock3_297',0,'14961047'),('bmBlock3_298',0,'14961067'),('bmBlock3_299',0,'14970827'),('bmBlock3_3',0,'14810867'),('bmBlock3_30',0,'14821007'),('bmBlock3_300',0,'14970837'),('bmBlock3_301',0,'14970847'),('bmBlock3_302',0,'14970857'),('bmBlock3_303',0,'14970867'),('bmBlock3_304',0,'14970877'),('bmBlock3_305',0,'14970887'),('bmBlock3_306',0,'14970897'),('bmBlock3_307',0,'14970907'),('bmBlock3_308',0,'14970917'),('bmBlock3_309',0,'14970927'),('bmBlock3_31',0,'14821027'),('bmBlock3_310',0,'14970937'),('bmBlock3_311',0,'14970947'),('bmBlock3_312',0,'14970957'),('bmBlock3_313',0,'14970967'),('bmBlock3_314',0,'14970977'),('bmBlock3_315',0,'14970987'),('bmBlock3_316',0,'14970997'),('bmBlock3_317',0,'14971007'),('bmBlock3_318',0,'14971017'),('bmBlock3_319',0,'14971027'),('bmBlock3_32',0,'14821047'),('bmBlock3_320',0,'14971037'),('bmBlock3_321',0,'14971047'),('bmBlock3_322',0,'14971057'),('bmBlock3_323',0,'14971067'),('bmBlock3_324',0,'14980827'),('bmBlock3_325',0,'14980847'),('bmBlock3_326',0,'14980867'),('bmBlock3_327',0,'14980887'),('bmBlock3_328',0,'14980907'),('bmBlock3_329',0,'14980927'),('bmBlock3_33',0,'14830827'),('bmBlock3_330',0,'14980947'),('bmBlock3_331',0,'14980967'),('bmBlock3_332',0,'14980987'),('bmBlock3_333',0,'14981007'),('bmBlock3_334',0,'14981027'),('bmBlock3_335',0,'14981047'),('bmBlock3_336',0,'14981067'),('bmBlock3_337',0,'14990827'),('bmBlock3_338',0,'14990837'),('bmBlock3_339',0,'14990847'),('bmBlock3_34',0,'14830837'),('bmBlock3_340',0,'14990857'),('bmBlock3_341',0,'14990867'),('bmBlock3_342',0,'14990877'),('bmBlock3_343',0,'14990887'),('bmBlock3_344',0,'14990897'),('bmBlock3_345',0,'14990907'),('bmBlock3_346',0,'14990917'),('bmBlock3_347',0,'14990927'),('bmBlock3_348',0,'14990937'),('bmBlock3_349',0,'14990947'),('bmBlock3_35',0,'14830847'),('bmBlock3_350',0,'14990957'),('bmBlock3_351',0,'14990967'),('bmBlock3_352',0,'14990977'),('bmBlock3_353',0,'14990987'),('bmBlock3_354',0,'14990997'),('bmBlock3_355',0,'14991007'),('bmBlock3_356',0,'14991017'),('bmBlock3_357',0,'14991027'),('bmBlock3_358',0,'14991037'),('bmBlock3_359',0,'14991047'),('bmBlock3_36',0,'14830857'),('bmBlock3_360',0,'14991057'),('bmBlock3_361',0,'14991067'),('bmBlock3_362',0,'15000827'),('bmBlock3_363',0,'15000847'),('bmBlock3_364',0,'15000867'),('bmBlock3_365',0,'15000887'),('bmBlock3_366',0,'15000907'),('bmBlock3_367',0,'15000927'),('bmBlock3_368',0,'15000947'),('bmBlock3_369',0,'15000967'),('bmBlock3_37',0,'14830867'),('bmBlock3_370',0,'15000987'),('bmBlock3_371',0,'15001007'),('bmBlock3_372',0,'15001027'),('bmBlock3_373',0,'15001047'),('bmBlock3_374',0,'15001067'),('bmBlock3_375',0,'15010827'),('bmBlock3_376',0,'15010837'),('bmBlock3_377',0,'15010847'),('bmBlock3_378',0,'15010857'),('bmBlock3_379',0,'15010867'),('bmBlock3_38',0,'14830877'),('bmBlock3_380',0,'15010877'),('bmBlock3_381',0,'15010887'),('bmBlock3_382',0,'15010897'),('bmBlock3_383',0,'15010907'),('bmBlock3_384',0,'15010917'),('bmBlock3_385',0,'15010927'),('bmBlock3_386',0,'15010937'),('bmBlock3_387',0,'15010947'),('bmBlock3_388',0,'15010957'),('bmBlock3_389',0,'15010967'),('bmBlock3_39',0,'14830887'),('bmBlock3_390',0,'15010977'),('bmBlock3_391',0,'15010987'),('bmBlock3_392',0,'15010997'),('bmBlock3_393',0,'15011007'),('bmBlock3_394',0,'15011017'),('bmBlock3_395',0,'15011027'),('bmBlock3_396',0,'15011037'),('bmBlock3_397',0,'15011047'),('bmBlock3_398',0,'15011057'),('bmBlock3_399',0,'15011067'),('bmBlock3_4',0,'14810877'),('bmBlock3_40',0,'14830897'),('bmBlock3_400',0,'15020827'),('bmBlock3_401',0,'15020847'),('bmBlock3_402',0,'15020867'),('bmBlock3_403',0,'15020887'),('bmBlock3_404',0,'15020907'),('bmBlock3_405',0,'15020927'),('bmBlock3_406',0,'15020947'),('bmBlock3_407',0,'15020967'),('bmBlock3_408',0,'15020987'),('bmBlock3_409',0,'15021007'),('bmBlock3_41',0,'14830907'),('bmBlock3_410',0,'15021027'),('bmBlock3_411',0,'15021047'),('bmBlock3_412',0,'15021067'),('bmBlock3_413',0,'15030827'),('bmBlock3_414',0,'15030837'),('bmBlock3_415',0,'15030847'),('bmBlock3_416',0,'15030857'),('bmBlock3_417',0,'15030867'),('bmBlock3_418',0,'15030877'),('bmBlock3_419',0,'15030887'),('bmBlock3_42',0,'14830917'),('bmBlock3_420',0,'15030897'),('bmBlock3_421',0,'15030907'),('bmBlock3_422',0,'15030917'),('bmBlock3_423',0,'15030927'),('bmBlock3_424',0,'15030937'),('bmBlock3_425',0,'15030947'),('bmBlock3_426',0,'15030957'),('bmBlock3_427',0,'15030967'),('bmBlock3_428',0,'15030977'),('bmBlock3_429',0,'15030987'),('bmBlock3_43',0,'14830927'),('bmBlock3_430',0,'15030997'),('bmBlock3_431',0,'15031007'),('bmBlock3_432',0,'15031017'),('bmBlock3_433',0,'15031027'),('bmBlock3_434',0,'15031037'),('bmBlock3_435',0,'15031047'),('bmBlock3_436',0,'15031057'),('bmBlock3_437',0,'15031067'),('bmBlock3_438',0,'15040827'),('bmBlock3_439',0,'15040847'),('bmBlock3_44',0,'14830937'),('bmBlock3_440',0,'15040867'),('bmBlock3_441',0,'15040887'),('bmBlock3_442',0,'15040907'),('bmBlock3_443',0,'15040927'),('bmBlock3_444',0,'15040947'),('bmBlock3_445',0,'15040967'),('bmBlock3_446',0,'15040987'),('bmBlock3_447',0,'15041007'),('bmBlock3_448',0,'15041027'),('bmBlock3_449',0,'15041047'),('bmBlock3_45',0,'14830947'),('bmBlock3_450',0,'15041067'),('bmBlock3_451',0,'15050827'),('bmBlock3_452',0,'15050837'),('bmBlock3_453',0,'15050847'),('bmBlock3_454',0,'15050857'),('bmBlock3_455',0,'15050867'),('bmBlock3_456',0,'15050877'),('bmBlock3_457',0,'15050887'),('bmBlock3_458',0,'15050897'),('bmBlock3_459',0,'15050907'),('bmBlock3_46',0,'14830957'),('bmBlock3_460',0,'15050917'),('bmBlock3_461',0,'15050927'),('bmBlock3_462',0,'15050937'),('bmBlock3_463',0,'15050947'),('bmBlock3_464',0,'15050957'),('bmBlock3_465',0,'15050967'),('bmBlock3_466',0,'15050977'),('bmBlock3_467',0,'15050987'),('bmBlock3_468',0,'15050997'),('bmBlock3_469',0,'15051007'),('bmBlock3_47',0,'14830967'),('bmBlock3_470',0,'15051017'),('bmBlock3_471',0,'15051027'),('bmBlock3_472',0,'15051037'),('bmBlock3_473',0,'15051047'),('bmBlock3_474',0,'15051057'),('bmBlock3_475',0,'15051067'),('bmBlock3_476',0,'15060827'),('bmBlock3_477',0,'15060847'),('bmBlock3_478',0,'15060867'),('bmBlock3_479',0,'15060887'),('bmBlock3_48',0,'14830977'),('bmBlock3_480',0,'15060907'),('bmBlock3_481',0,'15060927'),('bmBlock3_482',0,'15060947'),('bmBlock3_483',0,'15060967'),('bmBlock3_484',0,'15060987'),('bmBlock3_485',0,'15061007'),('bmBlock3_486',0,'15061027'),('bmBlock3_487',0,'15061047'),('bmBlock3_488',0,'15061067'),('bmBlock3_489',0,'15070847'),('bmBlock3_49',0,'14830987'),('bmBlock3_490',0,'15070857'),('bmBlock3_491',0,'15070867'),('bmBlock3_492',0,'15070877'),('bmBlock3_493',0,'15070887'),('bmBlock3_494',0,'15070897'),('bmBlock3_495',0,'15070907'),('bmBlock3_496',0,'15070917'),('bmBlock3_497',0,'15070927'),('bmBlock3_498',0,'15070937'),('bmBlock3_499',0,'15070947'),('bmBlock3_5',0,'14810887'),('bmBlock3_50',0,'14830997'),('bmBlock3_500',0,'15070957'),('bmBlock3_501',0,'15070967'),('bmBlock3_502',0,'15070977'),('bmBlock3_503',0,'15070987'),('bmBlock3_504',0,'15070997'),('bmBlock3_505',0,'15071007'),('bmBlock3_506',0,'15071017'),('bmBlock3_507',0,'15071027'),('bmBlock3_508',0,'15071037'),('bmBlock3_509',0,'15071047'),('bmBlock3_51',0,'14831007'),('bmBlock3_510',0,'15080847'),('bmBlock3_511',0,'15080867'),('bmBlock3_512',0,'15080887'),('bmBlock3_513',0,'15080907'),('bmBlock3_514',0,'15080927'),('bmBlock3_515',0,'15080947'),('bmBlock3_516',0,'15080967'),('bmBlock3_517',0,'15080987'),('bmBlock3_518',0,'15081007'),('bmBlock3_519',0,'15081027'),('bmBlock3_52',0,'14831017'),('bmBlock3_520',0,'15081047'),('bmBlock3_53',0,'14831027'),('bmBlock3_54',0,'14831037'),('bmBlock3_55',0,'14831047'),('bmBlock3_56',0,'14831057'),('bmBlock3_57',0,'14831067'),('bmBlock3_58',0,'14840827'),('bmBlock3_59',0,'14840847'),('bmBlock3_6',0,'14810897'),('bmBlock3_60',0,'14840867'),('bmBlock3_61',0,'14840887'),('bmBlock3_62',0,'14840907'),('bmBlock3_63',0,'14840927'),('bmBlock3_64',0,'14840947'),('bmBlock3_65',0,'14840967'),('bmBlock3_66',0,'14840987'),('bmBlock3_67',0,'14841007'),('bmBlock3_68',0,'14841027'),('bmBlock3_69',0,'14841047'),('bmBlock3_7',0,'14810907'),('bmBlock3_70',0,'14841067'),('bmBlock3_71',0,'14850827'),('bmBlock3_72',0,'14850837'),('bmBlock3_73',0,'14850847'),('bmBlock3_74',0,'14850857'),('bmBlock3_75',0,'14850867'),('bmBlock3_76',0,'14850877'),('bmBlock3_77',0,'14850887'),('bmBlock3_78',0,'14850897'),('bmBlock3_79',0,'14850907'),('bmBlock3_8',0,'14810917'),('bmBlock3_80',0,'14850917'),('bmBlock3_81',0,'14850927'),('bmBlock3_82',0,'14850937'),('bmBlock3_83',0,'14850947'),('bmBlock3_84',0,'14850957'),('bmBlock3_85',0,'14850967'),('bmBlock3_86',0,'14850977'),('bmBlock3_87',0,'14850987'),('bmBlock3_88',0,'14850997'),('bmBlock3_89',0,'14851007'),('bmBlock3_9',0,'14810927'),('bmBlock3_90',0,'14851017'),('bmBlock3_91',0,'14851027'),('bmBlock3_92',0,'14851037'),('bmBlock3_93',0,'14851047'),('bmBlock3_94',0,'14851057'),('bmBlock3_95',0,'14851067'),('bmBlock3_96',0,'14860827'),('bmBlock3_97',0,'14860847'),('bmBlock3_98',0,'14860867'),('bmBlock3_99',0,'14860887'),('bmBlock4_1',0,'15470857'),('bmBlock4_10',0,'15470947'),('bmBlock4_100',0,'15520917'),('bmBlock4_101',0,'15520937'),('bmBlock4_102',0,'15520957'),('bmBlock4_103',0,'15520977'),('bmBlock4_104',0,'15520997'),('bmBlock4_105',0,'15521017'),('bmBlock4_106',0,'15521037'),('bmBlock4_107',0,'15521057'),('bmBlock4_108',0,'15521077'),('bmBlock4_109',0,'15530837'),('bmBlock4_11',0,'15470957'),('bmBlock4_110',0,'15530847'),('bmBlock4_111',0,'15530857'),('bmBlock4_112',0,'15530867'),('bmBlock4_113',0,'15530877'),('bmBlock4_114',0,'15530887'),('bmBlock4_115',0,'15530897'),('bmBlock4_116',0,'15530907'),('bmBlock4_117',0,'15530917'),('bmBlock4_118',0,'15530927'),('bmBlock4_119',0,'15530937'),('bmBlock4_12',0,'15470967'),('bmBlock4_120',0,'15530947'),('bmBlock4_121',0,'15530957'),('bmBlock4_122',0,'15530967'),('bmBlock4_123',0,'15530977'),('bmBlock4_124',0,'15530987'),('bmBlock4_125',0,'15530997'),('bmBlock4_126',0,'15531007'),('bmBlock4_127',0,'15531017'),('bmBlock4_128',0,'15531027'),('bmBlock4_129',0,'15531037'),('bmBlock4_13',0,'15470977'),('bmBlock4_130',0,'15531047'),('bmBlock4_131',0,'15531057'),('bmBlock4_132',0,'15531067'),('bmBlock4_133',0,'15531077'),('bmBlock4_134',0,'15540837'),('bmBlock4_135',0,'15540857'),('bmBlock4_136',0,'15540877'),('bmBlock4_137',0,'15540897'),('bmBlock4_138',0,'15540917'),('bmBlock4_139',0,'15540937'),('bmBlock4_14',0,'15470987'),('bmBlock4_140',0,'15540957'),('bmBlock4_141',0,'15540977'),('bmBlock4_142',0,'15540997'),('bmBlock4_143',0,'15541017'),('bmBlock4_144',0,'15541037'),('bmBlock4_145',0,'15541057'),('bmBlock4_146',0,'15541077'),('bmBlock4_147',0,'15550837'),('bmBlock4_148',0,'15550847'),('bmBlock4_149',0,'15550857'),('bmBlock4_15',0,'15470997'),('bmBlock4_150',0,'15550867'),('bmBlock4_151',0,'15550877'),('bmBlock4_152',0,'15550887'),('bmBlock4_153',0,'15550897'),('bmBlock4_154',0,'15550907'),('bmBlock4_155',0,'15550917'),('bmBlock4_156',0,'15550927'),('bmBlock4_157',0,'15550937'),('bmBlock4_158',0,'15550947'),('bmBlock4_159',0,'15550957'),('bmBlock4_16',0,'15471007'),('bmBlock4_160',0,'15550967'),('bmBlock4_161',0,'15550977'),('bmBlock4_162',0,'15550987'),('bmBlock4_163',0,'15550997'),('bmBlock4_164',0,'15551007'),('bmBlock4_165',0,'15551017'),('bmBlock4_166',0,'15551027'),('bmBlock4_167',0,'15551037'),('bmBlock4_168',0,'15551047'),('bmBlock4_169',0,'15551057'),('bmBlock4_17',0,'15471017'),('bmBlock4_170',0,'15551067'),('bmBlock4_171',0,'15551077'),('bmBlock4_172',0,'15560837'),('bmBlock4_173',0,'15560857'),('bmBlock4_174',0,'15560877'),('bmBlock4_175',0,'15560897'),('bmBlock4_176',0,'15560917'),('bmBlock4_177',0,'15560937'),('bmBlock4_178',0,'15560957'),('bmBlock4_179',0,'15560977'),('bmBlock4_18',0,'15471027'),('bmBlock4_180',0,'15560997'),('bmBlock4_181',0,'15561017'),('bmBlock4_182',0,'15561037'),('bmBlock4_183',0,'15561057'),('bmBlock4_184',0,'15561077'),('bmBlock4_185',0,'15570837'),('bmBlock4_186',0,'15570847'),('bmBlock4_187',0,'15570857'),('bmBlock4_188',0,'15570867'),('bmBlock4_189',0,'15570877'),('bmBlock4_19',0,'15471037'),('bmBlock4_190',0,'15570887'),('bmBlock4_191',0,'15570897'),('bmBlock4_192',0,'15570907'),('bmBlock4_193',0,'15570917'),('bmBlock4_194',0,'15570927'),('bmBlock4_195',0,'15570937'),('bmBlock4_196',0,'15570947'),('bmBlock4_197',0,'15570957'),('bmBlock4_198',0,'15570967'),('bmBlock4_199',0,'15570977'),('bmBlock4_2',0,'15470867'),('bmBlock4_20',0,'15471047'),('bmBlock4_200',0,'15570987'),('bmBlock4_201',0,'15570997'),('bmBlock4_202',0,'15571007'),('bmBlock4_203',0,'15571017'),('bmBlock4_204',0,'15571027'),('bmBlock4_205',0,'15571037'),('bmBlock4_206',0,'15571047'),('bmBlock4_207',0,'15571057'),('bmBlock4_208',0,'15571067'),('bmBlock4_209',0,'15571077'),('bmBlock4_21',0,'15471057'),('bmBlock4_210',0,'15580837'),('bmBlock4_211',0,'15580857'),('bmBlock4_212',0,'15580877'),('bmBlock4_213',0,'15580897'),('bmBlock4_214',0,'15580917'),('bmBlock4_215',0,'15580937'),('bmBlock4_216',0,'15580957'),('bmBlock4_217',0,'15580977'),('bmBlock4_218',0,'15580997'),('bmBlock4_219',0,'15581017'),('bmBlock4_22',0,'15480857'),('bmBlock4_220',0,'15581037'),('bmBlock4_221',0,'15581057'),('bmBlock4_222',0,'15581077'),('bmBlock4_223',0,'15590837'),('bmBlock4_224',0,'15590847'),('bmBlock4_225',0,'15590857'),('bmBlock4_226',0,'15590867'),('bmBlock4_227',0,'15590877'),('bmBlock4_228',0,'15590887'),('bmBlock4_229',0,'15590897'),('bmBlock4_23',0,'15480877'),('bmBlock4_230',0,'15590907'),('bmBlock4_231',0,'15590917'),('bmBlock4_232',0,'15590927'),('bmBlock4_233',0,'15590937'),('bmBlock4_234',0,'15590947'),('bmBlock4_235',0,'15590957'),('bmBlock4_236',0,'15590967'),('bmBlock4_237',0,'15590977'),('bmBlock4_238',0,'15590987'),('bmBlock4_239',0,'15590997'),('bmBlock4_24',0,'15480897'),('bmBlock4_240',0,'15591007'),('bmBlock4_241',0,'15591017'),('bmBlock4_242',0,'15591027'),('bmBlock4_243',0,'15591037'),('bmBlock4_244',0,'15591047'),('bmBlock4_245',0,'15591057'),('bmBlock4_246',0,'15591067'),('bmBlock4_247',0,'15591077'),('bmBlock4_248',0,'15600837'),('bmBlock4_249',0,'15600857'),('bmBlock4_25',0,'15480917'),('bmBlock4_250',0,'15600877'),('bmBlock4_251',0,'15600897'),('bmBlock4_252',0,'15600917'),('bmBlock4_253',0,'15600937'),('bmBlock4_254',0,'15600957'),('bmBlock4_255',0,'15600977'),('bmBlock4_256',0,'15600997'),('bmBlock4_257',0,'15601017'),('bmBlock4_258',0,'15601037'),('bmBlock4_259',0,'15601057'),('bmBlock4_26',0,'15480937'),('bmBlock4_260',0,'15601077'),('bmBlock4_261',0,'15610837'),('bmBlock4_262',0,'15610847'),('bmBlock4_263',0,'15610857'),('bmBlock4_264',0,'15610867'),('bmBlock4_265',0,'15610877'),('bmBlock4_266',0,'15610887'),('bmBlock4_267',0,'15610897'),('bmBlock4_268',0,'15610907'),('bmBlock4_269',0,'15610917'),('bmBlock4_27',0,'15480957'),('bmBlock4_270',0,'15610927'),('bmBlock4_271',0,'15610937'),('bmBlock4_272',0,'15610947'),('bmBlock4_273',0,'15610957'),('bmBlock4_274',0,'15610967'),('bmBlock4_275',0,'15610977'),('bmBlock4_276',0,'15610987'),('bmBlock4_277',0,'15610997'),('bmBlock4_278',0,'15611007'),('bmBlock4_279',0,'15611017'),('bmBlock4_28',0,'15480977'),('bmBlock4_280',0,'15611027'),('bmBlock4_281',0,'15611037'),('bmBlock4_282',0,'15611047'),('bmBlock4_283',0,'15611057'),('bmBlock4_284',0,'15611067'),('bmBlock4_285',0,'15611077'),('bmBlock4_286',0,'15620837'),('bmBlock4_287',0,'15620857'),('bmBlock4_288',0,'15620877'),('bmBlock4_289',0,'15620897'),('bmBlock4_29',0,'15480997'),('bmBlock4_290',0,'15620917'),('bmBlock4_291',0,'15620937'),('bmBlock4_292',0,'15620957'),('bmBlock4_293',0,'15620977'),('bmBlock4_294',0,'15620997'),('bmBlock4_295',0,'15621017'),('bmBlock4_296',0,'15621037'),('bmBlock4_297',0,'15621057'),('bmBlock4_298',0,'15621077'),('bmBlock4_299',0,'15630837'),('bmBlock4_3',0,'15470877'),('bmBlock4_30',0,'15481017'),('bmBlock4_300',0,'15630847'),('bmBlock4_301',0,'15630857'),('bmBlock4_302',0,'15630867'),('bmBlock4_303',0,'15630877'),('bmBlock4_304',0,'15630887'),('bmBlock4_305',0,'15630897'),('bmBlock4_306',0,'15630907'),('bmBlock4_307',0,'15630917'),('bmBlock4_308',0,'15630927'),('bmBlock4_309',0,'15630937'),('bmBlock4_31',0,'15481037'),('bmBlock4_310',0,'15630947'),('bmBlock4_311',0,'15630957'),('bmBlock4_312',0,'15630967'),('bmBlock4_313',0,'15630977'),('bmBlock4_314',0,'15630987'),('bmBlock4_315',0,'15630997'),('bmBlock4_316',0,'15631007'),('bmBlock4_317',0,'15631017'),('bmBlock4_318',0,'15631027'),('bmBlock4_319',0,'15631037'),('bmBlock4_32',0,'15481057'),('bmBlock4_320',0,'15631047'),('bmBlock4_321',0,'15631057'),('bmBlock4_322',0,'15631067'),('bmBlock4_323',0,'15631077'),('bmBlock4_324',0,'15640837'),('bmBlock4_325',0,'15640857'),('bmBlock4_326',0,'15640877'),('bmBlock4_327',0,'15640897'),('bmBlock4_328',0,'15640917'),('bmBlock4_329',0,'15640937'),('bmBlock4_33',0,'15490837'),('bmBlock4_330',0,'15640957'),('bmBlock4_331',0,'15640977'),('bmBlock4_332',0,'15640997'),('bmBlock4_333',0,'15641017'),('bmBlock4_334',0,'15641037'),('bmBlock4_335',0,'15641057'),('bmBlock4_336',0,'15641077'),('bmBlock4_337',0,'15650837'),('bmBlock4_338',0,'15650847'),('bmBlock4_339',0,'15650857'),('bmBlock4_34',0,'15490847'),('bmBlock4_340',0,'15650867'),('bmBlock4_341',0,'15650877'),('bmBlock4_342',0,'15650887'),('bmBlock4_343',0,'15650897'),('bmBlock4_344',0,'15650907'),('bmBlock4_345',0,'15650917'),('bmBlock4_346',0,'15650927'),('bmBlock4_347',0,'15650937'),('bmBlock4_348',0,'15650947'),('bmBlock4_349',0,'15650957'),('bmBlock4_35',0,'15490857'),('bmBlock4_350',0,'15650967'),('bmBlock4_351',0,'15650977'),('bmBlock4_352',0,'15650987'),('bmBlock4_353',0,'15650997'),('bmBlock4_354',0,'15651007'),('bmBlock4_355',0,'15651017'),('bmBlock4_356',0,'15651027'),('bmBlock4_357',0,'15651037'),('bmBlock4_358',0,'15651047'),('bmBlock4_359',0,'15651057'),('bmBlock4_36',0,'15490867'),('bmBlock4_360',0,'15651067'),('bmBlock4_361',0,'15651077'),('bmBlock4_362',0,'15660837'),('bmBlock4_363',0,'15660857'),('bmBlock4_364',0,'15660877'),('bmBlock4_365',0,'15660897'),('bmBlock4_366',0,'15660917'),('bmBlock4_367',0,'15660937'),('bmBlock4_368',0,'15660957'),('bmBlock4_369',0,'15660977'),('bmBlock4_37',0,'15490877'),('bmBlock4_370',0,'15660997'),('bmBlock4_371',0,'15661017'),('bmBlock4_372',0,'15661037'),('bmBlock4_373',0,'15661057'),('bmBlock4_374',0,'15661077'),('bmBlock4_375',0,'15670837'),('bmBlock4_376',0,'15670847'),('bmBlock4_377',0,'15670857'),('bmBlock4_378',0,'15670867'),('bmBlock4_379',0,'15670877'),('bmBlock4_38',0,'15490887'),('bmBlock4_380',0,'15670887'),('bmBlock4_381',0,'15670897'),('bmBlock4_382',0,'15670907'),('bmBlock4_383',0,'15670917'),('bmBlock4_384',0,'15670927'),('bmBlock4_385',0,'15670937'),('bmBlock4_386',0,'15670947'),('bmBlock4_387',0,'15670957'),('bmBlock4_388',0,'15670967'),('bmBlock4_389',0,'15670977'),('bmBlock4_39',0,'15490897'),('bmBlock4_390',0,'15670987'),('bmBlock4_391',0,'15670997'),('bmBlock4_392',0,'15671007'),('bmBlock4_393',0,'15671017'),('bmBlock4_394',0,'15671027'),('bmBlock4_395',0,'15671037'),('bmBlock4_396',0,'15671047'),('bmBlock4_397',0,'15671057'),('bmBlock4_398',0,'15671067'),('bmBlock4_399',0,'15671077'),('bmBlock4_4',0,'15470887'),('bmBlock4_40',0,'15490907'),('bmBlock4_400',0,'15680837'),('bmBlock4_401',0,'15680857'),('bmBlock4_402',0,'15680877'),('bmBlock4_403',0,'15680897'),('bmBlock4_404',0,'15680917'),('bmBlock4_405',0,'15680937'),('bmBlock4_406',0,'15680957'),('bmBlock4_407',0,'15680977'),('bmBlock4_408',0,'15680997'),('bmBlock4_409',0,'15681017'),('bmBlock4_41',0,'15490917'),('bmBlock4_410',0,'15681037'),('bmBlock4_411',0,'15681057'),('bmBlock4_412',0,'15681077'),('bmBlock4_413',0,'15690837'),('bmBlock4_414',0,'15690847'),('bmBlock4_415',0,'15690857'),('bmBlock4_416',0,'15690867'),('bmBlock4_417',0,'15690877'),('bmBlock4_418',0,'15690887'),('bmBlock4_419',0,'15690897'),('bmBlock4_42',0,'15490927'),('bmBlock4_420',0,'15690907'),('bmBlock4_421',0,'15690917'),('bmBlock4_422',0,'15690927'),('bmBlock4_423',0,'15690937'),('bmBlock4_424',0,'15690947'),('bmBlock4_425',0,'15690957'),('bmBlock4_426',0,'15690967'),('bmBlock4_427',0,'15690977'),('bmBlock4_428',0,'15690987'),('bmBlock4_429',0,'15690997'),('bmBlock4_43',0,'15490937'),('bmBlock4_430',0,'15691007'),('bmBlock4_431',0,'15691017'),('bmBlock4_432',0,'15691027'),('bmBlock4_433',0,'15691037'),('bmBlock4_434',0,'15691047'),('bmBlock4_435',0,'15691057'),('bmBlock4_436',0,'15691067'),('bmBlock4_437',0,'15691077'),('bmBlock4_438',0,'15700837'),('bmBlock4_439',0,'15700857'),('bmBlock4_44',0,'15490947'),('bmBlock4_440',0,'15700877'),('bmBlock4_441',0,'15700897'),('bmBlock4_442',0,'15700917'),('bmBlock4_443',0,'15700937'),('bmBlock4_444',0,'15700957'),('bmBlock4_445',0,'15700977'),('bmBlock4_446',0,'15700997'),('bmBlock4_447',0,'15701017'),('bmBlock4_448',0,'15701037'),('bmBlock4_449',0,'15701057'),('bmBlock4_45',0,'15490957'),('bmBlock4_450',0,'15701077'),('bmBlock4_451',0,'15710837'),('bmBlock4_452',0,'15710847'),('bmBlock4_453',0,'15710857'),('bmBlock4_454',0,'15710867'),('bmBlock4_455',0,'15710877'),('bmBlock4_456',0,'15710887'),('bmBlock4_457',0,'15710897'),('bmBlock4_458',0,'15710907'),('bmBlock4_459',0,'15710917'),('bmBlock4_46',0,'15490967'),('bmBlock4_460',0,'15710927'),('bmBlock4_461',0,'15710937'),('bmBlock4_462',0,'15710947'),('bmBlock4_463',0,'15710957'),('bmBlock4_464',0,'15710967'),('bmBlock4_465',0,'15710977'),('bmBlock4_466',0,'15710987'),('bmBlock4_467',0,'15710997'),('bmBlock4_468',0,'15711007'),('bmBlock4_469',0,'15711017'),('bmBlock4_47',0,'15490977'),('bmBlock4_470',0,'15711027'),('bmBlock4_471',0,'15711037'),('bmBlock4_472',0,'15711047'),('bmBlock4_473',0,'15711057'),('bmBlock4_474',0,'15711067'),('bmBlock4_475',0,'15711077'),('bmBlock4_476',0,'15720837'),('bmBlock4_477',0,'15720857'),('bmBlock4_478',0,'15720877'),('bmBlock4_479',0,'15720897'),('bmBlock4_48',0,'15490987'),('bmBlock4_480',0,'15720917'),('bmBlock4_481',0,'15720937'),('bmBlock4_482',0,'15720957'),('bmBlock4_483',0,'15720977'),('bmBlock4_484',0,'15720997'),('bmBlock4_485',0,'15721017'),('bmBlock4_486',0,'15721037'),('bmBlock4_487',0,'15721057'),('bmBlock4_488',0,'15721077'),('bmBlock4_489',0,'15730857'),('bmBlock4_49',0,'15490997'),('bmBlock4_490',0,'15730867'),('bmBlock4_491',0,'15730877'),('bmBlock4_492',0,'15730887'),('bmBlock4_493',0,'15730897'),('bmBlock4_494',0,'15730907'),('bmBlock4_495',0,'15730917'),('bmBlock4_496',0,'15730927'),('bmBlock4_497',0,'15730937'),('bmBlock4_498',0,'15730947'),('bmBlock4_499',0,'15730957'),('bmBlock4_5',0,'15470897'),('bmBlock4_50',0,'15491007'),('bmBlock4_500',0,'15730967'),('bmBlock4_501',0,'15730977'),('bmBlock4_502',0,'15730987'),('bmBlock4_503',0,'15730997'),('bmBlock4_504',0,'15731007'),('bmBlock4_505',0,'15731017'),('bmBlock4_506',0,'15731027'),('bmBlock4_507',0,'15731037'),('bmBlock4_508',0,'15731047'),('bmBlock4_509',0,'15731057'),('bmBlock4_51',0,'15491017'),('bmBlock4_510',0,'15740857'),('bmBlock4_511',0,'15740877'),('bmBlock4_512',0,'15740897'),('bmBlock4_513',0,'15740917'),('bmBlock4_514',0,'15740937'),('bmBlock4_515',0,'15740957'),('bmBlock4_516',0,'15740977'),('bmBlock4_517',0,'15740997'),('bmBlock4_518',0,'15741017'),('bmBlock4_519',0,'15741037'),('bmBlock4_52',0,'15491027'),('bmBlock4_520',0,'15741057'),('bmBlock4_53',0,'15491037'),('bmBlock4_54',0,'15491047'),('bmBlock4_55',0,'15491057'),('bmBlock4_56',0,'15491067'),('bmBlock4_57',0,'15491077'),('bmBlock4_58',0,'15500837'),('bmBlock4_59',0,'15500857'),('bmBlock4_6',0,'15470907'),('bmBlock4_60',0,'15500877'),('bmBlock4_61',0,'15500897'),('bmBlock4_62',0,'15500917'),('bmBlock4_63',0,'15500937'),('bmBlock4_64',0,'15500957'),('bmBlock4_65',0,'15500977'),('bmBlock4_66',0,'15500997'),('bmBlock4_67',0,'15501017'),('bmBlock4_68',0,'15501037'),('bmBlock4_69',0,'15501057'),('bmBlock4_7',0,'15470917'),('bmBlock4_70',0,'15501077'),('bmBlock4_71',0,'15510837'),('bmBlock4_72',0,'15510847'),('bmBlock4_73',0,'15510857'),('bmBlock4_74',0,'15510867'),('bmBlock4_75',0,'15510877'),('bmBlock4_76',0,'15510887'),('bmBlock4_77',0,'15510897'),('bmBlock4_78',0,'15510907'),('bmBlock4_79',0,'15510917'),('bmBlock4_8',0,'15470927'),('bmBlock4_80',0,'15510927'),('bmBlock4_81',0,'15510937'),('bmBlock4_82',0,'15510947'),('bmBlock4_83',0,'15510957'),('bmBlock4_84',0,'15510967'),('bmBlock4_85',0,'15510977'),('bmBlock4_86',0,'15510987'),('bmBlock4_87',0,'15510997'),('bmBlock4_88',0,'15511007'),('bmBlock4_89',0,'15511017'),('bmBlock4_9',0,'15470937'),('bmBlock4_90',0,'15511027'),('bmBlock4_91',0,'15511037'),('bmBlock4_92',0,'15511047'),('bmBlock4_93',0,'15511057'),('bmBlock4_94',0,'15511067'),('bmBlock4_95',0,'15511077'),('bmBlock4_96',0,'15520837'),('bmBlock4_97',0,'15520857'),('bmBlock4_98',0,'15520877'),('bmBlock4_99',0,'15520897'),('bmBlock5_1',0,'14821397'),('bmBlock5_10',0,'14821487'),('bmBlock5_100',0,'14871457'),('bmBlock5_101',0,'14871477'),('bmBlock5_102',0,'14871497'),('bmBlock5_103',0,'14871517'),('bmBlock5_104',0,'14871537'),('bmBlock5_105',0,'14871557'),('bmBlock5_106',0,'14871577'),('bmBlock5_107',0,'14871597'),('bmBlock5_108',0,'14871617'),('bmBlock5_109',0,'14881377'),('bmBlock5_11',0,'14821497'),('bmBlock5_110',0,'14881387'),('bmBlock5_111',0,'14881397'),('bmBlock5_112',0,'14881407'),('bmBlock5_113',0,'14881417'),('bmBlock5_114',0,'14881427'),('bmBlock5_115',0,'14881437'),('bmBlock5_116',0,'14881447'),('bmBlock5_117',0,'14881457'),('bmBlock5_118',0,'14881467'),('bmBlock5_119',0,'14881477'),('bmBlock5_12',0,'14821507'),('bmBlock5_120',0,'14881487'),('bmBlock5_121',0,'14881497'),('bmBlock5_122',0,'14881507'),('bmBlock5_123',0,'14881517'),('bmBlock5_124',0,'14881527'),('bmBlock5_125',0,'14881537'),('bmBlock5_126',0,'14881547'),('bmBlock5_127',0,'14881557'),('bmBlock5_128',0,'14881567'),('bmBlock5_129',0,'14881577'),('bmBlock5_13',0,'14821517'),('bmBlock5_130',0,'14881587'),('bmBlock5_131',0,'14881597'),('bmBlock5_132',0,'14881607'),('bmBlock5_133',0,'14881617'),('bmBlock5_134',0,'14891377'),('bmBlock5_135',0,'14891397'),('bmBlock5_136',0,'14891417'),('bmBlock5_137',0,'14891437'),('bmBlock5_138',0,'14891457'),('bmBlock5_139',0,'14891477'),('bmBlock5_14',0,'14821527'),('bmBlock5_140',0,'14891497'),('bmBlock5_141',0,'14891517'),('bmBlock5_142',0,'14891537'),('bmBlock5_143',0,'14891557'),('bmBlock5_144',0,'14891577'),('bmBlock5_145',0,'14891597'),('bmBlock5_146',0,'14891617'),('bmBlock5_147',0,'14901377'),('bmBlock5_148',0,'14901387'),('bmBlock5_149',0,'14901397'),('bmBlock5_15',0,'14821537'),('bmBlock5_150',0,'14901407'),('bmBlock5_151',0,'14901417'),('bmBlock5_152',0,'14901427'),('bmBlock5_153',0,'14901437'),('bmBlock5_154',0,'14901447'),('bmBlock5_155',0,'14901457'),('bmBlock5_156',0,'14901467'),('bmBlock5_157',0,'14901477'),('bmBlock5_158',0,'14901487'),('bmBlock5_159',0,'14901497'),('bmBlock5_16',0,'14821547'),('bmBlock5_160',0,'14901507'),('bmBlock5_161',0,'14901517'),('bmBlock5_162',0,'14901527'),('bmBlock5_163',0,'14901537'),('bmBlock5_164',0,'14901547'),('bmBlock5_165',0,'14901557'),('bmBlock5_166',0,'14901567'),('bmBlock5_167',0,'14901577'),('bmBlock5_168',0,'14901587'),('bmBlock5_169',0,'14901597'),('bmBlock5_17',0,'14821557'),('bmBlock5_170',0,'14901607'),('bmBlock5_171',0,'14901617'),('bmBlock5_172',0,'14911377'),('bmBlock5_173',0,'14911397'),('bmBlock5_174',0,'14911417'),('bmBlock5_175',0,'14911437'),('bmBlock5_176',0,'14911457'),('bmBlock5_177',0,'14911477'),('bmBlock5_178',0,'14911497'),('bmBlock5_179',0,'14911517'),('bmBlock5_18',0,'14821567'),('bmBlock5_180',0,'14911537'),('bmBlock5_181',0,'14911557'),('bmBlock5_182',0,'14911577'),('bmBlock5_183',0,'14911597'),('bmBlock5_184',0,'14911617'),('bmBlock5_185',0,'14921377'),('bmBlock5_186',0,'14921387'),('bmBlock5_187',0,'14921397'),('bmBlock5_188',0,'14921407'),('bmBlock5_189',0,'14921417'),('bmBlock5_19',0,'14821577'),('bmBlock5_190',0,'14921427'),('bmBlock5_191',0,'14921437'),('bmBlock5_192',0,'14921447'),('bmBlock5_193',0,'14921457'),('bmBlock5_194',0,'14921467'),('bmBlock5_195',0,'14921477'),('bmBlock5_196',0,'14921487'),('bmBlock5_197',0,'14921497'),('bmBlock5_198',0,'14921507'),('bmBlock5_199',0,'14921517'),('bmBlock5_2',0,'14821407'),('bmBlock5_20',0,'14821587'),('bmBlock5_200',0,'14921527'),('bmBlock5_201',0,'14921537'),('bmBlock5_202',0,'14921547'),('bmBlock5_203',0,'14921557'),('bmBlock5_204',0,'14921567'),('bmBlock5_205',0,'14921577'),('bmBlock5_206',0,'14921587'),('bmBlock5_207',0,'14921597'),('bmBlock5_208',0,'14921607'),('bmBlock5_209',0,'14921617'),('bmBlock5_21',0,'14821597'),('bmBlock5_210',0,'14931377'),('bmBlock5_211',0,'14931397'),('bmBlock5_212',0,'14931417'),('bmBlock5_213',0,'14931437'),('bmBlock5_214',0,'14931457'),('bmBlock5_215',0,'14931477'),('bmBlock5_216',0,'14931497'),('bmBlock5_217',0,'14931517'),('bmBlock5_218',0,'14931537'),('bmBlock5_219',0,'14931557'),('bmBlock5_22',0,'14831397'),('bmBlock5_220',0,'14931577'),('bmBlock5_221',0,'14931597'),('bmBlock5_222',0,'14931617'),('bmBlock5_223',0,'14941377'),('bmBlock5_224',0,'14941387'),('bmBlock5_225',0,'14941397'),('bmBlock5_226',0,'14941407'),('bmBlock5_227',0,'14941417'),('bmBlock5_228',0,'14941427'),('bmBlock5_229',0,'14941437'),('bmBlock5_23',0,'14831417'),('bmBlock5_230',0,'14941447'),('bmBlock5_231',0,'14941457'),('bmBlock5_232',0,'14941467'),('bmBlock5_233',0,'14941477'),('bmBlock5_234',0,'14941487'),('bmBlock5_235',0,'14941497'),('bmBlock5_236',0,'14941507'),('bmBlock5_237',0,'14941517'),('bmBlock5_238',0,'14941527'),('bmBlock5_239',0,'14941537'),('bmBlock5_24',0,'14831437'),('bmBlock5_240',0,'14941547'),('bmBlock5_241',0,'14941557'),('bmBlock5_242',0,'14941567'),('bmBlock5_243',0,'14941577'),('bmBlock5_244',0,'14941587'),('bmBlock5_245',0,'14941597'),('bmBlock5_246',0,'14941607'),('bmBlock5_247',0,'14941617'),('bmBlock5_248',0,'14951377'),('bmBlock5_249',0,'14951397'),('bmBlock5_25',0,'14831457'),('bmBlock5_250',0,'14951417'),('bmBlock5_251',0,'14951437'),('bmBlock5_252',0,'14951457'),('bmBlock5_253',0,'14951477'),('bmBlock5_254',0,'14951497'),('bmBlock5_255',0,'14951517'),('bmBlock5_256',0,'14951537'),('bmBlock5_257',0,'14951557'),('bmBlock5_258',0,'14951577'),('bmBlock5_259',0,'14951597'),('bmBlock5_26',0,'14831477'),('bmBlock5_260',0,'14951617'),('bmBlock5_261',0,'14961377'),('bmBlock5_262',0,'14961387'),('bmBlock5_263',0,'14961397'),('bmBlock5_264',0,'14961407'),('bmBlock5_265',0,'14961417'),('bmBlock5_266',0,'14961427'),('bmBlock5_267',0,'14961437'),('bmBlock5_268',0,'14961447'),('bmBlock5_269',0,'14961457'),('bmBlock5_27',0,'14831497'),('bmBlock5_270',0,'14961467'),('bmBlock5_271',0,'14961477'),('bmBlock5_272',0,'14961487'),('bmBlock5_273',0,'14961497'),('bmBlock5_274',0,'14961507'),('bmBlock5_275',0,'14961517'),('bmBlock5_276',0,'14961527'),('bmBlock5_277',0,'14961537'),('bmBlock5_278',0,'14961547'),('bmBlock5_279',0,'14961557'),('bmBlock5_28',0,'14831517'),('bmBlock5_280',0,'14961567'),('bmBlock5_281',0,'14961577'),('bmBlock5_282',0,'14961587'),('bmBlock5_283',0,'14961597'),('bmBlock5_284',0,'14961607'),('bmBlock5_285',0,'14961617'),('bmBlock5_286',0,'14971377'),('bmBlock5_287',0,'14971397'),('bmBlock5_288',0,'14971417'),('bmBlock5_289',0,'14971437'),('bmBlock5_29',0,'14831537'),('bmBlock5_290',0,'14971457'),('bmBlock5_291',0,'14971477'),('bmBlock5_292',0,'14971497'),('bmBlock5_293',0,'14971517'),('bmBlock5_294',0,'14971537'),('bmBlock5_295',0,'14971557'),('bmBlock5_296',0,'14971577'),('bmBlock5_297',0,'14971597'),('bmBlock5_298',0,'14971617'),('bmBlock5_299',0,'14981377'),('bmBlock5_3',0,'14821417'),('bmBlock5_30',0,'14831557'),('bmBlock5_300',0,'14981387'),('bmBlock5_301',0,'14981397'),('bmBlock5_302',0,'14981407'),('bmBlock5_303',0,'14981417'),('bmBlock5_304',0,'14981427'),('bmBlock5_305',0,'14981437'),('bmBlock5_306',0,'14981447'),('bmBlock5_307',0,'14981457'),('bmBlock5_308',0,'14981467'),('bmBlock5_309',0,'14981477'),('bmBlock5_31',0,'14831577'),('bmBlock5_310',0,'14981487'),('bmBlock5_311',0,'14981497'),('bmBlock5_312',0,'14981507'),('bmBlock5_313',0,'14981517'),('bmBlock5_314',0,'14981527'),('bmBlock5_315',0,'14981537'),('bmBlock5_316',0,'14981547'),('bmBlock5_317',0,'14981557'),('bmBlock5_318',0,'14981567'),('bmBlock5_319',0,'14981577'),('bmBlock5_32',0,'14831597'),('bmBlock5_320',0,'14981587'),('bmBlock5_321',0,'14981597'),('bmBlock5_322',0,'14981607'),('bmBlock5_323',0,'14981617'),('bmBlock5_324',0,'14991377'),('bmBlock5_325',0,'14991397'),('bmBlock5_326',0,'14991417'),('bmBlock5_327',0,'14991437'),('bmBlock5_328',0,'14991457'),('bmBlock5_329',0,'14991477'),('bmBlock5_33',0,'14841377'),('bmBlock5_330',0,'14991497'),('bmBlock5_331',0,'14991517'),('bmBlock5_332',0,'14991537'),('bmBlock5_333',0,'14991557'),('bmBlock5_334',0,'14991577'),('bmBlock5_335',0,'14991597'),('bmBlock5_336',0,'14991617'),('bmBlock5_337',0,'15001377'),('bmBlock5_338',0,'15001387'),('bmBlock5_339',0,'15001397'),('bmBlock5_34',0,'14841387'),('bmBlock5_340',0,'15001407'),('bmBlock5_341',0,'15001417'),('bmBlock5_342',0,'15001427'),('bmBlock5_343',0,'15001437'),('bmBlock5_344',0,'15001447'),('bmBlock5_345',0,'15001457'),('bmBlock5_346',0,'15001467'),('bmBlock5_347',0,'15001477'),('bmBlock5_348',0,'15001487'),('bmBlock5_349',0,'15001497'),('bmBlock5_35',0,'14841397'),('bmBlock5_350',0,'15001507'),('bmBlock5_351',0,'15001517'),('bmBlock5_352',0,'15001527'),('bmBlock5_353',0,'15001537'),('bmBlock5_354',0,'15001547'),('bmBlock5_355',0,'15001557'),('bmBlock5_356',0,'15001567'),('bmBlock5_357',0,'15001577'),('bmBlock5_358',0,'15001587'),('bmBlock5_359',0,'15001597'),('bmBlock5_36',0,'14841407'),('bmBlock5_360',0,'15001607'),('bmBlock5_361',0,'15001617'),('bmBlock5_362',0,'15011377'),('bmBlock5_363',0,'15011397'),('bmBlock5_364',0,'15011417'),('bmBlock5_365',0,'15011437'),('bmBlock5_366',0,'15011457'),('bmBlock5_367',0,'15011477'),('bmBlock5_368',0,'15011497'),('bmBlock5_369',0,'15011517'),('bmBlock5_37',0,'14841417'),('bmBlock5_370',0,'15011537'),('bmBlock5_371',0,'15011557'),('bmBlock5_372',0,'15011577'),('bmBlock5_373',0,'15011597'),('bmBlock5_374',0,'15011617'),('bmBlock5_375',0,'15021377'),('bmBlock5_376',0,'15021387'),('bmBlock5_377',0,'15021397'),('bmBlock5_378',0,'15021407'),('bmBlock5_379',0,'15021417'),('bmBlock5_38',0,'14841427'),('bmBlock5_380',0,'15021427'),('bmBlock5_381',0,'15021437'),('bmBlock5_382',0,'15021447'),('bmBlock5_383',0,'15021457'),('bmBlock5_384',0,'15021467'),('bmBlock5_385',0,'15021477'),('bmBlock5_386',0,'15021487'),('bmBlock5_387',0,'15021497'),('bmBlock5_388',0,'15021507'),('bmBlock5_389',0,'15021517'),('bmBlock5_39',0,'14841437'),('bmBlock5_390',0,'15021527'),('bmBlock5_391',0,'15021537'),('bmBlock5_392',0,'15021547'),('bmBlock5_393',0,'15021557'),('bmBlock5_394',0,'15021567'),('bmBlock5_395',0,'15021577'),('bmBlock5_396',0,'15021587'),('bmBlock5_397',0,'15021597'),('bmBlock5_398',0,'15021607'),('bmBlock5_399',0,'15021617'),('bmBlock5_4',0,'14821427'),('bmBlock5_40',0,'14841447'),('bmBlock5_400',0,'15031377'),('bmBlock5_401',0,'15031397'),('bmBlock5_402',0,'15031417'),('bmBlock5_403',0,'15031437'),('bmBlock5_404',0,'15031457'),('bmBlock5_405',0,'15031477'),('bmBlock5_406',0,'15031497'),('bmBlock5_407',0,'15031517'),('bmBlock5_408',0,'15031537'),('bmBlock5_409',0,'15031557'),('bmBlock5_41',0,'14841457'),('bmBlock5_410',0,'15031577'),('bmBlock5_411',0,'15031597'),('bmBlock5_412',0,'15031617'),('bmBlock5_413',0,'15041377'),('bmBlock5_414',0,'15041387'),('bmBlock5_415',0,'15041397'),('bmBlock5_416',0,'15041407'),('bmBlock5_417',0,'15041417'),('bmBlock5_418',0,'15041427'),('bmBlock5_419',0,'15041437'),('bmBlock5_42',0,'14841467'),('bmBlock5_420',0,'15041447'),('bmBlock5_421',0,'15041457'),('bmBlock5_422',0,'15041467'),('bmBlock5_423',0,'15041477'),('bmBlock5_424',0,'15041487'),('bmBlock5_425',0,'15041497'),('bmBlock5_426',0,'15041507'),('bmBlock5_427',0,'15041517'),('bmBlock5_428',0,'15041527'),('bmBlock5_429',0,'15041537'),('bmBlock5_43',0,'14841477'),('bmBlock5_430',0,'15041547'),('bmBlock5_431',0,'15041557'),('bmBlock5_432',0,'15041567'),('bmBlock5_433',0,'15041577'),('bmBlock5_434',0,'15041587'),('bmBlock5_435',0,'15041597'),('bmBlock5_436',0,'15041607'),('bmBlock5_437',0,'15041617'),('bmBlock5_438',0,'15051377'),('bmBlock5_439',0,'15051397'),('bmBlock5_44',0,'14841487'),('bmBlock5_440',0,'15051417'),('bmBlock5_441',0,'15051437'),('bmBlock5_442',0,'15051457'),('bmBlock5_443',0,'15051477'),('bmBlock5_444',0,'15051497'),('bmBlock5_445',0,'15051517'),('bmBlock5_446',0,'15051537'),('bmBlock5_447',0,'15051557'),('bmBlock5_448',0,'15051577'),('bmBlock5_449',0,'15051597'),('bmBlock5_45',0,'14841497'),('bmBlock5_450',0,'15051617'),('bmBlock5_451',0,'15061377'),('bmBlock5_452',0,'15061387'),('bmBlock5_453',0,'15061397'),('bmBlock5_454',0,'15061407'),('bmBlock5_455',0,'15061417'),('bmBlock5_456',0,'15061427'),('bmBlock5_457',0,'15061437'),('bmBlock5_458',0,'15061447'),('bmBlock5_459',0,'15061457'),('bmBlock5_46',0,'14841507'),('bmBlock5_460',0,'15061467'),('bmBlock5_461',0,'15061477'),('bmBlock5_462',0,'15061487'),('bmBlock5_463',0,'15061497'),('bmBlock5_464',0,'15061507'),('bmBlock5_465',0,'15061517'),('bmBlock5_466',0,'15061527'),('bmBlock5_467',0,'15061537'),('bmBlock5_468',0,'15061547'),('bmBlock5_469',0,'15061557'),('bmBlock5_47',0,'14841517'),('bmBlock5_470',0,'15061567'),('bmBlock5_471',0,'15061577'),('bmBlock5_472',0,'15061587'),('bmBlock5_473',0,'15061597'),('bmBlock5_474',0,'15061607'),('bmBlock5_475',0,'15061617'),('bmBlock5_476',0,'15071377'),('bmBlock5_477',0,'15071397'),('bmBlock5_478',0,'15071417'),('bmBlock5_479',0,'15071437'),('bmBlock5_48',0,'14841527'),('bmBlock5_480',0,'15071457'),('bmBlock5_481',0,'15071477'),('bmBlock5_482',0,'15071497'),('bmBlock5_483',0,'15071517'),('bmBlock5_484',0,'15071537'),('bmBlock5_485',0,'15071557'),('bmBlock5_486',0,'15071577'),('bmBlock5_487',0,'15071597'),('bmBlock5_488',0,'15071617'),('bmBlock5_489',0,'15081397'),('bmBlock5_49',0,'14841537'),('bmBlock5_490',0,'15081407'),('bmBlock5_491',0,'15081417'),('bmBlock5_492',0,'15081427'),('bmBlock5_493',0,'15081437'),('bmBlock5_494',0,'15081447'),('bmBlock5_495',0,'15081457'),('bmBlock5_496',0,'15081467'),('bmBlock5_497',0,'15081477'),('bmBlock5_498',0,'15081487'),('bmBlock5_499',0,'15081497'),('bmBlock5_5',0,'14821437'),('bmBlock5_50',0,'14841547'),('bmBlock5_500',0,'15081507'),('bmBlock5_501',0,'15081517'),('bmBlock5_502',0,'15081527'),('bmBlock5_503',0,'15081537'),('bmBlock5_504',0,'15081547'),('bmBlock5_505',0,'15081557'),('bmBlock5_506',0,'15081567'),('bmBlock5_507',0,'15081577'),('bmBlock5_508',0,'15081587'),('bmBlock5_509',0,'15081597'),('bmBlock5_51',0,'14841557'),('bmBlock5_510',0,'15091397'),('bmBlock5_511',0,'15091417'),('bmBlock5_512',0,'15091437'),('bmBlock5_513',0,'15091457'),('bmBlock5_514',0,'15091477'),('bmBlock5_515',0,'15091497'),('bmBlock5_516',0,'15091517'),('bmBlock5_517',0,'15091537'),('bmBlock5_518',0,'15091557'),('bmBlock5_519',0,'15091577'),('bmBlock5_52',0,'14841567'),('bmBlock5_520',0,'15091597'),('bmBlock5_53',0,'14841577'),('bmBlock5_54',0,'14841587'),('bmBlock5_55',0,'14841597'),('bmBlock5_56',0,'14841607'),('bmBlock5_57',0,'14841617'),('bmBlock5_58',0,'14851377'),('bmBlock5_59',0,'14851397'),('bmBlock5_6',0,'14821447'),('bmBlock5_60',0,'14851417'),('bmBlock5_61',0,'14851437'),('bmBlock5_62',0,'14851457'),('bmBlock5_63',0,'14851477'),('bmBlock5_64',0,'14851497'),('bmBlock5_65',0,'14851517'),('bmBlock5_66',0,'14851537'),('bmBlock5_67',0,'14851557'),('bmBlock5_68',0,'14851577'),('bmBlock5_69',0,'14851597'),('bmBlock5_7',0,'14821457'),('bmBlock5_70',0,'14851617'),('bmBlock5_71',0,'14861377'),('bmBlock5_72',0,'14861387'),('bmBlock5_73',0,'14861397'),('bmBlock5_74',0,'14861407'),('bmBlock5_75',0,'14861417'),('bmBlock5_76',0,'14861427'),('bmBlock5_77',0,'14861437'),('bmBlock5_78',0,'14861447'),('bmBlock5_79',0,'14861457'),('bmBlock5_8',0,'14821467'),('bmBlock5_80',0,'14861467'),('bmBlock5_81',0,'14861477'),('bmBlock5_82',0,'14861487'),('bmBlock5_83',0,'14861497'),('bmBlock5_84',0,'14861507'),('bmBlock5_85',0,'14861517'),('bmBlock5_86',0,'14861527'),('bmBlock5_87',0,'14861537'),('bmBlock5_88',0,'14861547'),('bmBlock5_89',0,'14861557'),('bmBlock5_9',0,'14821477'),('bmBlock5_90',0,'14861567'),('bmBlock5_91',0,'14861577'),('bmBlock5_92',0,'14861587'),('bmBlock5_93',0,'14861597'),('bmBlock5_94',0,'14861607'),('bmBlock5_95',0,'14861617'),('bmBlock5_96',0,'14871377'),('bmBlock5_97',0,'14871397'),('bmBlock5_98',0,'14871417'),('bmBlock5_99',0,'14871437'),('bmBlock6_1',0,'15481407'),('bmBlock6_10',0,'15481497'),('bmBlock6_100',0,'15531467'),('bmBlock6_101',0,'15531487'),('bmBlock6_102',0,'15531507'),('bmBlock6_103',0,'15531527'),('bmBlock6_104',0,'15531547'),('bmBlock6_105',0,'15531567'),('bmBlock6_106',0,'15531587'),('bmBlock6_107',0,'15531607'),('bmBlock6_108',0,'15531627'),('bmBlock6_109',0,'15541387'),('bmBlock6_11',0,'15481507'),('bmBlock6_110',0,'15541397'),('bmBlock6_111',0,'15541407'),('bmBlock6_112',0,'15541417'),('bmBlock6_113',0,'15541427'),('bmBlock6_114',0,'15541437'),('bmBlock6_115',0,'15541447'),('bmBlock6_116',0,'15541457'),('bmBlock6_117',0,'15541467'),('bmBlock6_118',0,'15541477'),('bmBlock6_119',0,'15541487'),('bmBlock6_12',0,'15481517'),('bmBlock6_120',0,'15541497'),('bmBlock6_121',0,'15541507'),('bmBlock6_122',0,'15541517'),('bmBlock6_123',0,'15541527'),('bmBlock6_124',0,'15541537'),('bmBlock6_125',0,'15541547'),('bmBlock6_126',0,'15541557'),('bmBlock6_127',0,'15541567'),('bmBlock6_128',0,'15541577'),('bmBlock6_129',0,'15541587'),('bmBlock6_13',0,'15481527'),('bmBlock6_130',0,'15541597'),('bmBlock6_131',0,'15541607'),('bmBlock6_132',0,'15541617'),('bmBlock6_133',0,'15541627'),('bmBlock6_134',0,'15551387'),('bmBlock6_135',0,'15551407'),('bmBlock6_136',0,'15551427'),('bmBlock6_137',0,'15551447'),('bmBlock6_138',0,'15551467'),('bmBlock6_139',0,'15551487'),('bmBlock6_14',0,'15481537'),('bmBlock6_140',0,'15551507'),('bmBlock6_141',0,'15551527'),('bmBlock6_142',0,'15551547'),('bmBlock6_143',0,'15551567'),('bmBlock6_144',0,'15551587'),('bmBlock6_145',0,'15551607'),('bmBlock6_146',0,'15551627'),('bmBlock6_147',0,'15561387'),('bmBlock6_148',0,'15561397'),('bmBlock6_149',0,'15561407'),('bmBlock6_15',0,'15481547'),('bmBlock6_150',0,'15561417'),('bmBlock6_151',0,'15561427'),('bmBlock6_152',0,'15561437'),('bmBlock6_153',0,'15561447'),('bmBlock6_154',0,'15561457'),('bmBlock6_155',0,'15561467'),('bmBlock6_156',0,'15561477'),('bmBlock6_157',0,'15561487'),('bmBlock6_158',0,'15561497'),('bmBlock6_159',0,'15561507'),('bmBlock6_16',0,'15481557'),('bmBlock6_160',0,'15561517'),('bmBlock6_161',0,'15561527'),('bmBlock6_162',0,'15561537'),('bmBlock6_163',0,'15561547'),('bmBlock6_164',0,'15561557'),('bmBlock6_165',0,'15561567'),('bmBlock6_166',0,'15561577'),('bmBlock6_167',0,'15561587'),('bmBlock6_168',0,'15561597'),('bmBlock6_169',0,'15561607'),('bmBlock6_17',0,'15481567'),('bmBlock6_170',0,'15561617'),('bmBlock6_171',0,'15561627'),('bmBlock6_172',0,'15571387'),('bmBlock6_173',0,'15571407'),('bmBlock6_174',0,'15571427'),('bmBlock6_175',0,'15571447'),('bmBlock6_176',0,'15571467'),('bmBlock6_177',0,'15571487'),('bmBlock6_178',0,'15571507'),('bmBlock6_179',0,'15571527'),('bmBlock6_18',0,'15481577'),('bmBlock6_180',0,'15571547'),('bmBlock6_181',0,'15571567'),('bmBlock6_182',0,'15571587'),('bmBlock6_183',0,'15571607'),('bmBlock6_184',0,'15571627'),('bmBlock6_185',0,'15581387'),('bmBlock6_186',0,'15581397'),('bmBlock6_187',0,'15581407'),('bmBlock6_188',0,'15581417'),('bmBlock6_189',0,'15581427'),('bmBlock6_19',0,'15481587'),('bmBlock6_190',0,'15581437'),('bmBlock6_191',0,'15581447'),('bmBlock6_192',0,'15581457'),('bmBlock6_193',0,'15581467'),('bmBlock6_194',0,'15581477'),('bmBlock6_195',0,'15581487'),('bmBlock6_196',0,'15581497'),('bmBlock6_197',0,'15581507'),('bmBlock6_198',0,'15581517'),('bmBlock6_199',0,'15581527'),('bmBlock6_2',0,'15481417'),('bmBlock6_20',0,'15481597'),('bmBlock6_200',0,'15581537'),('bmBlock6_201',0,'15581547'),('bmBlock6_202',0,'15581557'),('bmBlock6_203',0,'15581567'),('bmBlock6_204',0,'15581577'),('bmBlock6_205',0,'15581587'),('bmBlock6_206',0,'15581597'),('bmBlock6_207',0,'15581607'),('bmBlock6_208',0,'15581617'),('bmBlock6_209',0,'15581627'),('bmBlock6_21',0,'15481607'),('bmBlock6_210',0,'15591387'),('bmBlock6_211',0,'15591407'),('bmBlock6_212',0,'15591427'),('bmBlock6_213',0,'15591447'),('bmBlock6_214',0,'15591467'),('bmBlock6_215',0,'15591487'),('bmBlock6_216',0,'15591507'),('bmBlock6_217',0,'15591527'),('bmBlock6_218',0,'15591547'),('bmBlock6_219',0,'15591567'),('bmBlock6_22',0,'15491407'),('bmBlock6_220',0,'15591587'),('bmBlock6_221',0,'15591607'),('bmBlock6_222',0,'15591627'),('bmBlock6_223',0,'15601387'),('bmBlock6_224',0,'15601397'),('bmBlock6_225',0,'15601407'),('bmBlock6_226',0,'15601417'),('bmBlock6_227',0,'15601427'),('bmBlock6_228',0,'15601437'),('bmBlock6_229',0,'15601447'),('bmBlock6_23',0,'15491427'),('bmBlock6_230',0,'15601457'),('bmBlock6_231',0,'15601467'),('bmBlock6_232',0,'15601477'),('bmBlock6_233',0,'15601487'),('bmBlock6_234',0,'15601497'),('bmBlock6_235',0,'15601507'),('bmBlock6_236',0,'15601517'),('bmBlock6_237',0,'15601527'),('bmBlock6_238',0,'15601537'),('bmBlock6_239',0,'15601547'),('bmBlock6_24',0,'15491447'),('bmBlock6_240',0,'15601557'),('bmBlock6_241',0,'15601567'),('bmBlock6_242',0,'15601577'),('bmBlock6_243',0,'15601587'),('bmBlock6_244',0,'15601597'),('bmBlock6_245',0,'15601607'),('bmBlock6_246',0,'15601617'),('bmBlock6_247',0,'15601627'),('bmBlock6_248',0,'15611387'),('bmBlock6_249',0,'15611407'),('bmBlock6_25',0,'15491467'),('bmBlock6_250',0,'15611427'),('bmBlock6_251',0,'15611447'),('bmBlock6_252',0,'15611467'),('bmBlock6_253',0,'15611487'),('bmBlock6_254',0,'15611507'),('bmBlock6_255',0,'15611527'),('bmBlock6_256',0,'15611547'),('bmBlock6_257',0,'15611567'),('bmBlock6_258',0,'15611587'),('bmBlock6_259',0,'15611607'),('bmBlock6_26',0,'15491487'),('bmBlock6_260',0,'15611627'),('bmBlock6_261',0,'15621387'),('bmBlock6_262',0,'15621397'),('bmBlock6_263',0,'15621407'),('bmBlock6_264',0,'15621417'),('bmBlock6_265',0,'15621427'),('bmBlock6_266',0,'15621437'),('bmBlock6_267',0,'15621447'),('bmBlock6_268',0,'15621457'),('bmBlock6_269',0,'15621467'),('bmBlock6_27',0,'15491507'),('bmBlock6_270',0,'15621477'),('bmBlock6_271',0,'15621487'),('bmBlock6_272',0,'15621497'),('bmBlock6_273',0,'15621507'),('bmBlock6_274',0,'15621517'),('bmBlock6_275',0,'15621527'),('bmBlock6_276',0,'15621537'),('bmBlock6_277',0,'15621547'),('bmBlock6_278',0,'15621557'),('bmBlock6_279',0,'15621567'),('bmBlock6_28',0,'15491527'),('bmBlock6_280',0,'15621577'),('bmBlock6_281',0,'15621587'),('bmBlock6_282',0,'15621597'),('bmBlock6_283',0,'15621607'),('bmBlock6_284',0,'15621617'),('bmBlock6_285',0,'15621627'),('bmBlock6_286',0,'15631387'),('bmBlock6_287',0,'15631407'),('bmBlock6_288',0,'15631427'),('bmBlock6_289',0,'15631447'),('bmBlock6_29',0,'15491547'),('bmBlock6_290',0,'15631467'),('bmBlock6_291',0,'15631487'),('bmBlock6_292',0,'15631507'),('bmBlock6_293',0,'15631527'),('bmBlock6_294',0,'15631547'),('bmBlock6_295',0,'15631567'),('bmBlock6_296',0,'15631587'),('bmBlock6_297',0,'15631607'),('bmBlock6_298',0,'15631627'),('bmBlock6_299',0,'15641387'),('bmBlock6_3',0,'15481427'),('bmBlock6_30',0,'15491567'),('bmBlock6_300',0,'15641397'),('bmBlock6_301',0,'15641407'),('bmBlock6_302',0,'15641417'),('bmBlock6_303',0,'15641427'),('bmBlock6_304',0,'15641437'),('bmBlock6_305',0,'15641447'),('bmBlock6_306',0,'15641457'),('bmBlock6_307',0,'15641467'),('bmBlock6_308',0,'15641477'),('bmBlock6_309',0,'15641487'),('bmBlock6_31',0,'15491587'),('bmBlock6_310',0,'15641497'),('bmBlock6_311',0,'15641507'),('bmBlock6_312',0,'15641517'),('bmBlock6_313',0,'15641527'),('bmBlock6_314',0,'15641537'),('bmBlock6_315',0,'15641547'),('bmBlock6_316',0,'15641557'),('bmBlock6_317',0,'15641567'),('bmBlock6_318',0,'15641577'),('bmBlock6_319',0,'15641587'),('bmBlock6_32',0,'15491607'),('bmBlock6_320',0,'15641597'),('bmBlock6_321',0,'15641607'),('bmBlock6_322',0,'15641617'),('bmBlock6_323',0,'15641627'),('bmBlock6_324',0,'15651387'),('bmBlock6_325',0,'15651407'),('bmBlock6_326',0,'15651427'),('bmBlock6_327',0,'15651447'),('bmBlock6_328',0,'15651467'),('bmBlock6_329',0,'15651487'),('bmBlock6_33',0,'15501387'),('bmBlock6_330',0,'15651507'),('bmBlock6_331',0,'15651527'),('bmBlock6_332',0,'15651547'),('bmBlock6_333',0,'15651567'),('bmBlock6_334',0,'15651587'),('bmBlock6_335',0,'15651607'),('bmBlock6_336',0,'15651627'),('bmBlock6_337',0,'15661387'),('bmBlock6_338',0,'15661397'),('bmBlock6_339',0,'15661407'),('bmBlock6_34',0,'15501397'),('bmBlock6_340',0,'15661417'),('bmBlock6_341',0,'15661427'),('bmBlock6_342',0,'15661437'),('bmBlock6_343',0,'15661447'),('bmBlock6_344',0,'15661457'),('bmBlock6_345',0,'15661467'),('bmBlock6_346',0,'15661477'),('bmBlock6_347',0,'15661487'),('bmBlock6_348',0,'15661497'),('bmBlock6_349',0,'15661507'),('bmBlock6_35',0,'15501407'),('bmBlock6_350',0,'15661517'),('bmBlock6_351',0,'15661527'),('bmBlock6_352',0,'15661537'),('bmBlock6_353',0,'15661547'),('bmBlock6_354',0,'15661557'),('bmBlock6_355',0,'15661567'),('bmBlock6_356',0,'15661577'),('bmBlock6_357',0,'15661587'),('bmBlock6_358',0,'15661597'),('bmBlock6_359',0,'15661607'),('bmBlock6_36',0,'15501417'),('bmBlock6_360',0,'15661617'),('bmBlock6_361',0,'15661627'),('bmBlock6_362',0,'15671387'),('bmBlock6_363',0,'15671407'),('bmBlock6_364',0,'15671427'),('bmBlock6_365',0,'15671447'),('bmBlock6_366',0,'15671467'),('bmBlock6_367',0,'15671487'),('bmBlock6_368',0,'15671507'),('bmBlock6_369',0,'15671527'),('bmBlock6_37',0,'15501427'),('bmBlock6_370',0,'15671547'),('bmBlock6_371',0,'15671567'),('bmBlock6_372',0,'15671587'),('bmBlock6_373',0,'15671607'),('bmBlock6_374',0,'15671627'),('bmBlock6_375',0,'15681387'),('bmBlock6_376',0,'15681397'),('bmBlock6_377',0,'15681407'),('bmBlock6_378',0,'15681417'),('bmBlock6_379',0,'15681427'),('bmBlock6_38',0,'15501437'),('bmBlock6_380',0,'15681437'),('bmBlock6_381',0,'15681447'),('bmBlock6_382',0,'15681457'),('bmBlock6_383',0,'15681467'),('bmBlock6_384',0,'15681477'),('bmBlock6_385',0,'15681487'),('bmBlock6_386',0,'15681497'),('bmBlock6_387',0,'15681507'),('bmBlock6_388',0,'15681517'),('bmBlock6_389',0,'15681527'),('bmBlock6_39',0,'15501447'),('bmBlock6_390',0,'15681537'),('bmBlock6_391',0,'15681547'),('bmBlock6_392',0,'15681557'),('bmBlock6_393',0,'15681567'),('bmBlock6_394',0,'15681577'),('bmBlock6_395',0,'15681587'),('bmBlock6_396',0,'15681597'),('bmBlock6_397',0,'15681607'),('bmBlock6_398',0,'15681617'),('bmBlock6_399',0,'15681627'),('bmBlock6_4',0,'15481437'),('bmBlock6_40',0,'15501457'),('bmBlock6_400',0,'15691387'),('bmBlock6_401',0,'15691407'),('bmBlock6_402',0,'15691427'),('bmBlock6_403',0,'15691447'),('bmBlock6_404',0,'15691467'),('bmBlock6_405',0,'15691487'),('bmBlock6_406',0,'15691507'),('bmBlock6_407',0,'15691527'),('bmBlock6_408',0,'15691547'),('bmBlock6_409',0,'15691567'),('bmBlock6_41',0,'15501467'),('bmBlock6_410',0,'15691587'),('bmBlock6_411',0,'15691607'),('bmBlock6_412',0,'15691627'),('bmBlock6_413',0,'15701387'),('bmBlock6_414',0,'15701397'),('bmBlock6_415',0,'15701407'),('bmBlock6_416',0,'15701417'),('bmBlock6_417',0,'15701427'),('bmBlock6_418',0,'15701437'),('bmBlock6_419',0,'15701447'),('bmBlock6_42',0,'15501477'),('bmBlock6_420',0,'15701457'),('bmBlock6_421',0,'15701467'),('bmBlock6_422',0,'15701477'),('bmBlock6_423',0,'15701487'),('bmBlock6_424',0,'15701497'),('bmBlock6_425',0,'15701507'),('bmBlock6_426',0,'15701517'),('bmBlock6_427',0,'15701527'),('bmBlock6_428',0,'15701537'),('bmBlock6_429',0,'15701547'),('bmBlock6_43',0,'15501487'),('bmBlock6_430',0,'15701557'),('bmBlock6_431',0,'15701567'),('bmBlock6_432',0,'15701577'),('bmBlock6_433',0,'15701587'),('bmBlock6_434',0,'15701597'),('bmBlock6_435',0,'15701607'),('bmBlock6_436',0,'15701617'),('bmBlock6_437',0,'15701627'),('bmBlock6_438',0,'15711387'),('bmBlock6_439',0,'15711407'),('bmBlock6_44',0,'15501497'),('bmBlock6_440',0,'15711427'),('bmBlock6_441',0,'15711447'),('bmBlock6_442',0,'15711467'),('bmBlock6_443',0,'15711487'),('bmBlock6_444',0,'15711507'),('bmBlock6_445',0,'15711527'),('bmBlock6_446',0,'15711547'),('bmBlock6_447',0,'15711567'),('bmBlock6_448',0,'15711587'),('bmBlock6_449',0,'15711607'),('bmBlock6_45',0,'15501507'),('bmBlock6_450',0,'15711627'),('bmBlock6_451',0,'15721387'),('bmBlock6_452',0,'15721397'),('bmBlock6_453',0,'15721407'),('bmBlock6_454',0,'15721417'),('bmBlock6_455',0,'15721427'),('bmBlock6_456',0,'15721437'),('bmBlock6_457',0,'15721447'),('bmBlock6_458',0,'15721457'),('bmBlock6_459',0,'15721467'),('bmBlock6_46',0,'15501517'),('bmBlock6_460',0,'15721477'),('bmBlock6_461',0,'15721487'),('bmBlock6_462',0,'15721497'),('bmBlock6_463',0,'15721507'),('bmBlock6_464',0,'15721517'),('bmBlock6_465',0,'15721527'),('bmBlock6_466',0,'15721537'),('bmBlock6_467',0,'15721547'),('bmBlock6_468',0,'15721557'),('bmBlock6_469',0,'15721567'),('bmBlock6_47',0,'15501527'),('bmBlock6_470',0,'15721577'),('bmBlock6_471',0,'15721587'),('bmBlock6_472',0,'15721597'),('bmBlock6_473',0,'15721607'),('bmBlock6_474',0,'15721617'),('bmBlock6_475',0,'15721627'),('bmBlock6_476',0,'15731387'),('bmBlock6_477',0,'15731407'),('bmBlock6_478',0,'15731427'),('bmBlock6_479',0,'15731447'),('bmBlock6_48',0,'15501537'),('bmBlock6_480',0,'15731467'),('bmBlock6_481',0,'15731487'),('bmBlock6_482',0,'15731507'),('bmBlock6_483',0,'15731527'),('bmBlock6_484',0,'15731547'),('bmBlock6_485',0,'15731567'),('bmBlock6_486',0,'15731587'),('bmBlock6_487',0,'15731607'),('bmBlock6_488',0,'15731627'),('bmBlock6_489',0,'15741407'),('bmBlock6_49',0,'15501547'),('bmBlock6_490',0,'15741417'),('bmBlock6_491',0,'15741427'),('bmBlock6_492',0,'15741437'),('bmBlock6_493',0,'15741447'),('bmBlock6_494',0,'15741457'),('bmBlock6_495',0,'15741467'),('bmBlock6_496',0,'15741477'),('bmBlock6_497',0,'15741487'),('bmBlock6_498',0,'15741497'),('bmBlock6_499',0,'15741507'),('bmBlock6_5',0,'15481447'),('bmBlock6_50',0,'15501557'),('bmBlock6_500',0,'15741517'),('bmBlock6_501',0,'15741527'),('bmBlock6_502',0,'15741537'),('bmBlock6_503',0,'15741547'),('bmBlock6_504',0,'15741557'),('bmBlock6_505',0,'15741567'),('bmBlock6_506',0,'15741577'),('bmBlock6_507',0,'15741587'),('bmBlock6_508',0,'15741597'),('bmBlock6_509',0,'15741607'),('bmBlock6_51',0,'15501567'),('bmBlock6_510',0,'15751407'),('bmBlock6_511',0,'15751427'),('bmBlock6_512',0,'15751447'),('bmBlock6_513',0,'15751467'),('bmBlock6_514',0,'15751487'),('bmBlock6_515',0,'15751507'),('bmBlock6_516',0,'15751527'),('bmBlock6_517',0,'15751547'),('bmBlock6_518',0,'15751567'),('bmBlock6_519',0,'15751587'),('bmBlock6_52',0,'15501577'),('bmBlock6_520',0,'15751607'),('bmBlock6_53',0,'15501587'),('bmBlock6_54',0,'15501597'),('bmBlock6_55',0,'15501607'),('bmBlock6_56',0,'15501617'),('bmBlock6_57',0,'15501627'),('bmBlock6_58',0,'15511387'),('bmBlock6_59',0,'15511407'),('bmBlock6_6',0,'15481457'),('bmBlock6_60',0,'15511427'),('bmBlock6_61',0,'15511447'),('bmBlock6_62',0,'15511467'),('bmBlock6_63',0,'15511487'),('bmBlock6_64',0,'15511507'),('bmBlock6_65',0,'15511527'),('bmBlock6_66',0,'15511547'),('bmBlock6_67',0,'15511567'),('bmBlock6_68',0,'15511587'),('bmBlock6_69',0,'15511607'),('bmBlock6_7',0,'15481467'),('bmBlock6_70',0,'15511627'),('bmBlock6_71',0,'15521387'),('bmBlock6_72',0,'15521397'),('bmBlock6_73',0,'15521407'),('bmBlock6_74',0,'15521417'),('bmBlock6_75',0,'15521427'),('bmBlock6_76',0,'15521437'),('bmBlock6_77',0,'15521447'),('bmBlock6_78',0,'15521457'),('bmBlock6_79',0,'15521467'),('bmBlock6_8',0,'15481477'),('bmBlock6_80',0,'15521477'),('bmBlock6_81',0,'15521487'),('bmBlock6_82',0,'15521497'),('bmBlock6_83',0,'15521507'),('bmBlock6_84',0,'15521517'),('bmBlock6_85',0,'15521527'),('bmBlock6_86',0,'15521537'),('bmBlock6_87',0,'15521547'),('bmBlock6_88',0,'15521557'),('bmBlock6_89',0,'15521567'),('bmBlock6_9',0,'15481487'),('bmBlock6_90',0,'15521577'),('bmBlock6_91',0,'15521587'),('bmBlock6_92',0,'15521597'),('bmBlock6_93',0,'15521607'),('bmBlock6_94',0,'15521617'),('bmBlock6_95',0,'15521627'),('bmBlock6_96',0,'15531387'),('bmBlock6_97',0,'15531407'),('bmBlock6_98',0,'15531427'),('bmBlock6_99',0,'15531447'),('bmBlockCount1',0,'520'),('bmBlockCount2',0,'520'),('bmBlockCount3',0,'520'),('bmBlockCount4',0,'520'),('bmBlockCount5',0,'520'),('bmBlockCount6',0,'520'),('bmMusicLoop',0,'1786163459'),('cidOneInRingOne',0,'0'),('cidOneInRingTwo',0,'0'),('cidShootingOne',0,'0'),('cidShootingTwo',0,'0'),('cidSnakeGame',0,'0'),('cidTwoInRingOne',0,'0'),('cidTwoInRingTwo',0,'0'),('comecouWar',0,'1'),('countbear',0,'9'),('countblack knight',0,'0'),('countbloody hunter',0,'2'),('countchicken',0,'2'),('countchoking fear',0,'14'),('countclawed rotworm',0,'28'),('countcockroach',0,'72'),('countcyclops',0,'21'),('countcyclops drone',0,'3'),('countcyclops smith',0,'0'),('countdeer',0,'1'),('countdestroyer',0,'3'),('countdevil skeleton',0,'0'),('countdonkey',0,'7'),('countdragon',0,'4'),('countdromedary',0,'2'),('countelephant',0,'1'),('countfrazzlemaw',0,'9'),('countgargoyle',0,'7'),('countgilacorn',0,'3'),('countgrudgan',0,'0'),('countguzzlemaw',0,'10'),('countjoaninha da terra',0,'8'),('countleao de ba sin se',0,'31'),('countmawhawk',0,'5'),('countmidnight panther',0,'14'),('countminotaur amazon',0,'1'),('countnomad',0,'1'),('countpanda',0,'0'),('countpica-pau da terra',0,'53'),('countpig',0,'0'),('countpoison spider',0,'0'),('countrotworm',0,'1807'),('countskeleton',0,'9'),('countson of water',0,'8'),('countspider',0,'0'),('countspiritual bloody hunter',0,'0'),('countspiritual leao de ba sin se',0,'27'),('counttarantula de pedra',0,'6'),('countterror bird',0,'0'),('countwailing widow',0,'0'),('countwater buffalo',0,'5'),('countwolf',0,'3'),('countzuko\'s disciple',0,'6'),('dailychallengercount0',0,'1'),('dailychallengercount1',0,'3'),('dailychallengercount2',0,'2'),('dailychallengercount3',0,'2'),('dailychallengermonster0',0,'Abyssador'),('dailychallengermonster1',0,'Moohtant'),('dailychallengermonster2',0,'Olaf'),('dailychallengermonster3',0,'Hellflayer'),('dailyeasycount0',0,'18'),('dailyeasycount1',0,'17'),('dailyeasycount2',0,'19'),('dailyeasycount3',0,'15'),('dailyeasymonster0',0,'Elf'),('dailyeasymonster1',0,'Kongra'),('dailyeasymonster2',0,'Orc'),('dailyeasymonster3',0,'Dwarve'),('dailyextremecount0',0,'49'),('dailyextremecount1',0,'48'),('dailyextremecount2',0,'49'),('dailyextremecount3',0,'48'),('dailyextrememonster0',0,'Vulcongra'),('dailyextrememonster1',0,'Lost Husher'),('dailyextrememonster2',0,'Draken Warmaster'),('dailyextrememonster3',0,'Minotaur Amazon'),('dailyhardcorecount0',0,'28'),('dailyhardcorecount1',0,'27'),('dailyhardcorecount2',0,'30'),('dailyhardcorecount3',0,'29'),('dailyhardcoremonster0',0,'Lizard High Guard'),('dailyhardcoremonster1',0,'Vulcongra'),('dailyhardcoremonster2',0,'Hydramat'),('dailyhardcoremonster3',0,'Hydramat'),('dailyhardcount0',0,'29'),('dailyhardcount1',0,'26'),('dailyhardcount2',0,'28'),('dailyhardcount3',0,'30'),('dailyhardmonster0',0,'Sea Serpent'),('dailyhardmonster1',0,'War Golem'),('dailyhardmonster2',0,'Ancient Scarab'),('dailyhardmonster3',0,'Dragon'),('dailymediumcount0',0,'24'),('dailymediumcount1',0,'21'),('dailymediumcount2',0,'20'),('dailymediumcount3',0,'20'),('dailymediummonster0',0,'Wyvern'),('dailymediummonster1',0,'Fire Devil'),('dailymediummonster2',0,'Ice Golem'),('dailymediummonster3',0,'Son of Water'),('dayId1',0,'108'),('geniusGame1',0,'0'),('geniusGame2',0,'0'),('geniusGame3',0,'0'),('GlobalSaveDays',0,'11'),('lider1',0,'0'),('lider2',0,'0'),('resetQuestBauOpen',0,'-1'),('resetQuestClosed',0,'-1'),('yearId1',0,'0');
/*!40000 ALTER TABLE `global_storage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `guild_invites`
--

DROP TABLE IF EXISTS `guild_invites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guild_invites` (
  `player_id` int(11) NOT NULL DEFAULT 0,
  `guild_id` int(11) NOT NULL DEFAULT 0,
  UNIQUE KEY `player_id` (`player_id`,`guild_id`),
  KEY `guild_id` (`guild_id`),
  CONSTRAINT `guild_invites_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
  CONSTRAINT `guild_invites_ibfk_2` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `guild_invites`
--

LOCK TABLES `guild_invites` WRITE;
/*!40000 ALTER TABLE `guild_invites` DISABLE KEYS */;
/*!40000 ALTER TABLE `guild_invites` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `guild_kills`
--

DROP TABLE IF EXISTS `guild_kills`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guild_kills` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guild_id` int(11) NOT NULL,
  `war_id` int(11) NOT NULL,
  `death_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `guild_id` (`guild_id`),
  KEY `war_id` (`war_id`),
  KEY `death_id` (`death_id`),
  CONSTRAINT `guild_kills_ibfk_1` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE,
  CONSTRAINT `guild_kills_ibfk_2` FOREIGN KEY (`war_id`) REFERENCES `guild_wars` (`id`) ON DELETE CASCADE,
  CONSTRAINT `guild_kills_ibfk_3` FOREIGN KEY (`death_id`) REFERENCES `player_deaths` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `guild_kills`
--

LOCK TABLES `guild_kills` WRITE;
/*!40000 ALTER TABLE `guild_kills` DISABLE KEYS */;
/*!40000 ALTER TABLE `guild_kills` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `guild_membership`
--

DROP TABLE IF EXISTS `guild_membership`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guild_membership` (
  `player_id` int(11) NOT NULL,
  `guild_id` int(11) NOT NULL,
  `rank_id` int(11) NOT NULL,
  `nick` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`player_id`),
  KEY `guild_id` (`guild_id`),
  KEY `rank_id` (`rank_id`),
  CONSTRAINT `guild_membership_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `guild_membership_ibfk_2` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `guild_membership_ibfk_3` FOREIGN KEY (`rank_id`) REFERENCES `guild_ranks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `guild_membership`
--

LOCK TABLES `guild_membership` WRITE;
/*!40000 ALTER TABLE `guild_membership` DISABLE KEYS */;
/*!40000 ALTER TABLE `guild_membership` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `guild_ranks`
--

DROP TABLE IF EXISTS `guild_ranks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guild_ranks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guild_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `level` int(11) NOT NULL COMMENT '1 - leader, 2 - vice leader, 3 - member',
  PRIMARY KEY (`id`),
  KEY `guild_id` (`guild_id`),
  CONSTRAINT `guild_ranks_ibfk_1` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `guild_ranks`
--

LOCK TABLES `guild_ranks` WRITE;
/*!40000 ALTER TABLE `guild_ranks` DISABLE KEYS */;
/*!40000 ALTER TABLE `guild_ranks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `guild_wars`
--

DROP TABLE IF EXISTS `guild_wars`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guild_wars` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guild_id` int(11) NOT NULL,
  `enemy_id` int(11) NOT NULL,
  `begin` bigint(20) NOT NULL DEFAULT 0,
  `end` bigint(20) NOT NULL DEFAULT 0,
  `frags` int(10) unsigned NOT NULL DEFAULT 0,
  `payment` bigint(20) unsigned NOT NULL DEFAULT 0,
  `guild_kills` int(10) unsigned NOT NULL DEFAULT 0,
  `enemy_kills` int(10) unsigned NOT NULL DEFAULT 0,
  `status` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `status` (`status`),
  KEY `guild_id` (`guild_id`),
  KEY `enemy_id` (`enemy_id`),
  CONSTRAINT `guild_wars_ibfk_1` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE,
  CONSTRAINT `guild_wars_ibfk_2` FOREIGN KEY (`enemy_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `guild_wars`
--

LOCK TABLES `guild_wars` WRITE;
/*!40000 ALTER TABLE `guild_wars` DISABLE KEYS */;
/*!40000 ALTER TABLE `guild_wars` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `guilds`
--

DROP TABLE IF EXISTS `guilds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guilds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `name` varchar(255) NOT NULL,
  `ownerid` int(11) NOT NULL,
  `creationdata` int(11) NOT NULL,
  `checkdata` int(11) NOT NULL,
  `motd` varchar(255) NOT NULL,
  `balance` bigint(20) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`,`world_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `guilds`
--

LOCK TABLES `guilds` WRITE;
/*!40000 ALTER TABLE `guilds` DISABLE KEYS */;
/*!40000 ALTER TABLE `guilds` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `oncreate_guilds` AFTER INSERT ON `guilds` FOR EACH ROW BEGIN INSERT INTO `guild_ranks` (`name`, `level`, `guild_id`) VALUES ('Leader', 3, NEW.`id`); INSERT INTO `guild_ranks` (`name`, `level`, `guild_id`) VALUES ('Vice-Leader', 2, NEW.`id`); INSERT INTO `guild_ranks` (`name`, `level`, `guild_id`) VALUES ('Member', 1, NEW.`id`); END */;;
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
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `ondelete_guilds`
BEFORE DELETE
ON `guilds`
FOR EACH ROW
BEGIN
	UPDATE `players` SET `guildnick` = '', `rank_id` = 0 WHERE `rank_id` IN (SELECT `id` FROM `guild_ranks` WHERE `guild_id` = OLD.`id`);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `guildwar_kills`
--

DROP TABLE IF EXISTS `guildwar_kills`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guildwar_kills` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `killer` varchar(50) NOT NULL,
  `target` varchar(50) NOT NULL,
  `killerguild` int(11) NOT NULL DEFAULT 0,
  `targetguild` int(11) NOT NULL DEFAULT 0,
  `warid` int(11) NOT NULL DEFAULT 0,
  `time` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `warid` (`warid`),
  CONSTRAINT `guildwar_kills_ibfk_1` FOREIGN KEY (`warid`) REFERENCES `guild_wars` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `guildwar_kills`
--

LOCK TABLES `guildwar_kills` WRITE;
/*!40000 ALTER TABLE `guildwar_kills` DISABLE KEYS */;
/*!40000 ALTER TABLE `guildwar_kills` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `house_auctions`
--

DROP TABLE IF EXISTS `house_auctions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `house_auctions` (
  `house_id` int(10) unsigned NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `player_id` int(11) NOT NULL,
  `bid` int(10) unsigned NOT NULL DEFAULT 0,
  `limit` int(10) unsigned NOT NULL DEFAULT 0,
  `endtime` bigint(20) unsigned NOT NULL DEFAULT 0,
  UNIQUE KEY `house_id` (`house_id`,`world_id`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `house_auctions_ibfk_1` FOREIGN KEY (`house_id`, `world_id`) REFERENCES `houses` (`id`, `world_id`) ON DELETE CASCADE,
  CONSTRAINT `house_auctions_ibfk_2` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `house_auctions`
--

LOCK TABLES `house_auctions` WRITE;
/*!40000 ALTER TABLE `house_auctions` DISABLE KEYS */;
/*!40000 ALTER TABLE `house_auctions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `house_data`
--

DROP TABLE IF EXISTS `house_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `house_data` (
  `house_id` int(10) unsigned NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `data` longblob NOT NULL,
  UNIQUE KEY `house_id` (`house_id`,`world_id`),
  CONSTRAINT `house_data_ibfk_1` FOREIGN KEY (`house_id`, `world_id`) REFERENCES `houses` (`id`, `world_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `house_data`
--

LOCK TABLES `house_data` WRITE;
/*!40000 ALTER TABLE `house_data` DISABLE KEYS */;
INSERT INTO `house_data` VALUES (4,0,'ì~\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ì\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0ó\0\0\0í(\0'),(5,0,'z\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0z\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0~\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0~\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0|\0\0\0í(\0'),(6,0,'z\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0z\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0|\0\0\0í(\0'),(7,0,'~\0\0\0ä(\0€\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(8,0,'|\0\0\0í(\0~\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0~\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(9,0,'\0\0\0ä(\0‚\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0‚\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(10,0,'s\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0s\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0s\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0t\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0w\0\0\0í(\0'),(11,0,'q\0\0\0¹\0\0\0\0\0r\0\0\0»\0\0\0\0\0p\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0p\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0v\0\0\0ä(\0'),(12,0,'q\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0r\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0p\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0p\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0u\0\0\0ä(\0'),(13,0,'l\0\0\0í(\0m\0\0\0d4€\0\0description\0\0\0\0\0price\n\0\0\0Unsellable\0m\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0m\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(14,0,'k\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0l\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0l\0\0\0í(\0'),(16,0,'j\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0k\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0i\0\0\0ä(\0'),(21,0,'q\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0r\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0 v\0\0\0ä(\0'),(22,0,'s\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0t\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0u\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0(s\0\0\0í(\0 u\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(23,0,'j\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0k\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0i\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0 i\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0(l\0\0\0í(\0'),(24,0,'j\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0k\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0 h\0\0\0ä(\0'),(25,0,'$j\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0$k\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0&h\0\0\0ä(\0'),(26,0,'a\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0b\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0a\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0b\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0#b\0\0\0í(\0\"d\0\0\0ä(\0'),(27,0,'9{\0\0\0ä(\09|\0\0\0ä(\07\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\07\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\08\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\08\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(28,0,'@y\0\0\0ä(\0@|\0\0\0ä(\0@}\0\0\0ä(\0>\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0?\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0@\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0A\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(29,0,'4s\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\05r\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\06r\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\03t\0\0\0í(\04t\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(30,0,'$q\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0$r\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0&v\0\0\0ä(\0'),(31,0,'3o\0\0\0í(\04n\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\04o\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\05p\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\06p\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(32,0,'T\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0U\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0U\0\0\0í(\0'),(33,0,'	T\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0\nT\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0V\0\0\0í(\0'),(35,0,'T\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0T\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0W\0\0\0í(\0'),(36,0,'Y\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0Y\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0[\0\0\0í(\0'),(37,0,'V\0\0\0í(\0	T\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0\nT\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(38,0,'[\0\0\0í(\0Y\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Z\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(39,0,'>K\0\0\0ä(\0>N\0\0\0ä(\0@G\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0@G\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0@H\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0@H\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(40,0,'8?\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0@?\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0@?\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0;A\0\0\0í(\08@\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\09D\0\0\0ä(\0@@\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0@@\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(41,0,'þK\0\0\0ä(\0ýL\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0þL\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0O\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0\0P\0\0\0í(\0P\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0P\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0P\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(42,0,'÷K\0\0\0ä(\0õL\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0õM\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(43,0,'êO\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0îL\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0îM\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0ðK\0\0\0ä(\0êQ\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0ëQ\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0êP\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0íP\0\0\0í(\0'),(44,0,'ùB\0\0\0ä(\0ü@\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0üA\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(45,0,'÷C\0\0\0í(\0õF\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0öF\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(46,0,'úC\0\0\0í(\0ûF\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0üF\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(47,0,'@\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0A\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0B\0\0\0í(\0B\0\0\0í(\0B\0\0\0í(\0C\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0C\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(49,0,'íV\0\0\0í(\0ê\\\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0ë\\\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(50,0,'Úh\0\0\0¡\0'),(51,0,'Ïh\0\0\0¡\0'),(54,0,'Ìf\0\0\0¡\0'),(55,0,'Ë_\0\0\0¡\0'),(56,0,'Õ\\\0\0\0¡\0Ø_\0\0\0¡\0'),(57,0,'ÝV\0\0\0¡\0áW\0\0\0ž\0'),(58,0,'ØW\0\0\0ž\0'),(59,0,'ÍT\0\0\0¡\0ÌW\0\0\0ž\0'),(60,0,'ÚO\0\0\0¡\0'),(68,0,'û‹\0\0\0ä\0ùŽ\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ù\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(69,0,'\0\0\0ä\0\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0‘\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(70,0,'&†\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0&‡\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0*ˆ\0\0\0á\0'),(71,0,':‹\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\06\0\0\0á\0:Œ\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(72,0,'.‡\0\0\0ä\00„\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\00…\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(73,0,'&ˆ\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0&‰\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0)‰\0\0\0á\0'),(74,0,'÷‰\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0÷Š\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0ú‹\0\0\0á\0'),(75,0,'ÿ…\0\0\0á\0\0†\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0†\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(77,0,'\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0‚\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0…\0\0\0ä\0'),(78,0,'\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0‚\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0…\0\0\0ä\0'),(79,0,'Š\0\0\0á\0\Zˆ\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0\Z‰\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(80,0,'\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ƒ\0\0\0ä\0€\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(81,0,'\Z\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ƒ\0\0\0ä\0\Z€\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(82,0,'\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0€\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0‚\0\0\0ä\0'),(83,0,'\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0€\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0‚\0\0\0ä\0'),(84,0,'‘\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0’\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0“\0\0\0á\0'),(85,0,'‘\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0’\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0”\0\0\0ä\0'),(86,0,'“\0\0\0á\0‘\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0’\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(87,0,'‘\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0’\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0”\0\0\0ä\0'),(88,0,'+‘\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0+’\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0.’\0\0\0á\0'),(89,0,'1’\0\0\0á\04‘\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\04’\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(90,0,'Az\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0A{\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Fz\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0F{\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0D~\0\0\0ä\0'),(91,0,'Bw\0\0\0á\0Eu\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ev\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(92,0,'Aw\0\0\0á\0Eu\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ev\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(93,0,'î§\0\0\0ä\0ï¨\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ï©\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(94,0,'ã£\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ã¤\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0æ¥\0\0\0á\0'),(96,0,'Lß\0\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0MÞ\0\0\0\0ë\Z\0Là\0\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Lã\0\0\0\0t\0'),(97,0,'RÞ\0\0\0\0ë\Z\0Qã\0\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Uâ\0\0\0\0t\0Qä\0\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Så\0\0\0\0s\0'),(98,0,'Qß\0\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Qà\0\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Sã\0\0\0\0ë\Z\0Uâ\0\0\0\0t\0'),(99,0,'Lß\0\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Là\0\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Nã\0\0\0\0ë\Z\0'),(100,0,'\\à\0\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0]à\0\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0^â\0\0\0\0ô\Z\0]æ\0\0\0\0s\0'),(101,0,'\\à\0\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0]à\0\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0^ã\0\0\0\0ô\Z\0\\æ\0\0\0\0s\0'),(102,0,'?Ô\0\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0?Õ\0\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0E×\0\0\0\0ô\Z\0FÚ\0\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0GÚ\0\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0GÛ\0\0\0\0s\0HØ\0\0\0\0t\0'),(103,0,'GÒ\0\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0GÓ\0\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0HÓ\0\0\0\0t\0CÔ\0\0\0\0ë\Z\0'),(104,0,'?Ò\0\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0?Ó\0\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0A×\0\0\0\0ô\Z\0'),(105,0,'AË\0\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0HÊ\0\0\0\0ë\Z\0@Ì\0\0\0\0t\0AÌ\0\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0EÎ\0\0\0\0s\0KÌ\0\0\0\0t\0'),(106,0,'EÄ\0\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0EÅ\0\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0HÆ\0\0\0\0ë\Z\0KÄ\0\0\0\0t\0'),(107,0,'hÒ\0\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0hÓ\0\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0kÔ\0\0\0\0ô\Z\0'),(108,0,'È\0ô\0\0\0ô\Z\0'),(109,0,'È\0ú\0\0\0ô\Z\0'),(110,0,'Ù\0æ\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ù\0ç\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Ý\0æ\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ý\0ç\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Û\0ë\0\0\0Ð#\0'),(111,0,'Ð\0æ\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ð\0ç\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Ô\0æ\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ô\0ç\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Ò\0ë\0\0\0Ð#\0'),(112,0,'·\0ß\0\0\0º€\0\0descriptione\0\0\0It belongs to house \'Fire Nation Capital House 5\'. Nobody owns this house. It costs 84000 gold coins.\0¹\0Ü\0\0\0&\0º\0Ý\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0º\0Þ\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0¹\0â\0\0\0&\0'),(113,0,'™\0Ö\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0™\0×\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0\0Ø\0\0\0º€\0\0descriptione\0\0\0It belongs to house \'Fire Nation Capital House 6\'. Nobody owns this house. It costs 90000 gold coins.\0'),(114,0,'˜\0Ð\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0˜\0Ñ\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0›\0Ò\0\0\0º€\0\0descriptione\0\0\0It belongs to house \'Fire Nation Capital House 7\'. Nobody owns this house. It costs 48000 gold coins.\0'),(115,0,'§\0Ï\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0¥\0Ð\0\0\0º€\0\0descriptione\0\0\0It belongs to house \'Fire Nation Capital House 8\'. Nobody owns this house. It costs 30000 gold coins.\0§\0Ð\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(116,0,'¡\0Ä\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0¡\0Å\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0¥\0Å\0\0\0º€\0\0descriptione\0\0\0It belongs to house \'Fire Nation Capital House 9\'. Nobody owns this house. It costs 66000 gold coins.\0'),(117,0,'ª\0Ô\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ª\0Õ\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0­\0Õ\0\0\0º€\0\0descriptionf\0\0\0It belongs to house \'Fire Nation Capital House 10\'. Nobody owns this house. It costs 54000 gold coins.\0'),(118,0,'Â\0»\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Æ\0»\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ç\0¹\0\0\0Í#\0Â\0¼\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Æ\0¼\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(119,0,'Â\0¾\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Â\0¿\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Æ\0¾\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Æ\0¿\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Ä\0Á\0\0\0Ð#\0Ä\0Ç\0\0\0Ð#\0Ç\0Ä\0\0\0Í#\0Â\0È\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Â\0É\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(120,0,'Ñ\0·\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ð\0¶\0\0\0Ð#\0Ñ\0¸\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(121,0,'Ú\0·\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ù\0¶\0\0\0Ð#\0Ú\0¸\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(122,0,'Ì\0Ê\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ì\0Ë\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Î\0Ê\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Î\0Ë\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Ð\0Ì\0\0\0Í#\0'),(123,0,'Ö\0Ì\0\0\0Ð#\0Ù\0Ï\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ù\0Ð\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(124,0,'Ã\0¯\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Å\0¯\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ç\0®\0\0\0Í#\0Ã\0°\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Å\0°\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(125,0,'î\0©\0\0\0Ð#\0ï\0ª\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ï\0«\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0î\0±\0\0\0Ð#\0'),(126,0,'÷\0ª\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0÷\0«\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0õ\0±\0\0\0Ð#\0'),(127,0,'þ\0±\0\0\0Ð#\0\0ª\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0\0«\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(128,0,'ª\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0«\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0	­\0\0\0Ð#\0'),(129,0,'ª\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0«\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0­\0\0\0Ð#\0'),(130,0,'¯\0\0\0Í#\0\r®\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0\r¯\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(131,0,'·\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0\nµ\0\0\0Ð#\0\r·\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0¸\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0\nº\0\0\0Ð#\0\nº\0\0\0Ð#\0\r¸\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0¼\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0½\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0½\0\0\0Í#\0Â\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0Ã\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0\nÀ\0\0\0Ð#\0\nÀ\0\0\0Ð#\0\rÂ\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0\rÃ\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0\nÅ\0\0\0Ð#\0'),(132,0,'þ\0Ú\0\0\0Õ#\0ý\0Þ\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0þ\0Þ\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(133,0,'×\0\0\0Ó#\0Ö\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0×\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(134,0,'þ\0Ú\0\0\0Õ#\0ý\0Þ\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0þ\0Þ\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(135,0,'×\0\0\0Ó#\0Ö\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0×\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(136,0,'×\0\0\0Õ#\0\rÛ\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0\rÜ\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(137,0,'ý\0Ë\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ý\0Î\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ý\0Ï\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0ý\0Ì\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0\0Ë\0\0\0Í#\0Ê\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0Ê\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0Ï\0\0\0Í#\0'),(138,0,'ý\0Ê\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ý\0Ë\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0Ë\0\0\0Í#\0'),(139,0,'\nÉ\0\0\0Ð#\0\rÊ\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0\rË\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0\rÏ\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0\rÐ\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(147,0,')_\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0.^\0\0\0ä(\01_\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0)b\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0)c\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0)`\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0-d\0\0\0ä(\00c\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\01c\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\01`\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(148,0,'K\0\0\0ä(\0N\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0O\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0	P\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0\nP\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(149,0,'í@\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0íA\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0îF\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0ïF\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0ïG\0\0\0ä(\0'),(150,0,'\\\0\0\0ä(\0\\\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0]\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(151,0,'!I\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0\"I\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0\'J\0\0\0í(\0'),(152,0,'!F\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0!G\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0\'F\0\0\0í(\0'),(153,0,'!C\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0\"C\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0\'B\0\0\0í(\0'),(154,0,'+B\0\0\0í(\00C\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\01C\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(155,0,'+F\0\0\0í(\01F\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\01G\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(156,0,'+J\0\0\0í(\00I\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\01I\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(157,0,'+J\0\0\0í(\00I\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\01I\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(158,0,'!I\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0\"I\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0\'J\0\0\0í(\0'),(159,0,'!F\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0!G\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0\'F\0\0\0í(\0'),(160,0,'+F\0\0\0í(\01F\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\01G\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0'),(161,0,'+B\0\0\0í(\00C\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\01C\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(162,0,'!C\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0\"C\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0\'B\0\0\0í(\0'),(164,0,'‚}\0\0\0½€\0\0description\\\0\0\0It belongs to house \'Unnamed House #164\'. Nobody owns this house. It costs 36000 gold coins.\0'),(166,0,'~\0\0\0½€\0\0description\\\0\0\0It belongs to house \'Unnamed House #166\'. Nobody owns this house. It costs 36000 gold coins.\0'),(167,0,'•y\0\0\0½€\0\0description\\\0\0\0It belongs to house \'Unnamed House #167\'. Nobody owns this house. It costs 36000 gold coins.\0'),(168,0,'‚\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0‚\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0…\0\0\0í(\0…\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0†\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0ˆ\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0ˆ\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(169,0,'îk\0\0\0Ú€\0\0description\0\0\0Nobody is sleeping there.\0ën\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0îl\0\0\0Û€\0\0description\0\0\0Nobody is sleeping there.\0ìn\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0ïl\0\0\0í(\0'),(171,0,'ür\0\0\0í(\0\0p\0\0\0à€\0\0description\0\0\0Nobody is sleeping there.\0p\0\0\0á€\0\0description\0\0\0Nobody is sleeping there.\0'),(172,0,'‰x\0\0\0½€\0\0description\\\0\0\0It belongs to house \'Unnamed House #172\'. Nobody owns this house. It costs 36000 gold coins.\0');
/*!40000 ALTER TABLE `house_data` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `house_lists`
--

DROP TABLE IF EXISTS `house_lists`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `house_lists` (
  `house_id` int(10) unsigned NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `listid` int(11) NOT NULL,
  `list` text NOT NULL,
  UNIQUE KEY `house_id` (`house_id`,`world_id`,`listid`),
  CONSTRAINT `house_lists_ibfk_1` FOREIGN KEY (`house_id`, `world_id`) REFERENCES `houses` (`id`, `world_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `house_lists`
--

LOCK TABLES `house_lists` WRITE;
/*!40000 ALTER TABLE `house_lists` DISABLE KEYS */;
/*!40000 ALTER TABLE `house_lists` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `houses`
--

DROP TABLE IF EXISTS `houses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `houses` (
  `id` int(10) unsigned NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `owner` int(11) NOT NULL,
  `paid` int(10) unsigned NOT NULL DEFAULT 0,
  `warnings` int(11) NOT NULL DEFAULT 0,
  `lastwarning` int(10) unsigned NOT NULL DEFAULT 0,
  `name` varchar(255) NOT NULL,
  `town` int(10) unsigned NOT NULL DEFAULT 0,
  `size` int(10) unsigned NOT NULL DEFAULT 0,
  `price` int(10) unsigned NOT NULL DEFAULT 0,
  `rent` int(10) unsigned NOT NULL DEFAULT 0,
  `doors` int(10) unsigned NOT NULL DEFAULT 0,
  `beds` int(10) unsigned NOT NULL DEFAULT 0,
  `tiles` int(10) unsigned NOT NULL DEFAULT 0,
  `guild` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `clear` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `highest_bidder` int(11) NOT NULL DEFAULT 0,
  `bid_end` int(11) NOT NULL DEFAULT 0,
  `last_bid` int(11) NOT NULL DEFAULT 0,
  `bid` int(11) NOT NULL DEFAULT 0,
  UNIQUE KEY `id` (`id`,`world_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `houses`
--

LOCK TABLES `houses` WRITE;
/*!40000 ALTER TABLE `houses` DISABLE KEYS */;
INSERT INTO `houses` VALUES (4,0,0,0,0,0,'Ba Sing Se House 27',1,17,108000,0,0,1,46,0,0,0,0,0,0),(5,0,0,0,0,0,'Ba Sing Se House 47',1,13,90000,0,0,2,39,0,0,0,0,0,0),(6,0,0,0,0,0,'Ba Sing Se House 48',1,10,66000,0,0,1,32,0,0,0,0,0,0),(7,0,0,0,0,0,'Ba Sing Se House 49',1,23,144000,0,0,1,45,0,0,0,0,0,0),(8,0,0,0,0,0,'Ba Sing Se House 50',1,14,90000,0,0,1,27,0,0,0,0,0,0),(9,0,0,0,0,0,'Ba Sing Se House 1',1,8,54000,0,0,1,21,0,0,0,0,0,0),(10,0,0,0,0,0,'Ba Sing Se House 37',1,42,264000,0,0,2,97,0,0,0,0,0,0),(11,0,0,0,0,0,'Ba Sing Se House 2',1,21,132000,0,0,1,51,0,0,0,0,0,0),(12,0,0,0,0,0,'Ba Sing Se House 3',1,18,120000,0,0,2,35,0,0,0,0,0,0),(13,0,0,0,0,0,'Ba Sing Se House 4',1,26,162000,0,0,1,43,0,0,0,0,0,0),(14,0,0,0,0,0,'Ba Sing Se House 5',1,10,66000,0,0,1,30,0,0,0,0,0,0),(16,0,0,0,0,0,'Ba Sing Se House 7',1,18,114000,0,0,1,36,0,0,0,0,0,0),(21,0,0,0,0,0,'Ba Sing Se House 8',1,16,102000,0,0,1,40,0,0,0,0,0,0),(22,0,0,0,0,0,'Ba Sing Se House 10',1,40,252000,0,0,2,62,0,0,0,0,0,0),(23,0,0,0,0,0,'Ba Sing Se House 11',1,40,252000,0,0,2,62,0,0,0,0,0,0),(24,0,0,0,0,0,'Ba Sing Se House 12',1,16,102000,0,0,1,40,0,0,0,0,0,0),(25,0,0,0,0,0,'Ba Sing Se House 13',1,16,102000,0,0,1,39,0,0,0,0,0,0),(26,0,0,0,0,0,'Ba Sing Se House 14',1,48,300000,0,0,2,100,0,0,0,0,0,0),(27,0,0,0,0,0,'Ba Sing Se House 15',1,48,300000,0,0,2,93,0,0,0,0,0,0),(28,0,0,0,0,0,'Ba Sing Se House 16',1,52,324000,0,0,2,105,0,0,0,0,0,0),(29,0,0,0,0,0,'Ba Sing Se House 17',1,52,324000,0,0,2,87,0,0,0,0,0,0),(30,0,0,0,0,0,'Ba Sing Se House 9',1,16,102000,0,0,1,40,0,0,0,0,0,0),(31,0,0,0,0,0,'Ba Sing Se House 18',1,52,324000,0,0,2,82,0,0,0,0,0,0),(32,0,0,0,0,0,'Ba Sing Se House 19',1,58,354000,0,0,1,108,0,0,0,0,0,0),(33,0,0,0,0,0,'Ba Sing Se House 20',1,26,162000,0,0,1,40,0,0,0,0,0,0),(34,0,0,0,0,0,'Ba Sing Se House 21',1,1,6000,0,0,0,14,0,0,0,0,0,0),(35,0,0,0,0,0,'Ba Sing Se House 22',1,14,90000,0,0,1,25,0,0,0,0,0,0),(36,0,0,0,0,0,'Ba Sing Se House 23',1,14,90000,0,0,1,25,0,0,0,0,0,0),(37,0,0,0,0,0,'Ba Sing Se House 24',1,26,162000,0,0,1,45,0,0,0,0,0,0),(38,0,0,0,0,0,'Ba Sing Se House 25',1,26,162000,0,0,1,45,0,0,0,0,0,0),(39,0,0,0,0,0,'Ba Sing Se House 26',1,61,378000,0,0,2,111,0,0,0,0,0,0),(40,0,0,0,0,0,'Ba Sing Se House 28',1,79,492000,0,0,3,137,0,0,0,0,0,0),(41,0,0,0,0,0,'Ba Sing Se House 29',1,68,426000,0,0,3,134,0,0,0,0,0,0),(42,0,0,0,0,0,'Ba Sing Se House 30',1,38,234000,0,0,1,66,0,0,0,0,0,0),(43,0,0,0,0,0,'Ba Sing Se House 31',1,63,396000,0,0,3,119,0,0,0,0,0,0),(44,0,0,0,0,0,'Ba Sing Se House 32',1,18,114000,0,0,1,47,0,0,0,0,0,0),(45,0,0,0,0,0,'Ba Sing Se House 33',1,12,78000,0,0,1,24,0,0,0,0,0,0),(46,0,0,0,0,0,'Ba Sing Se House 34',1,12,78000,0,0,1,36,0,0,0,0,0,0),(47,0,0,0,0,0,'Ba Sing Se House 35',1,84,516000,0,0,2,150,0,0,0,0,0,0),(49,0,0,0,0,0,'Ba Sing Se House 36',1,22,138000,0,0,1,36,0,0,0,0,0,0),(50,0,0,0,0,0,'Ba Sing Se House 38',1,16,96000,0,0,0,36,0,0,0,0,0,0),(51,0,0,0,0,0,'Ba Sing Se House 39',1,22,132000,0,0,0,53,0,0,0,0,0,0),(54,0,0,0,0,0,'Ba Sing Se House 40',1,29,174000,0,0,0,64,0,0,0,0,0,0),(55,0,0,0,0,0,'Ba Sing Se House 41',1,56,336000,0,0,0,98,0,0,0,0,0,0),(56,0,0,0,0,0,'Ba Sing Se House 42',1,69,414000,0,0,0,120,0,0,0,0,0,0),(57,0,0,0,0,0,'Ba Sing Se House 43',1,26,156000,0,0,0,57,0,0,0,0,0,0),(58,0,0,0,0,0,'Ba Sing Se House 44',1,15,90000,0,0,0,35,0,0,0,0,0,0),(59,0,0,0,0,0,'Ba Sing Se House 45',1,68,408000,0,0,0,119,0,0,0,0,0,0),(60,0,0,0,0,0,'Ba Sing Se House 46',1,12,72000,0,0,0,32,0,0,0,0,0,0),(68,0,0,0,0,0,'South Air Temple House 1',3,14,90000,0,0,1,36,0,0,0,0,0,0),(69,0,0,0,0,0,'South Air Temple House 2',3,14,90000,0,0,1,36,0,0,0,0,0,0),(70,0,0,0,0,0,'South Air Temple House 3',3,14,90000,0,0,1,36,0,0,0,0,0,0),(71,0,0,0,0,0,'South Air Temple House 4',3,14,90000,0,0,1,36,0,0,0,0,0,0),(72,0,0,0,0,0,'South Air Temple House 5',3,16,102000,0,0,1,40,0,0,0,0,0,0),(73,0,0,0,0,0,'South Air Temple House 6',3,7,48000,0,0,1,20,0,0,0,0,0,0),(74,0,0,0,0,0,'South Air Temple House 7',3,13,84000,0,0,1,35,0,0,0,0,0,0),(75,0,0,0,0,0,'South Air Temple House 8',3,6,42000,0,0,1,24,0,0,0,0,0,0),(77,0,0,0,0,0,'South Air Temple House 10',3,14,90000,0,0,1,36,0,0,0,0,0,0),(78,0,0,0,0,0,'South Air Temple House 11',3,14,90000,0,0,1,36,0,0,0,0,0,0),(79,0,0,0,0,0,'South Air Temple House 12',3,14,90000,0,0,1,36,0,0,0,0,0,0),(80,0,0,0,0,0,'South Air Temple House 13',3,10,66000,0,0,1,25,0,0,0,0,0,0),(81,0,0,0,0,0,'South Air Temple House 14',3,10,66000,0,0,1,30,0,0,0,0,0,0),(82,0,0,0,0,0,'South Air Temple House 15',3,8,54000,0,0,1,16,0,0,0,0,0,0),(83,0,0,0,0,0,'South Air Temple House 16',3,8,54000,0,0,1,16,0,0,0,0,0,0),(84,0,0,0,0,0,'South Air Temple House 17',3,10,66000,0,0,1,30,0,0,0,0,0,0),(85,0,0,0,0,0,'South Air Temple House 18',3,8,54000,0,0,1,16,0,0,0,0,0,0),(86,0,0,0,0,0,'South Air Temple House 19',3,13,84000,0,0,1,35,0,0,0,0,0,0),(87,0,0,0,0,0,'South Air Temple House 20',3,8,54000,0,0,1,16,0,0,0,0,0,0),(88,0,0,0,0,0,'South Air Temple House 21',3,8,54000,0,0,1,16,0,0,0,0,0,0),(89,0,0,0,0,0,'South Air Temple House 22',3,8,54000,0,0,1,20,0,0,0,0,0,0),(90,0,0,0,0,0,'South Air Temple House 23',3,21,138000,0,0,2,35,0,0,0,0,0,0),(91,0,0,0,0,0,'South Air Temple House 24',3,11,72000,0,0,1,20,0,0,0,0,0,0),(92,0,0,0,0,0,'South Air Temple House 25',3,15,96000,0,0,1,30,0,0,0,0,0,0),(93,0,0,0,0,0,'South Air Temple House 26',3,3,24000,0,0,1,15,0,0,0,0,0,0),(94,0,0,0,0,0,'South Air Temple House 27',3,7,48000,0,0,1,16,0,0,0,0,0,0),(96,0,0,0,0,0,'North Water Tribe House 9',4,18,114000,0,0,1,44,0,0,0,0,0,0),(97,0,0,0,0,0,'North Water Tribe House 10',4,21,132000,0,0,1,39,0,0,0,0,0,0),(98,0,0,0,0,0,'North Water Tribe House 11',4,13,84000,0,0,1,24,0,0,0,0,0,0),(99,0,0,0,0,0,'North Water Tribe House 12',4,12,78000,0,0,1,18,0,0,0,0,0,0),(100,0,0,0,0,0,'North Water Tribe House 1',4,26,162000,0,0,1,39,0,0,0,0,0,0),(101,0,0,0,0,0,'North Water Tribe House 2',4,26,162000,0,0,1,47,0,0,0,0,0,0),(102,0,0,0,0,0,'North Water Tribe House 3',4,56,348000,0,0,2,91,0,0,0,0,0,0),(103,0,0,0,0,0,'North Water Tribe House 4',4,10,66000,0,0,1,21,0,0,0,0,0,0),(104,0,0,0,0,0,'North Water Tribe House 5',4,12,78000,0,0,1,24,0,0,0,0,0,0),(105,0,0,0,0,0,'North Water Tribe House 6',4,28,174000,0,0,1,54,0,0,0,0,0,0),(106,0,0,0,0,0,'North Water Tribe House 7',4,14,90000,0,0,1,26,0,0,0,0,0,0),(107,0,0,0,0,0,'North Water Tribe House 8',4,13,84000,0,0,1,20,0,0,0,0,0,0),(108,0,0,0,0,0,'Fire Nation Capital House 1',5,24,144000,0,0,0,60,0,0,0,0,0,0),(109,0,0,0,0,0,'Fire Nation Capital House 2',5,24,144000,0,0,0,60,0,0,0,0,0,0),(110,0,0,0,0,0,'Fire Nation Capital House 3',5,45,282000,0,0,2,85,0,0,0,0,0,0),(111,0,0,0,0,0,'Fire Nation Capital House 4',5,45,282000,0,0,2,85,0,0,0,0,0,0),(112,0,0,0,0,0,'Fire Nation Capital House 5',5,13,84000,0,1,1,35,0,0,0,0,0,0),(113,0,0,0,0,0,'Fire Nation Capital House 6',5,14,90000,0,1,1,36,0,0,0,0,0,0),(114,0,0,0,0,0,'Fire Nation Capital House 7',5,7,48000,0,1,1,25,0,0,0,0,0,0),(115,0,0,0,0,0,'Fire Nation Capital House 8',5,4,30000,0,1,1,20,0,0,0,0,0,0),(116,0,0,0,0,0,'Fire Nation Capital House 9',5,10,66000,0,1,1,30,0,0,0,0,0,0),(117,0,0,0,0,0,'Fire Nation Capital House 10',5,8,54000,0,1,1,28,0,0,0,0,0,0),(118,0,0,0,0,0,'Fire Nation Capital House 11',5,36,228000,0,0,2,71,0,0,0,0,0,0),(119,0,0,0,0,0,'Fire Nation Capital House 12',5,104,642000,0,0,3,187,0,0,0,0,0,0),(120,0,0,0,0,0,'Fire Nation Capital House 13',5,46,282000,0,0,1,83,0,0,0,0,0,0),(121,0,0,0,0,0,'Fire Nation Capital House 14',5,46,282000,0,0,1,83,0,0,0,0,0,0),(122,0,0,0,0,0,'Fire Nation Capital House 15',5,24,156000,0,0,2,40,0,0,0,0,0,0),(123,0,0,0,0,0,'Fire Nation Capital House 16',5,16,102000,0,0,1,38,0,0,0,0,0,0),(124,0,0,0,0,0,'Fire Nation Capital House 17',5,69,426000,0,0,2,120,0,0,0,0,0,0),(125,0,0,0,0,0,'Fire Nation Capital House 18',5,50,306000,0,0,1,95,0,0,0,0,0,0),(126,0,0,0,0,0,'Fire Nation Capital House 19',5,58,354000,0,0,1,111,0,0,0,0,0,0),(127,0,0,0,0,0,'Fire Nation Capital House 20',5,70,426000,0,0,1,124,0,0,0,0,0,0),(128,0,0,0,0,0,'Fire Nation Capital House 21',5,21,132000,0,0,1,48,0,0,0,0,0,0),(129,0,0,0,0,0,'Fire Nation Capital House 22',5,21,132000,0,0,1,35,0,0,0,0,0,0),(130,0,0,0,0,0,'Fire Nation Capital House 23',5,13,84000,0,0,1,28,0,0,0,0,0,0),(131,0,0,0,0,0,'Fire Nation Capital House 24',5,164,1014000,0,0,5,294,0,0,0,0,0,0),(132,0,0,0,0,0,'Fire Nation Capital House 25',5,14,90000,0,0,1,29,0,0,0,0,0,0),(133,0,0,0,0,0,'Fire Nation Capital House 26',5,14,90000,0,0,1,30,0,0,0,0,0,0),(134,0,0,0,0,0,'Fire Nation Capital House 27',5,14,90000,0,0,1,29,0,0,0,0,0,0),(135,0,0,0,0,0,'Fire Nation Capital House 28',5,14,90000,0,0,1,29,0,0,0,0,0,0),(136,0,0,0,0,0,'Fire Nation Capital House 29',5,12,78000,0,0,1,34,0,0,0,0,0,0),(137,0,0,0,0,0,'Fire Nation Capital House 30',5,50,318000,0,0,3,77,0,0,0,0,0,0),(138,0,0,0,0,0,'Fire Nation Capital House 31',5,16,102000,0,0,1,21,0,0,0,0,0,0),(139,0,0,0,0,0,'Fire Nation Capital House 32',5,82,504000,0,0,2,140,0,0,0,0,0,0),(147,0,0,0,0,0,'Ba Sing Se House 51',1,82,516000,0,0,4,137,0,0,0,0,0,0),(148,0,0,0,0,0,'Ba Sing Se House 52',1,63,390000,0,0,2,111,0,0,0,0,0,0),(149,0,0,0,0,0,'Ba Sing Se House 53',1,72,444000,0,0,2,120,0,0,0,0,0,0),(150,0,0,0,0,0,'Ba Sing Se House 54',1,29,180000,0,0,1,49,0,0,0,0,0,0),(151,0,0,0,0,0,'Ba Sing Se House 55',1,19,120000,0,0,1,37,0,0,0,0,0,0),(152,0,0,0,0,0,'Ba Sing Se House 56',1,16,102000,0,0,1,24,0,0,0,0,0,0),(153,0,0,0,0,0,'Ba Sing Se House 57',1,19,120000,0,0,1,37,0,0,0,0,0,0),(154,0,0,0,0,0,'Ba Sing Se House 58',1,19,120000,0,0,1,40,0,0,0,0,0,0),(155,0,0,0,0,0,'Ba Sing Se House 59',1,16,102000,0,0,1,24,0,0,0,0,0,0),(156,0,0,0,0,0,'Ba Sing Se House 60',1,19,120000,0,0,1,37,0,0,0,0,0,0),(157,0,0,0,0,0,'Ba Sing Se House 61',1,19,120000,0,0,1,37,0,0,0,0,0,0),(158,0,0,0,0,0,'Ba Sing Se House 62',1,19,120000,0,0,1,32,0,0,0,0,0,0),(159,0,0,0,0,0,'Ba Sing Se House 63',1,16,102000,0,0,1,21,0,0,0,0,0,0),(160,0,0,0,0,0,'Ba Sing Se House 64',1,16,102000,0,0,1,24,0,0,0,0,0,0),(161,0,0,0,0,0,'Ba Sing Se House 65',1,19,120000,0,0,1,30,0,0,0,0,0,0),(162,0,0,0,0,0,'Ba Sing Se House 66',1,19,120000,0,0,1,25,0,0,0,0,0,0),(164,0,0,0,0,0,'Unnamed House #164',3,6,36000,0,1,0,12,0,0,0,0,0,0),(166,0,0,0,0,0,'Unnamed House #166',5,6,36000,0,1,0,12,0,0,0,0,0,0),(167,0,0,0,0,0,'Unnamed House #167',4,6,36000,0,1,0,12,0,0,0,0,0,0),(168,0,0,0,0,0,'Ba Sing Se House 67',1,27,180000,0,0,3,65,0,0,0,0,0,0),(169,0,0,0,0,0,'Ba Sing Se House 68',1,34,216000,0,0,2,73,0,0,0,0,0,0),(171,0,0,0,0,0,'Ba Sing Se House 69',1,22,138000,0,0,1,41,0,0,0,0,0,0),(172,0,0,0,0,0,'Unnamed House #172',1,6,36000,0,1,0,12,0,0,0,0,0,0);
/*!40000 ALTER TABLE `houses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ip_bans`
--

DROP TABLE IF EXISTS `ip_bans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ip_bans` (
  `ip` int(10) unsigned NOT NULL,
  `reason` varchar(255) NOT NULL,
  `banned_at` bigint(20) NOT NULL,
  `expires_at` bigint(20) NOT NULL,
  `banned_by` int(11) NOT NULL,
  PRIMARY KEY (`ip`),
  KEY `banned_by` (`banned_by`),
  CONSTRAINT `ip_bans_ibfk_1` FOREIGN KEY (`banned_by`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ip_bans`
--

LOCK TABLES `ip_bans` WRITE;
/*!40000 ALTER TABLE `ip_bans` DISABLE KEYS */;
/*!40000 ALTER TABLE `ip_bans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `killers`
--

DROP TABLE IF EXISTS `killers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `killers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `death_id` int(11) NOT NULL,
  `final_hit` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `unjustified` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `war` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `death_id` (`death_id`),
  CONSTRAINT `killers_ibfk_1` FOREIGN KEY (`death_id`) REFERENCES `player_deaths` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `killers`
--

LOCK TABLES `killers` WRITE;
/*!40000 ALTER TABLE `killers` DISABLE KEYS */;
INSERT INTO `killers` VALUES (1,1,1,0,0),(2,2,1,0,0),(3,3,1,0,0),(4,4,1,0,0),(5,5,1,0,0),(6,5,0,0,0),(7,6,1,0,0),(8,7,1,0,0),(9,7,0,0,0),(10,8,1,0,0),(11,9,1,0,0),(12,10,1,0,0),(13,11,1,0,0),(14,12,1,0,0),(15,13,1,0,0),(16,14,1,0,0),(17,15,1,0,0),(18,15,0,0,0),(19,16,1,0,0),(20,17,1,0,0),(21,18,1,0,0),(22,19,1,0,0),(23,20,1,0,0),(24,21,1,0,0),(25,22,1,0,0),(26,23,1,0,0),(27,24,1,0,0),(28,25,1,0,0),(29,26,1,0,0),(30,27,1,0,0),(31,27,0,0,0),(32,28,1,0,0),(33,28,0,0,0),(34,29,1,0,0),(35,29,0,0,0),(36,30,1,0,0),(37,31,1,0,0),(38,32,1,0,0),(39,32,0,0,0),(40,33,1,0,0),(41,33,0,0,0),(42,34,1,0,0),(43,35,1,0,0),(44,36,1,0,0),(45,37,1,0,0),(46,38,1,0,0),(47,39,1,0,0),(48,39,0,0,0),(49,40,1,0,0),(50,41,1,0,0);
/*!40000 ALTER TABLE `killers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `login_history`
--

DROP TABLE IF EXISTS `login_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `login_history` (
  `account_id` int(11) NOT NULL DEFAULT 0,
  `player_id` int(11) NOT NULL DEFAULT 0,
  `type` tinyint(1) NOT NULL DEFAULT 0,
  `login` tinyint(1) NOT NULL DEFAULT 0,
  `ip` int(11) NOT NULL DEFAULT 0,
  `date` int(11) NOT NULL DEFAULT 0,
  KEY `player_id` (`player_id`),
  CONSTRAINT `login_history_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `login_history`
--

LOCK TABLES `login_history` WRITE;
/*!40000 ALTER TABLE `login_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `login_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `market_history`
--

DROP TABLE IF EXISTS `market_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `market_history` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `sale` tinyint(1) NOT NULL DEFAULT 0,
  `itemtype` int(10) unsigned NOT NULL,
  `amount` smallint(5) unsigned NOT NULL,
  `price` int(10) unsigned NOT NULL DEFAULT 0,
  `expires_at` bigint(20) unsigned NOT NULL,
  `inserted` bigint(20) unsigned NOT NULL,
  `state` tinyint(1) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `player_id` (`player_id`,`sale`),
  CONSTRAINT `market_history_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `market_history`
--

LOCK TABLES `market_history` WRITE;
/*!40000 ALTER TABLE `market_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `market_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `market_offers`
--

DROP TABLE IF EXISTS `market_offers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `market_offers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `sale` tinyint(1) NOT NULL DEFAULT 0,
  `itemtype` int(10) unsigned NOT NULL,
  `amount` smallint(5) unsigned NOT NULL,
  `created` bigint(20) unsigned NOT NULL,
  `anonymous` tinyint(1) NOT NULL DEFAULT 0,
  `price` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `sale` (`sale`,`itemtype`),
  KEY `created` (`created`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `market_offers_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `market_offers`
--

LOCK TABLES `market_offers` WRITE;
/*!40000 ALTER TABLE `market_offers` DISABLE KEYS */;
/*!40000 ALTER TABLE `market_offers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pagsegurotransacoes`
--

DROP TABLE IF EXISTS `pagsegurotransacoes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pagsegurotransacoes` (
  `TransacaoID` varchar(36) NOT NULL,
  `VendedorEmail` varchar(200) NOT NULL,
  `Referencia` varchar(200) DEFAULT NULL,
  `TipoFrete` char(2) DEFAULT NULL,
  `ValorFrete` decimal(10,2) DEFAULT NULL,
  `Extras` decimal(10,2) DEFAULT NULL,
  `Anotacao` text DEFAULT NULL,
  `TipoPagamento` varchar(50) NOT NULL,
  `StatusTransacao` varchar(50) NOT NULL,
  `CliNome` varchar(200) NOT NULL,
  `CliEmail` varchar(200) NOT NULL,
  `CliEndereco` varchar(200) NOT NULL,
  `CliNumero` varchar(10) DEFAULT NULL,
  `CliComplemento` varchar(100) DEFAULT NULL,
  `CliBairro` varchar(100) NOT NULL,
  `CliCidade` varchar(100) NOT NULL,
  `CliEstado` char(2) NOT NULL,
  `CliCEP` varchar(9) NOT NULL,
  `CliTelefone` varchar(14) DEFAULT NULL,
  `NumItens` int(11) NOT NULL,
  `Data` datetime NOT NULL,
  `ProdQuantidade_x` int(5) NOT NULL,
  `status` tinyint(1) unsigned NOT NULL DEFAULT 0,
  UNIQUE KEY `TransacaoID` (`TransacaoID`,`StatusTransacao`),
  KEY `Referencia` (`Referencia`),
  KEY `status` (`status`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pagsegurotransacoes`
--

LOCK TABLES `pagsegurotransacoes` WRITE;
/*!40000 ALTER TABLE `pagsegurotransacoes` DISABLE KEYS */;
/*!40000 ALTER TABLE `pagsegurotransacoes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_advances`
--

DROP TABLE IF EXISTS `player_advances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_advances` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) DEFAULT NULL,
  `skill` int(11) DEFAULT NULL,
  `oldlevel` int(11) DEFAULT NULL,
  `newlevel` int(11) DEFAULT NULL,
  `time` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cid` (`cid`),
  CONSTRAINT `player_advances_ibfk_1` FOREIGN KEY (`cid`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_advances`
--

LOCK TABLES `player_advances` WRITE;
/*!40000 ALTER TABLE `player_advances` DISABLE KEYS */;
/*!40000 ALTER TABLE `player_advances` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_creature_manager`
--

DROP TABLE IF EXISTS `player_creature_manager`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_creature_manager` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `creature_name` varchar(255) NOT NULL,
  `custom_name` varchar(255) NOT NULL,
  `stage` int(11) NOT NULL DEFAULT 1,
  `last_train` bigint(20) NOT NULL DEFAULT 0,
  `watered_stage` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_creature_manager_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_creature_manager`
--

LOCK TABLES `player_creature_manager` WRITE;
/*!40000 ALTER TABLE `player_creature_manager` DISABLE KEYS */;
INSERT INTO `player_creature_manager` VALUES (1,2,'Fire Seed','Fire Fruit Plant',3,1785241178,0),(2,2,'Earth Seed','Earth Fruit Plant',3,1785241200,0),(3,2,'Air Seed','Air Fruit Plant',3,1785241221,0),(4,2,'Water Seed','Water Fruit Plant',3,1785241218,0),(5,2,'Fire Seed','Fire Seedling',1,1785253911,0);
/*!40000 ALTER TABLE `player_creature_manager` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_deaths`
--

DROP TABLE IF EXISTS `player_deaths`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_deaths` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `date` bigint(20) unsigned NOT NULL,
  `level` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `date` (`date`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_deaths_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_deaths`
--

LOCK TABLES `player_deaths` WRITE;
/*!40000 ALTER TABLE `player_deaths` DISABLE KEYS */;
INSERT INTO `player_deaths` VALUES (1,3,1784862397,16),(2,3,1785044039,15),(3,3,1785336334,15),(4,3,1785336405,16),(5,3,1785336548,17),(6,3,1785551783,20),(7,3,1785793067,20),(8,3,1785793117,19),(9,6,1786070460,8),(10,6,1786071175,18),(11,6,1786071408,18),(12,5,1786142287,19),(13,5,1786142420,19),(14,5,1786142808,18),(15,5,1786143232,18),(16,5,1786143586,18),(17,5,1786144147,17),(18,5,1786144226,17),(19,5,1786144391,17),(20,5,1786144577,16),(21,5,1786144857,16),(22,5,1786145076,16),(23,5,1786145105,16),(24,5,1786145129,15),(25,5,1786145153,15),(26,5,1786146432,15),(27,5,1786146543,14),(28,4,1786175032,14),(29,6,1786220263,27),(30,3,1786228855,19),(31,5,1786241118,14),(32,5,1786392518,550),(33,5,1786393410,546),(34,4,1786481756,29),(35,4,1786483410,29),(36,4,1786484300,29),(37,4,1786487969,29),(38,6,1786500364,27),(39,4,1786598995,60),(40,4,1786604816,61),(41,4,1786605273,60);
/*!40000 ALTER TABLE `player_deaths` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_depotitems`
--

DROP TABLE IF EXISTS `player_depotitems`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_depotitems` (
  `player_id` int(11) NOT NULL,
  `sid` int(11) NOT NULL COMMENT 'any given range, eg. 0-100 is reserved for depot lockers and all above 100 will be normal items inside depots',
  `pid` int(11) NOT NULL DEFAULT 0,
  `itemtype` int(11) NOT NULL,
  `count` int(11) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL,
  UNIQUE KEY `player_id_2` (`player_id`,`sid`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_depotitems_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_depotitems`
--

LOCK TABLES `player_depotitems` WRITE;
/*!40000 ALTER TABLE `player_depotitems` DISABLE KEYS */;
INSERT INTO `player_depotitems` VALUES (2,101,0,2589,1,''),(2,102,1,2589,1,''),(2,103,101,18358,1,''),(2,104,101,2594,1,''),(2,105,102,2594,1,''),(2,106,104,13734,1,'€\0\0description\0\0\0\0\0price\n\0\0\0Unsellable'),(2,107,104,2498,1,'€\0\0armor\0\0\0\0description3\0\0\0[Armor: +27%]\nAn excellent masterpiece of a smith. \0name\0\0\0rare royal helmet'),(2,108,104,13732,1,''),(2,109,104,13733,1,''),(2,110,104,18338,3500,'€\0\0charges¬\r\0\0'),(2,111,104,18338,3500,'€\0\0charges¬\r\0\0'),(2,112,104,18338,3500,'€\0\0charges¬\r\0\0\0descriptionQ\0\0\0Use it on an Exercise Dummy to train your magic level. Consumes 1 charge per hit.\0price\n\0\0\0Unsellable'),(2,113,104,18338,3500,'€\0\0charges¬\r\0\0'),(2,114,104,18338,3500,'€\0\0charges¬\r\0\0'),(2,115,104,18338,3500,'€\0\0charges¬\r\0\0'),(2,116,104,18338,3500,'€\0\0charges¬\r\0\0'),(2,117,104,18338,3500,'€\0\0charges¬\r\0\0'),(2,118,104,18338,3500,'€\0\0charges¬\r\0\0'),(2,119,104,18337,3500,'€\0\0charges¬\r\0\0'),(2,120,104,18337,3500,'€\0\0charges¬\r\0\0\0descriptionQ\0\0\0Use it on an Exercise Dummy to train your magic level. Consumes 1 charge per hit.\0price\n\0\0\0Unsellable'),(2,121,104,18337,3500,'€\0\0charges¬\r\0\0'),(2,122,104,18337,3500,'€\0\0charges¬\r\0\0'),(2,123,104,18337,3500,'€\0\0charges¬\r\0\0\0descriptionQ\0\0\0Use it on an Exercise Dummy to train your magic level. Consumes 1 charge per hit.\0price\n\0\0\0Unsellable'),(2,124,104,18337,3500,'€\0\0charges¬\r\0\0'),(2,125,104,18337,3500,'€\0\0charges¬\r\0\0\0descriptionQ\0\0\0Use it on an Exercise Dummy to train your magic level. Consumes 1 charge per hit.\0price\n\0\0\0Unsellable'),(2,126,104,18337,3500,'€\0\0charges¬\r\0\0'),(2,127,104,18337,3500,'€\0\0charges¬\r\0\0'),(2,128,104,18337,3500,'€\0\0charges¬\r\0\0\0descriptionQ\0\0\0Use it on an Exercise Dummy to train your magic level. Consumes 1 charge per hit.\0price\n\0\0\0Unsellable'),(3,101,0,2589,1,''),(3,102,101,2594,1,''),(3,103,101,18358,1,''),(5,101,0,2589,1,''),(5,102,101,2594,1,''),(5,103,101,18358,1,''),(5,104,102,2148,78,'N'),(5,105,102,11192,2,''),(5,106,102,2152,4,''),(5,107,102,2394,1,''),(5,108,102,2129,1,''),(5,109,102,2394,1,''),(5,110,102,2394,1,''),(5,111,102,2129,1,''),(5,112,102,2394,1,''),(5,113,102,2513,1,'€\0\0description\0\0\0Price: 75 gold.\0priceK\0\0\0'),(5,114,102,7452,1,'€\0\0description\0\0\0Price: 750 gold.\0priceî\0\0');
/*!40000 ALTER TABLE `player_depotitems` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_depotlockeritems`
--

DROP TABLE IF EXISTS `player_depotlockeritems`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_depotlockeritems` (
  `player_id` int(11) NOT NULL,
  `sid` int(11) NOT NULL COMMENT 'any given range eg 0-100 will be reserved for depot lockers and all > 100 will be then normal items inside depots',
  `pid` int(11) NOT NULL DEFAULT 0,
  `itemtype` smallint(6) NOT NULL,
  `count` smallint(6) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL,
  UNIQUE KEY `player_id_2` (`player_id`,`sid`),
  CONSTRAINT `player_depotlockeritems_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_depotlockeritems`
--

LOCK TABLES `player_depotlockeritems` WRITE;
/*!40000 ALTER TABLE `player_depotlockeritems` DISABLE KEYS */;
/*!40000 ALTER TABLE `player_depotlockeritems` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_inboxitems`
--

DROP TABLE IF EXISTS `player_inboxitems`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_inboxitems` (
  `player_id` int(11) NOT NULL,
  `sid` int(11) NOT NULL,
  `pid` int(11) NOT NULL DEFAULT 0,
  `itemtype` smallint(5) unsigned NOT NULL,
  `count` smallint(6) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL,
  UNIQUE KEY `player_id_2` (`player_id`,`sid`),
  CONSTRAINT `player_inboxitems_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_inboxitems`
--

LOCK TABLES `player_inboxitems` WRITE;
/*!40000 ALTER TABLE `player_inboxitems` DISABLE KEYS */;
/*!40000 ALTER TABLE `player_inboxitems` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_items`
--

DROP TABLE IF EXISTS `player_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_items` (
  `player_id` int(11) NOT NULL,
  `pid` int(11) NOT NULL DEFAULT 0,
  `sid` int(11) NOT NULL DEFAULT 0,
  `itemtype` int(11) NOT NULL DEFAULT 0,
  `count` int(11) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL,
  UNIQUE KEY `player_id_2` (`player_id`,`sid`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_items_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_items`
--

LOCK TABLES `player_items` WRITE;
/*!40000 ALTER TABLE `player_items` DISABLE KEYS */;
INSERT INTO `player_items` VALUES (2,1,101,13731,1,''),(2,3,102,1988,1,''),(2,4,103,13732,1,''),(2,5,104,13412,1,''),(2,6,105,2389,12,''),(2,7,106,13733,1,''),(2,8,107,13734,1,''),(2,102,108,2428,1,''),(2,102,109,3963,1,''),(2,102,110,7379,1,''),(2,102,111,1998,1,''),(2,102,112,2002,1,''),(2,102,113,2428,1,''),(2,102,114,3963,1,''),(2,102,115,7379,1,''),(2,102,116,1998,1,''),(2,102,117,2002,1,''),(2,102,118,2428,1,''),(2,102,119,3963,1,''),(2,102,120,7379,1,''),(2,102,121,1998,1,''),(2,102,122,7620,33,'!'),(2,102,123,2148,30,''),(2,102,124,18146,7,''),(2,102,125,7425,1,''),(2,102,126,13092,1,''),(2,102,127,4864,1,''),(2,111,128,2428,1,''),(2,111,129,3963,1,''),(2,111,130,7379,1,''),(2,111,131,1998,1,''),(2,111,132,2002,1,''),(2,111,133,2428,1,''),(2,111,134,3963,1,''),(2,111,135,7379,1,''),(2,111,136,1998,1,''),(2,111,137,2002,1,''),(2,111,138,2428,1,''),(2,111,139,3963,1,''),(2,111,140,7379,1,''),(2,111,141,1998,1,''),(2,111,142,2002,1,''),(2,111,143,2428,1,''),(2,111,144,3963,1,''),(2,111,145,7379,1,''),(2,111,146,1998,1,''),(2,111,147,2002,1,''),(2,112,148,2428,1,''),(2,112,149,3963,1,''),(2,112,150,7379,1,''),(2,112,151,1998,1,''),(2,112,152,2002,1,''),(2,112,153,2428,1,''),(2,112,154,3963,1,''),(2,112,155,7379,1,''),(2,112,156,1998,1,''),(2,112,157,2002,1,''),(2,112,158,2428,1,''),(2,112,159,3963,1,''),(2,112,160,7379,1,''),(2,112,161,1998,1,''),(2,112,162,2002,1,''),(2,112,163,2428,1,''),(2,112,164,3963,1,''),(2,112,165,7379,1,''),(2,112,166,1998,1,''),(2,112,167,2002,1,''),(2,116,168,2428,1,''),(2,116,169,3963,1,''),(2,116,170,7379,1,''),(2,116,171,1998,1,''),(2,116,172,2002,1,''),(2,116,173,2428,1,''),(2,116,174,3963,1,''),(2,116,175,7379,1,''),(2,116,176,1998,1,''),(2,116,177,2002,1,''),(2,116,178,2428,1,''),(2,116,179,3963,1,''),(2,116,180,7379,1,''),(2,116,181,1998,1,''),(2,116,182,2002,1,''),(2,116,183,2428,1,''),(2,116,184,3963,1,''),(2,116,185,7379,1,''),(2,116,186,1998,1,''),(2,116,187,2002,1,''),(2,117,188,2428,1,''),(2,117,189,3963,1,''),(2,117,190,7379,1,''),(2,117,191,1998,1,''),(2,117,192,2002,1,''),(2,117,193,2428,1,''),(2,117,194,3963,1,''),(2,117,195,7379,1,''),(2,117,196,1998,1,''),(2,117,197,2002,1,''),(2,117,198,2428,1,''),(2,117,199,3963,1,''),(2,117,200,7379,1,''),(2,117,201,1998,1,''),(2,117,202,2002,1,''),(2,117,203,2428,1,''),(2,117,204,3963,1,''),(2,117,205,7379,1,''),(2,117,206,1998,1,''),(2,117,207,2002,1,''),(2,121,208,2428,1,''),(2,121,209,3963,1,''),(2,121,210,7379,1,''),(2,121,211,1998,1,''),(2,121,212,2002,1,''),(2,121,213,2428,1,''),(2,121,214,3963,1,''),(2,121,215,7379,1,''),(2,121,216,1998,1,''),(2,121,217,2002,1,''),(2,121,218,2428,1,''),(2,121,219,3963,1,''),(2,121,220,7379,1,''),(2,121,221,1998,1,''),(2,121,222,2002,1,''),(2,121,223,2428,1,''),(2,121,224,3963,1,''),(2,121,225,7379,1,''),(2,121,226,1998,1,''),(2,121,227,2002,1,''),(2,131,228,2428,1,''),(2,131,229,3963,1,''),(2,131,230,7379,1,''),(2,131,231,1998,1,''),(2,131,232,2002,1,''),(2,131,233,2428,1,''),(2,131,234,3963,1,''),(2,131,235,7379,1,''),(2,131,236,1998,1,''),(2,131,237,2002,1,''),(2,131,238,2428,1,''),(2,131,239,3963,1,''),(2,131,240,7379,1,''),(2,131,241,1998,1,''),(2,131,242,2002,1,''),(2,131,243,2428,1,''),(2,131,244,3963,1,''),(2,131,245,7379,1,''),(2,131,246,1998,1,''),(2,131,247,2002,1,''),(2,132,248,2428,1,''),(2,132,249,3963,1,''),(2,132,250,7379,1,''),(2,132,251,1998,1,''),(2,132,252,2002,1,''),(2,132,253,2428,1,''),(2,132,254,3963,1,''),(2,132,255,7379,1,''),(2,132,256,1998,1,''),(2,132,257,2002,1,''),(2,132,258,2428,1,''),(2,132,259,3963,1,''),(2,132,260,7379,1,''),(2,132,261,1998,1,''),(2,132,262,2002,1,''),(2,132,263,2428,1,''),(2,132,264,3963,1,''),(2,132,265,7379,1,''),(2,132,266,1998,1,''),(2,132,267,2002,1,''),(2,136,268,2428,1,''),(2,136,269,3963,1,''),(2,136,270,7379,1,''),(2,136,271,1998,1,''),(2,136,272,2002,1,''),(2,136,273,2428,1,''),(2,136,274,3963,1,''),(2,136,275,7379,1,''),(2,136,276,1998,1,''),(2,136,277,2002,1,''),(2,136,278,2428,1,''),(2,136,279,3963,1,''),(2,136,280,7379,1,''),(2,136,281,1998,1,''),(2,136,282,2002,1,''),(2,136,283,2428,1,''),(2,136,284,3963,1,''),(2,136,285,7379,1,''),(2,136,286,1998,1,''),(2,136,287,2002,1,''),(2,137,288,2428,1,''),(2,137,289,3963,1,''),(2,137,290,7379,1,''),(2,137,291,1998,1,''),(2,137,292,2002,1,''),(2,137,293,2428,1,''),(2,137,294,3963,1,''),(2,137,295,7379,1,''),(2,137,296,1998,1,''),(2,137,297,2002,1,''),(2,137,298,2428,1,''),(2,137,299,3963,1,''),(2,137,300,7379,1,''),(2,137,301,1998,1,''),(2,137,302,2002,1,''),(2,137,303,2428,1,''),(2,137,304,3963,1,''),(2,137,305,7379,1,''),(2,137,306,1998,1,''),(2,137,307,2002,1,''),(2,141,308,2428,1,''),(2,141,309,3963,1,''),(2,141,310,7379,1,''),(2,141,311,1998,1,''),(2,141,312,2002,1,''),(2,141,313,2428,1,''),(2,141,314,3963,1,''),(2,141,315,7379,1,''),(2,141,316,1998,1,''),(2,141,317,2002,1,''),(2,141,318,2428,1,''),(2,141,319,3963,1,''),(2,141,320,7379,1,''),(2,141,321,1998,1,''),(2,141,322,2002,1,''),(2,141,323,2428,1,''),(2,141,324,3963,1,''),(2,141,325,7379,1,''),(2,141,326,1998,1,''),(2,141,327,2002,1,''),(2,142,328,2428,1,''),(2,142,329,3963,1,''),(2,142,330,7379,1,''),(2,142,331,1998,1,''),(2,142,332,2002,1,''),(2,142,333,2428,1,''),(2,142,334,3963,1,''),(2,142,335,7379,1,''),(2,142,336,1998,1,''),(2,142,337,2002,1,''),(2,142,338,2428,1,''),(2,142,339,3963,1,''),(2,142,340,7379,1,''),(2,142,341,1998,1,''),(2,142,342,2002,1,''),(2,142,343,2428,1,''),(2,142,344,3963,1,''),(2,142,345,7379,1,''),(2,142,346,1998,1,''),(2,142,347,2002,1,''),(2,146,348,2428,1,''),(2,146,349,3963,1,''),(2,146,350,7379,1,''),(2,146,351,1998,1,''),(2,146,352,2002,1,''),(2,146,353,2428,1,''),(2,146,354,3963,1,''),(2,146,355,7379,1,''),(2,146,356,1998,1,''),(2,146,357,2002,1,''),(2,146,358,2428,1,''),(2,146,359,3963,1,''),(2,146,360,7379,1,''),(2,146,361,1998,1,''),(2,146,362,2002,1,''),(2,146,363,2428,1,''),(2,146,364,3963,1,''),(2,146,365,7379,1,''),(2,146,366,1998,1,''),(2,146,367,2002,1,''),(2,147,368,2428,1,''),(2,147,369,3963,1,''),(2,147,370,7379,1,''),(2,147,371,1998,1,''),(2,147,372,2002,1,''),(2,147,373,2428,1,''),(2,147,374,3963,1,''),(2,147,375,7379,1,''),(2,147,376,1998,1,''),(2,147,377,2002,1,''),(2,147,378,2428,1,''),(2,147,379,3963,1,''),(2,147,380,7379,1,''),(2,147,381,1998,1,''),(2,147,382,2002,1,''),(2,147,383,2428,1,''),(2,147,384,3963,1,''),(2,147,385,7379,1,''),(2,147,386,1998,1,''),(2,147,387,2002,1,''),(2,151,388,2428,1,''),(2,151,389,3963,1,''),(2,151,390,7379,1,''),(2,151,391,1998,1,''),(2,151,392,2002,1,''),(2,151,393,2428,1,''),(2,151,394,3963,1,''),(2,151,395,7379,1,''),(2,151,396,1998,1,''),(2,151,397,2002,1,''),(2,151,398,2428,1,''),(2,151,399,3963,1,''),(2,151,400,7379,1,''),(2,151,401,1998,1,''),(2,151,402,2002,1,''),(2,151,403,2428,1,''),(2,151,404,3963,1,''),(2,151,405,7379,1,''),(2,151,406,1998,1,''),(2,151,407,2002,1,''),(2,152,408,2428,1,''),(2,152,409,3963,1,''),(2,152,410,7379,1,''),(2,152,411,1998,1,''),(2,152,412,2002,1,''),(2,152,413,2428,1,''),(2,152,414,3963,1,''),(2,152,415,7379,1,''),(2,152,416,1998,1,''),(2,152,417,2002,1,''),(2,152,418,2428,1,''),(2,152,419,3963,1,''),(2,152,420,7379,1,''),(2,152,421,1998,1,''),(2,152,422,2002,1,''),(2,152,423,2428,1,''),(2,152,424,3963,1,''),(2,152,425,7379,1,''),(2,152,426,1998,1,''),(2,152,427,2002,1,''),(2,156,428,2428,1,''),(2,156,429,3963,1,''),(2,156,430,7379,1,''),(2,156,431,1998,1,''),(2,156,432,2002,1,''),(2,156,433,2428,1,''),(2,156,434,3963,1,''),(2,156,435,7379,1,''),(2,156,436,1998,1,''),(2,156,437,2002,1,''),(2,156,438,2428,1,''),(2,156,439,3963,1,''),(2,156,440,7379,1,''),(2,156,441,1998,1,''),(2,156,442,2002,1,''),(2,156,443,2428,1,''),(2,156,444,3963,1,''),(2,156,445,7379,1,''),(2,156,446,1998,1,''),(2,156,447,2002,1,''),(2,157,448,2428,1,''),(2,157,449,3963,1,''),(2,157,450,7379,1,''),(2,157,451,1998,1,''),(2,157,452,2002,1,''),(2,157,453,2428,1,''),(2,157,454,3963,1,''),(2,157,455,7379,1,''),(2,157,456,1998,1,''),(2,157,457,2002,1,''),(2,157,458,2428,1,''),(2,157,459,3963,1,''),(2,157,460,7379,1,''),(2,157,461,1998,1,''),(2,157,462,2002,1,''),(2,157,463,2428,1,''),(2,157,464,3963,1,''),(2,157,465,7379,1,''),(2,157,466,1998,1,''),(2,157,467,2002,1,''),(2,161,468,2428,1,''),(2,161,469,3963,1,''),(2,161,470,7379,1,''),(2,161,471,1998,1,''),(2,161,472,2002,1,''),(2,161,473,2428,1,''),(2,161,474,3963,1,''),(2,161,475,7379,1,''),(2,161,476,1998,1,''),(2,161,477,2002,1,''),(2,161,478,2428,1,''),(2,161,479,3963,1,''),(2,161,480,7379,1,''),(2,161,481,1998,1,''),(2,161,482,2002,1,''),(2,161,483,2428,1,''),(2,161,484,3963,1,''),(2,161,485,7379,1,''),(2,161,486,1998,1,''),(2,161,487,2002,1,''),(2,162,488,2428,1,''),(2,162,489,3963,1,''),(2,162,490,7379,1,''),(2,162,491,1998,1,''),(2,162,492,2002,1,''),(2,162,493,2428,1,''),(2,162,494,3963,1,''),(2,162,495,7379,1,''),(2,162,496,1998,1,''),(2,162,497,2002,1,''),(2,162,498,2428,1,''),(2,162,499,3963,1,''),(2,162,500,7379,1,''),(2,162,501,1998,1,''),(2,162,502,2002,1,''),(2,162,503,2428,1,''),(2,162,504,3963,1,''),(2,162,505,7379,1,''),(2,162,506,1998,1,''),(2,162,507,2002,1,''),(2,166,508,2428,1,''),(2,166,509,3963,1,''),(2,166,510,7379,1,''),(2,166,511,1998,1,''),(2,166,512,2002,1,''),(2,166,513,2428,1,''),(2,166,514,3963,1,''),(2,166,515,7379,1,''),(2,166,516,1998,1,''),(2,166,517,2002,1,''),(2,166,518,2428,1,''),(2,166,519,3963,1,''),(2,166,520,7379,1,''),(2,166,521,1998,1,''),(2,166,522,2002,1,''),(2,166,523,2428,1,''),(2,166,524,3963,1,''),(2,166,525,7379,1,''),(2,166,526,1998,1,''),(2,166,527,2002,1,''),(2,167,528,2428,1,''),(2,167,529,3963,1,''),(2,167,530,7379,1,''),(2,167,531,1998,1,''),(2,167,532,2002,1,''),(2,167,533,2428,1,''),(2,167,534,3963,1,''),(2,167,535,7379,1,''),(2,167,536,1998,1,''),(2,167,537,2002,1,''),(2,167,538,2428,1,''),(2,167,539,3963,1,''),(2,167,540,7379,1,''),(2,167,541,1998,1,''),(2,167,542,2002,1,''),(2,167,543,2428,1,''),(2,167,544,3963,1,''),(2,167,545,7379,1,''),(2,167,546,1998,1,''),(2,167,547,2002,1,''),(2,171,548,2428,1,''),(2,171,549,3963,1,''),(2,171,550,7379,1,''),(2,171,551,1998,1,''),(2,171,552,2002,1,''),(2,171,553,2428,1,''),(2,171,554,3963,1,''),(2,171,555,7379,1,''),(2,171,556,1998,1,''),(2,171,557,2002,1,''),(2,171,558,2428,1,''),(2,171,559,3963,1,''),(2,171,560,7379,1,''),(2,171,561,1998,1,''),(2,171,562,2002,1,''),(2,171,563,2428,1,''),(2,171,564,3963,1,''),(2,171,565,7379,1,''),(2,171,566,1998,1,''),(2,171,567,2002,1,''),(2,172,568,2428,1,''),(2,172,569,3963,1,''),(2,172,570,7379,1,''),(2,172,571,1998,1,''),(2,172,572,2002,1,''),(2,172,573,2428,1,''),(2,172,574,3963,1,''),(2,172,575,7379,1,''),(2,172,576,1998,1,''),(2,172,577,2002,1,''),(2,172,578,2428,1,''),(2,172,579,3963,1,''),(2,172,580,7379,1,''),(2,172,581,1998,1,''),(2,172,582,2002,1,''),(2,172,583,2428,1,''),(2,172,584,3963,1,''),(2,172,585,7379,1,''),(2,172,586,1998,1,''),(2,172,587,2002,1,''),(2,176,588,2428,1,''),(2,176,589,3963,1,''),(2,176,590,7379,1,''),(2,176,591,1998,1,''),(2,176,592,2002,1,''),(2,176,593,2428,1,''),(2,176,594,3963,1,''),(2,176,595,7379,1,''),(2,176,596,1998,1,''),(2,176,597,2002,1,''),(2,176,598,2428,1,''),(2,176,599,3963,1,''),(2,176,600,7379,1,''),(2,176,601,1998,1,''),(2,176,602,2002,1,''),(2,176,603,2428,1,''),(2,176,604,3963,1,''),(2,176,605,7379,1,''),(2,176,606,1998,1,''),(2,176,607,2002,1,''),(2,177,608,2428,1,''),(2,177,609,3963,1,''),(2,177,610,7379,1,''),(2,177,611,1998,1,''),(2,177,612,2002,1,''),(2,177,613,2428,1,''),(2,177,614,3963,1,''),(2,177,615,7379,1,''),(2,177,616,1998,1,''),(2,177,617,2002,1,''),(2,177,618,2428,1,''),(2,177,619,3963,1,''),(2,177,620,7379,1,''),(2,177,621,1998,1,''),(2,177,622,2002,1,''),(2,177,623,2428,1,''),(2,177,624,3963,1,''),(2,177,625,7379,1,''),(2,177,626,1998,1,''),(2,177,627,2002,1,''),(2,181,628,2428,1,''),(2,181,629,3963,1,''),(2,181,630,7379,1,''),(2,181,631,1998,1,''),(2,181,632,2002,1,''),(2,181,633,2428,1,''),(2,181,634,3963,1,''),(2,181,635,7379,1,''),(2,181,636,1998,1,''),(2,181,637,2002,1,''),(2,181,638,2428,1,''),(2,181,639,3963,1,''),(2,181,640,7379,1,''),(2,181,641,1998,1,''),(2,181,642,2002,1,''),(2,181,643,2428,1,''),(2,181,644,3963,1,''),(2,181,645,7379,1,''),(2,181,646,1998,1,''),(2,181,647,2002,1,''),(2,182,648,2428,1,''),(2,182,649,3963,1,''),(2,182,650,7379,1,''),(2,182,651,1998,1,''),(2,182,652,2002,1,''),(2,182,653,2428,1,''),(2,182,654,3963,1,''),(2,182,655,7379,1,''),(2,182,656,1998,1,''),(2,182,657,2002,1,''),(2,182,658,2428,1,''),(2,182,659,3963,1,''),(2,182,660,7379,1,''),(2,182,661,1998,1,''),(2,182,662,2002,1,''),(2,182,663,2428,1,''),(2,182,664,3963,1,''),(2,182,665,7379,1,''),(2,182,666,1998,1,''),(2,182,667,2002,1,''),(2,186,668,2428,1,''),(2,186,669,3963,1,''),(2,186,670,7379,1,''),(2,186,671,1998,1,''),(2,186,672,2002,1,''),(2,186,673,2428,1,''),(2,186,674,3963,1,''),(2,186,675,7379,1,''),(2,186,676,1998,1,''),(2,186,677,2002,1,''),(2,186,678,2428,1,''),(2,186,679,3963,1,''),(2,186,680,7379,1,''),(2,186,681,1998,1,''),(2,186,682,2002,1,''),(2,186,683,2428,1,''),(2,186,684,3963,1,''),(2,186,685,7379,1,''),(2,186,686,1998,1,''),(2,186,687,2002,1,''),(2,187,688,2428,1,''),(2,187,689,3963,1,''),(2,187,690,7379,1,''),(2,187,691,1998,1,''),(2,187,692,2002,1,''),(2,187,693,2428,1,''),(2,187,694,3963,1,''),(2,187,695,7379,1,''),(2,187,696,1998,1,''),(2,187,697,2002,1,''),(2,187,698,2428,1,''),(2,187,699,3963,1,''),(2,187,700,7379,1,''),(2,187,701,1998,1,''),(2,187,702,2002,1,''),(2,187,703,2428,1,''),(2,187,704,3963,1,''),(2,187,705,7379,1,''),(2,187,706,1998,1,''),(2,187,707,2002,1,''),(2,191,708,2428,1,''),(2,191,709,3963,1,''),(2,191,710,7379,1,''),(2,191,711,1998,1,''),(2,191,712,2002,1,''),(2,191,713,2428,1,''),(2,191,714,3963,1,''),(2,191,715,7379,1,''),(2,191,716,1998,1,''),(2,191,717,2002,1,''),(2,191,718,2428,1,''),(2,191,719,3963,1,''),(2,191,720,7379,1,''),(2,191,721,1998,1,''),(2,191,722,2002,1,''),(2,191,723,2428,1,''),(2,191,724,3963,1,''),(2,191,725,7379,1,''),(2,191,726,1998,1,''),(2,191,727,2002,1,''),(2,192,728,2428,1,''),(2,192,729,3963,1,''),(2,192,730,7379,1,''),(2,192,731,1998,1,''),(2,192,732,2002,1,''),(2,192,733,2428,1,''),(2,192,734,3963,1,''),(2,192,735,7379,1,''),(2,192,736,1998,1,''),(2,192,737,2002,1,''),(2,192,738,2428,1,''),(2,192,739,3963,1,''),(2,192,740,7379,1,''),(2,192,741,1998,1,''),(2,192,742,2002,1,''),(2,192,743,2428,1,''),(2,192,744,3963,1,''),(2,192,745,7379,1,''),(2,192,746,1998,1,''),(2,192,747,2002,1,''),(2,196,748,2428,1,''),(2,196,749,3963,1,''),(2,196,750,7379,1,''),(2,196,751,1998,1,''),(2,196,752,2002,1,''),(2,196,753,2428,1,''),(2,196,754,3963,1,''),(2,196,755,7379,1,''),(2,196,756,1998,1,''),(2,196,757,2002,1,''),(2,196,758,2428,1,''),(2,196,759,3963,1,''),(2,196,760,7379,1,''),(2,196,761,1998,1,''),(2,196,762,2002,1,''),(2,196,763,2428,1,''),(2,196,764,3963,1,''),(2,196,765,7379,1,''),(2,196,766,1998,1,''),(2,196,767,2002,1,''),(2,197,768,2428,1,''),(2,197,769,3963,1,''),(2,197,770,7379,1,''),(2,197,771,1998,1,''),(2,197,772,2002,1,''),(2,197,773,2428,1,''),(2,197,774,3963,1,''),(2,197,775,7379,1,''),(2,197,776,1998,1,''),(2,197,777,2002,1,''),(2,197,778,2428,1,''),(2,197,779,3963,1,''),(2,197,780,7379,1,''),(2,197,781,1998,1,''),(2,197,782,2002,1,''),(2,197,783,2428,1,''),(2,197,784,3963,1,''),(2,197,785,7379,1,''),(2,197,786,1998,1,''),(2,197,787,2002,1,''),(2,201,788,2428,1,''),(2,201,789,3963,1,''),(2,201,790,7379,1,''),(2,201,791,1998,1,''),(2,201,792,2002,1,''),(2,201,793,2428,1,''),(2,201,794,3963,1,''),(2,201,795,7379,1,''),(2,201,796,1998,1,''),(2,201,797,2002,1,''),(2,201,798,2428,1,''),(2,201,799,3963,1,''),(2,201,800,7379,1,''),(2,201,801,1998,1,''),(2,201,802,2002,1,''),(2,201,803,2428,1,''),(2,201,804,3963,1,''),(2,201,805,7379,1,''),(2,201,806,1998,1,''),(2,201,807,2002,1,''),(2,202,808,2428,1,''),(2,202,809,3963,1,''),(2,202,810,7379,1,''),(2,202,811,1998,1,''),(2,202,812,2002,1,''),(2,202,813,2428,1,''),(2,202,814,3963,1,''),(2,202,815,7379,1,''),(2,202,816,1998,1,''),(2,202,817,2002,1,''),(2,202,818,2428,1,''),(2,202,819,3963,1,''),(2,202,820,7379,1,''),(2,202,821,1998,1,''),(2,202,822,2002,1,''),(2,202,823,2428,1,''),(2,202,824,3963,1,''),(2,202,825,7379,1,''),(2,202,826,1998,1,''),(2,202,827,2002,1,''),(2,206,828,2428,1,''),(2,206,829,3963,1,''),(2,206,830,7379,1,''),(2,206,831,1998,1,''),(2,206,832,2002,1,''),(2,206,833,2428,1,''),(2,206,834,3963,1,''),(2,206,835,7379,1,''),(2,206,836,1998,1,''),(2,206,837,2002,1,''),(2,206,838,2428,1,''),(2,206,839,3963,1,''),(2,206,840,7379,1,''),(2,206,841,1998,1,''),(2,206,842,2002,1,''),(2,206,843,2428,1,''),(2,206,844,3963,1,''),(2,206,845,7379,1,''),(2,206,846,1998,1,''),(2,206,847,2002,1,''),(2,207,848,2428,1,''),(2,207,849,3963,1,''),(2,207,850,7379,1,''),(2,207,851,1998,1,''),(2,207,852,2002,1,''),(2,207,853,2428,1,''),(2,207,854,3963,1,''),(2,207,855,7379,1,''),(2,207,856,1998,1,''),(2,207,857,2002,1,''),(2,207,858,2428,1,''),(2,207,859,3963,1,''),(2,207,860,7379,1,''),(2,207,861,1998,1,''),(2,207,862,2002,1,''),(2,207,863,2428,1,''),(2,207,864,3963,1,''),(2,207,865,7379,1,''),(2,207,866,1998,1,''),(2,207,867,2002,1,''),(2,211,868,2428,1,''),(2,211,869,3963,1,''),(2,211,870,7379,1,''),(2,211,871,1998,1,''),(2,211,872,2002,1,''),(2,211,873,2428,1,''),(2,211,874,3963,1,''),(2,211,875,7379,1,''),(2,211,876,1998,1,''),(2,211,877,2002,1,''),(2,211,878,2428,1,''),(2,211,879,3963,1,''),(2,211,880,7379,1,''),(2,211,881,1998,1,''),(2,211,882,2002,1,''),(2,211,883,2428,1,''),(2,211,884,3963,1,''),(2,211,885,7379,1,''),(2,211,886,1998,1,''),(2,211,887,2002,1,''),(2,212,888,2428,1,''),(2,212,889,3963,1,''),(2,212,890,7379,1,''),(2,212,891,1998,1,''),(2,212,892,2002,1,''),(2,212,893,2428,1,''),(2,212,894,3963,1,''),(2,212,895,7379,1,''),(2,212,896,1998,1,''),(2,212,897,2002,1,''),(2,212,898,2428,1,''),(2,212,899,3963,1,''),(2,212,900,7379,1,''),(2,212,901,1998,1,''),(2,212,902,2002,1,''),(2,212,903,2428,1,''),(2,212,904,3963,1,''),(2,212,905,7379,1,''),(2,212,906,1998,1,''),(2,212,907,2002,1,''),(2,216,908,2428,1,''),(2,216,909,3963,1,''),(2,216,910,7379,1,''),(2,216,911,1998,1,''),(2,216,912,2002,1,''),(2,216,913,2428,1,''),(2,216,914,3963,1,''),(2,216,915,7379,1,''),(2,216,916,1998,1,''),(2,216,917,2002,1,''),(2,216,918,2428,1,''),(2,216,919,3963,1,''),(2,216,920,7379,1,''),(2,216,921,1998,1,''),(2,216,922,2002,1,''),(2,216,923,2428,1,''),(2,216,924,3963,1,''),(2,216,925,7379,1,''),(2,216,926,1998,1,''),(2,216,927,2002,1,''),(2,217,928,2428,1,''),(2,217,929,3963,1,''),(2,217,930,7379,1,''),(2,217,931,1998,1,''),(2,217,932,2002,1,''),(2,217,933,2428,1,''),(2,217,934,3963,1,''),(2,217,935,7379,1,''),(2,217,936,1998,1,''),(2,217,937,2002,1,''),(2,217,938,2428,1,''),(2,217,939,3963,1,''),(2,217,940,7379,1,''),(2,217,941,1998,1,''),(2,217,942,2002,1,''),(2,217,943,2428,1,''),(2,217,944,3963,1,''),(2,217,945,7379,1,''),(2,217,946,1998,1,''),(2,217,947,2002,1,''),(2,221,948,2428,1,''),(2,221,949,3963,1,''),(2,221,950,7379,1,''),(2,221,951,1998,1,''),(2,221,952,2002,1,''),(2,221,953,2428,1,''),(2,221,954,3963,1,''),(2,221,955,7379,1,''),(2,221,956,1998,1,''),(2,221,957,2002,1,''),(2,221,958,2428,1,''),(2,221,959,3963,1,''),(2,221,960,7379,1,''),(2,221,961,1998,1,''),(2,221,962,2002,1,''),(2,221,963,2428,1,''),(2,221,964,3963,1,''),(2,221,965,7379,1,''),(2,221,966,1998,1,''),(2,221,967,2002,1,''),(2,222,968,2428,1,''),(2,222,969,3963,1,''),(2,222,970,7379,1,''),(2,222,971,1998,1,''),(2,222,972,2002,1,''),(2,222,973,2428,1,''),(2,222,974,3963,1,''),(2,222,975,7379,1,''),(2,222,976,1998,1,''),(2,222,977,2002,1,''),(2,222,978,2428,1,''),(2,222,979,3963,1,''),(2,222,980,7379,1,''),(2,222,981,1998,1,''),(2,222,982,2002,1,''),(2,222,983,2428,1,''),(2,222,984,3963,1,''),(2,222,985,7379,1,''),(2,222,986,1998,1,''),(2,222,987,2002,1,''),(2,226,988,2428,1,''),(2,226,989,3963,1,''),(2,226,990,7379,1,''),(2,226,991,1998,1,''),(2,226,992,2002,1,''),(2,226,993,2428,1,''),(2,226,994,3963,1,''),(2,226,995,7379,1,''),(2,226,996,1998,1,''),(2,226,997,2002,1,''),(2,226,998,2428,1,''),(2,226,999,3963,1,''),(2,226,1000,7379,1,''),(2,226,1001,1998,1,''),(2,226,1002,2002,1,''),(2,226,1003,2428,1,''),(2,226,1004,3963,1,''),(2,226,1005,7379,1,''),(2,226,1006,1998,1,''),(2,226,1007,2002,1,''),(2,227,1008,2428,1,''),(2,227,1009,3963,1,''),(2,227,1010,7379,1,''),(2,227,1011,1998,1,''),(2,227,1012,2002,1,''),(2,227,1013,2428,1,''),(2,227,1014,3963,1,''),(2,227,1015,7379,1,''),(2,227,1016,1998,1,''),(2,227,1017,2002,1,''),(2,227,1018,2428,1,''),(2,227,1019,3963,1,''),(2,227,1020,7379,1,''),(2,227,1021,1998,1,''),(2,227,1022,2002,1,''),(2,227,1023,2428,1,''),(2,227,1024,3963,1,''),(2,227,1025,7379,1,''),(2,227,1026,1998,1,''),(2,227,1027,2002,1,''),(2,231,1028,2428,1,''),(2,231,1029,3963,1,''),(2,231,1030,7379,1,''),(2,231,1031,1998,1,''),(2,231,1032,2002,1,''),(2,231,1033,2428,1,''),(2,231,1034,3963,1,''),(2,231,1035,7379,1,''),(2,231,1036,1998,1,''),(2,231,1037,2002,1,''),(2,231,1038,2428,1,''),(2,231,1039,3963,1,''),(2,231,1040,7379,1,''),(2,231,1041,1998,1,''),(2,231,1042,2002,1,''),(2,231,1043,2428,1,''),(2,231,1044,3963,1,''),(2,231,1045,7379,1,''),(2,231,1046,1998,1,''),(2,231,1047,2002,1,''),(2,232,1048,2428,1,''),(2,232,1049,3963,1,''),(2,232,1050,7379,1,''),(2,232,1051,1998,1,''),(2,232,1052,2002,1,''),(2,232,1053,2428,1,''),(2,232,1054,3963,1,''),(2,232,1055,7379,1,''),(2,232,1056,1998,1,''),(2,232,1057,2002,1,''),(2,232,1058,2428,1,''),(2,232,1059,3963,1,''),(2,232,1060,7379,1,''),(2,232,1061,1998,1,''),(2,232,1062,2002,1,''),(2,232,1063,2428,1,''),(2,232,1064,3963,1,''),(2,232,1065,7379,1,''),(2,232,1066,1998,1,''),(2,232,1067,2002,1,''),(2,236,1068,2428,1,''),(2,236,1069,3963,1,''),(2,236,1070,7379,1,''),(2,236,1071,1998,1,''),(2,236,1072,2002,1,''),(2,236,1073,2428,1,''),(2,236,1074,3963,1,''),(2,236,1075,7379,1,''),(2,236,1076,1998,1,''),(2,236,1077,2002,1,''),(2,236,1078,2428,1,''),(2,236,1079,3963,1,''),(2,236,1080,7379,1,''),(2,236,1081,1998,1,''),(2,236,1082,2002,1,''),(2,236,1083,2428,1,''),(2,236,1084,3963,1,''),(2,236,1085,7379,1,''),(2,236,1086,1998,1,''),(2,236,1087,2002,1,''),(2,237,1088,2428,1,''),(2,237,1089,3963,1,''),(2,237,1090,7379,1,''),(2,237,1091,1998,1,''),(2,237,1092,2002,1,''),(2,237,1093,2428,1,''),(2,237,1094,3963,1,''),(2,237,1095,7379,1,''),(2,237,1096,1998,1,''),(2,237,1097,2002,1,''),(2,237,1098,2428,1,''),(2,237,1099,3963,1,''),(2,237,1100,7379,1,''),(2,237,1101,1998,1,''),(2,237,1102,2002,1,''),(2,237,1103,2428,1,''),(2,237,1104,3963,1,''),(2,237,1105,7379,1,''),(2,237,1106,1998,1,''),(2,237,1107,2002,1,''),(2,241,1108,2428,1,''),(2,241,1109,3963,1,''),(2,241,1110,7379,1,''),(2,241,1111,1998,1,''),(2,241,1112,2002,1,''),(2,241,1113,2428,1,''),(2,241,1114,3963,1,''),(2,241,1115,7379,1,''),(2,241,1116,1998,1,''),(2,241,1117,2002,1,''),(2,241,1118,2428,1,''),(2,241,1119,3963,1,''),(2,241,1120,7379,1,''),(2,241,1121,1998,1,''),(2,241,1122,2002,1,''),(2,241,1123,2428,1,''),(2,241,1124,3963,1,''),(2,241,1125,7379,1,''),(2,241,1126,1998,1,''),(2,241,1127,2002,1,''),(2,242,1128,2428,1,''),(2,242,1129,3963,1,''),(2,242,1130,7379,1,''),(2,242,1131,1998,1,''),(2,242,1132,2002,1,''),(2,242,1133,2428,1,''),(2,242,1134,3963,1,''),(2,242,1135,7379,1,''),(2,242,1136,1998,1,''),(2,242,1137,2002,1,''),(2,242,1138,2428,1,''),(2,242,1139,3963,1,''),(2,242,1140,7379,1,''),(2,242,1141,1998,1,''),(2,242,1142,2002,1,''),(2,242,1143,2428,1,''),(2,242,1144,3963,1,''),(2,242,1145,7379,1,''),(2,242,1146,1998,1,''),(2,242,1147,2002,1,''),(2,246,1148,2428,1,''),(2,246,1149,3963,1,''),(2,246,1150,7379,1,''),(2,246,1151,1998,1,''),(2,246,1152,2002,1,''),(2,246,1153,2428,1,''),(2,246,1154,3963,1,''),(2,246,1155,7379,1,''),(2,246,1156,1998,1,''),(2,246,1157,2002,1,''),(2,246,1158,2428,1,''),(2,246,1159,3963,1,''),(2,246,1160,7379,1,''),(2,246,1161,1998,1,''),(2,246,1162,2002,1,''),(2,246,1163,2428,1,''),(2,246,1164,3963,1,''),(2,246,1165,7379,1,''),(2,246,1166,1998,1,''),(2,246,1167,2002,1,''),(2,247,1168,2428,1,''),(2,247,1169,3963,1,''),(2,247,1170,7379,1,''),(2,247,1171,1998,1,''),(2,247,1172,2002,1,''),(2,247,1173,2428,1,''),(2,247,1174,3963,1,''),(2,247,1175,7379,1,''),(2,247,1176,1998,1,''),(2,247,1177,2002,1,''),(2,247,1178,2428,1,''),(2,247,1179,3963,1,''),(2,247,1180,7379,1,''),(2,247,1181,1998,1,''),(2,247,1182,2002,1,''),(2,247,1183,2428,1,''),(2,247,1184,3963,1,''),(2,247,1185,7379,1,''),(2,247,1186,1998,1,''),(2,247,1187,2002,1,''),(2,251,1188,2428,1,''),(2,251,1189,3963,1,''),(2,251,1190,7379,1,''),(2,251,1191,1998,1,''),(2,251,1192,2002,1,''),(2,251,1193,2428,1,''),(2,251,1194,3963,1,''),(2,251,1195,7379,1,''),(2,251,1196,1998,1,''),(2,251,1197,2002,1,''),(2,251,1198,2428,1,''),(2,251,1199,3963,1,''),(2,251,1200,7379,1,''),(2,251,1201,1998,1,''),(2,251,1202,2002,1,''),(2,251,1203,2428,1,''),(2,251,1204,3963,1,''),(2,251,1205,7379,1,''),(2,251,1206,1998,1,''),(2,251,1207,2002,1,''),(2,252,1208,2428,1,''),(2,252,1209,3963,1,''),(2,252,1210,7379,1,''),(2,252,1211,1998,1,''),(2,252,1212,2002,1,''),(2,252,1213,2428,1,''),(2,252,1214,3963,1,''),(2,252,1215,7379,1,''),(2,252,1216,1998,1,''),(2,252,1217,2002,1,''),(2,252,1218,2428,1,''),(2,252,1219,3963,1,''),(2,252,1220,7379,1,''),(2,252,1221,1998,1,''),(2,252,1222,2002,1,''),(2,252,1223,2428,1,''),(2,252,1224,3963,1,''),(2,252,1225,7379,1,''),(2,252,1226,1998,1,''),(2,252,1227,2002,1,''),(2,256,1228,2428,1,''),(2,256,1229,3963,1,''),(2,256,1230,7379,1,''),(2,256,1231,1998,1,''),(2,256,1232,2002,1,''),(2,256,1233,2428,1,''),(2,256,1234,3963,1,''),(2,256,1235,7379,1,''),(2,256,1236,1998,1,''),(2,256,1237,2002,1,''),(2,256,1238,2428,1,''),(2,256,1239,3963,1,''),(2,256,1240,7379,1,''),(2,256,1241,1998,1,''),(2,256,1242,2002,1,''),(2,256,1243,2428,1,''),(2,256,1244,3963,1,''),(2,256,1245,7379,1,''),(2,256,1246,1998,1,''),(2,256,1247,2002,1,''),(2,257,1248,2428,1,''),(2,257,1249,3963,1,''),(2,257,1250,7379,1,''),(2,257,1251,1998,1,''),(2,257,1252,2002,1,''),(2,257,1253,2428,1,''),(2,257,1254,3963,1,''),(2,257,1255,7379,1,''),(2,257,1256,1998,1,''),(2,257,1257,2002,1,''),(2,257,1258,2428,1,''),(2,257,1259,3963,1,''),(2,257,1260,7379,1,''),(2,257,1261,1998,1,''),(2,257,1262,2002,1,''),(2,257,1263,2428,1,''),(2,257,1264,3963,1,''),(2,257,1265,7379,1,''),(2,257,1266,1998,1,''),(2,257,1267,2002,1,''),(2,261,1268,2428,1,''),(2,261,1269,3963,1,''),(2,261,1270,7379,1,''),(2,261,1271,1998,1,''),(2,261,1272,2002,1,''),(2,261,1273,2428,1,''),(2,261,1274,3963,1,''),(2,261,1275,7379,1,''),(2,261,1276,1998,1,''),(2,261,1277,2002,1,''),(2,261,1278,2428,1,''),(2,261,1279,3963,1,''),(2,261,1280,7379,1,''),(2,261,1281,1998,1,''),(2,261,1282,2002,1,''),(2,261,1283,2428,1,''),(2,261,1284,3963,1,''),(2,261,1285,7379,1,''),(2,261,1286,1998,1,''),(2,261,1287,2002,1,''),(2,262,1288,2428,1,''),(2,262,1289,3963,1,''),(2,262,1290,7379,1,''),(2,262,1291,1998,1,''),(2,262,1292,2002,1,''),(2,262,1293,2428,1,''),(2,262,1294,3963,1,''),(2,262,1295,7379,1,''),(2,262,1296,1998,1,''),(2,262,1297,2002,1,''),(2,262,1298,2428,1,''),(2,262,1299,3963,1,''),(2,262,1300,7379,1,''),(2,262,1301,1998,1,''),(2,262,1302,2002,1,''),(2,262,1303,2428,1,''),(2,262,1304,3963,1,''),(2,262,1305,7379,1,''),(2,262,1306,1998,1,''),(2,262,1307,2002,1,''),(2,266,1308,2428,1,''),(2,266,1309,3963,1,''),(2,266,1310,7379,1,''),(2,266,1311,1998,1,''),(2,266,1312,2002,1,''),(2,266,1313,2428,1,''),(2,266,1314,3963,1,''),(2,266,1315,7379,1,''),(2,266,1316,1998,1,''),(2,266,1317,2002,1,''),(2,266,1318,2428,1,''),(2,266,1319,3963,1,''),(2,266,1320,7379,1,''),(2,266,1321,1998,1,''),(2,266,1322,2002,1,''),(2,266,1323,2428,1,''),(2,266,1324,3963,1,''),(2,266,1325,7379,1,''),(2,266,1326,1998,1,''),(2,266,1327,2002,1,''),(2,267,1328,2428,1,''),(2,267,1329,3963,1,''),(2,267,1330,7379,1,''),(2,267,1331,1998,1,''),(2,267,1332,2002,1,''),(2,267,1333,2428,1,''),(2,267,1334,3963,1,''),(2,267,1335,7379,1,''),(2,267,1336,1998,1,''),(2,267,1337,2002,1,''),(2,267,1338,2428,1,''),(2,267,1339,3963,1,''),(2,267,1340,7379,1,''),(2,267,1341,1998,1,''),(2,267,1342,2002,1,''),(2,267,1343,2428,1,''),(2,267,1344,3963,1,''),(2,267,1345,7379,1,''),(2,267,1346,1998,1,''),(2,267,1347,2002,1,''),(2,271,1348,2428,1,''),(2,271,1349,3963,1,''),(2,271,1350,7379,1,''),(2,271,1351,1998,1,''),(2,271,1352,2002,1,''),(2,271,1353,2428,1,''),(2,271,1354,3963,1,''),(2,271,1355,7379,1,''),(2,271,1356,1998,1,''),(2,271,1357,2002,1,''),(2,271,1358,2428,1,''),(2,271,1359,3963,1,''),(2,271,1360,7379,1,''),(2,271,1361,1998,1,''),(2,271,1362,2002,1,''),(2,271,1363,2428,1,''),(2,271,1364,3963,1,''),(2,271,1365,7379,1,''),(2,271,1366,1998,1,''),(2,271,1367,2002,1,''),(2,272,1368,2428,1,''),(2,272,1369,3963,1,''),(2,272,1370,7379,1,''),(2,272,1371,1998,1,''),(2,272,1372,2002,1,''),(2,272,1373,2428,1,''),(2,272,1374,3963,1,''),(2,272,1375,7379,1,''),(2,272,1376,1998,1,''),(2,272,1377,2002,1,''),(2,272,1378,2428,1,''),(2,272,1379,3963,1,''),(2,272,1380,7379,1,''),(2,272,1381,1998,1,''),(2,272,1382,2002,1,''),(2,272,1383,2428,1,''),(2,272,1384,3963,1,''),(2,272,1385,7379,1,''),(2,272,1386,1998,1,''),(2,272,1387,2002,1,''),(2,276,1388,2428,1,''),(2,276,1389,3963,1,''),(2,276,1390,7379,1,''),(2,276,1391,1998,1,''),(2,276,1392,2002,1,''),(2,276,1393,2428,1,''),(2,276,1394,3963,1,''),(2,276,1395,7379,1,''),(2,276,1396,1998,1,''),(2,276,1397,2002,1,''),(2,276,1398,2428,1,''),(2,276,1399,3963,1,''),(2,276,1400,7379,1,''),(2,276,1401,1998,1,''),(2,276,1402,2002,1,''),(2,276,1403,2428,1,''),(2,276,1404,3963,1,''),(2,276,1405,7379,1,''),(2,276,1406,1998,1,''),(2,276,1407,2002,1,''),(2,277,1408,2428,1,''),(2,277,1409,3963,1,''),(2,277,1410,7379,1,''),(2,277,1411,1998,1,''),(2,277,1412,2002,1,''),(2,277,1413,2428,1,''),(2,277,1414,3963,1,''),(2,277,1415,7379,1,''),(2,277,1416,1998,1,''),(2,277,1417,2002,1,''),(2,277,1418,2428,1,''),(2,277,1419,3963,1,''),(2,277,1420,7379,1,''),(2,277,1421,1998,1,''),(2,277,1422,2002,1,''),(2,277,1423,2428,1,''),(2,277,1424,3963,1,''),(2,277,1425,7379,1,''),(2,277,1426,1998,1,''),(2,277,1427,2002,1,''),(2,281,1428,2428,1,''),(2,281,1429,3963,1,''),(2,281,1430,7379,1,''),(2,281,1431,1998,1,''),(2,281,1432,2002,1,''),(2,281,1433,2428,1,''),(2,281,1434,3963,1,''),(2,281,1435,7379,1,''),(2,281,1436,1998,1,''),(2,281,1437,2002,1,''),(2,281,1438,2428,1,''),(2,281,1439,3963,1,''),(2,281,1440,7379,1,''),(2,281,1441,1998,1,''),(2,281,1442,2002,1,''),(2,281,1443,2428,1,''),(2,281,1444,3963,1,''),(2,281,1445,7379,1,''),(2,281,1446,1998,1,''),(2,281,1447,2002,1,''),(2,282,1448,2428,1,''),(2,282,1449,3963,1,''),(2,282,1450,7379,1,''),(2,282,1451,1998,1,''),(2,282,1452,2002,1,''),(2,282,1453,2428,1,''),(2,282,1454,3963,1,''),(2,282,1455,7379,1,''),(2,282,1456,1998,1,''),(2,282,1457,2002,1,''),(2,282,1458,2428,1,''),(2,282,1459,3963,1,''),(2,282,1460,7379,1,''),(2,282,1461,1998,1,''),(2,282,1462,2002,1,''),(2,282,1463,2428,1,''),(2,282,1464,3963,1,''),(2,282,1465,7379,1,''),(2,282,1466,1998,1,''),(2,282,1467,2002,1,''),(2,286,1468,2428,1,''),(2,286,1469,3963,1,''),(2,286,1470,7379,1,''),(2,286,1471,1998,1,''),(2,286,1472,2002,1,''),(2,286,1473,2428,1,''),(2,286,1474,3963,1,''),(2,286,1475,7379,1,''),(2,286,1476,1998,1,''),(2,286,1477,2002,1,''),(2,286,1478,2428,1,''),(2,286,1479,3963,1,''),(2,286,1480,7379,1,''),(2,286,1481,1998,1,''),(2,286,1482,2002,1,''),(2,286,1483,2428,1,''),(2,286,1484,3963,1,''),(2,286,1485,7379,1,''),(2,286,1486,1998,1,''),(2,286,1487,2002,1,''),(2,287,1488,2428,1,''),(2,287,1489,3963,1,''),(2,287,1490,7379,1,''),(2,287,1491,1998,1,''),(2,287,1492,2002,1,''),(2,287,1493,2428,1,''),(2,287,1494,3963,1,''),(2,287,1495,7379,1,''),(2,287,1496,1998,1,''),(2,287,1497,2002,1,''),(2,287,1498,2428,1,''),(2,287,1499,3963,1,''),(2,287,1500,7379,1,''),(2,287,1501,1998,1,''),(2,287,1502,2002,1,''),(2,287,1503,2428,1,''),(2,287,1504,3963,1,''),(2,287,1505,7379,1,''),(2,287,1506,1998,1,''),(2,287,1507,2002,1,''),(2,291,1508,2428,1,''),(2,291,1509,3963,1,''),(2,291,1510,7379,1,''),(2,291,1511,1998,1,''),(2,291,1512,2002,1,''),(2,291,1513,2428,1,''),(2,291,1514,3963,1,''),(2,291,1515,7379,1,''),(2,291,1516,1998,1,''),(2,291,1517,2002,1,''),(2,291,1518,2428,1,''),(2,291,1519,3963,1,''),(2,291,1520,7379,1,''),(2,291,1521,1998,1,''),(2,291,1522,2002,1,''),(2,291,1523,2428,1,''),(2,291,1524,3963,1,''),(2,291,1525,7379,1,''),(2,291,1526,1998,1,''),(2,291,1527,2002,1,''),(2,292,1528,2428,1,''),(2,292,1529,3963,1,''),(2,292,1530,7379,1,''),(2,292,1531,1998,1,''),(2,292,1532,2002,1,''),(2,292,1533,2428,1,''),(2,292,1534,3963,1,''),(2,292,1535,7379,1,''),(2,292,1536,1998,1,''),(2,292,1537,2002,1,''),(2,292,1538,2428,1,''),(2,292,1539,3963,1,''),(2,292,1540,7379,1,''),(2,292,1541,1998,1,''),(2,292,1542,2002,1,''),(2,292,1543,2428,1,''),(2,292,1544,3963,1,''),(2,292,1545,7379,1,''),(2,292,1546,1998,1,''),(2,292,1547,2002,1,''),(2,296,1548,2428,1,''),(2,296,1549,3963,1,''),(2,296,1550,7379,1,''),(2,296,1551,1998,1,''),(2,296,1552,2002,1,''),(2,296,1553,2428,1,''),(2,296,1554,3963,1,''),(2,296,1555,7379,1,''),(2,296,1556,1998,1,''),(2,296,1557,2002,1,''),(2,296,1558,2428,1,''),(2,296,1559,3963,1,''),(2,296,1560,7379,1,''),(2,296,1561,1998,1,''),(2,296,1562,2002,1,''),(2,296,1563,2428,1,''),(2,296,1564,3963,1,''),(2,296,1565,7379,1,''),(2,296,1566,1998,1,''),(2,296,1567,2002,1,''),(2,297,1568,2428,1,''),(2,297,1569,3963,1,''),(2,297,1570,7379,1,''),(2,297,1571,1998,1,''),(2,297,1572,2002,1,''),(2,297,1573,2428,1,''),(2,297,1574,3963,1,''),(2,297,1575,7379,1,''),(2,297,1576,1998,1,''),(2,297,1577,2002,1,''),(2,297,1578,2428,1,''),(2,297,1579,3963,1,''),(2,297,1580,7379,1,''),(2,297,1581,1998,1,''),(2,297,1582,2002,1,''),(2,297,1583,2428,1,''),(2,297,1584,3963,1,''),(2,297,1585,7379,1,''),(2,297,1586,1998,1,''),(2,297,1587,2002,1,''),(2,301,1588,2428,1,''),(2,301,1589,3963,1,''),(2,301,1590,7379,1,''),(2,301,1591,1998,1,''),(2,301,1592,2002,1,''),(2,301,1593,2428,1,''),(2,301,1594,3963,1,''),(2,301,1595,7379,1,''),(2,301,1596,1998,1,''),(2,301,1597,2002,1,''),(2,301,1598,2428,1,''),(2,301,1599,3963,1,''),(2,301,1600,7379,1,''),(2,301,1601,1998,1,''),(2,301,1602,2002,1,''),(2,301,1603,2428,1,''),(2,301,1604,3963,1,''),(2,301,1605,7379,1,''),(2,301,1606,1998,1,''),(2,301,1607,2002,1,''),(2,302,1608,2428,1,''),(2,302,1609,3963,1,''),(2,302,1610,7379,1,''),(2,302,1611,1998,1,''),(2,302,1612,2002,1,''),(2,302,1613,2428,1,''),(2,302,1614,3963,1,''),(2,302,1615,7379,1,''),(2,302,1616,1998,1,''),(2,302,1617,2002,1,''),(2,302,1618,2428,1,''),(2,302,1619,3963,1,''),(2,302,1620,7379,1,''),(2,302,1621,1998,1,''),(2,302,1622,2002,1,''),(2,302,1623,2428,1,''),(2,302,1624,3963,1,''),(2,302,1625,7379,1,''),(2,302,1626,1998,1,''),(2,302,1627,2002,1,''),(2,306,1628,2428,1,''),(2,306,1629,3963,1,''),(2,306,1630,7379,1,''),(2,306,1631,1998,1,''),(2,306,1632,2002,1,''),(2,306,1633,2428,1,''),(2,306,1634,3963,1,''),(2,306,1635,7379,1,''),(2,306,1636,1998,1,''),(2,306,1637,2002,1,''),(2,306,1638,2428,1,''),(2,306,1639,3963,1,''),(2,306,1640,7379,1,''),(2,306,1641,1998,1,''),(2,306,1642,2002,1,''),(2,306,1643,2428,1,''),(2,306,1644,3963,1,''),(2,306,1645,7379,1,''),(2,306,1646,1998,1,''),(2,306,1647,2002,1,''),(2,307,1648,2428,1,''),(2,307,1649,3963,1,''),(2,307,1650,7379,1,''),(2,307,1651,1998,1,''),(2,307,1652,2002,1,''),(2,307,1653,2428,1,''),(2,307,1654,3963,1,''),(2,307,1655,7379,1,''),(2,307,1656,1998,1,''),(2,307,1657,2002,1,''),(2,307,1658,2428,1,''),(2,307,1659,3963,1,''),(2,307,1660,7379,1,''),(2,307,1661,1998,1,''),(2,307,1662,2002,1,''),(2,307,1663,2428,1,''),(2,307,1664,3963,1,''),(2,307,1665,7379,1,''),(2,307,1666,1998,1,''),(2,307,1667,2002,1,''),(2,311,1668,2428,1,''),(2,311,1669,3963,1,''),(2,311,1670,7379,1,''),(2,311,1671,1998,1,''),(2,311,1672,2002,1,''),(2,311,1673,2428,1,''),(2,311,1674,3963,1,''),(2,311,1675,7379,1,''),(2,311,1676,1998,1,''),(2,311,1677,2002,1,''),(2,311,1678,2428,1,''),(2,311,1679,3963,1,''),(2,311,1680,7379,1,''),(2,311,1681,1998,1,''),(2,311,1682,2002,1,''),(2,311,1683,2428,1,''),(2,311,1684,3963,1,''),(2,311,1685,7379,1,''),(2,311,1686,1998,1,''),(2,311,1687,2002,1,''),(2,312,1688,2428,1,''),(2,312,1689,3963,1,''),(2,312,1690,7379,1,''),(2,312,1691,1998,1,''),(2,312,1692,2002,1,''),(2,312,1693,2428,1,''),(2,312,1694,3963,1,''),(2,312,1695,7379,1,''),(2,312,1696,1998,1,''),(2,312,1697,2002,1,''),(2,312,1698,2428,1,''),(2,312,1699,3963,1,''),(2,312,1700,7379,1,''),(2,312,1701,1998,1,''),(2,312,1702,2002,1,''),(2,312,1703,2428,1,''),(2,312,1704,3963,1,''),(2,312,1705,7379,1,''),(2,312,1706,1998,1,''),(2,312,1707,2002,1,''),(2,316,1708,2428,1,''),(2,316,1709,3963,1,''),(2,316,1710,7379,1,''),(2,316,1711,1998,1,''),(2,316,1712,2002,1,''),(2,316,1713,2428,1,''),(2,316,1714,3963,1,''),(2,316,1715,7379,1,''),(2,316,1716,1998,1,''),(2,316,1717,2002,1,''),(2,316,1718,2428,1,''),(2,316,1719,3963,1,''),(2,316,1720,7379,1,''),(2,316,1721,1998,1,''),(2,316,1722,2002,1,''),(2,316,1723,2428,1,''),(2,316,1724,3963,1,''),(2,316,1725,7379,1,''),(2,316,1726,1998,1,''),(2,316,1727,2002,1,''),(2,317,1728,2428,1,''),(2,317,1729,3963,1,''),(2,317,1730,7379,1,''),(2,317,1731,1998,1,''),(2,317,1732,2002,1,''),(2,317,1733,2428,1,''),(2,317,1734,3963,1,''),(2,317,1735,7379,1,''),(2,317,1736,1998,1,''),(2,317,1737,2002,1,''),(2,317,1738,2428,1,''),(2,317,1739,3963,1,''),(2,317,1740,7379,1,''),(2,317,1741,1998,1,''),(2,317,1742,2002,1,''),(2,317,1743,2428,1,''),(2,317,1744,3963,1,''),(2,317,1745,7379,1,''),(2,317,1746,1998,1,''),(2,317,1747,2002,1,''),(2,321,1748,2428,1,''),(2,321,1749,3963,1,''),(2,321,1750,7379,1,''),(2,321,1751,1998,1,''),(2,321,1752,2002,1,''),(2,321,1753,2428,1,''),(2,321,1754,3963,1,''),(2,321,1755,7379,1,''),(2,321,1756,1998,1,''),(2,321,1757,2002,1,''),(2,321,1758,2428,1,''),(2,321,1759,3963,1,''),(2,321,1760,7379,1,''),(2,321,1761,1998,1,''),(2,321,1762,2002,1,''),(2,321,1763,2428,1,''),(2,321,1764,3963,1,''),(2,321,1765,7379,1,''),(2,321,1766,1998,1,''),(2,321,1767,2002,1,''),(2,322,1768,2428,1,''),(2,322,1769,3963,1,''),(2,322,1770,7379,1,''),(2,322,1771,1998,1,''),(2,322,1772,2002,1,''),(2,322,1773,2428,1,''),(2,322,1774,3963,1,''),(2,322,1775,7379,1,''),(2,322,1776,1998,1,''),(2,322,1777,2002,1,''),(2,322,1778,2428,1,''),(2,322,1779,3963,1,''),(2,322,1780,7379,1,''),(2,322,1781,1998,1,''),(2,322,1782,2002,1,''),(2,322,1783,2428,1,''),(2,322,1784,3963,1,''),(2,322,1785,7379,1,''),(2,322,1786,1998,1,''),(2,322,1787,2002,1,''),(2,326,1788,2428,1,''),(2,326,1789,3963,1,''),(2,326,1790,7379,1,''),(2,326,1791,1998,1,''),(2,326,1792,2002,1,''),(2,326,1793,2428,1,''),(2,326,1794,3963,1,''),(2,326,1795,7379,1,''),(2,326,1796,1998,1,''),(2,326,1797,2002,1,''),(2,326,1798,2428,1,''),(2,326,1799,3963,1,''),(2,326,1800,7379,1,''),(2,326,1801,1998,1,''),(2,326,1802,2002,1,''),(2,326,1803,2428,1,''),(2,326,1804,3963,1,''),(2,326,1805,7379,1,''),(2,326,1806,1998,1,''),(2,326,1807,2002,1,''),(2,327,1808,2428,1,''),(2,327,1809,3963,1,''),(2,327,1810,7379,1,''),(2,327,1811,1998,1,''),(2,327,1812,2002,1,''),(2,327,1813,2428,1,''),(2,327,1814,3963,1,''),(2,327,1815,7379,1,''),(2,327,1816,1998,1,''),(2,327,1817,2002,1,''),(2,327,1818,2428,1,''),(2,327,1819,3963,1,''),(2,327,1820,7379,1,''),(2,327,1821,1998,1,''),(2,327,1822,2002,1,''),(2,327,1823,2428,1,''),(2,327,1824,3963,1,''),(2,327,1825,7379,1,''),(2,327,1826,1998,1,''),(2,327,1827,2002,1,''),(2,331,1828,2428,1,''),(2,331,1829,3963,1,''),(2,331,1830,7379,1,''),(2,331,1831,1998,1,''),(2,331,1832,2002,1,''),(2,331,1833,2428,1,''),(2,331,1834,3963,1,''),(2,331,1835,7379,1,''),(2,331,1836,1998,1,''),(2,331,1837,2002,1,''),(2,331,1838,2428,1,''),(2,331,1839,3963,1,''),(2,331,1840,7379,1,''),(2,331,1841,1998,1,''),(2,331,1842,2002,1,''),(2,331,1843,2428,1,''),(2,331,1844,3963,1,''),(2,331,1845,7379,1,''),(2,331,1846,1998,1,''),(2,331,1847,2002,1,''),(2,332,1848,2428,1,''),(2,332,1849,3963,1,''),(2,332,1850,7379,1,''),(2,332,1851,1998,1,''),(2,332,1852,2002,1,''),(2,332,1853,2428,1,''),(2,332,1854,3963,1,''),(2,332,1855,7379,1,''),(2,332,1856,1998,1,''),(2,332,1857,2002,1,''),(2,332,1858,2428,1,''),(2,332,1859,3963,1,''),(2,332,1860,7379,1,''),(2,332,1861,1998,1,''),(2,332,1862,2002,1,''),(2,332,1863,2428,1,''),(2,332,1864,3963,1,''),(2,332,1865,7379,1,''),(2,332,1866,1998,1,''),(2,332,1867,2002,1,''),(2,336,1868,2428,1,''),(2,336,1869,3963,1,''),(2,336,1870,7379,1,''),(2,336,1871,1998,1,''),(2,336,1872,2002,1,''),(2,336,1873,2428,1,''),(2,336,1874,3963,1,''),(2,336,1875,7379,1,''),(2,336,1876,1998,1,''),(2,336,1877,2002,1,''),(2,336,1878,2428,1,''),(2,336,1879,3963,1,''),(2,336,1880,7379,1,''),(2,336,1881,1998,1,''),(2,336,1882,2002,1,''),(2,336,1883,2428,1,''),(2,336,1884,3963,1,''),(2,336,1885,7379,1,''),(2,336,1886,1998,1,''),(2,336,1887,2002,1,''),(2,337,1888,2428,1,''),(2,337,1889,3963,1,''),(2,337,1890,7379,1,''),(2,337,1891,1998,1,''),(2,337,1892,2002,1,''),(2,337,1893,2428,1,''),(2,337,1894,3963,1,''),(2,337,1895,7379,1,''),(2,337,1896,1998,1,''),(2,337,1897,2002,1,''),(2,337,1898,2428,1,''),(2,337,1899,3963,1,''),(2,337,1900,7379,1,''),(2,337,1901,1998,1,''),(2,337,1902,2002,1,''),(2,337,1903,2428,1,''),(2,337,1904,3963,1,''),(2,337,1905,7379,1,''),(2,337,1906,1998,1,''),(2,337,1907,2002,1,''),(2,341,1908,2428,1,''),(2,341,1909,3963,1,''),(2,341,1910,7379,1,''),(2,341,1911,1998,1,''),(2,341,1912,2002,1,''),(2,341,1913,2428,1,''),(2,341,1914,3963,1,''),(2,341,1915,7379,1,''),(2,341,1916,1998,1,''),(2,341,1917,2002,1,''),(2,341,1918,2428,1,''),(2,341,1919,3963,1,''),(2,341,1920,7379,1,''),(2,341,1921,1998,1,''),(2,341,1922,2002,1,''),(2,341,1923,2428,1,''),(2,341,1924,3963,1,''),(2,341,1925,7379,1,''),(2,341,1926,1998,1,''),(2,341,1927,2002,1,''),(2,342,1928,2428,1,''),(2,342,1929,3963,1,''),(2,342,1930,7379,1,''),(2,342,1931,1998,1,''),(2,342,1932,2002,1,''),(2,342,1933,2428,1,''),(2,342,1934,3963,1,''),(2,342,1935,7379,1,''),(2,342,1936,1998,1,''),(2,342,1937,2002,1,''),(2,342,1938,2428,1,''),(2,342,1939,3963,1,''),(2,342,1940,7379,1,''),(2,342,1941,1998,1,''),(2,342,1942,2002,1,''),(2,342,1943,2428,1,''),(2,342,1944,3963,1,''),(2,342,1945,7379,1,''),(2,342,1946,1998,1,''),(2,342,1947,2002,1,''),(2,346,1948,2428,1,''),(2,346,1949,3963,1,''),(2,346,1950,7379,1,''),(2,346,1951,1998,1,''),(2,346,1952,2002,1,''),(2,346,1953,2428,1,''),(2,346,1954,3963,1,''),(2,346,1955,7379,1,''),(2,346,1956,1998,1,''),(2,346,1957,2002,1,''),(2,346,1958,2428,1,''),(2,346,1959,3963,1,''),(2,346,1960,7379,1,''),(2,346,1961,1998,1,''),(2,346,1962,2002,1,''),(2,346,1963,2428,1,''),(2,346,1964,3963,1,''),(2,346,1965,7379,1,''),(2,346,1966,1998,1,''),(2,346,1967,2002,1,''),(2,347,1968,2428,1,''),(2,347,1969,3963,1,''),(2,347,1970,7379,1,''),(2,347,1971,1998,1,''),(2,347,1972,2002,1,''),(2,347,1973,2428,1,''),(2,347,1974,3963,1,''),(2,347,1975,7379,1,''),(2,347,1976,1998,1,''),(2,347,1977,2002,1,''),(2,347,1978,2428,1,''),(2,347,1979,3963,1,''),(2,347,1980,7379,1,''),(2,347,1981,1998,1,''),(2,347,1982,2002,1,''),(2,347,1983,2428,1,''),(2,347,1984,3963,1,''),(2,347,1985,7379,1,''),(2,347,1986,1998,1,''),(2,347,1987,2002,1,''),(2,351,1988,2428,1,''),(2,351,1989,3963,1,''),(2,351,1990,7379,1,''),(2,351,1991,1998,1,''),(2,351,1992,2002,1,''),(2,351,1993,2428,1,''),(2,351,1994,3963,1,''),(2,351,1995,7379,1,''),(2,351,1996,1998,1,''),(2,351,1997,2002,1,''),(2,351,1998,2428,1,''),(2,351,1999,3963,1,''),(2,351,2000,7379,1,''),(2,351,2001,1998,1,''),(2,351,2002,2002,1,''),(2,351,2003,2428,1,''),(2,351,2004,3963,1,''),(2,351,2005,7379,1,''),(2,351,2006,1998,1,''),(2,351,2007,2002,1,''),(2,352,2008,2428,1,''),(2,352,2009,3963,1,''),(2,352,2010,7379,1,''),(2,352,2011,1998,1,''),(2,352,2012,2002,1,''),(2,352,2013,2428,1,''),(2,352,2014,3963,1,''),(2,352,2015,7379,1,''),(2,352,2016,1998,1,''),(2,352,2017,2002,1,''),(2,352,2018,2428,1,''),(2,352,2019,3963,1,''),(2,352,2020,7379,1,''),(2,352,2021,1998,1,''),(2,352,2022,2002,1,''),(2,352,2023,2428,1,''),(2,352,2024,3963,1,''),(2,352,2025,7379,1,''),(2,352,2026,1998,1,''),(2,352,2027,2002,1,''),(2,356,2028,2428,1,''),(2,356,2029,3963,1,''),(2,356,2030,7379,1,''),(2,356,2031,1998,1,''),(2,356,2032,2002,1,''),(2,356,2033,2428,1,''),(2,356,2034,3963,1,''),(2,356,2035,7379,1,''),(2,356,2036,1998,1,''),(2,356,2037,2002,1,''),(2,356,2038,2428,1,''),(2,356,2039,3963,1,''),(2,356,2040,7379,1,''),(2,356,2041,1998,1,''),(2,356,2042,2002,1,''),(2,356,2043,2428,1,''),(2,356,2044,3963,1,''),(2,356,2045,7379,1,''),(2,356,2046,1998,1,''),(2,356,2047,2002,1,''),(2,357,2048,2428,1,''),(2,357,2049,3963,1,''),(2,357,2050,7379,1,''),(2,357,2051,1998,1,''),(2,357,2052,2002,1,''),(2,357,2053,2428,1,''),(2,357,2054,3963,1,''),(2,357,2055,7379,1,''),(2,357,2056,1998,1,''),(2,357,2057,2002,1,''),(2,357,2058,2428,1,''),(2,357,2059,3963,1,''),(2,357,2060,7379,1,''),(2,357,2061,1998,1,''),(2,357,2062,2002,1,''),(2,357,2063,2428,1,''),(2,357,2064,3963,1,''),(2,357,2065,7379,1,''),(2,357,2066,1998,1,''),(2,357,2067,2002,1,''),(2,361,2068,2428,1,''),(2,361,2069,3963,1,''),(2,361,2070,7379,1,''),(2,361,2071,1998,1,''),(2,361,2072,2002,1,''),(2,361,2073,2428,1,''),(2,361,2074,3963,1,''),(2,361,2075,7379,1,''),(2,361,2076,1998,1,''),(2,361,2077,2002,1,''),(2,361,2078,2428,1,''),(2,361,2079,3963,1,''),(2,361,2080,7379,1,''),(2,361,2081,1998,1,''),(2,361,2082,2002,1,''),(2,361,2083,2428,1,''),(2,361,2084,3963,1,''),(2,361,2085,7379,1,''),(2,361,2086,1998,1,''),(2,361,2087,2002,1,''),(2,362,2088,2428,1,''),(2,362,2089,3963,1,''),(2,362,2090,7379,1,''),(2,362,2091,1998,1,''),(2,362,2092,2002,1,''),(2,362,2093,2428,1,''),(2,362,2094,3963,1,''),(2,362,2095,7379,1,''),(2,362,2096,1998,1,''),(2,362,2097,2002,1,''),(2,362,2098,2428,1,''),(2,362,2099,3963,1,''),(2,362,2100,7379,1,''),(2,362,2101,1998,1,''),(2,362,2102,2002,1,''),(2,362,2103,2428,1,''),(2,362,2104,3963,1,''),(2,362,2105,7379,1,''),(2,362,2106,1998,1,''),(2,362,2107,2002,1,''),(2,366,2108,2428,1,''),(2,366,2109,3963,1,''),(2,366,2110,7379,1,''),(2,366,2111,1998,1,''),(2,366,2112,2002,1,''),(2,366,2113,2428,1,''),(2,366,2114,3963,1,''),(2,366,2115,7379,1,''),(2,366,2116,1998,1,''),(2,366,2117,2002,1,''),(2,366,2118,2428,1,''),(2,366,2119,3963,1,''),(2,366,2120,7379,1,''),(2,366,2121,1998,1,''),(2,366,2122,2002,1,''),(2,366,2123,2428,1,''),(2,366,2124,3963,1,''),(2,366,2125,7379,1,''),(2,366,2126,1998,1,''),(2,366,2127,2002,1,''),(2,367,2128,2428,1,''),(2,367,2129,3963,1,''),(2,367,2130,7379,1,''),(2,367,2131,1998,1,''),(2,367,2132,2002,1,''),(2,367,2133,2428,1,''),(2,367,2134,3963,1,''),(2,367,2135,7379,1,''),(2,367,2136,1998,1,''),(2,367,2137,2002,1,''),(2,367,2138,2428,1,''),(2,367,2139,3963,1,''),(2,367,2140,7379,1,''),(2,367,2141,1998,1,''),(2,367,2142,2002,1,''),(2,367,2143,2428,1,''),(2,367,2144,3963,1,''),(2,367,2145,7379,1,''),(2,367,2146,1998,1,''),(2,367,2147,2002,1,''),(2,371,2148,2428,1,''),(2,371,2149,3963,1,''),(2,371,2150,7379,1,''),(2,371,2151,1998,1,''),(2,371,2152,2002,1,''),(2,371,2153,2428,1,''),(2,371,2154,3963,1,''),(2,371,2155,7379,1,''),(2,371,2156,1998,1,''),(2,371,2157,2002,1,''),(2,371,2158,2428,1,''),(2,371,2159,3963,1,''),(2,371,2160,7379,1,''),(2,371,2161,1998,1,''),(2,371,2162,2002,1,''),(2,371,2163,2428,1,''),(2,371,2164,3963,1,''),(2,371,2165,7379,1,''),(2,371,2166,1998,1,''),(2,371,2167,2002,1,''),(2,372,2168,2428,1,''),(2,372,2169,3963,1,''),(2,372,2170,7379,1,''),(2,372,2171,1998,1,''),(2,372,2172,2002,1,''),(2,372,2173,2428,1,''),(2,372,2174,3963,1,''),(2,372,2175,7379,1,''),(2,372,2176,1998,1,''),(2,372,2177,2002,1,''),(2,372,2178,2428,1,''),(2,372,2179,3963,1,''),(2,372,2180,7379,1,''),(2,372,2181,1998,1,''),(2,372,2182,2002,1,''),(2,372,2183,2428,1,''),(2,372,2184,3963,1,''),(2,372,2185,7379,1,''),(2,372,2186,1998,1,''),(2,372,2187,2002,1,''),(2,376,2188,2428,1,''),(2,376,2189,3963,1,''),(2,376,2190,7379,1,''),(2,376,2191,1998,1,''),(2,376,2192,2002,1,''),(2,376,2193,2428,1,''),(2,376,2194,3963,1,''),(2,376,2195,7379,1,''),(2,376,2196,1998,1,''),(2,376,2197,2002,1,''),(2,376,2198,2428,1,''),(2,376,2199,3963,1,''),(2,376,2200,7379,1,''),(2,376,2201,1998,1,''),(2,376,2202,2002,1,''),(2,376,2203,2428,1,''),(2,376,2204,3963,1,''),(2,376,2205,7379,1,''),(2,376,2206,1998,1,''),(2,376,2207,2002,1,''),(2,377,2208,2428,1,''),(2,377,2209,3963,1,''),(2,377,2210,7379,1,''),(2,377,2211,1998,1,''),(2,377,2212,2002,1,''),(2,377,2213,2428,1,''),(2,377,2214,3963,1,''),(2,377,2215,7379,1,''),(2,377,2216,1998,1,''),(2,377,2217,2002,1,''),(2,377,2218,2428,1,''),(2,377,2219,3963,1,''),(2,377,2220,7379,1,''),(2,377,2221,1998,1,''),(2,377,2222,2002,1,''),(2,377,2223,2428,1,''),(2,377,2224,3963,1,''),(2,377,2225,7379,1,''),(2,377,2226,1998,1,''),(2,377,2227,2002,1,''),(2,381,2228,2428,1,''),(2,381,2229,3963,1,''),(2,381,2230,7379,1,''),(2,381,2231,1998,1,''),(2,381,2232,2002,1,''),(2,381,2233,2428,1,''),(2,381,2234,3963,1,''),(2,381,2235,7379,1,''),(2,381,2236,1998,1,''),(2,381,2237,2002,1,''),(2,381,2238,2428,1,''),(2,381,2239,3963,1,''),(2,381,2240,7379,1,''),(2,381,2241,1998,1,''),(2,381,2242,2002,1,''),(2,381,2243,2428,1,''),(2,381,2244,3963,1,''),(2,381,2245,7379,1,''),(2,381,2246,1998,1,''),(2,381,2247,2002,1,''),(2,382,2248,2428,1,''),(2,382,2249,3963,1,''),(2,382,2250,7379,1,''),(2,382,2251,1998,1,''),(2,382,2252,2002,1,''),(2,382,2253,2428,1,''),(2,382,2254,3963,1,''),(2,382,2255,7379,1,''),(2,382,2256,1998,1,''),(2,382,2257,2002,1,''),(2,382,2258,2428,1,''),(2,382,2259,3963,1,''),(2,382,2260,7379,1,''),(2,382,2261,1998,1,''),(2,382,2262,2002,1,''),(2,382,2263,2428,1,''),(2,382,2264,3963,1,''),(2,382,2265,7379,1,''),(2,382,2266,1998,1,''),(2,382,2267,2002,1,''),(2,386,2268,2428,1,''),(2,386,2269,3963,1,''),(2,386,2270,7379,1,''),(2,386,2271,1998,1,''),(2,386,2272,2002,1,''),(2,386,2273,2428,1,''),(2,386,2274,3963,1,''),(2,386,2275,7379,1,''),(2,386,2276,1998,1,''),(2,386,2277,2002,1,''),(2,386,2278,2428,1,''),(2,386,2279,3963,1,''),(2,386,2280,7379,1,''),(2,386,2281,1998,1,''),(2,386,2282,2002,1,''),(2,386,2283,2428,1,''),(2,386,2284,3963,1,''),(2,386,2285,7379,1,''),(2,386,2286,1998,1,''),(2,386,2287,2002,1,''),(2,387,2288,2428,1,''),(2,387,2289,3963,1,''),(2,387,2290,7379,1,''),(2,387,2291,1998,1,''),(2,387,2292,2002,1,''),(2,387,2293,2428,1,''),(2,387,2294,3963,1,''),(2,387,2295,7379,1,''),(2,387,2296,1998,1,''),(2,387,2297,2002,1,''),(2,387,2298,2428,1,''),(2,387,2299,3963,1,''),(2,387,2300,7379,1,''),(2,387,2301,1998,1,''),(2,387,2302,2002,1,''),(2,387,2303,2428,1,''),(2,387,2304,3963,1,''),(2,387,2305,7379,1,''),(2,387,2306,1998,1,''),(2,387,2307,2002,1,''),(2,391,2308,2428,1,''),(2,391,2309,3963,1,''),(2,391,2310,7379,1,''),(2,391,2311,1998,1,''),(2,391,2312,2002,1,''),(2,391,2313,2428,1,''),(2,391,2314,3963,1,''),(2,391,2315,7379,1,''),(2,391,2316,1998,1,''),(2,391,2317,2002,1,''),(2,391,2318,2428,1,''),(2,391,2319,3963,1,''),(2,391,2320,7379,1,''),(2,391,2321,1998,1,''),(2,391,2322,2002,1,''),(2,391,2323,2428,1,''),(2,391,2324,3963,1,''),(2,391,2325,7379,1,''),(2,391,2326,1998,1,''),(2,391,2327,2002,1,''),(2,392,2328,2428,1,''),(2,392,2329,3963,1,''),(2,392,2330,7379,1,''),(2,392,2331,1998,1,''),(2,392,2332,2002,1,''),(2,392,2333,2428,1,''),(2,392,2334,3963,1,''),(2,392,2335,7379,1,''),(2,392,2336,1998,1,''),(2,392,2337,2002,1,''),(2,392,2338,2428,1,''),(2,392,2339,3963,1,''),(2,392,2340,7379,1,''),(2,392,2341,1998,1,''),(2,392,2342,2002,1,''),(2,392,2343,2428,1,''),(2,392,2344,3963,1,''),(2,392,2345,7379,1,''),(2,392,2346,1998,1,''),(2,392,2347,2002,1,''),(2,396,2348,2428,1,''),(2,396,2349,3963,1,''),(2,396,2350,7379,1,''),(2,396,2351,1998,1,''),(2,396,2352,2002,1,''),(2,396,2353,2428,1,''),(2,396,2354,3963,1,''),(2,396,2355,7379,1,''),(2,396,2356,1998,1,''),(2,396,2357,2002,1,''),(2,396,2358,2428,1,''),(2,396,2359,3963,1,''),(2,396,2360,7379,1,''),(2,396,2361,1998,1,''),(2,396,2362,2002,1,''),(2,396,2363,2428,1,''),(2,396,2364,3963,1,''),(2,396,2365,7379,1,''),(2,396,2366,1998,1,''),(2,396,2367,2002,1,''),(2,397,2368,2428,1,''),(2,397,2369,3963,1,''),(2,397,2370,7379,1,''),(2,397,2371,1998,1,''),(2,397,2372,2002,1,''),(2,397,2373,2428,1,''),(2,397,2374,3963,1,''),(2,397,2375,7379,1,''),(2,397,2376,1998,1,''),(2,397,2377,2002,1,''),(2,397,2378,2428,1,''),(2,397,2379,3963,1,''),(2,397,2380,7379,1,''),(2,397,2381,1998,1,''),(2,397,2382,2002,1,''),(2,397,2383,2428,1,''),(2,397,2384,3963,1,''),(2,397,2385,7379,1,''),(2,397,2386,1998,1,''),(2,397,2387,2002,1,''),(2,401,2388,2428,1,''),(2,401,2389,3963,1,''),(2,401,2390,7379,1,''),(2,401,2391,1998,1,''),(2,401,2392,2002,1,''),(2,401,2393,2428,1,''),(2,401,2394,3963,1,''),(2,401,2395,7379,1,''),(2,401,2396,1998,1,''),(2,401,2397,2002,1,''),(2,401,2398,2428,1,''),(2,401,2399,3963,1,''),(2,401,2400,7379,1,''),(2,401,2401,1998,1,''),(2,401,2402,2002,1,''),(2,401,2403,2428,1,''),(2,401,2404,3963,1,''),(2,401,2405,7379,1,''),(2,401,2406,1998,1,''),(2,401,2407,2002,1,''),(2,402,2408,2428,1,''),(2,402,2409,3963,1,''),(2,402,2410,7379,1,''),(2,402,2411,1998,1,''),(2,402,2412,2002,1,''),(2,402,2413,2428,1,''),(2,402,2414,3963,1,''),(2,402,2415,7379,1,''),(2,402,2416,1998,1,''),(2,402,2417,2002,1,''),(2,402,2418,2428,1,''),(2,402,2419,3963,1,''),(2,402,2420,7379,1,''),(2,402,2421,1998,1,''),(2,402,2422,2002,1,''),(2,402,2423,2428,1,''),(2,402,2424,3963,1,''),(2,402,2425,7379,1,''),(2,402,2426,1998,1,''),(2,402,2427,2002,1,''),(2,406,2428,2428,1,''),(2,406,2429,3963,1,''),(2,406,2430,7379,1,''),(2,406,2431,1998,1,''),(2,406,2432,2002,1,''),(2,406,2433,2428,1,''),(2,406,2434,3963,1,''),(2,406,2435,7379,1,''),(2,406,2436,1998,1,''),(2,406,2437,2002,1,''),(2,406,2438,2428,1,''),(2,406,2439,3963,1,''),(2,406,2440,7379,1,''),(2,406,2441,1998,1,''),(2,406,2442,2002,1,''),(2,406,2443,2428,1,''),(2,406,2444,3963,1,''),(2,406,2445,7379,1,''),(2,406,2446,1998,1,''),(2,406,2447,2002,1,''),(2,407,2448,2428,1,''),(2,407,2449,3963,1,''),(2,407,2450,7379,1,''),(2,407,2451,1998,1,''),(2,407,2452,2002,1,''),(2,407,2453,2428,1,''),(2,407,2454,3963,1,''),(2,407,2455,7379,1,''),(2,407,2456,1998,1,''),(2,407,2457,2002,1,''),(2,407,2458,2428,1,''),(2,407,2459,3963,1,''),(2,407,2460,7379,1,''),(2,407,2461,1998,1,''),(2,407,2462,2002,1,''),(2,407,2463,2428,1,''),(2,407,2464,3963,1,''),(2,407,2465,7379,1,''),(2,407,2466,1998,1,''),(2,407,2467,2002,1,''),(2,411,2468,2428,1,''),(2,411,2469,3963,1,''),(2,411,2470,7379,1,''),(2,411,2471,1998,1,''),(2,411,2472,2002,1,''),(2,411,2473,2428,1,''),(2,411,2474,3963,1,''),(2,411,2475,7379,1,''),(2,411,2476,1998,1,''),(2,411,2477,2002,1,''),(2,411,2478,2428,1,''),(2,411,2479,3963,1,''),(2,411,2480,7379,1,''),(2,411,2481,1998,1,''),(2,411,2482,2002,1,''),(2,411,2483,2428,1,''),(2,411,2484,3963,1,''),(2,411,2485,7379,1,''),(2,411,2486,1998,1,''),(2,411,2487,2002,1,''),(2,412,2488,2428,1,''),(2,412,2489,3963,1,''),(2,412,2490,7379,1,''),(2,412,2491,1998,1,''),(2,412,2492,2002,1,''),(2,412,2493,2428,1,''),(2,412,2494,3963,1,''),(2,412,2495,7379,1,''),(2,412,2496,1998,1,''),(2,412,2497,2002,1,''),(2,412,2498,2428,1,''),(2,412,2499,3963,1,''),(2,412,2500,7379,1,''),(2,412,2501,1998,1,''),(2,412,2502,2002,1,''),(2,412,2503,2428,1,''),(2,412,2504,3963,1,''),(2,412,2505,7379,1,''),(2,412,2506,1998,1,''),(2,412,2507,2002,1,''),(2,416,2508,2428,1,''),(2,416,2509,3963,1,''),(2,416,2510,7379,1,''),(2,416,2511,1998,1,''),(2,416,2512,2002,1,''),(2,416,2513,2428,1,''),(2,416,2514,3963,1,''),(2,416,2515,7379,1,''),(2,416,2516,1998,1,''),(2,416,2517,2002,1,''),(2,416,2518,2428,1,''),(2,416,2519,3963,1,''),(2,416,2520,7379,1,''),(2,416,2521,1998,1,''),(2,416,2522,2002,1,''),(2,416,2523,2428,1,''),(2,416,2524,3963,1,''),(2,416,2525,7379,1,''),(2,416,2526,1998,1,''),(2,416,2527,2002,1,''),(2,417,2528,2428,1,''),(2,417,2529,3963,1,''),(2,417,2530,7379,1,''),(2,417,2531,1998,1,''),(2,417,2532,2002,1,''),(2,417,2533,2428,1,''),(2,417,2534,3963,1,''),(2,417,2535,7379,1,''),(2,417,2536,1998,1,''),(2,417,2537,2002,1,''),(2,417,2538,2428,1,''),(2,417,2539,3963,1,''),(2,417,2540,7379,1,''),(2,417,2541,1998,1,''),(2,417,2542,2002,1,''),(2,417,2543,2428,1,''),(2,417,2544,3963,1,''),(2,417,2545,7379,1,''),(2,417,2546,1998,1,''),(2,417,2547,2002,1,''),(2,421,2548,2428,1,''),(2,421,2549,3963,1,''),(2,421,2550,7379,1,''),(2,421,2551,1998,1,''),(2,421,2552,2002,1,''),(2,421,2553,2428,1,''),(2,421,2554,3963,1,''),(2,421,2555,7379,1,''),(2,421,2556,1998,1,''),(2,421,2557,2002,1,''),(2,421,2558,2428,1,''),(2,421,2559,3963,1,''),(2,421,2560,7379,1,''),(2,421,2561,1998,1,''),(2,421,2562,2002,1,''),(2,421,2563,2428,1,''),(2,421,2564,3963,1,''),(2,421,2565,7379,1,''),(2,421,2566,1998,1,''),(2,421,2567,2002,1,''),(2,422,2568,2428,1,''),(2,422,2569,3963,1,''),(2,422,2570,7379,1,''),(2,422,2571,1998,1,''),(2,422,2572,2002,1,''),(2,422,2573,2428,1,''),(2,422,2574,3963,1,''),(2,422,2575,7379,1,''),(2,422,2576,1998,1,''),(2,422,2577,2002,1,''),(2,422,2578,2428,1,''),(2,422,2579,3963,1,''),(2,422,2580,7379,1,''),(2,422,2581,1998,1,''),(2,422,2582,2002,1,''),(2,422,2583,2428,1,''),(2,422,2584,3963,1,''),(2,422,2585,7379,1,''),(2,422,2586,1998,1,''),(2,422,2587,2002,1,''),(2,426,2588,2428,1,''),(2,426,2589,3963,1,''),(2,426,2590,7379,1,''),(2,426,2591,1998,1,''),(2,426,2592,2002,1,''),(2,426,2593,2428,1,''),(2,426,2594,3963,1,''),(2,426,2595,7379,1,''),(2,426,2596,1998,1,''),(2,426,2597,2002,1,''),(2,426,2598,2428,1,''),(2,426,2599,3963,1,''),(2,426,2600,7379,1,''),(2,426,2601,1998,1,''),(2,426,2602,2002,1,''),(2,426,2603,2428,1,''),(2,426,2604,3963,1,''),(2,426,2605,7379,1,''),(2,426,2606,1998,1,''),(2,426,2607,2002,1,''),(2,427,2608,2428,1,''),(2,427,2609,3963,1,''),(2,427,2610,7379,1,''),(2,427,2611,1998,1,''),(2,427,2612,2002,1,''),(2,427,2613,2428,1,''),(2,427,2614,3963,1,''),(2,427,2615,7379,1,''),(2,427,2616,1998,1,''),(2,427,2617,2002,1,''),(2,427,2618,2428,1,''),(2,427,2619,3963,1,''),(2,427,2620,7379,1,''),(2,427,2621,1998,1,''),(2,427,2622,2002,1,''),(2,427,2623,2428,1,''),(2,427,2624,3963,1,''),(2,427,2625,7379,1,''),(2,427,2626,1998,1,''),(2,427,2627,2002,1,''),(2,431,2628,2428,1,''),(2,431,2629,3963,1,''),(2,431,2630,7379,1,''),(2,431,2631,1998,1,''),(2,431,2632,2002,1,''),(2,431,2633,2428,1,''),(2,431,2634,3963,1,''),(2,431,2635,7379,1,''),(2,431,2636,1998,1,''),(2,431,2637,2002,1,''),(2,431,2638,2428,1,''),(2,431,2639,3963,1,''),(2,431,2640,7379,1,''),(2,431,2641,1998,1,''),(2,431,2642,2002,1,''),(2,431,2643,2428,1,''),(2,431,2644,3963,1,''),(2,431,2645,7379,1,''),(2,431,2646,1998,1,''),(2,431,2647,2002,1,''),(2,432,2648,2428,1,''),(2,432,2649,3963,1,''),(2,432,2650,7379,1,''),(2,432,2651,1998,1,''),(2,432,2652,2002,1,''),(2,432,2653,2428,1,''),(2,432,2654,3963,1,''),(2,432,2655,7379,1,''),(2,432,2656,1998,1,''),(2,432,2657,2002,1,''),(2,432,2658,2428,1,''),(2,432,2659,3963,1,''),(2,432,2660,7379,1,''),(2,432,2661,1998,1,''),(2,432,2662,2002,1,''),(2,432,2663,2428,1,''),(2,432,2664,3963,1,''),(2,432,2665,7379,1,''),(2,432,2666,1998,1,''),(2,432,2667,2002,1,''),(2,436,2668,2428,1,''),(2,436,2669,3963,1,''),(2,436,2670,7379,1,''),(2,436,2671,1998,1,''),(2,436,2672,2002,1,''),(2,436,2673,2428,1,''),(2,436,2674,3963,1,''),(2,436,2675,7379,1,''),(2,436,2676,1998,1,''),(2,436,2677,2002,1,''),(2,436,2678,2428,1,''),(2,436,2679,3963,1,''),(2,436,2680,7379,1,''),(2,436,2681,1998,1,''),(2,436,2682,2002,1,''),(2,436,2683,2428,1,''),(2,436,2684,3963,1,''),(2,436,2685,7379,1,''),(2,436,2686,1998,1,''),(2,436,2687,2002,1,''),(2,437,2688,2428,1,''),(2,437,2689,3963,1,''),(2,437,2690,7379,1,''),(2,437,2691,1998,1,''),(2,437,2692,2002,1,''),(2,437,2693,2428,1,''),(2,437,2694,3963,1,''),(2,437,2695,7379,1,''),(2,437,2696,1998,1,''),(2,437,2697,2002,1,''),(2,437,2698,2428,1,''),(2,437,2699,3963,1,''),(2,437,2700,7379,1,''),(2,437,2701,1998,1,''),(2,437,2702,2002,1,''),(2,437,2703,2428,1,''),(2,437,2704,3963,1,''),(2,437,2705,7379,1,''),(2,437,2706,1998,1,''),(2,437,2707,2002,1,''),(2,441,2708,2428,1,''),(2,441,2709,3963,1,''),(2,441,2710,7379,1,''),(2,441,2711,1998,1,''),(2,441,2712,2002,1,''),(2,441,2713,2428,1,''),(2,441,2714,3963,1,''),(2,441,2715,7379,1,''),(2,441,2716,1998,1,''),(2,441,2717,2002,1,''),(2,441,2718,2428,1,''),(2,441,2719,3963,1,''),(2,441,2720,7379,1,''),(2,441,2721,1998,1,''),(2,441,2722,2002,1,''),(2,441,2723,2428,1,''),(2,441,2724,3963,1,''),(2,441,2725,7379,1,''),(2,441,2726,1998,1,''),(2,441,2727,2002,1,''),(2,442,2728,2428,1,''),(2,442,2729,3963,1,''),(2,442,2730,7379,1,''),(2,442,2731,1998,1,''),(2,442,2732,2002,1,''),(2,442,2733,2428,1,''),(2,442,2734,3963,1,''),(2,442,2735,7379,1,''),(2,442,2736,1998,1,''),(2,442,2737,2002,1,''),(2,442,2738,2428,1,''),(2,442,2739,3963,1,''),(2,442,2740,7379,1,''),(2,442,2741,1998,1,''),(2,442,2742,2002,1,''),(2,442,2743,2428,1,''),(2,442,2744,3963,1,''),(2,442,2745,7379,1,''),(2,442,2746,1998,1,''),(2,442,2747,2002,1,''),(2,446,2748,2428,1,''),(2,446,2749,3963,1,''),(2,446,2750,7379,1,''),(2,446,2751,1998,1,''),(2,446,2752,2002,1,''),(2,446,2753,2428,1,''),(2,446,2754,3963,1,''),(2,446,2755,7379,1,''),(2,446,2756,1998,1,''),(2,446,2757,2002,1,''),(2,446,2758,2428,1,''),(2,446,2759,3963,1,''),(2,446,2760,7379,1,''),(2,446,2761,1998,1,''),(2,446,2762,2002,1,''),(2,446,2763,2428,1,''),(2,446,2764,3963,1,''),(2,446,2765,7379,1,''),(2,446,2766,1998,1,''),(2,446,2767,2002,1,''),(2,447,2768,2428,1,''),(2,447,2769,3963,1,''),(2,447,2770,7379,1,''),(2,447,2771,1998,1,''),(2,447,2772,2002,1,''),(2,447,2773,2428,1,''),(2,447,2774,3963,1,''),(2,447,2775,7379,1,''),(2,447,2776,1998,1,''),(2,447,2777,2002,1,''),(2,447,2778,2428,1,''),(2,447,2779,3963,1,''),(2,447,2780,7379,1,''),(2,447,2781,1998,1,''),(2,447,2782,2002,1,''),(2,447,2783,2428,1,''),(2,447,2784,3963,1,''),(2,447,2785,7379,1,''),(2,447,2786,1998,1,''),(2,447,2787,2002,1,''),(2,451,2788,2428,1,''),(2,451,2789,3963,1,''),(2,451,2790,7379,1,''),(2,451,2791,1998,1,''),(2,451,2792,2002,1,''),(2,451,2793,2428,1,''),(2,451,2794,3963,1,''),(2,451,2795,7379,1,''),(2,451,2796,1998,1,''),(2,451,2797,2002,1,''),(2,451,2798,2428,1,''),(2,451,2799,3963,1,''),(2,451,2800,7379,1,''),(2,451,2801,1998,1,''),(2,451,2802,2002,1,''),(2,451,2803,2428,1,''),(2,451,2804,3963,1,''),(2,451,2805,7379,1,''),(2,451,2806,1998,1,''),(2,451,2807,2002,1,''),(2,452,2808,2428,1,''),(2,452,2809,3963,1,''),(2,452,2810,7379,1,''),(2,452,2811,1998,1,''),(2,452,2812,2002,1,''),(2,452,2813,2428,1,''),(2,452,2814,3963,1,''),(2,452,2815,7379,1,''),(2,452,2816,1998,1,''),(2,452,2817,2002,1,''),(2,452,2818,2428,1,''),(2,452,2819,3963,1,''),(2,452,2820,7379,1,''),(2,452,2821,1998,1,''),(2,452,2822,2002,1,''),(2,452,2823,2428,1,''),(2,452,2824,3963,1,''),(2,452,2825,7379,1,''),(2,452,2826,1998,1,''),(2,452,2827,2002,1,''),(2,456,2828,2428,1,''),(2,456,2829,3963,1,''),(2,456,2830,7379,1,''),(2,456,2831,1998,1,''),(2,456,2832,2002,1,''),(2,456,2833,2428,1,''),(2,456,2834,3963,1,''),(2,456,2835,7379,1,''),(2,456,2836,1998,1,''),(2,456,2837,2002,1,''),(2,456,2838,2428,1,''),(2,456,2839,3963,1,''),(2,456,2840,7379,1,''),(2,456,2841,1998,1,''),(2,456,2842,2002,1,''),(2,456,2843,2428,1,''),(2,456,2844,3963,1,''),(2,456,2845,7379,1,''),(2,456,2846,1998,1,''),(2,456,2847,2002,1,''),(2,457,2848,2428,1,''),(2,457,2849,3963,1,''),(2,457,2850,7379,1,''),(2,457,2851,1998,1,''),(2,457,2852,2002,1,''),(2,457,2853,2428,1,''),(2,457,2854,3963,1,''),(2,457,2855,7379,1,''),(2,457,2856,1998,1,''),(2,457,2857,2002,1,''),(2,457,2858,2428,1,''),(2,457,2859,3963,1,''),(2,457,2860,7379,1,''),(2,457,2861,1998,1,''),(2,457,2862,2002,1,''),(2,457,2863,2428,1,''),(2,457,2864,3963,1,''),(2,457,2865,7379,1,''),(2,457,2866,1998,1,''),(2,457,2867,2002,1,''),(2,461,2868,2428,1,''),(2,461,2869,3963,1,''),(2,461,2870,7379,1,''),(2,461,2871,1998,1,''),(2,461,2872,2002,1,''),(2,461,2873,2428,1,''),(2,461,2874,3963,1,''),(2,461,2875,7379,1,''),(2,461,2876,1998,1,''),(2,461,2877,2002,1,''),(2,461,2878,2428,1,''),(2,461,2879,3963,1,''),(2,461,2880,7379,1,''),(2,461,2881,1998,1,''),(2,461,2882,2002,1,''),(2,461,2883,2428,1,''),(2,461,2884,3963,1,''),(2,461,2885,7379,1,''),(2,461,2886,1998,1,''),(2,461,2887,2002,1,''),(2,462,2888,2428,1,''),(2,462,2889,3963,1,''),(2,462,2890,7379,1,''),(2,462,2891,1998,1,''),(2,462,2892,2002,1,''),(2,462,2893,2428,1,''),(2,462,2894,3963,1,''),(2,462,2895,7379,1,''),(2,462,2896,1998,1,''),(2,462,2897,2002,1,''),(2,462,2898,2428,1,''),(2,462,2899,3963,1,''),(2,462,2900,7379,1,''),(2,462,2901,1998,1,''),(2,462,2902,2002,1,''),(2,462,2903,2428,1,''),(2,462,2904,3963,1,''),(2,462,2905,7379,1,''),(2,462,2906,1998,1,''),(2,462,2907,2002,1,''),(2,466,2908,2428,1,''),(2,466,2909,3963,1,''),(2,466,2910,7379,1,''),(2,466,2911,1998,1,''),(2,466,2912,2002,1,''),(2,466,2913,2428,1,''),(2,466,2914,3963,1,''),(2,466,2915,7379,1,''),(2,466,2916,1998,1,''),(2,466,2917,2002,1,''),(2,466,2918,2428,1,''),(2,466,2919,3963,1,''),(2,466,2920,7379,1,''),(2,466,2921,1998,1,''),(2,466,2922,2002,1,''),(2,466,2923,2428,1,''),(2,466,2924,3963,1,''),(2,466,2925,7379,1,''),(2,466,2926,1998,1,''),(2,466,2927,2002,1,''),(2,467,2928,2428,1,''),(2,467,2929,3963,1,''),(2,467,2930,7379,1,''),(2,467,2931,1998,1,''),(2,467,2932,2002,1,''),(2,467,2933,2428,1,''),(2,467,2934,3963,1,''),(2,467,2935,7379,1,''),(2,467,2936,1998,1,''),(2,467,2937,2002,1,''),(2,467,2938,2428,1,''),(2,467,2939,3963,1,''),(2,467,2940,7379,1,''),(2,467,2941,1998,1,''),(2,467,2942,2002,1,''),(2,467,2943,2428,1,''),(2,467,2944,3963,1,''),(2,467,2945,7379,1,''),(2,467,2946,1998,1,''),(2,467,2947,2002,1,''),(2,471,2948,2428,1,''),(2,471,2949,3963,1,''),(2,471,2950,7379,1,''),(2,471,2951,1998,1,''),(2,471,2952,2002,1,''),(2,471,2953,2428,1,''),(2,471,2954,3963,1,''),(2,471,2955,7379,1,''),(2,471,2956,1998,1,''),(2,471,2957,2002,1,''),(2,471,2958,2428,1,''),(2,471,2959,3963,1,''),(2,471,2960,7379,1,''),(2,471,2961,1998,1,''),(2,471,2962,2002,1,''),(2,471,2963,2428,1,''),(2,471,2964,3963,1,''),(2,471,2965,7379,1,''),(2,471,2966,1998,1,''),(2,471,2967,2002,1,''),(2,472,2968,2428,1,''),(2,472,2969,3963,1,''),(2,472,2970,7379,1,''),(2,472,2971,1998,1,''),(2,472,2972,2002,1,''),(2,472,2973,2428,1,''),(2,472,2974,3963,1,''),(2,472,2975,7379,1,''),(2,472,2976,1998,1,''),(2,472,2977,2002,1,''),(2,472,2978,2428,1,''),(2,472,2979,3963,1,''),(2,472,2980,7379,1,''),(2,472,2981,1998,1,''),(2,472,2982,2002,1,''),(2,472,2983,2428,1,''),(2,472,2984,3963,1,''),(2,472,2985,7379,1,''),(2,472,2986,1998,1,''),(2,472,2987,2002,1,''),(2,476,2988,2428,1,''),(2,476,2989,3963,1,''),(2,476,2990,7379,1,''),(2,476,2991,1998,1,''),(2,476,2992,2002,1,''),(2,476,2993,2428,1,''),(2,476,2994,3963,1,''),(2,476,2995,7379,1,''),(2,476,2996,1998,1,''),(2,476,2997,2002,1,''),(2,476,2998,2428,1,''),(2,476,2999,3963,1,''),(2,476,3000,7379,1,''),(2,476,3001,1998,1,''),(2,476,3002,2002,1,''),(2,476,3003,2428,1,''),(2,476,3004,3963,1,''),(2,476,3005,7379,1,''),(2,476,3006,1998,1,''),(2,476,3007,2002,1,''),(2,477,3008,2428,1,''),(2,477,3009,3963,1,''),(2,477,3010,7379,1,''),(2,477,3011,1998,1,''),(2,477,3012,2002,1,''),(2,477,3013,2428,1,''),(2,477,3014,3963,1,''),(2,477,3015,7379,1,''),(2,477,3016,1998,1,''),(2,477,3017,2002,1,''),(2,477,3018,2428,1,''),(2,477,3019,3963,1,''),(2,477,3020,7379,1,''),(2,477,3021,1998,1,''),(2,477,3022,2002,1,''),(2,477,3023,2428,1,''),(2,477,3024,3963,1,''),(2,477,3025,7379,1,''),(2,477,3026,1998,1,''),(2,477,3027,2002,1,''),(2,481,3028,2428,1,''),(2,481,3029,3963,1,''),(2,481,3030,7379,1,''),(2,481,3031,1998,1,''),(2,481,3032,2002,1,''),(2,481,3033,2428,1,''),(2,481,3034,3963,1,''),(2,481,3035,7379,1,''),(2,481,3036,1998,1,''),(2,481,3037,2002,1,''),(2,481,3038,2428,1,''),(2,481,3039,3963,1,''),(2,481,3040,7379,1,''),(2,481,3041,1998,1,''),(2,481,3042,2002,1,''),(2,481,3043,2428,1,''),(2,481,3044,3963,1,''),(2,481,3045,7379,1,''),(2,481,3046,1998,1,''),(2,481,3047,2002,1,''),(2,482,3048,2428,1,''),(2,482,3049,3963,1,''),(2,482,3050,7379,1,''),(2,482,3051,1998,1,''),(2,482,3052,2002,1,''),(2,482,3053,2428,1,''),(2,482,3054,3963,1,''),(2,482,3055,7379,1,''),(2,482,3056,1998,1,''),(2,482,3057,2002,1,''),(2,482,3058,2428,1,''),(2,482,3059,3963,1,''),(2,482,3060,7379,1,''),(2,482,3061,1998,1,''),(2,482,3062,2002,1,''),(2,482,3063,2428,1,''),(2,482,3064,3963,1,''),(2,482,3065,7379,1,''),(2,482,3066,1998,1,''),(2,482,3067,2002,1,''),(2,486,3068,2428,1,''),(2,486,3069,3963,1,''),(2,486,3070,7379,1,''),(2,486,3071,1998,1,''),(2,486,3072,2002,1,''),(2,486,3073,2428,1,''),(2,486,3074,3963,1,''),(2,486,3075,7379,1,''),(2,486,3076,1998,1,''),(2,486,3077,2002,1,''),(2,486,3078,2428,1,''),(2,486,3079,3963,1,''),(2,486,3080,7379,1,''),(2,486,3081,1998,1,''),(2,486,3082,2002,1,''),(2,486,3083,2428,1,''),(2,486,3084,3963,1,''),(2,486,3085,7379,1,''),(2,486,3086,1998,1,''),(2,486,3087,2002,1,''),(2,487,3088,2428,1,''),(2,487,3089,3963,1,''),(2,487,3090,7379,1,''),(2,487,3091,1998,1,''),(2,487,3092,2002,1,''),(2,487,3093,2428,1,''),(2,487,3094,3963,1,''),(2,487,3095,7379,1,''),(2,487,3096,1998,1,''),(2,487,3097,2002,1,''),(2,487,3098,2428,1,''),(2,487,3099,3963,1,''),(2,487,3100,7379,1,''),(2,487,3101,1998,1,''),(2,487,3102,2002,1,''),(2,487,3103,2428,1,''),(2,487,3104,3963,1,''),(2,487,3105,7379,1,''),(2,487,3106,1998,1,''),(2,487,3107,2002,1,''),(2,491,3108,2428,1,''),(2,491,3109,3963,1,''),(2,491,3110,7379,1,''),(2,491,3111,1998,1,''),(2,491,3112,2002,1,''),(2,491,3113,2428,1,''),(2,491,3114,3963,1,''),(2,491,3115,7379,1,''),(2,491,3116,1998,1,''),(2,491,3117,2002,1,''),(2,491,3118,2428,1,''),(2,491,3119,3963,1,''),(2,491,3120,7379,1,''),(2,491,3121,1998,1,''),(2,491,3122,2002,1,''),(2,491,3123,2428,1,''),(2,491,3124,3963,1,''),(2,491,3125,7379,1,''),(2,491,3126,1998,1,''),(2,491,3127,2002,1,''),(2,492,3128,2428,1,''),(2,492,3129,3963,1,''),(2,492,3130,7379,1,''),(2,492,3131,1998,1,''),(2,492,3132,2002,1,''),(2,492,3133,2428,1,''),(2,492,3134,3963,1,''),(2,492,3135,7379,1,''),(2,492,3136,1998,1,''),(2,492,3137,2002,1,''),(2,492,3138,2428,1,''),(2,492,3139,3963,1,''),(2,492,3140,7379,1,''),(2,492,3141,1998,1,''),(2,492,3142,2002,1,''),(2,492,3143,2428,1,''),(2,492,3144,3963,1,''),(2,492,3145,7379,1,''),(2,492,3146,1998,1,''),(2,492,3147,2002,1,''),(2,496,3148,2428,1,''),(2,496,3149,3963,1,''),(2,496,3150,7379,1,''),(2,496,3151,1998,1,''),(2,496,3152,2002,1,''),(2,496,3153,2428,1,''),(2,496,3154,3963,1,''),(2,496,3155,7379,1,''),(2,496,3156,1998,1,''),(2,496,3157,2002,1,''),(2,496,3158,2428,1,''),(2,496,3159,3963,1,''),(2,496,3160,7379,1,''),(2,496,3161,1998,1,''),(2,496,3162,2002,1,''),(2,496,3163,2428,1,''),(2,496,3164,3963,1,''),(2,496,3165,7379,1,''),(2,496,3166,1998,1,''),(2,496,3167,2002,1,''),(2,497,3168,2428,1,''),(2,497,3169,3963,1,''),(2,497,3170,7379,1,''),(2,497,3171,1998,1,''),(2,497,3172,2002,1,''),(2,497,3173,2428,1,''),(2,497,3174,3963,1,''),(2,497,3175,7379,1,''),(2,497,3176,1998,1,''),(2,497,3177,2002,1,''),(2,497,3178,2428,1,''),(2,497,3179,3963,1,''),(2,497,3180,7379,1,''),(2,497,3181,1998,1,''),(2,497,3182,2002,1,''),(2,497,3183,2428,1,''),(2,497,3184,3963,1,''),(2,497,3185,7379,1,''),(2,497,3186,1998,1,''),(2,497,3187,2002,1,''),(2,501,3188,2428,1,''),(2,501,3189,3963,1,''),(2,501,3190,7379,1,''),(2,501,3191,1998,1,''),(2,501,3192,2002,1,''),(2,501,3193,2428,1,''),(2,501,3194,3963,1,''),(2,501,3195,7379,1,''),(2,501,3196,1998,1,''),(2,501,3197,2002,1,''),(2,501,3198,2428,1,''),(2,501,3199,3963,1,''),(2,501,3200,7379,1,''),(2,501,3201,1998,1,''),(2,501,3202,2002,1,''),(2,501,3203,2428,1,''),(2,501,3204,3963,1,''),(2,501,3205,7379,1,''),(2,501,3206,1998,1,''),(2,501,3207,2002,1,''),(2,502,3208,2428,1,''),(2,502,3209,3963,1,''),(2,502,3210,7379,1,''),(2,502,3211,1998,1,''),(2,502,3212,2002,1,''),(2,502,3213,2428,1,''),(2,502,3214,3963,1,''),(2,502,3215,7379,1,''),(2,502,3216,1998,1,''),(2,502,3217,2002,1,''),(2,502,3218,2428,1,''),(2,502,3219,3963,1,''),(2,502,3220,7379,1,''),(2,502,3221,1998,1,''),(2,502,3222,2002,1,''),(2,502,3223,2428,1,''),(2,502,3224,3963,1,''),(2,502,3225,7379,1,''),(2,502,3226,1998,1,''),(2,502,3227,2002,1,''),(2,506,3228,2428,1,''),(2,506,3229,3963,1,''),(2,506,3230,7379,1,''),(2,506,3231,1998,1,''),(2,506,3232,2002,1,''),(2,506,3233,2428,1,''),(2,506,3234,3963,1,''),(2,506,3235,7379,1,''),(2,506,3236,1998,1,''),(2,506,3237,2002,1,''),(2,506,3238,2428,1,''),(2,506,3239,3963,1,''),(2,506,3240,7379,1,''),(2,506,3241,1998,1,''),(2,506,3242,2002,1,''),(2,506,3243,2428,1,''),(2,506,3244,3963,1,''),(2,506,3245,7379,1,''),(2,506,3246,1998,1,''),(2,506,3247,2002,1,''),(2,507,3248,2428,1,''),(2,507,3249,3963,1,''),(2,507,3250,7379,1,''),(2,507,3251,1998,1,''),(2,507,3252,2002,1,''),(2,507,3253,2428,1,''),(2,507,3254,3963,1,''),(2,507,3255,7379,1,''),(2,507,3256,1998,1,''),(2,507,3257,2002,1,''),(2,507,3258,2428,1,''),(2,507,3259,3963,1,''),(2,507,3260,7379,1,''),(2,507,3261,1998,1,''),(2,507,3262,2002,1,''),(2,507,3263,2428,1,''),(2,507,3264,3963,1,''),(2,507,3265,7379,1,''),(2,507,3266,1998,1,''),(2,507,3267,2002,1,''),(2,511,3268,2428,1,''),(2,511,3269,3963,1,''),(2,511,3270,7379,1,''),(2,511,3271,1998,1,''),(2,511,3272,2002,1,''),(2,511,3273,2428,1,''),(2,511,3274,3963,1,''),(2,511,3275,7379,1,''),(2,511,3276,1998,1,''),(2,511,3277,2002,1,''),(2,511,3278,2428,1,''),(2,511,3279,3963,1,''),(2,511,3280,7379,1,''),(2,511,3281,1998,1,''),(2,511,3282,2002,1,''),(2,511,3283,2428,1,''),(2,511,3284,3963,1,''),(2,511,3285,7379,1,''),(2,511,3286,1998,1,''),(2,511,3287,2002,1,''),(2,512,3288,2428,1,''),(2,512,3289,3963,1,''),(2,512,3290,7379,1,''),(2,512,3291,1998,1,''),(2,512,3292,2002,1,''),(2,512,3293,2428,1,''),(2,512,3294,3963,1,''),(2,512,3295,7379,1,''),(2,512,3296,1998,1,''),(2,512,3297,2002,1,''),(2,512,3298,2428,1,''),(2,512,3299,3963,1,''),(2,512,3300,7379,1,''),(2,512,3301,1998,1,''),(2,512,3302,2002,1,''),(2,512,3303,2428,1,''),(2,512,3304,3963,1,''),(2,512,3305,7379,1,''),(2,512,3306,1998,1,''),(2,512,3307,2002,1,''),(2,516,3308,2428,1,''),(2,516,3309,3963,1,''),(2,516,3310,7379,1,''),(2,516,3311,1998,1,''),(2,516,3312,2002,1,''),(2,516,3313,2428,1,''),(2,516,3314,3963,1,''),(2,516,3315,7379,1,''),(2,516,3316,1998,1,''),(2,516,3317,2002,1,''),(2,516,3318,2428,1,''),(2,516,3319,3963,1,''),(2,516,3320,7379,1,''),(2,516,3321,1998,1,''),(2,516,3322,2002,1,''),(2,516,3323,2428,1,''),(2,516,3324,3963,1,''),(2,516,3325,7379,1,''),(2,516,3326,1998,1,''),(2,516,3327,2002,1,''),(2,517,3328,2428,1,''),(2,517,3329,3963,1,''),(2,517,3330,7379,1,''),(2,517,3331,1998,1,''),(2,517,3332,2002,1,''),(2,517,3333,2428,1,''),(2,517,3334,3963,1,''),(2,517,3335,7379,1,''),(2,517,3336,1998,1,''),(2,517,3337,2002,1,''),(2,517,3338,2428,1,''),(2,517,3339,3963,1,''),(2,517,3340,7379,1,''),(2,517,3341,1998,1,''),(2,517,3342,2002,1,''),(2,517,3343,2428,1,''),(2,517,3344,3963,1,''),(2,517,3345,7379,1,''),(2,517,3346,1998,1,''),(2,517,3347,2002,1,''),(2,521,3348,2428,1,''),(2,521,3349,3963,1,''),(2,521,3350,7379,1,''),(2,521,3351,1998,1,''),(2,521,3352,2002,1,''),(2,521,3353,2428,1,''),(2,521,3354,3963,1,''),(2,521,3355,7379,1,''),(2,521,3356,1998,1,''),(2,521,3357,2002,1,''),(2,521,3358,2428,1,''),(2,521,3359,3963,1,''),(2,521,3360,7379,1,''),(2,521,3361,1998,1,''),(2,521,3362,2002,1,''),(2,521,3363,2428,1,''),(2,521,3364,3963,1,''),(2,521,3365,7379,1,''),(2,521,3366,1998,1,''),(2,521,3367,2002,1,''),(2,522,3368,2428,1,''),(2,522,3369,3963,1,''),(2,522,3370,7379,1,''),(2,522,3371,1998,1,''),(2,522,3372,2002,1,''),(2,522,3373,2428,1,''),(2,522,3374,3963,1,''),(2,522,3375,7379,1,''),(2,522,3376,1998,1,''),(2,522,3377,2002,1,''),(2,522,3378,2428,1,''),(2,522,3379,3963,1,''),(2,522,3380,7379,1,''),(2,522,3381,1998,1,''),(2,522,3382,2002,1,''),(2,522,3383,2428,1,''),(2,522,3384,3963,1,''),(2,522,3385,7379,1,''),(2,522,3386,1998,1,''),(2,522,3387,2002,1,''),(2,526,3388,2428,1,''),(2,526,3389,3963,1,''),(2,526,3390,7379,1,''),(2,526,3391,1998,1,''),(2,526,3392,2002,1,''),(2,526,3393,2428,1,''),(2,526,3394,3963,1,''),(2,526,3395,7379,1,''),(2,526,3396,1998,1,''),(2,526,3397,2002,1,''),(2,526,3398,2428,1,''),(2,526,3399,3963,1,''),(2,526,3400,7379,1,''),(2,526,3401,1998,1,''),(2,526,3402,2002,1,''),(2,526,3403,2428,1,''),(2,526,3404,3963,1,''),(2,526,3405,7379,1,''),(2,526,3406,1998,1,''),(2,526,3407,2002,1,''),(2,527,3408,2428,1,''),(2,527,3409,3963,1,''),(2,527,3410,7379,1,''),(2,527,3411,1998,1,''),(2,527,3412,2002,1,''),(2,527,3413,2428,1,''),(2,527,3414,3963,1,''),(2,527,3415,7379,1,''),(2,527,3416,1998,1,''),(2,527,3417,2002,1,''),(2,527,3418,2428,1,''),(2,527,3419,3963,1,''),(2,527,3420,7379,1,''),(2,527,3421,1998,1,''),(2,527,3422,2002,1,''),(2,527,3423,2428,1,''),(2,527,3424,3963,1,''),(2,527,3425,7379,1,''),(2,527,3426,1998,1,''),(2,527,3427,2002,1,''),(2,531,3428,2428,1,''),(2,531,3429,3963,1,''),(2,531,3430,7379,1,''),(2,531,3431,1998,1,''),(2,531,3432,2002,1,''),(2,531,3433,2428,1,''),(2,531,3434,3963,1,''),(2,531,3435,7379,1,''),(2,531,3436,1998,1,''),(2,531,3437,2002,1,''),(2,531,3438,2428,1,''),(2,531,3439,3963,1,''),(2,531,3440,7379,1,''),(2,531,3441,1998,1,''),(2,531,3442,2002,1,''),(2,531,3443,2428,1,''),(2,531,3444,3963,1,''),(2,531,3445,7379,1,''),(2,531,3446,1998,1,''),(2,531,3447,2002,1,''),(2,532,3448,2428,1,''),(2,532,3449,3963,1,''),(2,532,3450,7379,1,''),(2,532,3451,1998,1,''),(2,532,3452,2002,1,''),(2,532,3453,2428,1,''),(2,532,3454,3963,1,''),(2,532,3455,7379,1,''),(2,532,3456,1998,1,''),(2,532,3457,2002,1,''),(2,532,3458,2428,1,''),(2,532,3459,3963,1,''),(2,532,3460,7379,1,''),(2,532,3461,1998,1,''),(2,532,3462,2002,1,''),(2,532,3463,2428,1,''),(2,532,3464,3963,1,''),(2,532,3465,7379,1,''),(2,532,3466,1998,1,''),(2,532,3467,2002,1,''),(2,536,3468,2428,1,''),(2,536,3469,3963,1,''),(2,536,3470,7379,1,''),(2,536,3471,1998,1,''),(2,536,3472,2002,1,''),(2,536,3473,2428,1,''),(2,536,3474,3963,1,''),(2,536,3475,7379,1,''),(2,536,3476,1998,1,''),(2,536,3477,2002,1,''),(2,536,3478,2428,1,''),(2,536,3479,3963,1,''),(2,536,3480,7379,1,''),(2,536,3481,1998,1,''),(2,536,3482,2002,1,''),(2,536,3483,2428,1,''),(2,536,3484,3963,1,''),(2,536,3485,7379,1,''),(2,536,3486,1998,1,''),(2,536,3487,2002,1,''),(2,537,3488,2428,1,''),(2,537,3489,3963,1,''),(2,537,3490,7379,1,''),(2,537,3491,1998,1,''),(2,537,3492,2002,1,''),(2,537,3493,2428,1,''),(2,537,3494,3963,1,''),(2,537,3495,7379,1,''),(2,537,3496,1998,1,''),(2,537,3497,2002,1,''),(2,537,3498,2428,1,''),(2,537,3499,3963,1,''),(2,537,3500,7379,1,''),(2,537,3501,1998,1,''),(2,537,3502,2002,1,''),(2,537,3503,2428,1,''),(2,537,3504,3963,1,''),(2,537,3505,7379,1,''),(2,537,3506,1998,1,''),(2,537,3507,2002,1,''),(2,541,3508,2428,1,''),(2,541,3509,3963,1,''),(2,541,3510,7379,1,''),(2,541,3511,1998,1,''),(2,541,3512,2002,1,''),(2,541,3513,2428,1,''),(2,541,3514,3963,1,''),(2,541,3515,7379,1,''),(2,541,3516,1998,1,''),(2,541,3517,2002,1,''),(2,541,3518,2428,1,''),(2,541,3519,3963,1,''),(2,541,3520,7379,1,''),(2,541,3521,1998,1,''),(2,541,3522,2002,1,''),(2,541,3523,2428,1,''),(2,541,3524,3963,1,''),(2,541,3525,7379,1,''),(2,541,3526,1998,1,''),(2,541,3527,2002,1,''),(2,542,3528,2428,1,''),(2,542,3529,3963,1,''),(2,542,3530,7379,1,''),(2,542,3531,1998,1,''),(2,542,3532,2002,1,''),(2,542,3533,2428,1,''),(2,542,3534,3963,1,''),(2,542,3535,7379,1,''),(2,542,3536,1998,1,''),(2,542,3537,2002,1,''),(2,542,3538,2428,1,''),(2,542,3539,3963,1,''),(2,542,3540,7379,1,''),(2,542,3541,1998,1,''),(2,542,3542,2002,1,''),(2,542,3543,2428,1,''),(2,542,3544,3963,1,''),(2,542,3545,7379,1,''),(2,542,3546,1998,1,''),(2,542,3547,2002,1,''),(2,546,3548,2428,1,''),(2,546,3549,3963,1,''),(2,546,3550,7379,1,''),(2,546,3551,1998,1,''),(2,546,3552,2002,1,''),(2,546,3553,2428,1,''),(2,546,3554,3963,1,''),(2,546,3555,7379,1,''),(2,546,3556,1998,1,''),(2,546,3557,2002,1,''),(2,546,3558,2428,1,''),(2,546,3559,3963,1,''),(2,546,3560,7379,1,''),(2,546,3561,1998,1,''),(2,546,3562,2002,1,''),(2,546,3563,2428,1,''),(2,546,3564,3963,1,''),(2,546,3565,7379,1,''),(2,546,3566,1998,1,''),(2,546,3567,2002,1,''),(2,547,3568,2428,1,''),(2,547,3569,3963,1,''),(2,547,3570,7379,1,''),(2,547,3571,1998,1,''),(2,547,3572,2002,1,''),(2,547,3573,2428,1,''),(2,547,3574,3963,1,''),(2,547,3575,7379,1,''),(2,547,3576,1998,1,''),(2,547,3577,2002,1,''),(2,547,3578,2428,1,''),(2,547,3579,3963,1,''),(2,547,3580,7379,1,''),(2,547,3581,1998,1,''),(2,547,3582,2002,1,''),(2,547,3583,2428,1,''),(2,547,3584,3963,1,''),(2,547,3585,7379,1,''),(2,547,3586,1998,1,''),(2,547,3587,2002,1,''),(2,551,3588,2428,1,''),(2,551,3589,3963,1,''),(2,551,3590,7379,1,''),(2,551,3591,1998,1,''),(2,551,3592,2002,1,''),(2,551,3593,2428,1,''),(2,551,3594,3963,1,''),(2,551,3595,7379,1,''),(2,551,3596,1998,1,''),(2,551,3597,2002,1,''),(2,551,3598,2428,1,''),(2,551,3599,3963,1,''),(2,551,3600,7379,1,''),(2,551,3601,1998,1,''),(2,551,3602,2002,1,''),(2,551,3603,2428,1,''),(2,551,3604,3963,1,''),(2,551,3605,7379,1,''),(2,551,3606,1998,1,''),(2,551,3607,2002,1,''),(2,552,3608,2428,1,''),(2,552,3609,3963,1,''),(2,552,3610,7379,1,''),(2,552,3611,1998,1,''),(2,552,3612,2002,1,''),(2,552,3613,2428,1,''),(2,552,3614,3963,1,''),(2,552,3615,7379,1,''),(2,552,3616,1998,1,''),(2,552,3617,2002,1,''),(2,552,3618,2428,1,''),(2,552,3619,3963,1,''),(2,552,3620,7379,1,''),(2,552,3621,1998,1,''),(2,552,3622,2002,1,''),(2,552,3623,2428,1,''),(2,552,3624,3963,1,''),(2,552,3625,7379,1,''),(2,552,3626,1998,1,''),(2,552,3627,2002,1,''),(2,556,3628,2428,1,''),(2,556,3629,3963,1,''),(2,556,3630,7379,1,''),(2,556,3631,1998,1,''),(2,556,3632,2002,1,''),(2,556,3633,2428,1,''),(2,556,3634,3963,1,''),(2,556,3635,7379,1,''),(2,556,3636,1998,1,''),(2,556,3637,2002,1,''),(2,556,3638,2428,1,''),(2,556,3639,3963,1,''),(2,556,3640,7379,1,''),(2,556,3641,1998,1,''),(2,556,3642,2002,1,''),(2,556,3643,2428,1,''),(2,556,3644,3963,1,''),(2,556,3645,7379,1,''),(2,556,3646,1998,1,''),(2,556,3647,2002,1,''),(2,557,3648,2428,1,''),(2,557,3649,3963,1,''),(2,557,3650,7379,1,''),(2,557,3651,1998,1,''),(2,557,3652,2002,1,''),(2,557,3653,2428,1,''),(2,557,3654,3963,1,''),(2,557,3655,7379,1,''),(2,557,3656,1998,1,''),(2,557,3657,2002,1,''),(2,557,3658,2428,1,''),(2,557,3659,3963,1,''),(2,557,3660,7379,1,''),(2,557,3661,1998,1,''),(2,557,3662,2002,1,''),(2,557,3663,2428,1,''),(2,557,3664,3963,1,''),(2,557,3665,7379,1,''),(2,557,3666,1998,1,''),(2,557,3667,2002,1,''),(2,561,3668,2428,1,''),(2,561,3669,3963,1,''),(2,561,3670,7379,1,''),(2,561,3671,1998,1,''),(2,561,3672,2002,1,''),(2,561,3673,2428,1,''),(2,561,3674,3963,1,''),(2,561,3675,7379,1,''),(2,561,3676,1998,1,''),(2,561,3677,2002,1,''),(2,561,3678,2428,1,''),(2,561,3679,3963,1,''),(2,561,3680,7379,1,''),(2,561,3681,1998,1,''),(2,561,3682,2002,1,''),(2,561,3683,2428,1,''),(2,561,3684,3963,1,''),(2,561,3685,7379,1,''),(2,561,3686,1998,1,''),(2,561,3687,2002,1,''),(2,562,3688,2428,1,''),(2,562,3689,3963,1,''),(2,562,3690,7379,1,''),(2,562,3691,1998,1,''),(2,562,3692,2002,1,''),(2,562,3693,2428,1,''),(2,562,3694,3963,1,''),(2,562,3695,7379,1,''),(2,562,3696,1998,1,''),(2,562,3697,2002,1,''),(2,562,3698,2428,1,''),(2,562,3699,3963,1,''),(2,562,3700,7379,1,''),(2,562,3701,1998,1,''),(2,562,3702,2002,1,''),(2,562,3703,2428,1,''),(2,562,3704,3963,1,''),(2,562,3705,7379,1,''),(2,562,3706,1998,1,''),(2,562,3707,2002,1,''),(2,566,3708,2428,1,''),(2,566,3709,3963,1,''),(2,566,3710,7379,1,''),(2,566,3711,1998,1,''),(2,566,3712,2002,1,''),(2,566,3713,2428,1,''),(2,566,3714,3963,1,''),(2,566,3715,7379,1,''),(2,566,3716,1998,1,''),(2,566,3717,2002,1,''),(2,566,3718,2428,1,''),(2,566,3719,3963,1,''),(2,566,3720,7379,1,''),(2,566,3721,1998,1,''),(2,566,3722,2002,1,''),(2,566,3723,2428,1,''),(2,566,3724,3963,1,''),(2,566,3725,7379,1,''),(2,566,3726,1998,1,''),(2,566,3727,2002,1,''),(2,567,3728,2428,1,''),(2,567,3729,3963,1,''),(2,567,3730,7379,1,''),(2,567,3731,1998,1,''),(2,567,3732,2002,1,''),(2,567,3733,2428,1,''),(2,567,3734,3963,1,''),(2,567,3735,7379,1,''),(2,567,3736,1998,1,''),(2,567,3737,2002,1,''),(2,567,3738,2428,1,''),(2,567,3739,3963,1,''),(2,567,3740,7379,1,''),(2,567,3741,1998,1,''),(2,567,3742,2002,1,''),(2,567,3743,2428,1,''),(2,567,3744,3963,1,''),(2,567,3745,7379,1,''),(2,567,3746,1998,1,''),(2,567,3747,2002,1,''),(2,571,3748,2428,1,''),(2,571,3749,3963,1,''),(2,571,3750,7379,1,''),(2,571,3751,1998,1,''),(2,571,3752,2002,1,''),(2,571,3753,2428,1,''),(2,571,3754,3963,1,''),(2,571,3755,7379,1,''),(2,571,3756,1998,1,''),(2,571,3757,2002,1,''),(2,571,3758,2428,1,''),(2,571,3759,3963,1,''),(2,571,3760,7379,1,''),(2,571,3761,1998,1,''),(2,571,3762,2002,1,''),(2,571,3763,2428,1,''),(2,571,3764,3963,1,''),(2,571,3765,7379,1,''),(2,571,3766,1998,1,''),(2,571,3767,2002,1,''),(2,572,3768,2428,1,''),(2,572,3769,3963,1,''),(2,572,3770,7379,1,''),(2,572,3771,1998,1,''),(2,572,3772,2002,1,''),(2,572,3773,2428,1,''),(2,572,3774,3963,1,''),(2,572,3775,7379,1,''),(2,572,3776,1998,1,''),(2,572,3777,2002,1,''),(2,572,3778,2428,1,''),(2,572,3779,3963,1,''),(2,572,3780,7379,1,''),(2,572,3781,1998,1,''),(2,572,3782,2002,1,''),(2,572,3783,2428,1,''),(2,572,3784,3963,1,''),(2,572,3785,7379,1,''),(2,572,3786,1998,1,''),(2,572,3787,2002,1,''),(2,576,3788,2428,1,''),(2,576,3789,3963,1,''),(2,576,3790,7379,1,''),(2,576,3791,1998,1,''),(2,576,3792,2002,1,''),(2,576,3793,2428,1,''),(2,576,3794,3963,1,''),(2,576,3795,7379,1,''),(2,576,3796,1998,1,''),(2,576,3797,2002,1,''),(2,576,3798,2428,1,''),(2,576,3799,3963,1,''),(2,576,3800,7379,1,''),(2,576,3801,1998,1,''),(2,576,3802,2002,1,''),(2,576,3803,2428,1,''),(2,576,3804,3963,1,''),(2,576,3805,7379,1,''),(2,576,3806,1998,1,''),(2,576,3807,2002,1,''),(2,577,3808,2428,1,''),(2,577,3809,3963,1,''),(2,577,3810,7379,1,''),(2,577,3811,1998,1,''),(2,577,3812,2002,1,''),(2,577,3813,2428,1,''),(2,577,3814,3963,1,''),(2,577,3815,7379,1,''),(2,577,3816,1998,1,''),(2,577,3817,2002,1,''),(2,577,3818,2428,1,''),(2,577,3819,3963,1,''),(2,577,3820,7379,1,''),(2,577,3821,1998,1,''),(2,577,3822,2002,1,''),(2,577,3823,2428,1,''),(2,577,3824,3963,1,''),(2,577,3825,7379,1,''),(2,577,3826,1998,1,''),(2,577,3827,2002,1,''),(2,581,3828,2428,1,''),(2,581,3829,3963,1,''),(2,581,3830,7379,1,''),(2,581,3831,1998,1,''),(2,581,3832,2002,1,''),(2,581,3833,2428,1,''),(2,581,3834,3963,1,''),(2,581,3835,7379,1,''),(2,581,3836,1998,1,''),(2,581,3837,2002,1,''),(2,581,3838,2428,1,''),(2,581,3839,3963,1,''),(2,581,3840,7379,1,''),(2,581,3841,1998,1,''),(2,581,3842,2002,1,''),(2,581,3843,2428,1,''),(2,581,3844,3963,1,''),(2,581,3845,7379,1,''),(2,581,3846,1998,1,''),(2,581,3847,2002,1,''),(2,582,3848,2428,1,''),(2,582,3849,3963,1,''),(2,582,3850,7379,1,''),(2,582,3851,1998,1,''),(2,582,3852,2002,1,''),(2,582,3853,2428,1,''),(2,582,3854,3963,1,''),(2,582,3855,7379,1,''),(2,582,3856,1998,1,''),(2,582,3857,2002,1,''),(2,582,3858,2428,1,''),(2,582,3859,3963,1,''),(2,582,3860,7379,1,''),(2,582,3861,1998,1,''),(2,582,3862,2002,1,''),(2,582,3863,2428,1,''),(2,582,3864,3963,1,''),(2,582,3865,7379,1,''),(2,582,3866,1998,1,''),(2,582,3867,2002,1,''),(2,586,3868,2428,1,''),(2,586,3869,3963,1,''),(2,586,3870,7379,1,''),(2,586,3871,1998,1,''),(2,586,3872,2002,1,''),(2,586,3873,2428,1,''),(2,586,3874,3963,1,''),(2,586,3875,7379,1,''),(2,586,3876,1998,1,''),(2,586,3877,2002,1,''),(2,586,3878,2428,1,''),(2,586,3879,3963,1,''),(2,586,3880,7379,1,''),(2,586,3881,1998,1,''),(2,586,3882,2002,1,''),(2,586,3883,2428,1,''),(2,586,3884,3963,1,''),(2,586,3885,7379,1,''),(2,586,3886,1998,1,''),(2,586,3887,2002,1,''),(2,587,3888,2428,1,''),(2,587,3889,3963,1,''),(2,587,3890,7379,1,''),(2,587,3891,1998,1,''),(2,587,3892,2002,1,''),(2,587,3893,2428,1,''),(2,587,3894,3963,1,''),(2,587,3895,7379,1,''),(2,587,3896,1998,1,''),(2,587,3897,2002,1,''),(2,587,3898,2428,1,''),(2,587,3899,3963,1,''),(2,587,3900,7379,1,''),(2,587,3901,1998,1,''),(2,587,3902,2002,1,''),(2,587,3903,2428,1,''),(2,587,3904,3963,1,''),(2,587,3905,7379,1,''),(2,587,3906,1998,1,''),(2,587,3907,2002,1,''),(2,591,3908,2428,1,''),(2,591,3909,3963,1,''),(2,591,3910,7379,1,''),(2,591,3911,1998,1,''),(2,591,3912,2002,1,''),(2,591,3913,2428,1,''),(2,591,3914,3963,1,''),(2,591,3915,7379,1,''),(2,591,3916,1998,1,''),(2,591,3917,2002,1,''),(2,591,3918,2428,1,''),(2,591,3919,3963,1,''),(2,591,3920,7379,1,''),(2,591,3921,1998,1,''),(2,591,3922,2002,1,''),(2,591,3923,2428,1,''),(2,591,3924,3963,1,''),(2,591,3925,7379,1,''),(2,591,3926,1998,1,''),(2,591,3927,2002,1,''),(2,592,3928,2428,1,''),(2,592,3929,3963,1,''),(2,592,3930,7379,1,''),(2,592,3931,1998,1,''),(2,592,3932,2002,1,''),(2,592,3933,2428,1,''),(2,592,3934,3963,1,''),(2,592,3935,7379,1,''),(2,592,3936,1998,1,''),(2,592,3937,2002,1,''),(2,592,3938,2428,1,''),(2,592,3939,3963,1,''),(2,592,3940,7379,1,''),(2,592,3941,1998,1,''),(2,592,3942,2002,1,''),(2,592,3943,2428,1,''),(2,592,3944,3963,1,''),(2,592,3945,7379,1,''),(2,592,3946,1998,1,''),(2,592,3947,2002,1,''),(2,596,3948,2428,1,''),(2,596,3949,3963,1,''),(2,596,3950,7379,1,''),(2,596,3951,1998,1,''),(2,596,3952,2002,1,''),(2,596,3953,2428,1,''),(2,596,3954,3963,1,''),(2,596,3955,7379,1,''),(2,596,3956,1998,1,''),(2,596,3957,2002,1,''),(2,596,3958,2428,1,''),(2,596,3959,3963,1,''),(2,596,3960,7379,1,''),(2,596,3961,1998,1,''),(2,596,3962,2002,1,''),(2,596,3963,2428,1,''),(2,596,3964,3963,1,''),(2,596,3965,7379,1,''),(2,596,3966,1998,1,''),(2,596,3967,2002,1,''),(2,597,3968,2428,1,''),(2,597,3969,3963,1,''),(2,597,3970,7379,1,''),(2,597,3971,1998,1,''),(2,597,3972,2002,1,''),(2,597,3973,2428,1,''),(2,597,3974,3963,1,''),(2,597,3975,7379,1,''),(2,597,3976,1998,1,''),(2,597,3977,2002,1,''),(2,597,3978,2428,1,''),(2,597,3979,3963,1,''),(2,597,3980,7379,1,''),(2,597,3981,1998,1,''),(2,597,3982,2002,1,''),(2,597,3983,2428,1,''),(2,597,3984,3963,1,''),(2,597,3985,7379,1,''),(2,597,3986,1998,1,''),(2,597,3987,2002,1,''),(2,601,3988,2428,1,''),(2,601,3989,3963,1,''),(2,601,3990,7379,1,''),(2,601,3991,1998,1,''),(2,601,3992,2002,1,''),(2,601,3993,2428,1,''),(2,601,3994,3963,1,''),(2,601,3995,7379,1,''),(2,601,3996,1998,1,''),(2,601,3997,2002,1,''),(2,601,3998,2428,1,''),(2,601,3999,3963,1,''),(2,601,4000,7379,1,''),(2,601,4001,1998,1,''),(2,601,4002,2002,1,''),(2,601,4003,2428,1,''),(2,601,4004,3963,1,''),(2,601,4005,7379,1,''),(2,601,4006,1998,1,''),(2,601,4007,2002,1,''),(2,602,4008,2428,1,''),(2,602,4009,3963,1,''),(2,602,4010,7379,1,''),(2,602,4011,1998,1,''),(2,602,4012,2002,1,''),(2,602,4013,2428,1,''),(2,602,4014,3963,1,''),(2,602,4015,7379,1,''),(2,602,4016,1998,1,''),(2,602,4017,2002,1,''),(2,602,4018,2428,1,''),(2,602,4019,3963,1,''),(2,602,4020,7379,1,''),(2,602,4021,1998,1,''),(2,602,4022,2002,1,''),(2,602,4023,2428,1,''),(2,602,4024,3963,1,''),(2,602,4025,7379,1,''),(2,602,4026,1998,1,''),(2,602,4027,2002,1,''),(2,606,4028,2428,1,''),(2,606,4029,3963,1,''),(2,606,4030,7379,1,''),(2,606,4031,1998,1,''),(2,606,4032,2002,1,''),(2,606,4033,2428,1,''),(2,606,4034,3963,1,''),(2,606,4035,7379,1,''),(2,606,4036,1998,1,''),(2,606,4037,2002,1,''),(2,606,4038,2428,1,''),(2,606,4039,3963,1,''),(2,606,4040,7379,1,''),(2,606,4041,1998,1,''),(2,606,4042,2002,1,''),(2,606,4043,2428,1,''),(2,606,4044,3963,1,''),(2,606,4045,7379,1,''),(2,606,4046,1998,1,''),(2,606,4047,2002,1,''),(2,607,4048,2428,1,''),(2,607,4049,3963,1,''),(2,607,4050,7379,1,''),(2,607,4051,1998,1,''),(2,607,4052,2002,1,''),(2,607,4053,2428,1,''),(2,607,4054,3963,1,''),(2,607,4055,7379,1,''),(2,607,4056,1998,1,''),(2,607,4057,2002,1,''),(2,607,4058,2428,1,''),(2,607,4059,3963,1,''),(2,607,4060,7379,1,''),(2,607,4061,1998,1,''),(2,607,4062,2002,1,''),(2,607,4063,2428,1,''),(2,607,4064,3963,1,''),(2,607,4065,7379,1,''),(2,607,4066,1998,1,''),(2,607,4067,2002,1,''),(2,611,4068,2428,1,''),(2,611,4069,3963,1,''),(2,611,4070,7379,1,''),(2,611,4071,1998,1,''),(2,611,4072,2002,1,''),(2,611,4073,2428,1,''),(2,611,4074,3963,1,''),(2,611,4075,7379,1,''),(2,611,4076,1998,1,''),(2,611,4077,2002,1,''),(2,611,4078,2428,1,''),(2,611,4079,3963,1,''),(2,611,4080,7379,1,''),(2,611,4081,1998,1,''),(2,611,4082,2002,1,''),(2,611,4083,2428,1,''),(2,611,4084,3963,1,''),(2,611,4085,7379,1,''),(2,611,4086,1998,1,''),(2,611,4087,2002,1,''),(2,612,4088,2428,1,''),(2,612,4089,3963,1,''),(2,612,4090,7379,1,''),(2,612,4091,1998,1,''),(2,612,4092,2002,1,''),(2,612,4093,2428,1,''),(2,612,4094,3963,1,''),(2,612,4095,7379,1,''),(2,612,4096,1998,1,''),(2,612,4097,2002,1,''),(2,612,4098,2428,1,''),(2,612,4099,3963,1,''),(2,612,4100,7379,1,''),(2,612,4101,1998,1,''),(2,612,4102,2002,1,''),(2,612,4103,2428,1,''),(2,612,4104,3963,1,''),(2,612,4105,7379,1,''),(2,612,4106,1998,1,''),(2,612,4107,2002,1,''),(2,616,4108,2428,1,''),(2,616,4109,3963,1,''),(2,616,4110,7379,1,''),(2,616,4111,1998,1,''),(2,616,4112,2002,1,''),(2,616,4113,2428,1,''),(2,616,4114,3963,1,''),(2,616,4115,7379,1,''),(2,616,4116,1998,1,''),(2,616,4117,2002,1,''),(2,616,4118,2428,1,''),(2,616,4119,3963,1,''),(2,616,4120,7379,1,''),(2,616,4121,1998,1,''),(2,616,4122,2002,1,''),(2,616,4123,2428,1,''),(2,616,4124,3963,1,''),(2,616,4125,7379,1,''),(2,616,4126,1998,1,''),(2,616,4127,2002,1,''),(2,617,4128,2428,1,''),(2,617,4129,3963,1,''),(2,617,4130,7379,1,''),(2,617,4131,1998,1,''),(2,617,4132,2002,1,''),(2,617,4133,2428,1,''),(2,617,4134,3963,1,''),(2,617,4135,7379,1,''),(2,617,4136,1998,1,''),(2,617,4137,2002,1,''),(2,617,4138,2428,1,''),(2,617,4139,3963,1,''),(2,617,4140,7379,1,''),(2,617,4141,1998,1,''),(2,617,4142,2002,1,''),(2,617,4143,2428,1,''),(2,617,4144,3963,1,''),(2,617,4145,7379,1,''),(2,617,4146,1998,1,''),(2,617,4147,2002,1,''),(2,621,4148,2428,1,''),(2,621,4149,3963,1,''),(2,621,4150,7379,1,''),(2,621,4151,1998,1,''),(2,621,4152,2002,1,''),(2,621,4153,2428,1,''),(2,621,4154,3963,1,''),(2,621,4155,7379,1,''),(2,621,4156,1998,1,''),(2,621,4157,2002,1,''),(2,621,4158,2428,1,''),(2,621,4159,3963,1,''),(2,621,4160,7379,1,''),(2,621,4161,1998,1,''),(2,621,4162,2002,1,''),(2,621,4163,2428,1,''),(2,621,4164,3963,1,''),(2,621,4165,7379,1,''),(2,621,4166,1998,1,''),(2,621,4167,2002,1,''),(2,622,4168,2428,1,''),(2,622,4169,3963,1,''),(2,622,4170,7379,1,''),(2,622,4171,1998,1,''),(2,622,4172,2002,1,''),(2,622,4173,2428,1,''),(2,622,4174,3963,1,''),(2,622,4175,7379,1,''),(2,622,4176,1998,1,''),(2,622,4177,2002,1,''),(2,622,4178,2428,1,''),(2,622,4179,3963,1,''),(2,622,4180,7379,1,''),(2,622,4181,1998,1,''),(2,622,4182,2002,1,''),(2,622,4183,2428,1,''),(2,622,4184,3963,1,''),(2,622,4185,7379,1,''),(2,622,4186,1998,1,''),(2,622,4187,2002,1,''),(2,626,4188,2428,1,''),(2,626,4189,3963,1,''),(2,626,4190,7379,1,''),(2,626,4191,1998,1,''),(2,626,4192,2002,1,''),(2,626,4193,2428,1,''),(2,626,4194,3963,1,''),(2,626,4195,7379,1,''),(2,626,4196,1998,1,''),(2,626,4197,2002,1,''),(2,626,4198,2428,1,''),(2,626,4199,3963,1,''),(2,626,4200,7379,1,''),(2,626,4201,1998,1,''),(2,626,4202,2002,1,''),(2,626,4203,2428,1,''),(2,626,4204,3963,1,''),(2,626,4205,7379,1,''),(2,626,4206,1998,1,''),(2,626,4207,2002,1,''),(2,627,4208,2428,1,''),(2,627,4209,3963,1,''),(2,627,4210,7379,1,''),(2,627,4211,1998,1,''),(2,627,4212,2002,1,''),(2,627,4213,2428,1,''),(2,627,4214,3963,1,''),(2,627,4215,7379,1,''),(2,627,4216,1998,1,''),(2,627,4217,2002,1,''),(2,627,4218,2428,1,''),(2,627,4219,3963,1,''),(2,627,4220,7379,1,''),(2,627,4221,1998,1,''),(2,627,4222,2002,1,''),(2,627,4223,2428,1,''),(2,627,4224,3963,1,''),(2,627,4225,7379,1,''),(2,627,4226,1998,1,''),(2,627,4227,2002,1,''),(2,631,4228,2428,1,''),(2,631,4229,3963,1,''),(2,631,4230,7379,1,''),(2,631,4231,1998,1,''),(2,631,4232,2002,1,''),(2,631,4233,2428,1,''),(2,631,4234,3963,1,''),(2,631,4235,7379,1,''),(2,631,4236,1998,1,''),(2,631,4237,2002,1,''),(2,631,4238,2428,1,''),(2,631,4239,3963,1,''),(2,631,4240,7379,1,''),(2,631,4241,1998,1,''),(2,631,4242,2002,1,''),(2,631,4243,2428,1,''),(2,631,4244,3963,1,''),(2,631,4245,7379,1,''),(2,631,4246,1998,1,''),(2,631,4247,2002,1,''),(2,632,4248,2428,1,''),(2,632,4249,3963,1,''),(2,632,4250,7379,1,''),(2,632,4251,1998,1,''),(2,632,4252,2002,1,''),(2,632,4253,2428,1,''),(2,632,4254,3963,1,''),(2,632,4255,7379,1,''),(2,632,4256,1998,1,''),(2,632,4257,2002,1,''),(2,632,4258,2428,1,''),(2,632,4259,3963,1,''),(2,632,4260,7379,1,''),(2,632,4261,1998,1,''),(2,632,4262,2002,1,''),(2,632,4263,2428,1,''),(2,632,4264,3963,1,''),(2,632,4265,7379,1,''),(2,632,4266,1998,1,''),(2,632,4267,2002,1,''),(2,636,4268,2428,1,''),(2,636,4269,3963,1,''),(2,636,4270,7379,1,''),(2,636,4271,1998,1,''),(2,636,4272,2002,1,''),(2,636,4273,2428,1,''),(2,636,4274,3963,1,''),(2,636,4275,7379,1,''),(2,636,4276,1998,1,''),(2,636,4277,2002,1,''),(2,636,4278,2428,1,''),(2,636,4279,3963,1,''),(2,636,4280,7379,1,''),(2,636,4281,1998,1,''),(2,636,4282,2002,1,''),(2,636,4283,2428,1,''),(2,636,4284,3963,1,''),(2,636,4285,7379,1,''),(2,636,4286,1998,1,''),(2,636,4287,2002,1,''),(2,637,4288,2428,1,''),(2,637,4289,3963,1,''),(2,637,4290,7379,1,''),(2,637,4291,1998,1,''),(2,637,4292,2002,1,''),(2,637,4293,2428,1,''),(2,637,4294,3963,1,''),(2,637,4295,7379,1,''),(2,637,4296,1998,1,''),(2,637,4297,2002,1,''),(2,637,4298,2428,1,''),(2,637,4299,3963,1,''),(2,637,4300,7379,1,''),(2,637,4301,1998,1,''),(2,637,4302,2002,1,''),(2,637,4303,2428,1,''),(2,637,4304,3963,1,''),(2,637,4305,7379,1,''),(2,637,4306,1998,1,''),(2,637,4307,2002,1,''),(2,641,4308,2428,1,''),(2,641,4309,3963,1,''),(2,641,4310,7379,1,''),(2,641,4311,1998,1,''),(2,641,4312,2002,1,''),(2,641,4313,2428,1,''),(2,641,4314,3963,1,''),(2,641,4315,7379,1,''),(2,641,4316,1998,1,''),(2,641,4317,2002,1,''),(2,641,4318,2428,1,''),(2,641,4319,3963,1,''),(2,641,4320,7379,1,''),(2,641,4321,1998,1,''),(2,641,4322,2002,1,''),(2,641,4323,2428,1,''),(2,641,4324,3963,1,''),(2,641,4325,7379,1,''),(2,641,4326,1998,1,''),(2,641,4327,2002,1,''),(2,642,4328,2428,1,''),(2,642,4329,3963,1,''),(2,642,4330,7379,1,''),(2,642,4331,1998,1,''),(2,642,4332,2002,1,''),(2,642,4333,2428,1,''),(2,642,4334,3963,1,''),(2,642,4335,7379,1,''),(2,642,4336,1998,1,''),(2,642,4337,2002,1,''),(2,642,4338,2428,1,''),(2,642,4339,3963,1,''),(2,642,4340,7379,1,''),(2,642,4341,1998,1,''),(2,642,4342,2002,1,''),(2,642,4343,2428,1,''),(2,642,4344,3963,1,''),(2,642,4345,7379,1,''),(2,642,4346,1998,1,''),(2,642,4347,2002,1,''),(2,646,4348,2428,1,''),(2,646,4349,3963,1,''),(2,646,4350,7379,1,''),(2,646,4351,1998,1,''),(2,646,4352,2002,1,''),(2,646,4353,2428,1,''),(2,646,4354,3963,1,''),(2,646,4355,7379,1,''),(2,646,4356,1998,1,''),(2,646,4357,2002,1,''),(2,646,4358,2428,1,''),(2,646,4359,3963,1,''),(2,646,4360,7379,1,''),(2,646,4361,1998,1,''),(2,646,4362,2002,1,''),(2,646,4363,2428,1,''),(2,646,4364,3963,1,''),(2,646,4365,7379,1,''),(2,646,4366,1998,1,''),(2,646,4367,2002,1,''),(2,647,4368,2428,1,''),(2,647,4369,3963,1,''),(2,647,4370,7379,1,''),(2,647,4371,1998,1,''),(2,647,4372,2002,1,''),(2,647,4373,2428,1,''),(2,647,4374,3963,1,''),(2,647,4375,7379,1,''),(2,647,4376,1998,1,''),(2,647,4377,2002,1,''),(2,647,4378,2428,1,''),(2,647,4379,3963,1,''),(2,647,4380,7379,1,''),(2,647,4381,1998,1,''),(2,647,4382,2002,1,''),(2,647,4383,2428,1,''),(2,647,4384,3963,1,''),(2,647,4385,7379,1,''),(2,647,4386,1998,1,''),(2,647,4387,2002,1,''),(2,651,4388,2428,1,''),(2,651,4389,3963,1,''),(2,651,4390,7379,1,''),(2,651,4391,1998,1,''),(2,651,4392,2002,1,''),(2,651,4393,2428,1,''),(2,651,4394,3963,1,''),(2,651,4395,7379,1,''),(2,651,4396,1998,1,''),(2,651,4397,2002,1,''),(2,651,4398,2428,1,''),(2,651,4399,3963,1,''),(2,651,4400,7379,1,''),(2,651,4401,1998,1,''),(2,651,4402,2002,1,''),(2,651,4403,2428,1,''),(2,651,4404,3963,1,''),(2,651,4405,7379,1,''),(2,651,4406,1998,1,''),(2,651,4407,2002,1,''),(2,652,4408,2428,1,''),(2,652,4409,3963,1,''),(2,652,4410,7379,1,''),(2,652,4411,1998,1,''),(2,652,4412,2002,1,''),(2,652,4413,2428,1,''),(2,652,4414,3963,1,''),(2,652,4415,7379,1,''),(2,652,4416,1998,1,''),(2,652,4417,2002,1,''),(2,652,4418,2428,1,''),(2,652,4419,3963,1,''),(2,652,4420,7379,1,''),(2,652,4421,1998,1,''),(2,652,4422,2002,1,''),(2,652,4423,2428,1,''),(2,652,4424,3963,1,''),(2,652,4425,7379,1,''),(2,652,4426,1998,1,''),(2,652,4427,2002,1,''),(2,656,4428,2428,1,''),(2,656,4429,3963,1,''),(2,656,4430,7379,1,''),(2,656,4431,1998,1,''),(2,656,4432,2002,1,''),(2,656,4433,2428,1,''),(2,656,4434,3963,1,''),(2,656,4435,7379,1,''),(2,656,4436,1998,1,''),(2,656,4437,2002,1,''),(2,656,4438,2428,1,''),(2,656,4439,3963,1,''),(2,656,4440,7379,1,''),(2,656,4441,1998,1,''),(2,656,4442,2002,1,''),(2,656,4443,2428,1,''),(2,656,4444,3963,1,''),(2,656,4445,7379,1,''),(2,656,4446,1998,1,''),(2,656,4447,2002,1,''),(2,657,4448,2428,1,''),(2,657,4449,3963,1,''),(2,657,4450,7379,1,''),(2,657,4451,1998,1,''),(2,657,4452,2002,1,''),(2,657,4453,2428,1,''),(2,657,4454,3963,1,''),(2,657,4455,7379,1,''),(2,657,4456,1998,1,''),(2,657,4457,2002,1,''),(2,657,4458,2428,1,''),(2,657,4459,3963,1,''),(2,657,4460,7379,1,''),(2,657,4461,1998,1,''),(2,657,4462,2002,1,''),(2,657,4463,2428,1,''),(2,657,4464,3963,1,''),(2,657,4465,7379,1,''),(2,657,4466,1998,1,''),(2,657,4467,2002,1,''),(2,661,4468,2428,1,''),(2,661,4469,3963,1,''),(2,661,4470,7379,1,''),(2,661,4471,1998,1,''),(2,661,4472,2002,1,''),(2,661,4473,2428,1,''),(2,661,4474,3963,1,''),(2,661,4475,7379,1,''),(2,661,4476,1998,1,''),(2,661,4477,2002,1,''),(2,661,4478,2428,1,''),(2,661,4479,3963,1,''),(2,661,4480,7379,1,''),(2,661,4481,1998,1,''),(2,661,4482,2002,1,''),(2,661,4483,2428,1,''),(2,661,4484,3963,1,''),(2,661,4485,7379,1,''),(2,661,4486,1998,1,''),(2,661,4487,2002,1,''),(2,662,4488,2428,1,''),(2,662,4489,3963,1,''),(2,662,4490,7379,1,''),(2,662,4491,1998,1,''),(2,662,4492,2002,1,''),(2,662,4493,2428,1,''),(2,662,4494,3963,1,''),(2,662,4495,7379,1,''),(2,662,4496,1998,1,''),(2,662,4497,2002,1,''),(2,662,4498,2428,1,''),(2,662,4499,3963,1,''),(2,662,4500,7379,1,''),(2,662,4501,1998,1,''),(2,662,4502,2002,1,''),(2,662,4503,2428,1,''),(2,662,4504,3963,1,''),(2,662,4505,7379,1,''),(2,662,4506,1998,1,''),(2,662,4507,2002,1,''),(2,666,4508,2428,1,''),(2,666,4509,3963,1,''),(2,666,4510,7379,1,''),(2,666,4511,1998,1,''),(2,666,4512,2002,1,''),(2,666,4513,2428,1,''),(2,666,4514,3963,1,''),(2,666,4515,7379,1,''),(2,666,4516,1998,1,''),(2,666,4517,2002,1,''),(2,666,4518,2428,1,''),(2,666,4519,3963,1,''),(2,666,4520,7379,1,''),(2,666,4521,1998,1,''),(2,666,4522,2002,1,''),(2,666,4523,2428,1,''),(2,666,4524,3963,1,''),(2,666,4525,7379,1,''),(2,666,4526,1998,1,''),(2,666,4527,2002,1,''),(2,667,4528,2428,1,''),(2,667,4529,3963,1,''),(2,667,4530,7379,1,''),(2,667,4531,1998,1,''),(2,667,4532,2002,1,''),(2,667,4533,2428,1,''),(2,667,4534,3963,1,''),(2,667,4535,7379,1,''),(2,667,4536,1998,1,''),(2,667,4537,2002,1,''),(2,667,4538,2428,1,''),(2,667,4539,3963,1,''),(2,667,4540,7379,1,''),(2,667,4541,1998,1,''),(2,667,4542,2002,1,''),(2,667,4543,2428,1,''),(2,667,4544,3963,1,''),(2,667,4545,7379,1,''),(2,667,4546,1998,1,''),(2,667,4547,2002,1,''),(2,671,4548,2428,1,''),(2,671,4549,3963,1,''),(2,671,4550,7379,1,''),(2,671,4551,1998,1,''),(2,671,4552,2002,1,''),(2,671,4553,2428,1,''),(2,671,4554,3963,1,''),(2,671,4555,7379,1,''),(2,671,4556,1998,1,''),(2,671,4557,2002,1,''),(2,671,4558,2428,1,''),(2,671,4559,3963,1,''),(2,671,4560,7379,1,''),(2,671,4561,1998,1,''),(2,671,4562,2002,1,''),(2,671,4563,2428,1,''),(2,671,4564,3963,1,''),(2,671,4565,7379,1,''),(2,671,4566,1998,1,''),(2,671,4567,2002,1,''),(2,672,4568,2428,1,''),(2,672,4569,3963,1,''),(2,672,4570,7379,1,''),(2,672,4571,1998,1,''),(2,672,4572,2002,1,''),(2,672,4573,2428,1,''),(2,672,4574,3963,1,''),(2,672,4575,7379,1,''),(2,672,4576,1998,1,''),(2,672,4577,2002,1,''),(2,672,4578,2428,1,''),(2,672,4579,3963,1,''),(2,672,4580,7379,1,''),(2,672,4581,1998,1,''),(2,672,4582,2002,1,''),(2,672,4583,2428,1,''),(2,672,4584,3963,1,''),(2,672,4585,7379,1,''),(2,672,4586,1998,1,''),(2,672,4587,2002,1,''),(2,676,4588,2428,1,''),(2,676,4589,3963,1,''),(2,676,4590,7379,1,''),(2,676,4591,1998,1,''),(2,676,4592,2002,1,''),(2,676,4593,2428,1,''),(2,676,4594,3963,1,''),(2,676,4595,7379,1,''),(2,676,4596,1998,1,''),(2,676,4597,2002,1,''),(2,676,4598,2428,1,''),(2,676,4599,3963,1,''),(2,676,4600,7379,1,''),(2,676,4601,1998,1,''),(2,676,4602,2002,1,''),(2,676,4603,2428,1,''),(2,676,4604,3963,1,''),(2,676,4605,7379,1,''),(2,676,4606,1998,1,''),(2,676,4607,2002,1,''),(2,677,4608,2428,1,''),(2,677,4609,3963,1,''),(2,677,4610,7379,1,''),(2,677,4611,1998,1,''),(2,677,4612,2002,1,''),(2,677,4613,2428,1,''),(2,677,4614,3963,1,''),(2,677,4615,7379,1,''),(2,677,4616,1998,1,''),(2,677,4617,2002,1,''),(2,677,4618,2428,1,''),(2,677,4619,3963,1,''),(2,677,4620,7379,1,''),(2,677,4621,1998,1,''),(2,677,4622,2002,1,''),(2,677,4623,2428,1,''),(2,677,4624,3963,1,''),(2,677,4625,7379,1,''),(2,677,4626,1998,1,''),(2,677,4627,2002,1,''),(2,681,4628,2428,1,''),(2,681,4629,3963,1,''),(2,681,4630,7379,1,''),(2,681,4631,1998,1,''),(2,681,4632,2002,1,''),(2,681,4633,2428,1,''),(2,681,4634,3963,1,''),(2,681,4635,7379,1,''),(2,681,4636,1998,1,''),(2,681,4637,2002,1,''),(2,681,4638,2428,1,''),(2,681,4639,3963,1,''),(2,681,4640,7379,1,''),(2,681,4641,1998,1,''),(2,681,4642,2002,1,''),(2,681,4643,2428,1,''),(2,681,4644,3963,1,''),(2,681,4645,7379,1,''),(2,681,4646,1998,1,''),(2,681,4647,2002,1,''),(2,682,4648,2428,1,''),(2,682,4649,3963,1,''),(2,682,4650,7379,1,''),(2,682,4651,1998,1,''),(2,682,4652,2002,1,''),(2,682,4653,2428,1,''),(2,682,4654,3963,1,''),(2,682,4655,7379,1,''),(2,682,4656,1998,1,''),(2,682,4657,2002,1,''),(2,682,4658,2428,1,''),(2,682,4659,3963,1,''),(2,682,4660,7379,1,''),(2,682,4661,1998,1,''),(2,682,4662,2002,1,''),(2,682,4663,2428,1,''),(2,682,4664,3963,1,''),(2,682,4665,7379,1,''),(2,682,4666,1998,1,''),(2,682,4667,2002,1,''),(2,686,4668,2428,1,''),(2,686,4669,3963,1,''),(2,686,4670,7379,1,''),(2,686,4671,1998,1,''),(2,686,4672,2002,1,''),(2,686,4673,2428,1,''),(2,686,4674,3963,1,''),(2,686,4675,7379,1,''),(2,686,4676,1998,1,''),(2,686,4677,2002,1,''),(2,686,4678,2428,1,''),(2,686,4679,3963,1,''),(2,686,4680,7379,1,''),(2,686,4681,1998,1,''),(2,686,4682,2002,1,''),(2,686,4683,2428,1,''),(2,686,4684,3963,1,''),(2,686,4685,7379,1,''),(2,686,4686,1998,1,''),(2,686,4687,2002,1,''),(2,687,4688,2428,1,''),(2,687,4689,3963,1,''),(2,687,4690,7379,1,''),(2,687,4691,1998,1,''),(2,687,4692,2002,1,''),(2,687,4693,2428,1,''),(2,687,4694,3963,1,''),(2,687,4695,7379,1,''),(2,687,4696,1998,1,''),(2,687,4697,2002,1,''),(2,687,4698,2428,1,''),(2,687,4699,3963,1,''),(2,687,4700,7379,1,''),(2,687,4701,1998,1,''),(2,687,4702,2002,1,''),(2,687,4703,2428,1,''),(2,687,4704,3963,1,''),(2,687,4705,7379,1,''),(2,687,4706,1998,1,''),(2,687,4707,2002,1,''),(2,691,4708,2428,1,''),(2,691,4709,3963,1,''),(2,691,4710,7379,1,''),(2,691,4711,1998,1,''),(2,691,4712,2002,1,''),(2,691,4713,2428,1,''),(2,691,4714,3963,1,''),(2,691,4715,7379,1,''),(2,691,4716,1998,1,''),(2,691,4717,2002,1,''),(2,691,4718,2428,1,''),(2,691,4719,3963,1,''),(2,691,4720,7379,1,''),(2,691,4721,1998,1,''),(2,691,4722,2002,1,''),(2,691,4723,2428,1,''),(2,691,4724,3963,1,''),(2,691,4725,7379,1,''),(2,691,4726,1998,1,''),(2,691,4727,2002,1,''),(2,692,4728,2428,1,''),(2,692,4729,3963,1,''),(2,692,4730,7379,1,''),(2,692,4731,1998,1,''),(2,692,4732,2002,1,''),(2,692,4733,2428,1,''),(2,692,4734,3963,1,''),(2,692,4735,7379,1,''),(2,692,4736,1998,1,''),(2,692,4737,2002,1,''),(2,692,4738,2428,1,''),(2,692,4739,3963,1,''),(2,692,4740,7379,1,''),(2,692,4741,1998,1,''),(2,692,4742,2002,1,''),(2,692,4743,2428,1,''),(2,692,4744,3963,1,''),(2,692,4745,7379,1,''),(2,692,4746,1998,1,''),(2,692,4747,2002,1,''),(2,696,4748,2428,1,''),(2,696,4749,3963,1,''),(2,696,4750,7379,1,''),(2,696,4751,1998,1,''),(2,696,4752,2002,1,''),(2,696,4753,2428,1,''),(2,696,4754,3963,1,''),(2,696,4755,7379,1,''),(2,696,4756,1998,1,''),(2,696,4757,2002,1,''),(2,696,4758,2428,1,''),(2,696,4759,3963,1,''),(2,696,4760,7379,1,''),(2,696,4761,1998,1,''),(2,696,4762,2002,1,''),(2,696,4763,2428,1,''),(2,696,4764,3963,1,''),(2,696,4765,7379,1,''),(2,696,4766,1998,1,''),(2,696,4767,2002,1,''),(2,697,4768,2428,1,''),(2,697,4769,3963,1,''),(2,697,4770,7379,1,''),(2,697,4771,1998,1,''),(2,697,4772,2002,1,''),(2,697,4773,2428,1,''),(2,697,4774,3963,1,''),(2,697,4775,7379,1,''),(2,697,4776,1998,1,''),(2,697,4777,2002,1,''),(2,697,4778,2428,1,''),(2,697,4779,3963,1,''),(2,697,4780,7379,1,''),(2,697,4781,1998,1,''),(2,697,4782,2002,1,''),(2,697,4783,2428,1,''),(2,697,4784,3963,1,''),(2,697,4785,7379,1,''),(2,697,4786,1998,1,''),(2,697,4787,2002,1,''),(2,701,4788,2428,1,''),(2,701,4789,3963,1,''),(2,701,4790,7379,1,''),(2,701,4791,1998,1,''),(2,701,4792,2002,1,''),(2,701,4793,2428,1,''),(2,701,4794,3963,1,''),(2,701,4795,7379,1,''),(2,701,4796,1998,1,''),(2,701,4797,2002,1,''),(2,701,4798,2428,1,''),(2,701,4799,3963,1,''),(2,701,4800,7379,1,''),(2,701,4801,1998,1,''),(2,701,4802,2002,1,''),(2,701,4803,2428,1,''),(2,701,4804,3963,1,''),(2,701,4805,7379,1,''),(2,701,4806,1998,1,''),(2,701,4807,2002,1,''),(2,702,4808,2428,1,''),(2,702,4809,3963,1,''),(2,702,4810,7379,1,''),(2,702,4811,1998,1,''),(2,702,4812,2002,1,''),(2,702,4813,2428,1,''),(2,702,4814,3963,1,''),(2,702,4815,7379,1,''),(2,702,4816,1998,1,''),(2,702,4817,2002,1,''),(2,702,4818,2428,1,''),(2,702,4819,3963,1,''),(2,702,4820,7379,1,''),(2,702,4821,1998,1,''),(2,702,4822,2002,1,''),(2,702,4823,2428,1,''),(2,702,4824,3963,1,''),(2,702,4825,7379,1,''),(2,702,4826,1998,1,''),(2,702,4827,2002,1,''),(2,706,4828,2428,1,''),(2,706,4829,3963,1,''),(2,706,4830,7379,1,''),(2,706,4831,1998,1,''),(2,706,4832,2002,1,''),(2,706,4833,2428,1,''),(2,706,4834,3963,1,''),(2,706,4835,7379,1,''),(2,706,4836,1998,1,''),(2,706,4837,2002,1,''),(2,706,4838,2428,1,''),(2,706,4839,3963,1,''),(2,706,4840,7379,1,''),(2,706,4841,1998,1,''),(2,706,4842,2002,1,''),(2,706,4843,2428,1,''),(2,706,4844,3963,1,''),(2,706,4845,7379,1,''),(2,706,4846,1998,1,''),(2,706,4847,2002,1,''),(2,707,4848,2428,1,''),(2,707,4849,3963,1,''),(2,707,4850,7379,1,''),(2,707,4851,1998,1,''),(2,707,4852,2002,1,''),(2,707,4853,2428,1,''),(2,707,4854,3963,1,''),(2,707,4855,7379,1,''),(2,707,4856,1998,1,''),(2,707,4857,2002,1,''),(2,707,4858,2428,1,''),(2,707,4859,3963,1,''),(2,707,4860,7379,1,''),(2,707,4861,1998,1,''),(2,707,4862,2002,1,''),(2,707,4863,2428,1,''),(2,707,4864,3963,1,''),(2,707,4865,7379,1,''),(2,707,4866,1998,1,''),(2,707,4867,2002,1,''),(2,711,4868,2428,1,''),(2,711,4869,3963,1,''),(2,711,4870,7379,1,''),(2,711,4871,1998,1,''),(2,711,4872,2002,1,''),(2,711,4873,2428,1,''),(2,711,4874,3963,1,''),(2,711,4875,7379,1,''),(2,711,4876,1998,1,''),(2,711,4877,2002,1,''),(2,711,4878,2428,1,''),(2,711,4879,3963,1,''),(2,711,4880,7379,1,''),(2,711,4881,1998,1,''),(2,711,4882,2002,1,''),(2,711,4883,2428,1,''),(2,711,4884,3963,1,''),(2,711,4885,7379,1,''),(2,711,4886,1998,1,''),(2,711,4887,2002,1,''),(2,712,4888,2428,1,''),(2,712,4889,3963,1,''),(2,712,4890,7379,1,''),(2,712,4891,1998,1,''),(2,712,4892,2002,1,''),(2,712,4893,2428,1,''),(2,712,4894,3963,1,''),(2,712,4895,7379,1,''),(2,712,4896,1998,1,''),(2,712,4897,2002,1,''),(2,712,4898,2428,1,''),(2,712,4899,3963,1,''),(2,712,4900,7379,1,''),(2,712,4901,1998,1,''),(2,712,4902,2002,1,''),(2,712,4903,2428,1,''),(2,712,4904,3963,1,''),(2,712,4905,7379,1,''),(2,712,4906,1998,1,''),(2,712,4907,2002,1,''),(2,716,4908,2428,1,''),(2,716,4909,3963,1,''),(2,716,4910,7379,1,''),(2,716,4911,1998,1,''),(2,716,4912,2002,1,''),(2,716,4913,2428,1,''),(2,716,4914,3963,1,''),(2,716,4915,7379,1,''),(2,716,4916,1998,1,''),(2,716,4917,2002,1,''),(2,716,4918,2428,1,''),(2,716,4919,3963,1,''),(2,716,4920,7379,1,''),(2,716,4921,1998,1,''),(2,716,4922,2002,1,''),(2,716,4923,2428,1,''),(2,716,4924,3963,1,''),(2,716,4925,7379,1,''),(2,716,4926,1998,1,''),(2,716,4927,2002,1,''),(2,717,4928,2428,1,''),(2,717,4929,3963,1,''),(2,717,4930,7379,1,''),(2,717,4931,1998,1,''),(2,717,4932,2002,1,''),(2,717,4933,2428,1,''),(2,717,4934,3963,1,''),(2,717,4935,7379,1,''),(2,717,4936,1998,1,''),(2,717,4937,2002,1,''),(2,717,4938,2428,1,''),(2,717,4939,3963,1,''),(2,717,4940,7379,1,''),(2,717,4941,1998,1,''),(2,717,4942,2002,1,''),(2,717,4943,2428,1,''),(2,717,4944,3963,1,''),(2,717,4945,7379,1,''),(2,717,4946,1998,1,''),(2,717,4947,2002,1,''),(2,721,4948,2428,1,''),(2,721,4949,3963,1,''),(2,721,4950,7379,1,''),(2,721,4951,1998,1,''),(2,721,4952,2002,1,''),(2,721,4953,2428,1,''),(2,721,4954,3963,1,''),(2,721,4955,7379,1,''),(2,721,4956,1998,1,''),(2,721,4957,2002,1,''),(2,721,4958,2428,1,''),(2,721,4959,3963,1,''),(2,721,4960,7379,1,''),(2,721,4961,1998,1,''),(2,721,4962,2002,1,''),(2,721,4963,2428,1,''),(2,721,4964,3963,1,''),(2,721,4965,7379,1,''),(2,721,4966,1998,1,''),(2,721,4967,2002,1,''),(2,722,4968,2428,1,''),(2,722,4969,3963,1,''),(2,722,4970,7379,1,''),(2,722,4971,1998,1,''),(2,722,4972,2002,1,''),(2,722,4973,2428,1,''),(2,722,4974,3963,1,''),(2,722,4975,7379,1,''),(2,722,4976,1998,1,''),(2,722,4977,2002,1,''),(2,722,4978,2428,1,''),(2,722,4979,3963,1,''),(2,722,4980,7379,1,''),(2,722,4981,1998,1,''),(2,722,4982,2002,1,''),(2,722,4983,2428,1,''),(2,722,4984,3963,1,''),(2,722,4985,7379,1,''),(2,722,4986,1998,1,''),(2,722,4987,2002,1,''),(2,726,4988,2428,1,''),(2,726,4989,3963,1,''),(2,726,4990,7379,1,''),(2,726,4991,1998,1,''),(2,726,4992,2002,1,''),(2,726,4993,2428,1,''),(2,726,4994,3963,1,''),(2,726,4995,7379,1,''),(2,726,4996,1998,1,''),(2,726,4997,2002,1,''),(2,726,4998,2428,1,''),(2,726,4999,3963,1,''),(2,726,5000,7379,1,''),(2,726,5001,1998,1,''),(2,726,5002,2002,1,''),(2,726,5003,2428,1,''),(2,726,5004,3963,1,''),(2,726,5005,7379,1,''),(2,726,5006,1998,1,''),(2,726,5007,2002,1,''),(2,727,5008,2428,1,''),(2,727,5009,3963,1,''),(2,727,5010,7379,1,''),(2,727,5011,1998,1,''),(2,727,5012,2002,1,''),(2,727,5013,2428,1,''),(2,727,5014,3963,1,''),(2,727,5015,7379,1,''),(2,727,5016,1998,1,''),(2,727,5017,2002,1,''),(2,727,5018,2428,1,''),(2,727,5019,3963,1,''),(2,727,5020,7379,1,''),(2,727,5021,1998,1,''),(2,727,5022,2002,1,''),(2,727,5023,2428,1,''),(2,727,5024,3963,1,''),(2,727,5025,7379,1,''),(2,727,5026,1998,1,''),(2,727,5027,2002,1,''),(2,731,5028,2428,1,''),(2,731,5029,3963,1,''),(2,731,5030,7379,1,''),(2,731,5031,1998,1,''),(2,731,5032,2002,1,''),(2,731,5033,2428,1,''),(2,731,5034,3963,1,''),(2,731,5035,7379,1,''),(2,731,5036,1998,1,''),(2,731,5037,2002,1,''),(2,731,5038,2428,1,''),(2,731,5039,3963,1,''),(2,731,5040,7379,1,''),(2,731,5041,1998,1,''),(2,731,5042,2002,1,''),(2,731,5043,2428,1,''),(2,731,5044,3963,1,''),(2,731,5045,7379,1,''),(2,731,5046,1998,1,''),(2,731,5047,2002,1,''),(2,732,5048,2428,1,''),(2,732,5049,3963,1,''),(2,732,5050,7379,1,''),(2,732,5051,1998,1,''),(2,732,5052,2002,1,''),(2,732,5053,2428,1,''),(2,732,5054,3963,1,''),(2,732,5055,7379,1,''),(2,732,5056,1998,1,''),(2,732,5057,2002,1,''),(2,732,5058,2428,1,''),(2,732,5059,3963,1,''),(2,732,5060,7379,1,''),(2,732,5061,1998,1,''),(2,732,5062,2002,1,''),(2,732,5063,2428,1,''),(2,732,5064,3963,1,''),(2,732,5065,7379,1,''),(2,732,5066,1998,1,''),(2,732,5067,2002,1,''),(2,736,5068,2428,1,''),(2,736,5069,3963,1,''),(2,736,5070,7379,1,''),(2,736,5071,1998,1,''),(2,736,5072,2002,1,''),(2,736,5073,2428,1,''),(2,736,5074,3963,1,''),(2,736,5075,7379,1,''),(2,736,5076,1998,1,''),(2,736,5077,2002,1,''),(2,736,5078,2428,1,''),(2,736,5079,3963,1,''),(2,736,5080,7379,1,''),(2,736,5081,1998,1,''),(2,736,5082,2002,1,''),(2,736,5083,2428,1,''),(2,736,5084,3963,1,''),(2,736,5085,7379,1,''),(2,736,5086,1998,1,''),(2,736,5087,2002,1,''),(2,737,5088,2428,1,''),(2,737,5089,3963,1,''),(2,737,5090,7379,1,''),(2,737,5091,1998,1,''),(2,737,5092,2002,1,''),(2,737,5093,2428,1,''),(2,737,5094,3963,1,''),(2,737,5095,7379,1,''),(2,737,5096,1998,1,''),(2,737,5097,2002,1,''),(2,737,5098,2428,1,''),(2,737,5099,3963,1,''),(2,737,5100,7379,1,''),(2,737,5101,1998,1,''),(2,737,5102,2002,1,''),(2,737,5103,2428,1,''),(2,737,5104,3963,1,''),(2,737,5105,7379,1,''),(2,737,5106,1998,1,''),(2,737,5107,2002,1,''),(2,741,5108,2428,1,''),(2,741,5109,3963,1,''),(2,741,5110,7379,1,''),(2,741,5111,1998,1,''),(2,741,5112,2002,1,''),(2,741,5113,2428,1,''),(2,741,5114,3963,1,''),(2,741,5115,7379,1,''),(2,741,5116,1998,1,''),(2,741,5117,2002,1,''),(2,741,5118,2428,1,''),(2,741,5119,3963,1,''),(2,741,5120,7379,1,''),(2,741,5121,1998,1,''),(2,741,5122,2002,1,''),(2,741,5123,2428,1,''),(2,741,5124,3963,1,''),(2,741,5125,7379,1,''),(2,741,5126,1998,1,''),(2,741,5127,2002,1,''),(2,742,5128,2428,1,''),(2,742,5129,3963,1,''),(2,742,5130,7379,1,''),(2,742,5131,1998,1,''),(2,742,5132,2002,1,''),(2,742,5133,2428,1,''),(2,742,5134,3963,1,''),(2,742,5135,7379,1,''),(2,742,5136,1998,1,''),(2,742,5137,2002,1,''),(2,742,5138,2428,1,''),(2,742,5139,3963,1,''),(2,742,5140,7379,1,''),(2,742,5141,1998,1,''),(2,742,5142,2002,1,''),(2,742,5143,2428,1,''),(2,742,5144,3963,1,''),(2,742,5145,7379,1,''),(2,742,5146,1998,1,''),(2,742,5147,2002,1,''),(2,746,5148,2428,1,''),(2,746,5149,3963,1,''),(2,746,5150,7379,1,''),(2,746,5151,1998,1,''),(2,746,5152,2002,1,''),(2,746,5153,2428,1,''),(2,746,5154,3963,1,''),(2,746,5155,7379,1,''),(2,746,5156,1998,1,''),(2,746,5157,2002,1,''),(2,746,5158,2428,1,''),(2,746,5159,3963,1,''),(2,746,5160,7379,1,''),(2,746,5161,1998,1,''),(2,746,5162,2002,1,''),(2,746,5163,2428,1,''),(2,746,5164,3963,1,''),(2,746,5165,7379,1,''),(2,746,5166,1998,1,''),(2,746,5167,2002,1,''),(2,747,5168,2428,1,''),(2,747,5169,3963,1,''),(2,747,5170,7379,1,''),(2,747,5171,1998,1,''),(2,747,5172,2002,1,''),(2,747,5173,2428,1,''),(2,747,5174,3963,1,''),(2,747,5175,7379,1,''),(2,747,5176,1998,1,''),(2,747,5177,2002,1,''),(2,747,5178,2428,1,''),(2,747,5179,3963,1,''),(2,747,5180,7379,1,''),(2,747,5181,1998,1,''),(2,747,5182,2002,1,''),(2,747,5183,2428,1,''),(2,747,5184,3963,1,''),(2,747,5185,7379,1,''),(2,747,5186,1998,1,''),(2,747,5187,2002,1,''),(2,751,5188,2428,1,''),(2,751,5189,3963,1,''),(2,751,5190,7379,1,''),(2,751,5191,1998,1,''),(2,751,5192,2002,1,''),(2,751,5193,2428,1,''),(2,751,5194,3963,1,''),(2,751,5195,7379,1,''),(2,751,5196,1998,1,''),(2,751,5197,2002,1,''),(2,751,5198,2428,1,''),(2,751,5199,3963,1,''),(2,751,5200,7379,1,''),(2,751,5201,1998,1,''),(2,751,5202,2002,1,''),(2,751,5203,2428,1,''),(2,751,5204,3963,1,''),(2,751,5205,7379,1,''),(2,751,5206,1998,1,''),(2,751,5207,2002,1,''),(2,752,5208,2428,1,''),(2,752,5209,3963,1,''),(2,752,5210,7379,1,''),(2,752,5211,1998,1,''),(2,752,5212,2002,1,''),(2,752,5213,2428,1,''),(2,752,5214,3963,1,''),(2,752,5215,7379,1,''),(2,752,5216,1998,1,''),(2,752,5217,2002,1,''),(2,752,5218,2428,1,''),(2,752,5219,3963,1,''),(2,752,5220,7379,1,''),(2,752,5221,1998,1,''),(2,752,5222,2002,1,''),(2,752,5223,2428,1,''),(2,752,5224,3963,1,''),(2,752,5225,7379,1,''),(2,752,5226,1998,1,''),(2,752,5227,2002,1,''),(2,756,5228,2428,1,''),(2,756,5229,3963,1,''),(2,756,5230,7379,1,''),(2,756,5231,1998,1,''),(2,756,5232,2002,1,''),(2,756,5233,2428,1,''),(2,756,5234,3963,1,''),(2,756,5235,7379,1,''),(2,756,5236,1998,1,''),(2,756,5237,2002,1,''),(2,756,5238,2428,1,''),(2,756,5239,3963,1,''),(2,756,5240,7379,1,''),(2,756,5241,1998,1,''),(2,756,5242,2002,1,''),(2,756,5243,2428,1,''),(2,756,5244,3963,1,''),(2,756,5245,7379,1,''),(2,756,5246,1998,1,''),(2,756,5247,2002,1,''),(2,757,5248,2428,1,''),(2,757,5249,3963,1,''),(2,757,5250,7379,1,''),(2,757,5251,1998,1,''),(2,757,5252,2002,1,''),(2,757,5253,2428,1,''),(2,757,5254,3963,1,''),(2,757,5255,7379,1,''),(2,757,5256,1998,1,''),(2,757,5257,2002,1,''),(2,757,5258,2428,1,''),(2,757,5259,3963,1,''),(2,757,5260,7379,1,''),(2,757,5261,1998,1,''),(2,757,5262,2002,1,''),(2,757,5263,2428,1,''),(2,757,5264,3963,1,''),(2,757,5265,7379,1,''),(2,757,5266,1998,1,''),(2,757,5267,2002,1,''),(2,761,5268,2428,1,''),(2,761,5269,3963,1,''),(2,761,5270,7379,1,''),(2,761,5271,1998,1,''),(2,761,5272,2002,1,''),(2,761,5273,2428,1,''),(2,761,5274,3963,1,''),(2,761,5275,7379,1,''),(2,761,5276,1998,1,''),(2,761,5277,2002,1,''),(2,761,5278,2428,1,''),(2,761,5279,3963,1,''),(2,761,5280,7379,1,''),(2,761,5281,1998,1,''),(2,761,5282,2002,1,''),(2,761,5283,2428,1,''),(2,761,5284,3963,1,''),(2,761,5285,7379,1,''),(2,761,5286,1998,1,''),(2,761,5287,2002,1,''),(2,762,5288,2428,1,''),(2,762,5289,3963,1,''),(2,762,5290,7379,1,''),(2,762,5291,1998,1,''),(2,762,5292,2002,1,''),(2,762,5293,2428,1,''),(2,762,5294,3963,1,''),(2,762,5295,7379,1,''),(2,762,5296,1998,1,''),(2,762,5297,2002,1,''),(2,762,5298,2428,1,''),(2,762,5299,3963,1,''),(2,762,5300,7379,1,''),(2,762,5301,1998,1,''),(2,762,5302,2002,1,''),(2,762,5303,2428,1,''),(2,762,5304,3963,1,''),(2,762,5305,7379,1,''),(2,762,5306,1998,1,''),(2,762,5307,2002,1,''),(2,766,5308,2428,1,''),(2,766,5309,3963,1,''),(2,766,5310,7379,1,''),(2,766,5311,1998,1,''),(2,766,5312,2002,1,''),(2,766,5313,2428,1,''),(2,766,5314,3963,1,''),(2,766,5315,7379,1,''),(2,766,5316,1998,1,''),(2,766,5317,2002,1,''),(2,766,5318,2428,1,''),(2,766,5319,3963,1,''),(2,766,5320,7379,1,''),(2,766,5321,1998,1,''),(2,766,5322,2002,1,''),(2,766,5323,2428,1,''),(2,766,5324,3963,1,''),(2,766,5325,7379,1,''),(2,766,5326,1998,1,''),(2,766,5327,2002,1,''),(2,767,5328,2428,1,''),(2,767,5329,3963,1,''),(2,767,5330,7379,1,''),(2,767,5331,1998,1,''),(2,767,5332,2002,1,''),(2,767,5333,2428,1,''),(2,767,5334,3963,1,''),(2,767,5335,7379,1,''),(2,767,5336,1998,1,''),(2,767,5337,2002,1,''),(2,767,5338,2428,1,''),(2,767,5339,3963,1,''),(2,767,5340,7379,1,''),(2,767,5341,1998,1,''),(2,767,5342,2002,1,''),(2,767,5343,2428,1,''),(2,767,5344,3963,1,''),(2,767,5345,7379,1,''),(2,767,5346,1998,1,''),(2,767,5347,2002,1,''),(2,771,5348,2428,1,''),(2,771,5349,3963,1,''),(2,771,5350,7379,1,''),(2,771,5351,1998,1,''),(2,771,5352,2002,1,''),(2,771,5353,2428,1,''),(2,771,5354,3963,1,''),(2,771,5355,7379,1,''),(2,771,5356,1998,1,''),(2,771,5357,2002,1,''),(2,771,5358,2428,1,''),(2,771,5359,3963,1,''),(2,771,5360,7379,1,''),(2,771,5361,1998,1,''),(2,771,5362,2002,1,''),(2,771,5363,2428,1,''),(2,771,5364,3963,1,''),(2,771,5365,7379,1,''),(2,771,5366,1998,1,''),(2,771,5367,2002,1,''),(2,772,5368,2428,1,''),(2,772,5369,3963,1,''),(2,772,5370,7379,1,''),(2,772,5371,1998,1,''),(2,772,5372,2002,1,''),(2,772,5373,2428,1,''),(2,772,5374,3963,1,''),(2,772,5375,7379,1,''),(2,772,5376,1998,1,''),(2,772,5377,2002,1,''),(2,772,5378,2428,1,''),(2,772,5379,3963,1,''),(2,772,5380,7379,1,''),(2,772,5381,1998,1,''),(2,772,5382,2002,1,''),(2,772,5383,2428,1,''),(2,772,5384,3963,1,''),(2,772,5385,7379,1,''),(2,772,5386,1998,1,''),(2,772,5387,2002,1,''),(2,776,5388,2428,1,''),(2,776,5389,3963,1,''),(2,776,5390,7379,1,''),(2,776,5391,1998,1,''),(2,776,5392,2002,1,''),(2,776,5393,2428,1,''),(2,776,5394,3963,1,''),(2,776,5395,7379,1,''),(2,776,5396,1998,1,''),(2,776,5397,2002,1,''),(2,776,5398,2428,1,''),(2,776,5399,3963,1,''),(2,776,5400,7379,1,''),(2,776,5401,1998,1,''),(2,776,5402,2002,1,''),(2,776,5403,2428,1,''),(2,776,5404,3963,1,''),(2,776,5405,7379,1,''),(2,776,5406,1998,1,''),(2,776,5407,2002,1,''),(2,777,5408,2428,1,''),(2,777,5409,3963,1,''),(2,777,5410,7379,1,''),(2,777,5411,1998,1,''),(2,777,5412,2002,1,''),(2,777,5413,2428,1,''),(2,777,5414,3963,1,''),(2,777,5415,7379,1,''),(2,777,5416,1998,1,''),(2,777,5417,2002,1,''),(2,777,5418,2428,1,''),(2,777,5419,3963,1,''),(2,777,5420,7379,1,''),(2,777,5421,1998,1,''),(2,777,5422,2002,1,''),(2,777,5423,2428,1,''),(2,777,5424,3963,1,''),(2,777,5425,7379,1,''),(2,777,5426,1998,1,''),(2,777,5427,2002,1,''),(2,781,5428,2428,1,''),(2,781,5429,3963,1,''),(2,781,5430,7379,1,''),(2,781,5431,1998,1,''),(2,781,5432,2002,1,''),(2,781,5433,2428,1,''),(2,781,5434,3963,1,''),(2,781,5435,7379,1,''),(2,781,5436,1998,1,''),(2,781,5437,2002,1,''),(2,781,5438,2428,1,''),(2,781,5439,3963,1,''),(2,781,5440,7379,1,''),(2,781,5441,1998,1,''),(2,781,5442,2002,1,''),(2,781,5443,2428,1,''),(2,781,5444,3963,1,''),(2,781,5445,7379,1,''),(2,781,5446,1998,1,''),(2,781,5447,2002,1,''),(2,782,5448,2428,1,''),(2,782,5449,3963,1,''),(2,782,5450,7379,1,''),(2,782,5451,1998,1,''),(2,782,5452,2002,1,''),(2,782,5453,2428,1,''),(2,782,5454,3963,1,''),(2,782,5455,7379,1,''),(2,782,5456,1998,1,''),(2,782,5457,2002,1,''),(2,782,5458,2428,1,''),(2,782,5459,3963,1,''),(2,782,5460,7379,1,''),(2,782,5461,1998,1,''),(2,782,5462,2002,1,''),(2,782,5463,2428,1,''),(2,782,5464,3963,1,''),(2,782,5465,7379,1,''),(2,782,5466,1998,1,''),(2,782,5467,2002,1,''),(2,786,5468,2428,1,''),(2,786,5469,3963,1,''),(2,786,5470,7379,1,''),(2,786,5471,1998,1,''),(2,786,5472,2002,1,''),(2,786,5473,2428,1,''),(2,786,5474,3963,1,''),(2,786,5475,7379,1,''),(2,786,5476,1998,1,''),(2,786,5477,2002,1,''),(2,786,5478,2428,1,''),(2,786,5479,3963,1,''),(2,786,5480,7379,1,''),(2,786,5481,1998,1,''),(2,786,5482,2002,1,''),(2,786,5483,2428,1,''),(2,786,5484,3963,1,''),(2,786,5485,7379,1,''),(2,786,5486,1998,1,''),(2,786,5487,2002,1,''),(2,787,5488,2428,1,''),(2,787,5489,3963,1,''),(2,787,5490,7379,1,''),(2,787,5491,1998,1,''),(2,787,5492,2002,1,''),(2,787,5493,2428,1,''),(2,787,5494,3963,1,''),(2,787,5495,7379,1,''),(2,787,5496,1998,1,''),(2,787,5497,2002,1,''),(2,787,5498,2428,1,''),(2,787,5499,3963,1,''),(2,787,5500,7379,1,''),(2,787,5501,1998,1,''),(2,787,5502,2002,1,''),(2,787,5503,2428,1,''),(2,787,5504,3963,1,''),(2,787,5505,7379,1,''),(2,787,5506,1998,1,''),(2,787,5507,2002,1,''),(2,791,5508,2428,1,''),(2,791,5509,3963,1,''),(2,791,5510,7379,1,''),(2,791,5511,1998,1,''),(2,791,5512,2002,1,''),(2,791,5513,2428,1,''),(2,791,5514,3963,1,''),(2,791,5515,7379,1,''),(2,791,5516,1998,1,''),(2,791,5517,2002,1,''),(2,791,5518,2428,1,''),(2,791,5519,3963,1,''),(2,791,5520,7379,1,''),(2,791,5521,1998,1,''),(2,791,5522,2002,1,''),(2,791,5523,2428,1,''),(2,791,5524,3963,1,''),(2,791,5525,7379,1,''),(2,791,5526,1998,1,''),(2,791,5527,2002,1,''),(2,792,5528,2428,1,''),(2,792,5529,3963,1,''),(2,792,5530,7379,1,''),(2,792,5531,1998,1,''),(2,792,5532,2002,1,''),(2,792,5533,2428,1,''),(2,792,5534,3963,1,''),(2,792,5535,7379,1,''),(2,792,5536,1998,1,''),(2,792,5537,2002,1,''),(2,792,5538,2428,1,''),(2,792,5539,3963,1,''),(2,792,5540,7379,1,''),(2,792,5541,1998,1,''),(2,792,5542,2002,1,''),(2,792,5543,2428,1,''),(2,792,5544,3963,1,''),(2,792,5545,7379,1,''),(2,792,5546,1998,1,''),(2,792,5547,2002,1,''),(2,796,5548,2428,1,''),(2,796,5549,3963,1,''),(2,796,5550,7379,1,''),(2,796,5551,1998,1,''),(2,796,5552,2002,1,''),(2,796,5553,2428,1,''),(2,796,5554,3963,1,''),(2,796,5555,7379,1,''),(2,796,5556,1998,1,''),(2,796,5557,2002,1,''),(2,796,5558,2428,1,''),(2,796,5559,3963,1,''),(2,796,5560,7379,1,''),(2,796,5561,1998,1,''),(2,796,5562,2002,1,''),(2,796,5563,2428,1,''),(2,796,5564,3963,1,''),(2,796,5565,7379,1,''),(2,796,5566,1998,1,''),(2,796,5567,2002,1,''),(2,797,5568,2428,1,''),(2,797,5569,3963,1,''),(2,797,5570,7379,1,''),(2,797,5571,1998,1,''),(2,797,5572,2002,1,''),(2,797,5573,2428,1,''),(2,797,5574,3963,1,''),(2,797,5575,7379,1,''),(2,797,5576,1998,1,''),(2,797,5577,2002,1,''),(2,797,5578,2428,1,''),(2,797,5579,3963,1,''),(2,797,5580,7379,1,''),(2,797,5581,1998,1,''),(2,797,5582,2002,1,''),(2,797,5583,2428,1,''),(2,797,5584,3963,1,''),(2,797,5585,7379,1,''),(2,797,5586,1998,1,''),(2,797,5587,2002,1,''),(2,801,5588,2428,1,''),(2,801,5589,3963,1,''),(2,801,5590,7379,1,''),(2,801,5591,1998,1,''),(2,801,5592,2002,1,''),(2,801,5593,2428,1,''),(2,801,5594,3963,1,''),(2,801,5595,7379,1,''),(2,801,5596,1998,1,''),(2,801,5597,2002,1,''),(2,801,5598,2428,1,''),(2,801,5599,3963,1,''),(2,801,5600,7379,1,''),(2,801,5601,1998,1,''),(2,801,5602,2002,1,''),(2,801,5603,2428,1,''),(2,801,5604,3963,1,''),(2,801,5605,7379,1,''),(2,801,5606,1998,1,''),(2,801,5607,2002,1,''),(2,802,5608,2428,1,''),(2,802,5609,3963,1,''),(2,802,5610,7379,1,''),(2,802,5611,1998,1,''),(2,802,5612,2002,1,''),(2,802,5613,2428,1,''),(2,802,5614,3963,1,''),(2,802,5615,7379,1,''),(2,802,5616,1998,1,''),(2,802,5617,2002,1,''),(2,802,5618,2428,1,''),(2,802,5619,3963,1,''),(2,802,5620,7379,1,''),(2,802,5621,1998,1,''),(2,802,5622,2002,1,''),(2,802,5623,2428,1,''),(2,802,5624,3963,1,''),(2,802,5625,7379,1,''),(2,802,5626,1998,1,''),(2,802,5627,2002,1,''),(2,806,5628,2428,1,''),(2,806,5629,3963,1,''),(2,806,5630,7379,1,''),(2,806,5631,1998,1,''),(2,806,5632,2002,1,''),(2,806,5633,2428,1,''),(2,806,5634,3963,1,''),(2,806,5635,7379,1,''),(2,806,5636,1998,1,''),(2,806,5637,2002,1,''),(2,806,5638,2428,1,''),(2,806,5639,3963,1,''),(2,806,5640,7379,1,''),(2,806,5641,1998,1,''),(2,806,5642,2002,1,''),(2,806,5643,2428,1,''),(2,806,5644,3963,1,''),(2,806,5645,7379,1,''),(2,806,5646,1998,1,''),(2,806,5647,2002,1,''),(2,807,5648,2428,1,''),(2,807,5649,3963,1,''),(2,807,5650,7379,1,''),(2,807,5651,1998,1,''),(2,807,5652,2002,1,''),(2,807,5653,2428,1,''),(2,807,5654,3963,1,''),(2,807,5655,7379,1,''),(2,807,5656,1998,1,''),(2,807,5657,2002,1,''),(2,807,5658,2428,1,''),(2,807,5659,3963,1,''),(2,807,5660,7379,1,''),(2,807,5661,1998,1,''),(2,807,5662,2002,1,''),(2,807,5663,2428,1,''),(2,807,5664,3963,1,''),(2,807,5665,7379,1,''),(2,807,5666,1998,1,''),(2,807,5667,2002,1,''),(2,811,5668,2428,1,''),(2,811,5669,3963,1,''),(2,811,5670,7379,1,''),(2,811,5671,1998,1,''),(2,811,5672,2002,1,''),(2,811,5673,2428,1,''),(2,811,5674,3963,1,''),(2,811,5675,7379,1,''),(2,811,5676,1998,1,''),(2,811,5677,2002,1,''),(2,811,5678,2428,1,''),(2,811,5679,3963,1,''),(2,811,5680,7379,1,''),(2,811,5681,1998,1,''),(2,811,5682,2002,1,''),(2,811,5683,2428,1,''),(2,811,5684,3963,1,''),(2,811,5685,7379,1,''),(2,811,5686,1998,1,''),(2,811,5687,2002,1,''),(2,812,5688,2428,1,''),(2,812,5689,3963,1,''),(2,812,5690,7379,1,''),(2,812,5691,1998,1,''),(2,812,5692,2002,1,''),(2,812,5693,2428,1,''),(2,812,5694,3963,1,''),(2,812,5695,7379,1,''),(2,812,5696,1998,1,''),(2,812,5697,2002,1,''),(2,812,5698,2428,1,''),(2,812,5699,3963,1,''),(2,812,5700,7379,1,''),(2,812,5701,1998,1,''),(2,812,5702,2002,1,''),(2,812,5703,2428,1,''),(2,812,5704,3963,1,''),(2,812,5705,7379,1,''),(2,812,5706,1998,1,''),(2,812,5707,2002,1,''),(2,816,5708,2428,1,''),(2,816,5709,3963,1,''),(2,816,5710,7379,1,''),(2,816,5711,1998,1,''),(2,816,5712,2002,1,''),(2,816,5713,2428,1,''),(2,816,5714,3963,1,''),(2,816,5715,7379,1,''),(2,816,5716,1998,1,''),(2,816,5717,2002,1,''),(2,816,5718,2428,1,''),(2,816,5719,3963,1,''),(2,816,5720,7379,1,''),(2,816,5721,1998,1,''),(2,816,5722,2002,1,''),(2,816,5723,2428,1,''),(2,816,5724,3963,1,''),(2,816,5725,7379,1,''),(2,816,5726,1998,1,''),(2,816,5727,2002,1,''),(2,817,5728,2428,1,''),(2,817,5729,3963,1,''),(2,817,5730,7379,1,''),(2,817,5731,1998,1,''),(2,817,5732,2002,1,''),(2,817,5733,2428,1,''),(2,817,5734,3963,1,''),(2,817,5735,7379,1,''),(2,817,5736,1998,1,''),(2,817,5737,2002,1,''),(2,817,5738,2428,1,''),(2,817,5739,3963,1,''),(2,817,5740,7379,1,''),(2,817,5741,1998,1,''),(2,817,5742,2002,1,''),(2,817,5743,2428,1,''),(2,817,5744,3963,1,''),(2,817,5745,7379,1,''),(2,817,5746,1998,1,''),(2,817,5747,2002,1,''),(2,821,5748,2428,1,''),(2,821,5749,3963,1,''),(2,821,5750,7379,1,''),(2,821,5751,1998,1,''),(2,821,5752,2002,1,''),(2,821,5753,2428,1,''),(2,821,5754,3963,1,''),(2,821,5755,7379,1,''),(2,821,5756,1998,1,''),(2,821,5757,2002,1,''),(2,821,5758,2428,1,''),(2,821,5759,3963,1,''),(2,821,5760,7379,1,''),(2,821,5761,1998,1,''),(2,821,5762,2002,1,''),(2,821,5763,2428,1,''),(2,821,5764,3963,1,''),(2,821,5765,7379,1,''),(2,821,5766,1998,1,''),(2,821,5767,2002,1,''),(2,822,5768,2428,1,''),(2,822,5769,3963,1,''),(2,822,5770,7379,1,''),(2,822,5771,1998,1,''),(2,822,5772,2002,1,''),(2,822,5773,2428,1,''),(2,822,5774,3963,1,''),(2,822,5775,7379,1,''),(2,822,5776,1998,1,''),(2,822,5777,2002,1,''),(2,822,5778,2428,1,''),(2,822,5779,3963,1,''),(2,822,5780,7379,1,''),(2,822,5781,1998,1,''),(2,822,5782,2002,1,''),(2,822,5783,2428,1,''),(2,822,5784,3963,1,''),(2,822,5785,7379,1,''),(2,822,5786,1998,1,''),(2,822,5787,2002,1,''),(2,826,5788,2428,1,''),(2,826,5789,3963,1,''),(2,826,5790,7379,1,''),(2,826,5791,1998,1,''),(2,826,5792,2002,1,''),(2,826,5793,2428,1,''),(2,826,5794,3963,1,''),(2,826,5795,7379,1,''),(2,826,5796,1998,1,''),(2,826,5797,2002,1,''),(2,826,5798,2428,1,''),(2,826,5799,3963,1,''),(2,826,5800,7379,1,''),(2,826,5801,1998,1,''),(2,826,5802,2002,1,''),(2,826,5803,2428,1,''),(2,826,5804,3963,1,''),(2,826,5805,7379,1,''),(2,826,5806,1998,1,''),(2,826,5807,2002,1,''),(2,827,5808,2428,1,''),(2,827,5809,3963,1,''),(2,827,5810,7379,1,''),(2,827,5811,1998,1,''),(2,827,5812,2002,1,''),(2,827,5813,2428,1,''),(2,827,5814,3963,1,''),(2,827,5815,7379,1,''),(2,827,5816,1998,1,''),(2,827,5817,2002,1,''),(2,827,5818,2428,1,''),(2,827,5819,3963,1,''),(2,827,5820,7379,1,''),(2,827,5821,1998,1,''),(2,827,5822,2002,1,''),(2,827,5823,2428,1,''),(2,827,5824,3963,1,''),(2,827,5825,7379,1,''),(2,827,5826,1998,1,''),(2,827,5827,2002,1,''),(2,831,5828,2428,1,''),(2,831,5829,3963,1,''),(2,831,5830,7379,1,''),(2,831,5831,1998,1,''),(2,831,5832,2002,1,''),(2,831,5833,2428,1,''),(2,831,5834,3963,1,''),(2,831,5835,7379,1,''),(2,831,5836,1998,1,''),(2,831,5837,2002,1,''),(2,831,5838,2428,1,''),(2,831,5839,3963,1,''),(2,831,5840,7379,1,''),(2,831,5841,1998,1,''),(2,831,5842,2002,1,''),(2,831,5843,2428,1,''),(2,831,5844,3963,1,''),(2,831,5845,7379,1,''),(2,831,5846,1998,1,''),(2,831,5847,2002,1,''),(2,832,5848,2428,1,''),(2,832,5849,3963,1,''),(2,832,5850,7379,1,''),(2,832,5851,1998,1,''),(2,832,5852,2002,1,''),(2,832,5853,2428,1,''),(2,832,5854,3963,1,''),(2,832,5855,7379,1,''),(2,832,5856,1998,1,''),(2,832,5857,2002,1,''),(2,832,5858,2428,1,''),(2,832,5859,3963,1,''),(2,832,5860,7379,1,''),(2,832,5861,1998,1,''),(2,832,5862,2002,1,''),(2,832,5863,2428,1,''),(2,832,5864,3963,1,''),(2,832,5865,7379,1,''),(2,832,5866,1998,1,''),(2,832,5867,2002,1,''),(2,836,5868,2428,1,''),(2,836,5869,3963,1,''),(2,836,5870,7379,1,''),(2,836,5871,1998,1,''),(2,836,5872,2002,1,''),(2,836,5873,2428,1,''),(2,836,5874,3963,1,''),(2,836,5875,7379,1,''),(2,836,5876,1998,1,''),(2,836,5877,2002,1,''),(2,836,5878,2428,1,''),(2,836,5879,3963,1,''),(2,836,5880,7379,1,''),(2,836,5881,1998,1,''),(2,836,5882,2002,1,''),(2,836,5883,2428,1,''),(2,836,5884,3963,1,''),(2,836,5885,7379,1,''),(2,836,5886,1998,1,''),(2,836,5887,2002,1,''),(2,837,5888,2428,1,''),(2,837,5889,3963,1,''),(2,837,5890,7379,1,''),(2,837,5891,1998,1,''),(2,837,5892,2002,1,''),(2,837,5893,2428,1,''),(2,837,5894,3963,1,''),(2,837,5895,7379,1,''),(2,837,5896,1998,1,''),(2,837,5897,2002,1,''),(2,837,5898,2428,1,''),(2,837,5899,3963,1,''),(2,837,5900,7379,1,''),(2,837,5901,1998,1,''),(2,837,5902,2002,1,''),(2,837,5903,2428,1,''),(2,837,5904,3963,1,''),(2,837,5905,7379,1,''),(2,837,5906,1998,1,''),(2,837,5907,2002,1,''),(2,841,5908,2428,1,''),(2,841,5909,3963,1,''),(2,841,5910,7379,1,''),(2,841,5911,1998,1,''),(2,841,5912,2002,1,''),(2,841,5913,2428,1,''),(2,841,5914,3963,1,''),(2,841,5915,7379,1,''),(2,841,5916,1998,1,''),(2,841,5917,2002,1,''),(2,841,5918,2428,1,''),(2,841,5919,3963,1,''),(2,841,5920,7379,1,''),(2,841,5921,1998,1,''),(2,841,5922,2002,1,''),(2,841,5923,2428,1,''),(2,841,5924,3963,1,''),(2,841,5925,7379,1,''),(2,841,5926,1998,1,''),(2,841,5927,2002,1,''),(2,842,5928,2428,1,''),(2,842,5929,3963,1,''),(2,842,5930,7379,1,''),(2,842,5931,1998,1,''),(2,842,5932,2002,1,''),(2,842,5933,2428,1,''),(2,842,5934,3963,1,''),(2,842,5935,7379,1,''),(2,842,5936,1998,1,''),(2,842,5937,2002,1,''),(2,842,5938,2428,1,''),(2,842,5939,3963,1,''),(2,842,5940,7379,1,''),(2,842,5941,1998,1,''),(2,842,5942,2002,1,''),(2,842,5943,2428,1,''),(2,842,5944,3963,1,''),(2,842,5945,7379,1,''),(2,842,5946,1998,1,''),(2,842,5947,2002,1,''),(2,846,5948,2428,1,''),(2,846,5949,3963,1,''),(2,846,5950,7379,1,''),(2,846,5951,1998,1,''),(2,846,5952,2002,1,''),(2,846,5953,2428,1,''),(2,846,5954,3963,1,''),(2,846,5955,7379,1,''),(2,846,5956,1998,1,''),(2,846,5957,2002,1,''),(2,846,5958,2428,1,''),(2,846,5959,3963,1,''),(2,846,5960,7379,1,''),(2,846,5961,1998,1,''),(2,846,5962,2002,1,''),(2,846,5963,2428,1,''),(2,846,5964,3963,1,''),(2,846,5965,7379,1,''),(2,846,5966,1998,1,''),(2,846,5967,2002,1,''),(2,847,5968,2428,1,''),(2,847,5969,3963,1,''),(2,847,5970,7379,1,''),(2,847,5971,1998,1,''),(2,847,5972,2002,1,''),(2,847,5973,2428,1,''),(2,847,5974,3963,1,''),(2,847,5975,7379,1,''),(2,847,5976,1998,1,''),(2,847,5977,2002,1,''),(2,847,5978,2428,1,''),(2,847,5979,3963,1,''),(2,847,5980,7379,1,''),(2,847,5981,1998,1,''),(2,847,5982,2002,1,''),(2,847,5983,2428,1,''),(2,847,5984,3963,1,''),(2,847,5985,7379,1,''),(2,847,5986,1998,1,''),(2,847,5987,2002,1,''),(2,851,5988,2428,1,''),(2,851,5989,3963,1,''),(2,851,5990,7379,1,''),(2,851,5991,1998,1,''),(2,851,5992,2002,1,''),(2,851,5993,2428,1,''),(2,851,5994,3963,1,''),(2,851,5995,7379,1,''),(2,851,5996,1998,1,''),(2,851,5997,2002,1,''),(2,851,5998,2428,1,''),(2,851,5999,3963,1,''),(2,851,6000,7379,1,''),(2,851,6001,1998,1,''),(2,851,6002,2002,1,''),(2,851,6003,2428,1,''),(2,851,6004,3963,1,''),(2,851,6005,7379,1,''),(2,851,6006,1998,1,''),(2,851,6007,2002,1,''),(2,852,6008,2428,1,''),(2,852,6009,3963,1,''),(2,852,6010,7379,1,''),(2,852,6011,1998,1,''),(2,852,6012,2002,1,''),(2,852,6013,2428,1,''),(2,852,6014,3963,1,''),(2,852,6015,7379,1,''),(2,852,6016,1998,1,''),(2,852,6017,2002,1,''),(2,852,6018,2428,1,''),(2,852,6019,3963,1,''),(2,852,6020,7379,1,''),(2,852,6021,1998,1,''),(2,852,6022,2002,1,''),(2,852,6023,2428,1,''),(2,852,6024,3963,1,''),(2,852,6025,7379,1,''),(2,852,6026,1998,1,''),(2,852,6027,2002,1,''),(2,856,6028,2428,1,''),(2,856,6029,3963,1,''),(2,856,6030,7379,1,''),(2,856,6031,1998,1,''),(2,856,6032,2002,1,''),(2,856,6033,2428,1,''),(2,856,6034,3963,1,''),(2,856,6035,7379,1,''),(2,856,6036,1998,1,''),(2,856,6037,2002,1,''),(2,856,6038,2428,1,''),(2,856,6039,3963,1,''),(2,856,6040,7379,1,''),(2,856,6041,1998,1,''),(2,856,6042,2002,1,''),(2,856,6043,2428,1,''),(2,856,6044,3963,1,''),(2,856,6045,7379,1,''),(2,856,6046,1998,1,''),(2,856,6047,2002,1,''),(2,857,6048,2428,1,''),(2,857,6049,3963,1,''),(2,857,6050,7379,1,''),(2,857,6051,1998,1,''),(2,857,6052,2002,1,''),(2,857,6053,2428,1,''),(2,857,6054,3963,1,''),(2,857,6055,7379,1,''),(2,857,6056,1998,1,''),(2,857,6057,2002,1,''),(2,857,6058,2428,1,''),(2,857,6059,3963,1,''),(2,857,6060,7379,1,''),(2,857,6061,1998,1,''),(2,857,6062,2002,1,''),(2,857,6063,2428,1,''),(2,857,6064,3963,1,''),(2,857,6065,7379,1,''),(2,857,6066,1998,1,''),(2,857,6067,2002,1,''),(2,861,6068,2428,1,''),(2,861,6069,3963,1,''),(2,861,6070,7379,1,''),(2,861,6071,1998,1,''),(2,861,6072,2002,1,''),(2,861,6073,2428,1,''),(2,861,6074,3963,1,''),(2,861,6075,7379,1,''),(2,861,6076,1998,1,''),(2,861,6077,2002,1,''),(2,861,6078,2428,1,''),(2,861,6079,3963,1,''),(2,861,6080,7379,1,''),(2,861,6081,1998,1,''),(2,861,6082,2002,1,''),(2,861,6083,2428,1,''),(2,861,6084,3963,1,''),(2,861,6085,7379,1,''),(2,861,6086,1998,1,''),(2,861,6087,2002,1,''),(2,862,6088,2428,1,''),(2,862,6089,3963,1,''),(2,862,6090,7379,1,''),(2,862,6091,1998,1,''),(2,862,6092,2002,1,''),(2,862,6093,2428,1,''),(2,862,6094,3963,1,''),(2,862,6095,7379,1,''),(2,862,6096,1998,1,''),(2,862,6097,2002,1,''),(2,862,6098,2428,1,''),(2,862,6099,3963,1,''),(2,862,6100,7379,1,''),(2,862,6101,1998,1,''),(2,862,6102,2002,1,''),(2,862,6103,2428,1,''),(2,862,6104,3963,1,''),(2,862,6105,7379,1,''),(2,862,6106,1998,1,''),(2,862,6107,2002,1,''),(2,866,6108,2428,1,''),(2,866,6109,3963,1,''),(2,866,6110,7379,1,''),(2,866,6111,1998,1,''),(2,866,6112,2002,1,''),(2,866,6113,2428,1,''),(2,866,6114,3963,1,''),(2,866,6115,7379,1,''),(2,866,6116,1998,1,''),(2,866,6117,2002,1,''),(2,866,6118,2428,1,''),(2,866,6119,3963,1,''),(2,866,6120,7379,1,''),(2,866,6121,1998,1,''),(2,866,6122,2002,1,''),(2,866,6123,2428,1,''),(2,866,6124,3963,1,''),(2,866,6125,7379,1,''),(2,866,6126,1998,1,''),(2,866,6127,2002,1,''),(2,867,6128,2428,1,''),(2,867,6129,3963,1,''),(2,867,6130,7379,1,''),(2,867,6131,1998,1,''),(2,867,6132,2002,1,''),(2,867,6133,2428,1,''),(2,867,6134,3963,1,''),(2,867,6135,7379,1,''),(2,867,6136,1998,1,''),(2,867,6137,2002,1,''),(2,867,6138,2428,1,''),(2,867,6139,3963,1,''),(2,867,6140,7379,1,''),(2,867,6141,1998,1,''),(2,867,6142,2002,1,''),(2,867,6143,2428,1,''),(2,867,6144,3963,1,''),(2,867,6145,7379,1,''),(2,867,6146,1998,1,''),(2,867,6147,2002,1,''),(2,871,6148,2002,1,''),(2,871,6149,2428,1,''),(2,871,6150,3963,1,''),(2,871,6151,7379,1,''),(2,871,6152,1998,1,''),(2,871,6153,2002,1,''),(3,3,101,1987,1,''),(3,4,102,12810,1,'€\0\0description \0\0\0[+100 health]. Price: 5100 gold.\0priceì\0\0'),(3,101,103,7590,90,'Z€\0\0description\0\0\0\0\0price\n\0\0\0Unsellable'),(3,101,104,15014,61,'='),(4,3,101,1987,1,''),(4,4,102,2486,1,'€\0\0description\0\0\0Price: 520 gold.\0price\0\0'),(4,5,103,2152,8,''),(4,6,104,2392,1,'€\0\0description-\0\0\0The blade is a magic flame. Price: 4500 gold.\0price”\0\0'),(4,11,105,18434,1,''),(4,12,106,18435,1,''),(4,106,107,2148,55,'7'),(4,106,108,2148,100,'d'),(4,106,109,2148,100,'d'),(4,106,110,2148,100,'d'),(4,106,111,2148,100,'d'),(4,106,112,2148,100,'d'),(4,106,113,2148,100,'d'),(4,106,114,2148,100,'d'),(4,106,115,2148,100,'d'),(4,106,116,2148,100,'d'),(4,106,117,2148,100,'d'),(4,106,118,2148,100,'d'),(4,106,119,2148,100,'d'),(4,106,120,2148,100,'d'),(4,106,121,2148,100,'d'),(4,106,122,2148,100,'d'),(4,106,123,2148,100,'d'),(4,106,124,2148,100,'d'),(4,106,125,2148,100,'d'),(4,106,126,2148,100,'d'),(4,106,127,2148,100,'d'),(4,106,128,2148,100,'d'),(4,106,129,2148,100,'d'),(4,106,130,2148,100,'d'),(4,106,131,2148,100,'d'),(4,106,132,2148,100,'d'),(4,106,133,2148,100,'d'),(5,1,101,13118,1,'€\0\0description\0\0\0Price: 15000 gold.\0price˜:\0\0'),(5,2,102,13339,1,'€\0\0description\0\0\0Price: 5000 gold.\0priceˆ\0\0'),(5,3,103,1987,1,''),(5,5,104,13300,1,'€\0\0description\0\0\0Price: 12000 gold.\0priceà.\0\0'),(5,6,105,13895,1,'€\0\0description\0\0\0\0\0price\n\0\0\0Unsellable'),(5,10,106,2152,2,''),(5,12,107,18435,1,''),(5,107,108,2177,1,''),(5,107,109,2177,1,''),(5,107,110,2148,54,'6'),(5,107,111,2498,1,''),(5,107,112,2177,1,''),(5,107,113,2177,1,''),(5,107,114,2148,100,'d'),(5,107,115,2177,1,''),(5,107,116,2795,21,''),(5,107,117,2145,32,' '),(5,107,118,2148,100,'d'),(5,107,119,2148,100,'d'),(5,107,120,2148,100,'d'),(5,107,121,2148,100,'d'),(5,107,122,10522,1,''),(5,107,123,2148,100,'d'),(5,107,124,2148,100,'d'),(5,107,125,13300,1,''),(5,107,126,12689,1,''),(5,107,127,2148,100,'d'),(5,107,128,2148,100,'d'),(5,107,129,10522,1,''),(5,107,130,2148,100,'d'),(5,107,131,2148,100,'d'),(5,107,132,2148,100,'d'),(5,107,133,13300,1,''),(5,107,134,2129,1,''),(5,107,135,12862,1,'€\0\0description\0\0\0Price: 20000 gold.\0price N\0\0'),(5,107,136,2148,100,'d'),(5,107,137,2148,100,'d'),(5,107,138,10522,1,''),(5,107,139,2148,100,'d'),(5,107,140,2789,40,'('),(5,107,141,2148,100,'d'),(5,107,142,2148,100,'d'),(5,107,143,10522,1,''),(5,107,144,13300,1,'€\0\0description\0\0\0Price: 12000 gold.\0priceà.\0\0'),(5,107,145,2148,100,'d'),(5,107,146,2148,100,'d'),(5,107,147,12959,1,''),(5,107,148,2148,100,'d'),(5,107,149,10522,1,''),(5,107,150,2148,100,'d'),(5,107,151,2148,100,'d'),(5,107,152,13300,1,''),(5,107,153,2148,100,'d'),(5,107,154,13300,1,''),(5,107,155,2148,100,'d'),(5,107,156,2148,100,'d'),(5,107,157,2148,100,'d'),(5,107,158,10522,1,''),(5,107,159,2148,100,'d'),(5,107,160,13300,1,''),(5,107,161,2148,100,'d'),(5,107,162,10522,1,''),(5,107,163,2148,100,'d'),(5,107,164,2148,100,'d'),(5,107,165,2148,100,'d'),(5,107,166,13300,1,''),(5,107,167,10522,1,''),(5,107,168,2148,100,'d'),(5,107,169,18101,3,'€\0\0descriptione\0\0\0It enchants your equipment with +7 movement speed. Be careful, one equipment can only have one rune. \0price\n\0\0\0Unsellable'),(5,107,170,13339,1,''),(5,107,171,2148,100,'d'),(5,107,172,2148,100,'d'),(5,107,173,2148,100,'d'),(5,107,174,2152,57,'9'),(5,107,175,2789,100,'d'),(5,107,176,11192,3,''),(5,107,177,10609,31,''),(6,3,101,1987,1,'');
/*!40000 ALTER TABLE `player_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_killers`
--

DROP TABLE IF EXISTS `player_killers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_killers` (
  `kill_id` int(11) NOT NULL,
  `player_id` int(11) NOT NULL,
  KEY `kill_id` (`kill_id`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_killers_ibfk_1` FOREIGN KEY (`kill_id`) REFERENCES `killers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `player_killers_ibfk_2` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_killers`
--

LOCK TABLES `player_killers` WRITE;
/*!40000 ALTER TABLE `player_killers` DISABLE KEYS */;
/*!40000 ALTER TABLE `player_killers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_namelocks`
--

DROP TABLE IF EXISTS `player_namelocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_namelocks` (
  `player_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `new_name` varchar(255) NOT NULL,
  `date` bigint(20) NOT NULL DEFAULT 0,
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_namelocks_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_namelocks`
--

LOCK TABLES `player_namelocks` WRITE;
/*!40000 ALTER TABLE `player_namelocks` DISABLE KEYS */;
/*!40000 ALTER TABLE `player_namelocks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_skills`
--

DROP TABLE IF EXISTS `player_skills`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_skills` (
  `player_id` int(11) NOT NULL,
  `skillid` tinyint(2) NOT NULL DEFAULT 0,
  `value` int(10) unsigned NOT NULL DEFAULT 0,
  `count` int(10) unsigned NOT NULL DEFAULT 0,
  UNIQUE KEY `player_id_2` (`player_id`,`skillid`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_skills_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_skills`
--

LOCK TABLES `player_skills` WRITE;
/*!40000 ALTER TABLE `player_skills` DISABLE KEYS */;
INSERT INTO `player_skills` VALUES (2,0,10,0),(2,1,10,0),(2,2,10,0),(2,3,10,0),(2,4,10,0),(2,5,10,0),(2,6,10,0),(3,0,14,25),(3,1,10,2),(3,2,10,0),(3,3,10,0),(3,4,22,26),(3,5,11,82),(3,6,10,0),(4,0,13,37),(4,1,10,0),(4,2,11,30),(4,3,10,0),(4,4,11,30),(4,5,10,8),(4,6,10,0),(5,0,13,23),(5,1,10,42),(5,2,10,0),(5,3,11,30),(5,4,21,53),(5,5,10,48),(5,6,10,0),(6,0,12,11),(6,1,10,6),(6,2,10,0),(6,3,10,0),(6,4,22,88),(6,5,12,102),(6,6,10,0);
/*!40000 ALTER TABLE `player_skills` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_spells`
--

DROP TABLE IF EXISTS `player_spells`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_spells` (
  `player_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  UNIQUE KEY `player_id_2` (`player_id`,`name`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_spells_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_spells`
--

LOCK TABLES `player_spells` WRITE;
/*!40000 ALTER TABLE `player_spells` DISABLE KEYS */;
/*!40000 ALTER TABLE `player_spells` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_statements`
--

DROP TABLE IF EXISTS `player_statements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_statements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `channel_id` int(11) NOT NULL DEFAULT 0,
  `text` varchar(255) NOT NULL,
  `date` bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `player_id` (`player_id`),
  KEY `channel_id` (`channel_id`),
  CONSTRAINT `player_statements_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_statements`
--

LOCK TABLES `player_statements` WRITE;
/*!40000 ALTER TABLE `player_statements` DISABLE KEYS */;
/*!40000 ALTER TABLE `player_statements` ENABLE KEYS */;
UNLOCK TABLES;

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
INSERT INTO `player_storage` VALUES (1,'10001501','65539'),(2,'0','7'),(2,'100079','5'),(2,'1150001','1786754390'),(2,'188100','477'),(2,'31851','1786683972'),(2,'40250','1'),(2,'42001','1'),(2,'45001','2'),(2,'45002','0'),(2,'45003','1'),(2,'45900','1'),(2,'49150','1'),(2,'49151','23'),(2,'49160','1'),(2,'49161','0'),(2,'49170','2'),(2,'49171','1'),(2,'49190','1'),(2,'63719','1'),(2,'920009','1'),(2,'920101','1'),(2,'920102','1'),(2,'920103','1'),(2,'9701','0'),(2,'9702','0'),(2,'9703','0'),(2,'9704','0'),(2,'9705','0'),(2,'9706','0'),(2,'9707','0'),(2,'9708','0'),(2,'9709','0'),(2,'9710','0'),(2,'9711','0'),(2,'9712','0'),(2,'9713','0'),(2,'9714','0'),(2,'9715','0'),(2,'9716','0'),(2,'9717','0'),(2,'9718','0'),(2,'9719','0'),(2,'9720','0'),(2,'9721','0'),(2,'9722','0'),(2,'9723','0'),(2,'9724','0'),(2,'9725','0'),(2,'9726','0'),(2,'9727','0'),(2,'9728','0'),(2,'9729','0'),(2,'9730','0'),(2,'9731','0'),(2,'9740','1786244760'),(2,'9741','8'),(2,'9999','1786240808'),(3,'10001501','1048579'),(3,'1150001','1786605529'),(3,'188100','20'),(3,'42001','1'),(3,'9701','0'),(3,'9702','0'),(3,'9703','0'),(3,'9704','0'),(3,'9705','0'),(3,'9706','0'),(3,'9707','0'),(3,'9708','0'),(3,'9709','0'),(3,'9710','0'),(3,'9711','0'),(3,'9712','0'),(3,'9713','0'),(3,'9714','0'),(3,'9715','0'),(3,'9716','0'),(3,'9717','0'),(3,'9718','0'),(3,'9719','0'),(3,'9720','0'),(3,'9721','0'),(3,'9722','0'),(3,'9723','0'),(3,'9724','0'),(3,'9725','0'),(3,'9726','0'),(3,'9727','0'),(3,'9728','0'),(3,'9729','0'),(3,'9730','0'),(3,'9731','0'),(3,'9740','1786241309'),(3,'9741','8'),(3,'9999','1786069901'),(3,'AirBarrierReduction','1786605845'),(3,'antiloop','-1'),(3,'autolootdesativo','1'),(3,'avatarAtkExh','1786605921'),(3,'AvatarMode','1786605845'),(3,'avatarProtec','1786605870'),(3,'bendvalue','21'),(3,'bombermanInQueue','-1'),(3,'canPotion','1'),(3,'cantEarthArmor','1786605940'),(3,'canturecover','1786605946'),(3,'currentCid','268437073'),(3,'currentFold','earth recover'),(3,'DailyHunt_Claimed_2','0'),(3,'DailyHunt_Claimed_5','0'),(3,'DailyHunt_Day','dy1030'),(3,'DailyHunt_Kill_1','0'),(3,'DailyHunt_Kill_2','0'),(3,'DailyHunt_Kill_3','0'),(3,'DailyHunt_Kill_4','0'),(3,'DailyHunt_Kill_5','0'),(3,'DailyHunt_Monster_1','bone beast'),(3,'DailyHunt_Monster_2','snake'),(3,'DailyHunt_Monster_3','crystal golem'),(3,'DailyHunt_Monster_4','noble lion'),(3,'DailyHunt_Monster_5','colerian the barbarian'),(3,'dailyTaskColdown','1786059330'),(3,'dodgevalue','0'),(3,'entroumontado','-1'),(3,'exaustedearthcrush','1786605920'),(3,'exaustedearthfury','1786605800'),(3,'exaustedearthgrowth','1786605929'),(3,'exaustedearthjump','1786237111'),(3,'exaustedearthleech','1786605940'),(3,'exaustedearthpull','1786605925'),(3,'exaustedearthpunch','1786605918'),(3,'exaustedearthrecover','1786605946'),(3,'exaustedearthrock','1786605918'),(3,'expBeforeDie','-1'),(3,'getAwnserAntiBot','-1'),(3,'getCompletedDailydy110','0'),(3,'getCompletedDailydy130','0'),(3,'getCompletedDailydy160','0'),(3,'getCompletedDailydy170','0'),(3,'getCompletedDailydy180','0'),(3,'getCompletedDailydy280','0'),(3,'getCompletedDailydy290','0'),(3,'getCompletedDailydy370','0'),(3,'getCompletedDailydy390','0'),(3,'getCompletedDailydy410','0'),(3,'getCompletedDailydy420','0'),(3,'getCompletedDailydy430','0'),(3,'getCompletedDailydy440','0'),(3,'getCompletedDailydy560','0'),(3,'getCompletedDailydy680','0'),(3,'getCompletedDailydy690','0'),(3,'getCompletedDailydy720','0'),(3,'getCompletedDailydy750','0'),(3,'getCompletedDailydy760','0'),(3,'getCompletedDailydy80','0'),(3,'getPlayerLang','isEnglish'),(3,'getPointsInDodge','0'),(3,'getTurnMsgPoints','1'),(3,'hasBuyearth leech','1'),(3,'hasPassiveDeathActive','1786239653'),(3,'healthBeforePotion','3310'),(3,'healthvalue','2'),(3,'isAvatar','1'),(3,'isInDailyTask','0'),(3,'jamudouroupa','1'),(3,'knockoutAttackers',''),(3,'knockoutOldLevel','19'),(3,'lastGlobalSaveLogin','6'),(3,'lastHit','1073743436'),(3,'marketCheck','1786606113'),(3,'morreuD','-1'),(3,'npodedeslogar','1786605534'),(3,'onMoveFlyPosX','511'),(3,'onMoveFlyPosY','360'),(3,'onMoveFlyPosZ','7'),(3,'pendentes','0'),(3,'playerCanMoveDirection','0'),(3,'playerCantDown','-1'),(3,'playerHasGetInitialItens','1'),(3,'playerHasStun','1786236659'),(3,'playerOnAir','-1'),(3,'playerWithBless','-1'),(3,'speedvalue','0'),(3,'spiritualTotem_18193','1'),(3,'startedWithMana','1'),(3,'taskInCourse1','2'),(3,'taskInCourse1npcName','Don Corleone'),(3,'taskInCourse2','1'),(3,'taskInCourse27','1'),(3,'taskInCourse27npcName','Don Corleone'),(3,'taskInCourse2npcName','Don Corleone'),(3,'taskInCourse4','1'),(3,'taskInCourse48','1'),(3,'taskInCourse48npcName','Don Corleone'),(3,'taskInCourse49','1'),(3,'taskInCourse49npcName','Don Corleone'),(3,'taskInCourse4npcName','Don Corleone'),(3,'taskInCourse90','1'),(3,'taskInCourse90npcName','Don Corleone'),(3,'taskInCourse91','1'),(3,'taskInCourse91npcName','Don Corleone'),(3,'taskInCourseGetMonsters1','25'),(3,'TimeDailyDois','0'),(3,'TimeDailyQuatro','0'),(3,'TimeDailyTres','0'),(3,'TimeDailyUm','0'),(3,'timeLogin','1786605529'),(4,'10001501','65539'),(4,'1150001','1786663240'),(4,'188100','61'),(4,'42001','1'),(4,'9701','0'),(4,'9702','0'),(4,'9703','0'),(4,'9704','0'),(4,'9705','0'),(4,'9706','0'),(4,'9707','0'),(4,'9708','0'),(4,'9709','0'),(4,'9710','0'),(4,'9711','0'),(4,'9712','0'),(4,'9713','0'),(4,'9714','0'),(4,'9715','0'),(4,'9716','0'),(4,'9717','0'),(4,'9718','0'),(4,'9719','0'),(4,'9720','0'),(4,'9721','0'),(4,'9722','0'),(4,'9723','0'),(4,'9724','0'),(4,'9725','0'),(4,'9726','0'),(4,'9727','0'),(4,'9728','0'),(4,'9729','0'),(4,'9730','0'),(4,'9731','0'),(4,'9740','1786174847'),(4,'9741','8'),(4,'AirBarrierReduction','1786605270'),(4,'antiloop','-1'),(4,'autolootdesativo','1'),(4,'avatarAtkExh','1786605269'),(4,'AvatarMode','1786605270'),(4,'avatarProtec','1786605295'),(4,'bendvalue','6'),(4,'blessExp','-1'),(4,'blessExpName','Sony'),(4,'bombermanInQueue','-1'),(4,'canturecover','1786605272'),(4,'currentCid','268437067'),(4,'currentFold','fire bolt'),(4,'DailyHunt_Claimed_2','0'),(4,'DailyHunt_Claimed_5','0'),(4,'DailyHunt_Day','dy1050'),(4,'DailyHunt_Kill_1','0'),(4,'DailyHunt_Kill_2','0'),(4,'DailyHunt_Kill_3','0'),(4,'DailyHunt_Kill_4','0'),(4,'DailyHunt_Kill_5','0'),(4,'DailyHunt_Monster_1','crawler'),(4,'DailyHunt_Monster_2','wolf'),(4,'DailyHunt_Monster_3','dragonling'),(4,'DailyHunt_Monster_4','fire res'),(4,'DailyHunt_Monster_5','insectoid scout'),(4,'dailyTaskColdown','1786174847'),(4,'entroumontado','-1'),(4,'exaustedfirebolt','1786605273'),(4,'exaustedfirecannon','1786599416'),(4,'exaustedfireimpulse','1786481414'),(4,'exaustedfirekick','1786605267'),(4,'exaustedfirerecover','1786605272'),(4,'exaustedfireres','1786605317'),(4,'exaustedfireskyfall','1786605271'),(4,'exaustedfirestar','1786604477'),(4,'exaustedfirewhip','1786599183'),(4,'exaustedfirewrath','1786599162'),(4,'expBeforeDie','-1'),(4,'fireoverPower','0'),(4,'firstPendentes','1'),(4,'getAwnserAntiBot','-1'),(4,'getCompletedDailydy570','0'),(4,'getCompletedDailydy580','0'),(4,'getCompletedDailydy590','0'),(4,'getCompletedDailydy600','0'),(4,'getCompletedDailydy610','0'),(4,'getCompletedDailydy730','0'),(4,'getPlayerLang','isEnglish'),(4,'getPointsInDodge','0'),(4,'getTurnMsgPoints','1'),(4,'hasPassiveDeathActive','1786609579'),(4,'healthvalue','16'),(4,'isAvatar','0'),(4,'isInDailyTask','0'),(4,'knockoutAttackers',''),(4,'knockoutOldLevel','60'),(4,'lastGlobalSaveLogin','6'),(4,'lastHit','1073743411'),(4,'marketCheck','1786663270'),(4,'morreuD','-1'),(4,'npodedeslogar','1786663245'),(4,'onMoveFlyPosX','514'),(4,'onMoveFlyPosY','358'),(4,'onMoveFlyPosZ','7'),(4,'pendentes','32'),(4,'playerCanMoveDirection','0'),(4,'playerHasGetInitialItens','1'),(4,'playerOnAir','-1'),(4,'playerWithBless','-1'),(4,'pvpLevelMessage','1'),(4,'startedWithMana','1'),(4,'taskInCourse1','1'),(4,'taskInCourse12','1'),(4,'taskInCourse12npcName','Don Corleone'),(4,'taskInCourse13','1'),(4,'taskInCourse13npcName','Don Corleone'),(4,'taskInCourse1npcName','Don Corleone'),(4,'taskInCourse2','1'),(4,'taskInCourse21','1'),(4,'taskInCourse21npcName','Don Corleone'),(4,'taskInCourse27','1'),(4,'taskInCourse27npcName','Don Corleone'),(4,'taskInCourse28','1'),(4,'taskInCourse28npcName','Don Corleone'),(4,'taskInCourse2npcName','Don Corleone'),(4,'taskInCourse3','1'),(4,'taskInCourse30','1'),(4,'taskInCourse30npcName','Don Corleone'),(4,'taskInCourse3npcName','Don Corleone'),(4,'taskInCourse4','1'),(4,'taskInCourse40','1'),(4,'taskInCourse40npcName','Don Corleone'),(4,'taskInCourse48','1'),(4,'taskInCourse48npcName','Don Corleone'),(4,'taskInCourse49','1'),(4,'taskInCourse49npcName','Don Corleone'),(4,'taskInCourse4npcName','Don Corleone'),(4,'taskInCourse7','1'),(4,'taskInCourse7npcName','Don Corleone'),(4,'taskInCourse90','1'),(4,'taskInCourse90npcName','Don Corleone'),(4,'taskInCourse91','1'),(4,'taskInCourse91npcName','Don Corleone'),(4,'TimeDailyDois','0'),(4,'TimeDailyQuatro','0'),(4,'TimeDailyTres','0'),(4,'TimeDailyUm','0'),(4,'timeLogin','1786663240'),(5,'10001501','720899'),(5,'10001502','3407872'),(5,'1150001','1786611286'),(5,'188100','22'),(5,'42001','1'),(5,'9701','0'),(5,'9702','0'),(5,'9703','0'),(5,'9704','0'),(5,'9705','0'),(5,'9706','0'),(5,'9707','0'),(5,'9708','0'),(5,'9709','0'),(5,'9710','0'),(5,'9711','0'),(5,'9712','0'),(5,'9713','0'),(5,'9714','0'),(5,'9715','0'),(5,'9716','0'),(5,'9717','0'),(5,'9718','0'),(5,'9719','0'),(5,'9720','0'),(5,'9721','0'),(5,'9722','0'),(5,'9723','0'),(5,'9724','0'),(5,'9725','0'),(5,'9726','0'),(5,'9727','0'),(5,'9728','0'),(5,'9729','0'),(5,'9730','0'),(5,'9731','0'),(5,'9740','1786241108'),(5,'9741','8'),(5,'AirBarrierReduction','1786393400'),(5,'antiloop','-1'),(5,'autolootdesativo','1'),(5,'avatarAtkExh','1786393292'),(5,'AvatarMode','1786393400'),(5,'avatarProtec','1786393425'),(5,'bendvalue','10'),(5,'bombermanActiveBombs','0'),(5,'bombermanArena','-1'),(5,'bombermanBombSize','1'),(5,'bombermanInMatch','-1'),(5,'bombermanInQueue','-1'),(5,'bombermanKick','0'),(5,'bombermanMatchStart','-1'),(5,'bombermanMaxBombs','1'),(5,'bombermanOutfitAddons','0'),(5,'bombermanOutfitBody','0'),(5,'bombermanOutfitEx','0'),(5,'bombermanOutfitFeet','0'),(5,'bombermanOutfitHead','0'),(5,'bombermanOutfitLegs','0'),(5,'bombermanOutfitMount','0'),(5,'bombermanOutfitType','0'),(5,'bombermanPartner','-1'),(5,'bombermanSavedSpeed','0'),(5,'bombermanSpeed','1'),(5,'bombermanSpeedDelta','0'),(5,'canturecover','1786394063'),(5,'currentCid','268437027'),(5,'currentFold','air recover'),(5,'DailyHunt_Claimed_2','0'),(5,'DailyHunt_Claimed_5','0'),(5,'DailyHunt_Day','dy1040'),(5,'DailyHunt_Kill_1','0'),(5,'DailyHunt_Kill_2','0'),(5,'DailyHunt_Kill_3','0'),(5,'DailyHunt_Kill_4','0'),(5,'DailyHunt_Kill_5','0'),(5,'DailyHunt_Monster_1','slick water elemental'),(5,'DailyHunt_Monster_2','pirate skeleton'),(5,'DailyHunt_Monster_3','mimic'),(5,'DailyHunt_Monster_4','sand dragon'),(5,'DailyHunt_Monster_5','black sheep'),(5,'dailyTaskColdown','1786142222'),(5,'entroumontado','-1'),(5,'exaustedairball','1786393073'),(5,'exaustedairboost','1786392328'),(5,'exaustedairburst','1786394046'),(5,'exaustedairfan','1786394083'),(5,'exaustedairgale','1786394061'),(5,'exaustedairjump','1786392858'),(5,'exaustedairrecover','1786394063'),(5,'exaustedairrun','1786393326'),(5,'exaustedairwings','1786394062'),(5,'expBeforeDie','-1'),(5,'firstPendentes','1'),(5,'getAwnserAntiBot','-1'),(5,'getCompletedDailydy570','0'),(5,'getCompletedDailydy580','0'),(5,'getCompletedDailydy590','0'),(5,'getCompletedDailydy600','0'),(5,'getCompletedDailydy610','0'),(5,'getCompletedDailydy720','0'),(5,'getCompletedDailydy750','0'),(5,'getCompletedDailydy760','0'),(5,'getPlayerLang','isEnglish'),(5,'getPointsInDodge','0'),(5,'getTurnMsgPoints','1'),(5,'hasPassiveDeathActive','1786403299'),(5,'healthvalue','5'),(5,'isAvatar','1'),(5,'isInDailyTask','0'),(5,'jamudouroupa','1'),(5,'knockoutAttackers',''),(5,'knockoutOldLevel','546'),(5,'lastGlobalSaveLogin','6'),(5,'lastHit','1073753154'),(5,'marketCheck','1786611392'),(5,'momoactive','1'),(5,'momoitem_12540','1'),(5,'momoitem_3384','0'),(5,'momoitem_3413','0'),(5,'morreuD','-1'),(5,'npodedeslogar','1786611291'),(5,'onMoveFlyPosX','514'),(5,'onMoveFlyPosY','350'),(5,'onMoveFlyPosZ','7'),(5,'pendentes','0'),(5,'playerCanMoveDirection','0'),(5,'playerCantDown','-1'),(5,'playerHasGetInitialItens','1'),(5,'playerOnAir','-1'),(5,'playerWithBless','-1'),(5,'pointsUsedInLifeCrystal','2'),(5,'startedWithMana','1'),(5,'stopDashs','1785874840'),(5,'taskInCourse1','1'),(5,'taskInCourse1npcName','Don Corleone'),(5,'taskInCourse2','1'),(5,'taskInCourse27','1'),(5,'taskInCourse27npcName','Don Corleone'),(5,'taskInCourse28','1'),(5,'taskInCourse28npcName','Don Corleone'),(5,'taskInCourse2npcName','Don Corleone'),(5,'taskInCourse4','1'),(5,'taskInCourse40','1'),(5,'taskInCourse40npcName','Don Corleone'),(5,'taskInCourse48','1'),(5,'taskInCourse48npcName','Don Corleone'),(5,'taskInCourse49','1'),(5,'taskInCourse49npcName','Don Corleone'),(5,'taskInCourse4npcName','Don Corleone'),(5,'taskInCourse90','1'),(5,'taskInCourse90npcName','Don Corleone'),(5,'taskInCourse91','1'),(5,'taskInCourse91npcName','Don Corleone'),(5,'taskInCourseGetMonsters1','7'),(5,'taskInCourseGetMonsters2','10'),(5,'TimeDailyDois','0'),(5,'TimeDailyQuatro','0'),(5,'TimeDailyTres','0'),(5,'TimeDailyUm','0'),(5,'timeLogin','1786611286'),(6,'10001501','65539'),(6,'1150001','1786570793'),(6,'188100','27'),(6,'42001','1'),(6,'49170','1'),(6,'9701','0'),(6,'9702','0'),(6,'9703','0'),(6,'9704','0'),(6,'9705','0'),(6,'9706','0'),(6,'9707','0'),(6,'9708','0'),(6,'9709','0'),(6,'9710','0'),(6,'9711','0'),(6,'9712','0'),(6,'9713','0'),(6,'9714','0'),(6,'9715','0'),(6,'9716','0'),(6,'9717','0'),(6,'9718','0'),(6,'9719','0'),(6,'9720','0'),(6,'9721','0'),(6,'9722','0'),(6,'9723','0'),(6,'9724','0'),(6,'9725','0'),(6,'9726','0'),(6,'9727','0'),(6,'9728','0'),(6,'9729','0'),(6,'9730','0'),(6,'9731','0'),(6,'9740','1786219803'),(6,'9741','8'),(6,'autolootdesativo','1'),(6,'bendvalue','19'),(6,'bombermanActiveBombs','0'),(6,'bombermanArena','-1'),(6,'bombermanBombSize','1'),(6,'bombermanInMatch','-1'),(6,'bombermanInQueue','-1'),(6,'bombermanKick','0'),(6,'bombermanMaxBombs','1'),(6,'bombermanSpeed','1'),(6,'bombermanSpeedDelta','0'),(6,'canturecover','1786500450'),(6,'currentCid','268436950'),(6,'currentFold','fire recover'),(6,'DailyHunt_Claimed_2','0'),(6,'DailyHunt_Claimed_5','0'),(6,'DailyHunt_Day','dy1000'),(6,'DailyHunt_Kill_1','0'),(6,'DailyHunt_Kill_2','0'),(6,'DailyHunt_Kill_3','0'),(6,'DailyHunt_Kill_4','0'),(6,'DailyHunt_Kill_5','0'),(6,'DailyHunt_Monster_1','orc shaman'),(6,'DailyHunt_Monster_2','evil avatar'),(6,'DailyHunt_Monster_3','red butterfly'),(6,'DailyHunt_Monster_4','grorlam'),(6,'DailyHunt_Monster_5','massive earth elemental'),(6,'dailyTaskColdown','1786070249'),(6,'entroumontado','-1'),(6,'exaustedfirebolt','1786220082'),(6,'exaustedfireimpulse','1786220062'),(6,'exaustedfirekick','1786500444'),(6,'exaustedfirerecover','1786500450'),(6,'exaustedfireskyfall','1786500449'),(6,'exaustedfirewhip','1786500450'),(6,'expBeforeDie','-1'),(6,'fireoverPower','0'),(6,'firstPendentes','1'),(6,'getAwnserAntiBot','-1'),(6,'getCompletedDailydy690','0'),(6,'getCompletedDailydy700','0'),(6,'getCompletedDailydy720','0'),(6,'getCompletedDailydy750','0'),(6,'getPlayerLang','isEnglish'),(6,'getPointsInDodge','0'),(6,'getTurnMsgPoints','1'),(6,'hasPassiveDeathActive','1786511159'),(6,'isAvatar','0'),(6,'isInDailyTask','0'),(6,'jamudouroupa','1'),(6,'knockoutAttackers',''),(6,'knockoutOldLevel','27'),(6,'lastGlobalSaveLogin','6'),(6,'lastHit','1073743066'),(6,'marketCheck','1786571729'),(6,'morreuD','-1'),(6,'npodedeslogar','1786570798'),(6,'onMoveFlyPosX','446'),(6,'onMoveFlyPosY','342'),(6,'onMoveFlyPosZ','7'),(6,'pendentes','1'),(6,'playerCanMoveDirection','0'),(6,'playerHasGetInitialItens','1'),(6,'playerOnAir','-1'),(6,'playerWithBless','-1'),(6,'questChests25455','1'),(6,'startedWithMana','1'),(6,'taskInCourse1','2'),(6,'taskInCourse12','1'),(6,'taskInCourse12npcName','Don Corleone'),(6,'taskInCourse1npcName','Don Corleone'),(6,'taskInCourse2','1'),(6,'taskInCourse27','1'),(6,'taskInCourse27npcName','Don Corleone'),(6,'taskInCourse28','1'),(6,'taskInCourse28npcName','Don Corleone'),(6,'taskInCourse2npcName','Don Corleone'),(6,'taskInCourse3','1'),(6,'taskInCourse3npcName','Don Corleone'),(6,'taskInCourse4','1'),(6,'taskInCourse40','1'),(6,'taskInCourse40npcName','Don Corleone'),(6,'taskInCourse48','1'),(6,'taskInCourse48npcName','Don Corleone'),(6,'taskInCourse49','1'),(6,'taskInCourse49npcName','Don Corleone'),(6,'taskInCourse4npcName','Don Corleone'),(6,'taskInCourse7','1'),(6,'taskInCourse7npcName','Don Corleone'),(6,'taskInCourse90','1'),(6,'taskInCourse90npcName','Don Corleone'),(6,'taskInCourse91','1'),(6,'taskInCourse91npcName','Don Corleone'),(6,'taskInCourseGetMonsters1','25'),(6,'taskInCourseGetMonsters2','12'),(6,'taskInCourseGetMonsters4','4'),(6,'TimeDailyDois','0'),(6,'TimeDailyQuatro','0'),(6,'TimeDailyTres','0'),(6,'TimeDailyUm','0'),(6,'timeLogin','1786570793');
/*!40000 ALTER TABLE `player_storage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_storeinboxitems`
--

DROP TABLE IF EXISTS `player_storeinboxitems`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_storeinboxitems` (
  `player_id` int(11) NOT NULL,
  `sid` int(11) NOT NULL,
  `pid` int(11) NOT NULL DEFAULT 0,
  `itemtype` smallint(5) unsigned NOT NULL,
  `count` smallint(6) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL,
  UNIQUE KEY `player_id_2` (`player_id`,`sid`),
  CONSTRAINT `player_storeinboxitems_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_storeinboxitems`
--

LOCK TABLES `player_storeinboxitems` WRITE;
/*!40000 ALTER TABLE `player_storeinboxitems` DISABLE KEYS */;
/*!40000 ALTER TABLE `player_storeinboxitems` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_string_storage`
--

DROP TABLE IF EXISTS `player_string_storage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_string_storage` (
  `player_id` int(11) NOT NULL,
  `key` varchar(255) NOT NULL,
  `value` text NOT NULL,
  UNIQUE KEY `player_id_2` (`player_id`,`key`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `player_string_storage_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_string_storage`
--

LOCK TABLES `player_string_storage` WRITE;
/*!40000 ALTER TABLE `player_string_storage` DISABLE KEYS */;
INSERT INTO `player_string_storage` VALUES (2,'1150001','1786805514'),(2,'188100','477'),(2,'42001','1'),(2,'bombermanInQueue','-1'),(2,'currentCid','0'),(2,'DailyHunt_Claimed_2','0'),(2,'DailyHunt_Claimed_5','0'),(2,'DailyHunt_Day','dy22026'),(2,'DailyHunt_Kill_1','0'),(2,'DailyHunt_Kill_2','0'),(2,'DailyHunt_Kill_3','0'),(2,'DailyHunt_Kill_4','0'),(2,'DailyHunt_Kill_5','0'),(2,'DailyHunt_Monster_1','terra beetle'),(2,'DailyHunt_Monster_2','pica-pau da terra'),(2,'DailyHunt_Monster_3','joaninha da terra'),(2,'DailyHunt_Monster_4','cockroach'),(2,'DailyHunt_Monster_5','abelha de barro'),(2,'expBeforeDie','-1'),(2,'firstPendentes','1'),(2,'getAwnserAntiBot','-1'),(2,'getPlayerLang','isEnglish'),(2,'getPointsInDodge','0'),(2,'isAvatar','0'),(2,'marketCheck','1786805573'),(2,'npodedeslogar','1786805518'),(2,'onMoveFlyPosX','500'),(2,'onMoveFlyPosY','353'),(2,'onMoveFlyPosZ','7'),(2,'pendentes','1'),(2,'playerCanMoveDirection','0'),(2,'playerHasGetInitialItens','1'),(2,'startedWithMana','1'),(2,'timeLogin','1786805513'),(3,'AirBarrierReduction','1786605845'),(3,'antiloop','-1'),(3,'autolootdesativo','1'),(3,'avatarAtkExh','1786605921'),(3,'AvatarMode','1786605845'),(3,'avatarProtec','1786605870'),(3,'bendvalue','21'),(3,'bombermanInQueue','-1'),(3,'canPotion','1'),(3,'cantEarthArmor','1786605940'),(3,'canturecover','1786605946'),(3,'currentCid','268437073'),(3,'currentFold','earth recover'),(3,'DailyHunt_Claimed_2','0'),(3,'DailyHunt_Claimed_5','0'),(3,'DailyHunt_Day','dy1030'),(3,'DailyHunt_Kill_1','0'),(3,'DailyHunt_Kill_2','0'),(3,'DailyHunt_Kill_3','0'),(3,'DailyHunt_Kill_4','0'),(3,'DailyHunt_Kill_5','0'),(3,'DailyHunt_Monster_1','bone beast'),(3,'DailyHunt_Monster_2','snake'),(3,'DailyHunt_Monster_3','crystal golem'),(3,'DailyHunt_Monster_4','noble lion'),(3,'DailyHunt_Monster_5','colerian the barbarian'),(3,'dailyTaskColdown','1786059330'),(3,'dodgevalue','0'),(3,'entroumontado','-1'),(3,'exaustedearthcrush','1786605920'),(3,'exaustedearthfury','1786605800'),(3,'exaustedearthgrowth','1786605929'),(3,'exaustedearthjump','1786237111'),(3,'exaustedearthleech','1786605940'),(3,'exaustedearthpull','1786605925'),(3,'exaustedearthpunch','1786605918'),(3,'exaustedearthrecover','1786605946'),(3,'exaustedearthrock','1786605918'),(3,'expBeforeDie','-1'),(3,'getAwnserAntiBot','-1'),(3,'getCompletedDailydy110','0'),(3,'getCompletedDailydy130','0'),(3,'getCompletedDailydy160','0'),(3,'getCompletedDailydy170','0'),(3,'getCompletedDailydy180','0'),(3,'getCompletedDailydy280','0'),(3,'getCompletedDailydy290','0'),(3,'getCompletedDailydy370','0'),(3,'getCompletedDailydy390','0'),(3,'getCompletedDailydy410','0'),(3,'getCompletedDailydy420','0'),(3,'getCompletedDailydy430','0'),(3,'getCompletedDailydy440','0'),(3,'getCompletedDailydy560','0'),(3,'getCompletedDailydy680','0'),(3,'getCompletedDailydy690','0'),(3,'getCompletedDailydy720','0'),(3,'getCompletedDailydy750','0'),(3,'getCompletedDailydy760','0'),(3,'getCompletedDailydy80','0'),(3,'getPlayerLang','isEnglish'),(3,'getPointsInDodge','0'),(3,'getTurnMsgPoints','1'),(3,'hasBuyearth leech','1'),(3,'hasPassiveDeathActive','1786239653'),(3,'healthBeforePotion','3310'),(3,'healthvalue','2'),(3,'isAvatar','1'),(3,'isInDailyTask','0'),(3,'jamudouroupa','1'),(3,'knockoutAttackers',''),(3,'knockoutOldLevel','19'),(3,'lastGlobalSaveLogin','6'),(3,'lastHit','1073743436'),(3,'marketCheck','1786606113'),(3,'morreuD','-1'),(3,'npodedeslogar','1786605534'),(3,'onMoveFlyPosX','511'),(3,'onMoveFlyPosY','360'),(3,'onMoveFlyPosZ','7'),(3,'pendentes','0'),(3,'playerCanMoveDirection','0'),(3,'playerCantDown','-1'),(3,'playerHasGetInitialItens','1'),(3,'playerHasStun','1786236659'),(3,'playerOnAir','-1'),(3,'playerWithBless','-1'),(3,'speedvalue','0'),(3,'spiritualTotem_18193','1'),(3,'startedWithMana','1'),(3,'taskInCourse1','2'),(3,'taskInCourse1npcName','Don Corleone'),(3,'taskInCourse2','1'),(3,'taskInCourse27','1'),(3,'taskInCourse27npcName','Don Corleone'),(3,'taskInCourse2npcName','Don Corleone'),(3,'taskInCourse4','1'),(3,'taskInCourse48','1'),(3,'taskInCourse48npcName','Don Corleone'),(3,'taskInCourse49','1'),(3,'taskInCourse49npcName','Don Corleone'),(3,'taskInCourse4npcName','Don Corleone'),(3,'taskInCourse90','1'),(3,'taskInCourse90npcName','Don Corleone'),(3,'taskInCourse91','1'),(3,'taskInCourse91npcName','Don Corleone'),(3,'taskInCourseGetMonsters1','25'),(3,'TimeDailyDois','0'),(3,'TimeDailyQuatro','0'),(3,'TimeDailyTres','0'),(3,'TimeDailyUm','0'),(3,'timeLogin','1786605529'),(4,'AirBarrierReduction','1786605270'),(4,'antiloop','-1'),(4,'autolootdesativo','1'),(4,'avatarAtkExh','1786605269'),(4,'AvatarMode','1786605270'),(4,'avatarProtec','1786605295'),(4,'bendvalue','6'),(4,'blessExp','-1'),(4,'blessExpName','Sony'),(4,'bombermanInQueue','-1'),(4,'canturecover','1786605272'),(4,'currentCid','268437067'),(4,'currentFold','fire bolt'),(4,'DailyHunt_Claimed_2','0'),(4,'DailyHunt_Claimed_5','0'),(4,'DailyHunt_Day','dy1050'),(4,'DailyHunt_Kill_1','0'),(4,'DailyHunt_Kill_2','0'),(4,'DailyHunt_Kill_3','0'),(4,'DailyHunt_Kill_4','0'),(4,'DailyHunt_Kill_5','0'),(4,'DailyHunt_Monster_1','crawler'),(4,'DailyHunt_Monster_2','wolf'),(4,'DailyHunt_Monster_3','dragonling'),(4,'DailyHunt_Monster_4','fire res'),(4,'DailyHunt_Monster_5','insectoid scout'),(4,'dailyTaskColdown','1786174847'),(4,'entroumontado','-1'),(4,'exaustedfirebolt','1786605273'),(4,'exaustedfirecannon','1786599416'),(4,'exaustedfireimpulse','1786481414'),(4,'exaustedfirekick','1786605267'),(4,'exaustedfirerecover','1786605272'),(4,'exaustedfireres','1786605317'),(4,'exaustedfireskyfall','1786605271'),(4,'exaustedfirestar','1786604477'),(4,'exaustedfirewhip','1786599183'),(4,'exaustedfirewrath','1786599162'),(4,'expBeforeDie','-1'),(4,'fireoverPower','0'),(4,'firstPendentes','1'),(4,'getAwnserAntiBot','-1'),(4,'getCompletedDailydy570','0'),(4,'getCompletedDailydy580','0'),(4,'getCompletedDailydy590','0'),(4,'getCompletedDailydy600','0'),(4,'getCompletedDailydy610','0'),(4,'getCompletedDailydy730','0'),(4,'getPlayerLang','isEnglish'),(4,'getPointsInDodge','0'),(4,'getTurnMsgPoints','1'),(4,'hasPassiveDeathActive','1786609579'),(4,'healthvalue','16'),(4,'isAvatar','0'),(4,'isInDailyTask','0'),(4,'knockoutAttackers',''),(4,'knockoutOldLevel','60'),(4,'lastGlobalSaveLogin','6'),(4,'lastHit','1073743411'),(4,'marketCheck','1786663270'),(4,'morreuD','-1'),(4,'npodedeslogar','1786663245'),(4,'onMoveFlyPosX','514'),(4,'onMoveFlyPosY','358'),(4,'onMoveFlyPosZ','7'),(4,'pendentes','32'),(4,'playerCanMoveDirection','0'),(4,'playerHasGetInitialItens','1'),(4,'playerOnAir','-1'),(4,'playerWithBless','-1'),(4,'pvpLevelMessage','1'),(4,'startedWithMana','1'),(4,'taskInCourse1','1'),(4,'taskInCourse12','1'),(4,'taskInCourse12npcName','Don Corleone'),(4,'taskInCourse13','1'),(4,'taskInCourse13npcName','Don Corleone'),(4,'taskInCourse1npcName','Don Corleone'),(4,'taskInCourse2','1'),(4,'taskInCourse21','1'),(4,'taskInCourse21npcName','Don Corleone'),(4,'taskInCourse27','1'),(4,'taskInCourse27npcName','Don Corleone'),(4,'taskInCourse28','1'),(4,'taskInCourse28npcName','Don Corleone'),(4,'taskInCourse2npcName','Don Corleone'),(4,'taskInCourse3','1'),(4,'taskInCourse30','1'),(4,'taskInCourse30npcName','Don Corleone'),(4,'taskInCourse3npcName','Don Corleone'),(4,'taskInCourse4','1'),(4,'taskInCourse40','1'),(4,'taskInCourse40npcName','Don Corleone'),(4,'taskInCourse48','1'),(4,'taskInCourse48npcName','Don Corleone'),(4,'taskInCourse49','1'),(4,'taskInCourse49npcName','Don Corleone'),(4,'taskInCourse4npcName','Don Corleone'),(4,'taskInCourse7','1'),(4,'taskInCourse7npcName','Don Corleone'),(4,'taskInCourse90','1'),(4,'taskInCourse90npcName','Don Corleone'),(4,'taskInCourse91','1'),(4,'taskInCourse91npcName','Don Corleone'),(4,'TimeDailyDois','0'),(4,'TimeDailyQuatro','0'),(4,'TimeDailyTres','0'),(4,'TimeDailyUm','0'),(4,'timeLogin','1786663240'),(5,'AirBarrierReduction','1786393400'),(5,'antiloop','-1'),(5,'autolootdesativo','1'),(5,'avatarAtkExh','1786393292'),(5,'AvatarMode','1786393400'),(5,'avatarProtec','1786393425'),(5,'bendvalue','10'),(5,'bombermanActiveBombs','0'),(5,'bombermanArena','-1'),(5,'bombermanBombSize','1'),(5,'bombermanInMatch','-1'),(5,'bombermanInQueue','-1'),(5,'bombermanKick','0'),(5,'bombermanMatchStart','-1'),(5,'bombermanMaxBombs','1'),(5,'bombermanOutfitAddons','0'),(5,'bombermanOutfitBody','0'),(5,'bombermanOutfitEx','0'),(5,'bombermanOutfitFeet','0'),(5,'bombermanOutfitHead','0'),(5,'bombermanOutfitLegs','0'),(5,'bombermanOutfitMount','0'),(5,'bombermanOutfitType','0'),(5,'bombermanPartner','-1'),(5,'bombermanSavedSpeed','0'),(5,'bombermanSpeed','1'),(5,'bombermanSpeedDelta','0'),(5,'canturecover','1786394063'),(5,'currentCid','268437027'),(5,'currentFold','air recover'),(5,'DailyHunt_Claimed_2','0'),(5,'DailyHunt_Claimed_5','0'),(5,'DailyHunt_Day','dy1040'),(5,'DailyHunt_Kill_1','0'),(5,'DailyHunt_Kill_2','0'),(5,'DailyHunt_Kill_3','0'),(5,'DailyHunt_Kill_4','0'),(5,'DailyHunt_Kill_5','0'),(5,'DailyHunt_Monster_1','slick water elemental'),(5,'DailyHunt_Monster_2','pirate skeleton'),(5,'DailyHunt_Monster_3','mimic'),(5,'DailyHunt_Monster_4','sand dragon'),(5,'DailyHunt_Monster_5','black sheep'),(5,'dailyTaskColdown','1786142222'),(5,'entroumontado','-1'),(5,'exaustedairball','1786393073'),(5,'exaustedairboost','1786392328'),(5,'exaustedairburst','1786394046'),(5,'exaustedairfan','1786394083'),(5,'exaustedairgale','1786394061'),(5,'exaustedairjump','1786392858'),(5,'exaustedairrecover','1786394063'),(5,'exaustedairrun','1786393326'),(5,'exaustedairwings','1786394062'),(5,'expBeforeDie','-1'),(5,'firstPendentes','1'),(5,'getAwnserAntiBot','-1'),(5,'getCompletedDailydy570','0'),(5,'getCompletedDailydy580','0'),(5,'getCompletedDailydy590','0'),(5,'getCompletedDailydy600','0'),(5,'getCompletedDailydy610','0'),(5,'getCompletedDailydy720','0'),(5,'getCompletedDailydy750','0'),(5,'getCompletedDailydy760','0'),(5,'getPlayerLang','isEnglish'),(5,'getPointsInDodge','0'),(5,'getTurnMsgPoints','1'),(5,'hasPassiveDeathActive','1786403299'),(5,'healthvalue','5'),(5,'isAvatar','1'),(5,'isInDailyTask','0'),(5,'jamudouroupa','1'),(5,'knockoutAttackers',''),(5,'knockoutOldLevel','546'),(5,'lastGlobalSaveLogin','6'),(5,'lastHit','1073753154'),(5,'marketCheck','1786611392'),(5,'momoactive','1'),(5,'momoitem_12540','1'),(5,'momoitem_3384','0'),(5,'momoitem_3413','0'),(5,'morreuD','-1'),(5,'npodedeslogar','1786611291'),(5,'onMoveFlyPosX','514'),(5,'onMoveFlyPosY','350'),(5,'onMoveFlyPosZ','7'),(5,'pendentes','0'),(5,'playerCanMoveDirection','0'),(5,'playerCantDown','-1'),(5,'playerHasGetInitialItens','1'),(5,'playerOnAir','-1'),(5,'playerWithBless','-1'),(5,'pointsUsedInLifeCrystal','2'),(5,'startedWithMana','1'),(5,'stopDashs','1785874840'),(5,'taskInCourse1','1'),(5,'taskInCourse1npcName','Don Corleone'),(5,'taskInCourse2','1'),(5,'taskInCourse27','1'),(5,'taskInCourse27npcName','Don Corleone'),(5,'taskInCourse28','1'),(5,'taskInCourse28npcName','Don Corleone'),(5,'taskInCourse2npcName','Don Corleone'),(5,'taskInCourse4','1'),(5,'taskInCourse40','1'),(5,'taskInCourse40npcName','Don Corleone'),(5,'taskInCourse48','1'),(5,'taskInCourse48npcName','Don Corleone'),(5,'taskInCourse49','1'),(5,'taskInCourse49npcName','Don Corleone'),(5,'taskInCourse4npcName','Don Corleone'),(5,'taskInCourse90','1'),(5,'taskInCourse90npcName','Don Corleone'),(5,'taskInCourse91','1'),(5,'taskInCourse91npcName','Don Corleone'),(5,'taskInCourseGetMonsters1','7'),(5,'taskInCourseGetMonsters2','10'),(5,'TimeDailyDois','0'),(5,'TimeDailyQuatro','0'),(5,'TimeDailyTres','0'),(5,'TimeDailyUm','0'),(5,'timeLogin','1786611286'),(6,'autolootdesativo','1'),(6,'bendvalue','19'),(6,'bombermanActiveBombs','0'),(6,'bombermanArena','-1'),(6,'bombermanBombSize','1'),(6,'bombermanInMatch','-1'),(6,'bombermanInQueue','-1'),(6,'bombermanKick','0'),(6,'bombermanMaxBombs','1'),(6,'bombermanSpeed','1'),(6,'bombermanSpeedDelta','0'),(6,'canturecover','1786500450'),(6,'currentCid','268436950'),(6,'currentFold','fire recover'),(6,'DailyHunt_Claimed_2','0'),(6,'DailyHunt_Claimed_5','0'),(6,'DailyHunt_Day','dy1000'),(6,'DailyHunt_Kill_1','0'),(6,'DailyHunt_Kill_2','0'),(6,'DailyHunt_Kill_3','0'),(6,'DailyHunt_Kill_4','0'),(6,'DailyHunt_Kill_5','0'),(6,'DailyHunt_Monster_1','orc shaman'),(6,'DailyHunt_Monster_2','evil avatar'),(6,'DailyHunt_Monster_3','red butterfly'),(6,'DailyHunt_Monster_4','grorlam'),(6,'DailyHunt_Monster_5','massive earth elemental'),(6,'dailyTaskColdown','1786070249'),(6,'entroumontado','-1'),(6,'exaustedfirebolt','1786220082'),(6,'exaustedfireimpulse','1786220062'),(6,'exaustedfirekick','1786500444'),(6,'exaustedfirerecover','1786500450'),(6,'exaustedfireskyfall','1786500449'),(6,'exaustedfirewhip','1786500450'),(6,'expBeforeDie','-1'),(6,'fireoverPower','0'),(6,'firstPendentes','1'),(6,'getAwnserAntiBot','-1'),(6,'getCompletedDailydy690','0'),(6,'getCompletedDailydy700','0'),(6,'getCompletedDailydy720','0'),(6,'getCompletedDailydy750','0'),(6,'getPlayerLang','isEnglish'),(6,'getPointsInDodge','0'),(6,'getTurnMsgPoints','1'),(6,'hasPassiveDeathActive','1786511159'),(6,'isAvatar','0'),(6,'isInDailyTask','0'),(6,'jamudouroupa','1'),(6,'knockoutAttackers',''),(6,'knockoutOldLevel','27'),(6,'lastGlobalSaveLogin','6'),(6,'lastHit','1073743066'),(6,'marketCheck','1786571729'),(6,'morreuD','-1'),(6,'npodedeslogar','1786570798'),(6,'onMoveFlyPosX','446'),(6,'onMoveFlyPosY','342'),(6,'onMoveFlyPosZ','7'),(6,'pendentes','1'),(6,'playerCanMoveDirection','0'),(6,'playerHasGetInitialItens','1'),(6,'playerOnAir','-1'),(6,'playerWithBless','-1'),(6,'questChests25455','1'),(6,'startedWithMana','1'),(6,'taskInCourse1','2'),(6,'taskInCourse12','1'),(6,'taskInCourse12npcName','Don Corleone'),(6,'taskInCourse1npcName','Don Corleone'),(6,'taskInCourse2','1'),(6,'taskInCourse27','1'),(6,'taskInCourse27npcName','Don Corleone'),(6,'taskInCourse28','1'),(6,'taskInCourse28npcName','Don Corleone'),(6,'taskInCourse2npcName','Don Corleone'),(6,'taskInCourse3','1'),(6,'taskInCourse3npcName','Don Corleone'),(6,'taskInCourse4','1'),(6,'taskInCourse40','1'),(6,'taskInCourse40npcName','Don Corleone'),(6,'taskInCourse48','1'),(6,'taskInCourse48npcName','Don Corleone'),(6,'taskInCourse49','1'),(6,'taskInCourse49npcName','Don Corleone'),(6,'taskInCourse4npcName','Don Corleone'),(6,'taskInCourse7','1'),(6,'taskInCourse7npcName','Don Corleone'),(6,'taskInCourse90','1'),(6,'taskInCourse90npcName','Don Corleone'),(6,'taskInCourse91','1'),(6,'taskInCourse91npcName','Don Corleone'),(6,'taskInCourseGetMonsters1','25'),(6,'taskInCourseGetMonsters2','12'),(6,'taskInCourseGetMonsters4','4'),(6,'TimeDailyDois','0'),(6,'TimeDailyQuatro','0'),(6,'TimeDailyTres','0'),(6,'TimeDailyUm','0'),(6,'timeLogin','1786570793');
/*!40000 ALTER TABLE `player_string_storage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_viplist`
--

DROP TABLE IF EXISTS `player_viplist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_viplist` (
  `player_id` int(11) NOT NULL,
  `vip_id` int(11) NOT NULL,
  `description` varchar(128) NOT NULL,
  `icon` int(11) unsigned NOT NULL,
  `notify` tinyint(1) NOT NULL,
  UNIQUE KEY `player_id_2` (`player_id`,`vip_id`),
  KEY `player_id` (`player_id`),
  KEY `vip_id` (`vip_id`),
  CONSTRAINT `player_viplist_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
  CONSTRAINT `player_viplist_ibfk_2` FOREIGN KEY (`vip_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_viplist`
--

LOCK TABLES `player_viplist` WRITE;
/*!40000 ALTER TABLE `player_viplist` DISABLE KEYS */;
/*!40000 ALTER TABLE `player_viplist` ENABLE KEYS */;
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
  `skill_fist` int(11) unsigned NOT NULL DEFAULT 10,
  `skill_fist_tries` bigint(20) unsigned NOT NULL DEFAULT 0,
  `skill_club` int(11) unsigned NOT NULL DEFAULT 10,
  `skill_club_tries` bigint(20) unsigned NOT NULL DEFAULT 0,
  `skill_sword` int(11) unsigned NOT NULL DEFAULT 10,
  `skill_sword_tries` bigint(20) unsigned NOT NULL DEFAULT 0,
  `skill_axe` int(11) unsigned NOT NULL DEFAULT 10,
  `skill_axe_tries` bigint(20) unsigned NOT NULL DEFAULT 0,
  `skill_dist` int(11) unsigned NOT NULL DEFAULT 10,
  `skill_dist_tries` bigint(20) unsigned NOT NULL DEFAULT 0,
  `skill_shielding` int(11) unsigned NOT NULL DEFAULT 10,
  `skill_shielding_tries` bigint(20) unsigned NOT NULL DEFAULT 0,
  `skill_fishing` int(11) unsigned NOT NULL DEFAULT 10,
  `skill_fishing_tries` bigint(20) unsigned NOT NULL DEFAULT 0,
  `direction` int(11) NOT NULL DEFAULT 2,
  `loss_experience` int(11) NOT NULL DEFAULT 100,
  `loss_mana` int(11) NOT NULL DEFAULT 100,
  `loss_skills` int(11) NOT NULL DEFAULT 100,
  `loss_containers` int(11) NOT NULL DEFAULT 100,
  `loss_items` int(11) NOT NULL DEFAULT 100,
  `premend` int(11) NOT NULL DEFAULT 0 COMMENT 'NOT IN USE BY THE SERVER',
  `online` tinyint(1) NOT NULL DEFAULT 0,
  `onlinetime` bigint(20) unsigned NOT NULL DEFAULT 0,
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
  `deletion` bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`,`deleted`),
  KEY `account_id` (`account_id`),
  KEY `group_id` (`group_id`),
  KEY `online` (`online`),
  KEY `deleted` (`deleted`),
  CONSTRAINT `players_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `players`
--

LOCK TABLES `players` WRITE;
/*!40000 ALTER TABLE `players` DISABLE KEYS */;
INSERT INTO `players` VALUES (1,'Account Manager',0,1,1,1,0,150,150,0,0,0,0,0,1020,0,0,0,0,0,0,0,0,853,921,7,'',400,0,1786810084,16777343,0,0,0,0,'',0,0,0,0,3361,10,0,10,0,10,0,10,0,10,0,10,0,10,0,0,100,100,100,100,100,0,0,0,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,0,1,1,1,1,1,0,2147483647,0,0,0),(2,'Mahito',0,6,2,477,1,14420,14420,1786754394,114,0,115,68,1025,0,0,6,2480,2480,143,100,2,500,353,7,'',8925,1,1786805513,16777343,1,0,0,0,'',1786805562,0,0,0,2520,10,0,10,0,10,0,10,0,10,0,10,0,10,0,1,60,100,100,100,0,0,0,379360,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,1,1,1,1,1,1,0,2147483647,0,0,0),(3,'Terrinha',0,1,2,100,4,3310,3210,15750100,114,0,115,68,1085,0,0,25,595,595,0,100,2,513,362,7,'\0 \0\0ÿÿÿÿ03\0\Z\0\0\0\0\0\0\0\0è\0\0\0\0\0Ð\0\0\0\0\0þ',1000,1,1786605529,16777343,1,4,0,0,'',1786298027,0,0,0,2518,14,25,10,2,10,0,10,0,22,26,11,82,10,0,2,60,100,100,100,0,0,0,0,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,1,1,1,1,1,1,0,1784877983,0,0,0),(4,'Pansa Beifong',0,1,2,60,1,2710,2710,3297541,114,0,115,68,1020,0,0,20,395,395,0,100,1,514,358,7,'',1250,0,1786663240,16777343,1,4,0,0,'',1786663260,0,0,0,2520,13,37,10,0,11,30,10,0,11,30,10,8,10,0,2,60,100,100,100,0,0,0,0,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,0,1,1,1,1,1,0,12574,0,0,0),(5,'Explainer',0,1,2,542,3,16622,16622,2637024321,114,0,115,68,1065,0,0,110,2587,2805,45877,100,1,514,350,7,'',900,1,1786611286,16777343,1,4,0,0,'',1786611381,0,0,0,2520,13,23,10,42,10,0,11,30,21,53,10,48,10,0,2,60,100,100,100,0,0,0,0,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,0,1,1,1,1,1,0,22258,0,0,0),(6,'Barbiezinha milgrau',0,1,2,26,1,867,890,259946,114,0,115,68,1020,0,0,19,179,225,0,100,1,446,342,7,'',1200,0,1786570793,16777343,1,4,0,0,'',1786571727,0,0,0,2520,12,11,10,6,10,0,10,0,22,88,12,102,10,0,2,60,100,100,100,0,0,0,0,0,0,0,'',0,0,0,'',0,'',0,0,0,'0',0,-1,43200,'',0,0,1,1,1,1,1,1,0,8053,0,0,0);
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
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `ondelete_players` BEFORE DELETE ON `players` FOR EACH ROW BEGIN DELETE FROM `bans` WHERE `type` = 2 AND `value` = OLD.`id`; UPDATE `houses` SET `owner` = 0 WHERE `owner` = OLD.`id`; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `players_online`
--

DROP TABLE IF EXISTS `players_online`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `players_online` (
  `player_id` int(11) NOT NULL,
  PRIMARY KEY (`player_id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `players_online`
--

LOCK TABLES `players_online` WRITE;
/*!40000 ALTER TABLE `players_online` DISABLE KEYS */;
/*!40000 ALTER TABLE `players_online` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rewards`
--

DROP TABLE IF EXISTS `rewards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rewards` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `need_premmy` int(11) NOT NULL DEFAULT 0,
  `need_level` int(11) NOT NULL DEFAULT 0,
  `world_id` int(11) NOT NULL DEFAULT 0,
  `reward_name` varchar(60) NOT NULL,
  `reward_description` text NOT NULL,
  `reward_award_text` text NOT NULL,
  `type` varchar(20) NOT NULL,
  `value` varchar(20) NOT NULL,
  `value1` varchar(20) NOT NULL,
  `condition` varchar(5) NOT NULL DEFAULT '>=',
  `value2` varchar(20) NOT NULL,
  `value3` varchar(20) NOT NULL DEFAULT 'null',
  `value4` varchar(20) NOT NULL DEFAULT 'null',
  `reward` varchar(20) NOT NULL,
  `value_reward` varchar(20) NOT NULL,
  `value_reward1` varchar(200) NOT NULL,
  `stars` int(11) NOT NULL,
  `ativado` smallint(1) NOT NULL DEFAULT 1,
  `icon_especial` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rewards`
--

LOCK TABLES `rewards` WRITE;
/*!40000 ALTER TABLE `rewards` DISABLE KEYS */;
/*!40000 ALTER TABLE `rewards` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rewards_completed`
--

DROP TABLE IF EXISTS `rewards_completed`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rewards_completed` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reward_id` int(11) NOT NULL,
  `value` varchar(20) NOT NULL,
  `value1` varchar(20) NOT NULL,
  `time` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rewards_completed`
--

LOCK TABLES `rewards_completed` WRITE;
/*!40000 ALTER TABLE `rewards_completed` DISABLE KEYS */;
/*!40000 ALTER TABLE `rewards_completed` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sellchar`
--

DROP TABLE IF EXISTS `sellchar`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sellchar` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL,
  `vocation` int(11) NOT NULL,
  `text` text NOT NULL,
  `price` int(11) NOT NULL,
  `status` varchar(40) NOT NULL,
  `oldid` varchar(40) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sellchar`
--

LOCK TABLES `sellchar` WRITE;
/*!40000 ALTER TABLE `sellchar` DISABLE KEYS */;
/*!40000 ALTER TABLE `sellchar` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `server_config`
--

DROP TABLE IF EXISTS `server_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `server_config` (
  `config` varchar(35) NOT NULL DEFAULT '',
  `value` varchar(255) NOT NULL DEFAULT '',
  UNIQUE KEY `config` (`config`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `server_config`
--

LOCK TABLES `server_config` WRITE;
/*!40000 ALTER TABLE `server_config` DISABLE KEYS */;
INSERT INTO `server_config` VALUES ('db_version','35'),('encryption','2'),('motd_hash','9ce2fb1875a454efc858d85557c3d2d02f818e81'),('motd_num','1'),('players_record','1');
/*!40000 ALTER TABLE `server_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `server_motd`
--

DROP TABLE IF EXISTS `server_motd`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `server_motd` (
  `id` int(10) unsigned NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `text` text NOT NULL,
  UNIQUE KEY `id` (`id`,`world_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `server_motd`
--

LOCK TABLES `server_motd` WRITE;
/*!40000 ALTER TABLE `server_motd` DISABLE KEYS */;
INSERT INTO `server_motd` VALUES (1,0,'Welcome to The Forgotten Server!'),(2,0,'Welcome to fantastic world of Avatar! Like us in facebook.com/otavatartibia.'),(3,0,'Welcome to fantastic world of Avatar!');
/*!40000 ALTER TABLE `server_motd` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `server_record`
--

DROP TABLE IF EXISTS `server_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `server_record` (
  `record` int(11) NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `timestamp` bigint(20) NOT NULL,
  UNIQUE KEY `record` (`record`,`world_id`,`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `server_record`
--

LOCK TABLES `server_record` WRITE;
/*!40000 ALTER TABLE `server_record` DISABLE KEYS */;
INSERT INTO `server_record` VALUES (0,0,0),(1,255,1786737545),(101,0,1784641407),(102,0,1785044006),(103,0,1785794001);
/*!40000 ALTER TABLE `server_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `server_reports`
--

DROP TABLE IF EXISTS `server_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `server_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `player_id` int(11) NOT NULL DEFAULT 1,
  `posx` int(11) NOT NULL DEFAULT 0,
  `posy` int(11) NOT NULL DEFAULT 0,
  `posz` int(11) NOT NULL DEFAULT 0,
  `timestamp` bigint(20) NOT NULL DEFAULT 0,
  `report` text NOT NULL,
  `reads` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `world_id` (`world_id`),
  KEY `reads` (`reads`),
  KEY `player_id` (`player_id`),
  CONSTRAINT `server_reports_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `server_reports`
--

LOCK TABLES `server_reports` WRITE;
/*!40000 ALTER TABLE `server_reports` DISABLE KEYS */;
/*!40000 ALTER TABLE `server_reports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `server_storage`
--

DROP TABLE IF EXISTS `server_storage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `server_storage` (
  `key` varchar(255) NOT NULL,
  `value` text NOT NULL,
  UNIQUE KEY `key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `server_storage`
--

LOCK TABLES `server_storage` WRITE;
/*!40000 ALTER TABLE `server_storage` DISABLE KEYS */;
/*!40000 ALTER TABLE `server_storage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shop_history`
--

DROP TABLE IF EXISTS `shop_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `shop_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account` int(11) NOT NULL,
  `player` int(11) NOT NULL,
  `date` datetime NOT NULL,
  `title` varchar(100) NOT NULL,
  `cost` int(11) NOT NULL,
  `details` varchar(500) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_history`
--

LOCK TABLES `shop_history` WRITE;
/*!40000 ALTER TABLE `shop_history` DISABLE KEYS */;
INSERT INTO `shop_history` VALUES (1,2,2,'2026-08-09 01:03:27','Crystal Coin',1,'{\"type\":\"item\",\"itemId\":2160,\"title\":\"Crystal Coin\",\"count\":1,\"item\":3043,\"description\":\"You will receive 1 crystal coins.\",\"cost\":1}'),(2,2,2,'2026-08-09 01:03:46','Demon Helmet',11,'{\"type\":\"item\",\"itemId\":2493,\"title\":\"Demon Helmet\",\"count\":1,\"item\":3387,\"description\":\"A very rare helmet.\",\"cost\":11}'),(3,2,2,'2026-08-09 01:03:49','Demon Helmet',11,'{\"type\":\"item\",\"itemId\":2493,\"title\":\"Demon Helmet\",\"count\":1,\"item\":3387,\"description\":\"A very rare helmet.\",\"cost\":11}'),(4,2,2,'2026-08-09 01:03:50','Demon Helmet',11,'{\"type\":\"item\",\"itemId\":2493,\"title\":\"Demon Helmet\",\"count\":1,\"item\":3387,\"description\":\"A very rare helmet.\",\"cost\":11}'),(5,2,2,'2026-08-09 01:03:51','Demon Helmet',11,'{\"type\":\"item\",\"itemId\":2493,\"title\":\"Demon Helmet\",\"count\":1,\"item\":3387,\"description\":\"A very rare helmet.\",\"cost\":11}'),(6,2,2,'2026-08-09 01:03:53','Demon Helmet',11,'{\"type\":\"item\",\"itemId\":2493,\"title\":\"Demon Helmet\",\"count\":1,\"item\":3387,\"description\":\"A very rare helmet.\",\"cost\":11}'),(7,2,2,'2026-08-09 01:03:55','Demon Helmet',11,'{\"type\":\"item\",\"itemId\":2493,\"title\":\"Demon Helmet\",\"count\":1,\"item\":3387,\"description\":\"A very rare helmet.\",\"cost\":11}'),(8,2,2,'2026-08-09 01:03:57','Demon Helmet',11,'{\"type\":\"item\",\"itemId\":2493,\"title\":\"Demon Helmet\",\"count\":1,\"item\":3387,\"description\":\"A very rare helmet.\",\"cost\":11}'),(9,2,2,'2026-08-09 01:05:36','Demon Helmet',11,'{\"type\":\"item\",\"itemId\":2493,\"title\":\"Demon Helmet\",\"count\":1,\"item\":3387,\"description\":\"A very rare helmet.\",\"cost\":11}'),(10,2,2,'2026-08-09 01:31:48','Camera',25,'{\"cost\":25,\"count\":1,\"title\":\"Camera\",\"type\":\"item\",\"itemId\":18432,\"item\":17434,\"description\":\"Use it to turn on or off your channel.\"}'),(11,2,2,'2026-08-09 01:52:02','Camera',25,'{\"itemId\":18432,\"item\":17434,\"description\":\"Use it to turn on or off your channel.\",\"cost\":25,\"count\":1,\"title\":\"Camera\",\"type\":\"item\"}'),(12,2,2,'2026-08-09 01:53:44','Camera',25,'{\"count\":1,\"description\":\"Use it to turn on or off your channel.\",\"cost\":25,\"type\":\"item\",\"title\":\"Camera\",\"itemId\":18432,\"item\":17434}'),(13,2,2,'2026-08-09 02:10:49','Camera',25,'{\"cost\":25,\"description\":\"Use it to turn on or off your channel.\",\"title\":\"Camera\",\"itemId\":18432,\"count\":1,\"type\":\"item\",\"item\":17434}'),(14,2,2,'2026-08-09 02:26:36','Camera',25,'{\"itemId\":18432,\"item\":17434,\"cost\":25,\"type\":\"item\",\"count\":1,\"description\":\"Use it to turn on or off your channel.\",\"title\":\"Camera\"}'),(15,2,2,'2026-08-09 02:54:47','Camera',25,'{\"description\":\"Use it to turn on or off your channel.\",\"cost\":25,\"item\":17434,\"itemId\":18432,\"title\":\"Camera\",\"count\":1,\"type\":\"item\"}'),(16,2,4,'2026-08-09 03:25:05','Camera',25,'{\"title\":\"Camera\",\"description\":\"Use it to turn on or off your channel.\",\"itemId\":18432,\"count\":1,\"item\":17434,\"type\":\"item\",\"cost\":25}'),(17,2,5,'2026-08-09 04:04:26','Air avatar state',10,'{\"outfit\":{\"head\":2,\"addons\":0,\"feet\":114,\"type\":1226,\"mount\":0,\"body\":116,\"legs\":114},\"type\":\"outfit\",\"cost\":10,\"description\":\"Feel the air avatar state\",\"title\":\"Air avatar state\"}'),(18,2,5,'2026-08-09 04:04:50','Air avatar state',10,'{\"outfit\":{\"head\":2,\"addons\":0,\"feet\":114,\"type\":1226,\"mount\":0,\"body\":116,\"legs\":114},\"type\":\"outfit\",\"cost\":10,\"description\":\"Feel the air avatar state\",\"title\":\"Air avatar state\"}'),(19,2,2,'2026-08-09 04:07:32','Full Avatar State',100,'{\"cost\":100,\"type\":\"outfit\",\"title\":\"Full Avatar State\",\"outfit\":{\"addons\":0,\"legs\":114,\"head\":2,\"body\":116,\"type\":1224,\"mount\":0,\"feet\":114},\"description\":\"Feel the power of becoming an true avatar\"}'),(20,2,5,'2026-08-09 04:20:07','Air avatar state',10,'{\"title\":\"Air avatar state\",\"type\":\"outfit\",\"description\":\"Feel the air avatar state\",\"cost\":10,\"outfit\":{\"head\":2,\"body\":116,\"addons\":0,\"type\":1226,\"mount\":0,\"feet\":114,\"legs\":114}}'),(21,2,5,'2026-08-09 04:21:33','Full Avatar State',100,'{\"title\":\"Full Avatar State\",\"type\":\"outfit\",\"description\":\"Feel the power of becoming an true avatar\",\"cost\":100,\"outfit\":{\"head\":2,\"body\":116,\"addons\":0,\"type\":1224,\"mount\":0,\"feet\":114,\"legs\":114}}'),(22,2,5,'2026-08-09 04:38:55','Air avatar state',10,'{\"title\":\"Air avatar state\",\"type\":\"outfit\",\"description\":\"Feel the air avatar state\",\"outfit\":{\"head\":2,\"body\":116,\"feet\":114,\"legs\":114,\"mount\":0,\"addons\":0,\"type\":1226},\"cost\":10}'),(23,2,2,'2026-08-09 15:07:02','Momo Pouch',25,'{\"item\":17437,\"cost\":25,\"description\":\"A special pouch that can only be equipped in its own slot.\",\"count\":1,\"type\":\"item\",\"itemId\":18435,\"title\":\"Momo Pouch\"}'),(24,2,2,'2026-08-09 15:50:41','Momo Pouch',25,'{\"count\":1,\"type\":\"item\",\"cost\":25,\"description\":\"A special pouch that can only be equipped in its own slot.\",\"itemId\":18435,\"title\":\"Momo Pouch\",\"item\":17437}'),(25,2,5,'2026-08-09 16:42:37','Camera',25,'{\"itemId\":18432,\"type\":\"item\",\"cost\":25,\"item\":17434,\"description\":\"Use it to turn on or off your channel.\",\"count\":1,\"title\":\"Camera\"}'),(26,2,5,'2026-08-09 16:42:47','Momo Pouch',25,'{\"itemId\":18435,\"type\":\"item\",\"cost\":25,\"item\":17437,\"description\":\"A special pouch that can only be equipped in its own slot.\",\"count\":1,\"title\":\"Momo Pouch\"}'),(27,2,5,'2026-08-09 17:02:37','Momo Pouch',25,'{\"itemId\":18435,\"cost\":25,\"description\":\"A special pouch that can only be equipped in its own slot.\",\"item\":17437,\"count\":1,\"type\":\"item\",\"title\":\"Momo Pouch\"}'),(28,2,2,'2026-08-09 19:46:33','Momo Pouch',25,'{\"description\":\"A special pouch that can only be equipped in its own slot.\",\"type\":\"item\",\"itemId\":18435,\"item\":17437,\"title\":\"Momo Pouch\",\"count\":1,\"cost\":25}'),(29,2,4,'2026-08-11 19:39:19','Momo Pouch',25,'{\"item\":17437,\"itemId\":18435,\"type\":\"item\",\"description\":\"A special pouch that can only be equipped in its own slot.\",\"cost\":25,\"title\":\"Momo Pouch\",\"count\":1}'),(30,2,6,'2026-08-12 17:25:51','Momo Pouch',25,'{\"count\":1,\"description\":\"A special pouch that can only be equipped in its own slot.\",\"itemId\":18435,\"title\":\"Momo Pouch\",\"cost\":25,\"item\":17437,\"type\":\"item\"}');
/*!40000 ALTER TABLE `shop_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `statistics`
--

DROP TABLE IF EXISTS `statistics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `statistics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `section` varchar(32) NOT NULL,
  `action` varchar(32) NOT NULL,
  `when` int(11) NOT NULL,
  `ant_uri` varchar(255) NOT NULL,
  `uri` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `statistics`
--

LOCK TABLES `statistics` WRITE;
/*!40000 ALTER TABLE `statistics` DISABLE KEYS */;
/*!40000 ALTER TABLE `statistics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tasksmonsters`
--

DROP TABLE IF EXISTS `tasksmonsters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tasksmonsters` (
  `Name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `MonsterName` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `Amount` int(11) NOT NULL,
  `Experience` double NOT NULL,
  `InNpcs` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `MoneyWin` int(11) DEFAULT NULL,
  `Identifier` int(11) NOT NULL,
  `levelMin` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tasksmonsters`
--

LOCK TABLES `tasksmonsters` WRITE;
/*!40000 ALTER TABLE `tasksmonsters` DISABLE KEYS */;
INSERT INTO `tasksmonsters` VALUES ('Initial Rotworms','Rotworm',25,0,'geralTasks',0,1,2),('Tortoise Easy','Tortoise',30,0,'geralTasks',0,90,5),('Thornback Tortoise Easy','Thornback Tortoise',30,0,'geralTasks',0,91,8),('Cyclops Easy','Cyclops',30,0,'geralTasks',0,2,15),('Cyclops Medium','Cyclops Drone',30,0,'geralTasks',0,4,20),('Cyclops Hard','Cyclops Smith',100,0,'geralTasks',0,3,25),('Cyclops Extreme','Cyclops Smith',500,0,'geralTasks',0,150,30),('Hydras Easy','Hydra',160,0,'geralTasks',0,5,50),('Hydras Medium','Hydramat',35,0,'geralTasks',0,6,52),('Hydras Hard','Hydra',550,0,'geralTasks',0,151,56),('Hydras Extreme','Hydramat',140,0,'geralTasks',0,152,61),('Demoniacs Skeletons','Demon Skeleton',60,0,'geralTasks',0,7,26),('Boss Devil Skeleton','Devil Skeleton',1,0,'notHave',0,8,1),('Terror Easy','Terror Bird',130,0,'geralTasks',0,9,35),('Destroyer Easy','Destroyer',40,0,'geralTasks',0,10,45),('Frost Dragon Easy','Frost Dragon Hatchling',130,0,'geralTasks',0,89,41),('Frost Dragon Medium','Frost Dragon',80,0,'geralTasks',0,11,51),('Crystal Spider Easy','Crystal Spider',45,0,'geralTasks',0,12,27),('Ice Witch Easy','Ice Witch',55,0,'geralTasks',0,13,28),('Bloody Easy','Bloody Hunter',30,0,'geralTasks',0,14,40),('Bloody Hard','Bloody Alchemist',50,0,'geralTasks',0,15,42),('Dragons Easy','Dragon Hatchling',60,0,'geralTasks',0,16,36),('Dragons Medium','Dragon',120,0,'geralTasks',0,17,46),('Dragons Extreme','Dragon',1500,0,'geralTasks',0,155,56),('Sea Serpent Easy','Sea Serpent',200,0,'geralTasks',0,18,52),('Sea Serpent Hard','Sea Serpent',800,0,'geralTasks',0,153,57),('Frost Dragon Hard','Zero',15,0,'geralTasks',0,19,53),('Diabolic Imp Easy','Diabolic Imp',30,0,'geralTasks',0,20,37),('Fire Devil Easy','Fire Devil',45,0,'geralTasks',0,21,28),('Behemoth Easy','Behemoth',70,0,'geralTasks',0,22,47),('Behemoth Hard','Behemoth',320,0,'geralTasks',0,154,54),('Dragons Hard','Dragon Lord',80,0,'geralTasks',0,23,85),('Necromancer Easy','Necromancer',40,0,'geralTasks',0,24,38),('Golens Easy','Worker Golem',150,0,'geralTasks',0,25,60),('Golens Hard','War Golem',150,0,'geralTasks',0,26,70),('Orc Easy','Orc',50,0,'geralTasks',0,27,16),('Orc Medium','Orc Berserker',50,0,'geralTasks',0,28,21),('Orc Hard','Orc Warlord',50,0,'geralTasks',0,29,30),('Vampires Easy','Vampire',100,0,'geralTasks',0,30,29),('Vampires Medium','Marcelline',150,0,'geralTasks',0,31,54),('Vampires Hard','Abadeer',550,0,'geralTasks',0,32,80),('Banshee','Banshee',100,0,'geralTasks',0,33,61),('Hellspawn','Hellspawn',250,0,'geralTasks',0,34,81),('Vulcan Easy','Magma Crawler',380,0,'geralTasks',0,52,78),('Vulcan Medium','Vulcongra',360,0,'geralTasks',0,53,79),('Vulcan Hard','Orewalker',290,0,'geralTasks',0,54,85),('Vulcan Extreme','Weeper',320,0,'geralTasks',0,55,85),('Vulcan Hardcore','Cliff Strider',300,0,'geralTasks',0,75,90),('Nipper Easy','Frazzlemaw',360,0,'geralTasks',0,56,82),('Nipper Medium','Choking Fear',300,0,'geralTasks',0,57,83),('Nipper Hard','Guzzlemaw',320,0,'geralTasks',0,58,85),('Niper Extreme','Mawhawk',290,0,'geralTasks',0,59,91),('Niper Hardcore','Minotaur Amazon',310,0,'geralTasks',0,76,92),('Niper Master','Minotaur Hunter',380,0,'geralTasks',0,77,95),('Mine Easy','Deepling Scout',240,0,'geralTasks',0,78,100),('Mine Medium','Deepling Spellsinger',260,0,'geralTasks',0,79,101),('Mine Hard','Deepling Tyrant',210,0,'geralTasks',0,80,102),('Mine Extreme','Deepling Warrior',450,0,'geralTasks',0,81,105),('Mutation Easy','Mutated Human',140,0,'geralTasks',0,82,62),('Mutation Medium','Mutated Bat',200,0,'geralTasks',0,83,65),('Mutation Hard','Mutated Rat',300,0,'geralTasks',0,84,71),('Giants Extreme','Frost Giantess',150,0,'geralTasks',0,85,75),('Giants Hardcore','Frost Giant',40,0,'geralTasks',0,86,84),('Crystal Golem Hard','Crystal Golem',350,0,'geralTasks',0,87,110),('Crystal Crusher Hard','Crystal Crusher',320,0,'geralTasks',0,88,115),('Askarak Easy','Askarak Demon',350,0,'geralTasks',0,60,76),('Askarak Medium','Askarak Lord',450,0,'geralTasks',0,62,80),('Askarak Hard','Askarak Prince',850,0,'geralTasks',0,61,85),('Shaburak Easy','Shaburak Demon',450,0,'geralTasks',0,63,80),('Shaburak Medium','Shaburak Lord',550,0,'geralTasks',0,64,83),('Shaburak Hard','Shaburak Prince',950,0,'geralTasks',0,65,85),('Vampire Extreme','Nightfiend',350,0,'geralTasks',0,66,85),('Vampire Hardcore','The Pale Count',430,0,'geralTasks',0,67,93),('Vampire Master','Vicious Manbat',500,0,'geralTasks',0,68,95),('Vampire Torture','Vampire Viscount',900,0,'geralTasks',0,69,103),('Mummys Easy','Kashek',100,0,'geralTasks',0,35,72),('Mummys Medium','Munrah',600,0,'geralTasks',0,36,75),('Mummys Hard','Kashek',800,0,'geralTasks',0,37,83),('Wyvern Easy','Wyvern',100,0,'geralTasks',0,38,31),('Wyrm Easy','Wyrm',100,0,'geralTasks',0,39,84),('Nomads Easy','Air Defensor',100,0,'geralTasks',0,40,22),('Big Bugs Easy','Tilehorned',50,0,'geralTasks',0,41,43),('Big Bugs Hard','Tilehorned',300,0,'geralTasks',0,42,48),('Bogs Easy','Bog Raider',50,0,'geralTasks',0,43,60),('Bogs Hard','Bog Raider',300,0,'geralTasks',0,44,63),('Primate Easy','Primate',80,0,'geralTasks',0,45,62),('Knights Easy','Black Knight',100,0,'geralTasks',0,46,47),('Knights Hard','Dark Knight',200,0,'geralTasks',0,47,61),('Monkeys Easy','Sibang',30,0,'geralTasks',0,48,10),('Monkeys Hard','Kongra',100,0,'geralTasks',0,49,17),('Dwarf Easy','Enslaved Dwarf',70,0,'geralTasks',0,70,90),('Dwarf Medium','Lost Berserker',150,0,'geralTasks',0,71,94),('Dwarf Hard','Lost Basher',200,0,'geralTasks',0,72,97),('Dwarf Extreme','Lost Thrower',300,0,'geralTasks',0,73,98),('Dwarf Hardcore','Lost Husher',550,0,'geralTasks',0,74,104),('Ogre Brute Easy','Ogre Brute',300,0,'geralTasks',0,93,105),('Ogre Savage Easy','Ogre Savage',300,0,'geralTasks',0,94,106),('Ogre Shaman Easy','Ogre Shaman',300,0,'geralTasks',0,95,107),('Ogre Brute Hard','Ogre Brute',1000,0,'geralTasks',0,96,110),('Ogre Savage Hard','Ogre Savage',1000,0,'geralTasks',0,97,113),('Sandstone Scorpion Easy','Sandstone Scorpion',100,0,'geralTasks',0,99,70),('Sandstone Scorpion Hard','Sandstone Scorpion',500,0,'geralTasks',0,100,75),('Deep Terror Easy','Deep Terror',150,0,'geralTasks',0,101,79),('Deep Terror Hard','Deep Terror',450,0,'geralTasks',0,102,85),('Plaguesmith Easy','Plaguesmith',100,0,'geralTasks',0,103,86),('Plaguesmith Hard','Plaguesmith',500,0,'geralTasks',0,104,87),('Grimeleech Easy','Grimeleech',50,0,'geralTasks',0,105,90),('Grimeleech Hard','Grimeleech',350,0,'geralTasks',0,106,92),('Fungus Easy','Hideous Fungus',250,0,'geralTasks',0,107,91),('Fungus Medium','Humongous Fungus',300,0,'geralTasks',0,128,92),('Fungus Hard','Hideous Fungus',450,0,'geralTasks',0,108,93),('Ghastly Easy','Ghastly Dragon',100,0,'geralTasks',0,109,131),('Ghastly Hard','Ghastly Dragon',600,0,'geralTasks',0,110,135),('Moohtant Easy','Moohtant',20,0,'geralTasks',0,111,136),('Lava Golem Easy','Lava Golem',20,0,'geralTasks',0,112,137),('Jaul Easy','Jaul',20,0,'geralTasks',0,113,138),('King Scorpianus Easy','King Scorpianus',20,0,'geralTasks',0,114,139),('Abyssador Easy','Abyssador',20,0,'geralTasks',0,115,140),('Demodras Easy','Demodras',20,0,'geralTasks',0,142,141),('Insectoid Scout Easy','Insectoid Scout',300,0,'geralTasks',0,116,160),('Spitter Easy','Spitter',400,0,'geralTasks',0,117,165),('Spidris Easy','Spidris',400,0,'geralTasks',0,118,170),('Spitter Hard','Spitter',1000,0,'geralTasks',0,120,180),('Spidris Hard','Spidris',1000,0,'geralTasks',0,121,185),('Moohtant Medium','Moohtant',50,0,'geralTasks',0,123,186),('Lava Golem Medium','Lava Golem',50,0,'geralTasks',0,124,188),('Jaul Medium','Jaul',50,0,'geralTasks',0,125,190),('King Scorpianus Medium','King Scorpianus',50,0,'geralTasks',0,126,192),('Abyssador Medium','Abyssador',50,0,'geralTasks',0,127,194),('Demodras Medium','Demodras',50,0,'geralTasks',0,143,195),('Kollos Easy','Kollos',20,0,'geralTasks',0,122,200),('Leviathan Easy','Leviathan',300,0,'geralTasks',0,130,200),('Leviathan Medium','Leviathan',650,0,'geralTasks',0,131,210),('Leviathan Hard','Leviathan',1000,0,'geralTasks',0,132,225),('Leviathan Extreme','Leviathan',3000,0,'geralTasks',0,133,240),('Elder Wyrm Easy','Elder Wyrm',300,0,'geralTasks',0,134,205),('Elder Wyrm Medium','Elder Wyrm',550,0,'geralTasks',0,135,215),('Elder Wyrm Hard','Elder Wyrm',1000,0,'geralTasks',0,136,230),('Elder Wyrm Extreme','Elder Wyrm',3000,0,'geralTasks',0,137,250),('Kelpie Easy','Kelpie',20,0,'geralTasks',0,138,204),('Kelpie Medium','Kelpie',50,0,'geralTasks',0,139,218),('Tyrn Easy','Tyrn',20,0,'geralTasks',0,140,222),('Tyrn Medium','Tyrn',50,0,'geralTasks',0,141,237),('Moohtant Hard','Moohtant',100,0,'geralTasks',0,144,226),('Lava Golem Hard','Lava Golem',100,0,'geralTasks',0,145,227),('King Scorpianus Hard','King Scorpianus',100,0,'geralTasks',0,147,229),('Abyssador Hard','Abyssador',100,0,'geralTasks',0,148,230),('Demodras Hard','Demodras',100,0,'geralTasks',0,149,231),('Grim Reaper Easy','Grim Reaper',100,0,'geralTasks',0,156,53),('Grim Reaper Hard','Grim Reaper',500,0,'geralTasks',0,157,73),('Medusa Easy','Medusa',120,0,'geralTasks',0,158,58),('Medusa Hard','Medusa',600,0,'geralTasks',0,159,76),('Serpent Spawn Medium','Serpent Spawn',500,0,'geralTasks',0,177,75),('Serpent Spawn Extreme','Serpent Spawn',1200,0,'geralTasks',0,178,86),('Beholder Easy','Beholder',300,0,'geralTasks',0,179,91),('Beholder Hard','Elder Beholder',600,0,'geralTasks',0,180,96),('Energy Elementals Easy','Energy Elemental',300,0,'geralTasks',0,181,102),('Energy Elementals Hard','Energy Overlord',200,0,'geralTasks',0,182,116),('Undead Dragon Easy','Undead Dragon',250,0,'geralTasks',0,160,83),('Undead Dragon Hard','Undead Dragon',700,0,'geralTasks',0,161,93),('Warlock Easy','Warlock',150,0,'geralTasks',0,162,60),('Warlock Hard','Warlock',500,0,'geralTasks',0,163,62),('Dark Warlock Easy','Dark Warlock',150,0,'geralTasks',0,164,120),('Dark Warlock Hard','Dark Warlock',350,0,'geralTasks',0,165,130),('Drakens Easy','Draken Elite',100,0,'geralTasks',0,166,81),('Drakens Medium','Draken Spellweaver',350,0,'geralTasks',0,167,87),('Drakens Hard','Draken Warmaster',450,0,'geralTasks',0,168,92),('Lizards Easy','Lizard Legionnaire',100,0,'geralTasks',0,169,41),('Lizards Medium','Lizard High Guard',200,0,'geralTasks',0,170,47),('Lizards Hard','Lizard Chosen',400,0,'geralTasks',0,171,52),('Sand Dragon Easy','Sand Dragon',250,0,'geralTasks',0,172,97),('Sand Dragon Hard','Sand Dragon',700,0,'geralTasks',0,173,105),('Death Dragon Easy','Death Dragon',250,0,'geralTasks',0,174,147),('Death Dragon Hard','Death Dragon',500,0,'geralTasks',0,175,155),('Zorvorax Hard','Zorvorax',100,0,'geralTasks',0,176,171),('Dragons POI','Dragon',50,0,'notHave',0,50,915),('Dragons Lord POI','Dragon Lord',10,0,'notHave',0,51,915),('Water Outlaws Easy','Water Outlaw',100,0,'geralTasks',0,223,171),('Water Outlaws Hard','Water Outlaw',500,0,'geralTasks',0,224,175),('Water Outlaws Extreme','Water Outlaw Leader',350,0,'geralTasks',0,227,180),('Nightstalker Easy','Nightstalker',120,0,'geralTasks',0,225,177),('Dark Fury Hard','Dark Fury',500,0,'geralTasks',0,226,182),('Dark Fury Extreme','Dark Fury',1500,0,'geralTasks',0,228,191),('Quara Mantassin Easy','Quara Mantassin',400,0,'geralTasks',0,229,152),('Quara Predator Hard','Quara Predator',450,0,'geralTasks',0,230,161),('Quara Mantassin Extreme','Quara Mantassin',900,0,'geralTasks',0,231,168),('Silencer Easy','Silencer',150,0,'geralTasks',0,232,212),('Vexclaw Medium','Vexclaw',450,0,'geralTasks',0,233,217),('Silencer Hard','Silencer',850,0,'geralTasks',0,234,222),('Orclops Medium','Orclops Doomhauler',650,0,'geralTasks',0,235,227),('Shaper Hard','Shaper Matriarch',750,0,'geralTasks',0,236,232),('Orclops Extreme','Orclops Doomhauler',1500,0,'geralTasks',0,237,237),('Snowman Easy','Muffled Snowman',250,0,'geralTasks',0,238,182),('Snowman Medium','Muffled Snowman',650,0,'geralTasks',0,239,193),('Snowman Hard','Ancient Snowman',400,0,'geralTasks',0,240,204),('Snowman Extreme','Muffled Snowman',1500,0,'geralTasks',0,241,211),('Olaf Easy','Olaf',20,0,'geralTasks',0,242,141),('Olaf Medium','Olaf',50,0,'geralTasks',0,243,182),('Zushuka Medium','Zushuka',500,0,'geralTasks',0,244,214),('Zushuka Hard','Zushuka',1000,0,'geralTasks',0,245,246),('Zushuka Extreme','Zushuka',2500,0,'geralTasks',0,246,271),('Yakchal Hard','Yakchal',400,0,'geralTasks',0,247,244),('Yakchal Extreme','Yakchal',850,0,'geralTasks',0,248,266),('Kraken Hard','Kraken',200,0,'geralTasks',0,249,259),('Horus Hard','Horus',600,0,'geralTasks',0,250,265),('Horus Extreme','Horus',1500,0,'geralTasks',0,251,280),('Carnival Hard','Carnival',700,0,'geralTasks',0,252,241),('Carnival Extreme','Carnival',1500,0,'geralTasks',0,253,252),('Dead Beat Medium','Dead Beat',450,0,'geralTasks',0,254,223),('Dead Beat Hard','Dead Beat',700,0,'geralTasks',0,255,237),('Dead Beat Extreme','Dead Beat',1500,0,'geralTasks',0,256,258),('Mouth of Hell Hard','Mouth of Hell',200,0,'geralTasks',0,257,260),('Leecher Easy','Leecher',250,0,'geralTasks',0,258,219),('Leecher Medium','Leecher',550,0,'geralTasks',0,259,234),('Leecher Hard','Leecher',850,0,'geralTasks',0,260,245),('Jafar Hard','Jafar',400,0,'geralTasks',0,261,263),('Jafar Extreme','Jafar',800,0,'geralTasks',0,262,276),('Machine King Hard','Machine King',200,0,'geralTasks',0,263,261),('Death Wing Hard','Death Wing',200,0,'geralTasks',0,264,262);
/*!40000 ALTER TABLE `tasksmonsters` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tile_items`
--

DROP TABLE IF EXISTS `tile_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tile_items` (
  `tile_id` int(10) unsigned NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `sid` int(11) NOT NULL,
  `pid` int(11) NOT NULL DEFAULT 0,
  `itemtype` int(11) NOT NULL,
  `count` int(11) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL,
  UNIQUE KEY `tile_id` (`tile_id`,`world_id`,`sid`),
  KEY `sid` (`sid`),
  CONSTRAINT `tile_items_ibfk_1` FOREIGN KEY (`tile_id`) REFERENCES `tiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tile_items`
--

LOCK TABLES `tile_items` WRITE;
/*!40000 ALTER TABLE `tile_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `tile_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tile_store`
--

DROP TABLE IF EXISTS `tile_store`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tile_store` (
  `house_id` int(10) unsigned NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `data` longblob NOT NULL,
  KEY `house_id` (`house_id`),
  CONSTRAINT `tile_store_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `houses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tile_store`
--

LOCK TABLES `tile_store` WRITE;
/*!40000 ALTER TABLE `tile_store` DISABLE KEYS */;
INSERT INTO `tile_store` VALUES (4,0,'ì~\0\0\0Ú\0'),(4,0,'ì\0\0\0Û\0'),(4,0,'ó\0\0\0í(\0'),(5,0,'z\0\0\0à\0'),(5,0,'z\0\0\0á\0'),(5,0,'~\0\0\0à\0'),(5,0,'~\0\0\0á\0'),(5,0,'|\0\0\0í(\0'),(6,0,'z\0\0\0à\0'),(6,0,'z\0\0\0á\0'),(6,0,'|\0\0\0í(\0'),(7,0,'~\0\0\0ä(\0'),(7,0,'€\0\0\0Ú\0'),(7,0,'\0\0\0Û\0'),(8,0,'|\0\0\0í(\0'),(8,0,'~\0\0\0à\0'),(8,0,'~\0\0\0á\0'),(9,0,'\0\0\0ä(\0'),(9,0,'‚\0\0\0à\0'),(9,0,'‚\0\0\0á\0'),(10,0,'s\0\0\0à\0'),(10,0,'s\0\0\0á\0'),(10,0,'s\0\0\0Ú\0'),(10,0,'t\0\0\0Û\0'),(10,0,'w\0\0\0í(\0'),(11,0,'p\0\0\0à\0'),(11,0,'p\0\0\0á\0'),(11,0,'v\0\0\0ä(\0'),(12,0,'q\0\0\0Ú\0'),(12,0,'r\0\0\0Û\0'),(12,0,'p\0\0\0à\0'),(12,0,'p\0\0\0á\0'),(12,0,'u\0\0\0ä(\0'),(13,0,'l\0\0\0í(\0'),(13,0,'m\0\0\0à\0'),(13,0,'m\0\0\0á\0'),(14,0,'k\0\0\0Ú\0'),(14,0,'l\0\0\0Û\0'),(14,0,'l\0\0\0í(\0'),(16,0,'j\0\0\0Ú\0'),(16,0,'k\0\0\0Û\0'),(16,0,'i\0\0\0ä(\0'),(21,0,'q\0\0\0Ú\0'),(21,0,'r\0\0\0Û\0'),(21,0,' v\0\0\0ä(\0'),(22,0,'s\0\0\0Ú\0'),(22,0,'t\0\0\0Û\0'),(22,0,'u\0\0\0à\0'),(22,0,'(s\0\0\0í(\0'),(22,0,' u\0\0\0á\0'),(23,0,'j\0\0\0Ú\0'),(23,0,'k\0\0\0Û\0'),(23,0,'i\0\0\0à\0'),(23,0,' i\0\0\0á\0'),(23,0,'(l\0\0\0í(\0'),(24,0,'j\0\0\0Ú\0'),(24,0,'k\0\0\0Û\0'),(24,0,' h\0\0\0ä(\0'),(25,0,'$j\0\0\0Ú\0'),(25,0,'$k\0\0\0Û\0'),(25,0,'&h\0\0\0ä(\0'),(26,0,'a\0\0\0Ú\0'),(26,0,'b\0\0\0Û\0'),(26,0,'a\0\0\0Ú\0'),(26,0,'b\0\0\0Û\0'),(26,0,'#b\0\0\0í(\0'),(26,0,'\"d\0\0\0ä(\0'),(27,0,'9{\0\0\0ä(\0'),(27,0,'9|\0\0\0ä(\0'),(27,0,'7\0\0\0à\0'),(27,0,'7\0\0\0à\0'),(27,0,'8\0\0\0á\0'),(27,0,'8\0\0\0á\0'),(28,0,'@y\0\0\0ä(\0'),(28,0,'@|\0\0\0ä(\0'),(28,0,'@}\0\0\0ä(\0'),(28,0,'>\0\0\0à\0'),(28,0,'?\0\0\0á\0'),(28,0,'@\0\0\0à\0'),(28,0,'A\0\0\0á\0'),(29,0,'4s\0\0\0Ú\0'),(29,0,'5r\0\0\0à\0'),(29,0,'6r\0\0\0á\0'),(29,0,'3t\0\0\0í(\0'),(29,0,'4t\0\0\0Û\0'),(30,0,'$q\0\0\0Ú\0'),(30,0,'$r\0\0\0Û\0'),(30,0,'&v\0\0\0ä(\0'),(31,0,'3o\0\0\0í(\0'),(31,0,'4n\0\0\0Ú\0'),(31,0,'4o\0\0\0Û\0'),(31,0,'5p\0\0\0à\0'),(31,0,'6p\0\0\0á\0'),(32,0,'T\0\0\0Ú\0'),(32,0,'U\0\0\0Û\0'),(32,0,'U\0\0\0í(\0'),(33,0,'	T\0\0\0à\0'),(33,0,'\nT\0\0\0á\0'),(33,0,'V\0\0\0í(\0'),(35,0,'T\0\0\0à\0'),(35,0,'T\0\0\0á\0'),(35,0,'W\0\0\0í(\0'),(36,0,'Y\0\0\0à\0'),(36,0,'Y\0\0\0á\0'),(36,0,'[\0\0\0í(\0'),(37,0,'V\0\0\0í(\0'),(37,0,'	T\0\0\0à\0'),(37,0,'\nT\0\0\0á\0'),(38,0,'[\0\0\0í(\0'),(38,0,'Y\0\0\0Ú\0'),(38,0,'Z\0\0\0Û\0'),(39,0,'>K\0\0\0ä(\0'),(39,0,'>N\0\0\0ä(\0'),(39,0,'@G\0\0\0Ú\0'),(39,0,'@G\0\0\0Ú\0'),(39,0,'@H\0\0\0Û\0'),(39,0,'@H\0\0\0Û\0'),(40,0,'8?\0\0\0Ú\0'),(40,0,'@?\0\0\0Ú\0'),(40,0,'@?\0\0\0Ú\0'),(40,0,';A\0\0\0í(\0'),(40,0,'8@\0\0\0Û\0'),(40,0,'9D\0\0\0ä(\0'),(40,0,'@@\0\0\0Û\0'),(40,0,'@@\0\0\0Û\0'),(41,0,'þK\0\0\0ä(\0'),(41,0,'ýL\0\0\0à\0'),(41,0,'þL\0\0\0á\0'),(41,0,'O\0\0\0Ú\0'),(41,0,'\0P\0\0\0í(\0'),(41,0,'P\0\0\0à\0'),(41,0,'P\0\0\0á\0'),(41,0,'P\0\0\0Û\0'),(42,0,'÷K\0\0\0ä(\0'),(42,0,'õL\0\0\0Ú\0'),(42,0,'õM\0\0\0Û\0'),(43,0,'êO\0\0\0Ú\0'),(43,0,'îL\0\0\0Ú\0'),(43,0,'îM\0\0\0Û\0'),(43,0,'ðK\0\0\0ä(\0'),(43,0,'êQ\0\0\0à\0'),(43,0,'ëQ\0\0\0á\0'),(43,0,'êP\0\0\0Û\0'),(43,0,'íP\0\0\0í(\0'),(44,0,'ùB\0\0\0ä(\0'),(44,0,'ü@\0\0\0Ú\0'),(44,0,'üA\0\0\0Û\0'),(45,0,'÷C\0\0\0í(\0'),(45,0,'õF\0\0\0à\0'),(45,0,'öF\0\0\0á\0'),(46,0,'úC\0\0\0í(\0'),(46,0,'ûF\0\0\0à\0'),(46,0,'üF\0\0\0á\0'),(47,0,'@\0\0\0Ú\0'),(47,0,'A\0\0\0Û\0'),(47,0,'B\0\0\0í(\0'),(47,0,'B\0\0\0í(\0'),(47,0,'B\0\0\0í(\0'),(47,0,'C\0\0\0à\0'),(47,0,'C\0\0\0á\0'),(49,0,'íV\0\0\0í(\0'),(49,0,'ê\\\0\0\0à\0'),(49,0,'ë\\\0\0\0á\0'),(50,0,'Úh\0\0\0¡\0'),(51,0,'Ïh\0\0\0¡\0'),(54,0,'Ìf\0\0\0¡\0'),(55,0,'Ë_\0\0\0¡\0'),(56,0,'Õ\\\0\0\0¡\0'),(56,0,'Ø_\0\0\0¡\0'),(57,0,'ÝV\0\0\0¡\0'),(57,0,'áW\0\0\0ž\0'),(58,0,'ØW\0\0\0ž\0'),(59,0,'ÍT\0\0\0¡\0'),(59,0,'ÌW\0\0\0ž\0'),(60,0,'ÚO\0\0\0¡\0'),(68,0,'û‹\0\0\0ä\0'),(68,0,'ùŽ\0\0\0Ú\0'),(68,0,'ù\0\0\0Û\0'),(69,0,'\0\0\0ä\0'),(69,0,'\0\0\0Ú\0'),(69,0,'‘\0\0\0Û\0'),(70,0,'&†\0\0\0Ú\0'),(70,0,'&‡\0\0\0Û\0'),(70,0,'*ˆ\0\0\0á\0'),(71,0,':‹\0\0\0Ú\0'),(71,0,'6\0\0\0á\0'),(71,0,':Œ\0\0\0Û\0'),(72,0,'.‡\0\0\0ä\0'),(72,0,'0„\0\0\0Ú\0'),(72,0,'0…\0\0\0Û\0'),(73,0,'&ˆ\0\0\0Ú\0'),(73,0,'&‰\0\0\0Û\0'),(73,0,')‰\0\0\0á\0'),(74,0,'÷‰\0\0\0Ú\0'),(74,0,'÷Š\0\0\0Û\0'),(74,0,'ú‹\0\0\0á\0'),(75,0,'ÿ…\0\0\0á\0'),(75,0,'\0†\0\0\0à\0'),(75,0,'†\0\0\0á\0'),(77,0,'\0\0\0Ú\0'),(77,0,'‚\0\0\0Û\0'),(77,0,'…\0\0\0ä\0'),(78,0,'\0\0\0Ú\0'),(78,0,'‚\0\0\0Û\0'),(78,0,'…\0\0\0ä\0'),(79,0,'Š\0\0\0á\0'),(79,0,'\Zˆ\0\0\0Ú\0'),(79,0,'\Z‰\0\0\0Û\0'),(80,0,'\0\0\0Ú\0'),(80,0,'ƒ\0\0\0ä\0'),(80,0,'€\0\0\0Û\0'),(81,0,'\Z\0\0\0Ú\0'),(81,0,'ƒ\0\0\0ä\0'),(81,0,'\Z€\0\0\0Û\0'),(82,0,'\0\0\0Ú\0'),(82,0,'€\0\0\0Û\0'),(82,0,'‚\0\0\0ä\0'),(83,0,'\0\0\0Ú\0'),(83,0,'€\0\0\0Û\0'),(83,0,'‚\0\0\0ä\0'),(84,0,'‘\0\0\0Ú\0'),(84,0,'’\0\0\0Û\0'),(84,0,'“\0\0\0á\0'),(85,0,'‘\0\0\0Ú\0'),(85,0,'’\0\0\0Û\0'),(85,0,'”\0\0\0ä\0'),(86,0,'“\0\0\0á\0'),(86,0,'‘\0\0\0Ú\0'),(86,0,'’\0\0\0Û\0'),(87,0,'‘\0\0\0Ú\0'),(87,0,'’\0\0\0Û\0'),(87,0,'”\0\0\0ä\0'),(88,0,'+‘\0\0\0Ú\0'),(88,0,'+’\0\0\0Û\0'),(88,0,'.’\0\0\0á\0'),(89,0,'1’\0\0\0á\0'),(89,0,'4‘\0\0\0Ú\0'),(89,0,'4’\0\0\0Û\0'),(90,0,'Az\0\0\0Ú\0'),(90,0,'A{\0\0\0Û\0'),(90,0,'Fz\0\0\0Ú\0'),(90,0,'F{\0\0\0Û\0'),(90,0,'D~\0\0\0ä\0'),(91,0,'Bw\0\0\0á\0'),(91,0,'Eu\0\0\0Ú\0'),(91,0,'Ev\0\0\0Û\0'),(92,0,'Aw\0\0\0á\0'),(92,0,'Eu\0\0\0Ú\0'),(92,0,'Ev\0\0\0Û\0'),(93,0,'î§\0\0\0ä\0'),(93,0,'ï¨\0\0\0Ú\0'),(93,0,'ï©\0\0\0Û\0'),(94,0,'ã£\0\0\0Ú\0'),(94,0,'ã¤\0\0\0Û\0'),(94,0,'æ¥\0\0\0á\0'),(96,0,'Lß\0\0\0\0Ú\0'),(96,0,'MÞ\0\0\0\0ë\Z\0'),(96,0,'Là\0\0\0\0Û\0'),(96,0,'Lã\0\0\0\0t\0'),(97,0,'RÞ\0\0\0\0ë\Z\0'),(97,0,'Qã\0\0\0\0Ú\0'),(97,0,'Uâ\0\0\0\0t\0'),(97,0,'Qä\0\0\0\0Û\0'),(97,0,'Så\0\0\0\0s\0'),(98,0,'Qß\0\0\0\0Ú\0'),(98,0,'Qà\0\0\0\0Û\0'),(98,0,'Sã\0\0\0\0ë\Z\0'),(98,0,'Uâ\0\0\0\0t\0'),(99,0,'Lß\0\0\0\0Ú\0'),(99,0,'Là\0\0\0\0Û\0'),(99,0,'Nã\0\0\0\0ë\Z\0'),(100,0,'\\à\0\0\0\0à\0'),(100,0,']à\0\0\0\0á\0'),(100,0,'^â\0\0\0\0ô\Z\0'),(100,0,']æ\0\0\0\0s\0'),(101,0,'\\à\0\0\0\0à\0'),(101,0,']à\0\0\0\0á\0'),(101,0,'^ã\0\0\0\0ô\Z\0'),(101,0,'\\æ\0\0\0\0s\0'),(102,0,'?Ô\0\0\0\0Ú\0'),(102,0,'?Õ\0\0\0\0Û\0'),(102,0,'E×\0\0\0\0ô\Z\0'),(102,0,'FÚ\0\0\0\0à\0'),(102,0,'GÚ\0\0\0\0á\0'),(102,0,'GÛ\0\0\0\0s\0'),(102,0,'HØ\0\0\0\0t\0'),(103,0,'GÒ\0\0\0\0Ú\0'),(103,0,'GÓ\0\0\0\0Û\0'),(103,0,'HÓ\0\0\0\0t\0'),(103,0,'CÔ\0\0\0\0ë\Z\0'),(104,0,'?Ò\0\0\0\0Ú\0'),(104,0,'?Ó\0\0\0\0Û\0'),(104,0,'A×\0\0\0\0ô\Z\0'),(105,0,'AË\0\0\0\0Ú\0'),(105,0,'HÊ\0\0\0\0ë\Z\0'),(105,0,'@Ì\0\0\0\0t\0'),(105,0,'AÌ\0\0\0\0Û\0'),(105,0,'EÎ\0\0\0\0s\0'),(105,0,'KÌ\0\0\0\0t\0'),(106,0,'EÄ\0\0\0\0Ú\0'),(106,0,'EÅ\0\0\0\0Û\0'),(106,0,'HÆ\0\0\0\0ë\Z\0'),(106,0,'KÄ\0\0\0\0t\0'),(107,0,'hÒ\0\0\0\0Ú\0'),(107,0,'hÓ\0\0\0\0Û\0'),(107,0,'kÔ\0\0\0\0ô\Z\0'),(108,0,'È\0ô\0\0\0ô\Z\0'),(109,0,'È\0ú\0\0\0ô\Z\0'),(110,0,'Ù\0æ\0\0\0Ú\0'),(110,0,'Ù\0ç\0\0\0Û\0'),(110,0,'Ý\0æ\0\0\0Ú\0'),(110,0,'Ý\0ç\0\0\0Û\0'),(110,0,'Û\0ë\0\0\0Ð#\0'),(111,0,'Ð\0æ\0\0\0Ú\0'),(111,0,'Ð\0ç\0\0\0Û\0'),(111,0,'Ô\0æ\0\0\0Ú\0'),(111,0,'Ô\0ç\0\0\0Û\0'),(111,0,'Ò\0ë\0\0\0Ð#\0'),(112,0,'·\0ß\0\0\0º\0'),(112,0,'¹\0Ü\0\0\0&\0'),(112,0,'º\0Ý\0\0\0Ú\0'),(112,0,'º\0Þ\0\0\0Û\0'),(112,0,'¹\0â\0\0\0&\0'),(113,0,'™\0Ö\0\0\0Ú\0'),(113,0,'™\0×\0\0\0Û\0'),(113,0,'\0Ø\0\0\0º\0'),(114,0,'˜\0Ð\0\0\0Ú\0'),(114,0,'˜\0Ñ\0\0\0Û\0'),(114,0,'›\0Ò\0\0\0º\0'),(115,0,'§\0Ï\0\0\0Ú\0'),(115,0,'¥\0Ð\0\0\0º\0'),(115,0,'§\0Ð\0\0\0Û\0'),(116,0,'¡\0Ä\0\0\0Ú\0'),(116,0,'¡\0Å\0\0\0Û\0'),(116,0,'¥\0Å\0\0\0º\0'),(117,0,'ª\0Ô\0\0\0Ú\0'),(117,0,'ª\0Õ\0\0\0Û\0'),(117,0,'­\0Õ\0\0\0º\0'),(118,0,'Â\0»\0\0\0Ú\0'),(118,0,'Æ\0»\0\0\0Ú\0'),(118,0,'Ç\0¹\0\0\0Í#\0'),(118,0,'Â\0¼\0\0\0Û\0'),(118,0,'Æ\0¼\0\0\0Û\0'),(119,0,'Â\0¾\0\0\0Ú\0'),(119,0,'Â\0¿\0\0\0Û\0'),(119,0,'Æ\0¾\0\0\0Ú\0'),(119,0,'Æ\0¿\0\0\0Û\0'),(119,0,'Ä\0Á\0\0\0Ð#\0'),(119,0,'Ä\0Ç\0\0\0Ð#\0'),(119,0,'Ç\0Ä\0\0\0Í#\0'),(119,0,'Â\0È\0\0\0Ú\0'),(119,0,'Â\0É\0\0\0Û\0'),(120,0,'Ñ\0·\0\0\0Ú\0'),(120,0,'Ð\0¶\0\0\0Ð#\0'),(120,0,'Ñ\0¸\0\0\0Û\0'),(121,0,'Ú\0·\0\0\0Ú\0'),(121,0,'Ù\0¶\0\0\0Ð#\0'),(121,0,'Ú\0¸\0\0\0Û\0'),(122,0,'Ì\0Ê\0\0\0Ú\0'),(122,0,'Ì\0Ë\0\0\0Û\0'),(122,0,'Î\0Ê\0\0\0Ú\0'),(122,0,'Î\0Ë\0\0\0Û\0'),(122,0,'Ð\0Ì\0\0\0Í#\0'),(123,0,'Ö\0Ì\0\0\0Ð#\0'),(123,0,'Ù\0Ï\0\0\0Ú\0'),(123,0,'Ù\0Ð\0\0\0Û\0'),(124,0,'Ã\0¯\0\0\0Ú\0'),(124,0,'Å\0¯\0\0\0Ú\0'),(124,0,'Ç\0®\0\0\0Í#\0'),(124,0,'Ã\0°\0\0\0Û\0'),(124,0,'Å\0°\0\0\0Û\0'),(125,0,'î\0©\0\0\0Ð#\0'),(125,0,'ï\0ª\0\0\0Ú\0'),(125,0,'ï\0«\0\0\0Û\0'),(125,0,'î\0±\0\0\0Ð#\0'),(126,0,'÷\0ª\0\0\0Ú\0'),(126,0,'÷\0«\0\0\0Û\0'),(126,0,'õ\0±\0\0\0Ð#\0'),(127,0,'þ\0±\0\0\0Ð#\0'),(127,0,'\0ª\0\0\0Ú\0'),(127,0,'\0«\0\0\0Û\0'),(128,0,'ª\0\0\0Ú\0'),(128,0,'«\0\0\0Û\0'),(128,0,'	­\0\0\0Ð#\0'),(129,0,'ª\0\0\0Ú\0'),(129,0,'«\0\0\0Û\0'),(129,0,'­\0\0\0Ð#\0'),(130,0,'¯\0\0\0Í#\0'),(130,0,'\r®\0\0\0Ú\0'),(130,0,'\r¯\0\0\0Û\0'),(131,0,'·\0\0\0Ú\0'),(131,0,'\nµ\0\0\0Ð#\0'),(131,0,'\r·\0\0\0Ú\0'),(131,0,'¸\0\0\0Û\0'),(131,0,'\nº\0\0\0Ð#\0'),(131,0,'\nº\0\0\0Ð#\0'),(131,0,'\r¸\0\0\0Û\0'),(131,0,'¼\0\0\0Ú\0'),(131,0,'½\0\0\0Û\0'),(131,0,'½\0\0\0Í#\0'),(131,0,'Â\0\0\0Ú\0'),(131,0,'Ã\0\0\0Û\0'),(131,0,'\nÀ\0\0\0Ð#\0'),(131,0,'\nÀ\0\0\0Ð#\0'),(131,0,'\rÂ\0\0\0Ú\0'),(131,0,'\rÃ\0\0\0Û\0'),(131,0,'\nÅ\0\0\0Ð#\0'),(132,0,'þ\0Ú\0\0\0Õ#\0'),(132,0,'ý\0Þ\0\0\0à\0'),(132,0,'þ\0Þ\0\0\0á\0'),(133,0,'×\0\0\0Ó#\0'),(133,0,'Ö\0\0\0Ú\0'),(133,0,'×\0\0\0Û\0'),(134,0,'þ\0Ú\0\0\0Õ#\0'),(134,0,'ý\0Þ\0\0\0à\0'),(134,0,'þ\0Þ\0\0\0á\0'),(135,0,'×\0\0\0Ó#\0'),(135,0,'Ö\0\0\0Ú\0'),(135,0,'×\0\0\0Û\0'),(136,0,'×\0\0\0Õ#\0'),(136,0,'\rÛ\0\0\0Ú\0'),(136,0,'\rÜ\0\0\0Û\0'),(137,0,'ý\0Ë\0\0\0Ú\0'),(137,0,'ý\0Î\0\0\0Ú\0'),(137,0,'ý\0Ï\0\0\0Û\0'),(137,0,'ý\0Ì\0\0\0Û\0'),(137,0,'\0Ë\0\0\0Í#\0'),(137,0,'Ê\0\0\0à\0'),(137,0,'Ê\0\0\0á\0'),(137,0,'Ï\0\0\0Í#\0'),(138,0,'ý\0Ê\0\0\0Ú\0'),(138,0,'ý\0Ë\0\0\0Û\0'),(138,0,'Ë\0\0\0Í#\0'),(139,0,'\nÉ\0\0\0Ð#\0'),(139,0,'\rÊ\0\0\0Ú\0'),(139,0,'\rË\0\0\0Û\0'),(139,0,'\rÏ\0\0\0Ú\0'),(139,0,'\rÐ\0\0\0Û\0'),(147,0,')_\0\0\0Ú\0'),(147,0,'.^\0\0\0ä(\0'),(147,0,'1_\0\0\0Ú\0'),(147,0,')b\0\0\0Ú\0'),(147,0,')c\0\0\0Û\0'),(147,0,')`\0\0\0Û\0'),(147,0,'-d\0\0\0ä(\0'),(147,0,'0c\0\0\0à\0'),(147,0,'1c\0\0\0á\0'),(147,0,'1`\0\0\0Û\0'),(148,0,'K\0\0\0ä(\0'),(148,0,'N\0\0\0Ú\0'),(148,0,'O\0\0\0Û\0'),(148,0,'	P\0\0\0à\0'),(148,0,'\nP\0\0\0á\0'),(149,0,'í@\0\0\0Ú\0'),(149,0,'íA\0\0\0Û\0'),(149,0,'îF\0\0\0à\0'),(149,0,'ïF\0\0\0á\0'),(149,0,'ïG\0\0\0ä(\0'),(150,0,'\\\0\0\0ä(\0'),(150,0,'\\\0\0\0Ú\0'),(150,0,']\0\0\0Û\0'),(151,0,'!I\0\0\0à\0'),(151,0,'\"I\0\0\0á\0'),(151,0,'\'J\0\0\0í(\0'),(152,0,'!F\0\0\0Ú\0'),(152,0,'!G\0\0\0Û\0'),(152,0,'\'F\0\0\0í(\0'),(153,0,'!C\0\0\0à\0'),(153,0,'\"C\0\0\0á\0'),(153,0,'\'B\0\0\0í(\0'),(154,0,'+B\0\0\0í(\0'),(154,0,'0C\0\0\0à\0'),(154,0,'1C\0\0\0á\0'),(155,0,'+F\0\0\0í(\0'),(155,0,'1F\0\0\0Ú\0'),(155,0,'1G\0\0\0Û\0'),(156,0,'+J\0\0\0í(\0'),(156,0,'0I\0\0\0à\0'),(156,0,'1I\0\0\0á\0'),(157,0,'+J\0\0\0í(\0'),(157,0,'0I\0\0\0à\0'),(157,0,'1I\0\0\0á\0'),(158,0,'!I\0\0\0à\0'),(158,0,'\"I\0\0\0á\0'),(158,0,'\'J\0\0\0í(\0'),(159,0,'!F\0\0\0Ú\0'),(159,0,'!G\0\0\0Û\0'),(159,0,'\'F\0\0\0í(\0'),(160,0,'+F\0\0\0í(\0'),(160,0,'1F\0\0\0Ú\0'),(160,0,'1G\0\0\0Û\0'),(161,0,'+B\0\0\0í(\0'),(161,0,'0C\0\0\0à\0'),(161,0,'1C\0\0\0á\0'),(162,0,'!C\0\0\0à\0'),(162,0,'\"C\0\0\0á\0'),(162,0,'\'B\0\0\0í(\0'),(164,0,'‚}\0\0\0½\0'),(166,0,'~\0\0\0½\0'),(167,0,'•y\0\0\0½\0'),(168,0,'‚\0\0\0à\0'),(168,0,'‚\0\0\0á\0'),(168,0,'…\0\0\0í(\0'),(168,0,'…\0\0\0Ú\0'),(168,0,'†\0\0\0Û\0'),(168,0,'ˆ\0\0\0à\0'),(168,0,'ˆ\0\0\0á\0'),(169,0,'îk\0\0\0Ú\0'),(169,0,'ën\0\0\0à\0'),(169,0,'îl\0\0\0Û\0'),(169,0,'ìn\0\0\0á\0'),(169,0,'ïl\0\0\0í(\0'),(171,0,'ür\0\0\0í(\0'),(171,0,'\0p\0\0\0à\0'),(171,0,'p\0\0\0á\0'),(172,0,'‰x\0\0\0½\0');
/*!40000 ALTER TABLE `tile_store` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tiles`
--

DROP TABLE IF EXISTS `tiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tiles` (
  `id` int(10) unsigned NOT NULL,
  `world_id` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `house_id` int(10) unsigned NOT NULL,
  `x` int(5) unsigned NOT NULL,
  `y` int(5) unsigned NOT NULL,
  `z` tinyint(2) unsigned NOT NULL,
  UNIQUE KEY `id` (`id`,`world_id`),
  KEY `x` (`x`,`y`,`z`),
  KEY `house_id` (`house_id`,`world_id`),
  CONSTRAINT `tiles_ibfk_1` FOREIGN KEY (`house_id`, `world_id`) REFERENCES `houses` (`id`, `world_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tiles`
--

LOCK TABLES `tiles` WRITE;
/*!40000 ALTER TABLE `tiles` DISABLE KEYS */;
/*!40000 ALTER TABLE `tiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `towns`
--

DROP TABLE IF EXISTS `towns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `towns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `posx` int(11) NOT NULL DEFAULT 0,
  `posy` int(11) NOT NULL DEFAULT 0,
  `posz` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `towns`
--

LOCK TABLES `towns` WRITE;
/*!40000 ALTER TABLE `towns` DISABLE KEYS */;
/*!40000 ALTER TABLE `towns` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_bug_tracker`
--

DROP TABLE IF EXISTS `z_bug_tracker`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_bug_tracker` (
  `account` varchar(255) NOT NULL,
  `type` int(11) NOT NULL,
  `status` int(11) NOT NULL,
  `text` text NOT NULL,
  `id` int(11) NOT NULL,
  `subject` varchar(255) NOT NULL,
  `reply` int(11) NOT NULL,
  `who` int(11) NOT NULL,
  `uid` int(11) NOT NULL AUTO_INCREMENT,
  `tag` int(11) NOT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_bug_tracker`
--

LOCK TABLES `z_bug_tracker` WRITE;
/*!40000 ALTER TABLE `z_bug_tracker` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_bug_tracker` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_changelog`
--

DROP TABLE IF EXISTS `z_changelog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_changelog` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(255) NOT NULL DEFAULT '',
  `where` varchar(255) NOT NULL DEFAULT '',
  `date` int(11) NOT NULL DEFAULT 0,
  `description` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_changelog`
--

LOCK TABLES `z_changelog` WRITE;
/*!40000 ALTER TABLE `z_changelog` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_changelog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_character_trade`
--

DROP TABLE IF EXISTS `z_character_trade`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_character_trade` (
  `player_id` int(11) NOT NULL,
  `price` int(11) NOT NULL,
  `old_accountid` int(11) NOT NULL,
  PRIMARY KEY (`player_id`),
  UNIQUE KEY `player_id` (`player_id`),
  KEY `z_account_player` (`old_accountid`),
  CONSTRAINT `z_character_trade_ibfk_1` FOREIGN KEY (`old_accountid`) REFERENCES `accounts` (`id`),
  CONSTRAINT `z_character_trade_ibfk_2` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_character_trade`
--

LOCK TABLES `z_character_trade` WRITE;
/*!40000 ALTER TABLE `z_character_trade` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_character_trade` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_character_trade_history`
--

DROP TABLE IF EXISTS `z_character_trade_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_character_trade_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `old_accountid` int(11) NOT NULL,
  `new_accountid` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `z_charhistory_account` (`player_id`),
  CONSTRAINT `z_character_trade_history_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_character_trade_history`
--

LOCK TABLES `z_character_trade_history` WRITE;
/*!40000 ALTER TABLE `z_character_trade_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_character_trade_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_donate_history_item`
--

DROP TABLE IF EXISTS `z_donate_history_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_donate_history_item` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `to_name` varchar(255) NOT NULL DEFAULT '0',
  `to_account` int(11) NOT NULL DEFAULT 0,
  `from_nick` varchar(255) NOT NULL,
  `from_account` int(11) NOT NULL DEFAULT 0,
  `price` int(11) NOT NULL DEFAULT 0,
  `offer_id` int(11) NOT NULL DEFAULT 0,
  `trans_state` varchar(255) NOT NULL,
  `trans_start` int(11) NOT NULL DEFAULT 0,
  `trans_real` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_donate_history_item`
--

LOCK TABLES `z_donate_history_item` WRITE;
/*!40000 ALTER TABLE `z_donate_history_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_donate_history_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_forum`
--

DROP TABLE IF EXISTS `z_forum`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_forum` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sticky` tinyint(1) NOT NULL DEFAULT 0,
  `closed` tinyint(1) NOT NULL DEFAULT 0,
  `first_post` int(11) NOT NULL DEFAULT 0,
  `last_post` int(11) NOT NULL DEFAULT 0,
  `section` int(3) NOT NULL DEFAULT 0,
  `replies` int(11) NOT NULL DEFAULT 0,
  `views` int(11) NOT NULL DEFAULT 0,
  `author_aid` int(11) NOT NULL DEFAULT 0,
  `author_guid` int(11) NOT NULL DEFAULT 0,
  `post_text` text NOT NULL,
  `post_topic` varchar(255) NOT NULL,
  `post_smile` tinyint(1) NOT NULL DEFAULT 0,
  `post_date` int(11) NOT NULL DEFAULT 0,
  `last_edit_aid` int(11) NOT NULL DEFAULT 0,
  `edit_date` int(11) NOT NULL DEFAULT 0,
  `post_ip` varchar(32) NOT NULL DEFAULT '0.0.0.0',
  `icon_id` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `section` (`section`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_forum`
--

LOCK TABLES `z_forum` WRITE;
/*!40000 ALTER TABLE `z_forum` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_forum` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_monsters`
--

DROP TABLE IF EXISTS `z_monsters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_monsters` (
  `hide_creature` tinyint(1) NOT NULL DEFAULT 0,
  `name` varchar(255) NOT NULL,
  `mana` int(11) NOT NULL,
  `exp` int(11) NOT NULL,
  `health` int(11) NOT NULL,
  `speed_lvl` int(11) NOT NULL DEFAULT 1,
  `use_haste` tinyint(1) NOT NULL,
  `voices` text NOT NULL,
  `immunities` varchar(255) NOT NULL,
  `summonable` tinyint(1) NOT NULL,
  `convinceable` tinyint(1) NOT NULL,
  `race` varchar(255) NOT NULL,
  `gfx_name` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_monsters`
--

LOCK TABLES `z_monsters` WRITE;
/*!40000 ALTER TABLE `z_monsters` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_monsters` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_news_big`
--

DROP TABLE IF EXISTS `z_news_big`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_news_big` (
  `hide_news` tinyint(1) NOT NULL DEFAULT 0,
  `date` int(11) NOT NULL DEFAULT 0,
  `author` varchar(255) NOT NULL,
  `author_id` int(11) NOT NULL,
  `image_id` int(3) NOT NULL DEFAULT 0,
  `topic` varchar(255) NOT NULL,
  `text` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_news_big`
--

LOCK TABLES `z_news_big` WRITE;
/*!40000 ALTER TABLE `z_news_big` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_news_big` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_news_tickers`
--

DROP TABLE IF EXISTS `z_news_tickers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_news_tickers` (
  `date` int(11) NOT NULL DEFAULT 1,
  `author` int(11) NOT NULL,
  `image_id` int(3) NOT NULL DEFAULT 0,
  `text` varchar(999) NOT NULL,
  `hide_ticker` int(11) NOT NULL,
  PRIMARY KEY (`date`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_news_tickers`
--

LOCK TABLES `z_news_tickers` WRITE;
/*!40000 ALTER TABLE `z_news_tickers` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_news_tickers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_ots_comunication`
--

DROP TABLE IF EXISTS `z_ots_comunication`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_ots_comunication` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `type` varchar(255) NOT NULL DEFAULT '',
  `action` varchar(255) NOT NULL DEFAULT '',
  `param1` varchar(255) NOT NULL DEFAULT '',
  `param2` varchar(255) NOT NULL DEFAULT '',
  `param3` varchar(255) NOT NULL DEFAULT '',
  `param4` varchar(255) NOT NULL DEFAULT '',
  `param5` varchar(255) NOT NULL DEFAULT '',
  `status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_ots_comunication`
--

LOCK TABLES `z_ots_comunication` WRITE;
/*!40000 ALTER TABLE `z_ots_comunication` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_ots_comunication` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_ots_comunication_donate`
--

DROP TABLE IF EXISTS `z_ots_comunication_donate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_ots_comunication_donate` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `type` varchar(255) NOT NULL DEFAULT '',
  `action` varchar(255) NOT NULL DEFAULT '',
  `param1` varchar(255) NOT NULL DEFAULT '',
  `param2` varchar(255) NOT NULL DEFAULT '',
  `param3` varchar(255) NOT NULL DEFAULT '',
  `param4` varchar(255) NOT NULL DEFAULT '',
  `param5` varchar(255) NOT NULL DEFAULT '',
  `status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_ots_comunication_donate`
--

LOCK TABLES `z_ots_comunication_donate` WRITE;
/*!40000 ALTER TABLE `z_ots_comunication_donate` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_ots_comunication_donate` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_polls`
--

DROP TABLE IF EXISTS `z_polls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_polls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `question` varchar(255) NOT NULL,
  `end` int(11) NOT NULL,
  `start` int(11) NOT NULL,
  `answers` int(11) NOT NULL,
  `votes_all` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_polls`
--

LOCK TABLES `z_polls` WRITE;
/*!40000 ALTER TABLE `z_polls` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_polls` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_polls_answers`
--

DROP TABLE IF EXISTS `z_polls_answers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_polls_answers` (
  `poll_id` int(11) NOT NULL,
  `answer_id` int(11) NOT NULL,
  `answer` varchar(255) NOT NULL,
  `votes` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_polls_answers`
--

LOCK TABLES `z_polls_answers` WRITE;
/*!40000 ALTER TABLE `z_polls_answers` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_polls_answers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_shop_history_item`
--

DROP TABLE IF EXISTS `z_shop_history_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_shop_history_item` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `to_name` varchar(255) NOT NULL DEFAULT '0',
  `to_account` int(11) NOT NULL DEFAULT 0,
  `from_nick` varchar(255) NOT NULL,
  `from_account` int(11) NOT NULL DEFAULT 0,
  `price` int(11) NOT NULL DEFAULT 0,
  `offer_id` int(11) NOT NULL DEFAULT 0,
  `trans_state` varchar(255) NOT NULL,
  `trans_start` int(11) NOT NULL DEFAULT 0,
  `trans_real` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_shop_history_item`
--

LOCK TABLES `z_shop_history_item` WRITE;
/*!40000 ALTER TABLE `z_shop_history_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_shop_history_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_shop_history_pacc`
--

DROP TABLE IF EXISTS `z_shop_history_pacc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_shop_history_pacc` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `to_name` varchar(255) NOT NULL DEFAULT '0',
  `to_account` int(11) NOT NULL DEFAULT 0,
  `from_nick` varchar(255) NOT NULL,
  `from_account` int(11) NOT NULL DEFAULT 0,
  `price` int(11) NOT NULL DEFAULT 0,
  `pacc_days` int(11) NOT NULL DEFAULT 0,
  `trans_state` varchar(255) NOT NULL,
  `trans_start` int(11) NOT NULL DEFAULT 0,
  `trans_real` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_shop_history_pacc`
--

LOCK TABLES `z_shop_history_pacc` WRITE;
/*!40000 ALTER TABLE `z_shop_history_pacc` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_shop_history_pacc` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_shop_offer`
--

DROP TABLE IF EXISTS `z_shop_offer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_shop_offer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `points` int(11) NOT NULL DEFAULT 0,
  `realpoints` int(11) NOT NULL DEFAULT 0,
  `itemid1` int(11) NOT NULL DEFAULT 0,
  `itemid2` int(11) NOT NULL DEFAULT 0,
  `itemid3` int(11) NOT NULL DEFAULT 0,
  `count1` int(11) NOT NULL DEFAULT 0,
  `count2` int(11) NOT NULL DEFAULT 0,
  `count3` int(11) NOT NULL DEFAULT 0,
  `offer_type` varchar(255) DEFAULT NULL,
  `offer_description` text NOT NULL,
  `prazo` varchar(255) NOT NULL,
  `offer_name` varchar(255) NOT NULL,
  `pid` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_shop_offer`
--

LOCK TABLES `z_shop_offer` WRITE;
/*!40000 ALTER TABLE `z_shop_offer` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_shop_offer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_shop_points_bought`
--

DROP TABLE IF EXISTS `z_shop_points_bought`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_shop_points_bought` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `amount` int(11) NOT NULL,
  `type` varchar(255) NOT NULL,
  `accountid` int(11) NOT NULL,
  `code` varchar(255) NOT NULL,
  `paypalmail` varchar(255) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_shop_points_bought`
--

LOCK TABLES `z_shop_points_bought` WRITE;
/*!40000 ALTER TABLE `z_shop_points_bought` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_shop_points_bought` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_spells`
--

DROP TABLE IF EXISTS `z_spells`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_spells` (
  `name` varchar(255) NOT NULL,
  `spell` varchar(255) NOT NULL,
  `spell_type` varchar(255) NOT NULL,
  `mana` int(11) NOT NULL DEFAULT 0,
  `lvl` int(11) NOT NULL DEFAULT 0,
  `mlvl` int(11) NOT NULL DEFAULT 0,
  `soul` int(11) NOT NULL DEFAULT 0,
  `pacc` varchar(255) NOT NULL,
  `vocations` varchar(255) NOT NULL,
  `conj_count` int(11) NOT NULL DEFAULT 0,
  `hide_spell` int(11) NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_spells`
--

LOCK TABLES `z_spells` WRITE;
/*!40000 ALTER TABLE `z_spells` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_spells` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `z_tracker`
--

DROP TABLE IF EXISTS `z_tracker`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z_tracker` (
  `account` varchar(255) NOT NULL,
  `type` int(11) NOT NULL,
  `status` int(11) NOT NULL,
  `text` text NOT NULL,
  `id` int(11) NOT NULL,
  `subject` varchar(255) NOT NULL,
  `typetracker` int(11) NOT NULL,
  `tag` int(11) NOT NULL,
  `priority` int(11) NOT NULL,
  `reply` int(11) NOT NULL,
  `who` int(11) NOT NULL,
  `uid` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `z_tracker`
--

LOCK TABLES `z_tracker` WRITE;
/*!40000 ALTER TABLE `z_tracker` DISABLE KEYS */;
/*!40000 ALTER TABLE `z_tracker` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `zaypay_payment`
--

DROP TABLE IF EXISTS `zaypay_payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `zaypay_payment` (
  `payID` bigint(20) NOT NULL,
  `account_id` int(11) NOT NULL,
  `status` varchar(255) NOT NULL,
  PRIMARY KEY (`payID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zaypay_payment`
--

LOCK TABLES `zaypay_payment` WRITE;
/*!40000 ALTER TABLE `zaypay_payment` DISABLE KEYS */;
/*!40000 ALTER TABLE `zaypay_payment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'avatar'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-08-15 13:15:51
