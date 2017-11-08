--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local nameTest


function initReservedSlots()
	local k, v, cursor,errorString, row, isStaff, canReserve

	if server.reservedSlotsUsed == 0 then
		conn:execute("DELETE FROM reservedSlots")
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

		if (botman.dbReservedSlotsUsed < server.reservedSlots) then
			if players[k].accessLevel < 3 then
				isStaff = 1
				canReserve = 1
			end

			if players[k].donor or players[k].reserveSlot then
				canReserve = 1
			end

			conn:execute("INSERT INTO reservedSlots(steam, reserved, staff) VALUES (" .. k .. "," .. canReserve .. "," .. isStaff .. ")")

			-- update botman.dbReservedSlotsUsed
			cursor,errorString = conn:execute("select count(steam) as totalRows from reservedSlots")
			row = cursor:fetch({}, "a")
			botman.dbReservedSlotsUsed = tonumber(row.totalRows)
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

	if (botman.dbReservedSlotsUsed < server.reservedSlots) then
		if players[steam].donor or players[steam].reserveSlot then
			canReserve = 1
		end

		if players[steam].accessLevel < 3 then
			isStaff = 1
			canReserve = 1
		end

		conn:execute("INSERT INTO reservedSlots(steam, reserved, staff) VALUES (" .. steam .. "," .. canReserve .. "," .. isStaff .. ")")
		botman.dbReservedSlotsUsed = botman.dbReservedSlotsUsed + 1

		if canReserve == 0 then
			message("pm " .. steam .. " [" .. server.warnColour .. "]You are using a reserved slot and may be kicked to make room for another player.[-]")
		end

		-- update botman.dbReservedSlotsUsed
		cursor,errorString = conn:execute("select count(steam) as totalRows from reservedSlots")
		row = cursor:fetch({}, "a")
		botman.dbReservedSlotsUsed = tonumber(row.totalRows)
	end
end


function updateReservedSlots()
	local cursor, errorString, row, rows, playerRemoved

	-- update botman.dbReservedSlotsUsed
	cursor,errorString = conn:execute("select count(steam) as totalRows from reservedSlots")
	row = cursor:fetch({}, "a")
	botman.dbReservedSlotsUsed = tonumber(row.totalRows)

	while botman.dbReservedSlotsUsed > server.reservedSlotsUsed do
		playerRemoved = false

		-- try to remove staff from reserved slots first
		cursor,errorString = conn:execute("select * from reservedSlots where staff = 1 limit " .. botman.dbReservedSlotsUsed - server.reservedSlotsUsed)
		rows = cursor:numrows()

		if rows > 0 then
			row = cursor:fetch({}, "a")
			conn:execute("delete * from reservedSlots where steam = " .. row.steam)
			botman.dbReservedSlotsUsed = botman.dbReservedSlotsUsed - 1
			playerRemoved = true
		end

		-- try to remove other players from reserved slots
		if botman.dbReservedSlotsUsed > server.reservedSlotsUsed then
			cursor,errorString = conn:execute("select * from reservedSlots where staff = 0 and reserved = 0 limit " .. botman.dbReservedSlotsUsed - server.reservedSlotsUsed)
			rows = cursor:numrows()

			if rows > 0 then
				row = cursor:fetch({}, "a")
				conn:execute("delete * from reservedSlots where steam = " .. row.steam)
				botman.dbReservedSlotsUsed = botman.dbReservedSlotsUsed - 1
				playerRemoved = true
			end
		end

		if not playerRemoved then
			-- update botman.dbReservedSlotsUsed from the db
			cursor,errorString = conn:execute("select count(steam) as totalRows from reservedSlots")
			row = cursor:fetch({}, "a")
			botman.dbReservedSlotsUsed = tonumber(row.totalRows)

			-- nobody left to remove so break the loop
			return
		end
	end

	-- update botman.dbReservedSlotsUsed from the db
	cursor,errorString = conn:execute("select count(steam) as totalRows from reservedSlots")
	row = cursor:fetch({}, "a")
	botman.dbReservedSlotsUsed = tonumber(row.totalRows)
end


function freeReservedSlot()
	-- returns true if someone gets kicked
	local cursor, errorString, row

	if tonumber(server.reservedSlots) == 0 then -- disable if reservedSlots is 0
		return false
	end

	cursor,errorString = conn:execute("select * from reservedSlots where staff = 0 and reserved = 0 order by timeAdded desc")
	row = cursor:fetch({}, "a")

	if row then
		if igplayers[row.steam] then
			kick(row.steam, "Sorry, you have been kicked to make room for a reserved slot :(")
			irc_chat(server.ircAlerts, "Player " .. players[row.steam].name ..  " was kicked from a reserved slot.")
			conn:execute("DELETE FROM reservedSlots WHERE steam = " .. row.steam)
			botman.dbReservedSlotsUsed = botman.dbReservedSlotsUsed - 1

			return true
		end
	end

	conn:execute("delete from reservedSlots where deleteRow = 1")

	return false
end


function playerDenied(line)

end


function playerConnected(line)
	local entityid, player, steam, steamOwner, IP, temp_table, temp, debug, commas
	local timestamp = os.time()

	debug = false

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if playerConnectCounter == nil then
		playerConnectCounter = 1
	else
		playerConnectCounter = 	playerConnectCounter + 1
	end

	if (debug) then
		dbug("debug playerConnectCounter " .. playerConnectCounter)
		dbug("botman.playersOnline " .. botman.playersOnline)
		dbug("server.maxPlayers " .. server.maxPlayers)
		dbug("server.reservedSlots " .. server.reservedSlots)
		dbug("server.ServerMaxPlayerCount " .. server.ServerMaxPlayerCount)
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	local _, commas = string.gsub(line, ",", "")

	tmp = string.sub(line, 1, string.find(line, " INF "))
	if string.find(tmp, ",") then
		commas = commas - 1
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if commas > 5 then
		-- player has one or more commas in their name.  That screws with parsing lines so kick them with a message to change their name.
		temp = string.find(line, "steamOwner=") + 11
		steam = string.sub(line, temp, temp + 16)

		kick(steam, "You have one or more commas in your name. Please remove them.")
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if server.reservedSlots == server.maxPlayers then
		server.reservedSlots = server.reservedSlots - 1
		conn:execute("UPDATE server SET reservedSlots = " .. server.reservedSlots)
		irc_chat(chatvars.ircMain, "Auto-adjusted reserved slots to one less than max players. Reserved slots can't equal max players.")
	end

	botman.playersOnline = botman.playersOnline + 1
	server.reservedSlotsUsed = tonumber(botman.playersOnline) - (tonumber(server.maxPlayers) - tonumber(server.reservedSlots))

	temp_table = string.split(line, ",")
	timeConnected = string.sub(line, 1, 19)

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "steamid=") then
		player = string.trim(string.sub(temp_table[3], string.find(temp_table[3], "name=") + 5, string.find(temp_table[3], ",")))
		steam = string.sub(temp_table[4], string.find(temp_table[4], "steamid=") + 8, string.find(temp_table[4], ","))
		entityid = string.sub(temp_table[2], string.find(temp_table[2], "entityid=") + 9, string.find(temp_table[2], ","))
		if string.find(line, "steamOwner") then
			steamOwner = string.sub(temp_table[5], string.find(temp_table[5], "steamOwner=") + 11)
			IP = string.sub(temp_table[6], string.find(temp_table[6], "ip=") + 3)
			IP = IP:gsub("::ffff:","")
		else
			steamOwner = steam
			IP = string.sub(temp_table[5], string.find(temp_table[5], "ip=") + 3)
			IP = IP:gsub("::ffff:","")
		end
	end

	if IP == nil then IP = "" end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "OwnerID=") and not string.find(line, "OwnerID=''") then
		steam = string.sub(line, string.find(line, "OwnerID=") + 9, string.find(line, "PlayerName=") - 4)
		player = string.trim(string.sub(line, string.find(line, "PlayerName=") + 12, string.len(line) - 1))
		entityid = string.sub(line, string.find(line, "EntityID=") + 9, string.find(line, "PlayerID=") - 3)
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	-- log the player connection in events table
	if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','player joined','Player joined " .. escape(player) .. " " .. steam .. " Owner " .. steamOwner .. " " .. entityid .. " " .. IP .. "'," .. steamOwner .. ")") end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if	botman.db2Connected then
		-- copy in bots db
		connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','player joined','Player joined " .. escape(player) .. " " .. steam .. " Owner " .. steamOwner .. " " .. entityid .. " " .. IP .. "'," .. steamOwner .. ")")
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	lastPlayerConnected = player
	lastSteamConnected = steam

	if string.find(player, "[\(\)]%d+") then
		kick(steam, "Sorry another player with the same name as you is playing here right now.  We do not allow multiple players on at the same time with the same name.")
		return
	end

	if isReservedName(player, steam) then
		kick(steam, "That name is reserved.  You cannot play as " .. player .. " here.")
		alertAdmins("A player was kicked using an admin's name! " .. entityid .. " " .. player, "alert")
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','impersonated admin','Player joined posing as an admin " .. escape(player) .. " " .. steam .. " Owner " .. steamOwner .. " " .. entityid .. " " .. IP .. "'," .. steamOwner .. ")") end
		irc_chat(server.ircMain, "!!  Player joined with admin's name but a different steam key !! " .. player .. " steam: " .. steam.. " owner: " .. steamOwner .. " id: " .. entityid)
		irc_chat(server.ircAlerts, "!!  Player joined with admin's name but a different steam key !! " .. player .. " steam: " .. steam.. " owner: " .. steamOwner .. " id: " .. entityid)
		return
	end

	-- add to players table
	if (players[steam] == nil) then
		initNewPlayer(steam, player, entityid, steamOwner)
		fixMissingPlayer(steam, steamOwner)

		irc_chat(server.ircMain, "###  New player joined " .. player .. " steam: " .. steam.. " owner: " .. steamOwner .. " id: " .. entityid .. " ###")
		irc_chat(server.ircAlerts, "New player joined")
		irc_chat(server.ircAlerts, line:gsub("%,", ""))
		irc_chat(server.ircWatch, server.gameDate .. " " .. steam .. " " .. player .. " new player connected")
		logChat(botman.serverTime, "Server", "New player joined " .. player .. " steam: " .. steam.. " owner: " .. steamOwner .. " id: " .. entityid)

		alertAdmins("New player joined " .. entityid .. " " .. player, "warn")

		if botman.dbConnected then conn:execute("INSERT INTO players (steam, steamOwner, id, name, protectSize, protect2Size, firstSeen) VALUES (" .. steam .. "," .. steamOwner .. "," .. entityid .. ",'" .. escape(player) .. "'," .. server.baseSize .. "," .. server.baseSize .. "," .. os.time() .. ")") end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','new player','New player joined " .. escape(player) .. " steam: " .. steam .. " owner: " .. steamOwner .. " id: " .. entityid .. "'," .. steam .. ")") end

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end
	else
		irc_chat(server.ircMain, server.gameDate .. " " .. steam .. " " .. player .. " connected")
		logChat(botman.serverTime, "Server", steam .. " " .. player .. " connected")

		if players[steam].watchPlayer then
			irc_chat(server.ircWatch, server.gameDate .. " " .. steam .. " " .. player .. " connected")
		end

		players[steam].IP = IP

		if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

		cmd = "llp " .. steam
		tempTimer( 5, [[send("]] .. cmd .. [[")]] )
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	-- add to in-game players table
	if (igplayers[steam] == nil) then
		initNewIGPlayer(steam, player, entityid, steamOwner)
		fixMissingIGPlayer(steam, steamOwner)
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	-- kick for bad player name
	if	(not server.allowNumericNames or not server.allowGarbageNames) and not whitelist[steam] then
		temp = countAlphaNumeric(player)

		if tonumber(player) ~= nil or tonumber(temp) == 0 then
			kick(steam, "Names without letters are not allowed here. You need to change your name to play on this server.")
			return
		end
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	igplayers[steam].playerConnectCounter = playerConnectCounter

	if tonumber(botman.playersOnline) == tonumber(server.ServerMaxPlayerCount) and tonumber(server.reservedSlots) > 0 then
		-- any player that is staff or a donor can take a reserved slot from a regular joe
		if players[steam].reserveSlot or players[steam].accessLevel < 11 or players[steam].donor then
			if (botman.dbReservedSlotsUsed >= server.reservedSlots) then
				if not freeReservedSlot(steam) then
					kick(steam, "Server is full :(")
					return
				end
			end
		else
			kick(steam, "Server is full :(")
			return
		end
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if server.reservedSlotsUsed > 0 and (botman.dbReservedSlotsUsed < server.reservedSlotsUsed) then
		fillReservedSlot(steam)
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if server.coppi then
		if players[steam].mute then
			send("mpc " .. steam .. " true")
		end

		if players[steam].chatColour ~= "" then
			if string.upper(players[steam].chatColour) ~= "FFFFFF" then
				send("cpc " .. steam .. " " .. stripAllQuotes(players[steam].chatColour) .. " 1")
			else
				setChatColour(steam)
			end
		end
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if IP ~= "" then
		CheckBlacklist(steam, IP)
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if (not lastHotspots[steam]) then
		lastHotspots[steam] = {}
	end

	if (players[steam].sessionCount ~= nil) then
		players[steam].sessionCount = players[steam].sessionCount + 1
	else
		players[steam].sessionCount = 1
	end

	if (friends[steam] == nil) then
		friends[steam] = {}
		friends[steam].friends = ""
	end

	players[steam].autoKicked = nil
	invTemp[steam] = {}

	if not string.find(players[steam].names, player, nil, true) then -- the last argument disables pattern matching.  We need to do this for player names with () in them.
		players[steam].names = players[steam].names .. "," .. player
	end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if botman.dbConnected then conn:execute("UPDATE players SET aliases = '" .. players[steam].names .. "', sessionCount = " .. players[steam].sessionCount .. " WHERE steam = " .. steam) end

	if (debug) then dbug("debug playerConnected line " .. debugger.getinfo(1).currentline) end

	if not server.allowRapidRelogging then
		-- temp ban the player if they are relogging too many times in quick succession
		if tonumber(players[steam].relogCount) > 5 and players[steam].newPlayer then
			banPlayer(steam, "10 minutes", "relogging many times in a short space of time.", "")
			players[steam].relogCount = 0
		end
	end

	-- delete read mail that isn't flagged as saved (status = 2).
	if botman.dbConnected then conn:execute("DELETE FROM mail WHERE id = " .. steam .. " and status = 1") end

	if server.coppi then
		-- limit ingame chat length to block chat bombs.
		send("pcml " .. steam .. " 300")
	end

	if tonumber(players[steam].donorExpiry) < os.time() and players[steam].donor then
		irc_chat(server.ircAlerts, "Player " .. player ..  " " .. steam .. " donor status has expired.")
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','donor','" .. escape(player) .. " " .. steam .. " donor status expired.'," .. steam ..")") end

		players[steam].donor = false
		players[steam].donorLevel = 0
		if botman.dbConnected then conn:execute("UPDATE players SET donor = 0, donorLevel = 0 WHERE steam = " .. steam) end

		message("pm " .. steam .. " [" .. server.chatColour .. "]Your donor status has expired :(  Contact an admin if you need help accessing your second base. Your 2nd base's protection will be disabled one week from when your donor status expired.[-]")

		if os.time() - tonumber(players[steam].donorExpiry) > (60 * 60 * 24 * 7) then
			players[steam].protect2 = false
			if botman.dbConnected then conn:execute("UPDATE players SET protect2 = 0 WHERE steam = " .. steam) end
			message("pm " .. steam .. " [" .. server.alertColour .. "]ALERT! Your second base is no longer bot protected![-]")
		end

		-- remove the player's waypoints
		conn:execute("delete from waypoints where steam = " .. steam)
		message("pm " .. steam .. " [" .. server.chatColour .. "]Also your waypoints have been cleared.  You will need to create new ones. :([-]")

		-- reload the player's waypoints
		loadWaypoints(steam)
	end

	if players[steam].watchPlayer and tonumber(players[steam].watchPlayerTimer) < os.time() then
		players[steam].watchPlayer = false
		players[steam].watchPlayerTimer = 0
		if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. steam) end
	end

	send("lkp steam")
	players[steam].pendingBans = 0

	-- check if GBL ban
	if botman.db2Connected then
		cursor,errorString = connBots:execute("SELECT * FROM bans WHERE (Steam = " .. steam .. " or Steam = " .. steamOwner .. ") and GBLBan = 1 and GBLBanActive = 1")
		rows = cursor:numrows()

		if tonumber(rows) > 0 then
			row = cursor:fetch({}, "a")
			kick(steam, "You are on the global ban list. " .. row.GBLBanReason)
			banPlayer(steam, "10 years", "On global ban list", 0, 0, true)
			return
		else
			-- check number of pending global bans and alert if this player has any, but allow them to join.
			cursor,errorString = connBots:execute("SELECT count(steam) as pendingBans FROM bans WHERE (Steam = " .. steam .. " or Steam = " .. steamOwner .. ") and GBLBan = 1 and GBLBanVetted = 0")
			row = cursor:fetch({}, "a")
			if tonumber(row.pendingBans) > 0 then
				irc_chat(server.ircMain, "ALERT!  Player " .. steam ..  " " .. player .. " has " .. row.pendingBans .. " pending global bans.  If the bot bans them, it will add a new active global ban.")
				players[steam].pendingBans = row.pendingBans
				alertAdmins("ALERT!  Player " .. steam ..  " " .. player .. " has " .. row.pendingBans .. " pending global bans.  If the bot bans them, it will add a new active global ban.")
			end
		end
	end


	if debug then dbug("playerConnected end") end
end
