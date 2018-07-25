--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local shortHelp = false
local skipHelp = false
local tmp = {}
local debug, result

debug = false -- should be false unless testing

function gmsg_djkrose()
	calledFunction = "gmsg_djkrose"
	result = false

	if botman.debugAll then
		debug = true -- this should be true
	end

	-- NEW STUFF!   SQUEEEEEEEE!

-- ################## djkrose command functions ##################

	local function cmd_ExportPrefab()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}export {named area}"
			help[2] = "This command requires that you have previously marked out an area to be exported using the {#}mark command.\n"
			help[2] = help[2] .. "Everything within the marked area will be saved as a prefab file including he contents of all containers and ownership."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "export,prefab,script"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "port") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "script"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "export" and chatvars.words[2] ~= "" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			if not prefabCopies[chatvars.playerid .. chatvars.words[2]] then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You haven't marked a prefab called " .. chatvars.words[2] .. ". Please do that first.[-]")
			else
				send("dj-export " .. chatvars.playerid .. chatvars.words[2] .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].z2)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You saved a prefab called " .. chatvars.words[2] .. ".[-]")
			end

			botman.faultyChat = false
			return true
		end
	end

	if (debug) then dbug("debug djkrose line " .. debugger.getinfo(1).currentline) end

	local function cmd_ImportPrefab()
		local prefix, suffix

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}import {named area}\n"
			help[1] = help[1] .. "Optional extras: replace, empty, face {0-3}"
			help[2] = help[2] .. "This command requires that you have previously marked out an area to be exported using the {#}mark command.\n"
			help[2] = help[2] .. "You can rotate the prefab with face. 0 = unmodified 1 = 90° right 2 = 180° right 3 = 270° right.\n"
			help[2] = help[2] .. "Add 'replace' if you want to replace the original prefab or it will spawn at your current position and elevation.\n"
			help[2] = help[2] .. "Add 'empty' if you don't want to restore the contents of containers.  Note: Currently this only works if the container has been destroyed."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "import,prefab,script"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "port") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "script"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "import" and chatvars.words[2] ~= "" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			tmp.x = chatvars.intX
			tmp.y = chatvars.intY - 1
			tmp.z = chatvars.intZ
			tmp.replace = false
			tmp.face = 0
			tmp.noContents = false
			tmp.prefab = chatvars.playerid .. chatvars.words[2]

			if not prefabCopies[tmp.prefab] then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You haven't marked a prefab called " .. chatvars.words[2] .. ". Please do that first.[-]")
			else
				for i=2,chatvars.wordCount,1 do
					if chatvars.words[i] == "replace" then
						tmp.replace = true
						tmp.x = prefabCopies[tmp.prefab].x1
						tmp.y = prefabCopies[tmp.prefab].y1
						tmp.z = prefabCopies[tmp.prefab].z1

						-- if Coppi's mod is installed, first replace the prefab with air blocks so the import is flawless.
						if server.coppi then
							if server.coppiRelease == "Mod Coppis command additions Light" or tonumber(server.coppiVersion) > 4.4 then
								prefix = "cp-"
								suffix = ""
							else
								prefix = ""
								suffix = " 0"
							end

							send(prefix .. "pblock air " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].z2 .. suffix)
						end
					end

					if chatvars.words[i] == "rotate" or chatvars.words[i] == "face" then
						tmp.face = chatvars.words[i+1]
					end

					if chatvars.words[i] == "empty" then
						tmp.noContents = true
					end
				end

				if tmp.noContents then
					send("dj-import " .. tmp.prefab .. " " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " " .. tmp.face)
				else
					send("dj-import " .. tmp.prefab .. " /all " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z .. " " .. tmp.face)
				end

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The saved prefab called " .. chatvars.words[2] .. " has been imported.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end

	if (debug) then dbug("debug djkrose line " .. debugger.getinfo(1).currentline) end

	local function cmd_RegenChunk()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}regen {optional distance} (max 30)"
			help[2] = "Regenerate the chunk you are standing in and surrounding chunks if you specify a distance.\n"
			help[2] = help[2] .. "Note: The console command used, dj-regen calculates the chunks so if it doesn't regenerate a small part, just move to the effected area and repeat the command."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "regen,chunk,script"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "regen") or string.find(chatvars.command, "chunk") or string.find(chatvars.command, "map"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "regen" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == nil then
				send("dj-regen " .. chatvars.intX .. " " .. chatvars.intZ .. " "  .. chatvars.intX .. " " .. chatvars.intZ)
			else
				if chatvars.number ~= nil then
					chatvars.number = math.abs(chatvars.number)

					if chatvars.number > 30 then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number too big. Used 30 instead.[-]")
						chatvars.number = 30
					end

					send("dj-regen " .. chatvars.intX - chatvars.number .. " " .. chatvars.intZ - chatvars.number .. " "  .. chatvars.intX + chatvars.number.. " " .. chatvars.intZ + chatvars.number)
				else
					send("dj-regen " .. chatvars.intX .. " " .. chatvars.intZ .. " "  .. chatvars.intX .. " " .. chatvars.intZ)
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - djkrose commands ====")
		dbug("Registering help - djkrose commands")

		tmp = {}
		tmp.topicDescription = "djkrose's mod adds many great features to the server. The bot provides helper commands to free you from the console and it can combine several console commands into one bot command."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'scripting'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('scripting', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "scripting" then
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
		irc_chat(chatvars.ircAlias, "DJKRose's scripting Mod Commands:")
		irc_chat(chatvars.ircAlias, "=================================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "scripting")
	end

	result = cmd_ExportPrefab()

	if result then
		if debug then dbug("debug cmd_ExportPrefab triggered") end
		return result
	end

	if (debug) then dbug("debug djkrose line " .. debugger.getinfo(1).currentline) end

	result = cmd_ImportPrefab()

	if result then
		if debug then dbug("debug cmd_ImportPrefab triggered") end
		return result
	end

	if (debug) then dbug("debug djkrose line " .. debugger.getinfo(1).currentline) end

	result = cmd_RegenChunk()

	if result then
		if debug then dbug("debug cmd_RegenChunk triggered") end
		return result
	end

	if debug then dbug("debug djkrose end") end

	-- can't touch dis
	if true then
		return result
	end
end
