--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]	
	
function FifteenSecondTimer()
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
					if players[k].newPlayer or tonumber(players[k].ping) > 150 then
						send("pug " .. k)
					end
				end
			end
			
			if not server.playersCanFly then
				-- check for flying players
				for k,v in pairs(igplayers) do
					if players[k].newPlayer or tonumber(players[k].ping) > 150 then
						send("pgd " .. k)
					end
				end				
			end				
		end		
	end
end