-- This script now lives in scripts/functions.lua
-- After editing it type /reload code or restart the bot for your changes to be used.

function reloadBotScripts()
	disableTimer("ReloadScripts")
	local debug, chatColour, k, v
	
	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false
	
	if type(server) == "table" then
		chatColour = server.chatColour
	else
		chatColour = "D4FFD4"
	end

	-- scripts
	dofile(homedir .. "/scripts/core_functions.lua")
	dofile(homedir .. "/scripts/edit_me.lua")
	dofile(homedir .. "/scripts/functions.lua")
	dofile(homedir .. "/scripts/irc_functions.lua")
	dofile(homedir .. "/scripts/irc_message.lua")
	dofile(homedir .. "/scripts/irc_help.lua")
	dofile(homedir .. "/scripts/uberbot.lua")
	dofile(homedir .. "/scripts/coppi.lua")
	dofile(homedir .. "/scripts/coppi_ubex.lua")
	dofile(homedir .. "/scripts/gimme.lua")
	dofile(homedir .. "/scripts/inventory.lua")
	dofile(homedir .. "/scripts/shop.lua")
	dofile(homedir .. "/scripts/teleport_functions.lua")
	dofile(homedir .. "/scripts/load_lua_tables.lua")
	dofile(homedir .. "/scripts/new_server.lua")
	dofile(homedir .. "/scripts/lua_tables.lua")
	dofile(homedir .. "/scripts/reset_bot.lua")
	dofile(homedir .. "/scripts/base_protection.lua")
	dofile(homedir .. "/scripts/save_db_tables.lua")
	dofile(homedir .. "/scripts/one_minute.lua")
	dofile(homedir .. "/scripts/one_hour.lua")
	dofile(homedir .. "/scripts/thirty_minutes.lua")
	dofile(homedir .. "/scripts/mysql.lua")
	if debug then dbug("done misc scripts") end

	-- chat scripts
	dofile(homedir .. "/scripts/chat/gmsg_functions.lua")
	if debug then dbug("1") end
	dofile(homedir .. "/scripts/chat/gmsg_admin.lua")
	if debug then dbug("2") end
	dofile(homedir .. "/scripts/chat/gmsg_base.lua")
	if debug then dbug("3") end
	dofile(homedir .. "/scripts/chat/gmsg_custom.lua")
	if debug then dbug("4") end
	dofile(homedir .. "/scripts/chat/gmsg_friends.lua")
	if debug then dbug("5") end
	dofile(homedir .. "/scripts/chat/gmsg_fun.lua")
	if debug then dbug("6") end
	dofile(homedir .. "/scripts/chat/gmsg_help.lua")
	if debug then dbug("7") end
	dofile(homedir .. "/scripts/chat/gmsg_hotspots.lua")
	if debug then dbug("8") end
	dofile(homedir .. "/scripts/chat/gmsg_info.lua")
	if debug then dbug("9") end
	dofile(homedir .. "/scripts/chat/gmsg_locations.lua")
	if debug then dbug("10") end
	dofile(homedir .. "/scripts/chat/gmsg_mail.lua")
	if debug then dbug("11") end
	dofile(homedir .. "/scripts/chat/gmsg_misc.lua")
	if debug then dbug("12") end
	dofile(homedir .. "/scripts/chat/gmsg_pms.lua")
	if debug then dbug("13") end
	dofile(homedir .. "/scripts/chat/gmsg_resets.lua")
	if debug then dbug("14") end
	dofile(homedir .. "/scripts/chat/gmsg_server.lua")
	if debug then dbug("15") end
	dofile(homedir .. "/scripts/chat/gmsg_shop.lua")
	if debug then dbug("16") end
	dofile(homedir .. "/scripts/chat/gmsg_teleports.lua")
	if debug then dbug("17") end
	dofile(homedir .. "/scripts/chat/gmsg_tracker.lua")
	if debug then dbug("18") end
	dofile(homedir .. "/scripts/chat/gmsg_trial_code.lua")
	if debug then dbug("19") end
	dofile(homedir .. "/scripts/chat/gmsg_unslashed.lua")
	if debug then dbug("20") end
	dofile(homedir .. "/scripts/chat/gmsg_villages.lua")
	if debug then dbug("21") end
	dofile(homedir .. "/scripts/chat/gmsg_waypoints.lua")
	if debug then dbug("done chat scripts") end

	-- timers
	dofile(homedir .. "/scripts/timers/thirty_second_timer.lua")
	dofile(homedir .. "/scripts/timers/one_minute_timer.lua")
	dofile(homedir .. "/scripts/timers/list_players_timer.lua")
	dofile(homedir .. "/scripts/timers/one_hour_timer.lua")
	dofile(homedir .. "/scripts/timers/reconnect_timer.lua")
	dofile(homedir .. "/scripts/timers/timed_commands_timer.lua")
	dofile(homedir .. "/scripts/timers/irc_queue_timer.lua")
	dofile(homedir .. "/scripts/timers/fortyfive_second_timer.lua")
	dofile(homedir .. "/scripts/timers/track_player_timer.lua")
	dofile(homedir .. "/scripts/timers/message_queue_timer.lua")
	dofile(homedir .. "/scripts/timers/two_minute_timer.lua")
	dofile(homedir .. "/scripts/timers/player_queued_commands_timer.lua")
	dofile(homedir .. "/scripts/timers/gimme_queued_commands_timer.lua")
	if debug then dbug("done timers scripts") end

	-- triggers
	dofile(homedir .. "/scripts/triggers/pvp.lua")
	dofile(homedir .. "/scripts/triggers/match_all.lua")
	dofile(homedir .. "/scripts/triggers/player_info.lua")
	dofile(homedir .. "/scripts/triggers/player_connected.lua")
	dofile(homedir .. "/scripts/triggers/player_disconnected.lua")
	dofile(homedir .. "/scripts/triggers/end_list_players.lua")	
	dofile(homedir .. "/scripts/triggers/list_known_players.lua")
	dofile(homedir .. "/scripts/triggers/scouts.lua")
	dofile(homedir .. "/scripts/triggers/inventory_owner.lua")
	dofile(homedir .. "/scripts/triggers/air_drop_alert.lua")
	dofile(homedir .. "/scripts/triggers/game_time.lua")
	dofile(homedir .. "/scripts/triggers/game_tick_count.lua")
	dofile(homedir .. "/scripts/triggers/login_successful.lua")
	dofile(homedir .. "/scripts/triggers/collect_ban.lua")
	dofile(homedir .. "/scripts/triggers/unban_player.lua")
	dofile(homedir .. "/scripts/triggers/overstack.lua")
	dofile(homedir .. "/scripts/triggers/mem.lua")
	dofile(homedir .. "/scripts/triggers/lp.lua")
	dofile(homedir .. "/scripts/triggers/tele.lua")
	dofile(homedir .. "/scripts/triggers/llp.lua")
	if debug then dbug("done triggers scripts") end
		
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
	if debug then dbug("done enable triggers and timers") end

	if type(server) == "table" then	
		if server.windowGMSG ~= nil then
			alterTables() -- make sure all new table changes are done.  The server table is the most important to get updated.
			getPlayerFields() -- refresh player fields
			getServerFields() -- refresh server fields
			loadServer() -- force a reload incase new server fields have been added so they get initialised with default values.	
		
			openUserWindow(server.windowGMSG) 
			openUserWindow(server.windowDebug) 
			openUserWindow(server.windowLists) 
			openUserWindow(server.windowPlayers) 
			openUserWindow(server.windowAlerts) 
			
			for k,v in pairs(igplayers) do
				fixMissingIGPlayer(k)
			
				if accessLevel(k) < 3 then
					message("pm " .. k .. " [" .. chatColour .. "]The bot's scripts have reloaded.[-]")
				end
			end
			
			for k,v in pairs(players) do
				fixMissingPlayer(k)
			end			
			
			tempTimer( 2, [[send("teleh")]] )			
			tempTimer( 3, [[send("ubex_ubexv")]] )
		end
	end
	
	if server.ircMain ~= nil then
		irc_QueueMsg(server.ircMain, "The bot's scripts have reloaded.")
	end
	
	if debug then dbug("end reloadBotScripts") end
end
