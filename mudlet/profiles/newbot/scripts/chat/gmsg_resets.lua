--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local region, x, z, debug, result, help, tmp
local shortHelp = false
local skipHelp = false

debug = false -- should be false unless testing

function gmsg_resets()
	calledFunction = "gmsg_resets"
	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## reset command functions ##################

	local function cmd_DeleteResetZones()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}clear reset zones"
			help[2] = "The bot will forget all the reset zones so you can start over marking new ones."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "clear,forget,remo,del,reset,zone"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "clear" or chatvars.words[1] == "reset" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" and chatvars.words[3] == "zones"  or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if ((chatvars.words[1] == "clear" or chatvars.words[1] == "reset" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" and chatvars.words[3] == "zones") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			resetRegions = {}
			conn:execute("TRUNCATE resetZones")
			conn:execute("UPDATE keystones SET remove = 0") -- clear the remove flag from the keystones table to prevent removals that we don't want.

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]All reset zones have been forgotten.[-]")
			else
				irc_chat(chatvars.ircAlias, "All reset zones have been forgotten.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleResetZone()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}add/remove reset\n"
			help[1] = help[1] .. " {#}add/remove reset x-coord z-coord"
			help[2] = "Flag or unflag an entire region as a reset zone.  If you don't specify an x and z coord, you need to be playing and standing inside the region.\n"
			help[2] = help[2] .. "Example with coords: /add reset -1 3.  This will make region r.-1.3.7rg a reset zone."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,remo,reset,zone"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "remo") or string.find(chatvars.command, "dele") or string.find(chatvars.command, "reset") or string.find(chatvars.command, "regi") or string.find(chatvars.command, "zone") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if (not igplayers[chatvars.playerid]) and table.maxn(chatvars.numbers) < 2 then
				irc_chat(chatvars.ircAlias, "Please specify an x and z coord. eg {#}add reset -1 3, or join the server and repeat the command while standing in the region.")
				botman.faultyChat = false
				return true
			end

			if table.maxn(chatvars.numbers) == 0 then
				x = math.floor(igplayers[chatvars.playerid].xPos / 512)
				z = math.floor(igplayers[chatvars.playerid].zPos / 512)
			else
				x = math.floor(chatvars.numbers[1])
				z = math.floor(chatvars.numbers[2])
			end

			region = "r." .. x .. "." .. z .. ".7rg"

			if (chatvars.words[1] == "add") then
				resetRegions[region] = {}
				conn:execute("INSERT INTO resetZones (region) VALUES ('" .. region .. "')")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Region " .. region .. " is now a reset zone.[-]")
				else
					irc_chat(chatvars.ircAlias, "Region " .. region .. " is now a reset zone.")
				end
			else
				resetRegions[region] = nil
				conn:execute("DELETE FROM resetZones WHERE region = '" .. region .. "'")
				conn:execute("UPDATE keystones SET remove = 0") -- clear the remove flag from the keystones table to prevent removals that we don't want.

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Region " .. region .. " is no longer a reset zone.[-]")
				else
					irc_chat(chatvars.ircAlias, "Region " .. region .. " is no longer a reset zone.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListResetZones()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reset zones"
			help[2] = "List all of the regions that are reset zones."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "view,list,reset,zone"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reset") or string.find(chatvars.command, "zone") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "reset" and chatvars.words[2] == "zones") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			cursor,errorString = conn:execute("select * from resetZones")
			rows = cursor:numrows()

			if rows == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No regions have been flagged as reset zones.[-]")
				else
					irc_chat(chatvars.ircAlias, "No regions have been flagged as reset zones.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The following regions are reset zones:[-]")
				else
					irc_chat(chatvars.ircAlias, "The following regions are reset zones:")
				end

				row = cursor:fetch({}, "a")
				while row do
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.region .. "[-]")
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

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - reset commands ====")
		dbug("Registering help - reset commands")

		tmp = {}
		tmp.topicDescription = "Reset zones tell a player where when they can't place claims or setbase in a location or region.  The bot is not able to actually delete parts of the map and that must be done manually with the server offline.  The bot does provide a list of regions that are reset zones if any regions have been flagged as such."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'reset zones'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('reset zones', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
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
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Reset Zone Commands:")
		irc_chat(chatvars.ircAlias, "====================")
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
		return result
	end

	if (debug) then dbug("debug resets line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListResetZones()

	if result then
		if debug then dbug("debug cmd_ListResetZones triggered") end
		return result
	end

	if debug then dbug("debug resets end of remote commands") end

	result = cmd_ToggleResetZone()

	if result then
		if debug then dbug("debug cmd_ToggleResetZone triggered") end
		return result
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Reset commands help registered ****")
		dbug("Reset commands help registered")
		topicID = topicID + 1
	end

	if debug then dbug("debug resets end") end

	-- can't touch dis
	if true then
		return result
	end
end
