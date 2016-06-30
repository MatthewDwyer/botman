--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function oneMinuteTimer()
	-- run a quick test to prove or disprove that we are still connected to the database.
	-- there is a rare instance where we lose the connection for unknown reasons.
	dbConnected = isDBConnected()

	if botDisabled then
		return
	end

	OneMinuteTimer()

	if tablelength(players) == 0 then
		gatherServerData()
		return
	end

	if server.coppi then
		for k, v in pairs(igplayers) do
	--		if players[k].autoFriend ~= "NA" then
	--			send("lpf " .. k)
	--		end
		end
	end

	if not botDisabled then
		writeBotTick()
	end

	if tonumber(playersOnline) > 9 then
		if scanZombies then send("le") end
	end
end
