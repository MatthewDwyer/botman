--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false

function playerDisconnected(line)
	local steam, playerID, entityID, name, pos, temp

if (debug) then dbug("debug playerDisconnected line " .. line) end

	botman.playersOnline = tonumber(botman.playersOnline) - 1

	local _, commas = string.gsub(line, ",", "")

	if commas ~= 3 then
		-- don't process if the line is invalid
		return
	end

if (debug) then dbug("debug playerDisconnected line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "Player disconnected:") then
		temp = string.split(line, ",")
		entityID = string.sub(temp[1], string.find(temp[1], "EntityID=") + 9)
		steam = string.match(temp[2], "(%d+)")
		name = stripQuotes(string.sub(temp[4], 13, string.len(temp[4])))

		conn:execute("delete from reservedSlots where steam = " .. steam)

		if players[steam] == nil then
			initNewPlayer(steam, name, entityID, steam)
		end

if (debug) then dbug("debug playerDisconnected line " .. debugger.getinfo(1).currentline) end

		if igplayers[steam] == nil then
			initNewIGPlayer(steam, name, entityID, steam)
		end

if (debug) then dbug("debug playerDisconnected line " .. debugger.getinfo(1).currentline) end

		fixMissingPlayer(steam)
		fixMissingIGPlayer(steam)

if (debug) then dbug("debug playerDisconnected line " .. debugger.getinfo(1).currentline) end

		-- 2016-09-11T04:14:28
		botman.serverTime = string.sub(line, 1, 10) .. " " .. string.sub(line, 12, 16)
		botman.serverHour = string.sub(line, 12, 13)
		botman.serverMinute = string.sub(line, 15, 16)

		if server.dateTest == nil then
			server.dateTest = string.sub(botman.serverTime, 1, 10)
		end

if (debug) then dbug("debug playerDisconnected line " .. debugger.getinfo(1).currentline) end

		if customPlayerDisconnected ~= nil then
			-- read the note on overriding bot code in custom/custom_functions.lua
			if customPlayerDisconnected(line, entityID, steam, name) then
				return
			end
		end

		dbug("Saving disconnected player " .. igplayers[steam].name)

if (debug) then dbug("debug playerDisconnected line " .. debugger.getinfo(1).currentline) end

		irc_chat(server.ircMain, botman.serverTime .. " " .. server.gameDate .. " " .. steam .. " " .. players[steam].name .. " disconnected")
		irc_chat(server.ircAlerts, server.gameDate .. " " .. steam .. " " .. players[steam].name .. " disconnected")
		logChat(botman.serverTime, "Server", botman.serverTime .. " " .. server.gameDate .. " " .. steam .. " " .. players[steam].name .. " disconnected")

		if players[steam].watchPlayer then
			irc_chat(server.ircWatch, server.gameDate .. " " .. steam .. " " .. players[steam].name .. " disconnected")
		end

		-- attempt to insert the player into bots db players table
		if	botman.db2Connected then
			insertBotsPlayer(steam)
		end

		saveDisconnectedPlayer(steam)

		-- set the player offline in bots db
		connBots:execute("UPDATE players set online = 0 where steam = " .. steam .. " AND botID = " .. server.botID)

		-- log the player connection in events table
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','player left','Player disconnected " .. escape(players[steam].name) .. " " .. steam .. " Owner " .. players[steam].steamOwner .. " " .. players[steam].id .. "'," .. players[steam].steamOwner .. ")") end

		-- check how many claims they have placed
		sendCommand("llp " .. steam .. " parseable")
	end
end
