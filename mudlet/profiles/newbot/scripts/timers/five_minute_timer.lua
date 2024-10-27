--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]


function FiveMinuteTimer()
	if botman.botOffline then
		return
	end

	if tonumber(botman.playersOnline) > 0 then
		-- save the penguins! er I mean world!
		if not botman.serverRebooting then
			if not botMaintenance.lastSA then
				botMaintenance.lastSA = os.time()
				saveBotMaintenance()
				--sendCommand("sa")
			else
				if (os.time() - botMaintenance.lastSA) > 30 then
					botMaintenance.lastSA = os.time()
					saveBotMaintenance()
					--sendCommand("sa")
				end
			end
		end
	end
end