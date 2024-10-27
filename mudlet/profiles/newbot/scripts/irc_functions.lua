--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

-- if you have oper status on your irc server, you can set channel modes.  This one sets flood protection to 5000 chars in 1 second which should prevent the bot from getting banned for flooding.
-- /mode #channel +f [5000t#b]:1

-- /mode #mychannel +k mypassword
--

local debug = false -- should be false unless testing
local steam, steamOwner, userID

function getNick()
	server.ircBotName = ircGetNick()
end


function secureIRCChannels()
	sendIrc("#mudlet", "/part #mudlet")
	sendIrc("", "/join " .. string.trim(server.ircMain .. " " .. server.ircMainPassword))
	sendIrc("", "/join " .. string.trim(server.ircAlerts .. " " .. server.ircAlertsPassword))
	sendIrc("", "/join " .. string.trim(server.ircWatch .. " " .. server.ircWatchPassword))

	if server.ircMainPassword ~= "" then
		sendIrc("", "/mode " .. server.ircMain .. " +sk " .. server.ircMainPassword)
	end

	if server.ircAlertsPassword ~= "" then
		sendIrc("", "/mode " .. server.ircAlerts .. " +sk " .. server.ircAlertsPassword)
	end

	if server.ircWatchPassword ~= "" then
		sendIrc("", "/mode " .. server.ircWatch .. " +sk " .. server.ircWatchPassword)
	end
end


function joinIRCServer()
	if not server.ircPort or not server.ircServer then
		return
	end

	-- delete some Mudlet files that store IP and other info forcing Mudlet to regenerate them.
	os.remove(homedir .. "/irc_host")
	os.remove(homedir .. "/irc_port")
	os.remove(homedir .. "/irc_server_port")

	-- Do not allow the bot to automatically connect to Freenode.
	if server.ircServer then
		if string.find(string.lower(server.ircServer), "freenode") then
			server.ircServer = "127.0.0.1"
		end
	end

	setIrcServer(server.ircServer, server.ircPort)
	setIrcChannels( {server.ircMain, server.ircAlerts, server.ircWatch })
	tempTimer(1, [[secureIRCChannels()]])

	if server.ircBotName then
		if server.ircBotName ~= "Bot" then
			if setIrcNick ~= nil then
				-- Mudlet 3.x
				setIrcNick(server.ircBotName)
			end
		end
	end
end


function irc_chat(name, msg)
	local multilineText, k, v, file, botIsTalking

	botIsTalking = false

	-- Don't allow the bot to command itself
	if (name == server.botName) or (name == server.ircBotName) or botman.registerHelp then
		botIsTalking = true
	end

	if not msg then
		return
	end

	-- replace any placeholder text with actual values
	msg = msg:gsub("{#}", server.commandPrefix)
	msg = msg:gsub("{server}", server.serverName)
	msg = msg:gsub("{money}", server.moneyName)
	msg = msg:gsub("{monies}", server.moneyPlural)

	msg = stripBBCodes(msg)
	multilineText = string.split(msg, "\n")

	for k,v in pairs(multilineText) do
		if botman.registerHelp then
			if botman.webdavFolderWriteable then
				file = io.open(botman.chatlogPath .. "/help/help.txt", "a")

				if v == "." then
					v = ""
				else
					v = string.trim(v)
				end

				file:write(v .. "\n")
				file:close()
			end
		else
			if not botIsTalking then
				connMEM:execute("INSERT INTO ircQueue (name, command) VALUES ('" .. name .. "','" .. connMEM:escape(v) .. "')")
			end
		end

		if name == server.ircAlerts then
			logAlerts(botman.serverTime, v)
		end
	end

	if not botIsTalking then
		enableTimer("ircQueue")
	end
end


function irc_reportDiskFree(name)
	local s
	local f = io.popen("df -h") -- run df -h

	repeat
	  s = f:read ("*l") -- read one line
	  if s then  -- if not end of file (EOF)
	   if string.find(s, "Filesystem") or string.find(s, "/dev/") and not string.find(s, "tmpfs") then irc_chat(name, s) end
	  end
	until not s  -- until end of file

	f:close()
end


function irc_Inventory(tmp)
	local rows, i, max

	if tmp.timestamp then
		cursor,errorString = connINVTRAK:execute("SELECT * FROM inventoryTracker WHERE steam = '" .. tmp.playerID .."' AND timestamp = " .. tmp.timestamp)
	else
		cursor,errorString = connINVTRAK:execute("SELECT * FROM inventoryTracker WHERE steam = '" .. tmp.playerID .."' ORDER BY timestamp DESC Limit 1")
	end

	row = cursor:fetch({}, "a")
	if row then
		irc_chat(tmp.name, ".")
		irc_chat(tmp.name, "Belt of " .. players[tmp.playerID].name)

		tmp.inventory = string.split(row.belt, "|")

		max = tablelength(tmp.inventory)-1
		for i=1, max, 1 do
			tmp.slot = string.split(tmp.inventory[i], ",")
			if tonumber(tmp.slot[4]) > 0 then
				irc_chat(tmp.name, "Slot " .. tmp.slot[1] .. " qty " .. tmp.slot[2] .. " " .. tmp.slot[3] .. " " .. tmp.slot[4])
			else
				irc_chat(tmp.name, "Slot " .. tmp.slot[1] .. " qty " .. tmp.slot[2] .. " " .. tmp.slot[3])
			end
		end

		irc_chat(tmp.name, ".")
		irc_chat(tmp.name, "Backpack of " .. players[tmp.playerID].name)

		tmp.inventory = string.split(row.pack, "|")

		max = tablelength(tmp.inventory)-1
		for i=1, max, 1 do
			tmp.slot = string.split(tmp.inventory[i], ",")
			if tonumber(tmp.slot[4]) > 0 then
				irc_chat(tmp.name, "Slot " .. tmp.slot[1] .. " qty " .. tmp.slot[2] .. " " .. tmp.slot[3] .. " " .. tmp.slot[4])
			else
				irc_chat(tmp.name, "Slot " .. tmp.slot[1] .. " qty " .. tmp.slot[2] .. " " .. tmp.slot[3])
			end
		end

		irc_chat(tmp.name, ".")
		irc_chat(tmp.name, "Equipment of " .. players[tmp.playerID].name)

		tmp.inventory = string.split(row.equipment, "|")

		max = tablelength(tmp.inventory)-1
		for i=1, max, 1 do
			tmp.slot = string.split(tmp.inventory[i], ",")
			irc_chat(tmp.name, "Slot " .. tmp.slot[1] .. " " .. tmp.slot[2] .. " " .. tmp.slot[3])
		end
	else
		irc_chat(tmp.name, ".")
		irc_chat(tmp.name, "I do not have an inventory recorded for " .. players[tmp.playerID].platform .. "_" .. tmp.playerID .. " " .. players[tmp.playerID].name)

		cursor,errorString = conn:execute("SELECT platform, id, steam, userID, name FROM players WHERE name LIKE '%" .. tmp.search .. "%'")
		rows = cursor:numrows()

		irc_chat(tmp.name, "I found " .. rows .. " players that matched " .. tmp.search)
		row = cursor:fetch({}, "a")

		while row do
			irc_chat(tmp.name, "Player " .. row.platform .. "_" .. row.steam .. " " .. row.userID .. " " .. row.name)
			row = cursor:fetch(row, "a")
		end

	end

	irc_chat(tmp.name, ".")
end


function irc_ListTables()
	irc_chat(irc_params.name, "These are the bot tables that you can view and edit:")
	irc_chat(irc_params.name, "botman")
	irc_chat(irc_params.name, "server")
	irc_chat(irc_params.name, "rollingMessages")
	irc_chat(irc_params.name, "whitelist")
	irc_chat(irc_params.name, "----")
end


function irc_ListHelpCommand()
	local cursor, errorString, row, counter, ingameOnly

	cursor,errorString = connSQL:execute("SELECT * FROM helpCommands WHERE keywords LIKE '%" .. irc_params.keyword .. "%' ORDER BY functionName")

	counter = 1
	row = cursor:fetch({}, "a")

	irc_chat(irc_params.name, "Help commands matching keyword " .. irc_params.keyword .. ":")

	while row do
		if row.ingameOnly == 1 then
			ingameOnly = "yes"
		else
			ingameOnly = "no"
		end

		if ingameOnly then
			irc_chat(irc_params.name, "#" .. counter .. " command: " .. row.command .. " - access level " .. row.accessLevel .. "   (in-game only)")
		else
			irc_chat(irc_params.name, "#" .. counter .. " command: " .. row.command .. " - access level " .. row.accessLevel)
		end

		if irc_params.fullHelp then
			irc_chat(irc_params.name, row.description)
			irc_chat(irc_params.name, ".")
		end

		if irc_params.showNotes then
			if row.notes ~= "" then
				irc_chat(irc_params.name, "=== Notes ===")
				irc_chat(irc_params.name, row.notes)
				irc_chat(irc_params.name, ".")
			end
		end

		counter = counter + 1
		row = cursor:fetch(row, "a")
	end

	irc_chat(irc_params.name, ".")
end


function irc_SetHelpCommand()
	local cursor, errorString, row, counter

	cursor,errorString = connSQL:execute("SELECT command, topic, functionName, accessLevel, ingameOnly FROM helpCommands WHERE keywords LIKE '%" .. irc_params.keyword .. "%' ORDER BY functionName")

	counter = 1
	row = cursor:fetch({}, "a")

	while row do
		if counter == irc_params.index then
			connSQL:execute("UPDATE helpCommands SET accessLevel = " .. irc_params.accessLevel .. " WHERE functionName = '" .. row.functionName .. "' AND topic = '" .. row.topic .. "'")
			irc_chat(irc_params.name, "The new access level for " .. row.command .. " is " .. irc_params.accessLevel)

			return
		end

		counter = counter + 1
		row = cursor:fetch(row, "a")
	end

	irc_chat(irc_params.name, ".")
end


function irc_ListBases(steam)
	local msg, cursor, errorString, row, prot, privacy

	if steam ~= "0" then
		cursor,errorString = conn:execute("SELECT bases.steam, name, x, y, z, bases.protect, bases.keepOut, bases.protectSize, bases.title, bases.baseNumber from players inner join bases where players.steam = bases.steam and bases.steam = '" .. steam .. "' order by name")
	else
		if irc_params.x then
			cursor,errorString = conn:execute("SELECT bases.steam, name, x, y, z, bases.protect, bases.keepOut, bases.protectSize, bases.title, bases.baseNumber from players inner join bases where players.steam = bases.steam AND abs(x - " .. irc_params.x .. ") <= " .. irc_params.range .. " AND abs(z - " .. irc_params.z .. ") <= " .. irc_params.range .. " order by name, bases.steam")
		else
			cursor,errorString = conn:execute("SELECT bases.steam, name, x, y, z, bases.protect, bases.keepOut, bases.protectSize, bases.title, bases.baseNumber from players inner join bases where players.steam = bases.steam order by name, bases.steam")
		end
	end

	if irc_params.x then
		irc_chat(irc_params.name, "Bases within " .. irc_params.range .. " of xPos " .. irc_params.x .. " zPos " .. irc_params.z)
	end

	row = cursor:fetch({}, "a")

	if row then
		irc_chat(irc_params.name, "Steam | Name | Base Number | Base Name | Base Coordinates | Protected | Base Size")
	else
		irc_chat(irc_params.name, "No bases recorded.")
	end

	while row do
		if tonumber(row.protect) == 1 then
			prot = "YES"
		else
			prot = "NO"
		end

		if tonumber(row.keepOut) == 1 then
			privacy = " [PRIVATE]"
		else
			privacy = " [OPEN]"
		end

		msg = row.steam .. "   " .. row.name .. "   base "
		msg = msg .. row.baseNumber .. " " .. string.trim(row.title) .. " @ " .. row.x .. " " .. row.y .. " " .. row.z .. "  protected " .. prot .. privacy .. " size " .. row.protectSize
		irc_chat(irc_params.name, msg)
		row = cursor:fetch(row, "a")
	end

	irc_chat(irc_params.name, ".")
end


function irc_ListBeds(steam)
	local msg, k, v

	for k,v in pairs(players) do
		if steam ~= "0" then
			if v.steam == steam then
				msg = v.steam .. " " .. v.name .. " "

				if tonumber(v.bedX) == 0 and tonumber(v.bedY) == 0 and tonumber(v.bedZ) == 0 then
					msg = msg .. " no bedroll recorded"
				else
					msg = msg .. " bedroll at " .. v.bedX .. " " .. v.bedY .. " " .. v.bedZ
				end

				irc_chat(irc_params.name, msg)
			end
		else
			msg = v.steam .. " " .. v.name .. " "

			if tonumber(v.bedX) == 0 and tonumber(v.bedY) == 0 and tonumber(v.bedZ) == 0 then
				msg = msg .. " no bedroll recorded"
			else
				msg = msg .. " bedroll " .. v.bedX .. " " .. v.bedY .. " " .. v.bedZ
			end

			irc_chat(irc_params.name, msg)
		end
	end

	irc_chat(irc_params.name, ".")
end


function irc_PlayersNearPlayer(name, name1, range, xPos, zPos, offline, otherTarget)
	local alone, dist, number, flag

	alone = true

	if offline == false then
		if name1 ~= "" then
			irc_chat(name, "Players within " .. range .. " meters of " .. players[name1].name .. " are:")
		end

		if otherTarget ~= nil then
			irc_chat(name, "Players within " .. range .. " meters of " .. otherTarget .. " are:")
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "Players within " .. range .. " meters of x " .. xPos .. " z " .. zPos .. " are:")
		end

		for k, v in pairs(igplayers) do
			if k ~= name1 then
				if name1 ~= "" then
					dist = distancexz(players[name1].xPos, players[name1].zPos, v.xPos, v.zPos)
				else
					dist = distancexz(xPos, zPos, v.xPos, v.zPos)
				end

				if dist <= range then
					irc_chat(name, v.name .. " steam: " .. k .. " distance: " .. string.format("%-4.2d", dist) .. " meters")
					alone = false
				end
			end
		end
	else
		if name1 ~= "" then
			irc_chat(name, "Players within " .. range .. " meters of " .. players[name1].name .. " including offline are:")
		end

		if otherTarget ~= nil then
			irc_chat(name, "Players within " .. range .. " meters of " .. otherTarget .. " including offline are:")
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "Players within " .. range .. " meters of x " .. xPos .. " z " .. zPos .. " including offline are:")
		end

		for k, v in pairs(players) do
			if k ~= name1 then
				if name1 ~= "" then
					dist = distancexz(players[name1].xPos, players[name1].zPos, v.xPos, v.zPos)
				else
					dist = distancexz(xPos, zPos, v.xPos, v.zPos)
				end

				if dist <= range then
					if igplayers[k] then
						flag = " PLAYING"
					else
						flag = " OFFLINE"
					end

					irc_chat(name, v.name .. " steam: " .. k .. " distance: " .. string.format("%-4.2d", dist) .. " meters" .. flag)
					alone = false
				end
			end
		end
	end

	if (alone == true) then
		if name1 ~= "" then
			irc_chat(name, "There is nobody within " .. range .. " meters of " .. players[name1].name)
		end

		if otherTarget ~= nil then
			irc_chat(name, "Players within " .. range .. " meters of " .. otherTarget .. " including offline are:")
			irc_chat(name, "There is nobody within " .. range .. " meters of " .. otherTarget)
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "There is nobody within " .. range .. " meters of x " .. xPos .. " z " .. zPos)
		end
	end

	irc_chat(name, ".")
end


function irc_BasesNearPlayer(name, name1, range, xPos, zPos, otherTarget)
	local alone, dist, protected, cursor, errorString, row

	alone = true

	if name1 ~= "" then
		irc_chat(name, "Bases within " .. range .. " meters of " .. players[name1].name .. " are:")
	end

	if otherTarget ~= nil then
		irc_chat(name, "Bases within " .. range .. " meters of " .. otherTarget .. " are:")
	end

	if name1 == "" and otherTarget == nil then
		irc_chat(name, "Bases within " .. range .. " meters of " .. players[name].name .. " are:")
	end

	cursor,errorString = conn:execute("SELECT bases.steam, name, x, y, z, bases.protect from players inner join bases where players.steam = bases.steam order by name, bases.steam")

	row = cursor:fetch({}, "a")

	while row do
		if name1 ~= "" then
			dist = distancexz(players[name1].xPos, players[name1].zPos, row.x, row.z)
		else
			dist = distancexz(xPos, zPos, row.x, row.z)
		end

		if dist <= tonumber(range) then
			if tonumber(row.protect) == 0 then
				protected = " bot protected"
			else
				protected = " unprotected"
			end

			irc_chat(name, row.name .. " steam: " .. row.steam .. " distance: " .. string.format("%-.2d", dist) .. " meters" .. protected)
			alone = false
		end

		row = cursor:fetch(row, "a")
	end

	if (alone == true) then
		if name1 ~= "" then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name1].name)
		end

		if otherTarget ~= nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. otherTarget)
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name].name)
		end
	end

	irc_chat(name, ".")
end


function irc_LocationsNearPlayer(name, name1, range, xPos, zPos, otherTarget)
	local alone, dist

	alone = true

	if name1 ~= "" then
		irc_chat(name, "Locations within " .. range .. " meters of " .. players[name1].name .. " are:")
	end

	if otherTarget ~= nil then
		irc_chat(name, "Locations within " .. range .. " meters of " .. otherTarget .. " are:")
	end

	if name1 == "" and otherTarget == nil then
		irc_chat(name, "Locations within " .. range .. " meters of " .. players[name].name .. " are:")
	end

	for k, v in pairs(locations) do
		if name1 ~= "" then
			dist = distancexz(players[name1].xPos, players[name1].zPos, v.x, v.z)
		else
			dist = distancexz(xPos, zPos, v.x, v.z)
		end

		if dist <= tonumber(range) then
			irc_chat(name, v.name .. " distance: " .. string.format("%-.2d", dist) .. " meters")
			alone = false
		end
	end

	if (alone == true) then
		if name1 ~= "" then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name1].name)
		end

		if otherTarget ~= nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. otherTarget)
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name].name)
		end
	end

	irc_chat(name, ".")
end


function irc_EntitiesNearPlayer(name, name1, range, xPos, zPos, otherTarget)
	local alone, dist, cursor, errorString, row

	alone = true

	if name1 ~= "" then
		irc_chat(name, "Entities within " .. range .. " meters of " .. players[name1].name .. " are:")
	end

	if otherTarget ~= nil then
		irc_chat(name, "Entities within " .. range .. " meters of " .. otherTarget .. " are:")
	end

	if name1 == "" and otherTarget == nil then
		irc_chat(name, "Entities within " .. range .. " meters of " .. players[name].name .. " are:")
	end

	cursor,errorString = connMEM:execute("SELECT * FROM entities WHERE type <> 'EntityPlayer'")

	row = cursor:fetch({}, "a")
	while row do
		if name1 ~= "" then
			dist = distancexz(players[name1].xPos, players[name1].zPos, row.x, row.z)
		else
			dist = distancexz(xPos, zPos, row.x, row.z)
		end

		if dist <= tonumber(range) then
			irc_chat(name, row.name .. " id: " .. row.entityID .. " distance: " .. string.format("%-.2d", dist))
			alone = false
		end

		row = cursor:fetch(row, "a")
	end

	if (alone == true) then
		if name1 ~= "" then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name1].name)
		end

		if otherTarget ~= nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. otherTarget)
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name].name)
		end
	end

	irc_chat(name, ".")
end


function irc_PlayerShortInfo()
	local time, days, hours, minutes, donor, expiry
	local msg, cursor, errorString, row, prot

	if (debug) then dbug("debug irc functions line " .. debugger.getinfo(1).currentline) end

	donor, expiry = isDonor(irc_params.pid)

	if (igplayers[irc_params.pid]) then
		time = tonumber(players[irc_params.pid].timeOnServer) + tonumber(igplayers[irc_params.pid].sessionPlaytime)
	else
		time = tonumber(players[irc_params.pid].timeOnServer)
	end

	days = math.floor(time / 86400)

	if (days > 0) then
		time = time - (days * 86400)
	end

	hours = math.floor(time / 3600)

	if (hours > 0) then
		time = time - (hours * 3600)
	end

	minutes = math.floor(time / 60)
	time = time - (minutes * 60)

	irc_chat(irc_params.name, "Info for player " .. irc_params.pname)
	if players[irc_params.pid].newPlayer == true then irc_chat(irc_params.name, "A new player") end
	irc_chat(irc_params.name, "SteamID/GamePass " .. players[irc_params.pid].platform .. "_" .. irc_params.pid)
	irc_chat(irc_params.name, "UserID " .. players[irc_params.pid].userID)

	if players[irc_params.pid].platform == "Steam" then
		irc_chat(irc_params.name, "Steam Rep https://steamrep.com/search?q=" .. irc_params.pid)
		irc_chat(irc_params.name, "Steam https://steamcommunity.com/profiles/" .. irc_params.pid)

		if irc_params.pid ~= players[irc_params.pid].steamOwner then
			irc_chat(irc_params.name, ".")
			irc_chat(irc_params.name, "Family Key:")
			irc_chat(irc_params.name, "Steam Rep https://steamrep.com/search?q=" .. players[irc_params.pid].steamOwner)
			irc_chat(irc_params.name, "Steam https://steamcommunity.com/profiles/" .. players[irc_params.pid].steamOwner)
			irc_chat(irc_params.name, ".")
		end
	end

	irc_chat(irc_params.name, "Player ID " .. players[irc_params.pid].id)
	if players[irc_params.pid].firstSeen ~= nil then irc_chat(irc_params.name, "First seen: " .. os.date("%Y-%m-%d %H:%M:%S", players[irc_params.pid].firstSeen) ) end
	irc_chat(irc_params.name, seen(irc_params.pid))
	irc_chat(irc_params.name, "Total time played: " .. days .. " days " .. hours .. " hours " .. minutes .. " minutes " .. time .. " seconds")
	if players[irc_params.pid].aliases then irc_chat(irc_params.name, "Has played as " .. players[irc_params.pid].aliases) end

	if players[irc_params.pid].bedX ~= 0 and players[irc_params.pid].bedY ~= 0 and players[irc_params.pid].bedZ ~= 0 then
		irc_chat(irc_params.name, "Has a bedroll at " .. players[irc_params.pid].bedX .. " " .. players[irc_params.pid].bedY .. " " .. players[irc_params.pid].bedZ )
	else
		irc_chat(irc_params.name, "Does not have a bedroll down or its location is not recorded yet.")
	end

	cursor,errorString = conn:execute("SELECT bases.steam, name, x, y, z, title, bases.protect, bases.protectSize from players inner join bases where players.steam = bases.steam and bases.steam = '" .. irc_params.pid .. "' order by name")
	row = cursor:fetch({}, "a")

	if not row then
		irc_chat(irc_params.name, "Has not set a base.")
	end

	while row do
		if tonumber(row.protect) == 1 then
			prot = "protected"
		else
			prot = "not protected"
		end

		if row.title ~= "" then
			irc_chat(irc_params.name, "Has a base called " .. row.title .. " at   " .. row.x .. " " .. row.y .. " " .. row.z .. "   size " .. row.protectSize .. " " .. prot)
		else
			irc_chat(irc_params.name, "Has a base at   " .. row.x .. " " .. row.y .. " " .. row.z .. "   size " .. row.protectSize .. " " .. prot)
		end

		row = cursor:fetch(row, "a")
	end

	if players[irc_params.pid].hackerScore then irc_chat(irc_params.name, "Hacker score: " .. players[irc_params.pid].hackerScore) end

	if players[irc_params.pid].timeout == true then
		irc_chat(irc_params.name, "Is in timeout")
	else
		irc_chat(irc_params.name, "Not in timeout")
	end

	if players[irc_params.pid].prisoner then
		irc_chat(irc_params.name, "Is a prisoner")
		if players[irc_params.pid].prisonReason ~= nil then irc_chat(irc_params.name, "Reason Arrested: " .. players[irc_params.pid].prisonReason) end
	else
		irc_chat(irc_params.name, "Not a prisoner")
	end

	irc_chat(irc_params.name, server.moneyPlural .. " " .. string.format("%d", players[irc_params.pid].cash))
	irc_chat(irc_params.name, "Keystones placed " .. players[irc_params.pid].keystones)
	irc_chat(irc_params.name, "Zombies " .. players[irc_params.pid].zombies)
	irc_chat(irc_params.name, "Score " .. players[irc_params.pid].score)
	irc_chat(irc_params.name, "Deaths " .. players[irc_params.pid].deaths)
	irc_chat(irc_params.name, "PVP kills " .. players[irc_params.pid].playerKills)
	irc_chat(irc_params.name, "Level " .. players[irc_params.pid].level)
	irc_chat(irc_params.name, "Current Session " .. players[irc_params.pid].sessionCount)
	irc_chat(irc_params.name, "IP https://www.whois.com/whois/" .. players[irc_params.pid].ip)
	irc_chat(irc_params.name, "Ping " .. players[irc_params.pid].ping .. " Country: " .. players[irc_params.pid].country)

	if players[irc_params.pid].china then
		irc_chat(irc_params.name, "China IP detected")
	end

	if players[irc_params.pid].exiled then
		irc_chat(irc_params.name, "Is exiled")
	else
		irc_chat(irc_params.name, "Not exiled")
	end

	if players[irc_params.pid].inLocation then
		if players[irc_params.pid].inLocation ~= "" then
			irc_chat(irc_params.name, "In location " .. players[irc_params.pid].inLocation)
		else
			irc_chat(irc_params.name, "Not in a named location")
		end
	end

	irc_chat(irc_params.name, "Current position " .. players[irc_params.pid].xPos .. " " .. players[irc_params.pid].yPos .. " " .. players[irc_params.pid].zPos)

	if donor then
		irc_chat(irc_params.name, "Is a donor")
		if expiry then
			irc_chat(irc_params.name, "Expires on " .. os.date("%Y-%m-%d %H:%M:%S",  expiry))
		end
	else
		irc_chat(irc_params.name, "Not a donor")
	end

	if players[irc_params.pid].groupID == 0 then
		irc_chat(irc_params.name, "Not in a player group")
	else
		irc_chat(irc_params.name, "Is a member of player group " .. playerGroups["G" .. players[irc_params.pid].groupID].name)
	end

	cursor,errorString = conn:execute("SELECT * FROM bans WHERE steam =  '" .. irc_params.player.steam .. "' or steam =  '" .. irc_params.player.userID .. "'")
	if cursor:numrows() > 0 then
		row = cursor:fetch({}, "a")
		irc_chat(irc_params.name, "BANNED until " .. row.BannedTo .. " " .. row.Reason)
	else
		irc_chat(irc_params.name, "Is not banned")
	end

	irc_chat(irc_params.name, "----")
end


function listStaff(steam, ingame)
	local tmp

	tmp = {}

	-- players do not see steam ID's of staff unless they are staff too.

	-- steam can be passed an irc nick so we need to do a lookup
	tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(steam, "all")

	if igplayers[tmp.steam] and ingame then
		message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]The staff are:[-]")
	else
		irc_chat(irc_params.name, "The staff are:")
	end

	for k, v in pairs(staffList) do
		tmp.staffSteam, tmp.staffSteamOwner, tmp.staffUserID, tmp.staffPlatform = LookupPlayer(v.userID, "all")
		tmp.staffName = ""

		if players[tmp.staffSteam] then
			tmp.staffName = players[tmp.staffSteam].name
		else
			if v.name then
				tmp.staffName = v.name
			end
		end

		if tmp.staffSteam == "0" then
			tmp.staffSteam = k

			if tonumber(k) then
				tmp.staffPlatform = "Steam"
			end
		end

		if tmp.staffPlatform == "" then
			tmp.staffID = tmp.staffSteam
		else
			tmp.staffID = tmp.staffPlatform .. "_" .. tmp.staffSteam
		end

		if igplayers[tmp.staffSteam] then
			tmp.online = "  [IN GAME NOW]"
		else
			tmp.online = " "
		end

		if isAdminHidden(tmp.steam, tmp.userID) then
			if igplayers[tmp.steam] and ingame then
				if not players[tmp.staffSteam] or tmp.staffSteam == "0" then
					message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]" .. tmp.staffID .. " level " .. v.adminLevel .. " " .. tmp.staffName .. "[-]")
				else
					message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]" .. tmp.staffID .. " level " .. v.adminLevel .. " " .. tmp.staffName .. tmp.online .. "[-]")
				end
			else
				if not players[tmp.staffSteam] or tmp.staffSteam == "0" then
					irc_chat(irc_params.name, tmp.staffID .. " level " .. v.adminLevel ..  " " ..tmp.staffName)
				else
					irc_chat(irc_params.name, tmp.staffID .. " level " .. v.adminLevel .. " " .. tmp.staffName .. tmp.online)
				end
			end
		else
			if igplayers[tmp.steam] and ingame then
				if players[tmp.staffSteam] then
					message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]" .. tmp.staffName .. tmp.online .. "[-]")
				end
			else
				if players[tmp.staffSteam] then
					irc_chat(irc_params.name,  tmp.staffName .. tmp.online)
				end
			end
		end
	end

	if not igplayers[tmp.steam] then
		irc_chat(irc_params.name, ".")
	end
end


function irc_friend()
	-- add to friends table
	if addFriend(irc_params.pid, irc_params.pid2) then
		irc_chat(irc_params.name, players[irc_params.pid].name .. " is now friends with " .. players[irc_params.pid2].name)
	else
		irc_chat(irc_params.name, players[irc_params.pid].name .. " is already friends with " .. players[irc_params.pid2].name)
	end

	irc_chat(irc_params.name, ".")
end


function irc_unfriend()
	irc_chat(irc_params.name, players[irc_params.pid].name .. " is no longer friends with " .. players[irc_params.pid2].name)
	irc_chat(irc_params.name, ".")

	conn:execute("DELETE FROM friends WHERE steam = '" .. irc_params.pid .. "' AND friend = '" .. irc_params.pid2 .. "'")
	tempTimer( 3, [[loadFriends()]] )
end


function irc_friends()
	local friendlist, steam, k, v

	irc_chat(irc_params.name, players[irc_params.pid].name .. " is friends with..")

	if countFriends(irc_params.pid) == 0 then
		irc_chat(irc_params.name, "Nobody :(")
	else
		for k,v in pairs(friends[irc_params.pid].friends) do
			steam = LookupPlayer(k, "all")

			if players[steam] then
				irc_chat(irc_params.name, steam .. " " .. players[steam].name)
			else
				irc_chat(irc_params.name, k .. " - An old friend not known to the bot")
			end
		end
	end

	irc_chat(irc_params.name, ".")
end


function irc_new_players(name)
	local steam, steamOwner, userID, x, z

	steam, steamOwner, userID = LookupOfflinePlayer(name, "all")

	irc_chat(name, "New players in the last 2 days:")

	for k, v in pairs(players) do
		if v.firstSeen ~= nil then
			if ((os.time() - tonumber(v.firstSeen)) < 86401) then
				if not isAdminHidden(steam, userID) then
					irc_chat(name, v.name)
				else
					irc_chat(name, "steam: " .. k .. " id: " .. v.id .. " name: " .. v.name .. " at " .. v.xPos .. " " .. v.yPos .. " " .. v.zPos)
				end
			end
		end
	end

	irc_chat(name, ".")
end


function irc_server_status(name, days)
	irc_chat(name, "The server date is " .. botman.serverTime)

	if days == nil then
		irc_chat(name, "24 hour stats to now:")
		days = 1
	else
		irc_chat(name, "Last " .. days .. " days stats to now:")
	end

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%pvp%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "PVPs: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%timeout%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "Timeouts: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%arrest%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "Arrests: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%new%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "New players: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%ban%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "Bans: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%hack%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "Hack events: " .. row.number)
end


function irc_server_event(name, event, steam, days)
	if days == 0 then
		irc_chat(name, event .. " events in the last 24 hours:")
		days = 1
	else
		irc_chat(name, event .. " events in the last " .. days .. " days:")
	end

	if steam == "0" then
		cursor,errorString = conn:execute("SELECT * FROM events WHERE (type LIKE '%" .. event .. "%' or event LIKE '%" .. event .. "%') AND timestamp >= DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	else
		cursor,errorString = conn:execute("SELECT * FROM events WHERE (steam = '" .. steam .. "' AND type LIKE '%" .. event .. "%' or event LIKE '%" .. event .. "%') AND timestamp >= DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	end

	row = cursor:fetch({}, "a")
	while row do
		irc_chat(name, row.serverTime .. " " .. row.event .. " at " .. row.x .. " " .. row.y - 1 .. " " .. row.z)
		row = cursor:fetch(row, "a")
	end

	irc_chat(name, ".")
end


function irc_players(name)
	local x, z, flags, line, index, country
	local steam, userID

	connMEM:execute("DELETE FROM list")
	steam, userID = LookupIRCAlias(name, "all")
	index = 1

	irc_chat(name, "The following players are in-game right now:")

	for k, v in pairs(igplayers) do
		x = math.floor(v.xPos / 512)
		z = math.floor(v.zPos / 512)

		flags = " "
		line = ""

		if isAdminHidden(k, v.userID) then
			flags = flags .. "[ADMIN]"
		end

		if players[k].newPlayer then
			flags = flags .. "[NEW]"
		end

		if players[k].timeout then flags = flags .. "[TIMEOUT]" end
		if players[k].prisoner then flags = flags .. "[PRISONER]" end

		if isDonor(k) then
			flags = flags .. "[DONOR]"
		end

		if players[k].country then
			country = players[k].country
		else
			country = "N/A"
		end

		if tonumber(players[k].hackerScore) > 0 then
			flags = flags .. "[HACKER]"

			if v.flying then
				flags = flags .. "[FLYING " .. v.flyingHeight .. "]"
			end

			if v.noclip then
				flags = flags .. "[NOCLIP]"
			end
		end

		if (not isAdminHidden(steam, userID)) then
			line = "#" .. index .. " " .. v.name .. " score: " .. string.format("%d", v.score) .. "| PVP: " .. string.format("%d", v.playerKills) .. "| zeds: " .. string.format("%d", v.zombies) .. "| level: " .. v.level .. " " .. flags .. "| " .. country .. "| ping: " .. v.ping .. "| Hacker score: " .. players[k].hackerScore
		else
			if players[steam].ircAuthenticated then
				if players[k].country then
					country = players[k].country
				else
					country = "N/A"
				end

				if v.inLocation ~= "" then
					if v.platform ~= "Steam" then
						line = "#" .. index .. " " .. v.name  .. flags .. " @ " .. v.xPos .. " " .. v.yPos .. " " .. v.zPos .. " in " .. v.inLocation .. " | " .. v.platform .. " " .. k .. " | " .. v.userID ..  "| id: " .. v.id .. "| score: " .. string.format("%d", v.score) .. "| PVP: " .. string.format("%d", v.playerKills) .. "| zeds: " .. string.format("%d", v.zombies) .. "| level: " .. v.level .. "| region r." .. x .. "." .. z .. ".7rg | " .. country .. "| ping: " .. v.ping .. "| Hacker score: " .. players[k].hackerScore
					else
						line = "#" .. index .. " " .. v.name  .. flags .. " @ " .. v.xPos .. " " .. v.yPos .. " " .. v.zPos .. " in " .. v.inLocation .. " | " .. k .. " | " .. v.userID ..  "| id: " .. v.id .. "| score: " .. string.format("%d", v.score) .. "| PVP: " .. string.format("%d", v.playerKills) .. "| zeds: " .. string.format("%d", v.zombies) .. "| level: " .. v.level .. "| region r." .. x .. "." .. z .. ".7rg | " .. country .. "| ping: " .. v.ping .. "| Hacker score: " .. players[k].hackerScore
					end
				else
					if v.platform ~= "Steam" then
						line = "#" .. index .. " " .. v.name  .. flags .. " @ " .. v.xPos .. " " .. v.yPos .. " " .. v.zPos .. " | " .. v.platform .. " " .. k .. " | " .. v.userID ..  " | id: " .. v.id .. " | score: " .. string.format("%d", v.score) .. " | PVP: " .. string.format("%d", v.playerKills) .. " | zeds: " .. string.format("%d", v.zombies) .. " | level: " .. v.level .. " | region r." .. x .. "." .. z .. ".7rg | " .. country .. " | ping: " .. v.ping .. " | Hacker score: " .. players[k].hackerScore
					else
						line = "#" .. index .. " " .. v.name  .. flags .. " @ " .. v.xPos .. " " .. v.yPos .. " " .. v.zPos .. " | " .. k .. " | " .. v.userID ..  " | id: " .. v.id .. " | score: " .. string.format("%d", v.score) .. " | PVP: " .. string.format("%d", v.playerKills) .. " | zeds: " .. string.format("%d", v.zombies) .. " | level: " .. v.level .. " | region r." .. x .. "." .. z .. ".7rg | " .. country .. " | ping: " .. v.ping .. " | Hacker score: " .. players[k].hackerScore
					end
				end
			else
				if v.platform ~= "Steam" then
					line = "#" .. index .. " " .. v.platform .. " " .. k .. " " .. v.name .. "| score: " .. string.format("%d", v.score) .. "| PVP: " .. string.format("%d", v.playerKills) .. "| zeds: " .. string.format("%d", v.zombies) .. " " .. flags .. "| ping: " .. v.ping .. "| Hacker score: " .. players[k].hackerScore
				else
					line = "#" .. index .. " " .. k .. " " .. v.name .. "| score: " .. string.format("%d", v.score) .. "| PVP: " .. string.format("%d", v.playerKills) .. "| zeds: " .. string.format("%d", v.zombies) .. " " .. flags .. "| ping: " .. v.ping .. "| Hacker score: " .. players[k].hackerScore
				end
			end
		end

		index = index + 1
		connMEM:execute("INSERT INTO list (id, thing) VALUES (" .. index .. ",'" .. connMEM:escape(line) .. "')")
	end

	cursor,errorString = connMEM:execute("SELECT * FROM list ORDER BY id")
	row = cursor:fetch({}, "a")

	while row do
		irc_chat(name, row.thing)
		row = cursor:fetch(row, "a")
	end

	connMEM:execute("DELETE FROM list")
	irc_chat(irc_params.name, "There are " .. botman.playersOnline .. " players online.")
	irc_chat(name, ".")
end


function irc_who_played(name)
	local tmp = {}

	tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(name, "all")
	irc_chat(name, "The following players joined the server over the last 24 hours:")

	cursor,errorString = conn:execute("SELECT steam, userID, serverTime FROM events WHERE type = 'player joined' AND timestamp >= DATE_SUB(now(), INTERVAL 1 DAY) ORDER BY timestamp desc")

	row = cursor:fetch({}, "a")
	while row do
		if (not isAdminHidden(tmp.steam, tmp.userID)) then
			irc_chat(name, row.serverTime .. " " .. players[row.steam].name)
		else
			irc_chat(name, row.serverTime .. " " .. players[row.steam].platform .. " " .. row.steam .. " " .. row.userID .. " " .. players[row.steam].name)
		end

		row = cursor:fetch(row, "a")
	end

	irc_chat(name, ".")
end


function irc_listResetZones(name)
   local a = {}
	local n
	local sid
	local pid

	irc_chat(name, "The following regions are designated reset zones:")

   for n in pairs(resetRegions) do
		table.insert(a, n)
	end

	table.sort(a)

   for k, v in ipairs(a) do
		irc_chat(name, "region: " .. v)
	end

	irc_chat(name, ".")
end


function irc_gameTime(name)
	irc_chat(name, "The game date is: " .. server.gameDate)
	irc_uptime(name)
end


function irc_uptime(name)
	local days, diff, hours, minutes

	irc_chat(name, "The server time is " .. os.date("%Y-%m-%d %H:%M:%S", calculateServerTime(os.time())))

	diff = os.difftime(os.time(), botman.botStarted)
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (hours > 0) then
		diff = diff - (hours * 3600)
	end

	minutes = math.floor(diff / 60)

	irc_chat(name, server.botName .. " has been online " .. days .. " days " .. hours .. " hours " .. minutes .." minutes")

	if tonumber(server.uptime) < 0 then
		irc_chat(name, "Server uptime is unknown")
	else
		diff = server.uptime
		days = math.floor(diff / 86400)

		if (days > 0) then
			diff = diff - (days * 86400)
		end

		hours = math.floor(diff / 3600)

		if (hours > 0) then
			diff = diff - (hours * 3600)
		end

		minutes = math.floor(diff / 60)
		irc_chat(name, "Server uptime is " .. days .. " days " .. hours .. " hours " .. minutes .." minutes")
	end

	irc_chat(name, ".")
end


function irc_listAllPlayers(name) --tested
    local a = {}
	local n, isADonor, adminPlayer, isPrisoner, isBanned
	local steam, steamOwner, userID

	irc_chat(name, "These are all the players on record:")

    for n in pairs(players) do
		table.insert(a, players[n].name)
	end

	table.sort(a)

	if irc_params.pname == nil then
		for k, v in ipairs(a) do
			steam, steamOwner, userID = LookupOfflinePlayer(v, "all")

			if steam ~= "0" then
				if players[steam].prisoner then
					isPrisoner = "Prisoner"
				else
					isPrisoner = ""
				end

				if isDonor(steam) then
					isADonor = "Donor"
				else
					isADonor = ""
				end

				if isAdminHidden(steam, userID) then
					adminPlayer = "Admin"
				else
					adminPlayer = "Player"
				end

				cmd = "steam: " .. steam .. " id: " .. players[steam].id .. " name: " .. v .. " [ " .. string.trim(adminPlayer .. " " .. isADonor .. " " .. isPrisoner) .. " ] seen " .. players[steam].seen .. " playtime " .. players[steam].playtime .. " cash " .. players[steam].cash
				irc_chat(irc_params.name, cmd)
			end
		end
	else
		steam, steamOwner, userID = LookupPlayer(irc_params.pname)

		if players[steam] then
			if players[steam].prisoner then
				isPrisoner = "Prisoner"
			else
				isPrisoner = ""
			end

			if isDonor(steam) then
				isADonor = "Donor"
			else
				isADonor = ""
			end

			if isAdminHidden(steam, userID) then
				adminPlayer = "Admin"
			else
				adminPlayer = "Player"
			end

			cmd = "steam: " .. steam .. " id: " .. players[steam].id .. " name: " .. players[steam].name .. " [ " .. string.trim(adminPlayer .. " " .. isADonor .. " " .. isPrisoner) .. " ] seen " .. players[steam].seen .. " playtime " .. players[steam].playtime .. " cash " .. players[steam].cash
			irc_chat(irc_params.name, cmd)
		else
			irc_chat(irc_params.name, "No player found like " .. irc_params.pname)
		end
	end

	irc_chat(name, ".")
end


function irc_listAllArchivedPlayers(name) --tested
    local a = {}
	local n, isADonor, adminPlayer, isPrisoner, isBanned
	local steam, steamOwner, userID

    for n in pairs(playersArchived) do
		table.insert(a, playersArchived[n].name)
	end

	table.sort(a)

	if irc_params.pname == nil then
		irc_chat(name, "These are all the archived players on record:")

		for k, v in ipairs(a) do
			steam, steamOwner, userID = LookupArchivedPlayer(v, "all")

			if steam ~= "0" then
				if playersArchived[steam].prisoner then
					isPrisoner = "Prisoner"
				else
					isPrisoner = ""
				end

				if isDonor(steam) then
					isADonor = "Donor"
				else
					isADonor = ""
				end

				if isAdminHidden(steam, userID) then
					adminPlayer = "Admin"
				else
					adminPlayer = "Player"
				end

				cmd = "steam: " .. steam .. " id: " .. playersArchived[steam].id .. " name: " .. v .. " [ " .. adminPlayer .. " " .. isADonor .. " " .. isPrisoner .. " ] seen " .. playersArchived[steam].seen .. " playtime " .. playersArchived[steam].playtime
				irc_chat(irc_params.name, cmd)
			end
		end
	else
		irc_chat(name, "Archived player " .. irc_params.pname .. ":")
		steam, steamOwner, userID = LookupArchivedPlayer(irc_params.pname)

		if playersArchived[steam] then
			if playersArchived[steam].prisoner then
				isPrisoner = "Prisoner"
			else
				isPrisoner = ""
			end

			if isDonor(steam) then
				isADonor = "Donor"
			else
				isADonor = ""
			end

			if isAdminHidden(steam, userID) then
				adminPlayer = "Admin"
			else
				adminPlayer = "Player"
			end

			cmd = "steam: " .. steam .. " id: " .. playersArchived[steam].id .. " name: " .. playersArchived[steam].name .. " [ " .. string.trim(adminPlayer .. " " .. isADonor .. " " .. isPrisoner) .. " ] seen " .. playersArchived[steam].seen .. " playtime " .. playersArchived[steam].playtime .. " cash " .. playersArchived[steam].cash
			irc_chat(irc_params.name, cmd)
		else
			irc_chat(irc_params.name, "No player found like " .. irc_params.pname)
		end
	end

	irc_chat(name, ".")
end


function irc_IGPlayerInfo()
	if (players[irc_params.pid]) then
		if igplayers[irc_params.pid] then
			irc_chat(irc_params.name, "In-Game Player record of: " .. irc_params.pname)
			for k, v in pairs(igplayers[irc_params.pid]) do
				cmd = ""

				if k ~= "inventory" and k ~= "inventoryLast" then
					if irc_params.search ~= "" then
						if string.find(string.lower(k), irc_params.search) then
							cmd = k .. "," .. tostring(v)
						end
					else
						cmd = k .. "," .. tostring(v)
					end

					if cmd ~= "" then
						irc_chat(irc_params.name, cmd)
					end
				end
			end
		else
			irc_chat(irc_params.name, "There is currently no in-game record for " .. irc_params.pname .. ". It gets deleted after they leave the server.")
		end
	else
		irc_chat(irc_params.name, "I do not know a player called " .. irc_params.pname)
	end

	irc_chat(irc_params.name, ".")
end


function irc_playerStatus()
	local protected, base
	local cursor, errorString, row, prot

	cursor,errorString = conn:execute("SELECT bases.steam, name, x, y, z, baseNumber, title, bases.protect, bases.protectSize from players inner join bases where players.steam = bases.steam and players.steam = '" .. irc_params.pid .. "' order by name, bases.steam")
	row = cursor:fetch({}, "a")

	irc_chat(irc_params.name, irc_params.pname .. " has " .. string.format("%d", players[irc_params.pid].cash) .. " " .. server.moneyPlural .. "")

	if players[irc_params.pid].bedX ~= 0 and players[irc_params.pid].bedY ~= 0 and players[irc_params.pid].bedZ ~= 0 then
		irc_chat(irc_params.name, "Has a bedroll at " .. players[irc_params.pid].bedX .. " " .. players[irc_params.pid].bedY .. " " .. players[irc_params.pid].bedZ )
	else
		irc_chat(irc_params.name, "Does not have a bedroll down or its location is not recorded yet.")
	end

	if not row then
		irc_chat(irc_params.name, irc_params.pname .. " has no bases.")
	else
		while row do
			if tonumber(row.protect) == 1 then
				prot = "protected"
			else
				prot = "not protected"
			end

			if row.title ~= "" then
				irc_chat(irc_params.name, "Has base " .. row.baseNumber .. " called " .. row.title .. " at   " .. row.x .. " " .. row.y .. " " .. row.z .. "   of size " .. row.protectSize .. " and is " .. prot)
			else
				irc_chat(irc_params.name, "Has base " .. row.baseNumber .. " at   " .. row.x .. " " .. row.y .. " " .. row.z .. "   of size " .. row.protectSize .. " and is " .. prot)
			end

			row = cursor:fetch(row, "a")
		end
	end

	irc_chat(irc_params.name, ".")
end
