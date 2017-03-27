--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function lpTrigger(line)
	if botman.botDisabled then
		return
	end
	
	botman.listPlayers = true

	if string.find(string.sub(line, 1, 19), os.date("%Y")) then
		-- 2016-09-11T04:14:28 		
		botman.serverTime = string.sub(line, 1, 19)
		botman.serverHour = string.sub(line, 12, 13)
		botman.serverMinute = string.sub(line, 15, 16)		
		specialDay = ""

		if (string.find(botman.serverTime, "02-14", 5, 10)) then specialDay = "valentine" end
		if (string.find(botman.serverTime, "12-25", 5, 10)) then specialDay = "christmas" end
	end
end
