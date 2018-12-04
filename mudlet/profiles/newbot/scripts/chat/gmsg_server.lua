--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug, tmp, msg, result, help
local shortHelp = false
local skipHelp = false

-- enable debug to see where the code is stopping. Any error will be somewhere after the last successful debug line.
debug = false -- should be false unless testing

function gmsg_server()
	calledFunction = "gmsg_server"
	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## server command functions ##################

	local function cmd_CancelReboot()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}cancel reboot"
			help[2] = "Cancel a scheduled reboot.  You may not be able to stop a forced or automatically scheduled reboot but you can pause it instead."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "reboo,shut,canc,stop"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "cancel") or string.find(chatvars.command, "reboot"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "cancel" and chatvars.words[2] == "reboot" and chatvars.words[3] == nil) then
			if (chatvars.playername ~= "Server") then
				if chatvars.accessLevel > 1 then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is for admins only[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}join server {ip} port {telnet port} pass {telnet password}"
			help[2] = "Tell the bot to join a different game server."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "server,join,new,change,ip,port,pass"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "join") or string.find(chatvars.command, "server"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "join" and chatvars.words[2] == "server" and string.find(chatvars.command, "port") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}pause reboot"
			help[2] = "Pause a scheduled reboot.  It will stay paused until you unpause it or restart the bot."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "server,rebo,pause,resu"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pause") or string.find(chatvars.command, "reboot"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "pause" or chatvars.words[1] == "paws") and chatvars.words[2] == "reboot" and chatvars.words[3] == nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if botman.scheduledRestart == true and botman.scheduledRestartPaused == false then
				botman.scheduledRestartPaused = true
				restartTimeRemaining = botman.scheduledRestartTimestamp - os.time()

				if chatvars.words[1] == "paws" then
					message("say [" .. server.chatColour .. "]The reboot has been pawsed.[-]")
				else
					message("say [" .. server.chatColour .. "]The reboot has been paused.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RunConsoleCommand()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}run command {a console command}"
			help[2] = "Sometimes you need to make the bot run a specific console command.\n"
			help[2] = help[2] .. "This can be used to force the bot re-parse a list.  Only server owners can do this."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,run,comm,cons"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "run") or string.find(chatvars.command, "comm") or string.find(chatvars.command, "cons"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			tmp = string.sub(line, string.find(line, "command") + 8)
			sendCommand(tmp)
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Say()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}say{2 letter language code} {something you want translated}"
			help[2] = "If the translator utility is installed, the bot can translate from english what you say into the language you specify.\n"
			help[2] = help[2] .. "eg. {#}sayfr Hello.  The bot will say Smegz0r: Bonjour\n"
			help[2] = help[2] .. "Note: This uses Google and due to the number of bots I host, it is not installed on my servers as I don't want to risk an invoice from them.\n"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,run,comm,cons"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "say"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reboot\n"
			help[1] = help[1] .. " {#}reboot {n} minute (or hour) (optional: forced)\n"
			help[1] = help[1] .. " {#}reboot now"
			help[2] = "Schedule a timed or immediate server reboot.  The actual restart must be handled externally by something else.\n"
			help[2] = help[2] .. "Just before the reboot happens, the bot issues a save command. If you add forced, only a level 0 admin can stop the reboot.\n"
			help[2] = help[2] .. "Shutting down the bot will also cancel a reboot but any automatic (timed) reboots will reschedule if the server wasn't also restarted."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "server,rebo,now,time,sched"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if tonumber(chatvars.ircid) > 0 then
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					send("sa")
				else
					if (os.time() - botMaintenance.lastSA) > 30 then
						botMaintenance.lastSA = os.time()
						saveBotMaintenance()
						send("sa")
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
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetAccessOverride()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}override access {number from 99 to 4}"
			help[2] = "All players have an access level which governs what they can do.  You can override it for everyone to temporarily raise their access.\n"
			help[2] = help[2] .. "eg. {#}overide access 10 would make all players donors until you restore it.  To do that type {#}override access 99.  This is faster than giving individual players donor access if you just want to do a free donor weekend."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,acce,over,set"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "overr") or string.find(chatvars.command, "acc"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
						irc_chat(chatvars.ircAlias, "Do not set the access override lower than 3!")
					end

					botman.faultyChat = false
					return true
				end

				server.accessLevelOverride = chatvars.number
				conn:execute("UPDATE server SET accessLevelOverride = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player access levels have been over-ridden! Minimum access level is now " .. chatvars.number .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "Player access levels have been over-ridden! Minimum access level is now " .. chatvars.number .. ".")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetArchivePlayersThreshold()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set archive players day {number (days) default is 60}"
			help[2] = "The bot will archive players who haven't played in 60 days except for admins.  You can disable this feature by setting it to 0.\n"
			help[2] = help[2] .. "The bot will archive players at startup or if you use the command {#}archive players."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,set,arch,day,play,seen"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "arch") or string.find(chatvars.command, "play") or string.find(chatvars.command, "seen"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "archive" and chatvars.words[3] == "players" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))
				server.archivePlayersLastSeenDays = chatvars.number
				conn:execute("UPDATE server SET archivePlayersLastSeenDays = " .. chatvars.number)

				if chatvars.number == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not be archived.[-]")
					else
						irc_chat(chatvars.ircAlias, "Players will not be archived.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who are not admins and haven't played in " .. server.archivePlayersLastSeenDays .. " days will be archived when the bot starts up.  You can force it now with {#}archive players.[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If you have a lot of players it will make the bot unresponsive for a short time.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set bail {number}"
			help[2] = "Set how many " .. server.moneyPlural .. " it costs to bail out of prison.  To disable bail set it to zero (the default)"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,bail,prison,cost,amount,price"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bail") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "Bail is disabled on this server.  Players must be released by someone to get out of prison.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Players can release themselves from prison at a cost of " .. server.bailCost .. " " .. server.moneyPlural .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can release themselves from prison at a cost of " .. server.bailCost .. " " .. server.moneyPlural)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetClearViewMOTD()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}motd (to view it)\n"
			help[1] = help[1] .. " {#}motd (or {#}set motd) {your message here} (to set it)\n"
			help[1] = help[1] .. " {#}motd clear (to disable it)"
			help[2] = "Display the current message of the day.  If an admin types anything after {#}motd the typed text becomes the new MOTD.\n"
			help[2] = help[2] .. "To remove it type {#}motd clear"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,motd,mess,day"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "motd") or string.find(chatvars.command, "mess"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "motd") or (chatvars.words[1] == "set" and chatvars.words[2] == "motd") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[2] == nil then
				if server.MOTD == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]There is no MOTD set.[-]")
					else
						irc_chat(chatvars.ircAlias, "There is no MOTD set.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.MOTD .. "[-]")
					else
						irc_chat(chatvars.ircAlias, server.MOTD)
					end
				end
			else
				if chatvars.words[2] == "clear" then
					server.MOTD = nil
					conn:execute("UPDATE server SET MOTD = ''")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]MOTD has been cleared.[-]")
					else
						irc_chat(chatvars.ircAlias, "MOTD has been cleared.")
					end
				else
					server.MOTD = stripQuotes(string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "motd") + 5))
					conn:execute("UPDATE server SET MOTD = '" .. escape(server.MOTD) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New message of the day recorded.[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.MOTD .. "[-]")
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


	local function cmd_SetIRCChannels()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set irc main (or alerts or watch) {channel name without a # sign}"
			help[2] = "Change the bot's IRC channels."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,irc,web,chan,main,alert,watc"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, " irc")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "irc" and (chatvars.words[3] == "main" or chatvars.words[3] == "alerts" or chatvars.words[3] == "watch") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			pname = chatvars.words[4]

			if chatvars.words[3] == "main" then
				server.ircMain = "#" .. pname
				server.ircAlerts = "#" .. pname .. "_alerts"
				server.ircWatch = "#" .. pname .. "_watch"
				server.ircTracker = "#" .. pname .. "_tracker"

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The main irc channel is now " .. server.ircMain .. ", alerts is " ..  server.ircAlerts .. " and watch is " ..  server.ircWatch .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "The main irc channel is now " .. server.ircMain .. ", alerts is " ..  server.ircAlerts .. " and watch is " ..  server.ircWatch)
				end
			end

			if chatvars.words[3] == "alerts" then
				server.ircAlerts = "#" .. pname

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The alerts irc channel is now " .. server.ircAlerts .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "The alerts irc channel is now " .. server.ircAlerts)
				end
			end

			if chatvars.words[3] == "watch" then
				server.ircWatch = "#" .. pname

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The watch irc channel is now " .. server.ircWatch .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "The watch irc channel is now " .. server.ircWatch)
				end
			end

			conn:execute("UPDATE server SET ircMain = '" .. escape(server.ircMain) .. "', ircAlerts = '" .. escape(server.ircAlerts) .. "', ircWatch = '" .. escape(server.ircWatch) .. "', ircTracker = '" .. escape(server.ircTracker) .. "'")

			if botman.customMudlet then
				joinIRCServer()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetIRCNick()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set irc nick {bot name}"
			help[2] = "Change the bot's IRC nickname. Sometimes it can have a nick collision with itself and it gets an underscore appended to it."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,irc,nick,name"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, " irc")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "irc" and chatvars.words[3] == "nick" and chatvars.words[4] ~= "" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			pname = chatvars.wordsOld[4]

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot's irc nick is now " .. pname .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, "The bot's irc nick is now " .. pname)
			end

			ircSetNick(pname)
			server.ircBotName = pname
			conn:execute("UPDATE server SET ircBotname = '" .. escape(pname) .. "'")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetIRCServer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set irc server {IP or URL and optional port}"
			help[2] = "Use this command if you want players to know your IRC server's address."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,irc,server,port"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, " irc")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			tmp = string.sub(chatvars.command, string.find(chatvars.command, "server") + 7)
			tmp = string.trim(tmp)

			if tmp == nil or tmp == "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]A server name is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "A server name is required.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The IRC server is now at " .. tmp .. "[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set map size {number}"
			help[2] = "Set the maximum distance from 0,0 that players are allowed to travel. Any players already outside this limit will be teleported to 0,0 and may get stuck under the map.  They can relog.\n"
			help[2] = help[2] .. "Size is in metres (blocks) and be careful not to set it too small.  The default map size is 10000 but the bot's default is 20000.\n"
			help[2] = help[2] .. "Whatever size you set, donors will be able to travel 5km futher out so the true boundary is +5000."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,map,size,limit,bound"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, " map")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
	end


	local function cmd_SetMaxAnimals()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set max animals {number}"
			help[2] = "Change the server's max spawned animals."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,max,anim,enti"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max") or string.find(chatvars.command, "anim"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
						irc_chat(chatvars.ircAlias, chatvars.number .. " is too high. Set a lower limit.")
					end

					botman.faultyChat = false
					return true
				end

				sendCommand("sg MaxSpawnedAnimals " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Max spawned animals is now " .. chatvars.number .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Max spawned animals is now " .. chatvars.number)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxPing()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set (or clear) max ping {number}"
			help[2] = "To kick high ping players set a max ping.  It will only be applied to new players. You can also whitelist a new player to make them exempt.\n"
			help[2] = help[2] .. "The bot doesn't immediately kick for high ping, it samples ping over 30 seconds and will only kick for a sustained high ping."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,max,ping,kick"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ping"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "Ping kicking is disabled.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				if tonumber(chatvars.number) > -1 and tonumber(chatvars.number) < 100 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. chatvars.number .. " is quite low. Enter a number > 99[-]")
					else
						irc_chat(chatvars.ircAlias, chatvars.number .. " is quite low. Enter a number > 99")
					end
				else
					server.pingKick = chatvars.number
					conn:execute("UPDATE server SET pingKick = " .. chatvars.number)

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players with a ping above " .. chatvars.number .. " will be kicked from the server.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set max players {number}"
			help[2] = "Change the server's max players. Admins can always join using the automated reserved slots feature."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,max,play"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Max players is now " .. chatvars.number .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Max players is now " .. chatvars.number)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxUptime()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set max uptime {number}\n"
			help[1] = help[1] .. " {#}max uptime (to see it)"
			help[2] = "Set how long (in hours) that the server can be running before the bot schedules a reboot.  The bot will always add 15 minutes as the reboot is only scheduled at that time."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,max,upt"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "max" and chatvars.words[2] == "uptime" and chatvars.words[3] == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Max server uptime is " .. server.maxServerUptime .. " hours.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Change it with " .. server.commandPrefix .. "set max uptime {hours}[-]")
			else
				irc_chat(chatvars.ircAlias, "Max server uptime is " .. server.maxServerUptime .. " hours.")
				irc_chat(chatvars.ircAlias, "Change it with " .. server.commandPrefix .. "set max uptime {hours}")
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
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "I will reboot the server when the server has been running " .. chatvars.number .. " hours.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxZombies()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set max zombies {number}"
			help[2] = "Change the server's max spawned zombies."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,max,zed,zom"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, " max") or string.find(chatvars.command, "zom"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
						irc_chat(chatvars.ircAlias, chatvars.number .. " is too high. Set a lower limit.")
					end

					botman.faultyChat = false
					return true
				end

				sendCommand("sg MaxSpawnedZombies " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Max spawned zombies is now " .. chatvars.number .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Max spawned zombies is now " .. chatvars.number)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetNewPlayerMaxLevel()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set new player max level {number} (game level)"
			help[2] = "By default a new player is automatically upgraded to a regular player once they pass level 9.\n"
			help[2] = help[2] .. "Use this command to change it to a different player level."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,new,play,max,level"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, " level") or string.find(chatvars.command, " play"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.command == "new player max level" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players stop being new after level " .. server.newPlayerMaxLevel .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, "New players stop being new after level " .. server.newPlayerMaxLevel)
			end

			botman.faultyChat = false
			return true
		end

		if string.find(chatvars.command, "new player max level") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.newPlayerMaxLevel = chatvars.number
				conn:execute("UPDATE server SET newPlayerMaxLevel = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players stop being new after level " .. chatvars.number .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "New players stop being new after level " .. chatvars.number)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetNewPlayerTimer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set new player timer {number} (in minutes)\n"
			help[1] = help[1] .. " {#}new player timer (to see it)"
			help[2] = "By default a new player is treated differently from regulars and has some restrictions placed on them mainly concerning inventory.\n"
			help[2] = help[2] .. "Set it to 0 to disable this feature."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,new,play,time"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, " time") or string.find(chatvars.command, " play"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "new" and chatvars.words[2] == "player" and chatvars.words[3] == "timer" and chatvars.words[4] == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players stop being new after " .. server.newPlayerTimer .. " minutes total play time.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Change it with " .. server.commandPrefix .. "set new player timer {number} (in minutes)[-]")
			else
				irc_chat(chatvars.ircAlias, "New players stop being new after " .. server.newPlayerTimer .. " minutes total play time.")
				irc_chat(chatvars.ircAlias, "Change it with cmd " .. server.commandPrefix .. "set new player timer {number} (in minutes)")
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "New players stop being new after " .. chatvars.number .. " minutes total play time.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetOverstackLimit()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set overstack {number} (default 1000)"
			help[2] = "Sets the maximum stack size before the bot will warn a player about overstacking.  Usually the bot learns this directly from the server as stack sizes are exceeded."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,over,stack,time"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "overs"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			server.overstackThreshold = chatvars.number
			conn:execute("UPDATE server SET overstackThreshold = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If no overstack limit is recorded, the minimum stack size to trigger an overstack warning is " .. server.overstackThreshold .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, "If no overstack limit is recorded, the minimum stack size to trigger an overstack warning is " .. server.overstackThreshold .. ".")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetPingKickTarget()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set ping kick target {new or all}"
			help[2] = "By default if a ping kick is set it only applies to new players. Set to all to have it applied to everyone.\n"
			help[2] = help[2] .. "Note: Does not apply to exempt players which includes admins, donors and individuals that have been bot whitelisted."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,ping,kick,targ"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ping"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "ping" and chatvars.words[3] == "kick" and chatvars.words[4] == "target" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[5] == "new" then
				server.pingKickTarget = "new"
				conn:execute("UPDATE server SET pingKickTarget = 'new'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Ping kicks will only happen to new players.[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Anyone except staff, donors and bot whitelisted players can be ping kicked.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set prison timer {number} (in minutes)"
			help[2] = "Set how long someone stays in prison when jailed by the bot.  To not have a time limit, set this to 0 which is the default."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,prison,time"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "time") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "prison" and chatvars.words[3] == "timer" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "Prisoners must be released by someone to get out of prison. There is no time limit.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Prisoners will be automatically released from prison after " .. server.maxPrisonTime .. " minutes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Prisoners will be automatically released from prison after " .. server.maxPrisonTime .. " minutes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetPVPCooldown()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set pvp cooldown {seconds}"
			help[2] = "Set how long after a pvp kill before the player can use teleport commands again."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,pvp,time,cool,delay"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(chatvars.number) -- eliminate the negative

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Players must wait %s seconds after killing a player before they can teleport.[-]", chatvars.playerid, server.chatColour, chatvars.number))
				else
					irc_chat(chatvars.ircAlias, string.format("Players must wait %s seconds after killing a player before they can teleport.", chatvars.number))
				end

				server.pvpTeleportCooldown = chatvars.number
				conn:execute("UPDATE server SET pvpTeleportCooldown = " .. chatvars.number)
			else
				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]A number (seconds) is required.  Set to 0 to have no timer.[-]", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "A number (seconds) is required.  Set to 0 to have no timer.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetReservedSlots()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set reserved slots {number of slots}"
			help[2] = "You can have a number of server slots reserved for admins and selected players.\n"
			help[2] = help[2] .. "Anyone can join but if the server becomes full, players who aren't staff or allowed to reserve a slot will be randomly selected and kicked if an admin or authorised player joins.\n"
			help[2] = help[2] .. "To disable, set reserved slots to 0."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,reser,slot"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reser") or string.find(chatvars.command, "slot") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number ~= nil then
				if math.abs(chatvars.number) > server.maxPlayers then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Reserved slots can't be more than max players.[-]")
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

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. chatvars.number .. " slots are now reserved slots.[-]")
				else
					irc_chat(chatvars.ircAlias, chatvars.number .. " slots are now reserved slots.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You didn't give me a number.[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]eg " .. server.commandPrefix .. "set reserved slots 5[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set rolling delay {minutes}"
			help[2] = "Set the delay in minutes between rolling announcements."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,roll,anno,time,delay"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "anno") or string.find(chatvars.command, "set") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "rolling" and chatvars.words[3] == "delay" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				conn:execute("UPDATE timedEvents SET delayMinutes = " .. chatvars.number .. " WHERE timer = 'announcements'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A rolling announcement will display every " .. chatvars.number .. " minutes when players are on.[-]")
				else
					irc_chat(chatvars.ircAlias, "A rolling announcement will display every " .. chatvars.number .. " minutes when players are on.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetRules()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set rules {new rules}"
			help[2] = "Set the server rules.  You can use supported bbcode tags, but only when setting the rules from IRC.  Each tag must be closed with this tag [-] or colours will bleed into the next line.\n"
			help[2] = help[2] .. "To display the rules type {#}rules"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,rule"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rules") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
				irc_chat(chatvars.ircAlias, "New rules recorded.")
				irc_chat(chatvars.ircAlias, server.rules)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerAPIKey()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set server api {api key from 7daystodie-servers.com}"
			help[2] = "Your API key is not recorded in logs or the databases and no bot command reports it.  It is used to determine if a player has voted for your server today.\n"
			help[2] = help[2] .. "While the bot takes precautions to keep your API key a secret, you should be careful not to type it anywhere in public.  The safest place to give it to the bot is in private chat on IRC or on the bot's web interface when that is available."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,api,key"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "api") or string.find(chatvars.command, "set") or string.find(chatvars.command, "server"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "server" and chatvars.words[3] == "api" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]API key required. Get it from 7daystodie-servers.com.[-]")
				else
					irc_chat(chatvars.ircAlias, "API key required. Get it from 7daystodie-servers.com.")
				end

				botman.faultyChat = false
				return true
			end

			serverAPI = chatvars.wordsOld[4]
			writeAPI()

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If you have enabled voting, players will receive a reward item for voting for your server once per day.[-]")
			else
				irc_chat(chatvars.ircAlias, "If you have enabled voting, players will receive a reward item for voting for your server once per day.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerGroup()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set server group {group name} (one word)"
			help[2] = "This is used by the bots database which could be a cloud database.  It is used to identify this bot as belonging to a group if you have more than one server.  You do not need to set this."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,server,group"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "serv") or string.find(chatvars.command, "group"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "Group name required.  One word, no spaces.")
				end

				botman.faultyChat = false
				return true
			else
				server.serverGroup = tmp.group
				conn:execute("UPDATE server SET serverGroup = '" .. escape(tmp.group) .. "'")

				if botman.db2Connected then
					-- update server in bots db
					connBots:execute("UPDATE servers SET serverGroup = '" .. escape(tmp.group) .. "' WHERE serverName = '" .. escape(server.serverName) .. "'")
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This server is now a member of " .. tmp.group .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "This server is now a member of " .. tmp.group .. ".")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerIP()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set server ip {IP of your 7 Days to Die server}"
			help[2] = "The bot is unable to read the IP from its own profile for the server so enter it here.  It will display in the {#}info command and be used if a few other places."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,server,ip"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "server") or string.find(chatvars.command, " ip"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "server" and chatvars.words[3] == "ip" and chatvars.words[5] == nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			tmp = chatvars.words[4]

			if tmp == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]The server ip is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "The server ip is required.")
				end
			else
				server.IP = tmp
				conn:execute("UPDATE server SET IP = '" .. escape(tmp) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The server ip is now " .. tmp .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "The server ip is now " .. tmp)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerRebootHour()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set reboot hour {0 to 23}"
			help[2] = "Reboot the server when the server time matches the hour (24 hour time).  To disable clock based reboots set this to -1 or don't enter a number."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,server,reboo,hour,time"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reboot") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "reboot" and chatvars.words[3] == "hour" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You have disabled clock based reboots.[-]")
				else
					irc_chat(chatvars.ircAlias, "You have disabled clock based reboots.")
				end
			else
				server.rebootHour = chatvars.number
				conn:execute("UPDATE server SET rebootHour = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetServerRebootMinute()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set reboot minute {0 to 59}"
			help[2] = "Reboot the server when the server time matches the hour and minute (24 hour time).  To disable clock based reboots use {#}set reboot hour (without a number)"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,server,reboo,mini,time"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reboot") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "reboot" and chatvars.words[3] == "minute" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "A number from 0 to 59 was expected.")
				end
			else
				server.rebootMinute = chatvars.number
				conn:execute("UPDATE server SET rebootMinute = " .. chatvars.number)

				if tonumber(server.rebootHour) > -1 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "A reboot will be scheduled when the server time is " .. server.rebootHour .. ":" .. string.format("%02d", server.rebootMinute) .. ".")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Now set the reboot hour with " .. server.commandPrefix .. "set reboot hour {0-23}.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set server pve (or pvp, creative or contest)"
			help[2] = "Set the entire server to be PVE, PVP, Creative or Contest.\n"
			help[2] = help[2] .. "Contest mode is not implemented yet and all setting it creative does is stop the bot pestering players about their inventory."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,server,pvp,pve,crea"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "server") or string.find(chatvars.command, "pve") or string.find(chatvars.command, "pvp"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set" and chatvars.words[2] == "server") and chatvars.words[3] ~= nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
	end


	local function cmd_SetupAllocsWebMap()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}setup map"
			help[2] = "Optional extras after setup map: no hostiles, no animals, show players, show claims, show inventory\n"
			help[2] = help[2] .. "eg. {#}setup map no hostiles no animals show players show claims show inventory\n"
			help[2] = help[2] .. "The bot can fix your server map's permissions with some nice settings.  If you use this command, the following permissions are set:\n"
			help[2] = help[2] .. "web.map 2000\n"
			help[2] = help[2] .. "webapi.getlandclaims 1000\n"
			help[2] = help[2] .. "webapi.viewallplayers 2\n"
			help[2] = help[2] .. "webapi.viewallclaims 2\n"
			help[2] = help[2] .. "webapi.getplayerinventory 2\n"
			help[2] = help[2] .. "webapi.getplayerslocation 2\n"
			help[2] = help[2] .. "webapi.getplayersOnline 2000\n"
			help[2] = help[2] .. "webapi.getstats 2000\n"
			help[2] = help[2] .. "webapi.gethostilelocation 2000\n"
			help[2] = help[2] .. "webapi.getanimalslocation 2000\n"
			help[2] = help[2] .. "If setting no hostiles and/or no animals:\n"
			help[2] = help[2] .. "webapi.gethostilelocation 2\n"
			help[2] = help[2] .. "webapi.getanimalslocation 2\n"
			help[2] = help[2] .. "If setting show players, show claims, show inventory:\n"
			help[2] = help[2] .. "webapi.viewallplayers 2000\n"
			help[2] = help[2] .. "webapi.viewallclaims 2000\n"
			help[2] = help[2] .. "webapi.getplayerinventory 2000"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,map,perm"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "map"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			sendCommand("webpermission add web.map 2000")
			sendCommand("webpermission add webapi.getplayersOnline 2000")
			sendCommand("webpermission add webapi.getstats 2000")
			sendCommand("webpermission add webapi.getlandclaims 1000")

			if string.find(chatvars.command, "no hostiles") then
				sendCommand("webpermission add webapi.gethostilelocation 2")
			else
				sendCommand("webpermission add webapi.gethostilelocation 2000")
			end

			if string.find(chatvars.command, "no animals") then
				sendCommand("webpermission add webapi.getanimalslocation 2")
			else
				sendCommand("webpermission add webapi.getanimalslocation 2000")
			end

			if string.find(chatvars.command, "show players") then
				sendCommand("webpermission add webapi.viewallplayers 2000")
				irc_chat(chatvars.ircAlias, "webapi.getplayerslocation 2000")
			else
				sendCommand("webpermission add webapi.viewallplayers 2")
				irc_chat(chatvars.ircAlias, "webapi.getplayerslocation 2")
			end

			if string.find(chatvars.command, "show claims") then
				sendCommand("webpermission add webapi.viewallclaims 2000")
			else
				sendCommand("webpermission add webapi.viewallclaims 2")
			end

			if string.find(chatvars.command, "show inventory") then
				sendCommand("webpermission add webapi.getplayerinventory 2000")
			else
				sendCommand("webpermission add webapi.getplayerinventory 2")
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The map permissions have been set.[-]")
			else
				irc_chat(chatvars.ircAlias, "The map permissions have been set.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetWebPanelPort() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set web panel port {port of server's control panel/web panel}\n"
			help[1] = help[1] .. "or {#}set api port {number}"
			help[2] = "The bot needs to be told the port for Alloc's web map. If you give it the wrong port and API support is enabled or you enable that later, the bot will try that port and the ports +/- 2 above and below it."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,web,port"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "web"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set" and (chatvars.words[2] == "web" or chatvars.words[2] == "control") and chatvars.words[3] == "panel" and chatvars.words[4] == "port") or (chatvars.words[1] == "set" and chatvars.words[2] == "api" and chatvars.words[3] == "port") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Port number between 1 and 65535 expected.[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Valid ports range from 1 to 65535.[-]")
				else
					irc_chat(chatvars.ircAlias, "Valid ports range from 1 to 65535.")
				end

				botman.faultyChat = false
				return true
			end

			if server.useAllocsWebAPI then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The web API will now be re-tested because the port has changed.[-]")
				else
					irc_chat(chatvars.ircAlias, "The web API will now be re-tested because the port has changed.")
				end
			end

			server.webPanelPort = chatvars.number
			botman.oldAPIPort = server.webPanelPort
			botman.testAPIPort = nil
			conn:execute("UPDATE server SET webPanelPort = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You set the web panel port to " .. chatvars.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "You set the web panel port to " .. chatvars.number)
			end

			if server.useAllocsWebAPI then
				-- verify that the web API is working for us
				tempTimer( 2, [[message("pm APItest \"test\"")]] )
				tempTimer( 5, [[checkAPIWorking()]] )
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetWebsite()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set website {your website or steam group}"
			help[2] = "Tell the bot the URL of your website or steam group so your players can ask for it."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,web,url"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "web"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set welcome message {your message here}\n"
			help[1] = help[1] .. " {#}clear welcome message"
			help[2] = "You can set a custom welcome message that will override the default greeting message when a player joins."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,welc,mess"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "welc"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New welcome message " .. msg .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "New welcome message " .. msg)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBadNames()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}allow/disallow/kick bad names"
			help[2] = "Auto-kick players with numeric names or names that contain no letters such as ascii art crap.\n"
			help[2] = help[2] .. "They will see a kick message asking them to change their name."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "allow,bad,name,kick"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bad") or string.find(chatvars.command, "name"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow" or chatvars.words[1] == "kick") and chatvars.words[2] == "bad" and chatvars.words[3] == "names" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "allow" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players with names that have no letters can play here.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players with names that have no letters can play here.")
				end

				server.allowNumericNames = true
				server.allowGarbageNames = true
				conn:execute("UPDATE server SET allowNumericNames = 1, allowGarbageNames = 1")
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will kick players with names that have no letters.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable vac (disable is the default)"
			help[2] = "If a player has any VAC bans you can auto-ban them or allow them in.\n"
			help[2] = help[2] .. "Each time they join, admins will be alerted to their VAC ban. To stop that, add the them to the bot's whitelist."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,vac,ban,alert"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ban") or string.find(chatvars.command, "vac"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "vac" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "enable" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players with VAC bans can play here.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players with VAC bans can play here.")
				end

				server.banVACBannedPlayers = false
				conn:execute("UPDATE server SET banVACBannedPlayers = 0")
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players with VAC bans will be banned from the server unless they are staff or whitelisted.[-]")
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


	local function cmd_ToggleCBSMFriendly()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set cbsm friendly (the default)\n"
			help[1] = help[1] .. " {#}set cbsm unfriendly (or anything other than the word friendly such as die die die)"
			help[2] = "If set to friendly, the bot will automatically switch from / commands to using the ! since CBSM uses the /\n"
			help[2] = help[2] .. "Set to anything else and the bot will use / commands whether CBSM is present or not."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,cbsm"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "cbsm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "cbsm" and chatvars.words[3] ~= nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "Commands will automatically remap from / to = when CBSM is detected.")
				end
			else
				server.CBSMFriendly = false
				server.commandPrefix = "/"
				conn:execute("UPDATE server SET CBSMFriendly = 0, commandPrefix = '/'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Commands will continue to expect a / with CBSM present.[-]")
				else
					irc_chat(chatvars.ircAlias, "Commands will continue to expect a / with CBSM present.")
				end

				message("say [" .. server.chatColour .. "]Commands now begin with a " .. server.commandPrefix .. "  To use commands such as who type " .. server.commandPrefix .. "who[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleDespawnZombiesBeforeBloodMoon()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}remove zombies before bloodmoon\n"
			help[1] = help[1] .. " {#}leave zombies before bloodmoon\n"
			help[2] = "If you have Stompy's BC mod, the bot can despawn all zombies server wide a few minutes before bloodmoon starts.  It may trigger more than once.\n"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "blood,horde,remo,desp"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "remov") or string.find(chatvars.command, "zomb"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "remove" or chatvars.words[1] == "leave") and chatvars.words[2] == "zombies" and chatvars.words[3] == "before" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "remove" then
				server.despawnZombiesBeforeBloodMoon = true
				conn:execute("UPDATE server SET despawnZombiesBeforeBloodMoon = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]All zombies will despawn one or more times during 9pm before bloodmoon begins.[-]")
				else
					irc_chat(chatvars.ircAlias, "All zombies will despawn one or more times during 9pm before bloodmoon begins.")
				end
			else
				server.despawnZombiesBeforeBloodMoon = true
				conn:execute("UPDATE server SET despawnZombiesBeforeBloodMoon = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Zombies will not be despawned before bloodmoon begins.[-]")
				else
					irc_chat(chatvars.ircAlias, "Zombies will not be despawned before bloodmoon begins.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleEntityScan()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable entity scan (disabled by default)"
			help[2] = "Scan for entities server wide every 30 seconds.\n"
			help[2] = help[2] .. "The resulting list is copied to the entities Lua table where it can be further processed for other bot features."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,scan,enti"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "scan") or string.find(chatvars.command, "ent"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "I will scan entities every 30 seconds.")
				end
			else
				server.scanEntities = false
				conn:execute("UPDATE server SET scanEntities = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]I will not scan for entities.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will not scan for entities.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleErrorScan()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable error scan (disabled by default)"
			help[2] = "The server can automatically scan for and fix some errors using console commands if you have Coppi's mod or djkrose's scripting mod installed.\n"
			help[2] = help[2] .. "You can disable the scan if you suspect it is creating lag."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,scan,err"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "scan") or string.find(chatvars.command, "err") or string.find(chatvars.command, "fix"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "I will scan the server for errors.")
				end
			else
				server.scanErrors = false
				conn:execute("UPDATE server SET scanErrors = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]I will not scan for errors.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will not scan for errors.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleHardcoreMode()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable hardcore mode"
			help[2] = "Allow players to use bot commands.  This is the default.\n"
			help[2] = help[2] .. "Players can still talk to the bot and use info commands such as {#}rules."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,hard,mode,comm"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hard") or string.find(chatvars.command, "mode") or string.find(chatvars.command, "server"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "hardcore" and chatvars.words[3] == "mode" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "disable" then
				server.hardcore = false
				conn:execute("UPDATE server SET hardcore = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can command the bot.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can command the bot.")
				end
			else
				server.hardcore = true
				conn:execute("UPDATE server SET hardcore = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can only talk to the bot and do basic info commands.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can only talk to the bot and do basic info commands.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIdleKick()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable idle kick (disabled is default)"
			help[2] = "When the server is full, if idle kick is on players will get kick warnings for 15 minutes of no movement then they get kicked."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,idle,kick"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "kick"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "idle" and chatvars.words[3] == "kick" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "enable" then
				server.idleKick = true
				conn:execute("UPDATE server SET idleKick = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]When the server is full, idling players will get kick warnings for 15 minutes then kicked if they don't move.[-]")
				else
					irc_chat(chatvars.ircAlias, "When the server is full, idling players will get kick warnings for 15 minutes then kicked if they don't move.")
				end
			else
				server.idleKick = false
				conn:execute("UPDATE server SET idleKick = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not be kicked for idling on the server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will not be kicked for idling on the server.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIgnorePlayerFlying()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}allow/disallow flying"
			help[2] = "Toggle the bot's player flying detection.  You would want to do this if players can use debug mode on your server."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "allow,fly"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "fly") or string.find(chatvars.command, "hack") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow") and chatvars.words[2] == "flying" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "allow" then
				server.playersCanFly = true
				conn:execute("UPDATE server SET playersCanFly = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players are allowed to fly.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players are allowed to fly.")
				end
			else
				server.playersCanFly = false
				conn:execute("UPDATE server SET playersCanFly = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will be temp banned for flying.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will be temp banned for flying.")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIRCPrivate()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set irc private/public"
			help[2] = "If IRC is private, the bot won't share the url or info with players and players can't invite anyone to irc using the invite command.\n"
			help[2] = help[2] .. "When public, players can find the IRC info with {#}help irc and they can create irc invites for themselves and others."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,irc,pub,priv"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "irc") or string.find(chatvars.command, "pub") or string.find(chatvars.command, "priv"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "irc" and (chatvars.words[3] == "public" or chatvars.words[3] == "private") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[3] == "public" then
				server.ircPrivate = false
				conn:execute("UPDATE server SET ircPrivate = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can see the IRC server info and can create IRC invites.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can see the IRC server info and can create IRC invites.")
				end
			else
				server.ircPrivate = true
				conn:execute("UPDATE server SET ircPrivate = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not see the IRC server info and cannot create IRC invites.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will not see the IRC server info and cannot create IRC invites.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleNoClipScan()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable noclip scan (the default)"
			help[2] = "Using Coppi's mod version 2.5+ you can detect players that are noclipping under the map.\n"
			help[2] = help[2] .. "It can false flag but it is still a useful early warning of a possible hacker.  The bot will ban a player found clipping a lot for one week."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,clip,scan"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "scan") or string.find(chatvars.command, "clip") or string.find(chatvars.command, "fly"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "noclip" and chatvars.words[3] == "scan" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "I will scan for noclipping players and report them to IRC.")
				end
			else
				server.scanNoclip = false
				conn:execute("UPDATE server SET scanNoclip = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]I will not scan for noclipping players.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will not scan for noclipping players.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleOverstackChecking()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}allow/disallow overstack or {#}enable/disable overstack"
			help[2] = "By default the bot reads overstack warnings coming from the server to learn what the stack limits are and it will pester players with excessive stack sizes and can send them to timeout for non-compliance."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,allow,over,stack"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "overs"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow" or chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and string.find(chatvars.words[2], "overstack") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "allow" or chatvars.words[1] == "enable" then
				server.allowOverstacking = true
				conn:execute("UPDATE server SET allowOverstacking = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will ignore overstacking.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will ignore overstacking.")
				end
			else
				server.allowOverstacking = false
				conn:execute("UPDATE server SET allowOverstacking = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will monitor stack sizes, warn and alert for overstacking.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will monitor stack sizes, warn and alert for overstacking.")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TogglePVPRulesByCompass()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}northeast pve/pvp\n"
			help[1] = help[1] .. " {#}northeast pve/pvp\n"
			help[1] = help[1] .. " {#}northwest pve/pvp\n"
			help[1] = help[1] .. " {#}southeast pve/pvp\n"
			help[1] = help[1] .. " {#}southwest pve/pvp\n"
			help[1] = help[1] .. " {#}north pve/pvp\n"
			help[1] = help[1] .. " {#}south pve/pvp\n"
			help[1] = help[1] .. " {#}east pve/pvp\n"
			help[1] = help[1] .. " {#}west pve/pvp"
			help[2] = "Make northeast/northwest/southeast/southwest/north/south/east/west of 0,0 PVE or PVP."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,pvp,pve,north,south,east,west"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "northeast" or chatvars.words[1] == "northwest" or chatvars.words[1] == "southeast" or chatvars.words[1] == "southwest" or chatvars.words[1] == "north" or chatvars.words[1] == "south" or chatvars.words[1] == "east" or chatvars.words[1] == "west") and chatvars.words[2] ~= nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[2] ~= "pvp" and chatvars.words[2] ~= "pve" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Command expects pvp or pve as 2nd part eg " .. server.commandPrefix .. "northeast pvp.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}allow/disallow rapid relog"
			help[2] = "New players who want to cheat often relog rapidly in order to spawn lots of items into the server using cheats or bugs.\n"
			help[2] = help[2] .. "If enabled, the bot will temp ban (10 minutes) players caught relogging several times in short order."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "allow,rapid,relog,log,join"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "relog") or string.find(chatvars.command, "allow"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow") and chatvars.words[2] == "rapid" and string.find(chatvars.command, "relog") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "allow"	then
				server.allowRapidRelogging = true
				conn:execute("UPDATE server SET allowRapidRelogging = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will do nothing about new players relogging multiple times rapidly.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will do nothing about new players relogging multiple times rapidly.")
				end
			else
				server.allowRapidRelogging = false
				conn:execute("UPDATE server SET allowRapidRelogging = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players relogging a lot in a short time will be banned for 10 minutes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players relogging a lot in a short time will be banned for 10 minutes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleRegionPM()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable region pm"
			help[2] = "A PM for admins that tells them the region name when they move to a new region."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,region,pm"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "region") or string.find(chatvars.command, " pm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "region" and chatvars.words[3] == "pm" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "enable" then
				server.enableRegionPM = true
				conn:execute("UPDATE server SET enableRegionPM = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The current region will be PM'ed to admins.[-]")
				else
					irc_chat(chatvars.ircAlias, "The current region will be PM'ed to admins.")
				end
			else
				server.enableRegionPM = false
				conn:execute("UPDATE server SET enableRegionPM = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The current region will not be PM'ed.[-]")
				else
					irc_chat(chatvars.ircAlias, "The current region will not be PM'ed.")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleServerReboots()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or disable) reboot"
			help[2] = "By default the bot does not manage server reboots.\n"
			help[2] = help[2] .. "See also {#}set max uptime (default 12 hours)"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,rebo,rest,shut,start,stop"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "enable" then
				server.allowReboot = true
				conn:execute("UPDATE server SET allowReboot = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will automatically reboot the server as needed.[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will not reboot the server.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will not reboot the server.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleTranslate()
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}translate on/off {player name}"
			help[2] = "If the Google translate API is installed, the bot can automatically translate the players chat to english."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "on,off,trans,lang"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "translate" and (chatvars.words[2] == "on" or chatvars.words[2] == "off") and chatvars.words[3] ~= nil) then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "translate" and (chatvars.words[2] == "on" or chatvars.words[2] == "off") and chatvars.words[3] ~= nil) then
			if chatvars.words[2] == "on" then
				pname = string.sub(chatvars.command, string.find(chatvars.command, " on ") + 4)
			else
				pname = string.sub(chatvars.command, string.find(chatvars.command, " off ") + 5)
			end

			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if chatvars.words[2] == "on" then
				if not isArchived then
					players[id].translate = true
					conn:execute("UPDATE players SET translate = 1 WHERE steam = " .. id)
				else
					playersArchived[id].translate = true
					conn:execute("UPDATE playersArchived SET translate = 1 WHERE steam = " .. id)
				end

				message("say [" .. server.chatColour .. "]Chat from player " .. playerName ..  " will be translated to English.[-]")
			else
				if not isArchived then
					players[id].translate = false
					conn:execute("UPDATE players SET translate = 0 WHERE steam = " .. id)
				else
					playersArchived[id].translate = false
					conn:execute("UPDATE playersArchived SET translate = 0 WHERE steam = " .. id)
				end

				message("say [" .. server.chatColour .. "]Chat from player " .. playerName ..  " will not be translated.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleWatchAlerts()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}disable/enable watch alerts"
			help[2] = "Enable or disable ingame private messages about watched player inventory and base raiding. Alerts will still go to IRC."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,watch,alert,pm,irc"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "watch") or string.find(chatvars.command, "player") or string.find(chatvars.command, "new"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "watch" and chatvars.words[3] == "alerts" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "enable" then
				server.disableWatchAlerts = false
				conn:execute("UPDATE server SET disableWatchAlerts = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Alerts on the activities of watched players will be PM'ed to admins.[-]")
				else
					irc_chat(chatvars.ircAlias, "Alerts on the activities of watched players will be PM'ed to admins.")
				end
			else
				server.disableWatchAlerts = true
				conn:execute("UPDATE server SET disableWatchAlerts = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Watch alerts will go to IRC only.[-]")
				else
					irc_chat(chatvars.ircAlias, "Watch alerts will go to IRC only.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnpauseReboot()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}resume/unpause reboot"
			help[2] = "Resume a paused reboot."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "pause,resume,rebo"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "reboot")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "unpause" or chatvars.words[1] == "unpaws" or chatvars.words[1] == "resume") and chatvars.words[2] == "reboot" and chatvars.words[3] == nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if botman.scheduledRestartPaused == true then
				botman.scheduledRestartTimestamp = os.time() + restartTimeRemaining
				botman.scheduledRestartPaused = false
				rebootTimer = restartTimeRemaining

				if chatvars.words[1] == "unpaws" then
					message("say [" .. server.chatColour .. "]The paws have been removed from the reboot countdown.[-]")
				else
					message("say [" .. server.chatColour .. "]The reboot countdown has resumed.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

if debug then dbug("debug server") end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - server commands ====")
		dbug("Registering help - server commands")

		tmp = {}
		tmp.topicDescription = "Server commands mainly cover settings that change the nature of the server or turn features on or off that relate to the server."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'server'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('server', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

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
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Server Commands:")
		irc_chat(chatvars.ircAlias, "================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "server")
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleTranslate()

	if result then
		if debug then dbug("debug cmd_ToggleTranslate triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_Say()

	if result then
		if debug then dbug("debug cmd_Say triggered") end
		return result
	end

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return false
		end
	else
		if tonumber(chatvars.ircid) > 0 then
			if (chatvars.accessLevel > 2) then
				botman.faultyChat = false
				return false
			end
		end
	end
	-- ##################################################################

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_CancelReboot()

	if result then
		if debug then dbug("debug cmd_CancelReboot triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_JoinGameServer()

	if result then
		if debug then dbug("debug cmd_JoinGameServer triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_PauseReboot()

	if result then
		if debug then dbug("debug cmd_PauseReboot triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_RunConsoleCommand()

	if result then
		if debug then dbug("debug cmd_RunConsoleCommand triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ScheduleServerReboot()

	if result then
		if debug then dbug("debug cmd_ScheduleServerReboot triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetAccessOverride()

	if result then
		if debug then dbug("debug cmd_SetAccessOverride triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetArchivePlayersThreshold()

	if result then
		if debug then dbug("debug cmd_SetArchivePlayersThreshold triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBailCost()

	if result then
		if debug then dbug("debug cmd_SetBailCost triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetClearViewMOTD()

	if result then
		if debug then dbug("debug cmd_SetClearViewMOTD triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetIRCChannels()

	if result then
		if debug then dbug("debug cmd_SetIRCChannels triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetIRCNick()

	if result then
		if debug then dbug("debug cmd_SetIRCNick triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetIRCServer()

	if result then
		if debug then dbug("debug cmd_SetIRCServer triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMapSize()

	if result then
		if debug then dbug("debug cmd_SetMapSize triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxAnimals()

	if result then
		if debug then dbug("debug cmd_SetMaxAnimals triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxPing()

	if result then
		if debug then dbug("debug cmd_SetMaxPing triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxPlayers()

	if result then
		if debug then dbug("debug cmd_SetMaxPlayers triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxUptime()

	if result then
		if debug then dbug("debug cmd_SetMaxUptime triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxZombies()

	if result then
		if debug then dbug("debug cmd_SetMaxZombies triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetNewPlayerMaxLevel()

	if result then
		if debug then dbug("debug cmd_SetNewPlayerMaxLevel triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetNewPlayerTimer()

	if result then
		if debug then dbug("debug cmd_SetNewPlayerTimer triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetOverstackLimit()

	if result then
		if debug then dbug("debug cmd_SetOverstackLimit triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetPingKickTarget()

	if result then
		if debug then dbug("debug cmd_SetPingKickTarget triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetPrisonTimer()

	if result then
		if debug then dbug("debug cmd_SetPrisonTimer triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetPVPCooldown()

	if result then
		if debug then dbug("debug cmd_SetPVPCooldown triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetReservedSlots()

	if result then
		if debug then dbug("debug cmd_SetReservedSlots triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetRollingAnnouncementTimer()

	if result then
		if debug then dbug("debug cmd_SetRollingAnnouncementTimer triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetRules()

	if result then
		if debug then dbug("debug cmd_SetRules triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerAPIKey()

	if result then
		if debug then dbug("debug cmd_SetServerAPIKey triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerGroup()

	if result then
		if debug then dbug("debug cmd_SetServerGroup triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerIP()

	if result then
		if debug then dbug("debug cmd_SetServerIP triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerRebootHour()

	if result then
		if debug then dbug("debug cmd_SetServerRebootHour triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerRebootMinute()

	if result then
		if debug then dbug("debug cmd_SetServerRebootMinute triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetServerType()

	if result then
		if debug then dbug("debug cmd_SetServerType triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetupAllocsWebMap()

	if result then
		if debug then dbug("debug cmd_SetupAllocsWebMap triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWebPanelPort()

	if result then
		if debug then dbug("debug cmd_SetWebPanelPort triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWebsite()

	if result then
		if debug then dbug("debug cmd_SetWebsite triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWelcomeMessage()

	if result then
		if debug then dbug("debug cmd_SetWelcomeMessage triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBadNames()

	if result then
		if debug then dbug("debug cmd_ToggleBadNames triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBanVACBannedPlayers()

	if result then
		if debug then dbug("debug cmd_ToggleBanVACBannedPlayers triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleCBSMFriendly()

	if result then
		if debug then dbug("debug cmd_ToggleCBSMFriendly triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleDespawnZombiesBeforeBloodMoon()

	if result then
		if debug then dbug("debug cmd_ToggleDespawnZombiesBeforeBloodMoon triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleEntityScan()

	if result then
		if debug then dbug("debug cmd_ToggleEntityScan triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleErrorScan()

	if result then
		if debug then dbug("debug cmd_ToggleErrorScan triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleHardcoreMode()

	if result then
		if debug then dbug("debug cmd_ToggleHardcoreMode triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIdleKick()

	if result then
		if debug then dbug("debug cmd_ToggleIdleKick triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIgnorePlayerFlying()

	if result then
		if debug then dbug("debug cmd_ToggleIgnorePlayerFlying triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIRCPrivate()

	if result then
		if debug then dbug("debug cmd_ToggleIRCPrivate triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleNoClipScan()

	if result then
		if debug then dbug("debug cmd_ToggleNoClipScan triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleOverstackChecking()

	if result then
		if debug then dbug("debug cmd_ToggleOverstackChecking triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_TogglePVPRulesByCompass()

	if result then
		if debug then dbug("debug cmd_TogglePVPRulesByCompass triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleRapidRelogTempBan()

	if result then
		if debug then dbug("debug cmd_ToggleRapidRelogTempBan triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleRegionPM()

	if result then
		if debug then dbug("debug cmd_ToggleRegionPM triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleServerReboots()

	if result then
		if debug then dbug("debug cmd_ToggleServerReboots triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleWatchAlerts()

	if result then
		if debug then dbug("debug cmd_ToggleWatchAlerts triggered") end
		return result
	end

	if (debug) then dbug("debug server line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnpauseReboot()

	if result then
		if debug then dbug("debug cmd_UnpauseReboot triggered") end
		return result
	end

	if debug then dbug("debug server end of remote commands") end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Server commands help registered ****")
		dbug("Server commands help registered")
		topicID = topicID + 1
	end

	if debug then dbug("debug server end") end

	-- can't touch dis
	if true then
		return result
	end
end
