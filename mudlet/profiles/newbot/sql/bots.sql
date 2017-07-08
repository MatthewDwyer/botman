-- phpMyAdmin SQL Dump
-- version 4.6.6
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jul 08, 2017 at 09:22 AM
-- Server version: 10.1.24-MariaDB
-- PHP Version: 7.0.20

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `bots`
--

-- --------------------------------------------------------

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
  `GBLBan` tinyint(1) NOT NULL DEFAULT '0',
  `GBLBanExpiry` date NOT NULL,
  `GBLBanReason` varchar(255) NOT NULL DEFAULT '',
  `GBLBanVetted` tinyint(1) NOT NULL DEFAULT '0',
  `GBLBanActive` tinyint(1) NOT NULL DEFAULT '0',
  `id` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `donors`
--

CREATE TABLE `donors` (
  `botID` int(11) NOT NULL,
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `donor` tinyint(1) NOT NULL DEFAULT '0',
  `donorLevel` int(11) NOT NULL DEFAULT '0',
  `donorExpiry` int(11) DEFAULT NULL,
  `serverGroup` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `events`
--

CREATE TABLE `events` (
  `id` bigint(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `serverTime` varchar(19) NOT NULL,
  `type` varchar(15) NOT NULL,
  `event` varchar(255) NOT NULL,
  `steam` varchar(17) NOT NULL,
  `server` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
  `EndIP` bigint(15) NOT NULL,
  `Country` varchar(2) DEFAULT NULL,
  `DateAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `botID` int(11) NOT NULL DEFAULT '0',
  `steam` bigint(17) NOT NULL DEFAULT '0',
  `playerName` varchar(25) NOT NULL DEFAULT '',
  `IP` varchar(15) NOT NULL DEFAULT ''
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
  `toServer` int(11) NOT NULL,
  `messageTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

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
  `botID` int(11) NOT NULL DEFAULT '0',
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
  `protect2Size` int(11) DEFAULT '32',
  `ircAlias` varchar(15) NOT NULL,
  `ircAuthenticated` tinyint(1) NOT NULL DEFAULT '0',
  `steamOwner` bigint(17) NOT NULL DEFAULT '0'
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
  `tick` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `serverGroup` varchar(20) DEFAULT NULL,
  `botID` int(11) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bans`
--
ALTER TABLE `bans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `donors`
--
ALTER TABLE `donors`
  ADD PRIMARY KEY (`botID`,`steam`),
  ADD UNIQUE KEY `steam` (`steam`);

--
-- Indexes for table `events`
--
ALTER TABLE `events`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD KEY `server` (`server`,`id`);

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
  ADD PRIMARY KEY (`steam`,`botID`);

--
-- Indexes for table `proxies`
--
ALTER TABLE `proxies`
  ADD PRIMARY KEY (`scanString`);

--
-- Indexes for table `servers`
--
ALTER TABLE `servers`
  ADD PRIMARY KEY (`serverName`),
  ADD UNIQUE KEY `serverName` (`serverName`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bans`
--
ALTER TABLE `bans`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `events`
--
ALTER TABLE `events`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=520;
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
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
