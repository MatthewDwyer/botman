--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
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

	local loc, locationName, locationName, id, pname, status, temp, pvp

	tmp = {}

	if botman.registerHelp then
		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'locations'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('locations', 'A location is usually a teleport destination. They can be configured for many purposes.')")
		else
			row = cursor:fetch(row, "a")
			tmp.topicID = row.topicID
		end

		cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpCommands'")
		row = cursor:fetch(row, "a")
		tmp.commandID = row.Auto_increment
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
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
		irc_chat(players[chatvars.ircid].ircAlias, "")
		irc_chat(players[chatvars.ircid].ircAlias, "Location Commands:")
		irc_chat(players[chatvars.ircid].ircAlias, "================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if chatvars.showHelpSections then
		irc_chat(players[chatvars.ircid].ircAlias, "locations")
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if botman.registerHelp then
		tmp.command = "<#>location clear reset <name>"
		tmp.keywords = "locat, clear, set"
		tmp.accessLevel = 2
		tmp.description = "Remove the reset zone flag.  Unless otherwise restricted, players will be allowed to place claims and setbase."
		tmp.notes = "some notes"
		tmp.ingameOnly = 0
		registerHelp()
	end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "clear") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location clear reset <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Remove the reset zone flag.  Unless otherwise restricted, players will be allowed to place claims and setbase.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "clear" and chatvars.words[3] == "reset") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			locations[loc].resetZone = false
			conn:execute("UPDATE locations set resetZone = false WHERE name = '" .. locationName .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is no longer a reset zone[-]")

			if (chatvars.playername ~= "Server") then
				irc_chat(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is no longer a reset zone.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "clear"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> clear")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Delete all random spawns for the location.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and string.find(chatvars.command, "clear") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "Location " .. locationName .. "'s teleports have been deleted.")
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "remove"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location remove <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Delete the location and all of its spawnpoints.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "remove") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "The server needs a prison.  PVPs will be temp-banned instead.")
			end
		end

		if (loc == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			locations[loc] = nil
			conn:execute("DELETE FROM locationSpawns WHERE location = '" .. escape(locationName) .. "'")
			conn:execute("DELETE FROM locations WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed a location called " .. locationName .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "You removed a location called " .. locationName)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> pvp (or pve)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Mark the location as a pvp or pve zone.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "pve")) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
					irc_chat(players[chatvars.ircid].ircAlias, "The location " .. locations[loc].name .. " is now a PVE zone.")
				end
			else
				locations[loc].pvp = true
				conn:execute("UPDATE locations set pvp = true WHERE name = '" .. escape(locationName) .. "'")
				message("say [" .. server.chatColour .. "]The location " .. locations[loc].name .. " is now a PVP zone![-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(players[chatvars.ircid].ircAlias, "The location " .. locations[loc].name .. " is now a PVP zone.")
				end
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "able"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location enable <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Flag the location as enabled. Currently this flag isn't used and you can ignore this command.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "enable") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			locations[loc].active = true
			conn:execute("UPDATE locations set active = true WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location called " .. locationName .. " is now enabled.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now enabled.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "able"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location disable <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Flag the location as disabled. Currently this flag isn't used and you can ignore this command.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "disable") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			locations[loc].active = false
			conn:execute("UPDATE locations set active = false WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location called " .. locationName .. " is now disabled.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now disabled.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "priv"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location private <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Flag the location as private.  Only staff will see it and be able to freely teleport to it.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "private") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			locations[loc].public = false
			conn:execute("UPDATE locations set public = false WHERE name = '" .. escape(locationName) .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now private[-]")

			if (chatvars.playername ~= "Server") then
				irc_chat(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now private.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "pub"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location public <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Flag the location as public.  Everyone will see it with " .. server.commandPrefix .. "locations. Other restrictions may prevent them going there.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "public") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			locations[loc].public = true
			conn:execute("UPDATE locations set public = true WHERE name = '" .. locationName .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now public[-]")

			if (chatvars.playername ~= "Server") then
				irc_chat(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now public.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location set reset <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Flag the location as a reset zone.  The bot will warn players not to build in it and will block " .. server.commandPrefix .. "setbase and will remove placed claims of non-staff.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "set" and chatvars.words[3] == "reset") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			locations[loc].resetZone = true
			conn:execute("UPDATE locations set resetZone = true WHERE name = '" .. locationName .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now a reset zone[-]")

			if (chatvars.playername ~= "Server") then
				irc_chat(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now a reset zone.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "lobby") or string.find(chatvars.command, "spawn") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "lobby <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "If the lobby location exists, send the player to it. You can also do this to offline players, they will be moved to the lobby when they rejoin.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "lobby" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
					irc_chat(players[chatvars.ircid].ircAlias, "Player " .. players[id].name .. " has been sent to the lobby.")
				end
			else
				players[id].lobby = true
				conn:execute("UPDATE players set location = 'lobby' WHERE steam = " .. id)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " will spawn in the lobby next time they connect to the server.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " will spawn in the lobby next time they connect to the server.")
				end
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player matched that name.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "No player matched that name.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "own"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location owner <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Assign ownership of a location to a player.  They will be able to set protect on it and players not friended to them won't be able to teleport there.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[3] == "owner") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "No player matched that name.")
			end

			botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "allow") or string.find(chatvars.command, "base"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location allow base <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Allow players to " .. server.commandPrefix .. "setbase in the location.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "allow" and chatvars.words[3] == "base") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			locations[loc].allowBase = true
			conn:execute("UPDATE locations SET allowBase = true WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players may setbase in " .. locationName .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Players may setbase in " .. locationName .. ".")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "allow") or string.find(chatvars.command, "base"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location disallow base <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Block " .. server.commandPrefix .. "setbase in the location.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "disallow" and chatvars.words[3] == "base") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			locations[loc].allowBase = true
			conn:execute("UPDATE locations SET allowBase = false WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players may not setbase in " .. locationName .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Players may not setbase in " .. locationName .. ".")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "acc"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> access <minimum access level>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set the minimum access level required to teleport to the location.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and string.find(chatvars.command, "access") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "The location " .. locationName .. " is restricted to players with access level " .. locations[loc].accessLevel .. " and above.")
			end
		end

		if loc == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "size"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> size <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set the size of the location measured from its centre.  To make a 200 metre location set it to 100.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and string.find(chatvars.command, "size") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "The location " .. locations[loc].name .. " now spans " .. tonumber(chatvars.number * 2) .. " metres.")
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "safe"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location safe <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Flag the location as a safe zone.  The bot will automatically kill zombies in the location if players are in it.")
				irc_chat(players[chatvars.ircid].ircAlias, "To prevent this feature spamming the server it is triggered every 30 seconds. When there are more than 10 players it changes to every minute.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "safe") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			locations[loc].killZombies = true
			server.scanZombies = true
			conn:execute("UPDATE locations set killZombies = true WHERE name = '" .. escape(locationName) .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is now a safezone.[-]")

			if (chatvars.playername ~= "Server") then
				irc_chat(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is now a safezone.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "safe"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location unsafe <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot will no longer kill zombies in the location.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "unsafe") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			locations[loc].killZombies = false
			conn:execute("UPDATE locations set killZombies = false WHERE name = '" .. escape(locationName) .. "'")

			message("say [" .. server.chatColour .. "]The location called " .. locationName .. " is no longer a safezone![-]")

			if (chatvars.playername ~= "Server") then
				irc_chat(players[chatvars.ircid].ircAlias, "The location called " .. locationName .. " is no longer a safezone.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "game"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> minigame <game type>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Flag the location as part of a minigame such as capture the flag.  The minigame is an unfinished idea so this command doesn't do much yet.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and string.find(chatvars.command, "minigame") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		locationName = chatvars.words[2]
		loc = LookupLocation(locationName)

		if (loc == nil) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		else
			miniGame = string.sub(chatvars.command, string.find(chatvars.command, "minigame") + 9)

			if (miniGame == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You didn't enter a minigame (eg. ctf, contest).[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "You didn't enter a minigame (eg. ctf, contest).")
				end

				botman.faultyChat = false
				return true
			end

			locations[loc].miniGame = miniGame
			conn:execute("UPDATE locations set miniGame = '" .. escape(miniGame) .. "' WHERE name = '" .. loc .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. locationName .. " is the mini-game " .. miniGame .. ".[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The location " .. locationName .. " is the mini-game " .. miniGame)
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "cost"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> cost <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Require the player to have <number> " .. server.moneyPlural .. " to teleport there.  The " .. server.moneyPlural .. " are removed from the player afterwards.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and string.find(chatvars.command, "cost") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
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
				locations[loc].currency = server.moneyPlural
			end

			conn:execute("UPDATE locations set cost = " .. math.floor(tonumber(chatvars.number)) .. ", currency = '" .. escape(locations[loc].currency) .. "' WHERE name = '" .. escape(locationName) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. locationName .. " requires " .. locations[loc].cost .. " " .. locations[loc].currency .. " to teleport.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The location " .. locationName .. " requires " .. locations[loc].cost .. " " .. locations[loc].currency .. " to teleport.")
			end
		end

		if loc == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "close"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> day closed <0-7>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Block and remove players from the location on a set day. 7 = day 7")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and string.find(chatvars.command, "day closed")) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "day close") - 2)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if loc == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end

			botman.faultyChat = false
			return true
		end

		if chatvars.number == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Missing day, a number from 0 to 7.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Missing day, a number from 0 to 7.")
			end

			botman.faultyChat = false
			return true
		end

		if tonumber(chatvars.number) < 0 or tonumber(chatvars.number) > 7 then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Closed day outside of range 0 to 7.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Closed day outside of range 0 to 7.")
			end

			botman.faultyChat = false
			return true
		end

		locations[loc].dayClosed = chatvars.number
		conn:execute("UPDATE locations SET dayClosed = " .. chatvars.number .. " WHERE name = '" .. escape(loc) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. loc .. " will be closed on day " .. locations[loc].dayClosed .. "[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, loc .. " will be closed on day " .. locations[loc].dayClosed)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "open"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> open <0-23>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Allow players inside the location from a set hour.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and string.find(chatvars.command, " open")) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "open") - 2)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if loc == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end

			botman.faultyChat = false
			return true
		end

		if chatvars.number == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Missing open hour, a number from 0 to 23.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Missing open hour, a number from 0 to 23.")
			end

			botman.faultyChat = false
			return true
		end

		if tonumber(chatvars.number) < 0 or tonumber(chatvars.number) > 23 then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Open hour outside of range 0 to 23.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Open hour outside of range 0 to 23.")
			end

			botman.faultyChat = false
			return true
		end

		locations[loc].timeOpen = chatvars.number
		conn:execute("UPDATE locations SET timeOpen = " .. chatvars.number .. " WHERE name = '" .. escape(loc) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. loc .. " will open at " .. locations[loc].timeOpen .. ":00[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, loc .. " will open at " .. locations[loc].timeOpen .. ":00")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "close"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> close <0-23>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Block and remove players from the location from a set hour.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and string.find(chatvars.command, " close") and chatvars.words[2] ~= "add") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "close") - 2)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if loc == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end

			botman.faultyChat = false
			return true
		end

		if chatvars.number == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Missing close hour, a number from 0 to 23.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Missing close hour, a number from 0 to 23.")
			end

			botman.faultyChat = false
			return true
		end

		if tonumber(chatvars.number) < 0 or tonumber(chatvars.number) > 23 then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Close hour outside of range 0 to 23.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Close hour outside of range 0 to 23.")
			end

			botman.faultyChat = false
			return true
		end

		locations[loc].timeClosed = chatvars.number
		conn:execute("UPDATE locations SET timeClosed = " .. chatvars.number .. " WHERE name = '" .. escape(loc) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. loc .. " will be closed at " .. locations[loc].timeClosed .. ":00[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, loc .. " will be closed at " .. locations[loc].timeClosed .. ":00")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "lev"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> min level <minimum player level>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> max level <maximum player level>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> min level <minimum player level> max level <maximum player level>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set a player level requirement to teleport to a location.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "location" and (string.find(chatvars.command, "min level") or string.find(chatvars.command, "max level")) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if (not string.find(chatvars.command, "min level") and string.find(chatvars.command, "max level")) then
			tmp.locationName = string.trim(string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "max level") - 2))
		end

		if (string.find(chatvars.command, "min level")) then
			tmp.locationName = string.trim(string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9, string.find(chatvars.command, "min level") - 2))
		end

		tmp.loc = LookupLocation(tmp.locationName)

		if tmp.loc ~= nil then
			tmp.minLevel = locations[tmp.loc].minimumLevel
			tmp.maxLevel = locations[tmp.loc].maximumLevel

			if (string.find(chatvars.command, "min level") and not string.find(chatvars.command, "max level")) then
				tmp.minLevel = string.sub(chatvars.command, string.find(chatvars.command, "min level") + 10)
			end

			if (not string.find(chatvars.command, "min level") and string.find(chatvars.command, "max level")) then
				tmp.maxLevel = string.sub(chatvars.command, string.find(chatvars.command, "max level") + 10)
			end

			if (string.find(chatvars.command, "min level") and string.find(chatvars.command, "max level")) then
				tmp.minLevel = string.sub(chatvars.command, string.find(chatvars.command, "min level") + 10, string.find(chatvars.command, "max level") - 2)
				tmp.maxLevel = string.sub(chatvars.command, string.find(chatvars.command, "max level") + 10)
			end

			tmp.minLevel = tonumber(tmp.minLevel)
			tmp.maxLevel = tonumber(tmp.maxLevel)

			-- flip if max < min and max not zero
			if tmp.minLevel > tmp.maxLevel and tmp.maxLevel > 0 then
				temp = tmp.maxLevel
				tmp.maxLevel = tmp.minLevel
				tmp.minLevel = temp
			end

			-- update the levels for the location
			conn:execute("UPDATE locations set minimumLevel = " .. tmp.minLevel .. ", maximumLevel = " .. tmp.maxLevel .. " WHERE name = '" .. escape(tmp.locationName) .. "'")
			locations[tmp.loc].minimumLevel = tmp.minLevel
			locations[tmp.loc].maximumLevel = tmp.maxLevel

			if tmp.minLevel == 0 and tmp.maxLevel == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. tmp.locationName .. " is not restricted by player level.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "The location " .. tmp.locationName .. " is not restricted by player level.")
				end

				botman.faultyChat = false
				return true
			end

			if tmp.minLevel > 0 then
				if tmp.maxLevel > 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. tmp.locationName .. " is restricted to players with player levels from " .. tmp.minLevel .. " to " .. tmp.maxLevel .. ".[-]")
					else
						irc_chat(players[chatvars.ircid].ircAlias, "The location " .. tmp.locationName .. " is restricted to players with player levels from " .. tmp.minLevel .. " to " .. tmp.maxLevel .. ".")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. tmp.locationName .. " is restricted to players with minimum player level of " .. tmp.minLevel .. " and above.[-]")
					else
						irc_chat(players[chatvars.ircid].ircAlias, "The location " .. tmp.locationName .. " is restricted to players with minimum player level of " .. tmp.minLevel .. " and above.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if tmp.maxLevel > 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The location " .. tmp.locationName .. " is restricted to players with a player level below " .. tmp.maxLevel + 1 .. ".[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "The location " .. tmp.locationName .. " is restricted to players with a player level below " .. tmp.maxLevel + 1 .. ".")
				end
			end
		end

		if tmp.loc == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "That location does not exist.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not run remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(players[chatvars.ircid].ircAlias, "")
		irc_chat(players[chatvars.ircid].ircAlias, "Location In-Game Only:")
		irc_chat(players[chatvars.ircid].ircAlias, "========================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "prot"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "protect location")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Tell the bot to protect the location that you are in. It will instruct you what to do and will tell you when the location is protected.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
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

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "prot"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "unprotect location <optional name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Remove bot protection from the location. You can leave out the location name if you are in the location.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
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

			botman.faultyChat = false
			return true
		end

		if igplayers[chatvars.playerid].alertLocation ~= "" then
			locations[igplayers[chatvars.playerid].alertLocation].protected = false
			conn:execute("UPDATE locations SET protected = 0 WHERE name = '" .. escape(igplayers[chatvars.playerid].alertLocation) .. "'")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have disabled protection for " .. igplayers[chatvars.playerid].alertLocation .. ".[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not in a location. Use this command when you have entered the location that you wish to remove protection from.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "add"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location add <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Create a location where you are standing.  Unless you add random spawns, any player teleporting to the location will arrive at your current position.  If you are not on the ground, make sure the players can survive the landing.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "add") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "add ") + 4)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc ~= nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location already exists.[-]")
			botman.faultyChat = false
			return true
		else
			pvp = pvpZone(chatvars.intX, chatvars.intZ)

			locations[locationName] = {}
			locations[locationName].name = locationName

			conn:execute("INSERT INTO locations (name, x, y, z, owner) VALUES ('" .. escape(locationName) .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. "," .. chatvars.playerid .. ") ON DUPLICATE KEY UPDATE x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. ", owner = " .. chatvars.playerid)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','location added','Location " .. escape(locationName) .. " added'," .. chatvars.playerid .. ")")
			message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " has created a location called " .. locationName .. "[-]")

			loadLocations(locationName)
			locations[locationName].pvp = pvp
		end

		if (locationName == "prison") and server.gameType ~= "pvp" then
			message("say [" .. server.chatColour .. "]Server PVP protection is now enabled.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "move"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location move <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Move an existing location to where you are standing.  Unless you add random spawns, any player teleporting to the location will arrive at your current position.")
				irc_chat(players[chatvars.ircid].ircAlias, "If you are not on the ground, make sure the players can survive the landing.  If there are existing random spawns for the location, moving it will not move them.")
				irc_chat(players[chatvars.ircid].ircAlias, "You should clear them and redo them using " .. server.commandPrefix .. "location <name> clear and " .. server.commandPrefix .. "location <name> random.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and chatvars.words[2] == "move") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "move ") + 5)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			botman.faultyChat = false
			return true
		else
			locations[loc].x = chatvars.intX
			locations[loc].y = chatvars.intY
			locations[loc].z = chatvars.intZ

			conn:execute("INSERT INTO locations (name, x, y, z) VALUES ('" .. escape(locationName) .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ") ON DUPLICATE KEY UPDATE x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','location moved','Location " .. escape(locationName) .. " moved'," .. chatvars.playerid .. ")")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have moved a location called " .. locationName .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "locations")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "List the locations and basic info about them.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "locations" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		for k, v in pairs(locations) do
			status = ""

			if not isLocationOpen(k) then
				status = "[CLOSED]"
				v.open = false
			else
				if v.timeOpen ~= v.timeClosed then
					if v.timeClosed == 0 then
						status = status .. "closes midnight"
					else
						status = status .. "closes " .. string.format("%02d", v.timeClosed) .. ":00"
					end

					if v.timeOpen == 0 then
						status = status .. " re-opens midnight"
					else
						status = status .. " re-opens " .. string.format("%02d", v.timeOpen) .. ":00"
					end
				end

				if tonumber(v.dayClosed) > 0 then
					status = status .. " closed on day " .. v.dayClosed
				end

				v.open = true
			end

			if tonumber(v.cost) > 0 and v.currency ~= nil then
				status = status .. " costs: " .. v.cost .. " " .. v.currency
			end

			if not v.public then
				status = status .. " [private]"
			end

			if tonumber(chatvars.accessLevel) < 3 then
				if not v.active then
					status = status .. " [disabled]"
				end

				if status ~= "" then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. " - " .. status .. "[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. "[-]")
				end
			else
				if v.active and tonumber(chatvars.accessLevel) <= v.accessLevel then
					if status ~= "" then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. " - " .. status .. "[-]")
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. v.name .. "[-]")
					end
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "size"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> ends here")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Set the size of the location as the difference between your position and the centre of the location. Handy for setting it visually.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and string.find(chatvars.command, "ends here")) and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
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

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "rand"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name> random")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Start setting random spawn points for the location.  The bot uses your position which it samples every 3 seconds or so.  It only records a new coordinate when you have moved more than 2 metres from the last recorded spot.")
				irc_chat(players[chatvars.ircid].ircAlias, "Unless you intend players to fall, do not fly or clip through objects while recording.  To stop recording just type stop.")
				irc_chat(players[chatvars.ircid].ircAlias, "You can record random spawns anywhere and more than once but remember to type stop after each recording or the bot will continue recording your movement and making spawn points from them.")
				irc_chat(players[chatvars.ircid].ircAlias, "The spawns do not have to be inside the location and you can make groups of spawns anywhere in the world for the location.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location" and string.find(chatvars.command, "random")) and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
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

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set tp <optional location>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Create a single random teleport for the location you are in or if you are recording random teleports, it will set for that location.")
				irc_chat(players[chatvars.ircid].ircAlias, "If you provide a location name you will create 1 random TP for that location where you are standing.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "set" and chatvars.words[2] == "tp") and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[3] ~= nil then
			locationName = string.sub(chatvars.command, string.find(chatvars.command, " tp ") + 4, string.len(chatvars.command))
			locationName = string.trim(locationName)
			loc = LookupLocation(locationName)

			if locations[chatvars.words[3]] then
				conn:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. chatvars.words[3] .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Random TP added to " .. chatvars.words[3] .. "[-]")

				botman.faultyChat = false
				return true
			end
		end

		if igplayers[chatvars.playerid].location ~= nil then
			conn:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. igplayers[chatvars.playerid].location .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Random TP added to " .. igplayers[chatvars.playerid].location .. "[-]")
		else
			if players[chatvars.playerid].inLocation ~= "" then
				conn:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. players[chatvars.playerid].inLocation .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Random TP added to " .. players[chatvars.playerid].inLocation .. "[-]")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "location <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "See detailed information about a location including a list of players currently in it.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "location") and (chatvars.playerid ~= 0) then
		-- display details about the location

		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		end

		locationName = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9)
		locationName = string.trim(locationName)
		loc = LookupLocation(locationName)

		if (loc == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That location does not exist.[-]")
			botman.faultyChat = false
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

			temp = ""
			if tonumber(row.mayor) > 0 then
				temp = LookupPlayer(row.mayor)
				temp = players[temp].name
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Mayor: " .. temp .. "[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Protected: " .. dbYN(row.protected) .. "[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]PVP: " .. dbYN(row.pvp) .. "[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Access Level: " .. row.accessLevel .. "[-]")

			if row.minimumLevel == row.maximumLevel then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Not player level restricted.[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Minimum player level: " .. row.minimumLevel .. ".[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Maximum player level: " .. row.maximumLevel .. ".[-]")
			end

			temp = ""
			if tonumber(row.owner) > 0 then
				temp = LookupPlayer(row.owner)
				temp = players[temp].name
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Owner: " .. temp .. "[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Coords: " .. row.x .. " " .. row.y .. " " .. row.z .. "[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Size: " .. row.size * 2 .. "[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Cost: " .. row.cost .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "show"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "show locations")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "When you enter and leave a location you will see a private message informing you of this.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "show" and chatvars.words[2] == "locations") and (chatvars.playerid ~= 0) then
		players[chatvars.playerid].showLocationMessages = true
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will be alerted when you enter or leave locations.[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "locat") or string.find(chatvars.command, "hide"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "hide locations")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot will say nothing when you enter or leave a location except for pvp and pve zone changes.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "hide" and chatvars.words[2] == "locations") and (chatvars.playerid ~= 0) then
		players[chatvars.playerid].showLocationMessages = false
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The only location messages you will see will be PVE and PVP zones.[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug locations line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	-- look for command in locations table
	loc = LookupLocation(chatvars.command)

	if (loc ~= nil) then
		if (players[chatvars.playerid].prisoner or not players[chatvars.playerid].canTeleport or not server.allowTeleporting) and tonumber(chatvars.accessLevel) > 2 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not allowed to use teleports.[-]")
			botman.faultyChat = false
			return true
		end

		if (players[chatvars.playerid].walkies) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not opted in to using teleports. Type " .. server.commandPrefix .. "enabletp to opt-in.[-]")
			botman.faultyChat = false
			return true
		end

		-- reject if not an admin and pvpTeleportCooldown is > zero
		if tonumber(chatvars.accessLevel) > 2 and (players[chatvars.playerid].pvpTeleportCooldown - os.time() > 0) then
			message(string.format("pm %s [%s]You must wait %s before you are allowed to teleport again.", chatvars.playerid, server.chatColour, os.date("%M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())))
			botman.faultyChat = false
			result = true
			return
		end

		cursor,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. escape(loc) .."'")
		row = cursor:fetch({}, "a")

		if (locations[loc].village == true) then
 			if villagers[chatvars.playerid .. loc] then
				if (players[chatvars.playerid].baseCooldown - os.time() > 0) and (chatvars.accessLevel > 2 or botman.ignoreAdmins == false) then --  and botman.ignoreAdmins == false
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have to wait " .. os.date("%M minutes %S seconds",players[chatvars.playerid].baseCooldown - os.time()) .. " before you can use " .. server.commandPrefix .. loc .. " again.[-]")
					botman.faultyChat = false
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

					cursor,errorString = conn:execute("select * from locationSpawns where location='" .. loc .. "'")
					if cursor:numrows() > 0 then
						randomTP(chatvars.playerid, loc)
					else
						cmd = "tele " .. chatvars.playerid .. " " .. locations[loc].x .. " " .. locations[loc].y .. " " .. locations[loc].z
						teleport(cmd)
					end

					botman.faultyChat = false
					return true
				end
			end
		end

		if (row.public == "0" and chatvars.accessLevel > 2) and row.owner ~= chatvars.playerid then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " is private[-]")
			botman.faultyChat = false
			return true
		end

		if (row.active == "0" and chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " is not enabled right now[-]")
			botman.faultyChat = false
			return true
		end

		if not locations[loc].open then
			locations[loc].open = isLocationOpen(loc)

			if locations[loc].open then
				message("say [" .. server.chatColour .. "]The location " .. loc .. " is now open.[-]")
			end
		end

		if not locations[loc].open and chatvars.accessLevel > 2 then
			if locations[loc].timeOpen == 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " is closed. It will re-open at midnight.[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. " is closed. It will re-open at " .. locations[loc].timeOpen .. ":00[-]")
			end

			botman.faultyChat = false
			return true
		end

		if (chatvars.accessLevel > tonumber(row.accessLevel) or (locations[loc].newPlayersOnly and not players[chatvars.playerid].newPlayer and chatvars.accessLevel > 2)) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not authorised to visit " .. row.name .. ".[-]")
			botman.faultyChat = false
			return true
		end

		-- check player level restrictions on the location
		if (tonumber(row.minimumLevel) > 0 or tonumber(row.maximumLevel) > 0) and chatvars.accessLevel > 2 then
			if tonumber(row.minimumLevel) > 0 and tonumber(players[chatvars.playerid].level) < tonumber(row.minimumLevel) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting to " .. row.name .. " is level restricted. You need to reach level " .. row.minimumLevel .. ".[-]")
				botman.faultyChat = false
				return true
			end

			if tonumber(row.minimumLevel) > 0 and tonumber(row.maximumLevel) > 0 and (tonumber(players[chatvars.playerid].level) < tonumber(row.minimumLevel) or tonumber(players[chatvars.playerid].level) > tonumber(row.maximumLevel)) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting to " .. row.name .. " is level restricted. You can go there when your level is " .. row.minimumLevel .. " to " .. row.maximumLevel .. ".[-]")
				botman.faultyChat = false
				return true
			end

			if tonumber(row.maximumLevel) > 0 and tonumber(players[chatvars.playerid].level) > tonumber(row.maximumLevel) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting to " .. row.name .. " is level restricted and your level is too high.[-]")
				botman.faultyChat = false
				return true
			end
		end

		if tonumber(row.cost) > 0 then
			if string.lower(row.currency) == string.lower(server.moneyPlural) then
				if players[chatvars.playerid].cash < tonumber(row.cost) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. " to travel there.[-]")
					botman.faultyChat = false
					return true
				else
					-- collect payment
					players[chatvars.playerid].cash = players[chatvars.playerid].cash - tonumber(row.cost)
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.cost .. " " .. server.moneyPlural .. " have been deducted for teleporting to " .. row.name .. ".[-]")
				end
			else
				if not inInventory(chatvars.playerid, row.currency, row.cost) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough of the required item to travel there.[-]")
					botman.faultyChat = false
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
			randomTP(chatvars.playerid, loc)

			if server.announceTeleports then
				if server.coppi and tonumber(chatvars.accessLevel) > 2 then message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " has moved to " .. loc .. "[-]") end
			end
		else
			cmd = "tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z
			prepareTeleport(chatvars.playerid, cmd)
			teleport(cmd)

			if server.announceTeleports then
				if server.coppi and tonumber(chatvars.accessLevel) > 2 then message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " has moved to " .. loc .. "[-]") end
			end
		end

		botman.faultyChat = false
		return true
	end

if debug then dbug("debug locations end") end

end

