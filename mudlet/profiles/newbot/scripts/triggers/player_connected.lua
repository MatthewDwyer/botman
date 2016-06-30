--[[ 
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local nameTest

function playerDenied(line)
	local steam

	steam = string.trim(string.sub(line, string.find(line, "INF Player") + 12, string.find(line, "denied") - 3))
	steam = LookupPlayer(steam)

	if steam ~= nil then
		if (accessLevel(steam) < 5) then
			reserveSlot(steam)
		end
	end
end

function playerConnected(line)
	local entityid, player, steam, steamOwner, IP, temp_table, temp, debug
	local timestamp = os.time()

	debug = false

	if debug then dbug("playerConnected 1") end

	temp_table = string.split(line, ",")
	timeConnected = string.sub(line, 1, 19)

	if string.find(line, "steamid=") then 
		player = string.trim(string.sub(temp_table[3], string.find(temp_table[3], "name=") + 5, string.find(temp_table[3], ",")))
		steam = string.sub(temp_table[4], string.find(temp_table[4], "steamid=") + 8, string.find(temp_table[4], ","))
		entityid = string.sub(temp_table[2], string.find(temp_table[2], "entityid=") + 9, string.find(temp_table[2], ","))
		if string.find(line, "steamOwner") then
			steamOwner = string.sub(temp_table[5], string.find(temp_table[5], "steamOwner=") + 11)
			IP = string.sub(temp_table[6], string.find(temp_table[6], "ip=") + 3)
		else
			steamOwner = steam
			IP = string.sub(temp_table[5], string.find(temp_table[5], "ip=") + 3)
		end
	end

	if IP == nil then IP = "" end

	if debug then dbug("playerConnected 2") end

	if string.find(line, "OwnerID=") and not string.find(line, "OwnerID=''") then
		steam = string.sub(line, string.find(line, "OwnerID=") + 9, string.find(line, "PlayerName=") - 4)
		player = string.trim(string.sub(line, string.find(line, "PlayerName=") + 12, string.len(line) - 1))
		entityid = string.sub(line, string.find(line, "EntityID=") + 9, string.find(line, "PlayerID=") - 3)
	end

	if debug then dbug("playerConnected 3") end

	-- log the player connection in events table
	conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. serverTime .. "','player joined','Player joined " .. escape(player) .. " " .. steam .. " Owner " .. steamOwner .. " " .. entityid .. " " .. IP .. "'," .. steamOwner .. ")")

	if debug then dbug("playerConnected 4") end

	if	db2Connected then
		-- copy in bots db
		connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.ServerName) .. "','" .. serverTime .. "','player joined','Player joined " .. escape(player) .. " " .. steam .. " Owner " .. steamOwner .. " " .. entityid .. " " .. IP .. "'," .. steamOwner .. ")")
	end

	if debug then dbug("playerConnected 5") end

	lastPlayerConnected = player
	lastSteamConnected = steam

	if string.find(player, "[\(\)]%d+") then
		kick(steam, "Sorry another player with the same name as you is playing here right now.  We do not allow multiple players on at the same time with the same name.")
		return
	end

	if isReservedName(player, steam) then
		kick(steam, "That name is reserved.  You cannot play as " .. player .. " here.")
		return
	end
	
	irc_QueueMsg(server.ircMain, gameDate .. " " .. steam .. " " .. player .. " connected")
	logChat(serverTime, "Server", steam .. " " .. player .. " connected")

	-- add to players table
	if (not players[steam]) then
		initNewPlayer(steam, player, entityid, steamOwner)
		fixMissingPlayer(steam, steamOwner)

		irc_QueueMsg(server.ircMain, "###  New player joined " .. player .. " steam: " .. steam.. " owner: " .. steamOwner .. " id: " .. entityid .. " ###")
		irc_QueueMsg(server.ircAlerts, "New player joined")
		irc_QueueMsg(server.ircAlerts, line:gsub("%,", ""))
		irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. player .. " new player connected")

		for k, v in pairs(igplayers) do
			if accessLevel(k) < 3 then
				message("pm " .. k .. " [" .. server.chatColour .. "]New player joined " .. entityid .. " " .. player .. "[-]")
			end
		end

		conn:execute("INSERT INTO players (steam, steamOwner, id, name, protectSize, protect2Size, firstSeen) VALUES (" .. steam .. "," .. steamOwner .. "," .. entityid .. ",'" .. escape(player) .. "'," .. server.baseSize .. "," .. server.baseSize .. "," .. os.time() .. ")")		

		if debug then dbug("playerConnected 6") end

		conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. serverTime .. "','new player','New player joined " .. escape(player) .. " steam: " .. steam .. " owner: " .. steamOwner .. " id: " .. entityid .. "'," .. steam .. ")")

		if debug then dbug("playerConnected 7") end

		if	db2Connected then
			-- also update the bots db
			insertBotsPlayer(steam)
		end

		if debug then dbug("playerConnected 8") end

		if	db2Connected then
			-- copy in bots db 
			connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.ServerName) .. "','" .. serverTime .. "','new player','New player joined " .. escape(player) .. " steam: " .. steam .. " owner: " .. steamOwner .. " id: " .. entityid .. "'," .. steam .. ")")
		end

		if debug then dbug("playerConnected 9") end
	else
		-- add to in-game players table
		if (not igplayers[steam]) then
			initNewIGPlayer(steam, player, entityid, steamOwner)
			fixMissingIGPlayer(steam, steamOwner)
		end

		players[steam].IP = IP

		if debug then dbug("playerConnected 10") end

		if	db2Connected then
			-- update player in bots db
			updateBotsPlayer(steam)
		end
		cmd = "llp " .. steam
		tempTimer( 5, [[send("]] .. cmd .. [[")]] )
	end

	if inWhitelist(steam) then
		players[steam].whitelisted = true
	end

	if server.coppi and players[steam].mute then
		send("mpc " .. steam .. " true")
	end

	if debug then dbug("playerConnected 11") end

	if IP ~= "" then
		CheckBlacklist(steam, IP)
	end

	if debug then dbug("playerConnected 12") end

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

	if debug then dbug("playerConnected 13") end

	conn:execute("UPDATE players SET aliases = '" .. players[steam].names .. "', sessionCount = " .. players[steam].sessionCount .. " WHERE steam = " .. steam)

	if debug then dbug("playerConnected 14") end

	-- kick player if currently banned or permabanned
	cursor,errorString = conn:execute("SELECT * FROM bans WHERE Steam = " .. steam .. " or Steam = " .. steamOwner .. " and expiryDate > '" .. os.date("%Y-%m-%d %H:%M:%S") .. "'")
	if cursor:numrows() > 0 then
		kick(steam, "You are currently banned. Contact us if this is in error.")
		return
	end

	-- kick for bad player name
	if	not server.allowNumericNames and not server.allowGarbageNames and not players[steam].whitelisted then
		temp = countAlphaNumeric(player)

		if tonumber(player) ~= nil or tonumber(temp) == 0 then
			kick(steam, "Names without letters are not allowed here. You need to change your name to play on this server.")
			return
		end
	end

	-- kick player if only 1 slot left and it is reserved for someone else
	if tonumber(playersOnline) == tonumber(server.ServerMaxPlayerCount) - 1 and tonumber(table.maxn(reservedSlots)) > 0 and not reservedSlots[steam] then
		kick(steam, "Sorry the last slot is temporarily reserved. Please try again in a minute.")
		return
	end	

	if not server.allowRapidRelogging then
		-- temp ban the player if they are relogging too many times in quick succession
		if tonumber(players[steam].relogCount) > 3 and players[steam].newPlayer then
			banPlayer(steam, "1 day", "relogging many times in a short space of time.", "")
			players[steam].relogCount = 0
		end
	end

	-- delete read mail that isn't flagged as saved (status = 2).
	conn:execute("DELETE FROM mail WHERE id = " .. steam .. " and status = 1")

	if server.coppi then
		send("pcml " .. steam .. " 255")
	end

	cecho(server.windowDebug, "Finished Player Connected\n")

	-- if they player is doing the spawn drop hack to spawn items into the game we should see them with the le command.
	send("le")

	if debug then dbug("playerConnected end") end
end
