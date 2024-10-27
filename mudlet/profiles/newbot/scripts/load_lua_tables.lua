--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

local debug
debug = false -- should be false unless testing


function loadBadItems()
	local cursor, errorString, row, k, v

	calledFunction = "badItems"
	if (debug) then dbug("debug badItems line " .. debugger.getinfo(1).currentline) end

	-- load badItems
	getTableFields("badItems")

	badItems = {}
	cursor,errorString = conn:execute("SELECT * FROM badItems")
	row = cursor:fetch({}, "a")

	while row do
		if (debug) then dbug("debug loadBadItem " .. row.item) end

		badItems[row.item] = {}

		for k,v in pairs(badItemsFields) do
			if v.type == "var" or v.type == "big" then
				badItems[row.item][k] = row[k]
			end

			if v.type == "int" or v.type == "flo" then
				badItems[row.item][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				badItems[row.item][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug badItems line end") end
end


function loadBadWords()
	local cursor, errorString, row

	-- load badWords
	badWords = {}
	cursor,errorString = conn:execute("SELECT * FROM badWords")
	row = cursor:fetch({}, "a")

	while row do
		badWords[row.badWord] = {} -- @%&$*! >:(
		badWords[row.badWord].cost = tonumber(row.cost)
		badWords[row.badWord].counter = tonumber(row.counter)
		badWords[row.badWord].response = row.response
		badWords[row.badWord].cooldown = tonumber(row.cooldown)
		row = cursor:fetch(row, "a")
	end
end


function loadBans()
	local cursor, errorString, row

	-- load bans
    bans = {}
	cursor,errorString = conn:execute("SELECT * FROM bans")
	row = cursor:fetch({}, "a")

	while row do
		bans[row.Steam] = {}
		bans[row.Steam].steam = row.Steam
		bans[row.Steam].BannedTo = row.BannedTo
		bans[row.Steam].Reason = row.Reason
		bans[row.Steam].expiryDate = row.expiryDate
		bans[row.Steam].userID = row.userID
		bans[row.Steam].platform = row.platform

		row = cursor:fetch(row, "a")
	end
end


function loadBases()
	local cursor, errorString, row

	-- load bases
    bases = {}
	cursor,errorString = conn:execute("SELECT * FROM bases")
	row = cursor:fetch({}, "a")

	while row do
		bases[row.steam .. "_" .. row.baseNumber] = {}
		bases[row.steam .. "_" .. row.baseNumber].steam = row.steam
		bases[row.steam .. "_" .. row.baseNumber].baseNumber = row.baseNumber
		bases[row.steam .. "_" .. row.baseNumber].title = row.title
		bases[row.steam .. "_" .. row.baseNumber].x = row.x
		bases[row.steam .. "_" .. row.baseNumber].y = row.y
		bases[row.steam .. "_" .. row.baseNumber].z = row.z
		bases[row.steam .. "_" .. row.baseNumber].exitX = row.exitX
		bases[row.steam .. "_" .. row.baseNumber].exitY = row.exitY
		bases[row.steam .. "_" .. row.baseNumber].exitZ = row.exitZ
		bases[row.steam .. "_" .. row.baseNumber].size = row.size
		bases[row.steam .. "_" .. row.baseNumber].protect = dbTrue(row.protect)
		bases[row.steam .. "_" .. row.baseNumber].protectSize = row.protectSize
		bases[row.steam .. "_" .. row.baseNumber].keepOut = dbTrue(row.keepOut)
		bases[row.steam .. "_" .. row.baseNumber].creationTimestamp = row.creationTimestamp
		bases[row.steam .. "_" .. row.baseNumber].creationGameDay = row.creationGameDay

		row = cursor:fetch(row, "a")
	end

	-- load base members too
	loadBaseMembers()
end


function loadBaseMembers()
	local cursor, errorString, row

	-- load base members
    baseMembers = {}
	cursor,errorString = conn:execute("SELECT * FROM baseMembers")
	row = cursor:fetch({}, "a")

	while row do
		if not baseMembers[row.baseOwner .. "_" .. row.baseNumber] then
			baseMembers[row.baseOwner .. "_" .. row.baseNumber] = {}
			baseMembers[row.baseOwner .. "_" .. row.baseNumber].baseOwner = row.baseOwner
			baseMembers[row.baseOwner .. "_" .. row.baseNumber].baseNumber = row.baseNumber
			baseMembers[row.baseOwner .. "_" .. row.baseNumber].baseMembers = {}
		end

		baseMembers[row.baseOwner .. "_" .. row.baseNumber].baseMembers[row.baseMember] = {}

		row = cursor:fetch(row, "a")
	end
end


function loadHelpCommands(JSON)
	local cursor, errorString, row, key
	local file

	helpCommands = {}
	cursor,errorString = connSQL:execute("SELECT * FROM helpCommands")

	row = cursor:fetch({}, "a")
	while row do
		key = row.topic .. "_" .. row.functionName
		helpCommands[key] = {}
		helpCommands[key].accessLevel = tonumber(row.accessLevel)
		helpCommands[key].ingameOnly = dbTrue(row.ingameOnly)

		-- force the /yes command to work anywhere.
		if key == "misc_cmd_Yes" or key == "bot_cmd_ResetBot" or key == "bot_cmd_ResetServer" or key == "bot_cmd_QuickResetBot" then
			helpCommands[key].ingameOnly = false
		end

		if JSON then
			helpCommands[key].command = row.command
			helpCommands[key].topic = row.topic
		end

		row = cursor:fetch(row, "a")
	end

	if JSON then
		os.remove(botman.chatlogPath .. "/temp/commands.json")
		file = io.open(botman.chatlogPath .. "/temp/commands.json", "a")
		file:write(yajl.to_string(helpCommands))
		file:close()
	end
end


function loadCustomMessages()
	local cursor, errorString, row

	-- load customMessages
	customMessages = {}
	cursor,errorString = conn:execute("SELECT * FROM customMessages")
	row = cursor:fetch({}, "a")

	while row do
		customMessages[row.command] = {}
		customMessages[row.command].message = row.message
		customMessages[row.command].accessLevel = tonumber(row.accessLevel)
		row = cursor:fetch(row, "a")
	end
end


function loadDonors(steam)
	local cursor, errorString, row

	-- load donors
	if not steam then
		donors = {}
		cursor,errorString = conn:execute("SELECT * FROM donors")
	else
		cursor,errorString = conn:execute("SELECT * FROM donors WHERE steam = '" .. steam .. "'")
	end

	row = cursor:fetch({}, "a")

	while row do
		donors[row.steam] = {}
		donors[row.steam].steam = row.steam
		donors[row.steam].expiry = row.expiry
		donors[row.steam].name = row.name
		donors[row.steam].expired = dbTrue(row.expired)
		row = cursor:fetch(row, "a")
	end
end


function loadFriends(steam)
	local cursor, errorString, row

	-- load friends
	if steam == nil then
		friends = {}
		cursor,errorString = conn:execute("SELECT * FROM friends")
	else
		cursor,errorString = conn:execute("SELECT * FROM friends WHERE steam = '" .. steam .. "'")
		friends[steam] = {}
	end

	row = cursor:fetch({}, "a")

	while row do
		if not friends[row.steam] then
			friends[row.steam] = {}
			friends[row.steam].friends = {}
		end

		friends[row.steam].friends[row.friend] = {}

		row = cursor:fetch(row, "a")
	end
end


function loadGimmePrizes()
	local cursor, errorString, row, cat, k, v

	-- load gimmePrizes
	getTableFields("gimmePrizes")

	gimmePrizes = {}
	cursor,errorString = conn:execute("SELECT * FROM gimmePrizes")

	row = cursor:fetch({}, "a")
	while row do
		gimmePrizes[row.name] = {}

		for k,v in pairs(gimmePrizesFields) do
			if v.type == "var" or v.type == "big" then
				gimmePrizes[row.name][k] = row[k]
			end

			if v.type == "int" or v.type == "flo" then
				gimmePrizes[row.name][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				gimmePrizes[row.name][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end
end


function loadGimmeZombies()
	local cursor, errorString, row, rows, k, v, n, m, strIdx

	calledFunction = "gimmeZombies"
	if (debug) then dbug("debug gimmeZombies line " .. debugger.getinfo(1).currentline) end

	-- load gimmeZombies
	gimmeZombies = {}

	cursor,errorString = conn:execute("SELECT * FROM gimmeZombies")
	rows = tonumber(cursor:numrows())
	row = cursor:fetch({}, "a")

	botman.maxGimmeZombies = tonumber(rows)

	if row then
		cols = cursor:getcolnames()
	end

	while row do
		strIdx = tostring(row.entityID)
		gimmeZombies[strIdx] = {}
		gimmeZombies[strIdx].entityID = row.entityID
		gimmeZombies[strIdx].zombie = row.zombie
		gimmeZombies[strIdx].minPlayerLevel = row.minPlayerLevel
		gimmeZombies[strIdx].minArenaLevel = row.minArenaLevel
		gimmeZombies[strIdx].bossZombie = dbTrue(row.bossZombie)
		gimmeZombies[strIdx].doNotSpawn = dbTrue(row.doNotSpawn)
		gimmeZombies[strIdx].maxHealth = row.maxHealth
		gimmeZombies[strIdx].remove = dbTrue(row.remove)

		row = cursor:fetch(row, "a")
	end

	for k,v in pairs(gimmeZombies) do
		if string.find(v.zombie, "Radiated") or string.find(v.zombie, "Feral") then
			v.bossZombie = true
		end
	end

	if (debug) then dbug("debug gimmeZombies line end") end
end


function loadHotspots()
	local idx, nextidx
	local cursor, errorString, row

	nextidx = -1

	calledFunction = "hotspots"
	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	-- load hotspots
	getTableFields("hotspots")

	hotspots = {}
	cursor,errorString = conn:execute("SELECT * FROM hotspots")
	row = cursor:fetch({}, "a")

	if row then
		cols = cursor:getcolnames()
	end

	while row do
		idx = tonumber(row.idx)

		if idx == 0 then
			if nextidx == -1 then
				idx = 1
				nextidx = 2
			else
				idx = nextidx
				nextidx = nextidx + 1
			end

			conn:execute("UPDATE hotspots SET idx = " .. idx .. " WHERE id = " .. row.id)
		end

		hotspots[idx] = {}

		for k,v in pairs(cols) do
			for n,m in pairs(row) do
				if n == _G["hotspotsFields"][v].field then
					if _G["hotspotsFields"][v].type == "var" or _G["hotspotsFields"][v].type == "big" then
						hotspots[idx][n] = m
					end

					if _G["hotspotsFields"][v].type == "int" then
						hotspots[idx][n] = tonumber(m)
					end

					if _G["hotspotsFields"][v].type == "tin" then
						hotspots[idx][n] = dbTrue(m)
					end
				end
			end
		end

		row = cursor:fetch(row, "a")
	end
end


function loadKeystones()
	local cursor, errorString, row, k, v, m, n, cols

	calledFunction = "loadKeystones"
	if (debug) then dbug("debug loadKeystones line " .. debugger.getinfo(1).currentline) end

	keystones = {}
	cursor,errorString = connSQL:execute("SELECT * FROM keystones")
	row = cursor:fetch({}, "a")

	while row do
		keystones[row.x .. row.y .. row.z] = {}
		keystones[row.x .. row.y .. row.z].userID = row.steam
		keystones[row.x .. row.y .. row.z].x = row.x
		keystones[row.x .. row.y .. row.z].y = row.y
		keystones[row.x .. row.y .. row.z].z = row.z
		keystones[row.x .. row.y .. row.z].remove = dbTrue(row.remove)
		keystones[row.x .. row.y .. row.z].removed = tonumber(row.removed)
		keystones[row.x .. row.y .. row.z].expired = dbTrue(row.expired)

		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug loadKeystones end") end
end


function loadJoiningPlayers()
	local cursor, errorString, row, k, v, m, n, cols

	calledFunction = "loadJoiningPlayers"
	if (debug) then dbug("debug loadJoiningPlayers line " .. debugger.getinfo(1).currentline) end

	joiningPlayers = {}
	cursor,errorString = connSQL:execute("SELECT * FROM joiningPlayers")
	row = cursor:fetch({}, "a")

	while row do
		joiningPlayers[row.steam] = {}
		joiningPlayers[row.steam].steam = row.steam
		joiningPlayers[row.steam].userID = row.userID
		joiningPlayers[row.steam].name = row.name

		row = cursor:fetch(row, "a")
	end

	connSQL:execute("DELETE FROM joiningPlayers WHERE timestamp < " .. os.time() - 86400)

	if (debug) then dbug("debug loadJoiningPlayers end") end
end


function loadLocationCategories()
	local cursor, errorString, row

	-- load locationCategories
	locationCategories = {}
	cursor,errorString = conn:execute("SELECT * FROM locationCategories")
	row = cursor:fetch({}, "a")

	while row do
		locationCategories[row.categoryName] = {}
		locationCategories[row.categoryName].minAccessLevel = row.minAccessLevel
		locationCategories[row.categoryName].maxAccessLevel = row.maxAccessLevel
		row = cursor:fetch(row, "a")
	end
end


function loadLocations(loc)
	local cursor, errorString, row, k, v, m, n, cols

	calledFunction = "loadLocations"
	if (debug) then dbug("debug loadLocations line " .. debugger.getinfo(1).currentline) end

	getTableFields("locations")

	if type(locations) ~= "table" then
		locations = {}
	end

	if loc == nil then
		locations = {}
		cursor,errorString = conn:execute("SELECT * FROM locations")
	else
		cursor,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. escape(loc) .. "'")
	end

	row = cursor:fetch({}, "a")

	while row do
		if (debug) then dbug("debug loadLocation " .. row.name) end

		locations[row.name] = {}

		for k,v in pairs(locationsFields) do
			if v.type == "var" or v.type == "big" then
				locations[row.name][k] = row[k]
			end

			if v.type == "int" or v.type == "flo" then
				locations[row.name][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				locations[row.name][k] = dbTrue(row[k])
			end
		end

		locations[row.name].open = true
		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug loadLocations end") end
end


function loadModBotman()
	local cursor, errorString, row, modBotmanOld

	-- load modBotman
	if type(modBotman) == "table" then
		-- copy the current contents of the modBotman table into modBotmanOld so we can see what's changed later
		modBotmanOld = {}
		for k,v in pairs(modBotman) do
			modBotmanOld[k] = v
		end
	end

    modBotman = {}
	cursor,errorString = conn:execute("SELECT * FROM modBotman")
	row = cursor:fetch({}, "a")

	if row then
		modBotman.anticheat = dbTrue(row.anticheat)
		modBotman.botName = row.botName
		modBotman.botNameColourPublic = row.botNameColourPublic
		modBotman.botNameColourPrivate = row.botNameColourPrivate
		modBotman.chatCommandPrefix = row.chatCommandPrefix
		modBotman.chatCommandsHidden = dbTrue(row.chatCommandsHidden)
		modBotman.clanEnabled = dbTrue(row.clanEnabled)
		modBotman.clanMaxClans = row.clanMaxClans
		modBotman.clanMaxPlayers = row.clanMaxPlayers
		modBotman.clanMinLevel = row.clanMinLevel
		modBotman.customMessagesEnabled = dbTrue(row.customMessagesEnabled)
		modBotman.dropminerEnabled = dbTrue(row.dropminerEnabled)
		modBotman.dropminerTriggerEntityCount = row.dropminerTriggerEntityCount
		modBotman.dropminerTriggerFallingCount = row.dropminerTriggerFallingCount
		modBotman.disableChatColours = dbTrue(row.disableChatColours)
		modBotman.killZonesEnabled = dbTrue(row.killZonesEnabled)
		modBotman.resetsEnabled = dbTrue(row.resetsEnabled)
		modBotman.resetsDelay = row.resetsDelay
		modBotman.resetsPrefabsOnly = dbTrue(row.resetsPrefabsOnly)
		modBotman.resetsRemoveLCB = dbTrue(row.resetsRemoveLCB)
		modBotman.version = row.version
		modBotman.webmapEnabled = dbTrue(row.webmapEnabled)
		modBotman.webmapColour = row.webmapColour
		modBotman.webmapPath = row.webmapPath
		modBotman.zombieAnnouncerEnabled = dbTrue(row.zombieAnnouncerEnabled)
		modBotman.zombieFreeTimeEnabled = dbTrue(row.zombieFreeTimeEnabled)
		modBotman.zombieFreeTimeStart = row.zombieFreeTimeStart
		modBotman.zombieFreeTimeEnd = row.zombieFreeTimeEnd
	else
		conn:execute("INSERT INTO modBotman SET version = '0'")
	end


	if server.botman then
		if modBotmanOld.anticheat ~= nil then
			if (modBotmanOld.anticheat ~= modBotman.anticheat) then
				if modBotman.anticheat then
					sendCommand("bm-anticheat enable")
				else
					sendCommand("bm-anticheat disable")
				end
			end
		else
			if modBotman.anticheat then
				sendCommand("bm-anticheat enable")
			else
				sendCommand("bm-anticheat disable")
			end
		end


		if modBotmanOld.botName ~= nil then
			if (modBotmanOld.botName ~= modBotman.botName) then
				sendCommand("bm-change botname " .. modBotman.botName)
				server.botName = stripBBCodes(modBotman.botName)
				conn:execute("UPDATE server SET botName = '" .. escape(server.botName) .. "'")
			end
		else
			server.botName = stripBBCodes(modBotman.botName)
			sendCommand("bm-change botname " .. server.botName)
			conn:execute("UPDATE server SET botName = '" .. escape(server.botName) .. "'")
		end


		if modBotmanOld.botNameColourPublic ~= nil then
			if (modBotmanOld.botNameColourPublic ~= modBotman.botNameColourPublic) then
				sendCommand("bm-change public-color " .. modBotman.botNameColourPublic)
				server.botNameColour = modBotman.botNameColourPublic
				conn:execute("UPDATE server SET botNameColour = '" .. escape(modBotman.botNameColourPublic) .. "'")
			end
		else
			sendCommand("bm-change public-color " .. modBotman.botNameColourPublic)
			server.botNameColour = modBotman.botNameColourPublic
			conn:execute("UPDATE server SET botNameColour = '" .. escape(modBotman.botNameColourPublic) .. "'")
		end


		if modBotmanOld.botNameColourPrivate ~= nil then
			if (modBotmanOld.botNameColourPrivate ~= modBotman.botNameColourPrivate) then
				sendCommand("bm-change public-color " .. modBotman.botNameColourPrivate)
			end
		else
			sendCommand("bm-change public-color " .. modBotman.botNameColourPrivate)
		end


		if modBotmanOld.chatCommandPrefix ~= nil then
			if (modBotmanOld.chatCommandPrefix ~= modBotman.chatCommandPrefix) then
				sendCommand("bm-chatcommands prefix " .. modBotman.chatCommandPrefix)
				server.commandPrefix = modBotman.chatCommandPrefix
				conn:execute("UPDATE server SET commandPrefix = '" .. escape(modBotman.chatCommandPrefix) .. "'")
			end
		else
			sendCommand("bm-chatcommands prefix " .. modBotman.chatCommandPrefix)
			server.commandPrefix = modBotman.chatCommandPrefix
			conn:execute("UPDATE server SET commandPrefix = '" .. escape(modBotman.chatCommandPrefix) .. "'")
		end


		if modBotmanOld.chatCommandsHidden ~= nil then
			if (modBotmanOld.chatCommandsHidden ~= modBotman.chatCommandsHidden) then
				if modBotman.chatCommandsHidden then
					sendCommand("bm-chatcommands hide true")
					server.hideCommands = true
					conn:execute("UPDATE server SET hideCommands = 1")
				else
					sendCommand("bm-chatcommands hide false")
					server.hideCommands = false
					conn:execute("UPDATE server SET hideCommands = 0")
				end
			end
		else
			if modBotman.chatCommandsHidden then
				sendCommand("bm-chatcommands hide true")
				server.hideCommands = true
				conn:execute("UPDATE server SET hideCommands = 1")
			else
				sendCommand("bm-chatcommands hide false")
				server.hideCommands = false
				conn:execute("UPDATE server SET hideCommands = 0")
			end
		end


		if modBotmanOld.clanEnabled ~= nil then
			if (modBotmanOld.clanEnabled ~= modBotman.clanEnabled) then
				if modBotman.clanEnabled then
					sendCommand("bm-clan enable")
				else
					sendCommand("bm-clan disable")
				end
			end
		else
			if modBotman.clanEnabled then
				sendCommand("bm-clan enable")
			else
				sendCommand("bm-clan disable")
			end
		end


		if modBotmanOld.clanMaxClans ~= nil then
			if (modBotmanOld.clanMaxClans ~= modBotman.clanMaxClans) then
				sendCommand("bm-clan max clans " .. modBotman.clanMaxClans)
			end
		else
			sendCommand("bm-clan max clans " .. modBotman.clanMaxClans)
		end


		if modBotmanOld.clanMaxPlayers ~= nil then
			if (modBotmanOld.clanMaxPlayers ~= modBotman.clanMaxPlayers) then
				sendCommand("bm-clan max players " .. modBotman.clanMaxPlayers)
			end
		else
			sendCommand("bm-clan max players " .. modBotman.clanMaxPlayers)
		end


		if modBotmanOld.clanMinLevel ~= nil then
			if (modBotmanOld.clanMinLevel ~= modBotman.clanMinLevel) then
				sendCommand("bm-clan min_level " .. modBotman.clanMinLevel)
			end
		else
			sendCommand("bm-clan min_level " .. modBotman.clanMinLevel)
		end


		if modBotmanOld.customMessagesEnabled ~= nil then
			if (modBotmanOld.customMessagesEnabled ~= modBotman.customMessagesEnabled) then
				if modBotman.customMessagesEnabled then
					sendCommand("bm-custommessages enable")
				else
					sendCommand("bm-custommessages disable")
				end
			end
		else
			if modBotman.customMessagesEnabled then
				sendCommand("bm-custommessages enable")
			else
				sendCommand("bm-custommessages disable")
			end
		end


		if modBotmanOld.dropminerEnabled ~= nil then
			if (modBotmanOld.dropminerEnabled ~= modBotman.dropminerEnabled) then
				if modBotman.dropminerEnabled then
					sendCommand("bm-dropmine enable")
				else
					sendCommand("bm-dropmine disable")
				end
			end
		else
			if modBotman.dropminerEnabled then
				sendCommand("bm-dropmine enable")
			else
				sendCommand("bm-dropmine disable")
			end
		end


		if modBotmanOld.dropminerTriggerEntityCount ~= nil then
			if (modBotmanOld.dropminerTriggerEntityCount ~= modBotman.dropminerTriggerEntityCount) then
				sendCommand("bm-dropmine triggercount entities  " .. modBotman.dropminerTriggerEntityCount)
			end
		else
			sendCommand("bm-dropmine triggercount entities  " .. modBotman.dropminerTriggerEntityCount)
		end


		if modBotmanOld.dropminerTriggerFallingCount ~= nil then
			if (modBotmanOld.dropminerTriggerFallingCount ~= modBotman.dropminerTriggerFallingCount) then
				sendCommand("bm-dropmine triggercount falling  " .. modBotman.dropminerTriggerFallingCount)
			end
		else
			sendCommand("bm-dropmine triggercount falling  " .. modBotman.dropminerTriggerFallingCount)
		end


		if modBotmanOld.killZonesEnabled ~= nil then
			if (modBotmanOld.killZonesEnabled ~= modBotman.killZonesEnabled) then
				if modBotman.killZonesEnabled then
					sendCommand("bm-zone enable")
				else
					sendCommand("bm-zone disable")
				end
			end
		else
			if modBotman.killZonesEnabled then
				sendCommand("bm-zone enable")
			else
				sendCommand("bm-zone disable")
			end
		end


		if modBotmanOld.resetsEnabled ~= nil then
			if (modBotmanOld.resetsEnabled ~= modBotman.resetsEnabled) then
				if modBotman.resetsEnabled then
					sendCommand("bm-resetregions enable")
				else
					sendCommand("bm-resetregions disable")
				end
			end
		else
			if modBotman.resetsEnabled then
				sendCommand("bm-resetregions enable")
			else
				sendCommand("bm-resetregions disable")
			end
		end

		if modBotmanOld.resetsDelay ~= nil then
			if (modBotmanOld.resetsDelay ~= modBotman.resetsDelay) then
				sendCommand("bm-resetregions delay " .. modBotman.resetsDelay)
			end
		else
			sendCommand("bm-resetregions delay " .. modBotman.resetsDelay)
		end


		if modBotmanOld.resetsPrefabsOnly ~= nil then
			if (modBotmanOld.resetsPrefabsOnly ~= modBotman.resetsPrefabsOnly) then
				if modBotman.resetsPrefabsOnly then
					sendCommand("bm-resetregions prefabsonly true")
				else
					sendCommand("bm-resetregions prefabsonly false")
				end
			end
		else
			if modBotman.resetsPrefabsOnly then
				sendCommand("bm-resetregions prefabsonly true")
			else
				sendCommand("bm-resetregions prefabsonly false")
			end
		end


		if modBotmanOld.resetsRemoveLCB ~= nil then
			if (modBotmanOld.resetsRemoveLCB ~= modBotman.resetsRemoveLCB) then
				if modBotman.resetsRemoveLCB then
					sendCommand("bm-resetregions removelcbs  true")
				else
					sendCommand("bm-resetregions removelcbs  false")
				end
			end
		else
			if modBotman.resetsRemoveLCB then
				sendCommand("bm-resetregions removelcbs  true")
			else
				sendCommand("bm-resetregions removelcbs  false")
			end
		end


		if modBotmanOld.webmapColour ~= nil then
			if (modBotmanOld.webmapColour ~= modBotman.webmapColour) then
				sendCommand("bm-webmapzones color " .. modBotman.webmapColour)
			end
		else
			sendCommand("bm-webmapzones color " .. modBotman.webmapColour)
		end


		if modBotmanOld.webmapEnabled ~= nil then
			if (modBotmanOld.webmapEnabled ~= modBotman.webmapEnabled) then
				if modBotman.webmapEnabled then
					sendCommand("bm-webmapzones enable")
				else
					sendCommand("bm-webmapzones disable")
				end
			end
		else
			if modBotman.webmapEnabled then
				sendCommand("bm-webmapzones enable")
			else
				sendCommand("bm-webmapzones disable")
			end
		end


		if modBotmanOld.webmapPath ~= nil then
			if (modBotmanOld.webmapPath ~= modBotman.webmapPath) then
				sendCommand("bm-webmapzones path " .. modBotman.webmapPath)
			end
		else
			sendCommand("bm-webmapzones path " .. modBotman.webmapPath)
		end


		if modBotmanOld.zombieAnnouncerEnabled ~= nil then
			if (modBotmanOld.zombieAnnouncerEnabled ~= modBotman.zombieAnnouncerEnabled) then
				if modBotman.zombieAnnouncerEnabled then
					sendCommand("bm-zombieannouncer enable")
				else
					sendCommand("bm-zombieannouncer disable")
				end
			end
		else
			if modBotman.zombieAnnouncerEnabled then
				sendCommand("bm-zombieannouncer enable")
			else
				sendCommand("bm-zombieannouncer disable")
			end
		end


		if modBotmanOld.zombieFreeTimeEnabled ~= nil then
			if (modBotmanOld.zombieFreeTimeEnabled ~= modBotman.zombieFreeTimeEnabled) then
				if modBotman.zombieFreeTimeEnabled then
					sendCommand("bm-zombiefreetime enable")
				else
					sendCommand("bm-zombiefreetime disable")
				end
			end
		else
			if modBotman.zombieFreeTimeEnabled then
				sendCommand("bm-zombiefreetime enable")
			else
				sendCommand("bm-zombiefreetime disable")
			end
		end


		if modBotmanOld.zombieFreeTimeStart ~= nil then
			if ((modBotmanOld.zombieFreeTimeStart ~= modBotman.zombieFreeTimeStart) or (modBotmanOld.zombieFreeTimeEnd ~= modBotman.zombieFreeTimeEnd)) then
				sendCommand("bm-zombiefreetime set " .. modBotman.zombieFreeTimeStart .. " " .. zombieFreeTimeEnd)
			end
		else
			sendCommand("bm-zombiefreetime set " .. modBotman.zombieFreeTimeStart .. " " .. zombieFreeTimeEnd)
		end
	end
end


function loadOtherEntities()
	local idx, cursor, errorString, row

	-- load otherEntities
    otherEntities = {}
	cursor,errorString = conn:execute("SELECT * FROM otherEntities")
	row = cursor:fetch({}, "a")

	while row do
		idx = tostring(row.entityID)

		otherEntities[idx] = {}
		otherEntities[idx].entity = row.entity
		otherEntities[idx].entityID = row.entityID
		otherEntities[idx].doNotSpawn = dbTrue(row.doNotSpawn)
		otherEntities[idx].doNotDespawn = dbTrue(row.doNotDespawn)

		if string.find(row.entity, "Trader") or string.find(row.entity, "ehicle") or string.find(row.entity, "emplate") or string.find(row.entity, "Plane") or string.find(row.entity, "sc_") or string.find(row.entity, "nvisible") or string.find(row.entity, "ontainer") then
			otherEntities[idx].doNotSpawn = true
			otherEntities[idx].doNotDespawn = true
		end

		row = cursor:fetch(row, "a")
	end
end


function loadPlayers(steam, onlyFixMissingData)
	local cursor, errorString, row, testAdmins, temp
	local word, words, rdate, ryear, rmonth, rday, rhour, rmin, rsec, k, v

	testAdmins = {}

	cursor,errorString = connSQL:execute("SELECT * FROM persistentQueue")
	row = cursor:fetch({}, "a")

	while row do
		if string.find(row.command, "admin add") then
			temp = string.split(row.command, " ")
			testAdmins[temp[3]] = {}
		end

		row = cursor:fetch(row, "a")
	end

	-- load players table)
	getPlayerFields()

	if not steam then
		cursor,errorString = conn:execute("SELECT * FROM players")
	else
		cursor,errorString = conn:execute("SELECT * FROM players WHERE steam = '" .. steam .. "'")
	end

	row = cursor:fetch({}, "a")

	while row do
		if row.steam ~= "0" then
			if not players[row.steam] then
				players[row.steam] = {}
			end

			for k,v in pairs(playerFields) do
				if not onlyFixMissingData then
					if v.type == "var" or v.type == "big" then
						players[row.steam][k] = row[k]
					end

					if v.type == "int" or v.type == "flo" then
						players[row.steam][k] = tonumber(row[k])
					end

					if v.type == "tin" then
						players[row.steam][k] = dbTrue(row[k])
					end
				end

				-- NO CAPES! er.. I mean nulls
				if v.type == "var" or v.type == "big" then
					if players[row.steam][k] == nil and v.default ~= "nil" then
						players[row.steam][k] = v.default
					end
				end

				if v.type == "int" or v.type == "flo" then
					if players[row.steam][k] == nil then
						players[row.steam][k] = tonumber(v.default)
					end
				end

				if v.type == "tin" then
					if players[row.steam][k] == nil then
						players[row.steam][k] = dbTrue(v.default)
					end
				end
			end

			if testAdmins[row.steam] then
				players[row.steam].testAsPlayer = true
			end

			-- don't restore the botTimeout field anymore
			players[row.steam].botTimeout = false
		end

		row = cursor:fetch(row, "a")
	end

	-- delete bad player records
	conn:execute("DELETE FROM players WHERE steam = '0'")
end


function loadPlayersArchived(steam)
	local cursor, errorString, row
	local word, words, rdate, ryear, rmonth, rday, rhour, rmin, rsec, k, v

	-- load playersArchived table)
	getTableFields("playersArchived")

	if steam == nil then
		if isFile(homedir .. "/data_backup/playersArchived.lua") then
			table.load(homedir .. "/data_backup/playersArchived.lua", playersArchived)
		end

		cursor,errorString = conn:execute("SELECT * FROM playersArchived")
	else
		cursor,errorString = conn:execute("SELECT * FROM playersArchived WHERE steam = '" .. steam .. "'")
	end

	row = cursor:fetch({}, "a")

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	while row do
		playersArchived[row.steam] = {}

		for k,v in pairs(playersArchivedFields) do
			if v.type == "var" or v.type == "big" then
				playersArchived[row.steam][k] = row[k]
			end

			if v.type == "int" or v.type == "flo" then
				playersArchived[row.steam][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				playersArchived[row.steam][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end
end


function loadPlayerGroups()
	local cursor, errorString, row
	local groupID

	-- load playerGroups
    playerGroups = {}
	cursor,errorString = conn:execute("SELECT * FROM playerGroups")
	row = cursor:fetch({}, "a")

	-- if the table is empty create a Donors group and set it up with the default donor cooldowns and other values from the server table
	if not row then
		conn:execute("INSERT INTO playerGroups(name, maxBases, maxProtectedBases, baseSize, baseCooldown, baseCost, maxWaypoints, waypointCost, waypointCooldown, waypointCreateCost, chatColour, teleportCost, packCost, teleportPublicCost, teleportPublicCooldown, returnCooldown, p2pCooldown, playerTeleportDelay, maxGimmies, packCooldown, zombieKillReward, allowLottery, lotteryMultiplier, lotteryTicketPrice, deathCost, mapSize, perMinutePayRate, pvpAllowProtect, gimmeZombies, allowTeleporting, allowShop, allowGimme, hardcore, reserveSlot) VALUES ('Donors'," .. server.maxBases  .. "," .. server.maxBases  .. "," .. server.baseSize .. "," .. server.baseCooldown .. "," .. server.baseCost .. "," .. server.maxWaypointsDonors .. "," .. server.waypointCost .. "," .. server.waypointCooldown .. "," .. server.waypointCreateCost .. ",'" .. server.chatColourDonor .. "'," .. server.teleportCost .. "," .. server.packCost .. "," .. server.teleportPublicCost .. "," .. server.teleportPublicCooldown .. "," .. server.returnCooldown .. "," .. server.p2pCooldown .. "," .. server.playerTeleportDelay .. ",16," .. server.packCooldown .. ",3," .. dbBool(server.allowLottery) .. "," .. server.lotteryMultiplier .. "," .. server.lotteryTicketPrice .. "," .. server.deathCost .. "," .. server.mapSizePlayers .. "," ..  server.perMinutePayRate .. "," .. dbBool(server.pvpAllowProtect) .. "," .. dbBool(server.gimmeZombies) .. "," .. dbBool(server.allowTeleporting) .. "," .. dbBool(server.allowShop) .. "," .. dbBool(server.allowGimme) .. "," .. dbBool(server.hardcore) .. ",1)")
		tempTimer( 2, [[addDonorsToPlayerGroup()]] ) -- we need to delay doing this to give MySQL time to process the new group we just added.
	end

	while row do
		groupID = "G" .. row.groupID

		playerGroups[groupID] = {}
		playerGroups[groupID].groupID = tonumber(row.groupID)
		playerGroups[groupID].name = row.name
		playerGroups[groupID].maxBases = tonumber(row.maxBases)
		playerGroups[groupID].maxProtectedBases = tonumber(row.maxProtectedBases)
		playerGroups[groupID].baseSize = tonumber(row.baseSize)
		playerGroups[groupID].baseCooldown = tonumber(row.baseCooldown)
		playerGroups[groupID].baseCost = tonumber(row.baseCost)
		playerGroups[groupID].maxWaypoints = tonumber(row.maxWaypoints)
		playerGroups[groupID].waypointCost = tonumber(row.waypointCost)
		playerGroups[groupID].waypointCooldown = tonumber(row.waypointCooldown)
		playerGroups[groupID].waypointCreateCost = tonumber(row.waypointCreateCost)
		playerGroups[groupID].chatColour = row.chatColour
		playerGroups[groupID].teleportCost = tonumber(row.teleportCost)
		playerGroups[groupID].packCost = tonumber(row.packCost)
		playerGroups[groupID].teleportPublicCost = tonumber(row.teleportPublicCost)
		playerGroups[groupID].teleportPublicCooldown = tonumber(row.teleportPublicCooldown)
		playerGroups[groupID].returnCooldown = tonumber(row.returnCooldown)
		playerGroups[groupID].p2pCooldown = tonumber(row.p2pCooldown)
		playerGroups[groupID].namePrefix = row.namePrefix
		playerGroups[groupID].playerTeleportDelay = tonumber(row.playerTeleportDelay)
		playerGroups[groupID].maxGimmies = tonumber(row.maxGimmies)
		playerGroups[groupID].packCooldown = tonumber(row.packCooldown)
		playerGroups[groupID].zombieKillReward = tonumber(row.zombieKillReward)
		playerGroups[groupID].allowLottery = dbTrue(row.allowLottery)
		playerGroups[groupID].lotteryMultiplier = tonumber(row.lotteryMultiplier)
		playerGroups[groupID].lotteryTicketPrice = tonumber(row.lotteryTicketPrice)
		playerGroups[groupID].deathCost = tonumber(row.deathCost)
		playerGroups[groupID].mapSize = tonumber(row.mapSize)
		playerGroups[groupID].perMinutePayRate = tonumber(row.perMinutePayRate)
		playerGroups[groupID].pvpAllowProtect = dbTrue(row.pvpAllowProtect)
		playerGroups[groupID].gimmeZombies = dbTrue(row.gimmeZombies)
		playerGroups[groupID].allowTeleporting = dbTrue(row.allowTeleporting)
		playerGroups[groupID].allowShop = dbTrue(row.allowShop)
		playerGroups[groupID].allowGimme = dbTrue(row.allowGimme)
		playerGroups[groupID].hardcore = dbTrue(row.hardcore)
		playerGroups[groupID].allowHomeTeleport = dbTrue(row.allowHomeTeleport)
		playerGroups[groupID].allowPlayerToPlayerTeleporting = dbTrue(row.allowPlayerToPlayerTeleporting)
		playerGroups[groupID].allowVisitInPVP = dbTrue(row.allowVisitInPVP)
		playerGroups[groupID].reserveSlot = dbTrue(row.reserveSlot)
		playerGroups[groupID].allowWaypoints = dbTrue(row.allowWaypoints)
		playerGroups[groupID].setBaseCooldown = tonumber(row.setBaseCooldown)
		playerGroups[groupID].setWPCooldown = tonumber(row.setWPCooldown)
		playerGroups[groupID].accessLevel = tonumber(row.accessLevel)
		playerGroups[groupID].donorGroup = dbTrue(row.donorGroup)
		playerGroups[groupID].gimmeRaincheck = tonumber(row.gimmeRaincheck)

		row = cursor:fetch(row, "a")
	end
end


function loadPrefabCopies()
	local cursor, errorString, row

	-- load prefabs
    prefabCopies = {}
	cursor,errorString = connSQL:execute("SELECT * FROM prefabCopies")
	row = cursor:fetch({}, "a")

	while row do
		prefabCopies[row.owner .. row.name] = {}
		prefabCopies[row.owner .. row.name].x1 = tonumber(row.x1)
		prefabCopies[row.owner .. row.name].y1 = tonumber(row.y1)
		prefabCopies[row.owner .. row.name].z1 = tonumber(row.z1)
		prefabCopies[row.owner .. row.name].x2 = tonumber(row.x2)
		prefabCopies[row.owner .. row.name].y2 = tonumber(row.y2)
		prefabCopies[row.owner .. row.name].z2 = tonumber(row.z2)
		prefabCopies[row.owner .. row.name].owner = row.owner
		prefabCopies[row.owner .. row.name].name = row.name
		row = cursor:fetch(row, "a")
	end
end


function loadProxies()
	local proxy
	local cursor, errorString, row

	-- load proxies
	proxies = {}
	cursor,errorString = connSQL:execute("SELECT * FROM proxies")
	row = cursor:fetch({}, "a")

	while row do
		proxy = string.trim(row.scanString)
		proxies[proxy] = {}
		proxies[proxy].scanString = proxy
		proxies[proxy].action = row.action
		proxies[proxy].hits = tonumber(row.hits)
		row = cursor:fetch(row, "a")
	end

	if botman.botsConnected then
		-- check for new proxies in the bots db
		cursor,errorString = connBots:execute("SELECT * FROM proxies")
		row = cursor:fetch({}, "a")
		while row do
			proxy = string.trim(row.scanString)

			if not proxies[proxy] then
				proxies[proxy] = {}
				proxies[proxy].scanString = proxy
				proxies[proxy].action = row.action
				proxies[proxy].hits = 0

				connSQL:execute("INSERT INTO proxies (scanString, action, hits) VALUES ('" .. connMEM:escape(proxy) .. "','" .. connMEM:escape(row.action) .. "',0)")
			end

			row = cursor:fetch(row, "a")
		end
	end
end


function loadResetZones(skip)
	local cursor, errorString, row

	-- load reset zones
	resetRegions = {}

	cursor,errorString = conn:execute("SELECT * FROM resetZones")
	row = cursor:fetch({}, "a")

	while row do
		resetRegions[row.region] = {}
		resetRegions[row.region].x = row.x
		resetRegions[row.region].z = row.z

		if modBotman.version and (os.time() - botman.botStarted > 30) and not skip then
			sendCommand("bm-resetregions add " .. row.x .. "." .. row.z)
		end

		row = cursor:fetch(row, "a")
	end
end


function loadRestrictedItems()
	local cursor, errorString, row, k, v

	calledFunction = "restrictedItems"
	if (debug) then dbug("debug restrictedItems line " .. debugger.getinfo(1).currentline) end

	-- load restrictedItems
	getTableFields("restrictedItems")

	restrictedItems = {}
	cursor,errorString = conn:execute("SELECT * FROM restrictedItems")
	row = cursor:fetch({}, "a")

	while row do
		if (debug) then dbug("debug loadBadItem " .. row.item) end

		restrictedItems[row.item] = {}

		for k,v in pairs(restrictedItemsFields) do
			if v.type == "var" or v.type == "big" then
				restrictedItems[row.item][k] = row[k]
			end

			if v.type == "int" or v.type == "flo" then
				restrictedItems[row.item][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				restrictedItems[row.item][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug restrictedItems line end") end
end


function loadServer(setupStuff)
	local temp, cursor, errorString, row, rows, k, v, serverOld

	calledFunction = "loadServer"

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	-- load server
	getServerFields()

	if type(server) ~= "table" then
		server = {}
	end

	cursor,errorString = conn:execute("SELECT * FROM server")
	rows = tonumber(cursor:numrows())

	if rows == 0 then
		initServer()
	end

	-- copy the current contents of the server table into serverOld so we can see what's changed later
	serverOld = {}
	for k,v in pairs(server) do
		serverOld[k] = v
	end

	cursor,errorString = conn:execute("SELECT * FROM server")
	row = cursor:fetch({}, "a")

	for k,v in pairs(serverFields) do
		if v.type == "var" or v.type == "big" then
			server[k] = row[k]
		end

		if v.type == "int" or v.type == "flo" then
			server[k] = tonumber(row[k])
		end

		if v.type == "tin" then
			server[k] = dbTrue(row[k])
		end

		-- NO CAPES! er.. I mean nulls
		if v.type == "var" or v.type == "big" and v.default ~= "nil" then
			if row[k] == nil then
				server[k] = v.default
			end
		end

		if v.type == "int" or v.type == "flo" then
			if row[k] == nil then
				server[k] = tonumber(v.default)
			end
		end

		if v.type == "tin" then
			if row[k] == nil then
				server[k] = dbTrue(v.default)
			end
		end
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	if server.botPaused then
		botman.botDisabled = true
	else
		botman.botDisabled = false
	end

	if not server.reservedSlotsUsed then
		server.reservedSlotsUsed = 0
	end

	if row.chatlogPath == "" or row.chatlogPath == nil then
		botman.chatlogPath = homedir .. "/chatlogs"
	end

	botman.chatlogPath = row.chatlogPath

	if row.moneyName == nil or row.moneyName == "|" then
		-- fix if missing money
		temp = string.split("Zenny|Zennies", "|")
	else
		temp = string.split(row.moneyName, "|")
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	server.moneyName = temp[1]

	if temp[2] == nil then
		-- fix if missing money plural
		server.moneyPlural = temp[1]
	else
		server.moneyPlural = temp[2]
	end

	if server.gameType == "pvp" then
		if server.northeastZone == "" then
			server.northeastZone = "pvp"
		end

		if server.northwestZone == "" then
			server.northwestZone = "pvp"
		end

		if server.southeastZone == "" then
			server.southeastZone = "pvp"
		end

		if server.southwestZone == "" then
			server.southwestZone = "pvp"
		end
	else
		if server.northeastZone == "" then
			server.northeastZone = "pve"
		end

		if server.northwestZone == "" then
			server.northwestZone = "pve"
		end

		if server.southeastZone == "" then
			server.southeastZone = "pve"
		end

		if server.southwestZone == "" then
			server.southwestZone = "pve"
		end
	end

	-- make sure we save the 4 zones back to the server table
	conn:execute("UPDATE server SET northeastZone = '" .. escape(server.northeastZone) .. "', northwestZone = '" .. escape(server.northwestZone) .. "', southeastZone = '" .. escape(server.southeastZone) .. "', southwestZone = '" .. escape(server.southwestZone) .. "'")

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	if server.ircServer then
		if string.find(server.ircServer, ":") then
			temp = string.split(server.ircServer, ":")
			server.ircServer = temp[1]
			server.ircPort = temp[2]
		end
	else
		if row.ircServer ~= "" then
			server.ircServer = row.ircServer
		else
			server.ircServer = ircServer
		end

		if row.ircPort ~= "" then
			server.ircPort = row.ircPort
		else
			server.ircPort = ircPort
		end
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	if server.ircMain == "#new" then
		server.ircMain = ircChannel
		server.ircAlerts = ircChannel .. "_alerts"
		server.ircWatch = ircChannel .. "_watch"
	end

	-- fix the alerts and watch channels if they get swapped
	if string.find(server.ircAlerts, "_watch") then
		temp = server.ircAlerts

		server.ircAlerts = server.ircWatch
		server.ircWatch = temp
		conn:execute("UPDATE server SET ircAlerts = '" .. escape(server.ircAlerts) .. "', ircWatch = '" .. escape(server.ircWatch) .. "'")
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	if server.telnetPass ~= "" then
		telnetPassword = server.telnetPass
	else
		server.telnetPass = telnetPassword
		conn:execute("UPDATE server SET telnetPass = '" .. escape(telnetPassword) .. "'")
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	if server.ircBotName ~= "Bot" then
		if setIrcNick ~= nil then
			-- Mudlet 3.x
			setIrcNick(server.ircBotName)
		end
	end

	whitelistedCountries = {}
	if row.whitelistCountries then
		temp = string.split(row.whitelistCountries, ",")

		max = tablelength(temp)
		for i=1,max,1 do
			whitelistedCountries[temp[i]] = {}
		end
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	blacklistedCountries = {}
	if row.blacklistCountries then
		temp = string.split(row.blacklistCountries, ",")

		max = tablelength(temp)
		for i=1,max,1 do
			blacklistedCountries[temp[i]] = {}
		end
	end

	if not server.uptime then
		server.uptime = 0
	end

	if tonumber(server.telnetPort) == 0 then
		if exists(homedir .. "/server_address.lua") then
			dofile(homedir .. "/server_address.lua")

			if botman.dbConnected then
				conn:execute("UPDATE server SET IP = '" .. escape(server.IP) .. "', telnetPort = " .. server.telnetPort)
			end

			if botman.botsConnected then
				connBots:execute("UPDATE servers SET IP = '" .. escape(server.IP) .. "' WHERE botID = " .. server.botID)
			end
		else
			if telnetPort then
				server.telnetPort = telnetPort
			end
		end
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	-- stuff to do after loading the server table when applicable

	-- set everyone's chat colour
	if setupStuff or (server.chatColourPrisoner ~= serverOld.chatColourPrisoner) or (server.chatColourMod ~= serverOld.chatColourMod) or (server.chatColourAdmin ~= serverOld.chatColourAdmin) or (server.chatColourOwner ~= serverOld.chatColourOwner) or (server.chatColourDonor ~= serverOld.chatColourDonor) or (server.chatColourPlayer ~= serverOld.chatColourPlayer) or (server.chatColourNewPlayer ~= serverOld.chatColourNewPlayer) then
		-- only set chat colours for players if not disabled
		if not modBotman.disableChatColours then
			for k,v in pairs(igplayers) do
				setChatColour(k, players[k].accessLevel)
			end
		end
	end

	if setupStuff or (server.botNameColour ~= serverOld.botNameColour) or (server.botName ~= serverOld.botName) or (server.commandPrefix ~= serverOld.commandPrefix) then
		-- if using botman mod
		if server.botman then
			-- set the colour of the bot's name
			sendCommand("bm-change botname [" .. server.botNameColour .. "]" .. server.botName)

			-- update the command prefix
			sendCommand("bm-chatcommands prefix " .. server.commandPrefix)

			if server.commandPrefix == "" then
				sendCommand("bm-chatcommands hide false")
			end
		end
	end

	if (server.ircPort ~= serverOld.ircPort) or (server.ircServer ~= serverOld.ircServer) or (server.ircBotName ~= serverOld.ircBotName) or (server.ircMain ~= serverOld.ircMain) or (server.ircWatch ~= serverOld.ircWatch) or (server.ircAlerts ~= serverOld.ircAlerts) then
		joinIRCServer()
	end

	conn:execute("UPDATE timedEvents SET delayMinutes = " .. server.gimmeResetTime .. " WHERE timer = 'gimmeReset'")

	if botStatus.telnetSpamThreshold then
		botStatus.telnetSpamThreshold = server.safeModeSpamTrigger
	end
end


function loadShop()
	local cursor, errorString, row, cat, k, v
	-- load shop

	getTableFields("shop")

	shop = {}
	cursor,errorString = conn:execute("SELECT * FROM shop")

	row = cursor:fetch({}, "a")
	while row do
		shop[row.item] = {}

		for k,v in pairs(shopFields) do
			if v.type == "var" or v.type == "big" then
				shop[row.item][k] = row[k]
			end

			if v.type == "int" or v.type == "flo" then
				shop[row.item][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				shop[row.item][k] = dbTrue(row[k])
			end

			-- NO CAPES! er.. I mean nulls
			if v.type == "var" or v.type == "big" and v.default ~= "nil" then
				if shop[row.item][k] == nil then
					shop[row.item][k] = v.default
				end
			end

			if v.type == "int" or v.type == "flo" then
				if shop[row.item][k] == nil then
					shop[row.item][k] = tonumber(v.default)
				end
			end

			if v.type == "tin" then
				if shop[row.item][k] == nil then
					shop[row.item][k] = dbTrue(v.default)
				end
			end
		end

		row = cursor:fetch(row, "a")
	end
end


function loadShopCategories()
	local cursor, errorString, row, cat

	-- load shop categories
	shopCategories = {}
	cursor,errorString = conn:execute("SELECT * FROM shopCategories")

	-- add the misc category so it always exists
	if cursor:numrows() > 0 then
		shopCategories["misc"] = {}
		shopCategories["misc"].idx = 1
		shopCategories["misc"].code = "misc"
	end

	row = cursor:fetch({}, "a")
	while row do
		cat = string.lower(row.category) -- only cool cats allowed

		shopCategories[cat] = {}
		shopCategories[cat].idx = row.idx
		shopCategories[cat].code = string.lower(row.code)
		row = cursor:fetch(row, "a")
	end
end


function loadStaff()
	local cursor, errorString, row, adminLevel
	local steam, steamOwner, userID

	-- load staff
    staffList = {}
	cursor,errorString = conn:execute("SELECT * FROM staff")
	row = cursor:fetch({}, "a")

	while row do
		adminLevel = tonumber(row.adminLevel)

		if row.steam then
			if not staffList[row.steam] then
				staffList[row.steam] = {}
				staffList[row.steam].adminLevel = tonumber(row.adminLevel)
				staffList[row.steam].platform = row.platform
				staffList[row.steam].userID = row.userID
				staffList[row.steam].steam = row.steam
				staffList[row.steam].hidden = dbTrue(row.hidden)
				staffList[row.steam].name = row.name

				if players[row.steam] then
					staffList[row.steam].name = players[row.steam].name
				else
					if players[row.userID] then
						staffList[row.steam].name = players[row.userID].name
					end
				end
			end
		end

		row = cursor:fetch(row, "a")
	end
end


function loadTeleports(tp)
	local cursor, errorString, row, k, v

	calledFunction = "teleports"
	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	-- load teleports
	getTableFields("teleports")

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if type(teleports) ~= "table" then
		teleports = {}
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if tp == nil then
		teleports = {}
		cursor,errorString = conn:execute("SELECT * FROM teleports")
	else
		cursor,errorString = conn:execute("SELECT * FROM teleports where name = '" .. escape(tp) .. "'")
	end

	row = cursor:fetch({}, "a")

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	while row do
		teleports[row.name] = {}

		for k,v in pairs(teleportsFields) do
			if v.type == "var" or v.type == "big" then
				teleports[row.name][k] = row[k]
			end

			if v.type == "int" or v.type == "flo" then
				teleports[row.name][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				teleports[row.name][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug teleports line end") end
end


function loadVillagers()
	local cursor, errorString, row

	-- load villagers
	villagers = {}
	cursor,errorString = conn:execute("SELECT * FROM villagers")
	row = cursor:fetch({}, "a")

	while row do
		villagers[row.steam .. row.village] = {}
		villagers[row.steam .. row.village].steam = row.steam
		villagers[row.steam .. row.village].village = row.village
		row = cursor:fetch(row, "a")
	end
end


function loadWaypoints(steam)
	local idx, k, v
	local cursor, errorString, row

	-- load waypoints
	if steam == nil then
		-- refresh the waypoints table from the db is no steam is specified
		waypoints = {}
	else
		-- first delete all the waypoints belonging to this steam id so we can reload them from the db
		-- we have to do this because we only index them by their record id in the db
		for k,v in pairs(waypoints) do
			if v.steam == steam then
				waypoints[k] = nil
			end
		end
	end

	if steam == nil then
		cursor,errorString = conn:execute("SELECT * FROM waypoints")
	else
		cursor,errorString = conn:execute("SELECT * FROM waypoints where steam = '" .. steam .. "'")
	end

	row = cursor:fetch({}, "a")
	while row do
		idx = tonumber(row.id)
		waypoints[idx] = {}
		waypoints[idx].id = idx
		waypoints[idx].steam = row.steam
		waypoints[idx].name = row.name
		waypoints[idx].x = tonumber(row.x)
		waypoints[idx].y = tonumber(row.y)
		waypoints[idx].z = tonumber(row.z)
		waypoints[idx].shared = dbTrue(row.shared)
		waypoints[idx].linked = tonumber(row.linked)
		row = cursor:fetch(row, "a")
	end
end


function loadWhitelist()
	local cursor, errorString, row

	-- load whitelist
    whitelist = {}
	cursor,errorString = conn:execute("SELECT * FROM whitelist")
	row = cursor:fetch({}, "a")
	while row do
		whitelist[row.steam] = {}
		whitelist[row.steam].steam = row.steam
		whitelist[row.steam].userID = row.userID
		whitelist[row.steam].platform = row.platform
		row = cursor:fetch(row, "a")
	end
end


function loadTables(skipPlayers)
	display("debug loadTables\n")

	loadServer()
	--display("debug loaded server\n")

	loadModBotman()
	display("debug loaded modBotman\n")

	if not skipPlayers then
		loadPlayersArchived()
		--display("debug loaded playersArchived\n")
		sleep(1)
	end

	if not skipPlayers then
		loadPlayers()
		--display("debug loaded players\n")
		sleep(1)
	end

	loadStaff()
	--display("debug loaded staff list\n")

	loadResetZones()
	--display("debug loaded reset zones\n")

	loadTeleports()
	--display("debug loaded teleports\n")

	loadLocations()
	--display("debug loaded locations\n")

	loadLocationCategories()
	--display("debug loaded locationCategories\n")

	loadBases() -- and base members
	--display("debug loaded bases\n")

	loadDonors()
	--display("debug loaded donors\n")

	migrateDonors() -- if the donors table is empty, try to populate it from donors in the players table.

	loadBadItems()
	--display("debug loaded badItems\n")

	loadRestrictedItems()
	--display("debug loaded restrictedItems\n")

	loadFriends()
	--display("debug loaded friends\n")

	loadHotspots()
	--display("debug loaded hotspots\n")

	loadVillagers()
	--display("debug loaded villagers\n")

	loadShop()
	--display("debug loaded shop\n")

	loadShopCategories()
	--display("debug loaded shopCategories\n")

	loadCustomMessages()
	--display("debug loaded customMessages\n")

	loadProxies()
	--display("debug loaded proxies\n")

	loadBadWords()
	--display("debug loaded badWords\n")

	loadPrefabCopies()
	--display("debug loaded prefabCopies\n")

	loadWaypoints()
	--display("debug loaded waypoints\n")

	loadWhitelist()
	--display("debug loaded whitelist\n")

	loadGimmePrizes()
	--display("debug loaded gimmePrizes\n")

	loadGimmeZombies()
	--display("debug loaded gimmeZombies\n")

	loadOtherEntities()
	--display("debug loaded otherEntities\n")

	loadBans()
	--display("debug loaded bans\n")

	loadBotMaintenance()

	loadKeystones()
	--display("debug loaded keystones\n")

	loadHelpCommands()
	--display("debug loaded loadHelpCommands\n")

	loadPlayerGroups()
	--display("debug loaded loadPlayerGroups\n")

	loadJoiningPlayers()
	--display("debug loaded loadJoiningPlayers\n")

	display("debug loadTables completed\n")
end