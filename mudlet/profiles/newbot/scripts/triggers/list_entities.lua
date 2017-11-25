--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function listEntities(line, mod)
	-- 13. id=2647, [type=EntityZombie, name=zombieBoe, id=2647], pos=(-97.3, 128.0, 195.5), rot=(0.0, 2.3, 0.0), lifetime=float.Max, remleote=False, dead=False, health=200

	local temp, zedID, zedType, zedName, zedX, zedY, zedZ, zedDead, zedHealth, loc, removedID

	removedID = 0

	if mod == "BCM" then
		zedID = string.sub(line, string.find(line, "[", nil, true) + 1, string.find(line,"]", nil, true) - 1)
		zedName = string.sub(line, string.find(line, "Detected") + 9, string.find(line,"[", nil, true) - 1)

		zedNameLower = string.lower(zedName)
		zedType = string.sub(line, string.find(line, "Entity"), string.find(line, ")@", nil, true) - 1)
		temp = string.sub(line, string.find(line, "@") + 1)
		temp = string.split(temp, " ")
		zedX = temp[1]
		zedY = temp[2]
		zedZ = temp[3]

		-- don't despawn players with zombie in their name xD
		if zedType ~= "EntityPlayer" then
			loc = inLocation(zedX, zedZ)

			if loc ~= false then
				if locations[loc].killZombies then
					if string.find(zedNameLower, "zombie") or string.find(zedNameLower, "animal") or string.find(zedNameLower, "bandit") then
						if (not string.find(zedNameLower, "chicken")) and (not string.find(zedNameLower, "rabbit")) and (not string.find(zedNameLower, "stag")) and (zedName ~= "animalBoar") then
							send("removeentity " .. zedID)

							if botman.getMetrics then
								metrics.telnetCommands = metrics.telnetCommands + 1
							end

							removedID = zedID
						end
					end
				end
			end
		end

		if removedID == 0 then
			conn:execute("INSERT INTO memEntities (entityID, type, name, x, y, z, dead, health) VALUES (" .. zedID .. ",'" .. zedType .. "','" .. zedName .. "'," .. zedX .. "," .. zedY .. "," .. zedZ .. "," .. zedDead .. "," .. zedHealth .. ")")
		end

		return
	end

	if mod == nil then
		temp = string.split(line, ",")

		zedID = string.sub(temp[1], string.find(temp[1], "id=") + 3)
		zedType = string.sub(temp[2], string.find(temp[2], "type=") + 5)
		zedName = string.sub(temp[3], string.find(temp[3], "name=") + 5)
		zedNameLower = string.lower(zedName)
		zedX = string.sub(temp[5], string.find(temp[5], "pos") + 5)
		zedY = temp[6]
		zedZ = string.sub(temp[7], 1, string.len(temp[7]) - 1)
		zedDead=0
		zedHealth = string.sub(temp[14], string.find(temp[14], "health=") + 7)

		if zedName == "EntityFallingBlock" then
			zedX = string.trim(string.sub(temp[3], 7))
			zedY = string.trim(temp[4])
			zedZ = string.trim(string.sub(temp[5], 1, string.len(temp[5]) - 1))

			zedX = math.floor(zedX)
			zedY = math.floor(zedY)
			zedZ = math.floor(zedZ)

			temp = getRegion(zedX,zedZ)
			if not fallingBlocks[temp] then
				fallingBlocks[temp] = {}
				fallingBlocks[temp].count = 1
				fallingBlocks[temp].x = zedX
				fallingBlocks[temp].y = zedY
				fallingBlocks[temp].z = zedZ
			else
				fallingBlocks[temp].count = fallingBlocks[temp].count + 1
				fallingBlocks[temp].x = zedX
				fallingBlocks[temp].y = zedY
				fallingBlocks[temp].z = zedZ
			end

			return
		end

		if temp[13] == " dead=False" then
			-- don't despawn players with zombie in their name xD
			if not string.find(line, "EntityPlayer") then
				loc = inLocation(zedX, zedZ)

				if loc ~= false then
					if locations[loc].killZombies then
						if string.find(zedNameLower, "zombie") or string.find(zedNameLower, "animal") or string.find(zedNameLower, "bandit") then
							if (not string.find(zedNameLower, "chicken")) and (not string.find(zedNameLower, "rabbit")) and (not string.find(zedNameLower, "stag")) and (zedName ~= "animalBoar") then
								if not server.lagged then
									send("removeentity " .. zedID)

									if botman.getMetrics then
										metrics.telnetCommands = metrics.telnetCommands + 1
									end

									removedID = zedID
								end
							end
						end
					end
				end
			end

			if removedID == 0 then
				conn:execute("INSERT INTO memEntities (entityID, type, name, x, y, z, dead, health) VALUES (" .. zedID .. ",'" .. zedType .. "','" .. zedName .. "'," .. zedX .. "," .. zedY .. "," .. zedZ .. "," .. zedDead .. "," .. zedHealth .. ")")
			end
		end
	end
end