--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

local debug

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false -- should be false unless testing

function matchAll(line, logDate, logTime)
	local pname, pid, number, died, coords, words, temp, test, msg, claimRemoved, web
	local dy, mth, yr, hr, min, sec, pm, reason, timestamp, banDate
	local fields, values, x, y, z, id, loc, reset, steam, k, v, rows, tmp
	local pref, value, isChat, cmd
	local cursor, status, errorString


	if botman.debugAll then
		--debug = true
	end

	if string.find(line, "WRN ") or string.find(line, "ERR ") then
		if not botStatus.telnetSpamCount then
			botStatus.telnetSpamCount = 0
		end

		botStatus.telnetSpamCount = botStatus.telnetSpamCount + 1
	end

	if botStatus.safeMode then
		return
	end

	if string.find(line, "WRN Invalid Admintoken used from", nil, true) then
		if string.find(line, server.botsIP, nil, true) then
			if server.useAllocsWebAPI then
				botman.APIOffline = false
				toggleTriggers("api offline")
			end

			if not botman.lastAPIConnect then
				connectToAPI()
				botman.lastAPIConnect = os.time()
			else
				if os.time() - botman.lastAPIConnect > 60 then
					connectToAPI()
					botman.lastAPIConnect = os.time()
				end
			end

			return
		end
	end

	if string.find(line, "WRN ") then
		return
	end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	web = "webtokens"

	if string.find(line, "VehicleManager") then
		return
	end

	if string.find(line, "Steamworks.NET") then
		return
	end

	if string.find(line, "KeyNotFoundException") then
		return
	end

	-- set counter to help detect the bot going offline
	botman.botOfflineCount = 0
	botman.botOffline = false
	botman.lastServerResponseTimestamp = os.time()

	isChat = false
	tmp = {}

	if botman.getMetrics then
		metrics.telnetLines = metrics.telnetLines + 1
	end

	if string.find(line, "StackTrace:") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1

			if not metrics.errorStackTrace then
				metrics.errorStackTrace = true
				metrics.errorLines[metrics.errorLinesCount] = line
				metrics.errorLinesCount = metrics.errorLinesCount + 1
			end
		end

		return
	end

	if string.find(line, "SleeperVolume") then -- ignore lines containing this.
		return
	end

	if string.find(line, "ERR ") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1

			if not metrics.errorERR then
				metrics.errorERR = true
				metrics.errorLines[metrics.errorLinesCount] = line
				metrics.errorLinesCount = metrics.errorLinesCount + 1
			end
		end

		return
	end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

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

		return
	end

	if string.find(line, "NaN") then -- ignore lines containing this.
		return
	end

	if string.find(line, "INF Delta out") then -- ignore lines containing this.
		return
	end

	if string.find(line, "INF Missing ") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1
		end

		return
	end

	if string.find(line, "INF Error ") then -- ignore lines containing this.
		return
	end

	if string.find(line, "IndexOutOfRangeException") then -- ignore lines containing this.
		return
	end

	if string.find(line, "Unbalanced") then -- ignore lines containing this.
		return
	end

	if string.find(line, "->") then -- ignore lines containing this.
		return
	end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "NullReferenceException:") then -- ignore lines containing this.
		if botman.nullRefDetectedDelay then
			if botman.nullRefDetectedDelay < os.time() then
				botman.nullRefDetectedDelay = nil
				botman.nullrefDetected = true
				sendCommand("le")
			end
		else
			if not botman.nullrefDetected then
				botman.nullrefDetected = true
				sendCommand("le")
			end
		end

		return
	end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if server.readLogUsingTelnet then
		logTelnet(line)
	end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "Chat") then
		isChat = true
	end

	if customMatchAll ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customMatchAll(line) then

			return
		end
	end

	if string.find(line, "*** ERROR: unknown command 'webtokens") then -- revert to using telnet
		if server.readLogUsingTelnet then
			if server.useAllocsWebAPI then
				server.useAllocsWebAPI = false
				conn:execute("UPDATE server set useAllocsWebAPI = 0")
				irc_chat(server.ircAlerts, "Alloc's mod missing or not fully installed.  The bot is using telnet instead.")
				toggleTriggers("api offline")
			end
		else
			irc_chat(server.ircAlerts, "ALERT: Alloc's mod missing or not fully installed. The bot is not using telnet and cannot communicate with the server.")
			irc_chat(server.ircAlerts, "Please check that Aloc's mod is installed and it's 3 dll files are present.")
		end

		return
	end


	if string.find(line, "*** ERROR: Executing command 'admin'", nil, true) then -- abort processing the admin list
		-- abort reading admin list
		getAdminList = nil

		return
	end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	-- grab the server time
	if string.find(line, "INF ") then
		if string.find(string.sub(line, 1, 19), os.date("%Y")) then
			botman.serverTime = string.sub(line, 1, 10) .. " " .. string.sub(line, 12, 19)
			botman.serverTimeStamp = dateToTimestamp(botman.serverTime)

			if not botman.serverTimeSync then
				botman.serverTimeSync = 0
			end

			botman.serverTimeSync = -(os.time() - botman.serverTimeStamp)

			-- if botman.serverTimeStamp == 0 then
				-- botman.serverTimeStamp = dateToTimestamp(botman.serverTime)

				-- if not botman.serverTimeSync then
					-- botman.serverTimeSync = 0
				-- end

				-- if botman.serverTimeSync == 0 then
					-- botman.serverTimeSync = -(os.time() - botman.serverTimeStamp)
				-- end
			-- end

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

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if (string.sub(line, 1, 4) == os.date("%Y")) then
		badPlayerJoined = false
		badJoinLine = ""

		if readAnticheat then
			readAnticheat = nil
		end

		if botman.readGG then
			botman.readGG = false -- must be false not nil

			if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('GamePrefs','panel','" .. escape(yajl.to_string(GamePrefs)) .. "')") end

			if tonumber(server.reservedSlots) > 0 then
				if botman.initReservedSlots then
					initSlots()
					botman.initReservedSlots = false
				else
					-- setup or adjust the number of slots in the slots table
					addOrRemoveSlots()
				end
			end
		end
	end

	if not server.useAllocsWebAPI then
		if (string.sub(line, 1, 4) == os.date("%Y")) then
			if echoConsole then
				echoConsole = false
				echoConsoleTo = nil
			end

			if readResetRegions then
				tempTimer(3, [[loadResetZones(true)]])
			end

			readResetRegions = nil

			if getZombies then
				getZombies = nil

				if botman.dbConnected then conn:execute("DELETE FROM gimmeZombies WHERE remove = 1 OR zombie LIKE '%Template%'") end
				loadGimmeZombies()

				if botman.dbConnected then conn:execute("DELETE FROM otherEntities WHERE remove = 1 OR entity LIKE '%Template%' OR entity LIKE '%invisible%'") end
				loadOtherEntities()
			end

			if collectBans then
				collectBans = false
				loadBans()
			end

			if readVersion then
				readVersion = nil
				resetVersion = nil
				table.save(homedir .. "/data_backup/modVersions.lua", modVersions)
				if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('modVersions','panel','" .. escape(yajl.to_string(modVersions)) .. "')") end

				if server.allocs and server.botman then
					botMaintenance.modsInstalled = true
				else
					botMaintenance.modsInstalled = false
				end

				if botman.dbConnected then conn:execute("DELETE FROM webInterfaceJSON WHERE ident = 'modVersions'") end
				if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('modVersions','panel','" .. escape(yajl.to_string(modVersions)) .. "')") end
				saveBotMaintenance()
			end
		end

		if echoConsole and echoConsoleTo then
			line = line:gsub(",", "") -- strip out commas
			irc_chat(echoConsoleTo, line)
		end
	end

	if string.find(line, "AIDirector: Spawning Scouts") and server.enableScreamerAlert then
		scoutsWarning(line)
		return
	end

	if string.find(line, "PlayerSpawnedInWorld") then
		tmp.coords = string.sub(line, string.find(line, "position:") + 10, string.find(line, ")") -1)
		tmp.coords = tmp.coords:gsub(",", "")
		tmp.spawnedReason = "N/A"

		temp = string.split(line, ", ")
		tmp.temp = string.split(temp[5], "_")
		tmp.steam = stripAllQuotes(tmp.temp[2])
		tmp.playerName = string.split(temp[8], "=")
		tmp.playerName = string.sub(tmp.playerName[2], 2, string.len(tmp.playerName[2]) - 1)

		if igplayers[tmp.steam] then
			igplayers[tmp.steam].spawnedInWorld = true

			if igplayers[tmp.steam].spawnedCoordsOld == "0 0 0" then
				igplayers[tmp.steam].spawnedCoordsOld = igplayers[tmp.steam].spawnedCoords
				igplayers[tmp.steam].spawnedCoords = tmp.coords
				igplayers[tmp.steam].spawnChecked = true
			else
				igplayers[tmp.steam].spawnedCoords = tmp.coords

				if igplayers[tmp.steam].spawnedCoordsOld ~= igplayers[tmp.steam].spawnedCoords then
					igplayers[tmp.steam].tp = tonumber(igplayers[tmp.steam].tp) - 1
				end

				if string.sub(players[tmp.steam].lastCommand, 2, 4) == "bag" then
					igplayers[tmp.steam].tp = tonumber(igplayers[tmp.steam].tp) + 1
					igplayers[tmp.steam].spawnChecked = true
				end
			end

			temp = string.split(tmp.coords, " ")
			igplayers[tmp.steam].spawnedXPos = temp[1]
			igplayers[tmp.steam].spawnedYPos = temp[2]
			igplayers[tmp.steam].spawnedZPos = temp[3]
		end

		if string.find(line, "reason: Died") then
			tmp.spawnedReason = "died"
			igplayers[tmp.steam].spawnChecked = true
			igplayers[tmp.steam].teleCooldown = 3
		end

		if string.find(line, "reason: JoinMultiplayer") then
			tmp.spawnedReason = "joined"
			igplayers[tmp.steam].spawnChecked = true
			igplayers[tmp.steam].teleCooldown = 3
			irc_chat(server.ircMain, "Player " .. tmp.steam .. " " .. tmp.playerName .. " spawned at " .. igplayers[tmp.steam].spawnedXPos .. " " .. igplayers[tmp.steam].spawnedYPos .. " " .. igplayers[tmp.steam].spawnedZPos)
			irc_chat(server.ircAlerts, "Player " .. tmp.steam .. " " .. tmp.playerName .. " spawned at " .. igplayers[tmp.steam].spawnedXPos .. " " .. igplayers[tmp.steam].spawnedYPos .. " " .. igplayers[tmp.steam].spawnedZPos)

			if players[tmp.steam].accessLevel == 0 and not server.allocs and not botman.botDisabled then
				message("pm " .. igplayers[tmp.steam].userID .. " [" .. server.warnColour .. "]ALERT! The bot requires Alloc's mod but it appears to be missing. The bot will not work well without it :([-]")
			end

			if server.botman then
				if players[tmp.steam].nameOverride ~= "" then
					setOverrideChatName(tmp.steam, players[tmp.steam].nameOverride)
				end

				tmp.namePrefix = LookupSettingValue(tmp.steam, "namePrefix")

				if tmp.namePrefix ~= "" then
					setOverrideChatName(tmp.steam, tmp.namePrefix .. players[tmp.steam].name)
				end
			end
		end

		if string.find(line, "reason: Teleport") then
			tmp.spawnedReason = "teleport"

			if igplayers[tmp.steam].spawnPending then
				igplayers[tmp.steam].spawnChecked = true
			else
				igplayers[tmp.steam].spawnChecked = false
			end
		end

		igplayers[tmp.steam].spawnPending = false
		igplayers[tmp.steam].spawnedReason = tmp.spawnedReason
	end


	if string.find(line, "GamePref.", nil, true) then
		if not botman.readGG then
			GamePrefs = {}
		end

		botman.readGG = true
	end


	if string.find(line, "type=Entity") then
		listEntities(line)

		return
	end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

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

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end


	if (string.find(line, "GMSG: Player") and string.find(line, " died")) then
		pname = string.sub(line, string.find(line, "GMSG") + 14, string.len(line) - 6)
		pname = stripQuotes(string.trim(pname))
		died = true
	end

	if died then
		tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(pname, "all")

		if (tmp.steam ~= "0") then
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. igplayers[tmp.steam].xPos .. "," .. igplayers[tmp.steam].yPos .. "," .. igplayers[tmp.steam].zPos .. ",'" .. botman.serverTime .. "','death','" .. escape(pname) .. " died','" .. tmp.steam .. "')") end

			igplayers[tmp.steam].tp = 1
			igplayers[tmp.steam].hackerTPScore = 0
			igplayers[tmp.steam].deadX = igplayers[tmp.steam].xPos
			igplayers[tmp.steam].deadY = igplayers[tmp.steam].yPos
			igplayers[tmp.steam].deadZ = igplayers[tmp.steam].zPos
			igplayers[tmp.steam].teleCooldown = 1000
			igplayers[tmp.steam].spawnedInWorld = false

			players[tmp.steam].deathX = igplayers[tmp.steam].xPos
			players[tmp.steam].deathY = igplayers[tmp.steam].yPos
			players[tmp.steam].deathZ = igplayers[tmp.steam].zPos

			tmp.deathCost = LookupSettingValue(tmp.steam, "deathCost")

			if tonumber(tmp.deathCost) > 0 then
				players[tmp.steam].cash = tonumber(players[tmp.steam].cash) - tmp.deathCost

				if tonumber(players[tmp.steam].cash) < 0 then
					players[tmp.steam].cash = 0
				end
			end

			irc_chat(server.ircMain, "Player " .. tmp.steam .. " name: " .. pname .. "'s death recorded at " .. igplayers[tmp.steam].deadX .. " " .. igplayers[tmp.steam].deadY .. " " .. igplayers[tmp.steam].deadZ)
			irc_chat(server.ircAlerts, "Player " .. tmp.steam .. " name: " .. pname .. "'s death recorded at " .. igplayers[tmp.steam].deadX .. " " .. igplayers[tmp.steam].deadY .. " " .. igplayers[tmp.steam].deadZ)

			tmp.packCooldown = LookupSettingValue(tmp.steam, "packCooldown")
			players[tmp.steam].packCooldown = os.time() + tmp.packCooldown

			-- nuke their gimme queue of zeds
			for k, v in pairs(gimmeQueuedCommands) do
				if (v.steam == tmp.steam) and (string.find(v.cmd, "se " .. tmp.steam)) then
					gimmeQueuedCommands[k] = nil
				end
			end
		end

		return
	end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "INF BloodMoon starting") or string.find(line, "INF BloodMoonParty") and not isChat then
		server.delayReboot = true

		if botman.scheduledRestart then
			if tonumber(server.feralRebootDelay) == 0 then
				botman.scheduledRestartTimestamp = os.time() + ((server.DayLightLength + server.DayNightLength) * 60)
			else
				botman.scheduledRestartTimestamp = os.time() + (server.feralRebootDelay * 60)
			end
		end
	end

	if (string.find(line, "ServerMaxPlayerCount set to")) then
		number = tonumber(string.match(line, " (%d+)"))
		server.ServerMaxPlayerCount = number

		if server.maxPlayers == 0 then
			server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

			if botman.dbConnected then
				conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
			end
		else
			if tonumber(server.maxPlayers) ~= tonumber(server.ServerMaxPlayerCount) - 1 then
				server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

				if botman.dbConnected then
					conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
				end
			end
		end

		return
	end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if not server.useAllocsWebAPI then
		if getAdminList then
			if string.sub(line, 1, 3) ~= "   " or string.find(line, "Defined Group Permissions") or string.find(line, 1, 8) == "Total of" then
				getAdminList = nil

				return
			end
		end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

		if readBotmanConfig then
			if string.find(line, "</Botman>", nil, true) then
				readBotmanConfig = nil
				table.insert(botman.config, line)
				processBotmanConfig()

				return
			end

			table.insert(botman.config, line)
		end


		if getAdminList then
			conn:execute("DELETE FROM staff WHERE adminLevel > " .. server.maxAdminLevel)

			line = string.trim(line)
			tmp.temp = string.split(line, ":")
			tmp.accessLevel = tonumber(string.trim(tmp.temp[1]))
			tmp.temp[2] = string.trim(tmp.temp[2])
			tmp.name = string.sub(tmp.temp[3], 2, string.len(tmp.temp[3]) - 1)
			tmp.platform = ""

			if not tmp.name then
				tmp.name = ""
			end

			if string.find(tmp.temp[2], "EOS") then
				tmp.userID = string.split(tmp.temp[2], " ")
				tmp.userID = tmp.userID[1]
				tmp.steamLU, tmp.steamOwnerLU, tmp.userIDLU, tmp.platformLU = LookupPlayer(tmp.userID)

				if tmp.steamLU ~= "0" and tmp.steamLU ~= "" then
					tmp.steam = tmp.steamLU
					tmp.userID = tmp.userIDLU
					tmp.platform = tmp.platformLU
				end
			else
				tmp.temp = string.split(tmp.temp[2], " ")
				tmp.temp = string.split(tmp.temp[1], "_")
				tmp.steam = tmp.temp[2]
				tmp.steamLU, tmp.steamOwnerLU, tmp.userIDLU, tmp.platformLU = LookupPlayer(tmp.steam)

				if tmp.steamLU ~= "0" and tmp.steamLU ~= "" then
					tmp.steam = tmp.steamLU
					tmp.userID = tmp.userIDLU
					tmp.platform = tmp.platformLU
				end
			end

			if not tmp.steam then
				tmp.steam = tmp.userID
			end

			if tonumber(tmp.accessLevel) <= tonumber(server.maxAdminLevel) and tmp.userID then
				if tmp.steam ~= "0" and tmp.steam ~= "" and tmp.userID ~= "0"and tmp.userID ~= "" then
					-- add the steamid to the staffList table
					if not staffList[tmp.userID] then
						staffList[tmp.userID] = {}
						staffList[tmp.userID].hidden = false
					end

					staffList[tmp.userID].adminLevel = tmp.accessLevel
					staffList[tmp.userID].userID = tmp.userID

					if tmp.name then
						staffList[tmp.userID].name = tmp.name
					end

					if players[tmp.steam] then
						players[tmp.steam].accessLevel = tmp.accessLevel
						players[tmp.steam].newPlayer = false
						players[tmp.steam].silentBob = false
						players[tmp.steam].walkies = false
						players[tmp.steam].timeout = false
						players[tmp.steam].botTimeout = false
						players[tmp.steam].prisoner = false
						players[tmp.steam].exiled = false
						players[tmp.steam].canTeleport = true
						players[tmp.steam].botHelp = true
						players[tmp.steam].hackerScore = 0

						if staffList[tmp.userID].hidden then
							players[tmp.steam].testAsPlayer = true
						else
							players[tmp.steam].testAsPlayer = nil
						end

						staffList[tmp.userID].name = players[tmp.steam].name

						if botman.dbConnected then
							conn:execute("UPDATE players SET newPlayer = 0, silentBob = 0, walkies = 0, exiled = 0, canTeleport = 1, botHelp = 1, accessLevel = " .. tmp.accessLevel .. " WHERE steam = '" .. tmp.steam .. "'")

							status, errorString = conn:execute("INSERT INTO staff (steam, adminLevel, userID, platform, hidden, name) VALUES ('" .. tmp.userID .. "'," .. tmp.accessLevel .. ",'" .. tmp.userID .. "','" .. tmp.platform .. "'," .. dbBool(staffList[tmp.userID].hidden) .. ",'" .. escape(staffList[tmp.userID].name) .. "')")

							if not status then
								if string.find(errorString, "Duplicate entry") then
									conn:execute("UPDATE staff SET adminLevel = " .. tmp.accessLevel .. " WHERE steam = '" .. tmp.userID .. "'")
								end
							end
						end

						if players[tmp.steam].botTimeout and igplayers[tmp.steam] then
							gmsg(server.commandPrefix .. "return Steam_" .. tmp.steam)
						end
					end
				end

				if tmp.steam == "0" and tmp.userID ~= "0" and tmp.userID ~= "" then
					-- add the userID to the staffList table
					if not staffList[tmp.userID] then
						staffList[tmp.userID] = {}
						staffList[tmp.userID].hidden = false
					end

					staffList[tmp.userID].adminLevel = tmp.accessLevel
					staffList[tmp.userID].name = tmp.name

					if botman.dbConnected then
						status, errorString = conn:execute("INSERT INTO staff (steam, adminLevel, userID, platform, hidden, name) VALUES ('" .. tmp.userID .. "'," .. tmp.accessLevel .. ",'" .. tmp.userID .. "','" .. tmp.platform .. "'," .. dbBool(staffList[tmp.userID].hidden) .. ",'" .. escape(staffList[tmp.userID].name) .. "')")

						if not status then
							if string.find(errorString, "Duplicate entry") then
								conn:execute("UPDATE staff SET adminLevel = " .. tmp.accessLevel .. " WHERE steam = '" .. tmp.userID .. "'")
							end
						end
					end
				end
			end

			tempTimer( 5, [[loadStaff()]] )

			return
		end


		if playerListItems ~= nil then
			if string.find(line, "Listed ") then
				playerListItems = nil
			end

			return
		end


		if ircListItems ~= nil then
			if string.sub(string.trim(line), 1, 5) == "Slot " then
				ircListItems = nil
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
				message("pm " .. players[playerListItems].userID .. " [" .. server.chatColour .. "]" .. string.trim(line) .. "[-]")
			end
		end


		-- collect the ban list
		if collectBans then
			if not string.find(line, "Reason") then
				if string.find(line, "-") then
					temp = string.split(line, "%-")
					bannedTo = string.trim(temp[1] .. "-" .. temp[2] .. "-" .. temp[3])
					steam = string.sub(temp[4], 1, string.len(temp[4]) - 2)
					steam = string.trim(steam)
					reason = string.trim(temp[7])

					if botman.dbConnected then
						conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. bannedTo .. "','" .. steam .. "','" .. escape(reason) .. "',STR_TO_DATE('" .. bannedTo .. "', '%Y-%m-%d %H:%i:%s'))")

						if players[steam] then
							-- also insert the steam owner (will only work if the steam id is different)
							conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. bannedTo .. "','" .. players[steam].steamOwner .. "','" .. escape(reason) .. "',STR_TO_DATE('" .. bannedTo .. "', '%Y-%m-%d %H:%i:%s'))")
						end
					end
				end
			end
		end


		-- get zombies into table gimmeZombies
		if getZombies ~= nil then
			if string.find(line, "ombie") then
				temp = string.split(line, "%-")

				local entityID = string.trim(temp[1])
				local zombie = string.trim(temp[2])

				if botman.dbConnected then
					status, errorString = conn:execute("INSERT INTO gimmeZombies (zombie, entityID) VALUES ('" .. zombie .. "'," .. entityID .. ")")

					if not status then
						if string.find(errorString, "Duplicate entry") then
							conn:execute("UPDATE gimmeZombies SET remove = 0 WHERE zombie = '" .. zombie .. "'")
						end
					end
				end

				updateGimmeZombies(entityID, zombie)
			else
				if (string.sub(line, 1, 4) ~= os.date("%Y")) then
					temp = string.split(line, "%-")

					local entityID = string.trim(temp[1])
					local entity = string.trim(temp[2])

					if botman.dbConnected then conn:execute("INSERT INTO otherEntities (entity, entityID) VALUES ('" .. entity .. "'," .. entityID .. ")") end
					updateOtherEntities(entityID, entity)
				end
			end
		end

		if string.find(line, "INF Executing command") then
			botman.serverStarting = false
		end


		if string.find(line, "Executing command 'version") or string.find(line, "Game version:", nil, true) then
			readVersion = true
			resetVersion = true
		end


		if echoConsoleTo ~= nil then
			if string.find(line, echoConsoleTrigger, nil, true) then
				echoConsole = true
			end
		end
	end

	if server.botman and not botman.botDisabled then
		if string.find(line, "PUG: entity_id") then
			words = {}
			tmp = {}

			for word in string.gmatch(line, "(-?%d+)") do
				table.insert(words, word)
			end

			tmp.steam = words[1]
			tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(tmp.steam)

			tmp.x = igplayers[tmp.steam].xPos
			tmp.y = igplayers[tmp.steam].yPos
			tmp.z = igplayers[tmp.steam].zPos

			if string.find(line, "isUnderGround=True") and not isAdminHidden(tmp.steam, tmp.userID) then
				igplayers[tmp.steam].noclip = true

				if tonumber(igplayers[tmp.steam].noclipX) == 0 and tonumber(igplayers[tmp.steam].noclipZ) == 0 then
					igplayers[tmp.steam].noclipX = tmp.x
					igplayers[tmp.steam].noclipY = tmp.y
					igplayers[tmp.steam].noclipZ = tmp.z

					igplayers[tmp.steam].hackerDetection = "noclipping"
					players[tmp.steam].hackerScore = tonumber(players[tmp.steam].hackerScore) + 10
				else
					-- distance traveled since last detection
					tmp.dist = distancexyz(tmp.x, tmp.y, tmp.z, igplayers[tmp.steam].noclipX, igplayers[tmp.steam].noclipY, igplayers[tmp.steam].noclipZ)

					-- update coords
					igplayers[tmp.steam].noclipX = tmp.x
					igplayers[tmp.steam].noclipY = tmp.y
					igplayers[tmp.steam].noclipZ = tmp.z

					if igplayers[tmp.steam].noclipCount == nil then
						igplayers[tmp.steam].noclipCount = 1
					end

					if tonumber(tmp.dist) > 0 then
						igplayers[tmp.steam].hackerDetection = "noclipping"
						players[tmp.steam].hackerScore = tonumber(players[tmp.steam].hackerScore) + 10

						alertAdmins("Player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected noclipping (count: " .. igplayers[tmp.steam].noclipCount .. ") (hacker score: " .. players[tmp.steam].hackerScore .. ") " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z, "warn")
						irc_chat(server.ircMain, "Player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected noclipping (count: " .. igplayers[tmp.steam].noclipCount .. ") (session: " .. players[tmp.steam].session .. " hacker score: " .. players[tmp.steam].hackerScore .. ") " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " moved " .. string.format("%d", tmp.dist))
						irc_chat(server.ircAlerts, "Player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected noclipping (count: " .. igplayers[tmp.steam].noclipCount .. ") (session: " .. players[tmp.steam].session .. " hacker score: " .. players[tmp.steam].hackerScore .. ") " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " moved " .. string.format("%d", tmp.dist))
					else
						if igplayers[tmp.steam].noclipX == tmp.x and igplayers[tmp.steam].noclipY == tmp.y and igplayers[tmp.steam].noclipZ == tmp.z then
							if igplayers[tmp.steam].lastHackerAlert == nil then
								igplayers[tmp.steam].lastHackerAlert = os.time()

								irc_chat(server.ircMain, "Player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected noclipping (count: " .. igplayers[tmp.steam].noclipCount .. ") (session: " .. players[tmp.steam].session .. " hacker score: " .. players[tmp.steam].hackerScore .. ") " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " moved " .. string.format("%d", tmp.dist))
								irc_chat(server.ircAlerts, server.gameDate .. " player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected noclipping (count: " .. igplayers[tmp.steam].noclipCount .. ") (session: " .. players[tmp.steam].session .. " hacker score: " .. players[tmp.steam].hackerScore .. ") " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " moved " .. string.format("%d", tmp.dist))
								alertAdmins("Player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected noclipping (count: " .. igplayers[tmp.steam].noclipCount .. ") (hacker score: " .. players[tmp.steam].hackerScore .. ") " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " moved " .. string.format("%d", tmp.dist), "warn")
							end

							if tonumber(os.time() - igplayers[tmp.steam].lastHackerAlert) > 120 then
								igplayers[tmp.steam].lastHackerAlert = os.time()
								irc_chat(server.ircAlerts, server.gameDate .. " player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected noclipping (count: " .. igplayers[tmp.steam].noclipCount .. ") (session: " .. players[tmp.steam].sessionCount .. " hacker score: " .. players[tmp.steam].hackerScore .. ") " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " moved " .. string.format("%d", tmp.dist))
								alertAdmins("Player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected noclipping (count: " .. igplayers[tmp.steam].noclipCount .. ") (hacker score: " .. players[tmp.steam].hackerScore .. ") " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z ..  " moved " .. string.format("%d", tmp.dist), "warn")
							end
						end
					end

					igplayers[tmp.steam].noclipCount = tonumber(igplayers[tmp.steam].noclipCount) + 1
				end
			else
				igplayers[tmp.steam].noclip = false

				-- update coords anyway
				igplayers[tmp.steam].noclipX = tmp.x
				igplayers[tmp.steam].noclipY = tmp.y
				igplayers[tmp.steam].noclipZ = tmp.z
			end

			return
		end


		if string.find(line, "PGD: entity_id", nil, true) and string.find(line, "vehicle=", nil, true) and not botman.botDisabled then
			words = {}
			tmp = {}

			for word in string.gmatch(line, "(-?%d+)") do
				table.insert(words, word)
			end

			tmp.isFlying = false
			tmp.isAdmin = false
			tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(words[1])
			tmp.isAdmin = isAdminHidden(tmp.steam, tmp.userID)

			igplayers[tmp.steam].flying = false
			tmp.groundHeight = tonumber(words[2]) -- distance above ground

			if not igplayers[tmp.steam].flyingHeight then
				igplayers[tmp.steam].flyingHeight = 0
			end

			if not igplayers[tmp.steam].flyingHeightOld then
				igplayers[tmp.steam].flyingHeightOld = 0
			end

			if tmp.groundHeight == 0 then
				igplayers[tmp.steam].flyingHeight = 0
				igplayers[tmp.steam].flyingHeightOld = 0
			end

			if tmp.groundHeight == igplayers[tmp.steam].flyingHeightOld then
				igplayers[tmp.steam].flyingHeight = tmp.groundHeight
			else
				igplayers[tmp.steam].flyingHeightOld = tmp.groundHeight
			end

			if string.find(line, "vehicle=True") then
				igplayers[tmp.steam].inVehicle = true
				tmp.inVehicle = true
			else
				igplayers[tmp.steam].inVehicle = false
				tmp.inVehicle = false
			end

			if (tonumber(tmp.groundHeight) > tonumber(server.hackerFlyingTrigger)) and not server.playersCanFly then
				if igplayers[tmp.steam].flyingHeight == nil then
					igplayers[tmp.steam].flyingHeight = tmp.groundHeight
					igplayers[tmp.steam].flyingHeightOld = tmp.groundHeight
				end

				if not tmp.inVehicle and not tmp.isAdmin and (tonumber(tmp.groundHeight) >= igplayers[tmp.steam].flyingHeight) then
					igplayers[tmp.steam].flyingHeight = tmp.groundHeight
					tmp.x = igplayers[tmp.steam].xPos
					tmp.y = igplayers[tmp.steam].yPos
					tmp.z = igplayers[tmp.steam].zPos

					if not players[tmp.steam].timeout and not players[tmp.steam].botTimeout and igplayers[tmp.steam].lastTP == nil and not players[tmp.steam].ignorePlayer then
						tmp.isFlying = true
						igplayers[tmp.steam].flying = true
						igplayers[tmp.steam].detectedFlying = true

						if not igplayers[tmp.steam].detectedFlyingCounter then
							igplayers[tmp.steam].detectedFlyingCounter = 0
						end

						igplayers[tmp.steam].flyCount = igplayers[tmp.steam].flyCount + 1
						igplayers[tmp.steam].detectedFlyingCounter = igplayers[tmp.steam].detectedFlyingCounter + 1

						if igplayers[tmp.steam].flyingX == 0 then
							igplayers[tmp.steam].flyingX = tmp.x
							igplayers[tmp.steam].flyingY = tmp.y
							igplayers[tmp.steam].flyingZ = tmp.z

							igplayers[tmp.steam].hackerDetection = "flying"
							players[tmp.steam].hackerScore = tonumber(players[tmp.steam].hackerScore) + 10
						else
							-- distance of travel ignoring Y (height)
							tmp.horizontalTravel = distancexyz(tmp.x, 0, tmp.z, igplayers[tmp.steam].flyingX, 0, igplayers[tmp.steam].flyingZ)

							-- update coords
							igplayers[tmp.steam].flyingX = tmp.x
							igplayers[tmp.steam].flyingY = tmp.y
							igplayers[tmp.steam].flyingZ = tmp.z

							igplayers[tmp.steam].hackerDetection = "flying"
							players[tmp.steam].hackerScore = tonumber(players[tmp.steam].hackerScore) + 10

							if tonumber(igplayers[tmp.steam].flyCount) > 0 then
								irc_chat(server.ircMain, "Player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected flying (count: " .. igplayers[tmp.steam].flyCount .. ") (session: " .. players[tmp.steam].sessionCount .. " hacker score: " .. players[tmp.steam].hackerScore .. ") @ " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " high " .. tmp.groundHeight .. " moved " .. string.format("%d", tmp.horizontalTravel))

								irc_chat(server.ircAlerts, server.gameDate .. " player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected flying (count: " .. igplayers[tmp.steam].flyCount .. ") (session: " .. players[tmp.steam].sessionCount .. " hacker score: " .. players[tmp.steam].hackerScore .. ") @ " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " high " .. tmp.groundHeight .. " moved " .. string.format("%d", tmp.horizontalTravel))

								alertAdmins("Player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " is flying (count: " .. igplayers[tmp.steam].flyCount .. ") (hacker score: " .. players[tmp.steam].hackerScore .. ") @ " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " high " .. tmp.groundHeight .. " moved " .. string.format("%d", tmp.horizontalTravel), "warn")

								conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam, userID) VALUES (" .. tmp.x .. "," .. tmp.y .. "," .. tmp.z .. ",'" .. botman.serverTime .. "','hacker flying','" .. server.gameDate .. " player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected flying (hacker score: " .. players[tmp.steam].hackerScore .. ") @ " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " high " .. tmp.groundHeight .. " moved " .. string.format("%d", tmp.horizontalTravel) .. "','" .. tmp.steam .. "','" .. tmp.userID .. "')")
							else
								if igplayers[tmp.steam].flyingX == tmp.x and igplayers[tmp.steam].flyingY == tmp.y and igplayers[tmp.steam].flyingZ == tmp.z then
									if igplayers[tmp.steam].lastHackerAlert == nil then
										igplayers[tmp.steam].lastHackerAlert = os.time()

										alertAdmins("Player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected flying (count: " .. igplayers[tmp.steam].flyCount .. ") (hacker score: " .. players[tmp.steam].hackerScore .. ") @ " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " high " .. tmp.groundHeight .. " moved " .. string.format("%d", tmp.horizontalTravel), "warn")

										irc_chat(server.ircMain, "Player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected flying (count: " .. igplayers[tmp.steam].flyCount .. ") (session: " .. players[tmp.steam].session .. " hacker score: " .. players[tmp.steam].hackerScore .. ") @ " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " high " .. tmp.groundHeight .. " moved " .. string.format("%d", tmp.horizontalTravel))

										irc_chat(server.ircAlerts, server.gameDate .. " player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected flying (count: " .. igplayers[tmp.steam].flyCount .. ") (session: " .. players[tmp.steam].session .. " hacker score: " .. players[tmp.steam].hackerScore .. ") @ " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " high " .. tmp.groundHeight .. " moved " .. string.format("%d", tmp.horizontalTravel))
									end

									if os.time() - igplayers[tmp.steam].lastHackerAlert > 120 then
										alertAdmins("Player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected flying (count: " .. igplayers[tmp.steam].flyCount .. ") (hacker score: " .. players[tmp.steam].hackerScore .. ") @ " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " moved " .. string.format("%d", tmp.horizontalTravel), "warn")

										irc_chat(server.ircAlerts, server.gameDate .. " player " .. tmp.steam .. " " .. igplayers[tmp.steam].name .. " detected flying (count: " .. igplayers[tmp.steam].flyCount .. ") (session: " .. players[tmp.steam].session .. " hacker score: " .. players[tmp.steam].hackerScore .. ") @ " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " moved " .. string.format("%d", tmp.horizontalTravel))
									end
								end
							end
						end
					end
				end

				if not tmp.inVehicle and not tmp.isAdmin then
					igplayers[tmp.steam].flyingHeight = tmp.groundHeight
				end
			end

			if not igplayers[tmp.steam].noclip and not tmp.isFlying then
				-- the player is not flying or noclipped so reduce the hackerScore and flyCount
				if tonumber(players[tmp.steam].hackerScore) > 0 then
					players[tmp.steam].hackerScore = tonumber(players[tmp.steam].hackerScore) - 5
				end

				if tonumber(igplayers[tmp.steam].flyCount) > 0 then
					igplayers[tmp.steam].flyCount  = igplayers[tmp.steam].flyCount - 1
				end
			end

			return
		end
	end

	-- ===================================
	-- infrequent telnet events below here
	-- ===================================

	if string.find(line, "No spawn point found near player!") then
		for k,v in pairs(igplayers) do
			if v.voteRewarded then
				if os.time() - v.voteRewarded < 10 then
					v.voteRewardOwing = 1
					message("pm " .. v.userID .. " [" .. server.warnColour .. "]Oh no! Your reward failed to spawn.  Move outside to somewhere more open and try again by typing {#}claim vote[-]")
					message("pm " .. v.userID .. " [" .. server.warnColour .. "]Claim it before you leave the server.[-]")
					break
				end
			end
		end
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if not server.useAllocsWebAPI then
		if string.find(line, "Executing command 'le'") then
			botman.listEntities = true
			botman.lastListEntities = os.time()
			connMEM:execute("DELETE FROM entities")

			return
		end


		if string.find(line, "Executing command 'li *") then
			-- li * is not supported in telnet mode because there is too much data and it overloads the bot and causes high cpu.
			return
		end


		if (string.find(line, "Banned until -")) then
			collectBans = true
			conn:execute("TRUNCATE bans")

			return
		end

		-- update owners, admins and mods
		if string.find(line, "Level: UserID (Player name if online", nil, true) then
			getAdminList = true

			return
		end
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if botman.readGG and not string.find(line, "GamePref.", nil, true) then
		botman.readGG = false
	end

	if botman.readGG then
		number = tonumber(string.match(line, " (%d+)"))

		temp = string.split(line, " = ")
		pref = string.sub(temp[1], 10)

		if not temp[2] then
			return
		end

		value = string.sub(line, string.find(line, " = ") + 3)
		GamePrefs[pref] = value

		if (string.find(line, "PlayerKillingMode =")) then
			if botStatus.newBot then
				botStatus.newBot = false

				value = tonumber(value)

				if value == 0 then
					server.gameType = "pve"
					server.northeastZone = "pve"
					server.northwestZone = "pve"
					server.southeastZone = "pve"
					server.southwestZone = "pve"
				else
					server.gameType = "pvp"
					server.northeastZone = "pvp"
					server.northwestZone = "pvp"
					server.southeastZone = "pvp"
					server.southwestZone = "pvp"
				end
			end

			return
		end

		if (string.find(line, "HideCommandExecutionLog =")) then
			server.HideCommandExecutionLog = number

			return
		end

		if (string.find(line, "MaxSpawnedZombies set to")) then
			server.MaxSpawnedZombies = number

			return
		end

		if (string.find(line, "MaxSpawnedAnimals set to")) then
			server.MaxSpawnedAnimals = number

			return
		end

		if (string.find(line, "LootRespawnDays =")) then
			server.LootRespawnDays = number

			return
		end

		if (string.find(line, "BlockDurabilityModifier =")) then
			server.BlockDurabilityModifier = number

			return
		end

		if (string.find(line, "DayNightLength =")) then
			server.DayNightLength = number

			return
		end

		if (string.find(line, "DayLightLength =")) then
			server.DayLightLength = number

			return
		end

		if (string.find(line, "DropOnDeath =")) then
			server.DropOnDeath = number

			return
		end

		if (string.find(line, "DropOnQuit =")) then
			server.DropOnQuit = number

			return
		end

		if (string.find(line, "EnemyDifficulty =")) then
			server.EnemyDifficulty = number

			return
		end

		if (string.find(line, "LandClaimSize =")) then
			server.LandClaimSize = number

			return
		end

		if (string.find(line, "LandClaimExpiryTime =")) then
			server.LandClaimExpiryTime = number

			return
		end

		if (string.find(line, "LootAbundance =")) then
			server.LootAbundance = number

			return
		end

		if (string.find(line, "LootRespawnDays =")) then
			server.LootRespawnDays = number

			return
		end

		if (string.find(line, "ServerPort =")) then
			server.ServerPort = number
			if botman.dbConnected then
				conn:execute("UPDATE server SET ServerPort = " .. server.ServerPort)
			end

			if botman.botsConnected then
				connBots:execute("UPDATE servers SET ServerPort = " .. server.ServerPort .. " WHERE botID = " .. server.botID)
			end

			return
		end

		if (string.find(line, "ZombiesRun =")) then
			server.ZombiesRun = number

			return
		end

		if (string.find(line, "ZombieMove =")) then
			server.ZombiesRun = -1
			server.ZombieMove = number

			return
		end

		if (string.find(line, "ZombieMoveNight =")) then
			server.ZombieMoveNight = number

			return
		end

		if (string.find(line, "ZombieBMMove =")) then
			server.ZombieBMMove = number

			return
		end

		if (string.find(line, "ZombieFeralMove =")) then
			server.ZombieFeralMove = number

			return
		end

		if (string.find(line, "BloodMoonFrequency =")) then
			server.BloodMoonFrequency = number
			server.hordeNight = number

			return
		end

		if (string.find(line, "BloodMoonRange =")) then
			server.BloodMoonRange = number

			return
		end

		if (string.find(line, "ServerName =")) then
			server.serverName = string.trim(string.sub(line, 22))

			if botman.dbConnected then
				conn:execute("UPDATE server SET serverName = '" .. escape(server.serverName) .. "'")
			end

			if botman.botsConnected then
				connBots:execute("UPDATE servers SET serverName = '" .. escape(server.serverName) .. "' WHERE botID = " .. server.botID)
			end

			if string.find(string.lower(server.serverName), "pvp", nil, true) and not string.find(string.lower(server.serverName), "pve", nil, true) then
				server.gameType = "pvp"

				if server.northeastZone == "" then
					server.northeastZone = "pvp"
				end

				if server.northwestZone == "" then
					server.northwestZone = "pvp"
				end

				if server.southeastZone == "" then
					server.southeastZone = "pvp"
				end

				if server.southwestZone == "" then
					server.southwestZone = "pvp"
				end
			else
				if server.northeastZone == "" then
					server.northeastZone = "pve"
				end

				if server.northwestZone == "" then
					server.northwestZone = "pve"
				end

				if server.southeastZone == "" then
					server.southeastZone = "pve"
				end

				if server.southwestZone == "" then
					server.southwestZone = "pve"
				end
			end

			return
		end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

		if (string.find(line, "GameName =")) then
			server.GameName = string.trim(string.sub(line, 20))

			return
		end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

		if (string.find(line, "ServerMaxPlayerCount =")) then
			number = tonumber(string.match(line, " (%d+)"))
			server.ServerMaxPlayerCount = number

			if server.maxPlayers == 0 then
				server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

				if botman.dbConnected then
					conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
				end
			else
				if tonumber(server.maxPlayers) ~= tonumber(server.ServerMaxPlayerCount) - 1 then
					if tonumber(server.reservedSlots) > 0 then
						if tonumber(server.maxPlayers) > tonumber(server.ServerMaxPlayerCount) then
							server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

							if botman.dbConnected then
								conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
							end

							return
						end

						if tonumber(server.maxPlayers) < tonumber(server.ServerMaxPlayerCount) -1 then
							server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

							if botman.dbConnected then
								conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
							end
						end
					else
						server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

						if botman.dbConnected then
							conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
						end
					end
				end
			end

			return
		end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

		if (string.find(line, "MaxSpawnedZombies =")) then
			server.MaxSpawnedZombies = number
			-- If we detect this line it means we are receiving data from the server so we set a flag to let us know elsewhere that we got server data ok.
			serverDataLoaded = true

			return
		end
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.sub(line, 1, 4) == "Mod " then
		if resetVersion and not server.useAllocsWebAPI then
			modVersions = {}
			server.allocs = false
			server.botman = false
			server.otherManager = false
			resetVersion = nil
		end

--dbug("debug matchAll line " .. debugger.getinfo(1).currentline)

		modVersions[line] = {}
	end


	-- detect CSMM Patrons Mod
	if string.find(line, "Mod CSMM Patrons") then
		server.otherManager = true

		return
	end


	-- detect Alloc's Mod
	if string.find(line, "Mod Allocs server fixes") or string.find(line, "Mod Allocs_Core") then
		server.allocs = true
		temp = string.split(line, ":")
		server.allocsServerFixes = temp[2]

		return
	end


	if string.find(line, "Mod Allocs command extensions") or string.find(line, "Allocs_Commands") then
		server.allocs = true
		temp = string.split(line, ":")
		server.allocsCommandExtensions = temp[2]

		return
	end


	if string.find(line, "Mod Allocs MapRendering") or string.find(line, "Allocs_Webinterface") then
		server.allocs = true
		temp = string.split(line, ":")
		server.allocsMap = temp[2]

		return
	end


	if (string.find(line, "entity numbers:")) then
		-- flag all the zombies for removal so we can detect deleted zeds
		if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET remove = 1") end
		if botman.dbConnected then conn:execute("UPDATE otherEntities SET remove = 1") end

		getZombies = true

		return
	end


	if string.find(line, "ERROR: unknown command 'bm-playerunderground'") then
		server.scanNoclip = false

		return
	end


	-- detect server version
	if string.find(line, "Game version:") then
		temp = string.sub(line, string.find(line, "Game version:") + 13)
		modVersions["Server " .. string.trim(temp)] = {}

		server.gameVersion = string.trim(string.sub(line, string.find(line, "Game version:") + 14, string.find(line, "Compatibility") - 2))
		if botman.dbConnected then conn:execute("UPDATE server SET gameVersion = '" .. escape(server.gameVersion) .. "'") end

		temp = string.split(server.gameVersion, " ")
		server.gameVersionNumber = tonumber(temp[2])

		return
	end

	-- detect Botman mod
	if string.find(line, "Mod Botman:") then
		server.botman = true
		temp = string.split(line, ":")
		server.botmanVersion = temp[2]
		modBotman.version = temp[2]

		if botman.dbConnected then conn:execute("UPDATE modBotman SET version = '" .. temp[2] .. "'") end

		return
	end


	if (string.find(line, "Process chat error")) then
		irc_chat(server.ircAlerts, "Server error detected. Re-validate to fix: " .. line)
	end


	if string.find(line, "Playername or entity ID not found.") then
		return
	end


	if string.find(line, "Version mismatch") then
		irc_chat(server.ircAlerts, line)

		return
	end


	if string.find(line, "ERR EXCEPTION:") and string.find(line, "Cannot expand this MemoryStream") and not botman.serverErrorReported then
		-- report memory error
		botman.serverErrorReported = true
		irc_chat(server.ircAlerts, "Server error detected.")
		irc_chat(server.ircAlerts, line)

		return
	end

	if string.find(line, "INF Server shutting down", nil, true) and not string.find(line, "Chat") then
		serverShutdown()

		return
	end

	if string.find(line, "INF World.Unload", nil, true) and not string.find(line, "Chat") then
		serverShutdown()

		return
	end

	if string.find(line, 'kickall "Server restarting"',nil, true) and not server.readLogUsingTelnet then
		serverShutdown()

		return
	end


	if string.find(line, "ERROR: Command") then
		if string.find(line, "game is started") and not string.find(line, "Chat") then
			botman.gameStarted = false
			server.uptime = 0
			botman.playersOnline = 0
			botStatus.playersOnline = 0
			server.serverStartTimestamp = os.time() -- near enough to correct :P
		end
	end


	if string.find(line, "StartGame done") and not string.find(line, "Chat") then
		botman.gameStarted = true
		botman.serverStarting = false
		botman.worldGenerating = nil

		botman.playersOnline = 0
		botStatus.playersOnline = 0
		server.serverStartTimestamp = os.time() -- near enough to correct :P
		server.uptime = 0
		processServerCommandQueue()

		irc_chat(server.ircMain, "Players can now join the server :D")

		if server.useAllocsWebAPI and tonumber(server.allocsMap) > 0 then
			botman.APIOffline = false
			toggleTriggers("api online")
		end

		-- move these out of here and don't put them on timers
		sendCommand("gt")
		sendCommand("admin list")
		sendCommand("version")
		sendCommand("gg")

		tempTimer( 7, [[sendCommand("llp parseable")]] )

		if server.botman then
			tempTimer( 11, [[sendCommand("bm-resetregions list")]] )
		end

		return
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "INF Reloading serveradmin.xml") then
		sendCommand("admin list")

		return
	end

	if getuptime then
		getuptime = nil
		temp = string.split(line, ":")

		-- hours
		tmp  = tonumber(string.match(temp[1], "(%d+)"))

		server.uptime = tmp * 60 * 60

		-- minutes
		tmp  = tonumber(string.match(temp[2], "(%d+)"))
		server.uptime = server.uptime + (tmp * 60)

		-- seconds
		tmp  = tonumber(string.match(temp[3], "(%d+)"))

		server.uptime = server.uptime + tmp
		server.serverStartTimestamp = os.time() - server.uptime
		return
	end


	if string.find(line, "INF Executing command 'bm-uptime'", nil, true) and not server.useAllocsWebAPI then
		getuptime = true
		return
	end


	if string.find(line, "BotStartupCheck")  then
		if string.find(line, "by Telnet from ") then
			temp = string.sub(line, string.find(line, "by Telnet from ") + 15)
			temp = string.split(temp, ":")
			server.botsIP = temp[1]

			conn:execute("UPDATE server SET botsIP = '" .. server.botsIP .. "'")
			return
		end
	end


	if string.find(line, "Server IP:") and not string.find(line, "Chat") then
		if server.IP == "0.0.0.0" then
			temp = string.split(line, ": ")
			server.IP = string.trim(temp[2])
			conn:execute("UPDATE server SET IP = '" .. server.IP .. "'")
		end
	end


	if string.find(line, "INF [Web] Started Webserver", nil, true) then
		botman.worldGenerating = nil
		temp = string.sub(line, string.find(line, " on ") + 4)
		temp = tonumber(temp) - 2
		server.webPanelPort = temp
		conn:execute("UPDATE server set webPanelPort = " .. server.webPanelPort)
		anticheatBans = {}

		stackLimits = {}
	end


	if string.find(line, "INF WorldGenerator:Generating", nil, true) then
		if not botman.worldGenerating then
			botman.worldGenerating = true
			irc_chat(server.ircMain, "The bot is temporarily paused while the world is being generated.  If it is still paused by the time you can join the server type " .. server.commandPrefix .. "unpause bot")
		end
	end


	if botman.worldGenerating then
		temp = string.sub(line, string.find(line, "INF") + 4)
		irc_chat(server.ircMain, temp)
	end


	if string.find(line, "Reset Status:", nil, true) then
		temp = string.sub(line, string.find(line, "INF") + 4)
		irc_chat(server.ircMain, temp)
	end


	if server.botman and not botman.botDisabled then
		if (readAnticheat or string.find(line,"~Botman AntiCheat~", nil, true)) and (not string.find(line, "unauthorized locked container")) then
			tmp = {}
			tmp.name = string.sub(line, string.find(line, "-NAME:") + 6, string.find(line, "--ID:") - 2)
			tmp.id = string.sub(line, string.find(line, "-ID:") + 4, string.find(line, "--LVL:") - 2)
			tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(tmp.id)

			tmp.hack = ""
			tmp.level = string.sub(line, string.find(line, "-LVL:") + 5)
			tmp.level = string.match(tmp.level, "(-?%d+)")
			tmp.alert = string.sub(line, string.find(line, "-LVL:") + 5)
			tmp.alert = string.sub(tmp.alert, string.find(tmp.alert, " ") + 1)

			if (not isStaff(tmp.steam, tmp.userID)) and (not players[tmp.steam].testAsPlayer) and (not bans[tmp.steam]) and (not anticheatBans[tmp.steam]) then
				if string.find(line, " spawned ") then
					temp = string.split(tmp.alert, " ")
					tmp.entity = stripQuotes(temp[3])
					tmp.x = string.match(temp[4], "(-?\%d+)")
					tmp.y = string.match(temp[5], "(-?\%d+)")
					tmp.z = string.match(temp[6], "(-?\%d+)")
					tmp.hack = "spawned " .. tmp.entity .. " at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z

					if tonumber(tmp.level) > 2 then
						irc_chat(server.ircMain, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
						irc_chat(server.ircAlerts, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
					end
				else
					tmp.x = players[tmp.steam].xPos
					tmp.y = players[tmp.steam].yPos
					tmp.z = players[tmp.steam].zPos
					tmp.hack = "using dm at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z

					if tonumber(tmp.level) > 2 then
						irc_chat(server.ircMain, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
						irc_chat(server.ircAlerts, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
					end
				end

				if tonumber(tmp.level) > 2 then
					anticheatBans[tmp.steam] = {}
					banPlayer(tmp.platform, tmp.userID, tmp.steam, "10 years", "hacking", "")
					logHacker(botman.serverTime, "Botman anticheat detected " .. tmp.steam .. " " .. tmp.name .. " " .. tmp.hack)
					message("say [" .. server.chatColour .. "]Banning player " .. tmp.name .. " 10 years for using hacks.[-]")
					irc_chat("#hackers", "[BANNED] Player " .. tmp.steam .. " " .. tmp.name .. " has has been banned for hacking by anticheat.")
					irc_chat("#hackers", line)
					irc_chat(server.ircMain, "[BANNED] Player " .. tmp.steam .. " " .. tmp.name .. " has has been banned for hacking.")
					irc_chat(server.ircAlerts, botman.serverTime .. " " .. server.gameDate .. " [BANNED] Player " .. tmp.steam .. " " .. tmp.name .. " has has been banned for 10 years for hacking.")
					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. tmp.x .. "," .. tmp.y .. "," .. tmp.z .. ",'" .. botman.serverTime .. "','ban','Player " .. tmp.steam .. " " .. escape(tmp.name) .. " has has been banned for 10 years for hacking.','" .. tmp.steam .. "')")
				end
			end
		end
	end


	if string.find(line, "bm-anticheat report", nil, true) then
		readAnticheat = true
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>", nil, true) then
		readBotmanConfig = true
		botman.config = {}
	end

	if string.find(line, "Web API token with name=bot and secret") and string.find(line, "added with permission level of 0.")  then
		temp = string.sub(line, string.find(line, "secret=") + 7, string.find(line, "added with permission") - 1)
		temp = string.trim(temp)
		server.useAllocsWebAPI = true
		server.allocsWebAPIUser = "bot"
		server.allocsWebAPIPassword = temp
		conn:execute("UPDATE server set allocsWebAPIUser = 'bot', allocsWebAPIPassword = '" .. escape(server.allocsWebAPIPassword) .. "', useAllocsWebAPI = 1")
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	if badPlayerJoined then
		if string.find(line, "INF Player set to online") or string.find(line, "INF PlayerSpawnedInWorld") then
			-- abort!  abort!
			badPlayerJoined = false
			badJoinLine = ""
		end

		if badPlayerJoined and not string.find(line, "INF Player connected") then
			playerConnected(badJoinLine .. line)
		end
	end

	-- if Allocs webmap has this error, force the bot to use telnet mode
	if string.find(line, "at AllocsFixes.NetConnections.Servers.Web.Web.HandleRequest") then
		if server.useAllocsWebAPI then
			server.useAllocsWebAPI = false
			conn:execute("UPDATE server set useAllocsWebAPI = 0")
			irc_chat(server.ircAlerts, "Alloc's web map has an error so the bot has automatically disabled API mode. If your bot has been told to never use telnet, it has no way to communicate with the server currently.")
			toggleTriggers("api offline")
		end
	end

	if readResetRegions then
		if string.find(line, "There are currently no reset regions") then
			readResetRegions = nil
			return
		end

		if string.sub(line, 1, 2) == "r." then
			temp = string.split(v, "%.")
			x = temp[2]
			z = temp[3]

			if not resetRegions[v .. ".7rg"] then
				resetRegions[v .. ".7rg"] = {}
			end

			resetRegions[v .. ".7rg"].x = x
			resetRegions[v .. ".7rg"].z = z
			resetRegions[v .. ".7rg"].inConfig = true
			conn:execute("INSERT INTO resetZones (region, x, z) VALUES ('" .. escape(v .. ".7rg") .. "'," .. x .. "," .. z .. ")")
		end
	end

	if string.find(line, "bm-resetregions list", nil, true) then
		readResetRegions = true

		for k,v in pairs(resetRegions) do
			v.inConfig = false
		end
	end

	if string.find(line, "ERROR") and string.find(line, "can only be executed") and not isChat then
		botman.serverStarting = true
	end

	if string.find(line, "Incorrect region file header!") then
		tmp.line = escape(line)
		irc_chat(server.ircAlerts, string.sub(tmp.line, string.find(tmp.line, "Incorr"), string.len(tmp.line)))
	end

	if string.find(line, "PlatformAuth authorization successful", nil, true) then
		tmp.split = string.split(line, ", ")

		tmp.steam = string.split(tmp.split[2], "=")
		tmp.steam = string.split(tmp.steam[2], "_")
		tmp.platform = stripAllQuotes(tmp.steam[1])
		tmp.steam = stripAllQuotes(tmp.steam[2])

		tmp.userID = string.split(tmp.split[3], "=")
		tmp.userID = stripAllQuotes(tmp.userID[2] )

		tmp.steamOwner = string.split(tmp.split[4], "=")
		if string.find(tmp.steamOwner[2], "unknown") then
			tmp.steamOwner = tmp.steam
		else
			tmp.steamOwner = string.split(tmp.steamOwner[2], "_")
			tmp.steamOwner = stripAllQuotes(tmp.steamOwner[2])
			tmp.steamOwner = tmp.steamOwner[2]
		end

		tmp.playerName = string.split(tmp.split[5], "=")
		tmp.playerName = string.sub(tmp.playerName[2], 2, string.len(tmp.playerName[2]) - 1)

		if server.kickXBox and tmp.platform == "XBL" and not botman.botDisabled then
			kick(tmp.userID, "This server does not allow connections from XBox.")
			irc_chat(server.ircAlerts, server.gameDate .. " player " .. tmp.userID .. " kicked because XBox players are not allowed to play here " .. tmp.platform .. "_" .. tmp.steam)
			return
		end

		if playersArchived[tmp.steam] then
			if debug then dbug("Restoring player " .. tmp.platform .. "_" ..  tmp.steam .. " " .. tmp.playerName .. " from archive") end
			conn:execute("INSERT INTO players SELECT * from playersArchived WHERE steam = '" .. tmp.steam .. "'")
			conn:execute("DELETE FROM playersArchived WHERE steam = '" .. tmp.steam .. "'")
			playersArchived[tmp.steam] = nil
			tempTimer( 1, [[ loadPlayers("]] .. tmp.steam .. [[") ]] )

			return
		end

		if joiningPlayers == nil then
			joiningPlayers = {}
		end

		joiningPlayers[tmp.steam] = {}
		joiningPlayers[tmp.steam].steam = tmp.steam
		joiningPlayers[tmp.steam].userID = tmp.userID
		joiningPlayers[tmp.steam].name = tmp.playerName

		connSQL:execute("INSERT INTO joiningPlayers (steam, userID, name, timestamp) VALUES ('" .. tmp.steam .. "','" .. tmp.userID .. "','" .. tmp.playerName .. "'," .. os.time() .. ")")
	end

	if string.find(line, "Password incorrect, please enter password:", nil, true) then
		botman.wrongTelnetPass = true
		disconnect()
	end

	botman.lastTelnetResponseTimestamp = os.time()
end

