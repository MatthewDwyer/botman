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

debug = false -- should be false unless testing

function activateWaypointTunnel()
	message("pm " .. tmp.steam .. " [" .. server.chatColour .. "]Chevron Seven is LOCKED![-]")
	conn:execute("UPDATE waypoints SET linked = " .. tmp.wp1id .. " WHERE id = " .. tmp.wp2id)
	conn:execute("UPDATE waypoints SET linked = " .. tmp.wp2id .. " WHERE id = " .. tmp.wp1id)
	loadWaypoints(tmp.steam)
end


function gmsg_waypoints()
	calledFunction = "gmsg_waypoints"
	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## waypoint command functions ##################

	local function cmd_ClearAllWaypoints()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}clear all waypoints {optional player name}"
			help[2] = "Delete all your waypoints (anyone can do this) or those of a named player (only admins)"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,clear,all,dele,remov"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way") or string.find(chatvars.command, "clear")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "clear" and chatvars.words[2] == "all" and string.find(chatvars.words[3], "wayp") then
			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.words[4]) and (chatvars.accessLevel > 3) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only admins can clear a named player's waypoints.  Just type " .. server.commandPrefix .. "clear waypoints[-]")
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

				if not (pid == 0) then
					conn:execute("DELETE FROM waypoints WHERE steam = " .. pid)

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have deleted all of " .. players[pid].name .. "'s waypoints.[-]")
					else
						irc_chat(chatvars.ircAlias, "You have deleted all of " .. players[pid].name .. "'s waypoints.")
					end

					-- reload the player's waypoints
					loadWaypoints(pid)
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found called " .. pname)
					end
				end

				botman.faultyChat = false
				return true
			else
				if (chatvars.playername ~= "Server") then
					conn:execute("DELETE FROM waypoints WHERE steam = " .. chatvars.playerid)
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have deleted all of your waypoints.[-]")

					-- reload the player's waypoints
					loadWaypoints(chatvars.playerid)
				else
					conn:execute("DELETE FROM waypoints WHERE steam = " .. chatvars.ircid)
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}clear wp {name}"
			help[2] = "Delete a named waypoint.  If they are linked, this also unlinks them."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,clear,dele,remov"
				tmp.accessLevel = 10
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "clear" and (chatvars.words[2] == "wp" or string.find(chatvars.words[2], "way"))) then
			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

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
	end


	local function cmd_CloseWaypoint()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}close wp {waypoint name}"
			help[2] = "Make a waypoint private again. This is its default state."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,close,priv,publ"
				tmp.accessLevel = 10
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "close" or chatvars.words[1] == "unshare") and (string.find(chatvars.words[2], "wayp") or chatvars.words[2] == "wp") then
			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

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
	end


	local function cmd_LinkWaypoints()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}link wp {name of wp1} to {name of wp2}"
			help[2] = "Link your waypoints to create a portal instead.  In this mode you cannot teleport to them, instead you activate them by stepping into them."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,link,join,portal"
				tmp.accessLevel = 10
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "link") then
			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

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
	end


	local function cmd_ListWaypoints()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}waypoints {player name} (list a player's waypoints)\n"
			help[1] = help[1] .. " {#}waypoints range {distance} (list all waypoints within range of your position)\n"
			help[1] = help[1] .. " {#}waypoints near {player or location} range {distance} (list all waypoints within range of a player or location)"
			help[2] = "List the waypoints of a player or within {distance} of your current position or the location of another player or location."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,list"
				tmp.accessLevel = 10
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "waypoints" or (chatvars.words[1] == "list" and chatvars.words[2] == "waypoints") then
			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
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

				if tmp.steam == 0 then
					tmp.steam = LookupArchivedPlayer(tmp.pname)

					if not (tmp.steam == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end
				end

				if (tmp.steam == 0) then
					-- look for a location instead
					if chatvars.accessLevel < 3 then
						tmp.location = LookupLocation(tmp.name)

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player or location found called " .. tmp.name .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player or location found called " .. tmp.name)
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. tmp.name .. "[-]")
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
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can only view your friends waypoints or your own waypoints.[-]")
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

			if (tmp.steam ~= 0 and tmp.range == 0) then
				cursor,errorString = conn:execute("select * from waypoints where steam = " .. tmp.steam)
				row = cursor:fetch({}, "a")

				if row then
					if tmp.steam == chatvars.playerid then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your waypoints:[-]")
						else
							irc_chat(chatvars.ircAlias, "Your waypoints:")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. "'s waypoints:[-]")
						else
							irc_chat(chatvars.ircAlias, players[tmp.steam].name .. "'s waypoints:")
						end
					end
				else
					if tmp.steam == chatvars.playerid then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no waypoints.[-]")
						else
							irc_chat(chatvars.ircAlias, "You have no waypoints.")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. " has no waypoints.[-]")
						else
							irc_chat(chatvars.ircAlias, players[tmp.steam].name .. " has no waypoints.")
						end
					end
				end
			end

			if (tmp.steam ~= 0 and tmp.range ~= 0) then
				cursor,errorString = conn:execute("select * from waypoints where steam = " .. tmp.steam)
				row = cursor:fetch({}, "a")

				if row then
					if tmp.steam == chatvars.playerid then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints within " .. tmp.range .. " metres:[-]")
						else
							irc_chat(chatvars.ircAlias, "Waypoints within " .. tmp.range .. " metres:")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints within " .. tmp.range .. " metres of " .. players[tmp.steam].name .. ":[-]")
						else
							irc_chat(chatvars.ircAlias, "Waypoints within " .. tmp.range .. " metres of " .. players[tmp.steam].name .. ":")
						end
					end
				else
					if tmp.steam == chatvars.playerid then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No waypoints found.[-]")
						else
							irc_chat(chatvars.ircAlias, "No waypoints found.")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No waypoints found near " .. players[tmp.steam].name .. ".[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints within " .. tmp.range .. " metres of " .. tmp.location .. ":[-]")
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
							tmp.linked = " linked to " .. waypoints[tonumber(row.linked)].name .. "."
						else
							tmp.linked = ""
						end

						if chatvars.accessLevel > 2 and (tmp.shared == " shared " or chatvars.playerid == row.steam) then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked .. "[-]")
							else
								irc_chat(chatvars.ircAlias, row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked)
							end
						end

						if chatvars.accessLevel < 3 then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked .. "[-]")
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
						tmp.linked = " linked to " .. waypoints[tonumber(row.linked)].name .. "."
					else
						tmp.linked = ""
					end

					if chatvars.accessLevel > 2 and (tmp.shared == " shared " or chatvars.playerid == row.steam) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked .. "[-]")
						else
							irc_chat(chatvars.ircAlias, row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked)
						end
					end

					if chatvars.accessLevel < 3 then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. tmp.shared .. tmp.linked .. "[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}open wp {waypoint name}"
			help[2] = "Share a waypoint with your friends."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,open,share,friend"
				tmp.accessLevel = 10
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "open" or chatvars.words[1] == "share") and (string.find(chatvars.words[2], "wayp") or chatvars.words[2] == "wp") then
			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your friends can now teleport to your waypoint by typing " .. server.commandPrefix .. "wp " .. players[chatvars.playerid].name .. " " .. waypoints[tmp.id].name .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxWaypoints()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set max waypoints {number} (server wide)\n"
			help[1] = help[1] .. " {#}set max waypoints {player name} number {number} (for a specific player)\n"
			help[1] = help[1] .. " {#}set max waypoints donors {number} (for donors)"
			help[2] = "Set the max number of waypoints players can have or a specific player can have."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,set,max,donor"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

			tmp = {}

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "A number is required.")
				end

				botman.faultyChat = false
				return true
			end

			if string.find(chatvars.command, " number ") then
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "waypoints ") + 10, string.find(chatvars.command, " number") - 1)
				tmp.pname = stripQuotes(tmp.pname)
				tmp.id = LookupPlayer(tmp.pname)

				if tmp.id == 0 then
					tmp.id = LookupArchivedPlayer(tmp.pname)

					if not (tmp.id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end
				end

				if tmp.id ~= 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[tmp.id].name .. " can set " .. chatvars.number .. " waypoints.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. players[tmp.id].name .. " can set " .. chatvars.number .. " waypoints.")
					end

					conn:execute("UPDATE players SET maxWaypoints = " .. chatvars.number .. " where steam = " .. tmp.id)
					players[tmp.id].maxWaypoints = chatvars.number
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No matching player name found.[-]")
					else
						irc_chat(chatvars.ircAlias, "No matching player name found.")
					end
				end
			else
				if string.find(chatvars.command, " donors ") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Donors can set a maximum of " .. chatvars.number .. " waypoints unless individually set to something else.[-]")
					else
						irc_chat(chatvars.ircAlias, "Donors can set a maximum of " .. chatvars.number .. " waypoints unless individually set to something else.")
					end

					for k,v in pairs(players) do
						if v.donor then
							v.maxWaypoints = chatvars.number
							conn:execute("UPDATE players SET maxWaypoints = " .. chatvars.number .. " where steam = " .. k)
						end
					end

					server.maxWaypointsDonors = chatvars.number
					conn:execute("UPDATE server SET maxWaypointsDonors = " .. chatvars.number)
				else
					if chatvars.words[5] == nil then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can set a maximum of " .. chatvars.number .. " waypoints unless individually set to something else.[-]")
						else
							irc_chat(chatvars.ircAlias, "Players can set a maximum of " .. chatvars.number .. " waypoints unless individually set to something else.")
						end

						conn:execute("UPDATE server SET maxWaypoints = " .. chatvars.number)
						conn:execute("UPDATE players SET maxWaypoints = " .. chatvars.number)
						server.maxWaypoints = chatvars.number

						for k,v in pairs(players) do
							v.maxWaypoints = chatvars.number
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There was something wrong with your command, a typo?[-]")
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid options are..[-]")
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set max waypoints {number}[-]")
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set max waypoints {player name} number {number}[-]")
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set max waypoints donors {number}[-]")
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

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set wp {waypoint name}"
			help[2] = "Create or move your first waypoint where you are standing.  It retains its current status if it already exists."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,set"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set" and (string.find(chatvars.words[2], "wayp") or chatvars.words[2] == "wp")) then
			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.accessLevel > 10) and not server.waypointsPublic then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
				botman.faultyChat = false
				return true
			end

			allowed, id = canSetWaypointHere(chatvars.playerid, chatvars.intX, chatvars.intZ)

			if not allowed and (chatvars.accessLevel > 2 or not botman.ignoreAdmins) then
				irc_chat(server.ircWatch, players[chatvars.playerid].name .. " set waypoint blocked by " .. id)
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not allowed to set your waypoint here.[-]")
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
	end


	local function cmd_SetWaypointCooldown()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set waypoint cooldown {number} (seconds)"
			help[2] = "Set how long in seconds players must wait between uses of waypoints"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,set,time,cool"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way") or string.find(chatvars.command, "time") or string.find(chatvars.command, "cool")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
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


	local function cmd_SetWaypointCost()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set waypoint cost {number}"
			help[2] = "Set a price to use waypoints.  Players must have sufficient " .. server.moneyPlural .. " to teleport."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,cost,set"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way") or string.find(chatvars.command, "cost")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set waypoint create cost {number}"
			help[2] = "Set a price to create waypoints.  Players must have sufficient " .. server.moneyPlural

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,cost,set"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way") or string.find(chatvars.command, "cost")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
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


	local function cmd_SetWaypointsPublic()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set waypoints public/private"
			help[2] = "Make waypoints accessible to all (except new players) or restricted to donors only."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,set,publ,priv"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[3] == "public" then
				server.waypointsPublic = true
				conn:execute("UPDATE server SET waypointsPublic = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Everyone except new players can set and share waypoints.[-]")
				else
					irc_chat(chatvars.ircAlias, "Everyone except new players can set and share waypoints.")
				end
			else
				server.waypointsPublic = false
				conn:execute("UPDATE server SET waypointsPublic = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are restricted to donors only.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are restricted to donors only.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnlinkWaypoints()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}unlink wp {name of waypoint}"
			help[2] = "Close your portal and convert each end back into two waypoints which you can then teleport to as normal."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp,link,portal"
				tmp.accessLevel = 10
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "unlink") then
			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
				else
					irc_chat(chatvars.ircAlias, "Waypoints are disabled on this server.")
				end

				botman.faultyChat = false
				return true
			end

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
	end


	local function cmd_UseWaypoint()
		local loc

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}wp or {#}wp1 or {#}{your name}"
			help[2] = "Teleport to your first waypoint."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "wayp"
				tmp.accessLevel = 10
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "way")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "waypoint" or chatvars.words[1] == "wp") then
			-- reject if not an admin and player teleporting has been disabled
			if (chatvars.accessLevel > 2) and not server.allowTeleporting then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting has been disabled on this server.[-]")
				botman.faultyChat = false
				result = true
				return true
			end

			if (chatvars.accessLevel > 10) and not server.waypointsPublic then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
				botman.faultyChat = false
				return true
			end

			if not server.allowWaypoints then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled on this server.[-]")
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

				if tmp.friend ~= 0 then
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
					return true
				end

				-- check the waypoint destination in restricted area
				if (chatvars.accessLevel > 3) then
					if not isDestinationAllowed(chatvars.playerid, waypoints[tmp.id].x, waypoints[tmp.id].z) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry, your waypoint is in a restricted area.[-]")
						botman.faultyChat = false
						return true
					end

					-- we need to do a separate test for locations that don't allow waypoints as the function we used above is shared by other code
					loc = inLocation(waypoints[tmp.id].x, waypoints[tmp.id].z)

					if loc then
						if not locations[loc].allowWaypoints then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry, your waypoint is in a restricted area.[-]")
							botman.faultyChat = false
							return true
						end
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

				if (os.time() - igplayers[chatvars.playerid].lastTPTimestamp < 5) and (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport is recharging.  Wait a few seconds.  You can repeat your last command by typing " .. server.commandPrefix .."[-]")
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
					if players[chatvars.playerid].donor then
						players[chatvars.playerid].waypointCooldown = os.time() + math.floor(server.waypointCooldown / 2)
					else
						players[chatvars.playerid].waypointCooldown = os.time() + server.waypointCooldown
					end
				end
			else
				if tmp.friend ~= 0 then
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
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - waypoint commands ====")
		if debug then dbug("Registering help - waypoint commands") end

		tmp = {}
		tmp.topicDescription = "Waypoints are player managed personal teleports.\n"
		tmp.topicDescription = tmp.topicDescription .. "You can specify how many waypoints individuals or groups of players can have and apply other restrictions on their use.\n"
		tmp.topicDescription = tmp.topicDescription .. "Pairs of waypoints can be linked to create a portal.  Portals differ in that the player steps into them to activate them.\n"
		tmp.topicDescription = tmp.topicDescription .. "Waypoints can be shared with a players friends and they can step into their portals as well.  Portals can be unlinked which reverts them to waypoints."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'waypoints'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('waypoints', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	-- reject if not an admin and server is in hardcore mode
	if isServerHardcore(chatvars.playerid) then
		botman.faultyChat = false
		return false
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

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

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Waypoint Commands:")
		irc_chat(chatvars.ircAlias, "==================")
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
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListWaypoints()

	if result then
		if debug then dbug("debug cmd_ListWaypoints triggered") end
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxWaypoints()

	if result then
		if debug then dbug("debug cmd_SetMaxWaypoints triggered") end
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWaypointCooldown()

	if result then
		if debug then dbug("debug cmd_SetWaypointCooldown triggered") end
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWaypointCost()

	if result then
		if debug then dbug("debug cmd_SetWaypointCost triggered") end
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWaypointCreateCost()

	if result then
		if debug then dbug("debug cmd_SetWaypointCreateCost triggered") end
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWaypointsPublic()

	if result then
		if debug then dbug("debug cmd_SetWaypointsPublic triggered") end
		return result
	end

	if debug then dbug("debug waypoints end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == 0 and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Waypoint Commands (In-Game Only):")
		irc_chat(chatvars.ircAlias, "=================================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClearWaypoint()

	if result then
		if debug then dbug("debug cmd_ClearWaypoint triggered") end
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_CloseWaypoint()

	if result then
		if debug then dbug("debug cmd_CloseWaypoint triggered") end
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_OpenWaypoint()

	if result then
		if debug then dbug("debug cmd_OpenWaypoint triggered") end
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWaypoint()

	if result then
		if debug then dbug("debug cmd_SetWaypoint triggered") end
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_LinkWaypoints()

	if result then
		if debug then dbug("debug cmd_LinkWaypoints triggered") end
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnlinkWaypoints()

	if result then
		if debug then dbug("debug cmd_UnlinkWaypoints triggered") end
		return result
	end

	if (debug) then dbug("debug waypoints line " .. debugger.getinfo(1).currentline) end

	result = cmd_UseWaypoint()

	if result then
		if debug then dbug("debug cmd_UseWaypoint triggered") end
		return result
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Waypoint commands help registered ****")
		if debug then dbug("Waypoint commands help registered") end
		topicID = topicID + 1
	end

	if debug then dbug("debug waypoints end") end

	-- can't touch dis
	if true then
		return result
	end
end
