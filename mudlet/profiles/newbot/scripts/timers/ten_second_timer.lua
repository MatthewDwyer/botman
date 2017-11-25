--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function TenSecondTimer()
	if botman.botOffline or botman.botDisabled then
		return
	end

	-- test for telnet command lag as it can creep up on busy servers or when there are lots of telnet errors going on
	if not botman.botOffline and not botman.botDisabled then
		botman.lagCheckTime = os.time()
		send("pm LagCheck " .. server.botID)

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end
	else
		botman.lagCheckTime = os.time()
		server.lagged = false
	end
end