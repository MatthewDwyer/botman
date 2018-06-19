--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local loc, locationName, locationName, id, pname, status, pvp, result, debug, temp, tmp
local shortHelp = false
local skipHelp = false

debug = false -- should be false unless testing

if botman.debugAll then
	debug = true -- this should be true
end

function gmsg_locations()
	calledFunction = "gmsg_locations"
	result = false
	tmp = {}

-- ################## location command functions ##################

	local function cmd_AddLocation()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location add {name}"
			help[2] = "Create a location where you are standing.  Unless you add random spawns, any player teleporting to the location will arrive at your current position.  If you are not on the ground, make sure the players can survive the landing."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,add,crea,make"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "add") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and chatvars.words[2] == "add") then
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

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "add ") + 4)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if (loc ~= nil) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location already exists.[-]")
				botman.faultyChat = false
				return true
			else
				pvp = pvpZone(chatvars.intX, chatvars.intZ)

				locations[locationName] = {}
				locations[locationName].name = locationName

				conn:execute("INSERT INTO locations (name, x, y, z, owner) VALUES ('" .. escape(locationName) .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. "," .. chatvars.playerid .. ") ON DUPLICATE KEY UPDATE x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. ", owner = " .. chatvars.playerid)
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','location added','Location " .. escape(locationName) .. " added'," .. chatvars.playerid .. ")")
				message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " has created a location called " .. locationName .. "[-]")

				loadLocations(locationName)
				locations[locationName].pvp = pvp
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListCategories()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location categories"
			help[2] = "List the location categories. Only admins see the access level restrictions"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,,cat,list"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "list") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and chatvars.words[2] == "categories" and chatvars.words[3] == nil) then
			if tablelength(locationCategories) == 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There are no location categories.[-]")
			else
				if chatvars.accessLevel < 3 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Category |  Min Access Level | Max Access Level[-]")

					for k, v in pairs(locationCategories) do
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. k .. " min: " .. v.minAccessLevel .. " max: " .. v.maxAccessLevel .. "[-]")
					end
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]These are the location categories..[-]")

					for k, v in pairs(locationCategories) do
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. k .. "[-]")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListLocations()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}locations"
			help[2] = "List the locations and basic info about them."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,list"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "list") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "locations") then
			for k, v in pairs(locations) do
				status = ""

				if not isLocationOpen(k) then
					status = "[CLOSED]"
					v.open = false
				else
					if v.timeOpen ~= v.timeClosed then
						if v.timeClosed == 0 then
							status = status .. "closes midnight"
						else
							status = status .. "closes " .. string.format("%02d", v.timeClosed) .. ":00"
						end

						if v.timeOpen == 0 then
							status = status .. " re-opens midnight"
						else
							status = status .. " re-opens " .. string.format("%02d", v.timeOpen) .. ":00"
						end
					end

					if tonumber(v.dayClosed) > 0 then
						status = status .. " closed on day " .. v.dayClosed
					end

					v.open = true
				end

				if tonumber(v.cost) > 0 and v.currency ~= nil then
					status = status .. " costs: " .. v.cost .. " " .. v.currency
				end

				if not v.public then
					status = status .. " [private]"
				end

				if chatvars.words[2] == nil then
					if v.locationCategory == "" then
						if tonumber(chatvars.accessLevel) < 3 then
							if not v.active then
								status = status .. " [disabled]"
							end

							if status ~= "" then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. " - " .. status .. "[-]")
							else
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. "[-]")
							end
						else
							if v.active and tonumber(chatvars.accessLevel) <= v.accessLevel then
								if status ~= "" then
									message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. " - " .. status .. "[-]")
								else
									message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. "[-]")
								end
							end
						end
					end
				else
					if v.locationCategory == chatvars.words[2] then
						if tonumber(chatvars.accessLevel) < 3 then
							if not v.active then
								status = status .. " [disabled]"
							end

							if status ~= "" then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. " - " .. status .. "[-]")
							else
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. "[-]")
							end
						else
							if v.active and tonumber(chatvars.accessLevel) <= v.accessLevel then
								if status ~= "" then
									message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. " - " .. status .. "[-]")
								else
									message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. "[-]")
								end
							end
						end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Lobby()
		local playerName, isArchived, lobby

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}lobby {player name}"
			help[2] = "If the lobby location exists, send the player to it. You can also do this to offline players, they will be moved to the lobby when they rejoin.\n"
			help[2] = help[2] .. "If location spawn exists and lobby does not, spawn is the lobby location."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,lobby,spawn,tele,tp,start,play,new"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "lobby") or string.find(chatvars.command, "spawn") or string.find(chatvars.command, "player") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "lobby" and chatvars.words[2] ~= nil) then
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
			end

			if not locations["lobby"] and not locations["spawn"] then

			end

			-- use spawn as a substitute for lobby
			if locations["spawn"] then
				lobby = "spawn"
			end

			-- if lobby exists, use it
			if locations["lobby"] then
				lobby = "lobby"
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "lobby ") + 6)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if (id ~= 0) then
				-- if the player is ingame, send them to the lobby otherwise flag it to happen when they rejoin
				if (igplayers[id]) then
					cmd = "tele " .. id .. " " .. locations[lobby].x .. " " .. locations[lobby].y .. " " .. locations[lobby].z
					teleport(cmd, id)

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " has been sent to " .. lobby .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. players[id].name .. " has been sent to " .. lobby .. ".")
					end
				else
					if not isArchived then
						players[id].lobby = true
						conn:execute("UPDATE players set location = '" .. lobby .. "' WHERE steam = " .. id)
					else
						playersArchived[id].lobby = true
						conn:execute("UPDATE playersArchived set location = '" .. lobby .. "' WHERE steam = " .. id)
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " will spawn at " .. lobby .. " next time they connect to the server.[-]")
					else
						irc_chat(chatvars.ircAlias, playerName .. " will spawn at " .. lobby .. " next time they connect to the server.")
					end
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player matched that name.[-]")
				else
					irc_chat(chatvars.ircAlias, "No player matched that name.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LocationClearReset()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location clear reset {location name}"
			help[2] = "Remove the reset zone flag.  Unless otherwise restricted, players will be allowed to place claims and setbase."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,clear,set"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "clear") or string.find(chatvars.command, "set") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and chatvars.words[2] == "clear" and chatvars.words[3] == "reset") then
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
			end

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "reset ") + 6)
			locationName = string.trim(locationName)

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				locations[loc].resetZone = false
				conn:execute("UPDATE locations set resetZone = 0 WHERE name = '" .. escape(locationName) .. "'")

				message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is no longer a reset zone[-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "The location called " .. locationName .. " is no longer a reset zone.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LocationClearSpawnPoints()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} clear"
			help[2] = "Delete all random spawns for the location."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,clear,spawn"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "clear") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and string.find(chatvars.command, "clear") then
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
			end

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "clear") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if loc ~= nil then
				conn:execute("DELETE FROM locationSpawns WHERE location = '" .. escape(loc) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Location " .. locationName .. "'s teleports have been deleted.[-]")
				else
					irc_chat(chatvars.ircAlias, "Location " .. locationName .. "'s teleports have been deleted.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LocationEndsHere()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} ends here"
			help[2] = "Set the size of the location as the difference between your position and the centre of the location. Handy for setting it visually."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,set,end,size"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "size") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and string.find(chatvars.command, "ends here")) then
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

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "end") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if loc ~= nil then
				dist = distancexz(locations[loc].x, locations[loc].z, igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos)
				locations[loc].size = string.format("%d", dist)
				conn:execute("UPDATE locations set size = " .. locations[loc].size .. ", protectSize = " .. locations[loc].size .. " WHERE name = '" .. locationName .. "'")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. loc .. " now spans " .. string.format("%d", dist * 2) .. " meters.[-]")

				if loc == "Prison" then
					server.prisonSize = math.floor(tonumber(locations[loc].size))
					conn:execute("UPDATE server SET prisonSize = " .. math.floor(tonumber(locations[loc].size)))
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LocationInfo()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name}"
			help[2] = "See detailed information about a location including a list of players currently in it."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,view,info"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "view") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location") then
			-- display details about the location

			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			end

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if (loc ~= nil) then
				cursor,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. locationName .."'")
				row = cursor:fetch({}, "a")

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Location: " .. row.name .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Active: " .. dbYN(row.active) .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset Zone: " .. dbYN(row.resetZone) .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Safe Zone: " .. dbYN(row.killZombies) .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Public: " .. dbYN(row.public) .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Allow Bases: " .. dbYN(row.allowBase) .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Allow Waypoints: " .. dbYN(row.allowWaypoints) .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Allow Returns: " .. dbYN(row.allowReturns) .. "[-]")

				if row.miniGame ~= nil then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Mini Game: " .. row.miniGame .. "[-]")
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Village: " .. dbYN(row.village) .. "[-]")

				pname = ""
				if tonumber(row.mayor) > 0 then
					id = row.mayor

					if not players[id] then
						pname = playersArchived[id].name
					else
						pname = players[id].name
					end
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Mayor: " .. pname .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Protected: " .. dbYN(row.protected) .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]PVP: " .. dbYN(row.pvp) .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Access Level: " .. row.accessLevel .. "[-]")

				if row.minimumLevel == row.maximumLevel then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Not player level restricted.[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Minimum player level: " .. row.minimumLevel .. ".[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Maximum player level: " .. row.maximumLevel .. ".[-]")
				end

				pname = ""
				if tonumber(row.owner) > 0 then
					id = row.mayor

					if not players[id] then
						pname = playersArchived[id].name
					else
						pname = players[id].name
					end
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Owner: " .. pname .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Coords: " .. row.x .. " " .. row.y .. " " .. row.z .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Size: " .. row.size * 2 .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Cost: " .. row.cost .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Hidden: " .. dbYN(row.hidden) .. "[-]")

				botman.faultyChat = false
				return true
			end
		end
	end


	local function cmd_LocationRandom()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} random"
			help[2] = "Start setting random spawn points for the location.  The bot uses your position which it samples every 3 seconds or so.  It only records a new coordinate when you have moved more than 2 metres from the last recorded spot.\n"
			help[2] = help[2] .. "Unless you intend players to fall, do not fly or clip through objects while recording.  To stop recording just type stop.\n"
			help[2] = help[2] .. "You can record random spawns anywhere and more than once but remember to type stop after each recording or the bot will continue recording your movement and making spawn points from them.\n"
			help[2] = help[2] .. "The spawns do not have to be inside the location and you can make groups of spawns anywhere in the world for the location."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,set,spawn,rand"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "rand") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and string.find(chatvars.command, "random")) then
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

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "random") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if loc ~= nil then
				igplayers[chatvars.playerid].location = loc
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are now creating spawn points for location " .. loc .. ". DO NOT FLY.[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LocationSetReset()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location set reset {name}"
			help[2] = "Flag the location as a reset zone.  The bot will warn players not to build in it and will block {#}setbase and will remove placed claims of non-staff."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,reset,zone,set"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "set") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and chatvars.words[2] == "set" and chatvars.words[3] == "reset") then
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
			end

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "reset ") + 6)
			locationName = string.trim(locationName)

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				locations[loc].resetZone = true
				conn:execute("UPDATE locations set resetZone = 1 WHERE name = '" .. escape(locationName) .. "'")

				message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now a reset zone[-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "The location called " .. locationName .. " is now a reset zone.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MoveLocation()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location move {name}"
			help[2] = "Move an existing location to where you are standing.  Unless you add random spawns, any player teleporting to the location will arrive at your current position.\n"
			help[2] = help[2] .. "If you are not on the ground, make sure the players can survive the landing.  If there are existing random spawns for the location, moving it will not move them.\n"
			help[2] = help[2] .. "You should clear them and redo them using {#}location {name} clear and {#}location {name} random."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,add,crea,make"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "move") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and chatvars.words[2] == "move") then
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

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "move ") + 5)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if (loc == nil) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				botman.faultyChat = false
				return true
			else
				locations[loc].x = chatvars.intX
				locations[loc].y = chatvars.intY
				locations[loc].z = chatvars.intZ

				conn:execute("INSERT INTO locations (name, x, y, z) VALUES ('" .. escape(locationName) .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ") ON DUPLICATE KEY UPDATE x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ)
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','location moved','Location " .. escape(locationName) .. " moved'," .. chatvars.playerid .. ")")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have moved a location called " .. locationName .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ProtectLocation()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}protect location"
			help[2] = "Tell the bot to protect the location that you are in. It will instruct you what to do and will tell you when the location is protected."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,prot"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "prot") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "protect" and chatvars.words[2] == "location") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			if igplayers[chatvars.playerid].alertLocation ~= "" then
				igplayers[chatvars.playerid].alertLocationExit = igplayers[chatvars.playerid].alertLocation
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Walk out of " .. igplayers[chatvars.playerid].alertLocation .. " and I will do the rest.[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not in a location. Use this command when you have entered the location that you wish to protect.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RemoveLocation()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location remove {name}"
			help[2] = "Delete the location and all of its spawnpoints."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,dele,remov"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "remove") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and chatvars.words[2] == "remove") then
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
			end

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "remove ") + 7)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if locationName == string.lower("prison") and server.gameType ~= "pvp" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The server needs a prison.  PVPs will be temp-banned instead.[-]")
				else
					irc_chat(chatvars.ircAlias, "The server needs a prison.  PVPs will be temp-banned instead.")
				end
			end

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				locations[loc] = nil
				conn:execute("DELETE FROM locationSpawns WHERE location = '" .. escape(locationName) .. "'")
				conn:execute("DELETE FROM locations WHERE name = '" .. escape(locationName) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed a location called " .. locationName .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "You removed a location called " .. locationName)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RenameLocation()
		local oldLocation, newLocation, loc

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {old name} rename {new name}"
			help[2] = "Change an existing location's name to something else."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,name"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "name") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and string.find(chatvars.command, "rename")) then
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
			end

			newLocation = string.sub(chatvars.commandOld, string.find(chatvars.command, "rename ") + 7)
			newLocation = string.trim(newLocation)

			if locations[newLocation] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. newLocation .. " already exists.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. newLocation .. " already exists.")
				end

				botman.faultyChat = false
				return true
			end

			oldLocation = string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "rename") - 2)
			oldLocation = string.trim(oldLocation)
			loc = LookupLocation(oldLocation)

			if not locations[oldLocation] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. oldLocation .. " does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. oldLocation .. " does not exist.")
				end

				botman.faultyChat = false
				return true
			end

			if newLocation == "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New location name required.[-]")
				else
					irc_chat(chatvars.ircAlias, "New location name required.")
				end

				botman.faultyChat = false
				return true
			end

			if loc ~= nil and newLocation ~= "" then
				locations[newLocation] = locations[loc]
				locations[newLocation].name = newLocation
				locations[loc] = nil

				conn:execute("UPDATE locations SET name = '" .. escape(newLocation) .. "' WHERE name = '" .. escape(oldLocation) .. "'")
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. locations[newLocation].x .. "," .. locations[newLocation].y .. "," .. locations[newLocation].z .. ",'" .. botman.serverTime .. "','location change','Location " .. escape(oldLocation) .. " renamed " .. escape(newLocation) .. "'," .. chatvars.playerid .. ")")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have renamed " .. oldLocation .. " to " .. newLocation .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "You have renamed " .. oldLocation .. " to " .. newLocation)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetClearLocationCategory()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} category {category name}\n"
			help[1] = help[1] .. " {#}location {name} clear category"
			help[2] = "Set or clear a category for a location.  If the category doesn't exist it is created."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,set,clear,cat"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "cate") or string.find(chatvars.command, "set") or string.find(chatvars.command, "clear") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and string.find(chatvars.command, " category") and chatvars.words[3] ~= nil) then

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
			end

			tmp = {}

			if not string.find(chatvars.command, " clear") then
				tmp.location = string.trim(string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, " category") - 1))
				tmp.category = string.trim(string.sub(chatvars.commandOld, string.find(chatvars.command, " category ") + 10))

				if tmp.location == "" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Location name required.[-]")
					else
						irc_chat(chatvars.ircAlias, "Location name required.")
					end

					botman.faultyChat = false
					return true
				end

				if tmp.category == "" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Category required.[-]")
					else
						irc_chat(chatvars.ircAlias, "Category required.")
					end

					botman.faultyChat = false
					return true
				end

				tmp.loc = LookupLocation(tmp.location)

				if tmp.loc == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location doesn't exist.[-]")
					else
						irc_chat(chatvars.ircAlias, "That location doesn't exist.")
					end

					botman.faultyChat = false
					return true
				end

				locations[tmp.loc].locationCategory = tmp.category

				conn:execute("UPDATE locations set locationCategory = '" .. escape(tmp.category) .. "' WHERE name = '" .. escape(tmp.loc) .. "'")
				conn:execute("INSERT INTO locationCategories (categoryName, minAccessLevel, maxAccessLevel) VALUES ('" .. escape(tmp.category) .. "',99,0)")

				-- reload location categories from the database
				loadLocationCategories()

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Location " .. tmp.loc .. " has been added to the location category " .. tmp.category .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "Location " .. tmp.loc .. " has been added to the location category " .. tmp.category)
				end
			else
				tmp.location = string.trim(string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, " clear") - 1))

				if tmp.location == "" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Location name required.[-]")
					else
						irc_chat(chatvars.ircAlias, "Location name required.")
					end

					botman.faultyChat = false
					return true
				end

				tmp.loc = LookupLocation(tmp.location)

				if tmp.loc == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location doesn't exist.[-]")
					else
						irc_chat(chatvars.ircAlias, "That location doesn't exist.")
					end

					botman.faultyChat = false
					return true
				end

				locations[tmp.loc].locationCategory = ""
				conn:execute("UPDATE locations set locationCategory = '' WHERE name = '" .. escape(tmp.loc) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Location " .. tmp.loc .. "'s category has been cleared.[-]")
				else
					irc_chat(chatvars.ircAlias, "Location " .. tmp.loc .. "'s category has been cleared.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationAccess()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} access {minimum access level}"
			help[2] = "Set the minimum access level required to teleport to the location."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,set,acc,limit,restr,block,deny,max,leve"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "set") or string.find(chatvars.command, "acce") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" or (chatvars.words[1] == "set" and chatvars.words[2] == "location")) and string.find(chatvars.command, "access") then
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
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "access") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if chatvars.number ~= nil and loc ~= nil then
				locations[loc].accessLevel = math.floor(tonumber(chatvars.number))
				conn:execute("UPDATE locations set accessLevel = " .. math.floor(tonumber(chatvars.number)) .. " WHERE name = '" .. escape(locationName) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. locationName .. " is restricted to players with access level " .. locations[loc].accessLevel .. " and above.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. locationName .. " is restricted to players with access level " .. locations[loc].accessLevel .. " and above.")
				end
			end

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationCloseHour()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} close {0-23}"
			help[2] = "Block and remove players from the location from a set hour."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,close,set,open"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "close") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and string.find(chatvars.command, " close") and chatvars.words[2] ~= "add" and not string.find(chatvars.command, "day closed")) then
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
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "close") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Missing close hour, a number from 0 to 23.[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing close hour, a number from 0 to 23.")
				end

				botman.faultyChat = false
				return true
			end

			if tonumber(chatvars.number) < 0 or tonumber(chatvars.number) > 23 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Close hour outside of range 0 to 23.[-]")
				else
					irc_chat(chatvars.ircAlias, "Close hour outside of range 0 to 23.")
				end

				botman.faultyChat = false
				return true
			end

			locations[loc].timeClosed = chatvars.number
			conn:execute("UPDATE locations SET timeClosed = " .. chatvars.number .. " WHERE name = '" .. escape(loc) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. loc .. " will be closed at " .. locations[loc].timeClosed .. ":00[-]")
			else
				irc_chat(chatvars.ircAlias, loc .. " will be closed at " .. locations[loc].timeClosed .. ":00")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationCoolDownTimer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set location {name} cooldown {number in seconds}"
			help[2] = "After teleporting to the location, players won't be able to teleport back to it until the cooldown timer expires."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,set,cool,time"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "time") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "location" and string.find(chatvars.command, "cooldown") then
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
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "cooldown") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if chatvars.number ~= nil and loc ~= nil then
				locations[loc].coolDownTimer = math.floor(tonumber(chatvars.number))
				conn:execute("UPDATE locations set coolDownTimer = " .. math.floor(tonumber(chatvars.number)) .. " WHERE name = '" .. escape(locationName) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. locationName .. " now has a cooldown timer of " .. locations[loc].coolDownTimer .. " seconds.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. locationName .. " now has a cooldown timer of " .. locations[loc].coolDownTimer .. " seconds.")
				end
			end

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationCost()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} cost {number}"
			help[2] = "Require the player to have {number} " .. server.moneyPlural .. " to teleport there.  The " .. server.moneyPlural .. " are removed from the player afterwards."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,set,game"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "cost") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and string.find(chatvars.command, "cost") then
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
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "cost") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if chatvars.number ~= nil and loc ~= nil then
				locations[loc].cost = math.floor(tonumber(chatvars.number))
	-- TODO:  Look for the word currency and grab what follows it as the item to require an amount (cost) of.
				if locations[loc].currency == nil then
					locations[loc].currency = server.moneyPlural
				end

				conn:execute("UPDATE locations set cost = " .. math.floor(tonumber(chatvars.number)) .. ", currency = '" .. escape(locations[loc].currency) .. "' WHERE name = '" .. escape(locationName) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. locationName .. " requires " .. locations[loc].cost .. " " .. locations[loc].currency .. " to teleport.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. locationName .. " requires " .. locations[loc].cost .. " " .. locations[loc].currency .. " to teleport.")
				end
			end

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationDayClosed()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} day closed {0-7}"
			help[2] = "Block and remove players from the location on a set day. Disable this feature by setting it to 0."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,close,set,open"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "close") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and string.find(chatvars.command, "day closed")) then
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
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "day close") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Missing day, a number from 0 to 7.[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing day, a number from 0 to 7.")
				end

				botman.faultyChat = false
				return true
			end

			chatvars.number = math.abs(chatvars.number)

			locations[loc].dayClosed = chatvars.number
			conn:execute("UPDATE locations SET dayClosed = " .. chatvars.number .. " WHERE name = '" .. escape(loc) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. loc .. " will be closed on day " .. locations[loc].dayClosed .. "[-]")
			else
				irc_chat(chatvars.ircAlias, loc .. " will be closed on day " .. locations[loc].dayClosed)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationMinigame()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} minigame {game type}"
			help[2] = "Flag the location as part of a minigame such as capture the flag.  The minigame is an unfinished idea so this command doesn't do much yet."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,set,game"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "game") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and string.find(chatvars.command, "minigame") then
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
			end

			locationName = chatvars.words[2]
			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				miniGame = string.sub(chatvars.command, string.find(chatvars.command, "minigame") + 9)

				if (miniGame == nil) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You didn't enter a minigame (eg. ctf, contest).[-]")
					else
						irc_chat(chatvars.ircAlias, "You didn't enter a minigame (eg. ctf, contest).")
					end

					botman.faultyChat = false
					return true
				end

				locations[loc].miniGame = miniGame
				conn:execute("UPDATE locations set miniGame = '" .. escape(miniGame) .. "' WHERE name = '" .. escape(loc) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. locationName .. " is the mini-game " .. miniGame .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. locationName .. " is the mini-game " .. miniGame)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationOpenHour()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} open {0-23}"
			help[2] = "Allow players inside the location from a set hour."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,close,set,open"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "open") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and string.find(chatvars.command, " open")) then
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
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "open") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Missing open hour, a number from 0 to 23.[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing open hour, a number from 0 to 23.")
				end

				botman.faultyChat = false
				return true
			end

			if tonumber(chatvars.number) < 0 or tonumber(chatvars.number) > 23 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Open hour outside of range 0 to 23.[-]")
				else
					irc_chat(chatvars.ircAlias, "Open hour outside of range 0 to 23.")
				end

				botman.faultyChat = false
				return true
			end

			locations[loc].timeOpen = chatvars.number
			conn:execute("UPDATE locations SET timeOpen = " .. chatvars.number .. " WHERE name = '" .. escape(loc) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. loc .. " will open at " .. locations[loc].timeOpen .. ":00[-]")
			else
				irc_chat(chatvars.ircAlias, loc .. " will open at " .. locations[loc].timeOpen .. ":00")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationOwner()
		local playerName

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location owner {player name}"
			help[2] = "Assign ownership of a location to a player.  They will be able to set protect on it and players not friended to them won't be able to teleport there."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,set,own,assign"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "own") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "location" and chatvars.words[3] == "owner") then
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
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "owner ") + 6)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player matched that name.[-]")
					else
						irc_chat(chatvars.ircAlias, "No player matched that name.")
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
			end

			loc = string.trim(chatvars.words[2])
			loc = LookupLocation(loc)

			if (loc ~= nil) then
				locations[loc].owner = id
				conn:execute("UPDATE locations set owner = " .. id .. " WHERE name = '" .. escape(loc) .. "'")
				message("say [" .. server.chatColour .. "]" .. playerName .. " is the proud new owner of the location called " .. loc .. "[-]")
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationPlayerLevelRestriction()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} min level {minimum player level}\n"
			help[1] = help[1] .. " {#}location {name} max level {maximum player level}\n"
			help[1] = help[1] .. " {#}location {name} min level {minimum player level} max level {maximum player level}"
			help[2] = "Set a player level requirement to teleport to a location."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,leve,acce"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "lev") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and (string.find(chatvars.command, "min level") or string.find(chatvars.command, "max level")) then
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
			end

			if (not string.find(chatvars.command, "min level") and string.find(chatvars.command, "max level")) then
				tmp.locationName = string.trim(string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "max level") - 2))
			end

			if (string.find(chatvars.command, "min level")) then
				tmp.locationName = string.trim(string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "min level") - 2))
			end

			tmp.loc = LookupLocation(tmp.locationName)

			if tmp.loc ~= nil then
				tmp.minLevel = locations[tmp.loc].minimumLevel
				tmp.maxLevel = locations[tmp.loc].maximumLevel

				if (string.find(chatvars.command, "min level") and not string.find(chatvars.command, "max level")) then
					tmp.minLevel = string.sub(chatvars.command, string.find(chatvars.command, "min level") + 10)
				end

				if (not string.find(chatvars.command, "min level") and string.find(chatvars.command, "max level")) then
					tmp.maxLevel = string.sub(chatvars.command, string.find(chatvars.command, "max level") + 10)
				end

				if (string.find(chatvars.command, "min level") and string.find(chatvars.command, "max level")) then
					tmp.minLevel = string.sub(chatvars.command, string.find(chatvars.command, "min level") + 10, string.find(chatvars.command, "max level") - 2)
					tmp.maxLevel = string.sub(chatvars.command, string.find(chatvars.command, "max level") + 10)
				end

				tmp.minLevel = tonumber(tmp.minLevel)
				tmp.maxLevel = tonumber(tmp.maxLevel)

				-- flip if max < min and max not zero
				if tmp.minLevel > tmp.maxLevel and tmp.maxLevel > 0 then
					temp = tmp.maxLevel
					tmp.maxLevel = tmp.minLevel
					tmp.minLevel = temp
				end

				-- update the levels for the location
				conn:execute("UPDATE locations set minimumLevel = " .. tmp.minLevel .. ", maximumLevel = " .. tmp.maxLevel .. " WHERE name = '" .. escape(tmp.locationName) .. "'")
				locations[tmp.loc].minimumLevel = tmp.minLevel
				locations[tmp.loc].maximumLevel = tmp.maxLevel

				if tmp.minLevel == 0 and tmp.maxLevel == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. tmp.locationName .. " is not restricted by player level.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location " .. tmp.locationName .. " is not restricted by player level.")
					end

					botman.faultyChat = false
					return true
				end

				if tmp.minLevel > 0 then
					if tmp.maxLevel > 0 then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. tmp.locationName .. " is restricted to players with player levels from " .. tmp.minLevel .. " to " .. tmp.maxLevel .. ".[-]")
						else
							irc_chat(chatvars.ircAlias, "The location " .. tmp.locationName .. " is restricted to players with player levels from " .. tmp.minLevel .. " to " .. tmp.maxLevel .. ".")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. tmp.locationName .. " is restricted to players with minimum player level of " .. tmp.minLevel .. " and above.[-]")
						else
							irc_chat(chatvars.ircAlias, "The location " .. tmp.locationName .. " is restricted to players with minimum player level of " .. tmp.minLevel .. " and above.")
						end
					end

					botman.faultyChat = false
					return true
				end

				if tmp.maxLevel > 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. tmp.locationName .. " is restricted to players with a player level below " .. tmp.maxLevel + 1 .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "The location " .. tmp.locationName .. " is restricted to players with a player level below " .. tmp.maxLevel + 1 .. ".")
					end
				end
			end

			if tmp.loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationSize()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} size {number}"
			help[2] = "Set the size of the location measured from its centre.  To make a 200 metre location set it to 100."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,set,size"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "size") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and string.find(chatvars.command, "size") then
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
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "size") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if chatvars.number ~= nil and loc ~= nil then
				locations[locationName].size = math.floor(tonumber(chatvars.number))
				conn:execute("UPDATE locations set size = " .. math.floor(tonumber(chatvars.number)) .. ", protectSize = " .. math.floor(tonumber(chatvars.number)) .. " WHERE name = '" .. escape(locationName) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. locations[loc].name .. " now spans " .. tonumber(chatvars.number * 2) .. " metres.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. locations[loc].name .. " now spans " .. tonumber(chatvars.number * 2) .. " metres.")
				end

				if loc == string.lower("prison") then
					server.prisonSize = math.floor(tonumber(chatvars.number))
					conn:execute("UPDATE server SET prisonSize = " .. math.floor(tonumber(chatvars.number)))
				end
			end

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetTP()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set tp {optional location}"
			help[2] = "Create a single random teleport for the location you are in or if you are recording random teleports, it will set for that location.\n"
			help[2] = help[2] .. "If you provide a location name you will create 1 random TP for that location where you are standing."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,set,spawn,tp,point"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "set") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set" and chatvars.words[2] == "tp") then
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

			if chatvars.words[3] ~= nil then
				locationName = string.sub(chatvars.command, string.find(chatvars.command, " tp ") + 4, string.len(chatvars.command))
				locationName = string.trim(locationName)
				loc = LookupLocation(locationName)

				if locations[chatvars.words[3]] then
					conn:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. chatvars.words[3] .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Random TP added to " .. chatvars.words[3] .. "[-]")

					botman.faultyChat = false
					return true
				end
			end

			if igplayers[chatvars.playerid].location ~= nil then
				conn:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. igplayers[chatvars.playerid].location .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Random TP added to " .. igplayers[chatvars.playerid].location .. "[-]")
			else
				if players[chatvars.playerid].inLocation ~= "" then
					conn:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. players[chatvars.playerid].inLocation .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Random TP added to " .. players[chatvars.playerid].inLocation .. "[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationAllowBase()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location allow base {location name}\n"
			help[1] = help[1] .. " {#}location disallow/deny/block base {location name}"
			help[2] = "Allow players to {#}setbase in the location or block that."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,base,home,allow,enable,block,deny"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "allow") or string.find(chatvars.command, "base") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and (chatvars.words[2] == "allow" or chatvars.words[2] == "disallow") and chatvars.words[3] == "base" then
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
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "base ") + 5)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[2] == "allow" then
					locations[loc].allowBase = true
					conn:execute("UPDATE locations SET allowBase = 1 WHERE name = '" .. escape(locationName) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players may setbase in " .. locationName .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players may setbase in " .. locationName .. ".")
					end
				else
					locations[loc].allowBase = false
					conn:execute("UPDATE locations SET allowBase = 0 WHERE name = '" .. escape(locationName) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players cannot setbase in " .. locationName .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players cannot setbase in " .. locationName .. ".")
					end

				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationEnabled()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location enable/disable {name}"
			help[2] = "Flag the location as enabled or disabled. Currently this flag isn't used and you can ignore this command."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,able,on,off"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "able") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and (chatvars.words[2] == "enable" or chatvars.words[2] == "disable") then
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
			end

			if chatvars.words[2] == "enable" then
				locationName = string.sub(chatvars.command, string.find(chatvars.command, "enable ") + 7)
			else
				locationName = string.sub(chatvars.command, string.find(chatvars.command, "disable ") + 8)
			end

			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[2] == "enable" then
					locations[loc].active = true
					conn:execute("UPDATE locations set active = 1 WHERE name = '" .. escape(locationName) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location called " .. locationName .. " is now enabled.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location called " .. locationName .. " is now enabled.")
					end
				else
					locations[loc].active = false
					conn:execute("UPDATE locations set active = 0 WHERE name = '" .. escape(locationName) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location called " .. locationName .. " is now disabled.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location called " .. locationName .. " is now disabled.")
					end

				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationPrivate()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location private/public {name} (default is private)"
			help[2] = "Flag the location as private or public.  Players can only use public locations."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,priv,pub,set"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "priv") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and (chatvars.words[2] == "private" or chatvars.words[2] == "public") then
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
			end

			if chatvars.words[2] == "private" then
				locationName = string.sub(chatvars.command, string.find(chatvars.command, "private ") + 8)
			else
				locationName = string.sub(chatvars.command, string.find(chatvars.command, "public ") + 7)
			end

			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[2] == "private" then
					locations[loc].public = false
					conn:execute("UPDATE locations set public = 0 WHERE name = '" .. escape(locationName) .. "'")

					message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now private[-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location called " .. locationName .. " is now private.")
					end
				else
					locations[loc].public = true
					conn:execute("UPDATE locations set public = 1 WHERE name = '" .. escape(locationName) .. "'")

					message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now public[-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location called " .. locationName .. " is now public.")
					end

				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationPVP()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} pvp\n"
			help[1] = help[1] .. " {#}location {name} pve"
			help[2] = "Change the rules at a location to pvp or pve."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,pve,pvp,set"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve")) then
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
			end

			locationName = ""
			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, " pv") - 1)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if loc ~= nil then
				if string.find(chatvars.command, "pve") then
					locations[loc].pvp = false
					conn:execute("UPDATE locations set pvp = 0 WHERE name = '" .. escape(locationName) .. "'")
					message("say [" .. server.chatColour .. "]The location " .. locations[loc].name .. " is now a PVE zone.[-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location " .. locations[loc].name .. " is now a PVE zone.")
					end
				else
					locations[loc].pvp = true
					conn:execute("UPDATE locations set pvp = 1 WHERE name = '" .. escape(locationName) .. "'")
					message("say [" .. server.chatColour .. "]The location " .. locations[loc].name .. " is now a PVP zone![-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location " .. locations[loc].name .. " is now a PVP zone.")
					end
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationReturns()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} enable (or disable) returns"
			help[2] = "Enable or disable the return command for a location."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,retu,able"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "able") or string.find(chatvars.command, "return") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and string.find(chatvars.command, "able") and string.find(chatvars.command, "return") then
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

			if string.find(chatvars.command, "disable") then
				temp = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[2]), string.find(chatvars.command, "disable") - 2)
			else
				temp = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[2]), string.find(chatvars.command, "enable") - 2)
			end

			if locations[temp] then
				if string.find(chatvars.command, "disable") then
					locations[temp].allowReturns = false
					conn:execute("UPDATE locations set allowReturns = 0 WHERE name = '" .. escape(temp) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not be able to use returns in " .. locations[temp].name .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players will not be able to use returns in " .. locations[temp].name)
					end
				else
					locations[temp].allowReturns = true
					conn:execute("UPDATE locations set allowReturns = 1 WHERE name = '" .. escape(temp) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can use returns in " .. locations[temp].name .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players can use returns in " .. locations[temp].name)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationSafe()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location safe/unsafe {location name}"
			help[2] = "Flag/unflag the location as a safe zone.  The bot will automatically kill zombies in the location if players are in it.\n"
			help[2] = help[2] .. "To prevent this feature spamming the server it is triggered every 30 seconds. When there are more than 10 players it changes to every minute.\n"
			help[2] = help[2] .. "If you have StompyNZ's Bad Company mod, the bot will instantly despawn zombies that spawn inside the zone. Walk-in zombies are detected as above."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,safe,zone"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "safe") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and (chatvars.words[2] == "safe" or chatvars.words[2] == "unsafe") then
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
			end

			if chatvars.words[2] == "safe" then
				locationName = string.sub(chatvars.command, string.find(chatvars.command, "safe ") + 5)
			else
				locationName = string.sub(chatvars.command, string.find(chatvars.command, "unsafe ") + 7)
			end

			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[2] == "safe" then
					locations[loc].killZombies = true
					server.scanZombies = true
					conn:execute("UPDATE locations set killZombies = 1 WHERE name = '" .. escape(locationName) .. "'")

					message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now a safezone.[-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location called " .. locationName .. " is now a safezone.")
					end
				else
					locations[loc].killZombies = true
					server.scanZombies = true
					conn:execute("UPDATE locations set killZombies = 0 WHERE name = '" .. escape(locationName) .. "'")

					message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is no longer a safezone![-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location called " .. locationName .. " is no longer a safezone.")
					end

				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationWatchPlayers()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} watch\n"
			help[1] = help[1] .. " {#}location {name} stop watching\n"
			help[2] = "Set a location to report player activity regardless of other player watch settings, or not.  The default is to not watch players.\n"
			help[2] = help[2] .. "Use this setting to be alerted whenever a player enters/exits a watched location or their inventory changes while in it."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,watch,play"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "watch") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and (string.find(chatvars.command, "watch") or string.find(chatvars.command, "stop watching")) then
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

			if string.find(chatvars.command, "stop watch") then
				loc = string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, " stop w") - 1)
			else
				loc = string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, " watch") - 1)
			end

			loc = LookupLocation(loc)

			if loc ~= nil then
				if string.find(chatvars.command, "stop watch") then
					locations[loc].watch = false
					conn:execute("UPDATE locations set watchPlayers = 0 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not be watched in location " .. loc .. " unless individually watched.[-]")
					else
						irc_chat(chatvars.ircAlias, "Players not will be watched in location " .. loc .. " unless individually watched")
					end
				else
					locations[loc].watch = true
					conn:execute("UPDATE locations set watchPlayers = 1 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will be watched in location " .. loc .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players will be watched in location " .. loc)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationWaypoints()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} enable (or disable) waypoints"
			help[2] = "Block or allow players to set waypoints in the location."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,wayp,able"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "able") or string.find(chatvars.command, "wayp") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "location" and string.find(chatvars.command, "able") and string.find(chatvars.command, "wayp") then
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

			if string.find(chatvars.command, "disable") then
				temp = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[2]), string.find(chatvars.command, "disable") - 2)
			else
				temp = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[2]), string.find(chatvars.command, "enable") - 2)
			end

			if locations[temp] then
				if string.find(chatvars.command, "disable") then
					locations[temp].allowWaypoints = false
					conn:execute("UPDATE locations set allowWaypoints = 0 WHERE name = '" .. escape(temp) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not be able to set waypoints in " .. locations[temp].name .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players will not be able to set waypoints in " .. locations[temp].name)
					end
				else
					locations[temp].allowWaypoints = true
					conn:execute("UPDATE locations set allowWaypoints = 1 WHERE name = '" .. escape(temp) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can set waypoints in " .. locations[temp].name .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players can set waypoints in " .. locations[temp].name)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleShowLocationEnterExitMessage()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}show/hide locations"
			help[2] = "Normally when you enter and leave a location you will see a private message informing you of this.  You can disable the message."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,show,hide"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "show") or string.find(chatvars.command, "hide") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "show" or chatvars.words[1] == "hide") and chatvars.words[2] == "locations" then
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

			if chatvars.words[1] == "show" then
				server.showLocationMessages = true
				conn:execute("UPDATE server SET showLocationMessages = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will be alerted when they enter or leave locations.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will be alerted when they enter or leave locations.")
				end
			else
				server.showLocationMessages = false
				conn:execute("UPDATE server SET showLocationMessages = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will only see rule changes when they enter or leave locations.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will only see rule changes when they enter or leave locations.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnprotectLocation()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}unprotect location {optional name}"
			help[2] = "Remove bot protection from the location. You can leave out the location name if you are in the location."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "locat,prot"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "prot") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "unprotect" and chatvars.words[2] == "location") then
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
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if loc ~= nil then
				locations[loc].protected = false
				conn:execute("UPDATE locations SET protected = 0 WHERE name = '" .. escape(loc) .. "'")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have disabled protection for " .. loc .. ".[-]")

				botman.faultyChat = false
				return true
			end

			if igplayers[chatvars.playerid].alertLocation ~= "" then
				locations[igplayers[chatvars.playerid].alertLocation].protected = false
				conn:execute("UPDATE locations SET protected = 0 WHERE name = '" .. escape(igplayers[chatvars.playerid].alertLocation) .. "'")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have disabled protection for " .. igplayers[chatvars.playerid].alertLocation .. ".[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not in a location. Use this command when you have entered the location that you wish to remove protection from.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "===== Registering help - location commands ====")
		dbug("Registering help - location commands")

		tmp = {}
		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'locations'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('locations', 'A location is usually a teleport destination. They can be configured for many purposes.')")
		else
			row = cursor:fetch(row, "a")
			tmp.topicID = row.topicID
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.command, "locat") then
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
		irc_chat(chatvars.ircAlias, "Location Commands:")
		irc_chat(chatvars.ircAlias, "==================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "locations")
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddLocation()

	if result then
		if debug then dbug("debug cmd_AddLocation triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListCategories()

	if result then
		if debug then dbug("debug cmd_ListCategories triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListLocations()

	if result then
		if debug then dbug("debug cmd_ListLocations triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_Lobby()

	if result then
		if debug then dbug("debug cmd_Lobby triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationClearReset()

	if result then
		if debug then dbug("debug cmd_LocationClearReset triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationClearSpawnPoints()

	if result then
		if debug then dbug("debug cmd_LocationClearSpawnPoints triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationEndsHere()

	if result then
		if debug then dbug("debug cmd_LocationEndsHere triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationInfo()

	if result then
		if debug then dbug("debug cmd_LocationInfo triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationRandom()

	if result then
		if debug then dbug("debug cmd_LocationRandom triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationSetReset()

	if result then
		if debug then dbug("debug cmd_LocationSetReset triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_MoveLocation()

	if result then
		if debug then dbug("debug cmd_MoveLocation triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ProtectLocation()

	if result then
		if debug then dbug("debug cmd_ProtectLocation triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_RemoveLocation()

	if result then
		if debug then dbug("debug cmd_RemoveLocation triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_RenameLocation()

	if result then
		if debug then dbug("debug cmd_RenameLocation triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetClearLocationCategory()

	if result then
		if debug then dbug("debug cmd_SetClearLocationCategory triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationAccess()

	if result then
		if debug then dbug("debug cmd_SetLocationAccess triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationCloseHour()

	if result then
		if debug then dbug("debug cmd_SetLocationCloseHour triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationCoolDownTimer()

	if result then
		if debug then dbug("debug cmd_SetLocationCoolDownTimer triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationCost()

	if result then
		if debug then dbug("debug cmd_SetLocationCost triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationDayClosed()

	if result then
		if debug then dbug("debug cmd_SetLocationDayClosed triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationMinigame()

	if result then
		if debug then dbug("debug cmd_SetLocationMinigame triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationOpenHour()

	if result then
		if debug then dbug("debug cmd_SetLocationOpenHour triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationOwner()

	if result then
		if debug then dbug("debug cmd_SetLocationOwner triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationPlayerLevelRestriction()

	if result then
		if debug then dbug("debug cmd_SetLocationPlayerLevelRestriction triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationSize()

	if result then
		if debug then dbug("debug cmd_SetLocationSize triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetTP()

	if result then
		if debug then dbug("debug cmd_SetTP triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationAllowBase()

	if result then
		if debug then dbug("debug cmd_ToggleLocationAllowBase triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationEnabled()

	if result then
		if debug then dbug("debug cmd_ToggleLocationEnabled triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationPrivate()

	if result then
		if debug then dbug("debug cmd_ToggleLocationPrivate triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationPVP()

	if result then
		if debug then dbug("debug cmd_ToggleLocationPVP triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationReturns()

	if result then
		if debug then dbug("debug cmd_ToggleLocationReturns triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationSafe()

	if result then
		if debug then dbug("debug cmd_ToggleLocationSafe triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationWatchPlayers()

	if result then
		if debug then dbug("debug cmd_ToggleLocationWatchPlayers triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationWaypoints()

	if result then
		if debug then dbug("debug cmd_ToggleLocationWaypoints triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleShowLocationEnterExitMessage()

	if result then
		if debug then dbug("debug cmd_ToggleShowLocationEnterExitMessage triggered") end
		return result
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnprotectLocation()

	if result then
		if debug then dbug("debug cmd_UnprotectLocation triggered") end
		return result
	end

	if debug then dbug("debug locations end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == 0 and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	-- look for command in locations table

	-- if a location called spawn exists and lobby does not, substitute lobby with spawn
	if chatvars.words[1] == "spawn" then
		if locations["lobby"] and not locations["spawn"] then
			chatvars.command = "lobby"
		end
	end

	-- if a location called lobby exists and spawn does not, substitute spawn with lobby
	if chatvars.words[1] == "lobby" then
		if locations["spawn"] and not locations["lobby"] then
			chatvars.command = "spawn"
		end
	end

	loc = LookupLocation(chatvars.command)

	if (loc ~= nil) then
		-- reject if not an admin and server is in hardcore mode
		if isServerHardcore(chatvars.playerid) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is disabled.[-]")
			botman.faultyChat = false
			return true
		end

		if (players[chatvars.playerid].prisoner or not players[chatvars.playerid].canTeleport or not server.allowTeleporting) and tonumber(chatvars.accessLevel) > 2 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not allowed to use teleports.[-]")
			botman.faultyChat = false
			return true
		end

		if (players[chatvars.playerid].walkies) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not opted in to using teleports. Type " .. server.commandPrefix .. "enabletp to opt-in.[-]")
			botman.faultyChat = false
			return true
		end

		-- reject if not an admin and pvpTeleportCooldown is > zero
		if tonumber(chatvars.accessLevel) > 2 and (players[chatvars.playerid].pvpTeleportCooldown - os.time() > 0) then
			message(string.format("pm %s [%s]You must wait %s before you are allowed to teleport again.", chatvars.playerid, server.chatColour, os.date("%M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())))
			botman.faultyChat = false
			result = true
			return true
		end

		if (os.time() - igplayers[chatvars.playerid].lastTPTimestamp < 5) and (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport is recharging.  Wait a few seconds.  You can repeat your last command by typing " .. server.commandPrefix .."[-]")
			botman.faultyChat = false
			return true
		end

		cursor,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. escape(loc) .."'")
		row = cursor:fetch({}, "a")

		if (locations[loc].village == true) then
 			if villagers[chatvars.playerid .. loc] then
				if (players[chatvars.playerid].baseCooldown - os.time() > 0) and (chatvars.accessLevel > 2 or botman.ignoreAdmins == false) then --  and botman.ignoreAdmins == false
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have to wait " .. os.date("%M minutes %S seconds",players[chatvars.playerid].baseCooldown - os.time()) .. " before you can use " .. server.commandPrefix .. loc .. " again.[-]")
					botman.faultyChat = false
					return true
				else
					if players[chatvars.playerid].donor then
						players[chatvars.playerid].baseCooldown = (os.time() + math.floor(tonumber(server.baseCooldown) / 2))
					else
						players[chatvars.playerid].baseCooldown = (os.time() + server.baseCooldown)
					end

					players[chatvars.playerid].xPosOld = 0
					players[chatvars.playerid].yPosOld = 0
					players[chatvars.playerid].zPosOld = 0
					igplayers[chatvars.playerid].lastLocation = loc

					cursor,errorString = conn:execute("select * from locationSpawns where location='" .. loc .. "'")
					if cursor:numrows() > 0 then
						randomTP(chatvars.playerid, loc)
					else
						cmd = "tele " .. chatvars.playerid .. " " .. locations[loc].x .. " " .. locations[loc].y .. " " .. locations[loc].z
						teleport(cmd, chatvars.playerid)
					end

					botman.faultyChat = false
					return true
				end
			end
		end

		if (row.public == "0" and chatvars.accessLevel > 2) and row.owner ~= chatvars.playerid then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " is private[-]")
			botman.faultyChat = false
			return true
		end

		if (row.active == "0" and chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " is not enabled right now[-]")
			botman.faultyChat = false
			return true
		end

		if not locations[loc].open then
			locations[loc].open = isLocationOpen(loc)

			if locations[loc].open then
				message("say [" .. server.chatColour .. "]The location " .. loc .. " is now open.[-]")
			end
		end

		if not locations[loc].open and chatvars.accessLevel > 2 then
			if locations[loc].timeOpen == 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " is closed. It will re-open at midnight.[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " is closed. It will re-open at " .. locations[loc].timeOpen .. ":00[-]")
			end

			botman.faultyChat = false
			return true
		end

		if (chatvars.accessLevel > tonumber(row.accessLevel) or (locations[loc].newPlayersOnly and not players[chatvars.playerid].newPlayer and chatvars.accessLevel > 2)) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not authorised to visit " .. row.name .. ".[-]")
			botman.faultyChat = false
			return true
		end

		-- reject if not an admin and the location has a cooldown timer and the player's cooldown timer > 0
		if players[chatvars.playerid]["loc_" .. loc] then
			if tonumber(chatvars.accessLevel) > 2 and (players[chatvars.playerid]["loc_" .. loc] - os.time() > 0) then
				message(string.format("pm %s [%s]You must wait %s before you are allowed to teleport to %s again.", chatvars.playerid, server.chatColour, os.date("%M minutes %S seconds",players[chatvars.playerid]["loc_" .. loc] - os.time()), loc))
				botman.faultyChat = false
				result = true
				return true
			end
		end

		-- check player level restrictions on the location
		if (tonumber(row.minimumLevel) > 0 or tonumber(row.maximumLevel) > 0) and chatvars.accessLevel > 2 then
			if tonumber(row.minimumLevel) > 0 and tonumber(players[chatvars.playerid].level) < tonumber(row.minimumLevel) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting to " .. row.name .. " is level restricted. You need to reach level " .. row.minimumLevel .. ".[-]")
				botman.faultyChat = false
				return true
			end

			if tonumber(row.minimumLevel) > 0 and tonumber(row.maximumLevel) > 0 and (tonumber(players[chatvars.playerid].level) < tonumber(row.minimumLevel) or tonumber(players[chatvars.playerid].level) > tonumber(row.maximumLevel)) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting to " .. row.name .. " is level restricted. You can go there when your level is " .. row.minimumLevel .. " to " .. row.maximumLevel .. ".[-]")
				botman.faultyChat = false
				return true
			end

			if tonumber(row.maximumLevel) > 0 and tonumber(players[chatvars.playerid].level) > tonumber(row.maximumLevel) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting to " .. row.name .. " is level restricted and your level is too high.[-]")
				botman.faultyChat = false
				return true
			end
		end

		if tonumber(row.cost) > 0 then
			if string.lower(row.currency) == string.lower(server.moneyPlural) then
				if players[chatvars.playerid].cash < tonumber(row.cost) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. " to travel there.[-]")
					botman.faultyChat = false
					return true
				else
					-- collect payment
					players[chatvars.playerid].cash = players[chatvars.playerid].cash - tonumber(row.cost)
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.cost .. " " .. server.moneyPlural .. " have been deducted for teleporting to " .. row.name .. ".[-]")
				end
			else
				if not inInventory(chatvars.playerid, row.currency, row.cost) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough of the required item to travel there.[-]")
					botman.faultyChat = false
					return true
				end
			end
		end

		if tonumber(chatvars.intY) > -1 then
			if igplayers[chatvars.playerid].lastLocation ~= loc then
				savePosition(chatvars.playerid)
				igplayers[chatvars.playerid].lastLocation = loc
			else
				savePosition(chatvars.playerid, 2)
			end
		end

		cursor,errorString = conn:execute("select * from locationSpawns where location='" .. escape(loc) .. "'")
		if cursor:numrows() > 0 then
			randomTP(chatvars.playerid, loc)

			if server.announceTeleports then
				if tonumber(chatvars.accessLevel) > 2 then message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " is porting to " .. loc .. "[-]") end
			end
		else
			if tonumber(locations[loc].coolDownTimer) > 0 then
				players[chatvars.playerid]["loc_" .. loc] = os.time() + locations[loc].coolDownTimer
			end

			cmd = "tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z

			if tonumber(server.playerTeleportDelay) == 0 or tonumber(players[chatvars.playerid].accessLevel) < 2 then --  or not igplayers[chatvars.playerid].currentLocationPVP
				teleport(cmd, chatvars.playerid)
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will be teleported to " .. loc .. " in " .. server.playerTeleportDelay .. " seconds.[-]")
				if botman.dbConnected then conn:execute("insert into miscQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
			end

			if server.announceTeleports then
				if tonumber(chatvars.accessLevel) > 2 then message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " is porting to " .. loc .. "[-]") end
			end
		end

		botman.faultyChat = false
		return true
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Location commands help registered ****")
		dbug("Location commands help registered")
		topicID = topicID + 1
	end

	if debug then dbug("debug locations end") end

	-- can't touch dis
	if true then
		return result
	end
end

