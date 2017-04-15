--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


--[[
add /claims <distance> it will count all claims (using llp) within range.
add /claim owners <distance> will list all the players with claims down in range
update /tp so it accepts coords
admin commands
--]]

function gmsg_admin()
	calledFunction = "gmsg_admin"

	local debug, tmp, str
	local shortHelp = false
	local skipHelp = false

	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false
	tmp = {}

if debug then dbug("debug admin") end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "admin" then
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
		irc_chat(players[chatvars.ircid].ircAlias, "Admin Commands:")
		irc_chat(players[chatvars.ircid].ircAlias, "================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if chatvars.showHelpSections then
		irc_chat(players[chatvars.ircid].ircAlias, "admin")
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "read claims")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "read claims")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make the bot run llp so it knows where all the claims are and who owns them.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "read" and chatvars.words[2] == "claims" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		-- run llp
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reading claims[-]")
		send("llp")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reload admins")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reload admins")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make the bot run admin list to reload the admins from the server's list.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reload" or chatvars.words[1] == "refresh" or chatvars.words[1] == "update") and chatvars.words[2] == "admins" then
		-- run admin list
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reading admin list[-]")
		send("admin list")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reload bot")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reload bot")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make the bot read several things from the server including admin list, ban list, gg, lkp and others.  If you have Coppi's Mod installed it will also detect that.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reload" or chatvars.words[1] == "refresh" or chatvars.words[1] == "update") and chatvars.words[2] == "bot" then
		-- run admin list, gg, ban list and lkp

		message("say [" .. server.chatColour .. "]Collecting known players[-]")
		send("lkp -online")

		tempTimer( 4, [[message("say [" .. server.chatColour .. "]Reading admin list[-]")]] )
		tempTimer( 4, [[send("admin list")]] )

		tempTimer( 6, [[message("say [" .. server.chatColour .. "]Reading bans[-]")]] )
		tempTimer( 6, [[send("ban list")]] )

		tempTimer( 8, [[message("say [" .. server.chatColour .. "]Reading server config[-]")]] )
		tempTimer( 8, [[send("gg")]] )

		tempTimer( 10, [[message("say [" .. server.chatColour .. "]Reading claims[-]")]])
		tempTimer( 10, [[send("llp)]] )

		tempTimer( 13, [[send("pm IPCHECK")]] )
		tempTimer( 13, [[message("say [" .. server.chatColour .. "]Reload complete.[-]")]] )

		tempTimer( 15, [[send("teleh")]] )
		tempTimer( 16, [[registerBot()]] )

		botman.faultyChat = false
		return true

	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "timeout")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "timeout <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Send a player to timeout.  You can use their steam or game id and part or all of their name.  If you send the wrong player to timeout " .. server.commandPrefix .. "return <player> to fix that.")
				irc_chat(players[chatvars.ircid].ircAlias, "While in timeout, the player will not be able to use any bot commands but they can chat.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "timeout") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 90) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		end

		if (chatvars.words[2] == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Send a player to timeout where they can only talk.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can also send yourself to timeout but not other staff.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "timeout <player>[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]See also: " .. server.commandPrefix .. "return <player>[-]")
			botman.faultyChat = false
			return true
		end

		tmp = {}
		tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "timeout ") + 8)
		tmp.pname = string.trim(tmp.pname)
		tmp.id = LookupPlayer(tmp.pname)

		if (chatvars.playername ~= "Server") then
			if (players[tmp.id].newPlayer == false and chatvars.accessLevel > 3) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are limited to sending new players to timeout. " .. players[tmp.id].name .. " is not new.[-]")
				botman.faultyChat = false
				return true
			end
		end

		if (players[tmp.id].timeout == true) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This player is already in timeout.  Did you mean " .. server.commandPrefix .. "return ?[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Player " .. tmp.id .. " " .. players[tmp.id].name .. " is already in timeout.")
			end

			botman.faultyChat = false
			return true
		end

		if (accessLevel(tmp.id) < 3 and botman.ignoreAdmins == true) and tmp.id ~= chatvars.playerid then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Staff cannot be sent to timeout.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Staff cannot be sent to timeout.")
			end

			botman.faultyChat = false
			return true
		end

		if accessLevel(tmp.id) > 2	then
			players[tmp.id].silentBob = true
		end

		-- first record their current x y z
		players[tmp.id].timeout = true
		players[tmp.id].xPosTimeout = math.floor(players[tmp.id].xPos)
		players[tmp.id].yPosTimeout = math.ceil(players[tmp.id].yPos)
		players[tmp.id].zPosTimeout = math.floor(players[tmp.id].zPos)

		if (chatvars.playername ~= "Server") then
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[tmp.id].xPosTimeout .. "," .. players[tmp.id].yPosTimeout .. "," .. players[tmp.id].zPosTimeout .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(players[tmp.id].name) .. " SteamID: " .. tmp.id .. " sent to timeout by " .. escape(players[chatvars.playerid].name) .. "'," .. tmp.id .. ")")
		else
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[tmp.id].xPosTimeout .. "," .. players[tmp.id].yPosTimeout .. "," .. players[tmp.id].zPosTimeout .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(players[tmp.id].name) .. " SteamID: " .. tmp.id .. " sent to timeout by " .. escape(players[chatvars.ircid].name) .. "'," .. tmp.id .. ")")
		end

		-- then teleport the player to timeout
		send("tele " .. tmp.id .. " " .. players[tmp.id].xPosTimeout .. " 50000 " .. players[tmp.id].zPosTimeout)

		message("say [" .. server.chatColour .. "]" .. players[tmp.id].name .. " has been sent to timeout.[-]")

		conn:execute("UPDATE players SET timeout = 1, silentBob = 1, xPosTimeout = " .. players[tmp.id].xPosTimeout .. ", yPosTimeout = " .. players[tmp.id].yPosTimeout .. ", zPosTimeout = " .. players[tmp.id].zPosTimeout .. " WHERE steam = " .. tmp.id)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "return")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "return <player>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "return <player> to <location or other player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Return a player from timeout.  You can use their steam or game id and part or all of their name.")
				irc_chat(players[chatvars.ircid].ircAlias, "You can return them to any player even offline ones or to any location. If you just return them, they will return to wherever they were when they were sent to timeout.")
				irc_chat(players[chatvars.ircid].ircAlias, "Your regular players can also return new players from timeout but only if a player sent them there.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "return" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 90) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted. Just type " .. server.commandPrefix .. "return.[-]")
				botman.faultyChat = false
				return true
			end
		end

		tmp = {}

		if string.find(chatvars.command, " to ") then
			tmp.loc = string.sub(chatvars.command, string.find(chatvars.command, " to ") + 4)
			tmp.loc = string.trim(tmp.loc)
			tmp.loc = LookupLocation(tmp.loc)

			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "return ") + 7, string.find(chatvars.command, " to ") - 1)
			tmp.pname = string.trim(tmp.pname)
			tmp.id = LookupPlayer(tmp.pname)
		else
			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "return ") + 7)
			tmp.pname = string.trim(tmp.pname)
			tmp.id = LookupPlayer(tmp.pname)
		end

		if (chatvars.playername ~= "Server") then
			-- don't allow players to return anyone to a different location.
			if (chatvars.accessLevel > 2) then
				tmp.loc = nil
			end
		end

		if (players[tmp.id].timeout == true and tmp.id == chatvars.playerid and chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. You cannot release yourself.[-]")
			botman.faultyChat = false
			return true
		end

		if players[tmp.id].timeout == false and players[tmp.id].prisoner and ((tmp.id ~= chatvars.playerid and chatvars.accessLevel > 2) or chatvars.playerid == players[id].pvpVictim) then
			gmsg(server.commandPrefix .. "release " .. players[tmp.id].name)
			botman.faultyChat = false
			return true
		end

		if (chatvars.playername ~= "Server") then
			if chatvars.accessLevel > 2 then
				if players[tmp.id].newPlayer == true or players[tmp.id].timeout == false then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can only use this command on new players in timeout and a player sent them there.[-]")
					botman.faultyChat = false
					return true
				end
			end
		end

		-- return player to previously recorded x y z
		if (igplayers[tmp.id]) then
			if tonumber(players[tmp.id].yPosTimeout) > 0 then
				players[tmp.id].timeout = false
				players[tmp.id].botTimeout = false
				players[tmp.id].freeze = false
				players[tmp.id].silentBob = false

				igplayers[tmp.id].skipExcessInventory = true

				if tmp.loc ~= nil then
					tmp.cmd = "tele " .. tmp.id .. " " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z
				else
					send("tele " .. tmp.id .. " " .. players[tmp.id].xPosTimeout .. " " .. players[tmp.id].yPosTimeout .. " " .. players[tmp.id].zPosTimeout)

					players[tmp.id].xPosTimeout = 0
					players[tmp.id].yPosTimeout = 0
					players[tmp.id].zPosTimeout = 0

					conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, xPosTimeout = 0, yPosTimeout = 0, zPosTimeout = 0 WHERE steam = " .. tmp.id)

					message("say [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. "[-]")

					botman.faultyChat = false
					return true
				end

				prepareTeleport(tmp.id, tmp.cmd)
				teleport(tmp.cmd, true)

				players[tmp.id].xPosTimeout = 0
				players[tmp.id].yPosTimeout = 0
				players[tmp.id].zPosTimeout = 0

				if tmp.loc ~= nil then
					message("say [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. " to " .. tmp.loc .. "[-]")
				else
					message("say [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. "[-]")
				end

				conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, xPosTimeout = 0, yPosTimeout = 0, zPosTimeout = 0 WHERE steam = " .. tmp.id)

				botman.faultyChat = false
				return true
			end

			if tonumber(players[tmp.id].yPosOld) > 0 then
				players[tmp.id].timeout = false
				players[tmp.id].botTimeout = false

				if tmp.loc ~= nil then
					tmp.cmd = "tele " .. tmp.id .. " " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z
				else
					tmp.cmd = "tele " .. tmp.id .. " " .. players[tmp.id].xPosOld .. " " .. players[tmp.id].yPosOld .. " " .. players[tmp.id].zPosOld
				end

				prepareTeleport(tmp.id, tmp.cmd)
				teleport(tmp.cmd, true)

				players[tmp.id].xPosOld = 0
				players[tmp.id].yPosOld = 0
				players[tmp.id].zPosOld = 0

				conn:execute("UPDATE players SET timeout = 0, botTimeout = 0, xPosOld = 0, yPosOld = 0, zPosOld = 0 WHERE steam = " .. tmp.id)

				if tmp.loc ~= nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. " to " .. tmp.loc .. "[-]")
					else
						message("say [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. " to " .. tmp.loc .. "[-]")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. "[-]")
					else
						message("say [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. "[-]")
					end
				end
			end
		else
			if (players[tmp.id].yPosTimeout) then
				players[tmp.id].timeout = false
				players[tmp.id].botTimeout = false
				players[tmp.id].location = "return player"
				players[tmp.id].silentBob = false

				message("say [" .. server.chatColour .. "]" .. players[tmp.id].name .. " will be returned when they next join the server.[-]")

				conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0 WHERE steam = " .. tmp.id)

				botman.faultyChat = false
				return true
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "prison") or string.find(chatvars.command, "releas"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "release <player>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "just release <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Release a player from prison.  They are teleported back to where they were arrested.")
				irc_chat(players[chatvars.ircid].ircAlias, "Alternatively just release them so they do not teleport and have to walk back or use bot commands.")
				irc_chat(players[chatvars.ircid].ircAlias, "See also " .. server.commandPrefix .. "release here")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "release" or (chatvars.words[1] == "just" and chatvars.words[2] == "release")) then
		prisoner = string.sub(chatvars.command, string.find(chatvars.command, "release ") + 8)
		prisoner = string.trim(prisoner)
		prisonerid = LookupPlayer(prisoner)
		prisoner = players[prisonerid].name

		if prisonerid == nil then
			message("say [" .. server.chatColour .. "]We don't have a prisoner called " .. prisoner .. ".[-]")
			botman.faultyChat = false
			return true
		end

		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				if (prisonerid == chatvars.playerid) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can't release yourself.  This isn't Idiocracy.[-]")
					botman.faultyChat = false
					return true
				end

				if (players[prisonerid].pvpVictim ~= chatvars.playerid) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. prisoner .. " is not in prison for your death and cannot be released by you.[-]")
					botman.faultyChat = false
					return true
				end
			end
		end

		if (players[prisonerid].timeout == true or players[prisonerid].botTimeout == true) then
			players[prisonerid].timeout = false
			players[prisonerid].botTimeout = false
			players[prisonerid].freeze = false
			players[prisonerid].silentBob = false
			gmsg(server.commandPrefix .. "return " .. prisonerid)
			setChatColour(prisonerid)

			conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0 WHERE steam = " .. prisonerid)

			botman.faultyChat = false
			return true
		end

		if (not players[prisonerid].prisoner and players[prisonerid].timeout == false) then
			message("say [" .. server.chatColour .. "]Citizen " .. prisoner .. " is not a prisoner[-]")
			botman.faultyChat = false
			return true
		end

		players[prisonerid].xPosOld = 0
		players[prisonerid].yPosOld = 0
		players[prisonerid].zPosOld = 0

		if (igplayers[prisonerid]) then
			message("say [" .. server.warnColour .. "]Releasing prisoner " .. prisoner .. "[-]")
			message("pm " .. prisonerid .. " [" .. server.chatColour .. "]You are released from prison.  Be a good citizen if you wish to remain free.[-]")

			if (chatvars.words[1] ~= "just") then
				if (players[prisonerid].prisonxPosOld) then
					cmd = "tele " .. prisonerid .. " " .. players[prisonerid].prisonxPosOld .. " " .. players[prisonerid].prisonyPosOld .. " " .. players[prisonerid].prisonzPosOld
					igplayers[prisonerid].lastTP = cmd
					prepareTeleport(prisonerid, cmd)
					teleport(cmd, true)
				end
			else
				message("pm " .. prisonerid .. " [" .. server.chatColour .. "]You are a free citizen, but you must find your own way back.[-]")
			end

			conn:execute("UPDATE players SET prisoner = 0, silentBob = 0, xPosOld = " .. players[prisonerid].prisonxPosOld .. ", yPosOld = " .. players[prisonerid].prisonyPosOld .. ", zPosOld = " .. players[prisonerid].prisonzPosOld .. " WHERE steam = " .. prisonerid)
		else
			if (players[prisonerid]) then
				players[prisonerid].location = "return player"
				message("say [" .. server.chatColour .. "]" .. players[prisonerid].name .. " will be released when they next join the server.[-]")

				players[prisonerid].xPosOld = players[prisonerid].prisonxPosOld
				players[prisonerid].yPosOld = players[prisonerid].prisonyPosOld
				players[prisonerid].zPosOld = players[prisonerid].prisonzPosOld

				conn:execute("UPDATE players SET prisoner = 0, silentBob = 0, location = 'return player', xPosOld = " .. players[prisonerid].prisonxPosOld .. ", yPosOld = " .. players[prisonerid].prisonyPosOld .. ", zPosOld = " .. players[prisonerid].prisonzPosOld .. " WHERE steam = " .. prisonerid)
			end
		end

		players[prisonerid].prisoner = false
		players[prisonerid].silentBob = false
		setChatColour(prisonerid)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "give" and (string.find(chatvars.words[2], "claim") or string.find(chatvars.words[2], "key") or string.find(chatvars.words[2], "lcb")) then
		if players[chatvars.playerid].removedClaims > 20 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I am holding a lot of claims. Due to bugs with the count I can't release them to you.  Please talk to an admin to get them back so we can verify the count.[-]")

			botman.faultyChat = false
			return true
		end

		if players[chatvars.playerid].removedClaims > 0 then
			send("give " .. chatvars.playerid .. " keystoneBlock " .. players[chatvars.playerid].removedClaims)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I was holding " .. players[chatvars.playerid].removedClaims .. " keystones for you and have dropped them at your feet.  Press e to collect them now.[-]")
			players[chatvars.playerid].removedClaims = 0
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I have no keystones to give you at this time.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return false
		end
	else
		if tonumber(chatvars.ircid) > 0 then
			if (accessLevel(chatvars.ircid) > 2) then
				botman.faultyChat = false
				return false
			end
		end
	end
	-- ##################################################################

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "feral") or string.find(chatvars.command, "rebo"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "feral reboot delay <minutes>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set how many minutes after day 7 that the bot will wait before rebooting if a reboot is scheduled for day 7.")
				irc_chat(players[chatvars.ircid].ircAlias, "To disable this feature, set it to 0.  The bot will wait a full game day instead.")				
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "feral" and chatvars.words[2] == "reboot" and chatvars.words[3] == "delay") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		server.feralRebootDelay = math.abs(math.floor(chatvars.number))
		conn:execute("UPDATE server SET feralRebootDelay = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reboots that fall on a feral day will happen " .. server.feralRebootDelay .. " minutes into the next day.[-]")
		else
			message("say [" .. server.chatColour .. "]Reboots that fall on a feral day will happen " .. server.feralRebootDelay .. " minutes into the next day.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end
	
	if (chatvars.words[1] == "restart") and (chatvars.words[2] == "bot") and (chatvars.accessLevel < 3) then
		if botman.customMudlet then	
			savePlayers()		
			closeMudlet()		
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is not supported in your Mudlet.  You need the latest custom Mudlet by TheFae.[-]")		
		end

		botman.faultyChat = false
		return true
	end		
	
	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end	

	if (chatvars.words[1] == "hordeme") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			irc_chat(players[chatvars.ircid].ircAlias, "This command is not available from IRC. Use it ingame.")
			botman.faultyChat = false
			return true
		end

		message("say [" .. server.chatColour .. "]HORDE!!![-]")

		for i=1,50,1 do
			cmd = "se " .. players[chatvars.playerid].id .. " " .. PicknMix()
			conn:execute("INSERT INTO gimmeQueue (steam, command) VALUES (" .. chatvars.playerid .. ",'" .. cmd .. "')")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim") or string.find(chatvars.command, "keys"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "leave claims <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Stop the bot automatically removing a player's claims.  They will still be removed if they are in a location that doesn't allow player claims.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "leave" and chatvars.words[2] == "claims" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = chatvars.words[3]
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			-- this players claims wil not be removed unless in a reset zone and not staff
			players[id].removeClaims = false
			conn:execute("UPDATE keystones SET remove = 0 WHERE steam = " .. id)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. "'s claims will not be removed unless found in reset zones (if not staff).[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. "'s claims will not be removed unless found in reset zones (if not staff)")
			end

			conn:execute("UPDATE players SET removeClaims = 0 WHERE steam = " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim") or string.find(chatvars.command, "keys"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "remove claims <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot will automatically remove the player's claims whenever possible. The chunk has to be loaded and the bot takes several minutes to remove them but it will remove them.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "remove" and chatvars.words[2] == "claims" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = chatvars.words[3]
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			-- flag the player's claims for removal
			players[id].removeClaims = true

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will remove all of player " .. players[id].name .. "'s claims when their chunks are loaded.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "I will remove all of player " .. players[id].name .. "'s claims when their chunks are loaded.")
			end

			send("llp " .. id)

			conn:execute("UPDATE players SET removeClaims = 1 WHERE steam = " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "claims <range> (range is optional and defaults to 50)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "List all of the claims within range with who owns them")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "claims") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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
			chatvars.number = 50
		end

		cursor,errorString = conn:execute("SELECT * FROM keystones WHERE abs(x - " .. chatvars.intX .. ") <= " .. chatvars.number .. " AND abs(z - " .. chatvars.intZ .. ") <= " .. chatvars.number)
		row = cursor:fetch({}, "a")
		while row do
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[row.steam].name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. "[-]")
			else
--				irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " has been exiled.")
			end

			row = cursor:fetch(row, "a")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "exile")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "exile <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Bannish a player to a special location called " .. server.commandPrefix .. "exile which must exist first.")
				irc_chat(players[chatvars.ircid].ircAlias, "While exiled, the player will not be able to command the bot.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "exile" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = chatvars.words[2]
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			-- flag the player as exiled
			players[id].exiled = 1
			players[id].silentBob = true
			players[id].canTeleport = false

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has been exiled.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " has been exiled.")
			end

			conn:execute("UPDATE players SET exiled = 1, silentBob = 1, canTeleport = 0 WHERE steam = " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "exile") or string.find(chatvars.command, "free"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "free <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Release the player from exile, however it does not return them.  They can type " .. server.commandPrefix .. "return or you can return them.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "free") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		end

		pname = chatvars.words[2]
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			-- flag the player as no longer exiled
			players[id].exiled = 2
			players[id].silentBob = false
			players[id].canTeleport = true
			message("say [" .. server.chatColour .. "]" .. players[id].name .. " has been released from exile! :D[-]")

			conn:execute("UPDATE players SET exiled = 2, silentBob = 0, canTeleport = 1 WHERE steam = " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "new") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "player <player> is not new")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Upgrade a new player to a regular without making them wait for the bot to upgrade them. They will no longer be as restricted as a new player.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "player" and string.find(chatvars.command, "is not new")) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		end

		pname = chatvars.words[2]
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			-- set the newPlayer flag to false
			players[id].newPlayer = false
			players[id].watchPlayer = false
			players[id].watchPlayerTimer = 0
			message("say [" .. server.chatColour .. "]" .. players[id].name .. " is no longer new here. Welcome back " .. players[id].name .. "! =D[-]")

			conn:execute("UPDATE players SET newPlayer = 0, watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "donor"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "add donor <player> level <0 to 7> expires <number> week or month or year")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Give a player donor status.  This doesn't have to involve money.  Donors get a few perks above other players but no items or " .. server.moneyPlural .. ".")
				irc_chat(players[chatvars.ircid].ircAlias, "Level and expiry are optional.  The default is level 1 and expiry 10 years.")
				irc_chat(players[chatvars.ircid].ircAlias, "You can also temporarily raise everyone to donor level with " .. server.commandPrefix .. "override access.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "add" and chatvars.words[2] == "donor") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		if (chatvars.words[3] == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Add donors with optional level and expiry. Defaults level 1 and 10 years.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add donor bob level 5 expires 1 week (or month or year)[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Expires automatically. 2nd protected base becomes unprotected 1 week later.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Add donors with optional level and expiry. Defaults level 1 and 10 years.")
				irc_chat(players[chatvars.ircid].ircAlias, "eg. " .. server.commandPrefix .. "add donor bob level 5 expires 1 week (or month or year)")
				irc_chat(players[chatvars.ircid].ircAlias, "Expires automatically. 2nd protected base becomes unprotected 1 week later.")
			end

			botman.faultyChat = false
			return true
		end

		tmp = {}
		tmp.sql = "UPDATE players SET donor = 1"
		tmp.level = 1
		tmp.expiry = calcTimestamp("10 years")

		for i=4,chatvars.wordCount,1 do
			if chatvars.words[i] == "expires" then
				tmp.expiry = string.sub(chatvars.command, string.find(chatvars.command, "expires") + 8)
				tmp.expiry = calcTimestamp(tmp.expiry)

				if tonumber(tmp.expiry) <= os.time() then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Invalid expiry entered. Expected <number> <week or month or year> eg. 1 month.[-]")
					else
						irc_chat(players[chatvars.ircid].ircAlias, "Invalid expiry entered. Expected <number> <week or month or year> eg. 1 month.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[i] == "level" then
				tmp.level = math.abs(ToInt(chatvars.words[i+1]))

				if tmp.level > 7 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level must be a number from 0 to 7.[-]")
					else
						irc_chat(players[chatvars.ircid].ircAlias, "Level must be a number from 0 to 7.")
					end

					botman.faultyChat = false
					return true
				end

				if tmp.level == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level must be a number from 0 to 7.[-]")
					else
						irc_chat(players[chatvars.ircid].ircAlias, "Level must be a number from 0 to 7.")
					end

					botman.faultyChat = false
					return true
				end
			end
		end

		tmp.sql = tmp.sql .. ", donorExpiry = '" .. os.date("%Y-%m-%d %H:%M:%S", tmp.expiry) .. "', donorLevel = " .. tmp.level
		tmp.pname = chatvars.words[3]
		tmp.id = LookupPlayer(tmp.pname)

		if tmp.id ~= nil then
			-- set the donor flag to true
			players[tmp.id].donor = true
			players[tmp.id].donorLevel = tmp.level
			players[tmp.id].donorExpiry = tmp.expiry
			message("say [" .. server.chatColour .. "]" .. players[tmp.id].name .. " has donated! Thanks =D[-]")
			conn:execute(tmp.sql .. " WHERE steam = " .. tmp.id)
			-- also add them to the bot's whitelist
			whitelist[tmp.id] = {}
			conn:execute("INSERT INTO whitelist (steam) VALUES (" .. tmp.id .. ")")

			send("ban remove " .. tmp.id)

			-- create or update the donor record on the shared database
			if server.serverGroup ~= "" then
				connBots:execute("INSERT INTO donors (donor, donorLevel, donorExpiry, steam, botID, serverGroup) VALUES (1, " .. tmp.level .. ", " .. tmp.expiry .. ", " .. tmp.id .. "," .. server.botID .. ",'" .. escape(server.serverGroup) .. "')")
				connBots:execute("UPDATE donors SET donor = 1, donorLevel = " .. tmp.level .. ", donorExpiry = " .. tmp.expiry .. " WHERE steam = " .. tmp.id .. " AND serverGroup = '" .. escape(server.serverGroup) .. "'")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "donor"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "remove donor <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Remove a player's donor status.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "remove" and chatvars.words[2] == "donor" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "donor ") + 6)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			-- set the donor flag to false
			players[id].donor = false
			players[id].donorLevel = 0
			players[id].donorExpiry = os.time() - 1
			message("say [" .. server.chatColour .. "]" .. players[id].name .. " no longer has donor status :([-]")

			conn:execute("UPDATE players SET donor = 0, donorLevel = 0, donorExpiry = " .. os.time() - 1 .. " WHERE steam = " .. id)

			if server.serverGroup ~= "" then
				connBots:execute("UPDATE donors SET donor = 0, donorLevel = 0, donorExpiry = " .. os.time() - 1 .. " WHERE steam = " .. id .. " AND serverGroup = '" .. escape(server.serverGroup) .. "'")
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found with that name.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "No player found with that name.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "give"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "give <item> <quantity>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Give everyone that is playing quantity of an item. The default is to give 1 of the item.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "give" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		for k, v in pairs(igplayers) do
			if accessLevel(k) > 2 then
				if chatvars.number ~= nil then
					send("give " .. k .. " " .. chatvars.words[2] .. " " .. chatvars.number)
				else
					send("give " .. k .. " " .. chatvars.words[2] .. " 1")
				end

				message("pm " .. k .. " [" .. server.chatColour .. "][i]FREE STUFF!  Press e to pick up some " .. chatvars.words[2] .. " now. =D[/i]")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. chatvars.words[2] .. " has been dropped at " .. players[k].name .. "'s feet.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, chatvars.words[2] .. " has been dropped at " .. players[k].name .. "'s feet.")
				end
			end
		end
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disallow teleport <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Prevent a player from using any teleports.  They won't be able to teleport themselves, but they can still be teleported.  Also physical teleports won't work for them.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "disallow" and chatvars.words[2] == "teleport" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "teleport") + 9)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			players[id].canTeleport = false
			message("say [" .. server.chatColour .. "] " .. players[id].name ..  " is not allowed to use teleports.[-]")

			conn:execute("UPDATE players SET canTeleport = 0 WHERE steam = " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "allow teleport <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The player will be able to use teleport commands and physical teleports again.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "allow" and chatvars.words[2] == "teleport" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "teleport") + 9)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			players[id].canTeleport = true
			message("say [" .. server.chatColour .. "] " .. players[id].name ..  " is allowed to use teleports.[-]")

			conn:execute("UPDATE players SET canTeleport = 1 WHERE steam = " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "enable waypoints")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Donors will be able to create, use and share waypoints.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" and chatvars.words[2] == "waypoints" and chatvars.words[3] == nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		server.allowWaypoints = true

		conn:execute("UPDATE server SET allowWaypoints = 1")

		if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are enabled for donors.[-]")
		else
			message("say [" .. server.chatColour .. "]Waypoints are enabled for donors.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "disable waypoints")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Waypoints will not be available.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "disable" and chatvars.words[2] == "waypoints" and chatvars.words[3] == nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		server.allowWaypoints = false

		conn:execute("UPDATE server SET allowWaypoints = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are restricted to admins.[-]")
		else
			message("say [" .. server.chatColour .. "]Waypoints are restricted to admins.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "close shop")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The shop will not be available.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "close" and chatvars.words[2] == "shop") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		message("say [" .. server.chatColour .. "]The shop is closed until further notice.[-]")
		server.allowShop = false

		conn:execute("UPDATE server SET allowShop = 0")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "open shop")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The shop will be available.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "open" and chatvars.words[2] == "shop") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		message("say [" .. server.chatColour .. "]The shop is open for business.[-]")
		server.allowShop = true

		conn:execute("UPDATE server SET allowShop = 1")
		loadShopCategories()

		botman.faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reset shop")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Restock the shop to the max quantity of each item.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reset" and chatvars.words[2] == "shop") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		message("say [" .. server.chatColour .. "]Hurrah!  >NEW< stock![-]")
		resetShop(true)
		loadShopCategories()

		botman.faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set shop open < 0 - 23 >")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Enter a number from 0 to 23 which will be the game hour that the shop opens.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "shop" and chatvars.words[3] == "open") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		if chatvars.number == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number from 0 to 23 is expected (military time)[-]")
			botman.faultyChat = false
			return true
		else
			chatvars.number = math.floor(chatvars.number)

			if tonumber(chatvars.number) < 0 or tonumber(chatvars.number) > 23 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number from 0 to 23 is expected (military time)[-]")
				botman.faultyChat = false
				return true
			end

			server.shopOpenHour = chatvars.number
			conn:execute("UPDATE server SET shopOpenHour = " .. chatvars.number)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The shop opens at " .. chatvars.number .. ":00 hours[-]")

			botman.faultyChat = false
			return true
		end
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set shop close < 0 - 23 >")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Enter a number from 0 to 23 which will be the game hour that the shop closes.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "shop" and chatvars.words[3] == "close") then

		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		if chatvars.number == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number from 0 to 23 is expected (military time)[-]")
			botman.faultyChat = false
			return true
		else
			chatvars.number = math.floor(chatvars.number)

			if tonumber(chatvars.number) < 0 or tonumber(chatvars.number) > 23 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number from 0 to 23 is expected (military time)[-]")
				botman.faultyChat = false
				return true
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The shop closes at " .. chatvars.number .. ":00 hours[-]")
			server.shopCloseHour = chatvars.number
			conn:execute("UPDATE server SET shopCloseHour = " .. chatvars.number)

			botman.faultyChat = false
			return true
		end
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set shop location <location name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Tie the shop to a location.  Buying from the shop will only be possible while in that location (excluding admins).")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "shop" and chatvars.words[3] == "location") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		str = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9)
		str = string.trim(str)
		str = LookupLocation(str)

		if str == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A location is required for this command.[-]")
			botman.faultyChat = false
			return true
		else
			message("say [" .. server.chatColour .. "]The shop is now located at ".. str .. "[-]")
			server.shopLocation = str
			conn:execute("UPDATE server SET shopLocation = '" .. str .. "'")

			botman.faultyChat = false
			return true
		end
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "clear shop location")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The shop will be accessible from anywhere.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "clear" and chatvars.words[2] == "shop" and chatvars.words[3] == "location") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		message("say [" .. server.chatColour .. "]The shop is no longer bound to a location.[-]")
		server.shopLocation = nil
		conn:execute("UPDATE server SET shopLocation = null")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "whitelist add <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Add a player to the bot's whitelist. This is not the server's whitelist and it works differently.")
				irc_chat(players[chatvars.ircid].ircAlias, "It exempts the player from ping kicks and country blocks.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "whitelist" and chatvars.words[2] == "add" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = nil
		pname = string.sub(chatvars.command, string.find(chatvars.command, "add ") + 4)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command requires a player name or no match found.")
			end

			botman.faultyChat = false
			return true
		end

		whitelist[id] = {}
		conn:execute("INSERT INTO whitelist (steam) VALUES (" .. id .. ")")

		send("ban remove " .. id)

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has been added to the whitelist.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " has been added to the whitelist.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "whitelist remove <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Remove a player from the whitelist.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "whitelist" and chatvars.words[2] == "remove" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = nil
		pname = string.sub(chatvars.command, string.find(chatvars.command, "remove ") + 7)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command requires a player name or no match found.")
			end

			botman.faultyChat = false
			return true
		end

		whitelist[id] = nil
		conn:execute("DELETE FROM whitelist WHERE steam = " .. id)

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " is no longer whitelisted.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " is no longer whitelisted.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "player") or string.find(chatvars.command, "excl") or string.find(chatvars.command, "igno"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "ignore player <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Allowed the player to have uncraftable inventory and ignore hacker like activity such as teleporting and flying.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "ignore" and chatvars.words[2] == "player" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = nil
		pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command requires a player name or no match found.")
			end

			botman.faultyChat = false
			return true
		end

		if (players[id]) then
			players[id].ignorePlayer = true

			conn:execute("UPDATE players SET ignorePlayer = 1 WHERE steam = " .. id)
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " is allowed to carry uncraftable items, fly, teleport and other fun stuff.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias,players[id].name .. " is allowed to carry uncraftable items, fly, teleport and other fun stuff.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "player") or string.find(chatvars.command, "incl"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "include player <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Treat the player the same as other players. They will not be allowed uncraftable inventory and hacker like activity will be treated as such.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "include" and chatvars.words[2] == "player" and chatvars.words[3] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = nil
		pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command requires a player name or no match found.")
			end

			botman.faultyChat = false
			return true
		end

		if (players[id]) then
			players[id].ignorePlayer = false

			conn:execute("UPDATE players SET ignorePlayer = 0 WHERE steam = " .. id)
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " will be subject to the same restrictions as other players.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " will be subject to the same restrictions as other players.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "player") or string.find(chatvars.command, "block"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "block player <player>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "unblock player <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Prevent a player from using IRC.  Other stuff may be blocked in the future.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "block" or chatvars.words[1] == "unblock") and chatvars.words[2] == "player" and chatvars.words[3] ~= nil then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = nil
		pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Command requires a player name or no match found.")
			end

			botman.faultyChat = false
			return true
		end

		if (players[id]) then
			if chatvars.words[1] == "block" then
				players[id].denyRights = true
				conn:execute("UPDATE players SET denyRights = 1 WHERE steam = " .. id)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " will be ignored on IRC.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias,players[id].name .. " will be ignored on IRC.")
				end
			else
				players[id].denyRights = false
				conn:execute("UPDATE players SET denyRights = 0 WHERE steam = " .. id)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " can talk to the bot on IRC.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias,players[id].name .. " can talk to the bot on IRC.")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "prisoner") or string.find(chatvars.command, "arrest"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "prisoner <player> arrested <reason for arrest>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "prisoner <player> (read the reason if one is recorded)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "You can record or view the reason for a player being arrested.  If they are released, this record is destroyed.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "prisoner") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		reason = nil

		if string.find(chatvars.command, "arrested") then
			prisoner = string.sub(chatvars.command, string.find(chatvars.command, "prisoner ") + 9, string.find(chatvars.command, "arrested") -1)
			reason = string.sub(chatvars.command, string.find(chatvars.command, "arrested ") + 9)
		else
			prisoner = string.sub(chatvars.command, string.find(chatvars.command, "prisoner ") + 9)
		end

		prisoner = stripQuotes(string.trim(prisoner))
		prisonerid = LookupPlayer(prisoner)
		prisoner = players[prisonerid].name

		if (prisonerid == nil or not players[prisonerid].prisoner) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. prisoner .. " is not a prisoner[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, prisoner .. " is not a prisoner.")
			end

			botman.faultyChat = false
			return true
		end

		if players[prisonerid].prisoner then
			if reason ~= nil then
				players[prisonerid].prisonReason = reason
				conn:execute("UPDATE players SET prisonReason = '" .. escape(reason) .. "' WHERE steam = " .. prisonerid)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added a reason for prisoner " .. prisoner .. "'s arrest[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "Reason for prisoner " .. prisoner .. "'s arrest noted.")
				end
			else
				if players[prisonerid].prisonReason ~= nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. prisoner .. " was arrested for " .. players[prisonerid].prisonReason .. "[-]")
					else
						irc_chat(players[chatvars.ircid].ircAlias, prisoner .. " was arrested for " .. players[prisonerid].prisonReason)
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] No reason is recorded for " .. prisoner .. "'s arrest.[-]")
					else
						irc_chat(players[chatvars.ircid].ircAlias, "No reason is recorded for " .. prisoner .. "'s arrest.")
					end
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "arrest") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "jail"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "arrest <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Send a player to prison.  If the location prison does not exist they are put into timeout instead.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "arrest") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		prisoner = string.sub(chatvars.command, string.find(chatvars.command, "arrest ") + 7)
		prisoner = string.trim(prisoner)
		prisonerid = LookupPlayer(prisoner)

		if prisonerid == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. prisoner .. "[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "No player found called " .. prisoner)
			end

			botman.faultyChat = false
			return true
		end

		prisoner = players[prisonerid].name

		if (players[prisonerid]) then
			if (players[prisonerid].timeout == true) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. prisoner .. " is in timeout. " .. server.commandPrefix .. "return them first[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, prisoner .. " is in timeout. Return them first")
				end

				botman.faultyChat = false
				return true
			end
		end

		if (chatvars.playername ~= "Server") then
			if (accessLevel(prisonerid) < 3 and botman.ignoreAdmins == true and prisonerid ~= chatvars.playerid) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Staff can not be arrested.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "Staff can not be arrested.")
				end

				botman.faultyChat = false
				return true
			end
		end

		if locations["prison"] == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Create a location called prison first. Sending them to timeout instead..[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Create a location called prison first. Sending them to timeout instead.")
			end

			gmsg(server.commandPrefix .. "timeout " .. prisoner)
			botman.faultyChat = false
			return true
		end

		arrest(prisonerid, "Arrested by admin", 10000, 44640)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "timer"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "resettimers <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Normally a player needs to wait a set time after " .. server.commandPrefix .. "base before they can use it again. This zeroes that timer and also resets their gimmies.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "resettimers") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = nil
		pname = string.sub(chatvars.command, string.find(chatvars.command, "resettimers ") + 12)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (pname == nil and chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required.[-]")
			botman.faultyChat = false
			return true
		end

		if (players[id]) then
			players[id].baseCooldown = 0
			players[id].gimmeCount = 0

			conn:execute("UPDATE players SET baseCooldown = 0, gimmeCount = 0 WHERE steam = " .. id)
		end

		message("say [" .. server.chatColour .. "]Cooldown timers have been reset for " .. players[id].name .. "[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "exclude") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "rule"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "exclude admins")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The normal rules that apply to players will not apply to admins.  They can go anywhere they want.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "exclude" and chatvars.words[2] == "admins") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		botman.ignoreAdmins = true

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admins can ignore the server rules.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Admins can ignore the server rules.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "include") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "rule"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "include admins")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Admins are treated the same as normal players and the bot will punish or block them as it would the players.  This is mainly used to test the bot while still being an admin.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "includeadmins") or (chatvars.words[1] == "include" and chatvars.words[2] == "admins") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		botman.ignoreAdmins = false

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admins must obey the server rules.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Admins must obey the server rules.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "freeze") or string.find(chatvars.command, "player") or string.find(chatvars.command, "stop"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "freeze <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Bind a player to their current position.  They get teleported back if they move.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "freeze" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "freeze") + 7)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (pname == nil or pname == "") then
			botman.faultyChat = false
			return true
		end

		if (id ~= nil) then
			if accessLevel(id) < 3 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The staff are cold enough as it is.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				end

				botman.faultyChat = false
				return true
			end

			players[id].freeze = true
			players[id].prisonxPosOld = math.floor(players[id].xPos)
			players[id].prisonyPosOld = math.ceil(players[id].yPos)
			players[id].prisonzPosOld = math.floor(players[id].zPos)
			message("say [" .. server.chatColour .. "]STOP RIGHT THERE CRIMINAL SCUM![-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "freeze") or string.find(chatvars.command, "player") or string.find(chatvars.command, "stop"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "unfreeze <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Allow the player to move again.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "unfreeze" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "unfreeze") + 9)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (pname == nil or pname == "") then
			botman.faultyChat = false
			return true
		end

		if (players[id]) then
			players[id].freeze = false
			players[id].prisonxPosOld = 0
			players[id].prisonyPosOld = 0
			players[id].prisonzPosOld = 0
			message("say [" .. server.chatColour .. "]Citizen " .. players[id].name .. ", you are free to go.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "move") or string.find(chatvars.command, "player") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "move <player> to <location>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Teleport a player to a location. To teleport them to another player use the send command.")
				irc_chat(players[chatvars.ircid].ircAlias, "If the player is offline, they will be moved to the location when they next join.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "move") and chatvars.words[2] ~= nil and string.find(chatvars.command, " to ") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "move") + 5, string.find(chatvars.command, " to ") - 1)
		pname = string.trim(pname)

		location = string.sub(chatvars.command, string.find(chatvars.command, " to ") + 4)
		location = string.trim(location)

		loc = LookupLocation(location)
		id = LookupPlayer(pname)

		if (id ~= nil and loc ~= nil) then
			-- if the player is ingame, send them to the lobby otherwise flag it to happen when they rejoin
			if (igplayers[id]) then
				cmd = "tele " .. id .. " " .. locations[loc].x .. " " .. locations[loc].y .. " " .. locations[loc].z
				igplayers[id].lastTP = cmd
				teleport(cmd, true)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " has been sent to " .. locations[loc].name .. "[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "Player " .. players[id].name .. " has been sent to " .. locations[loc].name)
				end
			else
				players[id].location = loc

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " will spawn at " .. locations[loc].name .. " next time they join.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "Player " .. players[id].name .. " will spawn at " .. locations[loc].name .. " next time they join.")
				end

				conn:execute("UPDATE players SET location = '" .. loc .. "' WHERE steam = " .. id)
			end
		end

		players[id].xPosOld = locations[loc].x
		players[id].yPosOld = locations[loc].y
		players[id].zPosOld = locations[loc].z

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "home") or string.find(chatvars.command, "player") or string.find(chatvars.command, "send"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "sendhome <player> or " .. server.commandPrefix .. "sendhome2 <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Teleport a player to their first or second base.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "sendhome" or chatvars.words[1] == "sendhome2") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "sendhome") + 9)
		pname = string.trim(pname)

		if (pname == "") then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required or could not be found for this command[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "A player name is required or could not be found for this command")
			end

			botman.faultyChat = false
			return true
		else
			id = 0
			id = LookupPlayer(pname)

			if (id == 0) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No in-game players found with that name.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "No in-game players found called " .. pname)
				end

				botman.faultyChat = false
				return true
			end

			if (players[id].timeout == true) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is in timeout. " .. server.commandPrefix .. "return them first[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " is in timeout. Return them first.")
				end

				botman.faultyChat = false
				return true
			end

			-- first record the current x y z
			if (igplayers[id]) then
				players[id].xPosOld = math.floor(igplayers[id].xPos)
				players[id].yPosOld = math.ceil(igplayers[id].yPos)
				players[id].zPosOld = math.floor(igplayers[id].zPos)
			end

			if (chatvars.words[1] == "sendhome") then
				if (players[id].homeX == 0 and players[id].homeZ == 0) then
					if server.coppi then
						prepareTeleport(id, "")
						send("teleh " .. id)
					
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has been sent to their bed.[-]")
						else
							irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " has been sent to their bed.")
						end					
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has not set a base yet.[-]")
						else
							irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " has not set a base yet.")
						end
					end

					botman.faultyChat = false
					return true
				else
					if (igplayers[id]) then
						cmd = "tele " .. id .. " " .. players[id].homeX .. " " .. players[id].homeY .. " " .. players[id].homeZ
						prepareTeleport(id, cmd)
						teleport(cmd, true)
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has been sent home")
					else
						irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " has been sent home.")
					end
				end
			else
				if (players[id].home2X == 0 and players[id].home2Z == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has not set a 2nd base yet.[-]")
					else
						irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " has not set a 2nd base yet.")
					end

					botman.faultyChat = false
					return true
				else
					if (igplayers[id]) then
						cmd = "tele " .. id .. " " .. players[id].home2X .. " " .. players[id].home2Y .. " " .. players[id].home2Z
						prepareTeleport(id, cmd)
						teleport(cmd, true)
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has been sent home")
					else
						irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " has been sent home.")
					end
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "watch") or string.find(chatvars.command, "player") or string.find(chatvars.command, "new"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "watch <player>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "watch new players")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Flag a player or all current new players for extra attention and logging.  New players are watched by default.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "watch") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		if (chatvars.words[2] == "new" and chatvars.words[3] == "players") then
			for k,v in pairs(players) do
				if v.newPlayer == true then
					v.watchPlayer = true
					v.watchPlayerTimer = os.time() + 2419200 -- 1 month or until not new
					conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + 2419200 .. " WHERE steam = " .. k)
				end
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players will be watched.[-]")

			botman.faultyChat = false
			return true
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "watch ") + 6)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if not (id == nil) then
			players[id].watchPlayer = true
			players[id].watchPlayerTimer = os.time() + 259200 -- 3 days
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admins will be alerted whenever " .. players[id].name ..  " enters a base.[-]")
			end

			conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + 259200 .. " WHERE steam = " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "watch") or string.find(chatvars.command, "player") or string.find(chatvars.command, "stop"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "stop watching <player>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "stop watching everyone")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Stop watching a player or stop watching everyone.  Activity will still be recorded but admins won't see private messages about it.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "stop" and chatvars.words[2] == "watching") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		if (chatvars.words[3] == "everyone") then
			for k,v in pairs(players) do
				v.watchPlayer = false
				v.watchPlayerTimer = 0
				conn:execute("UPDATE players SET watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. k)
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Nobody is being watched right now.[-]")

			botman.faultyChat = false
			return true
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "watching ") + 9)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if not (id == nil) then
			players[id].watchPlayer = false
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name ..  " will no longer be watched.[-]")
			end

			conn:execute("UPDATE players SET watchPlayer = 0 WHERE steam = " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "send") or string.find(chatvars.command, "player") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "send <player1> to <player2>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Teleport a player to another player even if the other player is offline.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "send") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		id1 = nil
		id2 = nil

		for i=2,chatvars.wordCount,1 do
			if (chatvars.words[i] ~= "to") then
				if id1 ~= nil and id2 == nil then
					id2 = LookupPlayer(chatvars.words[i])
				end

				if id1 == nil then
					id1 = LookupPlayer(chatvars.words[i])
				end
			end
		end

		if (id ~= nil and id2 ~= nil) then
			if (players[id1].timeout == true) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id1].name .. " is in timeout. Return them first[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, players[id1].name .. " is in timeout. Return them first.")
				end

				botman.faultyChat = false
				return true
			end

			-- first record the current x y z
			players[id1].xPosOld = math.floor(players[id1].xPos)
			players[id1].yPosOld = math.floor(players[id1].yPos)
			players[id1].zPosOld = math.floor(players[id1].zPos)

			if (igplayers[id2]) then
				cmd = "tele " .. id1 .. " " .. id2
				prepareTeleport(id1, cmd)
				teleport(cmd, true)
			else
				cmd = "tele " .. id1 .. " " .. math.floor(players[id2].xPos) .. " " .. math.ceil(players[id2].yPos) .. " " .. math.floor(players[id2].zPos)
				prepareTeleport(id1, cmd)
				teleport(cmd, true)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "burn") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "burn <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set a player on fire.  It usually kills them.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "burn" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		if (chatvars.words[2] ~= nil) then
			pname = chatvars.words[2]
			pid = LookupPlayer(pname)

			if pid == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No in-game players found with that name.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "No in-game players found called " .. pname)
				end

				botman.faultyChat = false
				return true
			end
		end

		send("buffplayer " .. pid .. " burning")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You set " .. players[pid].name .. " on fire![-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "You set " .. players[pid].name .. " on fire!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shit") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "shit <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Give a player the shits for shits and giggles.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "shit" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		if (chatvars.words[2] ~= nil) then
			pname = chatvars.words[2]
			pid = LookupPlayer(pname)

			if pid == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No in-game players found with that name.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "No in-game players found called " .. pname)
				end

				botman.faultyChat = false
				return true
			end
		end

		send("buffplayer " .. pid .. " dysentery")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You showed " .. players[pid].name .. " that you give a shit.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "You showed " .. players[pid].name .. " that you give a shit.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "mend") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "mend <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Remove the brokenLeg buff from a player or yourself if no name given.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "mend") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pid = chatvars.playerid

		if (chatvars.words[2] ~= nil) then
			pname = chatvars.words[2]
			pid = LookupPlayer(pname)
		end

		send("debuffplayer " .. pid .. " sprainedLeg")
		send("debuffplayer " .. pid .. " brokenLeg")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You fixed " .. players[pid].name .. "'s legs[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "You fixed " .. players[pid].name .. "'s legs")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "cure") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "cure <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Cure a player or yourself if no name given.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "cure") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pid = chatvars.playerid

		if (chatvars.words[2] ~= nil) then
			pname = chatvars.words[2]
			pid = LookupPlayer(pname)
		end

		send("buffplayer " .. pid .. " cured")
		send("debuffplayer " .. pid .. " dysentery")
		send("debuffplayer " .. pid .. " dysentery2")
		send("debuffplayer " .. pid .. " foodPoisoning")
		send("debuffplayer " .. pid .. " infection")
		send("debuffplayer " .. pid .. " infection1")
		send("debuffplayer " .. pid .. " infection2")
		send("debuffplayer " .. pid .. " infection3")
		send("debuffplayer " .. pid .. " infection4")


		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You cured " .. players[pid].name .. "[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "You cured " .. players[pid].name)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "warm") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "warm <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Warm a player or yourself if no name given.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "warm") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pid = chatvars.playerid

		if (chatvars.words[2] ~= nil) then
			pname = chatvars.words[2]
			pid = LookupPlayer(pname)
		end

		send("buffplayer " .. pid .. " stewWarming")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[pid].name .. " is warming up.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, players[pid].name .. " is warming up.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "cool") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "cool <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Cool a player or yourself if no name given.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "cool") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pid = chatvars.playerid

		if (chatvars.words[2] ~= nil) then
			pname = chatvars.words[2]
			pid = LookupPlayer(pname)
		end

		send("buffplayer " .. pid .. " redTeaCooling")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[pid].name .. " is cooling down.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, players[pid].name .. " is cooling down.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "heal") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "heal <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Apply big firstaid buff to a player or yourself if no name given.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "heal") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pid = chatvars.playerid

		if (chatvars.words[2] ~= nil) then
			pname = chatvars.words[2]
			pid = LookupPlayer(pname)
		end

		send("buffplayer " .. pid .. " firstAid")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You gave " .. players[pid].name .. " firstaid.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "You gave " .. players[pid].name .. " firstaid.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shut") or string.find(chatvars.command, "stop") or string.find(chatvars.command, "bot"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "shutdown bot")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "While not essential as it seems to work just fine, you can tell the bot to save all pending player data, before you quit Mudlet.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "shutdown" and chatvars.words[2] == "bot") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		irc_chat(server.ircMain, "Saving player data.  Wait a minute before stopping Mudlet or until I say I'm ready.")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Saving player data.  Wait a minute before stopping Mudlet or until I say I'm ready.[-]")
			shutdownBot(chatvars.playerid)
		else
			tempTimer( 3, [[shutdownBot(0)]] ) -- This timer is necessary to stop Mudlet freezing.  It doesn't seem to like running this function as server immediately but is fine with a delay.
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "clear") or string.find(chatvars.command, "stack"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reset stack")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "If you have changed stack sizes and the bot is mistakenly abusing players for overstacking, you can make the bot forget the stack sizes.")
				irc_chat(players[chatvars.ircid].ircAlias, "It will re-learn them from the server as players overstack beyond the new stack limits.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "clear" or chatvars.words[1] == "reset") and chatvars.words[2] == "stack" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		stackLimits = {}

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot's record of stack limits has been wiped.  It will re-learn them from the server as players overstack items.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "The bot's record of stack limits has been wiped.  It will re-learn them from the server as players overstack items.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ban") or string.find(chatvars.command, "black"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "unban <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Remove a player from the server's ban list")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "unban" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "unban ") + 6)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "No player found called " .. pname)
			end

			botman.faultyChat = false
			return true
		end

		send("ban remove " .. id)

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has been unbanned.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " has been unbanned.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ban") or string.find(chatvars.command, "black"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "ban <player> (ban for 10 years with the reason 'banned')")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "ban <player> reason <reason for ban> (ban for 10 years with the reason you provided)")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "ban <player> time <number> hour or day or month or year reason <reason for ban>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Ban a player from the server.  You can optionally give a reason and a duration. The default is a 10 year ban with the reason 'banned'.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "ban" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		reason = "banned"
		duration = "10 years"

		if not string.find(chatvars.command, "reason") and not string.find(chatvars.command, "time") then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4)
		end

		if string.find(chatvars.command, "reason") then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, "reason") - 2)

			if string.find(chatvars.command, " time") then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, "time") - 2)
			end
		end

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "No player found called " .. pname)
			end

			botman.faultyChat = false
			return true
		end

		if string.find(chatvars.command, "reason") then
			reason = string.sub(chatvars.command, string.find(chatvars.command, "reason ") + 7)
		end

		if string.find(chatvars.command, "time") then
			if string.find(chatvars.command, "reason") then
				duration = string.sub(chatvars.command, string.find(chatvars.command, "time ") + 5, string.find(chatvars.command, "reason") - 2)
			else
				duration = string.sub(chatvars.command, string.find(chatvars.command, "time ") + 5)
			end
		end

		send("ban add " .. id .. " " .. duration .. " " .. reason)

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has been banned " .. duration .. " for " .. reason .. ".[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " has been banned " .. duration .. " for " .. reason)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "own") or string.find(chatvars.command, "staff"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "list owners")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Lists the server owners and shows who if any are playing.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "list" and chatvars.words[2] == "owners" and chatvars.words[3] == nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		listOwners(chatvars.playerid)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "admins") or string.find(chatvars.command, "staff"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "list admins")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Lists the server admins and shows who if any are playing.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "list" and chatvars.words[2] == "admins" and chatvars.words[3] == nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		listAdmins(chatvars.playerid)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "mods") or string.find(chatvars.command, "staff"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "list mods")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Lists the server mods and shows who if any are playing.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "list" and chatvars.words[2] == "mods" and chatvars.words[3] == nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		listMods(chatvars.playerid)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "staff"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "list staff")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Lists the server staff and shows who if any are playing.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "list" and chatvars.words[2] == "staff" and chatvars.words[3] == nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		listStaff(chatvars.playerid)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or string.find(chatvars.command, "item") or string.find(chatvars.command, "bad"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "add bad item <item>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Add an item to the list of bad items.  The default action is to timeout the player.")
				irc_chat(players[chatvars.ircid].ircAlias, "See also " .. server.commandPrefix .. "ignore player <name> and " .. server.commandPrefix .. "include player <name>")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "add" and chatvars.words[2] == "bad" and chatvars.words[3] == "item" and chatvars.words[4] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		bad = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "bad item") + 9)

		conn:execute("INSERT INTO badItems SET item = '" .. bad .. "'")

		badItems[bad] = {}

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added " .. bad .. " to the list of bad items[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "You added " .. bad .. " to the list of bad items.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rem") or string.find(chatvars.command, "item") or string.find(chatvars.command, "bad"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "remove bad item <item>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Remove an item to the list of bad items.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "remove" and chatvars.words[2] == "bad" and chatvars.words[3] == "item" and chatvars.words[4] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		bad = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "bad item") + 9)

		conn:execute("DELETE FROM badItems WHERE item = '" .. bad .. "'")

		badItems[bad] = nil

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed " .. bad .. " from the list of bad items.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "You removed " .. bad .. " from the list of bad items.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "item") or string.find(chatvars.command, "bad"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "bad items")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "List the items that are not allowed in player inventories and what action is taken.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "bad" and chatvars.words[2] == "items") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 3) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 3) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I scan for these items in inventory:[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Item        Action[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "I scan for these items in inventory:")
			irc_chat(players[chatvars.ircid].ircAlias, "Item        Action")
		end

		for k, v in pairs(badItems) do
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. k .. "   " .. v.action  .. "[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, k .. "   " .. v.action)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or string.find(chatvars.command, "item") or string.find(chatvars.command, "rest"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "add restricted item <item name> qty <count> action <action> access <level>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Add an item to the list of restricted items.")
				irc_chat(players[chatvars.ircid].ircAlias, "Valid actions are timeout, ban, exile  and watch")
				irc_chat(players[chatvars.ircid].ircAlias, "eg. " .. server.commandPrefix .. "add restricted item tnt qty 5 action timeout access 90")
				irc_chat(players[chatvars.ircid].ircAlias, "Players with access > 90 will be sent to timeout for more than 5 tnt.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "add" and chatvars.words[2] == "restricted") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		if (chatvars.words[3] == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Add an item to the inventory scanner for special attention.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add restricted item tnt qty 5 action timeout access 90[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players with access > 90 will be sent to timeout for more than 5 tnt.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, exile, and watch[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Add an item to the inventory scanner for special attention.")
				irc_chat(players[chatvars.ircid].ircAlias, "eg. " .. server.commandPrefix .. "add restricted item tnt qty 5 action timeout access 90.")
				irc_chat(players[chatvars.ircid].ircAlias, "Players with access > 90 will be sent to timeout for more than 5 tnt.")
				irc_chat(players[chatvars.ircid].ircAlias, "Valid actions are timeout, ban, exile, and watch")
			end

			botman.faultyChat = false
			return true
		end

		item = ""
		qty = 0
		access = 100
		action = "timeout"

		for i=3,chatvars.wordCount,1 do
			if chatvars.words[i] == "item" then
				item = chatvars.wordsOld[i+1]
			end

			if chatvars.words[i] == "qty" then
				qty = chatvars.words[i+1]
			end

			if chatvars.words[i] == "access" then
				access = chatvars.words[i+1]
			end

			if chatvars.words[i] == "action" then
				action = chatvars.wordsOld[i+1]
			end
		end

		if action ~= "timeout" and action ~= "ban" and action ~= "exile" and action ~= "watch" then
			action = "timeout"
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Invalid action entered, using timeout instead.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, exile, and watch.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Invalid action entered, using timeout instead.")
				irc_chat(players[chatvars.ircid].ircAlias, "Valid actions are timeout, ban, exile, and watch.")
			end
		end

		if item == "" or access == 100 then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Item, qty and access are required.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add restricted item mineCandyTin qty 20 access 99 action timeout[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, exile. Bans last 1 day.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Item, qty and access are required.")
				irc_chat(players[chatvars.ircid].ircAlias, "eg. " .. server.commandPrefix .. "add restricted item mineCandyTin qty 20 access 99 action timeout")
				irc_chat(players[chatvars.ircid].ircAlias, "Valid actions are timeout, ban, exile. Bans last 1 day.")
			end
		else
			conn:execute("INSERT INTO restrictedItems (item, qty, accessLevel, action) VALUES ('" .. escape(item) .. "'," .. qty .. "," .. access .. ",'" .. action .. "') ON DUPLICATE KEY UPDATE item = '" .. escape(item) .. "', qty = " .. qty .. ", accessLevel = " .. access .. ", action = '" .. action .. "'")
			conn:execute("INSERT INTO memRestrictedItems (item, qty, accessLevel, action) VALUES ('" .. escape(item) .. "'," .. qty .. "," .. access .. ",'" .. action .. "') ON DUPLICATE KEY UPDATE item = '" .. escape(item) .. "', qty = " .. qty .. ", accessLevel = " .. access .. ", action = '" .. action .. "'")

			restrictedItems[item] = {}
			restrictedItems[item].qty = tonumber(qty)
			restrictedItems[item].accessLevel = tonumber(access)
			restrictedItems[item].action = action

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added " .. item .. " quantity " .. qty .. " with minimum access level " .. access .. " and action " .. action .. " to restricted items.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "You added " .. item .. " quantity " .. qty .. " with minimum access level " .. access .. " and action " .. action .. " to restricted items.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rem") or string.find(chatvars.command, "item") or string.find(chatvars.command, "rest"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "remove restricted item <item name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Remove an item from the list of restricted items.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "remove" and chatvars.words[2] == "restricted" and chatvars.words[3] == "item" and chatvars.words[4] ~= nil) then
		if (chatvars.accessLevel > 1) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a restricted command[-]")
			botman.faultyChat = false
			return true
		end

		bad = string.sub(chatvars.command, string.find(chatvars.command, "restricted item") + 16)

		conn:execute("DELETE FROM restrictedItems WHERE item = '" .. bad .. "'")
		conn:execute("DELETE FROM memRestrictedItems WHERE item = '" .. bad .. "'")

		restrictedItems[bad] = nil
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed " .. bad .. " from the list of restricted items[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "item") or string.find(chatvars.command, "rest"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "restricted items")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "List the items that new players are not allowed to have in inventory and what action is taken.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "restricted" and chatvars.words[2] == "items") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I scan for these restricted items in inventory:[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Item      Quantity      Min Access Level[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "I scan for these restricted items in inventory:")
			irc_chat(players[chatvars.ircid].ircAlias, "Item.........Quantity..........Min Access Level")
		end

		for k, v in pairs(restrictedItems) do
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. k .. " max qty " .. v.qty .. " min access " .. v.accessLevel .. " action " .. v.action .. "[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, k .. " max qty " .. v.qty .. " min access " .. v.accessLevel .. " action " .. v.action)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "slot") or string.find(chatvars.command, "player") or string.find(chatvars.command, "rese"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reserve slot <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Give a player the right to take a reserved slot when the server is full.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reserve" and chatvars.words[2] == "slot") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, " slot ") + 6)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if not (id == nil) then
			players[id].reserveSlot = true
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name ..  " can take a reserved slot when the server is full.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Player " .. players[id].name ..  " can take a reserved slot when the server is full.")
			end

			conn:execute("UPDATE players SET reserveSlot = 1 WHERE steam = " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "slot") or string.find(chatvars.command, "player") or string.find(chatvars.command, "rese"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "unreserve slot <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Remove a player's right to take a reserved slot when the server is full.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "unreserve" and chatvars.words[2] == "slot") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, " slot ") + 6)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if not (id == nil) then
			players[id].reserveSlot = false
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name ..  " can not reserve a slot when the server is full.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Player " .. players[id].name ..  " can not reserve a slot when the server is full.")
			end

			conn:execute("UPDATE players SET reserveSlot = 0 WHERE steam = " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

-- ###################  do not allow remote commands beyond this point ################

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(players[chatvars.ircid].ircAlias, "")
		irc_chat(players[chatvars.ircid].ircAlias, "Admin In-Game Only:")
		irc_chat(players[chatvars.ircid].ircAlias, "===================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "who") or string.find(chatvars.command, "visit"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "who visited <player> days <days> hours <hrs> range <dist> height <ht>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "See who visited a player location or base.")
				irc_chat(players[chatvars.ircid].ircAlias, "Example with defaults: " .. server.commandPrefix .. "who visited player smeg days 1 hours 0 range 10 height 5")
				irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "who visited bed smeg")				
				irc_chat(players[chatvars.ircid].ircAlias, "Add base to just see base visitors. Setting hours will reset days to zero.")
				irc_chat(players[chatvars.ircid].ircAlias, "Use this command to discover who's been at the player's location.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (chatvars.words[1] == "who" and chatvars.words[2] == "visited") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end
		
	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end		

		if (chatvars.words[3] == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]See who visited a player location or base.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Example with defaults:[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who visited player smeg days 1 hours 0 range 10 height 5[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who visited bed smeg[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Add base to just see their base visitors[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Setting hours will reset days to zero[-]")

			botman.faultyChat = false
			return true
		end

		tmp = {}
		tmp.days = 1
		tmp.hours = 0
		tmp.range = 10
		tmp.height = 5
		tmp.basesOnly = "player"

		for i=3,chatvars.wordCount,1 do
			if chatvars.words[i] == "player" or chatvars.words[i] == "bed" then
				tmp.name = chatvars.words[i+1]
				tmp.steam = LookupPlayer(tmp.name)

				if tmp.steam and chatvars.words[i] == "player" then
					tmp.player = true
					tmp.x = players[tmp.steam].xPos
					tmp.y = players[tmp.steam].yPos
					tmp.z = players[tmp.steam].zPos
				end

				if tmp.steam and chatvars.words[i] == "bed" then
					tmp.bed = true
					tmp.x = players[tmp.steam].bedX
					tmp.y = players[tmp.steam].bedY
					tmp.z = players[tmp.steam].bedZ
				end
			end

			if chatvars.words[i] == "range" then
				tmp.range = tonumber(chatvars.words[i+1])
			end

			if chatvars.words[i] == "days" then
				tmp.days = tonumber(chatvars.words[i+1])
				tmp.hours = 0
			end

			if chatvars.words[i] == "hours" then
				tmp.hours = tonumber(chatvars.words[i+1])
				tmp.days = 0
			end

			if chatvars.words[i] == "base" then
				tmp.baseOnly = "base"
			end

			if chatvars.words[i] == "x" then
				tmp.x = tonumber(chatvars.words[i+1])
			end

			if chatvars.words[i] == "y" then
				tmp.y = tonumber(chatvars.words[i+1])
			end

			if chatvars.words[i] == "z" then
				tmp.z = tonumber(chatvars.words[i+1])
			end

			if chatvars.words[i] == "height" then
				tmp.height = tonumber(chatvars.words[i+1])
			end
		end

		if (tmp.basesOnly == "base") and tmp.steam then
			if players[tmp.steam].homeX ~= 0 and players[tmp.steam].homeZ ~= 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of base 1 of " .. players[tmp.steam].name .. " at " .. players[tmp.steam].homeX .. " " .. players[tmp.steam].homeY .. " " .. players[tmp.steam].homeZ .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
				dbWho(chatvars.playerid, players[tmp.steam].homeX, players[tmp.steam].homeY, players[tmp.steam].homeZ, tmp.range, tmp.days, tmp.hours, tmp.height, true)
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. " does not have a base set yet.[-]")
			end

			if players[tmp.steam].home2X ~= 0 and players[tmp.steam].home2Z ~= 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of base 2 of " .. players[tmp.steam].name .. " at " .. players[tmp.steam].home2X .. " " .. players[tmp.steam].home2Y .. " " .. players[tmp.steam].home2Z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
				dbWho(chatvars.playerid, players[tmp.steam].home2X, players[tmp.steam].home2Y, players[tmp.steam].home2Z, tmp.range, tmp.days, tmp.hours, tmp.height, true)
			end
		end

		if tmp.basesOnly == "player" and tmp.steam then
			if tmp.player then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. " at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
			end

			if tmp.bed then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. "'s bed at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
			end

			dbWho(chatvars.playerid, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height, true)
		end

		if not tmp.steam then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
			dbWho(chatvars.playerid, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height, true)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "home") or string.find(chatvars.command, "admin"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "bases (or homes)")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "bases range <number>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "bases near <player> range <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "See what player bases are nearby.  You can use it on yourself or on a player.")
				irc_chat(players[chatvars.ircid].ircAlias, "Range and player are optional.  The default range is 200 metres.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "bases" or chatvars.words[1] == "homes") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		alone = true
		if (chatvars.number == nil) then chatvars.number = 201 end

		if (not string.find(chatvars.command, "range")) and (not string.find(chatvars.command, "near")) then
			for k, v in pairs(players) do
				if (v.homeX) and (v.homeX ~= 0 and v.homeZ ~= 0) then
					dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, v.homeX, v.homeZ)

					if dist < tonumber(chatvars.number) then
						if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of you are:[-]") end

						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%-8.2d", dist) .. " meters[-]")
						alone = false
					end
				end

				if (v.home2X) and (v.home2X ~= 0 and v.home2Z ~= 0) then
					dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, v.home2X, v.home2Z)

					if dist < tonumber(chatvars.number) then
						if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of you are:[-]") end

						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%-8.2d", dist) .. " meters[-]")
						alone = false
					end
				end
			end

			if (alone == true) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There are none within " .. chatvars.number .. " meters of you.")
			end
		else
			if string.find(chatvars.command, "range") then
				name1 = string.sub(chatvars.command, string.find(chatvars.command, "near") + 5, string.find(chatvars.command, "range") - 1)
				chatvars.number = string.sub(chatvars.command, string.find(chatvars.command, "range") + 6)
			else
				name1 = string.sub(chatvars.command, string.find(chatvars.command, "near") + 5)
			end

			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				for k, v in pairs(players) do
					if (v.homeX) and (v.homeX ~= 0 and v.homeZ ~= 0) then
						dist = distancexz(igplayers[pid].xPos, igplayers[pid].zPos, v.homeX, v.homeZ)

						if dist < tonumber(chatvars.number) then
							if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of " .. players[pid].name .. " are:[-]") end

							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%-8.2d", dist) .. " meters[-]")
							alone = false
						end
					end

					if (v.home2X) and (v.home2X ~= 0 and v.home2Z ~= 0) then
						dist = distancexz(igplayers[pid].xPos, igplayers[pid].zPos, v.home2X, v.home2Z)

						if dist < tonumber(chatvars.number) then
							if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of " .. players[pid].name .. " are:[-]") end

							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%-8.2d", dist) .. " meters[-]")
							alone = false
						end
					end
				end

				if (alone == true) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There are none within " .. chatvars.number .. " meters of " .. players[pid].name .. "[-]")
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. name1 .. "[-]")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or string.find(chatvars.command, "admin"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "admin add <player or steam or game ID> level <0-2>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Give a player admin status and a level.")
				irc_chat(players[chatvars.ircid].ircAlias, "Server owners are level 0, admins are level 1 and moderators level 2.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (string.find(chatvars.command, "admin add ") and chatvars.accessLevel == 0) and (chatvars.playerid ~= 0) then
		if string.find(chatvars.command, "level") then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "admin add ") + 10, string.find(chatvars.command, "level") - 1)
		else
			pname = string.sub(chatvars.command, string.find(chatvars.command, "admin add ") + 10)
		end

		pname = string.trim(pname)
		id = LookupPlayer(pname)
		number = -1

		for i=3,chatvars.wordCount,1 do
			if chatvars.words[i] == "level" then
				number = chatvars.words[i+1]
			end
		end

		if number == -1 then
			number = 1
		end

		if id ~= nil then
			-- add the steamid to the admins table
			if tonumber(number) == 0 then
				owners[id] = {}
			end

			if tonumber(number) == 1 then
				admins[id] = {}
			end

			if tonumber(number) == 2 then
				mods[id] = {}
			end

			players[id].newPlayer = false
			players[id].silentBob = false
			players[id].walkies = false
			players[id].exiled = 2
			players[id].canTeleport = true
			players[id].botHelp = true

			if tonumber(players[id].accessLevel) > tonumber(number) then
				players[id].accessLevel = number
			end

			message("say [" .. server.chatColour .. "]" .. players[id].name .. " has been given admin powers[-]")
			send("admin add " .. id .. " " .. number)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "remove") or string.find(chatvars.command, "admin"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "admin remove <player or steam or game ID>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Remove an admin so they become a regular player.")
				irc_chat(players[chatvars.ircid].ircAlias, "This does not stop them using god mode etc if they are ingame and already have dm enabled.  They must leave the server or disable dm themselves.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (string.find(chatvars.command, "admin remove ") and chatvars.accessLevel == 0) and (chatvars.playerid ~= 0) then
		pname = string.sub(chatvars.command, string.find(chatvars.command, "admin remove ") + 13)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			-- remove the steamid from the admins table
			owners[players[id].steam] = nil
			admins[players[id].steam] = nil
			mods[players[id].steam] = nil
			players[id].accessLevel = 90

			message("say [" .. server.chatColour .. "]" .. players[id].name .. "'s admin powers have been revoked[-]")
			send("admin remove " .. id)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "goto") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "goto <player or steam or game ID>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Teleport to the current position of a player.")
				irc_chat(players[chatvars.ircid].ircAlias, "This works with offline players too.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "goto" and chatvars.words[2] ~= nil and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		if (players[chatvars.playerid].timeout == true) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. You cannot " .. server.commandPrefix .. "goto anywhere until you are released.[-]")
			botman.faultyChat = false
			return true
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "goto ") + 5)

		-- first record the current x y z
		players[chatvars.playerid].xPosOld = chatvars.intX
		players[chatvars.playerid].yPosOld = chatvars.intY
		players[chatvars.playerid].zPosOld = chatvars.intZ

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if not (id == nil) then
			-- then teleport to the player
			cmd = "tele " .. chatvars.playerid .. " " .. math.floor(players[id].xPos) + 1 .. " " .. math.ceil(players[id].yPos) .. " " .. math.floor(players[id].zPos)
			teleport(cmd, true)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "offline") or string.find(chatvars.command, "player") or string.find(chatvars.command, "near"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "offline players nearby")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "offline players nearby range <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "List all offline players near your position. The default range is 200 metres.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "offline" and chatvars.words[2] == "players" and chatvars.words[3] == "nearby") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		chatvars.number = 201

		if string.find(chatvars.command, "range") then
			chatvars.number = string.sub(chatvars.command, string.find(chatvars.command, "range") + 6)
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]offline players within " .. chatvars.number .. " meters of you are:[-]")

		alone = true

		for k, v in pairs(players) do
			if igplayers[k] == nil and v.xPos ~= nil then
				dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, v.xPos, v.zPos)
				dist = math.abs(dist)

				if tonumber(dist) <= tonumber(chatvars.number) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%d", dist) .. "[-]")
					alone = false
				end
			end
		end

		if (alone == true) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No offline players within range.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "death") or string.find(chatvars.command, "crime"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "crimescene <prisoner>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Teleport to the coords where a player was when they got arrested.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "crimescene") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		prisoner = string.sub(chatvars.command, string.find(chatvars.command, "scene ") + 6)
		prisoner = string.trim(prisoner)
		prisonerid = LookupPlayer(prisoner)

		if (players[prisonerid].prisoner) then
			-- first record the current x y z
			players[chatvars.playerid].xPosOld = chatvars.intX
			players[chatvars.playerid].yPosOld = chatvars.intY
			players[chatvars.playerid].zPosOld = chatvars.intZ

			-- then teleport to the prisoners old coords
			cmd = "tele " .. chatvars.playerid .. " " .. players[prisonerid].prisonxPosOld .. " " .. players[prisonerid].prisonyPosOld .. " " .. players[prisonerid].prisonzPosOld
			prepareTeleport(chatvars.playerid, cmd)
			teleport(cmd, true)
		else
			-- tp to their return coords if they are set
			if tonumber(players[prisonerid].yPosTimeout) ~= 0 then
				-- first record the current x y z
				players[chatvars.playerid].xPosOld = chatvars.intX
				players[chatvars.playerid].yPosOld = chatvars.intY
				players[chatvars.playerid].zPosOld = chatvars.intZ

				-- then teleport to the prisoners old coords
				cmd = "tele " .. chatvars.playerid .. " " .. players[prisonerid].xPosTimeout .. " " .. players[prisonerid].yPosTimeout .. " " .. players[prisonerid].zPosTimeout
				prepareTeleport(chatvars.playerid, cmd)
				teleport(cmd, true)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "goto") or string.find(chatvars.command, "near") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "near <player> <optional number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Teleport below and a short distance away from a player.  You must be flying for this or you will just fall all the time.")
				irc_chat(players[chatvars.ircid].ircAlias, "You arrive 20 metres below the player and 10 metres to the side.  If you give a number after the player name you will be that number metres off to the side.")
				irc_chat(players[chatvars.ircid].ircAlias, "The bot will keep you near the player, teleporting you close to them if they get away from you.")
				irc_chat(players[chatvars.ircid].ircAlias, "To stop following them type " .. server.commandPrefix .. "stop.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "closeto" or chatvars.words[1] == "near") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		if (players[chatvars.playerid].timeout == true) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. You cannot go anywhere until you are released for safety reasons.[-]")
			botman.faultyChat = false
			return true
		end

		if chatvars.words[1] == "closeto" then
			pname = chatvars.words[2]
		end

		if chatvars.words[1] == "near" then
			pname = chatvars.words[2]
		end

		if chatvars.words[3] ~= nil then
			igplayers[chatvars.playerid].followDistance = tonumber(chatvars.words[3])
		end

		-- first record the current x y z
		players[chatvars.playerid].xPosOld = chatvars.intX
		players[chatvars.playerid].yPosOld = chatvars.intY
		players[chatvars.playerid].zPosOld = chatvars.intZ

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if not (id == nil) then
			igplayers[chatvars.playerid].following = id

			-- then teleport close to the player
			cmd = "tele " .. chatvars.playerid .. " " .. math.floor(igplayers[id].xPos + 10) .. " " .. math.ceil(igplayers[id].yPos - 20) .. " " .. math.floor(igplayers[id].zPos + 10)
			send(cmd)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "prisoners")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "List all the players who are prisoners.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "prisoners" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]List of prisoners:[-]")

		for k, v in pairs(players) do
			if v.prisoner then
				tmp = {}

				if v.prisonReason then
					tmp.reason = v.prisonReason
				else
					tmp.reason = ""
				end

				if tonumber(v.pvpVictim) == 0 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " " .. tmp.reason .. "[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " PVP " .. players[v.pvpVictim].name .. "[-]")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "equip") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "inv"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "equip admin")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Spawn various items on you.  The bot checks your inventory and will top you up instead of doubling up if you repeat this command later.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "equip" and chatvars.words[2] == "admin") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 1) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		tmp = {}
		tmp.inventory = igplayers[chatvars.playerid].pack .. igplayers[chatvars.playerid].belt
		tmp.equipment = igplayers[chatvars.playerid].equipment


		if not string.find(tmp.inventory .. tmp.equipment, "ironBoots") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " ironBoots 1 600', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quality = getEquipment(tmp.equipment, "ironBoots")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "ironBoots")
			end

			if tmp.found and tonumber(tmp.quality) < 300 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " ironBoots 1 600', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "auger") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " auger 1 600', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "auger")

			if tmp.found and tonumber(tmp.quality) < 300 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " auger 1 600', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "chainsaw") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " chainsaw 1 600', " .. chatvars.playerid .. ")")
		end


		-- nailgun
		if not string.find(tmp.inventory, "nailgun") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " nailgun 1', " .. chatvars.playerid .. ")")
		end


		-- mining helment
		tmp.found, tmp.quality = getEquipment(tmp.equipment, "miningHelmet")

		if not tmp.found then
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "miningHelmet")
		end

		if not tmp.found then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " miningHelmet 1 600', " .. chatvars.playerid .. ")")
		else
			if tmp.quality < 100 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " miningHelmet 1 600', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory .. tmp.equipment, "ironChestArmor") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " ironChestArmor 1 600', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quality = getEquipment(tmp.equipment, "ironChestArmor")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "ironChestArmor")
			end

			if tmp.found and tmp.quality < 300 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " ironChestArmor 1 600', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory .. tmp.equipment, "ironLegArmor") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " ironLegArmor 1 600', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quality = getEquipment(tmp.equipment, "ironLegArmor")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "ironLegArmor")
			end
		end


		if not string.find(tmp.inventory .. tmp.equipment, "ironGloves") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " ironGloves 1 600', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quality = getEquipment(tmp.equipment, "ironGloves")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "ironGloves")
			end
		end


		if not string.find(tmp.inventory .. tmp.equipment, "leatherDuster") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " leatherDuster 1 600', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quality = getEquipment(tmp.equipment, "leatherDuster")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "leatherDuster")
			end
		end


		if not string.find(tmp.inventory, "redTea") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " redTea 10', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "redTea")

			if tonumber(tmp.quantity) < 10 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " redTea " .. 10 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "gasCan") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " gasCan 400', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "gasCan")

			if tonumber(tmp.quantity) < 400 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " gasCan " .. 400 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "meatStew") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " meatStew 20', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "meatStew")

			if tonumber(tmp.quantity) < 20 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " meatStew " .. 20 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "firstAidKit") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " firstAidKit 10', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "firstAidKit")

			if tonumber(tmp.quantity) < 10 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " firstAidKit " .. 10 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "antibiotics") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " antibiotics 10', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "antibiotics")

			if tonumber(tmp.quantity) < 10 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " antibiotics " .. 10 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "shotgunShell") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " shotgunShell 500', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "shotgunShell")

			if tonumber(tmp.quantity) < 500 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " shotgunShell " .. 500 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "gunPumpShotgun") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " gunPumpShotgun 1', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "gunPumpShotgun")

			if tonumber(tmp.quality) < 300 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " gunPumpShotgun 1', " .. chatvars.playerid .. ")")
			end
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]We deliver :)[-]")
		botman.faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "supp") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "inv"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "supplies")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Spawn various items on you like equip admin does but no armour or guns.  The bot checks your inventory and will top you up instead of doubling up if you repeat this command later.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "supplies") then
		if (chatvars.accessLevel > 1) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		tmp = {}
		tmp.inventory = igplayers[chatvars.playerid].pack .. igplayers[chatvars.playerid].belt
		tmp.equipment = igplayers[chatvars.playerid].equipment

		if not string.find(tmp.inventory, "redTea") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " redTea 10', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "redTea")

			if tonumber(tmp.quantity) < 10 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " redTea " .. 10 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "gasCan") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " gasCan 800', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "gasCan")

			if tonumber(tmp.quantity) < 800 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " gasCan " .. 800 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "meatStew") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " meatStew 20', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "meatStew")

			if tonumber(tmp.quantity) < 20 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " meatStew " .. 20 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "firstAidKit") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " firstAidKit 10', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "firstAidKit")

			if tonumber(tmp.quantity) < 10 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " firstAidKit " .. 10 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "antibiotics") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " antibiotics 10', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "antibiotics")

			if tonumber(tmp.quantity) < 10 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " antibiotics " .. 10 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end


		if not string.find(tmp.inventory, "shotgunShell") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " shotgunShell 500', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "shotgunShell")

			if tonumber(tmp.quantity) < 500 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " shotgunShell " .. 500 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
			end
		end

		if not string.find(tmp.inventory .. tmp.equipment, "miningHelmet") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " miningHelmet 1 600', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quality = getEquipment(tmp.equipment, "miningHelmet")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "miningHelmet")
			end

			if tmp.found and tmp.quality < 300 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " miningHelmet 1 600', " .. chatvars.playerid .. ")")
			end
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]SUPPLIES![-]")
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rele") or string.find(chatvars.command, "free") or string.find(chatvars.command, "pris"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "release here <prisoner>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Release a player from prison and move them to your location.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "release" and chatvars.words[2] == "here" and chatvars.words[3] ~= nil) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		prisoner = string.sub(chatvars.command, string.find(chatvars.command, ": " .. server.commandPrefix .. "release here ") + 16)
		prisoner = string.trim(prisoner)
		prisonerid = LookupPlayer(prisoner)

		if (players[prisonerid].prisoner == false) then
			message("say [" .. server.chatColour .. "]Citizen " .. players[prisonerid].name .. " is not a prisoner[-]")
			botman.faultyChat = false
			return true
		end

		players[prisonerid].prisoner = false
		players[prisonerid].timeout = false
		players[prisonerid].botTimeout = false
		players[prisonerid].freeze = false
		players[prisonerid].silentBob = false
		
		if players[prisonerid].chatColour ~= "" then
			send("cpc " .. prisonerid .. " " .. players[prisonerid].chatColour .. " 1")
		else
			setChatColour(prisonerid)
		end

		conn:execute("UPDATE players SET prisoner=0,timeout=0,botTimeout=0,silentBob=0 WHERE steam = " .. prisonerid)

		message("say [" .. server.chatColour .. "]Releasing prisoner " .. players[prisonerid].name .. "[-]")

		if (players[prisonerid].steam) then
			message("pm " .. prisonerid .. " [" .. server.chatColour .. "]You are released from prison.  Be a good citizen if you wish to remain free.[-]")
			cmd = "tele " .. prisonerid .. " " .. chatvars.playerid
			prepareTeleport(prisonerid, cmd)

			teleport(cmd, true)
			players[prisonerid].xPosOld = 0
			players[prisonerid].yPosOld = 0
			players[prisonerid].zPosOld = 0
			players[prisonerid].prisonxPosOld = 0
			players[prisonerid].prisonyPosOld = 0
			players[prisonerid].prisonzPosOld = 0
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "playerbase <player>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "playerhome <player>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "playerbase2 <player>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "playerhome2 <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Teleport yourself to the first or second base of a player.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "playerhome" or chatvars.words[1] == "playerbase" or chatvars.words[1] == "playerhome2" or chatvars.words[1] == "playerbase2") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1], nil, true) + string.len(chatvars.words[1]))
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (pname == "") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required or could not be found for this command[-]")
			botman.faultyChat = false
			return true
		else
			if (chatvars.words[1] == "playerhome" or chatvars.words[1] == "playerbase") then
				if (players[id].homeX == 0 and players[id].homeZ == 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " Has not set a base yet.[-]")
					botman.faultyChat = false
					return true
				else
					-- first record the current x y z
					players[chatvars.playerid].xPosOld = math.floor(igplayers[chatvars.playerid].xPos)
					players[chatvars.playerid].yPosOld = math.ceil(igplayers[chatvars.playerid].yPos)
					players[chatvars.playerid].zPosOld = math.floor(igplayers[chatvars.playerid].zPos)

					cmd = "tele " .. chatvars.playerid .. " " .. players[id].homeX .. " " .. players[id].homeY .. " " .. players[id].homeZ
					prepareTeleport(chatvars.playerid, cmd)
					teleport(cmd, true)
				end
			else
				if (players[id].home2X == 0 and players[id].home2Z == 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " Has not set a 2nd base yet.[-]")
					botman.faultyChat = false
					return true
				else
					-- first record the current x y z
					players[chatvars.playerid].xPosOld = math.floor(igplayers[chatvars.playerid].xPos)
					players[chatvars.playerid].yPosOld = math.ceil(igplayers[chatvars.playerid].yPos)
					players[chatvars.playerid].zPosOld = math.floor(igplayers[chatvars.playerid].zPos)

					cmd = "tele " .. chatvars.playerid .. " " .. players[id].home2X .. " " .. players[id].home2Y .. " " .. players[id].home2Z
					prepareTeleport(chatvars.playerid, cmd)
					teleport(cmd, true)
				end
			end
		end

		botman.faultyChat = false
		return true
	end

if debug then dbug("admin end") end

end
