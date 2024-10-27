--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function thirtySecondTimer()
	local k, v, cmd, url
	local maxUptime, dailyRebootTime, secondsSinceMidnight, midnightTimestamp, rebootDelay

	if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('botman','panel','" .. escape(yajl.to_string(botman)) .. "')") end
	if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('server','panel','" .. escape(yajl.to_string(server)) .. "')") end

	-- piggyback on this timer and process the web panel queue
	WebPanelQueue()

	maxUptime = 0
	dailyRebootTime = 0

	fixMissingServer() -- test for missing values

	windowMessage(server.windowDebug, "30 second timer\n")

	if botman.botDisabled then
		return
	end

	sendNextAnnouncement(true) -- for announcements that need to be sent at a specific server time each day

	if customThirtySecondTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customThirtySecondTimer() then
			return
		end
	end

	if botman.botOffline then
		return
	end

	if server.botsIP == "0.0.0.0" then
		send("pm BotStartupCheck \"test\"")
	end

	if (botman.announceBot == true) then
		-- fixMissingServer() -- test for missing values

		if not server.beQuietBot then
			message("say [" .. server.chatColour .. "]" .. server.botName .. " is online. Command me. :3[-]")
		end
		botman.announceBot = false
	end

	math.randomseed(os.time())

	if (botman.initError == true) then
		gatherServerData()
		botman.initError = false
		botman.announceBot = true
	end

	newDay()

	-- scan player inventories
	if not server.useAllocsWebAPI then
		for k, v in pairs(igplayers) do
			if (v.killTimer == nil) then v.killTimer = 0 end

			if tonumber(v.killTimer) < 2 then
				cmd = "si " .. v.platform .. "_" .. v.steam
				if botman.dbConnected then connSQL:execute("INSERT into commandQueue (command, steam) VALUES ('" .. cmd .. "','" .. k .. "')") end
			end
		end

		cmd = "DoneInventory"
		if botman.dbConnected then connSQL:execute("INSERT into commandQueue (command) VALUES ('" .. cmd .. "')") end
	else
		if tonumber(botman.playersOnline) > 0 then
			sendCommand("getplayerinventories", "getplayerinventories?", "inventories.txt")
		end
	end

	-- update the shared database (bots) server table (mainly for players online and a timestamp so others can see we're still online
	updateBotsServerTable()

	if server.allowReboot then
		if botman.nextRebootTest then
			if os.time() < botman.nextRebootTest then
				return
			end
		end

		if not botman.scheduledRestart then
			-- calc maxUptime in minutes
			if server.maxServerUptime < 25 then
				maxUptime = server.maxServerUptime * 60  -- total minutes where maxServerUptime is hours
			else
				maxUptime = server.maxServerUptime -- in minutes
			end

			-- if a daily reboot time is set, calc it in minutes of the day
			if tonumber(server.rebootHour) ~= 0 and tonumber(server.rebootMinute) ~= 0 then
				dailyRebootTime = (tonumber(server.rebootHour) * 60 * 60) + (tonumber(server.rebootMinute) * 60)
			end

			rebootDelay = maxUptime - math.floor(server.uptime / 60) -- maxUptime (in minutes) minus server uptime (in minutes) giving number of minutes remaining before next reboot

			if rebootDelay < 16 then
				-- prevent negative timed reboots occuring if the bot was offline and missed the scheduled reboot time
				if rebootDelay < 1 then
					rebootDelay = 15 -- 15 minutes from now
				end

				message("say [" .. server.chatColour .. "]The server will reboot in " .. rebootDelay .. " minutes.[-]")
				botman.scheduledRestartPaused = false
				botman.scheduledRestart = true
				botman.scheduledRestartTimestamp = os.time() + (rebootDelay * 60)
			else
				if dailyRebootTime > 0 then
					midnightTimestamp = {year=os.date('%Y', botman.serverTimeStamp), month=os.date('%m', botman.serverTimeStamp), day=os.date('%d', botman.serverTimeStamp), hour=0, min=0, sec=0}
					secondsSinceMidnight = botman.serverTimeStamp - os.time(midnightTimestamp)

					if dailyRebootTime - secondsSinceMidnight >= 0 and dailyRebootTime - secondsSinceMidnight < 16 then
						message("say [" .. server.chatColour .. "]The server will reboot in " .. math.floor((dailyRebootTime - secondsSinceMidnight) / 60) .. " minutes.[-]")
						botman.scheduledRestartPaused = false
						botman.scheduledRestart = true
						botman.scheduledRestartTimestamp = os.time() + (dailyRebootTime - secondsSinceMidnight)
					end
				end
			end
		end
	end
end
