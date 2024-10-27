--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function playerQueuedCommands()
	local cursor, errorString, row, k, v, a, b, steam, command, dist, arena

	if botman.playerQueueEmpty == nil then
		botman.playerQueueEmpty = false
	end

	if botman.playerQueueEmpty then
		return
	end

	if botman.botDisabled or botman.botOffline or not botman.dbConnected or not botman.arenaCount then
		return
	end

	if botman.gimmeDifficulty == 1 then
		cursor,errorString = connSQL:execute("SELECT * FROM playerQueue ORDER BY id LIMIT 1")
	else
		cursor,errorString = connSQL:execute("SELECT * FROM playerQueue ORDER BY id LIMIT " .. botman.arenaCount)
	end

	if not cursor then
		return
	end

	row = cursor:fetch({}, "a")

	if not row then
		botman.playerQueueEmpty = true
	end

	if row then
		arena = LookupLocation("arena")

		while row do
			steam = row.steam
			command = row.command

			if steam == "0" then
				if row.delayTimer - os.time() > 0 then
					return
				end

				connSQL:execute("DELETE FROM playerQueue WHERE id = " .. row.id)

				if command == "reset" then
					resetGimmeArena()
				else
					for a, b in pairs(arenaPlayers) do
						dist = distancexz(igplayers[a].xPos, igplayers[a].zPos, locations[arena].x, locations[arena].z)

						if (tonumber(dist) <= tonumber(locations[arena].size)) then
							message("pm " .. players[b.steam].userID .. " [" .. server.chatColour .. "]" .. command .. "[-]")
						end
					end
				end

				return
			end

			if steam ~= "0" then
				if (not igplayers[steam]) then
					-- destroy the command without sending it
					connSQL:execute("DELETE FROM playerQueue WHERE id = " .. row.id)
					return
				end
			end

			if (distancexz(igplayers[steam].xPos, igplayers[steam].zPos, locations[arena].x, locations[arena].z ) > locations[arena].size + 1 or igplayers[steam].deadX ~= nil) then
				-- destroy the command without sending it
				connSQL:execute("DELETE FROM playerQueue WHERE id = " .. row.id)
				return
			else
				connSQL:execute("DELETE FROM playerQueue WHERE id = " .. row.id)

				if steam ~= "0" then
					if (igplayers[steam].deadX == nil) then
						if string.sub(command, 1, 2) == "se" then
							sendCommand(command)
						else
							 message(command)
						end

						return
					end
				else
					if string.sub(command, 1, 2) == "se" then
						sendCommand(command)
					else
						 message(command)
					end

					return
				end
			end

			row = cursor:fetch(row, "a")
		end

		-- we can probably remove this line but just incase none of the tests above delete it, we'll try to delete the row here too.
		connSQL:execute("DELETE FROM playerQueue WHERE id = " .. row.id)
	else
		-- if the arena game fails to stop when the table is empty, stop the arena game
		if botman.gimmeHell == 1 then
			botman.gimmeHell = 0
		end
	end
end
