--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function playerQueuedCommands()
	if botDisabled then
		return
	end

	cursor,errorString = conn:execute("select * from playerQueue order by id limit 0,1")
	row = cursor:fetch({}, "a")

	if row then
		if row.boss == true then
			for k, v in pairs(igplayers) do
				if distancexz(igplayers[k].xPos, igplayers[k].zPos, locations["arena"].x, locations["arena"].z) then
					for a, b in pairs(arenaPlayers) do
						message("pm " .. players[b.id].id .. " [" .. server.chatColour .. "]Here comes the BOSS!")
					end

					cecho(server.windowDebug, "running player queued command " .. row.command .. "\n")
					send(row.command)	
					conn:execute("delete from playerQueue where id = " .. row.id)
					return
				end
			end

			return	
		end

		if tonumber(row.steam) > 0 and (not igplayers[row.steam]) then
			-- destroy the command without sending it
			cecho(server.windowDebug, "destroying player queued command " .. row.command .. "\n")
			conn:execute("delete from playerQueue where id = " .. row.id)
			return
		end

		if tonumber(row.steam) == 0 then
			if (string.sub(row.command, 1, 2) ~= "se") and (string.sub(row.command, 1, 3) ~= "say") and (string.sub(row.command, 1, 2) ~= "pm") and (row.command ~= "reset") then
				send(row.command)	
			else
				if row.command == "reset" then
					resetGimmeHell()
				else
					message(row.command)
				end
			end

			conn:execute("delete from playerQueue where id = " .. row.id)
			return
		end

		if (distancexz(igplayers[row.steam].xPos, igplayers[row.steam].zPos, locations["arena"].x, locations["arena"].z ) > locations["arena"].size + 1 or igplayers[row.steam].deadX ~= nil) then
			-- destroy the command without sending it
			cecho(server.windowDebug, "destroying player queued command " .. row.command .. "\n")
			conn:execute("delete from playerQueue where id = " .. row.id)
			return
		else
			if (tonumber(row.steam) > 0) then
				if (igplayers[row.steam].deadX == nil) then
					cecho(server.windowDebug, "running player queued command " .. row.command .. "\n")

					if string.sub(row.command, 1, 2) == "se" then
						send(row.command)	
					else
						 message(row.command)	
					end

					conn:execute("delete from playerQueue where id = " .. row.id)
					return
				end
			else
				cecho(server.windowDebug, "running player queued command " .. row.command .. "\n")

				if string.sub(row.command, 1, 2) == "se" then
					send(row.command)	
				else
					 message(row.command)	
				end

				conn:execute("delete from playerQueue where id = " .. row.id)
				return
			end
		end

		conn:execute("delete from playerQueue where id = " .. row.id)
	end
end
