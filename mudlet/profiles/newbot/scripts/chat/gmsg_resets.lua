--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_resets()
	local region, x, z, debug, result, help, tmp
	local shortHelp = false

	debug = false -- should be false unless testing

	calledFunction = "gmsg_resets"
	result = false
	tmp = {}
	tmp.topic = "resets"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## reset command functions ##################

	local function cmd_DeleteResetZones()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}clear reset zones"
			help[2] = "The bot will forget all the reset zones so you can start over marking new ones."

			tmp.command = help[1]
			tmp.keywords = "clear,forget,remove,delete,reset,zones"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "clear" or chatvars.words[1] == "reset" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" and chatvars.words[3] == "zones" and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if ((chatvars.words[1] == "clear" or chatvars.words[1] == "reset" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" and chatvars.words[3] == "zones") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			resetRegions = {}
			conn:execute("TRUNCATE resetZones")
			connSQL:execute("UPDATE keystones SET remove = 0") -- clear the remove flag from the keystones table to prevent removals that we don't want.

			if server.botman then
				sendCommand("bm-resetregions clearall")
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]All reset zones have been forgotten.[-]")
			else
				irc_chat(chatvars.ircAlias, "All reset zones have been forgotten.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleResetZone()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}add (or {#}remove) reset\n"
			help[1] = help[1] .. "Or {#}add (or {#}remove) reset x-coord z-coord"
			help[2] = "Flag or unflag an entire region as a reset zone.  If you don't specify an x and z coord, you need to be playing and standing inside the region.\n"
			help[2] = help[2] .. "Example with coords: /add reset -1 3.  This will make region r.-1.3.7rg a reset zone."

			tmp.command = help[1]
			tmp.keywords = "add,remove,reset,zones"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "remo") or string.find(chatvars.command, "dele") or string.find(chatvars.command, "reset") or string.find(chatvars.command, "regi") or string.find(chatvars.command, "zone") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (not igplayers[chatvars.playerid]) and tablelength(chatvars.numbers) < 2 then
				irc_chat(chatvars.ircAlias, "Please specify an x and z coord. eg {#}add reset -1 3, or join the server and repeat the command while standing in the region.")
				botman.faultyChat = false
				return true
			end

			if tablelength(chatvars.numbers) == 0 then
				x = math.floor(igplayers[chatvars.playerid].xPos / 512)
				z = math.floor(igplayers[chatvars.playerid].zPos / 512)
			else
				x = math.floor(chatvars.numbers[1])
				z = math.floor(chatvars.numbers[2])
			end

			region = "r." .. x .. "." .. z .. ".7rg"

			if (chatvars.words[1] == "add") then
				resetRegions[region] = {}
				conn:execute("INSERT INTO resetZones (region, x, z) VALUES ('" .. escape(region) .. "'," .. x .. "," .. z .. ")")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Region " .. region .. " is now a reset zone.[-]")
				else
					irc_chat(chatvars.ircAlias, "Region " .. region .. " is now a reset zone.")
				end

				if server.botman then
					sendCommand("bm-resetregions add " .. x .. "." .. z)
				end
			else
				resetRegions[region] = nil
				conn:execute("DELETE FROM resetZones WHERE region = '" .. region .. "'")
				connSQL:execute("UPDATE keystones SET remove = 0") -- clear the remove flag from the keystones table to prevent removals that we don't want.

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Region " .. region .. " is no longer a reset zone.[-]")
				else
					irc_chat(chatvars.ircAlias, "Region " .. region .. " is no longer a reset zone.")
				end

				sendCommand("bm-resetregions remove " .. x .. "." .. z)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListResetZones()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reset zones"
			help[2] = "List all of the regions that are reset zones."

			tmp.command = help[1]
			tmp.keywords = "view,list,reset,zones"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reset") or string.find(chatvars.command, "zone") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "reset" and chatvars.words[2] == "zones") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			cursor,errorString = conn:execute("select * from resetZones")
			rows = cursor:numrows()

			if rows == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No regions have been flagged as reset zones.[-]")
				else
					irc_chat(chatvars.ircAlias, "No regions have been flagged as reset zones.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The following regions are reset zones:[-]")
				else
					irc_chat(chatvars.ircAlias, "The following regions are reset zones:")
				end

				row = cursor:fetch({}, "a")
				while row do
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.region .. "[-]")
					else
						irc_chat(chatvars.ircAlias, row.region)
					end

					row = cursor:fetch(row, "a")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RedoResetZones()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}redo reset zones"
			help[2] = "Put back all of the reset zones via the Botman mod if you've accidentally deleted the mod's config.xml file from the server.\n"
			help[2] = help[2] .. "Note:  This requires the Botman mod or all it really does is list the reset zones."

			tmp.command = help[1]
			tmp.keywords = "add,restore,reset,zones,reload"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "redo") or string.find(chatvars.command, "zone") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "redo" and chatvars.words[2] == "reset" and chatvars.words[3] == "zones") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			cursor,errorString = conn:execute("select * from resetZones")
			rows = cursor:numrows()

			if rows == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No regions have been flagged as reset zones.[-]")
				else
					irc_chat(chatvars.ircAlias, "No regions have been flagged as reset zones.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Re-adding reset zones from the bot to the server:[-]")
				else
					irc_chat(chatvars.ircAlias, "Re-adding reset zones from the bot to the server:")
				end

				row = cursor:fetch({}, "a")
				while row do
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] adding reset zone " .. row.region .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "adding reset zone " .. row.region)
					end

					if server.botman then
						sendCommand("bm-resetregions add " .. row.x .. "." .. row.z)
					end

					row = cursor:fetch(row, "a")
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		if debug then dbug("Registering help - reset commands") end

		tmp.topicDescription = "Reset zones tell a player where when they can't place claims or setbase in a location or region.  The bot is not able to actually delete parts of the map and that must be done manually with the server offline.  The bot does provide a list of regions that are reset zones if any regions have been flagged as such."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Reset Zone Commands:")
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, tmp.topicDescription)
			irc_chat(chatvars.ircAlias, ".")
		end

		cursor,errorString = connSQL:execute("SELECT count(*) FROM helpTopics WHERE topic = '" .. tmp.topic .. "'")
		row = cursor:fetch({}, "a")
		rows = row["count(*)"]

		if rows == 0 then
			connSQL:execute("INSERT INTO helpTopics (topic, description) VALUES ('" .. tmp.topic .. "', '" .. connMEM:escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false, ""
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "resets" then
				botman.faultyChat = false
				return true, ""
			end
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and chatvars.words[1] ~= "help" and not botman.registerHelp then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Reset Zone Commands:")
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Regions can be marked as reset zones to warn players not to build in them.")
		irc_chat(chatvars.ircAlias, "It will block setbase and sethome and any claims placed by players are removed.")
		irc_chat(chatvars.ircAlias, "Currently the bot does not have the ability to physically delete region files but it can provide a list of reset zones for manual deletion.")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "resets")
	end

	if (debug) then dbug("debug resets line " .. debugger.getinfo(1).currentline) end

	result = cmd_DeleteResetZones()

	if result then
		if debug then dbug("debug cmd_DeleteResetZones triggered") end
		return result, "cmd_DeleteResetZones"
	end

	if (debug) then dbug("debug resets line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListResetZones()

	if result then
		if debug then dbug("debug cmd_ListResetZones triggered") end
		return result, "cmd_ListResetZones"
	end

	if debug then dbug("debug resets end of remote commands") end

	result = cmd_RedoResetZones()

	if result then
		if debug then dbug("debug cmd_RedoResetZones triggered") end
		return result, "cmd_RedoResetZones"
	end

	if debug then dbug("debug resets end of remote commands") end

	result = cmd_ToggleResetZone()

	if result then
		if debug then dbug("debug cmd_ToggleResetZone triggered") end
		return result, "cmd_ToggleResetZone"
	end

	if botman.registerHelp then
		if debug then dbug("Reset commands help registered") end
	end

	if debug then dbug("debug resets end") end

	-- can't touch dis
	if true then
		return result, ""
	end
end
