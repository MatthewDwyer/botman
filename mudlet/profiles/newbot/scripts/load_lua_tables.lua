--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug
debug = false -- should be false unless testing


function loadBadItems()
	local cursor, errorString, row, k, v

	--debug = false
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

			if v.type == "int" then
				badItems[row.item][k] = tonumber(row[k])
			end

			if v.type == "flo" then
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
	getTableFields("badWords")

	badWords = {}
	cursor,errorString = conn:execute("SELECT * FROM badWords")
	row = cursor:fetch({}, "a")
	while row do
		badWords[row.badWord] = {}
		badWords[row.badWord].cost = tonumber(row.cost)
		badWords[row.badWord].counter = tonumber(row.counter)
		row = cursor:fetch(row, "a")
	end
end


function loadBans()
	local cursor, errorString, row
	-- load bans

	getTableFields("bans")

    bans = {}
	cursor,errorString = conn:execute("SELECT * FROM bans")
	row = cursor:fetch({}, "a")
	while row do
		bans[row.Steam] = {}
		bans[row.Steam].steam = row.Steam
		bans[row.Steam].BannedTo = row.BannedTo
		bans[row.Steam].Reason = row.Reason
		bans[row.Steam].expiryDate = row.expiryDate

		row = cursor:fetch(row, "a")
	end
end


function loadBases()
	local cursor, errorString, row
	-- load bases

	getTableFields("bases")

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
		bases[row.steam .. "_" .. row.baseNumber].protect = row.protect
		bases[row.steam .. "_" .. row.baseNumber].keepOut = row.keepOut
		bases[row.steam .. "_" .. row.baseNumber].creationTimestamp = row.creationTimestamp
		bases[row.steam .. "_" .. row.baseNumber].creationGameDay = row.creationGameDay

		row = cursor:fetch(row, "a")
	end
end


function loadCustomMessages()
	local cursor, errorString, row

	-- load customMessages
	getTableFields("customMessages")

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

	getTableFields("donors")

	if not steam then
		donors = {}
		cursor,errorString = conn:execute("SELECT * FROM donors")
	else
		cursor,errorString = conn:execute("SELECT * FROM donors WHERE steam = " .. steam)
	end

	row = cursor:fetch({}, "a")
	while row do
		donors[row.steam] = {}
		donors[row.steam].steam = row.steam
		donors[row.steam].level = row.level
		donors[row.steam].expiry = row.expiry
		donors[row.steam].name = row.name
		donors[row.steam].expired = dbTrue(row.expired)
		row = cursor:fetch(row, "a")
	end
end


function loadFriends(steam)
	local cursor, errorString, row

	-- load friends
	getTableFields("friends")

	if steam == nil then
		friends = {}
		cursor,errorString = conn:execute("SELECT * FROM friends")
	else
		cursor,errorString = conn:execute("SELECT * FROM friends WHERE steam = " .. steam)
		friends[steam] = {}
	end

	row = cursor:fetch({}, "a")
	while row do
		if friends[row.steam] == nil then
			friends[row.steam] = {}
			friends[row.steam].friends = ""
		end

		if friends[row.steam].friends == "" then
			friends[row.steam].friends = row.friend
		else
			friends[row.steam].friends = friends[row.steam].friends .. "," .. row.friend
		end

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

			if v.type == "int" then
				gimmePrizes[row.name][k] = tonumber(row[k])
			end

			if v.type == "flo" then
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

	--debug = false
	calledFunction = "gimmeZombies"
	if (debug) then dbug("debug gimmeZombies line " .. debugger.getinfo(1).currentline) end

	-- load gimmeZombies
	getTableFields("gimmeZombies")

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

	--debug = false
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

	--debug = false
	calledFunction = "loadKeystones"
	if (debug) then dbug("debug loadKeystones line " .. debugger.getinfo(1).currentline) end

	getTableFields("keystones")

	if type(keystones) ~= "table" then
		keystones = {}
	end

	keystones = {}
	cursor,errorString = conn:execute("SELECT * FROM keystones")
	row = cursor:fetch({}, "a")

	while row do
		if (debug) then dbug("debug loadKeystones " .. row.name) end

		keystones[row.x .. row.y .. row.z] = {}

		for k,v in pairs(keystonesFields) do
			if v.type == "var" or v.type == "big" then
				keystones[row.x .. row.y .. row.z][k] = row[k]
			end

			if v.type == "int" then
				keystones[row.x .. row.y .. row.z][k] = tonumber(row[k])
			end

			if v.type == "flo" then
				keystones[row.x .. row.y .. row.z][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				keystones[row.x .. row.y .. row.z][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug loadKeystones end") end
end


function loadLocationCategories()
	local cursor, errorString, row

	-- load locationCategories
	getTableFields("locationCategories")

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

	--debug = false
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

			if v.type == "int" then
				locations[row.name][k] = tonumber(row[k])
			end

			if v.type == "flo" then
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

	getTableFields("modBotman")

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
		modBotman.blockTreeRemoval = dbTrue(row.blockTreeRemoval)
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

		-- if modBotmanOld.blockTreeRemoval ~= modBotman.blockTreeRemoval then
			-- if modBotman.blockTreeRemoval then

			-- else

			-- end
		-- end

		-- blockTreeRemoval


		if modBotmanOld.botName ~= nil then
			if (modBotmanOld.botName ~= modBotman.botName) then
				sendCommand("bm-change botname " .. modBotman.botName)
				server.botName = modBotman.botName
				conn:execute("UPDATE server SET botName = '" .. escape(modBotman.botName) .. "'")
			end
		else
			sendCommand("bm-change botname " .. modBotman.botName)
			server.botName = modBotman.botName
			conn:execute("UPDATE server SET botName = '" .. escape(modBotman.botName) .. "'")
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
	getTableFields("otherEntities")

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


function loadPlayers(steam)
	local cursor, errorString, row, testAdmins, temp
	local word, words, rdate, ryear, rmonth, rday, rhour, rmin, rsec, k, v

	testAdmins = {}

	cursor,errorString = conn:execute("SELECT * FROM persistentQueue")
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
		if isFile(homedir .. "/data_backup/players.lua") then
			table.load(homedir .. "/data_backup/players.lua", players)
		end

		cursor,errorString = conn:execute("SELECT * FROM players")
	else
		cursor,errorString = conn:execute("SELECT * FROM players WHERE steam = " .. steam)
	end

	row = cursor:fetch({}, "a")
	while row do
		-- don't load the player if they are in the table playersArchived
		if not playersArchived[row.steam] then
			if not players[row.steam] then
				players[row.steam] = {}
			end

			for k,v in pairs(playerFields) do
				if v.type == "var" or v.type == "big" then
					players[row.steam][k] = row[k]
				end

				if v.type == "int" then
					players[row.steam][k] = tonumber(row[k])
				end

				if v.type == "flo" then
					players[row.steam][k] = tonumber(row[k])
				end

				if v.type == "tin" then
					players[row.steam][k] = dbTrue(row[k])
				end
			end
		end

		if testAdmins[row.steam] then
			players[row.steam].testAsPlayer = true
		end

		row = cursor:fetch(row, "a")
	end
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
		cursor,errorString = conn:execute("SELECT * FROM playersArchived WHERE steam = " .. steam)
	end

	row = cursor:fetch({}, "a")

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	while row do
		playersArchived[row.steam] = {}

		for k,v in pairs(playersArchivedFields) do
			if v.type == "var" or v.type == "big" then
				playersArchived[row.steam][k] = row[k]
			end

			if v.type == "int" then
				playersArchived[row.steam][k] = tonumber(row[k])
			end

			if v.type == "flo" then
				playersArchived[row.steam][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				playersArchived[row.steam][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end
end


function loadPrefabCopies()
	local cursor, errorString, row

	-- load prefabs
	getTableFields("prefabCopies")

    prefabCopies = {}
	cursor,errorString = conn:execute("SELECT * FROM prefabCopies")
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
	getTableFields("proxies")

	proxies = {}
	cursor,errorString = conn:execute("SELECT * FROM proxies")
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

				conn:execute("INSERT INTO proxies (scanString, action, hits) VALUES ('" .. escape(proxy) .. "','" .. escape(row.action) .. "',0)")
			end

			row = cursor:fetch(row, "a")
		end
	end
end


function loadResetZones()
	local cursor, errorString, row
	-- load reset zones

	getTableFields("resetZones")
	resetRegions = {}

	cursor,errorString = conn:execute("SELECT * FROM resetZones")
	row = cursor:fetch({}, "a")
	while row do
		resetRegions[row.region] = {}
		resetRegions[row.region].x = row.x
		resetRegions[row.region].z = row.z

		if modBotman.version and (os.time() - botman.botStarted > 30) then
			sendCommand("bm-resetregions add " .. row.x .. "." .. row.z)
		end

		row = cursor:fetch(row, "a")
	end
end


function loadRestrictedItems()
	local cursor, errorString, row, k, v

	--debug = false
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

			if v.type == "int" then
				restrictedItems[row.item][k] = tonumber(row[k])
			end

			if v.type == "flo" then
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

--	debug = false
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

		if v.type == "int" then
			server[k] = tonumber(row[k])
		end

		if v.type == "flo" then
			server[k] = tonumber(row[k])
		end

		if v.type == "tin" then
			server[k] = dbTrue(row[k])
		end
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

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
		if ircSetNick ~= nil then
			-- TheFae's modded mudlet
			ircSetNick(server.ircBotName)
		end

		if setIrcNick ~= nil then
			-- Mudlet 3.x
			setIrcNick(server.ircBotName)
		end
	end

	whitelistedCountries = {}
	if row.whitelistCountries then
		temp = string.split(row.whitelistCountries, ",")

		max = table.maxn(temp)
		for i=1,max,1 do
			whitelistedCountries[temp[i]] = {}
		end
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	blacklistedCountries = {}
	if row.blacklistCountries then
		temp = string.split(row.blacklistCountries, ",")

		max = table.maxn(temp)
		for i=1,max,1 do
			blacklistedCountries[temp[i]] = {}
		end
	end

	if not server.uptime then
		server.uptime = 0
	end

	if telnetPort then
		if server.telnetPort == 0 then
			server.telnetPort = telnetPort
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

			return
		end

		-- if using BC mod
		if server.stompy and not server.botman then
			-- update the command prefix
			sendCommand("bc-chatprefix " .. prefix)

			if server.commandPrefix == "" then
				sendCommand("bc-chatprefix \"\"")
			end

			return
		end
	end

	if (server.ircPort ~= serverOld.ircPort) or (server.ircServer ~= serverOld.ircServer) or (server.ircBotName ~= serverOld.ircBotName) or (server.ircMain ~= serverOld.ircMain) or (server.ircWatch ~= serverOld.ircWatch) or (server.ircAlerts ~= serverOld.ircAlerts) then
		joinIRCServer()
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

			if v.type == "int" then
				shop[row.item][k] = tonumber(row[k])
			end

			if v.type == "flo" then
				shop[row.item][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				shop[row.item][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end
end


function loadShopCategories()
	local cursor, errorString, row, cat
	-- load shop categories

	getTableFields("shopCategories")

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
	-- load staff

	getTableFields("staff")

    staffList = {}
	cursor,errorString = conn:execute("SELECT * FROM staff")
	row = cursor:fetch({}, "a")

	while row do
		adminLevel = tonumber(row.adminLevel)

		staffList[row.steam] = {}
		staffList[row.steam].adminLevel = row.adminLevel

		if adminLevel == 0 then
			owners[row.steam] = {}
		end

		if adminLevel == 1 then
			admins[row.steam] = {}
		end

		if adminLevel == 2 then
			mods[row.steam] = {}
		end

		row = cursor:fetch(row, "a")
	end
end


function loadTables(skipPlayers)
	if (debug) then display("debug loadTables\n") end

	loadServer()
	if (debug) then display("debug loaded server\n") end

	loadModBotman()
	if (debug) then display("debug loaded modBotman\n") end

	if not skipPlayers then
		loadPlayersArchived()
		if (debug) then display("debug loaded playersArchived\n") end
	end

	if not skipPlayers then
		loadPlayers()
		if (debug) then display("debug loaded players\n") end
	end

	loadStaff()
	if (debug) then display("debug loaded staff list\n") end

	loadResetZones()
	if (debug) then display("debug loaded reset zones\n") end

	loadTeleports()
	if (debug) then display("debug loaded teleports\n") end

	loadLocations()
	if (debug) then display("debug loaded locations\n") end

	loadLocationCategories()

	loadBadItems()
	if (debug) then display("debug loaded badItems\n") end

	loadRestrictedItems()
	if (debug) then display("debug loaded restrictedItems\n") end

	loadFriends()
	if (debug) then display("debug loaded friends\n") end

	loadHotspots()
	if (debug) then display("debug loaded hotspots\n") end

	loadVillagers()
	if (debug) then display("debug loaded villagers\n") end

	loadShop()
	if (debug) then display("debug loaded shop\n") end

	loadShopCategories()
	if (debug) then display("debug loaded shopCategories\n") end

	loadCustomMessages()
	if (debug) then display("debug loaded customMessages\n") end

	loadProxies()
	if (debug) then display("debug loaded proxies\n") end

	loadBadWords()
	if (debug) then display("debug loaded badWords\n") end

	loadPrefabCopies()
	if (debug) then display("debug loaded prefabCopies\n") end

	loadWaypoints()
	if (debug) then display("debug loaded waypoints\n") end

	loadWhitelist()
	if (debug) then display("debug loaded whitelist\n") end

	loadGimmePrizes()
	if (debug) then display("debug loaded gimmePrizes\n") end

	loadGimmeZombies()
	if (debug) then display("debug loaded gimmeZombies\n") end

	loadOtherEntities()
	if (debug) then display("debug loaded otherEntities\n") end

	loadBans()
	if (debug) then display("debug loaded bans\n") end

	loadKeystones()
	if (debug) then display("debug loaded keystones\n") end

	loadBases()
	if (debug) then display("debug loaded bases\n") end

	loadDonors()
	if (debug) then display("debug loaded donors\n") end

	loadBotMaintenance()

	migrateDonors() -- if the donors table is empty, try to populate it from donors in the players table.

	if (debug) then display("debug loadTables completed\n") end
end


function loadTeleports(tp)
	local cursor, errorString, row, k, v

--	debug = false
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

			if v.type == "int" then
				teleports[row.name][k] = tonumber(row[k])
			end

			if v.type == "flo" then
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
	getTableFields("villagers")

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

	getTableFields("waypoints")

	if steam == nil then
		cursor,errorString = conn:execute("SELECT * FROM waypoints")
	else
		cursor,errorString = conn:execute("SELECT * FROM waypoints where steam = " .. steam)
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
	getTableFields("whitelist")

    whitelist = {}
	cursor,errorString = conn:execute("SELECT * FROM whitelist")
	row = cursor:fetch({}, "a")
	while row do
		whitelist[row.steam] = {}
		row = cursor:fetch(row, "a")
	end
end