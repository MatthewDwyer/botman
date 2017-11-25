--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

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
	local words, word, rday, rhour, rmin, k,v, debug
	local diff, days, hours, restartTime, zombiePlayers

	windowMessage(server.windowDebug, "60 second timer\n")

	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	-- special test for bot offline incase the main test fails to trigger
	if botman.lastTelnetTimestamp == nil then
		botman.lastTelnetTimestamp = os.time()
	end

	if os.time() - botman.lastTelnetTimestamp > 300 then
		botman.lastTelnetTimestamp = os.time() -- reset this to make it sleep 5 minutes
		botman.botOfflineCount = 2
		reconnect()
		irc_chat(server.ircMain, "Bot is offline - reconnecting.")
	end

	writeBotmanINI()

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	zombiePlayers = {}
	diff = gameTick
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	-- save some server fields
	if botman.dbConnected then conn:execute("UPDATE server SET lottery = " .. server.lottery .. ", date = '" .. server.date .. "', ircBotName = '" .. server.ircBotName .. "'") end

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

		if tonumber(v.afk - os.time()) < 300 and tonumber(v.afk - os.time()) > 60 and (botman.playersOnline >= server.ServerMaxPlayerCount) and (accessLevel(steam) > 2) and server.idleKick then
			message("pm " .. v.steam .. " [" .. server.warnColour .. "]You appear to be away from your keyboard.  You will be kicked in " .. os.date("%M minutes %S seconds",v.afk - os.time()) .. " for being afk.  If you move, talk or do things you will not be kicked.[-]")
		end

		if debug then
			dbug("steam " .. k .. " name " .. v.name)
		end

		-- save the igplayer to players
		savePlayerData(k)

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

			-- check how many claims they have placed
			send("llp " .. k .. " parseable")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			-- flag this ingame player record for deletion
			zombiePlayers[k] = {}

			if botman.db2Connected then
				-- update player in bots db
				connBots:execute("UPDATE players SET ip = '" .. players[k].IP .. "', name = '" .. escape(stripCommas(players[k].name)) .. "', online = 0 WHERE steam = " .. k .. " AND botID = " .. server.botID)
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

	if tonumber(botman.playersOnline) == 0 and botman.scheduledRestart and server.allowReboot then
		irc_chat(server.ircMain, "A reboot is scheduled and nobody is on so the server is rebooting now.")
		botman.scheduledRestart = false
		botman.scheduledRestartTimestamp = os.time()
		botman.scheduledRestartPaused = false
		botman.scheduledRestartForced = false

		if (botman.rebootTimerID ~= nil) then killTimer(botman.rebootTimerID) end
		if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end

		botman.rebootTimerID = nil
		rebootTimerDelayID = nil

		send("sa")

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end

		finishReboot()
	end

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	if (botman.playersOnline == 0 and gameTick < 0) and (scheduledReboot ~= true) and server.allowReboot == true then
		botman.rebootTimerID = tempTimer( 60, [[startReboot()]] )
		scheduledReboot = true
	end

	if (debug) then dbug("debug one minute timer line " .. debugger.getinfo(1).currentline) end

	-- report excessive falling blocks
	for k,v in pairs(fallingBlocks) do
		if tonumber(v.count) > 99 then
			irc_chat(server.ircAlerts, v.count .. " blocks fell off the world in region " .. k .. " ( " .. v.x .. " " .. v.y .. " " .. v.z .. " ) in the last minute.")
			alertAdmins(v.count .. " blocks fell off the world in region " .. k .. " ( " .. v.x .. " " .. v.y .. " " .. v.z .. " ) in the last minute.", "warn")
		end
	end

	-- reset the fallingBlocks table
	fallingBlocks = {}

	if (server.scanZombies or server.scanEntities) and not server.lagged then
		send("le")

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end
	end

	if debug then dbug("debug one minute timer end") end
end
