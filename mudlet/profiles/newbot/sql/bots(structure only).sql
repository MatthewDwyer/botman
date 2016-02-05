-- phpMyAdmin SQL Dump
-- version 4.2.12deb2+deb8u1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Feb 05, 2016 at 09:54 PM
-- Server version: 10.0.22-MariaDB-0+deb8u1
-- PHP Version: 5.6.14-0+deb8u1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `bots`
--

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
-- Table structure for table `bans`
--

CREATE TABLE `bans` (
  `steam` varchar(17) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `bannedTo` varchar(22) NOT NULL,
  `permanent` tinyint(1) NOT NULL DEFAULT '0',
  `server` varchar(20) NOT NULL,
  `playTime` int(11) NOT NULL DEFAULT '0',
  `score` int(11) NOT NULL DEFAULT '0',
  `playerKills` int(11) NOT NULL DEFAULT '0',
  `zombies` int(11) NOT NULL DEFAULT '0',
  `country` varchar(2) DEFAULT NULL,
  `belt` varchar(500) DEFAULT NULL,
  `pack` varchar(600) DEFAULT NULL,
  `equipment` varchar(500) DEFAULT NULL,
  `expiry` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `guides`
--

CREATE TABLE `guides` (
`guideID` int(11) NOT NULL,
  `Title` varchar(100) NOT NULL,
  `Summary` varchar(255) NOT NULL,
  `guide` text NOT NULL
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
  `lastUpdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
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
  `description` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `IPBlacklist`
--

CREATE TABLE `IPBlacklist` (
  `StartIP` bigint(15) NOT NULL,
  `EndIP` bigint(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `messageQueue`
--

CREATE TABLE `messageQueue` (
`id` bigint(20) NOT NULL,
  `sender` bigint(17) NOT NULL DEFAULT '0',
  `recipient` bigint(20) NOT NULL DEFAULT '0',
  `message` varchar(1000) NOT NULL,
  `fromServer` int(11) NOT NULL,
  `toServer` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `players`
--

CREATE TABLE `players` (
  `server` varchar(20) NOT NULL,
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `name` varchar(25) NOT NULL,
  `playerid` int(11) NOT NULL,
  `level` int(11) NOT NULL DEFAULT '1',
  `cash` int(11) NOT NULL DEFAULT '0',
  `pvpBounty` int(11) NOT NULL DEFAULT '0',
  `zombies` int(11) NOT NULL DEFAULT '0',
  `score` int(11) NOT NULL DEFAULT '0',
  `playerKills` int(11) NOT NULL DEFAULT '0',
  `deaths` int(11) NOT NULL DEFAULT '0',
  `timeOnServer` int(11) NOT NULL DEFAULT '0',
  `ip` varchar(15) DEFAULT NULL,
  `donor` tinyint(1) NOT NULL DEFAULT '0',
  `online` tinyint(1) NOT NULL DEFAULT '0',
  `countries` varchar(50) NOT NULL,
  `donorLevel` int(11) NOT NULL DEFAULT '0',
  `donorExpiry` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `group` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
-- Table structure for table `servers`
--

CREATE TABLE `servers` (
  `ServerPort` int(11) NOT NULL DEFAULT '0',
  `IP` varchar(15) DEFAULT NULL,
  `botName` varchar(20) NOT NULL DEFAULT '"Botman"',
  `serverName` varchar(50) NOT NULL,
  `playersOnline` int(11) NOT NULL DEFAULT '0',
`id` int(11) NOT NULL,
  `tick` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
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

--
-- Indexes for dumped tables
--

--
-- Indexes for table `badItems`
--
ALTER TABLE `badItems`
 ADD PRIMARY KEY (`item`);

--
-- Indexes for table `bans`
--
ALTER TABLE `bans`
 ADD PRIMARY KEY (`steam`,`server`);

--
-- Indexes for table `guides`
--
ALTER TABLE `guides`
 ADD PRIMARY KEY (`guideID`);

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
-- Indexes for table `IPBlacklist`
--
ALTER TABLE `IPBlacklist`
 ADD PRIMARY KEY (`StartIP`);

--
-- Indexes for table `messageQueue`
--
ALTER TABLE `messageQueue`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `players`
--
ALTER TABLE `players`
 ADD PRIMARY KEY (`server`,`steam`), ADD UNIQUE KEY `steam` (`steam`);

--
-- Indexes for table `proxies`
--
ALTER TABLE `proxies`
 ADD PRIMARY KEY (`scanString`);

--
-- Indexes for table `servers`
--
ALTER TABLE `servers`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `serverName` (`serverName`);

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
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `guides`
--
ALTER TABLE `guides`
MODIFY `guideID` int(11) NOT NULL AUTO_INCREMENT;
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
-- AUTO_INCREMENT for table `messageQueue`
--
ALTER TABLE `messageQueue`
MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `servers`
--
ALTER TABLE `servers`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
