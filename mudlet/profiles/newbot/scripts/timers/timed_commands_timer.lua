--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function timedCommandsTimer()
	local cursor, errorString, row

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	cursor,errorString = conn:execute("select * from commandQueue order by id limit 0,1")

	if not cursor then
		return
	end

	row = cursor:fetch({}, "a")

	if row then
		windowMessage(server.windowDebug, "running timed command (" .. row.id .. ") " .. row.command .. "\n")

		if (row.command ~= "DoneInventory") then

			if igplayers[row.steam] == nil then
				conn:execute("delete from commandQueue where steam = " .. row.steam)
				return
			end

			sendCommand(row.command)

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			conn:execute("delete from commandQueue where id = " .. row.id)
		else
			conn:execute("delete from commandQueue where id = " .. row.id)
			CheckInventory()
			tempTimer( 2, [[CheckClaimsRemoved()]] )
		end
	end
end
