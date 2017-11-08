--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function listEntities(line)
	-- 13. id=2647, [type=EntityZombie, name=zombieBoe, id=2647], pos=(-97.3, 128.0, 195.5), rot=(0.0, 2.3, 0.0), lifetime=float.Max, remleote=False, dead=False, health=200

	local temp, zedID, zedType, zedName, zedX, zedY, zedZ, zedDead, zedHealth, loc, removedID

	temp = string.split(line, ",")
	removedID = 0

	if not (string.find(temp[2], "Item") or string.find(temp[2], "Player")) then
		zedID = string.sub(temp[1], string.find(temp[1], "id=") + 3)
		zedType = string.sub(temp[2], string.find(temp[2], "type=") + 5)
		zedName = string.sub(temp[3], string.find(temp[3], "name=") + 5)
		zedNameLower = string.lower(zedName)
		zedX = string.sub(temp[5], string.find(temp[5], "pos") + 5)
		zedY = temp[6]
		zedZ = string.sub(temp[7], 1, string.len(temp[7]) - 1)
		zedDead=0
		zedHealth = string.sub(temp[14], string.find(temp[14], "health=") + 7)

		if temp[13] == " dead=False" then
			loc = inLocation(zedX, zedZ)

			if loc ~= false then
				if locations[loc].killZombies and (string.find(zedNameLower, "zombie") or string.find(zedNameLower, "animal") or string.find(zedNameLower, "bandit")) then
					if not string.find(zedNameLower, "chicken") and not string.find(zedNameLower, "rabbit") and not string.find(zedNameLower, "stag") and not string.find(zedNameLower, "boar") and not string.find(zedNameLower, "pig") then
						send("removeentity " .. zedID)
						removedID = zedID
					end
				end
			end

			if removedID == 0 then
				conn:execute("INSERT INTO memEntities (entityID, type, name, x, y, z, dead, health) VALUES (" .. zedID .. ",'" .. zedType .. "','" .. zedName .. "'," .. zedX .. "," .. zedY .. "," .. zedZ .. "," .. zedDead .. "," .. zedHealth .. ")")
			end
		else
			conn:execute("DELETE FROM memEntities WHERE entityID = " .. zedID)
		end
	end
end