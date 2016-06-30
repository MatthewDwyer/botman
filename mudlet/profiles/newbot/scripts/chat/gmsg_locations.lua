--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_locations()
	calledFunction = "gmsg_locations"
	
	local shortHelp = false
	local skipHelp = false
	local debug, temp
	debug = false

	local loc, locationName, locationName, id, pname, active

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
		return false
	end
	
	if chatvars.showHelp then
		if chatvars.words[3] then		
			if not string.find(chatvars.command, "locat") then
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
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Location Commands:")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "================")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
		
		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

if debug then dbug("debug locations 1") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "clear"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location <name> clear")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Delete all random spawns for the location.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and string.find(chatvars.command, "clear") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end
		
		locationName = ""
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "clear") - 2)
		locationName = string.trim(locationName)			
		loc = LookupLocation(locationName)

		if loc ~= nil then
			conn:execute("DELETE FROM locationSpawns WHERE location = '" .. escape(loc) .. "'")
			
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Location " .. locationName .. "'s teleports have been deleted.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Location " .. locationName .. "'s teleports have been deleted.")
			end			
		else
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end					
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 2") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "remove"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location remove <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Delete the location and all of its spawnpoints.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "remove") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = ""
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "remove ") + 7)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if locationName == string.lower("prison") and server.gameType ~= "pvp" then
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The server needs a prison.  PVPs will be temp-banned instead.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The server needs a prison.  PVPs will be temp-banned instead.")
			end			
		end 

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end			
		else	
			locations[loc] = nil
			conn:execute("DELETE FROM locationSpawns WHERE location = '" .. escape(locationName) .. "'")
			conn:execute("DELETE FROM locations WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed a location called " .. locationName .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You removed a location called " .. locationName)
			end			
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 3") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location <name> pvp (or pve)")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Mark the location as a pvp or pve zone.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve")) then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end
		
		locationName = ""
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, " pv") - 1)
		locationName = string.trim(locationName)	
		loc = LookupLocation(locationName)

		if loc ~= nil then
			if string.find(chatvars.command, "pve") then
				locations[loc].pvp = false
				conn:execute("UPDATE locations set pvp = false WHERE name = '" .. escape(locationName) .. "'")
				message("say [" .. server.chatColour .. "]The location " .. locations[loc].name .. " is now a PVE zone.[-]")

				if (chatvars.playername ~= "Server") then 
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location " .. locations[loc].name .. " is now a PVE zone.")
				end	
			else
				locations[loc].pvp = true
				conn:execute("UPDATE locations set pvp = true WHERE name = '" .. escape(locationName) .. "'")
				message("say [" .. server.chatColour .. "]The location " .. locations[loc].name .. " is now a PVP zone![-]")		

				if (chatvars.playername ~= "Server") then 
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location " .. locations[loc].name .. " is now a PVP zone.")
				end	
			end			
		else
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 4") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "able"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location enable <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Flag the location as enabled. Currently this flag isn't used and you can ignore this command.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "enable") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "enable ") + 7)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		else	
			locations[loc].active = true
			conn:execute("UPDATE locations set active = true WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location called " .. locationName .. " is now enabled.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now enabled.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 5") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "able"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location disable <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Flag the location as disabled. Currently this flag isn't used and you can ignore this command.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "disable") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "disable ") + 8)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		else	
			locations[loc].active = false
			conn:execute("UPDATE locations set active = false WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location called " .. locationName .. " is now disabled.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now disabled.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 6") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "priv"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location private <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Flag the location as private.  Only staff will see it and be able to freely teleport to it.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "private") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "private ") + 8)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		else	
			locations[loc].public = false
			conn:execute("UPDATE locations set public = false WHERE name = '" .. escape(locationName) .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now private[-]")

			if (chatvars.playername ~= "Server") then 
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now private.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 7") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "pub"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location public <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Flag the location as public.  Everyone will see it with /locations. Other restrictions may prevent them going there.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "public") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = ""
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "public ") + 7)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		else	
			locations[loc].public = true
			conn:execute("UPDATE locations set public = true WHERE name = '" .. locationName .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now public[-]")

			if (chatvars.playername ~= "Server") then 
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now public.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 8") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location set reset <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Flag the location as a reset zone.  The bot will warn players not to build in it and will block /setbase and will remove placed claims of non-staff.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "set" and chatvars.words[3] == "reset") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = ""
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "reset ") + 6)
		locationName = string.trim(locationName)

		loc = LookupLocation(locationName)

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		else	
			locations[loc].resetZone = true
			conn:execute("UPDATE locations set resetZone = true WHERE name = '" .. locationName .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now a reset zone[-]")

			if (chatvars.playername ~= "Server") then 
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now a reset zone.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 9") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "clear") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location clear reset <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Remove the reset zone flag.  Unless otherwise restricted, players will be allowed to place claims and setbase.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "clear" and chatvars.words[3] == "reset") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = ""
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "reset ") + 6)
		locationName = string.trim(locationName)

		loc = LookupLocation(locationName)

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		else	
			locations[loc].resetZone = false
			conn:execute("UPDATE locations set resetZone = false WHERE name = '" .. locationName .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is no longer a reset zone[-]")

			if (chatvars.playername ~= "Server") then 
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is no longer a reset zone.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 10") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "lobby") or string.find(chatvars.command, "spawn") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/lobby <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "If the lobby location exists, send the player to it. You can also do this to offline players, they will be moved to the lobby when they rejoin.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end 

	if (chatvars.words[1] == "lobby" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "lobby ") + 6)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id ~= nil) then
			-- if the player is ingame, send them to the lobby otherwise flag it to happen when they rejoin
			if (igplayers[id]) then
				cmd = "tele " .. id .. " " .. locations["spawnpoint1"].x .. " " .. locations["spawnpoint1"].y .. " " .. locations["spawnpoint1"].z
				teleport(cmd)

				if (chatvars.playername ~= "Server") then 
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " has been sent to the lobby.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "Player " .. players[id].name .. " has been sent to the lobby.")
				end	
			else
				players[id].lobby = true
				conn:execute("UPDATE players set location = 'lobby' WHERE steam = " .. id)

				if (chatvars.playername ~= "Server") then 
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " will spawn in the lobby next time they connect to the server.[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, players[id].name .. " will spawn in the lobby next time they connect to the server.")
				end	
			end
		else
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player matched that name.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "No player matched that name.")
			end	
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("debug locations 11") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "own"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location owner <player>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Assign ownership of a location to a player.  They will be able to set protect on it and players not friended to them won't be able to teleport there.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[3] == "owner") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "owner ") + 6)
		pname = string.trim(pname)
		id = LookupPlayer(pname)
		
		if (players[id]) then
			pname = players[id].name
		else
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player matched that name.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "No player matched that name.")
			end	

			faultyChat = false
			return true
		end

		loc = string.trim(chatvars.words[2])
		loc = LookupLocation(loc)

		if (loc ~= nil) then
			locations[loc].owner = id
			conn:execute("UPDATE locations set owner = " .. id .. " WHERE name = '" .. escape(loc) .. "'")
			message("say [" .. server.chatColour .. "]" .. players[id].name .. " is the proud new owner of the location called " .. loc .. "[-]")
		else
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 12") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "allow") or string.find(chatvars.command, "base"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location allow base <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Allow players to /setbase in the location.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "allow" and chatvars.words[3] == "base") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "base ") + 5)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		else	
			locations[loc].allowBase = true
			conn:execute("UPDATE locations SET allowBase = true WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players may setbase in " .. locationName .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players may setbase in " .. locationName .. ".")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 13") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "allow") or string.find(chatvars.command, "base"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location disallow base <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Block /setbase in the location.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "disallow" and chatvars.words[3] == "base") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "base ") + 5)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		else	
			locations[loc].allowBase = true
			conn:execute("UPDATE locations SET allowBase = false WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players may not setbase in " .. locationName .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Players may not setbase in " .. locationName .. ".")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 14") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "acc"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location <name> access <minimum access level>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set the minimum access level required to teleport to the location.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and string.find(chatvars.command, "access") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end
		
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "access") - 2)
		locationName = string.trim(locationName)	
		loc = LookupLocation(locationName)

		if chatvars.number ~= nil and loc ~= nil then
			locations[loc].accessLevel = math.floor(tonumber(chatvars.number))
			conn:execute("UPDATE locations set accessLevel = " .. math.floor(tonumber(chatvars.number)) .. " WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. locationName .. " is restricted to players with access level " .. locations[loc].accessLevel .. " and above.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location " .. locationName .. " is restricted to players with access level " .. locations[loc].accessLevel .. " and above.")
			end	
		end

		if loc == nil then
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 15") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "size"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location <name> size <number>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set the size of the location measured from its centre.  To make a 200 metre location set it to 100.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and string.find(chatvars.command, "size") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end
		
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "size") - 2)
		locationName = string.trim(locationName)			
		loc = LookupLocation(locationName)

		if chatvars.number ~= nil and loc ~= nil then
			locations[locationName].size = math.floor(tonumber(chatvars.number))
			conn:execute("UPDATE locations set size = " .. math.floor(tonumber(chatvars.number)) .. ", protectSize = " .. math.floor(tonumber(chatvars.number)) .. " WHERE name = '" .. locationName .. "'")

			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. locations[loc].name .. " now spans " .. tonumber(chatvars.number * 2) .. " metres.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location " .. locations[loc].name .. " now spans " .. tonumber(chatvars.number * 2) .. " metres.")
			end	

			if loc == string.lower("prison") then
				server.prisonSize = math.floor(tonumber(chatvars.number))
				conn:execute("UPDATE server SET prisonSize = " .. math.floor(tonumber(chatvars.number)))
			end
		end

		if loc == nil then
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 16") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "safe"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location safe <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Flag the location as a safe zone.  The bot will automatically kill zombies in the location if players are in it.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "To prevent this feature spamming the server it is triggered every 30 seconds. When there are more than 10 players it changes to every minute.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "safe") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "safe ") + 5)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		else	
			locations[loc].killZombies = true
			scanZombies = true
			conn:execute("UPDATE locations set killZombies = true WHERE name = '" .. escape(locationName) .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now a safezone.[-]")

			if (chatvars.playername ~= "Server") then 
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now a safezone.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 17") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "safe"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location unsafe <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot will no longer kill zombies in the location.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "unsafe") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "unsafe ") + 7)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		else	
			locations[loc].killZombies = false
			conn:execute("UPDATE locations set killZombies = false WHERE name = '" .. escape(locationName) .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is no longer a safezone![-]")

			if (chatvars.playername ~= "Server") then 
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is no longer a safezone.")
			end	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 18") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "game"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location <name> minigame <game type>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Flag the location as part of a minigame such as capture the flag.  The minigame is an unfinished idea so this command doesn't do much yet.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and string.find(chatvars.command, "minigame") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = chatvars.words[2]
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		else	
			miniGame = string.sub(chatvars.command, string.find(chatvars.command, "minigame") + 9)

			if (miniGame == nil) then 
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You didn't enter a minigame (eg. ctf, contest).[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "You didn't enter a minigame (eg. ctf, contest).")
				end

				faultyChat = false
				return true
			end

			locations[loc].miniGame = miniGame
			conn:execute("UPDATE locations set miniGame = '" .. escape(miniGame) .. "' WHERE name = '" .. loc .. "'")

			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. locationName .. " is the mini-game " .. miniGame .. ".[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location " .. locationName .. " is the mini-game " .. miniGame)
			end			
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 19") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "cost"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location <name> cost <number>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Require the player to have <number> zennies to teleport there.  The zennies are removed from the player afterwards.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and string.find(chatvars.command, "cost") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end
		
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "cost") - 2)
		locationName = string.trim(locationName)	
		loc = LookupLocation(locationName)

		if chatvars.number ~= nil and loc ~= nil then
			locations[loc].cost = math.floor(tonumber(chatvars.number))
-- TODO:  Look for the word currency and grab what follows it as the item to require an amount (cost) of.
			if locations[loc].currency == nil then
				locations[loc].currency = "zennies"
			end

			conn:execute("UPDATE locations set cost = " .. math.floor(tonumber(chatvars.number)) .. ", currency = '" .. escape(locations[loc].currency) .. "' WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. locationName .. " requires " .. locations[loc].cost .. " " .. locations[loc].currency .. " to teleport.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The location " .. locationName .. " requires " .. locations[loc].cost .. " " .. locations[loc].currency .. " to teleport.")
			end	
		end

		if loc == nil then
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end	
		end

		faultyChat = false
		return true
	end

	-- ###################  do not run remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)
	
	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Location In-Game Only:")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "========================")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
	end

if debug then dbug("debug locations 20") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "prot"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/protect location")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Tell the bot to protect the location that you are in. It will instruct you what to do and will tell you when the location is protected.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "protect" and chatvars.words[2] == "location") and (chatvars.playerid ~= 0) then	
		if igplayers[chatvars.playerid].alertLocation ~= "" then
			igplayers[chatvars.playerid].alertLocationExit = igplayers[chatvars.playerid].alertLocation
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Walk out of " .. igplayers[chatvars.playerid].alertLocation .. " and I will do the rest.[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not in a location. Use this command when you have entered the location that you wish to protect.[-]")		
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("debug locations 21") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "prot"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/unprotect location <optional name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Remove bot protection from the location. You can leave out the location name if you are in the location.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "unprotect" and chatvars.words[2] == "location") and (chatvars.playerid ~= 0) then
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9)
		locationName = string.trim(locationName)	
		loc = LookupLocation(locationName)
		
		if loc ~= nil then
			locations[loc].protected = false
			conn:execute("UPDATE locations SET protected = 0 WHERE name = '" .. escape(loc) .. "'")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have disabled protection for " .. loc .. ".[-]")

			faultyChat = false
			return true		
		end
	
		if igplayers[chatvars.playerid].alertLocation ~= "" then
			locations[igplayers[chatvars.playerid].alertLocation].protected = false
			conn:execute("UPDATE locations SET protected = 0 WHERE name = '" .. escape(igplayers[chatvars.playerid].alertLocation) .. "'")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have disabled protection for " .. igplayers[chatvars.playerid].alertLocation .. ".[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not in a location. Use this command when you have entered the location that you wish to remove protection from.[-]")				
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("debug locations 22") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "add"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location add <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Create a location where you are standing.  Unless you add random spawns, any player teleporting to the location will arrive at your current position.  If you are not on the ground, make sure the players can survive the landing.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "add") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "add ") + 4)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc ~= nil) then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location already exists.[-]")
			faultyChat = false
			return true
		else	
			locations[locationName] = {}
			locations[locationName].name = locationName
			locations[locationName].x = chatvars.intX
			locations[locationName].y = chatvars.intY
			locations[locationName].z = chatvars.intZ
			locations[locationName].active = true
			locations[locationName].public = false
			locations[locationName].owner = chatvars.playerid
			locations[locationName].size = 20
			locations[locationName].killZombies = false

			conn:execute("INSERT INTO locations (name, x, y, z) VALUES ('" .. escape(locationName) .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ") ON DUPLICATE KEY UPDATE x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. serverTime .. "','location added','Location " .. escape(locationName) .. " added'," .. chatvars.playerid .. ")")
			message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " has created a location called " .. locationName .. "[-]")

			loadLocations(locationName)
		end

		if (locationName == "prison") then
			message("say [" .. server.chatColour .. "]Server PVP protection is now enabled.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 23") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "move"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location move <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Move an existing location to where you are standing.  Unless you add random spawns, any player teleporting to the location will arrive at your current position.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "If you are not on the ground, make sure the players can survive the landing.  If there are existing random spawns for the location, moving it will not move them.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You should clear them and redo them using /location <name> clear and /location <name> random.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "move") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "move ") + 5)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			faultyChat = false
			return true
		else	
			locations[loc].x = chatvars.intX
			locations[loc].y = chatvars.intY
			locations[loc].z = chatvars.intZ

			conn:execute("INSERT INTO locations (name, x, y, z) VALUES ('" .. escape(locationName) .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ") ON DUPLICATE KEY UPDATE x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. serverTime .. "','location moved','Location " .. escape(locationName) .. " moved'," .. chatvars.playerid .. ")")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have moved a location called " .. locationName .. "[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 24") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/locations")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "List the locations and basic info about them.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "locations" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		for k, v in pairs(locations) do
			if (v.active == true) then
				active = "enabled"
			else
				active = "disabled"
			end
		
			if (not v.public and accessLevel(chatvars.playerid) < 3) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/" .. v.name .. " private " .. active .. "[-]")
			end

			if (v.public) then
				if (accessLevel(chatvars.playerid) < 3) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/" .. v.name .. " public " .. active .. "[-]")
				else
					if v.active then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/" .. v.name .. "[-]")
					end
				end
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 25") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "size"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location <name> ends here")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Set the size of the location as the difference between your position and the centre of the location. Handy for setting it visually.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and string.find(chatvars.command, "ends here")) and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end
		
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "end") - 2)
		locationName = string.trim(locationName)			
		loc = LookupLocation(locationName)

		if loc ~= nil then
			dist = distancexz(locations[loc].x, locations[loc].z, igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos)
			locations[loc].size = string.format("%d", dist)
			conn:execute("UPDATE locations set size = " .. locations[loc].size .. ", protectSize = " .. locations[loc].size .. " WHERE name = '" .. locationName .. "'")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. loc .. " now spans " .. string.format("%d", dist * 2) .. " meters.[-]")

			if loc == "Prison" then
				server.prisonSize = math.floor(tonumber(locations[loc].size))
				conn:execute("UPDATE server SET prisonSize = " .. math.floor(tonumber(locations[loc].size)))
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 26") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "rand"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location <name> random")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Start setting random spawn points for the location.  The bot uses your position which it samples every 3 seconds or so.  It only records a new coordinate when you have moved more than 2 metres from the last recorded spot.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "Unless you intend players to fall, do not fly or clip through objects while recording.  To stop recording just type stop.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "You can record random spawns anywhere and more than once but remember to type stop after each recording or the bot will continue recording your movement and making spawn points from them.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The spawns do not have to be inside the location and you can make groups of spawns anywhere in the world for the location.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and string.find(chatvars.command, "random")) and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end
		
		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "random") - 2)
		locationName = string.trim(locationName)			
		loc = LookupLocation(locationName)

		if loc ~= nil then
			igplayers[chatvars.playerid].location = loc
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are now creating spawn points for location " .. loc .. ". DO NOT FLY.[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 27") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/location <name>")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "See detailed information about a location including a list of players currently in it.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location") and (chatvars.playerid ~= 0) then
		-- display details about the location

		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			faultyChat = false
			return true
		else	
			cursor,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. locationName .."'")
			row = cursor:fetch({}, "a")

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Location: " .. row.name .. "[-]")				
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Active: " .. dbYN(row.active) .. "[-]")				
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset Zone: " .. dbYN(row.resetZone) .. "[-]")				
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Safe Zone: " .. dbYN(row.killZombies) .. "[-]")				
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Public: " .. dbYN(row.public) .. "[-]")				
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Allow Bases: " .. dbYN(row.allowBase) .. "[-]")				

			if row.miniGame ~= nil then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Mini Game: " .. row.miniGame .. "[-]")				
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Village: " .. dbYN(row.village) .. "[-]")				

			temp = LookupPlayer(row.mayor)
			if row.owner ~= "0" then 
				temp = LookupPlayer(row.mayor)
			else
				temp = ""
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Mayor: " .. temp .. "[-]")				
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Protected: " .. dbYN(row.protected) .. "[-]")				
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]PVP: " .. dbYN(row.pvp) .. "[-]")				
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Access Level: " .. row.accessLevel .. "[-]")				

			temp = LookupPlayer(row.owner)
			if row.owner ~= "0" then 
				temp = LookupPlayer(row.owner)
			else
				temp = ""
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Owner: " .. temp .. "[-]")				
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Coords: " .. row.x .. " " .. row.y .. " " .. row.z .. "[-]")				
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Size: " .. row.size * 2 .. "[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Cost: " .. row.cost .. "[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 28") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "show"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/show locations")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "When you enter and leave a location you will see a private message informing you of this.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "show" and chatvars.words[2] == "locations") and (chatvars.playerid ~= 0) then
		players[chatvars.playerid].showLocationMessages = true
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will be alerted when you enter or leave locations.[-]")				

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 29") end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "hide"))) or chatvars.words[1] ~= "help" then
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "/hide locations")
			
			if not shortHelp then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "The bot will say nothing when you enter or leave a location except for pvp and pve zone changes.")
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "hide" and chatvars.words[2] == "locations") and (chatvars.playerid ~= 0) then
		players[chatvars.playerid].showLocationMessages = false
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The only location messages you will see will be PVE and PVP zones.[-]")				

		faultyChat = false
		return true
	end

if debug then dbug("debug locations 30") end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		faultyChat = false
		return false
	end
	-- ####################################################################################

	-- look for command in locations table
	loc = LookupLocation(chatvars.command)

	if (loc ~= nil) then
		if (players[chatvars.playerid].prisoner or not players[chatvars.playerid].canTeleport) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not allowed to use teleports.[-]")
			faultyChat = false
			return true
		end

		if (players[chatvars.playerid].walkies) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not opted in to using teleports. Type /enabletp to opt-in.[-]")
			faultyChat = false
			return true
		end

		cursor,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. escape(loc) .."'")
		row = cursor:fetch({}, "a")

		if (locations[loc].village == true) then
 			if villagers[chatvars.playerid .. loc] then
				if (players[chatvars.playerid].baseCooldown - os.time() > 0) and (accessLevel(chatvars.playerid) > 2 or server.ignoreAdmins == false) then --  and server.ignoreAdmins == false
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have to wait " .. os.date("%M minutes %S seconds",players[chatvars.playerid].baseCooldown - os.time()) .. " before you can use /" .. loc .. " again.[-]")
					faultyChat = false
					return true
				else
					if players[chatvars.playerid].donor then
						players[chatvars.playerid].baseCooldown = (os.time() + math.floor(tonumber(server.baseCooldown) / 2))
					else
						players[chatvars.playerid].baseCooldown = (os.time() + server.baseCooldown)
					end

					players[chatvars.playerid].xPosOld = 0
					players[chatvars.playerid].yPosOld = 0
					players[chatvars.playerid].zPosOld = 0
					igplayers[chatvars.playerid].lastLocation = loc

					if players[chatvars.playerid].watchPlayer then
						irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
					end

					cursor,errorString = conn:execute("select * from locationSpawns where location='" .. loc .. "'")
					if cursor:numrows() > 0 then
						randomPVPTP(chatvars.playerid, loc)
					else
						cmd = "tele " .. chatvars.playerid .. " " .. locations[loc].x .. " " .. locations[loc].y .. " " .. locations[loc].z
						teleport(cmd)
					end

					faultyChat = false
					return true
				end
			end
		end

		if (row.public == "0" and accessLevel(chatvars.playerid) > 2) and row.owner ~= chatvars.playerid then --  and not LookupVillager(chatvars.playerid, loc)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " is private[-]")
			faultyChat = false
			return true
		end

		if (row.active == "0" and accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " is not enabled right now[-]")
			faultyChat = false
			return true
		end

		if (accessLevel(chatvars.playerid) > tonumber(row.accessLevel)) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not authorised to visit " .. row.name .. ".[-]")
			faultyChat = false
			return true
		end

		if tonumber(row.cost) > 0 then
			if row.currency == "zennies" then
				if players[chatvars.playerid].cash < tonumber(row.cost) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough zennies to travel there.[-]")
					faultyChat = false
					return true
				else
					-- collect payment
					players[chatvars.playerid].cash = players[chatvars.playerid].cash - tonumber(row.cost)
				end
			else
				if not inInventory(chatvars.playerid, row.currency, row.cost) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough of the required item to travel there.[-]")
					faultyChat = false
					return true
				end
			end
		end

		if tonumber(chatvars.intY) > -1 then
			if igplayers[chatvars.playerid].lastLocation ~= loc then
				savePosition(chatvars.playerid)
				igplayers[chatvars.playerid].lastLocation = loc
			else
				savePosition(chatvars.playerid, 2)
			end
		end

		cursor,errorString = conn:execute("select * from locationSpawns where location='" .. escape(loc) .. "'")
		if cursor:numrows() > 0 then
			if players[chatvars.playerid].watchPlayer then
				irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
			end

			randomPVPTP(chatvars.playerid, loc)

			if server.announceTeleports then
				if server.coppi and tonumber(chatvars.accessLevel) > 2 then message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " has moved to " .. loc .. "[-]") end
			end
		else
			cmd = "tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z

			if players[chatvars.playerid].watchPlayer then
				irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
			end

			prepareTeleport(chatvars.playerid, cmd)
			teleport(cmd)

			if server.announceTeleports then
				if server.coppi and tonumber(chatvars.accessLevel) > 2 then message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " has moved to " .. loc .. "[-]") end
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug locations end") end

end

