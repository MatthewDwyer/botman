--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function listEntities(line)
	-- 13. id=2647, [type=EntityZombie, name=zombieBoe, id=2647], pos=(-97.3, 128.0, 195.5), rot=(0.0, 2.3, 0.0), lifetime=float.Max, remleote=False, dead=False, health=200

	local temp, zedID, zedType, zedName, zedX, zedY, zedZ, zedDead, zedHealth, loc, removedID, tmp, i

	if botman.nullrefDetected then
		botman.nullrefDetected = nil
		botman.nullRefDetectedDelay = os.time() + 90 -- check the spawned entities again in 90 seconds
	end

	removedID = 0
	tmp = {}

	if not string.find(line, "id=") then
		return
	end

	temp = string.split(line, ",")
	i = 1
	tmp.zedDead = 1
	tmp.zedHealth = 0

	while temp[i] do
		if string.find(temp[i], " id=") then
			tmp.zedID = string.sub(temp[i], string.find(temp[i], "id=") + 3)
			tmp.zedID = tonumber(string.match(tmp.zedID, "(-?%d+)"))
		end

		if string.find(temp[i], "type=") then
			tmp.zedType = string.sub(temp[i], string.find(temp[i], "type=") + 5)
		end

		if string.find(temp[i], "name=") then
			tmp.zedName = string.sub(temp[i], string.find(temp[i], "name=") + 5)
			tmp.zedNameLower = string.lower(tmp.zedName)
		end

		if string.find(temp[i], "health=") then
			tmp.zedHealth = tonumber(string.sub(temp[i], string.find(temp[i], "health=") + 7))
		end

		if string.find(temp[i], "dead=False") then
			tmp.zedDead = 0
		end

		if string.find(temp[i], "pos=") then
			tmp.zedX = tonumber(string.match(temp[i], "(-?%d+)"))
			tmp.zedY = tonumber(string.match(temp[i+1], "(-?%d+)"))
			tmp.zedZ = tonumber(string.match(temp[i+2], "(-?%d+)"))
			i = i + 2
		end

		i = i + 1
	end

	if string.find(tmp.zedName, "emplate") or string.find(tmp.zedName, "Test") or string.find(tmp.zedName, "playerNewMale") then
		-- remove these entities because they cause nullrefs
		removeEntityCommand(tmp.zedID)
		removedID = tmp.zedID
	end

	if tmp.zedDead == 0 then
		-- don't despawn players with zombie in their name xD
		if not string.find(line, "EntityPlayer") then
			loc = inLocation(tmp.zedX, tmp.zedZ)

			if loc ~= false then
				if locations[loc].killZombies then
					if string.find(tmp.zedNameLower, "zombie") or string.find(tmp.zedNameLower, "animal") or string.find(tmp.zedNameLower, "bandit") then
						if (not string.find(tmp.zedNameLower, "chicken")) and (not string.find(tmp.zedNameLower, "rabbit")) and (not string.find(tmp.zedNameLower, "stag")) and (tmp.zedName ~= "animalBoar") then
							removeEntityCommand(tmp.zedID)
							removedID = tmp.zedID
						end
					end
				end
			end
		end

		if removedID == 0 then
			connMEM:execute("INSERT INTO entities (entityID, type, name, x, y, z, dead, health) VALUES (" .. tmp.zedID .. ",'" .. tmp.zedType .. "','" .. tmp.zedName .. "'," .. tmp.zedX .. "," .. tmp.zedY .. "," .. tmp.zedZ .. "," .. tmp.zedDead .. "," .. tmp.zedHealth .. ")")
		end
	end
end