--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local ircID, pid, login, name1, name2, words, wordsOld, words2, wordCount, word2Count, result, msgLower, counter, xpos, zpos, debug, tmp, k, v, filter, temp, action
local displayIRCHelp, number, numberCount, numbers = {}

debug = false -- should be false unless testing

if botman.debugAll then
	debug = true -- this should be true
end

local function requireLogin(name, silent)
	local steam

	steam = LookupIRCAlias(name)

	-- see if we can find this irc nick in the bots database
	if steam ~= 0 then
		if players[steam].block then
			irc_chat(name, "You are not allowed to command me :P")
			return false
		end

		cursor,errorString = conn:execute("SELECT * FROM players where ircAlias = '" .. escape(name) .. "' and steam = " .. steam)
		if cursor:numrows() == 0 then
			if not silent then
				irc_chat(name, "Your bot login has expired. Login and repeat your command.")
			end

			return true
		else
			row = cursor:fetch(row, "a")

			if row.ircAuthenticated then
				players[steam].ircSessionExpiry = os.time() + 86400 -- 1 day
				players[steam].ircAuthenticated = true
				ircID = steam
				return false
			end
		end
	end
end



ircStatusMessage = function (name, message, code)
	dbug(name .. " " .. message .. " " .. code)
end


IRCMessage = function (event, name, channel, msg)
	ircID = nil
	displayIRCHelp = false

	local function dbugi(text)
		-- this is just a dummy function to prevent us trying to use dbugi() here.  If we call the real dbugi function here we get an infinite loop.
		dbug(text)
	end

	result = false

	if debug then
		dbug(event .. " " .. name .. " " .. channel .. " " .. msg)
	end

	-- try once to get the irc nick of the bot.
	if botman.getIRCNick == nil then
		botman.getIRCNick = true
	end

	if server.ircBotName == "Bot" and botman.getIRCNick then
		if ircGetNick ~= nil then
			server.ircBotName = ircGetNick()
		end

		if getIrcNick ~= nil then
			server.ircBotName = getIrcNick()
		end

		botman.getIRCNick = false
	else
		botman.getIRCNick = false
	end

	-- block Mudlet from messaging the official Mudlet support channel
	if (channel == "#mudlet") then
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	irc_params = {}

	if server.ircMain == "#new" and string.find(channel, "#", nil, true) and not string.find(channel, "_", nil, true) then
		if (not string.find(channel, "_", nil, true)) and string.find(channel, "#", nil, true) then
			server.ircMain = channel
			server.ircAlerts = channel .. "_alerts"
			server.ircWatch = channel .. "_watch"
			server.ircTracker = channel .. "_tracker"
			conn:execute("UPDATE server SET ircMain = '" .. escape(server.ircMain) .. "', ircAlerts = '" .. escape(server.ircAlerts) .. "', ircWatch = '" .. escape(server.ircWatch) .. "', ircTracker = '" .. escape(server.ircTracker) .. "'")
		end
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	-- block Mudlet from reacting to its own messages
	if (name == server.botName or name == server.ircBotName or string.find(msg, "<" .. server.ircBotName .. ">", nil, true)) then
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	words = {}
	wordsOld = {}
	numbers = {}
	for word in msg:gmatch("%S+") do table.insert(wordsOld, word) end

	words2 = string.split(msg, " ")
	word2Count = table.maxn(words2)
	msgLower = string.lower(msg)

	irc_params.name = name
	for word in msgLower:gmatch("%w+") do table.insert(words, word) end
	wordCount = table.maxn(words)

	for word in string.gmatch (msg, " (-?\%d+)") do
		table.insert(numbers, word)
	end

	number = tonumber(string.match(msg, " (-?\%d+)"))

	-- break the line into numbers
	for word in string.gmatch (msg, " (-?\%d+)") do
		table.insert(numbers, tonumber(word))
	end

	numberCount = table.maxn(numbers)
	ircID = LookupOfflinePlayer(name, "all")

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if customIRC ~= nil then
		if customIRC(name, words, wordsOld, msgLower, ircID) then
			irc_params = {}
			return
		end
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help")
		irc_chat(name, "View the bot's IRC help.")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == nil) then
		irc_commands()

		irc_chat(name, "IRC bot commands:")
		irc_chat(name, ".")
		displayIRCHelp = true
	end


if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == "irc") then
		irc_chat(name, "IRC bot commands:")
		irc_chat(name, ".")
		displayIRCHelp = true
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "load" or words[1] == "read" or words[1] == "reload") and words[2] == "botman" and words[3] == "ini" then
		readBotmanINI()
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "save" and words[2] == "botman" and words[3] == "ini" then
		writeBotmanINI()
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "use" and words[2] == "telnet") then
		server.useAllocsWebAPI = false
		conn:execute("UPDATE server set useAllocsWebAPI = 0")
		irc_chat(name, "The bot is now using telnet.")
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "use" and words[2] == "api") then
		if tonumber(server.allocsMap) < 26 then
			irc_chat(name, "This feature requires Allocs MapRendering and Webinterface version 26.  Your version is " .. server.allocsMap .. ".  Please update your copy of Alloc's mod.")
			return
		end

		if tonumber(server.webPanelPort) == 0 then
			irc_chat(name, "You must first set the web panel port. This is normally port 8080 but yours may be different.  To set it type {#}set web panel port {the port number}")
			return
		end

		-- the message must be sent first because we change the webtoken password next which would block the message.
		irc_chat(name, "The bot will test using Alloc's web API.")
		server.useAllocsWebAPI = true

		if server.allocsWebAPIPassword == "" then
			server.allocsWebAPIPassword = (rand(100000) * rand(5)) + rand(10000)
			send("webtokens add bot " .. server.allocsWebAPIPassword .. " 0")
		end

		conn:execute("UPDATE server set allocsWebAPIUser = 'bot', allocsWebAPIPassword = '" .. escape(server.allocsWebAPIPassword) .. "', useAllocsWebAPI = 1")
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: reload code")
		irc_chat(name, "Make the bot reload its code.  It also performs some maintenance tasks on the bot's data.")
		irc_chat(name, ".")
	end

	if (words[1] == "reload" and (string.find(msg, "code") or string.find(msg, "script")) and words[3] == nil) then
		reloadCode()
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: reload bot")
		irc_chat(name, "Make the bot read gg, admin list, ban list, version and lkp -online.")
		irc_chat(name, ".")
	end

	if (words[1] == "reload" and string.find(msg, "bot") and words[3] == nil) then
		irc_chat(name, "Reading gg, admins, bans, lkp, version from server.")
		reloadBot()
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: update code")
		irc_chat(name, "Make the bot check for code updates and apply them.")
		irc_chat(name, ".")
	end

	if (words[1] == "update" and (words[2] == "code" or words[2] == "scripts" or words[2] == "bot") and words[3] == nil) then
		updateBot(true)
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: server")
		irc_chat(name, "View basic info about the server and installed mods.")
		irc_chat(name, ".")
	end

	if (words[1] == "server") then
		if words[2] == nil then
			irc_chat(name, "Server name is " .. server.serverName)
			irc_chat(name, "Address is " .. server.IP .. ":" .. server.ServerPort)
			irc_chat(name, "Game version is " .. server.gameVersion)
			irc_chat(name, "The server time is " .. botman.serverTime)

			if server.gameDate then
				irc_chat(name, "The game time is " .. server.gameDate)
			end

			irc_chat(name, "The server map should be here http://" .. server.IP .. ":" .. server.webPanelPort + 2)

			if server.updateBranch ~= '' then
				irc_chat(name, "The bot is running code from the " .. server.updateBranch .. " branch")
			end

			if server.updateBot then
				irc_chat(name, "The bot checks for new code daily")
			else
				irc_chat(name, "Bot updates are set to happen manually using the 'update code' command")
			end

			if server.botVersion ~= '' then
				irc_chat(name, "The bot version is " .. server.botVersion)
			end

			if server.useAllocsWebAPI then
				irc_chat(name, "The bot is using Alloc's API to send commands.")
			else
				irc_chat(name, "The bot is using telnet to send commands.")
			end

			irc_chat(name, "Command prefix is " .. server.commandPrefix)

			if not server.allocs then
				irc_chat(name, "Alloc's mod is not installed")
			end

			if not server.stompy then
				irc_chat(name, "StompyNZ's mod is not installed")
			end

			if not server.botman then
				irc_chat(name, "Botman mod is not installed")
			end

			if modVersions then
				irc_chat(name, ".")
				irc_chat(name, "The server is running these mods:")

				for k, v in pairs(modVersions) do
					irc_chat(name, k)
				end

				irc_chat(name, ".")
			end

			irc_chat(name, "There are  " .. botman.playersOnline .. " players online.")

			cursor,errorString = conn:execute("SELECT * FROM performance  ORDER BY serverdate DESC Limit 0, 1")
			row = cursor:fetch({}, "a")
			irc_chat(name, "Last Server FPS: " .. row.fps .. " Players: " .. row.players .. " Zombies: " .. row.zombies .. " Entities: " .. row.entities .. " Heap: " .. row.heap .. " HeapMax: " .. row.heapMax)

			irc_uptime(name)
			irc_chat(name, ".")
			irc_params = {}
			return
		end
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: bot info")
		irc_chat(name, "Display basic info about the bot.")
		irc_chat(name, ".")
	end

	if (words[1] == "bot" and words[2] == "info") then
		-- bot name
		irc_chat(name, "The bot is called " .. server.botName)

		-- API or telnet
		if server.useAllocsWebAPI then
			if botman.APIOffline then
				irc_chat(name, "API is offline.")
				irc_chat(name, "The bot is using telnet to talk to the server.")

				if server.useAllocsWebAPI then
					irc_chat(name, "The bot will keep trying to use the API.")
				end
			else
				irc_chat(name, "API is online.")

				if server.readLogUsingTelnet then
					irc_chat(name, "The bot is using Alloc's web API only to send commands to the server.")
				else
					irc_chat(name, "The bot is using Alloc's web API to command and monitor the server.")
				end
			end
		else
			irc_chat(name, "The bot is using telnet to talk to the server.")
		end

		if server.readLogUsingTelnet then
			irc_chat(name, "The bot is using telnet to monitor server traffic.")
		end

		-- code branch
		if server.updateBranch ~= '' then
			irc_chat(name, "The bot is running code from the " .. server.updateBranch .. " branch.")
		end

		-- code version
		if server.botVersion ~= '' then
			irc_chat(name, "The bot's code is version " .. server.botVersion)
		end

		-- bot updates enabled or not
		if server.updateBot then
			irc_chat(name, "The bot checks for new code daily.")
		else
			irc_chat(name, "Bot updates are set to happen manually using the {#}update code command")
		end

		if botman.botOffline then
			irc_chat(name, "The bot is offline.")
		else
			irc_chat(name, "The bot is online.")
		end

		if botman.telnetOffline then
			irc_chat(name, "Telnet is offline.")
		else
			irc_chat(name, "Telnet is online.")
		end
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: search blacklist {IP}")
		irc_chat(name, "See if an IP is in the blacklist or not.")
		irc_chat(name, ".")
	end

	if (words[1] == "search" and words[2] == "blacklist") then
		tmp = {}
		tmp.ip = string.sub(msg, string.find(msg, "blacklist") + 10)

		searchBlacklist(tmp.ip, name)
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop, or help shop")
		irc_chat(name, "View the IRC help for the shop management.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == nil) or (words[1] == "help" and words[2] == "shop") then
		irc_HelpShop()
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: empty category {category name}")
		irc_chat(name, "Delete everything from a category so you can start fresh.")
		irc_chat(name, ".")
	end

	if words[1] == "empty" and words[2] == "category" then
		if shopCategories[words[3]] then
			conn:execute("delete FROM shop WHERE category = '" .. escape(words[3]) .. "'")
			irc_chat(name, "The shop category called " .. words[3] .. " has been emptied.")
			irc_chat(name, ".")
			irc_params = {}
			return
		else
			irc_chat(name, "No shop category called " .. words[3] .. " exists.")
			irc_chat(name, ".")
			irc_params = {}
			return
		end
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop {category name}")
		irc_chat(name, "List the items in the specified shop category.")
		irc_chat(name, ".")
	end

	if words[1] == "shop" and shopCategories[words[2]] then
		LookupShop(words[2])

		cursor,errorString = conn:execute("SELECT * FROM memShop ORDER BY idx")
		row = cursor:fetch({}, "a")

		while row do
			if tonumber(row.stock) == -1 then
				msg = "Code:  " .. row.code .. "    item:  " .. row.item .. "    price:  " .. row.price .. " UNLIMITED"
			else
				msg = "Code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. "  (" .. row.stock .. ")  left"
			end

			irc_chat(name, msg)
			row = cursor:fetch(row, "a")
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop categories")
		irc_chat(name, "List the shop categories.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "categories") then
		irc_chat(name, "The shop categories are:")

		for k, v in pairs(shopCategories) do
			irc_chat(name, k)
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop {item name}")
		irc_chat(name, "View an item in the shop.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] ~= nil and words[3] == nil) then
		LookupShop(wordsOld[2])

		cursor,errorString = conn:execute("SELECT * FROM memShop ORDER BY category, idx")
		row = cursor:fetch({}, "a")

		while row do
			if tonumber(row.stock) == -1 then
				msg = "Code:  " .. row.code .. "    item:  " .. row.item .. "    price:  " .. row.price .. " UNLIMITED"
			else
				msg = "Code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. "  (" .. row.stock .. ")  left"
			end

			irc_chat(name, msg)

			row = cursor:fetch(row, "a")
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: villages")
		irc_chat(name, "List the villages and who the mayor is.")
		irc_chat(name, ".")
	end

	if (words[1] == "villages" and words[2] == nil) then
		irc_chat(name, "List of villages on the server:")
		for k, v in pairs(locations) do
			if v.village == true then
				if v.mayor ~= 0 then
					pid = LookupOfflinePlayer(v.mayor)
				end

				if pid ~= 0 then
					irc_chat(name, v.name .. " the mayor is " .. players[pid].name)
				else
					irc_chat(name, v.name .. " has no mayor")
				end
			end
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: fps")
		irc_chat(name, "View the last recorded mem output. (mem is updated every 40 seconds while players are online)")
		irc_chat(name, ".")
	end

	if words[1] == "fps" and words[2] == nil then
		cursor,errorString = conn:execute("SELECT * FROM performance ORDER BY timestamp DESC Limit 0, 1")
		row = cursor:fetch({}, "a")

		if row then
			irc_chat(name, "Server FPS: " .. row.fps .. " Players: " .. row.players .. " Zombies: " .. row.zombies .. " Entities: " .. row.entities .. " Heap: " .. row.heap .. " HeapMax: " .. row.heapMax)
		end

		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help custom commands")
		irc_chat(name, "View the help for custom commands.")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == "custom" and words[3] == "commands") then
		irc_HelpCustomCommands()
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: date, or time, or day")
		irc_chat(name, "View the game day and time (not server time)")
		irc_chat(name, ".")
	end

	if (words[1] == "date" or words[1] == "time" or words[1] == "day") and words[2] == nil then
		irc_gameTime(name)
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: uptime")
		irc_chat(name, "See how long the bot and server have been running.")
		irc_chat(name, ".")
	end

	if (words[1] == "uptime") and words[2] == nil then
		irc_uptime(name)
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: location categories")
		irc_chat(name, "List any defined location categories.")
		irc_chat(name, ".")
	end

	if (words[1] == "location" and words[2] == "categories") then
		if tablelength(locationCategories) == 0 then
			irc_chat(name, "There are no location categories.")
		else
			if ircID then
				if players[ircID].accessLevel < 3 then
					irc_chat(name, "Category | Minimum Access Level | Maximum Access Level")

					for k, v in pairs(locationCategories) do
						irc_chat(name, k .. " min: " .. v.minAccessLevel .. " max: " .. v.maxAccessLevel)
					end
				end
			else
				irc_chat(name, "Category")

				for k, v in pairs(locationCategories) do
					irc_chat(name, k)
				end

			end
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: location {name of location}")
		irc_chat(name, "View info about a specified location")
		irc_chat(name, ".")
	end

	if (words[1] == "location") then
		-- display details about the location

		locationName = words[2]
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then
			irc_chat(name, "That location does not exist.")
			irc_params = {}
			return
		else
			cursor,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. locationName .."'")
			row = cursor:fetch({}, "a")

			irc_chat(name, "Location: " .. row.name)
			irc_chat(name, "Category: " .. row.locationCategory)
			irc_chat(name, "Active: " .. dbYN(row.active))
			irc_chat(name, "Reset Zone: " .. dbYN(row.resetZone))
			irc_chat(name, "Safe Zone: " .. dbYN(row.killZombies))
			irc_chat(name, "Public: " .. dbYN(row.public))
			irc_chat(name, "Allow Bases: " .. dbYN(row.allowBase))
			irc_chat(name, "Allow Waypoints: " .. dbYN(row.allowWaypoints))
			irc_chat(name, "Allow Returns: " .. dbYN(row.allowReturns))

			if row.miniGame ~= nil then
				irc_chat(name, "Mini Game: " .. row.miniGame)
			end

			irc_chat(name, "Village: " .. dbYN(row.village))

			temp = 0
			if tonumber(row.mayor) > 0 then
				temp = LookupPlayer(row.mayor)

				if temp ~= 0 then
					temp = players[temp].name
				end
			end

			if temp ~= 0 then
				irc_chat(name, "Mayor: " .. temp)
			else
				irc_chat(name, "Mayor: Nobody is the mayor")
			end

			irc_chat(name, "Protected: " .. dbYN(row.protected))
			irc_chat(name, "PVP: " .. dbYN(row.pvp))
			irc_chat(name, "Access Level: " .. row.accessLevel)

			temp = 0
			if tonumber(row.owner) > 0 then
				temp = LookupPlayer(row.owner)
				temp = players[temp].name
			end

			irc_chat(name, "Owner: " .. temp)
			irc_chat(name, "Coords: " .. row.x .. " " .. row.y .. " " .. row.z)
			irc_chat(name, "Size: " .. row.size * 2)
			if row.timeOpen == 0 and row.timeClosed == 0 then
				irc_chat(name, "Always open")
			else
				irc_chat(name, "Opens: " .. row.timeOpen .. ":00")
				irc_chat(name, "Closes: " .. row.timeClosed .. ":00")
			end

			if tonumber(row.minimumLevel) == 0 and tonumber(row.maximumLevel) == 0 then
				irc_chat(name, "No level restriction")
			else
				irc_chat(name, "Minimum level: " .. row.minimumLevel)
				irc_chat(name, "Maximum level: " .. row.maximumLevel)
			end

			irc_chat(name, "Hidden: " .. dbYN(row.hidden))

			irc_chat(name, "Players in " .. loc)

			for k,v in pairs(igplayers) do
				if players[k].inLocation == loc then
					irc_chat(name, v.name)
				end
			end

			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: server stats")
		irc_chat(name, "View basic stats about the server from the last 24 hours.")
		irc_chat(name, ".")
	end

	if words[1] == "server" and (words[2] == "status" or words[2] == "stats") then
		irc_server_status(name)
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: who played today")
		irc_chat(name, "List who played on the server in the last 24 hours in order of appearance.")
		irc_chat(name, ".")
	end

	if words[1] == "who" and words[2] == "played" and words[3] == "today" then
		irc_who_played(name)
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help topics")
		irc_chat(name, "View IRC command help topics.")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == "topics") then
		irc_HelpTopics()
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: locations")
		irc_chat(name, "List the locations.")
		irc_chat(name, ".")
	end

	if (words[1] == "locations" and words[2] == nil) then
		irc_chat(name, "List of locations:")

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

			if ircID then
				if players[ircID].accessLevel < 3 then
					if v.locationCategory ~= "" then
						irc_chat(name, v.name .. " " .. public .. " " .. active .. " xyz " .. v.x .. " " .. v.y .. " " .. v.z .. " category " .. v.locationCategory)
					else
						irc_chat(name, v.name .. " " .. public .. " " .. active .. " xyz " .. v.x .. " " .. v.y .. " " .. v.z)
					end
				else
					if public == "public" then
						irc_chat(name, v.name)
					end
				end
			else
				if public == "public" then
					irc_chat(name, v.name)
				end
			end
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: staff")
		irc_chat(name, "List the staff including owners, admins and mods.")
		irc_chat(name, ".")
	end

	if (words[1] == "staff" and words[2] == nil) then
		listOwners(name)
		listAdmins(name)
		listMods(name)
		irc_params = {}
		return
	end

	if displayIRCHelp then
		irc_chat(name, "Command: owners")
		irc_chat(name, "List the owners only.")
		irc_chat(name, ".")
	end

	if (words[1] == "owners" and words[2] == nil) then
		listOwners(name)
		irc_params = {}
		return
	end

	if displayIRCHelp then
		irc_chat(name, "Command: admins")
		irc_chat(name, "List the admins only.")
		irc_chat(name, ".")
	end

	if (words[1] == "admins" and words[2] == nil) then
		listAdmins(name)
		irc_params = {}
		return
	end

	if displayIRCHelp then
		irc_chat(name, "Command: mods")
		irc_chat(name, "List the mods only.")
		irc_chat(name, ".")
	end

	if (words[1] == "mods" and words[2] == nil) then
		listMods(name)
		irc_params = {}
		return
	end


	if words[1] == string.lower(server.botName) or words[1] == string.lower(server.ircBotName) and words[2] == nil then
		irc_chat(name, "Hi " .. name)
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: restore admin")
		irc_chat(name, "Restore your admin status early if you used {#}test as player and the timer hasn't expired yet.")
		irc_chat(name, ".")
	end

	-- try to find the irc person in the players table
	-- commands below here won't work if the bot doesn't match you against a player record
	--ircID = LookupIRCAlias(name)

	if ircID == 0 then
		ircID = LookupOfflinePlayer(name, "all")
	end

	if ircID ~= 0 then
		if string.find(msg, "restore admin") then
			gmsg(server.commandPrefix .. "restore admin", ircID)
			irc_params = {}
			return
		end

		if players[ircID].ircMute then
			irc_params = {}
			return
		end

		if players[ircID].ircAuthenticated == false then
			requireLogin(name, true)
		else
			-- keep login session alive
			players[ircID].ircSessionExpiry = os.time() + 86400 -- 1 day
			--connBots:execute("UPDATE players SET ircAuthenticated = 1 WHERE steam = " .. ircID)
			conn:execute("UPDATE players SET ircAuthenticated = 1 WHERE steam = " .. ircID)
		end

		if debug then dbug("IRC: " .. name .. " access " .. players[ircID].accessLevel .. " said " .. msg) end
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: logout")
		irc_chat(name, "Log out of the bot on IRC (does not disconnect you from the IRC server).")
		irc_chat(name, ".")
	end

	if words[1] == "logout" or (words[1] == "log" and words[2] == "out") then
		if ircID and ircID ~= 0 then
			players[ircID].ircAuthenticated = false
			players[ircID].ircSessionExpiry = os.time()
			conn:execute("UPDATE players SET ircAuthenticated = 0 WHERE steam = " .. ircID)
			--connBots:execute("UPDATE players SET ircAuthenticated = 0 WHERE steam = " .. ircID)
			irc_chat(name, "You have logged out.  To log back in type your bot login or type bow before me.")
		end

		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: hi bot")
		irc_chat(name, "Get the bot to respond to you.  It will create a private chat channel as well as respond to you in the current channel.")
		irc_chat(name, ".")
	end

	if (words[1] == "hi" or words[1] == "hello") and (string.lower(words[2]) == string.lower(server.botName) or string.lower(words[2]) == string.lower(server.ircBotName) or words[2] == "bot" or words[2] == "server") then
		irc_chat(name, "Hi there " .. name .. "!  How can I help you today?")

		if ircID == nil then
			ircID = LookupOfflinePlayer(name, "all")
		else
			if not players[ircID].ircAuthenticated then
				requireLogin(name, true)
			end
		end

		if ircID and ircID ~= 0 then
			if players[ircID].ircAuthenticated then
				irc_chat(channel, "Command me :3")
			else
				if name == channel then
					irc_chat(channel, "To command me you need to log in to the bot.  You can use your bot login here or type the special command, bow before me.")
				else
					irc_chat(channel, "Hi there " .. name .. "! To command me, please move to " .. server.ircBotName .. " to login.")
				end
			end
		else
			if name == channel then
				irc_chat(channel, "Hi there " .. name .. "!  You are not logged in to the bot.  You can login here or type the special command, bow before me.")
			else
				irc_chat(channel, "Hi there " .. name .. ", this is the " .. channel .. " channel.  Please move to " .. server.ircBotName .. " to login.")
			end
		end

		irc_params = {}
		return
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: who")
		irc_chat(name, "List everyone playing on the server right now.  The info varies depending on if you are staff or player, logged in to the bot or not.")
		irc_chat(name, ".")
	end

	if (words[1] == "who" and words[2] == nil) then
		if not players[ircID].ircAuthenticated then
			requireLogin(name, true)
		end

		irc_players(name)
		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: login {name} pass {password}")
		irc_chat(name, "Log in to the bot.  Do NOT do this in any public channels (they start with a #).  Do this only in the bot's private chat channel.  If the bot sees this in a public channel it will destroy your login.  If that happens, use the invite command to invite yourself to IRC.  Follow the in-game prompts and you will get authenticated again.")
		irc_chat(name, ".")
	end

	if (words[1] == "login") then
		tmp = {}

		if words[2] ~= nil then
			if not string.find(msg, " pass ") then
				irc_chat(name, "Logins have changed.  The new format is login {name} pass {password}")
				irc_chat(name, "Your login will need to be updated to the new format.  You can do this yourself by typing invite {your ingame name} then join the server and type /read mail and follow the instructions there.")
				irc_chat(name, ".")
				irc_params = {}
				return
			else
				tmp.login = string.sub(msg, string.find(msgLower, "login") + 6, string.find(msg, " pass ") - 1)
				tmp.pass = string.sub(msg, string.find(msgLower, " pass ") + 6)
			end

			ircID = LookupIRCPass(tmp.login, tmp.pass)

			if ircID ~= 0 then
				if string.find(channel, "#") then
					irc_chat(name, "You accidentally revealed your password in a public channel.  You password has been automatically wiped and you won't be able to login until Smeg sets a new password for you.")
					players[ircID].ircAuthenticated = false
					players[ircID].ircPass = nil

					conn:execute("UPDATE players SET ircPass = '' WHERE steam = " .. ircID)
					connBots:execute("UPDATE players SET ircAuthenticated = 0 WHERE steam = " .. ircID)
					irc_params = {}
					return
				end

				players[ircID].ircAuthenticated = true
				players[ircID].ircAlias = name

				-- fix a weird bug where the wrong player can have the irc alias for this player and they can't get it back
				conn:execute("UPDATE players SET ircAlias = '' WHERE ircAlias = '" .. escape(name) .. "'")
				conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = " .. ircID)
				connBots:execute("UPDATE players SET ircAlias = '' WHERE ircAlias = '" .. escape(name) .. "'")
				connBots:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "', ircAuthenticated = 1 WHERE steam = " .. ircID)

				players[ircID].ircSessionExpiry = os.time() + 86400 -- 1 day

				irc_chat(name, "You have logged in " .. name)
				irc_chat(name, ".")
				irc_params = {}
				return
			else
				irc_chat(name, "Name or password not recognised. :{")
				irc_chat(name, "Note: You must have joined the server at least once to be recognised.  Also a password must have been set for you.")
				irc_chat(name, "You can get yourself recognised and give yourself a password by typing invite {your ingame name}. Join the server and /read mail then follow the bot's instructions.")
				irc_chat(name, ".")
				irc_params = {}
				return
			end

			if (players[ircID].ircPass == nil) then
				irc_chat(name, "You don't currently have a password.  Ask us to set one for you.")
				irc_chat(name, "Note: You must have joined the server at least once to be recognised as then you will have a player record.")
				irc_chat(name, "You can get yourself recognised and give yourself a password by typing invite {your ingame name}. Join the server and /read mail then follow the bot's instructions.")
				irc_chat(name, ".")
			end
		else
			irc_chat(name, "You didn't give me the password.  Type login {password} or login {name} pass {password}")
			irc_chat(name, "Note: You must have joined the server at least once to be recognised as then you will have a player record.")
			irc_chat(name, "You can get yourself recognised and give yourself a password by typing invite {your ingame name}. Join the server and /read mail then follow the bot's instructions.")
		end

		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: rescue me")
		irc_chat(name, "This command fixes a weird and long standing bug where the bot can get mixed up between you on IRC and a random player.  It doesn't give them admin commands but it does cause you to not be able to use them on IRC and the say command uses the other player name instead of yours.  One day I shall find this bug!")
		irc_chat(name, ".")
	end

	if words[1] == "rescue" and words[2] == "me" then
		for k,v in pairs(players) do
			if v.ircAlias == name then
				v.ircAlias = ""
				irc_chat(name, "Your nick has been released from a player record. Now login to claim it.")

				conn:execute("UPDATE players SET ircAlias = '' WHERE steam = " .. k)
			end
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: bow before me")
		irc_chat(name, "Login to the bot without a password.  Only works if you have previously been authenticated.")
		irc_chat(name, ".")
	end

	if words[1] == "bow" and (words[2] == "before" or words[2] == "to") and words[3] == "me" then
		--ircID = LookupOfflinePlayer(name, "all")

		if players[ircID].accessLevel < 3 then
			players[ircID].ircSessionExpiry = os.time() + 86400 -- 1 day
			players[ircID].ircAuthenticated = true
			players[ircID].ircAlias = name
			irc_chat(name, "You have logged in " .. name)
			irc_chat(name, ".")

			conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = " .. ircID)
			connBots:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "', ircAuthenticated = 1 WHERE steam = " .. ircID)
		else
			irc_chat(name, "Did you drop your contact lense?")
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: bow")
		irc_chat(name, "Same as bow before me but less typing.  You also get a silly response.")
		irc_chat(name, ".")
	end

	if words[1] == "bow" and words[2] == nil then
		irc_chat(name, "Thank you!  Thank you!  You're beautiful!  I love ya :D")
		irc_chat(name, "OH!  Ooooooh!  You wanted to log in?")
		irc_chat(name, ".")
		irc_chat(name, "Papers please.")
		irc_chat(name, ".")

		--ircID = LookupOfflinePlayer(name, "all")

		if players[ircID].accessLevel < 3 then
			players[ircID].ircSessionExpiry = os.time() + 86400 -- 1 day
			players[ircID].ircAuthenticated = true
			players[ircID].ircAlias = name
			irc_chat(name, "You have logged in " .. name)
			irc_chat(name)

			conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = " .. ircID)
			connBots:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "', ircAuthenticated = 1 WHERE steam = " .. ircID)
		else
			irc_chat(name, "Did you drop your contact lense?")
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "i" and words[2] == "am" and words[3] ~= nil then
		ircID = LookupPlayer(words[3], "code")

		if ircID ~= 0 then
			players[ircID].ircSessionExpiry = os.time() + 86400 -- 1 day
			players[ircID].ircAuthenticated = true
			players[ircID].ircAlias = name
			players[ircID].ircInvite = nil
			irc_chat(name, "Welcome to our IRC server " .. name .. "!")
			irc_chat(name, "Your current IRC nickname is now recorded in your player record.  To prevent others from impersonating you on IRC, you need to give me a password.")
			irc_chat(name, "Please just use numbers and letters and no symbols.  To set or change your password type new login {name} pass {password}.  eg. new login joe pass catsrul3")
			irc_chat(name, ".")
			irc_chat(name, "To use your password, never type it in " .. server.ircMain .. " or anywhere other than here in this private chat between us or others may see your password.")
			irc_chat(name, "If you accidentally login in " .. server.ircMain .. " I will wipe your password and you will need to set a new one.  If that happens type invite followed by your in-game name and I will send you a new IRC invite code.")

			if players[ircID].accessLevel < 3 then
				irc_chat(name, "As an admin of " .. server.serverName .. " you have a lot of commands available.  Type help and you can start exploring all of the commands available to you.")
				irc_chat(name, ".")
				irc_chat(name, "Some common IRC bot commands are:")
				irc_chat(name, "help, staff, who, uptime, server, server stats, info {player name}, inv {player name}, near player {player name}, new players")
			else
				irc_chat(name, "As a player you have some commands you can give me.  To see them all type help.  You can also chat to in-game players from here but ideally in " .. server.ircMain .. ". To speak to them type say followed by a message.")
				irc_chat(name, "Anything after the word say is repeated in-game with your name infront of it and -irc to show that you are speaking from here.")
				irc_chat(name, "Note that on IRC, bot commands do not use a /.  This is because the IRC server uses / for server its IRC commands.")
				irc_chat(name, ".")
				irc_chat(name, "Some common IRC bot commands are:")
				irc_chat(name, "help, staff, who, uptime, server, server stats, day, rules")
				irc_chat(name, ".")
				irc_chat(name, "Never login in " .. server.ircMain .. " or any channel that begins with a #.  Always type hi bot and use the private chat channel.")
				irc_chat(name, ".")
			end

			irc_chat(name, ".")
			conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = " .. ircID)
			connBots:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "', ircAuthenticated = 1 WHERE steam = " .. ircID)
		end

		irc_params = {}
		return
	end

	if ircID ~= 0 then
		if players[ircID].denyRights then
			irc_params = {}
			return
		end
	end

	if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help manual")
		irc_chat(name, "Read the help manual.  Its about a page and a half.")
		irc_chat(name, ".")
	end

	if words[1] == "help" and (words[2] == "guide" or words[2] == "manual") then
		irc_Manual()
		irc_params = {}
		return
	end

	if displayIRCHelp then
		irc_chat(name, "Command: help setup")
		irc_chat(name, "View the help topic on setting up the bot.")
		irc_chat(name, ".")
	end

	if words[1] == "help" and words[2] == "setup" then
		irc_Setup()
		irc_params = {}
		return
	end

	if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: server {IP}")
		irc_chat(name, "Tell the bot the IP of the server that it is connected to.  Due to a limitation in Mudlet it can't easily determine this for itself.")
		irc_chat(name, ".")
	end

	if (words[1] == "server") then
		if words[2] == "ip" then
			if not players[ircID].ircAuthenticated then
				if requireLogin(name) then
					irc_params = {}
					return
				end
			end

			if (string.trim(words[3]) ~= "") then
				server.IP = string.sub(msg, string.find(msg, words[3]), string.len(msg))
				irc_chat(name, "The server address is now " .. server.IP .. ":" .. server.ServerPort)
				irc_chat(name, ".")
				conn:execute("UPDATE server SET IP = '" .. escape(server.IP) .. "'")

				if botman.db2Connected then
					connBots:execute("UPDATE servers SET IP = '" .. escape(server.IP) .. "' WHERE botID = " .. server.botID)
				end

				irc_params = {}
				return
			end
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: new login {name} pass {password}")
		irc_chat(name, "Change your bot login.")
		irc_chat(name, ".")
	end

	if words[1] == "new" and string.find(msg, "pass") and words[3] ~= nil then
		if players[ircID].ircAuthenticated == false then
			if requireLogin(name) then
				irc_params = {}
				return
			end
		end

		tmp = {}

		for i=2,wordCount,1 do
			if words[i] == "login" then
				tmp.login = wordsOld[i+1]
			end

			if words[i] == "pass" then
				tmp.pass = wordsOld[i+1]
			end
		end

		if tmp.login == nil then
			irc_chat(name, "The format of this command has changed.  It is, new login {name} pass {password}")
			irc_chat(name, ".")
			irc_params = {}
			return
		end

		if string.find(msg, "catsrul3") then
			irc_chat(name, "Yes they do but don't tell them that, also pick a different password. :P")
			irc_params = {}
			return
		end

		if countAlphaNumeric(words[3]) ~= string.len(words[3]) then
			irc_chat(name, "Your password can only contain letters and/or numbers.")
		else
			players[ircID].ircLogin = tmp.login
			players[ircID].ircPass = tmp.pass
			conn:execute("UPDATE players SET ircLogin = '" .. escape(tmp.login) .. "', ircPass = '" .. escape(tmp.pass) .. "' WHERE steam = " .. ircID)
			connBots:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "', ircAuthenticated = 1 WHERE steam = " .. ircID)
			irc_chat(name, "You have set your new login. Test it now by typing login " .. tmp.login .. " pass " .. tmp.pass)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: say {something man}")
		irc_chat(name, "Say something publicly in-game to the players as yourself.")
		irc_chat(name, ".")
	end

	if (words[1] == "say") then
		if players[ircID].ircAuthenticated == false then
			if requireLogin(name) then
				irc_params = {}
				return
			end
		end

		if not players[ircID].ircMute then
			msg = string.trim(string.sub(msg, 5))
			if ircID == "76561197983251951" then
				message("say [FFD700]Bot Master[-] " .. players[ircID].name .. "-irc: [i]" .. msg .. "[/i][-]")
			else
				if server.sayUsesIRCNick then
					message("say " .. name .. "-irc: [i]" .. msg .. "[/i][-]")
				else
					message("say " .. players[ircID].name .. "-irc: [i]" .. msg .. "[/i][-]")
				end
			end
		else
			irc_chat(name, "Sorry you have been muted")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: sayfr {something to be translated}")
		irc_chat(name, "Depreciated feature.  It should work but requires a translation utility installed in Linux.  I don't use it anymore as I host too many bots and don't want a big surprise bill from Google.")
		irc_chat(name, ".")
	end

	if (string.find(words[1], "say") and (string.len(words[1]) == 5) and words[2] ~= nil) then
		if players[ircID].ircAuthenticated == false then
			if requireLogin(name) then
				irc_params = {}
				return
			end
		end

		msg = string.sub(msg, string.len(words[1]) + 2)
		msg = string.trim(msg)

		if (msg ~= "") then
			Translate(ircID, msg, string.sub(words[1], 4), true)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: command help")
		irc_chat(name, "View the ingame command help in full including descriptions.")
		irc_chat(name, ".")
	end

	if (words[1] == "command" and words[2] == "help") and (players[ircID].accessLevel < 3) then
		if words[3] == nil then
			gmsg(server.commandPrefix .. "command help", ircID)
		else
			gmsg(server.commandPrefix .. "command help " .. words[3], ircID)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list help")
		irc_chat(name, "View the ingame command help minus the description texts.")
		irc_chat(name, ".")
	end

	if (words[1] == "list" and words[2] == "help") and (players[ircID].accessLevel < 3) then
		if words[3] == nil then
			gmsg(server.commandPrefix .. "list help", ircID)
		else
			gmsg(server.commandPrefix .. "list help " .. words[3], ircID)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help server")
		irc_chat(name, "View the server help topic")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == "server") and (players[ircID].accessLevel < 3) then
		irc_HelpServer()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help donors")
		irc_chat(name, "View the donor help topic")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == "donors") and (players[ircID].accessLevel < 3) then
		irc_HelpDonors()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help csi")
		irc_chat(name, "View the CSI help topic")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == "csi") and (players[ircID].accessLevel < 3) then
		irc_HelpCSI()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help watchlist")
		irc_chat(name, "View the watchlist help topic")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == "watchlist") and (players[ircID].accessLevel < 3) then
		irc_HelpWatchlist()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help bad items")
		irc_chat(name, "View the bad items help topic")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == "bad" and words[3] == "items") and (players[ircID].accessLevel < 3) then
		irc_HelpBadItems()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help announcements")
		irc_chat(name, "View the rolling announcements help topic")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == "announcements") and (players[ircID].accessLevel < 3) then
		irc_HelpAnnouncements()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help commands")
		irc_chat(name, "View the remote commands help topic")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == "commands") and (players[ircID].accessLevel < 3) then
		irc_HelpCommands()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help motd")
		irc_chat(name, "View the message of the day help topic")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == "motd") and (players[ircID].accessLevel < 3) then
		irc_HelpMOTD()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help access")
		irc_chat(name, "View the access levels help topic")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] == "access") then
		irc_HelpAccess()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: reset zones")
		irc_chat(name, "List the reset zones.")
		irc_chat(name, ".")
	end

	if (words[1] == "reset" and words[2] == "zones" and words[3] == nil) and (players[ircID].accessLevel < 3) then
		irc_listResetZones(name)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: stop")
		irc_chat(name, "Stop the bot's current command output so you can issue a new command without waiting for the last one to finish.")
		irc_chat(name, ".")
	end

	if (words[1] == "nuke" or words[1] == "clear" and words[2] == "irc") or ((words[1] == "stop" or words[1] == "sotp" or words[1] == "stahp") and words[2] == nil) then
		conn:execute("DELETE FROM ircQueue WHERE name = '" .. name .. "'")
		irc_chat(channel, "IRC spam nuked for " .. name)

		if ircListItems == ircID then ircListItems = nil end

		if echoConsoleTo == name then
			echoConsole = false
			echoConsoleTo = nil
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: stop all")
		irc_chat(name, "Stop the bot's IRC command output for everyone.")
		irc_chat(name, ".")
	end

	if words[1] == "nuke" or words[1] == "clear" or words[1] == "stop" and words[2] == "all" then
		conn:execute("TRUNCATE ircQueue")
		irc_chat(channel, "IRC spam nuked for everyone.")

		ircListItems = nil
		echoConsole = false
		echoConsoleTo = nil
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: rules {new rules}")
		irc_chat(name, "View the server rules.")
		irc_chat(name, ".")
	end

	if (words[1] == "rules") then
		if words[2] == nil then
			irc_chat(name, "The server rules are " .. server.rules)
			irc_chat(name, ".")
			irc_params = {}
			return
		else
			if (players[ircID].accessLevel < 3) then
				irc_chat(name, "To change the rules type set rules {new rules}")
				irc_chat(name, ".")
			end

			irc_params = {}
			return
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: invite {player name}")
		irc_chat(name, "Send and IRC invite to a player.  The bot will give them a series of simple instructions that they must follow in order to join the IRC server and be recognised by the bot.  Also useful if you get your own bot login disabled, just invite yourself, join the server and {#}read mail or follow the prompts if you are already ingame.")
		irc_chat(name, ".")
	end

	if (words[1] == "invite" and words[2] ~= nil) and (not server.ircPrivate or players[ircID].accessLevel < 3) then
		name1 = string.trim(string.sub(msgLower, string.find(msgLower, "invite") + 7))
		pid = LookupPlayer(name1)

		if pid ~= 0 then
			number = rand(10000)
			result = LookupPlayer(number, "code")

			while result ~= 0 do
				number = rand(10000)
				result = LookupPlayer(number, "code")
			end

			players[pid].ircInvite = number

			if igplayers[pid] then
				message("pm " .. pid .. " HEY " .. players[pid].name .. "! You have an invite code for IRC! Reply with " .. server.commandPrefix .. "accept " .. number .. " or ignore it.")
			end

			conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. pid .. ", '" .. escape("You have an invite code for IRC! Reply with " .. server.commandPrefix .. "accept " .. number .. " or ignore it.") .. "')")
			irc_chat(name, "An IRC invite code has been sent to " .. players[pid].name)
			irc_chat(name, ".")
			irc_params = {}
			return
		end
	end

-- ########### Staff only beyond here ###########

	if (ircID == nil or ircID == 0) then
		irc_params = {} -- GET OUT!
		return
	end

	if (players[ircID].accessLevel > 2) then
		irc_params = {}
		return -- and take your dog.
	end

-- ########### Staff only beyond here ###########

	if players[ircID].ircAuthenticated == false then
		if requireLogin(name) then
			irc_params = {}
			return
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: fix bot")
		irc_chat(name, "Restricted: Owners and Admins only")
		irc_chat(name, "The bot will run a number of house-keeping tasks from data collection to database maintenance.  The bot will appear frozen during this time until it has completed these tasks.")
		irc_chat(name, "DO NOT repeat the command, just wait for it to complete.  The bot will start talking again and shortly after will respond to new commands.")
		irc_chat(name, ".")
	end

	if (words[1] == "fix" and words[2] == "bot") and words[3] == nil then
		if (players[ircID].accessLevel > 1) then
			irc_chat(name, "Restricted command.")
			irc_params = {}
			return
		end

		if not botman.fixingBot then
			botman.fixingBot = true
			fixBot()
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: add location category {category} {minimum access level} {maximum access level}")
		irc_chat(name, "Add a location category and optionally assign a minimum access level and maximum access level (can be the same level.)")
		irc_chat(name, ".")
	end

	if words[1] == "add" and words[2] == "location" and words[3] == "category" then
		tmp = {}
		tmp.category = wordsOld[4]
		tmp.minAccessLevel = 99
		tmp.maxAccessLevel = 0

		if numbers[1] then
			numbers[1] = math.abs(numbers[1])

			if numbers[1] > 99 then
				irc_chat(name, "Minimum access level must be in the range 0 to 99")
				irc_params = {}
				return
			end
		end

		if numbers[2] then
			numbers[2] = math.abs(numbers[2])

			if numbers[2] > 99 then
				irc_chat(name, "Maximum access level must be in the range 0 to 99")
				irc_params = {}
				return
			end
		end

		if numbers[1] and numbers[2] then
			if numbers[1] < numbers[2] then
				numbers[3] = numbers[1]
				numbers[1] = numbers[2]
				numbers[2] = numbers[3]
			end

			tmp.minAccessLevel = numbers[1]
			tmp.maxAccessLevel = numbers[2]
		end

		conn:execute("DELETE FROM locationCategories WHERE categoryName = '" .. escape(tmp.category) .. "'")
		conn:execute("INSERT INTO locationCategories (categoryName, minAccessLevel, maxAccessLevel) VALUES ('" .. escape(tmp.category) .. "'," .. tmp.minAccessLevel .. "," .. tmp.maxAccessLevel .. ")")

		irc_chat(name, "Location category " .. tmp.category .. " added with minimum access level " .. tmp.minAccessLevel .. " and maximum access level " .. tmp.maxAccessLevel)
		irc_chat(name, ".")

		-- reload location categories from the database
		loadLocationCategories()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: remove location category")
		irc_chat(name, "Remove a location category. It is also removed from all locations currently assigned to it.")
		irc_chat(name, ".")
	end

	if words[1] == "remove" and words[2] == "location" and words[3] == "category" then
		tmp = {}
		tmp.category = wordsOld[4]

		conn:execute("DELETE FROM locationCategories WHERE categoryName = '" .. escape(tmp.category) .. "'")
		conn:execute("UPDATE locations SET locationCategory = '' WHERE locationCategory = '" .. escape(tmp.category) .. "'")

		irc_chat(name, "Location category " .. tmp.category .. " removed")
		irc_chat(name, ".")

		-- reload location categories from the database
		loadLocationCategories()

		-- reload locations from the database
		loadLocations()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: run report")
		irc_chat(name, "View a report on server performance including how long the command lag is.  The report recalculates continuously until stopped by typing stop report.")
		irc_chat(name, ".")
	end

	if words[1] == "run" and (words[2] == "report" or words[3] == "report") then
		botman.getMetrics = true
		botman.getFullMetrics = false

		if words[3] == "report" then
			botman.getFullMetrics = true
		end

		metrics.reportTo = name
		metrics.pass = 1
		metrics.startTime = os.time()
		metrics.endTime = metrics.startTime
		metrics.commands = 0
		metrics.commandLag = 0
		metrics.errors = 0
		metrics.telnetLines = 0

		irc_chat(name, "Gathering performance metrics. To stop it type stop report.")
		irc_chat(name, "The report will display shortly..")
		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: stop report")
		irc_chat(name, "Stop the running report.")
		irc_chat(name, ".")
	end

	if (words[1] == "stop" and words[2] == "report") then
		botman.getMetrics = false
		irc_chat(name, "Reporting stopped.")
		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: unmute irc {player}")
		irc_chat(name, "Allow a player to use bot commands on IRC again.")
		irc_chat(name, ".")
	end

	if (words[1] == "unmute" and words[2] == "irc" and words[3] ~= nil) then
		name1 = words[3]
		name1 = string.trim(name1)
		pid = LookupPlayer(name1)

		players[pid].ircMute = true
		conn:execute("UPDATE players SET ircMute = 0 WHERE steam = " .. pid)

		msg = players[pid].name .. " can command the bot and can speak to ingame players."
		irc_chat(name, msg)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: mute irc {player}")
		irc_chat(name, "Block a player from commanding the bot on IRC.")
		irc_chat(name, ".")
	end

	if (words[1] == "mute" and words[2] == "irc" and words[3] ~= nil) then
		name1 = words[3]
		name1 = string.trim(name1)
		pid = LookupPlayer(name1)

		players[pid].ircMute = true
		conn:execute("UPDATE players SET ircMute = 1 WHERE steam = " .. pid)

		msg = players[pid].name .. " will not be able to command the bot beyond basic info and can't speak to ingame players."
		irc_chat(name, msg)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: sql {a select statement}")
		irc_chat(name, "Run a select query on the bot's database and view the output.  It is limited to 100 records by default.  Specify a different limit if you want more.")
		irc_chat(name, "Only select queries are permitted.  This is mainly intended for debugging purposes.")
		irc_chat(name, "Only server owners can use this command.")
		irc_chat(name, ".")
	end

	if (words[1] == "sql" and words[2] == "select") and players[ircID].accessLevel == 0 then
		tmp = {}
		tmp.sql = string.sub(msg, 4)

		if not string.find(tmp.sql, "limit ") then
			tmp.sql = tmp.sql .. " limit 100"
		end

		cursor,errorString = conn:execute(tmp.sql)
		row = cursor:fetch({}, "a")

		while row do
			tmp.result = ""

			for k,v in pairs(row) do
				if tmp.result == "" then
					tmp.result = k .. ": " .. v
				else
					tmp.result = tmp.result .. ", " .. k .. ": " .. v
				end
			end

			if string.len(tmp.result) > 255 then
				tmp.col = 1

				while tmp.col < string.len(tmp.result) do
					tmp.line = string.sub(tmp.result, tmp.col, tmp.col + 254)
					tmp.col = tmp.col + 255
					irc_chat(name, tmp.line)
				end
			else
				irc_chat(name, tmp.result)
			end

			row = cursor:fetch(row, "a")
		end

		irc_chat(name, ".")
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: set irc server {IP:Port}")
		irc_chat(name, "The bot will connect to the IRC server that you specify.  If the IP and port are wrong, you will need to join the server and issue same command in-game but with a valid IP and port.")
		irc_chat(name, "Only server owners can use this command.")
		irc_chat(name, ".")
	end

	if (words[1] == "set" and words[2] == "irc" and words[3] == "server") and players[ircID].accessLevel == 0 then
		server.ircServer = string.sub(msg, string.find(msg, " server ") + 8)
		temp = string.split(server.ircServer, ":")
		server.ircServer = temp[1]
		server.ircPort = temp[2]

		conn:execute("UPDATE server SET ircServer = '" .. escape(server.ircServer) .. "', ircPort = '" .. escape(server.ircPort) .. "'")

		if botman.customMudlet then
			irc_chat(name, "The bot will now connect to the irc server at " .. server.ircServer .. ":" .. server.ircPort)
			irc_chat(name, ".")
			joinIRCServer()
			ircSaveSessionConfigs()
		else
			irc_chat(name, "You have set the irc server to " .. server.ircServer .. ":" .. server.ircPort)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: set server ip {server IP} port {telnet port} pass {telnet password}")
		irc_chat(name, "Make the bot join a different 7 Days to Die server.  All parts are required even if they are not changing.")
		irc_chat(name, "Only server owners can use this command.")
		irc_chat(name, ".")
	end

	if (words[1] == "set" and words[2] == "server") and string.find(msg, "pass") and players[ircID].accessLevel == 0 then
		local sIP, sPort, sPass

		sIP = server.IP
		sPass = telnetPassword
		sPort = server.telnetPort

		for i=2,word2Count,1 do
			if words2[i] == "server" then
				sIP = words2[i+1]
			end

			if words2[i] == "ip" then
				sIP = words2[i+1]
			end

			if words2[i] == "port" then
				sPort = words2[i+1]
			end

			if words2[i] == "pass" then
				sPass = words2[i+1]
			end
		end

		server.IP = sIP
		server.telnetPass = sPass
		server.telnetPort = sPort
		telnetPassword = sPass
		conn:execute("UPDATE server SET IP = '" .. escape(server.IP) .. "', telnetPass = '" .. escape(server.telnetPass) .. "', telnetPort = " .. escape(server.telnetPort))

		if botman.db2Connected then
			connBots:execute("UPDATE servers SET IP = '" .. escape(server.IP) .. "' WHERE botID = " .. server.botID)
		end

		-- delete some Mudlet files that store IP and other info forcing Mudlet to regenerate them.
		os.remove(homedir .. "/ip")
		os.remove(homedir .. "/port")
		os.remove(homedir .. "/password")
		os.remove(homedir .. "/url")

		reconnect(sIP, sPort, true)
		saveProfile()

		irc_chat(server.ircMain, "Connecting to new 7 Days to Die server " .. server.IP .. " port " .. server.telnetPort)
		irc_chat(chatvars.ircAlias, "Connecting to new 7 Days to Die server " .. server.IP .. " port " .. server.telnetPort)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: restart bot")
		irc_chat(name, "If your bot's server or the bot's launcher script monitors the bot's process ID, you can command the bot to shut down and restart itself.  This can help to fix temporary problems with the bot.")
		irc_chat(name, "All bots hosted at botmanhosting or hosted by Smegz0r can be restarted this way.  The command is disabled by default.")
		irc_chat(name, ".")
	end

	if (words[1] == "restart" and words[2] == "bot") then
		if not server.allowBotRestarts then
			irc_chat(name, "This command is disabled.  Enable it with /enable bot restart")
			irc_chat(name, "If you do not have a script or other process monitoring the bot, it will not restart automatically.")
			irc_chat(name, "Scripts can be downloaded at http://botman.nz/shellscripts.zip and may require some editing for paths.")
			irc_params = {}
			return
		end

		if botman.customMudlet then
			if server.masterPassword ~= "" then
				irc_chat(name, "This command requires a password to complete.")
				irc_chat(name, "Type " .. server.commandPrefix .. "password {the password} (Do not type the {}).")
				players[ircID].botQuestion = "restart bot"
			else
				restartBot()
			end
		else
			irc_chat(name, "This command is not supported in your Mudlet.  You need the latest custom Mudlet by TheFae or Mudlet 3.4")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: check disk")
		irc_chat(name, "View basic information about disk usage on the server hosting the bot.")
		irc_chat(name, ".")
	end

	if words[1] == "check" and words[2] == "disk" and words[3] == nil then
		irc_reportDiskFree(name)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: command prefix {new in-game command prefix}")
		irc_chat(name, "Change the in-game command prefix to something else.  The default is /.  The bot can automatically change to ! if it detects some other server managers.")
		irc_chat(name, "If there is a command clash between the bot and another manager or mod, you should use this command.  The only symbol that cannot be used is the other slash.")
		irc_chat(name, ".")
	end

	if (words[1] == "command" and words[2] == "prefix") then
		tmp = {}
		tmp.prefix = string.sub(msg, string.find(msg, "prefix") + 7)
		tmp.prefix = string.sub(tmp.prefix, 1, 1)

		if tmp.prefix == "\\" then
			irc_chat(server.ircMain, "The bot does not support commands using a \\ because it is a special character in Lua and will not display in chat.  Please choose another symbol.")
			irc_params = {}
			return
		end

		if tmp.prefix ~= "" then
			server.commandPrefix = tmp.prefix
			conn:execute("UPDATE server SET commandPrefix = '" .. escape(tmp.prefix) .. "'")
			irc_chat(server.ircMain, "Ingame bot commands must now start with a " .. tmp.prefix)
			message("say [" .. server.chatColour .. "]Commands now begin with a " .. server.commandPrefix .. ". To use commands such as who type " .. server.commandPrefix .. "who.[-]")


			hidePlayerChat(tmp.prefix)
		else
			server.commandPrefix = ""
			conn:execute("UPDATE server SET commandPrefix = ''")
			irc_chat(server.ircMain, "Ingame bot commands do not use a prefix and can be typed in public chat.")
			message("say [" .. server.chatColour .. "]Bot commands are now just text.  To use commands such as who simply type who.[-]")

			hidePlayerChat()
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: server settings {optional filter}")
		irc_chat(name, "View current settings in the bot, organised by category.  You can view a specific category if you type it after settings.")
		irc_chat(name, "The categories are: chat, shop, teleports, security, waypoints, misc, games, irc, mods.")
		irc_chat(name, "The displayed settings may not be a complete list as the bot is still under development and new settings are added frequently.")
		irc_chat(name, ".")
	end

	if words[1] == "server" and words[2] == "settings" then
		filter = "all"

		if words[3] ~= nil then
			if string.find(words[3], "colo") or words[3] == "chat" then
				filter = "chat"
			end

			if words[3] == "shop" or words[3] == "cash" or words[3] == "money" or words[3] == server.moneyPlural then
				filter = "shop"
			end

			if string.find(words[3], "tele") or words[3] == "tp" then
				filter = "teleports"
			end

			if words[3] == "security" then
				filter = "security"
			end

			if string.find(words[3], "wayp") or words[3] == "wp" then
				filter = "waypoints"
			end

			if words[3] == "misc" or words[3] == "general" then
				filter = "general"
			end

			if words[3] == "games" then
				filter = "games"
			end

			if words[3] == "irc" then
				filter = "irc"
			end

			if words[3] == "mods" then
				filter = "mods"
			end
		else
			irc_chat(name, "You can filter this list.")
			irc_chat(name, "Filters: chat, shop, games, irc, teleporting, waypoints, security, misc, mods")
			irc_chat(name, "eg. server settings security")
			irc_chat(name, "---")
		end


		irc_chat(name, "The bot's server settings")

		if filter == "all" or filter == "chat" then
			irc_chat(name, "Chat colours")
			irc_chat(name, "---")

			irc_chat(name, "Normal bot messages are coloured " .. server.chatColour)
			irc_chat(name, "Bot alert messages are coloured " .. server.alertColour)
			irc_chat(name, "Bot warning messages are coloured " .. server.warnColour)
			irc_chat(name, "Server owner chat colour is " .. server.chatColourOwner)
			irc_chat(name, "Admin names are coloured " .. server.chatColourAdmin)
			irc_chat(name, "Moderator names are coloured " .. server.chatColourMod)
			irc_chat(name, "Donor names are coloured " .. server.chatColourDonor)
			irc_chat(name, "Regular player names are coloured " .. server.chatColourPlayer)
			irc_chat(name, "New player names are coloured " .. server.chatColourNewPlayer)
			irc_chat(name, "Prisoner names are coloured " .. server.chatColourPrisoner)
		end


		if filter == "all" or filter == "shop" then
			irc_chat(name, "---")
			irc_chat(name, "The shop and currency")
			irc_chat(name, "---")

			irc_chat(name, "The in-game money is called the " .. server.moneyName .. " or " .. server.moneyPlural)

			if server.allowShop then
				irc_chat(name, "Shop is open")
			else
				irc_chat(name, "Shop is closed")
			end

			if server.allowBank then
				irc_chat(name, "Players can earn " .. server.moneyPlural)
			else
				irc_chat(name, "In-game money is disabled")
			end

			irc_chat(name, "Killing a zombie earns a player " .. server.zombieKillReward .. " " .. server.moneyPlural)

			if server.alertSpending then
				irc_chat(name, "Players will be notified when a command costs them " .. server.moneyPlural)
			else
				irc_chat(name, "Players will be silently charged when a command costs them " .. server.moneyPlural)
			end

			if server.allowLottery then
				irc_chat(name, "Daily lottery is running")
			else
				irc_chat(name, "Daily lottery is disabled")
			end

			irc_chat(name, "The shop will reset in " .. server.shopCountdown .. " real days")

			if server.shopCloseHour ~= server.shopOpenHour then
				irc_chat(name, "The shop closes at " .. shopCloseHour .. " and opens at " .. shopOpenHour)
			else
				irc_chat(name, "The shop does not close at certain times of the day.")
			end

			irc_chat(name, "Players are awarded " .. server.perMinutePayRate .. " " .. server.moneyPlural .. " per minute (except for new players)")

			irc_chat(name, "The daily lottery is at " .. server.lottery .. " " .. server.moneyPlural)
			irc_chat(name, "Zombie kills are multiplied by " .. server.lotteryMultiplier .. " and added to the daily lottery")
		end


		if filter == "all" or filter == "games" then
			irc_chat(name, "---")
			irc_chat(name, "Games")
			irc_chat(name, "---")
			irc_chat(name, "Gimme:")

			if server.allowGimme then
				irc_chat(name, "Gimme can be played")
			else
				irc_chat(name, "Gimme is disabled")
			end

			if server.gimmePeace then
				irc_chat(name, "Gimme messages are PM's")
			else
				irc_chat(name, "Gimme messages are public messages")
			end

			if server.gimmeZombies then
				irc_chat(name, "The gimme game includes zombie prizes.")
			else
				irc_chat(name, "The gimme game will not award zombies as prizes.")
			end

			irc_chat(name, "Gimme will reset every " .. server.gimmeResetTime .. " minutes.")

			irc_chat(name, ".")
			irc_chat(name, "Swear Jar: (not finished yet)")

			if server.swearJar then
				irc_chat(name, "Players detected swearing are fined")
			else
				irc_chat(name, "Players can swear without penalty")
			end

			irc_chat(name, "The swear jar has " .. server.swearCash .. " " .. server.moneyPlural .. " in it")
			irc_chat(name, "The fine for swearing is " .. server.swearFine .. " " .. server.moneyPlural)


			irc_chat(name, ".")
			irc_chat(name, "Voting (not server voting): (also not finished yet)")

			if server.allowPlayerVoteTopics then
				irc_chat(name, "Players can create a voting topic.")
			else
				irc_chat(name, "Only admins can create voting topics.")
			end

			if server.allowVoting then
				irc_chat(name, "Players can vote.")
			else
				irc_chat(name, "Voting is disabled.")
			end
		end

		if filter == "all" or filter == "irc" then
			irc_chat(name, "---")
			irc_chat(name, "IRC Settings")
			irc_chat(name, "---")

			irc_chat(name, "The IRC main channel is " .. server.ircMain)
			irc_chat(name, "The IRC alerts channel is " .. server.ircAlerts)
			irc_chat(name, "The IRC watch channel is " .. server.ircWatch)
			irc_chat(name, "The bot's name on IRC is " .. server.ircBotName)

			if server.ircPrivate then
				irc_chat(name, "The IRC IP is not shared ingame with players.")
			else
				irc_chat(name, "Players can discover the IRC IP with /help irc.")
			end

			irc_chat(name, "The IRC server's address is " .. server.ircServer)
			irc_chat(name, "The IRC port is " .. server.ircPort)
		end


		if filter == "all" or filter == "teleports" or filter == "waypoints" then
			irc_chat(name, "---")
			irc_chat(name, "Teleporting")
			irc_chat(name, "---")

			if server.allowTeleporting then
				irc_chat(name, "Players can teleport")
			else
				irc_chat(name, "Player teleports are disabled")
			end

			if server.allowPlayerToPlayerTeleporting then
				irc_chat(name, "Players can teleport to friends.")
			else
				irc_chat(name, "Players cannot teleport to other players.")
			end

			if server.allowHomeTeleport then
				irc_chat(name, "Players can teleport home.")
			else
				irc_chat(name, "Players are not able to teleport home.")
			end

			if server.allowPackTeleport then
				irc_chat(name, "Players can teleport to their pack after dying.")
			else
				irc_chat(name, "Players cannot teleport to their pack after dying.")
			end

			irc_chat(name, "The pack command costs players  " .. server.packCost .. " " .. server.moneyPlural)

			if server.announceTeleports then
				irc_chat(name, "Players teleporting is announced in public chat")
			else
				irc_chat(name, "Player teleports are silent")
			end

			irc_chat(name, "Private teleporting costs " .. server.teleportCost .. " " .. server.moneyPlural)
			irc_chat(name, "Players must wait " .. server.teleportPublicCooldown .. " seconds between teleport commands.")
			irc_chat(name, "Public teleports cost " .. server.teleportPublicCost .. " " .. server.moneyPlural)

			if server.pvpTeleportCooldown > 0 then
				irc_chat(name, "Player teleport commands in PVP areas are delayed " .. server.pvpTeleportCooldown .. " seconds after they PVP someone.")
			else
				irc_chat(name, "Player teleport commands are not delayed in PVP areas.")
			end

			if server.playerTeleportDelay > 0 then
				irc_chat(name, "Player teleports are delayed by " .. server.playerTeleportDelay .. " seconds.")
			else
				irc_chat(name, "Player teleports are not delayed.")
			end

			irc_chat(name, "Players must wait " .. server.packCooldown .. " seconds after death before " .. server.commandPrefix .. "pack is available")

			if server.allowReturns then
				irc_chat(name, "Players can use the " .. server.commandPrefix .. "return command.")
			else
				irc_chat(name, "Players cannot use the " .. server.commandPrefix .. "return command.")
			end

			if server.allowStuckTeleport then
				irc_chat(name, "Players can use the " .. server.commandPrefix .. "stuck command.")
			else
				irc_chat(name, "Players cannot use the " .. server.commandPrefix .. "stuck command.")
			end

			irc_chat(name, "Base cooldown timer is " .. server.baseCooldown .. " seconds")

			if server.baseCost > 0 then
				irc_chat(name, "The base command costs " .. server.baseCost)
			else
				irc_chat(name, "Players can use the base command free of cost.")
			end

			if server.disableTPinPVP then
				irc_chat(name, "Players are not able to teleport when in areas governed by PVP rules.")
			else
				irc_chat(name, "Unless otherwise disabled, players can teleport in PVP areas.")
			end
		end


		if filter == "all" or filter == "waypoints" then
			irc_chat(name, "---")
			irc_chat(name, "Waypoints")
			irc_chat(name, "---")

			if server.allowWaypoints then
				irc_chat(name, "Players can use waypoints")
			else
				irc_chat(name, "Waypoints are disabled")
			end

			if server.waypointsPublic then
				irc_chat(name, "Everyone can use waypoints.")
			else
				irc_chat(name, "Only donors and staff can use waypoints.")
			end

			irc_chat(name, "Players can have " .. server.maxWaypoints .. " waypoints")
			irc_chat(name, "Players must wait " .. server.waypointCooldown .. " seconds between waypoint teleports.")
			irc_chat(name, "Waypoints cost " .. server.waypointCost .. " " .. server.moneyPlural .. " to use.")
			irc_chat(name, "Waypoints cost " .. server.waypointCreateCost .. " " .. server.moneyPlural .. " to create.")
		end


		if filter == "all" or filter == "security" then
			irc_chat(name, "---")
			irc_chat(name, "Security!")
			irc_chat(name, "---")

			if server.whitelistCountries ~= '' then
				irc_chat(name, "The server is restricted to players from " .. server.whitelistCountries .. " except for staff.")
			else
				irc_chat(name, "There are no whitelisted countries set.")
			end

			if server.allowOverstacking then
				irc_chat(name, "Ignore inventory overstacking")
			else
				irc_chat(name, "Punish inventory overstacking")
			end

			if botman.ignoreAdmins then
				irc_chat(name, "Admins are exempt from normal restrictions on players")
			else
				irc_chat(name, "Admins are treated like normal players for testing purposes")
			end

			irc_chat(name, "Tracking data is kept for " .. server.trackingKeepDays .. " days.")

			if server.allowProxies then
				irc_chat(name, "Players can connect using proxy servers.")
			else
				irc_chat(name, "Using a proxy will get a player banned.")
			end

			if server.allowRapidRelogging then
				irc_chat(name, "Ignore players doing rapid relogging")
			else
				irc_chat(name, "Temp ban players doing rapid relogging")
			end

			if server.scanNoclip then
				irc_chat(name, "The bot will scan for noclipped players")
			else
				irc_chat(name, "The bot will not scan for noclipped players")
			end

			irc_chat(name, "The bot reserves " .. server.reservedSlots .. " slots for staff, donors and other players selected by admins.")

			if server.pvpIgnoreFriendlyKills then
				irc_chat(name, "Players are never arrested for killing friends.")
			else
				irc_chat(name, "Players killing their friends can be arrested.")
			end

			if tonumber(server.pingKick) > 0 then
				irc_chat(name, "New players with a ping over " .. server.pingKick .. " are kicked from the server")
			else
				irc_chat(name, "Ping kick is disabled")
			end

			if server.playersCanFly then
				irc_chat(name, "Flying players are ignored by the bot")
			else
				irc_chat(name, "Players detected flying will be reported and may be temp banned")
			end

			irc_chat(name, "Minimum stack size to be considered overstacking is " .. server.overstackThreshold)

			irc_chat(name, "The bot restricts player movement to " .. server.mapSize .. " from 0,0")

			if server.maxPrisonTime > 0 then
				irc_chat(name, "Prisoners are automatically released from prison after " .. server.maxPrisonTime .. " minutes")
			else
				irc_chat(name, "Prisoners are kept in prison forever or until released.")
			end

			if server.hackerTPDetection then
				irc_chat(name, "Players detected teleporting long distances with no detectable command may be temp banned.")
			else
				irc_chat(name, "Teleporting players will not be temp banned. The presence of Server Tools and some other mods make detecting hacker teleporting impossible.")
			end

			if server.hardcore then
				irc_chat(name, "Players cannot use bot commands with some exceptions.")
			else
				irc_chat(name, "Players can command the bot, limited only by access level.")
			end

			if server.hideCommands then
				irc_chat(name, "Commands are hidden from public chat")
			else
				irc_chat(name, "Commands are visible in public chat")
			end

			if server.idleKick then
				irc_chat(name, "Idle players are kicked after 15 minutes when the server is full")
			else
				irc_chat(name, "Idle players are never kicked")
			end

			irc_chat(name, "Players with more than " .. server.GBLBanThreshold .. " global bans are automatically banned.")

			if server.bailCost > 0 then
				irc_chat(name, "Players can be bailed out of prison.")
			else
				irc_chat(name, "Players cannot be bailed from prison")
			end

			irc_chat(name, "Default base protection size is " .. server.baseSize)
			irc_chat(name, "Blacklist response is " .. server.blacklistResponse)
			irc_chat(name, "Blocked countries: " .. server.blacklistCountries)

			if server.disableBaseProtection then
				irc_chat(name, "Base protection is disabled")
			else
				irc_chat(name, "Players can set base protection")
			end

			if server.disableWatchAlerts then
				irc_chat(name, "The bot will not PM ingame alerts about watched players.")
			else
				irc_chat(name, "The bot PM's ingame alerts about watched players.")
			end

			irc_chat(name, "Base protection auto-expires " .. server.protectionMaxDays .. " real days after a players last play")

			if server.pvpAllowProtect then
				irc_chat(name, "Players are allowed to set base protection in PVP areas.")
			else
				irc_chat(name, "Base protection is disabled in PVP areas.")
			end

			if server.allowNumericNames then
				irc_chat(name, "Allow players to have numeric names")
			else
				irc_chat(name, "Kick players with numeric names")
			end

			irc_chat(name, "Access level override: " .. server.accessLevelOverride)
		end


		if filter == "all" or filter == "general" then
			irc_chat(name, "---")
			irc_chat(name, "General settings")
			irc_chat(name, "---")
			irc_chat(name, "Access level override: " .. server.accessLevelOverride)

			if server.enableLagCheck then
				irc_chat(name, "The bot will test for command lag.")
			else
				irc_chat(name, "The bot will not test for command lag.")
			end

			if server.allowNumericNames then
				irc_chat(name, "Allow players to have numeric names")
			else
				irc_chat(name, "Kick players with numeric names")
			end

			if server.serverGroup ~= nil then
				irc_chat(name, "The server group is " .. server.serverGroup)
			end

			if server.allowReboot then
				irc_chat(name, "Bot reboots the server")
			else
				irc_chat(name, "Bot never reboots the server")
			end

			if server.updateBot then
				irc_chat(name, "The bot will check daily for updates from the " .. server.updateBranch .. " branch.")
			else
				irc_chat(name, "The bot will not automatically update itself.")
			end

			if server.allowPhysics then
				irc_chat(name, "Physics is on")
			else
				irc_chat(name, "Physics is off")
			end

			if server.allowBotRestarts then
				irc_chat(name, "The bot can be commanded to restart itself with " .. server.commandPrefix .. "restart bot")
			else
				irc_chat(name, "The bot can only be restarted manually and will not automatically restart if something causes it to quit.")
			end

			if server.allowGarbageNames then
				irc_chat(name, "Players can have non-alphanumeric names")
			else
				irc_chat(name, "Players with non-alphanumeric names will be kicked")
			end

			irc_chat(name, "The server rules are " .. server.rules)

			if server.scanEntities then
				irc_chat(name, "The bot will scan active entities.")
			else
				irc_chat(name, "The bot will not do timed entity scans.")
			end

			if server.scanErrors then
				irc_chat(name, "The bot will scan for and fix map errors.")
			else
				irc_chat(name, "The bot will not fix map errors.")
			end


			if server.scanZombies then
				irc_chat(name, "The bot will read all the active zombies every 15-30 seconds for features such as safe zones.")
			else
				irc_chat(name, "The bot will not scan for zombies.")
			end

			if server.rebootHour > 0 then
				irc_chat(name, "The bot will reboot the server daily when the server time is " .. server.rebootHour .. ":" .. server.rebootMinute)
			else
				irc_chat(name, "The bot does not reboot the server daily at a set time.")
			end

			irc_chat(name, "Max players is " .. server.maxPlayers)
			irc_chat(name, "Max server uptime before a reboot is " .. server.maxServerUptime .. " hours")
			irc_chat(name, "Max spawned zombies is " .. server.MaxSpawnedZombies)
			irc_chat(name, "The message of the day is " .. server.MOTD)
			irc_chat(name, "New players are upgraded to regular players after " .. server.newPlayerTimer .. " minutes total playtime")
			irc_chat(name, "Northeast of 0,0 is " .. server.northeastZone)
			irc_chat(name, "Northwest of 0,0 is " .. server.northwestZone)
			irc_chat(name, "Southeast of 0,0 is " .. server.southeastZone)
			irc_chat(name, "Southwest of 0,0 is " .. server.southwestZone)

			irc_chat(name, "The bot is called " .. server.botName)

			if server.botRestartHour ~= 25 then
				irc_chat(name, "The bot will automatically restart itself daily when the server hour is " .. server.botRestartHour .. " and bot restarts are enabled and the bot has been up more than 1 hour.")
			end

			if server.CBSMFriendly then
				irc_chat(name, "If the bot detects CBSM, it will automatically switch bot commands from using /  to using !")
			else
				irc_chat(name, "The bot will not change the bot command prefix to let CBSM use / commands.")
			end

			irc_chat(name, "Daily chat and command logs are stored at " .. server.chatlogPath .. " on the bot's host")
			irc_chat(name, "Bot commands ingame use the " .. server.commandPrefix .. " prefix")

			if server.enableRegionPM then
				irc_chat(name, "Admins and donors see region names as they travel")
			else
				irc_chat(name, "Region names are not shown")
			end

			irc_chat(name, "Scheduled server reboots that fall on horde days will be delayed by " .. server.feralRebootDelay .. " minutes.")
			irc_chat(name, "This is a " .. server.gameType .. " server")
			irc_chat(name, "The IP of the server is " .. server.IP)
		end


		if filter == "all" or filter == "mods" then
			irc_chat(name, "---")
			irc_chat(name, "Supported Mods")
			irc_chat(name, "---")

			if server.allocs then
				irc_chat(name, "Alloc's Server Fixes " .. server.allocsServerFixes)
				irc_chat(name, "Alloc's Command Extensions " .. server.allocsCommandExtensions)
				irc_chat(name, "Alloc's Map " .. server.allocsMap)
			else
				irc_chat(name, "ALERT!  Alloc's mod is not installed!  The bot can't function without it.  Grab it here http://botman.nz/Botman_Mods.zip")
			end

			if server.coppi then
				irc_chat(name, "Coppi's mod version is " .. server.coppiVersion)
			end

			if server.stompy then
				irc_chat(name, "StompyNZ's mod version is " .. server.stompyVersion)
			else
				irc_chat(name, "StompyNZ's mod is not installed.")
			end
		end

		irc_chat(name, "-end-")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: new players")
		irc_chat(name, "List new players that have joined in the last 24 hours.  To see further back, add a number eg: new players 5 will give you the last 5 days.")
		irc_chat(name, ".")
	end

	if words[1] == "new" and words[2] == "players" then
		pid = LookupOfflinePlayer(name, "all")

		if number == nil then
			number = 86400
		else
			number = number * 86400
		end

		irc_chat(name, "New players in the last " .. math.floor(number / 86400) .. " days:")

		cursor,errorString = conn:execute("SELECT * FROM events where timestamp >= '" .. os.date('%Y-%m-%d %H:%M:%S', os.time() - number).. "' and type = 'new player' order by timestamp desc")
		row = cursor:fetch({}, "a")

		while row do
			if accessLevel(pid) > 3 then
				irc_chat(name, v.name)
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

				irc_chat(name, msg)
			end

			row = cursor:fetch(row, "a")
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: check dns {player}")
		irc_chat(name, "Make the bot do a DNS lookup on any player.  Mainly useful if a player of interest is already in the game before the bot joined.  Otherwise the bot will check their DNS only when the player re-logs.")
		irc_chat(name, ".")
	end

	if words[1] == "check" and words[2] == "dns" then
		if debug then dbug("debug ircmessage " .. msg) end
		pid = 0
		number = ""

		for i=2,wordCount,1 do
			if words2[i] == "dns" then
				name1 = words2[i+1]
				pid = LookupPlayer(name1)
			end
		end


		if pid ~= 0 then
			number = players[pid].ip

			irc_chat(name, "Checking DNS record for " .. pid .. " IP " .. number)
			CheckBlacklist(pid, number)
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: view alerts")
		irc_chat(name, "")
		irc_chat(name, ".")
	end

	if words[1] == "view" and words[2] == "alerts" then
		if debug then dbug("debug ircmessage " .. msg) end
		if number == nil then number = 20 end

		cursor,errorString = conn:execute("SELECT * FROM alerts order by alertID desc limit " .. number)
		if cursor:numrows() == 0 then
			irc_chat(name, "There are no alerts recorded.")
		else
			irc_chat(name, "The most recent alerts are:")
			row = cursor:fetch({}, "a")
			while row do
				msg = "On " .. row.timestamp .. " player " .. players[row.steam].name .. " " .. row.steam .. " at " .. row.x .. " " .. row.y .. " " .. row.z .. " said " .. row.message
				irc_chat(name, msg)
				row = cursor:fetch(row, "a")
			end
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: view slots")
		irc_chat(name, "View information about the bot's player slots and reserved slots.")
		irc_chat(name, ".")
	end

	if (words[1] == "view" and words[2] == "slots") and accessLevel(ircID) < 3 then
		irc_chat(name, "Reserved slots status:")
		irc_chat(name, "server.reservedSlots = " .. server.reservedSlots)
		irc_chat(name, "botman.playersOnline = " .. botman.playersOnline)
		irc_chat(name, "server.maxPlayers = " .. server.maxPlayers)
		irc_chat(name, "server.ServerMaxPlayerCount = " .. server.ServerMaxPlayerCount)

		irc_chat(name, "The player slots:")

		cursor,errorString = conn:execute("SELECT * FROM slots")
		row = cursor:fetch({}, "a")
		while row do
			if players[row.steam] then
				irc_chat(name, "Slot " .. row.slot .. " | reserved " .. dbYN(row.reserved) .. " | empty " .. dbYN(row.free) .. " | steam " .. row.steam .. " | name " .. players[row.steam].name .. " | staff " .. dbYN(row.staff))
			else
				irc_chat(name, "Slot " .. row.slot .. " | reserved " .. dbYN(row.reserved) .. " | empty " .. dbYN(row.free) .. " | steam " .. row.steam .. " | name | staff " .. dbYN(row.staff))
			end

			row = cursor:fetch(row, "a")
		end

		irc_chat(name, ".")
		irc_params = {}
		return true
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: show inventory")
		irc_chat(name, "View historic inventory movement of a player.  They do not need to be playing right now.")
		irc_chat(name, "Full example.. show inventory player Joe xpos 100 zpos 200 days 2 range 50 item tnt qty 20")
		irc_chat(name, "You can grab the coords from any player by adding, near john (for example)")
		irc_chat(name, "Defaults: days = 1, range = 100km, xpos = 0, zpos = 0")
		irc_chat(name, "Optional: player (or near) joe, days 1, hours 1, range 50, item tin, qty 10, xpos 0, zpos 0, session 1")
		irc_chat(name, "Currently this command always reports up to the current time.  Later you will be able to specify an end date and time.")
		irc_chat(name, ".")
	end

	if words[1] == "show" and words[2] == "inventory" then
		if words[3] == nil then
			irc_chat(name, "Full example.. show inventory player Joe xpos 100 zpos 200 days 2 range 50 item tnt qty 20")
			irc_chat(name, "You can grab the coords from any player by adding, near joe")
			irc_chat(name, "Defaults: days = 1, range = 100km, xpos = 0, zpos = 0")
			irc_chat(name, "Optional: player (or near) joe, days 1, hours 1, range 50, item tin, qty 10, xpos 0, zpos 0, session 1")
			irc_chat(name, ".")
			irc_params = {}
			return
		end

		name1 = nil
		pid = 0
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

				if pid2 ~= 0 then
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

		if pid ~= 0 then
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

		irc_chat(name, "Inventory tracking data for query:")
		irc_chat(name, sql)

		cursor,errorString = conn:execute(sql)
		if cursor:numrows() == 0 then
			irc_chat(name, "No inventory tracking is recorded for your search parameters.")
		else
			irc_chat(name, " ")
			irc_chat(name, "   id   |      steam       |      timestamp     |    item     | qty | x y z | session | name")
			row = cursor:fetch({}, "a")

			rows = cursor:numrows()

			if rows > 50 then
				irc_chat(name, "***** Report length " .. rows .. " rows.  Cancel it with: nuke irc *****")
			end

			while row do
				msg = row.id .. ", " .. row.steam .. ", " .. row.timestamp .. ", " .. row.item .. ", " .. row.delta .. ", " .. row.x .. " " .. row.y .. " " .. row.z .. ", " .. row.session .. ", " .. players[row.steam].name
				irc_chat(name, msg)
				row = cursor:fetch(row, "a")
			end
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: announcements")
		irc_chat(name, "View the rolling announcements.")
		irc_chat(name, ".")
	end

	if words[1] == "announcements" then
		if debug then dbug("debug ircmessage " .. msg) end
		counter = 1
		cursor,errorString = conn:execute("SELECT * FROM announcements")
		if cursor:numrows() == 0 then
			irc_chat(name, "There are no announcements recorded.")
		else
			irc_chat(name, "The server announcements are:")
			row = cursor:fetch({}, "a")
			while row do
				msg = "Announcement (" .. counter .. ") " .. row.message
				counter = counter + 1
				irc_chat(name, msg)
				row = cursor:fetch(row, "a")
			end
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: add announcement")
		irc_chat(name, "Add a new rolling announcement.")
		irc_chat(name, ".")
	end

	if words[1] == "add" and words[2] == "announcement" and words[3] ~= nil then
		if debug then dbug("debug ircmessage " .. msg) end
		msg = string.sub(msg, 17, string.len(msg))
		msg = string.trim(msg)

		conn:execute("INSERT INTO announcements (message, startdate, enddate) VALUES ('" .. escape(msg) .. "','" .. os.date("%Y-%m-%d", os.time()) .. "','2020-01-01')")

		irc_chat(name, "New announcement added.")
		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: delete announcement")
		irc_chat(name, "If you type 'announcements' you will see a numbered list of rolling announcements.  To delete a specific announcement type its number at the end of this command.")
		irc_chat(name, "eg. delete announcement 3")
		irc_chat(name, ".")
	end

	if words[1] == "delete" and words[2] == "announcement" and words[3] ~= nil then
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

		irc_chat(name, "Announcement " .. number .. " deleted.")
		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: who visited")
		irc_chat(name, "See who visited a player location or base.")
		irc_chat(name, "Example with defaults:  who visited player smeg days 1 range 10 height 4")
		irc_chat(name, "Example with coords:  who visited x 0 y 100 z 0 height 5 days 1 range 20")
		irc_chat(name, "Another example:  who visited player smeg base")
		irc_chat(name, "Another example:  who visited bed smeg")
		irc_chat(name, "Setting hours will reset days to zero")
		irc_chat(name, "Defaults: days = 1 or hours = 0, range = 10")
		irc_chat(name, ".")
	end

	if (words[1] == "who" and words[2] == "visited") then
		if words[3] == nil then
			irc_chat(name, "See who visited a player location or base.")
			irc_chat(name, "Example with defaults:  who visited player smeg days 1 range 10 height 4")
			irc_chat(name, "Example with coords:  who visited x 0 y 100 z 0 height 5 days 1 range 20")
			irc_chat(name, "Another example:  who visited player smeg base")
			irc_chat(name, "Another example:  who visited bed smeg")
			irc_chat(name, "Setting hours will reset days to zero")
			irc_chat(name, "Defaults: days = 1 or hours = 0, range = 10")
			irc_chat(name, ".")
			irc_params = {}
			return
		end

		tmp = {}
		tmp.days = 1
		tmp.hours = 0
		tmp.range = 10
		tmp.height = 10
		tmp.basesOnly = "player"
		tmp.steam = 0

		for i=3,wordCount,1 do
			if words[i] == "player" or words[i] == "bed" then
				tmp.name = words[i+1]
				tmp.steam = LookupPlayer(tmp.name)

				if tmp.steam ~= 0 and words[i] == "player" then
					tmp.player = true
					tmp.x = players[tmp.steam].xPos
					tmp.y = players[tmp.steam].yPos
					tmp.z = players[tmp.steam].zPos
				end

				if tmp.steam ~= 0 and words[i] == "bed" then
					tmp.bed = true
					tmp.x = players[tmp.steam].bedX
					tmp.y = players[tmp.steam].bedY
					tmp.z = players[tmp.steam].bedZ
				end
			end

			if words[i] == "range" then
				tmp.range = tonumber(words[i+1])
			end

			if words[i] == "days" then
				tmp.days = tonumber(words[i+1])
				tmp.hours = 0
			end

			if words[i] == "hours" then
				tmp.hours = tonumber(words[i+1])
				tmp.days = 0
			end

			if words[i] == "base" then
				tmp.baseOnly = "base"
			end

			if words[i] == "x" then
				tmp.x = tonumber(words[i+1])
			end

			if words[i] == "y" then
				tmp.y = tonumber(words[i+1])
			end

			if words[i] == "z" then
				tmp.z = tonumber(words[i+1])
			end

			if words[i] == "height" then
				tmp.height = tonumber(words[i+1])
			end
		end

		if (tmp.basesOnly == "base") and tmp.steam ~= 0 then
			if players[tmp.steam].homeX ~= 0 and players[tmp.steam].homeZ ~= 0 then
				irc_chat(name, "Players who visited within " .. tmp.range .. " metres of base 1 of " .. players[tmp.steam].name .. " at " .. players[tmp.steam].homeX .. " " .. players[tmp.steam].homeY .. " " .. players[tmp.steam].homeZ .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
				dbWho(name, players[tmp.steam].homeX, players[tmp.steam].homeY, players[tmp.steam].homeZ, tmp.range, tmp.days, tmp.hours, tmp.height, ircID, false)
			else
				irc_chat(name, "Player " .. players[tmp.steam].name .. " does not have a base set.")
			end

			if players[tmp.steam].home2X ~= 0 and players[tmp.steam].home2Z ~= 0 then
				irc_chat(name, ".")
				irc_chat(name, "Players who visited within " .. tmp.range .. " metres of base 2 of " .. players[tmp.steam].name .. " at " .. players[tmp.steam].home2X .. " " .. players[tmp.steam].home2Y .. " " .. players[tmp.steam].home2Z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
				dbWho(name, players[tmp.steam].home2X, players[tmp.steam].home2Y, players[tmp.steam].home2Z, tmp.range, tmp.days, tmp.hours, tmp.height, ircID, false)
			end
		end

		if tmp.basesOnly == "player" and tmp.steam ~= 0 then
			if tmp.player then
				irc_chat(name, "Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. " at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
			end

			if tmp.bed then
				irc_chat(name, "Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. "'s bed at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
			end

			dbWho(name, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height, ircID, false)
		end

		if tmp.steam == 0 then
			irc_chat(name, "Players who visited within " .. tmp.range .. " metres of " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
			dbWho(name, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height, ircID, false)
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: pay {player} {amount of {monies}}")
		irc_chat(name, "eg. pay joe 1000.  Joe will receive 1000 {monies} and will be alerted with a private message.  You will also see a confirmation message that you have paid them.")
		irc_chat(name, "Only owners and level 1 admins can do this on IRC.")
		irc_chat(name, ".")
	end

	if (words[1] == "pay") then
		if (players[ircID].accessLevel > 1) then
			irc_chat(name, "Restricted command.")
			irc_params = {}
			return
		end

		name1 = words[2]
		name1 = string.trim(name1)
		pid = LookupPlayer(name1)

		if pid ~= 0 then
			players[pid].cash = players[pid].cash + number
			conn:execute("UPDATE players set cash = " .. escape(players[pid].cash) .. " WHERE steam = " .. pid)
			message("pm " .. pid .. " " .. players[ircID].name .. " just paid you " .. number .. " " .. server.moneyPlural .. "!  You now have " .. string.format("%d", players[pid].cash) .. " " .. server.moneyPlural .. "!  KA-CHING!!")

			msg = "You just paid " .. number .. " " .. server.moneyPlural .. " to " .. players[pid].name .. " giving them a total of " .. string.format("%d", players[pid].cash) .. " " .. server.moneyPlural .. "."
			irc_chat(name, msg)
		else
			irc_chat(name, "No player found called " .. name1)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: set player {name} cash {value}")
		irc_chat(name, "Command: set player everyone cash {value}")
		irc_chat(name, "Reset a player's cash to a specific amount to fix stuff-ups, or reset everyone's cash if you type everyone instead of a player name.")
		irc_chat(name, ".")
	end

	if words[1] == "set" and words[2] == "player" and (string.find(msg, "cash") or string.find(msg, "money") or string.find(msg, server.moneyPlural)) and players[ircID].accessLevel == 0 then
		if words[3] ~= "everyone" then
			name1 = words[3]
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if pid ~= 0 then
				if numbers[2] ~= nil then
					number = numbers[2]
					players[pid].cash = number
				else
					if numbers[1] ~= nil then
						number = numbers[1]
						players[pid].cash = number
					else
						irc_chat(name, "Expected a number for cash but no cash found. Check under your seat, might be some cash there. xD")
						irc_params = {}
						return
					end
				end

				players[pid].cash = number
				conn:execute("UPDATE players set cash = " .. escape(players[pid].cash) .. " WHERE steam = " .. pid)
				msg = "You set " .. players[pid].name .. "'s " .. server.moneyPlural .. " to " .. number
				irc_chat(name, msg)
			else
				irc_chat(name, "No player found called " .. name1)
			end
		else
			if numbers[2] ~= nil then
				number = numbers[2]
			else
				if numbers[1] ~= nil then
					number = numbers[1]
				else
					irc_chat(name, "Expected a number for cash but no cash found. Check under your seat, might be some cash there. xD")
					irc_params = {}
					return
				end
			end

			for k,v in pairs(players) do
				v.cash = number
			end

			conn:execute("UPDATE players set cash = " .. escape(number))
			msg = "You set everyone's " .. server.moneyPlural .. " to " .. number
			irc_chat(name, msg)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: set update branch {branch name}")
		irc_chat(name, "Tell the bot to switch to a different code branch.")
		irc_chat(name, ".")
	end

	if words[1] == "set" and words[2] == "update" and words[3] == "branch" and words[4] ~= nil then
		server.server.updateBranch = words[4]
		irc_chat(name, "The bot will check for updates from the " .. server.updateBranch .. " code branch.")
		irc_chat(name, ".")
		conn:execute("UPDATE server SET updateBranch = '" .. escape(server.updateBranch) .. "'")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: enable/disable debug")
		irc_chat(name, "If you have access to Mudlet you can enable or disable debug output to Mudlet's debug and lists windows. This automatically disables itself when Mudlet is closed.")
		irc_chat(name, ".")
	end

	if (words[1] == "enable" or words[1] == "disable") and words[2] == "debug" and words[3] == nil then
		if words[1] == "enable" then
			server.enableWindowMessages = true
			irc_chat(name, "Debugging enabled")
		else
			server.enableWindowMessages = false
			irc_chat(name, "Debugging disabled")
		end

		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: claims {optional player}")
		irc_chat(name, "List all of the claims on the server or a specific player's claims.")
		irc_chat(name, ".")
	end

	if (words[1] == "claims") then
		if debug then dbug("debug ircmessage " .. msg) end
		if players[ircID].ircAuthenticated == false then
			if requireLogin(name) then
				irc_params = {}
				return
			end
		end

		pid = 0

		if (words[2] ~= nil) then
			name1 = string.sub(msg, string.find(msgLower, "claims") + 7)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)
		end

		if pid ~= 0 then
			if players[pid].keystones == 0 then
				msg = players[pid].name .. " has not placed any claims."
				irc_chat(name, msg)
				irc_params = {}
				return
			end
		end


		if pid == 0 then
			for k, v in pairs(players) do
				if tonumber(v.keystones) > 0 then
					msg = v.keystones .. "   claims belong to " .. k .. " " .. v.name
					irc_chat(name, msg)
				end
			end
		else
			msg = players[pid].name .. " has placed " .. players[pid].keystones .. " at these coordinates.."
			irc_chat(name, msg)

			cursor,errorString = conn:execute("SELECT * FROM keystones WHERE steam = " .. pid)
			row = cursor:fetch({}, "a")
			while row do
				msg = row.x .. " " .. row.y .. " " .. row.z
				irc_chat(name, msg)
				row = cursor:fetch(row, "a")
			end
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: cmd {normal ingame command}")
		irc_chat(name, "Use an in-game command from IRC.  The command is identical to how you use it in-game except you prefix it with cmd.  eg.  cmd /uptime.  Not all in-game commands allow you to use them from IRC and will tell you if you can't use them.")
		irc_chat(name, ".")
	end

	if (words[1] == "cmd") then
		msg = string.trim(string.sub(msg, string.find(msgLower, "cmd") + 4))
		gmsg(msg, ircID)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: pm {player} {message}")
		irc_chat(name, "")
		irc_chat(name, ".")
	end

	if (words[1] == "pm") then
		pid = LookupPlayer(words[2])

		if pid ~= 0 then
			msg = string.sub(msg, string.find(msg, words2[2], nil, true) + string.len(words2[2]) + 1)

			if igplayers[pid] then
				message("pm " .. pid .. " " .. name .. "-irc: [i]" .. msg .. "[-]")
				irc_chat(name, "pm sent to " .. players[pid].name .. " you said " .. msg)
			else
				conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (" .. ircID .. "," .. pid .. ", '" .. escape(msg) .. "')")
				irc_chat(name, "Mail sent to " .. players[pid].name .. " you said " .. msg)
				irc_chat(name, "They will receive your message when they join the server.")
			end
		else
			irc_chat(name, "No player called " .. words[2] .. " found.")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

-- ************************************************************************************************

	if displayIRCHelp then
		irc_chat(name, "Command: con {console command}")
		irc_chat(name, "Send a console command to the server.  If you don't see the console output on IRC it will be a command that the bot doesn't pipe back to IRC.  The command will still be ran.  This feature is restricted to server owners.")
		irc_chat(name, ".")
	end

	if (words[1] == "con") and players[ircID].accessLevel == 0 then
		msg = string.trim(string.sub(msg, string.find(msgLower, "con") + 4))

		-- if string.sub(msg, 1, 4) == "help" then
			-- echoConsoleTo = name
			-- echoConsole = false
		-- end

		if msg == "se" or msg == "webpermission list" or msg == "ban list" or msg == "lp" or msg == "le" or string.sub(msg, 1, 3) == "lpf" or string.sub(msg, 1, 3) == "lpb" or string.sub(msg, 1, 3) == "lps" or msg == "SystemInfo" or msg == "traderlist" or msg == "gg" or msg == "version" or string.sub(msg, 1, 3) == "li " or string.sub(msg, 1, 3) == "si " or string.sub(msg, 1, 4) == "help" then
			echoConsole = false
			echoConsoleTo = name
			echoConsoleTrigger = ""

			if string.sub(msg, 1, 3) == "si " then
				echoConsoleTrigger = string.sub(msg, 4)
			end
		end

		if server.useAllocsWebAPI then
			conQueue[name] = {}
			conQueue[name].ircUser = name
			conQueue[name].command = msg
		end

		if msg ~= "lp" then
			sendCommand(msg)
		end

		irc_params = {}
		return
	end
-- ************************************************************************************************

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: set bot owner {steam ID}")
		irc_chat(name, "Assign a steam ID as owner of this bot. Only 1 steam ID can be the bot owner and this can only be assigned once.")
		irc_chat(name, "This isn't currently used by the bot but will be used later.")
		irc_chat(name, "To use this command you must be a level 0 admin and to have been seen on the server by the bot.")
		irc_chat(name, ".")
	end

	if words[1] == "set" and words[2] == "bot" and words[3] == "owner" and words[4] ~= nil and (players[ircID].accessLevel == 0) then
		if tonumber(server.botOwner) ~= 0 then
			irc_chat(name, "The bot owner has already be been set.  To change it now you must manually edit the bot's server table in the database.")
			irc_params = {}
			return
		end

		if not isValidSteamID(words[4]) then
			irc_chat(name, "The steam ID you provided does not look like a steam ID.")
			irc_params = {}
			return
		end

		server.botOwner = words[4]
		conn:execute("UPDATE server SET botOwner = " .. escape(words[4]))
		irc_chat(name, "This bot is owned by steam ID " .. words[4])

		irc_params = {}
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: villagers")
		irc_chat(name, "List all of the villagers.  It also shows who are the mayors.")
		irc_chat(name, ".")
	end

	if (words[1] == "villagers" and words[2] == nil) then
		irc_chat(name, "The following players are villagers:")
		for k, v in pairs(villagers) do
			tmp = v.village .. " " .. players[k].name

			if locations[v.village].mayor == k then
				tmp = text .. " (the mayor of " .. v.village .. ")"
			end

			irc_chat(name, tmp)
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: base cooldown {seconds}")
		irc_chat(name, "Set a timer between uses of the {#}base or {#}home command.  Donors wait half as long.")
		irc_chat(name, ".")
	end

	if (words[1] == "base") and (words[2] == "cooldown" or words[2] == "timer") then
		if words[3] == nil then
			irc_chat(name, server.commandPrefix .. "base can only be used once every " .. (server.baseCooldown / 60) .. " minutes for players and " .. math.floor((server.baseCooldown / 60) / 2) .. " minutes for donors.")
			irc_chat(name, ".")
			irc_params = {}
			return
		end

		if words[3] ~= nil then
			server.baseCooldown = tonumber(words[3])
			irc_chat(name, "The base cooldown timer is now " .. (server.baseCooldown / 60) .. " minutes for players and " .. math.floor((server.baseCooldown / 60) / 2) .. " minutes for donors.")
			irc_chat(name, ".")

			conn:execute("UPDATE server SET baseCooldown = 0")
			irc_params = {}
			return
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: set rules {new rules}")
		irc_chat(name, "Change the server rules.")
		irc_chat(name, ".")
	end

	if (words[1] == "set" and words[2] == "rules") then
		if words[3] ~= nil then
			server.rules = string.sub(msg, string.find(msgLower, "set rules") + 9)
			irc_chat(name, "New server rules recorded: " .. server.rules)
			irc_chat(name, ".")

			conn:execute("UPDATE server SET rules = '" .. escape(server.rules) .. "'")
			irc_params = {}
			return
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: motd")
		irc_chat(name, "View the message of the day.  You can clear it with motd clear.")
		irc_chat(name, ".")
	end

	if (words[1] == "motd") then
		if words[2] == nil then
			irc_chat(name, "MOTD is " .. server.MOTD)
			irc_chat(name, ".")
			irc_params = {}
			return
		end

		if words[2] == "delete" or words[2] == "clear" then
			server.MOTD = nil
			irc_chat(name, "Message of the day has been deleted.")
			irc_chat(name, ".")

			conn:execute("UPDATE server SET MOTD = ''")
			irc_params = {}
			return
		end

		irc_chat(name, "To change the MOTD type set motd <new message of the day>")
		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: set motd {message}")
		irc_chat(name, "Change the message of the day.")
		irc_chat(name, ".")
	end

	if (words[1] == "set" and words[2] == "motd") then
		if words[3] ~= nil then
			server.MOTD = string.sub(msg, string.find(msgLower, "set motd") + 9)
			irc_chat(name, "New message of the day recorded. " .. server.MOTD)
			irc_chat(name, ".")

			conn:execute("UPDATE server SET MOTD = '" .. escape(server.MOTD) .. "'")
			irc_params = {}
			return
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: set api port")
		irc_chat(name, "Tell the bot what port the Alloc's API is using.")
		irc_chat(name, ".")
	end

	if words[1] == "set" and words[2] == "api" and words[3] == "port" and words[4] ~= nil and (players[ircID].accessLevel == 0) then
		if number == nil then
			irc_chat(name, "Port number between 1 and 65535 expected.")
			return
		else
			number = math.abs(number)
		end

		if tonumber(number) > 65535 then
			irc_chat(name, "Valid ports range from 1 to 65535.")
			return
		end

		os.remove(homedir .. "/temp/apitest.txt")
		server.webPanelPort = number
		conn:execute("UPDATE server SET webPanelPort = " .. escape(number))
		irc_chat(name, "You set the web panel port to " .. number)

		if server.useAllocsWebAPI then
			irc_chat(name, "The web API will now be re-tested.")
			os.remove(homedir .. "/temp/apitest.txt")
			startUsingAllocsWebAPI()
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: set api key {API key from 7daystodie-servers.com}")
		irc_chat(name, "Tell the bot your servers API key.  DO NOT do this in a public channel!\n")
		irc_chat(name, "Your key is not logged or displayed anywhere.  It is kept out of the database too.\n")
		irc_chat(name, "Once set, your players will be able to use the command {#}claim vote.\n")
		irc_chat(name, ".")
	end

	if words[1] == "set" and words[2] == "api" and words[3] == "key" and words[4] ~= nil and (players[ircID].accessLevel == 0) then
		serverAPI = wordsOld[4]
		writeAPI()
		irc_chat(name, "Your players can now get rewarded for voting for your server using the command {#}claim vote")
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list tables")
		irc_chat(name, "List the bot's tables.")
		irc_chat(name, ".")
	end

	if (words[1] == "list") and (words[2] == "tables") and (words[3] == nil) and (players[ircID].accessLevel == 0) then
		irc_ListTables()
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: show table {table name} {optional search string}")
		irc_chat(name, "View the contents of one of the bot's tables.  Not all tables will display but you'll soon work out which ones you can view.")
		irc_chat(name, ".")
	end

	if (words[1] == "show") and (words[2] == "table") and (words[3] ~= nil) and (players[ircID].accessLevel == 0) then
		irc_chat(name, "The " .. words[3] .." table: ")

		if words[4] ~= nil then
			words[4] = string.lower(words[4])
		end

		if string.lower(words[3]) == "locations" then
			for k, v in pairs(locations) do
				if words[4] ~= nil then
					if string.find(string.lower(v.name), words[4])  then
						irc_chat(name, "Location " .. k)
						irc_chat(name, ".")

						for n,m in pairs(locations[k]) do
							irc_chat(name, n .. "," .. tostring(m))
						end

						irc_chat(name, ".")
					end
				else
					irc_chat(name, "Location " .. k)
					irc_chat(name, ".")

					for n,m in pairs(locations[k]) do
						irc_chat(name, n .. "," .. tostring(m))
					end

					irc_chat(name, ".")
				end
			end

			irc_chat(name, ".")
			irc_params = {}
			return
		end

		if string.lower(words[3]) == "hotspots" then
			for k, v in pairs(hotspots) do
				irc_chat(name, "Hotspot " .. k)
				irc_chat(name, ".")

				for n,m in pairs(hotspots[k]) do
					irc_chat(name, n .. "," .. tostring(m))
				end

				irc_chat(name, ".")
			end

			irc_chat(name, ".")
			irc_params = {}
			return
		end

		if string.lower(words[3]) == "teleports" then
			for k, v in pairs(teleports) do
				if words[4] ~= nil then
					if string.find(string.lower(v.name), words[4])  then
						irc_chat(name, "Teleport " .. k)
						irc_chat(name, ".")

						for n,m in pairs(teleports[k]) do
							irc_chat(name, n .. "," .. tostring(m))
						end

						irc_chat(name, ".")
					end
				else
					irc_chat(name, "Teleport " .. k)
					irc_chat(name, ".")

					for n,m in pairs(teleports[k]) do
						irc_chat(name, n .. "," .. tostring(m))
					end

					irc_chat(name, ".")
				end
			end

			irc_chat(name, ".")
			irc_params = {}
			return
		end

		if string.lower(words[3]) == "gimmezombies" then
			for k, v in pairs(gimmeZombies) do
				if words[4] ~= nil then
					if string.find(string.lower(v.zombie), words[4])  then
						irc_chat(name, "Zombie " .. k)
						irc_chat(name, ".")

						for n,m in pairs(gimmeZombies[k]) do
							irc_chat(name, n .. "," .. tostring(m))
						end

						irc_chat(name, ".")
					end
				else
					irc_chat(name, "Zombie " .. k)
					irc_chat(name, ".")

					for n,m in pairs(gimmeZombies[k]) do
						irc_chat(name, n .. "," .. tostring(m))
					end

					irc_chat(name, ".")
				end
			end

			irc_chat(name, ".")
			irc_params = {}
			return
		end

		-- other tables
		for k, v in pairs(_G[words[3]]) do
			if words[4] ~= nil then
				if not string.find(string.lower(k),"pass") and string.find(string.lower(k), words[4])  then
					irc_chat(name, k .. "," .. tostring(v))
				end
			else
				if not string.find(string.lower(k),"pass") then
					irc_chat(name, k .. "," .. tostring(v))
				end
			end
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: reset bot keep money")
		irc_chat(name, "Make the bot forget map specific information but remember the player cash.  Use this command after a map wipe.")
		irc_chat(name, ".")
	end

	if words[1] == "reset" and words[2] == "bot" and words[3] == "keep" and words[4] == "money" and (players[ircID].accessLevel == 0) then
		if resetbotCount == nil then resetbotCount = 0 end

		if tonumber(resetbotCount) < 1 then
			resetbotCount = tonumber(resetbotCount) + 1
			irc_chat(name, "ALERT! Only do this after a server wipe!  To reset me repeat the reset bot command again.")
			irc_chat(name, ".")
		end

		ResetBot(true)
		resetbotCount = 0

		irc_chat(name, "I have been reset.  All bases, inventories etc are forgotten, but not the players.")
		irc_chat(name, ".")
		irc_params = {}
		return
	else
		resetbotCount = 0
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: reset bot")
		irc_chat(name, "Make the bot forget map specific information.  Use this command after a map wipe.")
		irc_chat(name, ".")
	end

	if (words[1] == "reset") and (words[2] == "bot") and (players[ircID].accessLevel == 0) then
		if resetbotCount == nil then resetbotCount = 0 end

		if tonumber(resetbotCount) < 1 then
			resetbotCount = tonumber(resetbotCount) + 1
			irc_chat(name, "ALERT! Only do this after a server wipe!  To reset me repeat the reset bot command again.")
			irc_chat(name, ".")
		end

		ResetBot(nil, "UndoReset")
		resetbotCount = 0

		irc_chat(name, "I have been reset.  All bases, inventories etc are forgotten, but not the players.")
		irc_chat(name, ".")
		irc_params = {}
		return
	else
		resetbotCount = 0
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: stop translating {player}")
		irc_chat(name, "Stop sending a player's in-game chat to Google for translating.")
		irc_chat(name, ".")
	end

	if words[1] == "stop" and words[2] == "translating" and words[3] ~= nil then
		name1 = string.sub(msg, string.find(msgLower, "translating") + 11)
		name1 = string.trim(name1)
		pid = LookupPlayer(name1)

		if (pid ~= 0) then
			players[pid].ircTranslate = nil
			players[pid].translate = nil
			irc_chat(name, "Chat from " .. players[pid].name .. " will not be translated")
			irc_chat(name, ".")

			conn:execute("UPDATE players SET translate = 0, ircTranslate = 0 WHERE steam = " .. pid)
		else
			irc_chat(name, "No player found matching " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: translate {player}")
		irc_chat(name, "This command only works if a Linux utility called trans is installed.  It uses Google Translate so I no longer use it since I don't want to risk a huge bill from Google.  It worked great when I used to use it.")
		irc_chat(name, ".")
	end

	if words[1] == "translate" and words[2] ~= nil then
		name1 = string.sub(msg, string.find(msgLower, "translate") + 10)
		name1 = string.trim(name1)
		pid = LookupPlayer(name1)

		if (pid ~= 0) then
			players[pid].translate = true
			irc_chat(name, "Chat from " .. players[pid].name .. " will be translated in-game")
			irc_chat(name, ".")

			conn:execute("UPDATE players SET translate = 1 WHERE steam = " .. pid)
		else
			irc_chat(name, "No player found matching " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: stealth translate {player}")
		irc_chat(name, "Only translate a player's in-game chat to IRC.")
		irc_chat(name, ".")
	end

	if words[1] == "stealth" and words[2] == "translate" and words[3] ~= nil then
		name1 = string.sub(msg, string.find(msgLower, "translate") + 10)
		name1 = string.trim(name1)
		pid = LookupPlayer(name1)

		if (pid ~= 0) then
			players[pid].ircTranslate = true
			irc_chat(name, "Chat from " .. players[pid].name .. " will be translated to irc only")
			irc_chat(name, ".")

			conn:execute("UPDATE players SET ircTranslate = 1 WHERE steam = " .. pid)
		else
			irc_chat(name, "No player found matching " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: open shop")
		irc_chat(name, "Enable the shop so player's can buy stuff and spend their hard earned {monies}.")
		irc_chat(name, ".")
	end

	if (words[1] == "open" and words[2] == "shop") then
		server.allowShop = true

		irc_chat(name, "Players can use the shop and play in the lottery.")
		irc_chat(name, ".")

		conn:execute("UPDATE server SET allowShop = 1")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: close shop")
		irc_chat(name, "Disable the shop.  You'll soon see who can't live without it xD")
		irc_chat(name, ".")
	end

	if (words[1] == "close" and words[2] == "shop") then
		server.allowShop = false

		irc_chat(name, "Only staff can use the shop.")
		irc_chat(name, ".")

		conn:execute("UPDATE server SET allowShop = 0")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "shop" and words[2] == "variation" and words[3] ~= nil) then
		LookupShop(words[3])

		irc_chat(name, "You have changed the price variation for " .. shopItem .. " to " .. words2[4])
		irc_chat(name, ".")

		conn:execute("UPDATE shop SET variation = " .. escape(tonumber(words2[4])) .. " WHERE item = '" .. escape(shopItem) .. "'")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop units {item} {new unit quantity}")
		irc_chat(name, "Change the number of units sold per sale of the specified item.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "units" and words[3] ~= nil) then
		LookupShop(words[3])

		irc_chat(name, "You have changed the units for " .. shopItem .. " to " .. words2[4])
		irc_chat(name, ".")

		conn:execute("UPDATE shop SET units = " .. escape(tonumber(words2[4])) .. " WHERE item = '" .. escape(shopItem) .. "'")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "shop" and words[2] == "special" and words[3] ~= nil) then
		LookupShop(words[3], true)

		if shopItem == "" then
			irc_chat(name, "The item " .. words[3] .. " does not exist.")
			irc_params = {}
			return
		end

		irc_chat(name, "You have changed the special for " .. shopItem .. " to " .. words2[4])
		irc_chat(name, ".")

		conn:execute("UPDATE shop SET special = " .. escape(tonumber(words2[4])) .. " WHERE item = '" .. escape(shopItem) .. "'")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop price {item} {new price}")
		irc_chat(name, "Change the price of an item in the shop.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "price" and words[3] ~= nil) then
		LookupShop(words[3], true)

		if shopItem == "" then
			irc_chat(name, "The item " .. words[3] .. " does not exist.")
			irc_params = {}
			return
		end

		irc_chat(name, "You have changed the price for " .. shopItem .. " to " .. words2[4])
		irc_chat(name, ".")

		conn:execute("UPDATE shop SET price = " .. escape(tonumber(words2[4])) .. " WHERE item = '" .. escape(shopItem) .. "'")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop units {item} {new units}")
		irc_chat(name, "Change the number of units given when buying a specific item in the shop.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "units" and words[3] ~= nil) then
		LookupShop(words[3], true)

		if shopItem == "" then
			irc_chat(name, "The item " .. words[3] .. " does not exist.")
			irc_params = {}
			return
		end

		irc_chat(name, "You have changed the units given for " .. shopItem .. " to " .. words2[4])
		irc_chat(name, ".")

		conn:execute("UPDATE shop SET units = " .. escape(tonumber(words2[4])) .. " WHERE item = '" .. escape(shopItem) .. "'")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop quality {item} {new quality 0-6 or custom number}")
		irc_chat(name, "Change the quality of an item given when buying a specific item in the shop.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "quality" and words[3] ~= nil) then
		LookupShop(words[3], true)

		if shopItem == "" then
			irc_chat(name, "The item " .. words[3] .. " does not exist.")
			irc_params = {}
			return
		end

		irc_chat(name, "You have changed the quality given for " .. shopItem .. " to " .. words2[4])
		irc_chat(name, ".")

		conn:execute("UPDATE shop SET quality = " .. escape(tonumber(words2[4])) .. " WHERE item = '" .. escape(shopItem) .. "'")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop max {item} {max stock level}")
		irc_chat(name, "Set the maximum quantity of an item for sale in the shop.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "max" and words[3] ~= nil) then
		LookupShop(words[3], true)

		if shopItem == "" then
			irc_chat(name, "The item " .. words[3] .. " does not exist.")
			irc_params = {}
			return
		end

		irc_chat(name, "You have changed the max stock level for " .. shopItem .. " to " .. words[4])
		irc_chat(name, ".")

		conn:execute("UPDATE shop SET maxStock = " .. escape(tonumber(words2[4])) .. " WHERE item = '" .. escape(shopItem) .. "'")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop restock {item} {quantity}")
		irc_chat(name, "Increase the quantity of an item in the shop.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "restock" and words[3] ~= nil) then
		LookupShop(wordsOld[3], true)
		shopStock = tonumber(words2[4])

		if shopItem == "" then
			irc_chat(name, "The item " .. wordsOld[3] .. " does not exist.")
			irc_params = {}
			return
		end

		if (shopStock < 0) then
			shopStock = -1
			irc_chat(name, shopItem .. " now has unlimited stock")
		else
			irc_chat(name, "There are now " .. shopStock .. " of " .. shopItem .. " for sale.")
		end

		conn:execute("UPDATE shop SET stock = " .. escape(shopStock) .. " WHERE item = '" .. escape(shopItem) .. "'")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop add category {category name} code {short code}")
		irc_chat(name, "Add a new category to the shop, such as weapons.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "add" and words[3] == "category") then
		shopCategories[words[4]] = {}

		for i=2,wordCount,1 do
			if words[i] == "code" then
				shopCategories[words[4]].code  = words[i+1]
				shopCategories[words[4]].index = 1

				conn:execute("INSERT INTO shopCategories (category, idx, code) VALUES ('" .. escape(words[4]) .. "',1,'" .. escape(words[i+1]) .. "')")
			end
		end

		if (shopCategories[words[4]].code == nil) then
			irc_chat(name, "A code is required. Do not include numbers in the code.")
			irc_params = {}
			return
		end

		irc_chat(name, "You added or updated the category " .. words[4] .. ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop remove category {category name}")
		irc_chat(name, "Remove a category from the shop.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "remove" and words[3] == "category") then
		if not shopCategories[words[4]] then
			irc_chat(name, "The category " .. words[4] .. " does not exist.")
			irc_params = {}
			return
		end

		shopCategories[words[4]] = nil
		conn:execute("DELETE FROM shopCategories WHERE category = '" .. escape(words[4]) .. "'")
		conn:execute("UPDATE shop SET category = '' WHERE category = '" .. escape(words[4]) .. "')")

		irc_chat(name, "You removed the " .. words[4] .. " category from the shop.  Any items using it now have no category.")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop change category {old category} to {new category}")
		irc_chat(name, "Rename a shop category.  All of its items will move to the new category.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "change" and words[3] == "category") then
		if words[5] == "to" then
			oldCategory = words[4]
			newCategory = words[6]
		else
			oldCategory = words[4]
			newCategory = words[5]
		end

		if not shopCategories[oldCategory] then
			irc_chat(name, "The category " .. words[4] .. " does not exist.")
			irc_params = {}
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

		irc_chat(name, "You changed category " .. oldCategory .. " to " .. newCategory .. ". Any items using " .. oldCategory .. " have been updated.")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: inv {player}")
		irc_chat(name, "View the current or last known inventory of a player.")
		irc_chat(name, ".")
	end

	if (words[1] == "inv") then
		tmp = {}
		tmp.name = name

		if words[2] == nil then
			tmp.playerID = players[ircID].selectedSteam
		else
			tmp.playerID = string.trim(string.sub(msg, string.find(msgLower, "inv") + 4))
			tmp.playerID = LookupPlayer(tmp.playerID)
		end

		if (tmp.playerID ~= 0) then
			players[ircID].selectedSteam = tmp.playerID
			irc_NewInventory(tmp)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list villagers {name of village}")
		irc_chat(name, "List all of the village members of a specific village.")
		irc_chat(name, ".")
	end

	if (words[1] == "list" and words[2] == "villagers" and words[3] ~= nil) then
		name1 = string.sub(msg, string.find(msgLower, "villagers") + 10)
		name1 = string.trim(name1)
		pid = LookupVillage(name1)

		if (pid ~= 0) then
			irc_params.pid = pid
			irc_params.pname = players[pid].name
			irc_ListVillagers()
		else
			irc_chat(name, "No village found matching " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list {optional player} bases")
		irc_chat(name, "List all of the player bases or just those of one player.")
		irc_chat(name, ".")
	end

	if words[1] == "list" and (words[2] == "bases" or words[3] == "bases") then
		pid = 0
		for i=2,wordCount,1 do
			if words[i] == "bases" then
				pid = words[i+1]
			end
		end

		if words[2] == "protected" then
			irc_params.filter = "protected"
		else
			irc_params.filter = "all"
		end

		if pid ~= nil then
			pid = LookupPlayer(pid)
		end

		irc_ListBases(pid)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: add bad item {item name} action {exile, ban or timeout} (timeout is the default)")
		irc_chat(name, "Add an item to the bad items list.")
		irc_chat(name, ".")
	end

	if (words[1] == "add" and words[2] == "bad" and words[3] == "item" and words[4] ~= nil and players[ircID].accessLevel == 0) then
		name1 = wordsOld[4]

		if words[5] == "action" then
			action = words[6]

			if not string.find("banexiletimeout", action) then
				action = "timeout"
			end
		else
			action = "timeout"
		end

		-- add the bad item to badItems table
		badItems[name1] = {}
		badItems[name1].action = action

		conn:execute("INSERT INTO badItems (item, action) VALUES ('" .. escape(name1) .. "','" .. escape(action) .. "')")

		irc_chat(name, name1 .. " has been added to the bad items list.  The bot will " .. action .. " players caught with it.")
		irc_chat(name, ".")

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: remove bad item {item name}")
		irc_chat(name, "Remove an item from the bad items list.")
		irc_chat(name, ".")
	end

	if (words[1] == "remove" and words[2] == "bad" and words[3] == "item" and words[4] ~= nil and players[ircID].accessLevel == 0) then
		name1 = wordsOld[4]

		if not badItems[name1] then
			irc_chat(name, name1 .. " has already been removed or you typed the name wrong (case sensitive).")
			irc_params = {}
			return
		end

		-- remove the bad item from the badItems table
		badItems[name1] = nil

		conn:execute("DELETE FROM badItems WHERE item = '" .. escape(name1) .. "'")

		irc_chat(name, name1 .. " has been removed from the bad items list.")
		irc_chat(name, ".")

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: bad item {item name} action {exile, ban or timeout}")
		irc_chat(name, "Change what the bot does when it detects a specific bad item in inventory.")
		irc_chat(name, ".")
	end

	if (words[1] == "bad" and words[2] == "item" and words[3] ~= nil and players[ircID].accessLevel == 0) then
		name1 = wordsOld[3]

		if not badItems[name1] then
			irc_chat(name, name1 .. " is not in the list of bad items.")
			irc_params = {}
			return
		end

		if words[4] == "action" then
			action = words[5]

			if not string.find("banexiletimeout", action) then
				action = "timeout"
			end
		else
			action = "timeout"
		end

		-- add the bad item to badItems table
		badItems[name1].action = action

		conn:execute("UPDATE badItems SET action = '" .. escape(action) .. "' WHERE item = '" .. escape(name1) .. "'")

		irc_chat(name, name1 .. "'s action has been changed to " .. action)
		irc_chat(name, ".")

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: near player {player}")
		irc_chat(name, "Lists players, bases and locations near a player or coordinate.")
		irc_chat(name, "Usage: near player {name}")
		irc_chat(name, "optional: range {number}")
		irc_chat(name, "optional: Instead of player use xpos {number} zpos {number}")
		irc_chat(name, ".")
	end

	if (words[1] == "near") and (words[2] ~= "entity") then
		if words[2] == nil then
			irc_chat(name, "Lists players, bases and locations near a player or coordinate.")
			irc_chat(name, "Usage: near player {name}")
			irc_chat(name, "optional: range {number}")
			irc_chat(name, "optional: Instead of player use xpos {number} zpos {number}")

		end

		name1 = 0
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

		if name1 ~= 0 then
			name1 = string.trim(name1)
			name1 = LookupPlayer(name1)

			if name1 == 0 then
				irc_chat(name, "No player found matching " .. name1)
				irc_params = {}
				return
			end
		end

		if name1 == 0 then
			irc_PlayersNearPlayer(name, "", range, xPos, zPos, offline)
			irc_BasesNearPlayer(name, "", range, xPos, zPos)
			irc_LocationsNearPlayer(name, "", range, xPos, zPos)
			irc_EntitiesNearPlayer(name, "", range, xPos, zPos)
		else
			irc_PlayersNearPlayer(name, name1, range, xPos, zPos, offline)
			irc_BasesNearPlayer(name, name1, range, xPos, zPos)
			irc_LocationsNearPlayer(name, name1, range, xPos, zPos)
			irc_EntitiesNearPlayer(name, name1, range, xPos, zPos)
		end

		irc_params = {}
		sendCommand("le")
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: info {player}")
		irc_chat(name, "View info about a player including links to some 7 Days related websites and the player's DNS record.")
		irc_chat(name, ".")
	end

	if (words[1] == "info") then
		if words[2] == nil then
			pid = players[ircID].selectedSteam
		else
			name1 = string.sub(msg, string.find(msgLower, "info") + 5)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)
		end

		if (pid ~= 0) then
			players[ircID].selectedSteam = pid
			irc_params.pid = pid
			irc_params.pname = players[pid].name

			irc_PlayerShortInfo()
			irc_friends()
		else
			irc_chat(name, "No player found matching " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: add donor {player}")
		irc_chat(name, "Give a player donor status.  They get a few special privileges but it is not play to win.  There are no game items included.")
		irc_chat(name, ".")
	end

	if (words[1] == "add" and words[2] == "donor" and words[3] ~= nil and owners[ircID]) then
		name1 = string.sub(msg, string.find(msgLower, "donor") + 6)
		name1 = string.trim(name1)
		pid = LookupPlayer(name1)

		if pid ~= 0 then
			-- update the player record
			players[pid].donor = true
			irc_chat(name, players[pid].name .. " is now a donor.")
			irc_chat(name, ".")

			conn:execute("UPDATE players SET donor = 1 WHERE steam = " .. pid)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: remove donor {player}")
		irc_chat(name, "Remove a player's donor status.")
		irc_chat(name, ".")
	end

	if (words[1] == "remove" and words[2] == "donor" and words[3] ~= nil and owners[ircID]) then
		name1 = string.sub(msg, string.find(msgLower, "donor") + 6)
		name1 = string.trim(name1)
		pid = LookupPlayer(name1)

		if pid ~= 0 then
			-- update the player record
			players[pid].donor = false
			irc_chat(name, players[pid].name .. " is no longer a donor.")
			irc_chat(name, ".")

			conn:execute("UPDATE players SET donor = 0 WHERE steam = " .. pid)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: add owner {player}")
		irc_chat(name, "Give a player owner status which is the highest admin status in the bot and server.")
		irc_chat(name, ".")
	end

	if (words[1] == "add" and words[2] == "owner" and words[3] ~= nil and owners[ircID]) then
		name1 = string.sub(msg, string.find(msgLower, "owner") + 6)
		name1 = string.trim(name1)
		pid = LookupPlayer(name1)

		if pid ~= 0 then
			-- add the steamid to the owners table
			owners[pid] = {}
			irc_chat(name, players[pid].name .. " has been added as a server owner.")
			irc_chat(name, ".")

			sendCommand("admin add " .. pid .. " 0")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: remove owner {player}")
		irc_chat(name, "Remove an owner so they are just a regular player.")
		irc_chat(name, ".")
	end

	if (words[1] == "remove" and words[2] == "owner" and words[3] ~= nil and owners[ircID]) then
		name1 = string.sub(msg, string.find(msgLower, "owner") + 6)
		name1 = string.trim(name1)
		pid = LookupPlayer(name1)

		if pid ~= 0 then
			-- remove the steamid from the owners table
			owners[pid] = nil
			irc_chat(name, players[pid].name .. " is no longer a server owner.")
			irc_chat(name, ".")

			sendCommand("admin remove " .. pid)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: add admin {player}")
		irc_chat(name, "Give a player admin status.   Note:  This gives them level 1 admin status only.")
		irc_chat(name, ".")
	end

	if (words[1] == "add" and words[2] == "admin" and words[3] ~= nil and owners[ircID]) then
		name1 = string.sub(msg, string.find(msgLower, "admin") + 6)
		name1 = string.trim(name1)
		pid = LookupPlayer(name1)

		if pid ~= 0 then
			-- add the steamid to the admins table
			admins[pid] = {}
			irc_chat(name, players[pid].name .. " has been added as a server admin.")
			irc_chat(name, ".")

			sendCommand("admin add " .. pid .. " 1")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: remove admin {player}")
		irc_chat(name, "OUT!  Remove an admin.  They become a player again.")
		irc_chat(name, ".")
	end

	if (words[1] == "remove" and words[2] == "admin" and words[3] ~= nil and players[ircID].accessLevel == 0) then
		name1 = string.sub(msg, string.find(msgLower, "admin") + 6)
		name1 = string.trim(name1)

		pid = LookupPlayer(name1)

		if pid ~= 0 then
			-- remove the steamid from the admins table
			admins[pid] = nil
			irc_chat(name, players[pid].name .. " is no longer a server admin.")
			irc_chat(name, ".")

			sendCommand("admin remove " .. pid)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: permaban {jackass}")
		irc_chat(name, "Ban and permanban a player. Not currently used by the bot, but the ban works.")
		irc_chat(name, ".")
	end

	if (words[1] == "permaban") then
		name1 = string.trim(string.sub(msg, string.find(msgLower, "permaban") + 9))
		pid = LookupPlayer(name1)

		if (pid ~= 0) then
			banPlayer(pid, "10 years", "Permanent ban", ircID)

			irc_chat(name, name1 .. " has been banned for 10 years.")
			irc_chat(name, ".")

			conn:execute("UPDATE players SET permanentBan = 1 WHERE steam = " .. pid)
			players[pid].permanentBan = true
		else
			irc_chat(name, "No player found matching " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: remove permaban {player}")
		irc_chat(name, "Unban a player and remove their permaban status. Not currently used by the bot, but it will unban them.")
		irc_chat(name, ".")
	end

	if (words[1] == "remove" and words[2] == "permaban") then
		name1 = string.trim(string.sub(msg, string.find(msgLower, "permaban") + 9))
		pid = LookupPlayer(name1)

		if (pid ~= 0) then
			conn:execute("UPDATE players SET permanentBan = 0 WHERE steam = " .. pid)
			sendCommand("ban remove " .. pid)
			players[pid].permanentBan = false
			irc_chat(name, "Ban lifted for player " .. name1)
			irc_chat(name, ".")
		else
			irc_chat(name, "No player found matching " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: add player {player} login {name} pass {password}")
		irc_chat(name, "Authorise a player to login to the bot here on IRC.  They can login with login {name} pass {password}.  They must not use that in any public channels, only in private with the bot or the bot will destroy their login.")
		irc_chat(name, ".")
	end

	if (words[1] == "add" and words[2] == "player") then
		tmp = {}
		tmp.name = string.trim(string.sub(msg, string.find(msgLower, "player ") + 7, string.find(msgLower, " login") - 1))

		for i=3,wordCount,1 do
			if words[i] == "login" then
				tmp.login = wordsOld[i+1]
			end

			if words[i] == "pass" then
				tmp.pass = wordsOld[i+1]
			end
		end

		pid = LookupOfflinePlayer(tmp.name)
		if (pid ~= 0) then
			players[pid].ircLogin = tmp.login
			players[pid].ircPass = tmp.pass

			irc_chat(name, players[pid].name .. " is now authorised to talk to ingame players")
			irc_chat(name, ".")

			conn:execute("UPDATE players SET ircLogin = '" .. escape(tmp.login) .. "', ircPass = '" .. escape(tmp.pass) .. "' WHERE steam = " .. pid)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: player {player one} unfriend {player two}")
		irc_chat(name, "Make a player no longer friends with another player.  Does not change friend status done through the game's own friend system.")
		irc_chat(name, ".")
	end

	if (words[1] == "player" and string.find(msgLower, "unfriend")) then
		name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, "unfriend") - 1))
		name2 = string.trim(string.sub(msg, string.find(msgLower, "unfriend") + 9))

		pid = LookupPlayer(name1)
		if (pid ~= 0) then
			irc_params.pid = pid
			pid = LookupPlayer(name2)
			if (pid ~= 0) then
				irc_params.pid2 = pid
				irc_unfriend()
			else
				irc_chat(name, "No player found matching " .. name2)
				irc_chat(name, ".")
			end
		else
			irc_chat(name, "No player found matching " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: player {player one} friend {player two}")
		irc_chat(name, "Make friends.  No not you!  Make a player friends with another player.")
		irc_chat(name, ".")
	end

	if (words[1] == "player" and string.find(msgLower, "friend")) then
		name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, "friend") - 1))
		name2 = string.trim(string.sub(msg, string.find(msgLower, "friend") + 7))

		pid = LookupPlayer(name1)
		if (pid ~= 0) then
			irc_params.pid = pid
			pid = LookupPlayer(name2)
			if (pid ~= 0) then
				irc_params.pid2 = pid
				irc_friend()
			else
				irc_chat(name, "No player found matching " .. name2)
				irc_chat(name, ".")
			end
		else
			irc_chat(name, "No player found matching " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: friends {player}")
		irc_chat(name, "View all of the friends of a player known to the bot or the game.")
		irc_chat(name, ".")
	end

	if (words[1] == "friends") then
		name1 = string.trim(string.sub(msg, string.find(msgLower, "friends") + 8))
		pid = LookupPlayer(name1)

		if (pid ~= 0) then
			irc_params.pid = pid
			irc_params.pname = players[pid].name
			irc_friends()
		else
			irc_chat(name, "No player found matching " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: players {optional player name}")
		irc_chat(name, "Get a list of all of the players or a specific player (except archived players).")
		irc_chat(name, ".")
	end

	if (words[1] == "players") and players[ircID].accessLevel < 3 then
		if words[2] ~= nil then
			irc_params.pname = string.sub(msg, 9)
		end

		irc_listAllPlayers(name)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: archived players {optional player name}")
		irc_chat(name, "Get a list of all the players that have been archived or a specific player.")
		irc_chat(name, ".")
	end

	if words[1] == "archived" and words[2] == "players" and players[ircID].accessLevel < 3 then
		if words[3] ~= nil then
			irc_params.pname = string.sub(msg, 18)
		end

		irc_listAllArchivedPlayers(name)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: player {name}")
		irc_chat(name, "Command: player {name} find {search string}")
		irc_chat(name, "View the permanent record for a player or you can just list specific info using find.  eg player smegz find home.")
		irc_chat(name, ".")
	end

	if (words[1] == "player") then
		if not string.find(msg, " find ") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7))
			search = ""
		else
			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, " find ") - 1))
			search = string.trim(string.sub(msg, string.find(msgLower, " find ") + 6))
			search = string.lower(search)
		end

		pid = LookupOfflinePlayer(name1)

		if (pid ~= 0) then
			if (players[pid]) then
				irc_chat(name, "Player record of: " .. pid .. " " .. players[pid].name)
				for k, v in pairs(players[pid]) do
					cmd = ""

					if k ~= "ircPass" then
						if search ~= "" then
							if string.find(string.lower(k), search) then
								cmd = k .. "," .. tostring(v)
							end
						else
							cmd = k .. "," .. tostring(v)
						end

						if cmd ~= "" then
							irc_chat(name, cmd)
						end
					end
				end
			else
				irc_chat(name, ".")
				irc_chat(name, "I do not know a player called " .. name1)
			end

			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: archived player {name}")
		irc_chat(name, "Command: archived player {name} find {search string}")
		irc_chat(name, "View the permanent record for an archived player or you can just list specific info using find.  eg archived player smegz find home.")
		irc_chat(name, ".")
	end

	if words[1] == "archived" and words[2] == "player" then
		if not string.find(msg, " find ") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7))
			search = ""
		else
			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, " find ") - 1))
			search = string.trim(string.sub(msg, string.find(msgLower, " find ") + 6))
			search = string.lower(search)
		end

		pid = LookupArchivedPlayer(name1)

		if (pid ~= 0) then
			if (playersArchived[pid]) then
				irc_chat(name, "Archived player record of: " .. pid .. " " .. playersArchived[pid].name)
				for k, v in pairs(playersArchived[pid]) do
					cmd = ""

					if k ~= "ircPass" then
						if search ~= "" then
							if string.find(string.lower(k), search) then
								cmd = k .. "," .. tostring(v)
							end
						else
							cmd = k .. "," .. tostring(v)
						end

						if cmd ~= "" then
							irc_chat(name, cmd)
						end
					end
				end
			else
				irc_chat(name, ".")
				irc_chat(name, "I do not know a player called " .. name1)
			end

			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: igplayer {name}")
		irc_chat(name, "Command: igplayer {name} find {search string}")
		irc_chat(name, "View the bot's record for a player that is currently on the server.")
		irc_chat(name, ".")
	end

	if (words[1] == "igplayer") then
		if not string.find(msg, " find ") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "igplayer") + 9))
			search = ""
		else
			name1 = string.trim(string.sub(msg, string.find(msgLower, "igplayer") + 9, string.find(msgLower, " find ") - 1))
			search = string.trim(string.sub(msg, string.find(msgLower, " find ") + 6))
			search = string.lower(search)
		end

		pid = LookupPlayer(name1)

		if (pid ~= 0) then
			irc_params.pid = pid
			irc_params.pname = players[pid].name
			irc_params.search = search
			irc_IGPlayerInfo()
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: igplayers")
		irc_chat(name, "View the bot's record for each player that is currently on the server.")
		irc_chat(name, ".")
	end

	if (words[1] == "igplayers" and words[2] == nil) then

		for k,v in pairs(igplayers) do
			irc_params.pid = k
			irc_params.pname = players[k].name
			irc_IGPlayerInfo()
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (words[1] == "igplayers" and words[2] ~= nil) then
		for k,v in pairs(igplayers) do
			irc_chat(irc_params.name, "steam, " .. v.steam .. " id," .. v.id .. " name," .. v.name .. " connected," .. tostring(v.connected) .. " killTimer," .. v.killTimer)
		end

		irc_chat(name, ".")
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: watch {player}")
		irc_chat(name, "")
		irc_chat(name, ".")
	end

	if (words[1] == "watch") then
		name1 = string.trim(string.sub(msg, string.find(msgLower, "watch") + 6))
		pid = LookupPlayer(name1)

		if (pid ~= 0) then
			players[pid].watchPlayer = true

			conn:execute("UPDATE players SET watchPlayer = 1 WHERE steam = " .. pid)

			irc_chat(name, "Now watching player " .. players[pid].name)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: stop watching {player}")
		irc_chat(name, "Stop getting in-game messages about a player every time their inventory changes or they get too close to a base.")
		irc_chat(name, ".")
	end

	if (words[1] == "stop" and words[2] == "watching") then
		name1 = string.trim(string.sub(msg, string.find(msgLower, "watching") + 9))
		pid = LookupPlayer(name1)

		if (pid ~= 0) then
			players[pid].watchPlayer = false

			conn:execute("UPDATE players SET watchPlayer = 0 WHERE steam = " .. pid)

			irc_chat(name, "No longer watching player " .. players[pid].name)
			irc_chat(name, ".")
		else
			irc_chat(name, "No player matched " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: donors {optional player name}")
		irc_chat(name, "List all of the donors or a specific donor.")
		irc_chat(name, ".")
	end

	if (words[1] == "donors") then
		tmp = {}
		tmp.count = 0
		tmp.name = ""
		conn:execute("DELETE FROM list WHERE steam = " .. ircID)

		if words[2] == nil then
			irc_chat(name, "These are all the donors on record:")

			for k,v in pairs(donors) do
				name1 = ""

				if players[k] then
					name1 = players[k].name
				end

				if playersArchived[k] then
					name1 = playersArchived[k].name
				end

				conn:execute("INSERT INTO list (thing, class, steam) VALUES ('" .. escape(name1) .. "','" .. k .. "'," .. ircID .. ")")
				tmp.count = tmp.count + 1
			end

			cursor,errorString = conn:execute("SELECT * FROM list where steam = " .. ircID .. " order by thing")
			row = cursor:fetch({}, "a")
			while row do
				tmp.steam = row.class

				diff = os.difftime(players[tmp.steam].donorExpiry, os.time())
				days = math.floor(diff / 86400)

				if (days > 0) then
					diff = diff - (days * 86400)
				end

				hours = math.floor(diff / 3600)

				if (hours > 0) then
					diff = diff - (hours * 3600)
				end

				minutes = math.floor(diff / 60)

				if tonumber(days) < 0 then
					irc_chat(name, "steam: " .. tmp.steam .. " id: " .. string.format("%-8d", players[tmp.steam].id) .. " name: " .. players[tmp.steam].name .. " cash " ..string.format("%d",  players[tmp.steam].cash) .. " *** expired ***")
				else
					irc_chat(name, "steam: " .. tmp.steam .. " id: " .. string.format("%-8d", players[tmp.steam].id) .. " name: " .. players[tmp.steam].name .. " cash " .. string.format("%d", players[tmp.steam].cash) .. " expires in " .. days .. " days " .. hours .. " hours " .. minutes .." minutes")
				end

				row = cursor:fetch(row, "a")
			end

			conn:execute("DELETE FROM list WHERE steam = " .. ircID)

			irc_chat(name, "Total donors: " .. tmp.count)
		else
			tmp.name = string.sub(msg, 8)
			tmp.steam = LookupPlayer(tmp.name)

			if players[tmp.steam] then
				irc_chat(name, "Donor record of " .. tmp.name .. ":")

				diff = os.difftime(players[tmp.steam].donorExpiry, os.time())
				days = math.floor(diff / 86400)

				if (days > 0) then
					diff = diff - (days * 86400)
				end

				hours = math.floor(diff / 3600)

				if (hours > 0) then
					diff = diff - (hours * 3600)
				end

				minutes = math.floor(diff / 60)

				if tonumber(days) < 0 then
					irc_chat(name, "steam: " .. tmp.steam .. " id: " .. string.format("%-8d", players[tmp.steam].id) .. " name: " .. players[tmp.steam].name .. " cash " .. string.format("%d", players[tmp.steam].cash) .. " *** expired ***")
				else
					irc_chat(name, "steam: " .. tmp.steam .. " id: " .. string.format("%-8d", players[tmp.steam].id) .. " name: " .. players[tmp.steam].name .. " cash " .. string.format("%d", players[tmp.steam].cash) .. " expires in " .. days .. " days " .. hours .. " hours " .. minutes .." minutes")
				end
			else
				irc_chat(name, "No player found like " .. tmp.name)
			end
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: teleports")
		irc_chat(name, "List all of the teleports.  These are not locations or waypoints.  They are special teleports that players step onto in-game to get automatically teleported somewhere.")
		irc_chat(name, ".")
	end

	if (words[1] == "teleports" and words[2] == nil) then
		irc_chat(name, "List of teleports:")

		for k, v in pairs(teleports) do
			if (v.public == true) then
				public = "public"
			else
				public = "private"
			end

			irc_chat(name, v.name .. "." .. public)
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list bad items")
		irc_chat(name, "")
		irc_chat(name, ".")
	end

	if (words[1] == "list" and words[2] == "bad" and words[3] == "items") then
		irc_chat(name, "I scan for these bad items in inventory:")

		for k, v in pairs(badItems) do
			irc_chat(name, k .. " -> " .. v.action)
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: prisoners")
		irc_chat(name, "List all of the current prisoners. If a reason was recorded, that will be shown too.")
		irc_chat(name, ".")
	end

	if (words[1] == "prisoners" and words[2] == nil) then
		irc_chat(name, "List of prisoners:")

		for k, v in pairs(players) do
			if v.prisoner then
				tmp = {}

				if v.prisonReason then
					tmp.reason = v.prisonReason
				else
					tmp.reason = ""
				end

				if tonumber(v.pvpVictim) == 0 then
					irc_chat(name, k .. " " .. players[k].name .. " " .. tmp.reason)
				else
					irc_chat(name, k .. " " .. players[k].name .. " PVP " .. players[v.pvpVictim].name .. " " .. v.pvpVictim)
				end
			end
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: li {item name}")
		irc_chat(name, "List game items.  eg. li boots, will list all items with boots in their name.")
		irc_chat(name, ".")
	end

	if (words[1] == "li" and words[2] ~= nil) then
		ircListItems = ircID
		sendCommand("li " .. words[2])
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list prefabs {optional partial name of a prefab}")
		irc_chat(name, "Lists of all the prefabs known to the server or a filtered list if you specify part of a prefab name.")
		irc_chat(name, ".")
	end

	if (words[1] == "list" and words[2] == "prefabs") then
		ircListItems = ircID
		ircListItemsFilter = ""

		if words[3] ~= nil then
			ircListItemsFilter = string.lower(words[3])
		end

		sendCommand("bc-go prefabs")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: status {player}")
		irc_chat(name, "View some info about a player's bases and donor status.")
		irc_chat(name, ".")
	end

	if (words[1] == "status") then
		name1 = string.trim(string.sub(msg, string.find(msgLower, "status") + 7))
		pid = LookupPlayer(name1)

		if (pid ~= 0) then
			irc_params.pid = pid
			irc_params.pname = players[pid].name
			irc_playerStatus()
		else
			irc_chat(name, "No player found matching " .. name1)
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop add item {item name} category {category} price {price} stock {max stock} units {units spawned} quality {0-6}")
		irc_chat(name, "Add an item to the shop.  If a unit is given and a player buys 1 item, the bot will give 1 * the unit eg. 10 of the item.")
		irc_chat(name, "If quality is set to 0 the spawned item will have a random quality.  You can set any number that is supported by your server (usually 1-6).")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "add" and words[3] == "item" and words[4] ~= nil) then
		LookupShop(wordsOld[4], "all")

		if shopCode ~= "" then
			irc_chat(name, "The item " .. shopCode .. " already exists.")
		else
			class = "misc"
			price = 10000
			stock = 0
			units = 0
			quality = 0

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

				if words[i] == "units" then
					units = tonumber(words[i+1])
				end

				if words[i] == "quality" then
					quality = tonumber(words[i+1])
				end
			end

			irc_chat(name, "You added " .. wordsOld[4] .. " to the shop.  You will need to add any missing info such as code, category, units, price, quality and quantity.")

			conn:execute("INSERT INTO shop (item, category, stock, maxStock, price, units, quality) VALUES ('" .. escape(wordsOld[4]) .. "','" .. escape(class) .. "'," .. stock .. "," .. stock .. "," .. price .. "," .. units .. "," .. quality .. ")")

			reindexShop(class)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: empty shop")
		irc_chat(name, "Completely empty the shop so you can start fresh.")
		irc_chat(name, ".")
	end

	if (words[1] == "empty" and words[2] == "shop") then
		conn:execute("TRUNCATE shop")
		conn:execute("DELETE FROM shopCategories WHERE category <> 'misc'")
		loadShopCategories()
		irc_chat(name, "You emptied the shop.  Only the misc category remains.")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: shop remove item {item name}")
		irc_chat(name, "Remove an item from the shop.")
		irc_chat(name, ".")
	end

	if (words[1] == "shop" and words[2] == "remove" and words[3] == "item") then
		LookupShop(wordsOld[4], "all")

		if shopCode ~= "" then
			conn:execute("DELETE FROM shop WHERE item = '" .. escape(shopItem) .. "'")
			reindexShop(shopCategory)
			irc_chat(name, "You removed the item " .. shopItem .. " from the shop.")
		else
			irc_chat(name, "The item " .. wordsOld[4] .. " does not exist.")
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: add command {command} access {minimum access level} message {private message}")
		irc_chat(name, "Add a custom command.  At the moment these are just a private message.  Later more actions will be possible.")
		irc_chat(name, ".")
	end

	if (words[1] == "add" and words[2] == "command" and players[ircID].accessLevel < 3) then
		cmd = words[3]

		if words[4] == "access" then
			number = tonumber(words[5])
		else
			number = 99
		end

		tmp = string.trim(string.sub(msg, string.find(msgLower, "message") + 8))

		if tmp == nil then
			irc_chat(name, "Bad command.  This is used to create commands that send a private message to the player. You can add an optional access level.  99 is the default.")
			irc_chat(name, "Valid access levels are 99 (everyone), 90 (regulars), 4 (donors), 2 (mods), 1 (admins) 0 (owners)")
			irc_chat(name, "These commands are searched after all other commands. If an identical command exists, it will be used instead. Test the commands you add.")
			irc_chat(name, "Correct syntax is: add command {command} access {99 to 0} message {private message}")
		end

		-- add the custom message to table customMessages
		conn:execute("INSERT INTO customMessages (command, message, accessLevel) VALUES ('" .. escape(cmd) .. "','" .. escape(tmp) .. "'," .. number .. ") ON DUPLICATE KEY UPDATE accessLevel = " .. number .. ", message = '" .. escape(tmp) .. "'")

		-- reload from the database
		loadCustomMessages()

		irc_chat(name, cmd .. " has been added to custom commands.")
		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: remove command {command}")
		irc_chat(name, "Delete a custom command.")
		irc_chat(name, ".")
	end

	if (words[1] == "remove" and words[2] == "command" and players[ircID].accessLevel < 3) then
		cmd = words[3]

		-- remove the custom message from table customMessages
		conn:execute("DELETE FROM customMessages WHERE command = '" .. escape(cmd) .. "'")

		-- remove it from the Lua table
		customMessages[cmd] = nil

		irc_chat(name, cmd .. " has been removed from custom commands.")
		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: blacklist add {player}")
		irc_chat(name, "Add a player to the bot's blacklist.  The bot will ban them for 10 years.")
		irc_chat(name, ".")
	end

	if (words[1] == "blacklist" and words[2] == "add" and players[ircID].accessLevel < 3) then
		pid = LookupPlayer(words[3])

		if pid ~= 0 then
			banPlayer(pid, "10 years", "blacklisted", ircID)
			irc_chat(name, "Player " .. pid  .. " " .. players[pid].name .. " has been blacklisted 10 years.")
			irc_params = {}
			return
		else
			banPlayer(words[3], "10 years", "blacklisted", ircID)
			irc_chat(name, "Player " .. words[3] .. " has been blacklisted 10 years.")
			irc_params = {}
			return
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: ban remove {player}")
		irc_chat(name, "Unban a player.")
		irc_chat(name, ".")
	end

	if (words[1] == "blacklist" or words[1] == "ban" and words[2] == "remove" and players[ircID].accessLevel < 3) then
		pid = LookupPlayer(words[3])
		if pid ~= 0 then
			sendCommand("ban remove " .. pid)
			irc_chat(name, "Player " .. pid  .. " " .. players[pid].name .. " has been unbanned.")
			irc_params = {}
			return
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list event {event type}")
		irc_chat(name, "Several events are logged and can be searched with list event. Select from any of the following or add a player name or steam ID.")
		irc_chat(name, "eg. list event ban. Matching events in the last day are displayed.  To see more days add a number eg. list event ban 5")
		irc_chat(name, ".")
	end

	if words[1] == "list" and string.find(words[2], "event") then
		if words[3] == nil then
			-- display command help
			irc_chat(name, "Several events are logged and can be searched with list event. Search for an event and/or add a player name or steam ID.")
			irc_chat(name, "eg. list event ban. Matching events in the last day are displayed.  To see more days add a number eg. list event ban 5")
			irc_chat(name, "For a list of events that can be searched for, just type list event.")
			irc_chat(name, ".")

			cursor,errorString = conn:execute("SELECT DISTINCT type from events order by type")
			row = cursor:fetch({}, "a")
			while row do
				irc_chat(name, row.type)
				row = cursor:fetch(row, "a")
			end

			irc_chat(name, ".")
			irc_params = {}
			return
		end

		for i=4,wordCount,1 do
			if words[i] == "player" then
				pid = words[i+1]
				pid = LookupPlayer(pid)
			end
		end

		if number == nil then
			number = 0
		end

		irc_server_event(name, words[3], pid, number)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: search player {name}")
		irc_chat(name, "Search for a player by name.  It will list any players that match your search.")
		irc_chat(name, ".")
	end

	if words[1] == "search" and words[2] == "player" then
		irc_chat(name, "Players matching " .. words[3])

		cursor,errorString = conn:execute("SELECT id, steam, name FROM players where name like '%" .. words[3] .. "%'")
		row = cursor:fetch({}, "a")
		while row do
			irc_chat(name, row.id  .. " " .. row.steam .. " " .. row.name)
			row = cursor:fetch(row, "a")
		end

		irc_chat(name, ".")
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list duplicate players")
		irc_chat(name, "Get a list of all players with the same name. Useful for fixing issues.")
		irc_chat(name, ".")
	end

	if words[1] == "list" and words[2] == "duplicate" and words[3] == "players" then
		irc_chat(name, "Players with identical names and different steam keys:")

		cursor,errorString = conn:execute("SELECT GROUP_CONCAT(steam) as SteamKey, name, COUNT(*) c FROM players GROUP BY name HAVING c > 1")
		row = cursor:fetch({}, "a")
		while row do
			for k,v in next, string.split(row.SteamKey, ",") do
				irc_chat(name, v  .. " " .. row.name)
			end

			row = cursor:fetch(row, "a")
		end

		irc_chat(name, ".")
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: add proxy {text to match} action {ban or exile}")
		irc_chat(name, "Add a proxy for the bot to scan for and what action to take when it sees it.")
		irc_chat(name, ".")
	end

	if (words[1] == "add" and words[2] == "proxy") then
		if words[3] == nil then
			irc_chat(name, "I do a dns lookup on every player that joins. You can ban or exile players found using a known proxy.")
			irc_chat(name, "Staff and whitelisted players are ignored.")
			irc_chat(name, "Command example: add proxy YPSOLUTIONS action ban.  Action is optional and can be ban or exile.  Ban is the default.")
			irc_chat(name, "To remove a proxy type remove proxy YPSOLUTIONS.  To list proxies type list proxies.")
			irc_params = {}
			return
		end

		proxy = nil
		if string.find(msg, " action") then
			proxy = string.sub(msg, string.find(msg, "proxy") + 6, string.find(msg, "action") - 1)
		else
			proxy = string.sub(msg, string.find(msg, "proxy") + 6)
		end

		if proxy == nil then
			irc_chat(name, "The proxy is required.")
			irc_chat(name, "Command example: add proxy YPSOLUTIONS action ban.  Action is optional and can be ban or exile.  Ban is the default.")
			irc_params = {}
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
			irc_chat(name, "Invalid optional action given.")
			irc_chat(name, "Command example: add proxy YPSOLUTIONS action ban.  Action is optional and can be ban or exile.  Ban is the default.")
			irc_params = {}
			return
		end

		-- add the proxy to table proxies
		conn:execute("INSERT INTO proxies (scanString, action, hits) VALUES ('" .. escape(proxy) .. "','" .. escape(action) .. "',0)")

		if ircID == Smegz0r and botman.db2Connected then
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

		irc_chat(name, "Proxy " .. proxy  .. " has been added. New players using it will be " .. action)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: remove proxy {text}")
		irc_chat(name, "Remove a proxy.")
		irc_chat(name, ".")
	end

	if (words[1] == "remove" and words[2] == "proxy") then
		proxy = string.sub(msg, string.find(msg, "proxy") + 6)
		proxy = string.trim(string.upper(proxy))

		if proxy == nil then
			irc_chat(name, "The proxy is required.")
			irc_chat(name, "Command example: remove proxy YPSOLUTIONS.")
			irc_params = {}
			return
		end

		-- remve the proxy from the proxies table
		conn:execute("DELETE FROM proxies WHERE scanString = '" .. escape(proxy) .. "'")

		-- and remove it from the Lua table proxies
		proxies[proxy] = nil
		irc_chat(name, "You have removed the proxy " .. proxy)
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list proxies")
		irc_chat(name, "View all of the proxies that the bot checks for, how many hits each has had and what action the bot takes when it sees one.")
		irc_chat(name, ".")
	end

	if words[1] == "list" and words[2] == "proxies" then
		cursor,errorString = connBots:execute("SELECT * FROM proxies")
		if cursor:numrows() == 0 then
			irc_chat(name, "There are no proxies on record.")
		else
			irc_chat(name, "I am scanning for these proxies:")
			row = cursor:fetch({}, "a")
			while row do
				msg = "proxy: " .. row.scanString .. " action: " .. row.action .. " hits: " .. row.hits
				irc_chat(name, msg)
				row = cursor:fetch(row, "a")
			end
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list regions")
		irc_chat(name, "List all of the regions that contain a player base. Does not take into account parts of bases that cross into other regions.")
		irc_chat(name, ".")
	end

	if words[1] == "list" and words[2] == "regions" then
		conn:execute("DELETE FROM list WHERE steam = " .. ircID)

		irc_chat(name, "The following regions have player bases in them.")

		for k,v in pairs(players) do
			if math.abs(v.homeX) > 0 and math.abs(v.homeZ) > 0 then
				temp = getRegion(v.homeX, v.homeZ)
				conn:execute("INSERT INTO list (thing, steam) VALUES ('" .. temp .. "'," .. ircID .. ")")
			end

			if math.abs(v.home2X) > 0 and math.abs(v.home2Z) > 0 then
				temp = getRegion(v.home2X, v.home2Z)
				conn:execute("INSERT INTO list (thing, steam) VALUES ('" .. temp .. "'," .. ircID .. ")")
			end
		end

		cursor,errorString = conn:execute("SELECT * FROM list WHERE steam = " .. ircID .. " order by thing")
		row = cursor:fetch({}, "a")
		while row do
			irc_chat(name, row.thing)
			row = cursor:fetch(row, "a")
		end

		conn:execute("DELETE FROM list WHERE steam = " .. ircID)

		irc_chat(name, ".")
		irc_chat(name, "The following regions have locations in them.")

		for k,v in pairs(locations) do
			temp = getRegion(v.x, v.z)
				conn:execute("INSERT INTO list (thing, steam) VALUES ('" .. temp .. "'," .. ircID .. ")")
		end

		cursor,errorString = conn:execute("SELECT * FROM list WHERE steam = " .. ircID .. " order by thing")
		row = cursor:fetch({}, "a")
		while row do
			irc_chat(name, row.thing)
			row = cursor:fetch(row, "a")
		end

		conn:execute("DELETE FROM list WHERE steam = " .. ircID)

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list restricted items")
		irc_chat(name, "View the list of restricted items.  These are items that new players aren't allowed.")
		irc_chat(name, ".")
	end

	if (words[1] == "list" and words[2] == "restricted" and words[3] == "items") then
		irc_chat(name, "I scan for these restricted items in inventories:")

		for k, v in pairs(restrictedItems) do
			irc_chat(name, k .. " qty " .. v.qty .. " access level " .. v.accessLevel .. " action " .. v.action)
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: list entities")
		irc_chat(name, "List all of entities currently in the world.")
		irc_chat(name, ".")
	end

	if (words[1] == "list" and words[2] == "entities") then
		if botman.lastListEntities == nil then
			irc_chat(name, "Entities have not yet been scanned.  A scan has been actioned now. Repeat your command for the list.")
			sendCommand("le")
			irc_params = {}
			return
		end

		diff = os.difftime(os.time(), botman.lastListEntities)
		days = math.floor(diff / 86400)

		if (days > 0) then
			diff = diff - (days * 86400)
		end

		hours = math.floor(diff / 3600)

		if (hours > 0) then
			diff = diff - (hours * 3600)
		end

		minutes = math.floor(diff / 60)
		seconds = diff - (minutes * 60)

		if minutes > 1 then
			irc_chat(name, "It has been more than two minutes since the last entity scan.  A scan has been actioned now. Repeat your command for the list.")
			sendCommand("le")
			irc_params = {}
			return
		end

		if days==0 and hours==0 and minutes==0 and seconds==0 then
			irc_chat(name, "Entities need to be re-scanned.  A scan has been actioned now. Repeat your command for the list.")
			sendCommand("le")
			irc_params = {}
			return
		else
			irc_chat(name, "Entities last scanned " .. minutes .." minutes " .. seconds .. " seconds ago")
		end

		irc_chat(name, "The currently loaded entities are:")

		cursor,errorString = conn:execute("SELECT * FROM memEntities order by name")
		row = cursor:fetch({}, "a")
		while row do
			irc_chat(name, "id= " .. row.entityID .. ", " .. row.name .. ", xyz= " .. row.x .. " " .. row.y .. " " .. row.z .. ", health= " .. row.health)
			row = cursor:fetch(row, "a")
		end

		irc_chat(name, ".")
		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: near entity {entity ID}")
		irc_chat(name, "View a list of players, bases and locations near a specific entity.")
		irc_chat(name, ".")
	end

	if (words[1] == "near" and words[2] == "entity" and words[3] ~= nil) then
		pid = words[3]

		cursor,errorString = conn:execute("SELECT * FROM memEntities WHERE entityID = " .. pid)
		row = cursor:fetch({}, "a")

		if row then
			irc_chat(name, "Players, bases and locations near entity " .. row.entityID .. " " .. row.name .. " at " .. row.x .. " " .. row.y .. " " .. row.z)
			irc_chat(name, ".")

			irc_PlayersNearPlayer(name, "", 200, row.x, row.z, false, row.entityID .. " " .. row.name)
			irc_BasesNearPlayer(name, "", 200, row.x, row.z, row.entityID .. " " .. row.name)
			irc_LocationsNearPlayer(name, "", 200, row.x, row.z, row.entityID .. " " .. row.name)
		end

		irc_params = {}
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == nil) then
		irc_chat(irc_params.name, "You can view in-game command help by topic using list help {topic} or command help {topic} for any of the following topics:")
		irc_chat(name, ".")
		gmsg(server.commandPrefix .. "help sections", ircID)
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if displayIRCHelp then
		irc_chat(name, "Command: help {command}")
		irc_chat(name, "View help for an in-game command.  You will see help for any commands that match your search based on keywords.")
		irc_chat(name, ".")
	end

	if (words[1] == "help" and words[2] ~= nil) then
		if displayIRCHelp then
			irc_chat(name, "In-game IRC command help:")
			irc_chat(name, ".")
		end

		result = gmsg(server.commandPrefix .. "help " .. string.sub(msg, 6), ircID)

		if not result then
			irc_chat(name, "No help found for " .. words[2])
			irc_chat(name, "For help topics type help topics")
			irc_chat(name, "For general help type help")
			irc_chat(name, "You can also search for help by a keyword eg. help set")
			irc_chat(name, ".")
		end

		irc_params = {}
		return
	end

	if debug then dbug ("debug ircmessage end") end
end

