--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function matchAll(line)
	if botDisabled then
		return
	end
	
	if string.find(line, "->") or string.find(line, "NullReferenceException:") or string.find(line, "NaN") then -- what is this shit?  ignore it.
		return
	end

	local pname, pid, number, died, coords, words, temp, msg
	local dy, mth, yr, hr, min, sec, pm, reason, timestamp, banDate
	local fields, values, x, z, id, loc, reset, steam, k, v

	-- set counter to help detect the bot going offline
	botOffline = 2

	if string.find(line, "INF Server shutting down!") then
		saveLuaTables()
	end

	if string.find(line, "type=EntityZombie") then
		temp = string.split(line, " ")
		id = string.match(temp[7], "(-?%d+)")
		x = string.match(temp[9], "(-?%d+)")
		z = string.match(temp[11], "(-?%d+)")

		loc = inLocation(x, z)

		if not loc and server.gameType == "con" then
			send("kill " .. id)
		end

		if loc ~= false then
			if locations[loc].killZombies then
				send("kill " .. id)
			end
		end
	end

	if server.coppi then
		if string.find(line, "friends:") then
			collectFriends = string.sub(line, 1, string.find(line, "friends:") - 2)
			collectFriends = LookupPlayer(collectFriends)
		end
	end

	-- look for general stuff
	died = false
	if (string.find(line, "INF GMSG") and string.find(line, "eliminated")) then
		nameStart = string.find(line, "eliminated ") + 11
		pname = string.trim(string.sub(line, nameStart))
		died = true
	end

	if (string.find(line, "INF GMSG: Player") and string.find(line, " died")) then
		pname = string.sub(line, string.find(line, "GMSG") + 14, string.len(line) - 6)
		pname = string.trim(pname)
		died = true
	end

	if died then
		pid = LookupPlayer(pname)

		if (pid ~= nil) then
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[pid].xPos) .. "," .. math.ceil(igplayers[pid].yPos) .. "," .. math.floor(igplayers[pid].zPos) .. ",'" .. serverTime .. "','death','" .. escape(pname) .. " died'," .. pid .. ")")

			players[pid].tp = 1
			players[pid].hackerScore = 0
			igplayers[pid].deadX = math.floor(igplayers[pid].xPos)
			igplayers[pid].deadY = math.ceil(igplayers[pid].yPos)
			igplayers[pid].deadZ = math.floor(igplayers[pid].zPos)

			players[pid].deathX = igplayers[pid].xPos
			players[pid].deathY = igplayers[pid].yPos
			players[pid].deathZ = igplayers[pid].zPos

			if inLocation(players[pid].deathX, players[pid].deathZ) == "deadzone" then
				players[pid].baseCooldown = 0
				conn:execute("UPDATE players SET baseCooldown = 0 WHERE steam = " .. pid)
			end

			irc_QueueMsg(server.ircMain, "Player " .. pid .. " name: " .. pname .. "'s death recorded at " .. igplayers[pid].deadX .. " " .. igplayers[pid].deadY .. " " .. igplayers[pid].deadZ)

			if tonumber(server.packCooldown) > 0 then
				players[pid].packCooldown = os.time() + server.packCooldown
			end

			if players[pid].watchPlayer then
				irc_QueueMsg(server.ircTracker, gameDate .. " " .. pid .. " " .. players[pid].name .. " died at " .. igplayers[pid].deadX .. " " .. igplayers[pid].deadY .. " " .. igplayers[pid].deadZ)
			end
		end

		-- nuke their gimme queue of zeds
		for k, v in pairs(gimmeQueuedCommands) do
			if (v.steam == pid) and (string.find(v.cmd, "se " .. pid)) then
				gimmeQueuedCommands[k] = nil
			end
		end
	end

	number = tonumber(string.match(line, " (%d+)"))

	if (string.find(line, "ServerMaxPlayerCount set to")) then
		server.ServerMaxPlayerCount = number
	end

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
	end

	if (string.find(line, "ZombiesRun =")) then
		server.ZombiesRun = number
	end

	if (string.find(line, "ServerName =")) then
		server.ServerName = string.trim(string.sub(line, 22))
	end

	if (string.find(line, "GameName =")) then
		server.GameName = string.trim(string.sub(line, 20))
	end

	if (string.find(line, "ServerMaxPlayerCount =")) then
		server.ServerMaxPlayerCount = number
	end

	if (string.find(line, "MaxSpawnedZombies =")) then
		server.MaxSpawnedZombies = number
		-- If we detect this line it means we are receiving data from the server so we set a flag to let us know elsewhere that we got server data ok.
		serverDataLoaded = true
	end

	conn:execute("UPDATE server SET serverName = '" .. escape(server.ServerName) .. "', ServerPort = " .. server.ServerPort)

	if getAdminList ~= nil then
		if string.sub(line, 1, 4) ~= "    " then
			getAdminList = nil
		end
	end

	if getAdminList ~= nil then
		temp = string.split(line, ":")
		temp[1] = string.trim(temp[1])
		temp[2] = string.trim(string.sub(temp[2], 1, 18))

		number = tonumber(temp[1])
		pid = temp[2]

		if players[pid] then
			if number == 0 then
				owners[pid] = {}
			end

			if number == 1 then
				admins[pid] = {}
			end

			if number == 2 then
				mods[pid] = {}
			end

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
			conn:execute("UPDATE players SET newPlayer = 0, silentBob = 0, walkies = 0, exiled = 2, canTeleport = 1, enableTP = 1, botHelp = 1, accessLevel = " .. number .. " WHERE steam = " .. pid)		
		end
	end

	-- update owners, admins and mods
	if (line == "  Level: SteamID (Player name if online)") then
		owners = {}
		admins = {}
		mods = {}
		getAdminList = true
	end


	if string.sub(line, 1, 4) == "   (" then
		coords = string.split(string.sub(line, 5, string.len(line) - 1), ",")

		if players[llpid].removedClaims == nil then
			players[llpid].removedClaims = 0
		end

		conn:execute("UPDATE keystones SET remove = 1 WHERE steam = " .. llpid .. " AND x = " .. coords[1] .. " AND y = " .. coords[2] .. " AND z = " .. coords[3] .. " AND remove > 1")
		conn:execute("UPDATE keystones SET removed = 0 WHERE steam = " .. llpid .. " AND x = " .. coords[1] .. " AND y = " .. coords[2] .. " AND z = " .. coords[3])

		if accessLevel(llpid) > 3 then
			region = getRegion(coords[1], coords[3])

			loc, reset = inLocation(coords[1], coords[3])

			if (resetRegions[region]) or reset or players[llpid].removeClaims == true then
				conn:execute("INSERT INTO keystones (steam, x, y, z, remove) VALUES (" .. llpid .. "," .. coords[1] .. "," .. coords[2] .. "," .. coords[3] .. ",1) ON DUPLICATE KEY UPDATE remove = 1")
			else
				conn:execute("INSERT INTO keystones (steam, x, y, z) VALUES (" .. llpid .. "," .. coords[1] .. "," .. coords[2] .. "," .. coords[3] .. ")")
			end		
		else
			conn:execute("INSERT INTO keystones (steam, x, y, z) VALUES (" .. llpid .. "," .. coords[1] .. "," .. coords[2] .. "," .. coords[3] .. ")")
		end
	end


	if ircListItems ~= nil and string.sub(string.trim(line), 1, 5) == "Slot " then
		ircListItems = nil
	end


	if ircListItems ~= nil then
		if string.sub(line,1,4) == "    " and string.sub(line,5,5) ~= " " then
			irc_QueueMsg(players[ircListItems].ircAlias, string.trim(line))
		end
	end


	-- collect the ban list
	if collectBans ~= nil then
		if (string.find(line, " AM ")) or (string.find(line, " PM ")) and not string.find(line, "banned until") then
			temp = string.split(line, "-")
			steam = string.trim(temp[2])

			conn:execute("INSERT INTO bans (BannedTo, steam, reason) VALUES ('" .. string.trim(temp[1]) .. "'," .. steam .. ",'" .. string.trim(temp[3]) .. "')")

			-- also insert the steam owner (will only work if the steam id is different)
			conn:execute("INSERT INTO bans (BannedTo, steam, reason) VALUES ('" .. string.trim(temp[1]) .. "'," .. players[steam].steamOwner .. ",'" .. string.trim(temp[3]) .. "')")
		end
	end


	if (string.find(line, "Banned until")) then
		collectBans = true
	end


	if echoConsoleTo ~= nil then
		if string.find(line, "Executing command 'help") then
			echoConsole = true
			return
		end

		if string.find(line, "Executing command 'se'") then
			echoConsole = true
			return
		end

		if string.find(line, "Executing command 'si ") and string.find(line, echoConsoleTrigger) then
			echoConsole = true
			return
		end

		if string.find(line, "Executing command 'gg'") then
			echoConsole = true
			return
		end

		if string.find(line, "Executing command 'llp") then
			echoConsole = true
			return
		end

		if string.find(line, "Executing command 'ban list'") then
			echoConsole = true
			return
		end

		if (echoConsole ~= nil) and (string.sub(line, 1, 4) == os.date("%Y")) then
			echoConsole = nil
			echoConsoleTo = l
		end

		if echoConsole == true then
			line = line:gsub(",", "") -- strip out commas
			irc_QueueMsg(echoConsoleTo, line)
		end
	end


	if (string.sub(line, 1, 4) == os.date("%Y")) then
		collectBans = nil
		collectFriends = nil
	end


	-- collect the friend list
	if collectFriends ~= nil then
	--	if not string.find(line, "friends:") then
	--		temp = string.split(line, " ")
	--		pid = LookupPlayer(temp[4])		

	--		if (not string.find(friends[collectFriends].friends, pid)) then
	--			friends[collectFriends].friends = friends[collectFriends].friends .. pid .. ","
	--			irc_QueueMsg(server.ircMain, players[collectFriends].name .. " is now friends with " .. players[pid].name)

	--			if igplayers[collectFriends] then
	--				message("pm " .. collectFriends .. " [" .. server.chatColour .. "]" .. players[pid].name .. " is now recognised as a friend[-]")	
	--			end

	--			conn:execute("INSERT INTO friends (steam, friend) VALUES (" .. collectFriends .. "," .. pid .. ")")
	--		end

	--	end
	end


	--2015-08-23T15:08:25 87646.450 INF Executing command 'pm IPCHECK' by Telnet from 127.0.0.1:59765
	if string.find(line, "IPCHECK") then
		temp = string.sub(line, string.find(line, "from ") + 5)
		server.botsIP = string.sub(temp, 1, string.find(temp, ":") - 1)
	end

	
	if string.find(line, "Physics enabled: False") then
		if server.allowPhysics and server.coppi then
			send("py")
		end
	end


	if string.find(line, "Physics enabled: True") then
		if not server.allowPhysics and server.coppi then
			send("py")
		end
	end
	

	-- detect UberFox's mod
	if not server.ubex then
		if string.find(line, "UBEXV") then
			server.ubex = true
			server.coppi = false
			dbug("Bot is using Uberfox's mod")
			
			-- disable Coppi's command hider as it can prevent UberFox's mod seeing commands.
			send("tcch")
		end
	end


	-- detect Coppi's modded Alloc's Mod
	if not server.ubex then
		if string.find(line, "Command: tcch") or string.find(line, "Usage: teleportplayerhome") then
			server.coppi = true
			server.ubex = false
			dbug("Bot is using Coppi's additions")

			if server.hideCommands then
				send("tcch /")
			end
		end
	end
	
	-- support for ubex commands
	if string.find(line, "FAPGD SUCCESS") then
		for k,v in pairs(igplayers) do
			v.flying = false
		end
			
		if not string.find(line, "IdCount=0") then
			temp = stripQuotes(string.sub(line, string.find(line, "IdList=") + 7))
			temp = string.split(temp, "|")
			
			for x=1,tablelength(temp),1 do
				pid = temp[x]
				
				if not players[pid].timeout and not players[pid].botTimeout and igplayers[pid].lastTP == nil and not players[pid].ignorePlayer then
					igplayers[pid].flying = true
					
					if (math.floor(igplayers[pid].yPos) - math.floor(igplayers[pid].yPosLast)) > 3 and tonumber(igplayers[pid].yPosLast) ~= 0 then
						igplayers[pid].flyCount = igplayers[pid].flyCount + 1

						if accessLevel(pid) > 2 then
							msg = "Player " .. igplayers[pid].name .. " detected flying (" .. igplayers[pid].flyCount .. ") " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos)
							irc_QueueMsg(server.ircAlerts, msg)
						
							if tonumber(igplayers[pid].flyCount) > 1 then
								irc_QueueMsg(server.ircMain, msg)
								
								for k,v in pairs(igplayers) do
									if accessLevel(k) < 3 then
										message("pm " .. k .. " " .. msg .. "[-]")
									end
								end
							end
						end
					end
					
					if tonumber(igplayers[pid].flyCount) > 2 and accessLevel(pid) > 2 and players[pid].newPlayer and tonumber(players[pid].ping) > 180 then
						if not players[pid].prisoner then
							arrest(pid, "possibly flying.")
							message("pm " .. pid .. " We have detected that you were flying.  You will be released if we find that you did not fly.[-]")
						else
							message("say [" .. server.chatColour .. "]Temp-banning " .. players[pid].name .. " 1 day.  Detected flying while in prison.[-]")
							banPlayer(pid, "1 day", "You are temp banned for flying while in prison.", "")
						end
					end
				end
			end
		end
			
		for k,v in pairs(igplayers) do
			if not v.flying then
				v.flyCount = 0
			end
		end
	end
end

