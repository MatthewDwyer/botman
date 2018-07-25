--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function reconnectTimer()
	local channels

	if botman.botConnectedTimestamp == nil then
		botman.botConnectedTimestamp = os.time()
	end

	if botman.botOfflineCount == nil then
		botman.botOfflineCount = 1
	end

	if botman.botOffline == nil then
		botman.botOffline = false
	end

	if botman.botOffline then
		botman.botOfflineCount = tonumber(botman.botOfflineCount) - 1
	end

	-- special extra test for bot offline
	if botman.lastTelnetTimestamp == nil then
		botman.lastTelnetTimestamp = os.time()
	end

	if os.time() - botman.lastTelnetTimestamp > 300 then
		botman.lastTelnetTimestamp = os.time() -- reset this to make it sleep 5 minutes
		botman.botOfflineCount = 1
		irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")
		reconnect()
		return
	end

	if tonumber(botman.botOfflineCount) < 1 then
--		botman.botOffline = true

		if tonumber(botman.botOfflineCount) == 0 then
			botman.botOfflineTimestamp = os.time()
		end

		if math.abs(os.time() - botman.botOfflineTimestamp) < 600 then -- 600
			dbug("Bot is offline - attempting reconnection.")
			botman.botOfflineCount = 1
			irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")
			reconnect()
			return
		else
			if tonumber(botman.botOfflineCount) < -6 then
				if server.allowBotRestarts then
					restartBot()
					return
				else
					dbug("Bot is offline - attempting reconnection (2 minute delay).")
					botman.botOfflineCount = 1
					irc_chat(server.ircMain, "Bot is offline - attempting reconnection (2 minute delay).")
					reconnect()
					return
				end
			end
		end
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
end