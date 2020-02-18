--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gameTimeTrigger(line)
	local word, words, k, v, closed, closingSoon, oldGameDay, temp

	if botman.botDisabled then
		return
	end

	local words = {}

	for word in line:gmatch("%w+") do table.insert(words, word) end

	if server.useAllocsWebAPI then
		-- we successfully sent a command to telnet so reset relogCount.
		-- If we can't talk to it, after several relog attempts we'll message IRC to let someone know there's a problem with telnet.
		relogCount = 0
	end

	server.gameDate = string.trim(line)
	oldGameDay = server.gameDay
	server.gameDay = words[2]
	server.gameHour = tonumber(words[3])
	server.gameMinute = words[4]
	server.gameDate = "Day " .. server.gameDay .. ", " ..string.format("%02d", server.gameHour) .. ":" .. server.gameMinute

	if (server.gameDay % server.hordeNight == 0) then
		if server.BloodMoonRange then
			if tonumber(server.BloodMoonRange) == 0 then
				botman.hordeNightToday = true
				botman.hordeNightYesterday = false

				if server.delayReboot == nil then
					server.delayReboot = false
				end

				if not server.delayReboot and botman.scheduledRestart then
					message("say [" .. server.chatColour .. "]Feral hordes run today so the server will reboot tomorrow.[-]")
					server.delayReboot = true
				end
			end
		else
			botman.hordeNightToday = true
			botman.hordeNightYesterday = false

			if server.delayReboot == nil then
				server.delayReboot = false
			end

			if not server.delayReboot and botman.scheduledRestart then
				message("say [" .. server.chatColour .. "]Feral hordes run today so the server will reboot tomorrow.[-]")
				server.delayReboot = true
			end
		end
	else
		botman.hordeNightToday = false
		botman.hordeNightYesterday = true

		if server.delayReboot and botman.scheduledRestart then
			if tonumber(server.feralRebootDelay) == 0 then
				botman.scheduledRestartTimestamp = os.time() + ((server.DayLightLength + server.DayNightLength) * 60)
			else
				botman.scheduledRestartTimestamp = os.time() + (server.feralRebootDelay * 60)
			end
		end

		server.delayReboot = false
	end

	if (botman.hordeNightToday and tonumber(server.gameHour) == 21 and tonumber(server.gameMinute) > 45 and server.despawnZombiesBeforeBloodMoon and server.stompy) then
		if server.BloodMoonRange then
			if tonumber(server.BloodMoonRange) == 0 then
				sendCommand("bc-remove /type=EntityZombie")
				sendCommand("bc-remove /type=EntityZombieCrawl")
			end
		else
			sendCommand("bc-remove /type=EntityZombie")
			sendCommand("bc-remove /type=EntityZombieCrawl")
		end
	end

	if (tonumber(server.gameHour) == 0 and server.allowLottery == true) then
		if not botman.dailyDraw then
			drawLottery()
			botman.dailyDraw = true
		end
	else
		botman.dailyDraw = false
	end

	if tonumber(server.gameDay) < tonumber(oldGameDay) and tonumber(server.gameDay) > 0 and not server.warnBotReset then
		if tonumber(server.gameDay) < 5 then
			-- the server date has rolled back.  try to alert any level 0 admin that the bot may need a reset too.
			server.warnBotReset = true

			for k,v in pairs(igplayers) do
				if accessLevel(k) == 0 then
					message("pm " .. k .. " [" .. server.chatColour .. "]ALERT!  It appears that the server has been reset but not the bot.[-]")
					message("pm " .. k .. " [" .. server.chatColour .. "]To reset me type " .. server.commandPrefix .. "reset bot.[-]")
					message("pm " .. k .. " [" .. server.chatColour .. "]To dismiss this alert type " .. server.commandPrefix .. "no reset.[-]")
				end
			end
		end
	end

	if tonumber(server.gameDay) > tonumber(oldGameDay) or not botman.day7Message then
		botman.HordeInDays = day7ForPanel()
	end

	if botman.dbConnected then conn:execute("UPDATE server SET server.gameDay = " .. server.gameDay) end

	 --check locations for opening and closing times
	for k,v in pairs(locations) do
		closed, closingSoon = isLocationOpen(v.name)

		if isLocationOpen(v.name) then
			if not v.open then
				message("say [" .. server.chatColour .. "]The location called " .. v.name .. " is now open.[-]")
				v.open = true
			end
		else
			if v.open then
				message("say [" .. server.chatColour .. "]The location called " .. v.name .. " has closed.[-]")
				v.open = false
			end
		end

		if closingSoon then
			if not v.closingSoon then
				message("say [" .. server.chatColour .. "]The location called " .. v.name .. " is closing soon.[-]")
				v.closingSoon = true
			end
		else
			v.closingSoon = false
		end
	end

	if not server.useAllocsWebAPI then
		deleteLine()
	end
end
