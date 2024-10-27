--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function inventoryOwner(line)
	local pname

	if botman.botDisabled then
		return
	end

	if server.useAllocsWebAPI then
		return
	end

	pname = string.sub(line, string.find(line, "player ") + 7)
	pname = string.sub(pname, 1, string.len(pname) - 1)

	invCheckID = LookupPlayer(pname, "all")

	if invCheckID ~= "0" then
		if (string.find(line, "Belt of player")) then
			if (igplayers[invCheckID].inventoryLast ~= igplayers[invCheckID].inventory) then
				igplayers[invCheckID].inventoryLast = igplayers[invCheckID].inventory
			end

			igplayers[invCheckID].inventory = ""
			igplayers[invCheckID].oldBelt = igplayers[invCheckID].belt
			igplayers[invCheckID].belt = ""
			igplayers[invCheckID].oldPack = igplayers[invCheckID].pack
			igplayers[invCheckID].pack = ""
			igplayers[invCheckID].oldEquipment = igplayers[invCheckID].equipment
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
end
