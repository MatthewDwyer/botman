--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function OneSecondTimer()
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
