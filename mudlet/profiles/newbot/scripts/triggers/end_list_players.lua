--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function endListPlayers(line)
	local cursor, errorString, row
	local freeSlots

	if botman.botDisabled then
		return
	end

	if botman.listPlayers and not botman.listEntities then
		botman.playersOnline = tonumber(string.match(line, "%d+"))
		playerConnectCounter = botman.playersOnline

		if (botman.playersOnline == 0) then
			-- we could schedule something to happen when no players are online
		end

		if tonumber(server.botID) > 0 then
			for k,v in pairs(igplayers) do
				insertBotsPlayer(k)
			end
		end

		botman.listPlayers = false
	end

	if botman.listEntities then
		botman.listEntities = false
	end

	-- reset relogCount as we have established that the server is talking to us
	relogCount = 0


	if tonumber(server.reservedSlots) > 0 then
		freeSlots = server.maxPlayers - botman.playersOnline
		server.reservedSlotsUsed = server.reservedSlots - freeSlots

		if tonumber(server.reservedSlotsUsed) < 0 then
			server.reservedSlotsUsed = 0
		end

		if botman.initReservedSlots then
			initReservedSlots()
		end

		if botman.dbReservedSlotsUsed == nil then
			cursor,errorString = conn:execute("select count(steam) as totalRows from reservedSlots")
			row = cursor:fetch({}, "a")
			botman.dbReservedSlotsUsed = tonumber(row.totalRows)
		end

		if tonumber(botman.dbReservedSlotsUsed) > tonumber(server.reservedSlotsUsed) then
			updateReservedSlots(botman.dbReservedSlotsUsed)
		end
	else
		server.reservedSlotsUsed = 0
		botman.dbReservedSlotsUsed = 0
	end
end
