--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function airDropAlert(line)
	if botman.botDisabled then
		return
	end

	if not server.enableAirdropAlert then
		return
	end

	local test, dist, direction, coord, k, v, r

	if string.find(line, "Spawned supply crate at") then
		test = string.sub(line, string.find(line, "crate at (", nil, true) + 11)
		test = string.sub(test, 1, string.find(test, "), plane", nil, true) - 1)
	else
		test = string.sub(line, string.find(line, "@") + 4)
		test = string.sub(test, 1, string.len(test) - 2)
	end

	coord = string.split(test, ",")

	for k, v in pairs(igplayers) do
		dist = distancexz(v.xPos, v.zPos, coord[1], coord[3])
		if (tonumber(dist) < 2000) then
			direction = getCompass(v.xPos, v.zPos, coord[1], coord[3])

			r = randSQL(100)
			if r > 90 then
				message("pm " .. v.userID .. " " ..  " [" .. server.chatColour .. "]Ze plane! Ze plane![-]")
			end

			message("pm " .. v.userID .. " " ..  " [" .. server.chatColour .. "]Supplies have been dropped " .. math.floor(dist) .. " meters to the " .. direction .."![-]")
		end
	end
end
