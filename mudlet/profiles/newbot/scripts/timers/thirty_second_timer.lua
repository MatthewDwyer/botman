--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug = false

function thirtySecondTimer()
	local k, v, cmd

	-- windowMessage(server.windowDebug, "30 second timer\n")

	if botman.botDisabled or botman.botOffline then
		return
	end

	if(debug) then dbugFull("I", "", "", "30 second timer.") end

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
		send("gt")
		newDay()

		-- scan player inventories
		for k, v in pairs(igplayers) do
			if (igplayers[k].killTimer == nil) then igplayers[k].killTimer = 9 end

			-- if tonumber(igplayers[k].killTimer) < 2 then
				cmd = "si " .. k
				if botman.dbConnected then conn:execute("INSERT into commandQueue (command, steam) VALUES ('" .. cmd .. "'," .. k .. ")") end
			-- end
		end

		cmd = "DoneInventory"
		if botman.dbConnected then conn:execute("INSERT into commandQueue (command) VALUES ('" .. cmd .. "')") end
	end

	-- update the shared database (bots) server table (mainly for players online and a timestamp so others can see we're still online
	updateBotsServerTable()
end
