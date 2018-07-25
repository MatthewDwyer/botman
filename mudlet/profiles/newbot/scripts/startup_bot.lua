--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	          This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

debugger = require "debug"
mysql = require "luasql.mysql"
local debug

-- record start and end execution times of code and report it.  At the moment I'm sending the timing info to the bot's lists window.
benchmarkBot = false


function dbugi(text)
	-- send text to the special debug irc channel
	if server ~= nil then
		irc_chat(server.ircMain .. "_debug", text)
	end
end


function dbug(text)
	-- send text to the debug window we created in Mudlet.
	if server == nil then
		display(text .. "\n")
		return
	end

	if server.windowLists then
		windowMessage(server.windowLists, text .. "\n")
	end
end


function checkData()
	local benchStart = os.clock()

	if botman.botDisabled or botman.botOffline then
		return
	end

	if server.botName == nil then
		loadServer()
		botman.botStarted = nil
		login()
	end

	if tablelength(shopCategories) == 0 then
		loadShopCategories()
	end

	if tonumber(server.ServerPort) == 0 then
		send("gg")
	end

	if (botman.playersOnline > 0) then
		if tablelength(igplayers) == 0 then
			igplayers = {}
			send("lp")
		end
	end

	if not botman.customMudlet then
		irc_chat(server.ircMain, "You appear to not be using the custom Mudlet build by TheFae or an old version. The latest version adds several nice automation features and better IRC support. You can get here https://github.com/itsTheFae/FaesMudlet2")
	end

	if tablelength(owners) == 0 then
		send("admin list")
	end

	if benchmarkBot then
		dbug("function checkData elapsed time: " .. string.format("%.2f", os.clock() - benchStart))
	end
end


function getServerData(getAllPlayers)
	local benchStart = os.clock()

	if botman.botDisabled or botman.botOffline then
		return
	end

	reloadBot(getAllPlayers)

	if benchmarkBot then
		dbug("function getServerData elapsed time: " .. string.format("%.2f", os.clock() - benchStart))
	end
end


function login()
	local benchStart = os.clock()
	local getAllPlayers = false

	debug = false
	debugdb = false

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	if type(botman) ~= "table" then
		botman = {}
	end

	-- disable some stuff we no longer use
	disableTrigger("le")
	disableTimer("GimmeReset")

	if type(server) ~= "table" then
		server = {}
		getAllPlayers = true

		if not botman.botDisabled then
			botman.botOffline = false
		end

		botman.scheduledRestartPaused = false
		botman.scheduledRestartForced = false
		botman.scheduledRestart = false
		botman.scheduledRestartTimestamp = os.time()
		botman.lastBlockCommandOwner =	0
		botman.initReservedSlots = true
		botman.webdavFolderWriteable = true
		server.lagged = false
	end

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	tempTimer( 120, [[checkData()]] )
	stackLimits = {}

	if (botman.botStarted == nil) then
		botman.botStarted = os.time()

		if reloadBotScripts == nil then
			dofile(homedir .. "/scripts/reload_bot_scripts.lua")
			reloadBotScripts()
		end

		if not botman.sysExitID then
			botman.sysExitID = registerAnonymousEventHandler("sysExitEvent", "onSysExit")
		end

		if not botman.sysIrcStatusMessageID then
			botman.sysIrcStatusMessageID = registerAnonymousEventHandler("sysIrcStatusMessage", "ircStatusMessage")
		end

		if not botman.sysDisconnectionID then
			botman.sysDisconnectionID = registerAnonymousEventHandler("sysDisconnectionEvent", "onSysDisconnection")
		end

		modVersions = {}

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
		botman.db2Connected = isDBBotsConnected()
		botman.initError = true
		botman.serverTime = ""
		botman.feralWarning = false
		botman.playersOnline = -1
		botman.userHome = string.sub(homedir, 1, string.find(homedir, ".config") - 2)
		loadServer()
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

		if closeMudlet ~= nil then
			botman.customMudlet = true
		end

		if loadWindowLayout ~= nil then
			loadWindowLayout()
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		fixTables()

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

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

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
		startLogging(true)

		getServerData(getAllPlayers)

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

		-- Flag all players as offline
		if tonumber(server.botID) > 0 then
			connBots:execute("UPDATE players set online = 0 WHERE botID = " .. server.botID)
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end
	end

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	if not isFile(homedir .. "/botman.ini") then
		storeBotmanINI()
	end

	-- load the server API key if it exists
	readAPI()

	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end

	-- join the irc server
	if botman.customMudlet then
		joinIRCServer()
	end

	if custom_startup ~= nil then
		custom_startup()
	end

	if debug then display("debug login end\n") end

	if benchmarkBot then
		dbug("function login elapsed time: " .. string.format("%.2f", os.clock() - benchStart))
	end
end
