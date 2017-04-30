--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function oneMinuteTimer()
	local k, v, days, hours, minutes
	
	fixMissingStuff()	

	if botman.botDisabled or botman.botOffline or server.lagged then
		return
	end	

	everyMinute()

	if tablelength(players) == 0 then
		gatherServerData()
		return
	end	

	if server.coppi then
		for k, v in pairs(igplayers) do
			if players[k].autoFriend ~= "NA" then
				send("lpf " .. k)
			end
		end
	end	
	
	if tonumber(server.maxPrisonTime) > 0 then
		-- check for players to release from prison
		for k,v in pairs(igplayers) do
			if tonumber(players[k].prisonReleaseTime) < os.time() and players[k].prisoner and tonumber(players[k].prisonReleaseTime) > 0 then
				gmsg(server.commandPrefix .. "release " .. k)
			else
				if players[k].prisoner then
					if players[k].prisonReleaseTime - os.time() < 86164 then					
						days, hours, minutes = timeRemaining(players[k].prisonReleaseTime)
						message("pm " .. k .. " [" .. server.chatColour .. "]You will be released in about " .. days .. " days " .. hours .. " hours and " .. minutes .. " minutes.[-]")
					end
				end
			end
		end	
	end

	botHeartbeat()
end
