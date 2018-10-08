--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function LKPQueue()
	local row, cursor, errorString, LKPLine

	if not botman.dbConnected then
		return
	end

	cursor,errorString = conn:execute("SELECT * FROM LKPQueue ORDER BY id LIMIT 1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			LKPLine = row.line
			conn:execute("DELETE FROM LKPQueue WHERE id = " .. row.id)
			processLKPLine(LKPLine)
		end
	end
end


function miscCommandsTimer()
	local cursor, errorString, row, temp, steam, command

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	cursor,errorString = conn:execute("SELECT * FROM miscQueue WHERE timerDelay = '0000-00-00 00:00:00'  ORDER BY id limit 0,1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			steam = row.steam
			command = row.command

			if string.find(command, "admin add") then
				irc_chat(server.ircMain, "Player " .. players[steam].name .. " has been given admin.")
				temp = string.split(command, " ")
				setChatColour(steam, temp[4])
				conn:execute("DELETE FROM miscQueue WHERE id = " .. row.id)
				sendCommand(command)
			end

			if string.find(command, "ban remove") then
				irc_chat(server.ircMain, "Player " .. players[steam].name .. " has been unbanned.")
				conn:execute("DELETE FROM miscQueue WHERE id = " .. row.id)
				sendCommand(command)
			end

			if string.find(command, "tele ") then
				if igplayers[steam] then
					conn:execute("DELETE FROM miscQueue WHERE id = " .. row.id)
					teleport(command, steam)
				end
			else
				conn:execute("DELETE FROM miscQueue WHERE id = " .. row.id)
				sendCommand(command)
			end
		end
	end

	-- check all the delayed commands.  send any that are not in the future
	cursor,errorString = conn:execute("SELECT id, steam, command, action, value, UNIX_TIMESTAMP(timerDelay) AS delay FROM miscQueue WHERE timerDelay <> '0000-00-00 00:00:00' ORDER BY id")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			while row do
				steam = row.steam
				command = row.command

				if row.delay - os.time() <= 0 then
					if string.sub(command, 1, 3) == "pm " or string.sub(command, 1, 3) == "say" then
						conn:execute("DELETE FROM miscQueue WHERE id = " .. row.id)
						message(command)

						if string.find(row.command, "admin status") then
							irc_chat(server.ircMain, "OH GOD NOOOO! " .. players[steam].name .. "'s admin status has been restored.")
						end
					else
						if string.find(command, "tele ") then
							if igplayers[steam] then
								conn:execute("DELETE FROM miscQueue WHERE id = " .. row.id)
								teleport(command, steam)
							end
						else
							conn:execute("DELETE FROM miscQueue WHERE id = " .. row.id)
							sendCommand(command)

							if string.find(command, "admin add") then
								temp = string.split(command, " ")
								setChatColour(steam, temp[4])
							end
						end
					end
				end

				row = cursor:fetch(row, "a")
			end
		end
	end
end


function gimmeQueuedCommands()
	local cursor1, cursor1, errorString, row1, row2, command

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
						command = row2.command
						conn:execute("DELETE FROM gimmeQueue WHERE id = " .. row2.id)
						display(command)
						sendCommand(command)
					end
				end
			end

			row1 = cursor1:fetch(row1, "a")
		end
	end

	-- piggy back on this timer so we don't need to add more timers to the profile.
	-- miscCommands are whatever we need done on a timer that isn't covered elsewhere
	miscCommandsTimer()

	-- Process 1 line from LKP.  We process them this way to avoid freezing the bot when reading thousands of players
	LKPQueue()
end
