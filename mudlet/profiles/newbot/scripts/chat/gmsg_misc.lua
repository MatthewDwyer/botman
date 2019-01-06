--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local result, debug, help, tmp
local shortHelp = false
local skipHelp = false

debug = false -- should be false unless testing

local note, pname, pid, debug, result, help

function gmsg_misc()
	calledFunction = "gmsg_misc"
	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## Miscellaneous command functions ##################

	-- votecrate for Deadlights server
	if chatvars.words[1] == "votecrate" then
		sendCommand("cvc " .. chatvars.playerid)
		botman.faultyChat = false
		return true
	end


	local function cmd_AcceptIRCInvite() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}accept"
			help[2] = "Use this command if you have received an invite to join the IRC server and want further instructions from the bot."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "accept,irc"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "accept") or string.find(chatvars.command, "irc"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "accept" and chatvars.words[2] ~= nil then
			if (chatvars.playername == "Server") then
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].ircInvite ~= nil then
				if chatvars.number == players[chatvars.playerid].ircInvite then
					if server.ircServer ~= nil then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Great! Join our IRC server using this link, https://kiwiirc.com/client/" .. server.ircServer .. ":" .. server.ircPort .. "/" .. server.ircMain .. "[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]From the channel " .. server.ircMain .. " type hi bot.[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A private chat from " .. server.ircBotName .. " will appear. In it type I am " .. players[chatvars.playerid].ircInvite .. "[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will give you a brief introduction to IRC and what you can do there, and it will ask for a password which will become your login.[-]")
						conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. chatvars.playerid .. ", '" .. escape("Join our IRC server at https://kiwiirc.com/client/" .. server.ircServer .. ":" .. server.ircPort .. "/" .. server.ircMain .. ". Type hi bot then go to the private channel called " .. server.ircBotName .. " and type I am " .. players[chatvars.playerid].ircInvite .. "')"))
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Great! Join our IRC server and on it type /join " .. server.ircMain .. "[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]From the channel " .. server.ircMain .. " type hi bot.[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A private chat from " .. server.ircBotName .. " will appear. In it type I am " .. players[chatvars.playerid].ircInvite .. "[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will give you a brief introduction to IRC and what you can do there, and it will ask for a password which will become your login.[-]")
						conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. chatvars.playerid .. ", '" .. escape("Join our IRC server and on it type /join " .. server.ircMain .. ". Type hi bot then go to the private channel called " .. server.ircBotName .. " and type I am " .. players[chatvars.playerid].ircInvite .. "')"))
					end
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I am sorry but that is not the right code.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddCustomCommand() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}add command {command} message {custom message}"
			help[2] = "Add a custom command.  Currently all it can do is send a private message.  Later more actions will be added including the ability to add multiple actions."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,comm,cust"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or string.find(chatvars.command, "command") or string.find(chatvars.command, "custom"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "add" and chatvars.words[2] == "command") then
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

			access = 99

			if string.find(chatvars.command, "message") then
				msg = string.sub(chatvars.commandOld, string.find(chatvars.command, "message") + 8)

				if string.find(chatvars.command, "level") then
					cmd = string.sub(chatvars.commandOld, string.find(chatvars.command, "command") + 8, string.find(chatvars.command, "level") - 2)
					access = string.sub(chatvars.command, string.find(chatvars.command, "level") + 6, string.find(chatvars.command, "message") - 2)
				else
					cmd = string.sub(chatvars.commandOld, string.find(chatvars.command, "command") + 8, string.find(chatvars.command, "message") - 2)
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Message required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Message required.")
				end

				botman.faultyChat = false
				return true
			end

			if cmd == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Command required.")
				end

				botman.faultyChat = false
				return true
			end

			-- strip leading /
			if (string.sub(cmd, 1, 1) == server.commandPrefix and server.commandPrefix ~= "") then
				cmd = string.sub(cmd, 2)
			end

			conn:execute("INSERT INTO customMessages (command, message, accessLevel) Values ('" .. escape(cmd) .. "','" .. escape(msg) .. "'," .. access .. ") ON DUPLICATE KEY UPDATE accessLevel = " .. access.. ", message = '" .. escape(msg) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added the command: " .. server.commandPrefix .. cmd .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, "You added the command: " .. server.commandPrefix .. cmd)
			end

			-- reload from the database
			loadCustomMessages()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_BailOutPrisoner()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}bail {player}"
			help[1] = help[1] .. " {#}bail {player} pay {amount}"
			help[2] = "Anyone can bail a prisoner out of prison if they have enough " .. server.moneyPlural .. ".\n"
			help[2] = help[2] .. "If you don't have enough " .. server.moneyPlural .. " you can reduce the bail by making payment towards it."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bail,prisoner"
				tmp.accessLevel = 90
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bail") or string.find(chatvars.command, "prison"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "bail" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 90) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.payment = 0

			if not string.find(chatvars.command, " pay ") then
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "bail") + 5)
			else
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "bail") + 5, string.find(chatvars.command, " pay ") - 1)
				tmp.payment = math.abs(chatvars.number) -- don't be so negative!
			end

			tmp.pname = stripQuotes(string.trim(tmp.pname))
			tmp.pid = LookupPlayer(tmp.pname)

			if tmp.pid == 0 then
				tmp.pid = LookupArchivedPlayer(tmp.pname)

				if not (tmp.pid == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if (tmp.pid == 0) then
				if tmp.payment == 0 then
					tmp.payment = tonumber(players[chatvars.playerid].bail)
				end

				if tonumber(players[chatvars.playerid].bail) == 0 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You cannot be bailed out of prison.[-]")
					botman.faultyChat = false
					return true
				end

				if not players[chatvars.playerid].prisoner then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not a prisoner.[-]")
					botman.faultyChat = false
					return true
				else
					if tonumber(players[chatvars.playerid].cash) <= tonumber(players[chatvars.playerid].bail) then
						if tonumber(players[chatvars.playerid].cash) >= tmp.payment then
							players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - tmp.payment
							conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = " .. chatvars.playerid)
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. tmp.payment .. " " .. server.moneyPlural .. " has been removed from your cash.[-]")

							players[chatvars.playerid].bail = tonumber(players[chatvars.playerid].bail) - tmp.payment
							conn:execute("UPDATE players SET bail = bail - " .. tmp.payment .. " WHERE steam = " .. chatvars.playerid)

							if tonumber(players[chatvars.playerid].bail) <= 0 then
								gmsg(server.commandPrefix .. "release " .. chatvars.playerid)
							else
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your bail is now " .. players[chatvars.playerid].bail .. " " .. server.moneyPlural .. ".  Get back in your cell prisoner![-]")
							end
						else
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't have enough " .. server.moneyPlural .. " to post bail prisoner.[-]")
							botman.faultyChat = false
							return true
						end
					end
				end
			else
				if tmp.payment == 0 then
					tmp.payment = tonumber(players[tmp.pid].bail)
				end

				if not players[tmp.pid].prisoner then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. " is not a prisoner.[-]")
					botman.faultyChat = false
					return true
				else
					if tonumber(players[tmp.pid].bail) == 0 then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. "  cannot be bailed out of prison.[-]")
						botman.faultyChat = false
						return true
					else
						if tonumber(players[chatvars.playerid].cash) <= tonumber(players[tmp.pid].bail) then
							if tonumber(players[chatvars.playerid].cash) >= tmp.payment then
								players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - tmp.payment
								conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = " .. chatvars.playerid)
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. tmp.payment .. " " .. server.moneyPlural .. " has been removed from your cash.[-]")

								players[tmp.pid].bail = tonumber(players[tmp.pid].bail) - tmp.payment
								conn:execute("UPDATE players SET bail = bail - " .. tmp.payment .. " WHERE steam = " .. tmp.pid)

								if tonumber(players[tmp.pid].bail) <= 0 then
									gmsg(server.commandPrefix .. "release " .. tmp.pid)
								else
									message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. "'s bail is now " .. players[tmp.pid].bail .. " " .. server.moneyPlural .. ".  Come back when you have the rest or wait for their eventual release.[-]")
								end
							else
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't have enough " .. server.moneyPlural .. " to post " .. players[tmp.pid].name .. "'s bail.[-]")
								botman.faultyChat = false
								return true
							end
						end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Bk() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}bk {bookmark number}"
			help[2] = "Teleport to the numbered bookmark (Admins only)"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bookmark"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "book"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "bk" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			if (chatvars.number == nil) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bookmark number is required eg. " .. server.commandPrefix .. "goto bookmark 5[-]")
				botman.faultyChat = false
				return true
			else
				cursor,errorString = conn:execute("select * from bookmarks where id = " .. chatvars.number)
				rows = cursor:numrows()

				if rows > 0 then
					row = cursor:fetch({}, "a")

					-- first record their current x y z
					savePosition(chatvars.playerid)

					cmd = "tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z
					teleport(cmd, chatvars.playerid)

					if players[row.steam] then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is " .. players[row.steam].name .. "'s bookmark " .. row.note .. ".[-]")
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is " .. playersArchived[row.steam].name .. "'s bookmark " .. row.note .. ".[-]")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Bookmark() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}bookmark {message}"
			help[2] = "Record the coordinates where you are standing with a message.  This was created to help admins quickly teleport to places that players wanted screenshot or videoed by admins before a server wipe.\n"
			help[2] = help[2] .. "Only admins can teleport to them.  Players can only view a list of the bookmarks created by themselves."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bookmark"
				tmp.accessLevel = 90
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "book"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "bookmark" and chatvars.words[2] ~= nil) then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 90) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			note = string.sub(chatvars.command, string.find(chatvars.command, "bookmark ") + 9)

			if note == nil then note = "" end

			conn:execute("INSERT INTO bookmarks (steam, x, y, z, note) VALUES (" .. chatvars.playerid .. "," .. igplayers[chatvars.playerid].xPos .. "," .. igplayers[chatvars.playerid].yPos .. "," .. igplayers[chatvars.playerid].zPos .. ",'" .. escape(note) .. "')")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have bookmarked your current position for admins with the message: " .. note .. ".[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ClaimVote() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}claim vote"
			help[2] = "Claim your reward for voting for the server at 7daystodie-servers.com\n"
			help[2] = help[2] .. "Can only be claimed once per day."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "claim,vote,reward,server"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "vote") or string.find(chatvars.command, "reward") or string.find(chatvars.command, "claim"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "claim" and (chatvars.words[2] == "vote" or chatvars.words[2] == "bote") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 99) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == "bote" then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]UPBOTES AHOY![-]")
			end

			if not server.JimsCommands then
				checkServerVote(chatvars.playerid)
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This server is using {#}votecrate.  Please use that command instead of {#}claim vote.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListCustomCommands() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}custom commands"
			help[2] = "List the custom commands."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "list,comm,cust"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or string.find(chatvars.command, "command") or string.find(chatvars.command, "custom"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "custom" and chatvars.words[2] == "commands") or string.find(chatvars.command, "list custom commands") then
			cursor,errorString = conn:execute("SELECT * FROM customMessages")
			row = cursor:fetch({}, "a")

			if not row then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There are no custom commands.[-]")
				else
					irc_chat(chatvars.ircAlias, "There are no custom commands.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Custom commands:[-]")
				else
					irc_chat(chatvars.ircAlias, "Custom commands:")
				end
			end

			while row do
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. row.command .. "[-]")
				else
					irc_chat(chatvars.ircAlias, server.commandPrefix .. row.command)
				end

				row = cursor:fetch(row, "a")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GetRegionName() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}get region {x coordinate} {z coordinate}"
			help[2] = "Get the region name for the supplied coordinates."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "region"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "region"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "get" and chatvars.words[2] == "region" and chatvars.words[3] ~=  nil then
			if ToInt(chatvars.words[3]) == nil or ToInt(chatvars.words[4]) == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Integer coordinates expected for x and z eg. /get region 123 456[-]")
				else
					irc_chat(chatvars.ircAlias, "Integer coordinates expected for x and z eg. /get region 123 456")
				end
			else
				result = getRegion(chatvars.words[3], chatvars.words[4])

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The region at xPos " .. chatvars.words[3] .. " zPos " .. chatvars.words[4] .. " is " .. result .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "The region at (x) " .. chatvars.words[3] .. " (z) " .. chatvars.words[4] .. " is " .. result)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_InvitePlayerToIRC() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}invite {player}"
			help[2] = "Invite a player to join the IRC server.  Choose carefully who you invite."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "invite,irc"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "invite") or string.find(chatvars.command, "irc"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "invite" and chatvars.words[2] ~= nil then
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

			pname = string.sub(chatvars.command, string.find(chatvars.command, "invite") + 7)
			pname = stripQuotes(string.trim(pname))
			pid = LookupPlayer(pname)

			if pid == 0 then
				pid = LookupArchivedPlayer(pname)

				if not (pid == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if pid ~= 0 then
				players[pid].ircInvite = rand(10000)

				if igplayers[pid] then
					message("pm " .. pid .. " HEY " .. players[pid].name .. "! You have an invite code for IRC :D Reply with " .. server.commandPrefix .. "accept " .. players[pid].ircInvite .. " or ignore it. D:")
				end

				conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. pid .. ", '" .. escape("You have an invite code for IRC! Reply with " .. server.commandPrefix .. "accept " .. players[pid].ircInvite .. " or ignore it.") .. "')")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You sent an IRC invite to " .. players[pid].name .. "![-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I don't know anyone called " .. pname .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBookmarks() -- tested
		local playerName, pname, pid

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}list bookmarks {player}"
			help[2] = "If players have bookmarked coordinates on your server, this command will give you a numbered list of a player's bookmarks\n"
			help[2] = help[2] .. "Players can only list their own bookmarks and can't teleport to them."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bk,book,mark"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bk") or string.find(chatvars.command, "book"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "list" and chatvars.words[2] == "bookmarks" then
			if chatvars.words[3] == nil and chatvars.accessLevel < 3 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player name required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player name required.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.accessLevel < 3 then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "bookmarks ") + 10)
				pname = stripQuotes(string.trim(pname))
				pid = LookupPlayer(pname)
			else
				pname = players[chatvars.playerid].name
				pid = chatvars.playerid
			end

			if pid == 0 then
				pid = LookupArchivedPlayer(pname)

				if pid ~= 0 then
					playerName = playersArchived[pid].name
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found with that name.[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found with that name.")
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[pid].name
			end

			if (chatvars.accessLevel > 2) then
				pid = chatvars.playerid
			end

			cursor,errorString = conn:execute("select * from bookmarks where steam = " .. pid)

			if cursor:numrows() == 0 then
				if (chatvars.playername ~= "Server") then
					if pid == chatvars.playerid then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no bookmarks.[-]")
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no bookmarks.[-]")
					end
				else
					if pid == chatvars.playerid then
						irc_chat(chatvars.ircAlias, "You have no bookmarks.")
					else
						irc_chat(chatvars.ircAlias, playerName .. " has no bookmarks.")
					end
				end

				botman.faultyChat = false
				return true
			end

			row = cursor:fetch({}, "a")

			while row do
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.id .. " " .. row.x .. " " .. row.y .. " " .. row.z .. " " .. row.note .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "#" .. row.id .. " " .. row.x .. " " .. row.y .. " " .. row.z .. " " .. row.note)
				end

				row = cursor:fetch(row, "a")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MarkOutArea()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}mark {name} start/end or p1/p2"
			help[2] = "Mark out a named area to be used later with commands that accept coordinate pairs\n"
			help[2] = help[2] .. "You can save and reload it using Coppi's Mod with {#}save {name} and {#}load prefab {name}\n"
			help[2] = help[2] .. "Or if using djkrose's scripting Mod with {#}export {name} and {#}import {name}\n"
			help[2] = help[2] .. "Mark two opposite corners of the area you wish to copy.  Move up or down between corners to add volume or stay at the same height to mark out a flat area."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "mark,start,end,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "mark") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "copy"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "mark" and (chatvars.words[3] == "start" or chatvars.words[3] == "end" or chatvars.words[3] == "p1" or chatvars.words[3] == "p2") then
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

				irc_chat(chatvars.ircAlias, "You can only use this command ingame.")
				botman.faultyChat = false
				return true
			end

			if not prefabCopies[chatvars.playerid .. chatvars.words[2]] then
				prefabCopies[chatvars.playerid .. chatvars.words[2]] = {}

				if chatvars.words[3] == "start" or chatvars.words[3] == "p1" then
					prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
					prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
					prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 = chatvars.intX
					prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 = chatvars.intY
					prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 = chatvars.intZ

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.words[2] .. " end[-]")
					if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'" .. escape(chatvars.words[2]) .. "'," .. chatvars.intX .. "," .. chatvars.intY -1 .. "," .. chatvars.intZ .. ")") end
				else
					prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
					prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
					prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 = chatvars.intX
					prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 = chatvars.intY
					prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 = chatvars.intZ

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.words[2] .. " start[-]")
					if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x2, y2, z2) VALUES (" .. chatvars.playerid .. ",'" .. escape(chatvars.words[2]) .. "'," .. chatvars.intX .. "," .. chatvars.intY -1 .. "," .. chatvars.intZ .. ")") end
				end
			else
				if chatvars.words[3] == "start" or chatvars.words[3] == "p1" then
					prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
					prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
					prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 = chatvars.intX
					prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 = chatvars.intY
					prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 = chatvars.intZ

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.words[2] .. " end[-]")
					if botman.dbConnected then conn:execute("UPDATE prefabCopies SET x1 = " .. chatvars.intX .. ", y1 = " .. chatvars.intY -1 .. ", z1 = " .. chatvars.intZ .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[2]) .. "'") end
				else
					prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
					prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
					prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 = chatvars.intX
					prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 = chatvars.intY
					prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 = chatvars.intZ

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.words[2] .. " start[-]")
					if botman.dbConnected then conn:execute("UPDATE prefabCopies SET x2 = " .. chatvars.intX .. ", y2 = " .. chatvars.intY -1 .. ", z2 = " .. chatvars.intZ .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[2]) .. "'") end
				end
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]When done you can save it with the BC mod by typing " .. server.commandPrefix .. "save " .. chatvars.words[2] .. "[-]")

			if server.djkrose then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Or save it with djkrose's scripting mod by typing " .. server.commandPrefix .. "export " .. chatvars.words[2] .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RemoveCustomCommand() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}remove command {command}"
			help[2] = "Remove a custom command."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "remo,dele,comm,cust"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "remove") or string.find(chatvars.command, "dele") or string.find(chatvars.command, "command") or string.find(chatvars.command, "custom"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "remove" and chatvars.words[2] == "command") then
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

			cmd = string.sub(chatvars.commandOld, string.find(chatvars.command, "command") + 8)

			if cmd ~= nil then
				conn:execute("DELETE FROM customMessages WHERE command = '" .. escape(cmd) .. "'")
				customMessages[cmd] = nil

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed the command " .. server.commandPrefix .. cmd .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "You removed the command: " .. server.commandPrefix .. cmd)
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Command required.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Yes() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}yes"
			help[2] = "If the bot asks you a yes/no question you can simply say yes or use this command to hide your response if commands are hidden."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "yes"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "yes"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "yes" and chatvars.words[2] == nil and chatvars.playername ~= "Server" then
			if players[chatvars.playerid].botQuestion == "reset server" and chatvars.accessLevel == 0 then
				message("say [" .. server.chatColour .. "]Deleting all bot data and starting fresh..[-]")
				tempTimer(5, [[ResetServer()]])

				players[chatvars.playerid].botQuestion = ""
				players[chatvars.playerid].botQuestionID = nil
				players[chatvars.playerid].botQuestionValue = nil

				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].botQuestion == "reset bot keep money" and chatvars.accessLevel == 0 then
				ResetBot(true)
				message("say [" .. server.chatColour .. "]I have been reset.  All bases, inventories etc are forgotten, but not the players or their money.[-]")

				players[chatvars.playerid].botQuestion = ""
				players[chatvars.playerid].botQuestionID = nil
				players[chatvars.playerid].botQuestionValue = nil

				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].botQuestion == "reset bot" and chatvars.accessLevel == 0 then
				ResetBot()
				message("say [" .. server.chatColour .. "]I have been reset.  All bases, inventories etc are forgotten, but not the players.[-]")

				players[chatvars.playerid].botQuestion = ""
				players[chatvars.playerid].botQuestionID = nil
				players[chatvars.playerid].botQuestionValue = nil

				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].botQuestion == "quick reset bot" and chatvars.accessLevel == 0 then
				QuickBotReset()
				message("say [" .. server.chatColour .. "]I have been reset except for players, locations and reset zones.[-]")

				players[chatvars.playerid].botQuestion = ""
				players[chatvars.playerid].botQuestionID = nil
				players[chatvars.playerid].botQuestionValue = nil

				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].botQuestion == "pay player" then
				payPlayer()

				botman.faultyChat = false
				return true
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - misc commands ====")
		dbug("Registering help - misc commands")

		tmp = {}
		tmp.topicDescription = "Miscellaneous commands are commands that don't really belong in other sections or haven't been put in one yet :("

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'misc'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('misc', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

if debug then dbug("debug misc") end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "misc" then
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
		irc_chat(chatvars.ircAlias, "Misc Commands:")
		irc_chat(chatvars.ircAlias, "==============")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "misc")
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_AcceptIRCInvite()

	if result then
		if debug then dbug("debug cmd_AcceptIRCInvite triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddCustomCommand()

	if result then
		if debug then dbug("debug cmd_AddCustomCommand triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_Bk()

	if result then
		if debug then dbug("debug cmd_Bk triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_Bookmark()

	if result then
		if debug then dbug("debug cmd_Bookmark triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClaimVote()

	if result then
		if debug then dbug("debug cmd_ClaimVote triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBookmarks()

	if result then
		if debug then dbug("debug cmd_ListBookmarks triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_BailOutPrisoner()

	if result then
		if debug then dbug("debug cmd_BailOutPrisoner triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_GetRegionName()

	if result then
		if debug then dbug("debug cmd_GetRegionName triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_InvitePlayerToIRC()

	if result then
		if debug then dbug("debug cmd_InvitePlayerToIRC triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListCustomCommands()

	if result then
		if debug then dbug("debug cmd_ListCustomCommands triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_MarkOutArea()

	if result then
		if debug then dbug("debug cmd_MarkOutArea triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_RemoveCustomCommand()

	if result then
		if debug then dbug("debug cmd_RemoveCustomCommand triggered") end
		return result
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_Yes()

	if result then
		if debug then dbug("debug cmd_Yes triggered") end
		return result
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Miscellaneous commands help registered ****")
		dbug("Miscellaneous commands help registered")
		topicID = topicID + 1
	end

	-- if the command matches a custom command, do the command.
	if customMessages[chatvars.words[1]] then
		cursor,errorString = conn:execute("select * from customMessages where command = '" .. escape(chatvars.words[1]) .. "'")
		row = cursor:fetch({}, "a")

		if row then
			if (chatvars.playername == "Server") then
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			if (chatvars.accessLevel <= tonumber(row.accessLevel)) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.message .. "[-]")
				botman.faultyChat = false
				return true
			end

			botman.faultyChat = false
			return true
		end
	end

	if debug then dbug("debug misc end") end

	-- can't touch dis
	if true then
		return result
	end
end


	-- if (chatvars.words[1] == "fetch" and chatvars.words[2] == "claims") then -- TODO: Finish this later
		-- send("llp " .. chatvars.playerid .. " parseable")

		-- if botman.getMetrics then
			-- metrics.telnetCommands = metrics.telnetCommands + 1
		-- end

		-- botman.faultyChat = false
		-- return true
	-- end
