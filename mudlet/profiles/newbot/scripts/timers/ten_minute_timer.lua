--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function TenMinuteTimer()
	-- if tonumber(botman.playersOnline) <= 0 then
		-- sendCommand("mem")
	-- end

	if customTenMinuteTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customTenMinuteTimer then
			return
		end
	end

	if relogCount > 5 then
		irc_chat(server.ircMain, "The bot is having trouble staying connected to the server.  The server may require a restart.")
	end
end
