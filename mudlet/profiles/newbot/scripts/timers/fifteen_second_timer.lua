--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function FifteenSecondTimer()
	if botman.botOffline or botman.botDisabled then
		return
	end

	if customFifteenSecondTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customFifteenSecondTimer() then
			return
		end
	end

	-- run a quick test to prove or disprove that we are still connected to the database.
	-- there is a rare instance where we lose the connection for unknown reasons.

	if not botman.dbConnected then
		openDB()
	end

	-- this looks weird but its the only way that works
	botman.dbConnected = false
	botman.dbConnected = isDBConnected()

	if not botman.db2Connected then
		openBotsDB()
	end

	botman.db2Connected = false
	botman.db2Connected = isDBBotsConnected()

	if server.lagged then
		return
	end

	send("gt")

	if botman.getMetrics then
		metrics.telnetCommands = metrics.telnetCommands + 1
	end

	if tonumber(botman.playersOnline) < 10 then
		if server.coppi then
			if server.scanNoclip then
				-- check for noclipped players
				for k,v in pairs(igplayers) do
					if tonumber(players[k].accessLevel) > 2 then
						send("pug " .. k)

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end
					end
				end
			end

			if not server.playersCanFly then
				-- check for flying players
				for k,v in pairs(igplayers) do
					if tonumber(players[k].accessLevel) > 2 then
						send("pgd " .. k)

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end
					end
				end
			end
		end
	end
end