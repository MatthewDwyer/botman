--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function listKnownPlayers(line)
	if botDisabled then
		return
	end

	local name, id, steam, playtime, seen, result

	data = string.split(line, ",")

	name = string.sub(data[1], string.find(data[1], ". ") + 2)
	id = string.sub(data[2], string.find(data[2], "id=") + 3)
	steam = string.sub(data[3], string.find(data[3], "steamid=") + 8)
	playtime = string.sub(data[6], string.find(data[6], "playtime=") + 9, string.len(data[6]) - 2)
	seen = string.sub(data[7], string.find(data[7], "seen=") + 5)

	local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+)"
	local runyear, runmonth, runday, runhour, runminute, runseconds = seen:match(pattern)
	local seenTimestamp = os.time({year = runyear, month = runmonth, day = runday, hour = runhour, min = runminute, sec = runseconds})

	if (not players[steam] and (playtime ~= "0")) then
		cecho(server.windowDebug, "add player " .. name .. "\n")
		players[steam] = {}
		players[steam].id = id
		players[steam].name = name
		players[steam].steam = steam
		players[steam].playtime = playtime
		players[steam].seen = seen

		conn:execute("INSERT INTO players (steam, id, name, playtime, seen) VALUES (" .. steam .. "," .. id .. ",'" .. escape(name) .. "'," .. playtime .. ",'" .. seen .. "') ON DUPLICATE KEY UPDATE playtime = " .. playtime .. ", seen = '" .. seen .. "'")
	else
		if (playtime ~= "0") then
			cecho(server.windowDebug, "update player " .. name .. "\n")
			players[steam].id = id
			players[steam].name = name
			players[steam].playtime = playtime
			players[steam].seen = seen

			conn:execute("INSERT INTO players (steam, id, name, playtime, seen) VALUES (" .. steam .. "," .. id .. ",'" .. escape(name) .. "'," .. playtime .. ",'" .. seen .. "') ON DUPLICATE KEY UPDATE playtime = " .. playtime .. ", seen = '" .. seen .. "'")
		end
	end

	-- add missing fields and give them default values
	fixMissingPlayer(steam)
end
