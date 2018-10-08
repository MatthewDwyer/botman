--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function APITimer()
	local row, cursor, errorString, URL, outputFile

	if not botman.dbConnected then
		return
	end

	cursor,errorString = conn:execute("select * from APIQueue order by id limit 1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			URL = row.URL
			outputFile = row.OutputFile
			conn:execute("delete from APIQueue where id = " .. row.id)

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
				logBotCommand(botman.serverTime, URL)
			end

			os.remove(outputFile)
			downloadFile(outputFile, URL)
		end
	end
end
