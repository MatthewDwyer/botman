--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function overstackTrigger(line)
	if botman.botDisabled then
		return
	end

	local item, limit, id

	id = string.sub(line, string.find(line, " ID ") + 4, string.find(line, " has") - 1)
	item = string.sub(line, string.find(line, "stack for ") + 11, string.find(line, "greater") - 3)
	limit = string.sub(line, string.find(line, " > ") + 3, string.len(line) - 1)

	stackLimits[item] = {}
	stackLimits[item].limit = tonumber(limit)

	id = LookupPlayer(id)
	if id ~= nil then
		players[id].overstack = true

		if not string.find(item, players[id].overstackItems) then
			players[id].overstackItems = players[id].overstackItems .. item .. "|"
		end
	end
end
