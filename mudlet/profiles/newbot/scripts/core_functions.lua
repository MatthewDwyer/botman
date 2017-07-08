--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug = false

function alertAdmins(msg, alert)
	-- pm all in-game admins with msg
	local k, v, msgColour

	if(debug) then dbugFull("D", "" , debugger.getinfo(1, "nSl"), (alert or "") .. ", " .. msg) end

	if type(server) == "table" then
		msgColour = server.chatColour
		if alert == "alert" then msgColour = server.alertColour end
		if alert == "warn" then msgColour = server.warnColour end
	else
		msgColour = "D4FFD4"
	end

	if(debug) then dbugFull("D", "" , debugger.getinfo(1, "nSl")) end

	echo(msg .. "\n\n") 
	dbugFull("I", "", "", msg)

	if(debug) then dbugFull("D", "" , debugger.getinfo(1, "nSl")) end

	for k, v in pairs(igplayers) do
		if (accessLevel(k) < 3) then
			if(debug) then dbugFull("D", "" , debugger.getinfo(1, "nSl"), "pm sent to " .. v.name) end
			message("pm " .. k .. " [" .. msgColour .. "]" .. msg .. "[-]")
		end
	end

	if(debug) then dbugFull("D", "" , debugger.getinfo(1, "nSl")) end
end


function stripCommas(value)
	if value == true or value == false then
		return value
	end

	value = string.trim(value)
	value = string.gsub(value, ",", "")
	return value
end


function stripQuotes(name)
	local oldName
	oldName = name

	name = string.gsub(name, "'", "")
	name = string.gsub(name, '"', "")
	name = string.trim(name)
--[[
	name = string.match(name, "^'(.*)'$")

	if name == oldName then
		name = string.match(name, "^\"(.*)\"$")
	end

	if name == nil then name = oldName end

	if string.sub(name, string.len(name)) == "'" then
		name = string.sub(name, 1, string.len(name) - 1)
	end
--]]

	return name
end


function isFile(name)
    if type(name)~="string" then return false end
    if not isDir(name) then
        return os.rename(name,name) and true or false
        -- note that the short evaluation is to
        -- return false instead of a possible nil
    end

    return false
end


function isFileOrDir(name)
    if type(name)~="string" then return false end
    return os.rename(name, name) and true or false
end


function isDir(name)
    if type(name)~="string" then return false end
    local cd = lfs.currentdir()
    local is = lfs.chdir(name) and true or false
    lfs.chdir(cd)
    return is
end


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


local lastMsg
function message(msg, irc)
	-- parse msg and enclose the actual message in double quotes
	local words, word, msgToSend

	if(msg == lastMsg) then
		if(debug) then dbugFull("D", debugger.traceback(), debugger.getinfo(1,"nSl"), "duplicate message intercepted:" .. msg) end
		return
	else
		lastMsg = msg
	end

	words = {}
	msgToSend = string.sub(msg, 21)

	for word in msg:gmatch("%S+") do table.insert(words, word) end

	if words[1] == "say" then
		-- say the message in public chat
		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
		send("say \"" .. string.sub(msg, 5) .. "\"")
	else
	    if(not players[words[2]]) then
		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
		echo(msgToSend .. "\n\n")
	    else
		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if players[words[2]].exiled~=1 then
			if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

			if(string.find(msg, '"')) then
				 if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Message has quotes in it: (" .. msg .. ")") end
				 msg = string.gsub(msg, '"', '')
				 if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Sending fixed message to player: " .. words[2] .. "(" .. msg .. ")") end
			end

			send("pm  " .. words[2] .. " \"" .. msgToSend .. "\"")
		end

		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if irc ~= nil then
			-- send a copy of the pm to irc
			if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

			irc_chat(irc, "pm to " .. words[2] .. " " .. msgToSend)
		end
          end
	end
end



function pvpZone(x, z)
	local k,v, result

	if server.gameType == "pvp" then
		result = true
	else
		result = false
	end

	-- is the coord x,z a pvp zone?
	if server.northeastZone == "pvp" and tonumber(x) > 0 and tonumber(z) > 0 then
		result = true
	end

	if server.northeastZone == "pve" and tonumber(x) > 0 and tonumber(z) > 0 then
		result = false
	end

	if server.northwestZone == "pvp" and tonumber(x) < 0 and tonumber(z) > 0 then
		result = true
	end

	if server.northwestZone == "pve" and tonumber(x) < 0 and tonumber(z) > 0 then
		result = false
	end

	if server.southeastZone == "pvp" and tonumber(x) > 0 and tonumber(z) < 0 then
		result = true
	end

	if server.southeastZone == "pve" and tonumber(x) > 0 and tonumber(z) < 0 then
		result = false
	end

	if server.southwestZone == "pvp" and tonumber(x) < 0 and tonumber(z) < 0 then
		result = true
	end

	if server.southwestZone == "pve" and tonumber(x) < 0 and tonumber(z) < 0 then
		result = false
	end

	for k, v in pairs(locations) do
		if (v.pvp) then
			-- if the coord is inside a pvp location, return true
			if math.abs(v.x-x) <= (tonumber(v.size)) and math.abs(v.z-z) <= (tonumber(v.size)) then
				result = true
			end
		else
			-- if the coord is inside a pve location, return false
			if math.abs(v.x-x) <= (tonumber(v.size)) and math.abs(v.z-z) <= (tonumber(v.size)) then
				result = false
			end
		end
	end

	return result
end


function inLocation(x, z)
	-- is the coord inside a location?
	local closestLocation, closestDistance, dist, reset

	if x == nil then
		return false, false
	end

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
	local k,v

	-- is id in the arenaPlayers table?
	for k, v in pairs(arenaPlayers) do
		if (id == v.id) then
			return k
		end
	end
end


function LookupPlayer(search, match)
	-- try to find the player amoung those who are playing right now
	local id, k,v

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "LookupPlayer(" .. search ..")") end

	if string.trim(search) == "" then
		if(debug) then  dbugFull("D", "", debugger.getinfo(1,"nSl"), "trim(" .. search .. ") == empty string.") end
		return nil
	end

	if(type(search) == "string") then
		search = string.lower(search)
	end

	if string.starts(search, "\"") and string.ends(search,"\"") then
		search = search:match("%w+")
		match = "all"
	end

	for k, v in pairs(igplayers) do
		if match == "code" then
			if tonumber(search) == tonumber(players[k].ircInvite) then
				return k
			end
		else
			if(debug and v.id == nil) then  dbugFull("D", "", debugger.getinfo(1,"nSl"), "LookupPlayer(" .. search .. ") found nil id in igplayers for (" .. v.steam .. ", " .. v.name .. ")") end

			if(debug and v.name == nil) then  dbugFull("D", "", debugger.getinfo(1,"nSl"), "LookupPlayer(" .. search .. ") found nil name in igplayers.") end

			if(debug and v.steam == nil) then  dbugFull("D", "", debugger.getinfo(1,"nSl"), "LookupPlayer(" .. search .. ") found nil steam in igplayers.") end

			if(debug and v.id ~= nil) then  dbugFull("D", "", debugger.getinfo(1,"nSl"), "LookupPlayer(" .. search .. ") vs " .. v.id .. "(" .. v.name .. ")") end

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

					if (v.id ~= nil and string.find(v.id, search)) then
						return k
					end
				end
			end
		end
	end

	-- no matches so try again but including all players
	id = LookupOfflinePlayer(search, match)

	-- if id isn't nil we found a match
	if id ~= nil then return id end

	if(debug) then
		dbugFull("D", debugger.traceback(), debugger.getinfo(1,"nSl"), "LookupPlayer failed for: " .. search)
		dumpPlayers(players)
		dumpPlayers(igplayers)
	end
end


function LookupOfflinePlayer(search, match)
	local k,v

	if string.trim(search) == "" then
		return nil
	end

	search = string.lower(search)

	if string.starts(search, "\"") and string.ends(search,"\"") then
		search = search:match("%w+")
		match = "all"
	end

	for k, v in pairs(players) do
		if match == "code" then
			if tonumber(search) == tonumber(players[k].ircInvite) then
				return k
			end
		else
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
	end

	return nil
end


function LookupIRCAlias(name)
	-- returns a steam ID if only 1 player record uses the name.
	local k,v, nickCount, steam

	nickCount = 0

	for k, v in pairs(players) do
		if (v.ircAlias ~= nil) then
			if (name == v.ircAlias) then
				nickCount = nickCount + 1
				steam = k
			end
		end
	end

	if nickCount == 1 then
		return steam
	end
end


function LookupIRCPass(login, pass)
	local k,v

	if string.trim(pass) == "" then
		return nil
	end

	for k, v in pairs(players) do
		if (v.ircPass ~= nil) then
			if (login == v.ircLogin) and (pass == v.ircPass) then
				return k
			end
		end
	end
end


function LookupLocation(command)
	local k,v

	-- is command the name of a location?
	command = string.lower(command)

	if (string.find(command, server.commandPrefix) == 1) then
		command = string.sub(command, 2) -- strip off the leading /
	end

	for k, v in pairs(locations) do
		if (command == string.lower(v.name)) then
			return k
		end
	end
end


function LookupTeleportByName(tpname)
	local k,v

	-- find a teleport by its name
	tpname = string.lower(tpname)

	for k, v in pairs(teleports) do
		if (tpname == string.lower(v.name)) then
			return k
		end
	end
end


function LookupTeleport(x,y,z)
	local k,v, match

	-- is this 3D coord inside a teleport?
	-- 0 = no, 1 = match xyz, 2 = match dx dy dz (the other end)
	match = 0

	for k, v in pairs(teleports) do
       if ((math.abs(math.abs(x) - math.abs(v.x)) < 1.1) and (math.abs(math.abs(y) - math.abs(v.y)) < 1.1) and (math.abs(math.abs(z) - math.abs(v.z)) < 1.1)) then
			if v.active then
				match = 1
				return k, match
			end
		end

		if(v.dx) then
	       if ((math.abs(math.abs(x) - math.abs(v.dx)) < 1.1) and (math.abs(math.abs(y) - math.abs(v.dy)) < 1.1) and (math.abs(math.abs(z) - math.abs(v.dz)) < 1.1)) then
				if v.active then
					match = 2
					return k, match
				end
			end
		end
	end
end


function LookupWaypointByName(steam, name, friend)
	-- return the waypoint id if a match found for name and owned by steam
	local k, v

	name = string.lower(name)

	for k,v in pairs(waypoints) do
		if friend ~= nil then
			if string.lower(v.name) == name and v.steam == friend then
				if isFriend(friend, steam) then
					return k
				end
			end
		else
			if v.steam == steam and string.lower(v.name) == name then
				return k
			end
		end
	end

	return 0
end


function LookupWaypoint(x,y,z)
	-- return the waypoint owner's steam ID and waypoint 1 or 2 if the player's coords are within 3 blocks of a waypoint
	local k, v

	for k, v in pairs(waypoints) do
		if tonumber(v.y) > 0 then
			if distancexyz(x, y, z, v.x, v.y, v.z) <= 2 then
				return k
			end
		end
	end

	return 0
end


function ClosestWaypoint(x,y,z,steam)
	-- what is the closest hotspot to this 3D coord?
	local closest = 100000
	local dist = 200000
	local wp = 0
	local k,v, dist

	for k,v in pairs(waypoints) do
		if steam ~= nil then
			if v.steam == steam then
				dist = distancexyz(x, y, z, v.x, v.y, v.z)

				if (dist < closest) then
					closest = dist
					wp = k
				end
			end
		else
			dist = distancexyz(x, y, z, v.x, v.y, v.z)

			if (dist < closest) then
				closest = dist
				wp = k
			end
		end
	end

	return wp
end


function LookupHotspot(x,y,z)
	-- return the closest hotspot that these coords are inside
	local size, k, v

	for k, v in pairs(hotspots) do
		if (v.radius ~= nil) then
			size = v.radius
		else
			size = 3
		end

		if distancexyz(x, y, z, v.x, v.y, v.z) <= tonumber(size) then
			return k
		end
	end
end


function ClosestHotspot(x, y, z)
	-- what is the closest hotspot to this 3D coord?
	local closest = 1000
	local dist = 2000
	local spot = 0
	local k,v, dist

	for k, v in pairs(hotspots) do
		dist = distancexyz(x, y, z, v.x, v.y, v.z)

		if (dist < closest) then
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

	if(not T) then return nil end

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


function getRegionChunkXZ(xpos,zpos)
	-- calc the region XZ and chunk XZ from the coords.
	local rx, rz, cx, cz

	rx = math.floor(tonumber(xpos) / 512)
	rz = math.floor(tonumber(zpos) / 512)

	cx = math.floor(tonumber(xpos) / 16)
	cz = math.floor(tonumber(zpos) / 16)

	return rx, rz, cx, cz
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
	if(not pid) then
		return 99
	end

	-- determine the access level of the player

	if debug then dbug("accesslevel pid " .. pid) end

	if(pid == 0) then
		-- no pid?  return the worst possible access level.
		return 99
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	if owners[pid] then
		players[pid].accessLevel = 0
		return 0
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	if admins[pid] then
		players[pid].accessLevel = 1
		return 1
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	if mods[pid] then
		players[pid].accessLevel = 2
		return 2
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	if tonumber(server.accessLevelOverride) < 99 then
		return tonumber(server.accessLevelOverride)
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	-- 3 is reserved for visiting admins

	if(not players[pid]) then 
		if(debug) then 
			dbugFull("D", "", debugger.getinfo(1,"nSl"), "Accesslevel " .. pid .. " not found in players")
		end

		return 99
	end

	if players[pid].donor == true then
--TODO: Add donor levels
		players[pid].accessLevel = 10
		return 10
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	-- anyone stripped of certain rights
	if players[pid].denyRights == true then
		players[pid].accessLevel = 99
		return 99
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

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

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	-- new players
	players[pid].accessLevel = 99
	return 99
end


function fixMissingPlayer(steam)
	-- if any fields are missing from the players player record, add them with default values

	if(debug) then 
		dbugFull("D", debugger.traceback(),debugger.getinfo(1,"nSl"), steam .. " " .. players[steam].name) 
	end

	local k,v

	if(not players[steam]) then
		players[steam] = {}
		players[steam].steam = steam
	end

	for k,v in pairs(playerFields) do
		if players[steam][k] == nil then
			if v.default ~= "nil" then
				if v.type == "tin" then
					if v.default == "0" then
						players[steam][k] = false
					else
						players[steam][k] = true
					end
				else
					if v.default == "CURRENT_TIMESTAMP" then
						players[steam][k] = os.time()
					else
						players[steam][k] = v.default
					end
				end
			end
		end
	end

        if (players[steam].sessionPlaytime == nil) then
                players[steam].sessionPlaytime = 0
        end

	if(players[steam].deathZ == nil) then
		players[steam].deathZ = 0
	end

	if(players[steam].ircAlias == nil) then
		players[steam].ircAlias = players[steam].name
	end

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
		players[steam].level = 0
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

	if (players[steam].waypoint2X == nil) then
		players[steam].waypoint2X = 0
		players[steam].waypoint2Y = 0
		players[steam].waypoint2Z = 0
		players[steam].waypointsLinked = false
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
		players[steam].watchPlayer = true
	end

	if (players[steam].sessionCount == nil) then
		players[steam].sessionCount = 1
	end

	if (players[steam].watchPlayer == nil) then
		players[steam].watchPlayer = false
	end

	if (players[steam].watchPlayerTimer == nil) then
		if players[steam].watchPlayer then
			players[steam].watchPlayerTimer = os.time() + 259200 -- 3 days
		else
			players[steam].watchPlayerTimer = 0
		end
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
	end

	if players[steam].lastCommandTimestamp == nil then
		players[steam].lastCommandTimestamp = os.time() -1
	end

	if players[steam].lastChatLine == nil then
		players[steam].lastChatLine = ""
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

	if players[steam].hackerTPScore == nil then
		players[steam].hackerTPScore = 0
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

	if players[steam].location == nil then
		players[steam].location = ""
	end

	if players[steam].GBLCount == nil then
		players[steam].GBLCount = 0
	end

	if players[steam].commandCooldown == nil then
		players[steam].commandCooldown = 0
	end

	if players[steam].pendingBans == nil then
		players[steam].pendingBans = 0
	end

--	dbug("finished fixMissingPlayer")
end


function fixMissingIGPlayer(steam)
	-- if any fields are missing from the players in-game player record, add them with default values

        if(debug) then
                dbugFull("D", debugger.traceback(),debugger.getinfo(1,"nSl"), steam .. " " .. igplayers[steam].name)
        end


	if(not igplayers[steam]) then
		if(debug) then
			 dbugFull("D", "", debugger.getinfo(1,"nSl"), "Unable to fix playerid " .. steam .. " they are not in the igplayers table!")
		end
		return
	end

        if (igplayers[steam].deaths == nil) then
                igplayers[steam].deaths = 0
        end

	if(igplayers[steam].deathZ == nil) then
		igplayers[steam].deathZ = 0
	end

        if players[steam].playerKills == nil then
                players[steam].playerKills = 0
        end

	if (igplayers[steam].claimPass == nil) then
		igplayers[steam].claimPass = 0
	end

	if (igplayers[steam].checkNewPlayer == nil) then
		igplayers[steam].checkNewPlayer = true
	end

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
		igplayers[steam].teleCooldown = 200
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
		igplayers[steam].ping = 0
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

		igplayers[steam].xPosLastAlert = 0
		igplayers[steam].yPosLastAlert = 0
		igplayers[steam].zPosLastAlert = 0
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
		igplayers[steam].flyingX = 0
		igplayers[steam].flyingZ = 0
	end

	if igplayers[steam].noclip == nil then
		igplayers[steam].noclip = false
		igplayers[steam].noclipX = 0
		igplayers[steam].noclipZ = 0
	end

	if igplayers[steam].reservedSlot == nil then
		igplayers[steam].reservedSlot = false
	end

	if igplayers[steam].rawRotation == nil then
		igplayers[steam].rawRotation = 0
	end

	if igplayers[steam].rawPosition == nil then
		igplayers[steam].rawPosition = 0
	end
end


function fixMissingServer()
	local k,v

	for k,v in pairs(serverFields) do
		if server[k] == nil then
			if v.default ~= "nil" then
				if v.type == "tin" then
					if v.default == "0" then
						server[k] = false
					else
						server[k] = true
					end
				else
					server[k] = v.default
				end
			end
		end
	end
end


function dumpPlayers(dumpTable)
	local k, v, tLabel
	local count = 0

	if(dumpTable == players) then
		tLabel = "Players"
	else
		tLabel = "IGPlayers"
	end

	cecho("\n                                     " .. tLabel .. " Table Dump\n")
	cecho("------------------------------------------------------------------------------------------------\n")

	for k, v in pairs(dumpTable) do
		count = count + 1
	
		if(v.name and v.steam and v.id) then
			echo(string.format("%3d. %-26s id=%6d Steam=", count, v.name, v.id))
			echoLink(v.steam,  "openUrl(\"http://steamcommunity.com/profiles/" .. v.steam .. "\")", "Click to view players Steam profile.")
			if(dumpTable == igplayers) then
				local PVP="PvE"
				local S =  os.time() - v.firstSeen
				local H, M

				if(S >= 3600) then
					H = math.floor(S/3600)

					S = S - (H * 3600)
				else
					H = 0
				end

				if(S >= 60) then
					M = math.floor(S/60)
					S = S - (M * 60)
				else
					M = 0
				end

				if(v.currentLocationPVP) then
					PVP="PvP"
				end

				
				echo(" Online for: " .. string.format("%02d:%02d:%02d", H, M, S) .. " - " .. PVP .. " A" .. (players[v.steam].accessLevel or 99) .. "\n")
			else 
				if(banList[v.steam]) then
					echo(" BANNED")
				end
				echo("\n")
			end
		else 
			if(v.steam ~= 0) then
				echo("skipping incomplete player: " .. k .. "\n")
			end
		end

	end

	echo("\n")
end

function getRestartOffset()
	local time = os.time()
	local tmpArray = os.date("*t", time)
	local jmpForward

	if(server.maxServerUptime == nil) then
		dbugFull("E", "", debugger.getinfo(1, "nSl"), "Fixing server.maxServerUptime = nil")
		server.maxServerUptime = 48
	end

	if(server.maxServerUptime <= 24) then
		dbugFull("E", "", debugger.getinfo(1, "nSl"), "Fixing server.maxServerUptime = " .. server.maxServerUptime)
		server.maxServerUptime = 48
	end

	jmpForward = server.maxServerUptime * 3600

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "jmpForward = " .. jmpForward) end

	if(tmpArray.hour >= 18) then
		jmpForward = jmpForward + 86400
	end

        tmpArray = os.date("*t",  time + jmpForward)  

        tmpArray.hour = 3
        tmpArray.min = 0
	tmpArray.sec = 0

	return os.time(tmpArray)
end


function showNextRestart()
	local standardRestart = getRestartOffset()
	local nextRestart = botman.scheduledRestartTimestamp

	if(standardRestart ~= nextRestart) then
		cecho("Standard Restart would be @: " .. os.date("%c", standardRestart) .. "\n")
		cecho("But the next restart will be @: " .. os.date("%c", nextRestart) .. "\n")
	else
		cecho("Next Restart will be @: " .. os.date("%c", nextRestart) .. "\n")
	end
end

function resetRestart()
	botman.scheduledRestartTimestamp = getRestartOffset()
	botman.scheduledRestart = false
        botman.scheduledRestartPaused = false
        botman.scheduledRestartForced = false
end
