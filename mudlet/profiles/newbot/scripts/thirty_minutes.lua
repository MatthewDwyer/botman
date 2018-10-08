--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function ThirtyMinuteTimer()
	windowMessage(server.windowDebug, "half hour timer\n")

	-- save the world (and the kitties)
	if not botman.botOffline and not botman.serverRebooting then
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
	end

	-- check for new proxies
	loadProxies()
end
