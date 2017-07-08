--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function QuickBotReset()
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
	conn:execute("TRUNCATE TABLE events")
	conn:execute("TRUNCATE TABLE gimmeQueue")
	conn:execute("TRUNCATE TABLE hotspots")
	conn:execute("TRUNCATE TABLE ircQueue")
	conn:execute("TRUNCATE TABLE keystones")
	conn:execute("TRUNCATE TABLE lottery")
	conn:execute("TRUNCATE TABLE mail")
	conn:execute("TRUNCATE TABLE memLottery")
	conn:execute("TRUNCATE TABLE memTracker")
	conn:execute("TRUNCATE TABLE messageQueue")
	conn:execute("TRUNCATE TABLE miscQueue")
	conn:execute("TRUNCATE TABLE performance")
	conn:execute("TRUNCATE TABLE playerQueue")
	conn:execute("TRUNCATE TABLE polls")
	conn:execute("TRUNCATE TABLE pollVotes")
	conn:execute("TRUNCATE TABLE teleports")
	conn:execute("TRUNCATE TABLE tracker")
	conn:execute("TRUNCATE TABLE searchResults")
	conn:execute("TRUNCATE TABLE villagers")
	conn:execute("TRUNCATE TABLE inventoryChanges")
	conn:execute("TRUNCATE TABLE inventoryTracker")
	conn:execute("TRUNCATE TABLE waypoints")
end


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
		v.alertMapLimit = false
		v.alertPrison = true
		v.alertRemovedClaims = false
		v.alertReset = true
		v.allowBadInventory=false
		v.bail=0
		v.baseCooldown = 0
		v.bed=""
		v.bedX=0
		v.bedY=0
		v.bedZ=0
		v.botTimeout=false
		v.canTeleport=true
		v.cash = 0
		v.deaths = 0
		v.exiled=false
		v.exit2X = 0
		v.exit2Y = 0
		v.exit2Z = 0
		v.exitX = 0
		v.exitY = 0
		v.exitZ = 0
		v.gimmeCount = 0
		v.home2X = 0
		v.home2Y = 0
		v.home2Z = 0
		v.homeX = 0
		v.homeY = 0
		v.homeZ = 0
		v.keystones = 0
		v.lastBaseRaid = 0
		v.location = "lobby"
		v.overstack = false
		v.overstackItems = ""
		v.overstackScore = 0
		v.overstackTimeout = false
		v.playerKills = 0
		v.prisoner=false
		v.prisonReason=""
		v.prisonReleaseTime=0
		v.prisonxPosOld=0
		v.prisonyPosOld=0
		v.prisonzPosOld=0
		v.protect = false
		v.protect2 = false
		v.protect2Size = 41
		v.protectSize = 41
		v.pvpBounty = 0
		v.pvpCount=0
		v.pvpVictim=0
		v.raiding = false
		v.removedClaims = 0
		v.score = 0
		v.sessionCount = 0
		v.silentBob=false
		v.timeout = false
		v.tokens = 0
		v.walkies=false
		v.watchCash=false
		v.watchPlayer = false
		v.xPos = 0
		v.xPosOld = 0
		v.yPos = 0
		v.yPosOld = 0
		v.zombies = 0
		v.zPos = 0
		v.zPosOld = 0

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
	waypoints = {}

	server.lottery = 0
	server.mapSize = 10000
	server.prisonSize = 100
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
	conn:execute("TRUNCATE TABLE miscQueue")
	conn:execute("TRUNCATE TABLE performance")
	conn:execute("TRUNCATE TABLE playerQueue")
	conn:execute("TRUNCATE TABLE polls")
	conn:execute("TRUNCATE TABLE pollVotes")
	conn:execute("TRUNCATE TABLE resetZones")
	conn:execute("TRUNCATE TABLE teleports")
	conn:execute("TRUNCATE TABLE tracker")
	conn:execute("TRUNCATE TABLE searchResults")
	conn:execute("TRUNCATE TABLE villagers")
	conn:execute("TRUNCATE TABLE inventoryChanges")
	conn:execute("TRUNCATE TABLE inventoryTracker")
	conn:execute("TRUNCATE TABLE waypoints")

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

	botman.serverTime = ""
	botman.feralWarning = false
	homedir = getMudlethomedir()

	lfs.mkdir(homedir .. "/daily")
	lfs.mkdir(homedir .. "/dns")
	lfs.mkdir(homedir .. "/temp")
	lfs.mkdir(homedir .. "/chatlogs")
	lfs.mkdir(homedir .. "/data_backup")

	admins = {}
	friends = {}
	gimmeQueuedCommands = {}
	hotspots = {}
	igplayers = {}
	invTemp = {}
	lastHotspots = {}
	locations = {}
	mods = {}
	owners = {}
	players = {}
	resetRegions = {}
	server = {}
	shop = {}
	shopCategories = {}
	stackLimits = {}
	teleports = {}
	villagers = {}
	waypoints = {}

	openUserWindow(server.windowGMSG)
	openUserWindow(server.windowDebug)
	openUserWindow(server.windowLists)

	dbug("Resetting Bot (full wipe)")

	Smegz0r = "76561197983251951"

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

	conn:execute("TRUNCATE TABLE players")
	conn:execute("TRUNCATE TABLE whitelist")

	ResetBot()
	initServer()

	botman.botStarted = nil
	login()
end
