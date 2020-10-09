--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
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

	if tonumber(limit) > 1 then
		stackLimits[item] = {}
		stackLimits[item].limit = tonumber(limit)
	end

	id = LookupPlayer(id)
	if id ~= 0 then
		players[id].overstack = true

		if not string.find(item, players[id].overstackItems) then
			players[id].overstackItems = players[id].overstackItems .. item .. "|"
		end
	end
end
