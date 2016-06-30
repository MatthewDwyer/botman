--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function twoMinuteTimer()
	-- to fix a weird bug where the bot would stop responding to chat but could be woken up by irc chatter we send the bots a wake up call
	irc_QueueMsg(server.ircBotName, "Wake up!")	
end
