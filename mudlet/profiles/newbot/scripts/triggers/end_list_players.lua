--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function endListPlayers(line)
	local cursor, errorString, row, k, v, freeSlots

	if botman.botDisabled then
		return
	end

	-- this check should not be needed but just in case future telnet messages start with 'Total of', we only want the list players count.
	if not string.find(line, "in the game", nil, true) then
		return
	end

	if not server.useAllocsWebAPI then
		if botman.readingLKP then
			botman.readingLKP = nil

			if botman.archivePlayers then
				botman.archivePlayers = nil

				--	Everyone who is flagged notInLKP gets archived.
				for k,v in pairs(players) do
					if v.notInLKP then
						if botman.dbConnected then connSQL:execute("INSERT INTO miscQueue (steam, command) VALUES ('" .. k .. "', 'archive player')") end
						botman.miscQueueEmpty = false
					end
				end
			end
		end

		if botman.listPlayers and not botman.listEntities then
			botman.playersOnline = tonumber(string.match(line, "%d+"))
			botStatus.playersOnline = botman.playersOnline

			if not botman.playersOnline then
				botman.playersOnline = 0
				botStatus.playersOnline = 0
			end

			playerConnectCounter = botman.playersOnline

			if (botman.playersOnline == 0) then
				-- we could schedule something to happen when no players are online
			end

			if botman.trackingTicker == nil then
				botman.trackingTicker = 0
			end

			if tonumber(botman.trackingTicker) > 2 then
				botman.trackingTicker = 0
			end

			botman.listPlayers = false

			if tonumber(server.reservedSlots) > 0 then
				if botman.initReservedSlots then
					initSlots()

					botman.initReservedSlots = false
				end
			end
		end

		if botman.listEntities then
			botman.listEntities = false
		end

		-- reset relogCount as we have established that the server is talking to us
		relogCount = 0
	end
end
