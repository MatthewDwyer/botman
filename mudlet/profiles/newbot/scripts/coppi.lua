--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function mutePlayer(steam)
	send("mpc " .. steam .. " true")
	players[steam].mute = true
	irc_QueueMsg(server.ircMain, players[steam].name .. "'s chat has been muted :D")
	message("pm " .. steam .. " [" .. server.chatColour .. "]Your chat has been muted.[-]")
	conn:execute("UPDATE players SET mute = 1 WHERE steam = " .. steam)
end


function unmutePlayer(steam)
	send("mpc " .. steam .. " false")
	players[steam].mute = false
	irc_QueueMsg(server.ircMain, players[steam].name .. "'s chat is no longer muted D:")
	message("pm " .. steam .. " [" .. server.chatColour .. "]Your chat is no longer muted.[-]")
	conn:execute("UPDATE players SET mute = 0 WHERE steam = " .. steam)
end


function gmsg_coppi()
	calledFunction = "gmsg_coppi"

	local debug

	debug = false

if debug then dbug("debug coppi start") end

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then 
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return false
		end
	end
	-- ##################################################################

if debug then dbug("debug coppi 1") end

	if chatvars.words[1] == "mute" and chatvars.words[2] ~= nil then
		pname = string.sub(chatvars.command, string.find(chatvars.command, "mute ") + 6)
		pname = string.trim(pname)
		pid = LookupPlayer(pname)

		if pid == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
			else
				irc_QueueMsg(server.ircMain, "No player found called " .. pname)
			end

			faultyChat = false
			return true
		end

		mutePlayer(pid)

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Chat from player " .. players[pid].name .. " is blocked :D[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug coppi 2") end

	if chatvars.words[1] == "unmute" and chatvars.words[2] ~= nil then
		pname = string.sub(chatvars.command, string.find(chatvars.command, "mute ") + 6)
		pname = string.trim(pname)
		pid = LookupPlayer(pname)

		if pid == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
			else
				irc_QueueMsg(server.ircMain, "No player found called " .. pname)
			end

			faultyChat = false
			return true
		end

		unmutePlayer(pid)

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[pid].name .. " can chat again D:[-]")
		end


		faultyChat = false
		return true
	end

if debug then dbug("debug coppi 3") end

	if chatvars.words[1] == "spawn" and (chatvars.words[2] == "horde") then
		if chatvars.words[3] ~= nil then
			pid = LookupPlayer(chatvars.words[3])
			if pid ~= nil then
				if igplayers[pid] then
					send("sh " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos))
					irc_QueueMsg(server.ircMain, "Horde spawned by bot at " .. igplayers[pid].name .. "'s position at " .. math.floor(igplayers[pid].xPos) .. " " .. math.floor(igplayers[pid].yPos) .. " " .. math.floor(igplayers[pid].zPos))
				end
			else
				loc = LookupLocation(chatvars.words[3])
				if loc ~= nil then
					send("sh " .. locations[loc].x .. " " .. locations[loc].y .. " " .. locations[loc].z)	
					irc_QueueMsg(server.ircMain, "Horde spawned by bot at " .. locations[loc].x .. " " .. locations[loc].y .. " " .. locations[loc].z)
				end
			end
		else
			if (chatvars.playername ~= "Server") then
				if igplayers[chatvars.playerid].horde ~= nil then
					send("sh " .. igplayers[chatvars.playerid].horde)
				else
					send("sh " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ)
				end
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug coppi 4") end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == nil) then
		faultyChat = false
		return false
	end
	-- ####################################################################################

if debug then dbug("debug coppi 8") end

	if chatvars.words[1] == "set" and (chatvars.words[2] == "horde") then
		-- mark the player's current position for spawning a horde with /spawn horde
		igplayers[chatvars.playerid].horde = chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ

		faultyChat = false
		return true
	end

if debug then dbug("debug coppi 9") end

	if chatvars.words[1] == "clear" and (chatvars.words[2] == "horde") then
		-- forget the pre-recorded coords of the horde spawn point
		igplayers[chatvars.playerid].horde = nil

		faultyChat = false
		return true
	end

if debug then dbug("debug coppi end") end

end
