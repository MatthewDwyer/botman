--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

-- escape SQLite strings with connMEM:escape()   eg.  They're becomes They''re
-- note: the MySQL escape() works differently  eg.  They're becomes They\'re
-- You must use the escape function meant for the database engine being used.

-- how to get a number of rows returned in a query in SQLite since it has no built in row count query result --
-- cursor,errorString = connSQL:execute("SELECT count(*) FROM locationSpawns WHERE location='" .. loc .. "'")
-- rowSQL = cursor:fetch({}, "a")
-- rowCount = rowSQL["count(*)"]
-----------------------------

sqlite3 = require "luasql.sqlite3"
local statements = {}
-- display("debug sqlite line " .. debugger.getinfo(1).currentline .. "\n")


function randSQL(low, high) -- size is how many digits eg. 3 for a random 3 digit number.  max limits it eg.  max 100 won't return anything greater than 100
	local result, loopCount

	local function picker()
		local cursor,errorString, row, rnum

		cursor,errorString = connMEM:execute("SELECT random()")
		row = cursor:fetch({}, "a")
		rnum = string.format("%.f", math.abs(row["random()"]))
		math.randomseed(tonumber(rnum))

		if high then
			return math.random(low, high)
		else
			return math.random(low)
		end
	end

	if high then
		result = picker(low, high)
	else
		result = picker(low)
	end

	loopCount = 1

	-- don't draw the same random number as last time
	if botman.lastRandomNumber then
		while botman.lastRandomNumber == result do
			if high then
				result = picker(low, high)
			else
				result = picker(low)
			end
			-- don't get stuck in an infinite loop
			if loopCount > 4 then
				break -- dance
			end

			loopCount = loopCount + 1
		end
	end

	botman.lastRandomNumber = result
	return result
end


function isSQLTableEmpty(db, tbl)
	local cursor, errorString, rowSQL, rowCount, result

	result = false
	rowCount = 0

	if db == "connMEM" then
		cursor,errorString = connMEM:execute("SELECT count(*) FROM " .. tbl)
		rowSQL = cursor:fetch({}, "a")
		rowCount = rowSQL["count(*)"]
	end

	if db == "connSQL" then
		cursor,errorString = connSQL:execute("SELECT count(*) FROM " .. tbl)
		rowSQL = cursor:fetch({}, "a")
		rowCount = rowSQL["count(*)"]
	end

	-- don't bother counting connTRAK it will be too big and we don't care either :P
	if rowCount > 0 then
		result = false
	else
		result = true
	end
	return result, rowCount
end


local function doSQLiteSQL(sql, forced, whichDB)
	local shortSQL = string.sub(sql, 1, 1000) -- truncate the sql to 1000 chars

	if not statements[shortSQL] or forced then
		statements[shortSQL] = {}

		if whichDB == "connSQL" then
			connSQL:execute(sql)
		end

		if whichDB == "connTRAK" then
			connTRAK:execute(sql)
		end

		if whichDB == "connTRAKSHADOW" then
			connTRAKSHADOW:execute(sql)
		end

		if whichDB == "connINVDELTA" then
			connINVDELTA:execute(sql)
		end

		if whichDB == "connINVTRAK" then
			connINVTRAK:execute(sql)
		end

		connSQL:execute("INSERT INTO altertables (statement) VALUES ('" .. connMEM:escape(shortSQL) .. "')")
	end
end


local function alterSQLTables()
	-- unlike MySQL, SQLite can only alter 1 field at a time.  To add multiple columns each must be in its own statement.

	-- load the previously executed statements from altertables into the Lua statements table for checking by doSQL
	statements = {}
	cursor,errorString = connSQL:execute("SELECT DISTINCT statement FROM altertables")
	row = cursor:fetch({}, "a")
	while row do
		statements[row.statement] = {}
		row = cursor:fetch(row, "a")
	end

	-- tables database

	-- fix an oops
	doSQLiteSQL('DELETE FROM altertables', false, "connSQL")

	-- fix another oops
	doSQLiteSQL('DELETE FROM keystones', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "players" ADD "setBaseCooldown" INTEGER DEFAULT 0', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "players" ADD "setWPCooldown" INTEGER DEFAULT 0', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "players" ADD "userID" TEXT NOT NULL DEFAULT ""', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "players" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "bookmarks" ADD "userID" TEXT NOT NULL DEFAULT ""', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "bookmarks" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "commandQueue" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "commandQueue" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "connectQueue" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "connectQueue" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "joiningPlayers" ADD "name" TEXT NOT NULL DEFAULT ""', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "lottery" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "lottery" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "mail" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "mail" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "APIQueue" ADD "Timestamp" INTEGER NOT NULL DEFAULT 0', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "messageQueue" ADD "recipientUserID" TEXT NOT NULL DEFAULT ""', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "messageQueue" ADD "senderUserID" TEXT NOT NULL DEFAULT ""', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "miscQueue" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "miscQueue" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "persistentQueue" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "persistentQueue" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")

	doSQLiteSQL('ALTER TABLE "playerQueue" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")
	doSQLiteSQL('ALTER TABLE "playerQueue" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connSQL")

	doSQLiteSQL('CREATE TABLE "spawnableItemsQueue" ("id" INTEGER, "tableName" TEXT, PRIMARY KEY("id" AUTOINCREMENT))', false, "connSQL")

	-- tracking databases
	doSQLiteSQL('ALTER TABLE "inventoryChanges" ADD "userID" TEXT NOT NULL DEFAULT ""', false, "connINVDELTA")
	doSQLiteSQL('ALTER TABLE "inventoryChanges" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connINVDELTA")
	doSQLiteSQL('ALTER TABLE "inventoryTracker" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connINVTRAK")
	doSQLiteSQL('ALTER TABLE "inventoryTracker" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connINVTRAK")
	doSQLiteSQL('ALTER TABLE "tracker" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connTRAK")
	doSQLiteSQL('ALTER TABLE "tracker" ADD "platform" TEXT NOT NULL DEFAULT ""', false, "connTRAK")

	doSQLiteSQL('CREATE TABLE "inventoryChanges_temp" ("steam" TEXT, "timestamp" INTEGER,	"item" TEXT, "delta" INTEGER DEFAULT 0,	"x"	INTEGER DEFAULT 0,	"y"	INTEGER DEFAULT 0,	"z"	INTEGER DEFAULT 0, "session"	INTEGER DEFAULT 0, "flag"	TEXT, "userID"	TEXT NOT NULL, "platform"	TEXT NOT NULL, PRIMARY KEY("steam","timestamp"))', false, "connINVDELTA")

	doSQLiteSQL('INSERT INTO "inventoryChanges_temp" (steam, timestamp, item, delta, x,y,z,session,flag,userID,platform) SELECT steam, timestamp, item, delta, x,y,z,session,flag,userID,platform FROM inventoryChanges', false, "connINVDELTA"
	)
	doSQLiteSQL('DROP TABLE "inventoryChanges"', false, "connINVDELTA")

	doSQLiteSQL('CREATE TABLE "inventoryChanges" AS SELECT * FROM "inventoryChanges_temp"', false, "connINVDELTA")

	doSQLiteSQL('DROP TABLE "inventoryChanges_temp"', false, "connINVDELTA")
end


function openEarlySQLiteDB()
	local cursor, errorString, row

	lastAction = "Open Early SQLite Database"
	envSQL = sqlite3.sqlite3()

	connMEM = envSQL:connect('') -- temporary sqlite db in memory only

	-- create memory tables
	connMEM:execute('CREATE TABLE "gimmeQueue" ("id" INTEGER,"command" TEXT,"steam"	TEXT DEFAULT "0", "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connMEM:execute('CREATE TABLE "ircQueue" ("id" INTEGER,"name" TEXT,"command" TEXT,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connMEM:execute('CREATE TABLE "list" ("thing" TEXT,"id"	INTEGER DEFAULT 0,"class" TEXT,"steam" TEXT DEFAULT "0", "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "")') -- converted
	connMEM:execute('CREATE TABLE "list2" ("thing" TEXT,"id" INTEGER DEFAULT 0,"class" TEXT,"steam" TEXT DEFAULT "0", "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "")') -- converted
	connMEM:execute('CREATE TABLE "entities" ("entityID"	INTEGER UNIQUE,"type" TEXT,"name" TEXT,"x" INTEGER DEFAULT 0, "y" INTEGER DEFAULT 0, "z" INTEGER DEFAULT 0,"dead" INTEGER DEFAULT 0,"health" INTEGER DEFAULT 0,PRIMARY KEY("entityID"))') -- converted
	connMEM:execute('CREATE TABLE "tracker" ("trackerID"	INTEGER,"admin"	TEXT DEFAULT "0","steam" TEXT DEFAULT "0","timestamp" INTEGER,"x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,"session" INTEGER DEFAULT 0,"flag" TEXT,"baseKey" TEXT DEFAULT "",PRIMARY KEY("trackerID" AUTOINCREMENT))') -- converted, tested
	connMEM:execute('CREATE TABLE "shop" ("item" TEXT,"category" TEXT,"price" INTEGER DEFAULT 50, "stock" INTEGER DEFAULT 50,"idx" INTEGER DEFAULT 0,"code" TEXT,"units" INTEGER DEFAULT 1,"quality" INTEGER DEFAULT 0,PRIMARY KEY("item"))') -- converted
	connMEM:execute('CREATE TABLE "searchResults" ("id"	INTEGER,"owner"	TEXT DEFAULT "0","steam" TEXT DEFAULT "0","x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,"session" INTEGER DEFAULT 0,"date" TEXT,"counter" INTEGER DEFAULT 0, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connMEM:execute('CREATE TABLE "serverCommandQueue" ("id" INTEGER, "command" TEXT NOT NULL UNIQUE, PRIMARY KEY("id" AUTOINCREMENT))')

	connSQL = envSQL:connect(homedir .. '/tables.sqlite') -- sqlite db on disk
	connSQL:execute("PRAGMA auto_vacuum = 0")

	-- try to create tables in tables.sqlite
	connSQL:execute('CREATE TABLE "APIQueue" ("id" INTEGER,"URL" TEXT,"OutputFile" TEXT,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connSQL:execute('CREATE TABLE "bookmarks" ("id" INTEGER,"steam" TEXT DEFAULT "0","x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,"note" TEXT, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connSQL:execute('CREATE TABLE "commandQueue" ("id" INTEGER,"steam" TEXT DEFAULT "0","command" TEXT, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connSQL:execute('CREATE TABLE "connectQueue" ("id" INTEGER,"steam" TEXT DEFAULT "0","command" TEXT,"processed" INTEGER DEFAULT 0, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connSQL:execute('CREATE TABLE "helpCommands" ("topic" TEXT, "functionName" TEXT, "command" TEXT, "description" TEXT, "notes" INTEGER, "keywords" TEXT, "lastUpdate" INTEGER, "accessLevel" INTEGER DEFAULT 99, "ingameOnly" INTEGER DEFAULT 0, PRIMARY KEY("topic","functionName"))')
	connSQL:execute('CREATE TABLE "helpTopics" ("topic" TEXT, "description" TEXT, PRIMARY KEY("topic"))')
	connSQL:execute('CREATE TABLE "keystones" ("steam" TEXT,"x" INTEGER,"y" INTEGER,"z" INTEGER,"remove" INTEGER DEFAULT 0,"removed" INTEGER DEFAULT 0,"expired" INTEGER DEFAULT 0, PRIMARY KEY("steam","x","y","z"))') -- converted
	connSQL:execute('CREATE TABLE "LKPQueue" ("id" INTEGER,"line" TEXT, PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connSQL:execute('CREATE TABLE "locationSpawns" ("id" INTEGER,"location" TEXT,"x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,	PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connSQL:execute('CREATE TABLE "lottery" ("steam" TEXT DEFAULT "0", "ticket" INTEGER DEFAULT 0, userID TEXT, platform TEXT, PRIMARY KEY("steam","ticket"))') -- converted
	connSQL:execute('CREATE TABLE "mail" ("id" INTEGER,"sender" TEXT DEFAULT "0","recipient" TEXT DEFAULT "0","message" TEXT,"status" INTEGER DEFAULT 0,"flag" TEXT, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connSQL:execute('CREATE TABLE "messageQueue" ("id" INTEGER,"sender" TEXT DEFAULT "0","recipient" TEXT DEFAULT "0","message" TEXT, "senderUserID" TEXT NOT NULL DEFAULT "", "recipientUserID" TEXT NOT NULL DEFAULT "", PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connSQL:execute('CREATE TABLE "miscQueue" ("id" INTEGER,"steam" TEXT DEFAULT "0","command" TEXT,"action" TEXT,"value" INTEGER DEFAULT 0,"timerDelay" INTEGER DEFAULT 0, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connSQL:execute('CREATE TABLE "persistentQueue" ("id" INTEGER, "steam" TEXT DEFAULT 0, "command" TEXT, "action" TEXT, "value" INTEGER DEFAULT 0, "timerDelay" INTEGER, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("id" AUTOINCREMENT))')
	connSQL:execute('CREATE TABLE "playerQueue" ("id" INTEGER,"command" TEXT,"arena" INTEGER DEFAULT 0,"boss" INTEGER DEFAULT 0,"steam" TEXT DEFAULT "0","delayTimer" INTEGER DEFAULT 0, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connSQL:execute('CREATE TABLE "prefabCopies" ("owner" TEXT,"name" TEXT,"x1" INTEGER DEFAULT 0,"x2" INTEGER DEFAULT 0,"y1" INTEGER DEFAULT 0,"y2" INTEGER DEFAULT 0,"z1" INTEGER DEFAULT 0,"z2" INTEGER DEFAULT 0,"blockName" TEXT,"rotation" INTEGER DEFAULT 0,PRIMARY KEY("owner","name"))') -- converted
	connSQL:execute('CREATE TABLE "proxies" ("scanString" TEXT,"action" TEXT DEFAULT "nothing","hits" INTEGER DEFAULT 0,PRIMARY KEY("scanString"))') -- converted
	connSQL:execute('CREATE TABLE "altertables" ("id" INTEGER,"statement" TEXT,PRIMARY KEY("id" AUTOINCREMENT))')
	connSQL:execute('CREATE TABLE "players" ("steam" TEXT UNIQUE, "name" TEXT, "nameOverride" TEXT DEFAULT "", "id" INTEGER DEFAULT 0, "sessionCount" INTEGER DEFAULT 1, "newPlayer" INTEGER DEFAULT 1, "firstSeen" INTEGER DEFAULT 0, "xPos" INTEGER DEFAULT 0, "yPos" INTEGER DEFAULT 0, "zPos" INTEGER DEFAULT 0, "xPosOld" INTEGER DEFAULT 0, "yPosOld" INTEGER DEFAULT 0, "zPosOld" INTEGER DEFAULT 0, "chatColour" TEXT DEFAULT "FFFFFF", "cash" INTEGER DEFAULT 0, "maxWaypoints" INTEGER DEFAULT 0, "pvpBounty" INTEGER DEFAULT 0, "watchCash" INTEGER DEFAULT 0, "watchPlayer" INTEGER DEFAULT 1, "watchPlayerTimer" INTEGER DEFAULT 0, "timeout" INTEGER DEFAULT 0, "botTimeout" INTEGER DEFAULT 0, "xPosTimeout" INTEGER DEFAULT 0, "yPosTimeout" INTEGER DEFAULT 0, "zPosTimeout" INTEGER DEFAULT 0, "ircAlias" TEXT DEFAULT "", "ircLogin" TEXT DEFAULT "", "ircPass" TEXT DEFAULT "", "bed" TEXT DEFAULT "", "bedX" INTEGER DEFAULT 0, "bedY" INTEGER DEFAULT 0, "bedZ" INTEGER DEFAULT 0, "exiled" INTEGER DEFAULT 0, "prisoner" INTEGER DEFAULT 0, "prisonReleaseTime" INTEGER DEFAULT 0, "prisonReason" TEXT DEFAULT "", "prisonxPosOld" INTEGER DEFAULT 0, "prisonyPosOld" INTEGER DEFAULT 0, "prisonzPosOld" INTEGER DEFAULT 0, "pvpVictim" INTEGER DEFAULT 0, "bail" INTEGER DEFAULT 0, "permanentBan" INTEGER DEFAULT 0, "whitelisted" INTEGER DEFAULT 0, "silentBob" INTEGER DEFAULT 0, "walkies" INTEGER DEFAULT 0, "canTeleport" INTEGER DEFAULT 1, "allowBadInventory" INTEGER DEFAULT 0, "noSpam" INTEGER DEFAULT 0, "mute" INTEGER DEFAULT 0, "ignorePlayer" INTEGER DEFAULT 0, "reserveSlot" INTEGER DEFAULT 0, "baseCooldown" INTEGER DEFAULT 0, "pvpTeleportCooldown" INTEGER DEFAULT 0, "returnCooldown" INTEGER DEFAULT 0, "commandCooldown" INTEGER DEFAULT 0, "gimmeCooldown" INTEGER DEFAULT 0, "p2pCooldown" INTEGER DEFAULT 0, "teleCooldown" INTEGER DEFAULT 0, "waypointCooldown" INTEGER DEFAULT 0, "location" TEXT DEFAULT "", "maxBases" INTEGER DEFAULT 1, "maxProtectedBases" INTEGER DEFAULT 1,"groupID" INTEGER DEFAULT 0,"allowWaypoints" INTEGER DEFAULT 0, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("steam"))')
	connSQL:execute('CREATE TABLE "joiningPlayers" ("steam" TEXT NOT NULL, "userID" TEXT, "timestamp" INTEGER, PRIMARY KEY("steam"))')
	connSQL:execute('CREATE TABLE "settings" ("resumeRebootAfterDay" INTEGER DEFAULT 0, "botIsPaused" INTEGER DEFAULT 0, "doNotReboot" INTEGER DEFAULT 0)')

	connTRAK = envSQL:connect(homedir .. '/tracking.sqlite') -- sqlite db on disk for movement tracking
	connTRAK:execute("PRAGMA auto_vacuum = 0")
	-- try to create tables in tracking.sqlite
	connTRAK:execute('CREATE TABLE "tracker" ("trackerID" INTEGER,"steam" TEXT DEFAULT "0","timestamp" INTEGER,"x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,"session" INTEGER DEFAULT 0,"flag" TEXT, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("trackerID" AUTOINCREMENT))')

	connTRAKSHADOW = envSQL:connect(homedir .. '/trackingShadow.sqlite') -- sqlite db on disk for movement tracking
	connTRAKSHADOW:execute("PRAGMA auto_vacuum = 0")
	-- try to create tables in trackingShadow.sqlite
	connTRAKSHADOW:execute('CREATE TABLE "tracker" ("trackerID" INTEGER,"steam" TEXT DEFAULT "0","timestamp" INTEGER,"x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,"session" INTEGER DEFAULT 0,"flag" TEXT, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("trackerID" AUTOINCREMENT))')

	connINVDELTA = envSQL:connect(homedir .. '/inventoryDELTA.sqlite') -- sqlite db on disk for inventory tracking
	connINVDELTA:execute("PRAGMA auto_vacuum = 0")
	-- try to create tables in inventoryDELTA.sqlite
	connINVDELTA:execute('CREATE TABLE "inventoryChanges" ("steam" INTEGER,"timestamp" INTEGER,"item" TEXT,"delta" INTEGER DEFAULT 0,"x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,"session" INTEGER DEFAULT 0,"flag" TEXT, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("steam","timestamp"))')

	connINVTRAK = envSQL:connect(homedir .. '/inventoryTracker.sqlite') -- sqlite db on disk for inventory tracking
	connINVTRAK:execute("PRAGMA auto_vacuum = 0")
	-- try to create tables in inventoryTracker.sqlite
	connINVTRAK:execute('CREATE TABLE "inventoryTracker" ("steam" TEXT,"timestamp" INTEGER,"belt" TEXT,"pack" TEXT,"equipment" TEXT,"session" INTEGER DEFAULT 0,"x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0, "userID" TEXT NOT NULL DEFAULT "", "platform" TEXT NOT NULL DEFAULT "", PRIMARY KEY("steam","timestamp"))')

	alterSQLTables()
end


function openSQLiteDB()
	local cursor, errorString, row
	local queued = false

	lastAction = "Open SQLite Database"
	disableTimers() -- stop all of the timers so that nothing interferes with this code
	tempTimer(30, [[enableTimers()]]) -- schedule the timers to be re-enabled again just in case the code below fails to complete

	-- copy data from mysql to sqlite

	-- bookmarks
	if isSQLTableEmpty("connSQL", "bookmarks") then
		cursor,errorString = conn:execute("SHOW TABLES LIKE 'bookmarks'")
		row = cursor:fetch({}, "a")

		if row then
			cursor,errorString = conn:execute("SELECT * FROM bookmarks")
			row = cursor:fetch({}, "a")

			while row do
				connSQL:execute('INSERT INTO bookmarks (id, steam, x, y, z, note) VALUES (' .. row.id .. ',"' .. row.steam .. '",' .. row.x .. ',' .. row.y .. ',' .. row.z .. ',"' .. connMEM:escape(row.note) .. '")')
				row = cursor:fetch(row, "a")
			end

			-- drop the old mysql table
			conn:execute("DROP TABLE bookmarks")
		end
	end

	-- keystones
	if isSQLTableEmpty("connSQL", "keystones") then
		cursor,errorString = conn:execute("SHOW TABLES LIKE 'keystones'")
		row = cursor:fetch({}, "a")

		if row then
			cursor,errorString = conn:execute("SELECT * FROM keystones")
			row = cursor:fetch({}, "a")

			while row do
				connSQL:execute('INSERT INTO keystones (steam, x, y, z, remove, removed, expired) VALUES ("' .. row.steam .. '",' .. row.x .. ',' .. row.y .. ',' .. row.z .. ',' .. row.remove .. ',' .. row.removed .. ',' .. row.expired .. ')')
				row = cursor:fetch(row, "a")
			end

			-- drop the old mysql table
			conn:execute("DROP TABLE keystones")
		end
	end

	-- locationSpawns
	if isSQLTableEmpty("connSQL", "locationSpawns") then
		cursor,errorString = conn:execute("SHOW TABLES LIKE 'locationSpawns'")
		row = cursor:fetch({}, "a")

		if row then
			cursor,errorString = conn:execute("SELECT * FROM locationSpawns")

			row = cursor:fetch({}, "a")

			while row do
				connSQL:execute('INSERT INTO locationSpawns (id, location, x, y, z) VALUES (' .. row.id .. ',"' .. connMEM:escape(row.location) .. '",' .. row.x .. ',' .. row.y .. ',' .. row.z .. ')')
				row = cursor:fetch(row, "a")
			end

			-- drop the old mysql table
			conn:execute("DROP TABLE locationSpawns")
		end
	end

	-- lottery
	if isSQLTableEmpty("connSQL", "lottery") then
		cursor,errorString = conn:execute("SHOW TABLES LIKE 'lottery'")
		row = cursor:fetch({}, "a")

		if row then
			cursor,errorString = conn:execute("SELECT * FROM lottery")
			row = cursor:fetch({}, "a")

			while row do
				connSQL:execute('INSERT INTO lottery (steam, ticket) VALUES ("' .. row.steam .. '",' .. row.ticket .. ')')
				row = cursor:fetch(row, "a")
			end

			-- drop the old mysql table
			conn:execute("DROP TABLE lottery")
		end
	end

	-- mail
	if isSQLTableEmpty("connSQL", "mail") then
		cursor,errorString = conn:execute("SHOW TABLES LIKE 'mail'")
		row = cursor:fetch({}, "a")

		if row then
			cursor,errorString = conn:execute("SELECT * FROM mail")
			row = cursor:fetch({}, "a")

			while row do
				connSQL:execute('INSERT INTO mail (id, sender, recipient, message, status) VALUES (' .. row.id .. ',"' .. row.sender .. '","' .. row.recipient .. '","' .. connMEM:escape(row.message) .. '",' .. row.status .. ')')
				row = cursor:fetch(row, "a")
			end

			-- drop the old mysql table
			conn:execute("DROP TABLE mail")
		end
	end

	-- messageQueue
	if isSQLTableEmpty("connSQL", "messageQueue") then
		cursor,errorString = conn:execute("SHOW TABLES LIKE 'messageQueue'")
		row = cursor:fetch({}, "a")

		if row then
			cursor,errorString = conn:execute("SELECT * FROM messageQueue")
			row = cursor:fetch({}, "a")

			while row do
				connSQL:execute('INSERT INTO messageQueue (id, sender, recipient, message) VALUES (' .. row.id .. ',"' .. row.sender .. '","' .. row.recipient .. '","' .. connMEM:escape(row.message) .. '")')
				queued = true
				row = cursor:fetch(row, "a")
			end

			if queued then
				tempTimer(2, [[ botman.messageQueueEmpty = false  ]])
			end

			-- drop the old mysql table
			conn:execute("DROP TABLE messageQueue")
		end
	end

	-- persistentQueue
	if isSQLTableEmpty("connSQL", "persistentQueue") then
		cursor,errorString = conn:execute("SHOW TABLES LIKE 'persistentQueue'")
		row = cursor:fetch({}, "a")

		if row then
			cursor,errorString = conn:execute("SELECT * FROM persistentQueue")
			row = cursor:fetch({}, "a")

			while row do
				connSQL:execute('INSERT INTO persistentQueue (id, steam, command, action, value, timerDelay) VALUES (' .. row.id .. ',"' .. row.steam .. '","' .. row.command .. '","' .. row.action .. '",' .. row.value .. ',' .. row.timerDelay .. ')')
				botman.persistentQueueEmpty = false
				row = cursor:fetch(row, "a")
			end

			-- drop the old mysql table
			conn:execute("DROP TABLE persistentQueue")
		end
	end

	-- prefabCopies
	if isSQLTableEmpty("connSQL", "prefabCopies") then
		cursor,errorString = conn:execute("SHOW TABLES LIKE 'prefabCopies'")
		row = cursor:fetch({}, "a")

		if row then
			cursor,errorString = conn:execute("SELECT * FROM prefabCopies")
			row = cursor:fetch({}, "a")

			while row do
				connSQL:execute('INSERT INTO prefabCopies (owner, name, x1, x2, y1, y2, z1, z2, blockName, rotation) VALUES ("' .. row.owner .. '","' .. connMEM:escape(row.name) .. '",' .. row.x1 .. ',' .. row.x2 .. ',' .. row.y1 .. ',' .. row.y2 .. ',' .. row.z1 .. ',' .. row.z2 .. ',"' .. row.blockName .. '",' .. row.rotation .. ')')
				row = cursor:fetch(row, "a")
			end

			-- drop the old mysql table
			conn:execute("DROP TABLE prefabCopies")
		end
	end

	-- proxies
	if isSQLTableEmpty("connSQL", "proxies") then
		cursor,errorString = conn:execute("SHOW TABLES LIKE 'proxies'")
		row = cursor:fetch({}, "a")

		if row then
			cursor,errorString = conn:execute("SELECT * FROM proxies")
			row = cursor:fetch({}, "a")

			while row do
				connSQL:execute('INSERT INTO proxies (scanString, action, hits) VALUES ("' .. connMEM:escape(row.scanString) .. '","' .. row.action .. '",' .. row.hits .. ')')
				row = cursor:fetch(row, "a")
			end

			-- drop the old mysql table
			conn:execute("DROP TABLE proxies")
		end
	end

	enableTimers() -- Gosh! Is that the time?  Re-enable the timers.
end


function dumpSQLiteTable(table)
	local cursor, errorString, row, fields, values, k, v, file

	cursor,errorString = connSQL:execute("SELECT * FROM " .. table)
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


function saveSQLitePlayer(steam)
	local player = players[steam]
	local cursor,errorString,row

	cursor,errorString = connSQL:execute("SELECT steam FROM players WHERE steam = '" .. steam .. "'")
	row = cursor:fetch({}, "a")

	if not row then
 		connSQL:execute('INSERT INTO players (steam, name, nameOverride, chatColour, ircAlias, ircLogin, ircPass, prisonReason, location, id, sessionCount, firstSeen, xPos, yPos, zPos, xPosOld, yPosOld, zPosOld, cash, maxWaypoints, pvpBounty, timeout, xPosTimeout, yPosTimeout, zPosTimeout, bed, bedX, bedY, bedZ, prisonReleaseTime, prisonxPosOld, prisonyPosOld, prisonzPosOld, pvpVictim, bail, baseCooldown, pvpTeleportCooldown, returnCooldown, commandCooldown, gimmeCooldown, p2pCooldown, teleCooldown, waypointCooldown, watchPlayerTimer, newPlayer, watchCash, watchPlayer, exiled, prisoner, permanentBan, whitelisted, silentBob, walkies, canTeleport, allowBadInventory, noSpam, mute, ignorePlayer, reserveSlot, maxBases, maxProtectedBases, groupID, userID, platform) VALUES (' .. steam .. ', "' .. connMEM:escape(player.name) .. '", "' .. connMEM:escape(player.nameOverride) .. '", "' .. connMEM:escape(player.chatColour) .. '", "' .. connMEM:escape(player.ircAlias) .. '", "' .. connMEM:escape(player.ircLogin) .. '", "' .. connMEM:escape(player.ircPass) .. '", "' .. connMEM:escape(player.prisonReason) .. '", "' .. connMEM:escape(player.location) .. '",' .. player.id .. ',' .. player.sessionCount .. ',' .. player.firstSeen .. ',' .. player.xPos .. ',' .. player.yPos .. ',' .. player.zPos .. ',' .. player.xPosOld .. ',' .. player.yPosOld .. ',' .. player.zPosOld .. ',' .. player.cash .. ',' .. player.maxWaypoints .. ',' .. player.pvpBounty .. ',' .. dbBool(player.timeout) .. ',' .. player.xPosTimeout .. ',' .. player.yPosTimeout .. ',' .. player.zPosTimeout .. ',"' .. player.bed .. '",' .. player.bedX .. ',' .. player.bedY .. ',' .. player.bedZ .. ',' .. player.prisonReleaseTime .. ',' .. player.prisonxPosOld .. ',' .. player.prisonyPosOld .. ',' .. player.prisonzPosOld .. ',"' .. player.pvpVictim .. '",' .. player.bail .. ',' .. player.baseCooldown .. ',' .. player.pvpTeleportCooldown .. ',' .. player.returnCooldown .. ',' .. player.commandCooldown .. ',' .. player.gimmeCooldown .. ',' .. player.p2pCooldown .. ',' .. player.teleCooldown .. ',' .. player.waypointCooldown .. ',' .. player.watchPlayerTimer .. ',' .. dbBool(player.newPlayer) .. ',' .. dbBool(player.watchCash) .. ',' .. dbBool(player.watchPlayer) .. ',' .. dbBool(player.exiled) .. ',' .. dbBool(player.prisoner) .. ',' .. dbBool(player.permanentBan) .. ',' .. dbBool(player.whitelisted) .. ',' .. dbBool(player.silentBob) .. ',' .. dbBool(player.walkies) .. ',' .. dbBool(player.canTeleport) .. ',' .. dbBool(player.allowBadInventory) .. ',' .. dbBool(player.noSpam) .. ',' .. dbBool(player.mute) .. ',' .. dbBool(player.ignorePlayer) .. ',' .. dbBool(player.reserveSlot) .. ',' .. player.maxBases .. ',' .. player.maxProtectedBases ..  ',' .. player.groupID .. ',"' .. connMEM:escape(player.userID) .. '","' .. connMEM:escape(player.platform) .. '")')
	else
		connSQL:execute("UPDATE players SET name='" .. connMEM:escape(player.name) .. "', nameOverride='" .. connMEM:escape(player.nameOverride) .. "', id=" .. player.id .. ", sessionCount=" .. player.sessionCount .. ", newPlayer=" .. dbBool(player.newPlayer) .. ", firstSeen=" .. player.firstSeen .. ", xPos=" .. player.xPos .. ", yPos=" .. player.yPos .. ", zPos=" .. player.zPos .. ", xPosOld=" .. player.xPosOld .. ", yPosOld=" .. player.yPosOld .. ", zPosOld=" .. player.zPosOld .. ", chatColour='" .. connMEM:escape(player.chatColour) .. "', cash=" .. player.cash .. ", maxWaypoints=" .. player.maxWaypoints .. ", pvpBounty=" .. player.pvpBounty .. ", watchCash=" .. dbBool(player.watchCash) .. ", watchPlayer=" .. dbBool(player.watchPlayer) .. ", watchPlayerTimer=" .. player.watchPlayerTimer .. ", timeout=" .. dbBool(player.timeout) .. ", xPosTimeout=" .. player.xPosTimeout .. ", yPosTimeout=" .. player.yPosTimeout .. ", zPosTimeout=" .. player.zPosTimeout .. ", ircAlias='" .. connMEM:escape(player.ircAlias) .. "', ircLogin='" .. connMEM:escape(player.ircLogin) .. "', ircPass='" .. connMEM:escape(player.ircPass) .. "', bed='" .. connMEM:escape(player.bed) .. "', bedX=" .. player.bedX .. ", bedY=" .. player.bedY .. ", bedZ=" .. player.bedZ .. ", exiled=" .. dbBool(player.exiled) .. ", prisoner=" .. dbBool(player.prisoner) .. ", prisonReleaseTime=" .. player.prisonReleaseTime .. ", prisonReason='" .. connMEM:escape(player.prisonReason) .. "', prisonxPosOld=" .. player.prisonxPosOld .. ", prisonyPosOld=" .. player.prisonyPosOld .. ", prisonzPosOld=" .. player.prisonzPosOld .. ", pvpVictim='" .. player.pvpVictim .. "', bail=" .. player.bail .. ", permanentBan=" .. dbBool(player.permanentBan) .. ", whitelisted=" .. dbBool(player.whitelisted) .. ", silentBob=" .. dbBool(player.silentBob) .. ", walkies=" .. dbBool(player.walkies) .. ", canTeleport=" .. dbBool(player.canTeleport) .. ", allowBadInventory=" .. dbBool(player.allowBadInventory) .. ", noSpam=" .. dbBool(player.noSpam) .. ", mute=" .. dbBool(player.mute) .. ", ignorePlayer=" .. dbBool(player.ignorePlayer) .. ", reserveSlot=" .. dbBool(player.reserveSlot) .. ", baseCooldown=" .. player.baseCooldown .. ", pvpTeleportCooldown=" .. player.pvpTeleportCooldown .. ", returnCooldown=" .. player.returnCooldown .. ", commandCooldown=" .. player.commandCooldown .. ", gimmeCooldown=" .. player.gimmeCooldown .. ", p2pCooldown=" .. player.p2pCooldown .. ", teleCooldown=" .. player.teleCooldown .. ", waypointCooldown=" .. player.waypointCooldown .. ", location='" .. connMEM:escape(player.location) .. "', maxBases=" .. player.maxBases .. ", maxProtectedBases=" .. player.maxProtectedBases .. ", groupID=" .. player.groupID .. ", userID='" .. connMEM:escape(player.userID) .. "', platform='" .. connMEM:escape(player.platform) .. "' WHERE steam='" .. steam .. "'")
	end
end


function restoreSQLitePlayer(steam)
	local cursor,errorString,row

	cursor,errorString = connSQL:execute("SELECT * FROM players WHERE steam = '" .. steam .. "'")
	row = cursor:fetch({}, "a")

	if row then
		conn:execute("UPDATE players SET name='" .. escape(row.name) .. "', nameOverride='" .. escape(row.nameOverride) .. "', id=" .. row.id .. ", sessionCount=" .. row.sessionCount .. ", newPlayer=" .. row.newPlayer .. ", firstSeen=" .. row.firstSeen .. ", xPos=" .. row.xPos .. ", yPos=" .. row.yPos .. ", zPos=" .. row.zPos .. ", xPosOld=" .. row.xPosOld .. ", yPosOld=" .. row.yPosOld .. ", zPosOld=" .. row.zPosOld .. ", chatColour='" .. escape(row.chatColour) .. "', cash=" .. row.cash .. ", maxWaypoints=" .. row.maxWaypoints .. ", pvpBounty=" .. row.pvpBounty .. ", watchCash=" .. row.watchCash .. ", watchPlayer=" .. row.watchPlayer .. ", watchPlayerTimer=" .. row.watchPlayerTimer .. ", timeout=" .. row.timeout .. ", xPosTimeout=" .. row.xPosTimeout .. ", yPosTimeout=" .. row.yPosTimeout .. ", zPosTimeout=" .. row.zPosTimeout .. ", ircAlias='" .. escape(row.ircAlias) .. "', ircLogin='" .. escape(row.ircLogin) .. "', ircPass='" .. escape(row.ircPass) .. "', bed='" .. escape(row.bed) .. "', bedX=" .. row.bedX .. ", bedY=" .. row.bedY .. ", bedZ=" .. row.bedZ .. ", exiled=" .. row.exiled .. ", prisoner=" .. row.prisoner .. ", prisonReleaseTime=" .. row.prisonReleaseTime .. ", prisonReason='" .. escape(row.prisonReason) .. "', prisonxPosOld=" .. row.prisonxPosOld .. ", prisonyPosOld=" .. row.prisonyPosOld .. ", prisonzPosOld=" .. row.prisonzPosOld .. ", pvpVictim='" .. row.pvpVictim .. "', bail=" .. row.bail .. ", permanentBan=" .. row.permanentBan .. ", whitelisted=" .. row.whitelisted .. ", silentBob=" .. row.silentBob .. ", walkies=" .. row.walkies .. ", canTeleport=" .. row.canTeleport .. ", allowBadInventory=" .. row.allowBadInventory .. ", noSpam=" .. row.noSpam .. ", mute=" .. row.mute .. ", ignorePlayer=" .. row.ignorePlayer .. ", reserveSlot=" .. row.reserveSlot .. ", baseCooldown=" .. row.baseCooldown .. ", pvpTeleportCooldown=" .. row.pvpTeleportCooldown .. ", returnCooldown=" .. row.returnCooldown .. ", commandCooldown=" .. row.commandCooldown .. ", gimmeCooldown=" .. row.gimmeCooldown .. ", p2pCooldown=" .. row.p2pCooldown .. ", teleCooldown=" .. row.teleCooldown .. ", waypointCooldown=" .. row.waypointCooldown .. ", location='" .. escape(row.location) .. "', maxBases=" .. row.maxBases .. ", maxProtectedBases=" .. row.maxProtectedBases .. ", groupID=" .. row.groupID .. " WHERE steam= '" .. steam .. "'")
		loadPlayers(steam)
	end
end


function getSQLTableFields(table)
	local field, tbl, cursor, errorString, row

	--function inspect the table and store field names, types and default values
	tbl = table .. "Fields"

	_G[tbl] = {}

	cursor,errorString = connSQL:execute("SHOW FIELDS FROM " .. table)
	row = cursor:fetch({}, "a")

	while row do
		field = row.Field

		_G[tbl][field] = {}
		_G[tbl][field].field = field
		_G[tbl][field].type = string.sub(row.Type, 1,3)
		_G[tbl][field].key = "nil"
		_G[tbl][field].default = "nil"

		if row.Key then
			_G[tbl][field].key = string.sub(row.Key, 1,3)
		end

		if row.Default then
			_G[tbl][field].default = row.Default
		end

		row = cursor:fetch(row, "a")
	end
end


function processServerCommandQueue()
	local cursor, errorString, row

	cursor,errorString = connMEM:execute("SELECT * FROM serverCommandQueue")
	row = cursor:fetch({}, "a")

	while row do
		sendCommand(row.command)
		row = cursor:fetch(row, "a")
	end

	connMEM:execute("DELETE FROM serverCommandQueue")
end


function deleteTrackingDataSQLite(keepDays)
	-- to prevent the database collecting too much data, becoming slow and potentially filling the root partition
	-- we periodically clear out old data.  The default is to keep the last 28 days.

	local DateYear = os.date('%Y', os.time())
	local DateMonth = os.date('%m', os.time())
	local DateDay = os.date('%d', os.time())
	local deletionDate = os.time({day = DateDay - keepDays, month = DateMonth, year = DateYear})
	local deletionDate90Days = os.time({day = DateDay - 90, month = DateMonth, year = DateYear})

	connINVDELTA:execute("DELETE FROM inventoryChanges WHERE timestamp < \"" .. os.date("%Y-%m-%d", deletionDate))
	connINVTRAK:execute("DELETE FROM inventoryTracker WHERE timestamp < \"" .. os.date("%Y-%m-%d", deletionDate))
	connTRAK:execute("DELETE FROM tracker WHERE timestamp < \"" .. os.date("%Y-%m-%d", deletionDate))
	connTRAKSHADOW:execute("DELETE FROM tracker WHERE timestamp < \"" .. os.date("%Y-%m-%d", deletionDate))

	-- may need to only do the vacuuming when no players are on if this turns out to be very slow with large data
	-- I want to break free
	connTRAK:execute("VACUUM")
	connTRAKSHADOW:execute("VACUUM")
	connINVDELTA:execute("VACUUM")
	-- I want to breaaak free
	connINVTRAK:execute("VACUUM")
	connSQL:execute("VACUUM")
	connMEM:execute("VACUUM")
end