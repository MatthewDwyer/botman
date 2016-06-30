--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function playerDisconnected(line)
	local steam, pos

	if botDisabled then
		return
	end

	if string.find(line, "Player disconnected:") then
		pos = string.find(line, "PlayerID='") + 10
		steam = string.sub(line, pos, pos + 16)

		serverTime = string.sub(line, 1, 19)
		newDay()

		dbug("Saving disconnected player " .. igplayers[steam].name)

		playerDisconnected(steam)

		irc_QueueMsg(server.ircMain, gameDate .. " " .. steam .. " " .. players[steam].name .. " disconnected")
		irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. players[steam].name .. " disconnected")
		logChat(serverTime, "Server", steam .. " " .. players[steam].name .. " disconnected")

		-- check how many claims they have placed
		send("llp " .. steam)
	end
end
