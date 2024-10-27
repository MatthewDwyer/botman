--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function oneHourTimer()
	local k, v, status, diff

	if botman.botDisabled then
		return
	end

	expireDonors()

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
		if not isDir(webdavFolder) then
			botman.webdavFolderExists = false
			botman.chatlogPath = homedir .. "/chatlogs"
		else
			botman.chatlogPath = webdavFolder
		end

		if botman.dbConnected then conn:execute("UPDATE server SET chatlogPath = '" .. escape(botman.chatlogPath) .. "'") end
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
		--if botman.dbBotsConnected then connBots:execute("UPDATE players set online = 0 WHERE botID = " .. server.botID) end
	end

	-- fix any problems with player records
	for k,v in pairs(players) do
		if tonumber(v.groupExpiry) > 0 then
			diff = os.difftime(v.groupExpiry, os.time())

			if tonumber(diff) < 0 then
				-- group membership has expired
				v.groupID = v.groupExpiryFallbackGroup
				v.groupExpiryFallbackGroup = 0
				v.groupExpiry = 0
			end
		end

		fixMissingPlayer(v.platform, k, v.steamOwner, v.userID)

		if tonumber(diff) < 0 then
			updatePlayer(k)
		end
	end

	--sendCommand("llp parseable")
end
