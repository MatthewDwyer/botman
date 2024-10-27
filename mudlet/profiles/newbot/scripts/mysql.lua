--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]


-- useful reference: luapower.com/mysql

mysql = require "luasql.mysql"
local debug = false
local statements = {}


local function doSQL(sql, botsDB, forced)
	local shortSQL = string.sub(sql, 1, 1000) -- truncate the sql to 1000 chars
	local newSQL
	local cursor, errorString

	if (not statements[shortSQL]) or forced then
		statements[shortSQL] = {}

		-- make sure that all changes to the players table are mirrored to playersArchived.
		if string.find(sql, "ALTER TABLE `players`", nil, true) and not botsDB then
			newSQL = sql
			newSQL = newSQL:gsub("`players`", "`playersArchived`")

			-- apply the altered sql to the playersArchived table
			conn:execute(newSQL)
		end

		if botsDB then
			connBots:execute(sql)
		else

			cursor,errorString = conn:execute(sql)

			-- if errorString then
				-- if string.find(errorString, "error") then
					-- logDebug(sql)
					-- logDebug(errorString)
				-- end
			-- end
		end

		conn:execute("INSERT INTO altertables (statement) VALUES ('" .. escape(shortSQL) .. "')")
	end
end


function resetMySQLMemoryTables()
	-- make sure the tables exist
	refreshMySQLMemoryTables()
end


function deleteTrackingData(keepDays)
	-- to prevent the database collecting too much data, becoming slow and potentially filling the root partition
	-- we periodically clear out old data.  The default is to keep the last 28 days.
	-- It will be necessary to optimise the tables occasionally to purge the deleted records, but we need to give this task time to complete.

	-- don't run if the password is empty till I fix it so it'll work then
	if botDBPass == "" then
		return
	end

	local cmd
	local DateYear = os.date('%Y', os.time())
	local DateMonth = os.date('%m', os.time())
	local DateDay = os.date('%d', os.time())
	local deletionDate = os.time({day = DateDay - keepDays, month = DateMonth, year = DateYear})
	local deletionDate90Days = os.time({day = DateDay - 90, month = DateMonth, year = DateYear})

	cmd = "mysql -u " .. botDBUser .. " -p" .. botDBPass .. " -e 'DELETE FROM performance WHERE timestamp < \"" .. os.date("%Y-%m-%d", deletionDate90Days) .. "\"; DELETE FROM events WHERE timestamp < \"" .. os.date("%Y-%m-%d", deletionDate90Days) .. "\";' " .. botDB
	os.execute(cmd)
end


function migratePlayers()
	local cursor, errorString

	cursor,errorString = connBots:execute("SHOW COLUMNS FROM players LIKE 'steamOwner'")
	rows = cursor:numrows()

	if rows == 0 then
		connBots:execute("CREATE TABLE players2 LIKE players")
		connBots:execute("ALTER TABLE players2 DISABLE KEYS")
		connBots:execute("ALTER TABLE  players2 DROP PRIMARY KEY , ADD PRIMARY KEY (steam,botID)")
		connBots:execute("ALTER TABLE players2 ENABLE KEYS")
		connBots:execute("DROP TABLE players")
		connBots:execute("RENAME TABLE players2 TO players")
		connBots:execute("ALTER TABLE `players` ADD `steamOwner` BIGINT(17) NOT NULL DEFAULT '0'")
	end
end


function migrateBases()
	local cursor, errorString, rows, k, v

	cursor,errorString = conn:execute("SELECT * FROM bases")
	rows = cursor:numrows()

	if tonumber(rows) == 0 then
		for k,v in pairs(players) do
			if v.homeX then
				if tonumber(v.homeX) + tonumber(v.homeY) + tonumber(v.homeZ) ~= 0 then
					conn:execute("INSERT INTO bases (steam, baseNumber, x, y, z, exitX, exitY, exitZ, size, protect, protectSize) VALUES (" .. k .. ",1," .. v.homeX .. "," .. v.homeY .. "," .. v.homeZ .. "," .. v.exitX .. "," .. v.exitY .. "," .. v.exitZ .. "," .. server.baseSize .. "," .. dbBool(v.protect) .. "," .. v.protectSize .. ")")
				end

				if tonumber(v.home2X) + tonumber(v.home2Y) + tonumber(v.home2Z) ~= 0 then
					conn:execute("INSERT INTO bases (steam, baseNumber, x, y, z, exitX, exitY, exitZ, size, protect, protectSize) VALUES (" .. k .. ",2," .. v.home2X .. "," .. v.home2Y .. "," .. v.home2Z .. "," .. v.exit2X .. "," .. v.exit2Y .. "," .. v.exit2Z .. "," .. server.baseSize .. "," .. dbBool(v.protect2) .. "," .. v.protect2Size .. ")")
				end
			end
		end

		-- drop some fields from the players table and playersArchived table
		doSQL("ALTER TABLE players DROP `homeX`, DROP `homeY`, DROP `homeZ`, DROP `home2X`, DROP `home2Y`, DROP `home2Z`, DROP `exitX`, DROP `exitY`, DROP `exitZ`, DROP `exit2X`, DROP `exit2Y`, DROP `exit2Z`, DROP `protectSize`, DROP `protect2Size`, DROP `protect`, DROP `protect2`")
		doSQL("ALTER TABLE playersArchived DROP `homeX`, DROP `homeY`, DROP `homeZ`, DROP `home2X`, DROP `home2Y`, DROP `home2Z`, DROP `exitX`, DROP `exitY`, DROP `exitZ`, DROP `exit2X`, DROP `exit2Y`, DROP `exit2Z`, DROP `protectSize`, DROP `protect2Size`, DROP `protect`, DROP `protect2`")
	else
		-- drop some fields from the players table and playersArchived table
		doSQL("ALTER TABLE players DROP `homeX`, DROP `homeY`, DROP `homeZ`, DROP `home2X`, DROP `home2Y`, DROP `home2Z`, DROP `exitX`, DROP `exitY`, DROP `exitZ`, DROP `exit2X`, DROP `exit2Y`, DROP `exit2Z`, DROP `protectSize`, DROP `protect2Size`, DROP `protect`, DROP `protect2`")
		doSQL("ALTER TABLE playersArchived DROP `homeX`, DROP `homeY`, DROP `homeZ`, DROP `home2X`, DROP `home2Y`, DROP `home2Z`, DROP `exitX`, DROP `exitY`, DROP `exitZ`, DROP `exit2X`, DROP `exit2Y`, DROP `exit2Z`, DROP `protectSize`, DROP `protect2Size`, DROP `protect`, DROP `protect2`")
		return
	end

	loadBases()
end


function migrateDonors()
	local cursor, errorString, rows, k, v

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM donors")
		rows = cursor:numrows()

		if tonumber(rows) == 0 then
			conn:execute("INSERT INTO donors (steam, expiry, name) SELECT steam, donorExpiry, name FROM players WHERE donor = 1")
		else
			-- do a one time update of the donors table from the players table where the player is a donor and not expired
			for k,v in pairs(players) do
				if v.donor then
					if tonumber(v.donorExpiry) < os.time() then
						conn:execute("UPDATE donors SET expired = 1 WHERE steam = '" .. k .. "'")
						conn:execute("UPDATE donors SET expired = 1 WHERE steam = '" .. v.userID .. "'")

						irc_chat(server.ircAlerts, "Player " .. v.name ..  " " .. k .. " donor status has expired.")
						conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','donor','" .. escape(v.name) .. " " .. k .. " donor status expired.','" .. k .. "')")

						v.protect2 = false
						v.maxWaypoints = server.maxWaypoints
						conn:execute("UPDATE players SET protect2 = 0, donor = 0, maxWaypoints = " .. server.maxWaypoints .. " WHERE steam = '" .. k .. "'")

						-- remove the player's waypoints
						conn:execute("DELETE FROM waypoints WHERE steam = '" .. k .. "'")

						-- reload the player's waypoints
						loadWaypoints(k)

						connSQL:execute("INSERT INTO mail (sender, recipient, message) VALUES (0, '" .. k .. "', '" .. connMEM:escape("Your donor status has expired.  Any waypoints you had will need to be set again and extra bases have lost bot protection.") .. "')")
					end

					v.donor = false
					conn:execute("UPDATE players SET donor = 0 WHERE steam = '" .. k .. "'")
				end
			end

			return
		end

		loadDonors()

		for k,v in pairs(donors) do
			connBots:execute("INSERT INTO donors (donor, donorExpiry, steam, botID, serverGroup) VALUES (1," .. v.expiry .. ", '" .. k .. "'," .. server.botID .. ",'" .. escape(server.serverGroup) .. "')")
		end

		-- make sure we aren't missing any donors in the donors table that are donors in the players table
		for k,v in pairs(players) do
			if v.donor and not donors[k] then
				conn:execute("INSERT INTO donors (steam, expiry, name) SELECT steam, donorExpiry, name FROM players WHERE steam = '" .. k .. "'")
			end
		end

		conn:execute("UPDATE donors SET name = (SELECT name FROM players WHERE donors.steam = players.steam)")

		loadDonors() -- again again ^^
	end
end


function initBotsData()
	local IP, country

	if debug then display("initBotsData start\n") end

	-- insert players in bots db
	for k, v in pairs(players) do
		if v.ip == nil then
			v.ip = ""
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

	if botman.botsConnected then
		--connBots:execute("UPDATE players set online = 0 WHERE server = '" .. escape(server.serverName) .. "'")
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

		id = randSQL(9999)
		cursor,errorString = connBots:execute("select botID from servers where botID = " .. id)

		while tonumber(cursor:numrows()) > 0 do
			id = randSQL(9999)
			cursor,errorString = connBots:execute("select botID from servers where botID = " .. id)
		end

		connBots:execute("INSERT INTO servers (ServerPort, IP, botName, serverName, playersOnline, tick, botID) VALUES (" .. server.ServerPort .. ",'" .. server.IP .. "','" .. escape(server.botName) .. "','" .. escape(server.serverName) .. "'," .. botman.playersOnline .. ", now()," .. id .. ")")
		server.botID = id
		conn:execute("UPDATE server SET botID = " .. id)
	else
		-- check that there is a server record for this bot in bots db
		cursor,errorString = connBots:execute("select * from servers where botID = " .. server.botID)
		rows = cursor:numrows()

		if rows == 0 then
			connBots:execute("INSERT INTO servers (ServerPort, IP, botName, serverName, playersOnline, tick, botID) VALUES (" .. server.ServerPort .. ",'" .. escape(server.IP) .. "','" .. escape(server.botName) .. "','" .. escape(server.serverName) .. "'," .. botman.playersOnline .. ", now()," .. server.botID .. ")")
		else
			-- update it with current data
			connBots:execute("UPDATE servers SET serverName = '" .. escape(server.serverName) .. "', IP = '" .. escape(server.IP) .. "', ServerPort = " .. server.ServerPort .. ", botName = '" .. escape(server.botName) .. "', playersOnline = " .. botman.playersOnline .. ", tick = now() WHERE botID = " .. server.botID)
		end
	end

	-- Try to insert the current players into the players table on bots db
	for k, v in pairs(igplayers) do
		insertBotsPlayer(k)
	end

	if debug then display("registerBot end\n") end
end


function insertBotsPlayer(steam)
	if not botman.botsConnected or not players[steam] then
		return
	end

	-- if tonumber(server.botID) > 0 then
		-- -- insert or update player in bots db
		-- if players[steam].ip then
			-- connBots:execute("INSERT INTO players (botID, server, steam, ip, name, online, level, zombies, score, playerKills, deaths, timeOnServer, playtime, country, ping) VALUES (" .. server.botID .. ",'" .. escape(server.serverName) .. "'," .. steam .. ",'" .. players[steam].ip .. "','" .. escape(players[steam].name) .. "', 1," .. players[steam].level .. "," .. players[steam].zombies .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].deaths .. "," .. players[steam].timeOnServer .. "," .. igplayers[steam].sessionPlaytime .. ",'" .. players[steam].country .. "'," .. players[steam].ping .. ") ON DUPLICATE KEY UPDATE ip = '" .. players[steam].ip .. "', name = '" .. escape(players[steam].name) .. "', online = 1, level = " .. players[steam].level .. ", zombies = " .. players[steam].zombies .. ", score = " .. players[steam].score .. ", playerKills = " .. players[steam].playerKills .. ", deaths = " .. players[steam].deaths .. ", timeOnServer  = " .. players[steam].timeOnServer .. ", playtime = " .. igplayers[steam].sessionPlaytime .. ", country = '" .. players[steam].country .. "', ping = " .. players[steam].ping)
		-- else
			-- connBots:execute("INSERT INTO players (botID, server, steam, name, online, level, zombies, score, playerKills, deaths, timeOnServer, playtime, country, ping) VALUES (" .. server.botID .. ",'" .. escape(server.serverName) .. "'," .. steam .. ",'" .. escape(players[steam].name) .. "', 1," .. players[steam].level .. "," .. players[steam].zombies .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].deaths .. "," .. players[steam].timeOnServer .. "," .. igplayers[steam].sessionPlaytime .. ",'" .. players[steam].country .. "'," .. players[steam].ping .. ") ON DUPLICATE KEY UPDATE ip = '" .. players[steam].ip .. "', name = '" .. escape(players[steam].name) .. "', online = 1, level = " .. players[steam].level .. ", zombies = " .. players[steam].zombies .. ", score = " .. players[steam].score .. ", playerKills = " .. players[steam].playerKills .. ", deaths = " .. players[steam].deaths .. ", timeOnServer  = " .. players[steam].timeOnServer .. ", playtime = " .. igplayers[steam].sessionPlaytime .. ", country = '" .. players[steam].country .. "', ping = " .. players[steam].ping)
		-- end
	-- end
end


function updateBotsServerTable()
	local k, v

	if not botman.botsConnected or tonumber(server.botID) == 0 then
		return
	end

	connBots:execute("UPDATE servers SET ServerPort = " .. server.ServerPort .. ", IP = '" .. server.IP .. "', botName = '" .. escape(server.botName) .. "', playersOnline = " .. botman.playersOnline .. ", tick = now() WHERE botID = '" .. escape(server.botID))

	-- -- updated players on bots db
	-- for k, v in pairs(igplayers) do
		-- -- update player in bots db
		-- connBots:execute("UPDATE players SET ip = '" .. players[k].ip .. "', name = '" .. escape(v.name) .. "', online = 1, level = " .. v.level .. ", zombies = " .. v.zombies .. ", score = " .. v.score .. ", playerKills = " .. v.playerKills .. ", deaths = " .. v.deaths .. ", timeOnServer  = " .. players[k].timeOnServer .. ", playtime = " .. v.sessionPlaytime .. ", country = '" .. players[k].country .. "', ping = " .. v.ping .. " WHERE steam = " .. k .. " AND botID = " .. server.botID)
	-- end
end


function dumpTable(table)
	local cursor, errorString, row, fields, values, k, v, file

	cursor,errorString = conn:execute("SELECT * FROM " .. table)
	row = cursor:fetch({}, "a")

	file = io.open(homedir .. "/data_backup/" .. table .. "_" .. os.date("%Y%m%d_%H%M%S") .. ".csv", "a")

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


function rand(high, low, real)
	local cursor, errorString

	-- generate a random number using MySQL
	if low == nil then low = 1 end
	if real == nil then
		cursor,errorString = conn:execute("select floor(RAND()*(" .. high + 1 .. "-" .. low .. ")+" .. low .. ") as rnum")
	else
		cursor,errorString = conn:execute("select RAND()*(" .. high + 1 .. "-" .. low .. ")+" .. low .. " as rnum")
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
	if tonumber(value) == 0 then
		return false
	else
		return true
	end
end


function dbYN(value)
	-- translate db true false to the string Yes or No
	if tonumber(value) == 0 then
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
	resetMySQLMemoryTables()
	alterTables()
	getServerFields()
	getPlayerFields()
	if debug then display("initDB end") end
end


function closeDB()
	conn:close()
	connBots:close()

	botman.dbConnected = false
	botman.dbBotsConnected = false
end


function importBlacklist()
	local cursor, cursor2, errorString, row

	if not botman.botsConnected then
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
			split = string.split(ln, "%-")
			ip1 = IPToInt(string.trim(split[1]))
			ip2 = IPToInt(string.trim(split[2]))
			connBots:execute("INSERT INTO IPBlacklistClean (StartIP, EndIP, Country) VALUES (" .. ip1 .. "," .. ip2 .. ",'CN')")
		end
	end
end


function importBadItems()
	local cursor, cursor2, errorString, row

	if not botman.botsConnected then
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


function refreshMySQLMemoryTables()
	-- all we're doing here is ensuring that all of the memory tables have had all of their table changes applied.
	conn:execute("CREATE TABLE `slots` (`slot` int(11) NOT NULL,`steam` VARCHAR(40) NOT NULL DEFAULT '0',`online` tinyint(1) NOT NULL DEFAULT '0',`joinedTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`joinedSession` int(11) NOT NULL DEFAULT '0',`expires` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`reserved` tinyint(1) NOT NULL DEFAULT '0',`staff` tinyint(1) NOT NULL DEFAULT '0',`free` TINYINT(1) NOT NULL DEFAULT '1',`canBeKicked` TINYINT(1) NOT NULL DEFAULT '1',`disconnectedTimestamp` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00', PRIMARY KEY (`slot`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4")
end


function alterTables()
	local cursor, errorString, row, rows

	if debug then display("alterTables start\n") end

	-- These are here to make it easier to update other bots while the bot is in development.
	-- After each sql statement is processed, they are stored in the table altertables which is checked so that each statement is only ever run once.
	-- When the bot first runs it will execute all of these statements and will appear frozen for several seconds.  Don't panic!  It comes back.

	-- new tables
	conn:execute("CREATE TABLE `altertables` (`id` int(11) NOT NULL,`statement` varchar(1000) NULL DEFAULT '') ENGINE=InnoDB DEFAULT CHARSET=latin1")
	conn:execute("ALTER TABLE `altertables` ADD PRIMARY KEY (`id`)")
	conn:execute("ALTER TABLE `altertables` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT")
	conn:execute("ALTER TABLE `altertables` CHANGE `statement` `statement` VARCHAR(1000) NULL DEFAULT ''")

	-- the altertables table is used to store statements that we've already executed so we don't keep trying to modify the db with the same stuff
	-- every time the bot is started or refreshed.

	-- load the previously executed statements from altertables into the Lua statements table for checking by doSQL
	statements = {}
	cursor,errorString = conn:execute("SELECT * FROM altertables")
	row = cursor:fetch({}, "a")
	while row do
		statements[row.statement] = {}
		row = cursor:fetch(row, "a")
	end

	-- new tables continued
	doSQL("CREATE TABLE `playerGroups` (`groupID` int(11) NOT NULL AUTO_INCREMENT,`name` varchar(50) NOT NULL,`maxBases` int(11) NOT NULL DEFAULT '1',`maxProtectedBases` int(11) NOT NULL DEFAULT '1',`baseSize` int(11) NOT NULL DEFAULT '32',`baseCooldown` int(11) NOT NULL DEFAULT '300',`baseCost` int(11) NOT NULL DEFAULT '0',`maxWaypoints` int(11) NOT NULL DEFAULT '1',`waypointCost` int(11) NOT NULL DEFAULT '0',`waypointCooldown` int(11) NOT NULL DEFAULT '0',`waypointCreateCost` int(11) NOT NULL DEFAULT '0',`chatColour` varchar(6) NOT NULL DEFAULT 'FFFFFF',`teleportCost` int(11) NOT NULL DEFAULT '0',`packCost` int(11) NOT NULL DEFAULT '0',`teleportPublicCost` int(11) NOT NULL DEFAULT '0',`teleportPublicCooldown` int(11) NOT NULL DEFAULT '0',`returnCooldown` int(11) NOT NULL DEFAULT '0',`p2pCooldown` int(11) NOT NULL DEFAULT '0',`namePrefix` VARCHAR(20) NOT NULL DEFAULT '',`playerTeleportDelay` INT NOT NULL DEFAULT '0',`maxGimmies` INT NOT NULL DEFAULT '11',`packCooldown` INT NOT NULL DEFAULT '60',`zombieKillReward` INT NOT NULL DEFAULT '3',`allowLottery` TINYINT(1) NOT NULL DEFAULT '1',`lotteryMultiplier` INT NOT NULL DEFAULT '2',`lotteryTicketPrice` INT NOT NULL DEFAULT '25',`deathCost` INT NOT NULL DEFAULT '0',`mapSize` INT NOT NULL DEFAULT '20000',`perMinutePayRate` INT NOT NULL DEFAULT '0',`pvpAllowProtect` TINYINT(1) NOT NULL DEFAULT '0',`gimmeZombies` TINYINT(1) NOT NULL DEFAULT '1',`allowTeleporting` TINYINT(1) NOT NULL DEFAULT '1',`allowShop` TINYINT(1) NOT NULL DEFAULT '0',`allowGimme` TINYINT(1) NOT NULL DEFAULT '0',`hardcore` TINYINT(1) NOT NULL DEFAULT '0',`allowHomeTeleport` TINYINT(1) NOT NULL DEFAULT '1',`allowPlayerToPlayerTeleporting` TINYINT(1) NOT NULL DEFAULT '1',`allowVisitInPVP` TINYINT(1) NOT NULL DEFAULT '0', `reserveSlot` TINYINT(1) NOT NULL DEFAULT '0',`allowWaypoints` TINYINT(1) NOT NULL DEFAULT '0',PRIMARY KEY (`groupID`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE `baseMembers` (`baseOwner` varchar(40) NOT NULL DEFAULT '0',`baseNumber` int(11) NOT NULL DEFAULT 0,`baseMember` varchar(40) NOT NULL DEFAULT '0', PRIMARY KEY(`baseOwner`, `baseNumber`, `baseMember`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")

	-- changes to players table. These are duplicated to the playersArchived table in doSQL()
	doSQL("ALTER TABLE `players` ADD `maxBases` INT NOT NULL DEFAULT '1', ADD `maxProtectedBases` INT NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `players` ADD `groupID` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` DROP waypointX, DROP waypointY, DROP waypointZ, DROP waypoint2X, DROP waypoint2Y, DROP waypoint2Z")
	doSQL("ALTER TABLE `players` ADD `userID` VARCHAR(50) NOT NULL DEFAULT '', ADD `platform` VARCHAR(20) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `players` ADD `nameOverride` VARCHAR(100) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `players` CHANGE `ircAlias` `ircAlias` VARCHAR(30), CHANGE `ircLogin` `ircLogin` VARCHAR(30)")
	doSQL("ALTER TABLE `players` CHANGE `ircPass` `ircPass` VARCHAR(30) NULL DEFAULT NULL")

	if (debug) then display("debug alterTables line " .. debugger.getinfo(1).currentline) end

	-- changes to server table
	doSQL("ALTER TABLE `server` CHANGE `northeastZone` `northeastZone` VARCHAR(5) NULL DEFAULT '', CHANGE `northwestZone` `northwestZone` VARCHAR(5) NULL DEFAULT '', CHANGE `southeastZone` `southeastZone` VARCHAR(5) NULL DEFAULT '', CHANGE `southwestZone` `southwestZone` VARCHAR(5) NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` ADD `noGreetingMessages` TINYINT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `maxBases` INT NOT NULL DEFAULT '1', ADD `maxProtectedBases` INT NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` DROP `longPlayUpgradeTime`, DROP `allowPhysics`, DROP `ircTracker`, DROP `CBSMFriendly`, DROP `ServerToolsDetected`, DROP `lastBotsMessageTimestamp`, DROP `lastBotsMessageID`, DROP `SDXDetected`, DROP `databaseMaintenanceFinished`, DROP `enableTimedClaimScan`, DROP `spleefGameCoords`, DROP `bountyRewardItem`, DROP `enableLagCheck`, DROP `allowSecondBaseWithoutDonor`, DROP `commandLagThreshold`, DROP `telnetFallback`, DROP `waypointsPublic`")
	doSQL("ALTER TABLE `server` CHANGE `logPollingInterval` `logPollingInterval` INT(11) NULL DEFAULT '5'")
	doSQL("ALTER TABLE `server` ADD `setBaseCooldown` INT NOT NULL DEFAULT '0', ADD `setWPCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `maxGimmies` INT(11) NOT NULL DEFAULT '11'")
	doSQL("ALTER TABLE `server` ADD `suppressDisabledCommand` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `maxAdminLevel` INT NOT NULL DEFAULT '2'")
	doSQL("ALTER TABLE `server` ADD `kickXBox` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `allowVisitInPVP` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `botLoggingLevel` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `hackerFlyingTrigger` INT NOT NULL DEFAULT '7'")
	doSQL("ALTER TABLE `server` ADD `allowSuicide` TINYINT(1) NOT NULL DEFAULT '1', ADD `suicideCost` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `botPaused` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `safeModeSpamTrigger` INT NOT NULL DEFAULT '100'")

	if (debug) then display("debug alterTables line " .. debugger.getinfo(1).currentline) end

	-- other table changes
	doSQL('ALTER TABLE `webInterfaceJSON` ADD INDEX(`ident`)')
	doSQL('ALTER TABLE `webInterfaceQueue` ADD INDEX(`id`)')
	doSQL('ALTER TABLE `timedEvents` ADD INDEX(`timer`)')
	doSQL('ALTER TABLE `proxies` ADD INDEX(`scanString`)')
	doSQL('ALTER TABLE `announcements` ADD INDEX(`id`)')
	doSQL('ALTER TABLE `bans` ADD INDEX(`Steam`)')

	-- dropped tables and fields
	doSQL("DROP TABLE helpTopicCommands")
	doSQL("DROP TABLE commandAccessRestrictions")
	doSQL("DROP TABLE botCommands")
	doSQL("DROP TABLE list")
	doSQL("DROP TABLE list2")
	doSQL("DROP TABLE gimmequeue")
	doSQL("ALTER TABLE helpTopics DROP COLUMN topicID")
	doSQL("ALTER TABLE locations DROP COLUMN plot, DROP COLUMN plotWallBock, DROP COLUMN plotFillBlock, DROP COLUMN plotGridSize, DROP COLUMN plotDepth")
	doSQL("ALTER TABLE donors DROP COLUMN level")
	doSQL("ALTER TABLE announcements DROP COLUMN startDate, DROP COLUMN endDate")

	-- new fields
	doSQL("ALTER TABLE `helpCommands` ADD `functionName` varchar(60) NOT NULL DEFAULT '', ADD `topic` VARCHAR(20) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `bans` ADD `userID` VARCHAR(50) NULL DEFAULT '', ADD `platform` VARCHAR(20) NULL DEFAULT ''")
	doSQL("ALTER TABLE `staff` ADD `userID` VARCHAR(50) NULL DEFAULT '', ADD `platform` VARCHAR(20) NULL DEFAULT ''")
	doSQL("ALTER TABLE `whitelist` ADD `userID` VARCHAR(50) NULL DEFAULT '', ADD `platform` VARCHAR(20) NULL DEFAULT ''")
	doSQL("ALTER TABLE `webInterfaceQueue` ADD `userID` VARCHAR(50) NULL DEFAULT '', ADD `platform` VARCHAR(20) NULL DEFAULT ''")
	doSQL("ALTER TABLE `slots` ADD `userID` VARCHAR(50) NULL DEFAULT '', ADD `platform` VARCHAR(20) NULL DEFAULT ''")
	doSQL("ALTER TABLE `playerGroups` ADD `accessLevel` INT NOT NULL DEFAULT '90', ADD `donorGroup` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `groupID` INT(11) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `customMessages` ADD `groupID` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `customCommands` ADD `groupID` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `bases` ADD `protectSize` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `events` ADD `userID` VARCHAR(36) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `playerGroups` ADD `gimmeRaincheck` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `playerGroups` ADD `disableBaseProtection` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `playerGroups` ADD `setBaseCooldown` INT NOT NULL DEFAULT '0', ADD `setWPCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `setBaseCooldown` INT NOT NULL DEFAULT '0', ADD `setWPCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `announcements` ADD `triggerServerTime` TIME NULL DEFAULT '00:00:00', ADD `lastTriggered` INT(11) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `modBotman` ADD `vehicleFileDelete` TINYINT(1) NOT NULL DEFAULT '0', ADD `webmapTracePrefabs` TINYINT(1) NOT NULL DEFAULT '0', ADD `webmapTraceTraders` TINYINT(1) NOT NULL DEFAULT '0', ADD `webmapTraceResetAreas` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `staff` ADD `name` VARCHAR(100) NOT NULL DEFAULT '', ADD `hidden` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `groupExpiry` INT NOT NULL DEFAULT '0', ADD `groupExpiryFallbackGroup` INT NOT NULL DEFAULT '0'")

	-- inserts and removals
	doSQL("INSERT INTO `timedEvents` (`timer`, `delayMinutes`, `nextTime`, `disabled`) VALUES ('gimmeReset', '120', CURRENT_TIMESTAMP, '0')")
	doSQL("INSERT INTO `timedEvents` (`timer`, `delayMinutes`, `nextTime`, `disabled`) VALUES ('announcements', '60', CURRENT_TIMESTAMP, '0')")
	doSQL("DELETE FROM badItems WHERE item = 'snow'") -- remove a test item that shouldn't be live :O

	-- field changes
	doSQL("ALTER TABLE `bases` CHANGE `creationTimestamp` `creationTimestamp` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `badWords` ADD `response` VARCHAR(10) NOT NULL DEFAULT 'nothing', ADD `cooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `alerts` CHANGE `timestamp` `timestamp` INT NOT NULL DEFAULT '0', CHANGE `status` `status` VARCHAR(100) NOT NULL DEFAULT 'new alert', DROP COLUMN sent")
	doSQL("ALTER TABLE `locations` CHANGE `name` `name` VARCHAR(50) NULL DEFAULT '', CHANGE `currency` `currency` VARCHAR(60) NULL DEFAULT NULL")
	doSQL("ALTER TABLE `locationCategories` CHANGE `categoryName` `categoryName` VARCHAR(20) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `restrictedItems` CHANGE `item` `item` VARCHAR(100) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `IPBlacklist` CHANGE `playerName` `playerName` VARCHAR(100) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `teleports` CHANGE `name` `name` VARCHAR(100) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `waypoints` CHANGE `steam` `steam` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `webInterfaceJSON` CHANGE `json` `json` VARCHAR(10000) NULL DEFAULT NULL")
	doSQL("ALTER TABLE `webInterfaceQueue` CHANGE `actionQuery` `actionQuery` VARCHAR(2000) NULL DEFAULT NULL")
	doSQL("ALTER TABLE `shopCategories` CHANGE `code` `code` VARCHAR(10) NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` CHANGE `hackerFlyingTrigger` `hackerFlyingTrigger` INT NOT NULL DEFAULT '7'")
	doSQL("ALTER TABLE `server` CHANGE `safeModeSpamTrigger` `safeModeSpamTrigger` INT NOT NULL DEFAULT '100'")

	-- changes to replace steam id with platform id as primary field for stuff
	doSQL("ALTER TABLE `players` CHANGE `steam` `steam` VARCHAR(40) NOT NULL DEFAULT '0', CHANGE `steamOwner` `steamOwner` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `alerts` CHANGE `steam` `steam` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `bans` CHANGE `Steam` `Steam` VARCHAR(40) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `bases` CHANGE `steam` `steam` VARCHAR(40) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `donors` CHANGE `steam` `steam` VARCHAR(40) NOT NULL")
	doSQL("ALTER TABLE `events` CHANGE `steam` `steam` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `friends` CHANGE `steam` `steam` VARCHAR(40) NOT NULL, CHANGE `friend` `friend` VARCHAR(40) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `IPBlacklist` CHANGE `steam` `steam` VARCHAR(40) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` CHANGE `owner` `owner` VARCHAR(40) NULL DEFAULT '0', CHANGE `mayor` `mayor` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `playerNotes` CHANGE `steam` `steam` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `playersArchived` CHANGE `steam` `steam` VARCHAR(40) NOT NULL DEFAULT '0', CHANGE `steamOwner` `steamOwner` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `polls` CHANGE `author` `author` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `pollVotes` CHANGE `steam` `steam` VARCHAR(40) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `staff` CHANGE `steam` `steam` VARCHAR(40) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `teleports` CHANGE `owner` `owner` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `villagers` CHANGE `steam` `steam` VARCHAR(40) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `waypoints` CHANGE `steam` `steam` VARCHAR(40) NULL DEFAULT '0")
	doSQL("ALTER TABLE `webInterfaceQueue` CHANGE `steam` `steam` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `whitelist` CHANGE `steam` `steam` VARCHAR(40) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` CHANGE `botOwner` `botOwner` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `hotspots` CHANGE `owner` `owner` VARCHAR(40) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` CHANGE `pvpVictim` `pvpVictim` VARCHAR(40) NULL DEFAULT '0'")

	-- change some values
	doSQL("UPDATE server set hackerFlyingTrigger = 7")

	-- bots db
	doSQL("ALTER TABLE `bans` CHANGE `bannedTo` `bannedTo` VARCHAR(22) NULL DEFAULT NULL, CHANGE `GBLBanExpiry` `GBLBanExpiry` DATE NULL DEFAULT NULL", true)


	-- change the primary key of table helpCommands if still using commandID.
	cursor,errorString = conn:execute("SHOW COLUMNS FROM `helpCommands` LIKE 'commandID'")
	rows = cursor:numrows()

	if rows > 0 then
		conn:execute("TRUNCATE helpCommands")
		conn:execute("ALTER TABLE  helpCommands DROP COLUMN commandID , ADD PRIMARY KEY (functionName,topic)")
	end

	-- fix a bad choice of primary keys. Won't touch players again since it won't complete if a field exists which it then adds.
	migratePlayers()

	-- migrate bases from the players table to the bases table
	migrateBases()

	conn:execute("UPDATE players SET platform = 'Steam' WHERE platform = ''")

	if debug then display("alterTables end") end

	statements = {}

	if botman.fixingBot then
		botman.fixingBot = false

		if server.allowBotRestarts then
			restartBot()
		end
	end
end


function botHeartbeat()
	-- update the servers table in database bots with the current timestamp so the web interface can see that this bot is awake.
	-- if botman.botsConnected then
		-- connBots:execute("UPDATE servers SET tick = now(), playersOnline = " .. botman.playersOnline .. " WHERE botID = " .. server.botID)
	-- end
end
