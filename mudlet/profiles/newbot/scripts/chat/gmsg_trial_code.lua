--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


-- trial code goes here.  These commands are not accessible to players until moved to other sections.

function gmsg_trial_code()
	calledFunction = "gmsg_trial_code"

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
		return false
	end


	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		faultyChat = false
		return false
	end
	-- ####################################################################################

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then 
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return false
		end
	end
	-- ##################################################################

	if (chatvars.words[1] == "test" and chatvars.words[2] == "test" and accessLevel(chatvars.playerid) == 0) then
		-- add a command to test here.  restricted to server owners.

		if locations["lobby"] then
			cursor,errorString = conn:execute("select * from locationSpawns where location='lobby'")
			if cursor:numrows() > 0 then
				randomPVPTP(chatvars.playerid, "lobby")
			else
				cmd = "tele " .. chatvars.playerid .. " " .. locations["lobby"].x .. " " .. locations["lobby"].y .. " " .. locations["lobby"].z
				prepareTeleport(chatvars.playerid, cmd)
				teleport(cmd, true)
			end
		end
	end


	if (chatvars.words[1] == "most" and chatvars.words[2] == "wanted") or chatvars.words[1] == "bounty" then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The top 10 payers with a bounty on their heads are:[-]")

		for k, v in pairs(top10) do
			--message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. v.name .. " $" .. v.bounty .. "[-]")
		end

		faultyChat = false
		return true
	end

end
