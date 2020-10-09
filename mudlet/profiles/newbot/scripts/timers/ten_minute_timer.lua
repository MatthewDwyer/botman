--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function TenMinuteTimer()
	if tonumber(server.uptime) == 0 then
		if server.botman then
			sendCommand("bm-uptime")
		end

		if not server.botman and server.stompy then
			sendCommand("bc-time")
		end
	end

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
