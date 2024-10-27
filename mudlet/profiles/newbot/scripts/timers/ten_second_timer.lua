--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function TenSecondTimer()
	local k, v

	if botman.botDisabled or botman.botOffline then
		return
	end

	if customTenSecondTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customTenSecondTimer() then
			return
		end
	end

	if tonumber(botman.playersOnline) > 0 then
		if (server.scanZombies or server.scanEntities) then
			if server.useAllocsWebAPI then
				sendCommand("gethostilelocation")
			else
				sendCommand("le")
			end
		end
	end

	if tablelength(igplayers) ~= tonumber(botman.playersOnline) then
		if botman.playersOnline == 0 then
			playersOnlineList = {}
			igplayers = {}
			botman.oneMinuteTimer_faulty = false
		end

		if botman.oneMinuteTimer_faulty then
			for k,v in pairs(playersOnlineList) do
				if not igplayers[k] then
					-- this player has disconnected but is still in the igplayers table so we need to remove them
					igplayers[k] = nil
				end
			end
		end
	end

	if tablelength(igplayers) == 0 and tonumber(botman.playersOnline) == 0 and not botman.oneMinuteTimer_faulty then
		playersOnlineList = {}
	end
end