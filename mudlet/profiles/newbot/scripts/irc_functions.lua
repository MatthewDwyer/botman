--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- if you have oper status on your irc server, you can set channel modes.  This one sets flood protection to 5000 chars in 1 second which should prevent the bot from getting banned for flooding.
-- /mode #channel +f [5000t#b]:1

function irc_QueueMsg(name, msg)
	-- Don't allow the bot to command itself
	if name == server.botName then
		return
	end

	conn:execute("INSERT INTO ircQueue (name, command) VALUES ('" .. name .. "','" .. escape(msg) .. "')")
end


function irc_NewInventory(steam, trackerID)
	local tbl, slot, rows, i

	if trackerID ~= nil then
		cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .." AND inventoryTrackerID = " .. trackerID)
	else
		cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .." ORDER BY inventoryTrackerid DESC Limit 1")
	end

	row = cursor:fetch({}, "a")
	if row then
		irc_QueueMsg(irc_params[1], "")
		irc_QueueMsg(irc_params[1], "Belt of " .. irc_params[3])
		irc_QueueMsg(irc_params[1], "")

		tbl = string.split(row.belt, "|")
		for i=1, table.maxn(tbl) - 1, 1 do
			slot = string.split(tbl[i], ",")
			if tonumber(slot[4]) > 0 then
				irc_QueueMsg(irc_params[1], "Slot " .. slot[1] .. " qty " .. slot[2] .. " " .. slot[3] .. " " .. slot[4])
			else
				irc_QueueMsg(irc_params[1], "Slot " .. slot[1] .. " qty " .. slot[2] .. " " .. slot[3])
			end
		end

		irc_QueueMsg(irc_params[1], "")
		irc_QueueMsg(irc_params[1], "Backpack of " .. irc_params[3])
		irc_QueueMsg(irc_params[1], "")

		tbl = string.split(row.pack, "|")
		for i=1, table.maxn(tbl) - 1, 1 do
			slot = string.split(tbl[i], ",")
			if tonumber(slot[4]) > 0 then
				irc_QueueMsg(irc_params[1], "Slot " .. slot[1] .. " qty " .. slot[2] .. " " .. slot[3] .. " " .. slot[4])
			else
				irc_QueueMsg(irc_params[1], "Slot " .. slot[1] .. " qty " .. slot[2] .. " " .. slot[3])
			end
		end

		irc_QueueMsg(irc_params[1], "")
		irc_QueueMsg(irc_params[1], "Equipment of " .. irc_params[3])
		irc_QueueMsg(irc_params[1], "")

		tbl = string.split(row.equipment, "|")
		for i=1, table.maxn(tbl) - 1, 1 do
			slot = string.split(tbl[i], ",")
			irc_QueueMsg(irc_params[1], "Slot " .. slot[1] .. " qty " .. slot[2] .. " " .. slot[3])
		end
	else
		irc_QueueMsg(irc_params[1], "")
		irc_QueueMsg(irc_params[1], "I do not have an inventory recorded for " .. players[steam].name)
	end

	irc_QueueMsg(irc_params[1], "")
end


function irc_Request_Inventory()
	irc_NewInventory(irc_params[2])
end


function irc_message()
	irc_QueueMsg(irc_params[1], irc_params[2])
end


function irc_ListTables()
	irc_QueueMsg(irc_params[1], "These are the bot tables that you can view and edit:")
	irc_QueueMsg(irc_params[1], "server")
	irc_QueueMsg(irc_params[1], "rollingMessages")
	irc_QueueMsg(irc_params[1], "whitelist")
	irc_QueueMsg(irc_params[1], "")
end


function irc_List_Villages()
	local id

	irc_QueueMsg(irc_params[1], "List of villages on the server:")
	for k, v in pairs(locations) do
		if v.village == true then
			id = LookupOfflinePlayer(v.mayor)
			if id ~= nil then
				irc_QueueMsg(irc_params[1], v.name .. " the Mayor is " .. players[id].name)
			else
				irc_QueueMsg(irc_params[1], v.name)
			end
		end
	end

	irc_QueueMsg(irc_params[1], "")
end


function irc_List_Villagers()
	local text

	irc_QueueMsg(irc_params[1], "The following players are villagers:")
	for k, v in pairs(villagers) do
		text = v.village .. " " .. players[k].name

		if locations[v.village].mayor == k then
			text = text .. " (the mayor of " .. v.village .. ")"
		end

		irc_QueueMsg(irc_params[1], text)
	end

	irc_QueueMsg(irc_params[1], "")
end


function irc_ListBases(steam)
	local prot1
	local prot2
	local msg

	if steam ~= nil then
		cursor,errorString = conn:execute("SELECT steam, name, homeX, homeY, homeZ, home2X, home2Y, home2Z, protect, protect2, protectSize, protect2Size from players where steam = " .. steam .. " order by name")
	else
		cursor,errorString = conn:execute("SELECT steam, name, homeX, homeY, homeZ, home2X, home2Y, home2Z, protect, protect2, protectSize, protect2Size from players order by name")
	end

	row = cursor:fetch({}, "a")
	while row do
		prot1 = "OFF"
		prot2 = "OFF"

		if row.protect == true then prot1 = "ON" end
		if row.protect2 == true then prot2 = "ON" end
		msg = row.steam .. " " .. row.name .. " "

		if tonumber(row.homeX) == 0 and tonumber(row.homeY) == 0 and tonumber(row.homeZ) == 0 and tonumber(row.home2X) == 0 and tonumber(row.home2Y) == 0 and tonumber(row.home2Z) == 0 then
			if steam ~= nil then
				msg = msg .. "has no base set"
			else
				msg = nil
			end
		else
			msg = msg .. row.homeX .. " " .. row.homeY .. " " .. row.homeZ .. " " .. prot1 .. " (" .. row.protectSize .. ") "
			msg = msg .. row.home2X .. " " .. row.home2Y .. " " .. row.home2Z .. " " .. prot2 .. " (" .. row.protect2Size .. ") "
		end

		if irc_params[2] == "protected" and (row.protect == true or row.protect2 == true) then
			if msg ~= nil then
				irc_QueueMsg(irc_params[1], msg)
			end
		end

		if irc_params[2] ~= "protected" then	
			if msg ~= nil then
				irc_QueueMsg(irc_params[1], msg)
			end
		end

		row = cursor:fetch(row, "a")	
	end

	irc_QueueMsg(irc_params[1], "")
end


function irc_PlayersNearPlayer(name, name1, range, xPos, zPos, offline)
	local alone, dist, number, flag

	alone = true

	if offline == false then
		if name1 ~= "" then
			irc_QueueMsg(name, "Players within " .. range .. " meters of " .. players[name1].name .. " are:") 	
		else
			irc_QueueMsg(name, "Players within " .. range .. " meters of x " .. xPos .. " z " .. zPos .. " are:") 	
		end

		for k, v in pairs(igplayers) do
			if k ~= name1 then
				if name1 ~= "" then
					dist = distancexz(players[name1].xPos, players[name1].zPos, v.xPos, v.zPos)
				else
					dist = distancexz(xPos, zPos, v.xPos, v.zPos)
				end

				if dist <= range then
					irc_QueueMsg(name, v.name .. " distance: " .. string.format("%-4.2d", dist) .. " meters")
					alone = false
				end
			end
		end
	else
		if name1 ~= "" then
			irc_QueueMsg(name, "Players within " .. range .. " meters of " .. players[name1].name .. " including offline are:") 	
		else
			irc_QueueMsg(name, "Players within " .. range .. " meters of x " .. xPos .. " z " .. zPos .. " including offline are:") 	
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

					irc_QueueMsg(name, v.name .. " distance: " .. string.format("%-4.2d", dist) .. " meters" .. flag)
					alone = false
				end
			end
		end
	end

	if (alone == true) then
		if name1 ~= "" then
			irc_QueueMsg(name, "There is nobody within " .. range .. " meters of " .. players[name1].name)
		else
			irc_QueueMsg(name, "There is nobody within " .. range .. " meters of x " .. xPos .. " z " .. zPos)
		end
	end

	irc_QueueMsg(name, "")
end


function irc_BasesNearPlayer(name, name1, range, xPos, zPos)
	local alone, dist, protected

	alone = true

	irc_QueueMsg(name, "Bases within " .. range .. " meters of " .. players[name1].name .. " are:") 	

	for k, v in pairs(players) do
		if (v.homeX ~= 0 and v.homeZ ~= 0) then
			if name1 ~= "" then
				dist = distancexz(players[name1].xPos, players[name1].zPos, v.homeX, v.homeZ)
			else
				dist = distancexz(xPos, zPos, v.homeX, v.homeZ)			
			end

			if dist <= range then
				if players[k].protect == true then
					protected = " bot protected"
				else
					protected = " unprotected"
				end

				irc_QueueMsg(name, v.name .. " distance: " .. string.format("%-.2d", dist) .. " meters" .. protected)
				alone = false
			end
		end
		
		if (v.home2X ~= 0 and v.home2Z ~= 0) then
			if name1 ~= "" then		
				dist = distancexz(players[name1].xPos, players[name1].zPos, v.home2X, v.home2Z)
			else
				dist = distancexz(xPos, zPos, v.home2X, v.home2Z)			
			end

			if dist <= range then
				if players[k].protect2 == true then
					protected = " bot protected"
				else
					protected = " unprotected"
				end

				irc_QueueMsg(name, v.name .. " (base 2) distance: " .. string.format("%-.2d", dist) .. " meters" .. protected)
				alone = false
			end
		end		
	end

	if (alone == true) then
		irc_QueueMsg(name, "There are none within " .. range .. " meters of " .. players[name1].name)
	end

	irc_QueueMsg(name, "")
end


function irc_LocationsNearPlayer(name, name1, range, xPos, zPos)
	local alone, dist

	alone = true

	irc_QueueMsg(name, "Locations within " .. range .. " meters of " .. players[name1].name .. " are:") 	

	for k, v in pairs(locations) do
		if name1 ~= "" then
			dist = distancexz(players[name1].xPos, players[name1].zPos, v.x, v.z)
		else
			dist = distancexz(xPos, zPos, v.x, v.z)			
		end

		if dist <= range then
			irc_QueueMsg(name, v.name .. " distance: " .. string.format("%-.2d", dist) .. " meters")
			alone = false
		end
	end

	if (alone == true) then
		irc_QueueMsg(name, "There are none within " .. range .. " meters of " .. players[name1].name)
	end

	irc_QueueMsg(name, "")
end


function irc_PlayerShortInfo()
	local time
	local days
	local hours
	local minutes

	if (igplayers[irc_params[2]]) then
		time = tonumber(players[irc_params[2]].timeOnServer) + tonumber(igplayers[irc_params[2]].sessionPlaytime)
	else
		time = tonumber(players[irc_params[2]].timeOnServer)
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

	irc_QueueMsg(irc_params[1], "Info for player " .. irc_params[3])
	if players[irc_params[2]].newPlayer == true then irc_QueueMsg(irc_params[1], "A new player") end
	irc_QueueMsg(irc_params[1], "SteamID " .. players[irc_params[2]].steam)
	irc_QueueMsg(irc_params[1], "Steam Rep http://steamrep.com/search?q=" .. players[irc_params[2]].steam)
	irc_QueueMsg(irc_params[1], "Steam http://steamcommunity.com/profiles/" .. players[irc_params[2]].steam)
	irc_QueueMsg(irc_params[1], "Player ID " .. players[irc_params[2]].id)
	if players[irc_params[2]].firstSeen ~= nil then irc_QueueMsg(irc_params[1], "First seen: " .. os.date("%Y-%m-%d %H:%M:%S", players[irc_params[2]].firstSeen) ) end
	irc_QueueMsg(irc_params[1], seen(irc_params[2]))
	irc_QueueMsg(irc_params[1], "Total time played: " .. days .. " days " .. hours .. " hours " .. minutes .. " minutes " .. time .. " seconds")
	if players[irc_params[2]].names ~= nil then irc_QueueMsg(irc_params[1], "Has played as " .. players[irc_params[2]].names) end
	if players[irc_params[2]].timeout == true then irc_QueueMsg(irc_params[1], "Is in timeout") end
	if players[irc_params[2]].prisoner then 
		irc_QueueMsg(irc_params[1], "Is a prisoner") 
		if players[irc_params[2]].prisonReason ~= nil then irc_QueueMsg(irc_params[1], "Reason Arrested: " .. players[irc_params[2]].prisonReason) end
	end
	irc_QueueMsg(irc_params[1], "Keystones placed " .. players[irc_params[2]].keystones)
	irc_QueueMsg(irc_params[1], "Zombies " .. players[irc_params[2]].zombies)
	irc_QueueMsg(irc_params[1], "Score " .. players[irc_params[2]].score)
	irc_QueueMsg(irc_params[1], "Deaths " .. players[irc_params[2]].deaths)
	irc_QueueMsg(irc_params[1], "Current Session " .. players[irc_params[2]].sessionCount)
	irc_QueueMsg(irc_params[1], "IP http://who.is/whois-ip/ip-address/" .. players[irc_params[2]].IP)
	irc_QueueMsg(irc_params[1], "Ping " .. players[irc_params[2]].ping .. " Country: " .. players[irc_params[2]].country)

	if players[irc_params[2]].china then
		irc_QueueMsg(irc_params[1], "China IP detected")
	end

	if players[irc_params[2]].exiled == 1 then
		irc_QueueMsg(irc_params[1], "Is exiled")
	else
		irc_QueueMsg(irc_params[1], "Not exiled")
	end

	if players[irc_params[2]].inLocation ~= "" then
		irc_QueueMsg(irc_params[1], "In location " .. players[irc_params[2]].inLocation)
	else
		irc_QueueMsg(irc_params[1], "Not in a named location")
	end

	irc_QueueMsg(irc_params[1], "Current position " .. math.floor(players[irc_params[2]].xPos) .. " " .. math.ceil(players[irc_params[2]].yPos) .. " " .. math.floor(players[irc_params[2]].zPos))

	if players[irc_params[2]].donor then
		irc_QueueMsg(irc_params[1], "Is a donor")
	else
		irc_QueueMsg(irc_params[1], "Not a donor")
	end

	cursor,errorString = conn:execute("SELECT * FROM bans WHERE steam =  " .. irc_params[2])
	if cursor:numrows() > 0 then
		row = cursor:fetch({}, "a")
		irc_QueueMsg(irc_params[1], "BANNED until " .. row.BannedTo .. " " .. row.Reason)
	end

	irc_QueueMsg(irc_params[1], "")
end


function irc_List_Owners()
	irc_QueueMsg(irc_params[1], "The server owners are..")
	for k, v in pairs(owners) do
		irc_QueueMsg(irc_params[1], players[k].name)
	end

	irc_QueueMsg(irc_params[1], "")
end


function irc_List_Admins()
	irc_QueueMsg(irc_params[1], "The server admins are..")
	for k, v in pairs(admins) do
		irc_QueueMsg(irc_params[1], players[k].name)
	end

	irc_QueueMsg(irc_params[1], "")
end


function irc_List_Mods()
	irc_QueueMsg(irc_params[1], "The server mods are..")
	for k, v in pairs(mods) do
		irc_QueueMsg(irc_params[1], players[k].name)
	end

	irc_QueueMsg(irc_params[1], "")
end


function irc_friend()
	-- add to friends table
	if (friends[irc_params[2]] == nil) then
		friends[irc_params[2]] = {}
		friends[irc_params[2]].friends = ""
	end

	if (not string.find(friends[irc_params[2]].friends, irc_params[3])) then
		friends[irc_params[2]].friends = friends[irc_params[2]].friends .. irc_params[3] .. ","
		irc_QueueMsg(irc_params[1], players[irc_params[2]].name .. " is now friends with " .. players[irc_params[3]].name) 
	else
		irc_QueueMsg(irc_params[1], players[irc_params[2]].name .. " is already friends with " .. players[irc_params[3]].name) 
	end

	conn:execute("INSERT INTO friends (steam, friend) VALUES (" .. irc_params[3] .. "," .. irc_params[2] .. ")")

	irc_QueueMsg(irc_params[1], "")
end


function irc_unfriend()
	local friendlist

	-- add to friends table
	if (friends[irc_params[2]] == nil) then
		friends[irc_params[2]] = {}
		friends[irc_params[2]].friends = ""
	end

	friendlist = string.split(friends[irc_params[2]].friends, ",")

	-- now simply rebuild friend skipping over the one we are removing
	friends[irc_params[2]].friends = ""
	for i=1,table.maxn(friendlist) - 1,1 do
		if (friendlist[i] ~= irc_params[3]) then
			friends[irc_params[2]].friends = friends[irc_params[2]].friends .. friendlist[i] .. ","
		end
	end
	
	irc_QueueMsg(irc_params[1], players[irc_params[2]].name .. " is no longer friends with " .. players[irc_params[3]].name) 

	conn:execute("DELETE FROM friends WHERE steam = " .. irc_params[3] .. " AND friend = " .. irc_params[2])	

	irc_QueueMsg(irc_params[1], "")
end


function irc_friends()
	local friendlist

	friendlist = string.split(friends[irc_params[2]].friends, ",")

	irc_QueueMsg(irc_params[1], irc_params[3] .. " is friends with..")
	for i=1,table.maxn(friendlist)-1,1 do
		if (friendlist[i] ~= "") then
			id = LookupPlayer(friendlist[i])
			irc_QueueMsg(irc_params[1], players[id].name)
		end
	end	

	irc_QueueMsg(irc_params[1], "")
end


function irc_new_players(name)
	local id
	local x
	local z

	id = LookupOfflinePlayer(name, "all")

	irc_QueueMsg(name, "New players in the last 2 days:")

	for k, v in pairs(players) do
		if v.firstSeen ~= nil then
			if ((os.time() - tonumber(v.firstSeen)) < 86401) then
				if accessLevel(id) > 3 then
					irc_QueueMsg(name, v.name) 
				else
					irc_QueueMsg(name, "steam: " .. k .. " id: " .. string.format("%8d", v.id) .. " name: " .. v.name .. " at " .. math.floor(v.xPos) .. " " .. math.ceil(v.yPos) .. " " .. math.floor(v.zPos))
				end					
			end
		end
	end
	
	irc_QueueMsg(name, "")
end


function irc_server_status(name, days)
	irc_QueueMsg(name, "The server date is " .. serverTime)

	if days == nil then
		irc_QueueMsg(name, "24 hour stats to now:")
		days = 1
	else
		irc_QueueMsg(name, "Last " .. days .. " days stats to now:")
	end

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%pvp%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_QueueMsg(name, "PVPs: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%timeout%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_QueueMsg(name, "Timeouts: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%arrest%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_QueueMsg(name, "Arrests: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%new%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_QueueMsg(name, "New players: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%ban%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_QueueMsg(name, "Bans: " .. row.number)

	cursor,errorString = conn:execute("SELECT MAX(players) as number FROM performance WHERE timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_QueueMsg(name, "Most players online: " .. row.number)
	irc_QueueMsg(name, "")
end


function irc_server_event(name, event, steam, days)
	if days == 0 then
		irc_QueueMsg(name, event .. "s in the last 24 hours:")
		days = 1
	else
		irc_QueueMsg(name, event .. "s in the last " .. days .. " days:")
	end

	if steam == 0 then
		cursor,errorString = conn:execute("SELECT * FROM events WHERE type LIKE '%" .. event .. "%' or event LIKE '%" .. event .. "%' AND timestamp >= DATE_SUB(now(), INTERVAL ".. days .. " DAY)")	
	else
		cursor,errorString = conn:execute("SELECT * FROM events WHERE steam = " .. steam .. " AND type LIKE '%" .. event .. "%' or event LIKE '%" .. event .. "%' AND timestamp >= DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	end

	row = cursor:fetch({}, "a")
	while row do
		irc_QueueMsg(name, row.serverTime .. " " .. row.event .. " at " .. row.x .. " " .. row.y .. " " .. row.z)
		row = cursor:fetch(row, "a")
	end

	irc_QueueMsg(name, "")
end


function irc_players(name)
	local id
	local x
	local z
	local flags

	id = LookupPlayer(name, "all")

	irc_QueueMsg(name, "The following users are in-game right now:")

	for k, v in pairs(igplayers) do
		x = math.floor(v.xPos / 512)
		z = math.floor(v.zPos / 512)

		flags = " "
		if players[k].newPlayer == true then flags = flags .. "[NEW]" end
		if players[k].timeout == true then flags = flags .. "[TIMEOUT]" end

		if (accessLevel(id) > 3) then
			irc_QueueMsg(name, v.name .. " score: " .. string.format("%-6d", v.score) .. " PVP: " .. string.format("%-2d", v.playerKills) .. " zeds: " .. string.format("%-6d", v.zombies) .. " " .. flags)
		else
			if players[id].ircAuthenticated == true then
				irc_QueueMsg(name, "steam: " .. k .. " id: " .. string.format("%-7d", v.id) .. " score: " .. string.format("%-6d", v.score) .. " PVP: " .. string.format("%-2d", v.playerKills) .. " zeds: " .. string.format("%-6d", v.zombies) .. " region r." .. x .. "." .. z .. ".7rg   name: " .. v.name  .. flags .. " [ " .. math.floor(v.xPos) .. " " .. math.ceil(v.yPos) .. " " .. math.floor(v.zPos) .. " ] " .. players[k].country .. " " .. v.ping)
			else
				irc_QueueMsg(name, v.name .. " score: " .. string.format("%-6d", v.score) .. " PVP: " .. string.format("%-2d", v.playerKills) .. " zeds: " .. string.format("%-6d", v.zombies) .. " " .. flags)
			end
		end
	end

	irc_QueueMsg(irc_params[1], "There are " .. playersOnline .. " players online.")
	irc_QueueMsg(name, "")
end


function irc_listResetZones(name)
   local a = {}
	local n
	local sid
	local pid

	irc_QueueMsg(name, "The following regions are designated reset zones:")

   for n in pairs(resetRegions) do
		table.insert(a, n)
	end  

	table.sort(a)

   for k, v in ipairs(a) do
		irc_QueueMsg(name, "region: " .. v)
	end

	irc_QueueMsg(name, "")
end


function irc_gameTime(name)
	irc_QueueMsg(name, "The game date is: " .. gameDate)
end


function irc_uptime(name)
	diff = os.difftime(os.time(), botStarted)
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (hours > 0) then
		diff = diff - (hours * 3600)
	end

	minutes = math.floor(diff / 60)

	irc_QueueMsg(name, server.botName .. " has been online " .. days .. " days " .. hours .. " hours " .. minutes .." minutes")

	if gameTick < 0 then
		irc_QueueMsg(name, "Server uptime is uncertain")
	else
		diff = gameTick
		--diff = os.difftime(os.time(), serverStarted)
		days = math.floor(diff / 86400)

		if (days > 0) then
			diff = diff - (days * 86400)
		end

		hours = math.floor(diff / 3600)

		if (hours > 0) then
			diff = diff - (hours * 3600)
		end

		minutes = math.floor(diff / 60)

		irc_QueueMsg(name, "Server uptime is " .. days .. " days " .. hours .. " hours " .. minutes .." minutes")
	end
	
	irc_QueueMsg(name, "")
end


function irc_listAllPlayers(name)
    local a = {}
	local n
	local sid
	local pid

	irc_QueueMsg(name, "These are all the players on record:")

    for n in pairs(players) do
		table.insert(a, players[n].name)
	end  

	table.sort(a)

    for k, v in ipairs(a) do
		sid = LookupOfflinePlayer(v, "all")
		pid = players[sid].id

		cmd = "steam: " .. sid .. " id: " .. string.format("%-8d", pid) .. " name: " .. v
		irc_QueueMsg(irc_params[1], cmd)
	end

	irc_QueueMsg(name, "")
end


function irc_IGPlayerInfo()
	if (players[irc_params[2]] ~= nil) then
		irc_QueueMsg(irc_params[1], "In-Game Player record of: " .. players[irc_params[2]].name)
		for k, v in pairs(igplayers[irc_params[2]]) do
			if k ~= "inventory" and k ~= "inventoryLast" then
				cmd = k .. "," .. tostring(v)
				irc_QueueMsg(irc_params[1], cmd)
			end
		end
	else
		irc_QueueMsg(irc_params[1], "")
		irc_QueueMsg(irc_params[1], "I do not know a player called " .. irc_params[3])
	end
	
	irc_QueueMsg(irc_params[1], "")
end


function irc_PlayerInfo()
	if (players[irc_params[2]] ~= nil) then
		irc_QueueMsg(irc_params[1], "Player record of: " .. players[irc_params[2]].name)
		for k, v in pairs(players[irc_params[2]]) do
			if k ~= "ircPass" then
				cmd = k .. "," .. tostring(v)
				irc_QueueMsg(irc_params[1], cmd)
			end
		end
	else
		irc_QueueMsg(irc_params[1], "")
		irc_QueueMsg(irc_params[1], "I do not know a player called " .. irc_params[3])
	end
	
	irc_QueueMsg(irc_params[1], "")	
end


function irc_ShowTable()
	irc_QueueMsg(irc_params[1], "The " .. irc_params[2] .." table: ")

	if string.lower(irc_params[2]) == "server" then
		for k, v in pairs(server) do
			cmd = k .. "," .. tostring(v)
			irc_QueueMsg(irc_params[1], cmd)
		end
	
		irc_QueueMsg(irc_params[1], "")	
	end
end


function irc_listDonors(name)
   local a = {}
	local n
	local sid
	local pid

	irc_QueueMsg(name, "These are all the donors on record:")

   for n in pairs(players) do
		if (players[n].donor == true) then
			table.insert(a, players[n].name)
		end
	end  

	table.sort(a)

   for k, v in ipairs(a) do
		sid = LookupOfflinePlayer(v, "all")
		pid = players[sid].id

		irc_QueueMsg(name, "steam: " .. sid .. " id: " .. string.format("%-8d", pid) .. " name: " .. v)
	end

	irc_QueueMsg(name, "")
end


function irc_uncraftables(name)
	irc_QueueMsg(name, "I scan for these uncraftable items in inventories:")

	for k, v in pairs(badItems) do
		irc_QueueMsg(name, k)
	end

	irc_QueueMsg(name, "")
end


function irc_restricted(name)
	irc_QueueMsg(name, "I scan for these restricted items in inventories:")

	for k, v in pairs(restrictedItems) do
		irc_QueueMsg(name, k)
	end

	irc_QueueMsg(name, "")
end


function irc_teleports(name)
	irc_QueueMsg(name, "List of teleports:")

	for k, v in pairs(teleports) do
		if (v.public == true) then
			public = "public"
		else
			public = "private"
		end

		irc_QueueMsg(name, v.name .. " " .. public)
	end

	irc_QueueMsg(name, "")
end


function irc_locations(name)
	local id

	id = LookupOfflinePlayer(name, "all")

	irc_QueueMsg(name, "List of locations:")

	for k, v in pairs(locations) do
		if (v.public == true) then
			public = "public"
		else
			public = "private"
		end

		if (v.active == true) then
			active = "enabled"
		else
			active = "disabled"
		end

		if not admins[id] and public == "private" then
			irc_QueueMsg(name, v.name .. " " .. public .. " " .. active .. " xyz " .. v.x .. "," .. v.y .. "," .. v.z)
		else
			irc_QueueMsg(name, v.name .. " " .. public .. " " .. active .. " xyz " .. v.x .. "," .. v.y .. "," .. v.z)
		end
	end

	irc_QueueMsg(name, "")
end


function irc_prisoners(name)
	irc_QueueMsg(name, "List of prisoners:")

	-- pm a list of all the prisoners
	if (prisoners == {}) then
		irc_QueueMsg(name, v.name .. "Nobody is in prison")
		return
	end

	for k, v in pairs(prisoners) do
		irc_QueueMsg(name, k .. " " .. players[k].name)
	end

	irc_QueueMsg(name, "")
end


function irc_playerStatus()
	local protected
	local base

	if (players[irc_params[2]].protect == true) then
		protected = "protected"
	else
		protected = "not protected (unless you have LCB's down)"
	end
	
	if (players[irc_params[2]].homeX == 0 and players[irc_params[2]].homeY == 0 and players[irc_params[2]].homeZ == 0) then
		base = "Has not done /setbase"	
	else
		base = "Has set a base"
	end
	irc_QueueMsg(irc_params[1], irc_params[3] .. " has " .. players[irc_params[2]].cash .. " zennies")

	irc_QueueMsg(irc_params[1], "Base status for " .. irc_params[3] .. " is..")
	irc_QueueMsg(irc_params[1], base)
	irc_QueueMsg(irc_params[1], "The base is " .. protected)
	irc_QueueMsg(irc_params[1], "Protection size is " .. players[irc_params[2]].protectSize .. " meters")

	if (players[irc_params[2]].protectPaused ~= nil) then
		irc_QueueMsg(irc_params[1], "Protection is paused")
	end


	if (players[irc_params[2]].protect2 == true) then
		protected = "protected"
	else
		protected = "not protected (unless you have LCB's down)"
	end
	
	if (players[irc_params[2]].home2X == 0 and players[irc_params[2]].home2Y == 0 and players[irc_params[2]].home2Z == 0) then
		base = "Has not done /setbase"	
	else
		base = "Has set a base"
	end

	irc_QueueMsg(irc_params[1], "Second Base status for " .. irc_params[3] .. " is..")
	irc_QueueMsg(irc_params[1], base)
	irc_QueueMsg(irc_params[1], "Base2 is " .. protected)
	irc_QueueMsg(irc_params[1], "Protection size is " .. players[irc_params[2]].protect2Size .. " meters")

	if (players[irc_params[2]].protect2Paused ~= nil) then
		irc_QueueMsg(irc_params[1], "Protection is paused")
	end

	irc_QueueMsg(irc_params[1], "")
end
