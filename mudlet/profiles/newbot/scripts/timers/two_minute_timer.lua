--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function twoMinuteTimer()
	-- to fix a weird bug where the bot would stop responding to chat but could be woken up by irc chatter we send the bot a wake up call
	irc_chat(server.ircBotName, "Keep alive")

	writeBotmanINI()

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	if tonumber(botman.playersOnline) > 0 then
		-- save the penguins! er I mean world!
		if not botman.serverRebooting then
			if not botMaintenance.lastSA then
				botMaintenance.lastSA = os.time()
				saveBotMaintenance()
				send("sa")
			else
				if (os.time() - botMaintenance.lastSA) > 30 then
					botMaintenance.lastSA = os.time()
					saveBotMaintenance()
					send("sa")
				end
			end
		end

		if server.scanErrors and server.coppi then
			for k,v in pairs(igplayers) do
				sendCommand("rcd " .. math.floor(v.xPos) .. " " .. math.floor(v.zPos))
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
				if botman.dbBotsConnected then connBots:execute("UPDATE players SET ircAuthenticated = 0 WHERE steam = " .. k) end
			else
				if (v.ircSessionExpiry - os.time()) < 0 then
					v.ircAuthenticated = false
					if botman.dbBotsConnected then connBots:execute("UPDATE players SET ircAuthenticated = 0 WHERE steam = " .. k) end
				end
			end
		end
	end

	if tonumber(botman.playersOnline) > 24 then
		removeClaims()
	end
end
