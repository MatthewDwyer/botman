--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]


function quickBotReset()
	-- reset stuff but don't touch players or locations or reset zones.
	teleports = {}
	invTemp = {}
	hotspots = {}
	lastHotspots = {}
	villagers = {}

	server.lottery = 0
	server.mapSize = 10000

	-- empty tables in mysql
	conn:execute("TRUNCATE TABLE alerts")
	conn:execute("TRUNCATE TABLE events")
	conn:execute("TRUNCATE TABLE hotspots")
	conn:execute("TRUNCATE TABLE performance")
	conn:execute("TRUNCATE TABLE polls")
	conn:execute("TRUNCATE TABLE pollVotes")
	conn:execute("TRUNCATE TABLE teleports")
	conn:execute("TRUNCATE TABLE waypoints")

	-- empty tables in sqlite
	connSQL:execute("DELETE FROM bookmarks")
	connSQL:execute("DELETE FROM commandQueue")
	connSQL:execute("DELETE FROM connectQueue")
	connSQL:execute("DELETE FROM keystones")
	connSQL:execute("DELETE FROM lottery")
	connSQL:execute("DELETE FROM mail")
	connSQL:execute("DELETE FROM messageQueue")
	connSQL:execute("DELETE FROM miscQueue")
	connSQL:execute("DELETE FROM playerQueue")

	connMEM:execute("DELETE FROM gimmeQueue")
	connMEM:execute("DELETE FROM ircQueue")
	connMEM:execute("DELETE FROM list")
	connMEM:execute("DELETE FROM list2")
	connMEM:execute("DELETE FROM tracker")
	connMEM:execute("DELETE FROM searchResults")

	connTRAK:execute("DELETE FROM tracker")
	connTRAKSHADOW:execute("DELETE FROM tracker")

	connINVDELTA:execute("DELETE FROM inventoryChanges")
	connINVTRAK:execute("DELETE FROM inventoryTracker")

	-- remove a flag so that the bot will re-test for installed mods.
	botMaintenance.modsInstalled = false
	saveBotMaintenance()
end


function resetBases()
	conn:execute("TRUNCATE TABLE bases")
	conn:execute("UPDATE players SET baseCooldown=0")
	loadPlayers()
end


function ResetBot(keepTheMoney, backupName)
	if backupName then
		saveLuaTables(os.date("%Y%m%d_%H%M%S"), backupName)
	else
		saveLuaTables(os.date("%Y%m%d_%H%M%S"))
	end

	-- save some additional tables from mysql
	dumpTable("events")
	dumpTable("announcements")
	dumpTable("alerts")

	-- and sqlite
	dumpSQLiteTable("locationSpawns")

	-- clean up other tables
	bases = {}
	teleports = {}
	invTemp = {}
	hotspots = {}
	keystones = {}
	resetRegions = {}
	lastHotspots = {}
	stackLimits = {}
	villagers = {}
	locations = {}
	waypoints = {}

	server.lottery = 0
	server.warnBotReset = false
	server.playersCanFly = true

	-- empty tables in mysql
	conn:execute("TRUNCATE TABLE alerts")
	conn:execute("TRUNCATE TABLE bases")
	conn:execute("TRUNCATE TABLE events")
	conn:execute("TRUNCATE TABLE hotspots")
	conn:execute("TRUNCATE TABLE locations")
	conn:execute("TRUNCATE TABLE performance")
	conn:execute("TRUNCATE TABLE polls")
	conn:execute("TRUNCATE TABLE pollVotes")
	conn:execute("TRUNCATE TABLE reservedSlots")
	conn:execute("TRUNCATE TABLE resetZones")
	conn:execute("TRUNCATE TABLE teleports")
	conn:execute("TRUNCATE TABLE villagers")
	conn:execute("TRUNCATE TABLE waypoints")

	-- empty tables in sqlite
	connSQL:execute("DELETE FROM bookmarks")
	connSQL:execute("DELETE FROM commandQueue")
	connSQL:execute("DELETE FROM connectQueue")
	connSQL:execute("DELETE FROM keystones")
	connSQL:execute("DELETE FROM locationSpawns")
	connSQL:execute("DELETE FROM lottery")
	connSQL:execute("DELETE FROM mail")
	connSQL:execute("DELETE FROM messageQueue")
	connSQL:execute("DELETE FROM miscQueue")
	connSQL:execute("DELETE FROM playerQueue")
	connSQL:execute("DELETE FROM prefabCopies")

	connMEM:execute("DELETE FROM tracker")
	connMEM:execute("DELETE FROM list")
	connMEM:execute("DELETE FROM list2")
	connMEM:execute("DELETE FROM gimmeQueue")
	connMEM:execute("DELETE FROM ircQueue")
	connMEM:execute("DELETE FROM searchResults")

	connTRAK:execute("DELETE FROM tracker")
	connTRAKSHADOW:execute("DELETE FROM tracker")

	connINVDELTA:execute("DELETE FROM inventoryChanges")
	connINVTRAK:execute("DELETE FROM inventoryTracker")

	-- reset some data in the players table
	sql = "UPDATE players SET bail=0, bed='', bedX=0, bedY=0, bedZ=0, deaths=0, xPos=0, xPosOld=0, yPos=0, yPosOld=0, zPos=0, zPosOld=0, exiled=0, keystones=0, location='lobby', canTeleport=1, botTimeout=0, allowBadInventory=0, baseCooldown=0, overstackTimeout=0, playerKills=0, prisoner=0, prisonReason='', prisonReleaseTime=0, prisonxPosOld=0, prisonyPosOld=0, prisonzPosOld=0, pvpBounty=0, pvpCount=0, pvpVictim='0', score=0, sessionCount=0, silentBob=0, walkies=0, zombies=0, timeout=0"

	if keepTheMoney == nil then
		sql = sql .. ", cash=0"
	end

	conn:execute(sql)
	getServerData(true)

	-- remove a flag so that the bot will re-test for installed mods.
	botMaintenance.modsInstalled = false
	saveBotMaintenance()

	if server.botman then
		tempTimer( 1, [[sendCommand("bm-resetregions clearall")]] )
	end

	if botman.resetServer then
		botman.resetServer = nil
		restartBot()
	else
		loadTables()
	end
end


function ResetServer()
	-- This will wipe everything from the bot about the server and its players and it will ask the server for players and other info.
	-- For anything else, default values will be set until you change them.

	saveLuaTables(os.date("%Y%m%d_%H%M%S"), "undo_reset_server")

	botman.resetServer = true
	botman.serverTime = ""
	botman.feralWarning = false
	homedir = getMudletHomeDir()

	lfs.mkdir(homedir .. "/daily")
	lfs.mkdir(homedir .. "/dns")
	lfs.mkdir(homedir .. "/temp")
	lfs.mkdir(homedir .. "/chatlogs")
	lfs.mkdir(homedir .. "/data_backup")

	friends = {}
	gimmeQueuedCommands = {}
	hotspots = {}
	igplayers = {}
	invTemp = {}
	lastHotspots = {}
	locations = {}
	resetRegions = {}
	shopCategories = {}
	stackLimits = {}
	teleports = {}
	villagers = {}
	waypoints = {}

	if (botman.ExceptionCount == nil) then
		botman.ExceptionCount = 0
	end

	botman.announceBot = true
	botman.botStarted = os.time()
	botman.faultyGimme = false
	botman.faultyChat = false
	botman.gimmeHell = 0
	botman.scheduledRestartPaused  = false
	botman.scheduledRestart = false
	botman.ExceptionRebooted = false

	if server.lottery == nil then
		server.lottery = 0
	end

	forgetPlayers() -- forget Freeman
	ResetBot()
end
