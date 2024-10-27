--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]


function timedCommandsTimer()
	local cursor, errorString, row, steam, command

	if botman.botDisabled or botman.botOffline or not botman.dbConnected then
		return
	end

	cursor,errorString = connSQL:execute("SELECT * FROM commandQueue ORDER BY id limit 1")
	row = cursor:fetch({}, "a")

	if row then
		steam = row.steam
		command = row.command

		windowMessage(server.windowDebug, "running timed command (" .. row.id .. ") " .. command .. "\n")

		if (row.command ~= "DoneInventory") then

			if igplayers[steam] == nil then
				connSQL:execute("DELETE FROM commandQueue WHERE steam = '" .. steam .. "'")
			else
				connSQL:execute("DELETE FROM commandQueue WHERE id = " .. row.id)
				sendCommand(command)
			end
		else
			connSQL:execute("DELETE FROM commandQueue WHERE id = " .. row.id)
			CheckInventory()
		end
	end
end
