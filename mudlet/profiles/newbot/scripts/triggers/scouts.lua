--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]


function scoutsWarning(line)
	local dist, direction, pos
	local tmp = {}
	local numbers = {}

	if botman.botDisabled then
		return
	end

	if not server.enableScreamerAlert then
		return
	end

	-- we need to remove everything before INF for the gmatch below to work correctly.
	pos = string.find(line, "INF")
	line = string.sub(line, pos)

	-- Iterate through all matches in the string
	for number in line:gmatch("(-?%d+%.?%d*)") do
		-- Convert the matched string to a number and add it to the table
		table.insert(numbers, tonumber(number))
	end

	tmp.spawnX = numbers[1]
	tmp.spawnZ = numbers[3]
	tmp.destX = numbers[4]
	tmp.destZ = numbers[6]

	for k, v in pairs(igplayers) do
		direction = getCompass(v.xPos, v.zPos, tmp.spawnX, tmp.spawnZ)
		dist = distancexz(v.xPos, v.zPos, tmp.destX, tmp.destZ)

		if (dist < 200) then
			message("pm " .. v.userID .. " " ..  " [" .. server.chatColour .. "]Screamers have been detected heading your way from the " .. direction .. ".[-]")
		end
	end
end
