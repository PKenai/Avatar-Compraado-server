-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Tempo de geração: 21/07/2026 às 19:56
-- Versão do servidor: 8.2.0
-- Versão do PHP: 8.3.0

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `avatar`
--

-- --------------------------------------------------------

--
-- Estrutura para tabela `accounts`
--

CREATE TABLE `accounts` (
  `id` int NOT NULL,
  `name` varchar(32) NOT NULL DEFAULT '',
  `password` varchar(255) NOT NULL,
  `salt` varchar(40) NOT NULL DEFAULT '',
  `premdays` int NOT NULL DEFAULT '0',
  `lastday` int UNSIGNED NOT NULL DEFAULT '0',
  `email` varchar(255) NOT NULL DEFAULT '',
  `key` varchar(32) NOT NULL DEFAULT '0',
  `blocked` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'internal usage',
  `warnings` int NOT NULL DEFAULT '0',
  `group_id` int NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Despejando dados para a tabela `accounts`
--

INSERT INTO `accounts` (`id`, `name`, `password`, `salt`, `premdays`, `lastday`, `email`, `key`, `blocked`, `warnings`, `group_id`) VALUES
(1, '1', '356a192b7913b04c54574d18c28d46e6395428ab', '', 65535, 0, '', '0', 0, 0, 1),
(2, 'minhaconta', 'e7a959133960a74cf0da6c4517326348d8bca6c1', 'ixW6yqY7A4w3792fk5e-OCbydBac9La7y4FH2Wd', 0, 0, '', '0', 0, 0, 1),
(3, 'camiza', 'f346a797a074bf34d5c879d4d17b508e0e8c1232', 'B9y8mRW3a57xZUDPzvZ-KLKiCPp8VgES3Vq2A6s', 0, 0, '', '0', 0, 0, 1),
(4, 'contadois', 'e7a959133960a74cf0da6c4517326348d8bca6c1', 'ixW6yqY7A4w3792fk5e-OCbydBac9La7y4FH2Wd', 0, 0, '', '0', 0, 0, 1),
(5, 'camizas', 'f346a797a074bf34d5c879d4d17b508e0e8c1232', 'B9y8mRW3a57xZUDPzvZ-KLKiCPp8VgES3Vq2A6s', 0, 0, '', '0', 0, 0, 1);

--
-- Acionadores `accounts`
--
DELIMITER $$
CREATE TRIGGER `ondelete_accounts` BEFORE DELETE ON `accounts` FOR EACH ROW BEGIN
	DELETE FROM `bans` WHERE `type` IN (3, 4) AND `value` = OLD.`id`;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `account_viplist`
--

CREATE TABLE `account_viplist` (
  `account_id` int NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `player_id` int NOT NULL,
  `description` varchar(128) NOT NULL,
  `icon` int UNSIGNED NOT NULL,
  `notify` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `auction_system`
--

CREATE TABLE `auction_system` (
  `id` int NOT NULL,
  `player` int DEFAULT NULL,
  `item_id` int DEFAULT NULL,
  `item_name` varchar(255) DEFAULT NULL,
  `count` int DEFAULT NULL,
  `desc` varchar(255) DEFAULT NULL,
  `cost` int DEFAULT NULL,
  `date` int DEFAULT NULL,
  `expired` smallint DEFAULT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estrutura para tabela `bans`
--

CREATE TABLE `bans` (
  `id` int UNSIGNED NOT NULL,
  `type` tinyint(1) NOT NULL COMMENT '1 - ip, 2 - player, 3 - account, 4 - notation',
  `value` int UNSIGNED NOT NULL COMMENT 'ip - ip address, player - player_id, account - account_id, notation - account_id',
  `param` int UNSIGNED NOT NULL COMMENT 'ip - mask, player - type (1 - report, 2 - lock, 3 - ban), account - player, notation - player',
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `expires` int NOT NULL DEFAULT '-1',
  `added` int UNSIGNED NOT NULL,
  `admin_id` int UNSIGNED NOT NULL DEFAULT '0',
  `comment` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `environment_killers`
--

CREATE TABLE `environment_killers` (
  `kill_id` int NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `global_storage`
--

CREATE TABLE `global_storage` (
  `key` varchar(32) NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `value` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `guilds`
--

CREATE TABLE `guilds` (
  `id` int NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL,
  `ownerid` int NOT NULL,
  `creationdata` int NOT NULL,
  `checkdata` int NOT NULL,
  `motd` varchar(255) NOT NULL,
  `balance` bigint UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Acionadores `guilds`
--
DELIMITER $$
CREATE TRIGGER `oncreate_guilds` AFTER INSERT ON `guilds` FOR EACH ROW BEGIN
	INSERT INTO `guild_ranks` (`name`, `level`, `guild_id`) VALUES ('Leader', 3, NEW.`id`);
	INSERT INTO `guild_ranks` (`name`, `level`, `guild_id`) VALUES ('Vice-Leader', 2, NEW.`id`);
	INSERT INTO `guild_ranks` (`name`, `level`, `guild_id`) VALUES ('Member', 1, NEW.`id`);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `ondelete_guilds` BEFORE DELETE ON `guilds` FOR EACH ROW BEGIN
	UPDATE `players` SET `guildnick` = '', `rank_id` = 0 WHERE `rank_id` IN (SELECT `id` FROM `guild_ranks` WHERE `guild_id` = OLD.`id`);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `guild_invites`
--

CREATE TABLE `guild_invites` (
  `player_id` int NOT NULL DEFAULT '0',
  `guild_id` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `guild_kills`
--

CREATE TABLE `guild_kills` (
  `id` int NOT NULL,
  `guild_id` int NOT NULL,
  `war_id` int NOT NULL,
  `death_id` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `guild_ranks`
--

CREATE TABLE `guild_ranks` (
  `id` int NOT NULL,
  `guild_id` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `level` int NOT NULL COMMENT '1 - leader, 2 - vice leader, 3 - member'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `guild_wars`
--

CREATE TABLE `guild_wars` (
  `id` int NOT NULL,
  `guild_id` int NOT NULL,
  `enemy_id` int NOT NULL,
  `begin` bigint NOT NULL DEFAULT '0',
  `end` bigint NOT NULL DEFAULT '0',
  `frags` int UNSIGNED NOT NULL DEFAULT '0',
  `payment` bigint UNSIGNED NOT NULL DEFAULT '0',
  `guild_kills` int UNSIGNED NOT NULL DEFAULT '0',
  `enemy_kills` int UNSIGNED NOT NULL DEFAULT '0',
  `status` tinyint UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `houses`
--

CREATE TABLE `houses` (
  `id` int UNSIGNED NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `owner` int NOT NULL,
  `paid` int UNSIGNED NOT NULL DEFAULT '0',
  `warnings` int NOT NULL DEFAULT '0',
  `lastwarning` int UNSIGNED NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL,
  `town` int UNSIGNED NOT NULL DEFAULT '0',
  `size` int UNSIGNED NOT NULL DEFAULT '0',
  `price` int UNSIGNED NOT NULL DEFAULT '0',
  `rent` int UNSIGNED NOT NULL DEFAULT '0',
  `doors` int UNSIGNED NOT NULL DEFAULT '0',
  `beds` int UNSIGNED NOT NULL DEFAULT '0',
  `tiles` int UNSIGNED NOT NULL DEFAULT '0',
  `guild` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `clear` tinyint UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Despejando dados para a tabela `houses`
--

INSERT INTO `houses` (`id`, `world_id`, `owner`, `paid`, `warnings`, `lastwarning`, `name`, `town`, `size`, `price`, `rent`, `doors`, `beds`, `tiles`, `guild`, `clear`) VALUES
(4, 0, 0, 0, 0, 0, 'Ba Sing Se House 27', 1, 17, 108000, 0, 0, 1, 46, 0, 0),
(5, 0, 0, 0, 0, 0, 'Ba Sing Se House 47', 1, 13, 90000, 0, 0, 2, 39, 0, 0),
(6, 0, 0, 0, 0, 0, 'Ba Sing Se House 48', 1, 10, 66000, 0, 0, 1, 32, 0, 0),
(7, 0, 0, 0, 0, 0, 'Ba Sing Se House 49', 1, 23, 144000, 0, 0, 1, 45, 0, 0),
(8, 0, 0, 0, 0, 0, 'Ba Sing Se House 50', 1, 14, 90000, 0, 0, 1, 27, 0, 0),
(9, 0, 0, 0, 0, 0, 'Ba Sing Se House 1', 1, 8, 54000, 0, 0, 1, 21, 0, 0),
(10, 0, 0, 0, 0, 0, 'Ba Sing Se House 37', 1, 42, 264000, 0, 0, 2, 97, 0, 0),
(11, 0, 0, 0, 0, 0, 'Ba Sing Se House 2', 1, 21, 132000, 0, 0, 1, 51, 0, 0),
(12, 0, 0, 0, 0, 0, 'Ba Sing Se House 3', 1, 18, 120000, 0, 0, 2, 35, 0, 0),
(13, 0, 0, 0, 0, 0, 'Ba Sing Se House 4', 1, 26, 162000, 0, 0, 1, 43, 0, 0),
(14, 0, 0, 0, 0, 0, 'Ba Sing Se House 5', 1, 10, 66000, 0, 0, 1, 30, 0, 0),
(16, 0, 0, 0, 0, 0, 'Ba Sing Se House 7', 1, 18, 114000, 0, 0, 1, 36, 0, 0),
(21, 0, 0, 0, 0, 0, 'Ba Sing Se House 8', 1, 16, 102000, 0, 0, 1, 40, 0, 0),
(22, 0, 0, 0, 0, 0, 'Ba Sing Se House 10', 1, 40, 252000, 0, 0, 2, 62, 0, 0),
(23, 0, 0, 0, 0, 0, 'Ba Sing Se House 11', 1, 40, 252000, 0, 0, 2, 62, 0, 0),
(24, 0, 0, 0, 0, 0, 'Ba Sing Se House 12', 1, 16, 102000, 0, 0, 1, 40, 0, 0),
(25, 0, 0, 0, 0, 0, 'Ba Sing Se House 13', 1, 16, 102000, 0, 0, 1, 39, 0, 0),
(26, 0, 0, 0, 0, 0, 'Ba Sing Se House 14', 1, 48, 300000, 0, 0, 2, 100, 0, 0),
(27, 0, 0, 0, 0, 0, 'Ba Sing Se House 15', 1, 48, 300000, 0, 0, 2, 93, 0, 0),
(28, 0, 0, 0, 0, 0, 'Ba Sing Se House 16', 1, 52, 324000, 0, 0, 2, 105, 0, 0),
(29, 0, 0, 0, 0, 0, 'Ba Sing Se House 17', 1, 52, 324000, 0, 0, 2, 90, 0, 0),
(30, 0, 0, 0, 0, 0, 'Ba Sing Se House 9', 1, 16, 102000, 0, 0, 1, 40, 0, 0),
(31, 0, 0, 0, 0, 0, 'Ba Sing Se House 18', 1, 52, 324000, 0, 0, 2, 88, 0, 0),
(32, 0, 0, 0, 0, 0, 'Ba Sing Se House 19', 1, 58, 354000, 0, 0, 1, 108, 0, 0),
(33, 0, 0, 0, 0, 0, 'Ba Sing Se House 20', 1, 26, 162000, 0, 0, 1, 40, 0, 0),
(34, 0, 0, 0, 0, 0, 'Ba Sing Se House 21', 1, 16, 102000, 0, 0, 1, 38, 0, 0),
(35, 0, 0, 0, 0, 0, 'Ba Sing Se House 22', 1, 14, 90000, 0, 0, 1, 25, 0, 0),
(36, 0, 0, 0, 0, 0, 'Ba Sing Se House 23', 1, 14, 90000, 0, 0, 1, 25, 0, 0),
(37, 0, 0, 0, 0, 0, 'Ba Sing Se House 24', 1, 26, 162000, 0, 0, 1, 45, 0, 0),
(38, 0, 0, 0, 0, 0, 'Ba Sing Se House 25', 1, 26, 162000, 0, 0, 1, 45, 0, 0),
(39, 0, 0, 0, 0, 0, 'Ba Sing Se House 26', 1, 61, 378000, 0, 0, 2, 111, 0, 0),
(40, 0, 0, 0, 0, 0, 'Ba Sing Se House 28', 1, 79, 492000, 0, 0, 3, 137, 0, 0),
(41, 0, 0, 0, 0, 0, 'Ba Sing Se House 29', 1, 68, 426000, 0, 0, 3, 134, 0, 0),
(42, 0, 0, 0, 0, 0, 'Ba Sing Se House 30', 1, 38, 234000, 0, 0, 1, 66, 0, 0),
(43, 0, 0, 0, 0, 0, 'Ba Sing Se House 31', 1, 63, 396000, 0, 0, 3, 119, 0, 0),
(44, 0, 0, 0, 0, 0, 'Ba Sing Se House 32', 1, 18, 114000, 0, 0, 1, 47, 0, 0),
(45, 0, 0, 0, 0, 0, 'Ba Sing Se House 33', 1, 12, 78000, 0, 0, 1, 24, 0, 0),
(46, 0, 0, 0, 0, 0, 'Ba Sing Se House 34', 1, 12, 78000, 0, 0, 1, 36, 0, 0),
(47, 0, 0, 0, 0, 0, 'Ba Sing Se House 35', 1, 84, 516000, 0, 0, 2, 150, 0, 0),
(49, 0, 0, 0, 0, 0, 'Ba Sing Se House 36', 1, 22, 138000, 0, 0, 1, 36, 0, 0),
(50, 0, 0, 0, 0, 0, 'Ba Sing Se House 38', 1, 16, 96000, 0, 0, 0, 36, 0, 0),
(51, 0, 0, 0, 0, 0, 'Ba Sing Se House 39', 1, 22, 132000, 0, 0, 0, 53, 0, 0),
(54, 0, 0, 0, 0, 0, 'Ba Sing Se House 40', 1, 29, 174000, 0, 0, 0, 64, 0, 0),
(55, 0, 0, 0, 0, 0, 'Ba Sing Se House 41', 1, 56, 336000, 0, 0, 0, 98, 0, 0),
(56, 0, 0, 0, 0, 0, 'Ba Sing Se House 42', 1, 69, 414000, 0, 0, 0, 120, 0, 0),
(57, 0, 0, 0, 0, 0, 'Ba Sing Se House 43', 1, 26, 156000, 0, 0, 0, 57, 0, 0),
(58, 0, 0, 0, 0, 0, 'Ba Sing Se House 44', 1, 15, 90000, 0, 0, 0, 35, 0, 0),
(59, 0, 0, 0, 0, 0, 'Ba Sing Se House 45', 1, 68, 408000, 0, 0, 0, 119, 0, 0),
(60, 0, 0, 0, 0, 0, 'Ba Sing Se House 46', 1, 12, 72000, 0, 0, 0, 32, 0, 0),
(68, 0, 0, 0, 0, 0, 'South Air Temple House 1', 3, 14, 90000, 0, 0, 1, 36, 0, 0),
(69, 0, 0, 0, 0, 0, 'South Air Temple House 2', 3, 14, 90000, 0, 0, 1, 36, 0, 0),
(70, 0, 0, 0, 0, 0, 'South Air Temple House 3', 3, 14, 90000, 0, 0, 1, 36, 0, 0),
(71, 0, 0, 0, 0, 0, 'South Air Temple House 4', 3, 14, 90000, 0, 0, 1, 36, 0, 0),
(72, 0, 0, 0, 0, 0, 'South Air Temple House 5', 3, 16, 102000, 0, 0, 1, 40, 0, 0),
(73, 0, 0, 0, 0, 0, 'South Air Temple House 6', 3, 7, 48000, 0, 0, 1, 20, 0, 0),
(74, 0, 0, 0, 0, 0, 'South Air Temple House 7', 3, 13, 84000, 0, 0, 1, 35, 0, 0),
(75, 0, 0, 0, 0, 0, 'South Air Temple House 8', 3, 6, 42000, 0, 0, 1, 24, 0, 0),
(77, 0, 0, 0, 0, 0, 'South Air Temple House 10', 3, 14, 90000, 0, 0, 1, 36, 0, 0),
(78, 0, 0, 0, 0, 0, 'South Air Temple House 11', 3, 14, 90000, 0, 0, 1, 36, 0, 0),
(79, 0, 0, 0, 0, 0, 'South Air Temple House 12', 3, 14, 90000, 0, 0, 1, 36, 0, 0),
(80, 0, 0, 0, 0, 0, 'South Air Temple House 13', 3, 10, 66000, 0, 0, 1, 25, 0, 0),
(81, 0, 0, 0, 0, 0, 'South Air Temple House 14', 3, 10, 66000, 0, 0, 1, 30, 0, 0),
(82, 0, 0, 0, 0, 0, 'South Air Temple House 15', 3, 8, 54000, 0, 0, 1, 16, 0, 0),
(83, 0, 0, 0, 0, 0, 'South Air Temple House 16', 3, 8, 54000, 0, 0, 1, 16, 0, 0),
(84, 0, 0, 0, 0, 0, 'South Air Temple House 17', 3, 10, 66000, 0, 0, 1, 30, 0, 0),
(85, 0, 0, 0, 0, 0, 'South Air Temple House 18', 3, 8, 54000, 0, 0, 1, 16, 0, 0),
(86, 0, 0, 0, 0, 0, 'South Air Temple House 19', 3, 13, 84000, 0, 0, 1, 35, 0, 0),
(87, 0, 0, 0, 0, 0, 'South Air Temple House 20', 3, 8, 54000, 0, 0, 1, 16, 0, 0),
(88, 0, 0, 0, 0, 0, 'South Air Temple House 21', 3, 8, 54000, 0, 0, 1, 16, 0, 0),
(89, 0, 0, 0, 0, 0, 'South Air Temple House 22', 3, 8, 54000, 0, 0, 1, 20, 0, 0),
(90, 0, 0, 0, 0, 0, 'South Air Temple House 23', 3, 21, 138000, 0, 0, 2, 35, 0, 0),
(91, 0, 0, 0, 0, 0, 'South Air Temple House 24', 3, 11, 72000, 0, 0, 1, 20, 0, 0),
(92, 0, 0, 0, 0, 0, 'South Air Temple House 25', 3, 15, 96000, 0, 0, 1, 30, 0, 0),
(93, 0, 0, 0, 0, 0, 'South Air Temple House 26', 3, 3, 24000, 0, 0, 1, 15, 0, 0),
(94, 0, 0, 0, 0, 0, 'South Air Temple House 27', 3, 7, 48000, 0, 0, 1, 16, 0, 0),
(96, 0, 0, 0, 0, 0, 'North Water Tribe House 9', 4, 18, 114000, 0, 0, 1, 44, 0, 0),
(97, 0, 0, 0, 0, 0, 'North Water Tribe House 10', 4, 21, 132000, 0, 0, 1, 39, 0, 0),
(98, 0, 0, 0, 0, 0, 'North Water Tribe House 11', 4, 13, 84000, 0, 0, 1, 24, 0, 0),
(99, 0, 0, 0, 0, 0, 'North Water Tribe House 12', 4, 12, 78000, 0, 0, 1, 18, 0, 0),
(100, 0, 0, 0, 0, 0, 'North Water Tribe House 1', 4, 26, 162000, 0, 0, 1, 39, 0, 0),
(101, 0, 0, 0, 0, 0, 'North Water Tribe House 2', 4, 26, 162000, 0, 0, 1, 47, 0, 0),
(102, 0, 0, 0, 0, 0, 'North Water Tribe House 3', 4, 56, 348000, 0, 0, 2, 91, 0, 0),
(103, 0, 0, 0, 0, 0, 'North Water Tribe House 4', 4, 10, 66000, 0, 0, 1, 21, 0, 0),
(104, 0, 0, 0, 0, 0, 'North Water Tribe House 5', 4, 12, 78000, 0, 0, 1, 24, 0, 0),
(105, 0, 0, 0, 0, 0, 'North Water Tribe House 6', 4, 28, 174000, 0, 0, 1, 54, 0, 0),
(106, 0, 0, 0, 0, 0, 'North Water Tribe House 7', 4, 14, 90000, 0, 0, 1, 26, 0, 0),
(107, 0, 0, 0, 0, 0, 'North Water Tribe House 8', 4, 13, 84000, 0, 0, 1, 20, 0, 0),
(108, 0, 0, 0, 0, 0, 'Fire Nation Capital House 1', 5, 24, 144000, 0, 0, 0, 60, 0, 0),
(109, 0, 0, 0, 0, 0, 'Fire Nation Capital House 2', 5, 24, 144000, 0, 0, 0, 60, 0, 0),
(110, 0, 0, 0, 0, 0, 'Fire Nation Capital House 3', 5, 45, 282000, 0, 0, 2, 85, 0, 0),
(111, 0, 0, 0, 0, 0, 'Fire Nation Capital House 4', 5, 45, 282000, 0, 0, 2, 85, 0, 0),
(112, 0, 0, 0, 0, 0, 'Fire Nation Capital House 5', 5, 13, 84000, 0, 1, 1, 35, 0, 0),
(113, 0, 0, 0, 0, 0, 'Fire Nation Capital House 6', 5, 14, 90000, 0, 1, 1, 36, 0, 0),
(114, 0, 0, 0, 0, 0, 'Fire Nation Capital House 7', 5, 7, 48000, 0, 1, 1, 25, 0, 0),
(115, 0, 0, 0, 0, 0, 'Fire Nation Capital House 8', 5, 4, 30000, 0, 1, 1, 20, 0, 0),
(116, 0, 0, 0, 0, 0, 'Fire Nation Capital House 9', 5, 10, 66000, 0, 1, 1, 30, 0, 0),
(117, 0, 0, 0, 0, 0, 'Fire Nation Capital House 10', 5, 8, 54000, 0, 1, 1, 28, 0, 0),
(118, 0, 0, 0, 0, 0, 'Fire Nation Capital House 11', 5, 36, 228000, 0, 0, 2, 71, 0, 0),
(119, 0, 0, 0, 0, 0, 'Fire Nation Capital House 12', 5, 104, 642000, 0, 0, 3, 187, 0, 0),
(120, 0, 0, 0, 0, 0, 'Fire Nation Capital House 13', 5, 46, 282000, 0, 0, 1, 83, 0, 0),
(121, 0, 0, 0, 0, 0, 'Fire Nation Capital House 14', 5, 46, 282000, 0, 0, 1, 83, 0, 0),
(122, 0, 0, 0, 0, 0, 'Fire Nation Capital House 15', 5, 24, 156000, 0, 0, 2, 40, 0, 0),
(123, 0, 0, 0, 0, 0, 'Fire Nation Capital House 16', 5, 16, 102000, 0, 0, 1, 38, 0, 0),
(124, 0, 0, 0, 0, 0, 'Fire Nation Capital House 17', 5, 69, 426000, 0, 0, 2, 120, 0, 0),
(125, 0, 0, 0, 0, 0, 'Fire Nation Capital House 18', 5, 50, 306000, 0, 0, 1, 95, 0, 0),
(126, 0, 0, 0, 0, 0, 'Fire Nation Capital House 19', 5, 58, 354000, 0, 0, 1, 111, 0, 0),
(127, 0, 0, 0, 0, 0, 'Fire Nation Capital House 20', 5, 70, 426000, 0, 0, 1, 124, 0, 0),
(128, 0, 0, 0, 0, 0, 'Fire Nation Capital House 21', 5, 21, 132000, 0, 0, 1, 48, 0, 0),
(129, 0, 0, 0, 0, 0, 'Fire Nation Capital House 22', 5, 21, 132000, 0, 0, 1, 35, 0, 0),
(130, 0, 0, 0, 0, 0, 'Fire Nation Capital House 23', 5, 13, 84000, 0, 0, 1, 28, 0, 0),
(131, 0, 0, 0, 0, 0, 'Fire Nation Capital House 24', 5, 164, 1014000, 0, 0, 5, 294, 0, 0),
(132, 0, 0, 0, 0, 0, 'Fire Nation Capital House 25', 5, 14, 90000, 0, 0, 1, 29, 0, 0),
(133, 0, 0, 0, 0, 0, 'Fire Nation Capital House 26', 5, 14, 90000, 0, 0, 1, 30, 0, 0),
(134, 0, 0, 0, 0, 0, 'Fire Nation Capital House 27', 5, 14, 90000, 0, 0, 1, 29, 0, 0),
(135, 0, 0, 0, 0, 0, 'Fire Nation Capital House 28', 5, 14, 90000, 0, 0, 1, 29, 0, 0),
(136, 0, 0, 0, 0, 0, 'Fire Nation Capital House 29', 5, 12, 78000, 0, 0, 1, 34, 0, 0),
(137, 0, 0, 0, 0, 0, 'Fire Nation Capital House 30', 5, 50, 318000, 0, 0, 3, 77, 0, 0),
(138, 0, 0, 0, 0, 0, 'Fire Nation Capital House 31', 5, 16, 102000, 0, 0, 1, 21, 0, 0),
(139, 0, 0, 0, 0, 0, 'Fire Nation Capital House 32', 5, 82, 504000, 0, 0, 2, 140, 0, 0),
(147, 0, 0, 0, 0, 0, 'Ba Sing Se House 51', 1, 82, 516000, 0, 0, 4, 137, 0, 0),
(148, 0, 0, 0, 0, 0, 'Ba Sing Se House 52', 1, 63, 390000, 0, 0, 2, 111, 0, 0),
(149, 0, 0, 0, 0, 0, 'Ba Sing Se House 53', 1, 72, 444000, 0, 0, 2, 120, 0, 0),
(150, 0, 0, 0, 0, 0, 'Ba Sing Se House 54', 1, 29, 180000, 0, 0, 1, 49, 0, 0),
(151, 0, 0, 0, 0, 0, 'Ba Sing Se House 55', 1, 19, 120000, 0, 0, 1, 37, 0, 0),
(152, 0, 0, 0, 0, 0, 'Ba Sing Se House 56', 1, 16, 102000, 0, 0, 1, 24, 0, 0),
(153, 0, 0, 0, 0, 0, 'Ba Sing Se House 57', 1, 19, 120000, 0, 0, 1, 37, 0, 0),
(154, 0, 0, 0, 0, 0, 'Ba Sing Se House 58', 1, 19, 120000, 0, 0, 1, 40, 0, 0),
(155, 0, 0, 0, 0, 0, 'Ba Sing Se House 59', 1, 16, 102000, 0, 0, 1, 24, 0, 0),
(156, 0, 0, 0, 0, 0, 'Ba Sing Se House 60', 1, 19, 120000, 0, 0, 1, 37, 0, 0),
(157, 0, 0, 0, 0, 0, 'Ba Sing Se House 61', 1, 19, 120000, 0, 0, 1, 37, 0, 0),
(158, 0, 0, 0, 0, 0, 'Ba Sing Se House 62', 1, 19, 120000, 0, 0, 1, 32, 0, 0),
(159, 0, 0, 0, 0, 0, 'Ba Sing Se House 63', 1, 16, 102000, 0, 0, 1, 21, 0, 0),
(160, 0, 0, 0, 0, 0, 'Ba Sing Se House 64', 1, 16, 102000, 0, 0, 1, 24, 0, 0),
(161, 0, 0, 0, 0, 0, 'Ba Sing Se House 65', 1, 19, 120000, 0, 0, 1, 30, 0, 0),
(162, 0, 0, 0, 0, 0, 'Ba Sing Se House 66', 1, 19, 120000, 0, 0, 1, 25, 0, 0),
(164, 0, 0, 0, 0, 0, 'Unnamed House #164', 3, 6, 36000, 0, 1, 0, 12, 0, 0),
(166, 0, 0, 0, 0, 0, 'Unnamed House #166', 5, 6, 36000, 0, 1, 0, 12, 0, 0),
(167, 0, 0, 0, 0, 0, 'Unnamed House #167', 4, 6, 36000, 0, 1, 0, 12, 0, 0),
(168, 0, 0, 0, 0, 0, 'Ba Sing Se House 67', 1, 27, 180000, 0, 0, 3, 65, 0, 0),
(169, 0, 0, 0, 0, 0, 'Ba Sing Se House 68', 1, 34, 216000, 0, 0, 2, 73, 0, 0),
(171, 0, 0, 0, 0, 0, 'Ba Sing Se House 69', 1, 22, 138000, 0, 0, 1, 41, 0, 0),
(172, 0, 0, 0, 0, 0, 'Unnamed House #172', 1, 6, 36000, 0, 1, 0, 12, 0, 0);

-- --------------------------------------------------------

--
-- Estrutura para tabela `house_auctions`
--

CREATE TABLE `house_auctions` (
  `house_id` int UNSIGNED NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `player_id` int NOT NULL,
  `bid` int UNSIGNED NOT NULL DEFAULT '0',
  `limit` int UNSIGNED NOT NULL DEFAULT '0',
  `endtime` bigint UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `house_data`
--

CREATE TABLE `house_data` (
  `house_id` int UNSIGNED NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `data` longblob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `house_lists`
--

CREATE TABLE `house_lists` (
  `house_id` int UNSIGNED NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `listid` int NOT NULL,
  `list` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `killers`
--

CREATE TABLE `killers` (
  `id` int NOT NULL,
  `death_id` int NOT NULL,
  `final_hit` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `unjustified` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `war` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `market_history`
--

CREATE TABLE `market_history` (
  `id` int UNSIGNED NOT NULL,
  `player_id` int NOT NULL,
  `sale` tinyint(1) NOT NULL DEFAULT '0',
  `itemtype` int UNSIGNED NOT NULL,
  `amount` smallint UNSIGNED NOT NULL,
  `price` int UNSIGNED NOT NULL DEFAULT '0',
  `expires_at` bigint UNSIGNED NOT NULL,
  `inserted` bigint UNSIGNED NOT NULL,
  `state` tinyint UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `market_offers`
--

CREATE TABLE `market_offers` (
  `id` int UNSIGNED NOT NULL,
  `player_id` int NOT NULL,
  `sale` tinyint(1) NOT NULL DEFAULT '0',
  `itemtype` int UNSIGNED NOT NULL,
  `amount` smallint UNSIGNED NOT NULL,
  `created` bigint UNSIGNED NOT NULL,
  `anonymous` tinyint(1) NOT NULL DEFAULT '0',
  `price` int UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `players`
--

CREATE TABLE `players` (
  `id` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `group_id` int NOT NULL DEFAULT '1',
  `account_id` int NOT NULL DEFAULT '0',
  `level` int NOT NULL DEFAULT '1',
  `vocation` int NOT NULL DEFAULT '0',
  `health` int NOT NULL DEFAULT '150',
  `healthmax` int NOT NULL DEFAULT '150',
  `experience` bigint UNSIGNED NOT NULL DEFAULT '0',
  `lookbody` int NOT NULL DEFAULT '0',
  `lookfeet` int NOT NULL DEFAULT '0',
  `lookhead` int NOT NULL DEFAULT '0',
  `looklegs` int NOT NULL DEFAULT '0',
  `looktype` int NOT NULL DEFAULT '136',
  `lookaddons` int NOT NULL DEFAULT '0',
  `lookmount` int NOT NULL DEFAULT '0',
  `maglevel` int NOT NULL DEFAULT '0',
  `mana` int NOT NULL DEFAULT '0',
  `manamax` int NOT NULL DEFAULT '0',
  `manaspent` bigint UNSIGNED NOT NULL DEFAULT '0',
  `soul` int UNSIGNED NOT NULL DEFAULT '0',
  `town_id` int NOT NULL DEFAULT '0',
  `posx` int NOT NULL DEFAULT '0',
  `posy` int NOT NULL DEFAULT '0',
  `posz` int NOT NULL DEFAULT '0',
  `conditions` blob NOT NULL,
  `cap` int NOT NULL DEFAULT '0',
  `sex` int NOT NULL DEFAULT '0',
  `lastlogin` bigint UNSIGNED NOT NULL DEFAULT '0',
  `lastip` int UNSIGNED NOT NULL DEFAULT '0',
  `save` tinyint(1) NOT NULL DEFAULT '1',
  `skull` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `skulltime` int NOT NULL DEFAULT '0',
  `rank_id` int NOT NULL DEFAULT '0',
  `guildnick` varchar(255) NOT NULL DEFAULT '',
  `lastlogout` bigint UNSIGNED NOT NULL DEFAULT '0',
  `blessings` tinyint NOT NULL DEFAULT '0',
  `pvp_blessing` tinyint(1) NOT NULL DEFAULT '0',
  `balance` bigint UNSIGNED NOT NULL DEFAULT '0',
  `stamina` bigint UNSIGNED NOT NULL DEFAULT '151200000' COMMENT 'stored in miliseconds',
  `direction` int NOT NULL DEFAULT '2',
  `loss_experience` int NOT NULL DEFAULT '100',
  `loss_mana` int NOT NULL DEFAULT '100',
  `loss_skills` int NOT NULL DEFAULT '100',
  `loss_containers` int NOT NULL DEFAULT '100',
  `loss_items` int NOT NULL DEFAULT '100',
  `premend` int NOT NULL DEFAULT '0' COMMENT 'NOT IN USE BY THE SERVER',
  `online` tinyint(1) NOT NULL DEFAULT '0',
  `marriage` int UNSIGNED NOT NULL DEFAULT '0',
  `promotion` int NOT NULL DEFAULT '0',
  `deleted` int NOT NULL DEFAULT '0',
  `description` varchar(255) NOT NULL DEFAULT '',
  `resets` int NOT NULL DEFAULT '0',
  `timeOnline` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Despejando dados para a tabela `players`
--

INSERT INTO `players` (`id`, `name`, `world_id`, `group_id`, `account_id`, `level`, `vocation`, `health`, `healthmax`, `experience`, `lookbody`, `lookfeet`, `lookhead`, `looklegs`, `looktype`, `lookaddons`, `lookmount`, `maglevel`, `mana`, `manamax`, `manaspent`, `soul`, `town_id`, `posx`, `posy`, `posz`, `conditions`, `cap`, `sex`, `lastlogin`, `lastip`, `save`, `skull`, `skulltime`, `rank_id`, `guildnick`, `lastlogout`, `blessings`, `pvp_blessing`, `balance`, `stamina`, `direction`, `loss_experience`, `loss_mana`, `loss_skills`, `loss_containers`, `loss_items`, `premend`, `online`, `marriage`, `promotion`, `deleted`, `description`, `resets`, `timeOnline`) VALUES
(1, 'Account Manager', 0, 1, 1, 1, 0, 150, 150, 0, 0, 0, 0, 0, 110, 0, 0, 0, 0, 0, 0, 0, 0, 853, 921, 7, '', 400, 0, 1784656345, 16777343, 0, 0, 0, 0, '', 0, 0, 0, 0, 201660000, 0, 100, 100, 100, 100, 100, 0, 0, 0, 0, 0, '', 0, 1784656158),
(2, 'Heroi Teste', 0, 1, 2, 8, 0, 360, 360, 4200, 68, 76, 78, 39, 128, 0, 0, 0, 0, 0, 0, 100, 2, 500, 500, 7, 0x30, 750, 1, 0, 0, 1, 0, 0, 0, '', 0, 0, 0, 0, 151200000, 2, 100, 100, 100, 100, 100, 0, 0, 0, 0, 0, '', 0, 0),
(3, 'Leonardo', 0, 1, 3, 8, 0, 360, 360, 4200, 68, 76, 78, 39, 128, 0, 0, 0, 0, 0, 0, 100, 2, 500, 500, 7, 0x30, 750, 1, 0, 0, 1, 0, 0, 0, '', 0, 0, 0, 0, 151200000, 2, 100, 100, 100, 100, 100, 0, 0, 0, 0, 0, '', 0, 0),
(4, 'Aang', 0, 1, 4, 8, 3, 360, 360, 4200, 68, 76, 78, 39, 128, 0, 0, 0, 0, 0, 0, 100, 2, 500, 500, 7, 0x30, 750, 1, 0, 0, 1, 0, 0, 0, '', 0, 0, 0, 0, 151200000, 2, 100, 100, 100, 100, 100, 0, 0, 0, 0, 0, '', 0, 0),
(5, 'Jurubeba', 0, 1, 5, 8, 1, 360, 360, 4200, 68, 76, 78, 39, 128, 0, 0, 0, 0, 0, 0, 100, 2, 500, 500, 7, 0x30, 750, 1, 0, 0, 1, 0, 0, 0, '', 0, 0, 0, 0, 151200000, 2, 100, 100, 100, 100, 100, 0, 1, 0, 0, 0, '', 0, 0);

--
-- Acionadores `players`
--
DELIMITER $$
CREATE TRIGGER `oncreate_players` AFTER INSERT ON `players` FOR EACH ROW BEGIN
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 0, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 1, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 2, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 3, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 4, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 5, 10);
	INSERT INTO `player_skills` (`player_id`, `skillid`, `value`) VALUES (NEW.`id`, 6, 10);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `ondelete_players` BEFORE DELETE ON `players` FOR EACH ROW BEGIN
	DELETE FROM `bans` WHERE `type` IN (2, 5) AND `value` = OLD.`id`;
	UPDATE `houses` SET `owner` = 0 WHERE `owner` = OLD.`id`;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `player_deaths`
--

CREATE TABLE `player_deaths` (
  `id` int NOT NULL,
  `player_id` int NOT NULL,
  `date` bigint UNSIGNED NOT NULL,
  `level` int UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `player_depotitems`
--

CREATE TABLE `player_depotitems` (
  `player_id` int NOT NULL,
  `sid` int NOT NULL COMMENT 'any given range, eg. 0-100 is reserved for depot lockers and all above 100 will be normal items inside depots',
  `pid` int NOT NULL DEFAULT '0',
  `itemtype` int NOT NULL,
  `count` int NOT NULL DEFAULT '0',
  `attributes` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `player_items`
--

CREATE TABLE `player_items` (
  `player_id` int NOT NULL,
  `pid` int NOT NULL DEFAULT '0',
  `sid` int NOT NULL DEFAULT '0',
  `itemtype` int NOT NULL DEFAULT '0',
  `count` int NOT NULL DEFAULT '0',
  `attributes` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `player_killers`
--

CREATE TABLE `player_killers` (
  `kill_id` int NOT NULL,
  `player_id` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `player_namelocks`
--

CREATE TABLE `player_namelocks` (
  `player_id` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `new_name` varchar(255) NOT NULL,
  `date` bigint NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `player_skills`
--

CREATE TABLE `player_skills` (
  `player_id` int NOT NULL,
  `skillid` tinyint NOT NULL DEFAULT '0',
  `value` int UNSIGNED NOT NULL DEFAULT '0',
  `count` int UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Despejando dados para a tabela `player_skills`
--

INSERT INTO `player_skills` (`player_id`, `skillid`, `value`, `count`) VALUES
(2, 0, 10, 0),
(2, 1, 10, 0),
(2, 2, 10, 0),
(2, 3, 10, 0),
(2, 4, 10, 0),
(2, 5, 10, 0),
(2, 6, 10, 0),
(3, 0, 10, 0),
(3, 1, 10, 0),
(3, 2, 10, 0),
(3, 3, 10, 0),
(3, 4, 10, 0),
(3, 5, 10, 0),
(3, 6, 10, 0),
(4, 0, 10, 0),
(4, 1, 10, 0),
(4, 2, 10, 0),
(4, 3, 10, 0),
(4, 4, 10, 0),
(4, 5, 10, 0),
(4, 6, 10, 0),
(5, 0, 10, 0),
(5, 1, 10, 0),
(5, 2, 10, 0),
(5, 3, 10, 0),
(5, 4, 10, 0),
(5, 5, 10, 0),
(5, 6, 10, 0);

-- --------------------------------------------------------

--
-- Estrutura para tabela `player_spells`
--

CREATE TABLE `player_spells` (
  `player_id` int NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `player_statements`
--

CREATE TABLE `player_statements` (
  `id` int NOT NULL,
  `player_id` int NOT NULL,
  `channel_id` int NOT NULL DEFAULT '0',
  `text` varchar(255) NOT NULL,
  `date` bigint NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `player_storage`
--

CREATE TABLE `player_storage` (
  `player_id` int NOT NULL,
  `key` varchar(32) NOT NULL DEFAULT '0',
  `value` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `player_viplist`
--

CREATE TABLE `player_viplist` (
  `player_id` int NOT NULL,
  `vip_id` int NOT NULL,
  `description` varchar(128) NOT NULL,
  `icon` int UNSIGNED NOT NULL,
  `notify` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `server_config`
--

CREATE TABLE `server_config` (
  `config` varchar(35) NOT NULL DEFAULT '',
  `value` varchar(255) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Despejando dados para a tabela `server_config`
--

INSERT INTO `server_config` (`config`, `value`) VALUES
('db_version', '35'),
('encryption', '2');

-- --------------------------------------------------------

--
-- Estrutura para tabela `server_motd`
--

CREATE TABLE `server_motd` (
  `id` int UNSIGNED NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `text` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Despejando dados para a tabela `server_motd`
--

INSERT INTO `server_motd` (`id`, `world_id`, `text`) VALUES
(1, 0, 'Welcome to The Forgotten Server!'),
(2, 0, 'Welcome to fantastic world of Avatar! Like us in facebook.com/otavatartibia.');

-- --------------------------------------------------------

--
-- Estrutura para tabela `server_record`
--

CREATE TABLE `server_record` (
  `record` int NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `timestamp` bigint NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Despejando dados para a tabela `server_record`
--

INSERT INTO `server_record` (`record`, `world_id`, `timestamp`) VALUES
(0, 0, 0),
(101, 0, 1784648812),
(102, 0, 1784649350),
(103, 0, 1784650057),
(104, 0, 1784650318),
(105, 0, 1784650547),
(106, 0, 1784650715),
(107, 0, 1784650801),
(108, 0, 1784651064),
(109, 0, 1784651330);

-- --------------------------------------------------------

--
-- Estrutura para tabela `server_reports`
--

CREATE TABLE `server_reports` (
  `id` int NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `player_id` int NOT NULL DEFAULT '1',
  `posx` int NOT NULL DEFAULT '0',
  `posy` int NOT NULL DEFAULT '0',
  `posz` int NOT NULL DEFAULT '0',
  `timestamp` bigint NOT NULL DEFAULT '0',
  `report` text NOT NULL,
  `reads` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `tiles`
--

CREATE TABLE `tiles` (
  `id` int UNSIGNED NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `house_id` int UNSIGNED NOT NULL,
  `x` int UNSIGNED NOT NULL,
  `y` int UNSIGNED NOT NULL,
  `z` tinyint UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `tile_items`
--

CREATE TABLE `tile_items` (
  `tile_id` int UNSIGNED NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `sid` int NOT NULL,
  `pid` int NOT NULL DEFAULT '0',
  `itemtype` int NOT NULL,
  `count` int NOT NULL DEFAULT '0',
  `attributes` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `tile_store`
--

CREATE TABLE `tile_store` (
  `house_id` int UNSIGNED NOT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `data` longblob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Índices de tabela `account_viplist`
--
ALTER TABLE `account_viplist`
  ADD UNIQUE KEY `account_id_2` (`account_id`,`player_id`),
  ADD KEY `account_id` (`account_id`),
  ADD KEY `player_id` (`player_id`),
  ADD KEY `world_id` (`world_id`);

--
-- Índices de tabela `auction_system`
--
ALTER TABLE `auction_system`
  ADD PRIMARY KEY (`id`);

--
-- Índices de tabela `bans`
--
ALTER TABLE `bans`
  ADD PRIMARY KEY (`id`),
  ADD KEY `type` (`type`,`value`),
  ADD KEY `active` (`active`);

--
-- Índices de tabela `environment_killers`
--
ALTER TABLE `environment_killers`
  ADD KEY `kill_id` (`kill_id`);

--
-- Índices de tabela `global_storage`
--
ALTER TABLE `global_storage`
  ADD UNIQUE KEY `key` (`key`,`world_id`);

--
-- Índices de tabela `guilds`
--
ALTER TABLE `guilds`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`,`world_id`);

--
-- Índices de tabela `guild_invites`
--
ALTER TABLE `guild_invites`
  ADD UNIQUE KEY `player_id` (`player_id`,`guild_id`),
  ADD KEY `guild_id` (`guild_id`);

--
-- Índices de tabela `guild_kills`
--
ALTER TABLE `guild_kills`
  ADD PRIMARY KEY (`id`),
  ADD KEY `guild_id` (`guild_id`),
  ADD KEY `war_id` (`war_id`),
  ADD KEY `death_id` (`death_id`);

--
-- Índices de tabela `guild_ranks`
--
ALTER TABLE `guild_ranks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `guild_id` (`guild_id`);

--
-- Índices de tabela `guild_wars`
--
ALTER TABLE `guild_wars`
  ADD PRIMARY KEY (`id`),
  ADD KEY `status` (`status`),
  ADD KEY `guild_id` (`guild_id`),
  ADD KEY `enemy_id` (`enemy_id`);

--
-- Índices de tabela `houses`
--
ALTER TABLE `houses`
  ADD UNIQUE KEY `id` (`id`,`world_id`);

--
-- Índices de tabela `house_auctions`
--
ALTER TABLE `house_auctions`
  ADD UNIQUE KEY `house_id` (`house_id`,`world_id`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices de tabela `house_data`
--
ALTER TABLE `house_data`
  ADD UNIQUE KEY `house_id` (`house_id`,`world_id`);

--
-- Índices de tabela `house_lists`
--
ALTER TABLE `house_lists`
  ADD UNIQUE KEY `house_id` (`house_id`,`world_id`,`listid`);

--
-- Índices de tabela `killers`
--
ALTER TABLE `killers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `death_id` (`death_id`);

--
-- Índices de tabela `market_history`
--
ALTER TABLE `market_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player_id` (`player_id`,`sale`);

--
-- Índices de tabela `market_offers`
--
ALTER TABLE `market_offers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sale` (`sale`,`itemtype`),
  ADD KEY `created` (`created`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices de tabela `players`
--
ALTER TABLE `players`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`,`deleted`),
  ADD KEY `account_id` (`account_id`),
  ADD KEY `group_id` (`group_id`),
  ADD KEY `online` (`online`),
  ADD KEY `deleted` (`deleted`);

--
-- Índices de tabela `player_deaths`
--
ALTER TABLE `player_deaths`
  ADD PRIMARY KEY (`id`),
  ADD KEY `date` (`date`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices de tabela `player_depotitems`
--
ALTER TABLE `player_depotitems`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`sid`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices de tabela `player_items`
--
ALTER TABLE `player_items`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`sid`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices de tabela `player_killers`
--
ALTER TABLE `player_killers`
  ADD KEY `kill_id` (`kill_id`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices de tabela `player_namelocks`
--
ALTER TABLE `player_namelocks`
  ADD KEY `player_id` (`player_id`);

--
-- Índices de tabela `player_skills`
--
ALTER TABLE `player_skills`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`skillid`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices de tabela `player_spells`
--
ALTER TABLE `player_spells`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`name`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices de tabela `player_statements`
--
ALTER TABLE `player_statements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player_id` (`player_id`),
  ADD KEY `channel_id` (`channel_id`);

--
-- Índices de tabela `player_storage`
--
ALTER TABLE `player_storage`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`key`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices de tabela `player_viplist`
--
ALTER TABLE `player_viplist`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`vip_id`),
  ADD KEY `player_id` (`player_id`),
  ADD KEY `vip_id` (`vip_id`);

--
-- Índices de tabela `server_config`
--
ALTER TABLE `server_config`
  ADD UNIQUE KEY `config` (`config`);

--
-- Índices de tabela `server_motd`
--
ALTER TABLE `server_motd`
  ADD UNIQUE KEY `id` (`id`,`world_id`);

--
-- Índices de tabela `server_record`
--
ALTER TABLE `server_record`
  ADD UNIQUE KEY `record` (`record`,`world_id`,`timestamp`);

--
-- Índices de tabela `server_reports`
--
ALTER TABLE `server_reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `world_id` (`world_id`),
  ADD KEY `reads` (`reads`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices de tabela `tiles`
--
ALTER TABLE `tiles`
  ADD UNIQUE KEY `id` (`id`,`world_id`),
  ADD KEY `x` (`x`,`y`,`z`),
  ADD KEY `house_id` (`house_id`,`world_id`);

--
-- Índices de tabela `tile_items`
--
ALTER TABLE `tile_items`
  ADD UNIQUE KEY `tile_id` (`tile_id`,`world_id`,`sid`),
  ADD KEY `sid` (`sid`);

--
-- Índices de tabela `tile_store`
--
ALTER TABLE `tile_store`
  ADD KEY `house_id` (`house_id`);

--
-- AUTO_INCREMENT para tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de tabela `auction_system`
--
ALTER TABLE `auction_system`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `bans`
--
ALTER TABLE `bans`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `guilds`
--
ALTER TABLE `guilds`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `guild_kills`
--
ALTER TABLE `guild_kills`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `guild_ranks`
--
ALTER TABLE `guild_ranks`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `guild_wars`
--
ALTER TABLE `guild_wars`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `killers`
--
ALTER TABLE `killers`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `market_history`
--
ALTER TABLE `market_history`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `market_offers`
--
ALTER TABLE `market_offers`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `players`
--
ALTER TABLE `players`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de tabela `player_deaths`
--
ALTER TABLE `player_deaths`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `player_statements`
--
ALTER TABLE `player_statements`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `server_reports`
--
ALTER TABLE `server_reports`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- Restrições para tabelas despejadas
--

--
-- Restrições para tabelas `account_viplist`
--
ALTER TABLE `account_viplist`
  ADD CONSTRAINT `account_viplist_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `account_viplist_ibfk_2` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `environment_killers`
--
ALTER TABLE `environment_killers`
  ADD CONSTRAINT `environment_killers_ibfk_1` FOREIGN KEY (`kill_id`) REFERENCES `killers` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `guild_invites`
--
ALTER TABLE `guild_invites`
  ADD CONSTRAINT `guild_invites_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `guild_invites_ibfk_2` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `guild_kills`
--
ALTER TABLE `guild_kills`
  ADD CONSTRAINT `guild_kills_ibfk_1` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `guild_kills_ibfk_2` FOREIGN KEY (`war_id`) REFERENCES `guild_wars` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `guild_kills_ibfk_3` FOREIGN KEY (`death_id`) REFERENCES `player_deaths` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `guild_ranks`
--
ALTER TABLE `guild_ranks`
  ADD CONSTRAINT `guild_ranks_ibfk_1` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `guild_wars`
--
ALTER TABLE `guild_wars`
  ADD CONSTRAINT `guild_wars_ibfk_1` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `guild_wars_ibfk_2` FOREIGN KEY (`enemy_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `house_auctions`
--
ALTER TABLE `house_auctions`
  ADD CONSTRAINT `house_auctions_ibfk_1` FOREIGN KEY (`house_id`,`world_id`) REFERENCES `houses` (`id`, `world_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `house_auctions_ibfk_2` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `house_data`
--
ALTER TABLE `house_data`
  ADD CONSTRAINT `house_data_ibfk_1` FOREIGN KEY (`house_id`,`world_id`) REFERENCES `houses` (`id`, `world_id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `house_lists`
--
ALTER TABLE `house_lists`
  ADD CONSTRAINT `house_lists_ibfk_1` FOREIGN KEY (`house_id`,`world_id`) REFERENCES `houses` (`id`, `world_id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `killers`
--
ALTER TABLE `killers`
  ADD CONSTRAINT `killers_ibfk_1` FOREIGN KEY (`death_id`) REFERENCES `player_deaths` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `market_history`
--
ALTER TABLE `market_history`
  ADD CONSTRAINT `market_history_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `market_offers`
--
ALTER TABLE `market_offers`
  ADD CONSTRAINT `market_offers_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `players`
--
ALTER TABLE `players`
  ADD CONSTRAINT `players_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `player_deaths`
--
ALTER TABLE `player_deaths`
  ADD CONSTRAINT `player_deaths_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `player_depotitems`
--
ALTER TABLE `player_depotitems`
  ADD CONSTRAINT `player_depotitems_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `player_items`
--
ALTER TABLE `player_items`
  ADD CONSTRAINT `player_items_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `player_killers`
--
ALTER TABLE `player_killers`
  ADD CONSTRAINT `player_killers_ibfk_1` FOREIGN KEY (`kill_id`) REFERENCES `killers` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `player_killers_ibfk_2` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `player_namelocks`
--
ALTER TABLE `player_namelocks`
  ADD CONSTRAINT `player_namelocks_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `player_skills`
--
ALTER TABLE `player_skills`
  ADD CONSTRAINT `player_skills_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `player_spells`
--
ALTER TABLE `player_spells`
  ADD CONSTRAINT `player_spells_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `player_statements`
--
ALTER TABLE `player_statements`
  ADD CONSTRAINT `player_statements_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `player_storage`
--
ALTER TABLE `player_storage`
  ADD CONSTRAINT `player_storage_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `player_viplist`
--
ALTER TABLE `player_viplist`
  ADD CONSTRAINT `player_viplist_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `player_viplist_ibfk_2` FOREIGN KEY (`vip_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `server_reports`
--
ALTER TABLE `server_reports`
  ADD CONSTRAINT `server_reports_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `tiles`
--
ALTER TABLE `tiles`
  ADD CONSTRAINT `tiles_ibfk_1` FOREIGN KEY (`house_id`,`world_id`) REFERENCES `houses` (`id`, `world_id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `tile_items`
--
ALTER TABLE `tile_items`
  ADD CONSTRAINT `tile_items_ibfk_1` FOREIGN KEY (`tile_id`) REFERENCES `tiles` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `tile_store`
--
ALTER TABLE `tile_store`
  ADD CONSTRAINT `tile_store_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `houses` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
