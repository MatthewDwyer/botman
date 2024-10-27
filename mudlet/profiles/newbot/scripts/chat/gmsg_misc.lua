--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_misc()
	local result, debug, help, tmp
	local shortHelp = false

	debug = false -- should be false unless testing

	local note, pname, pid, debug, result, help

	calledFunction = "gmsg_misc"
	result = false
	tmp = {}
	tmp.topic = "misc"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## Miscellaneous command functions ##################

	-- votecrate for Deadlights server
	if chatvars.words[1] == "votecrate" then
		sendCommand("cvc " .. chatvars.userID)
		botman.faultyChat = false
		return true
	end


	local function cmd_AcceptIRCInvite() -- tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}accept"
			help[2] = "Use this command if you have received an invite to join the IRC server and want further instructions from the bot."

			tmp.command = help[1]
			tmp.keywords = "accept,irc"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "accept") or string.find(chatvars.command, "irc") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "accept" and chatvars.words[2] ~= nil then
			if (chatvars.playername == "Server") then
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].ircInvite ~= nil then
				if chatvars.number == players[chatvars.playerid].ircInvite then
					if server.ircServer ~= nil then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Great! Join our IRC server using this link, https://kiwiirc.com/client/" .. server.ircServer .. ":" .. server.ircPort .. "/" .. server.ircMain .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]From the channel " .. server.ircMain .. " type hi bot.[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A private chat from " .. server.ircBotName .. " will appear. In it type I am " .. players[chatvars.playerid].ircInvite .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will give you a brief introduction to IRC and what you can do there, and it will ask for a password which will become your login.[-]")
						connSQL:execute("INSERT INTO mail (sender, recipient, message) VALUES ('0','" .. chatvars.playerid .. "', '" .. connMEM:escape("Join our IRC server at https://kiwiirc.com/client/" .. server.ircServer .. ":" .. server.ircPort .. "/" .. server.ircMain .. ". Type hi bot then go to the private channel called " .. server.ircBotName .. " and type I am " .. players[chatvars.playerid].ircInvite .. "')"))
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Great! Join our IRC server and on it type /join " .. server.ircMain .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]From the channel " .. server.ircMain .. " type hi bot.[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A private chat from " .. server.ircBotName .. " will appear. In it type I am " .. players[chatvars.playerid].ircInvite .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will give you a brief introduction to IRC and what you can do there, and it will ask for a password which will become your login.[-]")
						connSQL:execute("INSERT INTO mail (sender, recipient, message) VALUES ('0','" .. chatvars.playerid .. "', '" .. connMEM:escape("Join our IRC server and on it type /join " .. server.ircMain .. ". Type hi bot then go to the private channel called " .. server.ircBotName .. " and type I am " .. players[chatvars.playerid].ircInvite .. "')"))
					end
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I am sorry but that is not the right code.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddCustomCommand() -- tested
		local status, errorString

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}add command {command} message {custom message}"
			help[2] = "Add a custom command.  Currently all it can do is send a private message.  Later more actions will be added including the ability to add multiple actions."

			tmp.command = help[1]
			tmp.keywords = "add,commands,custom"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "command") or string.find(chatvars.command, "custom") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "add" and chatvars.words[2] == "command") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
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
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Message required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Message required.")
				end

				botman.faultyChat = false
				return true
			end

			if cmd == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Command required.[-]")
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

			status, errorString = conn:execute("INSERT INTO customMessages (command, message, accessLevel) Values ('" .. escape(cmd) .. "','" .. escape(msg) .. "'," .. access .. ")")

			if not status then
				if string.find(errorString, "Duplicate entry") then
					conn:execute("UPDATE customMessages SET accessLevel = " ..  access .. ", message = '" .. escape(msg) .. "' WHERE command = '" .. escape(cmd) .. "'")
				end
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You added the command: " .. server.commandPrefix .. cmd .. ".[-]")
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
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}bail {player}\n"
			help[1] = help[1] .. " {#}bail {player} pay {amount}"
			help[2] = "Anyone can bail a prisoner out of prison if they have enough " .. server.moneyPlural .. ".\n"
			help[2] = help[2] .. "If you don't have enough " .. server.moneyPlural .. " you can reduce the bail by making payment towards it."

			tmp.command = help[1]
			tmp.keywords = "bail,prisoner"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "bail") or string.find(chatvars.command, "prison") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "bail" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
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

			if tmp.pid == "0" then
				tmp.pid = LookupArchivedPlayer(tmp.pname)

				if not (tmp.pid == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if (tmp.pid == "0") then
				if tmp.payment == 0 then
					tmp.payment = tonumber(players[chatvars.playerid].bail)
				end

				if tonumber(players[chatvars.playerid].bail) == 0 then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You cannot be bailed out of prison.[-]")
					botman.faultyChat = false
					return true
				end

				if not players[chatvars.playerid].prisoner then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not a prisoner.[-]")
					botman.faultyChat = false
					return true
				else
					if tonumber(players[chatvars.playerid].cash) <= tonumber(players[chatvars.playerid].bail) then
						if tonumber(players[chatvars.playerid].cash) >= tmp.payment then
							players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - tmp.payment
							conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = '" .. chatvars.playerid .. "'")
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.payment .. " " .. server.moneyPlural .. " has been removed from your cash.[-]")

							players[chatvars.playerid].bail = tonumber(players[chatvars.playerid].bail) - tmp.payment
							conn:execute("UPDATE players SET bail = bail - " .. tmp.payment .. " WHERE steam = '" .. chatvars.playerid .. "'")

							if tonumber(players[chatvars.playerid].bail) <= 0 then
								gmsg(server.commandPrefix .. "release " .. chatvars.playerid)
							else
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your bail is now " .. players[chatvars.playerid].bail .. " " .. server.moneyPlural .. ".  Get back in your cell prisoner![-]")
							end
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You don't have enough " .. server.moneyPlural .. " to post bail prisoner.[-]")
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
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. " is not a prisoner.[-]")
					botman.faultyChat = false
					return true
				else
					if tonumber(players[tmp.pid].bail) == 0 then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. "  cannot be bailed out of prison.[-]")
						botman.faultyChat = false
						return true
					else
						if tonumber(players[chatvars.playerid].cash) >= tonumber(players[tmp.pid].bail) then
							if tonumber(players[chatvars.playerid].cash) >= tmp.payment then
								players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - tmp.payment
								conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = '" .. chatvars.playerid .. "'")
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.payment .. " " .. server.moneyPlural .. " has been removed from your cash.[-]")

								players[tmp.pid].bail = tonumber(players[tmp.pid].bail) - tmp.payment
								conn:execute("UPDATE players SET bail = bail - " .. tmp.payment .. " WHERE steam = '" .. tmp.pid .. "'")

								if tonumber(players[tmp.pid].bail) <= 0 then
									gmsg(server.commandPrefix .. "release " .. tmp.pid)
								else
									message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. "'s bail is now " .. players[tmp.pid].bail .. " " .. server.moneyPlural .. ".  Come back when you have the rest or wait for their eventual release.[-]")
								end
							else
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You don't have enough " .. server.moneyPlural .. " to post " .. players[tmp.pid].name .. "'s bail.[-]")
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
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}bk {bookmark number}"
			help[2] = "Teleport to the numbered bookmark (Admins only)"

			tmp.command = help[1]
			tmp.keywords = "bookmarks"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "book") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "bk" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.number == nil) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bookmark number is required eg. " .. server.commandPrefix .. "goto bookmark 5[-]")
				botman.faultyChat = false
				return true
			else
				cursor,errorString = connSQL:execute("SELECT * FROM bookmarks WHERE id = " .. chatvars.number)
				row = cursor:fetch({}, "a")

				while row do
					-- first record their current x y z
					savePosition(chatvars.playerid)

					cmd = "tele " .. chatvars.userID .. " " .. row.x .. " " .. row.y .. " " .. row.z
					teleport(cmd, chatvars.playerid, chatvars.userID)

					if players[row.steam] then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This is " .. players[row.steam].name .. "'s bookmark " .. row.note .. ".[-]")
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This is " .. playersArchived[row.steam].name .. "'s bookmark " .. row.note .. ".[-]")
					end

					row = cursor:fetch(row, "a")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Bookmark() -- tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}bookmark {message}"
			help[2] = "Record the coordinates where you are standing with a message.  This was created to help admins quickly teleport to places that players wanted screenshot or videoed by admins before a server wipe.\n"
			help[2] = help[2] .. "Only admins can teleport to them.  Players can only view a list of the bookmarks created by themselves."

			tmp.command = help[1]
			tmp.keywords = "bookmarks"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "book") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "bookmark" and chatvars.words[2] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			note = string.sub(chatvars.command, string.find(chatvars.command, "bookmark ") + 9)

			if note == nil then note = "" end

			connSQL:execute("INSERT INTO bookmarks (steam, x, y, z, note) VALUES ('" .. chatvars.playerid .. "'," .. igplayers[chatvars.playerid].xPos .. "," .. igplayers[chatvars.playerid].yPos .. "," .. igplayers[chatvars.playerid].zPos .. ",'" .. connMEM:escape(note) .. "')")
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have bookmarked your current position for admins with the message: " .. note .. ".[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ClaimVote() -- tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}claim vote"
			help[2] = "Claim your reward for voting for the server at 7daystodie-servers.com\n"
			help[2] = help[2] .. "Can only be claimed once per day."

			tmp.command = help[1]
			tmp.keywords = "claim,vote,reward,server"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "vote") or string.find(chatvars.command, "reward") or string.find(chatvars.command, "claim") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "claim" and (chatvars.words[2] == "vote" or chatvars.words[2] == "bote") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == "bote" then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]UPBOTES AHOY![-]")
			end

			if igplayers[chatvars.playerid].voteRewardOwing then
				if tonumber(igplayers[chatvars.playerid].voteRewardOwing) > 0 then
					-- reward the player.  Good Player!  Have biscuit.
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Check the ground for your reward if it is not added directly to your inventory. If it doesn't, move and repeat {#}claim vote[-]")
					rewardServerVote(chatvars.gameid)
					igplayers[chatvars.playerid].voteRewarded = os.time()
					igplayers[chatvars.playerid].voteRewardOwing = 0
				else
					checkServerVote(chatvars.playerid)
				end
			else
				checkServerVote(chatvars.playerid)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListCustomCommands() -- tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}custom commands"
			help[2] = "List the custom commands."

			tmp.command = help[1]
			tmp.keywords = "list,commands,custom"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "command") or string.find(chatvars.command, "custom") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "custom" and chatvars.words[2] == "commands") or string.find(chatvars.command, "list custom commands") then
			cursor,errorString = conn:execute("SELECT * FROM customMessages")
			row = cursor:fetch({}, "a")

			if not row then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There are no custom commands.[-]")
				else
					irc_chat(chatvars.ircAlias, "There are no custom commands.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Custom commands:[-]")
				else
					irc_chat(chatvars.ircAlias, "Custom commands:")
				end
			end

			while row do
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. row.command .. "[-]")
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
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}get region {x coordinate} {z coordinate}"
			help[2] = "Get the region name for the supplied coordinates."

			tmp.command = help[1]
			tmp.keywords = "regions"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "region") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "get" and chatvars.words[2] == "region" and chatvars.words[3] ~=  nil then
			if ToInt(chatvars.words[3]) == nil or ToInt(chatvars.words[4]) == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Integer coordinates expected for x and z eg. /get region 123 456[-]")
				else
					irc_chat(chatvars.ircAlias, "Integer coordinates expected for x and z eg. /get region 123 456")
				end
			else
				result = getRegion(chatvars.words[3], chatvars.words[4])

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The region at xPos " .. chatvars.words[3] .. " zPos " .. chatvars.words[4] .. " is " .. result .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "The region at (x) " .. chatvars.words[3] .. " (z) " .. chatvars.words[4] .. " is " .. result)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_InvitePlayerToIRC() -- tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}irc invite {player}"
			help[2] = "Invite a player to join the IRC server.  Choose carefully who you invite."

			tmp.command = help[1]
			tmp.keywords = "invite,irc"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "invite") or string.find(chatvars.command, "irc") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "irc" and chatvars.words[2] == "invite" and chatvars.words[3] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "invite") + 7)
			pname = stripQuotes(string.trim(pname))
			tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if tmp.steam ~= "0" then
				players[tmp.steam].ircInvite = randSQL(10000)

				if igplayers[tmp.steam] then
					message("pm " .. tmp.userID .. " HEY " .. players[tmp.steam].name .. "! You have an invite code for IRC :D Reply with " .. server.commandPrefix .. "accept " .. players[tmp.steam].ircInvite .. " or ignore it. D:")
				end

				connSQL:execute("INSERT INTO mail (sender, recipient, message) VALUES ('0','" .. tmp.steam .. "', '" .. connMEM:escape("You have an invite code for IRC! Reply with " .. server.commandPrefix .. "accept " .. players[tmp.steam].ircInvite .. " or ignore it.") .. "')")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You sent an IRC invite to " .. players[tmp.steam].name .. "![-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I don't know anyone called " .. pname .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBookmarks() -- tested
		local playerName, pname, pid

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list bookmarks {player}"
			help[2] = "If players have bookmarked coordinates on your server, this command will give you a numbered list of a player's bookmarks\n"
			help[2] = help[2] .. "Players can only list their own bookmarks and can't teleport to them."

			tmp.command = help[1]
			tmp.keywords = "list,bookmarks"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "bk") or string.find(chatvars.command, "book") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "list" and chatvars.words[2] == "bookmarks" then
			if chatvars.words[3] == nil and chatvars.isAdminHidden then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player name required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player name required.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.isAdminHidden then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "bookmarks ") + 10)
				pname = stripQuotes(string.trim(pname))
				pid = LookupPlayer(pname)
			else
				pname = players[chatvars.playerid].name
				pid = chatvars.playerid
			end

			if pid == "0" then
				pid = LookupArchivedPlayer(pname)

				if pid ~= "0" then
					playerName = playersArchived[pid].name
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found with that name.[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found with that name.")
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[pid].name
			end

			if (not chatvars.isAdminHidden) then
				pid = chatvars.playerid
			end

			cursor,errorString = connSQL:execute("SELECT count(*) FROM bookmarks WHERE steam = '" .. pid .. "'")
			rowSQL = cursor:fetch({}, "a")
			rowCount = rowSQL["count(*)"]

			if rowCount == 0 then
				if (chatvars.playername ~= "Server") then
					if pid == chatvars.playerid then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have no bookmarks.[-]")
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have no bookmarks.[-]")
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
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.id .. " " .. row.x .. " " .. row.y .. " " .. row.z .. " " .. row.note .. "[-]")
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
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}mark {name} start/end or p1/p2"
			help[2] = "Mark out a named area to be used later with commands that accept coordinate pairs\n"
			help[2] = help[2] .. "You can save and reload it with {#}save {name} and {#}load prefab {name}\n"
			help[2] = help[2] .. "Mark two opposite corners of the area you wish to copy.  Move up or down between corners to add volume or stay at the same height to mark out a flat area."

			tmp.command = help[1]
			tmp.keywords = "mark,start,end"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "mark") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "copy") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "mark" and (chatvars.words[3] == "start" or chatvars.words[3] == "end" or chatvars.words[3] == "p1" or chatvars.words[3] == "p2") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
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

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.wordsOld[2] .. " end[-]")
					if botman.dbConnected then connSQL:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES ('" .. chatvars.playerid .. "','" .. connMEM:escape(chatvars.words[2]) .. "'," .. chatvars.intX .. "," .. chatvars.intY -1 .. "," .. chatvars.intZ .. ")") end
				else
					prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
					prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
					prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 = chatvars.intX
					prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 = chatvars.intY
					prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 = chatvars.intZ

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.wordsOld[2] .. " start[-]")
					if botman.dbConnected then connSQL:execute("INSERT into prefabCopies (owner, name, x2, y2, z2) VALUES ('" .. chatvars.playerid .. "','" .. connMEM:escape(chatvars.words[2]) .. "'," .. chatvars.intX .. "," .. chatvars.intY -1 .. "," .. chatvars.intZ .. ")") end
				end
			else
				if chatvars.words[3] == "start" or chatvars.words[3] == "p1" then
					prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
					prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
					prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 = chatvars.intX
					prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 = chatvars.intY
					prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 = chatvars.intZ

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.wordsOld[2] .. " end[-]")
					if botman.dbConnected then connSQL:execute("UPDATE prefabCopies SET x1 = " .. chatvars.intX .. ", y1 = " .. chatvars.intY -1 .. ", z1 = " .. chatvars.intZ .. " WHERE owner = '" .. chatvars.playerid .. "' AND name = '" .. connMEM:escape(chatvars.words[2]) .. "'") end
				else
					prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
					prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
					prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 = chatvars.intX
					prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 = chatvars.intY
					prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 = chatvars.intZ

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.wordsOld[2] .. " start[-]")
					if botman.dbConnected then connSQL:execute("UPDATE prefabCopies SET x2 = " .. chatvars.intX .. ", y2 = " .. chatvars.intY -1 .. ", z2 = " .. chatvars.intZ .. " WHERE owner = '" .. chatvars.playerid .. "' AND name = '" .. connMEM:escape(chatvars.words[2]) .. "'") end
				end
			end

			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]When done you can save it..[-]")
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]By typing " .. server.commandPrefix .. "save " .. chatvars.wordsOld[2] .. "[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RemoveCustomCommand() -- tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}remove command {command}"
			help[2] = "Remove a custom command."

			tmp.command = help[1]
			tmp.keywords = "remove,delete,commands,custom"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "remove") or string.find(chatvars.command, "dele") or string.find(chatvars.command, "command") or string.find(chatvars.command, "custom") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "remove" and chatvars.words[2] == "command") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			cmd = string.sub(chatvars.commandOld, string.find(chatvars.command, "command") + 8)

			if cmd ~= nil then
				conn:execute("DELETE FROM customMessages WHERE command = '" .. escape(cmd) .. "'")
				customMessages[cmd] = nil

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You removed the command " .. server.commandPrefix .. cmd .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "You removed the command: " .. server.commandPrefix .. cmd)
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Command required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Command required.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Yes() -- I SAID YES!
		local id, value, r

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}yes"
			help[2] = "If the bot asks you a yes/no question you can simply say yes or use this command to hide your response if commands are hidden."

			tmp.command = help[1]
			tmp.keywords = "yes"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "yes") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "yes" and chatvars.words[2] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].botQuestionID then
				id = players[chatvars.playerid].botQuestionID
			end

			if players[chatvars.playerid].botQuestionValue then
				value = players[chatvars.playerid].botQuestionValue
			end

			if players[chatvars.playerid].botQuestion == "reset server" and chatvars.accessLevel == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Deleting bot data and starting minty fresh. Pass me the bleach :D[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]My mind is going. I can feel it. I'm afraid " .. chatvars.playername .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "Deleting bot data and starting minty fresh. Pass me the bleach :D")
					irc_chat(chatvars.ircAlias, "My mind is going. I can feel it. I'm afraid " .. chatvars.ircAlias .. ".")
				end

				tempTimer(5, [[ResetServer()]])

				players[chatvars.playerid].botQuestion = ""
				players[chatvars.playerid].botQuestionID = nil
				players[chatvars.playerid].botQuestionValue = nil

				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].botQuestion == "reset bot keep money" and chatvars.accessLevel == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Resetting the bot and keeping all the cash.  IT'S MINE! ALL MINE! >:D[-]")
				else
					irc_chat(chatvars.ircAlias, "Resetting the bot and keeping all the cash.  IT'S MINE! ALL MINE! >:D")
				end

				ResetBot(true)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot has been reset. Who am I?[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot has been reset. Who am I?")
				end

				players[chatvars.playerid].botQuestion = ""
				players[chatvars.playerid].botQuestionID = nil
				players[chatvars.playerid].botQuestionValue = nil

				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].botQuestion == "reset bot" and chatvars.accessLevel == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Resetting the bot.[-]")
				else
					irc_chat(chatvars.ircAlias, "Resetting the bot.")
				end

				ResetBot()

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot has been reset. The old world has been forgotten.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot has been reset. The old world has been forgotten.")
				end

				players[chatvars.playerid].botQuestion = ""
				players[chatvars.playerid].botQuestionID = nil
				players[chatvars.playerid].botQuestionValue = nil

				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].botQuestion == "quick reset bot" and chatvars.accessLevel == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Partially resetting the bot.[-]")
				else
					irc_chat(chatvars.ircAlias, "Partially resetting the bot.")
				end

				quickBotReset()

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Reset complete. Players, locations and reset zones have been kept.[-]")
				else
					irc_chat(chatvars.ircAlias, "Reset complete. Players, locations and reset zones have been kept.")
				end

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

			if players[chatvars.playerid].botQuestion == "forget players" and chatvars.accessLevel == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players? Who needs em? Out with the trash I say. All players forgotten and their stuff except for admins.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players? Who needs em? Out with the trash I say. All players forgotten and their stuff except for admins.")
				end

				forgetPlayers()

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The players have been forgotten. Good riddance to them! >:)[-]")
				else
					irc_chat(chatvars.ircAlias, "The players have been forgotten. Good riddance to them! >:)")
				end

				players[chatvars.playerid].botQuestion = ""
				players[chatvars.playerid].botQuestionID = nil
				players[chatvars.playerid].botQuestionValue = nil
				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].botQuestion == "reset profile" and chatvars.accessLevel == 0 then
				sendCommand("bm-resetplayer Steam_" .. id .. " true")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Resetting " .. players[id].name .. "'s profile.[-]")
				else
					irc_chat(chatvars.ircAlias, "Resetting " .. players[id].name .. "'s profile.")
				end

				players[chatvars.playerid].botQuestion = ""
				players[chatvars.playerid].botQuestionID = nil
				players[chatvars.playerid].botQuestionValue = nil

				botman.faultyChat = false
				return true
			end

			r = randSQL(11)

			if (chatvars.playername ~= "Server") then
				if r == 1 then	message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]OK![-]") end
				if r == 2 then	message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Indeed[-]") end
				if r == 3 then	message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Quite so[-]") end
				if r == 4 then	message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]If you say so.[-]") end
				if r == 5 then	message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That settles it then.[-]") end
				if r == 6 then	message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]NO! GOD! NO GOD PLEASE NO! NO! NOOOOO!![-]") end
				if r == 7 then	message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Sure sure[-]") end
				if r == 8 then	message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Whatever[-]") end
				if r == 9 then	message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Excellent![-]") end
				if r == 10 then	message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I approve of this statement.[-]") end
				if r == 11 then	message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Another happy customer :D[-]") end

			else
				if r == 1 then	irc_chat(chatvars.ircAlias, "OK!") end
				if r == 2 then	irc_chat(chatvars.ircAlias, "Indeed") end
				if r == 3 then	irc_chat(chatvars.ircAlias, "Quite so") end
				if r == 4 then	irc_chat(chatvars.ircAlias, "If you say so.") end
				if r == 5 then	irc_chat(chatvars.ircAlias, "That settles it then.") end
				if r == 6 then	irc_chat(chatvars.ircAlias, "NO! GOD! NO GOD PLEASE NO! NO! NOOOOO!!") end
				if r == 7 then	irc_chat(chatvars.ircAlias, "Sure sure") end
				if r == 8 then	irc_chat(chatvars.ircAlias, "Whatever") end
				if r == 9 then	irc_chat(chatvars.ircAlias, "Excellent!") end
				if r == 10 then	irc_chat(chatvars.ircAlias, "I approve of this statement.") end
				if r == 11 then	irc_chat(chatvars.ircAlias, "Another happy customer :D") end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		if debug then dbug("Registering help - misc commands") end

		tmp.topicDescription = "Miscellaneous commands are commands that don't really belong in other sections or haven't been put in one yet :("

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Miscellaneous Commands:")
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

if debug then dbug("debug misc") end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "misc" then
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
		irc_chat(chatvars.ircAlias, "Misc Commands:")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "misc")
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_AcceptIRCInvite()

	if result then
		if debug then dbug("debug cmd_AcceptIRCInvite triggered") end
		return result, "cmd_AcceptIRCInvite"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddCustomCommand()

	if result then
		if debug then dbug("debug cmd_AddCustomCommand triggered") end
		return result, "cmd_AddCustomCommand"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_Bk()

	if result then
		if debug then dbug("debug cmd_Bk triggered") end
		return result, "cmd_Bk"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_Bookmark()

	if result then
		if debug then dbug("debug cmd_Bookmark triggered") end
		return result, "cmd_Bookmark"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClaimVote()

	if result then
		if debug then dbug("debug cmd_ClaimVote triggered") end
		return result, "cmd_ClaimVote"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBookmarks()

	if result then
		if debug then dbug("debug cmd_ListBookmarks triggered") end
		return result, "cmd_ListBookmarks"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_BailOutPrisoner()

	if result then
		if debug then dbug("debug cmd_BailOutPrisoner triggered") end
		return result, "cmd_BailOutPrisoner"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_GetRegionName()

	if result then
		if debug then dbug("debug cmd_GetRegionName triggered") end
		return result, "cmd_GetRegionName"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_InvitePlayerToIRC()

	if result then
		if debug then dbug("debug cmd_InvitePlayerToIRC triggered") end
		return result, "cmd_InvitePlayerToIRC"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListCustomCommands()

	if result then
		if debug then dbug("debug cmd_ListCustomCommands triggered") end
		return result, "cmd_ListCustomCommands"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_MarkOutArea()

	if result then
		if debug then dbug("debug cmd_MarkOutArea triggered") end
		return result, "cmd_MarkOutArea"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_RemoveCustomCommand()

	if result then
		if debug then dbug("debug cmd_RemoveCustomCommand triggered") end
		return result, "cmd_RemoveCustomCommand"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	result = cmd_Yes()

	if result then
		if debug then dbug("debug cmd_Yes triggered") end
		return result, "cmd_Yes"
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	if botman.registerHelp then
		if debug then dbug("Miscellaneous commands help registered") end
	end

	-- if the command matches a custom command, do the command.
	if customMessages[chatvars.words[1]] then
		cursor,errorString = conn:execute("select * from customMessages where command = '" .. escape(chatvars.words[1]) .. "'")
		row = cursor:fetch({}, "a")

		if row then
			if (chatvars.playername == "Server") then
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true, "custom message"
			end

			if (chatvars.accessLevel <= tonumber(row.accessLevel)) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.message .. "[-]")
				botman.faultyChat = false
				return true, "custom message"
			end

			botman.faultyChat = false
			return true, "custom message"
		end
	end

	if debug then dbug("debug misc end") end

	-- can't touch dis
	if true then
		return result, ""
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
