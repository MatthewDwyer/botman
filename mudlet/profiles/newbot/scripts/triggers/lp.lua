--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function lpTrigger(line)
	if botDisabled then
		return
	end

	if string.find(string.sub(line, 1, 19), os.date("%Y")) then
		serverTime = string.sub(line, 1, 19)
		specialDay = ""

		if (string.find(serverTime, "02-14", 5, 10)) then specialDay = "valentine" end
		if (string.find(serverTime, "12-25", 5, 10)) then specialDay = "christmas" end
	end
end
