--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

--/mode #haven2 +f [5000t#b]:1

local ircid, pid, login, name1, name2, words, wordsOld, words2, wordCount, result, msgLower, number, counter, xpos, zpos, debug, tmp

debug = false

function requireLogin(name)
	irc_QueueMsg(name, "Your login has expired. Login and and repeat your command.")
end

IRCMessage = function (event, name, channel, msg)
	if string.find(msg, "Server: ") then
		server.ircBotName = name
	end

	if debug then 
		dbug("debug ircmessage") 
		dbug(event .. " " .. name .. " " .. channel .. " " .. msg)
	end

	-- block Mudlet from messaging the official Mudlet support channel
	if (channel == "#mudlet") then
		server.ircDisabled = true
		return 
	end

	-- block Mudlet from reacting to its own messages
	if (name == server.botName or name == server.ircBotName or string.find(msg, "<" .. server.ircBotName .. ">", nil, true)) then return end

	wordsOld = {}
	for word in msg:gmatch("%S+") do table.insert(wordsOld, word) end

	words2 = string.split(msg, " ")
	msgLower = string.lower(msg)

	words = {}
	irc_params = {}
	ircid = LookupOfflinePlayer(name, "all")

	if ircid ~= nil and debug then
		dbug("ircid " .. ircid)
		dbug("accessLevel " .. accessLevel(ircid))
	end

	if ircid ~= nil then
		if players[ircid].ircAuthenticated == true then
			-- keep login session alive
			if accessLevel(ircid) < 4 then
				players[ircid].ircSessionExpiry = os.time() + 3600
			else
				players[ircid].ircSessionExpiry = os.time() + 10800
			end
		end

		dbug("IRC: " .. name .. " access " .. accessLevel(ircid) .. " said " .. msg)
	end

	if debug then dbug("debug ircmessage 2") end

	table.insert(irc_params, name)
	for word in msgLower:gmatch("%w+") do table.insert(words, word) end
	wordCount = table.maxn(words)

	number = tonumber(string.match(msg, " (-?\%d+)"))

	if (words[1] == "hi" or words[1] == "hello") and (string.lower(words[2]) == string.lower(server.botName) or string.lower(words[2]) == string.lower(server.ircBotName) or words[2] == "bot" or words[2] == "server") then
		table.insert(irc_params, " Hi there " .. name .. "!  How can I help you today?")
		irc_QueueMsg(name, irc_params[2])
		return
	end


	if (words[1] == "staff" and words[2] == nil) then
		irc_List_Owners(name)
		irc_List_Admins(name)
		irc_List_Mods(name)
		return
	end


	if (words[1] == "owners" and words[2] == nil) then
		irc_List_Owners(name)
		return
	end


	if (words[1] == "admins" and words[2] == nil) then
		irc_List_Admins(name)
		return
	end


	if (words[1] == "mods" and words[2] == nil) then
		irc_List_Mods(name)
		return
	end


	if words[1] == string.lower(server.botName) or words[1] == string.lower(server.ircBotName) and words[2] == nil then
		irc_params = {}
		table.insert(irc_params, server.ircMain)
		table.insert(irc_params, " Hi " .. name)
		irc_QueueMsg(irc_params[1], irc_params[2])
		return
	end


	if (words[1] == "say") then
		if players[ircid].ircAuthenticated == false then
			requireLogin(name)
			return
		end

		msg = string.trim(string.sub(msg, 5))
		message("say " .. name .. "-irc: [i]" .. msg .. "[/i][-]")
		return
	end


	if (string.find(words[1], "say") and (string.len(words[1]) == 5) and words[2] ~= nil) then
		if players[ircid].ircAuthenticated == false then
			requireLogin(name)
			return
		end

		msg = string.sub(msg, string.len(words[1]) + 2)
		msg = string.trim(msg)

		if (msg ~= "") then
			Translate(ircid, msg, string.sub(words[1], 4), true)
		end

		return
	end


	if (words[1] == "date" or words[1] == "time" or words[1] == "day") and words[2] == nil then
		irc_gameTime(channel)
		return
	end


	if (words[1] == "uptime") and words[2] == nil then
		irc_uptime(channel)
		return
	end


	if (words[1] == "location") then
		-- display details about the location

		locationName = words[2]
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			irc_QueueMsg(name, "That location does not exist.")
			return
		else	
			cursor,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. locationName .."'")
			row = cursor:fetch({}, "a")

			irc_QueueMsg(name, "Location: " .. row.name)
			irc_QueueMsg(name, "Active: " .. dbYN(row.active))
			irc_QueueMsg(name, "Reset Zone: " .. dbYN(row.resetZone))
			irc_QueueMsg(name, "Safe Zone: " .. dbYN(row.killZombies))
			irc_QueueMsg(name, "Public: " .. dbYN(row.public))
			irc_QueueMsg(name, "Allow Bases: " .. dbYN(row.allowBase))

			if row.miniGame ~= nil then
				irc_QueueMsg(name, "Mini Game: " .. row.miniGame)
			end

			irc_QueueMsg(name, "Village: " .. dbYN(row.village))

			temp = LookupPlayer(row.mayor)
			if row.owner ~= "0" then 
				temp = LookupPlayer(row.mayor)
			else
				temp = ""
			end

			irc_QueueMsg(name, "Mayor: " .. temp)
			irc_QueueMsg(name, "Protected: " .. dbYN(row.protected))
			irc_QueueMsg(name, "PVP: " .. dbYN(row.pvp))
			irc_QueueMsg(name, "Access Level: " .. row.accessLevel)

			temp = LookupPlayer(row.owner)
			if row.owner ~= "0" then 
				temp = LookupPlayer(row.owner)
			else
				temp = ""
			end

			irc_QueueMsg(name, "Owner: " .. temp)
			irc_QueueMsg(name, "Coords: " .. row.x .. " " .. row.y .. " " .. row.z)
			irc_QueueMsg(name, "Size: " .. row.size * 2)
			irc_QueueMsg(name, "Players in " .. loc)
	
			for k,v in pairs(igplayers) do
				if players[k].inLocation == loc then
					irc_QueueMsg(name, v.name)
				end
			end

			irc_QueueMsg(name, "")
		end

		return
	end
	

	if words[1] == "server" and (words[2] == "status" or words[2] == "stats") then
		irc_server_status(name)
		return
	end


	if (words[1] == "who" and words[2] == nil) then
		irc_players(name)
		return
	end


	if (words[1] == "help" and words[2] == "shop") then
		irc_HelpShop()
		return
	end


	if (words[1] == "help" and words[2] == "topics") then
		if words[3] ~= nil then
			table.insert(irc_params, words[3])
		end

		irc_HelpTopics()
		return
	end
	
	
	if (words[1] == "command" and words[2] == "help") then
		if words[3] == nil then 
			gmsg("/command help", ircid)
		else
			gmsg("/command help " .. words[3], ircid) 
		end

		return
	end	
	
	
	if (words[1] == "list" and words[2] == "help") then
		if words[3] == nil then 
			gmsg("/list help", ircid)
		else
			gmsg("/list help " .. words[3], ircid) 
		end

		return
	end


	if (words[1] == "help" and words[2] == nil) then
		irc_commands()
		return
	end
	
	
	if (words[1] == "help" and words[2] == "server") then
		irc_HelpServer()
		return
	end


	if (words[1] == "help" and words[2] == "donors") then
		irc_HelpDonors()
		return
	end
	
	
	if (words[1] == "help" and words[2] == "csi") then
		irc_HelpCSI()
		return
	end


	if (words[1] == "help" and words[2] == "watchlist") then
		irc_HelpWatchlist()
		return
	end
	
	
	if (words[1] == "help" and words[2] == "bad" and words[3] == "items") then
		irc_HelpBadItems()
		return
	end


	if (words[1] == "help" and words[2] == "announcements") then
		irc_HelpAnnouncements()
		return
	end


	if (words[1] == "help" and words[2] == "commands") then
		irc_HelpCommands()
		return
	end


	if (words[1] == "help" and words[2] == "custom" and words[3] == "commands") then
		irc_HelpCustomCommands()
		return
	end


	if (words[1] == "help" and words[2] == "motd") then
		irc_HelpMOTD()
		return
	end
	
	
	if (words[1] == "help" and words[2] ~= nil) then
		gmsg("/help " .. string.sub(msg, 6), ircid)
		return
	end


	if (words[1] == "reset" and words[2] == "zones" and words[3] == nil) then
		irc_listResetZones(name)
		return
	end


	if (words[1] == "locations" and words[2] == nil) then
		irc_locations(name)	
		return
	end


	if (words[1] == "villages" and words[2] == nil) then
		irc_List_Villages(name)
		return
	end


	if words[1] == "fps" and words[2] == nil then
		cursor,errorString = conn:execute("SELECT * FROM performance  ORDER BY serverdate DESC Limit 0, 1")
		row = cursor:fetch({}, "a")

		if row then
			irc_QueueMsg(channel, "Server FPS: " .. server.fps .. " Players: " .. row.players .. " Zombies: " .. row.zombies .. " Entities: " .. row.entities .. " Heap: " .. row.heap .. " HeapMax: " .. row.heapMax)
		end

		return
	end	


	if words[1] == "shop" and shopCategories[words[2]] then
		LookupShop(words[2], true)	

		cursor,errorString = conn:execute("SELECT * FROM memShop ORDER BY idx")
		row = cursor:fetch({}, "a")

		while row do
			if tonumber(row.stock) == -1 then
				msg = "Code:  " .. row.code .. "    item:  " .. row.item .. "    price:  " .. row.price .. " UNLIMITED"
			else
				msg = "Code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. "  (" .. row.stock .. ")  left"
			end

			irc_QueueMsg(irc_params[1], msg)
			row = cursor:fetch(row, "a")	
		end

		irc_QueueMsg(irc_params[1], "")											
		return
	end	


	if (words[1] == "shop" and words[2] == "categories") then		
		irc_QueueMsg(irc_params[1], "The shop categories are:")

		for k, v in pairs(shopCategories) do
			irc_QueueMsg(irc_params[1], k)
		end

		irc_QueueMsg(irc_params[1], "")				
		return
	end	


	if (words[1] == "shop" and words[2] ~= nil and words[3] == nil) then
		LookupShop(wordsOld[2], true)		

		cursor,errorString = conn:execute("SELECT * FROM memShop ORDER BY category, idx")
		row = cursor:fetch({}, "a")

		while row do
			if tonumber(row.stock) == -1 then
				msg = "Code:  " .. row.code .. "    item:  " .. row.item .. "    price:  " .. row.price .. " UNLIMITED"
			else
				msg = "Code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. "  (" .. row.stock .. ")  left"
			end

			irc_QueueMsg(irc_params[1], msg)

			row = cursor:fetch(row, "a")	
		end

		irc_QueueMsg(irc_params[1], "")				
		return
	end	


	if (words[1] == "nuke" or words[1] == "clear" and words[2] == "irc") or (words[1] == "stop" and words[2] == nil) then
		conn:execute("DELETE FROM ircQueue WHERE name = '" .. name .. "'")
		irc_QueueMsg(channel, "IRC spam nuked for " .. name)

		if ircListItems == ircid then ircListItems = nil end

		if echoConsoleTo == name then
			echoConsole = nil
			echoConsoleTo = nil
		end
	end
	
	
	if words[1] == "nuke" or words[1] == "clear" or words[1] == "stop" and words[2] == "all" then
		conn:execute("DELETE FROM ircQueue WHERE")
		irc_QueueMsg(channel, "IRC spam nuked for everyone")

		ircListItems = nil
		echoConsole = nil
		echoConsoleTo = nil
	end
	
	
	if (words[1] == "server") then
		if words[2] == "ip" or words[2] == "address" and (string.trim(words[3]) ~= "") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end			
		
			server.IP = string.sub(msg, string.find(msg, words[3]), string.len(msg))
			table.insert(irc_params, "The server address is now " .. server.IP .. ":" .. server.ServerPort)
			irc_message()

			conn:execute("UPDATE server SET IP = '" .. server.IP .. "'")
			getWhitelistedServers()

			return
		end

		if words[2] == nil then
			irc_QueueMsg(irc_params[1], "Server name is " .. server.ServerName)
			irc_QueueMsg(irc_params[1], "Address is " .. server.IP .. ":" .. server.ServerPort)
			irc_QueueMsg(irc_params[1], "There are  " .. playersOnline .. " players online.")
			return
		end
	end


	if (words[1] == "rules") then
		if words[2] == nil then
			table.insert(irc_params, "The server rules are " .. server.rules)
			irc_message()
			return
		else
			table.insert(irc_params, "To change the rules type set rules <new rules>")
			irc_message()
			return
		end
	end	
	
	
	if debug then dbug("debug ircmessage 3") end

	if (ircid ~= nil) and (accessLevel(ircid) < 3) then
-- ########### Staff only in this section ###########

	if words[1] == "new" and words[2] == "players" then	
		pid = LookupOfflinePlayer(name, "all")

		if number == nil then 
			number = 86400 
		else
			number = number * 86400
		end

		irc_QueueMsg(name, "New players in the last " .. math.floor(number / 86400) .. " days:")

		cursor,errorString = conn:execute("SELECT * FROM events where timestamp >= '" .. os.date('%Y-%m-%d %H:%M:%S', os.time() - number).. "' and type = 'new player' order by timestamp desc")
		row = cursor:fetch({}, "a")
		
		while row do
			if accessLevel(pid) > 3 then
				irc_QueueMsg(name, v.name)
			else
				msg = "steam: " .. row.steam .. " id: " .. string.format("%8d", players[row.steam].id) .. " name: " .. players[row.steam].name .. " at [ " .. players[row.steam].xPos .. " " .. players[row.steam].yPos .. " " .. players[row.steam].zPos .. " ] " .. players[row.steam].country
				msg = msg .. " PVP " .. players[row.steam].playerKills

				if (igplayers[row.steam]) then
					time = tonumber(players[row.steam].timeOnServer) + tonumber(igplayers[row.steam].sessionPlaytime)
				else
					time = tonumber(players[row.steam].timeOnServer)
				end

				hours = math.floor(time / 3600)

				if (hours > 0) then
					time = time - (hours * 3600)
				end

				minutes = math.floor(time / 60)

				msg = msg .. " Playtime " .. hours .. "h " .. minutes .. "m"

				cursor2,errorString = conn:execute("SELECT * FROM bans WHERE steam =  " .. row.steam)
				if cursor2:numrows() > 0 then
					msg = msg .. " BANNED"
				end

				if players[row.steam].timeout == true then
					msg = msg .. " TIMEOUT"
				end

				if players[row.steam].country == "CN" or players[row.steam].country == "HK" then
					msg = msg .. " Chinese"
				end

				irc_QueueMsg(name, msg)
			end

			row = cursor:fetch(row, "a")	
		end
	
		irc_QueueMsg(name, "")
		return
	end

		if words[1] == "check" and words[2] == "dns" then
			if debug then dbug("debug ircmessage " .. msg) end

			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			pid = ""
			number = ""

			for i=2,wordCount,1 do
				if words2[i] == "dns" then
					name1 = words2[i+1]
					pid = LookupPlayer(name1)
				end					
			end


			if pid ~= "" then
				number = players[pid].IP

				irc_QueueMsg(irc_params[1], "Checking DNS record for " .. pid .. " IP " .. number)
				CheckBlacklist(pid, number)
			end

			irc_QueueMsg(irc_params[1], "")											
			return
		end	

		if debug then dbug("debug ircmessage 4") end
	
		if words[1] == "view" and words[2] == "alerts" then
			if debug then dbug("debug ircmessage " .. msg) end
			if number == nil then number = 20 end

			cursor,errorString = conn:execute("SELECT * FROM alerts order by alertID desc limit " .. number)
			if cursor:numrows() == 0 then
				irc_QueueMsg(irc_params[1], "There are no alerts recorded.")
			else
				irc_QueueMsg(irc_params[1], "The most recent alerts are:")
				row = cursor:fetch({}, "a")
				while row do
					msg = "On " .. row.timestamp .. " player " .. players[row.steam].name .. " at " .. row.x .. " " .. row.y .. " " .. row.z .. " said " .. row.message
					irc_QueueMsg(irc_params[1], msg)
					row = cursor:fetch(row, "a")	
				end
			end

			irc_QueueMsg(irc_params[1], "")											
			return
		end	

		if debug then dbug("debug ircmessage 5") end

		if words[1] == "show" and words[2] == "inventory" then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			if words[3] == nil then
				irc_QueueMsg(irc_params[1], "Full example.. show inventory player Joe xpos 100 zpos 200 days 2 range 50 item tnt qty 20")
				irc_QueueMsg(irc_params[1], "You can grab the coords from any player by adding, near joe")
				irc_QueueMsg(irc_params[1], "Defaults: days = 1, range = 100km, xpos = 0, zpos = 0")
				irc_QueueMsg(irc_params[1], "Optional: player (or near) joe, days 1, hours 1, range 50, item tin, qty 10, xpos 0, zpos 0, session 1")
				irc_QueueMsg(irc_params[1], "")
				return
			end

			name1 = nil
			pid = nil
			days = 1
			hours = 0
			range = 100000
			item = nil
			xpos = 0
			zpos = 0
			qty = nil
			session = 0

			for i=3,wordCount,1 do
				if words2[i] == "player" then
					name1 = words2[i+1]
					pid = LookupPlayer(name1)
				end					
					
				if words2[i] == "days" then
					days = tonumber(words2[i+1])
				end								

				if words2[i] == "hours" then
					hours = tonumber(words2[i+1])
					days = 0
				end								

				if words2[i] == "range" then
					range = tonumber(words2[i+1])
				end	

				if words2[i] == "item" then
					item = words2[i+1]
				end	

				if words2[i] == "qty" then
					qty = words2[i+1]
				end	

				if words2[i] == "xpos" then
					xpos = tonumber(words2[i+1])
				end	

				if words2[i] == "zpos" then
					zpos = tonumber(words2[i+1])
				end	

				if words2[i] == "session" then
					session = words2[i+1]
				end	

				if words2[i] == "near" then
					name2 = words2[i+1]
					pid2 = LookupPlayer(name2)

					if pid2 ~= nil then
						xpos = players[pid2].xPos
						zpos = players[pid2].zPos
					end
				end		
			end

			if days == 0 then
				sql = "SELECT * FROM inventoryChanges WHERE abs(x - " .. xpos .. ") <= " .. range .. " AND abs(z - " .. zpos .. ") <= " .. range .. " AND timestamp >= '" .. os.date("%Y-%m-%d %H:%M:%S", os.time() - (tonumber(hours) * 3600)) .. "' "
			else
				sql = "SELECT * FROM inventoryChanges WHERE abs(x - " .. xpos .. ") <= " .. range .. " AND abs(z - " .. zpos .. ") <= " .. range .. " AND timestamp >= '" .. os.date("%Y-%m-%d %H:%M:%S", os.time() - (tonumber(days) * 86400)) .. "' "
			end

			if session ~= 0 then
				sql = "SELECT * FROM inventoryChanges WHERE abs(x - " .. xpos .. ") <= " .. range .. " AND abs(z - " .. zpos .. ") <= " .. range .. " AND session = " .. session .. " "
			end

			if pid ~= nil then
				sql = sql .. "AND steam = " .. pid .. " "
			end

			if qty ~= nil then
				if tonumber(qty) > 0 then
					sql = sql .. "AND delta > " .. qty .. " "
				else
					sql = sql .. "AND delta < " .. qty .. " "
				end
			end

			if item ~= nil then
				sql = sql .. "AND item like '%" .. item .. "%'"
			end

			irc_QueueMsg(irc_params[1], "Inventory tracking data for query:")
			irc_QueueMsg(irc_params[1], sql)

			cursor,errorString = conn:execute(sql)
			if cursor:numrows() == 0 then
				irc_QueueMsg(irc_params[1], "No inventory tracking is recorded for your search parameters.")
			else
				irc_QueueMsg(irc_params[1], "")
				irc_QueueMsg(irc_params[1], "   id   |      steam       |      timestamp     |    item     | qty | x y z | session | name")
				row = cursor:fetch({}, "a")

				rows = cursor:numrows()

				if rows > 50 then
					irc_QueueMsg(name, "***** Report length " .. rows .. " rows.  Cancel it with: nuke irc *****")
				end

				while row do
					msg = row.id .. ", " .. row.steam .. ", " .. row.timestamp .. ", " .. row.item .. ", " .. row.delta .. ", " .. row.x .. " " .. row.y .. " " .. row.z .. ", " .. row.session .. ", " .. players[row.steam].name
					irc_QueueMsg(irc_params[1], msg)
					row = cursor:fetch(row, "a")	
				end
			end

			irc_QueueMsg(irc_params[1], "")
			return
		end

		if debug then dbug("debug ircmessage 6") end

		if words[1] == "announcements" then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			counter = 1
			cursor,errorString = conn:execute("SELECT * FROM announcements")
			if cursor:numrows() == 0 then
				irc_QueueMsg(irc_params[1], "There are no announcements recorded.")
			else
				irc_QueueMsg(irc_params[1], "The server announcements are:")
				row = cursor:fetch({}, "a")
				while row do
					msg = "Announcement (" .. counter .. ") " .. row.message
					counter = counter + 1
					irc_QueueMsg(irc_params[1], msg)
					row = cursor:fetch(row, "a")	
				end
			end

			irc_QueueMsg(irc_params[1], "")
			return
		end

		if debug then dbug("debug ircmessage 7") end

		if words[1] == "add" and words[2] == "announcement" and words[3] ~= nil then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			msg = string.sub(msg, 17, string.len(msg))

			conn:execute("INSERT INTO announcements (message, startdate, enddate) VALUES ('" .. escape(msg) .. "'," .. os.date("%Y-%m-%d", os.time()) .. ",'2020-01-01')")

			irc_QueueMsg(irc_params[1], "New announcement added.")
			irc_QueueMsg(irc_params[1], "")
			return
		end

		if debug then dbug("debug ircmessage 8") end

		if words[1] == "delete" and words[2] == "announcement" and words[3] ~= nil then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			counter = 1
			cursor,errorString = conn:execute("SELECT * FROM announcements")
			row = cursor:fetch({}, "a")
			while row do
				if tonumber(number) == counter then
					conn:execute("DELETE FROM announcements WHERE id = " .. row.id)
				end

				counter = counter + 1
				row = cursor:fetch(row, "a")	
			end

			irc_QueueMsg(irc_params[1], "Announcement " .. number .. " deleted.")
			irc_QueueMsg(irc_params[1], "")
			return
		end

		if debug then dbug("debug ircmessage 9") end

		if (words[1] == "who" and words[2] == "visited") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end
			
			if words[3] == nil then
				irc_QueueMsg(irc_params[1], "See who visited a player location or base.")
				irc_QueueMsg(irc_params[1], "Example with defaults:  who visited smeg days 1 range 10 height 4")
				irc_QueueMsg(irc_params[1], "Example with coords:  who visited xpos 0 zpos 0 ypos 100 height 5 days 1 range 20")
				irc_QueueMsg(irc_params[1], "Setting hours will reset days to zero")						
				irc_QueueMsg(irc_params[1], "Defaults: days = 1 or hours = 0, range = 10")
				irc_QueueMsg(irc_params[1], "To see who visited a player's bases add bases at the end.  To report at players position and bases add all.")
				irc_QueueMsg(irc_params[1], "")
				return
			end			

			-- irc_params[1] == irc user
			-- irc_params[2] == target steam id
			-- irc_params[3] == distance (optional default=10
			-- irc_params[4] == days (optional default=1

			-- optional params
				-- range <distance in metres> Default 10
				-- days.  Default is 1 day ago from today (local time not server)

			if words[3] ~= "player" then
				name1 = string.trim(words[3])
			else
				name1 = string.trim(words[4])
			end

			pid = LookupPlayer(name1)
			days = 1
			hours = 0
			range = 10
			basesOnly = "player"

			if pid ~= nil then
				xpos = players[pid].xPos
				ypos = players[pid].yPos
				zpos = players[pid].zPos
			end

			for i=3,wordCount,1 do
				if words[i] == "range" then
					range = tonumber(words[i+1])
				end					
					
				if words[i] == "days" then
					days = tonumber(words[i+1])
					hours = 0
				end								

				if words[i] == "hours" then
					hours = tonumber(words[i+1])
					days = 0
				end								

				if words[i] == "base" then
					baseOnly = "base"
				end	

				if words[i] == "all" then
					baseOnly = "all"
				end	

				if words[i] == "xpos" then
					xpos = tonumber(words[i+1])
				end	

				if words[i] == "ypos" then
					ypos = tonumber(words[i+1])
				end	

				if words[i] == "zpos" then
					zpos = tonumber(words[i+1])
				end	

				if words[i] == "height" then
					height = tonumber(words[i+1])
				end	
			end

			if basesOnly == "base" or basesOnly == "all" then
				if players[pid].homeX ~= 0 and players[pid].homeZ ~= 0 then
					irc_QueueMsg(irc_params[1], "Players who visited within " .. range .. " metres of base 1 of " .. players[pid].name)
					dbWho(irc_params[1], players[pid].homeX, players[pid].homeY, players[pid].homeZ, range, days, hours, height)
				else
					irc_QueueMsg(irc_params[1], "Player " .. players[pid].name .. " does not have a base set.")
				end

				if players[pid].home2X ~= 0 and players[pid].home2Z ~= 0 then
					irc_QueueMsg(irc_params[1], "")
					irc_QueueMsg(irc_params[1], "Players who visited within " .. range .. " metres of base 2 of " .. players[pid].name)
					dbWho(irc_params[1], players[pid].home2X, players[pid].home2Y, players[pid].home2Z, range, days, hours, height)
				end
			end

			if basesOnly == "player" or basesOnly == "all" then
				irc_QueueMsg(irc_params[1], "Players who visited within " .. range .. " metres (X) " .. players[pid].xPos .. " (Z) " .. players[pid].zPos .. " of player " .. players[pid].name)
				dbWho(irc_params[1], players[pid].xPos, players[pid].yPos, players[pid].zPos, range, days, hours, height)
			end

			irc_QueueMsg(irc_params[1], "")

			return
		end

		if debug then dbug("debug ircmessage 10") end

		if (words[1] == "pay") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			name1 = string.sub(msg, string.find(msg, " to ") + 4, string.len(msg))
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			players[pid].cash = players[pid].cash + number		
			message("pm " .. pid .. " " .. players[ircid].name .. " just paid you " .. number .. " zennies!  You now have " .. players[pid].cash .. " zennies!  KA-CHING!!")

			msg = "You just paid " .. number .. " zennies to " .. players[pid].name .. " giving them a total of " .. players[pid].cash .. " zennies."
			irc_QueueMsg(irc_params[1], msg)
			return
		end

		if debug then dbug("debug ircmessage 11") end

		if (words[1] == "claims") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			pid = nil

			if (words[2] ~= nil) then
				name1 = string.sub(msg, string.find(msgLower, "claims") + 7)
				name1 = string.trim(name1)
				pid = LookupPlayer(name1)
			end

			if pid ~= nil then
				if players[pid].keystones == 0 then
					msg = players[pid].name .. " has not placed any claims."
  					irc_QueueMsg(irc_params[1], msg)
					return
				end
			end


			if pid == nil then
				for k, v in pairs(players) do
					if tonumber(v.keystones) > 0 then
						msg = v.keystones .. "   claims belong to " .. k .. " " .. v.name
						irc_QueueMsg(irc_params[1], msg)
					end
				end
			else
				msg = players[pid].name .. " has placed " .. players[pid].keystones .. " at these coordinates.."
				irc_QueueMsg(irc_params[1], msg)

				cursor,errorString = conn:execute("SELECT * FROM keystones WHERE steam = " .. pid)
				row = cursor:fetch({}, "a")
				while row do
					msg = row.x .. " " .. row.y .. " " .. row.z
					irc_QueueMsg(irc_params[1], msg)
					row = cursor:fetch(row, "a")	
				end
			end

			irc_QueueMsg(irc_params[1], "")
			return
		end

		if debug then dbug("debug ircmessage 12") end

		if (words[1] == "cmd") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			msg = string.trim(string.sub(msg, string.find(msgLower, "cmd") + 4))
			gmsg(msg, ircid)
			return
		end

		if debug then dbug("debug ircmessage 13") end

		if (words[1] == "pm") then
			if debug then dbug("debug ircmessage " .. msg) end

			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			pid = LookupPlayer(words[2])

			if pid ~= nil then
				msg = string.sub(msg, string.find(msg, words2[2], nil, true) + string.len(words2[2]) + 1)

				if igplayers[pid] then
					message("pm " .. pid .. " " .. name .. "-irc: [i]" .. msg .. "[-]")
					irc_QueueMsg(name, "pm sent to " .. players[pid].name .. " you said " .. msg)
				else
					conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (" .. ircid .. "," .. pid .. ", '" .. escape(msg) .. "')")
					irc_QueueMsg(name, "Mail sent to " .. players[pid].name .. " you said " .. msg)
					irc_QueueMsg(name, "They will receive your message when they join the server.")
				end
			else
				irc_QueueMsg(name, "No player called " .. words[2] .. " found.")
			end

			return
		end

		if debug then dbug("debug ircmessage 14") end

-- ************************************************************************************************8
		if (words[1] == "con") and accessLevel(ircid) < 3 then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			msg = string.lower(string.trim(string.sub(msg, string.find(msgLower, "con") + 4)))
			send(msg)

			if string.sub(msg, 1, 4) == "help" then
				echoConsoleTo = name
				tempTimer( 2, [[ echoConsoleTo = nil ]] )
				tempTimer( 2, [[ echoConsole = nil ]] )
			end

			if msg == "se" or msg == "ban list" or msg == "gg" or string.sub(msg, 1, 3) == "si " or string.sub(msg, 1, 3) == "llp" then
				echoConsoleTo = name
				echoConsoleTrigger = ""

				if string.sub(msg, 1, 3) == "si " then
					echoConsoleTrigger = string.sub(msg, 4)
				end

				tempTimer( 2, [[ echoConsoleTo = nil ]] )
				tempTimer( 2, [[ echoConsole = nil ]] )
			end

			return
		end
-- ************************************************************************************************

		if debug then dbug("debug ircmessage 15") end

		if (words[1] == "villagers" and words[2] == nil) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_List_Villagers(name)
			return
		end

		if debug then dbug("debug ircmessage 16") end

		if (words[1] == "base") and (words[2] == "cooldown" or words[2] == "timer") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			if words[3] == nil then
				table.insert(irc_params, "/base can only be used once every " .. (server.baseCooldown / 60) .. " minutes for players and " .. math.floor((server.baseCooldown / 60) / 2) .. " minutes for donors.")
				irc_message()
				return
			end

			if words[3] ~= nil then
				server.baseCooldown = tonumber(words[3])
				table.insert(irc_params, " The base cooldown timer is now " .. (server.baseCooldown / 60) .. " minutes for players and " .. math.floor((server.baseCooldown / 60) / 2) .. " minutes for donors.")
				irc_message()

				conn:execute("UPDATE server SET baseCooldown = 0")
				return
			end
		end

		if debug then dbug("debug ircmessage 17") end

		if (words[1] == "set" and words[2] == "rules") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			if words[3] ~= nil then
				server.rules = string.sub(msg, string.find(msgLower, "set rules") + 9)
				table.insert(irc_params, "New server rules recorded. " .. server.rules)
				irc_message()

				conn:execute("UPDATE server SET rules = '" .. server.rules .. "'")
				return
			end
		end

		if debug then dbug("debug ircmessage 18") end

		if (words[1] == "motd") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			if words[2] == nil then
				table.insert(irc_params, "MOTD is " .. server.MOTD)
				irc_message()
				return
			end

			if words[2] == "delete" or words[2] == "clear" then
				server.MOTD = nil
				table.insert(irc_params, "Message of the day has been deleted.")
				irc_message()

				conn:execute("UPDATE server SET MOTD = ''")
				return
			end

			table.insert(irc_params, "To change the MOTD type set motd <new message of the day>")
			irc_message()
			return
		end

		if debug then dbug("debug ircmessage 19") end

		if (words[1] == "set" and words[2] == "motd") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			if words[3] ~= nil then
				server.MOTD = string.sub(msg, string.find(msgLower, "set motd") + 9)
				table.insert(irc_params, "New message of the day recorded. " .. server.MOTD)
				irc_message()

				conn:execute("UPDATE server SET MOTD = '" .. server.MOTD .. "'")
				return
			end
		end

		if debug then dbug("debug ircmessage 20") end

		if (words[1] == "list") and (words[2] == "tables") and (words[3] == nil) and (accessLevel(ircid) == 0) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_ListTables()
			return
		end

		if debug then dbug("debug ircmessage 21") end

		if (words[1] == "show") and (words[2] == "table") and (words[3] ~= nil) and (accessLevel(ircid) == 0) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "table") + 6))
			table.insert(irc_params, name1)
			irc_ShowTable()
			return
		end

		if debug then dbug("debug ircmessage 22") end

		if (words[1] == "reset") and (words[2] == "bot") and (accessLevel(ircid) == 0) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end
			
			irc_params = {}
			table.insert(irc_params, server.ircMain)
			
			if resetbotCount == nil then resetbotCount = 0 end
			
			if tonumber(resetbotCount) < 2 then
				resetbotCount = tonumber(resetbotCount) + 1
				table.insert(irc_params, "ALERT! Only do this after a server wipe!  To reset me repeat the reset bot command again.")
			end

			ResetBot()
			
			resetbotCount = 0

			table.insert(irc_params, "I have been reset.  All bases, inventories etc are forgotten, but not the players.")
			irc_message()
			return
		else
			resetbotCount = 0
		end

		if debug then dbug("debug ircmessage 23") end

		if words[1] == "stop" and words[2] == "translating" and words[3] ~= nil then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.sub(msg, string.find(msgLower, "translating") + 11)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				players[pid].ircTranslate = nil
				players[pid].translate = nil
				table.insert(irc_params, "Chat from " .. players[pid].name .. " will not be translated")
				irc_message()

				conn:execute("UPDATE players SET translate = 0, ircTranslate = 0 WHERE steam = " .. pid)
			else
				table.insert(irc_params, "No player found matching " .. name1)
				irc_message()
			end

			return
		end

		if debug then dbug("debug ircmessage 24") end

		if words[1] == "translate" and words[2] ~= nil then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.sub(msg, string.find(msgLower, "translate") + 10)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				players[pid].translate = true
				table.insert(irc_params, "Chat from " .. players[pid].name .. " will be translated in-game")
				irc_message()

				conn:execute("UPDATE players SET translate = 1 WHERE steam = " .. pid)
			else
				table.insert(irc_params, "No player found matching " .. name1)
				irc_message()
			end

			return
		end

		if debug then dbug("debug ircmessage 25") end

		if words[1] == "stealth" and words[2] == "translate" and words[3] ~= nil then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.sub(msg, string.find(msgLower, "translate") + 10)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				players[pid].ircTranslate = true
				table.insert(irc_params, "Chat from " .. players[pid].name .. " will be translated to irc only")
				irc_message()

				conn:execute("UPDATE players SET ircTranslate = 1 WHERE steam = " .. pid)
			else
				table.insert(irc_params, "No player found matching " .. name1)
				irc_message()
			end

			return
		end
		
		if debug then dbug("debug ircmessage 26") end
		
		if (words[1] == "open" and words[2] == "shop") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			server.allowShop = true
			
			table.insert(irc_params, "Players can use the shop and play in the lottery.")
			irc_message()

			conn:execute("UPDATE server SET allowShop = 1")
			return
		end			
		
		if debug then dbug("debug ircmessage 27") end
		
		if (words[1] == "close" and words[2] == "shop") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			server.allowShop = false
			
			table.insert(irc_params, "Only staff can use the shop.")
			irc_message()

			conn:execute("UPDATE server SET allowShop = 0")
			return
		end					

		if debug then dbug("debug ircmessage 28") end

		if (words[1] == "shop" and words[2] == "variation" and words[3] ~= nil) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			LookupShop(words[3])

			table.insert(irc_params, "You have changed the price variation for " .. shopItem .. " to " .. words2[4])
			irc_message()

			conn:execute("UPDATE shop SET variation = " .. tonumber(words2[4]) .. " WHERE item = '" .. escape(shopItem) .. "'")
			return
		end	

		if debug then dbug("debug ircmessage 29") end

		if (words[1] == "shop" and words[2] == "special" and words[3] ~= nil) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			LookupShop(words[3], true)
			
			if shopItem == "" then
				irc_QueueMsg(irc_params[1], "The item " .. words[3] .. " does not exist.")			
				return
			end

			table.insert(irc_params, "You have changed the special for " .. shopItem .. " to " .. words2[4])
			irc_message()

			conn:execute("UPDATE shop SET special = " .. tonumber(words2[4]) .. " WHERE item = '" .. escape(shopItem) .. "'")
			return
		end	

		if debug then dbug("debug ircmessage 30") end

		if (words[1] == "shop" and words[2] == "price" and words[3] ~= nil) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			LookupShop(words[3], true)
			
			if shopItem == "" then
				irc_QueueMsg(irc_params[1], "The item " .. words[3] .. " does not exist.")			
				return
			end			

			table.insert(irc_params, "You have changed the price for " .. shopItem .. " to " .. words2[4])
			irc_message()

			conn:execute("UPDATE shop SET price = " .. tonumber(words2[4]) .. " WHERE item = '" .. escape(shopItem) .. "'")
			return
		end	

		if debug then dbug("debug ircmessage 31") end

		if (words[1] == "shop" and words[2] == "max" and words[3] ~= nil) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			LookupShop(words[3], true)
			
			if shopItem == "" then
				irc_QueueMsg(irc_params[1], "The item " .. words[3] .. " does not exist.")			
				return
			end			

			table.insert(irc_params, "You have changed the max stock level for " .. shopItem .. " to " .. words[4])
			irc_message()

			conn:execute("UPDATE shop SET maxStock = " .. tonumber(words2[4]) .. " WHERE item = '" .. escape(shopItem) .. "'")
			return
		end	

		if debug then dbug("debug ircmessage 32") end

		if (words[1] == "shop" and words[2] == "restock" and words[3] ~= nil) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			LookupShop(wordsOld[3], true)
			shopStock = tonumber(words2[4])
			
			if shopItem == "" then
				irc_QueueMsg(irc_params[1], "The item " .. wordsOld[3] .. " does not exist.")			
				return
			end

			if (shopStock < 0) then
				shopStock = -1
				irc_QueueMsg(irc_params[1], shopItem .. " now has unlimited stock")
			else
				irc_QueueMsg(irc_params[1], "There are now " .. shopStock .. " of " .. shopItem .. " for sale.")
			end

			conn:execute("UPDATE shop SET stock = " .. shopStock .. " WHERE item = '" .. escape(shopItem) .. "'")
			return
		end
		
		if debug then dbug("debug ircmessage 33") end
		
		if (words[1] == "shop" and words[2] == "add" and words[3] == "category") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end		

			shopCategories[words[4]] = {}
			
			for i=2,wordCount,1 do 			
				if words[i] == "code" then
					shopCategories[words[4]].code  = words[i+1]
					shopCategories[words[4]].index = 1

					conn:execute("INSERT INTO shopCategories (category, idx, code) VALUES ('" .. escape(words[4]) .. "',1,'" .. escape(words[i+1]) .. "')")
				end					
			end

			if (shopCategories[words[4]].code == nil) then
				irc_QueueMsg(irc_params[1], "A code is required. Do not include numbers in the code.")
				return
			end
			
			irc_QueueMsg(irc_params[1], "You added or updated the category " .. words[4] .. ".")
			return
		end	

		if debug then dbug("debug ircmessage 34") end
		
		if (words[1] == "shop" and words[2] == "remove" and words[3] == "category") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end
			
			if not shopCategories[words[4]] then
				irc_QueueMsg(irc_params[1], "The category " .. words[4] .. " does not exist.")
				return
			end

			shopCategories[words[4]] = nil
			conn:execute("DELETE FROM shopCategories WHERE category = '" .. escape(words[4]) .. "')")
			conn:execute("UPDATE shop SET category = '' WHERE category = '" .. escape(words[4]) .. "')")
			
			irc_QueueMsg(irc_params[1], "You removed the " .. words[4] .. " category from the shop.  Any items using it now have no category.")
			return
		end			
		
		if debug then dbug("debug ircmessage 35") end
		
		if (words[1] == "shop" and words[2] == "change" and words[3] == "category") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			if words[5] == "to" then
				oldCategory = words[4]
				newCategory = words[6]
			else
				oldCategory = words[4]			
				newCategory = words[5]				
			end
			
			if not shopCategories[oldCategory] then
				irc_QueueMsg(irc_params[1], "The category " .. words[4] .. " does not exist.")
				return
			end
		
			shopCategories[oldCategory] = nil
			shopCategories[newCategory] = {}

			conn:execute("UPDATE shopCategories SET category = '" .. escape(newCategory) .. "' WHERE category = '" .. escape(oldCategory) .. "')")
			conn:execute("UPDATE shop SET category = '" .. escape(newCategory) .. "' WHERE category = '" .. escape(oldCategory) .. "')")
			
			for i=2,wordCount,1 do 			
				if words[i] == "code" then
					shopCategories[newCategory].code  = words[i+1]
				end					
			end
			
			irc_QueueMsg(irc_params[1], "You changed category " .. oldCategory .. " to " .. newCategory .. ". Any items using " .. oldCategory .. " have been updated.")
			return
		end		

		if debug then dbug("debug ircmessage 36") end

		if (words[1] == "inv") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "inv") + 4))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				table.insert(irc_params, pid)
				table.insert(irc_params, players[pid].name)
				irc_NewInventory(pid)
			end

			return
		end
		
		if debug then dbug("debug ircmessage 37") end

		if (words[1] == "list" and words[2] == "villagers" and words[3] ~= nil) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			name1 = string.sub(msg, string.find(msgLower, "villagers") + 10)
			name1 = string.trim(name1)
			pid = LookupVillage(name1)

			if (pid ~= nil) then
				table.insert(irc_params, pid)
				table.insert(irc_params, players[pid].name)
				irc_ListVillagers()
			else	
				table.insert(irc_params, "No village found matching " .. name1)
				irc_message()
			end

			return
		end

		if debug then dbug("debug ircmessage 38") end

		if words[1] == "list" and (words[2] == "bases" or words[3] == "bases") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			pid = nil
			for i=2,wordCount,1 do
				if words[i] == "bases" then
					pid = words[i+1]
				end	
			end

			if words[2] == "protected" then
				table.insert(irc_params, "protected")
			else
				table.insert(irc_params, "all")
			end

			if pid ~= nil then
				pid = LookupPlayer(pid)
			end

			irc_ListBases(pid)

			return
		end

		if debug then dbug("debug ircmessage 39") end

		if (words[1] == "add" and words[2] == "bad" and words[3] == "item" and words[4] ~= nil and accessLevel(ircid) == 0) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			name1 = wordsOld[4]

			-- add the bad item to badItems table
			badItems[name1] = {}

			conn:execute("INSERT INTO badItems (item) VALUES ('" .. escape(name1) .. "')")

			table.insert(irc_params, name1 .. " has been added to the bad items list.")
			irc_message()

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			table.insert(irc_params, name1 .. " has been added to the bad items list.")
			irc_message()

			return
		end

		if debug then dbug("debug ircmessage 40") end

		if (words[1] == "remove" and words[2] == "bad" and words[3] == "item" and words[4] ~= nil and accessLevel(ircid) == 0) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			name1 = wordsOld[4]

			-- remove the bad item from the badItems table
			badItems[name1] = nil

			conn:execute("DELETE FROM badItems WHERE item = '" .. escape(name1) .. "'")

			table.insert(irc_params, name1 .. " has been removed from the bad items list.")
			irc_message()

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			table.insert(irc_params, name1 .. " has been removed from the bad items list.")
			irc_message()

			return
		end

		if debug then dbug("debug ircmessage 41") end

		if (words[1] == "near") then	
			if debug then dbug("debug ircmessage " .. msg) end	
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			if words[2] == nil then
				irc_QueueMsg(name, "Lists players, bases and locations near a player or coordinate.")
				irc_QueueMsg(name, "Usage: near player <name>")
				irc_QueueMsg(name, "optional: range <number>")
				irc_QueueMsg(name, "optional: Instead of player use xpos <number> zpos <number>")

			end
			
			name1 = nil
			range = 200
			xPos = 0
			zPos = 0
			offline = false
			
			for i=2,wordCount,1 do
				if words[i] == "player" then
					name1 = words[i+1]
				end	

				if words[i] == "range" then
					range = tonumber(words[i+1])
				end	

				if words[i] == "xpos" then
					xPos = tonumber(words[i+1])
				end	

				if words[i] == "zpos" then
					zPos = tonumber(words[i+1])
				end	

				if words[i] == "offline" then
					offline = true
				end	
			end			
	
			if name1 ~= nil then
				name1 = string.trim(name1)
				name1 = LookupPlayer(name1)

				if name1 == nil then
					irc_QueueMsg(name, "No player found matching " .. name1)
					return
				end
			end

			if name1 == nil then
				irc_PlayersNearPlayer(name, "", range, xPos, zPos, offline)
				irc_BasesNearPlayer(name, "", range, xPos, zPos)
				irc_LocationsNearPlayer(name, "", range, xPos, zPos)
			else
				irc_PlayersNearPlayer(name, name1, range, xPos, zPos, offline)
				irc_BasesNearPlayer(name, name1, range, xPos, zPos)
				irc_LocationsNearPlayer(name, name1, range, xPos, zPos)
			end

			return
		end

		if debug then dbug("debug ircmessage 42") end

		if (words[1] == "bases" or words[1] == "homes") and words[2] == "near" and words[3] ~= nil then	
			if debug then dbug("debug ircmessage " .. msg) end	
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			if string.find(msgLower, "range") then
				name1 = string.sub(msg, string.find(msgLower, "near") + 5, string.find(msgLower, "range") - 1)
				number = string.sub(msg, string.find(msgLower, "range") + 6)
			else
				name1 = string.sub(msg, string.find(msgLower, "near") + 5)
			end

			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				table.insert(irc_params, pid)
				table.insert(irc_params, players[pid].name)
				if string.find(msgLower, "range") then
					table.insert(irc_params, number)
				end

				irc_BasesNearPlayer()
			else	
				table.insert(irc_params, "No player found matching " .. name1)
				irc_message()
			end

			return
		end

		if debug then dbug("debug ircmessage 43") end

		if (words[1] == "info" and words[2] ~= nil) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			name1 = string.sub(msg, string.find(msgLower, "info") + 5)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				table.insert(irc_params, pid)
				table.insert(irc_params, players[pid].name)
				irc_PlayerShortInfo()
				irc_friends()
			else	
				table.insert(irc_params, "No player found matching " .. name1)
				irc_message()
			end

			return
		end

		if debug then dbug("debug ircmessage 44") end

		if (words[1] == "add" and words[2] == "donor" and words[3] ~= nil and owners[ircid]) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.sub(msg, string.find(msgLower, "donor") + 6)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- update the player record
				players[pid].donor = true
				table.insert(irc_params, players[pid].name .. " is now a donor.")
				irc_message()

				conn:execute("UPDATE players SET donor = 1 WHERE steam = " .. pid)
			end

			return
		end

		if debug then dbug("debug ircmessage 45") end

		if (words[1] == "remove" and words[2] == "donor" and words[3] ~= nil and owners[ircid]) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.sub(msg, string.find(msgLower, "donor") + 6)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- update the player record
				players[pid].donor = false
				table.insert(irc_params, players[pid].name .. " is no longer a donor.")
				irc_message()

				conn:execute("UPDATE players SET donor = 0 WHERE steam = " .. pid)
			end

			return
		end

		if debug then dbug("debug ircmessage 46") end

		if (words[1] == "add" and words[2] == "owner" and words[3] ~= nil and owners[ircid]) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.sub(msg, string.find(msgLower, "owner") + 6)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- add the steamid to the owners table
				owners[pid] = {}
				table.insert(irc_params, players[pid].name .. " has been added as a server owner.")
				irc_message()

				send("admin add " .. pid .. " 0")
			end

			return
		end

		if debug then dbug("debug ircmessage 47") end

		if (words[1] == "remove" and words[2] == "owner" and words[3] ~= nil and owners[ircid]) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.sub(msg, string.find(msgLower, "owner") + 6)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- remove the steamid from the owners table
				owners[pid] = nil
				table.insert(irc_params, players[pid].name .. " is no longer a server owner.")
				irc_message()

				send("admin remove " .. pid)
			end

			return
		end

		if debug then dbug("debug ircmessage 48") end

		if (words[1] == "add" and words[2] == "admin" and words[3] ~= nil and owners[ircid]) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.sub(msg, string.find(msgLower, "admin") + 6)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- add the steamid to the admins table
				admins[pid] = {}
				table.insert(irc_params, players[pid].name .. " has been added as a server admin.")
				irc_message()

				send("admin add " .. pid .. " 1")
			end
		
			return
		end

		if debug then dbug("debug ircmessage 49") end

		if (words[1] == "remove" and words[2] == "admin" and words[3] ~= nil and accessLevel(ircid) == 0) then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.sub(msg, string.find(msgLower, "admin") + 6)
			name1 = string.trim(name1)

			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- remove the steamid from the admins table
				admins[pid] = nil
				table.insert(irc_params, players[pid].name .. " is no longer a server admin.")
				irc_message()

				send("admin remove " .. pid)
			end

			return
		end

		if debug then dbug("debug ircmessage 50") end

		if (words[1] == "permaban") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.trim(string.sub(msg, string.find(msgLower, "permaban") + 9))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				table.insert(irc_params, pid)
				table.insert(irc_params, players[pid].name)
			else
				if (string.len(name1) == 17) then
					banPlayer(pid, "10 years", "Permanent ban", ircid)

					table.insert(irc_params, name1 .. " banned 10 years.")
					irc_message()

					conn:execute("UPDATE players SET permanentBan = 1 WHERE steam = " .. pid)
					players[pid].permanentBan = true
				else
					table.insert(irc_params, "No player found matching " .. name1)
					irc_message()
				end
			end
			return
		end

		if debug then dbug("debug ircmessage 51") end

		if (words[1] == "remove" and words[2] == "permaban") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.trim(string.sub(msg, string.find(msgLower, "permaban") + 9))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				table.insert(irc_params, pid)
				table.insert(irc_params, players[pid].name)

				conn:execute("UPDATE players SET permanentBan = 0 WHERE steam = " .. pid)
				send("ban remove " .. pid)
				players[pid].permanentBan = false

				table.insert(irc_params, "Ban lifted for player " .. name1)
				irc_message()
			else	
				table.insert(irc_params, "No player found matching " .. name1)
				irc_message()
			end
			return
		end

		if debug then dbug("debug ircmessage 52") end

		if (words[1] == "add" and words[2] == "player") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			for i=3,wordCount,1 do 					
				if words[i] == "login" then
					login = words[i+1]
				end					
			end

 			name1 = string.trim(string.sub(msg, string.find(msgLower, "player ") + 7, string.find(msgLower, " login") - 1))
			result = false

			for k, v in pairs(players) do
				if (login == v.ircPass) then
					result = true
					break
				end
			end

			if (result == true) then
				table.insert(irc_params, "That password is already in use.  Please choose another.")
				tempTimer( 2, [[irc_message()]] )	
				return
			end

			pid = LookupOfflinePlayer(name1, "all")
			if (pid ~= nil) then
				players[pid].ircPass = login
				players[pid].ircAuthenticated = false

				table.insert(irc_params, players[pid].name .. " is now authorised to talk to ingame players")
				irc_message()
				conn:execute("UPDATE players SET ircPass = '" .. escape(login) .. "' WHERE steam = " .. pid)
			end

			return
		end

		if debug then dbug("debug ircmessage 53") end

		if (words[1] == "player" and string.find(msgLower, "unfriend")) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, "unfriend") - 1))
			name2 = string.trim(string.sub(msg, string.find(msgLower, "unfriend") + 9))

			pid = LookupPlayer(name1)
			if (pid ~= nil) then
				table.insert(irc_params, pid)
				pid = LookupPlayer(name2)
				if (pid ~= nil) then
					table.insert(irc_params, pid)
					irc_unfriend()
				else	
					table.insert(irc_params, "No player found matching " .. name2)
					irc_message()
				end
			else
				table.insert(irc_params, "No player found matching " .. name1)
				irc_message()
			end

			return
		end

		if debug then dbug("debug ircmessage 54") end

		if (words[1] == "player" and string.find(msgLower, "friend")) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, "friend") - 1))
			name2 = string.trim(string.sub(msg, string.find(msgLower, "friend") + 7))

			pid = LookupPlayer(name1)
			if (pid ~= nil) then
				table.insert(irc_params, pid)
				pid = LookupPlayer(name2)
				if (pid ~= nil) then
					table.insert(irc_params, pid)
					irc_friend()
				else	
					table.insert(irc_params, "No player found matching " .. name2)
					irc_message()
				end
			else
				table.insert(irc_params, "No player found matching " .. name1)
				irc_message()
			end

			return
		end

		if debug then dbug("debug ircmessage 55") end

		if (words[1] == "friends") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "friends") + 8))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				table.insert(irc_params, pid)
				table.insert(irc_params, players[pid].name)
				irc_friends()
			else	
				table.insert(irc_params, "No player found matching " .. name1)
				irc_message()
			end
			return
		end

		if debug then dbug("debug ircmessage 56") end

		if (words[1] == "players" and words[2] == nil) and accessLevel(ircid) == 0 then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_listAllPlayers(name)
			return
		end

		if debug then dbug("debug ircmessage 57") end

		if (words[1] == "player") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7))
			pid = LookupOfflinePlayer(name1)

			if (pid ~= nil) then
				table.insert(irc_params, pid)
				table.insert(irc_params, players[pid].name)
				irc_PlayerInfo()
			end
			return
		end

		if debug then dbug("debug ircmessage 58") end

		if (words[1] == "igplayer") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "igplayer") + 9))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				table.insert(irc_params, pid)
				table.insert(irc_params, players[pid].name)
				irc_IGPlayerInfo()
			end
			return
		end

		if debug then dbug("debug ircmessage 59") end

		if (words[1] == "watch") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.trim(string.sub(msg, string.find(msgLower, "watch") + 6))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				players[pid].watchPlayer = true

				conn:execute("UPDATE players SET watchPlayer = 1 WHERE steam = " .. pid)
	
				table.insert(irc_params, "Now watching player " .. players[pid].name)
				irc_message()
			end
			return
		end

		if debug then dbug("debug ircmessage 60") end

		if (words[1] == "stop" and words[2] == "watching") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_params = {}
			table.insert(irc_params, server.ircMain)

			name1 = string.trim(string.sub(msg, string.find(msgLower, "watching") + 9))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				players[pid].watchPlayer = false

				conn:execute("UPDATE players SET watchPlayer = 0 WHERE steam = " .. pid)
	
				table.insert(irc_params, "No longer watching player " .. players[pid].name)
				irc_message()
			else
				table.insert(irc_params, "No player matched " .. name1)
				irc_message()
			end
			return
		end

		if debug then dbug("debug ircmessage 61") end

		if (words[1] == "donors" and words[2] == nil) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_listDonors(name)
			return
		end

		if debug then dbug("debug ircmessage 62") end

		if (words[1] == "teleports" and words[2] == nil) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_teleports(name)
			return
		end

		if debug then dbug("debug ircmessage 63") end

		if (words[1] == "list" and words[2] == "bad" and words[3] == "items") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_uncraftables(name)
			return
		end

		if debug then dbug("debug ircmessage 64") end

		if (words[1] == "prisoners" and words[2] == nil) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_prisoners(name)			
			return
		end

		if debug then dbug("debug ircmessage 65") end

		if (words[1] == "li" and words[2] ~= nil) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			ircListItems = ircid
			send("li " .. words[2])
		end

		if debug then dbug("debug ircmessage 66") end

		if (words[1] == "status") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "status") + 7))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				table.insert(irc_params, pid)
				table.insert(irc_params, players[pid].name)
				irc_playerStatus()
			else	
				table.insert(irc_params, "No player found matching " .. name1)
				irc_message()
			end
			return
		end

		if debug then dbug("debug ircmessage 67") end
		
		if (words[1] == "shop" and words[2] == "add" and words[3] == "item" and words[4] ~= nil) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			LookupShop(wordsOld[4], "all")

			if shopCode ~= "" then
				irc_QueueMsg(irc_params[1], "The item " .. shopCode .. " already exists.")
			else		
				class = "misc"
				price = 10000
				stock = 0

				for i=4,wordCount,1 do 					
					if words[i] == "category" then
						class = words[i+1]
					end					
					
					if words[i] == "price" then
						price = tonumber(words[i+1])
					end					
					
					if words[i] == "stock" then
						stock = tonumber(words[i+1])
					end					
				end

				irc_QueueMsg(irc_params[1], "You added " .. wordsOld[4] .. " to the shop.  You will need to add any missing info such as code, category, price and quantity.")

				conn:execute("INSERT INTO shop (item, category, stock, maxStock, price) VALUES ('" .. escape(wordsOld[4]) .. "','" .. escape(class) .. "'," .. stock .. "," .. stock .. "," .. price .. ")")
				
				reindexShop(class)				
			end

			return
		end

		if debug then dbug("debug ircmessage 68") end
		
		if (words[1] == "shop" and words[2] == "remove" and words[3] == "item") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			LookupShop(wordsOld[4], "all")

			if shopCode ~= "" then
				conn:execute("DELETE FROM shop WHERE item = '" .. escape(wordsOld[4]) .. "'")
				reindexShop(shopCategory)		
				irc_QueueMsg(name, "You removed the item " .. wordsOld[4] .. " from the shop.")
			else
				irc_QueueMsg(irc_params[1], "The item " .. wordsOld[4] .. " does not exist.")
			end			

			return
		end	

		if debug then dbug("debug ircmessage 69") end

		if (words[1] == "add" and words[2] == "command" and accessLevel(ircid) < 3) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			cmd = words[3]

			if words[4] == "access" then
				number = tonumber(words[5])
			else
				number = 99
			end

			tmp = string.trim(string.sub(msg, string.find(msgLower, "message") + 8))

			if tmp == nil then
				irc_QueueMsg(name, "Bad command.  This is used to create commands that send a private message to the player. You can add an optional access level.  99 is the default.")
				irc_QueueMsg(name, "Valid access levels are 99 (everyone), 90 (regulars), 4 (donors), 2 (mods), 1 (admins) 0 (owners)")
				irc_QueueMsg(name, "These commands are searched after all other commands. If an identical command exists, it will be used instead. Test the commands you add.")
				irc_QueueMsg(name, "Correct syntax is: add command <command> access <99 to 0> message <private message>")
			end

			-- add the custom message to table customMessages
			conn:execute("INSERT INTO customMessages (command, message, accessLevel) VALUES ('" .. escape(cmd) .. "','" .. escape(tmp) .. "'," .. number .. ") ON DUPLICATE KEY UPDATE accessLevel = " .. number .. ", message = '" .. escape(tmp) .. "'")

			-- reload from the database
			loadCustomMessages()

			table.insert(irc_params, cmd .. " has been added to custom commands.")
			irc_message()
			return
		end

		if debug then dbug("debug ircmessage 70") end

		if (words[1] == "remove" and words[2] == "command" and accessLevel(ircid) < 3) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			cmd = words[3]

			-- remove the custom message from table customMessages
			conn:execute("DELETE FROM customMessages WHERE command = '" .. escape(cmd) .. "'")

			-- remove it from the Lua table
			customMessages[cmd] = nil

			table.insert(irc_params, cmd .. " has been removed from custom commands.")
			irc_message()
			return
		end

		if debug then dbug("debug ircmessage 71") end

		if (words[1] == "blacklist" and words[2] == "add" and accessLevel(ircid) < 3) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			pid = LookupPlayer(words[3])

			if pid ~= nil then
				banPlayer(pid, "10 years", "blacklisted", ircid)
				irc_QueueMsg(name, "Player " .. pid  .. " " .. players[pid].name .. " has been blacklisted 10 years.")
				return
			else
				banPlayer(words[3], "10 years", "blacklisted", ircid)
				irc_QueueMsg(name, "Player " .. pid .. " has been blacklisted 10 years.")
				return
			end
		end

		if debug then dbug("debug ircmessage 72") end

		if (words[1] == "blacklist" or words[1] == "ban" and words[2] == "remove" and accessLevel(ircid) < 3) then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			pid = LookupPlayer(words[3])
			if pid ~= nil then
				send("ban remove " .. pid)
				irc_QueueMsg(name, "Player " .. pid  .. " " .. players[pid].name .. " has been unbanned.")
				return
			end
		end

		if debug then dbug("debug ircmessage 73") end

		if words[1] == "list" and (words[2] == "event") then
			for i=4,wordCount,1 do 					
				if words[i] == "player" then
					pid = words[i+1]
					pid = LookupPlayer(pid)
				end					
			end

			if number == nil then
				number = 0
			end

			if pid == nil then
				pid = 0
			end

			irc_server_event(name, words[3], pid, number)
			return
		end

		if debug then dbug("debug ircmessage 74") end

		if words[1] == "search" and words[2] == "player" then
			irc_QueueMsg(name, "Players matching " .. words[3])

			cursor,errorString = conn:execute("SELECT id, steam, name FROM players where name like '%" .. words[3] .. "%'")
			row = cursor:fetch({}, "a")
			while row do
				irc_QueueMsg(name, row.id  .. " " .. row.steam .. " " .. row.name)
				row = cursor:fetch(row, "a")
			end

			irc_QueueMsg(name, "")
		end

		if debug then dbug("debug ircmessage 75") end

		if (words[1] == "add" and words[2] == "proxy") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			if words[3] == nil then
				irc_QueueMsg(name, "I do a dns lookup on every player that joins. You can ban or exile players found using a known proxy.")
				irc_QueueMsg(name, "Staff and whitelisted players are ignored.")
				irc_QueueMsg(name, "Command example: add proxy YPSOLUTIONS action ban.  Action is optional and can be ban or exile.  Ban is the default.")
				irc_QueueMsg(name, "To remove a proxy type remove proxy YPSOLUTIONS.  To list proxies type list proxies.")
				return
			end

			proxy = nil
			if string.find(msg, " action") then
				proxy = string.sub(msg, string.find(msg, "proxy") + 6, string.find(msg, "action") - 1)
			else
				proxy = string.sub(msg, string.find(msg, "proxy") + 6)
			end

			if proxy == nil then
				irc_QueueMsg(name, "The proxy is required.")
				irc_QueueMsg(name, "Command example: add proxy YPSOLUTIONS action ban.  Action is optional and can be ban or exile.  Ban is the default.")
				return
			end

			proxy = string.trim(string.upper(proxy))
			action = "ban"

			for i=4,wordCount,1 do 					
				if words[i] == "action" then
					action = words[i+1]
				end					
			end

			if action ~= "ban" and action ~= "exile" then
				irc_QueueMsg(name, "Invalid optional action given.")
				irc_QueueMsg(name, "Command example: add proxy YPSOLUTIONS action ban.  Action is optional and can be ban or exile.  Ban is the default.")
				return
			end

			-- add the proxy to table proxies
			conn:execute("INSERT INTO proxies (scanString, action, hits) VALUES ('" .. escape(proxy) .. "','" .. escape(action) .. "',0)")

			if ircid == Smegz0r and db2Connected then
				-- also add it to bots db
				connBots:execute("INSERT INTO proxies (scanString, action, hits) VALUES ('" .. escape(proxy) .. "','ban',0)")
			end

			-- and add it to the Lua table proxies
			proxies[proxy] = {}
			proxies[proxy].scanString = proxy
			proxies[proxy].action = action
			proxies[proxy].hits = 0

			if action == "ban" then
				action = "banned."
			else
				action = "exiled."
			end

			irc_QueueMsg(name, "Proxy " .. proxy  .. " has been added. New players using it will be " .. action)
			return
		end

		if debug then dbug("debug ircmessage 76") end

		if (words[1] == "remove" and words[2] == "proxy") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			proxy = string.sub(msg, string.find(msg, "proxy") + 6)
			proxy = string.trim(string.upper(proxy))

			if proxy == nil then
				irc_QueueMsg(name, "The proxy is required.")
				irc_QueueMsg(name, "Command example: remove proxy YPSOLUTIONS.")
				return
			end

			-- remve the proxy from the proxies table
			conn:execute("DELETE FROM proxies WHERE scanString = '" .. escape(proxy) .. "'")

			-- and remove it from the Lua table proxies
			proxies[proxy] = nil
			irc_QueueMsg(name, "You have removed the proxy " .. proxy)
			return
		end

		if debug then dbug("debug ircmessage 77") end

		if words[1] == "list" and words[2] == "proxies" then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			cursor,errorString = conn:execute("SELECT * FROM proxies")
			if cursor:numrows() == 0 then
				irc_QueueMsg(irc_params[1], "There are no proxies on record.")
			else
				irc_QueueMsg(irc_params[1], "I am scanning for these proxies:")
				row = cursor:fetch({}, "a")
				while row do
					msg = "proxy: " .. row.scanString .. " action: " .. row.action .. " hits: " .. row.hits
					irc_QueueMsg(name, msg)
					row = cursor:fetch(row, "a")	
				end
			end

			irc_QueueMsg(name, "")
			return
		end

		if debug then dbug("debug ircmessage 78") end

		if words[1] == "list" and words[2] == "regions" then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			conn:execute("DELETE FROM list")

			irc_QueueMsg(name, "The following regions have player bases in them.")

			for k,v in pairs(players) do
				if math.abs(v.homeX) > 0 and math.abs(v.homeZ) > 0 then
					temp = getRegion(v.homeX, v.homeZ)
					conn:execute("INSERT INTO list (thing) VALUES ('" .. temp .. "')")
				end

				if math.abs(v.home2X) > 0 and math.abs(v.home2Z) > 0 then
					temp = getRegion(v.home2X, v.home2Z)
					conn:execute("INSERT INTO list (thing) VALUES ('" .. temp .. "')")
				end
			end

			cursor,errorString = conn:execute("SELECT * FROM list order by thing")
			row = cursor:fetch({}, "a")
			while row do
				irc_QueueMsg(name, row.thing)
				row = cursor:fetch(row, "a")
			end

			conn:execute("DELETE FROM list")

			irc_QueueMsg(name, "")
			irc_QueueMsg(name, "The following regions have locations in them.")

			for k,v in pairs(locations) do
				temp = getRegion(v.x, v.z)
					conn:execute("INSERT INTO list (thing) VALUES ('" .. temp .. "')")
			end

			cursor,errorString = conn:execute("SELECT * FROM list order by thing")
			row = cursor:fetch({}, "a")
			while row do
				irc_QueueMsg(name, row.thing)
				row = cursor:fetch(row, "a")
			end

			conn:execute("DELETE FROM list")

			irc_QueueMsg(name, "")
			return
		end

		if debug then dbug("debug ircmessage 79") end

		if (words[1] == "list" and words[2] == "restricted" and words[3] == "items") then
			if players[ircid].ircAuthenticated == false then
				requireLogin(name)
				return
			end

			irc_restricted(name)
			return
		end

	end

	if debug then dbug("debug ircmessage 80") end

	if (words[1] == "login") then
		if words[2] ~= nil then
			ircid = LookupIRCPass(string.sub(msg, string.find(msgLower, "ogin") + 5))

			if (ircid ~= nil) then
				if string.find(channel, "#") then
					table.insert(irc_params, "You accidentally revealed your password in a public channel.  You password has been automatically wiped and you won't be able to login until Smeg sets a new password for you.")
					irc_message()
					players[ircid].ircAuthenticated = false
					players[ircid].ircPass = nil

					conn:execute("UPDATE players SET ircPass = '' WHERE steam = " .. ircid)
					return
				end

				players[ircid].ircAuthenticated = true
				players[ircid].ircAlias = name

				-- fix a weird bug where the wrong player can have the irc alias for this player and they can't get it back
				conn:execute("UPDATE players SET ircAlias = '' WHERE ircAlias = '" .. escape(name) .. "'")
				conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = " .. ircid)

				if accessLevel(ircid) < 4 then
					players[ircid].ircSessionExpiry = os.time() + 3600
				else
					players[ircid].ircSessionExpiry = os.time() + 10800
				end

				table.insert(irc_params, "You have logged in " .. name)
				irc_message()
				return
			end

			if (players[ircid].ircPass == nil) then
				table.insert(irc_params, "You don't currently have a password.  Ask us to set one for you.")
				irc_message()
			end
		else
			irc_QueueMsg(name, "You didn't give me the password.  Type login <password> eg. login 1234")
		end

		return
	end

	if debug then dbug("debug ircmessage 81") end

	if words[1] == "rescue" and words[2] == "me" then
		for k,v in pairs(players) do
			if v.ircAlias == name then
				v.ircAlias = ""
				conn:execute("UPDATE players SET ircAlias = '' WHERE steam = " .. k)
				irc_QueueMsg(name, "Your nick has been released from a player record. Now login to claim it.")
			end
		end
	end

	if (words[1] == "bow" and words[2] == "before") and words[3] == "me" then
		ircid = LookupPlayer(name, "all")

		if accessLevel(ircid) < 3 then
			players[ircid].ircSessionExpiry = os.time() + 3600
			players[ircid].ircAuthenticated = true
			players[ircid].ircAlias = name
			table.insert(irc_params, "You have logged in " .. name)
			irc_message()

			conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = " .. ircid)
		else
			table.insert(irc_params, "Did you drop your contact lense?")
			irc_message()
		end
	end

	if debug then dbug ("debug ircmessage end") end
end

