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
  local result, done = {}, {}
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


function saveLuaTables(date)
	if date ~= nil then
		date = date .. "_"
	else
		date = ""
	end

	dbug("saving Lua tables")
	-- save a datestamped copy (for manual restore)
	table.save(homedir .. "/data_backup/" .. date .. "badItems.lua", badItems)
	table.save(homedir .. "/data_backup/" .. date .. "customMessages.lua", customMessages)
	table.save(homedir .. "/data_backup/" .. date .. "friends.lua", friends)
	table.save(homedir .. "/data_backup/" .. date .. "hotspots.lua", hotspots)
	table.save(homedir .. "/data_backup/" .. date .. "locations.lua", locations)
	table.save(homedir .. "/data_backup/" .. date .. "players.lua", players)
	table.save(homedir .. "/data_backup/" .. date .. "playersArchived.lua", playersArchived)
	table.save(homedir .. "/data_backup/" .. date .. "resetRegions.lua", resetRegions)
	table.save(homedir .. "/data_backup/" .. date .. "restrictedItems.lua", restrictedItems)
	table.save(homedir .. "/data_backup/" .. date .. "server.lua", server)
	table.save(homedir .. "/data_backup/" .. date .. "shopCategories.lua", shopCategories)
	table.save(homedir .. "/data_backup/" .. date .. "teleports.lua", teleports)
	table.save(homedir .. "/data_backup/" .. date .. "villagers.lua", villagers)
	table.save(homedir .. "/data_backup/" .. date .. "waypoints.lua", waypoints)

	-- save without a datestamp (used by /restore backup)
	table.save(homedir .. "/data_backup/badItems.lua", badItems)
	table.save(homedir .. "/data_backup/customMessages.lua", customMessages)
	table.save(homedir .. "/data_backup/friends.lua", friends)
	table.save(homedir .. "/data_backup/hotspots.lua", hotspots)
	table.save(homedir .. "/data_backup/locations.lua", locations)
	table.save(homedir .. "/data_backup/players.lua", players)
	table.save(homedir .. "/data_backup/playersArchived.lua", playersArchived)
	table.save(homedir .. "/data_backup/resetRegions.lua", resetRegions)
	table.save(homedir .. "/data_backup/restrictedItems.lua", restrictedItems)
	table.save(homedir .. "/data_backup/server.lua", server)
	table.save(homedir .. "/data_backup/shopCategories.lua", shopCategories)
	table.save(homedir .. "/data_backup/teleports.lua", teleports)
	table.save(homedir .. "/data_backup/villagers.lua", villagers)
	table.save(homedir .. "/data_backup/waypoints.lua", waypoints)

	dbug("finished saving Lua tables")
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
		fixMissingPlayer(k)
		updatePlayer(k)
	end

	for k,v in pairs(playersArchived) do
		dbug("Importing archived " .. k .. " " .. v.id .. " " .. v.name)
		conn:execute("INSERT INTO playersArchived (steam, id, name) VALUES (" .. k .. "," .. v.id .. ",'" .. escape(v.name) .. "')")
		fixMissingArchivedPlayer(k)
		updateArchivedPlayer(k)
	end

	dbug("Players Imported")
end


function importTeleports()
	dbug("Importing Teleports")

	for k,v in pairs(teleports) do
		conn:execute("INSERT INTO teleports (name, active, public, oneway, friends, x, y, z, dx, dy, dz, owner) VALUES ('" .. escape(v.name) .. "'," .. dbBool(v.active) .. "," .. dbBool(v.public) .. "," .. dbBool(v.oneway) .. "," .. dbBool(v.friends) .. "," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. v.dx .. "," .. v.dy .. "," .. v.owner .. ")")
	end
end


function importLocations()
	local sql, fields, values

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
	local friendlist, i, max

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
	dbug("Importing Villagers")

	for k,v in pairs(villagers) do
		conn:execute("INSERT INTO villagers (steam, village) VALUES (" .. k .. ",'" .. escape(v.village) .. "')")
	end

	dbug("Villagers Imported")
end


function importHotspots()
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
	dbug("Importing Reset Zones")

	for k,v in pairs(resetRegions) do
		conn:execute("INSERT INTO resetZones (region) VALUES ('" .. escape(k) .. "')")
	end

	dbug("Resets Imported")
end


function importBaditems()
	dbug("Importing Bad Items")

	for k,v in pairs(badItems) do
		conn:execute("INSERT INTO badItems (item) VALUES ('" .. escape(k) .. "')")
	end

	dbug("Bad Items Imported")
end


function importWaypoints()
	dbug("Importing Waypoints")

	for k,v in pairs(waypoints) do
		conn:execute("INSERT INTO waypoints (steam, name, x, y, z, linked, shared) VALUES (" .. v.steam .. ",'" .. escape(v.name) .. "'," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. v.linked .. "," .. dbBool(v.shared) .. ")")
	end

	dbug("Waypoints Imported")
end



function importLuaData()
	dbug("Importing Lua Tables")
	message("say Restoring bot data from backup..")

	dbug("Loading server")
	table.load(homedir .. "/data_backup/server.lua", server)

	dbug("Loading teleports")
	teleports = {}
	table.load(homedir .. "/data_backup/teleports.lua", teleports)

	 dbug("Loading friends")
	 friends = {}
	 table.load(homedir .. "/data_backup/friends.lua", friends)

	dbug("Loading locations")
	locations = {}
	table.load(homedir .. "/data_backup/locations.lua", locations)

	dbug("Loading hotspots")
	hotspots = {}
	table.load(homedir .. "/data_backup/hotspots.lua", hotspots)

	dbug("Loading villagers")
	villagers = {}
	table.load(homedir .. "/data_backup/villagers.lua", villagers)

	dbug("Loading shop categories")
	shopCategories = {}
	table.load(homedir .. "/data_backup/shopCategories.lua", shopCategories)

	dbug("Loading reset zones")
	resetZones = {}
	table.load(homedir .. "/data_backup/resetRegions.lua", resetRegions)

	dbug("Loading bad items")
	badItems = {}
	table.load(homedir .. "/data_backup/badItems.lua", badItems)

	dbug("Loading waypoints")
	waypoints = {}
	table.load(homedir .. "/data_backup/waypoints.lua", waypoints)

	dbug("Loading players")
	players = {}
	table.load(homedir .. "/data_backup/players.lua", players)

	conn:execute("TRUNCATE badItems")
	conn:execute("TRUNCATE friends")
	conn:execute("TRUNCATE hotspots")
	conn:execute("TRUNCATE locations")
	conn:execute("TRUNCATE players")
	conn:execute("TRUNCATE resetZones")
	conn:execute("TRUNCATE shopCategories")
	conn:execute("TRUNCATE teleports")
	conn:execute("TRUNCATE villagers")
	conn:execute("TRUNCATE waypoints")

	importBaditems()
	importHotspots()
	importLocations()
	importResets()
	importTeleports()
	importVillagers()
	importFriends()
	importShopCategories()
	importWaypoints()
	importPlayers()

	dbug("Import of Lua tables Complete")
	message("say Bot restore complete. It is now safe to turn off your modem. xD")
end
