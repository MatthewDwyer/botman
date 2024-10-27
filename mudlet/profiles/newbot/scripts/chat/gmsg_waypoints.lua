--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_waypoints()
	local tmp, debug, pname, pid, result, help
	local shortHelp = false

	debug = false -- should be false unless testing

	calledFunction = "gmsg_waypoints"
	result = false
	tmp = {}
	tmp.topic = "waypoints"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## waypoint command functions ##################

	local function cmd_ClearAllWaypoints()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}clear all waypoints {optional player name}"
			help[2] = "Delete all your waypoints (anyone can do this) or those of a named player (only admins)"

			tmp.command = help[1]
			tmp.keywords = "waypoints,clear,all,delete,remove"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") or string.find(chatvars.command, "clear") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "clear" and chatvars.words[2] == "all" and string.find(chatvars.words[3], "wayp") then
			if not chatvars.settings.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.words[4]) and not chatvars.isAdminHidden then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Only admins can clear a named player's waypoints.  Just type " .. server.commandPrefix .. "clear waypoints[-]")
				else
					irc_chat(chatvars.ircAlias, "Only admins can clear a named player's waypoints.  Just type " .. server.commandPrefix .. "clear waypoints")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[4] ~= nil then
				pname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[3], nil, true) + string.len(chatvars.words[3]))
				pname = string.trim(pname)
				pid = LookupPlayer(pname)

				if pid == "0" then
					pid = LookupArchivedPlayer(pname)

					if not (pid == "0") then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end
				end

				if not (pid == "0") then
					conn:execute("DELETE FROM waypoints WHERE steam = '" .. pid .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have deleted all of " .. players[pid].name .. "'s waypoints.[-]")
					else
						irc_chat(chatvars.ircAlias, "You have deleted all of " .. players[pid].name .. "'s waypoints.")
					end

					-- reload the player's waypoints
					loadWaypoints(pid)
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found called " .. pname)
					end
				end

				botman.faultyChat = false
				return true
			else
				if (chatvars.playername ~= "Server") then
					conn:execute("DELETE FROM waypoints WHERE steam = '" .. chatvars.playerid .. "'")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have deleted all of your waypoints.[-]")

					-- reload the player's waypoints
					loadWaypoints(chatvars.playerid)
				else
					conn:execute("DELETE FROM waypoints WHERE steam = '" .. chatvars.ircid .. "'")
					irc_chat(chatvars.ircAlias, "You have deleted all of your waypoints.")

					-- reload the player's waypoints
					loadWaypoints(chatvars.ircid)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ClearWaypoint()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}clear wp {name}"
			help[2] = "Delete a named waypoint.  If they are linked, this also unlinks them."

			tmp.command = help[1]
			tmp.keywords = "waypoints,clear,delete,remove"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "clear" and (chatvars.words[2] == "wp" or string.find(chatvars.words[2], "way"))) then
			if not chatvars.settings.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

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
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have cleared waypoint " .. tmp.name .. ".[-]")

				-- reload the player's waypoints
				tempTimer( 2, [[loadWaypoints("]] .. chatvars.playerid .. [[")]] )
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No waypoint found called " .. tmp.name .. ".[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_CloseWaypoint()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}close (or {#}unshare) wp {waypoint name}"
			help[2] = "Make a waypoint private again. This is its default state."

			tmp.command = help[1]
			tmp.keywords = "waypoints,close,private,public,unshare,wp"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "close" or chatvars.words[1] == "unshare") and (string.find(chatvars.words[2], "wayp") or chatvars.words[2] == "wp") then
			if not chatvars.settings.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

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
				conn:execute("UPDATE waypoints SET linked = 0 WHERE linked = " .. tmp.id)
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoint " .. waypoints[tmp.id].name .. " is now private.  Only you can use it.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LinkWaypoints()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}link wp {name of wp1} to {name of wp2}\n"
			help[1] = help[1] .. " {#}link wp {name of wp1} to friend {name} wp {their shared waypoint}"
			help[2] = "Link your waypoints to create a portal instead.  In this mode you can activate them by stepping into them.\n"
			help[2] = help[2] .. "You can link your waypoint to the shared waypoint of a friend until they unshare or delete their waypoint."

			tmp.command = help[1]
			tmp.keywords = "waypoints,link,join,portal"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "link" and chatvars.words[2] == "wp" then
			if not chatvars.settings.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

			if (not chatvars.isAdminHidden) and server.disableLinkedWaypoints then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Linking waypoints is disabled on this server.[-]")
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.steam = chatvars.playerid
			tmp.wp1 = string.sub(chatvars.command, string.find(chatvars.command, "link ") + 8, string.find(chatvars.command, " to ") - 1)

			if string.find(chatvars.command, "to friend") then
				tmp.cmd = string.sub(chatvars.command, string.find(chatvars.command, "to friend ") + 10)

				tmp.friend = string.sub(tmp.cmd, 1, string.find(tmp.cmd, " wp ") - 1)
				tmp.wp2 = chatvars.words[chatvars.wordCount]
				tmp.friendID = LookupPlayer(tmp.friend)

				tmp.wp2id = LookupWaypointByName(tmp.friendID, tmp.wp2)
			else
				tmp.wp2 = string.sub(chatvars.command, string.find(chatvars.command, " to ") + 4)
				tmp.wp2id = LookupWaypointByName(chatvars.playerid, tmp.wp2)
			end

			tmp.wp1id = LookupWaypointByName(chatvars.playerid, tmp.wp1)

			if tmp.wp1id == "0" then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoint " .. tmp.wp1 .. " not found.[-]")
				botman.faultyChat = false
				return true
			end

			if tmp.wp2id == "0" then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoint " .. tmp.wp2 .. " not found.[-]")
				botman.faultyChat = false
				return true
			end

			conn:execute("UPDATE waypoints SET linked = " .. tmp.wp1id .. " WHERE id = " .. tmp.wp2id)
			conn:execute("UPDATE waypoints SET linked = " .. tmp.wp2id .. " WHERE id = " .. tmp.wp1id)
			tempTimer( 2, [[loadWaypoints()]] )

			if tmp.friend then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoint " .. tmp.wp1 .. " is now linked to " .. players[tmp.friendID].name .. "'s shared wp " .. tmp.wp2 .. ".[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoint " .. tmp.wp1 .. " is now linked to " .. tmp.wp2 .. ".[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListWaypoints()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}waypoints {player name} (list a player's waypoints)\n"
			help[1] = help[1] .. " {#}waypoints range {distance} (list all waypoints within range of your position)\n"
			help[1] = help[1] .. " {#}waypoints near {player or location} range {distance} (list all waypoints within range of a player or location)"
			help[2] = "List the waypoints of a player or within {distance} of your current position or the location of another player or location."

			tmp.command = help[1]
			tmp.keywords = "waypoints,list"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, " " .. help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "waypoints" or (chatvars.words[1] == "list" and chatvars.words[2] == "waypoints") then
			if not chatvars.settings.allowWaypoints and not chatvars.isAdminHidden then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.steam = chatvars.playerid
			tmp.location = 0
			tmp.range = 0

			if not (string.find(chatvars.command, "near") or string.find(chatvars.command, "range")) then
				-- get the player name
				tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "waypoints") + 10)
			else
				if (string.find(chatvars.command, "near")) then
					-- set a default range
					tmp.range = 30

					-- get the player name
					if string.find(chatvars.command, "range") then
						tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "near") + 5, string.find(chatvars.command, "range") - 1)
					else
						tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "near") + 5)
					end
				end
			end

			-- lookup the player
			if (tmp.name ~= "") then
				tmp.name = string.trim(tmp.name)
				tmp.steam = LookupPlayer(tmp.name)

				if tmp.steam == "0" then
					tmp.steam = LookupArchivedPlayer(tmp.pname)

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

				if (tmp.steam == "0") then
					-- look for a location instead
					if chatvars.isAdminHidden then
						tmp.location = LookupLocation(tmp.name)

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player or location found called " .. tmp.name .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player or location found called " .. tmp.name)
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. tmp.name .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found called " .. tmp.name)
						end
					end

					botman.faultyChat = false
					return true
				end

				if chatvars.accessLevel > 3 then
					if not isFriend(tmp.steam, chatvars.playerid) and tmp.steam ~= chatvars.playerid then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You can only view your friends waypoints or your own waypoints.[-]")
						else
							irc_chat(chatvars.ircAlias, "You can only view your friends waypoints or your own waypoints.")
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if string.find(chatvars.command, "range") and chatvars.number then
				tmp.range = math.abs(chatvars.number)
			end

			if (tmp.steam ~= "0" and tmp.range == 0) then
				cursor,errorString = conn:execute("select * from waypoints where steam = '" .. tmp.steam .. "'")
				row = cursor:fetch({}, "a")

				if row then
					if tmp.steam == chatvars.playerid then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your waypoints:[-]")
						else
							irc_chat(chatvars.ircAlias, "Your waypoints:")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. "'s waypoints:[-]")
						else
							irc_chat(chatvars.ircAlias, players[tmp.steam].name .. "'s waypoints:")
						end
					end
				else
					if tmp.steam == chatvars.playerid then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have no waypoints.[-]")
						else
							irc_chat(chatvars.ircAlias, "You have no waypoints.")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. " has no waypoints.[-]")
						else
							irc_chat(chatvars.ircAlias, players[tmp.steam].name .. " has no waypoints.")
						end
					end
				end
			end

			if (tmp.steam ~= "0" and tmp.range ~= 0) then
				cursor,errorString = conn:execute("select * from waypoints where steam = '" .. tmp.steam .. "'")
				row = cursor:fetch({}, "a")

				if row then
					if tmp.steam == chatvars.playerid then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints within " .. tmp.range .. " metres:[-]")
						else
							irc_chat(chatvars.ircAlias, "Waypoints within " .. tmp.range .. " metres:")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints within " .. tmp.range .. " metres of " .. players[tmp.steam].name .. ":[-]")
						else
							irc_chat(chatvars.ircAlias, "Waypoints within " .. tmp.range .. " metres of " .. players[tmp.steam].name .. ":")
						end
					end
				else
					if tmp.steam == chatvars.playerid then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No waypoints found.[-]")
						else
							irc_chat(chatvars.ircAlias, "No waypoints found.")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No waypoints found near " .. players[tmp.steam].name .. ".[-]")
						else
							irc_chat(chatvars.ircAlias, "No waypoints found near " .. players[tmp.steam].name .. ".")
						end
					end
				end
			end

			if (tmp.location ~= 0) then
				cursor,errorString = conn:execute("select * from waypoints")
				row = cursor:fetch({}, "a")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints within " .. tmp.range .. " metres of " .. tmp.location .. ":[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints within " .. tmp.range .. " metres of " .. tmp.location .. ":")
				end
			end

			while row do
				if tmp.range ~= 0 then
					if tmp.location ~= 0 then
						tmp.dist = distancexyz(locations[tmp.location].x, locations[tmp.location].y, locations[tmp.location].z, row.x, row.y, row.z)
					else
						tmp.dist = distancexyz(chatvars.intX, chatvars.intY, chatvars.intZ, row.x, row.y, row.z)
					end

					if tonumber(tmp.dist) <= tmp.range then
						tmp.shared = " private "

						if row.shared == "1" then
							tmp.shared = " shared "
						end

						if row.public == "1" then
							tmp.shared = " public "
						end

						if tonumber(row.linked) > 0 then
							if waypoints[tonumber(row.linked)].steam ~= tmp.steam then
								tmp.linked = " linked to " .. players[row.steam].name .. "'s shared waypoint " .. waypoints[tonumber(row.linked)].name
							else
								tmp.linked = " linked to " .. waypoints[tonumber(row.linked)].name
							end
						else
							tmp.linked = ""
						end

						if not chatvars.isAdminHidden and (tmp.shared == " shared " or chatvars.playerid == row.steam) then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.name .. " " .. tmp.shared .. tmp.linked .. "[-]")
							else
								irc_chat(chatvars.ircAlias, row.name .. " " .. tmp.shared .. tmp.linked)
							end
						end

						if chatvars.isAdminHidden then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked .. "[-]")
							else
								irc_chat(chatvars.ircAlias, row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked)
							end
						end
					end
				else
					tmp.shared = " private "

					if row.shared == "1" then
						tmp.shared = " shared "
					end

					if row.public == "1" then
						tmp.shared = " public "
					end

					if tonumber(row.linked) > 0 then
						if waypoints[tonumber(row.linked)].steam ~= tmp.steam then
							tmp.linked = " linked to " .. players[row.steam].name .. "'s shared waypoint " .. waypoints[tonumber(row.linked)].name
						else
							tmp.linked = " linked to " .. waypoints[tonumber(row.linked)].name
						end
					else
						tmp.linked = ""
					end

					if not chatvars.isAdminHidden and (tmp.shared == " shared " or chatvars.playerid == row.steam) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.name .. " " .. tmp.shared .. tmp.linked .. "[-]")
						else
							irc_chat(chatvars.ircAlias, row.name .. " " .. tmp.shared .. tmp.linked)
						end
					end

					if chatvars.isAdminHidden then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked .. "[-]")
						else
							irc_chat(chatvars.ircAlias, row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked)
						end
					end
				end

				row = cursor:fetch(row, "a")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_OpenWaypoint()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}open (or {#}share) wp {waypoint name}"
			help[2] = "Share a waypoint with your friends."

			tmp.command = help[1]
			tmp.keywords = "waypoints,open,share,friends"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "open" or chatvars.words[1] == "share") and (string.find(chatvars.words[2], "wayp") or chatvars.words[2] == "wp") then
			if not chatvars.settings.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

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
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your friends can now teleport to your waypoint by typing " .. server.commandPrefix .. "wp " .. players[chatvars.playerid].name .. " " .. waypoints[tmp.id].name .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleAllowLinkedWaypoints()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable linked waypoints (default enabled)"
			help[2] = "If disabled, players will not be able to link waypoints.  Also any non-admin existing linked waypoints will be unlinked."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,waypoints,linked"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "linked" and chatvars.words[3] == "waypoints" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.disableLinkedWaypoints = false
				if botman.dbConnected then conn:execute("UPDATE server SET disableLinkedWaypoints = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can link pairs of waypoints.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can link pairs of waypoints.")
				end
			else
				server.disableLinkedWaypoints = true
				if botman.dbConnected then conn:execute("UPDATE server SET disableLinkedWaypoints = 1") end
				if botman.dbConnected then conn:execute("UPDATE waypoints SET linked = 0 WHERE linked > 0 AND steam NOT IN (SELECT steam FROM staff)") end

				tempTimer( 2, [[loadWaypoints()]] )

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can not link waypoints and existing linked waypoints have been unlinked (except for admins).[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can not link waypoints and existing linked waypoints have been unlinked (except for admins).")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleWaypoints()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable waypoints"
			help[2] = "Allow players to create, use and share waypoints."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,waypoints"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") and chatvars.showHelp or botman.registerHelp then
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

		if ((chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "waypoints") or (chatvars.words[1] == "set" and (chatvars.words[2] == "enable" or chatvars.words[2] == "disable") and chatvars.words[3] == "waypoints")	then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.allowWaypoints = true
				if botman.dbConnected then conn:execute("UPDATE server SET allowWaypoints = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints are enabled for players who are not in a group.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are enabled for players who are not in a group.")
				end
			else
				server.allowWaypoints = false
				if botman.dbConnected then conn:execute("UPDATE server SET allowWaypoints = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints are disabled for players who are not in a group.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled for players who are not in a group.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxWaypoints()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set max waypoints {number} (server wide)\n"
			help[1] = help[1] .. "Or {#}set max waypoints {player name} number {number} (for a specific player)\n"
			help[1] = help[1] .. "Or {#}set max waypoints donors {number} (for donors)"
			help[2] = "Set the max number of waypoints players can have or a specific player can have."

			tmp.command = help[1]
			tmp.keywords = "waypoints,set,maximum,donors"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, " " .. help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "waypoints" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Don't forget to {#}enable waypoints.[-]")
				else
					irc_chat(chatvars.ircAlias, "Don't forget to {#}enable waypoints.")
				end
			end

			tmp = {}

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A number is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "A number is required.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.numberCount > 1 then
				tmp.maxWaypoints = chatvars.numbers[2]
			else
				tmp.maxWaypoints = chatvars.numbers[1]
			end

			if string.find(chatvars.command, " number ") then
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "waypoints ") + 10, string.find(chatvars.command, " number") - 1)
				tmp.pname = stripQuotes(tmp.pname)
				tmp.id = LookupPlayer(tmp.pname)

				if tmp.id == "0" then
					tmp.id = LookupArchivedPlayer(tmp.pname)

					if not (tmp.id == "0") then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end
				end

				if tmp.id ~= "0" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. players[tmp.id].name .. " can set " .. tmp.maxWaypoints .. " waypoints.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. players[tmp.id].name .. " can set " .. tmp.maxWaypoints .. " waypoints.")
					end

					conn:execute("UPDATE players SET maxWaypoints = " .. tmp.maxWaypoints .. " where steam = '" .. tmp.id .. "'")
					players[tmp.id].maxWaypoints = tmp.maxWaypoints
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No matching player name found.[-]")
					else
						irc_chat(chatvars.ircAlias, "No matching player name found.")
					end
				end
			else
				if string.find(chatvars.command, " donors ") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Donors can set a maximum of " .. tmp.maxWaypoints .. " waypoints unless individually set to something else.[-]")
					else
						irc_chat(chatvars.ircAlias, "Donors can set a maximum of " .. tmp.maxWaypoints .. " waypoints unless individually set to something else.")
					end

					for k,v in pairs(donors) do
						if not v.expired then
							players[k].maxWaypoints = tmp.maxWaypoints
							conn:execute("UPDATE players SET maxWaypoints = " .. tmp.maxWaypoints .. " where steam = '" .. k .. "'")
						end
					end

					server.maxWaypointsDonors = tmp.maxWaypoints
					conn:execute("UPDATE server SET maxWaypointsDonors = " .. tmp.maxWaypoints)
				else
					if chatvars.words[5] == nil then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can set a maximum of " .. tmp.maxWaypoints .. " waypoints unless individually set to something else.[-]")
						else
							irc_chat(chatvars.ircAlias, "Players can set a maximum of " .. tmp.maxWaypoints .. " waypoints unless individually set to something else.")
						end

						conn:execute("UPDATE server SET maxWaypoints = " .. tmp.maxWaypoints)
						conn:execute("UPDATE players SET maxWaypoints = " .. tmp.maxWaypoints)
						server.maxWaypoints = tmp.maxWaypoints

						for k,v in pairs(players) do
							v.maxWaypoints = tmp.maxWaypoints
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There was something wrong with your command, a typo?[-]")
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Valid options are..[-]")
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set max waypoints {number}[-]")
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set max waypoints {player name} number {number}[-]")
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set max waypoints donors {number}[-]")
						else
							irc_chat(chatvars.ircAlias, "There was something wrong with your command, a typo?")
							irc_chat(chatvars.ircAlias, ".")
							irc_chat(chatvars.ircAlias, "Valid options are..")
							irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set max waypoints {number}")
							irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set max waypoints {player name} number {number}")
							irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set max waypoints donors {number}")
						end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetWaypoint()
		local allowed, id

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set wp {waypoint name}"
			help[2] = "Create or move your first waypoint where you are standing.  It retains its current status if it already exists."

			tmp.command = help[1]
			tmp.keywords = "waypoints,set,wp"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "set" and (string.find(chatvars.words[2], "wayp") or chatvars.words[2] == "wp")) then
			if not chatvars.settings.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

			-- check the setWPCooldown
			if not chatvars.isAdmin then
				if (players[chatvars.playerid].setWPCooldown - os.time() > 0) then
					if players[chatvars.playerid].setWPCooldown - os.time() < 3600 then
						delay = os.date("%M minutes %S seconds",players[chatvars.playerid].setWPCooldown - os.time())
					else
						delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].setWPCooldown - os.time())
					end

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have to wait " .. delay .. " before you can set another waypoint.[-]")
					botman.faultyChat = false
					return true
				end
			end

			allowed, id = canSetWaypointHere(chatvars.playerid, chatvars.intX, chatvars.intZ)

			if not allowed and (not chatvars.isAdminHidden or not botman.ignoreAdmins) then
				irc_chat(server.ircWatch, players[chatvars.playerid].name .. " set waypoint blocked by " .. id)
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not allowed to set your waypoint here.[-]")
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
				-- reload the player's waypoints into the Lua table waypoints
				waypoints[tmp.id].x = chatvars.intX
				waypoints[tmp.id].y = chatvars.intY
				waypoints[tmp.id].z = chatvars.intZ

				conn:execute("update waypoints set x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. " where id = " .. tmp.id)
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have updated a waypoint.  You can teleport to it with " .. server.commandPrefix .. "wp " .. tmp.name .. "[-]")
			else
				-- check that they haven't already reached
				cursor,errorString = conn:execute("select count(id) as totalWaypoints from waypoints where steam = '" .. chatvars.playerid .. "'")
				row = cursor:fetch({}, "a")

				if tonumber(row.totalWaypoints) >= tonumber(chatvars.settings.maxWaypoints) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have reached your limit of " .. chatvars.settings.maxWaypoints .. " waypoints.  To set this waypoint, you must modify an existing waypoint or clear one first.[-]")
					botman.faultyChat = false
					return true
				end

				-- allow if sufficient zennies
				if tonumber(chatvars.settings.waypointCreateCost) > 0 and (not chatvars.isAdmin) then
					if tonumber(players[chatvars.playerid].cash) < tonumber(chatvars.settings.waypointCreateCost) then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. ".  You require " .. chatvars.settings.waypointCreateCost .. ".  Kill some zombies, gamble, trade or beg to earn more.[-]")
						botman.faultyChat = false
						return true
					end
				end

				conn:execute("insert into waypoints (steam, name, x, y, z) values ('" .. chatvars.playerid .. "','" .. escape(tmp.name) .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You created a waypoint.  You can teleport to it with " .. server.commandPrefix .. "wp " .. tmp.name .. "[-]")
				players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - chatvars.settings.waypointCreateCost

				-- reload the player's waypoints into the Lua table waypoints
				tempTimer( 2, [[loadWaypoints("]] .. chatvars.playerid .. [[")]] )

				if tonumber(chatvars.settings.setWPCooldown) > 0 then
					players[chatvars.playerid].setWPCooldown = os.time() + chatvars.settings.setWPCooldown
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetWaypointCooldown()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set waypoint cooldown {number} (seconds)"
			help[2] = "Set how long in seconds players must wait between uses of waypoints"

			tmp.command = help[1]
			tmp.keywords = "waypoints,set,timer,cooldown,delay"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") or string.find(chatvars.command, "time") or string.find(chatvars.command, "cool") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and string.find(chatvars.words[2], "way") and chatvars.words[3] == "cooldown" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Don't forget to {#}enable waypoints.[-]")
				else
					irc_chat(chatvars.ircAlias, "Don't forget to {#}enable waypoints.")
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
	end


	local function cmd_SetSetWaypointCooldown()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set set wp cooldown {number} (seconds)"
			help[2] = "Set how long in seconds players must wait between uses of {#}set wp. This hampers abuse of the command to locate hidden bases.\n"
			help[2] = help[2] .. "Note this cooldown is not the waypoint cooldown timer."

			tmp.command = help[1]
			tmp.keywords = "waypoints,set,timer,cooldown,delay"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") or string.find(chatvars.command, "time") or string.find(chatvars.command, "cool") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "set" and (string.find(chatvars.words[3], "way") or chatvars.words[3] == "wp") and chatvars.words[4] == "cooldown" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number then
				server.setWPCooldown = chatvars.number
				conn:execute("UPDATE server SET setWPCooldown = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Set wp now has a cooldown. Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes (" .. chatvars.number .. " seconds) between uses.[-]")

					if not server.allowWaypoints then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Don't forget to {#}enable waypoints.[-]")
					end
				else
					irc_chat(chatvars.ircAlias, "Set wp now has a cooldown. Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes (" .. chatvars.number .. " seconds) between uses.")

					if not server.allowWaypoints then
						irc_chat(chatvars.ircAlias, "Don't forget to {#}enable waypoints.")
					end
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Number expected.[-]")
				else
					irc_chat(chatvars.ircAlias, "Number expected.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetWaypointCost()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set waypoint cost {number}"
			help[2] = "Set a price to use waypoints.  Players must have sufficient " .. server.moneyPlural .. " to teleport."

			tmp.command = help[1]
			tmp.keywords = "waypoints,cost,set"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") or string.find(chatvars.command, "cost") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and string.find(chatvars.words[2], "way") and chatvars.words[3] == "cost" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Don't forget to {#}enable waypoints.[-]")
				else
					irc_chat(chatvars.ircAlias, "Don't forget to {#}enable waypoints.")
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
	end


	local function cmd_SetWaypointCreateCost()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set waypoint create cost {number}"
			help[2] = "Set a price to create waypoints.  Players must have sufficient " .. server.moneyPlural

			tmp.command = help[1]
			tmp.keywords = "waypoints,create,cost,set"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") or string.find(chatvars.command, "cost") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and string.find(chatvars.words[2], "way") and chatvars.words[3] == "create" and chatvars.words[4] == "cost" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Don't forget to {#}enable waypoints.[-]")
				else
					irc_chat(chatvars.ircAlias, "Don't forget to {#}enable waypoints.")
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
	end


	local function cmd_UnlinkWaypoints()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}unlink wp {name of waypoint}"
			help[2] = "Close your portal and convert each end back into two waypoints which you can then teleport to as normal."

			tmp.command = help[1]
			tmp.keywords = "waypoints,unlink,portal"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "unlink") then
			if not chatvars.settings.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.wp1 = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[2]))
			tmp.wp1id = LookupWaypointByName(chatvars.playerid, tmp.wp1)

			if tmp.wp1id == "0" then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoint " .. tmp.wp1 .. " not found.[-]")
				botman.faultyChat = false
				return true
			end

			conn:execute("UPDATE waypoints SET linked = 0 WHERE id = " .. tmp.wp1id)
			conn:execute("UPDATE waypoints SET linked = 0 WHERE linked = " .. tmp.wp1id)

			-- reload the player's waypoints into the Lua table waypoints
			tempTimer( 2, [[loadWaypoints()]] )

			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your waypoints have disengaged and you can now use them as waypoints again.[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UseWaypoint()
		local loc, delay

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}wp or {#}wp1 or {#}wp {your named waypoint}\n"
			help[1] = help[1] .. "Or {#}wp bob {bob's shared waypoint}"
			help[2] = "Teleport to one of your waypoints or one of your friend's shared waypoints.\n"
			help[2] = help[2] .. "Examples:\n"
			help[2] = help[2] .. " {#}wp stash (tele to your waypoint called stash)\n"
			help[2] = help[2] .. " {#}wp bob pit (tele to bob's waypoint called pit)"

			tmp.command = help[1]
			tmp.keywords = "waypoints,wp"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "way") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "waypoint" or chatvars.words[1] == "wp") then
			-- reject if not an admin and player teleporting has been disabled
			if (not chatvars.isAdminHidden) and not chatvars.settings.allowTeleporting then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Teleporting has been disabled on this server.[-]")
				botman.faultyChat = false
				result = true
				return true
			end

			if not chatvars.settings.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

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

				if tmp.friend ~= "0" then
					-- check that using a friend's waypoint is allowed
					if not chatvars.settings.allowPlayerToPlayerTeleporting then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are only allowed to use your own waypoints.[-]")
						botman.faultyChat = false
						return true
					end

					tmp.id = LookupWaypointByName(chatvars.playerid, tmp.name, tmp.friend)
				end
			else
				tmp.id = LookupWaypointByName(chatvars.playerid, tmp.name)
			end

			if tonumber(tmp.id) > 0 then
				-- check the waypointCooldown
				if not chatvars.isAdmin then
					if (players[chatvars.playerid].waypointCooldown - os.time() > 0) then
						if players[chatvars.playerid].waypointCooldown - os.time() < 3600 then
							delay = os.date("%M minutes %S seconds",players[chatvars.playerid].waypointCooldown - os.time())
						else
							delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].waypointCooldown - os.time())
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have to wait " .. delay .. " before you can use another waypoint.[-]")
						botman.faultyChat = false
						return true
					end
				end

				-- reject if not an admin and pvpTeleportCooldown is > zero
				if not chatvars.isAdmin and (players[chatvars.playerid].pvpTeleportCooldown - os.time() > 0) then
					if players[chatvars.playerid].pvpTeleportCooldown - os.time() < 3600 then
						delay = os.date("%M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())
					else
						delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())
					end

					message(string.format("pm %s [%s]You must wait %s before you are allowed to teleport again.", chatvars.userID, server.chatColour, delay))
					botman.faultyChat = false
					result = true
					return true
				end

				-- check the waypoint destination in restricted area
				if not chatvars.isAdminHidden then
					if not isDestinationAllowed(chatvars.playerid, waypoints[tmp.id].x, waypoints[tmp.id].z) then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Sorry, your waypoint is in a restricted area.[-]")
						botman.faultyChat = false
						return true
					end

					-- we need to do a separate test for locations that don't allow waypoints as the function we used above is shared by other code
					loc = inLocation(waypoints[tmp.id].x, waypoints[tmp.id].z)

					if loc then
						if not locations[loc].allowWaypoints then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Sorry, your waypoint is in a restricted area.[-]")
							botman.faultyChat = false
							return true
						end
					end
				end

				-- teleport if sufficient zennies
				if tonumber(chatvars.settings.waypointCost) > 0 and (not chatvars.isAdmin) then
					if tonumber(players[chatvars.playerid].cash) < tonumber(chatvars.settings.waypointCost) then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. ".  You require " .. chatvars.settings.waypointCost .. ".  Kill some zombies, gamble, trade or beg to earn more.[-]")
						botman.faultyChat = false
						return true
					end
				end

				if (os.time() - igplayers[chatvars.playerid].lastTPTimestamp < 5) and (not chatvars.isAdmin) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Teleport is recharging.  Wait a few seconds.  You can repeat your last command by typing " .. server.commandPrefix .."[-]")
					botman.faultyChat = false
					return true
				end

				-- store the current coords
				players[chatvars.playerid].xPosOld = chatvars.intX
				players[chatvars.playerid].yPosOld = chatvars.intY
				players[chatvars.playerid].zPosOld = chatvars.intZ
				igplayers[chatvars.playerid].lastLocation = ""

				-- tp the player to the waypointwaypoint
				cmd = "tele " .. chatvars.userID .. " " .. waypoints[tmp.id].x .. " " .. waypoints[tmp.id].y .. " " .. waypoints[tmp.id].z

				players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - chatvars.settings.waypointCost

				if tonumber(chatvars.settings.waypointCooldown) > 0 then
					players[chatvars.playerid].waypointCooldown = os.time() + chatvars.settings.waypointCooldown
				end

				if tonumber(chatvars.settings.playerTeleportDelay) == 0 or chatvars.isAdmin then
					teleport(cmd, chatvars.playerid, chatvars.userID)
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You will be teleported to waypoint " .. waypoints[tmp.id].name .. " in " .. chatvars.settings.playerTeleportDelay .. " seconds.[-]")
					if botman.dbConnected then connSQL:execute("insert into persistentQueue (steam, command, timerDelay) values ('" .. chatvars.playerid .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + chatvars.settings.playerTeleportDelay .. "')") end
					botman.persistentQueueEmpty = false
					igplayers[chatvars.playerid].lastTPTimestamp = os.time() -- this won't really stop additional tp commands stacking but it will slow the player down a little.
				end
			else
				if tmp.friend ~= "0" then
					if not isFriend(tmp.friend, chatvars.playerid) then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.friend].name .. " is not friends with you so you can't visit their waypoints.[-]")
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.friend].name .. " does not have a waypoint called " .. tmp.name .. ".[-]")
					end
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There is no waypoint called " .. tmp.name .. ".[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		if debug then dbug("Registering help - waypoint commands") end

		tmp.topicDescription = "Waypoints are player managed personal teleports.\n"
		tmp.topicDescription = tmp.topicDescription .. "You can specify how many waypoints individuals or groups of players can have and apply other restrictions on their use.\n"
		tmp.topicDescription = tmp.topicDescription .. "Pairs of waypoints can be linked to create a portal.  Portals differ in that the player steps into them to activate them.\n"
		tmp.topicDescription = tmp.topicDescription .. "Waypoints can be shared with a players friends and they can step into their portals as well.  Portals can be unlinked which reverts them to waypoints."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Waypoint Commands:")
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, tmp.topicDescription)
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "You can find more information about waypoints in the following guide.")
			irc_chat(chatvars.ircAlias, "https://files.botman.nz/guides/Waypoints_Noobie_Guide.pdf")
			irc_chat(chatvars.ircAlias, ".")
		end

		cursor,errorString = connSQL:execute("SELECT count(*) FROM helpTopics WHERE topic = '" .. tmp.topic .. "'")
		row = cursor:fetch({}, "a")
		rows = row["count(*)"]

		if rows == 0 then
			connSQL:execute("INSERT INTO helpTopics (topic, description) VALUES ('" .. tmp.topic .. "', '" .. connMEM:escape(tmp.topicDescription) .. "')")
		end
	end

	-- reject if not an admin and server is in hardcore mode
	if (not chatvars.isAdminHidden) and chatvars.settings.hardcore then
		botman.faultyChat = false
		return false, ""
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false, ""
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.words[3], "way") then
				botman.faultyChat = false
				return true, ""
			end
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and chatvars.words[1] ~= "help" and not botman.registerHelp then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Waypoint Commands:")
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Waypoints are player managed personal teleports.")
		irc_chat(chatvars.ircAlias, "You can specify how many waypoints individuals or groups of players can have and apply other restrictions on their use.")
		irc_chat(chatvars.ircAlias, "Pairs of waypoints can be linked to create a portal.  Portals differ in that the player steps into them to activate them.")
		irc_chat(chatvars.ircAlias, "Waypoints can be shared with a players friends and they can step into their portals as well.  Portals can be unlinked which reverts them to waypoints.")
		irc_chat(chatvars.ircAlias, ".")
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "waypoints")
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClearAllWaypoints()

	if result then
		if debug then dbug("debug cmd_ClearAllWaypoints triggered") end
		return result, "cmd_ClearAllWaypoints"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListWaypoints()

	if result then
		if debug then dbug("debug cmd_ListWaypoints triggered") end
		return result, "cmd_ListWaypoints"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxWaypoints()

	if result then
		if debug then dbug("debug cmd_SetMaxWaypoints triggered") end
		return result, "cmd_SetMaxWaypoints"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWaypointCooldown()

	if result then
		if debug then dbug("debug cmd_SetWaypointCooldown triggered") end
		return result, "cmd_SetWaypointCooldown"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetSetWaypointCooldown()

	if result then
		if debug then dbug("debug cmd_SetSetWaypointCooldown triggered") end
		return result, "cmd_SetSetWaypointCooldown"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWaypointCost()

	if result then
		if debug then dbug("debug cmd_SetWaypointCost triggered") end
		return result, "cmd_SetWaypointCost"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWaypointCreateCost()

	if result then
		if debug then dbug("debug cmd_SetWaypointCreateCost triggered") end
		return result, "cmd_SetWaypointCreateCost"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleAllowLinkedWaypoints()

	if result then
		if debug then dbug("debug cmd_ToggleAllowLinkedWaypoints triggered") end
		return result, "cmd_ToggleAllowLinkedWaypoints"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleWaypoints()

	if result then
		if debug then dbug("debug cmd_ToggleWaypoints triggered") end
		return result, "cmd_ToggleWaypoints"
	end

	if debug then dbug("debug waypoints end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == "0" and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false, ""
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if chatvars.showHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Waypoint Commands (In-Game Only):")
		irc_chat(chatvars.ircAlias, ".")
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClearWaypoint()

	if result then
		if debug then dbug("debug cmd_ClearWaypoint triggered") end
		return result, "cmd_ClearWaypoint"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_CloseWaypoint()

	if result then
		if debug then dbug("debug cmd_CloseWaypoint triggered") end
		return result, "cmd_CloseWaypoint"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_OpenWaypoint()

	if result then
		if debug then dbug("debug cmd_OpenWaypoint triggered") end
		return result, "cmd_OpenWaypoint"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWaypoint()

	if result then
		if debug then dbug("debug cmd_SetWaypoint triggered") end
		return result, "cmd_SetWaypoint"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_LinkWaypoints()

	if result then
		if debug then dbug("debug cmd_LinkWaypoints triggered") end
		return result, "cmd_LinkWaypoints"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnlinkWaypoints()

	if result then
		if debug then dbug("debug cmd_UnlinkWaypoints triggered") end
		return result, "cmd_UnlinkWaypoints"
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_UseWaypoint()

	if result then
		if debug then dbug("debug cmd_UseWaypoint triggered") end
		return result, "cmd_UseWaypoint"
	end

	if botman.registerHelp then
		if debug then dbug("Waypoint commands help registered") end
	end

	if debug then dbug("debug waypoints end") end

	-- can't touch dis
	if true then
		return result, ""
	end
end
