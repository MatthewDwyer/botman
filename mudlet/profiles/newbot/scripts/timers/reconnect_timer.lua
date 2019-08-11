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

	-- make sure our test vars exist
	if botman.APIOffline == nil then
		botman.APIOffline = true
	end

	if botman.APIOfflineCount == nil then
		botman.APIOfflineCount = 0
	end

	if botman.botOffline == nil then
		botman.botOffline = true
	end

	if botman.botOfflineCount == nil then
		botman.botOfflineCount = 0
	end

	if botman.telnetOffline == nil then
		botman.telnetOffline = true
	end

	if botman.telnetOfflineCount == nil then
		botman.telnetOfflineCount = 0
	end

	if botman.lastAPIResponseTimestamp == nil then
		botman.lastAPIResponseTimestamp = os.time()
	end

	if botman.botConnectedTimestamp == nil then
		botman.botConnectedTimestamp = os.time()
	end

	if botman.lastServerResponseTimestamp == nil then
		botman.lastServerResponseTimestamp = os.time()
	end

	if botman.lastTelnetResponseTimestamp == nil then
		botman.lastTelnetResponseTimestamp = os.time()
	end

	-- continue testing
	if botman.telnetOffline and not server.telnetDisabled then
		botman.telnetOfflineCount = tonumber(botman.telnetOfflineCount) + 1
	end

	if (server.useAllocsWebAPI and botman.APIOffline) and (tonumber(botman.telnetOfflineCount) > 1 and not server.telnetDisabled) then
		botman.botOffline = true
	end

	if botman.botOffline then
		botman.botOfflineCount = tonumber(botman.botOfflineCount) + 1
	end

	if not botman.botOffline and server.useAllocsWebAPI and (botman.APIOffline or os.time() - botman.lastAPIResponseTimestamp > 60) and tonumber(server.webPanelPort) > 0 then
		os.remove(homedir .. "/temp/apitest.txt")
		botman.APITestSilent = true
		botman.lastAPIResponseTimestamp = os.time() -- reset to current time so it will only trigger this code every minute.
		startUsingAllocsWebAPI()
	end


	if not botman.botOffline and server.useAllocsWebAPI and tonumber(botman.APIOfflineCount) > 5 and tonumber(server.webPanelPort) > 0 then
		if server.useAllocsWebAPI and botman.APIOffline and not server.telnetDisabled then
			-- switch to using telnet
			server.useAllocsWebAPI = false
			conn:execute("UPDATE server set useAllocsWebAPI = 0")
		end
	end

	if (os.time() - botman.lastTelnetResponseTimestamp > 600) and not server.telnetDisabled then
		botman.telnetOffline = true
	end

	if (os.time() - botman.lastTelnetResponseTimestamp) > 540 and not server.telnetDisabled then
		send("gt")
	end

	if (botman.telnetOffline or botman.botOffline) and not server.telnetDisabled then
		if botman.telnetOffline then
			irc_chat(server.ircMain, "Bot is not connected to telnet - attempting reconnection.")
		else
			irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")
		end

		reconnect()
		return
	end

	if os.time() - botman.lastServerResponseTimestamp > 60 and botman.botOffline and not server.telnetDisabled then
		irc_chat(server.ircMain, "Bot is offline - attempting reconnection to telnet.")
		reconnect()
		return
	end

	if tonumber(botman.telnetOfflineCount) > 3 and not server.telnetDisabled then
		irc_chat(server.ircMain, "Bot is not connected to telnet - attempting reconnection.")
		reconnect()
		return
	end

	if tonumber(botman.botOfflineCount) > 0 then
		if tonumber(botman.botOfflineCount) < 16 then
			irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")
			reconnect()
		else
			if (botman.botOfflineCount % 20 == 0) then
				irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")
				reconnect()
			end
		end

		return
	end

	if tonumber(botman.botOfflineCount) > 180 then
		if server.allowBotRestarts then
			restartBot()
			return
		end
	end

	if server.useAllocsWebAPI and not botman.botOffline then
		botman.APIOfflineCount = tonumber(botman.APIOfflineCount) + 1
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