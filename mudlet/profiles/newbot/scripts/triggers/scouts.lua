--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function scoutsWarning(line)
	if botman.botDisabled then
		return
	end

	local test, dist, xStart, zStart, xEnd, zEnd, direction

	if string.find(line, "towards") then
		-- get the origin coords
		test = string.sub(line, string.find(line, "scouts") + 11, string.find(line, "heading") - 4)
		split = string.split(test, ",")
		xStart = string.match(split[1], "-?%d+")
		zStart = string.match(split[3], "-?%d+")

		-- get the destination coords
		test = string.sub(line, string.find(line, "towards") + 7)
		split = string.split(test, ",")
		xEnd = string.match(split[1], "-?%d+")
		zEnd = string.match(split[3], "-?%d+")

		if (string.find(line, "heading towards")) then
			for k, v in pairs(igplayers) do
				direction = getCompass(v.xPos, v.zPos, xStart, zStart)
				dist = distancexz(v.xPos, v.zPos, xEnd, zEnd)

				if (dist < 50) then
					message("pm " .. k .. " " ..  " [" .. server.chatColour .. "]Screamers have been detected heading your way from the " .. direction .. ".[-]")
				end
			end
		end
	end
end
