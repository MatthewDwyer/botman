--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function endListPlayers(line)
	local cursor, errorString, row, k, v, freeSlots

	if botman.botDisabled then
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
						if botman.dbConnected then conn:execute("INSERT into miscQueue (steam, command) VALUES (" .. k .. ", 'archive player')") end
					end
				end
			end
		end

		if botman.listPlayers and not botman.listEntities then
			botman.playersOnline = tonumber(string.match(line, "%d+"))

			if not botman.playersOnline then
				botman.playersOnline = 0
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

			if botman.initReservedSlots then
				initSlots()

				-- for k,v in pairs(igplayers) do
					-- assignASlot(k)
				-- end

				botman.initReservedSlots = false
			end
		end

		if botman.listEntities then
			botman.listEntities = false
		end

		-- reset relogCount as we have established that the server is talking to us
		relogCount = 0
	end
end
