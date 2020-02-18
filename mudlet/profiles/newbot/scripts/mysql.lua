--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


-- useful reference: luapower.com/mysql

mysql = require "luasql.mysql"
local debug = false
local statements = {}


function checkForData()
	local cursor, errorString, rows

	-- TODO:  Needs work and testing.  If uncommented atm it will prevent the bot starting up.

	-- cursor,errorString = conn:execute("SELECT 1 FROM server")
	-- rows = cursor:numrows()

	-- if rows == 0 then
		-- display("Server table empty! Attempting to import from last backup.")
		-- botman.silentDataImport = true
		-- importLuaData()
	-- end
end


function resetMySQLMemoryTables()
	-- make sure the tables exist
	refreshMySQLMemoryTables()

	-- nuke the memory tables to keep them minty fresh
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

	conn:execute("INSERT INTO memRestrictedItems (select * from restrictedItems)")
	conn:execute("INSERT INTO memLottery (select * from lottery)")
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


function migrateBases()
	local cursor, errorString, rows, k, v

	cursor,errorString = conn:execute("SELECT * FROM bases")
	rows = cursor:numrows()

	if tonumber(rows) == 0 then
		for k,v in pairs(players) do
			if tonumber(v.homeX) + tonumber(v.homeY) + tonumber(v.homeZ) ~= 0 then
				conn:execute("INSERT INTO bases (steam, baseNumber, x, y, z, exitX, exitY, exitZ, size, protect) VALUES (" .. k .. ",1," .. v.homeX .. "," .. v.homeY .. "," .. v.homeZ .. "," .. v.exitX .. "," .. v.exitY .. "," .. v.exitZ .. "," .. v.protectSize .. "," .. dbBool(v.protect) .. ")")
			end

			if tonumber(v.home2X) + tonumber(v.home2Y) + tonumber(v.home2Z) ~= 0 then
				conn:execute("INSERT INTO bases (steam, baseNumber, x, y, z, exitX, exitY, exitZ, size, protect) VALUES (" .. k .. ",2," .. v.home2X .. "," .. v.home2Y .. "," .. v.home2Z .. "," .. v.exit2X .. "," .. v.exit2Y .. "," .. v.exit2Z .. "," .. v.protect2Size .. "," .. dbBool(v.protect2) .. ")")
			end
		end
	else
		return
	end

	loadBases()
end


function migrateDonors()
	local cursor, errorString, rows, k, v

	cursor,errorString = conn:execute("SELECT * FROM donors")
	rows = cursor:numrows()

	if tonumber(rows) == 0 then
		conn:execute("INSERT INTO donors (steam, level, expiry) SELECT steam, donorLevel, donorExpiry FROM players WHERE donor = 1")
	else
		return
	end

	loadDonors()

	for k,v in pairs(donors) do
		connBots:execute("INSERT INTO donors (donor, donorLevel, donorExpiry, steam, botID, serverGroup) VALUES (1, " .. v.level .. ", " .. v.expiry .. ", " .. k .. "," .. server.botID .. ",'" .. escape(server.serverGroup) .. "')")
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
	refreshMySQLMemoryTables()
	resetMySQLMemoryTables()
	alterTables()
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
		conn:execute("CREATE TABLE `waypoints` (`id` int(11) NOT NULL, `steam` varchar(17) NOT NULL,`name` varchar(30) NOT NULL,`x` int(11) NOT NULL,`y` int(11) NOT NULL,`z` int(11) NOT NULL,`linked` int(11) NOT NULL DEFAULT '0',`shared` tinyint(1) NOT NULL DEFAULT '0', `public` TINYINT(1) NOT NULL DEFAULT '0') ENGINE=InnoDB DEFAULT CHARSET=latin1")
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

		conn:execute("INSERT INTO altertables (statement) VALUES ('" .. escape(shortSQL) .. "')")

		if botsDB then
			connBots:execute(sql)
		else
			conn:execute(sql)
		end
	end
end


function refreshMySQLMemoryTables()
	-- all we're doing here is ensuring that all of the memory tables have had all of their table changes applied.
	doSQL("CREATE TABLE `list` (`thing` varchar(255) NOT NULL DEFAULT '') ENGINE=MEMORY DEFAULT CHARSET=latin1 COMMENT='For sorting a list'", false, true)
	doSQL("CREATE TABLE `memEntities` (`entityID` bigint(20) NOT NULL,`type` varchar(20) NOT NULL DEFAULT '',`name` varchar(30) NOT NULL DEFAULT '',`x` int(11) NOT NULL DEFAULT '0',`y` int(11) NOT NULL DEFAULT '0',`z` int(11) DEFAULT '0',`dead` tinyint(1) NOT NULL DEFAULT '0',`health` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`entityID`)) ENGINE=MEMORY DEFAULT CHARSET=latin1", false, true)
	doSQL("CREATE TABLE `miscQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`steam` bigint(17) NOT NULL,`command` varchar(100) NOT NULL,`action` varchar(15) NOT NULL,`value` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8", false, true)
	doSQL("CREATE TABLE `connectQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT, `steam` bigint(17) NOT NULL, `command` varchar(255) NOT NULL, `processed` TINYINT(1) NOT NULL DEFAULT '0', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4", false, true)
	doSQL("CREATE TABLE `APIQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`URL` varchar(500) NOT NULL,`OutputFile` varchar(500) NOT NULL, PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4", false, true)
	doSQL("CREATE TABLE `LKPQueue` (`id` int(11) NOT NULL AUTO_INCREMENT, `line` varchar(255) NOT NULL DEFAULT '', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4", false, true)
	doSQL("CREATE TABLE `persistentQueue` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`steam` bigint(17) NOT NULL,`command` varchar(255) NOT NULL,`action` varchar(15) NOT NULL,  `value` int(11) NOT NULL DEFAULT '0',`timerDelay` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', PRIMARY KEY (`id`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4", false, true)
	doSQL("CREATE TABLE `slots` (`slot` int(11) NOT NULL,`steam` bigint(17) NOT NULL DEFAULT '0',`online` tinyint(1) NOT NULL DEFAULT '0',`joinedTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`joinedSession` int(11) NOT NULL DEFAULT '0',`expires` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,`reserved` tinyint(1) NOT NULL DEFAULT '0',`staff` tinyint(1) NOT NULL DEFAULT '0',`free` TINYINT(1) NOT NULL DEFAULT '1',`canBeKicked` TINYINT(1) NOT NULL DEFAULT '1',`disconnectedTimestamp` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00', PRIMARY KEY (`slot`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4", false, true)
	doSQL("ALTER TABLE `memShop` CHANGE `item` `item` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT ''", false, true)
	doSQL("ALTER TABLE `miscQueue` CHANGE `command` `command` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT ''", false, true)
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
	doSQL("CREATE TABLE list2 LIKE list", false, true)
end


function alterTables()
	local benchStart = os.clock()
	local sql

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
	doSQL("CREATE TABLE `otherEntities` (`entity` varchar(50) NOT NULL,`entityID` int(11) NOT NULL DEFAULT '0',`doNotSpawn` tinyint(1) NOT NULL DEFAULT '0', PRIMARY KEY (`entity`)) ENGINE=InnoDB DEFAULT CHARSET=latin1")
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
	doSQL("CREATE TABLE `donors` (`steam` int(11) NOT NULL, `level` int(11) NOT NULL DEFAULT '0', `expiry` int(11) DEFAULT NULL, PRIMARY KEY (`steam`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE `modBotman` (`clanEnabled` tinyint(1) NOT NULL DEFAULT '0',`clanMaxClans` int(11) NOT NULL DEFAULT '0',`clanMaxPlayers` int(11) NOT NULL DEFAULT '0',`clanMinLevel` int(11) NOT NULL DEFAULT '0') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")
	doSQL("CREATE TABLE list2 LIKE list")

	-- changes to players table
	doSQL("ALTER TABLE `players` ADD COLUMN `waypoint2X` INT NULL DEFAULT '0' , ADD COLUMN `waypoint2Y` INT NULL DEFAULT '0' , ADD COLUMN `waypoint2Z` INT NULL DEFAULT '0', ADD COLUMN `waypointsLinked` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `ircMute` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `chatColour` VARCHAR(6) NULL DEFAULT ''")
	doSQL("ALTER TABLE `players` ADD `teleCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `reserveSlot` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `prisonReleaseTime` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `maxWaypoints` INT NULL DEFAULT '2'")
	doSQL("ALTER TABLE `players` ADD ircLogin varchar(20) NULL DEFAULT ''")
	doSQL("ALTER TABLE `players` ADD `waypointCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `bail` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `watchPlayerTimer` INT(11) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `hackerScore` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `pvpTeleportCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `block` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `removedClaims` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `returnCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `commandCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `gimmeCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `VACBanned` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `bountyReason` VARCHAR(100) NULL DEFAULT ''")
	doSQL("ALTER TABLE `players` ADD `claimsExpired` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `showLocationMessages` TINYINT(1) NULL DEFAULT '1'") -- this is just here for backwards compatibility
	doSQL("ALTER TABLE `players` ADD `DNSLookupCount` INT NULL DEFAULT '0', ADD `lastDNSLookup` DATE NULL DEFAULT '1000-01-01'")
	doSQL("ALTER TABLE `players` ADD `ircAuthenticated` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `players` ADD `p2pCooldown` INT NULL DEFAULT '0'")

	doSQL("ALTER TABLE `players` CHANGE `name` `name` VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '', CHANGE `id` `id` INT(11) NULL DEFAULT '0', CHANGE `xPos` `xPos` INT(11) NULL DEFAULT '0', CHANGE `yPos` `yPos` INT(11) NULL DEFAULT '0', CHANGE `zPos` `zPos` INT(11) NULL DEFAULT '0', CHANGE `xPosOld` `xPosOld` INT(11) NULL DEFAULT '0', CHANGE `yPosOld` `yPosOld` INT(11) NULL DEFAULT '0', CHANGE `zPosOld` `zPosOld` INT(11) NULL DEFAULT '0', CHANGE `homeX` `homeX` INT(11) NULL DEFAULT '0', CHANGE `homeY` `homeY` INT(11) NULL DEFAULT '0', CHANGE `homeZ` `homeZ` INT(11) NULL DEFAULT '0', CHANGE `home2X` `home2X` INT(11) NULL DEFAULT '0', CHANGE `home2Y` `home2Y` INT(11) NULL DEFAULT '0', CHANGE `home2Z` `home2Z` INT(11) NULL DEFAULT '0', CHANGE `exitX` `exitX` INT(11) NULL DEFAULT '0', CHANGE `exitY` `exitY` INT(11) NULL DEFAULT '0', CHANGE `exitZ` `exitZ` INT(11) NULL DEFAULT '0', CHANGE `exit2X` `exit2X` INT(11) NULL DEFAULT '0', CHANGE `exit2Y` `exit2Y` INT(11) NULL DEFAULT '0', CHANGE `exit2Z` `exit2Z` INT(11) NULL DEFAULT '0', CHANGE `level` `level` INT(11) NULL DEFAULT '1', CHANGE `cash` `cash` FLOAT NULL DEFAULT '0', CHANGE `pvpBounty` `pvpBounty` INT(11) NULL DEFAULT '0', CHANGE `zombies` `zombies` INT(11) NULL DEFAULT '0', CHANGE `score` `score` INT(11) NULL DEFAULT '0', CHANGE `playerKills` `playerKills` INT(11) NULL DEFAULT '0', CHANGE `deaths` `deaths` INT(11) NULL DEFAULT '0', CHANGE `protectSize` `protectSize` INT(11) NULL DEFAULT '32', CHANGE `protect2Size` `protect2Size` INT(11) NULL DEFAULT '32'")

	doSQL("ALTER TABLE `players` CHANGE `sessionCount` `sessionCount` INT(11) NULL DEFAULT '1', CHANGE `timeOnServer` `timeOnServer` INT(11) NULL DEFAULT '0', CHANGE `firstSeen` `firstSeen` INT(11) NULL DEFAULT '0', CHANGE `keystones` `keystones` INT(11) NULL DEFAULT '0', CHANGE `overStackTimeout` `overStackTimeout` TINYINT(1) NULL DEFAULT '0', CHANGE `overstack` `overstack` TINYINT(1) NULL DEFAULT '0', CHANGE `shareWaypoint` `shareWaypoint` TINYINT(1) NULL DEFAULT '0', CHANGE `watchCash` `watchCash` TINYINT(1) NULL DEFAULT '0', CHANGE `watchPlayer` `watchPlayer` TINYINT(1) NULL DEFAULT '1', CHANGE `timeout` `timeout` TINYINT(1) NULL DEFAULT '0', CHANGE `denyRights` `denyRights` TINYINT(1) NULL DEFAULT '0', CHANGE `botTimeout` `botTimeout` TINYINT(1) NULL DEFAULT '0', CHANGE `newPlayer` `newPlayer` TINYINT(1) NULL DEFAULT '1', CHANGE `baseCooldown` `baseCooldown` INT(11) NULL DEFAULT '0', CHANGE `donor` `donor` TINYINT(1) NULL DEFAULT '0', CHANGE `playtime` `playtime` INT(11) NULL DEFAULT '0', CHANGE `protect` `protect` TINYINT(1) NULL DEFAULT '0', CHANGE `protect2` `protect2` TINYINT(1) NULL DEFAULT '0', CHANGE `tokens` `tokens` INT(11) NULL DEFAULT '0', CHANGE `exiled` `exiled` TINYINT(1) NULL DEFAULT '0', CHANGE `pvpCount` `pvpCount` INT(11) NULL DEFAULT '0', CHANGE `translate` `translate` TINYINT(1) NULL DEFAULT '0', CHANGE `prisoner` `prisoner` TINYINT(1) NULL DEFAULT '0', CHANGE `permanentBan` `permanentBan` TINYINT(1) NULL DEFAULT '0', CHANGE `whitelisted` `whitelisted` TINYINT(1) NULL DEFAULT '0', CHANGE `silentBob` `silentBob` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `players` CHANGE `walkies` `walkies` TINYINT(1) NULL DEFAULT '0', CHANGE `prisonxPosOld` `prisonxPosOld` INT(11) NULL DEFAULT '0', CHANGE `prisonyPosOld` `prisonyPosOld` INT(11) NULL DEFAULT '0', CHANGE `prisonzPosOld` `prisonzPosOld` INT(11) NULL DEFAULT '0', CHANGE `pvpVictim` `pvpVictim` BIGINT(17) NULL DEFAULT '0', CHANGE `canTeleport` `canTeleport` TINYINT(1) NULL DEFAULT '1', CHANGE `allowBadInventory` `allowBadInventory` TINYINT(1) NULL DEFAULT '0', CHANGE `ircTranslate` `ircTranslate` TINYINT(1) NULL DEFAULT '0', CHANGE `ircPass` `ircPass` VARCHAR(15) NULL DEFAULT '', CHANGE `noSpam` `noSpam` TINYINT(1) NULL DEFAULT '0', CHANGE `waypointX` `waypointX` INT(11) NULL DEFAULT '0', CHANGE `waypointY` `waypointY` INT(11) NULL DEFAULT '0', CHANGE `waypointZ` `waypointZ` INT(11) NULL DEFAULT '0', CHANGE `xPosTimeout` `xPosTimeout` INT(11) NULL DEFAULT '0', CHANGE `yPosTimeout` `yPosTimeout` INT(11) NULL DEFAULT '0', CHANGE `zPosTimeout` `zPosTimeout` INT(11) NULL DEFAULT '0', CHANGE `accessLevel` `accessLevel` INT(11) NULL DEFAULT '99', CHANGE `ping` `ping` INT(11) NULL DEFAULT '0', CHANGE `donorLevel` `donorLevel` INT(11) NULL DEFAULT '1', CHANGE `donorExpiry` `donorExpiry` INT(11) NULL DEFAULT '0', CHANGE `autoFriend` `autoFriend` VARCHAR(2) NULL DEFAULT 'AF' COMMENT 'NA/AF/AD', CHANGE `steamOwner` `steamOwner` BIGINT(17) NULL DEFAULT '0', CHANGE `bedX` `bedX` INT(11) NULL DEFAULT '0', CHANGE `bedY` `bedY` INT(11) NULL DEFAULT '0', CHANGE `bedZ` `bedZ` INT(11) NULL DEFAULT '0', CHANGE `mute` `mute` TINYINT(4) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `players` CHANGE `xPosOld2` `xPosOld2` INT(11) NULL DEFAULT '0', CHANGE `yPosOld2` `yPosOld2` INT(11) NULL DEFAULT '0', CHANGE `zPosOld2` `zPosOld2` INT(11) NULL DEFAULT '0', CHANGE `ignorePlayer` `ignorePlayer` TINYINT(1) NULL DEFAULT '0', CHANGE `ircMute` `ircMute` TINYINT(1) NULL DEFAULT '0', CHANGE `waypoint2X` `waypoint2X` INT(11) NULL DEFAULT '0', CHANGE `waypoint2Y` `waypoint2Y` INT(11) NULL DEFAULT '0', CHANGE `waypoint2Z` `waypoint2Z` INT(11) NULL DEFAULT '0', CHANGE `waypointsLinked` `waypointsLinked` TINYINT(1) NULL DEFAULT '0', CHANGE `chatColour` `chatColour` VARCHAR(6) NULL DEFAULT 'FFFFFF', CHANGE `teleCooldown` `teleCooldown` INT(11) NULL DEFAULT '0', CHANGE `reserveSlot` `reserveSlot` TINYINT(4) NULL DEFAULT '0', CHANGE `prisonReleaseTime` `prisonReleaseTime` INT(11) NULL DEFAULT '0', CHANGE `maxWaypoints` `maxWaypoints` INT(11) NULL DEFAULT '2', CHANGE `ircLogin` `ircLogin` VARCHAR(20) NULL DEFAULT '', CHANGE `waypointCooldown` `waypointCooldown` INT(11) NULL DEFAULT '0', CHANGE `bail` `bail` INT(11) NULL DEFAULT '0', CHANGE `watchPlayerTimer` `watchPlayerTimer` INT(11) NULL DEFAULT '0', CHANGE `hackerScore` `hackerScore` INT(11) NULL DEFAULT '0', CHANGE `pvpTeleportCooldown` `pvpTeleportCooldown` INT(11) NULL DEFAULT '0', CHANGE `block` `block` TINYINT(1) NULL DEFAULT '0', CHANGE `removedClaims` `removedClaims` INT(11) NULL DEFAULT '0', CHANGE `returnCooldown` `returnCooldown` INT(11) NULL DEFAULT '0', CHANGE `commandCooldown` `commandCooldown` INT(11) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `players` CHANGE `gimmeCooldown` `gimmeCooldown` INT(11) NULL DEFAULT '0', CHANGE `VACBanned` `VACBanned` TINYINT(1) NULL DEFAULT '0', CHANGE `bountyReason` `bountyReason` VARCHAR(100) NULL DEFAULT '', CHANGE `claimsExpired` `claimsExpired` TINYINT(1) NULL DEFAULT '0', CHANGE `showLocationMessages` `showLocationMessages` TINYINT(1) NULL DEFAULT '1', CHANGE `DNSLookupCount` `DNSLookupCount` INT(11) NULL DEFAULT '0', CHANGE `lastDNSLookup` `lastDNSLookup` DATE NULL DEFAULT '1000-01-01',  CHANGE `ircAuthenticated` `ircAuthenticated` TINYINT(1) NULL DEFAULT '0', CHANGE `p2pCooldown` `p2pCooldown` INT(11) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `players` CHANGE `location` `location` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '', DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci, CHANGE `aliases` `aliases` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL")

	doSQL("ALTER TABLE `playersArchived` CHANGE `name` `name` VARCHAR(100) NOT NULL DEFAULT ''")

	if (debug) then display("debug alterTables line " .. debugger.getinfo(1).currentline) end

	-- changes to server table
	doSQL("ALTER TABLE `server` ADD `teleportCost` INT NULL DEFAULT '200'")
	doSQL("ALTER TABLE `server` ADD `ircPrivate` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `waypointsPublic` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `waypointCost` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `waypointCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `waypointCreateCost` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `alertColour` VARCHAR(6) NULL DEFAULT 'DC143C'")
	doSQL("ALTER TABLE `server` ADD `warnColour` VARCHAR(6) NULL DEFAULT 'FFA500'")
	doSQL("ALTER TABLE `server` ADD `swearFine` INT NULL DEFAULT '5'")
	doSQL("ALTER TABLE `server` ADD `commandPrefix` VARCHAR(1) NULL DEFAULT '/'")
	doSQL("ALTER TABLE `server` ADD `chatlogPath` VARCHAR(200) NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` ADD `botVersion` VARCHAR(11) NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` ADD `packCost` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `baseCost` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `rebootHour` INT NULL DEFAULT '-1'")
	doSQL("ALTER TABLE `server` ADD `rebootMinute` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `maxPrisonTime` INT NULL DEFAULT '-1'")
	doSQL("ALTER TABLE `server` ADD `bailCost` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `maxWaypoints` INT NULL DEFAULT '2'")
	doSQL("ALTER TABLE `server` ADD `teleportPublicCost` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `teleportPublicCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `reservedSlots` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `allowReturns` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `scanNoclip` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `scanEntities` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `CBSMFriendly` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `scanErrors` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD disableTPinPVP TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `ServerToolsDetected` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `updateBot` INT(1) NULL DEFAULT '0' COMMENT '0 do not update, 1 stable branch, 2 testing branch'")
	doSQL("ALTER TABLE `server` ADD `alertSpending` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `GBLBanThreshold` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `lastBotsMessageID` INT NULL DEFAULT '0' , ADD `lastBotsMessageTimestamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP")
	doSQL("ALTER TABLE `server` ADD `gimmeZombies` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `allowProxies` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `SDXDetected` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `enableWindowMessages` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `updateBranch` VARCHAR(7) NULL DEFAULT 'stable'")
	doSQL("ALTER TABLE `server` ADD `chatColourNewPlayer` VARCHAR(6) NULL DEFAULT 'FFFFFF' , ADD `chatColourPlayer` VARCHAR(6) NULL DEFAULT 'FFFFFF' , ADD `chatColourDonor` VARCHAR(6) NULL DEFAULT 'FFFFFF' , ADD `chatColourPrisoner` VARCHAR(6) NULL DEFAULT 'FFFFFF' , ADD `chatColourMod` VARCHAR(6) NULL DEFAULT 'FFFFFF' , ADD `chatColourAdmin` VARCHAR(6) NULL DEFAULT 'FFFFFF' , ADD `chatColourOwner` VARCHAR(6) NULL DEFAULT 'FFFFFF'")
	doSQL("ALTER TABLE `server` ADD `commandCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `telnetPass` VARCHAR(50) NULL")
	doSQL("ALTER TABLE `server` ADD `telnetPort` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `feralRebootDelay` INT NULL DEFAULT '68'")
	doSQL("ALTER TABLE `server` ADD `pvpTeleportCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `allowPlayerToPlayerTeleporting` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `ircPort` INT NULL DEFAULT '6667'")
	doSQL("ALTER TABLE `server` ADD `botRestartHour` INT NULL DEFAULT '25'")
	doSQL("ALTER TABLE `server` ADD `trackingKeepDays` INT NULL DEFAULT '28' , ADD `databaseMaintenanceFinished` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `allowHomeTeleport` TINYINT(1) NULL DEFAULT '1' , ADD `playerTeleportDelay` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `allowPackTeleport` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `gameVersion` VARCHAR(30) NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` ADD `pvpIgnoreFriendlyKills` TINYINT(1) NULL DEFAULT '0', ADD `allowStuckTeleport` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `restrictIRC` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `nextAnnouncement` INT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `pvpAllowProtect` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `hackerTPDetection` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `whitelistCountries` VARCHAR(50) NULL DEFAULT '' , ADD `perMinutePayRate` INT NULL DEFAULT '0' , ADD `disableWatchAlerts` TINYINT(1) NULL DEFAULT '0' , ADD `masterPassword` VARCHAR(50) NULL DEFAULT '', ADD `allowBotRestarts` TINYINT(1) NULL DEFAULT '0', ADD `botOwner` VARCHAR(17) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `returnCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `botRestartDay` INT NULL DEFAULT '7'")
	doSQL("ALTER TABLE `server` ADD `enableTimedClaimScan` TINYINT(1) NULL DEFAULT '1', ADD `enableScreamerAlert` TINYINT(1) NULL DEFAULT '1' , ADD `enableAirdropAlert` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `spleefGameCoords` VARCHAR(20) NULL DEFAULT '4000 225 4000'") --todo add the game code
	doSQL("ALTER TABLE `server` ADD `gimmeResetTime` INT NULL DEFAULT '120', ADD `gimmeRaincheck` INT NULL DEFAULT '0'") -- gimmeRainCheck is a gimme cooldown timer between gimmes.
	doSQL("ALTER TABLE `server` ADD `pingKickTarget` VARCHAR(3) NULL DEFAULT 'new' , ADD `enableBounty` TINYINT(1) NULL DEFAULT '1', ADD `mapSizeNewPlayers` INT NULL DEFAULT '10000' , ADD `mapSizePlayers` INT NULL DEFAULT '10000', ADD `shopResetDays` INT NULL DEFAULT '3'")
	doSQL("ALTER TABLE `server` ADD `telnetLogKeepDays` INT NULL DEFAULT '14'")
	doSQL("ALTER TABLE `server` ADD `dailyRebootHour` int(11) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `maxWaypointsDonors` INT NULL DEFAULT '2'")
	doSQL("ALTER TABLE `server` ADD `baseProtectionExpiryDays` INT NULL DEFAULT '40'")
	doSQL("ALTER TABLE `server` ADD `banVACBannedPlayers` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `deathCost` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `showLocationMessages` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `bountyRewardItem` VARCHAR(25) NULL DEFAULT 'cash'")
	doSQL("ALTER TABLE `server` ADD `enableLagCheck` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `allowSecondBaseWithoutDonor` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `nonAlphabeticChatReaction` VARCHAR(10) NULL DEFAULT 'nothing'")
	doSQL("ALTER TABLE `server` ADD `lotteryTicketPrice` INT NULL DEFAULT '25'")
	doSQL("ALTER TABLE `server` ADD `newPlayerMaxLevel` INT NULL DEFAULT '9'")
	doSQL("ALTER TABLE `server` ADD `hordeNight` INT NULL DEFAULT '7'")
	doSQL("ALTER TABLE `server` ADD `hideUnknownCommand` TINYINT(1) NULL DEFAULT '0', ADD `beQuietBot` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `gimmeResetTimer` INT NULL DEFAULT '120', ADD `shopResetGameOrRealDays` TINYINT(1) NULL DEFAULT '0', ADD `zombieKillRewardDonors` FLOAT NULL DEFAULT '3'")
	doSQL("ALTER TABLE `server` ADD `allowFamilySteamKeys` TINYINT(1) NULL DEFAULT '1'") --todo: add commands and check for mismatched steam keys
	doSQL("ALTER TABLE `server` ADD `checkLevelHack` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `despawnZombiesBeforeBloodMoon` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `optOutGlobalBots` TINYINT(1) NULL DEFAULT '0'") -- todo code
	doSQL("ALTER TABLE `server` ADD `dropMiningWarningThreshold` INT NULL DEFAULT '99'")
	doSQL("ALTER TABLE `server` ADD `webPanelPort` INT NULL DEFAULT '8080'")
	doSQL("ALTER TABLE `server` ADD `allocsWebAPIUser` VARCHAR(100) NULL DEFAULT '', ADD `allocsWebAPIPassword` VARCHAR(100) NULL DEFAULT '', ADD `useAllocsWebAPI` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `defaultWatchTimer` INT NULL DEFAULT '259200'")
	doSQL("ALTER TABLE `server` ADD `archivePlayersLastSeenDays` INT NULL DEFAULT '60'")
	doSQL("ALTER TABLE `server` ADD `playersLastArchived` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP")
	doSQL("ALTER TABLE `server` ADD `alertLevelHack` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `server` ADD `logBotCommands` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `logInventory` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `removeExpiredClaims` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `baseDeadzone` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `reservedSlotTimelimit` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `logPollingInterval` INT NULL DEFAULT '3'")
	doSQL("ALTER TABLE `server` ADD `commandLagThreshold` INT NULL DEFAULT '15'")
	doSQL("ALTER TABLE `server` ADD `telnetDisabled` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `sayUsesIRCNick` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `readLogUsingTelnet` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `ircMainPassword` VARCHAR(30) NULL DEFAULT '', ADD `ircAlertsPassword` VARCHAR(30) NULL DEFAULT '', ADD `ircWatchPassword` VARCHAR(30) NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` ADD `chatColourPrivate` VARCHAR(6) NULL DEFAULT 'FFFFFF', ADD `botNameColour` VARCHAR(6) NULL DEFAULT 'FFFFFF'")
	doSQL("ALTER TABLE `server` ADD `disableFetch` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `p2pCooldown` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `telnetFallback` TINYINT(1) NULL DEFAULT '0' COMMENT 'Use telnet when API not working'")
	doSQL("ALTER TABLE `server` ADD `botsIP` VARCHAR(100) NULL DEFAULT '0.0.0.0'")

	doSQL("ALTER TABLE `server` CHANGE `shopCountdown` `shopCountdown` INT(11) NULL DEFAULT '0', CHANGE `gimmePeace` `gimmePeace` TINYINT(1) NULL DEFAULT '0', CHANGE `windowDebug` `windowDebug` VARCHAR(15) NULL DEFAULT 'Debug', CHANGE `ServerPort` `ServerPort` INT(11) NULL DEFAULT '0', CHANGE `windowAlerts` `windowAlerts` VARCHAR(15) NULL DEFAULT 'Alerts', CHANGE `allowGimme` `allowGimme` TINYINT(1) NULL DEFAULT '0', CHANGE `mapSize` `mapSize` INT(11) NULL DEFAULT '10000', CHANGE `ircAlerts` `ircAlerts` VARCHAR(50) NULL DEFAULT '#new_alerts', CHANGE `ircWatch` `ircWatch` VARCHAR(50) NULL DEFAULT '#new_watch', CHANGE `prisonSize` `prisonSize` INT(11) NULL DEFAULT '30', CHANGE `lottery` `lottery` FLOAT NULL DEFAULT '0', CHANGE `allowShop` `allowShop` TINYINT(1) NULL DEFAULT '0', CHANGE `windowGMSG` `windowGMSG` VARCHAR(15) NULL DEFAULT 'GMSG', CHANGE `botName` `botName` VARCHAR(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT 'Bot', CHANGE `allowWaypoints` `allowWaypoints` TINYINT(1) NULL DEFAULT '0', CHANGE `windowLists` `windowLists` VARCHAR(15) NULL DEFAULT 'Lists', CHANGE `ircMain` `ircMain` VARCHAR(50) NULL DEFAULT '#new', CHANGE `chatColour` `chatColour` VARCHAR(6) NULL DEFAULT 'D4FFD4', CHANGE `maxPlayers` `maxPlayers` INT(11) NULL DEFAULT '24', CHANGE `dailyRebootHour` `dailyRebootHour` INT(11) NULL DEFAULT '0', CHANGE `maxServerUptime` `maxServerUptime` INT(11) NULL DEFAULT '12', CHANGE `windowPlayers` `windowPlayers` VARCHAR(15) NULL DEFAULT 'Players', CHANGE `baseSize` `baseSize` INT(11) NULL DEFAULT '32', CHANGE `baseCooldown` `baseCooldown` INT(11) NULL DEFAULT '2400'")

	doSQL("ALTER TABLE `server` CHANGE `protectionMaxDays` `protectionMaxDays` INT(11) NULL DEFAULT '40', CHANGE `ircBotName` `ircBotName` VARCHAR(30) NULL DEFAULT 'Bot', CHANGE `serverName` `serverName` VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT 'New Server', CHANGE `lastDailyReboot` `lastDailyReboot` INT(11) NULL DEFAULT '0', CHANGE `allowNumericNames` `allowNumericNames` TINYINT(1) NULL DEFAULT '1', CHANGE `allowGarbageNames` `allowGarbageNames` TINYINT(1) NULL DEFAULT '1', CHANGE `allowReboot` `allowReboot` TINYINT(1) NULL DEFAULT '1', CHANGE `newPlayerTimer` `newPlayerTimer` INT(11) NULL DEFAULT '120', CHANGE `blacklistResponse` `blacklistResponse` VARCHAR(20) NULL DEFAULT 'ban', CHANGE `gameDay` `gameDay` INT(11) NULL DEFAULT '0', CHANGE `allowVoting` `allowVoting` TINYINT(1) NULL DEFAULT '0', CHANGE `allowPlayerVoteTopics` `allowPlayerVoteTopics` TINYINT(1) NULL DEFAULT '0', CHANGE `shopOpenHour` `shopOpenHour` INT(11) NULL DEFAULT '0', CHANGE `shopCloseHour` `shopCloseHour` INT(11) NULL DEFAULT '0', CHANGE `pingKick` `pingKick` INT(11) NULL DEFAULT '-1', CHANGE `longPlayUpgradeTime` `longPlayUpgradeTime` INT(11) NULL DEFAULT '0', CHANGE `gameType` `gameType` VARCHAR(3) NULL DEFAULT 'pve', CHANGE `hideCommands` `hideCommands` TINYINT(1) NULL DEFAULT '1', CHANGE `botTick` `botTick` INT(11) NULL DEFAULT '0', CHANGE `allowPhysics` `allowPhysics` TINYINT(1) NULL DEFAULT '1', CHANGE `playersCanFly` `playersCanFly` TINYINT(1) NULL DEFAULT '1', CHANGE `botID` `botID` INT(11) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `server` CHANGE `allowOverstacking` `allowOverstacking` TINYINT(1) NULL DEFAULT '0', CHANGE `announceTeleports` `announceTeleports` TINYINT(1) NULL DEFAULT '0', CHANGE `blacklistCountries` `blacklistCountries` VARCHAR(100) NULL DEFAULT 'CN', CHANGE `accessLevelOverride` `accessLevelOverride` INT(11) NULL DEFAULT '99', CHANGE `disableBaseProtection` `disableBaseProtection` TINYINT(1) NULL DEFAULT '0', CHANGE `packCooldown` `packCooldown` INT(11) NULL DEFAULT '0', CHANGE `moneyName` `moneyName` VARCHAR(60) NULL DEFAULT 'Zenny|Zennies', CHANGE `allowBank` `allowBank` TINYINT(1) NULL DEFAULT '1', CHANGE `overstackThreshold` `overstackThreshold` INT(11) NULL DEFAULT '1000', CHANGE `enableRegionPM` `enableRegionPM` TINYINT(1) NULL DEFAULT '1', CHANGE `allowRapidRelogging` `allowRapidRelogging` TINYINT(1) NULL DEFAULT '1', CHANGE `allowLottery` `allowLottery` TINYINT(1) NULL DEFAULT '1', CHANGE `lotteryMultiplier` `lotteryMultiplier` FLOAT NULL DEFAULT '2', CHANGE `zombieKillReward` `zombieKillReward` FLOAT NULL DEFAULT '3', CHANGE `ircTracker` `ircTracker` VARCHAR(50) NULL DEFAULT '#new_tracker', CHANGE `allowTeleporting` `allowTeleporting` TINYINT(1) NULL DEFAULT '1', CHANGE `hardcore` `hardcore` TINYINT(1) NULL DEFAULT '0', CHANGE `swearJar` `swearJar` TINYINT(1) NULL DEFAULT '0', CHANGE `swearCash` `swearCash` INT(11) NULL DEFAULT '0', CHANGE `idleKick` `idleKick` TINYINT(1) NULL DEFAULT '0', CHANGE `swearFine` `swearFine` INT(11) NULL DEFAULT '5', CHANGE `ircPrivate` `ircPrivate` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `server` CHANGE `waypointsPublic` `waypointsPublic` TINYINT(1) NULL DEFAULT '0', CHANGE `waypointCost` `waypointCost` INT(11) NULL DEFAULT '0', CHANGE `waypointCooldown` `waypointCooldown` INT(11) NULL DEFAULT '0', CHANGE `alertColour` `alertColour` VARCHAR(6) NULL DEFAULT 'DC143C', CHANGE `warnColour` `warnColour` VARCHAR(6) NULL DEFAULT 'FFA500', CHANGE `teleportCost` `teleportCost` INT(11) NULL DEFAULT '200', CHANGE `commandPrefix` `commandPrefix` VARCHAR(1) NULL DEFAULT '/', CHANGE `chatlogPath` `chatlogPath` VARCHAR(200) NULL DEFAULT '', CHANGE `botVersion` `botVersion` VARCHAR(20) NULL DEFAULT '', CHANGE `packCost` `packCost` INT(11) NULL DEFAULT '0', CHANGE `baseCost` `baseCost` INT(11) NULL DEFAULT '0', CHANGE `rebootHour` `rebootHour` INT(11) NULL DEFAULT '-1', CHANGE `rebootMinute` `rebootMinute` INT(11) NULL DEFAULT '0', CHANGE `maxPrisonTime` `maxPrisonTime` INT(11) NULL DEFAULT '-1', CHANGE `bailCost` `bailCost` INT(11) NULL DEFAULT '0', CHANGE `maxWaypoints` `maxWaypoints` INT(11) NULL DEFAULT '2', CHANGE `teleportPublicCost` `teleportPublicCost` INT(11) NULL DEFAULT '0', CHANGE `teleportPublicCooldown` `teleportPublicCooldown` INT(11) NULL DEFAULT '0', CHANGE `reservedSlots` `reservedSlots` INT(11) NULL DEFAULT '0', CHANGE `allowReturns` `allowReturns` TINYINT(1) NULL DEFAULT '1', CHANGE `scanNoclip` `scanNoclip` TINYINT(1) NULL DEFAULT '1', CHANGE `scanEntities` `scanEntities` TINYINT(1) NULL DEFAULT '0', CHANGE `CBSMFriendly` `CBSMFriendly` TINYINT(1) NULL DEFAULT '1'")

	doSQL("ALTER TABLE `server` CHANGE `ServerToolsDetected` `ServerToolsDetected` TINYINT(1) NULL DEFAULT '0', CHANGE `disableTPinPVP` `disableTPinPVP` TINYINT(1) NULL DEFAULT '0', CHANGE `updateBot` `updateBot` TINYINT(1) NULL DEFAULT '1', CHANGE `waypointCreateCost` `waypointCreateCost` INT(11) NULL DEFAULT '0', CHANGE `scanErrors` `scanErrors` TINYINT(1) NULL DEFAULT '0', CHANGE `alertSpending` `alertSpending` TINYINT(1) NULL DEFAULT '0', CHANGE `GBLBanThreshold` `GBLBanThreshold` INT(11) NULL DEFAULT '0', CHANGE `lastBotsMessageID` `lastBotsMessageID` INT(11) NULL DEFAULT '0', CHANGE `lastBotsMessageTimestamp` `lastBotsMessageTimestamp` INT(11) NULL DEFAULT '0', CHANGE `gimmeZombies` `gimmeZombies` TINYINT(1) NULL DEFAULT '1', CHANGE `allowProxies` `allowProxies` TINYINT(1) NULL DEFAULT '0', CHANGE `SDXDetected` `SDXDetected` TINYINT(1) NULL DEFAULT '0', CHANGE `enableWindowMessages` `enableWindowMessages` TINYINT(1) NULL DEFAULT '0', CHANGE `updateBranch` `updateBranch` VARCHAR(30) NULL DEFAULT 'a18', CHANGE `chatColourNewPlayer` `chatColourNewPlayer` VARCHAR(6) NULL DEFAULT 'FFFFFF', CHANGE `chatColourPlayer` `chatColourPlayer` VARCHAR(6) NULL DEFAULT 'FFFFFF', CHANGE `chatColourDonor` `chatColourDonor` VARCHAR(6) NULL DEFAULT 'FFFFFF', CHANGE `chatColourPrisoner` `chatColourPrisoner` VARCHAR(6) NULL DEFAULT 'FFFFFF', CHANGE `chatColourMod` `chatColourMod` VARCHAR(6) NULL DEFAULT 'FFFFFF', CHANGE `chatColourAdmin` `chatColourAdmin` VARCHAR(6) NULL DEFAULT 'FFFFFF', CHANGE `chatColourOwner` `chatColourOwner` VARCHAR(6) NULL DEFAULT 'FFFFFF'")

	doSQL("ALTER TABLE `server` CHANGE `commandCooldown` `commandCooldown` INT(11) NULL DEFAULT '0', CHANGE `telnetPass` `telnetPass` VARCHAR(50) NULL DEFAULT '', CHANGE `telnetPort` `telnetPort` INT(11) NULL DEFAULT '0', CHANGE `feralRebootDelay` `feralRebootDelay` INT(11) NULL DEFAULT '68', CHANGE `pvpTeleportCooldown` `pvpTeleportCooldown` INT(11) NULL DEFAULT '0', CHANGE `allowPlayerToPlayerTeleporting` `allowPlayerToPlayerTeleporting` TINYINT(1) NULL DEFAULT '1', CHANGE `ircPort` `ircPort` INT(11) NULL DEFAULT '6667', CHANGE `botRestartHour` `botRestartHour` INT(11) NULL DEFAULT '25', CHANGE `trackingKeepDays` `trackingKeepDays` INT(11) NULL DEFAULT '28', CHANGE `databaseMaintenanceFinished` `databaseMaintenanceFinished` TINYINT(1) NULL DEFAULT '1', CHANGE `allowHomeTeleport` `allowHomeTeleport` TINYINT(1) NULL DEFAULT '1', CHANGE `playerTeleportDelay` `playerTeleportDelay` INT(11) NULL DEFAULT '0', CHANGE `allowPackTeleport` `allowPackTeleport` TINYINT(1) NULL DEFAULT '1', CHANGE `gameVersion` `gameVersion` VARCHAR(30) NULL DEFAULT '', CHANGE `pvpIgnoreFriendlyKills` `pvpIgnoreFriendlyKills` TINYINT(1) NULL DEFAULT '0', CHANGE `allowStuckTeleport` `allowStuckTeleport` TINYINT(1) NULL DEFAULT '1', CHANGE `restrictIRC` `restrictIRC` TINYINT(1) NULL DEFAULT '0', CHANGE `nextAnnouncement` `nextAnnouncement` INT(11) NULL DEFAULT '1', CHANGE `pvpAllowProtect` `pvpAllowProtect` TINYINT(1) NULL DEFAULT '0', CHANGE `hackerTPDetection` `hackerTPDetection` TINYINT(1) NULL DEFAULT '1', CHANGE `whitelistCountries` `whitelistCountries` VARCHAR(50) NULL DEFAULT ''")

	doSQL("ALTER TABLE `server` CHANGE `perMinutePayRate` `perMinutePayRate` FLOAT NULL DEFAULT '0', CHANGE `disableWatchAlerts` `disableWatchAlerts` TINYINT(1) NULL DEFAULT '0', CHANGE `masterPassword` `masterPassword` VARCHAR(50) NULL DEFAULT '', CHANGE `allowBotRestarts` `allowBotRestarts` TINYINT(1) NULL DEFAULT '0', CHANGE `botOwner` `botOwner` VARCHAR(17) NULL DEFAULT '0', CHANGE `returnCooldown` `returnCooldown` INT(11) NULL DEFAULT '0', CHANGE `botRestartDay` `botRestartDay` INT(11) NULL DEFAULT '7', CHANGE `enableTimedClaimScan` `enableTimedClaimScan` TINYINT(1) NULL DEFAULT '1', CHANGE `enableScreamerAlert` `enableScreamerAlert` TINYINT(1) NULL DEFAULT '1', CHANGE `enableAirdropAlert` `enableAirdropAlert` TINYINT(1) NULL DEFAULT '1', CHANGE `spleefGameCoords` `spleefGameCoords` VARCHAR(20) NULL DEFAULT '4000 225 4000', CHANGE `gimmeResetTime` `gimmeResetTime` INT(11) NULL DEFAULT '120', CHANGE `gimmeRaincheck` `gimmeRaincheck` INT(11) NULL DEFAULT '0', CHANGE `pingKickTarget` `pingKickTarget` VARCHAR(3) NULL DEFAULT 'new', CHANGE `enableBounty` `enableBounty` TINYINT(1) NULL DEFAULT '1', CHANGE `mapSizeNewPlayers` `mapSizeNewPlayers` INT(11) NULL DEFAULT '10000', CHANGE `mapSizePlayers` `mapSizePlayers` INT(11) NULL DEFAULT '10000', CHANGE `shopResetDays` `shopResetDays` INT(11) NULL DEFAULT '3', CHANGE `telnetLogKeepDays` `telnetLogKeepDays` INT(11) NULL DEFAULT '14', CHANGE `maxWaypointsDonors` `maxWaypointsDonors` INT(11) NULL DEFAULT '2', CHANGE `baseProtectionExpiryDays` `baseProtectionExpiryDays` INT(11) NULL DEFAULT '40'")

	doSQL("ALTER TABLE `server` CHANGE `banVACBannedPlayers` `banVACBannedPlayers` TINYINT(1) NULL DEFAULT '0', CHANGE `deathCost` `deathCost` INT(11) NULL DEFAULT '0', CHANGE `showLocationMessages` `showLocationMessages` TINYINT(1) NULL DEFAULT '1', CHANGE `bountyRewardItem` `bountyRewardItem` VARCHAR(25) NULL DEFAULT 'cash', CHANGE `enableLagCheck` `enableLagCheck` TINYINT(1) NULL DEFAULT '1', CHANGE `allowSecondBaseWithoutDonor` `allowSecondBaseWithoutDonor` TINYINT(1) NULL DEFAULT '0', CHANGE `nonAlphabeticChatReaction` `nonAlphabeticChatReaction` VARCHAR(10) NULL DEFAULT 'nothing', CHANGE `lotteryTicketPrice` `lotteryTicketPrice` INT(11) NULL DEFAULT '25', CHANGE `newPlayerMaxLevel` `newPlayerMaxLevel` INT(11) NULL DEFAULT '9', CHANGE `hordeNight` `hordeNight` INT(11) NULL DEFAULT '7', CHANGE `hideUnknownCommand` `hideUnknownCommand` TINYINT(1) NULL DEFAULT '0', CHANGE `beQuietBot` `beQuietBot` TINYINT(1) NULL DEFAULT '0', CHANGE `gimmeResetTimer` `gimmeResetTimer` INT(11) NULL DEFAULT '120', CHANGE `shopResetGameOrRealDays` `shopResetGameOrRealDays` TINYINT(1) NULL DEFAULT '0', CHANGE `zombieKillRewardDonors` `zombieKillRewardDonors` FLOAT NULL DEFAULT '3', CHANGE `allowFamilySteamKeys` `allowFamilySteamKeys` TINYINT(1) NULL DEFAULT '1', CHANGE `checkLevelHack` `checkLevelHack` TINYINT(1) NULL DEFAULT '0', CHANGE `despawnZombiesBeforeBloodMoon` `despawnZombiesBeforeBloodMoon` TINYINT(1) NULL DEFAULT '0', CHANGE `optOutGlobalBots` `optOutGlobalBots` TINYINT(1) NULL DEFAULT '0', CHANGE `dropMiningWarningThreshold` `dropMiningWarningThreshold` INT(11) NULL DEFAULT '99'")

	doSQL("ALTER TABLE `server` CHANGE `webPanelPort` `webPanelPort` INT(11) NULL DEFAULT '0', CHANGE `allocsWebAPIUser` `allocsWebAPIUser` VARCHAR(100) NULL DEFAULT '', CHANGE `allocsWebAPIPassword` `allocsWebAPIPassword` VARCHAR(100) NULL DEFAULT '', CHANGE `useAllocsWebAPI` `useAllocsWebAPI` TINYINT(1) NULL DEFAULT '0', CHANGE `defaultWatchTimer` `defaultWatchTimer` INT(11) NULL DEFAULT '259200', CHANGE `archivePlayersLastSeenDays` `archivePlayersLastSeenDays` INT(11) NULL DEFAULT '60', CHANGE `playersLastArchived` `playersLastArchived` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, CHANGE `alertLevelHack` `alertLevelHack` TINYINT(1) NULL DEFAULT '1', CHANGE `logBotCommands` `logBotCommands` TINYINT(1) NULL DEFAULT '0', CHANGE `logInventory` `logInventory` TINYINT(1) NULL DEFAULT '1', CHANGE `removeExpiredClaims` `removeExpiredClaims` TINYINT(1) NULL DEFAULT '0', CHANGE `baseDeadzone` `baseDeadzone` INT(11) NULL DEFAULT '0', CHANGE `reservedSlotTimelimit` `reservedSlotTimelimit` INT(11) NULL DEFAULT '0', CHANGE `logPollingInterval` `logPollingInterval` INT(11) NULL DEFAULT '3', CHANGE `commandLagThreshold` `commandLagThreshold` INT(11) NULL DEFAULT '15', CHANGE `telnetDisabled` `telnetDisabled` TINYINT(1) NULL DEFAULT '0', CHANGE `sayUsesIRCNick` `sayUsesIRCNick` TINYINT(1) NULL DEFAULT '0', CHANGE `readLogUsingTelnet` `readLogUsingTelnet` TINYINT(1) NULL DEFAULT '0', CHANGE `ircMainPassword` `ircMainPassword` VARCHAR(30) NULL DEFAULT '', CHANGE `ircAlertsPassword` `ircAlertsPassword` VARCHAR(30) NULL DEFAULT ''")

	doSQL("ALTER TABLE `server` CHANGE `ircWatchPassword` `ircWatchPassword` VARCHAR(30) NULL DEFAULT '', CHANGE `chatColourPrivate` `chatColourPrivate` VARCHAR(6) NULL DEFAULT 'FFFFFF', CHANGE `botNameColour` `botNameColour` VARCHAR(6) NULL DEFAULT 'FFFFFF', CHANGE `disableFetch` `disableFetch` TINYINT(1) NULL DEFAULT '0', CHANGE `p2pCooldown` `p2pCooldown` INT(11) NULL DEFAULT '0', CHANGE `telnetFallback` `telnetFallback` TINYINT(1) NULL DEFAULT '0' COMMENT 'Use telnet when API not working', CHANGE `botsIP` `botsIP` VARCHAR(100) NULL DEFAULT '0.0.0.0'")

	doSQL("ALTER TABLE `server` CHANGE `rules` `rules` VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT 'A zombie ate the server rules! Tell an admin.', CHANGE `shopLocation` `shopLocation` VARCHAR(30) NULL DEFAULT '', CHANGE `blockCountries` `blacklistCountries` VARCHAR(100) NULL DEFAULT 'CN,HK', CHANGE `IP` `IP` VARCHAR(100) NULL DEFAULT '0.0.0.0', CHANGE `date` `date` VARCHAR(10) NULL DEFAULT '', CHANGE `welcome` `welcome` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '', CHANGE `MOTD` `MOTD` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '', CHANGE `website` `website` VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '', CHANGE `ircServer` `ircServer` VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '127.0.0.1', CHANGE `serverGroup` `serverGroup` VARCHAR(20) NULL DEFAULT ''")
	doSQL("ALTER TABLE `server` ADD `idleKickTimer` INT NULL DEFAULT '900', ADD `idleKickAnytime` TINYINT(1) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `server` ADD `newPlayerTimer` INT(11) NULL DEFAULT 120")
	doSQL("ALTER TABLE `server` ADD `newPlayerMaxLevel` INT(11) NULL DEFAULT 9")

	if (debug) then display("debug alterTables line " .. debugger.getinfo(1).currentline) end

	-- misc table changes

	-- new fields
	doSQL("ALTER TABLE `alerts` ADD `status` VARCHAR(30) NULL DEFAULT ''")

	doSQL("ALTER TABLE `badItems` ADD `validated` TINYINT(1) NULL DEFAULT '1'")

	doSQL("ALTER TABLE `bases` DROP PRIMARY KEY, ADD PRIMARY KEY(`steam`,`baseNumber`)")

	doSQL("ALTER TABLE `customCommands_Detail` DROP PRIMARY KEY , ADD PRIMARY KEY (`detailID`,`commandID`)")

	doSQL("ALTER TABLE `donors` ADD `name` VARCHAR(100) NULL DEFAULT ''")

	doSQL("ALTER TABLE `friends` ADD `autoAdded` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `gimmePrizes` ADD `quality` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `gimmePrizes` ADD `validated` TINYINT(1) NULL DEFAULT '1'")

	doSQL("ALTER TABLE `gimmeZombies` ADD `entityID` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `gimmeZombies` ADD `bossZombie` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `gimmeZombies` ADD `doNotSpawn` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `gimmeZombies` ADD `maxHealth` INT NULL DEFAULT '0'")

	doSQL("ALTER TABLE `hotspots` ADD `action` VARCHAR(10) NULL DEFAULT ''")
	doSQL("ALTER TABLE `hotspots` ADD `destination` VARCHAR(20) NULL DEFAULT ''")

	doSQL("ALTER TABLE `inventoryChanges` ADD `flag` VARCHAR(3) DEFAULT ''")

	doSQL("ALTER TABLE `IPBlacklist` ADD `DateAdded` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP , ADD `botID` INT NULL DEFAULT '0' , ADD `steam` BIGINT(17) NULL DEFAULT '0' , ADD `playerName` VARCHAR(25) NULL DEFAULT ''")
	doSQL("ALTER TABLE `IPBlacklist` ADD `Country` VARCHAR(2) DEFAULT ''")

	doSQL("ALTER TABLE `keystones` ADD `expired` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `list` ADD `steam` BIGINT(17) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `list` ADD `id` INT NULL DEFAULT '0' , ADD `class` VARCHAR(20) NULL DEFAULT ''")

	doSQL("ALTER TABLE `locations` ADD `timeOpen` INT NULL DEFAULT '0' , ADD `timeClosed` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `allowWaypoints` TINYINT(1) NULL DEFAULT '1' , ADD `allowReturns` TINYINT(1) NULL DEFAULT '1', ADD `allowLeave` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `locations` ADD `newPlayersOnly` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `minimumLevel` INT NULL DEFAULT '0', ADD `maximumLevel` INT NULL DEFAULT '0', ADD `dayClosed` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `dailyTaxRate` INT NULL DEFAULT '0', ADD `bank` INT NULL DEFAULT '0', ADD `prisonX` INT NULL DEFAULT '0' , ADD `prisonY` INT NULL DEFAULT '0' , ADD `prisonZ` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `hidden` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `locationCategory` VARCHAR(20) NULL DEFAULT ''")
	doSQL("ALTER TABLE `locations` ADD `coolDownTimer` INT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `plot` TINYINT(1) NULL DEFAULT '0', ADD `plotWallBock` VARCHAR(20) NULL DEFAULT 'bedrock', ADD `plotFillBlock` VARCHAR(20) NULL DEFAULT 'dirt', ADD `plotGridSize` INT NULL DEFAULT '0', ADD `plotDepth` INT NULL DEFAULT '5', ADD `hordeNightClosedHours` VARCHAR(5) NULL DEFAULT '00-00'")
	doSQL("ALTER TABLE `locations` ADD `watchPlayers` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `isRound` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `locations` ADD `lobby` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locations` ADD `height` INT NULL DEFAULT '-1'")
	doSQL("ALTER TABLE `locations` ADD `allowPack` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `locations` ADD `allowP2P` TINYINT(1) NULL DEFAULT '1'")

	doSQL("ALTER TABLE `memShop` ADD `units` INT NULL DEFAULT '1'")
	doSQL("ALTER TABLE `memShop` ADD `quality` INT NULL DEFAULT '0'")

	doSQL("ALTER TABLE `miscQueue` ADD `timerDelay` TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00'")

	doSQL("ALTER TABLE `otherEntities` ADD `doNotDespawn` TINYINT(1) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `otherEntities` ADD `remove` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `playerQueue` ADD `delayTimer` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP")

	doSQL("ALTER TABLE `restrictedItems` ADD `validated` TINYINT(1) NULL DEFAULT '1'")

	doSQL("ALTER TABLE `shop` ADD `validated` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `shop` ADD `units` INT(1) NULL, ADD `quality` INT(0) NULL")

	doSQL("ALTER TABLE `spawnableItems` ADD `craftable` TINYINT(1) NULL DEFAULT '1' , ADD `devBlock` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `teleports` ADD `size` FLOAT(11) NULL DEFAULT '1.5' COMMENT 'size of start tp' , ADD `dsize` FLOAT(11) NULL DEFAULT '1.5' COMMENT 'size of dest tp'")
	doSQL("ALTER TABLE `teleports` ADD `minimumAccess` INT NULL DEFAULT '0', ADD `maximumAccess` INT NULL DEFAULT '0'")

	doSQL("ALTER TABLE `waypoints` ADD `public` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `webInterfaceQueue` ADD `steam` BIGINT(17) NULL DEFAULT '0', ADD `actionArgs` VARCHAR(1000) NULL DEFAULT '', CHANGE `action` `action` VARCHAR(50), ADD `recipient` VARCHAR(5) NULL DEFAULT '', ADD `expire` TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00', ADD `sessionID` VARCHAR(32) NULL DEFAULT ''")

	doSQL("ALTER TABLE `webInterfaceJSON` ADD `recipient` varchar(5) NULL DEFAULT '', ADD `expire` timestamp NULL DEFAULT '0000-00-00 00:00:00'")

	doSQL("ALTER TABLE `modBotman` ADD `resetsEnabled` TINYINT(1) NULL DEFAULT '0', ADD `resetsDelay` INT NULL DEFAULT '999', ADD `resetsPrefabsOnly` TINYINT(1) NULL DEFAULT '1', ADD `resetsRemoveLCB` TINYINT NULL DEFAULT '1'")

	doSQL("ALTER TABLE `resetZones` ADD `x` INT NULL DEFAULT '0', ADD `z` INT NULL DEFAULT '0'")


	-- fix zero default tp sizes
	doSQL("UPDATE `teleports` SET size = 1.5 WHERE size = 0")
	doSQL("UPDATE `teleports` SET dsize = 1.5 WHERE dsize = 0")

	-- misc field changes
	doSQL("ALTER TABLE `badItems` CHANGE `action` `action` VARCHAR(10) NULL DEFAULT 'timeout', CHANGE `validated` `validated` TINYINT(1) NULL DEFAULT '1'")
	doSQL("ALTER TABLE `badItems` CHANGE `item` `item` VARCHAR(100) NOT NULL DEFAULT ''")

	doSQL("ALTER TABLE `badWords` CHANGE `badWord` `badWord` VARCHAR(100) NULL DEFAULT '', CHANGE `cost` `cost` INT(11) NULL DEFAULT '10', CHANGE `counter` `counter` INT(11) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `bans` CHANGE `BannedTo` `BannedTo` VARCHAR(22) NULL DEFAULT '', CHANGE `Reason` `Reason` VARCHAR(255) NULL DEFAULT '', CHANGE `expiryDate` `expiryDate` DATETIME NULL, CHANGE `Steam` `Steam` BIGINT(17) NOT NULL DEFAULT '0'")

	doSQL("ALTER TABLE `bases` CHANGE `title` `title` VARCHAR(100) NULL DEFAULT '', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `exitX` `exitX` INT(11) NULL DEFAULT '0', CHANGE `exitY` `exitY` INT(11) NULL DEFAULT '0', CHANGE `exitZ` `exitZ` INT(11) NULL DEFAULT '0', CHANGE `size` `size` INT(11) NULL DEFAULT '0', CHANGE `protect` `protect` TINYINT(1) NULL DEFAULT '0', CHANGE `keepOut` `keepOut` TINYINT(1) NULL DEFAULT '0', CHANGE `creationTimestamp` `creationTimestamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, CHANGE `creationGameDay` `creationGameDay` INT(11) NULL DEFAULT '0', CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0'")

	doSQL("ALTER TABLE `commandAccessRestrictions` CHANGE `functionName` `functionName` VARCHAR(100) NULL DEFAULT '', CHANGE `accessLevel` `accessLevel` INT(11) NULL DEFAULT '3'")

	doSQL("ALTER TABLE `customCommands` CHANGE `command` `command` VARCHAR(50) NULL DEFAULT '', CHANGE `accessLevel` `accessLevel` INT(11) NULL DEFAULT '2', CHANGE `help` `help` VARCHAR(255) NULL DEFAULT ''")

	doSQL("ALTER TABLE `customCommands_Detail` CHANGE `action` `action` VARCHAR(5) NULL DEFAULT '' COMMENT 'say,give,tele,spawn,buff,cmd', CHANGE `thing` `thing` VARCHAR(255) NULL DEFAULT '', CHANGE `commandID` `commandID` INT(11) NOT NULL DEFAULT '0'")

	doSQL("ALTER TABLE `customMessages` CHANGE `message` `message` VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '', CHANGE `accessLevel` `accessLevel` INT(11) NULL DEFAULT '99', CHANGE `command` `command` VARCHAR(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT ''")

	doSQL("ALTER TABLE `donors` CHANGE `level` `level` INT(11) NULL DEFAULT '0', CHANGE `name` `name` VARCHAR(100) NULL DEFAULT '', CHANGE `expiry` `expiry` INT(11) NULL DEFAULT NULL, CHANGE `steam` `steam` BIGINT(17) NOT NULL")

	doSQL("ALTER TABLE `friends` CHANGE `autoAdded` `autoAdded` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `gimmePrizes` CHANGE `category` `category` VARCHAR(15) NULL DEFAULT '', CHANGE `prizeLimit` `prizeLimit` INT(11) NULL DEFAULT '1', CHANGE `quality` `quality` INT(11) NULL DEFAULT '0', CHANGE `validated` `validated` TINYINT(1) NULL DEFAULT '1', CHANGE `name` `name` VARCHAR(100) NOT NULL DEFAULT ''")

	doSQL("ALTER TABLE `gimmeZombies` CHANGE `zombie` `zombie` VARCHAR(50) NULL DEFAULT '', CHANGE `minPlayerLevel` `minPlayerLevel` INT(11) NULL DEFAULT '1', CHANGE `minArenaLevel` `minArenaLevel` INT(11) NULL DEFAULT '1', CHANGE `bossZombie` `bossZombie` TINYINT(1) NULL DEFAULT '0', CHANGE `doNotSpawn` `doNotSpawn` TINYINT(1) NULL DEFAULT '0', CHANGE `maxHealth` `maxHealth` INT(11) NULL DEFAULT '0', CHANGE `remove` `remove` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `hotspots` CHANGE `hotspot` `hotspot` VARCHAR(500) NULL DEFAULT '', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `size` `size` INT(11) NULL DEFAULT '2', CHANGE `owner` `owner` BIGINT(17) NULL DEFAULT '0', CHANGE `idx` `idx` INT(11) NULL DEFAULT '0', CHANGE `action` `action` VARCHAR(10) NULL DEFAULT '', CHANGE `destination` `destination` VARCHAR(20) NULL DEFAULT ''")

	doSQL("ALTER TABLE `locationCategories` CHANGE `minAccessLevel` `minAccessLevel` INT(11) NULL DEFAULT '99', CHANGE `maxAccessLevel` `maxAccessLevel` INT(11) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `locations` CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `public` `public` TINYINT(1) NULL DEFAULT '0', CHANGE `active` `active` TINYINT(1) NULL DEFAULT '1', CHANGE `owner` `owner` BIGINT(17) NULL DEFAULT '0', CHANGE `village` `village` TINYINT(1) NULL DEFAULT '0', CHANGE `pvp` `pvp` TINYINT(1) NULL DEFAULT '0', CHANGE `protectSize` `protectSize` INT(11) NULL DEFAULT '50', CHANGE `exitX` `exitX` INT(11) NULL DEFAULT '0', CHANGE `exitY` `exitY` INT(11) NULL DEFAULT '0', CHANGE `exitZ` `exitZ` INT(11) NULL DEFAULT '0', CHANGE `cost` `cost` INT(11) NULL DEFAULT '0', CHANGE `allowBase` `allowBase` TINYINT(1) NULL DEFAULT '0', CHANGE `protected` `protected` TINYINT(1) NULL DEFAULT '0', CHANGE `accessLevel` `accessLevel` INT(11) NULL DEFAULT '99', CHANGE `size` `size` INT(11) NULL DEFAULT '20', CHANGE `mayor` `mayor` BIGINT(17) NULL DEFAULT '0', CHANGE `resetZone` `resetZone` TINYINT(1) NULL DEFAULT '0', CHANGE `killZombies` `killZombies` TINYINT(1) NULL DEFAULT '0', CHANGE `timeOpen` `timeOpen` INT(11) NULL DEFAULT '0', CHANGE `timeClosed` `timeClosed` INT(11) NULL DEFAULT '0', CHANGE `allowWaypoints` `allowWaypoints` TINYINT(1) NULL DEFAULT '1', CHANGE `allowReturns` `allowReturns` TINYINT(1) NULL DEFAULT '1', CHANGE `currency` `currency` VARCHAR(20) NULL DEFAULT NULL, CHANGE `name` `name` VARCHAR(50), CHANGE `allowLeave` `allowLeave` TINYINT(1) NULL DEFAULT '1'")

	doSQL("ALTER TABLE `locations` CHANGE `newPlayersOnly` `newPlayersOnly` TINYINT(1) NULL DEFAULT '0', CHANGE `minimumLevel` `minimumLevel` INT(11) NULL DEFAULT '0', CHANGE `maximumLevel` `maximumLevel` INT(11) NULL DEFAULT '0', CHANGE `dayClosed` `dayClosed` INT(11) NULL DEFAULT '0', CHANGE `dailyTaxRate` `dailyTaxRate` INT(11) NULL DEFAULT '0', CHANGE `bank` `bank` INT(11) NULL DEFAULT '0', CHANGE `prisonX` `prisonX` INT(11) NULL DEFAULT '0', CHANGE `prisonY` `prisonY` INT(11) NULL DEFAULT '0', CHANGE `prisonZ` `prisonZ` INT(11) NULL DEFAULT '0', CHANGE `hidden` `hidden` TINYINT(1) NULL DEFAULT '0', CHANGE `locationCategory` `locationCategory` VARCHAR(20) NULL DEFAULT '', CHANGE `coolDownTimer` `coolDownTimer` INT(11) NULL DEFAULT '0', CHANGE `plot` `plot` TINYINT(1) NULL DEFAULT '0', CHANGE `plotWallBock` `plotWallBock` VARCHAR(20) NULL DEFAULT 'terrBedrock', CHANGE `plotFillBlock` `plotFillBlock` VARCHAR(20) NULL DEFAULT 'terrDirt', CHANGE `plotGridSize` `plotGridSize` INT(11) NULL DEFAULT '0', CHANGE `plotDepth` `plotDepth` INT(11) NULL DEFAULT '5', CHANGE `hordeNightClosedHours` `hordeNightClosedHours` VARCHAR(5) NULL DEFAULT '00-00', CHANGE `watchPlayers` `watchPlayers` TINYINT(1) NULL DEFAULT '0', CHANGE `isRound` `isRound` TINYINT(1) NULL DEFAULT '1', CHANGE `lobby` `lobby` TINYINT(1) NULL DEFAULT '0', CHANGE `height` `height` INT(11) NULL DEFAULT '-1', CHANGE `allowPack` `allowPack` TINYINT(1) NULL DEFAULT '1', CHANGE `allowP2P` `allowP2P` TINYINT(1) NULL DEFAULT '1'")

	doSQL("ALTER TABLE `modBotman` CHANGE `clanEnabled` `clanEnabled` TINYINT(1) NULL DEFAULT '0', CHANGE `clanMaxClans` `clanMaxClans` INT(11) NULL DEFAULT '0', CHANGE `clanMaxPlayers` `clanMaxPlayers` INT(11) NULL DEFAULT '0', CHANGE `clanMinLevel` `clanMinLevel` INT(11) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `otherEntities` CHANGE `entityID` `entityID` INT(11) NULL DEFAULT '0', CHANGE `doNotSpawn` `doNotSpawn` TINYINT(1) NULL DEFAULT '0', CHANGE `doNotDespawn` `doNotDespawn` TINYINT(1) NULL DEFAULT '0', CHANGE `remove` `remove` TINYINT(1) NULL DEFAULT '0', CHANGE `entity` `entity` VARCHAR(50) NOT NULL DEFAULT ''")

	doSQL("ALTER TABLE `reservedSlots` CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0', CHANGE `timeAdded` `timeAdded` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, CHANGE `reserved` `reserved` TINYINT(1) NULL DEFAULT '0', CHANGE `staff` `staff` TINYINT(1) NULL DEFAULT '0', CHANGE `totalPlayTime` `totalPlayTime` INT(11) NULL DEFAULT '0', CHANGE `deleteRow` `deleteRow` TINYINT(1) NULL DEFAULT '0', ENGINE = MEMORY")

	doSQL("ALTER TABLE `restrictedItems` CHANGE `qty` `qty` INT(11) NULL DEFAULT '65', CHANGE `accessLevel` `accessLevel` INT(11) NULL DEFAULT '90', CHANGE `action` `action` VARCHAR(30) NULL DEFAULT '', CHANGE `validated` `validated` TINYINT(1) NULL DEFAULT '1'")

	doSQL("ALTER TABLE `shop` CHANGE `item` `item` VARCHAR(100) NOT NULL DEFAULT '', CHANGE `category` `category` VARCHAR(20) NULL DEFAULT 'misc', CHANGE `price` `price` INT(11) NULL DEFAULT '50', CHANGE `stock` `stock` INT(11) NULL DEFAULT '50', CHANGE `idx` `idx` INT(11) NULL DEFAULT '0', CHANGE `maxStock` `maxStock` INT(11) NULL DEFAULT '50', CHANGE `variation` `variation` INT(11) NULL DEFAULT '0', CHANGE `special` `special` INT(11) NULL DEFAULT '0', CHANGE `validated` `validated` TINYINT(1) NULL DEFAULT '1', CHANGE `units` `units` INT(11) NULL DEFAULT '1', CHANGE `quality` `quality` INT(11) NULL DEFAULT '3'")

	doSQL("ALTER TABLE `shopCategories` CHANGE `category` `category` VARCHAR(20) NOT NULL DEFAULT '', CHANGE `idx` `idx` INT(11) NULL DEFAULT '0', CHANGE `code` `code` VARCHAR(3) NULL DEFAULT ''")

	doSQL("ALTER TABLE `slots` CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `online` `online` TINYINT(1) NULL DEFAULT '0', CHANGE `joinedTime` `joinedTime` TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00', CHANGE `joinedSession` `joinedSession` INT(11) NULL DEFAULT '0', CHANGE `expires` `expires` TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00', CHANGE `reserved` `reserved` TINYINT(1) NULL DEFAULT '0', CHANGE `staff` `staff` TINYINT(1) NULL DEFAULT '0', CHANGE `free` `free` TINYINT(1) NULL DEFAULT '1', CHANGE `canBeKicked` `canBeKicked` TINYINT(1) NULL DEFAULT '1', CHANGE `disconnectedTimestamp` `disconnectedTimestamp` TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00'")

	doSQL("ALTER TABLE `spawnableItems` CHANGE `itemName` `itemName` VARCHAR(100) NOT NULL DEFAULT '', CHANGE `deleteItem` `deleteItem` TINYINT(1) NULL DEFAULT '0', CHANGE `accessLevelRestriction` `accessLevelRestriction` INT(11) NULL DEFAULT '99', CHANGE `category` `category` VARCHAR(20) NULL DEFAULT 'None', CHANGE `price` `price` INT(11) NULL DEFAULT '10000', CHANGE `stock` `stock` INT(11) NULL DEFAULT '5000', CHANGE `idx` `idx` INT(11) NULL DEFAULT '0', CHANGE `maxStock` `maxStock` INT(11) NULL DEFAULT '5000', CHANGE `inventoryResponse` `inventoryResponse` VARCHAR(10) NULL DEFAULT 'none', CHANGE `StackLimit` `StackLimit` INT(11) NULL DEFAULT '1000', CHANGE `newPlayerMaxInventory` `newPlayerMaxInventory` INT(11) NULL DEFAULT '-1', CHANGE `units` `units` INT(11) NULL DEFAULT '1', CHANGE `craftable` `craftable` TINYINT(1) NULL DEFAULT '1', CHANGE `devBlock` `devBlock` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `staff` CHANGE `adminLevel` `adminLevel` INT(11) NULL DEFAULT '2', CHANGE `blockDelete` `blockDelete` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `teleports` CHANGE `name` `name` VARCHAR(100), CHANGE `active` `active` TINYINT(1) NULL DEFAULT '1', CHANGE `owner` `owner` BIGINT(17) NULL DEFAULT '0', CHANGE `oneway` `oneway` TINYINT(1) NULL DEFAULT '0', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `dx` `dx` INT(11) NULL DEFAULT '0', CHANGE `dy` `dy` INT(11) NULL DEFAULT '0', CHANGE `dz` `dz` INT(11) NULL DEFAULT '0', CHANGE `friends` `friends` TINYINT(1) NULL DEFAULT '0', CHANGE `public` `public` TINYINT(1) NULL DEFAULT '0', CHANGE `size` `size` FLOAT NULL DEFAULT '1.5' COMMENT 'size of start tp', CHANGE `dsize` `dsize` FLOAT NULL DEFAULT '1.5' COMMENT 'size of dest tp', CHANGE `minimumAccess` `minimumAccess` INT(11) NULL DEFAULT '0', CHANGE `maximumAccess` `maximumAccess` INT(11) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `waypoints` CHANGE `name` `name` VARCHAR(50), CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `linked` `linked` INT(11) NULL DEFAULT '0', CHANGE `shared` `shared` TINYINT(1) NULL DEFAULT '0', CHANGE `public` `public` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `webInterfaceJSON` CHANGE `ident` `ident` VARCHAR(50) NOT NULL DEFAULT '', CHANGE `json` `json` TEXT NULL, CHANGE `sessionID` `sessionID` VARCHAR(32) NULL DEFAULT '', CHANGE `recipient` `recipient` VARCHAR(5) NULL DEFAULT '', CHANGE `expire` `expire` TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00'")

	doSQL("ALTER TABLE `webInterfaceQueue` CHANGE `actionTable` `actionTable` VARCHAR(50) NULL DEFAULT '', CHANGE `action` `action` VARCHAR(50) NULL DEFAULT '', CHANGE `actionQuery` `actionQuery` TEXT NULL DEFAULT '', CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `actionArgs` `actionArgs` VARCHAR(1000) NULL DEFAULT '', CHANGE `recipient` `recipient` VARCHAR(5) NULL DEFAULT '', CHANGE `expire` `expire` TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00', CHANGE `sessionID` `sessionID` VARCHAR(32) NULL DEFAULT ''")

	doSQL("ALTER TABLE `miscQueue` CHANGE `command` `command` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '', CHANGE `id` `id` BIGINT(20) NOT NULL AUTO_INCREMENT, CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `action` `action` VARCHAR(15) NULL DEFAULT '', CHANGE `value` `value` INT(11) NULL DEFAULT '0', CHANGE `timerDelay` `timerDelay` TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00'")

	doSQL("ALTER TABLE `botChat` MODIFY `botChatID` int(11) NOT NULL AUTO_INCREMENT")

	doSQL("ALTER TABLE `botChatResponses` MODIFY `botChatResponseID` int(11) NOT NULL AUTO_INCREMENT")

	doSQL("ALTER TABLE `memShop` CHANGE `item` `item` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL, CHANGE `code` `code` VARCHAR(10) NULL DEFAULT '', CHANGE `category` `category` VARCHAR(20) NULL DEFAULT '', CHANGE `price` `price` INT(11) NULL DEFAULT '50', CHANGE `stock` `stock` INT(11) NULL DEFAULT '50', CHANGE `idx` `idx` INT(11) NULL DEFAULT '0', CHANGE `units` `units` INT(11) NULL DEFAULT '1', CHANGE `quality` `quality` INT(11) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `events` CHANGE `event` `event` VARCHAR(255) NULL DEFAULT '', CHANGE `type` `type` VARCHAR(15) NULL DEFAULT '', CHANGE `serverTime` `serverTime` VARCHAR(19) NULL DEFAULT '', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `timestamp` `timestamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP")

	doSQL("ALTER TABLE `lottery` CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `memLottery` CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0'")

	doSQL("ALTER TABLE `playerNotes` CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `createdBy` `createdBy` BIGINT(17) NULL DEFAULT '0', CHANGE `note` `note` VARCHAR(400) NULL DEFAULT ''")

	doSQL("ALTER TABLE `whitelist` CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0'")
	doSQL("ALTER TABLE `memEntities` ENGINE = MEMORY")

	doSQL("ALTER TABLE `helpTopics` CHANGE `description` `description` TEXT NULL DEFAULT '', CHANGE `topic` `topic` VARCHAR(50) NULL DEFAULT ''")

	doSQL("ALTER TABLE `helpCommands` CHANGE `command` `command` TEXT NULL DEFAULT '', CHANGE `description` `description` TEXT NULL DEFAULT '', CHANGE `keywords` `keywords` VARCHAR(150) NULL DEFAULT '', CHANGE `notes` `notes` TEXT NULL DEFAULT '', CHANGE `lastUpdate` `lastUpdate` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, CHANGE `accessLevel` `accessLevel` INT(11) NULL DEFAULT '99', CHANGE `ingameOnly` `ingameOnly` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `keystones` CHANGE `removed` `removed` INT(11) NULL DEFAULT '0'")
	doSQL("UPDATE `keystones` SET removed = 0") -- this is necessary to stop the bot giving everyone claims in error due to a table change.

	doSQL("ALTER TABLE `LKPQueue` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT") -- to fix missing auto increment for some bots that helped with testing

	doSQL("ALTER TABLE `polls` CHANGE `topic` `topic` VARCHAR(255) NULL DEFAULT '', CHANGE `option1` `option1` VARCHAR(255) NULL DEFAULT '', CHANGE `option2` `option2` VARCHAR(255) NULL DEFAULT '', CHANGE `option3` `option3` VARCHAR(255) NULL DEFAULT '', CHANGE `option4` `option4` VARCHAR(255) NULL DEFAULT '', CHANGE `option5` `option5` VARCHAR(255) NULL DEFAULT '', CHANGE `option6` `option6` VARCHAR(255) NULL DEFAULT '', CHANGE `author` `author` BIGINT(17) NULL DEFAULT '0', CHANGE `created` `created` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, CHANGE `expires` `expires` TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00', CHANGE `responseYN` `responseYN` TINYINT(1) NULL DEFAULT '1', CHANGE `accessLevel` `accessLevel` INT(11) NULL DEFAULT '90'")

	doSQL("ALTER TABLE `pollVotes` CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `vote` `vote` INT(11) NULL DEFAULT '0', CHANGE `weight` `weight` FLOAT NULL DEFAULT '1'")

	doSQL("UPDATE server SET logInventory = 1")

	doSQL("ALTER TABLE `inventoryTracker` CHANGE `pack` `pack` VARCHAR(1100) NULL DEFAULT '', CHANGE `belt` `belt` VARCHAR(500) NULL DEFAULT '', CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `session` `session` INT(11) NULL DEFAULT '0', CHANGE `timestamp` `timestamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP")

	doSQL("ALTER TABLE `performance` CHANGE `serverDate` `serverDate` VARCHAR(19) NOT NULL DEFAULT '', CHANGE `gameTime` `gameTime` FLOAT NULL DEFAULT '0', CHANGE `fps` `fps` FLOAT NULL DEFAULT '0', CHANGE `heap` `heap` FLOAT NULL DEFAULT '0', CHANGE `heapMax` `heapMax` FLOAT NULL DEFAULT '0', CHANGE `chunks` `chunks` INT(11) NULL DEFAULT '0', CHANGE `cgo` `cgo` INT(11) NULL DEFAULT '0', CHANGE `players` `players` INT(11) NULL DEFAULT '0', CHANGE `zombies` `zombies` INT(11) NULL DEFAULT '0', CHANGE `entities` `entities` VARCHAR(12) NULL DEFAULT '', CHANGE `items` `items` INT(11) NULL DEFAULT '0', CHANGE `timestamp` `timestamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP")

	doSQL("ALTER TABLE `alerts` CHANGE `message` `message` VARCHAR(255) NULL DEFAULT '', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `connectQueue` CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `command` `command` VARCHAR(255) NULL DEFAULT '', CHANGE `processed` `processed` TINYINT(1) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `persistentQueue` CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `action` `action` VARCHAR(15) NULL DEFAULT '', CHANGE `command` `command` VARCHAR(255) NULL DEFAULT '', CHANGE `value` `value` INT(11) NULL DEFAULT '0', CHANGE `timerDelay` `timerDelay` TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00'")

	doSQL("ALTER TABLE `commandQueue` CHANGE `command` `command` VARCHAR(100) NULL DEFAULT '', CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `ircQueue` CHANGE `command` `command` VARCHAR(255) NULL DEFAULT '', CHANGE `name` `name` VARCHAR(20) NULL DEFAULT ''")

	doSQL("ALTER TABLE `APIQueue` CHANGE `URL` `URL` VARCHAR(500) NULL DEFAULT '', CHANGE `OutputFile` `OutputFile` VARCHAR(500) NULL DEFAULT ''")

	doSQL("ALTER TABLE `searchResults` CHANGE `owner` `owner` BIGINT(17) NULL DEFAULT '0', CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `counter` `counter` INT(11) NULL DEFAULT '0', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `session` `session` INT(11) NULL DEFAULT '0', CHANGE `date` `date` VARCHAR(20) NULL DEFAULT ''")

	doSQL("ALTER TABLE `announcements` CHANGE `endDate` `endDate` DATE NULL, CHANGE `message` `message` VARCHAR(400) NULL DEFAULT ''")

	doSQL("ALTER TABLE `botCommands` CHANGE `cmdIndex` `cmdIndex` INT(11) NULL DEFAULT '0', CHANGE `accessLevel` `accessLevel` INT(11) NULL DEFAULT '0', CHANGE `enabled` `enabled` TINYINT(1) NULL DEFAULT '1', CHANGE `keywords` `keywords` VARCHAR(150) NULL DEFAULT '', CHANGE `shortDescription` `shortDescription` VARCHAR(255) NULL DEFAULT '', CHANGE `longDescription` `longDescription` VARCHAR(1000) NULL DEFAULT '', CHANGE `sortOrder` `sortOrder` INT(11) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `gimmeQueue` CHANGE `command` `command` VARCHAR(255) NULL DEFAULT '', CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `IPBlacklist` CHANGE `EndIP` `EndIP` BIGINT(15) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `memRestrictedItems` CHANGE `item` `item` VARCHAR(50) NULL DEFAULT '', CHANGE `action` `action` VARCHAR(30) NULL DEFAULT '', CHANGE `qty` `qty` INT(11) NULL DEFAULT '65', CHANGE `accessLevel` `accessLevel` INT(11) NULL DEFAULT '90'")

	doSQL("ALTER TABLE `messageQueue` CHANGE `message` `message` VARCHAR(1000) NULL DEFAULT '', CHANGE `sender` `sender` BIGINT(17) NULL DEFAULT '0', CHANGE `recipient` `recipient` BIGINT(17) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `playerQueue` CHANGE `command` `command` VARCHAR(255) NULL DEFAULT '', CHANGE `arena` `arena` TINYINT(1) NULL DEFAULT '0', CHANGE `boss` `boss` TINYINT(1) NULL DEFAULT '0', CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `delayTimer` `delayTimer` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP")

	doSQL("ALTER TABLE `villagers` CHANGE `steam` `steam` BIGINT(17) NOT NULL DEFAULT '0', CHANGE `village` `village` VARCHAR(20) NOT NULL DEFAULT ''")

	doSQL("ALTER TABLE `tracker` CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `timestamp` `timestamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP")

	doSQL("ALTER TABLE `memTracker` CHANGE `admin` `admin` BIGINT(17) NULL DEFAULT '0', CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `timestamp` `timestamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP")

	doSQL("ALTER TABLE `list` CHANGE `thing` `thing` VARCHAR(255) NULL DEFAULT '', CHANGE `id` `id` INT(11) NULL DEFAULT '0', CHANGE `class` `class` VARCHAR(20) NULL DEFAULT '', CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `bookmarks` CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `note` `note` VARCHAR(50) NULL DEFAULT ''")

	doSQL("ALTER TABLE `inventoryChanges` CHANGE `steam` `steam` BIGINT(17) NULL DEFAULT '0', CHANGE `item` `item` VARCHAR(30) NULL DEFAULT '', CHANGE `delta` `delta` INT(11) NULL DEFAULT '0', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0', CHANGE `session` `session` INT(11) NULL DEFAULT '0', CHANGE `timestamp` `timestamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP")

	doSQL("ALTER TABLE `proxies` CHANGE `scanString` `scanString` VARCHAR(100) NOT NULL DEFAULT '', CHANGE `action` `action` VARCHAR(20) NULL DEFAULT 'nothing', CHANGE `hits` `hits` INT(11) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `memIgnoredItems` CHANGE `item` `item` VARCHAR(100) NOT NULL DEFAULT '', CHANGE `qty` `qty` INT(11) NULL DEFAULT '65'")

	doSQL("ALTER TABLE `mail` CHANGE `sender` `sender` BIGINT(17) NULL DEFAULT '0', CHANGE `message` `message` VARCHAR(500) NULL DEFAULT '', CHANGE `status` `status` INT(11) NULL DEFAULT '0'")

	doSQL("ALTER TABLE `locationSpawns` CHANGE `location` `location` VARCHAR(20) NULL DEFAULT '', CHANGE `x` `x` INT(11) NULL DEFAULT '0', CHANGE `y` `y` INT(11) NULL DEFAULT '0', CHANGE `z` `z` INT(11) NULL DEFAULT '0'")
	doSQL("ALTER TABLE `locationSpawns` ADD `id` INT NOT NULL AUTO_INCREMENT, ADD PRIMARY KEY (`id`)")

	-- misc inserts and removals
	doSQL("INSERT INTO `timedEvents` (`timer`, `delayMinutes`, `nextTime`, `disabled`) VALUES ('gimmeReset', '120', CURRENT_TIMESTAMP, '0')")
	doSQL("INSERT INTO `timedEvents` (`timer`, `delayMinutes`, `nextTime`, `disabled`) VALUES ('announcements', '60', CURRENT_TIMESTAMP, '0')")
	doSQL("DELETE FROM badItems WHERE item = 'snow'") -- remove a test item that shouldn't be live :O
	doSQL("INSERT INTO badItems (item, action) VALUES ('*Admin', 'timeout')")
	doSQL("ALTER TABLE `list` DROP INDEX `thing`")
	doSQL("ALTER TABLE `list` DROP PRIMARY KEY")
	doSQL("ALTER TABLE `resetZones` DROP COLUMN x1, DROP COLUMN x2, DROP COLUMN z1, DROP COLUMN z2")

	-- bots db
	doSQL("ALTER TABLE `bans` ADD `GBLBan` TINYINT(1) NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `messageQueue` ADD `messageTimestamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP", true)
	doSQL("ALTER TABLE `players` ADD `ircAlias` VARCHAR(15) NULL DEFAULT '', ADD `ircAuthenticated` TINYINT(1) NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `IPBlacklist` ADD  `DateAdded` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP , ADD `botID` INT NULL DEFAULT '0' , ADD `steam` BIGINT(17) NULL DEFAULT '0' , ADD `playerName` VARCHAR(25) NULL DEFAULT '', ADD `IP` VARCHAR(15) NULL DEFAULT ''", true)
	doSQL("ALTER TABLE `bans` ADD `GBLBanExpiry` DATE NOT NULL", true)
	doSQL("ALTER TABLE `bans` ADD `GBLBanReason` VARCHAR(255) NULL DEFAULT ''", true)
	doSQL("ALTER TABLE `bans` ADD `GBLBanVetted` TINYINT(1) NULL DEFAULT '0',  ADD `GBLBanActive` TINYINT(1) NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `players` ADD `VACBanned` TINYINT(1) NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `bans` ADD `level` INT NULL DEFAULT '0'", true)
	doSQL("ALTER TABLE `IPBlacklist` ADD `OrgName` VARCHAR(100) NULL DEFAULT '", true)
	doSQL("CREATE TABLE IF NOT EXISTS `IPTable` (`StartIP` bigint(15) NOT NULL,`EndIP` bigint(15) NOT NULL,`Country` varchar(2) NOT NULL DEFAULT '',`OrgName` varchar(100) NOT NULL DEFAULT '',`IP` varchar(20) NOT NULL DEFAULT '', PRIMARY KEY (`StartIP`)) ENGINE=InnoDB DEFAULT CHARSET=utf8", true)
	doSQL("CREATE TABLE IF NOT EXISTS `settings` (`DNSLookupCounter` int(11) NOT NULL DEFAULT '0',`DNSResetCounterDate` int(11) NOT NULL DEFAULT '10000101') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", true)
	doSQL("ALTER TABLE `IPTable` ADD `steam` BIGINT(17) NOT NULL DEFAULT '0', ADD `botID` INT NULL DEFAULT '0'", true)
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
		doSQL("ALTER TABLE `gimmeZombies` DROP PRIMARY KEY , ADD PRIMARY KEY (  `entityID` ), ADD `remove` TINYINT(1) NULL DEFAULT '0'")
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
