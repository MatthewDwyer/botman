--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function listKnownPlayers(line)
	local tmp

	if botman.botDisabled or server.useAllocsWebAPI then
		return
	end

	-- botman.readingLKP = true
	-- connSQL:execute("INSERT INTO LKPQueue (line) VALUES ('" .. connMEM:escape(line) .. "')")
	-- botman.lkpQueueEmpty = false

	-- tmp = {}
	-- tmp.data = string.split(line, ",")
	-- tmp.temp = string.sub(tmp.data[3], string.find(tmp.data[3], "steamid=") + 8)
	-- tmp.temp = string.split(tmp.temp, "_")
	-- tmp.steam = tmp.temp[2]

	-- if players[tmp.steam] then
		-- players[tmp.steam].notInLKP = false
	-- end
end
