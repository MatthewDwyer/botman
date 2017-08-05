--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function isServerHardcore(playerid)
	if server.hardcore and players[playerid] > 2  then
		return true
	else
		return false
	end
end


function makeINI()
	local file

	-- first delete the file
	os.remove(homedir .. "/botman.ini")

	-- now build a new one
	file = io.open(homedir .. "/botman.ini", "a")
	file:write("iniReadOnly=false\n")
	file:write("botOwner=\"0\"\n")
	if telnetPassword then file:write("telnetPassword=\"" .. telnetPassword .. "\"\n") end
	if botman.chatlogPath then file:write("webdavFolder=\"" .. botman.chatlogPath .. "\"\n") end
	file:write("ircPrivate=false\n")
	file:write("ircRestricted=false\n")
	if server.ircServer then file:write("ircServer=\"" .. server.ircServer .. "\"\n") end
	if server.ircPort then file:write("ircPort=" .. server.ircPort .. "\n") end
	if server.ircMain then file:write("ircChannel=\"" .. server.ircMain .. "\"\n") end
	if botDB then file:write("botDB=\"" .. botDB .. "\"\n") end
	if botDBUser then file:write("botDBUser=\"" .. botDBUser .. "\"\n") end
	if botDBPass then file:write("botDBPass=\"" .. botDBPass .. "\"\n") end
	if botsDB then file:write("botsDB=\"" .. botsDB .. "\"\n") end
	if botsDBUser then file:write("botsDBUser=\"" .. botsDBUser .. "\"\n") end
	if botsDBPass then file:write("botsDBPass=\"" .. botsDBPass .. "\"\n") end
	file:close()
end


function readItemsXML(xmlFile)
	local file, ln

	file = io.open(xmlFile, "rb")

	for ln in io.lines(file) do
		lines[#lines + 1] = line
	end

	-- if isFile(homedir .. "/temp/version.txt") then
		-- file = io.open(homedir .. "/temp/version.txt", "r")
		-- codeVersion = file:read "*a"
		-- codeBranch = file:read "*a"
		-- file:close()
end


function runTimedEvents()
	local cursor, errorString, rows

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM timedEvents WHERE nextTime < NOW() AND disabled = 0")

		row = cursor:fetch({}, "a")
		while row do
			if row.timer == "announcements" then
				conn:execute("UPDATE timedEvents SET nextTime = NOW() + " .. row.delayMinutes * 60 .. " WHERE timer = 'announcements'")
				sendNextAnnouncement()
			end

			row = cursor:fetch(row, "a")
		end
	end
end


function sendNextAnnouncement()
	local counter, cursor, errorString, rows

	if (tonumber(botman.playersOnline) == 0) then -- don't bother if nobody is there to see it
		return
	end

	counter = 1

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM announcements")
		rows = cursor:numrows()
		row = cursor:fetch({}, "a")
		while row do
			if tonumber(server.nextAnnouncement) == counter then
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape(row.message) .. "')")
			end

			counter = counter + 1
			row = cursor:fetch(row, "a")
		end
	end

	server.nextAnnouncement = server.nextAnnouncement + 1
	if (server.nextAnnouncement > rows) then server.nextAnnouncement = 1 end
	conn:execute("UPDATE server set nextAnnouncement = " .. server.nextAnnouncement)
end


function getLastCommandIndex(code)
	local cursor,errorString,row

	cursor,errorString = conn:execute("SELECT max(cmdIndex) as lastIndex FROM botCommands WHERE cmdCode = '" .. escape(code) .. "'")
	row = cursor:fetch({}, "a")

	return tonumber(row.lastIndex) + 1
end


function canSetHere(steam, x, z)
	local k, v, dist

	-- check for nearby bases that are not friendly
	for k, v in pairs(players) do
		if (v.homeX ~= nil) and k ~= steam then
				if (v.homeX ~= 0 and v.homeZ ~= 0) then
				dist = distancexz(x, z, v.homeX, v.homeZ)

				if (tonumber(dist) < tonumber(v.protectSize) + 10) then
					if not isFriend(k, steam) then
						return false
					end
				end
			end
		end

		if (v.home2X ~= nil) then
				if (v.home2X ~= 0 and v.home2Z ~= 0) then
				dist = distancexz(x, z, v.home2X, v.home2Z)

				if (dist < tonumber(v.protectSize) + 10) then
					if not isFriend(k, steam) then
						return false
					end
				end
			end
		end
	end

	return true
end


function collectSpawnableItemsList()
	if botman.dbConnected then
		conn:execute("UPDATE spawnableItems SET deleteItem = 1")
	end

	send("li a")
	send("li e")
	send("li i")
	send("li o")
	send("li u")
end


function adminsOnline()
	-- this function helps us choose different actions depending on if an admin is playing or not.
	local k, v

	for k,v in pairs(igplayers) do
		if v.accessLevel < 3 then
			return true
		end
	end

	return false
end


function isDestinationAllowed(steam, x, z)
	local outsideMap, outsideMapDonor, loc

	outsideMap = squareDistance(x, z, server.mapSize)
	outsideMapDonor = squareDistance(x, z, server.mapSize + 5000)
	loc = inLocation(x, z)

	-- prevent player exceeding the map limit unless an admin and ignoreadmins is false
	if outsideMap and not players[steam].donor and (accessLevel(steam) > 3) then
		if not loc then
			return false
		else
			-- check the locations access level restrictions
			if tonumber(locations[loc].accessLevel) < accessLevel(steam) then
				return false
			end
		end
	end

	if outsideMapDonor and (accessLevel(steam) > 3 or not botman.ignoreAdmins) then
		if not loc then
			return false
		else
			-- check the locations access level restrictions
			if tonumber(locations[loc].accessLevel) < accessLevel(steam) then
				return false
			end
		end
	end

	return true
end


function searchBlacklist(IP, name)
	local IPInt

	IPInt = IPToInt(IP)
	cursor,errorString = connBots:execute("SELECT * FROM IPBlacklist WHERE StartIP <=  " .. IPInt .. " AND EndIP >= " .. IPInt)
	row = cursor:fetch({}, "a")

	if row then
		if igplayers[name] then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Found in blacklist.  startIP = " .. row.StartIP .. ", endIP = " .. row.EndIP .. "[-]")
		else
			irc_chat(name, "Found in blacklist.  startIP = " .. row.StartIP .. ", endIP = " .. row.EndIP)
		end
	else
		if igplayers[name] then
			message("pm " .. steam .. " [" .. server.chatColour .. "]" .. IP .. " is not in the blacklist.[-]")
		else
			irc_chat(name, IP .. " is not in the blacklist.")
		end
	end
end


function savePlayers()
	local k,v

	for k,v in pairs(igplayers) do
		savePlayerData(k)
	end
end


function setChatColour(steam)
	if accessLevel(steam) > 3 and accessLevel(steam) < 11 then
		send("cpc " .. steam .. " " .. server.chatColourDonor .. " 1")
	end

	if accessLevel(steam) == 0 then
		send("cpc " .. steam .. " " .. server.chatColourOwner .. " 1")
	end

	if accessLevel(steam) == 1 then
		send("cpc " .. steam .. " " .. server.chatColourAdmin .. " 1")
	end

	if accessLevel(steam) == 2 then
		send("cpc " .. steam .. " " .. server.chatColourMod .. " 1")
	end

	if accessLevel(steam) == 90 then
		send("cpc " .. steam .. " " .. server.chatColourPlayer .. " 1")
	end

	if accessLevel(steam) == 99 then
		send("cpc " .. steam .. " " .. server.chatColourNewPlayer .. " 1")
	end

	if players[steam].prisoner then
		send("cpc " .. steam .. " " .. server.chatColourPrisoner .. " 1")
	end
end


function isLocationOpen(loc)
	local timeOpen, timeClosed, isOpen, gameHour

	gameHour = tonumber(server.gameHour)
	timeOpen = tonumber(locations[loc].timeOpen)
	timeClosed = tonumber(locations[loc].timeClosed)
	isOpen = true

	-- check the location for opening and closing times
	if tonumber(locations[loc].dayClosed) > 0 then
		if ((server.gameDay + 7 - locations[loc].dayClosed) % 7 == 0) then
			return false
		end
	end

	if timeOpen == timeClosed then
		isOpen = true
	else
		if timeOpen < timeClosed then
			if gameHour >= timeClosed then
				isOpen = false
			end

			if gameHour < timeOpen then
				isOpen = false
			end
		 else
			if gameHour >= timeClosed then
				isOpen = false
			end

			if gameHour >= timeOpen then
				isOpen = true
			end
		 end
	end

	return isOpen
end


function countGBLBans(steam)
	players[steam].GBLBans = 0

	cursor,errorString = connBots:execute("SELECT count(GBLBan) as totalBans FROM bans WHERE steam = '" .. steam .. "'")
	row = cursor:fetch({}, "a")
	players[steam].GBLBans = tonumber(row.totalBans)
end


function windowMessage(window, message, override)
	if server.enableWindowMessages or override then
		cecho(window, message)
	end
end


function scanForPossibleHackersNearby(steam, world)
	local k,v,dist,msg

	dist = 0

	for k,v in pairs(igplayers) do
		if (tonumber(players[k].hackerScore) > 20) and players[k].newPlayer then
			if world == nil then
				dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, v.xPos, v.zPos)
			end

			if dist < 301 then
				if locations["exile"] then
					players[k].exiled = 1
					players[k].silentBob = true
					players[k].canTeleport = false
					if botman.dbConnected then conn:execute("UPDATE players SET exiled = 1, silentBob = 1, canTeleport = 0 WHERE steam = " .. k) end

					if world ~= nil then
						msg = v.name .. " has been sent to exile, detected with a non-zero hacker score."
					else
						msg = v.name .. " has been sent to exile, detected near " .. players[steam].name .. " with a non-zero hacker score."
					end

					message("say [" .. server.alertColour .. "]" .. msg .. "[-]")
					irc_chat(server.ircAlerts, msg)
				else
					timeoutPlayer(k, "auto by bot for a non-zero hacker score", false)
				end
			end
		end
	end
end


function registerHelp()
	if botman.dbConnected then conn:execute("insert into helpCommands (command, description, keywords, accessLevel, ingameOnly) values ('" .. escape(tmp.command) .. "','" .. escape(tmp.description) .. "','" .. escape(tmp.keywords) .. "'," .. tmp.accessLevel .. "," .. tmp.ingameOnly .. ")") end
	tmp.commandID = tonumber(tmp.commandID) + 1
	if botman.dbConnected then conn:execute("insert into helpTopicCommands (topicID, commandID) values (" .. tmp.topicID .. "," .. tmp.commandID .. ")") end
end


function isValidSteamID(steam)
	-- here we're testing 2 things.  that the id is numeric and that it contains 17 digits
	-- I'm also testing that it begins with 7656.  As far as I know all Steam keys begin with this.

	if ToInt(steam) == nil then
		return false
	end

	if string.len(steam) ~= 17 then
		return false
	end

	if string.sub(steam, 1, 4) ~= "7656" then
		return false
	end

	return true
end


function removeBadPlayerRecords()
	local k,v

	for k,v in pairs(players) do
		if (tonumber(v.id) < 1) then
			igplayers[k] = nil
			players[k] = nil
		end
	end

	if botman.dbConnected then conn:execute("DELETE FROM players WHERE id < 1") end
end


function timeRemaining(finishTime)
	local diff, days, hours, minutes

	diff = os.difftime(finishTime, os.time())
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (hours > 0) then
		diff = diff - (hours * 3600)
	end

	minutes = math.floor(diff / 60)

	return days, hours, minutes
end


function alertSpentMoney(steam, amount)
	if server.alertSpending then
		message("pm " .. steam .. " [" .. server.warnColour .. "]You spent " .. amount .. " " .. server.moneyPlural .. "[-]")
	end
end


function fixBot()
	fixMissingStuff()
	fixShop()
	enableTimer("ReloadScripts")
	getServerData()

	-- join the irc server
	if botman.customMudlet then
		joinIRCServer()
	end
end


function addFriend(player, friend, auto)
	if auto == nil then auto = false end

	-- give a player a friend (yay!)
	-- returns true if a friend was added or false if already friends with them

	if (not string.find(friends[player].friends, friend)) then
		if auto then
			if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. player .. "," .. friend .. ", 1)") end
		else
			if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. player .. "," .. friend .. ", 0)") end
		end

		friends[player].friends = friends[player].friends .. "," .. friend
		return true
	else
		return false
	end
end


function getFriends(line)
	local pid, fpid, i, temp, max

	temp = string.split(line, ",")
	pid = string.trim(string.sub(temp[1], 14, 30))
	fpid = string.trim(string.sub(temp[2], 10, 26))

	-- delete auto-added friends from the MySQL table
	if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = " .. pid .. " AND autoAdded = 1") end

	-- add friends read from Coppi's lpf command
	-- grab the first one
	if not string.find(friends[pid].friends, fpid) then
		addFriend(pid, fpid, true)
	else
		if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. pid .. "," .. fpid .. ", 1)") end
	end

	-- grab the rest
	max = table.maxn(temp)
	for i=3,max,1 do
		fpid = string.trim(temp[i])
		if not string.find(friends[pid].friends, fpid) then
			addFriend(pid, fpid, true)
		else
			if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. pid .. "," .. fpid .. ", 1)") end
		end
	end
end


function trimLogs()
	local files, file, temp, k, v
	local yearPart, monthPart, dayPart

	files = {}

	for file in lfs.dir(homedir .. "/log") do
		if lfs.attributes(file,"mode") == nil then
			temp = string.split(file, "#")

			if temp[2] ~= nil then
				files[file] = {}
				files[file].delete = false
				files[file].date = temp[1]
				files[file].dateSplit = string.split(temp[1], "-")
			end
		end
	end

	for k,v in pairs(files) do
		if yearPart == nil then
			if v.dateSplit[1] == os.date('%Y') then
				yearPart = 1
			end

			if v.dateSplit[2] == os.date('%Y') then
				yearPart = 2
			end

			if v.dateSplit[3] == os.date('%Y') then
				yearPart = 3
			end
		end

		if dayPart == nil then
			if tonumber(v.dateSplit[1]) > 12 and yearPart ~= 1 then
				dayPart = 1
			end

			if tonumber(v.dateSplit[2]) > 12 and yearPart ~= 2 then
				dayPart = 2
			end

			if tonumber(v.dateSplit[3]) > 12 and yearPart ~= 3 then
				dayPart = 3
			end
		end

		if yearPart ~= nil and dayPart ~= nil then
			monthPart = 1

			if yearPart == 1 or dayPart == 1 then
				monthPart = 2
			end

			if yearPart == 2 or dayPart == 2 then
				monthPart = 3
			end
		end
	end

	for k,v in pairs(files) do
		fileDate = os.time({year = v.dateSplit[yearPart], month = v.dateSplit[monthPart], day = v.dateSplit[dayPart], hour = 0, min = 0, sec = 0})
		if os.time() - fileDate > 604800 then -- older than 7 days
			os.remove(homedir .. "/log/" .. k)
		end
	end
end

function removeEntities()
	-- remove any entities that are flagged for removal after updating the list
	local k, v
	local maxCount = 0

	for k,v in pairs(otherEntities) do
		if v.remove ~= nil then
			otherEntities[k] = nil
		else
			maxCount = maxCount + 1
		end
	end

	botman.maxOtherEntities = maxCount
end


function updateOtherEntities(entityID, entity)
	local k, v

	if otherEntities == nil then
		otherEntities = {}
	end

	if otherEntities[entityID] == nil then
		-- new entity so add it to otherEntities
		otherEntities[entityID] = {}
		otherEntities[entityID].entity = entity
		otherEntities[entityID].doNotSpawn = false
	else
		-- not new eneity but entityID for this entity has changed so look for and remove the old entity and add it with the new entityID
		if otherEntities[entityID].entity ~= entity then
			for k,v in pairs(otherEntities) do
				if v.entity == entity then
					otherEntities[k] = nil
				end
			end

			-- now add the entity again with the new entityID
			otherEntities[entityID] = {}
			otherEntities[entityID].entity = entity
			otherEntities[entityID].doNotSpawn = false
			otherEntities[entityID].remove = nil
		end
	end
end


function removeZombies()
	-- remove any zombies that are flagged for removal after updating the list
	local k, v
	local maxCount = 0

	for k,v in pairs(gimmeZombies) do
		if v.remove then
			gimmeZombies[k] = nil
		else
			maxCount = maxCount + 1
		end
	end

	botman.maxGimmeZombies = maxCount
end


function updateGimmeZombies(entityID, zombie)
	local k, v

	if gimmeZombies[entityID] == nil then
		-- new zombie so add it to gimmeZombies
		gimmeZombies[entityID] = {}
		gimmeZombies[entityID].zombie = zombie
		gimmeZombies[entityID].minPlayerLevel = 1
		gimmeZombies[entityID].minArenaLevel = 1
		gimmeZombies[entityID].bossZombie = false
		gimmeZombies[entityID].doNotSpawn = false

		if string.find(zombie, "cop") or string.find(zombie, "Cop") or string.find(zombie, "dog") or string.find(zombie, "Bear") or string.find(zombie, "Feral") or string.find(zombie, "Radiated") or string.find(zombie, "Behemoth") or string.find(zombie, "Template") then
			gimmeZombies[entityID].doNotSpawn = true
			if botman.dbConnected then conn:execute("UPDATE gimmeZombies set bossZombie = 0, doNotSpawn = 1 WHERE entityID = " .. entityID) end
		else
			if botman.dbConnected then conn:execute("UPDATE gimmeZombies set bossZombie = 0, doNotSpawn = 0 WHERE entityID = " .. entityID) end
		end

		gimmeZombies[entityID].maxHealth = 0
	else
		-- not new zombie but entityID for this zombie has changed so look for and remove the old zombie and add it with the new entityID
		if gimmeZombies[entityID].zombie ~= zombie then
			for k,v in pairs(gimmeZombies) do
				if v.zombie == zombie then
					gimmeZombies[k] = nil
				end
			end

			-- now add the zombie again with the new entityID
			gimmeZombies[entityID] = {}
			gimmeZombies[entityID].zombie = zombie
			gimmeZombies[entityID].minPlayerLevel = 1
			gimmeZombies[entityID].minArenaLevel = 1
			gimmeZombies[entityID].bossZombie = false
			gimmeZombies[entityID].doNotSpawn = false

			if string.find(zombie, "cop") or string.find(zombie, "Cop") or string.find(zombie, "dog") or string.find(zombie, "Bear") or string.find(zombie, "Feral") or string.find(zombie, "Radiated") or string.find(zombie, "Behemoth") or string.find(zombie, "Template") then
				gimmeZombies[entityID].doNotSpawn = true
				if botman.dbConnected then conn:execute("UPDATE gimmeZombies set bossZombie = 0, doNotSpawn = 1 WHERE entityID = " .. entityID) end
			else
				if botman.dbConnected then conn:execute("UPDATE gimmeZombies set bossZombie = 0, doNotSpawn = 0 WHERE entityID = " .. entityID) end
			end

			gimmeZombies[entityID].maxHealth = 0
			gimmeZombies[entityID].remove = nil
		end
	end
end

function restrictedCommandMessage()
	local r

	chatvars.restrictedCommand = true

	if not igplayers[chatvars.playerid].restrictedCommand then
		igplayers[chatvars.playerid].restrictedCommand = true
		return("This command is restricted")
	else
		r = rand(16)
		if r == 1 then return("It's still restricted") end
		if r == 2 then return("This command is not happening") end
		if r == 3 then return("Which part of NO are you having trouble with?") end
		if r == 4 then return("You again?") end
		if r == 5 then return("We've been over this. N. O.") end
		if r == 6 then return("no No NO!") end
		if r == 7 then return("Have this command you shall not.") end
		if r == 8 then return("Seriously?") end
		if r == 9 then return("This command is not for you.") end
		if r == 10 then return("Denied!") end
		if r == 11 then return("Give up.  You aren't using this command.") end

		if r == 12 then
			send("give " .. igplayers[chatvars.playerid].id .. " turd 1")
			return("I don't give a shit. That was a lie, but you're still not using this command.")
		end

		if r == 13 then return("Bored now.") end
		if r == 14 then return("[DENIED]  [DENI[DEN[DENIED]ENIED]NIED]  [DENIED]") end
		if r == 15 then return("A bit slow are we? Noooooooooooooooo.") end
		if r == 16 then return("Yyyyyyeeee No.") end
	end
end


function downloadHandler(event, ...)
   if event == "sysDownloadDone" then
      finishDownload(...)
   elseif event == "sysDownloadError" then
	   failDownload(...)
	end
end


function finishDownload(filePath)
	dbugi("download complete.  reading file..")

	local file, ln, codeVersion, codeBranch

	if isFile(homedir .. "/temp/version.txt") then
		file = io.open(homedir .. "/temp/version.txt", "r")
		codeVersion = file:read "*a"
		codeBranch = file:read "*a"
		file:close()

		dbugi("codeVersion " .. codeVersion)
		dbugi("codeBranch " .. codeBranch)
	end
end


function failDownload(filePath)

end


function isReservedName(player, steam)
	local k, v, pos

	-- strip any trailing (1) or other numbers in brackets
	if string.find(player, "%(%d+%)$") then
		player = string.sub(player, 1, string.find(player, "%(%d+%)$") - 1)
	end

	for k,v in pairs(players) do
		if (v.name == player) and (k ~= steam) then
			if tonumber(v.accessLevel) < 3 then
				return true
			end

			if tonumber(v.accessLevel) ~= tonumber(accessLevel(steam)) and igplayers[k] then
				return true
			end
		end
	end

	return false
end


function inWhitelist(steam)
	local cursor, errorString, row

	-- is the player in the whitelist?
	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM whitelist WHERE steam = " .. steam)
		row = cursor:fetch({}, "a")

		if row then
			return true
		else
			return false
		end
	else
		return false
	end
end


function atHome(steam)
	local dist, size, greet, home, time, r

	greet = false
	home = false

	if players[steam].lastAtHome == nil then
		players[steam].lastAtHome = os.time()
	end

	-- base 1
	if math.abs(players[steam].homeX) > 0 and math.abs(players[steam].homeZ) > 0 then
		dist = distancexz(math.floor(players[steam].xPos), math.floor(players[steam].zPos), players[steam].homeX, players[steam].homeZ)
		size = tonumber(players[steam].protectSize)

		if (dist <= size + 30) then
			home = true

			if not players[steam].atHome then
				greet = true
			end
		end
	end

	-- base 2
	if math.abs(players[steam].home2X) > 0 and math.abs(players[steam].home2Z) > 0 then
		dist = distancexz(math.floor(players[steam].xPos), math.floor(players[steam].zPos), players[steam].home2X, players[steam].home2Z)
		size = tonumber(players[steam].protect2Size)

		if (dist <= size + 30) then
			home = true

			if not players[steam].atHome then
				greet = true
			end
		end
	end

	if greet then
		time = os.time() - players[steam].lastAtHome

		if time > 300 and time <= 900 then
			r = rand(5)
			if r == 1 then message("pm " .. steam .. " [" .. server.chatColour .. "]Welcome home " .. players[steam].name .. "[-]") end
			if r == 2 then message("pm " .. steam .. " [" .. server.chatColour .. "]Back so soon " .. players[steam].name .. "?[-]") end
			if r == 3 then message("pm " .. steam .. " [" .. server.chatColour .. "]You're back![-]") end
			if r == 4 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home sweet home :)[-]") end
			if r == 5 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home again[-]") end
		end

		if time > 900 and time <= 1800 then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You're back " .. players[steam].name .. "! Welcome home :)[-]")
		end

		if time > 1800 and time <= 3600 then
			r = rand(5)
			if r == 1 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home at last " .. players[steam].name .. "![-]") end
			if r == 2 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home again, home again. Ziggity zig.[-]") end
			if r == 3 then message("pm " .. steam .. " [" .. server.chatColour .. "]Look what the cat dragged in.  Hello " .. players[steam].name .. "[-]") end
			if r == 4 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home at last " .. players[steam].name .. "![-]") end
			if r == 5 then message("pm " .. steam .. " [" .. server.chatColour .. "]You're back! So nice of you to drop by.[-]") end
		end

		if time > 3600 then
			message("pm " .. steam .. " [" .. server.chatColour .. "]So you decided to come home " .. players[steam].name .. "?[-]")
			message("pm " .. steam .. " [" .. server.chatColour .. "]Dinner's on the floor.[-]")
			r = rand(5)
			if r == 1 then send("give " .. steam .. " canDogfood 1") end
			if r == 2 then send("give " .. steam .. " canCatfood 1") end
			if r == 3 then send("give " .. steam .. " femur 1") end
			if r == 4 then send("give " .. steam .. " vegetableStew 1") end
			if r == 5 then send("give " .. steam .. " meatStew 1") end
		end
	end

	if home then
		players[steam].atHome = true
		players[steam].lastAtHome = os.time()
	else
		players[steam].atHome = false
	end
end


function calcTimestamp(str)
	-- takes input like 1 week, 1 month, 1 year and outputs a timestamp that much in the future
	local number, period

	str = string.lower(str)
	number = math.abs(math.floor(tonumber(string.match(str, "(-?%d+)"))))

	if string.find(str, "minute") then
		period = 60
	end

	if string.find(str, "hour") then
		period = 60 * 60
	end

	if string.find(str, "day") then
		period = 60 * 60 * 24
	end

	if string.find(str, "week") then
		period = 60 * 60 * 24 * 7
	end

	if string.find(str, "month") then
		period = 60 * 60 * 24 * 30
	end

	if string.find(str, "year") then
		period = 60 * 60 * 24 * 365
	end

	if number == nil or period == nil then
		return os.time()
	else
		return os.time() + period * number
	end
end


function countAlphaNumeric(test)
	local count
	-- return the number of alphanumeric characters in test

	local _, count = string.gsub(test, "%w", "")
	return count
end


function pmsg(msg, all)
	local k,v

	-- queue msg for output by a timer
	for k,v in pairs(igplayers) do
		if all ~= nil or players[k].noSpam == false then
			if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. k .. ",'" .. escape(msg) .. ")") end
		end
	end
end


function strDateToTimestamp(strdate)
	-- Unix timestamps end in 2038.  To prevent invalid dates, we will force year to 2030 if it is later.
	local sday, smonth, syear, shour, sminute, sseconds = strdate:match("(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)")

	-- don't allow dates over 2030.  timestamps stop at 2038
	if tonumber(syear) > 2030 then syear = 2030 end

	return os.time({year = syear, month = smonth, day = sday, hour = shour, min = sminute, sec = sseconds})
end


function getEquipment(equipment, item)
	-- search the most recent inventory recording for an item and if found return how much there is and best quality if applicable
	local tbl, test, i, found, quantity, quality, max

	found = false
	quality = 0
	quantity = 0
	tbl = string.split(equipment, "|")

	max = table.maxn(tbl)
	for i=1, max, 1 do
		test = string.split(tbl[i], ",")

		if test[2] == item then
			found = true

			if tonumber(test[3]) > tonumber(quality) then
				quality = tonumber(test[3])
			end
		end
	end

	if found then
		return true, quality
	else
		return false, 0
	end
end


function getInventory(inventory, item)
	-- search the most recent inventory recording for an item and if found return how much there is and best quality if applicable
	local tbl, test, i, found, quantity, quality, max

	found = false
	quality = 0
	quantity = 0
	tbl = string.split(inventory, "|")

	max = table.maxn(tbl)
	for i=1, max, 1 do
		test = string.split(tbl[i], ",")
		if test[3] == item then
			found = true
			quantity = quantity + tonumber(test[2])

			if tonumber(test[4]) > tonumber(quality) then
				quality = tonumber(test[4])
			end
		end
	end

	if found then
		return true, quantity, quality
	else
		return false, 0 , 0
	end
end


function inInventory(steam, item, quantity, slot)
	-- search the most recent inventory recording for an item
	local tbl, test, i, max

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .."  ORDER BY inventoryTrackerID DESC Limit 0, 1")
		row = cursor:fetch({}, "a")

		tbl = string.split(row.belt .. row.pack .. row.equipment, "|")

		max = table.maxn(tbl)
		for i=1, max, 1 do
			test = string.split(tbl[i], ",")
			if slot ~= nil then
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item and tonumber(test[1]) == slot then
					return true
				end
			else
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item then
					return true
				end
			end
		end
	end

	return false
end


function inBelt(steam, item, quantity, slot)
	-- search the most recent inventory recording for an item in the belt
	local tbl, test, i, max

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .."  ORDER BY inventoryTrackerID DESC Limit 0, 1")
		row = cursor:fetch({}, "a")

		tbl = string.split(row.belt, "|")

		max = table.maxn(tbl)
		for i=1, max, 1 do
			test = string.split(tbl[i], ",")
			if slot ~= nil then
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item and tonumber(test[1]) == slot then
					return true
				end
			else
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item then
					return true
				end
			end
		end
	end

	return false
end


function mapPosition(steam)
	-- express the player's coordinates as a compass bearing
	local ns, ew

	if tonumber(players[steam].xPos) < 0 then
		ew = math.abs(math.floor(players[steam].xPos)).. " W"
	else
		ew = math.floor(players[steam].xPos) .. " E"
	end

	if tonumber(players[steam].zPos) < 0 then
		ns = math.abs(math.floor(players[steam].zPos)) .. " S"
	else
		ns = math.floor(players[steam].zPos) .. " N"
	end

	return ns .. " " .. ew
end


function validPosition(steam, alert)
	-- check that y position is between bedrock and the max build height
	if tonumber(players[steam].yPos) > -1 and tonumber(players[steam].yPos) < 256 then
		return true
	else
		if alert ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You cannot do that here. If you recently teleported, wait a bit then try again.[-]")
		end

		return false
	end
end


function savePosition(steam, temp)
	-- helper function to save the players position
	if tonumber(players[steam].yPos) > -1 and tonumber(players[steam].yPos) < 256 then
		-- store the player's current x y z
		if temp == nil then
			players[steam].xPosOld = math.floor(players[steam].xPos)
			players[steam].yPosOld = math.ceil(players[steam].yPos)
			players[steam].zPosOld = math.floor(players[steam].zPos)

			if botman.dbConnected then conn:execute("UPDATE players SET xPosOld = " .. players[steam].xPosOld .. ", yPosOld = " .. players[steam].yPosOld .. ", zPosOld = " .. players[steam].zPosOld .. " WHERE steam = " .. steam) end
		else
			players[steam].xPosOld2 = math.floor(players[steam].xPos)
			players[steam].yPosOld2 = math.ceil(players[steam].yPos)
			players[steam].zPosOld2 = math.floor(players[steam].zPos)

			if botman.dbConnected then conn:execute("UPDATE players SET xPosOld2 = " .. players[steam].xPosOld2 .. ", yPosOld2 = " .. players[steam].yPosOld2 .. ", zPosOld2 = " .. players[steam].zPosOld2 .. " WHERE steam = " .. steam) end
		end
	end
end


function seen(steam)
	-- when was a player last seen ingame?
	local words, word, diff, ryear, rmonth, rday, rhour, rmin, rsec
	local dateNow, Now, dateSeen, Seen, days, hours, minutes

	if players[steam].seen == "" then
		return "A new player on for the first time now."
	end

	if igplayers[steam] then
		return players[steam].name .. " is on the server now."
	end

	words = {}
	for word in botman.serverTime:gmatch("%w+") do table.insert(words, word) end

	ryear = words[1]
	rmonth = words[2]
	rday = string.sub(words[3], 1, 2)
	rhour = string.sub(words[3], 4, 5)
	rmin = words[4]
	rsec = words[5]

	dateNow = {year=ryear, month=rmonth, day=rday, hour=rhour, min=rmin, sec=rsec}
	Now = os.time(dateNow)

	words = {}
	for word in players[steam].seen:gmatch("%w+") do table.insert(words, word) end

	ryear = words[1]
	rmonth = words[2]
	rday = string.sub(words[3], 1, 2)
	rhour = string.sub(words[3], 4, 5)
	rmin = words[4]
	rsec = words[5]

	dateSeen = {year=ryear, month=rmonth, day=rday, hour=rhour, min=rmin, sec=rsec}
	Seen = os.time(dateSeen)

	diff = os.difftime(Now, Seen)
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (hours > 0) then
		diff = diff - (hours * 3600)
	end

	minutes = math.floor(diff / 60)

	return players[steam].name .. " was last seen " .. days .. " days " .. hours .. " hours " .. minutes .." minutes ago"
end


function messageAdmins(message)
	-- helper function to send a message to all staff
	local k,v

	for k, v in pairs(players) do
		if (accessLevel(k) < 3) then
			if igplayers[k] then
				message("pm " .. k .. " [" .. server.chatColour .. "]" .. message .. "[-]")
			else
				if botman.dbConnected then conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. k .. ", '" .. escape(message) .. "')") end
			end
		end
	end
end


function kick(steam, reason)
	local tmp

	tmp = steam
	-- if there is no player with steamid steam, try looking it up incase we got their name instead of their steam
	if not players[steam] then
		steam = LookupPlayer(string.trim(steam))
		-- restore the original steam value if nothing matched as we may be banning someone who's never played here.
		if steam == nil then steam = tmp end
	end

	if igplayers[steam] then
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','kick','Player " .. steam .. " " .. escape(players[steam].name) .. " kicked for " .. escape(reason) .. "'," .. steam .. ")") end
	end

	send("kick " .. steam .. " " .. " \"" .. reason .. "\"")
	botman.playersOnline = botman.playersOnline - 1
	irc_chat(server.ircMain, "Player " .. players[steam].name .. " kicked. Reason: " .. reason)
end


function banPlayer(steam, duration, reason, issuer, gblBan, localOnly)
	local tmp, admin, belt, pack, equipment, country

	--TODO: Add GBL ban save

	if accessLevel(steam) < 3 then
		irc_chat(server.ircAlerts, "Request to ban admin " .. players[steam].name .. " rejected.  I will not ban admins.")
		message("pm " .. issuer .. " [" .. server.chatColour .. "]Request to ban admin " .. players[steam].name .. " rejected.  I will not ban admins.[-]")
		return
	end

	belt = ""
	pack = ""
	equipment = ""
	country = ""

	if reason == nil then
		reason = "banned"
	end

	if string.len(issuer) > 10 then
		admin = issuer
	else
		admin = 0
	end

	tmp = steam
	-- if there is no player with steamid steam, try looking it up incase we got their name instead of their steam
	if not players[steam] then
		steam = LookupPlayer(string.trim(steam))
		-- restore the original steam value if nothing matched as we may be banning someone who's never played here.
		if steam == nil then steam = tmp end
	end

	send("ban add " .. steam .. " " .. duration .. " \"" .. reason .. "\"")

	-- grab their belt, pack and equipment
	if players[steam] then
		country = players[steam].country

		if botman.dbConnected then
			cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .." ORDER BY inventoryTrackerid DESC Limit 1")
			row = cursor:fetch({}, "a")
			if row then
				belt = row.belt
				pack = row.pack
				equipment = row.equipment
			end

			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','ban','Player " .. steam .. " " .. escape(players[steam].name) .. " has has been banned for " .. duration .. " for " .. escape(reason) .. "'," .. steam .. ")")
		end

		irc_chat(server.ircMain, "[BANNED] Player " .. steam .. " " .. players[steam].name .. " has been banned for " .. duration .. " " .. reason)
		irc_chat(server.ircAlerts, "[BANNED] Player " .. steam .. " " .. players[steam].name .. " has been banned for " .. duration .. " " .. reason)
		alertAdmins("Player " .. players[steam].name .. " has been banned for " .. duration .. " " .. reason)

		-- add to bots db
		if botman.db2Connected and not localOnly then
			if tonumber(players[steam].pendingBans) > 0 then
				connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin, GBLBan, GBLBanActive) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "'," .. tonumber(players[steam].timeOnServer) + tonumber(players[steam].playtime) .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].zombies .. ",'" .. players[steam].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "',1,1)")
				irc_chat(server.ircMain, "Player " .. steam .. " " .. players[steam].name .. " has been globally banned.")
				message("say [" .. server.alertColourColour .. "]" .. players[id].name .. " has been globally banned.[-]")
			else
				connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "'," .. tonumber(players[steam].timeOnServer) + tonumber(players[steam].playtime) .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].zombies .. ",'" .. players[steam].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "')")
			end
		end

		send("llp " .. steam)

		-- Look for and also ban ingame players with the same IP
		for k,v in pairs(igplayers) do
			if players[k].IP == players[steam].IP and k ~= steam then
				send("ban add " .. k .. " " .. duration .. " \"same IP as banned player\"")

				if botman.dbConnected then
					cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. k .." ORDER BY inventoryTrackerid DESC Limit 1")
					row = cursor:fetch({}, "a")
					if row then
						belt = row.belt
						pack = row.pack
						equipment = row.equipment
					end

					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[k].xPos) .. "," .. math.ceil(players[k].yPos) .. "," .. math.floor(players[k].zPos) .. ",'" .. botman.serverTime .. "','ban','Player " .. k .. " " .. escape(players[k].name) .. " has has been banned for " .. duration .. " for " .. escape("same IP as banned player") .. "'," .. k .. ")")
				end

				irc_chat(server.ircMain, "[BANNED] Player " .. k .. " " .. players[k].name .. " has been banned for " .. duration .. " same IP as banned player")
				irc_chat(server.ircAlerts, "[BANNED] Player " .. k .. " " .. players[k].name .. " has been banned for " .. duration .. " same IP as banned player")
				alertAdmins("Player " .. players[k].name .. " has been banned for " .. duration .. " same IP as banned player")

				-- add to bots db
				if botman.db2Connected then
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin) VALUES ('" .. escape("MISSING") .. "'," .. k .. ",'" .. escape("same IP as banned player") .. "'," .. tonumber(players[k].timeOnServer) + tonumber(players[k].playtime) .. "," .. players[k].score .. "," .. players[k].playerKills .. "," .. players[k].zombies .. ",'" .. players[k].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "')")
				end
			end
		end
	else
		-- handle unknown steam id
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','ban','Player " .. steam .. " " .. steam .. " has has been banned for " .. duration .. " for " .. escape(reason) .. "'," .. steam .. ")") end
		irc_chat(server.ircMain, "[BANNED] Unknown player " .. steam .. " has been banned for " .. duration .. " " .. reason)
		irc_chat(server.ircAlerts, "[BANNED] Unknown player " .. steam .. " has been banned for " .. duration .. " " .. reason)

		-- add to bots db
		if botman.db2Connected then
			connBots:execute("INSERT INTO bans (bannedTo, steam, reason, permanent, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "',1,0,0,0,0,'','','','','" .. server.botID .. "','" .. admin .. "')")
		end
	end
end


function arrest(steam, reason, bail, releaseTime)
	local banTime = 60
	local cmd

	if tonumber(server.maxPrisonTime) > 0 then
		banTime = server.maxPrisonTime
	end

	if not locations["prison"] then
		message("say [" .. server.alertColour .. "]" .. players[steam].name .. " has been banned for " .. banTime .. " minutes for " .. reason .. ".[-]")
		banPlayer(steam, banTime .. " minutes", reason, "")
		return
	end

	players[steam].prisoner = true

	if releaseTime ~= nil then
		players[steam].prisonReleaseTime = os.time() + (releaseTime * 60)
	else
		players[steam].prisonReleaseTime = os.time() + (server.maxPrisonTime * 60)
	end

	if igplayers[steam] then
		players[steam].prisonxPosOld = math.floor(igplayers[steam].xPos)
		players[steam].prisonyPosOld = math.ceil(igplayers[steam].yPos)
		players[steam].prisonzPosOld = math.floor(igplayers[steam].zPos)
		igplayers[steam].xPosOld = math.floor(igplayers[steam].xPos)
		igplayers[steam].yPosOld = math.floor(igplayers[steam].yPos)
		igplayers[steam].zPosOld = math.floor(igplayers[steam].zPos)
		igplayers[steam].xPosLastOK = locations["prison"].x
		igplayers[steam].yPosLastOK = locations["prison"].y
		igplayers[steam].zPosLastOK = locations["prison"].z
		irc_chat(server.ircAlerts, players[steam].name .. " has been sent to prison for " .. reason .. " at " .. igplayers[steam].xPosOld .. " " .. igplayers[steam].yPosOld .. " " .. igplayers[steam].zPosOld)
		setChatColour(steam)
	else
		players[steam].prisonxPosOld = math.floor(players[steam].xPos)
		players[steam].prisonyPosOld = math.ceil(players[steam].yPos)
		players[steam].prisonzPosOld = math.floor(players[steam].zPos)
		players[steam].xPosOld = math.floor(players[steam].xPos)
		players[steam].yPosOld = math.floor(players[steam].yPos)
		players[steam].zPosOld = math.floor(players[steam].zPos)
		irc_chat(server.ircAlerts, players[steam].name .. " has been sent to prison for " .. reason .. " at " .. players[steam].xPosOld .. " " .. players[steam].yPosOld .. " " .. players[steam].zPosOld)
	end

	players[steam].bail = bail

	if accessLevel(steam) > 2 and (tonumber(bail) == 0) then
		players[steam].silentBob = true
		if botman.dbConnected then conn:execute("UPDATE players SET prisoner = 1, silentBob = 1, bail = 0, prisonReleaseTime = " .. players[steam].prisonReleaseTime .. ", prisonxPosOld = " .. players[steam].prisonxPosOld .. ", prisonyPosOld = " .. players[steam].prisonyPosOld .. ", prisonzPosOld = " .. players[steam].prisonzPosOld .. " WHERE steam = " .. steam) end
	else
		if botman.dbConnected then conn:execute("UPDATE players SET prisoner = 1, bail = " .. bail .. ", prisonReleaseTime = " .. players[steam].prisonReleaseTime .. ", prisonxPosOld = " .. players[steam].prisonxPosOld .. ", prisonyPosOld = " .. players[steam].prisonyPosOld .. ", prisonzPosOld = " .. players[steam].prisonzPosOld .. " WHERE steam = " .. steam) end
	end

	if botman.dbConnected then
		cursor,errorString = conn:execute("select * from locationSpawns where location='prison'")
		rows = cursor:numrows()

		if rows > 0 then
			randomTP(steam, "prison")
		else
			cmd = "tele " .. steam .. " " .. locations["prison"].x .. " " .. locations["prison"].y .. " " .. locations["prison"].z
			teleport(cmd, steam)
		end
	else
		cmd = "tele " .. steam .. " " .. locations["prison"].x .. " " .. locations["prison"].y .. " " .. locations["prison"].z
		teleport(cmd, steam)
	end

	message("say [" .. server.warnColour .. "]" .. players[steam].name .. " has been sent to prison for " .. reason .. ".[-]")
	message("pm " .. steam .. " [" .. server.chatColour .. "]You are confined to prison until released.[-]")

	if tonumber(bail) > 0 then
		message("pm " .. steam .. " [" .. server.chatColour .. "]You can release yourself for " .. bail .. " " .. server.moneyPlural .. ".[-]")
		message("pm " .. steam .. " [" .. server.chatColour .. "]Type " .. server.commandPrefix .. "bail to release yourself if you have the " .. server.moneyPlural .. ".[-]")
	end

	if releaseTime ~= nil then
		days, hours, minutes = timeRemaining(os.time() + (releaseTime * 60))
		message("pm " .. steam .. " [" .. server.chatColour .. "]You will be released in " .. days .. " days " .. hours .. " hours and " .. minutes .. " minutes.[-]")
	else
		if tonumber(server.maxPrisonTime) > 0 then
			days, hours, minutes = timeRemaining(os.time() + (server.maxPrisonTime * 60))
			message("pm " .. steam .. " [" .. server.chatColour .. "]You will be released in " .. days .. " days " .. hours .. " hours and " .. minutes .. " minutes.[-]")
		end
	end

	if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','prison','Player " .. steam .. " " .. escape(players[steam].name) .. " has has been sent to prison for " .. escape(reason) .. "'," .. steam .. ")") end
end


function timeoutPlayer(steam, reason, bot)
	-- if the player is not already in timeout, send them there.
	if players[steam].timeout == false and players[steam].botTimeout == false then
		players[steam].timeout = true
		if accessLevel(steam) > 2 then players[steam].silentBob = true end
		if bot then players[steam].botTimeout = true end -- the bot initiated this timeout
		-- record their position for return
		players[steam].xPosTimeout = math.floor(players[steam].xPos)
		players[steam].yPosTimeout = math.ceil(players[steam].yPos) + 1
		players[steam].zPosTimeout = math.floor(players[steam].zPos)

		if botman.dbConnected then
			conn:execute("UPDATE players SET timeout = 1, botTimeout = " .. dbBool(bot) .. ", xPosTimeout = " .. players[steam].xPosTimeout .. ", yPosTimeout = " .. players[steam].yPosTimeout .. ", zPosTimeout = " .. players[steam].zPosTimeout .. " WHERE steam = " .. steam)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','timeout','Player " .. steam .. " " .. escape(players[steam].name) .. " has has been sent to timeout for " .. escape(reason) .. "'," .. steam .. ")")
		end

		-- then teleport the player to timeout
		players[steam].tp = 1
		players[steam].hackerTPScore = 0

		send("tele " .. steam .. " " .. players[steam].xPosTimeout .. " 50000 " .. players[steam].zPosTimeout)

		message("say [" .. server.chatColour .. "]Sending player " .. players[steam].name .. " to timeout for " .. reason .. "[-]")
		irc_chat(server.ircAlerts, "[TIMEOUT] Player " .. steam .. " " .. players[steam].name .. " has been sent to timeout for " .. reason)
	end
end


function checkRegionClaims(x, z)
	local cursor, errorString, row

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM keystones WHERE floor(x / 512) =  " .. x .. " AND floor(z / 512) = " .. z)
		row = cursor:fetch({}, "a")
		while row do
			if row.remove == "1" then
				send("rlp " .. row.x .. " " .. row.y .. " " .. row.z)
				conn:execute("UPDATE keystones SET remove = 2 WHERE steam = " .. row.steam .. " AND x = " .. row.x .. " AND y = " .. row.y .. " AND z = " .. row.z )
			end

			row = cursor:fetch(row, "a")
		end
	end
end


function dbWho(ownerid, x, y, z, dist, days, hours, height, ingame)
	local cursor, errorString,row, counter

	if days == nil then days = 1 end
	if height == nil then height = 5 end

	if not botman.dbConnected then
		return
	end

	conn:execute("DELETE FROM searchResults WHERE owner = " .. ownerid)

	if hours > 0 then
		cursor,errorString = conn:execute("select distinct steam, session from tracker where abs(x - " .. x .. ") < " .. dist .. " and abs(z - " .. z .. ") < " .. dist .. " and abs(y - " .. y .. ") < " .. height .. " and timestamp >= '" .. os.date("%Y-%m-%d %H:%M:%S", os.time() - (tonumber(hours) * 3600)) .. "'")
	else
		cursor,errorString = conn:execute("select distinct steam, session from tracker where abs(x - " .. x .. ") < " .. dist .. " and abs(z - " .. z .. ") < " .. dist .. " and abs(y - " .. y .. ") < " .. height .. " and timestamp >= '" .. os.date("%Y-%m-%d %H:%M:%S", os.time() - (tonumber(days) * 86400)) .. "'")
	end

	row = cursor:fetch({}, "a")
	counter = 1
	rows = cursor:numrows()

	if igplayers[ownerid] == nil then
		if rows > 50 then
			irc_chat(ownerid, "****** Report length " .. rows .. " rows.  Cancel it with: nuke irc ******")
		end
	end

	while row do
		conn:execute("INSERT INTO searchResults (owner, steam, session, counter) VALUES (" .. ownerid .. "," .. row.steam .. "," .. row.session .. "," .. counter .. ")")

		if ingame then
			message("pm " .. ownerid .. " [" .. server.chatColour .. "] #" .. counter .." " .. row.steam .. " " .. players[row.steam].id .. " " .. players[row.steam].name .. " sess: " .. row.session .. "[-]")
		else
			irc_chat(ownerid, "#" .. counter .." " .. row.steam .. " " .. players[row.steam].name .. " sess: " .. row.session)
		end

		counter = counter + 1
		row = cursor:fetch(row, "a")
	end
end


function dailyMaintenance()
	-- put something here to be run when the server date hits midnight
	updateBot()

	-- update the list of claims
	send("llp")

	-- purge old tracking data and set a flag so we can tell when the database maintenance is complete.
	if tonumber(server.trackingKeepDays) > 0 then
		conn:execute("UPDATE server set databaseMaintenanceFinished = 0")
		deleteTrackingData(server.trackingKeepDays)
	end

	return true
end


function startReboot()
	-- add a random delay to mess with dupers
	local rnd = rand(10)

	send("sa")
	botman.rebootTimerID = tempTimer( 5 + rnd, [[finishReboot()]] )
end


function clearRebootFlags()
	botman.nextRebootTest = os.time() + 60
	botman.scheduledRestart = false
	botman.scheduledRestartTimestamp = os.time()
	botman.scheduledRestartPaused = false
	botman.scheduledRestartForced = false
end


function finishReboot()
	local k, v

	tempTimer( 30, [[clearRebootFlags()]] )

	if (botman.rebootTimerID ~= nil) then
		killTimer(botman.rebootTimerID)
		botman.rebootTimerID = nil
	end

	if (rebootTimerDelayID ~= nil) then
		killTimer(rebootTimerDelayID)
		rebootTimerDelayID = nil
	end

	for k, v in pairs(igplayers) do
		kick(k, "Server restarting.")
	end

	botman.ignoreAdmins = true
	send("shutdown")

	-- flag all players as offline
	connBots:execute("UPDATE players set online = 0 WHERE botID = " .. server.botID)
end


function newDay()
	if (string.sub(botman.serverTime, 1, 10) ~= server.date) then
		server.date = string.sub(botman.serverTime, 1, 10)

		-- force logging to start a new file
		startLogging(false)
		startLogging(true)

		dailyMaintenance()
		resetShop()

		if tonumber(botman.playersOnline) == 0 then
			saveLuaTables()
		end
	end
end


function IPToInt(ip)
	local o1,o2,o3,o4

	o1,o2,o3,o4 = ip:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
	return 2^24*o1 + 2^16*o2 + 2^8*o3 + o4
end


function readIPBlacklist()
	-- very slow.  don't run with a full server
	local ln
	local iprange

	local o1,o2,o3,o4
	local num1,num2

	for ln in io.lines(homedir .. "/cn.csv") do
		iprange = string.split(ln, ",")

		o1,o2,o3,o4 = iprange[1]:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
		num1 = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4

		o1,o2,o3,o4 = iprange[2]:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
		num2 = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4

		connBots:execute("INSERT INTO IPBlacklist (StartIP, EndIP) VALUES (" .. num1 .. "," .. num2 .. ")")
	end
end


function Translate(playerid, command, lang, override)
	local words, word, oldCount, matches

	os.remove(botman.userHome .. "/" .. server.botID .. "trans.txt")
	os.execute(botman.userHome .. "/" .. server.botID .. "trans.txt")

	words = {}
	for word in command:gmatch("%S+") do table.insert(words, word) end
	oldCount = table.maxn(words)

	if lang == "" then
		os.execute("trans -b -no-ansi \"" .. command .. "\" > " .. botman.userHome .. "/" .. server.botID .. "trans.txt")
	else
		os.execute("trans -b -no-ansi {en=" .. lang .."}  \"" .. command .. "\" > " .. botman.userHome .. "/" .. server.botID .. "trans.txt")
	end

	for ln in io.lines(botman.userHome .. "/" .. server.botID .. "trans.txt") do
		matches = 0
		for word in ln:gmatch("%S+") do
			if string.find(command, word, nil, true) then
				matches = matches + 1
			end
		end

		if matches < 2 then
			if ln ~= command and string.trim(ln) ~= "" then
				if players[playerid].translate == true or override ~= nil then
					message("say [BDFFFF]" .. players[playerid].name .. " [-]" .. ln)
				end

				if players[playerid].translate == false then
					irc_chat(server.ircMain, players[playerid].name .. " " .. ln)
				end
			end
		end
	end

	io.close()
end


function CheckClaimsRemoved()
	local k,v

	for k,v in pairs(igplayers) do
		if players[k].alertRemovedClaims == true then
			message("pm " .. k .. " [" .. server.chatColour .. "]You had expired claims or you placed claims in a restricted area and they have been automatically removed.  You can get them back by typing " .. server.commandPrefix .. "give claims.[-]")
			players[k].alertRemovedClaims = false
		end
	end
end


function CheckBlacklist(steam, ip)
	ip = ip:gsub("::ffff:", "")

	local o1,o2,o3,o4 = ip:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
	local ipint = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4
	local k, v, cursor, errorString

	if not botman.db2Connected then
		return
	end

	if not whitelist[steam] then
		-- test for China IP
		ipint = tonumber(ipint)

		cursor,errorString = connBots:execute("SELECT * FROM IPBlacklist WHERE StartIP <=  " .. ipint .. " AND EndIP >= " .. ipint)
		if cursor:numrows() > 0 then

			irc_chat(server.ircMain, "Chinese IP detected. " .. players[steam].name)
			irc_chat(server.ircAlerts, "Chinese IP detected. " .. players[steam].name)
			players[steam].china = true
			players[steam].country = "CN"
			players[steam].ircTranslate = true

			if server.blacklistResponse == 'exile' then
				if tonumber(players[steam].exiled) == 0 then
					players[steam].exiled = 1
					if botman.dbConnected then conn:execute("UPDATE players SET country = 'CN', exiled = 1, ircTranslate = 1 WHERE steam = " .. steam) end
				end

				-- alert players
				for k, v in pairs(igplayers) do
					if players[k].exiled~=1 and not players[k].prisoner then
						message("pm " .. k .. " Chinese player " .. players[steam].name .. " detected and exiled.[-]")
					end
				end
			end

			if server.blacklistResponse == 'ban' then
				irc_chat(server.ircMain, "Blacklisted player " .. players[steam].name .. " banned.")
				irc_chat(server.ircAlerts, "Blacklisted player " .. players[steam].name .. " banned.")
				banPlayer(steam, "10 years", "blacklisted", "")
			end

			connBots:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','info','Blacklisted player joined and banned. Name: " .. escape(player) .. " SteamID: " .. steam .. " IP: " .. ip  .. "'," .. steam .. ")")
		else
			reverseDNS(steam, ip)
		end
	end
end


function reverseDNS(steam, ip)
	os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	os.execute("whois " .. ip:gsub("::ffff:", "") .. " > \"" .. homedir .. "/dns/" .. steam .. ".txt\"")
	tempTimer( 60, [[readDNS("]] .. steam .. [[")]] )
end


function readDNS(steam)
	local file, ln, split, ip1, ip2, exiled, country, proxy, ISP, iprange, IP

	file = io.open(homedir .. "/dns/" .. steam .. ".txt", "r")
	exiled = false
	proxy = false
	country = ""
	for ln in file:lines() do
		ln = string.upper(ln)

		if string.find(ln, "%s(%d+)%.(%d+)%.(%d+)%.(%d+)%s") then
			a,b = string.find(ln, "%s(%d+)%.(%d+)%.(%d+)%.(%d+)%s")
			iprange = string.sub(ln, a, a+b)
		end

		if not whitelist[steam] and not players[steam].donor then
			for k,v in pairs(proxies) do
				if string.find(ln, string.upper(v.scanString), nil, true) then
					v.hits = tonumber(v.hits) + 1

					if botman.db2Connected then
						connBots:execute("UPDATE proxies SET hits = hits + 1 WHERE scanString = '" .. escape(k) .. "'")
					end

					if v.action == "ban" or v.action == "" then
						irc_chat(server.ircMain, "Player " .. players[steam].name .. " banned. Detected proxy " .. v.scanString)
						irc_chat(server.ircAlerts, "Player " .. players[steam].name .. " banned. Detected proxy " .. v.scanString)
						banPlayer(steam, "10 years", "Banned proxy. Contact us to get unbanned and whitelisted.", "")
						proxy = true
					else
						if players[steam].exiled == 0 then
							players[steam].exiled = 1
							irc_chat(server.ircMain, "Player " .. players[steam].name .. " exiled. Detected proxy " .. v.scanString)
							irc_chat(server.ircAlerts, "Player " .. players[steam].name .. " exiled. Detected proxy " .. v.scanString)
							exiled = true
							proxy = true
						end
					end
				end
			end
		end

		if proxy then break end

		if string.find(ln, "ABUSE@") then
			-- record the domain after the @ and store as the player's ISP
			ISP = string.sub(ln, string.find(ln, "ABUSE@") + 6)
			players[steam].ISP = ISP
		end

		if string.find(ln, "CHINA") then
			country = "CN"
			players[steam].country = "CN"
		end

		if string.find(ln, "OUNTRY:") or (ln == "ADDRESS:        CN") or (ln == "ADDRESS:        HK") then
			-- only report country change if CN or HK are involved. For once, don't blame Canada.
			a,b = string.find(ln, "%s(%w+)")
			country = string.sub(ln, a + 1)
			if players[steam].country ~= "" and players[steam].country ~= country and (players[steam].country == "CN" or players[steam].country == "HK" or country == "CN" or country == "HK") and not whitelist[steam] then
				irc_chat(server.ircAlerts, "Possible proxy detected! Country changed! " .. steam .. " " .. players[steam].name .. " " .. players[steam].IP .. " old country " .. players[steam].country .. " new " .. country)
				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (0,0,0'" .. botman.serverTime .. "','proxy','Suspected proxy used by " .. escape(players[steam].name) .. " " .. players[steam].IP .. " old country " .. players[steam].country .. " new " .. country .. "," .. steam .. ")") end
				proxy = true
			else
				 players[steam].country = country
			end
		end

		-- We consider HongKong to be China since Chinese players connect from there too.
		if (country == "CN" or country == "HK") and not whitelist[steam] then
			-- China detected. Add ip range to IPBlacklist table
			irc_chat(server.ircMain, "Chinese IP detected. " .. players[steam].name .. " " .. players[steam].IP)
			irc_chat(server.ircAlerts, "Chinese IP detected. " .. players[steam].name .. " " .. players[steam].IP)
			players[steam].china = true
			players[steam].ircTranslate = true

			if server.blacklistResponse == 'exile' then
				if players[steam].exiled == 0 then
					players[steam].exiled = 1
					irc_chat(server.ircMain, "Chinese player " .. players[steam].name .. " exiled.")
					irc_chat(server.ircAlerts, "Chinese player " .. players[steam].name .. " exiled.")
					exiled = true
				end
			end

			if server.blacklistResponse == 'ban' then
				irc_chat(server.ircMain, "Chinese player " .. players[steam].name .. " banned.")
				irc_chat(server.ircAlerts, "Chinese player " .. players[steam].name .. " banned.")
				banPlayer(steam, "10 years", "blacklisted", "")
			end

			if botman.db2Connected then
				if iprange ~= nil then
					split = string.split(iprange, "-")
					ip1 = IPToInt(string.trim(split[1]))
					ip2 = IPToInt(string.trim(split[2]))

					-- check that player's IP is actually within the discovered IP range
					IP = IPToInt(players[steam].IP)

					if IP >= ip1 and IP <= ip2 then
						irc_chat(server.ircMain, "Added new Chinese IP range " .. iprange .. " to blacklist")
						connBots:execute("INSERT INTO IPBlacklist (StartIP, EndIP, Country, botID, steam, playerName, IP) VALUES (" .. ip1 .. "," .. ip2 .. "'" .. country .. "'," .. server.botID .. "," .. steam .. ",'" .. escape(players[steam].name) .. "','" .. escape(players[steam].IP) .. "')")
					end
				end
			end

			-- alert players
			for k, v in pairs(igplayers) do
				if players[k].exiled~=1 and not players[k].prisoner then
					if exiled then
						message("pm " .. k .. " Chinese player " .. players[steam].name .. " detected and sent to exile.[-]")
					else
						message("pm " .. k .. " Chinese player " .. players[steam].name .. " detected.[-]")
					end
				end
			end

			if botman.dbConnected then
				conn:execute("UPDATE players SET country = '" .. escape(country) .. "', exiled = 1, ircTranslate = 1 WHERE steam = " .. steam)
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','info','Chinese player joined. Name: " .. escape(player) .. " SteamID: " .. steam .. " IP: " .. players[steam].IP  .. "'," .. steam .. ")")
			end

			file:close()

			-- got country so stop processing the dns record
			break
		end
	end

	if proxy then
		os.rename(homedir .. "/dns/" .. steam .. "_old.txt", homedir .. "/proxies/" .. steam .. "_" .. country .. ".txt")
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/proxies/" .. steam .. "_" .. country .. ".txt")
	else
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	end

	if botman.dbConnected then conn:execute("UPDATE players SET country = '" .. country .. "' WHERE steam = " .. steam) end

	file:close()

	if not proxy then
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	end
end


function initNewPlayer(steam, player, entityid, steamOwner)
	if botman.dbConnected then conn:execute("INSERT INTO players (steam, id, name, steamOwner) VALUES (" .. steam .. "," .. entityid .. ",'" .. escape(player) .. "'," .. steamOwner .. ")") end

	players[steam] = {}
	players[steam].alertMapLimit = false
	players[steam].alertPrison = true
	players[steam].alertPVP = true
	players[steam].alertReset = true
	players[steam].atHome = false
	players[steam].autoFriend = ""
	players[steam].baseCooldown = 0
	players[steam].bedX = 0
	players[steam].bedY = 0
	players[steam].bedZ = 0
	players[steam].botTimeout = false
	players[steam].cash = 0
	players[steam].chatColour = "FFFFFF 1"
	players[steam].commandCooldown = 0
	players[steam].country = ""
	players[steam].donor = false
	players[steam].donorExpiry = os.time()
	players[steam].donorLevel = 0
	players[steam].firstSeen = os.time()
	players[steam].GBLCount = 0
	players[steam].gimmeCount = 0
	players[steam].hackerScore = 0
	players[steam].hackerTPScore = 0
	players[steam].home2X = 0
	players[steam].home2Y = 0
	players[steam].home2Z = 0
	players[steam].homeX = 0
	players[steam].homeY = 0
	players[steam].homeZ = 0
	players[steam].id = entityid
	players[steam].ignorePlayer = false -- exclude player from checks like inventory, flying, teleporting etc.
	players[steam].ircPass = ""
	players[steam].ISP = ""
	players[steam].lastBaseRaid = 0
	players[steam].lastChatLine = ""
	players[steam].lastCommand = ""
	players[steam].lastCommandTimestamp = os.time()
	players[steam].lastLogout = os.time()
	players[steam].mute = false
	players[steam].name = player
	players[steam].names = player .. ","
	players[steam].newPlayer = true
	players[steam].overstack = false
	players[steam].overstackItems = ""
	players[steam].overstackScore = 0
	players[steam].overstackTimeout = false
	players[steam].packCooldown = 0
	players[steam].pendingBans = 0
	players[steam].permanentBan = false
	players[steam].ping = 0
	players[steam].playtime = 0
	players[steam].prisoner = false
	players[steam].prisonReason = ""
	players[steam].prisonReleaseTime = 0
	players[steam].prisonxPosOld = 0
	players[steam].prisonyPosOld = 0
	players[steam].prisonzPosOld = 0
	players[steam].protect = false
	players[steam].protect2 = false
	players[steam].protect2Size = server.baseSize
	players[steam].protectSize = server.baseSize
	players[steam].pvpVictim = 0
	players[steam].raiding = false
	players[steam].relogCount = 0
	players[steam].removeClaims = false
	players[steam].reserveSlot = false
	players[steam].sessionCount = 1
	players[steam].silentBob = false
	players[steam].steam = steam
	players[steam].steamOwner = steamOwner
	players[steam].teleCooldown = 0
	players[steam].timeOnServer = 0
	players[steam].timeout = false
	players[steam].tokens = 0
	players[steam].tp = 0
	players[steam].walkies = false
	players[steam].watchPlayer = true
	players[steam].watchPlayerTimer = os.time() + 2419200 -- stop watching in one month.  it will stop earlier once they are upgraded from new player status
	players[steam].waypoint2X = 0
	players[steam].waypoint2Y = 0
	players[steam].waypoint2Z = 0
	players[steam].waypointsLinked = false
	players[steam].waypointX = 0
	players[steam].waypointY = 0
	players[steam].waypointZ = 0
	players[steam].waypointCooldown = server.waypointCooldown
	players[steam].whitelisted = false
	players[steam].xPos = 0
	players[steam].xPosOld = 0
	players[steam].xPosOld2 = 0
	players[steam].yPos = 0
	players[steam].yPosOld = 0
	players[steam].yPosOld2 = 0
	players[steam].zPos = 0
	players[steam].zPosOld = 0
	players[steam].zPosOld2 = 0

	if locations["lobby"] then
		players[steam].location = "lobby"
	else
		players[steam].location = ""
	end

	return true
end


function initNewIGPlayer(steam, player, entityid, steamOwner)
	igplayers[steam] = {}
	igplayers[steam].afk = os.time() + 900
	igplayers[steam].alertRemovedClaims = false
	igplayers[steam].belt = ""
	igplayers[steam].botQuestion = "" -- used for storing the last question the bot asked the player.
	igplayers[steam].checkNewPlayer = true
	igplayers[steam].connected = true
	igplayers[steam].equipment = ""
	igplayers[steam].fetch = false
	igplayers[steam].firstSeen = os.time()
	igplayers[steam].flyCount = 0
	igplayers[steam].flying = false
	igplayers[steam].flyingX = 0
	igplayers[steam].flyingY = 0
	igplayers[steam].flyingZ = 0
	igplayers[steam].greet = true
	igplayers[steam].greetdelay = 4
	igplayers[steam].highPingCount = 0
	igplayers[steam].id = entityid
	igplayers[steam].illegalInventory = false
	igplayers[steam].inventory = ""
	igplayers[steam].inventoryLast = ""
	igplayers[steam].killTimer = 0
	igplayers[steam].lastHotspot = 0
	igplayers[steam].lastLogin = ""
	igplayers[steam].lastLP = os.time()
	igplayers[steam].name = player
	igplayers[steam].noclipX = 0
	igplayers[steam].noclipY = 0
	igplayers[steam].noclipZ = 0
	igplayers[steam].pack = ""
	igplayers[steam].ping = 0
	igplayers[steam].playGimme = false
	igplayers[steam].region = ""
	igplayers[steam].sessionPlaytime = 0
	igplayers[steam].sessionStart = os.time()
	igplayers[steam].steam = steam
	igplayers[steam].steamOwner = steamOwner
	igplayers[steam].teleCooldown = 200
	igplayers[steam].timeOnServer = 0
	igplayers[steam].xPos = 0
	igplayers[steam].xPosLast = 0
	igplayers[steam].xPosLastAlert = 0
	igplayers[steam].xPosLastOK = 0
	igplayers[steam].yPos = 0
	igplayers[steam].yPosLast = 0
	igplayers[steam].yPosLastAlert = 0
	igplayers[steam].yPosLastOK = 0
	igplayers[steam].zPos = 0
	igplayers[steam].zPosLast = 0
	igplayers[steam].zPosLastAlert = 0
	igplayers[steam].zPosLastOK = 0

	return true
end


function fixMissingStuff()
	lfs.mkdir(homedir .. "/custom")
	lfs.mkdir(homedir .. "/daily")
	lfs.mkdir(homedir .. "/dns")
	lfs.mkdir(homedir .. "/proxies")
	lfs.mkdir(homedir .. "/temp")
	lfs.mkdir(homedir .. "/scripts")
	lfs.mkdir(homedir .. "/data_backup")
	lfs.mkdir(homedir .. "/chatlogs")

	if not isFile(homedir .. "/custom/gmsg_custom.lua") then
		file = io.open(homedir .. "/custom/gmsg_custom.lua", "a")
		file:write("function gmsg_custom()\n")
		file:write("	calledFunction = \"gmsg_custom\"\n")
		file:write("	\-\- ###################  do not allow remote commands beyond this point ################\n")
		file:write("	if (chatvars.playerid == nil) then\n")
		file:write("		botman.faultyChat = false\n")
		file:write("		return false\n")
		file:write("	end\n")
		file:write("	\-\- ####################################################################################\n")
		file:write("	if (chatvars.words[1] == \"test\" and chatvars.words[2] == \"command\") then\n")
		file:write("		message(\"pm \" .. chatvars.playerid .. \" [\" .. server.chatColour .. \"]This is a sample command in gmsg_custom.lua in the scripts folder.[-]\")\n")
		file:write("		botman.faultyChat = false\n")
		file:write("		return true\n")
		file:write("	end\n")
		file:write("end\n")
		file:close()
	end

	if type(gimmeZombies) ~= "table" then
		gimmeZombies = {}
		send("se")
	end

	if benchmarkBot == nil then
		benchmarkBot = false
	end
end


function saveDisconnectedPlayer(steam)
	-- this function has been moved from the player disconnected trigger so we can call it in other places if necessary to ensure all online player data is saved to the database.
	fixMissingPlayer(steam)

	-- update players table with x y z
	players[steam].lastAtHome = nil
	players[steam].protectPaused = nil
	players[steam].protect2Paused = nil

	if igplayers[steam] then
		-- only process the igplayer record if the player is actually online otherwise assume these are already done
		players[steam].xPos = igplayers[steam].xPos
		players[steam].yPos = igplayers[steam].yPos
		players[steam].zPos = igplayers[steam].zPos
		players[steam].playerKills = igplayers[steam].playerKills
		players[steam].deaths = igplayers[steam].deaths
		players[steam].zombies = igplayers[steam].zombies
		players[steam].score = igplayers[steam].score
		players[steam].ping = igplayers[steam].ping
		players[steam].timeOnServer = players[steam].timeOnServer + igplayers[steam].sessionPlaytime

		if (igplayers[steam].sessionPlaytime) > 300 then
			players[steam].relogCount = 0
		end

		if (igplayers[steam].sessionPlaytime) < 60 then
			if not players[steam].timeout and not players[steam].botTimeout and not players[steam].prisoner then
				players[steam].relogCount = tonumber(players[steam].relogCount) + 1
			end
		else
			players[steam].relogCount = tonumber(players[steam].relogCount) - 1
			if tonumber(players[steam].relogCount) < 0 then players[steam].relogCount = 0 end
		end

		players[steam].lastLogout = os.time()
		players[steam].seen = botman.serverTime
	end

	if accessLevel(steam) < 3 then
		if botman.dbConnected then conn:execute("DELETE FROM memTracker WHERE admin = " .. steam) end
	end

	if botman.dbConnected then
		conn:execute("DELETE FROM messageQueue WHERE recipient = " .. steam)
		conn:execute("DELETE FROM gimmeQueue WHERE steam = " .. steam)
		conn:execute("DELETE FROM commandQueue WHERE steam = " .. steam)
		conn:execute("DELETE FROM playerQueue WHERE steam = " .. steam)
	end

	-- delete player from igplayers table
	igplayers[steam] = nil
	lastHotspots[steam] = nil
	invTemp[steam] = nil

	-- update the player record in the database
	updatePlayer(steam)

	if	botman.db2Connected then
		-- insert or update player in bots db
		connBots:execute("INSERT INTO players (server, steam, ip, name, online, botid) VALUES ('" .. escape(server.serverName) .. "'," .. steam .. ",'" .. players[steam].IP .. "','" .. escape(players[steam].name) .. "',0," .. server.botID .. ") ON DUPLICATE KEY UPDATE ip = '" .. players[steam].IP .. "', name = '" .. escape(players[steam].name) .. "', online = 0")
	end
end


function shutdownBot(steam)
	local k, v

	for k,v in pairs(igplayers) do
		savePlayerData(k)
	end

	saveLuaTables(os.date("%Y%m%d_%H%M%S"))

	if igplayers[steam] then
		message("pm " .. steam .. " [" .. server.chatColour .. "]" .. server.botName .. " is ready to shutdown.  Player data is saved.[-]")
	end

	sendIrc(server.ircMain, server.botName .. " is ready to shutdown.  Player data is saved.")
end
