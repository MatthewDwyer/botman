--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local tmp

function activateWaypointTunnel()
	message("pm " .. tmp.steam .. " [" .. server.chatColour .. "]Chevron Seven is LOCKED![-]")
	conn:execute("UPDATE waypoints SET linked = " .. tmp.wp1id .. " WHERE id = " .. tmp.wp2id)
	conn:execute("UPDATE waypoints SET linked = " .. tmp.wp2id .. " WHERE id = " .. tmp.wp1id)
	loadWaypoints(tmp.steam)
end


function gmsg_waypoints()
	calledFunction = "gmsg_waypoints"

	local debug
	local shortHelp = false
	local skipHelp = false

	debug = false

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.words[3], "way") then
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
		irc_chat(players[chatvars.ircid].ircAlias, "Waypoint Commands:")
		irc_chat(players[chatvars.ircid].ircAlias, "==================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if chatvars.showHelpSections then
		irc_chat(players[chatvars.ircid].ircAlias, "waypoints")
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "way")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set waypoints public/restricted")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make waypoints accessible to all (except new players) or restricted to donors only.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and (string.find(chatvars.words[2], "wayp") or chatvars.words[2] == "wp")) and (chatvars.words[3] == "public" or chatvars.words[3] == "private" or chatvars.words[3] == "restricted") then
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

		if chatvars.words[3] == "public" then
			server.waypointsPublic = true
			conn:execute("UPDATE server SET waypointsPublic = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Everyone except new players can set and share waypoints.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Everyone except new players can set and share waypoints.")
			end
		else
			server.waypointsPublic = false
			conn:execute("UPDATE server SET waypointsPublic = 0")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are restricted to donors only.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Waypoints are restricted to donors only.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "way")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set max waypoints <number>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set max waypoints <player> number <number>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set max waypoints donors <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set the max number of waypoints players can have or a specific player can have.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "waypoints" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

		tmp = {}

		if chatvars.number == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number is required.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "A number is required.")
			end

			botman.faultyChat = false
			return true
		end

		if string.find(chatvars.command, " number ") then
			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "waypoints ") + 10, string.find(chatvars.command, " number") - 1)
			tmp.pname = stripQuotes(tmp.pname)
			tmp.id = LookupPlayer(tmp.pname)

			if tmp.id ~= nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[tmp.id].name .. " can set " .. chatvars.number .. " waypoints.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "Player " .. players[tmp.id].name .. " can set " .. chatvars.number .. " waypoints.")
				end

				conn:execute("UPDATE players SET maxWaypoints = " .. chatvars.number .. " where steam = " .. tmp.id)
				players[tmp.id].maxWaypoints = chatvars.number
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No matching player name found.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "No matching player name found.")
				end
			end
		else
			if string.find(chatvars.command, " donors ") then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Donors can set a maximum of " .. chatvars.number .. " waypoints unless individually set to something else.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "Donors can set a maximum of " .. chatvars.number .. " waypoints unless individually set to something else.")
				end

				for k,v in pairs(players) do
					if v.donor then
						v.maxWaypoints = chatvars.number
						conn:execute("UPDATE players SET maxWaypoints = " .. chatvars.number .. " where steam = " .. k)
					end
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can set a maximum of " .. chatvars.number .. " waypoints unless individually set to something else.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "Players can set a maximum of " .. chatvars.number .. " waypoints unless individually set to something else.")
				end

				conn:execute("UPDATE server SET maxWaypoints = " .. chatvars.number)
				conn:execute("UPDATE players SET maxWaypoints = " .. chatvars.number)
				server.maxWaypoints = chatvars.number

				for k,v in pairs(players) do
					v.maxWaypoints = chatvars.number
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way") or string.find(chatvars.command, "cost"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set waypoint cost <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set a price to use waypoints.  Players must have sufficient " .. server.moneyPlural .. " to teleport.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and string.find(chatvars.words[2], "way") and chatvars.words[3] == "cost" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

		if chatvars.number then
			server.waypointCost = chatvars.number
			conn:execute("UPDATE server SET waypointCost = " .. chatvars.number)

			message("say [" .. server.chatColour .. "]Waypoints now cost " .. chatvars.number .. " " .. server.moneyPlural .. " per use.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way") or string.find(chatvars.command, "cost"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set waypoint create cost <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set a price to create waypoints.  Players must have sufficient " .. server.moneyPlural)
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and string.find(chatvars.words[2], "way") and chatvars.words[3] == "create" and chatvars.words[4] == "cost" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

		if chatvars.number then
			server.waypointCreateCost = chatvars.number
			conn:execute("UPDATE server SET waypointCreateCost = " .. chatvars.number)

			message("say [" .. server.chatColour .. "]Waypoints now cost " .. chatvars.number .. " " .. server.moneyPlural .. " to make.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way") or string.find(chatvars.command, "time") or string.find(chatvars.command, "cool"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set waypoint cooldown <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set how long in seconds players must wait between uses of waypoints")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and string.find(chatvars.words[2], "way") and chatvars.words[3] == "cooldown" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

		if chatvars.number then
			server.waypointCooldown = chatvars.number
			conn:execute("UPDATE server SET waypointCooldown = " .. chatvars.number)

			message("say [" .. server.chatColour .. "]Waypoints now have a timer. You must wait " .. chatvars.number .. " seconds after each use.[-]")
		end

		botman.faultyChat = false
		return true
	end

	-- ###################  do not allow remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(players[chatvars.ircid].ircAlias, "")
		irc_chat(players[chatvars.ircid].ircAlias, "Waypoint Commands (In-Game Only):")
		irc_chat(players[chatvars.ircid].ircAlias, "=================================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "open waypoint (or wp)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Share the first waypoint with your friends.  The 2nd waypoint is always private.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "open" or chatvars.words[1] == "share") and (string.find(chatvars.words[2], "wayp") or chatvars.words[2] == "wp") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 10) and not server.waypointsPublic then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			botman.faultyChat = false
			return true
		end

		tmp = {}

		if chatvars.words[3] ~= nil then
			tmp.id = LookupWaypointByName(chatvars.playerid, chatvars.words[3])
		else
			tmp.id = ClosestWaypoint(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].yPos, igplayers[chatvars.playerid].zPos, chatvars.playerid)
		end

		if tmp.id ~= 0 then
			-- mark the waypoint as shared so friends can use it.
			waypoints[tmp.id].shared = true
			conn:execute("UPDATE waypoints SET shared = 1 WHERE id = " .. tmp.id)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your friends can now teleport to your waypoint by typing " .. server.commandPrefix .. "wp " .. waypoints[tmp.id].name .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "close waypoint (or wp)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Make the first waypoint private again. This is its default state.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "close" or chatvars.words[1] == "unshare") and (string.find(chatvars.words[2], "wayp") or chatvars.words[2] == "wp") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 10) and not server.waypointsPublic then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			botman.faultyChat = false
			return true
		end

		tmp = {}

		if chatvars.words[3] ~= nil then
			tmp.id = LookupWaypointByName(chatvars.playerid, chatvars.words[3])
		else
			tmp.id = ClosestWaypoint(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].yPos, igplayers[chatvars.playerid].zPos, chatvars.playerid)
		end

		if tmp.id ~= 0 then
			-- mark the waypoint as not shared to make it private.
			waypoints[tmp.id].shared = false
			conn:execute("UPDATE waypoints SET shared = 0 WHERE id = " .. tmp.id)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoint " .. waypoints[tmp.id].name .. " is now private.  Only you can use it.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set waypoint (or wp or wp1)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Create or move your first waypoint where you are standing.  It retains its current status.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and (string.find(chatvars.words[2], "wayp") or chatvars.words[2] == "wp")) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 10) and not server.waypointsPublic then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			botman.faultyChat = false
			return true
		end

		tmp = {}

		if chatvars.words[3] == nil then
			tmp.name = "wp1"
		else
			tmp.name = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[3]))
		end

		tmp.id = LookupWaypointByName(chatvars.playerid, tmp.name)

		if tonumber(tmp.id) ~= 0 then
			conn:execute("update waypoints set x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. " where id = " .. tmp.id)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have updated a waypoint.  You can teleport to it with " .. server.commandPrefix .. "wp " .. tmp.name .. "[-]")
		else
			-- check that they haven't already reached
			cursor,errorString = conn:execute("select count(id) as totalWaypoints from waypoints where steam = " .. chatvars.playerid)
			row = cursor:fetch({}, "a")

			if tonumber(row.totalWaypoints) >= tonumber(players[chatvars.playerid].maxWaypoints) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have reached your limit of " .. players[chatvars.playerid].maxWaypoints .. " waypoints.  To set this waypoint, you must modify an existing waypoint or clear one first.[-]")
				botman.faultyChat = false
				return true
			end

			-- allow if sufficient zennies
			if tonumber(server.waypointCreateCost) > 0 and (chatvars.accessLevel > 2) then
				if tonumber(players[chatvars.playerid].cash) < tonumber(server.waypointCreateCost) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. ".  You require " .. server.waypointCreateCost .. ".  Kill some zombies, gamble, trade or beg to earn more.[-]")
					botman.faultyChat = false
					return true
				end
			end

			conn:execute("insert into waypoints (steam, name, x, y, z) values (" .. chatvars.playerid ..",'" .. escape(tmp.name) .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You created a waypoint.  You can teleport to it with " .. server.commandPrefix .. "wp " .. tmp.name .. "[-]")
			players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - server.waypointCreateCost
		end

		-- reload the player's waypoints into the Lua table waypoints
		loadWaypoints(chatvars.playerid)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "clear wp <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Delete a named waypoint.  If they are linked, this also unlinks them.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "clear" and (chatvars.words[2] == "wp" or string.find(chatvars.words[2], "way"))) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 10) and not server.waypointsPublic then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			botman.faultyChat = false
			return true
		end

		tmp = {}

		if chatvars.words[3] == nil then
			tmp.name = "wp1"
		else
			tmp.name = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[3]))
		end

		tmp.id = LookupWaypointByName(chatvars.playerid, tmp.name)

		if tonumber(tmp.id) ~= 0 then
			-- unlink if wp linked
			if waypoints[tmp.id].linked > 0 then
				conn:execute("UPDATE waypoints SET linked = 0 WHERE id = " .. tmp.id .. " or linked = " .. tmp.id)
			end

			-- now delete the wp
			conn:execute("Delete from waypoints where id = " .. tmp.id)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have cleared waypoint " .. tmp.name .. ".[-]")

			-- reload the player's waypoints
			loadWaypoints(chatvars.playerid)
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No waypoint found called " .. tmp.name .. ".[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "waypoint or " .. server.commandPrefix .. "wp1 or " .. server.commandPrefix .. "<your name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Teleport to your first waypoint.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "waypoint" or chatvars.words[1] == "wp") and (chatvars.playerid ~= 0) then
		-- reject if not an admin and player teleporting has been disabled
		if (chatvars.accessLevel > 2) and not server.allowTeleporting then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting has been disabled on this server.[-]")
			botman.faultyChat = false
			result = true
			return
		end

		if (chatvars.accessLevel > 10) and not server.waypointsPublic then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			botman.faultyChat = false
			return true
		end

		tmp = {}

		if chatvars.words[2] == nil then
			tmp.name = "wp1"
		else
			tmp.name = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[2]))
		end

		if chatvars.words[3] ~= nil then
			tmp.friend = LookupPlayer(chatvars.words[2])
			tmp.name = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[3]))

			if tmp.friend ~= nil then
				tmp.id = LookupWaypointByName(chatvars.playerid, tmp.name, tmp.friend)
			end
		else
			tmp.id = LookupWaypointByName(chatvars.playerid, tmp.name)
		end

		if tonumber(tmp.id) > 0 then
			-- check the waypointCooldown
			if (chatvars.accessLevel > 3) then
				if (players[chatvars.playerid].waypointCooldown - os.time() > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have to wait " .. os.date("%M minutes %S seconds",players[chatvars.playerid].waypointCooldown - os.time()) .. " before you can use another waypoint.[-]")
					botman.faultyChat = false
					return true
				end
			end

			-- reject if not an admin and pvpTeleportCooldown is > zero
			if tonumber(chatvars.accessLevel) > 2 and (players[chatvars.playerid].pvpTeleportCooldown - os.time() > 0) then
				message(string.format("pm %s [%s]You must wait %s before you are allowed to teleport again.", chatvars.playerid, server.chatColour, os.date("%M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())))
				botman.faultyChat = false
				result = true
				return
			end

			-- check the waypoint destination in restricted area
			if (chatvars.accessLevel > 3) then
				if not isDestinationAllowed(chatvars.playerid, waypoints[tmp.id].x, waypoints[tmp.id].z) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry, your waypoint is in a restricted area.[-]")
					botman.faultyChat = false
					return true
				end
			end

			-- teleport if sufficient zennies
			if tonumber(server.waypointCost) > 0 and (chatvars.accessLevel > 2) then
				if tonumber(players[chatvars.playerid].cash) < tonumber(server.waypointCost) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. ".  You require " .. server.waypointCost .. ".  Kill some zombies, gamble, trade or beg to earn more.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if tonumber(waypoints[tmp.id].linked) > 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That waypoint is linked with another.  Nobody can teleport to them until they are unlinked.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To use it simply step on it and wait a few seconds.[-]")
				botman.faultyChat = false
				return true
			end

			-- store the current coords
			players[chatvars.playerid].xPosOld = chatvars.intX
			players[chatvars.playerid].yPosOld = chatvars.intY
			players[chatvars.playerid].zPosOld = chatvars.intZ
			igplayers[chatvars.playerid].lastLocation = ""

			-- tp the player to the waypointwaypoint
			cmd = "tele " .. chatvars.playerid .. " " .. waypoints[tmp.id].x .. " " .. waypoints[tmp.id].y .. " " .. waypoints[tmp.id].z

			teleport(cmd, chatvars.playerid)
			players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - server.waypointCost

			if tonumber(server.waypointCooldown) > 0 then
				players[chatvars.playerid].waypointCooldown = os.time() + server.waypointCooldown
			end
		else
			if tmp.friend ~= nil then
				if not isFriend(tmp.friend, chatvars.playerid) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.friend].name .. " is not friends with you so you can't visit their waypoints.[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.friend].name .. " does not have a waypoint called " .. tmp.name .. ".[-]")
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no waypoint called " .. tmp.name .. ".[-]")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "waypoints <player name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "List the waypoints of a player.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "waypoints") and (chatvars.playerid ~= 0) then
		tmp = {}
		tmp.steam = chatvars.playerid

		if chatvars.words[2] ~= nil and chatvars.words[2] ~= "range" then
			tmp.name = chatvars.words[2]
			tmp.name = string.trim(tmp.name)
			if (tmp.name ~= nil) then tmp.steam = LookupPlayer(tmp.name) end

			if (tmp.steam == nil) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. tmp.name .. "[-]")
				botman.faultyChat = false
				return true
			end

			if chatvars.accessLevel > 3 then
				if not isFriend(tmp.steam, chatvars.playerid) and tmp.steam ~= chatvars.playerid then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can only view your friends or your own waypoints.[-]")
					botman.faultyChat = false
					return true
				end
			end
		end

		for i=2,chatvars.wordCount,1 do
			if chatvars.words[i] == "range" then
				tmp.range = tonumber(chatvars.words[i+1])
			end
		end

		if (tmp.steam == nil and tmp.range == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name or id is required unless a range is specified instead.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "waypoints Smegz0r or " .. server.commandPrefix .. "waypoints range 50.[-]")
			botman.faultyChat = false
			return true
		end

		if (tmp.steam ~= nil and tmp.range == nil) then
			cursor,errorString = conn:execute("select * from waypoints where steam = " .. tmp.steam)
			row = cursor:fetch({}, "a")

			if row then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. "'s waypoints:[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. " has no waypoints.[-]")
			end

			while row do
				if row.shared == "1" then
					tmp.shared = " shared "
				else
					tmp.shared = " private "
				end

				if tonumber(row.linked) > 0 then
					tmp.linked = " linked to " .. waypoints[tonumber(row.linked)].name .. " "
				else
					tmp.linked = ""
				end

				if chatvars.accessLevel > 3 and (tmp.shared == " shared " or chatvars.playerid == row.steam) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked .. "[-]")
				end

				if chatvars.accessLevel < 4 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked .. "[-]")
				end

				row = cursor:fetch(row, "a")
			end

			botman.faultyChat = false
			return true
		end

		if tmp.range ~= nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints within " .. tmp.range .. " metres:[-]")

			cursor,errorString = conn:execute("select * from waypoints where steam = " .. tmp.steam)
			row = cursor:fetch({}, "a")

			while row do
				tmp.dist = distancexyz(chatvars.intX, chatvars.intY, chatvars.intZ, row.x, row.y, row.z)

				if tonumber(tmp.dist) <= tmp.range then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[row.steam].name .. " " .. row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. "[-]")
				end

				row = cursor:fetch(row, "a")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "link wp <name of wp1> to <name of wp2>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Link your waypoints to create a portal instead.  In this mode you cannot teleport to them, instead you activate them by stepping into them.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "link") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 10) and not server.waypointsPublic then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			botman.faultyChat = false
			return true
		end

		tmp = {}
		tmp.steam = chatvars.playerid
		tmp.wp1 = string.sub(chatvars.command, string.find(chatvars.command, "link ") + 5, string.find(chatvars.command, " to ") - 1)
		tmp.wp2 = string.sub(chatvars.command, string.find(chatvars.command, " to ") + 4)

		tmp.wp1id = LookupWaypointByName(chatvars.playerid, tmp.wp1)
		tmp.wp2id = LookupWaypointByName(chatvars.playerid, tmp.wp2)

		if tmp.wp1id == 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoint " .. tmp.wp1 .. " not found.[-]")
			botman.faultyChat = false
			return true
		end

		if tmp.wp2id == 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoint " .. tmp.wp2 .. " not found.[-]")
			botman.faultyChat = false
			return true
		end

		conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. chatvars.playerid .. ",'" .. escape("[" .. server.chatColour .. "]Linking waypoints " .. tmp.wp1 .. " to " .. tmp.wp2 .. "..[-]") .. "')")
		conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. chatvars.playerid .. ",'" .. escape("[" .. server.chatColour .. "]Chevron One encoded[-]") .. "')")
		conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. chatvars.playerid .. ",'" .. escape("[" .. server.chatColour .. "]Chevron Two encoded[-]") .. "')")
		conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. chatvars.playerid .. ",'" .. escape("[" .. server.chatColour .. "]Chevron Three encoded[-]") .. "')")
		conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. chatvars.playerid .. ",'" .. escape("[" .. server.chatColour .. "]Chevron Four encoded[-]") .. "')")
		conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. chatvars.playerid .. ",'" .. escape("[" .. server.chatColour .. "]Chevron Five encoded[-]") .. "')")
		conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. chatvars.playerid .. ",'" .. escape("[" .. server.chatColour .. "]Chevron Six encoded[-]") .. "')")

		tempTimer( 16, [[ activateWaypointTunnel() ]] )

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "unlink waypoints (or " .. server.commandPrefix .. "unlink wp)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Close your portal and convert each end back into two waypoints which you can teleport to as normal.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "unlink") and (chatvars.playerid ~= 0) then
		tmp = {}

		if (chatvars.accessLevel > 10) and not server.waypointsPublic then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			botman.faultyChat = false
			return true
		end

		tmp = {}
		tmp.wp1 = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[2]))
		tmp.wp1id = LookupWaypointByName(chatvars.playerid, tmp.wp1)

		if tmp.wp1id == 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoint " .. tmp.wp1 .. " not found.[-]")
			botman.faultyChat = false
			return true
		end

		conn:execute("UPDATE waypoints SET linked = 0 WHERE id = " .. tmp.wp1id)
		conn:execute("UPDATE waypoints SET linked = 0 WHERE linked = " .. tmp.wp1id)
		loadWaypoints(tmp.steam)

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your waypoints have disengaged and you can now use them as waypoints again.[-]")

		botman.faultyChat = false
		return true
	end

if debug then dbug("debug waypoints end") end

end
