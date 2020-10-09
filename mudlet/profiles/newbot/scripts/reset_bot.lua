--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
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

	conn:execute("TRUNCATE TABLE alerts")
	conn:execute("TRUNCATE TABLE bookmarks")
	conn:execute("TRUNCATE TABLE commandQueue")
	conn:execute("TRUNCATE TABLE connectQueue")
	conn:execute("TRUNCATE TABLE events")
	connMEM:execute("DELETE FROM gimmeQueue")
	conn:execute("TRUNCATE TABLE hotspots")
	connMEM:execute("DELETE FROM ircQueue")
	conn:execute("TRUNCATE TABLE keystones")
	connMEM:execute("DELETE FROM list")
	connMEM:execute("DELETE FROM list2")
	conn:execute("TRUNCATE TABLE lottery")
	conn:execute("TRUNCATE TABLE mail")
	conn:execute("TRUNCATE TABLE memLottery")
	conn:execute("DELETE FROM memTracker")
	conn:execute("TRUNCATE TABLE messageQueue")
	conn:execute("TRUNCATE TABLE miscQueue")
	conn:execute("TRUNCATE TABLE performance")
	conn:execute("TRUNCATE TABLE playerQueue")
	conn:execute("TRUNCATE TABLE polls")
	conn:execute("TRUNCATE TABLE pollVotes")
	conn:execute("TRUNCATE TABLE teleports")
	conn:execute("TRUNCATE TABLE tracker")
	connMEM:execute("DELETE FROM searchResults")
	conn:execute("TRUNCATE TABLE inventoryChanges")
	conn:execute("TRUNCATE TABLE inventoryTracker")
	conn:execute("TRUNCATE TABLE waypoints")

	-- remove a flag so that the bot will re-test for installed mods.
	botMaintenance.modsInstalled = false
	saveBotMaintenance()
end


function resetBases()
	local sql

	conn:execute("TRUNCATE TABLE bases")

	-- reset bases in the players table
	sql = "UPDATE players SET homeX=0, home2X=0, homeY=0, home2Y=0, homeZ=0, home2Z=0, exitX=0, exit2X=0, exitY=0, exit2Y=0, exitZ=0, exit2Z=0, baseCooldown=0, protect=0, protect2=0, protectSize=" .. server.LandClaimSize .. ", protect2Size=" .. server.LandClaimSize
	conn:execute(sql)
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
	dumpTable("locationSpawns")
	dumpTable("alerts")

	-- clean up other tables
	teleports = {}
	invTemp = {}
	hotspots = {}
	resetRegions = {}
	lastHotspots = {}
	stackLimits = {}
	villagers = {}
	locations = {}
	waypoints = {}

	server.lottery = 0
	server.warnBotReset = false
	server.playersCanFly = true

	conn:execute("TRUNCATE TABLE alerts")
	conn:execute("TRUNCATE TABLE bases")
	conn:execute("TRUNCATE TABLE bookmarks")
	conn:execute("TRUNCATE TABLE commandQueue")
	conn:execute("TRUNCATE TABLE connectQueue")
	conn:execute("TRUNCATE TABLE events")
	connMEM:execute("DELETE FROM gimmeQueue")
	conn:execute("TRUNCATE TABLE hotspots")
	connMEM:execute("DELETE FROM ircQueue")
	conn:execute("TRUNCATE TABLE keystones")
	connMEM:execute("DELETE FROM list")
	connMEM:execute("DELETE FROM list2")
	conn:execute("TRUNCATE TABLE locations")
	conn:execute("TRUNCATE TABLE locationSpawns")
	conn:execute("TRUNCATE TABLE lottery")
	conn:execute("TRUNCATE TABLE mail")
	conn:execute("TRUNCATE TABLE memLottery")
	conn:execute("DELETE FROM memTracker")
	conn:execute("TRUNCATE TABLE messageQueue")
	conn:execute("TRUNCATE TABLE miscQueue")
	conn:execute("TRUNCATE TABLE performance")
	conn:execute("TRUNCATE TABLE playerQueue")
	conn:execute("TRUNCATE TABLE polls")
	conn:execute("TRUNCATE TABLE pollVotes")
	conn:execute("TRUNCATE TABLE prefabCopies")
	conn:execute("TRUNCATE TABLE reservedSlots")
	conn:execute("TRUNCATE TABLE resetZones")
	conn:execute("TRUNCATE TABLE teleports")
	conn:execute("TRUNCATE TABLE tracker")
	connMEM:execute("DELETE FROM searchResults")
	conn:execute("TRUNCATE TABLE villagers")
	conn:execute("TRUNCATE TABLE inventoryChanges")
	conn:execute("TRUNCATE TABLE inventoryTracker")
	conn:execute("TRUNCATE TABLE waypoints")

	-- reset some data in the players table
	sql = "UPDATE players SET bail=0, bed='', bedX=0, bedY=0, bedZ=0, deaths=0, xPos=0, xPosOld=0, yPos=0, yPosOld=0, zPos=0, zPosOld=0, homeX=0, home2X=0, homeY=0, home2Y=0, homeZ=0, home2Z=0, exitX=0, exit2X=0, exitY=0, exit2Y=0, exitZ=0, exit2Z=0, exiled=0, keystones=0, location='lobby', canTeleport=1, botTimeout=0, allowBadInventory=0, baseCooldown=0, overstackTimeout=0, playerKills=0, prisoner=0, prisonReason='', prisonReleaseTime=0, prisonxPosOld=0, prisonyPosOld=0, prisonzPosOld=0, protect=0, protect2=0, protectSize=" .. server.LandClaimSize .. ", protect2Size=" .. server.LandClaimSize .. ", pvpBounty=0, pvpCount=0, pvpVictim=0, score=0, sessionCount=0, silentBob=0, walkies=0, zombies=0, timeout=0"

	if keepTheMoney == nil then
		sql = sql .. ", cash=0"
	end

	conn:execute(sql)
	loadPlayers()
	getServerData(true)

	-- remove a flag so that the bot will re-test for installed mods.
	botMaintenance.modsInstalled = false
	saveBotMaintenance()

	if botman.resetServer then
		botman.resetServer = nil
		restartBot()
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

	forgetPlayers()
	ResetBot()
end
