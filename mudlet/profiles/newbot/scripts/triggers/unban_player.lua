--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function unbanPlayer(line)
	if botman.botDisabled then
		return
	end

	local temp, steam

	--Executing command 'ban remove 76561197983251951'

	temp = string.split(line, " ")
	steam = string.sub(temp[8], 1, string.len(temp[8]) - 1)
	players[steam].hackerScore = 0
	players[steam].timeout = false
	players[steam].botTimeout = false
	players[steam].freeze = false
	players[steam].silentBob = false
	players[steam].permanentBan = false
	if botman.dbConnected then conn:execute("UPDATE players SET hackerScore=0,timeout=0,botTimeout=0,silentBob=0,permanentBan=0 WHERE steam = " .. steam) end

	-- also remove the steam owner from the bans table
	if botman.dbConnected then conn:execute("DELETE FROM bans WHERE steam = " .. steam .. " or steam = " .. players[steam].steamOwner) end
end
