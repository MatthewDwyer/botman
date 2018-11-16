--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function sendCommand(command, api, outputFile)
	-- send the command to the server via Allocs web API if enabled otherwise use telnet

	-- any commands that must be sent via telnet, trap and send them first.
	-- if command == "pm IPCHECK" then
		-- send(command)
		-- return
	-- end

	--display("sent " .. command)

	botman.lastBotCommand = command

	if server.useAllocsWebAPI and not string.find(command, "webtokens ") and not string.find(command, "#") then
		-- fix missing api and outputFile for some commands
		if api == nil or api == "" then
			if command == "admin list" then
				api = "executeconsolecommand?command=admin list&"
				outputFile = "adminList.txt"
			end

			if command == "ban list" then
				api = "executeconsolecommand?command=ban list&"
				outputFile = "banList.txt"
			end

			if command == "bc-go prefabs" then -- this is used to read server ticks and grab the players online.
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "bc-go.txt"
			end

			if command == "bc-time" then -- this is used to read server ticks and grab the players online.
				api = "executeconsolecommand?command=bc-time&"
				outputFile = "time.txt"
			end

			if command == "gg" then
				api = "executeconsolecommand?command=gg&"
				outputFile = "gg.txt"
			end

			if string.sub(command, 1, 4) == "help" then
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "help.txt"
			end

			if command == "le" then
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "le.txt"
			end

			if string.sub(command, 1, 3) == "li " then
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "li.txt"
			end

			if string.find(command, "lkp") then
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "lkp.txt"
			end

			if string.find(command, "llp") then
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "llp.txt"
			end

			if command == "lp" then
				api = "getplayersonline/?"
				outputFile = "playersOnline.txt"
			end

			if string.find(command, "lpb") then
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "lpb.txt"
			end

			if string.find(command, "lpf") then
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "lpf.txt"
			end

			if command == "mem" then -- this is used to read server time, grab the players online and some performance metrics.
				api = "executeconsolecommand?command=mem&"
				outputFile = "mem.txt"
			end

			if string.find(command, "pgd") then
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "pgd.txt"
			end

			if string.find(command, "pug") then
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "pug.txt"
			end

			if string.sub(command, 1,3) == "se " or command == "se" then
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "se.txt"
			end

			if command == "version" then
				api = "executeconsolecommand?command=version&"
				outputFile = "installedMods.txt"
			end

			-- this must be last.  It is a catch-all for anything not matched above.
			if api == nil then
				api = "executeconsolecommand?command=" .. command .. "&"
				outputFile = "command.txt"
			end
		end

		url = "http://" .. server.IP .. ":" .. server.webPanelPort + 2 .. "/api/" .. api .. "adminuser=" .. server.allocsWebAPIUser .. "&admintoken=" .. server.allocsWebAPIPassword

		if outputFile == nil then
			outputFile = "dummy.txt"
		end

		os.remove(homedir .. "/temp/" .. outputFile)

		if server.logBotCommands then
			logBotCommand(botman.serverTime, url)
		end

		downloadFile(homedir .. "/temp/" .. outputFile, url)

		-- should be able to remove list later.  Just put it here to fix an issue with older bots updating and not having the metrics table.
		if type(metrics) ~= "table" then
			metrics = {}
			metrics.commands = 0
			metrics.commandLag = 0
			metrics.errors = 0
			metrics.telnetLines = 0
		end

		metrics.commands = metrics.commands + 1
	else
		if server.logBotCommands then
			logBotCommand(botman.serverTime, command)
		end

		-- should be able to remove list later.  Just put it here to fix an issue with older bots updating and not having the metrics table.
		if type(metrics) ~= "table" then
			metrics = {}
			metrics.commands = 0
			metrics.commandLag = 0
			metrics.errors = 0
			metrics.telnetLines = 0
		end

		send(command)
		metrics.commands = metrics.commands + 1
	end
end


function trueFalse(value)
	-- translate Lua true false to its string version
	if value == false then
		return "false"
	else
		return "true"
	end
end


function alertAdmins(msg, alert)
	-- pm all in-game admins with msg
	local k, v, msgColour

	if type(server) == "table" then
		msgColour = server.chatColour
		if alert == "alert" then msgColour = server.alertColour end
		if alert == "warn" then msgColour = server.warnColour end
	else
		msgColour = "D4FFD4"
	end

	for k, v in pairs(igplayers) do
		if (accessLevel(k) < 3) then
			message("pm " .. k .. " [" .. msgColour .. "]" .. msg .. "[-]")
		end
	end
end


function splitCRLF(value)
	local splitter = "\r\n"

	if value == true or value == false then
		return value
	end

	if not string.find(value, "\r\n") then
		splitter = "\n"
	end

	return string.split(value, splitter)
end


function stripMatching(value, search)
	if value == true or value == false then
		return value
	end

	value = string.trim(value)
	value = string.gsub(value, search, "")
	return value
end


function stripCommas(value)
	if value == true or value == false then
		return value
	end

	value = string.trim(value)
	value = string.gsub(value, ",", "")
	return value
end


function stripBBCodes(text)
	local oldText

	text = string.trim(text)
	oldText = text


	text = string.gsub(text, "%[[%/%!]-[^%[%]]-]", "")
	--text = string.match(text, "^[(.*)]$")

	if text == nil then
		text = oldtext
	end

	return text
end


function stripAngleBrackets(text)
	local oldText

	text = string.trim(text)
	oldText = text

	text = string.match(text, "^<(.*)>$")

	if text == nil then
		text = oldtext
	end

	return text
end


function stripQuotes(name)
	local oldName

	name = string.trim(name)
	oldName = name

	name = string.match(name, "^'(.*)'$")

	if name == nil then
		name = oldName
	else
		return name
	end

	name = string.match(name, "^\"(.*)\"$")

	if name == nil then name = oldName end

	if string.sub(name, string.len(name)) == "'" then
		name = string.sub(name, 1, string.len(name) - 1)
	end

	return name
end


function stripAllQuotes(name)
	name = string.gsub(name, "'", "")
	name = string.gsub(name, "\"", "")

	return name
end


function exists(name)
    if type(name)~="string" then return false end
    return os.rename(name,name) and true or false
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

	if testid == steamid then -- self
		return true -- I hope you are friends with yourself! (sorry if not)
	end

	if string.find(friends[testid].friends, steamid) then
		-- found steamid in testid's friends list.
		return true
	end

	-- steamid is not a friend of testid
	return false
end


function message(msg, steam)
	-- parse msg and enclose the actual message in double quotes
	local words, word, skip, url, k, v

	msg = msg:gsub("{#}", server.commandPrefix)

	if steam then
		msg = msg:gsub("{player}", players[steam].name)
	end

	msg = msg:gsub("{server}", server.serverName)
	msg = msg:gsub("{money}", server.moneyName)
	msg = msg:gsub("{monies}", server.moneyPlural)

	-- break the chat line into words
	words = {}
	for word in msg:gmatch("%S+") do
		table.insert(words, word)
	end

	if string.sub(msg, 1, 4) == "say " then
		-- say the message in public chat
		if server.useAllocsWebAPI then
			if not server.allocs then
				-- Alloc's mod is missing or not detected
				msg = string.sub(msg, 5)
				url = "http://" .. server.IP .. ":" .. server.webPanelPort + 2 .. "/api/executeconsolecommand/?command=say \"" .. msg .. "\"&adminuser=" .. server.allocsWebAPIUser .. "&admintoken=" .. server.allocsWebAPIPassword

				if botman.dbConnected then
					conn:execute("INSERT into APIQueue (URL, outputFile) VALUES ('" .. escape(url) .. "','" .. escape(homedir .. "/temp/dummy.txt") .. "')")
				end
			else
				-- Alloc's mod is installed so send all public messages as individual PM's
				msg = string.sub(msg, 5)
				irc_chat(server.ircMain, stripBBCodes(msg))

				for k,v in pairs(igplayers) do
					url = "http://" .. server.IP .. ":" .. server.webPanelPort + 2 .. "/api/executeconsolecommand/?command=pm " .. k .. " \"" .. msg .. "\"&adminuser=" .. server.allocsWebAPIUser .. "&admintoken=" .. server.allocsWebAPIPassword

					if botman.dbConnected then
						conn:execute("INSERT into APIQueue (URL, outputFile) VALUES ('" .. escape(url) .. "','" .. escape(homedir .. "/temp/dummy.txt") .. "')")
					end
				end
			end
		else
			if not server.allocs then
				-- Alloc's mod is missing or not detected
				msg = "say \"" .. string.sub(msg, 5) .. "\""
				send(msg)

				if server.logBotCommands then
					logBotCommand(botman.serverTime, msg)
				end

				metrics.commands = metrics.commands + 1
			else
				-- Alloc's mod is installed so send all public messages as individual PM's
				irc_chat(server.ircMain, stripBBCodes(string.sub(msg, 5)))
				msg = "\"" .. string.sub(msg, 5) .. "\""


				for k,v in pairs(igplayers) do
					send("pm " .. k .. " " .. msg)

					if server.logBotCommands then
						logBotCommand(botman.serverTime, msg)
					end

					metrics.commands = metrics.commands + 1
				end
			end
		end
	else
		if players[words[2]] then
			if players[words[2]].exiled ~= 1 then
				if server.useAllocsWebAPI then
					msg = string.sub(msg, 22)
					url = "http://" .. server.IP .. ":" .. server.webPanelPort + 2 .. "/api/executeconsolecommand/?command=pm " .. words[2] .. " \"" .. msg .. "\"&adminuser=" .. server.allocsWebAPIUser .. "&admintoken=" .. server.allocsWebAPIPassword

					if botman.dbConnected then
						conn:execute("INSERT into APIQueue (URL, outputFile) VALUES ('" .. escape(url) .. "','" .. escape(homedir .. "/temp/dummy.txt") .. "')")
					end
				else
					msg = "pm " .. words[2] .. " \"" .. string.sub(msg, 22) .. "\""
					send(msg)

					if server.logBotCommands then
						logBotCommand(botman.serverTime, msg)
					end

					metrics.commands = metrics.commands + 1
				end
			end
		else
			if server.useAllocsWebAPI then
				msg = string.sub(msg, 22)
				url = "http://" .. server.IP .. ":" .. server.webPanelPort + 2 .. "/api/executeconsolecommand/?command=pm " .. words[2] .. " \"" .. msg .. "\"&adminuser=" .. server.allocsWebAPIUser .. "&admintoken=" .. server.allocsWebAPIPassword

				if botman.dbConnected then
					conn:execute("INSERT into APIQueue (URL, outputFile) VALUES ('" .. escape(url) .. "','" .. escape(homedir .. "/temp/dummy.txt") .. "')")
				end
			else
				msg = "pm " .. words[2] .. " \"" .. string.sub(msg, 22) .. "\""
				send(msg)

				if server.logBotCommands then
					logBotCommand(botman.serverTime, msg)
				end

				metrics.commands = metrics.commands + 1
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


function pickRandomArenaPlayer()
	local k, v, r, i

	-- abort to prevent an infinite loop
	if tonumber(botman.arenaCount) == 0 then
		return 0
	end

	i = 1
	r = tonumber(rand(botman.arenaCount))

	for k, v in pairs(arenaPlayers) do
		if r == i then
			return k
		else
			i = i + 1
		end
	end

	return 0 -- return something
end


function dbLookupPlayer(search, match)
	-- cursor,errorString = conn:execute("SELECT id, steam, name FROM players")

	-- row = cursor:fetch({}, "a")
	-- while row do
		-- if row.timer == "announcements" then
			-- conn:execute("UPDATE timedEvents SET nextTime = NOW() + INTERVAL " .. row.delayMinutes .. " MINUTE WHERE timer = 'announcements'")
			-- sendNextAnnouncement()
		-- end

		-- row = cursor:fetch(row, "a")
	-- end
end


function LookupPlayer(search, match)
	-- try to find the player amoung those who are playing right now
	local steam, owner, k, v, test

	if string.trim(search) == "" then
		return 0, 0
	end

	-- if the search is a steam ID, don't bother walking through the list of in game players, just check that it is a member of the lua table igplayers
	if string.len(search) == 17 then
		test = tonumber(search)
		if (test ~= nil) then
			if igplayers[test] then
				return test
			end
		end
	end

	search = string.lower(search)

	if string.starts(search, "\"") and string.ends(search,"\"") then
		search = search:match("%w+")
		match = "all"
	end

	for k, v in pairs(igplayers) do
		if match == "code" then
			if tonumber(search) == tonumber(players[k].ircInvite) then
				return k, v.steamOwner
			end
		else
			if search == v.id then
				-- matched the player id
				return k, v.steamOwner
			end

			if k == search or v.steamOwner == search then
				-- matched the steam id or steamOwner id
				return k, v.steamOwner
			end

			if (v.name ~= nil) then
				if match == "all" then
					-- look for an exact match
					if (search == string.lower(v.name)) then
						return k, v.steamOwner
					end

					if (v.ircAlias ~= nil) and (search == string.lower(v.ircAlias)) then
						return k, v.steamOwner
					end
				else
					-- if it contains the search it is a match
					if (search == string.lower(v.name)) or (string.find(string.lower(v.name), search, nil, true)) then
						return k, v.steamOwner
					end

					if (string.find(v.id, search)) then
						return k, v.steamOwner
					end
				end
			end
		end
	end

	-- no matches so try again but including all players
	steam, owner = LookupOfflinePlayer(search, match)

	-- if steam isn't 0 we found a match
	return steam, owner
end


function LookupOfflinePlayer(search, match)
	local k, v, test

	if string.trim(search) == "" then
		return 0, 0
	end

	-- if the search is a steam ID, don't bother walking through the list of players, just check that it is a member of the lua table players
	if string.len(search) == 17 then
		test = tonumber(search)
		if (test ~= nil) then
			if players[test] then
				return test, players[test].steamOwner
			end
		end
	end

	search = string.lower(search)

	if string.starts(search, "\"") and string.ends(search,"\"") then
		search = search:match("%w+")
		match = "all"
	end

	for k, v in pairs(players) do
		if match == "code" then
			if tonumber(search) == tonumber(players[k].ircInvite) then
				return k, v.steamOwner
			end
		else
			if (v.name ~= nil) then
				if match == "all" then
					if (search == string.lower(v.name)) then
						return k, v.steamOwner
					end

					if (v.ircAlias ~= nil) and (search == string.lower(v.ircAlias)) then
						return k, v.steamOwner
					end
				else
					if (search == string.lower(v.name)) or (string.find(string.lower(v.name), search, nil, true)) then
						return k, v.steamOwner
					end
				end
			end

			if search == v.id then
				return k, v.steamOwner
			end

			if k == search or v.steamOwner == search then
				return k, v.steamOwner
			end
		end
	end

	-- got to here so no match found
	return 0, 0
end


function LookupArchivedPlayer(search, match)
	local k, v, test

	if string.trim(search) == "" then
		return 0, 0
	end

	-- if the search is a steam ID, don't bother walking through the list of players, just check that it is a member of the lua table playersArchived
	if string.len(search) == 17 then
		test = tonumber(search)
		if (test ~= nil) then
			if playersArchived[test] then
				return test
			end
		end
	end

	search = string.lower(search)

	if string.starts(search, "\"") and string.ends(search,"\"") then
		search = search:match("%w+")
		match = "all"
	end

	for k, v in pairs(playersArchived) do
		if match == "code" then
			if tonumber(search) == tonumber(playersArchived[k].ircInvite) then
				return k, v.steamOwner
			end
		else
			if (v.name ~= nil) then
				if match == "all" then
					if (search == string.lower(v.name)) then
						return k, v.steamOwner
					end

					if (v.ircAlias ~= nil) and (search == string.lower(v.ircAlias)) then
						return k, v.steamOwner
					end
				else
					if (search == string.lower(v.name)) or (string.find(string.lower(v.name), search, nil, true)) then
						return k, v.steamOwner
					end
				end
			end

			if search == v.id then
				return k, v.steamOwner
			end

			if k == search or v.steamOwner == search then
				return k, v.steamOwner
			end
		end
	end

	-- got to here so no match found
	return 0, 0
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
	else
		return 0
	end
end


function LookupIRCPass(login, pass)
	local k,v

	if string.trim(pass) == "" then
		return 0
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
		if distancexyz( x, y, z, v.x, v.y, v.z ) < tonumber(v.size) then
			if v.active then
				match = 1
				return k, match
			end
		end

		if(v.dx) then
			if distancexyz( x, y, z, v.dx, v.dy, v.dz ) < tonumber(v.dsize) then
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
			-- don't return the hotspot if the player has been archived (staff are never archived)

			if players[v.owner] then
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
	sendCommand(message)
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
	local debug

	debug = false

	-- determine the access level of the player

	if debug then dbug("accesslevel pid " .. pid) end

	if pid == 0 then
		-- no pid?  return the worst possible access level. That'll show em!
		return 99
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	if owners[pid] then
		if players[pid] then
			players[pid].accessLevel = 0
		end

		return 0
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	if admins[pid] then
		if players[pid] then
			players[pid].accessLevel = 1
		end

		return 1
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	if mods[pid] then
		if players[pid] then
			players[pid].accessLevel = 2
		end

		return 2
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	if tonumber(server.accessLevelOverride) < 99 and players[pid] then
		return tonumber(server.accessLevelOverride)
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	-- anyone stripped of certain rights
	if players[pid] then
		if players[pid].denyRights == true then
			players[pid].accessLevel = 99
			return 99
		end

		if players[pid].donor then
	--TODO: Add donor levels
			players[pid].accessLevel = 10
			return 10
		end
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	-- regulars
	if igplayers[pid] then
		if tonumber(players[pid].timeOnServer) + tonumber(igplayers[pid].sessionPlaytime) > (server.newPlayerTimer * 60) then
			players[pid].accessLevel = 90
			return 90
		end
	else
		if players[pid] then
			if tonumber(players[pid].timeOnServer) > (server.newPlayerTimer * 60) then
				players[pid].accessLevel = 90
				return 90
			end
		end
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	-- new players
	if players[pid] then
		players[pid].accessLevel = 99
	end

	return 99
end


function fixMissingPlayer(steam)
	-- if any fields are missing from the players player record, add them with default values
	local k,v

	if players[steam] == nil then
		players[steam] = {}
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
			else
				if v.type == "var" then
					players[steam][k] = ""
				end

				if v.type == "big" or v.type == "int" then
					players[steam][k] = 0
				end
			end
		end
	end

	-- do not remove these lines !!
	-- ============================

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

	if (players[steam].alertMapLimit == nil) then
		players[steam].alertMapLimit = false
	end

	if (players[steam].alertPrison == nil) then
		players[steam].alertPrison = true
	end

	if (players[steam].alertPVP == nil) then
		players[steam].alertPVP = true
	end

	if (players[steam].alertRemovedClaims == nil) then
		players[steam].alertRemovedClaims = false
	end

	if (players[steam].alertReset == nil) then
		players[steam].alertReset = true
	end

	if players[steam].aliases == nil then
		players[steam].aliases = players[steam].name
	end

	if players[steam].atHome == nil then
		players[steam].atHome = false
	end

	if players[steam].bed == nil then
		players[steam].bed = ""
	end

	if (players[steam].block == nil) then
		players[steam].block = false
	end

	if (players[steam].botQuestion == nil) then
		players[steam].botQuestion = ""
	end

	if (players[steam].bountyReason == nil) then
		players[steam].bountyReason = ""
	end

	if players[steam].commandCooldown == nil then
		players[steam].commandCooldown = 0
	end

	if players[steam].country == nil then
		players[steam].country = ""
	end

	if players[steam].deaths == nil then
		players[steam].deaths = 0
	end

	if players[steam].denyRights == nil then
		players[steam].denyRights = false
	end

	if players[steam].DNSLookupCount == nil then
		players[steam].DNSLookupCount = 0
	end

	if players[steam].exiled == nil then
		players[steam].exiled = 0
	end

	if players[steam].exit2X == 0 and players[steam].exit2Z == 0 then
		players[steam].exit2Y = 0
	end

	if players[steam].exitX == 0 and players[steam].exitZ == 0 then
		players[steam].exitY = 0
	end

	if players[steam].GBLCount == nil then
		players[steam].GBLCount = 0
	end

	if players[steam].gimmeCooldown == nil then
		players[steam].gimmeCooldown = 0
	end

	if players[steam].gimmeCount == nil then
		players[steam].gimmeCount = 0
	end

	if players[steam].home2X == 0 and players[steam].home2Z == 0 then
		players[steam].home2Y = 0
	end

	if players[steam].homeX == 0 and players[steam].homeZ == 0 then
		players[steam].homeY = 0
	end

	if players[steam].inLocation == nil then
		players[steam].inLocation = ""
	end

	if players[steam].ip == nil then
		players[steam].ip = ""
	end

	if players[steam].ircAlias == nil then
		players[steam].ircAlias = ""
	end

	if players[steam].ircAuthenticated == nil then
		players[steam].ircAuthenticated = false
	end

	if players[steam].ircPass == nil then
		players[steam].ircPass = ""
	end

	if players[steam].ircOtherNames == nil then
		players[steam].ircOtherNames = ""
	end

	if players[steam].ISP == nil then
		players[steam].ISP = ""
	end

	if (players[steam].lastBaseRaid == nil) then
		players[steam].lastBaseRaid = 0
	end

	if players[steam].lastChatLine == nil then
		players[steam].lastChatLine = ""
	end

	if players[steam].lastCommand == nil then
		players[steam].lastCommand = ""
	end

	if players[steam].lastCommandTimestamp == nil then
		players[steam].lastCommandTimestamp = os.time() -1
	end

	if players[steam].lastDNSLookup == nil then
		players[steam].lastDNSLookup = "1000-01-01"
	end

	if players[steam].lastLogout == nil then
		players[steam].lastLogout = os.time()
		players[steam].relogCount = 0
	end

	if players[steam].notInLKP == nil then
		players[steam].notInLKP = false
	end

	if players[steam].overstackItems == nil then
		players[steam].overstackItems = ""
	end

	if players[steam].overstackScore == nil then
		players[steam].overstackScore = 0
	end

	if players[steam].packCooldown == nil then
		players[steam].packCooldown = 0
	end

	if players[steam].pendingBans == nil then
		players[steam].pendingBans = 0
	end

	if players[steam].prisonReason == nil then
		players[steam].prisonReason = ""
	end

	if (players[steam].protect2Size == nil) then
		players[steam].protect2Size = server.baseSize
	else
		if tonumber(players[steam].protect2Size) < tonumber(server.baseSize) then
			players[steam].protect2Size = server.baseSize
		end
	end

	if (players[steam].protectSize == nil) then
		players[steam].protectSize = server.baseSize
	else
		if tonumber(players[steam].protectSize) < tonumber(server.baseSize) then
			players[steam].protectSize = server.baseSize
		end
	end

	if players[steam].pvpTeleportCooldown == nil then
		players[steam].pvpTeleportCooldown = 0
	end

	if (players[steam].raiding == nil) then
		players[steam].raiding = false
	end

	if (players[steam].removeClaims == nil) then
		players[steam].removeClaims = false
	end

	if players[steam].returnCooldown == nil then
		players[steam].returnCooldown = 0
	end

	if players[steam].seen == nil then
		players[steam].seen = ""
	end

	if (players[steam].steamOwner == nil) then
		players[steam].steamOwner = steam
	end

	if (players[steam].watchPlayerTimer == nil) then
		if players[steam].watchPlayer then
			players[steam].watchPlayerTimer = os.time() + server.defaultWatchTimer
		else
			players[steam].watchPlayerTimer = 0
		end
	end

	if players[steam].waypointCooldown == nil then
		players[steam].waypointCooldown = 0
	end

	if players[steam].VACBanned == nil then
		players[steam].VACBanned = false
	end
end


function fixMissingArchivedPlayer(steam)
	-- if any fields are missing from the players player record, add them with default values
	local k,v

	if playersArchived[steam] == nil then
		playersArchived[steam] = {}
	end

	for k,v in pairs(playerFields) do
		if playersArchived[steam][k] == nil then
			if v.default ~= "nil" then
				if v.type == "tin" then
					if v.default == "0" then
						playersArchived[steam][k] = false
					else
						playersArchived[steam][k] = true
					end
				else
					if v.default == "CURRENT_TIMESTAMP" then
						playersArchived[steam][k] = os.time()
					else
						playersArchived[steam][k] = v.default
					end
				end
			else
				if v.type == "var" then
					playersArchived[steam][k] = ""
				end

				if v.type == "big" or v.type == "int" then
					playersArchived[steam][k] = 0
				end
			end
		end
	end

	-- do not remove these lines !!
	-- ============================

	if (playersArchived[steam].alertMapLimit == nil) then
		playersArchived[steam].alertMapLimit = false
	end

	if (playersArchived[steam].alertPrison == nil) then
		playersArchived[steam].alertPrison = true
	end

	if (playersArchived[steam].alertPVP == nil) then
		playersArchived[steam].alertPVP = true
	end

	if (playersArchived[steam].alertRemovedClaims == nil) then
		playersArchived[steam].alertRemovedClaims = false
	end

	if (playersArchived[steam].alertReset == nil) then
		playersArchived[steam].alertReset = true
	end

	if playersArchived[steam].aliases == nil then
		playersArchived[steam].aliases = playersArchived[steam].name
	end

	if playersArchived[steam].atHome == nil then
		playersArchived[steam].atHome = false
	end

	if playersArchived[steam].bed == nil then
		playersArchived[steam].bed = ""
	end

	if (playersArchived[steam].block == nil) then
		playersArchived[steam].block = false
	end

	if (playersArchived[steam].botQuestion == nil) then
		playersArchived[steam].botQuestion = ""
	end

	if (playersArchived[steam].bountyReason == nil) then
		playersArchived[steam].bountyReason = ""
	end

	if playersArchived[steam].commandCooldown == nil then
		playersArchived[steam].commandCooldown = 0
	end

	if playersArchived[steam].country == nil then
		playersArchived[steam].country = ""
	end

	if playersArchived[steam].exit2X == 0 and playersArchived[steam].exit2Z == 0 then
		playersArchived[steam].exit2Y = 0
	end

	if playersArchived[steam].exitX == 0 and playersArchived[steam].exitZ == 0 then
		playersArchived[steam].exitY = 0
	end

	if playersArchived[steam].GBLCount == nil then
		playersArchived[steam].GBLCount = 0
	end

	if playersArchived[steam].gimmeCooldown == nil then
		playersArchived[steam].gimmeCooldown = 0
	end

	if playersArchived[steam].home2X == 0 and playersArchived[steam].home2Z == 0 then
		playersArchived[steam].home2Y = 0
	end

	if playersArchived[steam].homeX == 0 and playersArchived[steam].homeZ == 0 then
		playersArchived[steam].homeY = 0
	end

	if playersArchived[steam].ip == nil then
		playersArchived[steam].ip = ""
	end

	if playersArchived[steam].ircAlias == nil then
		playersArchived[steam].ircAlias = ""
	end

	if playersArchived[steam].ircAuthenticated == nil then
		playersArchived[steam].ircAuthenticated = false
	end

	if playersArchived[steam].ircPass == nil then
		playersArchived[steam].ircPass = ""
	end

	if playersArchived[steam].ircOtherNames == nil then
		playersArchived[steam].ircOtherNames = ""
	end

	if playersArchived[steam].ISP == nil then
		playersArchived[steam].ISP = ""
	end

	if (playersArchived[steam].lastBaseRaid == nil) then
		playersArchived[steam].lastBaseRaid = 0
	end

	if playersArchived[steam].lastChatLine == nil then
		playersArchived[steam].lastChatLine = ""
	end

	if playersArchived[steam].lastCommand == nil then
		playersArchived[steam].lastCommand = ""
	end

	if playersArchived[steam].lastCommandTimestamp == nil then
		playersArchived[steam].lastCommandTimestamp = os.time() -1
	end

	if playersArchived[steam].lastLogout == nil then
		playersArchived[steam].lastLogout = os.time()
		playersArchived[steam].relogCount = 0
	end

	if playersArchived[steam].overstackItems == nil then
		playersArchived[steam].overstackItems = ""
	end

	if playersArchived[steam].overstackScore == nil then
		playersArchived[steam].overstackScore = 0
	end

	if playersArchived[steam].packCooldown == nil then
		playersArchived[steam].packCooldown = 0
	end

	if playersArchived[steam].pendingBans == nil then
		playersArchived[steam].pendingBans = 0
	end

	if playersArchived[steam].prisonReason == nil then
		playersArchived[steam].prisonReason = ""
	end

	if (playersArchived[steam].protect2Size == nil) then
		playersArchived[steam].protect2Size = server.baseSize
	else
		if tonumber(playersArchived[steam].protect2Size) < tonumber(server.baseSize) then
			playersArchived[steam].protect2Size = server.baseSize
		end
	end

	if (playersArchived[steam].protectSize == nil) then
		playersArchived[steam].protectSize = server.baseSize
	else
		if tonumber(playersArchived[steam].protectSize) < tonumber(server.baseSize) then
			playersArchived[steam].protectSize = server.baseSize
		end
	end

	if playersArchived[steam].pvpTeleportCooldown == nil then
		playersArchived[steam].pvpTeleportCooldown = 0
	end

	if (playersArchived[steam].raiding == nil) then
		playersArchived[steam].raiding = false
	end

	if (playersArchived[steam].removeClaims == nil) then
		playersArchived[steam].removeClaims = false
	end

	if playersArchived[steam].returnCooldown == nil then
		playersArchived[steam].returnCooldown = 0
	end

	if playersArchived[steam].seen == nil then
		playersArchived[steam].seen = ""
	end

	if (playersArchived[steam].steamOwner == nil) then
		playersArchived[steam].steamOwner = steam
	end

	if (playersArchived[steam].watchPlayerTimer == nil) then
		if playersArchived[steam].watchPlayer then
			playersArchived[steam].watchPlayerTimer = os.time() + 259200 -- 3 days
		else
			playersArchived[steam].watchPlayerTimer = 0
		end
	end

	if playersArchived[steam].waypointCooldown == nil then
		playersArchived[steam].waypointCooldown = 0
	end

	if playersArchived[steam].VACBanned == nil then
		playersArchived[steam].VACBanned = false
	end
end


function fixMissingIGPlayer(steam)
	-- if any fields are missing from the players in-game player record, add them with default values

	if (igplayers[steam].afk == nil) then
		igplayers[steam].afk = os.time() + 900
	end

	if igplayers[steam].alertLocation == nil then
		igplayers[steam].alertLocation = ""
	end

	if igplayers[steam].alertRemovedClaims == nil then
		igplayers[steam].alertRemovedClaims = false
	end

	if (igplayers[steam].belt == nil) then
		igplayers[steam].belt = ""
	end

	if (igplayers[steam].checkNewPlayer == nil) then
		igplayers[steam].checkNewPlayer = true
	end

	if (igplayers[steam].chunkX == nil) then
		igplayers[steam].chunkX = 0
	end

	if (igplayers[steam].chunkZ == nil) then
		igplayers[steam].chunkZ = 0
	end

	if (igplayers[steam].claimPass == nil) then
		igplayers[steam].claimPass = 0
	end

	if (igplayers[steam].connected == nil) then
		igplayers[steam].connected = true
	end

	if (igplayers[steam].currentLocationPVP == nil) then
		igplayers[steam].currentLocationPVP = false
	end

	if (igplayers[steam].deaths == nil) then
		igplayers[steam].deaths = -1
	end

	if igplayers[steam].doge == nil then
		igplayers[steam].doge = false
	end

	if (igplayers[steam].equipment == nil) then
		igplayers[steam].equipment = ""
	end

	if (igplayers[steam].fetch == nil) then
		igplayers[steam].fetch = false
	end

	if (igplayers[steam].firstSeen == nil) then
		igplayers[steam].firstSeen = os.time()
	end

	if igplayers[steam].flying == nil then
		igplayers[steam].flying = false
	end

	if igplayers[steam].flyCount == nil then
		igplayers[steam].flyCount = 0
	end

	if igplayers[steam].flyingX == nil then
		igplayers[steam].flyingX = 0
	end

	if igplayers[steam].flyingY == nil then
		igplayers[steam].flyingY = 0
	end

	if igplayers[steam].flyingZ == nil then
		igplayers[steam].flyingZ = 0
	end

	if igplayers[steam].flyingHeight == nil then
		igplayers[steam].flyingHeight = 0
	end

	-- if (igplayers[steam].greet == nil) then
-- display("fix missing greet = false")
		-- igplayers[steam].greet = false
	-- end

	-- if (igplayers[steam].greetdelay == nil) then
		-- igplayers[steam].greetdelay = 0
	-- end

	if igplayers[steam].hackerTPScore == nil then
		igplayers[steam].hackerTPScore = 0
	end

	if igplayers[steam].highPingCount == nil then
		igplayers[steam].highPingCount = 0
	end

	if (igplayers[steam].illegalInventory == nil) then
		igplayers[steam].illegalInventory = false
	end

	if (igplayers[steam].inLocation == nil) then
		igplayers[steam].inLocation = ""
	end

	if (igplayers[steam].inventory == nil) then
		igplayers[steam].inventory = ""
	end

	if (igplayers[steam].inventoryLast == nil) then
		igplayers[steam].inventoryLast = ""
	end

	if (igplayers[steam].killTimer == nil) then
		igplayers[steam].killTimer = 0
	end

	if (igplayers[steam].lastHotspot == nil) then
		igplayers[steam].lastHotspot = 0
	end

	if (igplayers[steam].lastLogin == nil) then
		igplayers[steam].lastLogin = ""
	end

	if igplayers[steam].lastLP == nil then
		igplayers[steam].lastLP = os.time()
	end

	if igplayers[steam].lastTPTimestamp == nil then
		igplayers[steam].lastTPTimestamp = os.time()
	end

	if (igplayers[steam].level == nil) then
		igplayers[steam].level = -1
	end

	if igplayers[steam].noclip == nil then
		igplayers[steam].noclip = false
	end

	if igplayers[steam].noclipCount == nil then
		igplayers[steam].noclipCount = 0
	end

	if igplayers[steam].noclipX == nil then
		igplayers[steam].noclipX = 0
	end

	if igplayers[steam].noclipY == nil then
		igplayers[steam].noclipY = 0
	end

	if igplayers[steam].noclipZ == nil then
		igplayers[steam].noclipZ = 0
	end

	if igplayers[steam].notifyTP == nil then
		igplayers[steam].notifyTP = false
	end

	if (igplayers[steam].oldBelt == nil) then
		igplayers[steam].oldBelt = ""
	end

	if (igplayers[steam].oldLevel == nil) then
		igplayers[steam].oldLevel = -1
	end

	if (igplayers[steam].pack == nil) then
		igplayers[steam].pack = ""
	end

	if (igplayers[steam].ping == nil) then
		igplayers[steam].ping = ping
	end

	if igplayers[steam].playGimme == nil then
		igplayers[steam].playGimme = false
	end

	if (igplayers[steam].playerKills == nil) then
		igplayers[steam].playerKills = -1
	end

	if igplayers[steam].rawPosition == nil then
		igplayers[steam].rawPosition = 0
	end

	if igplayers[steam].rawRotation == nil then
		igplayers[steam].rawRotation = 0
	end

	if (igplayers[steam].region == nil) then
		igplayers[steam].region = ""
	end

	if (igplayers[steam].regionX == nil) then
		igplayers[steam].regionX = 0
	end

	if (igplayers[steam].regionZ == nil) then
		igplayers[steam].regionZ = 0
	end

	if igplayers[steam].reservedSlot == nil then
		igplayers[steam].reservedSlot = false
	end

	if (igplayers[steam].sessionPlaytime == nil) then
		igplayers[steam].sessionPlaytime = 0
	end

	if (igplayers[steam].sessionStart == nil) then
		igplayers[steam].sessionStart = os.time()
	end

	if igplayers[steam].spawnedInWorld == nil then
		igplayers[steam].spawnedInWorld = true
	end

	if igplayers[steam].spawnedReason == nil then
		igplayers[steam].spawnedReason = "fake reason"
	end

	if igplayers[steam].spawnChecked == nil then
		igplayers[steam].spawnChecked = true
	end

	if igplayers[steam].spawnPending == nil then
		igplayers[steam].spawnPending = false
	end

	if igplayers[steam].spawnedCoords == nil then
		igplayers[steam].spawnedCoords = "0 0 0"
	end

	if igplayers[steam].spawnedCoordsOld == nil then
		igplayers[steam].spawnedCoordsOld = "0 0 0"
	end

	if (igplayers[steam].steamOwner == nil) then
		igplayers[steam].steamOwner = steam
	end

	if (igplayers[steam].teleCooldown == nil) then
		igplayers[steam].teleCooldown = 200
	end

	if (igplayers[steam].timeOnServer == nil) then
		igplayers[steam].timeOnServer = players[steam].timeOnServer
	end

	if igplayers[steam].tp == nil then
		igplayers[steam].tp = 1
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

	if (igplayers[steam].zombies == nil) then
		igplayers[steam].zombies = -1
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