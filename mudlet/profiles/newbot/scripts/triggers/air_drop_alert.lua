--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function airDropAlert(line)
	if botman.botDisabled then
		return
	end

	local test, dist, direction, coord, k, v, r

	test = string.sub(line, string.find(line, "@") + 4)
	test = string.sub(test, 1, string.len(test) - 2)
	coord = string.split(test, ",")

	for k, v in pairs(igplayers) do
		dist = distancexz(v.xPos, v.zPos, coord[1], coord[3])
		if (tonumber(dist) < 800) then
			direction = getCompass(v.xPos, v.zPos, coord[1], coord[3])
			
			r = rand(100)
			if r > 90 then
				message("pm " .. k .. " " ..  " [" .. server.chatColour .. "]Ze plane! Ze plane![-]")			
			end
			
			message("pm " .. k .. " " ..  " [" .. server.chatColour .. "]Supplies have been dropped " .. math.floor(dist) .. " meters to the " .. direction .."![-]")
		end
	end
end
