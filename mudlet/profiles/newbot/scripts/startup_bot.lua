--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	          This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

require "load_lua_tables"
require "edit_me"
debugger = require "debug"
mysql = require "luasql.mysql"
local debug = false

-- record start and end execution times of code and report it.  At the moment I'm sending the timing info to the bot's lists window.
benchmarkBot = false

function dbugi(text)
	-- send text to the watch irc channel
	if (server and server.ircWatch) then
		irc_chat(server.ircWatch, text)
	else
		display(text)
	end
end

function dbugFull(ErrLvl, traceBack, dbugInfo, msg) 
	local dInfo = ""
	local msgOut

	if(ErrLvl == "E") then ErrLvl="Error" 
  	  elseif(ErrLvl == "D") then ErrLvl="Debug"
	   elseif(ErrLvl == "I") then ErrLvl="Info"
	end

	if(type(dbugInfo) == "table") then
		if(dbugInfo.source) then
			dInfo = string.sub(dbugInfo.source, string.find(dbugInfo.source, "scripts/") + 8, string.len(dbugInfo.source))
			if(dInfo == nil) then
				dInfo = dbugInfo.source
			end
		end

		if(dbugInfo.name) then
			if(string.len(dInfo) > 0) then
				dInfo = dInfo .. ", "
			end

			dInfo = dInfo .. dbugInfo.name
		end

		if(dbugInfo.currentline) then

			if(string.len(dInfo) > 0) then
                                dInfo = dInfo .. ", "
                        end

			dInfo = dInfo .. dbugInfo.currentline
		end

	else
		dInfo = ""
	end
		
	if(not msg) then 
		msg = "" 
	elseif(string.len(dInfo) > 0 ) then
		msg = ", " .. msg
	end

	if(not traceBack or traceBack == "") then
		traceBack = ""
	else
		traceBack = "\n" .. traceBack .. "\n"
	end

	msgOut = os.date("%c") .. " " .. ErrLvl .. ": " .. dInfo ..  msg .. traceBack
	dbug(msgOut)

	if(ErrLvl == "E") then
		dbugi("'" .. msgOut .. "'")
	end

end


function dbug(text)
	-- send text to the debug window we created in Mudlet.
	if (server and server.windowDebug) then
		cecho("Debug", text .. "\n")
	else
		display(text)
	end
end

function checkData()
	local benchStart = os.clock()

	if server.botName == nil then
		loadServer()
		botman.botStarted = nil
		refreshScripts()
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

	if (botman.playersOnline > 0) then
		if 	tablelength(igplayers) == 0 then
			igplayers = {}
			send("lp")
		end
	end

	if not server.allocs then
		irc_chat(name, "Alloc's mod appears to be missing and is required to run the bot (and the server).")
	end

	if not server.coppi then
		irc_chat(name, "Coppi's mod appears to be missing.  While not essential, it adds many great features.  Grab it here https://onedrive.live.com/?authkey=%21AGmv1pqf4fK2Oto&id=CD9F5C1DCDA5845%21111316&cid=0CD9F5C1DCDA5845")
	end

	if not botman.customMudlet then
		irc_chat(name, "You appear to not be using the custom Mudlet build by TheFae or an old version. The latest version adds several nice automation features and better IRC support. You can get here https://github.com/itsTheFae/FaesMudlet2")
		return
	end

	if benchmarkBot then
		dbug("function checkData elapsed time: " .. string.format("%.2f", os.clock() - benchStart))
	end
end


function getServerData(getAllPlayers)
	local benchStart = os.clock()

	--read mods
	send("version")

	--read the ban list
	tempTimer( 4, [[send("ban list")]] )

	--list known players
	if getAllPlayers then
		tempTimer( 6, [[send("lkp")]] )
	else
		tempTimer( 6, [[send("lkp -online")]] )
	end

	--read admin list
	tempTimer( 8, [[send("admin list")]] )

	--get the bot's IP
	tempTimer( 10, [[send("pm IPCHECK")]] )

	--read gg
	tempTimer( 12, [[send("gg")]] )

	--list the zombies
	tempTimer( 15, [[send("se")]] )

	--register the bot in the bots database
	tempTimer( 18, [[registerBot()]] )

	if benchmarkBot then
		dbug("function getServerData elapsed time: " .. string.format("%.2f", os.clock() - benchStart))
	end
end


function login()
	local benchStart = os.clock()
	local getAllPlayers = false

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if type(botman) ~= "table" then
		botman = {}
	end

	if(type(banList) ~= "table") then
		banList = {}
	end 

	if type(server) ~= "table" then
		server = {}
		botman.startedAt = os.time()
		getAllPlayers = true
		botman.scheduledRestartPaused = false
		botman.scheduledRestartForced = false
		botman.scheduledRestart = false
		botman.scheduledRestartTimestamp = getRestartOffset()

		if(debug) then 
			local tmpArray = os.time("*t", botman.scheduledRestartTimestamp)
			dbugFull("D", "", debugger.getinfo(1,"nSl"), "Time stamp set to: " .. tmpArray.day .. ":" .. tmpArray.hour .. ":" .. tmpArray.sec)
		end

		botman.lastBlockCommandOwner =	0
		server.lagged = false
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	-- if reloadBotScripts == nil then
		dofile(homedir .. "/scripts/reload_bot_scripts.lua")
		reloadBotScripts()
	-- end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	tempTimer( 120, [[checkData()]] )
	stackLimits = {}

	if(botman.botStarted ~= 0) then
		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		botman.botStarted = os.time()
		initBot()
		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
		openDB()
		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
		openBotsDB()
		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
		initDB()
		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
		botman.dbConnected = isDBConnected()
		if(not botman.dbConnected) then
			dbugFull("E", "", debugger.getinfo(1,"nSl"), "No connection for dbConnected")
		end
		botman.db2Connected = isDBBotsConnected()
		if(not botman.db2Connected) then
			dbugFull("E", "", debugger.getinfo(1,"nSl"), "No connection for db2Connected")
		end
		botman.initError = true
		botman.serverTime = ""
		botman.feralWarning = false
		botman.playersOnline = -1
		botman.userHome = string.sub(homedir, 1, string.find(homedir, ".config") - 2)
		loadServer()
		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
		botman.ignoreAdmins	= true
		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if server.botID == nil then
			if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "botID = 0") end
			server.botID = 0
		end

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

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

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if closeMudlet ~= nil then
			botman.customMudlet = true
		 	--loadWindowLayout()
		end

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		fixTables()

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		-- add your steam id here so you can debug using your name
		-- this should have been in edit_me.lua
		Smegz0r = "76561198024182120"

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

		fixMissingStuff()


		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		-- load tables
		loadTables()

		-- join the irc server
		if botman.customMudlet then
			joinIRCServer()
		end

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		-- set all players to offline in shared db
		cleanupBotsData()


		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		botman.nextRebootTest = nil
		botman.initError = false
		startLogging(true)
		getServerData(getAllPlayers)

		-- Flag all players as offline
		if tonumber(server.botID) > 0 then
			connBots:execute("UPDATE players set online = 0 WHERE botID = " .. server.botID)
		end

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "login end") end

	if benchmarkBot then
		dbugFull("I", "", debugger.getinfo(1,"nSl"), "Elapsed time: " .. string.format("%.2f", os.clock() - benchStart))
	end
end
