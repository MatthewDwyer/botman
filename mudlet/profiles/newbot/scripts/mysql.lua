--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


-- useful reference: luapower.com/mysql

mysql = require "luasql.mysql"

function initBotsData()
	local IP, country

	-- insert players in bots db
	for k, v in pairs(players) do
		if v.IP == nil then 
			IP = "" 
		else
			IP = v.IP
		end

		if v.country == nil then 
			country = "" 
		else
			country = v.country
		end
	end
end


function cleanupBotsData()
	if db2Connected then
		connBots:execute("UPDATE players set online = 0 WHERE server = '" .. escape(server.ServerName) .. "'")
	end
end


function registerBot()
	-- the server table in bots db should have 1 unique record for each server.  We achieve this by picking a random number and testing the server table
	-- to see if it is present.  We keep trying random numbers till we find an unused one then we insert a record into the servers table for this server.
	-- we record the new botID locally for later use.

	local id

	if not db2Connected then
		return
	end

	if tonumber(server.botID) == 0 then
		-- delete any server records with a botID of zero
		connBots:execute("DELETE FROM servers WHERE botID = 0")

		id = rand(9999)
		cursor,errorString = connBots:execute("select botID from servers where botID = " .. id)

		while tonumber(cursor:numrows()) > 0 do
			id = rand(9999)
			cursor,errorString = connBots:execute("select botID from servers where botID = " .. id)
		end

		connBots:execute("INSERT INTO servers (ServerPort, IP, botName, serverName, playersOnline, tick, botID) VALUES (" .. server.ServerPort .. ",'" .. server.IP .. "','" .. escape(server.botName) .. "','" .. escape(server.ServerName) .. "'," .. playersOnline .. ", now()," .. id .. ")")
		server.botID = id
		conn:execute("UPDATE server SET botID = " .. id)
	end

	-- Try to insert the current players into the players table on bots db
	for k, v in pairs(igplayers) do
		insertBotsPlayer(k)
	end
end


function insertBotsPlayer(steam)
	if not db2Connected then
		return
	end

	connBots:execute("UPDATE players set online = 0 WHERE steam = " .. steam)

	if tonumber(server.botID) > 0 then
		-- insert player in bots db
		connBots:execute("INSERT INTO players (botID, server, steam, ip, name, online, level, zombies, score, playerKills, deaths, timeOnServer, playtime, country, ping) VALUES (" .. server.botID .. ",'" .. escape(server.ServerName) .. "'," .. steam .. ",'" .. players[steam].IP .. "','" .. escape(players[steam].name) .. "', 1," .. players[steam].level .. "," .. players[steam].zombies .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].deaths .. "," .. players[steam].timeOnServer .. "," .. igplayers[steam].sessionPlaytime .. ",'" .. players[steam].country .. "'," .. players[steam].ping .. ")")
	end
end


function updateBotsPlayer(steam)
	if not db2Connected then
		return
	end

	connBots:execute("UPDATE players set online = 0 WHERE steam = " .. steam)

	if tonumber(server.botID) > 0 then
		-- update player in bots db
		connBots:execute("UPDATE players SET ip = '" .. players[steam].IP .. "', name = '" .. escape(players[steam].name) .. "', online = 1, level = " .. players[steam].level .. ", zombies = " .. players[steam].zombies .. ", score = " .. players[steam].score .. ", playerKills = " .. players[steam].playerKills .. ", deaths = " .. players[steam].deaths .. ", timeOnServer  = " .. players[steam].timeOnServer .. ", playtime = " .. igplayers[steam].sessionPlaytime .. ", country = '" .. players[steam].country .. "', ping = " .. players[steam].ping .. " WHERE steam = " .. steam .. " AND botID = " .. server.botID)
	end
end


function updateBotsServerTable()
	if not db2Connected then
		return
	end

	connBots:execute("UPDATE servers SET ServerPort = " .. server.ServerPort .. ", IP = '" .. server.IP .. "', botName = '" .. escape(server.botName) .. "', playersOnline = " .. playersOnline .. ", tick = now() WHERE botID = '" .. escape(server.botID))
	connBots:execute("UPDATE players set online = 0 WHERE server = '" .. escape(server.ServerName) .. "'")

	-- updated players on bots db
	for k, v in pairs(igplayers) do
		-- update player in bots db
		connBots:execute("UPDATE players SET ip = '" .. players[k].IP .. "', name = '" .. escape(v.name) .. "', online = 1, level = " .. v.level .. ", zombies = " .. v.zombies .. ", score = " .. v.score .. ", playerKills = " .. v.playerKills .. ", deaths = " .. v.deaths .. ", timeOnServer  = " .. players[k].timeOnServer .. ", playtime = " .. v.sessionPlaytime .. ", country = '" .. players[k].country .. "', ping = " .. v.ping .. " WHERE steam = " .. k .. " AND botID = " .. server.botID)
	end
end


function dumpTable(table)
	local cursor, errorString, row, fields, values, k, v, file

	cursor,errorString = conn:execute("SELECT * FROM " .. table)
	row = cursor:fetch({}, "a")

	file = io.open(homedir .. "/" .. table .. "_" .. os.date("%Y%m%d_%H%M%S") .. ".csv", "a")

	if row then
		fields = ""

		for k,v in pairs(row) do
			if fields ~= "" then fields = fields .. "," end
			fields = fields .. k
		end

		file:write(fields .. "\n")
	end

	while row do
		values = ""

		for k,v in pairs(row) do
			if values ~= "" then values = values .. "," end
			values = values .. v
		end

		file:write(values .. "\n")
		row = cursor:fetch(row, "a")	
	end

	file:close()
end


function isDBBotsConnected()
	cursor,errorString = connBots:execute("select RAND() as rnum")
	row = cursor:fetch({}, "a")

	if not row then
		return false
	else
		return true
	end
end


function isDBConnected()
	cursor,errorString = conn:execute("select RAND() as rnum")
	row = cursor:fetch({}, "a")

	if not row then
		return false
	else
		return true
	end
end


function rand(high, low, real)
	-- generate a random number using MySQL
	if low == nil then low = 1 end
	if real == nil then
		cursor,errorString = conn:execute("select floor(RAND()*(" .. high .. "-" .. low .. ")+" .. low .. ") as rnum")
	else
		cursor,errorString = conn:execute("select RAND()*(" .. high .. "-" .. low .. ")+" .. low .. " as rnum")
	end

	row = cursor:fetch({}, "a")
	return tonumber(row.rnum)
end


function nextID(table, idfield)
	local cursor, row, errorString

	cursor,errorString = conn:execute("SELECT MAX(" .. idfield .. ") as lastid FROM " .. table)
	row = cursor:fetch({}, "a")

	if row.id ~= nil then
		nextid = tonumber(row.lastid) + 1
	else
		nextid = 1
	end

	cursor:close()
	return nextid
end


function dbBaseDefend(steam, base)
-- experimental
	local cursor, errorString,row, dist

	dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, players[base].homeX, players[base].homeZ)

	if dist < server.baseSize then
		cursor,errorString = conn:execute("SELECT x, y, z FROM tracker WHERE steam = " .. steam .." AND (abs(x - " .. players[base].homeX .. ") > " .. server.baseSize .. " AND abs(z - " .. players[base].homeZ .. ") > " .. server.baseSize .. ")  AND (abs(x - " .. players[base].homeX .. ") < " .. server.baseSize + 40 .. " AND abs(z - " .. players[base].homeZ .. ") < " .. server.baseSize + 40 .. ") ORDER BY trackerid DESC Limit 0, 50")
		row = cursor:fetch({}, "a")
		while row do
			cmd = ("tele " .. steam .. " " .. row.x .. " " .. row.y .. " " .. row.z)
			teleport(cmd)

			if true then
				return
			end

			row = cursor:fetch(row, "a")	
		end
	end
end


function escape(string)
	-- always escape your strings!

	if string == nil then
		return ""
	else
		return conn:escape(string)
	end
end


function dbTrue(value)
	-- translate db true false to Lua true false
	if value == "0" then
		return false
	else
		return true
	end
end


function dbYN(value)
	-- translate db true false to Lua true false
	if value == "0" then
		return "No"
	else
		return "Yes"
	end
end


function dbBool(value)
	-- translate Lua true false to db 1 or 0
	if value == false then
		return 0
	else
		return 1
	end
end


function initDB()
	alterTables()

	conn:execute("DELETE FROM ircQueue")
	conn:execute("DELETE FROM memTracker")
	conn:execute("DELETE FROM messageQueue")
	conn:execute("DELETE FROM commandQueue")
	conn:execute("DELETE FROM gimmeQueue")
	conn:execute("DELETE FROM searchResults")
end


function closeDB()
	conn:close()
	connBots:close()
	env:close()

	dbConnected = false
end


function importBlacklist()
	local cursor, cursor2, errorString, row

	if not db2Connected then
		return
	end

	cursor,errorString = connBots:execute("SELECT * FROM IPBlacklist")
	row = cursor:fetch({}, "a")
	while row do
		cursor2,errorString = conn:execute("INSERT INTO IPBlacklist (StartIP, EndIP) values (" .. row.StartIP .. "," .. row.EndIP .. ")")
		row = cursor:fetch(row, "a")	
	end

	cursor:close()
	cursor2:close()
end


function importBadItems()
	local cursor, cursor2, errorString, row

	if not db2Connected then
		return
	end

	conn:execute("DELETE FROM badItems")

	cursor,errorString = connBots:execute("SELECT * FROM badItems")
	row = cursor:fetch({}, "a")
	while row do
		cursor2,errorString = conn:execute("INSERT INTO badItems (item, action) values ('" .. escape(row.item) .. "','" .. row.action .. "')")
		row = cursor:fetch(row, "a")	
	end

	cursor:close()
	cursor2:close()
end


function alterTables()
-- These are here to make it easier to update other bots while the bot is in development.
	conn:execute("ALTER TABLE `hotspots` CHANGE `size` `size` INT(11) NOT NULL DEFAULT '2'")
	conn:execute("ALTER TABLE `hotspots` ADD `idx` INT NOT NULL DEFAULT '0'")
	conn:execute("ALTER TABLE `keystones` ADD `removed` int(11) NOT NULL DEFAULT '1'")
	conn:execute("DROP TABLE `languages`")
	conn:execute("ALTER TABLE `locations` ADD `resetZone` tinyint(1) NOT NULL DEFAULT '0'")
	conn:execute("ALTER TABLE `players` DROP `teleCooldown`")
	conn:execute("ALTER TABLE `server` ADD `gameType` VARCHAR(3) NOT NULL DEFAULT 'pve'")
	conn:execute("ALTER TABLE `players` ADD `donorLevel` INT NOT NULL DEFAULT '0' , ADD `donorExpiry` TIMESTAMP NOT NULL")
	conn:execute("ALTER TABLE `locations` ADD `other` VARCHAR(10) NULL DEFAULT NULL")
	conn:execute("ALTER TABLE `server` ADD `hideCommands` BOOLEAN NOT NULL DEFAULT TRUE")
	conn:execute("ALTER TABLE `locations` ADD `killZombies` BOOLEAN NOT NULL DEFAULT FALSE")
	conn:execute("ALTER TABLE `players` ADD `autoFriend` VARCHAR(2) NOT NULL COMMENT 'NA/AF/AD'")
	conn:execute("ALTER TABLE `server` ADD `botTick` INT NOT NULL DEFAULT '0'")
	conn:execute("ALTER TABLE `players` ADD `ircOtherNames` VARCHAR(50) NULL")
	conn:execute("ALTER TABLE `performance` ADD `heapMax` FLOAT NOT NULL AFTER `heap`")
	conn:execute("ALTER TABLE `proxies` DROP `id`")
	conn:execute("ALTER TABLE `players` ADD `steamOwner` BIGINT(17) NOT NULL")
	conn:execute("ALTER TABLE `server` ADD `serverGroup` VARCHAR(20) NULL DEFAULT NULL")
	conn:execute("ALTER TABLE `server` ADD `botID` INT NOT NULL DEFAULT '0'")
	conn:execute("ALTER TABLE `server` ADD `allowOverstacking` BOOLEAN NOT NULL DEFAULT FALSE")
	conn:execute("CREATE TABLE IF NOT EXISTS `list` (`thing` varchar(255) NOT NULL) ENGINE=MEMORY DEFAULT CHARSET=latin1 COMMENT='For sorting a list'")
	conn:execute("ALTER TABLE `list` ADD UNIQUE KEY `thing` (`thing`)")
	conn:execute("ALTER TABLE `server` ADD `announceTeleports` BOOLEAN NOT NULL")
	conn:execute("ALTER TABLE `server` ADD `blockCountries` VARCHAR(60) NOT NULL DEFAULT 'CN'")
	conn:execute("ALTER TABLE `server` ADD `northeastZone` VARCHAR(5) NOT NULL DEFAULT 'pve', ADD `northwestZone` VARCHAR(5) NOT NULL DEFAULT 'pve' , ADD `southeastZone` VARCHAR(5) NOT NULL DEFAULT 'pve' , ADD `southwestZone` VARCHAR(5) NOT NULL DEFAULT 'pve'")
	conn:execute("ALTER TABLE `server` ADD `allowPhysics` BOOLEAN NOT NULL DEFAULT TRUE")
	conn:execute("ALTER TABLE `server` ADD `playersCanFly` BOOLEAN NOT NULL DEFAULT FALSE")
	conn:execute("ALTER TABLE `server` ADD `accessLevelOverride` INT NOT NULL DEFAULT '99'")
	conn:execute("ALTER TABLE `server` ADD `disableBaseProtection` BOOLEAN NOT NULL DEFAULT FALSE")
	conn:execute("ALTER TABLE `players` ADD `bedX` INT NOT NULL DEFAULT '0' , ADD `bedY` INT NOT NULL DEFAULT '0' , ADD `bedZ` INT NOT NULL DEFAULT '0'")
	conn:execute("ALTER TABLE `server` ADD `packCooldown` INT NOT NULL DEFAULT '0'")
	conn:execute("ALTER TABLE `server` ADD `moneyName` VARCHAR(20) NOT NULL DEFAULT 'Zenny|Zennies'")
	conn:execute("ALTER TABLE `server` ADD `allowBank` BOOLEAN NOT NULL DEFAULT TRUE")
	conn:execute("ALTER TABLE `server` ADD `overstackThreshold` INT NOT NULL DEFAULT '1000'")
	conn:execute("ALTER TABLE `server` ADD `enableRegionPM` BOOLEAN NOT NULL DEFAULT TRUE")
	conn:execute("ALTER TABLE `players` ADD `showLocationMessages` BOOLEAN NOT NULL DEFAULT TRUE")
	conn:execute("ALTER TABLE `server` ADD `allowRapidRelogging` TINYINT NOT NULL DEFAULT '1'")
	conn:execute("ALTER TABLE `players` ADD `mute` TINYINT NOT NULL DEFAULT '0'")
	conn:execute("ALTER TABLE `server` ADD `allowLottery` TINYINT NOT NULL DEFAULT '1', ADD `lotteryMultiplier` INT NOT NULL DEFAULT '2', ADD `zombieKillReward` INT NOT NULL DEFAULT '3'")
	conn:execute("ALTER TABLE `players` ADD `xPosOld2` INT NOT NULL DEFAULT '0' , ADD `yPosOld2` INT NOT NULL DEFAULT '0' , ADD `zPosOld2` INT NOT NULL DEFAULT '0'")
	conn:execute("ALTER TABLE `server` ADD `ircTracker` VARCHAR(15) NOT NULL DEFAULT '#new_tracker'")
	conn:execute("CREATE TABLE IF NOT EXISTS `whitelist` (`steam` bigint(17) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	conn:execute("ALTER TABLE `server` ADD `allowTeleporting` BOOLEAN NOT NULL DEFAULT TRUE")
	conn:execute("ALTER TABLE `server` ADD `hardcore` BOOLEAN NOT NULL DEFAULT FALSE")
	conn:execute("ALTER TABLE `players` ADD `ISP` VARCHAR(25) NULL DEFAULT NULL")
	conn:execute("ALTER TABLE `server` ADD `swearJar` TINYINT(1) NOT NULL DEFAULT '0', ADD `swearCash` INT NOT NULL DEFAULT '0' ")	
	conn:execute("CREATE TABLE IF NOT EXISTS `badWords` (`badWord` varchar(15) NOT NULL,`cost` int(11) NOT NULL DEFAULT '10',`counter` int(11) NOT NULL DEFAULT '0') ENGINE=InnoDB DEFAULT CHARSET=latin1")	
	conn:execute("ALTER TABLE `players` ADD `ignorePlayer` TINYINT(1) NOT NULL DEFAULT '0'")	
	conn:execute("ALTER TABLE `server` ADD `idleKick` TINYINT(1) NOT NULL DEFAULT '0'")
end


function readBotTick()
	local cursor, errorString, row

	cursor,errorString = conn:execute("select botTick from server")
	row = cursor:fetch({}, "a")

	if row then
		return tonumber(row.botTick)
	end

	cursor:close()	
end


function writeBotTick()
	if botTick == nil then
		botTick = 0
	end

	botTick = tonumber(botTick) + 1
	conn:execute("update server set botTick = " .. botTick)

	if db2Connected then
		connBots:execute("UPDATE servers SET tick = now() WHERE botID = " .. server.botID)
	end
end


function checkBotTick()
	local tick

	tick = readBotTick()

	if tick ~= botTick then
		botDisabled = true
		dbug("Another bot has been detected.  This bot has been disabled.")
		irc_QueueMsg(server.ircMain, "Another bot has been detected.  This bot has been disabled.  Do not run multiples of the same bot!")
		disconnect()
	end
end                                                                                                      
