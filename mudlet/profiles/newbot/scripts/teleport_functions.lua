--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
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
		players[steam].tp = 1
		players[steam].hackerTPScore = 0

		-- record the player's current x y z
		players[steam].xPosOld = math.floor(players[steam].xPos)
		players[steam].yPosOld = math.ceil(players[steam].yPos)
		players[steam].zPosOld = math.floor(players[steam].zPos)
		igplayers[steam].lastLocation = ""
	end
end


function teleport(cmd, steam)
	local coords, temp, dist
	dist = nil

	prepareTeleport(steam, cmd)

	-- disable some stuff because we are teleporting
	igplayers[steam].location = nil
	igplayers[steam].lastTP = cmd

	coords = string.sub(cmd, 24)
	coords = string.split(coords, " ")

	display(coords)

	-- don't teleport the player if the coords are 0 0 0
	if tonumber(coords[1]) == 0 and tonumber(coords[2]) < 1 and tonumber(coords[3]) == 0 then
		return false
	end

	-- if an admin is following a player (using the /near command) and they teleport away, stop following the player
	if igplayers[steam].following ~= nil then igplayers[steam].following = nil end

	players[steam].tp = 1
	players[steam].hackerTPScore = 0

	send(cmd)

	players[steam].tp = 1
	players[steam].hackerTPScore = 0

	return true
end


function fallCatcher(steam, x, y, z)
	local coords, temp, dist, cmd

	if players[steam].timeout == true or players[steam].botTimeout == true or igplayers[steam].following ~= nil or accessLevel(steam) < 3 then
		-- don't catch players in timeout or staff
		return
	end

	if (tonumber(y) < 0 and players[steam].timeout == false and players[steam].botTimeout == false and igplayers[steam].sessionPlaytime > 5)  then
		cmd = "tele " .. steam .. " " .. x .. " -1 " .. z
		teleport(cmd, steam)
	end
end


function randomTP(playerid, location, forced)
	local r, rows, row, rowCount

	if botman.dbConnected then
		cursor,errorString = conn:execute("select * from locationSpawns where location='" .. location .. "'")
		rows = tonumber(cursor:numrows())

		if rows == 0 then
			cmd = "tele " .. playerid .. " " .. locations[location].x .. " " .. locations[location].y .. " " .. locations[location].z

			if tonumber(server.playerTeleportDelay) == 0 or forced or not igplayers[playerid].currentLocationPVP or tonumber(players[playerid].accessLevel) < 2 then
				teleport(cmd, playerid)
			else
				message("pm " .. playerid .. " [" .. server.chatColour .. "]You will be teleported to " .. location .. " in " .. server.playerTeleportDelay .. " seconds.[-]")
				if botman.dbConnected then conn:execute("insert into miscQueue (steam, command, timerDelay) values (" .. playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
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

	if location == "lobby" then
		teleport(cmd, playerid)
	else
		if tonumber(server.playerTeleportDelay) == 0 or forced or not igplayers[playerid].currentLocationPVP or tonumber(players[playerid].accessLevel) < 2 then
			teleport(cmd, playerid)
		else
			message("pm " .. playerid .. " [" .. server.chatColour .. "]You will be teleported to " .. location .. " in " .. server.playerTeleportDelay .. " seconds.[-]")
			if botman.dbConnected then conn:execute("insert into miscQueue (steam, command, timerDelay) values (" .. playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
		end
	end
end
