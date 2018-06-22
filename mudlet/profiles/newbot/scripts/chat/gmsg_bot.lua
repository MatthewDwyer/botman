--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local tmp, debug, pname, pid, result, help
local shortHelp = false
local skipHelp = false

function gmsg_bot()
	calledFunction = "gmsg_bot"
	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## Bot command functions ##################

	local function cmd_ApproveGlobalBan()
		local playerName

		if chatvars.words[1] == "approve" and chatvars.words[2] == "gblban" and chatvars.words[3] ~= nil then
			if (chatvars.playerid ~= "Server") then
				if (chatvars.playerid ~= Smegz0r and chatvars.ircid ~= Smegz0r) then
					message(string.format("pm %s [%s]This command can only be used by Smegz0r. Get your own :P", chatvars.playerid, server.chatColour))
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
			id = LookupPlayer(pname)

			if id ~= 0 then
				-- don't ban if player is an admin :O
				if accessLevel(id) < 3 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You what?  You want to global ban one of the admins?   [DENIED][-]")
					else
						irc_chat(chatvars.ircAlias, "You what?  You want to global ban one of the admins?   [DENIED]")
					end

					botman.faultyChat = false
					return true
				else
					playerName = players[id].name
				end
			else
				id = LookupArchivedPlayer(pname)

				if id == 0 then
					-- pname must be a steam id
					id = pname
					playerName = id
				else
					playerName = playersArchived[id].name
				end
			end

			connBots:execute("UPDATE bans set GBLBan = 1, GBLBanVetted = 1, GBLBanActive = 1 WHERE steam = " .. id)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. "'s global ban has been approved.[-]")
			else
				irc_chat(chatvars.ircAlias, playername .. "'s global ban has been approved.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ClearBotsWhitelist()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}clear whitelist"
			help[2] = "Remove everyone from the bot's whitelist."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,clear,white,list"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			conn:execute("TRUNCATE TABLE whitelist")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The whitelist has been cleared.[-]")
			else
				irc_chat(chatvars.ircAlias, "The whitelist has been cleared.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GuessPassword()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}password {some password or phrase}"
			help[2] = "If you have set a master password, some bot commands will issue a password challenge.  Use this command to send the password to the bot."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,pass"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pass"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "password") and (chatvars.words[2] ~= nil) and (chatvars.accessLevel < 3) then
			local response

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

			if chatvars.ircid ~= 0 then
				id = chatvars.ircid
			else
				id = chatvars.playerid
			end

			if string.sub(chatvars.commandOld, string.find(chatvars.command, "password") + 9) ~= server.masterPassword then
				response = "password attempt failed."

				r = rand(10)
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. response .. "[-]")
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

				 if players[id].botQuestion == "restart bot" and (chatvars.accessLevel < 3) then
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
					QuickBotReset()

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


	local function cmd_NoReset()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}no reset"
			help[2] = "If the bot detects that the server days have rolled back, it will ask you if you want to reset the bot.  Type {#}no reset if you don't want the bot to reset itself."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,reset"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "no") and (chatvars.words[2] == "reset") then
			if chatvars.accessLevel > 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Oh ok then.[-]")
			server.warnBotReset = false

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_QuickResetBot()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}quick reset bot"
			help[2] = "Tell the bot to forget only some things, some player info, locations, bases etc.  You will be asked to confirm this, answer with yes.  Say anything else to abort.\n"
			help[2] = help[2] .. "Use this command after wiping the server.  The bot will detect the day change and will ask if you want to reset the bot too."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,reset"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "bot"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "quick") and (chatvars.words[2] == "reset") and (chatvars.words[3] == "bot") then
			if chatvars.accessLevel > 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end

			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Are you sure you want to reset me?  Answer yes to proceed or anything else to cancel.[-]")
			players[chatvars.playerid].botQuestion = "quick reset bot"

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RefreshCode()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}refresh code"
			help[2] = "Make the bot re-download and install from the current code branch for script updates.  Only necessary if someone has edited the code and needs to restore it."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,refr,code"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "refresh") or string.find(chatvars.command, "code") or string.find(chatvars.command, "script"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "refresh" and (chatvars.words[2] == "code" or chatvars.words[2] == "scripts" or words[2] == "bot") and chatvars.words[3] == nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				-- allow from irc
			end

			botman.refreshCode = true
			updateBot(true, chatvars.playerid)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RejoinIRC()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}rejoin irc"
			help[2] = "Sometimes the bot can fall off IRC and fail to reconnect.  This command forces it to reconnect."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,irc,web"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "irc")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "rejoin" or chatvars.words[1] == "reconnect") and chatvars.words[2] == "irc" then
			-- join (or rejoin) the irc server incase the bot has fallen off and failed to reconnect
			if botman.customMudlet then
				joinIRCServer()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReloadBot()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reload bot"
			help[2] = "Make the bot read several things from the server including admin list, ban list, gg, lkp and others.  If you have Coppi's Mod installed it will also detect that."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,real,load,refr,init"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "reload bot")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "reload" or chatvars.words[1] == "refresh" or chatvars.words[1] == "update") and chatvars.words[2] == "bot" then
			-- run admin list, gg, ban list and lkp

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Refreshing admins, bans, server config from server.[-]")
			else
				irc_chat(chatvars.ircAlias, "Refreshing admins, bans, server config from server.")
			end

			send("lkp -online")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			send("version")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			--tempTimer( 4, [[message("say [" .. server.chatColour .. "]Reading admin list[-]")]] )
			tempTimer( 4, [[send("admin list")]] )

			--tempTimer( 6, [[message("say [" .. server.chatColour .. "]Reading bans[-]")]] )
			tempTimer( 6, [[send("ban list")]] )

			--tempTimer( 8, [[message("say [" .. server.chatColour .. "]Reading server config[-]")]] )
			tempTimer( 8, [[send("gg")]] )

			--tempTimer( 10, [[message("say [" .. server.chatColour .. "]Reading claims[-]")]])
			tempTimer( 10, [[send("llp)]] )

			tempTimer( 13, [[send("pm IPCHECK")]] )
			--tempTimer( 13, [[message("say [" .. server.chatColour .. "]Reload complete.[-]")]] )

			tempTimer( 15, [[send("teleh")]] )
			tempTimer( 20, [[registerBot()]] )

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 6
			end

			botman.faultyChat = false
			return true
		end
	end



	local function cmd_ResetBot()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reset bot\n"
			help[1] = help[1] .. " {#}reset bot keep money"
			help[2] = "Tell the bot to forget only some things, some player info, locations, bases etc.  You will be asked to confirm this, answer with yes.  Say anything else to abort.\n"
			help[2] = help[2] .. "Use this command after wiping the server.  The bot will detect the day change and will ask if you want to reset the bot too."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,reset"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "bot"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "reset" and chatvars.words[2] == "bot" and chatvars.words[3] == "keep" and (chatvars.words[4] == "money" or chatvars.words[4] == "cash" or chatvars.words[4] == server.moneyName or chatvars.words[4] == server.moneyPlural) then
			if chatvars.accessLevel > 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end

			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Are you sure you want to reset me?  Answer yes to proceed or anything else to cancel.[-]")
			players[chatvars.playerid].botQuestion = "reset bot keep money"

			botman.faultyChat = false
			return true
		end

		if (chatvars.words[1] == "reset") and (chatvars.words[2] == "bot") and (chatvars.playerid ~= 0) then
			if chatvars.accessLevel > 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end

			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Are you sure you want to reset me?  Answer yes to proceed or anything else to cancel.[-]")
			players[chatvars.playerid].botQuestion = "reset bot"

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetServer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reset server"
			help[2] = "Tell the bot to forget everything it knows about the server.  You will be asked to confirm this, answer with yes.  Say anything else to abort.\n"
			help[2] = help[2] .. "Usually you only need to use {#}reset bot.  This reset goes further."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,reset,server"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "server"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "reset") and (chatvars.words[2] == "server") then
			if chatvars.accessLevel > 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end

			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Are you sure you want to wipe me completely clean?  Answer yes to proceed or anything else to cancel.[-]")
			players[chatvars.playerid].botQuestion = "reset server"

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RestartBot()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}restart bot"
			help[2] = "If your Mudlet (the bot's engine) is set up to automatically restart itself you can command the bot to restart.  Also this feature must be enabled."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,rest,start"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rest") or string.find(chatvars.command, "bot"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "restart") and (chatvars.words[2] == "bot") and (chatvars.accessLevel < 3) then
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

			if not server.allowBotRestarts then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is disabled.  Enable it with /enable bot restart[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If you do not have a script or other process monitoring the bot, it will not restart automatically.[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Scripts can be downloaded at http://botman.nz/shellscripts.zip and may require some editing for paths.[-]")
				else
					irc_chat(chatvars.ircAlias, "This command is disabled.  Enable it with /enable bot restart")
					irc_chat(chatvars.ircAlias, "If you do not have a script or other process monitoring the bot, it will not restart automatically.")
					irc_chat(chatvars.ircAlias, "Scripts can be downloaded at http://botman.nz/shellscripts.zip and may require some editing for paths.")
				end

				botman.faultyChat = false
				return true
			end

			if botman.customMudlet then
				if server.masterPassword ~= "" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command requires a password to complete. Don't use this command unless you know what it does and why you need to do it.[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Type " .. server.commandPrefix .. "password {the password} (Do not type the {}).[-]")
						players[chatvars.playerid].botQuestion = "restart bot"
					else
						irc_chat(chatvars.ircAlias, "This command requires a password to complete. Don't use this command unless you know what it does and why you need to do it.")
						irc_chat(chatvars.ircAlias, "Type " .. server.commandPrefix .. "password {the password} (Do not type the {}).")
						players[chatvars.ircid].botQuestion = "restart bot"
					end
				else
					restartBot()
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is not supported in your Mudlet.  You need the latest custom Mudlet by TheFae or Mudlet 3.4[-]")
				else
					irc_chat(chatvars.ircAlias, "This command is not supported in your Mudlet.  You need the latest custom Mudlet by TheFae or Mudlet 3.4")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RestoreBackup()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}restore backup"
			help[2] = "The bot saves its Lua tables daily at midnight (server time) and each time the server is shut down.\n"
			help[2] = help[2] .. "If the bot gets messed up, you can try to fix it with this command. Other timestamped backups are made before the bot is reset but you will first need to strip the date part off them to restore with this command."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,rest,recov,fix"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "restore") or string.find(chatvars.command, "backup"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "restore" and (chatvars.words[2] == "backup" or chatvars.words[2] == "bot") and chatvars.words[3] == nil then
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

			if botman.lastDataImport == nil then
				botman.lastDataImport = os.time() - 2400
			end

			if (os.time() - botman.lastDataImport) > 1800 then
				importLuaData()
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The backup has been restored.[-]")
			else
				irc_chat(chatvars.ircAlias, "The backup has been restored.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBlacklistResponse()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}blacklist action ban (or exile or 'nothing')"
			help[2] = "Set what happens to blacklisted players.  The default is to ban them 10 years but if you create a location called exile, the bot can bannish them to there instead.  It acts like a prison.\n"
			help[2] = help[2] .. "To disable the blacklist, set action to the word nothing.\n"
			help[2] = help[2] .. "NOTE: If blacklist action is nothing, proxies won't trigger a ban or exile response either."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,black,list,act"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "black") or string.find(chatvars.command, " ban"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[3] == nil then
				chatvars.words[3] = "nothing"
			end

			if chatvars.words[3] ~= "exile" and chatvars.words[3] ~= "ban" and chatvars.words[3] ~= "nothing" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Expected ban, exile or nothing as 3rd word.[-]")
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. response .. "[-]")
			else
				irc_chat(chatvars.ircAlias, response)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBotAlertColour()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set alert colour {hex code}"
			help[2] = "Set the colour of server alert messages."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,set,colo,alert"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "alert") or string.find(chatvars.command, "colo"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "alert" and string.find(chatvars.words[3], "colo") then
			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Please specify a colour code. eg. FF0000[-]")
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
				message("pm " .. chatvars.playerid .. " [" .. server.alertColour .. "]You have changed the colour for alert messages from the bot.[-]")
			else
				irc_chat(chatvars.ircAlias, "You have changed the colour for alert messages from the bot.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBotChatColour()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set chat colour {hex code}"
			help[2] = "Set the colour of server messages.  Player chat will be the default colour."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,set,colo,chat"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "chat" and string.find(chatvars.words[3], "colo") then
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

			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Please specify a colour code. eg. FF0000[-]")
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have changed the bot's chat colour.[-]")
			else
				irc_chat(chatvars.ircAlias, "You have changed the bot's chat colour.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBotName()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}name bot {some cool name}"
			help[2] = "The default name is Bot.  Help give your bot a personality by giving it a name."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,set,name"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, " name") or string.find(chatvars.command, " bot"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			tmp = stripQuotes(string.sub(chatvars.commandOld, string.find(chatvars.commandOld, chatvars.words[2], nil, true) + 4, string.len(chatvars.commandOld)))
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
	end


	local function cmd_SetBotRestartDay()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set bot restart {0+} (total bot days running)"
			help[2] = "The bot can automatically restart itself after running for days. The restart helps fix issues and keeps the bot fresh.\n"
			help[2] = help[2] .. "The default is 7 days between bot restarts. You can disable it by setting it to 0. Also it will only activate if bot restarts are enabled."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,set,day,rest,start"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "restart") or string.find(chatvars.command, " bot")  or string.find(chatvars.command, " set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set") and (chatvars.words[2] == "bot") and (chatvars.words[3] == "restart") and (chatvars.accessLevel < 3) then
			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number of 0 or more is required.[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will quit and automatically restart after running for " .. server.botRestartDay .. " days.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will quit and automatically restart after running for " .. server.botRestartDay .. " days.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will run until manually stopped.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will run until manually stopped.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBotWarningColour()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set warn colour {hex code}"
			help[2] = "Set the colour of server warning messages."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,set,colo,warn"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "warn" and string.find(chatvars.words[3], "colo") then
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

			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Please specify a colour code. eg. FF0000[-]")
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
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You have changed the colour for warning messages from the bot.[-]")
			else
				irc_chat(chatvars.ircAlias, "You have changed the colour for warning messages from the bot.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetCommandPrefix()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set command prefix / (or no symbol or any symbol except \\ )"
			help[2] = "Change bot commands from using / to using nothing or another symbol."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,set,comm,pref,symb"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "prefix"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set" and chatvars.words[2] == "command" and chatvars.words[3] == "prefix") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			tmp.prefix = chatvars.words[4]

			if tmp.prefix == "\\" then
				irc_chat(server.ircMain, "The bot does not support commands using a \\ because it is a special character in Lua and will not display in chat.  Please choose another symbol.")
				return
			end

			if tmp.prefix ~= "" then
				server.commandPrefix = tmp.prefix
				conn:execute("UPDATE server SET commandPrefix = '" .. tmp.prefix .. "'")

				if (chatvars.playername ~= "Server") then
					message("say [" .. server.chatColour .. "]Commands now begin with a " .. server.commandPrefix .. ". To use commands such as who type " .. server.commandPrefix .. "who.[-]")
				else
					irc_chat(server.ircMain, "Ingame bot commands must now start with a " .. tmp.prefix)
				end

				send("tcch " .. tmp.prefix)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			else
				server.commandPrefix = ""
				conn:execute("UPDATE server SET commandPrefix = ''")

				if (chatvars.playername ~= "Server") then
					message("say [" .. server.chatColour .. "]Bot commands are now just text.  To use commands such as who simply type who.[-]")
				else
					irc_chat(server.ircMain, "Ingame bot commands do not use a prefix such as /  Instead just type the commands as words.")
				end

				send("tcch")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMasterPassword()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set master password {secret password up to 50 characters}"
			help[2] = "Protect important commands such as {#}reset bot with a password.\n"
			help[2] = help[2] .. "This will prevent you or another server owner from accidentally doing something stupid (hopefully).\n"
			help[2] = help[2] .. "To remove it use {#}clear master password."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,set,pass"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pass") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set" or chatvars.words[1] == "clear") and chatvars.words[2] == "master" and chatvars.words[3] == "password" then
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

			if chatvars.words[1] == "clear" then
				server.masterPassword = ""
				conn:execute("UPDATE server SET masterPassword = ''")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have cleared the master password. Bot commands are only protected by access levels.[-]")
				else
					irc_chat(chatvars.ircAlias, "You have cleared the master password. Bot commands are only protected by access levels.")
				end
			else
				server.masterPassword = string.sub(chatvars.commandOld, string.find(chatvars.command, "master password") + 16)
				conn:execute("UPDATE server SET masterPassword = '" .. escape(server.masterPassword) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have set a password to protect important bot commands.[-]")
				else
					irc_chat(chatvars.ircAlias, "You have set a password to protect important bot commands.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetUpdateBranch()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set update branch"
			help[2] = "Bot updates are released in code branches such as stable and testing.  The stable branch will not update as often and should have less issues than testing.\n"
			help[2] = help[2] .. "New and trial features will release to testing before stable. Important fixes will be ported to stable from testing whenever possible.\n"
			help[2] = help[2] .. "You can switch between branches as often as you want.  Any changes in testing that are not in stable will never break stable should you switch back to it."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,set,upd,branch,code"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "upd") or string.find(chatvars.command, "set") or string.find(chatvars.command, "branch"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[4] ~= "" then
				server.updateBranch = chatvars.words[4]
				conn:execute("UPDATE server set updateBranch = '" .. chatvars.words[4] .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will check for updates from the " .. chatvars.words[4] .. " branch.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will check for updates from the " .. chatvars.words[4] .. " branch.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShutdownBot()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}shutdown bot"
			help[2] = "While not essential as it seems to work just fine, you can tell the bot to save all pending player data, before you quit Mudlet."
			help[2] = help[2] .. "Note: This doesn't actually stop the bot. It only ensures that everything has been saved so you can manually shutdown Mudlet."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,shut,stop"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shut") or string.find(chatvars.command, "stop") or string.find(chatvars.command, "bot"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "shutdown" and chatvars.words[2] == "bot") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			irc_chat(server.ircMain, "Saving player data.  Wait a minute before stopping Mudlet or until I say I'm ready.")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Saving player data.  Wait a minute before stopping Mudlet or until the bot says it is ready.[-]")
				shutdownBot(chatvars.playerid)
			else
				tempTimer( 3, [[shutdownBot(0)]] ) -- This timer is necessary to stop Mudlet freezing.  It doesn't seem to like running this function as server immediately but is fine with a delay.
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBeQuietBot()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set bot chatty/quiet"
			help[2] = "If you want to stop the bot responding to 'hi bot' and be more utilitarian, you can set the bot to be quiet."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,bot,chat,quiet"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "bot") or string.find(chatvars.command, "chat"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "bot" and (chatvars.words[3] == "chatty" or chatvars.words[3] == "quiet") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			if chatvars.words[3] == "quiet" then
				server.beQuietBot = true
				if botman.dbConnected then conn:execute("UPDATE server SET beQuietBot = 1") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will not talk back to players except to provide information.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will not talk back to players except to provide information.")
				end
			else
				server.beQuietBot = false
				if botman.dbConnected then conn:execute("UPDATE server SET beQuietBot = 0") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will answer players that talk to it with random silly responses.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will answer players that talk to it with random silly responses.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBotRestart()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable bot restart"
			help[2] = "Using a launcher script or some other monitoring process you can have the bot automatically restart itself every time it terminates.\n"
			help[2] = help[2] .. "Periodically restarting the bot helps to keep it running at its best.\n"
			help[2] = help[2] .. "This feature is disabled by default.  A restart script can be downloaded from http://botman.nz/shellscripts.zip\n"
			help[2] = help[2] .. "You will need to inspect and modify some paths in the scripts to match your setup."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,able,rest,start,stop"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bot") or string.find(chatvars.command, "start") or string.find(chatvars.command, "able"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.command, "able") and chatvars.words[2] == "bot" and string.find(chatvars.command, "restart") then
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
				server.allowBotRestarts = true
				conn:execute("UPDATE server SET allowBotRestarts = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will be able to restart the bot with the command " .. server.commandPrefix .. "restart bot.[-]")
				else
					irc_chat(chatvars.ircAlias, "You will be able to restart the bot with the command " .. server.commandPrefix .. "restart bot.")
				end
			else
				server.allowBotRestarts = false
				conn:execute("UPDATE server SET allowBotRestarts = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The command " .. server.commandPrefix .. "restart bot, will not do anything.[-]")
				else
					irc_chat(chatvars.ircAlias, "The command " .. server.commandPrefix .. "restart bot, will not do anything.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBotUpdates()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable updates (disabled by default)"
			help[2] = "Allow the bot to automatically update itself by downloading scripts. It will check daily, but you can also command it to check immediately with {#}update bot"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,able,upd"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "able") or string.find(chatvars.command, "upd"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
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
					irc_chat(chatvars.ircAlias, "The bot will automatically update itself daily if newer scripts are available.")
				end
			else
				server.updateBot = false
				conn:execute("UPDATE server set updateBot = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will not update automatically.  You will see an alert on IRC if an update is available.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will not update automatically.  You will see an alert on IRC if an update is available.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleCheckLevelHack()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable level hack check"
			help[2] = "Hackers can give themselves XP but normal play and/or game bugs can also cause large level changes.\n"
			help[2] = help[2] .. "The level check could falsely report legit level changes as hacking so this is disabled by default.\n"
			help[2] = help[2] .. "If you enable it and innocent players get banned, either unban them or turn it off again."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,able,level,hack"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hack") or string.find(chatvars.command, "level") or string.find(chatvars.command, "able"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "level" and chatvars.words[3] == "hack" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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
				server.checkLevelHack = false
				if botman.dbConnected then conn:execute("UPDATE server SET checkLevelHack = 0") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Level hack detection is disabled.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Level hack detection is disabled.")
				end
			end

			if chatvars.words[1] == "enable" then
				server.checkLevelHack = true
				if botman.dbConnected then conn:execute("UPDATE server SET checkLevelHack = 1") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Level hack detection is enabled.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Level hack detection is enabled.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleHackerTPDetection()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable hacker tp detection"
			help[2] = "Some mods or managers don't report legit teleports to telnet which breaks the bot's hacker teleport detection.\n"
			help[2] = help[2] .. "If the bot doesn't automatically disable/enable hacker tp detection, you can manually change it."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,able,prot,hack"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hack") or string.find(chatvars.command, "tele") or string.find(chatvars.command, "able"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "hacker" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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
				server.hackerTPDetection = false
				if botman.dbConnected then conn:execute("UPDATE server SET hackerTPDetection = 0") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Hacker teleport detection is disabled.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Hacker teleport detection is disabled.")
				end
			end

			if chatvars.words[1] == "enable" then
				server.hackerTPDetection = true
				if botman.dbConnected then conn:execute("UPDATE server SET hackerTPDetection = 1") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Hacker teleport detection is enabled.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Hacker teleport detection is enabled.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleHideUnknownCommand()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}show/hide unknown command"
			help[2] = "If the bot doesn't recognise a command it will respond with 'Unknown command'.  You can hide that message if you want."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,show,hide,unkno,comma"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "show") or string.find(chatvars.command, "hide") or string.find(chatvars.command, "unkno"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "show" or chatvars.words[1] == "hide") and chatvars.words[2] == "unknown" and chatvars.words[3] == "command" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			if chatvars.words[1] == "hide" then
				server.hideUnknownCommand = true
				if botman.dbConnected then conn:execute("UPDATE server SET hideUnknownCommand = 1") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will not respond if it doesn't recognise a command.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will not respond if it doesn't recognise a command.")
				end
			else
				server.hideUnknownCommand = false
				if botman.dbConnected then conn:execute("UPDATE server SET hideUnknownCommand = 0") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]The bot will respond with 'Unknown command' if it doesn't recognise a command.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "The bot will respond with 'Unknown command' if it doesn't recognise a command.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLagCheck()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable lag check (enabled by default)"
			help[2] = "Every 10 seconds while connected to the server, the bot sends a special lag check command to the server and times the response.\n"
			help[2] = help[2] .. "If the bot detects more than 10 seconds delay, it will automatically suspend several bot functions to reduce the number of commands that it sends to the server.\n"
			help[2] = help[2] .. "You can disable this check, but your bot won't pause for lag and the server could get significantly behind during busy times."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,able,lag,check"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "able") or string.find(chatvars.command, "lag"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "lag" then
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
				server.enableLagCheck = true
				conn:execute("UPDATE server set enableLagCheck = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will test for command lag and will suspend some bot functions when necessary.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will test for command lag and will suspend some bot functions when necessary.")
				end
			else
				server.enableLagCheck = false
				conn:execute("UPDATE server set enableLagCheck = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will not test for command lag. Server commands may be delayed during busy times.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will not test for command lag. Server commands may be delayed during busy times.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UpdateCode()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}update code"
			help[2] = "Make the bot check for script updates.  They will be installed if you have set {#}enable updates"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,upd,code"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "update") or string.find(chatvars.command, "code") or string.find(chatvars.command, "script"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "update" and (chatvars.words[2] == "code" or chatvars.words[2] == "scripts" or words[2] == "bot") and chatvars.words[3] == nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
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
		irc_chat(chatvars.ircAlias, "==== Registering help - bot commands ====")
		dbug("Registering help - bot commands")

		tmp = {}
		tmp.topicDescription = "Bot commands in this section as commands that alter settings relating to the bot itself."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'bot'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('bot', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.words[3], "bot") then
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

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Bot Commands:")
		irc_chat(chatvars.ircAlias, "=============")
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
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClearBotsWhitelist()

	if result then
		if debug then dbug("debug cmd_ClearBotsWhitelist triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_GuessPassword()

	if result then
		if debug then dbug("debug cmd_GuessPassword triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_QuickResetBot()

	if result then
		if debug then dbug("debug cmd_QuickResetBot triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_RefreshCode()

	if result then
		if debug then dbug("debug cmd_RefreshCode triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_RejoinIRC()

	if result then
		if debug then dbug("debug cmd_RejoinIRC triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReloadBot()

	if result then
		if debug then dbug("debug cmd_ReloadBot triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetBot()

	if result then
		if debug then dbug("debug cmd_ResetBot triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_RestartBot()

	if result then
		if debug then dbug("debug cmd_RestartBot triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_RestoreBackup()

	if result then
		if debug then dbug("debug cmd_RestoreBackup triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBlacklistResponse()

	if result then
		if debug then dbug("debug cmd_SetBlacklistResponse triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotAlertColour()

	if result then
		if debug then dbug("debug cmd_SetBotAlertColour triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotChatColour()

	if result then
		if debug then dbug("debug cmd_SetBotChatColour triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotName()

	if result then
		if debug then dbug("debug cmd_SetBotName triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotRestartDay()

	if result then
		if debug then dbug("debug cmd_SetBotRestartDay triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBotWarningColour()

	if result then
		if debug then dbug("debug cmd_SetBotWarningColour triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetCommandPrefix()

	if result then
		if debug then dbug("debug cmd_SetCommandPrefix triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMasterPassword()

	if result then
		if debug then dbug("debug cmd_SetMasterPassword triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetUpdateBranch()

	if result then
		if debug then dbug("debug cmd_SetUpdateBranch triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShutdownBot()

	if result then
		if debug then dbug("debug cmd_ShutdownBot triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBeQuietBot()

	if result then
		if debug then dbug("debug cmd_ToggleBeQuietBot triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBotRestart()

	if result then
		if debug then dbug("debug cmd_ToggleBotRestart triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBotUpdates()

	if result then
		if debug then dbug("debug cmd_ToggleBotUpdates triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleCheckLevelHack()

	if result then
		if debug then dbug("debug cmd_ToggleCheckLevelHack triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleHackerTPDetection()

	if result then
		if debug then dbug("debug cmd_ToggleHackerTPDetection triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleHideUnknownCommand()

	if result then
		if debug then dbug("debug cmd_ToggleHideUnknownCommand triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLagCheck()

	if result then
		if debug then dbug("debug cmd_ToggleLagCheck triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_UpdateCode()

	if result then
		if debug then dbug("debug cmd_UpdateCode triggered") end
		return result
	end

	if debug then dbug("debug bot end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == 0 and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Bot In-Game Only:")
		irc_chat(chatvars.ircAlias, "=================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_NoReset()

	if result then
		if debug then dbug("debug cmd_NoReset triggered") end
		return result
	end

	if (debug) then dbug("debug bot line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetServer()

	if result then
		if debug then dbug("debug cmd_ResetServer triggered") end
		return result
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Bot commands help registered ****")
		dbug("Bot commands help registered")
		topicID = topicID + 1
	end

	if debug then dbug("debug bot end") end

	-- can't touch dis
	if true then
		return result
	end
end
