--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

local debug


function savePlayerData(steam)
	--dbug("savePlayerData " .. steam)

	if players[steam].userID then
		fixMissingPlayer(players[steam].platform, steam, players[steam].steamOwner, players[steam].userID)
		fixMissingIGPlayer(players[steam].platform, steam, players[steam].steamOwner, players[steam].userID)
	end

	-- update players table with x y z
	players[steam].lastAtHome = nil
	players[steam].protectPaused = nil

	if igplayers[steam].name then
		players[steam].name = igplayers[steam].name
	else
		players[steam].name = ""
	end

	players[steam].xPos = igplayers[steam].xPos
	players[steam].yPos = igplayers[steam].yPos
	players[steam].zPos = igplayers[steam].zPos
	players[steam].seen = botman.serverTime
	players[steam].playerKills = igplayers[steam].playerKills
	players[steam].deaths = igplayers[steam].deaths
	players[steam].zombies = igplayers[steam].zombies
	players[steam].score = igplayers[steam].score
	players[steam].ping = igplayers[steam].ping

	if igplayers[steam].userID then
		players[steam].userID = igplayers[steam].userID
	end

	if igplayers[steam].platform then
		players[steam].platform = igplayers[steam].platform
	end

	-- update the player record in the database
	updatePlayer(steam)
	saveSQLitePlayer(steam)
end


function oneMinuteTimer()
	local words, word, rday, rhour, rmin, k, v, tmp
	local diff, days, minutes, hours, restartTime, zombiePlayers, tempDate, playerList

	botman.oneMinuteTimer_faulty = true
	tmp = {}

	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	fixMissingStuff()

	if tonumber(server.uptime) <= 0 then
		if server.botman then
			sendCommand("bm-uptime")
		end
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	tempDate = os.date("%Y-%m-%d", os.time())

	if botman.botDate == nil then
		botman.botDate = os.date("%Y-%m-%d", os.time())
		botman.botTime = os.date("%H:%M:%S", os.time())
	end

	-- if the bot's local date has changed, run NewBotDay
	if tempDate ~= botman.botDate then
		newBotDay()
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	botman.botDate = os.date("%Y-%m-%d", os.time())
	botman.botTime = os.date("%H:%M:%S", os.time())


if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	if botman.botOffline then
		botman.oneMinuteTimer_faulty = false
		return
	end

	botHeartbeat()

	if botman.botDisabled then
		botman.oneMinuteTimer_faulty = false
		return
	end

	if server.useAllocsWebAPI and botman.APIOffline then
		sendCommand("pm apitest")
	end

	if tonumber(botman.playersOnline) ~= 0 then
		sendCommand("gt")
	end

	if customOneMinuteTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customOneMinuteTimer() then
			botman.oneMinuteTimer_faulty = false
			return
		end
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	if tablelength(players) == 0 then
		gatherServerData()
		botman.oneMinuteTimer_faulty = false
		return
	end

	if tonumber(botman.playersOnline) > 0 then
		if server.botman then
			sendCommand("bm-listplayerbed")
			sendCommand("bm-listplayerfriends")
			sendCommand("bm-anticheat report")
		end

		-- if server.useAllocsWebAPI then
			-- sendCommand("lp")
		-- end

		if tonumber(botman.playersOnline) < 25 then
			removeClaims()
		end

		if tonumber(server.maxPrisonTime) > 0 then
			-- check for players to release from prison
			for k,v in pairs(igplayers) do
				if tonumber(players[k].prisonReleaseTime) < os.time() and players[k].prisoner and tonumber(players[k].prisonReleaseTime) > 0 then
					gmsg(server.commandPrefix .. "release " .. k)
				else
					if players[k].prisoner then
						if players[k].prisonReleaseTime - os.time() < 86164 then
							days, hours, minutes = timeRemaining(players[k].prisonReleaseTime)
							message("pm " .. v.userID .. " [" .. server.chatColour .. "]You will be released in about " .. days .. " days " .. hours .. " hours and " .. minutes .. " minutes.[-]")
						end
					end
				end
			end
		end
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	-- build list of players that are online for the panel
	panelWho()

	-- check for timed events due to run
	runTimedEvents()

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	if not server.windowGMSG then
		-- fix a weird issue where the server table is not all there.  In testing, after restoring the table the bot restarted itself which is what we're after here.
		loadServer()
	end

	windowMessage(server.windowDebug, "one minute timer\n")

	if not server.ServerMaxPlayerCount then
		-- missing ServerMaxPlayerCount so we need to re-read gg
		sendCommand("gg")
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	zombiePlayers = {}

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	if os.time() - server.serverStartTimestamp > 180 then
		if not server.delayReboot then
			if (botman.scheduledRestart == true) and botman.scheduledRestartPaused == false and tonumber(botman.playersOnline) > 0 and server.allowReboot == true then
				restartTime = botman.scheduledRestartTimestamp - os.time()

				if (restartTime > 60 and restartTime < 601) or (restartTime > 1139 and restartTime < 1201) or (restartTime > 1799 and restartTime < 1861) then
					message("say [" .. server.chatColour .. "]Rebooting in " .. os.date("%M minutes %S seconds",botman.scheduledRestartTimestamp - os.time()) .. ".[-]")
				end
			end
		end
	else
		botman.scheduledRestart = false
		botman.scheduledRestartTimestamp = os.time()
		botman.scheduledRestartPaused = false
		botman.scheduledRestartForced = false
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	for k, v in pairs(igplayers) do
		if not v.name then
			v.name = ""
		end

		if not players[k].newPlayer then
			players[k].cash = players[k].cash + LookupSettingValue(k, "perMinutePayRate")
		end

		if server.ServerMaxPlayerCount then
			if tonumber(v.afk - os.time()) < 200 and (botman.playersOnline >= server.ServerMaxPlayerCount or server.idleKickAnytime) and (not isAdminHidden(k, v.userID)) and server.idleKick then
				message("pm " .. v.userID .. " [" .. server.warnColour .. "]You appear to be away from your keyboard.  You will be kicked after " .. os.date("%M minutes %S seconds",v.afk - os.time()) .. " for being afk.  If you move, talk, add or remove inventory you will not be kicked.[-]")
			end
		end

		if tonumber(players[k].groupExpiry) > 0 then
			tmp.diff = os.difftime(players[k].groupExpiry, os.time())

			if tmp.diff < 0 then
				-- group membership has expired
				players[k].groupID = players[k].groupExpiryFallbackGroup
				players[k].groupExpiryFallbackGroup = 0
				players[k].groupExpiry = 0
			end
		end

if debug then
	dbug("steam " .. k .. " name " .. v.name)
end

		-- save the igplayer to players
		savePlayerData(k)

		-- reload the player from the database so that we fill in any missing fields with default values
		loadPlayers(k, true)

		-- add or update the player record in the bots shared database
		insertBotsPlayer(k)

		if (v.killTimer == nil) then
			v.killTimer = 0
		end

		v.killTimer = v.killTimer + 1

		if (v.killTimer > 1) then
			-- clean up some tables, removing the player from them
			invTemp[k] = nil

			if (v.timeOnServer) then players[k].timeOnServer = players[k].timeOnServer + v.sessionPlaytime end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

			if (os.time() - players[k].lastLogout) > 300 then
				players[k].relogCount = 0
			end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

			if (os.time() - players[k].lastLogout) < 60 then
				players[k].relogCount = tonumber(players[k].relogCount) + 1
			else
				players[k].relogCount = tonumber(players[k].relogCount) - 1
				if tonumber(players[k].relogCount) < 0 then players[k].relogCount = 0 end
			end

			lastHotspots[k] = nil
			players[k].lastLogout = os.time()

			if botman.dbConnected then
				connSQL:execute("DELETE FROM messageQueue WHERE recipient = '" .. k .. "'")
				connMEM:execute("DELETE FROM gimmeQueue WHERE steam = '" .. k .. "'")
				connSQL:execute("DELETE FROM commandQueue WHERE steam = '" .. k .. "'")
				connSQL:execute("DELETE FROM playerQueue WHERE steam = '" .. k .. "'")

				if isAdminHidden(k, v.userID) then
					connMEM:execute("DELETE FROM tracker WHERE steam = '" .. k .. "'")
				end
			end

			-- the player's y coord is negative.  Attempt to rescue them by sending them back to the surface.
			if tonumber(v.yPos) < 0 and not isAdminHidden(k, v.userID) then
				if not v.fallingRescue then
					v.fallingRescue = true
					sendCommand("tele " .. v.userID .. " " .. v.xPosLastOK .. " -1 " .. v.zPosLastOK)
				else
					v.fallingRescue = nil
					kick(k, "You were kicked to fix you falling under the world. You can rejoin any time.")
				end
			end

			-- check how many claims they have placed
			sendCommand("llp " .. v.userID .. " parseable")

			-- flag this ingame player record for deletion
			zombiePlayers[k] = {}

			if botman.botsConnected then
				-- update player in bots db
				--connBots:execute("UPDATE players SET ip = '" .. players[k].ip .. "', name = '" .. escape(stripCommas(players[k].name)) .. "', online = 0 WHERE steam = '" .. k .. "' AND botID = " .. server.botID)
			end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end
		end
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	for k, v in pairs(zombiePlayers) do
		if debug then dbug("Removing zombie player " .. players[k].name .. "\n") end
		igplayers[k] = nil
		playersOnlineList[k] = nil
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	-- check players table for problems and remove
	for k, v in pairs(players) do
		if (k ~= v.steam) or v.id == "-1" then
			players[k] = nil
			playersOnlineList[k] = nil
		end
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	-- report excessive falling blocks
	if tonumber(server.dropMiningWarningThreshold) > 0 then
		for k,v in pairs(fallingBlocks) do
			if tonumber(v.count) > tonumber(server.dropMiningWarningThreshold) then
				irc_chat(server.ircAlerts, v.count .. " blocks fell off the world in region " .. k .. " ( " .. v.x .. " " .. v.y .. " " .. v.z .. " )")
				alertAdmins(v.count .. " blocks fell off the world in region " .. k .. " ( " .. v.x .. " " .. v.y .. " " .. v.z .. " )", "warn")

				playerList = ""

				-- players near the falling blocks
				for a, b in pairs(igplayers) do
					dist = distancexz(v.x, v.z, b.xPos, b.zPos)

					if tonumber(dist) < 300 then
						if playerList == "" then
							playerList = b.name .. " (" .. string.format("%d", dist) .. ")"
						else
							playerList = playerList .. ", " .. b.name .. " (" .. string.format("%d", dist) .. ")"
						end
					end
				end

				if playerList ~= "" then
					irc_chat(server.ircAlerts, "Players near falling blocks and (distance): " .. playerList)
					alertAdmins("Players near falling blocks and (distance): " .. playerList, "warn")
				end
			end
		end
	end

	-- reset the fallingBlocks table
	fallingBlocks = {}

	-- if (server.scanZombies or server.scanEntities) then
		-- if not server.useAllocsWebAPI then
			-- sendCommand("le")
		-- end
	-- end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	-- save some server fields
	if botman.dbConnected then conn:execute("UPDATE server SET lottery = " .. server.lottery .. ", date = '" .. server.dateTest .. "', ircBotName = '" .. server.ircBotName .. "'") end

	if server.useAllocsWebAPI then
		-- if (botman.resendAdminList or tablelength(staffList) == 0) then
			-- if not botman.noAdminsDefined then
				-- sendCommand("admin list")
			-- end

			-- botman.resendAdminList = false
		-- end

		if botman.resendBanList then
			sendCommand("ban list")
			botman.resendBanList = false
		end

		if botman.resendGG then
			sendCommand("gg")
			botman.resendGG = false
		end

		if type(modVersions) ~= "table" then
			modVersions = {}
		end

		if botman.resendVersion or tablelength(modVersions) == 0 then
			sendCommand("version")
			botman.resendVersion = false
		end
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	if tonumber(server.reservedSlots) > 0 then
		updateSlots()
	end

	botman.oneMinuteTimer_faulty = false

if debug then dbug("debug one minute timer end") end
end
