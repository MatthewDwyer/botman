--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function miscCommandsTimer()
	local cursor, errorString, row

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	cursor,errorString = conn:execute("SELECT * FROM miscQueue WHERE timerDelay = '0000-00-00 00:00:00'  ORDER BY id limit 0,1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			if string.find(row.command, "admin add") then
				send(row.command)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				irc_chat(server.ircMain, "Player " .. players[row.steam].name .. " has been given admin.")
				setChatColour(row.steam)
			end

			if string.find(row.command, "ban remove") then
				send(row.command)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				irc_chat(server.ircMain, "Player " .. players[row.steam].name .. " has been unbanned.")
			end

			if string.find(row.command, "tele ") then
				if igplayers[row.steam] then
					teleport(row.command, row.steam)
				end
			else
				send(row.command)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end

			conn:execute("DELETE FROM miscQueue WHERE id = " .. row.id)
		end
	end

	-- check all the delayed commands.  send any that are not in the future
	cursor,errorString = conn:execute("SELECT id, steam, command, action, value, UNIX_TIMESTAMP(timerDelay) AS delay FROM miscQueue WHERE timerDelay <> '0000-00-00 00:00:00' ORDER BY id")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			while row do
				if row.delay - os.time() <= 0 then
					if string.sub(row.command, 1, 3) == "pm " or string.sub(row.command, 1, 3) == "say" then
						message(row.command)

						if string.find(row.command, "admin status") then
							irc_chat(server.ircMain, "OH GOD NOOOO! " .. players[row.steam].name .. "'s admin status has been restored.")
						end
					else
						if string.find(row.command, "tele ") then
							if igplayers[row.steam] then
								teleport(row.command, row.steam)
							end
						else
							send(row.command)

							if botman.getMetrics then
								metrics.telnetCommands = metrics.telnetCommands + 1
							end
						end
					end

					conn:execute("DELETE FROM miscQueue WHERE id = " .. row.id)
				end

				row = cursor:fetch(row, "a")
			end
		end
	end
end


function gimmeQueuedCommands()
	local pid, dist1, dist2, cursor1, cursor1, errorString, row1, row2

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	cursor1,errorString = conn:execute("SELECT DISTINCT steam FROM gimmeQueue")

	if cursor1 then
		row1 = cursor1:fetch({}, "a")

		while row1 do
			if not igplayers[row1.steam] then
				conn:execute("DELETE FROM gimmeQueue WHERE steam = " .. row1.steam)
			else
				cursor2,errorString = conn:execute("SELECT * FROM gimmeQueue WHERE steam = " .. row1.steam .. " ORDER BY id limit 0,1")

				if cursor2 then
					row2 = cursor2:fetch({}, "a")

					if row2 then
						send(row2.command)

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end

						conn:execute("DELETE FROM gimmeQueue WHERE id = " .. row2.id)
					end
				end
			end

			row1 = cursor1:fetch(row1, "a")
		end
	end

	-- piggy back on this timer so we don't need to add more timers to the profile.
	-- miscCommands are whatever we need done on a timer that isn't covered elsewhere
	miscCommandsTimer()
end
