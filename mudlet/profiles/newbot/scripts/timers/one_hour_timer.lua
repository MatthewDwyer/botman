--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function oneHourTimer()
	local k, v

	if botman.botDisabled then
		return
	end

	OneHourTimer()
	dailyMaintenance()

	-- fix any problems with player records
	for k,v in pairs(players) do
		fixMissingPlayer(k)
	end
end
