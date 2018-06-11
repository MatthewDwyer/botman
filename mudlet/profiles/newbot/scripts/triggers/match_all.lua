--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- 2017-12-06T21:53:48 139450.416 INF Executing command 'traderlist' by Telnet from 158.69.250.118:60713
-- traderlist: [1] Position, pos_x=714, pos_y=108, pos_z=1197, closed=True
-- traderlist: [1] Size, size_x=41, size_y=24, size_z=43, closed=True
-- traderlist: [1] Protection, protection_x=61, protection_y=24, protection_z=63, closed=True
-- traderlist: [1] TeleportCenter, teleportCenter_x=0, teleportCenter_y=1, teleportCenter_z=1, closed=True
-- traderlist: [1] TeleportSize, teleportSize_x=40, teleportSize_y=24, teleportSize_z=41, closed=True

-- 2017-12-06T21:57:32 139674.910 INF Executing command 'lps 295' by Telnet from 158.69.250.118:60713
-- Skill from: entityid=295, athletics=51, healthNut=0, sexualTyranosaurus=1, scavenging=23, fastEddie=0, qualityJoe=1, treasureHunter=0, clothingArmor=7, bluntWeapons=17, pummelPete=1, breakingAndEntering=0, bladeWeapons=20, knifeGuy=0, decapitator=0, miningTools=75, miner69er=4, constructionTools=64, workbench=1, concreteMixing=1, steelSmithing=1, chemistryStation=0, badMechanic=3, pistols=1, theOutlaw=0, deadShot=0, shotguns=1, boomStick=0, splatterGun=0, rifles=1, betterLeadThanDead=0, archery=23, medicine=2, craftSkillWeapons=6, macheteCraftingName=0, craftSkillTools=6, craftSkillGuns=0, 9mmRoundCrafting=0, 44MagnumRoundCrafting=0, shotgunShellCrafting=0, 762mmRoundCrafting=0, craftSkillScience=6, electricBasicsName=0, electricTriggersName=0, electricTrapsMeleeName=0, electricTrapsRangedName=0, electricGeneratorName=0, electricBatteryBankName=0, doItYourselfName=0, craftSkillArmor=0, craftSkillMiscellaneous=0, paintMagazineDecorations=0, paintMagazineFaux=1, paintMagazineMasonry=0, paintMagazineMetal=1, paintMagazineWallCoverings=1, paintMagazineWoodAndRoofing=0, theSurvivor=4, theCamel=2, quickerCrafting=0, theFixer=0, barter=32, secretStash=1.

function removeOldStaff()
	if getAdminList then
		-- abort if getAdminList is true as that means there's been a fault in the telnet data
		return
	end

	local k,v

	for k,v in pairs(owners) do
		if not staffList[k] then
			owners[k] = nil
		end
	end

	for k,v in pairs(admins) do
		if not staffList[k] then
			admins[k] = nil
		end
	end

	for k,v in pairs(mods) do
		if not staffList[k] then
			mods[k] = nil
		end
	end
end


function matchAll(line)
	local pname, pid, number, died, coords, words, temp, msg
	local dy, mth, yr, hr, min, sec, pm, reason, timestamp, banDate
	local fields, values, x, y, z, id, loc, reset, steam, k, v, rows, tmp

	-- set counter to help detect the bot going offline
	botman.botOfflineCount = 2
	botman.botOffline = false
	botman.lastTelnetTimestamp = os.time()

	if botman.botDisabled then
		return
	end

	if botman.getMetrics then
		metrics.telnetLines = metrics.telnetLines + 1
	end

	if string.find(line, "StackTrace:") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.telnetErrors = metrics.telnetErrors + 1
		end

		return
	end

	if string.find(line, "ERR ") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.telnetErrors = metrics.telnetErrors + 1
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
	end

	if string.find(line, "WRN ") then -- ignore lines containing this.
		if not string.find(line, "DENSITYMISMATCH") then
			deleteLine()
			return
		end
	end

	if string.find(line, "NaN") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.telnetErrors = metrics.telnetErrors + 1
		end

		deleteLine()
		return
	end

	if string.find(line, "Unbalanced") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.telnetErrors = metrics.telnetErrors + 1
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
			metrics.telnetCommands = 0
			metrics.telnetErrors = 0
			metrics.telnetLines = metrics.telnetLines + 1
		end

		deleteLine()
		return
	end


	if string.find(line, "pm IPCHECK") then
		temp = string.sub(line, string.find(line, "from ") + 5)
		server.botsIP = string.sub(temp, 1, string.find(temp, ":") - 1)

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
			send("rcd " .. temp[2] .. " " .. temp[4] .. " fix")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			deleteLine()
			return
		end
	end

	if string.find(line, "WRN ") then
		deleteLine()
		return
	end

	-- grab the server time
	if botman.serverTime == "" then
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

			-- write to the log
			logChat(botman.serverTime, "Server", "Bot starting up..")
		end
	end


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

			deleteLine()
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
		end

		if string.find(line, "reason: JoinMultiplayer") then
			tmp.spawnedReason = "joined"
			igplayers[tmp.pid].spawnChecked = true
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


	if string.find(line, "Executing command 'gg'") then
		if string.find(line, server.botsIP) then
			botman.readGG = true
		end
	end


	if string.find(line, "type=Entity") then
		listEntities(line)

		deleteLine()
		return
	end


	-- Stompy's Mod stuff
	if server.stompy then
		if (string.find(line, "(BCM) Spawn Detected", nil, true)) then
			botman.stompyReportsSpawns = true
			listEntities(line, "BCM")

			deleteLine()
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

		deleteLine()
		return
	end


	if (string.find(line, "ServerMaxPlayerCount set to")) then
		number = tonumber(string.match(line, " (%d+)"))
		server.ServerMaxPlayerCount = number

		if server.maxPlayers == 0 then
			server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

			if tonumber(server.reservedSlots) > 0 then
				send("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end
		else
			if tonumber(server.maxPlayers) ~= tonumber(server.ServerMaxPlayerCount) - 1 then
				server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

				if tonumber(server.reservedSlots) > 0 then
					send("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
				end
			end
		end

		deleteLine()
		return
	end


	if getAdminList then
		if string.sub(line, 1, 3) ~= "   " or string.find(line, 1, 8) == "Total of" then
			getAdminList = nil
			removeOldStaff()

			deleteLine()
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
			staffList[pid] = {}
		end

		if number == 1 then
			admins[pid] = {}
			staffList[pid] = {}
		end

		if number == 2 then
			mods[pid] = {}
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

			if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, silentBob = 0, walkies = 0, exiled = 2, canTeleport = 1, enableTP = 1, botHelp = 1, accessLevel = " .. number .. " WHERE steam = " .. pid) end
			if botman.dbConnected then conn:execute("INSERT INTO staff (steam, adminLevel) VALUES (" .. pid .. "," .. number .. ")") end
		end

		return
	end


	if llpid ~= nil then
		if string.sub(line, 1, 4) == "   (" then
			coords = string.split(string.sub(line, 5, string.len(line) - 1), ",")

			if players[llpid].removedClaims == nil then
				players[llpid].removedClaims = 0
			end

			if botman.dbConnected then
				conn:execute("UPDATE keystones SET remove = 1 WHERE steam = " .. llpid .. " AND x = " .. coords[1] .. " AND y = " .. coords[2] .. " AND z = " .. coords[3] .. " AND remove > 1")
				conn:execute("UPDATE keystones SET removed = 0 WHERE steam = " .. llpid .. " AND x = " .. coords[1] .. " AND y = " .. coords[2] .. " AND z = " .. coords[3])
			end

			if accessLevel(llpid) > 3 then
				region = getRegion(coords[1], coords[3])

				loc, reset = inLocation(coords[1], coords[3])

				if (resetRegions[region]) or reset or players[llpid].removeClaims == true then
					if botman.dbConnected then conn:execute("INSERT INTO keystones (steam, x, y, z, remove) VALUES (" .. llpid .. "," .. coords[1] .. "," .. coords[2] .. "," .. coords[3] .. ",1) ON DUPLICATE KEY UPDATE remove = 1") end
				else
					if botman.dbConnected then conn:execute("INSERT INTO keystones (steam, x, y, z) VALUES (" .. llpid .. "," .. coords[1] .. "," .. coords[2] .. "," .. coords[3] .. ")") end
				end
			else
				if botman.dbConnected then conn:execute("INSERT INTO keystones (steam, x, y, z) VALUES (" .. llpid .. "," .. coords[1] .. "," .. coords[2] .. "," .. coords[3] .. ")") end
			end
		end
	end


	if playerListItems ~= nil then
		if string.find(line, "Listed ") then
			playerListItems = nil
		end

		deleteLine()
		return
	end


	if ircListItems ~= nil then
		if string.sub(string.trim(line), 1, 5) == "Slot " then
			ircListItems = nil
		end

		deleteLine()
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
				conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. bannedTo .. "'," .. steam .. ",'" .. escape(reason) .. "','" .. bannedTo .. "')")

				if players[steam] then
					-- also insert the steam owner (will only work if the steam id is different)
					conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. bannedTo .. "'," .. players[steam].steamOwner .. ",'" .. escape(reason) .. "','" .. bannedTo .. "')")
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
		end

		if string.find(line, "Executing command 'ban list'") and string.find(line, server.botsIP) then
			echoConsole = true
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

			if string.find(line, "isUnderGround=True") and accessLevel(pid) > 2 then
				igplayers[pid].noclip = true

				if igplayers[pid].noclipX == 0 and igplayers[pid].noclipZ == 0 then
					igplayers[pid].noclipX = math.floor(igplayers[pid].xPos)
					igplayers[pid].noclipY = math.floor(igplayers[pid].yPos)
					igplayers[pid].noclipZ = math.floor(igplayers[pid].zPos)
				else
					-- dist is horizontal distance travelled since last detection
					dist = distancexyz(igplayers[pid].noclipX,igplayers[pid].noclipY,igplayers[pid].noclipZ,math.floor(igplayers[pid].xPos),math.floor(igplayers[pid].yPos),math.floor(igplayers[pid].zPos))
					igplayers[pid].noclipX = math.floor(igplayers[pid].xPos)
					igplayers[pid].noclipY = math.floor(igplayers[pid].yPos)
					igplayers[pid].noclipZ = math.floor(igplayers[pid].zPos)

					if tonumber(dist) > 5 or (tonumber(dist) > 1 and players[pid].newPlayer) then
						igplayers[pid].hackerDetection = "noclipping"

						if players[pid].newPlayer then
							if tonumber(players[pid].ping) > 150 then
								players[pid].hackerScore = tonumber(players[pid].hackerScore) + 40
							else
								players[pid].hackerScore = tonumber(players[pid].hackerScore) + 25
							end
						else
							players[pid].hackerScore = tonumber(players[pid].hackerScore) + 20
						end

						if igplayers[pid].noclipCount == nil then
							igplayers[pid].noclipCount = 1
						end

						alertAdmins("[" .. server.alertColour .. "]Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. igplayers[pid].noclipZ .. " " .. igplayers[pid].noclipY .. " " .. igplayers[pid].noclipZ .. "[-]", "warn")
						irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. igplayers[pid].noclipX .. " " .. igplayers[pid].noclipY .. " " .. igplayers[pid].noclipZ)
						irc_chat(server.ircAlerts, "Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. igplayers[pid].noclipX .. " " .. igplayers[pid].noclipY .. " " .. igplayers[pid].noclipZ)
						igplayers[pid].noclipCount = tonumber(igplayers[pid].noclipCount) + 1
					end
				end
			else
				igplayers[pid].noclip = false
				igplayers[pid].noclipCount = 0
			end

			deleteLine()
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

			if tonumber(dist) > 1 and accessLevel(pid) > 2 then
				if not players[pid].timeout and not players[pid].botTimeout and igplayers[pid].lastTP == nil and not players[pid].ignorePlayer then
					igplayers[pid].flying = true

					if igplayers[pid].flyingX == 0 then
						igplayers[pid].flyingX = math.floor(igplayers[pid].xPos)
						igplayers[pid].flyingY = math.floor(igplayers[pid].yPos)
						igplayers[pid].flyingZ = math.floor(igplayers[pid].zPos)
					else
						-- distance of travel horizontally
						dist = distancexz(igplayers[pid].flyingX,igplayers[pid].flyingZ,math.floor(igplayers[pid].xPos),math.floor(igplayers[pid].zPos))

						if tonumber(dist) > 5 or players[pid].newPlayer then
							if players[pid].newPlayer then
								if tonumber(players[pid].ping) > 150 then
									players[pid].hackerScore = tonumber(players[pid].hackerScore) + 40
								else
									players[pid].hackerScore = tonumber(players[pid].hackerScore) + 25
								end
							else
								players[pid].hackerScore = tonumber(players[pid].hackerScore) + 20
							end
						end

						igplayers[pid].flyingX = math.floor(igplayers[pid].xPos)
						igplayers[pid].flyingY = math.floor(igplayers[pid].yPos)
						igplayers[pid].flyingZ = math.floor(igplayers[pid].zPos)

						if tonumber(dist) > 5 or players[pid].newPlayer then
							igplayers[pid].flyCount = igplayers[pid].flyCount + 1
							igplayers[pid].hackerDetection = "flying"

							if tonumber(igplayers[pid].flyCount) > 1 then
								irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].sessionCount .. " hacker score: " .. players[pid].hackerScore .. ") " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos))
								irc_chat(server.ircAlerts, "Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].sessionCount .. " hacker score: " .. players[pid].hackerScore .. ") " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos))
							end

							if tonumber(igplayers[pid].flyCount) > 1 then
								alertAdmins("[" .. server.alertColour .. "]Player " .. pid .. " " .. igplayers[pid].name .. " may be flying (count: " .. igplayers[pid].flyCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos) .. "[-]", "warn")
							end
						end
					end
				end
			end

			if not igplayers[pid].flying then
				igplayers[pid].flyCount = 0
			end

			if not igplayers[pid].noclip and not igplayers[pid].flying then
				if tonumber(players[pid].hackerScore) > 0 then
					players[pid].hackerScore = tonumber(players[pid].hackerScore) - 5
				end
			end

			deleteLine()
			return
		end
	end

	-- ===================================
	-- infrequent telnet events below here
	-- ===================================

	if string.find(line, "Executing command 'le'") then
		if string.find(line, server.botsIP) then
			botman.listEntities = true
			botman.lastListEntities = os.time()
			conn:execute("TRUNCATE memEntities")
		end

		deleteLine()
		return
	end


	if string.find(line, "Executing command 'li ") then
		if string.find(line, server.botsIP) and playerListItems == nil then
			botman.listItems = true
		end

		deleteLine()
		return
	end


	if string.sub(line, 1, 4) == "Mod " then
		modVersions[line] = {}
	end


	-- detect Coppi's Mod
	if string.find(line, "Mod Coppis command additions") then
		server.coppi = true

		temp = string.split(line, ":")
		server.coppiVersion = temp[2]

		if server.hideCommands then
			send("tcch " .. server.commandPrefix)

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end
		end

		return
	end


	-- detect Alloc's Mod
	if string.find(line, "Mod Allocs server fixes") then
		server.allocs = true

		temp = string.split(line, ":")
		server.allocsVersion = temp[2]

		return
	end


	if (string.find(line, "please specify one of the entities")) then
		-- flag all the zombies for removal so we can detect deleted zeds
		if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET remove = 1") end

		getZombies = true
		return
	end


	if string.find(line, "command 'rcd") then
		if string.find(line, server.botsIP) then
			fixChunkDensity = true
		end

		deleteLine()
		return
	end


	if string.find(line, "Executing command 'version'") and server.botsIP then
		if string.find(line, server.botsIP) then
			modVersions = {}
			server.alloc = false
			server.coppi = false
			server.stompy = false
			server.SDXDetected = false
			server.ServerToolsDetected = false

			if botman.dbConnected then
				conn:execute("UPDATE server SET SDXDetected = 0, ServerToolsDetected = 0")
			end

			return
		end
	end


	if (string.find(line, "Banned until -")) then
		collectBans = true
		conn:execute("TRUNCATE bans")
		return
	end


	-- update owners, admins and mods
	if string.find(line, "Level: SteamID (Player name if online)", nil, true) then
		getAdminList = true
		staffList = {}
		return
	end


	if string.find(line, "DropOnDeath =") then
		if (not botman.readGG) and server.botsIP then
			botman.badServerConfig = true
			irc_chat(server.ircMain, "ALERT! It appears that the server config setting HideCommandExecutionLog is not set to 0")
			irc_chat(server.ircMain, "If any telnet traffic is hidden from the bot, important features will not work.  Please set it to 0")
		else
			botman.badServerConfig = false
		end

		return
	end


	if string.find(line, "INF Server shutting down!") then
		saveLuaTables()
		return
	end

	if string.find(line, "ERROR: unknown command 'pug'") then
		server.scanNoclip = false
		return
	end


	-- detect server version
	-- Game version: Alpha 16 (b105) Compatibility Version: Alpha 16
	if string.find(line, "Game version:") then
		server.gameVersion = string.trim(string.sub(line, string.find(line, "Game version:") + 14, string.find(line, "Compatibility") - 2))
		if botman.dbConnected then conn:execute("UPDATE server SET gameVersion = '" .. escape(server.gameVersion) .. "'") end
		return
	end

	-- detect Stompy's API mod
	if string.find(line, "Mod Bad Company Manager:") then
		server.stompy = true
		temp = string.split(line, ":")
		server.stompyVersion = temp[2]
		return
	end

	-- detect SDX mods
	if string.find(line, "Mod SDX:") or string.find(line, "SDX: ") and not server.SDXDetected then
		server.SDXDetected = true
		if botman.dbConnected then conn:execute("UPDATE server SET SDXDetected = 1") end
		return
	end

	-- detect server tools
	if string.find(line, "Mod Server Tools:") or string.find(line, "mod 'Server Tools'") and not server.ServerToolsDetected then
		server.ServerToolsDetected = true
		if botman.dbConnected then conn:execute("UPDATE server SET ServerToolsDetected = 1") end
		return
	end

	-- detect CBSM
	if string.find(line, "pm CBSM") and server.CBSMFriendly then
		if server.commandPrefix == "/" then
			message("say [" .. server.chatColour .. "]CBSM detected.  Bot commands now begin with a ! to not clash with CBSM commands.[-]")
			message("say [" .. server.chatColour .. "]To use bot commands such as /who you must now type !who[-]")
			server.commandPrefix = "!"
			if botman.dbConnected then conn:execute("UPDATE server SET commandPrefix = '!'") end
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

			return
		end
	end


	if botman.readGG or botman.badServerConfig then
		number = tonumber(string.match(line, " (%d+)"))

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
			if botman.dbConnected then conn:execute("UPDATE server SET serverName = '" .. escape(server.serverName) .. "', ServerPort = " .. server.ServerPort) end
			return
		end

		if (string.find(line, "ZombiesRun =")) then
			server.ZombiesRun = number
			return
		end

		if (string.find(line, "ServerName =")) then
			server.serverName = string.trim(string.sub(line, 22))

			if string.find(string.lower(server.serverName), "pvp") and not string.find(string.lower(server.serverName), "pve") then
				server.gameType = "pvp"
			end

			return
		end

		if (string.find(line, "GameName =")) then
			server.GameName = string.trim(string.sub(line, 20))
			return
		end

		if (string.find(line, "ServerMaxPlayerCount =")) then
			number = tonumber(string.match(line, " (%d+)"))
			server.ServerMaxPlayerCount = number

			if server.maxPlayers == 0 then
				server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

				if server.reservedSlots > 0 then
					send("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
				end
			else
				if tonumber(server.maxPlayers) ~= tonumber(server.ServerMaxPlayerCount) - 1 then
					server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

					if tonumber(server.reservedSlots) > 0 then
						send("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end
					end
				end
			end

			return
		end

		if (string.find(line, "MaxSpawnedZombies =")) then
			server.MaxSpawnedZombies = number
			-- If we detect this line it means we are receiving data from the server so we set a flag to let us know elsewhere that we got server data ok.
			serverDataLoaded = true
			return
		end
	end


	if (string.find(line, "Process chat error")) then
		irc_chat(server.ircAlerts, "Server error detected. Re-validate to fix: " .. line)
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

		if tonumber(lag) > 6 then
			server.lagged = true
		end

		deleteLine()
		return
	end


	if string.find(line, "bot_RemoveInvalidItems") then
		removeInvalidItems()
		return
	end


	if string.find(line, "Version mismatch") then
		irc_chat(server.ircAlerts, line)
		return
	end

end

