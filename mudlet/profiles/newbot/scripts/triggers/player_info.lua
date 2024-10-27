--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function playerInfo(lpdata)
	-- EDIT THIS FUNCTION WITH CARE.  This function is central to player management.  Some lines need to be run before others.
	-- Lua will stop execution wherever it strikes a fault (usually trying to use a non-existing variable)
	-- enable debugging to see roughly where the bot gets to.  It should reach 'end playerinfo'.
	-- Good luck :)

	local tmp = {}

	-- faultyPlayerinfo = true
	-- faultyPlayerinfoID = 0
	-- faultyPlayerinfoLine = line

	local debug, chunkX, chunkZ, exile, prison
	local steamtest, admin, lastGimme, lastLogin, playerAccessLevel, temp, settings
	local outsideMap, mapCenterDistance, regionX, regionZ
	local fields, values, flag, cmd, k, v, key
	local timestamp = os.time()
	local region = ""
	local resetZone = false
	local dist, hotspot, currentLocation
	local skipTPtest = false

	debug = false -- should be false unless testing

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if customPlayerInfo ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customPlayerInfo then
			if customPlayerInfo(line) then
				return true, "custom playerInfo"
			end
		end
	end

	if not lpdata.userID then
		lpdata.steam, lpdata.steamOwner, lpdata.userID, lpdata.platform = LookupPlayer(lpdata.steam)
	end

	if lpdata.userID == "" then
		lpdata.steam, lpdata.steamOwner, lpdata.userID, lpdata.platform = LookupPlayer(lpdata.steam)
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if server.kickXBox and lpdata.platform == "XBL" and not botman.botDisabled then
		kick(lpdata.userID, "This server does not allow connections from XBox.")
		irc_chat(server.ircAlerts, server.gameDate .. " player " .. lpdata.userID .. " kicked because XBox players are not allowed to play here " .. lpdata.platform .. "_" .. lpdata.steam)
		return true, "xbox player kicked"
	end

	exile = LookupLocation("exile")
	prison = LookupLocation("prison")

	flag = ""

	region = getRegion(lpdata.x, lpdata.z)
	regionX, regionZ, chunkX, chunkZ = getRegionChunkXZ(lpdata.x, lpdata.z)

	if (resetRegions[region]) then
		resetZone = true
	else
		resetZone = false
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if lpdata.userID == "" then
		lpdata.userID = LookupJoiningPlayer(lpdata.steam)
	end

	-- add to in-game players table
	if (not igplayers[lpdata.steam]) then
		igplayers[lpdata.steam] = {}
		igplayers[lpdata.steam].id = lpdata.entityid
		igplayers[lpdata.steam].name = lpdata.name
		igplayers[lpdata.steam].steam = lpdata.steam
		igplayers[lpdata.steam].steamOwner = lpdata.steam
		igplayers[lpdata.steam].userID = lpdata.userID
		igplayers[lpdata.steam].platform = lpdata.platform

		fixMissingIGPlayer(lpdata.platform, lpdata.steam, lpdata.steam, lpdata.userID)
	end

	if igplayers[lpdata.steam].readCounter == nil then
		igplayers[lpdata.steam].readCounter = 0
	else
		igplayers[lpdata.steam].readCounter = igplayers[lpdata.steam].readCounter + 1
	end

	if igplayers[lpdata.steam].checkNewPlayer == nil then
		fixMissingIGPlayer(lpdata.platform, lpdata.steam, lpdata.steam, lpdata.userID)
	end

	-- if player is missing from player lua table, try to load them from the databases.
	if not players[lpdata.steam] then
		-- try to load them from the sqlite database
		restoreSQLitePlayer(lpdata.steam)

		-- still missing?  try to load them from the players table in mysql
		if not players[lpdata.steam] then
			loadPlayers(lpdata.steam)
		end

		-- If the player record is still missing we make a new record below (and hope for the best)
	end

	-- add to players table
	if not players[lpdata.steam] then
		players[lpdata.steam] = {}
		players[lpdata.steam].id = lpdata.entityid
		players[lpdata.steam].name = lpdata.name
		players[lpdata.steam].steam = lpdata.steam
		players[lpdata.steam].steamOwner = lpdata.steam
		players[lpdata.steam].userID = lpdata.userID

		if tonumber(lpdata.score) == 0 and tonumber(lpdata.zombiekills) == 0 and tonumber(lpdata.playerdeaths) == 0 then
			players[lpdata.steam].newPlayer = true
		else
			players[lpdata.steam].newPlayer = false
		end

		players[lpdata.steam].watchPlayer = true
		players[lpdata.steam].watchPlayerTimer = os.time() + 2419200 -- stop watching in one month or until no longer a new player
		players[lpdata.steam].ip = lpdata.ip
		players[lpdata.steam].exiled = false

		irc_chat(server.ircMain, "###  New player joined " .. player .. " userID: " .. lpdata.userID .. " platform: " .. lpdata.platform .. " steam: " .. lpdata.steam .. " id: " .. lpdata.entityid .. " ###")
		irc_chat(server.ircAlerts, "New player joined " .. server.gameDate .. " " .. line:gsub("%,", ""))

		if botman.dbConnected then
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. lpdata.x .. "," .. lpdata.y .. "," .. lpdata.z .. ",'" .. botman.serverTime .. "','new player','New player joined (player info) " .. lpdata.name .. " steam: " .. lpdata.steam.. " id: " .. lpdata.entityid .. "','" .. lpdata.steam .. "')")
			conn:execute("INSERT INTO players (steam, lpdata.name, id, IP, newPlayer, watchPlayer, watchPlayerTimer) VALUES ('" .. lpdata.steam .. "','" .. escape(lpdata.name) .. "'," .. lpdata.entityid .. ",'" .. lpdata.ip .. "',1,1, " .. os.time() + 2419200 .. ")")
		end

		fixMissingPlayer(lpdata.platform, lpdata.steam, lpdata.steam, lpdata.userID)

		-- don't initially warn the player about pvp or pve zone.  Too many players complain about it when the bot is restarted.  We can warn them next time their zone changes.
		if pvpZone(lpdata.x, lpdata.z) then
			if players[lpdata.steam].alertPVP == true then
				players[lpdata.steam].alertPVP = false
			end
		else
			if players[lpdata.steam].alertPVP == false then
				players[lpdata.steam].alertPVP = true
			end
		end

		if players[lpdata.steam].newPlayer then
			setGroupMembership(lpdata.steam, "New Players", true)
		else
			setGroupMembership(lpdata.steam, "New Players", false)
		end

		if not server.optOutGlobalBots then
			CheckBlacklist(lpdata.steam, lpdata.ip)
		end
	else
		if not players[lpdata.steam].country then
			players[lpdata.steam].country = ""
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	settings = getSettings(lpdata.steam)

	if igplayers[lpdata.steam].greet then
		if tonumber(igplayers[lpdata.steam].greetdelay) > 0 then
			igplayers[lpdata.steam].greetdelay = igplayers[lpdata.steam].greetdelay -1
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if tonumber(lpdata.ping) > 0 then
		igplayers[lpdata.steam].ping = lpdata.ping
		players[lpdata.steam].ping = lpdata.ping
	else
		igplayers[lpdata.steam].ping = 0
		players[lpdata.steam].ping = 0
	end

	if not igplayers[lpdata.steam].xPosLast then
		-- this shouldn't be missing so give it the player's current position
		igplayers[lpdata.steam].xPosLast = lpdata.x
		igplayers[lpdata.steam].yPosLast = lpdata.y
		igplayers[lpdata.steam].zPosLast = lpdata.z
	end

	playerAccessLevel = tonumber(accessLevel(lpdata.steam, lpdata.userID))

	if isAdminHidden(lpdata.steam, lpdata.userID) then
		-- admins don't hack (no lie) ^^
		players[lpdata.steam].hackerScore = 0
		admin = true
	else
		admin = false
	end

	if lpdata.ip ~= "" and players[lpdata.steam].ip == "" then
		players[lpdata.steam].ip = lpdata.ip

		if not server.optOutGlobalBots then
			CheckBlacklist(lpdata.steam, lpdata.ip)
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- ping kick
	if not whitelist[lpdata.steam] and not isDonor(lpdata.steam) and not admin then
		if (server.pingKickTarget == "new" and players[lpdata.steam].newPlayer) or server.pingKickTarget == "all" then
			if tonumber(lpdata.ping) < tonumber(server.pingKick) and tonumber(server.pingKick) > 0 then
				igplayers[lpdata.steam].highPingCount = tonumber(igplayers[lpdata.steam].highPingCount) - 1
				if tonumber(igplayers[lpdata.steam].highPingCount) < 0 then igplayers[lpdata.steam].highPingCount = 0 end
			end

			if tonumber(lpdata.ping) > tonumber(server.pingKick) and tonumber(server.pingKick) > 0 then
				igplayers[lpdata.steam].highPingCount = tonumber(igplayers[lpdata.steam].highPingCount) + 1

				if tonumber(igplayers[lpdata.steam].highPingCount) > 15 then
					irc_chat(server.ircMain, "Kicked " .. lpdata.name .. " steam: " .. lpdata.steam.. " for high ping " .. lpdata.ping)
					kick(lpdata.steam, "High ping kicked.")
					return true, "high ping kicked"
				end
			end
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if tonumber(lpdata.y) > 0 and tonumber(lpdata.y) < 500 then
		igplayers[lpdata.steam].lastTP = nil
		forgetLastTP(lpdata.steam)
	end

	if players[lpdata.steam].location ~= "" and igplayers[lpdata.steam].spawnedInWorld and not botman.botDisabled then
		igplayers[lpdata.steam].teleCooldown = 0

		-- spawn the player at location
		if (locations[players[lpdata.steam].location]) then
			temp = players[lpdata.steam].location
			irc_chat(server.ircMain, "Player " .. lpdata.steam .. " " .. lpdata.name .. " is being moved to " .. temp)
			irc_chat(server.ircAlerts, "Player " .. lpdata.steam .. " " .. lpdata.name .. " is being moved to " .. temp)
			players[lpdata.steam].location = ""
			if botman.dbConnected then conn:execute("UPDATE players SET location = '' WHERE steam = '" .. lpdata.steam .. "'") end

			message(string.format("pm %s [%s]You are being moved to %s[-]", lpdata.userID, server.chatColour, temp))
			randomTP(lpdata.steam, lpdata.userID, temp, true)
		end

		if (players[lpdata.steam].location == "return player") then
			if players[lpdata.steam].xPosTimeout ~= 0 and players[lpdata.steam].zPosTimeout ~= 0 then
				cmd = "tele " .. lpdata.userID .. " " .. players[lpdata.steam].xPosTimeout .. " " .. players[lpdata.steam].yPosTimeout .. " " .. players[lpdata.steam].zPosTimeout
				players[lpdata.steam].xPosTimeout = 0
				players[lpdata.steam].yPosTimeout = 0
				players[lpdata.steam].zPosTimeout = 0
			else
				cmd = "tele " .. lpdata.userID .. " " .. players[lpdata.steam].xPosOld .. " " .. players[lpdata.steam].yPosOld .. " " .. players[lpdata.steam].zPosOld
			end

			players[lpdata.steam].location = ""
			if botman.dbConnected then conn:execute("UPDATE players SET location = '' WHERE steam = '" .. lpdata.steam .. "'") end
			teleport(cmd, lpdata.steam, lpdata.userID)
		end
	end

	if botman.botDisabled then
		players[lpdata.steam].location = ""
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if not botman.botDisabled then
		if tonumber(players[lpdata.steam].hackerScore) >= 10000 then
			players[lpdata.steam].hackerScore = 0

			if igplayers[lpdata.steam].hackerDetection ~= nil then
				message(string.format("say [%s]Banning %s. Hacking suspected. Evidence: " .. igplayers[lpdata.steam].hackerDetection .. "[-]", server.chatColour, players[lpdata.steam].name))
			else
				message(string.format("say [%s]Banning %s. Detected possible evidence of hacking.[-]", server.chatColour, players[lpdata.steam].name))
			end

			banPlayer(lpdata.platform, lpdata.userID, lpdata.steam, "1 year", "Automatic ban for suspected hacking. Admins have been alerted.", "")

			-- if the player has any pending global bans, activate them
			connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = '" .. lpdata.steam .. "'")
		else
			if tonumber(players[lpdata.steam].hackerScore) >= 49  then
				-- if the player has pending global bans recorded against them, we ban them early and also activate the global ban
				if tonumber(players[lpdata.steam].pendingBans) > 0 then
					players[lpdata.steam].hackerScore = 0
					if igplayers[lpdata.steam].hackerDetection ~= nil then
						message(string.format("say [%s]Temp banning %s. May be hacking. Detected " .. igplayers[lpdata.steam].hackerDetection .. "[-]", server.chatColour, players[lpdata.steam].name))
					else
						message(string.format("say [%s]Temp banning %s 1 week. Detected clipping or flying too much. Admins have been alerted.[-]", server.chatColour, players[lpdata.steam].name))
					end

					banPlayer(lpdata.platform, lpdata.userID, lpdata.steam, "1 week", "Automatic ban for suspected hacking. Admins have been alerted.", "")

					-- activate the pending bans
					connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = '" .. lpdata.steam .. "'")
				end
			end

			if tonumber(igplayers[lpdata.steam].flyCount) > 2 and not admin then
				players[lpdata.steam].hackerScore = 0
				if igplayers[lpdata.steam].hackerDetection ~= nil then
					message(string.format("say [%s]Temp banning %s 1 week for suspected hacking. Detected " .. igplayers[lpdata.steam].hackerDetection .. "[-]", server.chatColour, players[lpdata.steam].name))
				else
					message(string.format("say [%s]Temp banning %s 1 week for suspected hacking.[-]", server.chatColour, players[lpdata.steam].name))
				end

				banPlayer(lpdata.platform, lpdata.userID, lpdata.steam, "1 week", "Automatic ban for suspected hacking. Admins have been alerted.", "")

				-- if the player has any pending global bans, activate them
				if botman.botsConnected then
					connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = '" .. lpdata.steam .. "'")
				end
			end

		if tonumber(igplayers[lpdata.steam].flyCount) > 2 and not admin then
			players[lpdata.steam].hackerScore = 0
			if igplayers[lpdata.steam].hackerDetection ~= nil then
				message(string.format("say [%s]Temp banning %s 1 week for suspected hacking. Detected " .. igplayers[lpdata.steam].hackerDetection .. "[-]", server.chatColour, players[lpdata.steam].name))
			else
				message(string.format("say [%s]Temp banning %s 1 week for suspected hacking.[-]", server.chatColour, players[lpdata.steam].name))
			end

				banPlayer(lpdata.platform, lpdata.userID, lpdata.steam, "1 week", "Automatic ban for suspected hacking. Admins have been alerted.", "")

				-- if the player has any pending global bans, activate them
				connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = '" .. lpdata.steam .. "'")
			end
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- test for hackers teleporting
	if not botman.botDisabled then
		if server.hackerTPDetection and igplayers[lpdata.steam].spawnChecked == false and not igplayers[lpdata.steam].spawnPending then
			igplayers[lpdata.steam].spawnChecked = true

			-- ignore tele spawns for 10 seconds after the last legit tp to allow for lag and extra tp commands on delayed tp servers.
			if (os.time() - igplayers[lpdata.steam].lastTPTimestamp > 10) and (igplayers[lpdata.steam].spawnedCoordsOld ~= igplayers[lpdata.steam].spawnedCoords)then
				if not (players[lpdata.steam].timeout or players[lpdata.steam].botTimeout or players[lpdata.steam].ignorePlayer) then
					if tonumber(lpdata.x) ~= 0 and tonumber(lpdata.z) ~= 0 and tonumber(igplayers[lpdata.steam].xPos) ~= 0 and tonumber(igplayers[lpdata.steam].zPos) ~= 0 then
						dist = 0

						if igplayers[lpdata.steam].spawnedInWorld and igplayers[lpdata.steam].spawnedReason == "teleport" and igplayers[lpdata.steam].spawnedCoordsOld ~= "0 0 0" then
							dist = distancexz(lpdata.x, lpdata.z, igplayers[lpdata.steam].xPos, igplayers[lpdata.steam].zPos)
						end

						if (tonumber(dist) >= 900) then
							if tonumber(igplayers[lpdata.steam].tp) < 1 then
								if players[lpdata.steam].newPlayer == true then
									new = " [FF8C40]NEW player "
								else
									new = " [FF8C40]Player "
								end

								if not admin then
									irc_chat(server.ircMain, botman.serverTime .. " Player " .. lpdata.entityid .. " " .. lpdata.steam .. " name: " .. lpdata.name .. " detected teleporting to " .. lpdata.x .. " " .. lpdata.y .. " " .. lpdata.z .. " distance " .. string.format("%-8.2d", dist))
									irc_chat(server.ircAlerts, server.gameDate .. " player " .. lpdata.entityid .. " " .. lpdata.steam .. " name: " .. lpdata.name .. " detected teleporting to " .. lpdata.x .. " " .. lpdata.y .. " " .. lpdata.z .. " distance " .. string.format("%-8.2d", dist))

									igplayers[lpdata.steam].hackerTPScore = tonumber(igplayers[lpdata.steam].hackerTPScore) + 1
									players[lpdata.steam].watchPlayer = true
									players[lpdata.steam].watchPlayerTimer = os.time() + 259200 -- watch for 3 days
									if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + 259200 .. " WHERE steam = '" .. lpdata.steam .. "'") end

									if players[lpdata.steam].exiled == true or players[lpdata.steam].newPlayer then
										igplayers[lpdata.steam].hackerTPScore = tonumber(igplayers[lpdata.steam].hackerTPScore) + 1
									end

									if tonumber(igplayers[lpdata.steam].hackerTPScore) > 0 and players[lpdata.steam].newPlayer and tonumber(players[lpdata.steam].ping) > 180 then
										if locations[exile] and not players[lpdata.steam].prisoner then
											players[lpdata.steam].exiled = true
										else
											igplayers[lpdata.steam].hackerTPScore = tonumber(igplayers[lpdata.steam].hackerTPScore) + 1
										end
									end

									if tonumber(igplayers[lpdata.steam].hackerTPScore) > 1 then
										igplayers[lpdata.steam].hackerTPScore = 0
										igplayers[lpdata.steam].tp = 0
										message(string.format("say [%s]Temp banning %s 1 week for unexplained teleporting. An admin will investigate the circumstances.[-]", server.chatColour, players[lpdata.steam].name))
										banPlayer(lpdata.platform, lpdata.userID, lpdata.steam, "1 week", "We detected unusual teleporting from you and are investigating the circumstances.", "")

										-- if the player has any pending global bans, activate them
										connBots:execute("UPDATE bans set GBLBanActive = 1 WHERE GBLBan = 1 AND steam = '" .. lpdata.steam .. "'")
									end

									alertAdmins(lpdata.entityid .. " name: " .. lpdata.name .. " detected teleporting! In fly mode, type " .. server.commandPrefix .. "near " .. lpdata.entityid .. " to shadow them.", "warn")
								end
							end

							igplayers[lpdata.steam].tp = 0
						else
							igplayers[lpdata.steam].tp = 0
						end
					end
				end
			end

			igplayers[lpdata.steam].spawnChecked = true
			igplayers[lpdata.steam].spawnedCoordsOld = igplayers[lpdata.steam].spawnedCoords
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	igplayers[lpdata.steam].lastLP = os.time()

	players[lpdata.steam].id = lpdata.entityid
	players[lpdata.steam].userID = lpdata.userID
	players[lpdata.steam].name = lpdata.name
	players[lpdata.steam].steamOwner = igplayers[lpdata.steam].steamOwner
	igplayers[lpdata.steam].id = lpdata.entityid
	igplayers[lpdata.steam].name = lpdata.name
	igplayers[lpdata.steam].steam = lpdata.steam
	igplayers[lpdata.steam].userID = lpdata.userID

	if igplayers[lpdata.steam].deaths ~= nil then
		if tonumber(igplayers[lpdata.steam].deaths) < tonumber(lpdata.playerdeaths) then
			if tonumber(igplayers[lpdata.steam].yPosLast) > 0 then
				players[lpdata.steam].deathX = igplayers[lpdata.steam].xPosLast
				players[lpdata.steam].deathY = igplayers[lpdata.steam].yPosLast
				players[lpdata.steam].deathZ = igplayers[lpdata.steam].zPosLast

				igplayers[lpdata.steam].deadX = igplayers[lpdata.steam].xPosLast
				igplayers[lpdata.steam].deadY = igplayers[lpdata.steam].yPosLast
				igplayers[lpdata.steam].deadZ = igplayers[lpdata.steam].zPosLast
				igplayers[lpdata.steam].teleCooldown = 1000

				--irc_chat(server.ircMain, "Player " .. lpdata.steam .. " name: " .. lpdata.name .. "'s death recorded at " .. igplayers[lpdata.steam].deadX .. " " .. igplayers[lpdata.steam].deadY .. " " .. igplayers[lpdata.steam].deadZ)
				irc_chat(server.ircAlerts, server.gameDate .. " player " .. lpdata.steam .. " name: " .. lpdata.name .. "'s death recorded at " .. igplayers[lpdata.steam].deadX .. " " .. igplayers[lpdata.steam].deadY .. " " .. igplayers[lpdata.steam].deadZ)

				if not server.beQuietBot then
					-- r = randSQL(14)
					-- if (r == 1) then message("say [" .. server.chatColour .. "]" .. lpdata.name .. " removed themselves from the gene pool.[-]") end
					-- if (r == 2) then message("say [" .. server.chatColour .. "]LOL!  Didn't run far away enough did you " .. lpdata.name .. "?[-]") end
					-- if (r == 3) then message("say [" .. server.chatColour .. "]And the prize for most creative way to end themselves goes to.. " .. lpdata.name .. "[-]") end
					-- if (r == 4) then message("say [" .. server.chatColour .. "]" .. lpdata.name .. " really shouldn't handle explosives.[-]") end
					-- if (r == 5) then message("say Oh no! " .. lpdata.name .. " died.  What a shame.[-]") end
					-- if (r == 6) then message("say [" .. server.chatColour .. "]Great effort there " .. lpdata.name .. ". I'm awarding " .. randSQL(10) .. " points.[-]") end
					-- if (r == 7) then message("say [" .. server.chatColour .. "]LOL! REKT[-]") end

					-- if (r == 8) then
						-- message("say [" .. server.chatColour .. "]We are gathered here today to remember with sadness the passing of " .. lpdata.name .. ". Rest in pieces. Amen.[-]")
					-- end

					-- if (r == 9) then message("say [" .. server.chatColour .. "]" .. lpdata.name .. " cut the wrong wire.[-]") end
					-- if (r == 10) then message("say [" .. server.chatColour .. "]" .. lpdata.name .. " really showed that explosive who's boss![-]") end
					-- if (r == 11) then message("say [" .. server.chatColour .. "]" .. lpdata.name .. " shouldn't play Russian Roulette with a fully loaded gun.[-]") end
					-- if (r == 12) then message("say [" .. server.chatColour .. "]" .. lpdata.name .. " added a new stain to the floor.[-]") end
					-- if (r == 13) then message("say [" .. server.chatColour .. "]ISIS got nothing on " .. lpdata.name .. "'s suicide bomber skillz.[-]") end
					-- if (r == 14) then message("say [" .. server.chatColour .. "]" .. lpdata.name .. " reached a new low with that death. Six feet under.[-]") end
				end

				players[lpdata.steam].packCooldown = os.time() + settings.packCooldown
			end
		end
	end

	igplayers[lpdata.steam].xPosLast = igplayers[lpdata.steam].xPos
	igplayers[lpdata.steam].yPosLast = igplayers[lpdata.steam].yPos
	igplayers[lpdata.steam].zPosLast = igplayers[lpdata.steam].zPos
	igplayers[lpdata.steam].xPos = lpdata.x
	igplayers[lpdata.steam].yPos = lpdata.y
	igplayers[lpdata.steam].zPos = lpdata.z

	-- also add intX etc to prevent bad code breaking because it can't find it
	igplayers[lpdata.steam].intX = lpdata.x
	igplayers[lpdata.steam].intY = lpdata.y
	igplayers[lpdata.steam].intZ = lpdata.z

	igplayers[lpdata.steam].playerKills = lpdata.playerkills
	igplayers[lpdata.steam].deaths = lpdata.playerdeaths
	igplayers[lpdata.steam].zombies = lpdata.zombiekills
	igplayers[lpdata.steam].score = lpdata.score

	if igplayers[lpdata.steam].oldLevel == nil then
		igplayers[lpdata.steam].oldLevel = lpdata.level
	end

	-- hacker detection
	if tonumber(igplayers[lpdata.steam].oldLevel) ~= -1 and not botman.botDisabled then
		if tonumber(lpdata.level) - tonumber(igplayers[lpdata.steam].oldLevel) > 50 and not admin and server.alertLevelHack then
			alertAdmins(lpdata.entityid .. " name: " .. lpdata.name .. " detected possible level hacking!  Old level was " .. igplayers[lpdata.steam].oldLevel .. " new level is " .. lpdata.level .. " an increase of " .. tonumber(lpdata.level) - tonumber(igplayers[lpdata.steam].oldLevel), "alert")
			irc_chat(server.ircAlerts, server.gameDate .. " " .. lpdata.steam .. " name: " .. lpdata.name .. " detected possible level hacking!  Old level was " .. igplayers[lpdata.steam].oldLevel .. " new level is " .. lpdata.level .. " an increase of " .. tonumber(lpdata.level) - tonumber(igplayers[lpdata.steam].oldLevel))
		end

		if server.checkLevelHack then
			if tonumber(lpdata.level) - tonumber(igplayers[lpdata.steam].oldLevel) > 50 and not admin then
				players[lpdata.steam].hackerScore = 10000
				igplayers[lpdata.steam].hackerDetection = "Suspected level hack. (" .. lpdata.level .. ") an increase of " .. tonumber(lpdata.level) - tonumber(igplayers[lpdata.steam].oldLevel)
			end
		end
	end

	players[lpdata.steam].level = lpdata.level
	igplayers[lpdata.steam].level = lpdata.level
	igplayers[lpdata.steam].oldLevel = lpdata.level
	igplayers[lpdata.steam].killTimer = 0 -- to help us detect a player that has disconnected unnoticed
	igplayers[lpdata.steam].raiding = false
	igplayers[lpdata.steam].regionX = regionX
	igplayers[lpdata.steam].regionZ = regionZ
	igplayers[lpdata.steam].chunkX = chunkX
	igplayers[lpdata.steam].chunkZ = chunkZ

	if pvpZone(lpdata.x, lpdata.z) then
		igplayers[lpdata.steam].currentLocationPVP = true
	else
		igplayers[lpdata.steam].currentLocationPVP = false
	end

	if (igplayers[lpdata.steam].xPosLast == nil) then
		igplayers[lpdata.steam].xPosLast = lpdata.x
		igplayers[lpdata.steam].yPosLast = lpdata.y
		igplayers[lpdata.steam].zPosLast = lpdata.z
		igplayers[lpdata.steam].xPosLastOK = lpdata.x
		igplayers[lpdata.steam].yPosLastOK = lpdata.y
		igplayers[lpdata.steam].zPosLastOK = lpdata.z
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	atHome(lpdata.steam)
	currentLocation = inLocation(lpdata.x, lpdata.z)

	if currentLocation ~= false then
		igplayers[lpdata.steam].currentLocationPVP = locations[currentLocation].pvp
		igplayers[lpdata.steam].inLocation = currentLocation
		players[lpdata.steam].inLocation = currentLocation

		resetZone = locations[currentLocation].resetZone

		if locations[currentLocation].killZombies then
			server.scanZombies = true
		end
	else
		players[lpdata.steam].inLocation = ""
		igplayers[lpdata.steam].inLocation = ""
	end

	if server.showLocationMessages and not botman.botDisabled then
		if igplayers[lpdata.steam].alertLocation ~= currentLocation and currentLocation ~= false then
			if (locations[currentLocation].public) or admin then
				message(string.format("pm %s [%s]Welcome to %s[-]", lpdata.userID, server.chatColour, currentLocation))
			end
		end
	end

	if currentLocation == false then
		if server.showLocationMessages and not botman.botDisabled then
			if igplayers[lpdata.steam].alertLocation ~= "" then
				if not locations[igplayers[lpdata.steam].alertLocation] then
					igplayers[lpdata.steam].alertLocation = ""
				else
					if locations[igplayers[lpdata.steam].alertLocation].public or admin then
						message(string.format("pm %s [%s]You have left %s[-]", lpdata.userID, server.chatColour, igplayers[lpdata.steam].alertLocation))
					end
				end
			end
		end

		igplayers[lpdata.steam].alertLocation = ""
	else
		igplayers[lpdata.steam].alertLocation = currentLocation
	end

	-- fix weird cash bug
	if tonumber(players[lpdata.steam].cash) < 0 then
		players[lpdata.steam].cash = 0
	end

	-- convert zombie kills to cash
	if (tonumber(igplayers[lpdata.steam].zombies) > tonumber(players[lpdata.steam].zombies)) and (math.abs(igplayers[lpdata.steam].zombies - players[lpdata.steam].zombies) < 20) then
		if server.allowBank then
			players[lpdata.steam].cash = tonumber(players[lpdata.steam].cash) + math.abs(igplayers[lpdata.steam].zombies - players[lpdata.steam].zombies) * settings.zombieKillReward

			if (players[lpdata.steam].watchCash) and not botman.botDisabled then
				message(string.format("pm %s [%s]+%s %s $%s in the bank[-]", lpdata.userID, server.chatColour, math.abs(igplayers[lpdata.steam].zombies - players[lpdata.steam].zombies) * settings.zombieKillReward, server.moneyPlural, string.format("%d", players[lpdata.steam].cash)))
			end
		end

		if igplayers[lpdata.steam].doge and not botman.botDisabled then
			dogePhrase = dogeWOW() .. " " .. dogeWOW() .. " "

			r = randSQL(10)
			if r == 1 then dogePhrase = dogePhrase .. "WOW" end
			if r == 3 then dogePhrase = dogePhrase .. "Excite" end
			if r == 5 then dogePhrase = dogePhrase .. "Amaze" end
			if r == 7 then dogePhrase = dogePhrase .. "OMG" end
			if r == 9 then dogePhrase = dogePhrase .. "Respect" end

			message(string.format("pm %s [%s]" .. dogePhrase .. "[-]", lpdata.userID, server.chatColour))
		end

		if server.allowBank then
			-- update the lottery prize pool
			server.lottery = server.lottery + (math.abs(igplayers[lpdata.steam].zombies - players[lpdata.steam].zombies) * settings.lotteryMultiplier)
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- update player record of zombies
	players[lpdata.steam].zombies = igplayers[lpdata.steam].zombies

	if tonumber(players[lpdata.steam].playerKills) < tonumber(lpdata.playerkills) then
		players[lpdata.steam].playerKills = lpdata.playerkills
	end

	if tonumber(players[lpdata.steam].deaths) < tonumber(lpdata.playerdeaths) then
		players[lpdata.steam].deaths = lpdata.playerdeaths
	end

	if tonumber(players[lpdata.steam].score) < tonumber(lpdata.score) then
		players[lpdata.steam].score = lpdata.score
	end

	players[lpdata.steam].xPos = lpdata.x
	players[lpdata.steam].yPos = lpdata.y
	players[lpdata.steam].zPos = lpdata.z

	mapCenterDistance = distancexz(lpdata.x,lpdata.z,0,0)
	outsideMap = squareDistance(lpdata.x, lpdata.z, settings.mapSize)

	if (players[lpdata.steam].alertReset == nil) then
		players[lpdata.steam].alertReset = true
	end

	if (igplayers[lpdata.steam].greet) and not botman.botDisabled then
		if tonumber(igplayers[lpdata.steam].greetdelay) == 0 then
			igplayers[lpdata.steam].greet = false

			if not server.noGreetingMessages then
				if server.welcome ~= nil and server.welcome ~= "" then
					message(string.format("pm %s [%s]%s[-]", lpdata.userID, server.chatColour, server.welcome))
				else
					message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]Welcome to " .. server.serverName .. "!  Type " .. server.commandPrefix .. "info, " .. server.commandPrefix .. "rules or " .. server.commandPrefix .. "help for commands.[-]")
					message(string.format("pm %s [%s]We have a server manager bot called %s[-]", lpdata.userID, server.chatColour, server.botName))
				end

				if (tonumber(igplayers[lpdata.steam].zombies) ~= 0) then
					if isDonor(lpdata.steam) then
						welcome = "pm " .. lpdata.userID .. " [" .. server.chatColour .. "]Welcome back " .. lpdata.name .. "! Thanks for supporting us. =D[-]"
					else
						welcome = "pm " .. lpdata.userID .. " [" .. server.chatColour .. "]Welcome back " .. lpdata.name .. "![-]"
					end

					if (string.find(botman.serverTime, "02-14", 5, 10)) then welcome = "pm " .. lpdata.userID .. " [" .. server.chatColour .. "]Happy Valentines Day " .. lpdata.name .. "! ^^[-]" end

					message(welcome)
				else
					message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]Welcome " .. lpdata.name .. "![-]")
				end

				if (players[lpdata.steam].timeout == true) then
					message("pm " .. lpdata.userID .. " [" .. server.warnColour .. "]You are in timeout, not glitched or lagged.  You will stay here until released by an admin.[-]")
				end

				if (botman.scheduledRestart) then
					message("pm " .. lpdata.userID .. " [" .. server.alertColour .. "]<!>[-][" .. server.warnColour .. "] SERVER WILL REBOOT SHORTLY [-][" .. server.alertColour .. "]<!>[-]")
				end

				if server.MOTD ~= "" then
					if botman.dbConnected then connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','" .. lpdata.steam .. "','" .. connMEM:escape("[" .. server.chatColour .. "]" .. server.MOTD .. "[-]") .. "')") end
					tempTimer(1, [[ botman.messageQueueEmpty = false  ]])
				end

				if tonumber(players[lpdata.steam].removedClaims) > 0 then
					if botman.dbConnected then connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','" .. lpdata.steam .. "','" .. connMEM:escape("[" .. server.chatColour .. "]I am holding " .. players[lpdata.steam].removedClaims .. " land claim blocks for you. Type " .. server.commandPrefix .. "give claims to receive them.[-]") .. "')") end
					tempTimer(1, [[ botman.messageQueueEmpty = false  ]])
				end

				if botman.dbConnected then
					cursor,errorString = connSQL:execute("SELECT count(*) FROM mail WHERE recipient = '" .. lpdata.steam .. "' AND status = 0")
					rowSQL = cursor:fetch({}, "a")
					rowCount = rowSQL["count(*)"]

					if tonumber(rowCount) > 0 then
						if botman.dbConnected then connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','" .. lpdata.steam .. "','" .. connMEM:escape("[" .. server.chatColour .. "]NEW MAIL HAS ARRIVED!  Type " .. server.commandPrefix .. "read mail to read it now or " .. server.commandPrefix .. "help mail for more options.[-]") .. "')") end
						tempTimer(1, [[ botman.messageQueueEmpty = false  ]])
					end
				end

				if players[lpdata.steam].newPlayer == true and server.rules ~= "" then
					if botman.dbConnected then connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','" .. lpdata.steam .. "','" .. connMEM:escape("[" .. server.chatColour .. "]" .. server.rules .."[-]") .. "')") end
					tempTimer(1, [[ botman.messageQueueEmpty = false  ]])
				end

				if server.warnBotReset == true and playerAccessLevel == 0 then
					if botman.dbConnected then
						connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','" .. lpdata.steam .. "','" .. connMEM:escape("[" .. server.chatColour .. "]ALERT!  It appears that the server has been reset.[-]") .. "')")
						connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','" .. lpdata.steam .. "','" .. connMEM:escape("[" .. server.chatColour .. "]To reset me type " .. server.commandPrefix .. "reset bot.[-]") .. "')")
						connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','" .. lpdata.steam .. "','" .. connMEM:escape("[" .. server.chatColour .. "]To dismiss this alert type " .. server.commandPrefix .. "no reset.[-]") .. "')")
						tempTimer(1, [[ botman.messageQueueEmpty = false  ]])
					end
				end

				if (not players[lpdata.steam].santa) and specialDay == "christmas" then
					if botman.dbConnected then connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','" .. lpdata.steam .. "','" .. connMEM:escape("[" .. server.chatColour .. "]HO HO HO! Merry Christmas!  Type " .. server.commandPrefix .. "santa to open your Christmas stocking![-]") .. "')") end
					tempTimer(1, [[ botman.messageQueueEmpty = false  ]])
				end
			else
				if (players[lpdata.steam].timeout == true) then
					message("pm " .. lpdata.userID .. " [" .. server.warnColour .. "]You are in timeout, not glitched or lagged.  You will stay here until released by an admin.[-]")
				end

				if botman.dbConnected then
					cursor,errorString = connSQL:execute("SELECT count(*) FROM mail WHERE recipient = '" .. lpdata.steam .. "' AND status = 0")
					rowSQL = cursor:fetch({}, "a")
					rowCount = rowSQL["count(*)"]

					if tonumber(rowCount) > 0 then
						if botman.dbConnected then connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','" .. lpdata.steam .. "','" .. connMEM:escape("[" .. server.chatColour .. "]NEW MAIL HAS ARRIVED!  Type " .. server.commandPrefix .. "read mail to read it now or " .. server.commandPrefix .. "help mail for more options.[-]") .. "')") end
						tempTimer(1, [[ botman.messageQueueEmpty = false  ]])
					end
				end

				if (botman.scheduledRestart) then
					message("pm " .. lpdata.userID .. " [" .. server.alertColour .. "]<!>[-][" .. server.warnColour .. "] SERVER WILL REBOOT SHORTLY [-][" .. server.alertColour .. "]<!>[-]")
				end
			end

			-- run commands from the connectQueue now that the player has spawned and hopefully paying attention to chat
			tempTimer( 3, [[processConnectQueue("]].. lpdata.steam .. [[")]] )
			-- also check for removed claims
			tempTimer(10, [[CheckClaimsRemoved("]] .. lpdata.steam .. [[")]] )
		end
	end

	if botman.botDisabled then
		igplayers[lpdata.steam].greet = false
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if igplayers[lpdata.steam].alertLocation == "" and currentLocation ~= false and not botman.botDisabled then
		if botman.dbConnected then connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','" .. lpdata.steam .. "','" .. connMEM:escape("[" .. server.chatColour .. "]Welcome to " .. currentLocation .. "[-]") .. "')") end
		tempTimer(1, [[ botman.messageQueueEmpty = false  ]])
		igplayers[lpdata.steam].alertLocation = currentLocation
	end


	if tonumber(igplayers[lpdata.steam].teleCooldown) > 0 then
		igplayers[lpdata.steam].teleCooldown = tonumber(igplayers[lpdata.steam].teleCooldown) - 1
	end

	igplayers[lpdata.steam].sessionPlaytime = os.time() - igplayers[lpdata.steam].sessionStart

	if players[lpdata.steam].newPlayer == true then
		if (igplayers[lpdata.steam].sessionPlaytime + players[lpdata.steam].timeOnServer > (server.newPlayerTimer * 60) or tonumber(lpdata.level) > tonumber(server.newPlayerMaxLevel)) then
			players[lpdata.steam].newPlayer = false
			players[lpdata.steam].watchPlayer = false
			players[lpdata.steam].watchPlayerTimer = 0

			if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = '" .. lpdata.steam .. "'") end

			if string.upper(players[lpdata.steam].chatColour) == "FFFFFF" then
				setChatColour(lpdata.steam, players[lpdata.steam].accessLevel)
			end

			setGroupMembership(lpdata.steam, "New Players", false)
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- if we are following a player and they move more than 50 meters away, teleport us close to them.
	if igplayers[lpdata.steam].following ~= nil and not botman.botDisabled then
		if igplayers[igplayers[lpdata.steam].following] and players[igplayers[lpdata.steam].following].timeout == false and players[igplayers[lpdata.steam].following].botTimeout == false then
			followDistance = 50
			if igplayers[lpdata.steam].followDistance ~= nil then followDistance = tonumber(igplayers[lpdata.steam].followDistance) end

			dist = distancexz(igplayers[lpdata.steam].xPos, igplayers[lpdata.steam].zPos, igplayers[igplayers[lpdata.steam].following].xPos, igplayers[igplayers[lpdata.steam].following].zPos)
			if tonumber(dist) > followDistance and tonumber(igplayers[igplayers[lpdata.steam].following].yPos) > 0 then
				-- teleport close to the player
				igplayers[lpdata.steam].tp = 1
				igplayers[lpdata.steam].hackerTPScore = 0
				sendCommand("tele " .. lpdata.userID .. " " .. igplayers[igplayers[lpdata.steam].following].xPos .. " " .. igplayers[igplayers[lpdata.steam].following].yPos - 30 .. " " .. igplayers[igplayers[lpdata.steam].following].zPos)
			end
		end
	end

	if (igplayers[lpdata.steam].alertLocationExit ~= nil) and not botman.botDisabled then
		dist = distancexz(igplayers[lpdata.steam].xPos, igplayers[lpdata.steam].zPos, locations[igplayers[lpdata.steam].alertLocationExit].x, locations[igplayers[lpdata.steam].alertLocationExit].z)
		size = tonumber(locations[igplayers[lpdata.steam].alertLocationExit].size)

		if (tonumber(dist) > tonumber(locations[igplayers[lpdata.steam].alertLocationExit].size) + 100) then
			igplayers[lpdata.steam].alertLocationExit = nil

			message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]You have moved too far away from the location. If you still wish to do " .. server.commandPrefix .. "protect location, please start again.[-]")
		end

		if (tonumber(dist) > tonumber(locations[igplayers[lpdata.steam].alertLocationExit].size) + 10) and (tonumber(dist) <  tonumber(locations[igplayers[lpdata.steam].alertLocationExit].size) + 30) then
			locations[igplayers[lpdata.steam].alertLocationExit].exitX = lpdata.x
			locations[igplayers[lpdata.steam].alertLocationExit].exitY = lpdata.y
			locations[igplayers[lpdata.steam].alertLocationExit].exitZ = lpdata.z
			locations[igplayers[lpdata.steam].alertLocationExit].protected = true

			if botman.dbConnected then conn:execute("UPDATE locations SET exitX = " .. lpdata.x .. ", exitY = " .. lpdata.y .. ", exitZ = " .. lpdata.z .. ", protected = 1 WHERE name = '" .. escape(igplayers[lpdata.steam].alertLocationExit) .. "'") end
			message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]You have enabled protection for " .. igplayers[lpdata.steam].alertLocationExit .. ".[-]")

			igplayers[lpdata.steam].alertLocationExit = nil
		end
	end

	if (igplayers[lpdata.steam].alertVillageExit ~= nil) and not botman.botDisabled then
		dist = distancexz(igplayers[lpdata.steam].xPos, igplayers[lpdata.steam].zPos, locations[igplayers[lpdata.steam].alertVillageExit].x, locations[igplayers[lpdata.steam].alertVillageExit].z)
		size = tonumber(locations[igplayers[lpdata.steam].alertVillageExit].size)

		if (tonumber(dist) > tonumber(locations[igplayers[lpdata.steam].alertVillageExit].size) + 100) then
			igplayers[lpdata.steam].alertVillageExit = nil

			message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]You have moved too far away from " .. igplayers[lpdata.steam].alertVillageExit .. ". Return to " .. igplayers[lpdata.steam].alertVillageExit .. " and type " .. server.commandPrefix .. "protect village " .. igplayers[lpdata.steam].alertVillageExit .. " again.[-]")
		end

		if (tonumber(dist) >  tonumber(locations[igplayers[lpdata.steam].alertVillageExit].size) + 20) and (tonumber(dist) <  tonumber(locations[igplayers[lpdata.steam].alertVillageExit].size) + 100) then
			locations[igplayers[lpdata.steam].alertVillageExit].exitX = lpdata.x
			locations[igplayers[lpdata.steam].alertVillageExit].exitY = lpdata.y
			locations[igplayers[lpdata.steam].alertVillageExit].exitZ = lpdata.z
			locations[igplayers[lpdata.steam].alertVillageExit].protected = true

			if botman.dbConnected then conn:execute("UPDATE locations SET exitX = " .. lpdata.x .. ", exitY = " .. lpdata.y .. ", exitZ = " .. lpdata.z .. ", protected = 1 WHERE name = '" .. escape(igplayers[lpdata.steam].alertVillageExit) .. "'") end
			message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]You have enabled protection for " .. igplayers[lpdata.steam].alertVillageExit .. "[-]")

			igplayers[lpdata.steam].alertVillageExit = nil
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if (igplayers[lpdata.steam].alertBaseExit) and not botman.botDisabled then
		tmp.key = igplayers[lpdata.steam].alertBaseKey
		tmp.dist = distancexz(lpdata.x, lpdata.z, bases[tmp.key].x, bases[tmp.key].z)
		tmp.size = tonumber(bases[tmp.key].size)

		if (tonumber(tmp.dist) > 200) then
			igplayers[lpdata.steam].alertBaseExit = nil
			igplayers[lpdata.steam].alertBaseKey = nil

			message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]You have moved too far away from the base. If you still wish to do " .. server.commandPrefix .. "protect, please start again.[-]")
		end

		if (tonumber(tmp.dist) > tmp.size + 15) and (tonumber(tmp.dist) < tmp.size + 50) then
			bases[tmp.key].exitX = lpdata.x
			bases[tmp.key].exitY = lpdata.y + 1
			bases[tmp.key].exitZ = lpdata.z
			bases[tmp.key].protect = true
			if botman.dbConnected then conn:execute("UPDATE bases SET protect = 1 WHERE steam = '" .. bases[tmp.key].steam .. "' and baseNumber = " .. bases[tmp.key].baseNumber) end


			if (admin and lpdata.steam ~= bases[tmp.key].steam) then
				message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]You have set an exit teleport for " .. players[bases[tmp.key].steam].name .. "'s base.[-]")
			else
				message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]You have set an exit teleport for your base.  You can test it with " .. server.commandPrefix .. "test base.[-]")
			end

			igplayers[lpdata.steam].alertBaseExit = nil
			igplayers[lpdata.steam].alertBaseKey = nil
		end
	end

	x = math.floor(igplayers[lpdata.steam].xPos / 512)
	z = math.floor(igplayers[lpdata.steam].zPos / 512)

	if admin and server.enableRegionPM and not botman.botDisabled then
		if (igplayers[lpdata.steam].region ~= "r." .. x .. "." .. z .. ".7rg") then
			message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]Region " .. x .. "." .. z .. "[-]")
		end
	end

	igplayers[lpdata.steam].region = region
	igplayers[lpdata.steam].regionX = x
	igplayers[lpdata.steam].regionZ = z

	-- timeout
	if (players[lpdata.steam].timeout == true or players[lpdata.steam].botTimeout == true) and igplayers[lpdata.steam].spawnedInWorld and not botman.botDisabled then
		if (tonumber(lpdata.y) < 30000) then
			igplayers[lpdata.steam].tp = 1
			igplayers[lpdata.steam].hackerTPScore = 0
			sendCommand("tele " .. lpdata.userID .. " " .. lpdata.x .. " " .. 60000 .. " " .. lpdata.z)
		end

		return true, "player in timeout"
	end

	-- emergency return from timeout
	if (not players[lpdata.steam].timeout and not  players[lpdata.steam].botTimeout) and tonumber(lpdata.y) > 1000 and not admin then
		igplayers[lpdata.steam].tp = 1
		igplayers[lpdata.steam].hackerTPScore = 0

		if players[lpdata.steam].yPosTimeout == 0 then
			sendCommand("tele " .. lpdata.userID .. " " .. lpdata.x .. " -1 " .. lpdata.z)
		else
			sendCommand("tele " .. lpdata.userID .. " " .. players[lpdata.steam].xPosTimeout .. " " .. players[lpdata.steam].yPosTimeout .. " " .. players[lpdata.steam].zPosTimeout)
		end

		players[lpdata.steam].xPosTimeout = 0
		players[lpdata.steam].yPosTimeout = 0
		players[lpdata.steam].zPosTimeout = 0
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- add to tracker table
	dist = distancexyz(lpdata.x, lpdata.y, lpdata.z, igplayers[lpdata.steam].xPosLast, igplayers[lpdata.steam].yPosLast, igplayers[lpdata.steam].zPosLast)

	if tonumber(dist) > 2 and tonumber(lpdata.y) < 10000 then
		-- record the players position
		if igplayers[lpdata.steam].raiding then
			flag = flag .. "R"
		end

		if igplayers[lpdata.steam].illegalInventory then
			flag = flag .. "B"
		end

		if igplayers[lpdata.steam].flying or igplayers[lpdata.steam].noclip then
			flag = flag .. "F"
		end

		connTRAK:execute("INSERT INTO tracker (steam, timestamp, x, y, z, session, flag) VALUES ('" .. lpdata.steam .. "'," .. botman.serverTimeStamp .. "," .. lpdata.x .. "," .. lpdata.y .. "," .. lpdata.z .. "," .. players[lpdata.steam].sessionCount .. ",'" .. flag .. "')")

		if server.botLoggingLevel ~= 2 and tonumber(server.botLoggingLevel) < 4 then
			connTRAKSHADOW:execute("INSERT INTO tracker (steam, timestamp, x, y, z, session, flag) VALUES ('" .. lpdata.steam .. "'," .. botman.serverTimeStamp .. "," .. lpdata.x .. "," .. lpdata.y .. "," .. lpdata.z .. "," .. players[lpdata.steam].sessionCount .. ",'" .. flag .. "')")
		end

		if igplayers[lpdata.steam].location ~= nil then
			connSQL:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. igplayers[lpdata.steam].location .. "'," .. lpdata.x .. "," .. lpdata.y .. "," .. lpdata.z .. ")")
		end
	end

	-- prevent player exceeding the map limit unless they are an admin except when ignoreadmins is false
	if not isDestinationAllowed(lpdata.steam, lpdata.x, lpdata.z) and not botman.botDisabled then
		message("pm " .. lpdata.userID .. " [" .. server.warnColour .. "]This map is restricted to " .. (settings.mapSize / 1000) .. " km from the center.[-]")

		igplayers[lpdata.steam].tp = 1
		igplayers[lpdata.steam].hackerTPScore = 0

		if not isDestinationAllowed(lpdata.steam, igplayers[lpdata.steam].xPosLastOK, igplayers[lpdata.steam].zPosLastOK) then
			sendCommand("tele " .. lpdata.userID .. " 1 -1 0") -- if we don't know where to send the player, send them to the middle of the map. This should only happen rarely.
			message("pm " .. lpdata.userID .. " [" .. server.warnColour .. "]You have been moved to the center of the map.[-]")
		else
			sendCommand("tele " .. lpdata.userID .. " " .. igplayers[lpdata.steam].xPosLastOK .. " " .. igplayers[lpdata.steam].yPosLastOK .. " " .. igplayers[lpdata.steam].zPosLastOK)
		end

		return true, "player exceeded map limit"
	end

	if players[lpdata.steam].exiled == true and locations[exile] and not players[lpdata.steam].prisoner and not botman.botDisabled then
		if (distancexz( lpdata.x, lpdata.z, locations[exile].x, locations[exile].z ) > tonumber(locations[exile].size)) then
			randomTP(lpdata.steam, lpdata.userID, exile, true)
			return true, "player returned to exile"
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- left prison zone warning
	if (locations[prison]) and not botman.botDisabled then
		if (distancexz( lpdata.x, lpdata.z, locations[prison].x, locations[prison].z ) > tonumber(locations[prison].size)) then
			if (players[lpdata.steam].alertPrison == false) then
				players[lpdata.steam].alertPrison = true
			end
		end

		if (players[lpdata.steam].prisoner) then
			if (locations[prison]) then
				if (squareDistanceXZXZ(locations[prison].x, locations[prison].z, lpdata.x, lpdata.z, locations[prison].size)) then
					players[lpdata.steam].alertPrison = false
					randomTP(lpdata.steam, lpdata.userID, prison, true)
				end
			end

			return true, "prisoner tried to escape"
		end

		-- entered prison zone warning
		if (distancexz( lpdata.x, lpdata.z, locations[prison].x, locations[prison].z ) < tonumber(locations[prison].size)) then
			if (players[lpdata.steam].alertPrison == true) then
				if (not players[lpdata.steam].prisoner) and server.showLocationMessages then
					message("pm " .. lpdata.userID .. " [" .. server.warnColour .. "]You have entered the prison.  Continue at your own risk.[-]")
				end
				players[lpdata.steam].alertPrison = false
			end
		end
	end

	-- freeze!
	if (players[lpdata.steam].freeze == true) and not botman.botDisabled then
		dist = distancexz(lpdata.x, lpdata.z, players[lpdata.steam].prisonxPosOld, players[lpdata.steam].prisonzPosOld)

		if tonumber(dist) > 2 then
			igplayers[lpdata.steam].tp = 1
			igplayers[lpdata.steam].hackerTPScore = 0
			sendCommand("tele " .. lpdata.userID .. " " .. players[lpdata.steam].prisonxPosOld .. " " .. players[lpdata.steam].prisonyPosOld .. " " .. players[lpdata.steam].prisonzPosOld)
		end

		return true, "player not allowed to move"
	end

	-- remove player from location if the location is closed or their level is outside level restrictions
	if currentLocation ~= false and not botman.botDisabled then
		tmp = {}
		tmp.bootPlayer = false

		if not locations[currentLocation].open and not admin then
			tmp.bootPlayer = true
		end

		-- check player level restrictions on the location
		if (tonumber(locations[currentLocation].minimumLevel) > 0 or tonumber(locations[currentLocation].maximumLevel) > 0) and not admin then
			if tonumber(locations[currentLocation].minimumLevel) > 0 and tonumber(lpdata.level) < tonumber(locations[currentLocation].minimumLevel) then
				tmp.bootPlayer = true
			end

			if tonumber(locations[currentLocation].minimumLevel) > 0 and tonumber(locations[currentLocation].maximumLevel) > 0 and (tonumber(lpdata.level) < tonumber(locations[currentLocation].minimumLevel) or tonumber(lpdata.level) > tonumber(locations[currentLocation].maximumLevel)) then
				tmp.bootPlayer = true
			end

			if tonumber(locations[currentLocation].maximumLevel) > 0 and tonumber(lpdata.level) > tonumber(locations[currentLocation].maximumLevel) then
				tmp.bootPlayer = true
			end
		end

		-- check player access level restrictions on the location
		if tonumber(playerAccessLevel) > tonumber(locations[currentLocation].accessLevel) and not admin then
			tmp.bootPlayer = true
		end

		if tmp.bootPlayer then
			tmp = {}
			tmp.side = randSQL(4)
			tmp.offset = randSQL(50)

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

			tmp.cmd = "tele " .. lpdata.userID .. " " .. tmp.x .. " -1 " .. tmp.z
			teleport(tmp.cmd, lpdata.steam, lpdata.userID)
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- teleport lookup
	if (tonumber(igplayers[lpdata.steam].teleCooldown) < 1) and (players[lpdata.steam].prisoner == false) and not botman.botDisabled then
		tp = ""
		tp, match = LookupTeleport(lpdata.x, lpdata.y, lpdata.z)
		if (tp ~= nil and teleports[tp].active == true) then
			ownerid = LookupOfflinePlayer(teleports[tp].owner)
			if (players[lpdata.steam].walkies ~= true) then
				if (admin or (teleports[tp].owner == igplayers[lpdata.steam].steam or teleports[tp].public == true or isFriend(ownerid, lpdata.steam))) and teleports[tp].active then
					if match == 1 then
						-- check access level restrictions on the teleport
						if (tonumber(playerAccessLevel) >= tonumber(teleports[tp].maximumAccess) and tonumber(playerAccessLevel) <= tonumber(teleports[tp].minimumAccess)) or admin then
							if isDestinationAllowed(lpdata.steam, teleports[tp].dx, teleports[tp].dz) then
								igplayers[lpdata.steam].teleCooldown = 4
								cmd = "tele " .. lpdata.userID .. " " .. teleports[tp].dx .. " " .. teleports[tp].dy .. " " .. teleports[tp].dz
								teleport(cmd, lpdata.steam, lpdata.userID)

								return true, "player triggered teleport"
							end
						end
					end

					if match == 2 and teleports[tp].oneway == false then
						-- check access level restrictions on the teleport
						if (tonumber(playerAccessLevel) >= tonumber(teleports[tp].maximumAccess) and tonumber(playerAccessLevel) <= tonumber(teleports[tp].minimumAccess)) or admin then
							if isDestinationAllowed(lpdata.steam, teleports[tp].x, teleports[tp].z) then
								igplayers[lpdata.steam].teleCooldown = 4
								cmd = "tele " .. lpdata.userID .. " " .. teleports[tp].x .. " " .. teleports[tp].y .. " " .. teleports[tp].z
								teleport(cmd, lpdata.steam, lpdata.userID)

								return true, "player triggered teleport"
							end
						end
					end
				end
			end
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- linked waypoint lookup
	if tonumber(players[lpdata.steam].waypointCooldown) < os.time() then
		if (players[lpdata.steam].prisoner == false) and not botman.botDisabled then
			tmp = {}
			tmp.wpid = LookupWaypoint(lpdata.x, lpdata.y, lpdata.z)

			if tonumber(tmp.wpid) > 0 then
				tmp.linkedID = waypoints[tmp.wpid].linked

				if (waypoints[tmp.wpid].shared and isFriend(waypoints[tmp.wpid].steam, lpdata.steam) or waypoints[tmp.wpid].steam == lpdata.steam) and tonumber(tmp.linkedID) > 0 then
					-- reject if not an admin and player teleporting has been disabled
					if settings.allowTeleporting and not server.disableLinkedWaypoints then
						if isDestinationAllowed(lpdata.steam, waypoints[tmp.linkedID].x, waypoints[tmp.linkedID].z) then
							players[lpdata.steam].waypointCooldown = os.time() + 6
							cmd = "tele " .. lpdata.userID .. " " .. waypoints[tmp.linkedID].x .. " " .. waypoints[tmp.linkedID].y .. " " .. waypoints[tmp.linkedID].z
							teleport(cmd, lpdata.steam, lpdata.userID)

							return true, "player triggered waypoint"
						end
					else
						if admin then
							players[lpdata.steam].waypointCooldown = os.time() + 6
							cmd = "tele " .. lpdata.userID .. " " .. waypoints[tmp.linkedID].x .. " " .. waypoints[tmp.linkedID].y .. " " .. waypoints[tmp.linkedID].z
							teleport(cmd, lpdata.steam, lpdata.userID)

							return true, "player triggered waypoint"
						end
					end
				end
			end
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- left reset zone warning
	if (not resetZone) and not botman.botDisabled then
		if (players[lpdata.steam].alertReset == false) then
			message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]You are out of the reset zone.[-]")
			players[lpdata.steam].alertReset = true
		end
	end

	-- entered reset zone warning
	if (resetZone) and not botman.botDisabled then
		if (players[lpdata.steam].alertReset == true) then
			message("pm " .. lpdata.userID .. " [" .. server.warnColour .. "]You are in a reset zone. Don't build here.[-]")
			players[lpdata.steam].alertReset = false

			-- check for claims in the reset zone not owned by staff and remove them
			checkRegionClaims(x, z)
		end
	end

	if not botman.botDisabled then
		if baseProtection(lpdata.steam, lpdata.x, lpdata.y, lpdata.z) and not resetZone then
			return true, "player triggered protection"
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if (igplayers[lpdata.steam].deadX ~= nil) and igplayers[lpdata.steam].spawnedInWorld and igplayers[lpdata.steam].spawnedReason ~= "fake reason" then
		dist = math.abs(distancexz(igplayers[lpdata.steam].deadX, igplayers[lpdata.steam].deadZ, lpdata.x, lpdata.z))
		if tonumber(dist) > 2 then
			igplayers[lpdata.steam].deadX = nil
			igplayers[lpdata.steam].deadY = nil
			igplayers[lpdata.steam].deadZ = nil

			if not botman.botDisabled then
				if players[lpdata.steam].bed ~= "" then
					if tonumber(players[lpdata.steam].bedX) ~= 0 and tonumber(players[lpdata.steam].bedY) ~= 0 and tonumber(players[lpdata.steam].bedZ) ~= 0 then
						cmd = "tele " .. lpdata.userID .. " " .. players[lpdata.steam].bedX .. " " .. players[lpdata.steam].bedY .. " " .. players[lpdata.steam].bedZ
						teleport(cmd, lpdata.steam, lpdata.userID)
					end
				end
			end
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- hotspot lookup
	hotspot = LookupHotspot(lpdata.x, lpdata.y, lpdata.z)

	if (hotspot ~= nil) and not botman.botDisabled then
		tmp.skipHotspot = false

		if (igplayers[lpdata.steam].lastHotspot ~= hotspot) then
			for k, v in pairs(lastHotspots[lpdata.steam]) do
				if v == hotspot then -- don't add or display this hotspot yet.  we've seen it recently
					tmp.skipHotspot = true
				end
			end

			if not tmp.skipHotspot then
				igplayers[lpdata.steam].lastHotspot = hotspot
				message("pm " .. lpdata.userID .. " [" .. server.chatColour .. "]" .. hotspots[hotspot].hotspot .. "[-]")

				if (lastHotspots[lpdata.steam] == nil) then lastHotspots[lpdata.steam] = {} end
				if (tablelength(lastHotspots[lpdata.steam]) > 4) then
					table.remove(lastHotspots[lpdata.steam], 1)
				end

				table.insert(lastHotspots[lpdata.steam],  hotspot)
			end
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	if igplayers[lpdata.steam].rawPosition ~= lpdata.rawPosition then
		igplayers[lpdata.steam].afk = os.time() + tonumber(server.idleKickTimer)
		igplayers[lpdata.steam].rawPosition = lpdata.rawPosition
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline -- delete me
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end	 -- delete me

	if (tonumber(botman.playersOnline) >= tonumber(server.maxPlayers) or server.idleKickAnytime) and not admin and server.idleKick and not botman.botDisabled then
		if (igplayers[lpdata.steam].afk - os.time() < 0) then
			kick(lpdata.steam, "You were kicked because you idled too long, but you can rejoin at any time.")
		end
	end

	if igplayers[lpdata.steam].spawnedInWorld then
		if igplayers[lpdata.steam].greet then
			if tonumber(igplayers[lpdata.steam].greetdelay) > 0 then
				-- Player has spawned.  We can greet them now and do other stuff that waits for spawn
				igplayers[lpdata.steam].greetdelay = 0
			end
		end

		if tonumber(igplayers[lpdata.steam].teleCooldown) > 100 then
			igplayers[lpdata.steam].teleCooldown = 3
		end

		if igplayers[lpdata.steam].doFirstSpawnedTasks then
			igplayers[lpdata.steam].doFirstSpawnedTasks = nil

			if server.botman then
				if players[lpdata.steam].mute then
					mutePlayerChat(lpdata.steam , "true")
				end

				if players[lpdata.steam].chatColour ~= "" then
					if string.upper(string.sub(players[lpdata.steam].chatColour, 1, 6)) ~= "FFFFFF" then
						setPlayerColour(lpdata.steam, stripAllQuotes(players[lpdata.steam].chatColour))
					else
						setChatColour(lpdata.steam, players[lpdata.steam].accessLevel)
					end
				else
					setChatColour(lpdata.steam, players[lpdata.steam].accessLevel)
				end

				-- limit ingame chat length to block chat bombs.
				setPlayerChatLimit(lpdata.steam, 300)
			end
		end
	end

	if not botman.botDisabled then
		if igplayers[lpdata.steam].currentLocationPVP then
			if players[lpdata.steam].alertPVP == true then
				message("pm " .. lpdata.userID .. " [" .. server.alertColour .. "]You have entered a PVP zone!  Players are allowed to kill you![-]")
				players[lpdata.steam].alertPVP = false
			end
		else
			if players[lpdata.steam].alertPVP == false then
				message("pm " .. lpdata.userID .. " [" .. server.warnColour .. "]You have entered a PVE zone.  Do not kill other players![-]")
				players[lpdata.steam].alertPVP = true
			end
		end
	end

	playersOnlineList[lpdata.steam].debugLine = debugger.getinfo(1).currentline
	if debug then dbug("debug playerinfo line " .. debugger.getinfo(1).currentline, true) end

	-- stuff to do after everything else
	-- record this coord as the last one that the player was allowed to be at.  if their next step is not allowed, they get returned to this one.
	igplayers[lpdata.steam].xPosLastOK = lpdata.x
	igplayers[lpdata.steam].yPosLastOK = lpdata.y
	igplayers[lpdata.steam].zPosLastOK = lpdata.z

	if debug then dbug("end playerinfo", true) end

	return true, "player info done"
end


function playerInfoTrigger(line)
	local debug, temp, data, lpdata
	local result, statusMessage
	local num, badData

	debug = false

	if debug then dbug("debug playerInfoTrigger line " .. debugger.getinfo(1).currentline, true) end

	lpdata = {}

	-- if botman.botDisabled then
		-- return
	-- end

	if server.useAllocsWebAPI then
		return
	end

if debug then dbug("debug playerInfoTrigger line " .. debugger.getinfo(1).currentline, true) end

	if string.find(line, ", health=") then
		data = string.split(line, ", ")

		if string.find(data[3], "pos") then
			lpdata.name = string.trim(data[2])
		else
			temp = data[1] .. ", name" .. string.sub(line, string.find(line, ", pos="), string.len(line))
			data = string.split(temp, ", ")
			lpdata.name = string.trim(string.sub(line, string.find(line, ",") + 2, string.find(line, ", pos=") - 1))
		end

		-- stop processing this player if we don't have 18 parts to the line after splitting on comma
		-- it is probably a read error
		if (tablelength(data) < 19) then
			return
		end

		temp = string.split(data[1], "=")
		lpdata.entityid = temp[2]

		num = tonumber(string.sub(data[3], 6))
		if (num == nil) then badData = true end
		lpdata.x = math.floor(num)

		num = tonumber(data[4])
		if (num == nil) then badData = true end
		lpdata.y = math.floor(num)

		temp = string.split(data[5], ")")
		num = tonumber(temp[1])
		if (num == nil) then badData = true end
		lpdata.z = math.floor(num)

		temp = string.split(data[11], "=")
		num = tonumber(temp[2])
		if (num == nil) then badData = true end
		lpdata.playerdeaths = num

		temp = string.split(data[12], "=")
		num = tonumber(temp[2])
		if (num == nil) then badData = true end
		lpdata.zombiekills = num

		temp = string.split(data[13], "=")
		num = tonumber(temp[2])
		if (num == nil) then badData = true end
		lpdata.playerkills = num

		temp = string.split(data[14], "=")
		num = tonumber(temp[2])
		if (num == nil) then badData = true end
		lpdata.score = num

		temp = string.split(data[15], "=")
		num = tonumber(temp[2])
		if (num == nil) then badData = true end
		lpdata.level = num

		temp = string.split(data[16], "=")
		temp = string.split(temp[2], "_")
		lpdata.platform = temp[1]
		lpdata.steam = temp[2]
		lpdata.steam = tostring(lpdata.steam)

		temp = string.split(data[17], "=")
		lpdata.userID = temp[2]

		playersOnlineList[lpdata.steam] = {}
		botStatus.playersOnlineList[lpdata.steam] = {}
		botStatus.playersOnlineList[lpdata.steam].steam = lpdata.steam


		temp = string.split(data[18], "=")
		lpdata.ip = temp[2]
		lpdata.ip = lpdata.ip:gsub("::ffff:","")

		temp = string.split(data[19], "=")
		lpdata.ping = tonumber(temp[2])


		if not lpdata.userID then
			lpdata.userID = LookupJoiningPlayer(lpdata.steam)
		end

		if badData then
			if debug then
				dbug("debug playerInfoTrigger line " .. debugger.getinfo(1).currentline, true)
				dbug("Bad lp line: " .. line .. "\n", true)
			end

			return
		end

		lpdata.rawPosition = lpdata.x .. lpdata.y .. lpdata.z
		playersOnlineList[lpdata.steam].faulty = false
		result, statusMessage = pcall(playerInfo, lpdata)

		if not result then
			windowMessage(server.windowDebug, "!! Fault detected in playerinfo\n")
			windowMessage(server.windowDebug, "Last debug line " .. playersOnlineList[lpdata.steam].debugLine .. "\n")
			windowMessage(server.windowDebug, "Faulty player " .. lpdata.steam .. " " .. lpdata.name ..  "\n")
			windowMessage(server.windowDebug, line .. "\n")
			windowMessage(server.windowDebug, "----------\n")

			playersOnlineList[lpdata.steam].faulty = true
			fixMissingPlayer(lpdata.platform, lpdata.steam, lpdata.steam, lpdata.userID)
			fixMissingIGPlayer(lpdata.platform, lpdata.steam, lpdata.steam, lpdata.userID)
		end
	end

	if debug then dbug("end playerInfoTrigger", true) end
end