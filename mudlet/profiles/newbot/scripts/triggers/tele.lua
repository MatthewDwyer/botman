--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function teleTrigger(line)
	if botDisabled then
		return
	end

	local player, id, cmd

	if string.find(line, "from ") then
		cmd = string.sub(line, string.find(line, "tele "), string.find(line, "from") - 3)
		cmd = string.split(cmd, " ")

		i = table.maxn(cmd)
		id = LookupPlayer(cmd[2])
		players[id].tp = 1
		players[id].hackerScore = 0
	end

	if string.find(line, server.botsIP) then
		cmd = string.sub(line, string.find(line, "tele "), string.find(line, "by Telnet") - 3)
		cmd = string.split(cmd, " ")

		id = cmd[2]
		players[id].tp = 1
		players[id].hackerScore = 0
	end
end
