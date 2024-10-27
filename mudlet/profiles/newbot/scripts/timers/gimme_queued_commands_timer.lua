--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gimmeQueuedCommands()
	local cursor1, cursor1, errorString, row1, row2, command

	if botman.botDisabled or botman.botOffline or not botman.dbConnected then
		return
	end

	if botman.gimmeQueueEmpty == nil then
		botman.gimmeQueueEmpty = false
	end

	if not botman.gimmeQueueEmpty then
		cursor1,errorString = connMEM:execute("SELECT DISTINCT steam FROM gimmeQueue")

		if cursor1 then
			row1 = cursor1:fetch({}, "a")

			if not row1 then
				botman.gimmeQueueEmpty = true
			end

			while row1 do
				if not igplayers[row1.steam] then
					connMEM:execute("DELETE FROM gimmeQueue WHERE steam = '" .. row1.steam .. "'")
				else
					cursor2,errorString = connMEM:execute("SELECT * FROM gimmeQueue WHERE steam = '" .. row1.steam .. "' ORDER BY id limit 1")

					if cursor2 then
						row2 = cursor2:fetch({}, "a")

						if row2 then
							command = row2.command
							connMEM:execute("DELETE FROM gimmeQueue WHERE id = " .. row2.id)
							sendCommand(command)
						end
					end
				end

				row1 = cursor1:fetch(row1, "a")
			end
		end
	end

	-- piggy back on this timer so we don't need to add more timers to the profile.
	-- miscCommands are whatever we need done on a timer that isn't covered elsewhere
	miscCommandsTimer()
end
