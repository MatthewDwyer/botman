--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function APITimer()
	local row, cursor, errorString, url, cmd
	local httpHeaders = {["X-SDTD-API-TOKENNAME"] = server.allocsWebAPIUser, ["X-SDTD-API-SECRET"] = server.allocsWebAPIPassword}

	if (not botman.dbConnected) or botman.botOffline then
		return
	end

	connSQL:execute("DELETE FROM APIQueue WHERE timestamp < " .. os.time() - 30)

	cursor,errorString = connSQL:execute("SELECT * FROM APIQueue ORDER BY id LIMIT 1")

	if cursor then
		row = cursor:fetch({}, "a")

		if not row then
			disableTimer("APITimer")
		end

		if row then
			url = row.URL

			connSQL:execute("DELETE FROM APIQueue WHERE id = " .. row.id)

			-- should be able to remove list later.  Just put it here to fix an issue with older bots updating and not having the metrics table.
			if type(metrics) ~= "table" then
				metrics = {}
				metrics.commands = 0
				metrics.commandLag = 0
				metrics.errors = 0
				metrics.telnetLines = 0
			end

			metrics.commands = metrics.commands + 1

			if server.logBotCommands then
				logBotCommand(botman.serverTime, url)
			end

			if not string.find(url, "#") then
				pcall(postHTTP("", url, httpHeaders))
				-- the response from the server is processed in function onHttpPostDone(_, url, body) in functions.lua
			else
				cmd = string.sub(url, string.find(url, "command=") + 8, string.find(url, "&adminuser") - 1)
				sendCommand(cmd)
			end
		end
	end
end
