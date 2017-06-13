--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

--/mode #haven2 +f [5000t#b]:1

local ircid, pid, login, name1, name2, words, wordsOld, words2, wordCount, result, msgLower, number, counter, xpos, zpos, debug, tmp, k, v

debug = false

function requireLogin(name, silent)
	local steam

	steam = LookupIRCAlias(name)

	-- see if we can find this irc nick in the bots database
	if steam then
		cursor,errorString = connBots:execute("SELECT * FROM players where ircAlias = '" .. escape(name) .. "' and steam = " .. steam)
		if cursor:numrows() == 0 then
			if not silent then
				irc_chat(name, "Your bot login has expired. Login and repeat your command.")
			end

			return true
		else
			row = cursor:fetch(row, "a")

			if row.ircAuthenticated then
				players[steam].ircSessionExpiry = os.time() + 3600
				players[steam].ircAuthenticated = true
				players[steam].ircAlias = name
				ircid = steam
				return false
			end
		end
	end
end


IRCMessage = function (event, name, channel, msg)
	if debug then
		dbug("debug irc message line " .. debugger.getinfo(1).currentline)
		dbug(event .. " " .. name .. " " .. channel .. " " .. msg)
	end

	if ircGetNick ~= nil then
		server.ircBotName = ircGetNick()
	end

	-- block Mudlet from messaging the official Mudlet support channel
	if (channel == "#mudlet") then
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	irc_params = {}

	if server.ircMain == "#new" or server.ircMain == "#bot" and string.find(channel, "#", nil, true) and not string.find(channel, "_", nil, true) then
		server.ircMain = channel
		server.ircAlerts = channel .. "_alerts"
		server.ircWatch = channel .. "_watch"
		server.ircTracker = channel .. "_tracker"
		conn:execute("UPDATE server SET ircMain = '" .. server.ircMain .. "', ircAlerts = '" .. server.ircAlerts .. "', ircWatch = '" .. server.ircWatch .. "', ircTracker = '" .. server.ircTracker .. "'")
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	-- block Mudlet from reacting to its own messages
	if (name == server.botName or name == server.ircBotName or string.find(msg, "<" .. server.ircBotName .. ">", nil, true)) then return end

	words = {}
	wordsOld = {}
	for word in msg:gmatch("%S+") do table.insert(wordsOld, word) end

	words2 = string.split(msg, " ")
	msgLower = string.lower(msg)

	irc_params.name = name
	for word in msgLower:gmatch("%w+") do table.insert(words, word) end
	wordCount = table.maxn(words)

	number = tonumber(string.match(msg, " (-?\%d+)"))

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "fix" and words[2] == "bot") and words[3] == nil then
		fixBot()
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "reload" and (string.find(msg, "code") or string.find(msg, "script")) and words[3] == nil) then
		dofile(homedir .. "/scripts/reload_bot_scripts.lua")
		reloadBotScripts(true)
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "update" and (words[2] == "code" or words[2] == "scripts" or words[2] == "bot") and words[3] == nil) then
		updateBot(true)
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "server") then
		if words[2] == nil then
			irc_chat(name, "Server name is " .. server.serverName)
			irc_chat(name, "Address is " .. server.IP .. ":" .. server.ServerPort)
			irc_chat(name, "There are  " .. botman.playersOnline .. " players online.")
			irc_chat(name, " ")
			return
		end
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "search" and words[2] == "blacklist") then
		tmp = {}
		tmp.IP = string.sub(msg, string.find(msg, "blacklist") + 10)

		searchBlacklist(tmp.IP, name)
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "shop" and words[2] == nil) then
		irc_HelpShop()
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

			irc_chat(name, msg)
			row = cursor:fetch(row, "a")
		end

		irc_chat(name, " ")
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "shop" and words[2] == "categories") then
		irc_chat(name, "The shop categories are:")

		for k, v in pairs(shopCategories) do
			irc_chat(name, k)
		end

		irc_chat(name, " ")
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

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

			irc_chat(name, msg)

			row = cursor:fetch(row, "a")
		end

		irc_chat(name, " ")
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "villages" and words[2] == nil) then
		irc_chat(name, "List of villages on the server:")
		for k, v in pairs(locations) do
			if v.village == true then
				pid = LookupOfflinePlayer(v.mayor)

				if pid ~= nil then
					irc_chat(name, v.name .. " the Mayor is " .. players[pid].name)
				else
					irc_chat(name, v.name)
				end
			end
		end

		irc_chat(name, " ")
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "fps" and words[2] == nil then
		cursor,errorString = conn:execute("SELECT * FROM performance  ORDER BY serverdate DESC Limit 0, 1")
		row = cursor:fetch({}, "a")

		if row then
			irc_chat(channel, "Server FPS: " .. server.fps .. " Players: " .. row.players .. " Zombies: " .. row.zombies .. " Entities: " .. row.entities .. " Heap: " .. row.heap .. " HeapMax: " .. row.heapMax)
		end

		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == "custom" and words[3] == "commands") then
		irc_HelpCustomCommands()
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "date" or words[1] == "time" or words[1] == "day") and words[2] == nil then
		irc_gameTime(channel)
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "uptime") and words[2] == nil then
		irc_uptime(channel)
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "location") then
		-- display details about the location

		locationName = words[2]
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then
			irc_chat(name, "That location does not exist.")
			return
		else
			cursor,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. locationName .."'")
			row = cursor:fetch({}, "a")

			irc_chat(name, "Location: " .. row.name)
			irc_chat(name, "Active: " .. dbYN(row.active))
			irc_chat(name, "Reset Zone: " .. dbYN(row.resetZone))
			irc_chat(name, "Safe Zone: " .. dbYN(row.killZombies))
			irc_chat(name, "Public: " .. dbYN(row.public))
			irc_chat(name, "Allow Bases: " .. dbYN(row.allowBase))

			if row.miniGame ~= nil then
				irc_chat(name, "Mini Game: " .. row.miniGame)
			end

			irc_chat(name, "Village: " .. dbYN(row.village))

			temp = ""
			if tonumber(row.mayor) > 0 then
				temp = LookupPlayer(row.mayor)
				temp = players[temp].name
			end

			irc_chat(name, "Mayor: " .. temp)
			irc_chat(name, "Protected: " .. dbYN(row.protected))
			irc_chat(name, "PVP: " .. dbYN(row.pvp))
			irc_chat(name, "Access Level: " .. row.accessLevel)

			temp = ""
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

			irc_chat(name, "Players in " .. loc)

			for k,v in pairs(igplayers) do
				if players[k].inLocation == loc then
					irc_chat(name, v.name)
				end
			end

			irc_chat(name, " ")
		end

		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "server" and (words[2] == "status" or words[2] == "stats") then
		irc_server_status(name)
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "who" and (words[2] == "today" or words[2] == "last") then
		irc_who_played(name)
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == "shop") then
		irc_HelpShop()
		return
	end

	if (words[1] == "help" and words[2] == "topics") then
		irc_HelpTopics()
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

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

			if ircid then
				if players[ircid].accessLevel < 3 then
					irc_chat(name, v.name .. " " .. public .. " " .. active .. " xyz " .. v.x .. "," .. v.y .. "," .. v.z)
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

		irc_chat(name, " ")
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "staff" and words[2] == nil) then
		listOwners(name)
		listAdmins(name)
		listMods(name)
		return
	end


	if (words[1] == "owners" and words[2] == nil) then
		listOwners(name)
		return
	end


	if (words[1] == "admins" and words[2] == nil) then
		listAdmins(name)
		return
	end


	if (words[1] == "mods" and words[2] == nil) then
		listMods(name)
		return
	end


	if words[1] == string.lower(server.botName) or words[1] == string.lower(server.ircBotName) and words[2] == nil then
		irc_chat(name, "Hi " .. name)
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	-- try to find the irc person in the players table
	-- commands below here won't work if the bot doesn't match you against a player record
	ircid = LookupOfflinePlayer(name, "all")

	if ircid == nil then
		ircid = LookupOfflinePlayer(name)
	end

	if ircid then
		if players[ircid].ircAuthenticated == false then
			requireLogin(name, true)
		else
			-- keep login session alive
			if accessLevel(ircid) < 4 then
				players[ircid].ircSessionExpiry = os.time() + 3600
			else
				players[ircid].ircSessionExpiry = os.time() + 10800
			end

			connBots:execute("UPDATE players SET ircAuthenticated = 1 WHERE steam = " .. ircid)
		end

		if debug then dbug("IRC: " .. name .. " access " .. accessLevel(ircid) .. " said " .. msg) end
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "hi" or words[1] == "hello") and (string.lower(words[2]) == string.lower(server.botName) or string.lower(words[2]) == string.lower(server.ircBotName) or words[2] == "bot" or words[2] == "server") then
		irc_chat(name, "Hi there " .. name .. "!  How can I help you today?")

		if ircid == nil then
			ircid = LookupOfflinePlayer(name)
		else
			if not players[ircid].ircAuthenticated then
				requireLogin(name, true)
			end
		end

		if not ircid then
			irc_chat(channel, "Hi there " .. name .. ", this is the " .. channel .. " channel.  Please move to " .. server.ircBotName .. " to login.")
		else
			if players[ircid].ircAuthenticated then
				irc_chat(channel, "Hi there " .. name .. "!  Welcome to " .. channel .. ". You are logged in.")
			end
		end

		return
	end

if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "who" and words[2] == nil) then
		if not players[ircid].ircAuthenticated then
			requireLogin(name, true)
		end

		irc_players(name)
		return
	end

if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "login") then
		tmp = {}

		if words[2] ~= nil then
			if not string.find(msg, " pass ") then
				irc_chat(name, "Logins have changed.  The new format is login <name> pass <password>")
				irc_chat(name, "Your login will need to be updated to the new format.  You can do this yourself by typing invite <your ingame name> then join the server and type /read mail and follow the instructions there.")
				irc_chat(name, " ")
				return
			else
				tmp.login = string.sub(msg, string.find(msgLower, "login") + 6, string.find(msg, " pass ") - 1)
				tmp.pass = string.sub(msg, string.find(msgLower, " pass ") + 6)
			end

			ircid = LookupIRCPass(tmp.login, tmp.pass)

			if (ircid ~= nil) then
				if string.find(channel, "#") then
					irc_chat(name, "You accidentally revealed your password in a public channel.  You password has been automatically wiped and you won't be able to login until Smeg sets a new password for you.")
					players[ircid].ircAuthenticated = false
					players[ircid].ircPass = nil

					conn:execute("UPDATE players SET ircPass = '' WHERE steam = " .. ircid)
					connBots:execute("UPDATE players SET ircAuthenticated = 0 WHERE steam = " .. ircid)
					return
				end

				players[ircid].ircAuthenticated = true
				players[ircid].ircAlias = name

				-- fix a weird bug where the wrong player can have the irc alias for this player and they can't get it back
				conn:execute("UPDATE players SET ircAlias = '' WHERE ircAlias = '" .. escape(name) .. "'")
				conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = " .. ircid)
				connBots:execute("UPDATE players SET ircAlias = '' WHERE ircAlias = '" .. escape(name) .. "'")
				connBots:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "', ircAuthenticated = 1 WHERE steam = " .. ircid)

				players[ircid].ircSessionExpiry = os.time() + 10800 -- 3 hours!

				irc_chat(name, "You have logged in " .. name)
				irc_chat(name, " ")
				return
			else
				irc_chat(name, "Name or password not recognised. :{")
				irc_chat(name, "Note: You must have joined the server at least once to be recognised.  Also a password must have been set for you.")
				irc_chat(name, "You can get yourself recognised and give yourself a password by typing invite <your ingame name>. Join the server and /read mail then follow the bot's instructions.")
				irc_chat(name, " ")
				return
			end

			if (players[ircid].ircPass == nil) then
				irc_chat(name, "You don't currently have a password.  Ask us to set one for you.")
				irc_chat(name, "Note: You must have joined the server at least once to be recognised as then you will have a player record.")
				irc_chat(name, "You can get yourself recognised and give yourself a password by typing invite <your ingame name>. Join the server and /read mail then follow the bot's instructions.")
				irc_chat(name, " ")
			end
		else
			irc_chat(name, "You didn't give me the password.  Type login <password> or login <name> pass <password>")
			irc_chat(name, "Note: You must have joined the server at least once to be recognised as then you will have a player record.")
			irc_chat(name, "You can get yourself recognised and give yourself a password by typing invite <your ingame name>. Join the server and /read mail then follow the bot's instructions.")
		end

		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "rescue" and words[2] == "me" then
		for k,v in pairs(players) do
			if v.ircAlias == name then
				v.ircAlias = ""
				irc_chat(name, "Your nick has been released from a player record. Now login to claim it.")

				conn:execute("UPDATE players SET ircAlias = '' WHERE steam = " .. k)
			end
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "bow" and (words[2] == "before" or words[2] == "to") and words[3] == "me" then
		ircid = LookupPlayer(name, "all")

		if accessLevel(ircid) < 3 then
			players[ircid].ircSessionExpiry = os.time() + 10800 -- 3 hours!
			players[ircid].ircAuthenticated = true
			players[ircid].ircAlias = name
			irc_chat(name, "You have logged in " .. name)
			irc_chat(name)

			conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = " .. ircid)
			connBots:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "', ircAuthenticated = 1 WHERE steam = " .. ircid)
		else
			irc_chat(name, "Did you drop your contact lense?")
			irc_chat(name, " ")
		end

		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "i" and words[2] == "am" and words[3] ~= nil then
		ircid = LookupPlayer(words[3], "code")

		if ircid ~= nil then
			players[ircid].ircSessionExpiry = os.time() + 3600
			players[ircid].ircAuthenticated = true
			players[ircid].ircAlias = name
			players[ircid].ircInvite = nil
			irc_chat(name, "Welcome to our IRC server " .. name .. "!")
			irc_chat(name, "Your current IRC nickname is now recorded in your player record.  To prevent others from impersonating you on IRC, you need to give me a password.")
			irc_chat(name, "Please just use numbers and letters and no symbols.  To set or change your password type new login <name> pass <password>.  eg. new login joe pass catsrul3")
			irc_chat(name, " ")
			irc_chat(name, "To use your password, never type it in " .. server.ircMain .. " or anywhere other than here in this private chat between us or others may see your password.")
			irc_chat(name, "If you accidentally login in " .. server.ircMain .. " I will wipe your password and you will need to set a new one.  If that happens type invite followed by your in-game name and I will send you a new IRC invite code.")

			if accessLevel(ircid) < 3 then
				irc_chat(name, "As an admin of " .. server.serverName .. " you have a lot of commands available.  Type help and you can start exploring all of the commands available to you.")
				irc_chat(name, " ")
				irc_chat(name, "Some common IRC bot commands are:")
				irc_chat(name, "help, staff, who, uptime, server, server stats, info <player>, inv <player>, near player <player>, new players")
			else
				irc_chat(name, "As a player you have some commands you can give me.  To see them all type help.  You can also chat to in-game players from here but ideally in " .. server.ircMain .. ". To speak to them type say followed by a message.")
				irc_chat(name, "Anything after the word say is repeated in-game with your name infront of it and -irc to show that you are speaking from here.")
				irc_chat(name, "Note that on IRC, bot commands do not use a /.  This is because the IRC server uses / for server its IRC commands.")
				irc_chat(name, " ")
				irc_chat(name, "Some common IRC bot commands are:")
				irc_chat(name, "help, staff, who, uptime, server, server stats, day, rules")
				irc_chat(name, " ")
				irc_chat(name, "Never login in " .. server.ircMain .. " or any channel that begins with a #.  Always type hi bot and use the private chat channel.")
				irc_chat(name, " ")
			end

			irc_chat(name, " ")
			conn:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "' WHERE steam = " .. ircid)
			connBots:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "', ircAuthenticated = 1 WHERE steam = " .. ircid)
		end

		return
	end

	if players[ircid].denyRights then
		return
	end

	if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "help" and (words[2] == "intro" or words[2] == "guide" or words[2] == "manual") then
		irc_Manual()
	end

	if debug then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "server") then
		if words[2] == "ip" then
			if not players[ircid].ircAuthenticated then
				if requireLogin(name) then
					return
				end
			end

			if (string.trim(words[3]) ~= "") then
				server.IP = string.sub(msg, string.find(msg, words[3]), string.len(msg))
				irc_chat(name, "The server address is now " .. server.IP .. ":" .. server.ServerPort)
				irc_chat(name, " ")
				conn:execute("UPDATE server SET IP = '" .. server.IP .. "'")
				return
			end
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "new" and string.find(msg, "pass") and words[3] ~= nil then
		if players[ircid].ircAuthenticated == false then
			if requireLogin(name) then
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
			irc_chat(name, "The format of this command has changed.  It is, new login <name> pass <password>")
			irc_chat(name, " ")
			return
		end

		if string.find(msg, "catsrul3") then
			irc_chat(name, "Yes they do but don't tell them that, also pick a different password. :P")
			return
		end

		if countAlphaNumeric(words[3]) ~= string.len(words[3]) then
			irc_chat(name, "Your password can only contain letters and/or numbers.")
		else
			players[ircid].ircLogin = tmp.login
			players[ircid].ircPass = tmp.pass
			conn:execute("UPDATE players SET ircLogin = '" .. escape(tmp.login) .. "', ircPass = '" .. escape(tmp.pass) .. "' WHERE steam = " .. ircid)
			connBots:execute("UPDATE players SET ircAlias = '" .. escape(name) .. "', ircAuthenticated = 1 WHERE steam = " .. ircid)
			irc_chat(name, "You have set your new login. Test it now by typing login " .. tmp.login .. " pass " .. tmp.pass)
			irc_chat(name, " ")
		end

		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "say") then
		if players[ircid].ircAuthenticated == false then
			if requireLogin(name) then
				return
			end
		end

		msg = string.trim(string.sub(msg, 5))
		message("say " .. players[ircid].name .. "-irc: [i]" .. msg .. "[/i][-]")
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (string.find(words[1], "say") and (string.len(words[1]) == 5) and words[2] ~= nil) then
		if players[ircid].ircAuthenticated == false then
			if requireLogin(name) then
				return
			end
		end

		msg = string.sub(msg, string.len(words[1]) + 2)
		msg = string.trim(msg)

		if (msg ~= "") then
			Translate(ircid, msg, string.sub(words[1], 4), true)
		end

		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "command" and words[2] == "help") and (accessLevel(ircid) < 3) then
		if words[3] == nil then
			gmsg(server.commandPrefix .. "command help", ircid)
		else
			gmsg(server.commandPrefix .. "command help " .. words[3], ircid)
		end

		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "list" and words[2] == "help") and (accessLevel(ircid) < 3) then
		if words[3] == nil then
			gmsg(server.commandPrefix .. "list help", ircid)
		else
			gmsg(server.commandPrefix .. "list help " .. words[3], ircid)
		end

		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == nil) then --  and (accessLevel(ircid) < 3)
		irc_commands()
		gmsg(server.commandPrefix .. "help sections", ircid)
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == "server") and (accessLevel(ircid) < 3) then
		irc_HelpServer()
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == "donors") and (accessLevel(ircid) < 3) then
		irc_HelpDonors()
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == "csi") and (accessLevel(ircid) < 3) then
		irc_HelpCSI()
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == "watchlist") and (accessLevel(ircid) < 3) then
		irc_HelpWatchlist()
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == "bad" and words[3] == "items") and (accessLevel(ircid) < 3) then
		irc_HelpBadItems()
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == "announcements") and (accessLevel(ircid) < 3) then
		irc_HelpAnnouncements()
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == "commands") and (accessLevel(ircid) < 3) then
		irc_HelpCommands()
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] == "motd") and (accessLevel(ircid) < 3) then
		irc_HelpMOTD()
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "help" and words[2] ~= nil) then
		gmsg(server.commandPrefix .. "help " .. string.sub(msg, 6), ircid)
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "reset" and words[2] == "zones" and words[3] == nil) and (accessLevel(ircid) < 3) then
		irc_listResetZones(name)
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "nuke" or words[1] == "clear" and words[2] == "irc") or ((words[1] == "stop" or words[1] == "sotp" or words[1] == "stahp") and words[2] == nil) then
		conn:execute("DELETE FROM ircQueue WHERE name = '" .. name .. "'")
		irc_chat(channel, "IRC spam nuked for " .. name)

		if ircListItems == ircid then ircListItems = nil end

		if echoConsoleTo == name then
			echoConsole = nil
			echoConsoleTo = nil
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "nuke" or words[1] == "clear" or words[1] == "stop" and words[2] == "all" then
		conn:execute("DELETE FROM ircQueue")
		irc_chat(channel, "IRC spam nuked for everyone")

		ircListItems = nil
		echoConsole = nil
		echoConsoleTo = nil
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "rules") then
		if words[2] == nil then
			irc_chat(name, "The server rules are " .. server.rules)
			irc_chat(name, " ")
			return
		else
			if (accessLevel(ircid) < 3) then
				irc_chat(name, "To change the rules type set rules <new rules>")
				irc_chat(name, " ")
			end

			return
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "invite" and words[2] ~= nil) and (not server.ircPrivate or accessLevel(ircid) < 3) then
		name1 = string.trim(string.sub(msgLower, string.find(msgLower, "invite") + 7))
		pid = LookupPlayer(name1)

		if pid ~= nil then
			number = rand(10000)
			result = LookupPlayer(number, "code")

			while result ~= nil do
				number = rand(10000)
				result = LookupPlayer(number, "code")
			end

			players[pid].ircInvite = number

			if igplayers[pid] then
				message("pm " .. pid .. " HEY " .. players[pid].name .. "! You have an invite code for IRC! Reply with " .. server.commandPrefix .. "accept " .. number .. " or ignore it.")
			end

			conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. pid .. ", '" .. escape("You have an invite code for IRC! Reply with " .. server.commandPrefix .. "accept " .. number .. " or ignore it.") .. "')")
			irc_chat(name, "An IRC invite code has been sent to " .. players[pid].name)
			irc_chat(name, " ")
			return
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

-- ########### Staff only in this section ###########
	if (ircid == nil) then
		return
	end

	if (accessLevel(ircid) > 3) then
		return
	end

	if players[ircid].ircAuthenticated == false then
		if requireLogin(name) then
			return
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "sql" and words[2] == "select") and accessLevel(ircid) == 0 then
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

		irc_chat(name, " ")
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "set" and words[2] == "irc" and words[3] == "server") and accessLevel(ircid) == 0 then
		server.ircServer = string.sub(msg, string.find(msg, " server ") + 8)
		temp = string.split(server.ircServer, ":")
		server.ircServer = temp[1]
		server.ircPort = temp[2]

		conn:execute("UPDATE server SET ircServer = '" .. escape(server.ircServer) .. "', ircPort = '" .. escape(server.ircPort) .. "'")

		if botman.customMudlet then
			irc_chat(name, "The bot will now connect to the irc server at " .. server.ircServer .. ":" .. server.ircPort)
			irc_chat(name, " ")
			joinIRCServer()
			ircSaveSessionConfigs()
		else
			irc_chat(name, "You have set the irc server to " .. server.ircServer .. ":" .. server.ircPort)
			irc_chat(name, " ")
		end

		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "set" and words[2] == "server" and words[3] == "ip") and string.find(msg, "pass") and accessLevel(ircid) == 0 then
-- TODO:  Finish this.
		tmp = {}
		tmp.serverIP = string.sub(msg, string.find(msg, " ip ") + 4, string.find(msg, " pass ") - 1)
		tmp.split = string.split(tmp.serverIP, ":")
--		server.IP = tmp.split[1]
--		server.telnetPort = tmp.split[2]

-- dbug(tmp.serverIP)
-- dbug(tmp.split[1])
-- dbug(tmp.split[2])

		-- irc_chat(name, "The bot will now connect to the irc server at " .. server.ircServer .. ":" .. server.ircPort)
		-- irc_chat(name, " ")
		-- conn:execute("UPDATE server SET ircServer = '" .. escape(server.ircServer) .. "', ircPort = '" .. escape(server.ircPort) .. "'")

		-- tmp = chatvars.words[4]

		-- if tmp == nil then
			-- if (chatvars.playername ~= "Server") then
				-- message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]The server ip is required.[-]")
			-- else
				-- irc_chat(players[chatvars.ircid].ircAlias, "The server ip is required.")
			-- end
		-- else
			-- server.IP = tmp
			-- conn:execute("UPDATE server SET IP = '" .. escape(tmp) .. "'")

			-- if (chatvars.playername ~= "Server") then
				-- message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The server ip is now " .. tmp .. ".[-]")
			-- else
				-- irc_chat(players[chatvars.ircid].ircAlias, "The server ip is now " .. tmp)
			-- end
		-- end

		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "restart" and words[2] == "bot") then
		if botman.customMudlet then
			-- Mudlet will only automatically restart if you compiled TheFae's latest Mudlet and launched it from run-mudlet.sh with -r
			savePlayers()
			closeMudlet()
			return
		else
			irc_chat(name, "This command is not supported without the custom Mudlet which you can get here https://github.com/itsTheFae/FaesMudlet2")
			return
		end
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "check" and words[2] == "disk" and words[3] == nil then
		irc_reportDiskFree(name)
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "command" and words[2] == "prefix") then
		tmp = {}
		tmp.prefix = string.sub(msg, string.find(msg, "prefix") + 7)
		tmp.prefix = string.sub(tmp.prefix, 1, 1)

		if tmp.prefix == "\\" then
			irc_chat(server.ircMain, "The bot does not support commands using a \\ because it is a special character in Lua and will not display in chat.  Please choose another symbol.")
			return
		end

		if tmp.prefix ~= "" then
			server.commandPrefix = tmp.prefix
			conn:execute("UPDATE server SET commandPrefix = '" .. tmp.prefix .. "'")
			irc_chat(server.ircMain, "Ingame bot commands must now start with a " .. tmp.prefix)
			message("say [" .. server.chatColour .. "]Commands now begin with a " .. server.commandPrefix .. ". To use commands such as who type " .. server.commandPrefix .. "who.[-]")

			send("tcch " .. tmp.prefix)
		else
			server.commandPrefix = ""
			conn:execute("UPDATE server SET commandPrefix = ''")
			irc_chat(server.ircMain, "Ingame bot commands do not use a prefix and can be typed in public chat.")
			message("say [" .. server.chatColour .. "]Bot commands are now just text.  To use commands such as who simply type who.[-]")

			send("tcch")
		end

		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "test" and words[2] == "lottery" and words[3] == nil then
		drawLottery(ircid)
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "server" and words[2] == "settings" and words[3] == nil then
		irc_chat(name, "The bot's server settings are:")
		irc_chat(name, "Access level override: " .. server.accessLevelOverride)

		if server.allowBank then
			irc_chat(name, "Players can earn " .. server.moneyPlural)
		else
			irc_chat(name, "In-game money is disabled")
		end

		if server.allowGarbageNames then
			irc_chat(name, "Players can have non-alphanumeric names")
		else
			irc_chat(name, "Players with non-alphanumeric names will be kicked")
		end

		if server.allowGimme then
			irc_chat(name, "Gimme can be played")
		else
			irc_chat(name, "Gimme is disabled")
		end

		if server.allowLottery then
			irc_chat(name, "Daily lottery is running")
		else
			irc_chat(name, "Daily lottery is disabled")
		end

		if server.allowNumericNames then
			irc_chat(name, "Allow players to have numeric names")
		else
			irc_chat(name, "Kick players with numeric names")
		end

		if server.allowOverstacking then
			irc_chat(name, "Ignore inventory overstacking")
		else
			irc_chat(name, "Punish inventory overstacking")
		end

		if server.allowPhysics then
			irc_chat(name, "Physics is on")
		else
			irc_chat(name, "Physics is off")
		end

		if server.allowRapidRelogging then
			irc_chat(name, "Ignore players doing rapid relogging")
		else
			irc_chat(name, "Temp ban players doing rapid relogging")
		end

		if server.allowReboot then
			irc_chat(name, "Bot reboots the server")
		else
			irc_chat(name, "Bot never reboots the server")
		end

		if server.allowShop then
			irc_chat(name, "Shop is open")
		else
			irc_chat(name, "Shop is closed")
		end

		if server.allowTeleporting then
			irc_chat(name, "Players can teleport")
		else
			irc_chat(name, "Player teleports are disabled")
		end

		if server.allowWaypoints then
			irc_chat(name, "Players can use waypoints")
		else
			irc_chat(name, "Waypoints are disabled")
		end

		if server.announceTeleports then
			irc_chat(name, "Players teleporting is announced in public chat")
		else
			irc_chat(name, "Player teleports are silent")
		end

		irc_chat(name, "Base cooldown timer is " .. server.baseCooldown .. " seconds")
		irc_chat(name, "Default base protection size is " .. server.baseSize)
		irc_chat(name, "Blacklist response is " .. server.blacklistResponse)
		irc_chat(name, "Blocked countries: " .. server.blockCountries)
		irc_chat(name, "Bot is called " .. server.botName)
		irc_chat(name, "Server chat colour is " .. server.chatColour)

		if server.coppi then
			irc_chat(name, "Using Coppi's additions")
		else
			irc_chat(name, "Not using Coppi's additions")
		end

		if server.disableBaseProtection then
			irc_chat(name, "Base protection is disabled")
		else
			irc_chat(name, "Players can set base protection")
		end

		if server.enableRegionPM then
			irc_chat(name, "Admins and donors see region names as they travel")
		else
			irc_chat(name, "Region names are not shown")
		end

		if server.gimmePeace then
			irc_chat(name, "Gimme messages are PM's")
		else
			irc_chat(name, "Gimme messages are public")
		end

		if server.hardcore then
			irc_chat(name, "Players cannot use bot commands except for info commands and bot chats.")
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

		if botman.ignoreAdmins then
			irc_chat(name, "Admins are exempt from normal restrictions on players")
		else
			irc_chat(name, "Admins are treated like normal players for testing purposes")
		end

		irc_chat(name, "The bot's name on IRC is " .. server.ircBotName)
		irc_chat(name, "The IRC server's address is " .. server.ircServer)
		irc_chat(name, "Zombie kills are multiplied by " .. server.lotteryMultiplier .. " and added to the daily lottery")
		irc_chat(name, "The bot restricts player movement to " .. server.mapSize .. " from 0,0")
		irc_chat(name, "Max players is " .. server.maxPlayers)
		irc_chat(name, "Max server uptime before a reboot is " .. server.maxServerUptime .. " hours")
		irc_chat(name, "Max spawned zombies is " .. server.MaxSpawnedZombies)
		irc_chat(name, "The in-game money is called the " .. server.moneyName)
		irc_chat(name, "The message of the day is " .. server.MOTD)
		irc_chat(name, "New players are upgraded to regular players after " .. server.newPlayerTimer .. " minutes total playtime")
		irc_chat(name, "Northeast of 0,0 is " .. server.northeastZone)
		irc_chat(name, "Northwest of 0,0 is " .. server.northwestZone)
		irc_chat(name, "Minimum stack size to be considered overstacking is " .. server.overstackThreshold)
		irc_chat(name, "Players must wait " .. server.packCooldown .. " seconds after death before " .. server.commandPrefix .. "pack is available")

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

		irc_chat(name, "Base protection auto-expires " .. server.protectionMaxDays .. " real days after a players last play")
		irc_chat(name, "The server rules are " .. server.rules)
		irc_chat(name, "The server group is " .. server.serverGroup)
		irc_chat(name, "The shop will reset in " .. server.shopCountdown .. " real days")
		irc_chat(name, "Southeast of 0,0 is " .. server.southeastZone)
		irc_chat(name, "Southwest of 0,0 is " .. server.southwestZone)
		irc_chat(name, "The swear jar has " .. server.swearCash .. " " .. server.moneyPlural .. " in it")
		irc_chat(name, "The fine for swearing is " .. server.swearFine .. " " .. server.moneyPlural)

		if server.swearJar then
			irc_chat(name, "Players detected swearing are fined")
		else
			irc_chat(name, "Players can swear without penalty")
		end

		if server.coppi then
			irc_chat(name, "Using Coppi's Additions")
		end

		irc_chat(name, "Killing a zombie earns a player " .. server.zombieKillReward .. " " .. server.moneyPlural)
		irc_chat(name, " ")
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

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

		irc_chat(name, " ")
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

	if words[1] == "check" and words[2] == "dns" then
		if debug then dbug("debug ircmessage " .. msg) end
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

			irc_chat(name, "Checking DNS record for " .. pid .. " IP " .. number)
			CheckBlacklist(pid, number)
		end

		irc_chat(name, " ")
		return
	end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

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

			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if words[1] == "show" and words[2] == "inventory" then
			if words[3] == nil then
				irc_chat(name, "Full example.. show inventory player Joe xpos 100 zpos 200 days 2 range 50 item tnt qty 20")
				irc_chat(name, "You can grab the coords from any player by adding, near joe")
				irc_chat(name, "Defaults: days = 1, range = 100km, xpos = 0, zpos = 0")
				irc_chat(name, "Optional: player (or near) joe, days 1, hours 1, range 50, item tin, qty 10, xpos 0, zpos 0, session 1")
				irc_chat(name, " ")
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

			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

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

			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if words[1] == "add" and words[2] == "announcement" and words[3] ~= nil then
			if debug then dbug("debug ircmessage " .. msg) end
			msg = string.sub(msg, 17, string.len(msg))

			conn:execute("INSERT INTO announcements (message, startdate, enddate) VALUES ('" .. escape(msg) .. "'," .. os.date("%Y-%m-%d", os.time()) .. ",'2020-01-01')")

			irc_chat(name, "New announcement added.")
			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

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
			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "who" and words[2] == "visited") then
			if words[3] == nil then
				irc_chat(name, "See who visited a player location or base.")
				irc_chat(name, "Example with defaults:  who visited player smeg days 1 range 10 height 4")
				irc_chat(name, "Example with coords:  who visited x 0 y 100 z 0 height 5 days 1 range 20")
				irc_chat(name, "Another example:  who visited player smeg base")
				irc_chat(name, "Another example:  who visited bed smeg")
				irc_chat(name, "Setting hours will reset days to zero")
				irc_chat(name, "Defaults: days = 1 or hours = 0, range = 10")
				irc_chat(name, " ")
				return
			end

			tmp = {}
			tmp.days = 1
			tmp.hours = 0
			tmp.range = 10
			tmp.height = 5
			tmp.basesOnly = "player"

			for i=3,wordCount,1 do
				if words[i] == "player" or words[i] == "bed" then
					tmp.name = words[i+1]
					tmp.steam = LookupPlayer(tmp.name)

					if tmp.steam and words[i] == "player" then
						tmp.player = true
						tmp.x = players[tmp.steam].xPos
						tmp.y = players[tmp.steam].yPos
						tmp.z = players[tmp.steam].zPos
					end

					if tmp.steam and words[i] == "bed" then
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

			if (tmp.basesOnly == "base") and tmp.steam then
				if players[tmp.steam].homeX ~= 0 and players[tmp.steam].homeZ ~= 0 then
					irc_chat(name, "Players who visited within " .. tmp.range .. " metres of base 1 of " .. players[tmp.steam].name .. " at " .. players[tmp.steam].homeX .. " " .. players[tmp.steam].homeY .. " " .. players[tmp.steam].homeZ .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
					dbWho(name, players[tmp.steam].homeX, players[tmp.steam].homeY, players[tmp.steam].homeZ, tmp.range, tmp.days, tmp.hours, tmp.height)
				else
					irc_chat(name, "Player " .. players[tmp.steam].name .. " does not have a base set.")
				end

				if players[tmp.steam].home2X ~= 0 and players[tmp.steam].home2Z ~= 0 then
					irc_chat(name, " ")
					irc_chat(name, "Players who visited within " .. tmp.range .. " metres of base 2 of " .. players[tmp.steam].name .. " at " .. players[tmp.steam].home2X .. " " .. players[tmp.steam].home2Y .. " " .. players[tmp.steam].home2Z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
					dbWho(name, players[tmp.steam].home2X, players[tmp.steam].home2Y, players[tmp.steam].home2Z, tmp.range, tmp.days, tmp.hours, tmp.height)
				end
			end

			if tmp.basesOnly == "player" and tmp.steam then
				if tmp.player then
					irc_chat(name, "Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. " at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
				end

				if tmp.bed then
					irc_chat(name, "Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. "'s bed at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
				end

				dbWho(name, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height)
			end

			if not tmp.steam then
				irc_chat(name, "Players who visited within " .. tmp.range .. " metres of " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height)
				dbWho(name, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height)
			end

			irc_chat(name, " ")

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "pay") then
			name1 = words[2]
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			players[pid].cash = players[pid].cash + number
			message("pm " .. pid .. " " .. players[ircid].name .. " just paid you " .. number .. " " .. server.moneyPlural .. "!  You now have " .. players[pid].cash .. " " .. server.moneyPlural .. "!  KA-CHING!!")

			msg = "You just paid " .. number .. " " .. server.moneyPlural .. " to " .. players[pid].name .. " giving them a total of " .. players[pid].cash .. " " .. server.moneyPlural .. "."
			irc_chat(name, msg)
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "claims") then
			if debug then dbug("debug ircmessage " .. msg) end
			if players[ircid].ircAuthenticated == false then
				if requireLogin(name) then
					return
				end
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
  					irc_chat(name, msg)
					return
				end
			end


			if pid == nil then
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

			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "cmd") then
			msg = string.trim(string.sub(msg, string.find(msgLower, "cmd") + 4))
			gmsg(msg, ircid)
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "pm") then
			pid = LookupPlayer(words[2])

			if pid ~= nil then
				msg = string.sub(msg, string.find(msg, words2[2], nil, true) + string.len(words2[2]) + 1)

				if igplayers[pid] then
					message("pm " .. pid .. " " .. name .. "-irc: [i]" .. msg .. "[-]")
					irc_chat(name, "pm sent to " .. players[pid].name .. " you said " .. msg)
				else
					conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (" .. ircid .. "," .. pid .. ", '" .. escape(msg) .. "')")
					irc_chat(name, "Mail sent to " .. players[pid].name .. " you said " .. msg)
					irc_chat(name, "They will receive your message when they join the server.")
				end
			else
				irc_chat(name, "No player called " .. words[2] .. " found.")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

-- ************************************************************************************************8
		if (words[1] == "con") and accessLevel(ircid) == 0 then
			msg = string.lower(string.trim(string.sub(msg, string.find(msgLower, "con") + 4)))
			send(msg)

			if string.sub(msg, 1, 4) == "help" then
				echoConsoleTo = name
				tempTimer( 2, [[ echoConsoleTo = nil ]] )
				tempTimer( 2, [[ echoConsole = nil ]] )
			end

			if msg == "se" or msg == "le" or msg == "ban list" or msg == "gg" or msg == "version" or string.sub(msg, 1, 3) == "li " or string.sub(msg, 1, 3) == "si " or string.sub(msg, 1, 3) == "llp" then
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

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "villagers" and words[2] == nil) then
			irc_chat(name, "The following players are villagers:")
			for k, v in pairs(villagers) do
				tmp = v.village .. " " .. players[k].name

				if locations[v.village].mayor == k then
					tmp = text .. " (the mayor of " .. v.village .. ")"
				end

				irc_chat(name, tmp)
			end

			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "base") and (words[2] == "cooldown" or words[2] == "timer") then
			if words[3] == nil then
				irc_chat(name, server.commandPrefix .. "base can only be used once every " .. (server.baseCooldown / 60) .. " minutes for players and " .. math.floor((server.baseCooldown / 60) / 2) .. " minutes for donors.")
				irc_chat(name, " ")
				return
			end

			if words[3] ~= nil then
				server.baseCooldown = tonumber(words[3])
				irc_chat(name, "The base cooldown timer is now " .. (server.baseCooldown / 60) .. " minutes for players and " .. math.floor((server.baseCooldown / 60) / 2) .. " minutes for donors.")
				irc_chat(name, " ")

				conn:execute("UPDATE server SET baseCooldown = 0")
				return
			end
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "set" and words[2] == "rules") then
			if words[3] ~= nil then
				server.rules = string.sub(msg, string.find(msgLower, "set rules") + 9)
				irc_chat(name, "New server rules recorded: " .. server.rules)
				irc_chat(name, " ")

				conn:execute("UPDATE server SET rules = '" .. escape(server.rules) .. "'")
				return
			end
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "motd") then
			if words[2] == nil then
				irc_chat(name, "MOTD is " .. server.MOTD)
				irc_chat(name, " ")
				return
			end

			if words[2] == "delete" or words[2] == "clear" then
				server.MOTD = nil
				irc_chat(name, "Message of the day has been deleted.")
				irc_chat(name, " ")

				conn:execute("UPDATE server SET MOTD = ''")
				return
			end

			irc_chat(name, "To change the MOTD type set motd <new message of the day>")
			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "set" and words[2] == "motd") then
			if words[3] ~= nil then
				server.MOTD = string.sub(msg, string.find(msgLower, "set motd") + 9)
				irc_chat(name, "New message of the day recorded. " .. server.MOTD)
				irc_chat(name, " ")

				conn:execute("UPDATE server SET MOTD = '" .. escape(server.MOTD) .. "'")
				return
			end
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "list") and (words[2] == "tables") and (words[3] == nil) and (accessLevel(ircid) == 0) then
			irc_ListTables()
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "show") and (words[2] == "table") and (words[3] ~= nil) and (accessLevel(ircid) == 0) then
			irc_chat(name, "The " .. words[3] .." table: ")

			if string.lower(words[3]) == "server" then
				for k, v in pairs(server) do
					if not string.find(string.lower(k),"pass") then
						irc_chat(name, k .. "," .. tostring(v))
					end
				end

				irc_chat(name, " ")
				return
			end

			if string.lower(words[3]) == "botman" then
				for k, v in pairs(botman) do
					irc_chat(name, k .. "," .. tostring(v))
				end

				irc_chat(name, " ")
				return
			end

			if string.lower(words[3]) == "locations" then
				for k, v in pairs(locations) do
					irc_chat(name, "Location " .. k)
					irc_chat(name, " ")

					for n,m in pairs(locations[k]) do
						irc_chat(name, n .. "," .. tostring(m))
					end

					irc_chat(name, " ")
				end
			end

			if string.lower(words[3]) == "hotspots" then
				for k, v in pairs(hotspots) do
					irc_chat(name, "Hotspot " .. k)
					irc_chat(name, " ")

					for n,m in pairs(hotspots[k]) do
						irc_chat(name, n .. "," .. tostring(m))
					end

					irc_chat(name, " ")
				end
			end

			if string.lower(words[3]) == "teleports" then
				for k, v in pairs(teleports) do
					irc_chat(name, "Teleport " .. k)
					irc_chat(name, " ")

					for n,m in pairs(teleports[k]) do
						irc_chat(name, n .. "," .. tostring(m))
					end

					irc_chat(name, " ")
				end
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "reset") and (words[2] == "bot") and (accessLevel(ircid) == 0) then
			if resetbotCount == nil then resetbotCount = 0 end

			if tonumber(resetbotCount) < 1 then
				resetbotCount = tonumber(resetbotCount) + 1
				irc_chat(name, "ALERT! Only do this after a server wipe!  To reset me repeat the reset bot command again.")
				irc_chat(name, " ")
			end

			ResetBot()
			resetbotCount = 0

			irc_chat(name, "I have been reset.  All bases, inventories etc are forgotten, but not the players.")
			irc_chat(name, " ")
			return
		else
			resetbotCount = 0
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if words[1] == "stop" and words[2] == "translating" and words[3] ~= nil then
			name1 = string.sub(msg, string.find(msgLower, "translating") + 11)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				players[pid].ircTranslate = nil
				players[pid].translate = nil
				irc_chat(name, "Chat from " .. players[pid].name .. " will not be translated")
				irc_chat(name, " ")

				conn:execute("UPDATE players SET translate = 0, ircTranslate = 0 WHERE steam = " .. pid)
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, " ")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if words[1] == "translate" and words[2] ~= nil then
			name1 = string.sub(msg, string.find(msgLower, "translate") + 10)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				players[pid].translate = true
				irc_chat(name, "Chat from " .. players[pid].name .. " will be translated in-game")
				irc_chat(name, " ")

				conn:execute("UPDATE players SET translate = 1 WHERE steam = " .. pid)
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, " ")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if words[1] == "stealth" and words[2] == "translate" and words[3] ~= nil then
			name1 = string.sub(msg, string.find(msgLower, "translate") + 10)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				players[pid].ircTranslate = true
				irc_chat(name, "Chat from " .. players[pid].name .. " will be translated to irc only")
				irc_chat(name, " ")

				conn:execute("UPDATE players SET ircTranslate = 1 WHERE steam = " .. pid)
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, " ")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "open" and words[2] == "shop") then
			server.allowShop = true

			irc_chat(name, "Players can use the shop and play in the lottery.")
			irc_chat(name, " ")

			conn:execute("UPDATE server SET allowShop = 1")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "close" and words[2] == "shop") then
			server.allowShop = false

			irc_chat(name, "Only staff can use the shop.")
			irc_chat(name, " ")

			conn:execute("UPDATE server SET allowShop = 0")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "shop" and words[2] == "variation" and words[3] ~= nil) then
			LookupShop(words[3])

			irc_chat(name, "You have changed the price variation for " .. shopItem .. " to " .. words2[4])
			irc_chat(name, " ")

			conn:execute("UPDATE shop SET variation = " .. tonumber(words2[4]) .. " WHERE item = '" .. escape(shopItem) .. "'")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "shop" and words[2] == "special" and words[3] ~= nil) then
			LookupShop(words[3], true)

			if shopItem == "" then
				irc_chat(name, "The item " .. words[3] .. " does not exist.")
				return
			end

			irc_chat(name, "You have changed the special for " .. shopItem .. " to " .. words2[4])
			irc_chat(name, " ")

			conn:execute("UPDATE shop SET special = " .. tonumber(words2[4]) .. " WHERE item = '" .. escape(shopItem) .. "'")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "shop" and words[2] == "price" and words[3] ~= nil) then
			LookupShop(words[3], true)

			if shopItem == "" then
				irc_chat(name, "The item " .. words[3] .. " does not exist.")
				return
			end

			irc_chat(name, "You have changed the price for " .. shopItem .. " to " .. words2[4])
			irc_chat(name, " ")

			conn:execute("UPDATE shop SET price = " .. tonumber(words2[4]) .. " WHERE item = '" .. escape(shopItem) .. "'")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "shop" and words[2] == "max" and words[3] ~= nil) then
			LookupShop(words[3], true)

			if shopItem == "" then
				irc_chat(name, "The item " .. words[3] .. " does not exist.")
				return
			end

			irc_chat(name, "You have changed the max stock level for " .. shopItem .. " to " .. words[4])
			irc_chat(name, " ")

			conn:execute("UPDATE shop SET maxStock = " .. tonumber(words2[4]) .. " WHERE item = '" .. escape(shopItem) .. "'")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "shop" and words[2] == "restock" and words[3] ~= nil) then
			LookupShop(wordsOld[3], true)
			shopStock = tonumber(words2[4])

			if shopItem == "" then
				irc_chat(name, "The item " .. wordsOld[3] .. " does not exist.")
				return
			end

			if (shopStock < 0) then
				shopStock = -1
				irc_chat(name, shopItem .. " now has unlimited stock")
			else
				irc_chat(name, "There are now " .. shopStock .. " of " .. shopItem .. " for sale.")
			end

			conn:execute("UPDATE shop SET stock = " .. shopStock .. " WHERE item = '" .. escape(shopItem) .. "'")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

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
				return
			end

			irc_chat(name, "You added or updated the category " .. words[4] .. ".")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "shop" and words[2] == "remove" and words[3] == "category") then
			if not shopCategories[words[4]] then
				irc_chat(name, "The category " .. words[4] .. " does not exist.")
				return
			end

			shopCategories[words[4]] = nil
			conn:execute("DELETE FROM shopCategories WHERE category = '" .. escape(words[4]) .. "'")
			conn:execute("UPDATE shop SET category = '' WHERE category = '" .. escape(words[4]) .. "')")

			irc_chat(name, "You removed the " .. words[4] .. " category from the shop.  Any items using it now have no category.")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

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
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "inv") then
			tmp = {}
			tmp.name = name
			tmp.playerID = string.trim(string.sub(msg, string.find(msgLower, "inv") + 4))
			tmp.playerID = LookupPlayer(tmp.playerID)

			if (tmp.playerID ~= nil) then
				irc_NewInventory(tmp)
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "list" and words[2] == "villagers" and words[3] ~= nil) then
			name1 = string.sub(msg, string.find(msgLower, "villagers") + 10)
			name1 = string.trim(name1)
			pid = LookupVillage(name1)

			if (pid ~= nil) then
				irc_params.pid = pid
				irc_params.pname = players[pid].name
				irc_ListVillagers()
			else
				irc_chat(name, "No village found matching " .. name1)
				irc_chat(name, " ")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if words[1] == "list" and (words[2] == "bases" or words[3] == "bases") then
			pid = nil
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

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "add" and words[2] == "bad" and words[3] == "item" and words[4] ~= nil and accessLevel(ircid) == 0) then
			name1 = wordsOld[4]

			-- add the bad item to badItems table
			badItems[name1] = {}

			conn:execute("INSERT INTO badItems (item) VALUES ('" .. escape(name1) .. "')")

			irc_chat(name, name1 .. " has been added to the bad items list.")
			irc_chat(name, " ")

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "remove" and words[2] == "bad" and words[3] == "item" and words[4] ~= nil and accessLevel(ircid) == 0) then
			name1 = wordsOld[4]

			-- remove the bad item from the badItems table
			badItems[name1] = nil

			conn:execute("DELETE FROM badItems WHERE item = '" .. escape(name1) .. "'")

			irc_chat(name, name1 .. " has been removed from the bad items list.")
			irc_chat(name, " ")

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "near") then
			if words[2] == nil then
				irc_chat(name, "Lists players, bases and locations near a player or coordinate.")
				irc_chat(name, "Usage: near player <name>")
				irc_chat(name, "optional: range <number>")
				irc_chat(name, "optional: Instead of player use xpos <number> zpos <number>")

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
					irc_chat(name, "No player found matching " .. name1)
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

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "info" and words[2] ~= nil) then
			name1 = string.sub(msg, string.find(msgLower, "info") + 5)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if debug then dbug("debug ircmessage " .. name1) end
			if debug then dbug("debug ircmessage " .. pid) end

			if (pid ~= nil) then
				irc_params.pid = pid
				irc_params.pname = players[pid].name

				irc_PlayerShortInfo()
				irc_friends()
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, " ")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "add" and words[2] == "donor" and words[3] ~= nil and owners[ircid]) then
			name1 = string.sub(msg, string.find(msgLower, "donor") + 6)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- update the player record
				players[pid].donor = true
				irc_chat(name, players[pid].name .. " is now a donor.")
				irc_chat(name, " ")

				conn:execute("UPDATE players SET donor = 1 WHERE steam = " .. pid)
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "remove" and words[2] == "donor" and words[3] ~= nil and owners[ircid]) then
			name1 = string.sub(msg, string.find(msgLower, "donor") + 6)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- update the player record
				players[pid].donor = false
				irc_chat(name, players[pid].name .. " is no longer a donor.")
				irc_chat(name, " ")

				conn:execute("UPDATE players SET donor = 0 WHERE steam = " .. pid)
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "add" and words[2] == "owner" and words[3] ~= nil and owners[ircid]) then
			name1 = string.sub(msg, string.find(msgLower, "owner") + 6)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- add the steamid to the owners table
				owners[pid] = {}
				irc_chat(name, players[pid].name .. " has been added as a server owner.")
				irc_chat(name, " ")

				send("admin add " .. pid .. " 0")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "remove" and words[2] == "owner" and words[3] ~= nil and owners[ircid]) then
			name1 = string.sub(msg, string.find(msgLower, "owner") + 6)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- remove the steamid from the owners table
				owners[pid] = nil
				irc_chat(name, players[pid].name .. " is no longer a server owner.")
				irc_chat(name, " ")

				send("admin remove " .. pid)
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "add" and words[2] == "admin" and words[3] ~= nil and owners[ircid]) then
			name1 = string.sub(msg, string.find(msgLower, "admin") + 6)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- add the steamid to the admins table
				admins[pid] = {}
				irc_chat(name, players[pid].name .. " has been added as a server admin.")
				irc_chat(name, " ")

				send("admin add " .. pid .. " 1")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "remove" and words[2] == "admin" and words[3] ~= nil and accessLevel(ircid) == 0) then
			name1 = string.sub(msg, string.find(msgLower, "admin") + 6)
			name1 = string.trim(name1)

			pid = LookupPlayer(name1)

			if pid ~= nil then
				-- remove the steamid from the admins table
				admins[pid] = nil
				irc_chat(name, players[pid].name .. " is no longer a server admin.")
				irc_chat(name, " ")

				send("admin remove " .. pid)
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "permaban") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "permaban") + 9))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				banPlayer(pid, "10 years", "Permanent ban", ircid)

				irc_chat(name, name1 .. " has been banned for 10 years.")
				irc_chat(name, " ")

				conn:execute("UPDATE players SET permanentBan = 1 WHERE steam = " .. pid)
				players[pid].permanentBan = true
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, " ")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "remove" and words[2] == "permaban") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "permaban") + 9))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				conn:execute("UPDATE players SET permanentBan = 0 WHERE steam = " .. pid)
				send("ban remove " .. pid)
				players[pid].permanentBan = false

				irc_chat(name, "Ban lifted for player " .. name1)
				irc_chat(name, " ")
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, " ")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

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
			if (pid ~= nil) then
				players[pid].ircLogin = tmp.login
				players[pid].ircPass = tmp.pass

				irc_chat(name, players[pid].name .. " is now authorised to talk to ingame players")
				irc_chat(name, " ")

				conn:execute("UPDATE players SET ircLogin = '" .. escape(tmp.login) .. "', ircPass = '" .. escape(tmp.pass) .. "' WHERE steam = " .. pid)
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "player" and string.find(msgLower, "unfriend")) then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, "unfriend") - 1))
			name2 = string.trim(string.sub(msg, string.find(msgLower, "unfriend") + 9))

			pid = LookupPlayer(name1)
			if (pid ~= nil) then
				irc_params.pid = pid
				pid = LookupPlayer(name2)
				if (pid ~= nil) then
					irc_params.pid2 = pid
					irc_unfriend()
				else
					irc_chat(name, "No player found matching " .. name2)
					irc_chat(name, " ")
				end
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, " ")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "player" and string.find(msgLower, "friend")) then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7, string.find(msgLower, "friend") - 1))
			name2 = string.trim(string.sub(msg, string.find(msgLower, "friend") + 7))

			pid = LookupPlayer(name1)
			if (pid ~= nil) then
				irc_params.pid = pid
				pid = LookupPlayer(name2)
				if (pid ~= nil) then
					irc_params.pid2 = pid
					irc_friend()
				else
					irc_chat(name, "No player found matching " .. name2)
					irc_chat(name, " ")
				end
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, " ")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "friends") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "friends") + 8))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				irc_params.pid = pid
				irc_params.pname = players[pid].name
				irc_friends()
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, " ")
			end
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "players" and words[2] == nil) and accessLevel(ircid) == 0 then
			irc_listAllPlayers(name)
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "player") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "player") + 7))
			pid = LookupOfflinePlayer(name1)

			if (pid ~= nil) then
				if (players[pid] ~= nil) then
					irc_chat(name, "Player record of: " .. players[pid].name)
					for k, v in pairs(players[pid]) do
						if k ~= "ircPass" then
							cmd = k .. "," .. tostring(v)
							irc_chat(name, cmd)
						end
					end
				else
					irc_chat(name, " ")
					irc_chat(name, "I do not know a player called " .. name1)
				end

				irc_chat(name, " ")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "igplayer") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "igplayer") + 9))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				irc_params.pid = pid
				irc_params.pname = players[pid].name
				irc_IGPlayerInfo()
			end
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "watch") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "watch") + 6))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				players[pid].watchPlayer = true

				conn:execute("UPDATE players SET watchPlayer = 1 WHERE steam = " .. pid)

				irc_chat(name, "Now watching player " .. players[pid].name)
				irc_chat(name, " ")
			end
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "stop" and words[2] == "watching") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "watching") + 9))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				players[pid].watchPlayer = false

				conn:execute("UPDATE players SET watchPlayer = 0 WHERE steam = " .. pid)

				irc_chat(name, "No longer watching player " .. players[pid].name)
				irc_chat(name, " ")
			else
				irc_chat(name, "No player matched " .. name1)
				irc_chat(name, " ")
			end
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "donors" and words[2] == nil) then
			tmp = {}
			tmp.list = {}
			tmp.count = 0

			irc_chat(name, "These are all the donors on record:")

		    for i in pairs(players) do
				if (players[i].donor) then
					table.insert(tmp.list, players[i].name)
					tmp.count = tmp.count + 1
				end
			end

			table.sort(tmp.list)

		    for k, v in ipairs(tmp.list) do
				tmp.steam = LookupOfflinePlayer(v, "all")

				diff = os.difftime(players[tmp.steam].donorExpiry, os.time()) -- diff = os.difftime(players[tmp.steam].donorExpiry, os.time(dateNow))
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
					irc_chat(name, "steam: " .. tmp.steam .. " id: " .. string.format("%-8d", players[tmp.steam].id) .. " name: " .. players[tmp.steam].name .. " *** expired ***")
				else
					irc_chat(name, "steam: " .. tmp.steam .. " id: " .. string.format("%-8d", players[tmp.steam].id) .. " name: " .. players[tmp.steam].name .. " expires in " .. days .. " days " .. hours .. " hours " .. minutes .." minutes")
				end
			end

			irc_chat(name, tmp.count .. " current donors")
			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "teleports" and words[2] == nil) then
			irc_chat(name, "List of teleports:")

			for k, v in pairs(teleports) do
				if (v.public == true) then
					public = "public"
				else
					public = "private"
				end

				irc_chat(name, v.name .. " " .. public)
			end

			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "list" and words[2] == "bad" and words[3] == "items") then
			irc_chat(name, "I scan for these uncraftable items in inventories:")

			for k, v in pairs(badItems) do
				irc_chat(name, k)
			end

			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

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

			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "li" and words[2] ~= nil) then
			ircListItems = ircid
			send("li " .. words[2])
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "status") then
			name1 = string.trim(string.sub(msg, string.find(msgLower, "status") + 7))
			pid = LookupPlayer(name1)

			if (pid ~= nil) then
				irc_params.pid = pid
				irc_params.pname = players[pid].name
				irc_playerStatus()
			else
				irc_chat(name, "No player found matching " .. name1)
				irc_chat(name, " ")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "shop" and words[2] == "add" and words[3] == "item" and words[4] ~= nil) then
			LookupShop(wordsOld[4], "all")

			if shopCode ~= "" then
				irc_chat(name, "The item " .. shopCode .. " already exists.")
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

				irc_chat(name, "You added " .. wordsOld[4] .. " to the shop.  You will need to add any missing info such as code, category, price and quantity.")

				conn:execute("INSERT INTO shop (item, category, stock, maxStock, price) VALUES ('" .. escape(wordsOld[4]) .. "','" .. escape(class) .. "'," .. stock .. "," .. stock .. "," .. price .. ")")

				reindexShop(class)
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "shop" and words[2] == "remove" and words[3] == "item") then
			LookupShop(wordsOld[4], "all")

			if shopCode ~= "" then
				conn:execute("DELETE FROM shop WHERE item = '" .. escape(shopItem) .. "'")
				reindexShop(shopCategory)
				irc_chat(name, "You removed the item " .. shopItem .. " from the shop.")
			else
				irc_chat(name, "The item " .. wordsOld[4] .. " does not exist.")
			end

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "add" and words[2] == "command" and accessLevel(ircid) < 3) then
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
				irc_chat(name, "Correct syntax is: add command <command> access <99 to 0> message <private message>")
			end

			-- add the custom message to table customMessages
			conn:execute("INSERT INTO customMessages (command, message, accessLevel) VALUES ('" .. escape(cmd) .. "','" .. escape(tmp) .. "'," .. number .. ") ON DUPLICATE KEY UPDATE accessLevel = " .. number .. ", message = '" .. escape(tmp) .. "'")

			-- reload from the database
			loadCustomMessages()

			irc_chat(name, cmd .. " has been added to custom commands.")
			irc_chat(name, " ")

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "remove" and words[2] == "command" and accessLevel(ircid) < 3) then
			cmd = words[3]

			-- remove the custom message from table customMessages
			conn:execute("DELETE FROM customMessages WHERE command = '" .. escape(cmd) .. "'")

			-- remove it from the Lua table
			customMessages[cmd] = nil

			irc_chat(name, cmd .. " has been removed from custom commands.")
			irc_chat(name, " ")

			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "blacklist" and words[2] == "add" and accessLevel(ircid) < 3) then
			pid = LookupPlayer(words[3])

			if pid ~= nil then
				banPlayer(pid, "10 years", "blacklisted", ircid)
				irc_chat(name, "Player " .. pid  .. " " .. players[pid].name .. " has been blacklisted 10 years.")
				return
			else
				banPlayer(words[3], "10 years", "blacklisted", ircid)
				irc_chat(name, "Player " .. pid .. " has been blacklisted 10 years.")
				return
			end
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "blacklist" or words[1] == "ban" and words[2] == "remove" and accessLevel(ircid) < 3) then
			pid = LookupPlayer(words[3])
			if pid ~= nil then
				send("ban remove " .. pid)
				irc_chat(name, "Player " .. pid  .. " " .. players[pid].name .. " has been unbanned.")
				return
			end
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if words[1] == "list" and string.find(words[2], "event") then
			if words[3] == nil then
				-- display command help
				irc_chat(name, "Several events are logged and can be searched with list event. Select from any of the following or add a player name or steam ID.")
				irc_chat(name, "eg. list event ban. Matching events in the last day are displayed.  To see more days add a number eg. list event ban 5")
				irc_chat(name, " ")

				cursor,errorString = conn:execute("SELECT DISTINCT type from events order by type")
				row = cursor:fetch({}, "a")
				while row do
					irc_chat(name, row.type)
					row = cursor:fetch(row, "a")
				end

				irc_chat(name, " ")
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

			if pid == nil then
				pid = 0
			end

			irc_server_event(name, words[3], pid, number)
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if words[1] == "search" and words[2] == "player" then
			irc_chat(name, "Players matching " .. words[3])

			cursor,errorString = conn:execute("SELECT id, steam, name FROM players where name like '%" .. words[3] .. "%'")
			row = cursor:fetch({}, "a")
			while row do
				irc_chat(name, row.id  .. " " .. row.steam .. " " .. row.name)
				row = cursor:fetch(row, "a")
			end

			irc_chat(name, " ")
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "add" and words[2] == "proxy") then
			if words[3] == nil then
				irc_chat(name, "I do a dns lookup on every player that joins. You can ban or exile players found using a known proxy.")
				irc_chat(name, "Staff and whitelisted players are ignored.")
				irc_chat(name, "Command example: add proxy YPSOLUTIONS action ban.  Action is optional and can be ban or exile.  Ban is the default.")
				irc_chat(name, "To remove a proxy type remove proxy YPSOLUTIONS.  To list proxies type list proxies.")
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
				return
			end

			-- add the proxy to table proxies
			conn:execute("INSERT INTO proxies (scanString, action, hits) VALUES ('" .. escape(proxy) .. "','" .. escape(action) .. "',0)")

			if ircid == Smegz0r and botman.db2Connected then
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
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "remove" and words[2] == "proxy") then
			proxy = string.sub(msg, string.find(msg, "proxy") + 6)
			proxy = string.trim(string.upper(proxy))

			if proxy == nil then
				irc_chat(name, "The proxy is required.")
				irc_chat(name, "Command example: remove proxy YPSOLUTIONS.")
				return
			end

			-- remve the proxy from the proxies table
			conn:execute("DELETE FROM proxies WHERE scanString = '" .. escape(proxy) .. "'")

			-- and remove it from the Lua table proxies
			proxies[proxy] = nil
			irc_chat(name, "You have removed the proxy " .. proxy)
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

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

			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if words[1] == "list" and words[2] == "regions" then
			conn:execute("DELETE FROM list")

			irc_chat(name, "The following regions have player bases in them.")

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
				irc_chat(name, row.thing)
				row = cursor:fetch(row, "a")
			end

			conn:execute("DELETE FROM list")

			irc_chat(name, " ")
			irc_chat(name, "The following regions have locations in them.")

			for k,v in pairs(locations) do
				temp = getRegion(v.x, v.z)
					conn:execute("INSERT INTO list (thing) VALUES ('" .. temp .. "')")
			end

			cursor,errorString = conn:execute("SELECT * FROM list order by thing")
			row = cursor:fetch({}, "a")
			while row do
				irc_chat(name, row.thing)
				row = cursor:fetch(row, "a")
			end

			conn:execute("DELETE FROM list")

			irc_chat(name, " ")
			return
		end

	if (debug) then dbug("debug irc message line " .. debugger.getinfo(1).currentline) end

		if (words[1] == "list" and words[2] == "restricted" and words[3] == "items") then
			irc_chat(name, "I scan for these restricted items in inventories:")

			for k, v in pairs(restrictedItems) do
				irc_chat(name, k)
			end

			irc_chat(name, " ")
			return
		end

	if debug then dbug ("debug ircmessage end") end
end

