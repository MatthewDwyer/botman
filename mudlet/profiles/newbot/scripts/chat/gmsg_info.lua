--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_info()
	calledFunction = "gmsg_info"

	local xdir, zdir, dist, x, z, diff, days, hours, minutes, result, tokens, time	, werds, word, cmd
	local debug
	local shortHelp = false
	local skipHelp = false
	
	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
		return false
	end
	
	if chatvars.showHelp then
		if chatvars.words[3] then		
			if chatvars.words[3] ~= "info" then
				skipHelp = true
			end
		end
		if chatvars.words[1] == "help" then
			skipHelp = false
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Info Commands:")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "==============")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
	end

if debug then dbug("debug info 1") end

	result = false
	
	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/uptime")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Reports the bot and server's running times.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "uptime" and chatvars.words[2] == nil) then
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

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.botName .. " has been online " .. days .. " days " .. hours .. " hours " .. minutes .." minutes.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, server.botName .. " has been online " .. days .. " days " .. hours .. " hours " .. minutes .." minutes.")
			end

			if gameTick < 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Server uptime is unknown due to a server fault. Ask and admin to reboot the server.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "Server uptime is unknown due to a server fault. Ask and admin to reboot the server.")
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
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "Server uptime is " .. days .. " days " .. hours .. " hours " .. minutes .." minutes.")
				end				
			end

		faultyChat = false
		return true
	end 

if debug then dbug("debug info 2") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "server") or string.find(chatvars.command, "info"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/server or /info")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Displays info mostly from the server config.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "server" or chatvars.words[1] == "info") and chatvars.words[2] == nil then
		if (chatvars.playername ~= "Server") then
			-- Server name
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This server is " .. server.ServerName .. " " .. server.IP .. ":" .. server.ServerPort .. "[-]")	

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
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Land claim size is " .. server.LandClaimSize .. " meters. Expiry 30 days[-]")

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

			-- zombie memory
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Zombie memory is " .. server.EnemySenseMemory .. " seconds[-]")

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
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "This server is " .. server.ServerName .. " " .. server.IP .. ":" .. server.ServerPort)	

			if (server.gameType == "pve") then irc_QueueMsg(players[chatvars.ircid].ircAlias, "This is a PVE server.") end
			if (server.gameType == "pvp") then irc_QueueMsg(players[chatvars.ircid].ircAlias, "This is a PVP server.") end
			if (server.gameType == "cre") then irc_QueueMsg(players[chatvars.ircid].ircAlias, "This is a creative mode server.") end

			-- day/night length
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "A full day runs " .. server.DayNightLength .. " minutes.")

			-- drop on death
			if (server.DropOnDeath == 0) then irc_QueueMsg(players[chatvars.ircid].ircAlias, "You drop everything on death.") end
			if (server.DropOnDeath == 1) then irc_QueueMsg(players[chatvars.ircid].ircAlias, "You drop toolbelt on death.") end
			if (server.DropOnDeath == 2) then irc_QueueMsg(players[chatvars.ircid].ircAlias, "You drop backpack on death.") end
			if (server.DropOnDeath == 3) then irc_QueueMsg(players[chatvars.ircid].ircAlias, "You permanently lose everything on death.") end

			-- drop on quit
			if (server.DropOnQuit == 0) then irc_QueueMsg(players[chatvars.ircid].ircAlias, "You keep everything on quit.") end
			if (server.DropOnQuit == 1) then irc_QueueMsg(players[chatvars.ircid].ircAlias, "You drop everything on quit.") end
			if (server.DropOnQuit == 2) then irc_QueueMsg(players[chatvars.ircid].ircAlias, "You drop toolbelt only on quit.") end
			if (server.DropOnQuit == 3) then irc_QueueMsg(players[chatvars.ircid].ircAlias, "You drop backpack only on quit.") end

			-- land claim size
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Land claim size is " .. server.LandClaimSize .. " meters. Expiry 30 days.")

			-- block durability
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Block durability is " .. server.BlockDurabilityModifier .. "%")

			-- loot abundance
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Loot abundance is " .. server.LootAbundance .. "%")

			-- loot respawn
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Loot respawns after " .. server.LootRespawnDays .. " days.")

			-- zombies run
			if (server.ZombiesRun == 0) then irc_QueueMsg(players[chatvars.ircid].ircAlias, "Zombies run at night.") end
			if (server.ZombiesRun == 1) then irc_QueueMsg(players[chatvars.ircid].ircAlias, "Zombies never run.") end
			if (server.ZombiesRun == 2) then irc_QueueMsg(players[chatvars.ircid].ircAlias, "Zombies always run.") end

			-- zombie memory
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Zombie memory is " .. server.EnemySenseMemory .. " seconds.")

			-- map limit
			if players[chatvars.ircid].donor or accessLevel(chatvars.ircid) < 2 then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The world is limited to  " .. (server.mapSize + 10000) / 1000 .. " km from map center.")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The world is limited to  " .. server.mapSize / 1000 .. " km from map center.")
			end

			if server.idleKick then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "When the server is full, idle players are kicked after 15 minutes.")
			end
		end	
		
		faultyChat = false
		return true
	end

if debug then dbug("debug info 3") end	

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "next") or string.find(chatvars.command, "boot"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/next reboot")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Reports the time remaining before the next scheduled reboot.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end
	
	if (chatvars.words[1] == "when" or chatvars.words[1] == "next") and chatvars.words[2] == "reboot" then		
		if server.delayReboot then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Feral hordes run today so the reboot is suspended until midnight.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Feral hordes run today so the reboot is suspended until midnight.")
			end			
		else
			if (chatvars.playername ~= "Server") then
				nextReboot(chatvars.playerid)
			else
				nextReboot(chatvars.ircid)
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug info 4") end	

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "fps") or string.find(chatvars.command, "perf"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/fps")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Displays the most recent output from the server mem command.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end
	
	if (chatvars.words[1] == "fps" and chatvars.words[2] == nil) then
		cursor,errorString = conn:execute("SELECT * FROM performance  ORDER BY serverdate DESC Limit 0, 1")
		row = cursor:fetch({}, "a")

		if row then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Server FPS: " .. server.fps .. " Players: " .. row.players .. " Zombies: " .. row.zombies .. " Entities: " .. row.entities .. " Heap: " .. row.heap .. " HeapMax: " .. row.heapMax .. "[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Server FPS: " .. server.fps .. " Players: " .. row.players .. " Zombies: " .. row.zombies .. " Entities: " .. row.entities .. " Heap: " .. row.heap .. " HeapMax: " .. row.heapMax)
			end			
		end

		faultyChat = false
		return true
	end	
	
if debug then dbug("debug info 5") end	

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "date") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/server date")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Displays the system clock of the game server.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end
	
	if ((chatvars.words[1] == "server" and (chatvars.words[2] == "date" or chatvars.words[2] == "time")) and chatvars.words[3] == nil) then
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The server date is " .. serverTime .. "[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "The server date is " .. serverTime)
		end
		
		faultyChat = false
		return true
	end	
	
if debug then dbug("debug info 6") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "server") or string.find(chatvars.command, "stat"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/server stats")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Displays various server totals for the last 24 hours or more days if you add a number.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "eg. /server stats 5 (gives you the last 5 days cummulative stats)")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
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
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "24 hour stats to now:")
			end	
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. chatvars.number .. " day stats to now:[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, chatvars.number .. " day stats to now:")
			end			
		end
	
		cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%pvp%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
		row = cursor:fetch({}, "a")
		
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]PVPs: " .. row.number .. "[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "PVPs: " .. row.number)
		end							
		
		cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%timeout%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
		row = cursor:fetch({}, "a")
		
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Timeouts: " .. row.number .. "[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Timeouts: " .. row.number)
		end									
		
		cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%arrest%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
		row = cursor:fetch({}, "a")
		
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Arrests: " .. row.number .. "[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Arrests: " .. row.number)
		end									

		cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%new%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
		row = cursor:fetch({}, "a")
		
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players: " .. row.number .. "[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "New players: " .. row.number)
		end

		cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE event LIKE '%ban%' AND timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
		row = cursor:fetch({}, "a")
		
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bans: " .. row.number .. "[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Bans: " .. row.number)
		end
		
		cursor,errorString = conn:execute("SELECT MAX(players) as number FROM performance WHERE timestamp > DATE_SUB(now(), INTERVAL " .. chatvars.number .. " DAY)")
		row = cursor:fetch({}, "a")
		
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Most players online: " .. row.number .. "[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "Most players online: " .. row.number)
		end		

		faultyChat = false
		return true
	end	
	
if debug then dbug("debug info 7") end	

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "new") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/new players <optional number (days)")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "List the new players and basic info about them in the last day or more.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "new" and chatvars.words[2] == "players") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
				faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
				faultyChat = false
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
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "New players in the last " .. math.floor(number / 86400) .. " days:")
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
				irc_QueueMsg(players[chatvars.ircid].ircAlias, msg)
			end		
		
			row = cursor:fetch(row, "a")	
		end

		faultyChat = false
		return true
	end
	
if debug then dbug("debug info 8") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "see") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/seen <player>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Reports when the player was last on the server.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
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
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "player " .. players[id].name .. " is playing right now.")
			end		
			
			faultyChat = false
			return true
		end

		if (players[id]) then
			werds = {}
			for word in serverTime:gmatch("%w+") do table.insert(werds, word) end

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
				irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " was last seen " .. days .. " days " .. hours .. " hours " .. minutes .." minutes ago.")
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry I don't know a player called " .. pname .. ". Check your spelling.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Sorry I don't know a player called " .. pname .. ". Check your spelling.")
			end		
		end

		faultyChat = false
		return true
	end
	
if debug then dbug("debug info 9") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rule") or string.find(chatvars.command, "server"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/rules")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Reports the server rules.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "rules" and chatvars.words[2] == nil) then
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.rules .."[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, server.rules)
		end			
		
		faultyChat = false
		return true
	end
	
if debug then dbug("debug info 10") end

	-- ###################  do not allow remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)
	
	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Info Commands (In-Game Only):")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "=============================")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
	end	
	
	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "where"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/where")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Gives info about where you are in the world and the rules that apply there.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end	

	if (chatvars.words[1] == "where" or chatvars.words[1] == "whereami") and chatvars.words[2] == nil and (chatvars.playerid ~= 0) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are " .. string.format("%.2f", (distancexz(chatvars.intX, chatvars.intZ,0,0) / 1000)) .. " km from the center of the map.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are at " .. mapPosition(chatvars.playerid) .. "[-]")

		if pvpZone(chatvars.intX, chatvars.intZ) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]PVP is allowed here.[-]")
		else
			if (server.gameType ~= "pvp") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]PVE rules apply here. Do not kill players.[-]")
			end
		end

		if players[chatvars.playerid].inLocation ~= "" then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in the location " .. players[chatvars.playerid].inLocation .. "[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug info 11") end

	if (string.find(chatvars.command, "server") and (string.find(chatvars.command, "favourite") or string.find(chatvars.command, "favs") or string.find(chatvars.command, "called") or string.find(chatvars.command, "name") or string.find(chatvars.command, " ip"))) and (chatvars.playerid ~= 0) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This server is " .. server.ServerName .. " " .. server.IP .. ":" .. server.ServerPort .. "[-]")
		faultyChat = false
		return true
	end

if debug then dbug("debug info 12") end

	-- help
	if (chatvars.words[1] == "help") and (chatvars.playerid ~= 0) then
		if chatvars.words[2] ~= nil then
			cmd = string.trim(string.sub(chatvars.command, 7))
		end

		help(cmd)

		faultyChat = false
		return true
	end

if debug then dbug("debug info 13") end

	if (chatvars.words[1] == "commands") then
		help("commands")
		faultyChat = false
		return true
	end

if debug then dbug("debug info 14") end

	if (chatvars.words[1] == "status") and (chatvars.playerid ~= 0) then
		faultyChat = baseStatus(chatvars.command, chatvars.playerid)
		return true
	end

if debug then dbug("debug info 15") end

	if (chatvars.words[1] == "tokens" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if players[chatvars.playerid].tokens == nil then
			players[chatvars.playerid].tokens = 0
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have " .. players[chatvars.playerid].tokens .. " tokens remaining.[-]")

		if players[chatvars.playerid].tokens == 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Tokens can be purchased from the shop.  They give you access to special features such as teleporting directly to a friend.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug info 16") end

	if string.find(chatvars.command, "pvp") and (accessLevel(chatvars.playerid) == 99) and (chatvars.words[1] ~= "help") and (chatvars.playerid ~= 0) then
		if (server.gameType == "pvp") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a PVP server.[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a PVE server.  No PVP except in PVP zones.  Read /help pvp for info.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug info 17") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "who") or string.find(chatvars.command, "info"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/who <optional number distance>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Reports who is around you.  Donors and staff can see distances.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Donors can see 300 metres and other players can see 200.  New and watched players can't see staff near them.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "who" and chatvars.words[3] == nil) and (chatvars.playerid ~= 0) then	
		alone = true

		if (chatvars.number == nil) then chatvars.number = 500 end

		if (accessLevel(chatvars.playerid) > 2) then
			chatvars.number = 300
		end

		if (accessLevel(chatvars.playerid) > 10) then
			chatvars.number = 200
		end

		x = math.floor(igplayers[chatvars.playerid].xPos / 512)
		z = math.floor(igplayers[chatvars.playerid].zPos / 512)

		if (tonumber(chatvars.intX) < 0) then xdir = " west " else xdir = " east " end
		if (tonumber(chatvars.intZ) < 0) then zdir = " south" else zdir = " north" end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are at " .. chatvars.intX .. xdir .. chatvars.intZ .. zdir .. " at a height of " .. chatvars.intY .. "[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in region r." .. x .. "." .. z .. ".7rg[-]")

		if (pvpZone(chatvars.intX, chatvars.intZ) == false) or (server.gameType ~= "pvp") then
			for k, v in pairs(igplayers) do
				dist = distancexz(chatvars.intX, chatvars.intZ, v.xPos, v.zPos)

				if dist <= tonumber(chatvars.number) then
					if (v.steam ~= chatvars.playerid) then
						if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]players within " .. chatvars.number .. " meters of you are:[-]") end

						if (accessLevel(chatvars.playerid) < 11) then
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

		faultyChat = false
		return true
	end

if debug then dbug("debug info 18") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "alert") or string.find(chatvars.command, "info"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/alert <message>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Whatever is typed after /alert is recorded to the database and displayed on irc.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You can recall the alerts with the irc command view alerts <optional days>")				
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "alert") and (chatvars.playerid ~= 0) then
		if (chatvars.words[2] == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Please include a message eg /alert Claimed shop here![-]")
			faultyChat = false
			return true
		end

		command = string.sub(chatvars.command, string.find(chatvars.command, "alert ") + 6)
		cecho("alerts", "***** " .. chatvars.playername .. " at position " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ .. " said: " .. command .. "\n")
		sendIrc(server.ircAlerts, "***** " .. chatvars.playername .. " at position " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ .. " said: " .. command .. "\n")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Thank you! Your message has been recorded! =D[-]")

		conn:execute("INSERT INTO alerts (steam, x, y, z, message) VALUES (" .. chatvars.playerid .. "," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. command .. "')")

		faultyChat = false
		return true
	end

if debug then dbug("debug info 19") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "info") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/info <player>")	
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Displays info about a player.  Only staff can specify a player.  Players just see their own info.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "info" and chatvars.words[2] ~= nil) and (chatvars.playerid ~= 0) then		
		pname = string.sub(chatvars.command, string.find(chatvars.command, "info") + 5)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if accessLevel(chatvars.playerid) > 2 then
			if chatvars.playerid ~= id then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You may only view your own info.[-]")
				faultyChat = false
				return true
			end
		end

		if (id ~= nil) then
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

			werds = {}
			for word in serverTime:gmatch("%w+") do table.insert(werds, word) end

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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Zennies " .. players[id].cash .. "[-]")
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Current Session " .. players[id].sessionCount .. "[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]IP " .. players[id].ip .. "[-]")

			if players[id].donor then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Is a donor[-]")
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

		faultyChat = false
		return true
	end
	
if debug then dbug("debug info 20") end

	if (chatvars.words[1] == "about" and chatvars.words[2] == "bot") and (chatvars.playerid ~= 0) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.botName .. " is written by Smegzor. It is 100% free and open source.  Visit botman.nz for more info.[-]")

		faultyChat = false
		return true
	end

if debug then dbug("debug info end") end

end
