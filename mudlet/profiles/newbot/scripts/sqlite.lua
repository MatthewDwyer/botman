--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
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


-- function dumpSQLiteTable(table)
	-- local cursor, errorString, row, fields, values, k, v, file

	-- cursor,errorString = connSQL:execute("SELECT * FROM " .. table)
	-- row = cursor:fetch({}, "a")

	-- file = io.open(homedir .. "/" .. table .. "_" .. os.date("%Y%m%d_%H%M%S") .. ".csv", "a")

	-- if row then
		-- fields = ""

		-- for k,v in pairs(row) do
			-- if fields ~= "" then fields = fields .. "," end
			-- fields = fields .. k
		-- end

		-- file:write(fields .. "\n")
	-- end

	-- while row do
		-- values = ""

		-- for k,v in pairs(row) do
			-- if values ~= "" then values = values .. "," end
			-- values = values .. v
		-- end

		-- file:write(values .. "\n")
		-- row = cursor:fetch(row, "a")
	-- end

	-- file:close()
-- end


function randSQL(low, high) -- size is how many digits eg. 3 for a random 3 digit number.  max limits it eg.  max 100 won't return anything greater than 100
	local result

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

	-- -- don't draw the same random number as last time
	-- if botman.lastRandomNumber then
		-- while botman.lastRandomNumber == result do
			-- if high then
				-- result = picker(low, high)
			-- else
				-- result = picker(low)
			-- end
		-- end
	-- end

	botman.lastRandomNumber = result
	return result
end


function openSQLiteDB()
	local newDB, cursor, errorString

	-- newDB = not exists(homedir .. '/tables.sqlite')
	newDB = false -- TODO: remove this and uncomment above when ready
	lastAction = "Open SQLite Database"
	envSQL  = sqlite3.sqlite3()
	--connSQL = envSQL:connect(homedir .. '/tables.sqlite') -- sqlite db on disk
	--connTRAK = envSQL:connect(homedir .. '/tracking.sqlite') -- sqlite db on disk for inventory tracking
	connMEM = envSQL:connect('') -- temporary sqlite db in memory only

	-- create memory tables
	connMEM:execute('CREATE TABLE "gimmeQueue" ("id" INTEGER,"command" TEXT,"steam"	TEXT DEFAULT "0",PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connMEM:execute('CREATE TABLE "ircQueue" ("id" INTEGER,"name" TEXT,"command" TEXT,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
	connMEM:execute('CREATE TABLE "list" ("thing" TEXT,"id"	INTEGER DEFAULT 0,"class" TEXT,"steam" TEXT DEFAULT "0")') -- converted
	connMEM:execute('CREATE TABLE "list2" ("thing" TEXT,"id" INTEGER DEFAULT 0,"class" TEXT,"steam" TEXT DEFAULT "0")') -- converted
	connMEM:execute('CREATE TABLE "memEntities" ("entityID"	INTEGER UNIQUE,"type" TEXT,"name" TEXT,"x" INTEGER DEFAULT 0, "y" INTEGER DEFAULT 0, "z" INTEGER DEFAULT 0,"dead" INTEGER DEFAULT 0,"health" INTEGER DEFAULT 0,PRIMARY KEY("entityID"))') -- converted
	connMEM:execute('CREATE TABLE "memTracker" ("trackerID"	INTEGER,"admin"	TEXT DEFAULT "0","steam" TEXT DEFAULT "0","timestamp" INTEGER,"x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,"session" INTEGER DEFAULT 0,"flag" TEXT,PRIMARY KEY("trackerID" AUTOINCREMENT))') -- converted, tested
	connMEM:execute('CREATE TABLE "memShop" ("item"	TEXT,"category"	TEXT,"price" INTEGER DEFAULT 50, "stock" INTEGER DEFAULT 50,"idx" INTEGER DEFAULT 0,"code" TEXT,"units"	INTEGER DEFAULT 1,"quality"	INTEGER DEFAULT 0,PRIMARY KEY("item"))') -- converted
	connMEM:execute('CREATE TABLE "searchResults" ("id"	INTEGER,"owner"	TEXT DEFAULT "0","steam" TEXT DEFAULT "0","x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,"session" INTEGER DEFAULT 0,"date" TEXT,"counter" INTEGER DEFAULT 0,PRIMARY KEY("id" AUTOINCREMENT))') -- converted

	if newDB then
		-- create the tables in tables.sqlite because the db was just created and is empty
		connSQL:execute('CREATE TABLE "altertables" ("id" INTEGER,"statement" TEXT,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
		connSQL:execute('CREATE TABLE "APIQueue" ("id" INTEGER,"URL" TEXT,"OutputFile" TEXT,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
		connSQL:execute('CREATE TABLE "bookmarks" ("id" INTEGER,"steam" TEXT DEFAULT "0","x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,"note" TEXT,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
		connSQL:execute('CREATE TABLE "commandQueue" ("id" INTEGER,"steam" TEXT DEFAULT "0","command" TEXT,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
		connSQL:execute('CREATE TABLE "connectQueue" ("id" INTEGER,"steam" TEXT DEFAULT "0","command" TEXT,"processed" INTEGER DEFAULT 0,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
		connSQL:execute('CREATE TABLE "keystones" ("steam" TEXT,"x" INTEGER,"y" INTEGER,"z" INTEGER,"remove" INTEGER DEFAULT 0,"removed" INTEGER DEFAULT 0,"expired" INTEGER DEFAULT 0,PRIMARY KEY("steam","x","y","z"))') -- converted
		connSQL:execute('CREATE TABLE "LKPQueue" ("id" INTEGER,"line" TEXT, PRIMARY KEY("id" AUTOINCREMENT))') -- converted
		connSQL:execute('CREATE TABLE "locationSpawns" ("id" INTEGER,"location" TEXT,"x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,	PRIMARY KEY("id" AUTOINCREMENT))') -- converted
		connSQL:execute('CREATE TABLE "lottery" ("steam" TEXT DEFAULT "0", "ticket" INTEGER DEFAULT 0,PRIMARY KEY("steam","ticket"))') -- converted
		connSQL:execute('CREATE TABLE "mail" ("id" INTEGER,"sender" TEXT DEFAULT "0","recipient" TEXT DEFAULT "0","message" TEXT,"status" INTEGER DEFAULT 0,"flag" TEXT,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
		connSQL:execute('CREATE TABLE "messageQueue" ("id" INTEGER,"sender" TEXT DEFAULT "0","recipient" TEXT DEFAULT "0","message" TEXT,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
		connSQL:execute('CREATE TABLE "miscQueue" ("id" INTEGER,"steam" TEXT DEFAULT "0","command" TEXT,"action" TEXT,"value" INTEGER DEFAULT 0,"timerDelay" INTEGER DEFAULT 0,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
		connSQL:execute('CREATE TABLE "playerQueue" ("id" INTEGER,"command" TEXT,"arena" INTEGER DEFAULT 0,"boss" INTEGER DEFAULT 0,"steam" TEXT DEFAULT "0","delayTimer" INTEGER DEFAULT 0,PRIMARY KEY("id" AUTOINCREMENT))') -- converted
		connSQL:execute('CREATE TABLE "prefabCopies" ("owner" TEXT,"name" TEXT,"x1" INTEGER DEFAULT 0,"x2" INTEGER DEFAULT 0,"y1" INTEGER DEFAULT 0,"y2" INTEGER DEFAULT 0,"z1" INTEGER DEFAULT 0,"z2" INTEGER DEFAULT 0,"blockName" TEXT,"rotation" INTEGER DEFAULT 0,PRIMARY KEY("owner","name"))') -- converted
		connSQL:execute('CREATE TABLE "proxies" ("scanString" TEXT,"action" TEXT DEFAULT "nothing","hits" INTEGER DEFAULT 0,PRIMARY KEY("scanString"))') -- converted

		connTRAK:execute('CREATE TABLE "inventoryChanges" ("steam" INTEGER,"timestamp" INTEGER,"item" TEXT,"delta" INTEGER DEFAULT 0,"x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,"session" INTEGER DEFAULT 0,"flag" TEXT,PRIMARY KEY("steam","timestamp"))')
		connTRAK:execute('CREATE TABLE "inventoryTracker" ("steam" TEXT,"timestamp" INTEGER,"belt" TEXT,"pack" TEXT,"equipment" TEXT,"session" INTEGER DEFAULT 0,"x" INTEGER DEFAULT 0,"y" INTEGER DEFAULT 0,"z" INTEGER DEFAULT 0,PRIMARY KEY("steam","timestamp"))')

		-- copy data from mariadb to sqlite


		-- locationSpawns
		cursor,errorString = conn:execute("SELECT * FROM locationSpawns")
		row = cursor:fetch({}, "a")

		while row do
			connSQL:execute('INSERT INTO locationSpawns (id, location, x, y, z) VALUES (' .. row.id .. ',"' .. connMEM:escape(row.location) .. '",' .. row.x .. ',' .. row.y .. ',' .. row.z .. ')')
			row = cursor:fetch(row, "a")
		end
		--conn:execute("TRUNCATE locationSpawns")


		-- lottery
		cursor,errorString = conn:execute("SELECT * FROM lottery")
		row = cursor:fetch({}, "a")

		while row do
			connSQL:execute('INSERT INTO lottery (steam, ticket) VALUES ("' .. row.steam .. '",' .. row.ticket .. ')')
			row = cursor:fetch(row, "a")
		end
		--conn:execute("TRUNCATE lottery")

		-- -- altertables
		-- cursor,errorString = conn:execute("SELECT * FROM altertables")
		-- row = cursor:fetch({}, "a")

		-- while row do
			-- connSQL:execute('INSERT INTO altertables (id, statement) VALUES (' .. row.id .. ',"' .. connMEM:escape(row.statement) .. '")')
			-- row = cursor:fetch(row, "a")
		-- end
		-- --conn:execute("TRUNCATE altertables")


		-- bookmarks
		cursor,errorString = conn:execute("SELECT * FROM bookmarks")
		row = cursor:fetch({}, "a")

		while row do
			connSQL:execute('INSERT INTO bookmarks (id, steam, x, y, z, note) VALUES (' .. row.id .. ',"' .. row.steam .. '",' .. row.x .. ',' .. row.y .. ',' .. row.z .. ',"' .. connMEM:escape(row.note) .. '")')
			row = cursor:fetch(row, "a")
		end
		--conn:execute("TRUNCATE bookmarks")


		-- mail
		cursor,errorString = conn:execute("SELECT * FROM mail")
		row = cursor:fetch({}, "a")

		while row do
			connSQL:execute('INSERT INTO mail (id, sender, recipient, message, status, flag) VALUES (' .. row.id .. ',"' .. row.sender .. '","' .. row.recipient .. '","' .. connMEM:escape(row.message) .. '",' .. row.status .. ',"' .. row.flag .. '")')
			row = cursor:fetch(row, "a")
		end
		--conn:execute("TRUNCATE mail")


		-- prefabCopies
		cursor,errorString = conn:execute("SELECT * FROM prefabCopies")
		row = cursor:fetch({}, "a")

		while row do
			connSQL:execute('INSERT INTO prefabCopies (owner, name, x1, x2, y1, y2, z1, z2, blockName, rotation) VALUES ("' .. row.owner .. '","' .. connMEM:escape(row.name) .. '",' .. row.x1 .. ',' .. row.x2 .. ',' .. row.y1 .. ',' .. row.y2 .. ',' .. row.z1 .. ',' .. row.z2 .. ',"' .. row.blockName .. '",' .. row.rotation .. ')')
			row = cursor:fetch(row, "a")
		end
		--conn:execute("TRUNCATE prefabCopies")


		-- proxies
		cursor,errorString = conn:execute("SELECT * FROM proxies")
		row = cursor:fetch({}, "a")

		while row do
			connSQL:execute('INSERT INTO proxies (scanString, action, hits) VALUES ("' .. connMEM:escape(row.scanString) .. '","' .. row.action .. '",' .. row.hits .. ')')
			row = cursor:fetch(row, "a")
		end
		--conn:execute("TRUNCATE proxies")


		-- keystones
		cursor,errorString = conn:execute("SELECT * FROM keystones")
		row = cursor:fetch({}, "a")

		while row do
			connSQL:execute('INSERT INTO keystones (steam, x, y, z, remove, removed, expired) VALUES ("' .. row.steam .. '",' .. row.x .. ',' .. row.y .. ',' .. row.z .. ',' .. row.remove .. ',' .. row.removed .. ',' .. row.expired .. ')')
			row = cursor:fetch(row, "a")
		end
		--conn:execute("TRUNCATE keystones")
	end
end