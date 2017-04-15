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
	
	-- Flag all players as offline so we don't have any showing as online who left without being updated
	if tonumber(server.botID) > 0 then
		connBots:execute("UPDATE players set online = 0 WHERE botID = " .. server.botID)		
	end

	-- fix any problems with player records
	for k,v in pairs(players) do
		fixMissingPlayer(k)
	end
end
