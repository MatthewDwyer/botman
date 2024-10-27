--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_info()
	local debug, xdir, zdir, dist, x, z, diff, days, hours, minutes, result, time, werds, word, cmd, direction, help, tmp
	local shortHelp = false

	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false -- should be false unless testing

	calledFunction = "gmsg_info"
	result = false
	tmp = {}
	tmp.topic = "info"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## info command functions ##################

	local function cmd_BotInfo()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}bot info"
			help[2] = "Displays info about the bot."

			tmp.command = help[1]
			tmp.keywords = "information,bot"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if chatvars.words[1] == "bot" and chatvars.words[2] == "info" and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "bot" and chatvars.words[2] == "info" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				-- bot name
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot is called " .. server.botName .. "[-]")

				-- API or telnet
				if server.useAllocsWebAPI then
					if botman.APIOffline then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]API is offline.[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot is using telnet.[-]")
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]API is online.[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot is using Alloc's web API.[-]")
					end
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot is using telnet.[-]")
				end

				if botman.telnetOffline then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Telnet is offline.[-]")
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Telnet is online.[-]")
				end

				-- code branch
				if server.updateBranch ~= '' then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The code branch is " .. server.updateBranch .. "[-]")
				end

				-- code version
				if server.botVersion ~= '' then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot version is " .. server.botVersion .. "[-]")
				end

				-- bot updates enabled or not
				if server.updateBot then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot checks for new code daily.[-]")
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Bot updates are set to happen manually using the {#}update code command[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListNewPlayers()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}new players {optional number (days)"
			help[2] = "List the new players and basic info about them in the last day or more."

			tmp.command = help[1]
			tmp.keywords = "list,new,players"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "new") or string.find(chatvars.command, "play") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "new" and chatvars.words[2] == "players") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				number = 86400
			else
				number = chatvars.number * 86400
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players in the last " .. math.floor(number / 86400) .. " days:[-]")
			else
				irc_chat(chatvars.ircAlias, "New players in the last " .. math.floor(number / 86400) .. " days:")
			end

			cursor,errorString = conn:execute("SELECT * FROM events where timestamp >= '" .. os.date('%Y-%m-%d %H:%M:%S', os.time() - number).. "' and type = 'new player' order by timestamp desc")
			row = cursor:fetch({}, "a")

			while row do
				msg = "time: " .. row.serverTime .. " steam: " .. row.steam .. " id: " .. string.format("%8d", players[row.steam].id) .. " name: " .. players[row.steam].name .. " at [ " .. players[row.steam].xPos .. " " .. players[row.steam].yPos .. " " .. players[row.steam].zPos .. " ] " .. players[row.steam].country
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

				cursor2,errorString = conn:execute("SELECT * FROM bans WHERE steam = '" .. row.steam .. "'")
				if cursor2:numrows() > 0 then
					msg = msg .. " BANNED"
				end

				if players[row.steam].timeout == true then
					msg = msg .. " TIMEOUT"
				end

				if players[row.steam].country == "CN" or players[row.steam].country == "HK" then
					msg = msg .. " Chinese"
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. msg .. "[-]")
				else
					irc_chat(chatvars.ircAlias, msg)
				end

				row = cursor:fetch(row, "a")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SeenPlayer()
		local playerName, isArchived, lastSeenMessage, r

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}seen {player name}"
			help[2] = "Reports when the player was last on the server."

			tmp.command = help[1]
			tmp.keywords = "seen,player,when,last"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "see") or string.find(chatvars.command, "play") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "seen") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "seen ") + 5)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == "0" then
				id = LookupArchivedPlayer(pname)

				if not (id == "0") then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Sorry I don't know a player called " .. pname .. ". Check your spelling.[-]")
					else
						irc_chat(chatvars.ircAlias, "Sorry I don't know a player called " .. pname .. ". Check your spelling.")
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if (igplayers[id]) then
				if (chatvars.playername ~= "Server") then
					if chatvars.playerid == id then
						r = randSQL(10)
						if r == 1 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]YOU are playing right now.[-]") end
						if r == 2 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I dunno, why don't you ask yourself that?[-]") end
						if r == 3 then message("say ATTENTION! Attention everyone.  Have you seen " .. chatvars.playername .. "? " .. chatvars.playername .. " seems a little lost.[-]") end
						if r == 4 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No. No I have not.[-]") end
						if r == 5 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Dear diary. Today I was asked by " .. chatvars.playername .. " if I have seen " .. chatvars.playername .. ". I suspect one of us is losing it, I pray it is not me.[-]") end
						if r == 6 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Have I seen " .. chatvars.playername .. "? Why yes! Yes I have. If you go home right now, you will find " .. chatvars.playername .. " waiting for you. :D[-]") end
						if r == 7 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Oh God I am so depressed.[-]") end
						if r == 8 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. chatvars.playername .. "? Meh! Who cares?[-]") end
						if r == 9 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]What is seen cannot be unseen.. but I'm willing to give it a go. Got any bleach?[-]") end
						if r == 10 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I'm beginning to wish I hadn't :([-]") end
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[id].name .. " is playing right now.[-]")
					end
				else
					irc_chat(chatvars.ircAlias, players[id].name .. " is playing right now.")
				end

				botman.faultyChat = false
				return true
			end

			lastSeenMessage = seen(id)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. lastSeenMessage .. "[-]")
			else
				irc_chat(chatvars.ircAlias, lastSeenMessage)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SendAlertToAdmins()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}alert {message}"
			help[2] = "Whatever is typed after {#}alert is recorded to the database and displayed on irc.\n"
			help[2] = help[2] .. "You can recall the alerts with the irc command view alerts {optional days}"

			tmp.command = help[1]
			tmp.keywords = "alert,messages,msg,admin"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "alert") or string.find(chatvars.command, "info") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "alert") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[2] == nil) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Please include a message eg " .. server.commandPrefix .. "alert Claimed shop here![-]")
				botman.faultyChat = false
				return true
			end

			command = string.sub(chatvars.commandOld, string.find(chatvars.command, "alert ") + 6)
			sendIrc(server.ircAlerts, "***** " .. chatvars.userID .. " " .. chatvars.playername .. " at position " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ .. " said: " .. command .. "\n")
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Thank you! Your message has been recorded! =D[-]")

			if botman.dbConnected then conn:execute("INSERT INTO alerts (steam, x, y, z, message, timestamp) VALUES ('" .. chatvars.playerid .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. command .. "'," .. botman.serverTimeStamp .. ")") end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ServerInfo()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}server or {#}info"
			help[2] = "Displays info mostly from the server config."

			tmp.command = help[1]
			tmp.keywords = "information,server"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "server") or string.find(chatvars.command, "info") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "server" or chatvars.words[1] == "info") and chatvars.words[2] == nil then
			if (chatvars.playername ~= "Server") then
				if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
					botman.faultyChat = false
					return true
				end

				-- Server name
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This server is " .. server.serverName .. " " .. server.IP .. ":" .. server.ServerPort .. "[-]")

				if (server.gameType == "pve") then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This is a PVE server.[-]") end
				if (server.gameType == "pvp") then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This is a PVP server.[-]") end
				if (server.gameType == "cre") then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This is a creative mode server.[-]") end

				-- day/night length
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A full day runs " .. server.DayNightLength .. " minutes[-]")

				-- drop on death
				if (server.DropOnDeath == 0) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You drop nothing on death[-]") end
				if (server.DropOnDeath == 1) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You drop everything on death[-]") end
				if (server.DropOnDeath == 2) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You drop toolbelt on death[-]") end
				if (server.DropOnDeath == 3) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You drop backpack on death[-]") end
				if (server.DropOnDeath == 4) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You permanently lose everything on death[-]") end

				-- drop on quit
				if (server.DropOnQuit == 0) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You keep everything on quit[-]") end
				if (server.DropOnQuit == 1) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You drop everything on quit[-]") end
				if (server.DropOnQuit == 2) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You drop toolbelt only on quit[-]") end
				if (server.DropOnQuit == 3) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You drop backpack only on quit[-]") end

				-- land claim size
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Land claim size is " .. server.LandClaimSize .. " meters. Expiry " .. server.LandClaimExpiryTime .. " days[-]")

				-- loot abundance
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Loot abundance is " .. server.LootAbundance .. "%[-]")

				-- loot respawn
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Loot respawns after " .. server.LootRespawnDays .. " days[-]")

				-- zombies run
				if (server.ZombiesRun == 0) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Zombies run at night[-]") end
				if (server.ZombiesRun == 1) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Zombies never run[-]") end
				if (server.ZombiesRun == 2) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Zombies always run[-]") end

				if server.ZombieMove then
					if (server.ZombieMove == 0) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieMove: walk[-]") end
					if (server.ZombieMove == 1) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieMove: jog[-]") end
					if (server.ZombieMove == 2) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieMove: run[-]") end
					if (server.ZombieMove == 3) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieMove: sprint[-]") end
					if (server.ZombieMove == 4) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieMove: nightmare[-]") end
				end

				if server.ZombieMoveNight then
					if (server.ZombieMoveNight == 0) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieMoveNight: walk[-]") end
					if (server.ZombieMoveNight == 1) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieMoveNight: jog[-]") end
					if (server.ZombieMoveNight == 2) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieMoveNight: run[-]") end
					if (server.ZombieMoveNight == 3) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieMoveNight: sprint[-]") end
					if (server.ZombieMoveNight == 4) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieMoveNight: nightmare[-]") end
				end

				if server.ZombieFeralMove then
					if (server.ZombieFeralMove == 0) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieFeralMove: walk[-]") end
					if (server.ZombieFeralMove == 1) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieFeralMove: jog[-]") end
					if (server.ZombieFeralMove == 2) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieFeralMove: run[-]") end
					if (server.ZombieFeralMove == 3) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieFeralMove: sprint[-]") end
					if (server.ZombieFeralMove == 4) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieFeralMove: nightmare[-]") end
				end

				if server.ZombieBMMove then
					if (server.ZombieBMMove == 0) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieBMMove: walk[-]") end
					if (server.ZombieBMMove == 1) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieBMMove: jog[-]") end
					if (server.ZombieBMMove == 2) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieBMMove: run[-]") end
					if (server.ZombieBMMove == 3) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieBMMove: sprint[-]") end
					if (server.ZombieBMMove == 4) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]ZombieBMMove: nightmare[-]") end
				end

				-- map limit
				--message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The world is limited to  " .. chatvars.settings.mapSize / 1000 .. " km from map center[-]")

				if server.idleKick then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]When the server is full, idle players are kicked after " .. server.idleKickTimer .. " seconds.[-]")
				end
			else
				-- Server name
				irc_chat(chatvars.ircAlias, "This server is " .. server.serverName .. " " .. server.IP .. ":" .. server.ServerPort)

				if (server.gameType == "pve") then irc_chat(chatvars.ircAlias, "This is a PVE server.") end
				if (server.gameType == "pvp") then irc_chat(chatvars.ircAlias, "This is a PVP server.") end
				if (server.gameType == "cre") then irc_chat(chatvars.ircAlias, "This is a creative mode server.") end

				-- day/night length
				irc_chat(chatvars.ircAlias, "A full day runs " .. server.DayNightLength .. " minutes.")

				-- drop on death
				if (server.DropOnDeath == 0) then irc_chat(chatvars.ircAlias, "You drop everything on death.") end
				if (server.DropOnDeath == 1) then irc_chat(chatvars.ircAlias, "You drop toolbelt on death.") end
				if (server.DropOnDeath == 2) then irc_chat(chatvars.ircAlias, "You drop backpack on death.") end
				if (server.DropOnDeath == 3) then irc_chat(chatvars.ircAlias, "You permanently lose everything on death.") end

				-- drop on quit
				if (server.DropOnQuit == 0) then irc_chat(chatvars.ircAlias, "You keep everything on quit.") end
				if (server.DropOnQuit == 1) then irc_chat(chatvars.ircAlias, "You drop everything on quit.") end
				if (server.DropOnQuit == 2) then irc_chat(chatvars.ircAlias, "You drop toolbelt only on quit.") end
				if (server.DropOnQuit == 3) then irc_chat(chatvars.ircAlias, "You drop backpack only on quit.") end

				-- land claim size
				irc_chat(chatvars.ircAlias, "Land claim size is " .. server.LandClaimSize .. " meters. Expiry 30 days.")

				-- loot abundance
				irc_chat(chatvars.ircAlias, "Loot abundance is " .. server.LootAbundance .. "%")

				-- loot respawn
				irc_chat(chatvars.ircAlias, "Loot respawns after " .. server.LootRespawnDays .. " days.")

				-- zombies run
				if (server.ZombiesRun == 0) then irc_chat(chatvars.ircAlias, "Zombies run at night.") end
				if (server.ZombiesRun == 1) then irc_chat(chatvars.ircAlias, "Zombies never run.") end
				if (server.ZombiesRun == 2) then irc_chat(chatvars.ircAlias, "Zombies always run.") end

				if server.ZombieMove then
					if (server.ZombieMove == 0) then irc_chat(chatvars.ircAlias, "ZombieMove: walk") end
					if (server.ZombieMove == 1) then irc_chat(chatvars.ircAlias, "ZombieMove: jog") end
					if (server.ZombieMove == 2) then irc_chat(chatvars.ircAlias, "ZombieMove: run") end
					if (server.ZombieMove == 3) then irc_chat(chatvars.ircAlias, "ZombieMove: sprint") end
					if (server.ZombieMove == 4) then irc_chat(chatvars.ircAlias, "ZombieMove: nightmare") end
				end

				if server.ZombieMoveNight then
					if (server.ZombieMoveNight == 0) then irc_chat(chatvars.ircAlias, "ZombieMoveNight: walk") end
					if (server.ZombieMoveNight == 1) then irc_chat(chatvars.ircAlias, "ZombieMoveNight: jog") end
					if (server.ZombieMoveNight == 2) then irc_chat(chatvars.ircAlias, "ZombieMoveNight: run") end
					if (server.ZombieMoveNight == 3) then irc_chat(chatvars.ircAlias, "ZombieMoveNight: sprint") end
					if (server.ZombieMoveNight == 4) then irc_chat(chatvars.ircAlias, "ZombieMoveNight: nightmare") end
				end

				if server.ZombieFeralMove then
					if (server.ZombieFeralMove == 0) then irc_chat(chatvars.ircAlias, "ZombieFeralMove: walk") end
					if (server.ZombieFeralMove == 1) then irc_chat(chatvars.ircAlias, "ZombieFeralMove: jog") end
					if (server.ZombieFeralMove == 2) then irc_chat(chatvars.ircAlias, "ZombieFeralMove: run") end
					if (server.ZombieFeralMove == 3) then irc_chat(chatvars.ircAlias, "ZombieFeralMove: sprint") end
					if (server.ZombieFeralMove == 4) then irc_chat(chatvars.ircAlias, "ZombieFeralMove: nightmare") end
				end

				if server.ZombieBMMove then
					if (server.ZombieBMMove == 0) then irc_chat(chatvars.ircAlias, "ZombieBMMove: walk") end
					if (server.ZombieBMMove == 1) then irc_chat(chatvars.ircAlias, "ZombieBMMove: jog") end
					if (server.ZombieBMMove == 2) then irc_chat(chatvars.ircAlias, "ZombieBMMove: run") end
					if (server.ZombieBMMove == 3) then irc_chat(chatvars.ircAlias, "ZombieBMMove: sprint") end
					if (server.ZombieBMMove == 4) then irc_chat(chatvars.ircAlias, "ZombieBMMove: nightmare") end
				end

				-- -- map limit
				-- if players[chatvars.ircid].donor or chatvars.accessLevel < 2 then
					-- irc_chat(chatvars.ircAlias, "The world is limited to  " .. (server.mapSize + 10000) / 1000 .. " km from map center.")
				-- else
					-- irc_chat(chatvars.ircAlias, "The world is limited to  " .. server.mapSize / 1000 .. " km from map center.")
				-- end

				if server.idleKick then
					irc_chat(chatvars.ircAlias, "When the server is full, idle players are kicked after 15 minutes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShowRules()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}rules"
			help[2] = "Reports the server rules."

			tmp.command = help[1]
			tmp.keywords = "view,rules,server"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "rule") or string.find(chatvars.command, "server") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "rules" and chatvars.words[2] == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.rules .."[-]")
			else
				irc_chat(chatvars.ircAlias, server.rules)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShowServerFPS()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}fps"
			help[2] = "Displays the most recent output from the server mem command."

			tmp.command = help[1]
			tmp.keywords = "view,fps,performance"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "fps") or string.find(chatvars.command, "perf") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "fps" and chatvars.words[2] == nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Server FPS: " .. botman.performance.fps .. " Players: " .. botman.performance.players .. " Zombies: " .. botman.performance.zombies .. " Entities: " .. botman.performance.entities .. " Heap: " .. botman.performance.heap .. " HeapMax: " .. botman.performance.heapMax .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Server FPS: " .. botman.performance.fps .. " Players: " .. botman.performance.players .. " Zombies: " .. botman.performance.zombies .. " Entities: " .. botman.performance.entities .. " Heap: " .. botman.performance.heap .. " HeapMax: " .. botman.performance.heapMax)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShowServerStats()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}server stats"
			help[2] = "Displays various server totals for the last 24 hours or more days if you add a number.\n"
			help[2] = help[2] .. "eg. {#}server stats 5 (gives you the last 5 days cummulative stats)"

			tmp.command = help[1]
			tmp.keywords = "view,server,stats,statistics"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "server") or string.find(chatvars.command, "stat") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if ((chatvars.words[1] == "server" and string.find(chatvars.command, "stat")) and chatvars.words[4] == nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				chatvars.number = 1
			else
				chatvars.number = math.abs(math.floor(chatvars.number))
			end

			if chatvars.number == 0 then chatvars.number = 1 end

			if chatvars.number == 1 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]24 hour stats to now:[-]")
				else
					irc_chat(chatvars.ircAlias, "24 hour stats to now:")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. chatvars.number .. " day stats to now:[-]")
				else
					irc_chat(chatvars.ircAlias, chatvars.number .. " day stats to now:")
				end
			end

			cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%pvp%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]PVPs: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "PVPs: " .. row.number)
			end

			cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%timeout%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Timeouts: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Timeouts: " .. row.number)
			end

			cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%arrest%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Arrests: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Arrests: " .. row.number)
			end

			cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%new%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "New players: " .. row.number)
			end

			cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%ban%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Bans: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Bans: " .. row.number)
			end

			cursor,errorString = conn:execute("SELECT MAX(players) as number FROM performance WHERE timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Most players online: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Most players online: " .. row.number)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShowServerTime()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}server date"
			help[2] = "Displays the system clock of the game server."

			tmp.command = help[1]
			tmp.keywords = "view,server,date,time,current"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "date") or string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if ((chatvars.words[1] == "server" and (chatvars.words[2] == "date" or chatvars.words[2] == "time")) and chatvars.words[3] == nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The server date is " .. botman.serverTime .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "The server date is " .. botman.serverTime)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShowWherePlayer()
		local inResetZone

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}where"
			help[2] = "Gives info about where you are in the world and the rules that apply there."

			tmp.command = help[1]
			tmp.keywords = "where,player,location,coordinates"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "where") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "where" or chatvars.words[1] == "whereami") and chatvars.words[2] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			inResetZone = false

			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are " .. string.format("%.2f", (distancexz(chatvars.intX, chatvars.intZ,0,0) / 1000)) .. " km from the center of the map.[-]")
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are at " .. mapPosition(chatvars.playerid) .. "[-]")

			if igplayers[chatvars.playerid].currentLocationPVP then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]PVP is allowed here.[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]PVE rules apply here. Do not kill players.[-]")
			end

			if players[chatvars.playerid].inLocation ~= "" then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are in the location " .. players[chatvars.playerid].inLocation .. "[-]")
			end

			if players[chatvars.playerid].inLocation ~= "" then
				if locations[players[chatvars.playerid].inLocation].resetZone then
					inResetZone = true
				end
			end

			if resetRegions[igplayers[chatvars.playerid].region] then
				inResetZone = true
			end

			if inResetZone then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are in a reset zone.  Don't build here or place a claim.[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not in a reset zone.[-]")
			end

			if players[chatvars.playerid].atHome then
				tmp.baseFound, tmp.base = getNearestBase(chatvars.intX, chatvars.intZ, chatvars.playerid)
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are home in base " .. string.trim(tmp.base.baseNumber .. " " .. tmp.base.title) .. ".[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Uptime()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}uptime"
			help[2] = "Reports the bot and server's running times."

			tmp.command = help[1]
			tmp.keywords = "up,time,server,bot"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "uptime" and chatvars.words[2] == nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.days, tmp.hours, tmp.minutes, tmp.seconds = timestampToString(botman.botStarted, true)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The server time is " .. os.date("%Y-%m-%d %H:%M:%S", calculateServerTime(os.time())) .."[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.botName .. " has been online " .. tmp.days .. " days " .. tmp.hours .. " hours " .. tmp.minutes .. " minutes.[-]")
			else
				irc_chat(chatvars.ircAlias, "The server time is " .. os.date("%Y-%m-%d %H:%M:%S", calculateServerTime(os.time())))
				irc_chat(chatvars.ircAlias, server.botName .. " has been online " .. tmp.days .. " days " .. tmp.hours .. " hours " .. tmp.minutes .. " minutes " .. tmp.seconds .. " seconds.")
			end

			if server.uptime > 0 then
				diff = server.uptime
				days = math.floor(diff / 86400)

				if (days > 0) then
					diff = diff - (days * 86400)
				end

				hours = math.floor(diff / 3600)

				if (hours > 0) then
					diff = diff - (hours * 3600)
				end

				minutes = math.floor(diff / 60)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Server uptime is " .. days .. " days " .. hours .. " hours " .. minutes .." minutes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Server uptime is " .. days .. " days " .. hours .. " hours " .. minutes .." minutes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ViewPlayerInfo()
		local donor, expiry, k, v, protected

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}info {player}"
			help[2] = "Displays info about a player.  Only staff can specify a player.  Players just see their own info."

			tmp.command = help[1]
			tmp.keywords = "view,player,information"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "info") or string.find(chatvars.command, "play") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "info" and chatvars.words[2] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "info") + 5)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if not chatvars.isAdminHidden then
				id = chatvars.userID
			end

			if id == "0" and chatvars.isAdminHidden then
				-- show info for archived player
				id = LookupArchivedPlayer(pname)

				if not (id == "0") then
					donor, expiry = isDonor(id)

					if (igplayers[id]) then
						time = tonumber(playersArchived[id].timeOnServer) + tonumber(igplayers[id].sessionPlaytime)
					else
						time = tonumber(playersArchived[id].timeOnServer)
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

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Info for player " .. playersArchived[id].name .. "[-]")
					if playersArchived[id].newPlayer == true then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A new player.[-]") end
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Steam: " .. id .. " ID: " .. playersArchived[id].id .. "[-]")
					if playersArchived[id].firstSeen ~= nil then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]First seen: " .. os.date("%Y-%m-%d %H:%M:%S", playersArchived[id].firstSeen) .. "[-]") end
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Total time played: " .. days .. " days " .. hours .. " hours " .. minutes .. " minutes " .. time .. " seconds[-]")

					if playersArchived[id].bedX ~= 0 and playersArchived[id].bedY ~= 0 and playersArchived[id].bedZ ~= 0 then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Has a bedroll at " .. playersArchived[id].bedX .. " " .. playersArchived[id].bedY .. " " .. playersArchived[id].bedZ .. "[-]")
					end

					werds = {}
					for word in botman.serverTime:gmatch("%w+") do table.insert(werds, word) end

					ryear = werds[1]
					rmonth = werds[2]
					rday = string.sub(werds[3], 1, 2)
					rhour = string.sub(werds[3], 4, 5)
					rmin = werds[4]
					rsec = werds[5]

					dateNow = {year=ryear, month=rmonth, day=rday, hour=rhour, min=rmin, sec=rsec}
					Now = os.time(dateNow)

					werds = {}
					for word in playersArchived[id].seen:gmatch("%w+") do table.insert(werds, word) end

					ryear = werds[1]
					rmonth = werds[2]
					rday = string.sub(werds[3], 1, 2)
					rhour = string.sub(werds[3], 4, 5)
					rmin = werds[4]
					rsec = werds[5]

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

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" ..playersArchived[id].name .. " was last seen " .. days .. " days " .. hours .. " hours " .. minutes .." minutes ago[-]")

					if playersArchived[id].timeout then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Is in timeout[-]") end
					if playersArchived[id].prisoner then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Is a prisoner[-]")
						if playersArchived[id].prisonReason ~= nil then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Reason Arrested: " .. playersArchived[id].prisonReason .. "[-]") end
					end

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Keystones placed " .. playersArchived[id].keystones .. "[-]")

					if server.allowBank then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.moneyPlural .. " " .. string.format("%d", playersArchived[id].cash) .. "[-]")
					end

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Current Session " .. playersArchived[id].sessionCount .. "[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]IP " .. playersArchived[id].ip .. "[-]")

					if donor then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Is a donor[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Donor status expires on " .. os.date("%Y-%m-%d %H:%M:%S",  expiry))
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Is not a donor[-]")
					end

					cursor,errorString = conn:execute("SELECT * FROM bans WHERE steam = '" .. id .. "'")
					if cursor:numrows() > 0 then
						row = cursor:fetch({}, "a")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]BANNED until " .. row.BannedTo .. " " .. row.Reason .. "[-]")
					end
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player name required or no match found.[-]")
				end

				botman.faultyChat = false
				return true
			end

			-- show info for player who isn't archived.
			if (id ~= "0") then
				donor, expiry = isDonor(id)

				if (igplayers[id]) then
					time = tonumber(players[id].timeOnServer) + tonumber(igplayers[id].sessionPlaytime)
				else
					time = tonumber(players[id].timeOnServer)
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

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Info for player " .. players[id].name .. "[-]")
				if players[id].newPlayer == true then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A new player.[-]") end
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Steam: " .. id .. " ID: " .. players[id].id .. "[-]")
				if players[id].firstSeen ~= nil then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]First seen: " .. os.date("%Y-%m-%d %H:%M:%S", players[id].firstSeen) .. "[-]") end
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Total time played: " .. days .. " days " .. hours .. " hours " .. minutes .. " minutes " .. time .. " seconds[-]")

				if players[id].bedX ~= 0 and players[id].bedY ~= 0 and players[id].bedZ ~= 0 then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Has a bedroll at " .. players[id].bedX .. " " .. players[id].bedY .. " " .. players[id].bedZ .. "[-]")
				end

				for k,v in pairs(bases) do
					protected = ""

					if v.steam == id then
						if v.protect then
							protected = " protected"
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base " .. string.trim(v.baseNumber .. " " .. v.title) .. " at " .. v.x .. " " .. v.y .. " " .. v.z .. protected .. "[-]")
					end
				end

				werds = {}
				for word in botman.serverTime:gmatch("%w+") do table.insert(werds, word) end

				ryear = werds[1]
				rmonth = werds[2]
				rday = string.sub(werds[3], 1, 2)
				rhour = string.sub(werds[3], 4, 5)
				rmin = werds[4]
				rsec = werds[5]

				dateNow = {year=ryear, month=rmonth, day=rday, hour=rhour, min=rmin, sec=rsec}
				Now = os.time(dateNow)

				werds = {}
				for word in players[id].seen:gmatch("%w+") do table.insert(werds, word) end

				ryear = werds[1]
				rmonth = werds[2]
				rday = string.sub(werds[3], 1, 2)
				rhour = string.sub(werds[3], 4, 5)
				rmin = werds[4]
				rsec = werds[5]

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

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" ..players[id].name .. " was last seen " .. days .. " days " .. hours .. " hours " .. minutes .." minutes ago[-]")

				if players[id].timeout then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Is in timeout[-]") end
				if players[id].prisoner then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Is a prisoner[-]")
					if players[id].prisonReason ~= nil then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Reason Arrested: " .. players[id].prisonReason .. "[-]") end
				end

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Keystones placed " .. players[id].keystones .. "[-]")

				if server.allowBank then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.moneyPlural .. " " .. string.format("%d", players[id].cash) .. "[-]")
				end

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Current Session " .. players[id].sessionCount .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]IP " .. players[id].ip .. "[-]")

				if donor then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Is a donor[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Donor status expires on " .. os.date("%Y-%m-%d %H:%M:%S",  expiry))
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Is not a donor[-]")
				end

				cursor,errorString = conn:execute("SELECT * FROM bans WHERE steam = '" .. id .. "'")
				if cursor:numrows() > 0 then
					row = cursor:fetch({}, "a")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]BANNED until " .. row.BannedTo .. " " .. row.Reason .. "[-]")
				end
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player name required or no match found.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WhenDay7()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}day7 or {#}when feral or {#}bloodmoon"
			help[2] = "Reports the number of days remaining until the next horde night."

			tmp.command = help[1]
			tmp.keywords = "day,horde,night,feral"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "feral") or string.find(chatvars.command, "blood") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "when" and chatvars.words[2] == "feral") or chatvars.words[1] == "day7" or chatvars.words[1] == "bloodmoon" then
			day7(chatvars.userID)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WhenNextReboot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}next reboot"
			help[2] = "Reports the time remaining before the next scheduled reboot."

			tmp.command = help[1]
			tmp.keywords = "reboot,restart"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "next") or string.find(chatvars.command, "boot") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if ((chatvars.words[1] == "when" or chatvars.words[1] == "next") and chatvars.words[2] == "reboot") then
			if server.delayReboot then
				if (server.gameDay % server.hordeNight == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The reboot will happen after bloodmoon. Admins can force it with " .. server.commandPrefix .. "reboot now.[-]")
					else
						irc_chat(chatvars.ircAlias, "The reboot will happen after bloodmoon. Admins can force it with " .. server.commandPrefix .. "reboot now.")
					end
				end

				if (chatvars.playername ~= "Server") then
					nextReboot(chatvars.playerid)
				else
					nextReboot(chatvars.ircid)
				end
			else
				if (chatvars.playername ~= "Server") then
					nextReboot(chatvars.playerid)
				else
					nextReboot(chatvars.ircid)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WhoIsNearPlayer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}who {optional number distance}"
			help[2] = "Donors can see 300 metres and other players can see 200.  New and watched players can't see staff near them."

			tmp.command = help[1]
			tmp.keywords = "who,near,me,players"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "who") or string.find(chatvars.command, "info") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "who" and chatvars.words[2] ~= "visited" and chatvars.words[3] == nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			alone = true

			if (chatvars.number == nil) then chatvars.number = 500 end

			if (not chatvars.isAdminHidden) then
				chatvars.number = 300
			end

			if (chatvars.accessLevel > 10) then
				chatvars.number = 200
			end

			x = math.floor(igplayers[chatvars.playerid].xPos / 512)
			z = math.floor(igplayers[chatvars.playerid].zPos / 512)

			if (tonumber(chatvars.intX) < 0) then xdir = " west " else xdir = " east " end
			if (tonumber(chatvars.intZ) < 0) then zdir = " south" else zdir = " north" end

			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are at " .. chatvars.intX .. xdir .. chatvars.intZ .. zdir .. " at a height of " .. chatvars.intY .. "[-]")
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are in region r." .. x .. "." .. z .. ".7rg[-]")

			if (pvpZone(chatvars.intX, chatvars.intZ) == false) or chatvars.isAdminHidden then
				for k, v in pairs(igplayers) do
					dist = distancexz(chatvars.intX, chatvars.intZ, v.xPos, v.zPos)

					if dist <= tonumber(chatvars.number) then
						if (v.steam ~= chatvars.playerid) then
							if (alone == true) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]players within " .. chatvars.number .. " meters of you are:[-]") end

							if chatvars.isAdminHidden or chatvars.isDonor then
								x = math.floor(v.xPos / 512)
								z = math.floor(v.zPos / 512)

								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%d", dist) .. " region r." .. x .. "." .. z .. ".7rg[-]")
							else
								if (players[chatvars.playerid].watchPlayer == true) and not isAdminHidden(v.steam, v.userID) then
									message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. v.name .. "[-]")
								end

								if (players[chatvars.playerid].watchPlayer == false) then
									message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. v.name .. "[-]")
								end
							end
							alone = false
						end
					end
				end

				if alone then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Nobody is within " .. chatvars.number .. " meters of you.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WhoVisitedMe()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}who visited player {player name} days {days} hours {hrs} range {dist} height {ht}"
			help[2] = "See who visited a player location or base.\n"
			help[2] = help[2] .. "Example with defaults: {#}who visited player smeg days 1 hours 0 range 10 height 5\n"
			help[2] = help[2] .. " {#}who visited bed smeg\n"
			help[2] = help[2] .. "Add base to just see base visitors. Setting hours will reset days to zero.\n"
			help[2] = help[2] .. "Use this command to discover who's been at the player's location."

			tmp.command = help[1]
			tmp.keywords = "who,bed,visited,player"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "who") or string.find(chatvars.command, "visit") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "who" and chatvars.words[2] == "visited") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if not chatvars.isAdminHidden then
				if server.gameType == "pvp" then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command is not available in PVP.[-]")

					botman.faultyChat = false
					return true
				end

				if igplayers[chatvars.playerid] then
					if igplayers[chatvars.playerid].currentLocationPVP then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command is not available in PVP.[-]")

						botman.faultyChat = false
						return true
					end
				end
			end

			if (chatvars.words[3] == nil) then
				if (not chatvars.isAdminHidden) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]See who visited your base (or 2nd base).[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Examples with defaults:[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who visited base1/base2 days 1 hours 0 range 10 height 5[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who visited my bed[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Setting hours will reset days to zero[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will report up to right now.  You can't ask for just 2 days ago currently.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Range is limited to 100 metres from your base teleport.[-]")
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]See who visited a player location or base.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Example with defaults:[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who visited player smeg days 1 hours 0 range 10 height 5[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who visited bed smeg[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Add base to just see their base visitors[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Setting hours will reset days to zero[-]")
				end

				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.days = 1
			tmp.hours = 0
			tmp.range = 10
			tmp.height = 10
			tmp.basesOnly = "player"
			tmp.base = ""

			for i=3,chatvars.wordCount,1 do
				if chatvars.words[i] == "range" then
					tmp.range = tonumber(chatvars.words[i+1])
				end

				if chatvars.words[i] == "days" then
					tmp.days = tonumber(chatvars.words[i+1])
					tmp.hours = 0
				end

				if chatvars.words[i] == "hours" then
					tmp.hours = tonumber(chatvars.words[i+1])
					tmp.days = 0
				end

				if chatvars.words[i] == "height" then
					tmp.height = tonumber(chatvars.words[i+1])
				end

				-- staff only settings
				if (chatvars.isAdminHidden) then
					if chatvars.words[i] == "x" then
						tmp.x = tonumber(chatvars.words[i+1])
					end

					if chatvars.words[i] == "y" then
						tmp.y = tonumber(chatvars.words[i+1])
					end

					if chatvars.words[i] == "z" then
						tmp.z = tonumber(chatvars.words[i+1])
					end

					if chatvars.words[i] == "base" then
						tmp.baseOnly = "base"
					end

					if chatvars.words[i] == "player" or chatvars.words[i] == "bed" then
						tmp.name = chatvars.words[i+1]
						tmp.steam = LookupPlayer(tmp.name)

						if tmp.steam == "0" then
							tmp.steam = LookupArchivedPlayer(tmp.name)

							if not (tmp.steam == "0") then
								playerName = playersArchived[tmp.steam].name
								isArchived = true
							else
								if (chatvars.playername ~= "Server") then
									message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. tmp.name .. "[-]")
								else
									irc_chat(chatvars.ircAlias, "No player found matching " .. tmp.name)
								end

								botman.faultyChat = false
								return true
							end
						else
							playerName = players[tmp.steam].name
							isArchived = false
						end

						if tmp.steam and chatvars.words[i] == "player" then
							tmp.player = true

							if not isArchived then
								tmp.x = players[tmp.steam].xPos
								tmp.y = players[tmp.steam].yPos
								tmp.z = players[tmp.steam].zPos
							else
								tmp.x = playersArchived[tmp.steam].xPos
								tmp.y = playersArchived[tmp.steam].yPos
								tmp.z = playersArchived[tmp.steam].zPos
							end
						end

						if tmp.steam and chatvars.words[i] == "bed" then
							tmp.bed = true

							if not isArchived then
								tmp.x = players[tmp.steam].bedX
								tmp.y = players[tmp.steam].bedY
								tmp.z = players[tmp.steam].bedZ
							else
								tmp.x = playersArchived[tmp.steam].bedX
								tmp.y = playersArchived[tmp.steam].bedY
								tmp.z = playersArchived[tmp.steam].bedZ
							end
						end
					end
				end

				-- player settings
				if (not chatvars.isAdminHidden) then
					if chatvars.words[i] == "bed" then
						tmp.bed = true
						tmp.x = players[tmp.steam].bedX
						tmp.y = players[tmp.steam].bedY
						tmp.z = players[tmp.steam].bedZ
					end

					if chatvars.words[i] == "base1" or chatvars.words[i] == "home1" then
						tmp.base = "1"
					end

					if chatvars.words[i] == "base2" or chatvars.words[i] == "home2" then
						tmp.base = "2"
					end
				end
			end

			-- staff version
			if (chatvars.isAdminHidden) then
				if (tmp.basesOnly == "base") and tmp.steam then
					if not isArchived then
						if players[tmp.steam].homeX ~= 0 and players[tmp.steam].homeZ ~= 0 then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of base 1 of " .. players[tmp.steam].name .. " at " .. players[tmp.steam].homeX .. " " .. players[tmp.steam].homeY .. " " .. players[tmp.steam].homeZ .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
							dbWho(chatvars.userID, players[tmp.steam].homeX, players[tmp.steam].homeY, players[tmp.steam].homeZ, tmp.range, tmp.days, tmp.hours, tmp.height, chatvars.userID, true)
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. " does not have a base set yet.[-]")
						end

						if players[tmp.steam].home2X ~= 0 and players[tmp.steam].home2Z ~= 0 then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of base 2 of " .. players[tmp.steam].name .. " at " .. players[tmp.steam].home2X .. " " .. players[tmp.steam].home2Y .. " " .. players[tmp.steam].home2Z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
							dbWho(chatvars.userID, players[tmp.steam].home2X, players[tmp.steam].home2Y, players[tmp.steam].home2Z, tmp.range, tmp.days, tmp.hours, tmp.height, chatvars.userID, true)
						end
					else
						if playersArchived[tmp.steam].homeX ~= 0 and playersArchived[tmp.steam].homeZ ~= 0 then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of base 1 of " .. players[tmp.steam].name .. " at " .. playersArchived[tmp.steam].homeX .. " " .. playersArchived[tmp.steam].homeY .. " " .. playersArchived[tmp.steam].homeZ .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
							dbWho(chatvars.userID, playersArchived[tmp.steam].homeX, playersArchived[tmp.steam].homeY, playersArchived[tmp.steam].homeZ, tmp.range, tmp.days, tmp.hours, tmp.height, chatvars.userID, true)
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playersArchived[tmp.steam].name .. " does not have a base set yet.[-]")
						end

						if playersArchived[tmp.steam].home2X ~= 0 and playersArchived[tmp.steam].home2Z ~= 0 then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of base 2 of " .. playersArchived[tmp.steam].name .. " at " .. playersArchived[tmp.steam].home2X .. " " .. playersArchived[tmp.steam].home2Y .. " " .. playersArchived[tmp.steam].home2Z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
							dbWho(chatvars.userID, playersArchived[tmp.steam].home2X, playersArchived[tmp.steam].home2Y, playersArchived[tmp.steam].home2Z, tmp.range, tmp.days, tmp.hours, tmp.height, chatvars.userID, true)
						end
					end
				end

				if tmp.basesOnly == "player" and tmp.steam then
					if not isArchived then
						if tmp.player then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. " at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
						end

						if tmp.bed then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. "'s bed at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
						end
					else
						if tmp.player then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of player " .. playersArchived[tmp.steam].name .. " at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
						end

						if tmp.bed then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of player " .. playersArchived[tmp.steam].name .. "'s bed at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
						end
					end

					dbWho(chatvars.userID, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height, chatvars.userID, true)
				end

				if not tmp.steam then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
					dbWho(chatvars.userID, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height, chatvars.userID, true)
				end
			end


			-- player version
			if (not chatvars.isAdminHidden) then
				-- set some defaults and limits
				if tmp.height == 0 then tmp.height = 30 end
				if tmp.range > 100 then tmp.range = 100 end

				if tmp.base == "1" then
					if players[tmp.steam].homeX ~= 0 and players[tmp.steam].homeZ ~= 0 then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of your home at " .. players[tmp.steam].homeX .. " " .. players[tmp.steam].homeY .. " " .. players[tmp.steam].homeZ .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
						dbWho(chatvars.userID, players[tmp.steam].homeX, players[tmp.steam].homeY, players[tmp.steam].homeZ, tmp.range, tmp.days, tmp.hours, tmp.height, chatvars.userID, true)
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have not done " .. server.commandPrefix .. "sethome yet.[-]")
					end
				end

				if tmp.base == "2" then
					if players[tmp.steam].home2X ~= 0 and players[tmp.steam].home2Z ~= 0 then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of your second home at " .. players[tmp.steam].home2X .. " " .. players[tmp.steam].home2Y .. " " .. players[tmp.steam].home2Z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
						dbWho(chatvars.userID, players[tmp.steam].home2X, players[tmp.steam].home2Y, players[tmp.steam].home2Z, tmp.range, tmp.days, tmp.hours, tmp.height, chatvars.userID, true)
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have not done " .. server.commandPrefix .. "sethome2 yet (if you can have a 2nd home).[-]")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		if debug then dbug("Registering help - info commands") end

		tmp.topicDescription = "Info commands show players information about specific things such as rules, when the next horde night is, etc."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Info Commands:")
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, tmp.topicDescription)
			irc_chat(chatvars.ircAlias, ".")
		end

		cursor,errorString = connSQL:execute("SELECT count(*) FROM helpTopics WHERE topic = '" .. tmp.topic .. "'")
		row = cursor:fetch({}, "a")
		rows = row["count(*)"]

		if rows == 0 then
			connSQL:execute("INSERT INTO helpTopics (topic, description) VALUES ('" .. tmp.topic .. "', '" .. connMEM:escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "info" then
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and chatvars.words[1] ~= "help" and not botman.registerHelp then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Info Commands:")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "info")
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_BotInfo()

	if result then
		if debug then dbug("debug cmd_BotInfo triggered") end
		return result, "cmd_BotInfo"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_Uptime()

	if result then
		if debug then dbug("debug cmd_Uptime triggered") end
		return result, "cmd_Uptime"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ServerInfo()

	if result then
		if debug then dbug("debug cmd_ServerInfo triggered") end
		return result, "cmd_ServerInfo"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhenNextReboot()

	if result then
		if debug then dbug("debug cmd_WhenNextReboot triggered") end
		return result, "cmd_WhenNextReboot"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhenDay7()

	if result then
		if debug then dbug("debug cmd_WhenDay7 triggered") end
		return result, "cmd_WhenDay7"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShowServerFPS()

	if result then
		if debug then dbug("debug cmd_ShowServerFPS triggered") end
		return result, "cmd_ShowServerFPS"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShowServerTime()

	if result then
		if debug then dbug("debug cmd_ShowServerTime triggered") end
		return result, "cmd_ShowServerTime"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShowServerStats()

	if result then
		if debug then dbug("debug cmd_ShowServerStats triggered") end
		return result, "cmd_ShowServerStats"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListNewPlayers()

	if result then
		if debug then dbug("debug cmd_ListNewPlayers triggered") end
		return result, "cmd_ListNewPlayers"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_SeenPlayer()

	if result then
		if debug then dbug("debug cmd_SeenPlayer triggered") end
		return result, "cmd_SeenPlayer"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShowRules()

	if result then
		if debug then dbug("debug cmd_ShowRules triggered") end
		return result, "cmd_ShowRules"
	end

	if debug then dbug("debug info end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.userID == "0" and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if chatvars.showHelp and chatvars.words[1] ~= "help" and not botman.registerHelp then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Info Commands (In-Game Only):")
		irc_chat(chatvars.ircAlias, ".")
	end

	result = cmd_ShowWherePlayer()

	if result then
		if debug then dbug("debug cmd_ShowWherePlayer triggered") end
		return result, "cmd_ShowWherePlayer"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	-- help
	if chatvars.words[1] == "help" and chatvars.ircid == "0" then
		if chatvars.words[2] ~= nil then
			cmd = string.trim(string.sub(chatvars.command, 7))
		end

		commandHelp(cmd)

		botman.faultyChat = false
		return true, ""
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	-- db help
	if chatvars.words[1] == "hhelp" and chatvars.ircid == "0" then
		if chatvars.words[2] ~= nil then
			cmd = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[2]))
--			cmd = string.trim(string.sub(chatvars.command, 7))
		end

		dbHelp(cmd)

		botman.faultyChat = false
		return true, ""
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "commands") then
		commandHelp("commands")
		botman.faultyChat = false
		return true, ""
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "status") then
		botman.faultyChat = baseStatus(chatvars.command, chatvars.playerid, chatvars.userID)
		return true, ""
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	if string.find(chatvars.command, "pvp") and (chatvars.accessLevel == 99) and (chatvars.words[1] ~= "help") then
		if (server.gameType == "pvp") then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This is a PVP server.[-]")
		else
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This is a PVE server.  No PVP except in PVP zones.  Read /help pvp for info.[-]")
		end

		botman.faultyChat = false
		return true, ""
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhoIsNearPlayer()
	if result then
		if debug then dbug("debug cmd_WhoIsNearPlayer triggered") end
		return result, "cmd_WhoIsNearPlayer"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_SendAlertToAdmins()
	if result then
		if debug then dbug("debug cmd_SendAlertToAdmins triggered") end
		return result, "cmd_SendAlertToAdmins"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ViewPlayerInfo()
	if result then
		if debug then dbug("debug cmd_ViewPlayerInfo triggered") end
		return result, "cmd_ViewPlayerInfo"
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhoVisitedMe()
	if result then
		if debug then dbug("debug cmd_WhoVisitedMe triggered") end
		return result, "cmd_WhoVisitedMe"
	end

	if botman.registerHelp then
		if debug then dbug("Info commands help registered") end
	end

	if debug then dbug("debug info end") end

	-- can't touch dis
	if true then
		return result, ""
	end

end
