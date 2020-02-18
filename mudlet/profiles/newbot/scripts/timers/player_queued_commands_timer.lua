--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function playerQueuedCommands()
	local cursor, errorString, row, k, v, a, b, steam, command, dist

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected or not botman.arenaCount then
		return
	end

	if botman.gimmeDifficulty == 1 then
		cursor,errorString = conn:execute("select *, UNIX_TIMESTAMP(delayTimer) AS delay from playerQueue order by id limit 0,1")
	else
		cursor,errorString = conn:execute("select *, UNIX_TIMESTAMP(delayTimer) AS delay from playerQueue order by id limit 0," .. botman.arenaCount)
	end

	if not cursor then
		return
	end

	row = cursor:fetch({}, "a")

	if row then
		while row do
			steam = row.steam
			command = row.command

			if tonumber(steam) == 0 then
				if row.delay - os.time() > 0 then
					return
				end

				conn:execute("delete from playerQueue where id = " .. row.id)

				if command == "reset" then
					resetGimmeArena()
				else
					for a, b in pairs(arenaPlayers) do
						dist = distancexz(igplayers[a].xPos, igplayers[a].zPos, locations["arena"].x, locations["arena"].z)

						if (tonumber(dist) <= tonumber(locations["arena"].size)) then
							message("pm " .. b.steam .. " [" .. server.chatColour .. "]" .. command .. "[-]")
						end
					end
				end

				return
			end

			if tonumber(steam) > 0 then
				if (not igplayers[steam]) then
					-- destroy the command without sending it
					conn:execute("delete from playerQueue where id = " .. row.id)
					return
				end
			end

			if (distancexz(igplayers[steam].xPos, igplayers[steam].zPos, locations["arena"].x, locations["arena"].z ) > locations["arena"].size + 1 or igplayers[steam].deadX ~= nil) then
				-- destroy the command without sending it
				conn:execute("delete from playerQueue where id = " .. row.id)
				return
			else
				conn:execute("delete from playerQueue where id = " .. row.id)

				if (tonumber(steam) > 0) then
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
		conn:execute("delete from playerQueue where id = " .. row.id)
	else
		-- if the arena game fails to stop when the table is empty, stop the arena game
		if botman.gimmeHell == 1 then
			botman.gimmeHell = 0
		end
	end
end
