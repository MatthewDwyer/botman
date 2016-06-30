--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function unbanPlayer(line)
	if botDisabled then
		return
	end

	local temp, steam

	--Executing command 'ban remove 76561197983251951'

	temp = string.split(line, " ")
	steam = string.sub(temp[8], 1, string.len(temp[8]) - 1)

	-- also remove the steam owner from the bans table
	conn:execute("DELETE FROM bans WHERE steam = " .. steam .. " or steam = " .. players[steam].steamOwner)
end
