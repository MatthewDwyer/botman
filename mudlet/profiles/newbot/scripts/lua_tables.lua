function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end


function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end


function dumpTable( tbl )
  local k, v, result, file
  local done = {}

  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end

  file = io.open(homedir .. "/" .. "table_dump.txt", "a")
  file:write("{" .. table.concat( result, "," ) .. "}" .. "\n")
  file:close()
end


function loadBotMaintenance()
	botMaintenance = {}

	if isFile(homedir .. "/botMaintenance.lua") then
		table.load(homedir .. "/botMaintenance.lua", botMaintenance)
	end
end


function saveBotMaintenance()
	table.save(homedir .. "/botMaintenance.lua", botMaintenance)
end


function saveLuaTables(date, name)
	if date ~= nil then
		date = date .. "_"
	else
		date = ""
	end

	if name ~= nil then
		name = name .. "_"

		if name == "_" then
			name = ""
		end
	else
		name = ""
	end

	if date ~= "" or name ~= "" then
		-- save with a date or name
		table.save(homedir .. "/data_backup/" .. date .. name .. "badItems.lua", badItems)
		table.save(homedir .. "/data_backup/" .. date .. name .. "bases.lua", bases)
		table.save(homedir .. "/data_backup/" .. date .. name .. "customMessages.lua", customMessages)
		table.save(homedir .. "/data_backup/" .. date .. name .. "friends.lua", friends)
		table.save(homedir .. "/data_backup/" .. date .. name .. "hotspots.lua", hotspots)
		table.save(homedir .. "/data_backup/" .. date .. name .. "locationCategories.lua", locationCategories)
		table.save(homedir .. "/data_backup/" .. date .. name .. "locations.lua", locations)
		table.save(homedir .. "/data_backup/" .. date .. name .. "players.lua", players)
		table.save(homedir .. "/data_backup/" .. date .. name .. "playersArchived.lua", playersArchived)
		table.save(homedir .. "/data_backup/" .. date .. name .. "resetRegions.lua", resetRegions)
		table.save(homedir .. "/data_backup/" .. date .. name .. "restrictedItems.lua", restrictedItems)
		table.save(homedir .. "/data_backup/" .. date .. name .. "server.lua", server)
		table.save(homedir .. "/data_backup/" .. date .. name .. "shopCategories.lua", shopCategories)
		table.save(homedir .. "/data_backup/" .. date .. name .. "teleports.lua", teleports)
		table.save(homedir .. "/data_backup/" .. date .. name .. "villagers.lua", villagers)
		table.save(homedir .. "/data_backup/" .. date .. name .. "waypoints.lua", waypoints)
	else
		-- save without a date or name
		table.save(homedir .. "/data_backup/badItems.lua", badItems)
		table.save(homedir .. "/data_backup/bases.lua", bases)
		table.save(homedir .. "/data_backup/customMessages.lua", customMessages)
		table.save(homedir .. "/data_backup/friends.lua", friends)
		table.save(homedir .. "/data_backup/hotspots.lua", hotspots)
		table.save(homedir .. "/data_backup/locationCategories.lua", locationCategories)
		table.save(homedir .. "/data_backup/locations.lua", locations)
		table.save(homedir .. "/data_backup/modVersions.lua", modVersions)
		table.save(homedir .. "/data_backup/players.lua", players)
		table.save(homedir .. "/data_backup/playersArchived.lua", playersArchived)
		table.save(homedir .. "/data_backup/resetRegions.lua", resetRegions)
		table.save(homedir .. "/data_backup/restrictedItems.lua", restrictedItems)
		table.save(homedir .. "/data_backup/server.lua", server)
		table.save(homedir .. "/data_backup/shopCategories.lua", shopCategories)
		table.save(homedir .. "/data_backup/teleports.lua", teleports)
		table.save(homedir .. "/data_backup/villagers.lua", villagers)
		table.save(homedir .. "/data_backup/waypoints.lua", waypoints)
	end

	table.save(homedir .. "/data_backup/igplayers.lua", igplayers)
end


function importServer()
	dbug("Importing Server")

	conn:execute("DELETE FROM server)")
	conn:execute("INSERT INTO server (ircMain, ircAlerts, ircWatch, rules, shopCountdown, gimmePeace, allowGimme, mapSize, baseCooldown, MOTD, allowShop, chatColour, botName, lottery, allowWaypoints, prisonSize, baseSize) VALUES ('" .. escape(server.ircMain) .. "','" .. escape(server.ircAlerts) .. "','" .. escape(server.ircWatch) .. "','" .. escape(server.rules) .. "',0," .. dbBool(server.gimmePeace) .. "," .. dbBool(server.allowGimme) .. "," .. server.mapSize .. "," .. server.baseCooldown .. ",'" .. escape(server.MOTD) .. "'," .. dbBool(server.allowShop) .. ",'" .. server.chatColour .. "','" .. escape(server.botName) .. "'," .. server.lottery .. "," .. dbBool(server.allowWaypoints) .. "," .. server.prisonSize .. "," .. server.baseSize .. ")")

	-- reload from db to grab defaults for any missing data
	loadServer()

	openUserWindow(server.windowGMSG)
	openUserWindow(server.windowDebug)
	openUserWindow(server.windowLists)
end


function importShopCategories()
	dbug("Importing Shop Categories")

	for k,v in pairs(shopCategories) do
		conn:execute("INSERT INTO shopCategories (category, idx, code) VALUES ('" .. escape(k) .. "'," .. v.idx .. ",'" .. v.code .. "')")
	end

	dbug("Shop Categories Imported")
end


function importPlayers()
	dbug("Importing Players")

	for k,v in pairs(players) do
		dbug("Importing " .. k .. " " .. v.id .. " " .. v.name)
		conn:execute("INSERT INTO players (steam, id, name) VALUES (" .. k .. "," .. v.id .. ",'" .. escape(v.name) .. "')")
		conn:execute("INSERT INTO persistentQueue (steam, command) VALUES (" .. k .. ",'update player')")
	end

	for k,v in pairs(playersArchived) do
		dbug("Importing archived " .. k .. " " .. v.id .. " " .. v.name)
		conn:execute("INSERT INTO playersArchived (steam, id, name) VALUES (" .. k .. "," .. v.id .. ",'" .. escape(v.name) .. "')")
		conn:execute("INSERT INTO persistentQueue (steam, command) VALUES (" .. k .. ",'update archived player')")
	end

	dbug("Players Imported")
end


function importTeleports()
	local k, v

	dbug("Importing Teleports")

	for k,v in pairs(teleports) do
		conn:execute("INSERT INTO teleports (name, active, public, oneway, friends, x, y, z, dx, dy, dz, owner) VALUES ('" .. escape(v.name) .. "'," .. dbBool(v.active) .. "," .. dbBool(v.public) .. "," .. dbBool(v.oneway) .. "," .. dbBool(v.friends) .. "," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. v.dx .. "," .. v.dy .. "," .. v.owner .. ")")
	end
end


function importLocationCategories()
	local k, v

	dbug("Importing locationCategories")

	for k,v in pairs(locationCategories) do
		conn:execute("INSERT INTO locationCategories (categoryName, minAccessLevel, maxAccessLevel) VALUES (" .. escape(k) .. "," .. v.minAccessLevel .. "," .. v.maxAccessLevel .. ")")
	end

	dbug("locationCategories Imported")
end


function importLocations()
	local sql, fields, values, k, v

	dbug("Importing Locations")

	for k,v in pairs(locations) do
		fields = "name, x, y, z, public, active"
		values = "'" .. escape(v.name) .. "'," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. dbBool(v.public) .. "," .. dbBool(v.active)

		if v.protect ~= nil then
			fields = fields .. ", protected"
			values = values .. "," .. dbBool(v.protect)
		end

		if v.village ~= nil then
			fields = fields .. ", village"
			values = values .. "," .. dbBool(v.village)
		end

		if v.pvp ~= nil then
			fields = fields .. ", pvp"
			values = values .. "," .. dbBool(v.pvp)
		end

		if v.allowBase ~= nil then
			fields = fields .. ", allowBase"
			values = values .. "," .. dbBool(v.allowBase)
		end

		if v.accessLevel ~= nil then
			fields = fields .. ", accessLevel"
			values = values .. "," .. dbBool(v.accessLevel)
		end

		if v.owner ~= nil then
			fields = fields .. ", owner"
			values = values .. "," .. v.owner
		end

		if v.mayor ~= nil then
			fields = fields .. ", mayor"
			values = values .. "," .. v.mayor
		end

		if v.protectSize ~= nil then
			fields = fields .. ", protectSize"
			values = values .. "," .. v.protectSize
		end

		if v.killZombies ~= nil then
			fields = fields .. ", killZombies"
			values = values .. "," .. dbBool(v.killZombies)
		end

		sql = "INSERT INTO locations (" .. fields .. ") VALUES (" .. values .. ")"

		conn:execute(sql)
	end

	dbug("Locations Imported")
end


function importFriends()
	local friendlist, i, max, k, v

	dbug("Importing Friends")

	for k,v in pairs(friends) do
		dbug("Importing friends of " .. k)

		friendlist = string.split(v.friends, ",")

		max = table.maxn(friendlist)
		for i=1,max,1 do
			if friendlist[i] ~= "" then
				conn:execute("INSERT INTO friends (steam, friend) VALUES (" .. k .. "," .. friendlist[i] .. ")")
			end
		end
	end

	dbug("Friends Imported")
end


function importVillagers()
	local k, v

	dbug("Importing Villagers")

	for k,v in pairs(villagers) do
		conn:execute("INSERT INTO villagers (steam, village) VALUES (" .. k .. ",'" .. escape(v.village) .. "')")
	end

	dbug("Villagers Imported")
end


function importHotspots()
	local k, v

	dbug("Importing Hotspots")

	for k,v in pairs(hotspots) do
		if v.radius then
			conn:execute("INSERT INTO hotspots (hotspot, x, y, z, owner, size) VALUES ('" .. escape(v.message) .. "'," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. v.owner .. "," .. v.radius .. ")")
		else
			conn:execute("INSERT INTO hotspots (hotspot, x, y, z, owner) VALUES ('" .. escape(v.message) .. "'," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. v.owner .. ")")
		end
	end

	dbug("Hotspots Imported")
end


function importResets()
	local k, v

	dbug("Importing Reset Zones")

	for k,v in pairs(resetRegions) do
		conn:execute("INSERT INTO resetZones (region) VALUES ('" .. escape(k) .. "')")
	end

	dbug("Resets Imported")
end


function importBaditems()
	local k, v

	dbug("Importing Bad Items")

	for k,v in pairs(badItems) do
		conn:execute("INSERT INTO badItems (item) VALUES ('" .. escape(k) .. "')")
	end

	dbug("Bad Items Imported")
end


function importWaypoints()
	local k, v

	dbug("Importing Waypoints")

	for k,v in pairs(waypoints) do
		conn:execute("INSERT INTO waypoints (steam, name, x, y, z, linked, shared) VALUES (" .. v.steam .. ",'" .. escape(v.name) .. "'," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. v.linked .. "," .. dbBool(v.shared) .. ")")
	end

	dbug("Waypoints Imported")
end


function importModVersions()
	local k, v

	if isFile(homedir .. "/data_backup/modVersions.lua") then
		modVersions = {}
		table.load(homedir .. "/data_backup/modVersions.lua", modVersions)
		server.coppi = false
		server.csmm = false
		server.SDXDetected = false
		server.ServerToolsDetected = false
		server.djkrose = false

		if not botMaintenance.modsInstalled then
			server.stompy = false
			server.allocs = false
		end

		for k,v in pairs(modVersions) do
			matchAll(k)
		end
	end
end


function importLuaData(pathPrefix, onlyImportThis, path)
	local k, v, id, temp

	dbug("Importing Lua Tables")

	if pathPrefix then
		if onlyImportThis ~= "" then
			irc_chat(server.ircMain, "Restoring requested bot data from backup " .. pathPrefix)
			alertAdmins("Restoring requested bot data from backup " .. pathPrefix)
		else
			irc_chat(server.ircMain, "Restoring backup " .. pathPrefix)
			alertAdmins("Restoring backup " .. pathPrefix)
		end
	else
		if onlyImportThis ~= "" then
			irc_chat(server.ircMain, "Restoring requested bot data from last backup.")
			alertAdmins("Restoring requested bot data from last backup.")
		else
			irc_chat(server.ircMain, "Restoring last backup.")
			alertAdmins("Restoring last backup.")
		end
	end

	if path == nil then
		path = homedir .. "/data_backup/"
	end

	if not pathPrefix then
		pathPrefix = ""
	end

	if onlyImportThis == "" then
		dbug("Loading bad items")
		badItems = {}
		table.load(path .. pathPrefix .. "badItems.lua", badItems)

		dbug("Loading friends")
		friends = {}
		table.load(path .. pathPrefix .. "friends.lua", friends)

		dbug("Loading hotspots")
		hotspots = {}
		table.load(path .. pathPrefix .. "hotspots.lua", hotspots)

		dbug("Loading locationCategories")
		locationCategories = {}
		table.load(path .. pathPrefix .. "locationCategories.lua", locationCategories)

		dbug("Loading locations")
		locations = {}
		table.load(path .. pathPrefix .. "locations.lua", locations)

		dbug("Loading players")
		players = {}
		table.load(path .. pathPrefix .. "players.lua", players)

		dbug("Loading reset zones")
		resetZones = {}
		table.load(path .. pathPrefix .. "resetRegions.lua", resetRegions)

		dbug("Loading server")
		table.load(path .. pathPrefix .. "server.lua", server)

		dbug("Loading shop categories")
		shopCategories = {}
		table.load(path .. pathPrefix .. "shopCategories.lua", shopCategories)

		dbug("Loading teleports")
		teleports = {}
		table.load(path .. pathPrefix .. "teleports.lua", teleports)

		dbug("Loading villagers")
		villagers = {}
		table.load(path .. pathPrefix .. "villagers.lua", villagers)

		dbug("Loading waypoints")
		waypoints = {}
		table.load(path .. pathPrefix .. "waypoints.lua", waypoints)

		conn:execute("TRUNCATE badItems")
		conn:execute("TRUNCATE friends")
		conn:execute("TRUNCATE hotspots")
		conn:execute("TRUNCATE locations")
		conn:execute("TRUNCATE locationCategories")
		conn:execute("TRUNCATE players")
		conn:execute("TRUNCATE resetZones")
		conn:execute("TRUNCATE shopCategories")
		conn:execute("TRUNCATE teleports")
		conn:execute("TRUNCATE villagers")
		conn:execute("TRUNCATE waypoints")

		importBaditems()
		importHotspots()
		importLocationCategories()
		importLocations()
		importResets()
		importTeleports()
		importVillagers()
		importFriends()
		importShopCategories()
		importWaypoints()
		importPlayers()
	else
		-- restore bases and cash for the players table
		table.load(path .. pathPrefix .. "players.lua", playersTemp)

		for k,v in pairs(playersTemp) do
			if string.find(onlyImportThis, "bases") then
				if players[k] then
					if players[k].homeX == 0 and players[k].homeZ == 0 then
						players[k].homeX = v.homeX
						players[k].homeY = v.homeY
						players[k].homeZ = v.homeZ
						players[k].protect = v.protect
						players[k].protectSize = v.protectSize
					end

					if players[k].home2X == 0 and players[k].home2Z == 0 then
						players[k].home2X = v.home2X
						players[k].home2Y = v.home2Y
						players[k].home2Z = v.home2Z
						players[k].protect2 = v.protect2
						players[k].protect2Size = v.protect2Size
					end
				end
			end

			if string.find(onlyImportThis, "cash") then
				if players[k] then
					players[k].cash = players[k].cash + v.cash
				end
			end

			if string.find(onlyImportThis, "donors") then
				if players[k] then
					players[k].donor = v.donor
					players[k].donorLevel = v.donorLevel
					players[k].donorExpiry = v.donorExpiry
				end
			end

			if string.find(onlyImportThis, "colours") then
				if players[k] then
					players[k].chatColour = v.chatColour
				end
			end

			if string.find(onlyImportThis, " player ") then
				temp = string.split(onlyImportThis, " ")
				id = temp[2]

				if players[id] then
					players[id] = {}
					players[id] = playersTemp[id]
					conn:execute("INSERT INTO players (steam) VALUES (" .. k .. ")")
					conn:execute("INSERT INTO persistentQueue (steam, command) VALUES (" .. k .. ",'update player')")
				end
			end
		end

		playersTemp = nil
	end

	if string.find(onlyImportThis, "friends") then
		dbug("Loading friends")
		friends = {}
		table.load(path .. pathPrefix .. "friends.lua", friends)

		conn:execute("TRUNCATE friends")
		importFriends()
	end

	if string.find(onlyImportThis, "hotspots") then
		dbug("Loading hotspots")
		hotspots = {}
		table.load(path .. pathPrefix .. "hotspots.lua", hotspots)

		conn:execute("TRUNCATE hotspots")
		importHotspots()
	end

	if string.find(onlyImportThis, "locations") then
		dbug("Loading locationCategories")
		locationCategories = {}
		table.load(path .. pathPrefix .. "locationCategories.lua", locationCategories)

		dbug("Loading locations")
		locations = {}
		table.load(path .. pathPrefix .. "locations.lua", locations)

		conn:execute("TRUNCATE locations")
		conn:execute("TRUNCATE locationCategories")
		importLocationCategories()
		importLocations()
	end

	if string.find(onlyImportThis, "players") then
		dbug("Loading players")
		players = {}
		table.load(path .. pathPrefix .. "players.lua", players)

		conn:execute("TRUNCATE players")
		importPlayers()
	end

	if string.find(onlyImportThis, "resets") then
		dbug("Loading reset zones")
		resetZones = {}
		table.load(path .. pathPrefix .. "resetRegions.lua", resetRegions)

		conn:execute("TRUNCATE resetZones")
		importResets()
	end

	if string.find(onlyImportThis, "teleports") then
		dbug("Loading teleports")
		teleports = {}
		table.load(path .. pathPrefix .. "teleports.lua", teleports)

		conn:execute("TRUNCATE teleports")
		importTeleports()
	end

	if string.find(onlyImportThis, "villagers") then
		dbug("Loading villagers")
		villagers = {}
		table.load(path .. pathPrefix .. "villagers.lua", villagers)

		conn:execute("TRUNCATE villagers")
		importVillagers()
	end

	if string.find(onlyImportThis, "waypoints") then
		dbug("Loading waypoints")
		waypoints = {}
		table.load(path .. pathPrefix .. "waypoints.lua", waypoints)

		conn:execute("TRUNCATE waypoints")
		importWaypoints()
	end

	dbug("Import of Lua tables Complete")
	irc_chat(server.ircMain, "Bot restore complete. It is now safe to turn off your modem. xD")
	alertAdmins("Bot restore complete. It is now safe to turn off your modem. xD")
end
