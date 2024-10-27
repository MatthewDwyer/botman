--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function reconnectTimer()
--dbug("debug reconnectTimer line " .. debugger.getinfo(1).currentline)
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

	if botman.serverStarting == nil then
		botman.serverStarting = false
	end

	-- continue testing
	if botman.telnetOffline then
		if botman.wrongTelnetPass then
			if not botman.reconnectCooldown then
				botman.reconnectCooldown = 1
			else
				botman.reconnectCooldown = botman.reconnectCooldown + 1
			end

			if botman.reconnectCooldown < 4 then
				return
			else
				botman.reconnectCooldown = 1
			end
		end

		if botman.noLoginCooldown then
			botman.noLoginCooldown = botman.noLoginCooldown + 1

			if botman.noLoginCooldown > 9 then
				botman.noLoginCooldown = 1
			end

			if botman.noLoginCooldown > 6 then
				r = randSQL(30)
				if r == 5 then
					irc_chat(server.ircMain, "Server offline?   Wrong telnet port?   Port blocked?")
				end

				if r == 10 then
					irc_chat(server.ircMain, "Server gone for a cheesecake?")
				end

				if r == 15 then
					irc_chat(server.ircMain, "Zombies ate the server?")
				end

				if r == 20 then
					irc_chat(server.ircMain, "Where is the server?")
				end

				if r == 25 then
					irc_chat(server.ircMain, "Server!  Shut down all the garbage mashers on the detention level!")
				end

				irc_chat(server.ircMain, "Bot is not connected to telnet - no login prompt.")

				return
			end
		end
	end

	if botman.fileDownloadTimestamp then
		if botman.telnetOffline and not server.telnetDisabled then
			botman.fileDownloadTimestamp = nil
		end
	end

	if botman.telnetOffline and (not server.telnetDisabled or not server.readLogUsingTelnet) then
		botman.telnetOfflineCount = tonumber(botman.telnetOfflineCount) + 1
	end

	if botman.serverStarting then
		botman.APIOfflineCount = 0 -- keep the api offline count at zero
	end

	if (server.useAllocsWebAPI and botman.APIOffline) and (tonumber(botman.telnetOfflineCount) > 1 and not server.telnetDisabled) and tonumber(botman.playersOnline) > 0 then
		botman.botOffline = true
	end

	if botman.botOffline then
		botman.botOfflineCount = tonumber(botman.botOfflineCount) + 1
	end

	if botman.botOffline and server.useAllocsWebAPI and not server.readLogUsingTelnet then
		sendCommand("bm-uptime")
		toggleTriggers("api online")
	end

	if server.useAllocsWebAPI and not server.readLogUsingTelnet then
		-- the bot is in API mode and is not using telnet to read the server log so we don't need to try to reconnect to telnet.
		return
	end

	if (not botman.botOffline) and server.useAllocsWebAPI and (os.time() - botman.lastAPIResponseTimestamp > 60) and tonumber(server.webPanelPort) > 0 and server.allocs and tonumber(botman.playersOnline) > 0 then
		connectToAPI()
	end

	if (not botman.botOffline) and server.useAllocsWebAPI and (os.time() - botman.lastAPIResponseTimestamp > 1800) and tonumber(server.webPanelPort) > 0 and server.allocs and tonumber(botman.playersOnline) > 0 then
		if server.allowBotRestarts then
			irc_chat(server.ircAlerts, "Fault detected. Unable to communicate with Alloc's Web API. This is a bug in the bot's engine so the bot is restarting now which will fix it.")
			tempTimer(5, [[restartBot()]])
		end
	end

	if (botman.telnetOffline or botman.botOffline) and not server.telnetDisabled then
		if botman.telnetOffline then
			if botman.wrongTelnetPass then
				irc_chat(server.ircMain, "Bot is not connected to telnet - wrong password.")
			else
				if os.time() - botman.lastTelnetResponseTimestamp > 10 then
					if not botman.noLoginCooldown then
						botman.noLoginCooldown = 1
					end
				end

				irc_chat(server.ircMain, "Bot is not connected to telnet - attempting reconnection.")
			end
		else
			irc_chat(server.ircMain, "Bot is offline - attempting reconnection.")
		end

		if tonumber(server.telnetPort) > 0 then
			botman.telnetConnecting = true
			connectToServer(server.IP, server.telnetPort)
		else
			botman.telnetConnecting = true
			reconnect()
		end

		return
	end

	if (not botman.telnetOffline) and server.useAllocsWebAPI and tonumber(botman.APIOfflineCount) > 180 then
		-- switch to using telnet only after 1 hour has passed with telnet working and Alloc's web API not working
		botman.APIOfflineCount = 0
		server.useAllocsWebAPI = false
		server.readLogUsingTelnet = true
		conn:execute("UPDATE server set useAllocsWebAPI = 0, readLogUsingTelnet = 1")
		toggleTriggers("api offline")
		irc_chat(server.ircMain, "The bot is unable to use the API and has switched to telnet mode.")
	end

	botman.APIOfflineCount = 0

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