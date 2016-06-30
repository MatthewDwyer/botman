CREATE DATABASE  IF NOT EXISTS `bots`;
USE `bots`;

--
-- Table structure for table `IPBlacklist`
--

CREATE TABLE `IPBlacklist` (
  `StartIP` bigint(15) NOT NULL,
  `EndIP` bigint(15) NOT NULL,
  `Country` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`StartIP`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `bans`
--

CREATE TABLE `bans` (
  `steam` varchar(17) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `bannedTo` varchar(22) NOT NULL,
  `permanent` tinyint(1) NOT NULL DEFAULT '0',
  `playTime` int(11) NOT NULL DEFAULT '0',
  `score` int(11) NOT NULL DEFAULT '0',
  `playerKills` int(11) NOT NULL DEFAULT '0',
  `zombies` int(11) NOT NULL DEFAULT '0',
  `country` varchar(2) DEFAULT NULL,
  `belt` varchar(500) DEFAULT NULL,
  `pack` varchar(1000) DEFAULT NULL,
  `equipment` varchar(500) DEFAULT NULL,
  `dateAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `botID` varchar(7) DEFAULT NULL,
  `admin` varchar(17) DEFAULT NULL,
  PRIMARY KEY (`steam`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `donors`
--

CREATE TABLE `donors` (
  `server` varchar(20) NOT NULL,
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `name` varchar(25) NOT NULL,
  `donor` tinyint(1) NOT NULL DEFAULT '0',
  `donorLevel` int(11) NOT NULL DEFAULT '0',
  `donorExpiry` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`server`,`steam`),
  UNIQUE KEY `steam` (`steam`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `events`
--

CREATE TABLE `events` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `serverTime` varchar(19) NOT NULL,
  `type` varchar(15) NOT NULL,
  `event` varchar(255) NOT NULL,
  `steam` varchar(17) NOT NULL,
  `server` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `server` (`server`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=38038 DEFAULT CHARSET=utf8;

--
-- Table structure for table `guides`
--

CREATE TABLE `guides` (
  `guideID` int(11) NOT NULL AUTO_INCREMENT,
  `Title` varchar(100) NOT NULL,
  `Summary` varchar(255) NOT NULL,
  `guide` text NOT NULL,
  PRIMARY KEY (`guideID`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

--
-- Table structure for table `helpCommands`
--

CREATE TABLE `helpCommands` (
  `commandID` int(11) NOT NULL AUTO_INCREMENT,
  `command` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `notes` text NOT NULL,
  `keywords` varchar(150) NOT NULL,
  `lastUpdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`commandID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

--
-- Table structure for table `helpTopicCommands`
--

CREATE TABLE `helpTopicCommands` (
  `topicID` int(11) NOT NULL,
  `commandID` int(11) NOT NULL,
  PRIMARY KEY (`topicID`,`commandID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `helpTopics`
--

CREATE TABLE `helpTopics` (
  `topicID` int(11) NOT NULL AUTO_INCREMENT,
  `topic` varchar(20) NOT NULL,
  `description` varchar(150) NOT NULL,
  PRIMARY KEY (`topicID`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;

--
-- Table structure for table `messageQueue`
--

CREATE TABLE `messageQueue` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `sender` bigint(17) NOT NULL DEFAULT '0',
  `recipient` bigint(20) NOT NULL DEFAULT '0',
  `message` varchar(1000) NOT NULL,
  `fromServer` int(11) NOT NULL,
  `toServer` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `players`
--

CREATE TABLE `players` (
  `server` varchar(50) NOT NULL,
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `name` varchar(25) NOT NULL,
  `level` int(11) NOT NULL DEFAULT '1',
  `zombies` int(11) NOT NULL DEFAULT '0',
  `score` int(11) NOT NULL DEFAULT '0',
  `playerKills` int(11) NOT NULL DEFAULT '0',
  `deaths` int(11) NOT NULL DEFAULT '0',
  `timeOnServer` int(11) NOT NULL DEFAULT '0',
  `ip` varchar(15) DEFAULT NULL,
  `online` tinyint(1) NOT NULL DEFAULT '0',
  `country` varchar(2) DEFAULT NULL,
  `playtime` int(11) DEFAULT '0',
  `ping` int(11) NOT NULL DEFAULT '0',
  `botID` int(11) DEFAULT '0',
  `homeX` int(11) DEFAULT '0',
  `homeY` int(11) DEFAULT '0',
  `homeZ` int(11) DEFAULT '0',
  `home2X` int(11) DEFAULT '0',
  `home2Y` int(11) DEFAULT '0',
  `home2Z` int(11) DEFAULT '0',
  `exitX` int(11) DEFAULT '0',
  `exitY` int(11) DEFAULT '0',
  `exitZ` int(11) DEFAULT '0',
  `exit2X` int(11) DEFAULT '0',
  `exit2Y` int(11) DEFAULT '0',
  `exit2Z` int(11) DEFAULT '0',
  `protect` tinyint(1) DEFAULT '0',
  `protect2` tinyint(1) DEFAULT '0',
  `protectSize` int(11) DEFAULT '32',
  `protect2Size` int(11) DEFAULT '32'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `proxies`
--

CREATE TABLE `proxies` (
  `scanString` varchar(100) NOT NULL,
  `action` varchar(20) NOT NULL DEFAULT 'nothing',
  `hits` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`scanString`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `servers`
--

CREATE TABLE `servers` (
  `ServerPort` int(11) NOT NULL DEFAULT '0',
  `IP` varchar(15) DEFAULT NULL,
  `botName` varchar(20) NOT NULL DEFAULT '"Botman"',
  `serverName` varchar(50) NOT NULL,
  `playersOnline` int(11) NOT NULL DEFAULT '0',
  `tick` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `serverGroup` varchar(20) DEFAULT NULL,
  `botID` int(11) DEFAULT '0',
  PRIMARY KEY (`serverName`),
  UNIQUE KEY `serverName` (`serverName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
