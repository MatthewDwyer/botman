--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
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

	if tonumber(botman.serverHour) == tonumber(server.botRestartHour) and server.allowBotRestarts then
		uptime = math.floor((os.difftime(os.time(), botman.botStarted) / 3600))

		if uptime > 1 then
			-- if the bot has been running less than 1 hour it won't restart itself.
			restartBot()
			return
		end
	end
end
