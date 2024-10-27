--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function unbanPlayer(line)
	if botman.botDisabled then
		return
	end

	local steam

	steam = string.match(line, "(-?%d+)")
	players[steam].hackerScore = 0
	players[steam].timeout = false
	players[steam].botTimeout = false
	players[steam].freeze = false
	players[steam].silentBob = false
	players[steam].permanentBan = false
	if botman.dbConnected then conn:execute("UPDATE players SET hackerScore=0,timeout=0,botTimeout=0,silentBob=0,permanentBan=0 WHERE steam = '" .. steam .. "'") end

	-- also remove the steam owner from the bans table
	if botman.dbConnected then conn:execute("DELETE FROM bans WHERE steam = '" .. steam .. "' or steam = '" .. players[steam].steamOwner .. "'") end
end
