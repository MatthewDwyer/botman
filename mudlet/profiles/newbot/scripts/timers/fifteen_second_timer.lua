--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function FifteenSecondTimer()
	if customFifteenSecondTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customFifteenSecondTimer() then
			return
		end
	end

	-- run a quick test to prove or disprove that we are still connected to the database incase we've fallen off :O
	if not botman.dbConnected then
		openDB()
		openSQLiteDB()
	end

	-- force a re-test of the connection to the bot's database
	botman.dbConnected = isDBConnected()

	if not botman.botsConnected then
		openBotsDB()
	end

	-- force a re-test of the connection to the shared database called bots
	botman.botsConnected = isDBBotsConnected()

	if not server.lagged then
		if tonumber(botman.playersOnline) > 24 then
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