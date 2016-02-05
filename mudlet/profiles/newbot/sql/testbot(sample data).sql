-- phpMyAdmin SQL Dump
-- version 4.2.12deb2+deb8u1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Feb 05, 2016 at 10:22 PM
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

--
-- Dumping data for table `announcements`
--

INSERT INTO `announcements` (`id`, `message`, `startDate`, `endDate`) VALUES
(1, ' Tell the bot where your base is with /setbase. Enable teleporting to it with /enabletp and teleport with /base. Protect your base from raiders with /protect then simply walk out of your base and the bot will do the rest.', '0000-00-00', '2020-01-01'),
(2, ' Tell the bot who your friends are with /friend. Read /help friends. The bot will think they are raiding you otherwise.', '0000-00-00', '2020-01-01'),
(3, ' Donors get 2 base teleports and base protections, can be mayor of a village, explore 5km beyond the edge of the map and more cool stuff! =D', '0000-00-00', '2020-01-01'),
(4, ' We have a bot that you can command. Type /commands for the quick list or /help for more info.', '0000-00-00', '2020-01-01'),
(7, ' You can now place hotspots all over your base. They are private messages that you create which are triggered like mines. /help hotspots for info.', '0000-00-00', '2020-01-01');

--
-- Dumping data for table `badItems`
--

INSERT INTO `badItems` (`item`, `action`) VALUES
('apacheArtifactChest', 'timeout'),
('artcube', 'timeout'),
('bedrock', 'timeout'),
('cashRegister', 'timeout'),
('cobblestone', 'timeout'),
('concreteReinforced', 'timeout'),
('lootCrateShamway', 'timeout'),
('lootCrateShotgunMessiah', 'timeout'),
('lootCrateWorkingStiffs', 'timeout'),
('lootForest', 'timeout'),
('lootGarage', 'timeout'),
('lootHouse', 'timeout'),
('lootMP', 'timeout'),
('lootStreet', 'timeout'),
('lootYard', 'timeout'),
('metalReinforcedDoorWooden', 'timeout'),
('mountainManStorageChest ', 'timeout'),
('reinforcedCobblestone', 'timeout'),
('reinforcedMetalTrunk', 'timeout'),
('reinforcedMetalWoodTrunk', 'timeout'),
('reinforcedScrapIronWall', 'timeout'),
('reinforcedTrunkPineTip', 'timeout'),
('reinforcedWoodMetal', 'timeout'),
('sandstorm', 'timeout'),
('secureReinforcedDoorWooden', 'timeout'),
('smokestorm', 'timeout'),
('snowstorm1', 'timeout'),
('steeldoor1_v1', 'timeout'),
('steeldoor1_v2', 'timeout'),
('steeldoor1_v3', 'timeout'),
('steelWall', 'timeout'),
('supplyCrateShamway', 'timeout'),
('supplyCrateShotgunMessiah', 'timeout'),
('supplyCrateWorkingStiffs', 'timeout'),
('water', 'timeout'),
('waterMoving', 'timeout'),
('waterMovingBucket', 'timeout'),
('waterStaticBucket', 'timeout');

--
-- Dumping data for table `gimmePrizes`
--

INSERT INTO `gimmePrizes` (`name`, `category`, `prizeLimit`) VALUES
('44Magnum', 'weapon', 1),
('airConditioner', 'misc', 1),
('airFilter', 'misc', 1),
('aloeCream', 'health', 10),
('ammunitionNationBook', 'book', 1),
('antibiotics', 'health', 4),
('baconAndEggs', 'food', 10),
('bakedPotato', 'food', 10),
('ballCap', 'clothes', 1),
('bandana', 'clothes', 1),
('bandanaBlack', 'clothes', 1),
('bandanaBlue', 'clothes', 1),
('bandanaBrown', 'clothes', 1),
('bandanaGreen', 'clothes', 1),
('bandanaRed', 'clothes', 1),
('barbedFence', 'misc', 5),
('barrelSmokeTest', 'misc', 4),
('beer', 'food', 24),
('beerCooler', 'misc', 1),
('bin', 'misc', 1),
('bioFuel', 'misc', 10),
('birdnest', 'misc', 5),
('blackDenimPants', 'clothes', 1),
('bloodBag', 'health', 4),
('bloodDrawKit', 'health', 2),
('blueberryPie', 'food', 3),
('boneShiv', 'weapon', 1),
('bowl', 'misc', 1),
('brick', 'misc', 10),
('brownDenimPants', 'clothes', 1),
('bucket', 'tool', 1),
('cactus01', 'misc', 5),
('cactus02', 'misc', 5),
('cactus03', 'misc', 5),
('camoNet', 'misc', 10),
('canCatfood', 'food', 10),
('candle', 'misc', 6),
('canDogfood', 'food', 10),
('canMiso', 'food', 3),
('canPasta', 'food', 3),
('canPears', 'food', 3),
('canStock', 'food', 3),
('carBattery', 'misc', 1),
('Carpet1', 'misc', 5),
('chair01', 'misc', 3),
('chaulkboard', 'misc', 1),
('clothBoots', 'clothes', 1),
('clothGloves', 'clothes', 1),
('clothHat', 'clothes', 1),
('clothJacket', 'clothes', 1),
('clothPants', 'clothes', 1),
('coalOre', 'misc', 5),
('coffee', 'food', 15),
('coffeeBeans', 'food', 20),
('coldBeer', 'misc', 12),
('cookingGrill', 'misc', 1),
('corn', 'food', 1),
('cornBread', 'food', 20),
('cornMeal', 'food', 20),
('cornOnTheCob', 'food', 20),
('cornSeed', 'food', 20),
('corpseLoot01', 'misc', 1),
('cowboyHat', 'clothes', 1),
('denimJacket', 'clothes', 1),
('denimPants', 'clothes', 1),
('dirt', 'misc', 50),
('doNotUse', 'misc', 1),
('doorKnob', 'misc', 5),
('driftwood', 'misc', 10),
('drywall', 'misc', 3),
('egg', 'food', 5),
('eggboiled', 'food', 5),
('endTable', 'misc', 2),
('faucet02', 'misc', 3),
('faucetBrass02', 'misc', 3),
('femur', 'weapon', 20),
('fireaxe', 'weapon', 1),
('firstAidKit', 'health', 3),
('flashlight01', 'misc', 1),
('foodHoney', 'food', 4),
('foodYuccaFruit', 'food', 10),
('foodYuccaJuice', 'food', 5),
('footballHelmet', 'clothes', 1),
('fountain', 'misc', 1),
('gasCan', 'misc', 5),
('goldenRodTea', 'food', 15),
('grainAlcohol', 'food', 1),
('graniteSink', 'misc', 1),
('hammer', 'tool', 1),
('hive', 'misc', 1),
('hoe', 'tool', 1),
('huntingKnife', 'weapon', 1),
('ice', 'misc', 1),
('ironBoots', 'clothes', 1),
('ironChestArmor', 'clothes', 1),
('ironGloves', 'clothes', 1),
('ironHelmet', 'clothes', 1),
('ironLegArmor', 'clothes', 1),
('kevlarHelmet', 'clothes', 1),
('LCDScreen', 'misc', 2),
('leatherBoots', 'clothes', 1),
('leatherGloves', 'clothes', 1),
('leatherHat', 'clothes', 1),
('leatherJacket', 'clothes', 1),
('leatherPants', 'clothes', 1),
('macDyverBook', 'book', 1),
('mailbox', 'misc', 1),
('meatStew', 'food', 3),
('medicineCabinet', 'misc', 1),
('miningHelmet', 'clothes', 1),
('moldyBread', 'food', 3),
('munitionsBox', 'misc', 1),
('nailgun', 'misc', 1),
('nightstand', 'misc', 1),
('officeChair01', 'misc', 1),
('oilBarrel', 'misc', 1),
('oldChair', 'misc', 1),
('oven', 'misc', 1),
('painkillers', 'food', 5),
('painting01', 'misc', 1),
('painting02', 'misc', 1),
('pickaxe', 'tool', 1),
('pipeBomb', 'weapon', 3),
('pistol', 'weapon', 1),
('pistolBook', 'book', 1),
('plaidShirt', 'clothes', 1),
('plaidShirtBlack', 'clothes', 1),
('plaidShirtBlue', 'clothes', 1),
('plaidShirtBrown', 'clothes', 1),
('plaidShirtGreen', 'clothes', 1),
('plaidShirtRed', 'clothes', 1),
('plantFiberPants', 'clothes', 1),
('potato', 'food', 20),
('PumpShotgun', 'weapon', 1),
('radiator', 'misc', 1),
('redDenimPants', 'clothes', 1),
('rottingFlesh', 'food', 10),
('rug01', 'misc', 1),
('sandbags', 'misc', 5),
('santaHat', 'clothes', 1),
('sawedOffPumpShotgun', 'weapon', 1),
('scrapBoots', 'clothes', 1),
('scrapBrass', 'misc', 5),
('scrapChestArmor', 'clothes', 1),
('scrapGloves', 'clothes', 1),
('scrapHelmet', 'clothes', 1),
('scrapLegArmor', 'clothes', 1),
('shades', 'clothes', 1),
('shamSandwich', 'food', 20),
('shovel', 'tool', 1),
('signcamping', 'misc', 1),
('signnohazardouswaste', 'misc', 1),
('signslow', 'misc', 1),
('signstop', 'misc', 1),
('skullCap', 'clothes', 1),
('skullCapBlack', 'clothes', 1),
('skullCapBlue', 'clothes', 1),
('skullCapBrown', 'clothes', 1),
('skullCapGreen', 'clothes', 1),
('skullCapRed', 'clothes', 1),
('sledgehammer', 'tool', 1),
('sniperRifle', 'weapon', 1),
('suitcase', 'misc', 1),
('tankTopBlue', 'clothes', 1),
('tankTopGreen', 'clothes', 1),
('tankTopPurple', 'clothes', 1),
('tankTopRed', 'clothes', 1),
('tankTopWhite', 'clothes', 1),
('theEnforcerMagazine', 'book', 1),
('tire', 'misc', 3),
('toilet01', 'misc', 1),
('toilet02', 'misc', 1),
('toilet03', 'misc', 1),
('trash_can01', 'misc', 1),
('trophy', 'misc', 3),
('trophy2', 'misc', 3),
('trophy3', 'misc', 3),
('vegetableStew', 'food', 4),
('vitamins', 'food', 5),
('wallOven', 'misc', 1),
('weaponRepairKit', 'tool', 5),
('wornBoots', 'clothes', 1),
('wrench', 'tool', 1);

--
-- Dumping data for table `proxies`
--

INSERT INTO `proxies` (`scanString`, `action`, `hits`) VALUES
('BANK OF AMERICA ', 'ban', 0),
('KRYPT TECHNOLOGIES ', 'ban', 0),
('WIRELESS-ALARM.COM ', 'ban', 0),
('YPSOLUTIONS ', 'ban', 0);

--
-- Dumping data for table `restrictedItems`
--

INSERT INTO `restrictedItems` (`item`, `qty`, `accessLevel`, `action`) VALUES
('tnt', 5, 0, 'timeout');

--
-- Dumping data for table `shop`
--

INSERT INTO `shop` (`item`, `category`, `price`, `stock`, `idx`, `maxStock`, `variation`, `special`) VALUES
('10mmBullet', 'ammo', 24, 250, 1, 250, 0, 0),
('762mmBullet', 'ammo', 32, 250, 2, 250, 0, 0),
('9mmBullet', 'ammo', 16, 500, 3, 500, 0, 0),
('ammunitionNationBook', 'books', 800, 5, 1, 5, 0, 0),
('animalHide', 'resources', 80, 50, 1, 50, 0, 0),
('antibiotics', 'medic', 400, 20, 1, 20, 0, 0),
('augerBlade', 'auger', 1000, 5, 1, 5, 0, 0),
('augerParts', 'auger', 1000, 5, 2, 5, 0, 0),
('augerSchematic', 'books', 400, 0, 2, 0, 0, 0),
('bottledWater', 'food', 40, 9, 1, 10, 0, 0),
('canBeef', 'food', 50, 10, 2, 10, 0, 0),
('carBattery', 'misc', 500, 2, 1, 2, 0, 0),
('crossbow', 'weapons', 200, 25, 1, 25, 0, 0),
('crossbowBolt', 'ammo', 2, 500, 4, 500, 0, 0),
('fireaxe', 'tools', 300, 10, 1, 10, 0, 0),
('FirstAidBandage', 'medic', 50, 20, 2, 20, 0, 0),
('firstAidKit', 'medic', 100, 5, 3, 5, 0, 0),
('gasCan', 'resources', 400, 50, 2, 50, 0, 0),
('goldenRodTea', 'food', 80, 10, 3, 10, 0, 0),
('grainAlcohol', 'resources', 40, 50, 3, 50, 0, 0),
('huntingKnifeBook', 'books', 200, 5, 3, 5, 0, 0),
('leatherTanning', 'books', 800, 5, 4, 5, 0, 0),
('macDyverBook', 'books', 800, 10, 5, 10, 0, 0),
('meatStew', 'food', 140, 50, 5, 50, 0, 0),
('minibikeChassis', 'bike', 2000, 2, 1, 2, 0, 0),
('minibikeHandlebars', 'bike', 1000, 2, 2, 2, 0, 0),
('minibikeSeat', 'bike', 1000, 2, 3, 2, 0, 0),
('minibikeWheels', 'bike', 2000, 2, 4, 2, 0, 0),
('mp5', 'weapons', 1000, 5, 2, 5, 0, 0),
('nailgun', 'tools', 2500, 4, 2, 4, 0, 0),
('oil', 'resources', 40, 50, 4, 50, 0, 0),
('P2Ptoken', 'special', 100, 1, 1, 1, 0, 0),
('padlock', 'special', 200, 5, 2, 5, 0, 0),
('pickaxeIron', 'tools', 400, 5, 3, 5, 0, 0),
('pistol', 'weapons', 400, 10, 3, 10, 0, 0),
('pistolBook', 'books', 800, 5, 6, 5, 0, 0),
('potassiumNitratePowder', 'resources', 200, 50, 5, 50, 0, 0),
('repairKit', 'misc', 200, 50, 2, 50, 0, 0),
('scrapCable', 'bike', 100, 50, 5, 50, 0, 0),
('scrapIron', 'resources', 8, 500, 6, 500, 0, 0),
('setInConcrete', 'books', 1200, 5, 7, 5, 0, 0),
('shotgunShell', 'ammo', 16, 250, 5, 250, 0, 0),
('shovel', 'tools', 300, 10, 4, 10, 0, 0),
('smallEngine', 'misc', 2500, 2, 3, 2, 0, 0),
('woodPlank', 'resources', 4, 500, 7, 500, 0, 0);

--
-- Dumping data for table `shopCategories`
--

INSERT INTO `shopCategories` (`category`, `idx`, `code`) VALUES
('ammo', 1, 'am'),
('auger', 1, 'au'),
('bike', 1, 'mbp'),
('books', 1, 'bk'),
('food', 1, 'f'),
('medic', 1, 'm'),
('misc', 1, 'mis'),
('resources', 1, 'res'),
('special', 1, 'sp'),
('tools', 1, 'tls'),
('weapons', 1, 'wp');

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
