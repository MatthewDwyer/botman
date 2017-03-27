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


function saveLuaTables(date)
	if date ~= nil then
		date = date .. "_"
	else
		date = ""
	end

	dbug("saving Lua tables")
	table.save(homedir .. "/" .. date .. "badItems.lua", badItems)
	table.save(homedir .. "/" .. date .. "customMessages.lua", customMessages)
	table.save(homedir .. "/" .. date .. "friends.lua", friends)
	table.save(homedir .. "/" .. date .. "hotspots.lua", hotspots)
	table.save(homedir .. "/" .. date .. "locations.lua", locations)
	table.save(homedir .. "/" .. date .. "players.lua", players)
	table.save(homedir .. "/" .. date .. "resetRegions.lua", resetRegions)
	table.save(homedir .. "/" .. date .. "restrictedItems.lua", restrictedItems)
	table.save(homedir .. "/" .. date .. "server.lua", server)
	table.save(homedir .. "/" .. date .. "shopCategories.lua", shopCategories)
	table.save(homedir .. "/" .. date .. "teleports.lua", teleports)
	table.save(homedir .. "/" .. date .. "villagers.lua", villagers)
	table.save(homedir .. "/" .. date .. "waypoints.lua", waypoints)	
	
	table.save(homedir .. "/data_backup/badItems.lua", badItems)
	table.save(homedir .. "/data_backup/customMessages.lua", customMessages)
	table.save(homedir .. "/data_backup/friends.lua", friends)
	table.save(homedir .. "/data_backup/hotspots.lua", hotspots)
	table.save(homedir .. "/data_backup/locations.lua", locations)
	table.save(homedir .. "/data_backup/players.lua", players)
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
	message("say [" .. server.chatColour .. "]Importing server[-]")
	conn:execute("DELETE FROM server)")
	conn:execute("INSERT INTO server (ircMain, ircAlerts, ircWatch, rules, shopCountdown, gimmePeace, allowGimme, mapSize, baseCooldown, MOTD, allowShop, chatColour, botName, lottery, allowWaypoints, prisonSize, baseSize) VALUES ('" .. escape(server.ircMain) .. "','" .. escape(server.ircAlerts) .. "','" .. escape(server.ircWatch) .. "','" .. escape(server.rules) .. "',0," .. dbBool(server.gimmePeace) .. "," .. dbBool(server.allowGimme) .. "," .. server.mapSize .. "," .. server.baseCooldown .. ",'" .. escape(server.MOTD) .. "'," .. dbBool(server.allowShop) .. ",'" .. server.chatColour .. "','" .. escape(server.botName) .. "'," .. server.lottery .. "," .. dbBool(server.allowWaypoints) .. "," .. server.prisonSize .. "," .. server.baseSize .. ")")

	-- reload from db to grab defaults for any missing data
	loadServer()

	openUserWindow(server.windowGMSG) 
	openUserWindow(server.windowDebug) 
	openUserWindow(server.windowLists) 
	openUserWindow(server.windowPlayers) 
	openUserWindow(server.windowAlerts) 
end


function importShopCategories()
	dbug("Importing Shop Categories")
	message("say [" .. server.chatColour .. "]Importing shop categories[-]")

	for k,v in pairs(shopCategories) do
		conn:execute("INSERT INTO shopCategories (category, idx, code) VALUES ('" .. escape(k) .. "'," .. v.idx .. ",'" .. v.code .. "')")
	end

	dbug("Shop Categories Imported")
end


function importPlayers()
	dbug("Importing Players")
	message("say [" .. server.chatColour .. "]Importing players[-]")

	for k,v in pairs(players) do
		conn:execute("INSERT INTO players (steam, id, name) VALUES (" .. k .. "," .. v.id .. ",'" .. escape(v.name) .. "')")		
		fixMissingPlayer(k)
		updatePlayer(k)
	end

	dbug("Players Imported")
end


function importTeleports()
	dbug("Importing Teleports")
	message("say [" .. server.chatColour .. "]Importing teleports[-]")

	for k,v in pairs(teleports) do
		conn:execute("INSERT INTO teleports (name, active, public, oneway, friends, x, y, z, dx, dy, dz, owner) VALUES ('" .. escape(v.name) .. "'," .. dbBool(v.active) .. "," .. dbBool(v.public) .. "," .. dbBool(v.oneway) .. "," .. dbBool(v.friends) .. "," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. v.dx .. "," .. v.dy .. "," .. v.owner .. ")")
	end
end


function importLocations()
	local sql, fields, values

	dbug("Importing Locations")
	message("say [" .. server.chatColour .. "]Importing locations[-]")

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
	message("say [" .. server.chatColour .. "]Importing friends[-]")

	for k,v in pairs(friends) do
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
	message("say [" .. server.chatColour .. "]Importing villagers[-]")

	for k,v in pairs(villagers) do
		conn:execute("INSERT INTO villagers (steam, village) VALUES (" .. k .. ",'" .. escape(v.village) .. "')")
	end

	dbug("Villagers Imported")
end


function importHotspots()
	dbug("Importing Hotspots")
	message("say [" .. server.chatColour .. "]Importing hotspots[-]")

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
	message("say [" .. server.chatColour .. "]Importing reset zones[-]")

	for k,v in pairs(resetRegions) do
		conn:execute("INSERT INTO resetZones (region) VALUES ('" .. escape(k) .. "')")
	end

	dbug("Resets Imported")
end


function importBaditems()
	dbug("Importing Bad Items")
	message("say [" .. server.chatColour .. "]Importing bad items list[-]")

	for k,v in pairs(badItems) do
		conn:execute("INSERT INTO badItems (item) VALUES ('" .. escape(k) .. "')")
	end

	dbug("Bad Items Imported")
end


function importWaypoints()
	dbug("Importing Waypoints")
	message("say [" .. server.chatColour .. "]Importing waypoints[-]")

	for k,v in pairs(waypoints) do
		conn:execute("INSERT INTO waypoints (steam, name, x, y, z, linked, shared) VALUES (" .. v.steam .. ",'" .. escape(v.name) .. "'," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. dbBool(v.linked) .. "," .. dbBool(v.shared) .. ")")
	end

	dbug("Waypoints Imported")
end



function importLuaData()
	dbug("Importing Lua Tables")
	message("say [" .. server.chatColour .. "]Restoring bot data from backup..[-]")

dbug("import 1")
	dbug("Loading server")
	table.load(homedir .. "/data_backup/server.lua", server)
dbug("import 2")
	dbug("Loading players")
	table.load(homedir .. "/data_backup/players.lua", players)
dbug("import 3")
	dbug("Loading teleports")
	table.load(homedir .. "/data_backup/teleports.lua", teleports)
dbug("import 4")
	dbug("Loading friends")
	table.load(homedir .. "/data_backup/friends.lua", friends)
dbug("import 5")
	dbug("Loading locations")
	table.load(homedir .. "/data_backup/locations.lua", locations)
dbug("import 6")
	dbug("Loading hotspots")
	table.load(homedir .. "/data_backup/hotspots.lua", hotspots)
dbug("import 7")
	dbug("Loading villagers")
	table.load(homedir .. "/data_backup/villagers.lua", villagers)
dbug("import 9")
	dbug("Loading shop categories")
	table.load(homedir .. "/data_backup/shopCategories.lua", shopCategories)
dbug("import 11")
	dbug("Loading reset zones")
	table.load(homedir .. "/data_backup/resetRegions.lua", resetRegions)
dbug("import 12")
	dbug("Loading bad items")
	table.load(homedir .. "/data_backup/badItems.lua", badItems)
dbug("import 13")
	conn:execute("DELETE FROM badItems")
	conn:execute("DELETE FROM friends")
	conn:execute("DELETE FROM hotspots")
	conn:execute("DELETE FROM locations")
	conn:execute("DELETE FROM players")
	conn:execute("DELETE FROM resetZones")
	conn:execute("DELETE FROM shopCategories")
	conn:execute("DELETE FROM teleports")
	conn:execute("DELETE FROM villagers")

dbug("import 4")
	importPlayers()
dbug("import 5")
	importBaditems()
dbug("import 6")
	importHotspots()
dbug("import 8")
	importLocations()
dbug("import 9")
	importResets()
dbug("import 12")
	importTeleports()
dbug("import 13")
	importVillagers()
dbug("import 14")
	importFriends()
dbug("import 15")
	importShopCategories()

	dbug("Import of Lua tables Complete")
	message("say [" .. server.chatColour .. "]Bot restore complete.[-]")
end
