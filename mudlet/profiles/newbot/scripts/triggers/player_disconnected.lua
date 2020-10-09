--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false

function playerDisconnected(line)
	local pos, temp, pid, tmp

if (debug) then dbug("debug playerDisconnected line " .. line) end

	botman.playersOnline = tonumber(botman.playersOnline) - 1

	local _, commas = string.gsub(line, ",", "")

	if commas ~= 3 then
		-- don't process if the line is invalid
		return
	end

	tmp = {}

if (debug) then dbug("debug playerDisconnected line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "Player disconnected:") then
		temp = string.split(line, ",")
		tmp.temp = string.split(temp[1], "=")
		tmp.entityID = tmp.temp[2]
		tmp.steam = string.match(temp[2], "(%d+)")
		tmp.name = stripQuotes(string.sub(temp[4], 13, string.len(temp[4])))

		if igplayers[tmp.steam] then
			irc_chat(server.ircMain, botman.serverTime .. " " .. server.gameDate .. " " .. tmp.steam .. " " .. tmp.name .. " disconnected")
			irc_chat(server.ircAlerts, server.gameDate .. " " .. tmp.steam .. " " .. tmp.name .. " disconnected")
			logChat(botman.serverTime, "Server", botman.serverTime .. " " .. server.gameDate .. " " .. tmp.steam .. " " .. tmp.name .. " disconnected")
		end

		pid = LookupPlayer(tmp.steam)

		if pid == 0 then
			--logAlerts(botman.serverTime, "Call to initNewPlayer from PlayerDisconnected function using " .. line)
			--initNewPlayer(tmp.steam, tmp.name, tmp.entityID, tmp.steam, line)
			return
		end

if (debug) then dbug("debug playerDisconnected line " .. debugger.getinfo(1).currentline) end

		if not igplayers[tmp.steam] then
			initNewIGPlayer(tmp.steam, tmp.name, tmp.entityID, tmp.steam)
		end

if (debug) then dbug("debug playerDisconnected line " .. debugger.getinfo(1).currentline) end

		fixMissingPlayer(tmp.steam)
		fixMissingIGPlayer(tmp.steam)

if (debug) then dbug("debug playerDisconnected line " .. debugger.getinfo(1).currentline) end

		if customPlayerDisconnected ~= nil then
			-- read the note on overriding bot code in custom/custom_functions.lua
			if customPlayerDisconnected(line, tmp.entityID, tmp.steam, tmp.name) then
				return
			end
		end

		if debug then dbug("Saving disconnected player " .. igplayers[tmp.steam].name) end

if (debug) then dbug("debug playerDisconnected line " .. debugger.getinfo(1).currentline) end

		if players[tmp.steam].watchPlayer then
			irc_chat(server.ircWatch, server.gameDate .. " " .. tmp.steam .. " " .. players[tmp.steam].name .. " disconnected")
		end

		-- attempt to insert the player into bots db players table
		if	botman.botsConnected then
			insertBotsPlayer(tmp.steam)
		end

		saveDisconnectedPlayer(tmp.steam)
		freeASlot(tmp.steam)

		-- set the player offline in bots db
		connBots:execute("UPDATE players set online = 0 where steam = " .. tmp.steam .. " AND botID = " .. server.botID)

		-- log the player disconnection in events table
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','player left','Player disconnected " .. escape(players[tmp.steam].name) .. " " .. tmp.steam .. " Owner " .. players[tmp.steam].tmp.steamOwner .. " " .. players[tmp.steam].id .. "'," .. players[tmp.steam].tmp.steamOwner .. ")") end

		-- check how many claims they have placed
		sendCommand("llp " .. tmp.steam .. " parseable")
	end
end
