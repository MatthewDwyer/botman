--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function ResetBot()
	dbug("Archiving data")
	saveLuaTables(os.date("%Y%m%d_%H%M%S"))

	-- save some additional tables in from mysql
	dumpTable("events")
	dumpTable("announcements")
	dumpTable("locationSpawns")
	dumpTable("alerts")

	dbug("Running ResetBot")

	for k,v in pairs(players) do
		v.xPos = 0
		v.yPos = 0
		v.zPos = 0
		v.xPosOld = 0
		v.yPosOld = 0
		v.zPosOld = 0
		v.exitX = 0
		v.exitY = 0
		v.exitZ = 0
		v.exit2X = 0
		v.exit2Y = 0
		v.exit2Z = 0
		v.baseCooldown = 0		
		v.protect = false
		v.protectSize = 32
		v.protect2 = false
		v.protect2Size = 32
		v.homeX = 0
		v.homeY = 0
		v.homeZ = 0
		v.home2X = 0
		v.home2Y = 0
		v.home2Z = 0		
		v.timeout = false
		v.alertPrison = true
		v.alertReset = true
		v.alertMapLimit = false
		v.sessionCount = 1
		v.watchPlayer = false
		v.lastBaseRaid = 0
		v.zombies = 0
		v.cash = 0
		v.overstack = false
		v.overstackScore = 0
		v.overstackItems = ""
		v.overstackTimeout = false
		v.gimmeCount = 0
		v.raiding = false
		v.playerKills = 0
		v.score = 0
		v.deaths = 0
		v.alertRemovedClaims = false
		v.removedClaims = 0
		v.pvpBounty = 0
		v.tokens = 0
		v.keystones = 0
		
		-- remove some fields
		v.santa = nil
		v.protection = nil
		v.protectionSize = nil
		v.lobby = nil
		v.waypointY = nil
		v.waypointX = nil
		v.waypointZ = nil
		v.shareWaypoint = nil
		v.baseprotection = nil	

		updatePlayer(k)	
	end	
	
	-- clean up other tables
	teleports = {}
	invTemp = {}
	hotspots = {}
	resetRegions = {}
	lastHotspots = {}
	villagers = {}
	locations = {}

	server.lottery = 0
	server.mapSize = 20000
	server.prisonSize = 300
	server.warnBotReset = false

	dbug("Emptying tables")

	conn:execute("TRUNCATE TABLE alerts")
	conn:execute("TRUNCATE TABLE bookmarks")
	conn:execute("TRUNCATE TABLE commandQueue")
	conn:execute("TRUNCATE TABLE events")
	conn:execute("TRUNCATE TABLE gimmeQueue")
	conn:execute("TRUNCATE TABLE hotspots")
	conn:execute("TRUNCATE TABLE ircQueue")
	conn:execute("TRUNCATE TABLE keystones")
	conn:execute("TRUNCATE TABLE locations")
	conn:execute("TRUNCATE TABLE locationSpawns")
	conn:execute("TRUNCATE TABLE lottery")
	conn:execute("TRUNCATE TABLE mail")
	conn:execute("TRUNCATE TABLE memLottery")
	conn:execute("TRUNCATE TABLE memTracker")
	conn:execute("TRUNCATE TABLE messageQueue")
	conn:execute("TRUNCATE TABLE performance")
	conn:execute("TRUNCATE TABLE playerQueue")
	conn:execute("TRUNCATE TABLE resetZones")
	conn:execute("TRUNCATE TABLE teleports")
	conn:execute("TRUNCATE TABLE tracker")
	conn:execute("TRUNCATE TABLE searchResults")
	conn:execute("TRUNCATE TABLE villagers")
	conn:execute("TRUNCATE TABLE visits")
	conn:execute("TRUNCATE TABLE inventoryChanges")
	conn:execute("TRUNCATE TABLE inventoryTracker")

	dbug("Reading server, players, bans and admin data")

	send("lkp")
	tempTimer( 10, [[send("pm IPCHECK")]] )
	tempTimer( 12, [[send("admin list")]] )
	tempTimer( 14, [[send("gg")]] )
	tempTimer( 16, [[send("ban list")]] )

	dbug("Finished resetting bot")
	return true
end


function ResetServer()
	-- This will wipe everything from the bot about the server and its players and it will ask the server for players and other info.
	-- For anything else, default values will be set until you change them.

	serverTime = ""
	feralWarning = false
	scheduledReboot = false
	homedir = getMudletHomeDir()

	lfs.mkdir(homedir .. "/daily")
	lfs.mkdir(homedir .. "/dns")
	lfs.mkdir(homedir .. "/temp")

	players = {}
	igplayers = {}
	teleports = {}
	admins = {}
	friends = {}
	locations = {}
	server = {}
	invTemp = {}
	hotspots = {}
	resetRegions = {}
	gimmeQueuedCommands = {}
	lastHotspots = {}
	villagers = {}
	owners = {}
	mods = {}
	shop = {}
	shopCategories = {}
	stackLimits = {}

	openUserWindow(server.windowGMSG) 
	openUserWindow(server.windowDebug) 
	openUserWindow(server.windowLists) 
	openUserWindow(server.windowPlayers) 
	openUserWindow(server.windowAlerts) 

	dbug("Resetting Bot (full wipe)")

	yourname = "your steam id here"

	if (ExceptionCount == nil) then
		ExceptionCount = 0
	end

	AnnounceBot = true
	botStarted = os.time()
	faultyGimme = false
	faultyChat = false
	gimmeHell = 0
	server.scheduledRestartPaused  = false
	server.scheduledRestart = false
	ExceptionRebooted = false

	if server.lottery == nil then
		server.lottery = 0
	end

	conn:execute("TRUNCATE TABLE players")
	conn:execute("TRUNCATE TABLE whitelist")

	ResetBot()
	initServer()

	botStarted = nil
	login()
end
