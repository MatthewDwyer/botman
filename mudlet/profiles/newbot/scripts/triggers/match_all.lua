--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false -- should be false unless testing


function flagAdminsForRemoval()
	local k,v

	for k,v in pairs(owners) do
		v.remove = true
	end

	for k,v in pairs(admins) do
		v.remove = true
	end

	for k,v in pairs(mods) do
		v.remove = true
	end
end


function removeOldStaff()
	if getAdminList then
		-- abort if getAdminList is true as that means there's been a fault in the telnet data
		return
	end

	local k,v

	for k,v in pairs(owners) do
		if v.remove then
			owners[k] = nil
		end
	end

	for k,v in pairs(admins) do
		if v.remove then
			admins[k] = nil
		end
	end

	for k,v in pairs(mods) do
		if v.remove then
			mods[k] = nil
		end
	end

	-- nuke the staff table and rebuild it
	if botman.dbConnected then conn:execute("DELETE FROM staff") end

	for k,v in pairs(owners) do
		if botman.dbConnected then conn:execute("INSERT INTO staff (steam, adminLevel) VALUES (" .. k .. ", 0)") end
	end

	for k,v in pairs(admins) do
		if botman.dbConnected then conn:execute("INSERT INTO staff (steam, adminLevel) VALUES (" .. k .. ", 1)") end
	end

	for k,v in pairs(mods) do
		if botman.dbConnected then conn:execute("INSERT INTO staff (steam, adminLevel) VALUES (" .. k .. ", 2)") end
	end
end


function matchAll(line, logDate, logTime)
	local pname, pid, number, died, coords, words, temp, msg
	local dy, mth, yr, hr, min, sec, pm, reason, timestamp, banDate
	local fields, values, x, y, z, id, loc, reset, steam, k, v, rows, tmp

	if botman.debugAll then
		debug = true
	end

	-- set counter to help detect the bot going offline
	if not server.useAllocsWebAPI then
		botman.botOfflineCount = 0
		botman.botOffline = false
		botman.lastTelnetResponseTimestamp = os.time()
	end

	if botman.botDisabled then
		return
	end

	if botman.getMetrics then
		metrics.telnetLines = metrics.telnetLines + 1
	end

	if string.find(line, "StackTrace:") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1
		end

		if not debug then
			deleteLine()
		end

		return
	end

	if string.find(line, "ERR ") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1
		end

		if not debug then
			deleteLine()
		end

		return
	end

	-- monitor falling blocks so we can report if it gets excessive in a region
	if string.find(line, "EntityFallingBlock") then
		temp = string.split(line, ",")
		x = string.sub(temp[2], string.find(temp[2], "pos=") + 5)
		y = string.trim(temp[3])
		z = string.trim(string.sub(temp[4], 1, string.len(temp[4]) - 1))
		x = math.floor(x)
		y = math.floor(y)
		z = math.floor(z)

		temp = getRegion(x,z)
		if not fallingBlocks[temp] then
			fallingBlocks[temp] = {}
			fallingBlocks[temp].count = 1
			fallingBlocks[temp].x = x
			fallingBlocks[temp].y = y
			fallingBlocks[temp].z = z
		else
			fallingBlocks[temp].count = fallingBlocks[temp].count + 1
			fallingBlocks[temp].x = x
			fallingBlocks[temp].y = y
			fallingBlocks[temp].z = z
		end

		if not debug then
			deleteLine()
		end
	end

	if string.find(line, "WRN ") then -- ignore lines containing this.
		if not string.find(line, "DENSITYMISMATCH") then

			deleteLine()
			return
		end
	end

	if string.find(line, "NaN") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1
		end

		deleteLine()
		return
	end

	if string.find(line, "Unbalanced") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1
		end

		deleteLine()
		return
	end

	if string.find(line, "->") then -- ignore lines containing this.
		deleteLine()
		return
	end

	if string.find(line, "NullReferenceException:") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1
		end

		deleteLine()
		return
	end


	if customMatchAll ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customMatchAll(line) then
			return
		end
	end


	if string.find(line, "*** ERROR: Executing command 'admin'") then -- abort processing the admin list
		-- abort reading admin list
		getAdminList = nil

		deleteLine()
		return
	end

	if fixChunkDensity then
		if string.find(line, "WRN DENSITYMISMATCH") then
			fixChunkDensity = nil
			temp = string.split(line, "\;")
			sendCommand("rcd " .. temp[2] .. " " .. temp[4] .. " fix")

			deleteLine()
			return
		end
	end

	-- fix deathloop
	if server.coppi and (tonumber(server.coppiVersion) > 4.4 or server.coppiRelease == "Mod Coppis command additions Light") then
		if string.find(line, "Spawned entity with wrong pos") then
			if string.find(line, "type=EntityPlayer") then
				temp = string.split(line, ",")

				pname = string.sub(temp[2], string.find(temp[2], "=") + 1)
				pid = LookupPlayer(string.trim(pname))

				if pid ~= 0 then
					sendCommand("fdl " .. pid)

					irc_chat(server.ircAlerts, "Fixed death loop for player " ..  igplayers[pid].name)
				end
			end
		end
	end

	if string.find(line, "WRN ") then
		deleteLine()
		return
	end


	-- grab the server time
	if string.find(line, "INF ") then
		if string.find(string.sub(line, 1, 19), os.date("%Y")) then
			botman.serverTime = string.sub(line, 1, 10) .. " " .. string.sub(line, 12, 16)
			botman.serverHour = string.sub(line, 12, 13)
			botman.serverMinute = string.sub(line, 15, 16)
			specialDay = ""

			if (string.find(botman.serverTime, "02-14", 5, 10)) then specialDay = "valentine" end
			if (string.find(botman.serverTime, "12-25", 5, 10)) then specialDay = "christmas" end

			if server.dateTest == nil then
				server.dateTest = string.sub(botman.serverTime, 1, 10)
			end
		end
	end


	if not server.useAllocsWebAPI then
		if (string.sub(line, 1, 4) == os.date("%Y")) then
			if botman.readGG then
				botman.readGG = false
			end

			if echoConsole then
				echoConsole = false
				echoConsoleTo = nil
			end

			if getZombies then
				getZombies = nil

				if botman.dbConnected then conn:execute("DELETE FROM gimmeZombies WHERE remove = 1") end
				loadGimmeZombies()

				if botman.dbConnected then conn:execute("DELETE FROM otherEntities WHERE remove = 1") end
				loadOtherEntities()

				if botman.dbConnected then
					cursor,errorString = conn:execute("SELECT Count(entityID) as maxZeds from gimmeZombies")
					row = cursor:fetch({}, "a")
					botman.maxGimmeZombies = tonumber(row.maxZeds)
				end
			end

			if collectBans then
				collectBans = false
			end
		end

		if echoConsole then
			line = line:gsub(",", "") -- strip out commas
			irc_chat(echoConsoleTo, line)
		end
	end


	-- grab steam ID of player joining server if the server is using reserved slots
	if tonumber(server.reservedSlots) > 0 then
		if string.find(line, "INF Steam auth") then
			temp = string.split(line, ",")
			pid = string.sub(temp[3], 12, string.len(temp[3]) -1)

			-- check the slots and how full the server is try to kick a player from a reserved slot
			if players[pid].reserveSlot == true or players[pid].accessLevel < 11 then
				if (botman.dbReservedSlotsUsed >= server.reservedSlots) then
					freeReservedSlot()
				end
			end

			if not debug then
				deleteLine()
			end

			return
		end
	end


	if string.find(line, "PlayerSpawnedInWorld") then
		tmp = {}

		tmp.coords = string.sub(line, string.find(line, "position:") + 10, string.find(line, ")") -1)
		tmp.coords = tmp.coords:gsub(",", "")
		tmp.spawnedReason = "N/A"

		temp = string.split(line, ", ")
		tmp.pid = string.match(temp[5], "(-?%d+)")

		if igplayers[tmp.pid] then
			igplayers[tmp.pid].spawnedInWorld = true

			if igplayers[tmp.pid].spawnedCoordsOld == "0 0 0" then
				igplayers[tmp.pid].spawnedCoordsOld = igplayers[tmp.pid].spawnedCoords
				igplayers[tmp.pid].spawnedCoords = tmp.coords
				igplayers[tmp.pid].spawnChecked = true
			else
				igplayers[tmp.pid].spawnedCoords = tmp.coords

				if igplayers[tmp.pid].spawnedCoordsOld ~= igplayers[tmp.pid].spawnedCoords then
					igplayers[tmp.pid].tp = tonumber(igplayers[tmp.pid].tp) - 1
				end
			end

			temp = string.split(tmp.coords, " ")
			igplayers[tmp.pid].spawnedXPos = temp[1]
			igplayers[tmp.pid].spawnedYPos = temp[2]
			igplayers[tmp.pid].spawnedZPos = temp[3]
		end

		if string.find(line, "reason: Died") then
			tmp.spawnedReason = "died"
			igplayers[tmp.pid].spawnChecked = true
			igplayers[tmp.pid].teleCooldown = 3
		end

		if string.find(line, "reason: JoinMultiplayer") then
			tmp.spawnedReason = "joined"
			igplayers[tmp.pid].spawnChecked = true
			igplayers[tmp.pid].teleCooldown = 3
			irc_chat(server.ircMain, "Player " .. tmp.pid .. " " .. igplayers[tmp.pid].name .. " spawned at " .. igplayers[tmp.pid].spawnedXPos .. " " .. igplayers[tmp.pid].spawnedYPos .. " " .. igplayers[tmp.pid].spawnedZPos)
			irc_chat(server.ircAlerts, "Player " .. tmp.pid .. " " .. igplayers[tmp.pid].name .. " spawned at " .. igplayers[tmp.pid].spawnedXPos .. " " .. igplayers[tmp.pid].spawnedYPos .. " " .. igplayers[tmp.pid].spawnedZPos)
		end

		if string.find(line, "reason: Teleport") then
			tmp.spawnedReason = "teleport"

			if igplayers[tmp.pid].spawnPending then
				igplayers[tmp.pid].spawnChecked = true
			else
				igplayers[tmp.pid].spawnChecked = false
			end
		end

		igplayers[tmp.pid].spawnPending = false
		igplayers[tmp.pid].spawnedReason = tmp.spawnedReason
	end


	if not server.useAllocsWebAPI then
		if string.find(line, "GamePref.") then
			botman.readGG = true
		end
	end


	if string.find(line, "type=Entity") then
		listEntities(line)

		if not debug then
			deleteLine()
		end

		return
	end


	-- Stompy's Mod stuff
	if server.stompy then
		if (string.find(line, "(BCM) Spawn Detected", nil, true)) then
			botman.stompyReportsSpawns = true
			listEntities(line, "BCM")

			if not debug then
				deleteLine()
			end

			return
		end
	end

	-- look for general stuff
	died = false
	if (string.find(line, "INF GMSG") and string.find(line, "eliminated")) then
		nameStart = string.find(line, "eliminated ") + 11
		pname = stripQuotes(string.trim(string.sub(line, nameStart)))
		died = true
	end

	if (string.find(line, "INF GMSG") and string.find(line, "killed by")) then
		nameStart = string.sub(line, string.find(line, "Player ") + 8, string.find(line, "killed by ") - 1)
		pname = stripQuotes(string.trim(nameStart))
		died = true
	end

	if (string.find(line, "INF GMSG: Player") and string.find(line, " died")) then
		pname = string.sub(line, string.find(line, "GMSG") + 14, string.len(line) - 6)
		pname = stripQuotes(string.trim(pname))
		died = true
	end

	if died then
		pid = LookupPlayer(pname, "all")

		if (pid ~= 0) then
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[pid].xPos) .. "," .. math.ceil(igplayers[pid].yPos) .. "," .. math.floor(igplayers[pid].zPos) .. ",'" .. botman.serverTime .. "','death','" .. escape(pname) .. " died'," .. pid .. ")") end

			igplayers[pid].tp = 1
			igplayers[pid].hackerTPScore = 0
			igplayers[pid].deadX = math.floor(igplayers[pid].xPos)
			igplayers[pid].deadY = math.ceil(igplayers[pid].yPos)
			igplayers[pid].deadZ = math.floor(igplayers[pid].zPos)
			igplayers[pid].teleCooldown = 1000
			igplayers[pid].spawnedInWorld = false

			players[pid].deathX = igplayers[pid].xPos
			players[pid].deathY = igplayers[pid].yPos
			players[pid].deathZ = igplayers[pid].zPos

			irc_chat(server.ircMain, "Player " .. pid .. " name: " .. pname .. "'s death recorded at " .. igplayers[pid].deadX .. " " .. igplayers[pid].deadY .. " " .. igplayers[pid].deadZ)
			irc_chat(server.ircAlerts, "Player " .. pid .. " name: " .. pname .. "'s death recorded at " .. igplayers[pid].deadX .. " " .. igplayers[pid].deadY .. " " .. igplayers[pid].deadZ)

			if tonumber(server.packCooldown) > 0 then
				players[pid].packCooldown = os.time() + server.packCooldown
			end

			-- nuke their gimme queue of zeds
			for k, v in pairs(gimmeQueuedCommands) do
				if (v.steam == pid) and (string.find(v.cmd, "se " .. pid)) then
					gimmeQueuedCommands[k] = nil
				end
			end
		end

		if not debug then
			deleteLine()
		end

		return
	end


	if (string.find(line, "ServerMaxPlayerCount set to")) then
		number = tonumber(string.match(line, " (%d+)"))
		server.ServerMaxPlayerCount = number

		if server.maxPlayers == 0 then
			server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

			if tonumber(server.reservedSlots) > 0 then
				sendCommand("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full
			end
		else
			if tonumber(server.maxPlayers) ~= tonumber(server.ServerMaxPlayerCount) - 1 then
				server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

				if tonumber(server.reservedSlots) > 0 then
					sendCommand("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full
				end
			end
		end

		if not debug then
			deleteLine()
		end

		return
	end


	if not server.useAllocsWebAPI then
		if getAdminList then
			if string.sub(line, 1, 3) ~= "   " or string.find(line, 1, 8) == "Total of" then
				getAdminList = nil
				removeOldStaff()

				if not debug then
					deleteLine()
				end

				return
			end
		end

		if getAdminList then
			temp = string.split(line, ":")
			temp[1] = string.trim(temp[1])
			temp[2] = string.trim(string.sub(temp[2], 1, 18))

			number = tonumber(temp[1])
			pid = temp[2]

			if number == 0 then
				owners[pid] = {}
				owners[pid].remove = false
				staffList[pid] = {}
			end

			if number == 1 then
				admins[pid] = {}
				admins[pid].remove = false
				staffList[pid] = {}
			end

			if number == 2 then
				mods[pid] = {}
				mods[pid].remove = false
				staffList[pid] = {}
			end

			if players[pid] then
				players[pid].accessLevel = tonumber(number)
				players[pid].newPlayer = false
				players[pid].silentBob = false
				players[pid].walkies = false
				players[pid].timeout = false
				players[pid].botTimeout = false
				players[pid].prisoner = false
				players[pid].exiled = 2
				players[pid].canTeleport = true
				players[pid].enableTP = true
				players[pid].botHelp = true
				players[pid].hackerScore = 0
				players[pid].testAsPlayer = nil

				if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, silentBob = 0, walkies = 0, exiled = 2, canTeleport = 1, enableTP = 1, botHelp = 1, accessLevel = " .. number .. " WHERE steam = " .. pid) end
			end

			return
		end


		if playerListItems ~= nil then
			if string.find(line, "Listed ") then
				playerListItems = nil
			end

			if not debug then
				deleteLine()
			end

			return
		end


		if ircListItems ~= nil then
			if string.sub(string.trim(line), 1, 5) == "Slot " then
				ircListItems = nil
			end

			if not debug then
				deleteLine()
			end

			return
		end


		if ircListItems ~= nil then
			if string.sub(line,1,4) == "    " and string.sub(line,5,5) ~= " " then
				irc_chat(players[ircListItems].ircAlias, string.trim(line))
			end
		end


		if playerListItems ~= nil then
			if string.sub(line,1,4) == "    " and string.sub(line,5,5) ~= " " then
				message("pm " .. playerListItems .. " [" .. server.chatColour .. "]" .. string.trim(line) .. "[-]")
			end
		end


		-- collect the ban list
		if collectBans then
			if not string.find(line, "banned until") then
				temp = string.split(line, "-")
				bannedTo = string.trim(temp[1] .. "-" .. temp[2] .. "-" .. temp[3])
				steam = string.trim(temp[4])
				reason = string.trim(temp[5])

				if botman.dbConnected then
					conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. bannedTo .. "'," .. steam .. ",'" .. escape(reason) .. "',STR_TO_DATE('" .. bannedTo .. "', '%Y-%m-%d %H:%i:%s'))")

					if players[steam] then
						-- also insert the steam owner (will only work if the steam id is different)
						conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. bannedTo .. "'," .. players[steam].steamOwner .. ",'" .. escape(reason) .. "',STR_TO_DATE('" .. bannedTo .. "', '%Y-%m-%d %H:%i:%s'))")
					end
				end
			end
		end


		-- get zombies into table gimmeZombies
		if getZombies ~= nil then
			if string.find(line, "ombie") then
				temp = string.split(line, "-")

				local entityID = string.trim(temp[1])
				local zombie = string.trim(temp[2])

				if botman.dbConnected then conn:execute("INSERT INTO gimmeZombies (zombie, entityID) VALUES ('" .. zombie .. "'," .. entityID .. ") ON DUPLICATE KEY UPDATE remove = 0") end
				updateGimmeZombies(entityID, zombie)
			else
				if (string.sub(line, 1, 4) ~= os.date("%Y")) then
					temp = string.split(line, "-")

					local entityID = string.trim(temp[1])
					local entity = string.trim(temp[2])

					if botman.dbConnected then conn:execute("INSERT INTO otherEntities (entity, entityID) VALUES ('" .. entity .. "'," .. entityID .. ")") end
					updateOtherEntities(entityID, entity)
				end
			end
		end


		if botman.listItems and playerListItems == nil then
			if string.find(line, " matching items.") then
				botman.listItems = false
			else
				if botman.dbConnected then
					temp = string.trim(line)
					conn:execute("INSERT INTO spawnableItems (itemName) VALUES ('" .. escape(temp) .. "')")
				end
			end
		end


		if echoConsoleTo ~= nil then
			if string.find(line, "Executing command 'webpermission list") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'lpf") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'lpb") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'lps") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'SystemInfo") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'traderlist") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'help") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'version") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'le'") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'li ") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'se'") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'si ") and string.find(line, server.botsIP) and string.find(line, echoConsoleTrigger) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'gg'") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'ggs'") and string.find(line, server.botsIP) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'llp") and string.find(line, server.botsIP) then
				echoConsole = true
				conn:execute("DELETE FROM keystones WHERE x = 0 AND y = 0 AND z = 0")
			end

			if string.find(line, "Executing command 'ban list'") and string.find(line, server.botsIP) then
				echoConsole = true
			end
		end
	end


	if server.coppi and not server.playersCanFly then
		if string.find(line, "PUG: entity_id") then
			words = {}
			for word in string.gmatch(line, "(-?%d+)") do
				table.insert(words, word)
			end

			pid = words[1]
			pid = LookupPlayer(pid)

			x = math.floor(igplayers[pid].xPos)
			y = math.floor(igplayers[pid].yPos)
			z = math.floor(igplayers[pid].zPos)

			if string.find(line, "isUnderGround=True") and accessLevel(pid) > 2 then
				igplayers[pid].noclip = true

				if igplayers[pid].noclipX == 0 and igplayers[pid].noclipZ == 0 then
					igplayers[pid].noclipX = x
					igplayers[pid].noclipY = y
					igplayers[pid].noclipZ = z
				else
					-- dist is horizontal distance travelled since last detection
					dist = distancexyz(x, y, z, igplayers[pid].noclipX, igplayers[pid].noclipY, igplayers[pid].noclipZ)

					-- update coords
					igplayers[pid].noclipX = x
					igplayers[pid].noclipY = y
					igplayers[pid].noclipZ = z

					if igplayers[pid].noclipCount == nil then
						igplayers[pid].noclipCount = 1
					end

					if tonumber(dist) > 30 then
						igplayers[pid].hackerDetection = "noclipping"

						if players[pid].newPlayer then
							players[pid].hackerScore = tonumber(players[pid].hackerScore) + 20
						else
							players[pid].hackerScore = tonumber(players[pid].hackerScore) + 10
						end

						alertAdmins("[" .. server.alertColour .. "]Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. "[-]", "warn")
						irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
						irc_chat(server.ircAlerts, "Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
					else
						if igplayers[pid].noclipX == x and igplayers[pid].noclipY == y and igplayers[pid].noclipZ == z then
							if igplayers[pid].lastHackerAlert == nil then
								igplayers[pid].lastHackerAlert = os.time()

								irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								irc_chat(server.ircAlerts, server.gameDate .. " player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								alertAdmins("[" .. server.alertColour .. "]Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist) .. "[-]", "warn")
							end

							if tonumber(os.time() - igplayers[pid].lastHackerAlert) > 120 then
								igplayers[pid].lastHackerAlert = os.time()
								irc_chat(server.ircAlerts, server.gameDate .. " player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].sessionCount .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								alertAdmins("[" .. server.alertColour .. "]Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z ..  " moved " .. string.format("%d", dist) .. "[-]", "warn")
							end
						end
					end

					igplayers[pid].noclipCount = tonumber(igplayers[pid].noclipCount) + 1
				end
			else
				igplayers[pid].noclip = false

				-- update coords anyway
				igplayers[pid].noclipX = x
				igplayers[pid].noclipY = y
				igplayers[pid].noclipZ = z
			end

			if not debug then
				deleteLine()
			end

			return
		end


		if string.find(line, "PGD: entity_id") then
			words = {}
			for word in string.gmatch(line, "(-?%d+)") do
				table.insert(words, word)
			end

			pid = words[1]
			pid = LookupPlayer(pid)
			igplayers[pid].flying = false
			dist = tonumber(words[2]) -- distance above ground
			igplayers[pid].flyingHeight = dist

			x = math.floor(igplayers[pid].xPos)
			y = math.floor(igplayers[pid].yPos)
			z = math.floor(igplayers[pid].zPos)

			if tonumber(dist) > 5 and accessLevel(pid) > 2 then
				if not players[pid].timeout and not players[pid].botTimeout and igplayers[pid].lastTP == nil and not players[pid].ignorePlayer then
					igplayers[pid].flying = true

					if igplayers[pid].flyingX == 0 then
						igplayers[pid].flyingX = x
						igplayers[pid].flyingY = y
						igplayers[pid].flyingZ = z
					else
						-- distance of travel horizontally
						dist = distancexz(x, z, igplayers[pid].flyingX, igplayers[pid].flyingZ)

						-- update coords
						igplayers[pid].flyingX = x
						igplayers[pid].flyingY = y
						igplayers[pid].flyingZ = z

						if tonumber(dist) > 30 then
							if players[pid].newPlayer then
								players[pid].hackerScore = tonumber(players[pid].hackerScore) + 20
							else
								players[pid].hackerScore = tonumber(players[pid].hackerScore) + 10
							end
						end

						if tonumber(dist) > 5 then
							igplayers[pid].flyCount = igplayers[pid].flyCount + 1
							igplayers[pid].hackerDetection = "flying"

							if tonumber(igplayers[pid].flyCount) > 1 then
								irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].sessionCount .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z)
								irc_chat(server.ircAlerts, server.gameDate .. " player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].sessionCount .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								alertAdmins("[" .. server.alertColour .. "]Player " .. pid .. " " .. igplayers[pid].name .. " may be flying (count: " .. igplayers[pid].flyCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist) .. "[-]", "warn")
							end
						else
							if igplayers[pid].flyingX == x and igplayers[pid].flyingY == y and igplayers[pid].flyingZ == z then
								if igplayers[pid].lastHackerAlert == nil then
									igplayers[pid].lastHackerAlert = os.time()

									alertAdmins("[" .. server.alertColour .. "]Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist) .. "[-]", "warn")
									irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z)
									irc_chat(server.ircAlerts, server.gameDate .. " player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								end

								if os.time() - igplayers[pid].lastHackerAlert > 120 then
									alertAdmins("[" .. server.alertColour .. "]Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist) .. "[-]", "warn")
									irc_chat(server.ircAlerts, server.gameDate .. " player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								end
							end
						end
					end
				end
			end

			if not igplayers[pid].noclip and not igplayers[pid].flying then
				if tonumber(players[pid].hackerScore) > 0 then
					players[pid].hackerScore = tonumber(players[pid].hackerScore) - 5
				end
			end

			if not debug then
				deleteLine()
			end

			return
		end
	end

	-- ===================================
	-- infrequent telnet events below here
	-- ===================================

	if not server.useAllocsWebAPI then
		if string.find(line, "Executing command 'le'") then
			if string.find(line, server.botsIP) then
				botman.listEntities = true
				botman.lastListEntities = os.time()
				conn:execute("TRUNCATE memEntities")
			end

			if not debug then
				deleteLine()
			end

			return
		end


		if string.find(line, "Executing command 'li ") then
			if string.find(line, server.botsIP) and playerListItems == nil then
				botman.listItems = true
			end

			if not debug then
				deleteLine()
			end

			return
		end


		if string.find(line, "Executing command 'version'") and server.botsIP then
			if string.find(line, server.botsIP) then
				modVersions = {}
				server.allocs = false
				server.coppi = false
				server.csmm = false
				server.stompy = false
				server.SDXDetected = false
				server.ServerToolsDetected = false
				server.djkrose = false

				if botman.dbConnected then
					conn:execute("UPDATE server SET SDXDetected = 0, ServerToolsDetected = 0")
				end

				if not debug then
					deleteLine()
				end

				return
			end
		end


		if string.find(line, "Executing command 'admin list'") and server.botsIP then
			if string.find(line, server.botsIP) then
				flagAdminsForRemoval()

				if not debug then
					deleteLine()
				end

				return
			end
		end


		if (string.find(line, "Banned until -")) then
			collectBans = true
			conn:execute("TRUNCATE bans")

			if not debug then
				deleteLine()
			end

			return
		end


		-- update owners, admins and mods
		if string.find(line, "Level: SteamID (Player name if online)", nil, true) then
			getAdminList = true
			staffList = {}

			if not debug then
				deleteLine()
			end

			return
		end
	end


	if botman.readGG then
		number = tonumber(string.match(line, " (%d+)"))

		if (string.find(line, "HideCommandExecutionLog =")) then
			server.HideCommandExecutionLog = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "MaxSpawnedZombies set to")) then
			server.MaxSpawnedZombies = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "MaxSpawnedAnimals set to")) then
			server.MaxSpawnedAnimals = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "LootRespawnDays =")) then
			server.LootRespawnDays = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "BlockDurabilityModifier =")) then
			server.BlockDurabilityModifier = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "DayNightLength =")) then
			server.DayNightLength = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "DayLightLength =")) then
			server.DayLightLength = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "DropOnDeath =")) then
			server.DropOnDeath = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "DropOnQuit =")) then
			server.DropOnQuit = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "EnemyDifficulty =")) then
			server.EnemyDifficulty = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "LandClaimSize =")) then
			server.LandClaimSize = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "LandClaimExpiryTime =")) then
			server.LandClaimExpiryTime = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "LootAbundance =")) then
			server.LootAbundance = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "LootRespawnDays =")) then
			server.LootRespawnDays = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "ServerPort =")) then
			server.ServerPort = number
			if botman.dbConnected then conn:execute("UPDATE server SET serverName = '" .. escape(server.serverName) .. "', ServerPort = " .. server.ServerPort) end

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "ZombiesRun =")) then
			server.ZombiesRun = number

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "ServerName =")) then
			server.serverName = string.trim(string.sub(line, 22))

			if string.find(string.lower(server.serverName), "pvp") and not string.find(string.lower(server.serverName), "pve") then
				server.gameType = "pvp"
			end

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "GameName =")) then
			server.GameName = string.trim(string.sub(line, 20))

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "ServerMaxPlayerCount =")) then
			number = tonumber(string.match(line, " (%d+)"))
			server.ServerMaxPlayerCount = number

			if server.maxPlayers == 0 then
				server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

				if server.reservedSlots > 0 then
					sendCommand("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full
				end
			else
				if tonumber(server.maxPlayers) ~= tonumber(server.ServerMaxPlayerCount) - 1 then
					server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

					if tonumber(server.reservedSlots) > 0 then
						sendCommand("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full
					end
				end
			end

			if not debug then
				deleteLine()
			end

			return
		end

		if (string.find(line, "MaxSpawnedZombies =")) then
			server.MaxSpawnedZombies = number
			-- If we detect this line it means we are receiving data from the server so we set a flag to let us know elsewhere that we got server data ok.
			serverDataLoaded = true

			if not debug then
				deleteLine()
			end

			return
		end
	end


	if string.sub(line, 1, 4) == "Mod " then
		modVersions[line] = {}
	end


	-- detect CSMM Patrons Mod
	if string.find(line, "Mod CSMM Patrons") then
		server.coppi = true
		server.csmm = true

		temp = string.split(line, ":")
		server.coppiRelease = temp[1]
		server.coppiVersion = temp[2]

		if server.hideCommands then
			sendCommand("tcch " .. server.commandPrefix)
		end

		if not debug then
			deleteLine()
		end

		return
	end


	-- detect Coppi's Mod
	if string.find(line, "Mod Coppis command additions") then
		server.coppi = true


		temp = string.split(line, ":")
		server.coppiRelease = temp[1]
		server.coppiVersion = temp[2]

		if server.hideCommands then
			sendCommand("tcch " .. server.commandPrefix)
		end

		if not debug then
			deleteLine()
		end

		return
	end


	-- detect Alloc's Mod
	if string.find(line, "Mod Allocs server fixes") then
		server.allocs = true
		temp = string.split(line, ":")
		server.allocsServerFixes = temp[2]

		if not debug then
			deleteLine()
		end

		return
	end


	if string.find(line, "Mod Allocs command extensions") then
		server.allocs = true
		temp = string.split(line, ":")
		server.allocsCommandExtensions = temp[2]

		if not debug then
			deleteLine()
		end

		return
	end


	if string.find(line, "Mod Allocs MapRendering") then
		server.allocs = true
		temp = string.split(line, ":")
		server.allocsMap = temp[2]

		if not debug then
			deleteLine()
		end

		return
	end


	if (string.find(line, "please specify one of the entities")) then
		-- flag all the zombies for removal so we can detect deleted zeds
		if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET remove = 1") end
		if botman.dbConnected then conn:execute("UPDATE otherEntities SET remove = 1") end

		getZombies = true

		if not debug then
			deleteLine()
		end

		return
	end


	if string.find(line, "command 'rcd") then
		if string.find(line, server.botsIP) then
			fixChunkDensity = true
		end

		deleteLine()
		return
	end


	if string.find(line, "INF Server shutting down!") or string.find(line, "INF [Steamworks.NET] Stopping server") then
		saveLuaTables()

		if not debug then
			deleteLine()
		end

		return
	end

	if string.find(line, "ERROR: unknown command 'pug'") then
		server.scanNoclip = false

		if not debug then
			deleteLine()
		end

		return
	end


	-- detect server version
	if string.find(line, "Game version:") then
		server.gameVersion = string.trim(string.sub(line, string.find(line, "Game version:") + 14, string.find(line, "Compatibility") - 2))
		if botman.dbConnected then conn:execute("UPDATE server SET gameVersion = '" .. escape(server.gameVersion) .. "'") end

		if not debug then
			deleteLine()
		end

		return
	end

	-- detect Stompy's API mod
	if string.find(line, "Mod Bad Company Manager:") then
		server.stompy = true
		temp = string.split(line, ":")
		server.stompyVersion = temp[2]

		if not debug then
			deleteLine()
		end

		return
	end

	-- detect djkrose's scripting mod
	if string.find(line, "Mod djkrose's Scripting Mod:") then
		server.djkrose = true
		temp = string.split(line, ":")
		server.djkroseVersion = temp[2]

		if not debug then
			deleteLine()
		end

		return
	end

	-- detect Jims_Commands mod
	if string.find(line, "Mod Jims_Commands") then
		server.JimsCommands = true
		temp = string.split(line, ":")
		server.JimsCommandsVersion = temp[2]

		if not debug then
			deleteLine()
		end

		return
	end

	-- detect SDX mods
	if string.find(line, "Mod SDX:") or string.find(line, "SDX: ") and not server.SDXDetected then
		server.SDXDetected = true
		if botman.dbConnected then conn:execute("UPDATE server SET SDXDetected = 1") end

		if not debug then
			deleteLine()
		end

		return
	end

	-- detect server tools
	if string.find(line, "Mod Server Tools:") or string.find(line, "mod 'Server Tools'") and not server.ServerToolsDetected then
		server.ServerToolsDetected = true
		if botman.dbConnected then conn:execute("UPDATE server SET ServerToolsDetected = 1") end

		if not debug then
			deleteLine()
		end

		return
	end

	-- detect CBSM
	if string.find(line, "pm CBSM") and server.CBSMFriendly then
		if server.commandPrefix == "/" then
			message("say [" .. server.chatColour .. "]CBSM detected.  Bot commands now begin with a ! to not clash with CBSM commands.[-]")
			message("say [" .. server.chatColour .. "]To use bot commands such as /who you must now type !who[-]")
			server.commandPrefix = "!"
			if botman.dbConnected then conn:execute("UPDATE server SET commandPrefix = '!'") end

			if not debug then
				deleteLine()
			end

			return
		end
	end


	if server.coppi then
		-- player bed
		if string.sub(line, 1, 11) == "PlayerBed: " then
			local name = string.sub(line, 12, string.find(line, " at ") - 1)
			steam = LookupPlayer(name)

			if steam then
				local split = string.split(string.sub(line, string.find(line, " at ") + 4), ",")
				x = string.trim(split[1])
				y = string.trim(split[2])
				z = string.trim(split[3])

				players[steam].bedX = x
				players[steam].bedY = y
				players[steam].bedZ = z
				if botman.dbConnected then conn:execute("UPDATE players SET bedX = " .. x .. ", bedY = " .. y .. ", bedZ = " .. z .. " WHERE steam = " .. steam) end
			end

			if not debug then
				deleteLine()
			end

			return
		end
	end


	if (string.find(line, "Process chat error")) then
		irc_chat(server.ircAlerts, "Server error detected. Re-validate to fix: " .. line)

		if not debug then
			deleteLine()
		end
	end


	-- check for lag
	if string.find(line, "pm LagCheck ") and string.find(line, server.botsIP) then
		temp = string.split(line, "'")
		timestamp = tonumber(string.match(temp[2], " (%d+)"))

		server.lagged = false
		local lag = os.time() - timestamp

		if botman.getMetrics then
			metrics.telnetCommandLag = lag
		end

		if tonumber(lag) > 7 then
			server.lagged = true
		end

		deleteLine()
		return
	end


	if string.find(line, "Playername or entity ID not found.") then
		deleteLine()

		if not debug then
			deleteLine()
		end

		return
	end


	if string.find(line, "bot_RemoveInvalidItems") then
		removeInvalidItems()

		if not debug then
			deleteLine()
		end

		return
	end


	if string.find(line, "Version mismatch") then
		irc_chat(server.ircAlerts, line)

		if not debug then
			deleteLine()
		end

		return
	end


	if string.find(line, "ERR EXCEPTION:") and string.find(line, "Cannot expand this MemoryStream") and not botman.serverErrorReported then
		-- report memory error
		botman.serverErrorReported = true
		irc_chat(server.ircAlerts, "Server error detected.")
		irc_chat(server.ircAlerts, line)

		if not debug then
			deleteLine()
		end

		return
	end


	if (string.find(line, "INF [NET] ServerShutdown") or string.find(line, "INF World.Unload")) and not string.find(line, "Chat") then
		botman.botOffline = true

		if not debug then
			deleteLine()
		end

		return
	end


	if string.find(line, "INF Loading permissions file done") then
		if not string.find(botman.lastBotCommand, "webtokens") then
			sendCommand("admin list")
		end

		if not debug then
			deleteLine()
		end

		return
	end

	if not debug then
		deleteLine()
	end
end

