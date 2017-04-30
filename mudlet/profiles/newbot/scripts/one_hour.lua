--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function OneHourTimer()
	local counter, rows

	windowMessage(server.windowDebug, "1 hour timer\n")

	if (announceRoller == nil) then announceRoller = 1 end

	if (tonumber(botman.playersOnline) == 0) then 
		return 
	end

	counter = 1
	
	if botman.dbConnected then 
		cursor,errorString = conn:execute("SELECT * FROM announcements")
		rows = cursor:numrows()
		row = cursor:fetch({}, "a")
		while row do
			if tonumber(announceRoller) == counter then		
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape(row.message) .. "')")	
			end

			counter = counter + 1
			row = cursor:fetch(row, "a")	
		end
	end
	
	announceRoller = announceRoller + 1
	if (tonumber(announceRoller) > rows) then announceRoller = 1 end
	
	-- retest the chatlog folder so we can save daily chat logs
	botman.webdavFolderExists = true
	botman.webdavFolderWriteable = true
	
	if botman.chatlogPath == nil then
		botman.chatlogPath = webdavFolder
		if botman.dbConnected then conn:execute("UPDATE server SET chatlogPath = '" .. escape(webdavFolder) .. "'") end
	end		

	if not isDir(botman.chatlogPath) then
		botman.webdavFolderExists = false
	end	
	
	return true
end
