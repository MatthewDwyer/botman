--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- Coded something awesome?  Consider sharing it :D


function gmsg_custom()
	calledFunction = "gmsg_custom"
	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == nil) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################
	if (chatvars.words[1] == "test" and chatvars.words[2] == "command") then

		botman.faultyChat = false
		return true
	end
end
