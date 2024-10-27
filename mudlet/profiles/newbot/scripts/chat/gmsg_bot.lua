--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_bot()
	local tmp, debug, pname, pid, result, help
	local shortHelp = false

	-- enable debug to see where the code is stopping. Any error will be somewhere after the last successful debug line.
	debug = false -- should be false unless testing

	calledFunction = "gmsg_bot"
	result = false
	tmp = {}
	tmp.topic = "bot"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## Bot command functions ##################

	local function cmd_ApproveGlobalBan()
		local playerName, steam, steamOwner, userID

		if chatvars.words[1] == "approve" and chatvars.words[2] == "gblban" and chatvars.words[3] ~= nil then
			if (chatvars.playerid ~= "Server") then
				if (chatvars.playerid ~= Smegz0r and chatvars.ircid ~= Smegz0r) then
					message(string.format("pm %s [%s]This command can only be used by Smegz0r. Get your own :P", chatvars.userID, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.playerid ~= Smegz0r and chatvars.ircid ~= Smegz0r) then
					irc_chat(chatvars.ircAlias, "This command can only be used by Smegz0r. Get your own :P")
					botman.faultyChat = false
					return true
				end
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "gblban ") + 7)
			pname = string.trim(pname)
			steam, steamOwner, userID = LookupPlayer(pname)

			if steam ~= "0" then
				-- don't ban if player is an admin :O
				if isAdminHidden(steam, userID) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You what?  You want to global ban one of the admins?   [DENIED][-]")
					else
						irc_chat(chatvars.ircAlias, "You what?  You want to global ban one of the admins?   [DENIED]")
					end

					botman.faultyChat = false
					return true
				else
					playerName = players[steam].name
				end
			else
				steam, steamOwner, userID = LookupArchivedPlayer(pname)

				if steam == "0" then
					-- pname must be a steam id
					steam = pname
					playerName = steam
				else
					playerName = playersArchived[steam].name
				end
			end

			connBots:execute("UPDATE bans set GBLBan = 1, GBLBanVetted = 1, GBLBanActive = 1 WHERE steam = '" .. steam .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. "'s global ban has been approved.[-]")
			else
				irc_chat(chatvars.ircAlias, playername .. "'s global ban has been approved.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_BackupBot()
		local saveName

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}backup bot {optional name}"
			help[2] = "Make a backup of the bot's data before doing something to the bot. :O"

			tmp.command = help[1]
			tmp.keywords = "bot,backup,save"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "back") or string.find(chatvars.command, "save") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "backup" and chatvars.words[2] == "bot" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.wordsOld[3] ~= nil then
				saveName = string.sub(chatvars.commandOld, string.find(chatvars.command, " bot ") + 5)
			else
				saveName = ""
			end

			saveLuaTables(os.date("%Y%m%d_%H%M%S"), saveName)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot has been backed up.[-]")
			else
				irc_chat(chatvars.ircAlias, "The bot has been backed up.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ClearBotsWhitelist()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}clear whitelist"
			help[2] = "Remove everyone from the bot's whitelist."

			tmp.command = help[1]
			tmp.keywords = "bot,clear,white,list,empty"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "white") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "clear" and chatvars.words[2] == "whitelist" and chatvars.words[3] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			conn:execute("TRUNCATE TABLE whitelist")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The whitelist has been cleared.[-]")
			else
				irc_chat(chatvars.ircAlias, "The whitelist has been cleared.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Timers()
		local noActiveTimers = true

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}timers"
			help[2] = "List your active cooldown timers and how much time remains for each."

			tmp.command = help[1]
			tmp.keywords = "timers,cooldowns"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "time") or string.find(chatvars.command, "cool") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "timers" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				if not chatvars.isAdmin then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your active cooldown timers are:[-]")

					if (players[chatvars.playerid].waypointCooldown - os.time() > 0) then
						if players[chatvars.playerid].waypointCooldown - os.time() < 3600 then
							delay = os.date("%M minutes %S seconds",players[chatvars.playerid].waypointCooldown - os.time())
						else
							delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].waypointCooldown - os.time())
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "wp wait " .. delay .. ".[-]")
						noActiveTimers = false
					end

					if (players[chatvars.playerid].setWPCooldown - os.time() > 0) then
						if players[chatvars.playerid].setWPCooldown - os.time() < 3600 then
							delay = os.date("%M minutes %S seconds",players[chatvars.playerid].setWPCooldown - os.time())
						else
							delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].setWPCooldown - os.time())
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set wp wait " .. delay .. ".[-]")
						noActiveTimers = false
					end

					if (players[chatvars.playerid].pvpTeleportCooldown - os.time() > 0) then
						if players[chatvars.playerid].pvpTeleportCooldown - os.time() < 3600 then
							delay = os.date("%M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())
						else
							delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())
						end

						message(string.format("pm %s [%s]You must wait %s before you are allowed to teleport again after a PVP kill.", chatvars.userID, server.chatColour, delay))
						noActiveTimers = false
					end

					if (players[chatvars.playerid].baseCooldown - os.time() > 0) then
						if players[chatvars.playerid].baseCooldown - os.time() < 3600 then
							delay = os.date("%M minutes %S seconds",players[chatvars.playerid].baseCooldown - os.time())
						else
							delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].baseCooldown - os.time())
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "base wait " .. delay .. ".[-]")
						noActiveTimers = false
					end

					if (players[chatvars.playerid].setBaseCooldown - os.time() > 0) then
						if players[chatvars.playerid].setBaseCooldown - os.time() < 3600 then
							delay = os.date("%M minutes %S seconds",players[chatvars.playerid].setBaseCooldown - os.time())
						else
							delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].setBaseCooldown - os.time())
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "setbase wait " .. delay .. ".[-]")
						noActiveTimers = false
					end

					if (players[chatvars.playerid].returnCooldown - os.time() > 0) then
						if players[chatvars.playerid].returnCooldown - os.time() < 3600 then
							delay = os.date("%M minutes %S seconds",players[chatvars.playerid].returnCooldown - os.time())
						else
							delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].returnCooldown - os.time())
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "return wait " .. delay .. ".[-]")
						noActiveTimers = false
					end

					if (players[chatvars.playerid].gimmeCooldown - os.time() > 0) then
						if players[chatvars.playerid].gimmeCooldown - os.time() < 3600 then
							delay = os.date("%M minutes %S seconds",players[chatvars.playerid].gimmeCooldown - os.time())
						else
							delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].gimmeCooldown - os.time())
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "gimme wait " .. delay .. ".[-]")
						noActiveTimers = false
					end

					if (players[chatvars.playerid].p2pCooldown - os.time() > 0) then
						if players[chatvars.playerid].p2pCooldown - os.time() < 3600 then
							delay = os.date("%M minutes %S seconds",players[chatvars.playerid].p2pCooldown - os.time())
						else
							delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].p2pCooldown - os.time())
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "visit wait " .. delay .. ".[-]")
						noActiveTimers = false
					end
				end

				if noActiveTimers then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have no active cooldown timers! :D[-]")
				end
			else
				irc_chat(chatvars.ircAlias, "This command is in-game only.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ForgetPlayers()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}forget players"
			help[2] = "Makes the bot forget everything about players as if they were new again. It does not touch admins (nasty filthy adminses)."

			tmp.command = help[1]
			tmp.keywords = "bot,forget,players"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "forget") or string.find(chatvars.command, "players") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "forget" and chatvars.words[2] == "players" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Are you sure you want to forget all players excluding admins? Answer yes to proceed or anything else to cancel.[-]")
			else
				irc_chat(chatvars.ircAlias, "Are you sure you want to forget all players excluding admins? Answer yes to proceed or anything else to cancel.")
			end

			players[chatvars.playerid].botQuestion = "forget players"

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GuessPassword()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}password {some password or phrase}"
			help[2] = "If you have set a master password, some bot commands will issue a password challenge.  Use this command to send the password to the bot."

			tmp.command = help[1]
			tmp.keywords = "bot,password"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "pass") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "password") and (chatvars.words[2] ~= nil) and (chatvars.isAdminHidden) then
			local response

			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.ircid ~= "0" then
				id = chatvars.ircid
			else
				id = chatvars.playerid
			end

			if string.sub(chatvars.commandOld, string.find(chatvars.command, "password") + 9) ~= server.masterPassword then
				response = "password attempt failed."

				r = randSQL(10)
				if (r == 1) then response = "Your weak " .. response end
				if (r == 2) then response = "That pathetic " .. response end
				if (r == 3) then response = "Oh please. " .. firstToUpper(response) end
				if (r == 4) then response = "So close! " .. firstToUpper(response) end
				if (r == 5) then response = "Stop guessing. " .. firstToUpper(response) end
				if (r == 6) then response = "Uh uh uh! You forgot to say the magic word."end
				if (r == 7) then response = "Stop it! " .. firstToUpper(response) end
				if (r == 8) then response = "BZZT! " .. firstToUpper(response) end
				if (r == 9) then response = "Ruh roh! " .. firstToUpper(response) end
				if (r == 10) then response = "That's the wrongest password I've ever seen!" end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. response .. "[-]")
				else
					irc_chat(chatvars.ircAlias, response)
				end

				botman.faultyChat = false
				return true
			else
				-- password accepted (or a great guess)
				if players[id].botQuestion == "reset server" and chatvars.accessLevel == 0 then
					ResetServer()

					botman.faultyChat = false
					return true
				end

				 if players[id].botQuestion == "restart bot" and (chatvars.isAdminHidden) then
					players[id].botQuestion = ""
					players[id].botQuestionID = nil
					players[id].botQuestionValue = nil

					restartBot()

					botman.faultyChat = false
					return true
				end

				if players[ID].botQuestion == "reset bot keep money" and chatvars.accessLevel == 0 then
					ResetBot(true)

					message("say [" .. server.chatColour .. "]The bot has been reset.  All bases, inventories etc are forgotten, but not the players or their money.[-]")

					players[id].botQuestion = ""
					players[id].botQuestionID = nil
					players[id].botQuestionValue = nil

					botman.faultyChat = false
					return true
				end

				if players[id].botQuestion == "reset bot" and chatvars.accessLevel == 0 then
					ResetBot()

					message("say [" .. server.chatColour .. "]The bot has been reset.  All bases, inventories etc are forgotten, but not the players.[-]")

					players[id].botQuestion = ""
					players[id].botQuestionID = nil
					players[id].botQuestionValue = nil

					botman.faultyChat = false
					return true
				end

				if players[id].botQuestion == "quick reset bot" and chatvars.accessLevel == 0 then
					quickBotReset()

					message("say [" .. server.chatColour .. "]The bot has been reset except for players, locations and reset zones.[-]")

					players[id].botQuestion = ""
					players[id].botQuestionID = nil
					players[id].botQuestionValue = nil

					botman.faultyChat = false
					return true
				end
			end

			players[id].botQuestion = ""
			players[id].botQuestionID = nil
			players[id].botQuestionValue = nil

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBackups()
		local cursor, errorString, row, count

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list backups"
			help[2] = "View a numbered list of available backups.\n"
			help[2] = help[2] .. "Use {#}restore backup, to restore a backup. See the help for {#}restore backup for additional options."

			tmp.command = help[1]
			tmp.keywords = "bot,list,backups"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "backup") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "list" and string.find(chatvars.command, "backup") and chatvars.words[3] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			getBackupFiles(homedir .. "/data_backup")

			-- the file list isn't in a useful order for numbering.  Let's fix that.
			cursor,errorString = connMEM:execute("SELECT * FROM list WHERE class = 'backup' ORDER BY thing desc")
			row = cursor:fetch({}, "a")
			count = 2

			while row do
				connMEM:execute("UPDATE list SET id = " .. count .. " WHERE thing = '" .. connMEM:escape(row.thing) .. "'")
				count = count + 1
				row = cursor:fetch(row, "a")
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]#1 Latest backup[-]")
			else
				irc_chat(chatvars.ircAlias, "#1 Latest backup")
			end

			cursor,errorString = connMEM:execute("SELECT * FROM list WHERE class = 'backup' ORDER BY id")
			row = cursor:fetch({}, "a")

			while row do
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]#" .. row.id .. " " .. row.thing  .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "#" .. row.id .. " " .. row.thing)
				end

				row = cursor:fetch(row, "a")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListChatColours()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list chat colors"
			help[2] = "See the bot's chat colours and player chat colours."

			tmp.command = help[1]
			tmp.keywords = "bot,list,chat,colours,colors"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "list" and chatvars.words[2] == "chat" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Bot chat colour is " .. server.chatColour .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Bot warn colour is [-][" .. server.warnColour .. "]" .. server.chatColour .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Bot alert colour is [-][" .. server.alertColour .. "]" .. server.alertColour .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Owner colour is [-][" .. server.chatColourOwner .. "]" .. server.chatColourOwner .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Admin colour is [-][" .. server.chatColourAdmin .. "]" .. server.chatColourAdmin .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Mod colour is [-][" .. server.chatColourMod .. "]" .. server.chatColourMod .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Prisoner colour is [-][" .. server.chatColourPrisoner .. "]" .. server.chatColourPrisoner .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Donor colour is [-][" .. server.chatColourDonor .. "]" .. server.chatColourDonor .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player colour is [-][" .. server.chatColourPlayer .. "]" .. server.chatColourPlayer .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New player colour is [-][" .. server.chatColourNewPlayer .. "]" .. server.chatColourNewPlayer .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Bot chat colour is " .. server.chatColour)
				irc_chat(chatvars.ircAlias, "Bot warn colour is " .. server.warnColour)
				irc_chat(chatvars.ircAlias, "Bot alert colour is " .. server.alertColour)
				irc_chat(chatvars.ircAlias, "Owner colour is " .. server.chatColourOwner)
				irc_chat(chatvars.ircAlias, "Admin colour is " .. server.chatColourAdmin)
				irc_chat(chatvars.ircAlias, "Mod colour is " .. server.chatColourMod)
				irc_chat(chatvars.ircAlias, "Prisoner colour is " .. server.chatColourPrisoner)
				irc_chat(chatvars.ircAlias, "Donor colour is " .. server.chatColourDonor)
				irc_chat(chatvars.ircAlias, "Player colour is " .. server.chatColourPlayer)
				irc_chat(chatvars.ircAlias, "New player colour is " .. server.chatColourNewPlayer)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_NoReset()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}no reset"
			help[2] = "If the bot detects that the server days have rolled back, it will ask you if you want to reset the bot.  Type {#}no reset if you don't want the bot to reset itself."

			tmp.command = help[1]
			tmp.keywords = "bot,reset"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reset") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "no") and (chatvars.words[2] == "reset") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Oh ok then.[-]")
			server.warnBotReset = false

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_QuickResetBot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}quick reset bot"
			help[2] = "Tell the bot to forget only some things, some player info, locations, bases etc.  You will be asked to confirm this, answer with yes.  Say anything else to abort.\n"
			help[2] = help[2] .. "Use this command after wiping the server.  The bot will detect the day change and will ask if you want to reset the bot too."

			tmp.command = help[1]
			tmp.keywords = "bot,reset"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reset") or string.find(chatvars.command, "bot") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "quick") and (chatvars.words[2] == "reset") and (chatvars.words[3] == "bot") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Are you sure you want to reset the bot?  Answer yes to proceed or anything else to cancel.[-]")
			else
				irc_chat(chatvars.ircAlias, "Are you sure you want to reset the bot?  Answer cmd " .. server.commandPrefix .. "yes to proceed or anything else to cancel.")
			end

			players[chatvars.playerid].botQuestion = "quick reset bot"

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RefreshCode()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}refresh code"
			help[2] = "Make the bot re-download and install from the current code branch for script updates.  Only necessary if someone has edited the code and needs to restore it."

			tmp.command = help[1]
			tmp.keywords = "bot,refresh,code"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "refresh") or string.find(chatvars.command, "code") or string.find(chatvars.command, "script") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "refresh" and (chatvars.words[2] == "code" or chatvars.words[2] == "scripts" or words[2] == "bot") and chatvars.words[3] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			botman.refreshCode = true
			updateBot(true, chatvars.playerid)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RejoinIRC()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}rejoin irc"
			help[2] = "Sometimes the bot can fall off IRC and fail to reconnect.  This command forces it to reconnect."

			tmp.command = help[1]
			tmp.keywords = "bot,irc,server,lounge"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "irc") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "rejoin" or chatvars.words[1] == "reconnect") and chatvars.words[2] == "irc" then
			-- join (or rejoin) the irc server incase the bot has fallen off and failed to reconnect
			joinIRCServer()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReloadBot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reload bot"
			help[2] = "Make the bot read several things from the server including admin list, ban list, gg, lkp and others."

			tmp.command = help[1]
			tmp.keywords = "bot,reload,refresh,init"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reload bot") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "reload" or chatvars.words[1] == "refresh" or chatvars.words[1] == "update") and chatvars.words[2] == "bot" then
			-- run admin list, gg, ban list and lkp

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Refreshing admins, bans, server config from server.[-]")
			else
				irc_chat(chatvars.ircAlias, "Refreshing admins, bans, server config from server.")
			end

			reloadBot()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetBases()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reset bases"
			help[2] = "Just reset the player bases, nothing else.\n"
			help[2] = help[2] .. "This commmand is mainly for rare cases where you only need the bot to forget the player bases."

			tmp.command = help[1]
			tmp.keywords = "bot,reset,bases"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reset") or string.find(chatvars.command, "bot") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "reset" and chatvars.words[2] == "bases" and chatvars.words[3] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			resetBases()
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot has forgotten the player bases only.  Players will need to re-do {#}setbase.[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetBot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reset bot\n"
			help[1] = help[1] .. " {#}reset bot keep money"
			help[2] = "Tell the bot to forget only some things, some player info, locations, bases etc.  You will be asked to confirm this, answer with yes.  Say anything else to abort.\n"
			help[2] = help[2] .. "Use this command after wiping the server.  The bot will detect the day change and will ask if you want to reset the bot too."

			tmp.command = help[1]
			tmp.keywords = "bot,reset"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reset") or string.find(chatvars.command, "bot") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "reset" and chatvars.words[2] == "bot" and chatvars.words[3] == "keep" and (chatvars.words[4] == "money" or chatvars.words[4] == "cash" or chatvars.words[4] == server.moneyName or chatvars.words[4] == server.moneyPlural) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Are you sure you want to reset the bot?  Answer yes to proceed or anything else to cancel.[-]")
			else
				irc_chat(chatvars.ircAlias, "Are you sure you want to reset the bot?  Answer cmd " .. server.commandPrefix .. "yes to proceed or anything else to cancel.")
			end

			players[chatvars.playerid].botQuestion = "reset bot keep money"

			botman.faultyChat = false
			return true
		end

		if (chatvars.words[1] == "reset") and (chatvars.words[2] == "bot") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Are you sure you want to reset the bot?  Answer yes to proceed or anything else to cancel.[-]")
			else
				irc_chat(chatvars.ircAlias, "Are you sure you want to reset the bot?  Answer cmd " .. server.commandPrefix .. "yes to proceed or anything else to cancel.")
			end

			players[chatvars.playerid].botQuestion = "reset bot"

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetServer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reset server"
			help[2] = "Tell the bot to forget everything it knows about the server.  You will be asked to confirm this, answer with yes.  Say anything else to abort.\n"
			help[2] = help[2] .. "Usually you only need to use {#}reset bot.  This reset goes further."

			tmp.command = help[1]
			tmp.keywords = "bot,reset,server"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reset") or string.find(chatvars.command, "server") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "reset") and (chatvars.words[2] == "server") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Are you sure you want to wipe the bot completely clean?  Answer yes to proceed or anything else to cancel.[-]")
			else
				irc_chat(chatvars.ircAlias, "Are you sure you want to wipe the bot completely clean?  Answer cmd " .. server.commandPrefix .. "yes to proceed or anything else to cancel.")
			end

			players[chatvars.playerid].botQuestion = "reset server"

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RestartBot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}restart bot"
			help[2] = "If your Mudlet (the bot's engine) is set up to automatically restart itself you can command the bot to restart.  Also this feature must be enabled."

			tmp.command = help[1]
			tmp.keywords = "bot,restart"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "rest") or string.find(chatvars.command, "bot") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "restart") and (chatvars.words[2] == "bot") and (chatvars.isAdminHidden) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if not server.allowBotRestarts then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command is disabled.  Enable it with /enable bot restart[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]If you do not have a script or other process monitoring the bot, it will not restart automatically.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Scripts can be downloaded at https://botman.nz/shellscripts.zip and may require some editing for paths.[-]")
				else
					irc_chat(chatvars.ircAlias, "This command is disabled.  Enable it with /enable bot restart")
					irc_chat(chatvars.ircAlias, "If you do not have a script or other process monitoring the bot, it will not restart automatically.")
					irc_chat(chatvars.ircAlias, "Scripts can be downloaded at https://botman.nz/shellscripts.zip and may require some editing for paths.")
				end

				botman.faultyChat = false
				return true
			end

			if server.masterPassword ~= "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]This command requires a password to complete. Don't use this command unless you know what it does and why you need to do it.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Type " .. server.commandPrefix .. "password {the password} (Do not type the {}).[-]")
					players[chatvars.playerid].botQuestion = "restart bot"
				else
					irc_chat(chatvars.ircAlias, "This command requires a password to complete. Don't use this command unless you know what it does and why you need to do it.")
					irc_chat(chatvars.ircAlias, "Type " .. server.commandPrefix .. "password {the password} (Do not type the {}).")
					players[chatvars.ircid].botQuestion = "restart bot"
				end
			else
				restartBot()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RestoreBackup()
		local cursor, errorString, row, onlyImportThis, pos

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}restore backup {optional backup number} {optional words: bases, cash, donors, colors, locations, waypoints, friends, villagers, teleports, hotspots, resets, players, shop, gimme, zombies}\n"
			help[1] = help[1] .. " {#}restore backup {optional backup number} {optional words as above} player {name or steam or player id} (note: player {name} must be specified last)"
			help[2] = "The bot saves its Lua tables daily at midnight (server time) and each time the server is shut down.\n"
			help[2] = help[2] .. "If the bot gets messed up, you can try to fix it with this command. Other timestamped backups are made before the bot is reset but you will first need to strip the date part off them to restore with this command.\n"
			help[2] = help[2] .. "To only restore player bases, add the word bases, for cash add cash and for donors add donors. If these words are included, nothing else is restored.\n"
			help[2] = help[2] .. "You can also just restore 1 named player.\n"
			help[2] = help[2] .. "To see a list of backups use {#}list backups."

			tmp.command = help[1]
			tmp.keywords = "bot,restore,recover,fix"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "restore") or string.find(chatvars.command, "backup") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "restore" and (chatvars.words[2] == "backup" or chatvars.words[2] == "bot") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			onlyImportThis = ""

			if string.find(chatvars.command, " colo") then
				onlyImportThis = onlyImportThis .. "colours"
			end

			if string.find(chatvars.command, " base") then
				onlyImportThis = onlyImportThis .. "bases"
			end

			if string.find(chatvars.command, " cash") then
				onlyImportThis = onlyImportThis .. "cash"
			end

			if string.find(chatvars.command, " donor") then
				onlyImportThis = onlyImportThis .. "donors"
			end

			if string.find(chatvars.command, " player") then
				pos = string.find(chatvars.command, " player ") + 8
				onlyImportThis = onlyImportThis .. " player " .. string.sub(chatvars.command, pos)
			end

			if string.find(chatvars.command, " shop") then
				onlyImportThis = onlyImportThis .. "shop"
			end

			if string.find(chatvars.command, " gimme") then
				onlyImportThis = onlyImportThis .. "gimme"
			end

			if string.find(chatvars.command, " zombie") then
				onlyImportThis = onlyImportThis .. "zombies"
			end

			if chatvars.number then
				if chatvars.number == 1 then
					importLuaData()

					botman.faultyChat = false
					return true
				end

				cursor,errorString = connMEM:execute("SELECT * FROM list WHERE id = " .. chatvars.number .. " AND steam = '-10'")
				row = cursor:fetch({}, "a")

				if row.thing then
					importLuaData(row.thing .. "_", onlyImportThis)
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Pick one of the numbered backups.[-]")
					else
						irc_chat(chatvars.ircAlias, "Pick one of the numbered backups.")
					end

					botman.faultyChat = false
					return true
				end
			else
				importLuaData(nil, onlyImportThis)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetAPILogPollingInterval()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set api log read {interval in seconds} (default 3 seconds)"
			help[2] = "In API mode the bot will read the server log at regular intervals with the default being every 5 seconds.\n"
			help[2] = help[2] .. "You can set a longer delay but the bot won't respond to in-game commands faster than the delay that you set.\n"
			help[2] = help[2] .. "If you think the polling interval is causing server lag you can try slowing it down."

			tmp.command = help[1]
			tmp.keywords = "bot,api,log,time,delay,interval"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "api") or string.find(chatvars.command, " log") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "set api log read") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				chatvars.number = 1
			else
				chatvars.number = math.abs(chatvars.number)
			end

			server.logPollingInterval = chatvars.number
			conn:execute("UPDATE server SET logPollingInterval  = '" .. chatvars.number .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will poll the server log every " .. server.logPollingInterval .. " seconds.[-]")
			else
				irc_chat(chatvars.ircAlias, "The bot will poll the server log every " .. server.logPollingInterval .. " seconds.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBlacklistResponse()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}blacklist action ban (or exile or 'nothing')"
			help[2] = "Set what happens to blacklisted players.  The default is to ban them 10 years but if you create a location called exile, the bot can bannish them to there instead.  It acts like a prison.\n"
			help[2] = help[2] .. "To disable the blacklist, set action to the word nothing.\n"
			help[2] = help[2] .. "NOTE: If blacklist action is nothing, proxies won't trigger a ban or exile response either."

			tmp.command = help[1]
			tmp.keywords = "bot,black,list,action,ban,exile"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "black") or string.find(chatvars.command, " ban") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "blacklist" and string.find(chatvars.words[2], "action") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[3] == nil then
				chatvars.words[3] = "nothing"
			end

			if chatvars.words[3] ~= "exile" and chatvars.words[3] ~= "ban" and chatvars.words[3] ~= "nothing" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Expected ban, exile or nothing as 3rd word.[-]")
				else
					irc_chat(chatvars.ircAlias, "Expected ban, exile or nothing as 3rd word.")
				end

				botman.faultyChat = false
				return true
			end

			server.blacklistResponse = chatvars.words[3]
			conn:execute("UPDATE server SET blacklistResponse  = '" .. escape(chatvars.words[3]) .. "'")

			if chatvars.words[3] == "ban" then
				response = "Blacklisted players will be banned."
			end

			if chatvars.words[3] == "exile" then
				response = "Blacklisted players will be exiled if a location called exile exists."
			end

			if chatvars.words[3] == "nothing" then
				response = "Nothing will happen to blacklisted players. The blacklist is disabled."
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. response .. "[-]")
			else
				irc_chat(chatvars.ircAlias, response)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBotAlertColour()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set alert colour {hex code}"
			help[2] = "Set the colour of server alert messages."

			tmp.command = help[1]
			tmp.keywords = "bot,set,colour,color,alert"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "alert") or string.find(chatvars.command, "colo") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "alert" and string.find(chatvars.words[3], "colo") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Please specify a colour code. eg. FF0000[-]")
				else
					irc_chat(chatvars.ircAlias, "Please specify a colour code. eg. FF0000")
				end

				botman.faultyChat = false
				return true
			end

			server.alertColour = string.upper(chatvars.words[4])

			-- strip out any # characters
			server.alertColour = server.alertColour:gsub("#", "")
			server.alertColour = string.sub(server.alertColour, 1, 6)

			conn:execute("UPDATE server SET alertColour = '" .. escape(server.alertColour) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.alertColour .. "]You have changed the colour for alert messages from the bot.[-]")
			else
				irc_chat(chatvars.ircAlias, "You have changed the colour for alert messages from the bot.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBotChatColour()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set chat colour {hex code}"
			help[2] = "Set the colour of server messages.  Player chat will be the default colour."

			tmp.command = help[1]
			tmp.keywords = "bot,set,colour,color,chat"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "chat" and string.find(chatvars.words[3], "colo") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Please specify a colour code. eg. FF0000[-]")
				else
					irc_chat(chatvars.ircAlias, "Please specify a colour code. eg. FF0000")
				end

				botman.faultyChat = false
				return true
			end

			server.chatColour = string.upper(chatvars.words[4])

			-- strip out any # characters
			server.chatColour = server.chatColour:gsub("#", "")
			server.chatColour = string.sub(server.chatColour, 1, 6)

			conn:execute("UPDATE server SET chatColour = '" .. escape(server.chatColour) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have changed the bot's chat colour.[-]")
			else
				irc_chat(chatvars.ircAlias, "You have changed the bot's chat colour.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBotLogLevel()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set bot log level {0 - 5} (default 0)"
			help[2] = "To help reduce IO and improve bot performance you can tell the bot to not maintain certain logs.\n"
			help[2] = help[2] .. "When set to 0 the bot will record all logs that it maintains except where individual logs can be enabled or disabled with other commands. Settings are as follows..\n"
			help[2] = help[2] .. "0 = Everything is logged\n"
			help[2] = help[2] .. "1 = Telnet is not logged\n"
			help[2] = help[2] .. "2 = The player tracking shadow copy is not logged\n"
			help[2] = help[2] .. "3 = Bot commands are not logged separately\n"
			help[2] = help[2] .. "4 = Telnet and the tracking shadow copy are not logged\n"
			help[2] = help[2] .. "5 = Telnet, the tracking shadow copy, and bot commands are not logged"

			tmp.command = help[1]
			tmp.keywords = "bot,set,log,level"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "log") or string.find(chatvars.command, " bot")  or string.find(chatvars.command, " set") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "set") and (chatvars.words[2] == "bot") and (chatvars.words[3] == "log") and (chatvars.words[4] == "level") and (chatvars.isAdminHidden) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A number from 0 to 5 is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "A number from 0 to 5 is required.")
				end

				botman.faultyChat = false
				return true
			end

			if server.botLoggingLevel > 5 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A number from 0 to 5 is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "A number from 0 to 5 is required.")
				end
			end

			chatvars.number = math.abs(chatvars.number)
			server.botLoggingLevel = chatvars.number
			if botman.dbConnected then conn:execute("UPDATE server SET botLoggingLevel = " .. server.botLoggingLevel) end

			if server.botLoggingLevel == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]All bot logs are enabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "All bot logs are enabled.")
				end
			end

			if server.botLoggingLevel == 1 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will not log telnet.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will not log telnet.")
				end
			end

			if server.botLoggingLevel == 2 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The shadow copy of player movement will not be logged.[-]")
				else
					irc_chat(chatvars.ircAlias, "The shadow copy of player movement will not be logged.")
				end
			end

			if server.botLoggingLevel == 3 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Bot commands will not be logged to the separate commandlog file but are still logged in the chatlog file.[-]")
				else
					irc_chat(chatvars.ircAlias, "Bot commands will not be logged to the separate commandlog file but are still logged in the chatlog file.")
				end
			end

			if server.botLoggingLevel == 4 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will not log telnet or the shadow copy of player movement.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will not log telnet or the shadow copy of player movement.")
				end
			end

			if server.botLoggingLevel == 5 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will not log telnet, the shadow copy of player movement or bot commands.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will not log telnet, the shadow copy of player movement or bot commands.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBotName()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}name bot {some cool name}"
			help[2] = "The default name is Bot.  Help give your bot a personality by giving it a name."

			tmp.command = help[1]
			tmp.keywords = "bot,set,name"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, " name") or string.find(chatvars.command, " bot") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "name" and chatvars.words[2] == "bot" and chatvars.words[3] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = stripQuotes(string.sub(chatvars.commandOld, string.find(chatvars.commandOld, chatvars.words[2], nil, true) + 4, string.len(chatvars.commandOld)))
			if tmp == "Tester" and chatvars.playerid ~= Smegz0r then
				message("say [" .. server.warnColour .. "]That name is reserved.[-]")
				botman.faultyChat = false
				return true
			end

			server.botName = tmp

			if server.botman then
				sendCommand("bm-change botname [" .. server.botNameColour .. "]" .. server.botName)
			end

			message("say [" .. server.chatColour .. "]I shall henceforth be known as " .. server.botName .. ".[-]")

			msg = "say [" .. server.chatColour .. "]Hello I am the server bot, " .. server.botName .. ". Pleased to meet you. :3[-]"
			tempTimer( 5, [[message(msg)]] )

			conn:execute("UPDATE server SET botName = '" .. escape(server.botName) .. "'")

			if botman.botsConnected then
				connBots:execute("UPDATE servers SET botName = '" .. escape(server.botName) .. "' WHERE botID = " .. server.botID)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBotNameColour()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set bot name colour {hex colour code}"
			help[2] = "Set the colour of the bot's name.  Requires the botman mod."

			tmp.command = help[1]
			tmp.keywords = "bot,set,colour,color,name"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "name") or string.find(chatvars.command, "colo") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "bot" and chatvars.words[3] == "name" and string.find(chatvars.words[4], "colo") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[5] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Please specify a colour code. eg. FF0000[-]")
				else
					irc_chat(chatvars.ircAlias, "Please specify a colour code. eg. FF0000")
				end

				botman.faultyChat = false
				return true
			end

			server.botNameColour = string.upper(chatvars.words[5])

			-- strip out any # characters
			server.botNameColour = server.botNameColour:gsub("#", "")
			server.botNameColour = string.sub(server.botNameColour, 1, 6)

			conn:execute("UPDATE server SET botNameColour = '" .. escape(server.botNameColour) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have changed the colour of the bot's name in server messages.[-]")
			else
				irc_chat(chatvars.ircAlias, "You have changed the colour of the bot's name in server messages.")
			end

			if server.botman then
				sendCommand("bm-change botname [" .. server.botNameColour .. "]" .. server.botName)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBotRestartDay()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set bot restart {0+} (total bot days running)"
			help[2] = "The bot can automatically restart itself after running for days. The restart helps fix issues and keeps the bot fresh.\n"
			help[2] = help[2] .. "The default is 7 days between bot restarts. You can disable it by setting it to 0. Also it will only activate if bot restarts are enabled."

			tmp.command = help[1]
			tmp.keywords = "bot,set,day,restart"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "restart") or string.find(chatvars.command, " bot")  or string.find(chatvars.command, " set") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "set") and (chatvars.words[2] == "bot") and (chatvars.words[3] == "restart") and (chatvars.isAdminHidden) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A number of 0 or more is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "A number of 0 or more is required.")
				end

				botman.faultyChat = false
				return true
			end

			chatvars.number = math.abs(chatvars.number)
			server.botRestartDay = chatvars.number
			if botman.dbConnected then conn:execute("UPDATE server SET botRestartDay = " .. server.botRestartDay) end

			if server.botRestartDay > 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will quit and automatically restart after running for " .. server.botRestartDay .. " days.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will quit and automatically restart after running for " .. server.botRestartDay .. " days.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will run until manually stopped.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will run until manually stopped.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetTelnetSpamTrigger()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set spam trigger {number}"
			help[2] = "The bot has a safe mode and monitors telnet for WRN and ERR lines. If it counts more than the spam trigger value in 5 seconds, it will stop processing every single telnet line that it sees and go into safe mode.\n"
			help[2] = help[2] .. "In safe mode it will only process telnet lines for 5 seconds in every 25 seconds.\n"
			help[2] = help[2] .. "The bot will exit safe mode and resume normal processing of telnet lines once the spam detection drops below the spam trigger number.\n"
			help[2] = help[2] .. "It report to the alerts channel when it is in safe mode along with the current spam count."

			tmp.command = help[1]
			tmp.keywords = "bot,set,spam,trigger,threshold"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "spam") or string.find(chatvars.command, "trigger") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "set") and (chatvars.words[2] == "spam") and (chatvars.words[3] == "trigger") and (chatvars.isAdminHidden) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A number of 30 or more is required. The default is 50.[-]")
				else
					irc_chat(chatvars.ircAlias, "A number of 30 or more is required. The default is 50.")
				end

				botman.faultyChat = false
				return true
			end

			chatvars.number = math.abs(chatvars.number)

			if tonumber(chatvars.number) < 30 then
				chatvars.number = 30
			end

			server.safeModeSpamTrigger = chatvars.number
			if botman.dbConnected then conn:execute("UPDATE server SET safeModeSpamTrigger = " .. server.safeModeSpamTrigger) end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot's safe mode will trigger when WRN and ERR spam exceeds " .. server.safeModeSpamTrigger .. " within 5 second intervals.[-]")
			else
				irc_chat(chatvars.ircAlias, "The bot's safe mode will trigger when WRN and ERR spam exceeds " .. server.safeModeSpamTrigger .. " within 5 second intervals.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBotWarningColour()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set warn colour {hex code}"
			help[2] = "Set the colour of server warning messages."

			tmp.command = help[1]
			tmp.keywords = "bot,set,colour,color,warning"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "warn" and string.find(chatvars.words[3], "colo") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Please specify a colour code. eg. FF0000[-]")
				else
					irc_chat(chatvars.ircAlias, "Please specify a colour code. eg. FF0000")
				end

				botman.faultyChat = false
				return true
			end

			server.warnColour = string.upper(chatvars.words[4])

			-- strip out any # characters
			server.warnColour = server.warnColour:gsub("#", "")
			server.warnColour = string.sub(server.warnColour, 1, 6)

			conn:execute("UPDATE server SET warnColour = '" .. escape(server.warnColour) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]You have changed the colour for warning messages from the bot.[-]")
			else
				irc_chat(chatvars.ircAlias, "You have changed the colour for warning messages from the bot.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetCommandPrefix()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set command prefix / (or no symbol)"
			help[2] = "Change bot commands from using / to using nothing or another symbol."

			tmp.command = help[1]
			tmp.keywords = "bot,set,command,prefix,symbol,chat"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "prefix") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "set" and chatvars.words[2] == "command" and chatvars.words[3] == "prefix") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.prefix = chatvars.words[4]

			if tmp.prefix ~= "" then
				server.commandPrefix = tmp.prefix
				conn:execute("UPDATE server SET commandPrefix = '" .. tmp.prefix .. "'")

				if (chatvars.playername ~= "Server") then
					message("say [" .. server.chatColour .. "]Commands now begin with a " .. server.commandPrefix .. " To use commands such as who type " .. server.commandPrefix .. "who.[-]")
				else
					irc_chat(server.ircMain, "Ingame bot commands must now start with a " .. tmp.prefix)
				end

				if server.botman then
					sendCommand("bm-chatcommands prefix " .. server.commandPrefix)
				else
					hidePlayerChat(tmp.prefix)
				end
			else
				server.commandPrefix = ""
				conn:execute("UPDATE server SET commandPrefix = ''")

				if (chatvars.playername ~= "Server") then
					message("say [" .. server.chatColour .. "]Bot commands are now just text.  To use commands such as who simply type who.[-]")
				else
					irc_chat(server.ircMain, "Ingame bot commands do not use a prefix such as /  Instead just type the commands as words.")
				end

				hidePlayerChat()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMasterPassword()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set master password {secret password up to 50 characters}"
			help[2] = "Protect important commands such as {#}reset bot with a password.\n"
			help[2] = help[2] .. "This will prevent you or another server owner from accidentally doing something stupid (hopefully).\n"
			help[2] = help[2] .. "To remove it use {#}clear master password."

			tmp.command = help[1]
			tmp.keywords = "bot,set,password,master"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "pass") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "set" or chatvars.words[1] == "clear") and chatvars.words[2] == "master" and chatvars.words[3] == "password" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "clear" then
				server.masterPassword = ""
				conn:execute("UPDATE server SET masterPassword = ''")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have cleared the master password. Bot commands are only protected by access levels.[-]")
				else
					irc_chat(chatvars.ircAlias, "You have cleared the master password. Bot commands are only protected by access levels.")
				end
			else
				server.masterPassword = string.sub(chatvars.commandOld, string.find(chatvars.command, "master password") + 16)
				conn:execute("UPDATE server SET masterPassword = '" .. escape(server.masterPassword) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have set a password to protect important bot commands.[-]")
				else
					irc_chat(chatvars.ircAlias, "You have set a password to protect important bot commands.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetTelnetLogKeepDays()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set max log days {number}"
			help[2] = "The default is 14 days. Setting this too long will result in lots of log files on disk.\n"
			help[2] = help[2] .. "To prevent this causing issues on my hosted bots, the max you can set this is 60 days.\n"
			help[2] = help[2] .. "To set it higher you need to edit telnetlogkeepdays in the server table in the database."

			tmp.command = help[1]
			tmp.keywords = "bot,set,telnet,log,max,days"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "set") or string.find(chatvars.command, "log") or string.find(chatvars.command, "telnet") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "set max log day") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A number is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "A number is required.")
				end

				botman.faultyChat = false
				return true
			end

			chatvars.number = math.abs(chatvars.number)

			server.telnetLogKeepDays = chatvars.number
			if botman.dbConnected then conn:execute("UPDATE server SET telnetLogKeepDays = " .. chatvars.number) end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will keep logs for " .. server.telnetLogKeepDays .. " days. Some logs (eg. chat) are kept forever.[-]")
			else
				irc_chat(chatvars.ircAlias, "The bot will keep logs for " .. server.telnetLogKeepDays .. " days. Some logs (eg. chat) are kept forever.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetWebToken()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set web token {user} password {password}"
			help[2] = "If you have set a web token on the server for the bot to use, you can tell the bot the user and password with this command."

			tmp.command = help[1]
			tmp.keywords = "bot,set,web,token,user,password,api"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "set") or string.find(chatvars.command, "web") or string.find(chatvars.command, "token") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "set web token") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.webToken = string.sub(chatvars.commandOld, string.find(chatvars.command, " token ") + 7, string.find(chatvars.command, " password") - 1)
			tmp.webTokenPassword = string.sub(chatvars.commandOld, string.find(chatvars.command, " password ") + 10)
			display(tmp)

			server.allocsWebAPIUser = tmp.webToken
			server.allocsWebAPIPassword = tmp.webTokenPassword

			if botman.dbConnected then conn:execute("UPDATE server SET allocsWebAPIUser = '" .. escape(server.allocsWebAPIUser) .. "', allocsWebAPIPassword = '" .. escape(server.allocsWebAPIPassword) .. "'") end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have told the bot a new web token. This command does not add or change the web token on the server and doesn't tell the bot to start using it.[-]")
			else
				irc_chat(chatvars.ircAlias, "You have told the bot a new web token. This command does not add or change the web token on the server and doesn't tell the bot to start using it.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetUpdateBranch()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set update branch"
			help[2] = "Bot updates are released in code branches such as stable and testing.  The stable branch will not update as often and should have less issues than testing.\n"
			help[2] = help[2] .. "New and trial features will release to testing before stable. Important fixes will be ported to stable from testing whenever possible.\n"
			help[2] = help[2] .. "You can switch between branches as often as you want.  Any changes in testing that are not in stable will never break stable should you switch back to it."

			tmp.command = help[1]
			tmp.keywords = "bot,set,update,branch,code"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "upd") or string.find(chatvars.command, "set") or string.find(chatvars.command, "branch") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and (chatvars.words[2] == "update" or chatvars.words[2] == "code") and chatvars.words[3] == "branch" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[4] ~= "" then
				server.updateBranch = chatvars.words[4]
				conn:execute("UPDATE server set updateBranch = '" .. chatvars.words[4] .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will check for updates from the " .. chatvars.words[4] .. " branch.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will check for updates from the " .. chatvars.words[4] .. " branch.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShutdownBot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}shutdown bot"
			help[2] = "While not essential as it seems to work just fine, you can tell the bot to save all pending player data, before you quit Mudlet."
			help[2] = help[2] .. "Note: This doesn't actually stop the bot. It only ensures that everything has been saved so you can manually shutdown Mudlet."

			tmp.command = help[1]
			tmp.keywords = "bot,shutdown,stop"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "shut") or string.find(chatvars.command, "stop") or string.find(chatvars.command, "bot") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "shutdown" and chatvars.words[2] == "bot") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			irc_chat(server.ircMain, "Saving player data.  Wait a minute before stopping Mudlet or until I say I'm ready.")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Saving player data.  Wait a minute before stopping Mudlet or until the bot says it is ready.[-]")
				shutdownBot(chatvars.playerid)
			else
				tempTimer( 3, [[shutdownBot(0)]] ) -- This timer is necessary to stop Mudlet freezing.  It doesn't seem to like running this function as server immediately but is fine with a delay.
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBeQuietBot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set bot chatty/quiet"
			help[2] = "If you want to stop the bot responding to 'hi bot' and be more utilitarian, you can set the bot to be quiet."

			tmp.command = help[1]
			tmp.keywords = "set,bot,chat,quiet,talk"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "set") or string.find(chatvars.command, "bot") or string.find(chatvars.command, "chat") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "bot" and (chatvars.words[3] == "chatty" or chatvars.words[3] == "quiet") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[3] == "quiet" then
				server.beQuietBot = true
				if botman.dbConnected then conn:execute("UPDATE server SET beQuietBot = 1") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will not talk back to players except to provide information.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will not talk back to players except to provide information.")
				end
			else
				server.beQuietBot = false
				if botman.dbConnected then conn:execute("UPDATE server SET beQuietBot = 0") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will answer players that talk to it with random silly responses.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will answer players that talk to it with random silly responses.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBotRestart()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) bot restart"
			help[2] = "Using a launcher script or some other monitoring process you can have the bot automatically restart itself every time it terminates.\n"
			help[2] = help[2] .. "Periodically restarting the bot helps to keep it running at its best.\n"
			help[2] = help[2] .. "This feature is disabled by default.  A restart script can be downloaded from https://botman.nz/shellscripts.zip\n"
			help[2] = help[2] .. "You will need to inspect and modify some paths in the scripts to match your setup."

			tmp.command = help[1]
			tmp.keywords = "bot,enable,disable,restart,stop"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "bot") or string.find(chatvars.command, "start") or string.find(chatvars.command, "able") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "able") and chatvars.words[2] == "bot" and string.find(chatvars.command, "restart") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.allowBotRestarts = true
				conn:execute("UPDATE server SET allowBotRestarts = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You will be able to restart the bot with the command " .. server.commandPrefix .. "restart bot.[-]")
				else
					irc_chat(chatvars.ircAlias, "You will be able to restart the bot with the command " .. server.commandPrefix .. "restart bot.")
				end
			else
				server.allowBotRestarts = false
				conn:execute("UPDATE server SET allowBotRestarts = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The command " .. server.commandPrefix .. "restart bot, will not do anything.[-]")
				else
					irc_chat(chatvars.ircAlias, "The command " .. server.commandPrefix .. "restart bot, will not do anything.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBotUpdates()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) updates (disabled by default)"
			help[2] = "Allow the bot to automatically update itself by downloading scripts. It will check daily, but you can also command it to check immediately with {#}update bot"

			tmp.command = help[1]
			tmp.keywords = "bot,enable,disable,updates"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "able") or string.find(chatvars.command, "upd") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "updates" and chatvars.words[3] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.updateBot = true
				conn:execute("UPDATE server set updateBot = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will automatically update itself daily if newer scripts are available.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will automatically update itself daily if newer scripts are available.")
				end
			else
				server.updateBot = false
				conn:execute("UPDATE server set updateBot = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will not update automatically.  You will see an alert on IRC if an update is available.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will not update automatically.  You will see an alert on IRC if an update is available.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleCheckLevelHack()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) level hack check"
			help[2] = "Hackers can give themselves XP but normal play and/or game bugs can also cause large level changes.\n"
			help[2] = help[2] .. "The level check could falsely report legit level changes as hacking so this is disabled by default.\n"
			help[2] = help[2] .. "If you enable it and innocent players get banned, either unban them or turn it off again."

			tmp.command = help[1]
			tmp.keywords = "bot,enable,disable,level,hack,check"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "hack") or string.find(chatvars.command, "level") or string.find(chatvars.command, "able") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "level" and chatvars.words[3] == "hack" and chatvars.words[4] == "check" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "disable" then
				server.checkLevelHack = false
				if botman.dbConnected then conn:execute("UPDATE server SET checkLevelHack = 0") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Level hack detection is disabled.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Level hack detection is disabled.")
				end
			end

			if chatvars.words[1] == "enable" then
				server.checkLevelHack = true
				if botman.dbConnected then conn:execute("UPDATE server SET checkLevelHack = 1") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Level hack detection is enabled.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Level hack detection is enabled.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBotChatColours()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) bot colours (default enabled)"
			help[2] = "If you want something else managing chat colours you can stop the bot replacing them by disabling that feature with this command."

			tmp.command = help[1]
			tmp.keywords = "bot,enable,disable,chat,colours,colors"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo") or string.find(chatvars.command, "able") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "bot" and string.find(chatvars.words[3], "colo") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "disable" then
				modBotman.disableChatColours = true
				if botman.dbConnected then conn:execute("UPDATE modBotman SET disableChatColours = 1") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will not set chat colours for players but messages from the bot will still be coloured by the bot.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will not set chat colours for players but messages from the bot will still be coloured by the bot.")
				end
			end

			if chatvars.words[1] == "enable" then
				modBotman.disableChatColours = false
				if botman.dbConnected then conn:execute("UPDATE modBotman SET disableChatColours = 0") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will colour player chat.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will colour player chat.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleHackerTPDetection()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) hacker tp detection"
			help[2] = "Some mods or managers don't report legit teleports to telnet which breaks the bot's hacker teleport detection.\n"
			help[2] = help[2] .. "If the bot doesn't automatically disable/enable hacker tp detection, you can manually change it."

			tmp.command = help[1]
			tmp.keywords = "bot,enable,disable,protection,hack,teleport"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "hack") or string.find(chatvars.command, "tele") or string.find(chatvars.command, "able") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "hacker" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "disable" then
				server.hackerTPDetection = false
				if botman.dbConnected then conn:execute("UPDATE server SET hackerTPDetection = 0") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Hacker teleport detection is disabled.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Hacker teleport detection is disabled.")
				end
			end

			if chatvars.words[1] == "enable" then
				server.hackerTPDetection = true
				if botman.dbConnected then conn:execute("UPDATE server SET hackerTPDetection = 1") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Hacker teleport detection is enabled.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Hacker teleport detection is enabled.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleHideUnknownCommand()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}show (or {#}hide) unknown command"
			help[2] = "If the bot doesn't recognise a command it will respond with 'Unknown command'.  You can hide that message if you want."

			tmp.command = help[1]
			tmp.keywords = "bot,show,hide,unknown,command"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "show") or string.find(chatvars.command, "hide") or string.find(chatvars.command, "unkno") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "show" or chatvars.words[1] == "hide") and chatvars.words[2] == "unknown" and chatvars.words[3] == "command" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "hide" then
				server.hideUnknownCommand = true
				if botman.dbConnected then conn:execute("UPDATE server SET hideUnknownCommand = 1") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will not respond if it doesn't recognise a command.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will not respond if it doesn't recognise a command.")
				end
			else
				server.hideUnknownCommand = false
				if botman.dbConnected then conn:execute("UPDATE server SET hideUnknownCommand = 0") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will respond with 'Unknown command' if it doesn't recognise a command.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will respond with 'Unknown command' if it doesn't recognise a command.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleHideDisabledCommand()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}show (or {#}hide) disabled command"
			help[2] = "If you use another manager for some commands and both use the same command prefix and you have disabled some bot commands, the bot will tell players that a command is disabled.  You can stop the bot responding at all by hiding bot responses like 'This command is disabled'.\n"
			help[2] = help[2] .. "Note that this will suppress that response for all disabled bot commands and is not aware what if any commands are handled by another manager or mod."

			tmp.command = help[1]
			tmp.keywords = "bot,show,hide,disabled,command"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "show") or string.find(chatvars.command, "hide") or string.find(chatvars.command, "disab") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "show" or chatvars.words[1] == "hide") and chatvars.words[2] == "disabled" and chatvars.words[3] == "command" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "hide" then
				server.suppressDisabledCommand = true
				if botman.dbConnected then conn:execute("UPDATE server SET suppressDisabledCommand = 1") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will not respond for disabled commands.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will not respond for disabled commands.")
				end
			else
				server.suppressDisabledCommand = false
				if botman.dbConnected then conn:execute("UPDATE server SET suppressDisabledCommand = 0") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will tell players if a command is disabled.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will tell players if a command is disabled.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLogBotCommands()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) bot command log (disabled by default)"
			help[2] = "For debugging purposes, commands sent to the server by the bot can be logged just like player commands but to its own log file.\n"
			help[2] = help[2] .. "This will include sensitive information such as passwords so don't enable this if anyone has access to it that you don't want reading it.\n"
			help[2] = help[2] .. "Only server owners can enable this log."

			tmp.command = help[1]
			tmp.keywords = "bot,enable,disable,command,log"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "able") or string.find(chatvars.command, "log") or string.find(chatvars.command, "bot") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "bot" and chatvars.words[3] == "command" and chatvars.words[4] == "log" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.logBotCommands = true
				conn:execute("UPDATE server set logBotCommands = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Commands sent to the server by the bot will be logged.[-]")
				else
					irc_chat(chatvars.ircAlias, "Commands sent to the server by the bot will be logged.")
				end
			else
				server.logBotCommands = false
				conn:execute("UPDATE server set logBotCommands = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Commands from the bot will not be logged.[-]")
				else
					irc_chat(chatvars.ircAlias, "Commands from the bot will not be logged.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLogInventory()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) inventory log. (disabled by default)"
			help[2] = "The bot logs inventory and inventory changes to the database all the time.  You can also have inventory changes recorded to a daily text file along with the other daily logs."

			tmp.command = help[1]
			tmp.keywords = "bot,enable,disable,inventory,log"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "able") or string.find(chatvars.command, "log") or string.find(chatvars.command, "inv") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "inventory" and string.find(chatvars.words[3], "log") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.logInventory = true
				conn:execute("UPDATE server set logInventory = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Live inventory changes will also be logged to daily text files.[-]")
				else
					irc_chat(chatvars.ircAlias, "Live inventory changes will also be logged to daily text files.")
				end
			else
				server.logInventory = false
				conn:execute("UPDATE server set logInventory = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Live inventory changes will only be recorded in the database.[-]")
				else
					irc_chat(chatvars.ircAlias, "Live inventory changes will only be recorded in the database.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleReadLogUsingTelnet()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}read log using telnet (default)\n"
			help[1] = help[1] .. " {#}read log using api"
			help[2] = "Due to ongoing issues with the API log reader skipping lines the default is that in API mode, the bot will monitor the server via telnet.\n"
			help[2] = help[2] .. "If telnet is disabled or you tell the bot to read the log using the API, then it will monitor the server via the API."

			tmp.command = help[1]
			tmp.keywords = "toggle,on,off,enable,disable,api,telnet,log,read"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "log") or string.find(chatvars.command, "api") or string.find(chatvars.command, "telnet") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "read" and chatvars.words[2] == "log" and chatvars.words[3] == "using" and chatvars.words[4] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[4] == "telnet" then
				server.readLogUsingTelnet = true
				conn:execute("UPDATE server set readLogUsingTelnet = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will monitor telnet for server activity.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will monitor telnet for server activity.")
				end
			else
				server.readLogUsingTelnet = false
				conn:execute("UPDATE server set readLogUsingTelnet = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will use the API to monitor server activity.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will use the API to monitor server activity.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleUseAllocsWebAPI() -- tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}use telnet (this is the default now but the API is planned to become the new default soon)\n"
			help[1] = help[1] .. " {#}use api"
			help[2] =  "The bot communicates with the server using telnet. It can use Allocs web API instead."

			tmp.command = help[1]
			tmp.keywords = "bot,toggle,on,off,enable,disable,web,api,telnet,read"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "web") or string.find(chatvars.command, "api") or string.find(chatvars.command, "telnet") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "use" and (chatvars.words[2] == "telnet" or string.find(chatvars.command, "api")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == "telnet" then
				server.useAllocsWebAPI = false
				conn:execute("UPDATE server set useAllocsWebAPI = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot is now using telnet.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot is now using telnet.")
				end
			else
				if tonumber(server.webPanelPort) == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You must first set the web panel port. This is normally port 8080 but yours may be different.  To set it type {#}set web panel port {the port number} or just restart the server.[-]")
					else
						irc_chat(chatvars.ircAlias, "You must first set the web panel port. This is normally port 8080 but yours may be different.  To set it type {#}set web panel port {the port number} or just restart the server.")
					end

					botman.faultyChat = false
					return true
				end

				connectToAPI()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UpdateCode()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}update code"
			help[2] = "Make the bot check for script updates.  They will be installed if you have set {#}enable updates"

			tmp.command = help[1]
			tmp.keywords = "bot,update,code"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "update") or string.find(chatvars.command, "code") or string.find(chatvars.command, "script") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "update" and (chatvars.words[2] == "code" or chatvars.words[2] == "scripts" or words[2] == "bot") and chatvars.words[3] == nil then
			if (chatvars.playername ~= "Server") then
				if (not chatvars.isAdminHidden) then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				-- allow from irc
			end

			updateBot(true, chatvars.playerid)

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	if botman.registerHelp then
		if debug then dbug("Registering help - bot commands") end

		tmp.topicDescription = "Commands in this section are commands that alter settings relating to the bot itself."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Bot Commands:")
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

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "bot" then
				botman.faultyChat = false
				return true, ""
			end
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and chatvars.words[1] ~= "help" and not botman.registerHelp then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Bot Commands:")
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "These commands are for bot specific settings.")
		irc_chat(chatvars.ircAlias, ".")
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "bot")
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ApproveGlobalBan()

	if result then
		if debug then dbug("debug cmd_ApproveGlobalBan triggered") end
		return result, "cmd_ApproveGlobalBan"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_BackupBot()

	if result then
		if debug then dbug("debug cmd_BackupBot triggered") end
		return result, "cmd_BackupBot"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClearBotsWhitelist()

	if result then
		if debug then dbug("debug cmd_ClearBotsWhitelist triggered") end
		return result, "cmd_ClearBotsWhitelist"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ForgetPlayers()

	if result then
		if debug then dbug("debug cmd_ForgetPlayers triggered") end
		return result, "cmd_ForgetPlayers"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_GuessPassword()

	if result then
		if debug then dbug("debug cmd_GuessPassword triggered") end
		return result, "cmd_GuessPassword"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBackups()

	if result then
		if debug then dbug("debug cmd_ListBackups triggered") end
		return result, "cmd_ListBackups"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListChatColours()

	if result then
		if debug then dbug("debug cmd_ListChatColours triggered") end
		return result, "cmd_ListChatColours"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_QuickResetBot()

	if result then
		if debug then dbug("debug cmd_QuickResetBot triggered") end
		return result, "cmd_QuickResetBot"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_RefreshCode()

	if result then
		if debug then dbug("debug cmd_RefreshCode triggered") end
		return result, "cmd_RefreshCode"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_RejoinIRC()

	if result then
		if debug then dbug("debug cmd_RejoinIRC triggered") end
		return result, "cmd_RejoinIRC"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReloadBot()

	if result then
		if debug then dbug("debug cmd_ReloadBot triggered") end
		return result, "cmd_ReloadBot"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetBases()

	if result then
		if debug then dbug("debug cmd_ResetBases triggered") end
		return result, "cmd_ResetBases"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetBot()

	if result then
		if debug then dbug("debug cmd_ResetBot triggered") end
		return result, "cmd_ResetBot"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_RestartBot()

	if result then
		if debug then dbug("debug cmd_RestartBot triggered") end
		return result, "cmd_RestartBot"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_RestoreBackup()

	if result then
		if debug then dbug("debug cmd_RestoreBackup triggered") end
		return result, "cmd_RestoreBackup"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetAPILogPollingInterval()

	if result then
		if debug then dbug("debug cmd_SetAPILogPollingInterval triggered") end
		return result, "cmd_SetAPILogPollingInterval"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBlacklistResponse()

	if result then
		if debug then dbug("debug cmd_SetBlacklistResponse triggered") end
		return result, "cmd_SetBlacklistResponse"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotAlertColour()

	if result then
		if debug then dbug("debug cmd_SetBotAlertColour triggered") end
		return result, "cmd_SetBotAlertColour"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotChatColour()

	if result then
		if debug then dbug("debug cmd_SetBotChatColour triggered") end
		return result, "cmd_SetBotChatColour"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotLogLevel()

	if result then
		if debug then dbug("debug cmd_SetBotLogLevel triggered") end
		return result, "cmd_SetBotLogLevel"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotName()

	if result then
		if debug then dbug("debug cmd_SetBotName triggered") end
		return result, "cmd_SetBotName"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotNameColour()

	if result then
		if debug then dbug("debug cmd_SetBotNameColour triggered") end
		return result, "cmd_SetBotNameColour"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotRestartDay()

	if result then
		if debug then dbug("debug cmd_SetBotRestartDay triggered") end
		return result, "cmd_SetBotRestartDay"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetTelnetSpamTrigger()

	if result then
		if debug then dbug("debug cmd_SetTelnetSpamTrigger triggered") end
		return result, "cmd_SetTelnetSpamTrigger"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotWarningColour()

	if result then
		if debug then dbug("debug cmd_SetBotWarningColour triggered") end
		return result, "cmd_SetBotWarningColour"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetCommandPrefix()

	if result then
		if debug then dbug("debug cmd_SetCommandPrefix triggered") end
		return result, "cmd_SetCommandPrefix"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMasterPassword()

	if result then
		if debug then dbug("debug cmd_SetMasterPassword triggered") end
		return result, "cmd_SetMasterPassword"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetTelnetLogKeepDays()

	if result then
		if debug then dbug("debug cmd_SetTelnetLogKeepDays triggered") end
		return result, "cmd_SetTelnetLogKeepDays"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWebToken()

	if result then
		if debug then dbug("debug cmd_SetWebToken triggered") end
		return result, "cmd_SetWebToken"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetUpdateBranch()

	if result then
		if debug then dbug("debug cmd_SetUpdateBranch triggered") end
		return result, "cmd_SetUpdateBranch"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShutdownBot()

	if result then
		if debug then dbug("debug cmd_ShutdownBot triggered") end
		return result, "cmd_ShutdownBot"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_Timers()

	if result then
		if debug then dbug("debug cmd_Timers triggered") end
		return result, "cmd_Timers"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBeQuietBot()

	if result then
		if debug then dbug("debug cmd_ToggleBeQuietBot triggered") end
		return result, "cmd_ToggleBeQuietBot"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBotRestart()

	if result then
		if debug then dbug("debug cmd_ToggleBotRestart triggered") end
		return result, "cmd_ToggleBotRestart"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBotUpdates()

	if result then
		if debug then dbug("debug cmd_ToggleBotUpdates triggered") end
		return result, "cmd_ToggleBotUpdates"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleCheckLevelHack()

	if result then
		if debug then dbug("debug cmd_ToggleCheckLevelHack triggered") end
		return result, "cmd_ToggleCheckLevelHack"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBotChatColours()

	if result then
		if debug then dbug("debug cmd_ToggleBotChatColours triggered") end
		return result, "cmd_ToggleBotChatColours"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleHackerTPDetection()

	if result then
		if debug then dbug("debug cmd_ToggleHackerTPDetection triggered") end
		return result, "cmd_ToggleHackerTPDetection"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleHideUnknownCommand()

	if result then
		if debug then dbug("debug cmd_ToggleHideUnknownCommand triggered") end
		return result, "cmd_ToggleHideUnknownCommand"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleHideDisabledCommand()

	if result then
		if debug then dbug("debug cmd_ToggleHideDisabledCommand triggered") end
		return result, "cmd_ToggleHideDisabledCommand"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLogBotCommands()

	if result then
		if debug then dbug("debug cmd_ToggleLogBotCommands triggered") end
		return result, "cmd_ToggleLogBotCommands"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLogInventory()

	if result then
		if debug then dbug("debug cmd_ToggleLogInventory triggered") end
		return result, "cmd_ToggleLogInventory"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleReadLogUsingTelnet()

	if result then
		if debug then dbug("debug cmd_ToggleReadLogUsingTelnet triggered") end
		return result, "cmd_ToggleReadLogUsingTelnet"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleUseAllocsWebAPI()

	if result then
		if debug then dbug("debug cmd_ToggleUseAllocsWebAPI triggered") end
		return result, "cmd_ToggleUseAllocsWebAPI"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_UpdateCode()

	if result then
		if debug then dbug("debug cmd_UpdateCode triggered") end
		return result, "cmd_UpdateCode"
	end

	if debug then dbug("debug bot end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == "0" and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false, ""
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if chatvars.showHelp and chatvars.words[1] ~= "help" and not botman.registerHelp then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Bot Commands (In-Game Only):")
		irc_chat(chatvars.ircAlias, ".")
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_NoReset()

	if result then
		if debug then dbug("debug cmd_NoReset triggered") end
		return result, "cmd_NoReset"
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetServer()

	if result then
		if debug then dbug("debug cmd_ResetServer triggered") end
		return result, "cmd_ResetServer"
	end

	if botman.registerHelp then
		if debug then dbug("Bot commands help registered") end
	end

	if debug then dbug("debug bot end") end

	-- can't touch dis
	if true then
		return result, ""
	end
end
