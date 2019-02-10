--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function TenSecondTimer()
	if botman.botDisabled or botman.botOffline then
		return
	end

	botHeartbeat()

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
		else
			if server.enableLagCheck then
				botman.lagCheckTime = os.time()
			end
		end

		server.lagged = false
	else
		if tonumber(botman.playersOnline) > 0 and tonumber(botman.playersOnline) < 25 then
			if server.coppi and tonumber(botman.playersOnline) > 0 then
				if server.scanNoclip and tonumber(server.gameVersionNumber) < 17 then
					if server.coppiRelease == "Mod CSMM Patrons" then
						sendCommand("pinc")
					else
						sendCommand("pug")
					end
				end

				if not server.playersCanFly and tonumber(server.gameVersionNumber) < 17 then
					if server.coppiRelease == "Mod CSMM Patrons" then
						sendCommand("cph")
					else
						sendCommand("pgd")
					end
				end
			end

			if (server.scanZombies or server.scanEntities) then
				if server.useAllocsWebAPI then
					sendCommand("gethostilelocation", "gethostilelocation?", "hostiles.txt")
				end
			end
		end
	end
end