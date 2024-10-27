--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

-- dbug("debug core_functions line " .. debugger.getinfo(1).currentline)


function isAdmin(steam, userID)
	if players[steam] then
		if not userID then
			userID = players[steam].userID
		end

		if userID == "" then
			userID = players[steam].userID
		end

		if players[steam].testAsPlayer then
			return false, 90
		end
	end

	if staffList[steam] then
		if staffList[steam].hidden then
			return false, 90
		else
			return true, tonumber(staffList[steam].adminLevel)
		end
	end

	if userID then
		if staffList[userID] then
			if staffList[userID].hidden then
				return false, 90
			else
				return true, tonumber(staffList[userID].adminLevel)
			end
		end
	end

	return false, 99
end


function isAdminHidden(steam, userID)
	if players[steam] then
		if not userID then
			userID = players[steam].userID
		end

		if userID == "" then
			userID = players[steam].userID
		end
	end

	if staffList[steam] then
		return true, tonumber(staffList[steam].adminLevel)
	end

	if userID then
		if staffList[userID] then
			return true, tonumber(staffList[userID].adminLevel)
		end
	end

	return false, 99
end


function isAdminOnline()
	-- this function helps us choose different actions depending on if an admin is playing or not.
	local k, v

	for k,v in pairs(igplayers) do
		if staffList[v.steam] then
			return true
		end

		if staffList[v.userID] then
			return true
		end
	end

	return false
end


function dateToTimestamp(dateString)
	local ts

	local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+)"
	local runyear, runmonth, runday, runhour, runminute = dateString:match(pattern)

	ts = os.time({year = runyear, month = runmonth, day = runday, hour = runhour, min = runminute})
	return ts
end


function getSWNECoords(x1, y1, z1, x2, y2, z2)
	local coords = {}
	local num -- comfortably

	if x1 < x2 then
		coords.x1 = x1
		coords.x2 = x2
	else
		num = x1
		coords.x1 = x2
		coords.x2 = num
	end

	if y1 < y2 then
		coords.y1 = y1
		coords.y2 = y2
	else
		num = y1
		coords.y1 = y2
		coords.y2 = num
	end

	if z1 < z2 then
		coords.z1 = z1
		coords.z2 = z2
	else
		num = z1
		coords.z1 = z2
		coords.z2 = num
	end

	return coords.x1, coords.y1, coords.z1, coords.x2, coords.y2, coords.z2
end


function getSWNECoordsXZ(x1, z1, x2, z2)
	local coords = {}
	local num -- comfortably

	if x1 < x2 then
		coords.x1 = x1
		coords.x2 = x2
	else
		num = x1
		coords.x1 = x2
		coords.x2 = num
	end

	if z1 < z2 then
		coords.z1 = z1
		coords.z2 = z2
	else
		num = z1
		coords.z1 = z2
		coords.z2 = num
	end

	return coords.x1, coords.z1, coords.x2, coords.z2
end


function sendCommand(command)
	local APICommand, outputFile, sendToQueue, doNotQueue
	local httpHeaders = {["X-SDTD-API-TOKENNAME"] = server.allocsWebAPIUser, ["X-SDTD-API-SECRET"] = server.allocsWebAPIPassword}

	-- send the command to the server via Allocs web API if enabled otherwise use telnet
	-- any commands that must be sent via telnet, trap and send them first.

	if botman.worldGenerating then
		-- send no commands to the server while the world is generating.
		return
	end

	botman.lastBotCommand = command
	doNotQueue = false

	if not botman.gameStarted then
		sendToQueue = true
	end

	if server.useAllocsWebAPI and not string.find(command, "webtokens") and not string.find(command, "#") then -- and not botman.APIOffline
		-- send the command to Alloc's web API

		-- fix missing api and outputFile for some commands
		if command == "admin list" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "adminList.txt"
		end

		if command == "APICheck" then
			APICommand = "executeconsolecommand?command=apicheck"
			outputFile = "apicheck.txt"
		end

		if command == "ban list" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "banList.txt"
		end

		if string.find(command, "bm-anticheat report", nil, true) then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "bm-anticheat-report.txt"
		end

		if string.find(command, "bm-listplayerbed", nil, true) then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "bm-listplayerbed.txt"
			doNotQueue = true
		end

		if string.find(command, "bm-listplayerfriends", nil, true) then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "bm-listplayerfriends.txt"
			doNotQueue = true
		end

		if command == "bm-readconfig" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "bm-config.txt"
		end

		if command == "bm-resetregions list" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "bm-resetregions-list.txt"
		end

		if command == "bm-uptime" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "bm-uptime.txt"
		end

		if command == "gethostilelocation" then
			APICommand = "gethostilelocation?&"
			outputFile = "hostiles.txt"
			doNotQueue = true
		end

		if command == "getplayerinventories" then
			APICommand = "getplayerinventories?&"
			outputFile = "inventories.txt"
			doNotQueue = true
		end

		if command == "getserverinfo" then
			APICommand = "getserverinfo?&"
			outputFile = "serverinfo.txt"
			doNotQueue = true
		end

		-- don't send gg to the API for now as it messes up in the BC mod's JSON encoding if the Server Login Confirmation Text contains any /r/n's which is probably fairly common.
		if command == "gg" then
			-- instead send it to telnet as that parses it just fine.
			if sendToQueue then
				connMEM:execute('INSERT INTO serverCommandQueue (command) VALUES (' .. connMEM:escape(command) .. ')')
			else
				if server.readLogUsingTelnet then
					send(command)
				else
					APICommand = "executeconsolecommand?command=" .. command
					outputFile = "gg.txt"
				end
			end
		end

		if command == "gt" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "gametime.txt"
		end

		if string.sub(command, 1, 4) == "help" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "help.txt"
			doNotQueue = true
		end

		if command == "le" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "le.txt"
			doNotQueue = true
		end

		if string.sub(command, 1, 3) == "li " then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "li.txt"
			doNotQueue = true

		end

		if string.find(command, "lkp") then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "lkp.txt"
		end

		if string.find(command, "llp") then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "llp.txt"
		end

		if command == "lp" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "lp.txt"
			doNotQueue = true
		end

		-- if string.find(command, "lpf") then
			-- APICommand = "executeconsolecommand?command=" .. command
			-- outputFile = "lpf.txt"
		-- end

		if command == "mem" then -- this is used to read server time, grab the players online and some performance metrics.
			APICommand = "executeconsolecommand?command=mem"
			outputFile = "mem.txt"
			doNotQueue = true
		end

		if command == "pm apicheck" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "apicheck.txt"
			doNotQueue = true
		end

		if string.find(command, "bm-playergrounddistance", nil, true) then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "pgd.txt"
			doNotQueue = true
		end

		if string.find(command, "bm-playerunderground", nil, true) then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "pug.txt"
			doNotQueue = true
		end

		if string.sub(command, 1,3) == "se " or command == "se" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "se.txt"
			doNotQueue = true
		end

		if command == "version" then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "installedMods.txt"
		end

		-- this must be last.  It is a catch-all for anything not matched above.
		if APICommand == nil then
			APICommand = "executeconsolecommand?command=" .. command
			outputFile = "command.txt"
			doNotQueue = true
		end

		if command ~= "gg" or not server.readLogUsingTelnet then
			if sendToQueue then
				if not doNotQueue then
					connMEM:execute('INSERT INTO serverCommandQueue (command) VALUES (' .. connMEM:escape(command) .. ')')
				end
			else
				if botman.fileDownloadTimestamp == nil then
					botman.fileDownloadTimestamp = os.time()
				end

				if server.allocsMap == 0 and (command == "version" or command == "pm apitest") then
					-- version has not yet been sent so let's fix that.
					pcall(postHTTP("", "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/" .. APICommand, httpHeaders))
					-- the response from the server is processed in function onHttpPostDone(_, url, body) in functions.lua
				end

				pcall(postHTTP("", "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/" .. APICommand, httpHeaders))
				-- the response from the server is processed in function onHttpPostDone(_, url, body) in functions.lua

				-- should be able to remove list later.  Just put it here to fix an issue with older bots updating and not having the metrics table.
				if type(metrics) ~= "table" then
					metrics = {}
					metrics.commands = 0
					metrics.commandLag = 0
					metrics.errors = 0
					metrics.telnetLines = 0
				end

				metrics.commands = metrics.commands + 1

				if server.logBotCommands then
					logBotCommand(botman.serverTime, url)
				end
			end
		end
	else
		-- send the command to telnet

		if command == "getplayerinventories" or command == "gethostilelocation" or command == "li *" then
			return
		end

		-- should be able to remove list later.  Just put it here to fix an issue with older bots updating and not having the metrics table.
		if type(metrics) ~= "table" then
			metrics = {}
			metrics.commands = 0
			metrics.commandLag = 0
			metrics.errors = 0
			metrics.telnetLines = 0
		end

		if string.find(command, "bm-listplayerbed", nil, true) then
			doNotQueue = true
		end

		if string.find(command, "bm-listplayerfriends", nil, true) then
			doNotQueue = true
		end

		if string.sub(command, 1, 4) == "help" then
			doNotQueue = true
		end

		if command == "le" then
			doNotQueue = true
		end

		if string.sub(command, 1, 3) == "li " then
			doNotQueue = true
		end

		if command == "lp" then
			doNotQueue = true
		end

		if command == "mem" then
			doNotQueue = true
		end

		if string.find(command, "bm-playergrounddistance", nil, true) then
			doNotQueue = true
		end

		if string.find(command, "bm-playerunderground", nil, true) then
			doNotQueue = true
		end

		if string.sub(command, 1,3) == "se " or command == "se" then
			doNotQueue = true
		end

		if sendToQueue then
			if not doNotQueue then
				connMEM:execute('INSERT INTO serverCommandQueue (command) VALUES (' .. connMEM:escape(command) .. ')')
			end
		else
			send(command)
			metrics.commands = metrics.commands + 1

			if server.logBotCommands then
				logBotCommand(botman.serverTime, command)
			end
		end
	end

	if command == "shutdown" then
		server.uptime = 0
		server.serverStartTimestamp = os.time()
		saveLuaTables()
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

	if not alert then
		alert = ""
	end

	if type(server) == "table" then
		msgColour = server.chatColour
		if alert == "alert" then msgColour = server.alertColour end
		if alert == "warn" then msgColour = server.warnColour end
	else
		msgColour = "D4FFD4"
	end

	for k, v in pairs(igplayers) do
		if (isAdmin(k, v.userID)) then
			message("pm " .. v.userID .. " [" .. msgColour .. "]" .. msg .. "[-]")
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
	--text = string.gsub(text, "%[/c%]", "")
	--text = string.gsub(text, "%b[]", "")
	text = string.gsub(text, "%[[0-9a-fA-F]]-[^%[%]]-]", "")

	if text == nil then
		text = oldtext
	end

	return text
end


function stripAngleBrackets(text)
	local oldText

	text = string.trim(text)
	oldText = text
	text = string.gsub(text, "<", "")
	text = string.gsub(text, ">", "")

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
    return io.exists(name)
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
    return io.exists(name)
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
		if (igplayers[steam].sessionPlaytime + players[steam].timeOnServer < (tonumber(server.newPlayerTimer) * 60)) then
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

	if not friends[testid] then
		-- testid is not in the friends table
		return false
	end

	if tablelength(friends[testid].friends) == 0 then
		-- testid's friends list is empty
		return false
	end

	-- try to find steamid in the friends list of testid
	if friends[testid].friends[steamid] then
		return true
	end

	-- steamid is not a friend of testid
	return false
end


function countFriends(steam)
	-- how many friends?
	if not friends[steam] then
		return 0
	end

	return tablelength(friends[steam].friends)
end


function isBaseMember(testID, baseOwner, baseNumber)
	if not baseMembers[baseOwner .. "_" .. baseNumber] then
		-- there are no base members recorded for this base
		return false
	end

	-- try to find testID in the baseMembers table matching baseOwner and baseNumber
	if baseMembers[baseOwner .. "_" .. baseNumber].baseMembers[testID] then
		return true
	end

	-- could not find testID in the baseMembers table matching baseOwner and baseNumber
	return false
end


function countBaseMembers(baseOwner, baseNumber)
	-- how many members does this base have?
	if not baseMembers[baseOwner .. "_" .. baseNumber] then
		return 0
	end

	return tablelength(baseMembers[baseOwner .. "_" .. baseNumber].baseMembers)
end


function isHexCode(code)
	local test

	if string.len(code) == 7 then
		test = string.match(code, "#%x+$")
	end

	if string.len(code) == 6 then
		test = string.match(code, "^%x+$")
	end

	if test then
		return true
	else
		return false
	end
end


function isDonor(steam)
	if donors[steam] then
		if donors[steam].expired then
			return false
		else
			return true, donors[steam].expiry
		end
	else
		return false
	end
end


function message(msg, steam)
	-- parse msg and enclose the actual message in double quotes
	local words, word, skip, url, k, v, sayCommand, pmCommand, num, oldWord

	if server.suppressDisabledCommand then
		if string.find(msg, "This command is disabled") then
			return
		end
	end

	if server.botman then
		sayCommand = "bm-say"
		pmCommand = "bm-sayprivate"
	else
		sayCommand = "say"
		pmCommand = "pm"
	end

	msg = msg:gsub("{#}", server.commandPrefix)

	if steam then
		msg = msg:gsub("{player}", players[steam].name)
	end

	msg = msg:gsub("{server}", server.serverName)
	msg = msg:gsub("{money}", server.moneyName)
	msg = msg:gsub("{monies}", server.moneyPlural)

	if string.find(msg, "[", nil, true) and not string.find(msg, "[-]", nil, true) then
		msg = msg .. "[-]"
	end

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
				msg = sayCommand .. " \"" .. string.sub(msg, 5) .. "\""
				send(msg)

				if server.logBotCommands then
					logBotCommand(botman.serverTime, msg)
				end

				metrics.commands = metrics.commands + 1
			else
				msg = string.sub(msg, 5)
				url = "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/executeconsolecommand?command=" .. sayCommand .. " \"" .. msg .. "\""

				if botman.dbConnected then
					connSQL:execute("INSERT into APIQueue (URL, outputFile, timestamp) VALUES ('" .. connMEM:escape(url) .. "','" .. homedir .. "/temp/dummy.txt" .. "'," .. os.time() .. ")")
					botman.apiQueueEmpty = false
					enableTimer("APITimer")
				end
			end
		else
			msg = sayCommand .. " \"" .. string.sub(msg, 5) .. "\""
			send(msg)

			if server.logBotCommands then
				logBotCommand(botman.serverTime, msg)
			end

			metrics.commands = metrics.commands + 1
		end

	else
		if players[words[2]] then
			if server.useAllocsWebAPI then
				msg = string.sub(msg, string.find(msg, words[2]) + string.len(words[2]))
				url = "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/executeconsolecommand?command=" .. pmCommand .. " " .. words[2] .. " \"" .. msg .. "\""

				if botman.dbConnected then
					connSQL:execute("INSERT into APIQueue (URL, outputFile, timestamp) VALUES ('" .. connMEM:escape(url) .. "','" .. homedir .. "/temp/dummy.txt" .. "'," .. os.time() .. ")")
					botman.apiQueueEmpty = false
					enableTimer("APITimer")
				end
			else
				-- check for wrongly formatted steam id
				num = tonumber(words[2])

				if num ~= nil then
					if string.len(words[2]) == 17 then
						oldWord = words[2]
						-- this is a steam id without Steam_ in front of it so let's fix that now.
						words[2] = "Steam_" .. words[2]
						msg = string.gsub(msg, oldWord, words[2])
					end
				end

				msg = pmCommand .. " " .. words[2] .. " \"" .. string.sub(msg, string.find(msg, words[2]) + string.len(words[2])) .. "\""
				send(msg)

				if server.logBotCommands then
					logBotCommand(botman.serverTime, msg)
				end

				metrics.commands = metrics.commands + 1
			end
		else
			if server.useAllocsWebAPI then
				msg = string.sub(msg, string.find(msg, words[2]) + string.len(words[2]))
				url = "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/executeconsolecommand?command=" .. pmCommand .. " " .. words[2] .. " \"" .. msg .. "\""

				if botman.dbConnected then
					if words[2] == "apitest" then
						connSQL:execute("INSERT into APIQueue (URL, outputFile, timestamp) VALUES ('" .. connMEM:escape(url) .. "','" .. homedir .. "/temp/apitest.txt" .. "'," .. os.time() .. ")")
					else
						connSQL:execute("INSERT into APIQueue (URL, outputFile, timestamp) VALUES ('" .. connMEM:escape(url) .. "','" .. homedir .. "/temp/dummy.txt" .. "'," .. os.time() .. ")")
					end

					botman.apiQueueEmpty = false
					enableTimer("APITimer")
				end
			else
				-- check for wrongly formatted steam id
				num = tonumber(words[2])

				if num ~= nil then
					if string.len(words[2]) == 17 then
						oldWord = words[2]
						-- this is a steam id without Steam_ in front of it so let's fix that now.
						words[2] = "Steam_" .. words[2]
						msg = string.gsub(msg, oldWord, words[2])
					end
				end

				msg = pmCommand .. " " .. words[2] .. " \"" .. string.sub(msg, string.find(msg, words[2]) + string.len(words[2])) .. "\""
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
	local k,v, result, inLocation

	result = false

	if server.gameType == "pvp" then
		result = true
	end

	-- is the coord x,z a pvp zone?
	if server.northeastZone == "pvp" and tonumber(x) >= 0 and tonumber(z) >= 0 then
		result = true
	end

	if server.northeastZone == "pve" and tonumber(x) >= 0 and tonumber(z) >= 0 then
		result = false
	end

	if server.northwestZone == "pvp" and tonumber(x) < 0 and tonumber(z) >= 0 then
		result = true
	end

	if server.northwestZone == "pve" and tonumber(x) < 0 and tonumber(z) >= 0 then
		result = false
	end

	if server.southeastZone == "pvp" and tonumber(x) >= 0 and tonumber(z) < 0 then
		result = true
	end

	if server.southeastZone == "pve" and tonumber(x) >= 0 and tonumber(z) < 0 then
		result = false
	end

	if server.southwestZone == "pvp" and tonumber(x) < 0 and tonumber(z) < 0 then
		result = true
	end

	if server.southwestZone == "pve" and tonumber(x) < 0 and tonumber(z) < 0 then
		result = false
	end

	return result
end


function inLocation(x, z)
	-- is the coord inside a location?
	local closestLocation, closestDistance, dist, reset, inside

	if x == nil or locations == nil then
		return false, false
	end

	-- since locations can exist inside other locations, work out which location centre is closest
	closestDistance = 100000
	reset = false

	for k, v in pairs(locations) do
		dist = distancexz(x, z, v.x, v.z)
		inside = false

		if not v.isRound then
			if (math.abs(v.x-x) <= tonumber(v.size) and math.abs(v.z-z) <= tonumber(v.size)) then
				inside = true
			end
		else
			inside = insideCircle(x, z, v.x, v.z, v.size)
		end

		if v.size ~= nil then
			if inside then
				if tonumber(dist) < tonumber(closestDistance) then
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
		return "0"
	end

	i = 1
	r = tonumber(randSQL(botman.arenaCount))

	for k, v in pairs(arenaPlayers) do
		if r == i then
			return k
		else
			i = i + 1
		end
	end

	return "0" -- return something
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


function getNextBaseNumber(steam)
	local k, v, lastBaseNumber

	lastBaseNumber = 0

	-- lookup the base
	for k, v in pairs(bases) do
		if v.steam == steam then
			if tonumber(v.baseNumber) > lastBaseNumber then
				lastBaseNumber = tonumber(v.baseNumber)
			end
		end
	end

	return lastBaseNumber + 1
end


function getNearestBase(x, z, steam)
	local k, v, base, dist, shortestDist

	shortestDist = 1000000

	-- find the nearest base to x, z
	for k, v in pairs(bases) do
		if steam then
			-- just look at bases owned by steam
			if v.steam == steam then
				dist = distancexz(x, z, v.x, v.z)

				if dist < shortestDist then
					shortestDist = dist
					base = v
				end
			end
		else
			-- check every base for those two droids
			dist = distancexz(x, z, v.x, v.z)

			if dist < shortestDist then
				shortestDist = dist
				base = v
			end
		end
	end

	if base then
		return true, base
	else
		-- no base matched search
		return false, nil
	end
end


function LookupBase(steam, baseID)
	local k, v, base, baseNumber, baseName

	if baseID then
		baseNumber = tonumber(baseID)

		if baseNumber == nil then
			baseName = baseID
		end
	end

	-- lookup the base
	for k, v in pairs(bases) do
		if v.steam == steam then
			if not baseNumber and not baseName then
				base = v
				return true, base
			end

			if baseNumber then
				if tonumber(v.baseNumber) == baseNumber then
					base = v
					return true, base
				end
			end

			if baseName then
				baseName = string.lower(baseName)

				if string.lower(v.title) == baseName then
					base = v
					return true, base
				end
			end
		end
	end

	-- no base matched search
	return false, nil
end


function LookupPlayer(search, match)
	-- try to find the player in those who are playing right now
	-- returns steam, owner, userID, platform
	local steam, owner, userID, k, v, eos, name, platform, searchOld, searchUpper

	if string.trim(search) == "" then
		return "0", "0", "", ""
	end

	search = string.lower(search)
	searchUpper = string.upper(search)
	search = stripMatching(search, "steam_")
	search = stripMatching(search, "xbl_")
	searchOld = search
	eos = "eos_" .. search

	if not match then
		match = ""
	end

	if igplayers[search] then
		return search, igplayers[search].steamOwner, igplayers[search].userID, igplayers[search].platform
	end

	if igplayers[searchUpper] then
		return searchUpper, igplayers[searchUpper].steamOwner, igplayers[searchUpper].userID, igplayers[searchUpper].platform
	end

	if string.starts(search, "\"") and string.ends(search,"\"") then
		search = string.sub(search, 2, string.len(search) - 1)
		match = "all"
	end

	for k, v in pairs(igplayers) do
		if match == "code" then
			if tonumber(search) == tonumber(players[k].ircInvite) then
				return k, v.steamOwner, v.userID, v.platform
			end
		else
			if v.userID ~= nil then
				-- look for the EOS id
				userID = string.lower(v.userID)

				if (search == userID) or (eos == userID) then
					return k, v.steamOwner, v.userID, v.platform
				end
			end

			if (v.name ~= nil) then
				name = string.lower(v.name)

				if match == "all" then
					-- look for an exact match
					if (search == name) then
						return k, v.steamOwner, v.userID, v.platform
					end

					if (v.ircAlias ~= nil) and (search == string.lower(v.ircAlias)) then
						return k, v.steamOwner, v.userID, v.platform
					end
				else
					-- if it contains the search it is a match
					if (search == name) or (string.find(name, search, nil, true)) then
						return k, v.steamOwner, v.userID, v.platform
					end

					if (string.find(v.id, search)) then
						return k, v.steamOwner, v.userID, v.platform
					end
				end
			end
		end
	end

	-- no matches so try again but including all players
	steam, owner, userID, platform = LookupOfflinePlayer(searchOld, match)

	if steam ~= "0" and platform == "" then
		platform = "Steam"
	end

	-- if steam isn't 0 we found a match
	return steam, owner, userID, platform
end


function LookupOfflinePlayer(search, match)
	-- try to find the player in all known players
	-- returns steam, owner, userID, platform
	local k, v, eos, name, platform, userID, searchUpper

	if string.trim(search) == "" then
		return "0", "0", "", ""
	end

	search = string.lower(search)
	searchUpper = string.upper(search)
	search = stripMatching(search, "steam_")
	search = stripMatching(search, "xbl_")
	eos = "eos_" .. search

	if not match then
		match = ""
	end

	if players[search] then
		return search, players[search].steamOwner, players[search].userID, players[search].platform
	end

	if players[searchUpper] then
		return searchUpper, players[searchUpper].steamOwner, players[searchUpper].userID, players[searchUpper].platform
	end

	if string.starts(search, "\"") and string.ends(search,"\"") then
		search = string.sub(search, 2, string.len(search) - 1)
		match = "all"
	end

	for k, v in pairs(players) do
		if match == "code" then
			if tonumber(search) == tonumber(players[k].ircInvite) then
				return k, v.steamOwner, v.userID, v.platform
			end
		else
			if v.userID ~= nil then
				-- look for the EOS id
				userID = string.lower(v.userID)

				if (search == userID) or (eos == userID) then
					return k, v.steamOwner, v.userID, v.platform
				end
			end

			if (v.name ~= nil) then
				name = string.lower(v.name)

				if match == "all" then
					if (search == name) then
						return k, v.steamOwner, v.userID, v.platform
					end

					if (v.ircAlias ~= nil) and (search == string.lower(v.ircAlias)) then
						return k, v.steamOwner, v.userID, v.platform
					end
				else
					if (search == name) or (string.find(name, search, nil, true)) then
						return k, v.steamOwner, v.userID, v.platform
					end
				end
			end
		end
	end

	-- got to here so no match found
	return "0", "0", "", ""
end


function LookupArchivedPlayer(search, match)
	-- try to find the player in archived players
	-- returns steam, owner, userID, platform
	local k, v, name, platform, eos, userID, searchUpper

	if string.trim(search) == "" then
		return "0", "0", "", ""
	end

	search = string.lower(search)
	searchUpper = string.upper(search)
	search = stripMatching(search, "steam_")
	search = stripMatching(search, "xbl_")
	eos = "eos_" .. search

	if playersArchived[search] then
		return search, playersArchived[search].steamOwner, playersArchived[search].userID, playersArchived[search].platform
	end

	if playersArchived[searchUpper] then
		return searchUpper, playersArchived[searchUpper].steamOwner, playersArchived[searchUpper].userID, playersArchived[searchUpper].platform
	end

	if string.starts(search, "\"") and string.ends(search,"\"") then
		search = string.sub(search, 2, string.len(search) - 1)
		match = "all"
	end

	for k, v in pairs(playersArchived) do
		if match == "code" then
			if tonumber(search) == tonumber(playersArchived[k].ircInvite) then
				return k, v.steamOwner, v.userID, v.platform
			end
		else
			if v.userID ~= nil then
				userID = string.lower(v.userID)

				-- look for the EOS id
				if (search == userID) or (eos == userID) then
					return k, v.steamOwner, v.userID, v.platform
				end
			end

			if (v.name ~= nil) then
				name = string.lower(v.name)

				if match == "all" then
					if (search == name) then
						return k, v.steamOwner, v.userID, v.platform
					end

					if (v.ircAlias ~= nil) and (search == string.lower(v.ircAlias)) then
						return k, v.steamOwner, v.userID, v.platform
					end
				else
					if (search == name) or (string.find(name, search, nil, true)) then
						return k, v.steamOwner, v.userID, v.platform
					end
				end
			end
		end
	end

	-- got to here so no match found
	return "0", "0", "", ""
end


function LookupIRCAlias(name)
	-- returns a steam ID if only 1 player record uses the name.
	local k,v, nickCount, steam, userID

	nickCount = 0

	for k, v in pairs(players) do
		if (v.ircAlias ~= nil) then
			if (name == v.ircAlias) then
				nickCount = nickCount + 1
				steam = k
				userID = v.userID
			end
		end
	end

	if nickCount == 1 then
		return steam, userID
	else
		return "0", "0"
	end
end


function LookupIRCPass(login, pass)
	local k,v

	if string.trim(pass) == "" then
		return "0"
	end

	for k, v in pairs(players) do
		if (v.ircPass ~= nil) then
			if (login == v.ircLogin) and (pass == v.ircPass) then
				return k, v.userID
			end
		end
	end

	return "0", "0"
end


function LookupMarkedArea(name, steam)
	local k,v

	name = string.lower(name)

	for k,v in pairs(prefabCopies) do
		if (name == string.lower(v.name)) then
			if steam ~= nil then
				if (steam == v.steam) then
					return k
				end
			else
				return k
			end
		end
	end

	return ""
end


function LookupPlayerGroup(name)
	local k,v, idx

	if not name then
		return 0, ""
	end

	name = string.lower(name)
	idx = "G" .. name

	for k,v in pairs(playerGroups) do
		if k == idx then
			return v.groupID, v.name
		end

		if (name == string.lower(v.name)) then
			return v.groupID, v.name
		end
	end

	return 0, ""
end


function LookupLocation(command)
	local k,v, lobby

	-- is command the name of a location?
	command = string.lower(command)

	if (string.find(command, server.commandPrefix) == 1) then
		command = string.sub(command, 2) -- strip off the leading /
	end

	for k, v in pairs(locations) do
		if (command == string.lower(v.name)) then
			return k
		end

		if (command == "lobby" or command == "spawn") and v.lobby then
			return k
		end

		if string.lower(v.name) == "spawn" and (command == "lobby" or command == "spawn") then
			lobby = k
		end
	end

	if lobby then
		return lobby
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
			if distancexyz(x, y, z, v.x, v.y, v.z) < 2 then
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


function LookupVillage(village)
	local k,v

	-- is command the name of a location?
	village = string.lower(village)

	if (string.find(village, server.commandPrefix) == 1) then
		village = string.sub(village, 2) -- strip off the leading /
	end

	for k, v in pairs(locations) do
		if (village == string.lower(v.name)) and v.village then
			return k
		end
	end

	return "0"
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


function sortTable(tbl)
	-- take an unsorted table and create a sorted table containing just the original table's keys
	local n
	local a = {}

	for n in pairs(tbl) do
		table.insert(a, n)
	end

	table.sort(a)

	return a
end


function copyTable(t)
	-- In Lua if we assign a table to another table it just creates a reference to table rather than a copy.  To fix this we need to read the values in individually.
	-- This code does not handle nested tables.
	local tempTable = {}

	for k,v in pairs(t) do
		tempTable[k] = v
	end

	return tempTable
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


function insideCircle(x, z, cx, cz, radius)
	-- x and z is the coord to be tested
	-- cx and cz is the centre of the circle
	if math.pow(x-cx,2) + math.pow(z-cz,2) <= math.pow(radius,2) then
		return true
	else
		return false
	end
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


function getMapCoords(x, z)
	local dirX, dirZ

	if x > 0 then
		dirX = " E"
	else
		dirX = " W"
	end

	if z > 0 then
		dirZ = " N"
	else
		dirZ = " S"
	end

	return math.abs(x) .. dirX .. " " .. math.abs(z) .. dirZ
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


function getNumbers(str)
	local word, numbers

	numbers = {}

	for word in string.gmatch (str, "(-?\%d+)") do
		table.insert(numbers, tonumber(word))
	end

	return numbers
end


function accessLevel(steam, userID)
	local debug

	debug = false

	-- determine the access level of the player

	if debug then dbug("accesslevel steam " .. steam) end

	if steam == "0" then
		-- no steam?  return the worst possible access level. That'll show em!
		return 99
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	if userID then
		if staffList[userID] then
			if players[steam] then
				players[steam].accessLevel = tonumber(staffList[userID].adminLevel)
			end

			return tonumber(staffList[userID].adminLevel)
		end
	end

	if staffList[steam] then
		if players[steam] then
			players[steam].accessLevel = tonumber(staffList[steam].adminLevel)
		end

		return tonumber(staffList[steam].adminLevel)
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	-- anyone stripped of certain rights
	if players[steam] then
		if players[steam].denyRights == true then
			players[steam].accessLevel = 99
			return 99
		end
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	if tonumber(server.accessLevelOverride) < 99 and players[steam] then
		return tonumber(server.accessLevelOverride)
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	if tonumber(players[steam].groupID) > 0 then
		return playerGroups["G" .. players[steam].groupID].accessLevel
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	-- regulars
	if igplayers[steam] then
		if tonumber(players[steam].timeOnServer) + tonumber(igplayers[steam].sessionPlaytime) > (tonumber(server.newPlayerTimer) * 60) then
			players[steam].accessLevel = 90
			return 90
		end
	else
		if players[steam] then
			if tonumber(players[steam].timeOnServer) > (tonumber(server.newPlayerTimer) * 60) then
				players[steam].accessLevel = 90
				return 90
			end
		end
	end

	if debug then dbug("debug accesslevel line " .. debugger.getinfo(1).currentline) end

	-- new players
	if players[steam] then
		players[steam].accessLevel = 99
	end

	return 99
end


function fixMissingPlayer(platform, steam, steamOwner, userID)
	-- if any fields are missing from the players player record, add them with default values
	local k,v

	if steamOwner == "nil" then
		steamOwner = steam
	end

	if not players[steam] then
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
		friends[steam].friends = {}
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
		players[steam].exiled = false
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

	if players[steam].nameOverride == nil then
		players[steam].nameOverride = ""
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

	if players[steam].p2pCooldown == nil then
		players[steam].p2pCooldown = 0
	end

	if players[steam].packCooldown == nil then
		players[steam].packCooldown = 0
	end

	if players[steam].pendingBans == nil then
		players[steam].pendingBans = 0
	end

	if players[steam].platform == nil then
		players[steam].platform = platform
	end

	if players[steam].prisonReason == nil then
		players[steam].prisonReason = ""
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

	players[steam].steam = steam
	players[steam].steamOwner = steamOwner

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

	if userID then
		if (players[steam].userID == nil) then
			players[steam].userID = userID
		end
	end

	if players[steam].VACBanned == nil then
		players[steam].VACBanned = false
	end

	if players[steam].maxBases == nil then
		players[steam].maxBases = server.maxBases
	end

	if players[steam].maxProtectedBases == nil then
		players[steam].maxProtectedBases = server.maxProtectedBases
	end
end


function fixMissingArchivedPlayer(steam)
	-- if any fields are missing from the players player record, add them with default values
	local k,v

	if not playersArchived[steam] then
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

	if playersArchived[steam].GBLCount == nil then
		playersArchived[steam].GBLCount = 0
	end

	if playersArchived[steam].gimmeCooldown == nil then
		playersArchived[steam].gimmeCooldown = 0
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


function fixMissingIGPlayer(platform, steam, steamOwner, userID)
	-- if any fields are missing from the players in-game player record, add them with default values

	if steamOwner == "nil" then
		steamOwner = steam
	end

	if not igplayers[steam] then
		igplayers[steam] = {}
	end

	if (igplayers[steam].afk == nil) then
		igplayers[steam].afk = os.time() + tonumber(server.idleKickTimer)
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

	if igplayers[steam].platform == nil then
		igplayers[steam].platform = platform
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

	igplayers[steam].steam = steam
	igplayers[steam].steamOwner = steamOwner

	if (igplayers[steam].teleCooldown == nil) then
		igplayers[steam].teleCooldown = 200
	end

	if (igplayers[steam].timeOnServer == nil) then
		igplayers[steam].timeOnServer = players[steam].timeOnServer
	end

	if igplayers[steam].tp == nil then
		igplayers[steam].tp = 1
	end

	if userID then
		igplayers[steam].userID = userID
	else
		igplayers[steam].userID = ""
	end

	if not igplayers[steam].xPos then
		igplayers[steam].xPos = 0
		igplayers[steam].yPos = 0
		igplayers[steam].zPos = 0
	end

	if not igplayers[steam].xPosLast then
		igplayers[steam].xPosLast = 0
		igplayers[steam].yPosLast = 0
		igplayers[steam].zPosLast = 0
	end

	if not igplayers[steam].xPosLastOK then
		igplayers[steam].xPosLastOK = 0
		igplayers[steam].yPosLastOK = 0
		igplayers[steam].zPosLastOK = 0
	end

	if not igplayers[steam].xPosLastAlert then
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


function LookupSettingValue(steam, setting)
	-- The server table contains values for cooldowns and limits on things.  These can be overridden by settings in the playerGroup table or in the player record.
	-- Get the server setting then see if we need to use a different value from a group or the player record and return the setting's value
	local player = players[steam]
	-- first load the server setting into value.  This will be returned if nothing replaces it below.
	local value, idx

	if server[setting] then
		value = server[setting]
	end

	if tonumber(player.groupID) > 0 then
		idx = "G" .. player.groupID

		-- the player is a member of a group so replace value with the group's setting
		if playerGroups[idx][setting] then
			value = playerGroups[idx][setting]
		else
			value = player[setting]
		end
	end

	if setting == "maxWaypoints" then
		if tonumber(player.maxWaypoints) > value then
			-- the player has been given more waypoints so use the player's limit
			value = tonumber(player.maxWaypoints)
			return value
		end
	end

	if setting == "maxBases" then
		if tonumber(player.maxBases) > value then
			-- the player has been given more bases so use the player's limit
			value = tonumber(player.maxBases)
			return value
		end
	end

	if setting == "maxProtectedBases" then
		if tonumber(player.maxProtectedBases) > value then
			-- the player has been given more base protects so use the player's limit
			value = tonumber(player.maxProtectedBases)
			return value
		end
	end

	-- the setting in the player record overrides server settings but not group settings (except for maxWaypoints, maxBases and maxProtectedBases unless lower than the group max)
	if tonumber(player.groupID) == 0 then
		if player[setting] then
			value = player[setting]
		end
	end

	-- return the final value
	return value
end


function getSettings(steam)
	local settings, player, idx

	settings = {}

	-- special case for non-player (the bot)
	if steam == "0" then
		settings.maxGimmies = 11
		settings.teleportPublicCost = server.teleportPublicCost
		settings.maxWaypoints = 0
		settings.maxBases = 0
		settings.allowTeleporting = server.allowTeleporting
		settings.allowGimme = server.allowGimme
		settings.lotteryTicketPrice = server.lotteryTicketPrice
		settings.packCost = server.packCost
		settings.baseCooldown = server.baseCooldown
		settings.packCooldown = server.packCooldown
		settings.teleportCost = server.teleportCost
		settings.allowLottery = server.allowLottery
		settings.waypointCreateCost = server.waypointCreateCost
		settings.deathCost = server.deathCost
		settings.maxProtectedBases = 0
		settings.allowShop = server.allowShop
		settings.gimmeZombies = server.gimmeZombies
		settings.hardcore = server.hardcore
		settings.p2pCooldown = server.p2pCooldown
		settings.zombieKillReward = server.zombieKillReward
		settings.waypointCooldown = server.waypointCooldown
		settings.baseCost = server.baseCost
		settings.teleportPublicCooldown = server.teleportPublicCooldown
		settings.pvpAllowProtect = server.pvpAllowProtect
		settings.perMinutePayRate = server.perMinutePayRate
		settings.lotteryMultiplier = server.lotteryMultiplier
		settings.playerTeleportDelay = server.playerTeleportDelay
		settings.returnCooldown = server.returnCooldown
		settings.baseSize = server.baseSize
		settings.waypointCost = server.waypointCost
		settings.allowHomeTeleport = server.allowHomeTeleport
		settings.allowPlayerToPlayerTeleporting = server.allowPlayerToPlayerTeleporting
		settings.allowVisitInPVP = server.allowVisitInPVP
		settings.allowWaypoints = server.allowWaypoints
		settings.reserveSlot = false
		settings.gimmeRaincheck = server.gimmeRaincheck
		settings.groupID = 0
		settings.groupName = ""
		settings.suicideCost = server.suicideCost
		settings.allowSuicide = server.allowSuicide

		return settings
	end

	player = players[steam]

	if tonumber(player.groupID) > 0 then
		idx = "G" .. player.groupID
		settings = copyTable(playerGroups[idx])
		settings.groupName = playerGroups[idx].name
		settings.groupID = player.groupID

		if tonumber(player.maxBases) > tonumber(settings.maxBases) then
			settings.maxBases = player.maxBases
		end

		if tonumber(player.maxProtectedBases) > tonumber(settings.maxProtectedBases) then
			settings.maxProtectedBases = player.maxProtectedBases
		end

		if tonumber(player.maxWaypoints) > tonumber(settings.maxWaypoints) then
			settings.maxWaypoints = player.maxWaypoints
		end

		if player.reserveSlot then
			settings.reserveSlot = true
		end
	else
		settings = {}
		settings.maxGimmies = 11
		settings.teleportPublicCost = server.teleportPublicCost
		settings.maxWaypoints = server.maxWaypoints
		settings.maxBases = server.maxBases
		settings.allowTeleporting = server.allowTeleporting
		settings.allowGimme = server.allowGimme
		settings.lotteryTicketPrice = server.lotteryTicketPrice
		settings.packCost = server.packCost
		settings.baseCooldown = server.baseCooldown
		settings.packCooldown = server.packCooldown
		settings.teleportCost = server.teleportCost
		settings.allowLottery = server.allowLottery
		settings.waypointCreateCost = server.waypointCreateCost
		settings.deathCost = server.deathCost
		settings.maxProtectedBases = server.maxProtectedBases
		settings.allowShop = server.allowShop
		settings.gimmeZombies = server.gimmeZombies
		settings.hardcore = server.hardcore
		settings.p2pCooldown = server.p2pCooldown
		settings.zombieKillReward = server.zombieKillReward
		settings.waypointCooldown = server.waypointCooldown
		settings.baseCost = server.baseCost
		settings.teleportPublicCooldown = server.teleportPublicCooldown
		settings.pvpAllowProtect = server.pvpAllowProtect
		settings.perMinutePayRate = server.perMinutePayRate
		settings.lotteryMultiplier = server.lotteryMultiplier
		settings.playerTeleportDelay = server.playerTeleportDelay
		settings.returnCooldown = server.returnCooldown
		settings.baseSize = server.baseSize
		settings.waypointCost = server.waypointCost
		settings.allowHomeTeleport = server.allowHomeTeleport
		settings.allowPlayerToPlayerTeleporting = server.allowPlayerToPlayerTeleporting
		settings.allowVisitInPVP = server.allowVisitInPVP
		settings.allowWaypoints = server.allowWaypoints
		settings.reserveSlot = player.reserveSlot
		settings.gimmeRaincheck = server.gimmeRaincheck
		settings.groupID = 0
		settings.groupName = ""
		settings.suicideCost = server.suicideCost
		settings.allowSuicide = server.allowSuicide

		if player.newPlayer then
			settings.mapSize = server.mapSizeNewPlayers
		else
			settings.mapSize = server.mapSizePlayers
		end

		if tonumber(player.maxBases) > tonumber(server.maxBases) then
			settings.maxBases = player.maxBases
		end

		if tonumber(player.maxProtectedBases) > tonumber(server.maxProtectedBases) then
			settings.maxProtectedBases = player.maxProtectedBases
		end

		if tonumber(player.maxWaypoints) > tonumber(server.maxWaypoints) then
			settings.maxWaypoints = player.maxWaypoints
		end

		if player.reserveSlot then
			settings.reserveSlot = true
		end
	end

	return settings
end


function calculateServerTime(timestamp)
	-- given a timestamp, return what the server time was at that time.
	-- if botman.serverTimeSync doesn't exist yet just return the timestamp for the current server time rather than returning nothing or zero

	if botman.serverTimeSync then
		return timestamp + botman.serverTimeSync
	else
		return dateToTimestamp(botman.serverTime)
	end
end


function LookupJoiningPlayer(steam)
	local k, v

	if type(joiningPlayers) == "table" then
		for k, v in pairs(joiningPlayers) do
			if v.steam == steam then
				return v.userID
			end
		end
	else
		return ""
	end
end