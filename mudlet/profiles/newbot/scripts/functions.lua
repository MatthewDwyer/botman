--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function downloadHandler(event, ...)
   if event == "sysDownloadDone" then
      finishDownload(...)
   elseif event == "sysDownloadError" then
	   failDownload(...)
	end
end


function finishDownload(filePath)
	if string.find(filePath, "BotScriptsCRCList.txt") then
	
	end
end


function failDownload(filePath)

end


function dbug(text)
	-- send text to the debug window we created in Mudlet.
	if server == nil then
		display(text .. "\n")
		return	
	end
		
	if server.windowLists then
		cecho(server.windowLists, text .. "\n")
	end
end


function isReservedName(player, steam)
	local k, v, pos

	-- strip any trailing (1) or other numbers in brackets
	if string.find(player, "%(%d+%)$") then
		player = string.sub(player, 1, string.find(player, "%(%d+%)$") - 1)
	end

	for k,v in pairs(players) do
		if (v.name == player) and (k ~= steam) then
			if tonumber(v.accessLevel) < 3 then
				return true
			end

			if tonumber(v.accessLevel) ~= tonumber(accessLevel(steam)) and igplayer[k] then
				return true
			end
		end
	end

	return false
end


function stripQuotes(name)
	local oldName
	oldName = name

	name = string.match(name, "^'(.*)'$")
	
	if name == oldName then
		name = string.match(name, "^\"(.*)\"$")
	end
	
	if name == nil then name = oldName end
	
	if string.sub(name, string.len(name)) == "'" then
		name = string.sub(name, 1, string.len(name) - 1)
	end
	
	return name
end


function inWhitelist(steam)
	-- is the player in the whitelist?
	cursor,errorString = conn:execute("SELECT * FROM whitelist WHERE steam = " .. steam)
	row = cursor:fetch({}, "a")

	if row then
		return true
	else
		return false
	end
end


function getWhitelistedServers()
	whitelistedServers = {}
	whitelistedServers[server.IP] = {}
	whitelistedServers[server.botsIP] = {}	

	cursor,errorString = connBots:execute("select IP from servers")
	row = cursor:fetch({}, "a")

	while row do
		whitelistedServers[row.IP] = {}	
		row = cursor:fetch(row, "a")	
	end
end


function atHome(steam)
	local dist, size, greet, home, time

	greet = false
	home = false

	if players[steam].lastAtHome == nil then
		players[steam].lastAtHome = os.time()
	end

	-- base 1
	if math.abs(players[steam].homeX) > 0 and math.abs(players[steam].homeZ) > 0 then
		dist = distancexz(math.floor(players[steam].xPos), math.floor(players[steam].zPos), players[steam].homeX, players[steam].homeZ)
		size = tonumber(players[steam].protectSize)

		if (dist <= size) then
			home = true

			if not players[steam].atHome then
				greet = true
			end
		end
	end

	-- base 2
	if math.abs(players[steam].home2X) > 0 and math.abs(players[steam].home2Z) > 0 then
		dist = distancexz(math.floor(players[steam].xPos), math.floor(players[steam].zPos), players[steam].home2X, players[steam].home2Z)
		size = tonumber(players[steam].protect2Size)

		if (dist <= size) then
			home = true

			if not players[steam].atHome then
				greet = true
			end
		end
	end

	if greet then
		time = os.time() - players[steam].lastAtHome

		if time > 300 and time <= 900 then
			r = rand(5)
			if r == 1 then message("pm " .. steam .. " [" .. server.chatColour .. "]Welcome home " .. players[steam].name .. "[-]") end
			if r == 2 then message("pm " .. steam .. " [" .. server.chatColour .. "]Back so soon " .. players[steam].name .. "?[-]") end
			if r == 3 then message("pm " .. steam .. " [" .. server.chatColour .. "]You're back![-]") end
			if r == 4 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home sweet home :)[-]") end
			if r == 5 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home again[-]") end
		end

		if time > 900 and time <= 1800 then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You're back " .. players[steam].name .. "! Welcome home :)[-]")
		end

		if time > 1800 and time <= 3600 then
			r = rand(5)
			if r == 1 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home at last " .. players[steam].name .. "![-]") end
			if r == 2 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home again, home again. Ziggity zig.[-]") end
			if r == 3 then message("pm " .. steam .. " [" .. server.chatColour .. "]Look what the cat dragged in.  Hello " .. players[steam].name .. "[-]") end
			if r == 4 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home at last " .. players[steam].name .. "![-]") end
			if r == 5 then message("pm " .. steam .. " [" .. server.chatColour .. "]You're back! So nice of you to drop by.[-]") end
		end

		if time > 3600 then
			message("pm " .. steam .. " [" .. server.chatColour .. "]So you decided to come home " .. players[steam].name .. "?[-]")
			message("pm " .. steam .. " [" .. server.chatColour .. "]Dinner's on the floor.[-]")
			r = rand(5)
			if r == 1 then send("give " .. steam .. " canDogfood 1") end
			if r == 2 then send("give " .. steam .. " canCatfood 1") end
			if r == 3 then send("give " .. steam .. " femur 1") end
			if r == 4 then send("give " .. steam .. " vegetableStew 1") end
			if r == 5 then send("give " .. steam .. " meatStew 1") end
		end
	end

	if home then
		players[steam].atHome = true
		players[steam].lastAtHome = os.time()
	else
		players[steam].atHome = false
	end
end


function reserveSlot(steam)
	dbug("Reserving slot for " .. steam)
	send("sg ServerMaxPlayerCount " .. server.ServerMaxPlayerCount + 1)
	reservedSlots[steam] = steam
	tempTimer( 60, [[removeReservedSlot("]] .. steam .. [[")]] )
end


function removeReservedSlot(steam)
	if reservedSlots[steam] then
		dbug("Removing reserved slot for " .. steam)
		reservedSlots[steam] = nil
		send("sg ServerMaxPlayerCount " .. server.ServerMaxPlayerCount - 1)
	end
end


function calcTimestamp(str)
	-- takes input like 1 week, 1 month, 1 year and outputs a timestamp that much in the future
	local number, period

	str = string.lower(str)
	number = math.abs(math.floor(tonumber(string.match(str, "(-?%d+)"))))

	if string.find(str, "day") then
		period = 60 * 60 * 24
	end

	if string.find(str, "week") then
		period = 60 * 60 * 24 * 7
	end

	if string.find(str, "month") then
		period = 60 * 60 * 24 * 30
	end

	if string.find(str, "year") then
		period = 60 * 60 * 24 * 365
	end

	if number == nil or period == nil then 
		return os.time()
	else
		return os.time() + period * number
	end
end


function countAlphaNumeric(test)
	-- return the number of alphanumeric characters in test

	local _, count = string.gsub(test, "%w", "")
	return count
end


function isFile(name)
    if type(name)~="string" then return false end
    if not isDir(name) then
        return os.rename(name,name) and true or false
        -- note that the short evaluation is to
        -- return false instead of a possible nil
    end
    return false
end


function isFileOrDir(name)
    if type(name)~="string" then return false end
    return os.rename(name, name) and true or false
end


function isDir(name)
    if type(name)~="string" then return false end
    local cd = lfs.currentdir()
    local is = lfs.chdir(name) and true or false
    lfs.chdir(cd)
    return is
end


function pmsg(msg, all)
	-- queue msg for output by a timer
	for k,v in pairs(igplayers) do
		if all ~= nil or players[k].noSpam == false then
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. k .. ",'" .. escape(msg) .. ")")
		end
	end
end


function strDateToTimestamp(strdate)
	-- Unix timestamps end in 2038.  To prevent invalid dates, we will force year to 2030 if it is later.
	local sday, smonth, syear, shour, sminute, sseconds = strdate:match("(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)")

	-- don't allow dates over 2030.  timestamps stop at 2038
	if tonumber(syear) > 2030 then syear = 2030 end

	return os.time({year = syear, month = smonth, day = sday, hour = shour, min = sminute, sec = sseconds})
end


function getEquipment(equipment, item)
	-- search the most recent inventory recording for an item and if found return how much there is and best quality if applicable
	local tbl, test, i, found, quantity, quality

	found = false
	quality = 0
	quantity = 0
	tbl = string.split(equipment, "|")

	for i=1, table.maxn(tbl) - 1, 1 do
		test = string.split(tbl[i], ",")

		if test[2] == item then
			found = true

			if tonumber(test[3]) > tonumber(quality) then
				quality = tonumber(test[3])
			end
		end
	end

	if found then
		return true, quality
	else
		return false, 0
	end
end


function getInventory(inventory, item)
	-- search the most recent inventory recording for an item and if found return how much there is and best quality if applicable
	local tbl, test, i, found, quantity, quality

	found = false
	quality = 0
	quantity = 0
	tbl = string.split(inventory, "|")

	for i=1, table.maxn(tbl) - 1, 1 do
		test = string.split(tbl[i], ",")
		if test[3] == item then
			found = true
			quantity = quantity + tonumber(test[2])

			if tonumber(test[4]) > tonumber(quality) then
				quality = tonumber(test[4])
			end
		end
	end

	if found then
		return true, quantity, quality
	else
		return false, 0 , 0
	end
end


function inInventory(steam, item, quantity, slot)
	-- search the most recent inventory recording for an item
	local tbl, test, i

	cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .."  ORDER BY inventoryTrackerID DESC Limit 0, 1")
	row = cursor:fetch({}, "a")

	tbl = string.split(row.belt .. row.pack .. row.equipment, "|")

	for i=1, table.maxn(tbl) - 1, 1 do
		test = string.split(tbl[i], ",")
		if slot ~= nil then
			if tonumber(test[2]) >= tonumber(quantity) and test[3] == item and tonumber(test[1]) == slot then
				return true
			end
		else
			if tonumber(test[2]) >= tonumber(quantity) and test[3] == item then
				return true
			end
		end
	end

	return false
end


function inBelt(steam, item, quantity, slot)
	-- search the most recent inventory recording for an item in the belt
	local tbl, test, i

	cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .."  ORDER BY inventoryTrackerID DESC Limit 0, 1")
	row = cursor:fetch({}, "a")

	tbl = string.split(row.belt, "|")

	for i=1, table.maxn(tbl) - 1, 1 do
		test = string.split(tbl[i], ",")
		if slot ~= nil then
			if tonumber(test[2]) >= tonumber(quantity) and test[3] == item and tonumber(test[1]) == slot then
				return true
			end
		else
			if tonumber(test[2]) >= tonumber(quantity) and test[3] == item then
				return true
			end
		end
	end

	return false
end


function mapPosition(steam)
	-- express the player's coordinates as a compass bearing
	local ns, ew

	if tonumber(players[steam].xPos) < 0 then
		ew = math.abs(math.floor(players[steam].xPos)).. " W"
	else
		ew = math.floor(players[steam].xPos) .. " E"
	end

	if tonumber(players[steam].zPos) < 0 then
		ns = math.abs(math.floor(players[steam].zPos)) .. " S"
	else
		ns = math.floor(players[steam].zPos) .. " N"
	end

	return ns .. " " .. ew
end


function validPosition(steam, alert)
	-- check that y position is between bedrock and the max build height
	if tonumber(players[steam].yPos) > -1 and tonumber(players[steam].yPos) < 256 then
		return true
	else
		if alert ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You cannot do that here. If you recently teleported, wait a bit then try again.[-]")
		end

		return false
	end
end


function savePosition(steam, temp)
	-- helper function to save the players position
	if tonumber(players[steam].yPos) > -1 and tonumber(players[steam].yPos) < 256 then
		-- store the player's current x y z
		if temp == nil then
			players[steam].xPosOld = math.floor(players[steam].xPos)
			players[steam].yPosOld = math.ceil(players[steam].yPos)
			players[steam].zPosOld = math.floor(players[steam].zPos)

			conn:execute("UPDATE players SET xPosOld = " .. players[steam].xPosOld .. ", yPosOld = " .. players[steam].yPosOld .. ", zPosOld = " .. players[steam].zPosOld .. " WHERE steam = " .. steam)
		else
			players[steam].xPosOld2 = math.floor(players[steam].xPos)
			players[steam].yPosOld2 = math.ceil(players[steam].yPos)
			players[steam].zPosOld2 = math.floor(players[steam].zPos)

			conn:execute("UPDATE players SET xPosOld2 = " .. players[steam].xPosOld2 .. ", yPosOld2 = " .. players[steam].yPosOld2 .. ", zPosOld2 = " .. players[steam].zPosOld2 .. " WHERE steam = " .. steam)
		end
	end
end


function seen(steam)
	-- when was a player last seen ingame?
	local words, word, diff, ryear, rmonth, rday, rhour, rmin, rsec
	local dateNow, Now, dateSeen, Seen, days, hours, minutes

	if players[steam].seen == "" then
		return "A new player on for the first time now."
	end

	words = {}
	for word in serverTime:gmatch("%w+") do table.insert(words, word) end

	ryear = words[1]
	rmonth = words[2]
	rday = string.sub(words[3], 1, 2)
	rhour = string.sub(words[3], 4, 5)
	rmin = words[4]
	rsec = words[5]

	dateNow = {year=ryear, month=rmonth, day=rday, hour=rhour, min=rmin, sec=rsec}
	Now = os.time(dateNow)

	words = {}
	for word in players[steam].seen:gmatch("%w+") do table.insert(words, word) end

	ryear = words[1]
	rmonth = words[2]
	rday = string.sub(words[3], 1, 2)
	rhour = string.sub(words[3], 4, 5)
	rmin = words[4]
	rsec = words[5]

	dateSeen = {year=ryear, month=rmonth, day=rday, hour=rhour, min=rmin, sec=rsec}
	Seen = os.time(dateSeen)

	diff = os.difftime(Now, Seen)
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (hours > 0) then
		diff = diff - (hours * 3600)
	end

	minutes = math.floor(diff / 60)

	return players[steam].name .. " was last seen " .. days .. " days " .. hours .. " hours " .. minutes .." minutes ago"
end


function LookupHotspot(x,y,z)
	-- return the closest hotspot that these coords are inside
	local size, k, v

	for k, v in pairs(hotspots) do
		if (v.radius ~= nil) then 
			size = v.radius 
		else
			size = 3 
		end

		if distancexyz(x, y, z, v.x, v.y, v.z) <= tonumber(size) then
			return k
		end
	end
end


function messageAdmins(message)
	-- helper function to send a message to all staff
	local k,v

	for k, v in pairs(players) do
		if (accessLevel(k) < 3) then
			if igplayers[k] then
				message("pm " .. k .. " [" .. server.chatColour .. "]" .. message .. "[-]")
			else
				conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. k .. ", '" .. escape(message) .. "')")
			end
		end
	end
end


function kick(steam, reason)
	local tmp

	tmp = steam
	-- if there is no player with steamid steam, try looking it up incase we got their name instead of their steam
	if not players[steam] then
		steam = LookupPlayer(string.trim(steam))
		-- restore the original steam value if nothing matched as we may be banning someone who's never played here.
		if steam == nil then steam = tmp end
	end

	if igplayers[steam] then
		conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. serverTime .. "','kick','Player " .. steam .. " " .. escape(players[steam].name) .. " kicked for " .. escape(reason) .. "'," .. steam .. ")")
	end

	send("kick " .. steam .. " " .. " \"" .. reason .. "\"")
end


function banPlayer(steam, duration, reason, issuer)
	local tmp, admin, belt, pack, equipment
	
	-- TODO:  Look for and also ban players with the same IP

	belt = ""
	pack = ""
	equipment = ""

	if string.len(issuer) > 10 then
		admin = issuer
	else
		admin = 0
	end

	tmp = steam
	-- if there is no player with steamid steam, try looking it up incase we got their name instead of their steam
	if not players[steam] then
		steam = LookupPlayer(string.trim(steam))
		-- restore the original steam value if nothing matched as we may be banning someone who's never played here.
		if steam == nil then steam = tmp end
	end
	
	send("ban add " .. steam .. " " .. duration .. " \"" .. reason .. "\"")

	-- grab their belt, pack and equipment
	if players[steam] then
		cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .." ORDER BY inventoryTrackerid DESC Limit 1")
		row = cursor:fetch({}, "a")
		if row then
			belt = row.belt
			pack = row.pack
			equipment = row.equipment
		end
		
		conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. serverTime .. "','ban','Player " .. steam .. " " .. escape(players[steam].name) .. " has has been banned for " .. duration .. " for " .. escape(reason) .. "'," .. steam .. ")")
		irc_QueueMsg(server.ircMain, "[BANNED] Player " .. steam .. " " .. players[steam].name .. " has been banned for " .. duration .. " " .. reason)
		irc_QueueMsg(server.ircAlerts, "[BANNED] Player " .. steam .. " " .. players[steam].name .. " has been banned for " .. duration .. " " .. reason)
		
		-- add to bots db
		if reason == "blacklisted" then
			if db2Connected then
				connBots:execute("INSERT INTO bans (bannedTo, steam, reason, permanent, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "'," .. dbBool(players[steam].permanentBan) .. "," .. tonumber(players[steam].timeOnServer) + tonumber(players[steam].playtime) .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].zombies .. ",'" .. players[steam].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "')")
			end
		end
		
		send("llp " .. steam)
	else
		-- handle unknown steam id
		conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. serverTime .. "','ban','Player " .. steam .. " " .. steam .. " has has been banned for " .. duration .. " for " .. escape(reason) .. "'," .. steam .. ")")
		irc_QueueMsg(server.ircMain, "[BANNED] Unknown player " .. steam .. " has been banned for " .. duration .. " " .. reason)
		irc_QueueMsg(server.ircAlerts, "[BANNED] Unknown player " .. steam .. " has been banned for " .. duration .. " " .. reason)
		
		-- add to bots db
		if reason == "blacklisted" then
			if db2Connected then
				connBots:execute("INSERT INTO bans (bannedTo, steam, reason, permanent, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "',1,0,0,0,0,'','','','','" .. server.botID .. "','" .. admin .. "')")
			end
		end
	end
end


function arrest(steam, reason)
	if accessLevel(steam) < 3 then
		irc_QueueMsg(server.ircAlerts, gameDate .. " " .. steam .. " " .. players[steam].name .. " not arrested because they are staff.")
		return false
	end

	if igplayers[steam] then
		igplayers[steam].xPosOld = math.floor(igplayers[steam].xPos)
		igplayers[steam].yPosOld = math.floor(igplayers[steam].yPos)
		igplayers[steam].zPosOld = math.floor(igplayers[steam].zPos)	
		irc_QueueMsg(server.ircAlerts, players[steam].name .. " has been sent to prison for " .. reason .. " at " .. igplayers[steam].xPosOld .. " " .. igplayers[steam].yPosOld .. " " .. igplayers[steam].zPosOld)
	else
		players[steam].xPosOld = math.floor(players[steam].xPos)
		players[steam].yPosOld = math.floor(players[steam].yPos)
		players[steam].zPosOld = math.floor(players[steam].zPos)
		irc_QueueMsg(server.ircAlerts, players[steam].name .. " has been sent to prison for " .. reason .. " at " .. players[steam].xPosOld .. " " .. players[steam].yPosOld .. " " .. players[steam].zPosOld)
	end
	
	players[steam].prisoner = true			
	message("say [" .. server.chatColour .. "]" .. players[steam].name .. " has been sent to prison for " .. reason .. ".[-]")
	message("pm " .. steam .. " [" .. server.chatColour .. "]You are confined to prison until released.[-]")
	cmd = "tele " .. steam .. " " .. locations["prison"].x .. " " .. locations["prison"].y .. " " .. locations["prison"].z
	
	if players[steam].watchPlayer then
		irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. players[steam].name .. " arrested for " .. reason)
	end

	prepareTeleport(steam, cmd)
	teleport(cmd, true)
end


function timeoutPlayer(steam, reason, bot)
	-- if the player is not already in timeout, send them there.
	if players[steam].timeout == false and players[steam].botTimeout == false then
		players[steam].timeout = true
		if accessLevel(steam) > 2 then players[steam].silentBob = true end
		if bot then players[steam].botTimeout = true end -- the bot initiated this timeout
		-- record their position for return
		players[steam].xPosTimeout = math.floor(players[steam].xPos)
		players[steam].yPosTimeout = math.ceil(players[steam].yPos) + 1
		players[steam].zPosTimeout = math.floor(players[steam].zPos)

		conn:execute("UPDATE players SET timeout = 1, botTimeout = " .. dbBool(bot) .. ", xPosTimeout = " .. players[steam].xPosTimeout .. ", yPosTimeout = " .. players[steam].yPosTimeout .. ", zPosTimeout = " .. players[steam].zPosTimeout .. " WHERE steam = " .. steam)		
		conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. serverTime .. "','timeout','Player " .. steam .. " " .. escape(players[steam].name) .. " has has been sent to timeout for " .. escape(reason) .. "'," .. steam .. ")")
		
		-- then teleport the player to timeout
		players[steam].tp = 1
		players[steam].hackerScore = 0

		if players[steam].watchPlayer then
			irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. players[steam].name .. " sent to timeout")
		end

		send("tele " .. steam .. " " .. players[steam].xPosTimeout .. " 50000 " .. players[steam].zPosTimeout)

		message("say [" .. server.chatColour .. "]Sending player " .. players[steam].name .. " to timeout for " .. reason .. "[-]")
		irc_QueueMsg(server.ircMain, "[TIMEOUT] Player " .. steam .. " " .. players[steam].name .. " has been sent to timeout for " .. reason)
		irc_QueueMsg(server.ircAlerts, "[TIMEOUT] Player " .. steam .. " " .. players[steam].name .. " has been sent to timeout for " .. reason)
	end
end


function checkRegionClaims(x, z)
	cursor,errorString = conn:execute("SELECT * FROM keystones WHERE floor(x / 512) =  " .. x .. " AND floor(z / 512) = " .. z)
	row = cursor:fetch({}, "a")
	while row do
		if row.remove == "1" then
			send("rlp " .. row.x .. " " .. row.y .. " " .. row.z)
			conn:execute("UPDATE keystones SET remove = 2 WHERE steam = " .. row.steam .. " AND x = " .. row.x .. " AND y = " .. row.y .. " AND z = " .. row.z )
		end

		row = cursor:fetch(row, "a")	
	end
end


function dbWho(ownerid, x, y, z, dist, days, hours, height)
	local cursor, errorString,row, counter

	if days == nil then days = 1 end
	if height == nil then height = 4 end

	conn:execute("DELETE FROM searchResults WHERE owner = " .. ownerid)

	if hours > 0 then
		cursor,errorString = conn:execute("select distinct steam, session from tracker where abs(x - " .. x .. ") < " .. dist .. " and abs(z - " .. z .. ") < " .. dist .. " and abs(y - " .. y .. ") < " .. height .. " and timestamp >= '" .. os.date("%Y-%m-%d %H:%M:%S", os.time() - (tonumber(hours) * 3600)) .. "'")
	else
		cursor,errorString = conn:execute("select distinct steam, session from tracker where abs(x - " .. x .. ") < " .. dist .. " and abs(z - " .. z .. ") < " .. dist .. " and abs(y - " .. y .. ") < " .. height .. " and timestamp >= '" .. os.date("%Y-%m-%d %H:%M:%S", os.time() - (tonumber(days) * 86400)) .. "'")
	end

	row = cursor:fetch({}, "a")
	counter = 1
	rows = cursor:numrows()

	if igplayers[ownerid] == nil then
		if rows > 50 then
			irc_QueueMsg(ownerid, "****** Report length " .. rows .. " rows.  Cancel it with: nuke irc ******")
		end
	end

	while row do
		conn:execute("INSERT INTO searchResults (owner, steam, session, counter) VALUES (" .. ownerid .. "," .. row.steam .. "," .. row.session .. "," .. counter .. ")")

		if igplayers[ownerid] then
			message("pm " .. ownerid .. " [" .. server.chatColour .. "] #" .. counter .." " .. row.steam .. " " .. players[row.steam].id .. " " .. players[row.steam].name .. " sess: " .. row.session .. "[-]")
		else
			irc_QueueMsg(ownerid, "#" .. counter .." " .. row.steam .. " " .. players[row.steam].name .. " sess: " .. row.session)
		end

		counter = counter + 1
		row = cursor:fetch(row, "a")	
	end
end


function dailyMaintenance()
	-- put something here to be run when the server date hits midnight
	if db2Connected then
		getWhitelistedServers()
	end

	return true
end


function startReboot()
	send("sa")
	rebootTimerID = tempTimer( 5, [[finishReboot()]] )
end


function clearRebootFlags()
	nextRebootTest = os.time() + 60
	scheduledReboot = false 
	server.scheduledRestart = false
	server.scheduledRestartTimestamp = os.time()
	scheduledRestartPaused = false
	scheduledRestartForced = false
end


function finishReboot()
	tempTimer( 30, [[clearRebootFlags()]] )

	if (rebootTimerID ~= nil) then 
		killTimer(rebootTimerID)
		rebootTimerID = nil 
	end

	if (rebootTimerDelayID ~= nil) then 
		killTimer(rebootTimerDelayID)
		rebootTimerDelayID = nil 
	end

	if not server.allowPhysics then
		server.tempMaxPlayers = server.maxPlayers
		send("sg ServerMaxPlayerCount 0")
	end

	send("shutdown")
end


function newDay()
	if (string.sub(serverTime, 1, 10) ~= server.date) then
		server.date = string.sub(serverTime, 1, 10)
		resetShop()

		if tonumber(playersOnline) == 0 then
			saveLuaTables()
		end
	end
end


function IPToInt(ip)
	local o1,o2,o3,o4

	o1,o2,o3,o4 = ip:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
	return 2^24*o1 + 2^16*o2 + 2^8*o3 + o4
end


function readIPBlacklist()
	-- very slow.  don't run with a full server
	local ln
	local iprange

	local o1,o2,o3,o4
	local num1,num2

	for ln in io.lines(homedir .. "/cn.csv") do
		iprange = string.split(ln, ",")

		o1,o2,o3,o4 = iprange[1]:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
		num1 = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4

		o1,o2,o3,o4 = iprange[2]:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
		num2 = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4

		connBots:execute("INSERT INTO IPBlacklist (StartIP, EndIP) VALUES (" .. num1 .. "," .. num2 .. ")")
	end
end


function Translate(playerid, command, lang, override)
	local words, word, oldCount, matches

	os.remove(userHome .. "/" .. server.botID .. "trans.txt")
	os.execute(userHome .. "/" .. server.botID .. "trans.txt")

	words = {}
	for word in command:gmatch("%S+") do table.insert(words, word) end
	oldCount = table.maxn(words)

	if lang == "" then
		os.execute("trans -b -no-ansi \"" .. command .. "\" > " .. userHome .. "/" .. server.botID .. "trans.txt")
	else
		os.execute("trans -b -no-ansi {en=" .. lang .."}  \"" .. command .. "\" > " .. userHome .. "/" .. server.botID .. "trans.txt")
	end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         

	for ln in io.lines(userHome .. "/" .. server.botID .. "trans.txt") do
		matches = 0
		for word in ln:gmatch("%S+") do
			if string.find(command, word, nil, true) then
				matches = matches + 1
			end
		end

		if matches < 2 then
			if ln ~= command and string.trim(ln) ~= "" then
				if players[playerid].translate == true or override ~= nil then
					message("say [BDFFFF]" .. players[playerid].name .. " [-]" .. ln)
				end

				if players[playerid].translate == false then
					irc_QueueMsg(server.ircMain, players[playerid].name .. " " .. ln)
				end
			end
		end
	end

	io.close()
end


function CheckClaimsRemoved()
	for k,v in pairs(igplayers) do
		if players[k].alertRemovedClaims == true then
			message("pm " .. k .. " [" .. server.chatColour .. "]You placed claims in a restricted area and they have been automatically removed.  You can get them back by typing /give lcb.[-]")
			players[k].alertRemovedClaims = false
		end
	end
end


function CheckBlacklist(steam, ip)
	local o1,o2,o3,o4 = ip:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
	local ipint = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4

	if not db2Connected then
		return
	end

	if players[steam].whitelisted == false then
		-- test for China IP
		ipint = tonumber(ipint)

		cursor,errorString = connBots:execute("SELECT * FROM IPBlacklist WHERE StartIP <=  " .. ipint .. " AND EndIP >= " .. ipint)
		if cursor:numrows() > 0 then

			irc_QueueMsg(server.ircMain, "Chinese IP detected. " .. players[steam].name)
			irc_QueueMsg(server.ircAlerts, "Chinese IP detected. " .. players[steam].name)
			players[steam].china = true
			players[steam].country = "CN"
			players[steam].ircTranslate = true

			if server.blacklistResponse == 'exile' then
				if tonumber(players[steam].exiled) == 0 then
					players[steam].exiled = 1
					conn:execute("UPDATE players SET country = 'CN', exiled = 1, ircTranslate = 1 WHERE steam = " .. steam)
				end

				-- alert players
				for k, v in pairs(igplayers) do
					if players[k].exiled~=1 and not players[k].prisoner then
						message("pm " .. k .. " Chinese player " .. players[steam].name .. " detected and sent to exile.[-]")
					end
				end
			end

			if server.blacklistResponse == 'ban' then
				irc_QueueMsg(server.ircMain, "Chinese player " .. players[steam].name .. " banned.")
				irc_QueueMsg(server.ircAlerts, "Chinese player " .. players[steam].name .. " banned.")
				banPlayer(steam, "10 years", "blacklisted", "")
			end

			connBots:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. serverTime .. "','info','Chinese player joined. Name: " .. escape(player) .. " SteamID: " .. steam .. " IP: " .. ip  .. "'," .. steam .. ")")
		else
			reverseDNS(steam, ip)
		end
	end
end


function reverseDNS(steam, ip)
	os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	os.execute("whois " .. ip .. " > \"" .. homedir .. "/dns/" .. steam .. ".txt\"")
	tempTimer( 60, [[readDNS("]] .. steam .. [[")]] )
end


function readDNS(steam)
	local file, ln, split, ip1, ip2, exiled, country, proxy, ISP

	file = io.open(homedir .. "/dns/" .. steam .. ".txt", "r")	
	exiled = false
	proxy = false
	country = ""
	for ln in file:lines() do
		ln = string.upper(ln)

		if string.find(ln, "%s(%d+)%.(%d+)%.(%d+)%.(%d+)%s") then
			a,b = string.find(ln, "%s(%d+)%.(%d+)%.(%d+)%.(%d+)%s")
			iprange = string.sub(ln, a, a+b)
		end

		if not players[steam].whitelisted and isNewPlayer(steam) then
			for k,v in pairs(proxies) do
				if string.find(ln, string.upper(v.scanString), nil, true) then
					v.hits = tonumber(v.hits) + 1

					if db2Connected then
						connBots:execute("UPDATE proxies SET hits = hits + 1 WHERE scanString = '" .. escape(k) .. "'")
					end

					if v.action == "ban" or v.action == "" then
						irc_QueueMsg(server.ircMain, "Player " .. players[steam].name .. " banned. Detected proxy " .. v.scanString)
						irc_QueueMsg(server.ircAlerts, "Player " .. players[steam].name .. " banned. Detected proxy " .. v.scanString)
						banPlayer(steam, "10 years", "Banned proxy", "")
						proxy = true
					else
						if players[steam].exiled == 0 then
							players[steam].exiled = 1
							irc_QueueMsg(server.ircMain, "Player " .. players[steam].name .. " exiled. Detected proxy " .. v.scanString)
							irc_QueueMsg(server.ircAlerts, "Player " .. players[steam].name .. " exiled. Detected proxy " .. v.scanString)
							exiled = true
							proxy = true
						end
					end
				end
			end
		end

		if proxy then break end
		
		if string.find(ln, "ABUSE@") then
			-- record the domain after the @ and store as the player's ISP
			ISP = string.sub(ln, string.find(ln, "ABUSE@") + 6)
			players[steam].ISP = ISP
		end

		if string.find(ln, "OUNTRY:") or (ln == "ADDRESS:        CN") or (ln == "ADDRESS:        HK") then
			-- only report country change if CN or HK are involved. For once, don't blame Canada.
			a,b = string.find(ln, "%s(%w+)")
			country = string.sub(ln, a + 1)
			if players[steam].country ~= "" and players[steam].country ~= country and (players[steam].country == "CN" or players[steam].country == "HK" or country == "CN" or country == "HK") and players[steam].whitelisted == false then
				irc_QueueMsg(server.ircAlerts, "Possible proxy detected! Country changed! " .. steam .. " " .. players[steam].name .. " " .. players[steam].IP .. " old country " .. players[steam].country .. " new " .. country)
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (0,0,0'" .. serverTime .. "','proxy','Suspected proxy used by " .. escape(players[steam].name) .. " " .. players[steam].IP .. " old country " .. players[steam].country .. " new " .. country .. "," .. steam .. ")")	
				proxy = true
			else
				 players[steam].country = country
			end
		end

		-- We consider HongKong to be China since Chinese players connect from there too.
		if (country == "CN" or country == "HK") and players[steam].whitelisted == false then
			-- China detected. Add ip range to IPBlacklist table
			split = string.split(iprange, "-")

			ip1 = IPToInt(string.trim(split[1]))
			ip2 = IPToInt(string.trim(split[2]))
			
			irc_QueueMsg(server.ircMain, "Chinese IP detected. " .. players[steam].name .. " " .. players[steam].IP)
			irc_QueueMsg(server.ircAlerts, "Chinese IP detected. " .. players[steam].name .. " " .. players[steam].IP)
			players[steam].china = true
			players[steam].ircTranslate = true

			if server.blacklistResponse == 'exile' then
				if players[steam].exiled == 0 then
					players[steam].exiled = 1
					irc_QueueMsg(server.ircMain, "Chinese player " .. players[steam].name .. " exiled.")
					irc_QueueMsg(server.ircAlerts, "Chinese player " .. players[steam].name .. " exiled.")
					exiled = true
				end
			end

			if server.blacklistResponse == 'ban' then
				irc_QueueMsg(server.ircMain, "Chinese player " .. players[steam].name .. " banned.")
				irc_QueueMsg(server.ircAlerts, "Chinese player " .. players[steam].name .. " banned.")
				banPlayer(steam, "10 years", "blacklisted", "")
			end

			if db2Connected then
				irc_QueueMsg(server.ircMain, "Added new Chinese IP range " .. iprange .. " to blacklist")			
				connBots:execute("INSERT INTO IPBlacklist (StartIP, EndIP) VALUES (" .. ip1 .. "," .. ip2 .. ")")
			end

			-- alert players
			for k, v in pairs(igplayers) do
				if players[k].exiled~=1 and not players[k].prisoner then
					if exiled then
						message("pm " .. k .. " Chinese player " .. players[steam].name .. " detected and sent to exile.[-]")
					else
						message("pm " .. k .. " Chinese player " .. players[steam].name .. " detected.[-]")
					end
				end
			end

			conn:execute("UPDATE players SET country = '" .. escape(country) .. "', exiled = 1, ircTranslate = 1 WHERE steam = " .. steam)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. serverTime .. "','info','Chinese player joined. Name: " .. escape(player) .. " SteamID: " .. steam .. " IP: " .. players[steam].IP  .. "'," .. steam .. ")")	
			file:close()

			-- got country so stop processing the dns record
			break
		end
	end

	if proxy then
		os.rename(homedir .. "/dns/" .. steam .. "_old.txt", homedir .. "/proxies/" .. steam .. "_" .. country .. ".txt")
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/proxies/" .. steam .. "_" .. country .. ".txt")
	else
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	end

	conn:execute("UPDATE players SET country = '" .. country .. "' WHERE steam = " .. steam)

	file:close()

	if not proxy then
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	end
end


function initNewPlayer(steam, player, entityid, steamOwner)
	conn:execute("INSERT INTO players (steam, id, name, steamOwner) VALUES (" .. steam .. "," .. entityid .. ",'" .. escape(player) .. "'," .. steamOwner .. ")")

	players[steam] = {}
	players[steam].id = entityid
	players[steam].name = player
	players[steam].names = player .. ","
	players[steam].steam = steam
	players[steam].steamOwner = steamOwner
	players[steam].xPos = 0
	players[steam].yPos = 0
	players[steam].zPos = 0
	players[steam].xPosOld = 0
	players[steam].yPosOld = 0
	players[steam].zPosOld = 0
	players[steam].xPosOld2 = 0
	players[steam].yPosOld2 = 0
	players[steam].zPosOld2 = 0
	players[steam].homeX = 0
	players[steam].homeY = 0
	players[steam].homeZ = 0
	players[steam].home2X = 0
	players[steam].home2Y = 0
	players[steam].home2Z = 0
	players[steam].gimmeCount = 0
	players[steam].baseCooldown = 0
	players[steam].teleCooldown = 0
	players[steam].walkies = false
	players[steam].silentBob = false
	players[steam].donor = false
	players[steam].donorLevel = 0
	players[steam].donorExpiry = os.time()
	players[steam].protect = false
	players[steam].protectSize = server.baseSize
	players[steam].protect2 = false
	players[steam].protect2Size = server.baseSize
	players[steam].firstSeen = os.time()
	players[steam].timeOnServer = 0
	players[steam].alertPrison = true
	players[steam].alertPVP = true
	players[steam].alertReset = true
	players[steam].alertMapLimit = false
	players[steam].timeout = false
	players[steam].newPlayer = true
	players[steam].watchPlayer = true
	players[steam].sessionCount = 1
	players[steam].lastBaseRaid = 0
	players[steam].raiding = false
	players[steam].botTimeout = false
	players[steam].playtime = 0
	players[steam].cash = 0
	players[steam].overstack = false
	players[steam].overstackScore = 0
	players[steam].overstackTimeout = false
	players[steam].overstackItems = ""
	players[steam].removeClaims = false
	players[steam].tokens = 0
	players[steam].prisoner = false
	players[steam].whitelisted = false
	players[steam].permanentBan = false
	players[steam].prisonxPosOld = 0
	players[steam].prisonyPosOld = 0
	players[steam].prisonzPosOld = 0
	players[steam].prisonReason = ""
	players[steam].pvpVictim = 0
	players[steam].country = ""
	players[steam].ping = 0
	players[steam].lastLogout = os.time()
	players[steam].relogCount = 0
	players[steam].atHome = false
	players[steam].location = "lobby"
	players[steam].autoFriend = ""
	players[steam].hackerScore = 0
	players[steam].tp = 0
	players[steam].bedX = 0
	players[steam].bedY = 0
	players[steam].bedZ = 0
	players[steam].packCooldown = 0
	players[steam].ircPass = ""
	players[steam].ISP = ""
	players[steam].ignorePlayer = false -- exclude player from checks like inventory, flying, teleporting etc.
	return true
end


function initNewIGPlayer(steam, player, entityid, steamOwner)
	igplayers[steam] = {}
	igplayers[steam].id = entityid
	igplayers[steam].name = player
	igplayers[steam].steam = steam
	igplayers[steam].steamOwner = steamOwner
	igplayers[steam].greet = true
	igplayers[steam].connected = true
	igplayers[steam].greetdelay = 4
	igplayers[steam].xPos = 0
	igplayers[steam].yPos = 0
	igplayers[steam].zPos = 0
	igplayers[steam].xPosLast = 0
	igplayers[steam].yPosLast = 0
	igplayers[steam].zPosLast = 0
	igplayers[steam].xPosLastOK = 0
	igplayers[steam].yPosLastOK = 0
	igplayers[steam].zPosLastOK = 0
	igplayers[steam].firstSeen = os.time()
	igplayers[steam].sessionStart = os.time()
	igplayers[steam].sessionPlaytime = 0
	igplayers[steam].timeOnServer = 0
	igplayers[steam].lastHotspot = 0
	igplayers[steam].inventory = ""
	igplayers[steam].inventoryLast = ""
	igplayers[steam].illegalInventory = false
	igplayers[steam].botQuestion = "" -- used for storing the last question the bot asked the player.
	igplayers[steam].killTimer = 0
	igplayers[steam].xPosLastAlert = 0
	igplayers[steam].yPosLastAlert = 0
	igplayers[steam].zPosLastAlert = 0
	igplayers[steam].ping = 0
	igplayers[steam].highPingCount = 0
	igplayers[steam].afk = os.time() + 180
	igplayers[steam].checkNewPlayer = true
	igplayers[steam].lastLP = os.time()
	igplayers[steam].flying = false
	igplayers[steam].flyCount = 0
	return true
end


function fixMissingStuff()
	lfs.mkdir(homedir .. "/daily")
	lfs.mkdir(homedir .. "/dns")
	lfs.mkdir(homedir .. "/proxies")
	lfs.mkdir(homedir .. "/temp")
	lfs.mkdir(homedir .. "/scripts")

	if not isFile(homedir .. "/scripts/gmsg_custom.lua") then
		file = io.open(homedir .. "/scripts/gmsg_custom.lua", "a")
		file:write("function gmsg_custom()\n")
		file:write("	calledFunction = \"gmsg_custom\"\n")
		file:write("	\-\- ###################  do not allow remote commands beyond this point ################\n")
		file:write("	if (chatvars.playerid == nil) then\n")
		file:write("		faultyChat = false\n")
		file:write("		return false\n")
		file:write("	end\n")
		file:write("	\-\- ####################################################################################\n")
		file:write("	if (chatvars.words[1] == \"test\" and chatvars.words[2] == \"command\") then\n")
		file:write("		message(\"pm \" .. chatvars.playerid .. \" [\" .. server.chatColour .. \"]This is a sample command in gmsg_custom.lua in the scripts folder.[-]\")\n")
		file:write("		faultyChat = false\n")
		file:write("		return true\n")
		file:write("	end\n")
		file:write("end\n")
		file:close()
	end
end


function playerDisconnected(steam)
	-- this function has been moved from the player disconnected trigger so we can call it in other places if necessary to ensure all online player data is saved to the database.

	fixMissingPlayer(steam)

	-- update players table with x y z
	players[steam].lastAtHome = nil
	players[steam].protectPaused = nil
	players[steam].protect2Paused = nil

	if igplayers[steam] then
		-- only process the igplayer record if the player is actually online otherwise assume these are already done
		players[steam].xPos = igplayers[steam].xPos
		players[steam].yPos = igplayers[steam].yPos
		players[steam].zPos = igplayers[steam].zPos
		players[steam].playerKills = igplayers[steam].playerKills
		players[steam].deaths = igplayers[steam].deaths
		players[steam].zombies = igplayers[steam].zombies
		players[steam].score = igplayers[steam].score
		players[steam].ping = igplayers[steam].ping
		players[steam].timeOnServer = players[steam].timeOnServer + igplayers[steam].sessionPlaytime

		if (igplayers[steam].sessionPlaytime) > 300 then
			players[steam].relogCount = 0
		end

		if (igplayers[steam].sessionPlaytime) < 60 then
			if not players[steam].timeout and not players[steam].botTimeout and not players[steam].prisoner then
				players[steam].relogCount = tonumber(players[steam].relogCount) + 1
			end
		else
			players[steam].relogCount = tonumber(players[steam].relogCount) - 1
			if tonumber(players[steam].relogCount) < 0 then players[steam].relogCount = 0 end
		end

		players[steam].lastLogout = os.time()
		players[steam].seen = serverTime
	end

	if accessLevel(steam) < 3 then
		conn:execute("DELETE FROM memTracker WHERE admin = " .. steam)
	end

	conn:execute("DELETE FROM messageQueue WHERE recipient = " .. steam)
	conn:execute("DELETE FROM gimmeQueue WHERE steam = " .. steam)
	conn:execute("DELETE FROM commandQueue WHERE steam = " .. steam)
	conn:execute("DELETE FROM playerQueue WHERE steam = " .. steam)

	-- delete player from igplayers table
	igplayers[steam] = nil
	lastHotspots[steam] = nil
	invTemp[steam] = nil

	-- update the player record in the database
	updatePlayer(steam)

	if	db2Connected then
		-- insert or update player in bots db
		connBots:execute("INSERT INTO players (server, steam, ip, name, online) VALUES ('" .. escape(server.ServerName) .. "'," .. steam .. ",'" .. players[steam].IP .. "','" .. escape(players[steam].name) .. "',0) ON DUPLICATE KEY UPDATE ip = '" .. players[steam].IP .. "', name = '" .. escape(players[steam].name) .. "', online = 0")		
	end
end


function shutdownBot(steam)
	for k,v in pairs(igplayers) do
		savePlayerData(k)
	end

	if igplayers[steam] then
		message("pm " .. steam .. " [" .. server.chatColour .. "]" .. server.botName .. " is ready to shutdown.  Player data is saved.[-]")
	end
	
	sendIrc(server.ircMain, server.botName .. " is ready to shutdown.  Player data is saved.")		
end
