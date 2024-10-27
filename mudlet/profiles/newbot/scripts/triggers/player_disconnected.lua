--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

local debug

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false


function playerDisconnected(line)
	local pos, temp, pid, tmp, igplayerFound, playerFound, k, v

	if (debug) then dbug("called playerDisconnected " .. line) end

	botman.playersOnline = tonumber(botman.playersOnline) - 1
	botStatus.playersOnline = botman.playersOnline
	tmp = {}

	tmp.temp = string.split(line, ",")

	for k,v in pairs(tmp.temp) do
		if string.find(v, "EntityID=") then
			tmp.split = string.split(v, "=")
			tmp.entityID = tmp.split[2]
		end

		if string.find(v, "PltfmId=") then
			tmp.split = string.split(v, "='")
			tmp.split = string.split(tmp.split[2], "_")
			tmp.platform = tmp.split[1]
			tmp.steam = string.sub(tmp.split[2], 1, string.len(tmp.split[2]) -1)
		end

		if string.find(v, "CrossId=") then
			tmp.split = string.split(v, "='")
			tmp.userID = string.sub(tmp.split[2], 1, string.len(tmp.split[2]) -1)
		end

		if string.find(v, "OwnerID=") then
			tmp.split = string.split(v, "='")
			tmp.steamOwner = string.sub(tmp.split[2], 1, string.len(tmp.split[2]) -1)

			if tmp.steamOwner == "<unknown/none>" then
				tmp.steamOwner = tmp.steam
			end
		end

		if string.find(v, "PlayerName='") then
			tmp.split = string.split(v, "='")
			tmp.name = string.sub(tmp.split[2], 1, string.len(tmp.split[2]) -1)
		end
	end

	igplayerFound = false
	playerFound	= false

	if igplayers[tmp.steam] then
		igplayerFound = true
		irc_chat(server.ircMain, botman.serverTime .. " " .. server.gameDate .. " " .. tmp.platform .. "_" .. tmp.steam .. " " .. tmp.name .. " disconnected at " .. igplayers[tmp.steam].xPos .. " " .. igplayers[tmp.steam].yPos ..  " " .. igplayers[tmp.steam].zPos)
		irc_chat(server.ircAlerts, server.gameDate .. " " .. tmp.platform .. "_" .. tmp.steam .. " " .. tmp.name .. " disconnected at " .. igplayers[tmp.steam].xPos .. " " .. igplayers[tmp.steam].yPos ..  " " .. igplayers[tmp.steam].zPos)
		logChat(botman.serverTime, "Server", botman.serverTime .. " " .. server.gameDate .. " " .. tmp.platform .. "_" .. tmp.steam .. " " .. tmp.name .. " disconnected")
		fixMissingIGPlayer(tmp.platform, tmp.steam, tmp.steamOwner , tmp.userID)
	end

	if players[tmp.steam] then
		playerFound	= true
	end

	if customPlayerDisconnected ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customPlayerDisconnected(line, tmp.entityID, tmp.steam, tmp.name) then
			return
		end
	end

	if debug then dbug("Saving disconnected player " .. igplayers[tmp.steam].name) end

	if playerFound then
		if players[tmp.steam].watchPlayer then
			irc_chat(server.ircWatch, server.gameDate .. " " .. tmp.platform .. "_" .. tmp.steam .. " " .. players[tmp.steam].name .. " disconnected")
		end

		-- log the player disconnection in events table
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam, userID) VALUES (0,0,0,'" .. botman.serverTime .. "','player left','Player disconnected " .. escape(players[tmp.steam].name) .. " " .. tmp.platform .. "_" .. tmp.steam .. " Owner " .. players[tmp.steam].steamOwner .. " " .. players[tmp.steam].id .. "','" .. players[tmp.steam].steamOwner .. "','" .. tmp.userID .. "')") end
	end

	-- attempt to insert the player into bots db players table
	if	botman.botsConnected then
		insertBotsPlayer(tmp.steam)
	end

	-- set the player offline in bots db
	--connBots:execute("UPDATE players set online = 0 where steam = '" .. tmp.steam .. "' AND botID = " .. server.botID)
	saveDisconnectedPlayer(tmp.steam)

	if tonumber(server.reservedSlots) > 0 then
		freeASlot(tmp.steam)
	end

	-- check how many claims they have placed
	sendCommand("llp " .. tmp.userID .. " parseable")

	-- -- clean up admin list
	-- if tablelength(staffListSteam) > 0 then
		-- if staffListSteam[tmp.steam] and tmp.userID then
			-- sendCommand("admin remove Steam_" .. tmp.steam)
			-- sendCommand("admin add " .. tmp.userID .. " " .. staffListSteam[tmp.steam].accessLevel)
			-- staffListSteam[tmp.steam] = nil
		-- end
	-- end

	if (debug) then dbug("playerDisconnected finished") end
end
