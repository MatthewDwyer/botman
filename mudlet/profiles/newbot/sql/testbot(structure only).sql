SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `testbot`
--
CREATE DATABASE IF NOT EXISTS `testbot` DEFAULT CHARACTER SET utf8 COLLATE utf8mb4_general_ci;
USE `testbot`;

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `alerts` (
`alertID` bigint(20) NOT NULL AUTO_INCREMENT,
  `steam` bigint(17) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `message` varchar(255) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `sent` tinyint(1) NOT NULL DEFAULT '0',
  `status` varchar(30) NOT NULL DEFAULT '',
  PRIMARY KEY (`alertID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `altertables`
--

CREATE TABLE IF NOT EXISTS `altertables` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `statement` varchar(1000) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `announcements`
--

CREATE TABLE IF NOT EXISTS `announcements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `message` varchar(400) NOT NULL,
  `endDate` date NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `badItems`
--

CREATE TABLE IF NOT EXISTS `badItems` (
  `item` varchar(50) NOT NULL,
  `action` varchar(10) NOT NULL DEFAULT 'timeout',
  `validated` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `badWords`
--

CREATE TABLE IF NOT EXISTS `badWords` (
  `badWord` varchar(15) NOT NULL,
  `cost` int(11) NOT NULL DEFAULT '10',
  `counter` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `bans`
--

CREATE TABLE IF NOT EXISTS `bans` (
  `BannedTo` varchar(22) NOT NULL,
  `Steam` bigint(17) NOT NULL,
  `Reason` varchar(255) DEFAULT NULL,
  `expiryDate` datetime NOT NULL,
  PRIMARY KEY (`Steam`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `bookmarks`
--

CREATE TABLE IF NOT EXISTS `bookmarks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steam` bigint(17) NOT NULL,
  `x` int(11) NOT NULL DEFAULT '0',
  `y` int(11) NOT NULL DEFAULT '0',
  `z` int(11) NOT NULL DEFAULT '0',
  `note` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `botChat`
--

CREATE TABLE IF NOT EXISTS `botChat` (
  `botChatID` int(11) NOT NULL AUTO_INCREMENT,
  `triggerWords` varchar(255) NOT NULL DEFAULT '',
  `triggerPhrase` varchar(255) NOT NULL DEFAULT '',
  `accessLevelRestriction` int(11) NOT NULL DEFAULT '99',
  `mustAddressBot` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`botChatID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `botChatResponses`
--

CREATE TABLE IF NOT EXISTS `botChatResponses` (
  `botChatResponseID` int(11) NOT NULL AUTO_INCREMENT,
  `botChatID` int(11) NOT NULL DEFAULT '0',
  `response` varchar(300) NOT NULL DEFAULT '',
  PRIMARY KEY (`botChatResponseID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `botCommands`
--

CREATE TABLE IF NOT EXISTS `botCommands` (
  `cmdCode` varchar(5) NOT NULL,
  `cmdIndex` int(11) NOT NULL,
  `accessLevel` int(11) NOT NULL DEFAULT '0',
  `enabled` tinyint(1) NOT NULL DEFAULT '1',
  `keywords` varchar(150) NOT NULL DEFAULT '',
  `shortDescription` varchar(255) NOT NULL DEFAULT '',
  `longDescription` varchar(1000) NOT NULL DEFAULT '',
  `sortOrder` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`cmdCode`,`cmdIndex`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `commandAccessRestrictions`
--

CREATE TABLE IF NOT EXISTS `commandAccessRestrictions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `functionName` varchar(100) NOT NULL DEFAULT '',
  `accessLevel` int(11) NOT NULL DEFAULT '3',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `commandQueue`
--

CREATE TABLE IF NOT EXISTS `commandQueue` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `steam` bigint(17) NOT NULL,
  `command` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `connectQueue`
--

CREATE TABLE IF NOT EXISTS `connectQueue` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `steam` bigint(17) NOT NULL,
  `command` varchar(255) NOT NULL,
  `processed` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `customCommands`
--

CREATE TABLE IF NOT EXISTS `customCommands` (
  `commandID` int(11) NOT NULL AUTO_INCREMENT,
  `command` varchar(50) NOT NULL,
  `accessLevel` int(11) NOT NULL DEFAULT '2',
  `help` varchar(255) NOT NULL,
  PRIMARY KEY (`commandID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `customCommands_Detail`
--

CREATE TABLE IF NOT EXISTS `customCommands_Detail` (
`detailID` int(11) NOT NULL,
  `commandID` int(11) NOT NULL,
  `action` varchar(5) NOT NULL DEFAULT '' COMMENT 'say,give,tele,spawn,buff,cmd',
  `thing` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`detailID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `customMessages`
--

CREATE TABLE IF NOT EXISTS `customMessages` (
  `command` varchar(30) NOT NULL,
  `message` varchar(255) NOT NULL,
  `accessLevel` int(11) NOT NULL DEFAULT '99',
  PRIMARY KEY (`command`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `events`
--

CREATE TABLE IF NOT EXISTS `events` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `serverTime` varchar(19) NOT NULL,
  `type` varchar(15) NOT NULL,
  `event` varchar(255) NOT NULL,
  `steam` bigint(17) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `friends`
--

CREATE TABLE IF NOT EXISTS `friends` (
  `steam` bigint(17) NOT NULL,
  `friend` bigint(17) NOT NULL DEFAULT '0',
  `autoAdded` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steam`,`friend`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `gimmeGroup`
--

CREATE TABLE IF NOT EXISTS `gimmeGroup` (
  `groupName` varchar(30) NOT NULL DEFAULT '',
  PRIMARY KEY (`groupName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `gimmePrizes`
--

CREATE TABLE IF NOT EXISTS `gimmePrizes` (
  `name` varchar(20) NOT NULL,
  `category` varchar(15) NOT NULL,
  `prizeLimit` int(11) NOT NULL DEFAULT '1',
  `quality` int(11) NOT NULL DEFAULT '0',
  `validated` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `gimmeQueue`
--

CREATE TABLE IF NOT EXISTS `gimmeQueue` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `command` varchar(255) NOT NULL,
  `steam` bigint(17) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `gimmeZombies`
--

CREATE TABLE IF NOT EXISTS `gimmeZombies` (
  `zombie` varchar(50) NOT NULL,
  `minPlayerLevel` int(11) NOT NULL DEFAULT '1',
  `minArenaLevel` int(11) NOT NULL DEFAULT '1',
  `entityID` int(11) NOT NULL DEFAULT '0',
  `bossZombie` tinyint(1) NOT NULL DEFAULT '0',
  `doNotSpawn` tinyint(4) NOT NULL DEFAULT '0',
  `maxHealth` int(11) NOT NULL DEFAULT '0',
  `remove` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`entityID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `helpCommands`
--

CREATE TABLE IF NOT EXISTS `helpCommands` (
  `commandID` int(11) NOT NULL AUTO_INCREMENT,
  `command` text NOT NULL,
  `description` text NOT NULL,
  `notes` text NOT NULL,
  `keywords` varchar(150) NOT NULL,
  `lastUpdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `accessLevel` int(11) NOT NULL DEFAULT '99',
  `ingameOnly` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`commandID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `helpTopicCommands`
--

CREATE TABLE IF NOT EXISTS `helpTopicCommands` (
  `topicID` int(11) NOT NULL,
  `commandID` int(11) NOT NULL,
  PRIMARY KEY (`topicID`,`commandID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `helpTopics`
--

CREATE TABLE IF NOT EXISTS `helpTopics` (
  `topicID` int(11) NOT NULL AUTO_INCREMENT,
  `topic` varchar(50) NOT NULL,
  `description` text NOT NULL,
  PRIMARY KEY (`topicID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `hotspots`
--

CREATE TABLE IF NOT EXISTS `hotspots` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `idx` int(11) NOT NULL DEFAULT '0',
  `hotspot` varchar(255) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `size` int(11) NOT NULL DEFAULT '2',
  `owner` bigint(17) NOT NULL,
  `action` varchar(10) NOT NULL DEFAULT '',
  `destination` varchar(20) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `inventoryChanges`
--

CREATE TABLE IF NOT EXISTS `inventoryChanges` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `steam` bigint(17) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `item` varchar(30) NOT NULL,
  `delta` int(11) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `session` int(11) NOT NULL,
  `flag` varchar(3) DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `inventoryTracker`
--

CREATE TABLE IF NOT EXISTS `inventoryTracker` (
  `inventoryTrackerID` bigint(20) NOT NULL AUTO_INCREMENT,
  `belt` varchar(500) NOT NULL,
  `pack` varchar(1100) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `session` int(11) NOT NULL,
  `equipment` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`inventoryTrackerID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `IPBlacklist`
--

CREATE TABLE IF NOT EXISTS `IPBlacklist` (
  `StartIP` bigint(15) NOT NULL,
  `EndIP` bigint(15) NOT NULL,
  `Country` varchar(2) DEFAULT NULL,
  `DateAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `botID` int(11) NOT NULL DEFAULT '0',
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `playerName` varchar(25) NOT NULL DEFAULT '',
  PRIMARY KEY (`StartIP`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `ircQueue`
--

CREATE TABLE IF NOT EXISTS `ircQueue` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(20) NOT NULL,
  `command` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `keystones`
--

CREATE TABLE IF NOT EXISTS `keystones` (
  `steam` bigint(20) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `remove` tinyint(1) NOT NULL DEFAULT '0',
  `removed` int(11) NOT NULL DEFAULT '1',
  `expired` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steam`,`x`,`y`,`z`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `list`
--

CREATE TABLE IF NOT EXISTS `list` (
  `thing` varchar(255) NOT NULL,
  `id` int(11) NOT NULL DEFAULT '0',
  `class` varchar(20) NOT NULL DEFAULT '',
  UNIQUE KEY `thing` (`thing`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4 COMMENT='For sorting a list';

-- --------------------------------------------------------

--
-- Table structure for table `locationCategories`
--

CREATE TABLE IF NOT EXISTS `locationCategories` (
  `categoryName` varchar(20) NOT NULL,
  `minAccessLevel` int(11) NOT NULL DEFAULT '99',
  `maxAccessLevel` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`categoryName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `locations`
--

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
  `currency` varchar(20) DEFAULT NULL,
  `allowBase` tinyint(1) NOT NULL DEFAULT '0',
  `protected` tinyint(1) NOT NULL DEFAULT '0',
  `accessLevel` int(11) NOT NULL DEFAULT '99',
  `size` int(11) NOT NULL DEFAULT '20',
  `mayor` bigint(17) NOT NULL DEFAULT '0',
  `miniGame` varchar(10) DEFAULT NULL,
  `resetZone` tinyint(1) NOT NULL DEFAULT '0',
  `other` varchar(10) DEFAULT NULL,
  `killZombies` tinyint(1) NOT NULL DEFAULT '0',
  `timeOpen` int(11) NOT NULL DEFAULT '0',
  `timeClosed` int(11) NOT NULL DEFAULT '0',
  `allowWaypoints` tinyint(1) NOT NULL DEFAULT '1',
  `allowReturns` tinyint(1) NOT NULL DEFAULT '1',
  `allowLeave` tinyint(1) NOT NULL DEFAULT '1',
  `newPlayersOnly` tinyint(1) NOT NULL DEFAULT '0',
  `minimumLevel` int(11) NOT NULL DEFAULT '0',
  `maximumLevel` int(11) NOT NULL DEFAULT '0',
  `dayClosed` int(11) NOT NULL DEFAULT '0',
  `dailyTaxRate` int(11) NOT NULL DEFAULT '0',
  `bank` int(11) NOT NULL DEFAULT '0',
  `prisonX` int(11) NOT NULL DEFAULT '0',
  `prisonY` int(11) NOT NULL DEFAULT '0',
  `prisonZ` int(11) NOT NULL DEFAULT '0',
  `hidden` tinyint(1) NOT NULL DEFAULT '0',
  `locationCategory` varchar(20) NOT NULL DEFAULT '',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `locationSpawns`
--

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

CREATE TABLE IF NOT EXISTS `lottery` (
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `ticket` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steam`,`ticket`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `mail`
--

CREATE TABLE IF NOT EXISTS `mail` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `sender` bigint(17) NOT NULL,
  `recipient` bigint(17) DEFAULT '0',
  `message` varchar(500) NOT NULL,
  `status` int(11) NOT NULL DEFAULT '0',
  `flag` varchar(5) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `memEntities`
--

CREATE TABLE IF NOT EXISTS `memEntities` (
  `entityID` bigint(20) NOT NULL,
  `type` varchar(20) NOT NULL DEFAULT '',
  `name` varchar(30) NOT NULL DEFAULT '',
  `x` int(11) NOT NULL DEFAULT '0',
  `y` int(11) NOT NULL DEFAULT '0',
  `z` int(11) DEFAULT '0',
  `dead` tinyint(1) NOT NULL DEFAULT '0',
  `health` int(11) NOT NULL DEFAULT '0',
  UNIQUE KEY `entityID` (`entityID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `memIgnoredItems`
--

CREATE TABLE IF NOT EXISTS `memIgnoredItems` (
  `item` varchar(50) NOT NULL,
  `qty` int(11) NOT NULL DEFAULT '65',
  PRIMARY KEY (`item`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `memLottery`
--

CREATE TABLE IF NOT EXISTS `memLottery` (
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `ticket` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steam`,`ticket`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `memRestrictedItems`
--

CREATE TABLE IF NOT EXISTS `memRestrictedItems` (
  `item` varchar(50) NOT NULL,
  `qty` int(11) NOT NULL DEFAULT '65',
  `accessLevel` int(11) NOT NULL DEFAULT '90',
  `action` varchar(30) NOT NULL,
  PRIMARY KEY (`item`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `memShop`
--

CREATE TABLE IF NOT EXISTS `memShop` (
  `item` varchar(50) NOT NULL,
  `category` varchar(20) NOT NULL,
  `price` int(11) NOT NULL DEFAULT '50',
  `stock` int(11) NOT NULL DEFAULT '50',
  `idx` int(11) NOT NULL DEFAULT '0',
  `code` varchar(10) NOT NULL,
  PRIMARY KEY (`item`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `memTracker`
--

CREATE TABLE IF NOT EXISTS `memTracker` (
  `trackerID` bigint(20) NOT NULL AUTO_INCREMENT,
  `admin` bigint(17) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `session` int(11) DEFAULT '0',
  `flag` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`trackerID`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `messageQueue`
--

CREATE TABLE IF NOT EXISTS `messageQueue` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `sender` bigint(17) NOT NULL DEFAULT '0',
  `recipient` bigint(20) NOT NULL DEFAULT '0',
  `message` varchar(1000) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `miscQueue`
--

CREATE TABLE IF NOT EXISTS `miscQueue` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `steam` bigint(17) NOT NULL,
  `command` varchar(255) NOT NULL,
  `action` varchar(15) NOT NULL,
  `value` int(11) NOT NULL DEFAULT '0',
  `timerDelay` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `otherEntities`
--

CREATE TABLE IF NOT EXISTS `otherEntities` (
  `entity` varchar(50) NOT NULL,
  `entityID` int(11) NOT NULL DEFAULT '0',
  `doNotSpawn` tinyint(4) NOT NULL DEFAULT '0',
  `doNotDespawn` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `performance`
--

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
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`serverDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `playerNotes`
--

CREATE TABLE IF NOT EXISTS `playerNotes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `createdBy` bigint(17) NOT NULL DEFAULT '0',
  `note` varchar(400) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `playerQueue`
--

CREATE TABLE IF NOT EXISTS `playerQueue` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `command` varchar(255) NOT NULL,
  `arena` tinyint(1) NOT NULL DEFAULT '0',
  `boss` tinyint(1) NOT NULL DEFAULT '0',
  `steam` bigint(17) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `players`
--

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
  `cash` float NOT NULL DEFAULT '0',
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
  `ip` varchar(15) CHARACTER SET utf8 DEFAULT NULL,
  `seen` varchar(19) CHARACTER SET utf8 DEFAULT NULL,
  `baseCooldown` int(11) NOT NULL DEFAULT '0',
  `ircAlias` varchar(15) CHARACTER SET utf8 DEFAULT NULL,
  `bed` varchar(5) CHARACTER SET utf8 DEFAULT NULL,
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
  `prisonReason` varchar(150) CHARACTER SET utf8 DEFAULT NULL,
  `prisonxPosOld` int(11) NOT NULL DEFAULT '0',
  `prisonyPosOld` int(11) NOT NULL DEFAULT '0',
  `prisonzPosOld` int(11) NOT NULL DEFAULT '0',
  `pvpVictim` bigint(17) NOT NULL DEFAULT '0',
  `aliases` varchar(255) DEFAULT NULL,
  `location` varchar(15) CHARACTER SET utf8 DEFAULT '',
  `canTeleport` tinyint(1) NOT NULL DEFAULT '1',
  `allowBadInventory` tinyint(1) NOT NULL DEFAULT '0',
  `ircTranslate` tinyint(1) NOT NULL DEFAULT '0',
  `ircPass` varchar(15) CHARACTER SET utf8 NOT NULL,
  `noSpam` tinyint(1) NOT NULL DEFAULT '0',
  `waypointX` int(11) NOT NULL DEFAULT '0',
  `waypointY` int(11) NOT NULL DEFAULT '0',
  `waypointZ` int(11) NOT NULL DEFAULT '0',
  `xPosTimeout` int(11) NOT NULL DEFAULT '0',
  `yPosTimeout` int(11) NOT NULL DEFAULT '0',
  `zPosTimeout` int(11) NOT NULL DEFAULT '0',
  `accessLevel` int(11) NOT NULL DEFAULT '99',
  `country` varchar(2) CHARACTER SET utf8 DEFAULT NULL,
  `ping` int(11) NOT NULL DEFAULT '0',
  `donorLevel` int(11) NOT NULL DEFAULT '1',
  `donorExpiry` int(11) NOT NULL DEFAULT '0',
  `autoFriend` varchar(2) CHARACTER SET utf8 NOT NULL COMMENT 'NA/AF/AD',
  `ircOtherNames` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `steamOwner` bigint(17) NOT NULL,
  `bedX` int(11) NOT NULL DEFAULT '0',
  `bedY` int(11) NOT NULL DEFAULT '0',
  `bedZ` int(11) NOT NULL DEFAULT '0',
  `showLocationMessages` tinyint(1) NOT NULL DEFAULT '1',
  `mute` tinyint(4) NOT NULL DEFAULT '0',
  `xPosOld2` int(11) NOT NULL DEFAULT '0',
  `yPosOld2` int(11) NOT NULL DEFAULT '0',
  `zPosOld2` int(11) NOT NULL DEFAULT '0',
  `ISP` varchar(25) CHARACTER SET utf8 DEFAULT NULL,
  `ignorePlayer` tinyint(1) NOT NULL DEFAULT '0',
  `ircMute` tinyint(1) NOT NULL DEFAULT '0',
  `waypoint2X` int(11) NOT NULL DEFAULT '0',
  `waypoint2Y` int(11) NOT NULL DEFAULT '0',
  `waypoint2Z` int(11) NOT NULL DEFAULT '0',
  `waypointsLinked` tinyint(1) NOT NULL DEFAULT '0',
  `chatColour` varchar(6) CHARACTER SET utf8 NOT NULL DEFAULT 'FFFFFF',
  `teleCooldown` int(11) NOT NULL DEFAULT '0',
  `reserveSlot` tinyint(4) NOT NULL DEFAULT '0',
  `prisonReleaseTime` int(11) NOT NULL DEFAULT '0',
  `ircLogin` varchar(20) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `maxWaypoints` int(11) NOT NULL DEFAULT '2',
  `waypointCooldown` int(11) NOT NULL DEFAULT '0',
  `bail` int(11) NOT NULL DEFAULT '0',
  `watchPlayerTimer` int(11) NOT NULL DEFAULT '0',
  `hackerScore` int(11) NOT NULL DEFAULT '0',
  `commandCooldown` int(11) NOT NULL DEFAULT '0',
  `pvpTeleportCooldown` int(11) NOT NULL DEFAULT '0',
  `block` tinyint(1) NOT NULL DEFAULT '0',
  `removedClaims` int(11) NOT NULL DEFAULT '0',
  `returnCooldown` int(11) NOT NULL DEFAULT '0',
  `gimmeCooldown` int(11) NOT NULL DEFAULT '0',
  `VACBanned` tinyint(1) NOT NULL DEFAULT '0',
  `bountyReason` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`steam`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `polls`
--

CREATE TABLE IF NOT EXISTS `polls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
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
  `accessLevel` int(11) NOT NULL DEFAULT '90',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `pollVotes`
--

CREATE TABLE IF NOT EXISTS `pollVotes` (
  `pollID` int(11) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `vote` int(11) NOT NULL DEFAULT '0',
  `weight` float NOT NULL DEFAULT '1',
  PRIMARY KEY (`pollID`,`steam`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `prefabCopies`
--

CREATE TABLE IF NOT EXISTS `prefabCopies` (
  `owner` bigint(17) NOT NULL DEFAULT '0',
  `name` varchar(50) NOT NULL DEFAULT '',
  `x1` int(11) NOT NULL DEFAULT '0',
  `x2` int(11) NOT NULL DEFAULT '0',
  `y1` int(11) NOT NULL DEFAULT '0',
  `y2` int(11) NOT NULL DEFAULT '0',
  `z1` int(11) NOT NULL DEFAULT '0',
  `z2` int(11) NOT NULL DEFAULT '0',
  `blockName` varchar(50) NOT NULL DEFAULT '',
  `rotation` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`owner`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `proxies`
--

CREATE TABLE IF NOT EXISTS `proxies` (
  `scanString` varchar(100) NOT NULL,
  `action` varchar(20) NOT NULL DEFAULT 'nothing',
  `hits` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`scanString`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `reservedSlots`
--

CREATE TABLE IF NOT EXISTS `reservedSlots` (
  `steam` bigint(17) NOT NULL,
  `timeAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reserved` tinyint(1) NOT NULL DEFAULT '0',
  `staff` tinyint(1) NOT NULL DEFAULT '0',
  `totalPlayTime` int(11) NOT NULL DEFAULT '0',
  `deleteRow` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steam`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `resetZones`
--

CREATE TABLE IF NOT EXISTS `resetZones` (
  `region` varchar(20) NOT NULL DEFAULT '',
  `x1` int(11) DEFAULT '0',
  `z1` int(11) DEFAULT '0',
  `x2` int(11) DEFAULT '0',
  `z2` int(11) DEFAULT '0',
  PRIMARY KEY (`region`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `restrictedItems`
--

CREATE TABLE IF NOT EXISTS `restrictedItems` (
  `item` varchar(50) NOT NULL,
  `qty` int(11) NOT NULL DEFAULT '65',
  `accessLevel` int(11) NOT NULL DEFAULT '90',
  `action` varchar(30) NOT NULL,
  `validated` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `searchResults`
--

CREATE TABLE IF NOT EXISTS `searchResults` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `owner` bigint(17) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `x` int(11) DEFAULT NULL,
  `y` int(11) DEFAULT NULL,
  `z` int(11) DEFAULT NULL,
  `session` int(11) DEFAULT NULL,
  `date` varchar(20) DEFAULT NULL,
  `counter` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `server`
--

CREATE TABLE IF NOT EXISTS `server` (
  `rules` varchar(1000) DEFAULT 'A zombie ate the server rules! Tell an admin.',
  `shopCountdown` int(11) NOT NULL DEFAULT '0',
  `gimmePeace` tinyint(1) NOT NULL DEFAULT '0',
  `date` varchar(10) DEFAULT NULL,
  `windowDebug` varchar(15) NOT NULL DEFAULT 'Debug',
  `ServerPort` int(11) NOT NULL DEFAULT '0',
  `windowAlerts` varchar(15) NOT NULL DEFAULT 'Alerts',
  `allowGimme` tinyint(1) NOT NULL DEFAULT '0',
  `mapSize` int(11) NOT NULL DEFAULT '10000',
  `ircAlerts` varchar(50) NOT NULL DEFAULT '#new_alerts',
  `ircWatch` varchar(50) NOT NULL DEFAULT '#new_watch',
  `prisonSize` int(11) NOT NULL DEFAULT '30',
  `MOTD` varchar(255) DEFAULT 'We have a new server bot!',
  `IP` varchar(100) DEFAULT '0.0.0.0',
  `lottery` float NOT NULL DEFAULT '0',
  `allowShop` tinyint(1) NOT NULL DEFAULT '0',
  `windowGMSG` varchar(15) NOT NULL DEFAULT 'GMSG',
  `botName` varchar(30) NOT NULL DEFAULT 'Bot',
  `allowWaypoints` tinyint(1) NOT NULL DEFAULT '0',
  `windowLists` varchar(15) NOT NULL DEFAULT 'Lists',
  `ircMain` varchar(50) NOT NULL DEFAULT '#new',
  `chatColour` varchar(6) NOT NULL DEFAULT 'D4FFD4',
  `maxPlayers` int(11) NOT NULL DEFAULT '24',
  `dailyRebootHour` int(11) NOT NULL DEFAULT '0',
  `maxServerUptime` int(11) NOT NULL DEFAULT '12',
  `windowPlayers` varchar(15) NOT NULL DEFAULT 'Players',
  `baseSize` int(11) NOT NULL DEFAULT '32',
  `baseCooldown` int(11) NOT NULL DEFAULT '2400',
  `protectionMaxDays` int(11) NOT NULL DEFAULT '40',
  `ircBotName` varchar(30) NOT NULL DEFAULT 'Bot',
  `serverName` varchar(50) NOT NULL DEFAULT 'New Server',
  `lastDailyReboot` int(11) NOT NULL DEFAULT '0',
  `allowNumericNames` tinyint(1) NOT NULL DEFAULT '1',
  `allowGarbageNames` tinyint(1) NOT NULL DEFAULT '1',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `allowReboot` tinyint(1) NOT NULL DEFAULT '1',
  `newPlayerTimer` int(11) NOT NULL DEFAULT '120',
  `blacklistResponse` varchar(20) NOT NULL DEFAULT 'ban',
  `gameDay` int(11) NOT NULL DEFAULT '0',
  `welcome` varchar(255) DEFAULT NULL,
  `allowVoting` tinyint(1) NOT NULL DEFAULT '0',
  `allowPlayerVoteTopics` tinyint(1) NOT NULL DEFAULT '0',
  `shopOpenHour` int(11) NOT NULL DEFAULT '0',
  `shopCloseHour` int(11) NOT NULL DEFAULT '0',
  `shopLocation` varchar(30) DEFAULT NULL,
  `website` varchar(100) DEFAULT NULL,
  `ircServer` varchar(100) DEFAULT NULL,
  `pingKick` int(11) NOT NULL DEFAULT '-1',
  `longPlayUpgradeTime` int(11) NOT NULL DEFAULT '0',
  `gameType` varchar(3) NOT NULL DEFAULT 'pve',
  `hideCommands` tinyint(1) NOT NULL DEFAULT '1',
  `botTick` int(11) NOT NULL DEFAULT '0',
  `serverGroup` varchar(20) DEFAULT NULL,
  `botID` int(11) NOT NULL DEFAULT '0',
  `allowOverstacking` tinyint(1) NOT NULL DEFAULT '0',
  `announceTeleports` tinyint(1) NOT NULL,
  `blacklistCountries` varchar(100) NOT NULL DEFAULT 'CN,HK',
  `northeastZone` varchar(5) DEFAULT NULL,
  `northwestZone` varchar(5) DEFAULT NULL,
  `southeastZone` varchar(5) DEFAULT NULL,
  `southwestZone` varchar(5) DEFAULT NULL,
  `allowPhysics` tinyint(1) NOT NULL DEFAULT '1',
  `playersCanFly` tinyint(1) NOT NULL DEFAULT '0',
  `accessLevelOverride` int(11) NOT NULL DEFAULT '99',
  `disableBaseProtection` tinyint(1) NOT NULL DEFAULT '0',
  `packCooldown` int(11) NOT NULL DEFAULT '0',
  `moneyName` varchar(40) NOT NULL DEFAULT 'Zenny|Zennies',
  `allowBank` tinyint(1) NOT NULL DEFAULT '1',
  `overstackThreshold` int(11) NOT NULL DEFAULT '1000',
  `enableRegionPM` tinyint(1) NOT NULL DEFAULT '0',
  `allowRapidRelogging` tinyint(4) NOT NULL DEFAULT '1',
  `allowLottery` tinyint(4) NOT NULL DEFAULT '1',
  `lotteryMultiplier` int(11) NOT NULL DEFAULT '4',
  `zombieKillReward` int(11) NOT NULL DEFAULT '3',
  `ircTracker` varchar(50) NOT NULL DEFAULT '#new_tracker',
  `allowTeleporting` tinyint(1) NOT NULL DEFAULT '1',
  `hardcore` tinyint(1) NOT NULL DEFAULT '0',
  `swearJar` tinyint(1) NOT NULL DEFAULT '0',
  `swearCash` int(11) NOT NULL DEFAULT '0',
  `idleKick` tinyint(1) NOT NULL DEFAULT '0',
  `swearFine` int(11) NOT NULL DEFAULT '5',
  `ircPrivate` tinyint(1) NOT NULL DEFAULT '0',
  `waypointsPublic` tinyint(1) NOT NULL DEFAULT '0',
  `waypointCost` int(11) NOT NULL DEFAULT '0',
  `waypointCooldown` int(11) NOT NULL DEFAULT '0',
  `alertColour` varchar(6) NOT NULL DEFAULT 'DC143C',
  `warnColour` varchar(6) NOT NULL DEFAULT 'FFA500',
  `teleportCost` int(11) NOT NULL DEFAULT '200',
  `commandPrefix` varchar(1) NOT NULL DEFAULT '/',
  `chatlogPath` varchar(200) NOT NULL DEFAULT '',
  `botVersion` varchar(20) NOT NULL DEFAULT '',
  `packCost` int(11) NOT NULL DEFAULT '0',
  `baseCost` int(11) NOT NULL DEFAULT '0',
  `rebootHour` int(11) NOT NULL DEFAULT '-1',
  `rebootMinute` int(11) NOT NULL DEFAULT '0',
  `maxPrisonTime` int(11) NOT NULL DEFAULT '-1',
  `bailCost` int(11) NOT NULL DEFAULT '0',
  `maxWaypoints` int(11) NOT NULL DEFAULT '2',
  `teleportPublicCost` int(11) NOT NULL DEFAULT '0',
  `teleportPublicCooldown` int(11) NOT NULL DEFAULT '0',
  `reservedSlots` int(11) NOT NULL DEFAULT '0',
  `allowReturns` tinyint(1) NOT NULL DEFAULT '1',
  `scanNoclip` tinyint(1) NOT NULL DEFAULT '1',
  `scanEntities` tinyint(1) NOT NULL DEFAULT '0',
  `CBSMFriendly` tinyint(1) NOT NULL DEFAULT '1',
  `ServerToolsDetected` tinyint(1) NOT NULL DEFAULT '0',
  `disableTPinPVP` tinyint(1) NOT NULL DEFAULT '0',
  `updateBot` tinyint(1) NOT NULL DEFAULT '1',
  `waypointCreateCost` int(11) NOT NULL DEFAULT '0',
  `scanErrors` tinyint(1) NOT NULL DEFAULT '0',
  `alertSpending` tinyint(1) NOT NULL DEFAULT '0',
  `GBLBanThreshold` int(11) NOT NULL DEFAULT '0',
  `lastBotsMessageID` int(11) NOT NULL DEFAULT '0',
  `lastBotsMessageTimestamp` int(11) NOT NULL DEFAULT '0',
  `gimmeZombies` tinyint(1) NOT NULL DEFAULT '1',
  `allowProxies` tinyint(1) NOT NULL DEFAULT '0',
  `SDXDetected` tinyint(1) NOT NULL DEFAULT '0',
  `enableWindowMessages` tinyint(1) NOT NULL DEFAULT '0',
  `updateBranch` varchar(30) NOT NULL DEFAULT 'stable',
  `chatColourNewPlayer` varchar(6) NOT NULL DEFAULT 'FFFFFF',
  `chatColourPlayer` varchar(6) NOT NULL DEFAULT 'FFFFFF',
  `chatColourDonor` varchar(6) NOT NULL DEFAULT 'FFFFFF',
  `chatColourPrisoner` varchar(6) NOT NULL DEFAULT 'FFFFFF',
  `chatColourMod` varchar(6) NOT NULL DEFAULT 'FFFFFF',
  `chatColourAdmin` varchar(6) NOT NULL DEFAULT 'FFFFFF',
  `chatColourOwner` varchar(6) NOT NULL DEFAULT 'FFFFFF',
  `commandCooldown` int(11) NOT NULL DEFAULT '0',
  `telnetPass` varchar(50) NOT NULL,
  `telnetPort` int(11) NOT NULL DEFAULT '0',
  `feralRebootDelay` int(11) NOT NULL DEFAULT '68',
  `pvpTeleportCooldown` int(11) NOT NULL DEFAULT '0',
  `allowPlayerToPlayerTeleporting` tinyint(1) NOT NULL DEFAULT '1',
  `ircPort` int(11) NOT NULL DEFAULT '6667',
  `botRestartHour` int(11) NOT NULL DEFAULT '25',
  `trackingKeepDays` int(11) NOT NULL DEFAULT '14',
  `databaseMaintenanceFinished` tinyint(1) NOT NULL DEFAULT '1',
  `allowHomeTeleport` tinyint(1) NOT NULL DEFAULT '1',
  `playerTeleportDelay` int(11) NOT NULL DEFAULT '0',
  `allowPackTeleport` tinyint(1) NOT NULL DEFAULT '1',
  `gameVersion` varchar(30) NOT NULL DEFAULT '',
  `pvpIgnoreFriendlyKills` tinyint(1) NOT NULL DEFAULT '0',
  `allowStuckTeleport` tinyint(1) NOT NULL DEFAULT '1',
  `restrictIRC` tinyint(1) NOT NULL DEFAULT '0',
  `nextAnnouncement` int(11) NOT NULL DEFAULT '1',
  `pvpAllowProtect` tinyint(4) NOT NULL DEFAULT '0',
  `hackerTPDetection` tinyint(1) NOT NULL DEFAULT '1',
  `whitelistCountries` varchar(50) NOT NULL DEFAULT '',
  `perMinutePayRate` float NOT NULL DEFAULT '0',
  `disableWatchAlerts` tinyint(4) NOT NULL DEFAULT '0',
  `masterPassword` varchar(50) NOT NULL DEFAULT '',
  `allowBotRestarts` tinyint(4) NOT NULL DEFAULT '0',
  `botOwner` varchar(17) NOT NULL DEFAULT '0',
  `returnCooldown` int(11) NOT NULL DEFAULT '0',
  `botRestartDay` int(11) NOT NULL DEFAULT '7',
  `enableTimedClaimScan` tinyint(1) NOT NULL DEFAULT '1',
  `enableScreamerAlert` tinyint(1) NOT NULL DEFAULT '1',
  `enableAirdropAlert` tinyint(1) NOT NULL DEFAULT '1',
  `spleefGameCoords` varchar(20) NOT NULL DEFAULT '4000 225 4000',
  `gimmeResetTime` int(11) NOT NULL DEFAULT '120',
  `gimmeRaincheck` int(11) NOT NULL DEFAULT '0',
  `pingKickTarget` varchar(3) NOT NULL DEFAULT 'new',
  `enableBounty` tinyint(1) NOT NULL DEFAULT '1',
  `mapSizeNewPlayers` int(11) NOT NULL DEFAULT '10000',
  `mapSizePlayers` int(11) NOT NULL DEFAULT '10000',
  `shopResetDays` int(11) NOT NULL DEFAULT '3',
  `telnetLogKeepDays` int(11) NOT NULL DEFAULT '14',
  `maxWaypointsDonors` int(11) NOT NULL DEFAULT '2',
  `baseProtectionExpiryDays` int(11) NOT NULL DEFAULT '40',
  `banVACBannedPlayers` tinyint(1) NOT NULL DEFAULT '0',
  `deathCost` int(11) NOT NULL DEFAULT '0',
  `showLocationMessages` tinyint(1) NOT NULL DEFAULT '1',
  `bountyRewardItem` varchar(25) NOT NULL DEFAULT 'cash',
  `enableLagCheck` tinyint(1) NOT NULL DEFAULT '1',
  `allowSecondBaseWithoutDonor` tinyint(1) NOT NULL DEFAULT '0',
  `nonAlphabeticChatReaction` varchar(10) NOT NULL DEFAULT 'nothing',
  `lotteryTicketPrice` int(11) NOT NULL DEFAULT '25',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `shop`
--

CREATE TABLE IF NOT EXISTS `shop` (
  `item` varchar(50) NOT NULL,
  `category` varchar(20) NOT NULL,
  `price` int(11) NOT NULL DEFAULT '50',
  `stock` int(11) NOT NULL DEFAULT '50',
  `idx` int(11) NOT NULL DEFAULT '0',
  `maxStock` int(11) NOT NULL DEFAULT '50',
  `variation` int(11) NOT NULL DEFAULT '0',
  `special` int(11) NOT NULL DEFAULT '0',
  `validated` tinyint(1) NOT NULL DEFAULT '1',
  `units` int(1) NOT NULL,
  `quality` int(11) NOT NULL,
  PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `shopCategories`
--

CREATE TABLE IF NOT EXISTS `shopCategories` (
  `category` varchar(20) NOT NULL,
  `idx` int(11) NOT NULL,
  `code` varchar(3) NOT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `spawnableItems`
--

CREATE TABLE IF NOT EXISTS `spawnableItems` (
  `itemName` varchar(100) NOT NULL,
  `deleteItem` tinyint(1) NOT NULL DEFAULT '0',
  `accessLevelRestriction` int(11) NOT NULL DEFAULT '99',
  `category` varchar(20) NOT NULL DEFAULT 'None',
  `price` int(11) NOT NULL DEFAULT '10000',
  `stock` int(11) NOT NULL DEFAULT '5000',
  `idx` int(11) NOT NULL DEFAULT '0',
  `maxStock` int(11) NOT NULL DEFAULT '5000',
  `inventoryResponse` varchar(10) NOT NULL DEFAULT 'none',
  `StackLimit` int(11) NOT NULL DEFAULT '1000',
  `newPlayerMaxInventory` int(11) NOT NULL DEFAULT '-1',
  `units` int(11) NOT NULL DEFAULT '1',
  `craftable` tinyint(1) NOT NULL DEFAULT '1',
  `devBlock` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`itemName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `staff`
--

CREATE TABLE IF NOT EXISTS `staff` (
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `adminLevel` int(11) NOT NULL DEFAULT '2',
  `blockDelete` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steam`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `teleports`
--

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
  `public` tinyint(1) NOT NULL DEFAULT '0',
  `size` float NOT NULL DEFAULT '1.5' COMMENT 'size of start tp',
  `dsize` float NOT NULL DEFAULT '1.5' COMMENT 'size of dest tp',
  `minimumAccess` int(11) NOT NULL DEFAULT '0',
  `maximumAccess` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `timedEvents`
--

CREATE TABLE IF NOT EXISTS `timedEvents` (
  `timer` varchar(20) NOT NULL DEFAULT '',
  `delayMinutes` int(11) NOT NULL DEFAULT '10',
  `nextTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `disabled` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`timer`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `tracker`
--

CREATE TABLE IF NOT EXISTS `tracker` (
  `trackerID` bigint(20) NOT NULL AUTO_INCREMENT,
  `steam` bigint(17) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `session` int(11) DEFAULT '0',
  `flag` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`trackerID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `villagers`
--

CREATE TABLE IF NOT EXISTS `villagers` (
  `steam` bigint(17) NOT NULL,
  `village` varchar(20) NOT NULL,
  PRIMARY KEY (`steam`,`village`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `waypoints`
--

CREATE TABLE IF NOT EXISTS `waypoints` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `name` varchar(30) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `linked` int(11) NOT NULL DEFAULT '0',
  `shared` tinyint(4) NOT NULL DEFAULT '0',
  `public` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `webInterfaceQueue`
--

CREATE TABLE IF NOT EXISTS `webInterfaceQueue` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `action` varchar(10) NOT NULL DEFAULT '',
  `actionTable` varchar(50) NOT NULL DEFAULT '',
  `actionQuery` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `whitelist`
--

CREATE TABLE IF NOT EXISTS `whitelist` (
  `steam` bigint(17) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steam`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
