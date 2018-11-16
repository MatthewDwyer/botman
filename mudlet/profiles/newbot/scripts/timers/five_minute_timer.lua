--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function FiveMinuteTimer()
	if tonumber(botman.playersOnline) > 0 then
		-- save the penguins! er I mean world!
		if not botman.serverRebooting then
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
	end

	if not botman.botOffline and tonumber(botman.playersOnline) == 0 then
		-- send a telnet command every 5 minutes when no players are on so the bot can tell that it is still connected to telnet.
		send("gt") -- Are you there?   Is this thing on?
	end
end