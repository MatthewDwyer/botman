--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function playerInfo(faultyInfo)
	-- EDIT THIS FUNCTION WITH CARE.  This function is central to player management.  Some lines need to be run before others.
	-- Lua will stop execution wherever it strikes a fault (usually trying to use a non-existing variable)
	-- enable debugging to see roughly where the bot gets to.  It should reach 'end playerinfo'.
	-- Good luck :)

	local tmp = {}

	faultyPlayerinfo = true
	faultyPlayerinfoID = 0
	faultyPlayerinfoLine = line

	local debug, id, name, posX, posY, posZ, lastX, lastY, lastZ, lastDist, mapCenterDistance, regionX, regionZ, chunkX, chunkZ
	local deaths, zombies, kills, score, level, steam, steamtest, admin, lastGimme, lastLogin
	local xPosOld, yPosOld, zPosOld, rawPosition, rawRotation, outsideMap, outsideMapDonor, fields, values, flag
	local isAdmin = "No"
	local isPrisoner = "No"
	local timestamp = os.time()
	local region = ""
	local resetZone = false
	local ping, dist, IP, hotspot, currentLocation
	local skipTPtest = false
	local badData = false

	debug = false

	if debugPlayerInfo == nil then debugPlayerInfo = 0 end

	-- Set debugPlayerInfo to the steam id or player name that you want to monitor.  If the player is not on the server, the bot will reset debugPlayerInfo to zero.
	debugPlayerInfo = 0

	if (debugPlayerInfo ~= 0) then
		dbug("debug playerinfo " .. debugPlayerInfo, true)
		dbug(line, true)
	end

	flag = ""
	name_table = string.split(line, ", ")

	if string.find(name_table[3], "pos") then
		name = string.trim(name_table[2])
	else
		temp = name_table[1] .. ", name" .. string.sub(line, string.find(line, ", pos="), string.len(line))
		name_table = string.split(temp, ", ")
		name = string.trim(string.sub(line, string.find(line, ",") + 2, string.find(line, ", pos=") - 1))
	end

	-- stop processing this player if we don't have 18 parts to the line after splitting on comma
	-- it is probably a read error
	if (table.maxn(name_table) < 18) then
		faultyPlayerinfoID = 0
		dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true)
		return
	end

--dbug("debug playerinfo line " .. debugger.getinfo(1).currentline)

	temp = string.split(name_table[1], "=")
	id = temp[2]

	num = tonumber(string.sub(name_table[3], 6))
	if (num == nil) then badData = true end
	posX = num

	num = tonumber(name_table[4])
	if (num == nil) then badData = true end
	posY = num

	temp = string.split(name_table[5], ")")
	num = tonumber(temp[1])
	if (num == nil) then badData = true end
	posZ = num

	num = tonumber(name_table[7])
	if (num == nil) then badData = true end
	rotY = num

	temp = string.split(name_table[11], "=")
	num = tonumber(temp[2])
	if (num == nil) then badData = true end
	deaths = num

	temp = string.split(name_table[12], "=")
	num = tonumber(temp[2])
	if (num == nil) then badData = true end
	zombies = num

	temp = string.split(name_table[13], "=")
	num = tonumber(temp[2])
	if (num == nil) then badData = true end
	kills = num

	temp = string.split(name_table[14], "=")
	num = tonumber(temp[2])
	if (num == nil) then badData = true end
	score = num

	temp = string.split(name_table[15], "=")
	num = tonumber(temp[2])
	if (num == nil) then badData = true end
	level = num

	temp = string.split(name_table[16], "=")
	if (num == nil) then badData = true end
	steam = temp[2]

	faultyPlayerinfoID = steam

	temp = string.split(name_table[17], "=")
	IP = temp[2]
	IP = IP:gsub("::ffff:","")

	temp = string.split(name_table[18], "=")
	ping = temp[2]

--dbug("debug playerinfo line " .. debugger.getinfo(1).currentline)

--dbug("debug playerinfo steam " .. steam)
--dbug("debug debugplayerinfo  " .. debugPlayerInfo)

	if badData then
		dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true)
		dbug("Bad lp line: " .. line .. "\n", true)
		return
	end

--dbug("debug playerinfo line " .. debugger.getinfo(1).currentline)

	rawPosition = posX .. posY .. posZ
	rawRotation = rotY

--dbug("debug playerinfo line " .. debugger.getinfo(1).currentline)

	intX = math.floor(posX)
	intY = math.ceil(posY)
	intZ = math.floor(posZ)

--dbug("debug playerinfo line " .. debugger.getinfo(1).currentline)

	region = getRegion(intX, intZ)
	regionX, regionZ, chunkX, chunkZ = getRegionChunkXZ(intX, intZ)

--dbug("debug playerinfo line " .. debugger.getinfo(1).currentline)

	if (resetRegions[region]) then
--dbug("debug playerinfo line " .. debugger.getinfo(1).currentline)
		resetZone = true
	else
--dbug("debug playerinfo line " .. debugger.getinfo(1).currentline)
		resetZone = false
	end

--dbug("debug playerinfo line " .. debugger.getinfo(1).currentline)

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

--dbug("debug playerinfo line " .. debugger.getinfo(1).currentline)

	-- check for crazy server crash
	if (string.find(line, "type=EntityZombie")) then
		if botman.nextRebootTest == nil or (botman.nextRebootTest ~= nil and os.time() > botman.nextRebootTest) then
			if (botman.scheduledRestart == true) and botman.scheduledRestartForced == false then
				gmsg(server.commandPrefix .. "cancel reboot")
			end

			if botman.scheduledRestartForced == false then
				message("say [" .. server.chatColour .. "]Zombies have been detected in the player data and an urgent reboot has been initiated to fix it.[-]")
				message("say [" .. server.chatColour .. "]You have 2 minutes to stop what you are doing and clear your crafting, forges and campfires.[-]")
				gmsg(server.commandPrefix .. "reboot server 2 minutes forced")
			end
		end

		return
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- check for invalid or missing steamid.  kick if not passed
	steamtest = tonumber(steam)
	if (steamtest == nil) and (steam ~= "") or (string.len(steam) < 17) then
		send ("kick " .. id)

		faultyPlayerinfo = false
		return
	end

	-- add to in-game players table
	if (igplayers[steam] == nil) then
		igplayers[steam] = {}
		igplayers[steam].id = id
		igplayers[steam].name = name
		igplayers[steam].steam = steam
		igplayers[steam].steamOwner = steam

		fixMissingIGPlayer(steam)

		-- don't initially warn the player about pvp or pve zone.  Too many players complain about it when the bot is restarted.  We can warn them next time their zone changes.
		if pvpZone(posX, posZ) then
			if players[steam].alertPVP == true then
				players[steam].alertPVP = false
			end
		else
			if players[steam].alertPVP == false then
				players[steam].alertPVP = true
			end
		end
	end

	if igplayers[steam].checkNewPlayer == nil then
		fixMissingIGPlayer(steam)
	end

	-- add to players table
	if (players[steam] == nil) then
		players[steam] = {}
		players[steam].id = id
		players[steam].name = name
		players[steam].steam = steam

		if tonumber(score) == 0 and tonumber(zombies) == 0 and tonumber(deaths) == 0 then
			players[steam].newPlayer = true
		else
			players[steam].newPlayer = false
		end

		players[steam].watchPlayer = true
		players[steam].watchPlayerTimer = os.time() + 2419200 -- stop watching in one month or until no longer a new player
		players[steam].IP = IP
		players[steam].exiled = 0

		irc_chat(server.ircMain, "###  New player joined " .. player .. " steam: " .. steam.. " id: " .. id .. " ###")
		irc_chat(server.ircAlerts, "New player joined")
		irc_chat(server.ircAlerts, line)

		if botman.dbConnected then
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(posX) .. "," .. math.floor(posY) .. "," .. math.floor(posZ) .. ",'" .. botman.serverTime .. "','new player','New player joined " .. name .. " steam: " .. steam.. " id: " .. id .. "'," .. steam .. ")")
			conn:execute("INSERT INTO players (steam, name, id, IP, newPlayer, watchPlayer, watchPlayerTimer) VALUES (" .. steam .. ",'" .. escape(name) .. "'," .. id .. "," .. IP .. ",1,1, " .. os.time() + 2419200 .. ")")
		end

		fixMissingPlayer(steam)
		CheckBlacklist(steam, IP)
	end

	if tonumber(ping) > 0 then
		igplayers[steam].ping = ping
		players[steam].ping = ping
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if faultyInfo == steam then
		-- Attempt to fix the fault assuming it set some stuff because of it
		if igplayers[steam].yPosLastOK == 0 then
			igplayers[steam].xPosLastOK = intX
			igplayers[steam].yPosLastOK = intY
			igplayers[steam].zPosLastOK = intZ
		end
	end

	if (players[steam].prisoner == true) then
		isPrisoner = "Yes"
	end

	if accessLevel(steam) < 3 then
		isAdmin = "Yes"
	end

	if IP ~= "" and players[steam].IP == "" then
		players[steam].IP = IP
		CheckBlacklist(steam, IP)
	end

	-- ping kick
	if not whitelist[steam] and players[steam].newPlayer then
		if tonumber(ping) < tonumber(server.pingKick) and tonumber(server.pingKick) > 0 then
			igplayers[steam].highPingCount = tonumber(igplayers[steam].highPingCount) - 1
			if tonumber(igplayers[steam].highPingCount) < 0 then igplayers[steam].highPingCount = 0 end
		end

		if tonumber(ping) > tonumber(server.pingKick) and tonumber(server.pingKick) > 0 then
			igplayers[steam].highPingCount = tonumber(igplayers[steam].highPingCount) + 1

			if tonumber(igplayers[steam].highPingCount) > 15 then
				irc_chat(server.ircMain, "Kicked " .. name .. " steam: " .. steam.. " for high ping " .. ping)
				kick(steam, "High ping kicked.")
				return
			end
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if tonumber(intY) > 0 and tonumber(intY) < 500 then
		igplayers[steam].lastTP = nil
		forgetLastTP(steam)
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if players[steam].location ~= "" and tonumber(igplayers[steam].teleCooldown) < 1 then
		-- spawn the player at location
		if (locations[players[steam].location]) then
			message(string.format("pm %s [%s]You are being moved to %s[-]", steam, server.chatColour, players[steam].location))
			randomTP(steam, players[steam].location, true)

			players[steam].location = ""
			if botman.dbConnected then conn:execute("UPDATE players SET location = '' WHERE steam = " .. steam) end
		end

		if (players[steam].location == "return player") then

			if players[steam].xPosTimeout ~= 0 and players[steam].zPosTimeout ~= 0 then
				cmd = "tele " .. steam .. " " .. players[steam].xPosTimeout .. " " .. players[steam].yPosTimeout .. " " .. players[steam].zPosTimeout
				players[steam].xPosTimeout = 0
				players[steam].yPosTimeout = 0
				players[steam].zPosTimeout = 0
			else
				cmd = "tele " .. steam .. " " .. players[steam].xPosOld .. " " .. players[steam].yPosOld .. " " .. players[steam].zPosOld
			end

			teleport(cmd, steam)
			players[steam].location = ""
			if botman.dbConnected then conn:execute("UPDATE players SET location = '' WHERE steam = " .. steam) end
		end
	end

	if tonumber(players[steam].hackerScore) >= 10000 then
		players[steam].hackerScore = 0
		message(string.format("say [%s]Banning %s. Detected evidence of hacking.[-]", server.chatColour, players[steam].name))
		banPlayer(steam, "1 year", "Automatic ban by server manager", "")

		-- if the player has any pending global bans, activate them
		connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = " .. steam)
	else
		if tonumber(players[steam].hackerScore) >= 49  then
			if tonumber(players[steam].pendingBans) > 0 then
				players[steam].hackerScore = 0
				message(string.format("say [%s]Temp banning %s 1 week for suspected hacking. Admins have been alerted.[-]", server.chatColour, players[steam].name))
				banPlayer(steam, "1 week", "Automatic ban for suspected hacking. Admins have been alerted.", "")

				-- activate the pending bans
				connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = " .. steam)
			end
		end

		if tonumber(players[steam].hackerScore) >= 100 then
			players[steam].hackerScore = 0
			message(string.format("say [%s]Temp banning %s 1 week for suspected hacking. Admins have been alerted.[-]", server.chatColour, players[steam].name))
			banPlayer(steam, "1 week", "Automatic ban for suspected hacking. Admins have been alerted.", "")

			-- if the player has any pending global bans, activate them
			connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = " .. steam)
		end
	end

	-- test for hackers teleporting
	if (os.time() - players[steam].lastCommandTimestamp > 60) and not server.ServerToolsDetected and not server.SDXDetected then
		if not (players[steam].timeout or players[steam].botTimeout) and not players[steam].ignorePlayer then
			if tonumber(intY) > -5000 and tonumber(intX) ~= 0 and tonumber(intZ) ~= 0 and tonumber(igplayers[steam].xPos) ~= 0 and tonumber(igplayers[steam].zPos) ~= 0 and tonumber(os.time() - igplayers[steam].lastLP) < 4 then
				dist = 0

				if igplayers[steam].deadX == nil then
					dist = distancexz(posX, posZ, igplayers[steam].xPos, igplayers[steam].zPos)
				end

				if (dist >= 700) and tonumber(igplayers[steam].deaths) == tonumber(deaths) then
					if tonumber(players[steam].tp) < 1 then
						if players[steam].newPlayer == true then
							new = " [FF8C40]NEW player "
						else
							new = " [FF8C40]Player "
						end

						if accessLevel(steam) > 2 then
							irc_chat(server.ircMain, botman.serverTime .. " Player " .. id .. " " .. steam .. " name: " .. name .. " detected teleporting to " .. intX .. " " .. intY .. " " .. intZ .. " distance " .. string.format("%-8.2d", dist))
							irc_chat(server.ircAlerts, botman.serverTime .. " Player " .. id .. " " .. steam .. " name: " .. name .. " detected teleporting to " .. intX .. " " .. intY .. " " .. intZ .. " distance " .. string.format("%-8.2d", dist))

							players[steam].hackerTPScore = tonumber(players[steam].hackerTPScore) + 1
							players[steam].watchPlayer = true
							players[steam].watchPlayerTimer = os.time() + 259200 -- watch for 3 days
							if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + 259200 .. " WHERE steam = " .. steam) end

							if tonumber(players[steam].exiled) == 1 or players[steam].newPlayer then
								players[steam].hackerTPScore = tonumber(players[steam].hackerTPScore) + 1
							end

							if players[steam].hackerTPScore > 0 and players[steam].newPlayer and tonumber(players[steam].ping) > 180 then
								if locations["exile"] and not players[steam].prisoner then
									players[steam].exiled = 1
								else
									players[steam].hackerTPScore = tonumber(players[steam].hackerTPScore) + 1
								end
							end

							if tonumber(players[steam].hackerTPScore) > 1 then
								players[steam].hackerTPScore = 0
								players[steam].tp = 0
								message(string.format("say [%s]Temp banning %s 1 week for unexplained teleporting. An admin will investigate the circumstances.[-]", server.chatColour, players[steam].name))
								banPlayer(steam, "1 week", "We detected unusual teleporting from you and are investigating the circumstances.", "")

								-- if the player has any pending global bans, activate them
								connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = " .. steam)
							end

							alertAdmins(id .. " name: " .. name .. " detected teleporting! In fly mode, type " .. server.commandPrefix .. "near " .. id .. " to shadow them.", "warn")
						end
					end

					players[steam].tp = 0
				end
			end
		end
	end

	igplayers[steam].lastLP = os.time()

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	players[steam].id = id
	players[steam].name = name
	players[steam].steamOwner = igplayers[steam].steamOwner
	igplayers[steam].id = id
	igplayers[steam].name = name
	igplayers[steam].steam = steam

	if igplayers[steam].deaths ~= nil then
		if tonumber(igplayers[steam].deaths) < tonumber(deaths) then
			if server.SDXDetected and tonumber(igplayers[steam].yPosLast) > 0 then
				players[steam].deathX = math.floor(igplayers[steam].xPosLast)
				players[steam].deathY = math.ceil(igplayers[steam].yPosLast)
				players[steam].deathZ = math.floor(igplayers[steam].zPosLast)

				igplayers[steam].deadX = math.floor(igplayers[steam].xPosLast)
				igplayers[steam].deadY = math.ceil(igplayers[steam].yPosLast)
				igplayers[steam].deadZ = math.floor(igplayers[steam].zPosLast)
				igplayers[steam].teleCooldown = 1000

				irc_chat(server.ircMain, "Player " .. steam .. " name: " .. name .. "'s death recorded at " .. igplayers[steam].deadX .. " " .. igplayers[steam].deadY .. " " .. igplayers[steam].deadZ)
				irc_chat(server.ircAlerts, "Player " .. steam .. " name: " .. name .. "'s death recorded at " .. igplayers[steam].deadX .. " " .. igplayers[steam].deadY .. " " .. igplayers[steam].deadZ)

				message("say [" .. server.chatColour .. "]" .. name .. " has died.[-]")

				r = rand(14)
				if (r == 1) then message("say [" .. server.chatColour .. "]" .. name .. " removed themselves from the gene pool.[-]") end
				if (r == 2) then message("say [" .. server.chatColour .. "]LOL!  Didn't run far away enough did you " .. name .. "?[-]") end
				if (r == 3) then message("say [" .. server.chatColour .. "]And the prize for most creative way to end themselves goes to.. " .. name .. "[-]") end
				if (r == 4) then message("say [" .. server.chatColour .. "]" .. name .. " really shouldn't handle explosives.[-]") end
				if (r == 5) then message("say Oh no! " .. name .. " died.  What a shame.[-]") end
				if (r == 6) then message("say [" .. server.chatColour .. "]Great effort there " .. name .. ". I'm awarding " .. score .. " points.[-]") end
				if (r == 7) then message("say [" .. server.chatColour .. "]LOL! REKT[-]") end

				if (r == 8) then
					message("say [" .. server.chatColour .. "]We are gathered here today to remember with sadness the passing of " .. name .. ". Rest in pieces. Amen.[-]")
				end

				if (r == 9) then message("say [" .. server.chatColour .. "]" .. name .. " cut the wrong wire.[-]") end
				if (r == 10) then message("say [" .. server.chatColour .. "]" .. name .. " really showed that explosive who's boss![-]") end
				if (r == 11) then message("say [" .. server.chatColour .. "]" .. name .. " shouldn't play Russian Roulette with a fully loaded gun.[-]") end
				if (r == 12) then message("say [" .. server.chatColour .. "]" .. name .. " added a new stain to the floor.[-]") end
				if (r == 13) then message("say [" .. server.chatColour .. "]ISIS got nothing on " .. name .. "'s suicide bomber skillz.[-]") end
				if (r == 14) then message("say [" .. server.chatColour .. "]" .. name .. " reached a new low with that death. Six feet under.[-]") end

				if tonumber(server.packCooldown) > 0 then
					players[steam].packCooldown = os.time() + server.packCooldown
				end
			end
		end
	end

	igplayers[steam].xPosLast = igplayers[steam].xPos
	igplayers[steam].yPosLast = igplayers[steam].yPos
	igplayers[steam].zPosLast = igplayers[steam].zPos

	igplayers[steam].xPos = posX
	igplayers[steam].yPos = posY
	igplayers[steam].zPos = posZ
	igplayers[steam].playerKills = kills

	igplayers[steam].deaths = deaths
	igplayers[steam].zombies = zombies
	igplayers[steam].score = score

	if tonumber(players[steam].level) > 2000 then
		players[steam].hackerScore = 10000
	end

	igplayers[steam].level = level
	players[steam].level = level
	igplayers[steam].killTimer = 0 -- to help us detect a player that has disconnected unnoticed
	igplayers[steam].raiding = false
	igplayers[steam].regionX = regionX
	igplayers[steam].regionZ = regionZ
	igplayers[steam].chunkX = chunkX
	igplayers[steam].chunkZ = chunkZ

	if pvpZone(posX, posZ) then
		igplayers[steam].currentLocationPVP = true
	else
		igplayers[steam].currentLocationPVP = false
	end

	if (igplayers[steam].xPosLast == nil) then
		igplayers[steam].xPosLast = posX
		igplayers[steam].yPosLast = posY
		igplayers[steam].zPosLast = posZ
		igplayers[steam].xPosLastOK = intX
		igplayers[steam].yPosLastOK = intY
		igplayers[steam].zPosLastOK = intZ
	end

	atHome(steam)

	currentLocation = inLocation(intX, intZ)

	if currentLocation ~= false then
		igplayers[steam].currentLocationPVP = locations[currentLocation].pvp
	end

	if currentLocation ~= false then
		resetZone = locations[currentLocation].resetZone

		if locations[currentLocation].killZombies then
			server.scanZombies = true
		end
	end

	if players[steam].showLocationMessages then
		if igplayers[steam].alertLocation ~= currentLocation and currentLocation ~= false then
			message(string.format("pm %s [%s]Welcome to %s[-]", steam, server.chatColour, currentLocation))
		end
	end

	if currentLocation == false then
		if players[steam].showLocationMessages then
			if igplayers[steam].alertLocation ~= "" then
				message(string.format("pm %s [%s]You have left %s[-]", steam, server.chatColour, igplayers[steam].alertLocation))
			end
		end

		igplayers[steam].alertLocation = ""
		players[steam].inLocation = ""
	else
		igplayers[steam].alertLocation = currentLocation
		players[steam].inLocation = currentLocation
	end

	if igplayers[steam].checkNewPlayer == true then
		igplayers[steam].checkNewPlayer = false

		if tonumber(level) > 9 and players[steam].newPlayer then
			players[steam].newPlayer = false
			players[steam].watchPlayer = false
			players[steam].watchPlayerTimer = 0
			if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, watchPlayer = 0, watchPlayerTimer = 0  WHERE steam = " .. steam) end
			irc_chat(server.ircMain, "Player " .. name .. "'s new player status has been removed because their level is " .. level)

			if string.upper(players[steam].chatColour) == "FFFFFF" then
				setChatColour(steam)
			end
		end
	end

	-- fix weird cash bug
	if tonumber(players[steam].cash) < 0 then
		players[steam].cash = 0
	end

	-- convert zombie kills to cash
	if (tonumber(igplayers[steam].zombies) > tonumber(players[steam].zombies)) and (math.abs(igplayers[steam].zombies - players[steam].zombies) < 20) then
		if server.allowBank then
			players[steam].cash = tonumber(players[steam].cash) + math.abs(igplayers[steam].zombies - players[steam].zombies) * server.zombieKillReward

			if (players[steam].watchCash == true) then
				message(string.format("pm %s [%s]+%s %s $%s in the bank[-]", steam, server.chatColour, math.abs(igplayers[steam].zombies - players[steam].zombies) * server.zombieKillReward, server.moneyPlural, players[steam].cash))
			end
		end

		if igplayers[steam].doge then
			r = rand(60)
			if r == 1 then message(string.format("pm %s [%s]MUCH KILL[-]", steam, server.chatColour)) end
			if r == 2 then message(string.format("pm %s [%s]GREAT PAIN[-]", steam, server.chatColour)) end
			if r == 3 then message(string.format("pm %s [%s]WOW[-]", steam, server.chatColour)) end
			if r == 4 then message(string.format("pm %s [%s]VERY DEATH[-]", steam, server.chatColour)) end
			if r == 5 then message(string.format("pm %s [%s]AMAZING[-]", steam, server.chatColour)) end
			if r == 6 then message(string.format("pm %s [%s]CALL 911[-]", steam, server.chatColour)) end
			if r == 7 then message(string.format("pm %s [%s]BIG HIT[-]", steam, server.chatColour)) end
			if r == 8 then message(string.format("pm %s [%s]EXTREME GORE[-]", steam, server.chatColour)) end
			if r == 9 then message(string.format("pm %s [%s]EXTREME POWER SHOT[-]", steam, server.chatColour)) end
			if r == 10 then message(string.format("pm %s [%s]EPIC BLOOD LOSS[-]", steam, server.chatColour)) end
			if r == 11 then message(string.format("pm %s [%s]OMG[-]", steam, server.chatColour)) end
			if r == 12 then message(string.format("pm %s [%s]OVERKILL[-]", steam, server.chatColour)) end
			if r == 13 then message(string.format("pm %s [%s]EXTREME OVERKILL[-]", steam, server.chatColour)) end
			if r == 14 then message(string.format("pm %s [%s]VERY OP[-]", steam, server.chatColour)) end
			if r == 15 then message(string.format("pm %s [%s]DISMEMBERMENT[-]", steam, server.chatColour)) end
			if r == 16 then message(string.format("pm %s [%s]HEADSHOT[-]", steam, server.chatColour)) end
			if r == 17 then message(string.format("pm %s [%s]PSYCHO[-]", steam, server.chatColour)) end
			if r == 18 then message(string.format("pm %s [%s]HAX[-]", steam, server.chatColour)) end
			if r == 19 then message(string.format("pm %s [%s]GAME OVER MAN!  GAME OVER![-]", steam, server.chatColour)) end
			if r == 20 then message(string.format("pm %s [%s]OWNED[-]", steam, server.chatColour)) end
			if r == 21 then message(string.format("pm %s [%s]DUDE[-]", steam, server.chatColour)) end
			if r == 22 then message(string.format("pm %s [%s]SICK[-]", steam, server.chatColour)) end
			if r == 23 then message(string.format("pm %s [%s]INCREDIBLE[-]", steam, server.chatColour)) end
			if r == 24 then message(string.format("pm %s [%s]BODY PARTS FLYING[-]", steam, server.chatColour)) end
			if r == 25 then message(string.format("pm %s [%s]WTF[-]", steam, server.chatColour)) end
			if r == 26 then message(string.format("pm %s [%s]EPIC[-]", steam, server.chatColour)) end
			if r == 27 then message(string.format("pm %s [%s]AIMBOT HAX[-]", steam, server.chatColour)) end
			if r == 28 then message(string.format("pm %s [%s]EXPLOSIVE[-]", steam, server.chatColour)) end
			if r == 29 then message(string.format("pm %s [%s]IMPOSSIBRU[-]", steam, server.chatColour)) end
			if r == 30 then message(string.format("pm %s [%s]MASSIVE HURT[-]", steam, server.chatColour)) end
			if r == 31 then message(string.format("pm %s [%s]C-C-C-COMBO BREAKER[-]", steam, server.chatColour)) end
			if r == 32 then message(string.format("pm %s [%s]ULTRA KILL[-]", steam, server.chatColour)) end
			if r == 33 then message(string.format("pm %s [%s]SUPPRESSED[-]", steam, server.chatColour)) end
			if r == 34 then message(string.format("pm %s [%s]IMPRESSIVE[-]", steam, server.chatColour)) end
			if r == 35 then message(string.format("pm %s [%s]ONE UP[-]", steam, server.chatColour)) end
			if r == 36 then message(string.format("pm %s [%s]MEGA KILL[-]", steam, server.chatColour)) end
			if r == 37 then message(string.format("pm %s [%s]SUPER KILL[-]", steam, server.chatColour)) end
			if r == 38 then message(string.format("pm %s [%s]SKILL SHOT[-]", steam, server.chatColour)) end
			if r == 39 then message(string.format("pm %s [%s]VERY AMAZING[-]", steam, server.chatColour)) end
			if r == 40 then message(string.format("pm %s [%s]EPIC OWNAGE[-]", steam, server.chatColour)) end
			if r == 41 then message(string.format("pm %s [%s]OMG WTF HAX[-]", steam, server.chatColour)) end
			if r == 42 then message(string.format("pm %s [%s]HOW?[-]", steam, server.chatColour)) end
			if r == 43 then message(string.format("pm %s [%s]UNPOSSIBLE![-]", steam, server.chatColour)) end
			if r == 44 then message(string.format("pm %s [%s]CRAZY KILL[-]", steam, server.chatColour)) end
			if r == 45 then message(string.format("pm %s [%s]LEGENDARY KILL[-]", steam, server.chatColour)) end
			if r == 46 then message(string.format("pm %s [%s]GUTSY[-]", steam, server.chatColour)) end
			if r == 47 then message(string.format("pm %s [%s]SMOOTH[-]", steam, server.chatColour)) end
			if r == 48 then message(string.format("pm %s [%s]PRO[-]", steam, server.chatColour)) end
			if r == 49 then message(string.format("pm %s [%s]NUKED[-]", steam, server.chatColour)) end
			if r == 50 then message(string.format("pm %s [%s]STOLEN KILL[-]", steam, server.chatColour)) end
			if r == 51 then message(string.format("pm %s [%s]LEEEEEEEEEEEEEROY JENKINS!!!!!![-]", steam, server.chatColour)) end
			if r == 52 then message(string.format("pm %s [%s]TRUMPED[-]", steam, server.chatColour)) end
			if r == 53 then message(string.format("pm %s [%s]CRAP[-]", steam, server.chatColour)) end
			if r == 54 then message(string.format("pm %s [%s]WTF BBQ[-]", steam, server.chatColour)) end
			if r == 55 then message(string.format("pm %s [%s]KILLJOY[-]", steam, server.chatColour)) end
			if r == 56 then message(string.format("pm %s [%s]TIS BUT A SCRATCH[-]", steam, server.chatColour)) end
			if r == 57 then message(string.format("pm %s [%s]LEGLESS[-]", steam, server.chatColour)) end
			if r == 58 then message(string.format("pm %s [%s]OOPS[-]", steam, server.chatColour)) end
			if r == 59 then message(string.format("pm %s [%s]DAMN[-]", steam, server.chatColour)) end
			if r == 60 then message(string.format("pm %s [%s]RIM SHOT[-]", steam, server.chatColour)) end
		end

		if server.allowBank then
			-- update the lottery prize pool
			server.lottery = server.lottery + (math.abs(igplayers[steam].zombies - players[steam].zombies) * server.lotteryMultiplier)
		end
	end

	-- update player record of zombies
	players[steam].zombies = igplayers[steam].zombies

	if tonumber(players[steam].playerKills) < tonumber(kills) then
		players[steam].playerKills = kills
	end

	if tonumber(players[steam].deaths) < tonumber(deaths) then
		players[steam].deaths = deaths
	end

	if tonumber(players[steam].score) < tonumber(score) then
		players[steam].score = score
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	players[steam].xPos = posX
	players[steam].yPos = posY
	players[steam].zPos = posZ

	mapCenterDistance = distancexz(intX,intZ,0,0)
	outsideMap = squareDistance(intX, intZ, server.mapSize)
	outsideMapDonor = squareDistance(intX, intZ, server.mapSize + 5000)

	if (players[steam].alertReset == nil) then
		players[steam].alertReset = true
	end

	if (igplayers[steam].greet == true) and tonumber(igplayers[steam].greetdelay) == 0 then
	if (steam == debugPlayerInfo) and debug then dbug("greet is true", true) end
		igplayers[steam].greet = false

		if server.welcome ~= nil then
			message(string.format("pm %s [%s]%s[-]", steam, server.chatColour, server.welcome))
		else
			message("pm " .. steam .. " [" .. server.chatColour .. "]Welcome to " .. server.serverName .. "!  Type " .. server.commandPrefix .. "info, " .. server.commandPrefix .. "rules or " .. server.commandPrefix .. "help for commands.[-]")
			--message(string.format("pm %s [%s]Welcome to %s! Type %sinfo, %srules, or %shelp for commands[-]", steam, server.chatColour, server.name, server.commandPrefix, server.commandPrefix, server.commandPrefix))
			message(string.format("pm %s [%s]We have a server manager bot called %s[-]", steam, server.chatColour, server.botName))
		end

		if (tonumber(igplayers[steam].zombies) ~= 0) then
			if (players[steam].donor == true) then
				welcome = "pm " .. steam .. " [" .. server.chatColour .. "]Welcome back " .. name .. "! Thanks for supporting us. =D[-]"
			else
				welcome = "pm " .. steam .. " [" .. server.chatColour .. "]Welcome back " .. name .. "![-]"
			end

			if (string.find(botman.serverTime, "02-14", 5, 10)) then welcome = "pm " .. steam .. " [" .. server.chatColour .. "]Happy Valentines Day " .. name .. "![-]" end

			message(welcome)
		else
			message("pm " .. steam .. " [" .. server.chatColour .. "]Welcome " .. name .. "![-]")
		end

		if (players[steam].timeout == true) then
			message("pm " .. steam .. " [" .. server.warnColour .. "]You are in timeout, not glitched or lagged.  You will stay here until released by an admin.[-]")
		end

		if (botman.scheduledRestart) then
			message("pm " .. steam .. " [" .. server.alertColour .. "]<!>[-][" .. server.warnColour .. "] SERVER WILL REBOOT SHORTLY [-][" .. server.alertColour .. "]<!>[-]")
		end

		if server.MOTD ~= "" then
			if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]" .. server.MOTD .. "[-]") .. "')") end
		end

		if tonumber(players[steam].removedClaims) > 0 then
			if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]I am holding " .. players[steam].removedClaims .. " land claim blocks for you. Type " .. server.commandPrefix .. "give claims to receive them.[-]") .. "')") end
		end

		if botman.dbConnected then
			cursor,errorString = conn:execute("SELECT * FROM mail WHERE recipient = " .. steam .. " and status = 0")
			rows = cursor:numrows()

			if rows > 0 then
				if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]You have unread mail.  Type " .. server.commandPrefix .. "read mail to read it now or " .. server.commandPrefix .. "help mail for more options.[-]") .. "')") end
			end
		end

		if players[steam].newPlayer == true and server.rules ~= "" then
			if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]" .. server.rules .."[-]") .. "')") end
		end

		if server.warnBotReset == true and accessLevel(steam) == 0 then
			if botman.dbConnected then
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]ALERT!  It appears that the server has been reset.[-]") .. "')")
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]To reset me type " .. server.commandPrefix .. "reset bot.[-]") .. "')")
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]To dismiss this alert type " .. server.commandPrefix .. "no reset.[-]") .. "')")
			end
		end

		if (not players[steam].santa) and specialDay == "christmas" then
			if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]HO HO HO! Merry Christmas!  Type " .. server.commandPrefix .. "santa to open your Christmas stocking![-]") .. "')") end
		end
	end


	if igplayers[steam].alertLocation == "" and currentLocation ~= false then
		if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]Welcome to " .. currentLocation .. "[-]") .. "')") end
		igplayers[steam].alertLocation = currentLocation
	end


	if tonumber(igplayers[steam].greetdelay) > 0 then
		igplayers[steam].greetdelay = tonumber(igplayers[steam].greetdelay) - 1
	end


	if (igplayers[steam].teleCooldown > 0) then
		igplayers[steam].teleCooldown = tonumber(igplayers[steam].teleCooldown) - 1
	end

	igplayers[steam].sessionPlaytime = os.time() - igplayers[steam].sessionStart

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if (players[steam].newPlayer == true and (igplayers[steam].sessionPlaytime + players[steam].timeOnServer > (server.newPlayerTimer * 60))) then
		players[steam].newPlayer = false
		players[steam].watchPlayer = false
		players[steam].watchPlayerTimer = 0
		message("pm " .. steam .. " [" .. server.chatColour .. "]Your new player status has been lifted. :D[-]")
		if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. steam) end

		if string.upper(players[steam].chatColour) == "FFFFFF" then
			setChatColour(steam)
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- if we are following a player and they move more than 50 meters away, teleport us close to them.
	if igplayers[steam].following ~= nil then
		if igplayers[igplayers[steam].following] and players[igplayers[steam].following].timeout == false and players[igplayers[steam].following].botTimeout == false then
			followDistance = 50
			if igplayers[steam].followDistance ~= nil then followDistance = tonumber(igplayers[steam].followDistance) end

			dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, igplayers[igplayers[steam].following].xPos, igplayers[igplayers[steam].following].zPos)
			if dist > followDistance and igplayers[igplayers[steam].following].yPos > 0 then
				-- teleport close to the player
				players[steam].tp = 1
				players[steam].hackerTPScore = 0
				send("tele " .. steam .. " " .. math.floor(igplayers[igplayers[steam].following].xPos) .. " " .. math.ceil(igplayers[igplayers[steam].following].yPos - 30) .. " " .. math.floor(igplayers[igplayers[steam].following].zPos))
			end
		end
	end


	if (igplayers[steam].alertLocationExit ~= nil) then
		dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, locations[igplayers[steam].alertLocationExit].x, locations[igplayers[steam].alertLocationExit].z)
		size = tonumber(locations[igplayers[steam].alertLocationExit].size)

		if (dist > tonumber(locations[igplayers[steam].alertLocationExit].size) + 100) then
			igplayers[steam].alertLocationExit = nil

			message("pm " .. steam .. " [" .. server.chatColour .. "]Your have moved too far away from the location. If you still wish to do " .. server.commandPrefix .. "protect location, please start again.[-]")
			faultyPlayerinfo = false
			return
		end

		if (dist > tonumber(locations[igplayers[steam].alertLocationExit].size) + 10) and (dist <  tonumber(locations[igplayers[steam].alertLocationExit].size) + 30) then
			locations[igplayers[steam].alertLocationExit].exitX = intX
			locations[igplayers[steam].alertLocationExit].exitY = intY
			locations[igplayers[steam].alertLocationExit].exitZ = intZ
			locations[igplayers[steam].alertLocationExit].protected = true

			if botman.dbConnected then conn:execute("UPDATE locations SET exitX = " .. intX .. ", exitY = " .. intY .. ", exitZ = " .. intZ .. ", protected = 1 WHERE name = '" .. igplayers[steam].alertLocationExit .. "'") end
			message("pm " .. steam .. " [" .. server.chatColour .. "]You have enabled protection for " .. igplayers[steam].alertLocationExit .. ".[-]")

			igplayers[steam].alertLocationExit = nil

			faultyPlayerinfo = false
			return
		end
	end


	if (igplayers[steam].alertVillageExit ~= nil) then
		dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, locations[igplayers[steam].alertVillageExit].x, locations[igplayers[steam].alertVillageExit].z)
		size = tonumber(locations[igplayers[steam].alertVillageExit].size)

		if (dist > tonumber(locations[igplayers[steam].alertVillageExit].size) + 100) then
			igplayers[steam].alertVillageExit = nil

			message("pm " .. steam .. " [" .. server.chatColour .. "]Your have moved too far away from " .. igplayers[steam].alertVillageExit .. ". Return to " .. igplayers[steam].alertVillageExit .. " and type " .. server.commandPrefix .. "protect village " .. igplayers[steam].alertVillageExit .. " again.[-]")
			faultyPlayerinfo = false
			return
		end

		if (dist >  tonumber(locations[igplayers[steam].alertVillageExit].size) + 20) and (dist <  tonumber(locations[igplayers[steam].alertVillageExit].size) + 100) then
			locations[igplayers[steam].alertVillageExit].exitX = intX
			locations[igplayers[steam].alertVillageExit].exitY = intY
			locations[igplayers[steam].alertVillageExit].exitZ = intZ
			locations[igplayers[steam].alertVillageExit].protect = true

			message("pm " .. steam .. " [" .. server.chatColour .. "]You have enabled protection for " .. igplayers[steam].alertVillageExit .. "[-]")

			igplayers[steam].alertVillageExit = nil

			faultyPlayerinfo = false
			return
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if (igplayers[steam].alertBaseExit == true) then
		if igplayers[steam].alertBase == 1 then
			dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, players[igplayers[steam].alertBaseID].homeX, players[igplayers[steam].alertBaseID].homeZ)
			size = tonumber(players[igplayers[steam].alertBaseID].protectSize)
		else
			dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, players[igplayers[steam].alertBaseID].home2X, players[igplayers[steam].alertBaseID].home2Z)
			size = tonumber(players[igplayers[steam].alertBaseID].protect2Size)
		end

		if (dist > 200) then
			igplayers[steam].alertBaseExit = nil
			igplayers[steam].alertBaseID = nil
			igplayers[steam].alertBase = nil

			message("pm " .. steam .. " [" .. server.chatColour .. "]Your have moved too far away from the base. If you still wish to do " .. server.commandPrefix .. "protect, please start again.[-]")
			faultyPlayerinfo = false
			return
		end

		if igplayers[steam].alertBase == 1 then
			if (dist >  tonumber(players[igplayers[steam].alertBaseID].protectSize) + 15) and (dist <  tonumber(players[igplayers[steam].alertBaseID].protectSize) + 50) then
				players[igplayers[steam].alertBaseID].exitX = intX
				players[igplayers[steam].alertBaseID].exitY = intY
				players[igplayers[steam].alertBaseID].exitZ = intZ

				if (accessLevel(steam) < 3) then
					message("pm " .. steam .. " [" .. server.chatColour .. "]You have set an exit teleport for " .. players[igplayers[steam].alertBaseID].name .. "'s base.[-]")
				else
					message("pm " .. steam .. " [" .. server.chatColour .. "]You have set an exit teleport for your base.  You can test it with " .. server.commandPrefix .. "test base.[-]")
				end

				-- check for nearby bases
				failProtect = false
				for k, v in pairs(players) do
					if (v.homeX ~= 0) and k ~= igplayers[steam].alertBaseID then
							if (v.homeX ~= 0 and v.homeZ ~= 0) then
							dist = distancexz(players[igplayers[steam].alertBaseID].homeX, players[igplayers[steam].alertBaseID].homeZ, v.homeX, v.homeZ)

							if (tonumber(dist) < tonumber(players[igplayers[steam].alertBaseID].protectSize)) then
								if friends[k] == nil or not string.find(friends[k].friends, igplayers[steam].alertBaseID) then
									failProtect = true
								end
							end
						end
					end

					if (v.home2X ~= 0) and k ~= igplayers[steam].alertBaseID then
						if (v.home2X ~= 0 and v.home2Z ~= 0) then
							dist = distancexz(players[igplayers[steam].alertBaseID].homeX, players[igplayers[steam].alertBaseID].homeZ, v.home2X, v.home2Z)

							if (dist < players[igplayers[steam].alertBaseID].protectSize + 10) then
								if not string.find(friends[k].friends, igplayers[steam].alertBaseID) then
									failProtect = true
								end
							end
						end
					end
				end

				if failProtect == false then
					players[igplayers[steam].alertBaseID].protect = true
					message("pm " .. igplayers[steam].alertBaseID .. " [" .. server.chatColour .. "]Base protection for your base is active.[-]")
				else
					message("pm " .. igplayers[steam].alertBaseID .. " [" .. server.warnColour .. "]Your base is too close to another player base who is not on your friends list.  Protection cannot be enabled.[-]")
				end

				igplayers[steam].alertBaseExit = nil
				igplayers[steam].alertBaseID = nil
				igplayers[steam].alertBase = nil

				faultyPlayerinfo = false
				return
			end
		else
			if (dist >  tonumber(players[igplayers[steam].alertBaseID].protect2Size) + 15) and (dist <  tonumber(players[igplayers[steam].alertBaseID].protect2Size) + 50) then
				players[igplayers[steam].alertBaseID].exit2X = intX
				players[igplayers[steam].alertBaseID].exit2Y = intY
				players[igplayers[steam].alertBaseID].exit2Z = intZ

				if (accessLevel(steam) < 3) then
					message("pm " .. steam .. " [" .. server.chatColour .. "]You have set an exit teleport for " .. players[igplayers[steam].alertBaseID].name .. "'s 2nd base.[-]")
				else
					message("pm " .. steam .. " [" .. server.chatColour .. "]You have set an exit teleport for your 2nd base.  You can test it with " .. server.commandPrefix .. "test base.[-]")
				end

				-- check for nearby bases
				failProtect = false
				for k, v in pairs(players) do
					if (v.homeX ~= 0) and k ~= igplayers[steam].alertBaseID then
							if (v.homeX ~= 0 and v.homeZ ~= 0) then
							dist = distancexz(players[igplayers[steam].alertBaseID].home2X, players[igplayers[steam].alertBaseID].home2Z, v.homeX, v.homeZ)

							if (tonumber(dist) < tonumber(players[igplayers[steam].alertBaseID].protect2Size)) then
								if friends[k] == nil or not string.find(friends[k].friends, igplayers[steam].alertBaseID) then
									failProtect = true
								end
							end
						end
					end

					if (v.home2X ~= 0) and k ~= igplayers[steam].alertBaseID then
						if (v.home2X ~= 0 and v.home2Z ~= 0) then
							dist = distancexz(players[igplayers[steam].alertBaseID].home2X, players[igplayers[steam].alertBaseID].home2Z, v.home2X, v.home2Z)

							if (dist < players[igplayers[steam].alertBaseID].protect2Size + 10) then
								if not string.find(friends[k].friends, igplayers[steam].alertBaseID) then
									failProtect = true
								end
							end
						end
					end
				end

				if failProtect == false then
					players[igplayers[steam].alertBaseID].protect2 = true
					message("pm " .. igplayers[steam].alertBaseID .. " [" .. server.chatColour .. "]Base protection for your second base is active.[-]")
				else
					message("pm " .. igplayers[steam].alertBaseID .. " [" .. server.warnColour .. "]Your second base is too close to another player base who is not on your friends list.  Protection cannot be enabled.[-]")
				end

				igplayers[steam].alertBaseExit = nil
				igplayers[steam].alertBaseID = nil
				igplayers[steam].alertBase = nil

				faultyPlayerinfo = false
				return
			end
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	x = math.floor(igplayers[steam].xPos / 512)
	z = math.floor(igplayers[steam].zPos / 512)

	if (accessLevel(steam) < 4) and server.enableRegionPM then
		if (igplayers[steam].region ~= "r." .. x .. "." .. z .. ".7") then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Region r." .. x .. "." .. z .. ".7[-]")
		end
	end

	igplayers[steam].region = "r." .. x .. "." .. z .. ".7"
	igplayers[steam].regionX = x
	igplayers[steam].regionZ = z

	-- timeout
	if (players[steam].timeout == true or players[steam].botTimeout == true) then
		if (intY < 20000) then
			players[steam].tp = 1
			players[steam].hackerTPScore = 0
			send("tele " .. steam .. " " .. intX .. " " .. 50000 .. " " .. intZ)
		end

		faultyPlayerinfo = false
		return
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- world fall catcher
	fallCatcher(steam, intX, intY, intZ)

	-- prevent player exceeding the map limit unless they are an admin except when ignoreadmins is false
	if not isDestinationAllowed(steam, intX, intZ) then
		if players[steam].donor then
			message("pm " .. steam .. " [" .. server.warnColour .. "]This map is restricted to " .. (server.mapSize / 1000) .. " km from the center.[-]")
		else
			message("pm " .. steam .. " [" .. server.warnColour .. "]This map is restricted to " .. (server.mapSize / 1000) .. " km from the center.[-]")
		end

		players[steam].tp = 1
		players[steam].hackerTPScore = 0

		if not isDestinationAllowed(steam, igplayers[steam].xPosLastOK, igplayers[steam].zPosLastOK) then
			send ("tele " .. steam .. " 0 -1 0") -- if we don't know where to send the player, send them to the middle of the map. This should only happen rarely.
			message("pm " .. steam .. " [" .. server.warnColour .. "]You have been moved to the center of the map.[-]")
		else
			send ("tele " .. steam .. " " .. igplayers[steam].xPosLastOK .. " " .. igplayers[steam].yPosLastOK .. " " .. igplayers[steam].zPosLastOK)
		end

		faultyPlayerinfo = false
		return
	end

	if tonumber(players[steam].exiled) == 1 and locations["exile"] and not players[steam].prisoner then
		if (distancexz( intX, intZ, locations["exile"].x, locations["exile"].z ) > tonumber(locations["exile"].size)) then
			randomTP(steam, "exile", true)
			faultyPlayerinfo = false
			return
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- left prison zone warning
	if (locations["prison"]) then
		if (distancexz( intX, intZ, locations["prison"].x, locations["prison"].z ) > tonumber(locations["prison"].size)) then
			if (players[steam].alertPrison == false) then
				if (not players[steam].prisoner) and 	players[steam].showLocationMessages then
					message("pm " .. steam .. " [" .. server.chatColour .. "]You have left the prison.[-]")
				end

				players[steam].alertPrison = true
			end
		end

		if (players[steam].prisoner) then
			if (locations["prison"]) then
				if (squareDistanceXZXZ(locations["prison"].x, locations["prison"].z, intX, intZ, locations["prison"].size)) then
					players[steam].alertPrison = false
					randomTP(steam, "prison", true)
				end
			end

			faultyPlayerinfo = false
			return
		end

		-- entered prison zone warning
		if (distancexz( intX, intZ, locations["prison"].x, locations["prison"].z ) < tonumber(locations["prison"].size)) then
			if (players[steam].alertPrison == true) then
				if (not players[steam].prisoner) and players[steam].showLocationMessages then
					message("pm " .. steam .. " [" .. server.warnColour .. "]You have entered the prison.  Continue at your own risk.[-]")
				end
				players[steam].alertPrison = false
			end
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- freeze!
	if (players[steam].freeze == true) then
		dist = distancexz(posX, posZ, players[steam].prisonxPosOld, players[steam].prisonzPosOld)

		if dist > 2 then
			players[steam].tp = 1
			players[steam].hackerTPScore = 0
			send("tele " .. steam .. " " .. players[steam].prisonxPosOld .. " " .. players[steam].prisonyPosOld .. " " .. players[steam].prisonzPosOld)
		end

		faultyPlayerinfo = false
		return
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- remove player from location if the location is closed or their level is outside level restrictions
	if currentLocation ~= false then
		tmp = {}
		tmp.bootPlayer = false

		if not locations[currentLocation].open and accessLevel(steam) > 2 then
			tmp.bootPlayer = true
		end

		-- check player level restrictions on the location
		if (tonumber(locations[currentLocation].minimumLevel) > 0 or tonumber(locations[currentLocation].maximumLevel) > 0) and accessLevel(steam) > 2 then
			if tonumber(locations[currentLocation].minimumLevel) > 0 and level < tonumber(locations[currentLocation].minimumLevel) then
				tmp.bootPlayer = true
			end

			if tonumber(locations[currentLocation].minimumLevel) > 0 and tonumber(locations[currentLocation].maximumLevel) > 0 and (level < tonumber(locations[currentLocation].minimumLevel) or level > tonumber(locations[currentLocation].maximumLevel)) then
				tmp.bootPlayer = true
			end

			if tonumber(locations[currentLocation].maximumLevel) > 0 and level > tonumber(locations[currentLocation].maximumLevel) then
				tmp.bootPlayer = true
			end
		end

		if tmp.bootPlayer then
			tmp = {}
			tmp.side = rand(4)
			tmp.offset = rand(50)

			if tmp.side == 1 then
				tmp.x = locations[currentLocation].x - (locations[currentLocation].size + 20 + tmp.offset)
				tmp.z = locations[currentLocation].z
			end

			if tmp.side == 2 then
				tmp.x = locations[currentLocation].x + (locations[currentLocation].size + 20 + tmp.offset)
				tmp.z = locations[currentLocation].z
			end

			if tmp.side == 3 then
				tmp.x = locations[currentLocation].x
				tmp.z = locations[currentLocation].z - (locations[currentLocation].size + 20 + tmp.offset)
			end

			if tmp.side == 4 then
				tmp.x = locations[currentLocation].x
				tmp.z = locations[currentLocation].z + (locations[currentLocation].size + 20 + tmp.offset)
			end

			tmp.cmd = "tele " .. steam .. " " .. tmp.x .. " -1 " .. tmp.z
			teleport(tmp.cmd, steam)
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- teleport lookup
	if (igplayers[steam].teleCooldown < 1) and (players[steam].prisoner == false) then
		tp = ""
		tp, match = LookupTeleport(posX, posY, posZ)
		if (tp ~= nil and teleports[tp].active == true) then
			ownerid = LookupOfflinePlayer(teleports[tp].owner)
			if (players[steam].walkies ~= true) then
				if (accessLevel(steam) < 3) or (teleports[tp].owner == igplayers[steam].steam or teleports[tp].public == true or isFriend(ownerid, steam)) then
					if match == 1 then
						if isDestinationAllowed(steam, teleports[tp].dx, teleports[tp].dz) then
							igplayers[steam].teleCooldown = 2
							cmd = "tele " .. steam .. " " .. math.floor(teleports[tp].dx) .. " " .. math.ceil(teleports[tp].dy) .. " " .. math.floor(teleports[tp].dz)
							teleport(cmd, steam)
						end

						faultyPlayerinfo = false
						return
					end

					if match == 2 and teleports[tp].oneway == false then
						if isDestinationAllowed(steam, teleports[tp].x, teleports[tp].z) then
							igplayers[steam].teleCooldown = 2
							cmd = "tele " .. steam .. " " .. math.floor(teleports[tp].x) .. " " .. math.ceil(teleports[tp].y) .. " " .. math.floor(teleports[tp].z)
							teleport(cmd, steam)
						end

						faultyPlayerinfo = false
						return
					end
				end
			end
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- linked waypoint lookup
	if (igplayers[steam].teleCooldown < 1) and (players[steam].prisoner == false) then
		tmp = {}
		tmp.wpid = LookupWaypoint(posX, posY, posZ)

		if tonumber(tmp.wpid) > 0 then
			tmp.linkedID = waypoints[tmp.wpid].linked

			if (waypoints[tmp.wpid].shared and isFriend(waypoints[tmp.wpid].steam, steam) or waypoints[tmp.wpid].steam == steam) and tonumber(tmp.linkedID) > 0 then
				-- reject if not an admin and player teleporting has been disabled
				if server.allowTeleporting then
					if isDestinationAllowed(steam, waypoints[tmp.linkedID].x, waypoints[tmp.linkedID].z) then
						igplayers[steam].teleCooldown = 2
						cmd = "tele " .. steam .. " " .. math.floor(waypoints[tmp.linkedID].x) .. " " .. math.ceil(waypoints[tmp.linkedID].y) .. " " .. math.floor(waypoints[tmp.linkedID].z)
						teleport(cmd, steam)
					end

					faultyPlayerinfo = false
					return
				else
					if accessLevel(steam) < 3 then
						igplayers[steam].teleCooldown = 2
						cmd = "tele " .. steam .. " " .. math.floor(waypoints[tmp.linkedID].x) .. " " .. math.ceil(waypoints[tmp.linkedID].y) .. " " .. math.floor(waypoints[tmp.linkedID].z)
						teleport(cmd, steam)

						faultyPlayerinfo = false
						return
					end
				end
			end
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- left reset zone warning
	if (not resetZone) then
		if (players[steam].alertReset == false) and players[steam].showLocationMessages then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You are out of the reset zone.[-]")
			players[steam].alertReset = true
			faultyPlayerinfo = false
		end
	end


	-- entered reset zone warning
	if (resetZone) then
		if (players[steam].alertReset == true) and players[steam].showLocationMessages then
			message("pm " .. steam .. " [" .. server.warnColour .. "]You are in a reset zone. Don't build here.[-]")
			players[steam].alertReset = false
			faultyPlayerinfo = false

			-- check for claims in the reset zone not owned by staff and remove them
			checkRegionClaims(x, z)
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if	baseProtection(steam, posX, posY, posZ) and not resetZone then
		faultyPlayerinfo = false
		return
	end

	-- add to tracker table
	dist = distancexyz(intX, intY, intZ, igplayers[steam].xPosLast, igplayers[steam].yPosLast, igplayers[steam].zPosLast)

	if (dist > 2) and tonumber(intY) < 10000 then
		-- record the players position
		if igplayers[steam].raiding then
			flag = flag .. "R"
		end

		if igplayers[steam].illegalInventory then
			flag = flag .. "B"
		end

		if igplayers[steam].flying or igplayers[steam].noclip then
			flag = flag .. "F"
		end

		if botman.dbConnected then conn:execute("INSERT INTO tracker (steam, x, y, z, session, flag) VALUES (" .. steam .. "," .. intX .. "," .. intY .. "," .. intZ .. "," .. players[steam].sessionCount .. ",'" .. flag .. "')") end

		if igplayers[steam].location ~= nil then
			if botman.dbConnected then conn:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. igplayers[steam].location .. "'," .. intX .. "," .. intY .. "," .. intZ .. ")") end
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if (igplayers[steam].deadX ~= nil) then
		dist = math.abs(distancexz(igplayers[steam].deadX, igplayers[steam].deadZ, posX, posZ))
		if (dist > 2) then
			igplayers[steam].deadX = nil
			igplayers[steam].deadY = nil
			igplayers[steam].deadZ = nil

			if players[steam].bed ~= "" then
				if players[steam].bed == "base1" then
					cmd = "tele " .. steam .. " " .. players[steam].homeX .. " " .. players[steam].homeY .. " " .. players[steam].homeZ
					teleport(cmd, steam)
				end

				if players[steam].bed == "base2" then
					cmd = "tele " .. steam .. " " .. players[steam].home2X .. " " .. players[steam].home2Y .. " " .. players[steam].home2Z
					teleport(cmd, steam)
				end
			end
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- hotspot lookup
	hotspot = LookupHotspot(posX, posY, posZ)

	if (hotspot ~= nil) then
		tmp.skipHotspot = false

		if (igplayers[steam].lastHotspot ~= hotspot) then
			for k, v in pairs(lastHotspots[steam]) do
				if v == hotspot then -- don't add or display this hotspot yet.  we've seen it recently
					tmp.skipHotspot = true
				end
			end

			if not tmp.skipHotspot then
				igplayers[steam].lastHotspot = hotspot
				message("pm " .. steam .. " [" .. server.chatColour .. "]" .. hotspots[hotspot].hotspot .. "[-]")

				if (lastHotspots[steam] == nil) then lastHotspots[steam] = {} end
				if (table.maxn(lastHotspots[steam]) > 4) then
					table.remove(lastHotspots[steam], 1)
				end

				table.insert(lastHotspots[steam],  hotspot)
			end
		end
	end


	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if igplayers[steam].rawPosition ~= rawPosition then
		igplayers[steam].afk = os.time() + 900
		igplayers[steam].rawPosition = rawPosition
	end


	if igplayers[steam].rawRotation ~= rawRotation and rawRotation ~= nil then
		igplayers[steam].rawRotation = rawRotation

		if tonumber(igplayers[steam].teleCooldown) > 100 then
			igplayers[steam].teleCooldown = 0
		end
	end


	if tonumber(botman.playersOnline) >= tonumber(server.maxPlayers) and (accessLevel(steam) > 3) and server.idleKick then
		if (igplayers[steam].afk - os.time() < 0) then
			kick(steam, "Server is full.  You were kicked because you idled too long, but you can rejoin at any time. Thanks for playing! xD")
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if igplayers[steam].currentLocationPVP then
		if players[steam].alertPVP == true then
			message("pm " .. steam .. " [" .. server.alertColour .. "]You have entered a PVP zone!  Players are allowed to kill you![-]")
			players[steam].alertPVP = false
			faultyPlayerinfo = false
		end
	else
		if players[steam].alertPVP == false then
			message("pm " .. steam .. " [" .. server.warnColour .. "]You have entered a PVE zone.  Do not kill other players![-]")
			players[steam].alertPVP = true
			faultyPlayerinfo = false
		end
	end

	if (steam == debugPlayerInfo) and debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- stuff to do after everything else

	-- record this coord as the last one that the player was allowed to be at.  if their next step is not allowed, they get returned to this one.
	igplayers[steam].xPosLastOK = intX
	igplayers[steam].yPosLastOK = intY
	igplayers[steam].zPosLastOK = intZ

	faultyPlayerinfo = false

	if (steam == debugPlayerInfo) then
		dbug("end playerinfo", true)
	end
end


function playerInfoTrigger(line)
	if players[faultyPlayerinfoID] == nil then
		faultyPlayerinfoID = 0
	end

	if botman.botDisabled then
		return
	end

	if (faultyPlayerinfoID == debugPlayerInfo) or not igplayers[faultyPlayerinfoID] then
		debugPlayerInfo = 0
	end

	if string.find(line, ", health=") then
		if faultyPlayerinfo == true and tonumber(faultyPlayerinfoID) > -1 then
			dbug("debug playerinfo faulty player " .. faultyPlayerinfoID, true)

			windowMessage(server.windowDebug, "!! Fault detected in playerinfo trigger\n")
			windowMessage(server.windowDebug, faultyPlayerinfoLine .. "\n")

			if tonumber(faultyPlayerinfoID) > 0 and players[faultyPlayerinfoID] then
				fixMissingPlayer(faultyPlayerinfoID)

				if igplayers[faultyPlayerinfoID] then
					fixMissingIGPlayer(faultyPlayerinfoID)
				end
			end
		end

		playerInfo(faultyPlayerinfoID)
	end
end
