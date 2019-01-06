--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug


function savePlayerData(steam)
	--dbug("savePlayerData " .. steam)

	fixMissingPlayer(steam)
	fixMissingIGPlayer(steam)

	-- update players table with x y z
	players[steam].lastAtHome = nil
	players[steam].protectPaused = nil
	players[steam].name = igplayers[steam].name
	players[steam].xPos = igplayers[steam].xPos
	players[steam].yPos = igplayers[steam].yPos
	players[steam].zPos = igplayers[steam].zPos
	players[steam].seen = botman.serverTime
	players[steam].playerKills = igplayers[steam].playerKills
	players[steam].deaths = igplayers[steam].deaths
	players[steam].zombies = igplayers[steam].zombies
	players[steam].score = igplayers[steam].score
	players[steam].ping = igplayers[steam].ping

	-- update the player record in the database
	updatePlayer(steam)
end


function everyMinute()
	local words, word, rday, rhour, rmin, k, v
	local diff, days, hours, restartTime, zombiePlayers, tempDate, playerList

	windowMessage(server.windowDebug, "60 second timer\n")

	if not server.ServerMaxPlayerCount then
		-- missing ServerMaxPlayerCount so we need to re-read gg
		sendCommand("gg")
	end

	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	zombiePlayers = {}
	diff = server.uptime
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	if not server.delayReboot then
		--if (scheduledReboot == true or botman.scheduledRestart == true) and botman.scheduledRestartPaused == false and tonumber(botman.playersOnline) > 0 and server.allowReboot == true then
		if (botman.scheduledRestart == true) and botman.scheduledRestartPaused == false and tonumber(botman.playersOnline) > 0 and server.allowReboot == true then
			restartTime = botman.scheduledRestartTimestamp - os.time()

			if (restartTime > 60 and restartTime < 601) or (restartTime > 1139 and restartTime < 1201) or (restartTime > 1799 and restartTime < 1861) then
				message("say [" .. server.chatColour .. "]Rebooting in " .. os.date("%M minutes %S seconds",botman.scheduledRestartTimestamp - os.time()) .. ".[-]")
			end
		end
	end

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	for k, v in pairs(igplayers) do
		if not players[k].newPlayer then
			players[k].cash = players[k].cash + server.perMinutePayRate
		end

		if server.ServerMaxPlayerCount then
			if tonumber(v.afk - os.time()) < 300 and tonumber(v.afk - os.time()) > 60 and (botman.playersOnline >= server.ServerMaxPlayerCount) and (accessLevel(steam) > 2) and server.idleKick then
				message("pm " .. v.steam .. " [" .. server.warnColour .. "]You appear to be away from your keyboard.  You will be kicked in " .. os.date("%M minutes %S seconds",v.afk - os.time()) .. " for being afk.  If you move, talk or do things you will not be kicked.[-]")
			end
		end

		if debug then
			dbug("steam " .. k .. " name " .. v.name)
		end

		-- save the igplayer to players
		savePlayerData(k)

		-- reload the player from the database so that we fill in any missing fields with default values
		loadPlayers(k)

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
				conn:execute("DELETE FROM messageQueue WHERE recipient = " .. k)
				conn:execute("DELETE FROM gimmeQueue WHERE steam = " .. k)
				conn:execute("DELETE FROM commandQueue WHERE steam = " .. k)
				conn:execute("DELETE FROM playerQueue WHERE steam = " .. k)

				if accessLevel(k) < 3 then
					conn:execute("DELETE FROM memTracker WHERE steam = " .. k)
				end
			end

			-- the player's y coord is negative.  Attempt to rescue them by sending them back to the surface.
			if tonumber(v.yPos) < 0 and accessLevel(k) > 2 then
				if not v.fallingRescue then
					v.fallingRescue = true
					sendCommand("tele " .. k .. " " .. v.xPosLastOK .. " -1 " .. v.zPosLastOK)
				else
					v.fallingRescue = nil
					kick(k, "You were kicked to fix you falling under the world. You can rejoin any time.")
				end
			end

			-- check how many claims they have placed
			sendCommand("llp " .. k .. " parseable")

			-- flag this ingame player record for deletion
			zombiePlayers[k] = {}

			if botman.db2Connected then
				-- update player in bots db
				connBots:execute("UPDATE players SET ip = '" .. players[k].ip .. "', name = '" .. escape(stripCommas(players[k].name)) .. "', online = 0 WHERE steam = " .. k .. " AND botID = " .. server.botID)
			end

			if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end
		end
	end

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	initReservedSlots()

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	for k, v in pairs(zombiePlayers) do
		dbug("Removing zombie player " .. players[k].name .. "\n")
		igplayers[k] = nil
	end

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	-- check players table for problems and remove
	for k, v in pairs(players) do
		if (k ~= v.steam) or v.id == "-1" then
			players[k] = nil
		end
	end

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	if tonumber(botman.playersOnline) == 0 and botman.scheduledRestart and server.allowReboot and not botman.serverRebooting then
		irc_chat(server.ircMain, "A reboot is scheduled and nobody is on so the server is rebooting now.")
		botman.scheduledRestart = false
		botman.scheduledRestartTimestamp = os.time()
		botman.scheduledRestartPaused = false
		botman.scheduledRestartForced = false

		if (botman.rebootTimerID ~= nil) then killTimer(botman.rebootTimerID) end
		if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end

		botman.rebootTimerID = nil
		rebootTimerDelayID = nil

		if not botMaintenance.lastSA then
			botMaintenance.lastSA = os.time()
			saveBotMaintenance()
			send("sa")
		else
			if (os.time() - botMaintenance.lastSA) > 30 then
				botMaintenance.lastSA = os.time()
				saveBotMaintenance()
				send("sa")
			end
		end

		finishReboot()
	end

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	if (botman.playersOnline == 0 and server.uptime < 0) and (scheduledReboot ~= true) and server.allowReboot and not botman.serverRebooting then
		botman.rebootTimerID = tempTimer( 60, [[startReboot()]] )
		scheduledReboot = true
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

	if (server.scanZombies or server.scanEntities) and not server.lagged then
		if not server.useAllocsWebAPI then
			sendCommand("le")
		end
	end

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	-- save some server fields
	if botman.dbConnected then conn:execute("UPDATE server SET lottery = " .. server.lottery .. ", date = '" .. server.dateTest .. "', ircBotName = '" .. server.ircBotName .. "'") end

	if server.useAllocsWebAPI then
		if botman.resendAdminList or tablelength(staffList) == 0 then
			sendCommand("admin list")
			botman.resendAdminList = false
		end

		if botman.resendBanList then
			sendCommand("ban list")
			botman.resendBanList = false
		end

		if botman.resendGG then
			sendCommand("gg")
			botman.resendGG = false
		end

		if botman.resendVersion or tablelength(modVersions) == 0 or not server.allocs then
			sendCommand("version")
			botman.resendVersion = false
		end
	end

	if debug then dbug("debug everyMinute end") end
end


function oneMinuteTimer()
	local k, v, days, hours, minutes, tempDate

	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	fixMissingStuff()

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

	if botman.botDisabled or botman.botOffline or server.lagged then
		return
	end

	if customOneMinuteTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customOneMinuteTimer() then
			return
		end
	end

	if server.stompy and server.useAllocsWebAPI then
		sendcommand("bc-time")
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	everyMinute()

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	if tablelength(players) == 0 then
		gatherServerData()
		return
	end

	if tonumber(botman.playersOnline) > 0 then
		if tonumber(botman.playersOnline) < 25 then
			if server.stompy then
				--for k, v in pairs(igplayers) do
					sendCommand("bc-lp /online /filter=steamid,friends,bedroll,pack,walked")
				--end
			end

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
							message("pm " .. k .. " [" .. server.chatColour .. "]You will be released in about " .. days .. " days " .. hours .. " hours and " .. minutes .. " minutes.[-]")
						end
					end
				end
			end
		end
	end

if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	botHeartbeat()

	-- check for timed events due to run
	runTimedEvents()

if debug then dbug("debug one minute timer end") end
end
