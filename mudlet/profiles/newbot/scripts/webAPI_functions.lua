--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
local debug = false -- should be false unless testing


function getAPILog()
-- NOTE:  This can't work in practice because there is currently no way to know the current line number of the log.
-- Alloc must add a last log line number query to his API.

		 -- url = "http://" .. server.IP .. ":" .. server.webPanelPort + 2 .. "/api/getlog/?firstline=50&adminuser=" .. server.allocsWebAPIUser .. "&admintoken=" .. server.allocsWebAPIPassword
		 -- os.remove(homedir .. "/temp/log.txt")
		 -- downloadFile(homedir .. "/temp/log.txt", url)

end


function checkAPIWorking()
	local fileSize, ln, foundAPI

	fileSize = lfs.attributes (homedir .. "/temp/dummy.txt", "size")
	foundAPI = false

	-- if the API is working a file called dummy.txt will not be empty.
	if fileSize == nil or fileSize == 0 then
		-- oh no!  it's empty! maybe its 2 above or below?  Let's find out :D
		if not botman.testAPIPort then
			-- re-test 2 above the port we were given
			botman.testAPIPort = botman.oldAPIPort + 2
		else
			if botman.testAPIPort == botman.oldAPIPort + 2 then
				-- welp that didn't work.  Lets test 2 below the port we were given
				botman.testAPIPort = botman.oldAPIPort - 2
			else
				-- well shit.  We can't find the API.  Stop testing and give up.
				botman.testAPIPort = nil
			end
		end
	else
		file = io.open(homedir .. "/temp/dummy.txt", "r")

		for ln in file:lines() do
			if string.find(ln, "{\"command\"") then
				foundAPI = true

				if botman.testAPIPort then
					-- yay! we found the API.  Update the webPanelPort. Those silly humans!
					conn:execute("UPDATE server SET webPanelPort = " .. botman.testAPIPort)
					botman.testAPIPort = nil
				end
			else
				-- oh no!  it's empty! maybe its 2 above or below?  Let's find out :D
				if not botman.testAPIPort then
					-- re-test 2 above the port we were given
					botman.testAPIPort = botman.oldAPIPort + 2
				else
					if botman.testAPIPort == botman.oldAPIPort + 2 then
						-- welp that didn't work.  Lets test 2 below the port we were given
						botman.testAPIPort = botman.oldAPIPort - 2
					else
						-- well shit.  We can't find the API.  Stop testing and give up.
						botman.testAPIPort = nil
					end
				end
			end
		end

		file:close()
	end

	if botman.testAPIPort then
		server.webPanelPort = botman.testAPIPort

		-- verify that the web API is working for us
		tempTimer( 2, [[message("pm APITEST testing")]] )
		tempTimer( 5, [[checkAPIWorking()]] )
		return
	else
		if foundAPI then
			-- report our success
			alertAdmins("The bot is now using Alloc's web API to communicate with the server.")
			irc_chat(chatvars.ircAlias, "The bot is now using Alloc's web API to communicate with the server.")
		else
			server.useAllocsWebAPI = false
			server.webPanelPort = botman.oldAPIPort
			conn:execute("UPDATE server set useAllocsWebAPI = 0")

			alertAdmins("API FAILED! The bot is using telnet. Check your server's web panel port and set it with {#}set web panel port {port number}.  It should be set to 2 below your web map's port and is called ControlPanelPort in your server config.", "alert")
			irc_chat(chatvars.ircAlias, "API FAILED! The bot is using telnet.  Check your server's web panel port and set it with {#}set web panel port {port number}, then re-try {#}use api.  It should be set to 2 below your web map's port and is called ControlPanelPort in your server config.")
		end
	end
end


function API_PlayerInfo(data)
	-- EDIT THIS FUNCTION WITH CARE.  This function is central to player management.  Some lines need to be run before others.
	-- Lua will stop execution wherever it strikes a fault (usually trying to use a non-existing variable)
	-- enable debugging to see roughly where the bot gets to.  It should reach 'end API_Playerinfo'.
	-- Good luck :)

	if customAPIPlayerInfo ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customAPIPlayerInfo(data) then
			return
		end
	end

	data.level = math.floor(data.level)

	local tmp = {}

	local debug, posX, posY, posZ, lastX, lastY, lastZ, lastDist, mapCenterDistance, regionX, regionZ, chunkX, chunkZ
	local steamtest, admin, lastGimme, lastLogin, playerAccessLevel
	local xPosOld, yPosOld, zPosOld, position, outsideMap, outsideMapDonor, fields, values, flag
	local timestamp = os.time()
	local region = ""
	local resetZone = false
	local dist, hotspot, currentLocation

	debug = false -- should be false unless testing

	-- Set debugPlayerInfo to the steam id or player name that you want to monitor.  If the player is not on the server, the bot will reset debugPlayerInfo to zero.
	debugPlayerInfo = 0 -- should be 0 unless testing against a steam id

	flag = ""

	ping = data.ping
	posX = data.position.x
	posY = data.position.y
	posZ = data.position.z
	intX = posX
	intY = posY
	intZ = posZ

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	position = posX .. posY .. posZ

	region = getRegion(intX, intZ)
	regionX, regionZ, chunkX, chunkZ = getRegionChunkXZ(intX, intZ)

	if (resetRegions[region]) then
		resetZone = true
	else
		resetZone = false
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- check for invalid or missing steamid.  kick if not passed
	steamtest = tonumber(data.steamid)
	if (steamtest == nil) then
		sendCommand("kick " .. data.entityid)
		irc_chat(server.ircMain, "Player " .. data.name .. " kicked for invalid Steam ID: " .. data.steamid)
		faultyPlayerinfo = false
		return
	end

	if (string.len(data.steamid) < 17) then
		sendCommand("kick " .. data.entityid)
		irc_chat(server.ircMain, "Player " .. data.name .. " kicked for invalid Steam ID: " .. data.steamid)
		faultyPlayerinfo = false
		return
	end

	-- add to in-game players table
	if (igplayers[data.steamid] == nil) then
		igplayers[data.steamid] = {}
		igplayers[data.steamid].id = data.entityid
		igplayers[data.steamid].name = data.name
		igplayers[data.steamid].steam = data.steamid
		igplayers[data.steamid].steamOwner = data.steamid

		fixMissingIGPlayer(data.steamid)

		-- don't initially warn the player about pvp or pve zone.  Too many players complain about it when the bot is restarted.  We can warn them next time their zone changes.
		if pvpZone(posX, posZ) then
			if players[data.steamid].alertPVP == true then
				players[data.steamid].alertPVP = false
			end
		else
			if players[data.steamid].alertPVP == false then
				players[data.steamid].alertPVP = true
			end
		end
	end

	if igplayers[data.steamid].readCounter == nil then
		igplayers[data.steamid].readCounter = 0
	else
		igplayers[data.steamid].readCounter = igplayers[data.steamid].readCounter + 1
	end

	if igplayers[data.steamid].checkNewPlayer == nil then
		fixMissingIGPlayer(data.steamid)
	end

	-- add to players table
	if (players[data.steamid] == nil) then
		players[data.steamid] = {}
		players[data.steamid].id = data.entityid
		players[data.steamid].name = data.name
		players[data.steamid].steam = data.steamid

		if tonumber(data.score) == 0 and tonumber(data.zombiekills) == 0 and tonumber(data.playerdeaths) == 0 then
			players[data.steamid].newPlayer = true
		else
			players[data.steamid].newPlayer = false
		end

		players[data.steamid].watchPlayer = true
		players[data.steamid].watchPlayerTimer = os.time() + 2419200 -- stop watching in one month or until no longer a new player
		players[data.steamid].ip = data.ip
		players[data.steamid].exiled = 0

		irc_chat(server.ircMain, "###  New player joined " .. data.name .. " steam: " .. data.steamid.. " id: " .. data.entityid .. " ###")
		irc_chat(server.ircAlerts, "New player joined " .. server.gameDate)

		if botman.dbConnected then
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. posX .. "," .. posY .. "," .. posZ .. ",'" .. botman.serverTime .. "','new player','New player joined " .. data.name .. " steam: " .. data.steamid.. " id: " .. data.entityid .. "'," .. data.steamid .. ")")
			conn:execute("INSERT INTO players (steam, name, id, IP, newPlayer, watchPlayer, watchPlayerTimer) VALUES (" .. data.steamid .. ",'" .. escape(data.name) .. "'," .. data.entityid .. "," .. data.ip .. ",1,1, " .. os.time() + 2419200 .. ")")
		end

		fixMissingPlayer(data.steamid)
		CheckBlacklist(data.steamid, data.ip)
	end

	if igplayers[data.steamid].greet then
		if tonumber(igplayers[data.steamid].greetdelay) > 0 then
			igplayers[data.steamid].greetdelay = igplayers[data.steamid].greetdelay -1
		end
	end

	if tonumber(data.ping) > 0 then
		igplayers[data.steamid].ping = data.ping
		players[data.steamid].ping = data.ping
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if faultyInfo == data.steamid then
		-- Attempt to fix the fault assuming it set some stuff because of it
		if igplayers[data.steamid].yPosLastOK == 0 then
			igplayers[data.steamid].xPosLastOK = intX
			igplayers[data.steamid].yPosLastOK = intY
			igplayers[data.steamid].zPosLastOK = intZ
		end
	end

	playerAccessLevel = accessLevel(data.steamid)

	if playerAccessLevel < 3 then
		-- admins don't hack (no lie) ^^
		players[data.steamid].hackerScore = 0
		admin = true
	end

	if data.ip ~= "" and players[data.steamid].ip == "" then
		players[data.steamid].IP = data.ip
		CheckBlacklist(data.steamid, data.ip)
	end

	-- ping kick
	if (not whitelist[data.steamid]) and (not players[data.steamid].donor) and (playerAccessLevel > 2) then
		if (server.pingKickTarget == "new" and players[data.steamid].newPlayer) or server.pingKickTarget == "all" then
			if tonumber(data.ping) < tonumber(server.pingKick) and tonumber(server.pingKick) > 0 then
				igplayers[data.steamid].highPingCount = tonumber(igplayers[data.steamid].highPingCount) - 1
				if tonumber(igplayers[data.steamid].highPingCount) < 0 then igplayers[data.steamid].highPingCount = 0 end
			end

			if tonumber(data.ping) > tonumber(server.pingKick) and tonumber(server.pingKick) > 0 then
				igplayers[data.steamid].highPingCount = tonumber(igplayers[data.steamid].highPingCount) + 1

				if tonumber(igplayers[data.steamid].highPingCount) > 15 then
					irc_chat(server.ircMain, "Kicked " .. data.name .. " steam: " .. data.steamid.. " for high ping " .. data.ping)
					kick(data.steamid, "High ping kicked.")
					return
				end
			end
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if tonumber(intY) > 0 and tonumber(intY) < 500 then
		igplayers[data.steamid].lastTP = nil
		forgetLastTP(data.steamid)
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if players[data.steamid].location ~= "" and igplayers[data.steamid].spawnedInWorld then
		-- spawn the player at location
		if (locations[players[data.steamid].location]) then
			irc_chat(server.ircMain, "Player " .. data.steamid .. " " .. data.name .. " is being moved to " .. players[data.steamid].location)
			irc_chat(server.ircAlerts, "Player " .. data.steamid .. " " .. data.name .. " is being moved to " .. players[data.steamid].location)

			message(string.format("pm %s [%s]You are being moved to %s[-]", data.steamid, server.chatColour, players[data.steamid].location))
			randomTP(data.steamid, players[data.steamid].location, true)

			players[data.steamid].location = ""
			if botman.dbConnected then conn:execute("UPDATE players SET location = '' WHERE steam = " .. data.steamid) end
		end

		if (players[data.steamid].location == "return player") then

			if players[data.steamid].xPosTimeout ~= 0 and players[data.steamid].zPosTimeout ~= 0 then
				cmd = "tele " .. data.steamid .. " " .. players[data.steamid].xPosTimeout .. " " .. players[data.steamid].yPosTimeout .. " " .. players[data.steamid].zPosTimeout
				players[data.steamid].xPosTimeout = 0
				players[data.steamid].yPosTimeout = 0
				players[data.steamid].zPosTimeout = 0
			else
				cmd = "tele " .. data.steamid .. " " .. players[data.steamid].xPosOld .. " " .. players[data.steamid].yPosOld .. " " .. players[data.steamid].zPosOld
			end

			teleport(cmd, data.steamid)
			players[data.steamid].location = ""
			if botman.dbConnected then conn:execute("UPDATE players SET location = '' WHERE steam = " .. data.steamid) end
		end
	end

	if tonumber(players[data.steamid].hackerScore) >= 10000 then
		players[data.steamid].hackerScore = 0

		if igplayers[data.steamid].hackerDetection ~= nil then
			message(string.format("say [%s]Banning %s. Hacking suspected. Evidence: " .. igplayers[data.steamid].hackerDetection .. "[-]", server.chatColour, players[data.steamid].name))
		else
			message(string.format("say [%s]Banning %s. Detected possible evidence of hacking.[-]", server.chatColour, players[data.steamid].name))
		end

		banPlayer(data.steamid, "1 year", "Automatic ban for suspected hacking. Admins have been alerted.", "")

		-- if the player has any pending global bans, activate them
		connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = " .. data.steamid)
	else
		if tonumber(players[data.steamid].hackerScore) >= 49  then
			-- if the player has pending global bans recorded against them, we ban them early and also activate the global ban
			if tonumber(players[data.steamid].pendingBans) > 0 then
				players[data.steamid].hackerScore = 0
				if igplayers[data.steamid].hackerDetection ~= nil then
					message(string.format("say [%s]Temp banning %s. May be hacking. Detected " .. igplayers[data.steamid].hackerDetection .. "[-]", server.chatColour, players[data.steamid].name))
				else
					message(string.format("say [%s]Temp banning %s 1 week. Detected clipping or flying too much. Admins have been alerted.[-]", server.chatColour, players[data.steamid].name))
				end

				banPlayer(data.steamid, "1 week", "Automatic ban for suspected hacking. Admins have been alerted.", "")

				-- activate the pending bans
				connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = " .. data.steamid)
			end
		end

		if tonumber(players[data.steamid].hackerScore) >= 60 then
			players[data.steamid].hackerScore = 0
			if igplayers[data.steamid].hackerDetection ~= nil then
				message(string.format("say [%s]Temp banning %s 1 week for suspected hacking. Detected " .. igplayers[data.steamid].hackerDetection .. "[-]", server.chatColour, players[data.steamid].name))
			else
				message(string.format("say [%s]Temp banning %s 1 week for suspected hacking.[-]", server.chatColour, players[data.steamid].name))
			end

			banPlayer(data.steamid, "1 week", "Automatic ban for suspected hacking. Admins have been alerted.", "")

			-- if the player has any pending global bans, activate them
			connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = " .. data.steamid)
		end
	end


	-- test for hackers teleporting
	if server.hackerTPDetection and igplayers[data.steamid].spawnChecked == false and not igplayers[data.steamid].spawnPending then
		igplayers[data.steamid].spawnChecked = true

		-- ignore tele spawns for 10 seconds after the last legit tp to allow for lag and extra tp commands on delayed tp servers.
		if (os.time() - igplayers[data.steamid].lastTPTimestamp > 10) and (igplayers[data.steamid].spawnedCoordsOld ~= igplayers[data.steamid].spawnedCoords)then
			if not (players[data.steamid].timeout or players[data.steamid].botTimeout or players[data.steamid].ignorePlayer) then
				if tonumber(intX) ~= 0 and tonumber(intZ) ~= 0 and tonumber(igplayers[data.steamid].xPos) ~= 0 and tonumber(igplayers[data.steamid].zPos) ~= 0 then
					dist = 0

					if igplayers[data.steamid].spawnedInWorld and igplayers[data.steamid].spawnedReason == "teleport" and igplayers[data.steamid].spawnedCoordsOld ~= "0 0 0" then
						dist = distancexz(posX, posZ, igplayers[data.steamid].xPos, igplayers[data.steamid].zPos)
					end

					if (dist >= 900) then
						if tonumber(igplayers[data.steamid].tp) < 1 then
							if players[data.steamid].newPlayer == true then
								new = " [FF8C40]NEW player "
							else
								new = " [FF8C40]Player "
							end

							if playerAccessLevel > 2 then
								irc_chat(server.ircMain, botman.serverTime .. " Player " .. data.entityid .. " " .. data.steamid .. " name: " .. data.name .. " detected teleporting to " .. intX .. " " .. intY .. " " .. intZ .. " distance " .. string.format("%-8.2d", dist))
								irc_chat(server.ircAlerts, server.gameDate .. " player " .. data.entityid .. " " .. data.steamid .. " name: " .. data.name .. " detected teleporting to " .. intX .. " " .. intY .. " " .. intZ .. " distance " .. string.format("%-8.2d", dist))

								igplayers[data.steamid].hackerTPScore = tonumber(igplayers[data.steamid].hackerTPScore) + 1
								players[data.steamid].watchPlayer = true
								players[data.steamid].watchPlayerTimer = os.time() + 259200 -- watch for 3 days
								if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + 259200 .. " WHERE steam = " .. data.steamid) end

								if tonumber(players[data.steamid].exiled) == 1 or players[data.steamid].newPlayer then
									igplayers[data.steamid].hackerTPScore = tonumber(igplayers[data.steamid].hackerTPScore) + 1
								end

								if igplayers[data.steamid].hackerTPScore > 0 and players[data.steamid].newPlayer and tonumber(players[data.steamid].ping) > 180 then
									if locations["exile"] and not players[data.steamid].prisoner then
										players[data.steamid].exiled = 1
									else
										igplayers[data.steamid].hackerTPScore = tonumber(igplayers[data.steamid].hackerTPScore) + 1
									end
								end

								if tonumber(igplayers[data.steamid].hackerTPScore) > 1 then
									igplayers[data.steamid].hackerTPScore = 0
									igplayers[data.steamid].tp = 0
									message(string.format("say [%s]Temp banning %s 1 week for unexplained teleporting. An admin will investigate the circumstances.[-]", server.chatColour, players[data.steamid].name))
									banPlayer(data.steamid, "1 week", "We detected unusual teleporting from you and are investigating the circumstances.", "")

									-- if the player has any pending global bans, activate them
									connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = " .. data.steamid)
								end

								alertAdmins(data.entityid .. " name: " .. data.name .. " detected teleporting! In fly mode, type " .. server.commandPrefix .. "near " .. data.entityid .. " to shadow them.", "warn")
							end
						end

						igplayers[data.steamid].tp = 0
					else
						igplayers[data.steamid].tp = 0
					end
				end
			end
		end

		igplayers[data.steamid].spawnChecked = true
		igplayers[data.steamid].spawnedCoordsOld = igplayers[data.steamid].spawnedCoords
	end

	igplayers[data.steamid].lastLP = os.time()

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	players[data.steamid].id = data.entityid
	players[data.steamid].name = data.name
	players[data.steamid].steamOwner = igplayers[data.steamid].steamOwner
	igplayers[data.steamid].id = data.entityid
	igplayers[data.steamid].name = data.name
	igplayers[data.steamid].steam = data.steamid

	if igplayers[data.steamid].deaths ~= nil then
		if tonumber(igplayers[data.steamid].deaths) < tonumber(data.playerdeaths) then
			if server.SDXDetected and tonumber(igplayers[data.steamid].yPosLast) > 0 then
				players[data.steamid].deathX = math.floor(igplayers[data.steamid].xPosLast)
				players[data.steamid].deathY = math.ceil(igplayers[data.steamid].yPosLast)
				players[data.steamid].deathZ = math.floor(igplayers[data.steamid].zPosLast)

				igplayers[data.steamid].deadX = math.floor(igplayers[data.steamid].xPosLast)
				igplayers[data.steamid].deadY = math.ceil(igplayers[data.steamid].yPosLast)
				igplayers[data.steamid].deadZ = math.floor(igplayers[data.steamid].zPosLast)
				igplayers[data.steamid].teleCooldown = 1000

				irc_chat(server.ircMain, "Player " .. data.steamid .. " name: " .. data.name .. "'s death recorded at " .. igplayers[data.steamid].deadX .. " " .. igplayers[data.steamid].deadY .. " " .. igplayers[data.steamid].deadZ)
				irc_chat(server.ircAlerts, server.gameDate .. " player " .. data.steamid .. " name: " .. data.name .. "'s death recorded at " .. igplayers[data.steamid].deadX .. " " .. igplayers[data.steamid].deadY .. " " .. igplayers[data.steamid].deadZ)

				message("say [" .. server.chatColour .. "]" .. data.name .. " has died.[-]")

				r = rand(14)
				if (r == 1) then message("say [" .. server.chatColour .. "]" .. data.name .. " removed themselves from the gene pool.[-]") end
				if (r == 2) then message("say [" .. server.chatColour .. "]LOL!  Didn't run far away enough did you " .. data.name .. "?[-]") end
				if (r == 3) then message("say [" .. server.chatColour .. "]And the prize for most creative way to end themselves goes to.. " .. data.name .. "[-]") end
				if (r == 4) then message("say [" .. server.chatColour .. "]" .. data.name .. " really shouldn't handle explosives.[-]") end
				if (r == 5) then message("say Oh no! " .. data.name .. " died.  What a shame.[-]") end
				if (r == 6) then message("say [" .. server.chatColour .. "]Great effort there " .. data.name .. ". I'm awarding " .. data.score .. " points.[-]") end
				if (r == 7) then message("say [" .. server.chatColour .. "]LOL! REKT[-]") end

				if (r == 8) then
					message("say [" .. server.chatColour .. "]We are gathered here today to remember with sadness the passing of " .. data.name .. ". Rest in pieces. Amen.[-]")
				end

				if (r == 9) then message("say [" .. server.chatColour .. "]" .. data.name .. " cut the wrong wire.[-]") end
				if (r == 10) then message("say [" .. server.chatColour .. "]" .. data.name .. " really showed that explosive who's boss![-]") end
				if (r == 11) then message("say [" .. server.chatColour .. "]" .. data.name .. " shouldn't play Russian Roulette with a fully loaded gun.[-]") end
				if (r == 12) then message("say [" .. server.chatColour .. "]" .. data.name .. " added a new stain to the floor.[-]") end
				if (r == 13) then message("say [" .. server.chatColour .. "]ISIS got nothing on " .. data.name .. "'s suicide bomber skillz.[-]") end
				if (r == 14) then message("say [" .. server.chatColour .. "]" .. data.name .. " reached a new low with that death. Six feet under.[-]") end

				if tonumber(server.packCooldown) > 0 then
					players[data.steamid].packCooldown = os.time() + server.packCooldown
				end
			end
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	igplayers[data.steamid].xPosLast = igplayers[data.steamid].xPos
	igplayers[data.steamid].yPosLast = igplayers[data.steamid].yPos
	igplayers[data.steamid].zPosLast = igplayers[data.steamid].zPos
	igplayers[data.steamid].xPos = posX
	igplayers[data.steamid].yPos = posY
	igplayers[data.steamid].zPos = posZ
	igplayers[data.steamid].playerKills = data.playerkills
	igplayers[data.steamid].deaths = data.playerdeaths
	igplayers[data.steamid].zombies = data.zombiekills
	igplayers[data.steamid].score = data.score

	if igplayers[data.steamid].oldLevel == nil then
		igplayers[data.steamid].oldLevel = data.level
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- hacker detection
	if tonumber(data.level) - tonumber(igplayers[data.steamid].oldLevel) > 50 and not admin and server.alertLevelHack then
		alertAdmins(data.entityid .. " name: " .. data.name .. " detected possible level hacking!  Old level was " .. igplayers[data.steamid].oldLevel .. " new level is " .. data.level .. " an increase of " .. tonumber(data.level) - tonumber(igplayers[data.steamid].oldLevel), "alert")
		irc_chat(server.ircAlerts, server.gameDate .. " " .. data.steamid .. " name: " .. data.name .. " detected possible level hacking!  Old level was " .. igplayers[data.steamid].oldLevel .. " new level is " .. data.level .. " an increase of " .. tonumber(data.level) - tonumber(igplayers[data.steamid].oldLevel))
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if server.checkLevelHack then
		if tonumber(data.level) - tonumber(igplayers[data.steamid].oldLevel) > 50 and not admin then
			players[data.steamid].hackerScore = 10000
			igplayers[data.steamid].hackerDetection = "Suspected level hack. (" .. data.level .. ") an increase of " .. tonumber(data.level) - tonumber(igplayers[data.steamid].oldLevel)
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	players[data.steamid].level = data.level
	igplayers[data.steamid].level = data.level
	igplayers[data.steamid].oldLevel = data.level
	igplayers[data.steamid].killTimer = 0 -- to help us detect a player that has disconnected unnoticed
	igplayers[data.steamid].raiding = false
	igplayers[data.steamid].regionX = regionX
	igplayers[data.steamid].regionZ = regionZ
	igplayers[data.steamid].chunkX = chunkX
	igplayers[data.steamid].chunkZ = chunkZ

	if pvpZone(posX, posZ) then
		igplayers[data.steamid].currentLocationPVP = true
	else
		igplayers[data.steamid].currentLocationPVP = false
	end

	if (igplayers[data.steamid].xPosLast == nil) then
		igplayers[data.steamid].xPosLast = posX
		igplayers[data.steamid].yPosLast = posY
		igplayers[data.steamid].zPosLast = posZ
		igplayers[data.steamid].xPosLastOK = intX
		igplayers[data.steamid].yPosLastOK = intY
		igplayers[data.steamid].zPosLastOK = intZ
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	atHome(data.steamid)
	currentLocation = inLocation(intX, intZ)

	if currentLocation ~= false then
		igplayers[data.steamid].currentLocationPVP = locations[currentLocation].pvp
		igplayers[data.steamid].inLocation = currentLocation
		players[data.steamid].inLocation = currentLocation

		resetZone = locations[currentLocation].resetZone

		if locations[currentLocation].killZombies then
			server.scanZombies = true
		end
	else
		players[data.steamid].inLocation = ""
		igplayers[data.steamid].inLocation = ""
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if server.showLocationMessages then
		if igplayers[data.steamid].alertLocation ~= currentLocation and currentLocation ~= false then
			if locations[currentLocation].public or playerAccessLevel < 3 then
				message(string.format("pm %s [%s]Welcome to %s[-]", data.steamid, server.chatColour, currentLocation))
			end
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if currentLocation == false then
		if server.showLocationMessages then
			if igplayers[data.steamid].alertLocation ~= "" then
				if not locations[igplayers[data.steamid].alertLocation] then
					igplayers[data.steamid].alertLocation = ""
				else
					if locations[igplayers[data.steamid].alertLocation].public or playerAccessLevel < 3 then
						message(string.format("pm %s [%s]You have left %s[-]", data.steamid, server.chatColour, igplayers[data.steamid].alertLocation))
					end
				end
			end
		end

		igplayers[data.steamid].alertLocation = ""
	else
		igplayers[data.steamid].alertLocation = currentLocation
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- fix weird cash bug
	if tonumber(players[data.steamid].cash) < 0 then
		players[data.steamid].cash = 0
	end

	-- convert zombie kills to cash
	if (tonumber(igplayers[data.steamid].zombies) > tonumber(players[data.steamid].zombies)) and (math.abs(igplayers[data.steamid].zombies - players[data.steamid].zombies) < 20) then
		if server.allowBank then
			players[data.steamid].cash = tonumber(players[data.steamid].cash) + math.abs(igplayers[data.steamid].zombies - players[data.steamid].zombies) * server.zombieKillReward

			if (players[data.steamid].watchCash == true) then
				message(string.format("pm %s [%s]+%s %s $%s in the bank[-]", data.steamid, server.chatColour, math.abs(igplayers[data.steamid].zombies - players[data.steamid].zombies) * server.zombieKillReward, server.moneyPlural, players[data.steamid].cash))
			end
		end

		if igplayers[data.steamid].doge then
			r = rand(60)
			if r == 1 then message(string.format("pm %s [%s]MUCH KILL[-]", data.steamid, server.chatColour)) end
			if r == 2 then message(string.format("pm %s [%s]GREAT PAIN[-]", data.steamid, server.chatColour)) end
			if r == 3 then message(string.format("pm %s [%s]WOW[-]", data.steamid, server.chatColour)) end
			if r == 4 then message(string.format("pm %s [%s]VERY DEATH[-]", data.steamid, server.chatColour)) end
			if r == 5 then message(string.format("pm %s [%s]AMAZING[-]", data.steamid, server.chatColour)) end
			if r == 6 then message(string.format("pm %s [%s]CALL 911[-]", data.steamid, server.chatColour)) end
			if r == 7 then message(string.format("pm %s [%s]BIG HIT[-]", data.steamid, server.chatColour)) end
			if r == 8 then message(string.format("pm %s [%s]EXTREME GORE[-]", data.steamid, server.chatColour)) end
			if r == 9 then message(string.format("pm %s [%s]EXTREME POWER SHOT[-]", data.steamid, server.chatColour)) end
			if r == 10 then message(string.format("pm %s [%s]EPIC BLOOD LOSS[-]", data.steamid, server.chatColour)) end
			if r == 11 then message(string.format("pm %s [%s]OMG[-]", data.steamid, server.chatColour)) end
			if r == 12 then message(string.format("pm %s [%s]OVERKILL[-]", data.steamid, server.chatColour)) end
			if r == 13 then message(string.format("pm %s [%s]EXTREME OVERKILL[-]", data.steamid, server.chatColour)) end
			if r == 14 then message(string.format("pm %s [%s]VERY OP[-]", data.steamid, server.chatColour)) end
			if r == 15 then message(string.format("pm %s [%s]DISMEMBERMENT[-]", data.steamid, server.chatColour)) end
			if r == 16 then message(string.format("pm %s [%s]HEADSHOT[-]", data.steamid, server.chatColour)) end
			if r == 17 then message(string.format("pm %s [%s]PSYCHO[-]", data.steamid, server.chatColour)) end
			if r == 18 then message(string.format("pm %s [%s]HAX[-]", data.steamid, server.chatColour)) end
			if r == 19 then message(string.format("pm %s [%s]GAME OVER MAN!  GAME OVER![-]", data.steamid, server.chatColour)) end
			if r == 20 then message(string.format("pm %s [%s]OWNED[-]", data.steamid, server.chatColour)) end
			if r == 21 then message(string.format("pm %s [%s]DUDE[-]", data.steamid, server.chatColour)) end
			if r == 22 then message(string.format("pm %s [%s]SICK[-]", data.steamid, server.chatColour)) end
			if r == 23 then message(string.format("pm %s [%s]INCREDIBLE[-]", data.steamid, server.chatColour)) end
			if r == 24 then message(string.format("pm %s [%s]BODY PARTS FLYING[-]", data.steamid, server.chatColour)) end
			if r == 25 then message(string.format("pm %s [%s]WTF[-]", data.steamid, server.chatColour)) end
			if r == 26 then message(string.format("pm %s [%s]EPIC[-]", data.steamid, server.chatColour)) end
			if r == 27 then message(string.format("pm %s [%s]AIMBOT HAX[-]", data.steamid, server.chatColour)) end
			if r == 28 then message(string.format("pm %s [%s]EXPLOSIVE[-]", data.steamid, server.chatColour)) end
			if r == 29 then message(string.format("pm %s [%s]IMPOSSIBRU[-]", data.steamid, server.chatColour)) end
			if r == 30 then message(string.format("pm %s [%s]MASSIVE HURT[-]", data.steamid, server.chatColour)) end
			if r == 31 then message(string.format("pm %s [%s]C-C-C-COMBO BREAKER[-]", data.steamid, server.chatColour)) end
			if r == 32 then message(string.format("pm %s [%s]ULTRA KILL[-]", data.steamid, server.chatColour)) end
			if r == 33 then message(string.format("pm %s [%s]SUPPRESSED[-]", data.steamid, server.chatColour)) end
			if r == 34 then message(string.format("pm %s [%s]IMPRESSIVE[-]", data.steamid, server.chatColour)) end
			if r == 35 then message(string.format("pm %s [%s]ONE UP[-]", data.steamid, server.chatColour)) end
			if r == 36 then message(string.format("pm %s [%s]MEGA KILL[-]", data.steamid, server.chatColour)) end
			if r == 37 then message(string.format("pm %s [%s]SUPER KILL[-]", data.steamid, server.chatColour)) end
			if r == 38 then message(string.format("pm %s [%s]SKILL SHOT[-]", data.steamid, server.chatColour)) end
			if r == 39 then message(string.format("pm %s [%s]VERY AMAZING[-]", data.steamid, server.chatColour)) end
			if r == 40 then message(string.format("pm %s [%s]EPIC OWNAGE[-]", data.steamid, server.chatColour)) end
			if r == 41 then message(string.format("pm %s [%s]OMG WTF HAX[-]", data.steamid, server.chatColour)) end
			if r == 42 then message(string.format("pm %s [%s]HOW?[-]", data.steamid, server.chatColour)) end
			if r == 43 then message(string.format("pm %s [%s]UNPOSSIBLE![-]", data.steamid, server.chatColour)) end
			if r == 44 then message(string.format("pm %s [%s]CRAZY KILL[-]", data.steamid, server.chatColour)) end
			if r == 45 then message(string.format("pm %s [%s]LEGENDARY KILL[-]", data.steamid, server.chatColour)) end
			if r == 46 then message(string.format("pm %s [%s]GUTSY[-]", data.steamid, server.chatColour)) end
			if r == 47 then message(string.format("pm %s [%s]SMOOTH[-]", data.steamid, server.chatColour)) end
			if r == 48 then message(string.format("pm %s [%s]PRO[-]", data.steamid, server.chatColour)) end
			if r == 49 then message(string.format("pm %s [%s]NUKED[-]", data.steamid, server.chatColour)) end
			if r == 50 then message(string.format("pm %s [%s]STOLEN KILL[-]", data.steamid, server.chatColour)) end
			if r == 51 then message(string.format("pm %s [%s]LEEEEEEEEEEEEEROY JENKINS!!!!!![-]", data.steamid, server.chatColour)) end
			if r == 52 then message(string.format("pm %s [%s]TRUMPED[-]", data.steamid, server.chatColour)) end
			if r == 53 then message(string.format("pm %s [%s]CRAP[-]", data.steamid, server.chatColour)) end
			if r == 54 then message(string.format("pm %s [%s]WTF BBQ[-]", data.steamid, server.chatColour)) end
			if r == 55 then message(string.format("pm %s [%s]KILLJOY[-]", data.steamid, server.chatColour)) end
			if r == 56 then message(string.format("pm %s [%s]TIS BUT A SCRATCH[-]", data.steamid, server.chatColour)) end
			if r == 57 then message(string.format("pm %s [%s]LEGLESS[-]", data.steamid, server.chatColour)) end
			if r == 58 then message(string.format("pm %s [%s]OOPS[-]", data.steamid, server.chatColour)) end
			if r == 59 then message(string.format("pm %s [%s]DAMN[-]", data.steamid, server.chatColour)) end
			if r == 60 then message(string.format("pm %s [%s]RIM SHOT[-]", data.steamid, server.chatColour)) end
		end

		if server.allowBank then
			-- update the lottery prize pool
			server.lottery = server.lottery + (math.abs(igplayers[data.steamid].zombies - players[data.steamid].zombies) * server.lotteryMultiplier)
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- update player record of zombies
	players[data.steamid].zombies = igplayers[data.steamid].zombies

	if tonumber(players[data.steamid].playerKills) < tonumber(data.playerkills) then
		players[data.steamid].playerKills = data.playerkills
	end

	if tonumber(players[data.steamid].deaths) < tonumber(data.playerdeaths) then
		players[data.steamid].deaths = data.playerdeaths
	end

	if tonumber(players[data.steamid].score) < tonumber(data.score) then
		players[data.steamid].score = data.score
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	players[data.steamid].xPos = posX
	players[data.steamid].yPos = posY
	players[data.steamid].zPos = posZ

	mapCenterDistance = distancexz(intX,intZ,0,0)
	outsideMap = squareDistance(intX, intZ, server.mapSize)
	outsideMapDonor = squareDistance(intX, intZ, server.mapSize + 5000)

	if (players[data.steamid].alertReset == nil) then
		players[data.steamid].alertReset = true
	end

	if (igplayers[data.steamid].greet) and tonumber(igplayers[data.steamid].greetdelay) == 0 then
		igplayers[data.steamid].greet = false

		if server.welcome ~= nil then
			message(string.format("pm %s [%s]%s[-]", data.steamid, server.chatColour, server.welcome))
		else
			message("pm " .. data.steamid .. " [" .. server.chatColour .. "]Welcome to " .. server.serverName .. "!  Type " .. server.commandPrefix .. "info, " .. server.commandPrefix .. "rules or " .. server.commandPrefix .. "help for commands.[-]")
			message(string.format("pm %s [%s]We have a server manager bot called %s[-]", data.steamid, server.chatColour, server.botName))
		end

		if (tonumber(igplayers[data.steamid].zombies) ~= 0) then
			if (players[data.steamid].donor == true) then
				welcome = "pm " .. data.steamid .. " [" .. server.chatColour .. "]Welcome back " .. data.name .. "! Thanks for supporting us. =D[-]"
			else
				welcome = "pm " .. data.steamid .. " [" .. server.chatColour .. "]Welcome back " .. data.name .. "![-]"
			end

			if (string.find(botman.serverTime, "02-14", 5, 10)) then welcome = "pm " .. data.steamid .. " [" .. server.chatColour .. "]Happy Valentines Day " .. data.name .. "! ^^[-]" end

			message(welcome)
		else
			message("pm " .. data.steamid .. " [" .. server.chatColour .. "]Welcome " .. data.name .. "![-]")
		end

		if (players[data.steamid].timeout == true) then
			message("pm " .. data.steamid .. " [" .. server.warnColour .. "]You are in timeout, not glitched or lagged.  You will stay here until released by an admin.[-]")
		end

		if (botman.scheduledRestart) then
			message("pm " .. data.steamid .. " [" .. server.alertColour .. "]<!>[-][" .. server.warnColour .. "] SERVER WILL REBOOT SHORTLY [-][" .. server.alertColour .. "]<!>[-]")
		end

		if server.MOTD ~= "" then
			if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. data.steamid .. ",'" .. escape("[" .. server.chatColour .. "]" .. server.MOTD .. "[-]") .. "')") end
		end

		if tonumber(players[data.steamid].removedClaims) > 0 then
			if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. data.steamid .. ",'" .. escape("[" .. server.chatColour .. "]I am holding " .. players[data.steamid].removedClaims .. " land claim blocks for you. Type " .. server.commandPrefix .. "give claims to receive them.[-]") .. "')") end
		end

		if botman.dbConnected then
			cursor,errorString = conn:execute("SELECT * FROM mail WHERE recipient = " .. data.steamid .. " and status = 0")
			rows = cursor:numrows()

			if rows > 0 then
				if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. data.steamid .. ",'" .. escape("[" .. server.chatColour .. "]NEW MAIL HAS ARRIVED!  Type " .. server.commandPrefix .. "read mail to read it now or " .. server.commandPrefix .. "help mail for more options.[-]") .. "')") end
			end
		end

		if players[data.steamid].newPlayer == true and server.rules ~= "" then
			if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. data.steamid .. ",'" .. escape("[" .. server.chatColour .. "]" .. server.rules .."[-]") .. "')") end
		end

		if server.warnBotReset == true and playerAccessLevel == 0 then
			if botman.dbConnected then
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. data.steamid .. ",'" .. escape("[" .. server.chatColour .. "]ALERT!  It appears that the server has been reset.[-]") .. "')")
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. data.steamid .. ",'" .. escape("[" .. server.chatColour .. "]To reset me type " .. server.commandPrefix .. "reset bot.[-]") .. "')")
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. data.steamid .. ",'" .. escape("[" .. server.chatColour .. "]To dismiss this alert type " .. server.commandPrefix .. "no reset.[-]") .. "')")
			end
		end

		if (not players[data.steamid].santa) and specialDay == "christmas" then
			if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. data.steamid .. ",'" .. escape("[" .. server.chatColour .. "]HO HO HO! Merry Christmas!  Type " .. server.commandPrefix .. "santa to open your Christmas stocking![-]") .. "')") end
		end

		-- run commands from the connectQueue now that the player has spawned and hopefully paying attention to chat
		tempTimer( 3, [[processConnectQueue("]].. data.steamid .. [[")]] )
		-- also check for removed claims
		tempTimer(10, [[CheckClaimsRemoved("]] .. data.steamid .. [[")]] )
	end


	if igplayers[data.steamid].alertLocation == "" and currentLocation ~= false then
		if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. data.steamid .. ",'" .. escape("[" .. server.chatColour .. "]Welcome to " .. currentLocation .. "[-]") .. "')") end
		igplayers[data.steamid].alertLocation = currentLocation
	end


	if (igplayers[data.steamid].teleCooldown > 0) then
		igplayers[data.steamid].teleCooldown = tonumber(igplayers[data.steamid].teleCooldown) - 1
	end

	igplayers[data.steamid].sessionPlaytime = os.time() - igplayers[data.steamid].sessionStart

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if (players[data.steamid].newPlayer == true and (igplayers[data.steamid].sessionPlaytime + players[data.steamid].timeOnServer > (server.newPlayerTimer * 60))) then
		players[data.steamid].newPlayer = false
		players[data.steamid].watchPlayer = false
		players[data.steamid].watchPlayerTimer = 0
		message("pm " .. data.steamid .. " [" .. server.chatColour .. "]Your new player status has been lifted. :D[-]")
		if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. data.steamid) end

		if string.upper(players[data.steamid].chatColour) == "FFFFFF" then
			setChatColour(data.steamid)
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- if we are following a player and they move more than 50 meters away, teleport us close to them.
	if igplayers[data.steamid].following ~= nil then
		if igplayers[igplayers[data.steamid].following] and players[igplayers[data.steamid].following].timeout == false and players[igplayers[data.steamid].following].botTimeout == false then
			followDistance = 50
			if igplayers[data.steamid].followDistance ~= nil then followDistance = tonumber(igplayers[data.steamid].followDistance) end

			dist = distancexz(igplayers[data.steamid].xPos, igplayers[data.steamid].zPos, igplayers[igplayers[data.steamid].following].xPos, igplayers[igplayers[data.steamid].following].zPos)
			if dist > followDistance and igplayers[igplayers[data.steamid].following].yPos > 0 then
				-- teleport close to the player
				igplayers[data.steamid].tp = 1
				igplayers[data.steamid].hackerTPScore = 0
				sendCommand("tele " .. data.steamid .. " " .. math.floor(igplayers[igplayers[data.steamid].following].xPos) .. " " .. math.ceil(igplayers[igplayers[data.steamid].following].yPos - 30) .. " " .. math.floor(igplayers[igplayers[data.steamid].following].zPos))
			end
		end
	end


	if (igplayers[data.steamid].alertLocationExit ~= nil) then
		dist = distancexz(igplayers[data.steamid].xPos, igplayers[data.steamid].zPos, locations[igplayers[data.steamid].alertLocationExit].x, locations[igplayers[data.steamid].alertLocationExit].z)
		size = tonumber(locations[igplayers[data.steamid].alertLocationExit].size)

		if (dist > tonumber(locations[igplayers[data.steamid].alertLocationExit].size) + 100) then
			igplayers[data.steamid].alertLocationExit = nil

			message("pm " .. data.steamid .. " [" .. server.chatColour .. "]You have moved too far away from the location. If you still wish to do " .. server.commandPrefix .. "protect location, please start again.[-]")
			faultyPlayerinfo = false
			return
		end

		if (dist > tonumber(locations[igplayers[data.steamid].alertLocationExit].size) + 10) and (dist <  tonumber(locations[igplayers[data.steamid].alertLocationExit].size) + 30) then
			locations[igplayers[data.steamid].alertLocationExit].exitX = intX
			locations[igplayers[data.steamid].alertLocationExit].exitY = intY
			locations[igplayers[data.steamid].alertLocationExit].exitZ = intZ
			locations[igplayers[data.steamid].alertLocationExit].protected = true

			if botman.dbConnected then conn:execute("UPDATE locations SET exitX = " .. intX .. ", exitY = " .. intY .. ", exitZ = " .. intZ .. ", protected = 1 WHERE name = '" .. escape(igplayers[data.steamid].alertLocationExit) .. "'") end
			message("pm " .. data.steamid .. " [" .. server.chatColour .. "]You have enabled protection for " .. igplayers[data.steamid].alertLocationExit .. ".[-]")

			igplayers[data.steamid].alertLocationExit = nil

			faultyPlayerinfo = false
			return
		end
	end


	if (igplayers[data.steamid].alertVillageExit ~= nil) then
		dist = distancexz(igplayers[data.steamid].xPos, igplayers[data.steamid].zPos, locations[igplayers[data.steamid].alertVillageExit].x, locations[igplayers[data.steamid].alertVillageExit].z)
		size = tonumber(locations[igplayers[data.steamid].alertVillageExit].size)

		if (dist > tonumber(locations[igplayers[data.steamid].alertVillageExit].size) + 100) then
			igplayers[data.steamid].alertVillageExit = nil

			message("pm " .. data.steamid .. " [" .. server.chatColour .. "]You have moved too far away from " .. igplayers[data.steamid].alertVillageExit .. ". Return to " .. igplayers[data.steamid].alertVillageExit .. " and type " .. server.commandPrefix .. "protect village " .. igplayers[data.steamid].alertVillageExit .. " again.[-]")
			faultyPlayerinfo = false
			return
		end

		if (dist >  tonumber(locations[igplayers[data.steamid].alertVillageExit].size) + 20) and (dist <  tonumber(locations[igplayers[data.steamid].alertVillageExit].size) + 100) then
			locations[igplayers[data.steamid].alertVillageExit].exitX = intX
			locations[igplayers[data.steamid].alertVillageExit].exitY = intY
			locations[igplayers[data.steamid].alertVillageExit].exitZ = intZ
			locations[igplayers[data.steamid].alertVillageExit].protected = true

			if botman.dbConnected then conn:execute("UPDATE locations SET exitX = " .. intX .. ", exitY = " .. intY .. ", exitZ = " .. intZ .. ", protected = 1 WHERE name = '" .. escape(igplayers[data.steamid].alertVillageExit) .. "'") end
			message("pm " .. data.steamid .. " [" .. server.chatColour .. "]You have enabled protection for " .. igplayers[data.steamid].alertVillageExit .. "[-]")

			igplayers[data.steamid].alertVillageExit = nil

			faultyPlayerinfo = false
			return
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if (igplayers[data.steamid].alertBaseExit == true) then
		if igplayers[data.steamid].alertBase == 1 then
			dist = distancexz(igplayers[data.steamid].xPos, igplayers[data.steamid].zPos, players[igplayers[data.steamid].alertBaseID].homeX, players[igplayers[data.steamid].alertBaseID].homeZ)
			size = tonumber(players[igplayers[data.steamid].alertBaseID].protectSize)
		else
			dist = distancexz(igplayers[data.steamid].xPos, igplayers[data.steamid].zPos, players[igplayers[data.steamid].alertBaseID].home2X, players[igplayers[data.steamid].alertBaseID].home2Z)
			size = tonumber(players[igplayers[data.steamid].alertBaseID].protect2Size)
		end

		if (dist > 200) then
			igplayers[data.steamid].alertBaseExit = nil
			igplayers[data.steamid].alertBaseID = nil
			igplayers[data.steamid].alertBase = nil

			message("pm " .. data.steamid .. " [" .. server.chatColour .. "]You have moved too far away from the base. If you still wish to do " .. server.commandPrefix .. "protect, please start again.[-]")
			faultyPlayerinfo = false
			return
		end

		if igplayers[data.steamid].alertBase == 1 then
			if (dist >  tonumber(players[igplayers[data.steamid].alertBaseID].protectSize) + 15) and (dist <  tonumber(players[igplayers[data.steamid].alertBaseID].protectSize) + 50) then
				players[igplayers[data.steamid].alertBaseID].exitX = intX
				players[igplayers[data.steamid].alertBaseID].exitY = intY
				players[igplayers[data.steamid].alertBaseID].exitZ = intZ

				if (playerAccessLevel < 3) then
					message("pm " .. data.steamid .. " [" .. server.chatColour .. "]You have set an exit teleport for " .. players[igplayers[data.steamid].alertBaseID].name .. "'s base.[-]")
				else
					message("pm " .. data.steamid .. " [" .. server.chatColour .. "]You have set an exit teleport for your base.  You can test it with " .. server.commandPrefix .. "test base.[-]")
				end

				-- check for nearby bases
				failProtect = false
				for k, v in pairs(players) do
					if (v.homeX ~= 0) and k ~= igplayers[data.steamid].alertBaseID then
							if (v.homeX ~= 0 and v.homeZ ~= 0) then
							dist = distancexz(players[igplayers[data.steamid].alertBaseID].homeX, players[igplayers[data.steamid].alertBaseID].homeZ, v.homeX, v.homeZ)

							if (tonumber(dist) < tonumber(players[igplayers[data.steamid].alertBaseID].protectSize)) then
								if friends[k] == nil or not string.find(friends[k].friends, igplayers[data.steamid].alertBaseID) then
									failProtect = true
								end
							end
						end
					end

					if (v.home2X ~= 0) and k ~= igplayers[data.steamid].alertBaseID then
						if (v.home2X ~= 0 and v.home2Z ~= 0) then
							dist = distancexz(players[igplayers[data.steamid].alertBaseID].homeX, players[igplayers[data.steamid].alertBaseID].homeZ, v.home2X, v.home2Z)

							if (dist < players[igplayers[data.steamid].alertBaseID].protectSize + 10) then
								if not string.find(friends[k].friends, igplayers[data.steamid].alertBaseID) then
									failProtect = true
								end
							end
						end
					end
				end

				if failProtect == false then
					players[igplayers[data.steamid].alertBaseID].protect = true
					message("pm " .. igplayers[data.steamid].alertBaseID .. " [" .. server.chatColour .. "]Base protection for your base is active.[-]")
				else
					message("pm " .. igplayers[data.steamid].alertBaseID .. " [" .. server.warnColour .. "]Your base is too close to another player base who is not on your friends list.  Protection cannot be enabled.[-]")
				end

				igplayers[data.steamid].alertBaseExit = nil
				igplayers[data.steamid].alertBaseID = nil
				igplayers[data.steamid].alertBase = nil

				faultyPlayerinfo = false
				return
			end
		else
			if (dist >  tonumber(players[igplayers[data.steamid].alertBaseID].protect2Size) + 15) and (dist <  tonumber(players[igplayers[data.steamid].alertBaseID].protect2Size) + 50) then
				players[igplayers[data.steamid].alertBaseID].exit2X = intX
				players[igplayers[data.steamid].alertBaseID].exit2Y = intY
				players[igplayers[data.steamid].alertBaseID].exit2Z = intZ

				if (playerAccessLevel < 3) then
					message("pm " .. data.steamid .. " [" .. server.chatColour .. "]You have set an exit teleport for " .. players[igplayers[data.steamid].alertBaseID].name .. "'s 2nd base.[-]")
				else
					message("pm " .. data.steamid .. " [" .. server.chatColour .. "]You have set an exit teleport for your 2nd base.  You can test it with " .. server.commandPrefix .. "test base.[-]")
				end

				-- check for nearby bases
				failProtect = false
				for k, v in pairs(players) do
					if (v.homeX ~= 0) and k ~= igplayers[data.steamid].alertBaseID then
							if (v.homeX ~= 0 and v.homeZ ~= 0) then
							dist = distancexz(players[igplayers[data.steamid].alertBaseID].home2X, players[igplayers[data.steamid].alertBaseID].home2Z, v.homeX, v.homeZ)

							if (tonumber(dist) < tonumber(players[igplayers[data.steamid].alertBaseID].protect2Size)) then
								if friends[k] == nil or not string.find(friends[k].friends, igplayers[data.steamid].alertBaseID) then
									failProtect = true
								end
							end
						end
					end

					if (v.home2X ~= 0) and k ~= igplayers[data.steamid].alertBaseID then
						if (v.home2X ~= 0 and v.home2Z ~= 0) then
							dist = distancexz(players[igplayers[data.steamid].alertBaseID].home2X, players[igplayers[data.steamid].alertBaseID].home2Z, v.home2X, v.home2Z)

							if (dist < players[igplayers[data.steamid].alertBaseID].protect2Size + 10) then
								if not string.find(friends[k].friends, igplayers[data.steamid].alertBaseID) then
									failProtect = true
								end
							end
						end
					end
				end

				if failProtect == false then
					players[igplayers[data.steamid].alertBaseID].protect2 = true
					message("pm " .. igplayers[data.steamid].alertBaseID .. " [" .. server.chatColour .. "]Base protection for your second base is active.[-]")
				else
					message("pm " .. igplayers[data.steamid].alertBaseID .. " [" .. server.warnColour .. "]Your second base is too close to another player base who is not on your friends list.  Protection cannot be enabled.[-]")
				end

				igplayers[data.steamid].alertBaseExit = nil
				igplayers[data.steamid].alertBaseID = nil
				igplayers[data.steamid].alertBase = nil

				faultyPlayerinfo = false
				return
			end
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	x = math.floor(igplayers[data.steamid].xPos / 512)
	z = math.floor(igplayers[data.steamid].zPos / 512)

	if (playerAccessLevel < 4) and server.enableRegionPM then
		if (igplayers[data.steamid].region ~= "r." .. x .. "." .. z .. ".7rg") then
			message("pm " .. data.steamid .. " [" .. server.chatColour .. "]Region " .. x .. "." .. z .. "[-]")
		end
	end

	igplayers[data.steamid].region = region
	igplayers[data.steamid].regionX = x
	igplayers[data.steamid].regionZ = z

	-- timeout
	if (players[data.steamid].timeout == true or players[data.steamid].botTimeout == true) and igplayers[data.steamid].spawnedInWorld then
		if (intY < 30000) then
			igplayers[data.steamid].tp = 1
			igplayers[data.steamid].hackerTPScore = 0
			sendCommand("tele " .. data.steamid .. " " .. intX .. " " .. 60000 .. " " .. intZ)
		end

		faultyPlayerinfo = false
		return
	end

	-- emergency return from timeout
	if (not players[data.steamid].timeout and not  players[data.steamid].botTimeout) and intY > 1000 and playerAccessLevel > 2 then
		igplayers[data.steamid].tp = 1
		igplayers[data.steamid].hackerTPScore = 0

		if players[data.steamid].yPosTimeout == 0 then
			sendCommand("tele " .. data.steamid .. " " .. intX .. " -1 " .. intZ)
		else
			sendCommand("tele " .. data.steamid .. " " .. players[data.steamid].xPosTimeout .. " " .. players[data.steamid].yPosTimeout .. " " .. players[data.steamid].zPosTimeout)
		end

		players[data.steamid].xPosTimeout = 0
		players[data.steamid].yPosTimeout = 0
		players[data.steamid].zPosTimeout = 0
		faultyPlayerinfo = false
		return
	end


	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- prevent player exceeding the map limit unless they are an admin except when ignoreadmins is false
	if not isDestinationAllowed(data.steamid, intX, intZ) then
		if players[data.steamid].donor then
			message("pm " .. data.steamid .. " [" .. server.warnColour .. "]This map is restricted to " .. (server.mapSize / 1000) .. " km from the center.[-]")
		else
			message("pm " .. data.steamid .. " [" .. server.warnColour .. "]This map is restricted to " .. (server.mapSize / 1000) .. " km from the center.[-]")
		end

		igplayers[data.steamid].tp = 1
		igplayers[data.steamid].hackerTPScore = 0

		if not isDestinationAllowed(data.steamid, igplayers[data.steamid].xPosLastOK, igplayers[data.steamid].zPosLastOK) then
			send ("tele " .. data.steamid .. " 1 -1 0") -- if we don't know where to send the player, send them to the middle of the map. This should only happen rarely.
			message("pm " .. data.steamid .. " [" .. server.warnColour .. "]You have been moved to the center of the map.[-]")
		else
			send ("tele " .. data.steamid .. " " .. igplayers[data.steamid].xPosLastOK .. " " .. igplayers[data.steamid].yPosLastOK .. " " .. igplayers[data.steamid].zPosLastOK)
		end

		faultyPlayerinfo = false
		return
	end

	if tonumber(players[data.steamid].exiled) == 1 and locations["exile"] and not players[data.steamid].prisoner then
		if (distancexz( intX, intZ, locations["exile"].x, locations["exile"].z ) > tonumber(locations["exile"].size)) then
			randomTP(data.steamid, "exile", true)
			faultyPlayerinfo = false
			return
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- left prison zone warning
	if (locations["prison"]) then
		if (distancexz( intX, intZ, locations["prison"].x, locations["prison"].z ) > tonumber(locations["prison"].size)) then
			if (players[data.steamid].alertPrison == false) then
				players[data.steamid].alertPrison = true
			end
		end

		if (players[data.steamid].prisoner) then
			if (locations["prison"]) then
				if (squareDistanceXZXZ(locations["prison"].x, locations["prison"].z, intX, intZ, locations["prison"].size)) then
					players[data.steamid].alertPrison = false
					randomTP(data.steamid, "prison", true)
				end
			end

			faultyPlayerinfo = false
			return
		end

		-- entered prison zone warning
		if (distancexz( intX, intZ, locations["prison"].x, locations["prison"].z ) < tonumber(locations["prison"].size)) then
			if (players[data.steamid].alertPrison == true) then
				if (not players[data.steamid].prisoner) and server.showLocationMessages then
					message("pm " .. data.steamid .. " [" .. server.warnColour .. "]You have entered the prison.  Continue at your own risk.[-]")
				end
				players[data.steamid].alertPrison = false
			end
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- freeze!
	if (players[data.steamid].freeze == true) then
		dist = distancexz(posX, posZ, players[data.steamid].prisonxPosOld, players[data.steamid].prisonzPosOld)

		if dist > 2 then
			igplayers[data.steamid].tp = 1
			igplayers[data.steamid].hackerTPScore = 0
			sendCommand("tele " .. data.steamid .. " " .. players[data.steamid].prisonxPosOld .. " " .. players[data.steamid].prisonyPosOld .. " " .. players[data.steamid].prisonzPosOld)
		end

		faultyPlayerinfo = false
		return
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- remove player from location if the location is closed or their level is outside level restrictions
	if currentLocation ~= false then
		tmp = {}
		tmp.bootPlayer = false

		if not locations[currentLocation].open and playerAccessLevel > 2 then
			tmp.bootPlayer = true
		end

		-- check player level restrictions on the location
		if (tonumber(locations[currentLocation].minimumLevel) > 0 or tonumber(locations[currentLocation].maximumLevel) > 0) and playerAccessLevel > 2 then
			if tonumber(locations[currentLocation].minimumLevel) > 0 and data.level < tonumber(locations[currentLocation].minimumLevel) then
				tmp.bootPlayer = true
			end

			if tonumber(locations[currentLocation].minimumLevel) > 0 and tonumber(locations[currentLocation].maximumLevel) > 0 and (data.level < tonumber(locations[currentLocation].minimumLevel) or data.level > tonumber(locations[currentLocation].maximumLevel)) then
				tmp.bootPlayer = true
			end

			if tonumber(locations[currentLocation].maximumLevel) > 0 and data.level > tonumber(locations[currentLocation].maximumLevel) then
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

			tmp.cmd = "tele " .. data.steamid .. " " .. tmp.x .. " -1 " .. tmp.z
			teleport(tmp.cmd, data.steamid)
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- teleport lookup
	if (igplayers[data.steamid].teleCooldown < 1) and (players[data.steamid].prisoner == false) then
		tp = ""
		tp, match = LookupTeleport(posX, posY, posZ)
		if (tp ~= nil and teleports[tp].active == true) then
			ownerid = LookupOfflinePlayer(teleports[tp].owner)
			if (players[data.steamid].walkies ~= true) then
				if ((playerAccessLevel < 3) or (teleports[tp].owner == igplayers[data.steamid].steam or teleports[tp].public == true or isFriend(ownerid, data.steamid))) and teleports[tp].active then
					if match == 1 then
						-- check access level restrictions on the teleport
						if (playerAccessLevel >= tonumber(teleports[tp].maximumAccess) and playerAccessLevel <= tonumber(teleports[tp].minimumAccess)) or playerAccessLevel < 3 then
							if isDestinationAllowed(data.steamid, teleports[tp].dx, teleports[tp].dz) then
								igplayers[data.steamid].teleCooldown = 2
								cmd = "tele " .. data.steamid .. " " .. math.floor(teleports[tp].dx) .. " " .. math.ceil(teleports[tp].dy) .. " " .. math.floor(teleports[tp].dz)
								teleport(cmd, data.steamid)

								faultyPlayerinfo = false
								return
							end
						end
					end

					if match == 2 and teleports[tp].oneway == false then
						-- check access level restrictions on the teleport
						if (playerAccessLevel >= tonumber(teleports[tp].maximumAccess) and playerAccessLevel <= tonumber(teleports[tp].minimumAccess)) or playerAccessLevel < 3 then
							if isDestinationAllowed(data.steamid, teleports[tp].x, teleports[tp].z) then
								igplayers[data.steamid].teleCooldown = 2
								cmd = "tele " .. data.steamid .. " " .. math.floor(teleports[tp].x) .. " " .. math.ceil(teleports[tp].y) .. " " .. math.floor(teleports[tp].z)
								teleport(cmd, data.steamid)

								faultyPlayerinfo = false
								return
							end
						end
					end
				end
			end
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- linked waypoint lookup
	if (igplayers[data.steamid].teleCooldown < 1) and (players[data.steamid].prisoner == false) then
		tmp = {}
		tmp.wpid = LookupWaypoint(posX, posY, posZ)

		if tonumber(tmp.wpid) > 0 then
			tmp.linkedID = waypoints[tmp.wpid].linked

			if (waypoints[tmp.wpid].shared and isFriend(waypoints[tmp.wpid].steam, data.steamid) or waypoints[tmp.wpid].steam == data.steamid) and tonumber(tmp.linkedID) > 0 then
				-- reject if not an admin and player teleporting has been disabled
				if server.allowTeleporting then
					if isDestinationAllowed(data.steamid, waypoints[tmp.linkedID].x, waypoints[tmp.linkedID].z) then
						igplayers[data.steamid].teleCooldown = 2
						cmd = "tele " .. data.steamid .. " " .. math.floor(waypoints[tmp.linkedID].x) .. " " .. math.ceil(waypoints[tmp.linkedID].y) .. " " .. math.floor(waypoints[tmp.linkedID].z)
						teleport(cmd, data.steamid)

						faultyPlayerinfo = false
						return
					end
				else
					if playerAccessLevel < 3 then
						igplayers[data.steamid].teleCooldown = 2
						cmd = "tele " .. data.steamid .. " " .. math.floor(waypoints[tmp.linkedID].x) .. " " .. math.ceil(waypoints[tmp.linkedID].y) .. " " .. math.floor(waypoints[tmp.linkedID].z)
						teleport(cmd, data.steamid)

						faultyPlayerinfo = false
						return
					end
				end
			end
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- left reset zone warning
	if (not resetZone) then
		if (players[data.steamid].alertReset == false) then
			message("pm " .. data.steamid .. " [" .. server.chatColour .. "]You are out of the reset zone.[-]")
			players[data.steamid].alertReset = true
			faultyPlayerinfo = false
		end
	end


	-- entered reset zone warning
	if (resetZone) then
		if (players[data.steamid].alertReset == true) then
			message("pm " .. data.steamid .. " [" .. server.warnColour .. "]You are in a reset zone. Don't build here.[-]")
			players[data.steamid].alertReset = false
			faultyPlayerinfo = false

			-- check for claims in the reset zone not owned by staff and remove them
			checkRegionClaims(x, z)
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if	baseProtection(data.steamid, posX, posY, posZ) and not resetZone then
		faultyPlayerinfo = false
		return
	end

	-- add to tracker table
	dist = distancexyz(intX, intY, intZ, igplayers[data.steamid].xPosLast, igplayers[data.steamid].yPosLast, igplayers[data.steamid].zPosLast)

	if (dist > 2) and tonumber(intY) < 10000 then
		-- record the players position
		if igplayers[data.steamid].raiding then
			flag = flag .. "R"
		end

		if igplayers[data.steamid].illegalInventory then
			flag = flag .. "B"
		end

		if igplayers[data.steamid].flying or igplayers[data.steamid].noclip then
			flag = flag .. "F"
		end

		if botman.dbConnected then conn:execute("INSERT INTO tracker (steam, x, y, z, session, flag) VALUES (" .. data.steamid .. "," .. intX .. "," .. intY .. "," .. intZ .. "," .. players[data.steamid].sessionCount .. ",'" .. flag .. "')") end

		if igplayers[data.steamid].location ~= nil then
			if botman.dbConnected then conn:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. igplayers[data.steamid].location .. "'," .. intX .. "," .. intY .. "," .. intZ .. ")") end
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if (igplayers[data.steamid].deadX ~= nil) and igplayers[data.steamid].spawnedInWorld and igplayers[data.steamid].spawnedReason ~= "fake reason" then
		dist = math.abs(distancexz(igplayers[data.steamid].deadX, igplayers[data.steamid].deadZ, posX, posZ))
		if (dist > 2) then
			igplayers[data.steamid].deadX = nil
			igplayers[data.steamid].deadY = nil
			igplayers[data.steamid].deadZ = nil

			if players[data.steamid].bed ~= "" then
				if players[data.steamid].bed == "base1" then
					cmd = "tele " .. data.steamid .. " " .. players[data.steamid].homeX .. " " .. players[data.steamid].homeY .. " " .. players[data.steamid].homeZ
					teleport(cmd, data.steamid)
				end

				if players[data.steamid].bed == "base2" then
					cmd = "tele " .. data.steamid .. " " .. players[data.steamid].home2X .. " " .. players[data.steamid].home2Y .. " " .. players[data.steamid].home2Z
					teleport(cmd, data.steamid)
				end
			end
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- hotspot lookup
	hotspot = LookupHotspot(posX, posY, posZ)

	if (hotspot ~= nil) then
		tmp.skipHotspot = false

		if (igplayers[data.steamid].lastHotspot ~= hotspot) then
			for k, v in pairs(lastHotspots[data.steamid]) do
				if v == hotspot then -- don't add or display this hotspot yet.  we've seen it recently
					tmp.skipHotspot = true
				end
			end

			if not tmp.skipHotspot then
				igplayers[data.steamid].lastHotspot = hotspot
				message("pm " .. data.steamid .. " [" .. server.chatColour .. "]" .. hotspots[hotspot].hotspot .. "[-]")

				if (lastHotspots[data.steamid] == nil) then lastHotspots[data.steamid] = {} end
				if (table.maxn(lastHotspots[data.steamid]) > 4) then
					table.remove(lastHotspots[data.steamid], 1)
				end

				table.insert(lastHotspots[data.steamid],  hotspot)
			end
		end
	end


	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if igplayers[data.steamid].rawPosition ~= position then
		igplayers[data.steamid].afk = os.time() + 900
		igplayers[data.steamid].rawPosition = position
	end

	if igplayers[data.steamid].spawnedInWorld then
		if igplayers[data.steamid].greet and tonumber(igplayers[data.steamid].greetdelay) > 0 then
			-- Player has spawned.  We can greet them now and do other stuff that waits for spawn
			igplayers[data.steamid].greetdelay = 0
		end

		if tonumber(igplayers[data.steamid].teleCooldown) > 100 then
			igplayers[data.steamid].teleCooldown = 0
		end
	end


	if tonumber(botman.playersOnline) >= tonumber(server.maxPlayers) and (playerAccessLevel > 3) and server.idleKick then
		if (igplayers[data.steamid].afk - os.time() < 0) then
			kick(data.steamid, "Server is full.  You were kicked because you idled too long, but you can rejoin at any time. Thanks for playing! xD")
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	if igplayers[data.steamid].currentLocationPVP then
		if players[data.steamid].alertPVP == true then
			message("pm " .. data.steamid .. " [" .. server.alertColour .. "]You have entered a PVP zone!  Players are allowed to kill you![-]")
			players[data.steamid].alertPVP = false
			faultyPlayerinfo = false
		end
	else
		if players[data.steamid].alertPVP == false then
			message("pm " .. data.steamid .. " [" .. server.warnColour .. "]You have entered a PVE zone.  Do not kill other players![-]")
			players[data.steamid].alertPVP = true
			faultyPlayerinfo = false
		end
	end

	if (data.steamid == debugPlayerInfo) and debug then dbug("debug playerinfoJSON line " .. debugger.getinfo(1).currentline, true) end

	-- stuff to do after everything else

	-- record this coord as the last one that the player was allowed to be at.  if their next step is not allowed, they get returned to this one.
	igplayers[data.steamid].xPosLastOK = intX
	igplayers[data.steamid].yPosLastOK = intY
	igplayers[data.steamid].zPosLastOK = intZ

	faultyPlayerinfo = false

	if (data.steamid == debugPlayerInfo) then
		dbug("end API_Playerinfo", true)
	end
end


function readAPI_AdminList()
	local file, ln, result, data, index, count, temp, level, steam, con, q
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/adminList.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	flagAdminsForRemoval()
	staffList = {}
	file = io.open(homedir .. "/temp/adminList.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)
		data = splitCRLF(result.result)
		count = table.maxn(data)

		for con, q in pairs(conQueue) do
			if q.command == "admin list" then
				irc_chat(q.ircUser, data[1])
				irc_chat(q.ircUser, data[2])
			end
		end

		for index=3, count-1, 1 do
			temp = string.split(data[index], ":")
			temp[1] = string.trim(temp[1])
			temp[2] = string.trim(temp[2])
			level = tonumber(temp[1])
			steam = string.trim(string.sub(temp[2], 1, 18))

			if level == 0 then
				owners[steam] = {}
				owners[steam].remove = false
				staffList[steam] = {}
			end

			if level == 1 then
				admins[steam] = {}
				admins[steam].remove = false
				staffList[steam] = {}
			end

			if level == 2 then
				mods[steam] = {}
				mods[steam].remove = false
				staffList[steam] = {}
			end

			if players[steam] then
				players[steam].accessLevel = tonumber(level)
				players[steam].newPlayer = false
				players[steam].silentBob = false
				players[steam].walkies = false
				players[steam].timeout = false
				players[steam].prisoner = false
				players[steam].exiled = 2
				players[steam].canTeleport = true
				players[steam].enableTP = true
				players[steam].botHelp = true
				players[steam].hackerScore = 0
				players[steam].testAsPlayer = nil

				if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, silentBob = 0, walkies = 0, exiled = 2, canTeleport = 1, enableTP = 1, botHelp = 1, accessLevel = " .. level .. " WHERE steam = " .. steam) end
				if botman.dbConnected then conn:execute("INSERT INTO staff (steam, adminLevel) VALUES (" .. steam .. "," .. level .. ")") end

				if players[steam].botTimeout and igplayers[steam] then
					gmsg(server.commandPrefix .. "return " .. v.name)
				end
			end

			for con, q in pairs(conQueue) do
				if q.command == "admin list" then
					irc_chat(q.ircUser, data[index])
				end
			end
		end
	end

	file:close()
	removeOldStaff()

	for con, q in pairs(conQueue) do
		if q.command == "admin list" then
			conQueue[con] = nil
		end
	end
end


function readAPI_BanList()
	local file, ln, result, data, k, v, temp, con, q
	local bannedTo, steam, reason
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/banList.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/banList.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)
		data = splitCRLF(result.result)

		for k,v in pairs(data) do
			if k > 2 and v ~= "" then
				if v ~= "" then
					temp = string.split(v, " - ")

					bannedTo = string.trim(temp[3] .. " " .. temp[4])
					steam = string.trim(temp[6])
					reason = ""

					if temp[8] then
						reason = string.trim(temp[8])
					end

					if botman.dbConnected then
						conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. bannedTo .. "'," .. steam .. ",'" .. escape(reason) .. "',STR_TO_DATE('" .. bannedTo .. "', '%Y-%m-%d %H:%i:%s'))")
					end

					for con, q in pairs(conQueue) do
						if q.command == "ban list" then
							irc_chat(q.ircUser, data[k])
						end
					end
				end
			else
				for con, q in pairs(conQueue) do
					if q.command == "ban list" then
						irc_chat(q.ircUser, data[k])
					end
				end
			end
		end

	end

	file:close()

	for con, q in pairs(conQueue) do
		if q.command == "ban list" then
			conQueue[con] = nil
		end
	end
end


function readAPI_BCGo()
	local file, ln, result, data, k, v, a, b
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/bc-go.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/bc-go.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)

		-- This JSON data has nested JSON data that also needs to be converted to a Lua table
		data = yajl.to_value(result.result)

		for k,v in pairs(data) do
			if v ~= "" then
				for a,b in pairs(v) do
					if ircListItems ~= nil then
						if ircListItemsFilter ~= "" then
							if string.find(string.lower(b), ircListItemsFilter, nil, true) then
								irc_chat(players[ircListItems].ircAlias, b)
							end
						else
							irc_chat(players[ircListItems].ircAlias, b)
						end
					end
				end
			end
		end
	end

	file:close()
	ircListItems = nil
	ircListItemsFilter = nil
end


function readAPI_BCTime()
	local file, ln, result, data
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/bc-time.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/bc-time.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)
		-- This JSON data has nested JSON data that also needs to be converted to a Lua table
		result = yajl.to_value(result.result)

		server.uptime = math.floor(result.Ticks)
		server.playersOnline = tonumber(result.Players)
	end

	file:close()
end


function readAPI_Command()
	local file, ln, result, curr, totalPlayersOnline, temp, data, k, v, getData
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/command.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/command.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)

		for con, q in pairs(conQueue) do
			if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
				if string.find(result.result, "\n") then
					data = splitCRLF(result.result)

					for k,v in pairs(data) do
						irc_chat(q.ircUser, data[k])
					end
				else
					irc_chat(q.ircUser, result.result)
				end
			end
		end

		if string.find(result.command, "admin") and not string.find(result.command, "list") then
			tempTimer( 2, [[sendCommand("admin list")]] )
		end

		if string.sub(result.result, 1, 4) == "Day " then
			gameTimeTrigger(stripMatching(result.result, "\\r\\n"))
			gameTimeTrigger(stripMatching(result.result, "\\n"))
			file:close()
			return
		end

		if string.sub(result.command, 1, 3) == "sg " then
			result.result = stripMatching(result.result, "\\r\\n")
			result.result = stripMatching(result.result, "\\n")
			matchAll(result.result)
			file:close()
			return
		end

		if result.parameters == "bot_RemoveInvalidItems" then
			removeInvalidItems()
			file:close()
			return
		end

		if string.find(result.parameters, "LagCheck") then
			matchAll("pm " .. result.parameters)
			file:close()
			return
		end
	end

	file:close()

	for con, q in pairs(conQueue) do
		if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			conQueue[con] = nil
		end
	end
end


function readAPI_GG()
	local file, ln, result, data, k, v, con, q
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/gg.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/gg.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)
		data = splitCRLF(result.result)

		botman.readGG = true

		for k,v in pairs(data) do
			for con, q in pairs(conQueue) do
				if q.command == "gg" then
					irc_chat(q.ircUser, data[k])
				end
			end

			if v ~= "" then
				matchAll(v)
			end
		end

		botman.readGG = false
	end

	file:close()

	for con, q in pairs(conQueue) do
		if q.command == "gg" then
			conQueue[con] = nil
		end
	end
end


function readAPI_Help()
	local file, ln, result, data, k, v, con, q
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/help.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/help.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)
		data = splitCRLF(result.result)

		for k,v in pairs(data) do
			for con, q in pairs(conQueue) do
				if string.find(q.command, "help") then
					irc_chat(q.ircUser, v)
				end
			end
		end
	end

	file:close()

	for con, q in pairs(conQueue) do
		if string.find(q.command, "help") then
			conQueue[con] = nil
		end
	end
end


function readAPI_Inventories()
	if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

	local file, ln, result, data, k, v, index, count, steam, playerName
	local slot, quantity, quality, itemName
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/inventories.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

	file = io.open(homedir .. "/temp/inventories.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)
		count = table.maxn(result)

		if debug then display(result) end

		for index=1, count, 1 do
			if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

			steam = result[index].steamid
			playerName = result[index].playername

			if (debug) then
				dbug("steam = " .. steam)
				dbug("playerName = " .. playerName)
			end

			if (igplayers[steam].inventoryLast ~= igplayers[steam].inventory) then
				igplayers[steam].inventoryLast = igplayers[steam].inventory
			end

			igplayers[steam].inventory = ""
			igplayers[steam].oldBelt = igplayers[steam].belt
			igplayers[steam].belt = ""
			igplayers[steam].pack = ""
			igplayers[steam].equipment = ""

			for k,v in pairs(result[index].belt) do
				if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

				if v ~= "" then
					slot = k

					if type(v) == "table" then
						quantity = v.count
						quality = v.quality
						itemName = v.name

						igplayers[steam].inventory = igplayers[steam].inventory .. quantity .. "," .. itemName .. "," .. quality .. "|"
						igplayers[steam].belt = igplayers[steam].belt .. slot .. "," .. quantity .. "," .. itemName .. "," .. quality .. "|"
					end
				end
			end

			for k,v in pairs(result[index].bag) do
				if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

				if v ~= "" then
					slot = k

					if type(v) == "table" then
						quantity = v.count
						quality = v.quality
						itemName = v.name

						igplayers[steam].inventory = igplayers[steam].inventory .. quantity .. "," .. itemName .. "," .. quality .. "|"
						igplayers[steam].pack = igplayers[steam].pack .. slot .. "," .. quantity .. "," .. itemName .. "," .. quality .. "|"
					end
				end
			end

			for k,v in pairs(result[index].equipment) do
				if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

				if v ~= "" then
					slot = k

					if type(v) == "table" then
						quality = v.quality
						itemName = v.name
						igplayers[steam].equipment = igplayers[steam].equipment .. slot .. "," .. itemName .. "," .. quality .. "|"
					end
				end
			end

			if debug then
				dbug("belt = " .. igplayers[steam].belt)
				dbug("bag = " .. igplayers[steam].pack)
				dbug("inventory = " .. igplayers[steam].equipment)
			end
		end
	end

	file:close()

	for con, q in pairs(conQueue) do
		if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			conQueue[con] = nil
		end
	end

	if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

	CheckInventory()
end


function readAPI_Hostiles()
	local file, ln, result, temp, data, k, v, cursor, errorString
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/hostiles.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/hostiles.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)

		for k,v in pairs(result) do
			if v ~= "" then
				loc = inLocation(v.position.x, v.position.z)

				if loc ~= false then
					if locations[loc].killZombies then
						if not server.lagged then
							sendCommand("removeentity " .. v.id)
						end
					end
				end
			end
		end
	end

	file:close()
end


function readAPI_LE()
--TODO:  Not finished
	local file, ln, result, temp, data, k, v, entityID, entity, cursor, errorString,  con, q
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/le.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/le.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)

		for con, q in pairs(conQueue) do
			if q.command == result.command then
				if string.find(result.result, "\n") then
					data = splitCRLF(result.result)

					for k,v in pairs(data) do
						irc_chat(q.ircUser, data[k])
					end
				else
					irc_chat(q.ircUser, result.result)
				end
			end
		end

	end

	file:close()

	for con, q in pairs(conQueue) do
		if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			conQueue[con] = nil
		end
	end
end


function readAPI_LKP()
	local file, ln, result, temp, data, k, v, cursor, errorString
	local name, gameID, steamID, IP, playtime, seen, p1, p2
	local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+)"
	local runyear, runmonth, runday, runhour, runminute, seenTimestamp, tmp
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/lkp.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/lkp.txt", "r")

	--	first flag everyone except staff as notInLKP.  We will remove that flag as we find them in LKP.
	for k,v in pairs(players) do
		if tonumber(v.accessLevel) > 3 then
			v.notInLKP = true
		else
			v.notInLKP = false
		end
	end

	for ln in file:lines() do
		result = yajl.to_value(ln)
		data = splitCRLF(result.result)

		for k,v in pairs(data) do
			if v ~= "" then
				-- gather the data for the current player
				temp = string.split(v, ", ")
				p1, p2 = string.find(temp[1], ". ")
				name = string.sub(temp[1], p2+1)
				gameID = string.match(temp[2], "=(-?%d+)")
				steamID = string.match(temp[3], "=(-?%d+)")

				p1, p2 = string.find(temp[5], "ip=")
				IP = string.sub(temp[5], p2+1)

				p1, p2 = string.find(temp[6], "playtime=")
				playtime = string.match(string.sub(temp[6], p2+1), "(-?%d+) ")

				p1, p2 = string.find(temp[7], "seen=")
				seen = string.sub(temp[7], p2+1)

				-- skip if no valid gameID
				if tonumber(gameID) > 0 then
					-- skip archived players
					if not playersArchived[steamID] then
						tmp = {}
						tmp.runyear, tmp.runmonth, tmp.runday, tmp.runhour, tmp.runminute = seen:match(pattern)
						seenTimestamp = os.time({year = tmp.runyear, month = tmp.runmonth, day = tmp.runday, hour = tmp.runhour, min = tmp.runminute, 0})

						-- initially skip ingame players as this section is for archiving players we haven't seen for months
						if not igplayers[steamID] then
							-- make sure the player record exists so we can add missing players and archive them in one pass
							if not players[steamID] then
								players[steamID] = {}

								if gameID ~= "-1" then
									players[steamID].id = gameID
								end

								players[steamID].name = name
								players[steamID].steam = steamID
								players[steamID].playtime = playtime
								players[steamID].seen = seen

								if botman.dbConnected then conn:execute("INSERT INTO players (steam, id, name, playtime, seen) VALUES (" .. steamID .. "," .. gameID .. ",'" .. escape(name) .. "'," .. playtime .. ",'" .. seen .. "') ON DUPLICATE KEY UPDATE playtime = " .. playtime .. ", seen = '" .. seen .. "'") end
							else
								-- update the player record since it already exists
								if gameID ~= "-1" then
									players[steamID].id = gameID
								end

								players[steamID].name = name
								players[steamID].playtime = playtime
								players[steamID].seen = seen
								players[steamID].notInLKP = false

								if botman.dbConnected then conn:execute("INSERT INTO players (steam, id, name, playtime, seen) VALUES (" .. steamID .. "," .. gameID .. ",'" .. escape(name) .. "'," .. playtime .. ",'" .. seen .. "') ON DUPLICATE KEY UPDATE playtime = " .. playtime .. ", seen = '" .. seen .. "', name = '" .. escape(name) .. "', id = " .. gameID) end
							end

							-- add missing fields and give them default values
							fixMissingPlayer(steamID)

							-- don't archive if we have already archived players today.  This is mainly to prevent the bot being tied up every time someone commands it to run lkp.
							if os.time() - server.playersLastArchived > 86400 then
								if tonumber(server.archivePlayersLastSeenDays) > 0 then
									-- acrchive players that haven't played in 60 days and aren't an admin
									if ((os.time() - seenTimestamp) > 86400 * server.archivePlayersLastSeenDays or seen == "0001-01-01 00:00") and (accessLevel(steamID) > 3) then
										conn:execute("INSERT INTO playersArchived SELECT * from players WHERE steam = " .. steamID)
										conn:execute("DELETE FROM players WHERE steam = " .. steamID)
										players[steamID] = nil
										loadPlayersArchived(steamID)
									end
								end
							end
						else
							players[steamID].notInLKP = false
						end
					end
				end
			end
		end

		if os.time() - server.playersLastArchived > 86400 then
			server.playersLastArchived = os.time()
			conn:execute("UPDATE server SET playersLastArchived = current_timestamp")
		end
	end

	file:close()

	--	Everyone except staff who is still flagged notInLKP gets archived as well.
	for k,v in pairs(players) do
		if tonumber(v.accessLevel) > 3 and v.notInLKP then
			conn:execute("INSERT INTO playersArchived SELECT * from players WHERE steam = " .. k)
			conn:execute("DELETE FROM players WHERE steam = " .. k)
			players[k] = nil
			loadPlayersArchived(k)
		end
	end
end


function readAPI_LI()
	local file, ln, result, temp, data, k, v, entityID, entity, cursor, errorString, con, q
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/li.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/li.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)

		for con, q in pairs(conQueue) do
			if string.sub(q.command, 1, 3) == "li " then
				if string.find(result.result, "\n") then
					data = splitCRLF(result.result)

					for k,v in pairs(data) do
						irc_chat(q.ircUser, data[k])
					end
				else
					irc_chat(q.ircUser, result.result)
				end
			end
		end
	end

	file:close()

	for con, q in pairs(conQueue) do
		if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			conQueue[con] = nil
		end
	end
end


function readAPI_LLP()
	local file, ln, result, temp, coords, data, k, v, a, b, cursor, errorString, con, q
	local steam, x, y, z, keystoneCount, region, loc, reset, noPlayer
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/llp.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	conn:execute("DELETE FROM keystones WHERE x = 0 AND y = 0 AND z = 0")

	file = io.open(homedir .. "/temp/llp.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)

		for con, q in pairs(conQueue) do
			if string.find(q.command, result.command) then
				if string.find(result.result, "\n") then
					data = splitCRLF(result.result)

					for k,v in pairs(data) do
						irc_chat(q.ircUser, data[k])
					end
				else
					irc_chat(q.ircUser, result.result)
				end
			end
		end

		data = splitCRLF(result.result)

		for k,v in pairs(data) do
			if v ~= "" then
				temp = splitCRLF(v)

				for a,b in pairs(temp) do
					if string.find(b, "Player ") then
						steam = string.sub(b, 9, string.find(b, ')\"') - 1)
						steam = string.sub(steam, - 17)
						players[steam].claimsExpired = not string.find(b, ": True,") -- it's Opposite Day!
						noPlayer = false

						if not players[steam] then
							noPlayer = true
						else
							if players[steam].removedClaims == nil then
								players[steam].removedClaims = 0
							end
						end
					end

					if string.find(b, "owns ") and string.find(b, " keystones") then
						keystoneCount = string.sub(b, string.find(b, "owns ") + 5, string.find(b, " keystones") - 1)
						if not noPlayer then
							players[steam].keystones = keystoneCount
						end
					end

					if string.find(b, "location") then
						b = string.sub(b, string.find(b, "location") + 9)

						coords = string.split(b, ",")
						x = tonumber(coords[1])
						y = tonumber(coords[2])
						z = tonumber(coords[3])

						if tonumber(y) > 0 then
							if botman.dbConnected then
								conn:execute("UPDATE keystones SET removed = 0 WHERE steam = " .. steam .. " AND x = " .. x .. " AND y = " .. y .. " AND z = " .. z)
							end

							if not keystones[x .. y .. z] then
								keystones[x .. y .. z] = {}
								keystones[x .. y .. z].x = x
								keystones[x .. y .. z].y = y
								keystones[x .. y .. z].z = z
								keystones[x .. y .. z].steam = steam
							end

							keystones[x .. y .. z].expired = players[steam].claimsExpired
							keystones[x .. y .. z].removed = 0

							if players[steam].removeClaims then
								keystones[x .. y .. z].remove = true
							else
								keystones[x .. y .. z].remove = false
							end

							if accessLevel(steam) > 2 then
								region = getRegion(x, z)
								loc, reset = inLocation(x, z)

								if not noPlayer then
									if (resetRegions[region] or reset or players[steam].removeClaims) and not players[steam].testAsPlayer then
										if botman.dbConnected then conn:execute("INSERT INTO keystones (steam, x, y, z, remove, removed, expired) VALUES (" .. steam .. "," .. x .. "," .. y .. "," .. z .. ", 1, 0," .. dbBool(players[steam].claimsExpired) .. ") ON DUPLICATE KEY UPDATE remove = 1, removed = 0, expired = " .. dbBool(players[steam].claimsExpired)) end
									else
										if botman.dbConnected then conn:execute("INSERT INTO keystones (steam, x, y, z, expired) VALUES (" .. steam .. "," .. x .. "," .. y .. "," .. z .. "," .. dbBool(players[steam].claimsExpired) .. ")") end
									end
								end
							else
								if botman.dbConnected then conn:execute("INSERT INTO keystones (steam, x, y, z, expired) VALUES (" .. steam .. "," .. x .. "," .. y .. "," .. z .. "," .. dbBool(players[steam].claimsExpired) .. ")") end
							end
						end
					end
				end
			end
		end
	end

	file:close()

	for con, q in pairs(conQueue) do
		if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			conQueue[con] = nil
		end
	end
end


function readAPI_LPB()
	local file, ln, result, data, k, v, temp, pid, con, q
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/lpb.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/lpb.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)
		data = splitCRLF(result.result)

		for k,v in pairs(data) do
			for con, q in pairs(conQueue) do
				if string.sub(q.command, 1, 3) == "lpb" then
					irc_chat(q.ircUser, data[k])
				end
			end

			if v ~= "" then
				if not string.find(v, "The player") then
					temp = string.split(data, ": ")
					pid = temp[1]
					temp = string.split(temp[2], ", ")

					players[pid].bedX = temp[1]
					players[pid].bedY = temp[2]
					players[pid].bedZ = temp[3]
					if botman.dbConnected then conn:execute("UPDATE players SET bedX = " .. temp[1] .. ", bedY = " .. temp[2] .. ", bedZ = " .. temp[3].. " WHERE steam = " .. pid) end
				else
					pid = string.sub(v, 11, string.find(v, " does ") - 1)
					players[pid].bedX = 0
					players[pid].bedY = 0
					players[pid].bedZ = 0
					if botman.dbConnected then conn:execute("UPDATE players SET bedX = 0, bedY = 0, bedZ = 0 WHERE steam = " .. pid) end
				end
			end
		end

	end

	file:close()

	for con, q in pairs(conQueue) do
		if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			conQueue[con] = nil
		end
	end
end


function readAPI_LPF()
	local file, ln, result, data, k, v, con, q
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/lpf.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/lpf.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)
		data = splitCRLF(result.result)

		for k,v in pairs(data) do
			for con, q in pairs(conQueue) do
				if string.sub(q.command, 1, 3) == "lpf" then
					irc_chat(q.ircUser, data[k])
				end
			end

			if not string.find(v, "Player") and v ~= "" then
				getFriends(v)
			end
		end
	end

	file:close()

	for con, q in pairs(conQueue) do
		if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			conQueue[con] = nil
		end
	end
end


function readAPI_PlayersOnline()
	local file, ln, result, index, totalPlayersOnline, con, q
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/playersOnline.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/playersOnline.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)

		botman.playersOnline = table.maxn(result)

		for index=1, botman.playersOnline, 1 do
			API_PlayerInfo(result[index])

			for con, q in pairs(conQueue) do
				if q.command == "lp" then
					irc_chat(q.ircUser, data[k])
				end
			end
		end
	end

	file:close()

	for con, q in pairs(conQueue) do
		if q.command == "lp" then
			conQueue[con] = nil
		end
	end
end


function readAPI_PGD()
	local file, ln, result, data, k, v
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/pgd.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/pgd.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)
		data = splitCRLF(result.result)

		for k,v in pairs(data) do
			if v ~= "" then
				matchAll(v)
			end
		end

	end

	file:close()
end


function readAPI_PUG()
	local file, ln, result, data, k, v
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/pug.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/pug.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)
		data = splitCRLF(result.result)

		for k,v in pairs(data) do
			if v ~= "" then
				matchAll(v)
			end
		end

	end

	file:close()
end


function readAPI_ReadLog()
-- this works but knowing what the current log line number on the server is is critical or this is a waste of time.
	local file, ln, result, temp, data, k, v
	local uptime, date, time, msg

	file = io.open(homedir .. "/temp/log.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)

		botman.lastLogLine = result.lastLine

		for k,v in pairs(result.entries) do
			uptime = v.uptime
			date = v.date
			time = v.time
			msg = v.msg

			matchAll(msg, date, time)
		end
	end

--	server.serverTime = date .. " " .. string.sub(time, 1, 5)
--	server.uptime = math.floor(time * 60)
	file:close()
end


function readAPI_SE()
	local file, ln, result, temp, data, k, v, getData, entityID, entity, cursor, errorString
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/se.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/se.txt", "r")
	getData = false

	for ln in file:lines() do
		result = yajl.to_value(ln)
		data = splitCRLF(result.result)

		for k,v in pairs(data) do
			for con, q in pairs(conQueue) do
				if q.command == "se" then
					irc_chat(q.ircUser, data[k])
				end
			end

			if (string.find(v, "please specify one of the entities")) then
				-- flag all the zombies for removal so we can detect deleted zeds
				if botman.dbConnected then
					conn:execute("UPDATE gimmeZombies SET remove = 1")
					conn:execute("UPDATE otherEntities SET remove = 1")
				end

				getData = true
			else
				if getData then
					if v ~= "" then
						temp = string.split(v, "-")

						entityID = string.trim(temp[1])
						entity = string.trim(temp[2])

						if string.find(v, "ombie") then
							if botman.dbConnected then conn:execute("INSERT INTO gimmeZombies (zombie, entityID) VALUES ('" .. entity .. "'," .. entityID .. ") ON DUPLICATE KEY UPDATE remove = 0") end
							updateGimmeZombies(entityID, entity)
						else
							if botman.dbConnected then conn:execute("INSERT INTO otherEntities (entity, entityID) VALUES ('" .. entity .. "'," .. entityID .. ") ON DUPLICATE KEY UPDATE remove = 0") end
							updateOtherEntities(entityID, entity)
						end
					end
				end
			end
		end

		if botman.dbConnected then conn:execute("DELETE FROM gimmeZombies WHERE remove = 1") end
		loadGimmeZombies()

		if botman.dbConnected then conn:execute("DELETE FROM otherEntities WHERE remove = 1") end
		loadOtherEntities()

		if botman.dbConnected then
			cursor,errorString = conn:execute("SELECT Count(entityID) as maxZeds from gimmeZombies")
			row = cursor:fetch({}, "a")
			botman.maxGimmeZombies = tonumber(row.maxZeds)
		end
	end

	file:close()

	for con, q in pairs(conQueue) do
		if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			conQueue[con] = nil
		end
	end
end


function readAPI_MEM()
	local file, ln, result, data, con, q
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/mem.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	file = io.open(homedir .. "/temp/mem.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)

		for con, q in pairs(conQueue) do
			if q.command == result.command then
				if string.find(result.result, "\n") then
					data = splitCRLF(result.result)

					for k,v in pairs(data) do
						irc_chat(q.ircUser, data[k])
					end
				else
					irc_chat(q.ircUser, result.result)
				end
			end
		end

		data = stripMatching(result.result, "\\r\\n")
		data = stripMatching(result.result, "\\n")
		memTrigger(data)
	end

	file:close()

	for con, q in pairs(conQueue) do
		if q.command == result.command then
			conQueue[con] = nil
		end
	end
end


function readAPI_Version()
	local file, ln, result, data, k, v, con, q
	local fileSize

	fileSize = lfs.attributes (homedir .. "/temp/installedMods.txt", "size")

	-- abort if the file is empty
	if fileSize == nil or fileSize == 0 then
		return
	end

	modVersions = {}
	server.alloc = false
	server.coppi = false
	server.stompy = false
	server.SDXDetected = false
	server.ServerToolsDetected = false

	if botman.dbConnected then
		conn:execute("UPDATE server SET SDXDetected = 0, ServerToolsDetected = 0")
	end

	file = io.open(homedir .. "/temp/installedMods.txt", "r")

	for ln in file:lines() do
		result = yajl.to_value(ln)
		data = splitCRLF(result.result)

		for k,v in pairs(data) do
			for con, q in pairs(conQueue) do
				if q.command == "version" then
					irc_chat(q.ircUser, data[k])
				end
			end

			if v ~= "" then
				matchAll(v)
			end
		end

	end

	file:close()

	for con, q in pairs(conQueue) do
		if q.command == "version" then
			conQueue[con] = nil
		end
	end
end
