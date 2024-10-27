--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]


function forgetLastTP(steam)
	if igplayers[steam] then
		igplayers[steam].lastTP = nil
	end
end


function prepareTeleport(steam, userID, cmd)
	if igplayers[steam] then
		igplayers[steam].lastTP = cmd
		igplayers[steam].tp = 1
		igplayers[steam].hackerTPScore = 0

		-- record the player's current x y z
		if isAdminHidden(steam, userID) or (string.lower(players[steam].inLocation) ~= "prison") then
			players[steam].xPosOld = players[steam].xPos
			players[steam].yPosOld = players[steam].yPos
			players[steam].zPosOld = players[steam].zPos
		end

		igplayers[steam].lastLocation = ""
	end
end


function teleport(cmd, steam, userID, justTeleport)
	local coords, delay, dist, temp, i, max, num, newCmd, searchStr
	dist = nil

	prepareTeleport(steam, userID, cmd)

	temp = string.split(cmd, " ")
	newCmd = ""
	searchStr = userID


	max = tablelength(temp)
	for i=1,max,1 do
		num = tonumber(temp[i])
		if num ~= nil then
			if string.len(temp[i]) == 17 then
				-- this is a steam id that is missing Steam_ so we will add that and rebuild the command
				temp[i] = "Steam_" .. temp[i]
				searchStr = temp[i]
			end
		end

		newCmd = newCmd .. " " .. temp[i]
	end

	newCmd = string.trim(newCmd)
	cmd = newCmd

	-- disable some stuff because we are teleporting
	igplayers[steam].location = nil
	igplayers[steam].lastTP = cmd

	coords = string.sub(cmd, string.find(cmd, searchStr) + string.len(searchStr) + 1)
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
		delay = LookupSettingValue(steam, "returnCooldown")

		if tonumber(delay) > 0 and not isAdmin(steam) then
			players[steam].returnCooldown = delay
			if botman.dbConnected then conn:execute("UPDATE players SET returnCooldown = " .. delay .. " WHERE steam = '" .. steam .. "'") end
		end
	end

	return true
end


function randomTP(playerid, userID, location, forced)
	local r, rows, row, rowCount, cmd, cursor, errorString, delay

	if not locations[location] then
		-- Lua is case sensitive and location didn't match any keys so do a lookup on it (not case sensitive) and return the correct cased key name
		location = LookupLocation(location)
	end

	if botman.dbConnected then
		cursor,errorString = connSQL:execute("select count(*) from locationSpawns where location='" .. connMEM:escape(location) .. "'")
		row = cursor:fetch({}, "a")
		rowCount = row["count(*)"]

		delay = LookupSettingValue(playerid, "playerTeleportDelay")

		if rowCount == 0 then
			cmd = "tele " .. userID .. " " .. locations[location].x .. " " .. locations[location].y .. " " .. locations[location].z

			if tonumber(delay) == 0 or forced or isAdmin(playerid) then
				teleport(cmd, playerid, userID)
			else
				message("pm " .. userID .. " [" .. server.chatColour .. "]You will be teleported to " .. location .. " in " .. delay .. " seconds.[-]")
				connSQL:execute("insert into persistentQueue (steam, command, timerDelay) values ('" .. playerid .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + delay .. "')")
				botman.persistentQueueEmpty = false
			end

			return
		else
			r = randSQL(rowCount)
			cursor,errorString = connSQL:execute("select * from locationSpawns where location='" .. connMEM:escape(location) .. "' limit " .. r - 1 .. ",1")
			row = cursor:fetch({}, "a")
			cmd = "tele " .. userID .. " " .. row.x .. " " .. row.y .. " " .. row.z

			-- handle new player's being moved to lobby or spawn on first arrival.
			if (string.lower(location) == "lobby" or string.lower(location) == "spawn") and players[playerid].location ~= "" then
				teleport(cmd, playerid, userID)
			else
				if tonumber(delay) == 0 or forced or isAdmin(playerid)  then
					teleport(cmd, playerid, userID)
				else
					message("pm " .. userID .. " [" .. server.chatColour .. "]You will be teleported to " .. location .. " in " .. delay .. " seconds.[-]")
					connSQL:execute("insert into persistentQueue (steam, command, timerDelay) values ('" .. playerid .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + delay .. "')")
					botman.persistentQueueEmpty = false
					igplayers[playerid].lastTPTimestamp = os.time()
				end
			end
		end
	else
		cmd = "tele " .. userID .. " " .. locations[location].x .. " " .. locations[location].y .. " " .. locations[location].z
		teleport(cmd, playerid, userID)

		return
	end
end
