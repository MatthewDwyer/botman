--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_server()
	local debug, tmp, msg, result, help
	local shortHelp = false

	-- enable debug to see where the code is stopping. Any error will be somewhere after the last successful debug line.
	debug = false -- should be false unless testing

	calledFunction = "gmsg_server"
	result = false
	tmp = {}
	tmp.topic = "server"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## server command functions ##################

	local function cmd_CancelReboot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}cancel reboot"
			help[2] = "Cancel a scheduled reboot.  You may not be able to stop a forced or automatically scheduled reboot but you can pause it instead."

			tmp.command = help[1]
			tmp.keywords = "reboot,shutdown,cancel,stop,restart"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "cancel") or string.find(chatvars.command, "reboot") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "cancel" and chatvars.words[2] == "reboot" and chatvars.words[3] == nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				if (botman.scheduledRestartForced == true) and (chatvars.accessLevel > 0) then
					message("say [" .. server.warnColour .. "]A forced reboot is scheduled and will proceed as planned.[-]")
					botman.faultyChat = false
					return true
				end
			end

			botman.scheduledRestart = false
			botman.scheduledRestartTimestamp = os.time()
			botman.scheduledRestartPaused = false
			botman.scheduledRestartForced = false

			if (botman.rebootTimerID ~= nil) then killTimer(botman.rebootTimerID) end
			if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end
			if (rebootCountDown1 ~= nil) then killTimer(rebootCountDown1) end
			if (rebootCountDown2 ~= nil) then killTimer(rebootCountDown2) end
			if (rebootCountDown3 ~= nil) then killTimer(rebootCountDown3) end
			if (rebootCountDown4 ~= nil) then killTimer(rebootCountDown4) end
			if (rebootCountDown5 ~= nil) then killTimer(rebootCountDown5) end
			if (rebootCountDown6 ~= nil) then killTimer(rebootCountDown6) end
			if (rebootCountDown7 ~= nil) then killTimer(rebootCountDown7) end
			if (rebootCountDown8 ~= nil) then killTimer(rebootCountDown8) end
			if (rebootCountDown9 ~= nil) then killTimer(rebootCountDown9) end
			if (rebootCountDown10 ~= nil) then killTimer(rebootCountDown10) end
			if (rebootCountDown11 ~= nil) then killTimer(rebootCountDown11) end

			botman.rebootTimerID = nil
			rebootTimerDelayID = nil
			botman.serverRebooting = false

			message("say [" .. server.chatColour .. "]A server reboot has been cancelled.[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_JoinGameServer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}join server {ip} port {telnet port} pass {telnet password}"
			help[2] = "Tell the bot to join a different game server."

			tmp.command = help[1]
			tmp.keywords = "server,join,new,change,ip,port,password"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "join") or string.find(chatvars.command, "server") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "join" and chatvars.words[2] == "server" and string.find(chatvars.command, "port") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			serverMove = {}

			for i=2,chatvars.wordCount,1 do
				if chatvars.words[i] == "server" then
					serverMove.serverIP = chatvars.wordsOld[i+1]
				end

				if chatvars.words[i] == "port" then
					serverMove.telnetPort = chatvars.words[i+1]
				end

				if chatvars.words[i] == "pass" then
					serverMove.telnetPass = chatvars.words[i+1]
				end
			end

			server.telnetPass = serverMove.telnetPass
			telnetPassword = serverMove.telnetPass
			conn:execute("UPDATE server SET telnetPass = '" .. escape(serverMove.telnetPass) .. "'")

			reconnect(serverMove.serverIP, serverMove.telnetPort, true)
			saveProfile()
			serverMove = nil

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PauseReboot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}pause reboot"
			help[2] = "Pause a scheduled reboot.  It will stay paused until you unpause it or restart the bot."

			tmp.command = help[1]
			tmp.keywords = "server,reboot,pause,resume"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "pause") or string.find(chatvars.command, "reboot") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "pause" or chatvars.words[1] == "paws") and chatvars.words[2] == "reboot" and chatvars.words[3] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if botman.scheduledRestartPaused then
				if chatvars.words[1] == "paws" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The paws are already on the reboot.[-]")
					else
						irc_chat(chatvars.ircAlias, "The paws are already on the reboot.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The reboot is already paused.[-]")
					else
						irc_chat(chatvars.ircAlias, "The reboot is already paused.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if server.allowReboot then
				if server.maxServerUptime < 25 then
					botman.restartTimeRemaining = (tonumber(server.maxServerUptime) * 3600) - server.uptime + 900
				else
					botman.restartTimeRemaining = (tonumber(server.maxServerUptime) * 60) - server.uptime + 900
				end

				botman.scheduledRestartPaused = true

				if chatvars.words[1] == "paws" then
					message("say [" .. server.chatColour .. "]The reboot has been pawsed.[-]")
				else
					message("say [" .. server.chatColour .. "]The reboot has been paused.[-]")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Server reboots are not managed by the bot.[-]")
				else
					irc_chat(chatvars.ircAlias, "Server reboots are not managed by the bot.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RunConsoleCommand()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}run command {a console command}"
			help[2] = "Sometimes you need to make the bot run a specific console command.\n"
			help[2] = help[2] .. "This can be used to force the bot re-parse a list.  Only server owners can do this."

			tmp.command = help[1]
			tmp.keywords = "bot,run,command,console"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "run") or string.find(chatvars.command, "comm") or string.find(chatvars.command, "cons") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "run" and chatvars.words[2] == "command" and chatvars.words[3] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = string.sub(line, string.find(line, "command") + 8)
			sendCommand(tmp)
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Say()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}say{2 letter language code} {something you want translated}"
			help[2] = "If the translator utility is installed, the bot can translate from english what you say into the language you specify.\n"
			help[2] = help[2] .. "eg. {#}sayfr Hello.  The bot will say Smegz0r: Bonjour\n"
			help[2] = help[2] .. "Note: This uses Google and due to the number of bots I host, it is not installed on my servers as I don't want to risk an invoice from them.\n"

			tmp.command = help[1]
			tmp.keywords = "bot,run,command,console"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "say") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (string.find(chatvars.words[1], "say") and (string.len(chatvars.words[1]) == 5) and chatvars.words[2] ~= nil) then
			msg = string.sub(chatvars.command, string.len(chatvars.words[1]) + 2)
			msg = string.trim(msg)

			if (msg ~= "") then
				Translate(chatvars.playerid, msg, string.sub(chatvars.words[1], 4), true)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ScheduleServerReboot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reboot\n"
			help[1] = help[1] .. "Or {#}reboot {n} minute (or hour) (optional: forced)\n"
			help[1] = help[1] .. "Or {#}reboot now"
			help[2] = "Schedule a timed or immediate server reboot.  The actual restart must be handled externally by something else.\n"
			help[2] = help[2] .. "Just before the reboot happens, the bot issues a save command. If you add forced, only a level 0 admin can stop the reboot.\n"
			help[2] = help[2] .. "Shutting down the bot will also cancel a reboot but any automatic (timed) reboots will reschedule if the server wasn't also restarted."

			tmp.command = help[1]
			tmp.keywords = "server,reboots,now,time,schedule"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "reboot") then
				if server.allowReboot == false then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]This command is disabled for this server.  Reboot manually.[-]")
					botman.faultyChat = false
					return true
				end

			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[2] ~= "now") then
				if (botman.scheduledRestart == true) then
					message("say [" .. server.warnColour .. "]A reboot is already scheduled.  Cancel it first.[-]")
					botman.faultyChat = false
					return true
				end
			else
				botman.scheduledRestart = false
				botman.scheduledRestartTimestamp = os.time()
				botman.scheduledRestartPaused = false
				botman.scheduledRestartForced = false

				if (botman.rebootTimerID ~= nil) then killTimer(botman.rebootTimerID) end
				if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end

				botman.rebootTimerID = nil
				rebootTimerDelayID = nil

				if not botMaintenance.lastSA then
					botMaintenance.lastSA = os.time()
					saveBotMaintenance()
				else
					if (os.time() - botMaintenance.lastSA) > 30 then
						botMaintenance.lastSA = os.time()
						saveBotMaintenance()
					end
				end

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
				restartDelay = restartDelay * 60 * 60
			end

			botman.scheduledRestartPaused = false
			botman.scheduledRestart = true
			botman.scheduledRestartTimestamp = os.time() + restartDelay
			botman.nextRebootTest = nil

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetAccessOverride()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}override access {number from 99 to 4}"
			help[2] = "All players have an access level which governs what they can do.  You can override it for everyone to temporarily raise their access.\n"
			help[2] = help[2] .. "eg. {#}overide access 10 would make all players donors until you restore it.  To do that type {#}override access 99.  This is faster than giving individual players donor access if you just want to do a free donor weekend."

			tmp.command = help[1]
			tmp.keywords = "bot,acceess,override,set"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "overr") or string.find(chatvars.command, "acc") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "override" and chatvars.words[2] == "access" and chatvars.words[3] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				if chatvars.number < 3 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Do not set the access override lower than 3![-]")
					else
						irc_chat(chatvars.ircAlias, "Do not set the access override lower than 3!")
					end

					botman.faultyChat = false
					return true
				end

				server.accessLevelOverride = chatvars.number
				conn:execute("UPDATE server SET accessLevelOverride = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player access levels have been over-ridden! Minimum access level is now " .. chatvars.number .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "Player access levels have been over-ridden! Minimum access level is now " .. chatvars.number .. ".")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetArchivePlayersThreshold()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set archive players day {number (days) default is 60}"
			help[2] = "The bot will archive players who haven't played in 60 days except for admins.  You can disable this feature by setting it to 0.\n"
			help[2] = help[2] .. "The bot will archive players at startup or if you use the command {#}archive players."

			tmp.command = help[1]
			tmp.keywords = "bot,set,archived,day,players,seen"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "set") or string.find(chatvars.command, "arch") or string.find(chatvars.command, "play") or string.find(chatvars.command, "seen") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "archive" and chatvars.words[3] == "players" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))
				server.archivePlayersLastSeenDays = chatvars.number
				conn:execute("UPDATE server SET archivePlayersLastSeenDays = " .. chatvars.number)

				if chatvars.number == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will not be archived.[-]")
					else
						irc_chat(chatvars.ircAlias, "Players will not be archived.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who are not admins and haven't played in " .. server.archivePlayersLastSeenDays .. " days will be archived when the bot starts up.  You can force it now with {#}archive players.[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]If you have a lot of players it will make the bot unresponsive for a short time.[-]")
					else
						irc_chat(chatvars.ircAlias, "Players who are not admins and haven't played in " .. chatvars.number .. " days will be archived when the bot starts up.  You can force it now with {#}archive players.")
						irc_chat(chatvars.ircAlias, "If you have a lot of players it will make the bot unresponsive for a short time.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBailCost()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set bail {number}"
			help[2] = "Set how many " .. server.moneyPlural .. " it costs to bail out of prison.  To disable bail set it to zero (the default)"

			tmp.command = help[1]
			tmp.keywords = "set,bail,prison,cost,amount,price"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "bail") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "bail" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
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
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Bail is disabled on this server.  Players must be released by someone to get out of prison.[-]")
				else
					irc_chat(chatvars.ircAlias, "Bail is disabled on this server.  Players must be released by someone to get out of prison.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Players can release themselves from prison at a cost of " .. server.bailCost .. " " .. server.moneyPlural .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can release themselves from prison at a cost of " .. server.bailCost .. " " .. server.moneyPlural)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetClearViewMOTD()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}motd (to view it)\n"
			help[1] = help[1] .. " {#}motd (or {#}set motd) {your message here} (to set it)\n"
			help[1] = help[1] .. " {#}motd clear (to disable it)"
			help[2] = "Display the current message of the day.  If an admin types anything after {#}motd the typed text becomes the new MOTD.\n"
			help[2] = help[2] .. "To remove it type {#}motd clear"

			tmp.command = help[1]
			tmp.keywords = "set,motd,message,day"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "motd") or string.find(chatvars.command, "mess") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "motd") or (chatvars.words[1] == "set" and chatvars.words[2] == "motd") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == nil then
				if server.MOTD == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]There is no MOTD set.[-]")
					else
						irc_chat(chatvars.ircAlias, "There is no MOTD set.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.MOTD .. "[-]")
					else
						irc_chat(chatvars.ircAlias, server.MOTD)
					end
				end
			else
				if chatvars.words[2] == "clear" then
					server.MOTD = nil
					conn:execute("UPDATE server SET MOTD = ''")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]MOTD has been cleared.[-]")
					else
						irc_chat(chatvars.ircAlias, "MOTD has been cleared.")
					end
				else
					server.MOTD = stripQuotes(string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "motd") + 5))
					conn:execute("UPDATE server SET MOTD = '" .. escape(server.MOTD) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New message of the day recorded.[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.MOTD .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "New message of the day recorded.")
						irc_chat(chatvars.ircAlias, server.MOTD)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetIdleKickTimer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set idle kick {seconds} (default 900. 15 minutes)"
			help[2] = "How many seconds a player can be idle for before being kicked from the server. Does not include joining players that have not spawned yet."

			tmp.command = help[1]
			tmp.keywords = "set,idle,kick,time,delay"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "idle") or string.find(chatvars.command, "kick") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "idle" and chatvars.words[3] == "kick" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Number expected.  Default is 900 seconds which is 15 minutes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Number expected.  Default is 900 seconds which is 15 minutes.")
				end

				botman.faultyChat = false
				return true
			else
				chatvars.number = math.abs(chatvars.number)
			end

			if chatvars.number == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Timer can't be zero seconds.[-]")
				else
					irc_chat(chatvars.ircAlias, "Timer can't be zero seconds.")
				end

				botman.faultyChat = false
				return true
			else
				server.idleKickTimer = chatvars.number
				server.idleKick = true
				conn:execute("UPDATE server SET idleKick = 1, idleKickTimer = " .. server.idleKickTimer)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Idle players will be kicked after " .. server.idleKickTimer .. " seconds. Those slackers![-]")
				else
					irc_chat(chatvars.ircAlias, "Idle players will be kicked after " .. server.idleKickTimer .. " seconds. Those slackers!")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetIRCChannels()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set irc main (or alerts or watch) {channel name without a # sign}"
			help[2] = "Change the bot's IRC channels."

			tmp.command = help[1]
			tmp.keywords = "set,irc,web,channel,main,alert,watch"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, " irc")) and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "irc" and (chatvars.words[3] == "main" or chatvars.words[3] == "alerts" or chatvars.words[3] == "watch") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = chatvars.words[4]

			if chatvars.words[3] == "main" then
				server.ircMain = "#" .. pname
				server.ircAlerts = "#" .. pname .. "_alerts"
				server.ircWatch = "#" .. pname .. "_watch"

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The main irc channel is now " .. server.ircMain .. ", alerts is " ..  server.ircAlerts .. " and watch is " ..  server.ircWatch .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "The main irc channel is now " .. server.ircMain .. ", alerts is " ..  server.ircAlerts .. " and watch is " ..  server.ircWatch)
				end
			end

			if chatvars.words[3] == "alerts" then
				server.ircAlerts = "#" .. pname

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The alerts irc channel is now " .. server.ircAlerts .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "The alerts irc channel is now " .. server.ircAlerts)
				end
			end

			if chatvars.words[3] == "watch" then
				server.ircWatch = "#" .. pname

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The watch irc channel is now " .. server.ircWatch .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "The watch irc channel is now " .. server.ircWatch)
				end
			end

			conn:execute("UPDATE server SET ircMain = '" .. escape(server.ircMain) .. "', ircAlerts = '" .. escape(server.ircAlerts) .. "', ircWatch = '" .. escape(server.ircWatch) .. "'")

			joinIRCServer()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetIRCNick()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set irc nick {bot name}"
			help[2] = "Change the bot's IRC nickname. Sometimes it can have a nick collision with itself and it gets an underscore appended to it."

			tmp.command = help[1]
			tmp.keywords = "set,irc,nick,name"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, " irc")) and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "irc" and chatvars.words[3] == "nick" and chatvars.words[4] ~= "" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = chatvars.wordsOld[4]

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot's irc nick is now " .. pname .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, "The bot's irc nick is now " .. pname)
			end

			if setIrcNick ~= nil then
				-- Mudlet 3.x
				setIrcNick(pname)
			end

			if ircSetNick ~= nil then
				-- TheFae's modded mudlet
				ircSetNick(pname)
			end

			server.ircBotName = pname
			conn:execute("UPDATE server SET ircBotname = '" .. escape(pname) .. "'")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetIRCServer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set irc server {IP or URL and optional port}"
			help[2] = "Use this command if you want players to know your IRC server's address."

			tmp.command = help[1]
			tmp.keywords = "set,irc,server,port"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, " irc")) and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "set" and chatvars.words[2] == "irc" and chatvars.words[3] == "server") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = string.sub(chatvars.command, string.find(chatvars.command, "server") + 7)
			tmp = string.trim(tmp)

			if tmp == nil or tmp == "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]A server name is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "A server name is required.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The IRC server is now at " .. tmp .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "The IRC server is now at " .. tmp)
				end

				temp = string.split(tmp, ":")
				server.ircServer = temp[1]

				if temp[2] ~= nil then
					server.ircPort = temp[2]
					conn:execute("UPDATE server SET ircServer = '" .. escape(server.ircServer) .. "', ircPort = '" .. escape(server.ircPort) .. "'")
				else
					conn:execute("UPDATE server SET ircServer = '" .. escape(server.ircServer) .. "'")
				end

				joinIRCServer()
				ircSaveSessionConfigs()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMapSize()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set map size {number}"
			help[2] = "Set the maximum distance from 0,0 that players are allowed to travel. Any players already outside this limit will be teleported to 0,0 and may get stuck under the map.  They can relog.\n"
			help[2] = help[2] .. "Size is in metres (blocks) and be careful not to set it too small.  The default map size is 10000 but the bot's default is 20000.\n"
			help[2] = help[2] .. "Whatever size you set, donors will be able to travel 5km futher out so the true boundary is +5000."

			tmp.command = help[1]
			tmp.keywords = "set,map,size,limit,bound"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, " map")) and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "set" and chatvars.words[2] == "map" and chatvars.words[3] == "size") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				server.mapSize = chatvars.number
				message("say [" .. server.chatColour .. "]Players are now restricted to " .. tonumber(chatvars.number) + 5000 .. " meters from 0,0[-]")

				conn:execute("UPDATE server SET mapSize = " .. chatvars.number)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxAnimals()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set max animals {number}"
			help[2] = "Change the server's max spawned animals."

			tmp.command = help[1]
			tmp.keywords = "set,max,animals,entities"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, " max") or string.find(chatvars.command, "anim") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "animals" and chatvars.words[4] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				if chatvars.number > 150 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]" .. chatvars.number .. " is too high. Set a lower limit.[-]")
					else
						irc_chat(chatvars.ircAlias, chatvars.number .. " is too high. Set a lower limit.")
					end

					botman.faultyChat = false
					return true
				end

				sendCommand("sg MaxSpawnedAnimals " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Max spawned animals is now " .. chatvars.number .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Max spawned animals is now " .. chatvars.number)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxHackerFlyingGroundHeight()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set hacker flying trigger {number}"
			help[2] = "The anti-cheat flying detection will trigger when a player is detected more than this high above the ground."
			help[2] = help[2] .. "Default is 7. Used by the bot's flying hacker detection when enabled with {#}disallow flying."

			tmp.command = help[1]
			tmp.keywords = "set,max,fly,height"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, " max") or string.find(chatvars.command, "fly") or string.find(chatvars.command, "height") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and string.find(chatvars.words[2], "hack") and string.find(chatvars.words[3], "fly") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				if chatvars.number == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Set a higher value than 0 or disable this feature with {#}allow flying[-]")
					else
						irc_chat(chatvars.ircAlias, "Set a higher value than 0 or disable this feature with cmd {#}allow flying")
					end

					botman.faultyChat = false
					return true
				end

				server.hackerFlyingTrigger = tonumber(chatvars.number)
				conn:execute("UPDATE server SET hackerFlyingTrigger = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Hacker flying detection will trigger for players flying more than " .. chatvars.number .. " blocks above the ground.[-]")
				else
					irc_chat(chatvars.ircAlias, "Hacker flying detection will trigger for players flying more than " .. chatvars.number .. " blocks above the ground.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxPing()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set (or clear) max ping {number}"
			help[2] = "To kick high ping players set a max ping.  It will only be applied to new players. You can also whitelist a new player to make them exempt.\n"
			help[2] = help[2] .. "The bot doesn't immediately kick for high ping, it samples ping over 30 seconds and will only kick for a sustained high ping."

			tmp.command = help[1]
			tmp.keywords = "set,max,ping,kick"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "ping") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "set" or chatvars.words[1] == "clear") and chatvars.words[2] == "max" and chatvars.words[3] == "ping" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "clear" then
				server.pingKick = -1
				conn:execute("UPDATE server SET pingKick = -1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Ping kicking is disabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "Ping kicking is disabled.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				if tonumber(chatvars.number) > -1 and tonumber(chatvars.number) < 100 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]" .. chatvars.number .. " is quite low. Enter a number > 99[-]")
					else
						irc_chat(chatvars.ircAlias, chatvars.number .. " is quite low. Enter a number > 99")
					end
				else
					server.pingKick = chatvars.number
					conn:execute("UPDATE server SET pingKick = " .. chatvars.number)

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players with a ping above " .. chatvars.number .. " will be kicked from the server.[-]")
					else
						irc_chat(chatvars.ircAlias, "New players with a ping above " .. chatvars.number .. " will be kicked from the server.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxPlayers()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set max players {number}"
			help[2] = "Change the server's max players. Admins can always join using the automated reserved slots feature."

			tmp.command = help[1]
			tmp.keywords = "set,max,players"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, " max") or string.find(chatvars.command, "play") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "players" and chatvars.words[4] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))
				sendCommand("sg ServerMaxPlayerCount " .. chatvars.number)
				server.maxPlayers = chatvars.number
				conn:execute("UPDATE server SET maxPlayers = " .. chatvars.number)

				-- don't allow reserved slots to exceed max players
				if server.reservedSlots > server.maxPlayers then
					server.reservedSlots = server.maxPlayers
					conn:execute("UPDATE server SET reservedSlots = " .. server.reservedSlots)
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Max players is now " .. chatvars.number .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Max players is now " .. chatvars.number)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxUptime()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set max uptime {number}\n"
			help[1] = help[1] .. " {#}max uptime (to review it)"
			help[2] = "Set how long the server will run before the bot schedules a reboot.  The bot will always add 15 minutes as the reboot is only scheduled at that time.\n"
			help[2] = help[2] .. "Numbers 1 - 24 will be treated as hours, numbers above that will be treated as minutes.  So to set an uptime of 2 hours and 30 minutes use {#}set max uptime 150."

			tmp.command = help[1]
			tmp.keywords = "set,max,uptime,time"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, " max") or string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "max" and chatvars.words[2] == "uptime" and chatvars.words[3] == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Max server uptime is " .. server.maxServerUptime .. " hours.[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Change it with " .. server.commandPrefix .. "set max uptime {hours}[-]")
			else
				irc_chat(chatvars.ircAlias, "Max server uptime is " .. server.maxServerUptime .. " hours.")
				irc_chat(chatvars.ircAlias, "Change it with " .. server.commandPrefix .. "set max uptime {hours}")
			end

			botman.faultyChat = false
			return true
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "uptime" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				if chatvars.number == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A number is required. Up to 24 hours can be set with 1 to 24. Numbers above that are in minutes.[-]")
					else
						irc_chat(chatvars.ircAlias, "A number is required. Up to 24 hours can be set with 1 to 24. Numbers above that are in minutes.")
					end

					botman.faultyChat = false
					return true
				end

				server.maxServerUptime = chatvars.number
				conn:execute("UPDATE server SET maxServerUptime = " .. chatvars.number)

				if chatvars.number < 25 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I will reboot the server when the server has been up " .. chatvars.number .. " hours.[-]")
					else
						irc_chat(chatvars.ircAlias, "I will reboot the server when the server has been up " .. chatvars.number .. " hours.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I will reboot the server when the server has been up " .. chatvars.number .. " minutes.[-]")
					else
						irc_chat(chatvars.ircAlias, "I will reboot the server when the server has been up " .. chatvars.number .. " minutes.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxZombies()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set max zombies {number}"
			help[2] = "Change the server's max spawned zombies."

			tmp.command = help[1]
			tmp.keywords = "set,max,zeds,zombies"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, " max") or string.find(chatvars.command, "zom") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "max" and (chatvars.words[3] == "zeds" or chatvars.words[3] == "zombies") and chatvars.words[4] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				if chatvars.number > 150 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]" .. chatvars.number .. " is too high. Set a lower limit.[-]")
					else
						irc_chat(chatvars.ircAlias, chatvars.number .. " is too high. Set a lower limit.")
					end

					botman.faultyChat = false
					return true
				end

				sendCommand("sg MaxSpawnedZombies " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Max spawned zombies is now " .. chatvars.number .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Max spawned zombies is now " .. chatvars.number)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetNewPlayerMaxLevel()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set new player max level {number} (game level)"
			help[2] = "By default a new player is automatically upgraded to a regular player once they pass level 9.\n"
			help[2] = help[2] .. "Use this command to change it to a different player level."

			tmp.command = help[1]
			tmp.keywords = "set,new,player,max,level"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, " level") or string.find(chatvars.command, " play") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.command == "new player max level" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players stop being new after level " .. server.newPlayerMaxLevel .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, "New players stop being new after level " .. server.newPlayerMaxLevel)
			end

			botman.faultyChat = false
			return true
		end

		if string.find(chatvars.command, "new player max level") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.newPlayerMaxLevel = chatvars.number
				conn:execute("UPDATE server SET newPlayerMaxLevel = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players stop being new after level " .. chatvars.number .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "New players stop being new after level " .. chatvars.number)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetNewPlayerTimer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set new player timer {number} (in minutes)\n"
			help[1] = help[1] .. " {#}new player timer (to see it)"
			help[2] = "By default a new player is treated differently from regulars and has some restrictions placed on them mainly concerning inventory.\n"
			help[2] = help[2] .. "Set it to 0 to disable this feature."

			tmp.command = help[1]
			tmp.keywords = "set,new,player,timer"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, " time") or string.find(chatvars.command, " play") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "new" and chatvars.words[2] == "player" and chatvars.words[3] == "timer" and chatvars.words[4] == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players stop being new after " .. server.newPlayerTimer .. " minutes total play time.[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Change it with " .. server.commandPrefix .. "set new player timer {number} (in minutes)[-]")
			else
				irc_chat(chatvars.ircAlias, "New players stop being new after " .. server.newPlayerTimer .. " minutes total play time.")
				irc_chat(chatvars.ircAlias, "Change it with cmd " .. server.commandPrefix .. "set new player timer {number} (in minutes)")
			end

			botman.faultyChat = false
			return true
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "new" and chatvars.words[3] == "player" and chatvars.words[4] == "timer" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.newPlayerTimer = chatvars.number
				conn:execute("UPDATE server SET newPlayerTimer = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players stop being new after " .. chatvars.number .. " minutes total play time.[-]")
				else
					irc_chat(chatvars.ircAlias, "New players stop being new after " .. chatvars.number .. " minutes total play time.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetOverstackLimit()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set overstack {number} (default 1000)"
			help[2] = "Sets the maximum stack size before the bot will warn a player about overstacking.  Usually the bot learns this directly from the server as stack sizes are exceeded."

			tmp.command = help[1]
			tmp.keywords = "set,over,stack,size,limit,trigger"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "overs") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "overstack" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			server.overstackThreshold = chatvars.number
			conn:execute("UPDATE server SET overstackThreshold = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]If no overstack limit is recorded, the minimum stack size to trigger an overstack warning is " .. server.overstackThreshold .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, "If no overstack limit is recorded, the minimum stack size to trigger an overstack warning is " .. server.overstackThreshold .. ".")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetPingKickTarget()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set ping kick target {new or all}"
			help[2] = "By default if a ping kick is set it only applies to new players. Set to all to have it applied to everyone.\n"
			help[2] = help[2] .. "Note: Does not apply to exempt players which includes admins, donors and individuals that have been bot whitelisted."

			tmp.command = help[1]
			tmp.keywords = "set,ping,kick,target"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "ping") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "ping" and chatvars.words[3] == "kick" and chatvars.words[4] == "target" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[5] == "new" then
				server.pingKickTarget = "new"
				conn:execute("UPDATE server SET pingKickTarget = 'new'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Ping kicks will only happen to new players.[-]")
				else
					irc_chat(chatvars.ircAlias, "Ping kicks will only happen to new players.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[5] == "all" then
				server.pingKickTarget = "all"
				conn:execute("UPDATE server SET pingKickTarget = 'all'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Anyone except staff, donors and bot whitelisted players can be ping kicked.[-]")
				else
					irc_chat(chatvars.ircAlias, "Anyone except staff, donors and bot whitelisted players can be ping kicked.")
				end

				botman.faultyChat = false
				return true
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetPrisonTimer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set prison timer {number} (in minutes)"
			help[2] = "Set how long someone stays in prison when jailed by the bot.  To not have a time limit, set this to 0 which is the default."

			tmp.command = help[1]
			tmp.keywords = "set,prison,time"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "time") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "prison" and chatvars.words[3] == "timer" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
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
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Prisoners must be released by someone to get out of prison. There is no time limit.[-]")
				else
					irc_chat(chatvars.ircAlias, "Prisoners must be released by someone to get out of prison. There is no time limit.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Prisoners will be automatically released from prison after " .. server.maxPrisonTime .. " minutes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Prisoners will be automatically released from prison after " .. server.maxPrisonTime .. " minutes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetPVPCooldown()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set pvp cooldown {seconds}"
			help[2] = "Set how long after a pvp kill before the player can use teleport commands again."

			tmp.command = help[1]
			tmp.keywords = "set,pvp,timer,cooldown,delay,kill"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "pvp") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "pvp" and (chatvars.words[3] == "cooldown" or chatvars.words[3] == "delay" or chatvars.words[3] == "timer") and chatvars.words[4] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(chatvars.number) -- eliminate the negative

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Players must wait %s seconds after killing a player before they can teleport.[-]", chatvars.userID, server.chatColour, chatvars.number))
				else
					irc_chat(chatvars.ircAlias, string.format("Players must wait %s seconds after killing a player before they can teleport.", chatvars.number))
				end

				server.pvpTeleportCooldown = chatvars.number
				conn:execute("UPDATE server SET pvpTeleportCooldown = " .. chatvars.number)
			else
				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]A number (seconds) is required.  Set to 0 to have no timer.[-]", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "A number (seconds) is required.  Set to 0 to have no timer.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetPVPTempBanCooldown()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set pvp temp ban {minutes}"
			help[2] = "Set how long to temporarily ban a player after a pvp kill.\n"
			help[2] = help[2] .. "This is only used in PVE when there is no prison location."

			tmp.command = help[1]
			tmp.keywords = "set,pvp,ban,cooldown,timer,delay"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "pvp") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "ban") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "pvp" and chatvars.words[3] == "temp" and chatvars.words[4] == "ban" and chatvars.words[5] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(chatvars.number) -- eliminate the negative

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]PVP kills will be banned for %s minutes in PVE rules with no prison location set up.[-]", chatvars.userID, server.chatColour, chatvars.number))
				else
					irc_chat(chatvars.ircAlias, string.format("PVP kills will be banned for %s minutes in PVE rules with no prison location set up.", chatvars.number))
				end

				server.pvpTempBanCooldown = chatvars.number
				conn:execute("UPDATE server SET pvpTempBanCooldown = " .. chatvars.number)
			else
				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]A number (in minutes) is required.[-]", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "A number (in minutes) is required.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetReservedSlots()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set reserved slots {number of slots}"
			help[2] = "You can have a number of server slots reserved for admins and selected players.\n"
			help[2] = help[2] .. "Anyone can join but if the server becomes full, players who aren't staff or allowed to reserve a slot will be randomly selected and kicked if an admin or authorised player joins.\n"
			help[2] = help[2] .. "To disable, set reserved slots to 0."

			tmp.command = help[1]
			tmp.keywords = "set,reserved,slot,player"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reser") or string.find(chatvars.command, "slot") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "reserved" and chatvars.words[3] == "slots" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				if math.abs(chatvars.number) > server.maxPlayers then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Reserved slots can't be more than max players.[-]")
					else
						irc_chat(chatvars.ircAlias, "Reserved slots can't be more than max players.")
					end

					botman.faultyChat = false
					return true
				end

				server.reservedSlots = math.abs(chatvars.number)
				conn:execute("UPDATE server SET reservedSlots = " .. server.reservedSlots)

				if server.reservedSlots == 0 then
					if tonumber(server.ServerMaxPlayerCount) > tonumber(server.maxPlayers) then
						sendCommand("sg ServerMaxPlayerCount " .. server.maxPlayers) -- remove the extra slot that ensures reserved slot players can join in one go when server full
					else
						if tonumber(server.ServerMaxPlayerCount) <= tonumber(server.maxPlayers) then
							sendCommand("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add the extra slot that ensures reserved slot players can join in one go when server full
						end
					end
				end

				addOrRemoveSlots()

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. chatvars.number .. " slots are now reserved slots.[-]")
				else
					irc_chat(chatvars.ircAlias, chatvars.number .. " slots are now reserved slots.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]You didn't give me a number.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]eg " .. server.commandPrefix .. "set reserved slots 5[-]")
				else
					irc_chat(chatvars.ircAlias, "You didn't give me a number.")
					irc_chat(chatvars.ircAlias, "eg " .. server.commandPrefix .. "set reserved slots 5")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetRollingAnnouncementTimer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set rolling delay {minutes}"
			help[2] = "Set the delay in minutes between rolling announcements."

			tmp.command = help[1]
			tmp.keywords = "set,rolling,announcements,timer,delay"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "anno") or string.find(chatvars.command, "set") or string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "rolling" and chatvars.words[3] == "delay" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				conn:execute("UPDATE timedEvents SET delayMinutes = " .. chatvars.number .. " WHERE timer = 'announcements'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A rolling announcement will display every " .. chatvars.number .. " minutes when players are on.[-]")
				else
					irc_chat(chatvars.ircAlias, "A rolling announcement will display every " .. chatvars.number .. " minutes when players are on.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetRules()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set rules {new rules}"
			help[2] = "Set the server rules.  You can use supported bbcode tags, but only when setting the rules from IRC.  Each tag must be closed with this tag [-] or colours will bleed into the next line.\n"
			help[2] = help[2] .. "To display the rules type {#}rules"

			tmp.command = help[1]
			tmp.keywords = "set,rules,server"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "rules") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "set" and chatvars.words[2] == "rules" and chatvars.words[3] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			server.rules = stripQuotes(string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "rules") + 6))
			conn:execute("UPDATE server SET rules = '" .. escape(server.rules) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New rules recorded.[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.rules .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "New rules recorded.")
				irc_chat(chatvars.ircAlias, server.rules)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerAPIKey()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set server api {api key from 7daystodie-servers.com}"
			help[2] = "Your API key is not recorded in logs or the databases and no bot command reports it.  It is used to determine if a player has voted for your server today.\n"
			help[2] = help[2] .. "While the bot takes precautions to keep your API key a secret, you should be careful not to type it anywhere in public.  The safest place to give it to the bot is in private chat on IRC or on the bot's web interface when that is available."

			tmp.command = help[1]
			tmp.keywords = "set,api,key,7daystodie-servers.com,7days,7daystodie,servers"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "api") or string.find(chatvars.command, "set") or string.find(chatvars.command, "server") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "server" and chatvars.words[3] == "api" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]API key required. Get it from 7daystodie-servers.com.[-]")
				else
					irc_chat(chatvars.ircAlias, "API key required. Get it from 7daystodie-servers.com.")
				end

				botman.faultyChat = false
				return true
			end

			serverAPI = chatvars.wordsOld[4]
			writeAPI()

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]If you have enabled voting, players will receive a reward item for voting for your server once per day.[-]")
			else
				irc_chat(chatvars.ircAlias, "If you have enabled voting, players will receive a reward item for voting for your server once per day.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerVoteReward()
		local cursor, errorString, row, item, i, quantity, quality

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set server vote reward {default/random/list/item/entity}\n"
			help[1] = help[1] .. " {#}set server vote reward random quantity {number} quality {number}"
			help[2] = "The default reward is the sc_General supply crate. \n"
			help[2] = help[2] .. "If you set a random reward you can optionally set a quantity and quality.\n"
			help[2] = help[2] .. "Quality is random if not specified.\n"
			help[2] = help[2] .. "Quantity is the number of random items, not a quantity of the same item (except by chance). If quantity is not set the bot will give between 3 and 5 random items.\n"
			help[2] = help[2] .. "If you set the reward as list you will need additional commands to manage the reward items. For commands type {#}help reward list.\n"
			help[2] = help[2] .. "If you set the reward as item, the player will be given the item that you specify.\n"
			help[2] = help[2] .. "If you have a custom entity (eg sc_General2) type {#}set server vote reward entity sc_General2."

			tmp.command = help[1]
			tmp.keywords = "set,vote,reward,server"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "vote") or string.find(chatvars.command, "reward") or string.find(chatvars.command, "set") or string.find(chatvars.command, "server") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "server" and chatvars.words[3] == "vote" and chatvars.words[4] == "reward" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			item = ""
			quantity = 0
			quality = 0

			if chatvars.words[5] ~= "crate" and chatvars.words[5] ~= "random" and chatvars.words[5] ~= "list" and chatvars.words[5] ~= "item" and chatvars.words[5] ~= "entity" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Valid options are crate, random, list, or item.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]eg. {#}set server vote reward {crate/random/list/item}[-]")
				else
					irc_chat(chatvars.ircAlias, "Valid options are crate, random, list, or item.")
					irc_chat(chatvars.ircAlias, "eg. {#}set server vote reward {crate/random/list/item}")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[5] == "crate" then
				serverVoteReward = "crate"
				serverVoteRewardItem = "sc_General"
				writeAPI()

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Server votes will be rewarded with an sc_General crate next to the player.[-]")
				else
					irc_chat(chatvars.ircAlias, "Server votes will be rewarded with an sc_General crate next to the player.")
				end
			end

			if chatvars.words[5] == "random" then
				serverVoteReward = "random"
				serverVoteRewardItem = ""

				for i=6,chatvars.wordCount,1 do
					if chatvars.words[i] == "quantity" then
						quantity = chatvars.wordsOld[i+1]
					end

					if chatvars.words[i] == "quality" then
						quality = chatvars.wordsOld[i+1]
					end
				end

				serverVoteRewardQuantity = tonumber(quantity)
				serverVoteRewardQuality = tonumber(quality)
				writeAPI()

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Server votes will be rewarded with random items.[-]")
				else
					irc_chat(chatvars.ircAlias, "Server votes will be rewarded with random items.")
				end
			end

			if chatvars.words[5] == "list" then
				serverVoteReward = "list"
				serverVoteRewardItem = ""

				if serverVoteRewardList == nil then
					serverVoteRewardList = {}
				end

				writeAPI()

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Server votes will be rewarded with set items from a list.[-]")
				else
					irc_chat(chatvars.ircAlias, "Server votes will be rewarded with set items from a list.")
				end
			end

			if chatvars.words[5] == "item" then
				serverVoteReward = "item"
				serverVoteRewardItem = chatvars.wordsOld[6]
				writeAPI()

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Server votes will be rewarded with a " .. serverVoteRewardItem .. " given to the player.[-]")
				else
					irc_chat(chatvars.ircAlias, "Server votes will be rewarded with a " .. serverVoteRewardItem .. " given to the player.")
				end
			end

			if chatvars.words[5] == "entity" then
				serverVoteReward = "entity"
				serverVoteRewardItem = chatvars.wordsOld[6]
				writeAPI()

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Server votes will be rewarded with a " .. serverVoteRewardItem .. " spawned next to the player.[-]")
				else
					irc_chat(chatvars.ircAlias, "Server votes will be rewarded with a " .. serverVoteRewardItem .. " spawned next to the player.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerGroup()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set server group {group name} (one word)"
			help[2] = "This is used by the bots database which could be a cloud database.  It is used to identify this bot as belonging to a group if you have more than one server.  You do not need to set this."

			tmp.command = help[1]
			tmp.keywords = "set,server,group"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "serv") or string.find(chatvars.command, "group") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "server" and chatvars.words[3] == "group" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.group = chatvars.wordsOld[4]

			if tmp.group == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Group name required.  One word, no spaces.[-]")
				else
					irc_chat(chatvars.ircAlias, "Group name required.  One word, no spaces.")
				end

				botman.faultyChat = false
				return true
			else
				server.serverGroup = tmp.group
				conn:execute("UPDATE server SET serverGroup = '" .. escape(tmp.group) .. "'")

				if botman.botsConnected then
					-- update server in bots db
					connBots:execute("UPDATE servers SET serverGroup = '" .. escape(tmp.group) .. "' WHERE serverName = '" .. escape(server.serverName) .. "'")
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This server is now a member of " .. tmp.group .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "This server is now a member of " .. tmp.group .. ".")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerIP()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set server ip {IP of your 7 Days to Die server}"
			help[2] = "The bot is unable to read the IP from its own profile for the server so enter it here.  It will display in the {#}info command and be used if a few other places."

			tmp.command = help[1]
			tmp.keywords = "set,server,ip"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "server") or string.find(chatvars.command, " ip") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "server" and chatvars.words[3] == "ip" and chatvars.words[5] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = chatvars.words[4]

			if tmp == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]The server ip is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "The server ip is required.")
				end
			else
				server.IP = tmp
				conn:execute("UPDATE server SET IP = '" .. escape(server.IP) .. "'")

				if botman.botsConnected then
					connBots:execute("UPDATE servers SET IP = '" .. escape(server.IP) .. "' WHERE botID = " .. server.botID)
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The server ip is now " .. server.IP .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "The server ip is now " .. server.IP)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerRebootHour()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set reboot hour {0 to 23}"
			help[2] = "Reboot the server when the server time matches the hour (24 hour time).  To disable clock based reboots set this to -1 or don't enter a number."

			tmp.command = help[1]
			tmp.keywords = "set,server,reboot,hour,time,restart"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reboot") or string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "reboot" and chatvars.words[3] == "hour" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
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
							message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]A number from 0 to 23 was expected.[-]")
						else
							irc_chat(chatvars.ircAlias, "A number from 0 to 23 was expected.")
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
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]You have disabled clock based reboots.[-]")
				else
					irc_chat(chatvars.ircAlias, "You have disabled clock based reboots.")
				end
			else
				server.rebootHour = chatvars.number
				conn:execute("UPDATE server SET rebootHour = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerRebootMinute()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set reboot minute {0 to 59}"
			help[2] = "Reboot the server when the server time matches the hour and minute (24 hour time).  To disable clock based reboots use {#}set reboot hour (without a number)"

			tmp.command = help[1]
			tmp.keywords = "set,server,reboot,minutes,time,restart"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reboot") or string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "reboot" and chatvars.words[3] == "minute" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
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
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]A number from 0 to 59 was expected.[-]")
				else
					irc_chat(chatvars.ircAlias, "A number from 0 to 59 was expected.")
				end
			else
				server.rebootMinute = chatvars.number
				conn:execute("UPDATE server SET rebootMinute = " .. chatvars.number)

				if tonumber(server.rebootHour) > -1 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Now set the reboot hour with " .. server.commandPrefix .. "set reboot hour {0-23}.[-]")
					else
						irc_chat(chatvars.ircAlias, "Now set the reboot hour with " .. server.commandPrefix .. "set reboot hour {0-23}.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerType()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set server pve (or pvp, creative or contest)"
			help[2] = "Set the entire server to be PVE, PVP, Creative or Contest.\n"
			help[2] = help[2] .. "Contest mode is not implemented yet and all setting it creative does is stop the bot pestering players about their inventory."

			tmp.command = help[1]
			tmp.keywords = "set,server,pvp,pve,creative,contest,mode,game"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "server") or string.find(chatvars.command, "pve") or string.find(chatvars.command, "pvp") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "set" and chatvars.words[2] == "server") and chatvars.words[3] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
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
	end


	local function cmd_SetupAllocsWebMap()
		local web

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}setup map"
			help[2] = "Optional extras after setup map: no hostiles, no animals, show players, show claims, show inventory\n"
			help[2] = help[2] .. "eg. {#}setup map no hostiles no animals show players show claims show inventory\n"
			help[2] = help[2] .. "If you want to manually set a web permission, here is a valid console command for reference\n"
			help[2] = help[2] .. "webpermission add webapi.getplayersOnline global 1000\n"
			help[2] = help[2] .. "The bot can fix your server map's permissions with some nice settings.  If you use this command, the following permissions are set:\n"
			help[2] = help[2] .. "web.map 2000\n"
			help[2] = help[2] .. "webapi.getlandclaims 1000\n"
			help[2] = help[2] .. "webapi.viewallplayers 2\n"
			help[2] = help[2] .. "webapi.viewallclaims 2\n"
			help[2] = help[2] .. "webapi.getplayerinventory 2\n"
			help[2] = help[2] .. "webapi.getplayerslocation 2\n"
			help[2] = help[2] .. "webapi.getplayersOnline 1000\n"
			help[2] = help[2] .. "webapi.getstats 1000\n"
			help[2] = help[2] .. "webapi.gethostilelocation 2000\n"
			help[2] = help[2] .. "webapi.getanimalslocation 2000\n"
			help[2] = help[2] .. "If setting no hostiles and/or no animals:\n"
			help[2] = help[2] .. "webapi.gethostilelocation 2\n"
			help[2] = help[2] .. "webapi.getanimalslocation 2\n"
			help[2] = help[2] .. "If setting show players, show claims, show inventory:\n"
			help[2] = help[2] .. "webapi.viewallplayers 1000\n"
			help[2] = help[2] .. "webapi.viewallclaims 1000\n"
			help[2] = help[2] .. "webapi.getplayerinventory 1000"

			tmp.command = help[1]
			tmp.keywords = "set,map,permissions,live"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "map") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "setup" and string.find(chatvars.words[2], "map") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			web = "webpermission"

			sendCommand(web .. " add web.map global 2000")
			sendCommand(web .. " add webapi.getplayersOnline global 1000")
			sendCommand(web .. " add webapi.getstats global 1000")
			sendCommand(web .. " add webapi.getlandclaims global 1000")

			if string.find(chatvars.command, "no hostiles") then
				sendCommand(web .. " add webapi.gethostilelocation global 2")
			else
				sendCommand(web .. " add webapi.gethostilelocation global 2000")
			end

			if string.find(chatvars.command, "no animals") then
				sendCommand(web .. " add webapi.getanimalslocation global 2")
			else
				sendCommand(web .. " add webapi.getanimalslocation global 2000")
			end

			if string.find(chatvars.command, "show players") then
				sendCommand(web .. " add webapi.viewallplayers global 2000")
				sendCommand(web .. " add webapi.GetPlayersLocation global 2000")
			else
				sendCommand(web .. " add webapi.viewallplayers global 2")
				sendCommand(web .. " add webapi.GetPlayersLocation global 0")
			end

			if string.find(chatvars.command, "show claims") then
				sendCommand(web .. " add webapi.viewallclaims global 2000")
				sendCommand(web .. " add webapi.getlandclaims global 2000")
			else
				sendCommand(web .. " add webapi.viewallclaims global 2")
				sendCommand(web .. " add webapi.getlandclaims global 1000")
			end

			if string.find(chatvars.command, "show inventory") then
				sendCommand(web .. " add webapi.getplayerinventory global 2000")
			else
				sendCommand(web .. " add webapi.getplayerinventory global 2")
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The map permissions have been set.[-]")
			else
				irc_chat(chatvars.ircAlias, "The map permissions have been set.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetWebPanelPort() -- tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set web panel port {port of server's control panel/web panel}\n"
			help[1] = help[1] .. "or {#}set api port {number}"
			help[2] = "The bot needs to be told the port for Alloc's web map. If you give it the wrong port and API support is enabled or you enable that later, the bot will try that port and the ports +/- 2 above and below it."

			tmp.command = help[1]
			tmp.keywords = "set,web,port,panel"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "web") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "set" and (chatvars.words[2] == "web" or chatvars.words[2] == "control") and chatvars.words[3] == "panel" and chatvars.words[4] == "port") or (chatvars.words[1] == "set" and chatvars.words[2] == "api" and chatvars.words[3] == "port") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Port number between 1 and 65535 expected.[-]")
				else
					irc_chat(chatvars.ircAlias, "Port number between 1 and 65535 expected.")
				end

				botman.faultyChat = false
				return true
			else
				chatvars.number = math.abs(chatvars.number)
			end

			if tonumber(chatvars.number) > 65535 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Valid ports range from 1 to 65535.[-]")
				else
					irc_chat(chatvars.ircAlias, "Valid ports range from 1 to 65535.")
				end

				botman.faultyChat = false
				return true
			end

			if server.useAllocsWebAPI then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The web API will now be re-tested because the port has changed.[-]")
				else
					irc_chat(chatvars.ircAlias, "The web API will now be re-tested because the port has changed.")
				end
			end

			server.webPanelPort = chatvars.number
			botman.oldAPIPort = server.webPanelPort
			botman.testAPIPort = nil
			conn:execute("UPDATE server SET webPanelPort = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You set the web panel port to " .. chatvars.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "You set the web panel port to " .. chatvars.number)
			end

			connectToAPI()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetWebsite()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set website {your website or steam group}"
			help[2] = "Tell the bot the URL of your website or steam group so your players can ask for it."

			tmp.command = help[1]
			tmp.keywords = "set,website,url"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "web") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "set" and chatvars.words[2] == "website") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = string.sub(chatvars.command, string.find(chatvars.command, "website") + 8)
			tmp = string.trim(tmp)

			if tmp == nil then
				tmp = ""
			end

			server.website = tmp
			conn:execute("UPDATE server SET website = '" .. escape(tmp) .. "'")

			if tmp ~= "" then
				message("say [" .. server.chatColour .. "]Our website/group is " .. tmp .. ". Check us out! :3[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetWelcomeMessage()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set welcome message {your message here}\n"
			help[1] = help[1] .. " {#}clear welcome message"
			help[2] = "You can set a custom welcome message that will override the default greeting message when a player joins."

			tmp.command = help[1]
			tmp.keywords = "set,welcome,messages"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "welc") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "set" or chatvars.words[1] == "clear") and chatvars.words[2] == "welcome" and chatvars.words[3] == "message" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "clear" then
				server.welcome = nil
				conn:execute("UPDATE server SET welcome = null")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Server welcome message cleared.[-]")
				else
					irc_chat(chatvars.ircAlias, "Server welcome message cleared.")
				end

				botman.faultyChat = false
				return true
			end

			msg = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "message") + 8)
			msg = string.trim(msg)

			server.welcome = msg
			conn:execute("UPDATE server SET welcome = '" .. escape(msg) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New welcome message " .. msg .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "New welcome message " .. msg)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TestVoteReward()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}test vote reward"
			help[2] = "Admin and in-game only. The bot will try to spawn the server vote reward beside you."

			tmp.command = help[1]
			tmp.keywords = "test,vote,reward,server"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "test") or string.find(chatvars.command, "vote") or string.find(chatvars.command, "rewa") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "test" and chatvars.words[2] == "vote" and chatvars.words[3] == "reward" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			rewardServerVote(chatvars.gameid)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The server vote reward item or entity should have spawned beside you or been added to inventory.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBadNames()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}allow/disallow bad names"
			help[2] = "Auto-kick players with numeric names or names that contain no letters such as ascii art crap.\n"
			help[2] = help[2] .. "They will see a kick message asking them to change their name."

			tmp.command = help[1]
			tmp.keywords = "allow,bad,names"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "bad") or string.find(chatvars.command, "name") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow") and chatvars.words[2] == "bad" and chatvars.words[3] == "names" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "allow" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players with names that have no letters can play here.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players with names that have no letters can play here.")
				end

				server.allowNumericNames = true
				server.allowGarbageNames = true
				conn:execute("UPDATE server SET allowNumericNames = 1, allowGarbageNames = 1")
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I will kick players with names that have no letters.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will kick players with names that have no letters.")
				end

				server.allowNumericNames = false
				server.allowGarbageNames = false
				conn:execute("UPDATE server SET allowNumericNames = 0, allowGarbageNames = 0")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBanVACBannedPlayers()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) vac (disable is the default)"
			help[2] = "If a player has any VAC bans you can auto-ban them or allow them in.\n"
			help[2] = help[2] .. "Each time they join, admins will be alerted to their VAC ban. To stop that, add the them to the bot's whitelist."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,vac,ban,alerts"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "ban") or string.find(chatvars.command, "vac") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "vac" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players with VAC bans can play here.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players with VAC bans can play here.")
				end

				server.banVACBannedPlayers = false
				conn:execute("UPDATE server SET banVACBannedPlayers = 0")
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players with VAC bans will be banned from the server unless they are staff or whitelisted.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players with VAC bans will be banned from the server unless they are staff or whitelisted.")
				end

				server.banVACBannedPlayers = true
				conn:execute("UPDATE server SET banVACBannedPlayers = 1")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleDespawnZombiesBeforeBloodMoon()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}remove zombies before bloodmoon\n"
			help[1] = help[1] .. " {#}leave zombies before bloodmoon\n"
			help[2] = "This command is temporarily disabled until the Botman mod can despawn multiple entities using a filter."

			tmp.command = help[1]
			tmp.keywords = "blood,horde,remove,despawn,day"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "remov") or string.find(chatvars.command, "zomb") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "remove" or chatvars.words[1] == "leave") and chatvars.words[2] == "zombies" and chatvars.words[3] == "before" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "remove" then
				server.despawnZombiesBeforeBloodMoon = true
				conn:execute("UPDATE server SET despawnZombiesBeforeBloodMoon = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]All zombies will despawn one or more times during 9pm before bloodmoon begins.[-]")
				else
					irc_chat(chatvars.ircAlias, "All zombies will despawn one or more times during 9pm before bloodmoon begins.")
				end
			else
				server.despawnZombiesBeforeBloodMoon = false
				conn:execute("UPDATE server SET despawnZombiesBeforeBloodMoon = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Zombies will not be despawned before bloodmoon begins.[-]")
				else
					irc_chat(chatvars.ircAlias, "Zombies will not be despawned before bloodmoon begins.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleEntityScan()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) entity scan (disabled by default)"
			help[2] = "Scan for entities server wide every 30 seconds.\n"
			help[2] = help[2] .. "The resulting list is copied to the entities Lua table where it can be further processed for other bot features."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,scan,entity"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "scan") or string.find(chatvars.command, "ent") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "entity" and chatvars.words[3] == "scan" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.scanEntities = true
				conn:execute("UPDATE server SET scanEntities = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]I will scan entities every 30 seconds.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will scan entities every 30 seconds.")
				end
			else
				server.scanEntities = false
				conn:execute("UPDATE server SET scanEntities = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]I will not scan for entities.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will not scan for entities.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleErrorScan()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) error scan (disabled by default)"
			help[2] = "The server can automatically scan for and fix some errors using console commands if you have the BC mod or Botman mod installed.\n"
			help[2] = help[2] .. "You can disable the scan if you suspect it is creating lag."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,scan,error"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "scan") or string.find(chatvars.command, "err") or string.find(chatvars.command, "fix") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "error" and chatvars.words[3] == "scan" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.scanErrors = true
				conn:execute("UPDATE server SET scanErrors = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]I will scan the server for errors.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will scan the server for errors.")
				end
			else
				server.scanErrors = false
				conn:execute("UPDATE server SET scanErrors = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]I will not scan for errors.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will not scan for errors.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleFamilySteamKeys()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}allow/disallow family (allowed by default)"
			help[2] = "Set to disallow if you require all players use the owner steam key and want to block players with a steamid that does not match the steamOwner."

			tmp.command = help[1]
			tmp.keywords = "allow,steam,owner,family"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "allow") or string.find(chatvars.command, "steam") or string.find(chatvars.command, "family") or string.find(chatvars.command, "owner") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow") and chatvars.words[2] == "family" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "allow" then
				server.allowFamilySteamKeys = true
				conn:execute("UPDATE server SET allowFamilySteamKeys = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Players can join using a family key.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can join using a family key.")
				end
			else
				server.allowFamilySteamKeys = false
				conn:execute("UPDATE server SET allowFamilySteamKeys = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Players that join with a family key will be kicked.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players that join with a family key will be kicked.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleHardcoreMode()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) hardcore mode"
			help[2] = "Allow players to use bot commands.  This is the default.\n"
			help[2] = help[2] .. "Players can still talk to the bot and use info commands such as {#}rules."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,hardcore,mode,commands"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "hard") or string.find(chatvars.command, "mode") or string.find(chatvars.command, "server") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "hardcore" and chatvars.words[3] == "mode" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "disable" then
				server.hardcore = false
				conn:execute("UPDATE server SET hardcore = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can command the bot.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can command the bot.")
				end
			else
				server.hardcore = true
				conn:execute("UPDATE server SET hardcore = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can only talk to the bot and do basic info commands.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can only talk to the bot and do basic info commands.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIdleKick()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) idle kick (disabled is default)"
			help[2] = "When the server is full, if idle kick is on players will get kick warnings for 15 minutes of no movement then they get kicked."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,idle,kick"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "idle") or string.find(chatvars.command, "kick") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "idle" and chatvars.words[3] == "kick" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.idleKick = true
				conn:execute("UPDATE server SET idleKick = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]When the server is full, idling players will get kick warnings for 15 minutes then kicked if they don't move.[-]")
				else
					irc_chat(chatvars.ircAlias, "When the server is full, idling players will get kick warnings for 15 minutes then kicked if they don't move.")
				end
			else
				server.idleKick = false
				conn:execute("UPDATE server SET idleKick = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will not be kicked for idling on the server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will not be kicked for idling on the server.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIdleKickAnytime()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}allow/disallow idling (allowed is default)"
			help[2] = "If idle kick is enabled the default is to only kick idle players when the server is full. By setting disallow idling, players can be kicked for idling any time."

			tmp.command = help[1]
			tmp.keywords = "allow,idle,kick"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "idle") or string.find(chatvars.command, "kick") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow") and chatvars.words[2] == "idling" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "allow" then
				server.idleKickAnytime = false
				conn:execute("UPDATE server SET idleKickAnytime = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Idle players will only be kicked when the server is full and idle kicking is enabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "Idle players will only be kicked when the server is full and idle kicking is enabled.")
				end
			else
				server.idleKickAnytime = true
				conn:execute("UPDATE server SET idleKickAnytime = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Idle players can be kicked any time if idle kicking is enabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "Idle players can be kicked any time if idle kicking is enabled.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIgnorePlayerFlying()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}allow/disallow flying"
			help[2] = "Toggle the bot's player flying detection.  You would want to do this if players can use debug mode on your server."

			tmp.command = help[1]
			tmp.keywords = "allow,flying"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "fly") or string.find(chatvars.command, "hack") or string.find(chatvars.command, "tele") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow") and chatvars.words[2] == "flying" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "allow" then
				server.playersCanFly = true
				conn:execute("UPDATE server SET playersCanFly = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players are allowed to fly.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players are allowed to fly.")
				end
			else
				server.playersCanFly = false
				conn:execute("UPDATE server SET playersCanFly = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will be temp banned for flying.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will be temp banned for flying.")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIRCPrivate()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set irc private (or public)"
			help[2] = "If IRC is private, the bot won't share the url or info with players and players can't invite anyone to irc using the invite command.\n"
			help[2] = help[2] .. "When public, players can find the IRC info with {#}help irc and they can create irc invites for themselves and others."

			tmp.command = help[1]
			tmp.keywords = "set,irc,public,private"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "irc") or string.find(chatvars.command, "pub") or string.find(chatvars.command, "priv") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "irc" and (chatvars.words[3] == "public" or chatvars.words[3] == "private") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[3] == "public" then
				server.ircPrivate = false
				conn:execute("UPDATE server SET ircPrivate = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can see the IRC server info and can create IRC invites.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can see the IRC server info and can create IRC invites.")
				end
			else
				server.ircPrivate = true
				conn:execute("UPDATE server SET ircPrivate = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will not see the IRC server info and cannot create IRC invites.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will not see the IRC server info and cannot create IRC invites.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleNoClipScan()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) noclip scan (defaults disabled)"
			help[2] = "Using the Botman mod you can detect players that are noclipping under the map.\n"
			help[2] = help[2] .. "It can false flag but it is still a useful early warning of a possible hacker.  The bot will ban a player found clipping a lot for one week."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,scan,noclip,hackers,flying,map,underground"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "scan") or string.find(chatvars.command, "clip") or string.find(chatvars.command, "fly") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "noclip" and chatvars.words[3] == "scan" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.scanNoclip = true
				conn:execute("UPDATE server SET scanNoclip = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]I will scan for noclipping players and report them to IRC.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will scan for noclipping players and report them to IRC.")
				end
			else
				server.scanNoclip = false
				conn:execute("UPDATE server SET scanNoclip = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]I will not scan for noclipping players.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will not scan for noclipping players.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleOverstackChecking()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) overstack checking"
			help[2] = "By default the bot reads overstack warnings coming from the server to learn what the stack limits are and it will pester players with excessive stack sizes and can send them to timeout for non-compliance."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,allow,overstack,hackers,duping,dupers,cheaters"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "overs") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and string.find(chatvars.words[2], "overstack") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.allowOverstacking = false
				conn:execute("UPDATE server SET allowOverstacking = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I will monitor stack sizes, warn and alert for overstacking.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will monitor stack sizes, warn and alert for overstacking.")
				end
			else
				server.allowOverstacking = true
				conn:execute("UPDATE server SET allowOverstacking = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I will ignore overstacking.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will ignore overstacking.")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TogglePVPRulesByCompass()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}northeast pve (or pvp)\n"
			help[1] = help[1] .. " {#}northeast pve (or pvp)\n"
			help[1] = help[1] .. " {#}northwest pve (or pvp)\n"
			help[1] = help[1] .. " {#}southeast pve (or pvp)\n"
			help[1] = help[1] .. " {#}southwest pve (or pvp)\n"
			help[1] = help[1] .. " {#}north pve (or pvp)\n"
			help[1] = help[1] .. " {#}south pve (or pvp)\n"
			help[1] = help[1] .. " {#}east pve (or pvp)\n"
			help[1] = help[1] .. " {#}west pve (or pvp)"
			help[2] = "Make northeast/northwest/southeast/southwest/north/south/east/west of 0,0 PVE or PVP."

			tmp.command = help[1]
			tmp.keywords = "set,pvp,pve,north,south,east,west,map,world,game,rules"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "northeast" or chatvars.words[1] == "northwest" or chatvars.words[1] == "southeast" or chatvars.words[1] == "southwest" or chatvars.words[1] == "north" or chatvars.words[1] == "south" or chatvars.words[1] == "east" or chatvars.words[1] == "west") and chatvars.words[2] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "northeast pvp.[-]")
				else
					irc_chat(chatvars.ircAlias, "Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "northeast pvp.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "northeast" then
				server.northeastZone = chatvars.words[2]
				conn:execute("UPDATE server SET northeastZone = '" .. escape(chatvars.words[2]) .. "'")

				message("say [" .. server.chatColour .. "]Northeast of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "Northeast of 0,0 is now a " .. chatvars.words[2] .. " zone!")
				end
			end

			if chatvars.words[1] == "northwest" then
				server.northwestZone = chatvars.words[2]
				conn:execute("UPDATE server SET northwestZone = '" .. escape(chatvars.words[2]) .. "'")

				message("say [" .. server.chatColour .. "]Northwest of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "Northwest of 0,0 is now a " .. chatvars.words[2] .. " zone!")
				end
			end

			if chatvars.words[1] == "southeast" then
				server.southeastZone = chatvars.words[2]
				conn:execute("UPDATE server SET southeastZone = '" .. escape(chatvars.words[2]) .. "'")

				message("say [" .. server.chatColour .. "]Southeast of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "Southeast of 0,0 is now a " .. chatvars.words[2] .. " zone!")
				end
			end

			if chatvars.words[1] == "southwest" then
				server.southwestZone = chatvars.words[2]
				conn:execute("UPDATE server SET southwestZone = '" .. escape(chatvars.words[2]) .. "'")

				message("say [" .. server.chatColour .. "]Southwest of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "Southwest of 0,0 is now a " .. chatvars.words[2] .. " zone!")
				end
			end

			if chatvars.words[1] == "north" then
				server.northeastZone = chatvars.words[2]
				server.northwestZone = chatvars.words[2]
				conn:execute("UPDATE server SET northwestZone = '" .. escape(chatvars.words[2]) .. "', northeastZone = '" .. escape(chatvars.words[2]) .. "'")

				message("say [" .. server.chatColour .. "]North of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "North of 0,0 is now a " .. chatvars.words[2] .. " zone!")
				end
			end

			if chatvars.words[1] == "south" then
				server.southeastZone = chatvars.words[2]
				server.southwestZone = chatvars.words[2]
				conn:execute("UPDATE server SET southwestZone = '" .. escape(chatvars.words[2]) .. "', southeastZone = '" .. escape(chatvars.words[2]) .. "'")

				message("say [" .. server.chatColour .. "]South of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "South of 0,0 is now a " .. chatvars.words[2] .. " zone!")
				end
			end

			if chatvars.words[1] == "east" then
				server.northeastZone = chatvars.words[2]
				server.southeastZone = chatvars.words[2]
				conn:execute("UPDATE server SET northeastZone = '" .. escape(chatvars.words[2]) .. "', southeastZone = '" .. escape(chatvars.words[2]) .. "'")

				message("say [" .. server.chatColour .. "]East of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "East of 0,0 is now a " .. chatvars.words[2] .. " zone!")
				end
			end

			if chatvars.words[1] == "west" then
				server.northwestZone = chatvars.words[2]
				server.southwestZone = chatvars.words[2]
				conn:execute("UPDATE server SET northwestZone = '" .. escape(chatvars.words[2]) .. "', southwestZone = '" .. escape(chatvars.words[2]) .. "'")

				message("say [" .. server.chatColour .. "]West of 0,0 is now a " .. chatvars.words[2] .. " zone![-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "West of 0,0 is now a " .. chatvars.words[2] .. " zone!")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleRapidRelogTempBan()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}allow (or {#}disallow) rapid relog"
			help[2] = "New players who want to cheat often relog rapidly in order to spawn lots of items into the server using cheats or bugs.\n"
			help[2] = help[2] .. "If enabled, the bot will temp ban (10 minutes) players caught relogging several times in short order."

			tmp.command = help[1]
			tmp.keywords = "disallow,rapid,relogging,join,players"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "relog") or string.find(chatvars.command, "allow") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow") and chatvars.words[2] == "rapid" and string.find(chatvars.command, "relog") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "allow"	then
				server.allowRapidRelogging = true
				conn:execute("UPDATE server SET allowRapidRelogging = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will do nothing about new players relogging multiple times rapidly.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will do nothing about new players relogging multiple times rapidly.")
				end
			else
				server.allowRapidRelogging = false
				conn:execute("UPDATE server SET allowRapidRelogging = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players relogging a lot in a short time will be banned for 10 minutes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players relogging a lot in a short time will be banned for 10 minutes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleRegionPM()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) region pm"
			help[2] = "A PM for admins that tells them the region name when they move to a new region."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,region,pm"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "region") or string.find(chatvars.command, " pm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "region" and chatvars.words[3] == "pm" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.enableRegionPM = true
				conn:execute("UPDATE server SET enableRegionPM = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The current region will be PM'ed to admins.[-]")
				else
					irc_chat(chatvars.ircAlias, "The current region will be PM'ed to admins.")
				end
			else
				server.enableRegionPM = false
				conn:execute("UPDATE server SET enableRegionPM = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The current region will not be PM'ed.[-]")
				else
					irc_chat(chatvars.ircAlias, "The current region will not be PM'ed.")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleServerReboots()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or disable) reboot"
			help[2] = "By default the bot does not manage server reboots.\n"
			help[2] = help[2] .. "See also {#}set max uptime (default 12 hours)"

			tmp.command = help[1]
			tmp.keywords = "enable,disable,reboots,restarts,shutdowns,stop"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "reboot" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.allowReboot = true
				conn:execute("UPDATE server SET allowReboot = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I will automatically reboot the server as needed.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will automatically reboot the server as needed.")
				end
			else
				server.allowReboot = false
				conn:execute("UPDATE server SET allowReboot = 0")

				-- also cancel any pending reboot
				botman.scheduledRestart = false
				botman.scheduledRestartTimestamp = os.time()
				botman.scheduledRestartPaused = false
				botman.scheduledRestartForced = false

				if (botman.rebootTimerID ~= nil) then killTimer(botman.rebootTimerID) end
				if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end

				botman.rebootTimerID = nil
				rebootTimerDelayID = nil

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I will not reboot the server.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will not reboot the server.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleTelnetDisabled()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set telnet enabled (or disabled) (enabled is the default)"
			help[2] = "This doesn't change telnet in the server.  Instead use this to tell the bot if the server's telnet is enabled or disabled.\n"
			help[2] = help[2] .. "This is used by the bot as part of monitoring the status of telnet.  If telnet is disabled, the bot won't keep trying to connect to it."

			tmp.command = help[1]
			tmp.keywords = "set,telnet,enable,disable"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "able") or string.find(chatvars.command, "telnet") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "telnet" and (chatvars.words[3] == "enabled" or chatvars.words[3] == "disabled") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[3] == "enabled" then
				server.telnetDisabled = false
				conn:execute("UPDATE server SET telnetDisabled = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will try to stay connected to telnet even when in API mode.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will try to stay connected to telnet even when in API mode.")
				end
			else
				server.telnetDisabled = true
				conn:execute("UPDATE server SET telnetDisabled = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot won't keep trying to connect to telnet.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot won't keep trying to connect to telnet.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleTranslate()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}translate on (or off) {player name}"
			help[2] = "If the Google translate API is installed, the bot can automatically translate the players chat to english.\n"
			help[2] = "Note:  On hosted bots this feature is not installed so Google doesn't send me a large invoice."

			tmp.command = help[1]
			tmp.keywords = "on,off,translate,language"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "translate" and (chatvars.words[2] == "on" or chatvars.words[2] == "off") and chatvars.words[3] ~= nil) then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "translate" and (chatvars.words[2] == "on" or chatvars.words[2] == "off") and chatvars.words[3] ~= nil) then
			if chatvars.words[2] == "on" then
				pname = string.sub(chatvars.command, string.find(chatvars.command, " on ") + 4)
			else
				pname = string.sub(chatvars.command, string.find(chatvars.command, " off ") + 5)
			end

			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if chatvars.words[2] == "on" then
				if not isArchived then
					players[tmp.steam].translate = true
					conn:execute("UPDATE players SET translate = 1 WHERE steam = '" .. tmp.steam .. "'")
				else
					playersArchived[tmp.steam].translate = true
					conn:execute("UPDATE playersArchived SET translate = 1 WHERE steam = '" .. tmp.steam .. "'")
				end

				message("say [" .. server.chatColour .. "]Chat from player " .. playerName ..  " will be translated to English.[-]")
			else
				if not isArchived then
					players[tmp.steam].translate = false
					conn:execute("UPDATE players SET translate = 0 WHERE steam = '" .. tmp.steam .. "'")
				else
					playersArchived[tmp.steam].translate = false
					conn:execute("UPDATE playersArchived SET translate = 0 WHERE steam = '" .. tmp.steam .. "'")
				end

				message("say [" .. server.chatColour .. "]Chat from player " .. playerName ..  " will not be translated.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleWatchAlerts()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) watch alerts"
			help[2] = "Enable or disable ingame private messages about watched player inventory and base raiding. Alerts will still go to IRC."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,watch,alert,pm,irc"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "watch") or string.find(chatvars.command, "player") or string.find(chatvars.command, "new") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "watch" and chatvars.words[3] == "alerts" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.disableWatchAlerts = false
				conn:execute("UPDATE server SET disableWatchAlerts = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Alerts on the activities of watched players will be PM'ed to admins.[-]")
				else
					irc_chat(chatvars.ircAlias, "Alerts on the activities of watched players will be PM'ed to admins.")
				end
			else
				server.disableWatchAlerts = true
				conn:execute("UPDATE server SET disableWatchAlerts = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Watch alerts will go to IRC only.[-]")
				else
					irc_chat(chatvars.ircAlias, "Watch alerts will go to IRC only.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleWelcomeMessages()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) welcome messages"
			help[2] = "You can stop the bot greeting players when they join. This does not block alerts about mail, pending reboots or about being in timeout.\n"
			help[2] = "The welcome messages are enabled by default."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,welcome,messages,greeting"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "able") or string.find(chatvars.command, "welc") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and string.find(chatvars.words[2], "welc") and string.find(chatvars.words[3], "mess") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.noGreetingMessages = false
				conn:execute("UPDATE server SET noGreetingMessages = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will greet players when they join the server.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will greet players when they join the server.")
				end
			else
				server.noGreetingMessages = true
				conn:execute("UPDATE server SET noGreetingMessages = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will not be welcomed to the server by the bot. How rude![-]")
				else
					irc_chat(chatvars.ircAlias, "Players will not be welcomed to the server by the bot. How rude!")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnpauseReboot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}resume (or {#}unpause) reboot"
			help[2] = "Resume a paused reboot."

			tmp.command = help[1]
			tmp.keywords = "pause,resume,reboots,bot"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "unpause" or chatvars.words[1] == "unpaws" or chatvars.words[1] == "resume") and chatvars.words[2] == "reboot" and chatvars.words[3] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if botman.scheduledRestartPaused then
				if botman.scheduledRestartTimestamp then
					botman.scheduledRestartTimestamp = os.time() + botman.restartTimeRemaining
					botman.restartTimeRemaining = nil
				end

				botman.scheduledRestartPaused = false

				if chatvars.words[1] == "unpaws" then
					message("say [" .. server.chatColour .. "]The paws have been removed from the reboot countdown.[-]")
				else
					message("say [" .. server.chatColour .. "]The reboot countdown has resumed.[-]")
				end
			else
				if chatvars.words[1] == "unpaws" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There are no paws.[-]")
					else
						irc_chat(chatvars.ircAlias, "There are no paws.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The reboot is already resumed.[-]")
					else
						irc_chat(chatvars.ircAlias, "The reboot is already resumed.")
					end
				end

				botman.faultyChat = false
				return true
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_VisitMap()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}visitmap\n"
			help[1] = help[1] .. "Or {#}visitmap x1 z1 x2 z2\n"
			help[1] = help[1] .. "Or {#}visitmap range {distance}\n"
			help[1] = help[1] .. "Or {#}visitmap stop"
			help[2] = "Make the server explore the map while you hit up some zombie chicks.\n"
			help[2] = help[2] .. "If you add the optional word 'check' at the end of the command it will also check chunk density.\n"
			help[2] = help[2] .. "To visit the entire map do not include coordinates or a range."

			tmp.command = help[1]
			tmp.keywords = "visit,map,stop"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "visit") or string.find(chatvars.command, "map") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "visitmap" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if string.find(chatvars.command, "stop") then
				sendCommand("visitmap stop")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Stopping then visitmap command.[-]")
				else
					irc_chat(chatvars.ircAlias, "Stopping then visitmap command.")
				end

				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.check = ""

			if string.find(chatvars.command, "check") then
				tmp.check = "check"
			end

			if string.find(chatvars.command, "range") then
				if (chatvars.playername == "Server") then
					irc_chat(chatvars.ircAlias, "Range can only be used in-game.")

					botman.faultyChat = false
					return true
				end

				for i=2,chatvars.wordCount,1 do
					if chatvars.words[i] == "range" then
						tmp.range = tonumber(chatvars.words[i+1])
					end
				end
			end

			if chatvars.numberCount == 4 then
				-- doing visit map x1 z1 x2 z2
				tmp.x1 = chatvars.numbers[1]
				tmp.z1 = chatvars.numbers[2]
				tmp.x2 = chatvars.numbers[3]
				tmp.z2 = chatvars.numbers[4]
				tmp.range = nil
			else
				if tmp.range then
					-- doing a ranged area around the in-game player
					tmp.x1 = chatvars.intX - tmp.range
					tmp.z1 = chatvars.intZ + tmp.range
					tmp.x2 = chatvars.intX + tmp.range
					tmp.z2 = chatvars.intZ - tmp.range
				else
					-- doing the whole world.
					tmp.mapSize = math.floor(GamePrefs.WorldGenSize / 2)
					tmp.x1 = -tmp.mapSize
					tmp.z1 = tmp.mapSize
					tmp.x2 = tmp.mapSize
					tmp.z2 = -tmp.mapSize
				end
			end

			sendCommand(string.trim("visitmap " .. tmp.x1 .. " " .. tmp.z1 .. " " .. tmp.x2  .. " " .. tmp.z2 .. " " .. tmp.check))

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Sending the visitmap command to the server.[-]")
			else
				irc_chat(chatvars.ircAlias, "Sending the visitmap command to the server.")
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

if debug then dbug("debug server") end

	if botman.registerHelp then
		if debug then dbug("Registering help - server commands") end

		tmp.topicDescription = "Server commands mainly cover settings that change the nature of the server or turn features on or off that relate to the server."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Server Commands:")
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, tmp.topicDescription)
			irc_chat(chatvars.ircAlias, ".")
		end

		cursor,errorString = connSQL:execute("SELECT count(*) FROM helpTopics WHERE topic = '" .. tmp.topic .. "'")
		row = cursor:fetch({}, "a")
		rows = row["count(*)"]

		if rows == 0 then
			connSQL:execute("INSERT INTO helpTopics (topic, description) VALUES ('" .. tmp.topic .. "', '" .. connMEM:escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false, ""
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.words[3], "server") then
				botman.faultyChat = false
				return true, ""
			end
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and chatvars.words[1] ~= "help" and not botman.registerHelp then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Server Commands:")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "server")
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleTelnetDisabled()

	if result then
		if debug then dbug("debug cmd_ToggleTelnetDisabled triggered") end
		return result, "cmd_ToggleTelnetDisabled"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleTranslate()

	if result then
		if debug then dbug("debug cmd_ToggleTranslate triggered") end
		return result, "cmd_ToggleTranslate"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_Say()

	if result then
		if debug then dbug("debug cmd_Say triggered") end
		return result, "cmd_Say"
	end

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then
		if (not chatvars.isAdminHidden) then
			botman.faultyChat = false
			return false, ""
		end
	else
		if chatvars.ircid ~= "0" then
			if (not chatvars.isAdminHidden) then
				botman.faultyChat = false
				return false, ""
			end
		end
	end
	-- ##################################################################

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_CancelReboot()

	if result then
		if debug then dbug("debug cmd_CancelReboot triggered") end
		return result, "cmd_CancelReboot"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_JoinGameServer()

	if result then
		if debug then dbug("debug cmd_JoinGameServer triggered") end
		return result, "cmd_JoinGameServer"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_PauseReboot()

	if result then
		if debug then dbug("debug cmd_PauseReboot triggered") end
		return result, "cmd_PauseReboot"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_RunConsoleCommand()

	if result then
		if debug then dbug("debug cmd_RunConsoleCommand triggered") end
		return result, "cmd_RunConsoleCommand"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ScheduleServerReboot()

	if result then
		if debug then dbug("debug cmd_ScheduleServerReboot triggered") end
		return result, "cmd_ScheduleServerReboot"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetAccessOverride()

	if result then
		if debug then dbug("debug cmd_SetAccessOverride triggered") end
		return result, "cmd_SetAccessOverride"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetArchivePlayersThreshold()

	if result then
		if debug then dbug("debug cmd_SetArchivePlayersThreshold triggered") end
		return result, "cmd_SetArchivePlayersThreshold"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBailCost()

	if result then
		if debug then dbug("debug cmd_SetBailCost triggered") end
		return result, "cmd_SetBailCost"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetClearViewMOTD()

	if result then
		if debug then dbug("debug cmd_SetClearViewMOTD triggered") end
		return result, "cmd_SetClearViewMOTD"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetIdleKickTimer()

	if result then
		if debug then dbug("debug cmd_SetIdleKickTimer triggered") end
		return result, "cmd_SetIdleKickTimer"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetIRCChannels()

	if result then
		if debug then dbug("debug cmd_SetIRCChannels triggered") end
		return result, "cmd_SetIRCChannels"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetIRCNick()

	if result then
		if debug then dbug("debug cmd_SetIRCNick triggered") end
		return result, "cmd_SetIRCNick"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetIRCServer()

	if result then
		if debug then dbug("debug cmd_SetIRCServer triggered") end
		return result, "cmd_SetIRCServer"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMapSize()

	if result then
		if debug then dbug("debug cmd_SetMapSize triggered") end
		return result, "cmd_SetMapSize"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxAnimals()

	if result then
		if debug then dbug("debug cmd_SetMaxAnimals triggered") end
		return result, "cmd_SetMaxAnimals"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxHackerFlyingGroundHeight()

	if result then
		if debug then dbug("debug cmd_SetMaxHackerFlyingGroundHeight triggered") end
		return result, "cmd_SetMaxHackerFlyingGroundHeight"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxPing()

	if result then
		if debug then dbug("debug cmd_SetMaxPing triggered") end
		return result, "cmd_SetMaxPing"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxPlayers()

	if result then
		if debug then dbug("debug cmd_SetMaxPlayers triggered") end
		return result, "cmd_SetMaxPlayers"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxUptime()

	if result then
		if debug then dbug("debug cmd_SetMaxUptime triggered") end
		return result, "cmd_SetMaxUptime"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxZombies()

	if result then
		if debug then dbug("debug cmd_SetMaxZombies triggered") end
		return result, "cmd_SetMaxZombies"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetNewPlayerMaxLevel()

	if result then
		if debug then dbug("debug cmd_SetNewPlayerMaxLevel triggered") end
		return result, "cmd_SetNewPlayerMaxLevel"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetNewPlayerTimer()

	if result then
		if debug then dbug("debug cmd_SetNewPlayerTimer triggered") end
		return result, "cmd_SetNewPlayerTimer"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetOverstackLimit()

	if result then
		if debug then dbug("debug cmd_SetOverstackLimit triggered") end
		return result, "cmd_SetOverstackLimit"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetPingKickTarget()

	if result then
		if debug then dbug("debug cmd_SetPingKickTarget triggered") end
		return result, "cmd_SetPingKickTarget"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetPrisonTimer()

	if result then
		if debug then dbug("debug cmd_SetPrisonTimer triggered") end
		return result, "cmd_SetPrisonTimer"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetPVPCooldown()

	if result then
		if debug then dbug("debug cmd_SetPVPCooldown triggered") end
		return result, "cmd_SetPVPCooldown"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetPVPTempBanCooldown()

	if result then
		if debug then dbug("debug cmd_SetPVPTempBanCooldown triggered") end
		return result, "cmd_SetPVPTempBanCooldown"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetReservedSlots()

	if result then
		if debug then dbug("debug cmd_SetReservedSlots triggered") end
		return result, "cmd_SetReservedSlots"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetRollingAnnouncementTimer()

	if result then
		if debug then dbug("debug cmd_SetRollingAnnouncementTimer triggered") end
		return result, "cmd_SetRollingAnnouncementTimer"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetRules()

	if result then
		if debug then dbug("debug cmd_SetRules triggered") end
		return result, "cmd_SetRules"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerAPIKey()

	if result then
		if debug then dbug("debug cmd_SetServerAPIKey triggered") end
		return result, "cmd_SetServerAPIKey"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerVoteReward()

	if result then
		if debug then dbug("debug cmd_SetServerVoteReward triggered") end
		return result, "cmd_SetServerVoteReward"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerGroup()

	if result then
		if debug then dbug("debug cmd_SetServerGroup triggered") end
		return result, "cmd_SetServerGroup"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerIP()

	if result then
		if debug then dbug("debug cmd_SetServerIP triggered") end
		return result, "cmd_SetServerIP"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerRebootHour()

	if result then
		if debug then dbug("debug cmd_SetServerRebootHour triggered") end
		return result, "cmd_SetServerRebootHour"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerRebootMinute()

	if result then
		if debug then dbug("debug cmd_SetServerRebootMinute triggered") end
		return result, "cmd_SetServerRebootMinute"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerType()

	if result then
		if debug then dbug("debug cmd_SetServerType triggered") end
		return result, "cmd_SetServerType"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetupAllocsWebMap()

	if result then
		if debug then dbug("debug cmd_SetupAllocsWebMap triggered") end
		return result, "cmd_SetupAllocsWebMap"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWebPanelPort()

	if result then
		if debug then dbug("debug cmd_SetWebPanelPort triggered") end
		return result, "cmd_SetWebPanelPort"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWebsite()

	if result then
		if debug then dbug("debug cmd_SetWebsite triggered") end
		return result, "cmd_SetWebsite"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWelcomeMessage()

	if result then
		if debug then dbug("debug cmd_SetWelcomeMessage triggered") end
		return result, "cmd_SetWelcomeMessage"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_TestVoteReward()

	if result then
		if debug then dbug("debug cmd_TestVoteReward triggered") end
		return result, "cmd_TestVoteReward"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBadNames()

	if result then
		if debug then dbug("debug cmd_ToggleBadNames triggered") end
		return result, "cmd_ToggleBadNames"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBanVACBannedPlayers()

	if result then
		if debug then dbug("debug cmd_ToggleBanVACBannedPlayers triggered") end
		return result, "cmd_ToggleBanVACBannedPlayers"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleDespawnZombiesBeforeBloodMoon()

	if result then
		if debug then dbug("debug cmd_ToggleDespawnZombiesBeforeBloodMoon triggered") end
		return result, "cmd_ToggleDespawnZombiesBeforeBloodMoon"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleEntityScan()

	if result then
		if debug then dbug("debug cmd_ToggleEntityScan triggered") end
		return result, "cmd_ToggleEntityScan"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleErrorScan()

	if result then
		if debug then dbug("debug cmd_ToggleErrorScan triggered") end
		return result, "cmd_ToggleErrorScan"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleFamilySteamKeys()

	if result then
		if debug then dbug("debug cmd_ToggleFamilySteamKeys triggered") end
		return result, "cmd_ToggleFamilySteamKeys"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleHardcoreMode()

	if result then
		if debug then dbug("debug cmd_ToggleHardcoreMode triggered") end
		return result, "cmd_ToggleHardcoreMode"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIdleKick()

	if result then
		if debug then dbug("debug cmd_ToggleIdleKick triggered") end
		return result, "cmd_ToggleIdleKick"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIdleKickAnytime()

	if result then
		if debug then dbug("debug cmd_ToggleIdleKickAnytime triggered") end
		return result, "cmd_ToggleIdleKickAnytime"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIgnorePlayerFlying()

	if result then
		if debug then dbug("debug cmd_ToggleIgnorePlayerFlying triggered") end
		return result, "cmd_ToggleIgnorePlayerFlying"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIRCPrivate()

	if result then
		if debug then dbug("debug cmd_ToggleIRCPrivate triggered") end
		return result, "cmd_ToggleIRCPrivate"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleNoClipScan()

	if result then
		if debug then dbug("debug cmd_ToggleNoClipScan triggered") end
		return result, "cmd_ToggleNoClipScan"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleOverstackChecking()

	if result then
		if debug then dbug("debug cmd_ToggleOverstackChecking triggered") end
		return result, "cmd_ToggleOverstackChecking"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_TogglePVPRulesByCompass()

	if result then
		if debug then dbug("debug cmd_TogglePVPRulesByCompass triggered") end
		return result, "cmd_TogglePVPRulesByCompass"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleRapidRelogTempBan()

	if result then
		if debug then dbug("debug cmd_ToggleRapidRelogTempBan triggered") end
		return result, "cmd_ToggleRapidRelogTempBan"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleRegionPM()

	if result then
		if debug then dbug("debug cmd_ToggleRegionPM triggered") end
		return result, "cmd_ToggleRegionPM"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleServerReboots()

	if result then
		if debug then dbug("debug cmd_ToggleServerReboots triggered") end
		return result, "cmd_ToggleServerReboots"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleWatchAlerts()

	if result then
		if debug then dbug("debug cmd_ToggleWatchAlerts triggered") end
		return result, "cmd_ToggleWatchAlerts"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleWelcomeMessages()

	if result then
		if debug then dbug("debug cmd_ToggleWelcomeMessages triggered") end
		return result, "cmd_ToggleWelcomeMessages"
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnpauseReboot()

	if result then
		if debug then dbug("debug cmd_UnpauseReboot triggered") end
		return result, "cmd_UnpauseReboot"
	end

	if debug then dbug("debug server end of remote commands") end

	result = cmd_VisitMap()

	if result then
		if debug then dbug("debug cmd_VisitMap triggered") end
		return result, "cmd_VisitMap"
	end

	if debug then dbug("debug server end of remote commands") end

	if botman.registerHelp then
		if debug then dbug("Server commands help registered") end
	end

	if debug then dbug("debug server end") end

	-- can't touch dis
	if true then
		return result, ""
	end
end
