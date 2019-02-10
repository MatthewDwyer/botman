--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function listKnownPlayers(line)
	local tmp

	if botman.botDisabled then
		return
	end

	if server.useAllocsWebAPI then
		return
	end

	botman.readingLKP = true
	conn:execute("INSERT INTO LKPQueue (line) VALUES ('" .. escape(line) .. "')")

	tmp = {}
	tmp.data = string.split(line, ",")
	tmp.name = string.sub(tmp.data[1], string.find(tmp.data[1], ". ") + 2)
	tmp.id = string.sub(tmp.data[2], string.find(tmp.data[2], "id=") + 3)
	tmp.steam = string.sub(tmp.data[3], string.find(tmp.data[3], "steamid=") + 8)

	if players[tmp.steam] then
		players[tmp.steam].notInLKP = false
	end

	-- tmp.playtime = string.sub(tmp.data[6], string.find(tmp.data[6], "playtime=") + 9, string.len(tmp.data[6]) - 2)
	-- tmp.seen = string.sub(tmp.data[7], string.find(tmp.data[7], "seen=") + 5)

	-- if tmp.steam == "" then
		-- return
	-- end

	-- if playersArchived[tmp.steam] then
		-- -- don't process if this player has been archived
		-- return
	-- end

	-- local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+)"
	-- local runyear, runmonth, runday, runhour, runminute = tmp.seen:match(pattern)
	-- local seenTimestamp = os.time({year = runyear, month = runmonth, day = runday, hour = runhour, min = runminute, 0})

	-- if not igplayers[tmp.steam] and players[tmp.steam] then
		-- -- acrchive players that haven't played in 60 days and aren't an admin
		-- if (os.time() - seenTimestamp > 86400 * server.archivePlayersLastSeenDays) and (accessLevel(tmp.steam) > 3) then
			-- conn:execute("INSERT INTO playersArchived SELECT * from players WHERE steam = " .. tmp.steam)
			-- conn:execute("DELETE FROM players WHERE steam = " .. tmp.steam)
			-- players[tmp.steam] = nil
			-- loadPlayersArchived(tmp.steam)
			-- return
		-- end
	-- end

	-- if playersArchived[tmp.steam] then
		-- -- abort if the player has been archived
		-- return
	-- end

	-- if (not players[tmp.steam] and (tmp.playtime ~= "0")) then
		-- players[tmp.steam] = {}

		-- if tmp.id ~= "-1" then
			-- players[tmp.steam].id = tmp.id
		-- end

		-- players[tmp.steam].name = tmp.name
		-- players[tmp.steam].steam = tmp.steam
		-- players[tmp.steam].playtime = tmp.playtime
		-- players[tmp.steam].seen = tmp.seen

		-- if botman.dbConnected then conn:execute("INSERT INTO players (steam, id, name, playtime, seen) VALUES (" .. tmp.steam .. "," .. tmp.id .. ",'" .. escape(tmp.name) .. "'," .. tmp.playtime .. ",'" .. tmp.seen .. "') ON DUPLICATE KEY UPDATE playtime = " .. tmp.playtime .. ", seen = '" .. tmp.seen .. "'") end
	-- else
		-- if tmp.id ~= "-1" then
			-- players[tmp.steam].id = tmp.id
		-- end

		-- players[tmp.steam].name = tmp.name
		-- players[tmp.steam].playtime = tmp.playtime
		-- players[tmp.steam].seen = tmp.seen

		-- if botman.dbConnected then conn:execute("INSERT INTO players (steam, id, name, playtime, seen) VALUES (" .. tmp.steam .. "," .. tmp.id .. ",'" .. escape(tmp.name) .. "'," .. tmp.playtime .. ",'" .. tmp.seen .. "') ON DUPLICATE KEY UPDATE playtime = " .. tmp.playtime .. ", seen = '" .. tmp.seen .. "', name = '" .. escape(tmp.name) .. "', id = " .. tmp.id) end
	-- end

	-- -- add missing fields and give them default values
	-- fixMissingPlayer(tmp.steam)
end
