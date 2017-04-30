--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function inventoryOwner(line)
	if botman.botDisabled then
		return
	end

	local pname

	pname = string.sub(line, string.find(line, "player ") + 7)
	pname = string.sub(pname, 1, string.len(pname) - 1)

	invCheckID = LookupPlayer(pname, "all") 

	if (string.find(line, "Belt of player")) then
		if (igplayers[invCheckID].inventoryLast ~= igplayers[invCheckID].inventory) then
			igplayers[invCheckID].inventoryLast = igplayers[invCheckID].inventory
		end

		igplayers[invCheckID].inventory = ""
		igplayers[invCheckID].oldBelt = igplayers[invCheckID].belt
		igplayers[invCheckID].belt = ""
		igplayers[invCheckID].pack = ""
		igplayers[invCheckID].equipment = ""
		invScan = "belt"
	end

	if (string.find(line, "Bagpack of player")) then
		invScan = "bagpack"
	end

	if (string.find(line, "Equipment of player")) then
		invScan = "equipment"
	end
end
