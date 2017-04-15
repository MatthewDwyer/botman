--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug
debug = false

function loadServer()
	local temp, cursor, errorString, row, rows
	
--	debug = false
	calledFunction = "loadServer"
	
	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end	
	-- load server
	if serverFields == nil then
		getServerFields()
	end	
	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end	

	if type(server) ~= "table" then
		server = {}
	end

	cursor,errorString = conn:execute("select * from server")
	rows = tonumber(cursor:numrows())
	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end	
	if rows == 0 then
		if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end		
		initServer()
		if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end	
	else
		if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end	
		row = cursor:fetch({}, "a")
		
		for k,v in pairs(serverFields) do
			if v.type == "var" or v.type == "big" then
				server[k] = row[k]
			end
			
			if v.type == "int" then
				server[k] = tonumber(row[k])
			end			
			
			if v.type == "tin" then
				server[k] = dbTrue(row[k])
			end					
		end	

		botman.chatlogPath = row.chatlogPath
		
		temp = string.split(row.moneyName, "|")
		server.moneyName = temp[1]
		server.moneyPlural = temp[2]			
		
		if server.coppi == nil then server.coppi = false end
		if server.allocs == nil then server.allocs = false end

		if server.ircServer ~= nil then
			temp = string.split(server.ircServer, ":")	
			server.ircServer = temp[1]		
			server.ircPort = temp[2]
		else
			server.ircServer = ""
			server.ircPort = ""
		end
		
		if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end			
	end
end


function loadPlayers(steam)
	local word, words, rdate, ryear, rmonth, rday, rhour, rmin, rsec, k, v

	-- load players table
	--getTableFields("players")
	
	if playerFields == nil then
		getPlayerFields()
	end	

	if steam == nil then
		players = {}
		cursor,errorString = conn:execute("select * from players")
	else
		cursor,errorString = conn:execute("select * from players where steam = " .. steam)
	end

	row = cursor:fetch({}, "a")
	while row do
		players[row.steam] = {}
		
		for k,v in pairs(playerFields) do
			if v.type == "var" or v.type == "big" then
				players[row.steam][k] = row[k]
			end
			
			if v.type == "int" then
				players[row.steam][k] = tonumber(row[k])
			end			
			
			if v.type == "tin" then
				players[row.steam][k] = dbTrue(row[k])
			end					
		end

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
	local cursor, errorString, row
	
--	debug = false
	calledFunction = "teleports"
	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end		
	
	-- load teleports
	getTableFields("teleports")
	
	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end			

	if tp == nil then teleports = {} end
	
	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end			

	if type(teleports) ~= "table" then
		teleports = {}
	end
	
	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end			

	cursor,errorString = conn:execute("select * from teleports")
	row = cursor:fetch({}, "a")	
	
	if row then
		cols = cursor:getcolnames()		
	end
	
	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end			
	
	while row do	
		if tp == row.name or tp == nil then
			teleports[row.name] = {}

			for k,v in pairs(cols) do						
				for n,m in pairs(row) do	
					if n == _G["teleportsFields"][v].field then					
						if _G["teleportsFields"][v].type == "var" or _G["teleportsFields"][v].type == "big" then
							teleports[row.name][n] = m
						end
						
						if _G["teleportsFields"][v].type == "int" then
							teleports[row.name][n] = tonumber(m)
						end			
						
						if _G["teleportsFields"][v].type == "tin" then
							teleports[row.name][n] = dbTrue(m)
						end					
					end
				end			
			end
		end
		
		row = cursor:fetch(row, "a")			
	end	
	
if (debug) then dbug("debug teleports line end") end		
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
	
	if loc == nil then locations = {} end	

	cursor,errorString = conn:execute("select * from locations")
	row = cursor:fetch({}, "a")
	
	if row then
		cols = cursor:getcolnames()		
	end
	
	while row do		
		if (debug) then dbug("debug loadLocation " .. row.name) end			
		if loc == row.name or loc == nil then		
			locations[row.name] = {}

			for k,v in pairs(cols) do						
				for n,m in pairs(row) do	
					if n == _G["locationsFields"][v].field then					
						if _G["locationsFields"][v].type == "var" or _G["locationsFields"][v].type == "big" then
							locations[row.name][n] = m
						end
						
						if _G["locationsFields"][v].type == "int" then
							locations[row.name][n] = tonumber(m)
						end			
						
						if _G["locationsFields"][v].type == "tin" then
							locations[row.name][n] = dbTrue(m)
						end					
					end
				end			
			end
		end
		
		locations[row.name].open = true
		row = cursor:fetch(row, "a")			
	end	
	
	if (debug) then dbug("debug loadLocations end") end		
end


function loadBadItems()
	local cursor, errorString, row
	
	--debug = false
	calledFunction = "badItems"
	if (debug) then dbug("debug badItems line " .. debugger.getinfo(1).currentline) end		
	
	-- load badItems
	getTableFields("badItems")	

	if type(badItems) ~= "table" then
		badItems = {}
	end

	cursor,errorString = conn:execute("select * from badItems")
	row = cursor:fetch({}, "a")	

	if row then
		cols = cursor:getcolnames()		
	end	
	
	while row do		
		badItems[row.item] = {}

		for k,v in pairs(cols) do						
			for n,m in pairs(row) do	
				if n == _G["badItemsFields"][v].field then					
					if _G["badItemsFields"][v].type == "var" or _G["badItemsFields"][v].type == "big" then
						badItems[row.item][n] = m
					end
					
					if _G["badItemsFields"][v].type == "int" then
						badItems[row.item][n] = tonumber(m)
					end			
					
					if _G["badItemsFields"][v].type == "tin" then
						badItems[row.item][n] = dbTrue(m)
					end					
				end
			end			
		end
		
		row = cursor:fetch(row, "a")			
	end	
	
if (debug) then dbug("debug badItems line end") end		
end


function loadRestrictedItems()
	local cursor, errorString, row
	
	--debug = false
	calledFunction = "restrictedItems"
	if (debug) then dbug("debug restrictedItems line " .. debugger.getinfo(1).currentline) end		
	
	-- load restrictedItems
	getTableFields("restrictedItems")	

	if type(restrictedItems) ~= "table" then
		restrictedItems = {}
	end

	cursor,errorString = conn:execute("select * from restrictedItems")
	row = cursor:fetch({}, "a")	

	if row then
		cols = cursor:getcolnames()		
	end	
	
	while row do		
		restrictedItems[row.item] = {}

		for k,v in pairs(cols) do						
			for n,m in pairs(row) do	
				if n == _G["restrictedItemsFields"][v].field then					
					if _G["restrictedItemsFields"][v].type == "var" or _G["restrictedItemsFields"][v].type == "big" then
						restrictedItems[row.item][n] = m
					end
					
					if _G["restrictedItemsFields"][v].type == "int" then
						restrictedItems[row.item][n] = tonumber(m)
					end			
					
					if _G["restrictedItemsFields"][v].type == "tin" then
						restrictedItems[row.item][n] = dbTrue(m)
					end					
				end
			end			
		end
		
		row = cursor:fetch(row, "a")			
	end	
	
if (debug) then dbug("debug restrictedItems line end") end		
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
			friends[row.steam].friends = friends[row.steam].friends .. "," .. row.friend
		end

		row = cursor:fetch(row, "a")
	end
end


function loadHotspots()
	local idx, nextidx
	local cursor, errorString, row
	
	--debug = false
	calledFunction = "hotspots"
	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end		
	
	-- load hotspots
	getTableFields("hotspots")	

	if type(hotspots) ~= "table" then
		hotspots = {}
	end

	cursor,errorString = conn:execute("select * from hotspots")
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

			conn:execute("update hotspots set idx = " .. idx .. " where id = " .. row.id)
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
	
if (debug) then dbug("debug hotspots line end") end		
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
		customMessages[row.command].accessLevel = tonumber(row.accessLevel)
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
		proxies[proxy].hits = tonumber(row.hits)
		row = cursor:fetch(row, "a")
	end

	if botman.db2Connected then
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
		badWords[row.badWord] = {}
		badWords[row.badWord].cost = tonumber(row.cost)
		badWords[row.badWord].counter = tonumber(row.counter)
		row = cursor:fetch(row, "a")
	end
end


function loadPrefabCopies()
	-- load prefabs
    prefabCopies = {}
	getTableFields("prefabCopies")

	cursor,errorString = conn:execute("select * from prefabCopies")
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


function loadWaypoints(steam)
	local idx, k, v
	
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
		cursor,errorString = conn:execute("select * from waypoints")
	else
		cursor,errorString = conn:execute("select * from waypoints where steam = " .. steam)	
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
	-- load whitelist
    whitelist = {}
	getTableFields("whitelist")

	cursor,errorString = conn:execute("select * from whitelist")
	row = cursor:fetch({}, "a")
	while row do
		whitelist[row.steam] = {}
		row = cursor:fetch(row, "a")
	end
end


function loadGimmeZombies()
	local idx	
	local cursor, errorString, row
	
	--debug = false
	calledFunction = "gimmeZombies"
	if (debug) then dbug("debug gimmeZombies line " .. debugger.getinfo(1).currentline) end		
	
	-- load gimmeZombies
	gimmeZombies = {}
	getTableFields("gimmeZombies")	

	cursor,errorString = conn:execute("select * from gimmeZombies")
	row = cursor:fetch({}, "a")	

	if row then
		cols = cursor:getcolnames()		
	end	
	
	while row do		
		idx = tonumber(row.entityID)	
		gimmeZombies[idx] = {}

		for k,v in pairs(cols) do						
			for n,m in pairs(row) do	
				if n == _G["gimmeZombiesFields"][v].field then					
					if _G["gimmeZombiesFields"][v].type == "var" or _G["gimmeZombiesFields"][v].type == "big" then
						gimmeZombies[idx][n] = m
					end
					
					if _G["gimmeZombiesFields"][v].type == "int" then
						gimmeZombies[idx][n] = tonumber(m)
					end			
					
					if _G["gimmeZombiesFields"][v].type == "tin" then
						gimmeZombies[idx][n] = dbTrue(m)
					end					
				end
			end			
		end
		
		row = cursor:fetch(row, "a")			
	end	
	
if (debug) then dbug("debug gimmeZombies line end") end	
end


function loadOtherEntities()
	local idx

	-- load otherEntities
    otherEntities = {}
	getTableFields("otherEntities")

	cursor,errorString = conn:execute("select * from otherEntities")
	row = cursor:fetch({}, "a")
	while row do
		idx = tonumber(row.entityID)
	
		otherEntities[idx] = {}
		otherEntities[idx].entity = row.entity
		otherEntities[idx].doNotSpawn = dbTrue(row.doNotSpawn)		
		row = cursor:fetch(row, "a")
	end
end


function loadTables(skipPlayers)
if (debug) then display("debug loadTables\n") end		
	
	loadServer()	
if (debug) then display("debug loaded server\n") end			

	if not skipPlayers then
		loadPlayers()
if (debug) then display("debug loaded players\n") end			
	end	

	loadResetZones()
if (debug) then display("debug loaded reset zones\n") end			

	loadTeleports()
if (debug) then display("debug loaded teleports\n") end			

if (debug) then display("debug loading locations\n") end			
	loadLocations()
if (debug) then display("debug loaded locations\n") end			

if (debug) then display("debug loading badItems\n") end			
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
	migrateWhitelist()
	
	loadGimmeZombies()
if (debug) then display("debug loaded gimmeZombies\n") end			
	
	loadOtherEntities()
if (debug) then display("debug loaded otherEntities\n") end			
end
