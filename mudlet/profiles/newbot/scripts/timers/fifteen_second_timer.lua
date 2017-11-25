--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function FifteenSecondTimer()
	if botman.botOffline or botman.botDisabled then
		return
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

	-- -- test for telnet command lag as it can creep up on busy servers or when there are lots of telnet errors going on
	-- if not botman.botOffline and not botman.botDisabled then
		-- botman.lagCheckTime = os.time()
		-- send("pm LagCheck " .. server.botID)

		-- if botman.getMetrics then
			-- metrics.telnetCommands = metrics.telnetCommands + 1
		-- end
	-- else
		-- botman.lagCheckTime = os.time()
		-- server.lagged = false
	-- end

	if server.lagged then
		return
	end

	send("gt")

	if botman.getMetrics then
		metrics.telnetCommands = metrics.telnetCommands + 1
	end

	if tonumber(botman.playersOnline) < 10 then
		-- if server.scanZombies or server.scanEntities then
			-- send("le")
		-- end

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