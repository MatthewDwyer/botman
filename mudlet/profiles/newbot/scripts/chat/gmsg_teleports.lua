--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2016  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug
debug = false

function gmsg_teleports()
	calledFunction = "gmsg_teleports"

	local shortHelp = false
	local skipHelp = false

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.words[3], "tele") then
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
		irc_chat(chatvars.ircAlias, "Teleport Commands:")
		irc_chat(chatvars.ircAlias, "==================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "teleports")
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "dele") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {name} delete")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Delete a teleport.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "delete")) then
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

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "delete") - 1)
		tpname = string.trim(tpname)

		if (tpname == "") then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			else
				irc_chat(chatvars.ircAlias, "A name is required for the teleport")
			end

			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(tpname)

			teleports[tp] = nil
		end

		conn:execute("DELETE FROM teleports WHERE name = '" .. escape(tp) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have deleted a teleport called " .. tpname .. "[-]")
		else
			irc_chat(chatvars.ircAlias, "You have deleted a teleport called " .. tpname)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "priv") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {teleport name} private")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Make the teleport private.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "private")) then
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

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "private") - 1)
		tpname = string.trim(tpname)

		if (tpname == "") then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			else
				irc_chat(chatvars.ircAlias, "A name is required for the teleport")
			end

			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(tpname)

			teleports[tp].public = false
		end

		conn:execute("UPDATE teleports SET public = 0 WHERE name = '" .. escape(tp) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You changed a teleport called " .. tpname .. " to private[-]")
		else
			irc_chat(chatvars.ircAlias, "You changed a teleport called " .. tpname .. " to private")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "public") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {name} public")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Make a teleport public so anyone can use it.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "public")) then
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

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "public") - 1)
		tpname = string.trim(tpname)

		if (tpname == "") then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			else
				irc_chat(chatvars.ircAlias, "A name is required for the teleport")
			end

			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(tpname)

			teleports[tp].public = true
		end

		conn:execute("UPDATE teleports SET public = 1 WHERE name = '" .. escape(tp) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You changed a teleport called " .. tpname .. " to public[-]")
		else
			irc_chat(chatvars.ircAlias, "You changed a teleport called " .. tpname .. " to public")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "able") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {name} enable")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Enable a teleport that was disabled.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "enable")) then
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

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "enable") - 1)
		tpname = string.trim(tpname)

		if (tpname == "") then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			else
				irc_chat(chatvars.ircAlias, "A name is required for the teleport")
			end

			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(tpname)

			teleports[tp].active = true
		end

		conn:execute("UPDATE teleports SET active = 1 WHERE name = '" .. escape(tp) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You enabled a teleport called " .. tpname .. "[-]")
		else
			irc_chat(chatvars.ircAlias, "You enabled a teleport called " .. tpname)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "able") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {name} disable")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Disable a teleport to stop it triggering.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "disable")) then
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

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "disable") - 1)
		tpname = string.trim(tpname)

		if (tpname == "") then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			else
				irc_chat(chatvars.ircAlias, "A name is required for the teleport")
			end

			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(tpname)

			teleports[tp].active = false
		end

		conn:execute("UPDATE teleports SET active = 0 WHERE name = '" .. escape(tp) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You disabled a teleport called " .. tpname .. "[-]")
		else
			irc_chat(chatvars.ircAlias, "You disabled a teleport called " .. tpname)
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "way") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {name} one way")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Make a teleport work in one direction only. Teleports are a pair of coordinates and the second coordinate placed is the destination.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "one way")) then
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

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "one way") - 1)
		tpname = string.trim(tpname)
		tp = LookupTeleportByName(tpname)

		if (tp ~= "") then
			teleports[tp].oneway = true
			conn:execute("UPDATE teleports SET oneway = 1 WHERE name = '" .. escape(tp) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. teleports[tp].name .. " is a one way teleport.[-]")
			else
				irc_chat(chatvars.ircAlias, teleports[tp].name .. " is a one way teleport.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "way") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {name} two way")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Make a teleport work in both directions. After a short delay the player is teleported back if they don't move away.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "two way")) then
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

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "two way") - 1)
		tpname = string.trim(tpname)
		tp = LookupTeleportByName(tpname)

		if (tp ~= "") then
			teleports[tp].oneway = false
			conn:execute("UPDATE teleports SET oneway = 0 WHERE name = '" .. escape(tp) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. teleports[tp].name .. " is a two way teleport.[-]")
			else
				irc_chat(chatvars.ircAlias, teleports[tp].name .. " is a two way teleport.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "own") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {name} owner {player name}")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Assign ownership of a teleport to a player.  Only they and their friends can use it (and staff)")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "owner")) then
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

		tpname = ""
		tpowner = ""

		tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "owner") - 1)
		tpname = string.trim(tpname)

		tpowner = string.sub(chatvars.command, string.find(chatvars.command, "owner") + 6)
		tpowner = string.trim(tpowner)

		if tpname ~= "" and tpowner ~= "" then
			id = LookupPlayer(tpowner)
			if (players[id]) then
				tp = ""
				tp = LookupTeleportByName(tpname)

				if (tp ~= "") then
					teleports[tp].owner = id
					conn:execute("UPDATE teleports SET owner = " .. id .. " WHERE name = '" .. escape(tp) .. "'")
					message("say [" .. server.chatColour .. "]" .. players[id].name .. " is the proud new owner of a teleport called " .. teleports[tp].name .. "[-]")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "tp") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "enabletp {player name}")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Allows a player to use teleport commands.  Only staff can specify a player, otherwise it defaults to whoever issued the command.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (chatvars.words[1] == "enabletp") then
		id = chatvars.playerid
		pname = igplayers[chatvars.playerid].name

		if chatvars.accessLevel < 3 and chatvars.words[2] ~= nil then
			id = LookupPlayer(string.sub(chatvars.command, string.find(chatvars.command, "enabletp") + 9))
			if (id == 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No matching player found.[-]")
				botman.faultyChat = false
				return true
			else
				players[id].walkies = false
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " can now use teleports[-]")

				conn:execute("UPDATE players SET walkies = 0 WHERE steam = " .. id)

				botman.faultyChat = false
				return true
			end
		end

		players[id].walkies = false
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]you can use teleports and admins can teleport you[-]")
		conn:execute("UPDATE players SET walkies = 0 WHERE steam = " .. id)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "tp") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "disabletp {player name}")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Prevent a player using teleport commands. They can type " .. server.commandPrefix .. "enabletp any time. Only staff can specify a player, otherwise it defaults to whoever issued the command.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (chatvars.words[1] == "disabletp") then
		id = chatvars.playerid
		pname = igplayers[chatvars.playerid].name

		if chatvars.accessLevel < 3 and chatvars.words[2] ~= nil then
			id = LookupPlayer(string.sub(chatvars.command, string.find(chatvars.command, "disabletp") + 10))
			if (id == 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No matching player found.[-]")
				botman.faultyChat = false
				return true
			else
				players[id].walkies = true
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " can't use teleports[-]")

				conn:execute("UPDATE players SET walkies = 1 WHERE steam = " .. id)

				botman.faultyChat = false
				return true
			end
		end

		players[id].walkies = true
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]you cannot use teleports and admins can't teleport you (some exceptions)[-]")
		conn:execute("UPDATE players SET walkies = 1 WHERE steam = " .. id)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "tp") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set teleport cost {number}")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Set a price for all private teleporting (excludes public locations).  Players must have sufficient " .. server.moneyPlural .. " to teleport.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if chatvars.words[1] == "set" and string.find(chatvars.words[2], "tele") and chatvars.words[3] == "cost" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (chatvars.accessLevel > 1) then
				irc_chat(chatvars.ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number then
			server.teleportCost = chatvars.number
			conn:execute("UPDATE server SET teleportCost = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Private teleporting now costs " .. chatvars.number .. " " .. server.moneyPlural .. " per use.[-]")
			else
				irc_chat(chatvars.ircAlias, "Private teleporting now costs " .. chatvars.number .. " " .. server.moneyPlural .. " per use.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "delay") or string.find(chatvars.command, "time") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set teleport delay {number}")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Set a time delay for player initiated teleport commands.  The player will see a PM informing them that their teleport will happen in x seconds.  The default is 0 and no PM will be sent.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if chatvars.words[1] == "set" and string.find(chatvars.words[2], "tele") and chatvars.words[3] == "delay" then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (chatvars.accessLevel > 1) then
				irc_chat(chatvars.ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A number is expected.  Setting a delay of 0 means there will be no delay or PM.[-]")
			else
				irc_chat(chatvars.ircAlias, "A number is expected.  Setting a delay of 0 means there will be no delay or PM.")
			end
		else
			server.playerTeleportDelay = math.abs(chatvars.number)
			conn:execute("UPDATE server SET playerTeleportDelay = " .. math.abs(chatvars.number))

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player initiated teleporting will delay by " .. server.playerTeleportDelay .. " seconds.[-]")
			else
				irc_chat(chatvars.ircAlias, "Player initiated teleporting will delay by " .. server.playerTeleportDelay .. " seconds.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not allow remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Teleport In-Game Only:")
		irc_chat(chatvars.ircAlias, "========================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "fetch") or string.find(chatvars.command, "player") then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "fetch {player name}")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Move a player to your current location.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (chatvars.words[1] == "fetch") and (chatvars.playerid ~= 0) then
		-- reject if not an admin and server is in hardcore mode
		if isServerHardcore(chatvars.playerid) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is disabled.[-]")
			botman.faultyChat = false
			return true
		end

		if (chatvars.accessLevel > 2) and players[chatvars.playerid].cash < server.teleportCost then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You need " .. server.teleportCost .. " " .. server.moneyPlural .. " to fetch a friend to your location.[-]")
			botman.faultyChat = false
			return true
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "fetch ") + 6)

		if pname ~= "" then
			pname = string.trim(pname)
			id = LookupPlayer(pname)
		end

		if id == 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
			botman.faultyChat = false
			return true
		end

		if not igplayers[id] then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " is not playing right now.[-]")
			botman.faultyChat = false
			return true
		end

		-- reject if not an admin and player to player teleporting has been disabled
		if tonumber(chatvars.accessLevel) > 2 and not server.allowPlayerToPlayerTeleporting then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Fetching friends has been disabled on this server.[-]")
			botman.faultyChat = false
			return true
		end

		if (accessLevel(id) < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Staff cannot be fetched.[-]")
			botman.faultyChat = false
			return true
		end

		if (chatvars.accessLevel > 2) then
			-- reject if not a friend
			if (not isFriend(id,  chatvars.playerid)) and (chatvars.accessLevel > 2) and (id ~= chatvars.playerid) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only friends of " .. players[id].name .. " and staff can do this.")

				botman.faultyChat = false
				return true
			end
		end

		if players[id].yPosOld == 0 then
			-- first record their current x y z
			savePosition(id)
		end

		-- then teleport the player to you
		cmd = "tele " .. id .. " " .. chatvars.intX + 1 .. " " .. chatvars.intY .. " " .. chatvars.intZ
		teleport(cmd, chatvars.playerid)

		if (chatvars.accessLevel > 2) then
			players[chatvars.playerid].cash = players[chatvars.playerid].cash - server.teleportCost
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is being teleported to your location now.")
		message("pm " .. id .. " [" .. server.chatColour .. "]You are being teleported to " .. players[chatvars.playerid].name .. "'s location.")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "pack") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "pack")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Teleport close to where you last died.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (chatvars.words[1] == "pack" or chatvars.words[1] == "revive") and chatvars.words[2] == nil and (chatvars.playerid ~= 0) then
		-- reject if not an admin and server is in hardcore mode
		if (isServerHardcore(chatvars.playerid) or not server.allowPackTeleport) and chatvars.accessLevel > 2 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is disabled.[-]")
			botman.faultyChat = false
			return true
		end

		if tonumber(players[chatvars.playerid].deathX) ~= 0 then
			if players[chatvars.playerid].packCooldown > os.time() then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can " .. server.commandPrefix .. "pack in " .. os.date("%M minutes %S seconds", players[chatvars.playerid].packCooldown - os.time()) .. " seconds.[-]")
				botman.faultyChat = false
				return true
			end

			if tonumber(server.packCost) > 0 and (tonumber(players[chatvars.playerid].cash) < tonumber(server.packCost)) and (chatvars.accessLevel > 3) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. " to teleport to your pack.  You need " .. server.packCost .. " " .. server.moneyPlural .. ".[-]")
				botman.faultyChat = false
				return true
			end

			cursor,errorString = conn:execute("SELECT x, y, z FROM tracker WHERE steam = " .. chatvars.playerid .. " and ((abs(x - " .. players[chatvars.playerid].deathX .. ") > 0 and abs(x - " .. players[chatvars.playerid].deathX .. ") < 50) and (abs(z - " .. players[chatvars.playerid].deathZ .. ") > 5 and abs(z - " .. players[chatvars.playerid].deathZ .. ") < 50))  ORDER BY trackerid DESC Limit 0, 1")
			if cursor:numrows() > 0 then
				row = cursor:fetch({}, "a")
				cmd = ("tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z)
				players[chatvars.playerid].deathX = 0
				players[chatvars.playerid].deathY = 0
				players[chatvars.playerid].deathZ = 0

				-- first record their current x y z
				savePosition(chatvars.playerid)

				teleport(cmd, chatvars.playerid)

				if tonumber(server.packCost) > 0 and (chatvars.accessLevel > 3) then
					players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - server.packCost
					conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = " .. chatvars.playerid)
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. server.packCost .. " " .. server.moneyPlural .. " has been removed from your cash.[-]")
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry I am unable to find a spot close to your pack to send you there.[-]")
				players[chatvars.playerid].deathX = 0
				players[chatvars.playerid].deathY = 0
				players[chatvars.playerid].deathZ = 0
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not died since you last revived.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "stuck") or string.find(chatvars.command, "tele") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "stuck")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Teleport 2 metres up.  If " .. server.commandPrefix .. "stuck is repeated the bot will try to teleport you nearby.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (chatvars.words[1] == "stuck" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if not server.allowStuckTeleport then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The stuck command has been disabled on this server.[-]")
			botman.faultyChat = false
			return true
		end

		cmd = "tele " .. chatvars.playerid .. " " .. chatvars.intX .. " -1 " .. chatvars.intZ

		if tonumber(server.playerTeleportDelay) == 0 then
			teleport(cmd, chatvars.playerid)
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will teleport in " .. server.playerTeleportDelay .. " seconds.[-]")
			if botman.dbConnected then conn:execute("insert into miscQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "return") or string.find(chatvars.command, "tele") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "return")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Teleport back to where you came from before your last teleport command.  Locations support a 2nd return if you teleport within the location more than once without leaving it.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if ((chatvars.words[1] == "return") and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if not server.allowReturns and chatvars.accessLevel > 2 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The return command is disabled on this server.[-]")
			botman.faultyChat = false
			return true
		end

		if players[chatvars.playerid].inLocation ~= "" then
			if not locations[players[chatvars.playerid].inLocation].allowReturns and chatvars.accessLevel > 2 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The return command is disabled in this location.[-]")
				botman.faultyChat = false
				return true
			end
		end

		-- reject if not an admin and pvpTeleportCooldown or returnCooldown is > zero
		if tonumber(chatvars.accessLevel) > 2 then
			if (players[chatvars.playerid].returnCooldown - os.time() > 0) then
				message(string.format("pm %s [%s]You must wait %s before you are allowed to use return.", chatvars.playerid, server.chatColour, os.date("%M minutes %S seconds",players[chatvars.playerid].returnCooldown - os.time())))
				botman.faultyChat = false
				return true
			end

			if (players[chatvars.playerid].pvpTeleportCooldown - os.time() > 0) then
				message(string.format("pm %s [%s]You must wait %s before you are allowed to teleport again.", chatvars.playerid, server.chatColour, os.date("%M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())))
				botman.faultyChat = false
				return true
			end
		end

		-- return to previously recorded x y z
		if tonumber(players[chatvars.playerid].yPosOld) ~= 0 or tonumber(players[chatvars.playerid].yPosOld2) ~= 0 then
			if tonumber(players[chatvars.playerid].yPosOld2) ~= 0 then
				-- the player has teleported within the same location so they are returning to somewhere in that location
				cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].xPosOld2 .. " " .. players[chatvars.playerid].yPosOld2 .. " " .. players[chatvars.playerid].zPosOld2

				if tonumber(server.playerTeleportDelay) == 0 or not igplayers[chatvars.playerid].currentLocationPVP then
					teleport(cmd, chatvars.playerid)
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will return in " .. server.playerTeleportDelay .. " seconds.[-]")
					if botman.dbConnected then conn:execute("insert into miscQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
				end

				if players[chatvars.playerid].yPos < 1000 then
					players[chatvars.playerid].xPosOld2 = 0
					players[chatvars.playerid].yPosOld2 = 0
					players[chatvars.playerid].zPosOld2 = 0

					conn:execute("UPDATE players SET xPosOld2 = 0, yPosOld2 = 0, zPosOld2 = 0 WHERE steam = " .. chatvars.playerid)
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have another " .. server.commandPrefix .. "return available.[-]")
			else
				-- the player has teleported from outside their current location so they are returning to there.
				cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].xPosOld .. " " .. players[chatvars.playerid].yPosOld .. " " .. players[chatvars.playerid].zPosOld

				if tonumber(server.playerTeleportDelay) == 0 or not igplayers[chatvars.playerid].currentLocationPVP then
					teleport(cmd, chatvars.playerid)
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will return in " .. server.playerTeleportDelay .. " seconds.[-]")
					if botman.dbConnected then conn:execute("insert into miscQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
				end

				if players[chatvars.playerid].yPos < 1000 then
					players[chatvars.playerid].xPosOld = 0
					players[chatvars.playerid].yPosOld = 0
					players[chatvars.playerid].zPosOld = 0
					igplayers[chatvars.playerid].lastLocation = ""

					conn:execute("UPDATE players SET xPosOld = 0, yPosOld = 0, zPosOld = 0 WHERE steam = " .. chatvars.playerid)
				end
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have used all your returns.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "teleports")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "List the teleports.  Players can only see public teleports.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (chatvars.words[1] == "teleports" and chatvars.words[3] == nil) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		id = 0
		if (chatvars.words[2]) then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "teleports ") + 10)
			pname = string.trim(pname)
			if (pname ~= nil) then id = LookupPlayer(pname) end
		end

		for k, v in pairs(teleports) do
			if (v.public == true) then
				public = "public"
			else
				public = "private"
			end

			if (id == 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " " .. public .. "[-]")
			else
				if (v.owner == id) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " " .. public .. "[-]")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "opentp") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		teleName = ""
		teleName = string.sub(chatvars.command, string.find(chatvars.command, "opentp ") + 7)
		teleName = string.trim(teleName)

		if (teleName == "") then
			message("pm " .. chatvars.playername .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(teleName)
			action = "moved"

			if (tp == nil) then
				teleports[teleName] = {}
				action = "created"
				teleports[teleName].public = false
				teleports[teleName].active = false
				teleports[teleName].friends = false
				teleports[teleName].name = teleName
				teleports[teleName].owner = igplayers[chatvars.playerid].steam
				teleports[teleName].oneway = false
		   end

			teleports[teleName].x = chatvars.intX
			teleports[teleName].y = chatvars.intY
			teleports[teleName].z = chatvars.intZ
			teleports[teleName].size = 1.5
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have " .. action .. " a teleport called " .. teleName .. "[-]")
		conn:execute("INSERT INTO teleports (name, owner, x, y, z) VALUES ('" .. teleName .. "'," .. chatvars.playerid .. "," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ") ON DUPLICATE KEY UPDATE x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " ..chatvars.intZ)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "closetp") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		teleName = ""
		teleName = string.sub(chatvars.command, string.find(chatvars.command, "closetp ") + 8)
		teleName = string.trim(teleName)

		if (teleName == "") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(teleName)

			if (teleports[tp].name == teleName) then
				teleports[tp].dx = chatvars.intX
				teleports[tp].dy = chatvars.intY
				teleports[tp].dz = chatvars.intZ
				teleports[tp].dsize = 1.5

				if (teleports[tp].x ~= nil) then teleports[tp].active = true end
			end
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have activated a teleport called " .. teleName .. "[-]")
		conn:execute("UPDATE teleports SET dx = " .. chatvars.intX .. ", dy = " .. chatvars.intY .. ", dz = " .. chatvars.intZ .. " WHERE name = '" .. escape(tp) .. "'")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "start") or string.find(chatvars.command, "size") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {name} start size {radius in blocks}")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Set the size of the starting point of a pair of teleports.  The default is 3 wide (1.5 radius)")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "start") and string.find(chatvars.command, "size")) then
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

		teleName = ""
		teleName = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, " start"))
		teleName = string.trim(teleName)
		teleSize = math.abs(chatvars.number)

		if (teleName == "") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(teleName)
		end

		if (tp ~= nil) then
			conn:execute("UPDATE teleports SET size = " .. teleSize .. " WHERE name = '" .. escape(tp) .. "'")
			teleports[tp].size = teleSize
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport " .. teleName .. "'s start width is " .. teleSize * 2 .. "[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "end") or string.find(chatvars.command, "size") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {name} end size {radius in blocks}")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Set the size of the exit point of a pair of teleports.  The default is 3 wide (1.5 radius)")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "end") and string.find(chatvars.command, "size")) then
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

		teleName = ""
		teleName = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, " end"))
		teleName = string.trim(teleName)
		teleSize = math.abs(chatvars.number)

		if (teleName == "") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(teleName)
		end

		if (tp ~= nil) then
			conn:execute("UPDATE teleports SET dsize = " .. teleSize .. " WHERE name = '" .. escape(tp) .. "'")
			teleports[tp].dsize = teleSize
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport " .. teleName .. "'s end width is " .. teleSize * 2 .. "[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "start") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {name} start")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Create a teleport starting at your location or move an existing teleport's start to you.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "start")) then
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

		teleName = ""
		teleName = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, " start"))
		teleName = string.trim(teleName)

		if (teleName == "") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(teleName)
		end

		if (tp == nil) then
			teleports[teleName] = {}
			teleports[teleName].public = false
			teleports[teleName].active = true
			teleports[teleName].friends = false
			teleports[teleName].name = teleName
			teleports[teleName].owner = igplayers[chatvars.playerid].steam
			teleports[teleName].oneway = false
			teleports[teleName].x = chatvars.intX
			teleports[teleName].y = chatvars.intY
			teleports[teleName].z = chatvars.intZ
			teleports[teleName].size = 1.5
			teleports[teleName].dsize = 1.5

			conn:execute("INSERT INTO teleports (name, owner, x, y, z) VALUES ('" .. teleName .. "'," .. chatvars.playerid .. "," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
		else
			conn:execute("UPDATE teleports SET x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. " WHERE name = '" .. escape(tp) .. "'")
			teleports[teleName].x = chatvars.intX
			teleports[teleName].y = chatvars.intY
			teleports[teleName].z = chatvars.intZ
			teleports[teleName].active = true
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport " .. teleName .. " starts here[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or string.find(chatvars.command, "end") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tele {name} end")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Complete a teleport ending at your location or move an existing teleport's end to you.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "end")) then
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

		teleName = ""
		teleName = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, " end"))
		teleName = string.trim(teleName)

		if (teleName == "") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(teleName)
		end

		if (tp == nil) then
			teleports[teleName] = {}
			teleports[teleName].public = false
			teleports[teleName].active = true
			teleports[teleName].friends = false
			teleports[teleName].name = teleName
			teleports[teleName].owner = igplayers[chatvars.playerid].steam
			teleports[teleName].oneway = false
			teleports[teleName].dx = chatvars.intX
			teleports[teleName].dy = chatvars.intY
			teleports[teleName].dz = chatvars.intZ
			teleports[teleName].size = 1.5
			teleports[teleName].dsize = 1.5


			conn:execute("INSERT INTO teleports (name, owner, dx, dy, dz) VALUES ('" .. teleName .. "'," .. chatvars.playerid .. "," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ")")
		else
			conn:execute("UPDATE teleports SET dx = " .. chatvars.intX .. ", dy = " .. chatvars.intY .. ", dz = " .. chatvars.intZ .. " WHERE name = '" .. escape(tp) .. "'")
			teleports[teleName].dx = chatvars.intX
			teleports[teleName].dy = chatvars.intY
			teleports[teleName].dz = chatvars.intZ
			teleports[teleName].active = true
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport " .. teleName .. " ends here[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "tele") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tp {player name}")
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "tp {X coord} {Y coord} {Z coord}")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Teleport yourself to a player or to an coordinate.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if (chatvars.words[1] == "tp" or chatvars.words[1] == "tele") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		if chatvars.words[2] == "back" then
			-- first record their current x y z
			savePosition(chatvars.playerid)

			if chatvars.number == nil then
				chatvars.number = 10
			end

			cursor,errorString = conn:execute("select * from tracker where steam = " .. chatvars.playerid ..  " order by trackerID desc limit " .. chatvars.number .. ",1")
			row = cursor:fetch({}, "a")

			if row then
				cmd = "tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z
				teleport(cmd, chatvars.playerid)
				botman.faultyChat = false
				return true
			end
		end

		if (chatvars.words[2] == "north" or chatvars.words[2] == "south" or chatvars.words[2] == "east" or chatvars.words[2] == "west") then
			-- first record their current x y z
			savePosition(chatvars.playerid)

			if chatvars.number == nil then
				chatvars.number = 50
			end

			if chatvars.words[2] == "north" then
				cmd = "tele " .. chatvars.playerid .. " " .. math.floor(players[chatvars.playerid].xPos) .. " " .. math.ceil(players[chatvars.playerid].yPos) .. " " .. math.floor(players[chatvars.playerid].zPos) + chatvars.number
			end

			if chatvars.words[2] == "south" then
				cmd = "tele " .. chatvars.playerid .. " " .. math.floor(players[chatvars.playerid].xPos) .. " " .. math.ceil(players[chatvars.playerid].yPos) .. " " .. math.floor(players[chatvars.playerid].zPos) - chatvars.number
			end

			if chatvars.words[2] == "west" then
				cmd = "tele " .. chatvars.playerid .. " " .. math.floor(players[chatvars.playerid].xPos) - chatvars.number .. " " .. math.ceil(players[chatvars.playerid].yPos) .. " " .. math.floor(players[chatvars.playerid].zPos)
			end

			if chatvars.words[2] == "east" then
				cmd = "tele " .. chatvars.playerid .. " " .. math.floor(players[chatvars.playerid].xPos) + chatvars.number .. " " .. math.ceil(players[chatvars.playerid].yPos) .. " " .. math.floor(players[chatvars.playerid].zPos)
			end

			teleport(cmd, chatvars.playerid)

			botman.faultyChat = false
			return true
		end

		if chatvars.words[4] ~= nil then
			-- first record their current x y z
			savePosition(chatvars.playerid)

			cmd = "tele " .. chatvars.playerid .. " " .. math.floor(chatvars.words[2]) .. " " .. math.ceil(chatvars.words[3]) .. " " .. math.floor(chatvars.words[4])
			teleport(cmd, chatvars.playerid)

			botman.faultyChat = false
			return true
		end

		teleName = ""

		if chatvars.words[1] == "tp" then
			teleName = string.sub(chatvars.command, string.find(chatvars.command, "tp ") + 3)
		else
			teleName = string.sub(chatvars.command, string.find(chatvars.command, "tele ") + 5)
		end

		teleName = string.trim(teleName)

		if (teleName == "") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the " .. server.commandPrefix .. "tp command[-]")
			botman.faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(teleName)

			if tp ~= nil then
				-- first record their current x y z
				savePosition(chatvars.playerid)

				cmd = "tele " .. chatvars.playerid .. " " .. math.floor(teleports[tp].x) .. " " .. math.ceil(teleports[tp].y) .. " " .. math.floor(teleports[tp].z)
				teleport(cmd, chatvars.playerid)
				igplayers[chatvars.playerid].teleCooldown = 3

				botman.faultyChat = false
				return true
			end

			tp = LookupPlayer(teleName)

			if tp ~= nil then
				-- first record their current x y z
				savePosition(chatvars.playerid)

				cmd = "tele " .. chatvars.playerid .. " " .. math.floor(players[tp].xPos) .. " " .. math.ceil(players[tp].yPos) .. " " .. math.floor(players[tp].zPos)
				teleport(cmd, chatvars.playerid)

				botman.faultyChat = false
				return true
			end
		end

		botman.faultyChat = false
		return true
	end

if debug then dbug("teleports end") end

end
