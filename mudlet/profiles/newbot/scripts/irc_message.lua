--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

local pid, login, name1, name2, words, wordsOld, words2, wordCount, word2Count, result, msgLower, counter, xpos, zpos, debug, tmp, k, v, a, b, filter, temp, action
local displayIRCHelp, number, numberCount, numbers = {}
local steam, steamOwner, userID, platform
local ircSteam, ircSteamOwner, ircUserID
local admin, adminLevel
local cursor, errorString, row


local debug = false -- should be false unless testing

if botman.debugAll then
	debug = true -- this should be true
end


local function dbugi(text)
	-- this is just a dummy function to prevent us trying to use dbugi() here.  If we call the real dbugi function here we get an infinite loop.
	dbug(text)
end


local function requireLogin(name, silent)
	local steam, userID, k, v

	steam, userID = LookupIRCAlias(name)

	-- see if we can find this irc nick in the bots database
	if steam ~= "0" then
		if players[steam].block then
			irc_chat(name, "You are not allowed to command me :P")
			return false
		end

		cursor,errorString = conn:execute("SELECT * FROM players where ircAlias = '" .. escape(name) .. "' and steam = '" .. steam .. "'")
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
				ircSteam = steam
				ircUserID = userID

				return false
			end
		end
	end
end


ircStatusMessage = function (name, message, code)
	display("irc status " .. name .. " " .. message .. " " .. code)
end


function IRCMessage(event, name, channel, msg)
-- commands have been split into 2 IRCMessage functions to bypass a 200 local variable limit imposed by Lua
if debug then dbug ("debug ircmessage start") end
	ircSteam = "0"
	displayIRCHelp = false

	tmp = {}

	local function cmd_UseTelnet()
		if displayIRCHelp then
			irc_chat(name, "Command: use telnet")
			irc_chat(name, "The bot will monitor the server using telnet and will not use Alloc's web API. Switching to this mode can fix some issues as there are several differences between the two modes with how the bot reads and processes the server traffic.")
			irc_chat(name, ".")
			return false
		end

		if (words[1] == "use" and words[2] == "telnet") then
			server.useAllocsWebAPI = false
			server.readLogUsingTelnet = true
			conn:execute("UPDATE server set useAllocsWebAPI = 0, readLogUsingTelnet = 1")
			irc_chat(name, "The bot is now using telnet to monitor the server and is not using Alloc's web API.")
			return true
		end
	end


	local function cmd_UseAPI()
		if displayIRCHelp then
			irc_chat(name, "Command: use api")
			irc_chat(name, "The bot will send commands to the server using Alloc's web API. Unless set elsewhere, the bot will still use telnet to listen to the server but with very few exceptions it will not send commands via telnet.")
			irc_chat(name, ".")
			return false
		end

		if (words[1] == "use" and words[2] == "api") then
			if tonumber(server.webPanelPort) == 0 then
				irc_chat(name, "You must first set the web panel port. This is normally port 8080 but yours may be different.  To set it type {#}set web panel port {the port number} or just restart the server.")
				irc_chat(name, "Or from here you can type set api port {the port number}")
				return true
			end

			-- the message must be sent first because we change the webtoken password next which would block the message.
			irc_chat(name, "The bot will use Alloc's web API.")
			server.useAllocsWebAPI = true
			botman.APIOffline = false
			toggleTriggers("api online")

			if server.readLogUsingTelnet and not botman.telnetOffline then
				connectToAPI()
			end

			return true
		end
	end


	local function cmd_JustReloadCode()
		if displayIRCHelp then
			irc_chat(name, "Command: just reload code")
			irc_chat(name, "Make the bot reload its code without doing any other maintenance tasks afterwards.")
			irc_chat(name, ".")
			return false
		end

		if (words[1] == "just" and words[2] == "reload" and words[3] == "code") then
			refreshScripts()
			reloadCustomScripts()
			irc_chat(name, "The bots scripts have reloaded.")
			irc_params = {}
			return true
		end
	end


	local function cmd_ReloadCode()
		if displayIRCHelp then
			irc_chat(name, "Command: reload code")
			irc_chat(name, "Make the bot reload its code.  It also performs some maintenance tasks on the bot's data.")
			irc_chat(name, ".")
			return false
		end

		if (words[1] == "reload" and words[2] == "code" and words[3] == nil) then
			reloadCode()
			irc_params = {}
			return true
		end
	end


	local function cmd_ReloadAdmins()
		if displayIRCHelp then
			irc_chat(name, "Command: reload admins")
			irc_chat(name, "Make the bot read admin list")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "reload" and string.find(msgLower, "admins") and words[3] == nil) then
			irc_chat(name, "Reading admin list from server.")
			sendCommand("admin list")
			irc_params = {}
			return true
		end
	end


	local function cmd_ReloadBot()
		if displayIRCHelp then
			irc_chat(name, "Command: reload bot")
			irc_chat(name, "Make the bot read gg, admin list, ban list, version and lkp -online.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "reload" and string.find(msgLower, "bot") and words[3] == nil) then
			irc_chat(name, "Reading gg, admins, bans, lkp, version from server.")
			reloadBot()
			irc_params = {}
			return true
		end
	end


	local function cmd_UpdateCode()
		if displayIRCHelp then
			irc_chat(name, "Command: update code")
			irc_chat(name, "Make the bot check for code updates and apply them.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "update" and (words[2] == "code" or words[2] == "scripts" or words[2] == "bot") and words[3] == nil) then
			updateBot(true)
			irc_params = {}
			return true
		end
	end


	local function cmd_MapUrl()
		if displayIRCHelp then
			irc_chat(name, "Command: map")
			irc_chat(name, "View the URL where the server map should be located.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "map") then
			irc_chat(name, "The server map should be here http://" .. server.IP .. ":" .. server.webPanelPort .. "/legacymap")
			irc_chat(name, ".")
			return true
		end
	end


	local function cmd_ServerInfo()
		if displayIRCHelp then
			irc_chat(name, "Command: server")
			irc_chat(name, "View basic info about the server and installed mods.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "server") then
			if words[2] == nil then
				irc_chat(name, "Server name is " .. server.serverName)
				irc_chat(name, "Address is " .. server.IP .. ":" .. server.ServerPort)
				irc_chat(name, "Game version is " .. server.gameVersion)

				if server.gameDate then
					irc_chat(name, "The game time is " .. server.gameDate)
				end

				irc_chat(name, "The server map should be here http://" .. server.IP .. ":" .. server.webPanelPort .. "/legacymap")

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

				if not server.botman then
					irc_chat(name, "Botman mod is not installed")
				end

				if modVersions then
					irc_chat(name, ".")
					irc_chat(name, "The server is running these mods:")

					tmp.version = sortTable(modVersions)

					for k, v in ipairs(tmp.version) do
						if not string.find(v, "Server Alpha") then
							irc_chat(name, v)
						end
					end

					irc_chat(name, ".")
				end

				cursor,errorString = conn:execute("SELECT distinct userID FROM events WHERE type = 'player joined' AND timestamp >= DATE_SUB(now(), INTERVAL 1 DAY) ORDER BY timestamp desc")

				irc_chat(name, cursor:numrows() .. " players have joined in the last 24 hours.")
				irc_chat(name, ".")

				IRCMessage(event, name, channel, "who")

				if botman.performance ~= nil then
					irc_chat(name, "Last recorded server FPS: " .. botman.performance.fps .. " Players: " .. botman.performance.players .. " Zombies: " .. botman.performance.zombies .. " Entities: " .. botman.performance.entities .. " Heap: " .. botman.performance.heap .. " HeapMax: " .. botman.performance.heapMax)
				end

				irc_uptime(name)

				IRCMessage(event, name, channel, "list event new player")
				IRCMessage(event, name, channel, "list event ban")
				IRCMessage(event, name, channel, "list event prison")
				IRCMessage(event, name, channel, "list event hack")

				irc_chat(name, ".")
				irc_params = {}
				return true
			end
		end
	end


	local function cmd_Version()
		if displayIRCHelp then
			irc_chat(name, "Command: version")
			irc_chat(name, "View the installed mods.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "version") then
			tmp = {}

			if words[2] == nil then
				irc_chat(name, "Game version is " .. server.gameVersion)

				if modVersions then
					irc_chat(name, ".")
					irc_chat(name, "The server is running with these mods:")

					tmp.version = sortTable(modVersions)

					for k, v in ipairs(tmp.version) do
						if not string.find(v, "Server Alpha") then
							irc_chat(name, v)
						end
					end

					irc_chat(name, ".")
				end

				irc_params = {}
				return true
			end
		end
	end


	local function cmd_BotInfo()
		if displayIRCHelp then
			irc_chat(name, "Command: bot info")
			irc_chat(name, "Display basic info about the bot.")
			irc_chat(name, ".")
			return
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

			if server.telnetDisabled then
				irc_chat(name, "The bot is not using telnet.")
			else
				if botman.telnetOffline then
					irc_chat(name, "Telnet is offline.")
				else
					irc_chat(name, "Telnet is online.")
				end
			end

			return true
		end
	end


	local function cmd_SearchBlacklist()
		if displayIRCHelp then
			irc_chat(name, "Command: search blacklist {IP}")
			irc_chat(name, "See if an IP is in the blacklist or not.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "search" and words[2] == "blacklist") then
			tmp = {}
			tmp.ip = string.sub(msg, string.find(msgLower, "blacklist") + 10)

			searchBlacklist(tmp.ip, name)
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopHelp()
		if displayIRCHelp then
			irc_chat(name, "Command: shop, or help shop")
			irc_chat(name, "View the IRC help for the shop management.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == nil) or (words[1] == "help" and words[2] == "shop") then
			irc_HelpShop()
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopEmptyCategory()
		if displayIRCHelp then
			irc_chat(name, "Command: empty category {category name}")
			irc_chat(name, "Delete everything from a category so you can start minty fresh.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "empty" and words[2] == "category" then
			if shopCategories[words[3]] then
				conn:execute("delete FROM shop WHERE category = '" .. escape(words[3]) .. "'")
				irc_chat(name, "The shop category called " .. words[3] .. " has been emptied.")
				irc_chat(name, ".")
				irc_params = {}
			else
				irc_chat(name, "No shop category called " .. words[3] .. " exists.")
				irc_chat(name, ".")
				irc_params = {}
			end

			return true
		end
	end


	local function cmd_ShopListAllItemsInShop()
		local itemCount = 0
		local cursor2, row2

		if displayIRCHelp then
			irc_chat(name, "Command: shop stock")
			irc_chat(name, "List everything in the shop.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "shop" and words[2] == "stock" then
			cursor,errorString = conn:execute("SELECT * FROM shopCategories ORDER BY category")
			row = cursor:fetch({}, "a")

			while row do
				irc_chat(name, "Category: " .. row.category)
				itemCount = 0

				cursor2,errorString = conn:execute("SELECT * FROM shop WHERE category = '" .. row.category .. "' ORDER BY idx")
				row2 = cursor2:fetch({}, "a")

				while row2 do
					itemCount = itemCount + 1

					if tonumber(row2.stock) == -1 then
						msg = "Code:  " .. row.code .. string.format("%02d", row2.idx) .. "    item:  " .. row2.item .. "    price:  " .. row2.price .. " UNLIMITED"
					else
						msg = "Code:  " .. row.code .. string.format("%02d", row2.idx) .. "    item:  " .. row2.item .. " price: " .. row2.price .. "  (" .. row2.stock .. ")  left"
					end

					irc_chat(name, msg)
					row2 = cursor2:fetch(row2, "a")
				end

				irc_chat(name, "Total " .. itemCount .. " items in category " .. row.category)
				irc_chat(name, ".")

				row = cursor:fetch(row, "a")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ShopListCategoryItems()
		local itemCount = 0

		if displayIRCHelp then
			irc_chat(name, "Command: shop {category name}")
			irc_chat(name, "List the items in the specified shop category.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "shop" and shopCategories[words[2]] then
			LookupShop(words[2])

			cursor,errorString = connMEM:execute("SELECT * FROM shop ORDER BY idx")
			row = cursor:fetch({}, "a")

			while row do
				itemCount = itemCount + 1

				if tonumber(row.stock) == -1 then
					msg = "Code:  " .. row.code .. "    item:  " .. row.item .. "    price:  " .. row.price .. " UNLIMITED"
				else
					msg = "Code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. "  (" .. row.stock .. ")  left"
				end

				irc_chat(name, msg)
				row = cursor:fetch(row, "a")
			end

			irc_chat(name, "Total " .. itemCount .. " items in category " .. words[2])
			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopListCategories()
		if displayIRCHelp then
			irc_chat(name, "Command: shop categories")
			irc_chat(name, "List the shop categories.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == "categories") then
			irc_chat(name, "The shop categories are:")

			for k, v in pairs(shopCategories) do
				irc_chat(name, k)
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopListItem()
		local itemCount = 0

		if displayIRCHelp then
			irc_chat(name, "Command: shop {item name}")
			irc_chat(name, "View an item in the shop.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] ~= nil and words[3] == nil) then
			LookupShop(wordsOld[2])

			cursor,errorString = connMEM:execute("SELECT * FROM shop ORDER BY category, idx")
			row = cursor:fetch({}, "a")

			while row do
				itemCount = itemCount + 1

				if tonumber(row.stock) == -1 then
					msg = "Code:  " .. row.code .. "  item:  " .. row.item .. "  price:  " .. row.price .. " UNLIMITED"
				else
					msg = "Code:  " .. row.code .. "  item:  " .. row.item .. "  price: " .. row.price .. "  (" .. row.stock .. ")  left"
				end

				irc_chat(name, msg)

				row = cursor:fetch(row, "a")
			end

			irc_chat(name, wordsOld[2] .. " matched " .. itemCount .. " items in shop")
			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ListVillages()
		if displayIRCHelp then
			irc_chat(name, "Command: villages")
			irc_chat(name, "List the villages and who the mayor is.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "villages" and words[2] == nil) then
			tmp = {}
			tmp.locations = sortTable(locations)

			irc_chat(name, "List of villages on the server:")

			for k, v in ipairs(tmp.locations) do
				if locations[v].village == true then
					if locations[v].mayor ~= "0" then
						steam = LookupOfflinePlayer(locations[v].mayor)
					end

					if steam ~= "0" then
						irc_chat(name, locations[v].name .. " the mayor is " .. players[steam].name)
					else
						irc_chat(name, locations[v].name .. " has no mayor")
					end
				end
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_FPS()
		if displayIRCHelp then
			irc_chat(name, "Command: fps")
			irc_chat(name, "View the last recorded mem output. (mem is updated every 40 seconds while players are online)")
			irc_chat(name, ".")
			return
		end

		if words[1] == "fps" and words[2] == nil then
			if botman.performance ~= nil then
				irc_chat(name, "Server FPS: " .. botman.performance.fps .. " Players: " .. botman.performance.players .. " Zombies: " .. botman.performance.zombies .. " Entities: " .. botman.performance.entities .. " Heap: " .. botman.performance.heap .. " HeapMax: " .. botman.performance.heapMax)
			else
				irc_chat(name, "The bot has just sent the mem command to the server.  Repeat this command to see the server fps.")
				sendCommand("mem")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_HelpCustomCommands()
		if displayIRCHelp then
			irc_chat(name, "Command: help custom commands")
			irc_chat(name, "View the help for custom commands.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "custom" and words[3] == "commands") then
			irc_HelpCustomCommands()
			irc_params = {}
			return true
		end
	end


	local function cmd_Date()
		if displayIRCHelp then
			irc_chat(name, "Command: date, or time, or day")
			irc_chat(name, "View the game day and time (not server time)")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "date" or words[1] == "time" or words[1] == "day") and words[2] == nil then
			irc_gameTime(name)
			irc_params = {}
			return true
		end
	end


	local function cmd_Uptime()
		if displayIRCHelp then
			irc_chat(name, "Command: uptime")
			irc_chat(name, "See how long the bot and server have been running.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "uptime") and words[2] == nil then
			irc_uptime(name)
			irc_params = {}
			return true
		end
	end


	local function cmd_ListLocationCategories()
		if displayIRCHelp then
			irc_chat(name, "Command: location categories")
			irc_chat(name, "List any defined location categories.")
			irc_chat(name, ".")
			return
		end

		if string.find(msgLower, "location categories") or string.find(msgLower, "list location categories") then
			if tablelength(locationCategories) == 0 then
				irc_chat(name, "There are no location categories.")
			else
				if ircSteam ~= "0" then
					if admin then
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
			return true
		end
	end


	local function cmd_ListLocation()
		if displayIRCHelp then
			irc_chat(name, "Command: location {name of location}")
			irc_chat(name, "View info about a specified location")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "location") then
			-- display details about the location

			locationName = words[2]
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if (loc == nil) then
				irc_chat(name, "That location does not exist.")
				irc_params = {}
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

				steam = "0"
				if row.mayor ~= "0" then
					steam = LookupPlayer(row.mayor)

					if steam ~= "0" then
						name1 = players[steam].name
					end
				end

				if steam ~= "0" then
					irc_chat(name, "Mayor: " .. name1)
				else
					irc_chat(name, "Mayor: Nobody is the mayor")
				end

				irc_chat(name, "Protected: " .. dbYN(row.protected))
				irc_chat(name, "PVP: " .. dbYN(row.pvp))
				irc_chat(name, "Access Level: " .. row.accessLevel)

				steam = "0"
				if row.owner ~= "0" then
					steam = LookupPlayer(row.owner)
					name1 = players[steam].name
				end

				irc_chat(name, "Owner: " .. name1)
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
			return true
		end
	end


	local function cmd_ServerStats()
		if displayIRCHelp then
			irc_chat(name, "Command: server stats")
			irc_chat(name, "View basic stats about the server from the last 24 hours.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "server" and (words[2] == "status" or words[2] == "stats") then
			irc_server_status(name)
			irc_params = {}
			return true
		end
	end


	local function cmd_WhoPlayedToday()
		if displayIRCHelp then
			irc_chat(name, "Command: who played today")
			irc_chat(name, "List who played on the server in the last 24 hours in order of appearance.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "who" and words[2] == "played" and words[3] == "today" then
			irc_who_played(name)
			irc_params = {}
			return true
		end
	end


	local function cmd_ListHelpCommand()
		if displayIRCHelp then
			irc_chat(name, "Command: list help command {keyword}")
			irc_chat(name, "Or list help command {keyword} full and/or notes")
			irc_chat(name, "List all matching help commands from the bot's help commands table for use in changing the minimum access level required to use the command.")
			irc_chat(name, "Optionally include the full command help and/or notes and examples for each matched command.")
			irc_chat(name, ".")
			return
		end

		if string.find(msgLower, "list help command") or string.find(msgLower, "command list help") or string.find(msgLower, "help command list") then
			if not words[4] then
				irc_chat(name, "A keyword is required to narrow down the list eg. base")
				irc_params = {}
				return true
			else
				if words[5] then
					if words[5] == "full" then
						irc_params.fullHelp = true
					end

					if words[5] == "notes" or words[5] == "eg" or words[5] == "examples" then
						irc_params.showNotes = true
					end
				end

				if words[6] then
					if words[6] == "full" then
						irc_params.fullHelp = true
					end

					if words[6] == "notes" or words[6] == "eg" or words[6] == "examples" then
						irc_params.showNotes = true
					end
				end

				irc_params.keyword = words[4]
			end

			irc_ListHelpCommand()
			irc_params = {}
			return true
		end
	end


	local function cmd_SetHelpCommand() -- make restricted to admin level 0
		if displayIRCHelp then
			irc_chat(name, "Command: set help command {keyword} number {number from list} access {new minimum access level. valid range (0-99) }")
			irc_chat(name, "Set the minimum access level of a help command after using the command list help command {keyword}.")
			irc_chat(name, "The list command gives you a numbered list. Using that number and THE SAME keyword you can change the access level of a previously listed command.")
			irc_chat(name, "If you don't use the exact same keyword as before, you risk changing the access level of some other command which will have unintended consequences.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "set" and words[2] == "help" and words[3] == "command" then
			if not words[4] then
				irc_chat(name, "A keyword is required to narrow down the list eg. base")
				irc_params = {}
				return true
			else
				irc_params.keyword = words[4]
			end

			if not words[6] then
				irc_chat(name, "A number is required from the 'list command help' output. Make sure you specify the correct number.")
				irc_params = {}
				return true
			else
				irc_params.index = tonumber(words[6])
			end

			if not words[8] then
				irc_chat(name, "A number is required for the access level for the chosen command.")
				irc_params = {}
				return true
			else
				irc_params.accessLevel = math.abs(words[8])

				if irc_params.accessLevel > 99 then
					irc_chat(name, irc_params.accessLevel .. " is greater than 99. The valid range is 0 to 99.")
					irc_params = {}
					return true
				end
			end

			irc_SetHelpCommand()
			irc_params = {}
			return true
		end
	end


	local function cmd_ListHelpTopics()
		if displayIRCHelp then
			irc_chat(name, "Command: help topics")
			irc_chat(name, "View IRC command help topics.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "topics") then
			irc_HelpTopics()
			irc_params = {}
			return true
		end
	end


	local function cmd_ListLocations()
		if displayIRCHelp then
			irc_chat(name, "Command: locations")
			irc_chat(name, "List the locations.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "locations" and words[2] == nil) then
			tmp = {}
			tmp.locations = sortTable(locations)

			irc_chat(name, "List of locations:")

			for k, v in ipairs(tmp.locations) do
				if (locations[v].public == true) then
					public = "public"
				else
					public = "private"
				end

				if (locations[v].active == true) then
					active = "enabled"
				else
					active = "disabled"
				end

				if ircSteam ~= "0" then
					if admin then
						if locations[v].locationCategory ~= "" then
							irc_chat(name, locations[v].name .. " " .. public .. " " .. active .. " xyz " .. locations[v].x .. " " .. locations[v].y .. " " .. locations[v].z .. " category " .. locations[v].locationCategory)
						else
							irc_chat(name, locations[v].name .. " " .. public .. " " .. active .. " xyz " .. locations[v].x .. " " .. locations[v].y .. " " .. locations[v].z)
						end
					else
						if public == "public" then
							irc_chat(name, locations[v].name)
						end
					end
				else
					if public == "public" then
						irc_chat(name, locations[v].name)
					end
				end
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ListLocationSpawns()
		local counter = 1

		if displayIRCHelp then
			irc_chat(name, "Command: list location {name} spawns")
			irc_chat(name, "A numbered list of random spawn points for a location.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "list" and words[2] == "location") and (string.find(msgLower, " spawns")) and words[4] ~= nil then
			tmp = {}
			tmp.location = string.sub(msg, string.find(msgLower, " location ") + 10, string.find(msgLower, " spawns") - 1)
			tmp.loc = LookupLocation(tmp.location)

			if (not tmp.loc) then
				irc_chat(name, "The location, " .. tmp.location .. " does not exist or has a different name.")

				irc_chat(name, ".")
				irc_params = {}
				return true
			end

			cursor,errorString = connSQL:execute("select count(*) from locationSpawns where location='" .. connMEM:escape(tmp.location) .. "'")
			row = cursor:fetch({}, "a")
			rowCount = row["count(*)"]

			if rowCount == 0 then
				irc_chat(name, "The location, " .. tmp.location .. " has only 1 spawn point at " .. locations[tmp.location].x .. " " .. locations[tmp.location].y .. " " .. locations[tmp.location].z)

				irc_chat(name, ".")
				irc_params = {}
				return true
			end

			irc_chat(name, "List of spawn points for location: " .. tmp.location)

			cursor,errorString = connSQL:execute("select * from locationSpawns where location='" .. connMEM:escape(tmp.location) .. "'")
			row = cursor:fetch({}, "a")

			while row do
				irc_chat(name, "#" .. counter .. " " .. server.commandPrefix .. "tp " .. row.x .. " " .. row.y .. " " .. row.z)

				counter = counter + 1
				row = cursor:fetch(row, "a")
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ListStaff()
		if displayIRCHelp then
			irc_chat(name, "Command: staff")
			irc_chat(name, "List all of the admins.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "staff" and words[2] == nil) then
			listStaff(name)
			irc_params = {}
			return true
		end
	end


	local function cmd_ViewIRCCommandHelp()
		if displayIRCHelp then
			irc_chat(name, "Command: help")
			irc_chat(name, "View the bot's IRC help.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == nil) then
			irc_commands()

			irc_chat(name, ".")
			displayIRCHelp = true
			return true
		end
	end


	local function cmd_AllIRCCommandHelp()
		if displayIRCHelp then
			irc_chat(name, "Command: help irc")
			irc_chat(name, "Command: lounge commands")
			irc_chat(name, "View all IRC (lounge) bot command help.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "irc") or (words[1] == "lounge" and words[2] == "commands") then
			irc_chat(name, "IRC bot commands:")
			irc_chat(name, ".")
			displayIRCHelp = true
			return true
		end
	end


	local function cmd_RestoreAdmin()
		if displayIRCHelp then
			irc_chat(name, "Command: restore admin")
			irc_chat(name, "Restore your admin status early if you used {#}test as player and the timer hasn't expired yet.")
			irc_chat(name, ".")
			return
		end

		-- try to find the irc person in the players table
		-- commands below here won't work if the bot doesn't match you against a player record
		if ircSteam == "0" then
			ircSteam = LookupIRCAlias(name)
		end

		if ircSteam ~= "0" then
			if string.find(msgLower, "restore admin") then
				gmsg(server.commandPrefix .. "restore admin", ircSteam)
				irc_params = {}
				return true
			end

			if players[ircSteam].ircMute then
				irc_params = {}
				return true
			end

			if players[ircSteam].ircAuthenticated == false then
				requireLogin(name, true)
			else
				-- keep login session alive
				players[ircSteam].ircSessionExpiry = os.time() + 86400 -- 1 day
				conn:execute("UPDATE players SET ircAuthenticated = 1 WHERE steam = '" .. ircSteam .. "'")
			end

			if debug then dbug("IRC: " .. name .. " access " .. players[ircSteam].accessLevel .. " said " .. msg) end
		end
	end


	local function cmd_Logout()
		if displayIRCHelp then
			irc_chat(name, "Command: logout")
			irc_chat(name, "Log out of the bot on IRC (does not disconnect you from the IRC server).")
			irc_chat(name, ".")
			return
		end

		if words[1] == "logout" or (words[1] == "log" and words[2] == "out") then
			if ircSteam ~= "0" then
				players[ircSteam].ircAuthenticated = false
				players[ircSteam].ircSessionExpiry = os.time()
				conn:execute("UPDATE players SET ircAuthenticated = 0 WHERE steam = '" .. ircSteam .. "'")
				irc_chat(name, "You have logged out.  To log back in type your bot login or type bow before me.")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_Hi()
		if displayIRCHelp then
			irc_chat(name, "Command: hi bot")
			irc_chat(name, "Get the bot to respond to you.  It will create a private chat channel as well as respond to you in the current channel.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "hi" or words[1] == "hello") and (string.lower(words[2]) == string.lower(server.botName) or string.lower(words[2]) == string.lower(server.ircBotName) or words[2] == "bot" or words[2] == "server") then
			irc_chat(name, "Hi there " .. name .. "!  How can I help you today?")

			if ircSteam == "0" then
				ircSteam = LookupIRCAlias(name)
			else
				if not players[ircSteam].ircAuthenticated then
					requireLogin(name, true)
				end
			end

			if ircSteam ~= "0" then
				if players[ircSteam].ircAuthenticated then
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
			return true
		end
	end


	local function cmd_Who()
		if displayIRCHelp then
			irc_chat(name, "Command: who")
			irc_chat(name, "List everyone playing on the server right now.  The info varies depending on if you are staff or player, logged in to the bot or not.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "who" and words[2] == nil) then
			irc_players(name)
			irc_params = {}
			return true
		end
	end


	local function cmd_Login()
		if displayIRCHelp then
			irc_chat(name, "Command: login {name} pass {password}")
			irc_chat(name, "Log in to the bot.  Do NOT do this in any public channels (they start with a #).  Do this only in the bot's private chat channel.  If the bot sees this in a public channel it will destroy your login.  If that happens, use the invite command to invite yourself to IRC.  Follow the in-game prompts and you will get authenticated again.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "login") then
			tmp = {}

			if words[2] ~= nil then
				if not string.find(msgLower, " pass ") then
					irc_chat(name, "Logins have changed.  The new format is login {name} pass {password}")
					irc_chat(name, "Your login will need to be updated to the new format.  You can do this yourself by typing invite {your ingame name} then join the server and type /read mail and follow the instructions there.")
					irc_chat(name, ".")
					irc_params = {}
					return true
				else
					tmp.login = string.sub(msg, string.find(msgLower, "login") + 6, string.find(msgLower, " pass ") - 1)
					tmp.pass = string.sub(msg, string.find(msgLower, " pass ") + 6)
				end

				ircSteam = LookupIRCPass(tmp.login, tmp.pass)

				if not ircSteam then
					ircSteam = "0"
				end

				if ircSteam ~= "0" then
					if string.find(channel, "#") then
						irc_chat(name, "You accidentally revealed your password in a public channel.  You password has been automatically wiped and you won't be able to login until Smeg sets a new password for you.")
						players[ircSteam].ircAuthenticated = false
						players[ircSteam].ircPass = nil

						conn:execute("UPDATE players SET ircPass = '' WHERE steam = '" .. ircSteam .. "'")
						irc_params = {}
						return true
					end

					players[ircSteam].ircAuthenticated = true
					players[ircSteam].ircAlias = name

					-- fix a weird bug where the wrong player can have the irc alias for this player and they can't get it back
					conn:execute("UPDATE players SET ircAlias = '' WHERE ircAlias = '" .. escape(name) .. "'")
					conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = '" .. ircSteam .. "'")

					players[ircSteam].ircSessionExpiry = os.time() + 86400 -- 1 day

					irc_chat(name, "You have logged in " .. name)
					irc_chat(name, ".")
					irc_params = {}
					return true
				else
					irc_chat(name, "Name or password not recognised. :{")
					irc_chat(name, "Note: You must have joined the server at least once to be recognised.  Also a password must have been set for you.")
					irc_chat(name, "You can get yourself recognised and give yourself a password by typing invite {your ingame name}. Join the server and /read mail then follow the bot's instructions.")
					irc_chat(name, ".")
					irc_params = {}
					return true
				end

				if (players[ircSteam].ircPass == nil) then
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

			return true
		end
	end


	local function cmd_RescueMe()
		if displayIRCHelp then
			irc_chat(name, "Command: rescue me")
			irc_chat(name, "This command fixes a weird and long standing bug where the bot can get mixed up between you on IRC and a random player.  It doesn't give them admin commands but it does cause you to not be able to use them on IRC and the say command uses the other player name instead of yours.  One day I shall find this bug!")
			irc_chat(name, ".")
			return
		end

		-- come on baby
		if words[1] == "rescue" and words[2] == "me" then
			for k,v in pairs(players) do
				if v.ircAlias == name then
					v.ircAlias = ""
					irc_chat(name, "Your nick has been released from a player record. Now login to claim it.")
					conn:execute("UPDATE players SET ircAlias = '' WHERE steam = '" .. k .. "'")
				end
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_Bow()
		if displayIRCHelp then
			irc_chat(name, "Command: bow")
			irc_chat(name, "Login to the bot without a password.  Only works if you have previously been authenticated.")
			irc_chat(name, ".")
			return
		end

		-- kneel before your god >:)
		if words[1] == "bow" and words[2] == nil then
			irc_chat(name, "Thank you!  Thank you!  You're beautiful!  I love ya :D")
			irc_chat(name, "OH!  Ooooooh!  You wanted to log in?")
			irc_chat(name, ".")
			irc_chat(name, "Papers please.")
			irc_chat(name, ".")

			if admin then
				players[ircSteam].ircSessionExpiry = os.time() + 86400 -- 1 day
				players[ircSteam].ircAuthenticated = true
				players[ircSteam].ircAlias = name
				irc_chat(name, "You have logged in " .. name)
				irc_chat(name)

				conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = '" .. ircSteam .. "'")
			else
				irc_chat(name, "Did you drop your contact lense?")
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_IAm() -- Legend
		-- :O  Zombies!
		if words[1] == "i" and words[2] == "am" and words[3] ~= nil then
			ircSteam = LookupPlayer(words[3], "code")

			if not ircSteam then
				ircSteam = "0"
			end

			if ircSteam ~= "0" then
				players[ircSteam].ircSessionExpiry = os.time() + 86400 -- 1 day
				players[ircSteam].ircAuthenticated = true
				players[ircSteam].ircAlias = name
				players[ircSteam].ircInvite = nil
				irc_chat(name, "Welcome to our IRC server " .. name .. "!")
				irc_chat(name, "Your current IRC nickname is now recorded in your player record.  To prevent others from impersonating you on IRC, you need to give me a password.")
				irc_chat(name, "Please just use numbers and letters and no symbols.  To set or change your password type new login {name} pass {password}.  eg. new login joe pass catsrul3")
				irc_chat(name, ".")
				irc_chat(name, "To use your password, never type it in " .. server.ircMain .. " or anywhere other than here in this private chat between us or others may see your password.")
				irc_chat(name, "If you accidentally login in " .. server.ircMain .. " I will wipe your password and you will need to set a new one.  If that happens type invite followed by your in-game name and I will send you a new IRC invite code.")

				if admin then
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
				conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = ' " .. ircSteam .. "'")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_HelpManual()
		-- Manuel: Que?
		if displayIRCHelp then
			irc_chat(name, "Command: help manual")
			irc_chat(name, "Read the help manual.  Its about a page and a half.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "help" and (words[2] == "guide" or words[2] == "manual") then
			irc_Manual()
			irc_params = {}
			return true
		end
	end


	local function cmd_HelpSetup()
		if displayIRCHelp then
			irc_chat(name, "Command: help setup")
			irc_chat(name, "View the help topic on setting up the bot.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "help" and words[2] == "setup" then
			irc_Setup()
			irc_params = {}
			return true
		end
	end


	local function cmd_SetServerIP()
		if displayIRCHelp then
			irc_chat(name, "Command: set server ip {IP}")
			irc_chat(name, "Tell the bot the IP of the server that it is connected to.  Due to a limitation in Mudlet it can't easily determine this for itself from the Mudlet profile.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "set" and words[2] == "server" and words[3] == "ip" and not (string.find(msgLower, "pass")) then
			if not players[ircSteam].ircAuthenticated then
				if requireLogin(name) then
					irc_params = {}
					return true
				end
			end

			if (string.trim(words[4]) ~= "") then
				server.IP = string.sub(msg, string.find(msg, words[4]), string.len(msg))
				irc_chat(name, "The server address is now " .. server.IP .. ":" .. server.ServerPort)
				irc_chat(name, ".")
				conn:execute("UPDATE server SET IP = '" .. escape(server.IP) .. "'")

				if botman.botsConnected then
					connBots:execute("UPDATE servers SET IP = '" .. escape(server.IP) .. "' WHERE botID = " .. server.botID)
				end

				irc_params = {}
				return true
			end
		end
	end


	local function cmd_SetNewLogin()
		if displayIRCHelp then
			irc_chat(name, "Command: new login {name} pass {password}")
			irc_chat(name, "Change your bot login.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "new" and string.find(msgLower, "pass") and words[3] ~= nil then
			if players[ircSteam].ircAuthenticated == false then
				if requireLogin(name) then
					irc_params = {}
					return true
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
				return true
			end

			if string.find(msgLower, "catsrul3") then
				irc_chat(name, "Yes they do but don't tell them that, also pick a different password. :P")
				irc_params = {}
				return true
			end

			if countAlphaNumeric(words[3]) ~= string.len(words[3]) then
				irc_chat(name, "Your password can only contain letters and/or numbers.")
			else
				players[ircSteam].ircLogin = tmp.login
				players[ircSteam].ircPass = tmp.pass
				conn:execute("UPDATE players SET ircLogin = '" .. escape(tmp.login) .. "', ircPass = '" .. escape(tmp.pass) .. "' WHERE steam = '" .. ircSteam .. "'")
				irc_chat(name, "You have set your new login. Test it now by typing login " .. tmp.login .. " pass " .. tmp.pass)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_Say()
		if displayIRCHelp then
			irc_chat(name, "Command: say {something man}")
			irc_chat(name, "Say something publicly in-game to the players as yourself.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "say") then
			if players[ircSteam].ircAuthenticated == false then
				if requireLogin(name) then
					irc_params = {}
					return true
				end
			end

			if not players[ircSteam].ircMute then
				msg = string.trim(string.sub(msg, 5))
				if ircSteam == "76561197983251951" then
					message("say [FFD700]Bot Master[-] " .. players[ircSteam].name .. "-irc: [i]" .. msg .. "[/i][-]")
				else
					if server.sayUsesIRCNick then
						message("say " .. name .. "-irc: [i]" .. msg .. "[/i][-]")
					else
						message("say " .. players[ircSteam].name .. "-irc: [i]" .. msg .. "[/i][-]")
					end
				end
			else
				irc_chat(name, "Sorry you have been muted")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_SayTranslated()
		if displayIRCHelp then
			irc_chat(name, "Command: sayfr {something to be translated}")
			irc_chat(name, "Depreciated feature.  It should work but requires a translation utility installed in Linux.  I don't use it anymore as I host too many bots and don't want a big surprise bill from Google.")
			irc_chat(name, ".")
			return
		end

		if (string.find(words[1], "say") and (string.len(words[1]) == 5) and words[2] ~= nil) then
			if players[ircSteam].ircAuthenticated == false then
				if requireLogin(name) then
					irc_params = {}
					return true
				end
			end

			msg = string.sub(msg, string.len(words[1]) + 2)
			msg = string.trim(msg)

			if (msg ~= "") then
				Translate(ircSteam, msg, string.sub(words[1], 4), true)
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ListAllIngameCommandHelp()
		if displayIRCHelp then
			irc_chat(name, "Command: command help")
			irc_chat(name, "View the ingame command help in full including descriptions.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "command" and words[2] == "help") and admin then
			if words[3] == nil then
				-- here are all of the in-game commands and their help.  See you tomorrow :D
				gmsg(server.commandPrefix .. "command help", ircSteam)
			else
				gmsg(server.commandPrefix .. "command help " .. words[3], ircSteam)
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ListHelp()
		if displayIRCHelp then
			irc_chat(name, "Command: list help")
			irc_chat(name, "View the ingame command help minus the description texts.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "list" and words[2] == "help") and admin then
			if words[3] == nil then
				gmsg(server.commandPrefix .. "list help", ircSteam)
			else
				gmsg(server.commandPrefix .. "list help " .. words[3], ircSteam)
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_HelpTopicServer()
		if displayIRCHelp then
			irc_chat(name, "Command: help server")
			irc_chat(name, "View the server help topic")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "server") and admin then
			irc_HelpServer()
			irc_params = {}
			return true
		end
	end


	local function cmd_HelpTopicDonors()
		if displayIRCHelp then
			irc_chat(name, "Command: help donors")
			irc_chat(name, "View the donor help topic")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "donors") and admin then
			irc_HelpDonors()
			irc_params = {}
			return true
		end
	end


	local function cmd_HelpTopicCSI()
		if displayIRCHelp then
			irc_chat(name, "Command: help csi")
			irc_chat(name, "View the CSI help topic")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "csi") and admin then
			-- ENHANCE!
			irc_HelpCSI()
			irc_params = {}
			return true
		end
	end


	local function cmd_HelpTopicWatchlist()
		if displayIRCHelp then
			irc_chat(name, "Command: help watchlist")
			irc_chat(name, "View the watchlist help topic")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "watchlist") and admin then
			irc_HelpWatchlist()
			irc_params = {}
			return true
		end
	end


	local function cmd_HelpTopicBadItems()
		if displayIRCHelp then
			irc_chat(name, "Command: help bad items")
			irc_chat(name, "View the bad items help topic")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "bad" and words[3] == "items") and admin then
			irc_HelpBadItems()
			irc_params = {}
			return true
		end
	end


	local function cmd_HelpTopicAnnouncements()
		if displayIRCHelp then
			irc_chat(name, "Command: help announcements")
			irc_chat(name, "View the rolling announcements help topic")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "announcements") and admin then
			irc_HelpAnnouncements()
			irc_params = {}
			return true
		end
	end


	local function cmd_HelpTopicCommands()
		if displayIRCHelp then
			irc_chat(name, "Command: help commands")
			irc_chat(name, "View the remote commands help topic")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "commands") and admin then
			irc_HelpCommands()
			irc_params = {}
			return true
		end
	end


	local function cmd_HelpTopicMOTD()
		if displayIRCHelp then
			irc_chat(name, "Command: help motd")
			irc_chat(name, "View the message of the day help topic")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "motd") and admin then
			irc_HelpMOTD()
			irc_params = {}
			return true
		end
	end


	local function cmd_HelpTopicAccessLevels()
		if displayIRCHelp then
			irc_chat(name, "Command: help access")
			irc_chat(name, "View the access levels help topic")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] == "access") then
			irc_HelpAccess()
			irc_params = {}
			return true
		end
	end


	local function cmd_HelpTopicResetZones()
		if displayIRCHelp then
			irc_chat(name, "Command: reset zones")
			irc_chat(name, "List the reset zones.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "reset" and words[2] == "zones" and words[3] == nil) and admin then
			irc_listResetZones(name)
			irc_params = {}
			return true
		end
	end


	local function cmd_Stop()
		if displayIRCHelp then
			irc_chat(name, "Command: stop")
			irc_chat(name, "Stop the bot's current command output so you can issue a new command without waiting for the last one to finish.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "nuke" or words[1] == "clear" and words[2] == "irc") or ((words[1] == "stop" or words[1] == "sotp" or words[1] == "stahp") and words[2] == nil) then
			connMEM:execute("DELETE FROM ircQueue WHERE name = '" .. name .. "'")
			irc_chat(channel, "IRC spam nuked for " .. name)

			if ircListItems == ircSteam then ircListItems = nil end

			if echoConsoleTo == name then
				echoConsole = false
				echoConsoleTo = nil
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_NukeIRC()
		if displayIRCHelp then
			irc_chat(name, "Command: stop all")
			irc_chat(name, "Stop the bot's IRC command output for everyone.")
			irc_chat(name, ".")
			return
		end

		-- It's the only way to be sure
		if (words[1] == "nuke" or words[1] == "clear" or words[1] == "stop") and words[2] == "all" then
			connMEM:execute("DELETE FROM ircQueue")
			irc_chat(channel, "IRC spam nuked for everyone.")

			ircListItems = nil
			echoConsole = false
			echoConsoleTo = nil
			irc_params = {}
			return true
		end
	end


	local function cmd_Rules()
		if displayIRCHelp then
			irc_chat(name, "Command: rules {new rules}")
			irc_chat(name, "View the server rules.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "rules") then
			if words[2] == nil then
				irc_chat(name, "The server rules are " .. server.rules)
				irc_chat(name, ".")
				irc_params = {}
			else
				if admin then
					irc_chat(name, "To change the rules type set rules {new rules}")
					irc_chat(name, ".")
				end

				irc_params = {}
			end

			return true
		end
	end


	local function cmd_IRCInvite()
		if displayIRCHelp then
			irc_chat(name, "Command: invite {player name}")
			irc_chat(name, "Send and IRC invite to a player.  The bot will give them a series of simple instructions that they must follow in order to join the IRC server and be recognised by the bot.  Also useful if you get your own bot login disabled, just invite yourself, join the server and {#}read mail or follow the prompts if you are already ingame.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "invite" and words[2] ~= nil) and (not server.ircPrivate or admin) then
			name1 = string.trim(string.sub(msgLower, string.find(msgLower, "invite") + 7))
			steam = LookupPlayer(name1)

			if steam ~= "0" then
				number = rand(10000)
				result = LookupPlayer(number, "code")

				while result ~= "0" do
					number = rand(10000)
					result = LookupPlayer(number, "code")
				end

				players[steam].ircInvite = number

				if igplayers[steam] then
					message("pm " .. userID .. " HEY " .. players[steam].name .. "! You have an invite code for IRC! Reply with " .. server.commandPrefix .. "accept " .. number .. " or ignore it.")
				end

				connSQL:execute("INSERT INTO mail (sender, recipient, message) VALUES ('0','" .. steam .. "', '" .. connMEM:escape("You have an invite code for IRC! Reply with " .. server.commandPrefix .. "accept " .. number .. " or ignore it.") .. "')")
				irc_chat(name, "An IRC invite code has been sent to " .. players[steam].name)
				irc_chat(name, ".")
				irc_params = {}
				return true
			end
		end
	end

	-- ===== END OF COMMAND FUNCTIONS ======

	result = false

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

	if debug then dbug(event .. " " .. name .. " " .. channel .. " " .. msg) end

	-- block Mudlet from messaging the official Mudlet support channel
	if (channel == "#mudlet") then
		return true, ""
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	irc_params = {}

	if server.ircMain == "#new" and string.find(channel, "#", nil, true) and not string.find(channel, "_", nil, true) then
		if (not string.find(channel, "_", nil, true)) and string.find(channel, "#", nil, true) then
			server.ircMain = channel
			server.ircAlerts = channel .. "_alerts"
			server.ircWatch = channel .. "_watch"
			conn:execute("UPDATE server SET ircMain = '" .. escape(server.ircMain) .. "', ircAlerts = '" .. escape(server.ircAlerts) .. "', ircWatch = '" .. escape(server.ircWatch) .. "'")
		end
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	-- block Mudlet from reacting to its own messages
	if (name == server.botName or name == server.ircBotName or string.find(msg, "<" .. server.ircBotName .. ">", nil, true)) then
		irc_params = {}
		return true, ""
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	words = {}
	wordsOld = {}
	numbers = {}
	for word in msg:gmatch("%S+") do table.insert(wordsOld, word) end

	words2 = string.split(msg, " ")
	word2Count = tablelength(words2)
	msgLower = string.lower(msg)

	irc_params.name = name
	for word in msgLower:gmatch("-?\%w+") do table.insert(words, word) end

	wordCount = tablelength(words)

	for word in string.gmatch (msg, " (-?\%d+)") do
		table.insert(numbers, word)
	end

	number = tonumber(string.match(msg, " (-?\%d+)"))

	-- break the line into numbers
	for word in string.gmatch (msg, " (-?\%d+)") do
		table.insert(numbers, tonumber(word))
	end

	numberCount = tablelength(numbers)
	ircSteam = LookupIRCAlias(name)

	if ircSteam == "0" then
		ircSteam, ircSteamOwner, ircUserID = LookupPlayer(name, "all")
	else
		ircSteam, ircSteamOwner, ircUserID = LookupPlayer(ircSteam, "all")
	end

	admin, adminLevel = isAdminHidden(ircSteam, ircUserID)
	adminLevel = tonumber(adminLevel)

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if customIRC ~= nil then
		if customIRC(name, words, wordsOld, msgLower, ircSteam) then
			irc_params = {}
			if debug then dbug("debug ran IRC command customIRC") end
			return true, "IRC customIRC"
		end
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if players[ircSteam] then
		if players[ircSteam].denyRights then
			-- if someone on IRC has been blocked from using the bot on IRC this is as far as they get >:)
			irc_params = {}
			irc_chat(name, "I am not allowed to talk to you :O")
			return true, ""
		end
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == string.lower(server.botName) or words[1] == string.lower(server.ircBotName)) and words[2] == nil then
		irc_chat(name, "Hi " .. name)
		irc_params = {}
		return true, "IRC Hi"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	cmd_ViewIRCCommandHelp()

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	cmd_AllIRCCommandHelp()

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_UseTelnet() then
		if debug then dbug("debug ran IRC command cmd_UseTelnet") end
		return true, "IRC cmd_UseTelnet"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_UseAPI() then
		if debug then dbug("debug ran IRC command cmd_UseAPI") end
		return true, "IRC cmd_UseAPI"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ReloadCode() then
		if debug then dbug("debug ran IRC command cmd_ReloadCode") end
		return true, "IRC cmd_ReloadCode"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_JustReloadCode() then
		if debug then dbug("debug ran IRC command cmd_JustReloadCode") end
		return true, "IRC cmd_JustReloadCode"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ReloadAdmins() then
		if debug then dbug("debug ran IRC command cmd_ReloadAdmins") end
		return true, "IRC cmd_ReloadAdmins"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ReloadBot() then
		if debug then dbug("debug ran IRC command cmd_ReloadBot") end
		return true, "IRC cmd_ReloadBot"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_UpdateCode() then
		if debug then dbug("debug ran IRC command cmd_UpdateCode") end
		return true, "IRC cmd_UpdateCode"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_MapUrl() then
		if debug then dbug("debug ran IRC command cmd_MapUrl") end
		return true, "IRC cmd_MapUrl"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ServerInfo() then
		if debug then dbug("debug ran IRC command cmd_ServerInfo") end
		return true, "IRC cmd_ServerInfo"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_Version() then
		if debug then dbug("debug ran IRC command cmd_Version") end
		return true, "IRC cmd_Version"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_BotInfo() then
		if debug then dbug("debug ran IRC command cmd_BotInfo") end
		return true, "IRC cmd_BotInfo"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_SearchBlacklist() then
		if debug then dbug("debug ran IRC command cmd_SearchBlacklist") end
		return true, "IRC cmd_SearchBlacklist"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopHelp() then
		if debug then dbug("debug ran IRC command cmd_ShopHelp") end
		return true, "IRC cmd_ShopHelp"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopEmptyCategory() then
		if debug then dbug("debug ran IRC command cmd_ShopEmptyCategory") end
		return true, "IRC cmd_ShopEmptyCategory"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopListCategoryItems() then
		if debug then dbug("debug ran IRC command cmd_ShopListCategoryItems") end
		return true, "IRC cmd_ShopListCategoryItems"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopListCategories() then
		if debug then dbug("debug ran IRC command cmd_ShopListCategories") end
		return true, "IRC cmd_ShopListCategories"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopListAllItemsInShop() then
		if debug then dbug("debug ran IRC command cmd_ShopListAllItemsInShop") end
		return true, "IRC cmd_ShopListAllItemsInShop"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopListItem() then
		if debug then dbug("debug ran IRC command cmd_ShopListItem") end
		return true, "IRC cmd_ShopListItem"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ListVillages() then
		if debug then dbug("debug ran IRC command cmd_ListVillages") end
		return true, "IRC cmd_ListVillages"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_FPS() then
		if debug then dbug("debug ran IRC command cmd_FPS") end
		return true, "IRC cmd_FPS"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpCustomCommands() then
		if debug then dbug("debug ran IRC command cmd_HelpCustomCommands") end
		return true, "IRC cmd_HelpCustomCommands"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_Date() then
		if debug then dbug("debug ran IRC command cmd_Date") end
		return true, "IRC cmd_Date"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_Uptime() then
		if debug then dbug("debug ran IRC command cmd_Uptime") end
		return true, "IRC cmd_Uptime"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ListLocationCategories() then
		if debug then dbug("debug ran IRC command cmd_ListLocationCategories") end
		return true, "IRC cmd_ListLocationCategories"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ListLocation() then
		if debug then dbug("debug ran IRC command cmd_ListLocation") end
		return true, "IRC cmd_ListLocation"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ListLocationSpawns() then
		if debug then dbug("debug ran IRC command cmd_ListLocationSpawns") end
		return true, "IRC cmd_ListLocationSpawns"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ServerStats() then
		if debug then dbug("debug ran IRC command cmd_ServerStats") end
		return true, "IRC cmd_ServerStats"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_WhoPlayedToday() then
		if debug then dbug("debug ran IRC command cmd_WhoPlayedToday") end
		return true, "IRC cmd_WhoPlayedToday"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ListHelpCommand() then
		if debug then dbug("debug ran IRC command cmd_ListHelpCommand") end
		return true, "IRC cmd_ListHelpCommand"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_SetHelpCommand() then
		if debug then dbug("debug ran IRC command cmd_SetHelpCommand") end
		return true, "IRC cmd_SetHelpCommand"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ListHelpTopics() then
		if debug then dbug("debug ran IRC command cmd_ListHelpTopics") end
		return true, "IRC cmd_ListHelpTopics"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ListLocations() then
		if debug then dbug("debug ran IRC command cmd_ListLocations") end
		return true, "IRC cmd_ListLocations"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ListStaff() then
		if debug then dbug("debug ran IRC command cmd_ListStaff") end
		return true, "IRC cmd_ListStaff"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_RestoreAdmin() then
		if debug then dbug("debug ran IRC command cmd_RestoreAdmin") end
		return true, "IRC cmd_RestoreAdmin"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_Logout() then
		if debug then dbug("debug ran IRC command cmd_Logout") end
		return true, "IRC cmd_Logout"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_Hi() then
		if debug then dbug("debug ran IRC command cmd_Hi") end
		return true, "IRC cmd_Hi"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_Who() then
		if debug then dbug("debug ran IRC command cmd_Who") end
		return true, "IRC cmd_Who"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_Login() then
		if debug then dbug("debug ran IRC command cmd_Login") end
		return true, "IRC cmd_Login"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_RescueMe() then
		if debug then dbug("debug ran IRC command cmd_RescueMe") end
		return true, "IRC cmd_RescueMe"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_Bow() then
		if debug then dbug("debug ran IRC command cmd_Bow") end
		return true, "IRC cmd_Bow"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_IAm() then -- I am Sam. Sam I am.
		if debug then dbug("debug ran IRC command cmd_IAm") end
		return true, "IRC cmd_IAm"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpManual() then
		if debug then dbug("debug ran IRC command cmd_HelpManual") end
		return true, "IRC cmd_HelpManual"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpSetup() then
		if debug then dbug("debug ran IRC command cmd_HelpSetup") end
		return true, "IRC cmd_HelpSetup"
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_SetServerIP() then
		if debug then dbug("debug ran IRC command cmd_SetServerIP") end
		return true, "IRC cmd_SetServerIP"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_SetNewLogin() then
		if debug then dbug("debug ran IRC command cmd_SetNewLogin") end
		return true, "IRC cmd_SetNewLogin"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_Say() then
		if debug then dbug("debug ran IRC command cmd_Say") end
		return true, "IRC cmd_Say"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_SayTranslated() then
		if debug then dbug("debug ran IRC command cmd_SayTranslated") end
		return true, "IRC cmd_SayTranslated"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ListAllIngameCommandHelp() then
		if debug then dbug("debug ran IRC command cmd_ListAllIngameCommandHelp") end
		return true, "IRC cmd_ListAllIngameCommandHelp"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_ListHelp() then
		if debug then dbug("debug ran IRC command cmd_ListHelp") end
		return true, "IRC cmd_ListHelp"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpTopicServer() then
		if debug then dbug("debug ran IRC command cmd_HelpTopicServer") end
		return true, "IRC cmd_HelpTopicServer"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpTopicDonors() then
		if debug then dbug("debug ran IRC command cmd_HelpTopicDonors") end
		return true, "IRC cmd_HelpTopicDonors"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpTopicCSI() then
		if debug then dbug("debug ran IRC command cmd_HelpTopicCSI") end
		return true, "IRC cmd_HelpTopicCSI"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpTopicWatchlist() then
		if debug then dbug("debug ran IRC command cmd_HelpTopicWatchlist") end
		return true, "IRC cmd_HelpTopicWatchlist"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpTopicBadItems() then
		if debug then dbug("debug ran IRC command cmd_HelpTopicBadItems") end
		return true, "IRC cmd_HelpTopicBadItems"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpTopicAnnouncements() then
		if debug then dbug("debug ran IRC command cmd_HelpTopicAnnouncements") end
		return true, "IRC cmd_HelpTopicAnnouncements"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpTopicCommands() then
		if debug then dbug("debug ran IRC command cmd_HelpTopicCommands") end
		return true, "IRC cmd_HelpTopicCommands"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpTopicMOTD() then
		if debug then dbug("debug ran IRC command cmd_HelpTopicMOTD") end
		return true, "IRC cmd_HelpTopicMOTD"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpTopicAccessLevels() then
		if debug then dbug("debug ran IRC command cmd_HelpTopicAccessLevels") end
		return true, "IRC cmd_HelpTopicAccessLevels"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpTopicResetZones() then
		if debug then dbug("debug ran IRC command cmd_HelpTopicResetZones") end
		return true, "IRC cmd_HelpTopicResetZones"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_Stop() then
		if debug then dbug("debug ran IRC command cmd_Stop") end
		return true, "IRC cmd_Stop" -- SOTP!
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_NukeIRC() then
		if debug then dbug("debug ran IRC command cmd_NukeIRC") end
		return true, "IRC cmd_NukeIRC"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_Rules() then
		if debug then dbug("debug ran IRC command cmd_Rules") end
		return true, "IRC cmd_Rules"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if cmd_IRCInvite() then
		if debug then dbug("debug ran IRC command cmd_IRCInvite") end
		return true, "IRC cmd_IRCInvite"
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

-- ########### Staff only beyond here ###########

	if not botman.registerHelp then
		if ircSteam == "0" then
			irc_params = {} -- GET OUT!
			return true, ""
		end

		if not admin then
			irc_params = {}
			return true, "" -- and take your dog.
		end
	end

-- ########### Staff only beyond here ###########

	IRCMessage2(event, name, channel, msg)

if debug then dbug ("debug ircmessage end") end
end


function IRCMessage2(event, name, channel, msg)
-- commands have been split into 2 IRCMessage functions to bypass a 200 local variable limit imposed by Lua
if debug then dbug ("debug ircmessage2 start") end

	--displayIRCHelp = false

	tmp = {}

	local function cmd_ShopEditCategoryItems()
		if displayIRCHelp then
			irc_chat(name, "Command: shop edit {category name}")
			irc_chat(name, "Copy, edit, then paste the items in the specified shop category formatted for easy editing back into this chat.")
			irc_chat(name, "Using your favourite text editor you can bulk edit all the items in a category with the bot commands ready to re-paste.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "shop" and words[2] == "edit" and shopCategories[words[3]] then
			LookupShop(words[3])

			cursor,errorString = conn:execute("SELECT * FROM shop WHERE category = '" .. words[3] .. "' ORDER BY idx")
			row = cursor:fetch({}, "a")

			while row do
				msg = "shop add item " .. row.item .. " category " .. words[3] .. " price " .. row.price .. " stock " .. row.maxStock .. " units " .. row.units .. " quality " .. row.quality

				irc_chat(name, msg)
				row = cursor:fetch(row, "a")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ShopEditAllItemsInShop()
		local cursor2, row2

		if displayIRCHelp then
			irc_chat(name, "Command: shop edit stock")
			irc_chat(name, "Copy, edit, then paste the items for the entire shop formatted for easy editing back into this chat.")
			irc_chat(name, "Using your favourite text editor you can bulk edit all the items in the shop with the bot commands ready to re-paste.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "shop" and words[2] == "edit" and words[3] == "stock" then
			cursor,errorString = conn:execute("SELECT * FROM shopCategories ORDER BY category")
			row = cursor:fetch({}, "a")

			while row do
				cursor2,errorString = conn:execute("SELECT * FROM shop WHERE category = '" .. row.category .. "' ORDER BY idx")
				row2 = cursor2:fetch({}, "a")

				while row2 do
					msg = "shop add item " .. row2.item .. " category " .. row2.category .. " price " .. row2.price .. " stock " .. row2.maxStock .. " units " .. row2.units .. " quality " .. row2.quality

					irc_chat(name, msg)
					row2 = cursor2:fetch(row2, "a")
				end

				row = cursor:fetch(row, "a")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_GetGuides()
		if displayIRCHelp then
			irc_chat(name, "Command: get guides")
			irc_chat(name, "The bot comes with a growing number of guides to help you learn how to use the bot.  It will automatically grab them every 1-2 days but you can make it grab them immediately with this command.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "get" and words[2] == "guides") then
			irc_chat(name, "Downloading guides.  You will find them in the daily logs folder in " .. botman.chatlogPath:match("([^/]+)$") .. "\\guides")
			getGuides()
			return true
		end
	end

	local function cmd_FixBot()
		if displayIRCHelp then
			irc_chat(name, "Command: fix bot")
			irc_chat(name, "Restricted: Owners and Admins only")
			irc_chat(name, "The bot will run a number of house-keeping tasks from data collection to database maintenance.  The bot will appear frozen during this time until it has completed these tasks.")
			irc_chat(name, "DO NOT repeat the command, just wait for it to complete.  The bot will start talking again and shortly after will respond to new commands.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "fix" and words[2] == "bot") and words[3] == nil then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if not botman.fixingBot then
				botman.fixingBot = true
				fixBot()
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_AddLocationCategory()
		if displayIRCHelp then
			irc_chat(name, "Command: add location category {category} {minimum access level} {maximum access level}")
			irc_chat(name, "Add a location category and optionally assign a minimum access level and maximum access level (can be the same level.)")
			irc_chat(name, ".")
			return
		end

		if words[1] == "add" and words[2] == "location" and words[3] == "category" then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			tmp = {}
			tmp.category = wordsOld[4]
			tmp.minAccessLevel = 99
			tmp.maxAccessLevel = 0

			if numbers[1] then
				numbers[1] = math.abs(numbers[1])

				if numbers[1] > 99 then
					irc_chat(name, "Minimum access level must be in the range 0 to 99")
					irc_params = {}
					return true
				end
			end

			if numbers[2] then
				numbers[2] = math.abs(numbers[2])

				if numbers[2] > 99 then
					irc_chat(name, "Maximum access level must be in the range 0 to 99")
					irc_params = {}
					return true
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
			return true
		end
	end


	local function cmd_RemoveLocationCategory()
		if displayIRCHelp then
			irc_chat(name, "Command: remove location category")
			irc_chat(name, "Remove a location category. It is also removed from all locations currently assigned to it.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "remove" and words[2] == "location" and words[3] == "category" then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

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
			return true
		end
	end


	local function cmd_RunReport()
		if displayIRCHelp then
			irc_chat(name, "Command: run report")
			irc_chat(name, "View a report on server performance including how long the command lag is.  The report recalculates continuously until stopped by typing stop report.")
			irc_chat(name, ".")
			return
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
			return true
		end
	end


	local function cmd_StopReport()
		if displayIRCHelp then
			irc_chat(name, "Command: stop report")
			irc_chat(name, "Stop the running report.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "stop" and words[2] == "report") then
			botman.getMetrics = false
			irc_chat(name, "Reporting stopped.")
			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_UnmuteIRCUser()
		if displayIRCHelp then
			irc_chat(name, "Command: unmute irc {player}")
			irc_chat(name, "Allow a player to use bot commands on IRC again.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "unmute" and words[2] == "irc" and words[3] ~= nil) then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			name1 = words[3]
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			players[pid].ircMute = true
			conn:execute("UPDATE players SET ircMute = 0 WHERE steam = '" .. pid .. "'")

			msg = players[pid].name .. " can command the bot and can speak to ingame players."
			irc_chat(name, msg)
			irc_params = {}
			return true
		end
	end


	local function cmd_MuteIrcUser()
		if displayIRCHelp then
			irc_chat(name, "Command: mute irc {player}")
			irc_chat(name, "Block a player from commanding the bot on IRC.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "mute" and words[2] == "irc" and words[3] ~= nil) then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			name1 = words[3]
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			players[pid].ircMute = true
			conn:execute("UPDATE players SET ircMute = 1 WHERE steam = '" .. pid .. "'")

			msg = players[pid].name .. " will not be able to command the bot beyond basic info and can't speak to ingame players."
			irc_chat(name, msg)
			irc_params = {}
			return true
		end
	end


	local function cmd_RunSQLSelect()
		if displayIRCHelp then
			irc_chat(name, "Command: sql {a select statement}")
			irc_chat(name, "Run a select query on the bot's database and view the output.  It is limited to 100 records by default.  Specify a different limit if you want more.")
			irc_chat(name, "Only select queries are permitted.  This is mainly intended for debugging purposes.")
			irc_chat(name, "Only server owners can use this command.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "sql" and words[2] == "select") and players[ircSteam].accessLevel == 0 then
			tmp = {}
			tmp.sql = string.sub(msg, 4)

			if string.find(tmp.sql, ";") then
				irc_chat(name, "Using ; is not allowed :P")
				return true
			end

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
	end


	local function cmd_RunSQLMemSelect()
		if displayIRCHelp then
			irc_chat(name, "Command: sqlmem {a select statement}")
			irc_chat(name, "Run a select query on the bot's SQLite memory database and view the output.  It is limited to 100 records by default.  Specify a different limit if you want more.")
			irc_chat(name, "Only select queries are permitted.  This is mainly intended for debugging purposes.")
			irc_chat(name, "Only server owners can use this command.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "sqlmem" and words[2] == "select") and players[ircSteam].accessLevel == 0 then
			tmp = {}
			tmp.sql = string.sub(msg, 8)

			if string.find(tmp.sql, ";") then
				irc_chat(name, "Using ; is not allowed :P")
				return true
			end

			if not string.find(tmp.sql, "limit ") then
				tmp.sql = tmp.sql .. " limit 100"
			end

			cursor,errorString = connMEM:execute(tmp.sql)
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
			return true
		end
	end


	local function cmd_RunSQLTrakSelect()
		if displayIRCHelp then
			irc_chat(name, "Command: sqltrak {a select statement}")
			irc_chat(name, "Run a select query on the bot's SQLite tracking database and view the output.  It is limited to 100 records by default.  Specify a different limit if you want more.")
			irc_chat(name, "Only select queries are permitted.  This is mainly intended for debugging purposes.")
			irc_chat(name, "Only server owners can use this command.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "sqltrak" and words[2] == "select") and players[ircSteam].accessLevel == 0 then
			tmp = {}
			tmp.sql = string.sub(msg, 9)

			if string.find(tmp.sql, ";") then
				irc_chat(name, "Using ; is not allowed :P")
				return true
			end

			if not string.find(tmp.sql, "limit ") then
				tmp.sql = tmp.sql .. " limit 100"
			end

			cursor,errorString = connTRAK:execute(tmp.sql)
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
			return true
		end
	end


	local function cmd_RunSQLTrakShadowSelect()
		if displayIRCHelp then
			irc_chat(name, "Command: sqltrakshadow {a select statement}")
			irc_chat(name, "Run a select query on the bot's SQLite tracking shadow database and view the output.  It is limited to 100 records by default.  Specify a different limit if you want more.")
			irc_chat(name, "Only select queries are permitted.  This is mainly intended for debugging purposes.")
			irc_chat(name, "Only server owners can use this command.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "sqltrakshadow" and words[2] == "select") and players[ircSteam].accessLevel == 0 then
			tmp = {}
			tmp.sql = string.sub(msg, 9)

			if string.find(tmp.sql, ";") then
				irc_chat(name, "Using ; is not allowed :P")
				return true
			end

			if not string.find(tmp.sql, "limit ") then
				tmp.sql = tmp.sql .. " limit 100"
			end

			cursor,errorString = connTRAKSHADOW:execute(tmp.sql)
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
			return true
		end
	end


	local function cmd_RunSQLiteSelect()
		if displayIRCHelp then
			irc_chat(name, "Command: sqlite {a select statement}")
			irc_chat(name, "Run a select query on the bot's SQLite tracking database and view the output.  It is limited to 100 records by default.  Specify a different limit if you want more.")
			irc_chat(name, "Only select queries are permitted.  This is mainly intended for debugging purposes.")
			irc_chat(name, "Only server owners can use this command.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "sqlite" and words[2] == "select") and players[ircSteam].accessLevel == 0 then
			tmp = {}
			tmp.sql = string.sub(msg, 8)

			if string.find(tmp.sql, ";") then
				irc_chat(name, "Using ; is not allowed :P")
				return true
			end

			if not string.find(tmp.sql, "limit ") then
				tmp.sql = tmp.sql .. " limit 100"
			end

			cursor,errorString = connSQL:execute(tmp.sql)
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
			return true
		end
	end


	local function cmd_SetIRCServerIPAndPort()
		if displayIRCHelp then
			irc_chat(name, "Command: set irc server {IP:Port}")
			irc_chat(name, "The bot will connect to the IRC server that you specify.  If the IP and port are wrong, you will need to join the server and issue same command in-game but with a valid IP and port.")
			irc_chat(name, "Only server owners can use this command.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "set" and words[2] == "irc" and words[3] == "server") and players[ircSteam].accessLevel == 0 then
			server.ircServer = string.sub(msg, string.find(msgLower, " server ") + 8)
			temp = string.split(server.ircServer, ":")
			server.ircServer = temp[1]
			server.ircPort = temp[2]

			conn:execute("UPDATE server SET ircServer = '" .. escape(server.ircServer) .. "', ircPort = '" .. escape(server.ircPort) .. "'")

			irc_chat(name, "The bot will now connect to the irc server at " .. server.ircServer .. ":" .. server.ircPort)
			irc_chat(name, ".")
			joinIRCServer()
			ircSaveSessionConfigs()

			irc_params = {}
			return true
		end
	end


	local function cmd_MoveBotToNewServer()
		if displayIRCHelp then
			irc_chat(name, "Command: set server ip {server IP} port {telnet port} pass {telnet password}")
			irc_chat(name, "Make the bot join a different 7 Days to Die server.  All parts are required even if they are not changing.")
			irc_chat(name, "Only server owners can use this command.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "set" and words[2] == "server") and string.find(msgLower, "pass") and players[ircSteam].accessLevel == 0 then
			tmp = {}

			tmp.sIP = server.IP
			tmp.sPass = telnetPassword
			tmp.sPort = server.telnetPort

			for i=2,word2Count,1 do
				if words2[i] == "server" then
					tmp.sIP = words2[i+1]
				end

				if words2[i] == "ip" then
					tmp.sIP = words2[i+1]

					if string.find(tmp.sIP, ":") then
						tmp.temp = string.split(tmp.sIP, ":")
						tmp.sIP = tmp.temp[1]
					end
				end

				if words2[i] == "port" then
					tmp.sPort = words2[i+1]
				end

				if words2[i] == "pass" then
					tmp.sPass = words2[i+1]
				end
			end

			server.IP = tmp.sIP
			server.telnetPass = tmp.sPass
			server.telnetPort = tmp.sPort
			telnetPassword = tmp.sPass
			conn:execute("UPDATE server SET IP = '" .. escape(server.IP) .. "', telnetPass = '" .. escape(server.telnetPass) .. "', telnetPort = " .. escape(server.telnetPort))

			if botman.botsConnected then
				connBots:execute("UPDATE servers SET IP = '" .. escape(server.IP) .. "' WHERE botID = " .. server.botID)
			end

			-- delete some Mudlet files that store IP and other info forcing Mudlet to regenerate them.
			os.remove(homedir .. "/ip")
			os.remove(homedir .. "/port")
			os.remove(homedir .. "/password")
			os.remove(homedir .. "/url")

			reconnect(tmp.sIP, tmp.sPort, true)
			saveProfile()

			irc_chat(server.ircMain, "Connecting to new 7 Days to Die server " .. server.IP .. " port " .. server.telnetPort)
			irc_chat(chatvars.ircAlias, "Connecting to new 7 Days to Die server " .. server.IP .. " port " .. server.telnetPort)
			irc_params = {}
			return true
		end
	end


	local function cmd_RestartBot()
		if displayIRCHelp then
			irc_chat(name, "Command: restart bot")
			irc_chat(name, "If your bot's server or the bot's launcher script monitors the bot's process ID, you can command the bot to shut down and restart itself.  This can help to fix temporary problems with the bot.")
			irc_chat(name, "All bots hosted at botmanhosting or hosted by Smegz0r can be restarted this way.  The command is disabled by default.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "restart" and words[2] == "bot") then
			if not server.allowBotRestarts then
				irc_chat(name, "This command is disabled.  Enable it with /enable bot restart")
				irc_chat(name, "If you do not have a script or other process monitoring the bot, it will not restart automatically.")
				irc_chat(name, "Scripts can be downloaded at https://botman.nz/shellscripts.zip and may require some editing for paths.")
				irc_params = {}
				return true
			end

			if server.masterPassword ~= "" then
				irc_chat(name, "This command requires a password to complete.")
				irc_chat(name, "Type " .. server.commandPrefix .. "password {the password} (Do not type the {}).")
				players[ircSteam].botQuestion = "restart bot"
			else
				restartBot()
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_CheckDisk()
		if displayIRCHelp then
			irc_chat(name, "Command: check disk")
			irc_chat(name, "View basic information about disk usage on the server hosting the bot.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "check" and words[2] == "disk" and words[3] == nil then
			irc_reportDiskFree(name)
			irc_params = {}
			return true
		end
	end


	local function cmd_SetCommandPrefix()
		if displayIRCHelp then
			irc_chat(name, "Command: command prefix {new in-game command prefix}")
			irc_chat(name, "Change the in-game command prefix to something else.  The default is /  The bot can automatically change to ! if it detects some other server managers.")
			irc_chat(name, "If there is a command clash between the bot and another manager or mod, you should use this command.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "command" and words[2] == "prefix") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			tmp = {}
			tmp.prefix = string.sub(msg, string.find(msgLower, "prefix") + 7)
			tmp.prefix = string.sub(tmp.prefix, 1, 1)

			if tmp.prefix ~= "" then
				server.commandPrefix = tmp.prefix
				conn:execute("UPDATE server SET commandPrefix = '" .. escape(tmp.prefix) .. "'")
				irc_chat(server.ircMain, "Ingame bot commands must now start with a " .. tmp.prefix)
				message("say [" .. server.chatColour .. "]Commands now begin with a " .. server.commandPrefix .. " To use commands such as who type " .. server.commandPrefix .. "who.[-]")

				hidePlayerChat(tmp.prefix)
			else
				server.commandPrefix = ""
				conn:execute("UPDATE server SET commandPrefix = ''")
				irc_chat(server.ircMain, "Ingame bot commands do not use a prefix and can be typed in public chat.")
				message("say [" .. server.chatColour .. "]Bot commands are now just text.  To use commands such as who simply type who.[-]")

				hidePlayerChat()
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ViewServerSettings()
		if displayIRCHelp then
			irc_chat(name, "Command: server settings {optional filter}")
			irc_chat(name, "View current settings in the bot, organised by category.  You can view a specific category if you type it after settings.")
			irc_chat(name, "The categories are: chat, shop, teleports, security, waypoints, misc, games, irc, mods.")
			irc_chat(name, "The displayed settings may not be a complete list as the bot is still under development and new settings are added frequently.")
			irc_chat(name, ".")
			return
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
					irc_chat(name, "Idle players are kicked after " .. server.idleKickTimer .. " seconds when the server is full")
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

				if server.maxServerUptime < 25 then
					irc_chat(name, "Max server uptime before a reboot is " .. server.maxServerUptime .. " hours")
				else
					irc_chat(name, "Max server uptime before a reboot is " .. server.maxServerUptime .. " minutes")
				end

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
					irc_chat(name, "ALERT!  Alloc's mod is not installed!  The bot can't function without it.  Grab it here https://botman.nz/Botman_Mods.zip")
				end
			end

			irc_chat(name, "-end-")
			irc_params = {}
			return true
		end
	end


	local function cmd_ListNewPlayers()
		if displayIRCHelp then
			irc_chat(name, "Command: new players")
			irc_chat(name, "List new players that have joined in the last 24 hours.  To see further back, add a number eg: new players 5 will give you the last 5 days.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "new" and words[2] == "players" then
			if number == nil then
				number = 86400
			else
				number = number * 86400
			end

			irc_chat(name, "New players in the last " .. math.floor(number / 86400) .. " days:")

			cursor,errorString = conn:execute("SELECT * FROM events WHERE timestamp >= '" .. os.date('%Y-%m-%d %H:%M:%S', os.time() - number).. "' AND type = 'new player' ORDER BY timestamp DESC")
			row = cursor:fetch({}, "a")

			while row do
				if not isAdminHidden(ircSteam, ircUserID) then
					irc_chat(name, v.name)
				else
					msg = "steam: " .. row.steam .. " id: " .. players[row.steam].id .. " name: " .. players[row.steam].name .. " at [ " .. players[row.steam].xPos .. " " .. players[row.steam].yPos .. " " .. players[row.steam].zPos .. " ] " .. players[row.steam].country
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

					cursor2,errorString = conn:execute("SELECT * FROM bans WHERE steam =  '" .. row.steam .. "'")
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
			return true
		end
	end


	local function cmd_CheckPlayerOnBlacklist()
		if displayIRCHelp then
			irc_chat(name, "Command: check dns {player}")
			irc_chat(name, "Make the bot do a DNS lookup on any player.  Mainly useful if a player of interest is already in the game before the bot joined.  Otherwise the bot will check their DNS only when the player re-logs.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "check" and words[2] == "dns" then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if debug then dbug("debug ircmessage2 " .. msg) end
			pid = "0"
			number = ""

			for i=2,wordCount,1 do
				if words2[i] == "dns" then
					name1 = words2[i+1]
					pid = LookupPlayer(name1)
				end
			end


			if pid ~= "0" then
				number = players[pid].ip

				irc_chat(name, "Checking DNS record for " .. pid .. " IP " .. number)
				CheckBlacklist(pid, number)
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ViewAlerts()
		if displayIRCHelp then
			irc_chat(name, "Command: view alerts")
			irc_chat(name, "")
			irc_chat(name, ".")
			return
		end

		if words[1] == "view" and words[2] == "alerts" then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if debug then dbug("debug ircmessage2 " .. msg) end
			if number == nil then number = 20 end

			cursor,errorString = conn:execute("SELECT * FROM alerts ORDER BY alertID DESC LIMIT " .. number)
			if cursor:numrows() == 0 then
				irc_chat(name, "There are no alerts recorded.")
			else
				irc_chat(name, "The most recent alerts are:")
				row = cursor:fetch({}, "a")
				while row do
					msg = "#" .. row.alertID .. " [" .. row.status .. "] on " .. os.date("%Y-%m-%d %H:%M:%S", row.timestamp) .. " player " .. players[row.steam].name .. " " .. row.steam .. " at " .. row.x .. " " .. row.y .. " " .. row.z .. " said " .. row.message
					irc_chat(name, msg)
					row = cursor:fetch(row, "a")
				end
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_UpdateAlert()
		if displayIRCHelp then
			irc_chat(name, "Command: alert {number} status {your text here (max 100 length)}")
			irc_chat(name, "")
			irc_chat(name, ".")
			return
		end

		if words[1] == "alert" and words[3] == "status" then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if number == nil then
				irc_chat(name, "Alert ID number expected.")

				irc_params = {}
				return true
			end

			tmp = {}
			tmp.status = string.sub(msg, string.find(msgLower, " status ") + 8)

			conn:execute("UPDATE alerts SET status = '" .. escape(tmp.status) .. "' WHERE alertID = " .. number)
			irc_chat(name, "Alert #" .. number .. " status is " .. tmp.status .. ".")

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_DeleteAlert()
		if displayIRCHelp then
			irc_chat(name, "Command: delete alert {number}")
			irc_chat(name, "")
			irc_chat(name, ".")
			return
		end

		if words[1] == "delete" and words[2] == "alert" then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if number == nil then
				irc_chat(name, "Alert ID number expected.")

				irc_params = {}
				return true
			end

			conn:execute("DELETE FROM alerts WHERE alertID = " .. number)
			irc_chat(name, "Alert #" .. number .. " has been deleted.")

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_DeleteAllAlerts()
		if displayIRCHelp then
			irc_chat(name, "Command: delete alerts (delete all of them)")
			irc_chat(name, "")
			irc_chat(name, ".")
			return
		end

		if words[1] == "delete" and words[2] == "alerts" then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			conn:execute("Truncate alerts")
			irc_chat(name, "All alerts have been deleted. No need to be alarmed :}")

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ViewSlots()
		if displayIRCHelp then
			irc_chat(name, "Command: view slots")
			irc_chat(name, "View information about the bot's player slots and reserved slots.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "view" and words[2] == "slots") and admin then
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
					irc_chat(name, "Slot " .. row.slot .. " | reserved " .. dbYN(row.reserved) .. " | steam " .. row.steam .. " | name " .. row.name .. " | staff " .. dbYN(row.staff))
				else
					irc_chat(name, "Slot " .. row.slot .. " | reserved " .. dbYN(row.reserved) .. " | steam " .. row.steam .. " | name | staff " .. dbYN(row.staff))
				end

				row = cursor:fetch(row, "a")
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShowInventory()
		if displayIRCHelp then
			irc_chat(name, "Command: show inventory")
			irc_chat(name, "View historic inventory movement of a player.  They do not need to be playing right now.")
			irc_chat(name, "eg. show inventory player Joe xpos 100 zpos 200 days 2 range 50 item tnt qty 20 exclude bob")
			irc_chat(name, "eg. show inventory player Joe xpos 100 zpos 200 hours 1 range 50 item tnt qty 20 exclude bob")
			irc_chat(name, ".")
			irc_chat(name, "You can grab the coords from any player by adding, near john (for example)")
			irc_chat(name, "Defaults: days = 1, range = 100km, xpos = 0, zpos = 0")
			irc_chat(name, "Optional: player (or near) joe, days 1, hours 1, range 50, item tin, qty 10, xpos 0, zpos 0, session 1")
			irc_chat(name, "Currently this command always reports up to the current time.  Later you will be able to specify an end date and time.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "show" and words[2] == "inventory" then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if words[3] == nil then
				irc_chat(name, "Full example.. show inventory player Joe xpos 100 zpos 200 days 2 range 50 item tnt qty 20")
				irc_chat(name, "You can grab the coords from any player by adding, near joe")
				irc_chat(name, "Defaults: days = 1, range = 100km, xpos = 0, zpos = 0")
				irc_chat(name, "Optional: player (or near) joe, days 1, hours 1, range 50, item tin, qty 10, xpos 0, zpos 0, session 1")
				irc_chat(name, ".")
				irc_params = {}
				return true
			end

			tmp.name1 = nil
			tmp.pid = "0"
			tmp.days = 1
			tmp.hours = 0
			tmp.range = 100000
			tmp.item = nil
			tmp.xpos = 0
			tmp.zpos = 0
			tmp.qty = nil
			tmp.session = 0

			for i=3,wordCount,1 do
				if words2[i] == "player" then
					tmp.name1 = words2[i+1]
					tmp.pid = LookupPlayer(tmp.name1)
				end

				if words2[i] == "days" or words2[i] == "day" then
					tmp.days = tonumber(words2[i+1])
				end

				if words2[i] == "hours" or words2[i] == "hour" then
					tmp.hours = tonumber(words2[i+1])
					tmp.days = 0
				end

				if words2[i] == "range" then
					tmp.range = tonumber(words2[i+1])
				end

				if words2[i] == "item" then
					tmp.item = words2[i+1]
				end

				if words2[i] == "exclude" then
					tmp.exclude = words2[i+1]
				end

				if words2[i] == "qty" then
					tmp.qty = words2[i+1]
				end

				if words2[i] == "xpos" or words2[i] == "x" then
					tmp.xpos = tonumber(words2[i+1])
				end

				if words2[i] == "zpos" or words2[i] == "z" then
					tmp.zpos = tonumber(words2[i+1])
				end

				if words2[i] == "session" then
					tmp.session = words2[i+1]
				end

				if words2[i] == "near" then
					tmp.name2 = words2[i+1]
					tmp.pid2 = LookupPlayer(tmp.name2)

					if tmp.pid2 ~= "0" then
						tmp.xpos = players[tmp.pid2].xPos
						tmp.zpos = players[tmp.pid2].zPos
					end
				end
			end

			if tmp.days == 0 then
				tmp.sql = "SELECT * FROM inventoryChanges WHERE abs(x - " .. tmp.xpos .. ") <= " .. tmp.range .. " AND abs(z - " .. tmp.zpos .. ") <= " .. tmp.range .. " AND timestamp >= " .. os.time() - (tonumber(tmp.hours) * 3600) .. " "
			else
				tmp.sql = "SELECT * FROM inventoryChanges WHERE abs(x - " .. tmp.xpos .. ") <= " .. tmp.range .. " AND abs(z - " .. tmp.zpos .. ") <= " .. tmp.range .. " AND timestamp >= " .. os.time() - (tonumber(tmp.days) * 86400) .. " "
			end

			if tmp.session ~= 0 then
				tmp.sql = "SELECT * FROM inventoryChanges WHERE abs(x - " .. tmp.xpos .. ") <= " .. tmp.range .. " AND abs(z - " .. tmp.zpos .. ") <= " .. tmp.range .. " AND session = " .. tmp.session .. " "
			end

			if tmp.pid ~= "0" then
				tmp.sql = tmp.sql .. "AND steam = '" .. tmp.pid .. "' "
			end

			if tmp.qty ~= nil then
				if tonumber(tmp.qty) > 0 then
					tmp.sql = tmp.sql .. "AND delta > " .. tmp.qty .. " "
				else
					tmp.sql = tmp.sql .. "AND delta < " .. tmp.qty .. " "
				end
			end

			if tmp.item ~= nil then
				tmp.sql = tmp.sql .. "AND item like '%" .. connMEM:escape(tmp.item) .. "%'"
			end

			irc_chat(name, "Inventory tracking data for query:")
			irc_chat(name, tmp.sql)

			cursor,errorString = connINVDELTA:execute(tmp.sql)
			row = cursor:fetch({}, "a")

			if not row then
				irc_chat(name, "No inventory tracking is recorded for your search parameters.")
			else
				irc_chat(name, " ")
				irc_chat(name, "   id   |      steam       |      timestamp     |    item     | qty | x y z | session | name")
			end

			while row do
				if exclude then
					if players[row.steam].name ~= exclude then
						msg = os.date("%Y-%m-%d %H:%M:%S", row.timestamp) .. ", " .. row.steam .. ", " .. row.item .. ", " .. row.delta .. ", " .. row.x .. " " .. row.y .. " " .. row.z .. ", " .. row.session .. ", " .. players[row.steam].name
					end
				else
					msg = os.date("%Y-%m-%d %H:%M:%S", row.timestamp) .. ", " .. row.steam .. ", " .. row.item .. ", " .. row.delta .. ", " .. row.x .. " " .. row.y .. " " .. row.z .. ", " .. row.session .. ", " .. players[row.steam].name
				end

				irc_chat(name, msg)
				row = cursor:fetch(row, "a")
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ViewRollingAnnouncements()
		if displayIRCHelp then
			irc_chat(name, "Command: announcements")
			irc_chat(name, "View the rolling announcements.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "announcements" then
			if debug then dbug("debug ircmessage2 " .. msg) end
			counter = 1
			cursor,errorString = conn:execute("SELECT * FROM announcements")
			if cursor:numrows() == 0 then
				irc_chat(name, "There are no announcements recorded.")
			else
				irc_chat(name, "The server announcements are:")
				row = cursor:fetch({}, "a")
				while row do
					if row.triggerServerTime ~= '00:00:00' then
						msg = "Announcement (" .. counter .. ") [ at " .. row.triggerServerTime .. " ] " .. row.message
					else
						msg = "Announcement (" .. counter .. ") " .. row.message
					end

					counter = counter + 1
					irc_chat(name, msg)
					row = cursor:fetch(row, "a")
				end
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_AddAnnouncement()
		if displayIRCHelp then
			irc_chat(name, "Command: add announcement")
			irc_chat(name, "Add a new rolling announcement.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "add" and words[2] == "announcement" and words[3] ~= nil then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if debug then dbug("debug ircmessage2 " .. msg) end

			if words[3] == "time" then
				tmp.hour = words[4]
				tmp.minute = words[5]
				tmp.msg = string.sub(msg, 28, string.len(msg))
				tmp.msg = string.trim(tmp.msg)

				if not tonumber(tmp.hour) then
					irc_chat(name, "Hour is not valid.  Expected a number from 0 to 23.")
					irc_chat(name, ".")
					irc_params = {}
					return true
				end

				tmp.hour = tonumber(tmp.hour)

				if tmp.hour < 0 or tmp.hour > 23 then
					irc_chat(name, "Hour is not valid.  Expected a number from 0 to 23.")
					irc_chat(name, ".")
					irc_params = {}
					return true
				end

				if not tonumber(tmp.minute) then
					irc_chat(name, "Minute is not valid.  Expected a number from 0 to 59.")
					irc_chat(name, ".")
					irc_params = {}
					return true
				end

				tmp.minute = tonumber(tmp.minute)

				if tmp.minute < 0 or tmp.minute > 59 then
					irc_chat(name, "Minute is not valid.  Expected a number from 0 to 59.")
					irc_chat(name, ".")
					irc_params = {}
					return true
				end

				conn:execute("INSERT INTO announcements (message, triggerServerTime) VALUES ('" .. escape(tmp.msg) .. "','" .. tmp.hour .. ":" .. tmp.minute  .. ":00')")
				irc_chat(name, "New announcement added that will trigger at " .. tmp.hour .. ":" .. tmp.minute .. " server time.")
				irc_chat(name, "The new announcement is: " .. tmp.msg)
			else
				tmp.msg = string.sub(msg, 17, string.len(msg))
				tmp.msg = string.trim(tmp.msg)

				conn:execute("INSERT INTO announcements (message) VALUES ('" .. escape(tmp.msg) .. "')")
				irc_chat(name, "New announcement added.")
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_DeleteAnnouncement()
		if displayIRCHelp then
			irc_chat(name, "Command: delete announcement")
			irc_chat(name, "If you type 'announcements' you will see a numbered list of rolling announcements.  To delete a specific announcement type its number at the end of this command.")
			irc_chat(name, "eg. delete announcement 3")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "delete" or words[1] == "remove") and words[2] == "announcement" and words[3] ~= nil then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
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

			irc_chat(name, "Announcement " .. number .. " deleted.")
			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_WhoVisited()
		if displayIRCHelp then
			irc_chat(name, "Command: who visited")
			irc_chat(name, "See who visited a player location or base.")
			irc_chat(name, "Example with defaults:  who visited player smeg days 1 range 10 height 4")
			irc_chat(name, "Example with coords:  who visited x 0 y 100 z 0 height 5 days 1 range 20")
			irc_chat(name, "Another example:  who visited player smeg base")
			irc_chat(name, "Another example:  who visited bed smeg")
			irc_chat(name, "Setting hours will reset days to zero")
			irc_chat(name, "Defaults: days = 1 or hours = 0, range = 10")
			irc_chat(name, "This report could be very long. You can cancel it by typing nuke irc")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "who" and words[2] == "visited") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if words[3] == nil then
				irc_chat(name, "See who visited a player location or base.")
				irc_chat(name, "Example with defaults:  who visited player smeg days 1 range 10 height 4")
				irc_chat(name, "Example with coords:  who visited x 0 y 100 z 0 height 5 days 1 range 20")
				irc_chat(name, "Another example:  who visited player smeg base")
				irc_chat(name, "Another example:  who visited bed smeg")
				irc_chat(name, "Setting hours will reset days to zero")
				irc_chat(name, "Defaults: days = 1 or hours = 0, range = 10")
				irc_chat(name, "This report could be very long. You can cancel it by typing nuke irc")
				irc_chat(name, ".")
				irc_params = {}
				return true
			end

			tmp = {}
			tmp.days = 1
			tmp.hours = 0
			tmp.range = 10
			tmp.height = 10
			tmp.basesOnly = "player"
			tmp.steam = "0"
			tmp.useShadowCopy = false

			for i=3,wordCount,1 do
				if words[i] == "player" or words[i] == "bed" then
					tmp.name = words[i+1]
					tmp.steam = LookupPlayer(tmp.name)

					if tmp.steam ~= "0" and words[i] == "player" then
						tmp.player = true
						tmp.x = players[tmp.steam].xPos
						tmp.y = players[tmp.steam].yPos
						tmp.z = players[tmp.steam].zPos
					end

					if tmp.steam ~= "0" and words[i] == "bed" then
						tmp.bed = true
						tmp.x = players[tmp.steam].bedX
						tmp.y = players[tmp.steam].bedY
						tmp.z = players[tmp.steam].bedZ
					end
				end

				if i > 4 then
					if words[i] == "shadow" then
						tmp.useShadowCopy = true
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
					tmp.basesOnly = "base"
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

			if (tmp.basesOnly == "base") and tmp.steam ~= "0" then
				irc_chat(name, "This report could be very long.  Cancel it by typing nuke irc")

				tmp.bases = {}

				for k,v in pairs(bases) do
					if v.steam == tmp.steam then
						tmp.bases[tonumber(v.baseNumber)] = k
					end
				end

				for k,v in ipairs(tmp.bases) do
					tmp.base = bases[v]
					irc_chat(name, "Players who visited within " .. tmp.range .. " metres of base " .. string.trim(tmp.base.baseNumber .. " " .. tmp.base.title) .. " of " .. players[tmp.steam].name .. " at " .. tmp.base.x .. " " .. tmp.base.y .. " " .. tmp.base.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
					dbWho(name, tmp.base.x, tmp.base.y, tmp.base.z, tmp.range, tmp.days, tmp.hours, tmp.height, ircSteam, false, tmp.useShadowCopy)
					irc_chat(name, ".")
				end
			end

			if tmp.basesOnly == "player" and tmp.steam ~= "0" then
				if tmp.player then
					irc_chat(name, "Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. " at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
				end

				if tmp.bed then
					irc_chat(name, "Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. "'s bed at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
				end

				dbWho(name, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height, ircSteam, false, tmp.useShadowCopy)
			end

			if tmp.steam == "0" then
				irc_chat(name, "Players who visited within " .. tmp.range .. " metres of " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
				dbWho(name, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height, ircSteam, false, tmp.useShadowCopy)
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_PayPlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: pay {player} {amount of {monies}}")
			irc_chat(name, "eg. pay joe 1000.  Joe will receive 1000 {monies} and will be alerted with a private message.  You will also see a confirmation message that you have paid them.")
			irc_chat(name, "Only owners and level 1 admins can do this on IRC.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "pay") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			tmp = {}
			tmp.name1 = words[2]
			tmp.name1 = string.trim(tmp.name1)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.name1)
			tmp.cash = tonumber(words[wordCount])

			if tmp.cash == nil then
				irc_chat(name, "You forgot to tell me how much you want to pay.")

				irc_params = {}
				return true
			end

			tmp.cash = math.abs(tmp.cash)

			if tmp.steam ~= "0" then
				players[tmp.steam].cash = players[tmp.steam].cash + tmp.cash

				conn:execute("UPDATE players set cash = " .. escape(players[tmp.steam].cash) .. " WHERE steam = '" .. tmp.steam .. "'")

				message("pm " .. tmp.userID .. " " .. players[ircSteam].name .. " just paid you " .. tmp.cash .. " " .. server.moneyPlural .. "!  You now have " .. string.format("%d", players[tmp.steam].cash) .. " " .. server.moneyPlural .. "!  KA-CHING!!")
				msg = "You just paid " .. tmp.cash .. " " .. server.moneyPlural .. " to " .. players[tmp.steam].name .. " giving them a total of " .. string.format("%d", players[tmp.steam].cash) .. " " .. server.moneyPlural .. "."
				irc_chat(name, msg)
			else
				irc_chat(name, "No player found called " .. tmp.name1)
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_SetPlayerCash()
		if displayIRCHelp then
			irc_chat(name, "Command: set player {name} cash {value}")
			irc_chat(name, "Command: set player everyone cash {value}")
			irc_chat(name, "Reset a player's cash to a specific amount to fix stuff-ups, or reset everyone's cash if you type everyone instead of a player name.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "set" and words[2] == "player" and (string.find(msgLower, "cash") or string.find(msgLower, "money") or string.find(msgLower, string.lower(server.moneyPlural))) and players[ircSteam].accessLevel == 0 then
			if words[3] ~= "everyone" then
				name1 = words[3]
				name1 = string.trim(name1)
				pid = LookupPlayer(name1)

				if pid ~= "0" then
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
							return true
						end
					end

					players[pid].cash = number
					conn:execute("UPDATE players set cash = " .. escape(players[pid].cash) .. " WHERE steam = '" .. pid .. "'")
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
						return true
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
			return true
		end
	end


	local function cmd_SetCodeBranch()
		if displayIRCHelp then
			irc_chat(name, "Command: set update branch {branch name}")
			irc_chat(name, "Tell the bot to switch to a different code branch.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "set" and (words[2] == "update" or words[2] == "code") and words[3] == "branch" and words[4] ~= nil then
			server.server.updateBranch = words[4]
			irc_chat(name, "The bot will check for updates from the " .. server.updateBranch .. " code branch.")
			irc_chat(name, ".")
			conn:execute("UPDATE server SET updateBranch = '" .. escape(server.updateBranch) .. "'")
			irc_params = {}
			return true
		end
	end


	local function cmd_ToggleDebugMode()
		if displayIRCHelp then
			irc_chat(name, "Command: enable/disable debug")
			irc_chat(name, "If you have access to Mudlet you can enable or disable debug output to Mudlet's debug and lists windows. This automatically disables itself when Mudlet is closed.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "enable" or words[1] == "disable") and words[2] == "debug" and words[3] == nil then
			if words[1] == "enable" then
				server.enableWindowMessages = true
				irc_chat(name, "Debugging enabled")
			else
				server.enableWindowMessages = false
				irc_chat(name, "Debugging disabled")
			end

			return true
		end
	end


	local function cmd_ListClaims()
		if displayIRCHelp then
			irc_chat(name, "Command: claims {optional player}")
			irc_chat(name, "List all of the claims on the server or a specific player's claims.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "claims") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if debug then dbug("debug ircmessage2 " .. msg) end
			if players[ircSteam].ircAuthenticated == false then
				if requireLogin(name) then
					irc_params = {}
					return true
				end
			end

			steam = "0"

			if (words[2] ~= nil) then
				name1 = string.sub(msg, string.find(msgLower, "claims") + 7)
				name1 = string.trim(name1)
				steam, steamOwner, userID = LookupPlayer(name1)
			end

			if steam == "0" then
				for k, v in pairs(players) do
					if tonumber(v.keystones) > 0 then
						msg = v.keystones .. "   claims belong to " .. k .. " " .. v.userID ..  " " .. v.name
						irc_chat(name, msg)
					end
				end
			else
				msg = players[steam].name .. " " .. steam .. " " .. userID .. " has placed " .. players[steam].keystones .. " at these coordinates.."
				irc_chat(name, msg)
				cursor,errorString = connSQL:execute("SELECT * FROM keystones WHERE steam = '" .. userID .. "'")
				row = cursor:fetch({}, "a")
				while row do
					if row.expired then
						tmp.expired = ""
					else
						tmp.expired = "active"
					end

					msg = row.x .. " " .. row.y .. " " .. row.z .. " " .. tmp.expired
					irc_chat(name, msg)
					row = cursor:fetch(row, "a")
				end
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_RunIngameCommand()
		if displayIRCHelp then
			irc_chat(name, "Command: cmd {normal ingame command}")
			irc_chat(name, "Use an in-game command from IRC.  The command is identical to how you use it in-game except you prefix it with cmd.  eg.  cmd /uptime.  Not all in-game commands allow you to use them from IRC and will tell you if you can't use them.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "cmd") then
			msg = string.trim(string.sub(msg, string.find(msgLower, "cmd") + 4))
			gmsg(msg, ircSteam)
			irc_params = {}

			return true
		end
	end


	local function cmd_SendPM()
		if displayIRCHelp then
			irc_chat(name, "Command: pm {player} {message}")
			irc_chat(name, "")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "pm") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			steam, steamOwner, userID = LookupPlayer(words[2])

			if steam ~= "0" then
				msg = string.sub(msg, string.find(msg, words2[2], nil, true) + string.len(words2[2]) + 1)

				if igplayers[steam] then
					message("pm " .. userID .. " " .. name .. "-irc: [i]" .. msg .. "[-]")
					irc_chat(name, "pm sent to " .. players[steam].name .. " you said " .. msg)
				else
					connSQL:execute("INSERT INTO mail (sender, recipient, message) VALUES ('" .. ircSteam .. "','" .. steam .. "', '" .. connMEM:escape(msg) .. "')")
					irc_chat(name, "Mail sent to " .. players[steam].name .. " you said " .. msg)
					irc_chat(name, "They will receive your message when they join the server.")
				end
			else
				irc_chat(name, "No player called " .. words[2] .. " found.")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_SendConsoleCommand()
		if displayIRCHelp then
			irc_chat(name, "Command: con {console command}")
			irc_chat(name, "Send a console command to the server.  If you don't see the console output on IRC it will be a command that the bot doesn't pipe back to IRC.  The command will still be sent.  This feature is restricted to server owners.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "con") and tonumber(players[ircSteam].accessLevel) == 0 then
			msg = string.trim(string.sub(msg, string.find(msgLower, "con") + 4))
			echoConsole = false
			echoConsoleTo = name
			echoConsoleTrigger = msg

			if string.sub(msg, 1, 3) == "si " then
				echoConsoleTrigger = string.sub(msg, 4)

			end

			if server.useAllocsWebAPI then
				-- conQueue is only used in API mode
				conQueue[name] = {}
				conQueue[name].ircUser = name
				conQueue[name].command = msg
			end

			if msg ~= "lp" then
				sendCommand(msg)
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_AssignBotOwner()
		local steam, steamOwner, userID, platform

		if displayIRCHelp then
			irc_chat(name, "Command: set bot owner {steam ID}")
			irc_chat(name, "Assign a steam ID as owner of this bot. Only 1 steam ID can be the bot owner and this can only be assigned once.")
			irc_chat(name, "This isn't currently used by the bot but will be used later.")
			irc_chat(name, "To use this command you must be a level 0 admin and to have been seen on the server by the bot.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "set" and words[2] == "bot" and words[3] == "owner" and words[4] ~= nil and (players[ircSteam].accessLevel == 0) then
			if server.botOwner ~= "0" then
				irc_chat(name, "The bot owner has already be been set.  To change it now you must manually edit the bot's server table in the database.")
				irc_params = {}
				return true
			end

			steam, steamOwner, userID = LookupPlayer(words[4])

			if steam ~= "0" then
				server.botOwner = steam
				conn:execute("UPDATE server SET botOwner = '" .. escape(steam) .. "'")
				irc_chat(name, "This bot is now owned by " .. platform .. "_" .. steam .. " " .. players[steam].name)
			else
				irc_chat(name, "Nobody called " .. words[4] .. " found.")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ListVillagers()
		if displayIRCHelp then
			irc_chat(name, "Command: villagers")
			irc_chat(name, "List all of the villagers.  It also shows who are the mayors.")
			irc_chat(name, ".")
			return
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
			return true
		end
	end


	local function cmd_SetBaseCooldown()
		if displayIRCHelp then
			irc_chat(name, "Command: base cooldown {seconds}")
			irc_chat(name, "Set a timer between uses of the {#}base or {#}home command.  Donors wait half as long.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "base") and (words[2] == "cooldown" or words[2] == "timer") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if words[3] == nil then
				irc_chat(name, server.commandPrefix .. "base can only be used once every " .. (server.baseCooldown / 60) .. " minutes if player is not in a group.")
				irc_chat(name, ".")
				irc_params = {}
				return true
			end

			if words[3] ~= nil then
				server.baseCooldown = tonumber(words[3])
				irc_chat(name, "The base cooldown timer is now " .. (server.baseCooldown / 60) .. " minutes if player not in a group.")
				irc_chat(name, ".")

				conn:execute("UPDATE server SET baseCooldown = " .. server.baseCooldown)
				irc_params = {}
				return true
			end
		end
	end


	local function cmd_SetRules()
		if displayIRCHelp then
			irc_chat(name, "Command: set rules {new rules}")
			irc_chat(name, "Change the server rules.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "set" and words[2] == "rules") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if words[3] ~= nil then
				server.rules = string.sub(msg, string.find(msgLower, "set rules") + 9)
				irc_chat(name, "New server rules recorded: " .. server.rules)
				irc_chat(name, ".")

				conn:execute("UPDATE server SET rules = '" .. escape(server.rules) .. "'")
				irc_params = {}
				return true
			end
		end
	end


	local function cmd_ViewOrClearMOTD()
		if displayIRCHelp then
			irc_chat(name, "Command: motd")
			irc_chat(name, "View the message of the day.  You can clear it with motd clear.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "motd") then
			if words[2] == nil then
				irc_chat(name, "MOTD is " .. server.MOTD)
				irc_chat(name, ".")
				irc_params = {}
				return true
			end

			if words[2] == "delete" or words[2] == "clear" then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

				server.MOTD = nil
				irc_chat(name, "Message of the day has been deleted.")
				irc_chat(name, ".")

				conn:execute("UPDATE server SET MOTD = ''")
				irc_params = {}
				return true
			end

			irc_chat(name, "To change the MOTD type set motd <new message of the day>")
			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_SetMOTD()
		if displayIRCHelp then
			irc_chat(name, "Command: set motd {message}")
			irc_chat(name, "Change the message of the day.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "set" and words[2] == "motd") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if words[3] ~= nil then
				server.MOTD = string.sub(msg, string.find(msgLower, "set motd") + 9)
				irc_chat(name, "New message of the day recorded. " .. server.MOTD)
				irc_chat(name, ".")

				conn:execute("UPDATE server SET MOTD = '" .. escape(server.MOTD) .. "'")
				irc_params = {}
				return true
			end
		end
	end


	local function cmd_SetAPIPort()
		if displayIRCHelp then
			irc_chat(name, "Command: set api port")
			irc_chat(name, "Tell the bot what port the Alloc's API is using.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "set" and words[2] == "api" and words[3] == "port" and words[4] ~= nil and (players[ircSteam].accessLevel == 0) then
			if number == nil then
				irc_chat(name, "Port number between 1 and 65535 expected.")
				return true
			else
				number = math.abs(number)
			end

			if tonumber(number) > 65535 then
				irc_chat(name, "Valid ports range from 1 to 65535.")
				return true
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

			return true
		end
	end


	local function cmd_SetAPIKey()
		if displayIRCHelp then
			irc_chat(name, "Command: set api key {API key from 7daystodie-servers.com}")
			irc_chat(name, "Tell the bot your servers API key.  DO NOT do this in a public channel!\n")
			irc_chat(name, "Your key is not logged or displayed anywhere.  It is kept out of the database too.\n")
			irc_chat(name, "Once set, your players will be able to use the command {#}claim vote.\n")
			irc_chat(name, ".")
			return
		end

		if words[1] == "set" and words[2] == "api" and words[3] == "key" and words[4] ~= nil and (players[ircSteam].accessLevel == 0) then
			serverAPI = wordsOld[4]
			writeAPI()
			irc_chat(name, "Your players can now get rewarded for voting for your server using the command {#}claim vote")
			return true
		end
	end


	local function cmd_ListBotTables()
		if displayIRCHelp then
			irc_chat(name, "Command: list tables")
			irc_chat(name, "List the bot's tables.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "list") and (words[2] == "tables") and (words[3] == nil) and (players[ircSteam].accessLevel == 0) then
			irc_ListTables()
			irc_params = {}
			return true
		end
	end


	local function cmd_ShowBotTable()
		if displayIRCHelp then
			irc_chat(name, "Command: show table {table name} {optional search string}")
			irc_chat(name, "View the contents of one of the bot's tables.  Not all tables will display but you'll soon work out which ones you can view.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "show") and (words[2] == "table") and (words[3] ~= nil) and (players[ircSteam].accessLevel == 0) then
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
				return true
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
				return true
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
				return true
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
				return true
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
			return true
		end
	end


	local function cmd_ResetBotKeepCash()
		if displayIRCHelp then
			irc_chat(name, "Command: reset bot keep money")
			irc_chat(name, "Make the bot forget map specific information but remember the player cash.  Use this command after a map wipe.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "reset" and words[2] == "bot" and words[3] == "keep" and words[4] == "money" and (players[ircSteam].accessLevel == 0) then
			players[ircSteam].botQuestion = "reset bot keep money"
			irc_chat(name, "ALERT! Only do this after a server wipe! Type cmd " .. server.commandPrefix .. "yes to confirm the reset.")
			irc_chat(name, ".")

			irc_params = {}
			return true
		end
	end


	local function cmd_ResetBot()
		if displayIRCHelp then
			irc_chat(name, "Command: reset bot")
			irc_chat(name, "Make the bot forget map specific information.  Use this command after a map wipe.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "reset") and (words[2] == "bot") and (players[ircSteam].accessLevel == 0) then
			players[ircSteam].botQuestion = "reset bot"
			irc_chat(name, "ALERT! Only do this after a server wipe! Type cmd " .. server.commandPrefix .. "yes to confirm the reset.")
			irc_chat(name, ".")
			irc_params = {}
			return true
		else
			resetbotCount = 0
		end
	end


	local function cmd_StopTranslatingPlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: stop translating {player}")
			irc_chat(name, "Stop sending a player's in-game chat to Google for translating.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "stop" and words[2] == "translating" and words[3] ~= nil then
			name1 = string.sub(msg, string.find(msgLower, "translating") + 11)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= "0") then
				players[pid].ircTranslate = nil
				players[pid].translate = nil
				irc_chat(name, "Chat from " .. players[pid].name .. " will not be translated")
				irc_chat(name, ".")

				conn:execute("UPDATE players SET translate = 0, ircTranslate = 0 WHERE steam = '" .. pid .. "'")
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_TranslatePlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: translate {player}")
			irc_chat(name, "This command only works if a Linux utility called trans is installed.  It uses Google Translate so I no longer use it since I don't want to risk a huge bill from Google.  It worked great when I used to use it.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "translate" and words[2] ~= nil then
			name1 = string.sub(msg, string.find(msgLower, "translate") + 10)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= "0") then
				players[pid].translate = true
				irc_chat(name, "Chat from " .. players[pid].name .. " will be translated in-game")
				irc_chat(name, ".")

				conn:execute("UPDATE players SET translate = 1 WHERE steam = '" .. pid .. "'")
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_StealthTranslatePlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: stealth translate {player}")
			irc_chat(name, "Only translate a player's in-game chat to IRC.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "stealth" and words[2] == "translate" and words[3] ~= nil then
			name1 = string.sub(msg, string.find(msgLower, "translate") + 10)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= "0") then
				players[pid].ircTranslate = true
				irc_chat(name, "Chat from " .. players[pid].name .. " will be translated to irc only")
				irc_chat(name, ".")

				conn:execute("UPDATE players SET ircTranslate = 1 WHERE steam = '" .. pid .. "'")
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_OpenShop()
		if displayIRCHelp then
			irc_chat(name, "Command: open shop")
			irc_chat(name, "Enable the shop so player's can buy stuff and spend their hard earned {monies}.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "open" and words[2] == "shop") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			server.allowShop = true

			irc_chat(name, "Players can use the shop and play in the lottery.")
			irc_chat(name, ".")

			conn:execute("UPDATE server SET allowShop = 1")
			irc_params = {}
			return true
		end
	end


	local function cmd_CloseShop()
		if displayIRCHelp then
			irc_chat(name, "Command: close shop")
			irc_chat(name, "Disable the shop.  You'll soon see who can't live without it xD")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "close" and words[2] == "shop") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			server.allowShop = false

			irc_chat(name, "Only staff can use the shop.")
			irc_chat(name, ".")

			conn:execute("UPDATE server SET allowShop = 0")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopSetItemUnits()
		if displayIRCHelp then
			irc_chat(name, "Command: shop units {item} {new unit quantity}")
			irc_chat(name, "Change the number of units sold per sale of the specified item.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == "units" and words[3] ~= nil) then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			LookupShop(words[3])

			irc_chat(name, "You have changed the units for " .. shopItem .. " to " .. words2[4])
			irc_chat(name, ".")

			conn:execute("UPDATE shop SET units = " .. escape(tonumber(words2[4])) .. " WHERE item = '" .. escape(shopItem) .. "'")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopSetItemPrice()
		if displayIRCHelp then
			irc_chat(name, "Command: shop price {item} {new price}")
			irc_chat(name, "Change the price of an item in the shop.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == "price" and words[3] ~= nil) then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			LookupShop(words[3], true)

			if shopItem == "" then
				irc_chat(name, "The item " .. words[3] .. " does not exist.")
				irc_params = {}
				return true
			end

			irc_chat(name, "You have changed the price for " .. shopItem .. " to " .. words2[4])
			irc_chat(name, ".")

			conn:execute("UPDATE shop SET price = " .. escape(tonumber(words2[4])) .. " WHERE item = '" .. escape(shopItem) .. "'")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopSetItemQuality()
		if displayIRCHelp then
			irc_chat(name, "Command: shop quality {item} {new quality 0-6 or custom number}")
			irc_chat(name, "Change the quality of an item given when buying a specific item in the shop.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == "quality" and words[3] ~= nil) then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			LookupShop(words[3], true)

			if shopItem == "" then
				irc_chat(name, "The item " .. words[3] .. " does not exist.")
				irc_params = {}
				return true
			end

			irc_chat(name, "You have changed the quality given for " .. shopItem .. " to " .. words2[4])
			irc_chat(name, ".")

			conn:execute("UPDATE shop SET quality = " .. escape(tonumber(words2[4])) .. " WHERE item = '" .. escape(shopItem) .. "'")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopSetItemMaxStock()
		if displayIRCHelp then
			irc_chat(name, "Command: shop max {item} {max stock level}")
			irc_chat(name, "Set the maximum quantity of an item for sale in the shop.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == "max" and words[3] ~= nil) then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			LookupShop(words[3], true)

			if shopItem == "" then
				irc_chat(name, "The item " .. words[3] .. " does not exist.")
				irc_params = {}
				return true
			end

			irc_chat(name, "You have changed the max stock level for " .. shopItem .. " to " .. words[4])
			irc_chat(name, ".")

			conn:execute("UPDATE shop SET maxStock = " .. escape(tonumber(words2[4])) .. " WHERE item = '" .. escape(shopItem) .. "'")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopRestockItem()
		if displayIRCHelp then
			irc_chat(name, "Command: shop restock {item} {quantity}")
			irc_chat(name, "Increase the quantity of an item in the shop.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == "restock" and words[3] ~= nil) then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			LookupShop(wordsOld[3], true)
			shopStock = tonumber(words2[4])

			if shopItem == "" then
				irc_chat(name, "The item " .. wordsOld[3] .. " does not exist.")
				irc_params = {}
				return true
			end

			if (shopStock < 0) then
				shopStock = -1
				irc_chat(name, shopItem .. " now has unlimited stock")
			else
				irc_chat(name, "There are now " .. shopStock .. " of " .. shopItem .. " for sale.")
			end

			conn:execute("UPDATE shop SET stock = " .. escape(shopStock) .. " WHERE item = '" .. escape(shopItem) .. "'")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopAddCategory()
		if displayIRCHelp then
			irc_chat(name, "Command: shop add category {category name} code {short code}")
			irc_chat(name, "Add a new category to the shop, such as weapons.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == "add" and words[3] == "category") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			shopCategories[words[4]] = {}

			for i=2,wordCount,1 do
				if words[i] == "code" then
					shopCategories[words[4]].code  = string.sub(words[i+1], 1, 10)
					shopCategories[words[4]].index = 1

					conn:execute("INSERT INTO shopCategories (category, idx, code) VALUES ('" .. escape(words[4]) .. "',1,'" .. escape(shopCategories[words[4]].code) .. "')")
				end
			end

			if (shopCategories[words[4]].code == nil) then
				irc_chat(name, "A code is required. Do not include numbers in the code.")
				irc_params = {}
				return true
			end

			irc_chat(name, "You added the category " .. words[4] .. " with shortcode " .. shopCategories[words[4]].code .. ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopRemoveCategory()
		if displayIRCHelp then
			irc_chat(name, "Command: shop remove category {category name}")
			irc_chat(name, "Remove a category from the shop.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == "remove" and words[3] == "category") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if not shopCategories[words[4]] then
				irc_chat(name, "The category " .. words[4] .. " does not exist.")
				irc_params = {}
				return true
			end

			shopCategories[words[4]] = nil
			conn:execute("DELETE FROM shopCategories WHERE category = '" .. escape(words[4]) .. "'")
			conn:execute("UPDATE shop SET category = 'misc' WHERE category = '" .. escape(words[4]) .. "')")

			irc_chat(name, "You removed the " .. words[4] .. " category from the shop.  Any items using it are now in the misc category.")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopChangeCategory()
		if displayIRCHelp then
			irc_chat(name, "Command: shop change category {old category} to {new category}")
			irc_chat(name, "Command: shop change category {old category} to {new category} code {new code}")
			irc_chat(name, "Rename a shop category.  All of its items will move to the new category.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == "change" and words[3] == "category") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

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
				return true
			end

			shopCategories[oldCategory] = nil
			shopCategories[newCategory] = {}

			for i=2,wordCount,1 do
				if words[i] == "code" then
					shopCategories[newCategory].code  = string.sub(words[i+1], 1, 10)
				end
			end

			conn:execute("UPDATE shopCategories SET category = '" .. escape(newCategory) .. "', code = '" .. escape(shopCategories[newCategory].code) .. "' WHERE category = '" .. escape(oldCategory) .. "'")
			conn:execute("UPDATE shop SET category = '" .. escape(newCategory) .. "' WHERE category = '" .. escape(oldCategory) .. "'")
			tempTimer(2, [[loadShop()]])

			irc_chat(name, "You changed category " .. oldCategory .. " to " .. newCategory .. " using shortcode " .. shopCategories[newCategory].code .. ". Any items using " .. oldCategory .. " have been updated...")
			irc_params = {}

			return true
		end
	end


	local function cmd_ViewInventory()
		if displayIRCHelp then
			irc_chat(name, "Command: inv {player}")
			irc_chat(name, "View the current or last known inventory of a player.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "inv") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			tmp = {}
			tmp.name = name

			if words[2] == nil then
				tmp.playerID = players[ircSteam].selectedSteam
			else
				tmp.playerID = string.trim(string.sub(msg, string.find(msgLower, "inv") + 4))
				tmp.search = tmp.playerID
				tmp.playerID = LookupPlayer(tmp.playerID)
			end

			if (tmp.playerID ~= "0") then
				players[ircSteam].selectedSteam = tmp.playerID
				irc_Inventory(tmp)
			else
				irc_chat(tmp.name, "No player found matching " .. tmp.search)
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ListVillageMembers()
		local count = 0

		if displayIRCHelp then
			irc_chat(name, "Command: list villagers {name of village}")
			irc_chat(name, "List all of the village members of a specific village.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "list" and words[2] == "villagers" and words[3] ~= nil) then
			tmp.name1 = string.sub(msg, string.find(msgLower, "villagers") + 10)
			tmp.name1 = string.trim(tmp.name1)
			tmp.village = LookupVillage(tmp.name1)

			if (tmp.village ~= "0") then
				irc_chat(name, "Village " .. locations[tmp.pid].name .. " has the following members:")

				for k, v in pairs(villagers) do
					if v.village == tmp.village then
						count = count + 1
						tmp = v.village .. " " .. players[k].name

						if locations[v.village].mayor == k then
							tmp = text .. " (the mayor)"
						end

						irc_chat(name, tmp)
					end

					if count == 0 then
						irc_chat(name, locations[tmp.pid].name .. " has no members")
					end
				end
			else
				irc_chat(name, "No village found matching " .. tmp.name1)
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ListBases()
		if displayIRCHelp then
			irc_chat(name, "Command: list {optional player} bases")
			irc_chat(name, "List all of the player bases or just those of one player.")
			irc_chat(name, "Command: list bases near {x} {z} range {distance}")
			irc_chat(name, "List all of the player bases within range of a coordinate.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "list" and (words[2] == "bases" or words[3] == "bases") then
			if (players[ircSteam].accessLevel > 2) then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			pid = "0"
			if words[2] ~= "bases" then
				pid = string.sub(msg, 6, string.find(msgLower, " bases") - 1)
			end

			if words[1] == "list" and words[2] == "bases" and words[3] == "near" then
				irc_params.x = tonumber(words[4])
				irc_params.z = tonumber(words[5])
				irc_params.range = tonumber(words[7])
			end

			if pid ~= "0" then
				pid = LookupPlayer(pid)
			end

			irc_ListBases(pid)
			irc_params = {}
			return true
		end
	end


	local function cmd_ListBeds()
		if displayIRCHelp then
			irc_chat(name, "Command: list beds {optional player}")
			irc_chat(name, "List all of the player beds or just that of one player.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "list" and words[2] == "beds" then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			pid = "0"
			if words[3] then
				pid = words[3]
			end

			if pid ~= "0" then
				pid = LookupPlayer(pid)
			end

			irc_ListBeds(pid)
			irc_params = {}
			return true
		end
	end


	local function cmd_AddBadItem()
		if displayIRCHelp then
			irc_chat(name, "Command: add bad item {item name} action {exile, ban or timeout} (timeout is the default)")
			irc_chat(name, "Add an item to the bad items list.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "add" and words[2] == "bad" and words[3] == "item" and words[4] ~= nil and players[ircSteam].accessLevel == 0) then
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
			return true
		end
	end


	local function cmd_RemoveBadItem()
		if displayIRCHelp then
			irc_chat(name, "Command: remove bad item {item name}")
			irc_chat(name, "Remove an item from the bad items list.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "remove" and words[2] == "bad" and words[3] == "item" and words[4] ~= nil and players[ircSteam].accessLevel == 0) then
			name1 = wordsOld[4]

			if not badItems[name1] then
				irc_chat(name, name1 .. " has already been removed or you typed the name wrong (case sensitive).")
				irc_params = {}
				return true
			end

			-- remove the bad item from the badItems table
			badItems[name1] = nil

			conn:execute("DELETE FROM badItems WHERE item = '" .. escape(name1) .. "'")

			irc_chat(name, name1 .. " has been removed from the bad items list.")
			irc_chat(name, ".")

			irc_params = {}
			return true
		end
	end


	local function cmd_EditBadItem()
		if displayIRCHelp then
			irc_chat(name, "Command: bad item {item name} action {exile, ban or timeout}")
			irc_chat(name, "Change what the bot does when it detects a specific bad item in inventory.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "bad" and words[2] == "item" and words[3] ~= nil and players[ircSteam].accessLevel == 0) then
			name1 = wordsOld[3]

			if not badItems[name1] then
				irc_chat(name, name1 .. " is not in the list of bad items.")
				irc_params = {}
				return true
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
			return true
		end
	end


	local function cmd_DeleteOldLogs()
		if displayIRCHelp then
			irc_chat(name, "Command: delete old logs")
			irc_chat(name, "This should happen daily but if for some reason logs are not being trimmed, you can make the bot delete old logs. Mainly useful if the daily maintenance not completing for some reason.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "delete" and words[2] == "old" and words[3] == "logs" and players[ircSteam].accessLevel == 0) then
			irc_chat(name, "Deleting older bot logs..")
			os.execute("find " .. homedir .. "/telnet_logs/* -mtime +" .. server.telnetLogKeepDays .. " -exec rm {} \\;")

			-- delete other old logs
			os.execute("find " .. botman.chatlogPath .. "/*inventory.txt -mtime +" .. server.telnetLogKeepDays .. " -exec rm {} \\;")
			os.execute("find " .. botman.chatlogPath .. "/*botcommandlog.txt -mtime +7 -exec rm {} \\;")
			os.execute("find " .. botman.chatlogPath .. "/*commandlog.txt -mtime +90 -exec rm {} \\;")
			os.execute("find " .. botman.chatlogPath .. "/*alertlog.txt -mtime +90 -exec rm {} \\;")
			os.execute("find " .. botman.chatlogPath .. "/*panel.txt -mtime +30 -exec rm {} \\;")

			irc_chat(name, "Older bot logs have been deleted. Some are kept for " .. server.telnetLogKeepDays .. " days. Others are deleted after 30, 60 or 90 days. Player chat logs are never deleted.")
			irc_chat(name, ".")

			irc_params = {}
			return true
		end
	end


	local function cmd_NearPlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: near player {player}")
			irc_chat(name, "Lists players, bases and locations near a player or coordinate.")
			irc_chat(name, "Usage: near player {name}")
			irc_chat(name, "optional: range {number}")
			irc_chat(name, "optional: Instead of player use xpos {number} zpos {number}")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "near") and (words[2] ~= "entity") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if words[2] == nil then
				irc_chat(name, "Lists players, bases and locations near a player or coordinate.")
				irc_chat(name, "Usage: near player {name}")
				irc_chat(name, "optional: range {number}")
				irc_chat(name, "optional: Instead of player use xpos {number} zpos {number}")

			end

			name1 = "0"
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

			if name1 ~= "0" then
				name1 = string.trim(name1)
				name1 = LookupPlayer(name1)

				if name1 == "0" then
					irc_chat(name, "No player found matching " .. name1)
					irc_params = {}
					return true
				end
			end

			if name1 == "0" then
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
			return true
		end
	end


	local function cmd_PlayerInfo()
		if displayIRCHelp then
			irc_chat(name, "Command: info {player}")
			irc_chat(name, "View info about a player including links to some 7 Days related websites and the player's DNS record.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "info") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if words[2] == nil then
				pid = players[ircSteam].selectedSteam
			else
				name1 = string.sub(msg, string.find(msgLower, "info") + 5)
				name1 = string.trim(name1)
				pid = LookupPlayer(name1)
			end

			if (pid ~= "0") then
				players[ircSteam].selectedSteam = pid
				irc_params.player = players[pid]
				irc_params.pid = pid
				irc_params.pname = players[pid].name

				irc_PlayerShortInfo()
				irc_friends()
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_AddDonor()
		if displayIRCHelp then
			irc_chat(name, "Command: add donor {player} expires {number} week or month or year")
			irc_chat(name, "Give a player donor status.  They get a few special privileges but it is not play to win.  There are no game items included.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "add" and words[2] == "donor" and words[3] ~= nil) then
			if admin and adminLevel == 0 then
				if string.find(msgLower, "expires") then
					tmp.name1 = string.sub(msg, string.find(msgLower, "donor") + 6, string.find(msgLower, "expires") - 2)
					tmp.expiry = string.sub(msg, string.find(msgLower, "expires") + 7)
					tmp.expiry = calcTimestamp(tmp.expiry)
				else
					tmp.name1 = string.sub(msg, string.find(msgLower, "donor") + 6)
					tmp.expiry = calcTimestamp("10 years")
				end

				if not tmp.expiry then
					irc_chat(name, "Invalid expiry entered or missing.")
					return true
				end

				tmp.name1 = string.trim(tmp.name1)
				tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.name1)

				if tmp.steam ~= "0" then
					cursor,errorString = conn:execute("INSERT INTO donors (steam, name, level, expiry, expired) VALUES ('" .. tmp.steam .. "','" .. escape(players[tmp.steam].name) .. "',1," .. tmp.expiry .. ", 0)")

					if errorString then
						if string.find(errorString, "Duplicate entry") then
							cursor,errorString = conn:execute("UPDATE donors SET level = 1, expiry = " .. tmp.expiry .. ", expired=0, name = '" .. escape(players[tmp.steam].name) .. "' WHERE steam = '" .. tmp.steam .. "'")
						end
					end

					loadDonors()

					-- also add them to the bot's whitelist
					whitelist[tmp.steam] = {}
					players[tmp.steam].maxWaypoints = server.maxWaypointsDonors

					if botman.dbConnected then
						conn:execute("INSERT INTO whitelist (steam) VALUES ('" .. tmp.steam .. "')")
						conn:execute("UPDATE players SET maxWaypoints = " .. server.maxWaypointsDonors .. " WHERE steam = '" .. tmp.steam .. "'")
					end

					-- create or update the donor record on the shared database
					cursor,errorString = connBots:execute("INSERT INTO donors (donor, donorExpiry, steam, botID, serverGroup) VALUES (1, " .. tmp.expiry .. ", '" .. tmp.steam .. "'," .. server.botID .. ",'" .. escape(server.serverGroup) .. "')")

					if string.find(errorString, "Duplicate entry") then
						connBots:execute("UPDATE donors SET donor = 1, donorExpiry = " .. tmp.expiry .. ", serverGroup = '" .. escape(server.serverGroup) ..  "' WHERE steam = '" .. tmp.steam .. "' AND botID = " .. server.botID)
					end

					if igplayers[tmp.steam] then
						message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]You have been given donor privileges until " .. os.date("%d-%b-%Y",  tmp.expiry) .. ". Thank you for being awesome! =D[-]")
					end

					irc_chat(server.ircMain, players[tmp.steam].name .. " donor status expires on " .. os.date("%d-%b-%Y",  tmp.expiry))
				end

				irc_params = {}
				return true
			end
		end
	end


	local function cmd_RemoveDonor()
		if displayIRCHelp then
			irc_chat(name, "Command: remove donor {player}")
			irc_chat(name, "Remove a player's donor status.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "remove" and words[2] == "donor" and words[3] ~= nil) then
			if admin and adminLevel == 0 then
				name1 = string.sub(msg, string.find(msgLower, "donor") + 6)
				name1 = string.trim(name1)
				pid = LookupPlayer(name1)

				if pid ~= "0" then
					removeDonor(pid)

					-- reload bases from the database
					tempTimer( 3, [[loadBases()]] )

					-- reload donors from the database
					tempTimer( 3, [[loadDonors()]] )
				else
					irc_chat(name, name1 .. " did not match a player.")
				end

				irc_params = {}
				return true
			end
		end
	end


	local function cmd_AddOwner()
		local status, errorString

		if displayIRCHelp then
			irc_chat(name, "Command: add owner {player}")
			irc_chat(name, "Give a player owner status which is the highest admin status in the bot and server.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "add" and words[2] == "owner" and words[3] ~= nil) then
			if admin and adminLevel == 0 then
				name1 = string.sub(msg, string.find(msgLower, "owner") + 6)
				name1 = string.trim(name1)
				pid = LookupPlayer(name1)

				if pid ~= "0" then
					-- add the steamid to the staffList table
					staffList[pid] = {}
					staffList[pid].adminLevel = 0

					if botman.dbConnected then
						status, errorString = conn:execute("INSERT INTO staff (steam, userID, adminLevel) VALUES ('" .. pid .. "','" .. escape(userID) .. "', 0)")

						if not status then
							if string.find(errorString, "Duplicate entry") then
								conn:execute("UPDATE staff SET adminLevel = 0 WHERE steam = '" .. pid .. "'")
							end
						end
					end

					irc_chat(name, players[pid].name .. " has been added as a server owner.")
					irc_chat(name, ".")

					sendCommand("admin add Steam_" .. pid .. " 0")
				end

				irc_params = {}
				return true
			end
		end
	end


	local function cmd_RemoveOwner()
		if displayIRCHelp then
			irc_chat(name, "Command: remove owner {player}")
			irc_chat(name, "Remove an owner so they are just a regular player.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "remove" and words[2] == "owner" and words[3] ~= nil) then
			if admin and adminLevel == 0 then
				name1 = string.sub(msg, string.find(msgLower, "owner") + 6)
				name1 = string.trim(name1)
				steam, steamOwner, userID = LookupPlayer(name1)

				if steam ~= "0" then
					-- remove the steamid to the staffList table
					staffList[steam] = nil
					if botman.dbConnected then conn:execute("DELETE FROM staff WHERE steam = '" .. steam .. "'") end

					irc_chat(name, players[steam].name .. " is no longer a server owner.")
					irc_chat(name, ".")

					sendCommand("admin remove Steam_" .. steam)
					sendCommand("admin remove " .. userID)
				end

				irc_params = {}
				return true
			end
		end
	end


	local function cmd_AddAdmin()
		local status, errorString

		if displayIRCHelp then
			irc_chat(name, "Command: add admin {player}")
			irc_chat(name, "Give a player admin status.   Note:  This gives them level 1 admin status only.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "add" and words[2] == "admin" and words[3] ~= nil) then
			if admin and adminLevel == 0 then
				name1 = string.sub(msg, string.find(msgLower, "admin") + 6)
				name1 = string.trim(name1)
				steam, steamOwner, userID = LookupPlayer(name1)

				if steam ~= "0" then
					-- add the steamid to the staffList table
					staffList[steam] = {}
					staffList[steam].adminLevel = 1

					if botman.dbConnected then
						status, errorString = conn:execute("INSERT INTO staff (steam, userID, adminLevel) VALUES ('" .. steam .. "','" .. escape(userID) .. "', 1)")

						if not status then
							if string.find(errorString, "Duplicate entry") then
								conn:execute("UPDATE staff SET adminLevel = 1 WHERE steam = '" .. steam .. "'")
							end
						end
					end

					irc_chat(name, players[steam].name .. " has been added as a server admin.")
					irc_chat(name, ".")

					sendCommand("admin add Steam_" .. steam .. " 1")
				end

				irc_params = {}
				return true
			end
		end
	end


	local function cmd_RemoveAdmin()
		local tmp = {}

		if displayIRCHelp then
			irc_chat(name, "Command: remove admin {player}")
			irc_chat(name, "OUT!  Remove an admin.  They become a player again.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "remove" and words[2] == "admin" and words[3] ~= nil and players[ircSteam].accessLevel == 0) then
			tmp.name1 = string.sub(msg, string.find(msgLower, "admin") + 6)
			tmp.name1 = string.trim(tmp.name1)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.name1)

			if tmp.steam ~= "0" then
				-- remove the steamid to the staffList table
				staffList[tmp.steam] = nil

				if botman.dbConnected then
					conn:execute("DELETE FROM staff WHERE steam = '" .. tmp.steam .. "'")
					conn:execute("DELETE FROM staff WHERE userID = '" .. tmp.userID .. "'")
				end

				irc_chat(name, players[tmp.steam].name .. " is no longer a server admin.")
				irc_chat(name, ".")

				sendCommand("admin remove EOS_" .. tmp.userID)
				sendCommand("admin remove Steam_" .. tmp.steam)

				tempTimer(2, [[loadStaff()]])
			else
				if tmp.name1 ~= "0" then
					-- remove the steamid to the staffList table
					staffList[tmp.name1] = nil

					if botman.dbConnected then
						conn:execute("DELETE FROM staff WHERE steam = '" .. tmp.name1 .. "'")
						conn:execute("DELETE FROM staff WHERE userID = '" .. tmp.userID .. "'")
					end

					irc_chat(name, tmp.name1 .. " is no longer a server admin.")
					irc_chat(name, ".")

					sendCommand("admin remove EOS_" .. tmp.userID)
					sendCommand("admin remove Steam_" .. tmp.name1)

					tempTimer(2, [[loadStaff()]])
				end
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_AddPermaban()
		if displayIRCHelp then
			irc_chat(name, "Command: permaban {jackass}")
			irc_chat(name, "Ban and permanban a player. Not currently used by the bot, but the ban works.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "permaban") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "permaban") + 9))
			steam, steamOwner, userID, platform = LookupPlayer(name1)

			if (steam ~= "0") then
				banPlayer(platform, userID, steam, "10 years", "Permanent ban", ircSteam)

				irc_chat(name, name1 .. " has been banned for 10 years.")
				irc_chat(name, ".")

				conn:execute("UPDATE players SET permanentBan = 1 WHERE steam = '" .. steam .. "'")
				players[steam].permanentBan = true
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_RemovePermaban()
		if displayIRCHelp then
			irc_chat(name, "Command: remove permaban {player}")
			irc_chat(name, "Unban a player and remove their permaban status. Not currently used by the bot, but it will unban them.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "remove" and words[2] == "permaban") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "permaban") + 9))
			steam, steamOwner, userID = LookupPlayer(name1)

			if (steam ~= "0") then
				conn:execute("UPDATE players SET permanentBan = 0 WHERE steam = '" .. steam .. "'")
				sendCommand("ban remove Steam_" .. steam)
				sendCommand("ban remove " .. userID)
				players[steam].permanentBan = false
				irc_chat(name, "Ban lifted for player " .. name1)
				irc_chat(name, ".")
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_SetIRCLogin()
		if displayIRCHelp then
			irc_chat(name, "Command: add player {player} login {name} pass {password}")
			irc_chat(name, "Authorise a player to login to the bot here on IRC.  They can login with login {name} pass {password}.  They must not use that in any public channels, only in private with the bot or the bot will destroy their login.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "add" and words[2] == "player") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

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
			if (pid ~= "0") then
				players[pid].ircLogin = tmp.login
				players[pid].ircPass = tmp.pass

				irc_chat(name, players[pid].name .. " is now authorised to talk to ingame players")
				irc_chat(name, ".")

				conn:execute("UPDATE players SET ircLogin = '" .. escape(tmp.login) .. "', ircPass = '" .. escape(tmp.pass) .. "' WHERE steam = '" .. pid .. "'")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_UnfriendPlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: player {player one} unfriend {player two}")
			irc_chat(name, "Make a player no longer friends with another player.  Does not change friend status done through the game's own friend system.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "player" and string.find(msgLower, "unfriend")) then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, "unfriend") - 1))
			name2 = string.trim(string.sub(msg, string.find(msgLower, "unfriend") + 9))

			pid = LookupPlayer(name1)
			if (pid ~= "0") then
				irc_params.pid = pid
				pid = LookupPlayer(name2)
				if (pid ~= "0") then
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
			return true
		end
	end


	local function cmd_FriendPlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: player {player one} friend {player two}")
			irc_chat(name, "Make friends.  No not you!  Make a player friends with another player.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "player" and string.find(msgLower, "friend")) then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, "friend") - 1))
			name2 = string.trim(string.sub(msg, string.find(msgLower, "friend") + 7))

			pid = LookupPlayer(name1)
			if (pid ~= "0") then
				irc_params.pid = pid
				pid = LookupPlayer(name2)
				if (pid ~= "0") then
					irc_params.pid2 = pid
					irc_friend() -- say hello to my little friend
				else
					irc_chat(name, "No player found matching " .. name2)
					irc_chat(name, ".")
				end
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ListPlayersFriends()
		if displayIRCHelp then
			irc_chat(name, "Command: friends {player}")
			irc_chat(name, "View all of the friends of a player known to the bot or the game.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "friends") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "friends") + 8))
			pid = LookupPlayer(name1)

			if (pid ~= "0") then
				irc_params.pid = pid
				irc_params.pname = players[pid].name
				irc_friends() -- shortlist
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ListPlayers()
		if displayIRCHelp then
			irc_chat(name, "Command: players {optional player name}")
			irc_chat(name, "Get a list of all of the players or a specific player (except archived players).")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "players") and admin then
			if words[2] ~= nil then
				irc_params.pname = string.sub(msg, 9)
			end

			irc_listAllPlayers(name)
			irc_params = {}
			return true
		end
	end


	local function cmd_ListArchivedPlayers()
		if displayIRCHelp then
			irc_chat(name, "Command: archived players {optional player name}")
			irc_chat(name, "Get a list of all the players that have been archived or a specific player.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "archived" and words[2] == "players" and admin then
			if words[3] ~= nil then
				irc_params.pname = string.sub(msg, 18)
			end

			irc_listAllArchivedPlayers(name)
			irc_params = {}
			return true
		end
	end


	local function cmd_ViewPlayerRecord()
		if displayIRCHelp then
			irc_chat(name, "Command: player {name}")
			irc_chat(name, "Command: player {name} find {search string}")
			irc_chat(name, "View the permanent record for a player or you can just list specific info using find.  eg player smegz find home.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "player") then
			tmp = {}

			if not string.find(msgLower, " find ") then
				tmp.name = string.trim(string.sub(msg, string.find(msgLower, "player") + 7))
				tmp.search = ""
			else
				tmp.name = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, " find ") - 1))
				tmp.search = string.trim(string.sub(msg, string.find(msgLower, " find ") + 6))
				tmp.search = string.lower(tmp.search)
			end

			tmp.pid = LookupOfflinePlayer(tmp.name)

			if (tmp.pid ~= "0") then
				if (players[tmp.pid]) then
					tmp.player = players[tmp.pid]
					tmp.row = sortTable(tmp.player)

					irc_chat(name, "Player record of: " .. tmp.pid .. " " .. players[tmp.pid].name)
					for k, v in ipairs(tmp.row) do
						tmp.cmd = ""

						if v ~= "ircPass" then
							if tmp.search ~= "" then
								if string.find(string.lower(v), tmp.search) then
									tmp.value = tostring(tmp.player[v])

									if tmp.player.groupID ~= 0 and v ~= "name" then
										tmp.value = tostring(LookupSettingValue(tmp.pid, v))
									end

									tmp.cmd = v .. ", " .. tmp.value
								end
							else
								tmp.value = tostring(tmp.player[v])

								if tmp.player.groupID ~= 0 and v ~= "name" then
									tmp.value = tostring(LookupSettingValue(tmp.pid, v))
								end

								tmp.cmd = v .. ", " .. tmp.value
							end

							if tmp.cmd ~= "" then
								irc_chat(name, tmp.cmd)
							end
						end
					end
				else
					irc_chat(name, ".")
					irc_chat(name, "I do not know a player called " .. tmp.name)
				end

				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ViewShadowCopyPlayerRecord()
		if displayIRCHelp then
			irc_chat(name, "Command: sqlplayer {name}")
			irc_chat(name, "Command: sqlplayer {name} find {search string}")
			irc_chat(name, "View the shadow copy of a player record in the SQLite database (tables.sqlite) or you can just list specific info using find.  eg sqlplayer smegz find home.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "sqlplayer") then
			tmp = {}

			if not string.find(msgLower, " find ") then
				tmp.name = string.trim(string.sub(msg, string.find(msgLower, "player") + 7))
				tmp.search = ""
			else
				tmp.name = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, " find ") - 1))
				tmp.search = string.trim(string.sub(msg, string.find(msgLower, " find ") + 6))
				tmp.search = string.lower(tmp.search)
			end

			tmp.pid = LookupOfflinePlayer(tmp.name)

			if (tmp.pid ~= "0") then
				if (players[tmp.pid]) then
					irc_chat(name, "Player record of: " .. tmp.pid .. " " .. players[tmp.pid].name)

					cursor,errorString = connSQL:execute("SELECT * FROM players WHERE steam = '" .. tmp.pid .. "'")
					row = cursor:fetch({}, "a")

					if row then
						tmp.row = sortTable(row)

						for k,v in ipairs(tmp.row) do
							tmp.cmd = ""

							if k ~= "ircPass" then
								tmp.fieldType = playerFields[v].type
								tmp.value = row[v]

								if tmp.fieldType == "tin" then
									if row[v] == 0 then
										tmp.value = "false"
									else
										tmp.value = "true"
									end
								end

								if tmp.fieldType == "var" or tmp.fieldType == "big" then
									tmp.value = tostring(row[v])
								end

								if tmp.search ~= "" then
									if string.find(string.lower(v), tmp.search) then
										tmp.cmd = v .. ", " .. tmp.value
									end
								else
									tmp.cmd = v .. ", " .. tmp.value
								end

								if tmp.cmd ~= "" then
									irc_chat(name, tmp.cmd)
								end
							end
						end
					end
				else
					irc_chat(name, ".")
					irc_chat(name, "I do not know a player called " .. tmp.name)
				end

				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ViewArchivedPlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: archived player {name}")
			irc_chat(name, "Command: archived player {name} find {search string}")
			irc_chat(name, "View the permanent record for an archived player or you can just list specific info using find.  eg archived player smegz find home.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "archived" and words[2] == "player" then
			if not string.find(msgLower, " find ") then
				name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7))
				search = ""
			else
				name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, " find ") - 1))
				search = string.trim(string.sub(msg, string.find(msgLower, " find ") + 6))
				search = string.lower(search)
			end

			pid = LookupArchivedPlayer(name1)

			if (pid ~= "0") then
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
			return true
		end
	end


	local function cmd_ViewInGamePlayerRecord()
		if displayIRCHelp then
			irc_chat(name, "Command: igplayer {name}")
			irc_chat(name, "Command: igplayer {name} find {search string}")
			irc_chat(name, "View the bot's record for a player that is currently on the server.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "igplayer") then
			if not string.find(msgLower, " find ") then
				name1 = string.trim(string.sub(msg, string.find(msgLower, "igplayer") + 9))
				search = ""
			else
				name1 = string.trim(string.sub(msg, string.find(msgLower, "igplayer") + 9, string.find(msgLower, " find ") - 1))
				search = string.trim(string.sub(msg, string.find(msgLower, " find ") + 6))
				search = string.lower(search)
			end

			pid = LookupPlayer(name1)

			if (pid ~= "0") then
				irc_params.pid = pid
				irc_params.pname = players[pid].name
				irc_params.search = search
				irc_IGPlayerInfo()
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ListInGamePlayers()
		if displayIRCHelp then
			irc_chat(name, "Command: igplayers")
			irc_chat(name, "View the bot's record for each player that is currently on the server.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "igplayers" and words[2] == nil) then

			for k,v in pairs(igplayers) do
				irc_params.pid = k
				irc_params.pname = players[k].name
				irc_IGPlayerInfo()
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end

		if (words[1] == "igplayers" and words[2] ~= nil) then
			for k,v in pairs(igplayers) do
				irc_chat(irc_params.name, "steam, " .. v.steam .. " id," .. v.id .. " name," .. v.name .. " connected," .. tostring(v.connected) .. " killTimer," .. v.killTimer)
			end

			irc_chat(name, ".")
			return true
		end
	end


	local function cmd_WhoShortList()
		local status

		if displayIRCHelp then
			irc_chat(name, "Command: whos")
			irc_chat(name, "View compact list of players on server now.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "whos" and words[2] == nil) then
			irc_chat(name, "in game player (short list):")

			index = 1

			for k,v in pairs(igplayers) do
				status = " "

				if isAdminHidden(k, v.userID) then
					status = status .. "[ADMIN]"
				end

				if players[k].newPlayer then
					status = status .. "[NEW]"
				end

				if players[k].timeout then status = status .. "[TIMEOUT]" end
				if players[k].prisoner then status = status .. "[PRISONER]" end

				if isDonor(k) then
					status = status .. "[DONOR]"
				end

				irc_params.pname = players[k].name
				irc_chat(name, "#" .. index .. " " .. v.name .. " id " .. v.id .. " " .. v.platform .. " " .. k .. " " .. v.userID .. status)
				index = index + 1
			end

			irc_chat(irc_params.name, "There are " .. botman.playersOnline .. " players online.")
			irc_chat(name, ".")

			irc_params = {}
			return true
		end
	end


	local function cmd_Whom()
		if (words[1] == "whom" and words[2] == nil) then
			irc_chat(name, "Custom who command help:")

			irc_chat(irc_params.name, "List players online right now and specify what you want included.")
			irc_chat(irc_params.name, "eg. whom level score zeds.")
			irc_chat(irc_params.name, "Game id, steam, name, and EOS id are always included.")
			irc_chat(irc_params.name, "To use, type whom followed by any of the following list..")
			irc_chat(irc_params.name, "group, rank, level, score, zombies, playerkills, deaths, region, ping, hacker, location, coords")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "whom") then
			irc_chat(name, "In-game player (short list):")

			index = 1
			tmp = {}
			tmp.display = {}
			tmp.key = "Key: index | game id | steam | name | EOS"

			for i=2,wordCount,1 do
				if words2[i] == "group" then
					table.insert(tmp.display, "group")
					tmp.key = tmp.key .. " | group"
				end

				if words2[i] == "level" then
					table.insert(tmp.display, "level")
					tmp.key = tmp.key .. " | level"
				end

				if words2[i] == "rank" then
					table.insert(tmp.display, "rank")
					tmp.key = tmp.key .. " | rank"
				end

				if words2[i] == "score" then
					table.insert(tmp.display, "score")
					tmp.key = tmp.key .. " | score"
				end

				if words2[i] == "zombies" then
					table.insert(tmp.display, "zombies")
					tmp.key = tmp.key .. " | zeds"
				end

				if words2[i] == "playerkills" then
					table.insert(tmp.display, "playerKills")
					tmp.key = tmp.key .. " | kills"
				end

				if words2[i] == "deaths" then
					table.insert(tmp.display, "deaths")
					tmp.key = tmp.key .. " | deaths"
				end

				if words2[i] == "region" then
					table.insert(tmp.display, "region")
					tmp.key = tmp.key .. " | region"
				end

				if words2[i] == "hacker" then
					table.insert(tmp.display, "hacker")
					tmp.key = tmp.key .. " | hacker score"
				end

				if words2[i] == "ping" then
					table.insert(tmp.display, "ping")
					tmp.key = tmp.key .. " | ping"
				end

				if words2[i] == "coords" then
					table.insert(tmp.display, "coords")
					tmp.key = tmp.key .. " | coords"
				end

				if words2[i] == "location" then
					table.insert(tmp.display, "location")
					tmp.key = tmp.key .. " | location"
				end
			end


			irc_chat(name, tmp.key)

			for k,v in pairs(igplayers) do
				irc_params.pid = k
				irc_params.pname = players[k].name

				if v.platform ~= "Steam" then
					tmp.output = "#" .. index .. " | " .. v.id .. " | " .. v.platform .. " " .. k .. " | " .. v.name .. " | " .. v.userID
				else
					tmp.output = "#" .. index .. " | " .. v.id .. " | " .. k .. " | " .. v.name .. " | " .. v.userID
				end

				for a,b in pairs(tmp.display) do
					if b == "score" then
						tmp.output = tmp.output .. " | " .. v.score
					end

					if b == "zombies" then
						tmp.output = tmp.output .. " | " .. v.zombies
					end

					if b == "playerkills" then
						tmp.output = tmp.output .. " | " .. v.playerKills
					end

					if b == "deaths" then
						tmp.output = tmp.output .. " | " .. v.deaths
					end

					if b == "ping" then
						tmp.output = tmp.output .. " | " .. v.ping
					end

					if b == "coords" then
						tmp.output = tmp.output .. " | @ " .. v.xPos .. " " .. v.yPos .. " " .. v.zPos
					end

					if b == "location" then
						tmp.output = tmp.output .. " | " .. v.inLocation
					end

					if b == "region" then
						tmp.output = tmp.output .. " | " .. v.region
					end

					if b == "hacker" then
						tmp.output = tmp.output .. " | " .. players[k].hackerScore
					end

					if b == "rank" then
						tmp.rank = ""

						if isAdminHidden(k, v.userID) then
							tmp.rank = tmp.rank .. "[ADMIN]"
						end

						if isDonor(k) then
							tmp.rank = tmp.rank .. "[DONOR]"
						end

						if players[k].newPlayer then
							tmp.rank = tmp.rank .. "[NEW]"
						end

						if tonumber(players[k].hackerScore) > 0 then
							tmp.rank = tmp.rank .. "[HACKER]"
						end

						if v.flying then
							tmp.rank = tmp.rank .. "[FLYING " .. v.flyingHeight .. "]"
						end

						if v.flying then
							tmp.rank = tmp.rank .. "[NOCLIP]"
						end

						tmp.output = tmp.output .. " | " .. tmp.rank
					end

					if b == "group" then
						if players[k].groupID == 0 then
							tmp.output = tmp.output .. " | No Group"
						else
							tmp.output = tmp.output .. " | " .. playerGroups["G" .. players[k].groupID].name
						end
					end
				end

				irc_chat(name, tmp.output)
				index = index + 1
			end

			irc_chat(irc_params.name, "There are " .. botman.playersOnline .. " players online.")
			irc_chat(name, ".")

			irc_params = {}
			return true
		end
	end


	local function cmd_WatchPlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: watch {player}")
			irc_chat(name, "")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "watch") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "watch") + 6))
			pid = LookupPlayer(name1)

			if (pid ~= "0") then
				players[pid].watchPlayer = true

				conn:execute("UPDATE players SET watchPlayer = 1 WHERE steam = '" .. pid .. "'")

				irc_chat(name, "Now watching player " .. players[pid].name)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_StopWatchingPlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: stop watching {player}")
			irc_chat(name, "Stop getting in-game messages about a player every time their inventory changes or they get too close to a base.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "stop" and words[2] == "watching") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "watching") + 9))
			pid = LookupPlayer(name1)

			if (pid ~= "0") then
				players[pid].watchPlayer = false

				conn:execute("UPDATE players SET watchPlayer = 0 WHERE steam = '" .. pid .. "'")

				irc_chat(name, "No longer watching player " .. players[pid].name)
				irc_chat(name, ".")
			else
				irc_chat(name, "No player matched " .. name1)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ListDonors()
		if displayIRCHelp then
			irc_chat(name, "Command: donors {optional player name}")
			irc_chat(name, "List all of the donors or a specific donor.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "donors") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			tmp = {}
			tmp.count = 0
			tmp.name = ""

			connMEM:execute("DELETE FROM list WHERE steam = '" .. ircSteam .. "'")

			if words[2] == nil then
				irc_chat(name, "These are all the donors on record:")

				for k,v in pairs(donors) do
					if v.name then
						name1 = v.name
					else
						name1 = "*** name unknown ***"
					end

					if players[k] then
						if players[k].name then
							name1 = players[k].name
						else
							name1 = "*** name unknown ***"
						end
					end

					if playersArchived[k] then
						name1 = playersArchived[k].name
					end

					connMEM:execute("INSERT INTO list (thing, class, steam) VALUES ('" .. connMEM:escape(name1) .. "','" .. k .. "','" .. ircSteam .. "')")
					tmp.count = tmp.count + 1
				end

				cursor,errorString = connMEM:execute("SELECT * FROM list WHERE steam = '" .. ircSteam .. "' ORDER BY thing")
				row = cursor:fetch({}, "a")

				while row do
					tmp.steam = row.class
					tmp.name = row.thing
					tmp.id = "n/a"
					tmp.cash = 0
					tmp.days = 0
					tmp.hours = 0
					tmp.minutes = 0

					tmp.days, tmp.hours, tmp.minutes = timestampToString(donors[tmp.steam].expiry)

					if players[tmp.steam] then
						tmp.id = players[tmp.steam].id
						tmp.cash = players[tmp.steam].cash
					end

					if tonumber(tmp.days) < 0 then
						irc_chat(name, "steam: " .. tmp.steam .. " id: " .. tmp.id .. " name: " .. tmp.name .. " cash " .. tmp.cash .. " *** expired ***")
					else
						irc_chat(name, "steam: " .. tmp.steam .. " id: " .. tmp.id .. " name: " .. tmp.name .. " cash " .. tmp.cash .. " expires in " .. tmp.days .. " days " .. tmp.hours .. " hours " .. tmp.minutes .." minutes")
					end

					row = cursor:fetch(row, "a")
				end

				connMEM:execute("DELETE FROM list WHERE steam = '" .. ircSteam .. "'")

				irc_chat(name, "Total donors: " .. tmp.count)
			else
				tmp.name = string.sub(msg, 8)
				tmp.steam = LookupPlayer(tmp.name)
				tmp.days = 0
				tmp.hours = 0
				tmp.minutes = 0

				if players[tmp.steam] then
					irc_chat(name, "Donor record of " .. tmp.name .. ":")

					tmp.days, tmp.hours, tmp.minutes = timestampToString(donors[tmp.steam].expiry)

					if tonumber(tmp.days) < 0 then
						irc_chat(name, "steam: " .. tmp.steam .. " id: " .. players[tmp.steam].id .. " name: " .. players[tmp.steam].name .. " cash " .. string.format("%d", players[tmp.steam].cash) .. " *** expired ***")
					else
						irc_chat(name, "steam: " .. tmp.steam .. " id: " .. players[tmp.steam].id .. " name: " .. players[tmp.steam].name .. " cash " .. string.format("%d", players[tmp.steam].cash) .. " expires in " .. tmp.days .. " days " .. tmp.hours .. " hours " .. tmp.minutes .." minutes")
					end
				else
					irc_chat(name, "No player found like " .. tmp.name)
				end
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ListTeleports()
		if displayIRCHelp then
			irc_chat(name, "Command: teleports")
			irc_chat(name, "List all of the teleports.  These are not locations or waypoints.  They are special teleports that players step onto in-game to get automatically teleported somewhere.")
			irc_chat(name, ".")
			return
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
			return true
		end
	end


	local function cmd_ListBadItems()
		if displayIRCHelp then
			irc_chat(name, "Command: list bad items")
			irc_chat(name, "")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "list" and words[2] == "bad" and words[3] == "items") then
			irc_chat(name, "I scan for these bad items in inventory:")

			for k, v in pairs(badItems) do
				irc_chat(name, k .. " -> " .. v.action)
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ListPrisoners()
		if displayIRCHelp then
			irc_chat(name, "Command: prisoners")
			irc_chat(name, "List all of the current prisoners. If a reason was recorded, that will be shown too.")
			irc_chat(name, ".")
			return
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

					if v.pvpVictim == "0" then
						irc_chat(name, k .. " " .. players[k].name .. " " .. tmp.reason)
					else
						irc_chat(name, k .. " " .. players[k].name .. " PVP " .. players[v.pvpVictim].name .. " " .. v.pvpVictim)
					end
				end
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ListAllItems()
		if displayIRCHelp then
			irc_chat(name, "Command: list all items")
			irc_chat(name, "This command generates a text file called items.txt which you will find in the temp folder of your bot's daily logs folder.")
			irc_chat(name, "It will have every item known to your server which you can use as a handy guide when adding items to your shop etc.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "list" and words[2] == "all" and words[3] == "items") then
			if server.useAllocsWebAPI then
				irc_chat(name, "Generating items.txt in the logs folder " .. botman.chatlogPath:match("([^/]+)$") .. "/lists")
				botman.exportItemsList = true
				sendCommand("li *")
			else
				irc_chat(name, "The bot must be in API mode to use this command. It is currently in telnet mode.")
				irc_chat(name, "To see if your bot can use Alloc's web API type map, then see if the map url that appears loads a page. If it does, you can type use api, then type list all items.")
			end

			irc_params = {}

			return true
		end
	end


	local function cmd_ListAllEntities()
		if displayIRCHelp then
			irc_chat(name, "Command: list all entities")
			irc_chat(name, "This command generates a text file called entities.txt which you will find in the temp folder of your bot's daily logs folder.")
			irc_chat(name, "It will have every entity known to your server (except players) which you can use as a handy reference.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "list" and words[2] == "all" and words[3] == "entities") then
			if server.useAllocsWebAPI then
				irc_chat(name, "Generating entities.txt in the logs folder " .. botman.chatlogPath:match("([^/]+)$") .. "/lists")
				botman.exportEntitiesList = true
				sendCommand("se")
			else
				irc_chat(name, "The bot must be in API mode to use this command. It is currently in telnet mode.")
				irc_chat(name, "To see if your bot can use Alloc's web API type map, then see if the map url that appears loads a page. If it does, you can type use api, then type list all entities.")
			end

			irc_params = {}

			return true
		end
	end


	local function cmd_ListItems()
		if displayIRCHelp then
			irc_chat(name, "Command: li {item name}")
			irc_chat(name, "List game items.  eg. li boots, will list all items with boots in their name.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "li" and words[2] ~= nil) then
			ircListItems = ircSteam
			sendCommand("li " .. words[2])
			irc_params = {}
			return true
		end
	end


	local function cmd_ViewPlayerStatus()
		if displayIRCHelp then
			irc_chat(name, "Command: status {player}")
			irc_chat(name, "View some info about a player's bases and donor status.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "status") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			name1 = string.trim(string.sub(msg, string.find(msgLower, "status") + 7))
			pid = LookupPlayer(name1)

			if (pid ~= "0") then
				irc_params.pid = pid
				irc_params.pname = players[pid].name
				irc_playerStatus()
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_ShopAddItem()
		local tmp = {}
		local itemExists = false

		if displayIRCHelp then
			irc_chat(name, "Command: shop add item {item name} category {category} price {price} stock {max stock} units {units spawned} quality {0-6}")
			irc_chat(name, "Add an item to the shop.  If a unit is given and a player buys 1 item, the bot will give 1 * the unit eg. 10 of the item.")
			irc_chat(name, "If quality is set to 0 the spawned item will have a random quality.  You can set any number that is supported by your server (usually 1-6).")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == "add" and words[3] == "item" and words[4] ~= nil) then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			LookupShop(wordsOld[4], "all")

			if shopCode ~= "" then
				itemExists = true
			end

			tmp.class = "misc"
			tmp.price = 10000
			tmp.stock = 0
			tmp.units = 0
			tmp.quality = 0

			for i=4,wordCount,1 do
				if words[i] == "category" then
					tmp.class = words[i+1]
				end

				if words[i] == "price" then
					tmp.price = tonumber(words[i+1])
				end

				if words[i] == "stock" then
					tmp.stock = tonumber(words[i+1])
				end

				if words[i] == "units" then
					tmp.units = tonumber(words[i+1])
				end

				if words[i] == "quality" then
					tmp.quality = tonumber(words[i+1])
				end
			end

			if itemExists then
				irc_chat(name, "You replaced " .. wordsOld[4] .. " in the shop.")
				conn:execute("UPDATE shop SET category = '" .. escape(tmp.class) .. "', stock = " .. tmp.stock .. ", maxStock = " .. tmp.stock .. ", price = " .. tmp.price .. ", units = " .. tmp.units .. ", quality = " .. tmp.quality .. " WHERE item = '" .. escape(wordsOld[4]) .. "'")
			else
				irc_chat(name, "You added " .. wordsOld[4] .. " to the shop.  You will need to add any missing info such as code, category, units, price, quality and quantity.")
				conn:execute("INSERT INTO shop (item, category, stock, maxStock, price, units, quality) VALUES ('" .. escape(wordsOld[4]) .. "','" .. escape(tmp.class) .. "'," .. tmp.stock .. "," .. tmp.stock .. "," .. tmp.price .. "," .. tmp.units .. "," .. tmp.quality .. ")")
			end


			reindexShop(tmp.class)

			irc_params = {}
			return true
		end
	end


	local function cmd_ShopEmpty()
		if displayIRCHelp then
			irc_chat(name, "Command: empty shop")
			irc_chat(name, "Completely empty the shop so you can start fresh.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "empty" and words[2] == "shop") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			conn:execute("TRUNCATE shop")
			conn:execute("DELETE FROM shopCategories WHERE category <> 'misc'")
			loadShopCategories()
			irc_chat(name, "You emptied the shop.  Only the misc category remains.")
			irc_params = {}
			return true
		end
	end


	local function cmd_ShopRemoveItem()
		if displayIRCHelp then
			irc_chat(name, "Command: shop remove item {item name}")
			irc_chat(name, "Remove an item from the shop.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "shop" and words[2] == "remove" and words[3] == "item") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			LookupShop(wordsOld[4], "all")

			if shopCode ~= "" then
				conn:execute("DELETE FROM shop WHERE item = '" .. escape(shopItem) .. "'")
				reindexShop(shopCategory)
				irc_chat(name, "You removed the item " .. shopItem .. " from the shop.")
			else
				irc_chat(name, "The item " .. wordsOld[4] .. " does not exist.")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_AddCustomCommand()
		local status, errorString

		if displayIRCHelp then
			irc_chat(name, "Command: add command {command} access {minimum access level} message {private message}")
			irc_chat(name, "Add a custom command.  At the moment these are just a private message.  Later more actions will be possible.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "add" and words[2] == "command" and players[ircSteam].accessLevel < 3) then
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
			status, errorString = conn:execute("INSERT INTO customMessages (command, message, accessLevel) VALUES ('" .. escape(cmd) .. "','" .. escape(tmp) .. "'," .. number .. ")")

			if not status then
				if string.find(errorString, "Duplicate entry") then
					conn:execute("UPDATE customMessages SET accessLevel = " .. number .. ", message = '" .. escape(tmp) .. "' WHERE command = '" .. escape(cmd) .. "'")
				end
			end

			-- reload from the database
			loadCustomMessages()

			irc_chat(name, cmd .. " has been added to custom commands.")
			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_RemoveCustomCommand()
		if displayIRCHelp then
			irc_chat(name, "Command: remove command {command}")
			irc_chat(name, "Delete a custom command.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "remove" and words[2] == "command" and players[ircSteam].accessLevel < 3) then
			cmd = words[3]

			-- remove the custom message from table customMessages
			conn:execute("DELETE FROM customMessages WHERE command = '" .. escape(cmd) .. "'")

			-- remove it from the Lua table
			customMessages[cmd] = nil

			irc_chat(name, cmd .. " has been removed from custom commands.")
			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_BlacklistPlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: blacklist add {player}")
			irc_chat(name, "Add a player to the bot's blacklist.  The bot will ban them for 10 years.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "blacklist" and words[2] == "add" and players[ircSteam].accessLevel < 3) then
			steam, steamOwner, userID, platform = LookupPlayer(words[3])

			if pid ~= "0" then
				banPlayer(platform, userID, steam, "10 years", "blacklisted", ircSteam)
				irc_chat(name, "Player " .. steam  .. " " .. players[steam].name .. " has been blacklisted 10 years.")
				irc_params = {}
				return true
			else
				banPlayer(platform, userID, words[3], "10 years", "blacklisted", ircSteam)
				irc_chat(name, "Player " .. words[3] .. " has been blacklisted 10 years.")
				irc_params = {}
				return true
			end
		end
	end


	local function cmd_UnbanPlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: ban remove {player}")
			irc_chat(name, "Unban a player.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "blacklist" or words[1] == "ban" and words[2] == "remove" and players[ircSteam].accessLevel < 3) then
			steam, steamOwner, userID = LookupPlayer(words[3])

			if steam ~= "0" then
				sendCommand("ban remove Steam_" .. steam)
				sendCommand("ban remove " .. userID)
				irc_chat(name, "Player " .. steam  .. " " .. players[steam].name .. " has been unbanned.")
				irc_params = {}
				return true
			end
		end
	end


	local function cmd_ListEvents()
		if displayIRCHelp then
			irc_chat(name, "Command: list event {event type}")
			irc_chat(name, "Several events are logged and can be searched with list event. Select from any of the following or add a player name or steam ID.")
			irc_chat(name, "eg. list event ban. Matching events in the last day are displayed.  To see more days add a number eg. list event ban 5")
			irc_chat(name, ".")
			return
		end

		if words[1] == "list" and string.find(words[2], "event") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if words[3] == nil then
				-- display command help
				irc_chat(name, "Several events are logged and can be searched with list event. Search for an event and/or add a player name or steam ID.")
				irc_chat(name, "eg. list event ban. Matching events in the last day are displayed.  To see more days add a number eg. list event ban 5")
				irc_chat(name, "For a list of events that can be searched for, just type list event.")
				irc_chat(name, ".")

				cursor,errorString = conn:execute("SELECT DISTINCT type FROM events ORDER BY type")
				row = cursor:fetch({}, "a")
				while row do
					irc_chat(name, row.type)
					row = cursor:fetch(row, "a")
				end

				irc_chat(name, ".")
				irc_params = {}
				return true
			end

			if number == nil then
				number = 0
			end

			tmp = {}
			tmp.event = ""
			tmp.steam = "0"

			if string.find(msgLower, "hack") then
				tmp.event = "hack"
			end

			if string.find(msgLower, "new player") then
				tmp.event = "new player"
			end

			if string.find(msgLower, "player left") then
				tmp.event = "player left"
			end

			if string.find(msgLower, "player joined") then
				tmp.event = "player joined"
			end

			if string.find(msgLower, "kick") then
				tmp.event = "kick"
			end

			if string.find(msgLower, "ban") then
				tmp.event = "ban"
			end

			if string.find(msgLower, "prison") then
				tmp.event = "prison"
			end

			if string.find(msgLower, "location") then
				tmp.event = "location"
			end

			if string.find(msgLower, "player") and tmp.event == "" then
				tmp.event = words[3]

				for i=4,wordCount,1 do
					if words[i] == "player" then
						pid = words[i+1]
						tmp.steam = LookupPlayer(pid)
					end
				end

				if pid == nil then
					tmp.steam = "0"
				end
			end

			irc_server_event(name, tmp.event, tmp.steam, number)
			irc_params = {}
			return true
		end
	end


	local function cmd_SearchForPlayer()
		if displayIRCHelp then
			irc_chat(name, "Command: search player {name}")
			irc_chat(name, "Search for a player by name.  It will list any players that match your search.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "search" and words[2] == "player" then
			irc_chat(name, "Players matching " .. words[3])

			cursor,errorString = conn:execute("SELECT id, steam, userID, name FROM players WHERE name LIKE '%" .. words[3] .. "%'")
			row = cursor:fetch({}, "a")
			while row do
				irc_chat(name, "gameID " .. row.id  .. " steam " .. row.steam .. " " .. row.userID .. " " .. row.name)
				row = cursor:fetch(row, "a")
			end

			irc_chat(name, ".")
		end
	end


	local function cmd_ListDuplicatePlayers()
		if displayIRCHelp then
			irc_chat(name, "Command: list duplicate players")
			irc_chat(name, "Get a list of all players with the same name. Useful for fixing issues.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "list" and words[2] == "duplicate" and words[3] == "players" then
			irc_chat(name, "Players with identical names and different steam keys:")

			cursor,errorString = conn:execute("SELECT GROUP_CONCAT(steam) AS SteamKey, name, COUNT(*) c FROM players GROUP BY name HAVING c > 1")
			row = cursor:fetch({}, "a")
			while row do
				for k,v in next, string.split(row.SteamKey, ",") do
					irc_chat(name, v  .. " " .. row.name)
				end

				row = cursor:fetch(row, "a")
			end

			irc_chat(name, ".")
		end
	end


	local function cmd_AddProxy()
		if displayIRCHelp then
			irc_chat(name, "Command: add proxy {text to match} action {ban or exile}")
			irc_chat(name, "Add a proxy for the bot to scan for and what action to take when it sees it.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "add" and words[2] == "proxy") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if words[3] == nil then
				irc_chat(name, "I do a dns lookup on every player that joins. You can ban or exile players found using a known proxy.")
				irc_chat(name, "Staff and whitelisted players are ignored.")
				irc_chat(name, "Command example: add proxy YPSOLUTIONS action ban.  Action is optional and can be ban or exile.  Ban is the default.")
				irc_chat(name, "To remove a proxy type remove proxy YPSOLUTIONS.  To list proxies type list proxies.")
				irc_params = {}
				return true
			end

			proxy = nil
			if string.find(msgLower, " action") then
				proxy = string.sub(msg, string.find(msgLower, "proxy") + 6, string.find(msgLower, "action") - 1)
			else
				proxy = string.sub(msg, string.find(msgLower, "proxy") + 6)
			end

			if proxy == nil then
				irc_chat(name, "The proxy is required.")
				irc_chat(name, "Command example: add proxy YPSOLUTIONS action ban.  Action is optional and can be ban or exile.  Ban is the default.")
				irc_params = {}
				return true
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
				return true
			end

			-- add the proxy to table proxies
			connSQL:execute("INSERT INTO proxies (scanString, action, hits) VALUES ('" .. connMEM:escape(proxy) .. "','" .. connMEM:escape(action) .. "',0)")

			if ircSteam == Smegz0r and botman.botsConnected then
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
			return true
		end
	end


	local function cmd_RemoveProxy()
		if displayIRCHelp then
			irc_chat(name, "Command: remove proxy {text}")
			irc_chat(name, "Remove a proxy.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "remove" and words[2] == "proxy") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			proxy = string.sub(msg, string.find(msgLower, "proxy") + 6)
			proxy = string.trim(string.upper(proxy))

			if proxy == nil then
				irc_chat(name, "The proxy is required.")
				irc_chat(name, "Command example: remove proxy YPSOLUTIONS.")
				irc_params = {}
				return true
			end

			-- remve the proxy from the proxies table
			connSQL:execute("DELETE FROM proxies WHERE scanString = '" .. connMEM:escape(proxy) .. "'")

			-- and remove it from the Lua table proxies
			proxies[proxy] = nil
			irc_chat(name, "You have removed the proxy " .. proxy)
			irc_params = {}
			return true
		end
	end


	local function cmd_ListProxies()
		if displayIRCHelp then
			irc_chat(name, "Command: list proxies")
			irc_chat(name, "View all of the proxies that the bot checks for, how many hits each has had and what action the bot takes when it sees one.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "list" and words[2] == "proxies" then
			cursor,errorString = conn:execute("SELECT * FROM proxies")
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
			return true
		end
	end


	local function cmd_ListRegionsWithBases()
		if displayIRCHelp then
			irc_chat(name, "Command: list regions")
			irc_chat(name, "List all of the regions that contain a player base. Does not take into account parts of bases that cross into other regions.")
			irc_chat(name, ".")
			return
		end

		if words[1] == "list" and words[2] == "regions" then
			connMEM:execute("DELETE FROM list WHERE steam = '" .. ircSteam .. "'")

			irc_chat(name, "The following regions have player bases in them.")

			for k,v in pairs(bases) do
				if math.abs(v.x) > 0 and math.abs(v.z) > 0 then
					temp = getRegion(v.x, v.z)
					conn:execute("INSERT INTO list (thing, steam) VALUES ('" .. temp .. "','" .. ircSteam .. "')")
				end
			end

			cursor,errorString = connMEM:execute("SELECT * FROM list WHERE steam = '" .. ircSteam .. "' ORDER BY thing")
			row = cursor:fetch({}, "a")
			while row do
				irc_chat(name, row.thing)
				row = cursor:fetch(row, "a")
			end

			connMEM:execute("DELETE FROM list WHERE steam = '" .. ircSteam .. "'")

			irc_chat(name, ".")
			irc_chat(name, "The following regions have locations in them.")

			for k,v in pairs(locations) do
				temp = getRegion(v.x, v.z)
					conn:execute("INSERT INTO list (thing, steam) VALUES ('" .. temp .. "','" .. ircSteam .. "')")
			end

			cursor,errorString = connMEM:execute("SELECT * FROM list WHERE steam = '" .. ircSteam .. "' ORDER BY thing")
			row = cursor:fetch({}, "a")
			while row do
				irc_chat(name, row.thing)
				row = cursor:fetch(row, "a")
			end

			connMEM:execute("DELETE FROM list WHERE steam = '" .. ircSteam .. "'")

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ListRestrictedItems()
		if displayIRCHelp then
			irc_chat(name, "Command: list restricted items")
			irc_chat(name, "View the list of restricted items.  These are items that new players aren't allowed.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "list" and words[2] == "restricted" and words[3] == "items") then
			irc_chat(name, "I scan for these restricted items in inventories:")

			for k, v in pairs(restrictedItems) do
				irc_chat(name, k .. " qty " .. v.qty .. " access level " .. v.accessLevel .. " action " .. v.action)
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ListEntities()
		if displayIRCHelp then
			irc_chat(name, "Command: list entities")
			irc_chat(name, "List all of entities currently in the world.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "list" and words[2] == "entities") then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			if botman.lastListEntities == nil then
				irc_chat(name, "Entities have not yet been scanned.  A scan has been actioned now. Repeat your command for the list.")
				sendCommand("le")
				irc_params = {}
				return true
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
				return true
			end

			if days==0 and hours==0 and minutes==0 and seconds==0 then
				irc_chat(name, "Entities need to be re-scanned.  A scan has been actioned now. Repeat your command for the list.")
				sendCommand("le")
				irc_params = {}
				return true
			else
				irc_chat(name, "Entities last scanned " .. minutes .." minutes " .. seconds .. " seconds ago")
			end

			irc_chat(name, "The currently loaded entities are:")

			cursor,errorString = connMEM:execute("SELECT * FROM entities ORDER BY name")
			row = cursor:fetch({}, "a")
			while row do
				irc_chat(name, "id= " .. row.entityID .. ", " .. row.name .. ", xyz= " .. row.x .. " " .. row.y .. " " .. row.z .. ", health= " .. row.health)
				row = cursor:fetch(row, "a")
			end

			irc_chat(name, ".")
			irc_params = {}
			return true
		end
	end


	local function cmd_ViewNearAnEntity()
		if displayIRCHelp then
			irc_chat(name, "Command: near entity {entity ID}")
			irc_chat(name, "View a list of players, bases and locations near a specific entity.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "near" and words[2] == "entity" and words[3] ~= nil) then
			if not admin then
				irc_chat(name, "Restricted command.")
				irc_params = {}
				return true
			end

			pid = words[3]

			cursor,errorString = connMEM:execute("SELECT * FROM entities WHERE entityID = " .. pid)
			row = cursor:fetch({}, "a")

			if row then
				irc_chat(name, "Players, bases and locations near entity " .. row.entityID .. " " .. row.name .. " at " .. row.x .. " " .. row.y .. " " .. row.z)
				irc_chat(name, ".")

				irc_PlayersNearPlayer(name, "", 200, row.x, row.z, false, row.entityID .. " " .. row.name)
				irc_BasesNearPlayer(name, "", 200, row.x, row.z, row.entityID .. " " .. row.name)
				irc_LocationsNearPlayer(name, "", 200, row.x, row.z, row.entityID .. " " .. row.name)
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_Help()
		if (words[1] == "help" and words[2] == nil) then
			irc_chat(irc_params.name, "You can view in-game command help by topic using list help {topic} or command help {topic} for any of the following topics:")
			irc_chat(name, ".")
			gmsg(server.commandPrefix .. "help sections", ircSteam)
			return
			--return true
		end
	end


	local function cmd_HelpForACommand()
		if displayIRCHelp then
			irc_chat(name, "Command: help {command}")
			irc_chat(name, "View help for an in-game command.  You will see help for any commands that match your search based on keywords.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "help" and words[2] ~= nil) then
			if displayIRCHelp then
				irc_chat(name, "In-game IRC command help:")
				irc_chat(name, ".")
			end

			result = gmsg(server.commandPrefix .. "help " .. string.sub(msg, 6), ircSteam)

			if not result and not chatvars.showHelp and not chatvars.showHelpSections then
				irc_chat(name, "No help found for " .. words[2])
				irc_chat(name, "For help topics type help topics")
				irc_chat(name, "For general help type help")
				irc_chat(name, "You can also search for help by a keyword eg. help set")
				irc_chat(name, ".")
			end

			irc_params = {}
			return true
		end
	end


	local function cmd_PlayOnServer()
		if displayIRCHelp then
			irc_chat(name, "Command: play (or join)")
			irc_chat(name, "View the server ip, player port and basic version info so you can join the server by copy-pasting the ip and port into your game.")
			irc_chat(name, ".")
			return
		end

		if (words[1] == "play") or (words[1] == "join") and wordCount == 1 then
			if words[2] == nil then
				irc_chat(name, "Server name is " .. server.serverName)
				irc_chat(name, "Address is " .. server.IP .. ":" .. server.ServerPort)
				irc_chat(name, "Game version is " .. server.gameVersion)

				if server.gameDate then
					irc_chat(name, "The game time is " .. server.gameDate)
				end

				irc_chat(name, ".")
				irc_params = {}
				return true
			end
		end
	end

	-- ===== END OF COMMAND FUNCTIONS ======

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	result = false

-- ########### Staff only beyond here ###########

	if not botman.registerHelp then
		if ircSteam == "0" then
			irc_params = {} -- GET OUT!
			return true, ""
		end

		if not admin then
			irc_params = {}
			return true, "" -- and take your dog.
		end
	end

-- ########### Staff only beyond here ###########

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if not botman.registerHelp then
		if players[ircSteam].ircAuthenticated == false then
			if requireLogin(name) then
				irc_params = {}
				return true, ""
			end
		end
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_PlayOnServer() then
		if debug then dbug("debug ran IRC command cmd_PlayOnServer") end
		return true, "IRC cmd_PlayOnServer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_FixBot() then
		if debug then dbug("debug ran IRC command cmd_FixBot") end
		return true, "IRC cmd_FixBot"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_AddLocationCategory() then
		if debug then dbug("debug ran IRC command cmd_AddLocationCategory") end
		return true, "IRC cmd_AddLocationCategory"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RemoveLocationCategory() then
		if debug then dbug("debug ran IRC command cmd_RemoveLocationCategory") end
		return true, "IRC cmd_RemoveLocationCategory"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RunReport() then
		if debug then dbug("debug ran IRC command cmd_RunReport") end
		return true, "IRC cmd_RunReport"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_StopReport() then
		if debug then dbug("debug ran IRC command cmd_StopReport") end
		return true, "IRC cmd_StopReport"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_UnmuteIRCUser() then
		if debug then dbug("debug ran IRC command cmd_UnmuteIRCUser") end
		return true, "IRC cmd_UnmuteIRCUser"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_MuteIrcUser() then
		if debug then dbug("debug ran IRC command cmd_MuteIrcUser") end
		return true, "IRC cmd_MuteIrcUser"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RunSQLSelect() then
		if debug then dbug("debug ran IRC command cmd_RunSQLSelect") end
		return true, "IRC cmd_RunSQLSelect"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RunSQLMemSelect() then
		if debug then dbug("debug ran IRC command cmd_RunSQLMemSelect") end
		return true, "IRC cmd_RunSQLMemSelect"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RunSQLTrakSelect() then
		if debug then dbug("debug ran IRC command cmd_RunSQLTrakSelect") end
		return true, "IRC cmd_RunSQLTrakSelect"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RunSQLTrakShadowSelect() then
		if debug then dbug("debug ran IRC command cmd_RunSQLTrakShadowSelect") end
		return true, "IRC cmd_RunSQLTrakShadowSelect"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RunSQLiteSelect() then
		if debug then dbug("debug ran IRC command cmd_RunSQLiteSelect") end
		return true, "IRC cmd_RunSQLiteSelect"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SetIRCServerIPAndPort() then
		if debug then dbug("debug ran IRC command cmd_SetIRCServerIPAndPort") end
		return true, "IRC cmd_SetIRCServerIPAndPort"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_MoveBotToNewServer() then
		if debug then dbug("debug ran IRC command cmd_MoveBotToNewServer") end
		return true, "IRC cmd_MoveBotToNewServer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RestartBot() then
		if debug then dbug("debug ran IRC command cmd_RestartBot") end
		return true, "IRC cmd_RestartBot"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_CheckDisk() then
		if debug then dbug("debug ran IRC command cmd_CheckDisk") end
		return true, "IRC cmd_CheckDisk"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SetCommandPrefix() then
		if debug then dbug("debug ran IRC command cmd_SetCommandPrefix") end
		return true, "IRC cmd_SetCommandPrefix"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewServerSettings() then
		if debug then dbug("debug ran IRC command cmd_ViewServerSettings") end
		return true, "IRC cmd_ViewServerSettings"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListNewPlayers() then
		if debug then dbug("debug ran IRC command cmd_ListNewPlayers") end
		return true, "IRC cmd_ListNewPlayers"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_CheckPlayerOnBlacklist() then
		if debug then dbug("debug ran IRC command cmd_CheckPlayerOnBlacklist") end
		return true, "IRC cmd_CheckPlayerOnBlacklist"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewAlerts() then
		if debug then dbug("debug ran IRC command cmd_ViewAlerts") end
		return true, "IRC cmd_ViewAlerts"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_UpdateAlert() then
		if debug then dbug("debug ran IRC command cmd_UpdateAlert") end
		return true, "IRC cmd_UpdateAlert"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_DeleteAlert() then
		if debug then dbug("debug ran IRC command cmd_DeleteAlert") end
		return true, "IRC cmd_DeleteAlert"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_DeleteAllAlerts() then
		if debug then dbug("debug ran IRC command cmd_DeleteAllAlerts") end
		return true, "IRC cmd_DeleteAllAlerts"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewSlots() then
		if debug then dbug("debug ran IRC command cmd_ViewSlots") end
		return true, "IRC cmd_ViewSlots"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShowInventory() then
		if debug then dbug("debug ran IRC command cmd_ShowInventory") end
		return true, "IRC cmd_ShowInventory"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewRollingAnnouncements() then
		if debug then dbug("debug ran IRC command cmd_ViewRollingAnnouncements") end
		return true, "IRC cmd_ViewRollingAnnouncements"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_AddAnnouncement() then
		if debug then dbug("debug ran IRC command cmd_AddAnnouncement") end
		return true, "IRC cmd_AddAnnouncement"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_DeleteAnnouncement() then
		if debug then dbug("debug ran IRC command cmd_DeleteAnnouncement") end
		return true, "IRC cmd_DeleteAnnouncement"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_WhoVisited() then
		if debug then dbug("debug ran IRC command cmd_WhoVisited") end
		return true, "IRC cmd_WhoVisited"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_PayPlayer() then
		if debug then dbug("debug ran IRC command cmd_PayPlayer") end
		return true, "IRC cmd_PayPlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SetPlayerCash() then
		if debug then dbug("debug ran IRC command cmd_SetPlayerCash") end
		return true, "IRC cmd_SetPlayerCash"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SetCodeBranch() then
		if debug then dbug("debug ran IRC command cmd_SetCodeBranch") end
		return true, "IRC cmd_SetCodeBranch"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ToggleDebugMode() then
		if debug then dbug("debug ran IRC command cmd_ToggleDebugMode") end
		return true, "IRC cmd_ToggleDebugMode"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListClaims() then
		if debug then dbug("debug ran IRC command cmd_ListClaims") end
		return true, "IRC cmd_ListClaims"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RunIngameCommand() then
		if debug then dbug("debug ran IRC command cmd_RunIngameCommand") end
		return true, "IRC cmd_RunIngameCommand"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SendPM() then
		if debug then dbug("debug ran IRC command cmd_SendPM") end
		return true, "IRC cmd_SendPM"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SendConsoleCommand() then
		if debug then dbug("debug ran IRC command cmd_SendConsoleCommand") end
		return true, "IRC cmd_SendConsoleCommand"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_AssignBotOwner() then
		if debug then dbug("debug ran IRC command cmd_AssignBotOwner") end
		return true, "IRC cmd_AssignBotOwner"
	end

if debug then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListVillagers() then
		if debug then dbug("debug ran IRC command cmd_ListVillagers") end
		return true, "IRC cmd_ListVillagers"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SetBaseCooldown() then
		if debug then dbug("debug ran IRC command cmd_SetBaseCooldown") end
		return true, "IRC cmd_SetBaseCooldown"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SetRules() then
		if debug then dbug("debug ran IRC command cmd_SetRules") end
		return true, "IRC cmd_SetRules"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewOrClearMOTD() then
		if debug then dbug("debug ran IRC command cmd_ViewOrClearMOTD") end
		return true, "IRC cmd_ViewOrClearMOTD"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SetMOTD() then
		if debug then dbug("debug ran IRC command cmd_SetMOTD") end
		return true, "IRC cmd_SetMOTD"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SetAPIPort() then
		if debug then dbug("debug ran IRC command cmd_SetAPIPort") end
		return true, "IRC cmd_SetAPIPort"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SetAPIKey() then
		if debug then dbug("debug ran IRC command cmd_SetAPIKey") end
		return true, "IRC cmd_SetAPIKey"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListBotTables() then
		if debug then dbug("debug ran IRC command cmd_ListBotTables") end
		return true, "IRC cmd_ListBotTables"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShowBotTable() then
		if debug then dbug("debug ran IRC command cmd_ShowBotTable") end
		return true, "IRC cmd_ShowBotTable"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ResetBotKeepCash() then
		if debug then dbug("debug ran IRC command cmd_ResetBotKeepCash") end
		return true, "IRC cmd_ResetBotKeepCash"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ResetBot() then
		if debug then dbug("debug ran IRC command cmd_ResetBot") end
		return true, "IRC cmd_ResetBot"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_StopTranslatingPlayer() then
		if debug then dbug("debug ran IRC command cmd_StopTranslatingPlayer") end
		return true, "IRC cmd_StopTranslatingPlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_TranslatePlayer() then
		if debug then dbug("debug ran IRC command cmd_TranslatePlayer") end
		return true, "IRC cmd_TranslatePlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_StealthTranslatePlayer() then
		if debug then dbug("debug ran IRC command cmd_StealthTranslatePlayer") end
		return true, "IRC cmd_StealthTranslatePlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_OpenShop() then
		if debug then dbug("debug ran IRC command cmd_OpenShop") end
		return true, "IRC cmd_OpenShop"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_CloseShop() then
		if debug then dbug("debug ran IRC command cmd_CloseShop") end
		return true, "IRC cmd_CloseShop"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopSetItemUnits() then
		if debug then dbug("debug ran IRC command cmd_ShopSetItemUnits") end
		return true, "IRC cmd_ShopSetItemUnits"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopSetItemPrice() then
		if debug then dbug("debug ran IRC command cmd_ShopSetItemPrice") end
		return true, "IRC cmd_ShopSetItemPrice"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopSetItemQuality() then
		if debug then dbug("debug ran IRC command cmd_ShopSetItemQuality") end
		return true, "IRC cmd_ShopSetItemQuality"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopSetItemMaxStock() then
		if debug then dbug("debug ran IRC command cmd_ShopSetItemMaxStock") end
		return true, "IRC cmd_ShopSetItemMaxStock"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopRestockItem() then
		if debug then dbug("debug ran IRC command cmd_ShopRestockItem") end
		return true, "IRC cmd_ShopRestockItem"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopAddCategory() then
		if debug then dbug("debug ran IRC command cmd_ShopAddCategory") end
		return true, "IRC cmd_ShopAddCategory"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopRemoveCategory() then
		if debug then dbug("debug ran IRC command cmd_ShopRemoveCategory") end
		return true, "IRC cmd_ShopRemoveCategory"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopChangeCategory() then
		if debug then dbug("debug ran IRC command cmd_ShopChangeCategory") end
		return true, "IRC cmd_ShopChangeCategory"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewInventory() then
		if debug then dbug("debug ran IRC command cmd_ViewInventory") end
		return true, "IRC cmd_ViewInventory"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListVillageMembers() then
		if debug then dbug("debug ran IRC command cmd_ListVillageMembers") end
		return true, "IRC cmd_ListVillageMembers"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListBases() then
		if debug then dbug("debug ran IRC command cmd_ListBases") end
		return true, "IRC cmd_ListBases"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListBeds() then
		if debug then dbug("debug ran IRC command cmd_ListBeds") end
		return true, "IRC cmd_ListBeds"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_AddBadItem() then
		if debug then dbug("debug ran IRC command cmd_AddBadItem") end
		return true, "IRC cmd_AddBadItem"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RemoveBadItem() then
		if debug then dbug("debug ran IRC command cmd_RemoveBadItem") end
		return true, "IRC cmd_RemoveBadItem"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_EditBadItem() then
		if debug then dbug("debug ran IRC command cmd_EditBadItem") end
		return true, "IRC cmd_EditBadItem"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_NearPlayer() then
		if debug then dbug("debug ran IRC command cmd_NearPlayer") end
		return true, "IRC cmd_NearPlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_PlayerInfo() then
		if debug then dbug("debug ran IRC command cmd_PlayerInfo") end
		return true, "IRC cmd_PlayerInfo"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_AddDonor() then
		if debug then dbug("debug ran IRC command cmd_AddDonor") end
		return true, "IRC cmd_AddDonor"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RemoveDonor() then
		if debug then dbug("debug ran IRC command cmd_RemoveDonor") end
		return true, "IRC cmd_RemoveDonor"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_AddOwner() then
		if debug then dbug("debug ran IRC command cmd_AddOwner") end
		return true, "IRC cmd_AddOwner"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RemoveOwner() then
		if debug then dbug("debug ran IRC command cmd_RemoveOwner") end
		return true, "IRC cmd_RemoveOwner"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_AddAdmin() then
		if debug then dbug("debug ran IRC command cmd_AddAdmin") end
		return true, "IRC cmd_AddAdmin"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RemoveAdmin() then
		if debug then dbug("debug ran IRC command cmd_RemoveAdmin") end
		return true, "IRC cmd_RemoveAdmin"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_AddPermaban() then
		if debug then dbug("debug ran IRC command cmd_AddPermaban") end
		return true, "IRC cmd_AddPermaban"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RemovePermaban() then
		if debug then dbug("debug ran IRC command cmd_RemovePermaban") end
		return true, "IRC cmd_RemovePermaban"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SetIRCLogin() then
		if debug then dbug("debug ran IRC command cmd_SetIRCLogin") end
		return true, "IRC cmd_SetIRCLogin"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_UnfriendPlayer() then
		if debug then dbug("debug ran IRC command cmd_UnfriendPlayer") end
		return true, "IRC cmd_UnfriendPlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_FriendPlayer() then
		if debug then dbug("debug ran IRC command cmd_FriendPlayer") end
		return true, "IRC cmd_FriendPlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListPlayersFriends() then
		if debug then dbug("debug ran IRC command cmd_ListPlayersFriends") end
		return true, "IRC cmd_ListPlayersFriends"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListPlayers() then
		if debug then dbug("debug ran IRC command cmd_ListPlayers") end
		return true, "IRC cmd_ListPlayers"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListArchivedPlayers() then
		if debug then dbug("debug ran IRC command cmd_ListArchivedPlayers") end
		return true, "IRC cmd_ListArchivedPlayers"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewPlayerRecord() then
		if debug then dbug("debug ran IRC command cmd_ViewPlayerRecord") end
		return true, "IRC cmd_ViewPlayerRecord"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewShadowCopyPlayerRecord() then
		if debug then dbug("debug ran IRC command cmd_ViewShadowCopyPlayerRecord") end
		return true, "IRC cmd_ViewShadowCopyPlayerRecord"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewArchivedPlayer() then
		if debug then dbug("debug ran IRC command cmd_ViewArchivedPlayer") end
		return true, "IRC cmd_ViewArchivedPlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewInGamePlayerRecord() then
		if debug then dbug("debug ran IRC command cmd_ViewInGamePlayerRecord") end
		return true, "IRC cmd_ViewInGamePlayerRecord"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListInGamePlayers() then
		if debug then dbug("debug ran IRC command cmd_ListInGamePlayers") end
		return true, "IRC cmd_ListInGamePlayers"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_WhoShortList() then
		if debug then dbug("debug ran IRC command cmd_WhoShortList") end
		return true, "IRC cmd_WhoShortList"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_Whom() then
		if debug then dbug("debug ran IRC command cmd_Whom") end
		return true, "IRC cmd_Whom"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_WatchPlayer() then
		if debug then dbug("debug ran IRC command cmd_WatchPlayer") end
		return true, "IRC cmd_WatchPlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_StopWatchingPlayer() then
		if debug then dbug("debug ran IRC command cmd_StopWatchingPlayer") end
		return true, "IRC cmd_StopWatchingPlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListDonors() then
		if debug then dbug("debug ran IRC command cmd_ListDonors") end
		return true, "IRC cmd_ListDonors"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListTeleports() then
		if debug then dbug("debug ran IRC command cmd_ListTeleports") end
		return true, "IRC cmd_ListTeleports"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListBadItems() then
		if debug then dbug("debug ran IRC command cmd_ListBadItems") end
		return true, "IRC cmd_ListBadItems"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListPrisoners() then
		if debug then dbug("debug ran IRC command cmd_ListPrisoners") end
		return true, "IRC cmd_ListPrisoners"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListAllItems() then
		if debug then dbug("debug ran IRC command cmd_ListAllItems") end
		return true, "IRC cmd_ListAllItems"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListAllEntities() then
		if debug then dbug("debug ran IRC command cmd_ListAllEntities") end
		return true, "IRC cmd_ListAllEntities"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListItems() then
		if debug then dbug("debug ran IRC command cmd_ListItems") end
		return true, "IRC cmd_ListItems"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewPlayerStatus() then
		if debug then dbug("debug ran IRC command cmd_ViewPlayerStatus") end
		return true, "IRC cmd_ViewPlayerStatus"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopAddItem() then
		if debug then dbug("debug ran IRC command cmd_ShopAddItem") end
		return true, "IRC cmd_ShopAddItem"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopEmpty() then
		if debug then dbug("debug ran IRC command cmd_ShopEmpty") end
		return true, "IRC cmd_ShopEmpty"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopRemoveItem() then
		if debug then dbug("debug ran IRC command cmd_ShopRemoveItem") end
		return true, "IRC cmd_ShopRemoveItem"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_AddCustomCommand() then
		if debug then dbug("debug ran IRC command cmd_AddCustomCommand") end
		return true, "IRC cmd_AddCustomCommand"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RemoveCustomCommand() then
		if debug then dbug("debug ran IRC command cmd_RemoveCustomCommand") end
		return true, "IRC cmd_RemoveCustomCommand"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_BlacklistPlayer() then
		if debug then dbug("debug ran IRC command cmd_BlacklistPlayer") end
		return true, "IRC cmd_BlacklistPlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_UnbanPlayer() then
		if debug then dbug("debug ran IRC command cmd_UnbanPlayer") end
		return true, "IRC cmd_UnbanPlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListEvents() then
		if debug then dbug("debug ran IRC command cmd_ListEvents") end
		return true, "IRC cmd_ListEvents"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_SearchForPlayer() then
		if debug then dbug("debug ran IRC command cmd_SearchForPlayer") end
		return true, "IRC cmd_SearchForPlayer"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListDuplicatePlayers() then
		if debug then dbug("debug ran IRC command cmd_ListDuplicatePlayers") end
		return true, "IRC cmd_ListDuplicatePlayers"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_AddProxy() then
		if debug then dbug("debug ran IRC command cmd_AddProxy") end
		return true, "IRC cmd_AddProxy"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_RemoveProxy() then
		if debug then dbug("debug ran IRC command cmd_RemoveProxy") end
		return true, "IRC cmd_RemoveProxy"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListProxies() then
		if debug then dbug("debug ran IRC command cmd_ListProxies") end
		return true, "IRC cmd_ListProxies"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListRegionsWithBases() then
		if debug then dbug("debug ran IRC command cmd_ListRegionsWithBases") end
		return true, "IRC cmd_ListRegionsWithBases"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListRestrictedItems() then
		if debug then dbug("debug ran IRC command cmd_ListRestrictedItems") end
		return true, "IRC cmd_ListRestrictedItems"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ListEntities() then
		if debug then dbug("debug ran IRC command cmd_ListEntities") end
		return true, "IRC cmd_ListEntities"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ViewNearAnEntity() then
		if debug then dbug("debug ran IRC command cmd_ViewNearAnEntity") end
		return true, "IRC cmd_ViewNearAnEntity"
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_DeleteOldLogs() then
		if debug then dbug("debug ran IRC command cmd_DeleteOldLogs") end
		return true, "IRC cmd_DeleteOldLogs"
	end


if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if not botman.registerHelp then
		if cmd_Help() then
			if debug then dbug("debug ran IRC command cmd_Help") end
			--return true, "IRC cmd_Help"
			return
		end
	end

if (debug) then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_HelpForACommand() then
		if debug then dbug("debug ran IRC command cmd_HelpForACommand") end
		--return true, "IRC cmd_HelpForACommand"
		return
	end

if debug then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_GetGuides() then
		if debug then dbug("debug ran IRC command cmd_GetGuides") end
		return true, "IRC cmd_GetGuides"
	end

if debug then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopEditCategoryItems() then
		if debug then dbug("debug ran IRC command cmd_ShopEditCategoryItems") end
		return true, "IRC cmd_ShopEditCategoryItems"
	end

if debug then dbug("debug irc message2 line " .. debugger.getinfo(1).currentline) end

	if cmd_ShopEditAllItemsInShop() then
		if debug then dbug("debug ran IRC command cmd_ShopEditAllItemsInShop") end
		return true, "IRC cmd_ShopEditAllItemsInShop"
	end

if debug then dbug ("debug ircmessage2 end") end
end