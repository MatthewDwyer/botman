--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function lpTrigger(line)
	local uptime

	if botman.botDisabled then
		return
	end

	if botman.trackingTicker == nil then
		botman.trackingTicker = 0
	end

	botman.trackingTicker = botman.trackingTicker + 1

	botman.listPlayers = true
	relogCount = 0
	playersOnlineList = {}
	botStatus.playersOnlineList = {}

	if tonumber(botman.serverHour) == tonumber(server.botRestartHour) and server.allowBotRestarts then
		uptime = math.floor((os.difftime(os.time(), botman.botStarted) / 3600))

		if uptime > 1 then
			-- if the bot has been running less than 1 hour it won't restart itself.
			restartBot()
			return
		end
	end
end
