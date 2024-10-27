--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function twoMinuteTimer()
	-- make sure the bot is still connected to the irc server
	joinIRCServer()

	if botman.botDisabled or botman.botOffline or not botman.dbConnected then
		return
	end

	if tonumber(botman.playersOnline) > 0 then
		if server.scanErrors then
			for k,v in pairs(igplayers) do
				sendCommand("rcd " .. math.floor(v.xPos) .. " " .. math.floor(v.zPos) .. " fix")
			end
		end
	end

	if customTwoMinuteTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customTwoMinuteTimer() then
			return
		end
	end

	removeBadPlayerRecords()

	-- logout anyone on irc who hasn't typed anything and their session has expired
	for k,v in pairs(players) do
		if v.ircAuthenticated == true then
			if v.ircSessionExpiry == nil then
				v.ircAuthenticated = false
				--if botman.dbBotsConnected then connBots:execute("UPDATE players SET ircAuthenticated = 0 WHERE steam = '" .. k .. "'") end
			else
				if (v.ircSessionExpiry - os.time()) < 0 then
					v.ircAuthenticated = false
					--if botman.dbBotsConnected then connBots:execute("UPDATE players SET ircAuthenticated = 0 WHERE steam = '" .. k .. "'") end
				end
			end
		end
	end

	if tonumber(botman.playersOnline) > 24 then
		removeClaims()
	end

	if not botman.webdavFolderWriteable then
		testLogFolderWriteable()
	end

	if server.useAllocsWebAPI and botman.APIOffline then
		connectToAPI()
	end
end
