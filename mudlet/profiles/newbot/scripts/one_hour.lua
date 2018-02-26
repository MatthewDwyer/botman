--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function OneHourTimer()
	local status

	windowMessage(server.windowDebug, "1 hour timer\n")
	status = "Server is UP"

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

	if botman.botOffline then
		status "Server is OFFLINE"
	end

	if relogCount > 6 then
		status "Telnet has crashed."
	end

	if botman.botOffline then
		irc_chat("#status", "Bot " .. server.botName .. " on server " .. server.serverName .. " " .. server.IP .. ":" .. server.ServerPort .. " Game version: " .. server.gameVersion)
		irc_chat("#status", "Status: " .. status .. ", bot version: " .. server.botVersion .. " on branch " .. server.updateBranch)
	end

	return true
end
