--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


-- useful reference: luapower.com/mysql

mysql = require "luasql.mysql"
local debug = false
local statements = {}


function resetMySQLMemoryTables()
	-- this resets auto incrementing key fields to 1
	conn:execute("TRUNCATE TABLE APIQueue")
	conn:execute("TRUNCATE TABLE commandQueue")
	conn:execute("TRUNCATE TABLE gimmeQueue")
	conn:execute("TRUNCATE TABLE ircQueue")
	conn:execute("TRUNCATE TABLE list")
	conn:execute("TRUNCATE TABLE LKPQueue")
	conn:execute("TRUNCATE TABLE memEntities")
	conn:execute("TRUNCATE TABLE memIgnoredItems")
	conn:execute("TRUNCATE TABLE memLottery")
	conn:execute("TRUNCATE TABLE memRestrictedItems")
	conn:execute("TRUNCATE TABLE memShop")
	conn:execute("TRUNCATE TABLE memTracker")
	conn:execute("TRUNCATE TABLE messageQueue")
	conn:execute("TRUNCATE TABLE miscQueue")
	conn:execute("TRUNCATE TABLE playerQueue")
	-- we don't touch the reservedSlots memory table so that we can preserve it across restarts later
	conn:execute("TRUNCATE TABLE searchResults")
end


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

		id = rand(9999)
		cursor,errorString = connBots:execute("select botID from servers where botID = " .. id)

		while tonumber(cursor:numrows()) > 0 do
			id = rand(9999)
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
	if not botman.db2Connected then
		return
	end

	if tonumber(server.botID) > 0 then
		-- insert or update player in bots db
		if players[steam].ip then
			connBots:execute("INSERT INTO players (botID, server, steam, ip, name, online, level, zombies, score, playerKills, deaths, timeOnServer, playtime, country, ping) VALUES (" .. server.botID .. ",'" .. escape(server.serverName) .. "'," .. steam .. ",'" .. players[steam].ip .. "','" .. escape(players[steam].name) .. "', 1," .. players[steam].level .. "," .. players[steam].zombies .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].deaths .. "," .. players[steam].timeOnServer .. "," .. igplayers[steam].sessionPlaytime .. ",'" .. players[steam].country .. "'," .. players[steam].ping .. ") ON DUPLICATE KEY UPDATE ip = '" .. players[steam].ip .. "', name = '" .. escape(players[steam].name) .. "', online = 1, level = " .. players[steam].level .. ", zombies = " .. players[steam].zombies .. ", score = " .. players[steam].score .. ", playerKills = " .. players[steam].playerKills .. ", deaths = " .. players[steam].deaths .. ", timeOnServer  = " .. players[steam].timeOnServer .. ", playtime = " .. igplayers[steam].sessionPlaytime .. ", country = '" .. players[steam].country .. "', ping = " .. players[steam].ping)
		else
			connBots:execute("INSERT INTO players (botID, server, steam, name, online, level, zombies, score, playerKills, deaths, timeOnServer, playtime, country, ping) VALUES (" .. server.botID .. ",'" .. escape(server.serverName) .. "'," .. steam .. ",'" .. escape(players[steam].name) .. "', 1," .. players[steam].level .. "," .. players[steam].zombies .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].deaths .. "," .. players[steam].timeOnServer .. "," .. igplayers[steam].sessionPlaytime .. ",'" .. players[steam].country .. "'," .. players[steam].ping .. ") ON DUPLICATE KEY UPDATE ip = '" .. players[steam].ip .. "', name = '" .. escape(players[steam].name) .. "', online = 1, level = " .. players[steam].level .. ", zombies = " .. players[steam].zombies .. ", score = " .. players[steam].score .. ", playerKills = " .. players[steam].playerKills .. ", deaths = " .. players[steam].deaths .. ", timeOnServer  = " .. players[steam].timeOnServer .. ", playtime = " .. igplayers[steam].sessionPlaytime .. ", country = '" .. players[steam].country .. "', ping = " .. players[steam].ping)
		end
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
		connBots:execute("UPDATE players SET ip = '" .. players[k].ip .. "', name = '" .. escape(v.name) .. "', online = 1, level = " .. v.level .. ", zombies = " .. v.zombies .. ", score = " .. v.score .. ", playerKills = " .. v.playerKills .. ", deaths = " .. v.deaths .. ", timeOnServer  = " .. players[k].timeOnServer .. ", playtime = " .. v.sessionPlaytime .. ", country = '" .. players[k].country .. "', ping = " .. v.ping .. " WHERE steam = " .. k .. " AND botID = " .. server.botID)
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


function autoBaseDefend(raider, baseOwner, whichBase)
	-- experimental base protection like trader protection.  Teleports out in a random direction.
	local dist, protected

	dist = 10000
	protected = false

	if whichBase == 1 then
		dist = distancexz(igplayers[raider].xPos, igplayers[raider].zPos, players[baseOwner].homeX, players[baseOwner].homeZ)

		if players[baseOwner].protect then
			protected = true
		end
	else
		dist = distancexz(igplayers[raider].xPos, igplayers[raider].zPos, players[baseOwner].home2X, players[baseOwner].home2Z)

		if players[baseOwner].protect2 then
			protected = true
		end
	end

	if dist < server.baseSize and protected then
		tmp = {}
		tmp.side = rand(4)
		tmp.offset = rand(50)

		if tmp.side == 1 then
			tmp.x = players[baseOwner].homeX - (server.baseSize + 10 + tmp.offset)
			tmp.z = players[baseOwner].homeZ
		end

		if tmp.side == 2 then
			tmp.x = players[baseOwner].homeX + (server.baseSize + 10 + tmp.offset)
			tmp.z = players[baseOwner].homeZ
		end

		if tmp.side == 3 then
			tmp.x = players[baseOwner].homeX
			tmp.x = players[baseOwner].homeZ - (server.baseSize + 10 + tmp.offset)
		end

		if tmp.side == 4 then
			tmp.x = players[baseOwner].homeX
			tmp.x = players[baseOwner].homeZ + (server.baseSize + 10 + tmp.offset)
		end

		tmp.cmd = "tele " .. raider .. " " .. tmp.x .. " -1 " .. tmp.z
		teleport(tmp.cmd, raider)

		if whichBase == 1 then
			irc_chat(server.ircAlerts, "base protection triggered for base1 of " .. players[baseOwner].name .. " " .. baseOwner .. " against " .. players[raider].name .. " " .. raider)

			if igplayers[baseOwner] and not pvpZone(players[baseOwner].homeX, players[baseOwner].homeZ) then
				message("pm " .. baseOwner .. " [" .. server.chatColour .. "]" .. igplayers[raider].name .. " has been ejected from your 1st base.[-]")
			end

			alertAdmins(igplayers[raider].name .. " has been ejected from " .. players[baseOwner].name  .."'s 1st base.")
		else
			irc_chat(server.ircAlerts, "base protection triggered for base2 of " .. players[baseOwner].name .. " " .. baseOwner .. " against " .. players[raider].name .. " " .. raider)

			if igplayers[baseOwner] and not pvpZone(players[baseOwner].home2X, players[baseOwner].home2Z) then
				message("pm " .. baseOwner .. " [" .. server.chatColour .. "]" .. igplayers[raider].name .. " has been ejected from your 2nd base.[-]")
			end

			alertAdmins(igplayers[raider].name .. " has been ejected from " .. players[baseOwner].name  .."'s 2nd base.")
		end

		message("pm " .. raider .. " [" .. server.chatColour .. "]You are too close to a protected player base.  The base owner needs to add you to their friends list by typing " .. server.commandPrefix .. "friend " .. igplayers[raider].name .. "[-]")
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
	if tonumber(value) == 0 then
		return false
	else
		return true
	end
end


function dbYN(value)
	-- translate db true false to Lua true false
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

	botman.dbConnected = false
	botman.dbBotsConnected = false
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
		conn:execute("CREATE TABLE `waypoints` (`id` int(11) NOT NULL, `steam` varchar(17) NOT NULL,`name` varchar(30) NOT NULL,`x` int(11) NOT NULL,`y` int(11) NOT NULL,`z` int(11) NOT NULL,`linked` int(11) NOT NULL DEFAULT '0',`shared` tinyint(4) NOT NULL DEFAULT '0', `public` TINYINT(1) NOT NULL DEFAULT '0') ENGINE=InnoDB DEFAULT CHARSET=latin1")
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


local function doSQL(sql, botsDB, forced)
	local shortSQL = string.sub(sql, 1, 1000) -- truncate the sql to 1000 chars
	local newSQL

	-- make sure that all changes to the players table are mirrored to playersArchived.
	if string.find(sql, "ALTER TABLE `players`", nil, true) and not botsDB then
		newSQL = sql
		newSQL = newSQL:gsub("`players`", "`playersArchived`")

		-- apply the altered sql to the playersArchived table
		conn:execute(newSQL)
	end

	if not statements[shortSQL] or forced ~= nil then
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


function refreshMySQLMemoryTables()
	-- all we're doing here is ensuring that all of the memory tables have had all of their table changes applied.
	doSQL("CREATE TABLE `list` (`thing` varchar(255) NOT NULL) ENGINE=MEMORY DEFAULT CHARSET=latin1 COMMENT='For sorting a list'", false, true)
	doSQL("CREATE TABLE `memEntities` (`entityID` bigint(20) NOT NULL,`type` varchar(20) NOT NULL DEFAULT '',`name` varchar(30) NOT NULL DEFAULT '',`x` int(11) NOT NULL DEFAULT '0',`y` int(11) NOT NULL DEFAULT '0',`z` int(11) DEFAULT '0',`dead` tinyint(1) NOT NULL DEFAULT '0',`health` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`entityID`)) ENGINE=MEMORY DEFAULT CHARSET=latin1", false, true)
	doSQL("CREATE TABLE `miscQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`steam` bigint(17) NOT NULL,`command` varchar(100) NOT NULL,`action` varchar(15) NOT NULL,`value` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8", false, true)
	doSQL("CREATE TABLE `connectQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT, `steam` bigint(17) NOT NULL, `command` varchar(255) NOT NULL, `processed` TINYINT(1) NOT NULL DEFAULT '0', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4", false, true)
	doSQL("CREATE TABLE `APIQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`URL` varchar(500) NOT NULL,`OutputFile` varchar(500) NOT NULL, PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4", false, true)
	doSQL("CREATE TABLE `LKPQueue` (`id` int(11) NOT NULL AUTO_INCREMENT, `line` varchar(255) NOT NULL DEFAULT '', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4", false, true)
	doSQL("CREATE TABLE `persistentQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`steam` bigint(17) NOT NULL,`command` varchar(255) NOT NULL,`action` varchar(15) NOT NULL,  `value` int(11) NOT NULL DEFAULT '0',`timerDelay` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4", false, true)
	doSQL("CREATE TABLE `slots` (`slot` int(11) NOT NULL,`steam` bigint(17) NOT NULL DEFAULT '0',`online` tinyint(1) NOT NULL DEFAULT '0',`joinedTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`joinedSession` int(11) NOT NULL DEFAULT '0',`expires` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`reserved` tinyint(1) NOT NULL DEFAULT '0',`staff` tinyint(1) NOT NULL DEFAULT '0',`free` TINYINT(1) NOT NULL DEFAULT '1',`canBeKicked` TINYINT(1) NOT NULL DEFAULT '1',`disconnectedTimestamp` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00', PRIMARY KEY (`slot`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4", false, true)
	doSQL("ALTER TABLE `memShop` CHANGE `item` `item` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL", false, true)
	doSQL("ALTER TABLE `miscQueue` CHANGE `command` `command` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL", false, true)
	doSQL("ALTER TABLE `miscQueue` CHANGE `id` `id` BIGINT( 20 ) NOT NULL AUTO_INCREMENT", false, true)
	doSQL("ALTER TABLE `miscQueue` ADD `timerDelay` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'", false, true)
	doSQL("ALTER TABLE `memShop` ADD `units` INT NOT NULL DEFAULT '1'", false, true)
	doSQL("ALTER TABLE `memEntities` ENGINE = MEMORY", false, true)
	doSQL("ALTER TABLE `reservedSlots` ENGINE = MEMORY", false, true)
	doSQL("ALTER TABLE `list` ADD `id` INT NOT NULL DEFAULT '0' , ADD `class` VARCHAR(20) NOT NULL DEFAULT ''", false, true)
	doSQL("ALTER TABLE `LKPQueue` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT", false, true) -- to fix missing auto increment for some bots that helped with testing
	doSQL("ALTER TABLE `list` DROP INDEX `thing`, ADD PRIMARY KEY(`id`)", false, true)
	doSQL("ALTER TABLE `list` DROP PRIMARY KEY", false, true) -- OOPS! Doesn't work too well with indexes.  Down with them I say!
	doSQL("ALTER TABLE `list` ADD `steam` BIGINT(17) NOT NULL DEFAULT '0'", false, true)
	doSQL("ALTER TABLE `playerQueue` ADD `delayTimer` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP", false, true)
end


function alterTables()
	local benchStart = os.clock()
	local sql

	if debug then display("alterTables start\n") end

	-- These are here to make it easier to update other bots while the bot is in development.
	-- After each sql statement is processed, they are stored in the table altertables which is checked so that each statement is only ever run once.
	-- When the bot first runs it will execute all of these statements and will appear frozen for several seconds.  Don't panic!  It comes back.

	-- new tables
	conn:execute("CREATE TABLE `altertables` (`id` int(11) NOT NULL,`statement` varchar(1000) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	conn:execute("ALTER TABLE `altertables` ADD PRIMARY KEY (`id`)")
	conn:execute("ALTER TABLE `altertables` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT")

	-- the altertables table is used to store statements that we've already executed so we don't keep trying to modify the db with the same stuff
	-- every time the bot is started or refreshed.

	-- load the previously executed statements from altertables into the Lua statements table for checking by doSQL
	statements = {}
	cursor,errorString = conn:execute("select * from altertables")
	row = cursor:fetch({}, "a")
	while row do
		statements[row.statement] = {}
		row = cursor:fetch(row, "a")
	end

	-- new tables continued
	doSQL("CREATE TABLE `badWords` (`badWord` varchar(15) NOT NULL,`cost` int(11) NOT NULL DEFAULT '10',`counter` int(11) NOT NULL DEFAULT '0') ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `list` (`thing` varchar(255) NOT NULL) ENGINE=MEMORY DEFAULT CHARSET=latin1 COMMENT='For sorting a list'")
	doSQL("CREATE TABLE `prefabCopies` (`owner` bigint(17) NOT NULL DEFAULT '0',`name` varchar(50) NOT NULL DEFAULT '',`x1` int(11) NOT NULL DEFAULT '0',`x2` int(11) NOT NULL DEFAULT '0',`y1` int(11) NOT NULL DEFAULT '0',`y2` int(11) NOT NULL DEFAULT '0',`z1` int(11) NOT NULL DEFAULT '0',`z2` int(11) NOT NULL DEFAULT '0',`blockName` VARCHAR(50) NOT NULL DEFAULT '',`rotation` INT NOT NULL DEFAULT '0', PRIMARY KEY (`owner`,`name`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `memEntities` (`entityID` bigint(20) NOT NULL,`type` varchar(20) NOT NULL DEFAULT '',`name` varchar(30) NOT NULL DEFAULT '',`x` int(11) NOT NULL DEFAULT '0',`y` int(11) NOT NULL DEFAULT '0',`z` int(11) DEFAULT '0',`dead` tinyint(1) NOT NULL DEFAULT '0',`health` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`entityID`)) ENGINE=MEMORY DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `waypoints` (`steam` varchar(17) NOT NULL,`name` varchar(20) NOT NULL,`x` int(11) NOT NULL DEFAULT '0',`y` int(11) NOT NULL DEFAULT '0',`z` int(11) NOT NULL DEFAULT '0',`shared` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`steam`,`name`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `gimmeZombies` (`zombie` varchar(50) NOT NULL,`minPlayerLevel` int(11) NOT NULL DEFAULT '1',`minArenaLevel` int(11) NOT NULL DEFAULT '1', PRIMARY KEY (`zombie`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `miscQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`steam` bigint(17) NOT NULL,`command` varchar(100) NOT NULL,`action` varchar(15) NOT NULL,`value` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8")
	doSQL("CREATE TABLE `customCommands` (`commandID` int(11) NOT NULL AUTO_INCREMENT, `command` varchar(50) NOT NULL, `accessLevel` int(11) NOT NULL DEFAULT '2', `help` varchar(255) NOT NULL, PRIMARY KEY (`commandID`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `whitelist` (`steam` varchar(17) NOT NULL, PRIMARY KEY (`steam`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `otherEntities` (`entity` varchar(50) NOT NULL,`entityID` int(11) NOT NULL DEFAULT '0',`doNotSpawn` tinyint(4) NOT NULL DEFAULT '0', PRIMARY KEY (`entity`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `helpCommands` (`commandID` int(11) NOT NULL AUTO_INCREMENT,`command` varchar(255) NOT NULL,`description` varchar(255) NOT NULL,`notes` text NOT NULL,`keywords` varchar(150) NOT NULL,`lastUpdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`accessLevel` int(11) NOT NULL DEFAULT '99',`ingameOnly` tinyint(1) NOT NULL DEFAULT '0', PRIMARY KEY (`commandID`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `helpTopicCommands` (`topicID` int(11) NOT NULL,`commandID` int(11) NOT NULL, PRIMARY KEY (`topicID`, `commandID`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `helpTopics` (`topicID` int(11) NOT NULL AUTO_INCREMENT,`topic` varchar(20) NOT NULL,`description` varchar(200) NOT NULL, PRIMARY KEY (`topicID`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `staff` (`steam` bigint(17) NOT NULL DEFAULT '0',`adminLevel` int(11) NOT NULL DEFAULT '2',`blockDelete` tinyint(1) NOT NULL DEFAULT '0', PRIMARY KEY (`steam`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `spawnableItems` (`itemName` varchar(100) NOT NULL, `deleteItem` tinyint(1) NOT NULL DEFAULT '0', `accessLevelRestriction` int(11) NOT NULL DEFAULT '99', `category` varchar(20) NOT NULL DEFAULT 'None', `price` int(11) NOT NULL DEFAULT '10000', `stock` int(11) NOT NULL DEFAULT '5000', `idx` int(11) NOT NULL DEFAULT '0', `maxStock` int(11) NOT NULL DEFAULT '5000', `inventoryResponse` varchar(10) NOT NULL DEFAULT 'none', `StackLimit` int(11) NOT NULL DEFAULT '1000', `newPlayerMaxInventory` int(11) NOT NULL DEFAULT '-1', `units` int(11) NOT NULL DEFAULT '1', PRIMARY KEY (`itemName`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `reservedSlots` (`steam` varchar(17) NOT NULL,`timeAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`reserved` tinyint(1) NOT NULL DEFAULT '0',`staff` tinyint(1) NOT NULL DEFAULT '0',`totalPlayTime` int(11) NOT NULL DEFAULT '0',`deleteRow` TINYINT(1) NOT NULL DEFAULT '0',PRIMARY KEY (`steam`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `botCommands` (`cmdCode` varchar(5) NOT NULL,`cmdIndex` int(11) NOT NULL,`accessLevel` int(11) NOT NULL DEFAULT '0',`enabled` tinyint(1) NOT NULL DEFAULT '1',`keywords` varchar(150) NOT NULL DEFAULT '',`shortDescription` varchar(255) NOT NULL DEFAULT '',`longDescription` varchar(1000) NOT NULL DEFAULT '',`sortOrder` int(11) NOT NULL DEFAULT '0',PRIMARY KEY (`cmdCode`,`cmdIndex`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `timedEvents` (`timer` varchar(20) NOT NULL DEFAULT '',`delayMinutes` int(11) NOT NULL DEFAULT '10',`nextTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`disabled` tinyint(1) NOT NULL DEFAULT '0',PRIMARY KEY (`timer`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `botChat` (`botChatID` int(11) NOT NULL AUTO_INCREMENT,`triggerWords` varchar(255) NOT NULL DEFAULT '',`triggerPhrase` varchar(255) NOT NULL DEFAULT '',`accessLevelRestriction` int(11) NOT NULL DEFAULT '99',`mustAddressBot` tinyint(1) NOT NULL DEFAULT '0',PRIMARY KEY (`botChatID`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `botChatResponses` (`botChatResponseID` int(11) NOT NULL AUTO_INCREMENT,`botChatID` int(11) NOT NULL DEFAULT '0',`response` varchar(300) NOT NULL DEFAULT '',PRIMARY KEY (`botChatResponseID`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `webInterfaceQueue` (`id` int(11) NOT NULL AUTO_INCREMENT,`action` varchar(10) NOT NULL DEFAULT '',`actionTable` varchar(50) NOT NULL DEFAULT '',`actionQuery` text NOT NULL,PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `locationCategories` (`categoryName` varchar(20) NOT NULL,`minAccessLevel` int(11) NOT NULL DEFAULT '99',`maxAccessLevel` int(11) NOT NULL DEFAULT '0',PRIMARY KEY (`categoryName`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
	doSQL("CREATE TABLE `gimmeGroup` (`groupName` varchar(30) NOT NULL DEFAULT '',PRIMARY KEY (`groupName`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE `connectQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT, `steam` bigint(17) NOT NULL, `command` varchar(255) NOT NULL, `processed` TINYINT(1) NOT NULL DEFAULT '0', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE `commandAccessRestrictions` (`id` int(11) NOT NULL, `functionName` varchar(100) NOT NULL DEFAULT '', `accessLevel` int(11) NOT NULL DEFAULT '3', PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE `customCommands_Detail` (`detailID` int(11) NOT NULL, `commandID` int(11) NOT NULL, `action` varchar(5) NOT NULL DEFAULT '' COMMENT 'say,give,tele,spawn,buff,cmd', `thing` varchar(255) NOT NULL DEFAULT '', PRIMARY KEY (`detailID`,`commandID`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE playersArchived LIKE players")
	doSQL("CREATE TABLE `APIQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`URL` varchar(500) NOT NULL,`OutputFile` varchar(500) NOT NULL, PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE `LKPQueue` (`id` int(11) NOT NULL AUTO_INCREMENT, `line` varchar(255) NOT NULL DEFAULT '', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE `persistentQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`steam` bigint(17) NOT NULL,`command` varchar(255) NOT NULL,`action` varchar(15) NOT NULL,  `value` int(11) NOT NULL DEFAULT '0',`timerDelay` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE `slots` (`slot` int(11) NOT NULL,`steam` bigint(17) NOT NULL DEFAULT '0',`online` tinyint(1) NOT NULL DEFAULT '0',`joinedTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`joinedSession` int(11) NOT NULL DEFAULT '0',`expires` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`reserved` tinyint(1) NOT NULL DEFAULT '0',`staff` tinyint(1) NOT NULL DEFAULT '0',`free` TINYINT(1) NOT NULL DEFAULT '1',`canBeKicked` TINYINT(1) NOT NULL DEFAULT '1',`disconnectedTimestamp` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00', PRIMARY KEY (`slot`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE `bases` (`steam` bigint(17) NOT NULL,`baseNumber` int(11) NOT NULL DEFAULT '1',`title` varchar(100) NOT NULL DEFAULT '',`x` int(11) NOT NULL DEFAULT '0',`y` int(11) NOT NULL DEFAULT '0',`z` int(11) NOT NULL DEFAULT '0',`exitX` int(11) NOT NULL DEFAULT '0',`exitY` int(11) NOT NULL DEFAULT '0',`exitZ` int(11) NOT NULL DEFAULT '0',`size` int(11) NOT NULL DEFAULT '0',`protect` tinyint(1) NOT NULL DEFAULT '0',`keepOut` tinyint(1) NOT NULL DEFAULT '0',`creationTimestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,`creationGameDay` INT NOT NULL DEFAULT '0',PRIMARY KEY (`steam`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE `webInterfaceJSON` (`ident` varchar(50) NOT NULL,`json` text NOT NULL, `sessionID` VARCHAR(32) NOT NULL DEFAULT '', PRIMARY KEY (`ident`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")

	-- changes to players table
	doSQL("ALTER TABLE `players` ADD COLUMN `waypoint2X` INT NOT NULL DEFAULT '0' , ADD COLUMN `waypoint2Y` INT NOT NULL DEFAULT '0' , ADD COLUMN `waypoint2Z` INT NOT NULL DEFAULT '0', ADD COLUMN `waypointsLinked` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD COLUMN `ircMute` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD COLUMN `chatColour` VARCHAR(8) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `players` ADD COLUMN `teleCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD COLUMN `reserveSlot` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD COLUMN `prisonReleaseTime` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD COLUMN `maxWaypoints` INT NOT NULL DEFAULT '2'")
	doSQL("ALTER TABLE `players` ADD COLUMN ircLogin varchar(20) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `players` ADD COLUMN `waypointCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` CHANGE `location` `location` VARCHAR(15) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '', CHANGE `maxWaypoints` `maxWaypoints` INT(11) NOT NULL DEFAULT '2'")
	doSQL("ALTER TABLE `players` ADD `bail` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `watchPlayerTimer` INT(11) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `hackerScore` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `pvpTeleportCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `block` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `removedClaims` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `returnCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` CHANGE `cash` `cash` FLOAT(11) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` CHANGE `chatColour` `chatColour` VARCHAR(8) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'FFFFFF'")
	doSQL("ALTER TABLE `players` ADD `commandCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` CHANGE `chatColour` `chatColour` VARCHAR(6) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'FFFFFF'")
	doSQL("ALTER TABLE `players` ADD `gimmeCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` CHANGE `donorExpiry` `donorExpiry` INT(11) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci")
	doSQL("ALTER TABLE `players` CHANGE `name` `name` VARCHAR(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL")
	doSQL("ALTER TABLE `players` CHANGE `aliases` `aliases` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL")
	doSQL("ALTER TABLE `players` ADD `VACBanned` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `bountyReason` VARCHAR(100) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `players` ADD `claimsExpired` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `showLocationMessages` TINYINT(1) NOT NULL DEFAULT '1'") -- this is just here for backwards compatibility
	doSQL("ALTER TABLE `players` ADD `DNSLookupCount` INT NOT NULL DEFAULT '0', ADD `lastDNSLookup` DATE NOT NULL DEFAULT '1000-01-01'")
	doSQL("ALTER TABLE `players` ADD `ircAuthenticated` TINYINT(1) NOT NULL DEFAULT '0'")


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
	doSQL("ALTER TABLE `server` CHANGE `rules` `rules` VARCHAR(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT 'A zombie ate the server rules! Tell an admin.'")
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
	doSQL("ALTER TABLE `server` CHANGE `blacklistCountries` `blacklistCountries` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'CN'")
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
	doSQL("ALTER TABLE `server` ADD `allowHomeTeleport` TINYINT(1) NOT NULL DEFAULT '1' , ADD `playerTeleportDelay` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `allowPackTeleport` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `gameVersion` VARCHAR(30) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` ADD `pvpIgnoreFriendlyKills` TINYINT(1) NOT NULL DEFAULT '0', ADD `allowStuckTeleport` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `restrictIRC` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `nextAnnouncement` INT NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `pvpAllowProtect` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `hackerTPDetection` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` CHANGE `updateBranch` `updateBranch` VARCHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'stable'")
	doSQL("ALTER TABLE `server` CHANGE `moneyName` `moneyName` VARCHAR(40) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'Zenny|Zennies'")
	doSQL("ALTER TABLE `server` ADD `whitelistCountries` VARCHAR(50) NOT NULL DEFAULT '' , ADD `perMinutePayRate` INT NOT NULL DEFAULT '0' , ADD `disableWatchAlerts` TINYINT(1) NOT NULL DEFAULT '0' , ADD `masterPassword` VARCHAR(50) NOT NULL DEFAULT '', ADD `allowBotRestarts` TINYINT(1) NOT NULL DEFAULT '0', ADD `botOwner` VARCHAR(17) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` CHANGE `pvpAllowProtect` `pvpAllowProtect` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `returnCooldown` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` CHANGE `blockCountries` `blacklistCountries` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'CN,HK'")
	doSQL("ALTER TABLE `server` ADD `botRestartDay` INT NOT NULL DEFAULT '7'")
	doSQL("ALTER TABLE `server` CHANGE `perMinutePayRate` `perMinutePayRate` FLOAT(11) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `enableTimedClaimScan` TINYINT(1) NOT NULL DEFAULT '1', ADD `enableScreamerAlert` TINYINT(1) NOT NULL DEFAULT '1' , ADD `enableAirdropAlert` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `spleefGameCoords` VARCHAR(20) NOT NULL DEFAULT '4000 225 4000'") --todo add the game code
	doSQL("ALTER TABLE `server` CHANGE `blacklistResponse` `blacklistResponse` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'ban'")
	doSQL("ALTER TABLE `server` ADD `gimmeResetTime` INT NOT NULL DEFAULT '120', ADD `gimmeRaincheck` INT NOT NULL DEFAULT '0'") -- gimmeRainCheck is a gimme cooldown timer between gimmes.
	doSQL("ALTER TABLE `server` ADD `pingKickTarget` VARCHAR(3) NOT NULL DEFAULT 'new' , ADD `enableBounty` TINYINT(1) NOT NULL DEFAULT '1', ADD `mapSizeNewPlayers` INT NOT NULL DEFAULT '10000' , ADD `mapSizePlayers` INT NOT NULL DEFAULT '10000', ADD `shopResetDays` INT NOT NULL DEFAULT '3'")
	doSQL("ALTER TABLE `server` ADD `telnetLogKeepDays` INT NOT NULL DEFAULT '14'")
	doSQL("ALTER TABLE `server` CHANGE `IP` `IP` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0.0.0.0'")
	doSQL("ALTER TABLE `server` ADD `dailyRebootHour` int(11) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `maxWaypointsDonors` INT NOT NULL DEFAULT '2'")
	doSQL("ALTER TABLE `server` CHANGE `lastBotsMessageTimestamp` `lastBotsMessageTimestamp` INT(11) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `baseProtectionExpiryDays` INT NOT NULL DEFAULT '40'")
	doSQL("ALTER TABLE `server` ADD `banVACBannedPlayers` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` CHANGE `lottery` `lottery` FLOAT(11) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` CHANGE `lotteryMultiplier` `lotteryMultiplier` FLOAT(11) NOT NULL DEFAULT '2'")
	doSQL("ALTER TABLE `server` CHANGE `zombieKillReward` `zombieKillReward` FLOAT(11) NOT NULL DEFAULT '3'")
	doSQL("ALTER TABLE `server` ADD `deathCost` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `showLocationMessages` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `bountyRewardItem` VARCHAR(25) NOT NULL DEFAULT 'cash'")
	doSQL("ALTER TABLE `server` ADD `enableLagCheck` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `allowSecondBaseWithoutDonor` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `nonAlphabeticChatReaction` VARCHAR(10) NOT NULL DEFAULT 'nothing'")
	doSQL("ALTER TABLE `server` ADD `lotteryTicketPrice` INT NOT NULL DEFAULT '25'")
	doSQL("ALTER TABLE `server` ADD `newPlayerMaxLevel` INT NOT NULL DEFAULT '9'")
	doSQL("ALTER TABLE `server` ADD `hordeNight` INT NOT NULL DEFAULT '7'")
	doSQL("ALTER TABLE `server` ADD `hideUnknownCommand` TINYINT(1) NOT NULL DEFAULT '0', ADD `beQuietBot` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `gimmeResetTimer` INT NOT NULL DEFAULT '120', ADD `shopResetGameOrRealDays` TINYINT(1) NOT NULL DEFAULT '0', ADD `zombieKillRewardDonors` FLOAT NOT NULL DEFAULT '3'")
	doSQL("ALTER TABLE `server` ADD `allowFamilySteamKeys` TINYINT(1) NOT NULL DEFAULT '1'") --todo: add commands and check for mismatched steam keys
	doSQL("ALTER TABLE `server` ADD `checkLevelHack` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `despawnZombiesBeforeBloodMoon` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `optOutGlobalBots` TINYINT(1) NOT NULL DEFAULT '0'") -- todo code
	doSQL("ALTER TABLE `server` ADD `dropMiningWarningThreshold` INT NOT NULL DEFAULT '99'")
	doSQL("ALTER TABLE `server` ADD `webPanelPort` INT NOT NULL DEFAULT '8080'")
	doSQL("ALTER TABLE `server` ADD `allocsWebAPIUser` VARCHAR(100) NOT NULL DEFAULT '', ADD `allocsWebAPIPassword` VARCHAR(100) NOT NULL DEFAULT '', ADD `useAllocsWebAPI` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `defaultWatchTimer` INT NOT NULL DEFAULT '259200'")
	doSQL("ALTER TABLE `server` ADD `archivePlayersLastSeenDays` INT NOT NULL DEFAULT '60'")
	doSQL("ALTER TABLE `server` CHANGE `webPanelPort` `webPanelPort` INT(11) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `playersLastArchived` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP")
	doSQL("ALTER TABLE `server` ADD `alertLevelHack` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `logBotCommands` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `logInventory` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `removeExpiredClaims` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` CHANGE `date` `date` VARCHAR(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` CHANGE `welcome` `welcome` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` CHANGE `MOTD` `MOTD` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` CHANGE `shopLocation` `shopLocation` VARCHAR(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` CHANGE `rules` `rules` VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT 'A zombie ate the server rules! Tell an admin.'")
	doSQL("ALTER TABLE `server` CHANGE `botName` `botName` VARCHAR(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Bot'")
	doSQL("ALTER TABLE `server` CHANGE `serverName` `serverName` VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'New Server'")
	doSQL("ALTER TABLE `server` CHANGE `website` `website` VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` CHANGE `ircServer` `ircServer` VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '127.0.0.1'")
	doSQL("ALTER TABLE `server` CHANGE `serverGroup` `serverGroup` VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` CHANGE `moneyName` `moneyName` VARCHAR(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Zenny|Zennies'")
	doSQL("ALTER TABLE `server` ADD `baseDeadzone` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `reservedSlotTimelimit` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `logPollingInterval` INT NOT NULL DEFAULT '3'")
	doSQL("ALTER TABLE `server` ADD `commandLagThreshold` INT NOT NULL DEFAULT '15'")
	doSQL("ALTER TABLE `server` CHANGE `logInventory` `logInventory` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `telnetDisabled` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `sayUsesIRCNick` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `readLogUsingTelnet` TINYINT(1) NOT NULL DEFAULT '0'")

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
	doSQL("ALTER TABLE `gimmeZombies` ADD `doNotSpawn` TINYINT(1) NOT NULL DEFAULT '0'")
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
	doSQL("ALTER TABLE `keystones` ADD `expired` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `spawnableItems` ADD `craftable` TINYINT(1) NOT NULL DEFAULT '1' , ADD `devBlock` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("INSERT INTO `timedEvents` (`timer`, `delayMinutes`, `nextTime`, `disabled`) VALUES ('announcements', '60', CURRENT_TIMESTAMP, '0')")
	doSQL("ALTER TABLE `locations` ADD `hidden` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` CHANGE `currency` `currency` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL")
	doSQL("ALTER TABLE `teleports` ADD `size` FLOAT(11) NOT NULL DEFAULT '1.5' COMMENT 'size of start tp' , ADD `dsize` FLOAT(11) NOT NULL DEFAULT '1.5' COMMENT 'size of dest tp'")
	doSQL("ALTER TABLE `botChat` MODIFY `botChatID` int(11) NOT NULL AUTO_INCREMENT")
	doSQL("ALTER TABLE `botChatResponses` MODIFY `botChatResponseID` int(11) NOT NULL AUTO_INCREMENT")
	doSQL("INSERT INTO `timedEvents` (`timer`, `delayMinutes`, `nextTime`, `disabled`) VALUES ('gimmeReset', '120', CURRENT_TIMESTAMP, '0')")
	doSQL("ALTER TABLE `badItems` ADD `validated` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `gimmePrizes` ADD `validated` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `restrictedItems` ADD `validated` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `shop` ADD `validated` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `shop` ADD `units` INT(1) NOT NULL, ADD `quality` INT(0) NOT NULL")
	doSQL("ALTER TABLE `customCommands_Detail` DROP PRIMARY KEY , ADD PRIMARY KEY (`detailID`,`commandID`)")
	doSQL("ALTER TABLE `memShop` ADD `units` INT NOT NULL DEFAULT '1'")

	-- fix zero default tp sizes
	doSQL("UPDATE `teleports` SET size = 1.5 WHERE size = 0")
	doSQL("UPDATE `teleports` SET dsize = 1.5 WHERE dsize = 0")

	doSQL("ALTER TABLE `waypoints` CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `events` CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `lottery` CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `memLottery` CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `playerNotes` CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `playerNotes` CHANGE `createdBy` `createdBy` BIGINT(17) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `whitelist` CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `memEntities` ENGINE = MEMORY")
	doSQL("ALTER TABLE `locations` ADD `locationCategory` VARCHAR(20) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `otherEntities` ADD `doNotDespawn` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `reservedSlots` CHANGE `steam` `steam` BIGINT(17) NOT NULL")
	doSQL("ALTER TABLE `reservedSlots` ENGINE = MEMORY")
	doSQL("ALTER TABLE `list` ADD `id` INT NOT NULL DEFAULT '0' , ADD `class` VARCHAR(20) NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `waypoints` ADD `public` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `teleports` ADD `minimumAccess` INT NOT NULL DEFAULT '0', ADD `maximumAccess` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `helpTopics` CHANGE `description` `description` TEXT CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `helpTopics` CHANGE `topic` `topic` VARCHAR(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL")
	doSQL("ALTER TABLE `helpCommands` CHANGE `command` `command` TEXT CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `helpCommands` CHANGE `description` `description` TEXT CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT ''")
	doSQL("ALTER TABLE `locations` ADD `coolDownTimer` INT NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `plot` TINYINT(1) NOT NULL DEFAULT '0', ADD `plotWallBock` VARCHAR(20) NOT NULL DEFAULT 'bedrock', ADD `plotFillBlock` VARCHAR(20) NOT NULL DEFAULT 'dirt', ADD `plotGridSize` INT NOT NULL DEFAULT '0', ADD `plotDepth` INT NOT NULL DEFAULT '5', ADD `hordeNightClosedHours` VARCHAR(5) NOT NULL DEFAULT '00-00'")
	doSQL("ALTER TABLE `locations` ADD `watchPlayers` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `customMessages` CHANGE `message` `message` VARCHAR(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL")
	doSQL("ALTER TABLE `otherEntities` ADD `remove` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `isRound` TINYINT(1) NOT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `locations` ADD `lobby` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `keystones` CHANGE `removed` `removed` INT(11) NOT NULL DEFAULT '0'")
	doSQL("UPDATE `keystones` SET removed = 0") -- this is necessary to stop the bot giving everyone claims in error due to a table change.
	doSQL("ALTER TABLE `customCommands_Detail` CHANGE `thing` `thing` VARCHAR(255)")
	doSQL("ALTER TABLE `LKPQueue` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT") -- to fix missing auto increment for some bots that helped with testing
	doSQL("ALTER TABLE `locations` CHANGE `name` `name` VARCHAR(50)")
	doSQL("ALTER TABLE `hotspots` CHANGE `hotspot` `hotspot` VARCHAR(500)")
	doSQL("ALTER TABLE `polls` CHANGE `topic` `topic` VARCHAR(255)")
	doSQL("ALTER TABLE `polls` CHANGE `option1` `option1` VARCHAR(255)")
	doSQL("ALTER TABLE `polls` CHANGE `option2` `option2` VARCHAR(255)")
	doSQL("ALTER TABLE `polls` CHANGE `option3` `option3` VARCHAR(255)")
	doSQL("ALTER TABLE `polls` CHANGE `option4` `option4` VARCHAR(255)")
	doSQL("ALTER TABLE `polls` CHANGE `option5` `option5` VARCHAR(255)")
	doSQL("ALTER TABLE `polls` CHANGE `option6` `option6` VARCHAR(255)")
	doSQL("ALTER TABLE `teleports` CHANGE `name` `name` VARCHAR(100)")
	doSQL("ALTER TABLE `waypoints` CHANGE `name` `name` VARCHAR(50)")
	doSQL("ALTER TABLE `bases` DROP PRIMARY KEY, ADD PRIMARY KEY(`steam`,`baseNumber`)")
	doSQL("ALTER TABLE `list` DROP INDEX `thing`, ADD PRIMARY KEY(`id`)")
	doSQL("ALTER TABLE `list` DROP PRIMARY KEY") -- OOPS! Doesn't work too well with indexes.  Down with them I say!
	doSQL("ALTER TABLE `list` ADD `steam` BIGINT(17) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `playerQueue` ADD `delayTimer` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP")
	doSQL("ALTER TABLE `webInterfaceQueue` ADD `steam` BIGINT(17) NOT NULL DEFAULT '0', `actionArgs` VARCHAR(1000) NOT NULL DEFAULT '', CHANGE `action` `action` VARCHAR(50), ADD `recipient` VARCHAR(5) NOT NULL DEFAULT '', ADD `expire` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00', ADD `sessionID` VARCHAR(32) NOT NULL DEFAULT ''")
	doSQL("DELETE FROM badItems WHERE item = 'snow'") -- remove a test item that shouldn't be live :O
	doSQL("INSERT INTO badItems (item, action) VALUES ('*Admin', 'timeout')")
	doSQL("UPDATE server SET logInventory = 1")
	doSQL("ALTER TABLE `inventoryTracker` CHANGE `pack` `pack` VARCHAR(1100)")
	doSQL("ALTER TABLE `IPBlacklist` ADD `Country` VARCHAR(2) DEFAULT ''")
	doSQL("ALTER TABLE `webInterfaceJSON` ADD `recipient` varchar(5) NOT NULL DEFAULT '', ADD `expire` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'")

	-- bots db
	doSQL("ALTER TABLE `bans` ADD `GBLBan` TINYINT(1) NOT NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `messageQueue` ADD `messageTimestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP", true)
	doSQL("ALTER TABLE `players` ADD `ircAlias` VARCHAR(15) NOT NULL , ADD `ircAuthenticated` TINYINT(1) NOT NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `IPBlacklist` ADD  `DateAdded` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP , ADD `botID` INT NOT NULL DEFAULT '0' , ADD `steam` BIGINT(17) NOT NULL DEFAULT '0' , ADD `playerName` VARCHAR(25) NOT NULL DEFAULT '', ADD `IP` VARCHAR(15) NOT NULL DEFAULT ''", true)
	doSQL("ALTER TABLE `bans` ADD `GBLBanExpiry` DATE NOT NULL", true)
	doSQL("ALTER TABLE `bans` ADD `GBLBanReason` VARCHAR(255) NOT NULL DEFAULT ''", true)
	doSQL("ALTER TABLE `bans` ADD `GBLBanVetted` TINYINT(1) NOT NULL DEFAULT '0',  ADD `GBLBanActive` TINYINT(1) NOT NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `players` ADD `VACBanned` TINYINT(1) NOT NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `bans` ADD `level` INT NOT NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `IPBlacklist` ADD `OrgName` VARCHAR(100) NOT NULL DEFAULT '", true)
	doSQL("CREATE TABLE IF NOT EXISTS `IPTable` (`StartIP` bigint(15) NOT NULL,`EndIP` bigint(15) NOT NULL,`Country` varchar(2) NOT NULL DEFAULT '',`OrgName` varchar(100) NOT NULL DEFAULT '',`IP` varchar(20) NOT NULL DEFAULT '', PRIMARY KEY (`StartIP`)) ENGINE=InnoDB DEFAULT CHARSET=utf8", true)
	doSQL("CREATE TABLE IF NOT EXISTS `settings` (`DNSLookupCounter` int(11) NOT NULL DEFAULT '0',`DNSResetCounterDate` int(11) NOT NULL DEFAULT '10000101') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", true)
	doSQL("ALTER TABLE `IPTable` ADD `steam` BIGINT(17) NOT NULL DEFAULT '0', ADD `botID` INT NOT NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE servers DROP COLUMN dbName, DROP COLUMN dbUser, DROP COLUMN dbPass", true)

	-- change the primary key of table bans from steam to id (an auto incrementing integer field) if the id field does not exist.
	cursor,errorString = connBots:execute("SHOW COLUMNS FROM `bans` LIKE 'id'")
	rows = cursor:numrows()

	if rows == 0 then
		doSQL("ALTER TABLE  `bans` DROP PRIMARY KEY , ADD `id` bigint(20) NOT NULL AUTO_INCREMENT, ADD PRIMARY KEY (  `id` )", true)
	end

	-- change the primary key of table gimmeZombies from zombie to entityID if the remove field does not exist.
	cursor,errorString = conn:execute("SHOW COLUMNS FROM `gimmeZombies` LIKE 'remove'")
	rows = cursor:numrows()

	if rows == 0 then
		doSQL("TRUNCATE gimmeZombies")
		doSQL("ALTER TABLE `gimmeZombies` DROP PRIMARY KEY , ADD PRIMARY KEY (  `entityID` ), ADD `remove` TINYINT(1) NOT NULL DEFAULT '0'")
	end

	statements = {}

	-- fix a bad choice of primary keys. Won't touch players again since it won't complete if a field exists which it then adds.
	migratePlayers()

	if debug then display("alterTables end") end

	if benchmarkBot then
		display("function alterTables elapsed time: " .. string.format("%.2f", os.clock() - benchStart))
	end

	if botman.fixingBot then
		botman.fixingBot = false

		if server.allowBotRestarts then
			restartBot()
		end
	end
end


function botHeartbeat()
	-- update the servers table in database bots with the current timestamp so the web interface can see that this bot is awake.
	if botman.db2Connected then
		connBots:execute("UPDATE servers SET tick = now(), playersOnline = " .. botman.playersOnline .. " WHERE botID = " .. server.botID)
	end
end
