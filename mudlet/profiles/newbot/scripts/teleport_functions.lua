--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function forgetLastTP(steam)
	if igplayers[steam] then
		igplayers[steam].lastTP = nil
	end
end


function prepareTeleport(steam, cmd)
	if igplayers[steam] then
		igplayers[steam].lastTP = cmd
		igplayers[steam].tp = 1
		igplayers[steam].hackerTPScore = 0

		-- record the player's current x y z
		if tonumber(players[steam].accessLevel) < 3 or (string.lower(players[steam].inLocation) ~= "prison") then
			players[steam].xPosOld = players[steam].xPos
			players[steam].yPosOld = players[steam].yPos
			players[steam].zPosOld = players[steam].zPos
		end

		igplayers[steam].lastLocation = ""
	end
end


function teleport(cmd, steam, justTeleport)
	local coords, delay, dist
	dist = nil

	prepareTeleport(steam, cmd)

	-- disable some stuff because we are teleporting
	igplayers[steam].location = nil
	igplayers[steam].lastTP = cmd

	coords = string.sub(cmd, 24)
	coords = string.split(coords, " ")

	-- make sure all 3 coords are integers
	coords[1] = math.floor(coords[1])
	coords[2] = math.floor(coords[2])
	coords[3] = math.floor(coords[3])

	-- don't teleport the player if the coords are 0 0 0
	if coords[1] == 0 and coords[2] < 1 and coords[3] == 0 then
		return false
	end

	-- bump the y coord up by 1 so we don't tele into the ground.
	coords[2] = coords[2] + 1

	-- if an admin is following a player (using the /near command) and they teleport away, stop following the player
	if igplayers[steam].following ~= nil then igplayers[steam].following = nil end

	igplayers[steam].tp = 1
	igplayers[steam].hackerTPScore = 0
	igplayers[steam].spawnPending = true
	igplayers[steam].lastTPTimestamp = os.time()
	sendCommand(cmd)
	igplayers[steam].tp = 1
	igplayers[steam].hackerTPScore = 0

	if not justTeleport then
		if tonumber(server.returnCooldown) > 0 and accessLevel(steam) > 2 then
			if players[steam].donor then
				delay = os.time() + math.floor(server.returnCooldown / 2)
			else
				delay = os.time() + server.returnCooldown
			end

			players[steam].returnCooldown = delay
			if botman.dbConnected then conn:execute("UPDATE players SET returnCooldown = " .. delay .. " WHERE steam = " .. steam) end
		end
	end

	return true
end


function randomTP(playerid, location, forced)
	local r, rows, row, rowCount, cmd, cursor, errorString

	if not locations[location] then
		-- Lua is case sensitive and location didn't match any keys so do a lookup on it (not case sensitive) and return the correct cased key name
		location = LookupLocation(location)
	end

	if botman.dbConnected then
		cursor,errorString = conn:execute("select * from locationSpawns where location='" .. location .. "'")
		rows = tonumber(cursor:numrows())

		if rows == 0 then
			cmd = "tele " .. playerid .. " " .. locations[location].x .. " " .. locations[location].y .. " " .. locations[location].z

			if tonumber(server.playerTeleportDelay) == 0 or forced or tonumber(players[playerid].accessLevel) < 2 then --  or not igplayers[playerid].currentLocationPVP
				teleport(cmd, playerid)
			else
				message("pm " .. playerid .. " [" .. server.chatColour .. "]You will be teleported to " .. location .. " in " .. server.playerTeleportDelay .. " seconds.[-]")
				if botman.dbConnected then conn:execute("insert into persistentQueue (steam, command, timerDelay) values (" .. playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
			end

			return
		end
	else
		cmd = "tele " .. playerid .. " " .. locations[location].x .. " " .. locations[location].y .. " " .. locations[location].z
		teleport(cmd, playerid)

		return
	end

	rowCount = 1
	r = rand(rows)

	cursor,errorString = conn:execute("select * from locationSpawns where location='" .. location .. "' limit " .. r - 1 .. ",1")
	row = cursor:fetch({}, "a")
	cmd = "tele " .. playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z

	-- handle new player's being moved to lobby or spawn on first arrival.
	if (string.lower(location) == "lobby" or string.lower(location) == "spawn") and players[playerid].location ~= "" then
		teleport(cmd, playerid)
	else
		if tonumber(server.playerTeleportDelay) == 0 or forced or tonumber(players[playerid].accessLevel) < 2 then --  or not igplayers[playerid].currentLocationPVP
			teleport(cmd, playerid)
		else
			message("pm " .. playerid .. " [" .. server.chatColour .. "]You will be teleported to " .. location .. " in " .. server.playerTeleportDelay .. " seconds.[-]")
			if botman.dbConnected then conn:execute("insert into persistentQueue (steam, command, timerDelay) values (" .. playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
			igplayers[playerid].lastTPTimestamp = os.time()
		end
	end
end
