-- phpMyAdmin SQL Dump
-- version 4.2.12deb2+deb8u1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jan 20, 2016 at 12:29 AM
-- Server version: 10.0.22-MariaDB-0+deb8u1
-- PHP Version: 5.6.14-0+deb8u1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `testbot`
--
CREATE DATABASE IF NOT EXISTS `testbot` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `testbot`;

-- --------------------------------------------------------

--
-- Table structure for table `alerts`
--

DROP TABLE IF EXISTS `alerts`;
CREATE TABLE IF NOT EXISTS `alerts` (
`alertID` bigint(20) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `message` varchar(255) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `sent` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `announcements`
--

DROP TABLE IF EXISTS `announcements`;
CREATE TABLE IF NOT EXISTS `announcements` (
`id` int(11) NOT NULL,
  `message` varchar(400) NOT NULL,
  `startDate` date DEFAULT NULL,
  `endDate` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `badItems`
--

DROP TABLE IF EXISTS `badItems`;
CREATE TABLE IF NOT EXISTS `badItems` (
  `item` varchar(50) NOT NULL,
  `action` varchar(10) NOT NULL DEFAULT 'timeout'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `bans`
--

DROP TABLE IF EXISTS `bans`;
CREATE TABLE IF NOT EXISTS `bans` (
  `BannedTo` varchar(22) NOT NULL,
  `Steam` bigint(17) NOT NULL,
  `Reason` varchar(255) DEFAULT NULL,
  `expiryDate` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `bookmarks`
--

DROP TABLE IF EXISTS `bookmarks`;
CREATE TABLE IF NOT EXISTS `bookmarks` (
`id` int(11) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `x` int(11) NOT NULL DEFAULT '0',
  `y` int(11) NOT NULL DEFAULT '0',
  `z` int(11) NOT NULL DEFAULT '0',
  `note` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `commandQueue`
--

DROP TABLE IF EXISTS `commandQueue`;
CREATE TABLE IF NOT EXISTS `commandQueue` (
`id` bigint(20) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `command` varchar(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `customMessages`
--

DROP TABLE IF EXISTS `customMessages`;
CREATE TABLE IF NOT EXISTS `customMessages` (
  `command` varchar(30) NOT NULL,
  `message` varchar(255) NOT NULL,
  `accessLevel` int(11) NOT NULL DEFAULT '99'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
CREATE TABLE IF NOT EXISTS `events` (
`id` bigint(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `serverTime` varchar(19) NOT NULL,
  `type` varchar(15) NOT NULL,
  `event` varchar(255) NOT NULL,
  `steam` varchar(17) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `friends`
--

DROP TABLE IF EXISTS `friends`;
CREATE TABLE IF NOT EXISTS `friends` (
  `steam` bigint(17) NOT NULL,
  `friend` bigint(17) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `gimmePrizes`
--

DROP TABLE IF EXISTS `gimmePrizes`;
CREATE TABLE IF NOT EXISTS `gimmePrizes` (
  `name` varchar(20) NOT NULL,
  `category` varchar(15) NOT NULL,
  `prizeLimit` int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `gimmeQueue`
--

DROP TABLE IF EXISTS `gimmeQueue`;
CREATE TABLE IF NOT EXISTS `gimmeQueue` (
`id` int(11) NOT NULL,
  `command` varchar(255) NOT NULL,
  `steam` bigint(17) NOT NULL DEFAULT '0'
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `hotspots`
--

DROP TABLE IF EXISTS `hotspots`;
CREATE TABLE IF NOT EXISTS `hotspots` (
`id` int(11) NOT NULL,
  `idx` int(11) NOT NULL DEFAULT '0',
  `hotspot` varchar(255) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `size` int(11) NOT NULL DEFAULT '2',
  `owner` bigint(17) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `inventoryChanges`
--

DROP TABLE IF EXISTS `inventoryChanges`;
CREATE TABLE IF NOT EXISTS `inventoryChanges` (
`id` bigint(20) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `item` varchar(30) NOT NULL,
  `delta` int(11) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `session` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `inventoryTracker`
--

DROP TABLE IF EXISTS `inventoryTracker`;
CREATE TABLE IF NOT EXISTS `inventoryTracker` (
`inventoryTrackerID` bigint(20) NOT NULL,
  `belt` varchar(500) NOT NULL,
  `pack` varchar(1000) NOT NULL,
  `equipment` varchar(500) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `session` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `IPBlacklist`
--

DROP TABLE IF EXISTS `IPBlacklist`;
CREATE TABLE IF NOT EXISTS `IPBlacklist` (
  `StartIP` bigint(15) NOT NULL,
  `EndIP` bigint(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `ircQueue`
--

DROP TABLE IF EXISTS `ircQueue`;
CREATE TABLE IF NOT EXISTS `ircQueue` (
`id` int(11) NOT NULL,
  `name` varchar(20) NOT NULL,
  `command` varchar(255) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `keystones`
--

DROP TABLE IF EXISTS `keystones`;
CREATE TABLE IF NOT EXISTS `keystones` (
  `steam` bigint(20) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `remove` tinyint(1) NOT NULL DEFAULT '0',
  `removed` int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `locations`
--

DROP TABLE IF EXISTS `locations`;
CREATE TABLE IF NOT EXISTS `locations` (
  `name` varchar(20) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `public` tinyint(1) NOT NULL DEFAULT '0',
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `owner` bigint(17) NOT NULL,
  `village` tinyint(1) NOT NULL DEFAULT '0',
  `pvp` tinyint(1) NOT NULL DEFAULT '0',
  `protectSize` int(11) NOT NULL DEFAULT '50',
  `exitX` int(11) NOT NULL,
  `exitY` int(11) NOT NULL,
  `exitZ` int(11) NOT NULL,
  `cost` int(11) NOT NULL DEFAULT '0',
  `currency` varchar(10) DEFAULT NULL,
  `allowBase` tinyint(1) NOT NULL DEFAULT '0',
  `protected` tinyint(1) NOT NULL DEFAULT '0',
  `accessLevel` int(11) NOT NULL DEFAULT '99',
  `size` int(11) NOT NULL DEFAULT '20',
  `mayor` bigint(17) NOT NULL DEFAULT '0',
  `miniGame` varchar(10) DEFAULT NULL,
  `resetZone` tinyint(1) NOT NULL DEFAULT '0',
  `other` varchar(10) DEFAULT NULL,
  `killZombies` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `locationSpawns`
--

DROP TABLE IF EXISTS `locationSpawns`;
CREATE TABLE IF NOT EXISTS `locationSpawns` (
  `location` varchar(20) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `lottery`
--

DROP TABLE IF EXISTS `lottery`;
CREATE TABLE IF NOT EXISTS `lottery` (
  `steam` varchar(17) NOT NULL,
  `ticket` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `mail`
--

DROP TABLE IF EXISTS `mail`;
CREATE TABLE IF NOT EXISTS `mail` (
`id` bigint(20) NOT NULL,
  `sender` bigint(17) NOT NULL,
  `recipient` bigint(17) DEFAULT '0',
  `message` varchar(500) NOT NULL,
  `status` int(11) NOT NULL DEFAULT '0',
  `flag` varchar(5) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `memIgnoredItems`
--

DROP TABLE IF EXISTS `memIgnoredItems`;
CREATE TABLE IF NOT EXISTS `memIgnoredItems` (
  `item` varchar(50) NOT NULL,
  `qty` int(11) NOT NULL DEFAULT '65'
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `memLottery`
--

DROP TABLE IF EXISTS `memLottery`;
CREATE TABLE IF NOT EXISTS `memLottery` (
  `steam` varchar(17) NOT NULL,
  `ticket` int(11) NOT NULL DEFAULT '0'
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `memRestrictedItems`
--

DROP TABLE IF EXISTS `memRestrictedItems`;
CREATE TABLE IF NOT EXISTS `memRestrictedItems` (
  `item` varchar(50) NOT NULL,
  `qty` int(11) NOT NULL DEFAULT '65',
  `accessLevel` int(11) NOT NULL DEFAULT '90',
  `action` varchar(30) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `memShop`
--

DROP TABLE IF EXISTS `memShop`;
CREATE TABLE IF NOT EXISTS `memShop` (
  `item` varchar(20) NOT NULL,
  `category` varchar(20) NOT NULL,
  `price` int(11) NOT NULL DEFAULT '50',
  `stock` int(11) NOT NULL DEFAULT '50',
  `idx` int(11) NOT NULL DEFAULT '0',
  `code` varchar(10) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `memTracker`
--

DROP TABLE IF EXISTS `memTracker`;
CREATE TABLE IF NOT EXISTS `memTracker` (
`trackerID` bigint(20) NOT NULL,
  `admin` bigint(17) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `session` int(11) DEFAULT '0',
  `flag` varchar(10) DEFAULT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `messageQueue`
--

DROP TABLE IF EXISTS `messageQueue`;
CREATE TABLE IF NOT EXISTS `messageQueue` (
`id` bigint(20) NOT NULL,
  `sender` bigint(17) NOT NULL DEFAULT '0',
  `recipient` bigint(20) NOT NULL DEFAULT '0',
  `message` varchar(1000) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `performance`
--

DROP TABLE IF EXISTS `performance`;
CREATE TABLE IF NOT EXISTS `performance` (
  `serverDate` varchar(19) NOT NULL,
  `gameTime` float NOT NULL,
  `fps` float NOT NULL,
  `heap` float NOT NULL,
  `heapMax` float NOT NULL,
  `chunks` int(11) NOT NULL,
  `cgo` int(11) NOT NULL,
  `players` int(11) NOT NULL,
  `zombies` int(11) NOT NULL,
  `entities` varchar(12) NOT NULL,
  `items` int(11) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `playerNotes`
--

DROP TABLE IF EXISTS `playerNotes`;
CREATE TABLE IF NOT EXISTS `playerNotes` (
`id` int(11) NOT NULL,
  `steam` varchar(17) NOT NULL,
  `createdBy` varchar(17) NOT NULL,
  `note` varchar(400) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `playerQueue`
--

DROP TABLE IF EXISTS `playerQueue`;
CREATE TABLE IF NOT EXISTS `playerQueue` (
`id` int(11) NOT NULL,
  `command` varchar(255) NOT NULL,
  `arena` tinyint(1) NOT NULL DEFAULT '0',
  `boss` tinyint(1) NOT NULL DEFAULT '0',
  `steam` bigint(17) NOT NULL DEFAULT '0'
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `players`
--

DROP TABLE IF EXISTS `players`;
CREATE TABLE IF NOT EXISTS `players` (
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `name` varchar(25) NOT NULL,
  `id` int(11) NOT NULL,
  `xPos` int(11) NOT NULL DEFAULT '0',
  `yPos` int(11) NOT NULL DEFAULT '0',
  `zPos` int(11) NOT NULL DEFAULT '0',
  `xPosOld` int(11) NOT NULL DEFAULT '0',
  `yPosOld` int(11) NOT NULL DEFAULT '0',
  `zPosOld` int(11) NOT NULL DEFAULT '0',
  `homeX` int(11) NOT NULL DEFAULT '0',
  `homeY` int(11) NOT NULL DEFAULT '0',
  `homeZ` int(11) NOT NULL DEFAULT '0',
  `home2X` int(11) NOT NULL DEFAULT '0',
  `home2Y` int(11) NOT NULL DEFAULT '0',
  `home2Z` int(11) NOT NULL DEFAULT '0',
  `exitX` int(11) NOT NULL DEFAULT '0',
  `exitY` int(11) NOT NULL DEFAULT '0',
  `exitZ` int(11) NOT NULL DEFAULT '0',
  `exit2X` int(11) NOT NULL DEFAULT '0',
  `exit2Y` int(11) NOT NULL DEFAULT '0',
  `exit2Z` int(11) NOT NULL DEFAULT '0',
  `level` int(11) NOT NULL DEFAULT '1',
  `cash` int(11) NOT NULL DEFAULT '0',
  `pvpBounty` int(11) NOT NULL DEFAULT '0',
  `zombies` int(11) NOT NULL DEFAULT '0',
  `score` int(11) NOT NULL DEFAULT '0',
  `playerKills` int(11) NOT NULL DEFAULT '0',
  `deaths` int(11) NOT NULL DEFAULT '0',
  `protectSize` int(11) NOT NULL DEFAULT '32',
  `protect2Size` int(11) NOT NULL DEFAULT '32',
  `sessionCount` int(11) NOT NULL DEFAULT '1',
  `timeOnServer` int(11) NOT NULL DEFAULT '0',
  `firstSeen` int(11) NOT NULL DEFAULT '0',
  `keystones` int(11) NOT NULL DEFAULT '0',
  `overStackTimeout` tinyint(1) NOT NULL DEFAULT '0',
  `overstack` tinyint(1) NOT NULL DEFAULT '0',
  `shareWaypoint` tinyint(1) NOT NULL DEFAULT '0',
  `watchCash` tinyint(1) NOT NULL DEFAULT '0',
  `watchPlayer` tinyint(1) NOT NULL DEFAULT '1',
  `timeout` tinyint(1) NOT NULL DEFAULT '0',
  `denyRights` tinyint(1) NOT NULL DEFAULT '0',
  `botTimeout` tinyint(1) NOT NULL DEFAULT '0',
  `newPlayer` tinyint(1) NOT NULL DEFAULT '1',
  `ip` varchar(15) DEFAULT NULL,
  `seen` varchar(19) DEFAULT NULL,
  `baseCooldown` int(11) NOT NULL DEFAULT '0',
  `ircAlias` varchar(15) DEFAULT NULL,
  `bed` varchar(5) DEFAULT NULL,
  `donor` tinyint(1) NOT NULL DEFAULT '0',
  `playtime` int(11) NOT NULL DEFAULT '0',
  `protect` tinyint(1) NOT NULL DEFAULT '0',
  `protect2` tinyint(1) NOT NULL DEFAULT '0',
  `tokens` int(11) NOT NULL DEFAULT '0',
  `exiled` tinyint(1) NOT NULL DEFAULT '0',
  `pvpCount` int(11) NOT NULL DEFAULT '0',
  `translate` tinyint(1) NOT NULL DEFAULT '0',
  `prisoner` tinyint(1) NOT NULL DEFAULT '0',
  `permanentBan` tinyint(1) NOT NULL DEFAULT '0',
  `whitelisted` tinyint(1) NOT NULL DEFAULT '0',
  `silentBob` tinyint(1) NOT NULL DEFAULT '0',
  `walkies` tinyint(1) NOT NULL DEFAULT '0',
  `prisonReason` varchar(150) DEFAULT NULL,
  `prisonxPosOld` int(11) NOT NULL DEFAULT '0',
  `prisonyPosOld` int(11) NOT NULL DEFAULT '0',
  `prisonzPosOld` int(11) NOT NULL DEFAULT '0',
  `pvpVictim` bigint(17) NOT NULL DEFAULT '0',
  `aliases` varchar(255) DEFAULT NULL,
  `location` varchar(15) DEFAULT NULL,
  `canTeleport` tinyint(1) NOT NULL DEFAULT '1',
  `allowBadInventory` tinyint(1) NOT NULL DEFAULT '0',
  `ircTranslate` tinyint(1) NOT NULL DEFAULT '0',
  `ircPass` varchar(15) NOT NULL,
  `noSpam` tinyint(1) NOT NULL DEFAULT '0',
  `waypointX` int(11) NOT NULL DEFAULT '0',
  `waypointY` int(11) NOT NULL DEFAULT '0',
  `waypointZ` int(11) NOT NULL DEFAULT '0',
  `xPosTimeout` int(11) NOT NULL DEFAULT '0',
  `yPosTimeout` int(11) NOT NULL DEFAULT '0',
  `zPosTimeout` int(11) NOT NULL DEFAULT '0',
  `accessLevel` int(11) NOT NULL DEFAULT '99',
  `country` varchar(2) DEFAULT NULL,
  `ping` int(11) NOT NULL DEFAULT '0',
  `donorLevel` int(11) NOT NULL DEFAULT '1',
  `donorExpiry` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `autoFriend` varchar(2) NOT NULL COMMENT 'NA/AF/AD',
  `ircOtherNames` varchar(50) DEFAULT NULL,
  `steamOwner` bigint(17) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `polls`
--

DROP TABLE IF EXISTS `polls`;
CREATE TABLE IF NOT EXISTS `polls` (
`id` int(11) NOT NULL,
  `author` bigint(17) NOT NULL DEFAULT '0',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `expires` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `topic` varchar(150) NOT NULL,
  `responseYN` tinyint(1) NOT NULL DEFAULT '1',
  `option1` varchar(100) NOT NULL,
  `option2` varchar(100) NOT NULL,
  `option3` varchar(100) NOT NULL,
  `option4` varchar(100) NOT NULL,
  `option5` varchar(100) NOT NULL,
  `option6` varchar(100) NOT NULL,
  `accessLevel` int(11) NOT NULL DEFAULT '90'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `pollVotes`
--

DROP TABLE IF EXISTS `pollVotes`;
CREATE TABLE IF NOT EXISTS `pollVotes` (
  `pollID` int(11) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `vote` int(11) NOT NULL DEFAULT '0',
  `weight` float NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `proxies`
--

DROP TABLE IF EXISTS `proxies`;
CREATE TABLE IF NOT EXISTS `proxies` (
  `scanString` varchar(100) NOT NULL,
  `action` varchar(20) NOT NULL DEFAULT 'nothing',
  `hits` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `resetZones`
--

DROP TABLE IF EXISTS `resetZones`;
CREATE TABLE IF NOT EXISTS `resetZones` (
  `region` varchar(20) NOT NULL DEFAULT '',
  `x1` int(11) DEFAULT '0',
  `z1` int(11) DEFAULT '0',
  `x2` int(11) DEFAULT '0',
  `z2` int(11) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `restrictedItems`
--

DROP TABLE IF EXISTS `restrictedItems`;
CREATE TABLE IF NOT EXISTS `restrictedItems` (
  `item` varchar(50) NOT NULL,
  `qty` int(11) NOT NULL DEFAULT '65',
  `accessLevel` int(11) NOT NULL DEFAULT '90',
  `action` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `searchResults`
--

DROP TABLE IF EXISTS `searchResults`;
CREATE TABLE IF NOT EXISTS `searchResults` (
`id` bigint(20) NOT NULL,
  `owner` bigint(17) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `x` int(11) DEFAULT NULL,
  `y` int(11) DEFAULT NULL,
  `z` int(11) DEFAULT NULL,
  `session` int(11) DEFAULT NULL,
  `date` varchar(20) DEFAULT NULL,
  `counter` int(11) NOT NULL DEFAULT '0'
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `server`
--

DROP TABLE IF EXISTS `server`;
CREATE TABLE IF NOT EXISTS `server` (
  `rules` varchar(255) DEFAULT 'No rules',
  `shopCountdown` tinyint(4) NOT NULL DEFAULT '0',
  `gimmePeace` tinyint(1) NOT NULL DEFAULT '0',
  `date` varchar(10) DEFAULT NULL,
  `windowDebug` varchar(15) NOT NULL DEFAULT 'Debug',
  `ServerPort` int(11) NOT NULL DEFAULT '0',
  `windowAlerts` varchar(15) NOT NULL DEFAULT 'Alerts',
  `allowGimme` tinyint(1) NOT NULL DEFAULT '0',
  `mapSize` int(11) NOT NULL DEFAULT '20000',
  `ircAlerts` varchar(15) NOT NULL DEFAULT '#new_alerts',
  `ircWatch` varchar(15) NOT NULL DEFAULT '#new_watch',
  `prisonSize` int(11) NOT NULL DEFAULT '30',
  `MOTD` varchar(255) DEFAULT 'We have a new server bot!',
  `IP` varchar(15) DEFAULT '0.0.0.0',
  `lottery` int(11) NOT NULL DEFAULT '0',
  `allowShop` tinyint(1) NOT NULL DEFAULT '0',
  `windowGMSG` varchar(15) NOT NULL DEFAULT 'GMSG',
  `botName` varchar(15) NOT NULL DEFAULT 'Bot',
  `allowWaypoints` tinyint(1) NOT NULL DEFAULT '0',
  `windowLists` varchar(15) NOT NULL DEFAULT 'Lists',
  `ircMain` varchar(15) NOT NULL DEFAULT '#new',
  `chatColour` varchar(6) NOT NULL DEFAULT 'D4FFD4',
  `maxPlayers` int(11) NOT NULL DEFAULT '24',
  `maxServerUptime` int(11) NOT NULL DEFAULT '12',
  `windowPlayers` varchar(15) NOT NULL DEFAULT 'Players',
  `baseSize` int(11) NOT NULL DEFAULT '32',
  `baseCooldown` int(11) NOT NULL DEFAULT '2400',
  `protectionMaxDays` int(11) NOT NULL DEFAULT '40',
  `ircBotName` varchar(15) NOT NULL DEFAULT 'Bot',
  `serverName` varchar(50) NOT NULL DEFAULT 'New Server',
  `lastDailyReboot` int(11) NOT NULL DEFAULT '0',
  `allowNumericNames` tinyint(1) NOT NULL DEFAULT '1',
  `allowGarbageNames` tinyint(1) NOT NULL DEFAULT '1',
`id` int(11) NOT NULL,
  `allowReboot` tinyint(1) NOT NULL DEFAULT '1',
  `newPlayerTimer` int(11) NOT NULL DEFAULT '120',
  `blacklistResponse` varchar(20) NOT NULL DEFAULT 'exile',
  `gameDay` int(11) NOT NULL DEFAULT '0',
  `welcome` varchar(255) DEFAULT NULL,
  `allowVoting` tinyint(1) NOT NULL DEFAULT '0',
  `allowPlayerVoteTopics` tinyint(1) NOT NULL DEFAULT '0',
  `shopOpenHour` int(11) NOT NULL DEFAULT '0',
  `shopCloseHour` int(11) NOT NULL DEFAULT '0',
  `shopLocation` varchar(20) DEFAULT NULL,
  `website` varchar(100) DEFAULT NULL,
  `ircServer` varchar(100) DEFAULT NULL,
  `pingKick` int(11) NOT NULL DEFAULT '-1',
  `longPlayUpgradeTime` int(11) NOT NULL DEFAULT '0',
  `gameType` varchar(3) NOT NULL DEFAULT 'pve',
  `hideCommands` tinyint(1) NOT NULL DEFAULT '1',
  `botTick` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `shop`
--

DROP TABLE IF EXISTS `shop`;
CREATE TABLE IF NOT EXISTS `shop` (
  `item` varchar(50) NOT NULL,
  `category` varchar(20) NOT NULL,
  `price` int(11) NOT NULL DEFAULT '50',
  `stock` int(11) NOT NULL DEFAULT '50',
  `idx` int(11) NOT NULL DEFAULT '0',
  `maxStock` int(11) NOT NULL DEFAULT '50',
  `variation` int(11) NOT NULL DEFAULT '0',
  `special` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `shopCategories`
--

DROP TABLE IF EXISTS `shopCategories`;
CREATE TABLE IF NOT EXISTS `shopCategories` (
  `category` varchar(20) NOT NULL,
  `idx` int(11) NOT NULL,
  `code` varchar(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `teleports`
--

DROP TABLE IF EXISTS `teleports`;
CREATE TABLE IF NOT EXISTS `teleports` (
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `owner` bigint(17) NOT NULL,
  `oneway` tinyint(1) NOT NULL DEFAULT '0',
  `x` int(11) NOT NULL DEFAULT '0',
  `y` int(11) NOT NULL DEFAULT '0',
  `z` int(11) NOT NULL DEFAULT '0',
  `dx` int(11) NOT NULL DEFAULT '0',
  `dy` int(11) NOT NULL DEFAULT '0',
  `dz` int(11) NOT NULL DEFAULT '0',
  `name` varchar(15) NOT NULL,
  `friends` tinyint(1) NOT NULL DEFAULT '0',
  `public` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `tracker`
--

DROP TABLE IF EXISTS `tracker`;
CREATE TABLE IF NOT EXISTS `tracker` (
`trackerID` bigint(20) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `session` int(11) DEFAULT '0',
  `flag` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `villagers`
--

DROP TABLE IF EXISTS `villagers`;
CREATE TABLE IF NOT EXISTS `villagers` (
  `steam` bigint(17) NOT NULL,
  `village` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `visits`
--

DROP TABLE IF EXISTS `visits`;
CREATE TABLE IF NOT EXISTS `visits` (
`id` bigint(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `steam` bigint(17) NOT NULL,
  `visited` bigint(17) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `base` int(11) NOT NULL,
  `session` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `alerts`
--
ALTER TABLE `alerts`
 ADD PRIMARY KEY (`alertID`);

--
-- Indexes for table `announcements`
--
ALTER TABLE `announcements`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `badItems`
--
ALTER TABLE `badItems`
 ADD PRIMARY KEY (`item`);

--
-- Indexes for table `bans`
--
ALTER TABLE `bans`
 ADD PRIMARY KEY (`Steam`);

--
-- Indexes for table `bookmarks`
--
ALTER TABLE `bookmarks`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `commandQueue`
--
ALTER TABLE `commandQueue`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `customMessages`
--
ALTER TABLE `customMessages`
 ADD PRIMARY KEY (`command`);

--
-- Indexes for table `events`
--
ALTER TABLE `events`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `id` (`id`), ADD KEY `id_2` (`id`);

--
-- Indexes for table `friends`
--
ALTER TABLE `friends`
 ADD PRIMARY KEY (`steam`,`friend`);

--
-- Indexes for table `gimmePrizes`
--
ALTER TABLE `gimmePrizes`
 ADD PRIMARY KEY (`name`);

--
-- Indexes for table `gimmeQueue`
--
ALTER TABLE `gimmeQueue`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `hotspots`
--
ALTER TABLE `hotspots`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `inventoryChanges`
--
ALTER TABLE `inventoryChanges`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `id` (`id`), ADD UNIQUE KEY `id_2` (`id`), ADD UNIQUE KEY `id_5` (`id`), ADD KEY `steam` (`steam`), ADD KEY `id_3` (`id`), ADD KEY `id_4` (`id`);

--
-- Indexes for table `inventoryTracker`
--
ALTER TABLE `inventoryTracker`
 ADD PRIMARY KEY (`inventoryTrackerID`);

--
-- Indexes for table `IPBlacklist`
--
ALTER TABLE `IPBlacklist`
 ADD PRIMARY KEY (`StartIP`);

--
-- Indexes for table `ircQueue`
--
ALTER TABLE `ircQueue`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `keystones`
--
ALTER TABLE `keystones`
 ADD PRIMARY KEY (`steam`,`x`,`y`,`z`), ADD KEY `steam` (`steam`), ADD KEY `steam_2` (`steam`);

--
-- Indexes for table `locations`
--
ALTER TABLE `locations`
 ADD PRIMARY KEY (`name`), ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `lottery`
--
ALTER TABLE `lottery`
 ADD PRIMARY KEY (`steam`,`ticket`);

--
-- Indexes for table `mail`
--
ALTER TABLE `mail`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `memIgnoredItems`
--
ALTER TABLE `memIgnoredItems`
 ADD PRIMARY KEY (`item`);

--
-- Indexes for table `memLottery`
--
ALTER TABLE `memLottery`
 ADD PRIMARY KEY (`steam`,`ticket`);

--
-- Indexes for table `memRestrictedItems`
--
ALTER TABLE `memRestrictedItems`
 ADD PRIMARY KEY (`item`);

--
-- Indexes for table `memShop`
--
ALTER TABLE `memShop`
 ADD PRIMARY KEY (`item`);

--
-- Indexes for table `memTracker`
--
ALTER TABLE `memTracker`
 ADD PRIMARY KEY (`trackerID`);

--
-- Indexes for table `messageQueue`
--
ALTER TABLE `messageQueue`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `performance`
--
ALTER TABLE `performance`
 ADD PRIMARY KEY (`serverDate`), ADD KEY `serverDate` (`serverDate`);

--
-- Indexes for table `playerNotes`
--
ALTER TABLE `playerNotes`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `playerQueue`
--
ALTER TABLE `playerQueue`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `players`
--
ALTER TABLE `players`
 ADD PRIMARY KEY (`steam`), ADD UNIQUE KEY `steam` (`steam`);

--
-- Indexes for table `polls`
--
ALTER TABLE `polls`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pollVotes`
--
ALTER TABLE `pollVotes`
 ADD PRIMARY KEY (`pollID`,`steam`);

--
-- Indexes for table `proxies`
--
ALTER TABLE `proxies`
 ADD PRIMARY KEY (`scanString`);

--
-- Indexes for table `resetZones`
--
ALTER TABLE `resetZones`
 ADD PRIMARY KEY (`region`), ADD UNIQUE KEY `region` (`region`);

--
-- Indexes for table `restrictedItems`
--
ALTER TABLE `restrictedItems`
 ADD PRIMARY KEY (`item`);

--
-- Indexes for table `searchResults`
--
ALTER TABLE `searchResults`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `server`
--
ALTER TABLE `server`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `shop`
--
ALTER TABLE `shop`
 ADD PRIMARY KEY (`item`);

--
-- Indexes for table `shopCategories`
--
ALTER TABLE `shopCategories`
 ADD PRIMARY KEY (`category`);

--
-- Indexes for table `teleports`
--
ALTER TABLE `teleports`
 ADD PRIMARY KEY (`name`);

--
-- Indexes for table `tracker`
--
ALTER TABLE `tracker`
 ADD PRIMARY KEY (`trackerID`);

--
-- Indexes for table `villagers`
--
ALTER TABLE `villagers`
 ADD PRIMARY KEY (`steam`,`village`);

--
-- Indexes for table `visits`
--
ALTER TABLE `visits`
 ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `alerts`
--
ALTER TABLE `alerts`
MODIFY `alertID` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `announcements`
--
ALTER TABLE `announcements`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `bookmarks`
--
ALTER TABLE `bookmarks`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `commandQueue`
--
ALTER TABLE `commandQueue`
MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `events`
--
ALTER TABLE `events`
MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `gimmeQueue`
--
ALTER TABLE `gimmeQueue`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `hotspots`
--
ALTER TABLE `hotspots`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `inventoryChanges`
--
ALTER TABLE `inventoryChanges`
MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `inventoryTracker`
--
ALTER TABLE `inventoryTracker`
MODIFY `inventoryTrackerID` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `ircQueue`
--
ALTER TABLE `ircQueue`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `mail`
--
ALTER TABLE `mail`
MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `memTracker`
--
ALTER TABLE `memTracker`
MODIFY `trackerID` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `messageQueue`
--
ALTER TABLE `messageQueue`
MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `playerNotes`
--
ALTER TABLE `playerNotes`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `playerQueue`
--
ALTER TABLE `playerQueue`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `polls`
--
ALTER TABLE `polls`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `searchResults`
--
ALTER TABLE `searchResults`
MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `server`
--
ALTER TABLE `server`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `tracker`
--
ALTER TABLE `tracker`
MODIFY `trackerID` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `visits`
--
ALTER TABLE `visits`
MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
