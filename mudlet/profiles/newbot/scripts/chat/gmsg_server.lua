--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

--  weathersurvival on/off

local debug = false
function gmsg_server()
	calledFunction = "gmsg_server"

	local tmp
	local shortHelp = false
	local skipHelp = false
	local tmp

	if debug then dbug("debug server") end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
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
		irc_chat(players[chatvars.ircid].ircAlias, "")
		irc_chat(players[chatvars.ircid].ircAlias, "Server Commands:")
		irc_chat(players[chatvars.ircid].ircAlias, "================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if chatvars.showHelpSections then
		irc_chat(players[chatvars.ircid].ircAlias, "server")
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "translate")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "translate on <player name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "If the Google translate API is installed, the bot will automatically translate the players chat to english.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
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

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "translate")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "translate off <player name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Stop translating the players chat.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
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
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if (string.find(chatvars.words[1], "say") and (string.len(chatvars.words[1]) == 5) and chatvars.words[2] ~= nil) then
		msg = string.sub(chatvars.command, string.len(chatvars.words[1]) + 2)
		msg = string.trim(msg)

		if (msg ~= "") then
			Translate(chatvars.playerid, msg, string.sub(chatvars.words[1], 4), true)
		end
		botman.faultyChat = false
		return true
	end

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return false
		end
	else
		if (chatvars.ircid) then
			if(tonumber(chatvars.ircid) > 2) then
					botman.faultyChat = false
				return false
			end
		end
	end
	-- ##################################################################

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "run") or string.find(chatvars.command, "comm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "run command <a console command>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Sometimes you need to make the bot run a specific console command.")
				irc_chat(players[chatvars.ircid].ircAlias, "This can be used to force the bot re-parse a list.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "run" and chatvars.words[2] == "command" and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		tmp = string.sub(line, string.find(line, "command") + 8)
		send(tmp)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "restore") or string.find(chatvars.command, "backup"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "restore backup")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot saves its Lua tables daily at midnight (server time) and each time the server is shut down.")
				irc_chat(players[chatvars.ircid].ircAlias, "If the bot gets messed up, you can try to fix it with this command. Other timestamped backups are made before the bot is reset but you will first need to strip the date part off them to restore with this command.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "restore" and (chatvars.words[2] == "backup" or chatvars.words[2] == "bot") and chatvars.words[3] == nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		importLuaData()

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The backup has been restored.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "The backup has been restored.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, " irc")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set irc server <IP or URL and optional port>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Use this command if you want players to know your IRC server's address.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "irc" and chatvars.words[3] == "server") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		tmp = string.sub(chatvars.command, string.find(chatvars.command, "server") + 7)
		tmp = string.trim(tmp)

		if tmp == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]A server name is required.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "A server name is required.")
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The IRC server is now at " .. tmp .. "[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The IRC server is now at " .. tmp)
			end

			temp = string.split(tmp, ":")
			server.ircServer = temp[1]
			server.ircPort = temp[2]

			conn:execute("UPDATE server SET ircServer = '" .. escape(server.ircServer) .. "', ircPort = '" .. escape(server.ircPort) .. "'")

			joinIRCServer()
			ircSaveSessionConfigs()
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, " irc")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set irc main (or alerts, watch or tracker) <channel name without a # sign>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Change the bot's IRC channels. Note that the bot can only reside in the main channel which is currently hard-coded in Mudlet.  If the bot is not in the channel you set here, you will have to /msg the bot or issue all commands in private chat with the bot.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "irc") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		pname = chatvars.words[4]

		if chatvars.words[3] == "main" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The main irc channel is now " .. pname .. ", alerts is " ..  pname .. "_alerts" .. ", watch is " ..  pname .. "_watch" .. ", and _tracker is " ..  pname .. "_tracker" .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The main irc channel is now " .. pname .. ", alerts is " ..  pname .. "_alerts" .. ", watch is " ..  pname .. "_watch")
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
				irc_chat(players[chatvars.ircid].ircAlias, "The alerts irc channel is now " .. pname)
			end

			server.ircAlerts = "#" .. pname
		end

		if chatvars.words[3] == "watch" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The watch irc channel is now " .. pname .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The watch irc channel is now " .. pname)
			end

			server.ircWatch = "#" .. pname
		end

		if chatvars.words[3] == "tracker" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The tracker irc channel is now " .. pname .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The tracker irc channel is now " .. pname)
			end

			server.ircTracker = "#" .. pname
		end

		conn:execute("UPDATE server SET ircMain = '" .. server.ircMain .. "', ircAlerts = '" .. server.ircAlerts .. "', ircWatch = '" .. server.ircWatch .. "', ircTracker = '" .. server.ircTracker .. "'")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reboot")
			irc_chat(players[chatvars.ircid].ircAlias, "or " .. server.commandPrefix .. "reboot <n> minute (or hour) (optional: forced)")
			irc_chat(players[chatvars.ircid].ircAlias, "or " .. server.commandPrefix .. "reboot now")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Schedule a timed or immediate server reboot.  The actual restart must be handled externally by something else.")
				irc_chat(players[chatvars.ircid].ircAlias, "Just before the reboot happens, the bot issues a save command. If you add forced, only a level 0 admin can stop it.")
				irc_chat(players[chatvars.ircid].ircAlias, "Shutting down the bot will also cancel a reboot but any automatic (timed) reboots will reschedule if the server wasn't also restarted.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reboot") then
			if server.allowReboot == false then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is disabled for this server.  Reboot manually.[-]")
				botman.faultyChat = false
				return true
			end

		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if(chatvars.ircid) then
				if(tonumber(chatvars.ircid) > 0 and chatvars.accessLevel > 1) then
					irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end
		end

		if (chatvars.words[2] ~= "now") then
			if (botman.scheduledRestart == true) then
				message("say [" .. server.warnColour .. "]A reboot is already scheduled.  Cancel it first.[-]")
				botman.faultyChat = false
				return true
			end
		else
			botman.scheduledRestart = false
			botman.scheduledRestartTimestamp = getRestartOffset()
			botman.scheduledRestartPaused = false
			botman.scheduledRestartForced = false

			if (botman.rebootTimerID ~= nil) then killTimer(botman.rebootTimerID) end
			if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end

			botman.rebootTimerID = nil
			rebootTimerDelayID = nil

			send("sa")
			finishReboot()

			botman.faultyChat = false
			return true
		end

		restartDelay = string.match(chatvars.command, "%d+")
		if (restartDelay == nil) then
			restartDelay = 120
			message("say [" .. server.chatColour .. "]A server reboot is happening in 2 minutes.[-]")
		end

		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel < 2) then
				if (string.find(chatvars.command, "forced")) then
					botman.scheduledRestartForced = true
				end
			end
		end

		if (string.find(chatvars.command, "minute")) then
			if restartDelay == 1 then
				message("say [" .. server.chatColour .. "]A server reboot is happening in " .. restartDelay .. " minute.[-]")
			else
				message("say [" .. server.chatColour .. "]A server reboot is happening in " .. restartDelay .. " minutes.[-]")
			end

			restartDelay = restartDelay * 60
		end

		if (string.find(chatvars.command, "hour")) then
			message("say [" .. server.chatColour .. "]A server reboot is happening in " .. restartDelay .. " hours time.[-]")
			echo("A server reboot is happening in " .. restartDelay .. " hours time.\n\n")
			restartDelay = restartDelay * 3600
		end

		botman.scheduledRestartPaused = false
		botman.scheduledRestart = true
		botman.scheduledRestartTimestamp = getRestartOffset() + restartDelay
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "prison")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set prison size <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Depreciated. Use " .. server.commandPrefix .. "location prison size <number>")
				irc_chat(players[chatvars.ircid].ircAlias, "")
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
				irc_chat(players[chatvars.ircid].ircAlias, "The prison is now " .. tonumber(chatvars.number) .. " meters wide.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, " map")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set map size <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set the maximum distance from 0,0 that players are allowed to travel. Any players already outside this limit will be teleported to 0,0 and may get stuck under the map.  They can relog.")
				irc_chat(players[chatvars.ircid].ircAlias, "Size is in metres (blocks) and be careful not to set it too small.  The default map size is 10000 but the bot's default is 20000.")
				irc_chat(players[chatvars.ircid].ircAlias, "Whatever size you set, donors will be able to travel 5km futher out so the true boundary is +5000.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "map" and chatvars.words[3] == "size") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			server.mapSize = chatvars.number
			message("say [" .. server.chatColour .. "]Players are now restricted to " .. tonumber(chatvars.number) + 5000 .. " meters from 0,0[-]")

			conn:execute("UPDATE server SET mapSize = " .. chatvars.number)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "cool") or string.find(chatvars.command, "timer"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set base cooldown <number in seconds> (default is 2400 or 40 minutes)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The " .. server.commandPrefix .. "base or " .. server.commandPrefix .. "home command can have a time delay between uses.  Donors wait half as long.  If you set it to 0 there is no wait time.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "base" and chatvars.words[3] == "cooldown") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			server.baseCooldown = chatvars.number
			conn:execute("UPDATE server SET baseCooldown = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes after using " .. server.commandPrefix .. "base before it becomes available again.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Donors must wait " .. math.floor((tonumber(chatvars.number) / 60) / 2) .. " minutes.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes after using " .. server.commandPrefix .. "base before it becomes available again.")
				irc_chat(players[chatvars.ircid].ircAlias, "Donors must wait " .. math.floor((tonumber(chatvars.number) / 60) / 2) .. " minutes.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "motd") or string.find(chatvars.command, "mess"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "motd")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "motd (or " .. server.commandPrefix .. "set motd) <your message here>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "motd clear")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Display the current message of the day.  If an admin types anything after " .. server.commandPrefix .. "motd the typed text becomes the new MOTD.")
				irc_chat(players[chatvars.ircid].ircAlias, "To remove it type " .. server.commandPrefix .. "motd clear")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "motd") or (chatvars.words[1] == "set" and chatvars.words[2] == "motd") then
		if chatvars.words[2] == nil then
			if server.MOTD == nil then
				if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]There is no MOTD set.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "There is no MOTD set.")
				end
			else
				if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

				if (chatvars.playername ~= "Server") then
					if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "print motd for player: " .. chatvars.playerid .. "(" .. server.MOTD .. ")") end
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.MOTD .. "[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, server.MOTD)
				end
			end
		else

		if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

                if (chatvars.playername ~= "Server") then
                        if (chatvars.accessLevel > 0) then
                                message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
                                botman.faultyChat = false
                                return true
                        end
                else
                        if (chatvars.accessLevel > 0) then
                                if(players[chatvars.ircid]) then
                                        irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
                                else
                                        dbugFull("I", "", "", chatvars.command .. " is a restricted command.")
                                end
                                botman.faultyChat = false
                                return true
                        end
                end

			if chatvars.words[2] == "clear" then
				server.MOTD = nil
				conn:execute("UPDATE server SET MOTD = ''")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]MOTD has been cleared.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "MOTD has been cleared.")
				end
			else
				server.MOTD = stripQuotes(string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "motd") + 5))
				conn:execute("UPDATE server SET MOTD = '" .. escape(server.MOTD) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New message of the day recorded.[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.MOTD .. "[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "New message of the day recorded.")
					irc_chat(players[chatvars.ircid].ircAlias, server.MOTD)
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rules") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set rules <new rules>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set the server rules.  You can use supported bbcode tags, but only when setting the rules from IRC.  All tags must be closed with [-].")
				irc_chat(players[chatvars.ircid].ircAlias, "To display the rules type " .. server.commandPrefix .. "rules")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "rules" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.rules = stripQuotes(string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "rules") + 6))
		conn:execute("UPDATE server SET rules = '" .. escape(server.rules) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New rules recorded.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.rules .. "[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "New rules recorded.")
			irc_chat(players[chatvars.ircid].ircAlias, server.rules)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "cancel reboot")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Cancel a scheduled reboot.")
				irc_chat(players[chatvars.ircid].ircAlias, "You may not be able to stop a forced or automatically scheduled reboot but you can pause it instead.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "cancel" and chatvars.words[2] == "reboot" and chatvars.words[3] == nil) then
		if (chatvars.playername ~= "Server") then
			if chatvars.accessLevel > 1 then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is for admins only[-]")
				botman.faultyChat = false
				return true
			end
		end

		if (chatvars.playername ~= "Server") then
			if (botman.scheduledRestartForced == true) and (chatvars.accessLevel > 0) then
				message("say [" .. server.warnColour .. "]A forced reboot is scheduled and will proceed as planned.[-]")
				botman.faultyChat = false
				return true
			end
		end

--		scheduledReboot = false
--		server.scheduledIdleRestart = false
		botman.scheduledRestart = false
		botman.scheduledRestartTimestamp = getRestartOffset()
		botman.scheduledRestartPaused = false
		botman.scheduledRestartForced = false

		if (botman.rebootTimerID ~= nil) then killTimer(botman.rebootTimerID) end
		if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end

		botman.rebootTimerID = nil
		rebootTimerDelayID = nil

		message("say [" .. server.chatColour .. "]A server reboot has been cancelled.[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "pause reboot")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Pause a scheduled reboot.")
				irc_chat(players[chatvars.ircid].ircAlias, "It will stay paused until you unpause it or restart the bot.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "pause" or chatvars.words[1] == "paws" and chatvars.words[2] == "reboot" and chatvars.words[3] == nil) then
		if botman.scheduledRestart == true and botman.scheduledRestartPaused == false then
			botman.scheduledRestartPaused = true
			restartTimeRemaining = botman.scheduledRestartTimestamp - os.time()
			if(restartTimeRemaining < 0) then
				restartTimeRemaining = 0
			end

			message("say [" .. server.chatColour .. "]The reboot has been paused.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "unpause (or resume) reboot")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Resume a reboot.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "unpause" or chatvars.words[1] == "unpaws" or chatvars.words[1] == "resume" and chatvars.words[2] == "reboot" and chatvars.words[3] == nil) then
		if botman.scheduledRestartPaused == true then
			botman.scheduledRestartTimestamp = os.time() + restartTimeRemaining
			botman.scheduledRestartPaused = false
			rebootTimer = restartTimeRemaining

			message("say [" .. server.chatColour .. "]The reboot countdown has resumed.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable (or disable) reboot")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "By default the bot does not manage server reboots.")
				irc_chat(players[chatvars.ircid].ircAlias, "See also " .. server.commandPrefix .. "set max uptime (default 12 hours)")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "reboot" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "enable" then
			server.allowReboot = true
			conn:execute("UPDATE server SET allowReboot = true")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will automatically reboot the server as needed.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "I will automatically reboot the server as needed.")
			end
		else
			server.allowReboot = false
			conn:execute("UPDATE server SET allowReboot = false")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will not reboot the server.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "I will not reboot the server.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " name") or string.find(chatvars.command, " bot"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "name bot <some cool name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The default name is Bot.  Help give your bot a personality by giving it a name.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "name" and chatvars.words[2] == "bot" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		tmp = stripQuotes(string.sub(chatvars.oldLine, string.find(chatvars.oldLine, chatvars.words[2], nil, true) + 4, string.len(chatvars.oldLine)))
		if tmp == "Tester" and chatvars.playerid ~= Smegz0r then
			message("say [" .. server.warnColour .. "]That name is reserved.[-]")
			botman.faultyChat = false
			return true
		end

		server.botName = tmp
		message("say [" .. server.chatColour .. "]I shall henceforth be known as " .. server.botName .. ".[-]")

		msg = "say [" .. server.chatColour .. "]Hello I am the server bot, " .. server.botName .. ". Pleased to meet you. :3[-]"
		tempTimer( 5, [[message(msg)]] )

		conn:execute("UPDATE server SET botName = '" .. escape(server.botName) .. "'")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set chat colour <bbcolour code>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set the colour of server messages.  Player chat will be the default colour.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "chat" and string.find(chatvars.words[3], "colo") then
		server.chatColour = chatvars.words[4]
		conn:execute("UPDATE server SET chatColour = '" .. escape(server.chatColour) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have changed my chat colour.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "You have changed my chat colour.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "warn") or string.find(chatvars.command, "colo"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set warn colour <bbcolour code>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set the colour of server warning messages.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "warn" and string.find(chatvars.words[3], "colo") then
		server.warnColour = chatvars.words[4]
		conn:execute("UPDATE server SET warnColour = '" .. escape(server.warnColour) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You have changed the colour for warning messages from me.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "You have changed the colour for warning messages from me.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "alert") or string.find(chatvars.command, "colo"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set alert colour <bbcolour code>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set the colour of server alert messages.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "alert" and string.find(chatvars.words[3], "colo") then
		server.alertColour = chatvars.words[4]
		conn:execute("UPDATE server SET alertColour = '" .. escape(server.alertColour) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.alertColour .. "]You have changed the colour for alert messages from me.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "You have changed the colour for alert messages from me.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "web"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set website <your website or steam group>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Tell the bot the URL of your website or steam group so your players can ask for it.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "website") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				if(players[chatvars.ircid]) then
					irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				else 
					dbugFull("D", "", "", "set website is a restricted command.")
				end
				botman.faultyChat = false
				return true
			end
		end

		tmp = string.sub(chatvars.command, string.find(chatvars.command, "website") + 8)
		tmp = string.trim(tmp)

		if tmp == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]A website or group is required.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "A website or group is required.")
			end
		else
			server.website = tmp
			conn:execute("UPDATE server SET website = '" .. escape(tmp) .. "'")

			message("say [" .. server.chatColour .. "]Our website/group is " .. tmp .. ". Check us out! :3[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "server") or string.find(chatvars.command, " ip"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set server ip <IP of your 7 Days to Die server>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot is unable to read the IP from its own profile for the server so enter it here.  It will display in the " .. server.commandPrefix .. "info command and be used if a few other places.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "server" and chatvars.words[3] == "ip") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		tmp = chatvars.words[4]

		if tmp == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]The server ip is required.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The server ip is required.")
			end
		else
			server.IP = tmp
			conn:execute("UPDATE server SET IP = '" .. escape(tmp) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The server ip is now " .. tmp .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The server ip is now " .. tmp)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ping"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set (or clear) max ping <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "To kick high ping players set a max ping.  It will only be applied to new players. You can also whitelist a new player to make them exempt.")
				irc_chat(players[chatvars.ircid].ircAlias, "The bot doesn't immediately kick for high ping, it samples ping over 30 seconds and will only kick for a sustained high ping.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" or chatvars.words[1] == "clear") and chatvars.words[2] == "max" and chatvars.words[3] == "ping" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "clear" then
			server.pingKick = -1
			conn:execute("UPDATE server SET pingKick = -1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Ping kicking is disabled.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Ping kicking is disabled.")
			end

			botman.faultyChat = false
			return true
		end

		if chatvars.number ~= nil then
			if tonumber(chatvars.number) > -1 and tonumber(chatvars.number) < 100 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. chatvars.number .. " is quite low. Enter a number > 99[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, chatvars.number .. " is quite low. Enter a number > 99")
				end
			else
				server.pingKick = chatvars.number
				conn:execute("UPDATE server SET pingKick = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players with a ping above " .. chatvars.number .. " will be kicked from the server.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "New players with a ping above " .. chatvars.number .. " will be kicked from the server.")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "welc"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set (or clear) welcome message <your message here>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "You can set a custom welcome message that will override the default greeting message when a player joins.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end


	if (chatvars.words[1] == "set" or chatvars.words[1] == "clear") and chatvars.words[2] == "welcome" and chatvars.words[3] == "message" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "clear" then
			server.welcome = nil
			conn:execute("UPDATE server SET welcome = null")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Server welcome message cleared.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Server welcome message cleared.")
			end

			botman.faultyChat = false
			return true
		end

		msg = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "message") + 8)
		msg = string.trim(msg)

		server.welcome = msg
		conn:execute("UPDATE server SET welcome = '" .. escape(msg) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New welcome message " .. msg .. "[-]")
		else
			if(chatvars.ircid) then
				if(players[chatvars.ircid]) then
					irc_chat(players[chatvars.ircid].ircAlias, "New welcome message " .. msg)
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "server") or string.find(chatvars.command, "pve") or string.find(chatvars.command, "pvp"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set server pve (or pvp, creative or contest)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set the entire server to be PVE, PVP, Creative or Contest.")
				irc_chat(players[chatvars.ircid].ircAlias, "Contest mode is not implemented yet and all setting it creative does is stop the bot pestering players about their inventory.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "server") and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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

			botman.faultyChat = false
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

			botman.faultyChat = false
			return true
		end

		if chatvars.words[3] == "creative" then
			server.gameType = "cre"
			message("say [" .. server.chatColour .. "]This server is now creative.[-]")
			conn:execute("UPDATE server SET gameType = 'cre'")

			botman.faultyChat = false
			return true
		end

		if chatvars.words[3] == "contest" then
			server.gameType = "con"
			message("say [" .. server.chatColour .. "]This server is now in contest mode.[-]")
			conn:execute("UPDATE server SET gameType = 'con'")

			botman.faultyChat = false
			return true
		end

	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set pvp cooldown <seconds>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set how long after a pvp kill before the player can use teleport commands again.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "pvp" and (chatvars.words[3] == "cooldown" or chatvars.words[3] == "delay" or chatvars.words[3] == "timer") and chatvars.words[4] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(chatvars.number) -- eliminate the negative

			if (chatvars.playername ~= "Server") then
				message(string.format("pm %s [%s]Players must wait %s seconds after killing a player before they can teleport.[-]", chatvars.playerid, server.chatColour, chatvars.number))
			else
				irc_chat(players[chatvars.ircid].ircAlias, string.format("Players must wait %s seconds after killing a player before they can teleport.", chatvars.number))
			end

			server.pvpTeleportCooldown = chatvars.number
			conn:execute("UPDATE server SET pvpTeleportCooldown = " .. chatvars.number)
		else
			if (chatvars.playername ~= "Server") then
				message(string.format("pm %s [%s]A number (seconds) is required.  Set to 0 to have no timer.[-]", chatvars.playerid, server.chatColour))
			else
				irc_chat(players[chatvars.ircid].ircAlias, "A number (seconds) is required.  Set to 0 to have no timer.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bad") or string.find(chatvars.command, "name"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disallow bad names")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Auto-kick players with numeric names or names that contain no letters such as ascii art crap.")
				irc_chat(players[chatvars.ircid].ircAlias, "They will see a kick message asking them to change their name.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "disallow" and chatvars.words[2] == "bad" and chatvars.words[3] == "names") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will kick players with names that have no letters.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "I will kick players with names that have no letters.")
		end

		server.allowNumericNames = false
		server.allowGarbageNames = false
		conn:execute("UPDATE server SET allowNumericNames = 0, allowGarbageNames = 0")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bad") or string.find(chatvars.command, "name"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "allow bad names")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Allow numeric names or names that contain no letters such as ascii art.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "allow" and chatvars.words[2] == "bad" and chatvars.words[3] == "names") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can call themselves anything they like.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "]Players can call themselves anything they like.")
		end

		server.allowNumericNames = true
		server.allowGarbageNames = true
		conn:execute("UPDATE server SET allowNumericNames = 1, allowGarbageNames = 1")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max") or string.find(chatvars.command, "zom"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set max zombies <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Change the server's max spawned zombies.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "max" and (chatvars.words[3] == "zeds" or chatvars.words[3] == "zombies") and chatvars.words[4] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			if chatvars.number > 150 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. chatvars.number .. " is too high. Set a lower limit.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, chatvars.number .. " is too high. Set a lower limit.")
				end

				botman.faultyChat = false
				return true
			end

			send("sg MaxSpawnedZombies " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Max spawned zombies is now " .. chatvars.number .. "[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Max spawned zombies is now " .. chatvars.number)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set max players <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Change the server's max players. Admins can always join using the automated reserved slots feature.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "players" and chatvars.words[4] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			send("sg ServerMaxPlayerCount " .. chatvars.number)
			server.maxPlayers = chatvars.number
			conn:execute("UPDATE server SET maxPlayers = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Max players is now " .. chatvars.number .. "[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Max players is now " .. chatvars.number)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max") or string.find(chatvars.command, "anim"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set max animals <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Change the server's max spawned animals.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "animals" and chatvars.words[4] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			if chatvars.number > 150 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. chatvars.number .. " is too high. Set a lower limit.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, chatvars.number .. " is too high. Set a lower limit.")
				end

				botman.faultyChat = false
				return true
			end

			send("sg MaxSpawnedAnimals " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Max spawned animals is now " .. chatvars.number .. "[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Max spawned animals is now " .. chatvars.number)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, "info: " .. server.commandPrefix .. "max uptime")
			irc_chat(players[chatvars.ircid].ircAlias, "set: " .. server.commandPrefix .. "set max uptime <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set how long (in hours) that the server can be running before the bot schedules a reboot.  The bot will always add 15 minutes as the reboot is only scheduled at that time.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "max" and chatvars.words[2] == "uptime" and chatvars.words[3] == nil then
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Max server uptime is " .. server.maxServerUptime .. " hours.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Change it with " .. server.commandPrefix .. "set max uptime <hours>[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Max server uptime is " .. server.maxServerUptime .. " hours.")
			irc_chat(players[chatvars.ircid].ircAlias, "Change it with cmd " .. server.commandPrefix .. "set max uptime <hours>")
		end

		botman.faultyChat = false
		return true
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "uptime" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (chatvars.accessLevel > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				if(players[chatvars.ircid]) then
					irc_chat(players[chatvars.ircid].ircAlias, "I will reboot the server when the server has been running " .. chatvars.number .. " hours.")
				else
					irc_chat("Server", "I will reboot the server when the server has been running " .. chatvars.number .. " hours.")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " time") or string.find(chatvars.command, " play"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, "info: " .. server.commandPrefix .. "new player timer")
			irc_chat(players[chatvars.ircid].ircAlias, "set: " .. server.commandPrefix .. "set new player timer <number> (in minutes)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "By default a new player is treated differently from regulars and has some restrictions placed on them mainly concerning inventory.")
				irc_chat(players[chatvars.ircid].ircAlias, "Set it to 0 to disable this feature.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "new" and chatvars.words[2] == "player" and chatvars.words[3] == "timer" and chatvars.words[4] == nil then
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players stop being new after " .. server.newPlayerTimer .. " minutes total play time.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Change it with " .. server.commandPrefix .. "set new player timer <number> (in minutes)[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "New players stop being new after " .. server.newPlayerTimer .. " minutes total play time.")
			irc_chat(players[chatvars.ircid].ircAlias, "Change it with cmd " .. server.commandPrefix .. "set new player timer <number> (in minutes)")
		end

		botman.faultyChat = false
		return true
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "new" and chatvars.words[3] == "player" and chatvars.words[4] == "timer" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "New players stop being new after " .. chatvars.number .. " minutes total play time.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "serv") or string.find(chatvars.command, "group"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set server group <group name> (one word)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "This is used by the bots database which could be a cloud database.  It is used to identify this bot as belonging to a group if you have more than one server.  You do not need to set this.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "server" and chatvars.words[3] == "group" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		tmp = {}
		tmp.group = chatvars.wordsOld[4]

		if tmp.group == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Group name required.  One word, no spaces.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Group name required.  One word, no spaces.")
			end

			botman.faultyChat = false
			return true
		else
			server.group = tmp.group
			conn:execute("UPDATE server SET serverGroup = '" .. escape(tmp.group) .. "'")

			if botman.db2Connected then
				-- update server in bots db
				connBots:execute("UPDATE servers SET serverGroup = '" .. escape(tmp.group) .. "' WHERE serverName = '" .. escape(server.serverName) .. "'")
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This server is now a member of " .. tmp.group .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "This server is now a member of " .. tmp.group .. ".")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "overs"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "allow overstack")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "By default the bot reads overstack warnings coming from the server to learn what the stack limits are and it will pester players with excessive stack sizes and can send them to timeout for non-compliance.")
				irc_chat(players[chatvars.ircid].ircAlias, "Use this command to disable this feature")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "allow" and string.find(chatvars.words[2], "overstack") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.allowOverstacking = true
		conn:execute("UPDATE server SET allowOverstacking = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will ignore overstacking.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "I will ignore overstacking.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "overs"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disallow overstack")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot will warn players that are overstacking and will eventually send them to timeout if they continue overstacking.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disallow" and string.find(chatvars.words[2], "overstack") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.allowOverstacking = false
		conn:execute("UPDATE server SET allowOverstacking = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will monitor stack sizes, warn and alert for overstacking.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "I will monitor stack sizes, warn and alert for overstacking.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "black") or string.find(chatvars.command, " ban"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "blacklist action ban (or exile)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set what happens to blacklisted players.  The default is to ban them 10 years but if you create a location called exile, the bot can bannish them to there instead.  It acts like a prison.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "blacklist" and string.find(chatvars.words[2], "action") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[3] ~= "exile" and chatvars.words[3] ~= "ban" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Expected ban or exile as 3rd word.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Expected ban or exile as 3rd word.")
			end

			botman.faultyChat = false
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
			irc_chat(players[chatvars.ircid].ircAlias, "Blacklisted players will be " .. chatvars.words[3] .. ".")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, " tele"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "show (or hide) teleports")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "If bot commands are hidden from chat, you can have the bot announce whenever a player teleports to a location (except " .. server.commandPrefix .. "home).")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "show" and string.find(chatvars.words[2], "teleports") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.announceTeleports = true
		conn:execute("UPDATE server SET announceTeleports = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players teleporting to locations will be announced in chat.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Players teleporting to locations will be announced in chat.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "hide" and string.find(chatvars.words[2], "teleports") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.announceTeleports = false
		conn:execute("UPDATE server SET announceTeleports = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players teleporting to locations will be hidden from chat.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Players teleporting to locations will be hidden from chat.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "map"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "setup map")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot can fix your server map's permissions with some nice settings.  If you use this command, the following permissions are set:")
				irc_chat(players[chatvars.ircid].ircAlias, "web.map 2000")
				irc_chat(players[chatvars.ircid].ircAlias, "webapi.getlandclaims 1000")
				irc_chat(players[chatvars.ircid].ircAlias, "webapi.viewallplayers 2")
				irc_chat(players[chatvars.ircid].ircAlias, "webapi.viewallclaims 2")
				irc_chat(players[chatvars.ircid].ircAlias, "webapi.getplayerinventory 2")
				irc_chat(players[chatvars.ircid].ircAlias, "webapi.getplayerslocation 2")
				irc_chat(players[chatvars.ircid].ircAlias, "webapi.getplayersOnline 2000")
				irc_chat(players[chatvars.ircid].ircAlias, "webapi.getstats 2000")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "setup" and string.find(chatvars.words[2], "map") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		send("webpermission add web.map 2000")
		send("webpermission add webapi.getlandclaims 1000")
		send("webpermission add webapi.viewallplayers 2")
		send("webpermission add webapi.viewallclaims 2")
		send("webpermission add webapi.getplayerinventory 2")
		send("webpermission add webapi.getplayerslocation 2")
		send("webpermission add webapi.getplayersOnline 2000")
		send("webpermission add webapi.getstats 2000")

-- comment if you don't want everyone to see animal and zed locations
		send("webpermission add webapi.gethostilelocation 2000")
		send("webpermission add webapi.getanimalslocation 2000")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The map permissions have been set.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "The map permissions have been set.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "northeast pve (or pvp)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make northeast of 0,0 PVE or PVP.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "northeast" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (chatvars.accessLevel > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "northeast pvp.[-]")
			else
				if(players[chatvars.ircid]) then
					irc_chat(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "northeast pvp.")
				else
					irc_chat("Server", "Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "northeast pvp.")
				end
			end

			botman.faultyChat = false
			return true
		end

		server.northeastZone = chatvars.words[2]
		conn:execute("UPDATE server SET northeastZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]Northeast of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_chat(players[chatvars.ircid].ircAlias, "Northeast of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "northwest pve (or pvp)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make northwest of 0,0 PVE or PVP.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "northwest" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "northwest pvp.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "northwest pvp.")
			end

			botman.faultyChat = false
			return true
		end

		server.northwestZone = chatvars.words[2]
		conn:execute("UPDATE server SET northwestZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]Northwest of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_chat(players[chatvars.ircid].ircAlias, "Northwest of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "southeast pve (or pvp)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make southeast of 0,0 PVE or PVP.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "southeast" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "southeast pvp.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "southeast pvp.")
			end

			botman.faultyChat = false
			return true
		end

		server.southeastZone = chatvars.words[2]
		conn:execute("UPDATE server SET southeastZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]Southeast of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_chat(players[chatvars.ircid].ircAlias, "Southeast of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "southwest pve (or pvp)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make southwest of 0,0 PVE or PVP.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "southwest" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "southwest pvp.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "southwest pvp.")
			end

			botman.faultyChat = false
			return true
		end

		server.southwestZone = chatvars.words[2]
		conn:execute("UPDATE server SET southwestZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]Southwest of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_chat(players[chatvars.ircid].ircAlias, "Southwest of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "north pve (or pvp)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make north of 0,0 PVE or PVP.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "north" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "north pvp.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "north pvp.")
			end

			botman.faultyChat = false
			return true
		end

		server.northeastZone = chatvars.words[2]
		server.northwestZone = chatvars.words[2]
		conn:execute("UPDATE server SET northwestZone = '" .. escape(chatvars.words[2]) .. "', northeastZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]North of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_chat(players[chatvars.ircid].ircAlias, "North of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "south pve (or pvp)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make south of 0,0 PVE or PVP.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "south" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "south pvp.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "south pvp.")
			end

			botman.faultyChat = false
			return true
		end

		server.southeastZone = chatvars.words[2]
		server.southwestZone = chatvars.words[2]
		conn:execute("UPDATE server SET southwestZone = '" .. escape(chatvars.words[2]) .. "', southeastZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]South of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_chat(players[chatvars.ircid].ircAlias, "South of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "east pve (or pvp)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make east of 0,0 PVE or PVP.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "east" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "east pvp.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "east pvp.")
			end

			botman.faultyChat = false
			return true
		end

		server.northeastZone = chatvars.words[2]
		server.southeastZone = chatvars.words[2]
		conn:execute("UPDATE server SET northeastZone = '" .. escape(chatvars.words[2]) .. "', southeastZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]East of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_chat(players[chatvars.ircid].ircAlias, "East of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "west pve (or pvp)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make west of 0,0 PVE or PVP.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "west" and chatvars.words[2] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "west pvp.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "west pvp.")
			end

			botman.faultyChat = false
			return true
		end

		server.northwestZone = chatvars.words[2]
		server.southwestZone = chatvars.words[2]
		conn:execute("UPDATE server SET northwestZone = '" .. escape(chatvars.words[2]) .. "', southwestZone = '" .. escape(chatvars.words[2]) .. "'")

		message("say [" .. server.chatColour .. "]West of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

		if (chatvars.playername ~= "Server") then
			irc_chat(players[chatvars.ircid].ircAlias, "West of 0,0 is now a " .. chatvars.words[2] .. " zone!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "fly") or string.find(chatvars.command, "hack") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "allow flying")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "This disables the bot's hacker teleport detection.  You would want to do this if you allow creative mode or at least allow players to fly.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "allow" and chatvars.words[2] == "flying" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.playersCanFly = true
		conn:execute("UPDATE server SET playersCanFly = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players are allowed to fly![-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Players are allowed to fly!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "fly") or string.find(chatvars.command, "hack") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disallow flying")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "This enables the bot's hacker teleport detection.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disallow" and chatvars.words[2] == "flying" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.playersCanFly = false
		conn:execute("UPDATE server SET playersCanFly = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players may not fly![-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Players may not fly!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "overr") or string.find(chatvars.command, "acc"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "override access <number from 99 to 4>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "All players have an access level which governs what they can do.  You can override it for everyone to temporarily raise their access.")
				irc_chat(players[chatvars.ircid].ircAlias, "eg. " .. server.commandPrefix .. "overide access 10 would make all players donors until you restore it.  To do that type " .. server.commandPrefix .. "override access 99.  This is faster than giving individual players donor access if you just want to do a free donor weekend.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "override" and chatvars.words[2] == "access" and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			if chatvars.number < 3 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Do not set the access override lower than 3![-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "Do not set the access override lower than 3!")
				end

				botman.faultyChat = false
				return true
			end

			server.accessLevelOverride = chatvars.number
			conn:execute("UPDATE server SET accessLevelOverride = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player access levels have been over-ridden! Minimum access level is now " .. chatvars.number .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Player access levels have been over-ridden! Minimum access level is now " .. chatvars.number .. ".")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "prot"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disable base protection")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Base protection can be turned off server wide.  It does not make sense to use base protection on a PVP server.  Also it is not available anywhere that is set as a PVP zone on any server.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disable" and chatvars.words[2] == "base" and chatvars.words[3] == "protection" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.disableBaseProtection = true
		conn:execute("UPDATE server SET disableBaseProtection = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Base protection is disabled server wide!  Only claim blocks will protect from player damage now.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Base protection is disabled server wide!  Only claim blocks will protect from player damage now.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "prot"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable base protection")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Base protection is available by default but a player needs to set theirs up to use it.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "enable" and chatvars.words[2] == "base" and chatvars.words[3] == "protection" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.disableBaseProtection = false
		conn:execute("UPDATE server SET disableBaseProtection = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base protection is enabled server wide!  The bot will keep unfriended players out of bases.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Base protection is enabled server wide!  The bot will keep unfriended players out of bases")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pack") or string.find(chatvars.command, "cost") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set pack cost <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "By default players can type " .. server.commandPrefix .. "pack when they respawn after a death to return to close to their pack.  You can set a delay and/or a cost before the command is available after a death.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "pack" and chatvars.words[3] == "cost" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			server.packCost = chatvars.number
			conn:execute("UPDATE server SET packCost = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				if server.packCost == 0 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can teleport back to their pack for free.[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]After death a player must have at least " .. server.packCost .. " " .. server.moneyPlural .. " before they can use " .. server.commandPrefix .. "pack.[-]")
				end
			else
				if server.packCost == 0 then
					irc_chat(players[chatvars.ircid].ircAlias, "Players can teleport back to their pack for free.")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "After death a player must have at least " .. server.packCost .. " " .. server.moneyPlural .. " before they can use " .. server.commandPrefix .. "pack.")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pack") or string.find(chatvars.command, "time") or string.find(chatvars.command, "cool"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set pack cooldown <number in seconds>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "By default players can type " .. server.commandPrefix .. "pack when they respawn after a death to return to close to their pack.  You can set a delay and/or a cost before the command is available after a death.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "pack" and chatvars.words[3] == "cooldown" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			server.packCooldown = chatvars.number
			conn:execute("UPDATE server SET packCooldown = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]After death a player must wait " .. chatvars.number .. " seconds before they can use " .. server.commandPrefix .. "pack.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "After death a player must wait " .. chatvars.number .. " seconds before they can use " .. server.commandPrefix .. "pack.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "cost") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set base cost <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "By default players can type " .. server.commandPrefix .. "base to return to their base.  You can set a delay and/or a cost before the command is available.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "base" and chatvars.words[3] == "cost" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			server.baseCost = chatvars.number
			conn:execute("UPDATE server SET baseCost = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				if server.baseCost == 0 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can teleport back to their base for free.[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players must have at least " .. server.baseCost .. " " .. server.moneyPlural .. " before they can use " .. server.commandPrefix .. "base.[-]")
				end
			else
				if server.baseCost == 0 then
					irc_chat(players[chatvars.ircid].ircAlias, "Players can teleport back to their base for free.")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "Players must have at least " .. server.baseCost .. " " .. server.moneyPlural .. " before they can use " .. server.commandPrefix .. "base.")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bank") or string.find(chatvars.command, "cash"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable bank")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Enable " .. server.moneyPlural .. " and the bank.  Zombie kills will earn " .. server.moneyPlural .. " and the shop and gambling will be available if also enabled.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "enable" and chatvars.words[2] == "bank" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.allowBank = true
		conn:execute("UPDATE server SET allowBank = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This server uses game money.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "This server uses game money.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bank") or string.find(chatvars.command, "cash"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disable bank")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "You can disable " .. server.moneyPlural .. " and the bank.  Zombie kills won't earn anything and the shop and gambling won't be available.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disable" and chatvars.words[2] == "bank" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.allowBank = false
		conn:execute("UPDATE server SET allowBank = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This server will not use game money.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "This server will not use game money.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "overs"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set overstack <number> (default 1000)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Sets the maximum stack size before the bot will warn a player about overstacking.  Usually the bot learns this directly from the server as stack sizes are exceeded.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "overstack" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.overstackThreshold = chatvars.number
		conn:execute("UPDATE server SET overstackThreshold = " .. chatvars.number)

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If no overstack limit is recorded, the minimum stack size to trigger an overstack warning is " .. server.overstackThreshold .. ".[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "If no overstack limit is recorded, the minimum stack size to trigger an overstack warning is " .. server.overstackThreshold .. ".")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "region") or string.find(chatvars.command, " pm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable region pm")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Enable a PM for admins that tells them the region name when they move to a new region.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "enable" and chatvars.words[2] == "region" and chatvars.words[3] == "pm" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.enableRegionPM = true
		conn:execute("UPDATE server SET enableRegionPM = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The current region will be PM'ed to admins.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "The current region will be PM'ed to admins.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "region") or string.find(chatvars.command, " pm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disable region pm")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Disable a PM for admins that tells them the region name when they move to a new region.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disable" and chatvars.words[2] == "region" and chatvars.words[3] == "pm" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.enableRegionPM = false
		conn:execute("UPDATE server SET enableRegionPM = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The current region will not be PM'ed to admins.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "The current region will not be PM'ed to admins.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "lott") or string.find(chatvars.command, "gamb"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "open lottery")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Enable the daily lottery if it is currently disabled.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "open" and chatvars.words[2] == "lottery") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.allowLottery = true
		conn:execute("UPDATE server SET allowLottery = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The daily lottery will run at midnight.[-]")
		else
			irc_chat(server.ircMain, "The daily lottery will run at midnight.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "lott") or string.find(chatvars.command, "gamb"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "close lottery")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "You can disable the lottery while keeping the shop and " .. server.moneyPlural .. " in the game.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "close" and chatvars.words[2] == "lottery") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.allowLottery = false
		conn:execute("UPDATE server SET allowLottery = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The daily lottery is closed.[-]")
		else
			irc_chat(server.ircMain, "The daily lottery is closed.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "lott") or string.find(chatvars.command, "gamb"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set lottery multiplier <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Every zombie killed adds 1 x the lottery multiplier to the lottery total.  The higher the number, the faster the lottery rises.  The default is 2.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "lottery" and chatvars.words[3] == "multiplier" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "The lottery will grow by zombie kills multiplied by " .. chatvars.number)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "zom") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set zombie reward <" .. server.moneyPlural .. ">")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set how many " .. server.moneyPlural .. " a player earns for each zombie killed.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "zombie" and chatvars.words[3] == "reward" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			chatvars.number = math.abs(math.floor(chatvars.number))

			server.zombieKillReward = chatvars.number
			conn:execute("UPDATE server SET zombieKillReward = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will be awarded " .. chatvars.number .. " " .. server.moneyPlural .. " for every zombie killed.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Players will be awarded " .. chatvars.number .. " " .. server.moneyPlural .. " for every zombie killed.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "clear whitelist")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Remove everyone from the bot's whitelist.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "clear" and chatvars.words[2] == "whitelist" and chatvars.words[3] == nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		conn:execute("TRUNCATE TABLE whitelist")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The whitelist has been cleared.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "The whitelist has been cleared.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "whitelist all")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "You can add everyone except blacklisted players to the bot's whitelist.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "whitelist" and (chatvars.words[2] == "everyone" or chatvars.words[2] == "all") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
			irc_chat(players[chatvars.ircid].ircAlias, "Everyone except blacklisted players has been whitelisted.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "disa"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disable teleporting")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set this if you do not want your players using teleport commands. Admins can still teleport.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "disable" or chatvars.words[1] == "disallow") and chatvars.words[2] == "teleporting" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.allowTeleporting = false
		conn:execute("UPDATE server SET allowTeleporting = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not be able to use teleport commands.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Players will not be able to use teleport commands.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "allow") or string.find(chatvars.command, "enab"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable teleporting")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set this if you want your players using teleport commands.  This is the default.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" or chatvars.words[1] == "allow") and chatvars.words[2] == "teleporting" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.allowTeleporting = true
		conn:execute("UPDATE server SET allowTeleporting = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can use teleport commands.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Players can use teleport commands.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "able"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable p2p")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disable p2p")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Allow or block players teleporting to other players via shared waypoints or teleporting to friends.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "p2p" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if (chatvars.words[1] == "enable") then
			server.allowPlayerToPlayerTeleporting = true
			conn:execute("UPDATE server SET allowPlayerToPlayerTeleporting = 1")

			if (chatvars.playername ~= "Server") then
				message(string.format("pm %s [%s]Players can teleport to friends.[-]", chatvars.playerid, server.chatColour))
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Players can teleport to friends.")
			end
		else
			server.allowPlayerToPlayerTeleporting = false
			conn:execute("UPDATE server SET allowPlayerToPlayerTeleporting = 0")

			if (chatvars.playername ~= "Server") then
				message(string.format("pm %s [%s]Players can not teleport to friends.[-]", chatvars.playerid, server.chatColour))
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Players can not teleport to friends.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hard") or string.find(chatvars.command, "mode") or string.find(chatvars.command, "server"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disable hardcore mode")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Allow players to use bot commands.  This is the default.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disable" and chatvars.words[2] == "hardcore" and chatvars.words[3] == "mode" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.hardcore = false
		conn:execute("UPDATE server SET hardcore = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can command the bot.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Players can command the bot.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hard") or string.find(chatvars.command, "mode") or string.find(chatvars.command, "server"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable hardcore mode")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Don't let players use any bot commands.  Does not affect admins.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "enable" and chatvars.words[2] == "hardcore" and chatvars.words[3] == "mode" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.hardcore = true
		conn:execute("UPDATE server SET hardcore = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will ignore commands from players.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "The bot will ignore commands from players.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "fix shop")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Attempt to automatically fix the shop.  It reloads the shop categories, checks for any missing categories in shop items and assigns them to misc then reindexes the shop.")
				irc_chat(players[chatvars.ircid].ircAlias, "This fix is experimental and might not actually fix whatever is wrong with your shop.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "fix" and chatvars.words[2] == "shop" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		fixShop()

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Try using the shop and see if it is fixed.  If not repeating the command is not going to fix it this time.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Try using the shop and see if it is fixed.  If not repeating the command is not going to fix it this time.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "relog") or string.find(chatvars.command, "allow"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "allow rapid relog")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "New players who want to cheat often relog rapidly in order to spawn lots of items into the server using cheats or bugs.")
				irc_chat(players[chatvars.ircid].ircAlias, "This command makes the bot ignore these and do nothing to stop them.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "allow" and chatvars.words[2] == "rapid" and string.find(chatvars.command, "relog") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.allowRapidRelogging = true
		conn:execute("UPDATE server SET allowRapidRelogging = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will do nothing about new players relogging multiple times rapidly.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "The bot will do nothing about new players relogging multiple times rapidly.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "relog") or string.find(chatvars.command, "allow"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disallow rapid relog")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "New players who want to cheat often relog rapidly in order to spawn lots of items into the server using cheats or bugs.")
				irc_chat(players[chatvars.ircid].ircAlias, "This command makes the bot temp ban new players found to be relogging many times less than a minute apart.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "disallow" and chatvars.words[2] == "rapid" and string.find(chatvars.command, "relog") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 1) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		server.allowRapidRelogging = false
		conn:execute("UPDATE server SET allowRapidRelogging = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will temp ban new players that are relogging multiple times rapidly.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "The bot will temp ban new players that are relogging multiple times rapidly.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "kick"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "idle kick on (off is default)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "When the server is full, if idle kick is on players will get kick warnings for 15 minutes of no movement then they get kicked.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "idle" and chatvars.words[2] == "kick" and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[3] == "on" then
			server.idleKick = true
			conn:execute("UPDATE server SET idleKick = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]When the server is full, idling players will get kick warnings for 15 minutes then kicked if they don't move.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "When the server is full, idling players will get kick warnings for 15 minutes then kicked if they don't move.")
			end
		end

		if chatvars.words[3] == "off" then
			server.idleKick = false
			conn:execute("UPDATE server SET idleKick = 0")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not be kicked for idling on the server.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Players will not be kicked for idling on the server.")
			end
		end

		if chatvars.words[3] ~= "on" and chatvars.words[3] ~= "off" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Valid command is " .. server.commandPrefix .. "idle kick on or " .. server.commandPrefix .. "idle kick off.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Valid command is " .. server.commandPrefix .. "idle kick on or " .. server.commandPrefix .. "idle kick off.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "irc") or string.find(chatvars.command, "pub") or string.find(chatvars.command, "priv"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "irc private (or " .. server.commandPrefix .. "irc public)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "If IRC is private, the bot won't share the url or info with players and players can't invite anyone to irc using the invite command.")
				irc_chat(players[chatvars.ircid].ircAlias, "When public, players can find the IRC info with " .. server.commandPrefix .. "help irc and they can create irc invites for themselves and others.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "irc" and (chatvars.words[2] == "public" or chatvars.words[2] == "private") and chatvars.words[3] == nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[2] == "public" then
			server.ircPrivate = false
			conn:execute("UPDATE server SET ircPrivate = 0")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can see the IRC server info and can create IRC invites.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Players can see the IRC server info and can create IRC invites.")
			end
		end

		if chatvars.words[2] == "private" then
			server.ircPrivate = true
			conn:execute("UPDATE server SET ircPrivate = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not see the IRC server info and cannot create IRC invites.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Players will not see the IRC server info and cannot create IRC invites.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "money") or string.find(chatvars.command, "name") or string.find(chatvars.command, "cash"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set money name <singular> <plural>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The default money name is the Zenny and the plural is Zennies. Both names must be one word each.")
				irc_chat(players[chatvars.ircid].ircAlias, "eg " .. server.commandPrefix .. "set money name Chip Chips.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "money" and chatvars.words[3] == "name" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		tmp = {}
		tmp.money = chatvars.wordsOld[4]
		tmp.moneyPlural = chatvars.wordsOld[5]

		if tmp.money ~= nil and tmp.moneyPlural ~= nil then
			-- first update the currency name in the locations table
			conn:execute("UPDATE locations SET currency = '" .. escape(tmp.money) .. "' where currency = '" .. escape(server.moneyName) .. "'")

			for k,v in pairs(locations) do
				if v.currency then
					if string.lower(v.currency) == string.lower(server.moneyName) then
						v.currency = tmp.money
					end
				end
			end

			server.moneyName = tmp.money
			server.moneyPlural = tmp.moneyPlural
			conn:execute("UPDATE server SET moneyName = '" .. escape(tmp.money .. "|" .. tmp.moneyPlural) .. "'")

			message("say [" .. server.chatColour .. "]This server now uses money called the " .. server.moneyName ..".  All your old currency is now worthless!  Just kidding xD[-]")
			message("say [" .. server.chatColour .. "]The shop is now accepting your hard won " .. server.moneyPlural ..".[-]")
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]I know your money is worthless, but it still needs a name.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "I know your money is worthless, but it still needs a name.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "size") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set default base size <number in metres or blocks>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The default base protection size is 41 blocks (64 diameter).  This default only applies to new players joining the server for the first time.")
				irc_chat(players[chatvars.ircid].ircAlias, "Existing base sizes are not changed with this command.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "default" and chatvars.words[3] == "base" and chatvars.words[4] == "size" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			server.baseSize = chatvars.number
			conn:execute("UPDATE server SET baseSize = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]The default base protection size is now " .. chatvars.number .. " metres.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The default base protection size is now " .. chatvars.number .. " metres.")
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You didn't give the new base size.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]eg " .. server.commandPrefix .. "set default base size 25.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "You didn't give the new base size.")
				irc_chat(players[chatvars.ircid].ircAlias, "eg " .. server.commandPrefix .. "set default base size 25.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rese") or string.find(chatvars.command, "slot") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set reserved slots <number of slots>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "You can have a number of server slots reserved for admins and selected players.")
				irc_chat(players[chatvars.ircid].ircAlias, "Anyone can join but if the server becomes full, players who aren't staff or allowed to reserve a slot will be randomly selected and kicked if an admin or authorised player joins.")
				irc_chat(players[chatvars.ircid].ircAlias, "To disable, set reserved slots to 0.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "reserved" and chatvars.words[3] == "slots" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 0) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number ~= nil then
			server.reservedSlots = math.abs(chatvars.number)
			conn:execute("UPDATE server SET reservedSlots = " .. server.reservedSlots)

			if server.reservedSlots == 0 then
				if tonumber(server.ServerMaxPlayerCount) > server.maxPlayers then
				send("sg ServerMaxPlayerCount " .. server.maxPlayers) -- remove the extra slot that ensures reserved slot players can join in one go when server full
			else
				if tonumber(server.ServerMaxPlayerCount) <= server.maxPlayers then
				send("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add the extra slot that ensures reserved slot players can join in one go when server full
			end
		end
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "] " .. chatvars.number .. " slots are now reserved slots.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, chatvars.number .. " slots are now reserved slots.")
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You didn't give me a number.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]eg " .. server.commandPrefix .. "set reserved slots 5[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "You didn't give me a number.")
				irc_chat(players[chatvars.ircid].ircAlias, "eg " .. server.commandPrefix .. "set reserved slots 5")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bail") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set bail <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set how many " .. server.moneyPlural .. " it costs to bail out of prison.")
				irc_chat(players[chatvars.ircid].ircAlias, "To disable bail set it to zero (the default)")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "bail" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number == nil then
			server.bailCost = 0
			conn:execute("UPDATE server SET bailCost = 0")
		else
			tmp = {}
			tmp.bail = math.abs(chatvars.number)

			server.bailCost = tmp.bail
			conn:execute("UPDATE server SET bailCost = " .. tmp.bail)
		end

		if server.bailCost == 0 then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Bail is disabled on this server.  Players must be released by someone to get out of prison.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Bail is disabled on this server.  Players must be released by someone to get out of prison.")
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Players can release themselves from prison at a cost of " .. server.bailCost .. " " .. server.moneyPlural .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Players can release themselves from prison at a cost of " .. server.bailCost .. " " .. server.moneyPlural)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "time") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set prison timer <number> (in minutes)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set how long someone stays in prison for when jailed automatically.")
				irc_chat(players[chatvars.ircid].ircAlias, "To not have a time limit, set this to 0 which is the default.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "prison" and chatvars.words[3] == "timer" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number == nil then
			server.maxPrisonTime = 0
			conn:execute("UPDATE server SET maxPrisonTime = 0")
		else
			tmp = {}
			tmp.maxPrisonTime = math.abs(chatvars.number)

			server.maxPrisonTime = tmp.maxPrisonTime
			conn:execute("UPDATE server SET maxPrisonTime = " .. tmp.maxPrisonTime)
		end

		if server.maxPrisonTime == 0 then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Prisoners must be released by someone to get out of prison. There is no time limit.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Prisoners must be released by someone to get out of prison. There is no time limit.")
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Prisoners will be automatically released from prison after " .. server.maxPrisonTime .. " minutes.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Prisoners will be automatically released from prison after " .. server.maxPrisonTime .. " minutes.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "enable") or string.find(chatvars.command, "return") or string.find(chatvars.command, "disa"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable returns (the default)")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disable returns")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "After being teleported somewhere, players can type /return to be sent back to where they came from.")
				irc_chat(players[chatvars.ircid].ircAlias, "This is enabled by default but you can disable them.  Admins are not affected by this setting.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "returns" and chatvars.words[3] == nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "enable" then
			server.allowReturns = true
			conn:execute("UPDATE server SET allowReturns = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Players can return after being teleported by typing " .. server.commandPrefix .. "return.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Players can return after being teleported by typing " .. server.commandPrefix .. "return.")
			end
		else
			server.allowReturns = false
			conn:execute("UPDATE server SET allowReturns = 0")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]The " .. server.commandPrefix .. "return command is disabled for players.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The " .. server.commandPrefix .. "return command is disabled for players.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "scan") or string.find(chatvars.command, "clip") or string.find(chatvars.command, "fly"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable noclip scan (the default)")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disable noclip scan")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Using Coppi's mod version 2.5+ you can detect players that are noclipping under the map.")
				irc_chat(players[chatvars.ircid].ircAlias, "It can false flag but it is still a useful early warning of a possible hacker. Currently this feature only alerts to IRC. It does not punish.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "noclip" and chatvars.words[3] == "scan" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "enable" then
			server.scanNoclip = true
			conn:execute("UPDATE server SET scanNoclip = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]I will scan for noclipping players and report them to IRC.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "I will scan for noclipping players and report them to IRC.")
			end
		else
			server.scanNoclip = false
			conn:execute("UPDATE server SET scanNoclip = 0")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]I will not scan for noclipping players.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "I will not scan for noclipping players.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "scan") or string.find(chatvars.command, "err") or string.find(chatvars.command, "fix"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable error scan")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disable error scan (the default)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot can automatically scan for and fix some errors using console commands.")
				irc_chat(players[chatvars.ircid].ircAlias, "The scan happens automatically every 2 minutes.  You can disable them if you suspect they are creating lag.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "error" and chatvars.words[3] == "scan" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "enable" then
			server.scanErrors = true
			conn:execute("UPDATE server SET scanErrors = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]I will scan the server for errors.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "I will scan the server for errors.")
			end
		else
			server.scanErrors = false
			conn:execute("UPDATE server SET scanErrors = 0")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]I will not scan for errors.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "I will not scan for errors.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "scan") or string.find(chatvars.command, "ent"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable entity scan")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disable entity scan (the default)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Scan for entities server wide every 30 seconds.")
				irc_chat(players[chatvars.ircid].ircAlias, "The resulting list is copied to the entities Lua table where it can be further processed for other bot features.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "entity" and chatvars.words[3] == "scan" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "enable" then
			server.scanEntities = true
			conn:execute("UPDATE server SET scanEntities = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]I will scan entities every 30 seconds.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "I will scan entities every 30 seconds.")
			end
		else
			server.scanEntities = false
			conn:execute("UPDATE server SET scanEntities = 0")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]I will not scan for entities.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "I will not scan for entities.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reboot") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set reboot hour <0 to 23>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Reboot the server when the server time matches the hour (24 hour time)")
				irc_chat(players[chatvars.ircid].ircAlias, "To disable clock based reboots set this to -1 or don't enter a number.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "reboot" and chatvars.words[3] == "hour" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		tmp = {}

		-- validate number
		if chatvars.number == nil then
			tmp.disabled = true
		else
			if tonumber(chatvars.number) < 0 then
				tmp.disabled = true
			else
				chatvars.number = math.floor(chatvars.number)

				if chatvars.number > 23 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]A number from 0 to 23 was expected.[-]")
					else
						irc_chat(players[chatvars.ircid].ircAlias, "A number from 0 to 23 was expected.")
					end

					botman.faultyChat = false
					return true
				end
			end
		end

		if tmp.disabled then
			server.rebootHour = -1
			conn:execute("UPDATE server SET rebootHour = -1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You have disabled clock based reboots.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "You have disabled clock based reboots.")
			end
		else
			server.rebootHour = chatvars.number
			conn:execute("UPDATE server SET rebootHour = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reboot") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set reboot minute <0 to 59>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Reboot the server when the server time matches the hour and minute (24 hour time)")
				irc_chat(players[chatvars.ircid].ircAlias, "To disable clock based reboots use " .. server.commandPrefix .. "set reboot hour (without a number)")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "reboot" and chatvars.words[3] == "minute" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		tmp = {}

		-- validate number
		if chatvars.number == nil then
			tmp.invalid = true
		else
			if tonumber(chatvars.number) < 0 then
				tmp.invalid = true
			else
				chatvars.number = math.floor(chatvars.number)

				if chatvars.number > 59 then
					tmp.invalid = true
				end
			end
		end

		if tmp.invalid then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]A number from 0 to 59 was expected.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "A number from 0 to 59 was expected.")
			end
		else
			server.rebootMinute = chatvars.number
			conn:execute("UPDATE server SET rebootMinute = " .. chatvars.number)

			if tonumber(server.rebootHour) > -1 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Now set the reboot hour with " .. server.commandPrefix .. "set reboot hour <0-23>.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "Now set the reboot hour with " .. server.commandPrefix .. "set reboot hour <0-23>.")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "cbsm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set cbsm friendly")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set cbsm unfriendly")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Reboot the server when the server time matches the hour and minute (24 hour time)")
				irc_chat(players[chatvars.ircid].ircAlias, "To disable clock based reboots use " .. server.commandPrefix .. "set reboot hour (without a number)")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "cbsm" and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[3] == "friendly" then
			server.CBSMFriendly = true
			conn:execute("UPDATE server SET CBSMFriendly = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Commands will automatically remap from / to = when CBSM is detected.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Commands will automatically remap from / to = when CBSM is detected.")
			end
		else
			server.CBSMFriendly = false
			server.commandPrefix = "/"
			conn:execute("UPDATE server SET CBSMFriendly = 0, commandPrefix = '/'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Commands will continue to expect a / with CBSM present.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Commands will continue to expect a / with CBSM present.")
			end

			message("say [" .. server.chatColour .. "]Commands now begin with a " .. server.commandPrefix .. "  To use commands such as who type " .. server.commandPrefix .. "who[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "update") or string.find(chatvars.command, "code") or string.find(chatvars.command, "script"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "update code")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make the bot check for script updates.  They will be installed if you have set " .. server.commandPrefix .. "enable updates")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "update" and (chatvars.words[2] == "code" or chatvars.words[2] == "scripts") and chatvars.words[3] == nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			-- allow from irc
		end

		updateBot(true)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "able") or string.find(chatvars.command, "upd"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable/disable updates")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Allow the bot to automatically update itself by downloading scripts. It will check daily, but you can also command it to check immediately with " .. server.commandPrefix .. "update bot")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "updates" and chatvars.words[3] == nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "enable" then
			server.updateBot = true
			conn:execute("UPDATE server set updateBot = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will automatically update itself daily if newer scripts are available.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The bot will automatically update itself daily if newer scripts are available.")
			end
		else
			server.updateBot = false
			conn:execute("UPDATE server set updateBot = 0")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will not update automatically.  You will see an alert on IRC if an update is available.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The bot will not update automatically.  You will see an alert on IRC if an update is available.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "upd") or string.find(chatvars.command, "set") or string.find(chatvars.command, "branch"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set update branch")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Bot updates are released in two branches, stable and testing.  The stable branch will not update as often and should have less issues than testing.")
				irc_chat(players[chatvars.ircid].ircAlias, "New and trial features will release to testing before stable. Important fixes will be ported to stable from testing whenever possible.")
				irc_chat(players[chatvars.ircid].ircAlias, "You can switch between branches as often as you want.  Any changes in testing that are not in stable will never break stable should you switch back to it.")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "update" and chatvars.words[3] == "branch" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[4] == "stable" then
			server.updateBranch = "stable"
			conn:execute("UPDATE server set updateBranch = 'stable'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will check for updates from the stable branch.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The bot will check for updates from the stable branch.")
			end
		else
			server.updateBranch = "testing"
			conn:execute("UPDATE server set updateBranch = 'testing'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will check for updates from the testing branch.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The bot will check for updates from the testing branch.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

-- ###################  do not allow remote commands beyond this point ################

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(players[chatvars.ircid].ircAlias, "")
		irc_chat(players[chatvars.ircid].ircAlias, "Server In-Game Only:")
		irc_chat(players[chatvars.ircid].ircAlias, "========================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "server"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reset server")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Tell the bot to forget everything it knows about the server.  You will be asked to confirm this, answer with yes.  Say anything else to abort.")
				irc_chat(players[chatvars.ircid].ircAlias, "Usually you only need to use " .. server.commandPrefix .. "reset bot.  This reset goes further.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reset") and (chatvars.words[2] == "server") and (chatvars.playerid ~= 0) then
		if chatvars.accessLevel > 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Are you sure you want to wipe me completely clean?  Answer yes to proceed or anything else to cancel.[-]")
		igplayers[chatvars.playerid].botQuestion = "reset server"

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "bot"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reset bot")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Tell the bot to forget only some things, some player info, locations, bases etc.  You will be asked to confirm this, answer with yes.  Say anything else to abort.")
				irc_chat(players[chatvars.ircid].ircAlias, "Use this command after wiping the server.  The bot will detect the day change and will ask if you want to reset the bot too.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reset") and (chatvars.words[2] == "bot") and (chatvars.playerid ~= 0) then
		if chatvars.accessLevel > 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Are you sure you want to reset me?  Answer yes to proceed or anything else to cancel.[-]")
		igplayers[chatvars.playerid].botQuestion = "reset bot"

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "bot"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reset bot")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Tell the bot to forget only some things, some player info, locations, bases etc.  You will be asked to confirm this, answer with yes.  Say anything else to abort.")
				irc_chat(players[chatvars.ircid].ircAlias, "Use this command after wiping the server.  The bot will detect the day change and will ask if you want to reset the bot too.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "quick") and (chatvars.words[2] == "reset") and (chatvars.words[3] == "bot") and (chatvars.playerid ~= 0) then
		if chatvars.accessLevel > 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Are you sure you want to reset me?  Answer yes to proceed or anything else to cancel.[-]")
		igplayers[chatvars.playerid].botQuestion = "quick reset bot"

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "no reset")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "If the bot detects that the server days have rolled back, it will ask you if you want to reset the bot.  Type " .. server.commandPrefix .. "no reset if you don't want the bot to reset itself.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "no") and (chatvars.words[2] == "reset") and (chatvars.playerid ~= 0) then
		if chatvars.accessLevel > 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true3
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Oh ok then.[-]")
		server.warnBotReset = false

		botman.faultyChat = false
		return true
	end

if debug then dbug("debug server end") end

end
