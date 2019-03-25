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

	if botman.botDisabled or server.useAllocsWebAPI then
		return
	end

	botman.readingLKP = true
	conn:execute("INSERT INTO LKPQueue (line) VALUES ('" .. escape(line) .. "')")

	tmp = {}
	tmp.data = string.split(line, ",")
	tmp.steam = string.sub(tmp.data[3], string.find(tmp.data[3], "steamid=") + 8)

	if players[tmp.steam] then
		players[tmp.steam].notInLKP = false
	end
end
