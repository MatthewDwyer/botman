--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug = false
function FifteenSecondTimer()
	-- run a quick test to prove or disprove that we are still connected to the database.
	-- there is a rare instance where we lose the connection for unknown reasons.

	if not botman.dbConnected then
		--conn = env:connect(botDB, botDBUser, botDBPass)
		openDB()
	end

	-- this looks weird but its the only way that works
	botman.dbConnected = false
	botman.dbConnected = isDBConnected()

	if not botman.db2Connected then
		--connBots = env:connect(botsDB, botsDBUser, botsDBPass)
		openBotsDB()
	end

	botman.db2Connected = false
	botman.db2Connected = isDBBotsConnected()

	if botman.botOffline or botman.botDisabled or server.lagged then
		return
	end

	send("gt")

	if tonumber(botman.playersOnline) > 0 then
		if server.scanZombies or server.scanEntities then
			send("le")
		end

		if server.coppi then
			if server.scanNoclip then
				-- check for noclipped players
				for k,v in pairs(igplayers) do
					if(tonumber(k) > 0) then 
						if(not players[k]) then
							if(debug) then 
								dbugFull("D", "",debugger.getinfo(1,"nSl"), k .. " is in igplayers but not players!")
							end
						elseif players[k].newPlayer or tonumber(players[k].ping) > 150 then
							send("pug " .. k)
						end
					end
				end
			end

			if not server.playersCanFly then
				-- check for flying players
				for k,v in pairs(igplayers) do
					if(not players[k]) then
						if(debug) then 
							dbugFull("D", "",debugger.getinfo(1,"nSl"), k .. " is in igplayers but not players!")
						end
				 	elseif players[k].newPlayer or tonumber(players[k].ping) > 150 then
						send("pgd " .. k)
					end
				end
			end
		end
	end
end
