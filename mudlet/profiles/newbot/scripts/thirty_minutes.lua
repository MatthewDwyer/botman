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
		sendCommand("sa")
	end

	if botman.getMetrics then
		metrics.telnetCommands = metrics.telnetCommands + 1
	end

	-- check for new proxies
	loadProxies()
end
