--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_resets()
	calledFunction = "gmsg_resets"

	local region, x, z, debug
	local shortHelp = false
	local skipHelp = false

	debug = false

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
		return false
	end
	
	if chatvars.showHelp then
		if chatvars.words[3] then		
			if chatvars.words[3] ~= "resets" then
				skipHelp = true
			end
		end
		if chatvars.words[1] == "help" then
			skipHelp = false
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Reset Commands:")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "===============")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
	end

	-- ###################  do not allow remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

if debug then dbug("debug resets 1") end

	if ((chatvars.words[1] == "add" or chatvars.words[1] == "remove" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" and (chatvars.words[3] == "region" or chatvars.words[3] == "zone")) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		x = math.floor(igplayers[chatvars.playerid].xPos / 512)
		z = math.floor(igplayers[chatvars.playerid].zPos / 512)
		region = "r." .. x .. "." .. z .. ".7rg"

		if (chatvars.words[1] == "add") then
			resetRegions[region] = {}
			conn:execute("INSERT INTO resetZones (region) VALUES ('" .. region .. "')")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Region " .. region .. " is now a reset zone.[-]")
		else
			resetRegions[region] = nil
			conn:execute("DELETE FROM resetZones WHERE region = '" .. region .. "')")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Region " .. region .. " is no longer a reset zone.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug resets 2") end

	if (chatvars.words[1] == "reset" and chatvars.words[2] == "zones") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		cursor,errorString = conn:execute("select * from resetZones")
		if cursor:numrows() == 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No regions have been flagged as reset zones.[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The following regions are reset zones:[-]")

			row = cursor:fetch({}, "a")
			while row do
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.region .. "[-]")
				row = cursor:fetch(row, "a")	
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug resets end") end

end
