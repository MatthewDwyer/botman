--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug = false
local deathMsg = { "a gruesome death.", ".. really?", " R.I.P" }

scanningSlots = false

function removeOldStaff()
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
	if botman.botDisabled then
		return
	end

	if string.find(line, "StackTrace:") then -- what is this shit?  ignore it.
		return
	end

	if string.find(line, "ERR ") then -- what is this shit?  ignore it.
		return
	end

	if string.find(line, "WRN ") then -- what is this shit?  ignore it.
		return
	end

	if string.find(line, "NaN") then -- what is this shit?  ignore it.
		return
	end

	if string.find(line, "Unbalanced") then -- what is this shit?  ignore it.
		return
	end

	if string.find(line, "->") then -- what is this shit?  ignore it.
		return
	end

	if string.find(line, "NullReferenceException:") then -- what is this shit?  ignore it.
		return
	end

	local pname, pid, number, died, coords, words, temp, msg
	local dy, mth, yr, hr, min, sec, pm, reason, timestamp, banDate
	local fields, values, x, z, id, loc, reset, steam, k, v, tmp

	if fixChunkDensity and string.find(line, "WRN DENSITYMISMATCH") then
		fixChunkDensity = nil
		temp = string.split(line, "\;")
		send("rcd " .. temp[2] .. " " .. temp[4] .. " fix")
	end

	if string.find(line, "WRN ") then
		return
	end

	-- set counter to help detect the bot going offline
	botman.botOfflineCount = 2
	botman.botOffline = false

	tmp = {}

        if ircListItems ~= nil then
                if string.sub(string.trim(line), 1, 5) == "Slot " then
                        ircListItems = nil
                end
        end

        if playerListItems ~= nil then
                if string.find(line, "Listed ") then
                        playerListItems = nil
                        return true
                end
        end

        if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

        if ircListItems ~= nil then
                if string.sub(line,1,4) == "    " and string.sub(line,5,5) ~= " " then
                        irc_chat(players[ircListItems].ircAlias, string.trim(line))
			return true
                end
        end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

        if playerListItems ~= nil then
                if string.sub(line,1,4) == "    " and string.sub(line,5,5) ~= " " then
                        message("pm " .. playerListItems .. " [" .. server.chatColour .. "]" .. string.trim(line) .. "[-]")
                end
        end


	-- Handle tracking of when we stop seeing Slot entries.

	if(string.sub(string.trim(line), 1, 5) == "Slot " and not scanningSlots) then
		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Set scanningSlots = true for: " .. invScan) end
		scanningSlots = true
		echo("Lists", line .. "\n")
		return true
	elseif(string.sub(string.trim(line), 1, 5) ~= "Slot " and scanningSlots) then
		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Clear scanningSlots for: " .. invScan) end
		scanningSlots = false

                if(invScan == "belt") then

		    if(igplayers[invCheckID] ~= nil) then
                        for k, v in pairs(beltSlots) do
                                if(v == false) then
                                        igplayers[invCheckID].inventory = igplayers[invCheckID].inventory .. "0,0,0,B-" .. k .. "|"
                                end
                        end

                        resetBeltSlots()
		    end
                elseif(invScan == "bagpack") then

		    if(igplayers[invCheckID] ~= nil) then
                        for k, v in pairs(packSlots) do
                                if(v == false) then
                                        igplayers[invCheckID].inventory = igplayers[invCheckID].inventory .. "0,0,0,P-" .. k .. "|"
                                end
                        end

                        resetPackSlots()
		    end

		elseif(invScan == "equipment") then

		     if(igplayers[invCheckID] ~= nil) then
			for k, v in pairs(equipmentSlots) do
				if(v == false) then
					igplayers[invCheckID].inventory = igplayers[invCheckID].inventory .. "0,0,0,E-" .. k .. "|"
				end
			end

			resetEquipmentSlots()
			if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Call CheckInventory()") end
			CheckInventory()
		     end
		else
			dbugFull("E", "", debugger.getinfo(1,"nSl"), "Unknown settings for invScan: " .. (invScan or "nil"))
		end

	end
	
	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if string.find(line, "INF Server shutting down!") then
		saveLuaTables()
		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if string.find(line, "ERROR: unknown command 'pug'") then
		server.scanNoclip = false
		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	-- detect server tools
	if string.find(line, "Mod SDX:") or string.find(line, "SDX: ") and not server.SDXDetected then
		server.SDXDetected = true
		if botman.dbConnected then conn:execute("UPDATE server SET SDXDetected = 1") end
		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	-- detect SDX mods
	if string.find(line, "Mod Server Tools:") or string.find(line, "mod 'Server Tools'") and not server.ServerToolsDetected then
		server.ServerToolsDetected = true
		if botman.dbConnected then conn:execute("UPDATE server SET ServerToolsDetected = 1") end
		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	-- detect CBSM
	if string.find(line, "pm CBSM") and server.CBSMFriendly then
		if server.commandPrefix == "/" then
			message("say [" .. server.chatColour .. "]CBSM detected.  Bot commands now begin with a ! to not clash with CBSM commands.[-]")
			message("say [" .. server.chatColour .. "]To use bot commands such as /who you must now type !who[-]")
			server.commandPrefix = "!"
			if botman.dbConnected then conn:execute("UPDATE server SET commandPrefix = '!'") end
		end

		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if string.find(line, "type=EntityZombie") then
		temp = string.split(line, " ")
		id = string.match(temp[7], "(-?%d+)")
		x = string.match(temp[9], "(-?%d+)")
		z = string.match(temp[11], "(-?%d+)")

		loc = inLocation(x, z)

		if not server.lagged then
			if not loc and server.gameType == "con" then
				send("removeentity " .. id)
			end

			if loc ~= false then
				if locations[loc].killZombies then
					send("removeentity " .. id)
				end
			end
		end

		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	-- check for lag
	if string.find(line, "pm LagCheck " .. server.botID) and string.find(line, server.botsIP) then
		botman.lagCheckRead = true
		server.lagged = false
		tmp.lag = os.time() - botman.lagCheckTime

		if tonumber(tmp.lag) > 10 then
			server.lagged = true
		end

		if server.lagged then
			irc_chat(server.ircAlerts, "Server lag detected")
		end

		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	-- look for general stuff
	died = false
--[[
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
--]]
	if (string.find(line, "INF GMSG: Player") and string.find(line, " died")) then
		pname = string.sub(line, string.find(line, "GMSG") + 14, string.len(line) - 6)
		pname = stripQuotes(string.trim(pname))
		died = true
	end

	if (string.find(line, "Process chat error")) then
		irc_chat(server.ircAlerts, "Server error detected. Re-validate to fix: " .. line)
		return false
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if died then
		pid = LookupPlayer(pname, "all")

		if (pid ~= nil) then
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[pid].xPos) .. "," .. math.ceil(igplayers[pid].yPos) .. "," .. math.floor(igplayers[pid].zPos) .. ",'" .. botman.serverTime .. "','death','" .. escape(pname) .. " died'," .. pid .. ")") end

			players[pid].tp = 1
			players[pid].hackerTPScore = 0
			igplayers[pid].deadX = math.floor(igplayers[pid].xPos)
			igplayers[pid].deadY = math.ceil(igplayers[pid].yPos)
			igplayers[pid].deadZ = math.floor(igplayers[pid].zPos)
			igplayers[pid].teleCooldown = 1000

			players[pid].deathX = igplayers[pid].xPos
			players[pid].deathY = igplayers[pid].yPos
			players[pid].deathZ = igplayers[pid].zPos

			irc_chat(server.ircMain, "Player " .. pid .. " name: " .. pname .. "'s death recorded at " .. igplayers[pid].deadX .. " " .. igplayers[pid].deadY .. " " .. igplayers[pid].deadZ)
			irc_chat(server.ircAlerts, "Player " .. pid .. " name: " .. pname .. "'s death recorded at " .. igplayers[pid].deadX .. " " .. igplayers[pid].deadY .. " " .. igplayers[pid].deadZ)

			echo(os.date("%c").. " Player died " .. players[pid].name .. " id=" .. pid .. "(")
			echoLink(pid,  "openUrl(\"http://steamcommunity.com/profiles/" .. pid .. "\")", "Click to view players Steam profile.")
			echo(") @ x=" .. players[pid].deathX .. ", y=" .. players[pid].deathY .. ", z=" .. players[pid].deathZ .. "\n\n")

			message("say [" .. server.chatColour .. "]" .. players[pid].name .. " has died " .. deathMsg[math.random(1,3)])

			if tonumber(server.packCooldown) > 0 then
				players[pid].packCooldown = os.time() + server.packCooldown
			end
		end

		-- nuke their gimme queue of zeds
		if(type(gimmeQueuedCommands) == "table") then
			for k, v in pairs(gimmeQueuedCommands) do
				if (v.steam == pid) and (string.find(v.cmd, "se " .. pid)) then
					gimmeQueuedCommands[k] = nil
				end
			end
		end

		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (string.find(line, "ServerMaxPlayerCount set to")) then
		number = tonumber(string.match(line, " (%d+)"))
		server.ServerMaxPlayerCount = number

		if server.maxPlayers == 0 then
			server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

			if tonumber(server.reservedSlots) > 0 then
				send("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full
			end
		end

		return true
	end


	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (string.sub(line, 1, 4) == os.date("%Y")) then
		botman.readGG = false

		if (echoConsole ~= nil) then
			echoConsole = nil
			echoConsoleTo = l
		end
	end


	if botman.readGG then
		number = tonumber(string.match(line, " (%d+)"))

		if (string.find(line, "MaxSpawnedZombies set to")) then
			server.MaxSpawnedZombies = number
		end

		if (string.find(line, "MaxSpawnedAnimals set to")) then
			server.MaxSpawnedAnimals = number
		end

		if (string.find(line, "LootRespawnDays =")) then
			server.LootRespawnDays = number
		end

		if (string.find(line, "BlockDurabilityModifier =")) then
			server.BlockDurabilityModifier = number
		end

		if (string.find(line, "DayNightLength =")) then
			server.DayNightLength = number
		end

		if (string.find(line, "DayLightLength =")) then
			server.DayLightLength = number
		end

		if (string.find(line, "DropOnDeath =")) then
			server.DropOnDeath = number
		end

		if (string.find(line, "DropOnQuit =")) then
			server.DropOnQuit = number
		end

		if (string.find(line, "EnemyDifficulty =")) then
			server.EnemyDifficulty = number
		end

		if (string.find(line, "EnemySenseMemory =")) then
			server.EnemySenseMemory = number
		end

		if (string.find(line, "LandClaimSize =")) then
			server.LandClaimSize = number
		end

		if (string.find(line, "LootAbundance =")) then
			server.LootAbundance = number
		end

		if (string.find(line, "LootRespawnDays =")) then
			server.LootRespawnDays = number
		end

		if (string.find(line, "ServerPort =")) then
			server.ServerPort = number
			if botman.dbConnected then conn:execute("UPDATE server SET serverName = '" .. escape(server.serverName) .. "', ServerPort = " .. server.ServerPort) end
		end

		if (string.find(line, "ZombiesRun =")) then
			server.ZombiesRun = number
		end

		if (string.find(line, "ServerName =")) then
			server.serverName = string.trim(string.sub(line, 22))

			if string.find(string.lower(server.serverName), "pvp") and not string.find(string.lower(server.serverName), "pve") then
				server.gameType = "pvp"
			end
		end

		if (string.find(line, "GameName =")) then
			server.GameName = string.trim(string.sub(line, 20))
		end

		if (string.find(line, "ServerMaxPlayerCount =")) then
			server.ServerMaxPlayerCount = number

			if server.maxPlayers == 0 then
				server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

				if server.reservedSlots > 0 then
					send("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full
				end
			end
		end

		if (string.find(line, "MaxSpawnedZombies =")) then
			server.MaxSpawnedZombies = number
			-- If we detect this line it means we are receiving data from the server so we set a flag to let us know elsewhere that we got server data ok.
			serverDataLoaded = true
		end
	end


	if getAdminList ~= nil then
		if string.sub(line, 1, 4) ~= "    " then
			getAdminList = nil
		end

		removeOldStaff()
	end


	if getAdminList ~= nil then
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
		end
	end


	-- update owners, admins and mods
	if string.find(line, "Level: SteamID (Player name if online)", nil, true) then
		getAdminList = true
		staffList = {}
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

			return true
		end

	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end


--[[
	-- collect the ban list
	if collectBans ~= nil then
		if (string.find(line, " AM ")) or (string.find(line, " PM ")) and not string.find(line, "banned until") then
                        temp = string.split(line, "-")
                        steam = string.trim(temp[2])

			if(debug and not steam) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "steam = nil from " .. line) end

			if botman.dbConnected then conn:execute("INSERT INTO bans (BannedTo, steam, reason) VALUES ('" .. string.trim(temp[1]) .. "'," .. steam .. ",'" .. string.trim(temp[3]) .. "')") end

			-- also insert the steam owner (will only work if the steam id is different)

			-- if botman.dbConnected then conn:execute("INSERT INTO bans (BannedTo, steam, reason) VALUES ('" .. string.trim(temp[1]) .. "'," .. players[steam].steamOwner .. ",'" .. string.trim(temp[3]) .. "')") end
			-- if botman.dbConnected then conn:execute("INSERT INTO bans (BannedTo, steam, reason) VALUES ('" .. string.trim(temp[1]) .. "'," .. steam .. ",'" .. string.trim(temp[3]) .. "')") end
		end
	end
--]]


	if (string.find(line, "Banned until")) then
		collectBans = true
		return
	end


	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	-- get zombies into table gimmeZombies
	if getZombies ~= nil then
		if string.find(line, "ombie") then
			temp = string.split(line, "-")

			tmp = {}
			tmp.entityID = string.trim(temp[1])
			tmp.zombie = string.trim(temp[2])

			if botman.dbConnected then conn:execute("INSERT INTO gimmeZombies (zombie, entityID) VALUES ('" .. tmp.zombie .. "'," .. tmp.entityID .. ")") end
			updateGimmeZombies(tmp.entityID, tmp.zombie)
			return true
		else
			if (string.sub(line, 1, 4) ~= os.date("%Y")) then
				temp = string.split(line, "-")

				tmp = {}
				tmp.entityID = string.trim(temp[1])
				tmp.entity = string.trim(temp[2])


				if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), (tmp.entityID or "nil") .. ", " .. (tmp.entity or "nil") .. ", " .. line) end
				if(tmp.etntity ~= nil) then
					if botman.dbConnected then conn:execute("INSERT INTO otherEntities (entity, entityID) VALUES ('" .. tmp.entity .. "'," .. tmp.entityID .. ")") end
					updateOtherEntities(tmp.entityID, tmp.entity)
					return true
				end
			end
		end
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (string.match(line, "please specify one of the entities")) then
		-- flag all the zombies for removal so we can detect deleted zeds
		for k,v in pairs(gimmeZombies) do
			gimmeZombies[k].remove = true
		end

		getZombies = true
		return
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if string.find(line, "command 'rcd") and string.find(line, server.botsIP) then
		fixChunkDensity = true
		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if string.find(line, "Executing command 'gg'") and string.find(line, server.botsIP) then
		botman.readGG = true
		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if string.find(line, "Executing command 'le'") and string.find(line, server.botsIP) then
		botman.listEntities = true
		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if(not server) then
		dbugFull("D", "", debugger.getinfo(1,"nSl"), "Fixing nil server")
		server = {}
	end

	if(not server.botsIP) then
		dbugFull("D", "", debugger.getinfo(1,"nSl"), "Fixing nil server.botsIP")
		server.botsIP = "127.0.0.1"
	end

	if string.find(line, "Executing command 'version'") and string.find(line, server.botsIP) then
		server.SDXDetected = false
		server.ServerToolsDetected = false

		if botman.dbConnected then
			conn:execute("UPDATE server SET SDXDetected = 0")
			conn:execute("UPDATE server SET ServerToolsDetected = 0")
		end

		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if echoConsoleTo ~= nil then
		if string.find(line, "Executing command 'help") and string.find(line, server.botsIP) then
			echoConsole = true
			return
		end

		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if string.find(line, "Executing command 'version'") and string.find(line, server.botsIP) then
			echoConsole = true
			return
		end

		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if string.find(line, "Executing command 'le'") and string.find(line, server.botsIP) then
			echoConsole = true
			return
		end

		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if string.find(line, "Executing command 'li ") and string.find(line, server.botsIP) then
			echoConsole = true
			return
		end

		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if string.find(line, "Executing command 'se'") and string.find(line, server.botsIP) then
			echoConsole = true
			return
		end

		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if string.find(line, "Executing command 'si ") and string.find(line, server.botsIP) and string.find(line, echoConsoleTrigger) then
			echoConsole = true
			return
		end

		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if string.find(line, "Executing command 'gg'") and string.find(line, server.botsIP) then
			echoConsole = true
			return
		end

		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if string.find(line, "Executing command 'llp") and string.find(line, server.botsIP) then
			echoConsole = true
			return
		end

		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if string.find(line, "Executing command 'ban list'") and string.find(line, server.botsIP) then
			echoConsole = true
			return
		end

		-- if (string.sub(line, 1, 4) == os.date("%Y")) then
			-- botman.readGG = false

			-- if (echoConsole ~= nil) then
				-- echoConsole = nil
				-- echoConsoleTo = l
			-- end
		-- end

		if echoConsole == true then
			line = line:gsub(",", "") -- strip out commas
			irc_chat(echoConsoleTo, line)
		end
	end


	if (string.sub(line, 1, 4) == os.date("%Y")) then
		collectBans = nil

		if getZombies then
			getZombies = nil

			-- remove any zombies that are still flagged for removal
			for k,v in pairs(gimmeZombies) do
				if gimmeZombies[k].remove then
					pruneZIndex(k)
					gimmeZombies[k] = nil
				end
			end

			if botman.dbConnected then
				cursor,errorString = conn:execute("SELECT Count(entityID) as maxZeds from gimmeZombies")
				row = cursor:fetch({}, "a")
				botman.maxGimmeZombies = tonumber(row.maxZeds)
			end
		end
		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	--2015-08-23T15:08:25 87646.450 INF Executing command 'pm IPCHECK' by Telnet from 127.0.0.1:59765
	if string.find(line, "IPCHECK") then
		temp = string.sub(line, string.find(line, "from ") + 5)
		server.botsIP = string.sub(temp, 1, string.find(temp, ":") - 1)
		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	-- detect Coppi's Mod
	if string.find(line, "Mod Coppis command additions") then
		server.coppi = true

		if server.hideCommands then
			send("tcch " .. server.commandPrefix)
		end

		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
	-- detect Alloc's Mod
	if string.find(line, "Mod Allocs server fixes") then
		server.allocs = true
		return true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if server.coppi and not server.playersCanFly then
		if string.find(line, "PUG: entity_id") then
			words = {}
			for word in string.gmatch(line, "(-?%d+)") do
				table.insert(words, word)
			end

			pid = words[1]

			if(pid == nil) then
				dbugFull("E", "", debugger.getinfo(1,"nSl"), "pid == nil from (" .. line ..")")
			end
			local oldpid = pid
			pid = LookupPlayer(pid)

			if(pid == nil) then
				dbugFull("E", "", debugger.getinfo(1,"nSl"), "pid == nil from LookupPlayer(" .. oldpid ..")(" .. line ..")")
			end

			-- if players[pid].newPlayer then
				temp = 5
			-- else
				-- temp = 30
			-- end

			if string.find(line, "isUnderGround=True") and accessLevel(pid) > 2 then
				igplayers[pid].noclip = true

				if igplayers[pid].noclipX == 0 and igplayers[pid].noclipZ == 0 then
					igplayers[pid].noclipX = math.floor(igplayers[pid].xPos)
					igplayers[pid].noclipZ = math.floor(igplayers[pid].zPos)
				else
					dist = distancexz(igplayers[pid].noclipX,igplayers[pid].noclipZ,math.floor(igplayers[pid].xPos),math.floor(igplayers[pid].zPos))
					igplayers[pid].noclipX = math.floor(igplayers[pid].xPos)
					igplayers[pid].noclipZ = math.floor(igplayers[pid].zPos)

					if tonumber(dist) > 5 then
						if players[pid].newPlayer then
							if tonumber(players[pid].ping) > 150 then
								players[pid].hackerScore = tonumber(players[pid].hackerScore) + 40
							else
								players[pid].hackerScore = tonumber(players[pid].hackerScore) + 20
							end
						else
							players[pid].hackerScore = tonumber(players[pid].hackerScore) + 15
						end
					end

					if dist > temp then
						alertAdmins("[" .. server.alertColour .. "]Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (hacker score: " .. players[pid].hackerScore .. ") " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos) .. "[-]", "warn")
						irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos))
						irc_chat(server.ircAlerts, "Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos))
					end
				end
			else
				if(not pid) then
					 dbugFull("E", debugger.traceback(),debugger.getinfo(1,"nSl"), "pid = nil " .. line)
                                         return true
				end

				if(igplayers[pid] == nil) then
                				dbugFull("E", debugger.traceback(),debugger.getinfo(1,"nSl"), "igplayers[pid] = nil " .. line)
                				return true
        			end

				igplayers[pid].noclip = false
				igplayers[pid].noclipCount = 0
				igplayers[pid].noclipX = 0
				igplayers[pid].noclipZ = 0
			end

			return true
		end


		if string.find(line, "PGD: entity_id") then
			words = {}
			for word in string.gmatch(line, "(-?%d+)") do
				table.insert(words, word)
			end

			pid = words[1]

			if(pid == nil) then
				 dbugFull("E", debugger.traceback(),debugger.getinfo(1,"nSl"), "pid = nil " .. line)
                                 return true
			end

			pid = LookupPlayer(pid)

			if(pid == nil) then
				dbugFull("E", debugger.traceback(),debugger.getinfo(1,"nSl"), "pid = nil " .. line)
                               	return true
			else
				if(igplayers[pid] == nil) then
 					dbugFull("E", debugger.traceback(),debugger.getinfo(1,"nSl"), "igplayers[pid] = nil " .. line)
                                        return true
				end
			end
			igplayers[pid].flying = false
			dist = tonumber(words[2])

			if dist > 5 and accessLevel(pid) > 2 then
				if not players[pid].timeout and not players[pid].botTimeout and igplayers[pid].lastTP == nil and not players[pid].ignorePlayer then
					igplayers[pid].flying = true

					if igplayers[pid].flyingX == 0 then
						igplayers[pid].flyingX = math.floor(igplayers[pid].xPos)
						igplayers[pid].flyingZ = math.floor(igplayers[pid].zPos)
					else
						dist = distancexz(igplayers[pid].flyingX,igplayers[pid].flyingZ,math.floor(igplayers[pid].xPos),math.floor(igplayers[pid].zPos))

						if tonumber(dist) > 5 then
							if players[pid].newPlayer then
								if tonumber(players[pid].ping) > 150 then
									players[pid].hackerScore = tonumber(players[pid].hackerScore) + 40
								else
									players[pid].hackerScore = tonumber(players[pid].hackerScore) + 20
								end
							else
								players[pid].hackerScore = tonumber(players[pid].hackerScore) + 15
							end
						end

						igplayers[pid].flyingX = math.floor(igplayers[pid].xPos)
						igplayers[pid].flyingZ = math.floor(igplayers[pid].zPos)

						if dist > 5 then
						--if dist > 15 and dist < 100 then
							igplayers[pid].flyCount = igplayers[pid].flyCount + 1

							if tonumber(igplayers[pid].flyCount) > 1 then
								irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (session: " .. players[pid].sessionCount .. " hacker score: " .. players[pid].hackerScore .. ") " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos))
								irc_chat(server.ircAlerts, "Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (session: " .. players[pid].sessionCount .. " hacker score: " .. players[pid].hackerScore .. ") " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos))
							end

							if tonumber(igplayers[pid].flyCount) > 2 then
								alertAdmins("[" .. server.alertColour .. "]Player " .. pid .. " " .. igplayers[pid].name .. " may be flying (hacker score: " .. players[pid].hackerScore .. ") " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos) .. "[-]", "warn")
							end
						end
					end
				end
			end

			if not igplayers[pid].flying then
				igplayers[pid].flyCount = 0
				igplayers[pid].flyingX = 0
				igplayers[pid].flyingZ = 0
			end

			if not igplayers[pid].noclip and not igplayers[pid].flying then

				if(not players[pid]) then
					if(debug) then
						dbugFull("D", "",debugger.getinfo(1,"nSl"), "Unable to find name from: " .. line)
					end
				elseif tonumber(players[pid].hackerScore) > 0 then
					players[pid].hackerScore = tonumber(players[pid].hackerScore) - 5
				end
			end

			return true
		end


		-- player chat colour
		if string.find(line, "command 'cpc", nil, true) then
			tmp = {}
			tmp.line = string.sub(line, string.find(line, "command ") + 9, string.find(line, " from") - 2)
			tmp.parts = string.split(tmp.line, " ")
			tmp.colour = tmp.parts[3]
			tmp.name = tmp.parts[2]
			tmp.steam = LookupPlayer(tmp.name, "all")

			players[tmp.steam].chatColour = tmp.colour
			if botman.dbConnected then conn:execute("UPDATE players SET chatColour = '" .. escape(tmp.colour) .. "' WHERE steam = " .. tmp.steam) end
			return true
		end


		-- player bed
		if string.sub(line, 1, 11) == "PlayerBed: " then
			tmp = {}
			tmp.name = string.sub(line, 12, string.find(line, " at ") - 1)
			tmp.steam = LookupPlayer(tmp.name)

			if tmp.steam then
				tmp.split = string.split(string.sub(line, string.find(line, " at ") + 4), ",")
				tmp.x = string.trim(tmp.split[1])
				tmp.y = string.trim(tmp.split[2])
				tmp.z = string.trim(tmp.split[3])

				players[tmp.steam].bedX = tmp.x
				players[tmp.steam].bedY = tmp.y
				players[tmp.steam].bedZ = tmp.z
				if botman.dbConnected then conn:execute("UPDATE players SET bedX = " .. tmp.x .. ", bedY = " .. tmp.y .. ", bedZ = " .. tmp.z .. " WHERE steam = " .. tmp.steam) end
			end
			return true
		end
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if(string.match(line, "%d+. id=") or
	   string.match(line, "Total of %d+ in the game") or
           string.match(line, "Slot %d+:") or 
	   string.match(line, " of player ") or
 	   string.match(line, "Day %d+, %d+:%d+") or 
	   string.match(line, "%d+ - .*$") or
	   string.match(line, "^GamePref.") or
	   string.match(line, "Slot .*: ") or
	   string.match(line, "FriendsOf id=") or
	   string.trim(line) == "" or
	   string.match(line, "- .* - .*: %d+$"))
	then
		echo("Lists", line .. "\n")
		return true
	end

	if(string.match(line, "please specify one of the") or
	   string.match(line, "Message to player ") or
	   string.match(line, "^World saved$") or
	   string.match(line, "chatColor=FFFFFF$") or
	   string.match(line, "max chat length changed to $d+$") or
	   string.match(line, "Usage: tel")) 
	then
		return true
	end

	echo("Lists", line .. "\n")
	return false
end
