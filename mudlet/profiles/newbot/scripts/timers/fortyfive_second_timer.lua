--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyerbotman
--]]

function fortyfiveSecondTimer()
	local k, v, x, z, row, cursor, errorString

	if botman.botDisabled or botman.botOffline or not botman.dbConnected then
		return
	end

	if customFortyfiveSecondTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customFortyfiveSecondTimer() then
			return
		end
	end
end
