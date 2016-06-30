--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_server()
	calledFunction = "gmsg_server"

	local debug, tmp
	local shortHelp = false
	local skipHelp = false

	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false

if debug then dbug("debug server 0") end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then		
			if chatvars.words[3] ~= "server" then
				skipHelp = true
			end
		end
		if chatvars.words[1] == "help" then
			skipHelp = false
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Server Commands:")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "================")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
	end

if debug then dbug("debug server 1") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "translate")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/translate on <player name>")	
		
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "If the Google translate API is installed, the bot will automatically translate the players chat to english.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "translate" and chatvars.words[2] == "on" and chatvars.words[3] ~= nil) then
		pname = string.sub(chatvars.command, string.find(chatvars.command, " on ") + 5)
		pname = string.trim(pname)
		id = LookupPlayer(pname)
		if not (id == nil) then
			players[id].translate = true
			message("say [" .. server.chatColour .. "]Chat from player " .. players[id].name ..  " will be translated to English.[-]")

			conn:execute("UPDATE players SET translate = 1 WHERE steam = " .. id)
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 2") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "translate")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/translate off <player name>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Stop translating the players chat.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "translate" and chatvars.words[2] == "off" and chatvars.words[3] ~= nil) then
		pname = string.sub(chatvars.command, string.find(chatvars.command, " off ") + 6)
		pname = string.trim(pname)
		id = LookupPlayer(pname)
		if not (id == nil) then
			players[id].translate = false
			message("say [" .. server.chatColour .. "]Chat from player " .. players[id].name ..  " will no longer be translated.[-]")

			conn:execute("UPDATE players SET translate = 0 WHERE steam = " .. id)
		end
		faultyChat = false
		return true
	end

if debug then dbug("debug server 3") end

	if (string.find(chatvars.words[1], "say") and (string.len(chatvars.words[1]) == 5) and chatvars.words[2] ~= nil) then
		msg = string.sub(chatvars.command, string.len(chatvars.words[1]) + 2)
		msg = string.trim(msg)

		if (msg ~= "") then
			Translate(chatvars.playerid, msg, string.sub(chatvars.words[1], 4), true)
		end
		faultyChat = false
		return true
	end

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then 
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return false
		end
	else
		if tonumber(chatvars.ircid) > 0 then
			if (accessLevel(chatvars.ircid) > 2) then
				faultyChat = false
				return false
			end
		end
	end
	-- ##################################################################

if debug then dbug("debug server 4") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "restore") or string.find(chatvars.command, "backup"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/restore backup")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot saves its Lua tables daily at midnight (server time) and each time the server is shut down.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "If the bot gets messed up, you can try to fix it with this command. Other timestamped backups are made before the bot is reset but you will first need to strip the date part off them to restore with this command.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "restore" and chatvars.words[2] == "backup") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		importLuaData()
		
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The last bot backup is restored.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "The last bot backup is restored.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 5") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, " irc")) or chatvars.words[1] ~= "help" then	
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set irc server <IP or URL and optional port>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Use this command if you want players to know your IRC server's address.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "irc" and chatvars.words[3] == "server") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		tmp = string.sub(chatvars.command, string.find(chatvars.command, "server") + 7)
		tmp = string.trim(tmp)

		if tmp == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A server name is required.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "A server name is required.")
			end
		else
			message("say [" .. server.chatColour .. "]We have an irc server at " .. tmp .. ". See you there! :3[-]")
			server.ircServer = tmp
			conn:execute("UPDATE server SET ircServer = '" .. escape(tmp) .. "'")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 6") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, " irc")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set irc main (or alerts, watch or tracker) <channel name without a # sign>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Change the bot's IRC channels. Note that the bot can only reside in the main channel which is currently hard-coded in Mudlet.  If the bot is not in the channel you set here, you will have to /msg the bot or issue all commands in private chat with the bot.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "irc") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		pname = chatvars.words[4]

		if chatvars.words[3] == "main" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The main irc channel is now " .. pname .. ", alerts is " ..  pname .. "_alerts" .. ", watch is " ..  pname .. "_watch" .. ", and _tracker is " ..  pname .. "_tracker" .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The main irc channel is now " .. pname .. ", alerts is " ..  pname .. "_alerts" .. ", watch is " ..  pname .. "_watch" .. ", and _tracker is " ..  pname .. "_tracker")			
			end

			server.ircMain = "#" .. pname
			server.ircAlerts = "#" .. pname .. "_alerts"
			server.ircWatch = "#" .. pname .. "_watch"
			server.ircTracker = "#" .. pname .. "_tracker"
		end

		if chatvars.words[3] == "alerts" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The alerts irc channel is now " .. pname .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The alerts irc channel is now " .. pname)
			end

			server.ircAlerts = "#" .. pname
		end

		if chatvars.words[3] == "watch" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The watch irc channel is now " .. pname .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The watch irc channel is now " .. pname)				
			end

			server.ircWatch = "#" .. pname
		end

		if chatvars.words[3] == "tracker" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The tracker irc channel is now " .. pname .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The tracker irc channel is now " .. pname)				
			end

			server.ircTracker = "#" .. pname
		end

		conn:execute("UPDATE server SET ircMain = '" .. server.ircMain .. "', ircAlerts = '" .. server.ircAlerts .. "', ircWatch = '" .. server.ircWatch .. "', ircTracker = '" .. server.ircTracker .. "'")

		faultyChat = false
		return true
	end

if debug then dbug("debug server 7") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/reboot")	
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "or /reboot <n> minute (or hour) (optional: forced)")
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "or /reboot now")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Schedule a timed or immediate server reboot.  The actual restart must be handled externally by something else.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Just before the reboot happens, the bot issues a save command. If you add forced, only a level 0 admin can stop it.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Shutting down the bot will also cancel a reboot but any automatic (timed) reboots will reschedule if the server wasn't also restarted.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reboot") then
			if server.allowReboot == false then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is disabled for this server.  Reboot manually.[-]")
				faultyChat = false
				return true
			end

		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if tonumber(chatvars.ircid) > 0 then
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
			end
		end

		if (chatvars.words[2] ~= "now") then
			if (server.scheduledRestart == true) then
				message("say [" .. server.chatColour .. "]A reboot is already scheduled.  Cancel it first.[-]")
				faultyChat = false
				return true
			end
		else
			scheduledReboot = false
			server.scheduledIdleRestart = false
			server.scheduledRestart = false
			server.scheduledRestartTimestamp = os.time()
			scheduledRestartPaused = false
			scheduledRestartForced = false

			if (rebootTimerID ~= nil) then killTimer(rebootTimerID) end
			if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end

			rebootTimerID = nil
			rebootTimerDelayID = nil

			send("sa")
			finishReboot()

			faultyChat = false
			return true
		end

		restartDelay = string.match(chatvars.command, "%d+")
		if (restartDelay == nil) then
			restartDelay = 120
			message("say [" .. server.chatColour .. "]A server reboot is happening in 2 minutes.[-]")
		end

		if (chatvars.playername ~= "Server") then
			if (accessLevel(chatvars.playerid) < 2) then
				if (string.find(chatvars.command, "forced")) then
					scheduledRestartForced = true
				end
			end
		end

		if (string.find(chatvars.command, "minute")) then
			message("say [" .. server.chatColour .. "]A server reboot is happening in " .. restartDelay .. " minutes.[-]")
			restartDelay = restartDelay * 60
		end

		if (string.find(chatvars.command, "hour")) then
			message("say [" .. server.chatColour .. "]A server reboot is happening in " .. restartDelay .. " hours time.[-]")
			restartDelay = restartDelay * 60 * 60
		end

		scheduledRestartPaused = false
		server.scheduledRestart = true
		server.scheduledRestartTimestamp = os.time() + restartDelay
		faultyChat = false
		return true
	end

if debug then dbug("debug server 8") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "prison")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set prison size <number>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Depreciated. Use /location prison size <number>")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "prison" and chatvars.words[3] == "size") then
		if chatvars.number ~= nil then
			server.prisonSize = math.floor(tonumber(chatvars.number) / 2)
			conn:execute("UPDATE server SET prisonSize = " .. server.prisonSize)
			location["prison"].size = server.prisonSize

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The prison is now " .. tonumber(chatvars.number) .. " meters wide.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The prison is now " .. tonumber(chatvars.number) .. " meters wide.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 9") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, " map")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set map size <number>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set the maximum distance from 0,0 that players are allowed to travel. Any players already outside this limit will be teleported to 0,0 and may get stuck under the map.  They can relog.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Size is in metres (blocks) and be careful not to set it too small.  The default map size is 10000 but the bot's default is 20000.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Whatever size you set, donors will be able to travel that far out but other players will be restricted to 5000 metres short of that.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "map" and chatvars.words[3] == "size") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			server.mapSize = chatvars.number
			message("say [" .. server.chatColour .. "]Players are now restricted to " .. chatvars.number .. " meters from 0,0[-]")

			conn:execute("UPDATE server SET mapSize = " .. chatvars.number)
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 10") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "cool") or string.find(chatvars.command, "timer"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set base cooldown <number in seconds> (default is 2400 or 40 minutes)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The /base or /home command can have a time delay between uses.  Donors wait half as long.  If you set it to 0 there is no wait time.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "base" and chatvars.words[3] == "cooldown") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			server.baseCooldown = chatvars.number
			conn:execute("UPDATE server SET baseCooldown = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes after using /base before it becomes available again.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Donors must wait " .. math.floor((tonumber(chatvars.number) / 60) / 2) .. " minutes.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes after using /base before it becomes available again.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Donors must wait " .. math.floor((tonumber(chatvars.number) / 60) / 2) .. " minutes.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 11") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "motd") or string.find(chatvars.command, "mess"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/motd")	
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/motd <your message here>")			
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/motd clear")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Display the current message of the day.  If an admin types anything after /motd the typed text becomes the new MOTD.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "To remove it type /motd clear")	
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "motd") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[2] == nil then
			if server.MOTD == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no MOTD set.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "There is no MOTD set.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.MOTD .. "[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, server.MOTD)
				end
			end
		else
			if chatvars.words[2] == "clear" then
				server.MOTD = nil
				conn:execute("UPDATE server SET MOTD = ''")
				
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]MOTD has been cleared.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "MOTD has been cleared.")
				end				
			else
				server.MOTD = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "motd") + 5)
				conn:execute("UPDATE server SET MOTD = '" .. escape(server.MOTD) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New message of the day recorded.[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.MOTD .. "[-]")				
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "New message of the day recorded.")
					irc_QueueMsg(players[chatvars.ircid].ircAlias, server.MOTD)				
				end
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 12") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/cancel reboot")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Cancel a scheduled reboot.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You may not be able to stop a forced or automatically scheduled reboot but you can pause it instead.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "cancel" and chatvars.words[2] == "reboot" and chatvars.words[3] == nil) then
		if (chatvars.playername ~= "Server") then
			if accessLevel(chatvars.playerid) > 1 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is for admins only[-]")
				faultyChat = false
				return true
			end
		end

		if (chatvars.playername ~= "Server") then
			if (scheduledRestartForced == true) and (accessLevel(chatvars.playerid) > 0) then
				message("say [" .. server.chatColour .. "]A forced reboot is scheduled and will proceed as planned.[-]")
				faultyChat = false
				return true
			end
		end

		scheduledReboot = false
		server.scheduledIdleRestart = false
		server.scheduledRestart = false
		server.scheduledRestartTimestamp = os.time()
		scheduledRestartPaused = false
		scheduledRestartForced = false

		if (rebootTimerID ~= nil) then killTimer(rebootTimerID) end
		if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end

		rebootTimerID = nil
		rebootTimerDelayID = nil

		message("say [" .. server.chatColour .. "]A server reboot has been cancelled.[-]")

		faultyChat = false
		return true
	end

if debug then dbug("debug server 13") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/pause reboot")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Pause a scheduled reboot.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "It will stay paused until you unpause it or restart the bot.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "pause" and chatvars.words[2] == "reboot" and chatvars.words[3] == nil) then
		if server.scheduledRestart == true and scheduledRestartPaused == false then
			scheduledRestartPaused = true
			restartTimeRemaining = server.scheduledRestartTimestamp - os.time()

			message("say [" .. server.chatColour .. "]The reboot has been paused.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 14") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/unpause reboot")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Resume a reboot.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "unpause" and chatvars.words[2] == "reboot" and chatvars.words[3] == nil) then
		if scheduledRestartPaused == true then
			server.scheduledRestartTimestamp = os.time() + restartTimeRemaining
			scheduledRestartPaused = false
			rebootTimer = restartTimeRemaining

			message("say [" .. server.chatColour .. "]The reboot countdown has resumed.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 15") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/enable (or disable) reboot")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "By default the bot does not manage server reboots.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "See also /set max uptime (default 12 hours)")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "reboot" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "enable" then
			server.allowReboot = true
			conn:execute("UPDATE server SET allowReboot = true")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will automatically reboot the server as needed.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "I will automatically reboot the server as needed.")
			end
		else
			server.allowReboot = false
			conn:execute("UPDATE server SET allowReboot = false")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will not reboot the server.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "I will not reboot the server.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 16") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " name") or string.find(chatvars.command, " bot"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/name bot <some cool name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The default name is Bot.  Help give your bot a personality by giving it a name.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "name" and chatvars.words[2] == "bot" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		tmp = stripQuotes(string.sub(chatvars.oldLine, string.find(chatvars.oldLine, chatvars.words[2], nil, true) + 4, string.len(chatvars.oldLine)))
		if tmp == "Tester" and chatvars.playerid ~= Smegz0r then
			message("say [" .. server.chatColour .. "]That name is reserved.[-]")
			faultyChat = false
			return true
		end

		server.botName = tmp
		message("say [" .. server.chatColour .. "]I shall henceforth be known as " .. server.botName .. ".[-]")

		msg = "say [" .. server.chatColour .. "]Hello I am the server bot, " .. server.botName .. ". Pleased to meet you. :3[-]"
		tempTimer( 5, [[message(msg)]] )

		conn:execute("UPDATE server SET botName = '" .. escape(server.botName) .. "'")

		faultyChat = false
		return true
	end

if debug then dbug("debug server 17") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "chat"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set chat colour <bbcolour code>")
		
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set the colour of server messages.  Player chat will be the default colour.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "chat" and (chatvars.words[3] == "colour" or chatvars.words[3] == "color")) then
		server.chatColour = chatvars.words[4]
		conn:execute("UPDATE server SET chatColour = '" .. escape(server.chatColour) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have changed my chat colour.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "You have changed my chat colour.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 18") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "web"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set website <your website or steam group>")
		
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Tell the bot the URL of your website or steam group so your players can ask for it.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "website") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		tmp = string.sub(chatvars.command, string.find(chatvars.command, "website") + 8)
		tmp = string.trim(tmp)

		if tmp == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A website or group is required.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "A website or group is required.")
			end
		else
			server.website = tmp
			conn:execute("UPDATE server SET website = '" .. escape(tmp) .. "'")

			message("say [" .. server.chatColour .. "]Our website/group is " .. tmp .. ". Check us out! :3[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 19") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "server") or string.find(chatvars.command, " ip"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set server ip <IP of your 7 Days to Die server>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot is unable to read the IP from its own profile for the server so enter it here.  It will display in the /info command and be used if a few other places.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "server" and chatvars.words[3] == "ip") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		tmp = chatvars.words[4]

		if tmp == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The server ip is required.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The server ip is required.")
			end
		else
			server.IP = tmp
			conn:execute("UPDATE server SET IP = '" .. escape(tmp) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The server ip is " .. tmp .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The server ip is " .. tmp)
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 20") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ping"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set (or clear) max ping <number>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "To kick high ping players set a max ping.  It will only be applied to new players. You can also whitelist a new player to make them exempt.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot doesn't immediately kick for high ping, it samples ping over 30 seconds and will only kick for a sustained high ping.")			
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" or chatvars.words[1] == "clear") and chatvars.words[2] == "max" and chatvars.words[3] == "ping" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "clear" then
			server.pingKick = -1
			conn:execute("UPDATE server SET pingKick = -1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Ping kicking is disabled.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Ping kicking is disabled.")
			end

			faultyChat = false
			return true
		end

		if chatvars.number ~= nil then
			if tonumber(chatvars.number) > -1 and tonumber(chatvars.number) < 100 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. chatvars.number .. " is quite low. Enter a number > 99[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, chatvars.number .. " is quite low. Enter a number > 99")
				end
			else
				server.pingKick = chatvars.number
				conn:execute("UPDATE server SET pingKick = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players with a ping above " .. chatvars.number .. " will be kicked from the server.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "New players with a ping above " .. chatvars.number .. " will be kicked from the server.")
				end
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 21") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "welc"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set (or clear) welcome message <your message here>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You can set a custom welcome message that will override the default greeting message when a player joins.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end


	if (chatvars.words[1] == "set" or chatvars.words[1] == "clear") and chatvars.words[2] == "welcome" and chatvars.words[3] == "message" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "clear" then
			server.welcome = nil
			conn:execute("UPDATE server SET welcome = null")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Server welcome message cleared.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Server welcome message cleared.")
			end

			faultyChat = false
			return true
		end

		msg = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "message") + 8)
		msg = string.trim(msg)

		server.welcome = msg
		conn:execute("UPDATE server SET welcome = '" .. escape(msg) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New welcome message " .. msg .. "[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "New welcome message " .. msg)
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 22") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "server") or string.find(chatvars.command, "pve") or string.find(chatvars.command, "pvp"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set server pve (or pvp, creative or contest)")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set the entire server to be PVE, PVP, Creative or Contest.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Contest mode is not implemented yet and all setting it creative does is stop the bot pestering players about their inventory.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" or chatvars.words[1] == "server") and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[3] == "pvp" then
			server.gameType = "pvp"
			server.northwestZone = "pvp"
			server.southwestZone = "pvp"
			server.northeastZone = "pvp"
			server.southeastZone = "pvp"
			message("say [" .. server.chatColour .. "]This server is now PVP.[-]")
			conn:execute("UPDATE server SET gameType = 'pvp', northwestZone = 'pvp', southwestZone = 'pvp', northeastZone = 'pvp', southeastZone = 'pvp'")

			faultyChat = false
			return true
		end

		if chatvars.words[3] == "pve" then
			server.gameType = "pve"
			server.northwestZone = "pve"
			server.southwestZone = "pve"
			server.northeastZone = "pve"
			server.southeastZone = "pve"
			message("say [" .. server.chatColour .. "]This server is now PVE.[-]")
			conn:execute("UPDATE server SET gameType = 'pve', northwestZone = 'pve', southwestZone = 'pve', northeastZone = 'pve', southeastZone = 'pve'")

			faultyChat = false
			return true
		end

		if chatvars.words[3] == "creative" then
			server.gameType = "cre"
			message("say [" .. server.chatColour .. "]This server is now creative.[-]")
			conn:execute("UPDATE server SET gameType = 'cre'")

			faultyChat = false
			return true
		end

		if chatvars.words[3] == "contest" then
			server.gameType = "con"
			message("say [" .. server.chatColour .. "]This server is now in contest mode.[-]")
			conn:execute("UPDATE server SET gameType = 'con'")

			faultyChat = false
			return true
		end

	end

if debug then dbug("debug server 23") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bad") or string.find(chatvars.command, "name"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/disallow bad names")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Auto-kick players with numeric names or names that contain no letters such as ascii art crap.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "They will see a kick message asking them to change their name.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "disallow" and chatvars.words[2] == "bad" and chatvars.words[3] == "names") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will kick players with names that have no letters.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "I will kick players with names that have no letters.")
		end

		server.allowNumericNames = false
		server.allowGarbageNames = false
		conn:execute("UPDATE server SET allowNumericNames = 0, allowGarbageNames = 0")

		faultyChat = false
		return true
	end

if debug then dbug("debug server 24") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bad") or string.find(chatvars.command, "name"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/allow bad names")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Allow numeric names or names that contain no letters such as ascii art.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "allow" and chatvars.words[2] == "bad" and chatvars.words[3] == "names") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can call themselves anything they like.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "]Players can call themselves anything they like.")
		end

		server.allowNumericNames = true
		server.allowGarbageNames = true
		conn:execute("UPDATE server SET allowNumericNames = 1, allowGarbageNames = 1")

		faultyChat = false
		return true
	end

if debug then dbug("debug server 25") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max") or string.find(chatvars.command, "zom"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/max zombies <number>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Change the server's max spawned zombies.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "max" and (chatvars.words[2] == "zeds" or chatvars.words[2] == "zombies") and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			if chatvars.number > 150 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. chatvars.number .. " is too high. Set a lower limit.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, chatvars.number .. " is too high. Set a lower limit.")
				end

				faultyChat = false
				return true
			end

			send("sg MaxSpawnedZombies " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Max spawned zombies is now " .. chatvars.number .. "[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Max spawned zombies is now " .. chatvars.number)
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 26") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/max players <number>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Change the server's max players. Admins can always join using the automated reserved slots feature.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "max" and chatvars.words[2] == "players" and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			send("sg ServerMaxPlayerCount " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Max players is now " .. chatvars.number .. "[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Max players is now " .. chatvars.number)
			end

		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 27") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max") or string.find(chatvars.command, "anim"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/max animals <number>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Change the server's max spawned animals.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "max" and chatvars.words[2] == "animals" and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			if chatvars.number > 150 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. chatvars.number .. " is too high. Set a lower limit.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, chatvars.number .. " is too high. Set a lower limit.")
				end

				faultyChat = false
				return true
			end

			send("sg MaxSpawnedAnimals " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Max spawned animals is now " .. chatvars.number .. "[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Max spawned animals is now " .. chatvars.number)
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 28") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set max uptime <number>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set how long (in hours) that the server can be running before the bot schedules a reboot.  The bot will always add 15 minutes as the reboot is only scheduled at that time.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "uptime" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			server.maxServerUptime = chatvars.number
			conn:execute("UPDATE server SET maxServerUptime = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will reboot the server when the server has been running " .. chatvars.number .. " hours.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "I will reboot the server when the server has been running " .. chatvars.number .. " hours.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 29") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " time") or string.find(chatvars.command, " play"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set new player timer <number> (in minutes)")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "By default a new player is treated differently from regulars and has some restrictions placed on them mainly concerning inventory.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set it to 0 to disable this feature.")			
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "new" and chatvars.words[3] == "player" and chatvars.words[4] == "timer" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			server.newPlayerTimer = chatvars.number
			conn:execute("UPDATE server SET newPlayerTimer = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players stop being new after " .. chatvars.number .. " minutes total play time.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "New players stop being new after " .. chatvars.number .. " minutes total play time.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 30") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "serv") or string.find(chatvars.command, "group"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set server group <group name> (one word)")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This is used by the bots database which could be a cloud database.  It is used to identify this bot as belonging to a group if you have more than one server.  You do not need to set this.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "server" and chatvars.words[3] == "group" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		tmp = {}
		tmp.group = chatvars.wordsOld[4]

		if tmp.group == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Group name required.  One word, no spaces.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Group name required.  One word, no spaces.")
			end

			faultyChat = false
			return true
		else
			server.group = tmp.group
			conn:execute("UPDATE server SET serverGroup = '" .. escape(tmp.group) .. "'")

			if db2Connected then
				-- update server in bots db
				connBots:execute("UPDATE servers SET serverGroup = '" .. escape(tmp.group) .. "' WHERE serverName = '" .. escape(server.ServerName) .. "'")
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This server is now a member of " .. tmp.group .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This server is now a member of " .. tmp.group .. ".")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 31") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "overs"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/allow overstack")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "By default the bot reads overstack warnings coming from the server to learn what the stack limits are and it will pester players with excessive stack sizes and can send them to timeout for non-compliance.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Use this command to disable this feature")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "allow" and string.find(chatvars.words[2], "overstack") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.allowOverstacking = true
		conn:execute("UPDATE server SET allowOverstacking = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will ignore overstacking.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "I will ignore overstacking.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 32") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "overs"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/disallow overstack")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot will warn players that are overstacking and will eventually send them to timeout if they continue overstacking.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disallow" and string.find(chatvars.words[2], "overstack") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.allowOverstacking = false
		conn:execute("UPDATE server SET allowOverstacking = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will monitor stack sizes, warn and alert for overstacking.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "I will monitor stack sizes, warn and alert for overstacking.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 33") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "black") or string.find(chatvars.command, " ban"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/blacklist action ban (or exile)")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set what happens to blacklisted players.  The default is to ban them 10 years but if you create a location called exile, the bot can bannish them to there instead.  It acts like a prison.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "blacklist" and string.find(chatvars.words[2], "action") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[3] ~= "exile" and chatvars.words[3] ~= "ban" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Expected ban or exile as 3rd word.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Expected ban or exile as 3rd word.")
			end

			faultyChat = false
			return true
		end

		server.blacklistResponse = chatvars.words[3]
		conn:execute("UPDATE server SET blacklistResponse  = '" .. escape(chatvars.words[3]) .. "'")

		if chatvars.words[3] == "ban" then
			chatvars.words[3] = "banned"
		else
			chatvars.words[3] = "exiled"
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Blacklisted players will be " .. chatvars.words[3] .. ".[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Blacklisted players will be " .. chatvars.words[3] .. ".")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 34") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " tele"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/show (or hide) teleports")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "If bot commands are hidden from chat, you can have the bot announce whenever a player teleports to a location (except /home).")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "show" and string.find(chatvars.words[2], "teleports") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.announceTeleports = true
		conn:execute("UPDATE server SET announceTeleports = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players teleporting to locations will be announced in chat.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players teleporting to locations will be announced in chat.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 35") end

	if chatvars.words[1] == "hide" and string.find(chatvars.words[2], "teleports") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.announceTeleports = false
		conn:execute("UPDATE server SET announceTeleports = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players teleporting to locations will be hidden from chat.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players teleporting to locations will be hidden from chat.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 36") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "map"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/setup map")
			
			if not shortHelp then	
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot can fix your server map's permissions with some nice settings.  If you use this command, the following permissions are set:")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "web.map 2000")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "webapi.getlandclaims 1000")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "webapi.viewallplayers 2")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "webapi.viewallclaims 2")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "webapi.getplayerinventory 2")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "webapi.getplayerslocation 2")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "webapi.getplayersonline 2000")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "webapi.getstats 2000")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "setup" and string.find(chatvars.words[2], "map") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		send("webpermission add web.map 2000")
		send("webpermission add webapi.getlandclaims 1000")
		send("webpermission add webapi.viewallplayers 2")
		send("webpermission add webapi.viewallclaims 2")
		send("webpermission add webapi.getplayerinventory 2")
		send("webpermission add webapi.getplayerslocation 2")
-- uncomment if you want everyone to see animal or zed locations
--		send("webpermission add webapi.gethostilelocation 2000")
--		send("webpermission add webapi.getanimalslocation 2000")
		send("webpermission add webapi.getplayersonline 2000")
		send("webpermission add webapi.getstats 2000")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The map permissions have been set.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "The map permissions have been set.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 37") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/northeast pve (or pvp)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Make northeast of 0,0 PVE or PVP.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "northeast" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command expects pvp or pve as 2nd part eg /northeast pvp.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg /northeast pvp.")
			end

			faultyChat = false
			return true
		end

		server.northeastZone = chatvars.words[2]
		conn:execute("UPDATE server SET northeastZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]Northeast of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Northeast of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 38") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/northwest pve (or pvp)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Make northwest of 0,0 PVE or PVP.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "northwest" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command expects pvp or pve as 2nd part eg /northwest pvp.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg /northwest pvp.")
			end

			faultyChat = false
			return true
		end

		server.northwestZone = chatvars.words[2]
		conn:execute("UPDATE server SET northwestZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]Northwest of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Northwest of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 39") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/southeast pve (or pvp)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Make southeast of 0,0 PVE or PVP.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "southeast" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command expects pvp or pve as 2nd part eg /southeast pvp.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg /southeast pvp.")
			end

			faultyChat = false
			return true
		end

		server.southeastZone = chatvars.words[2]
		conn:execute("UPDATE server SET southeastZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]Southeast of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Southeast of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 40") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/southwest pve (or pvp)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Make southwest of 0,0 PVE or PVP.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "southwest" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command expects pvp or pve as 2nd part eg /southwest pvp.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg /southwest pvp.")
			end

			faultyChat = false
			return true
		end

		server.southwestZone = chatvars.words[2]
		conn:execute("UPDATE server SET southwestZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]Southwest of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Southwest of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 41") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/north pve (or pvp)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Make north of 0,0 PVE or PVP.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "north" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command expects pvp or pve as 2nd part eg /north pvp.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg /north pvp.")
			end

			faultyChat = false
			return true
		end

		server.northeastZone = chatvars.words[2]
		server.northwestZone = chatvars.words[2]
		conn:execute("UPDATE server SET northwestZone = '" .. escape(chatvars.words[2]) .. "', northeastZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]North of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "North of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 42") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/south pve (or pvp)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Make south of 0,0 PVE or PVP.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "south" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command expects pvp or pve as 2nd part eg /south pvp.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg /south pvp.")
			end

			faultyChat = false
			return true
		end

		server.southeastZone = chatvars.words[2]
		server.southwestZone = chatvars.words[2]
		conn:execute("UPDATE server SET southwestZone = '" .. escape(chatvars.words[2]) .. "', southeastZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]South of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "South of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 43") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/east pve (or pvp)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Make east of 0,0 PVE or PVP.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "east" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command expects pvp or pve as 2nd part eg /east pvp.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg /east pvp.")
			end

			faultyChat = false
			return true
		end

		server.northeastZone = chatvars.words[2]
		server.southeastZone = chatvars.words[2]
		conn:execute("UPDATE server SET northeastZone = '" .. escape(chatvars.words[2]) .. "', southeastZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]East of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "East of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 44") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/west pve (or pvp)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Make west of 0,0 PVE or PVP.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "west" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command expects pvp or pve as 2nd part eg /west pvp.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg /west pvp.")
			end

			faultyChat = false
			return true
		end

		server.northwestZone = chatvars.words[2]
		server.southwestZone = chatvars.words[2]
		conn:execute("UPDATE server SET northwestZone = '" .. escape(chatvars.words[2]) .. "', southwestZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]West of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "West of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 45") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "fly") or string.find(chatvars.command, "hack") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/allow flying")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This disables the bot's hacker teleport detection.  You would want to do this if you allow creative mode or at least allow players to fly.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "allow" and chatvars.words[2] == "flying" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.playersCanFly = true
		conn:execute("UPDATE server SET playersCanFly = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players are allowed to fly![-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players are allowed to fly!")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 46") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "fly") or string.find(chatvars.command, "hack") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/disallow flying")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This enables the bot's hacker teleport detection.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disallow" and chatvars.words[2] == "flying" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.playersCanFly = false
		conn:execute("UPDATE server SET playersCanFly = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players may not fly![-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players may not fly!")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 47") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "overr") or string.find(chatvars.command, "acc"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/override access <number from 99 to 4>")	
		
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "All players have an access level which governs what they can do.  You can override it for everyone to temporarily raise their access.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "eg. /overide access 10 would make all players donors until you restore it.  To do that type /override access 99.  This is faster than giving individual players donor access if you just want to do a free donor weekend.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "override" and chatvars.words[2] == "access" and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			if chatvars.number < 3 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Do not set the access override lower than 3![-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "Do not set the access override lower than 3!")
				end

				faultyChat = false
				return true
			end

			server.accessLevelOverride = chatvars.number
			conn:execute("UPDATE server SET accessLevelOverride = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player access levels have been over-ridden! Minimum access level is now " .. chatvars.number .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Player access levels have been over-ridden! Minimum access level is now " .. chatvars.number .. ".")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 48") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "prot"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/disable base protection")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Base protection can be turned off server wide.  It does not make sense to use base protection on a PVP server.  Also it is not available anywhere that is set as a PVP zone on any server.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disable" and chatvars.words[2] == "base" and chatvars.words[3] == "protection" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.disableBaseProtection = true
		conn:execute("UPDATE server SET disableBaseProtection = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base protection is disabled server wide!  Only claim blocks will protect from player damage now.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Base protection is disabled server wide!  Only claim blocks will protect from player damage now.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 49") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "prot"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/enable base protection")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Base protection is available by default but a player needs to set theirs up to use it.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "enable" and chatvars.words[2] == "base" and chatvars.words[3] == "protection" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.disableBaseProtection = false
		conn:execute("UPDATE server SET disableBaseProtection = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base protection is enabled server wide!  The bot will keep unfriended players out of bases.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Base protection is enabled server wide!  The bot will keep unfriended players out of bases")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 50") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pack") or string.find(chatvars.command, "time") or string.find(chatvars.command, "cool"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set pack cooldown <number in seconds>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "By default players can type /pack when they respawn after a death to return to close to their pack.  You can set a delay before the command is available after a death.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "pack" and chatvars.words[3] == "cooldown" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			server.packCooldown = chatvars.number
			conn:execute("UPDATE server SET packCooldown = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]After death a player must wait " .. chatvars.number .. " seconds before they can use /pack.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "After death a player must wait " .. chatvars.number .. " seconds before they can use /pack.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 51") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bank") or string.find(chatvars.command, "cash"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/enable bank")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Enable zennies and the bank.  Zombie kills will earn zennies and the shop and gambling will be available if also enabled.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "enable" and chatvars.words[2] == "bank" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.allowBank = true
		conn:execute("UPDATE server SET allowBank = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This server uses game money.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "This server uses game money.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 52") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bank") or string.find(chatvars.command, "cash"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/disable bank")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You can disable zennies and the bank.  Zombie kills won't earn anything and the shop and gambling won't be available.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disable" and chatvars.words[2] == "bank" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.allowBank = false
		conn:execute("UPDATE server SET allowBank = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This server will not use game money.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "This server will not use game money.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 53") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "overs"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set overstack <number> (default 1000)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Sets the maximum stack size before the bot will warn a player about overstacking.  Usually the bot learns this directly from the server as stack sizes are exceeded.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "overstack" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.overstackThreshold = chatvars.number
		conn:execute("UPDATE server SET overstackThreshold = " .. chatvars.number)

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If no overstack limit is recorded, the minimum stack size to trigger an overstack warning is " .. server.overstackThreshold .. ".[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "If no overstack limit is recorded, the minimum stack size to trigger an overstack warning is " .. server.overstackThreshold .. ".")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 54") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "region") or string.find(chatvars.command, " pm"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/enable region pm")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Enable a PM for admins that tells them the region name when they move to a new region.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "enable" and chatvars.words[2] == "region" and chatvars.words[3] == "pm" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.enableRegionPM = true
		conn:execute("UPDATE server SET enableRegionPM = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The current region will be PM'ed to admins.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "The current region will be PM'ed to admins.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 55") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "region") or string.find(chatvars.command, " pm"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/disable region pm")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Disable a PM for admins that tells them the region name when they move to a new region.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disable" and chatvars.words[2] == "region" and chatvars.words[3] == "pm" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.enableRegionPM = false
		conn:execute("UPDATE server SET enableRegionPM = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The current region will not be PM'ed to admins.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "The current region will not be PM'ed to admins.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 56") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "lott") or string.find(chatvars.command, "gamb"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/open lottery")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Enable the daily lottery if it is currently disabled.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "open" and chatvars.words[2] == "lottery") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.allowLottery = true
		conn:execute("UPDATE server SET allowLottery = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The daily lottery will run at midnight.[-]")
		else
			irc_QueueMsg(server.ircMain, "The daily lottery will run at midnight.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 57") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "lott") or string.find(chatvars.command, "gamb"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/close lottery")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You can disable the lottery while keeping the shop and zennies in the game.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "close" and chatvars.words[2] == "lottery") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.allowLottery = false
		conn:execute("UPDATE server SET allowLottery = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The daily lottery is closed.[-]")
		else
			irc_QueueMsg(server.ircMain, "The daily lottery is closed.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 58") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "lott") or string.find(chatvars.command, "gamb"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set lottery multiplier <number>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Every zombie killed adds 1 x the lottery multiplier to the lottery total.  The higher the number, the faster the lottery rises.  The default is 2.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "lottery" and chatvars.words[3] == "multiplier" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			server.lotteryMultiplier = chatvars.number
			conn:execute("UPDATE server SET lotteryMultiplier = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The lottery will grow by zombie kills multiplied by " .. chatvars.number .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The lottery will grow by zombie kills multiplied by " .. chatvars.number)
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 59") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "zom") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set zombie reward <zennies>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set how many zennies a player earns for each zombie killed.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "zombie" and chatvars.words[3] == "reward" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			server.zombieKillReward = chatvars.number
			conn:execute("UPDATE server SET zombieKillReward = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will be awarded " .. chatvars.number .. " zennies for every zombie killed.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players will be awarded " .. chatvars.number .. " zennies for every zombie killed.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 60") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/clear whitelist")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Remove everyone from the bot's whitelist.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "clear" and chatvars.words[2] == "whitelist" and chatvars.words[3] == nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		conn:execute("TRUNCATE TABLE whitelist")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The whitelist has been cleared.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "The whitelist has been cleared.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 61") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/whitelist all")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You can add everyone except blacklisted players to the bot's whitelist.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "whitelist" and chatvars.words[2] == "everyone" or chatvars.words[2] == "all" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		for k,v in pairs(players) do
			if not string.find(server.blockCountries, v.country) then
				conn:execute("INSERT INTO whitelist (steam) VALUES (" .. k .. ")")				
			end
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Everyone except blacklisted players has been whitelisted.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Everyone except blacklisted players has been whitelisted.")
		end

		faultyChat = false
		return true
	end
	
if debug then dbug("debug server 61") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "disa"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/disable teleporting")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set this if you do not want your players using teleport commands. Admins can still teleport.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "disable" or chatvars.words[1] == "disallow") and chatvars.words[2] == "teleporting" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.allowTeleporting = false
		conn:execute("UPDATE server SET allowTeleporting = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not be able to use teleport commands.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players will not be able to use teleport commands.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 62") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "allow") or string.find(chatvars.command, "enab"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/enable teleporting")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set this if you want your players using teleport commands.  This is the default.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" or chatvars.words[1] == "allow") and chatvars.words[2] == "teleporting" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.allowTeleporting = true
		conn:execute("UPDATE server SET allowTeleporting = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can use teleport commands.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players can use teleport commands.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 63") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hard") or string.find(chatvars.command, "mode") or string.find(chatvars.command, "server"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/disable hardcore mode")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Allow players to use bot commands.  This is the default.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disable" and chatvars.words[2] == "hardcore" and chatvars.words[3] == "mode" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.hardcore = false
		conn:execute("UPDATE server SET hardcore = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can command the bot.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players can command the bot.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug server 64") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hard") or string.find(chatvars.command, "mode") or string.find(chatvars.command, "server"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/enable hardcore mode")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Don't let players use any bot commands.  Does not affect admins.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "enable" and chatvars.words[2] == "hardcore" and chatvars.words[3] == "mode" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.hardcore = true
		conn:execute("UPDATE server SET hardcore = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will ignore commands from players.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot will ignore commands from players.")
		end

		faultyChat = false
		return true
	end
	
if debug then dbug("debug server 65") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/fix shop")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Attempt to automatically fix the shop.  It reloads the shop categories, checks for any missing categories in shop items and assigns them to misc then reindexes the shop.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This fix is experimental and might not actually fix whatever is wrong with your shop.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "fix" and chatvars.words[2] == "shop" then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		fixShop()

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Try using the shop and see if it is fixed.  If not repeating the command is not going to fix it this time.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Try using the shop and see if it is fixed.  If not repeating the command is not going to fix it this time.")
		end

		faultyChat = false
		return true
	end
	
if debug then dbug("debug server 66") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "relog") or string.find(chatvars.command, "allow"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/allow rapid relog")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "New players who want to cheat often relog rapidly in order to spawn lots of items into the server using cheats or bugs.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command makes the bot ignore these and do nothing to stop them.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "allow" and chatvars.words[2] == "rapid" and string.find(chatvars.command, "relog") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.allowRapidRelogging = true
		conn:execute("UPDATE server SET allowRapidRelogging = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will do nothing about new players relogging multiple times rapidly.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot will do nothing about new players relogging multiple times rapidly.")
		end

		faultyChat = false
		return true
	end
	
if debug then dbug("debug server 67") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "relog") or string.find(chatvars.command, "allow"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/disallow rapid relog")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "New players who want to cheat often relog rapidly in order to spawn lots of items into the server using cheats or bugs.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command makes the bot temp ban new players found to be relogging many times less than a minute apart.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disallow" and chatvars.words[2] == "rapid" and string.find(chatvars.command, "relog") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		server.allowRapidRelogging = false
		conn:execute("UPDATE server SET allowRapidRelogging = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will temp ban new players that are relogging multiple times rapidly.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot will temp ban new players that are relogging multiple times rapidly.")
		end

		faultyChat = false
		return true
	end
	
if debug then dbug("debug server 68") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "kick"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/idle kick on (off is default)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "When the server is full, if idle kick is on players will get kick warnings for 15 minutes of no movement then they get kicked.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "idle" and chatvars.words[2] == "kick" and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
				return true
			end
		end

		if chatvars.words[3] == "on" then
			server.idleKick = true
			conn:execute("UPDATE server SET idleKick = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]When the server is full, idling players will get kick warnings for 15 minutes then kicked if they don't move.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "When the server is full, idling players will get kick warnings for 15 minutes then kicked if they don't move.")
			end
		end
		
		if chatvars.words[3] == "off" then
			server.idleKick = false
			conn:execute("UPDATE server SET idleKick = 0")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not be kicked for idling on the server.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players will not be kicked for idling on the server.")
			end
		end
		
		if chatvars.words[3] ~= "on" and chatvars.words[3] ~= "off" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid command is /idle kick on or /idle kick off.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Valid command is /idle kick on or /idle kick off.")
			end		
		end

		faultyChat = false
		return true
	end
	
if debug then dbug("debug server 69") end

-- ###################  do not allow remote commands beyond this point ################
	
	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Server In-Game Only:")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "========================")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "server"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/reset server")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Tell the bot to forget everything it knows about the server.  You will be asked to confirm this, answer with yes.  Say anything else to abort.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Usually you only need to use /reset bot.  This reset goes further.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reset") and (chatvars.words[2] == "server") and (chatvars.playerid ~= 0) then
		if accessLevel(chatvars.playerid) > 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Are you sure you want to wipe me completely clean?  Answer yes to proceed or anything else to cancel.[-]")
		igplayers[chatvars.playerid].botQuestion = "reset server"

		faultyChat = false
		return true
	end

if debug then dbug("debug server 69") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "bot"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/reset bot")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Tell the bot to forget only some things, some player info, locations, bases etc.  You will be asked to confirm this, answer with yes.  Say anything else to abort.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Use this command after wiping the server.  The bot will detect the day change and will ask if you want to reset the bot too.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reset") and (chatvars.words[2] == "bot") and (chatvars.playerid ~= 0) then
		if accessLevel(chatvars.playerid) > 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Are you sure you want to reset me?  Answer yes to proceed or anything else to cancel.[-]")
		igplayers[chatvars.playerid].botQuestion = "reset bot"

		faultyChat = false
		return true
	end

if debug then dbug("debug server 70") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/no reset")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "If the bot detects that the server days have rolled back, it will ask you if you want to reset the bot.  Type /no reset if you don't want the bot to reset itself.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "no") and (chatvars.words[2] == "reset") and (chatvars.playerid ~= 0) then
		if accessLevel(chatvars.playerid) > 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true3
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Oh ok then.[-]")
		server.warnBotReset = false

		faultyChat = false
		return true
	end

if debug then dbug("debug server end") end

end
