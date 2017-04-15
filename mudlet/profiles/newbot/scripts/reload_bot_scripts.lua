-- This script now lives in scripts/functions.lua
-- After editing it type /reload code or restart the bot for your changes to be used.

local debug

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false

function fixTables()
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

	if type(gimmeZombies) ~= "table" then
		gimmeZombies = {}
	end		
	
	if type(otherEntities) ~= "table" then
		otherEntities = {}
	end	
	
	if type(waypoints) ~= "table" then
		waypoints = {}
	end
	
	if type(staffList) ~= "table" then
		staffList = {}
	end	
end


function reportReloadCode()
	if server.reloadCodeSuccess then
		alertAdmins("The bot's scripts have reloaded.")

		if server.ircMain ~= nil then
			irc_chat(server.ircMain, "The bot's scripts have reloaded.")
		end
	else
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


function refreshScripts()
if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end			

	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end				

	-- scripts
	server.nextCodeReload = "/scripts/core_functions.lua"
	dofile(homedir .. "/scripts/core_functions.lua")
	
	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end					
	
	server.nextCodeReload = "/scripts/functions.lua"
	dofile(homedir .. "/scripts/functions.lua")	
	
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
	
	server.nextCodeReload = "/scripts/coppi.lua"
	checkScript(homedir .. "/scripts/coppi.lua")
	
	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end
	
	server.nextCodeReload = "/scripts/gimme.lua"
	checkScript(homedir .. "/scripts/gimme.lua")
	
	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end
	
	server.nextCodeReload = "/scripts/inventory.lua"
	checkScript(homedir .. "/scripts/inventory.lua")
	
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
	
	server.nextCodeReload = "/scripts/one_minute.lua"
	checkScript(homedir .. "/scripts/one_minute.lua")
	
	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end
	
	server.nextCodeReload = "/scripts/one_hour.lua"
	checkScript(homedir .. "/scripts/one_hour.lua")
	
	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end
	
	server.nextCodeReload = "/scripts/thirty_minutes.lua"
	checkScript(homedir .. "/scripts/thirty_minutes.lua")
	
	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end						
	
	server.nextCodeReload = "/scripts/mysql.lua"
	checkScript(homedir .. "/scripts/mysql.lua")
	
	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end						
	
	server.nextCodeReload = "/scripts/trialCode.lua"
	checkScript(homedir .. "/scripts/trialCode.lua")	
	
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
	
	server.nextCodeReload = "/custom/gmsg_custom.lua"
	checkScript(homedir .. "/custom/gmsg_custom.lua")
	
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
	
	server.nextCodeReload = "/scripts/chat/gmsg_pms.lua"
	checkScript(homedir .. "/scripts/chat/gmsg_pms.lua")
	
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

	-- timers
	server.nextCodeReload = "/scripts/timers/thirty_second_timer.lua"
	checkScript(homedir .. "/scripts/timers/thirty_second_timer.lua")
	
	if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end
	
	server.nextCodeReload = "/scripts/timers/one_minute_timer.lua"
	checkScript(homedir .. "/scripts/timers/one_minute_timer.lua")
	
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

	-- enable triggers and timers.  No ability to enable scripts in code yet.
	enableTrigger("End list players")
	enableTrigger("PVP Police")
	enableTrigger("MatchAll")
	enableTrigger("InventorySlot")
	enableTrigger("Player connected")
	enableTrigger("playerinfo")
	enableTrigger("Player disconnected")
	enableTrigger("Inventory")
	enableTrigger("lkp")
	enableTrigger("Zombie scouts")
	enableTrigger("InventoryOwner")
	enableTrigger("AirDrop alert")
	enableTrigger("Spam")
	enableTrigger("Game Time")
	enableTrigger("GameTickCount")
	enableTrigger("Logon Successful")
	enableTrigger("Collect Ban")
	enableTrigger("Unban player")
	enableTrigger("Overstack")
	enableTrigger("Open Reserved Slot")
	enableTrigger("mem")
	enableTrigger("lp")
	enableTrigger("Tele")
	enableTrigger("llp")
	enableTrigger("Chat")
	enableTrigger("log chat")

	enableTimer("EveryHalfMinute")
	enableTimer("OneMinuteTimer")
	enableTimer("listPlayers")
	enableTimer("OneHourTimer")
	enableTimer("Reconnect")
	enableTimer("GimmeReset")
	enableTimer("TimedCommands")
	enableTimer("ThirtyMinuteTimer")
	enableTimer("PlayerQueuedCommands")
	enableTimer("GimmeQueuedCommands")
	enableTimer("ircQueue")
	enableTimer("Every45Seconds")
	enableTimer("TrackPlayer")
	enableTimer("messageQueue")
if (debug) then display("debug refreshScripts line " .. debugger.getinfo(1).currentline .. "\n") end			
end


function reloadBotScripts(skipTables)
	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end			
	
	fixTables()		

	local chatColour, k, v

	server.reloadCodeSuccess = false	
	tempTimer( 3, [[ reportReloadCode() ]] )			
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

	server.nextCodeReload = "finishing reload"
	if type(server) == "table" then
		if server.windowGMSG ~= nil then
		
	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end					
			-- refresh some things to fix or avoid missing info that we rely on.
			alterTables() -- make sure all new table changes are done.  The server table is the most important to get updated.
			getPlayerFields() -- refresh player fields
			getServerFields() -- refresh server fields
			
	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end						
			
			if skipTables ~= nil then
	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end									
				-- force a reload of the lua tables incase new fields have been added so they get initialised with default values.
				loadTables(true) -- passing true tells loadTables to not reload the players table.
			end
			
	if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end						

			openUserWindow(server.windowGMSG)
			openUserWindow(server.windowDebug)
			openUserWindow(server.windowLists)
			openUserWindow(server.windowPlayers)
			openUserWindow(server.windowAlerts)			

			for k,v in pairs(igplayers) do
				fixMissingIGPlayer(k)
			end

			for k,v in pairs(players) do
				fixMissingPlayer(k)
			end
			
			-- check the waypoints table and migrate the old waypoints to it if it is empty.
			migrateWaypoints()			
			
			fixMissingServer()
			registerBot()
			
			botman.webdavFolderExists = true			
			botman.webdavFolderWriteable = true			
			if botman.chatlogPath == nil or botman.chatlogPath == "" then
				botman.chatlogPath = webdavFolder
				conn:execute("UPDATE server SET chatlogPath = '" .. escape(webdavFolder) .. "'")
			end				
			
			send("gg")
			send("teleh")
			send("se")			
		end
	end
	
	server.reloadCodeSuccess = true	

if (debug) then display("debug reloadBotScripts line " .. debugger.getinfo(1).currentline .. "\n") end				
	
end
