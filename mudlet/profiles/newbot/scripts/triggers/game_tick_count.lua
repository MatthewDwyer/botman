--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gameTickCountTrigger(line)
	if botman.botDisabled then
		return
	end

	local diff, days, hours

	-- grab the tick counter
	test = string.sub(line, string.find(line, ":") + 7, string.find(line, " INF"))
	gameTick = tonumber(test)

	if botman.nextRebootTest ~= nil and os.time() < botman.nextRebootTest then
		return
	end

	if gameTick > 0 then
		server.uptime = gameTick
	else
		server.uptime = os.time() - botman.botStarted
	end

	if gameTick < 0 and botman.scheduledRestart == false and server.allowReboot == true then
		gmsg(server.commandPrefix .. "reboot server in 5 minutes", 0)
		message("say [" .. server.chatColour .. "]A fault has been detected. A reboot should fix it.[-]")
	end

	diff = gameTick
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (days * 24) + hours >= tonumber(server.maxServerUptime) and botman.scheduledRestart == false and server.allowReboot == true then
		message("say [" .. server.chatColour .. "]The server will reboot in 15 minutes.[-]")
		botman.scheduledRestartPaused = false
		botman.scheduledRestart = true
		botman.scheduledRestartTimestamp = os.time() + 900		
	end
end
