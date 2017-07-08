--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


-- useful reference: luapower.com/mysql
-- locals and cursor updated

mysql = require "luasql.mysql"
local debug = false
local statements = {}

function deleteTrackingData(keepDays)
	-- to prevent the database collecting too much data, becoming slow and potentially filling the root partition
	-- we periodically clear out old data.  The default is to keep the last 28 days.
	-- It will be necessary to optimise the tables occasionally to purge the deleted records, but we need to give this task time to complete.

	-- don't run if the password is empty till I fix it so it'll work then
	if botDBPass == "" then
		return
	end

	local cmd, deletionDate
	local DateYear = os.date('%Y', os.time())
	local DateMonth = os.date('%m', os.time())
	local DateDay = os.date('%d', os.time())
	local deletionDate = os.time({day = DateDay - keepDays, month = DateMonth, year = DateYear})

	cmd = "mysql -u " .. botDBUser .. " -p" .. botDBPass .. " -e 'DELETE FROM inventoryChanges WHERE timestamp < \"" .. os.date("%Y-%m-%d", deletionDate) .. "\";  DELETE FROM inventoryTracker WHERE timestamp < \"" .. os.date("%Y-%m-%d", deletionDate) .. "\";  DELETE FROM tracker WHERE timestamp < \"" .. os.date("%Y-%m-%d", deletionDate) .. "\"; UPDATE server set databaseMaintenanceFinished = 1;' " .. botDB
	os.execute(cmd)
end


function migratePlayers()
	local cursor, errorString

	cursor,errorString = connBots:execute("SHOW COLUMNS FROM players LIKE 'steamOwner'")
	rows = cursor:numrows()

	if (rows == 0) then
		connBots:execute("CREATE TABLE players2 LIKE players")
		connBots:execute("ALTER TABLE players2 DISABLE KEYS")
		connBots:execute("ALTER TABLE  players2 DROP PRIMARY KEY , ADD PRIMARY KEY (steam,botID)")
		connBots:execute("ALTER TABLE players2 ENABLE KEYS")
		connBots:execute("DROP TABLE players")
		connBots:execute("RENAME TABLE players2 TO players")
		connBots:execute("ALTER TABLE `players` ADD `steamOwner` BIGINT(17) NOT NULL DEFAULT '0'")
	end
end

function initBotsData()
	local IP, country

if debug then display("initBotsData start\n") end

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

if debug then display("initBotsData end\n") end
end


function cleanupBotsData()
if debug then display("cleanupBotsData start\n") end

	if botman.db2Connected then
		connBots:execute("UPDATE players set online = 0 WHERE server = '" .. escape(server.serverName) .. "'")
	end

if debug then display("cleanupBotsData end\n") end
end


function registerBot()
if debug then display("registerBot start\n") end

	-- the server table in bots db should have 1 unique record for each server.  We achieve this by picking a random number and testing the server table
	-- to see if it is present.  We keep trying random numbers till we find an unused one then we insert a record into the servers table for this server.
	-- we record the new botID locally for later use.

	local id, cursor, errorString, k, v

	isDBBotsConnected()

	if tonumber(server.botID) == 0 then
		-- delete any server records with a botID of zero
		connBots:execute("DELETE FROM servers WHERE botID = 0")

		id = math.random(1,9999)

		if(not id) then
			dbugFull("E", debugger.traceback(),debugger.getinfo(1,"nSl"), "math.random(1,9999) returned 'nil', unable to regsiter bot!!")
			return
		end

		cursor,errorString = connBots:execute("select botID from servers where botID = " .. id)

		while tonumber(cursor:numrows()) > 0 do
			id = math.random(1,9999)
			cursor,errorString = connBots:execute("select botID from servers where botID = " .. id)
		end

		connBots:execute("INSERT INTO servers (ServerPort, IP, botName, serverName, playersOnline, tick, botID, dbName, dbUser, dbPass) VALUES (" .. server.ServerPort .. ",'" .. server.IP .. "','" .. escape(server.botName) .. "','" .. escape(server.serverName) .. "'," .. botman.playersOnline .. ", now()," .. id .. ",'" .. escape(botDB) .. "','" .. escape(botDBUser) .. "','" .. escape(botDBPass) .. "')")
		server.botID = id
		conn:execute("UPDATE server SET botID = " .. id)
	else
		-- check that there is a server record for this bot in bots db
		cursor,errorString = connBots:execute("select * from servers where botID = " .. server.botID)
		rows = cursor:numrows()

		if rows == 0 then
			connBots:execute("INSERT INTO servers (ServerPort, IP, botName, serverName, playersOnline, tick, botID, dbName, dbUser, dbPass) VALUES (" .. server.ServerPort .. ",'" .. escape(server.IP) .. "','" .. escape(server.botName) .. "','" .. escape(server.serverName) .. "'," .. botman.playersOnline .. ", now()," .. server.botID .. ",'" .. escape(botDB) .. "','" .. escape(botDBUser) .. "','" .. escape(botDBPass) .. "')")
		else
			-- update it with current data
			connBots:execute("UPDATE servers SET serverName = '" .. escape(server.serverName) .. "', IP = '" .. escape(server.IP) .. "', ServerPort = " .. server.ServerPort .. ", botName = '" .. escape(server.botName) .. "', playersOnline = " .. botman.playersOnline .. ", tick = now(), dbName = '" .. escape(botDB) .. "', dbUser = '" .. escape(botDBUser) .. "', dbPass = '" .. escape(botDBPass) .. "' WHERE botID = " .. server.botID)
		end
	end

	-- Try to insert the current players into the players table on bots db
	for k, v in pairs(igplayers) do
		insertBotsPlayer(k)
	end

if debug then display("registerBot end\n") end
end


function insertBotsPlayer(steam)
	if not botman.db2Connected or not steam or not players[steam] then
		return
	end

	if tonumber(server.botID) > 0 then
		-- insert or update player in bots db
		if(debug) then
			if(not server.botID) then display("DEBUG: insertBotsPlayer - botID = nil") end
			if(not server.serverName) then display("DEBUG: insertBotsPlayer - server = nil") end
			if(not steam) then display("DEBUG: insertBotsPlayer - steam = nil") end
			if(not players[steam].IP) then display("DEBUG: insertBotsPlayer - ip = nil") end
			if(not players[steam].name) then display("DEBUG: insertBotsPlayer - name = nil") end
			if(not players[steam].level) then display("DEBUG: insertBotsPlayer - level = nil") end
			if(not players[steam].zombies) then display("DEBUG: insertBotsPlayer - zombies = nil") end
			if(not players[steam].score) then display("DEBUG: insertBotsPlayer - score = nil") end
			if(not players[steam].playerKills) then display("DEBUG: insertBotsPlayer - playerKills = nil") end
			if(not players[steam].deaths) then display("DEBUG: insertBotsPlayer - deaths = nil") end
			if(not players[steam].timeOnServer) then display("DEBUG: insertBotsPlayer - timeOnServer = nil") end
			if(not players[steam].sessionPlaytime) then display("DEBUG: insertBotsPlayer - Playtime = nil") end
			if(not players[steam].country) then display("DEBUG: insertBotsPlayer - country = nil") end
			if(not players[steam].ping) then display("DEBUG: insertBotsPlayer - ping = nil") end
		end

		connBots:execute("INSERT INTO players " .. 
		  "(botID, server, steam, ip, name, online, level, zombies, " ..
		  "score, playerKills, deaths, timeOnServer, playtime, " ..
		  "country, ping)" ..
	 	 " VALUES (" .. 
		  (server.botID or 0) .. ", " ..
		  "'" .. escape((server.serverName or "None")) .. "', " ..
                  (steam or 0) .. ", " ..
                  "'" .. (players[steam].IP or "127.0.0.1") .. "', " ..
		  "'" .. escape((players[steam].name or "none")) .. "', " ..
		  "1, " ..
		  (players[steam].level or 1) .. ", " ..
		  (players[steam].zombies or 0) .. ", " ..
		  (players[steam].score or 0) .. ", " ..
		  (players[steam].playerKills or 0).. ", " ..
		  (players[steam].deaths or 0) .. ", " ..
		  (players[steam].timeOnServer or 0) .. ", " ..
		  (igplayers[steam].sessionPlaytime or 0) .. ", " ..
		  "'" .. (players[steam].country or "N/A") .. "', " ..
		  (players[steam].ping or 0) .. ")" ..
		 " ON DUPLICATE KEY UPDATE " ..
		  "ip = '" .. (players[steam].IP or "127.0.0.1") .. "', " ..
		  " name = '" .. escape((players[steam].name or "none")) .. "', " ..
		  "online = 1, " ..
		  "level = " .. (players[steam].level or 1) .. ", " ..
		  "zombies = " .. (players[steam].zombies or 0) .. ", " ..
		  "score = " .. (players[steam].score or 0) .. ", " ..
		  "playerKills = " .. (players[steam].playerKills or 0) .. ", " ..
		  "deaths = " .. (players[steam].deaths or 0) .. ", " ..
		  "timeOnServer  = " .. (players[steam].timeOnServer or 0) .. ", " ..
		  "playtime = " .. (igplayers[steam].sessionPlaytime or 0) .. ", " ..
		  "country = '" .. (players[steam].country or "N/A") .. "', " ..
		  "ping = " .. (players[steam].ping or 0)
		)
	end
end


function updateBotsServerTable()
	local k, v

	if not botman.db2Connected or tonumber(server.botID) == 0 then
		return
	end

	connBots:execute("UPDATE servers SET ServerPort = " .. server.ServerPort .. ", IP = '" .. server.IP .. "', botName = '" .. escape(server.botName) .. "', playersOnline = " .. botman.playersOnline .. ", tick = now() WHERE botID = '" .. escape(server.botID))

	-- updated players on bots db
	for k, v in pairs(igplayers) do
		-- update player in bots db

		if(v.playerKills == nil) then v.playerKills = 0 end

		if(tonumber(k) < 1 or not players[k]) then
			if(debug) then
				dbugFull("D", "", debugger.getinfo(1,"nSl"), k .. " not found in players")
			end
		else

			connBots:execute("UPDATE players SET " ..
			"ip = '" .. (players[k].IP or "127.0.0.1") .. "', " ..
			"name = '" .. escape((v.name or "none")) .. "', " ..
			"online = 1, " ..
			"level = " .. (v.level or 1) .. ", " ..
			"zombies = " .. (v.zombies or 0) .. ", " ..
			"score = " .. (v.score or 0) .. ", " ..
			"playerKills = " .. (v.playerKills or 0) .. ", " ..
			"deaths = " .. (v.deaths or 0) .. ", " ..
			"timeOnServer  = " .. (players[k].timeOnServer or 0) .. ", " ..
			"playtime = " .. (v.sessionPlaytime or 0) .. ", " ..
			"country = '" .. (players[k].country or 0) .. "', " ..
			"ping = " .. (v.ping or 0) .. 
			" WHERE steam = " .. k .. " AND botID = " .. (server.botID or 0))
		end
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
	local cursor, errorString

	cursor,errorString = connBots:execute("select RAND() as rnum")

	if cursor then
		return true
	else
		-- this never executes if the db isn't connected
		return false
	end
end


function isDBConnected()
	local cursor, errorString

	cursor,errorString = conn:execute("select RAND() as rnum")

	if cursor then
		return true
	else
		-- this never executes if the db isn't connected
		return false
	end
end

--[[
function rand(high, low, real)
	local cursor, errorString
	local tmpHigh = tonumber(high)
	local res

	if(debug) then
		dbugFull("D", debugger.traceback(), debugger.getinfo(1,"nSl"))
	end

	-- generate a random number using MySQL
	if low == nil then low = 1 end

	if(not high or not tmpHigh) then
 		dbugFull("E", debugger.traceback(),debugger.getinfo(1,"nSl"), "invalid value for high: nil")
		return
	end

	if(type(high) ~= "number") then
		high=tmpHigh
	end

	if real == nil then
		res = math.floor(math.random(low,high))

		-- cursor,errorString = conn:execute("select floor(RAND()*(" .. high + 1 .. "-" .. low .. ")+" .. low .. ") as rnum")
	else
		res = math.random(low,high)

		-- cursor,errorString = conn:execute("select RAND()*(" .. high + 1 .. "-" .. low .. ")+" .. low .. " as rnum")
	end

	return res

	-- row = cursor:fetch({}, "a")
	-- return tonumber(row.rnum)
end
--]]

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
-- TODO: update with the new automatic trader-esk ejector
	local cursor, errorString,row, dist

	dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, players[base].homeX, players[base].homeZ)

	if dist < server.baseSize then
		cursor,errorString = conn:execute("SELECT x, y, z FROM tracker WHERE steam = " .. steam .." AND (abs(x - " .. players[base].homeX .. ") > " .. server.baseSize .. " AND abs(z - " .. players[base].homeZ .. ") > " .. server.baseSize .. ")  AND (abs(x - " .. players[base].homeX .. ") < " .. server.baseSize + 40 .. " AND abs(z - " .. players[base].homeZ .. ") < " .. server.baseSize + 40 .. ") ORDER BY trackerid DESC Limit 0, 50")
		row = cursor:fetch({}, "a")
		while row do
			cmd = ("tele " .. steam .. " " .. row.x .. " -1 " .. row.z)
			prepareTeleport(steam, cmd)
			teleport(cmd, true)

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
if debug then display("initDB start") end
	alterTables()

	conn:execute("TRUNCATE TABLE ircQueue")
	conn:execute("TRUNCATE TABLE memTracker")
	conn:execute("TRUNCATE TABLE messageQueue")
	conn:execute("TRUNCATE TABLE commandQueue")
	conn:execute("TRUNCATE TABLE gimmeQueue")
	conn:execute("TRUNCATE TABLE searchResults")

	conn:execute("TRUNCATE TABLE memRestrictedItems")
	conn:execute("INSERT INTO memRestrictedItems (SELECT * from restrictedItems)")

	getServerFields()
	getPlayerFields()
if debug then display("initDB end") end
end


function closeDB()
	conn:close()
	connBots:close()
	--env:close()

	botman.dbConnected = false
	botman.dbBotsConnected = false
end


function migrateWhitelist()
	local k, v

	for k,v in pairs(players) do
		if v.whitelisted then
			conn:execute("INSERT INTO Whitelist (steam) VALUES ('" .. k .. "')")
		end
	end
end


function importBlacklist()
	local cursor, cursor2, errorString, row

	if not botman.db2Connected then
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


function importBlacklistCSV()
	-- This will take several minutes and will lock up the bot until completed.  Let it finish.
	-- There is no command to run this function, you must run it manually via Mudlet.  One way is to add it to the test command in gmsg_custom.lua
	-- then run /test command
	local file, ln, split, ip1, ip2
	connBots("TRUNCATE IPBlacklist")

	file = io.open(homedir .. "/cn.txt", "r")
	for ln in file:lines() do
		if string.find(ln, "-") then
			ln = string.sub(ln, string.find(ln, ":") + 1)
			split = string.split(ln, "-")
			ip1 = IPToInt(string.trim(split[1]))
			ip2 = IPToInt(string.trim(split[2]))
			connBots:execute("INSERT INTO IPBlacklistClean (StartIP, EndIP, Country) VALUES (" .. ip1 .. "," .. ip2 .. ",'CN')")
		end
	end
end


function importBadItems()
	local cursor, cursor2, errorString, row

	if not botman.db2Connected then
		return
	end

	conn:execute("TRUNCATE TABLE badItems")

	cursor,errorString = connBots:execute("SELECT * FROM badItems")
	row = cursor:fetch({}, "a")
	while row do
		cursor2,errorString = conn:execute("INSERT INTO badItems (item, action) values ('" .. escape(row.item) .. "','" .. row.action .. "')")
		row = cursor:fetch(row, "a")
	end

	cursor:close()
	cursor2:close()
end


function migrateWaypoints()
	local cursor, errorString, row, k, v
	local fields, values, wp1ID, wp2ID

	-- fix the waypoints table
	cursor,errorString = conn:execute("select * from waypoints")
	row = cursor:fetch({}, "a")

	if not row then
		conn:execute("DROP TABLE `waypoints`")
		conn:execute("CREATE TABLE `waypoints` (`id` int(11) NOT NULL, `steam` varchar(17) NOT NULL,`name` varchar(30) NOT NULL,`x` int(11) NOT NULL,`y` int(11) NOT NULL,`z` int(11) NOT NULL,`linked` int(11) NOT NULL DEFAULT '0',`shared` tinyint(4) NOT NULL DEFAULT '0') ENGINE=InnoDB DEFAULT CHARSET=latin1")
		conn:execute("ALTER TABLE `waypoints` ADD PRIMARY KEY (`id`)")
		conn:execute("ALTER TABLE `waypoints` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT")

		-- now walk through the players table and migrate waypoints to the new waypoints table
		for k,v in pairs(players) do

			if tonumber(v.waypointY) > 0 then
				fields = "steam, name, x, y, z"
				values = k .. ",'wp1'," .. v.waypointX .. "," .. v.waypointY .. "," .. v.waypointZ

				if v.shareWaypoint then
					fields = fields .. ",shared"
					values = values .. ",1"
				end

				conn:execute("insert into waypoints (" .. fields .. ") values (" .. values .. ")")

				cursor,errorString = conn:execute("select LAST_INSERT_ID() as id")
				row = cursor:fetch({}, "a")

				wp1ID = row.id
			end

			if tonumber(v.waypoint2Y) > 0 then
				fields = "steam, name, x, y, z"
				values = k .. ",'wp2'," .. v.waypoint2X .. "," .. v.waypoint2Y .. "," .. v.waypoint2Z

				if v.shareWaypoint then
					fields = fields .. ",shared"
					values = values .. ",1"
				end

				conn:execute("insert into waypoints (" .. fields .. ") values (" .. values .. ")")

				cursor,errorString = conn:execute("select LAST_INSERT_ID() as id")
				row = cursor:fetch({}, "a")

				wp2ID = row.id
			end

			if v.waypointsLinked and tonumber(v.waypointY) > 0 and tonumber(v.waypoint2Y) > 0 then
				conn:execute("update waypoints set linked = " .. wp2ID .. " where id = " .. wp1ID)
				conn:execute("update waypoints set linked = " .. wp1ID .. " where id = " .. wp2ID)
			end

		end

		-- load the waypoints db table into the Lua table waypoints
		loadWaypoints()
	end
end


local function doSQL(sql, botsDB)
	local shortSQL = string.sub(sql, 1, 1000) -- truncate the sql to 1000 chars

	if not statements[shortSQL] then
		statements[shortSQL] = {}

		if botsDB then
			connBots:execute("INSERT INTO altertables (statement) VALUES ('" .. escape(shortSQL) .. "')")
			connBots:execute(sql)
		else
			conn:execute("INSERT INTO altertables (statement) VALUES ('" .. escape(shortSQL) .. "')")
			conn:execute(sql)
		end
	end
end


function alterTables()
	local benchStart = os.clock()
	local sql

if debug then display("alterTables start\n") end

-- These are here to make it easier to update other bots while the bot is in development.
-- If you think you are missing a table or field, try uncommenting these.

--	conn:execute("ALTER TABLE `hotspots` CHANGE `size` `size` INT(11) NOT NULL DEFAULT '2'")
--	conn:execute("ALTER TABLE `hotspots` ADD `idx` INT NOT NULL DEFAULT '0'")
	--conn:execute("ALTER TABLE `keystones` ADD `removed` int(11) NOT NULL DEFAULT '1'")
--	conn:execute("DROP TABLE `languages`")
	--conn:execute("ALTER TABLE `locations` ADD `resetZone` tinyint(1) NOT NULL DEFAULT '0'")
--	conn:execute("ALTER TABLE `server` ADD `gameType` VARCHAR(3) NOT NULL DEFAULT 'pve'")
--	conn:execute("ALTER TABLE `players` ADD `donorLevel` INT NOT NULL DEFAULT '0' , ADD `donorExpiry` TIMESTAMP NOT NULL")
--	conn:execute("ALTER TABLE `locations` ADD `other` VARCHAR(10) NULL DEFAULT NULL")
--	conn:execute("ALTER TABLE `server` ADD `hideCommands` BOOLEAN NOT NULL DEFAULT TRUE")
--	conn:execute("ALTER TABLE `locations` ADD `killZombies` BOOLEAN NOT NULL DEFAULT FALSE")
--	conn:execute("ALTER TABLE `players` ADD `autoFriend` VARCHAR(2) NOT NULL COMMENT 'NA/AF/AD'")
--	conn:execute("ALTER TABLE `server` ADD `botTick` INT NOT NULL DEFAULT '0'")
--	conn:execute("ALTER TABLE `players` ADD `ircOtherNames` VARCHAR(50) NULL")
--	conn:execute("ALTER TABLE `performance` ADD `heapMax` FLOAT NOT NULL AFTER `heap`")
--	conn:execute("ALTER TABLE `proxies` DROP `id`")
--	conn:execute("ALTER TABLE `players` ADD `steamOwner` BIGINT(17) NOT NULL")
--	conn:execute("ALTER TABLE `server` ADD `serverGroup` VARCHAR(20) NULL DEFAULT NULL")
--	conn:execute("ALTER TABLE `server` ADD `botID` INT NOT NULL DEFAULT '0'")
--	conn:execute("ALTER TABLE `server` ADD `allowOverstacking` BOOLEAN NOT NULL DEFAULT FALSE")
--	conn:execute("ALTER TABLE `list` ADD UNIQUE KEY `thing` (`thing`)")
--	conn:execute("ALTER TABLE `server` ADD `announceTeleports` BOOLEAN NOT NULL")
--	conn:execute("ALTER TABLE `server` ADD `blockCountries` VARCHAR(60) NOT NULL DEFAULT 'CN'")
--	conn:execute("ALTER TABLE `server` ADD `northeastZone` VARCHAR(5) NOT NULL DEFAULT 'pve', ADD `northwestZone` VARCHAR(5) NOT NULL DEFAULT 'pve' , ADD `southeastZone` VARCHAR(5) NOT NULL DEFAULT 'pve' , ADD `southwestZone` VARCHAR(5) NOT NULL DEFAULT 'pve'")
--	conn:execute("ALTER TABLE `server` ADD `allowPhysics` BOOLEAN NOT NULL DEFAULT TRUE")
--	conn:execute("ALTER TABLE `server` ADD `playersCanFly` BOOLEAN NOT NULL DEFAULT FALSE")
--	conn:execute("ALTER TABLE `server` ADD `accessLevelOverride` INT NOT NULL DEFAULT '99'")
--	conn:execute("ALTER TABLE `server` ADD `disableBaseProtection` BOOLEAN NOT NULL DEFAULT FALSE")
--	conn:execute("ALTER TABLE `players` ADD `bedX` INT NOT NULL DEFAULT '0' , ADD `bedY` INT NOT NULL DEFAULT '0' , ADD `bedZ` INT NOT NULL DEFAULT '0'")
--	conn:execute("ALTER TABLE `server` ADD `packCooldown` INT NOT NULL DEFAULT '0'")
--	conn:execute("ALTER TABLE `server` ADD `moneyName` VARCHAR(20) NOT NULL DEFAULT 'Zenny|Zennies'")
--	conn:execute("ALTER TABLE `server` ADD `allowBank` BOOLEAN NOT NULL DEFAULT TRUE")
--	conn:execute("ALTER TABLE `server` ADD `overstackThreshold` INT NOT NULL DEFAULT '1000'")
--	conn:execute("ALTER TABLE `server` ADD `enableRegionPM` BOOLEAN NOT NULL DEFAULT TRUE")
--	conn:execute("ALTER TABLE `players` ADD `showLocationMessages` BOOLEAN NOT NULL DEFAULT TRUE")
--	conn:execute("ALTER TABLE `server` ADD `allowRapidRelogging` TINYINT NOT NULL DEFAULT '1'")
--	conn:execute("ALTER TABLE `players` ADD `mute` TINYINT NOT NULL DEFAULT '0'")
--	conn:execute("ALTER TABLE `server` ADD `allowLottery` TINYINT NOT NULL DEFAULT '1', ADD `lotteryMultiplier` INT NOT NULL DEFAULT '2', ADD `zombieKillReward` INT NOT NULL DEFAULT '3'")
--	conn:execute("ALTER TABLE `players` ADD `xPosOld2` INT NOT NULL DEFAULT '0' , ADD `yPosOld2` INT NOT NULL DEFAULT '0' , ADD `zPosOld2` INT NOT NULL DEFAULT '0'")
--	conn:execute("ALTER TABLE `server` ADD `ircTracker` VARCHAR(15) NOT NULL DEFAULT '#new_tracker'")
--	conn:execute("ALTER TABLE `server` ADD `allowTeleporting` BOOLEAN NOT NULL DEFAULT TRUE")
--	conn:execute("ALTER TABLE `server` ADD `hardcore` BOOLEAN NOT NULL DEFAULT FALSE")
--	conn:execute("ALTER TABLE `players` ADD `ISP` VARCHAR(25) NULL DEFAULT NULL")
--	conn:execute("ALTER TABLE `server` ADD `swearJar` TINYINT(1) NOT NULL DEFAULT '0', ADD `swearCash` INT NOT NULL DEFAULT '0' ")
--	conn:execute("ALTER TABLE `players` ADD `ignorePlayer` TINYINT(1) NOT NULL DEFAULT '0'")
--	conn:execute("ALTER TABLE `server` ADD `idleKick` TINYINT(1) NOT NULL DEFAULT '0'")

	-- new tables
	conn:execute("CREATE TABLE `altertables` (`id` int(11) NOT NULL,`statement` varchar(1000) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	conn:execute("ALTER TABLE `altertables` ADD PRIMARY KEY (`id`)")
	conn:execute("ALTER TABLE `altertables` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT")

	-- the altertables table is used to store statements that we've already executed so we don't keep trying to modify the db with the same stuff
	-- every time the bot is started or refreshed.

	statements = {}
	cursor,errorString = conn:execute("select * from altertables")
	row = cursor:fetch({}, "a")
	while row do
		statements[row.statement] = {}
		row = cursor:fetch(row, "a")
	end

	doSQL("CREATE TABLE `badWords` (`badWord` varchar(15) NOT NULL,`cost` int(11) NOT NULL DEFAULT '10',`counter` int(11) NOT NULL DEFAULT '0') ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `list` (`thing` varchar(255) NOT NULL) ENGINE=MEMORY DEFAULT CHARSET=latin1 COMMENT='For sorting a list'")
	doSQL("CREATE TABLE `prefabCopies` (`owner` bigint(17) NOT NULL DEFAULT '0',`name` varchar(50) NOT NULL DEFAULT '',`x1` int(11) NOT NULL DEFAULT '0',`x2` int(11) NOT NULL DEFAULT '0',`y1` int(11) NOT NULL DEFAULT '0',`y2` int(11) NOT NULL DEFAULT '0',`z1` int(11) NOT NULL DEFAULT '0',`z2` int(11) NOT NULL DEFAULT '0',`blockName` VARCHAR(50) NOT NULL DEFAULT '',`rotation` INT NOT NULL DEFAULT '0', PRIMARY KEY (`owner`,`name`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `memEntities` (`entityID` bigint(20) NOT NULL,`type` varchar(20) NOT NULL DEFAULT '',`name` varchar(30) NOT NULL DEFAULT '',`x` int(11) NOT NULL DEFAULT '0',`y` int(11) NOT NULL DEFAULT '0',`z` int(11) DEFAULT '0',`dead` tinyint(1) NOT NULL DEFAULT '0',`health` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`entityID`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `waypoints` (`steam` varchar(17) NOT NULL,`name` varchar(20) NOT NULL,`x` int(11) NOT NULL DEFAULT '0',`y` int(11) NOT NULL DEFAULT '0',`z` int(11) NOT NULL DEFAULT '0',`shared` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`steam`,`name`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `gimmeZombies` (`zombie` varchar(50) NOT NULL,`minPlayerLevel` int(11) NOT NULL DEFAULT '1',`minArenaLevel` int(11) NOT NULL DEFAULT '1', PRIMARY KEY (`zombie`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `miscQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`steam` bigint(17) NOT NULL,`command` varchar(100) NOT NULL,`action` varchar(15) NOT NULL,`value` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8")
	doSQL("CREATE TABLE `customCommands` (`commandID` int(11) NOT NULL AUTO_INCREMENT, `command` varchar(50) NOT NULL, `accessLevel` int(11) NOT NULL DEFAULT '2', `help` varchar(255) NOT NULL, PRIMARY KEY (`commandID`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `whitelist` (`steam` varchar(17) NOT NULL, PRIMARY KEY (`steam`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `otherEntities` (`entity` varchar(50) NOT NULL,`entityID` int(11) NOT NULL DEFAULT '0',`doNotSpawn` tinyint(4) NOT NULL DEFAULT '0', PRIMARY KEY (`entity`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE IF NOT EXISTS `helpCommands` (`commandID` int(11) NOT NULL AUTO_INCREMENT,`command` varchar(255) NOT NULL,`description` varchar(255) NOT NULL,`notes` text NOT NULL,`keywords` varchar(150) NOT NULL,`lastUpdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`accessLevel` int(11) NOT NULL DEFAULT '99',`ingameOnly` tinyint(1) NOT NULL DEFAULT '0', PRIMARY KEY (`commandID`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE IF NOT EXISTS `helpTopicCommands` (`topicID` int(11) NOT NULL,`commandID` int(11) NOT NULL, PRIMARY KEY (`topicID`, `commandID`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE IF NOT EXISTS `helpTopics` (`topicID` int(11) NOT NULL AUTO_INCREMENT,`topic` varchar(20) NOT NULL,`description` varchar(200) NOT NULL, PRIMARY KEY (`topicID`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `staff` (`steam` bigint(17) NOT NULL DEFAULT '0',`adminLevel` int(11) NOT NULL DEFAULT '2',`blockDelete` tinyint(1) NOT NULL DEFAULT '0', PRIMARY KEY (`steam`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")

	-- changes to players table
	doSQL("ALTER TABLE `players` ADD COLUMN `waypoint2X` INT NOT NULL DEFAULT '0' , ADD COLUMN `waypoint2Y` INT NOT NULL DEFAULT '0' , ADD COLUMN `waypoint2Z` INT NOT NULL DEFAULT '0', ADD COLUMN `waypointsLinked` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD COLUMN `ircMute` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD COLUMN `chatColour` VARCHAR(8) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `players` ADD COLUMN `teleCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD COLUMN `reserveSlot` TINYINT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD COLUMN `prisonReleaseTime` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD COLUMN `maxWaypoints` INT NOT NULL DEFAULT '2'")
	doSQL("ALTER TABLE `players` ADD COLUMN ircLogin varchar(20) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `players` ADD COLUMN `waypointCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` CHANGE `location` `location` VARCHAR(15) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '', CHANGE `maxWaypoints` `maxWaypoints` INT(11) NOT NULL DEFAULT '2'")
	doSQL("ALTER TABLE `players` ADD `bail` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `watchPlayerTimer` INT(11) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `hackerScore` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `pvpTeleportCooldown` INT NOT NULL DEFAULT '0'")

if (debug) then display("debug alterTables line " .. debugger.getinfo(1).currentline) end
	-- changes to server table
	doSQL("ALTER TABLE `server` ADD COLUMN `teleportCost` INT NOT NULL DEFAULT '200'")
	doSQL("ALTER TABLE `server` ADD COLUMN `ircPrivate` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `waypointsPublic` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `waypointCost` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `waypointCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `waypointCreateCost` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `alertColour` VARCHAR(6) NOT NULL DEFAULT 'DC143C'")
	doSQL("ALTER TABLE `server` ADD COLUMN `warnColour` VARCHAR(6) NOT NULL DEFAULT 'FFA500'")
	doSQL("ALTER TABLE `server` ADD COLUMN `swearFine` INT NOT NULL DEFAULT '5'")
	doSQL("ALTER TABLE `server` ADD COLUMN `commandPrefix` VARCHAR(1) NOT NULL DEFAULT '/'")
	doSQL("ALTER TABLE `server` ADD COLUMN `chatlogPath` VARCHAR(200) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` ADD COLUMN `botVersion` VARCHAR(11) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` ADD COLUMN `packCost` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `baseCost` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `rebootHour` INT NOT NULL DEFAULT '-1'")
	doSQL("ALTER TABLE `server` ADD COLUMN `rebootMinute` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `maxPrisonTime` INT NOT NULL DEFAULT '-1'")
	doSQL("ALTER TABLE `server` ADD COLUMN `bailCost` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `maxWaypoints` INT NOT NULL DEFAULT '2'")
	doSQL("ALTER TABLE `server` ADD COLUMN `teleportPublicCost` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `teleportPublicCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `reservedSlots` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `allowReturns` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD COLUMN `scanNoclip` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD COLUMN `scanEntities` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `CBSMFriendly` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD COLUMN `scanErrors` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN disableTPinPVP TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD COLUMN `ServerToolsDetected` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` CHANGE `moneyName` `moneyName` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'Zenny|Zennies'")
	doSQL("ALTER TABLE `server` CHANGE rules VARCHAR(500) NOT NULL DEFAULT 'A zombie ate the server rules! Tell an admin.'")
	doSQL("ALTER TABLE `server` ADD `updateBot` INT(1) NOT NULL DEFAULT '0' COMMENT '0 do not update, 1 stable branch, 2 testing branch'")
	doSQL("ALTER TABLE `server` ADD `alertSpending` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `GBLBanThreshold` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` CHANGE `shopCountdown` `shopCountdown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `lastBotsMessageID` INT NOT NULL DEFAULT '0' , ADD `lastBotsMessageTimestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP")
	doSQL("ALTER TABLE `server` ADD `gimmeZombies` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `allowProxies` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `SDXDetected` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `enableWindowMessages` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `updateBranch` VARCHAR(7) NOT NULL DEFAULT 'stable'")
	doSQL("ALTER TABLE `server` ADD `chatColourNewPlayer` VARCHAR(6) NOT NULL DEFAULT 'FFFFFF' , ADD `chatColourPlayer` VARCHAR(6) NOT NULL DEFAULT 'FFFFFF' , ADD `chatColourDonor` VARCHAR(6) NOT NULL DEFAULT 'FFFFFF' , ADD `chatColourPrisoner` VARCHAR(6) NOT NULL DEFAULT 'FFFFFF' , ADD `chatColourMod` VARCHAR(6) NOT NULL DEFAULT 'FFFFFF' , ADD `chatColourAdmin` VARCHAR(6) NOT NULL DEFAULT 'FFFFFF' , ADD `chatColourOwner` VARCHAR(6) NOT NULL DEFAULT 'FFFFFF'")
	doSQL("ALTER TABLE `server` ADD `commandCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` CHANGE `ircAlerts` `ircAlerts` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '#new_alerts'")
	doSQL("ALTER TABLE `server` CHANGE `ircWatch` `ircWatch` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '#new_watch'")
	doSQL("ALTER TABLE `server` CHANGE `botName` `botName` VARCHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'Bot'")
	doSQL("ALTER TABLE `server` CHANGE `ircMain` `ircMain` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '#new'")
	doSQL("ALTER TABLE `server` CHANGE `ircBotName` `ircBotName` VARCHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'Bot'")
	doSQL("ALTER TABLE `server` CHANGE `shopLocation` `shopLocation` VARCHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL")
	doSQL("ALTER TABLE `server` CHANGE `blockCountries` `blockCountries` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'CN'")
	doSQL("ALTER TABLE `server` CHANGE `moneyName` `moneyName` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'Zenny|Zennies'")
	doSQL("ALTER TABLE `server` CHANGE `ircTracker` `ircTracker` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '#new_tracker'")
	doSQL("ALTER TABLE `server` CHANGE `mapSize` `mapSize` INT(11) NOT NULL DEFAULT '10000'")
	doSQL("ALTER TABLE `server` ADD `telnetPass` VARCHAR(50) NOT NULL")
	doSQL("ALTER TABLE `server` ADD `telnetPort` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `feralRebootDelay` INT NOT NULL DEFAULT '68'")
	doSQL("ALTER TABLE `server` ADD `pvpTeleportCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `allowPlayerToPlayerTeleporting` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `ircPort` INT NOT NULL DEFAULT '6667'")
	doSQL("ALTER TABLE `server` CHANGE `botVersion` `botVersion` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` CHANGE `updateBot` `updateBot` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `botRestartHour` INT NOT NULL DEFAULT '25'")
	doSQL("ALTER TABLE `server` ADD `trackingKeepDays` INT NOT NULL DEFAULT '28' , ADD `databaseMaintenanceFinished` TINYINT(1) NOT NULL DEFAULT '1'")


if (debug) then display("debug alterTables line " .. debugger.getinfo(1).currentline) end
	-- misc table changes
	doSQL("ALTER TABLE `friends` ADD `autoAdded` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `hotspots` ADD `action` VARCHAR(10) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `hotspots` ADD `destination` VARCHAR(20) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `inventoryChanges` ADD `flag` VARCHAR(3) DEFAULT ''")
	doSQL("ALTER TABLE `donors` CHANGE `donorExpiry` `donorExpiry` INT(11) NULL DEFAULT NULL")
	doSQL("ALTER TABLE `gimmePrizes` ADD `quality` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `gimmeZombies` ADD `entityID` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `gimmeZombies` ADD `bossZombie` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `gimmeZombies` ADD `doNotSpawn` TINYINT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `gimmeZombies` ADD `maxHealth` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `memShop` CHANGE `item` `item` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL")
	doSQL("ALTER TABLE `locations` ADD `timeOpen` INT NOT NULL DEFAULT '0' , ADD `timeClosed` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `allowWaypoints` TINYINT(1) NOT NULL DEFAULT '1' , ADD `allowReturns` TINYINT(1) NOT NULL DEFAULT '1', ADD `allowLeave` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `miscQueue` CHANGE `command` `command` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL")
	doSQL("ALTER TABLE `miscQueue` CHANGE `id` `id` BIGINT( 20 ) NOT NULL AUTO_INCREMENT")
	doSQL("ALTER TABLE `locations` ADD `newPlayersOnly` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `minimumLevel` INT NOT NULL DEFAULT '0', ADD `maximumLevel` INT NOT NULL DEFAULT '0', ADD `dayClosed` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `dailyTaxRate` INT NOT NULL DEFAULT '0', ADD `bank` INT NOT NULL DEFAULT '0', ADD `prisonX` INT NOT NULL DEFAULT '0' , ADD `prisonY` INT NOT NULL DEFAULT '0' , ADD `prisonZ` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `alerts` ADD `status` VARCHAR(30) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `IPBlacklist` ADD `DateAdded` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP , ADD `botID` INT NOT NULL DEFAULT '0' , ADD `steam` BIGINT(17) NOT NULL DEFAULT '0' , ADD `playerName` VARCHAR(25) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `miscQueue` ADD `timerDelay` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'")

	-- bots db
	doSQL("ALTER TABLE `bans` ADD `GBLBan` TINYINT(1) NOT NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `messageQueue` ADD `messageTimestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP", true)
	doSQL("ALTER TABLE `players` ADD `ircAlias` VARCHAR(15) NOT NULL , ADD `ircAuthenticated` TINYINT(1) NOT NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `IPBlacklist` ADD  `DateAdded` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP , ADD `botID` INT NOT NULL DEFAULT '0' , ADD `steam` BIGINT(17) NOT NULL DEFAULT '0' , ADD `playerName` VARCHAR(25) NOT NULL DEFAULT '', ADD `IP` VARCHAR(15) NOT NULL DEFAULT ''", true)
	doSQL("ALTER TABLE `bans` ADD `GBLBanExpiry` DATE NOT NULL", true)
	doSQL("ALTER TABLE `bans` ADD `GBLBanReason` VARCHAR(255) NOT NULL DEFAULT ''", true)
	doSQL("ALTER TABLE `bans` ADD `GBLBanVetted` TINYINT(1) NOT NULL DEFAULT '0',  ADD `GBLBanActive` TINYINT(1) NOT NULL DEFAULT '0'", true)

	-- change the primary key of table bans from steam to id (an auto incrementing integer field) if the id field does not exist.
	cursor,errorString = connBots:execute("SHOW COLUMNS FROM `bans` LIKE 'id'")
	rows = cursor:numrows()

	if rows == 0 then
		doSQL("ALTER TABLE  `bans` DROP PRIMARY KEY , ADD `id` bigint(20) NOT NULL AUTO_INCREMENT, ADD PRIMARY KEY (  `id` )", true)
	end

	statements = {}

	-- fix a bad choice of primary keys. Won't touch players again since it won't complete if a field exists which it then adds.
	migratePlayers()

if debug then display("alterTables end") end

	if benchmarkBot then
		display("function alterTables elapsed time: " .. string.format("%.2f", os.clock() - benchStart))
	end
end


function botHeartbeat()
	-- update the servers table in database bots with the current timestamp so the web interface can see that this bot is awake.
	if botman.db2Connected then
		connBots:execute("UPDATE servers SET tick = now() WHERE botID = " .. server.botID)
	end
end
