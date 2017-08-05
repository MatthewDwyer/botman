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

	local player, id, cmd, client

	if string.find(line, "tele ") and string.find(line, "by Telnet") then
		cmd = string.sub(line, string.find(line, "tele "), string.find(line, "by Telnet") - 2)
		cmd = string.split(cmd, " ")
		cmd[2] = stripQuotes(cmd[2])		

		-- the first part of the split is tele, 2nd part is the player being teleported
		id = cmd[2]
		players[id].tp = 1
		players[id].hackerTPScore = 0
		return
	end

	if string.find(line, "from ") then
		if string.find(line, "teleportplayer") then
			cmd = string.sub(line, string.find(line, "teleportplayer "), string.find(line, "from") - 2)
			cmd = string.split(cmd, " ")
			cmd[2] = stripQuotes(cmd[2])
			-- the first part of the split is tele, 2nd part is the player being teleported
			

			id = LookupPlayer(cmd[2], "all")
			players[id].tp = 1
			players[id].hackerTPScore = 0
			return
		end

		if string.find(line, "tele ") then
			cmd = string.sub(line, string.find(line, "tele "), string.find(line, "from") - 2)
			cmd = string.split(cmd, " ")
			cmd[2] = stripQuotes(cmd[2])
			-- the first part of the split is tele, 2nd part is the player being teleported

			id = LookupPlayer(cmd[2], "all")
			players[id].tp = 1
			players[id].hackerTPScore = 0
			return
		end
	end
end
