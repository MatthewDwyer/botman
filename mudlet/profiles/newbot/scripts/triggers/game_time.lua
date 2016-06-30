--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gameTimeTrigger(line)
	if botDisabled then
		return
	end

	local words = {}

	for word in line:gmatch("%w+") do table.insert(words, word) end

	gameDate = string.trim(line)
	gameDay = words[2]
	gameHour = tonumber(words[3])
	gameMinute = words[4]
	gameDate = "Day " .. gameDay .. ", " ..string.format("%02d", gameHour) .. ":" .. gameMinute
	
	if (gameDay % 7 == 0) then
		if server.delayReboot == nil then
			server.delayReboot = false
		end
	
		if not server.delayReboot and server.scheduledRestart then
			message("say [" .. server.chatColour .. "]Feral hordes run today so the server will not be rebooting until tomorrow or later.[-]")
			server.delayReboot = true
		end
	else	
		if server.delayReboot and server.scheduledRestart == true then
			if (server.scheduledRestartTimestamp - os.time()) < 0 then
				server.scheduledRestartTimestamp = os.time() + 1200
				message("say [" .. server.chatColour .. "]The server will reboot in 20 minutes.[-]")
			end
		end
		
		server.delayReboot = false
	end

	--if (gameDay % 7 == 0) then
	--	if (tonumber(gameHour) == 17) then
	--		if (feralWarning == false) then
	--			message("say [" .. server.chatColour .. "]Feral hordes will run tonight![-]")
	--			feralWarning = true
	--		end
	--	else
	--		feralWarning = false
	--	end
	--end


	if (tonumber(gameHour) == 0 and server.allowShop == true and server.allowLottery == true) then
		if 	dailyDraw == false then
			drawLottery()
			dailyDraw = true
		end
	else
		dailyDraw = false
	end

	if tonumber(gameDay) < tonumber(server.gameDay) and tonumber(server.gameDay) > 0 and server.warnBotReset ~= true then
		if tonumber(server.gameDay) < 10 then
			-- the server date has rolled back.  try to alert any level 0 admin that the bot may need a reset too.
			server.warnBotReset = true

			for k,v in pairs(igplayers) do
				if accessLevel(k) == 0 then
					message("pm " .. k .. " [" .. server.chatColour .. "]ALERT!  It appears that the server has been reset.[-]")
					message("pm " .. k .. " [" .. server.chatColour .. "]To reset me type /reset bot.[-]")
					message("pm " .. k .. " [" .. server.chatColour .. "]To dismiss this alert type /no reset.[-]")
				end
			end
		end
	end

	server.gameDay = gameDay
	conn:execute("UPDATE server SET gameDay = " .. gameDay)
end
