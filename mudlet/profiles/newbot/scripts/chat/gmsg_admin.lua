--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
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
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
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
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Admin Commands:")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "================")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
		
		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end
	
	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reload admins")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/reload admins")
		
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Make the bot run admin list to reload the admins from the server's list.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reload" or chatvars.words[1] == "refresh" or chatvars.words[1] == "update") and chatvars.words[2] == "admins" then
		-- run admin list
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reading admin list[-]")
		send("admin list")

		faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "reload bot")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/reload bot")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Make the bot read several things from the server including admin list, ban list, gg, lkp and others.  If you have Coppi's Mod installed it will also detect that.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reload" or chatvars.words[1] == "refresh" or chatvars.words[1] == "update") and chatvars.words[2] == "bot" then
		-- run admin list, gg, ban list and lkp

		message("say [" .. server.chatColour .. "]Collecting known players[-]")
		send("lkp")

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

		faultyChat = false
		return true

	end


	if chatvars.words[1] == "gimme" and chatvars.words[2] == "admin" and server.botName == "Tester" then
		-- add the steamid to the admins table
		admins[players[chatvars.playerid].steam] = {}
		players[chatvars.playerid].newPlayer = false
		players[chatvars.playerid].silentBob = false
		players[chatvars.playerid].walkies = false
		players[chatvars.playerid].exiled = 2
		players[chatvars.playerid].canTeleport = true
		players[chatvars.playerid].botHelp = true

		message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " has been given admin powers[-]")
		send("admin add " .. chatvars.playerid .. " 0")

		send("admin list")

		faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "timeout")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/timeout <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Send a player to timeout.  You can use their steam or game id and part or all of their name.  If you send the wrong player to timeout /return <player> to fix that.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "While in timeout, the player will not be able to use any bot commands but they can chat.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "timeout") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 90) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		if (chatvars.words[2] == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Send a player to timeout where they can only talk.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can also send yourself to timeout but not other staff.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/timeout <player>[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]See also: /return <player>[-]")
			faultyChat = false
			return true
		end

		tmp = {}
		tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "timeout ") + 8)
		tmp.pname = string.trim(tmp.pname)
		tmp.id = LookupPlayer(tmp.pname)

		if (chatvars.playername ~= "Server") then 	
			if (players[tmp.id].newPlayer == false and accessLevel(chatvars.playerid) > 3) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are limited to sending new players to timeout. " .. players[tmp.id].name .. " is not new.[-]")
				faultyChat = false
				return true
			end
		end

		if (players[tmp.id].timeout == true) then
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This player is already in timeout.  Did you mean /return ?[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Player " .. tmp.id .. " " .. players[tmp.id].name .. " is already in timeout.")
			end

			faultyChat = false
			return true
		end

		if (accessLevel(tmp.id) < 3 and server.ignoreAdmins == true) and tmp.id ~= chatvars.playerid then
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Staff cannot be sent to timeout.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Staff cannot be sent to timeout.")
			end

			faultyChat = false
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
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[tmp.id].xPosTimeout .. "," .. players[tmp.id].yPosTimeout .. "," .. players[tmp.id].zPosTimeout .. ",'" .. serverTime .. "','timeout','Player " .. escape(players[tmp.id].name) .. " SteamID: " .. tmp.id .. " sent to timeout by " .. escape(players[chatvars.playerid].name) .. "'," .. tmp.id .. ")")
		else
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[tmp.id].xPosTimeout .. "," .. players[tmp.id].yPosTimeout .. "," .. players[tmp.id].zPosTimeout .. ",'" .. serverTime .. "','timeout','Player " .. escape(players[tmp.id].name) .. " SteamID: " .. tmp.id .. " sent to timeout by " .. escape(players[chatvars.ircid].name) .. "'," .. tmp.id .. ")")
		end

		if players[tmp.id].watchPlayer then
			irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
		end
		
		-- then teleport the player to timeout
		send("tele " .. tmp.id .. " " .. players[tmp.id].xPosTimeout .. " 50000 " .. players[tmp.id].zPosTimeout)

		message("say [" .. server.chatColour .. "]" .. players[tmp.id].name .. " has been sent to timeout.[-]")

		conn:execute("UPDATE players SET timeout = 1, silentBob = 1, xPosTimeout = " .. players[tmp.id].xPosTimeout .. ", yPosTimeout = " .. players[tmp.id].yPosTimeout .. ", zPosTimeout = " .. players[tmp.id].zPosTimeout .. " WHERE steam = " .. tmp.id)		

		faultyChat = false
		return true
	end

if debug then dbug("admin 2") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "return")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/return <player>")
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/return <player> to <location or other player>")		
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Return a player from timeout.  You can use their steam or game id and part or all of their name.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You can return them to any player even offline ones or to any location. If you just return them, they will return to wherever they were when they were sent to timeout.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Your regular players can also return new players from timeout but only if a player sent them there.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "return" and chatvars.words[2] ~= nil) then 
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 90) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted. Just type /return.[-]")
				faultyChat = false
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
			if (accessLevel(chatvars.playerid) > 2) then
				tmp.loc = nil
			end
		end

		if (players[tmp.id].timeout == true and tmp.id == chatvars.playerid and accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. You cannot release yourself.[-]")
			faultyChat = false
			return true
		end
		
		if players[tmp.id].timeout == false and players[tmp.id].prisoner and ((tmp.id ~= chatvars.playerid and accessLevel(chatvars.playerid) > 2) or chatvars.playerid == players[id].pvpVictim) then
			gmsg("/release " .. players[tmp.id].name)
			faultyChat = false
			return true	
		end	

		if (chatvars.playername ~= "Server") then	
			if accessLevel(chatvars.playerid) > 2 then
				if players[tmp.id].newPlayer == true or players[tmp.id].timeout == false then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can only use this command on new players in timeout and a player sent them there.[-]")
					faultyChat = false
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

				if players[tmp.id].watchPlayer then
					irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
				end

				if tmp.loc ~= nil then
					tmp.cmd = "tele " .. tmp.id .. " " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z
				else
					send("tele " .. tmp.id .. " " .. players[tmp.id].xPosTimeout .. " " .. players[tmp.id].yPosTimeout .. " " .. players[tmp.id].zPosTimeout)

					players[tmp.id].xPosTimeout = 0
					players[tmp.id].yPosTimeout = 0
					players[tmp.id].zPosTimeout = 0

					conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, xPosTimeout = 0, yPosTimeout = 0, zPosTimeout = 0 WHERE steam = " .. tmp.id)

					message("say [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. "[-]")

					faultyChat = false
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

				faultyChat = false
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

				if players[tmp.id].watchPlayer then
					irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
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

				faultyChat = false
				return true
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 3") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "prison") or string.find(chatvars.command, "releas"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/release <player>")
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/just release <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Release a player from prison.  They are teleported back to where they were arrested.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Alternatively just release them so they do not teleport and have to walk back or use bot commands.")				
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "See also /release here")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
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
			faultyChat = false
			return true
		end

		if (chatvars.playername ~= "Server") then 	
			if (accessLevel(chatvars.playerid) > 2) and (players[prisonerid].pvpVictim ~= chatvars.playerid) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. prisoner .. " is not in prison for your death and cannot be released by you.[-]")	
				faultyChat = false	
				return true
			end		
		end

		if (players[prisonerid].timeout == true or players[prisonerid].botTimeout == true) then
			message("say [" .. server.chatColour .. "]Citizen " .. prisoner .. " is released from timeout.[-]")
			players[prisonerid].timeout = false
			players[prisonerid].botTimeout = false
			players[prisonerid].freeze = false
			players[prisonerid].silentBob = false 

			conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0 WHERE steam = " .. prisonerid)

			faultyChat = false
			return true
		end

		if (not players[prisonerid].prisoner and players[prisonerid].timeout == false) then
			message("say [" .. server.chatColour .. "]Citizen " .. prisoner .. " is not a prisoner[-]")
			faultyChat = false
			return true
		end
		
		players[prisonerid].xPosOld = 0
		players[prisonerid].yPosOld = 0
		players[prisonerid].zPosOld = 0
		
		if (igplayers[prisonerid]) then

			if players[prisonerid].watchPlayer then
				irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
			end

			message("say Releasing prisoner " .. prisoner)
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
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 4") end

	if chatvars.words[1] == "give" and (string.find(chatvars.words[2], "claim") or string.find(chatvars.words[2], "key") or string.find(chatvars.words[2], "lcb")) then
		if players[chatvars.playerid].removedClaims > 20 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I am holding a lot of claims. Due to bugs with the count I can't release them to you.  Please talk to an admin to get them back so we can verify the count.[-]")

			faultyChat = false
			return true
		end

		if players[chatvars.playerid].removedClaims > 0 then
			send("give " .. chatvars.playerid .. " keystoneBlock " .. players[chatvars.playerid].removedClaims)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I was holding " .. players[chatvars.playerid].removedClaims .. " keystones for you and have dropped them at your feet.  Press e to collect them now.[-]")
			players[chatvars.playerid].removedClaims = 0
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I have no keystones to give you at this time.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 5") end

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

if debug then dbug("admin 6") end

	if (chatvars.words[1] == "hordeme") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is not available from IRC. Use it ingame.")
			faultyChat = false
			return true
		end

		message("say [" .. server.chatColour .. "]HORDE!!![-]")

		for i=1,50,1 do
			cmd = "se " .. players[chatvars.playerid].id .. " " .. PicknMix()
			conn:execute("INSERT INTO gimmeQueue (steam, command) VALUES (" .. chatvars.playerid .. ",'" .. cmd .. "')")
		end

		faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim") or string.find(chatvars.command, "keys"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/leave claims <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Stop the bot automatically removing a player's claims.  They will still be removed if they are in a location that doesn't allow player claims.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "leave" and chatvars.words[2] == "claims" and chatvars.words[3] ~= nil) then
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
				irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. "'s claims will not be removed unless found in reset zones (if not staff)")
			end

			conn:execute("UPDATE players SET removeClaims = 0 WHERE steam = " .. id)
		end

		faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim") or string.find(chatvars.command, "keys"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/remove claims <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot will automatically remove the player's claims whenever possible. The chunk has to be loaded and the bot takes several minutes to remove them but it will remove them.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "remove" and chatvars.words[2] == "claims" and chatvars.words[3] ~= nil) then
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

		pname = chatvars.words[3]
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			-- flag the player's claims for removal
			players[id].removeClaims = true

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will remove all of player " .. players[id].name .. "'s claims when their chunks are loaded.[-]")		
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "I will remove all of player " .. players[id].name .. "'s claims when their chunks are loaded.")
			end

			send("llp " .. id)

			conn:execute("UPDATE players SET removeClaims = 1 WHERE steam = " .. id)
		end

		faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "exile")) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/exile <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Bannish a player to a special location called /exile which must exist first.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "While exiled, the player will not be able to command the bot.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "exile" and chatvars.words[2] ~= nil) then
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
				irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " has been exiled.")
			end

			conn:execute("UPDATE players SET exiled = 1, silentBob = 1, canTeleport = 0 WHERE steam = " .. id)
		end

		faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "exile") or string.find(chatvars.command, "free"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/free <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Release the player from exile, however it does not return them.  They can type /return or you can return them.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "free") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
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

		faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "new") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/player <player> is not new")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Upgrade a new player to a regular without making them wait for the bot to upgrade them. They will no longer be as restricted as a new player.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "player" and string.find(chatvars.command, "is not new")) then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
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
			message("say [" .. server.chatColour .. "]" .. players[id].name .. " is no longer new here. Welcome back " .. players[id].name .. "! =D[-]")

			conn:execute("UPDATE players SET newPlayer = 0, watchPlayer = 0 WHERE steam = " .. id)
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 7") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "donor"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/add donor <player> level <0 to 7> expires <number> week or month or year")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Give a player donor status.  This doesn't have to involve money.  Donors get a few perks above other players but no items or zennies.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Level and expiry are optional.  The default is level 1 and expiry 10 years.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You can also temporarily raise everyone to donor level with /override access.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "add" and chatvars.words[2] == "donor") then
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

		if (chatvars.words[3] == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Add donors with optional level and expiry. Defaults level 1 and 10 years.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. /add donor bob level 5 expires 1 week (or month or year)[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Expires automatically. 2nd protected base becomes unprotected 1 week later.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Add donors with optional level and expiry. Defaults level 1 and 10 years.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "eg. /add donor bob level 5 expires 1 week (or month or year)")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Expires automatically. 2nd protected base becomes unprotected 1 week later.")
			end

			faultyChat = false
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
						irc_QueueMsg(players[chatvars.ircid].ircAlias, "Invalid expiry entered. Expected <number> <week or month or year> eg. 1 month.")
					end

					faultyChat = false
					return true
				end
			end					

			if chatvars.words[i] == "level" then
				tmp.level = math.abs(ToInt(chatvars.words[i+1]))

				if tmp.level > 7 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level must be a number from 0 to 7.[-]")		
					else
						irc_QueueMsg(players[chatvars.ircid].ircAlias, "Level must be a number from 0 to 7.")
					end

					faultyChat = false
					return true
				end
				
				if tmp.level == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level must be a number from 0 to 7.[-]")		
					else
						irc_QueueMsg(players[chatvars.ircid].ircAlias, "Level must be a number from 0 to 7.")
					end

					faultyChat = false
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
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 8") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "donor"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/remove donor <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Remove a player's donor status.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "remove" and chatvars.words[2] == "donor" and chatvars.words[3] ~= nil) then
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
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found with that name.[-]")		
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "No player found with that name.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 10") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "give"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/give <item> <quantity>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Give everyone that is playing quantity of an item. The default is to give 1 of the item.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "give" and chatvars.words[2] ~= nil) then
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
					irc_QueueMsg(players[chatvars.ircid].ircAlias, chatvars.words[2] .. " has been dropped at " .. players[k].name .. "'s feet.")
				end
			end
		end
	end

if debug then dbug("admin 11") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/disallow teleport <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Prevent a player from using any teleports.  They won't be able to teleport themselves, but they can still be teleported.  Also physical teleports won't work for them.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "disallow" and chatvars.words[2] == "teleport" and chatvars.words[3] ~= nil) then
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "teleport") + 9)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			players[id].canTeleport = false
			message("say [" .. server.chatColour .. "] " .. players[id].name ..  " is not allowed to use teleports.[-]")

			conn:execute("UPDATE players SET canTeleport = 0 WHERE steam = " .. id)
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 12") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/allow teleport <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The player will be able to use teleport commands and physical teleports again.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "allow" and chatvars.words[2] == "teleport" and chatvars.words[3] ~= nil) then
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "teleport") + 9)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if id ~= nil then
			players[id].canTeleport = true
			message("say [" .. server.chatColour .. "] " .. players[id].name ..  " is allowed to use teleports.[-]")

			conn:execute("UPDATE players SET canTeleport = 1 WHERE steam = " .. id)
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 13") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/enable waypoints")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Donors will be able to create, use and share waypoints.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "enable" and chatvars.words[2] == "waypoints" and chatvars.words[3] == nil) then
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

		server.allowWaypoints = true

		conn:execute("UPDATE server SET allowWaypoints = 1")

		if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are enabled for donors.[-]")	
		else
			message("say [" .. server.chatColour .. "]Waypoints are enabled for donors.[-]")
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 14") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/disable waypoints")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Waypoints will not be available.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "disable" and chatvars.words[2] == "waypoints" and chatvars.words[3] == nil) then
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

		server.allowWaypoints = false

		conn:execute("UPDATE server SET allowWaypoints = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are restricted to admins.[-]")	
		else
			message("say [" .. server.chatColour .. "]Waypoints are restricted to admins.[-]")
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 15") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/close shop")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The shop will not be available.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "close" and chatvars.words[2] == "shop") then
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

		message("say [" .. server.chatColour .. "]The shop is closed until further notice.[-]")
		server.allowShop = false

		conn:execute("UPDATE server SET allowShop = 0")

		faultyChat = false
		return true
	end

if debug then dbug("admin 16") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/open shop")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The shop will be available.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "open" and chatvars.words[2] == "shop") then
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

		message("say [" .. server.chatColour .. "]The shop is open for business.[-]")
		server.allowShop = true	

		conn:execute("UPDATE server SET allowShop = 1")
		loadShopCategories()

		faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/reset shop")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Restock the shop to the max quantity of each item.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "reset" and chatvars.words[2] == "shop") then
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

		message("say [" .. server.chatColour .. "]Hurrah!  >NEW< stock![-]")
		resetShop(true)
		loadShopCategories()

		faultyChat = false
		return true
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set shop open < 0 - 23 >")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Enter a number from 0 to 23 which will be the game hour that the shop opens.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "shop" and chatvars.words[3] == "open") then
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

		if chatvars.number == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number from 0 to 23 is expected (military time)[-]")
			faultyChat = false
			return true
		else
			chatvars.number = math.floor(chatvars.number)

			if chatvars.number < 0 or chatvars.number > 23 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number from 0 to 23 is expected (military time)[-]")
				faultyChat = false
				return true
			end

			server.shopOpenHour = chatvars.number
			conn:execute("UPDATE server SET shopOpenHour = " .. chatvars.number)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The shop opens at " .. chatvars.number .. str .. ":00 hours[-]")

			faultyChat = false
			return true
		end
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set shop close < 0 - 23 >")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Enter a number from 0 to 23 which will be the game hour that the shop closes.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "shop" and chatvars.words[3] == "close") then
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

		if chatvars.number == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number from 0 to 23 is expected (military time)[-]")
			faultyChat = false
			return true
		else
			chatvars.number = math.floor(chatvars.number)

			if chatvars.number < 0 or chatvars.number > 23 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number from 0 to 23 is expected (military time)[-]")
				faultyChat = false
				return true
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The shop closes at " .. chatvars.number .. str .. ":00 hours[-]")
			server.shopCloseHour = chatvars.number
			conn:execute("UPDATE server SET shopCloseHour = " .. chatvars.number)

			faultyChat = false
			return true
		end
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/set shop location <location name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Tie the shop to a location.  Buying from the shop will only be possible while in that location (excluding admins).")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "shop" and chatvars.words[3] == "location") then
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

		str = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9)
		str = string.trim(str)
		str = LookupLocation(str)

		if str == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A location is required for this command.[-]")
			faultyChat = false
			return true
		else
			message("say [" .. server.chatColour .. "]The shop is now located at ".. str .. "[-]")
			server.shopLocation = str
			conn:execute("UPDATE server SET shopLocation = '" .. str .. "'")

			faultyChat = false
			return true
		end
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shop"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/clear shop location")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The shop will be accessible from anywhere.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "clear" and chatvars.words[2] == "shop" and chatvars.words[3] == "location") then
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

		message("say [" .. server.chatColour .. "]The shop is no longer bound to a location.[-]")
		server.shopLocation = nil
		conn:execute("UPDATE server SET shopLocation = null")

		faultyChat = false
		return true
	end

if debug then dbug("admin 17") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/whitelist add <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Add a player to the bot's whitelist. This is not the server's whitelist and it works differently.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "It exempts the player from ping kicks and country blocks.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "whitelist" and chatvars.words[2] == "add" and chatvars.words[3] ~= nil) then	
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

		pname = nil
		pname = string.sub(chatvars.command, string.find(chatvars.command, "add ") + 4)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command requires a player name or no match found.")		
			end
				
			faultyChat = false
			return true
		end

		players[id].whitelisted = true
		conn:execute("INSERT INTO whitelist (steam) VALUES (" .. id .. ")")				

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has been added to the whitelist.[-]")	
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " has been added to the whitelist.")
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 18") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/whitelist remove <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Remove a player from the whitelist.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "whitelist" and chatvars.words[2] == "remove" and chatvars.words[3] ~= nil) then	
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

		pname = nil
		pname = string.sub(chatvars.command, string.find(chatvars.command, "remove ") + 7)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command requires a player name or no match found.")	
			end
				
			faultyChat = false
			return true
		end

		players[id].whitelisted = false
		conn:execute("DELETE FROM whitelist WHERE steam = " .. id)				

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " is no longer whitelisted.[-]")	
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " is no longer whitelisted.")
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 19") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "player") or string.find(chatvars.command, "excl") or string.find(chatvars.command, "igno"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/ignore player <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Allowed the player to have uncraftable inventory and ignore hacker like activity such as teleporting and flying.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "ignore" and chatvars.words[2] == "player" and chatvars.words[3] ~= nil) then	
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

		pname = nil
		pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command requires a player name or no match found.")
			end
				
			faultyChat = false
			return true
		end

		if (players[id]) then
			players[id].ignorePlayer = true

			conn:execute("UPDATE players SET ignorePlayer = 1 WHERE steam = " .. id)
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " is allowed to carry uncraftable items, fly, teleport and other fun stuff.[-]")	
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias,players[id].name .. " is allowed to carry uncraftable items, fly, teleport and other fun stuff.")
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 20") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "player") or string.find(chatvars.command, "incl"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/include player <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Treat the player the same as other players. They will not be allowed uncraftable inventory and hacker like activity will be treated as such.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "include" and chatvars.words[2] == "player" and chatvars.words[3] ~= nil) then	
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

		pname = nil
		pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Command requires a player name or no match found.")		
			end
				
			faultyChat = false
			return true
		end

		if (players[id]) then
			players[id].ignorePlayer = false

			conn:execute("UPDATE players SET ignorePlayer = 0 WHERE steam = " .. id)
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " will be subject to the same restrictions as other players.[-]")	
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " will be subject to the same restrictions as other players.")
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 21") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "prisoner") or string.find(chatvars.command, "arrest"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/prisoner <player> arrested <reason for arrest>")
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/prisoner <player> (read the reason if one is recorded)")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You can record or view the reason for a player being arrested.  If they are released, this record is destroyed.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "prisoner") then
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
				irc_QueueMsg(players[chatvars.ircid].ircAlias, prisoner .. " is not a prisoner.")
			end

			faultyChat = false
			return true
		end

		if players[prisonerid].prisoner then
			if reason ~= nil then
				players[prisonerid].prisonReason = reason
				conn:execute("UPDATE players SET prisonReason = '" .. escape(reason) .. "' WHERE steam = " .. prisonerid)
				
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added a reason for prisoner " .. prisoner .. "'s arrest[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "Reason for prisoner " .. prisoner .. "'s arrest noted.")
				end
			else
				if players[prisonerid].prisonReason ~= nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. prisoner .. " was arrested for " .. players[prisonerid].prisonReason .. "[-]")
					else
						irc_QueueMsg(players[chatvars.ircid].ircAlias, prisoner .. " was arrested for " .. players[prisonerid].prisonReason)
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] No reason is recorded for " .. prisoner .. "'s arrest.[-]")
					else
						irc_QueueMsg(players[chatvars.ircid].ircAlias, "No reason is recorded for " .. prisoner .. "'s arrest.")
					end
				end
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 22") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "arrest") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "jail"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/arrest <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Send a player to prison.  If the location prison does not exist they are put into timeout instead.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "arrest") then
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

		prisoner = string.sub(chatvars.command, string.find(chatvars.command, "arrest ") + 7)
		prisoner = string.trim(prisoner)
		prisonerid = LookupPlayer(prisoner)

		if prisonerid == nil then
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. prisoner .. "[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "No player found called " .. prisoner)
			end

			faultyChat = false
			return true
		end

		prisoner = players[prisonerid].name

		if (players[prisonerid]) then
			if (players[prisonerid].timeout == true) then
				if (chatvars.playername ~= "Server") then 
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. prisoner .. " is in timeout. /return them first[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, prisoner .. " is in timeout. Return them first")
				end

				faultyChat = false
				return true
			end
		end

		if (chatvars.playername ~= "Server") then
			if (accessLevel(prisonerid) < 3 and server.ignoreAdmins == true and prisonerid ~= chatvars.playerid) then
				if (chatvars.playername ~= "Server") then 
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Staff can not be arrested.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "Staff can not be arrested.")
				end

				faultyChat = false
				return true
			end
		end

		if locations["prison"] == nil then
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Create a location called prison first. Sending them to timeout instead..[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Create a location called prison first. Sending them to timeout instead.")
			end

			gmsg("/timeout " .. prisoner)
			faultyChat = false
			return true
		end

		message("say Arresting citizen " .. prisoner)

		if (not players[prisonerid].prisoner) then
			players[prisonerid].prisoner = true
			players[prisonerid].prisonxPosOld = math.floor(igplayers[prisonerid].xPos)
			players[prisonerid].prisonyPosOld = math.ceil(igplayers[prisonerid].yPos)
			players[prisonerid].prisonzPosOld = math.floor(igplayers[prisonerid].zPos)
			igplayers[prisonerid].xPosLastOK = locations["prison"].x
			igplayers[prisonerid].yPosLastOK = locations["prison"].y
			igplayers[prisonerid].zPosLastOK = locations["prison"].z

			if accessLevel(prisonerid) > 2	then
				players[prisonerid].silentBob = true
			end

			conn:execute("UPDATE players SET prisoner = 1, silentBob = 1, prisonxPosOld = " .. players[prisonerid].prisonxPosOld .. ", prisonyPosOld = " .. players[prisonerid].prisonyPosOld .. ", prisonzPosOld = " .. players[prisonerid].prisonzPosOld .. " WHERE steam = " .. prisonerid)

			message("pm " .. prisonerid .. " [" .. server.chatColour .. "]You have been sentenced to prison.  There is no escape until you are released by an admin.[-]")
			cmd = "tele " .. prisonerid .. " " .. locations["prison"].x .. " " .. locations["prison"].y .. " " .. locations["prison"].z
			prepareTeleport(prisonerid, cmd)

			if players[prisonerid].watchPlayer then
				irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )				
			end

			teleport(cmd, true)
			
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[prisonerid].xPosOld .. "," .. players[prisonerid].yPosOld .. "," .. players[prisonerid].zPosOld .. ",'" .. serverTime .. "','arrest','Player " .. escape(players[prisonerid].name) .. " SteamID: " .. prisonerid .. " arrested by " .. escape(players[chatvars.playerid].name)  .. "'," .. prisonerid .. ")")
			
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 23") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "timer"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/resettimers <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Normally a player needs to wait a set time after /base before they can use it again. This zeroes that timer and also resets their gimmies.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "resettimers") then
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

		pname = nil
		pname = string.sub(chatvars.command, string.find(chatvars.command, "resettimers ") + 12)

		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (pname == nil and chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required.[-]")
			faultyChat = false
			return true
		end

		if (players[id]) then
			players[id].baseCooldown = 0
			players[id].gimmeCount = 0

			conn:execute("UPDATE players SET baseCooldown = 0, gimmeCount = 0 WHERE steam = " .. id)
		end

		message("say [" .. server.chatColour .. "]Cooldown timers have been reset for " .. players[id].name .. "[-]")

		faultyChat = false
		return true
	end

if debug then dbug("admin 24") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "exclude") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "rule"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/exclude admins")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The normal rules that apply to players will not apply to admins.  They can go anywhere they want.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "exclude" and chatvars.words[2] == "admins") then
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

		server.ignoreAdmins = true

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admins can ignore the server rules.[-]")		
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Admins can ignore the server rules.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 25") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "include") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "rule"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/include admins")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Admins are treated the same as normal players and the bot will punish or block them as it would the players.  This is mainly used to test the bot while still being an admin.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "includeadmins") or (chatvars.words[1] == "include" and chatvars.words[2] == "admins") then
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

		server.ignoreAdmins = false

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admins must obey the server rules.[-]")		
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Admins must obey the server rules.")
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 26") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "freeze") or string.find(chatvars.command, "player") or string.find(chatvars.command, "stop"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/freeze <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Bind a player to their current position.  They get teleported back if they move.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "freeze" and chatvars.words[2] ~= nil) then
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "freeze") + 7)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (pname == nil or pname == "") then
			faultyChat = false
			return true 
		end

		if (id ~= nil) then 
			players[id].freeze = true 
			message("say [" .. server.chatColour .. "]STOP RIGHT THERE CRIMINAL SCUM![-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 27") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "freeze") or string.find(chatvars.command, "player") or string.find(chatvars.command, "stop"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/unfreeze <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Allow the player to move again.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "unfreeze" and chatvars.words[2] ~= nil) then
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "unfreeze") + 9)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (pname == nil or pname == "") then
			faultyChat = false
			return true 
		end

		if (players[id]) then 
			players[id].freeze = false 
			message("say [" .. server.chatColour .. "]Citizen " .. players[id].name .. ", you are free to go.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 28") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "move") or string.find(chatvars.command, "player") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/move <player> to <location>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Teleport a player to a location. To teleport them to another player use the send command.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "If the player is offline, they will be moved to the location when they next join.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "move") and chatvars.words[2] ~= nil and string.find(chatvars.command, " to ") then
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "move") + 5, string.find(chatvars.command, " to ") - 1)
		pname = string.trim(pname)
		
		location = string.sub(chatvars.command, string.find(chatvars.command, " to ") + 4)
		location = string.trim(location)	

		loc = LookupLocation(location)	
		id = LookupPlayer(pname)

		if (id ~= nil and loc ~= nil) then
			-- if the player is ingame, send them to the lobby otherwise flag it to happen when they rejoin
			if (igplayers[id]) then

				if players[id].watchPlayer then
					irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
				end

				cmd = "tele " .. id .. " " .. locations[loc].x .. " " .. locations[loc].y .. " " .. locations[loc].z
				igplayers[id].lastTP = cmd
				teleport(cmd, true)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " has been sent to " .. locations[loc].name .. "[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "Player " .. players[id].name .. " has been sent to " .. locations[loc].name)
				end
			else
				players[id].location = loc

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " will spawn at " .. locations[loc].name .. " next time they join.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "Player " .. players[id].name .. " will spawn at " .. locations[loc].name .. " next time they join.")
				end

				conn:execute("UPDATE players SET location = '" .. loc .. "' WHERE steam = " .. id)
			end
		end

		players[id].xPosOld = locations[loc].x
		players[id].yPosOld = locations[loc].y
		players[id].zPosOld = locations[loc].z
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 29") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "home") or string.find(chatvars.command, "player") or string.find(chatvars.command, "send"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/sendhome <player> or /sendhome2 <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Teleport a player to their first or second base.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "sendhome" or chatvars.words[1] == "sendhome2") then
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

		pname = string.sub(chatvars.command, string.find(chatvars.command, "sendhome") + 9)
		pname = string.trim(pname)

		if (pname == "") then 
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required or could not be found for this command[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "A player name is required or could not be found for this command")
			end

			faultyChat = false
			return true
		else
			id = 0
			id = LookupPlayer(pname)

			if (id == 0) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No in-game players found with that name.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "No in-game players found called " .. pname)
				end

				faultyChat = false
				return true
			end

			if (players[id].timeout == true) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is in timeout. /return them first[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " is in timeout. Return them first.")
				end

				faultyChat = false
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
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has not set a base yet.[-]")
					else
						irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " has not set a base yet.")
					end

					faultyChat = false
					return true
				else
					if (igplayers[id]) then
						if players[id].watchPlayer then
							irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
						end

						cmd = "tele " .. id .. " " .. players[id].homeX .. " " .. players[id].homeY .. " " .. players[id].homeZ
						prepareTeleport(id, cmd)
						teleport(cmd, true)
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has been sent home")
					else
						irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " has been sent home.")
					end
				end
			else
				if (players[id].home2X == 0 and players[id].home2Z == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has not set a 2nd base yet.[-]")
					else
						irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " has not set a 2nd base yet.")
					end

					faultyChat = false
					return true
				else
					if (igplayers[id]) then
						if players[id].watchPlayer then
							irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
						end

						cmd = "tele " .. id .. " " .. players[id].home2X .. " " .. players[id].home2Y .. " " .. players[id].home2Z
						prepareTeleport(id, cmd)
						teleport(cmd, true)
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has been sent home")
					else
						irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " has been sent home.")
					end
				end
			end
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 30") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "watch") or string.find(chatvars.command, "player") or string.find(chatvars.command, "new"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/watch <player>")
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/watch new players")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Flag a player or all current new players for extra attention and logging.  New players are watched by default.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "watch") then
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

		if (chatvars.words[2] == "new" and chatvars.words[3] == "players") then
			for k,v in pairs(players) do
				if v.newPlayer == true then
					v.watchPlayer = true
					conn:execute("UPDATE players SET watchPlayer = 1 WHERE steam = " .. k)
				end
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players will be watched.[-]")

			faultyChat = false
			return true
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "watch ") + 6)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if not (id == nil) then
			players[id].watchPlayer = true
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admins will be alerted whenever " .. players[id].name ..  " enters a base.[-]")
			end

			conn:execute("UPDATE players SET watchPlayer = 1 WHERE steam = " .. id)
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 31") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "watch") or string.find(chatvars.command, "player") or string.find(chatvars.command, "stop"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/stop watching <player>")
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/stop watching everyone")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Stop watching a player or stop watching everyone.  Activity will still be recorded but admins won't see private messages about it.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "stop" and chatvars.words[2] == "watching") then
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

		if (chatvars.words[3] == "everyone") then
			for k,v in pairs(players) do
				v.watchPlayer = false
				conn:execute("UPDATE players SET watchPlayer = 0 WHERE steam = " .. k)
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Nobody is being watched right now.[-]")

			faultyChat = false
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
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 32") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "send") or string.find(chatvars.command, "player") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/send <player1> to <player2>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Teleport a player to another player even if the other player is offline.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "send") then
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
			if (players[id1].walkies == true) and (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id1].name .. " has not opted in to being teleported. Ask them to /enabletp first[-]")
				faultyChat = false
				return true
			end

			if (players[id1].timeout == true) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id1].name .. " is in timeout. Return them first[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id1].name .. " is in timeout. Return them first.")
				end

				faultyChat = false
				return true
			end

			-- first record the current x y z
			players[id1].xPosOld = math.floor(players[id1].xPos)
			players[id1].yPosOld = math.floor(players[id1].yPos)
			players[id1].zPosOld = math.floor(players[id1].zPos)

			if (igplayers[id2]) then
				if players[id1].watchPlayer then
					irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
				end

				cmd = "tele " .. id1 .. " " .. id2
				prepareTeleport(id1, cmd)
				teleport(cmd, true)
			else
				if players[id1].watchPlayer then
					irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
				end

				cmd = "tele " .. id1 .. " " .. math.floor(players[id2].xPos) .. " " .. math.ceil(players[id2].yPos) .. " " .. math.floor(players[id2].zPos)
				prepareTeleport(id1, cmd)
				teleport(cmd, true)
			end
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 33") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "burn") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/burn <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set a player on fire.  It usually kills them.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "burn" and chatvars.words[2] ~= nil) then
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

		if (chatvars.words[2] ~= nil) then
			pname = chatvars.words[2]
			pid = LookupPlayer(pname)

			if pid == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No in-game players found with that name.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "No in-game players found called " .. pname)
				end

				faultyChat = false
				return true
			end
		end

		send("buffplayer " .. pid .. " burning")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You set " .. players[pid].name .. " on fire![-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "You set " .. players[pid].name .. " on fire!")
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 34") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shut") or string.find(chatvars.command, "stop") or string.find(chatvars.command, "bot"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/shutdown bot")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "While not essential as it seems to work just fine, you can tell the bot to save all pending player data, before you quit Mudlet.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "shutdown" and chatvars.words[2] == "bot") then
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
		
		irc_QueueMsg(server.ircMain, "Saving player data.  Wait a minute before stopping Mudlet or until I say I'm ready.")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Saving player data.  Wait a minute before stopping Mudlet or until I say I'm ready.[-]")
			shutdownBot(chatvars.playerid)
		else
			tempTimer( 3, [[shutdownBot(0)]] ) -- This timer is necessary to stop Mudlet freezing.  It doesn't seem to like running this function as server immediately but is fine with a delay.
		end

		faultyChat = false
		return true
	end
	
if debug then dbug("admin 35") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "clear") or string.find(chatvars.command, "stack"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/reset stack")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "If you have changed stack sizes and the bot is mistakenly abusing players for overstacking, you can make the bot forget the stack sizes.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "It will re-learn them from the server as players overstack beyond the new stack limits.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "clear" or chatvars.words[1] == "reset") and chatvars.words[2] == "stack" then
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
		
		stackLimits = {}

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot's record of stack limits has been wiped.  It will re-learn them from the server as players overstack items.[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot's record of stack limits has been wiped.  It will re-learn them from the server as players overstack items.")
		end

		faultyChat = false
		return true
	end
	
if debug then dbug("admin 36") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ban") or string.find(chatvars.command, "black"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/unban <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Remove a player from the server's ban list")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "unban" and chatvars.words[2] ~= nil) then
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
		
		pname = string.sub(chatvars.command, string.find(chatvars.command, "unban ") + 6)
		pname = string.trim(pname)
		id = LookupPlayer(pname)
		
		if id == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "No player found called " .. pname)			
			end							
			
			faultyChat = false
			return true			
		end
		
		send("ban remove " .. id)
		
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has been unbanned.[-]")			
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " has been unbanned.")			
		end					

		faultyChat = false
		return true
	end	

if debug then dbug("admin 37") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ban") or string.find(chatvars.command, "black"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/ban <player> (ban for 10 years with the reason 'banned')")
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/ban <player> reason <reason for ban> (ban for 10 years with the reason you provided)")			
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/ban <player> time <number> hour or day or month or year reason <reason for ban>")			
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Ban a player from the server.  You can optionally give a reason and a duration. The default is a 10 year ban with the reason 'banned'.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "ban" and chatvars.words[2] ~= nil) then
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
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "No player found called " .. pname)			
			end							
			
			faultyChat = false
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
			irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " has been banned " .. duration .. " for " .. reason)			
		end					

		faultyChat = false
		return true
	end	

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		faultyChat = false
		return false
	end
	-- ####################################################################################


	if (chatvars.words[1] == "who" and chatvars.words[2] == "visited") then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		if (chatvars.words[3] == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]See who visited a player location or base.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Example with defaults:[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/who visited smeg days 1 hours 1 range 10 height 4[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Add base to just see base visitors[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Setting hours will reset days to zero[-]")
			faultyChat = false
			return true
		end
		
		-- optional params
			-- range <distance in metres> Default 10
			-- days.  Default is 1 day ago from today (local time not server)

		name1 = nil
		days = 1
		hours = 0
		range = 10
		height = 4
		baseOnly = "player"

		if chatvars.words[3] ~= nil then
			name1 = string.trim(chatvars.words[3])
		end

		for i=3,chatvars.wordCount,1 do
			if chatvars.words[i] == "range" then
				range = tonumber(chatvars.words[i+1])
			end	

			if chatvars.words[i] == "height" then
				height = tonumber(chatvars.words[i+1])
			end	
				
			if chatvars.words[i] == "days" then
				days = tonumber(chatvars.words[i+1])
			end								

			if chatvars.words[i] == "hours" then
				hours = tonumber(chatvars.words[i+1])
				days = 0
			end								

			if chatvars.words[i] == "base" then
				baseOnly = "base"
			end	

			if chatvars.words[i] == "player" then
				baseOnly = "player"
				name1 = string.trim(chatvars.words[i+1])
			end	
		end		

		if name1 ~= nil then
			pid = LookupPlayer(name1)
		else
			pid = chatvars.playerid
		end
		
		if baseOnly == "base" or baseOnly == "all" then
			if players[pid].homeX ~= 0 and players[pid].homeZ ~= 0 then
				if days == 0 then
					message("pm " .. chatvars.playerid .. " Players who visited within " .. range .. " metres of base 1 of " .. players[pid].name .. " in the last " .. hours .. " hours")
				else
					message("pm " .. chatvars.playerid .. " Players who visited within " .. range .. " metres of base 1 of " .. players[pid].name .. " in the last " .. days .. " days")
				end

				dbWho(chatvars.playerid, players[pid].homeX, players[pid].homeY, players[pid].homeZ, range, days, hours, height)
			else
				message("pm " .. chatvars.playerid .. " " .. players[pid].name .. " does not have a base set yet.")
			end

			if players[pid].home2X ~= 0 and players[pid].home2Z ~= 0 then
				message("pm " .. chatvars.playerid .. " ")
				if days == 0 then
					message("pm " .. chatvars.playerid .. " Players who visited within " .. range .. " metres of base 2 of " .. players[pid].name .. " in the last " .. hours .. " hours")
				else
					message("pm " .. chatvars.playerid .. " Players who visited within " .. range .. " metres of base 2 of " .. players[pid].name .. " in the last " .. days .. " days")
				end

				dbWho(chatvars.playerid, players[pid].home2X, players[pid].home2Y, players[pid].home2Z, range, days, hours, height)
			end
		end

		if baseOnly == "player" or baseOnly == "all" then
			if days == 0 then
				message("pm " .. chatvars.playerid .. " Players who visited within " .. range .. " metres (X) " .. players[pid].xPos .. " (Z) " .. players[pid].zPos .. " of player " .. players[pid].name .. " in the last " .. hours .. " hours")
			else
				message("pm " .. chatvars.playerid .. " Players who visited within " .. range .. " metres (X) " .. players[pid].xPos .. " (Z) " .. players[pid].zPos .. " of player " .. players[pid].name .. " in the last " .. days .. " days")
			end

			dbWho(chatvars.playerid, players[pid].xPos, players[pid].yPos, players[pid].zPos, range, days, hours, height)
		end		
		
		faultyChat = false
		return true
	end	

if debug then dbug("admin 35") end

	if (chatvars.words[1] == "bases" or chatvars.words[1] == "homes") then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
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

		faultyChat = false
		return true
	end

if debug then dbug("admin 36") end

	if (string.find(chatvars.command, "admin add ") and accessLevel(chatvars.playerid) == 0) then
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

		faultyChat = false
		return true
	end

if debug then dbug("admin 37") end

	if (string.find(chatvars.command, "admin remove ") and accessLevel(chatvars.playerid) == 0) then
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

		faultyChat = false
		return true
	end

if debug then dbug("admin 38") end

	if chatvars.words[1] == "goto" and chatvars.words[2] ~= nil then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		if (players[chatvars.playerid].timeout == true) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. You cannot /goto anywhere until you are released.[-]")
			faultyChat = false
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
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 39") end

	if (chatvars.words[1] == "offline" and chatvars.words[2] == "players" and chatvars.words[3] == "nearby") then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
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

		faultyChat = false
		return true
	end

if debug then dbug("admin 40") end

	if (chatvars.words[1] == "crimescene") then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
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
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 41") end

	if (chatvars.words[1] == "closeto" or chatvars.words[1] == "near") then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		if (players[chatvars.playerid].timeout == true) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. You cannot go anywhere until you are released for safety reasons.[-]")
			faultyChat = false
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
		
		faultyChat = false
		return true
	end

if debug then dbug("admin 42") end

	if (chatvars.words[1] == "add" and chatvars.words[2] == "bad" and chatvars.words[3] == "item" and chatvars.words[4] ~= nil) then
		if (accessLevel(chatvars.playerid) > 1) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a restricted command[-]")
			faultyChat = false
			return true
		end

		bad = string.sub(chatvars.command, string.find(chatvars.command, "bad item") + 9)

		conn:execute("INSERT INTO badItems SET item = '" .. bad .. "'")

		badItems[bad] = {}
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added " .. bad .. " to the list of bad items[-]")

		faultyChat = false
		return true
	end

if debug then dbug("admin 43") end

	if (chatvars.words[1] == "remove" and chatvars.words[2] == "bad" and chatvars.words[3] == "item" and chatvars.words[4] ~= nil) then
		if (accessLevel(chatvars.playerid) > 1) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a restricted command[-]")
			faultyChat = false
			return true
		end

		bad = string.sub(chatvars.command, string.find(chatvars.command, "bad item") + 9)

		conn:execute("DELETE FROM badItems WHERE item = '" .. bad .. "'")

		badItems[bad] = nil
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed " .. bad .. " from the list of bad items[-]")

		faultyChat = false
		return true
	end

if debug then dbug("admin 44") end

	if (chatvars.words[1] == "bad" and chatvars.words[2] == "items") then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a restricted command[-]")
			faultyChat = false
			return true
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I scan for these items in inventory:[-]")
		for k, v in pairs(badItems) do
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. k .. "[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 45") end

	if (chatvars.words[1] == "add" and chatvars.words[2] == "restricted") then
		if (accessLevel(chatvars.playerid) > 1) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a restricted command[-]")
			faultyChat = false
			return true
		end

		if (chatvars.words[3] == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Add an item to the inventory scanner for special attention.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. /add restricted item tnt qty 5 action timeout access 90[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players with access > 90 will be sent to timeout for more than 5 tnt.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, the name of a location (for exile), and watch[-]")
			faultyChat = false
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

		if action ~= "timeout" and action ~= "ban" and not locations[action] and action ~= "watch" then
			action = "timeout"
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Invalid action entered, using timeout instead.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, the name of a location (for exile), and watch[-]")
		end

		if item == "" or access == 100 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Item, qty and access are required.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. /add restricted item mineCandyTin qty 20 access 99 action timeout[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, exile. Bans last 1 day.[-]")
		else
			conn:execute("INSERT INTO restrictedItems (item, qty, accessLevel, action) VALUES ('" .. escape(item) .. "'," .. qty .. "," .. access .. ",'" .. action .. "') ON DUPLICATE KEY UPDATE item = '" .. escape(item) .. "', qty = " .. qty .. ", accessLevel = " .. access .. ", action = '" .. action .. "'")
			conn:execute("INSERT INTO memRestrictedItems (item, qty, accessLevel, action) VALUES ('" .. escape(item) .. "'," .. qty .. "," .. access .. ",'" .. action .. "') ON DUPLICATE KEY UPDATE item = '" .. escape(item) .. "', qty = " .. qty .. ", accessLevel = " .. access .. ", action = '" .. action .. "'")

			restrictedItems[item] = {}
			restrictedItems[item].qty = tonumber(qty)
			restrictedItems[item].accessLevel = tonumber(access)
			restrictedItems[item].action = action

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added " .. item .. " quantity " .. qty .. " with minimum access level " .. access .. " and action " .. action .. " to restricted items[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 46") end

	if (chatvars.words[1] == "remove" and chatvars.words[2] == "restricted" and chatvars.words[3] == "item" and chatvars.words[4] ~= nil) then
		if (accessLevel(chatvars.playerid) > 1) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a restricted command[-]")
			faultyChat = false
			return true
		end

		bad = string.sub(chatvars.command, string.find(chatvars.command, "restricted item") + 16)

		conn:execute("DELETE FROM restrictedItems WHERE item = '" .. bad .. "'")
		conn:execute("DELETE FROM memRestrictedItems WHERE item = '" .. bad .. "'")

		restrictedItems[bad] = nil
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed " .. bad .. " from the list of restricted items[-]")

		faultyChat = false
		return true
	end

if debug then dbug("admin 47") end

	if (chatvars.words[1] == "restricted" and chatvars.words[2] == "items") then
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
		
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I scan for these restricted items in inventory:[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Item      Quantity      Min Access Level[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "I scan for these restricted items in inventory:")
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Item.........Quantity..........Min Access Level")			
		end		

		for k, v in pairs(restrictedItems) do
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. k .. " max qty " .. v.qty .. " min access " .. v.accessLevel .. " action " .. v.action .. "[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, k .. " max qty " .. v.qty .. " min access " .. v.accessLevel .. " action " .. v.action)
			end			
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 48") end

	if (chatvars.words[1] == "prisoners" and chatvars.words[2] == nil) then	
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		-- pm a list of all the prisoners
		if (prisoners == {}) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Nobody is in prison[-]")	
			faultyChat = false
			return true
		end

		for k, v in pairs(players) do
			if v.prisoner then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " " .. v.prisonReason .. "[-]")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 49") end

	if (chatvars.words[1] == "equip" and chatvars.words[2] == "admin") then	
		if (accessLevel(chatvars.playerid) > 1) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
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


		if not string.find(tmp.inventory, "nailgun") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " nailgun 1', " .. chatvars.playerid .. ")")
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


		if not string.find(tmp.inventory, "keystoneBlock") then
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " keystoneBlock 10', " .. chatvars.playerid .. ")")
		else
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "keystoneBlock")

			if tonumber(tmp.quantity) < 10 then
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('give " .. chatvars.playerid .. " keystoneBlock " .. 10 - tonumber(tmp.quantity) .. "', " .. chatvars.playerid .. ")")
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
		faultyChat = false
		return true
	end

	if (chatvars.words[1] == "supplies") then	
		if (accessLevel(chatvars.playerid) > 1) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
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
		faultyChat = false
		return true
	end

if debug then dbug("admin 50") end

	if (chatvars.words[1] == "release" and chatvars.words[2] == "here" and chatvars.words[3] ~= nil) then	
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		prisoner = string.sub(chatvars.command, string.find(chatvars.command, ": /release here ") + 16)
		prisoner = string.trim(prisoner)
		prisonerid = LookupPlayer(prisoner)

		if (players[prisonerid].prisoner == false) then
			message("say [" .. server.chatColour .. "]Citizen " .. players[prisonerid].name .. " is not a prisoner[-]")
			faultyChat = false
			return true
		end

		players[prisonerid].prisoner = false

		conn:execute("UPDATE players SET prisoner = 0 WHERE steam = " .. prisonerid)

		message("say [" .. server.chatColour .. "]Releasing prisoner " .. players[prisonerid].name .. "[-]")

		if (players[prisonerid].steam) then
			message("pm " .. prisonerid .. " [" .. server.chatColour .. "]You are released from prison.  Be a good citizen if you wish to remain free.[-]")
			cmd = "tele " .. prisonerid .. " " .. chatvars.playerid
			prepareTeleport(prisonerid, cmd)

			if players[prisonerid].watchPlayer then
				irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
			end

			teleport(cmd, true)
			players[prisonerid].xPosOld = 0
			players[prisonerid].yPosOld = 0
			players[prisonerid].zPosOld = 0
			players[prisonerid].prisonxPosOld = 0
			players[prisonerid].prisonyPosOld = 0
			players[prisonerid].prisonzPosOld = 0
		end

		faultyChat = false
		return true
	end

if debug then dbug("admin 51") end

	if (chatvars.words[1] == "playerhome" or chatvars.words[1] == "playerbase" or chatvars.words[1] == "playerhome2" or chatvars.words[1] == "playerbase2") then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1], nil, true) + string.len(chatvars.words[1]))
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (pname == "") then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required or could not be found for this command[-]")
			faultyChat = false
			return true
		else
			if (chatvars.words[1] == "playerhome" or chatvars.words[1] == "playerbase") then
				if (players[id].homeX == 0 and players[id].homeZ == 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " Has not set a base yet.[-]")
					faultyChat = false
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
					faultyChat = false
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

		faultyChat = false
		return true
	end

if debug then dbug("admin end") end

end
