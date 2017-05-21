--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function listPlayers()
	local k,v

	if botman.botDisabled or botman.botOffline or server.lagged then
		return
	end

	if botman.finalCountdown == nil then
		botman.finalCountdown = false
	end

	server.scanZombies = false
	send("lp")

	if (botman.scheduledRestart == true and botman.scheduledRestartPaused == false) and server.allowReboot == true then

		if server.delayReboot == nil then
			server.delayReboot = false
		end

		if not server.delayReboot then
			if (botman.scheduledRestartTimestamp - os.time() < 0) then
				startReboot()
			else
				if (botman.scheduledRestartTimestamp - os.time() > 11) and (botman.scheduledRestartTimestamp - os.time() < 61) then
					message("say [" .. server.warnColour .. "]REBOOTING IN " .. botman.scheduledRestartTimestamp - os.time() .. " SECONDS[-]")
					botman.finalCountdown = false
				end

				if (botman.scheduledRestartTimestamp - os.time() < 12) and not botman.finalCountdown then
					botman.finalCountdown = true

					tempTimer( 1, [[message("say [" .. server.alertColour .. "]10[-]")]] )
					tempTimer( 2, [[message("say [" .. server.alertColour .. "]9[-]")]] )
					tempTimer( 3, [[message("say [" .. server.alertColour .. "]8[-]")]] )
					tempTimer( 4, [[message("say [" .. server.alertColour .. "]7[-]")]] )
					tempTimer( 5, [[message("say [" .. server.alertColour .. "]6[-]")]] )
					tempTimer( 6, [[message("say [" .. server.alertColour .. "]5[-]")]] )
					tempTimer( 7, [[message("say [" .. server.alertColour .. "]4[-]")]] )
					tempTimer( 8, [[message("say [" .. server.alertColour .. "]3[-]")]] )
					tempTimer( 9, [[message("say [" .. server.alertColour .. "]2[-]")]] )
					tempTimer( 10, [[message("say [" .. server.alertColour .. "]1[-]")]] )
					tempTimer( 11, [[message("say [" .. server.alertColour .. "]Rebooting..[-]")]] )
				end
			end
		end
	end

	if server.idleKick and (tonumber(botman.playersOnline) == tonumber(server.maxPlayers)) then
		for k,v in pairs(igplayers) do
			if (igplayers[k].afk - os.time() < 61) and accessLevel(k) > 2 then
				message("pm " .. k .. " [" .. server.alertColour .. "]Kicking you for idling in " .. igplayers[k].afk - os.time() .. "[-]")
			end
		end
	end
end
