--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_locations()
	local loc, locationName, locationName, steam, steamOwner, userID, pname, status, pvp, result, debug, temp, tmp, k, v, pos, delay, row, cursor, errorString, cmd, rowSQL
	local shortHelp = false

	debug = false -- should be false unless testing

	calledFunction = "gmsg_locations"
	result = false
	tmp = {}
	tmp.topic = "locations"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## location command functions ##################

	local function cmd_AddLocation()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location add {name}"
			help[2] = "Create a location where you are standing.  Unless you add random spawns, any player teleporting to the location will arrive at your current position.  If you are not on the ground, make sure the players can survive the landing."

			tmp.command = help[1]
			tmp.keywords = "location,add,create"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "add") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and chatvars.words[2] == "add") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pos = string.find(chatvars.commandOld, chatvars.wordsOld[3])
			locationName = string.sub(chatvars.commandOld, pos)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if (loc ~= nil) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location already exists.[-]")
				botman.faultyChat = false
				return true
			else
				pvp = pvpZone(chatvars.intX, chatvars.intZ)

				locations[locationName] = {}
				locations[locationName].name = locationName

				conn:execute("INSERT INTO locations (name, x, y, z, owner) VALUES ('" .. escape(locationName) .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. "," .. chatvars.playerid .. ")")
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','location added','Location " .. escape(locationName) .. " added','" .. chatvars.playerid .. "')")
				message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " has created a location called " .. locationName .. "[-]")

				-- if location is spawn or lobby, update all in-game players so they don't automatically get moved to lobby or spawn.  We only want that to happen to new players that haven't already joined.
				loc = string.lower(locationName)

				if (loc == "lobby" or loc == "spawn") then
					for k,v in pairs(igplayers) do
						if players[k].location == loc then
							players[k].location = ""
						end
					end
				end

				loadLocations(locationName)
				locations[locationName].pvp = pvp
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListCategories()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location categories"
			help[2] = "List the location categories. Only admins see the access level restrictions"

			tmp.command = help[1]
			tmp.keywords = "location,category,list"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "list") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and chatvars.words[2] == "categories" and chatvars.words[3] == nil) then
			if tablelength(locationCategories) == 0 then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There are no location categories.[-]")
			else
				if chatvars.isAdminHidden then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Category |  Min Access Level | Max Access Level[-]")

					for k, v in pairs(locationCategories) do
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. k .. " min: " .. v.minAccessLevel .. " max: " .. v.maxAccessLevel .. "[-]")
					end
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]These are the location categories..[-]")

					for k, v in pairs(locationCategories) do
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. k .. "[-]")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListLocations()
		local showLocation, noLocations

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}locations"
			help[2] = "List the locations and basic info about them."

			tmp.command = help[1]
			tmp.keywords = "locations,list"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "list") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "locations") then
			noLocations = true

			for k, v in pairs(locations) do
				noLocations = false
				status = ""

				if v.hidden and not chatvars.isAdminHidden then
					showLocation = false
				else
					showLocation = true
				end

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
						if chatvars.isAdminHidden then
							if not v.active then
								status = status .. " [disabled]"
							end

							if status ~= "" then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. " - " .. status .. "[-]")
							else
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. "[-]")
							end
						else
							if v.active and tonumber(chatvars.accessLevel) <= v.accessLevel and showLocation then
								if status ~= "" then
									message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. " - " .. status .. "[-]")
								else
									message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. "[-]")
								end
							end
						end
					end
				else
					if v.locationCategory == chatvars.words[2] then
						if chatvars.isAdminHidden then
							if not v.active then
								status = status .. " [disabled]"
							end

							if status ~= "" then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. " - " .. status .. "[-]")
							else
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. "[-]")
							end
						else
							if v.active and tonumber(chatvars.accessLevel) <= v.accessLevel and showLocation then
								if status ~= "" then
									message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. " - " .. status .. "[-]")
								else
									message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. "[-]")
								end
							end
						end
					end
				end
			end

			if noLocations then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There are no locations.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Lobby()
		local playerName, isArchived, lobby, k, v, loc

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}lobby {player name}"
			help[2] = "If the lobby location exists, send the player to it. You can also do this to offline players, they will be moved to the lobby when they rejoin.\n"
			help[2] = help[2] .. "If location spawn exists and lobby does not, spawn is the lobby location.\n"
			help[2] = help[2] .. "If a location has been assigned as the lobby and there isn't a location called lobby or spawn, it will be used instead."

			tmp.command = help[1]
			tmp.keywords = "location,lobby,spawn,teleport,tp,start,players,new"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "lobby") or string.find(chatvars.command, "spawn") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "lobby" or chatvars.words[1] == "spawn") and chatvars.words[2] ~= nil and chatvars.words[2] ~= "horde" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			-- use spawn as a substitute for lobby
			lobby = LookupLocation("spawn")

			-- if lobby exists, use it
			loc = LookupLocation("lobby")
			if loc ~= nil then
				lobby = loc
			end

			if not lobby then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Make or set a lobby or spawn location first.[-]")
				else
					irc_chat(chatvars.ircAlias, "Make or set a lobby or spawn location first.")
				end

				botman.faultyChat = false
				return true
			end

			if string.find(chatvars.command, "lobby ") then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "lobby ") + 6)
			end

			if string.find(chatvars.command, "spawn ") then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "spawn ") + 6)
			end

			pname = string.trim(pname)
			steam, steamOwner, userID = LookupPlayer(pname)

			if steam == "0" then
				steam, steamOwner, userID = LookupArchivedPlayer(pname)

				if not (steam == "0") then
					playerName = playersArchived[steam].name
					isArchived = true
				end
			else
				playerName = players[steam].name
				isArchived = false
			end

			if (steam ~= "0") then
				-- if the player is ingame, send them to the lobby otherwise flag it to happen when they rejoin
				if (igplayers[steam]) then
					cmd = "tele " .. userID .. " " .. locations[lobby].x .. " " .. locations[lobby].y + 1 .. " " .. locations[lobby].z
					teleport(cmd, steam, userID)

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. players[steam].name .. " has been sent to " .. lobby .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. players[steam].name .. " has been sent to " .. lobby .. ".")
					end
				else
					if not isArchived then
						players[steam].lobby = true
						conn:execute("UPDATE players set location = '" .. lobby .. "' WHERE steam = '" .. steam .. "'")
					else
						playersArchived[steam].lobby = true
						conn:execute("UPDATE playersArchived set location = '" .. lobby .. "' WHERE steam = '" .. steam .. "'")
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. " will spawn at " .. lobby .. " next time they connect to the server.[-]")
					else
						irc_chat(chatvars.ircAlias, playerName .. " will spawn at " .. lobby .. " next time they connect to the server.")
					end
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player matched that name.[-]")
				else
					irc_chat(chatvars.ircAlias, "No player matched that name.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LocationClearReset()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location clear reset {location name}"
			help[2] = "Remove the reset zone flag.  Unless otherwise restricted, players will be allowed to place claims and setbase."

			tmp.command = help[1]
			tmp.keywords = "location,clear,reset,zone"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "clear") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and chatvars.words[2] == "clear" and chatvars.words[3] == "reset") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""

			if chatvars.words[4] then
				locationName = string.sub(chatvars.command, 23)
				locationName = string.trim(locationName)
			end

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				locations[loc].resetZone = false
				conn:execute("UPDATE locations set resetZone = 0 WHERE name = '" .. escape(loc) .. "'")

				message("say [" .. server.chatColour .. "]The location called " .. loc .. " is no longer a reset zone[-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is no longer a reset zone.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LocationClearSpawnPoints()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} clear"
			help[2] = "Delete all random spawns for the location."

			tmp.command = help[1]
			tmp.keywords = "location,clear,spawn,random,teleports"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "clear") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and chatvars.words[chatvars.wordCount] == "clear" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "clear") - 2)
			locationName = string.trim(locationName)

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if loc ~= nil then
				connSQL:execute("DELETE FROM locationSpawns WHERE location = '" .. connMEM:escape(loc) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Location " .. loc .. "'s teleports have been deleted.[-]")
				else
					irc_chat(chatvars.ircAlias, "Location " .. loc .. "'s teleports have been deleted.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LocationEndsHere()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} ends here"
			help[2] = "Set the size of the location as the difference between your position and the centre of the location. Handy for setting it visually."

			tmp.command = help[1]
			tmp.keywords = "location,set,end,size,border,boundary,edge"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "size") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and string.find(chatvars.command, "ends here")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "end") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if loc ~= nil then
				dist = distancexz(locations[loc].x, locations[loc].z, igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos)
				locations[loc].size = string.format("%d", dist)
				conn:execute("UPDATE locations set size = " .. locations[loc].size .. ", protectSize = " .. locations[loc].size .. " WHERE name = '" .. loc .. "'")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. loc .. " now spans " .. string.format("%d", dist * 2) .. " meters.[-]")

				if loc == "Prison" then
					server.prisonSize = math.floor(tonumber(locations[loc].size))
					conn:execute("UPDATE server SET prisonSize = " .. math.floor(tonumber(locations[loc].size)))
				end
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LocationInfo()
		local cursor, errorString, row

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name}"
			help[2] = "See detailed information about a location including a list of players currently in it."

			tmp.command = help[1]
			tmp.keywords = "location,view,information"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "view") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location") then
			-- display details about the location

			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.command, 11)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if (loc ~= nil) then
				cursor,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. loc .."'")
				row = cursor:fetch({}, "a")

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Location: " .. row.name .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Active: " .. dbYN(row.active) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Reset Zone: " .. dbYN(row.resetZone) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Safe Zone: " .. dbYN(row.killZombies) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Public: " .. dbYN(row.public) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Allow Bases: " .. dbYN(row.allowBase) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Allow Waypoints: " .. dbYN(row.allowWaypoints) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Allow Returns: " .. dbYN(row.allowReturns) .. "[-]")

				if row.miniGame ~= nil then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Mini Game: " .. row.miniGame .. "[-]")
				end

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Village: " .. dbYN(row.village) .. "[-]")

				pname = ""
				if row.mayor ~= "0" then
					steam = row.mayor

					if not players[steam] then
						pname = playersArchived[steam].name
					else
						pname = players[steam].name
					end
				end

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Mayor: " .. pname .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Protected: " .. dbYN(row.protected) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]PVP: " .. dbYN(row.pvp) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Access Level: " .. row.accessLevel .. "[-]")

				if row.minimumLevel == row.maximumLevel then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Not player level restricted.[-]")
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Minimum player level: " .. row.minimumLevel .. ".[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Maximum player level: " .. row.maximumLevel .. ".[-]")
				end

				pname = ""
				if row.owner ~= "0" then
					steam = row.mayor

					if not players[steam] then
						pname = playersArchived[steam].name
					else
						pname = players[steam].name
					end
				end

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Owner: " .. pname .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Coords: " .. row.x .. " " .. row.y .. " " .. row.z .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Size: " .. row.size * 2 .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Cost: " .. row.cost .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Hidden: " .. dbYN(row.hidden) .. "[-]")

				botman.faultyChat = false
				return true
			end
		end
	end


	local function cmd_LocationRandom()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} random"
			help[2] = "Start setting random spawn points for the location.  The bot uses your position which it samples every 3 seconds or so.  It only records a new coordinate when you have moved more than 2 metres from the last recorded spot.\n"
			help[2] = help[2] .. "Unless you intend players to fall, do not fly or clip through objects while recording.  To stop recording just type stop.\n"
			help[2] = help[2] .. "You can record random spawns anywhere and more than once but remember to type stop after each recording or the bot will continue recording your movement and making spawn points from them.\n"
			help[2] = help[2] .. "The spawns do not have to be inside the location and you can make groups of spawns anywhere in the world for the location."

			tmp.command = help[1]
			tmp.keywords = "location,set,spawnpoint,random,teleports"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "rand") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and chatvars.words[chatvars.wordCount] == "random") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "random") - 2)
			locationName = string.trim(locationName)

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if loc ~= nil then
				igplayers[chatvars.playerid].location = loc
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are now creating spawn points for location " .. loc .. ". DO NOT FLY.[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LocationSetReset()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location set reset {name}"
			help[2] = "Flag the location as a reset zone.  The bot will warn players not to build in it and will block {#}setbase and will remove placed claims of non-staff."

			tmp.command = help[1]
			tmp.keywords = "location,reset,zone,set"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and chatvars.words[2] == "set" and chatvars.words[3] == "reset") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""

			if chatvars.words[4] then
				locationName = string.sub(chatvars.command, 21)
				locationName = string.trim(locationName)
			end

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				locations[loc].resetZone = true
				conn:execute("UPDATE locations set resetZone = 1 WHERE name = '" .. escape(loc) .. "'")

				message("say [" .. server.chatColour .. "]The location called " .. loc .. " is now a reset zone[-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is now a reset zone.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MoveLocation()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location move {name}"
			help[2] = "Move an existing location to where you are standing.  Unless you add random spawns, any player teleporting to the location will arrive at your current position.\n"
			help[2] = help[2] .. "If you are not on the ground, make sure the players can survive the landing.  If there are existing random spawns for the location, moving it will not move them.\n"
			help[2] = help[2] .. "You should clear them and redo them using {#}location {name} clear and {#}location {name} random."

			tmp.command = help[1]
			tmp.keywords = "location,move,relocate"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "move") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and chatvars.words[2] == "move") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.command, 16)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if (loc == nil) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				botman.faultyChat = false
				return true
			else
				locations[loc].x = chatvars.intX
				locations[loc].y = chatvars.intY
				locations[loc].z = chatvars.intZ

				conn:execute("UPDATE locations SET x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. " WHERE name = '" .. escape(loc) .. "'")
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','location moved','Location " .. escape(loc) .. " moved','" .. chatvars.playerid .. "')")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have moved a location called " .. loc .. "[-]")
				tempTimer( 3, [[loadLocations("]] .. loc .. [[")]] )
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ProtectLocation()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}protect location"
			help[2] = "Tell the bot to protect the location that you are in. It will instruct you what to do and will tell you when the location is protected."

			tmp.command = help[1]
			tmp.keywords = "location,protection"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "prot") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "protect" and chatvars.words[2] == "location") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if igplayers[chatvars.playerid].alertLocation ~= "" then
				igplayers[chatvars.playerid].alertLocationExit = igplayers[chatvars.playerid].alertLocation
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Walk out of " .. igplayers[chatvars.playerid].alertLocation .. " and I will do the rest.[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not in a location. Use this command when you have entered the location that you wish to protect.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RemoveLocation()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location remove {name}"
			help[2] = "Delete the location and all of its spawnpoints."

			tmp.command = help[1]
			tmp.keywords = "location,delete,remove"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "remove") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and chatvars.words[2] == "remove") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""

			if chatvars.words[3] then
				locationName = string.sub(chatvars.command, 18)
				locationName = string.trim(locationName)
			end

			if (chatvars.playername ~= "Server") then
				if locationName == "" then
					locationName = chatvars.inLocation
				end
			end

			loc = LookupLocation(locationName)

			if locationName == string.lower("prison") and server.gameType ~= "pvp" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The server needs a prison.  PVPs will be temp-banned instead.[-]")
				else
					irc_chat(chatvars.ircAlias, "The server needs a prison.  PVPs will be temp-banned instead.")
				end
			end

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				locations[loc] = nil
				connSQL:execute("DELETE FROM locationSpawns WHERE location = '" .. connMEM:escape(loc) .. "'")
				conn:execute("DELETE FROM locations WHERE name = '" .. escape(loc) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You removed a location called " .. loc .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "You removed a location called " .. loc)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RenameLocation()
		local oldLocation, newLocation, loc

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {old name} rename {new name}"
			help[2] = "Change an existing location's name to something else."

			tmp.command = help[1]
			tmp.keywords = "location,rename"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "name") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and string.find(chatvars.command, "rename")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			newLocation = string.sub(chatvars.commandOld, string.find(chatvars.command, "rename ") + 7)
			newLocation = string.trim(newLocation)

			if locations[newLocation] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. newLocation .. " already exists.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. newLocation .. " already exists.")
				end

				botman.faultyChat = false
				return true
			end

			oldLocation = string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "rename") - 2)
			oldLocation = string.trim(oldLocation)
			loc = LookupLocation(oldLocation)

			if not locations[loc] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. oldLocation .. " does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. oldLocation .. " does not exist.")
				end

				botman.faultyChat = false
				return true
			end

			if newLocation == "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New location name required.[-]")
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

				conn:execute("UPDATE locations SET name = '" .. escape(newLocation) .. "' WHERE name = '" .. escape(loc) .. "'")
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. locations[newLocation].x .. "," .. locations[newLocation].y .. "," .. locations[newLocation].z .. ",'" .. botman.serverTime .. "','location change','Location " .. escape(loc) .. " renamed " .. escape(newLocation) .. "','" .. chatvars.playerid .. "')")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have renamed " .. loc .. " to " .. newLocation .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "You have renamed " .. loc .. " to " .. newLocation)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetClearLocationCategory()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} category {category name}\n"
			help[1] = help[1] .. " {#}location {name} clear category"
			help[2] = "Set or clear a category for a location.  If the category doesn't exist it is created."

			tmp.command = help[1]
			tmp.keywords = "location,set,clear,category"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "cate") or string.find(chatvars.command, "set") or string.find(chatvars.command, "clear") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and string.find(chatvars.command, " category") and chatvars.words[3] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = {}

			if not string.find(chatvars.command, " clear") then
				tmp.location = string.trim(string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, " category") - 1))
				tmp.category = string.trim(string.sub(chatvars.commandOld, string.find(chatvars.command, " category ") + 10))

				if tmp.location == "" then
					tmp.location = chatvars.inLocation
				end

				if tmp.location == "" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Location name required.[-]")
					else
						irc_chat(chatvars.ircAlias, "Location name required.")
					end

					botman.faultyChat = false
					return true
				end

				if tmp.category == "" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Category required.[-]")
					else
						irc_chat(chatvars.ircAlias, "Category required.")
					end

					botman.faultyChat = false
					return true
				end

				tmp.loc = LookupLocation(tmp.location)

				if tmp.loc == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location doesn't exist.[-]")
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
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Location " .. tmp.loc .. " has been added to the location category " .. tmp.category .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "Location " .. tmp.loc .. " has been added to the location category " .. tmp.category)
				end
			else
				tmp.location = string.trim(string.sub(chatvars.commandOld, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, " clear") - 1))

				if tmp.location == "" then
					tmp.location = chatvars.inLocation
				end

				if tmp.location == "" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Location name required.[-]")
					else
						irc_chat(chatvars.ircAlias, "Location name required.")
					end

					botman.faultyChat = false
					return true
				end

				tmp.loc = LookupLocation(tmp.location)

				if tmp.loc == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location doesn't exist.[-]")
					else
						irc_chat(chatvars.ircAlias, "That location doesn't exist.")
					end

					botman.faultyChat = false
					return true
				end

				locations[tmp.loc].locationCategory = ""
				conn:execute("UPDATE locations set locationCategory = '' WHERE name = '" .. escape(tmp.loc) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Location " .. tmp.loc .. "'s category has been cleared.[-]")
				else
					irc_chat(chatvars.ircAlias, "Location " .. tmp.loc .. "'s category has been cleared.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationAccess()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} access {minimum access level}"
			help[2] = "Set the minimum access level required to teleport to the location."

			tmp.command = help[1]
			tmp.keywords = "location,set,access,limit,restriction,block,deny,max,level"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "set") or string.find(chatvars.command, "acce") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" or (chatvars.words[1] == "set" and chatvars.words[2] == "location")) and string.find(chatvars.command, "access") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""
			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "access") - 2)
			locationName = string.trim(locationName)

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if chatvars.number ~= nil and loc ~= nil then
				locations[loc].accessLevel = math.abs(chatvars.number)
				conn:execute("UPDATE locations set accessLevel = " .. locations[loc].accessLevel .. " WHERE name = '" .. escape(locationName) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. loc .. " is restricted to players with access level " .. locations[loc].accessLevel .. " and above.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. loc .. " is restricted to players with access level " .. locations[loc].accessLevel .. " and above.")
				end
			end

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationCloseHour()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} close {0-23}"
			help[2] = "Block and remove players from the location from a set hour."

			tmp.command = help[1]
			tmp.keywords = "location,close,set,open,times"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "close") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and string.find(chatvars.command, " close") and chatvars.words[2] ~= "add" and not string.find(chatvars.command, "day closed")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "close") - 2)
			locationName = string.trim(locationName)

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Missing close hour, a number from 0 to 23.[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing close hour, a number from 0 to 23.")
				end

				botman.faultyChat = false
				return true
			end

			if tonumber(chatvars.number) < 0 or tonumber(chatvars.number) > 23 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Close hour outside of range 0 to 23.[-]")
				else
					irc_chat(chatvars.ircAlias, "Close hour outside of range 0 to 23.")
				end

				botman.faultyChat = false
				return true
			end

			locations[loc].timeClosed = chatvars.number
			conn:execute("UPDATE locations SET timeClosed = " .. chatvars.number .. " WHERE name = '" .. escape(loc) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. loc .. " will be closed at " .. locations[loc].timeClosed .. ":00[-]")
			else
				irc_chat(chatvars.ircAlias, loc .. " will be closed at " .. locations[loc].timeClosed .. ":00")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationCoolDownTimer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set location {name} cooldown {number in seconds}"
			help[2] = "After teleporting to the location, players won't be able to teleport back to it until the cooldown timer expires."

			tmp.command = help[1]
			tmp.keywords = "location,set,cooldown,timer"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "location" and string.find(chatvars.command, "cooldown") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "cooldown") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if chatvars.number ~= nil and loc ~= nil then
				locations[loc].coolDownTimer = math.floor(tonumber(chatvars.number))
				conn:execute("UPDATE locations set coolDownTimer = " .. math.floor(tonumber(chatvars.number)) .. " WHERE name = '" .. escape(loc) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. loc .. " now has a cooldown timer of " .. locations[loc].coolDownTimer .. " seconds.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. loc .. " now has a cooldown timer of " .. locations[loc].coolDownTimer .. " seconds.")
				end
			end

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationCost()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} cost {number}"
			help[2] = "Require the player to have {number} " .. server.moneyPlural .. " to teleport there.  The " .. server.moneyPlural .. " are removed from the player afterwards."

			tmp.command = help[1]
			tmp.keywords = "location,set,cost,teleport"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "cost") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and string.find(chatvars.command, "cost") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "cost") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if chatvars.number ~= nil and loc ~= nil then
				locations[loc].cost = math.floor(tonumber(chatvars.number))
	-- TODO:  Look for the word currency and grab what follows it as the item to require an amount (cost) of.
				--if locations[loc].currency == nil then
					locations[loc].currency = server.moneyPlural
				--end

				conn:execute("UPDATE locations set cost = " .. math.floor(tonumber(chatvars.number)) .. ", currency = '" .. escape(locations[loc].currency) .. "' WHERE name = '" .. escape(locationName) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. loc .. " requires " .. locations[loc].cost .. " " .. locations[loc].currency .. " to teleport.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. loc .. " requires " .. locations[loc].cost .. " " .. locations[loc].currency .. " to teleport.")
				end
			end

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationDayClosed()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} day closed {number}"
			help[2] = "Block and remove players from the location on a set day. Disable this feature by setting it to 0."

			tmp.command = help[1]
			tmp.keywords = "location,close,set,open,day"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "close") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and string.find(chatvars.command, "day closed")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "day close") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Missing day, a number from 0 to 7.[-]")
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
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. loc .. " will be closed on day " .. locations[loc].dayClosed .. "[-]")
			else
				irc_chat(chatvars.ircAlias, loc .. " will be closed on day " .. locations[loc].dayClosed)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationMinigame()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} minigame {game type}"
			help[2] = "Flag the location as part of a minigame such as capture the flag.  The minigame is an unfinished idea so this command doesn't do much yet."

			tmp.command = help[1]
			tmp.keywords = "location,set,minigame"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "game") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and string.find(chatvars.command, "minigame") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = chatvars.words[2]
			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				miniGame = string.sub(chatvars.command, string.find(chatvars.command, "minigame") + 9)

				if (miniGame == nil) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You didn't enter a minigame (eg. ctf, contest).[-]")
					else
						irc_chat(chatvars.ircAlias, "You didn't enter a minigame (eg. ctf, contest).")
					end

					botman.faultyChat = false
					return true
				end

				locations[loc].miniGame = miniGame
				conn:execute("UPDATE locations set miniGame = '" .. escape(miniGame) .. "' WHERE name = '" .. escape(loc) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. loc .. " is the mini-game " .. miniGame .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. loc .. " is the mini-game " .. miniGame)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationOpenHour()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} open {0-23}"
			help[2] = "Allow players inside the location from a set hour."

			tmp.command = help[1]
			tmp.keywords = "location,close,set,open,time"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "open") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "location" and string.find(chatvars.command, " open")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "open") - 2)
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Missing open hour, a number from 0 to 23.[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing open hour, a number from 0 to 23.")
				end

				botman.faultyChat = false
				return true
			end

			if tonumber(chatvars.number) < 0 or tonumber(chatvars.number) > 23 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Open hour outside of range 0 to 23.[-]")
				else
					irc_chat(chatvars.ircAlias, "Open hour outside of range 0 to 23.")
				end

				botman.faultyChat = false
				return true
			end

			locations[loc].timeOpen = chatvars.number
			conn:execute("UPDATE locations SET timeOpen = " .. chatvars.number .. " WHERE name = '" .. escape(loc) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. loc .. " will open at " .. locations[loc].timeOpen .. ":00[-]")
			else
				irc_chat(chatvars.ircAlias, loc .. " will open at " .. locations[loc].timeOpen .. ":00")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationOwner()
		local playerName

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} owner {player name}"
			help[2] = "Assign ownership of a location to a player.  They will be able to set protect on it and players not friended to them won't be able to teleport there."

			tmp.command = help[1]
			tmp.keywords = "location,set,owner,assign,allocate"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "own") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and string.find(chatvars.command, " owner ") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "owner ") + 6)
			pname = string.trim(pname)
			steam, steamOwner, userID = LookupPlayer(pname)

			if steam == "0" then
				steam, steamOwner, userID = LookupArchivedPlayer(pname)

				if not (steam == "0") then
					playerName = playersArchived[steam].name
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player matched that name.[-]")
					else
						irc_chat(chatvars.ircAlias, "No player matched that name.")
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[steam].name
			end

			loc = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "owner") - 1)
			loc = string.trim(loc)
			loc = LookupLocation(loc)

			if (loc ~= nil) then
				locations[loc].owner = steam
				conn:execute("UPDATE locations set owner = '" .. steam .. "' WHERE name = '" .. escape(loc) .. "'")
				message("say [" .. server.chatColour .. "]" .. playerName .. " is the proud new owner of the location called " .. loc .. "[-]")
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationPlayerLevelRestriction()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} min level {minimum player level}\n"
			help[1] = help[1] .. "Or {#}location {name} max level {maximum player level}\n"
			help[1] = help[1] .. "Or {#}location {name} min level {minimum player level} max level {maximum player level}"
			help[2] = "Set a player level requirement to teleport to a location."

			tmp.command = help[1]
			tmp.keywords = "locat,level,access,minimum,maximum"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "lev") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and (string.find(chatvars.command, "min level") or string.find(chatvars.command, "max level")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
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
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. tmp.loc .. " is not restricted by player level.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location " .. tmp.loc .. " is not restricted by player level.")
					end

					botman.faultyChat = false
					return true
				end

				if tmp.minLevel > 0 then
					if tmp.maxLevel > 0 then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. tmp.loc .. " is restricted to players with player levels from " .. tmp.minLevel .. " to " .. tmp.maxLevel .. ".[-]")
						else
							irc_chat(chatvars.ircAlias, "The location " .. tmp.loc .. " is restricted to players with player levels from " .. tmp.minLevel .. " to " .. tmp.maxLevel .. ".")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. tmp.loc .. " is restricted to players with minimum player level of " .. tmp.minLevel .. " and above.[-]")
						else
							irc_chat(chatvars.ircAlias, "The location " .. tmp.locationName .. " is restricted to players with minimum player level of " .. tmp.minLevel .. " and above.")
						end
					end

					botman.faultyChat = false
					return true
				end

				if tmp.maxLevel > 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. tmp.loc .. " is restricted to players with a player level below " .. tmp.maxLevel + 1 .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "The location " .. tmp.loc .. " is restricted to players with a player level below " .. tmp.maxLevel + 1 .. ".")
					end
				end
			end

			if tmp.loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLocationSize()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} size {number}"
			help[2] = "Set the size of the location measured from its centre.  To make a 200 metre location set it to 100."

			tmp.command = help[1]
			tmp.keywords = "location,set,size"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "size") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and string.find(chatvars.command, "size") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "size") - 2)
			locationName = string.trim(locationName)

			loc = LookupLocation(locationName)

			if chatvars.number ~= nil and loc ~= nil then
				locations[loc].size = math.floor(tonumber(chatvars.number))
				conn:execute("UPDATE locations set size = " .. math.floor(tonumber(chatvars.number)) .. ", protectSize = " .. math.floor(tonumber(chatvars.number)) .. " WHERE name = '" .. escape(loc) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. loc .. " now spans " .. tonumber(chatvars.number * 2) .. " metres.[-]")
				else
					irc_chat(chatvars.ircAlias, "The location " .. loc .. " now spans " .. tonumber(chatvars.number * 2) .. " metres.")
				end

				if loc == string.lower("prison") then
					server.prisonSize = math.floor(tonumber(chatvars.number))
					conn:execute("UPDATE server SET prisonSize = " .. math.floor(tonumber(chatvars.number)))
				end
			end

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetTP()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set tp {optional location}"
			help[2] = "Create a single random teleport for the location you are in or if you are recording random teleports, it will set for that location.\n"
			help[2] = help[2] .. "If you provide a location name you will create 1 random TP for that location where you are standing."

			tmp.command = help[1]
			tmp.keywords = "location,set,spawn,tp,point,teleport"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "set" and chatvars.words[2] == "tp") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[3] ~= nil then
				locationName = string.sub(chatvars.command, 9)
				locationName = string.trim(locationName)
				loc = LookupLocation(locationName)

				if loc ~= nil then
					connSQL:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. chatvars.words[3] .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Random TP added to " .. loc .. "[-]")

					botman.faultyChat = false
					return true
				end
			end

			if igplayers[chatvars.playerid].location ~= nil then
				connSQL:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. igplayers[chatvars.playerid].location .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Random TP added to " .. igplayers[chatvars.playerid].location .. "[-]")
			else
				if players[chatvars.playerid].inLocation ~= "" then
					connSQL:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. players[chatvars.playerid].inLocation .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Random TP added to " .. players[chatvars.playerid].inLocation .. "[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationAllowBase()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location allow base {location name}\n"
			help[1] = help[1] .. "Or {#}location (disallow or deny or block) base {location name}"
			help[2] = "Allow players to {#}setbase in the location or block that."

			tmp.command = help[1]
			tmp.keywords = "location,base,home,disallow,allow,enable,disable,block,deny"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "allow") or string.find(chatvars.command, "base") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and (chatvars.words[2] == "allow" or chatvars.words[2] == "disallow") and chatvars.words[3] == "base" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.locationName = ""

			if chatvars.words[4] then
				tmp.pos = string.find(chatvars.command, " base ")
				tmp.locationName = string.sub(chatvars.command, tmp.pos + 6)
				tmp.locationName = string.trim(tmp.locationName)
			end

			if tmp.locationName == "" then
				tmp.locationName = chatvars.inLocation
			end

			tmp.loc = LookupLocation(tmp.locationName)

			if (tmp.loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[2] == "allow" then
					locations[tmp.loc].allowBase = true
					conn:execute("UPDATE locations SET allowBase = 1 WHERE name = '" .. escape(tmp.loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players may setbase in " .. tmp.loc .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players may setbase in " .. tmp.loc .. ".")
					end
				else
					locations[tmp.loc].allowBase = false
					conn:execute("UPDATE locations SET allowBase = 0 WHERE name = '" .. escape(tmp.loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players cannot setbase in " .. tmp.loc .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players cannot setbase in " .. tmp.loc .. ".")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationEnabled()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location enable (or disable) {name}"
			help[2] = "Flag the location as enabled or disabled. Currently this flag isn't used and you can ignore this command."

			tmp.command = help[1]
			tmp.keywords = "location,enable,disable,on,off"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "able") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and string.find(chatvars.words[2], "able") and not string.find(chatvars.command, "return") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""

			if chatvars.words[3] then
				locationName = string.sub(chatvars.command, 18)
				locationName = string.trim(locationName)
			end

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if string.find(chatvars.words[2], "enable") then
					locations[loc].active = true
					conn:execute("UPDATE locations set active = 1 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location called " .. loc .. " is now enabled.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is now enabled.")
					end
				else
					locations[loc].active = false
					conn:execute("UPDATE locations set active = 0 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location called " .. loc .. " is now disabled.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is now disabled.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationHidden()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location hide/unhide {name}"
			help[2] = "Flag the location as hidden or unhidden. Hidden locations are only shown to admins when using the {#}locations command."

			tmp.command = help[1]
			tmp.keywords = "locat,hide"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "able") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and (chatvars.words[2] == "hide" or chatvars.words[2] == "unhide" or chatvars.words[2] == "show") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""

			if chatvars.words[3] then
				if chatvars.words[2] == "hide" then
					locationName = string.sub(chatvars.command, 16)
				else
					locationName = string.sub(chatvars.command, 18)
				end

				locationName = string.trim(locationName)
			end

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[2] == "hide" then
					locations[loc].hidden = true
					conn:execute("UPDATE locations set hidden = 1 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location called " .. loc .. " is now hidden from players.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is now hidden from players.")
					end
				else
					locations[loc].hidden = false
					conn:execute("UPDATE locations set hidden = 0 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location called " .. loc .. " can be seen by players.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " can be seen by players.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationIsLobby()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location lobby/not lobby {name}"
			help[2] = "Flag the location as the lobby or not the lobby. New players will be sent to this location when they spawn if it is flagged as lobby.  Only one location will be used so flagging more will not make them all the lobby.\n"
			help[2] = help[2] .. "To do that use {#}set tp {location}.  This will add a random teleport destination for the location.  You can set as many as you want."

			tmp.command = help[1]
			tmp.keywords = "locat,lobby"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "lobby") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and (chatvars.words[2] == "lobby" or string.find(chatvars.command, "not lobby")) and not (string.find(chatvars.command, " pvp") or string.find(chatvars.command, " pve") or string.find(chatvars.command, " enable") or string.find(chatvars.command, " disable")) and chatvars.words[3] ~= "watch" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""
			locationName = string.sub(chatvars.command, string.find(chatvars.command, " lobby ") + 7)
			locationName = string.trim(locationName)

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[2] == "lobby" then
					locations[loc].lobby = true
					conn:execute("UPDATE locations set lobby = 1 WHERE name = '" .. escape(loc) .. "'")
					conn:execute("UPDATE locations set lobby = 0 WHERE name <> '" .. escape(loc) .. "'")

					-- reload the locations table
					loadLocations()

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location called " .. loc .. " is now the lobby.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is now the lobby.")
					end
				else
					locations[loc].lobby = false
					conn:execute("UPDATE locations set lobby = 0 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location called " .. loc .. " is no longer the lobby.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is no longer the lobby.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationIsRound()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location (round or circle or square) {name}"
			help[2] = "Locations are circles by default with a central coord and a radius.  You can make the location a square (with equal sides).\n"
			help[2] = help[2] .. "The location's size is always its radius."

			tmp.command = help[1]
			tmp.keywords = "location,toggle,set,square,round,circle,shape"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "togg") or string.find(chatvars.command, "round") or string.find(chatvars.command, "square") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and (chatvars.words[2] == "round" or chatvars.words[2] == "circle" or chatvars.words[2] == "square") and chatvars.words[3] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""

			if chatvars.words[3] then
				locationName = string.sub(chatvars.command, 17)
				locationName = string.trim(locationName)
			end

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[2] == "round" or chatvars.words[2] == "circle" then
					locations[loc].isRound = true
					conn:execute("UPDATE locations set isRound = 1 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location called " .. loc .. " is now a circle with radius " .. locations[loc].size .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is now a circle with radius " .. locations[loc].size .. ".")
					end
				else
					locations[loc].isRound = false
					conn:execute("UPDATE locations set isRound = 0 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location called " .. loc .. " is now a square with radius " .. locations[loc].size .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is now a square with radius " .. locations[loc].size .. ".")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationP2P()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location p2p enable (or disable) {name} (default is enabled)"
			help[2] = "When disabled, players will not be able to teleport to friends or fetch friends in the location."

			tmp.command = help[1]
			tmp.keywords = "location,p2p,enable,disable,set,toggle"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "p2p") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and chatvars.words[2] == "p2p" and string.find(chatvars.words[3], "able") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""

			if chatvars.words[4] then
				locationName = string.sub(chatvars.command, 22)
				locationName = string.trim(locationName)
			end

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[3] == "enable" then
					locations[loc].allowP2P = true
					conn:execute("UPDATE locations set allowP2P = 1 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. loc .. " allows players to teleport to friends and fetch friends.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location " .. loc .. " allows players to teleport to friends and fetch friends.")
					end
				else
					locations[loc].allowP2P = false
					conn:execute("UPDATE locations set allowP2P = 0 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The location " .. loc .. " will not let players teleport to friends or fetch friends.[-]")
					else
						irc_chat(chatvars.ircAlias, "The location " .. loc .. " will not let players teleport to friends or fetch friends.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationPack()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location pack enable (or disable) {name} (default is enabled)"
			help[2] = "When disabled, the {#}pack command will not work if the player died inside the location."

			tmp.command = help[1]
			tmp.keywords = "location,pack,enable,disable,set,toggle"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "pack") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and (chatvars.words[2] == "pack" or chatvars.words[2] == "revive") and string.find(chatvars.words[3], "able") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""

			if chatvars.words[4] then
				locationName = string.sub(chatvars.command, 23)
				locationName = string.trim(locationName)
			end

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[3] == "enable" then
					locations[loc].allowPack = true
					conn:execute("UPDATE locations set allowPack = 1 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players that die in the location " .. loc .. " can use the {#}pack command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Players that die in the location " .. loc .. " can use the {#}pack command.")
					end
				else
					locations[loc].allowPack = false
					conn:execute("UPDATE locations set allowPack = 0 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The {#}pack command is not available to players that die in the location " .. loc .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "The {#}pack command is not available to players that die in the location " .. loc)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationPrivate()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location private (or public) {name} (default is private)"
			help[2] = "Flag the location as private or public.  Players can only use public locations."

			tmp.command = help[1]
			tmp.keywords = "location,private,public,set,toggle"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "priv") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and (chatvars.words[2] == "private" or chatvars.words[2] == "public") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""

			if chatvars.words[3] then
				locationName = string.sub(chatvars.command, 18)
				locationName = string.trim(locationName)
			end

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[2] == "private" then
					locations[loc].public = false
					conn:execute("UPDATE locations set public = 0 WHERE name = '" .. escape(loc) .. "'")

					message("say [" .. server.chatColour .. "]The location called " .. loc .. " is now private[-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is now private.")
					end
				else
					locations[loc].public = true
					conn:execute("UPDATE locations set public = 1 WHERE name = '" .. escape(loc) .. "'")

					message("say [" .. server.chatColour .. "]The location called " .. loc .. " is now public[-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is now public.")
					end

				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationPVP()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} pvp\n"
			help[1] = help[1] .. " {#}location {name} pve"
			help[2] = "Change the rules at a location to pvp or pve."

			tmp.command = help[1]
			tmp.keywords = "location,pve,pvp,set,world,rules"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, " pv") - 1)
			locationName = string.trim(locationName)

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if loc ~= nil then
				if string.find(chatvars.command, "pve") then
					locations[loc].pvp = false
					conn:execute("UPDATE locations set pvp = 0 WHERE name = '" .. escape(loc) .. "'")
					message("say [" .. server.chatColour .. "]The location " .. loc .. " is now a PVE zone.[-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location " .. loc .. " is now a PVE zone.")
					end
				else
					locations[loc].pvp = true
					conn:execute("UPDATE locations set pvp = 1 WHERE name = '" .. escape(loc) .. "'")
					message("say [" .. server.chatColour .. "]The location " .. loc .. " is now a PVP zone![-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location " .. loc .. " is now a PVP zone.")
					end
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationReturns()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} enable (or disable) returns"
			help[2] = "Enable or disable the return command for a location."

			tmp.command = help[1]
			tmp.keywords = "location,return,enable,disable,teleport"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "able") or string.find(chatvars.command, "return") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and string.find(chatvars.command, "able") and string.find(chatvars.command, "return") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if string.find(chatvars.command, "disable") then
				temp = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[2]), string.find(chatvars.command, "disable") - 2)
			else
				temp = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[2]), string.find(chatvars.command, "enable") - 2)
			end

			loc = LookupLocation(temp)

			if loc ~= nil then
				if string.find(chatvars.command, "disable") then
					locations[loc].allowReturns = false
					conn:execute("UPDATE locations set allowReturns = 0 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will not be able to use returns in " .. loc .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players will not be able to use returns in " .. loc)
					end
				else
					locations[loc].allowReturns = true
					conn:execute("UPDATE locations set allowReturns = 1 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can use returns in " .. loc .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players can use returns in " .. loc)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationSafe()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location safe (or unsafe) {location name}"
			help[2] = "Flag/unflag the location as a safe zone.  The bot will automatically kill zombies in the location if players are in it.\n"
			help[2] = help[2] .. "To prevent this feature spamming the server it is triggered every 30 seconds. When there are more than 10 players it changes to every minute."

			tmp.command = help[1]
			tmp.keywords = "location,set,safe,zone,zombies,zeds,despawn,kill"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "safe") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and (chatvars.words[2] == "safe" or chatvars.words[2] == "unsafe") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = ""

			if chatvars.words[3] then
				locationName = string.sub(chatvars.command, 16)
				locationName = string.trim(locationName)
			end

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if (loc == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That location does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That location does not exist.")
				end
			else
				if chatvars.words[2] == "safe" then
					locations[loc].killZombies = true
					server.scanZombies = true
					conn:execute("UPDATE locations set killZombies = 1 WHERE name = '" .. escape(loc) .. "'")

					message("say [" .. server.chatColour .. "]The location called " .. loc .. " is now a safezone.[-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is now a safezone.")
					end
				else
					locations[loc].killZombies = false
					server.scanZombies = true
					conn:execute("UPDATE locations set killZombies = 0 WHERE name = '" .. escape(loc) .. "'")

					message("say [" .. server.chatColour .. "]The location called " .. loc .. " is no longer a safezone![-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, "The location called " .. loc .. " is no longer a safezone.")
					end

				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLocationWatchPlayers()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} watch\n"
			help[1] = help[1] .. "Or {#}location {name} stop watching"
			help[2] = "Set a location to report player activity regardless of other player watch settings, or not.  The default is to not watch players.\n"
			help[2] = help[2] .. "Use this setting to be alerted whenever a player enters/exits a watched location or their inventory changes while in it."

			tmp.command = help[1]
			tmp.keywords = "location,watch,player"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "watch") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and (string.find(chatvars.command, "watch") or string.find(chatvars.command, "stop watching")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
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
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will not be watched in location " .. loc .. " unless individually watched.[-]")
					else
						irc_chat(chatvars.ircAlias, "Players not will be watched in location " .. loc .. " unless individually watched")
					end
				else
					locations[loc].watch = true
					conn:execute("UPDATE locations set watchPlayers = 1 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will be watched in location " .. loc .. ".[-]")
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
		local loc

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}location {name} enable (or disable) waypoints"
			help[2] = "Block or allow players to set waypoints in the location."

			tmp.command = help[1]
			tmp.keywords = "location,waypoints,enable,disable,toggle"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "able") or string.find(chatvars.command, "wayp") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "location" and string.find(chatvars.command, "able") and string.find(chatvars.command, "wayp") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if string.find(chatvars.command, "disable") then
				temp = string.sub(chatvars.command, string.find(chatvars.command, "location") + 9, string.find(chatvars.command, "disable") - 2)
			else
				temp = string.sub(chatvars.command, string.find(chatvars.command, "location") + 9, string.find(chatvars.command, "enable") - 2)
			end

			loc = LookupLocation(temp)

			if locations[loc] then
				if string.find(chatvars.command, "disable") then
					locations[loc].allowWaypoints = false
					conn:execute("UPDATE locations set allowWaypoints = 0 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will not be able to set waypoints in " .. loc .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players will not be able to set waypoints in " .. loc)
					end
				else
					locations[loc].allowWaypoints = true
					conn:execute("UPDATE locations set allowWaypoints = 1 WHERE name = '" .. escape(loc) .. "'")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can set waypoints in " .. loc .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "Players can set waypoints in " .. loc)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleShowLocationEnterExitMessage()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}show (or {#}hide) locations"
			help[2] = "Normally when you enter and leave a location you will see a private message informing you of this.  You can disable the message."

			tmp.command = help[1]
			tmp.keywords = "location,show,hide"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "show") or string.find(chatvars.command, "hide") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "show" or chatvars.words[1] == "hide") and chatvars.words[2] == "locations" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "show" then
				server.showLocationMessages = true
				conn:execute("UPDATE server SET showLocationMessages = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will be alerted when they enter or leave locations.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will be alerted when they enter or leave locations.")
				end
			else
				server.showLocationMessages = false
				conn:execute("UPDATE server SET showLocationMessages = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will only see rule changes when they enter or leave locations.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will only see rule changes when they enter or leave locations.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnprotectLocation()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}unprotect location {optional name}"
			help[2] = "Remove bot protection from the location. You can leave out the location name if you are in the location."

			tmp.command = help[1]
			tmp.keywords = "location,protection"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "locat") or string.find(chatvars.command, "prot") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "unprotect" and chatvars.words[2] == "location") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			locationName = string.sub(chatvars.command, 21)
			locationName = string.trim(locationName)

			if locationName == "" then
				locationName = chatvars.inLocation
			end

			loc = LookupLocation(locationName)

			if loc ~= nil then
				locations[loc].protected = false
				conn:execute("UPDATE locations SET protected = 0 WHERE name = '" .. escape(loc) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have disabled protection for " .. loc .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "You have disabled protection for " .. loc .. ".")
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				if igplayers[chatvars.playerid].alertLocation ~= "" then
					locations[igplayers[chatvars.playerid].alertLocation].protected = false
					conn:execute("UPDATE locations SET protected = 0 WHERE name = '" .. escape(igplayers[chatvars.playerid].alertLocation) .. "'")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have disabled protection for " .. igplayers[chatvars.playerid].alertLocation .. ".[-]")
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not in a location. Use this command when you have entered the location that you wish to remove protection from.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		if debug then dbug("Registering help - location commands") end

		tmp.topicDescription = 'A location is usually a teleport destination. They can be configured for many purposes.'

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Location Commands:")
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, tmp.topicDescription)
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "You can find more information about locations in the following guide.")
			irc_chat(chatvars.ircAlias, "https://files.botman.nz/guides/Locations_Noobie_Guide.pdf")
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

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.command, "locat") then
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
		irc_chat(chatvars.ircAlias, "Location Commands:")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "locations")
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddLocation()

	if result then
		if debug then dbug("debug cmd_AddLocation triggered") end
		return result, "cmd_AddLocation"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListCategories()

	if result then
		if debug then dbug("debug cmd_ListCategories triggered") end
		return result, "cmd_ListCategories"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListLocations()

	if result then
		if debug then dbug("debug cmd_ListLocations triggered") end
		return result, "cmd_ListLocations"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_Lobby()

	if result then
		if debug then dbug("debug cmd_Lobby triggered") end
		return result, "cmd_Lobby"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationClearReset()

	if result then
		if debug then dbug("debug cmd_LocationClearReset triggered") end
		return result, "cmd_LocationClearReset"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationClearSpawnPoints()

	if result then
		if debug then dbug("debug cmd_LocationClearSpawnPoints triggered") end
		return result, "cmd_LocationClearSpawnPoints"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationEndsHere()

	if result then
		if debug then dbug("debug cmd_LocationEndsHere triggered") end
		return result, "cmd_LocationEndsHere"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationRandom()

	if result then
		if debug then dbug("debug cmd_LocationRandom triggered") end
		return result, "cmd_LocationRandom"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationSetReset()

	if result then
		if debug then dbug("debug cmd_LocationSetReset triggered") end
		return result, "cmd_LocationSetReset"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_MoveLocation()

	if result then
		if debug then dbug("debug cmd_MoveLocation triggered") end
		return result, "cmd_MoveLocation"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ProtectLocation()

	if result then
		if debug then dbug("debug cmd_ProtectLocation triggered") end
		return result, "cmd_ProtectLocation"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_RemoveLocation()

	if result then
		if debug then dbug("debug cmd_RemoveLocation triggered") end
		return result, "cmd_RemoveLocation"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_RenameLocation()

	if result then
		if debug then dbug("debug cmd_RenameLocation triggered") end
		return result, "cmd_RenameLocation"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetClearLocationCategory()

	if result then
		if debug then dbug("debug cmd_SetClearLocationCategory triggered") end
		return result, "cmd_SetClearLocationCategory"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationAccess()

	if result then
		if debug then dbug("debug cmd_SetLocationAccess triggered") end
		return result, "cmd_SetLocationAccess"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationCloseHour()

	if result then
		if debug then dbug("debug cmd_SetLocationCloseHour triggered") end
		return result, "cmd_SetLocationCloseHour"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationCoolDownTimer()

	if result then
		if debug then dbug("debug cmd_SetLocationCoolDownTimer triggered") end
		return result, "cmd_SetLocationCoolDownTimer"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationCost()

	if result then
		if debug then dbug("debug cmd_SetLocationCost triggered") end
		return result, "cmd_SetLocationCost"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationDayClosed()

	if result then
		if debug then dbug("debug cmd_SetLocationDayClosed triggered") end
		return result, "cmd_SetLocationDayClosed"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationMinigame()

	if result then
		if debug then dbug("debug cmd_SetLocationMinigame triggered") end
		return result, "cmd_SetLocationMinigame"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationOpenHour()

	if result then
		if debug then dbug("debug cmd_SetLocationOpenHour triggered") end
		return result, "cmd_SetLocationOpenHour"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationOwner()

	if result then
		if debug then dbug("debug cmd_SetLocationOwner triggered") end
		return result, "cmd_SetLocationOwner"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationPlayerLevelRestriction()

	if result then
		if debug then dbug("debug cmd_SetLocationPlayerLevelRestriction triggered") end
		return result, "cmd_SetLocationPlayerLevelRestriction"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLocationSize()

	if result then
		if debug then dbug("debug cmd_SetLocationSize triggered") end
		return result, "cmd_SetLocationSize"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetTP()

	if result then
		if debug then dbug("debug cmd_SetTP triggered") end
		return result, "cmd_SetTP"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationAllowBase()

	if result then
		if debug then dbug("debug cmd_ToggleLocationAllowBase triggered") end
		return result, "cmd_ToggleLocationAllowBase"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationEnabled()

	if result then
		if debug then dbug("debug cmd_ToggleLocationEnabled triggered") end
		return result, "cmd_ToggleLocationEnabled"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationHidden()

	if result then
		if debug then dbug("debug cmd_ToggleLocationHidden triggered") end
		return result, "cmd_ToggleLocationHidden"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationIsLobby()

	if result then
		if debug then dbug("debug cmd_ToggleLocationIsLobby triggered") end
		return result, "cmd_ToggleLocationIsLobby"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationIsRound()

	if result then
		if debug then dbug("debug cmd_ToggleLocationIsRound triggered") end
		return result, "cmd_ToggleLocationIsRound"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationP2P()

	if result then
		if debug then dbug("debug cmd_ToggleLocationP2P triggered") end
		return result, "cmd_ToggleLocationP2P"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationPack()

	if result then
		if debug then dbug("debug cmd_ToggleLocationPack triggered") end
		return result, "cmd_ToggleLocationPack"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationPrivate()

	if result then
		if debug then dbug("debug cmd_ToggleLocationPrivate triggered") end
		return result, "cmd_ToggleLocationPrivate"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationPVP()

	if result then
		if debug then dbug("debug cmd_ToggleLocationPVP triggered") end
		return result, "cmd_ToggleLocationPVP"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationReturns()

	if result then
		if debug then dbug("debug cmd_ToggleLocationReturns triggered") end
		return result, "cmd_ToggleLocationReturns"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationSafe()

	if result then
		if debug then dbug("debug cmd_ToggleLocationSafe triggered") end
		return result, "cmd_ToggleLocationSafe"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationWatchPlayers()

	if result then
		if debug then dbug("debug cmd_ToggleLocationWatchPlayers triggered") end
		return result, "cmd_ToggleLocationWatchPlayers"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLocationWaypoints()

	if result then
		if debug then dbug("debug cmd_ToggleLocationWaypoints triggered") end
		return result, "cmd_ToggleLocationWaypoints"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleShowLocationEnterExitMessage()

	if result then
		if debug then dbug("debug cmd_ToggleShowLocationEnterExitMessage triggered") end
		return result, "cmd_ToggleShowLocationEnterExitMessage"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnprotectLocation()

	if result then
		if debug then dbug("debug cmd_UnprotectLocation triggered") end
		return result, "cmd_UnprotectLocation"
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	result = cmd_LocationInfo()

	if result then
		if debug then dbug("debug cmd_LocationInfo triggered") end
		return result, "cmd_LocationInfo"
	end

	if debug then dbug("debug locations end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == "0" and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false, ""
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	-- look for command in locations table
	loc = LookupLocation(chatvars.command)

if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if (loc ~= nil) then
		-- reject if not an admin and server is in hardcore mode
		if (not chatvars.isAdminHidden) and chatvars.settings.hardcore then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command is disabled.[-]")
			botman.faultyChat = false
			return true, ""
		end

		if (players[chatvars.playerid].prisoner or not players[chatvars.playerid].canTeleport or not chatvars.settings.allowTeleporting) and not chatvars.isAdmin then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not allowed to use teleports.[-]")
			botman.faultyChat = false
			return true, ""
		end

		if (players[chatvars.playerid].walkies) then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not allowed to use teleports.[-]")
			botman.faultyChat = false
			return true, ""
		end

		-- reject if not an admin and pvpTeleportCooldown is > zero
		if not chatvars.isAdmin and tonumber(players[chatvars.playerid].pvpTeleportCooldown) > 0 then
			if (players[chatvars.playerid].pvpTeleportCooldown - os.time() > 0) then
				if players[chatvars.playerid].pvpTeleportCooldown - os.time() < 3600 then
					delay = os.date("%M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())
				else
					delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())
				end

				message(string.format("pm %s [%s]You must wait %s before you are allowed to teleport again.", chatvars.userID, server.chatColour, delay))
				botman.faultyChat = false
				result = true
				return true, ""
			end
		end

		if (os.time() - igplayers[chatvars.playerid].lastTPTimestamp < 5) and (not chatvars.isAdmin) then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Teleport is recharging.  Wait a few seconds.  You can repeat your last command by typing " .. server.commandPrefix .."[-]")
			botman.faultyChat = false
			return true, ""
		end

		cursor,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. escape(loc) .."'")
		row = cursor:fetch({}, "a")

		if (locations[loc].village == true) then
 			if villagers[chatvars.playerid .. loc] then
				if (players[chatvars.playerid].baseCooldown - os.time() > 0) and (not chatvars.isAdmin or botman.ignoreAdmins == false) then --  and botman.ignoreAdmins == false
					if players[chatvars.playerid].baseCooldown - os.time() < 3600 then
						delay = os.date("%M minutes %S seconds",players[chatvars.playerid].baseCooldown - os.time())
					else
						delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].baseCooldown - os.time())
					end

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have to wait " .. delay .. " before you can use " .. server.commandPrefix .. loc .. " again.[-]")
					botman.faultyChat = false
					return true, ""
				else
					players[chatvars.playerid].baseCooldown = (os.time() + chatvars.settings.baseCooldown)

					players[chatvars.playerid].xPosOld = 0
					players[chatvars.playerid].yPosOld = 0
					players[chatvars.playerid].zPosOld = 0
					igplayers[chatvars.playerid].lastLocation = loc

					cursor,errorString = connSQL:execute("SELECT count(*) FROM locationSpawns WHERE location='" .. connMEM:escape(loc) .. "'")
					rowSQL = cursor:fetch({}, "a")
					rowCount = rowSQL["count(*)"]

					if rowCount > 0 then
						randomTP(chatvars.playerid, chatvars.userID, loc)
					else
						cmd = "tele " .. chatvars.userID .. " " .. locations[loc].x .. " " .. locations[loc].y + 1 .. " " .. locations[loc].z
						teleport(cmd, chatvars.playerid, chatvars.userID)
					end

					botman.faultyChat = false
					return true, ""
				end
			end
		end

		if (row.public == "0" and not chatvars.isAdminHidden) and row.owner ~= chatvars.playerid then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.name .. " is private[-]")
			botman.faultyChat = false
			return true, ""
		end

		if (row.active == "0" and not chatvars.isAdminHidden) then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.name .. " is not enabled right now[-]")
			botman.faultyChat = false
			return true, ""
		end

		if not locations[loc].open then
			locations[loc].open = isLocationOpen(loc)

			if locations[loc].open then
				message("say [" .. server.chatColour .. "]The location " .. loc .. " is now open.[-]")
			end
		end

		if not locations[loc].open and not chatvars.isAdminHidden then
			if locations[loc].timeOpen == 0 then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.name .. " is closed. It will re-open at midnight.[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.name .. " is closed. It will re-open at " .. locations[loc].timeOpen .. ":00[-]")
			end

			botman.faultyChat = false
			return true, ""
		end

		if (chatvars.accessLevel > tonumber(row.accessLevel) or (locations[loc].newPlayersOnly and not players[chatvars.playerid].newPlayer and not chatvars.isAdminHidden)) then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not authorised to visit " .. row.name .. ".[-]")
			botman.faultyChat = false
			return true, ""
		end

		-- reject if not an admin and the location has a cooldown timer and the player's cooldown timer > 0
		if players[chatvars.playerid]["loc_" .. loc] then
			if not chatvars.isAdmin and (tonumber(players[chatvars.playerid]["loc_" .. loc]) - os.time() > 0) then
				if tonumber(players[chatvars.playerid]["loc_" .. loc]) - os.time() < 3600 then
					delay = os.date("%M minutes %S seconds",tonumber(players[chatvars.playerid]["loc_" .. loc]) - os.time())
				else
					delay = os.date("%H hours %M minutes %S seconds",tonumber(players[chatvars.playerid]["loc_" .. loc]) - os.time())
				end

				message(string.format("pm %s [%s]You must wait %s before you are allowed to teleport to %s again.", chatvars.userID, server.chatColour, delay, loc))
				botman.faultyChat = false
				result = true
				return true, ""
			end
		end

		-- check player level restrictions on the location
		if (tonumber(row.minimumLevel) > 0 or tonumber(row.maximumLevel) > 0) and not chatvars.isAdminHidden then
			if tonumber(row.minimumLevel) > 0 and tonumber(players[chatvars.playerid].level) < tonumber(row.minimumLevel) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Teleporting to " .. row.name .. " is level restricted. You need to reach level " .. row.minimumLevel .. ".[-]")
				botman.faultyChat = false
				return true, ""
			end

			if tonumber(row.minimumLevel) > 0 and tonumber(row.maximumLevel) > 0 and (tonumber(players[chatvars.playerid].level) < tonumber(row.minimumLevel) or tonumber(players[chatvars.playerid].level) > tonumber(row.maximumLevel)) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Teleporting to " .. row.name .. " is level restricted. You can go there when your level is " .. row.minimumLevel .. " to " .. row.maximumLevel .. ".[-]")
				botman.faultyChat = false
				return true, ""
			end

			if tonumber(row.maximumLevel) > 0 and tonumber(players[chatvars.playerid].level) > tonumber(row.maximumLevel) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Teleporting to " .. row.name .. " is level restricted and your level is too high.[-]")
				botman.faultyChat = false
				return true, ""
			end
		end

		if tonumber(row.cost) > 0 then
			if string.lower(row.currency) == string.lower(server.moneyPlural) then
				if players[chatvars.playerid].cash < tonumber(row.cost) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. " to travel there.[-]")
					botman.faultyChat = false
					return true, ""
				else
					-- collect payment
					players[chatvars.playerid].cash = players[chatvars.playerid].cash - tonumber(row.cost)
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.cost .. " " .. server.moneyPlural .. " have been deducted for teleporting to " .. row.name .. ".[-]")
				end
			else
				if not inInventory(chatvars.playerid, row.currency, row.cost) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You do not have enough of the required item to travel there.[-]")
					botman.faultyChat = false
					return true, ""
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

		cursor,errorString = connSQL:execute("SELECT count(*) FROM locationSpawns WHERE location='" .. connMEM:escape(loc) .. "'")
		rowSQL = cursor:fetch({}, "a")
		rowCount = rowSQL["count(*)"]

		if rowCount > 0 then
			randomTP(chatvars.playerid, chatvars.userID, loc)

			if server.announceTeleports then
				if not chatvars.isAdminHidden then message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " is porting to " .. loc .. "[-]") end
			end
		else
			if tonumber(locations[loc].coolDownTimer) > 0 then
				players[chatvars.playerid]["loc_" .. loc] = os.time() + locations[loc].coolDownTimer
			end

			cmd = "tele " .. chatvars.userID .. " " .. row.x .. " " .. row.y + 1 .. " " .. row.z

			if chatvars.settings.playerTeleportDelay == 0 or chatvars.isAdmin then --  or not igplayers[chatvars.playerid].currentLocationPVP
				teleport(cmd, chatvars.playerid, chatvars.userID)
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You will be teleported to " .. loc .. " in " .. chatvars.settings.playerTeleportDelay .. " seconds.[-]")
				if botman.dbConnected then connSQL:execute("insert into persistentQueue (steam, command, timerDelay) values ('" .. chatvars.playerid .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + chatvars.settings.playerTeleportDelay .. "')") end
				botman.persistentQueueEmpty = false
			end

			if server.announceTeleports then
				if not chatvars.isAdminHidden then message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " is porting to " .. loc .. "[-]") end
			end
		end

		botman.faultyChat = false
		return true, ""
	end

	if botman.registerHelp then
		if debug then dbug("Location commands help registered") end
	end

	if debug then dbug("debug locations end") end

	-- can't touch dis
	if true then
		return result, ""
	end
end

