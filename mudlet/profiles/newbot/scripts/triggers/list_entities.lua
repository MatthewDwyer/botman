--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function listEntities(line, mod)
	-- 13. id=2647, [type=EntityZombie, name=zombieBoe, id=2647], pos=(-97.3, 128.0, 195.5), rot=(0.0, 2.3, 0.0), lifetime=float.Max, remleote=False, dead=False, health=200

	local temp, zedID, zedType, zedName, zedX, zedY, zedZ, zedDead, zedHealth, loc, removedID, tmp

	removedID = 0
	tmp = {}

	if not string.find(line, "id=") then
		return
	end

	if mod == "BCM" then
		tmp.zedID = string.sub(line, string.find(line, "[", nil, true) + 1, string.find(line,"]", nil, true) - 1)
		tmp.zedName = string.sub(line, string.find(line, "Detected") + 9, string.find(line,"[", nil, true) - 1)

		tmp.zedNameLower = string.lower(tmp.zedName)
		tmp.zedType = string.sub(line, string.find(line, "Entity"), string.find(line, ")@", nil, true) - 1)
		temp = string.sub(line, string.find(line, "@") + 1)
		temp = string.split(temp, " ")
		tmp.zedX = string.trim(temp[1])
		tmp.zedY = string.trim(temp[2])
		tmp.zedZ = string.trim(temp[3])

		-- don't despawn players with zombie in their name xD
		if tmp.zedType ~= "EntityPlayer" then
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
			connMEM:execute("INSERT INTO memEntities (entityID, type, name, x, y, z, dead, health) VALUES (" .. tmp.zedID .. ",'" .. tmp.zedType .. "','" .. tmp.zedName .. "'," .. tmp.zedX .. "," .. tmp.zedY .. "," .. tmp.zedZ .. "," .. tmp.zedDead .. "," .. tmp.zedHealth .. ")")
		end

		return
	end

	if mod == nil then
		temp = string.split(line, ",")

		tmp.zedID = string.sub(temp[1], string.find(temp[1], "id=") + 3)
		tmp.zedType = string.sub(temp[2], string.find(temp[2], "type=") + 5)
		tmp.zedName = string.sub(temp[3], string.find(temp[3], "name=") + 5)
		tmp.zedNameLower = string.lower(tmp.zedName)
		tmp.zedX = string.sub(temp[5], string.find(temp[5], "pos") + 5)
		tmp.zedY = string.trim(temp[6])
		tmp.zedZ = string.trim(string.sub(temp[7], 1, string.len(temp[7]) - 1))
		tmp.zedDead=0
		tmp.zedHealth = string.sub(temp[14], string.find(temp[14], "health=") + 7)

		if temp[13] == " dead=False" then
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
				connMEM:execute("INSERT INTO memEntities (entityID, type, name, x, y, z, dead, health) VALUES (" .. tmp.zedID .. ",'" .. tmp.zedType .. "','" .. tmp.zedName .. "'," .. tmp.zedX .. "," .. tmp.zedY .. "," .. tmp.zedZ .. "," .. tmp.zedDead .. "," .. tmp.zedHealth .. ")")
			end
		end
	end
end