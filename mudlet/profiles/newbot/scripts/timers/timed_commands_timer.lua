--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function WebPanelQueue()
	local row, cursor, errorString, steam, action, actionTable, actionQuery, actionArgs, sessionID, temp

	-- delete any expired records in webInterfaceJSON
	conn:execute("DELETE FROM webInterfaceJSON WHERE expire < NOW() and expire <> '0000-00-00 00:00:00'")

	-- check webInterfaceQueue for records and process them
	cursor,errorString = conn:execute("SELECT * FROM webInterfaceQueue ORDER BY id")

	if cursor then
		row = cursor:fetch({}, "a")

		while row do
			steam = row.steam
			action = row.action
			actionTable = row.actionTable
			actionQuery = row.actionQuery
			actionArgs = row.actionArgs
			sessionID = row.sessionID
			temp = string.split(actionArgs, "/,/")
			conn:execute("DELETE FROM webInterfaceQueue WHERE id = " .. row.id)

			if action == "restart bot" then
				if server.allowBotRestarts then
					restartBot()
				end
			end

			if action == "restart server" then
				if server.allowReboot then
					botman.scheduledRestart = false
					botman.scheduledRestartTimestamp = os.time()
					botman.scheduledRestartPaused = false
					botman.scheduledRestartForced = true

					if (botman.rebootTimerID ~= nil) then killTimer(botman.rebootTimerID) end
					if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end

					botman.rebootTimerID = nil
					rebootTimerDelayID = nil
					botman.scheduledRestartPaused = false
					botman.scheduledRestart = true
					botman.scheduledRestartTimestamp = os.time() + 120
				end
			end

			if action == "fix bot" then
				fixBot()
			end

			if action == "kick" then
				kick(temp[1], temp[2])
			end

			if action == "encode" and actionTable == "botman" then
				if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, expires, json, sessionID) VALUES ('botman','panel','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + 60) .. "','" .. escape(yajl.to_string(botman)) .. "','" .. escape(sessionID) .. "')") end
			end

			if action == "reload table" then
				if actionTable == "locations" then
					loadLocations()
				end
			end


			row = cursor:fetch(row, "a")
		end
	end
end


function timedCommandsTimer()
	local cursor, errorString, row, steam, command

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	cursor,errorString = conn:execute("select * from commandQueue order by id limit 0,1")
	row = cursor:fetch({}, "a")

	if row then
		steam = row.steam
		command = row.command

		windowMessage(server.windowDebug, "running timed command (" .. row.id .. ") " .. command .. "\n")

		if (row.command ~= "DoneInventory") then

			if igplayers[steam] == nil then
				conn:execute("delete from commandQueue where steam = " .. steam)
			else
				conn:execute("delete from commandQueue where id = " .. row.id)
				sendCommand(command)
			end
		else
			conn:execute("delete from commandQueue where id = " .. row.id)
			CheckInventory()
		end
	end

	-- piggyback on this timer and process the web panel queue
	WebPanelQueue()
end
