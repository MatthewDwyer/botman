--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function thirtySecondTimer()
	local k, v, cmd

	windowMessage(server.windowDebug, "30 second timer\n")

	if botman.botDisabled or botman.botOffline then
		return
	end

	if (botman.announceBot == true) then
		fixMissingServer() -- test for missing values

		message("say [" .. server.chatColour .. "]" .. server.botName .. " is online. Command me. :3[-]")
		botman.announceBot = false
	end

	math.randomseed( os.time() )

	if (botman.initError == true) then
		message("say [" .. server.chatColour .. "]" .. server.botName .. " encountered a problem starting up.  Attempting automatic fix..[-]")
		gatherServerData()
		botman.initError = false
		botman.announceBot = true
	end

	if tonumber(server.rebootHour) == tonumber(botman.serverHour) and tonumber(server.rebootMinute) == tonumber(botman.serverMinute) and botman.scheduledRestart == false and server.allowReboot then
		message("say [" .. server.chatColour .. "]The server will reboot in 15 minutes.[-]")
		botman.scheduledRestartPaused = false
		botman.scheduledRestart = true
		botman.scheduledRestartTimestamp = os.time() + 900
	end

	if not server.lagged then
		newDay()

		-- scan player inventories
		for k, v in pairs(igplayers) do
			if (igplayers[k].killTimer == nil) then igplayers[k].killTimer = 9 end

			if tonumber(igplayers[k].killTimer) < 2 then
				cmd = "si " .. k
				if botman.dbConnected then conn:execute("INSERT into commandQueue (command, steam) VALUES ('" .. cmd .. "'," .. k .. ")") end
			end
		end

		cmd = "DoneInventory"
		if botman.dbConnected then conn:execute("INSERT into commandQueue (command) VALUES ('" .. cmd .. "')") end

		if tonumber(botman.playersOnline) > 15 then
			if server.scanZombies or server.scanEntities then
				send("le")
			end

			if server.coppi then
				if server.scanNoclip then
					if not string.find(server.gameVersion, "Alpha 16 (b105)") then
						-- check for noclipped players
						for k,v in pairs(igplayers) do
							if tonumber(players[k].accessLevel) > 2 then
								send("pug " .. k)
							end
						end
					end
				end

				if not server.playersCanFly then
					-- check for flying players
					for k,v in pairs(igplayers) do
						if tonumber(players[k].accessLevel) > 2 then
							send("pgd " .. k)
						end
					end
				end
			end
		end
	end

	-- update the shared database (bots) server table (mainly for players online and a timestamp so others can see we're still online
	updateBotsServerTable()
end
