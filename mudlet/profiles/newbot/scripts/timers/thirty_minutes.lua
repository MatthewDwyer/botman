--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]


function ThirtyMinuteTimer()
	windowMessage(server.windowDebug, "half hour timer\n")

	-- save the world (and the kitties)
	if not botman.botOffline and not botman.serverRebooting then
		if not botMaintenance.lastSA then
			botMaintenance.lastSA = os.time()
			saveBotMaintenance()
			sendCommand("sa")
		else
			if (os.time() - botMaintenance.lastSA) > 30 and tonumber(botman.playersOnline) > 0  then
				botMaintenance.lastSA = os.time()
				saveBotMaintenance()
				sendCommand("sa")
			end
		end
	end

	-- check for new proxies
	loadProxies()
end
