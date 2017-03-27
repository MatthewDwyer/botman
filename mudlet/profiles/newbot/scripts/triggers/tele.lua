--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function teleTrigger(line)
	if botman.botDisabled then
		return
	end
	
	local player, id, cmd, legit, client
	
	legit = true
	
	if string.find(line, "client") then
		client = string.sub(line, string.find(line, "client") + 7)
		if accessLevel(client) > 2 then legit = false end
	end

	if string.find(line, "from ") and legit then
		cmd = string.sub(line, string.find(line, "tele "), string.find(line, "from") - 3)
		cmd = string.split(cmd, " ")		
		id = LookupPlayer(cmd[2])
		players[id].tp = 1
		players[id].hackerTPScore = 0
	end
	
	if string.find(line, "from ") and legit then
		cmd = string.sub(line, string.find(line, "teleportplayer "), string.find(line, "from") - 3)
		cmd = string.split(cmd, " ")		
		id = LookupPlayer(cmd[2])
		players[id].tp = 1
		players[id].hackerTPScore = 0
	end	

	if string.find(line, "tele ") and string.find(line, "by Telnet") then	
		cmd = string.sub(line, string.find(line, "tele "), string.find(line, "by Telnet") - 3)
		cmd = string.split(cmd, " ")
		id = cmd[2]
		players[id].tp = 1
		players[id].hackerTPScore = 0
	end
end
