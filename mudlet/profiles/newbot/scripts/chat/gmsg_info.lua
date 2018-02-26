--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug, xdir, zdir, dist, x, z, diff, days, hours, minutes, result, time, werds, word, cmd, direction
local shortHelp = false
local skipHelp = false

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false -- should be false unless testing

if botman.debugAll then
	debug = true
end

function gmsg_info()
	calledFunction = "gmsg_info"
	result = false

-- ################## info command functions ##################

	local function cmd_ListNewPlayers()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "new") or string.find(chatvars.command, "play") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "new players {optional number (days)")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "List the new players and basic info about them in the last day or more.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "new" and chatvars.words[2] == "players") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number == nil then
				number = 86400
			else
				number = chatvars.number * 86400
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players in the last " .. math.floor(number / 86400) .. " days:[-]")
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

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. msg .. "[-]")
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
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "see") or string.find(chatvars.command, "play") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "seen {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Reports when the player was last on the server.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "seen") then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "seen ") + 5)
			pname = string.trim(pname)

			id = LookupPlayer(pname)

			if (igplayers[id]) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player " .. players[id].name .. " is playing right now.[-]")
				else
					irc_chat(chatvars.ircAlias, "player " .. players[id].name .. " is playing right now.")
				end

				botman.faultyChat = false
				return true
			end

			if (players[id]) then
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
				rday = werds[3]
				rhour = werds[4]
				rmin = werds[5]
				rsec = 0

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

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" ..players[id].name .. " was last seen " .. days .. " days " .. hours .. " hours " .. minutes .." minutes ago.[-]")
				else
					irc_chat(chatvars.ircAlias, players[id].name .. " was last seen " .. days .. " days " .. hours .. " hours " .. minutes .." minutes ago.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry I don't know a player called " .. pname .. ". Check your spelling.[-]")
				else
					irc_chat(chatvars.ircAlias, "Sorry I don't know a player called " .. pname .. ". Check your spelling.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SendAlertToAdmins()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "alert") or string.find(chatvars.command, "info") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "alert {message>")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Whatever is typed after " .. server.commandPrefix .. "alert is recorded to the database and displayed on irc.")
					irc_chat(chatvars.ircAlias, "You can recall the alerts with the irc command view alerts {optional days>")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "alert") then
			if (chatvars.words[2] == nil) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Please include a message eg " .. server.commandPrefix .. "alert Claimed shop here![-]")
				botman.faultyChat = false
				return true
			end

			command = string.sub(chatvars.command, string.find(chatvars.command, "alert ") + 6)
			sendIrc(server.ircAlerts, "***** " .. chatvars.playerid .. " " .. chatvars.playername .. " at position " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ .. " said: " .. command .. "\n")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Thank you! Your message has been recorded! =D[-]")

			if botman.dbConnected then conn:execute("INSERT INTO alerts (steam, x, y, z, message) VALUES (" .. chatvars.playerid .. "," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. command .. "')") end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ServerInfo()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "server") or string.find(chatvars.command, "info") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "server or " .. server.commandPrefix .. "info")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Displays info mostly from the server config.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "server" or chatvars.words[1] == "info") and chatvars.words[2] == nil then
			if (chatvars.playername ~= "Server") then
				-- Server name
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This server is " .. server.serverName .. " " .. server.IP .. ":" .. server.ServerPort .. "[-]")

				if (server.gameType == "pve") then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a PVE server.[-]") end
				if (server.gameType == "pvp") then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a PVP server.[-]") end
				if (server.gameType == "cre") then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a creative mode server.[-]") end

				-- day/night length
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A full day runs " .. server.DayNightLength .. " minutes[-]")

				-- drop on death
				if (server.DropOnDeath == 0) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You drop everything on death[-]") end
				if (server.DropOnDeath == 1) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You drop toolbelt on death[-]") end
				if (server.DropOnDeath == 2) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You drop backpack on death[-]") end
				if (server.DropOnDeath == 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You permanently lose everything on death[-]") end

				-- drop on quit
				if (server.DropOnQuit == 0) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You keep everything on quit[-]") end
				if (server.DropOnQuit == 1) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You drop everything on quit[-]") end
				if (server.DropOnQuit == 2) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You drop toolbelt only on quit[-]") end
				if (server.DropOnQuit == 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You drop backpack only on quit[-]") end

				-- land claim size
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Land claim size is " .. server.LandClaimSize .. " meters. Expiry " .. server.LandClaimExpiryTime .. " days[-]")

				-- block durability
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Block durability is " .. server.BlockDurabilityModifier .. "%[-]")

				-- loot abundance
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Loot abundance is " .. server.LootAbundance .. "%[-]")

				-- loot respawn
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Loot respawns after " .. server.LootRespawnDays .. " days[-]")

				-- zombies run
				if (server.ZombiesRun == 0) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Zombies run at night[-]") end
				if (server.ZombiesRun == 1) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Zombies never run[-]") end
				if (server.ZombiesRun == 2) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Zombies always run[-]") end

				-- map limit
				if players[chatvars.playerid].donor == true then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The world is limited to  " .. (server.mapSize + 10000) / 1000 .. " km from map center[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The world is limited to  " .. server.mapSize / 1000 .. " km from map center[-]")
				end

				if server.idleKick then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]When the server is full, idle players are kicked after 15 minutes.[-]")
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

				-- block durability
				irc_chat(chatvars.ircAlias, "Block durability is " .. server.BlockDurabilityModifier .. "%")

				-- loot abundance
				irc_chat(chatvars.ircAlias, "Loot abundance is " .. server.LootAbundance .. "%")

				-- loot respawn
				irc_chat(chatvars.ircAlias, "Loot respawns after " .. server.LootRespawnDays .. " days.")

				-- zombies run
				if (server.ZombiesRun == 0) then irc_chat(chatvars.ircAlias, "Zombies run at night.") end
				if (server.ZombiesRun == 1) then irc_chat(chatvars.ircAlias, "Zombies never run.") end
				if (server.ZombiesRun == 2) then irc_chat(chatvars.ircAlias, "Zombies always run.") end

				-- zombie memory
				irc_chat(chatvars.ircAlias, "Zombie memory is " .. server.EnemySenseMemory .. " seconds.")

				-- map limit
				if players[chatvars.ircid].donor or chatvars.accessLevel < 2 then
					irc_chat(chatvars.ircAlias, "The world is limited to  " .. (server.mapSize + 10000) / 1000 .. " km from map center.")
				else
					irc_chat(chatvars.ircAlias, "The world is limited to  " .. server.mapSize / 1000 .. " km from map center.")
				end

				if server.idleKick then
					irc_chat(chatvars.ircAlias, "When the server is full, idle players are kicked after 15 minutes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShowRules()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "rule") or string.find(chatvars.command, "server") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "rules")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Reports the server rules.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "rules" and chatvars.words[2] == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.rules .."[-]")
			else
				irc_chat(chatvars.ircAlias, server.rules)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShowServerFPS()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "fps") or string.find(chatvars.command, "perf") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "fps")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Displays the most recent output from the server mem command.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "fps" and chatvars.words[2] == nil) then
			if botman.dbConnected then
				cursor,errorString = conn:execute("SELECT * FROM performance  ORDER BY serverdate DESC Limit 0, 1")
				row = cursor:fetch({}, "a")

				if row then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Server FPS: " .. server.fps .. " Players: " .. row.players .. " Zombies: " .. row.zombies .. " Entities: " .. row.entities .. " Heap: " .. row.heap .. " HeapMax: " .. row.heapMax .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "Server FPS: " .. server.fps .. " Players: " .. row.players .. " Zombies: " .. row.zombies .. " Entities: " .. row.entities .. " Heap: " .. row.heap .. " HeapMax: " .. row.heapMax)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShowServerStats()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "server") or string.find(chatvars.command, "stat") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "server stats")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Displays various server totals for the last 24 hours or more days if you add a number.")
					irc_chat(chatvars.ircAlias, "eg. " .. server.commandPrefix .. "server stats 5 (gives you the last 5 days cummulative stats)")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if ((chatvars.words[1] == "server" and string.find(chatvars.command, "stat")) and chatvars.words[4] == nil) then
			if chatvars.number == nil then
				chatvars.number = 1
			else
				chatvars.number = math.abs(math.floor(chatvars.number))
			end

			if chatvars.number == 0 then chatvars.number = 1 end

			if chatvars.number == 1 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]24 hour stats to now:[-]")
				else
					irc_chat(chatvars.ircAlias, "24 hour stats to now:")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. chatvars.number .. " day stats to now:[-]")
				else
					irc_chat(chatvars.ircAlias, chatvars.number .. " day stats to now:")
				end
			end

			cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%pvp%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]PVPs: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "PVPs: " .. row.number)
			end

			cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%timeout%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Timeouts: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Timeouts: " .. row.number)
			end

			cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%arrest%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Arrests: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Arrests: " .. row.number)
			end

			cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%new%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "New players: " .. row.number)
			end

			cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%ban%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bans: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Bans: " .. row.number)
			end

			cursor,errorString = conn:execute("SELECT MAX(players) as number FROM performance WHERE timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
			row = cursor:fetch({}, "a")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Most players online: " .. row.number .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Most players online: " .. row.number)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShowServerTime()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "date") or string.find(chatvars.command, "time") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "server date")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Displays the system clock of the game server.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if ((chatvars.words[1] == "server" and (chatvars.words[2] == "date" or chatvars.words[2] == "time")) and chatvars.words[3] == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The server date is " .. botman.serverTime .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "The server date is " .. botman.serverTime)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShowWherePlayer()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "where") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "where")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Gives info about where you are in the world and the rules that apply there.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "where" or chatvars.words[1] == "whereami") and chatvars.words[2] == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are " .. string.format("%.2f", (distancexz(chatvars.intX, chatvars.intZ,0,0) / 1000)) .. " km from the center of the map.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are at " .. mapPosition(chatvars.playerid) .. "[-]")

			if igplayers[chatvars.playerid].currentLocationPVP then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]PVP is allowed here.[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]PVE rules apply here. Do not kill players.[-]")
			end

			if players[chatvars.playerid].inLocation ~= "" then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in the location " .. players[chatvars.playerid].inLocation .. "[-]")
			end

			if players[chatvars.playerid].atHome then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are at home.[-]")
			else
				if tonumber(players[chatvars.playerid].homeY) > 0 then
					direction = getCompass(players[chatvars.playerid].homeX, players[chatvars.playerid].homeZ, chatvars.intX, chatvars.intZ)
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are " .. string.format("%.2f", (distancexz(chatvars.intX, chatvars.intZ, players[chatvars.playerid].homeX, players[chatvars.playerid].homeZ) / 1000)) .. " km to the " .. direction .. " of your first home.[-]")
				end

				if tonumber(players[chatvars.playerid].home2Y) > 0 then
					direction = getCompass(players[chatvars.playerid].home2X, players[chatvars.playerid].home2Z, chatvars.intX, chatvars.intZ)
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are " .. string.format("%.2f", (distancexz(chatvars.intX, chatvars.intZ, players[chatvars.playerid].home2X, players[chatvars.playerid].home2Z) / 1000)) .. " km to the " .. direction .. " of your second home.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Uptime()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "time") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "uptime")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Reports the bot and server's running times.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "uptime" and chatvars.words[2] == nil) then
				diff = os.difftime(os.time(), botman.botStarted)
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.botName .. " has been online " .. days .. " days " .. hours .. " hours " .. minutes .." minutes.[-]")
				else
					irc_chat(chatvars.ircAlias, server.botName .. " has been online " .. days .. " days " .. hours .. " hours " .. minutes .." minutes.")
				end

				if gameTick < 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Server uptime is unknown due to a server fault. Ask and admin to reboot the server.[-]")
					else
						irc_chat(chatvars.ircAlias, "Server uptime is unknown due to a server fault. Ask and admin to reboot the server.")
					end
				else
					diff = gameTick
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
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Server uptime is " .. days .. " days " .. hours .. " hours " .. minutes .." minutes.[-]")
					else
						irc_chat(chatvars.ircAlias, "Server uptime is " .. days .. " days " .. hours .. " hours " .. minutes .." minutes.")
					end
				end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ViewPlayerInfo()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "info") or string.find(chatvars.command, "play") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "info {player>")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Displays info about a player.  Only staff can specify a player.  Players just see their own info.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "info" and chatvars.words[2] ~= nil) then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "info") + 5)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if chatvars.accessLevel > 2 then
				if chatvars.playerid ~= id then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You may only view your own info.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if (id ~= 0) then
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

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Info for player " .. players[id].name .. "[-]")
				if players[id].newPlayer == true then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A new player.[-]") end
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Steam: " .. id .. " ID: " .. players[id].id .. "[-]")
				if players[id].firstSeen ~= nil then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]First seen: " .. os.date("%Y-%m-%d %H:%M:%S", players[id].firstSeen) .. "[-]") end
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Total time played: " .. days .. " days " .. hours .. " hours " .. minutes .. " minutes " .. time .. " seconds[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Has a bedroll at " .. players[id].bedX .. " " .. players[id].bedY .. " " .. players[id].bedZ .. "[-]")

				if players[id].homeX ~= 0 and players[id].homeY ~= 0 and players[id].homeZ ~= 0 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base one is at " .. players[id].homeX .. " " .. players[id].homeY .. " " .. players[id].homeZ .. "[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base one has not been set.[-]")
				end

				if players[id].home2X ~= 0 and players[id].home2Y ~= 0 and players[id].home2Z ~= 0 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base two is at " .. players[id].home2X .. " " .. players[id].home2Y .. " " .. players[id].home2Z .. "[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base two has not been set.[-]")
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

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" ..players[id].name .. " was last seen " .. days .. " days " .. hours .. " hours " .. minutes .." minutes ago[-]")

				if players[id].timeout then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Is in timeout[-]") end
				if players[id].prisoner then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Is a prisoner[-]")
					if players[id].prisonReason ~= nil then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reason Arrested: " .. players[id].prisonReason .. "[-]") end
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Keystones placed " .. players[id].keystones .. "[-]")

				if server.allowBank then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.moneyPlural .. " " .. players[id].cash .. "[-]")
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Current Session " .. players[id].sessionCount .. "[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]IP " .. players[id].ip .. "[-]")

				if players[id].donor then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Is a donor[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Donor status expires on " .. os.date("%Y-%m-%d %H:%M:%S",  players[id].donorExpiry))
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Is not a donor[-]")
				end

				cursor,errorString = conn:execute("SELECT * FROM bans WHERE steam =  " .. id)
				if cursor:numrows() > 0 then
					row = cursor:fetch({}, "a")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]BANNED until " .. row.BannedTo .. " " .. row.Reason .. "[-]")
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player name required or no match found.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WhenDay7()
		if (chatvars.words[1] == "when" and chatvars.words[2] == "feral") or chatvars.words[1] == "day7" or chatvars.words[1] == "bloodmoon" then
			day7(chatvars.playerid)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WhenNextReboot()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "next") or string.find(chatvars.command, "boot") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "next reboot")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Reports the time remaining before the next scheduled reboot.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if ((chatvars.words[1] == "when" or chatvars.words[1] == "next") and chatvars.words[2] == "reboot") then
			if server.delayReboot then
				if (server.gameDay % 7 == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The reboot will happen after day 7. Admins can force it with " .. server.commandPrefix .. "reboot now.[-]")
					else
						irc_chat(chatvars.ircAlias, "The reboot will happen after day 7. Admins can force it with " .. server.commandPrefix .. "reboot now.")
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
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "who") or string.find(chatvars.command, "info") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "who {optional number distance}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Reports who is around you.  Donors and staff can see distances.")
					irc_chat(chatvars.ircAlias, "Donors can see 300 metres and other players can see 200.  New and watched players can't see staff near them.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "who" and chatvars.words[2] ~= "visited" and chatvars.words[3] == nil) then
			alone = true

			if (chatvars.number == nil) then chatvars.number = 500 end

			if (chatvars.accessLevel > 2) then
				chatvars.number = 300
			end

			if (chatvars.accessLevel > 10) then
				chatvars.number = 200
			end

			x = math.floor(igplayers[chatvars.playerid].xPos / 512)
			z = math.floor(igplayers[chatvars.playerid].zPos / 512)

			if (tonumber(chatvars.intX) < 0) then xdir = " west " else xdir = " east " end
			if (tonumber(chatvars.intZ) < 0) then zdir = " south" else zdir = " north" end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are at " .. chatvars.intX .. xdir .. chatvars.intZ .. zdir .. " at a height of " .. chatvars.intY .. "[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in region r." .. x .. "." .. z .. ".7[-]")

			if (pvpZone(chatvars.intX, chatvars.intZ) == false) or (server.gameType ~= "pvp") or chatvars.accessLevel < 3 then
				for k, v in pairs(igplayers) do
					dist = distancexz(chatvars.intX, chatvars.intZ, v.xPos, v.zPos)

					if dist <= tonumber(chatvars.number) then
						if (v.steam ~= chatvars.playerid) then
							if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]players within " .. chatvars.number .. " meters of you are:[-]") end

							if (chatvars.accessLevel < 11) then
								x = math.floor(v.xPos / 512)
								z = math.floor(v.zPos / 512)

								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%d", dist) .. " region r." .. x .. "." .. z .. ".7rg[-]")
							else
								if (players[chatvars.playerid].watchPlayer == true) and accessLevel(v.steam) > 2 then
									message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. "[-]")
								end

								if (players[chatvars.playerid].watchPlayer == false) then
									message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. "[-]")
								end
							end
							alone = false
						end
					end
				end

				if alone then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Nobody is within " .. chatvars.number .. " meters of you.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WhoVisitedMe()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "who") or string.find(chatvars.command, "visit"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "who visited {player name} days {days} hours {hrs} range {dist} height {ht}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "See who visited a player location or base.")
					irc_chat(chatvars.ircAlias, "Example with defaults: " .. server.commandPrefix .. "who visited player smeg days 1 hours 0 range 10 height 5")
					irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "who visited bed smeg")
					irc_chat(chatvars.ircAlias, "Add base to just see base visitors. Setting hours will reset days to zero.")
					irc_chat(chatvars.ircAlias, "Use this command to discover who's been at the player's location.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "who" and chatvars.words[2] == "visited") then
			if chatvars.accessLevel > 2 then
				if server.gameType == "pvp" then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is not available in PVP.[-]")

					botman.faultyChat = false
					return true
				end

				if igplayer[chatvars.playerid] then
					if igplayers[chatvars.playerid].currentLocationPVP then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is not available in PVP.[-]")

						botman.faultyChat = false
						return true
					end
				end
			end

			if (chatvars.words[3] == nil) then
				if (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]See who visited your base (or 2nd base).[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Examples with defaults:[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who visited base1/base2 days 1 hours 0 range 10 height 5[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who visited my bed[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Setting hours will reset days to zero[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will report up to right now.  You can't ask for just 2 days ago currently.[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Range is limited to 100 metres from your base teleport.[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]See who visited a player location or base.[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Example with defaults:[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who visited player smeg days 1 hours 0 range 10 height 5[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who visited bed smeg[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Add base to just see their base visitors[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Setting hours will reset days to zero[-]")
				end

				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.days = 1
			tmp.hours = 0
			tmp.range = 10
			tmp.height = 0
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
				if (chatvars.accessLevel < 3) then
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

						if tmp.steam == 0 then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. tmp.name .. "[-]")
							else
								irc_chat(chatvars.ircAlias, "No player found matching " .. tmp.name)
							end

							botman.faultyChat = false
							return true
						end

						if tmp.steam and chatvars.words[i] == "player" then
							tmp.player = true
							tmp.x = players[tmp.steam].xPos
							tmp.y = players[tmp.steam].yPos
							tmp.z = players[tmp.steam].zPos
						end

						if tmp.steam and chatvars.words[i] == "bed" then
							tmp.bed = true
							tmp.x = players[tmp.steam].bedX
							tmp.y = players[tmp.steam].bedY
							tmp.z = players[tmp.steam].bedZ
						end
					end
				end

				-- player settings
				if (chatvars.accessLevel > 2) then
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
			if (chatvars.accessLevel < 3) then
				if (tmp.basesOnly == "base") and tmp.steam then
					if players[tmp.steam].homeX ~= 0 and players[tmp.steam].homeZ ~= 0 then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of base 1 of " .. players[tmp.steam].name .. " at " .. players[tmp.steam].homeX .. " " .. players[tmp.steam].homeY .. " " .. players[tmp.steam].homeZ .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
						dbWho(chatvars.playerid, players[tmp.steam].homeX, players[tmp.steam].homeY, players[tmp.steam].homeZ, tmp.range, tmp.days, tmp.hours, tmp.height, true)
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. " does not have a base set yet.[-]")
					end

					if players[tmp.steam].home2X ~= 0 and players[tmp.steam].home2Z ~= 0 then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of base 2 of " .. players[tmp.steam].name .. " at " .. players[tmp.steam].home2X .. " " .. players[tmp.steam].home2Y .. " " .. players[tmp.steam].home2Z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
						dbWho(chatvars.playerid, players[tmp.steam].home2X, players[tmp.steam].home2Y, players[tmp.steam].home2Z, tmp.range, tmp.days, tmp.hours, tmp.height, true)
					end
				end

				if tmp.basesOnly == "player" and tmp.steam then
					if tmp.player then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. " at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
					end

					if tmp.bed then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of player " .. players[tmp.steam].name .. "'s bed at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
					end

					dbWho(chatvars.playerid, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height, true)
				end

				if not tmp.steam then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
					dbWho(chatvars.playerid, tmp.x, tmp.y, tmp.z, tmp.range, tmp.days, tmp.hours, tmp.height, true)
				end
			end


			-- player version
			if (chatvars.accessLevel > 2) then
				-- set some defaults and limits
				if tmp.height == 0 then tmp.height = 30 end
				if tmp.range > 100 then tmp.range = 100 end

				if tmp.base == "1" then
					if players[tmp.steam].homeX ~= 0 and players[tmp.steam].homeZ ~= 0 then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of your home at " .. players[tmp.steam].homeX .. " " .. players[tmp.steam].homeY .. " " .. players[tmp.steam].homeZ .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
						dbWho(chatvars.playerid, players[tmp.steam].homeX, players[tmp.steam].homeY, players[tmp.steam].homeZ, tmp.range, tmp.days, tmp.hours, tmp.height, true)
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not done " .. server.commandPrefix .. "sethome yet.[-]")
					end
				end

				if tmp.base == "2" then
					if players[tmp.steam].home2X ~= 0 and players[tmp.steam].home2Z ~= 0 then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who visited within " .. tmp.range .. " metres of your second home at " .. players[tmp.steam].home2X .. " " .. players[tmp.steam].home2Y .. " " .. players[tmp.steam].home2Z .. " days " .. tmp.days .. " hours " .. tmp.hours .. " height " .. tmp.height .. "[-]")
						dbWho(chatvars.playerid, players[tmp.steam].home2X, players[tmp.steam].home2Y, players[tmp.steam].home2Z, tmp.range, tmp.days, tmp.hours, tmp.height, true)
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not done " .. server.commandPrefix .. "sethome2 yet (if you can have a 2nd home).[-]")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "info" then
				skipHelp = true
			end
		end

		-- if chatvars.words[1] == "help" then
			-- skipHelp = false
		-- end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Info Commands:")
		irc_chat(chatvars.ircAlias, "==============")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "info")
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_Uptime()

	if result then
		if debug then dbug("debug cmd_Uptime triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ServerInfo()

	if result then
		if debug then dbug("debug cmd_ServerInfo triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhenNextReboot()

	if result then
		if debug then dbug("debug cmd_WhenNextReboot triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhenDay7()

	if result then
		if debug then dbug("debug cmd_WhenDay7 triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShowServerFPS()

	if result then
		if debug then dbug("debug cmd_ShowServerFPS triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShowServerTime()

	if result then
		if debug then dbug("debug cmd_ShowServerTime triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShowServerStats()

	if result then
		if debug then dbug("debug cmd_ShowServerStats triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListNewPlayers()

	if result then
		if debug then dbug("debug cmd_ListNewPlayers triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_SeenPlayer()

	if result then
		if debug then dbug("debug cmd_SeenPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShowRules()

	if result then
		if debug then dbug("debug cmd_ShowRules triggered") end
		return result
	end

	if debug then dbug("debug info end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == 0 and not chatvars.showHelp then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Info Commands (In-Game Only):")
		irc_chat(chatvars.ircAlias, "=============================")
		irc_chat(chatvars.ircAlias, ".")
	end

	result = cmd_ShowWherePlayer()

	if result then
		if debug then dbug("debug cmd_ShowWherePlayer triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	-- help
	if chatvars.words[1] == "help" and chatvars.ircid == 0 then
		if chatvars.words[2] ~= nil then
			cmd = string.trim(string.sub(chatvars.command, 7))
		end

		help(cmd)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "commands") then
		help("commands")
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "status") then
		botman.faultyChat = baseStatus(chatvars.command, chatvars.playerid)
		return true
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	if string.find(chatvars.command, "pvp") and (chatvars.accessLevel == 99) and (chatvars.words[1] ~= "help") then
		if (server.gameType == "pvp") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a PVP server.[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a PVE server.  No PVP except in PVP zones.  Read /help pvp for info.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhoIsNearPlayer()
	if result then
		if debug then dbug("debug cmd_WhoIsNearPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_SendAlertToAdmins()
	if result then
		if debug then dbug("debug cmd_SendAlertToAdmins triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_ViewPlayerInfo()
	if result then
		if debug then dbug("debug cmd_ViewPlayerInfo triggered") end
		return result
	end

	if (debug) then dbug("debug info line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhoVisitedMe()
	if result then
		if debug then dbug("debug cmd_WhoVisitedMe triggered") end
		return result
	end

	if debug then dbug("debug info end") end

	-- can't touch dis
	if true then
		return result
	end

end
