--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function reconnectTimer()
	local channels

	if botman.botConnectedTimestamp == nil then
		botman.botConnectedTimestamp = os.time()
	end

	if botman.lagCheckRead == nil then
		botman.lagCheckRead = true
	end

	if botman.botOffline == nil then
		botman.botOffline = false
	end

	if botman.botOfflineCount == nil then
		botman.botOfflineCount = 2
	end

	botman.botOfflineCount = tonumber(botman.botOfflineCount) - 1

	if tonumber(botman.botOfflineCount) < 1 then
		if not botman.botOffline then
			botman.botConnectedTimestamp = os.time()
		end

		botman.botOffline = true

		if math.abs(os.time() - botman.botConnectedTimestamp) < 600 then -- 600
			dbug("Bot is offline - attempting reconnection.")
			botman.botOfflineCount = 2
			reconnect()
			irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")
		else
			if tonumber(botman.botOfflineCount) < -6 then
				dbug("Bot is offline - attempting reconnection (2 minute delay).")
				botman.botOfflineCount = 2
				reconnect()
				irc_chat(server.ircMain, "Bot is offline - attempting reconnection (2 minute delay).")
			end
		end
	end

	-- test for telnet command lag as it can creep up on busy servers or when there are lots of telnet errors going on
	if botman.lagCheckRead and not botman.botOffline then
		botman.lagCheckRead = false
		botman.lagCheckTime = os.time()
		send("pm LagCheck " .. server.botID)
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