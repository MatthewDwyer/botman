--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function reconnectTimer()
	if botDisabled then
		return
	end

	botOffline = tonumber(botOffline) - 1

	if tonumber(botOffline) < 1 then
		dbug("Bot is offline - attempting reconnection.")
		botOffline = 2
		reconnect()
	end
end
