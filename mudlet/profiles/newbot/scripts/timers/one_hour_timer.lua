--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function oneHourTimer()
	local k, v, status

	if botman.botDisabled then
		return
	end

	if customHourlyTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customHourlyTimer() then
			return
		end
	end

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

	-- nuke the error log .xsession-errors to prevent Mudlet filling up the harddrive with crap
	os.execute(">~/.xsession-errors")

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

	-- Flag all players as offline so we don't have any showing as online who left without being updated
	if tonumber(server.botID) > 0 then
		if botman.dbBotsConnected then connBots:execute("UPDATE players set online = 0 WHERE botID = " .. server.botID) end
	end

	 -- fix any problems with player records
	 for k,v in pairs(players) do
		fixMissingPlayer(k)
	 end
end
