--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


-- trial code goes here.  These commands are not accessible to players until moved to other sections.

function gmsg_trial_code()
	calledFunction = "gmsg_trial_code"

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then
		if (chatvars.accessLevel > 0) then
			botman.faultyChat = false
			return false
		end
	end
	-- ##################################################################

	if (chatvars.words[1] == "run" and chatvars.words[2] == "code" and chatvars.accessLevel == 0) then
		-- run whatever is in trialCode.lua
		trialCode()
		botman.faultyChat = false
		return false
	end

end
