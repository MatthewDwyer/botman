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

	if (not botman.botOffline) and server.useAllocsWebAPI and (os.time() - botman.lastAPIResponseTimestamp > 60) and tonumber(server.webPanelPort) > 0 and server.allocs and tonumber(botman.playersOnline) > 0 then
		server.allocsWebAPIPassword = (rand(100000) * rand(5)) + rand(10000)
		send("webtokens add bot " .. server.allocsWebAPIPassword .. " 0")
		botman.lastBotCommand = "webtokens add bot"
		conn:execute("UPDATE server set allocsWebAPIUser = 'bot', allocsWebAPIPassword = '" .. escape(server.allocsWebAPIPassword) .. "', useAllocsWebAPI = 1")
		botman.APIOffline = false
		toggleTriggers("api online")
	end


	if not botman.botOffline and server.useAllocsWebAPI and tonumber(botman.APIOfflineCount) > 5 and tonumber(server.webPanelPort) > 0 then
		if server.telnetFallback then -- don't let the bot stop trying to use Alloc's web API unless telnetFallback is enabled.
			if server.useAllocsWebAPI and botman.APIOffline and not server.telnetDisabled then
				-- switch to using telnet
				server.useAllocsWebAPI = false
				conn:execute("UPDATE server set useAllocsWebAPI = 0")
			end
		end
	end

	if (os.time() - botman.lastTelnetResponseTimestamp > 600) and not server.telnetDisabled then
		botman.telnetOffline = true
	end

	if (os.time() - botman.lastTelnetResponseTimestamp) > 540 and not server.telnetDisabled and not botman.worldGenerating then
		send("gt")
	end

	if tonumber(botman.botOfflineCount) > 180 then
		if server.allowBotRestarts then
			restartBot()
			return
		end
	end

	if (botman.telnetOffline or botman.botOffline) and not server.telnetDisabled then
		if botman.telnetOffline then
			irc_chat(server.ircMain, "Bot is not connected to telnet - attempting reconnection.")
		else
			irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")
		end

		if tonumber(server.telnetPort) > 0 then
			connectToServer(server.IP, server.telnetPort)
		else
			reconnect()
		end

		return
	end

	if os.time() - botman.lastServerResponseTimestamp > 60 and botman.botOffline and not server.telnetDisabled then
		irc_chat(server.ircMain, "Bot is offline - attempting reconnection to telnet.")

		if tonumber(server.telnetPort) > 0 then
			connectToServer(server.IP, server.telnetPort)
		else
			reconnect()
		end

		return
	end

	if tonumber(botman.telnetOfflineCount) > 3 and not server.telnetDisabled then
		irc_chat(server.ircMain, "Bot is not connected to telnet - attempting reconnection.")

		if tonumber(server.telnetPort) > 0 then
			connectToServer(server.IP, server.telnetPort)
		else
			reconnect()
		end

		return
	end

	if tonumber(botman.botOfflineCount) > 0 then
		if tonumber(botman.botOfflineCount) < 16 then
			irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")

			if tonumber(server.telnetPort) > 0 then
				connectToServer(server.IP, server.telnetPort)
			else
				reconnect()
			end

		else
			if (botman.botOfflineCount % 20 == 0) then
				irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")

				if tonumber(server.telnetPort) > 0 then
					connectToServer(server.IP, server.telnetPort)
				else
					reconnect()
				end

			end
		end

		return
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
	end


	if type(server) == "table" and type(modVersions) ~= "table" then
		importModVersions()
	end
end