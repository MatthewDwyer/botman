--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
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
		-- the first part of the split is tele, 2nd part is the player being teleported
		cmd = string.split(cmd, " ")
		cmd[2] = stripQuotes(cmd[2])

		id = LookupPlayer(cmd[2], "all")
		igplayers[id].tp = 1
		igplayers[id].hackerTPScore = 0
		igplayers[id].spawnPending = true
		igplayers[id].lastTPTimestamp = os.time()
		return
	end

	if string.find(line, " from ") then
		if string.find(line, "teleportplayer") then
			cmd = string.sub(line, string.find(line, "teleportplayer "), string.find(line, "from") - 2)
			-- the first part of the split is tele, 2nd part is the player being teleported
			cmd = string.split(cmd, " ")
			cmd[2] = stripQuotes(cmd[2])

			id = LookupPlayer(cmd[2], "all")
			igplayers[id].tp = 1
			igplayers[id].hackerTPScore = 0
			igplayers[id].spawnPending = true
			igplayers[id].lastTPTimestamp = os.time()
			return
		end

		if string.find(line, "tele ") then
			cmd = string.sub(line, string.find(line, "tele "), string.find(line, "from") - 2)
			-- the first part of the split is tele, 2nd part is the player being teleported
			cmd = string.split(cmd, " ")
			cmd[2] = stripQuotes(cmd[2])

			id = LookupPlayer(cmd[2], "all")
			igplayers[id].tp = 1
			igplayers[id].hackserTPScore = 0
			igplayers[id].spawnPending = true
			igplayers[id].lastTPTimestamp = os.time()
			return
		end
	end
end
