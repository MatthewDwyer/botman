--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- to stop the bot getting booted from irc for flooding set something like this for each channel the bot uses
-- /mode #channel +f [5000t#b]:1

function ircQueueTimer()
	-- do not use IRC if bot is disabled or the channel name is #mudlet.
	if botDisabled or server.ircDisabled then
		return
	end

	cursor1,errorString = conn:execute("select distinct name from ircQueue")
	row1 = cursor1:fetch({}, "a")

	while row1 do
		cursor2,errorString = conn:execute("select * from ircQueue where name = '" .. escape(row1.name) .. "' order by id limit 0,1")
		row2 = cursor2:fetch({}, "a")

		if row2 then
			sendIrc(row2.name, row2.command)
			conn:execute("delete from ircQueue where id = " .. row2.id)
		end

		row1 = cursor1:fetch(row1, "a")
	end
end
