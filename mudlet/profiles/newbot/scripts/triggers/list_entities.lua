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

	local temp, zedID, zedX, zedY, zedZ, zedDead, loc

	temp = string.split(line, ",")

	if temp[13] == " dead=False" and not (string.find(temp[2], "Item") or string.find(temp[2], "Player")) then
		zedID = string.sub(temp[1], string.find(temp[1], "id=") + 3)
		zedX = string.sub(temp[5], string.find(temp[5], "pos") + 5)
		zedY = temp[6]
		zedZ = string.sub(temp[7], 1, string.len(temp[7]) - 1)

		loc = inLocation(zedX, zedZ)

		if loc ~= false then
			if locations[loc].killZombies then
				send("removeentity " .. zedID)
			end
		end
	end

	-- do some checks with where players and items are.  want to detect item spawn cheaters
	if string.find(temp[2], "Item") or string.find(temp[2], "Player") then

	end
end