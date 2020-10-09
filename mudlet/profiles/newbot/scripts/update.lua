--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug, steamID

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false -- should be false unless testing

if botman.debugAll then
	debug = true -- this should be true
end

function runBeforeBotUpdate()
	if isFile(homedir .. "/blockScripts.txt") then
		-- or don't
		return
	end

	-- do a backup of the bot's tables first
	saveLuaTables(os.date("%Y%m%d_%H%M%S"))
end

