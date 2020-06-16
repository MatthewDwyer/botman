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
		table.save(homedir .. "/data_backup/" .. date .. name .. "donors.lua", donors)
		table.save(homedir .. "/data_backup/" .. date .. name .. "friends.lua", friends)
		table.save(homedir .. "/data_backup/" .. date .. name .. "hotspots.lua", hotspots)
		table.save(homedir .. "/data_backup/" .. date .. name .. "locationCategories.lua", locationCategories)
		table.save(homedir .. "/data_backup/" .. date .. name .. "locations.lua", locations)
		table.save(homedir .. "/data_backup/" .. date .. name .. "modBotman.lua", modBotman)
		table.save(homedir .. "/data_backup/" .. date .. name .. "modVersions.lua", modVersions)
		table.save(homedir .. "/data_backup/" .. date .. name .. "players.lua", players)
		table.save(homedir .. "/data_backup/" .. date .. name .. "playersArchived.lua", playersArchived)
		table.save(homedir .. "/data_backup/" .. date .. name .. "resetRegions.lua", resetRegions)
		table.save(homedir .. "/data_backup/" .. date .. name .. "restrictedItems.lua", restrictedItems)
		table.save(homedir .. "/data_backup/" .. date .. name .. "server.lua", server)
		table.save(homedir .. "/data_backup/" .. date .. name .. "shop.lua", shop)
		table.save(homedir .. "/data_backup/" .. date .. name .. "shopCategories.lua", shopCategories)
		table.save(homedir .. "/data_backup/" .. date .. name .. "teleports.lua", teleports)
		table.save(homedir .. "/data_backup/" .. date .. name .. "villagers.lua", villagers)
		table.save(homedir .. "/data_backup/" .. date .. name .. "waypoints.lua", waypoints)
	else
		-- save without a date or name
		table.save(homedir .. "/data_backup/badItems.lua", badItems)
		table.save(homedir .. "/data_backup/bases.lua", bases)
		table.save(homedir .. "/data_backup/customMessages.lua", customMessages)
		table.save(homedir .. "/data_backup/donors.lua", donors)
		table.save(homedir .. "/data_backup/friends.lua", friends)
		table.save(homedir .. "/data_backup/hotspots.lua", hotspots)
		table.save(homedir .. "/data_backup/locationCategories.lua", locationCategories)
		table.save(homedir .. "/data_backup/locations.lua", locations)
		table.save(homedir .. "/data_backup/modBotman.lua", modBotman)
		table.save(homedir .. "/data_backup/modVersions.lua", modVersions)
		table.save(homedir .. "/data_backup/players.lua", players)
		table.save(homedir .. "/data_backup/playersArchived.lua", playersArchived)
		table.save(homedir .. "/data_backup/resetRegions.lua", resetRegions)
		table.save(homedir .. "/data_backup/restrictedItems.lua", restrictedItems)
		table.save(homedir .. "/data_backup/server.lua", server)
		table.save(homedir .. "/data_backup/shop.lua", shop)
		table.save(homedir .. "/data_backup/shopCategories.lua", shopCategories)
		table.save(homedir .. "/data_backup/teleports.lua", teleports)
		table.save(homedir .. "/data_backup/villagers.lua", villagers)
		table.save(homedir .. "/data_backup/waypoints.lua", waypoints)
	end

	table.save(homedir .. "/data_backup/igplayers.lua", igplayers)
end


function importServer()
	if debug then dbug("Importing Server") end

	conn:execute("DELETE FROM server)")
	conn:execute("INSERT INTO server (ircMain, ircAlerts, ircWatch, rules, shopCountdown, gimmePeace, allowGimme, mapSize, baseCooldown, MOTD, allowShop, chatColour, botName, lottery, allowWaypoints, prisonSize, baseSize) VALUES ('" .. escape(server.ircMain) .. "','" .. escape(server.ircAlerts) .. "','" .. escape(server.ircWatch) .. "','" .. escape(server.rules) .. "',0," .. dbBool(server.gimmePeace) .. "," .. dbBool(server.allowGimme) .. "," .. server.mapSize .. "," .. server.baseCooldown .. ",'" .. escape(server.MOTD) .. "'," .. dbBool(server.allowShop) .. ",'" .. server.chatColour .. "','" .. escape(server.botName) .. "'," .. server.lottery .. "," .. dbBool(server.allowWaypoints) .. "," .. server.prisonSize .. "," .. server.baseSize .. ")")

	-- reload from db to grab defaults for any missing data
	loadServer()

	openUserWindow(server.windowGMSG)
	openUserWindow(server.windowDebug)
	openUserWindow(server.windowLists)
end


function importShop()
	local k, v

	if debug then dbug("Importing Shop") end

	for k,v in pairs(shop) do
		if v.prizeLimit == nil then -- fixes an oops that caused bad shop data to be saved
			conn:execute("INSERT INTO shop (item, category, price, stock, idx, maxStock, variation, special, validated, units, quality) VALUES ('" .. escape(k) .. "','" .. escape(v.category) .. "'," .. v.price .. "," .. v.stock .. "," .. v.idx .. "," .. v.maxStock .. "," .. v.variation .. "," .. v.special .. ",1," .. v.units .. "," .. v.quality .. ")")
		end
	end

	if debug then dbug("Shop Shop Imported") end
end


function importShopCategories()
	local k, v

	if debug then dbug("Importing Shop Categories") end

	for k,v in pairs(shopCategories) do
		conn:execute("INSERT INTO shopCategories (category, idx, code) VALUES ('" .. escape(k) .. "'," .. v.idx .. ",'" .. v.code .. "')")
	end

	if debug then dbug("Shop Categories Imported") end
end


function importPlayers()
	local k, v

	if debug then dbug("Importing Players") end

	for k,v in pairs(players) do
		if debug then dbug("Importing " .. k .. " " .. v.id .. " " .. v.name) end
		conn:execute("INSERT INTO players (steam, id, name) VALUES (" .. k .. "," .. v.id .. ",'" .. escape(v.name) .. "')")
		conn:execute("INSERT INTO persistentQueue (steam, command) VALUES (" .. k .. ",'update player')")
	end

	for k,v in pairs(playersArchived) do
		if debug then dbug("Importing archived " .. k .. " " .. v.id .. " " .. v.name) end
		conn:execute("INSERT INTO playersArchived (steam, id, name) VALUES (" .. k .. "," .. v.id .. ",'" .. escape(v.name) .. "')")
		conn:execute("INSERT INTO persistentQueue (steam, command) VALUES (" .. k .. ",'update archived player')")
	end

	if debug then dbug("Players Imported") end
end


function importTeleports()
	local k, v

	if debug then dbug("Importing Teleports") end

	for k,v in pairs(teleports) do
		conn:execute("INSERT INTO teleports (name, active, public, oneway, friends, x, y, z, dx, dy, dz, owner) VALUES ('" .. escape(v.name) .. "'," .. dbBool(v.active) .. "," .. dbBool(v.public) .. "," .. dbBool(v.oneway) .. "," .. dbBool(v.friends) .. "," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. v.dx .. "," .. v.dy .. "," .. v.owner .. ")")
	end
end


function importLocationCategories()
	local k, v

	if debug then dbug("Importing locationCategories") end

	for k,v in pairs(locationCategories) do
		conn:execute("INSERT INTO locationCategories (categoryName, minAccessLevel, maxAccessLevel) VALUES (" .. escape(k) .. "," .. v.minAccessLevel .. "," .. v.maxAccessLevel .. ")")
	end

	if debug then dbug("locationCategories Imported") end
end


function importLocations()
	local sql, fields, values, k, v

	if debug then dbug("Importing Locations") end

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

	if debug then dbug("Locations Imported") end
end


function importFriends()
	local friendlist, i, max, k, v

	if debug then dbug("Importing Friends") end

	for k,v in pairs(friends) do
		if debug then dbug("Importing friends of " .. k) end

		if v.friends then
			friendlist = string.split(v.friends, ",")

			max = table.maxn(friendlist)
			for i=1,max,1 do
				if friendlist[i] ~= "" then
					conn:execute("INSERT INTO friends (steam, friend) VALUES (" .. k .. "," .. friendlist[i] .. ")")
				end
			end
		end
	end

	if debug then dbug("Friends Imported") end
end


function importVillagers()
	local k, v

	if debug then dbug("Importing Villagers") end

	for k,v in pairs(villagers) do
		conn:execute("INSERT INTO villagers (steam, village) VALUES (" .. k .. ",'" .. escape(v.village) .. "')")
	end

	if debug then dbug("Villagers Imported") end
end


function importHotspots()
	local k, v

	if debug then dbug("Importing Hotspots") end

	for k,v in pairs(hotspots) do
		if v.radius then
			conn:execute("INSERT INTO hotspots (hotspot, x, y, z, owner, size) VALUES ('" .. escape(v.message) .. "'," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. v.owner .. "," .. v.radius .. ")")
		else
			conn:execute("INSERT INTO hotspots (hotspot, x, y, z, owner) VALUES ('" .. escape(v.message) .. "'," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. v.owner .. ")")
		end
	end

	if debug then dbug("Hotspots Imported") end
end


function importResets()
	local k, v, temp

	if debug then dbug("Importing Reset Zones") end

	for k,v in pairs(resetRegions) do
		temp = string.split(k, "%.")
		conn:execute("INSERT INTO resetZones (region, x, z) VALUES ('" .. escape(k) .. "'," .. temp[2] .. "," .. temp[3] .. ")")
	end

	if debug then dbug("Resets Imported") end
end


function importBaditems()
	local k, v

	if debug then dbug("Importing Bad Items") end

	for k,v in pairs(badItems) do
		conn:execute("INSERT INTO badItems (item, action) VALUES ('" .. escape(k) .. "','" .. escape(v.action) .. "')")
	end

	if debug then dbug("Bad Items Imported") end
end


function importDonors()
	local k, v

	if debug then dbug("Importing Donors") end

	for k,v in pairs(donors) do
		conn:execute("INSERT INTO donors (steam, level, expiry) VALUES (" .. k .. "," .. v.level .. "," .. v.expiry .. ")")
	end

	if debug then dbug("Donors Imported") end
end


function importRestricteditems()
	local k, v

	if debug then dbug("Importing Restricted Items") end

	for k,v in pairs(restrictedItems) do
		conn:execute("INSERT INTO restrictedItems (item, qty, accessLevel, action) VALUES ('" .. escape(k) .. "'," .. v.qty .. "," .. v.accessLevel .. ",'" .. escape(v.action) .. "')")
	end

	if debug then dbug("Bad Items Imported") end
end


function importWaypoints()
	local k, v

	if debug then dbug("Importing Waypoints") end

	for k,v in pairs(waypoints) do
		conn:execute("INSERT INTO waypoints (steam, name, x, y, z, linked, shared) VALUES (" .. v.steam .. ",'" .. escape(v.name) .. "'," .. v.x .. "," .. v.y .. "," .. v.z .. "," .. v.linked .. "," .. dbBool(v.shared) .. ")")
	end

	if debug then dbug("Waypoints Imported") end
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
	local k, v, id, temp, pos, importedAPlayer

	if debug then dbug("Importing Lua Tables") end

	importedAPlayer = false

	if not botman.silentDataImport then
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
	end

	if not path then
		path = homedir .. "/data_backup/"
	end

	if not pathPrefix then
		pathPrefix = ""
	end

	if not onlyImportThis then
		onlyImportThis = ""
	end

	if onlyImportThis == "" then
		if debug then dbug("Loading bad items") end
		badItems = {}
		table.load(path .. pathPrefix .. "badItems.lua", badItems)

		if debug then dbug("Loading friends") end
		friends = {}
		table.load(path .. pathPrefix .. "friends.lua", friends)

		if debug then dbug("Loading hotspots") end
		hotspots = {}
		table.load(path .. pathPrefix .. "hotspots.lua", hotspots)

		if debug then dbug("Loading locationCategories") end
		locationCategories = {}
		table.load(path .. pathPrefix .. "locationCategories.lua", locationCategories)

		if debug then dbug("Loading locations") end
		locations = {}
		table.load(path .. pathPrefix .. "locations.lua", locations)

		if debug then dbug("Loading players") end
		players = {}
		table.load(path .. pathPrefix .. "players.lua", players)

		if debug then dbug("Loading reset zones") end
		resetRegions = {}
		table.load(path .. pathPrefix .. "resetRegions.lua", resetRegions)

		if debug then dbug("Loading server") end
		table.load(path .. pathPrefix .. "server.lua", server)

		if debug then dbug("Loading shop categories") end
		shopCategories = {}
		table.load(path .. pathPrefix .. "shopCategories.lua", shopCategories)

		if debug then dbug("Loading shop") end
		shop = {}
		table.load(path .. pathPrefix .. "shop.lua", shop)

		if debug then dbug("Loading teleports") end
		teleports = {}
		table.load(path .. pathPrefix .. "teleports.lua", teleports)

		if debug then dbug("Loading villagers") end
		villagers = {}
		table.load(path .. pathPrefix .. "villagers.lua", villagers)

		if debug then dbug("Loading waypoints") end
		waypoints = {}
		table.load(path .. pathPrefix .. "waypoints.lua", waypoints)

		conn:execute("TRUNCATE badItems")
		conn:execute("TRUNCATE donors")
		conn:execute("TRUNCATE friends")
		conn:execute("TRUNCATE hotspots")
		conn:execute("TRUNCATE locations")
		conn:execute("TRUNCATE locationCategories")
		conn:execute("TRUNCATE players")
		conn:execute("TRUNCATE resetZones")
		conn:execute("TRUNCATE restrictedItems")
		conn:execute("TRUNCATE shopCategories")
		conn:execute("TRUNCATE shop")
		conn:execute("TRUNCATE teleports")
		conn:execute("TRUNCATE villagers")
		conn:execute("TRUNCATE waypoints")

		importBaditems()
		importDonors()
		importRestricteditems()
		importHotspots()
		importLocationCategories()
		importLocations()
		importResets()
		importTeleports()
		importVillagers()
		importFriends()
		importShopCategories()
		importShop()
		importWaypoints()
		importPlayers()
	else
		-- restore bases and cash for the players table
		playersTemp = {}
		table.load(path .. pathPrefix .. "players.lua", playersTemp)

		if string.find(onlyImportThis, " player ", nil, true) then
			pos = string.find(onlyImportThis, " player ") + 8
			temp = string.sub(onlyImportThis, pos)
			temp = string.trim(temp)
			id = LookupPlayer(temp)
		end

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

			if string.find(onlyImportThis, " player ", nil, true) then
				if k == id then
					players[k] = {}
					players[k] = playersTemp[k]
					conn:execute("INSERT INTO players (steam) VALUES (" .. k .. ")")
					conn:execute("INSERT INTO persistentQueue (steam, command) VALUES (" .. k .. ",'update player')")
					importedAPlayer = true
				end
			end
		end

		playersTemp = nil
	end

	if string.find(onlyImportThis, "friends") then
		if debug then dbug("Loading friends") end
		friends = {}
		table.load(path .. pathPrefix .. "friends.lua", friends)

		conn:execute("TRUNCATE friends")
		importFriends()
	end

	if string.find(onlyImportThis, "hotspots") then
		if debug then dbug("Loading hotspots") end
		hotspots = {}
		table.load(path .. pathPrefix .. "hotspots.lua", hotspots)

		conn:execute("TRUNCATE hotspots")
		importHotspots()
	end

	if string.find(onlyImportThis, "locations") then
		if debug then dbug("Loading locationCategories") end
		locationCategories = {}
		table.load(path .. pathPrefix .. "locationCategories.lua", locationCategories)

		if debug then dbug("Loading locations") end
		locations = {}
		table.load(path .. pathPrefix .. "locations.lua", locations)

		conn:execute("TRUNCATE locations")
		conn:execute("TRUNCATE locationCategories")
		importLocationCategories()
		importLocations()
	end

	if string.find(onlyImportThis, "players") then
		if debug then dbug("Loading players") end
		players = {}
		table.load(path .. pathPrefix .. "players.lua", players)

		conn:execute("TRUNCATE players")
		importPlayers()
	end

	if string.find(onlyImportThis, "resets") then
		if debug then dbug("Loading reset zones") end
		resetRegions = {}
		table.load(path .. pathPrefix .. "resetRegions.lua", resetRegions)

		conn:execute("TRUNCATE resetZones")
		importResets()
	end

	if string.find(onlyImportThis, "teleports") then
		if debug then dbug("Loading teleports") end
		teleports = {}
		table.load(path .. pathPrefix .. "teleports.lua", teleports)

		conn:execute("TRUNCATE teleports")
		importTeleports()
	end

	if string.find(onlyImportThis, "villagers") then
		if debug then dbug("Loading villagers") end
		villagers = {}
		table.load(path .. pathPrefix .. "villagers.lua", villagers)

		conn:execute("TRUNCATE villagers")
		importVillagers()
	end

	if string.find(onlyImportThis, "waypoints") then
		if debug then dbug("Loading waypoints") end
		waypoints = {}
		table.load(path .. pathPrefix .. "waypoints.lua", waypoints)

		conn:execute("TRUNCATE waypoints")
		importWaypoints()
	end

	if debug then dbug("Import of Lua tables Complete") end

	if not botman.silentDataImport then
		if importedAPlayer then
			irc_chat(server.ircMain, "Player " .. id .. " " .. players[id].name .. " has been restored from backup.")
			alertAdmins("Player " .. id .. " " .. players[id].name .. " has been restored from backup.")
		else
			if string.find(onlyImportThis, " player ", nil, true) then
				irc_chat(server.ircMain, "Nothing restored.  That player wasn't found.  Either the name is wrong or the player is archived.")
				alertAdmins("Nothing restored.  That player wasn't found.  Either the name is wrong or the player is archived.")
			else
				irc_chat(server.ircMain, "Bot restore complete. It is now safe to turn off your modem. xD")
				alertAdmins("Bot restore complete. It is now safe to turn off your modem. xD")
			end
		end
	end
end
