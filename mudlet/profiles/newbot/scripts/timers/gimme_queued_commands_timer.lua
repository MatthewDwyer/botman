--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gimmeQueuedCommands()
	if botDisabled then
		return
	end

	local pid, dist1, dist2

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
end
