--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

-- This script now lives in scripts/functions.lua
-- After editing it type /reload code or restart the bot for your changes to be used.

local debug, steamID

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false -- should be false unless testing

if not telnetLogFileName then
	lfs.mkdir(homedir .. "/telnet_logs")
	telnetLogFileName = homedir .. "/telnet_logs/" .. os.date("%Y-%m-%d#%H-%M-%S") .. ".txt"
	telnetLogFile = io.open(telnetLogFileName, "a")
end


if botman.debugAll then
	debug = true -- this should be true
end


function postUpdate()
	local k, v

	os.remove(homedir .. "/temp/postUpdate.lua")
	os.execute("wget https://github.com/MatthewDwyer/botupdates/raw/master/" .. string.lower(server.updateBranch) .. "/postUpdate.lua -P \"" .. homedir .. "\"/temp/")
	tempTimer( 5, [[ dofile(homedir .. "/temp/postUpdate.lua") ]] )

	if not envSQL then
		openSQLiteDB()
	end

	for k,v in pairs(igplayers) do
		pcall(savePlayerData(k))
	end
end


function updateBot(forced, steam)
	if isFile(homedir .. "/blockScripts.txt") then
		irc_chat(server.ircMain, "Update cancelled")
		-- never update this bot
		return
	end

	if server.allocs and server.botman then
		botMaintenance.modsInstalled = true
		saveBotMaintenance()
	end

	if steam == nil then
		steamID = "0"
	else
		steamID = steam
	end

	if server.updateBranch ~= "" then
		os.remove(homedir .. "/temp/scripts.zip")
		os.remove(homedir .. "/temp/version.txt")
		os.execute("wget https://github.com/MatthewDwyer/botupdates/raw/master/" .. string.lower(server.updateBranch) .. "/version.txt -P \"" .. homedir .. "\"/temp/")

		if forced then
			tempTimer( 5, [[ checkScriptVersion(true) ]] )
		else
			tempTimer( 5, [[ checkScriptVersion() ]] )
		end
	end
end


function checkScriptVersion(forced)
	local file, ln, split, version

	file = io.open(homedir .. "/temp/version.txt", "r")

	for ln in file:lines() do
		split = string.split(ln, " ")
		if split[1] == "version" then
			version = split[2]

			if server.botVersion ~= split[2] or botman.refreshCode then
				botman.refreshCode = nil

				if server.updateBot or forced then
					irc_chat(server.ircMain, "Updating " .. server.botName .. " to version " .. version .. " code branch " .. string.lower(server.updateBranch))
					server.botVersion = version
					conn:execute("UPDATE server set botVersion = '" .. version .. "'")

					os.execute("wget https://github.com/MatthewDwyer/botupdates/raw/master/" .. string.lower(server.updateBranch) .. "/scripts.zip -P \"" .. homedir .. "\"/temp/")
					tempTimer( 10, [[ unpackScripts() ]] )
				else
					irc_chat(server.ircMain, "A bot update is available. Version " .. split[2] .. " Automatic updates are disabled.  Type update code to force it.")
				end
			else
				if forced then
					irc_chat(server.ircMain, "The bot is running the latest " .. string.lower(server.updateBranch) .. " version.")

					if steamID ~= "0" then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot is running the latest " .. string.lower(server.updateBranch) .. " version.[-]")
					end
				end
			end
		end
	end

	file:close()
end


function unpackScripts()
	dofile(homedir .. "/scripts/update.lua")
	runBeforeBotUpdate()

	os.execute("unzip -X -o \"" .. homedir .. "\"/temp/scripts.zip -d \"" .. homedir .. "\"")
	message("say [" .. server.chatColour .. "]" .. server.botName .. " has been updated.[-]")
	tempTimer( 5, [[ reloadBotScripts(true, true) ]] )
	tempTimer( 10, [[ loadPlayers() ]] )
	tempTimer( 15, [[ loadPlayersArchived() ]] )
	tempTimer( 20, [[ postUpdate() ]] )
	tempTimer( 30, [[ updateCommandHelp() ]] )
	dofile(homedir .. "/scripts/reload_bot_scripts.lua")
end


function fixTables() -- Waiter!  Where's my table!?
	if type(anticheatBans) ~= "table" then
		anticheatBans = {}
	end

	if type(badItems) ~= "table" then
		badItems = {}
	end

	if type(bans) ~= "table" then
		bans = {}
	end

	if type(bases) ~= "table" then
		bases = {}
	end

	if type(botman) ~= "table" then
		botman = {}
		botman.playersOnline = 0
		botStatus.playersOnline = 0
	end

	if type(botMaintenance) ~= "table" then
		botMaintenance = {}
	end

	if type(conQueue) ~= "table" then
		conQueue = {}
	end

	if type(customMessages) ~= "table" then
		customMessages = {}
	end

	if type(donors) ~= "table" then
		donors = {}
	end

	if type(fallingBlocks) ~= "table" then
		fallingBlocks = {}
	end

	if type(friends) ~= "table" then
		friends = {}
	end

	if type(gimmePrizes) ~= "table" then
		gimmePrizes = {}
	end

	if type(gimmeZombies) ~= "table" then
		gimmeZombies = {}
	end

	if type(helpCommands) ~= "table" then
		helpCommands = {}
	end

	if type(hotspots) ~= "table" then
		hotspots = {}
	end

	if type(igplayers) ~= "table" then
		igplayers = {}
	end

	if type(invTemp) ~= "table" then
		invTemp = {}
	end

	if type(keystones) ~= "table" then
		keystones = {}
	end

	if type(lastHotspots) ~= "table" then
		lastHotspots = {}
	end

	if type(metrics) ~= "table" then
		metrics = {}
		metrics.commands = 0
		metrics.commandLag = 0
		metrics.errors = 0
		metrics.telnetLines = 0
	end

	if type(modVersions) ~= "table" then
		modVersions = {}
	end

	if type(modBotman) ~= "table" then
		modBotman = {}
	end

	if type(playerGroup) ~= "table" then
		playerGroup = {}
	end

	if type(players) ~= "table" then
		players = {}
	end

	if type(playersArchived) ~= "table" then
		playersArchived = {}
	end

	if type(playersOnlineList) ~= "table" then
		playersOnlineList = {}
	end

	if type(proxies) ~= "table" then
		proxies = {}
	end

	if type(otherEntities) ~= "table" then
		otherEntities = {}
	end

	if type(restrictedItems) ~= "table" then
		restrictedItems = {}
	end

	if type(shop) ~= "table" then
		shop = {}
	end

	if type(shopCategories) ~= "table" then
		shopCategories = {}
	end

	if type(spawnableItems) ~= "table" then
		spawnableItems = {}
	end

	if type(stackLimits) ~= "table" then
		stackLimits = {}
	end

	if type(staffList) ~= "table" then
		staffList = {}
	end

	if type(villagers) ~= "table" then
		villagers = {}
	end

	if type(waypoints) ~= "table" then
		waypoints = {}
	end
end


function reportReloadCode()
	if server.reloadCodeSuccess then
		alertAdmins("The bot's scripts have reloaded.")

		if server.ircMain ~= nil then
			irc_chat(server.ircMain, "The bot's scripts have reloaded.")
		end

		if helpCommands then
			if tablelength(helpCommands) == 0 then
				-- automatically register command help and create a new help.txt file in the temp folder of the bot's daily logs web folder.
				botman.registerHelp	= true
				gmsg(server.commandPrefix .. "register help")
			end
		end
	else
		alertAdmins("Script error in " .. server.nextCodeReload)

		if server.ircMain ~= nil then
			irc_chat(server.ircMain, "Script error in " .. server.nextCodeReload)
		end
	end

	if not server.reloadCustomCodeSuccess then
		alertAdmins("Script error in " .. server.nextCodeReload)

		if server.ircMain ~= nil then
			irc_chat(server.ircMain, "Script error in " .. server.nextCodeReload)
		end
	end
end


function checkScript(script)
	if not isFile(script) then
		file = io.open(script, "a")
		file:write("--This script is missing!\n")
		file:close()

		irc_chat(server.ircMain, "Script missing " .. script)
	end

	dofile(script)
end


function reloadCustomScripts()
	server.reloadCustomCodeSuccess = false

	if (debug) then display("debug reloadCustomScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	if isFile(homedir .. "/custom/customIRC.lua") then
		server.nextCodeReload = "/custom/customIRC.lua"
		dofile(homedir .. "/custom/customIRC.lua")
	end

	if (debug) then display("debug reloadCustomScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	if isFile(homedir .. "/custom/custom_functions.lua") then
		server.nextCodeReload = "/custom/custom_functions.lua"
		dofile(homedir .. "/custom/custom_functions.lua")
	end

	if (debug) then display("debug reloadCustomScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	if isFile(homedir .. "/custom/gmsg_custom.lua") then
		server.nextCodeReload = "/custom/gmsg_custom.lua"
		checkScript(homedir .. "/custom/gmsg_custom.lua")
	end

	server.reloadCustomCodeSuccess = true

	if (debug) then display("debug reloadCustomScripts line " .. debugger.getinfo(1).currentline .. "\n") end
end


function refreshScripts()
	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	-- scripts
	server.nextCodeReload = "/scripts/core_functions.lua"
	dofile(homedir .. "/scripts/core_functions.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/functions.lua"
	dofile(homedir .. "/scripts/functions.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	fixMissingStuff()

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/debug.lua"
	checkScript(homedir .. "/scripts/debug.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/edit_me.lua"
	checkScript(homedir .. "/scripts/edit_me.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/irc_functions.lua"
	checkScript(homedir .. "/scripts/irc_functions.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/irc_message.lua"
	checkScript(homedir .. "/scripts/irc_message.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/irc_help.lua"
	checkScript(homedir .. "/scripts/irc_help.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/gimme.lua"
	checkScript(homedir .. "/scripts/gimme.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/inventory.lua"
	checkScript(homedir .. "/scripts/inventory.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/queues.lua"
	checkScript(homedir .. "/scripts/queues.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/shop.lua"
	checkScript(homedir .. "/scripts/shop.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/teleport_functions.lua"
	checkScript(homedir .. "/scripts/teleport_functions.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/load_lua_tables.lua"
	checkScript(homedir .. "/scripts/load_lua_tables.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/new_server.lua"
	checkScript(homedir .. "/scripts/new_server.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/lua_tables.lua"
	checkScript(homedir .. "/scripts/lua_tables.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/reset_bot.lua"
	checkScript(homedir .. "/scripts/reset_bot.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/base_protection.lua"
	checkScript(homedir .. "/scripts/base_protection.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/save_db_tables.lua"
	checkScript(homedir .. "/scripts/save_db_tables.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/sqlite.lua"
	checkScript(homedir .. "/scripts/sqlite.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/mysql.lua"
	checkScript(homedir .. "/scripts/mysql.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/trialCode.lua"
	checkScript(homedir .. "/scripts/trialCode.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/update.lua"
	checkScript(homedir .. "/scripts/update.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/webAPI_functions_JSON.lua"
	checkScript(homedir .. "/scripts/webAPI_functions_JSON.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	-- chat scripts
	server.nextCodeReload = "/scripts/chat/gmsg_functions.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_functions.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_admin.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_admin.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_base.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_base.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_bot.lua"
	dofile(homedir .. "/scripts/chat/gmsg_bot.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_botman.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_botman.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_friends.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_friends.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_fun.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_fun.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_help.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_help.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_hotspots.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_hotspots.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_info.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_info.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_locations.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_locations.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_mail.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_mail.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_misc.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_misc.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_resets.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_resets.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_server.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_server.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_shop.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_shop.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_teleports.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_teleports.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_tracker.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_tracker.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_trial_code.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_trial_code.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_unslashed.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_unslashed.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_villages.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_villages.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_waypoints.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_waypoints.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/chat/gmsg_groups.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_groups.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	-- timers
	server.nextCodeReload = "/scripts/timers/APITimer.lua"
	checkScript(homedir .. "/scripts/timers/APITimer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/thirty_second_timer.lua"
	checkScript(homedir .. "/scripts/timers/thirty_second_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/one_minute_timer.lua"
	checkScript(homedir .. "/scripts/timers/one_minute_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/one_second_timer.lua"
	checkScript(homedir .. "/scripts/timers/one_second_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/five_second_timer.lua"
	checkScript(homedir .. "/scripts/timers/five_second_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/list_players_timer.lua"
	checkScript(homedir .. "/scripts/timers/list_players_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/one_hour_timer.lua"
	checkScript(homedir .. "/scripts/timers/one_hour_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/reconnect_timer.lua"
	checkScript(homedir .. "/scripts/timers/reconnect_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/timed_commands_timer.lua"
	checkScript(homedir .. "/scripts/timers/timed_commands_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/irc_queue_timer.lua"
	checkScript(homedir .. "/scripts/timers/irc_queue_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/fortyfive_second_timer.lua"
	checkScript(homedir .. "/scripts/timers/fortyfive_second_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/track_player_timer.lua"
	checkScript(homedir .. "/scripts/timers/track_player_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/message_queue_timer.lua"
	checkScript(homedir .. "/scripts/timers/message_queue_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/two_minute_timer.lua"
	checkScript(homedir .. "/scripts/timers/two_minute_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/player_queued_commands_timer.lua"
	checkScript(homedir .. "/scripts/timers/player_queued_commands_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/gimme_queued_commands_timer.lua"
	checkScript(homedir .. "/scripts/timers/gimme_queued_commands_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/fifteen_second_timer.lua"
	checkScript(homedir .. "/scripts/timers/fifteen_second_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/ten_second_timer.lua"
	checkScript(homedir .. "/scripts/timers/ten_second_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/ten_minute_timer.lua"
	checkScript(homedir .. "/scripts/timers/ten_minute_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/five_minute_timer.lua"
	checkScript(homedir .. "/scripts/timers/five_minute_timer.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/timers/thirty_minutes.lua"
	checkScript(homedir .. "/scripts/timers/thirty_minutes.lua")

	server.nextCodeReload = ""
	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	-- triggers
	server.nextCodeReload = "/scripts/triggers/pvp.lua"
	checkScript(homedir .. "/scripts/triggers/pvp.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/match_all.lua"
	checkScript(homedir .. "/scripts/triggers/match_all.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/player_info.lua"
	checkScript(homedir .. "/scripts/triggers/player_info.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/player_connected.lua"
	checkScript(homedir .. "/scripts/triggers/player_connected.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/player_disconnected.lua"
	checkScript(homedir .. "/scripts/triggers/player_disconnected.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/end_list_players.lua"
	checkScript(homedir .. "/scripts/triggers/end_list_players.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/list_known_players.lua"
	checkScript(homedir .. "/scripts/triggers/list_known_players.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/scouts.lua"
	checkScript(homedir .. "/scripts/triggers/scouts.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/inventory_owner.lua"
	checkScript(homedir .. "/scripts/triggers/inventory_owner.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/air_drop_alert.lua"
	checkScript(homedir .. "/scripts/triggers/air_drop_alert.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/game_time.lua"
	checkScript(homedir .. "/scripts/triggers/game_time.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/game_tick_count.lua"
	checkScript(homedir .. "/scripts/triggers/game_tick_count.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/login_successful.lua"
	checkScript(homedir .. "/scripts/triggers/login_successful.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/collect_ban.lua"
	checkScript(homedir .. "/scripts/triggers/collect_ban.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/unban_player.lua"
	checkScript(homedir .. "/scripts/triggers/unban_player.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/overstack.lua"
	checkScript(homedir .. "/scripts/triggers/overstack.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/mem.lua"
	checkScript(homedir .. "/scripts/triggers/mem.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/lp.lua"
	checkScript(homedir .. "/scripts/triggers/lp.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/tele.lua"
	checkScript(homedir .. "/scripts/triggers/tele.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/llp.lua"
	checkScript(homedir .. "/scripts/triggers/llp.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/list_entities.lua"
	checkScript(homedir .. "/scripts/triggers/list_entities.lua")

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "/scripts/triggers/telnetCheck.lua"
	checkScript(homedir .. "/scripts/triggers/telnetCheck.lua")

if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	-- enable triggers and timers.  No ability to enable scripts in code yet.
	if not server.useAllocsWebAPI then
		toggleTriggers("api offline")
	else
		toggleTriggers("api online")
	end

	-- special case where the bot will use telnet to monitor the server regardless of other API settings
	if server.readLogUsingTelnet then
		toggleTriggers("api offline")
	end

	enableTrigger("Logon Successful")
	enableTrigger("lp")
	enableTrigger("Tele")
	enableTrigger("llp")

	enableTimer("APITimer")
	enableTimer("EverySecond")
	enableTimer("Every5Seconds")
	enableTimer("Every10Seconds")
	enableTimer("Every15Seconds")
	enableTimer("EveryHalfMinute")
	enableTimer("Every45Seconds")
	enableTimer("OneMinuteTimer")
	enableTimer("TwoMinuteTimer")
	enableTimer("five_minute_timer")
	enableTimer("ten_minute_timer")
	enableTimer("ThirtyMinuteTimer")
	enableTimer("OneHourTimer")
	enableTimer("listPlayers")
	enableTimer("Reconnect")
	enableTimer("TimedCommands")
	enableTimer("PlayerQueuedCommands")
	enableTimer("GimmeQueuedCommands")
	enableTimer("ircQueue")
	enableTimer("TrackPlayer")
	enableTimer("messageQueue")

	-- delayed reload for startup_bot.lua
	tempTimer( 5, [[ dofile(]] .. homedir .. [[ .. "/scripts/startup_bot.lua") ]] )

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end
end


function reloadBotScripts(skipTables, skipFetchData, silent)
	-- disable some stuff we no longer use
	disableTrigger("Spam")
	disableTrigger("le")
	disableTimer("GimmeReset")
	disableTrigger("GameTickCount")
	disableTrigger("Reload admins")

	if exists("Every5Seconds", "timer") == 0 then
	  permTimer("Every5Seconds", "", 5.0, [[FiveSecondTimer()]])
	end

	if exists("Every10Seconds", "timer") == 0 then
	  permTimer("Every10Seconds", "", 10.0, [[TenSecondTimer()]])
	end

	if exists("five_minute_timer", "timer") == 0 then
	  permTimer("five_minute_timer", "", 300.0, [[FiveMinuteTimer()]])
	end

	if exists("ten_minute_timer", "timer") == 0 then
	  permTimer("ten_minute_timer", "", 600.0, [[TenMinuteTimer()]])
	end

	if exists("APITimer", "timer") == 0 then
	  permTimer("APITimer", "", 0.150, [[APITimer()]])
	end

	if exists("EverySecond", "timer") == 0 then
	  permTimer("EverySecond", "", 1, [[OneSecondTimer()]])
	end

	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	fixTables()

	local chatColour, k, v

	server.reloadCodeSuccess = false

	if not silent then
		tempTimer( 10, [[ reportReloadCode() ]] )
	end

	disableTimer("ReloadScripts")

	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	if type(server) == "table" then
		chatColour = server.chatColour
	else
		chatColour = "D4FFD4"
	end

	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	refreshScripts()

	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end

	server.nextCodeReload = "finishing reload 1"
	if type(server) == "table" then
		if server.windowGMSG ~= nil then

	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end
			-- refresh some things to fix or avoid missing info that we rely on.
			alterTables() -- make sure all new table changes are done.  The server table is the most important to get updated.
			getPlayerFields() -- refresh player fields
			getServerFields() -- refresh server fields

	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end
			server.nextCodeReload = "finishing reload 2"

			if skipTables then
	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end
				-- force a reload of the lua tables in case new fields have been added so they get initialised with default values.
				loadTables(true) -- passing true tells loadTables to not reload the players table.
			end

	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end

			openUserWindow(server.windowGMSG)
			openUserWindow(server.windowDebug)
			openUserWindow(server.windowLists)

			server.nextCodeReload = "finishing reload 3"
			for k,v in pairs(igplayers) do
				fixMissingIGPlayer(v.platform, k, v.steamOwner, v.userID)
			end

			server.nextCodeReload = "finishing reload 4"
			for k,v in pairs(players) do
				fixMissingPlayer(v.platform, k, v.steamOwner, v.userID)
			end

			server.nextCodeReload = "finishing reload 5"
			fixMissingServer()
			registerBot()
			botman.webdavFolderExists = true

			if botman.chatlogPath == nil or botman.chatlogPath == "" then
				if not isDir(webdavFolder) then
					botman.webdavFolderExists = false
					botman.chatlogPath = homedir .. "/chatlogs"
				else
					botman.chatlogPath = webdavFolder
				end

				if botman.dbConnected then conn:execute("UPDATE server SET chatlogPath = '" .. escape(botman.chatlogPath) .. "'") end
			end

			if not skipFetchData then
				tempTimer( 30, [[reloadBot()]] )
			else
				if server.allocsMap then
					if tonumber(server.allocsMap) == 0 then
						tempTimer( 5, [[sendCommand("version")]] )
					end
				end

				tempTimer( 10, [[sendCommand("gg")]] )
			end

			if not botman.sysDisconnectionID then
				botman.sysDisconnectionID = registerAnonymousEventHandler("sysDisconnectionEvent", "onSysDisconnection")
			end
		end
	end

	if botman.spamID == nil then
		botman.blockTelnetSpam = false
		botman.spamID = tempRegexTrigger("^", [[blockTelnetSpam()]])
	end

	if botman.tokenTriggerID == nil then
		botman.tokenTriggerID = tempTrigger("Invalid Admintoken", [[invalidAdminTokenTrigger(line)]])
	end

	server.nextCodeReload = "finishing reload 6"
	-- load the server API key if it exists
	readAPI()

	-- Do some daily maintenance tasks
	if server.dateTest then
		if type(botMaintenance) ~= "table" then
			botMaintenance = {}
		end

		server.nextCodeReload = "finishing reload 7"
		-- run llp once per day
		if not botMaintenance.lastLLP then
			botMaintenance.lastLLP = server.dateTest
			saveBotMaintenance()
			sendCommand("llp parseable")
		else
			server.nextCodeReload = "finishing reload 8"
			if botMaintenance.lastLLP ~= server.dateTest then
				botMaintenance.lastLLP = server.dateTest
				saveBotMaintenance()
				sendCommand("llp parseable")
			end
		end

		server.nextCodeReload = "finishing reload 9"
		-- make sure we have run lkp at least once.  After that we will run it daily if there are 10 or less players online.
		if not botMaintenance.lastLKP then
				botMaintenance.lastLKP = server.dateTest
				saveBotMaintenance()
				sendCommand("lkp")
		else
			server.nextCodeReload = "finishing reload 10"
			if botMaintenance.lastLKP ~= server.dateTest then
				if tonumber(botman.playersOnline) < 11 then
					botMaintenance.lastLKP = server.dateTest
					saveBotMaintenance()
					sendCommand("lkp")
				end
			end
		end
	end

	enableTimer("APITimer")

	server.reloadCodeSuccess = true

	--reload the custom scripts
	tempTimer( 5, [[reloadCustomScripts()]] )

	if (debug) then display("debug reloadBotScripts end \n") end
end
