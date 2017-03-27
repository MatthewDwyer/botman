--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function miscCommandsTimer()
	local cursor, errorString, row

	cursor,errorString = conn:execute("select * from miscQueue order by id limit 0,1")
	row = cursor:fetch({}, "a")

	if row then
		if tonumber(row.steam) > 0 then
			if igplayers[row.steam] == nil then
				conn:execute("delete from miscQueue where steam = " .. row.steam)
				return
			end
		end
		
		send(row.command)	
		conn:execute("delete from miscQueue where id = " .. row.id)
	end
end


function gimmeQueuedCommands()
	local pid, dist1, dist2, cursor1, cursor1, errorString, row1, row2

	if botman.botDisabled or botman.botOffline or server.lagged then
		return
	end

	cursor1,errorString = conn:execute("select distinct steam from gimmeQueue")
	row1 = cursor1:fetch({}, "a")

	while row1 do
		cursor2,errorString = conn:execute("select * from gimmeQueue where steam = " .. row1.steam .. " order by id limit 0,1")
		row2 = cursor2:fetch({}, "a")

		if row2 then
			send(row2.command)
			conn:execute("delete from gimmeQueue where id = " .. row2.id)
		end

		row1 = cursor1:fetch(row1, "a")
	end
	
	-- piggy back on this timer so we don't need to add more timers to the profile.
	-- miscCommands are whatever we need done on a timer that isn't covered elsewhere
	miscCommandsTimer()		
end
