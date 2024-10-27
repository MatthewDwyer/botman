--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function OneSecondTimer()
	if botman and server then
		if botman.serverTimeSync then
			botman.serverTimeStamp = calculateServerTime(os.time())

			if server.serverStartTimestamp then
				server.uptime = os.time() - server.serverStartTimestamp
			end
		end

		if not server.readLogUsingTelnet then
			if server.useAllocsWebAPI then
				if not botman.lastLogRead then
					botman.lastLogRead = os.time()
					getAPILogUpdates_JSON()
				else
					if os.time() - botman.lastLogRead > server.logPollingInterval then
						botman.lastLogRead = os.time()
						getAPILogUpdates_JSON()
					end
				end
			end
		end
	end
end