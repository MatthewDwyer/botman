--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- to stop the bot getting booted from irc for flooding set something like this for each channel the bot uses
-- /mode #channel +f [5000t#b]:1

function ircQueueTimer()
	local row1, row2, cursor1, cursor2, errorString
	
	if not botman.dbConnected then 
		return
	end

	cursor1,errorString = conn:execute("select distinct name from ircQueue")
	
	if not cursor1 then
		return
	end
	
	row1 = cursor1:fetch({}, "a")

	while row1 do
		cursor2,errorString = conn:execute("select * from ircQueue where name = '" .. escape(row1.name) .. "' order by id limit 0,2")
		
		if cursor2 then
			row2 = cursor2:fetch({}, "a")

			if row2 then
				sendIrc(row2.name, row2.command)
				conn:execute("delete from ircQueue where id = " .. row2.id)
			end
		end

		row1 = cursor1:fetch(row1, "a")
	end
end
