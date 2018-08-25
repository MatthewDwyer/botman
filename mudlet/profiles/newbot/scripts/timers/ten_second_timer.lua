--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function TenSecondTimer()
	if botman.botDisabled or botman.botOffline then
		return
	end

	if customTenSecondTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customTenSecondTimer() then
			return
		end
	end

	if server.lagged then
		-- test for telnet command lag as it can creep up on busy servers or when there are lots of telnet errors going on
		if not botman.botOffline and not botman.botDisabled then
			if server.enableLagCheck then
				botman.lagCheckTime = os.time()
				sendCommand("pm LagCheck " .. os.time())
			end

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end
		else
			if server.enableLagCheck then
				botman.lagCheckTime = os.time()
			end

			server.lagged = false
		end
	else
		if server.coppi and tonumber(botman.playersOnline) > 0 then
			if server.scanNoclip then
				sendCommand("pug")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end

			if not server.playersCanFly then
				sendCommand("pgd")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end
		end

		if (server.scanZombies or server.scanEntities) then
			if server.useAllocsWebAPI then
				 url = "http://" .. server.IP .. ":" .. server.webPanelPort + 2 .. "/api/gethostilelocation/?adminuser=" .. server.allocsWebAPIUser .. "&admintoken=" .. server.allocsWebAPIPassword
				 os.remove(homedir .. "/temp/hostiles.txt")
				 downloadFile(homedir .. "/temp/hostiles.txt", url)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end
		end
	end
end