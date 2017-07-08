--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug = false

function listKnownPlayers(line)
	if botman.botDisabled then
		return
	end

	local name, id, steam, playtime, seen, result

	if(debug) then display("DEBUG listKownPlayers: " .. line) end

	data = string.split(line, ",")

	name = string.sub(data[1], string.find(data[1], ". ") + 2)
	id = string.sub(data[2], string.find(data[2], "id=") + 3)
	steam = string.sub(data[3], string.find(data[3], "steamid=") + 8)
	playtime = string.sub(data[6], string.find(data[6], "playtime=") + 9, string.len(data[6]) - 2)
	seen = string.sub(data[7], string.find(data[7], "seen=") + 5)

	local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+)"
	local runyear, runmonth, runday, runhour, runminute, runseconds = seen:match(pattern)
	local seenTimestamp = os.time({year = runyear, month = runmonth, day = runday, hour = runhour, min = runminute, sec = runseconds})

	if(playtime == "0" or id == "-1") then
		return
	end

	if (not players[steam]) then
		players[steam] = {}
	end

	if(debug) then display("DEBUG lkp make/update: " .. id .. ", " .. name .. ", " .. steam .. ", " .. playtime .. ", " .. seen) end

	players[steam].id = id
	players[steam].name = name
	players[steam].steam = steam
	players[steam].playtime = playtime
	players[steam].seen = seen

	if botman.dbConnected then conn:execute("INSERT INTO players (steam, id, name, playtime, seen) VALUES (" .. steam .. "," .. id .. ",'" .. escape(name) .. "'," .. playtime .. ",'" .. seen .. "') ON DUPLICATE KEY UPDATE playtime = " .. playtime .. ", seen = '" .. seen .. "'") end

	-- add missing fields and give them default values
	fixMissingPlayer(steam)

        if(not igplayers[steam]) then return end

        igplayers[steam].id = id
        igplayers[steam].name = name
        igplayers[steam].steam = steam
        igplayers[steam].playtime = playtime
        igplayers[steam].seen = seen


	-- add missing fields and give them default values
	fixMissingIGPlayer(steam)
end
