--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

-- to stop the bot getting booted from irc for flooding set something like this for each channel the bot uses
-- /mode #channel +f [5000t#b]:1

function ircQueueTimer()
	local row1, row2, cursor1, cursor2, errorString, name, command
	local tmp = {}

	if not botman.dbConnected then
		return
	end

	cursor1,errorString = connMEM:execute("SELECT DISTINCT name FROM ircQueue")

	if not cursor1 then
		return
	end

	row1 = cursor1:fetch({}, "a")

	if not row1 then
		disableTimer("ircQueue")
	end

	while row1 do
		cursor2,errorString = connMEM:execute("SELECT * FROM ircQueue WHERE name = '" .. connMEM:escape(row1.name) .. "' ORDER BY id LIMIT 2")

		if cursor2 then
			row2 = cursor2:fetch({}, "a")

			if row2 then
				tmp.name = row2.name
				tmp.command = string.trim(row2.command)
				connMEM:execute("DELETE FROM ircQueue WHERE id = " .. row2.id)

				if name ~= "#mudlet" and name ~= "#" .. server.ircBotName then
					sendIrc(tmp.name, " " .. tmp.command) -- the leading space prevents Mudlet from assuming all lines starting with a / are irc commands.
				end
			end
		end

		row1 = cursor1:fetch(row1, "a")
	end
end
