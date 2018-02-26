--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local region, x, z, debug, result, row, rows, cursor, errorString
local shortHelp = false
local skipHelp = false

debug = false -- should be false unless testing

if botman.debugAll then
	debug = true
end

function gmsg_resets()
	calledFunction = "gmsg_resets"
	result = false

-- ################## reset command functions ##################

	local function cmd_DeleteResetZones()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "clear" or chatvars.words[1] == "reset" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" and chatvars.words[3] == "zones"  or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "clear reset zones")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "The bot will forget all the reset zones so you can start over marking new ones.")
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
			conn:execute("DELETE FROM resetZones")
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
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "add") or string.find(chatvars.command, "remo") or string.find(chatvars.command, "dele") or string.find(chatvars.command, "reset") or string.find(chatvars.command, "regi") or string.find(chatvars.command, "zone") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "add reset zone")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "remove reset zone")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Flag or unflag an entire region as a reset zone.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if ((chatvars.words[1] == "add" or chatvars.words[1] == "remove" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" and (chatvars.words[3] == "region" or chatvars.words[3] == "zone")) then
			if (chatvars.accessLevel > 3) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
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
				conn:execute("DELETE FROM resetZones WHERE region = '" .. region .. "'")
				conn:execute("UPDATE keystones SET remove = 0") -- clear the remove flag from the keystones table to prevent removals that we don't want.
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Region " .. region .. " is no longer a reset zone.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListResetZones()
		if chatvars.showHelp and not skipHelp then
			if string.find(chatvars.command, "reset") or string.find(chatvars.command, "zone") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "reset zones")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "List all of the regions that are reset zones.")
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

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == 0 and not chatvars.showHelp then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if (debug) then dbug("debug resets line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleResetZone()

	if result then
		if debug then dbug("debug cmd_ToggleResetZone triggered") end
		return result
	end

	if debug then dbug("debug resets end") end

	-- can't touch dis
	if true then
		return result
	end
end
