--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

 -- These are run every second

function persistentQueueTimer()
	local cursor, errorString, row, temp, steam, command, ranCommand

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	ranCommand = false
	cursor,errorString = conn:execute("SELECT * FROM persistentQueue WHERE timerDelay = '0000-00-00 00:00:00'  ORDER BY id limit 0,1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			steam = row.steam
			command = row.command

			if command == "update player" then
				ranCommand = true
				fixMissingPlayer(steam)
				updatePlayer(steam)
				conn:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
			end

			if command == "update archived player" then
				ranCommand = true
				fixMissingArchivedPlayer(steam)
				updateArchivedPlayer(steam)
				conn:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
			end

			if string.find(command, "admin add") then
				ranCommand = true
				irc_chat(server.ircMain, "Player " .. players[steam].name .. " has been given admin.")
				temp = string.split(command, " ")
				setChatColour(steam, temp[4])
				conn:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
				sendCommand(command)
			end

			if string.find(command, "ban remove") then
				ranCommand = true
				irc_chat(server.ircMain, "Player " .. players[steam].name .. " has been unbanned.")
				conn:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
				sendCommand(command)
			end

			if string.find(command, "tele ") then
				ranCommand = true
				conn:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)

				if igplayers[steam] then
					teleport(command, steam)
				end
			end

			if not ranCommand then
				conn:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
				sendCommand(command)
			end
		end
	end

	-- check all the delayed commands.  send any that are not in the future
	cursor,errorString = conn:execute("SELECT id, steam, command, action, value, UNIX_TIMESTAMP(timerDelay) AS delay FROM persistentQueue WHERE timerDelay <> '0000-00-00 00:00:00' ORDER BY timerDelay, id limit 0,1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			steam = row.steam
			command = row.command

			if row.delay - os.time() <= 0 then
				if string.sub(command, 1, 3) == "pm " or string.sub(command, 1, 3) == "say" then
					ranCommand = true
					conn:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
					message(command)

					if string.find(row.command, "admin status") then
						irc_chat(server.ircMain, "OH GOD NOOOO! " .. players[steam].name .. "'s admin status has been restored.")
					end
				else
					if string.find(command, "tele ") then
						ranCommand = true
						conn:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)

						if igplayers[steam] then
							teleport(command, steam)
						end
					else
						ranCommand = true
						conn:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
						sendCommand(command)

						if string.find(command, "admin add") then
							temp = string.split(command, " ")
							setChatColour(steam, temp[4])
						end
					end
				end
			end
		end
	end
end


function trackPlayerTimer()
	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	local row, rows, k, v, cursor, errorString

	for k, v in pairs(igplayers) do
		if v.trackerCount ~= nil then
			if v.trackerStopped == false then
				v.trackerCountdown = tonumber(v.trackerCountdown) - 1

				if (v.trackerCountdown < 1) then
					v.trackerCountdown = v.trackerSpeed

					if v.trackerReversed then
						cursor,errorString = conn:execute("SELECT * FROM memTracker WHERE admin = " .. k .. " AND trackerID < " .. v.trackerCount .. " ORDER BY trackerID DESC LIMIT 0," .. v.trackerSkip + 1)
					else
						cursor,errorString = conn:execute("SELECT * FROM memTracker WHERE admin = " .. k .. " AND trackerID > " .. v.trackerCount .. " ORDER BY trackerID LIMIT 0," .. v.trackerSkip + 1)
					end

					if not cursor then
						return
					end

					row = cursor:fetch({}, "a")

					if row then
						sendCommand("tele " .. k .. " " .. row.x .. " " .. row.y .. " " .. row.z)
					end

					while row do
						row = cursor:fetch(row, "a")
						v.trackerCount = row.trackerID
					end

					v.trackerStopped = true

					if v.trackerStop ~= nil then
						v.trackerStopped = true
						v.trackerStop = nil
					end

					if igplayers[chatvars.playerid].trackerLastSession then
						message("pm " .. k .. " [" .. server.chatColour .. "]Tracking complete. You have reached the players current position.[-]")
					else
						message("pm " .. k .. " [" .. server.chatColour .. "]Tracking complete. Type " .. server.commandPrefix .. "next track or " .. server.commandPrefix .. "last track to continue from the next session.[-]")
					end
				end
			end
		end
	end

	-- piggy-back on this timer to run the persistentQueue.
	persistentQueueTimer()
end
