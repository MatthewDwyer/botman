--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug

-- enable debug to see where the code is stopping. Any error will be somewhere after the last successful debug line.
debug = false -- should be false unless testing

function playerConnected(line)
	local temp_table, temp, commas, freeSlots, test, tmp, cmd, pid
	local timestamp = os.time()
	local cursor, errorString, rows, row, k, v
	local foundSteam, foundIP, foundSteamOwner, foundEntity, foundName

	if not badPlayerJoined then
		badPlayerJoined = false
		badJoinLine = ""
	end

	foundSteam = false
	foundIP = false
	foundSteamOwner = false
	foundEntity = false
	foundName = false

	if botman.debugAll then
		debug = true -- this should be true
	end

	-- Papers please
	tmp = {}

	if playerConnectCounter == nil then
		playerConnectCounter = 1
	else
		playerConnectCounter = 	playerConnectCounter + 1
	end

	if (debug) then
		dbug("line " .. line)
		-- dbug("debug playerConnectCounter " .. playerConnectCounter)
		-- dbug("botman.playersOnline " .. botman.playersOnline)
		-- dbug("server.maxPlayers " .. server.maxPlayers)
		-- dbug("server.reservedSlots " .. server.reservedSlots)

		-- if server.ServerMaxPlayerCount then
			-- dbug("server.ServerMaxPlayerCount " .. server.ServerMaxPlayerCount)
		-- end
	end

	local _, commas = string.gsub(line, ",", "")

	temp = string.sub(line, 1, string.find(line, " INF "))
	if string.find(temp, ",") then
		commas = commas - 1
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if not badPlayerJoined then
		if commas > 5 then
			-- player has one or more commas in their name.  That screws with parsing lines so kick them with a message to change their name.
			temp = string.find(line, "steamOwner=") + 11
			tmp.steamOwner = string.sub(line, temp, temp + 16)

			kick(tmp.steamOwner, "You have one or more commas in your name. Please remove them.")
			irc_chat(server.ircAlerts, server.gameDate .. " player kicked for too many commas (not allowed in player name) " .. line)
			return
		end
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	temp_table = string.split(line, ",")
	timeConnected = string.sub(line, 1, 19)

	if string.find(line, "entityid=") then
		temp = string.split(temp_table[2], "=")
		tmp.entityid = temp[2]
		foundEntity = true
	end

	if string.find(line, "name=") then
		temp = string.split(temp_table[3], "name=")
		tmp.player = temp[2]
		foundName = true
	end

	if string.find(line, "steamid=") then
		temp = string.split(temp_table[4], "=")
		tmp.steam = temp[2]
		foundSteam = true

		if type(tmp.steam) ~= "string" then
			return
		end
	end

	if string.find(line, "steamOwner=") then
		temp = string.split(temp_table[5], "=")
		tmp.steamOwner = temp[2]
		foundSteamOwner = true
	end

	if string.find(line, "ip=") then
		temp = string.split(temp_table[6], "=")
		tmp.ip = temp[2]
		tmp.ip = tmp.ip:gsub("::ffff:","")
		foundIP = true
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if not foundEntity or not foundSteam or not foundSteamOwner or not foundName or not foundIP then
		badPlayerJoined = true
		badJoinLine = line
		return
	end

	if tmp.steam ~= tmp.steamOwner and not server.allowFamilySteamKeys then
		kick(tmp.steamOwner, "This server does not allow family steam keys.")
		irc_chat(server.ircAlerts, server.gameDate .. " player kicked because steam key " .. tmp.steam .. " does not match steamOwner " .. tmp.steamOwner)
		return
	end

	if tmp.steam then
		pid = LookupOfflinePlayer(tmp.steam)

		-- check playersArchived and move the player record back to the players table if found
		if playersArchived[tmp.steam] then
			if debug then dbug("Restoring player " .. tmp.steam .. " " .. tmp.player .. " from archive") end
			conn:execute("INSERT INTO players SELECT * from playersArchived WHERE steam = " .. tmp.steam)
			conn:execute("DELETE FROM playersArchived WHERE steam = " .. tmp.steam)
			playersArchived[tmp.steam] = nil
			loadPlayers(tmp.steam)
			pid = tmp.steam
		end
	end

	if tmp.ip == nil then tmp.ip = "" end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if tmp.steam then
		-- if	botman.botsConnected then
			-- -- copy in bots db
			-- connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','player joined','Player joined " .. escape(tmp.player) .. " " .. tmp.steam .. " Owner " .. tmp.steamOwner .. " " .. tmp.entityid .. " " .. tmp.ip .. "'," .. tmp.steamOwner .. ")")
		-- end

		lastPlayerConnected = tmp.player
		lastSteamConnected = tmp.steam

		if isReservedName(tmp.player, tmp.steam) then
			kick(tmp.steam, "That name is reserved.  You cannot play as " .. tmp.player .. " here.")
			alertAdmins("A player was kicked using an admin's name! " .. tmp.entityid .. " " .. tmp.player, "alert")
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','impersonated admin','Player joined posing as an admin " .. escape(tmp.player) .. " " .. tmp.steam .. " Owner " .. tmp.steamOwner .. " " .. tmp.entityid .. " " .. tmp.ip .. "'," .. tmp.steamOwner .. ")") end
			irc_chat(server.ircMain, "!!  Player joined with admin's name but a different steam key !! " .. tmp.player .. " steam: " .. tmp.steam .. " owner: " .. tmp.steamOwner .. " id: " .. tmp.entityid)
			irc_chat(server.ircAlerts, server.gameDate .. " player joined with admin's name but a different steam key " .. tmp.player .. " steam: " .. tmp.steam .. " owner: " .. tmp.steamOwner .. " id: " .. tmp.entityid)
			return
		end

		-- kick if another player is already on the server with the same name.
		for k,v in pairs(igplayers) do
			if (v.name == tmp.player) and k ~= tmp.steam then
				kick(tmp.steam, "We do not allow multiple players on at the same time with the same name.")
				return
			end
		end

		-- kick for bad player name
		if	(not server.allowNumericNames or not server.allowGarbageNames) and not whitelist[tmp.steam] then
			temp = countAlphaNumeric(tmp.player)

			if tonumber(tmp.player) ~= nil or tonumber(temp) == 0 then
				kick(tmp.steam, "Names without letters are not allowed here. You need to change your name to play on this server.")
				return
			end
		end

		-- kick for 127.
		if string.find(tmp.player, "127.") then
			kick(tmp.steam, "You must change your name to join this server.")
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','bad player name','Player kicked for bad name " .. escape(tmp.player) .. " " .. tmp.steam .. " Owner " .. tmp.steamOwner .. " " .. tmp.entityid .. " " .. tmp.ip .. "'," .. tmp.steamOwner .. ")") end
			irc_chat(server.ircAlerts, server.gameDate .. " player kicked becaus their name contains '127.' used to mess with LiteNetLib " .. tmp.player .. " steam: " .. tmp.steam .. " owner: " .. tmp.steamOwner .. " id: " .. tmp.entityid)
			return
		end

		-- kick if player name looks like a steam ID
		if string.len(tmp.player) == 17 then
			test = tonumber(tmp.player)
			if (test ~= nil) then
				kick(tmp.steam, "That name is not permitted.")
				return
			end
		end
	end

	-- do a final check if we failed to lookup the player
	if pid == 0 and tmp.steam then
		-- try to find the player in the events table
		cursor,errorString = conn:execute("SELECT count(steam) AS steamCount FROM events WHERE steam = " .. tmp.steam)
		row = cursor:fetch({}, "a")

		if tonumber(row.steamCount) > 0 then
			pid = tmp.steam
		end
	end

	if tmp.steam then
		-- log the player connection in events table
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','player joined','Player joined " .. escape(tmp.player) .. " " .. tmp.steam .. " Owner " .. tmp.steamOwner .. " " .. tmp.entityid .. " " .. tmp.ip .. "'," .. tmp.steamOwner .. ")") end
	end

	-- add to players table
	if pid == 0 and tmp.steam then
		initNewPlayer(tmp.steam, tmp.player, tmp.entityid, tmp.steamOwner, line)
		fixMissingPlayer(tmp.steam, tmp.steamOwner)

		if not string.find(line, "INF Steam authentication successful") then
			irc_chat(server.ircMain, "###  New player joined " .. tmp.player .. " steam: " .. tmp.steam .. " owner: " .. tmp.steamOwner .. " id: " .. tmp.entityid .. " ###")
			irc_chat(server.ircAlerts, "New player joined " .. server.gameDate .. " " .. line:gsub("%,", ""))
			irc_chat(server.ircWatch, server.gameDate .. " " .. tmp.steam .. " " .. tmp.player .. " new player connected")
			logChat(botman.serverTime, "Server", "New player joined " .. botman.serverTime .. " " .. server.gameDate .. " " .. tmp.player .. " steam: " .. tmp.steam .. " owner: " .. tmp.steamOwner .. " id: " .. tmp.entityid)

			alertAdmins("New player joined " .. tmp.player, "warn")
		end

		if botman.dbConnected then conn:execute("INSERT INTO players (steam, steamOwner, id, name, protectSize, protect2Size, firstSeen) VALUES (" .. tmp.steam .. "," .. tmp.steamOwner .. "," .. tmp.entityid .. ",'" .. escape(tmp.player) .. "'," .. server.baseSize .. "," .. server.baseSize .. "," .. os.time() .. ")") end
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','new player','New player joined " .. escape(tmp.player) .. " steam: " .. tmp.steam .. " owner: " .. tmp.steamOwner .. " id: " .. tmp.entityid .. "'," .. tmp.steam .. ")") end
	else
		if tmp.steam then
			irc_chat(server.ircMain, server.gameDate .. " " .. tmp.steam .. " " .. tmp.player .. " connected")
			irc_chat(server.ircAlerts, server.gameDate .. " " .. tmp.steam .. " " .. tmp.player .. " connected")
			logChat(botman.serverTime, "Server", tmp.steam .. " " .. tmp.player .. " connected")

			if players[tmp.steam].watchPlayer then
				irc_chat(server.ircWatch, server.gameDate .. " " .. tmp.steam .. " " .. tmp.player .. " connected")
			end

			players[tmp.steam].ip = tmp.ip

			if tonumber(players[tmp.steam].hackerScore) > 99 then
				players[tmp.steam].hackerScore = 90
			end

			cursor,errorString = conn:execute("SELECT count(steam) as result FROM miscQueue WHERE command like '%admin add%' and steam = " .. tmp.steam)
			row = cursor:fetch({}, "a")

			if tonumber(row.result) > 0 then
				players[tmp.steam].testAsPlayer = true
			else
				players[tmp.steam].testAsPlayer = nil
			end

			if server.stompy then
				tempTimer( 10, [[sendCommand("bc-lp ]] .. tmp.steam .. [[ /full")]] )
			end
		end
	end

	if tmp.steam then
		-- add to in-game players table
		if not igplayers[tmp.steam] then
			initNewIGPlayer(tmp.steam, tmp.player, tmp.entityid, tmp.steamOwner)
			fixMissingIGPlayer(tmp.steam, tmp.steamOwner)
		end

		players[tmp.steam].pendingBans = 0

		if not server.optOutGlobalBots then
			-- check if GBL ban
			if botman.botsConnected then
				cursor,errorString = connBots:execute("SELECT * FROM bans WHERE (Steam = " .. tmp.steam .. " OR Steam = " .. tmp.steamOwner .. ") AND GBLBan = 1 AND GBLBanActive = 1")
				rows = cursor:numrows()

				if tonumber(rows) > 0 then
					row = cursor:fetch({}, "a")
					kick(tmp.steam, "You are on the global ban list. " .. row.GBLBanReason)
					banPlayer(tmp.steam, "10 years", "On global ban list", 0, true)
					return
				else
					-- check number of pending global bans and alert if this player has any, but allow them to join.
					cursor,errorString = connBots:execute("SELECT count(steam) AS pendingBans FROM bans WHERE (Steam = " .. tmp.steam .. " OR Steam = " .. tmp.steamOwner .. ") AND GBLBan = 1 AND GBLBanVetted = 0")
					row = cursor:fetch({}, "a")
					if tonumber(row.pendingBans) > 0 then
						irc_chat(server.ircAlerts, "ALERT!  Player " .. tmp.steam ..  " " .. tmp.player .. " has " .. row.pendingBans .. " pending global bans.  If the bot bans them, it will add a new active global ban.")
						players[tmp.steam].pendingBans = row.pendingBans
						alertAdmins("ALERT!  Player " .. tmp.steam ..  " " .. tmp.player .. " has " .. row.pendingBans .. " pending global bans.  If the bot bans them, it will add a new active global ban.", "alert")
					end
				end
			end
		end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

		-- check for VAC ban

		if tonumber(tmp.steam) == tonumber(tmp.steamOwner) then
			os.remove(homedir .. "/temp/steamrep_" .. tmp.steam .. ".txt")
			os.execute("wget -nd http://steamrep.com/profiles/" .. tmp.steam .. " -O \"" .. homedir .. "/temp/steamrep_" .. tmp.steam .. ".txt\"")
			tempTimer( 5, [[ checkVACBan("]] .. tmp.steam .. [[") ]] )
		else
			os.remove(homedir .. "/temp/steamrep_" .. tmp.steam .. ".txt")
			os.execute("wget -nd http://steamrep.com/profiles/" .. tmp.steam .. " -O \"" .. homedir .. "/temp/steamrep_" .. tmp.steam .. ".txt\"")
			tempTimer( 5, [[ checkVACBan("]] .. tmp.steam .. [[") ]] )

			os.remove(homedir .. "/temp/steamrep_" .. tmp.steamOwner .. ".txt")
			os.execute("wget -nd http://steamrep.com/profiles/" .. tmp.steamOwner .. " -O \"" .. homedir .. "/temp/steamrep_" .. tmp.steamOwner .. ".txt\"")
			tempTimer( 10, [[ checkVACBan("]] .. tmp.steamOwner .. [[") ]] )
		end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

		igplayers[tmp.steam].playerConnectCounter = playerConnectCounter

		-- try to assign the player to a slot
		if tonumber(server.freeSlots) == 0 then
			-- any player that is staff or a donor can take a reserved slot from a regular joe
			-- admins can take a reserved slot for any non-admins (unless it's admins all the way down).
			if (players[tmp.steam].reserveSlot or staffList[tmp.steam] or isDonor(tmp.steam)) then
				if kickASlot(tmp.steam) then
					assignASlot(tmp.steam)
				else
					kick(tmp.steam, "Sorry the server is full. Please wait a bit and try again.")
					return
				end
			else
				kick(tmp.steam, "Sorry the server is full. Please wait a bit and try again.")
				return
			end
		else
			assignASlot(tmp.steam)
		end


		-- if server.ServerMaxPlayerCount then
			-- if tonumber(botman.playersOnline) == tonumber(server.ServerMaxPlayerCount) and tonumber(server.reservedSlots) > 0 then
				-- -- any player that is staff or a donor can take a reserved slot from a regular joe
				-- -- admins can take a reserved slot for any non-admins (unless it's admins all the way down).
				-- if (players[tmp.steam].reserveSlot or staffList[tmp.steam] or isDonor(tmp.steam)) then
					-- if tonumber(server.freeSlots) == 0 then
						-- if kickASlot(tmp.steam) then
							-- assignSlot(tmp.steam)
						-- else
							-- kick(tmp.steam, "Sorry the server is full. Please wait a bit and try again.")
							-- return
						-- end
					-- end



					-- if tonumber(server.reservedSlotsUsed) >= tonumber(server.reservedSlots) then
						-- if not freeReservedSlot(players[tmp.steam].accessLevel, tmp.steam) then
							-- kick(tmp.steam, "Server is full :(")
							-- return
						-- end
					-- end
				-- else
					-- kick(tmp.steam, "Server is full :(")
					-- return
				-- end
			-- end
		-- end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

		-- if tonumber(server.reservedSlotsUsed) > 0 and tonumber(botman.dbReservedSlotsUsed) < tonumber(server.reservedSlotsUsed) then
			-- assignSlot(tmp.steam)
		-- end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

		botman.playersOnline = tonumber(botman.playersOnline) + 1
		igplayers[tmp.steam].playerConnectCounter = playerConnectCounter
		igplayers[tmp.steam].doFirstSpawnedTasks = true

		-- if tonumber(botman.playersOnline) == tonumber(server.ServerMaxPlayerCount) and tonumber(server.reservedSlots) > 0 then
			-- kick(tmp.steam, "Server is full :(")
			-- return
		-- end

		-- assignSlot(tmp.steam)

		-- -- get the number of reserved slots in use right now
		-- cursor,errorString = conn:execute("SELECT COUNT(reserved) AS reservedSlotsInUse FROM slots WHERE reserved=1 AND free=0")
		-- row = cursor:fetch({}, "a")
		-- server.reservedSlotsUsed = tonumber(row.reservedSlotsInUse)

		if not server.optOutGlobalBots then
			if tmp.ip ~= "" then
				CheckBlacklist(tmp.steam, tmp.ip)
			end
		end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

		if (not lastHotspots[tmp.steam]) then
			lastHotspots[tmp.steam] = {}
		end

		if (players[tmp.steam].sessionCount ~= nil) then
			players[tmp.steam].sessionCount = players[tmp.steam].sessionCount + 1
		else
			players[tmp.steam].sessionCount = 1
		end

		if (friends[tmp.steam] == nil) then
			friends[tmp.steam] = {}
			friends[tmp.steam].friends = ""
		end

		players[tmp.steam].inABase = false
		players[tmp.steam].autoKicked = nil
		invTemp[tmp.steam] = {}

		if not string.find(players[tmp.steam].aliases, tmp.player, nil, true) then -- the last argument disables pattern matching.  We need to do this for player names with () in them.
			players[tmp.steam].aliases = players[tmp.steam].aliases .. "," .. tmp.player
		end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

		if botman.dbConnected then conn:execute("UPDATE players SET aliases = '" .. players[tmp.steam].aliases .. "', sessionCount = " .. players[tmp.steam].sessionCount .. " WHERE steam = " .. tmp.steam) end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

		if not server.allowRapidRelogging then
			-- temp ban the player if they are relogging too many times in quick succession
			if tonumber(players[tmp.steam].relogCount) > 5 and players[tmp.steam].newPlayer then
				banPlayer(tmp.steam, "10 minutes", "relogging many times in a short space of time.", "")
				players[tmp.steam].relogCount = 0
			end
		end

		-- delete read mail that isn't flagged as saved (status = 2).
		if botman.dbConnected then conn:execute("DELETE FROM mail WHERE id = " .. tmp.steam .. " and status = 1") end

		if players[tmp.steam].watchPlayer and tonumber(players[tmp.steam].watchPlayerTimer) < os.time() then
			players[tmp.steam].watchPlayer = false
			players[tmp.steam].watchPlayerTimer = 0
			if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. tmp.steam) end
			irc_chat(server.ircAlerts, "Inventory watching of player " .. tmp.player .. " has expired. They will no longer be watched.")
		end

		tempTimer( 15, [[ sendCommand("lkp ]] .. tmp.steam .. [[") ]] )

		-- check how many claims they have placed
		tempTimer( 20, [[ sendCommand("llp ]] .. tmp.steam .. [[ parseable") ]] )

		if customPlayerConnected ~= nil then
			-- read the note on overriding bot code in custom/custom_functions.lua
			if customPlayerConnected(line, tmp.entityid, tmp.player, tmp.steam, tmp.steamOwner, tmp.ip) then
				return
			end
		end
	end

	if debug then dbug("playerConnected end") end
end