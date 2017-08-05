--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function OneHourTimer()
	windowMessage(server.windowDebug, "1 hour timer\n")

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
