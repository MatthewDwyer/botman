--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_waypoints()
	calledFunction = "gmsg_waypoints"

	local debug
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
			if chatvars.words[3] ~= "waypoints" then
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
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Waypoint Commands:")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "==================")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
	end

	-- ###################  do not allow remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

if debug then dbug("debug waypoints 1") end

	if (chatvars.words[1] == "open" and (chatvars.words[2] == "waypoint" or chatvars.words[2] == "wp")) and (chatvars.playerid ~= 0) then
		if(accessLevel(chatvars.playerid) > 10) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			faultyChat = false
			return true		
		end

		-- set the players waypoint coords
		players[chatvars.playerid].shareWaypoint = true
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your friends can now teleport to your waypoint by typing just " .. players[chatvars.playerid].name .. " or part of it.[-]")	

		conn:execute("UPDATE players SET shareWaypoint = 1 WHERE steam = " .. chatvars.playerid)

		faultyChat = false
		return true
	end

if debug then dbug("debug waypoints 2") end

	if (chatvars.words[1] == "close" and (chatvars.words[2] == "waypoint" or chatvars.words[2] == "wp")) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 10) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			faultyChat = false
			return true		
		end

		-- set the players waypoint coords
		players[chatvars.playerid].shareWaypoint = false
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only you can teleport to your waypoint.[-]")	

		conn:execute("UPDATE players SET shareWaypoint = 0 WHERE steam = " .. chatvars.playerid)

		faultyChat = false
		return true
	end

if debug then dbug("debug waypoints 3") end

	if (chatvars.words[1] == "set" and (chatvars.words[2] == "waypoint" or chatvars.words[2] == "wp")) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 10) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			faultyChat = false
			return true		
		end

		-- set the players waypoint coords
		players[chatvars.playerid].waypointX = chatvars.intX
		players[chatvars.playerid].waypointY = chatvars.intY
		players[chatvars.playerid].waypointZ = chatvars.intZ	
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have set a waypoint.  You can tp to it with /waypoint.[-]")	

		conn:execute("UPDATE players SET waypointX = " .. chatvars.intX .. ", waypointY = " .. chatvars.intY .. ", waypointZ = " .. chatvars.intZ .. " WHERE steam = " .. chatvars.playerid)

		faultyChat = false
		return true
	end

if debug then dbug("debug waypoints 4") end

	if ((chatvars.words[1] == "clear" or chatvars.words[1] == "delete" or chatvars.words[1] == "kill") and chatvars.words[2] == "waypoint") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 10) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			faultyChat = false
			return true		
		end

		-- set the players waypoint coords
		players[chatvars.playerid].waypointX = nil
		players[chatvars.playerid].waypointY = nil
		players[chatvars.playerid].waypointZ = nil
		players[chatvars.playerid].shareWaypoint = false
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your waypoint has been cleared.[-]")	

		conn:execute("UPDATE players SET waypointX = 0, waypointY = 0, waypointZ = 0 WHERE steam = " .. chatvars.playerid)

		faultyChat = false
		return true
	end

if debug then dbug("debug waypoints 5") end

	if (chatvars.words[1] == "waypoint" or chatvars.words[1] == "wp" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 10) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have waypoints.[-]")
			faultyChat = false
			return true		
		end

		if tonumber(players[chatvars.playerid].waypointX) == 0 and tonumber(players[chatvars.playerid].waypointY) == 0 and tonumber(players[chatvars.playerid].waypointZ) == 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have a waypoint set.[-]")
			faultyChat = false
			return true		
		end
		
		-- store the current coords
		players[chatvars.playerid].xPosOld = chatvars.intX
		players[chatvars.playerid].yPosOld = chatvars.intY
		players[chatvars.playerid].zPosOld = chatvars.intZ

		-- tp the player to their waypointwaypoint
		cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].waypointX .. " " .. players[chatvars.playerid].waypointY .. " " .. players[chatvars.playerid].waypointZ
		teleport(cmd, true)

		faultyChat = false
		return true
	end

if debug then dbug("debug waypoints 6") end

	if (chatvars.words[1] == "waypoints") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		if (chatvars.words[2] == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name or id is required.[-]")
			faultyChat = false
			return true
		end

		id = nil
		if (chatvars.words[2]) then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "waypoints ") + 10)
			pname = string.trim(pname)
			if (pname ~= nil) then id = LookupPlayer(pname) end
			
			if (id ~= nil) then
				if (players[id].waypointX) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " " .. players[id].waypointX .. " " .. players[id].waypointY .. " " .. players[id].waypointZ .. "[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " Doesn't have a waypoint set.[-]")			
				end		
				
				faultyChat = false
				return true			
			else
				faultyChat = false
				return true			
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug waypoints end") end

end
