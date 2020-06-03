--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	          This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

debugger = require "debug"
mysql = require "luasql.mysql"
local debug

if not telnetLogFileName then
	telnetLogFileName = homedir .. "/telnet_logs/" .. os.date("%Y-%m-%d#%H-%M") .. ".txt"
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
	if botman.botDisabled or botman.botOffline then
		return
	end

	if server.botName == nil then
		loadServer()
		botman.botStarted = nil
		login()
	end

	sendCommand("version")
	sendCommand("gt")

	if server.botman then
		if server.uptime == 0 then
			sendCommand("bm-uptime")
		end

		sendCommand("bm-resetregions list")
		--sendCommand("bm-change botname [" .. server.botNameColour .. "]" .. server.botName)
		sendCommand("bm-anticheat report")
	end

	if tablelength(shopCategories) == 0 then
		loadShopCategories()
	end

	if tonumber(server.ServerPort) == 0 then
		sendCommand("gg")
	else
		addOrRemoveSlots()
	end

	if tablelength(owners) == 0 then
		sendCommand("admin list")
	end
end


function getServerData(getAllPlayers)
	if botman.botDisabled or botman.botOffline then
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
	local randomChannel, r

	debug = false
	debugdb = false

	startLogging(false)

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	-- disable some stuff we no longer use
	disableTrigger("le")
	disableTimer("GimmeReset")

	if type(botman) ~= "table" then
		botman = {}
		botman.botOffline = true
		botman.APIOffline = true
		botman.telnetOffline = true
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
	end

	tempTimer( 40, [[checkData()]] )

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

	if botman.sysIrcStatusMessageID == nil then
		botman.sysIrcStatusMessageID = registerAnonymousEventHandler("sysIrcStatusMessage", "ircStatusMessage")
		botman.sysIrcStatusMessageID = 0
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

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	if (botman.botStarted == nil) then
		botman.botStarted = os.time()

		telnetLogFileName = homedir .. "/telnet_logs/" .. os.date("%Y-%m-%d#%H-%M-%S", os.time()) .. ".txt"
		telnetLogFile = io.open(telnetLogFileName, "a")

		if reloadBotScripts == nil then
			dofile(homedir .. "/scripts/reload_bot_scripts.lua")
			reloadBotScripts(false, false, false)
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		-- this must come after reload_bot_scripts above.
		fixTables()

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
		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		if server.botID == nil then
			server.botID = 0
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		botman.webdavFolderExists = true

		if botman.chatlogPath == nil then
			botman.chatlogPath = webdavFolder
			if botman.dbConnected then conn:execute("UPDATE server SET chatlogPath = '" .. escape(webdavFolder) .. "'") end
		end

		if not isDir(botman.chatlogPath) then
			botman.webdavFolderExists = false
		end

		openUserWindow(server.windowGMSG)
		openUserWindow(server.windowDebug)
		openUserWindow(server.windowLists)

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		if closeMudlet ~= nil or addCustomLine ~= nil then
			botman.customMudlet = true
		end

		if loadWindowLayout ~= nil then
			loadWindowLayout()
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		-- add your steam id here so you can debug using your name
		Smegz0r = "76561197983251951"

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
		server.lagged = false

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		checkForMissingTables()

		fixMissingStuff()

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		-- load tables
		loadTables()

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		-- set all players to offline in shared db
		cleanupBotsData()

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		botman.nextRebootTest = nil
		botman.initError = false

		getServerData(getAllPlayers)

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		-- Flag all players as offline
		if tonumber(server.botID) > 0 then
			if botman.botsConnected then connBots:execute("UPDATE players set online = 0 WHERE botID = " .. server.botID) end
		end

		if not server.telnetDisabled then
			if not server.readLogUsingTelnet then
				if botman.dbConnected then conn:execute("UPDATE server set readLogUsingTelnet = 1") end
			end

			server.readLogUsingTelnet = true
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end
	end

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	if not isFile(homedir .. "/botman.ini") then
		--storeBotmanINI()
	end

	-- load the server API key if it exists
	readAPI()

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	-- join the irc server
	if botman.customMudlet then
		joinIRCServer()
	end

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	if server.botman then
		sendCommand("bm-readconfig")
	end

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	if custom_startup ~= nil then
		custom_startup()
	end

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	-- special case where the bot will use telnet to monitor the server regardless of other API settings
	if server.readLogUsingTelnet then
		toggleTriggers("api offline")
	end

	if debug then display("debug login end\n") end
end
