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
		igplayers[steam].lastCatchTimestamp = os.time() + 10
		igplayers[steam].lastTP = nil
	end
end


function prepareTeleport(steam, cmd)
	if igplayers[steam] then
		igplayers[steam].lastCatchTimestamp = os.time() + 10
		igplayers[steam].lastTP = cmd		
		players[steam].tp = 1
		players[steam].hackerTPScore = 0		
	end
end


function teleport(cmd, forced)
	local id, coords, temp, dist
	id = string.sub(cmd, 6, 22)
	dist = nil

	-- disable some stuff because we are teleporting
	igplayers[id].location = nil
	igplayers[id].lastTP = cmd

	coords = string.sub(cmd, 24)
	coords = string.split(coords, " ")

	-- don't teleport the player if the coords are 0 0 0
	if tonumber(coords[1]) == 0 and tonumber(coords[2]) == 0 and tonumber(coords[3]) == 0 then
		return
	end

	-- if an admin is following a player (using the /near command) and they teleport away, stop following the player
	if igplayers[id].following ~= nil then igplayers[id].following = nil end

	players[id].tp = 1
	players[id].hackerTPScore = 0
	
	send(cmd)

	players[id].tp = 1
	players[id].hackerTPScore = 0

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
		prepareTeleport(steam, cmd)
		teleport(cmd, true)		
	end
end


function randomTP(playerid, location, forced)
	local r, rows, row, rowCount

	if botman.dbConnected then 
		cursor,errorString = conn:execute("select * from locationSpawns where location='" .. location .. "'")
		rows = tonumber(cursor:numrows())

		if rows == 0 then
			cmd = "tele " .. playerid .. " " .. locations[location].x .. " " .. locations[location].y .. " " .. locations[location].z
			prepareTeleport(playerid, cmd)
			teleport(cmd, true)
			return
		end
	else
		cmd = "tele " .. playerid .. " " .. locations[location].x .. " " .. locations[location].y .. " " .. locations[location].z
		prepareTeleport(playerid, cmd)
		teleport(cmd, true)
		return	
	end

	rowCount = 1
	r = rand(rows)

	cursor,errorString = conn:execute("select * from locationSpawns where location='" .. location .. "' limit " .. r - 1 .. ",1")
	row = cursor:fetch({}, "a")
	cmd = "tele " .. playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z
	prepareTeleport(playerid, cmd)

	if location == "lobby" then
		teleport(cmd, true)
	else
		if forced ~= nil then
			teleport(cmd, true)
		else
			teleport(cmd)
		end
	end
end
