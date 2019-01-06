--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function timedCommandsTimer()
	local cursor, errorString, row, steam, command

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	cursor,errorString = conn:execute("select * from commandQueue order by id limit 0,1")

	if not cursor then
		return
	end

	row = cursor:fetch({}, "a")

	if row then
		steam = row.steam
		command = row.command

		windowMessage(server.windowDebug, "running timed command (" .. row.id .. ") " .. command .. "\n")

		if (row.command ~= "DoneInventory") then

			if igplayers[steam] == nil then
				conn:execute("delete from commandQueue where steam = " .. steam)
				return
			end

			conn:execute("delete from commandQueue where id = " .. row.id)
			sendCommand(command)
		else
			conn:execute("delete from commandQueue where id = " .. row.id)
			CheckInventory()
		end
	end
end
