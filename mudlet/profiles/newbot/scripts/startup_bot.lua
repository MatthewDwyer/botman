--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	          This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

debugger = require "debug"
mysql = require "luasql.mysql"
local debug

if not telnetLogFileName then
	lfs.mkdir(homedir .. "/telnet_logs")
	telnetLogFileName = homedir .. "/telnet_logs/" .. os.date("%Y-%m-%d#%H-%M-%S") .. ".txt"
	telnetLogFile = io.open(telnetLogFileName, "a")
end


function dbugi(text)
	-- send text to the special debug irc channel
	if server ~= nil then
		irc_chat(server.ircMain .. "_debug", text)
	end
end


function dbug(text)
	-- send text to the debug window we created in Mudlet.
	if type(server) ~= "table" then
		display(text .. "\n")
		return
	end

	if not server.enableWindowMessages then
		server.enableWindowMessages = true
	end

	if server.windowLists then
		windowMessage(server.windowLists, text .. "\n")
	end
end


function checkData()
	if botman.botOffline then
		return
	end

	if server.botName == nil then
		loadServer()
		botman.botStarted = nil
		login()
	end

	if tonumber(server.allocsMap) == 0 then
		sendCommand("version")
	end

	sendCommand("gt")

	if server.botman then
		sendCommand("bm-uptime")
		sendCommand("bm-resetregions list")
		sendCommand("bm-anticheat report")
	end

	if tablelength(shopCategories) == 0 then
		loadShopCategories()
	end

	if tonumber(server.ServerPort) == 0 then
		sendCommand("gg")
	else
		if tonumber(server.reservedSlots) > 0 then
			addOrRemoveSlots()
		end
	end

	if tablelength(staffList) == 0 then
		sendCommand("admin list")
	end

	sendCommand("llp parseable")
	gmsg(server.commandPrefix .. "register help")
end


function getServerData(getAllPlayers)
	if botman.botOffline then
		return
	end

	if getAllPlayers then
		reloadBot(getAllPlayers)
	else
		reloadBot()
	end
end


function login()
	local getAllPlayers = false
	local randomChannel, r, firstRun

	debug = false
	debugdb = false
	firstRun = false

	startLogging(false)
	os.remove(homedir .. "/chatlogs/debug.txt")

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	-- disable some stuff we no longer use
	disableTrigger("le")
	disableTimer("GimmeReset")
	disableTrigger("Zombie Scouts") -- trigger moved to match_all.lua

	if type(botStatus) ~= "table" then
		botStatus = {}
		botStatus.newBot = false
	end

	if type(botman) ~= "table" then
		firstRun = true

		botman = {}
		botman.gameStarted = true
		botman.botOffline = true
		botman.APIOffline = true
		botman.telnetOffline = true
		botman.serverStarting = false
		botman.playersOnline = 0
		botman.botConnectedTimestamp = os.time()
		botman.botOfflineCount = 0
		botman.telnetOfflineCount = 0
		botman.lastServerResponseTimestamp = os.time()
		botman.lastTelnetResponseTimestamp = os.time()
		botman.serverRebooting = false
		botman.scheduledRestartPaused = false
		botman.scheduledRestartForced = false
		botman.scheduledRestart = false
		botman.scheduledRestartTimestamp = os.time()
		botman.lastBlockCommandOwner =	0
		botman.initReservedSlots = true
		botman.webdavFolderWriteable = true
		botman.trackingTicker = 0
		botman.serverTimeStamp = 0
		botman.blockTelnetSpam = false

		if not botman.serverTimeSync then
			botman.serverTimeSync = 0
		end
	end

	if type(server) ~= "table" then
		server = {}
		getAllPlayers = true

		-- force the irc server to localhost so that we don't automatically join Freenode and the Mudlet channel if nothing else has been set.
		-- set some random irc channel name so that the bot should not join an existing channel with another bot in it if localhost has an irc server.
		math.randomseed(os.time())
		r = math.random(900) + 100
		randomChannel = "bot_" .. r
		server.ircServer = "127.0.0.1"
		server.ircMain = randomChannel
		server.ircAlerts = randomChannel .. "_alerts"
		server.ircWatch = randomChannel .. "_watch"
		server.ircPort = 6667
	end

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	botman.userHome = string.sub(homedir, 1, string.find(homedir, ".config") - 2)

	if botman.sysExitID == nil then
		botman.sysExitID = registerAnonymousEventHandler("sysExitEvent", "onSysExit")
		botman.sysExitID = 0
	end

	if botman.sysDisconnectionID == nil then
		botman.sysDisconnectionID = registerAnonymousEventHandler("sysDisconnectionEvent", "onSysDisconnection")
		botman.sysDisconnectionID = 0
	end

	if botman.sysDownloadDoneID == nil then
		botman.sysDownloadDoneID = registerAnonymousEventHandler("sysDownloadDone", "downloadHandler")
		botman.sysDownloadDoneID = 0
	end

	if botman.sysDownloadErrorID == nil then
		botman.sysDownloadErrorID = registerAnonymousEventHandler("sysDownloadError", "failDownload")
		botman.sysDownloadErrorID = 0
	end

	if botman.sysExitEventID == nil then
		botman.sysExitEventID = registerAnonymousEventHandler("sysExitEvent", "onCloseMudlet")
		botman.sysExitEventID = 0
	end

	if botman.sysPostHttpDoneID == nil then
		botman.sysPostHttpDoneID = registerAnonymousEventHandler("sysPostHttpDone", "onHttpPostDone")
		botman.sysPostHttpDoneID = 0
	end

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	if (botman.botStarted == nil) then
		botman.botStarted = os.time()

		if exists("APITimer", "timer") ~= 0 then
		  disableTimer("APITimer")
		end

		telnetLogFileName = homedir .. "/telnet_logs/" .. os.date("%Y-%m-%d#%H-%M-%S", os.time()) .. ".txt"
		telnetLogFile = io.open(telnetLogFileName, "a")

		if reloadBotScripts == nil then
			dofile(homedir .. "/scripts/reload_bot_scripts.lua")
			reloadBotScripts(false, false, false)
		end

		if firstRun then
			botStatus = {}
			botStatus.safeMode = false
			botStatus.firstRun = true
			botStatus.telnetSpamCount = 0
			botStatus.telnetSpamThreshold = 100
			botStatus.ranCheckData = false
			botStatus.playersOnline = 0
			botStatus.players = {}

			--toggleTriggers("stop") -- disable almost all triggers and timers
			-- just have the 5 second timer running first as we will use that to check telnet for evidence of a crashed server
			--enableTimer("Every5Seconds")
			--display("Bot is in safe mode")
		end

		if botman.blockTelnetSpam then
			if debug then
				botman.blockTelnetSpam = false
				tempTimer(30, [[setBlockTelnetSpam(true)]])
			end
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		-- this must come after reload_bot_scripts above.
		fixTables()

		openEarlySQLiteDB() -- this lives in sqlite.lua

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end
		initBot() -- this lives in edit_me.lua
		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end
		openDB() -- this lives in edit_me.lua
		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		openBotsDB() -- this lives in edit_me.lua
		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end
		initDB() -- this lives in mysql.lua
		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		botman.dbConnected = isDBConnected()
		botman.botsConnected = isDBBotsConnected()
		botman.initError = true
		botman.serverTime = ""
		botman.feralWarning = false
		botman.playersOnline = 0
		loadServer(true)
		botman.ignoreAdmins	= true

		if server.serverName == "New Server" then
			botStatus.newBot = true
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		if server.botID == nil then
			server.botID = 0
		end

		if not server.allocsMap then
			server.allocsMap = 0
		end

		botman.APIOffline = false

		if not botStatus.safeMode then
			toggleTriggers("api online")
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		botman.webdavFolderExists = true

		if botman.chatlogPath == nil then
			if not isDir(webdavFolder) then
				botman.webdavFolderExists = false
				botman.chatlogPath = homedir .. "/chatlogs"
			else
				botman.chatlogPath = webdavFolder
			end

			if botman.dbConnected then conn:execute("UPDATE server SET chatlogPath = '" .. escape(botman.chatlogPath) .. "'") end
		end

		openUserWindow(server.windowGMSG)
		openUserWindow(server.windowDebug)
		openUserWindow(server.windowLists)

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		if loadWindowLayout ~= nil then
			loadWindowLayout()
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		-- add your steam id here so you can debug using your name
		Smegz0r = "76561197983251951"
		Smegz0rEOS = "000236e4866847daa11cf36e1b8b630a"

		if (botman.ExceptionCount == nil) then
			botman.ExceptionCount = 0
		end

		botman.announceBot = true
		botman.alertMods = true
		botman.faultyGimme = false
		botman.faultyGimmeNumber = 0
		botman.faultyChat = false
		botman.gimmeHell = 0
		botman.scheduledRestartPaused  = false
		botman.scheduledRestart = false
		botman.ExceptionRebooted = false
		server.scanZombies = false

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		fixMissingStuff()

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		-- load tables
		loadTables()

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		openSQLiteDB() -- this lives in sqlite.lua

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		-- set all players to offline in shared db
		cleanupBotsData()

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		botman.nextRebootTest = os.time() + 300
		botman.initError = false

		if not botStatus.safeMode then
			getServerData(getAllPlayers)
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		-- Flag all players as offline
		if tonumber(server.botID) > 0 then
			--if botman.botsConnected then connBots:execute("UPDATE players set online = 0 WHERE botID = " .. server.botID) end
		end

		if not server.telnetDisabled then
			if not server.readLogUsingTelnet then
				if botman.dbConnected then conn:execute("UPDATE server set readLogUsingTelnet = 1") end
			end

			server.readLogUsingTelnet = true
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		if custom_startup ~= nil then
			custom_startup()
		end
	else
		if botman.blockTelnetSpam then
			botman.blockTelnetSpam = false
			tempTimer(60, [[setBlockTelnetSpam(true)]])
		end
	end

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	-- load the server API key if it exists
	readAPI()

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	-- join the irc server
	joinIRCServer()

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	if server.botman and not botStatus.safeMode then
		sendCommand("bm-readconfig")
	end

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	if not server.tempToken then
		server.tempToken = generatePassword(20)
	end

	if firstRun then
		-- read the mods from the saved lua table modVersions if it exists so we know already what mods should be present
		modVersions = {}
		server.allocs = false
		server.botman = false
		server.otherManager = false

		importModVersions()

		if not isFile(botman.chatlogPath .. "/guides/Player_Groups_Noobie_Guide.pdf") then
			getGuides()
		end

		file = io.open(botman.chatlogPath .. "/temp/readme.txt", "w")
		writeToFile(file, "Command help now has it's own help folder called help.  There is also a lists folder and a guides folder.")
		writeToFile(file, "The files in this temp folder are no longer updated.  Temp will be used for future temporary lists.")
		writeToFile(file, "Please look in " .. botman.chatlogPath:match("([^/]+)$") .. " for the new folders.")
		file:close()

		file = io.open(botman.chatlogPath .. "/help/readme.txt", "w")
		writeToFile(file, "The bot automatically generates the help.txt from your bot's current complete list of commands.")
		writeToFile(file, "If you change the bot's chat prefix, or set custom command permissions the help file will update with those changes.")
		writeToFile(file, "If it does not update immediately, you can force it to with the in-game command " .. server.commandPrefix .. "register help.")
		writeToFile(file, "You can do that command from The Lounge with cmd " .. server.commandPrefix .. "register help.")
		writeToFile(file, "Remember to use your bot's command prefix.")
		file:close()

		file = io.open(botman.chatlogPath .. "/lists/readme.txt", "w")
		writeToFile(file, "The bot can generate some handy lists for you.  The bot must be in API mode and the live map must be accessible.")
		writeToFile(file, "The following commands are only available in The Lounge, not in game.")
		writeToFile(file, "For a complete list of all items known to the server, type list all items.")
		writeToFile(file, "For a list of all entities, type list all entities.")
		writeToFile(file, "Repeating these commands will replace the lists so you can do these again as needed.")
		file:close()

		file = io.open(botman.chatlogPath .. "/guides/readme.txt", "w")
		writeToFile(file, "The bot automatically downloads guides daily.")
		writeToFile(file, "New guides may arrive with future bot updates.  Any changes to existing guides are fetched daily.")
		writeToFile(file, "If you want a new guide written, let me know and I will write it.")
		file:close()
	end

	if server.useAllocsWebAPI and tonumber(server.allocsMap) == 0 and not botStatus.safeMode then
		sendCommand("pm apitest")
		sendCommand("version")
		sendCommand("gt")
	end

	gmsg(server.commandPrefix .. "register help")

	if debug then display("debug login end\n") end
end
