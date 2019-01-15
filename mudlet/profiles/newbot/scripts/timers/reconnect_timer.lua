--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function reconnectTimer()
	local channels

	if botman.lastServerResponseTimestamp == nil then
		botman.lastServerResponseTimestamp = os.time()
	end

	if botman.lastTelnetResponseTimestamp == nil then
		botman.lastTelnetResponseTimestamp = os.time()
	end

	if botman.lastAPIResponseTimestamp == nil then
		botman.lastAPIResponseTimestamp = os.time()
	end

	if botman.botConnectedTimestamp == nil then
		botman.botConnectedTimestamp = os.time()
	end

	if botman.botOfflineCount == nil then
		botman.botOfflineCount = 0
	end

	if botman.botOffline == nil then
		botman.botOffline = false
	end

	if botman.botOffline then
		botman.botOfflineCount = tonumber(botman.botOfflineCount) + 1
	end

	if server.useAllocsWebAPI and botman.APIOffline and tonumber(server.webPanelPort) > 0 then
		os.remove(homedir .. "/temp/apitest.txt")
		botman.APITestSilent = true
		startUsingAllocsWebAPI()
	end

	if tonumber(botman.playersOnline) > 0 and (os.time() - botman.lastTelnetResponseTimestamp > 90 or botman.botOffline) then
		if (not server.useAllocsWebAPI) and botman.APIOffline then
			reconnect()
			return
		end
	end

	if os.time() - botman.lastServerResponseTimestamp > 60 and botman.botOffline then
		irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")
		reconnect()
		return
	end

	if (os.time() - botman.lastTelnetResponseTimestamp) > 310 then
		if (not server.useAllocsWebAPI) and botman.APIOffline then
			reconnect()
			return
		end
	end

	if tonumber(botman.botOfflineCount) > 30 then
		if server.allowBotRestarts then
			restartBot()
			return
		end
	end

	if tonumber(botman.botOfflineCount) > 0 then
		if tonumber(botman.botOfflineCount) < 16 then
			if botman.APIOffline then
				irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")
			end

			reconnect()
		else
			if (botman.botOfflineCount % 20 == 0) then
				if botman.APIOffline then
					irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")
				end

				reconnect()
			end
		end

		return
	end

	if ircGetChannels ~= nil then
		channels = ircGetChannels()

		if channels == "" then
			joinIRCServer()
			return
		end

		if not string.find(channels, server.ircMain) then
			ircJoin(server.ircMain)
		end

		if not string.find(channels, server.ircAlerts) then
			ircJoin(server.ircAlerts)
		end

		if not string.find(channels, server.ircWatch) then
			ircJoin(server.ircWatch)
		end
	end


	if type(server) == "table" and type(modVersions) ~= "table" then
		importModVersions()
	end
end