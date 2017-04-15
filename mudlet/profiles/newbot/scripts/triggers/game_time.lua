--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gameTimeTrigger(line)
	local word, words, k, v

	if botman.botDisabled then
		return
	end

	local words = {}

	for word in line:gmatch("%w+") do table.insert(words, word) end

	server.gameDate = string.trim(line)
	server.gameDay = words[2]
	server.gameHour = tonumber(words[3])
	server.gameMinute = words[4]
	server.gameDate = "Day " .. server.gameDay .. ", " ..string.format("%02d", server.gameHour) .. ":" .. server.gameMinute

	if (server.gameDay % 7 == 0) then
		if server.delayReboot == nil then
			server.delayReboot = false
		end

		if not server.delayReboot and botman.scheduledRestart then
			message("say [" .. server.chatColour .. "]Feral hordes run today so the server will reboot tomorrow.[-]")
			server.delayReboot = true
		end
	else
		if server.delayReboot and botman.scheduledRestart then
			if tonumber(server.feralRebootDelay) == 0 then
				botman.scheduledRestartTimestamp = os.time() + ((server.DayLightLength + server.DayNightLength) * 60)
				message("say [" .. server.chatColour .. "]The server will reboot in 1 game day (" .. server.DayLightLength + server.DayNightLength .. " minutes).[-]")
			else
				botman.scheduledRestartTimestamp = os.time() + (server.feralRebootDelay * 60)
				message("say [" .. server.chatColour .. "]The server will reboot in " .. server.feralRebootDelay .. " minutes.[-]")				
			end
		end

		server.delayReboot = false
	end

	if (tonumber(server.gameHour) == 0 and server.allowLottery == true) then
		if not botman.dailyDraw then
			drawLottery()
			botman.dailyDraw = true
		end
	else
		botman.dailyDraw = false
	end

	if tonumber(server.gameDay) < tonumber(server.gameDay) and tonumber(server.gameDay) > 0 and server.warnBotReset ~= true then
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

	conn:execute("UPDATE server SET server.gameDay = " .. server.gameDay)

	 --check locations for opening and closing times
	for k,v in pairs(locations) do
		if isLocationOpen(v.name) then
			if not v.open then
				message("say [" .. server.chatColour .. "]The location " .. v.name .. " is now open.[-]")
				v.open = true
			end
		else
			if v.open then
				message("say [" .. server.chatColour .. "]The location " .. v.name .. " has closed.[-]")
				v.open = false			
			end
		end
	end
end
