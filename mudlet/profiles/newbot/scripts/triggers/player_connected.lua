--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local nameTest

function initReservedSlots()
	local k, v, cursor,errorString, row, isStaff, canReserve

	if server.reservedSlotsUsed == 0 then
		conn:execute("TRUNCATE reservedSlots")
		botman.dbReservedSlotsUsed = 0
		return
	end

	if botman.dbReservedSlotsUsed == nil then
		cursor,errorString = conn:execute("select count(steam) as totalRows from reservedSlots")
		row = cursor:fetch({}, "a")
		botman.dbReservedSlotsUsed = tonumber(row.totalRows)
	end

	conn:execute("UPDATE reservedSlots set deleteRow = 1")

	-- add playing reserved slotters
	for k,v in pairs(igplayers) do
		isStaff = 0
		canReserve = 0

		if tonumber(botman.dbReservedSlotsUsed) < tonumber(server.reservedSlots) then
			if tonumber(players[k].accessLevel) < 3 then
				isStaff = 1
				canReserve = 1
			end

			if players[k].donor or players[k].reserveSlot then
				canReserve = 1
			end

			if canReserve == 1 then
				conn:execute("INSERT INTO reservedSlots(steam, reserved, staff) VALUES (" .. k .. "," .. canReserve .. "," .. isStaff .. ")")

				-- update botman.dbReservedSlotsUsed
				cursor,errorString = conn:execute("select count(steam) as totalRows from reservedSlots")
				row = cursor:fetch({}, "a")
				botman.dbReservedSlotsUsed = tonumber(row.totalRows)
			end
		end

		conn:execute("UPDATE reservedSlots set deleteRow = 0 WHERE steam = " .. k)
	end

	-- add other players who can be kicked
	for k,v in pairs(igplayers) do
		isStaff = 0
		canReserve = 0

		if tonumber(botman.dbReservedSlotsUsed) < tonumber(server.reservedSlots) then
			if tonumber(players[k].accessLevel) < 3 then
				isStaff = 1
				canReserve = 1
			end

			if players[k].donor or players[k].reserveSlot then
				canReserve = 1
			end

			if canReserve == 0 then
				conn:execute("INSERT INTO reservedSlots(steam, reserved, staff) VALUES (" .. k .. "," .. canReserve .. "," .. isStaff .. ")")

				-- update botman.dbReservedSlotsUsed
				cursor,errorString = conn:execute("select count(steam) as totalRows from reservedSlots")
				row = cursor:fetch({}, "a")
				botman.dbReservedSlotsUsed = tonumber(row.totalRows)
			end
		end

		conn:execute("UPDATE reservedSlots set deleteRow = 0 WHERE steam = " .. k)
	end

	-- remove players from reservedSlots that we have flagged for removal
	conn:execute("DELETE FROM reservedSlots WHERE deleteRow = 1")

	-- update botman.dbReservedSlotsUsed again
	cursor,errorString = conn:execute("select count(steam) as totalRows from reservedSlots")
	row = cursor:fetch({}, "a")
	botman.dbReservedSlotsUsed = tonumber(row.totalRows)

	-- reset flag so we don't call this function again until needed
	botman.initReservedSlots = false
end


function fillReservedSlot(steam)
	local cursor, errorString, row, canReserve, isStaff

	isStaff = 0
	canReserve = 0

	cursor,errorString = conn:execute("select count(steam) as totalRows from reservedSlots")
	row = cursor:fetch({}, "a")
	botman.dbReservedSlotsUsed = tonumber(row.totalRows)

	if tonumber(botman.dbReservedSlotsUsed) < tonumber(server.reservedSlots) then
		if players[steam].donor or players[steam].reserveSlot then
			canReserve = 1
		end

		if tonumber(players[steam].accessLevel) < 3 then
			isStaff = 1
			canReserve = 1
		end

		conn:execute("INSERT INTO reservedSlots(steam, reserved, staff) VALUES (" .. steam .. "," .. canReserve .. "," .. isStaff .. ")")

		if canReserve == 0 then
			message("pm " .. steam .. " [" .. server.warnColour .. "]You are using a reserved slot and may be kicked to make room for another player.[-]")
		end

		if canReserve == 1 and isStaff == 0 then
			message("pm " .. steam .. " [" .. server.warnColour .. "]If the server is full and an admin joins, you may be kicked to make room for them.[-]")
		end

		-- update botman.dbReservedSlotsUsed
		cursor,errorString = conn:execute("SELECT COUNT(steam) AS totalRows FROM reservedSlots")
		row = cursor:fetch({}, "a")
		botman.dbReservedSlotsUsed = tonumber(row.totalRows)
	end
end


function updateReservedSlots(dbSlotsUsed)
	local cursor, errorString, row, rows, playerRemoved

	-- update botman.dbReservedSlotsUsed
	while tonumber(dbSlotsUsed) > tonumber(server.reservedSlotsUsed) do
		playerRemoved = false

		-- try to remove staff from reserved slots first
		cursor,errorString = conn:execute("SELECT * FROM reservedSlots WHERE staff = 1")
		rows = cursor:numrows()

		if rows > 0 then
			row = cursor:fetch({}, "a")
			conn:execute("DELETE * FROM reservedSlots WHERE steam = " .. row.steam)
			botman.dbReservedSlotsUsed = botman.dbReservedSlotsUsed - 1
			dbSlotsUsed = dbSlotsUsed -1
			playerRemoved = true
		end

		-- try to remove other players from reserved slots
		if tonumber(botman.dbReservedSlotsUsed) > tonumber(server.reservedSlotsUsed) then
			cursor,errorString = conn:execute("SELECT * FROM reservedSlots WHERE staff = 0 AND reserved = 0 ORDER BY timeAdded DESC")
			rows = cursor:numrows()

			if rows > 0 then
				row = cursor:fetch({}, "a")
				conn:execute("DELETE * FROM reservedSlots WHERE steam = " .. row.steam)
				botman.dbReservedSlotsUsed = botman.dbReservedSlotsUsed - 1
				dbSlotsUsed = dbSlotsUsed -1
				playerRemoved = true
			end
		end

		if not playerRemoved then
			-- nobody left to remove so break the loop
			return
		end
	end

	-- update botman.dbReservedSlotsUsed
	cursor,errorString = conn:execute("SELECT COUNT(steam) AS totalRows FROM reservedSlots")
	row = cursor:fetch({}, "a")
	botman.dbReservedSlotsUsed = tonumber(row.totalRows)
end


function freeReservedSlot(accessLevel, steam)
	-- returns true if someone gets kicked
	local cursor, errorString, row, kickedSomeone

	if tonumber(server.reservedSlots) == 0 then -- disable if reservedSlots is 0
		return false
	end

	kickedSomeone = false

	-- the player who has occupied a reserved slot the longest and isn't a reserved slotter will be kicked
	cursor,errorString = conn:execute("select * from reservedSlots where reserved = 0 order by timeAdded desc")
	row = cursor:fetch({}, "a")

	if row then
		if igplayers[row.steam] then
			kickedSomeone = true
			kick(row.steam, "Sorry, you have been kicked to make room for a reserved slot :(")
			irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[row.steam].name ..  " was kicked from a reserved slot to let " .. players[steam].name .. " join.")
			conn:execute("DELETE FROM reservedSlots WHERE steam = " .. row.steam)
			botman.dbReservedSlotsUsed = botman.dbReservedSlotsUsed - 1

			return true
		end
	end

	-- the incoming player is an admin and we couldn't find a normal player to kick so kick a non-admin reserved slotter
	if not kickedSomeone and tonumber(accessLevel) < 3 then
		-- kick a non-admin from a slot.  If this fails, it's admins all the way down! :O
		cursor,errorString = conn:execute("select * from reservedSlots where reserved = 1 and staff = 0 order by timeAdded desc")
		row = cursor:fetch({}, "a")

		if row then
			if igplayers[row.steam] then
				kickedSomeone = true
				kick(row.steam, "Sorry, you have been kicked to make room for an admin :O")
				irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[row.steam].name ..  " was kicked from a reserved slot to make room for admin " .. players[steam].name .. ".")
				conn:execute("DELETE FROM reservedSlots WHERE steam = " .. row.steam)
				botman.dbReservedSlotsUsed = botman.dbReservedSlotsUsed - 1

				return true
			end
		end
	end

	return false
end

-- enable debug to see where the code is stopping. Any error will be somewhere after the last successful debug line.
debug = false -- should be false unless testing

function playerConnected(line)
	local temp_table, temp, debug, commas, freeSlots, test, tmp
	local timestamp = os.time()
	local cursor, errorString, rows

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
		dbug("debug playerConnectCounter " .. playerConnectCounter)
		dbug("botman.playersOnline " .. botman.playersOnline)
		dbug("server.maxPlayers " .. server.maxPlayers)
		dbug("server.reservedSlots " .. server.reservedSlots)

		if server.ServerMaxPlayerCount then
			dbug("server.ServerMaxPlayerCount " .. server.ServerMaxPlayerCount)
		end
	end

	local _, commas = string.gsub(line, ",", "")

	temp = string.sub(line, 1, string.find(line, " INF "))
	if string.find(temp, ",") then
		commas = commas - 1
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if commas > 5 then
		-- player has one or more commas in their name.  That screws with parsing lines so kick them with a message to change their name.
		temp = string.find(line, "steamOwner=") + 11
		tmp.steam = string.sub(line, temp, temp + 16)

		kick(tmp.steam, "You have one or more commas in your name. Please remove them.")
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	botman.playersOnline = botman.playersOnline + 1
	freeSlots = server.maxPlayers - botman.playersOnline
	server.reservedSlotsUsed = server.reservedSlots - freeSlots

	temp_table = string.split(line, ",")
	timeConnected = string.sub(line, 1, 19)

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "steamid=") then
		tmp.player = string.trim(string.sub(temp_table[3], string.find(temp_table[3], "name=") + 5, string.find(temp_table[3], ",")))
		tmp.steam = string.sub(temp_table[4], string.find(temp_table[4], "steamid=") + 8, string.find(temp_table[4], ","))
		tmp.entityid = string.sub(temp_table[2], string.find(temp_table[2], "entityid=") + 9, string.find(temp_table[2], ","))
		if string.find(line, "steamOwner") then
			tmp.steamOwner = string.sub(temp_table[5], string.find(temp_table[5], "steamOwner=") + 11)
			tmp.ip = string.sub(temp_table[6], string.find(temp_table[6], "ip=") + 3)
			tmp.ip = tmp.ip:gsub("::ffff:","")
		else
			tmp.steamOwner = tmp.steam
			tmp.ip = string.sub(temp_table[5], string.find(temp_table[5], "ip=") + 3)
			tmp.ip = tmp.ip:gsub("::ffff:","")
		end
	end

	if string.find(line, "PlayerID=") then
		tmp.player = string.trim(string.sub(temp_table[5], string.find(temp_table[5], "PlayerName=") + 12))
		tmp.player = stripQuotes(tmp.player)

		tmp.steam = string.sub(temp_table[3], string.find(temp_table[3], "PlayerID=") + 10)
		tmp.steam = stripQuotes(tmp.steam)

		tmp.steamOwner = string.sub(temp_table[4], string.find(temp_table[4], "OwnerID=") + 9)
		tmp.steamOwner = stripQuotes(tmp.steamOwner)

		tmp.entityid = -1
	end

	if tmp.ip == nil then tmp.ip = "" end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	-- if string.find(line, "OwnerID=") and not string.find(line, "OwnerID=''") then
		-- tmp.steam = string.sub(line, string.find(line, "OwnerID=") + 9, string.find(line, "PlayerName=") - 4)
		-- tmp.player = string.trim(string.sub(line, string.find(line, "PlayerName=") + 12, string.len(line) - 1))
		-- tmp.entityid = string.sub(line, string.find(line, "EntityID=") + 9, string.find(line, "PlayerID=") - 3)
	-- end

	if string.find(line, "steamid=") then
		-- log the player connection in events table
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','player joined','Player joined " .. escape(tmp.player) .. " " .. tmp.steam .. " Owner " .. tmp.steamOwner .. " " .. tmp.entityid .. " " .. tmp.ip .. "'," .. tmp.steamOwner .. ")") end

		if	botman.db2Connected then
			-- copy in bots db
			connBots:execute("INSERT INTO events (server, serverTime, type, event, tmp.steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','player joined','Player joined " .. escape(tmp.player) .. " " .. tmp.steam .. " Owner " .. tmp.steamOwner .. " " .. tmp.entityid .. " " .. tmp.ip .. "'," .. tmp.steamOwner .. ")")
		end

		lastPlayerConnected = tmp.player
		lastSteamConnected = tmp.steam

		if isReservedName(tmp.player, tmp.steam) then
			kick(tmp.steam, "That name is reserved.  You cannot play as " .. tmp.player .. " here.")
			alertAdmins("A player was kicked using an admin's name! " .. tmp.entityid .. " " .. tmp.player, "alert")
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','impersonated admin','Player joined posing as an admin " .. escape(tmp.player) .. " " .. tmp.steam .. " Owner " .. tmp.steamOwner .. " " .. tmp.entityid .. " " .. tmp.ip .. "'," .. tmp.steamOwner .. ")") end
			irc_chat(server.ircMain, "!!  Player joined with admin's name but a different steam key !! " .. tmp.player .. " steam: " .. tmp.steam.. " owner: " .. tmp.steamOwner .. " id: " .. tmp.entityid)
			irc_chat(server.ircAlerts, server.gameDate .. " player joined with admin's name but a different steam key " .. tmp.player .. " steam: " .. tmp.steam.. " owner: " .. tmp.steamOwner .. " id: " .. tmp.entityid)
			return
		end

		if string.find(tmp.player, "[\(\)]%d+") then
			kick(tmp.steam, "Sorry another player with the same name as you is playing here right now.  We do not allow multiple players on at the same time with the same name.")
			return
		end

		-- kick for bad player name
		if	(not server.allowNumericNames or not server.allowGarbageNames) and not whitelist[tmp.steam] then
			temp = countAlphaNumeric(tmp.player)

			if tonumber(tmp.player) ~= nil or tonumber(temp) == 0 then
				kick(tmp.steam, "Names without letters are not allowed here. You need to change your name to play on this server.")
				return
			end
		end

		-- kick if player name looks like a steam ID
		if string.len(tmp.player) == 17 then
			test = tonumber(tmp.player)
			if (test ~= nil) then
				kick(tmp.steam, "Your name is a number and the same length as a steam key. Nice try though.")
				return
			end
		end

		-- check playersArchived and move the player record back to the players table if found
		if playersArchived[tmp.steam] then
			dbug("Restoring player " .. tmp.steam .. " " .. tmp.player .. " from archive")
			conn:execute("INSERT INTO players SELECT * from playersArchived WHERE steam = " .. tmp.steam)
			conn:execute("DELETE FROM playersArchived WHERE steam = " .. tmp.steam)
			playersArchived[tmp.steam] = nil
			loadPlayers(tmp.steam)
		end

	end

	-- add to players table
	if (players[tmp.steam] == nil) then
		initNewPlayer(tmp.steam, tmp.player, tmp.entityid, tmp.steamOwner)
		fixMissingPlayer(tmp.steam, tmp.steamOwner)

		irc_chat(server.ircMain, "###  New player joined " .. tmp.player .. " steam: " .. tmp.steam.. " owner: " .. tmp.steamOwner .. " id: " .. tmp.entityid .. " ###")
		irc_chat(server.ircAlerts, "New player joined " .. server.gameDate .. " " .. line:gsub("%,", ""))
		irc_chat(server.ircWatch, server.gameDate .. " " .. tmp.steam .. " " .. tmp.player .. " new player connected")
		logChat(botman.serverTime, "Server", "New player joined " .. botman.serverTime .. " " .. server.gameDate .. " " .. tmp.player .. " steam: " .. tmp.steam.. " owner: " .. tmp.steamOwner .. " id: " .. tmp.entityid)

		alertAdmins("New player joined " .. tmp.entityid .. " " .. tmp.player, "warn")

		if botman.dbConnected then conn:execute("INSERT INTO players (steam, steamOwner, id, name, protectSize, protect2Size, firstSeen) VALUES (" .. tmp.steam .. "," .. tmp.steamOwner .. "," .. tmp.entityid .. ",'" .. escape(tmp.player) .. "'," .. server.baseSize .. "," .. server.baseSize .. "," .. os.time() .. ")") end
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','new player','New player joined " .. escape(tmp.player) .. " steam: " .. tmp.steam .. " owner: " .. tmp.steamOwner .. " id: " .. tmp.entityid .. "'," .. tmp.steam .. ")") end
	else
		if string.find(line, "steamid=") then
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

			tempTimer( 30, [[sendCommand("bc-lp ]] .. tmp.steam .. [[ /full")]] )
		end
	end

	if string.find(line, "steamid=") then
		-- add to in-game players table
		if not igplayers[tmp.steam] then
			initNewIGPlayer(tmp.steam, tmp.player, tmp.entityid, tmp.steamOwner)
			fixMissingIGPlayer(tmp.steam, tmp.steamOwner)
		end

		players[tmp.steam].pendingBans = 0

		if not server.optOutGlobalBots then
			-- check if GBL ban
			if botman.db2Connected then
				cursor,errorString = connBots:execute("SELECT * FROM bans WHERE (Steam = " .. tmp.steam .. " or Steam = " .. tmp.steamOwner .. ") and GBLBan = 1 and GBLBanActive = 1")
				rows = cursor:numrows()

				if tonumber(rows) > 0 then
					row = cursor:fetch({}, "a")
					kick(tmp.steam, "You are on the global ban list. " .. row.GBLBanReason)
					banPlayer(tmp.steam, "10 years", "On global ban list", 0, true)
					return
				else
					-- check number of pending global bans and alert if this player has any, but allow them to join.
					cursor,errorString = connBots:execute("SELECT count(steam) as pendingBans FROM bans WHERE (Steam = " .. tmp.steam .. " or Steam = " .. tmp.steamOwner .. ") and GBLBan = 1 and GBLBanVetted = 0")
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

		if server.ServerMaxPlayerCount then
			if tonumber(botman.playersOnline) == tonumber(server.ServerMaxPlayerCount) and tonumber(server.reservedSlots) > 0 then
				-- any player that is staff or a donor can take a reserved slot from a regular joe
				-- admins can take a reserved slot for any non-admins (unless it's admins all the way down).
				if players[tmp.steam].reserveSlot or tonumber(players[tmp.steam].accessLevel) < 3 or players[tmp.steam].donor then
					if tonumber(botman.dbReservedSlotsUsed) >= tonumber(server.reservedSlots) then
						if not freeReservedSlot(players[tmp.steam].accessLevel, tmp.steam) then
							kick(tmp.steam, "Server is full :(")
							return
						end
					end
				else
					kick(tmp.steam, "Server is full :(")
					return
				end
			end
		end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

		if tonumber(server.reservedSlotsUsed) > 0 and tonumber(botman.dbReservedSlotsUsed) < tonumber(server.reservedSlotsUsed) then
			fillReservedSlot(tmp.steam)
		end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

		if server.coppi then
			if players[tmp.steam].mute then
				tempTimer( 32, [[ mutePlayerChat(]] .. tmp.steam .. [[, "true") ]])
			end

			if players[tmp.steam].chatColour ~= "" then
				if string.upper(string.sub(players[tmp.steam].chatColour, 1, 6)) ~= "FFFFFF" then
					tempTimer( 35, [[ setPlayerColour(]] .. tmp.steam, stripAllQuotes(players[tmp.steam].chatColour .. [[) ]] ))
				else
					tempTimer( 35, [[ setChatColour(]] .. tmp.steam .. [[) ]] )
				end
			else
				tempTimer( 35, [[ setChatColour(]] .. tmp.steam .. [[) ]] )
			end
		end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

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

		if server.coppi then
			-- limit ingame chat length to block chat bombs.
			tempTimer( 40, [[ setPlayerChatLimit(]] .. tmp.steam .. [[, 300) ]] )
		end

		if tonumber(players[tmp.steam].donorExpiry) < os.time() and players[tmp.steam].donor then
			irc_chat(server.ircAlerts, "Player " .. tmp.player ..  " " .. tmp.steam .. " donor status has expired.")
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','donor','" .. escape(tmp.player) .. " " .. tmp.steam .. " donor status expired.'," .. tmp.steam ..")") end

			players[tmp.steam].donor = false
			players[tmp.steam].donorLevel = 0
			players[tmp.steam].protect2 = false
			players[tmp.steam].maxWaypoints = server.maxWaypoints
			if botman.dbConnected then conn:execute("UPDATE players SET protect2 = 0, donor = 0, donorLevel = 0, maxWaypoints = " .. server.maxWaypoints .. " WHERE steam = " .. tmp.steam) end

			message("pm " .. tmp.steam .. " [" .. server.chatColour .. "]Your donor status has expired :(  Contact an admin if you need help accessing your second base. Your 2nd base's protection will be disabled one week from when your donor status expired.[-]")
			message("pm " .. tmp.steam .. " [" .. server.alertColour .. "]ALERT! Your second base is no longer bot protected![-]")

			-- remove the player's waypoints
			conn:execute("delete from waypoints where steam = " .. tmp.steam)
			message("pm " .. tmp.steam .. " [" .. server.chatColour .. "]Also your waypoints have been cleared.  You will need to create new ones. :([-]")

			-- reload the player's waypoints
			loadWaypoints(tmp.steam)
		end

		if players[tmp.steam].watchPlayer and tonumber(players[tmp.steam].watchPlayerTimer) < os.time() then
			players[tmp.steam].watchPlayer = false
			players[tmp.steam].watchPlayerTimer = 0
			if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. tmp.steam) end
			irc_chat(server.ircAlerts, "Inventory watching of player " .. tmp.player .. " has expired. They will no longer be watched.")
		end

		tempTimer( 45, [[ sendCommand("lkp ]] .. tmp.steam .. [[") ]] )

		-- check how many claims they have placed
		tempTimer( 50, [[ sendCommand("llp ]] .. tmp.steam .. [[ parseable") ]] )

		if customPlayerConnected ~= nil then
			-- read the note on overriding bot code in custom/custom_functions.lua
			if customPlayerConnected(line, tmp.entityid, tmp.player, tmp.steam, tmp.steamOwner, tmp.ip) then
				return
			end
		end
	end

	if debug then dbug("playerConnected end") end
end