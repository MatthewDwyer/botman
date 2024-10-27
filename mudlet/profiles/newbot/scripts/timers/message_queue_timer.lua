--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function messageQueueTimer()
	local k, v, row, cursor, errorString, sender, recipient, msg

	if botman.messageQueueEmpty == nil then
		botman.messageQueueEmpty = false
	end

	if botman.messageQueueEmpty then
		return
	end

	if botman.botDisabled or botman.botOffline or not botman.dbConnected then
		return
	end

	cursor,errorString = connSQL:execute("SELECT count(*) FROM messageQueue")
	rowSQL = cursor:fetch({}, "a")
	rowCount = rowSQL["count(*)"]

	if rowCount == 0 then
		botman.messageQueueEmpty = true
		return
	end

	cursor,errorString = connSQL:execute("SELECT * FROM messageQueue WHERE recipient = '0' ORDER BY id LIMIT 1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			msg = row.message

			connSQL:execute("DELETE FROM messageQueue WHERE id = " .. row.id)
			message("say [" .. server.chatColour .. "]" .. msg .. "[-]")
		end
	end


	for k,v in pairs(igplayers) do
		cursor,errorString = connSQL:execute("SELECT * FROM messageQueue WHERE recipient = '" .. k .. "' ORDER BY id LIMIT 1")

		if cursor then
			row = cursor:fetch({}, "a")

			if row then
				msg = row.message
				sender = row.sender
				recipient = row.recipient
				connSQL:execute("DELETE FROM messageQueue WHERE id = " .. row.id)

				if recipient ~= "0" then
					if sender ~= "0" then
						message("pm " .. recipient .. " [" .. server.chatColour .. "]Message from " .. players[sender].name .. " " .. msg .. "[-]")
					else
						message("pm " .. recipient .. " [" .. server.chatColour .. "]" .. msg .. "[-]")
					end
				else
					message("say [" .. server.chatColour .. "]" .. msg .. "[-]")
				end
			end
		end
	end
end
