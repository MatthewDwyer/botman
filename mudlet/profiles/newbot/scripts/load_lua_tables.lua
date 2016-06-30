--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function loadServer()
	calledFunction = "loadServer"

	-- load server
	getTableFields("server")

	if type(server) ~= "table" then
		server = {}
	end

	cursor,errorString = conn:execute("select * from server")
	rows = tonumber(cursor:numrows())

	if rows == 0 then
		initServer()
	else
		row = cursor:fetch({}, "a")
		
		server.botName = row.botName
		server.windowGMSG = row.windowGMSG
		server.windowAlerts = row.windowAlerts
		server.windowDebug = row.windowDebug
		server.windowLists = row.windowLists
		server.windowPlayers = row.windowPlayers
		server.ServerPort = row.ServerPort
		server.allowGimme = dbTrue(row.allowGimme)
		server.mapSize = tonumber(row.mapSize)
		server.prisonSize = tonumber(row.prisonSize)
		server.MOTD = row.MOTD
		server.IP = row.IP
		server.lottery = tonumber(row.lottery)
		server.allowShop = dbTrue(row.allowShop)
		server.allowWaypoints = dbTrue(row.allowWaypoints)
		server.ircAlerts = row.ircAlerts
		server.ircMain = row.ircMain
		server.ircWatch = row.ircWatch
		server.ircTracker = row.ircTracker
		server.chatColour = row.chatColour
		server.maxPlayers = tonumber(row.maxPlayers)
		server.maxServerUptime = tonumber(row.maxServerUptime)
		server.baseSize = tonumber(row.baseSize)
		server.baseCooldown = tonumber(row.baseCooldown)
		server.protectionMaxDays = tonumber(row.protectionMaxDays)
		server.ircBotName = row.ircBotName
		server.ServerName = row.serverName
		server.rules = row.rules
		server.shopCountdown = tonumber(row.shopCountdown)
		server.gimmePeace = dbTrue(row.gimmePeace)
		server.lastDailyReboot = tonumber(row.lastDailyReboot)
		server.allowNumericNames = dbTrue(row.allowNumericNames)
		server.allowGarbageNames = dbTrue(row.allowGarbageNames)
		server.allowReboot = dbTrue(row.allowReboot)
		server.newPlayerTimer = tonumber(row.newPlayerTimer)
		server.blacklistResponse = row.blacklistResponse
		server.gameDay = tonumber(row.gameDay)
		server.shopLocation = row.shopLocation
		server.website = row.website
		server.ircServer = row.ircServer
		server.pingKick = tonumber(row.pingKick)
		server.gameType = row.gameType
		server.hideCommands = dbTrue(row.hideCommands)
		server.serverGroup = row.serverGroup
		server.botID = tonumber(row.botID)
		server.allowOverstacking = dbTrue(row.allowOverstacking)
		server.announceTeleports = dbTrue(row.announceTeleports)
		server.blockCountries = row.blockCountries
		server.allowPhysics = dbTrue(row.allowPhysics)
		server.northeastZone = row.northeastZone
		server.northwestZone = row.northwestZone
		server.southeastZone = row.southeastZone
		server.southwestZone = row.southwestZone
		server.playersCanFly = dbTrue(row.playersCanFly)
		server.accessLevelOverride = tonumber(row.accessLevelOverride)
		server.disableBaseProtection = dbTrue(row.disableBaseProtection)
		server.packCooldown = tonumber(row.packCooldown)
		server.allowBank = dbTrue(row.allowBank)
		server.moneyName = row.moneyName
		server.overstackThreshold = tonumber(row.overstackThreshold)
		server.enableRegionPM = dbTrue(row.enableRegionPM)
		server.allowRapidRelogging = dbTrue(row.allowRapidRelogging)
		server.allowLottery = dbTrue(row.allowLottery)
		server.lotteryMultiplier = tonumber(row.lotteryMultiplier)
		server.zombieKillReward = tonumber(row.zombieKillReward)
		server.allowTeleporting = dbTrue(row.allowTeleporting)
		server.hardcore = dbTrue(row.hardcore)
		server.swearJar = dbTrue(row.swearJar)
		server.swearCash = tonumber(row.swearCash)
		server.idleKick = dbTrue(row.idleKick)
	end

	-- set up other initial states
	server.ignoreAdmins = true
	server.uptime = os.time()
	server.coppi = false
	server.ubex = false
end


function loadPlayers(steam)
	local word, words, rdate, ryear, rmonth, rday, rhour, rmin, rsec

	-- load players table
	getTableFields("players")

	if steam == nil then 
		players = {} 
		cursor,errorString = conn:execute("select * from players")
	else
		cursor,errorString = conn:execute("select * from players where steam = " .. steam)
	end

	row = cursor:fetch({}, "a")
	while row do		
		players[row.steam] = {}
		players[row.steam].silentBob = dbTrue(row.silentBob)
		players[row.steam].walkies = dbTrue(row.walkies)
		players[row.steam].steam = row.steam
		players[row.steam].name = row.name
		players[row.steam].id = row.id
		players[row.steam].xPos = tonumber(row.xPos)
		players[row.steam].yPos = tonumber(row.yPos)
		players[row.steam].zPos = tonumber(row.zPos)
		players[row.steam].xPosOld = tonumber(row.xPosOld)
		players[row.steam].yPosOld = tonumber(row.yPosOld)
		players[row.steam].zPosOld = tonumber(row.zPosOld)
		players[row.steam].xPosTimeout = tonumber(row.xPosTimeout)
		players[row.steam].yPosTimeout = tonumber(row.yPosTimeout)
		players[row.steam].zPosTimeout = tonumber(row.zPosTimeout)
		players[row.steam].homeX = tonumber(row.homeX)
		players[row.steam].homeY = tonumber(row.homeY)
		players[row.steam].homeZ = tonumber(row.homeZ)
		players[row.steam].home2X = tonumber(row.home2X)
		players[row.steam].home2Y = tonumber(row.home2Y)
		players[row.steam].home2Z = tonumber(row.home2Z)
		players[row.steam].exitX = tonumber(row.exitX)
		players[row.steam].exitY = tonumber(row.exitY)
		players[row.steam].exitZ = tonumber(row.exitZ)
		players[row.steam].exit2X = tonumber(row.exit2X)
		players[row.steam].exit2Y = tonumber(row.exit2Y)
		players[row.steam].exit2Z = tonumber(row.exit2Z)
		players[row.steam].level = tonumber(row.level)
		players[row.steam].cash = tonumber(row.cash)
		players[row.steam].pvpBounty = tonumber(row.pvpBounty)
		players[row.steam].zombies = tonumber(row.zombies)
		players[row.steam].score = tonumber(row.score)
		players[row.steam].playerKills = tonumber(row.playerKills)
		players[row.steam].deaths = tonumber(row.deaths)
		players[row.steam].protectSize = tonumber(row.protectSize)
		players[row.steam].protect2Size = tonumber(row.protect2Size)
		players[row.steam].sessionCount = tonumber(row.sessionCount)
		players[row.steam].timeOnServer = tonumber(row.timeOnServer)
		players[row.steam].firstSeen = tonumber(row.firstSeen)
		players[row.steam].keystones = tonumber(row.keystones)
		players[row.steam].overstackTimeout = dbTrue(row.overstackTimeout)
		players[row.steam].overstack = dbTrue(row.overstack)
		players[row.steam].shareWaypoint = dbTrue(row.shareWaypoint)
		players[row.steam].watchCash = dbTrue(row.watchCash)
		players[row.steam].watchPlayer = dbTrue(row.watchPlayer)
		players[row.steam].timeout = dbTrue(row.timeout)
		players[row.steam].denyRights = dbTrue(row.denyRights)
		players[row.steam].botTimeout = dbTrue(row.botTimeout)
		players[row.steam].newPlayer = dbTrue(row.newPlayer)
		players[row.steam].IP = row.IP
		players[row.steam].seen = row.seen
		players[row.steam].baseCooldown = tonumber(row.baseCooldown)
		players[row.steam].ircAlias = row.ircAlias
		players[row.steam].ircPass = row.ircPass
		players[row.steam].bed = row.bed
		players[row.steam].donor = dbTrue(row.donor)
		players[row.steam].playtime = tonumber(row.playtime)
		players[row.steam].protect = dbTrue(row.protect)
		players[row.steam].protect2 = dbTrue(row.protect2)
		players[row.steam].tokens = tonumber(row.tokens)
		players[row.steam].exile = dbTrue(row.exile)
		players[row.steam].translate = dbTrue(row.translate)
		players[row.steam].prisoner = dbTrue(row.prisoner)
		players[row.steam].prisonReason = row.prisonReason
		players[row.steam].prisonxPosOld = tonumber(row.prisonxPosOld)
		players[row.steam].prisonyPosOld = tonumber(row.prisonyPosOld)
		players[row.steam].prisonzPosOld = tonumber(row.prisonzPosOld)
		players[row.steam].permanentBan = dbTrue(row.permanentBan)
		players[row.steam].whitelisted = dbTrue(row.whitelisted)
		players[row.steam].aliases = row.aliases
		players[row.steam].pvpVictim = row.pvpVictim
		players[row.steam].location = row.location
		players[row.steam].canTeleport = dbTrue(row.canTeleport)
		players[row.steam].ircTranslate = dbTrue(row.ircTranslate)
		players[row.steam].noSpam = dbTrue(row.noSpam)
		players[row.steam].waypointX = tonumber(row.waypointX)
		players[row.steam].waypointY = tonumber(row.waypointY)
		players[row.steam].waypointZ = tonumber(row.waypointZ)
		players[row.steam].accessLevel = tonumber(row.accessLevel)
		players[row.steam].country = row.country
		players[row.steam].ping = tonumber(row.ping)
		players[row.steam].donorLevel = tonumber(row.donorLevel)
		players[row.steam].autoFriend = row.autoFriend
		players[row.steam].bedX = tonumber(row.bedX)
		players[row.steam].bedY = tonumber(row.bedY)
		players[row.steam].bedZ = tonumber(row.bedZ)
		players[row.steam].showLocationMessages = dbTrue(row.showLocationMessages)
		players[row.steam].mute = dbTrue(row.mute)
		players[row.steam].ISP = row.ISP
		players[row.steam].ignorePlayer = dbTrue(row.ignorePlayer)

		-- convert donorExpiry to a timestamp
		words = {}
		for word in row.donorExpiry:gmatch("%w+") do table.insert(words, word) end

		ryear = words[1]
		rmonth = words[2]
		rday = words[3]
		rhour = words[4]
		rmin = words[5]
		rsec = words[6]

		rdate = {year=ryear, month=rmonth, day=rday, hour=rhour, min=rmin, sec=rsec}
		players[row.steam].donorExpiry = os.time(rdate)

		if tonumber(row.accessLevel) < 3 then
			-- add the steamid to the admins table
			if tonumber(row.accessLevel) == 0 then
				owners[players[row.steam].steam] = {}
			end

			if tonumber(row.accessLevel) == 1 then
				admins[players[row.steam].steam] = {}
			end

			if tonumber(row.accessLevel) == 2 then
				mods[players[row.steam].steam] = {}
			end
		end

		row = cursor:fetch(row, "a")	
	end
end


function loadShopCategories()
	-- load shop categories
   shopCategories = {}
	getTableFields("shopCategories")

	cursor,errorString = conn:execute("select * from shopCategories")

	-- add the misc category so it always exists
	if cursor:numrows() > 0 then
		shopCategories["misc"] = {}
		shopCategories["misc"].idx = 1
		shopCategories["misc"].code = "misc"
	end

	row = cursor:fetch({}, "a")
	while row do
		shopCategories[row.category] = {}
		shopCategories[row.category].idx = row.idx
		shopCategories[row.category].code = row.code
		row = cursor:fetch(row, "a")	
	end
end


function loadResetZones()
	-- load reset zones
   resetRegions = {}
	getTableFields("resetZones")

	cursor,errorString = conn:execute("select * from resetZones")
	row = cursor:fetch({}, "a")
	while row do
		resetRegions[row.region] = {}
		row = cursor:fetch(row, "a")	
	end
end


function loadTeleports(tp)
	-- load teleports
	getTableFields("teleports")

	if tp == nil then teleports = {} end

	cursor,errorString = conn:execute("select * from teleports")
	row = cursor:fetch({}, "a")
	while row do
		if tp == row.name or tp == nil then
			teleports[row.name] = {}
			teleports[row.name].id = row.id
			teleports[row.name].active = dbTrue(row.active)
			teleports[row.name].oneway = dbTrue(row.oneway)
			teleports[row.name].public = dbTrue(row.public)
			teleports[row.name].friends = dbTrue(row.friends)
			teleports[row.name].x = tonumber(row.x)
			teleports[row.name].y = tonumber(row.y)
			teleports[row.name].z = tonumber(row.z)
			teleports[row.name].dx = tonumber(row.dx)
			teleports[row.name].dy = tonumber(row.dy)
			teleports[row.name].dz = tonumber(row.dz)
			teleports[row.name].name = row.name
			teleports[row.name].owner = row.owner
			row = cursor:fetch(row, "a")	
		end
	end
end


function loadLocations(loc)
	-- load locations
	getTableFields("locations")

	if loc == nil then locations = {} end

	cursor,errorString = conn:execute("select * from locations")
	row = cursor:fetch({}, "a")
	while row do
		if loc == row.name or loc == nil then
			locations[row.name] = {}
			locations[row.name].name = row.name
			locations[row.name].active = dbTrue(row.active)
			locations[row.name].protect = dbTrue(row.protected)
			locations[row.name].public = dbTrue(row.public)
			locations[row.name].resetZone = dbTrue(row.resetZone)
			locations[row.name].village = dbTrue(row.village)
			locations[row.name].allowbase = dbTrue(row.allowbase)
			locations[row.name].pvp = dbTrue(row.pvp)
			locations[row.name].x = tonumber(row.x)
			locations[row.name].y = tonumber(row.y)
			locations[row.name].z = tonumber(row.z)
			locations[row.name].exitX = tonumber(row.exitX)
			locations[row.name].exitY = tonumber(row.exitY)
			locations[row.name].exitZ = tonumber(row.exitZ)
			locations[row.name].owner = row.owner
			locations[row.name].protectSize = tonumber(row.protectSize)
			locations[row.name].cost = tonumber(row.cost)
			locations[row.name].currency = row.currency
			locations[row.name].accessLevel = tonumber(row.accessLevel)
			locations[row.name].size = tonumber(row.size)
			locations[row.name].miniGame = row.miniGame
			locations[row.name].mayor = row.mayor
			locations[row.name].other = row.other -- used with miniGame
			locations[row.name].killZombies = dbTrue(row.killZombies)
		end

		row = cursor:fetch(row, "a")	
	end
end


function loadBadItems()
	-- load badItems
	getTableFields("badItems")

   badItems = {}
	cursor,errorString = conn:execute("select * from badItems")
	row = cursor:fetch({}, "a")
	while row do
		badItems[row.item] = {}
		badItems[row.item].item = row.item
		badItems[row.item].action = row.action
		row = cursor:fetch(row, "a")	
	end
end


function loadRestrictedItems()
	-- load restrictedItems
	getTableFields("restrictedItems")

   restrictedItems = {}
	cursor,errorString = conn:execute("select * from restrictedItems")
	row = cursor:fetch({}, "a")
	while row do
		restrictedItems[row.item] = {}
		restrictedItems[row.item].qty = tonumber(row.qty)
		restrictedItems[row.item].accessLevel = tonumber(row.accessLevel)
		restrictedItems[row.item].action = row.action
		row = cursor:fetch(row, "a")	
	end
end


function loadFriends()
	-- load friends
	getTableFields("friends")

   friends = {}
	cursor,errorString = conn:execute("select * from friends")
	row = cursor:fetch({}, "a")
	while row do
		if friends[row.steam] == nil then
			friends[row.steam] = {}
			friends[row.steam].friends = ""
		end

		if friends[row.steam].friends == "" then
			friends[row.steam].friends = row.friend
		else
			friends[row.steam].friends = friends[row.steam].friends .. "," .. row.friend .. ","
		end

		row = cursor:fetch(row, "a")	
	end
end


function loadHotspots()
	local idx, nextidx

	-- load hotspots
	getTableFields("hotspots")

	nextidx = -1
   hotspots = {}
	cursor,errorString = conn:execute("select * from hotspots")
	row = cursor:fetch({}, "a")
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

			conn:execute("update hotspots set idx = " .. idx .. " where id = " .. row.id)
		end

		hotspots[idx] = {}
		hotspots[idx].hotspot = row.hotspot
		hotspots[idx].x = row.x
		hotspots[idx].y = row.y
		hotspots[idx].z = row.z
		hotspots[idx].size = row.size
		hotspots[idx].owner = row.owner
		row = cursor:fetch(row, "a")	
	end
end


function loadVillagers()
	-- load villagers
	getTableFields("villagers")

   villagers = {}
	cursor,errorString = conn:execute("select * from villagers")
	row = cursor:fetch({}, "a")
	while row do
		villagers[row.steam .. row.village] = {}
		villagers[row.steam .. row.village].steam = row.steam
		villagers[row.steam .. row.village].village = row.village
		row = cursor:fetch(row, "a")	
	end
end


function loadCustomMessages()
	-- load customMessages
	getTableFields("customMessages")

   customMessages = {}
	cursor,errorString = conn:execute("select * from customMessages")
	row = cursor:fetch({}, "a")
	while row do
		customMessages[row.command] = {}
		customMessages[row.command].message = row.message
		customMessages[row.command].accessLevel = row.accessLevel
		row = cursor:fetch(row, "a")	
	end
end


function loadProxies()
	local proxy

	-- load proxies
	getTableFields("proxies")

   proxies = {}
	cursor,errorString = conn:execute("select * from proxies")
	row = cursor:fetch({}, "a")
	while row do
		proxy = string.trim(row.scanString)
		proxies[proxy] = {}
		proxies[proxy].scanString = proxy
		proxies[proxy].action = row.action
		proxies[proxy].hits = row.hits
		row = cursor:fetch(row, "a")	
	end

	if db2Connected then
		-- check for new proxies in the bots db
		cursor,errorString = connBots:execute("select * from proxies")
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


function loadBadWords()
	-- load badWords
	getTableFields("badWords")

	badWords = {}
	cursor,errorString = conn:execute("select * from badWords")
	row = cursor:fetch({}, "a")
	while row do
		proxies[row.badWord] = {}
		proxies[row.badWord].cost = row.cost
		proxies[row.badWord].counter = row.counter
		row = cursor:fetch(row, "a")	
	end
end


function loadTables()
	dbug("loading players")
	loadPlayers()
	dbug("loaded players")

	loadResetZones()
	dbug("loaded reset zones")

	loadTeleports()
	dbug("loaded teleports")

	loadLocations()
	dbug("loaded locations")

	loadBadItems()
	dbug("loaded bad items")

	loadRestrictedItems()
	dbug("loaded restricted items")

	loadFriends()
	dbug("loaded friends")

	loadHotspots()
	dbug("loaded hotspots")

	loadVillagers()
	dbug("loaded villagers")

	loadShopCategories()
	dbug("loaded shop categories")

	loadCustomMessages()
	dbug("loaded custom messages")

	loadProxies()
	dbug("loaded proxies")
	
	loadBadWords()
	dbug("loaded bad words")
end
