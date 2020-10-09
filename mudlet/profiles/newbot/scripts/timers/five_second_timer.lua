--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function FiveSecondTimer()
	if not server.readLogUsingTelnet then
		if server.useAllocsWebAPI and not botman.APIOffline then
			if not botman.lastLogRead then
				botman.lastLogRead = os.time()
				getAPILogUpdates()
			else
				if os.time() - botman.lastLogRead > server.logPollingInterval then
					botman.lastLogRead = os.time()
					getAPILogUpdates()
				end
			end
		end
	end

	if telnetLogFileName then
		-- force writes to the telnet log to save to disk
		telnetLogFile:flush()
	end
end
