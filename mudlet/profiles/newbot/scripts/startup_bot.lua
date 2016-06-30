--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	          This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug

function checkData()
	if server.botName == nil then
		loadServer()
		botStarted = nil
		login()
	end

	if tablelength(shopCategories) == 0 then
		loadShopCategories()		
	end

	if tablelength(owners) == 0 then
		send("admin list")
	end

	if tonumber(server.ServerPort) == 0 then
		send("gg")
	end

	if (playersOnline > 0) then
		if 	tablelength(igplayers) == 0 then
			igplayers = {}
			send("lp")
		end
	end
end


function getServerData()
	tempTimer( 2, [[send("ban list")]] )
	dbug("ban list")

	tempTimer( 5, [[send("lkp")]] )
	dbug("lkp")

	tempTimer( 8, [[send("llp")]] )
	dbug("llp")

	tempTimer( 8, [[send("admin list")]] )
	dbug("admin list")

	tempTimer( 10, [[send("pm IPCHECK")]] )
	dbug("ipcheck")

	tempTimer( 11, [[send("teleh")]] )
	dbug("coppi test")
	
	tempTimer( 12, [[send("ubex_ubexv")]] )
	dbug("ubex test")

	tempTimer( 13, [[send("gg")]] )
	dbug("gg")

	tempTimer( 15, [[registerBot()]] )
	dbug("registerBot")

	if db2Connected then
		tempTimer( 17, [[getWhitelistedServers()]] )
		dbug("getWhitelistedServers")
	end
end


function login()
	debug = false
	debugdb = false
	
	if type(server) ~= "table" then
		server = {}
		scheduledReboot = false
		scheduledRestartPaused = false
		scheduledRestartForced = false
		server.scheduledIdleRestart = false
		server.scheduledRestart = false
		server.scheduledRestartTimestamp = os.time()
	end	

	if reloadBotScripts == nil then
		dofile(homedir .. "/scripts/reload_bot_scripts.lua")
		reloadBotScripts()
	end

	tempTimer( 30, [[checkData()]] )

	stackLimits = {}

	if (botStarted == nil) then
		botStarted = os.time()
		
		initBot()

		openDB()
		initDB()
		openBotsDB()

		dbConnected = isDBConnected()
		db2Connected = isDBBotsConnected()

		initError = true
		serverTime = ""
		feralWarning = false
		scheduledReboot = false
		userHome = string.sub(homedir, 1, string.find(homedir, ".config") - 2)

		fixMissingStuff()

		loadServer()
		
		server.webdavFolderExists = true
		if not isDir("/var/www/webdav/chatlogs/" .. webdavFolder) then
			server.webdavFolderExists = false
		end

		openUserWindow(server.windowGMSG) 
		openUserWindow(server.windowDebug) 
		openUserWindow(server.windowLists) 
		openUserWindow(server.windowPlayers) 
		openUserWindow(server.windowAlerts) 

		if not botDisabled and botTick == nil then
			botTick = readBotTick()
			tempTimer( 58, [[checkBotTick()]] )
		end

		if debug then dbug("debug login 1\n") end

		if type(igplayers) ~= "table" then
		  igplayers = {}
		end

		if type(owners) ~= "table" then
		  owners = {}
		end

		if type(admins) ~= "table" then
		  admins = {}
		end

		if type(mods) ~= "table" then
		  mods = {}
		end

		if type(friends) ~= "table" then
		  friends = {}
		end

		if type(invTemp) ~= "table" then
		  invTemp = {}
		end

		if type(hotspots) ~= "table" then
		  hotspots = {}
		end

		if type(badItems) ~= "table" then
		  badItems = {}
		end

		if type(restrictedItems) ~= "table" then
		  restrictedItems = {}
		end

		if type(lastHotspots) ~= "table" then
			lastHotspots = {}
		end

		if type(villagers) ~= "table" then
		  villagers = {}
		end

		if type(shopCategories) ~= "table" then
			shopCategories = {}
		end

		if type(stackLimits) ~= "table" then
			stackLimits = {}
		end

		if type(customMessages) ~= "table" then
		  customMessages = {}
		end

		if type(reservedSlots) ~= "table" then
			reservedSlots = {}
		end

		if type(proxies) ~= "table" then
			proxies = {}
		end

		if type(whitelistedServers) ~= "table" then
			whitelistedServers = {}
		end

		if debug then dbug("debug login 2\n") end

		-- add your steam id here so you can debug using your name
		yourname = "your steam id here"

		if (ExceptionCount == nil) then
			ExceptionCount = 0
		end

		AnnounceBot = true
		faultyGimme = false
		faultyGimmeNumber = 0
		faultyChat = false
		gimmeHell = 0
		server.scheduledRestartPaused  = false
		server.scheduledRestart = false
		ExceptionRebooted = false
		scanZombies = false

		-- load tables
		loadTables()

		-- set all players to offline in cloud db
		cleanupBotsData()

		if debug then dbug("debug login 5\n") end

		nextRebootTest = nil
		initError = false
	end

	if debug then dbug("debug login end\n") end
end
