--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function isNewPlayer(steam)
	if igplayers[steam] then
		if (igplayers[steam].sessionPlaytime + players[steam].timeOnServer < (server.newPlayerTimer * 60)) then
			return true
		else
			return false
		end
	else
		if tonumber(players[steam].timeOnServer) < (tonumber(server.newPlayerTimer) * 60) then
			return true
		else
			return false
		end
	end

	return true
end


function isFriend(testid, steamid)
	-- is steamid a friend of testid?

	if testid == nil then
		return false
	end

	if friends[testid] == nil then -- testid is missing from friends data
		return false
	end

	if friends[testid].friends == nil then -- testid has no friends
		return false
	end

	if string.find(friends[testid].friends, steamid) then
		-- found steamid in testid's friends list.
		return true
	end

	-- steamid is not a friend of testid
	return false
end


function message(msg, irc)
	-- parse msg and enclose the actual message in double quotes
	words = {}
	for word in msg:gmatch("%S+") do table.insert(words, word) end

	if words[1] == "say" then
		-- say the message in public chat
		send("say \"" .. string.sub(msg, 5) .. "\"")
	else
		if players[words[2]].exiled~=1 then
			send("pm  " .. words[2] .. " \"" .. string.sub(msg, 21) .. "\"")
		end

		if irc ~= nil then
			-- send a copy of the pm to irc
			irc_QueueMsg(irc, "pm to " .. words[2] .. " " .. string.sub(msg, 21))
		end
	end
end


function pvpZone(x, z)
	-- is the coord x,z a pvp zone?
	if server.northeastZone == "pvp" and tonumber(x) > 0 and tonumber(z) > 0 then
		return true
	end

	if server.northwestZone == "pvp" and tonumber(x) < 0 and tonumber(z) > 0 then
		return true
	end

	if server.southeastZone == "pvp" and tonumber(x) > 0 and tonumber(z) < 0 then
		return true
	end

	if server.southwestZone == "pvp" and tonumber(x) < 0 and tonumber(z) < 0 then
		return true
	end

	for k, v in pairs(locations) do
		if (v.pvp) then
			-- if the coord is inside this pvp location, return the location name
			if math.abs(v.x-x) <= (tonumber(v.size)) and math.abs(v.z-z) <= (tonumber(v.size)) then
				return true
			end
		else
			-- if the coord is inside this pvp location, return the location name
			if math.abs(v.x-x) <= (tonumber(v.size)) and math.abs(v.z-z) <= (tonumber(v.size)) then
				return false
			end
		end
	end

	return false
end


function inLocation(x, z)
	-- is the coord inside a location?
	local closestLocation, closestDistance, dist, reset

	-- since locations can exist inside other locations, work out which location centre is closest
	closestDistance = 100000
	reset = false

	for k, v in pairs(locations) do
		if v.size ~= nil then
			if math.abs(v.x-x) <= tonumber(v.size) and math.abs(v.z-z) <= tonumber(v.size) then
				dist = distancexz(x, z, v.x, v.z)

				if tonumber(dist) < tonumber(closestDistance) then
					closestLocation = v.name
					closestDistance = dist
					reset = v.resetZone
				end	
			end
		else
			if math.abs(v.x-x) < 15 and math.abs(v.z-z) < 15 then
				dist = distancexz(x, z, v.x, v.z)

				if dist < closestDistance then
					closestLocation = v.name
					closestDistance = dist
					reset = v.resetZone
				end	
			end
		end
	end

	if closestLocation ~= nil then
		return closestLocation, reset
	else
		return false, false
	end
end


function LookupArenaPlayer(id)
	-- is id in the arenaPlayers table?
	for k, v in pairs(arenaPlayers) do
		if (id == v.id) then
			return k
		end
	end
end


function LookupPlayer(search, match)
	-- try to find the player amoung those who are playing right now
	local id

	if string.trim(search) == "" then
		return nil
	end

	search = string.lower(search)

	if string.starts(search, "\"") and string.ends(search,"\"") then
		search = search:match("%w+")
		match = "all"
	end

	for k, v in pairs(igplayers) do
		if search == v.id then
			-- matched the player id
			return k
		end

		if k == search then
			-- matched the steam id
			return k
		end

		if (v.name ~= nil) then
			if match == "all" then
				-- look for an exact match
				if (search == string.lower(v.name)) then
					return k
				end

				if (v.ircAlias ~= nil) and (search == string.lower(v.ircAlias)) then
					return k
				end
			else
				-- if it contains the search it is a match
				if (search == string.lower(v.name)) or (string.find(string.lower(v.name), search, nil, true)) then
					return k
				end

				if (string.find(v.id, search)) then
					return k
				end
			end
		end
	end

	-- no matches so try again but including all players
	id = LookupOfflinePlayer(search, match)

	-- if id isn't nil we found a match
	if id ~= nil then return id end
end


function LookupOfflinePlayer(search, match)
	if string.trim(search) == "" then
		return nil
	end

	search = string.lower(search)

	if string.starts(search, "\"") and string.ends(search,"\"") then
		search = search:match("%w+")
		match = "all"
	end

	for k, v in pairs(players) do
		if (v.name ~= nil) then
			if match == "all" then
				if (search == string.lower(v.name)) then
					return k
				end

				if (v.ircAlias ~= nil) and (search == string.lower(v.ircAlias)) then
					return k
				end
			else
				if (search == string.lower(v.name)) or (string.find(string.lower(v.name), search, nil, true)) then
					return k
				end
			end
		end

		if search == v.id then
			return k
		end

		if k == search then
			return k
		end
	end

	return nil
end


function LookupIRCPass(pass)
	if string.trim(pass) == "" then
		return nil
	end

	-- is this pass in use?
	pass = string.lower(pass)

	for k, v in pairs(players) do
		if (v.ircPass ~= nil) then
			if (pass == string.lower(v.ircPass)) then
				return k
			end
		end
	end
end


function LookupLocation(command)
	-- is command the name of a location?
	command = string.lower(command)

	if (string.find(command, "/") == 1) then 
		command = string.sub(command, 2) -- strip off the leading /
	end

	for k, v in pairs(locations) do
		if (command == string.lower(v.name)) then
			return k
		end
	end
end


function LookupTeleportByName(tpname)
	-- find a teleport by its name
	tpname = string.lower(tpname)

	for k, v in pairs(teleports) do
		if (tpname == string.lower(v.name)) then
			return k
		end
	end
end


function LookupTeleport(x,y,z)
	-- is this 3D coord inside a teleport?
	match = 0

	for k, v in pairs(teleports) do
       if ((math.abs(math.abs(x) - math.abs(v.x)) < 1) and (math.abs(math.abs(y) - math.abs(v.y)) < 1) and (math.abs(math.abs(z) - math.abs(v.z)) < 1)) then
			match = 1
			return k
		end

		if(v.dx) then
	       if ((math.abs(math.abs(x) - math.abs(v.dx)) < 1) and (math.abs(math.abs(y) - math.abs(v.dy)) < 1) and (math.abs(math.abs(z) - math.abs(v.dz)) < 1)) then
				match = 2
				return k
			end
		end
	end
end


function ClosestHotspot(x, y, z)
	-- what is the closest hotspot to this 3D coord?
	local closest = 1000
	local dist = 2000
	local spot = 0

	for k, v in pairs(hotspots) do
		dist = distancexyz(x, y, z, v.x, v.y, v.z)
			
		if (dist < closest) and (dist < 21) then
			closest = dist
			spot = k
		end
	end

	if (spot ~= 0) then
		return spot
	end
end


function LookupVillager(steam, village)
	-- is steam a member of village?
	if villagers[steam .. village] ~= nil then
		return true
	else
		return false
	end
end


function tablelength(T)
	-- helper function to count the members of a Lua table
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


function getRegion(xpos,zpos)
	-- build the region name from the coords.  Each region is a physical file in the saves folder
	local x
	local z

	x = math.floor(tonumber(xpos) / 512)
	z = math.floor(tonumber(zpos) / 512)
	return "r." .. x .. "." .. z .. ".7rg", x, z
end


function squareDistanceXZXZ(x1, z1, x2, z2, distance)
	-- calculate the square distance between 2 coords
	if math.abs(x2-x1) > tonumber(distance) or math.abs(z2-z1) > tonumber(distance) then
		return true
	else
		return false
	end
end


function squareDistance(x, z, distance)
	-- another square distance calculation
	if math.abs(x) > tonumber(distance) or math.abs(z) > tonumber(distance) then
		return true
	else
		return false
	end
end


function compare(a,b)
	-- simple sort
  return a[1] < b[1]
end


function distancexyz( x1, y1, z1, x2, y2, z2 )
	-- calc the distance between 2 points in 3D
   local dx = x2 - x1
	local dy = y2 - y1
	local dz = z2 - z1	
   return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end


function distancexz(x1, z1, x2, z2)
	-- calc the distance between 2 points in 2D (xz)
	local dx = x1 - x2
   local dz = z1 - z2
   return math.sqrt(dx * dx + dz * dz)
end


function say(message)
	-- just a catcher for old code
	send(message)
	return
end


function ToInt(number)
   return math.floor(tonumber(number) or nil)
end


function getAngle(x1, z1, x2, z2)
	-- Returns the angle between two points.
	return math.atan2(z2-z1, x2-x1) 
end


function getCompass(x1, z1, x2, z2)
	-- given 2 pairs of coordinates (the player and something else), determine where it is on a compass in relation to the player.
	local direction
	local angle
	local testangle
	local increment
	local index

	direction = { "south west","south","south east","east", "north east","north","north west","west" }

	angle = getAngle(x1, z1, x2, z2)

	increment = (2 * math.pi) / 8
	testangle = -math.pi + increment
	index = 1

	while angle > tonumber(testangle) do
	    index = index + 1
	    if(index > 8) then
        return direction[1] --roll over
		end

		testangle = testangle + increment
	end

	return direction[index]
end


function accessLevel(pid)
	-- determine the access level of the player

	if owners[pid] then
		players[pid].accessLevel = 0
		return 0
	end

	if admins[pid] then
		players[pid].accessLevel = 1
		return 1
	end

	if mods[pid] then
		players[pid].accessLevel = 2
		return 2
	end

	if tonumber(server.accessLevelOverride) < 99 then
		return tonumber(server.accessLevelOverride) 
	end

	-- 3 is reserved for visiting admins

	if players[pid].donor == true then
--TODO: Add donor levels
		players[pid].accessLevel = 10
		return 10
	end

	-- anyone stripped of certain rights
	if players[pid].denyRights == true then
		players[pid].accessLevel = 99
		return 99
	end

	-- regulars
	if igplayers[pid] then
		if tonumber(players[pid].timeOnServer) + tonumber(igplayers[pid].sessionPlaytime) > (server.newPlayerTimer * 60) then
			players[pid].accessLevel = 90
			return 90
		end
	else
		if tonumber(players[pid].timeOnServer) > (server.newPlayerTimer * 60) then
			players[pid].accessLevel = 90
			return 90
		end
	end
	
	-- new players
	players[pid].accessLevel = 99
	return 99
end


function fixMissingPlayer(steam)
	-- if any fields are missing from the players player record, add them with default values

	if (players[steam].steamOwner == nil) then
		players[steam].steamOwner = steam
	end

	if (players[steam].canTeleport == nil) then
		players[steam].canTeleport = true
	end

	if (players[steam].country == nil) then
		players[steam].country = ""
	end

	if (players[steam].prisoner == nil) then
		players[steam].prisoner = false
	end

	if (players[steam].whitelisted == nil) then
		players[steam].whitelisted = false
	end

	if (players[steam].permanentBan == nil) then
		players[steam].permanentBan = false
	end

	if (players[steam].tokens == nil) then
		players[steam].tokens = 0
	end

	if (players[steam].removeClaims == nil) then
		players[steam].removeClaims = false
	end

	if (players[steam].exiled == nil) then
		players[steam].exiled = 0
	end

	if (players[steam].removedClaims == nil) then
		players[steam].removedClaims = 0
	end

	if (players[steam].bed == nil) then
		players[steam].bed = ""
	end

	if (players[steam].seen == nil) then
		players[steam].seen = ""
	end

	if (players[steam].IP == nil) then
		players[steam].IP = ""
	end

	if (players[steam].raiding == nil) then
		players[steam].raiding = false
	end

	if (players[steam].watchCash == nil) then
		players[steam].watchCash = false
	end

	if (players[steam].alertPVP == nil) then
		players[steam].alertPVP = true
	end

	if (players[steam].shareWaypoint == nil) then
		players[steam].shareWaypoint = false
	end

	if (players[steam].teleCooldown == nil) then
		players[steam].teleCooldown = 0
	end

	if (players[steam].keystones == nil) then
		players[steam].keystones = 0
	end

	if (players[steam].firstSeen == nil) then
		players[steam].firstSeen = 0
	end

	if (players[steam].level == nil) then
		players[steam].level = 1
	end

	if (players[steam].exitX == nil) then
		players[steam].exitX = 0
		players[steam].exitY = 0
		players[steam].exitZ = 0
	end

	if players[steam].exitX == 0 and players[steam].exitZ == 0 then
		players[steam].exitY = 0
	end

	if (players[steam].exit2X == nil) then
		players[steam].exit2X = 0
		players[steam].exit2Y = 0
		players[steam].exit2Z = 0
	end

	if players[steam].exit2X == 0 and players[steam].exit2Z == 0 then
		players[steam].exit2Y = 0
	end

	if (players[steam].xPos == nil) then
		players[steam].xPos = 0
		players[steam].yPos = 0
		players[steam].zPos = 0
	end

	if (players[steam].xPosOld == nil) then
		players[steam].xPosOld = 0
		players[steam].yPosOld = 0
		players[steam].zPosOld = 0
	end

	if (players[steam].xPosOld2 == nil) then
		players[steam].xPosOld2 = 0
		players[steam].yPosOld2 = 0
		players[steam].zPosOld2 = 0
	end

	if (players[steam].ircAlias == nil) then
		players[steam].ircAlias = ""
		players[steam].ircPass = ""
		players[steam].ircAuthenticated = false
	end

	if (players[steam].baseCooldown == nil) then
		players[steam].baseCooldown = 0
	end

	if (players[steam].silentBob == nil) then
		players[steam].silentBob = false
	end

	if (players[steam].donor == nil) then
		players[steam].donor = false
	end

	if (players[steam].donorExpiry == nil) then
		players[steam].donorLevel = 0
		players[steam].donorExpiry = os.time()
	end

	if (players[steam].timeOnServer == nil) then
		players[steam].timeOnServer = 0
	end

	if (players[steam].protect == nil) then
		players[steam].protect = false
	end

	if (players[steam].protectSize == nil) then
		players[steam].protectSize = server.baseSize
	end

	if (players[steam].protect2 == nil) then
		players[steam].protect2 = false
	end

	if (players[steam].protect2Size == nil) then
		players[steam].protect2Size = server.baseSize
	end

	if (players[steam].homeX == nil) then
		players[steam].homeX = 0
		players[steam].homeY = 0
		players[steam].homeZ = 0
	end

	if players[steam].homeX == 0 and players[steam].homeZ == 0 then
		players[steam].homeY = 0
	end

	if (players[steam].home2X == nil) then
		players[steam].home2X = 0
		players[steam].home2Y = 0
		players[steam].home2Z = 0
	end

	if players[steam].home2X == 0 and players[steam].home2Z == 0 then
		players[steam].home2Y = 0
	end

	if (players[steam].waypointX == nil) then
		players[steam].waypointX = 0
		players[steam].waypointY = 0
		players[steam].waypointZ = 0
	end

	if (players[steam].timeout == nil) then
		players[steam].timeout = false
	end

	if (players[steam].alertPrison == nil) then
		players[steam].alertPrison = true
	end

	if (players[steam].alertReset == nil) then
		players[steam].alertReset = true
	end

	if (players[steam].alertMapLimit == nil) then
		players[steam].alertMapLimit = false
	end

	if (players[steam].alertRemovedClaims == nil) then
		players[steam].alertRemovedClaims = false
	end

	if (players[steam].walkies == nil) then
		players[steam].walkies = false
	end

	if (players[steam].newPlayer == nil) then
		players[steam].newPlayer = true
	end

	if (players[steam].sessionCount == nil) then
		players[steam].sessionCount = 1
	end

	if (players[steam].watchPlayer == nil) then
		players[steam].watchPlayer = true
	end

	if (players[steam].lastBaseRaid == nil) then
		players[steam].lastBaseRaid = 0
	end

	if players[steam].names == nil then
		players[steam].names = players[steam].name
	end

	if players[steam].playtime == nil then
		players[steam].playtime = 0
	end

	if players[steam].playerKills == nil then
		players[steam].playerKills = 0
	end

	if players[steam].deaths == nil then
		players[steam].deaths = 0
	end

	if players[steam].score == nil then
		players[steam].score = 0
	end

	if players[steam].zombies == nil then
		players[steam].zombies = 0
	end

	if players[steam].cash == nil then
		players[steam].cash = 0
	end

	if players[steam].overstackScore == nil then
		players[steam].overstack = false
		players[steam].overstackScore = 0
		players[steam].overstackItems = ""
		players[steam].overstackTimeout = false
	end

	if (players[steam].botTimeout == nil) then
		players[steam].botTimeout = false
	end

	if players[steam].pvpBounty == nil then
		players[steam].pvpBounty = 0
	end

	if (invTemp[steam] == nil) then
		invTemp[steam] = {}
	end

	if (friends[steam] == nil) then
		friends[steam] = {}
		friends[steam].friends = ""
	end

	if (lastHotspots[steam] == nil) then
		lastHotspots[steam] = {}
	end

	if players[steam].denyRights == nil then -- if true, a player is not allowed special roles like admin.
		players[steam].denyRights = false
	end

	if players[steam].lastCommand == nil then
		players[steam].lastCommand = ""
		players[steam].lastCommandTimestamp = os.time()
	end

	if players[steam].lastLogout == nil then
		players[steam].lastLogout = os.time()
		players[steam].relogCount = 0
	end

	if players[steam].atHome == nil then
		players[steam].atHome = false
	end

	if players[steam].autoFriend == nil then
		players[steam].autoFriend = ""
	end

	if players[steam].hackerScore == nil then
		players[steam].hackerScore = 0
	end

	if players[steam].tp == nil then
		players[steam].tp = 0
	end

	if (players[steam].bedX == nil) then
		players[steam].bedX = 0
		players[steam].bedY = 0
		players[steam].bedZ = 0
	end

	if players[steam].packCooldown == nil then
		players[steam].packCooldown = 0
	end

	if players[steam].ping == nil then
		players[steam].ping = 0
	end
	
	if players[steam].ISP == nil then
		players[steam].ISP = ""
	end
	
	if players[steam].ignorePlayer == nil then
		players[steam].ignorePlayer = false	
	end
end


function fixMissingIGPlayer(steam)
	-- if any fields are missing from the players in-game player record, add them with default values

	if (igplayers[steam].steamOwner == nil) then
		igplayers[steam].steamOwner = steam
	end

	if igplayers[steam].playGimme == nil then
		igplayers[steam].playGimme = false
	end

	if igplayers[steam].alertRemovedClaims == nil then
		igplayers[steam].alertRemovedClaims = false
	end

	if (igplayers[steam].lastLogin == nil) then
		igplayers[steam].lastLogin = ""
	end

	if (igplayers[steam].greet == nil) then
		igplayers[steam].greet = false
	end

	if (igplayers[steam].greetdelay == nil) then
		igplayers[steam].greetdelay = 0
	end

	if (igplayers[steam].teleCooldown == nil) then
		igplayers[steam].teleCooldown = 0
	end

	if (igplayers[steam].firstSeen == nil) then
		igplayers[steam].firstSeen = os.time()
	end

	if (igplayers[steam].sessionStart == nil) then
		igplayers[steam].sessionStart = os.time()
	end

	if (igplayers[steam].sessionPlaytime == nil) then
		igplayers[steam].sessionPlaytime = 0
	end

	if (igplayers[steam].fetch == nil) then
		igplayers[steam].fetch = false
	end

	if (igplayers[steam].lastHotspot == nil) then
		igplayers[steam].lastHotspot = 0
	end

	if (igplayers[steam].inventory == nil) then
		igplayers[steam].inventory = ""
	end

	if (igplayers[steam].belt == nil) then
		igplayers[steam].belt = ""
	end

	if (igplayers[steam].pack == nil) then
		igplayers[steam].pack = ""
	end

	if (igplayers[steam].equipment == nil) then
		igplayers[steam].equipment = ""
	end

	if (igplayers[steam].illegalInventory == nil) then
		igplayers[steam].illegalInventory = false
	end

	if (igplayers[steam].inventoryLast == nil) then
		igplayers[steam].inventoryLast = ""
	end

	if (igplayers[steam].botQuestion == nil) then
		igplayers[steam].botQuestion = ""
	end

	if (igplayers[steam].region == nil) then
		igplayers[steam].region = ""
	end

	if (igplayers[steam].killTimer == nil) then
		igplayers[steam].killTimer = 0
	end

	if (igplayers[steam].connected == nil) then
		igplayers[steam].connected = true
	end

	if (igplayers[steam].timeOnServer == nil) then
		igplayers[steam].timeOnServer = players[steam].timeOnServer
	end

	if (igplayers[steam].region == nil) then
		igplayers[steam].region = ""
	end

	if (igplayers[steam].ping == nil) then
		igplayers[steam].ping = ping
	end

	if (igplayers[steam].xPos == nil) then
		igplayers[steam].xPos = 0
		igplayers[steam].yPos = 0
		igplayers[steam].zPos = 0

		igplayers[steam].xPosLast = 0
		igplayers[steam].yPosLast = 0
		igplayers[steam].zPosLast = 0

		igplayers[steam].xPosLastOK = 0
		igplayers[steam].yPosLastOK = 0
		igplayers[steam].zPosLastOK = 0
	end

	if (igplayers[steam].afk == nil) then
		igplayers[steam].afk = os.time() + 900
	end

	if igplayers[steam].lastCatchTimestamp == nil then
		igplayers[steam].lastCatchTimestamp = os.time()
	end

	if igplayers[steam].alertLocation == nil then
		igplayers[steam].alertLocation = ""
	end

	if igplayers[steam].notifyTP == nil then
		igplayers[steam].notifyTP = false
	end

	if igplayers[steam].lastLP == nil then
		igplayers[steam].lastLP = os.time()
	end

	if igplayers[steam].doge == nil then
		igplayers[steam].doge = false
	end

	if igplayers[steam].highPingCount == nil then
		igplayers[steam].highPingCount = 0
	end
	
	if igplayers[steam].flying == nil then
		igplayers[steam].flying = false
		igplayers[steam].flyCount = 0
	end
end
