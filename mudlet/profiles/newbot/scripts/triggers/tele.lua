--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function teleTrigger(line)
	if botman.botDisabled then
		return
	end

	local player, id, cmd, adminName, adminSteam

	if string.find(line, "tele ") and string.find(line, "by Telnet") then
		cmd = string.sub(line, string.find(line, "tele "), string.find(line, "by Telnet") - 2)
		-- the first player is the player being teleported
		player = string.match(cmd, "\"(.*)\"%s")

		if player == nil then
			player = string.split(cmd, " ")
			player = stripQuotes(player[2])
		end

		id = LookupPlayer(player, "all")
		igplayers[id].tp = 1
		igplayers[id].hackerTPScore = 0
		igplayers[id].spawnPending = true
		igplayers[id].lastTPTimestamp = os.time()
		return
	end

	if string.find(line, " from ") then
		if string.find(line, "from client") then
			-- Sweet! An admin sent this command.  Let's get them!
			adminName = string.sub(line, string.find(line, "from client") + 12)

			if not players[adminName] then
				adminSteam = LookupPlayer(adminName)
			else
				adminSteam = adminName
				adminName = players[adminName].name
			end

			id = string.sub(line, string.find(line, "'tele ") + 6, string.find(line, "' from client") -1)

			if string.find(id, adminName) then
				id = string.sub(id, 1, string.find(id, adminName) - 2)
			end

			if string.find(id, adminSteam) then
				id = string.sub(id, 1, string.find(id, adminSteam) - 2)
			end

			id = string.trim(id)
			id = stripQuotes(id)

			if igplayers[id] then
				igplayers[id].tp = 1
				igplayers[id].hackerTPScore = 0
				igplayers[id].spawnPending = true
				igplayers[id].lastTPTimestamp = os.time()
				return
			end
		end

		if string.find(line, "teleportplayer") then
			cmd = string.sub(line, string.find(line, "teleportplayer "), string.find(line, "from") - 2)
			-- the first player is the player being teleported
			player = string.match(cmd, "\"(.*)\"%s")

			if player == nil then
				player = string.split(cmd, " ")
				player = stripQuotes(player[2])
			end

			id = LookupPlayer(player, "all")
			igplayers[id].tp = 1
			igplayers[id].hackerTPScore = 0
			igplayers[id].spawnPending = true
			igplayers[id].lastTPTimestamp = os.time()
			return
		end

		if string.find(line, "tele ") then
			cmd = string.sub(line, string.find(line, "tele "), string.find(line, "from") - 2)
			-- the first player is the player being teleported

			player = string.match(cmd, "\"(.*)\"%s")

			if player == nil then
				player = string.split(cmd, " ")
				player = stripQuotes(player[2])
			end

			if not igplayers[player] then
				id = LookupPlayer(player, "all")
			else
				id = player
			end

			igplayers[id].tp = 1
			igplayers[id].hackserTPScore = 0
			igplayers[id].spawnPending = true
			igplayers[id].lastTPTimestamp = os.time()
			return
		end
	end
end