--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2016  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug, tpname, tp, tpowner, pname, id, cmd, k, v, i, public, teleName, action, result, help, tmp -- cursor, errorString, row
local shortHelp = false
local skipHelp = false

debug = false -- should be false unless testing

function gmsg_teleports()
	calledFunction = "gmsg_teleports"
	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## teleport command functions ##################

	local function cmd_DeleteTeleport()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}tele {name} delete"
			help[2] = "Delete a teleport."

			tmp.command = help[1]
			tmp.keywords = "tele,dele,remo"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "delete"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
	end


	local function cmd_ToggleTeleportPublic()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}tele {teleport name} private\n"
			help[1] = help[1] .. " {#}tele {teleport name} public"
			help[2] = "Make the teleport private or public.  New teleports are private by default."

			tmp.command = help[1]
			tmp.keywords = "tele,set,pub,priv"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "priv") or string.find(chatvars.command, "publ") or string.find(chatvars.command, "set") or string.find(chatvars.command, "togg"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.words[1], "tele") and (string.find(chatvars.command, "private") or string.find(chatvars.command, "public")) then
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

			-- get the name of the teleport
			tpname = ""

			if string.find(chatvars.command, " private") then
				tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "private") - 1)
			else
				tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "public") - 1)
			end

			tpname = string.trim(tpname)

			if (tpname == "") then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
				else
					irc_chat(chatvars.ircAlias, "A name is required for the teleport")
				end

				botman.faultyChat = false
				return true
			end

			-- does the teleport exist?
			tp = ""
			tp = LookupTeleportByName(tpname)

			if tp == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No teleport found called " .. tpname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No teleport found called " .. tpname)
				end

				botman.faultyChat = false
				return true
			end

			-- set it to public or private
			if string.find(chatvars.command, " private") then
				teleports[tp].public = false
				conn:execute("UPDATE teleports SET public = 0 WHERE name = '" .. escape(tp) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You changed a teleport called " .. tpname .. " to private[-]")
				else
					irc_chat(chatvars.ircAlias, "You changed a teleport called " .. tpname .. " to private")
				end
			else
				teleports[tp].public = true
				conn:execute("UPDATE teleports SET public = 1 WHERE name = '" .. escape(tp) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You changed a teleport called " .. tpname .. " to public[-]")
				else
					irc_chat(chatvars.ircAlias, "You changed a teleport called " .. tpname .. " to public")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleTeleportEnabled()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}tele {name} enable\n"
			help[1] = help[1] .. " {#}tele {name} disable"
			help[2] = "Enable or disable a teleport."

			tmp.command = help[1]
			tmp.keywords = "tele,able"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "able"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (string.find(chatvars.words[1], "tele") and string.find(chatvars.command, "able") and chatvars.words[3] ~= nil) then
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

			-- get the name of the teleport
			tpname = ""

			if string.find(chatvars.command, " enable") then
				tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "enable") - 1)
			else
				tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "disable") - 1)
			end

			tpname = string.trim(tpname)

			if (tpname == "") then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
				else
					irc_chat(chatvars.ircAlias, "A name is required for the teleport")
				end

				botman.faultyChat = false
				return true
			end

			-- does the teleport exist?
			tp = ""
			tp = LookupTeleportByName(tpname)

			if tp == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No teleport found called " .. tpname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No teleport found called " .. tpname)
				end

				botman.faultyChat = false
				return true
			end

			-- set teleport enabled or disabled
			if string.find(chatvars.command, " enable") then
				teleports[tp].active = true
				conn:execute("UPDATE teleports SET active = 1 WHERE name = '" .. escape(tp) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You enabled a teleport called " .. tpname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "You enabled a teleport called " .. tpname)
				end
			else
				teleports[tp].active = false
				conn:execute("UPDATE teleports SET active = 0 WHERE name = '" .. escape(tp) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You disabled a teleport called " .. tpname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "You disabled a teleport called " .. tpname)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleTeleportOneWay()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}tele {name} one way\n"
			help[1] = help[1] .. " {#}tele {name} two way"
			help[2] = "Teleports are a pair of coordinates and the second coordinate placed is the destination.\n"
			help[2] = help[2] .. "You can make it work in one direction only or both ways (loop). They are two way teleports by default."

			tmp.command = help[1]
			tmp.keywords = "tele,one,two,dir"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.words[1], "tele") and (string.find(chatvars.command, "one way") or string.find(chatvars.command, "two way")) then
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

			-- get the name of the teleport
			tpname = ""

			if string.find(chatvars.command, "one way") then
				tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "one way") - 1)
			else
				tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1]) + string.len(chatvars.words[1]) + 1, string.find(chatvars.command, "two way") - 1)
			end

			tpname = string.trim(tpname)

			-- does the teleport exist?
			tp = ""
			tp = LookupTeleportByName(tpname)

			if tp == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No teleport found called " .. tpname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No teleport found called " .. tpname)
				end

				botman.faultyChat = false
				return true
			end

			-- set teleport one-way or two-way
			if string.find(chatvars.command, "one way") then
				teleports[tp].oneway = true
				conn:execute("UPDATE teleports SET oneway = 1 WHERE name = '" .. escape(tp) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. teleports[tp].name .. " is a one way teleport.[-]")
				else
					irc_chat(chatvars.ircAlias, teleports[tp].name .. " is a one way teleport.")
				end
			else
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
	end


	local function cmd_SetTeleportOwner()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}tele {name} owner {player name}"
			help[2] = "Assign ownership of a teleport to a player.  Only they and their friends can use it (and staff)"

			tmp.command = help[1]
			tmp.keywords = "tele,assign,own"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.words[1], "tele") or string.find(chatvars.command, "set tele") or string.find(chatvars.command, "owner"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (string.find(chatvars.words[1], "tele") or string.find(chatvars.command, "set tele")) and string.find(chatvars.command, "owner") then
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

			for i=1,chatvars.wordCount,1 do
				if tpname == "" then
					if string.find(chatvars.words[i], "tele") then
						tpname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[i]) + string.len(chatvars.words[i]) + 1, string.find(chatvars.command, "owner") - 1)
						tpname = string.trim(tpname)
					end
				end
			end

			tpowner = string.sub(chatvars.command, string.find(chatvars.command, "owner") + 6)
			tpowner = string.trim(tpowner)

			if tpname ~= "" and tpowner ~= "" then
				id = LookupPlayer(tpowner)

				if id == 0 then
					id = LookupArchivedPlayer(tpowner)

					if not (id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end
				end

				if (id ~= 0) then
					-- does the teleport exist?
					tp = ""
					tp = LookupTeleportByName(tpname)

					if tp == nil then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No teleport found called " .. tpname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No teleport found called " .. tpname)
						end

						botman.faultyChat = false
						return true
					end

					teleports[tp].owner = id
					conn:execute("UPDATE teleports SET owner = " .. id .. " WHERE name = '" .. escape(tp) .. "'")
					message("say [" .. server.chatColour .. "]" .. players[id].name .. " is the proud new owner of a teleport called " .. teleports[tp].name .. "[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleFetch()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable fetch"
			help[2] = "Allow or block players using the fetch command to teleport friends to them."

			tmp.command = help[1]
			tmp.keywords = "tele,able,fetch"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "able") or string.find(chatvars.command, "fetch"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "fetch" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
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

			if (chatvars.words[1] == "enable") then
				server.disableFetch = false
				conn:execute("UPDATE server SET disableFetch = 0")

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Players can use the {#}fetch command.[-]", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Players can use the {#}fetch command.")
				end
			else
				server.disableFetch = true
				conn:execute("UPDATE server SET disableFetch = 1")

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Players can not use the {#}fetch command.[-]", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Players can not use the {#}fetch command.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIndividualPlayerTeleporting()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enabletp {player name}\n"
			help[1] = help[1] .. " {#}disabletp {player name}"
			help[2] = "Allows a player to use teleport commands.  Only staff can specify a player, otherwise it defaults to whoever issued the command.\n"
			help[2] = help[2] .. "Note: Players can set/unset this on themselves too."

			tmp.command = help[1]
			tmp.keywords = "tele,able"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "tp") or string.find(chatvars.command, "able"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "enabletp" or chatvars.words[1] == "disabletp" then
			id = chatvars.playerid
			pname = igplayers[chatvars.playerid].name

			if chatvars.accessLevel < 3 and chatvars.words[2] ~= nil then
				id = LookupPlayer(string.sub(chatvars.command, string.find(chatvars.command, "abletp") + 9))

				if (id == 0) then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " ..pname .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found called " ..pname)
					end

					botman.faultyChat = false
					return true
				else
					if chatvars.words[1] == "enabletp" then
						players[id].walkies = false
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " can now use teleports.[-]")

						conn:execute("UPDATE players SET walkies = 0 WHERE steam = " .. id)
					else
						players[id].walkies = true
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " can't use teleports.[-]")

						conn:execute("UPDATE players SET walkies = 1 WHERE steam = " .. id)

					end

					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "enabletp" then
				players[id].walkies = false
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]you can use teleports.[-]")
				conn:execute("UPDATE players SET walkies = 0 WHERE steam = " .. id)
			else
				players[id].walkies = true
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]you can't use teleports.[-]")
				conn:execute("UPDATE players SET walkies = 1 WHERE steam = " .. id)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetTeleportCost()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set teleport cost {number}"
			help[2] = "Set a price for all private teleporting (excludes public locations).  Players must have sufficient " .. server.moneyPlural .. " to teleport."

			tmp.command = help[1]
			tmp.keywords = "tele,set,cost"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "tp"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
	end


	local function cmd_SetTeleportDelayTimer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set teleport delay {number}"
			help[2] = "Set a time delay for player initiated teleport commands.  The player will see a PM informing them that their teleport will happen in x seconds.  The default is 0 and no PM will be sent."

			tmp.command = help[1]
			tmp.keywords = "tele,set,cool,delay,time"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "delay") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
	end


	local function cmd_FetchPlayer()
		local r

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}fetch {player name}"
			help[2] = "Move a player to your current location (staff cannot be fetched)."

			tmp.command = help[1]
			tmp.keywords = "tele,fetch,move,tp,play"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "fetch") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "fetch") then
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
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
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
			if tonumber(chatvars.accessLevel) > 2 and server.disableFetch then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Fetching friends has been disabled on this server.[-]")
				botman.faultyChat = false
				return true
			end

			-- reject if not an admin and the player is in a location that does not allow p2p teleporting
			if tonumber(chatvars.accessLevel) > 2 then
				loc = players[chatvars.playerid].inLocation

				if locations[loc] then
					if not locations[loc].allowP2P then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in a location that does not allow fetching friends.[-]")

						r = rand(10)
						if r == 8 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]It's not a very fetching location if you ask me.[-]") end
						if r == 9 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Also I don't think you want " .. players[id].name  .. ".  I hear they don't wash.[-]") end
						if r == 10 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Well this is a bit sticky isn't it?.[-]") end

						botman.faultyChat = false
						return true
					end
				end
			end

			if (accessLevel(id) < 3) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Staff cannot be teleported by other staff.[-]")
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
			teleport(cmd, id)

			if (chatvars.accessLevel > 2) then
				players[chatvars.playerid].cash = players[chatvars.playerid].cash - server.teleportCost
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is being teleported to your location now.")
			message("pm " .. id .. " [" .. server.chatColour .. "]You are being teleported to " .. players[chatvars.playerid].name .. "'s location.")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PackTeleport()
		local loc

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}pack\n"
			help[1] = help[1] .. " {#}revive"
			help[2] = "Teleport close to where you last died."

			tmp.command = help[1]
			tmp.keywords = "tele,pack,revive,spawn"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "pack") or string.find(chatvars.command, "revive"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "pack" or chatvars.words[1] == "revive") and chatvars.words[2] == nil then
			-- reject if not an admin and server is in hardcore mode
			if (isServerHardcore(chatvars.playerid) or not server.allowPackTeleport) and chatvars.accessLevel > 2 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is disabled.[-]")
				botman.faultyChat = false
				return true
			end

			if tonumber(players[chatvars.playerid].deathX) ~= 0 then
				loc = inLocation(players[chatvars.playerid].deathX, players[chatvars.playerid].deathZ)

				if locations[loc] then
					if not locations[loc].allowPack then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You died in a location that does not allow the {#}" .. chatvars.words[1] .. " command.[-]")
						botman.faultyChat = false
						return true
					end
				end

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

				cmd = ("tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].deathX .. " " .. -1 .. " " .. players[chatvars.playerid].deathZ)

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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not died since you last revived.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_StuckTeleport()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}stuck"
			help[2] = "Teleport you to the highest ground level at your location."

			tmp.command = help[1]
			tmp.keywords = "tele,stuck"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "stuck") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "stuck" and chatvars.words[2] == nil) then
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
				if botman.dbConnected then conn:execute("insert into persistentQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReturnTeleport()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}return"
			help[2] = "Teleport back to where you came from before your last teleport command.  Locations support a 2nd return if you teleport within the location more than once without leaving it."

			tmp.command = help[1]
			tmp.keywords = "tele,tp,ret"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "return") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if ((chatvars.words[1] == "return") and chatvars.words[2] == nil) then
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

			-- reject if not an admin and pvpTeleportCooldown or returnCooldown is > zero or player is in timeout
			if tonumber(chatvars.accessLevel) > 2 then
				if (players[chatvars.playerid].timeout or players[chatvars.playerid].botTimeout) then
					message(string.format("pm %s [%s]You are in timeout.", chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end

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
					if (os.time() - igplayers[chatvars.playerid].lastTPTimestamp < 5) and (chatvars.accessLevel > 2) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport is recharging.  Wait a few seconds.  You can repeat your last command by typing " .. server.commandPrefix .."[-]")
						botman.faultyChat = false
						return true
					end

					-- the player has teleported within the same location so they are returning to somewhere in that location
					cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].xPosOld2 .. " " .. players[chatvars.playerid].yPosOld2 .. " " .. players[chatvars.playerid].zPosOld2

					if tonumber(server.playerTeleportDelay) == 0 or tonumber(chatvars.accessLevel) < 3 then --  or not igplayers[chatvars.playerid].currentLocationPVP
						teleport(cmd, chatvars.playerid)
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will return in " .. server.playerTeleportDelay .. " seconds.[-]")
						if botman.dbConnected then conn:execute("insert into persistentQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
					end

					if players[chatvars.playerid].yPos < 1000 then
						players[chatvars.playerid].xPosOld2 = 0
						players[chatvars.playerid].yPosOld2 = 0
						players[chatvars.playerid].zPosOld2 = 0

						conn:execute("UPDATE players SET xPosOld2 = 0, yPosOld2 = 0, zPosOld2 = 0 WHERE steam = " .. chatvars.playerid)
					end

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have another " .. server.commandPrefix .. "return available.[-]")
				else
					if (os.time() - igplayers[chatvars.playerid].lastTPTimestamp < 5) and (chatvars.accessLevel > 2) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport is recharging.  Wait a few seconds.  You can repeat your last command by typing " .. server.commandPrefix .."[-]")
						botman.faultyChat = false
						return true
					end

					-- the player has teleported from outside their current location so they are returning to there.
					cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].xPosOld .. " " .. players[chatvars.playerid].yPosOld .. " " .. players[chatvars.playerid].zPosOld

					if tonumber(server.playerTeleportDelay) == 0 or tonumber(chatvars.accessLevel) < 3 then --  or not igplayers[chatvars.playerid].currentLocationPVP
						teleport(cmd, chatvars.playerid)
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will return in " .. server.playerTeleportDelay .. " seconds.[-]")
						if botman.dbConnected then conn:execute("insert into persistentQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport somewhere first.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListTeleports()
		local tpOwner = ""

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}teleports"
			help[2] = "List the teleports."

			tmp.command = help[1]
			tmp.keywords = "tele,list"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "tele")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "teleports" and chatvars.words[3] == nil) then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end

			id = 0
			if (chatvars.words[2]) then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "teleports ") + 10)
				pname = string.trim(pname)
				if (pname ~= nil) then
					id = LookupPlayer(pname)

					if id == 0 then
						id = LookupArchivedPlayer(pname)

						if id ~= 0 then
							tpOwner = playersArchived[id].name
						else
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")

							botman.faultyChat = false
							return true
						end
					else
						tpOwner = players[id].name
					end
				end
			end

			for k, v in pairs(teleports) do
				if (v.public == true) then
					public = "public"
				else
					public = "private"
				end

				if (id == 0) then
					-- list all the teleports
					if players[v.owner] then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " " .. public .. " owned by " .. players[v.owner].name .. "[-]")
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " " .. public .. " owned by " .. playersArchived[v.owner].name .. "[-]")
					end
				else
					-- only list teleports owned by the specified player
					if (v.owner == id) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " " .. public .. " owned by " .. tpOwner .. "[-]")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetTeleportStartSize()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}tele {name} start size {radius in blocks}"
			help[2] = "Set the size of the starting point of a pair of teleports.  The default is 3 wide (1.5 radius)"

			tmp.command = help[1]
			tmp.keywords = "tele,size,set,tp,portal"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "start") or string.find(chatvars.command, "size"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport " .. teleName .. "'s start width is " .. teleSize * 2 .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetTeleportEndSize()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}tele {name} end size {radius in blocks}"
			help[2] = "Set the size of the exit point of a pair of teleports.  The default is 3 wide (1.5 radius)"

			tmp.command = help[1]
			tmp.keywords = "tele,size,set,tp,portal"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "end") or string.find(chatvars.command, "size"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
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
	end


	local function cmd_SetTeleportPlayerAccessLevelRestriction()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}tele {name} access min {minimum access level} max {maximum access level}\n"
			help[1] = help[1] .. " {#}tele {name} access min {minimum access level}\n"
			help[1] = help[1] .. " {#}tele {name} access max {maximum access level}"
			help[2] = "Set a player access level requirement to activate a teleport.\n"
			help[2] = help[2] .. "Teleports are not access level restricted by default and the min and max are both 0.  Set them to 0 to remove an access restriction.\n"
			help[2] = help[2] .. "Note: Access levels are not player levels. See {#}help access\n"
			help[2] = help[2] .. "eg. To limit to donors {#}tele test access min 10.  No need to set max as only admins are higher.\n"
			help[2] = help[2] .. "eg. To limit to new players {#}tele newbies access min 99 max 99."

			tmp.command = help[1]
			tmp.keywords = "tele,size,set,tp,portal"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "acc") or string.find(chatvars.command, "lev"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.command, "tele ") and string.find(chatvars.command, "access") then
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

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number (0 - 99) required for min or max.[-]")
				else
					irc_chat(chatvars.ircAlias, "Number (0 - 99) required for min or max.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.numbers[1] ~= nil then
				if chatvars.numbers[1] < 0 or chatvars.numbers[1] > 99 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number out of range. Valid numbers are from 0 to 99.[-]")
					else
						irc_chat(chatvars.ircAlias, "Number out of range. Valid numbers are from 0 to 99.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if chatvars.numbers[2] ~= nil then
				if chatvars.numbers[2] < 0 or chatvars.numbers[2] > 99 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number out of range. Valid numbers are from 0 to 99.[-]")
					else
						irc_chat(chatvars.ircAlias, "Number out of range. Valid numbers are from 0 to 99.")
					end

					botman.faultyChat = false
					return true
				end
			end

			tmp.teleportName = chatvars.words[2]
			tmp.tp = LookupTeleportByName(tmp.teleportName)

			if tmp.tp == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That teleport does not exist.[-]")
				else
					irc_chat(chatvars.ircAlias, "That teleport does not exist.")
				end

				botman.faultyChat = false
				return true
			end

			if tmp.tp ~= nil then
				tmp.minimumAccess = teleports[tmp.tp].minimumAccess
				tmp.maximumAccess = teleports[tmp.tp].maximumAccess

				if string.find(chatvars.command, "min ") and string.find(chatvars.command, "max ") then
					tmp.minimumAccess = chatvars.numbers[1]
					tmp.maximumAccess = chatvars.numbers[2]
				else
					if string.find(chatvars.command, "min ") then
						tmp.minimumAccess = chatvars.numbers[1]
					end

					if string.find(chatvars.command, "max ") then
						tmp.maximumAccess = chatvars.numbers[1]
					end
				end

				-- flip if max < min and max not zero
				if tmp.minimumAccess > tmp.maximumAccess and tmp.maximumAccess > 0 then
					tmp.temp = tmp.maximumAccess
					tmp.maximumAccess = tmp.minimumAccess
					tmp.minimumAccess = tmp.temp
				end

				-- update the access levels for the teleport
				conn:execute("UPDATE teleports set minimumAccess = " .. tmp.minimumAccess .. ", maximumAccess = " .. tmp.maximumAccess .. " WHERE name = '" .. escape(tmp.teleportName) .. "'")
				teleports[tmp.tp].minimumAccess = tmp.minimumAccess
				teleports[tmp.tp].maximumAccess = tmp.maximumAccess

				if tmp.minimumAccess == 0 and tmp.maximumAccess == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The teleport " .. tmp.tp .. " is not restricted by access level.[-]")
					else
						irc_chat(chatvars.ircAlias, "The teleport " .. tmp.tp .. " is not restricted by access level.")
					end

					botman.faultyChat = false
					return true
				end

				if tmp.minimumAccess > 0 then
					if tmp.maximumAccess > 0 then
						if tmp.minimumAccess == tmp.maximumAccess then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The teleport " .. tmp.tp .. " is restricted to players with an access level of " .. tmp.minimumAccess .. ".[-]")
							else
								irc_chat(chatvars.ircAlias, "The teleport " .. tmp.tp .. " is restricted to players with an access level of " .. tmp.minimumAccess)
							end
						else
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The teleport " .. tmp.tp .. " is restricted to players with access levels from " .. tmp.minimumAccess .. " to " .. tmp.maximumAccess .. ".[-]")
							else
								irc_chat(chatvars.ircAlias, "The teleport " .. tmp.tp .. " is restricted to players with access levels from " .. tmp.minimumAccess .. " to " .. tmp.maximumAccess)
							end
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The teleport " .. tmp.tp .. " is restricted to players with access levels from " .. tmp.minimumAccess .. " and above.[-]")
						else
							irc_chat(chatvars.ircAlias, "The teleport " .. tmp.tp .. " is restricted to players with access levels from " .. tmp.minimumAccess .. " and above.")
						end
					end

					botman.faultyChat = false
					return true
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_CreateTeleportStart()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}tele {name} start"
			help[2] = "Create a teleport starting at your location or move an existing teleport's start to you."

			tmp.command = help[1]
			tmp.keywords = "tele,start,crea,tp,portal"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "start") or string.find(chatvars.command, "opentp"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (string.find(chatvars.words[1], "tele") and (string.find(chatvars.command, "start") or string.find(chatvars.command, "open")) or string.find(chatvars.command, "opentp")) and not string.find(chatvars.command, "size") then
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

			if string.find(chatvars.command, "opentp") then
				teleName = string.sub(chatvars.command, string.find(chatvars.command, "opentp ") + 7)
			else
				if string.find(chatvars.command, "start") then
					teleName = string.sub(chatvars.command, string.find(chatvars.command, "tele ") + 5, string.find(chatvars.command, " start"))
				else
					teleName = string.sub(chatvars.command, string.find(chatvars.command, "tele ") + 5, string.find(chatvars.command, " open"))
				end
			end

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
				teleports[teleName].minimumAccess = 99
				teleports[teleName].maximumAccess = 0

				conn:execute("INSERT INTO teleports (name, owner, x, y, z, minimumAccess, maximumAccess) VALUES ('" .. teleName .. "'," .. chatvars.playerid .. "," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ", 99, 0)")
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
	end


	local function cmd_CreateTeleportEnd()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}tele {name} end"
			help[2] = "Complete a teleport ending at your location or move an existing teleport's end to you."

			tmp.command = help[1]
			tmp.keywords = "tele,end,crea,tp,portal"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "end") or string.find(chatvars.command, "closetp"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (string.find(chatvars.words[1], "tele") and (string.find(chatvars.command, "end") or string.find(chatvars.command, "close")) or string.find(chatvars.command, "closetp")) and not string.find(chatvars.command, "size") then
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

			if string.find(chatvars.command, "closetp") then
				teleName = string.sub(chatvars.command, string.find(chatvars.command, "closetp ") + 8)
			else
				if string.find(chatvars.command, "close") then
					teleName = string.sub(chatvars.command, string.find(chatvars.command, "tele ") + 5, string.find(chatvars.command, " close"))
				else
					teleName = string.sub(chatvars.command, string.find(chatvars.command, "tele ") + 5, string.find(chatvars.command, " end"))
				end
			end

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
				teleports[teleName].minimumAccess = 99
				teleports[teleName].maximumAccess = 0

				conn:execute("INSERT INTO teleports (name, owner, dx, dy, dz, minimumAccess, maximumAccess) VALUES ('" .. teleName .. "'," .. chatvars.playerid .. "," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ", 99, 0)")
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
	end


	local function cmd_AdminTeleport()
		local temp, x, z

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}tp {player name}\n"
			help[1] = help[1] ..  " {#}tp {name of teleport}\n"
			help[1] = help[1] .. " {#}tp {X coord} {Y coord} {Z coord}\n"
			help[1] = help[1] .. " {#}tp region {region X} {region Z} (tp's you to the centre of the region)\n"
			help[1] = help[1] .. " {#}tp #1 (tele to the coords of a line in a numbered list eg. from {#}list saves)\n"
			help[1] = help[1] .. " {#}north/south/east/west {distance}"
			help[2] = "Teleport yourself to a player, a coordinate, a named teleport, or a distance in a compass direction (north, south, east or west)."

			tmp.command = help[1]
			tmp.keywords = "tele,tp,coord,player,dir"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (chatvars.words[1] == "tp" or chatvars.words[1] == "tele")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "tp" then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end

			-- tp north, south, east, west {distance}
			if (chatvars.words[2] == "north" or chatvars.words[2] == "south" or chatvars.words[2] == "east" or chatvars.words[2] == "west") then
				-- first record their current x y z
				savePosition(chatvars.playerid)

				if chatvars.number == nil then
					chatvars.number = 50
				end

				if chatvars.words[2] == "north" then
					cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].xPos .. " " .. players[chatvars.playerid].yPos .. " " .. players[chatvars.playerid].zPos + chatvars.number
				end

				if chatvars.words[2] == "south" then
					cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].xPos .. " " .. players[chatvars.playerid].yPos .. " " .. players[chatvars.playerid].zPos - chatvars.number
				end

				if chatvars.words[2] == "west" then
					cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].xPos - chatvars.number .. " " .. players[chatvars.playerid].yPos .. " " .. players[chatvars.playerid].zPos
				end

				if chatvars.words[2] == "east" then
					cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].xPos + chatvars.number .. " " .. players[chatvars.playerid].yPos .. " " .. players[chatvars.playerid].zPos
				end

				teleport(cmd, chatvars.playerid)

				botman.faultyChat = false
				return true
			end

			-- tp to numbered line in a list
			if string.find(chatvars.words[2], "#") and chatvars.words[3] == nil and string.len(chatvars.words[2]) < 4 then
				-- this is most likely from a numbered list and the admin wants to go to its coordinates

				temp = string.match(chatvars.words[2], "#(%d+)")
				cursor,errorString = conn:execute("select * from list where id = " .. temp)
				row = cursor:fetch({}, "a")

				if row then
					temp = string.split(row.class, " ")

					-- first record their current x y z
					savePosition(chatvars.playerid)

					cmd = "tele " .. chatvars.playerid .. " " .. temp[1] .. " " .. temp[2] .. " " .. temp[3]
					teleport(cmd, chatvars.playerid)
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == "region" then
				x = math.floor(chatvars.words[3])
				z = math.floor(chatvars.words[4])

				x = (x * 512) + 256
				z = (z * 512) + 256

				cmd = "tele " .. chatvars.playerid .. " " .. x .. " -1 " .. z
				teleport(cmd, chatvars.playerid)

				botman.faultyChat = false
				return true
			end

			-- tp to x y z coord
			if chatvars.words[4] ~= nil then
				-- first record their current x y z
				savePosition(chatvars.playerid)

				cmd = "tele " .. chatvars.playerid .. " " .. math.floor(chatvars.words[2]) .. " " .. math.floor(chatvars.words[3]) .. " " .. math.floor(chatvars.words[4])
				teleport(cmd, chatvars.playerid)

				botman.faultyChat = false
				return true
			end

			-- tp to a named teleport or a player
			teleName = ""

			if chatvars.words[1] == "tp" then
				teleName = string.sub(chatvars.command, string.find(chatvars.command, "tp ") + 3)
			end

			if chatvars.words[1] == "tele" then
				teleName = string.sub(chatvars.command, string.find(chatvars.command, "tele ") + 5)
			end

			teleName = string.trim(teleName)

			if (teleName == "") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the " .. server.commandPrefix .. "tp command[-]")
				botman.faultyChat = false
				return true
			else
				tp = LookupTeleportByName(teleName)

				-- tp to a location
				if tp ~= nil then
					-- first record their current x y z
					savePosition(chatvars.playerid)

					cmd = "tele " .. chatvars.playerid .. " " .. teleports[tp].x .. " " .. teleports[tp].y .. " " .. teleports[tp].z
					teleport(cmd, chatvars.playerid)
					igplayers[chatvars.playerid].teleCooldown = 5

					if teleports[tp].active then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is the teleport called " .. tp .. ".  It will teleport you shortly if you do not move.[-]")
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is the teleport called " .. tp .. ".  It is disabled and will not activate.[-]")
					end

					botman.faultyChat = false
					return true
				end

				tp = LookupPlayer(teleName)

				if tp == 0 then
					tp = LookupArchivedPlayer(teleName)

					-- tp to an archived player
					if tp ~= 0 then
						-- first record their current x y z
						savePosition(chatvars.playerid)

						cmd = "tele " .. chatvars.playerid .. " " .. playersArchived[tp].xPos .. " " .. playersArchived[tp].yPos .. " " .. playersArchived[tp].zPos
						teleport(cmd, chatvars.playerid)

						if playersArchived[tp].xPos ~= 0 and playersArchived[tp].yPos ~= 0 and playersArchived[tp].zPos ~= 0 then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tp].name .. " was archived.  This is their last recorded position.[-]")
						end

						botman.faultyChat = false
						return true
					end
				end

				-- tp to a player
				if tp ~= 0 then
					-- first record their current x y z
					savePosition(chatvars.playerid)

					cmd = "tele " .. chatvars.playerid .. " " .. players[tp].xPos .. " " .. players[tp].yPos .. " " .. players[tp].zPos
					teleport(cmd, chatvars.playerid)

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is the last recorded position of " .. players[tp].name .. "[-]")

					botman.faultyChat = false
					return true
				end
			end
		end
	end


	local function cmd_TogglePlayerTeleportAnnouncements()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}show/hide teleports"
			help[2] = "If bot commands are hidden from chat, you can have the bot announce whenever a player teleports to a location (except {#}home)."

			tmp.command = help[1]
			tmp.keywords = "tele,show,hide"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, " tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "show" or chatvars.words[1] == "hide") and string.find(chatvars.words[2], "teleports") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "show" then
				server.announceTeleports = true
				conn:execute("UPDATE server SET announceTeleports = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player teleporting to locations will be announced in chat.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player teleporting to locations will be announced in chat.")
				end
			else
				server.announceTeleports = false
				conn:execute("UPDATE server SET announceTeleports = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player teleporting will not be publicly announced.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player teleporting will not be publicly announced.")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetPackCost()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set pack cost {number}"
			help[2] = "By default players can type {#}pack or {#}revive when they respawn after a death to return to close to their pack.  You can set a delay and/or a cost before the command is available after a death."

			tmp.command = help[1]
			tmp.keywords = "tele,set,cost,pack,revive"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pack") or string.find(chatvars.command, "cost") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "pack" and chatvars.words[3] == "cost" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.packCost = chatvars.number
				conn:execute("UPDATE server SET packCost = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					if server.packCost == 0 then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can teleport back to their pack for free.[-]")
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]After death a player must have at least " .. server.packCost .. " " .. server.moneyPlural .. " before they can use " .. server.commandPrefix .. "pack.[-]")
					end
				else
					if server.packCost == 0 then
						irc_chat(chatvars.ircAlias, "Players can teleport back to their pack for free.")
					else
						irc_chat(chatvars.ircAlias, "After death a player must have at least " .. server.packCost .. " " .. server.moneyPlural .. " before they can use " .. server.commandPrefix .. "pack.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetPackCooldownTimer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set pack cooldown {number in seconds}"
			help[2] = "By default players can type {#}pack when they respawn after a death to return to close to their pack.  You can set a delay and/or a cost before the command is available after a death."

			tmp.command = help[1]
			tmp.keywords = "tele,set,cool,delay,time,pack,revive"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pack") or string.find(chatvars.command, "time") or string.find(chatvars.command, "cool"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "pack" and chatvars.words[3] == "cooldown" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.packCooldown = chatvars.number
				conn:execute("UPDATE server SET packCooldown = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]After death a player must wait " .. chatvars.number .. " seconds before they can use " .. server.commandPrefix .. "pack.[-]")
				else
					irc_chat(chatvars.ircAlias, "After death a player must wait " .. chatvars.number .. " seconds before they can use " .. server.commandPrefix .. "pack.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetP2PMinimumAccess()
		local temp

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set p2p access {access level}"
			help[2] = "Restrict the {#}visit command to players at and above a bot access level.\n"
			help[2] = help[2] .. "Levels are 99 (everyone), 90 (everyone except new players), 10 (donors), 2 (mods), 1 (admins), 0 (owners)."

			tmp.command = help[1]
			tmp.keywords = "tele,set,p2p,access,level,min"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "p2p") or string.find(chatvars.command, "visit") or string.find(chatvars.command, "level"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "p2p" and chatvars.words[3] == "access" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.p2pMinimumAccess = chatvars.number
				conn:execute("UPDATE server SET p2pMinimumAccess = " .. chatvars.number)

				temp = ""

				if chatvars.number == 99 then
					temp = "Anyone can use the {#}visit command."
				end

				if chatvars.number == 90 then
					temp = "Only new players cannot use the {#}visit command."
				end

				if chatvars.number == 10 then
					temp = "The {#}visit command is restricted to donors and admins."
				end

				if chatvars.number == 2 then
					temp = "The {#}visit command is restricted to admins."
				end

				if chatvars.number == 1 then
					temp = "Only admins and owners can use the {#}visit command."
				end

				if chatvars.number == 0 then
					temp = "Only owners can use the {#}visit command."
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. temp .. "[-]")
				else
					irc_chat(chatvars.ircAlias, temp)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetP2PCooldownTimer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set p2p cooldown {number in seconds}"
			help[2] = "Set a cooldown after players teleport to friends before they can teleport to friends again.  Default is 0."

			tmp.command = help[1]
			tmp.keywords = "tele,set,cool,delay,time,p2p"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "p2p") or string.find(chatvars.command, "time") or string.find(chatvars.command, "cool"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "p2p" and chatvars.words[3] == "cooldown" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.p2pCooldown = chatvars.number
				conn:execute("UPDATE server SET p2pCooldown = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]After teleporting to a friend a player must wait " .. chatvars.number .. " seconds before they can teleport to a friend again.[-]")
				else
					irc_chat(chatvars.ircAlias, "After teleporting to a friend a player must wait " .. chatvars.number .. " seconds before they can teleport to a friend again.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleP2PTeleporting()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable p2p"
			help[2] = "Allow or block players teleporting to other players via shared waypoints or teleporting to friends."

			tmp.command = help[1]
			tmp.keywords = "tele,able,p2p,player,tp"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "able") or string.find(chatvars.command, "p2p"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "p2p" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.words[1] == "enable") then
				server.allowPlayerToPlayerTeleporting = true
				conn:execute("UPDATE server SET allowPlayerToPlayerTeleporting = 1")

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Players can teleport to friends.[-]", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Players can teleport to friends.")
				end
			else
				server.allowPlayerToPlayerTeleporting = false
				conn:execute("UPDATE server SET allowPlayerToPlayerTeleporting = 0")

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Players can not teleport to friends.[-]", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Players can not teleport to friends.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TogglePlayerTeleporting()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable teleporting"
			help[2] = "Toggle ability of players using teleport commands. Admins can still teleport."

			tmp.command = help[1]
			tmp.keywords = "tele,able,player,tp"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "able") or string.find(chatvars.command, "allow") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "allow" or chatvars.words[1] == "disable" or chatvars.words[1] == "disallow") and chatvars.words[2] == "teleporting" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "enable" or chatvars.words[1] == "allow" then
				server.allowTeleporting = true
				conn:execute("UPDATE server SET allowTeleporting = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can use teleport commands.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can use teleport commands.")
				end
			else
				server.allowTeleporting = false
				conn:execute("UPDATE server SET allowTeleporting = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will not be able to use teleport commands.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will not be able to use teleport commands.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleReturnCommand()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable return (enabled is default)"
			help[2] = "After being teleported somewhere, players can type {#}return to be sent back to where they came from.\n"
			help[2] = help[2] .. "This is enabled by default but you can disable them.  Admins are not affected by this setting."

			tmp.command = help[1]
			tmp.keywords = "tele,able,retu"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "able") or string.find(chatvars.command, "return"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "return" and chatvars.words[3] == nil then
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

			if chatvars.words[1] == "enable" then
				server.allowReturns = true
				conn:execute("UPDATE server SET allowReturns = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Players can return after being teleported by typing " .. server.commandPrefix .. "return.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can return after being teleported by typing " .. server.commandPrefix .. "return.")
				end
			else
				server.allowReturns = false
				conn:execute("UPDATE server SET allowReturns = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]The " .. server.commandPrefix .. "return command is disabled for players.[-]")
				else
					irc_chat(chatvars.ircAlias, "The " .. server.commandPrefix .. "return command is disabled for players.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleStuckTeleport()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable stuck"
			help[2] = "Enable or disable the {#}stuck command. Default is enabled."

			tmp.command = help[1]
			tmp.keywords = "tele,able,stuck,tp"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "stuck") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "stuck" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.words[1] == "enable") then
				server.allowStuckTeleport = true
				if botman.dbConnected then conn:execute("UPDATE server SET allowStuckTeleport=1") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Players can use the %sstuck command.", chatvars.playerid, server.chatColour, server.commandPrefix))
				else
					irc_chat(chatvars.ircAlias, "Players can use the " .. server.commandPrefix .. "stuck command.")
				end
			else
				server.allowStuckTeleport = false
				if botman.dbConnected then conn:execute("UPDATE server SET allowStuckTeleport=0") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Players cannot use the %sstuck command.", chatvars.playerid, server.chatColour, server.commandPrefix))
				else
					irc_chat(chatvars.ircAlias, "Players cannot use the " .. server.commandPrefix .. "stuck command.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ViewTeleport()
		local playerName

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}view teleport {named teleport}"
			help[2] = "View all the settings of a teleport."

			tmp.command = help[1]
			tmp.keywords = "tele,view,info"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "tele")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "view" and string.find(chatvars.words[2], "tele") and chatvars.words[3] ~= nil) then
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

			tmp = {}

			if (chatvars.words[3] ~= nil) then
				tmp.name = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[3]))
				tmp.name = string.trim(tmp.name)
				tmp.tp = LookupTeleportByName(tmp.name)

				if (tmp.tp == nil) then
					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]No teleport found called %s", chatvars.playerid, server.chatColour, tmp.name))
					else
						irc_chat(chatvars.ircAlias, "No teleport found called " .. tmp.name)
					end

					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Teleport name required.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Teleport name required.")
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message(string.format("pm %s [%s]Teleport: %s", chatvars.playerid, server.chatColour, tmp.tp))
			else
				irc_chat(chatvars.ircAlias, "Teleport " .. tmp.tp)
				irc_chat(chatvars.ircAlias, ".")
			end

			for k,v in pairs(teleports[tmp.tp]) do
				if (chatvars.playername ~= "Server") then
					if k ~= "owner" then
						message(string.format("pm %s [%s]%s , %s", chatvars.playerid, server.chatColour, k, tostring(v)))
					else
						if players[v] then
							playerName = players[v].name
						else
							playerName = playersArchived[v].name
						end

						message(string.format("pm %s [%s]%s , %s   %s", chatvars.playerid, server.chatColour, k, tostring(v), playerName))
					end
				else
					if k ~= "owner" then
						irc_chat(chatvars.ircAlias, k .. " , " .. tostring(v))
					else
						if players[v] then
							playerName = players[v].name
						else
							playerName = playersArchived[v].name
						end

						irc_chat(chatvars.ircAlias, k .. " , " .. tostring(v) .. "  " .. playerName)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_VisitPlayer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}visit {player name}"
			help[1] = help[1] .. " {#}goto {player name}"
			help[2] = "Teleport to another player.  If the server rules allow, you can teleport to a friend.  Various rules and cooldowns may block you."

			tmp.command = help[1]
			tmp.keywords = "tele,visit,goto"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "visit") or string.find(chatvars.command, "goto"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "visit" or chatvars.words[1] == "goto") and chatvars.words[2] ~= nil then
			pname = nil
			pname = string.sub(chatvars.command, string.len(chatvars.words[1]) + 2)
			pname = string.trim(pname)

			id = LookupPlayer(pname)

			if (players[chatvars.playerid].prisoner or not players[chatvars.playerid].canTeleport) then
				botman.faultyChat = false
				return true
			end

			if (id ~= 0) then
				-- reject if not an admin and server is in hardcore mode
				if isServerHardcore(chatvars.playerid) then
					message("pm " .. playerid .. " [" .. server.chatColour .. "]This command is disabled.[-]")
					botman.faultyChat = false
					return true
				end

				-- reject if not an admin and player teleporting has been disabled
				if tonumber(chatvars.accessLevel) > 2 and not server.allowTeleporting then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting has been disabled on this server.[-]")
					botman.faultyChat = false
					return true
				end

				-- reject if not an admin and player to player teleporting has been disabled
				if tonumber(chatvars.accessLevel) > 2 and not server.allowPlayerToPlayerTeleporting then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting to friends has been disabled on this server.[-]")
					botman.faultyChat = false
					return true
				end

				-- reject if server.p2pMinimumAccess is less than the player's access level
				if tonumber(chatvars.accessLevel) > tonumber(server.p2pMinimumAccess) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is not available to you.[-]")
					botman.faultyChat = false
					return true
				end

				-- reject if not an admin and the p2p target player is in a location that does not allow p2p teleports
				if tonumber(chatvars.accessLevel) > 2 then
					loc = players[id].inLocation

					if locations[loc] then
						if not locations[loc].allowP2P then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your friend is in a location that does not allow p2p teleporting.[-]")
							botman.faultyChat = false
							return true
						end
					end
				end

				-- reject if not an admin and p2pCooldown is non-zero and in the future
				if tonumber(chatvars.accessLevel) > 2 and (players[chatvars.playerid].p2pCooldown - os.time() > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You must wait " .. players[chatvars.playerid].p2pCooldown - os.time() .. " seconds before you can teleport to friends again.[-]")
					botman.faultyChat = false
					return true
				end

				-- reject if not an admin or a friend
				if (not isFriend(id,  chatvars.playerid)) and (chatvars.accessLevel > 2) and (id ~= chatvars.playerid) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only friends of " .. players[id].name .. " and staff can do this.[-]")
					botman.faultyChat = false
					return true
				end

				if pvpZone(players[id].xPos, players[id].zPos) and chatvars.accessLevel > 2 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not allowed to teleport to players in PVP zones.[-]")
					botman.faultyChat = false
					result = true
					return true
				end

				if not igplayers[id] and chatvars.accessLevel > 2 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is offline at the moment.  You will have to wait till they return or start walking.[-]")
					botman.faultyChat = false
					return true
				end

				if players[id].xPos == 0 and players[id].yPos == 0 and players[id].zPos == 0 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has not played here since the last map wipe.[-]")
					botman.faultyChat = false
					return true
				end

				-- teleport to a friend if sufficient zennies
				if tonumber(server.teleportCost) > 0 and (chatvars.accessLevel > 2) then
					if tonumber(players[chatvars.playerid].cash) < tonumber(server.teleportCost) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. ".  Kill some zombies, gamble, trade or beg to earn more.[-]")
						botman.faultyChat = false
						return true
					end
				end

				if (os.time() - igplayers[chatvars.playerid].lastTPTimestamp < 5) and (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport is recharging.  Wait a few seconds.  You can repeat your last command by typing " .. server.commandPrefix .."[-]")
					botman.faultyChat = false
					return true
				end

				-- first record the current x y z
				players[chatvars.playerid].xPosOld = chatvars.intX
				players[chatvars.playerid].yPosOld = chatvars.intY
				players[chatvars.playerid].zPosOld = chatvars.intZ
				igplayers[chatvars.playerid].lastLocation = ""

				-- then teleport to the friend
				cmd = "tele " .. chatvars.playerid .. " " .. players[id].xPos .. " " .. players[id].yPos .. " " .. players[id].zPos

				if tonumber(server.p2pCooldown) > 0 then
					players[chatvars.playerid].p2pCooldown = os.time() + server.p2pCooldown
					conn:execute("UPDATE players SET p2pCooldown = " .. players[chatvars.playerid].p2pCooldown .. " WHERE steam = " .. chatvars.playerid)
				end

				if tonumber(server.teleportCost) > 0 and (chatvars.accessLevel > 2) then
					players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - server.teleportCost
				end

				if tonumber(server.playerTeleportDelay) == 0 or not igplayers[chatvars.playerid].currentLocationPVP or tonumber(players[chatvars.playerid].accessLevel) < 2 then
					if teleport(cmd, chatvars.playerid) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have teleported to " .. players[id].name .. "'s location.[-]")
					end
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will be teleported to " .. players[id].name .. "'s location in " .. server.playerTeleportDelay .. " seconds.[-]")
					if botman.dbConnected then conn:execute("insert into persistentQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
					igplayers[chatvars.playerid].lastTPTimestamp = os.time() -- this won't really stop additional tp commands stacking but it will slow the player down a little.
				end

				botman.faultyChat = false
				return true
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. ".[-]")

				botman.faultyChat = false
				return true
			end
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - teleport commands ====")
		if debug then dbug("Registering help - teleport commands") end

		tmp.topicDescription = "Teleports are coordinates in the game world that can trigger when a player's position is within a preset range to teleport the player somewhere else.\n"
		tmp.topicDescription = tmp.topicDescription .. "A teleport's behaviour can be altered by changing its properties.\n"
		tmp.topicDescription = tmp.topicDescription .. "Also included here are commands to configure other teleporting settings and some other teleport commands."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'teleports'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('teleports', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

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

	result = cmd_DeleteTeleport()

	if result then
		if debug then dbug("debug cmd_DeleteTeleport triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleFetch()

	if result then
		if debug then dbug("debug cmd_ToggleFetch triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIndividualPlayerTeleporting()

	if result then
		if debug then dbug("debug cmd_ToggleIndividualPlayerTeleporting triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleTeleportEnabled()

	if result then
		if debug then dbug("debug cmd_ToggleTeleportEnabled triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleTeleportOneWay()

	if result then
		if debug then dbug("debug cmd_ToggleTeleportOneWay triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleTeleportPublic()

	if result then
		if debug then dbug("debug cmd_ToggleTeleportPublic triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetTeleportOwner()

	if result then
		if debug then dbug("debug cmd_SetTeleportOwner triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetTeleportCost()

	if result then
		if debug then dbug("debug cmd_SetTeleportCost triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetTeleportDelayTimer()

	if result then
		if debug then dbug("debug cmd_SetTeleportDelayTimer triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetTeleportPlayerAccessLevelRestriction()

	if result then
		if debug then dbug("debug cmd_SetTeleportPlayerAccessLevelRestriction triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleP2PTeleporting()

	if result then
		if debug then dbug("debug cmd_ToggleP2PTeleporting triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_TogglePlayerTeleportAnnouncements()

	if result then
		if debug then dbug("debug cmd_TogglePlayerTeleportAnnouncements triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_TogglePlayerTeleporting()

	if result then
		if debug then dbug("debug cmd_TogglePlayerTeleporting triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleReturnCommand()

	if result then
		if debug then dbug("debug cmd_ToggleReturnCommand triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleStuckTeleport()

	if result then
		if debug then dbug("debug cmd_ToggleStuckTeleport triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetPackCooldownTimer()

	if result then
		if debug then dbug("debug cmd_SetPackCooldownTimer triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetPackCost()

	if result then
		if debug then dbug("debug cmd_SetPackCost triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetP2PMinimumAccess()

	if result then
		if debug then dbug("debug cmd_SetP2PMinimumAccess triggered") end
		return result
	end

	if debug then dbug("debug teleports end of remote commands") end

	result = cmd_SetP2PCooldownTimer()

	if result then
		if debug then dbug("debug cmd_SetP2PCooldownTimer triggered") end
		return result
	end

	if debug then dbug("debug teleports end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == 0 and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Teleport In-Game Only:")
		irc_chat(chatvars.ircAlias, "======================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_AdminTeleport()

	if result then
		if debug then dbug("debug cmd_AdminTeleport triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_CreateTeleportEnd()

	if result then
		if debug then dbug("debug cmd_CreateTeleportEnd triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_CreateTeleportStart()

	if result then
		if debug then dbug("debug cmd_CreateTeleportStart triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_FetchPlayer()

	if result then
		if debug then dbug("debug cmd_FetchPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListTeleports()

	if result then
		if debug then dbug("debug cmd_ListTeleports triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_PackTeleport()

	if result then
		if debug then dbug("debug cmd_PackTeleport triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReturnTeleport()

	if result then
		if debug then dbug("debug cmd_ReturnTeleport triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetTeleportEndSize()

	if result then
		if debug then dbug("debug cmd_SetTeleportEndSize triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetTeleportStartSize()

	if result then
		if debug then dbug("debug cmd_SetTeleportStartSize triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_StuckTeleport()

	if result then
		if debug then dbug("debug cmd_StuckTeleport triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_ViewTeleport()

	if result then
		if debug then dbug("debug cmd_ViewTeleport triggered") end
		return result
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	result = cmd_VisitPlayer()

	if result then
		if debug then dbug("debug cmd_VisitPlayer triggered") end
		return result
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Teleport commands help registered ****")
		if debug then dbug("Teleport commands help registered") end
		topicID = topicID + 1
	end

	if debug then dbug("teleports end") end

	-- can't touch dis
	if true then
		return result
	end
end
