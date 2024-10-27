--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function FiveSecondTimer()
	-- this is just here to catch and fix a possible fault
	botman.registerHelp = nil

	if telnetLogFileName then
		-- force writes to the telnet log to save to disk
		telnetLogFile:flush()
	end

	if botStatus.safeMode then
		if botStatus.readTelnet == nil then
			botStatus.readTelnet = false
		end

		if not botStatus.readTelnet then
			botStatus.readTelnet = true

			if not botStatus.nextTelnetTest then
				enableTrigger("MatchAll")
			else
				if botStatus.nextTelnetTest == 0 then
					botStatus.nextTelnetTest = 5
					enableTrigger("MatchAll")
				end
			end
		else
			botStatus.readTelnet = false
			disableTrigger("MatchAll")

			if botStatus.telnetSpamCount < botStatus.telnetSpamThreshold then
				display("Bot has exited safe mode")
				irc_chat(server.ircAlerts, "Bot has exited safe mode")
				botStatus.readTelnet = true
				botStatus.safeMode = false
				botStatus.telnetSpamCount = 0

				if botStatus.firstRun then
					botStatus.firstRun = false

					-- finish startup tasks that were deferred
					toggleTriggers("start")

					if server.useAllocsWebAPI then
						toggleTriggers("api online")
					end

					tempTimer( 2, [[getServerData(true)]] )

					if not botStatus.ranCheckData then
						botStatus.ranCheckData = true
						tempTimer( 5, [[checkData()]] )
					end
				else
					toggleTriggers("start")

					if server.useAllocsWebAPI then
						toggleTriggers("api online")
					end
				end
			else
				-- Ruh Roh!  The server might be spamming errors
				irc_chat(server.ircAlerts, "Bot is in safe mode. ERR/WRN count is " .. botStatus.telnetSpamCount)
				display("Bot is in safe mode - spam count is " .. botStatus.telnetSpamCount)
				botStatus.telnetSpamCount = 0

				if not botStatus.nextTelnetTest then
					botStatus.nextTelnetTest = 5
				else
					botStatus.nextTelnetTest = botStatus.nextTelnetTest - 1
				end
			end
		end

		if botStatus.safeMode then
			-- safe mode is enabled so stop here
			return
		end
	else
		-- keep monitoring for telnet err or wrn spam
		if botStatus.telnetSpamCount >= botStatus.telnetSpamThreshold then
			irc_chat(server.ircAlerts, "Bot is in safe mode. Telnet ERR/WRN count is " .. botStatus.telnetSpamCount)
			display("Bot is in safe mode - Telnet ERR/WRN count is " .. botStatus.telnetSpamCount)
			-- go into safe mode
			botStatus.safeMode = true
			botStatus.readTelnet = false
			botStatus.telnetSpamCount = 0

			toggleTriggers("stop") -- disable almost all triggers and timers
			-- just have the TimedCommands timer running first as we will use that to check telnet for evidence of a crashed server
			enableTimer("Every5Seconds")

			if botStatus.safeMode then
				-- safe mode is enabled so stop here
				return
			end
		end
	end

	if botman and server then
		if tonumber(botman.playersOnline) > 0 then
			for k,v in pairs(igplayers) do
				if v.protectTest then
					if v.protectTestEnd - os.time() < 0 then
						v.protectTest = nil
					end
				end
			end

			if server.botman and tonumber(botman.playersOnline) > 0 then
				if server.scanNoclip then
					sendCommand("bm-playerunderground")
				end

				if not server.playersCanFly then
					sendCommand("bm-playergrounddistance")
				end
			end
		end
	end
end
