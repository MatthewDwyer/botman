--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function ThirtyMinuteTimer()
	cecho (server.windowDebug, "half hour timer\n")

	-- save the world (and the kitties)
	send("sa")

	-- reload the list of proxies from the bots db
	loadProxies()
end
