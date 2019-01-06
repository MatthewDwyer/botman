--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function lpTrigger(line)
	local uptime

	if botman.botDisabled then
		return
	end

	botman.listPlayers = true
	relogCount = 0

	if string.find(string.sub(line, 1, 19), os.date("%Y")) then
		-- 2016-09-11T04:14:28
		botman.serverTime = string.sub(line, 1, 10) .. " " .. string.sub(line, 12, 16)
		botman.serverHour = string.sub(line, 12, 13)
		botman.serverMinute = string.sub(line, 15, 16)
		specialDay = ""

		if (string.find(botman.serverTime, "02-14", 5, 10)) then specialDay = "valentine" end
		if (string.find(botman.serverTime, "12-25", 5, 10)) then specialDay = "christmas" end

		if server.dateTest == nil then
			server.dateTest = string.sub(botman.serverTime, 1, 10)
		end
	end

	if not server.useAllocsWebAPI then
		deleteLine()
	end

	if tonumber(botman.serverHour) == tonumber(server.botRestartHour) and server.allowBotRestarts then
		uptime = math.floor((os.difftime(os.time(), botman.botStarted) / 3600))

		if botman.customMudlet and (uptime > 1) then
			-- Mudlet will only automatically restart if you compiled TheFae's latest Mudlet and launched it from run-mudlet.sh with -r
			-- if the bot has been running less than 1 hour it won't restart itself.
			restartBot()
			return
		end
	end
end
