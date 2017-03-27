--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function endListPlayers(line)
	if botman.botDisabled then
		return
	end

	if botman.listPlayers and not botman.listEntities then	
		showPlayers = false
		botman.playersOnline = tonumber(string.match(line, "%d+"))
		playerConnectCounter = botman.playersOnline
		deleteLine()		
		
		server.reservedSlotsUsed = tonumber(botman.playersOnline) - (tonumber(server.maxPlayers) - tonumber(server.reservedSlots))	
		if server.reservedSlotsUsed < 0 then
			server.reservedSlotsUsed = 0
		end

		if (botman.playersOnline == 0) then
			-- we could schedule something to happen when no players are online
		else
			if tonumber(server.reservedSlotsUsed) == 0 and tonumber(server.reservedSlots) > 0 then
				updateReservedSlots()	
			end
		end
		botman.listPlayers = false	
	end	
	
	if botman.listEntities then
		botman.listEntities = false		
	end

	-- reset relogCount as we have established that the server is talking to us
	relogCount = 0
end
