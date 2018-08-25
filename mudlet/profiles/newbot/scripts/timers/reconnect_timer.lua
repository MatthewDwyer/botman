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
		botman.botOfflineCount = 0
	end

	if botman.botOffline == nil then
		botman.botOffline = false
	end

	if botman.botOffline then
		botman.botOfflineCount = tonumber(botman.botOfflineCount) + 1
	end

	-- special extra test for bot offline
	if botman.lastServerResponseTimestamp == nil then
		botman.lastServerResponseTimestamp = os.time()
	end

	if botman.botOffline == false and (os.time() - botman.lastServerResponseTimestamp > 120) then
		-- haven't communicated with the server in 1 minute but the bot thinks it is connected so force Mudlet to reconnect as it may have fallen
		-- off and failed to notice.
		reconnect()
		return
	end

	if botman.botOfflineCount > 2 and (os.time() - botman.botConnectedTimestamp > 1800) then
		if server.allowBotRestarts then
			restartBot()
			return
		end
	end

	if botman.botOfflineCount > 0 then
		if botman.botOfflineCount < 16 then
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