--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function savePlayerData(steam)
	dbug("savePlayerData " .. steam)

	fixMissingPlayer(steam)
	fixMissingIGPlayer(steam)

	-- update players table with x y z
	players[steam].lastAtHome = nil
	players[steam].protectPaused = nil
	players[steam].name = igplayers[steam].name
	players[steam].xPos = igplayers[steam].xPos
	players[steam].yPos = igplayers[steam].yPos
	players[steam].zPos = igplayers[steam].zPos
	players[steam].seen = serverTime
	players[steam].playerKills = igplayers[steam].playerKills
	players[steam].deaths = igplayers[steam].deaths
	players[steam].zombies = igplayers[steam].zombies
	players[steam].score = igplayers[steam].score
	players[steam].ping = igplayers[steam].ping

	-- update the player record in the database
	updatePlayer(steam)

	dbug("savePlayerData " .. steam .. " saved")
end


function OneMinuteTimer()
	local words, word, rday, rhour, rmin, k,v, debug
	local diff, days, hours, restartTime, zombiePlayers

	cecho (server.windowDebug, "60 second timer\n")

	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false

	if debug then dbug("debug one minute timer") end

	zombiePlayers = {}
	diff = gameTick
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if debug then dbug("debug one minute timer 1") end

	-- save some server fields
	conn:execute("UPDATE server SET lottery = " .. server.lottery .. ", date = '" .. server.date .. "'")

	if debug then dbug("debug one minute timer 2") end

	if not server.delayReboot then
		if (scheduledReboot == true or server.scheduledRestart == true) and scheduledRestartPaused == false and tonumber(playersOnline) > 0 and server.allowReboot == true then
			restartTime = server.scheduledRestartTimestamp - os.time()

			if (restartTime > 60 and restartTime < 601) or (restartTime > 1139 and restartTime < 1201) or (restartTime > 1799 and restartTime < 1861) then
				message("say [" .. server.chatColour .. "]Rebooting in " .. os.date("%M minutes %S seconds",server.scheduledRestartTimestamp - os.time()) .. ".[-]")
			end
		end
	end

	if debug then dbug("debug one minute timer 3") end

	if (idleKickTimer == nil) then 	idleKickTimer = 0 end

	for k, v in pairs(igplayers) do
--		if (v.afk - os.time() < 421) and (playersOnline >= server.ServerMaxPlayerCount) and (accessLevel(steam) > 2) then
--			message("pm " .. v.steam .. " [" .. server.chatColour .. "]You appear to be away from your keyboard.  You will be kicked in " .. os.date("%M minutes %S seconds",v.afk - os.time()) .. " for being afk.  If you simply move you will not be kicked.[-]")
--		end

		if debug then
			dbug("steam " .. k .. " name " .. v.name)
		end

		if (v.killTimer == nil) then
			v.killTimer = 0
		end

		v.killTimer = v.killTimer + 1

		if (v.killTimer > 1) then
			-- save the igplayer to players
			savePlayerData(k)

			-- clean up some tables, removing the player from them
			invTemp[k] = nil

			if (v.timeOnServer) then players[k].timeOnServer = players[k].timeOnServer + v.sessionPlaytime end

			if debug then dbug("debug one minute timer 3l") end

			if (os.time() - players[k].lastLogout) > 300 then
				players[k].relogCount = 0
			end

			if debug then dbug("debug one minute timer 3e") end

			if (os.time() - players[k].lastLogout) < 60 then
				players[k].relogCount = tonumber(players[k].relogCount) + 1
			else
				players[k].relogCount = tonumber(players[k].relogCount) - 1
				if tonumber(players[k].relogCount) < 0 then players[k].relogCount = 0 end
			end

			lastHotspots[k] = nil
			players[k].lastLogout = os.time()

			conn:execute("DELETE FROM messageQueue WHERE recipient = " .. k)
			conn:execute("DELETE FROM gimmeQueue WHERE steam = " .. k)
			conn:execute("DELETE FROM commandQueue WHERE steam = " .. k)
			conn:execute("DELETE FROM playerQueue WHERE steam = " .. k)

			if accessLevel(k) < 3 then
				conn:execute("DELETE FROM memTracker WHERE steam = " .. k)
			end

			-- check how many claims they have placed
			send("llp " .. k)

			-- flag this ingame player record for deletion
			zombiePlayers[k] = {}

			if db2Connected then
				-- update player in bots db
				connBots:execute("UPDATE players SET ip = '" .. players[k].IP .. "', name = '" .. escape(players[k].name) .. "', online = 0 WHERE steam = " .. k .. " AND botID = " .. server.botID)
			end

			if debug then dbug("debug one minute timer 3z") end
		end
	end

	if debug then dbug("debug one minute timer 4") end

	for k, v in pairs(zombiePlayers) do
		dbug("Removing zombie player " .. players[k].name .. "\n")
		igplayers[k] = nil
	end

	if debug then dbug("debug one minute timer 5") end

	-- check players table for problems and remove
	for k, v in pairs(players) do
		if (k ~= v.steam) or v.id == "-1" then
			players[k] = nil
		end
	end

	if debug then dbug("debug one minute timer 6") end

	if (playersOnline == 0 and gameTick < 0) and (scheduledReboot ~= true) and server.allowReboot == true then
		rebootTimerID = tempTimer( 60, [[startReboot()]] )
		scheduledReboot = true
	end

	if debug then dbug("debug one minute timer end") end
end
