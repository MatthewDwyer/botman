--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function endListPlayers(line)
	if botDisabled then
		return
	end

	showPlayers = false
	playersOnline = tonumber(string.match(line, "%d+"))
	deleteLine()

	if (playersOnline == 0) then
		-- we could schedule something to happen when no players are online
	end

	-- reset relogCount as we have established that the server is talking to us
	relogCount = 0
end
