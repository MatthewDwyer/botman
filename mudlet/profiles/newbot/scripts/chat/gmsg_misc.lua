--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function gmsg_misc()
	calledFunction = "gmsg_misc"

	local note, pname, pid, debug, result

	debug = false

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	-- votecrate for Deadlights server
	if chatvars.words[1] == "votecrate" then
		send("cvc " .. chatvars.playerid)
		botman.faultyChat = false
		return true
	end

	if chatvars.words[1] == "list" and chatvars.words[2] == "bookmarks" then
		pid = string.sub(chatvars.command, string.find(chatvars.command, "bookmarks ") + 10)
		pid = stripQuotes(string.trim(pid))
		pid = LookupPlayer(pid)

		if (chatvars.accessLevel > 2) then
			pid = chatvars.playerid
		end

		if (pid == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found with that name.[-]")
			else
				irc_chat(chatvars.ircAlias, "No player found with that name.")
			end

			botman.faultyChat = false
			return true
		else
			cursor,errorString = conn:execute("select * from bookmarks where steam = " .. pid)
			row = cursor:fetch({}, "a")

			while row do
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]#" .. row.id .. " " .. row.x .. " " .. row.y .. " " .. row.z .. " " .. row.note .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "#" .. row.id .. " " .. row.x .. " " .. row.y .. " " .. row.z .. " " .. row.note)
				end

				row = cursor:fetch(row, "a")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "bail" then
		pid = string.sub(chatvars.command, string.find(chatvars.command, "bail") + 5)
		pid = stripQuotes(string.trim(pid))
		pid = LookupPlayer(pid)

		if (pid == nil) then
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
				if tonumber(players[chatvars.playerid].cash) < tonumber(players[chatvars.playerid].bail) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't have enough " .. server.moneyPlural .. " to post bail.[-]")
					botman.faultyChat = false
					return true
				else
					players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - tonumber(players[chatvars.playerid].bail)
					conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = " .. chatvars.playerid)
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[chatvars.playerid].bail .. " " .. server.moneyPlural .. " has been removed from your cash.[-]")
					gmsg(server.commandPrefix .. "release " .. chatvars.playerid)
				end
			end

			botman.faultyChat = false
			return true
		else
			if not players[pid].prisoner then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[pid].name .. " is not a prisoner.[-]")
				botman.faultyChat = false
				return true
			else
				if tonumber(players[pid].bail) == 0 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[pid].name .. "  cannot be bailed out of prison.[-]")
					botman.faultyChat = false
					return true
				end

				if tonumber(players[chatvars.playerid].cash) < tonumber(players[pid].bail) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't have enough " .. server.moneyPlural .. " to bail " .. players[pid].name .. ".[-]")
					botman.faultyChat = false
					return true
				else
					if not isFriend(pid, chatvars.playerid) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are only allowed to bail out friends.[-]")
						botman.faultyChat = false
						return true
					else
						players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - players[pid].bail
						conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = " .. chatvars.playerid)
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[pid].bail .. " " .. server.moneyPlural .. " has been removed from your cash.[-]")
						gmsg(server.commandPrefix .. "release " .. pid)
					end
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "get" and chatvars.words[2] == "region" and chatvars.words[3] ~=  nil then
		if ToInt(chatvars.words[3]) == nil or ToInt(chatvars.words[4]) == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Integer coordinates expected for x and z eg. /get region 123 456[-]")
			else
				irc_chat(server.ircMain, "Integer coordinates expected for x and z eg. /get region 123 456")
			end
		else
			result = getRegion(chatvars.words[3], chatvars.words[4])

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The region at xPos " .. chatvars.words[3] .. " zPos " .. chatvars.words[4] .. " is " .. result .. "[-]")
			else
				irc_chat(server.ircMain, "The region at xPos " .. chatvars.words[3] .. " zPos " .. chatvars.words[4] .. " is " .. result)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "accept" and chatvars.words[2] ~= nil then
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

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "invite" and chatvars.words[2] ~= nil and (not server.ircPrivate or chatvars.accessLevel == 0) then
		pname = string.sub(chatvars.command, string.find(chatvars.command, "invite") + 7)
		pname = stripQuotes(string.trim(pname))
		pid = LookupPlayer(pname)

		if pid ~= nil then
			players[pid].ircInvite = rand(10000)

			if igplayers[pid] then
				message("pm " .. pid .. " HEY " .. players[pid].name .. "! You have an invite code for IRC! Reply with " .. server.commandPrefix .. "accept " .. players[pid].ircInvite .. " or ignore it.")
			end

			conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. pid .. ", '" .. escape("You have an invite code for IRC! Reply with " .. server.commandPrefix .. "accept " .. players[pid].ircInvite .. " or ignore it.") .. "')")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You sent an IRC invite to " .. players[pid].name .. "![-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I don't know anyone called " .. pname .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "fetch" and chatvars.words[2] == "claims") then
		send("llp " .. chatvars.playerid .. " parseable")


		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "bookmark" and chatvars.words[2] ~= nil) then

		note = string.sub(chatvars.command, string.find(chatvars.command, "bookmark ") + 9)

		if note == nil then note = "" end

		conn:execute("INSERT INTO bookmarks (steam, x, y, z, note) VALUES (" .. chatvars.playerid .. "," .. math.floor(igplayers[chatvars.playerid].xPos) .. "," .. math.ceil(igplayers[chatvars.playerid].yPos) .. "," .. math.floor(igplayers[chatvars.playerid].zPos) .. ",'" .. escape(note) .. "')")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Position added to bookmarks.[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "bk" then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if players[chatvars.playerid].botQuestion == "reset server" and chatvars.words[1] == "yes" and chatvars.accessLevel == 0 then
			message("say [" .. server.chatColour .. "]Deleting all bot data and starting fresh..[-]")
			ResetServer()

			players[chatvars.playerid].botQuestion = ""
			players[chatvars.playerid].botQuestionID = nil
			players[chatvars.playerid].botQuestionValue = nil
			botman.faultyChat = false
			return true
		end
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if players[chatvars.playerid].botQuestion == "reset bot keep money" and chatvars.words[1] == "yes" and chatvars.accessLevel == 0 then
			ResetBot(true)
			message("say [" .. server.chatColour .. "]I have been reset.  All bases, inventories etc are forgotten, but not the players or their money.[-]")

			players[chatvars.playerid].botQuestion = ""
			players[chatvars.playerid].botQuestionID = nil
			players[chatvars.playerid].botQuestionValue = nil
			botman.faultyChat = false
			return true
		end

		if players[chatvars.playerid].botQuestion == "reset bot" and chatvars.words[1] == "yes" and chatvars.accessLevel == 0 then
			ResetBot()
			message("say [" .. server.chatColour .. "]I have been reset.  All bases, inventories etc are forgotten, but not the players.[-]")

			players[chatvars.playerid].botQuestion = ""
			players[chatvars.playerid].botQuestionID = nil
			players[chatvars.playerid].botQuestionValue = nil
			botman.faultyChat = false
			return true
		end
	end

	if (debug) then dbug("debug misc line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if players[chatvars.playerid].botQuestion == "quick reset bot" and chatvars.words[1] == "yes" and chatvars.accessLevel == 0 then
			QuickBotReset()
			message("say [" .. server.chatColour .. "]I have been reset except for players, locations and reset zones.[-]")

			players[chatvars.playerid].botQuestion = ""
			players[chatvars.playerid].botQuestionID = nil
			players[chatvars.playerid].botQuestionValue = nil
			botman.faultyChat = false
			return true
		end
	end

if debug then dbug("debug misc end") end

end
