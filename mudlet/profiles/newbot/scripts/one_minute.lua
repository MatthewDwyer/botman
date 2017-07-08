--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug = false

function savePlayerData(steam)
	local name

	fixMissingPlayer(steam)
	fixMissingIGPlayer(steam)

	if(players[steam]) then name = players[steam].name
	elseif(igplayers[steam]) then name = igplayers[steam].name end

	if(not name) then  name = "undefined" end


	dbugFull("I", "", debugger.getinfo(1,"n"), name .. "(" ..steam .. ")")

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

	dbugFull("I", "", debugger.getinfo(1,"n"), players[steam].name .. "(" ..steam .. ") saved.")
end


function everyMinute()
	local words, word, rday, rhour, rmin, k,v
	local diff, days, hours, restartTime, zombiePlayers

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "One Minute timer start.\n") end

	-- enable debug to see where the code is stopping. Any error will be after the last debug line.

	zombiePlayers = {}
	diff = gameTick

	if(not diff) then
		gameTick = 0
		diff = 0
	end

	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	 if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	-- save some server fields
	if botman.dbConnected then conn:execute("UPDATE server SET lottery = " .. server.lottery .. ", date = '" .. server.date .. "', ircBotName = '" .. (server.ircBotName or "botman") .. "'") end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if not server.delayReboot then
		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		--if (scheduledReboot == true or botman.scheduledRestart == true) and botman.scheduledRestartPaused == false and tonumber(botman.playersOnline) > 0 and server.allowReboot == true then
		if (botman.scheduledRestart == true) and botman.scheduledRestartPaused == false and tonumber(botman.playersOnline) > 0 and server.allowReboot == true then
			if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
			restartTime = botman.scheduledRestartTimestamp - os.time()

			if (restartTime > 60 and restartTime < 601) or (restartTime > 1139 and restartTime < 1201) or (restartTime > 1799 and restartTime < 1861) then
				message("say [" .. server.chatColour .. "]Rebooting in " .. os.date("%M minutes %S seconds",botman.scheduledRestartTimestamp - os.time()) .. ".[-]")
			end
		end
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	for k, v in pairs(igplayers) do
		if tonumber(v.afk - os.time()) < 300 and tonumber(v.afk - os.time()) > 60 and (botman.playersOnline >= server.ServerMaxPlayerCount) and (accessLevel(steam) > 2) and server.idleKick then
			message("pm " .. v.steam .. " [" .. server.warnColour .. "]You appear to be away from your keyboard.  You will be kicked in " .. os.date("%M minutes %S seconds",v.afk - os.time()) .. " for being afk.  If you move, talk or do things you will not be kicked.[-]")
		end

		if debug then
			dbugFull("D", "", debugger.getinfo(1,"nSl"), "steam " .. k .. " name " .. v.name)
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

			if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

			if (os.time() - players[k].lastLogout) > 300 then
				players[k].relogCount = 0
			end

			if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

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
			send("llp " .. k)

			-- flag this ingame player record for deletion
			zombiePlayers[k] = {}

			if botman.db2Connected then
				-- update player in bots db
				connBots:execute("UPDATE players SET ip = '" .. players[k].IP .. "', name = '" .. escape(stripCommas(players[k].name)) .. "', online = 0 WHERE steam = " .. k .. " AND botID = " .. server.botID)
			end

		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
		end
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	for k, v in pairs(zombiePlayers) do
		dbugFull("I", "", debugger.getinfo(1,"nSl"), "Removing zombie player " .. players[k].name .. "\n")
		igplayers[k] = nil
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	-- check players table for problems and remove
	for k, v in pairs(players) do
		if (k ~= v.steam) or v.id == "-1" then
			players[k] = nil
		end
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if tonumber(botman.playersOnline) == 0 and botman.scheduledRestart and server.allowReboot then
		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		irc_chat(server.ircMain, "A reboot is scheduled and nobody is on so the server is rebooting now.")
		botman.scheduledRestart = false
		botman.scheduledRestartTimestamp = getRestartOffset()
		botman.scheduledRestartPaused = false
		botman.scheduledRestartForced = false

		if (botman.rebootTimerID ~= nil) then killTimer(botman.rebootTimerID) end
		if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end

		botman.rebootTimerID = nil
		rebootTimerDelayID = nil

		send("sa")
		finishReboot()
	end

	if (botman.playersOnline == 0 and gameTick < 0) and (scheduledReboot ~= true) and server.allowReboot == true then
		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		botman.rebootTimerID = tempTimer( 60, [[startReboot()]] )
		scheduledReboot = true
	end

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"),"One minute timer end.") end
end
