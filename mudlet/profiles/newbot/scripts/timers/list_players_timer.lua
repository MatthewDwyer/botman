--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function listPlayers()
	if botDisabled then
		return
	end

	if finalCountdown == nil then
		finalCountdown = false
	end

	scanZombies = false
	send("lp")

	if (server.scheduledRestart == true and scheduledRestartPaused == false) and server.allowReboot == true then
	
		if server.delayReboot == nil then
			server.delayReboot = false
		end
		
		if not server.delayReboot then
			if (server.scheduledRestartTimestamp - os.time() < 0) then
				startReboot()
			else
				if (server.scheduledRestartTimestamp - os.time() > 11) and (server.scheduledRestartTimestamp - os.time() < 61) then
					message("say [" .. server.chatColour .. "]REBOOTING IN " .. server.scheduledRestartTimestamp - os.time() .. " SECONDS[-]")
					finalCountdown = false
				end

				if (server.scheduledRestartTimestamp - os.time() < 12) and not finalCountdown then
					finalCountdown = true

					tempTimer( 1, [[message("say [" .. server.chatColour .. "]10[-]")]] )
					tempTimer( 2, [[message("say [" .. server.chatColour .. "]9[-]")]] )
					tempTimer( 3, [[message("say [" .. server.chatColour .. "]8[-]")]] )
					tempTimer( 4, [[message("say [" .. server.chatColour .. "]7[-]")]] )
					tempTimer( 5, [[message("say [" .. server.chatColour .. "]6[-]")]] )
					tempTimer( 6, [[message("say [" .. server.chatColour .. "]5[-]")]] )
					tempTimer( 7, [[message("say [" .. server.chatColour .. "]4[-]")]] )
					tempTimer( 8, [[message("say [" .. server.chatColour .. "]3[-]")]] )
					tempTimer( 9, [[message("say [" .. server.chatColour .. "]2[-]")]] )
					tempTimer( 10, [[message("say [" .. server.chatColour .. "]1[-]")]] )
					tempTimer( 11, [[message("say [" .. server.chatColour .. "]Rebooting..[-]")]] )
				end
			end
		end
	end
	
	if tonumber(playersOnline) > 0 then
		-- check for flying players
		send("ubex_fapgd 5")
	end
end
