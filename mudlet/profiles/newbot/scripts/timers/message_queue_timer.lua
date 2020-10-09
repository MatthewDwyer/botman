--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function messageQueueTimer()
	local k, v, row, cursor, errorString, sender, recipient, msg

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	cursor,errorString = conn:execute("select * from messageQueue")

	if cursor:numrows() == 0 then
		return
	end

	cursor,errorString = conn:execute("select * from messageQueue where recipient = 0 order by id limit 0,1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			msg = row.message

			conn:execute("delete from messageQueue where id = " .. row.id)
			message("say [" .. server.chatColour .. "]" .. msg .. "[-]")
		end
	end


	for k,v in pairs(igplayers) do
		cursor,errorString = conn:execute("select * from messageQueue where recipient = " .. k .. " order by id limit 0,1")

		if cursor then
			row = cursor:fetch({}, "a")

			if row then
				msg = row.message
				sender = row.sender
				recipient = row.recipient
				conn:execute("delete from messageQueue where id = " .. row.id)

				if tonumber(recipient) ~= 0 then
					if tonumber(sender) ~= 0 then
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
