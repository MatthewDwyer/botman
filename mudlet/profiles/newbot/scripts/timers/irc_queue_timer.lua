--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- to stop the bot getting booted from irc for flooding set something like this for each channel the bot uses
-- /mode #channel +f [5000t#b]:1

function ircQueueTimer()
	local row1, row2, cursor1, cursor2, errorString, name, command

	if not botman.dbConnected or botman.ircQueueEmpty then
		return
	end

	cursor1,errorString = conn:execute("select distinct name from ircQueue")

	if not cursor1 then
		return
	end

	row1 = cursor1:fetch({}, "a")

	if not row1 then
		botman.ircQueueEmpty = true
		disableTimer("ircQueue")
	end

	while row1 do
		cursor2,errorString = conn:execute("select * from ircQueue where name = '" .. escape(row1.name) .. "' order by id limit 0,2")

		if cursor2 then
			row2 = cursor2:fetch({}, "a")

			if row2 then
				name = row2.name
				command = row2.command
				conn:execute("delete from ircQueue where id = " .. row2.id)

				if name ~= "#mudlet" then
					sendIrc(name, command)
				end
			end
		end

		row1 = cursor1:fetch(row1, "a")
	end
end
