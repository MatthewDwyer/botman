--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function messageQueueTimer()
	local k, v, row, cursor, errorString

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	cursor,errorString = conn:execute("select * from messageQueue where recipient = 0 order by id limit 0,1")
	
	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			message("say [" .. server.chatColour .. "]" .. row.message .. "[-]")
			conn:execute("delete from messageQueue where id = " .. row.id)
		end
	end	


	for k,v in pairs(igplayers) do
		cursor,errorString = conn:execute("select * from messageQueue where recipient = " .. k .. " order by id limit 0,1")
		
		if cursor then
			row = cursor:fetch({}, "a")

			if row then
				if tonumber(row.recipient) ~= 0 then
					if tonumber(row.sender) ~= 0 then
						message("pm " .. row.recipient .. " [" .. server.chatColour .. "]Message from " .. players[row.sender].name .. " " .. row.message .. "[-]")
					else
						message("pm " .. row.recipient .. " [" .. server.chatColour .. "]" .. row.message .. "[-]")
					end
				else
					message("say [" .. server.chatColour .. "]" .. row.message .. "[-]")
				end

				conn:execute("delete from messageQueue where id = " .. row.id)
			end
		end
	end
end
