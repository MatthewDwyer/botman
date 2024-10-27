--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function listPlayers()
	local k,v
	local httpHeaders = {["X-SDTD-API-TOKENNAME"] = server.allocsWebAPIUser, ["X-SDTD-API-SECRET"] = server.allocsWebAPIPassword}

	if botman.botDisabled or botman.botOffline then
		return
	end

	if botman.finalCountdown == nil then
		botman.finalCountdown = false
	end

	server.scanZombies = false

	if tonumber(botman.playersOnline) ~= 0 then
		if botman.skipLP == nil then
			botman.skipLP = -1
		end

		if tonumber(botman.playersOnline) > 24 then
			botman.skipLP = botman.skipLP + 1
		else
			botman.skipLP = 0
		end

		if botman.skipLP == 0 then
			if server.useAllocsWebAPI then
				url = "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/getplayersonline"

				if not botman.lpSentTimestamp then
					botman.lpSentTimestamp = os.time()
				end

				postHTTP("", "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/getplayersonline", httpHeaders)
			else
				sendCommand("lp")
			end
		end

		if botman.skipLP == 0 then
			botman.skipLP = -2
		end
	end

	if (botman.scheduledRestart == true and botman.scheduledRestartPaused == false) and server.allowReboot == true then
		if server.delayReboot == nil then
			server.delayReboot = false
		end

		if not server.delayReboot then
			if (botman.scheduledRestartTimestamp - os.time() < 0) and not botman.serverRebooting then
				startReboot()
			else
				if (botman.scheduledRestartTimestamp - os.time() > 11) and (botman.scheduledRestartTimestamp - os.time() < 61) then
					message("say [" .. server.warnColour .. "]Rebooting in " .. botman.scheduledRestartTimestamp - os.time() .. " seconds[-]")
					botman.finalCountdown = false
				end

				if (botman.scheduledRestartTimestamp - os.time() < 12) and not botman.finalCountdown then
					botman.finalCountdown = true -- Its the final countdown!

					rebootCountDown1 = tempTimer( 1, [[message("say [" .. server.alertColour .. "]Rebooting in 10 seconds[-]")]] )
					--rebootCountDown2 = tempTimer( 2, [[message("say [" .. server.alertColour .. "]9[-]")]] )
					--rebootCountDown3 = tempTimer( 3, [[message("say [" .. server.alertColour .. "]8[-]")]] )
					--rebootCountDown4 = tempTimer( 4, [[message("say [" .. server.alertColour .. "]7[-]")]] )
					--rebootCountDown5 = tempTimer( 5, [[message("say [" .. server.alertColour .. "]6[-]")]] )
					--rebootCountDown6 = tempTimer( 6, [[message("say [" .. server.alertColour .. "]5[-]")]] )
					--rebootCountDown7 = tempTimer( 7, [[message("say [" .. server.alertColour .. "]4[-]")]] )
					--rebootCountDown8 = tempTimer( 8, [[message("say [" .. server.alertColour .. "]3[-]")]] )
					--rebootCountDown9 = tempTimer( 9, [[message("say [" .. server.alertColour .. "]2[-]")]] )
					--rebootCountDown10 = tempTimer( 10, [[message("say [" .. server.alertColour .. "]1[-]")]] )
					rebootCountDown11 = tempTimer( 11, [[message("say [" .. server.alertColour .. "]Rebooting..[-]")]] )
				end
			end
		end
	end

	-- piggy-back on this timer to run the persistentQueue.
	persistentQueueTimer()

	-- also process spawnable items if we are validating gimme and shop items.
	if not botman.spawnableItemsQueueEmpty then
		spawnableItemsQueue()
	end
end
