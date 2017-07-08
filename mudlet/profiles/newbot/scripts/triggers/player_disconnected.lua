--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug = false

-- enable debug to see where the code is stopping. Any error will be after the last debug line.

function playerDisconnected(line)
	local steam, playerID, entityID, name, pos, temp

	if (debug) then dbug("D", "", debugger.getinfo(1,"nSl")) end

	botman.playersOnline = tonumber(botman.playersOnline) - 1

	local _, commas = string.gsub(line, ",", "")

	if commas ~= 3 then
		-- don't process if the line is invalid
		return
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if string.find(line, "Player disconnected:") then
		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
		temp = string.split(line, ",")
		entityID = string.sub(temp[1], string.find(temp[1], "EntityID=") + 9)
		steam = string.match(temp[2], "(%d+)")
		name = stripQuotes(string.sub(temp[4], 13, string.len(temp[4])))

		if(not steam) then
			return
		end

		if players[steam] == nil then
			initNewPlayer(steam, name, entityID, steam)
		end

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if igplayers[steam] == nil then
			initNewIGPlayer(steam, name, entityID, steam)
		end

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		fixMissingPlayer(steam)
		fixMissingIGPlayer(steam)

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		-- 2016-09-11T04:14:28
		botman.serverTime = string.sub(line, 1, 19)
		botman.serverHour = string.sub(line, 12, 13)
		botman.serverMinute = string.sub(line, 15, 16)

		newDay()

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		echo(os.date("%c") .. " Saving disconnected player " .. igplayers[steam].name .. "(")
		echoLink(steam,  "openUrl(\"http://steamcommunity.com/profiles/" .. steam .. "\")", "Click to view players Steam profile.")
		echo(")\n\n")

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		irc_chat(server.ircMain, server.gameDate .. " " .. steam .. " " .. players[steam].name .. " disconnected")
		logChat(botman.serverTime, "Server", steam .. " " .. players[steam].name .. " disconnected")

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

		-- check how many claims they have placed
		send("llp " .. steam)
	end
end
