-- phpMyAdmin SQL Dump
-- version 4.6.6
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jul 08, 2017 at 09:19 AM
-- Server version: 10.1.24-MariaDB
-- PHP Version: 7.0.20

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `botman`
--

-- --------------------------------------------------------

--
-- Table structure for table `alerts`
--

CREATE TABLE `alerts` (
  `alertID` bigint(20) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `message` varchar(255) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `sent` tinyint(1) NOT NULL DEFAULT '0',
  `status` varchar(30) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `altertables`
--

CREATE TABLE `altertables` (
  `id` int(11) NOT NULL,
  `statement` varchar(1000) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `announcements`
--

CREATE TABLE `announcements` (
  `id` int(11) NOT NULL,
  `message` varchar(400) NOT NULL,
  `startDate` date DEFAULT NULL,
  `endDate` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `badItems`
--

CREATE TABLE `badItems` (
  `item` varchar(50) NOT NULL,
  `action` varchar(10) NOT NULL DEFAULT 'timeout'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `badWords`
--

CREATE TABLE `badWords` (
  `badWord` varchar(15) NOT NULL,
  `cost` int(11) NOT NULL DEFAULT '10',
  `counter` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `bans`
--

CREATE TABLE `bans` (
  `BannedTo` varchar(22) NOT NULL,
  `Steam` bigint(17) NOT NULL,
  `Reason` varchar(255) DEFAULT NULL,
  `expiryDate` datetime NOT NULL,
  `bannedOn` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `bookmarks`
--

CREATE TABLE `bookmarks` (
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

CREATE TABLE `commandQueue` (
  `id` bigint(20) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `command` varchar(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `customCommands`
--

CREATE TABLE `customCommands` (
  `commandID` int(11) NOT NULL,
  `command` varchar(50) NOT NULL,
  `accessLevel` int(11) NOT NULL DEFAULT '2',
  `help` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `customCommands_Detail`
--

CREATE TABLE `customCommands_Detail` (
  `detailID` int(11) NOT NULL,
  `commandID` int(11) NOT NULL,
  `action` varchar(5) NOT NULL DEFAULT '' COMMENT 'say,give,tele,spawn,buff,cmd',
  `thing` varchar(50) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `customMessages`
--

CREATE TABLE `customMessages` (
  `command` varchar(30) NOT NULL,
  `message` varchar(255) NOT NULL,
  `accessLevel` int(11) NOT NULL DEFAULT '99'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `events`
--

CREATE TABLE `events` (
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

CREATE TABLE `friends` (
  `steam` bigint(17) NOT NULL,
  `friend` bigint(17) NOT NULL DEFAULT '0',
  `autoAdded` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `gimmePrizes`
--

CREATE TABLE `gimmePrizes` (
  `name` varchar(20) NOT NULL,
  `category` varchar(15) NOT NULL,
  `prizeLimit` int(11) NOT NULL DEFAULT '1',
  `quality` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `gimmeQueue`
--

CREATE TABLE `gimmeQueue` (
  `id` int(11) NOT NULL,
  `command` varchar(255) NOT NULL,
  `steam` bigint(17) NOT NULL DEFAULT '0'
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `gimmeZombies`
--

CREATE TABLE `gimmeZombies` (
  `zombie` varchar(50) NOT NULL,
  `minPlayerLevel` int(11) NOT NULL DEFAULT '1',
  `minArenaLevel` int(11) NOT NULL DEFAULT '1',
  `entityID` int(11) NOT NULL DEFAULT '0',
  `bossZombie` tinyint(1) NOT NULL DEFAULT '0',
  `doNotSpawn` tinyint(4) NOT NULL DEFAULT '0',
  `maxHealth` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `helpCommands`
--

CREATE TABLE `helpCommands` (
  `commandID` int(11) NOT NULL,
  `command` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `notes` text NOT NULL,
  `keywords` varchar(150) NOT NULL,
  `lastUpdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `accessLevel` int(11) NOT NULL DEFAULT '99',
  `ingameOnly` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `helpTopicCommands`
--

CREATE TABLE `helpTopicCommands` (
  `topicID` int(11) NOT NULL,
  `commandID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `helpTopics`
--

CREATE TABLE `helpTopics` (
  `topicID` int(11) NOT NULL,
  `topic` varchar(20) NOT NULL,
  `description` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `hotspots`
--

CREATE TABLE `hotspots` (
  `id` int(11) NOT NULL,
  `idx` int(11) NOT NULL DEFAULT '0',
  `hotspot` varchar(255) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `size` int(11) NOT NULL DEFAULT '2',
  `owner` bigint(17) NOT NULL,
  `action` varchar(10) NOT NULL DEFAULT '',
  `destination` varchar(20) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `inventoryChanges`
--

CREATE TABLE `inventoryChanges` (
  `id` bigint(20) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `item` varchar(30) NOT NULL,
  `delta` int(11) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `session` int(11) NOT NULL,
  `flag` varchar(3) NOT NULL DEFAULT '',
  `Quality` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `inventoryTracker`
--

CREATE TABLE `inventoryTracker` (
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

CREATE TABLE `IPBlacklist` (
  `StartIP` bigint(15) NOT NULL,
  `EndIP` bigint(15) NOT NULL,
  `Country` varchar(2) DEFAULT NULL,
  `DateAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `botID` int(11) NOT NULL DEFAULT '0',
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `playerName` varchar(25) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `ircQueue`
--

CREATE TABLE `ircQueue` (
  `id` int(11) NOT NULL,
  `name` varchar(20) NOT NULL,
  `command` varchar(768) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `keystones`
--

CREATE TABLE `keystones` (
  `steam` bigint(20) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `remove` tinyint(1) NOT NULL DEFAULT '0',
  `removed` int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `list`
--

CREATE TABLE `list` (
  `thing` varchar(255) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=latin1 COMMENT='For sorting a list';

-- --------------------------------------------------------

--
-- Table structure for table `locations`
--

CREATE TABLE `locations` (
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
  `prisonZ` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `locationSpawns`
--

CREATE TABLE `locationSpawns` (
  `location` varchar(20) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `lottery`
--

CREATE TABLE `lottery` (
  `steam` varchar(17) NOT NULL,
  `ticket` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `mail`
--

CREATE TABLE `mail` (
  `id` bigint(20) NOT NULL,
  `sender` bigint(17) NOT NULL,
  `recipient` bigint(17) DEFAULT '0',
  `message` varchar(500) NOT NULL,
  `status` int(11) NOT NULL DEFAULT '0',
  `flag` varchar(5) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `memEntities`
--

CREATE TABLE `memEntities` (
  `entityID` bigint(20) NOT NULL,
  `type` varchar(20) NOT NULL DEFAULT '',
  `name` varchar(30) NOT NULL DEFAULT '',
  `x` int(11) NOT NULL DEFAULT '0',
  `y` int(11) NOT NULL DEFAULT '0',
  `z` int(11) DEFAULT '0',
  `dead` tinyint(1) NOT NULL DEFAULT '0',
  `health` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `memIgnoredItems`
--

CREATE TABLE `memIgnoredItems` (
  `item` varchar(50) NOT NULL,
  `qty` int(11) NOT NULL DEFAULT '65'
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `memLottery`
--

CREATE TABLE `memLottery` (
  `steam` varchar(17) NOT NULL,
  `ticket` int(11) NOT NULL DEFAULT '0'
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `memRestrictedItems`
--

CREATE TABLE `memRestrictedItems` (
  `item` varchar(50) NOT NULL,
  `qty` int(11) NOT NULL DEFAULT '65',
  `accessLevel` int(11) NOT NULL DEFAULT '90',
  `action` varchar(30) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `memShop`
--

CREATE TABLE `memShop` (
  `item` varchar(50) NOT NULL,
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

CREATE TABLE `memTracker` (
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

CREATE TABLE `messageQueue` (
  `id` bigint(20) NOT NULL,
  `sender` bigint(17) NOT NULL DEFAULT '0',
  `recipient` bigint(20) NOT NULL DEFAULT '0',
  `message` varchar(1000) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `miscQueue`
--

CREATE TABLE `miscQueue` (
  `id` bigint(20) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `command` varchar(255) NOT NULL,
  `action` varchar(15) NOT NULL,
  `value` int(11) NOT NULL DEFAULT '0',
  `timerDelay` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `otherEntities`
--

CREATE TABLE `otherEntities` (
  `entity` varchar(50) NOT NULL,
  `entityID` int(11) NOT NULL DEFAULT '0',
  `doNotSpawn` tinyint(4) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `performance`
--

CREATE TABLE `performance` (
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

CREATE TABLE `playerNotes` (
  `id` int(11) NOT NULL,
  `steam` varchar(17) NOT NULL,
  `createdBy` varchar(17) NOT NULL,
  `note` varchar(400) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `playerQueue`
--

CREATE TABLE `playerQueue` (
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

CREATE TABLE `players` (
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
  `location` varchar(15) DEFAULT '',
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
  `steamOwner` bigint(17) NOT NULL,
  `bedX` int(11) NOT NULL DEFAULT '0',
  `bedY` int(11) NOT NULL DEFAULT '0',
  `bedZ` int(11) NOT NULL DEFAULT '0',
  `showLocationMessages` tinyint(1) NOT NULL DEFAULT '1',
  `mute` tinyint(4) NOT NULL DEFAULT '0',
  `xPosOld2` int(11) NOT NULL DEFAULT '0',
  `yPosOld2` int(11) NOT NULL DEFAULT '0',
  `zPosOld2` int(11) NOT NULL DEFAULT '0',
  `ISP` varchar(25) DEFAULT NULL,
  `ignorePlayer` tinyint(1) NOT NULL DEFAULT '0',
  `ircMute` tinyint(1) NOT NULL DEFAULT '0',
  `waypoint2X` int(11) NOT NULL DEFAULT '0',
  `waypoint2Y` int(11) NOT NULL DEFAULT '0',
  `waypoint2Z` int(11) NOT NULL DEFAULT '0',
  `waypointsLinked` tinyint(1) NOT NULL DEFAULT '0',
  `chatColour` varchar(8) NOT NULL DEFAULT '',
  `teleCooldown` int(11) NOT NULL DEFAULT '0',
  `reserveSlot` tinyint(4) NOT NULL DEFAULT '0',
  `prisonReleaseTime` int(11) NOT NULL DEFAULT '0',
  `maxWaypoints` int(11) NOT NULL DEFAULT '2',
  `ircLogin` varchar(20) NOT NULL DEFAULT '',
  `waypointCooldown` int(11) NOT NULL DEFAULT '0',
  `bail` int(11) NOT NULL DEFAULT '0',
  `watchPlayerTimer` int(11) NOT NULL DEFAULT '0',
  `hackerScore` int(11) NOT NULL DEFAULT '0',
  `pvpTeleportCooldown` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `polls`
--

CREATE TABLE `polls` (
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

CREATE TABLE `pollVotes` (
  `pollID` int(11) NOT NULL,
  `steam` bigint(17) NOT NULL,
  `vote` int(11) NOT NULL DEFAULT '0',
  `weight` float NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `prefabCopies`
--

CREATE TABLE `prefabCopies` (
  `owner` bigint(17) NOT NULL DEFAULT '0',
  `name` varchar(50) NOT NULL DEFAULT '',
  `x1` int(11) NOT NULL DEFAULT '0',
  `x2` int(11) NOT NULL DEFAULT '0',
  `y1` int(11) NOT NULL DEFAULT '0',
  `y2` int(11) NOT NULL DEFAULT '0',
  `z1` int(11) NOT NULL DEFAULT '0',
  `z2` int(11) NOT NULL DEFAULT '0',
  `blockName` varchar(50) NOT NULL DEFAULT '',
  `rotation` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `proxies`
--

CREATE TABLE `proxies` (
  `scanString` varchar(100) NOT NULL,
  `action` varchar(20) NOT NULL DEFAULT 'nothing',
  `hits` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `resetZones`
--

CREATE TABLE `resetZones` (
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

CREATE TABLE `restrictedItems` (
  `item` varchar(50) NOT NULL,
  `qty` int(11) NOT NULL DEFAULT '65',
  `accessLevel` int(11) NOT NULL DEFAULT '90',
  `action` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `searchResults`
--

CREATE TABLE `searchResults` (
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

CREATE TABLE `server` (
  `rules` varchar(255) DEFAULT 'No rules',
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
  `IP` varchar(15) DEFAULT '0.0.0.0',
  `lottery` int(11) NOT NULL DEFAULT '0',
  `allowShop` tinyint(1) NOT NULL DEFAULT '0',
  `windowGMSG` varchar(15) NOT NULL DEFAULT 'GMSG',
  `botName` varchar(30) NOT NULL DEFAULT 'Bot',
  `allowWaypoints` tinyint(1) NOT NULL DEFAULT '0',
  `windowLists` varchar(15) NOT NULL DEFAULT 'Lists',
  `ircMain` varchar(50) NOT NULL DEFAULT '#new',
  `chatColour` varchar(6) NOT NULL DEFAULT 'D4FFD4',
  `maxPlayers` int(11) NOT NULL DEFAULT '24',
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
  `blockCountries` varchar(100) NOT NULL DEFAULT 'CN',
  `northeastZone` varchar(5) DEFAULT NULL,
  `northwestZone` varchar(5) DEFAULT NULL,
  `southeastZone` varchar(5) DEFAULT NULL,
  `southwestZone` varchar(5) DEFAULT NULL,
  `allowPhysics` tinyint(1) NOT NULL DEFAULT '1',
  `playersCanFly` tinyint(1) NOT NULL DEFAULT '0',
  `accessLevelOverride` int(11) NOT NULL DEFAULT '99',
  `disableBaseProtection` tinyint(1) NOT NULL DEFAULT '0',
  `packCooldown` int(11) NOT NULL DEFAULT '0',
  `moneyName` varchar(50) NOT NULL DEFAULT 'Zenny|Zennies',
  `allowBank` tinyint(1) NOT NULL DEFAULT '1',
  `overstackThreshold` int(11) NOT NULL DEFAULT '1000',
  `enableRegionPM` tinyint(1) NOT NULL DEFAULT '1',
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
  `waypointsPublic` tinyint(1) NOT NULL DEFAULT '0',
  `waypointCost` int(11) NOT NULL DEFAULT '0',
  `waypointCooldown` int(11) NOT NULL DEFAULT '0',
  `ircPrivate` tinyint(1) NOT NULL DEFAULT '0',
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
  `waypointCreateCost` int(11) NOT NULL DEFAULT '0',
  `scanErrors` tinyint(1) NOT NULL DEFAULT '0',
  `disableTPinPVP` tinyint(1) NOT NULL DEFAULT '0',
  `updateBot` tinyint(1) NOT NULL DEFAULT '0',
  `alertSpending` tinyint(1) NOT NULL DEFAULT '0',
  `GBLBanThreshold` int(11) NOT NULL DEFAULT '0',
  `lastBotsMessageID` int(11) NOT NULL DEFAULT '0',
  `lastBotsMessageTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `gimmeZombies` tinyint(1) NOT NULL DEFAULT '1',
  `allowProxies` tinyint(1) NOT NULL DEFAULT '0',
  `SDXDetected` tinyint(1) NOT NULL DEFAULT '0',
  `enableWindowMessages` tinyint(1) NOT NULL DEFAULT '0',
  `updateBranch` varchar(7) NOT NULL DEFAULT 'stable',
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
  `trackingKeepDays` int(11) NOT NULL DEFAULT '28',
  `databaseMaintenanceFinished` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `shop`
--

CREATE TABLE `shop` (
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

CREATE TABLE `shopCategories` (
  `category` varchar(20) NOT NULL,
  `idx` int(11) NOT NULL,
  `code` varchar(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `staff`
--

CREATE TABLE `staff` (
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `adminLevel` int(11) NOT NULL DEFAULT '2',
  `blockDelete` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `teleports`
--

CREATE TABLE `teleports` (
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

CREATE TABLE `tracker` (
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

CREATE TABLE `villagers` (
  `steam` bigint(17) NOT NULL,
  `village` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `waypoints`
--

CREATE TABLE `waypoints` (
  `id` int(11) NOT NULL,
  `steam` varchar(17) NOT NULL,
  `name` varchar(30) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `z` int(11) NOT NULL,
  `linked` int(11) NOT NULL DEFAULT '0',
  `shared` tinyint(4) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `whitelist`
--

CREATE TABLE `whitelist` (
  `steam` varchar(17) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `alerts`
--
ALTER TABLE `alerts`
  ADD PRIMARY KEY (`alertID`);

--
-- Indexes for table `altertables`
--
ALTER TABLE `altertables`
  ADD PRIMARY KEY (`id`);

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
-- Indexes for table `badWords`
--
ALTER TABLE `badWords`
  ADD UNIQUE KEY `badWord` (`badWord`);

--
-- Indexes for table `bans`
--
ALTER TABLE `bans`
  ADD PRIMARY KEY (`Steam`),
  ADD KEY `bannedOn` (`bannedOn`),
  ADD KEY `name` (`name`);

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
-- Indexes for table `customCommands`
--
ALTER TABLE `customCommands`
  ADD PRIMARY KEY (`commandID`);

--
-- Indexes for table `customCommands_Detail`
--
ALTER TABLE `customCommands_Detail`
  ADD PRIMARY KEY (`detailID`),
  ADD KEY `commandID` (`commandID`);

--
-- Indexes for table `customMessages`
--
ALTER TABLE `customMessages`
  ADD PRIMARY KEY (`command`);

--
-- Indexes for table `events`
--
ALTER TABLE `events`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD KEY `id_2` (`id`);

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
-- Indexes for table `gimmeZombies`
--
ALTER TABLE `gimmeZombies`
  ADD PRIMARY KEY (`zombie`);

--
-- Indexes for table `helpCommands`
--
ALTER TABLE `helpCommands`
  ADD PRIMARY KEY (`commandID`);

--
-- Indexes for table `helpTopicCommands`
--
ALTER TABLE `helpTopicCommands`
  ADD PRIMARY KEY (`topicID`,`commandID`);

--
-- Indexes for table `helpTopics`
--
ALTER TABLE `helpTopics`
  ADD PRIMARY KEY (`topicID`);

--
-- Indexes for table `hotspots`
--
ALTER TABLE `hotspots`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `inventoryChanges`
--
ALTER TABLE `inventoryChanges`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD UNIQUE KEY `id_2` (`id`),
  ADD UNIQUE KEY `id_5` (`id`),
  ADD KEY `steam` (`steam`),
  ADD KEY `id_3` (`id`),
  ADD KEY `id_4` (`id`),
  ADD KEY `Quality` (`Quality`),
  ADD KEY `item` (`item`,`Quality`);

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
  ADD PRIMARY KEY (`steam`,`x`,`y`,`z`),
  ADD KEY `steam` (`steam`),
  ADD KEY `steam_2` (`steam`);

--
-- Indexes for table `list`
--
ALTER TABLE `list`
  ADD UNIQUE KEY `thing` (`thing`);

--
-- Indexes for table `locations`
--
ALTER TABLE `locations`
  ADD PRIMARY KEY (`name`),
  ADD UNIQUE KEY `name` (`name`);

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
-- Indexes for table `memEntities`
--
ALTER TABLE `memEntities`
  ADD UNIQUE KEY `entityID` (`entityID`);

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
-- Indexes for table `miscQueue`
--
ALTER TABLE `miscQueue`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `otherEntities`
--
ALTER TABLE `otherEntities`
  ADD PRIMARY KEY (`entity`);

--
-- Indexes for table `performance`
--
ALTER TABLE `performance`
  ADD PRIMARY KEY (`serverDate`),
  ADD KEY `serverDate` (`serverDate`);

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
  ADD PRIMARY KEY (`steam`),
  ADD UNIQUE KEY `steam` (`steam`);

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
-- Indexes for table `prefabCopies`
--
ALTER TABLE `prefabCopies`
  ADD PRIMARY KEY (`owner`,`name`);

--
-- Indexes for table `proxies`
--
ALTER TABLE `proxies`
  ADD PRIMARY KEY (`scanString`);

--
-- Indexes for table `resetZones`
--
ALTER TABLE `resetZones`
  ADD PRIMARY KEY (`region`),
  ADD UNIQUE KEY `region` (`region`);

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
-- Indexes for table `staff`
--
ALTER TABLE `staff`
  ADD PRIMARY KEY (`steam`);

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
-- Indexes for table `waypoints`
--
ALTER TABLE `waypoints`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `whitelist`
--
ALTER TABLE `whitelist`
  ADD PRIMARY KEY (`steam`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `alerts`
--
ALTER TABLE `alerts`
  MODIFY `alertID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `altertables`
--
ALTER TABLE `altertables`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=113;
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
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;
--
-- AUTO_INCREMENT for table `customCommands`
--
ALTER TABLE `customCommands`
  MODIFY `commandID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `customCommands_Detail`
--
ALTER TABLE `customCommands_Detail`
  MODIFY `detailID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `events`
--
ALTER TABLE `events`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=779;
--
-- AUTO_INCREMENT for table `gimmeQueue`
--
ALTER TABLE `gimmeQueue`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `helpCommands`
--
ALTER TABLE `helpCommands`
  MODIFY `commandID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `helpTopics`
--
ALTER TABLE `helpTopics`
  MODIFY `topicID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `hotspots`
--
ALTER TABLE `hotspots`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `inventoryChanges`
--
ALTER TABLE `inventoryChanges`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=100122;
--
-- AUTO_INCREMENT for table `inventoryTracker`
--
ALTER TABLE `inventoryTracker`
  MODIFY `inventoryTrackerID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45599;
--
-- AUTO_INCREMENT for table `ircQueue`
--
ALTER TABLE `ircQueue`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;
--
-- AUTO_INCREMENT for table `mail`
--
ALTER TABLE `mail`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;
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
-- AUTO_INCREMENT for table `miscQueue`
--
ALTER TABLE `miscQueue`
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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `tracker`
--
ALTER TABLE `tracker`
  MODIFY `trackerID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=266682;
--
-- AUTO_INCREMENT for table `waypoints`
--
ALTER TABLE `waypoints`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
