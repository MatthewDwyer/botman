--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
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

function gmsg_botman()
	calledFunction = "gmsg_botman"
	result = false

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## Botman mod command functions ##################

	local function cmd_AddRemoveTraderProtection()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}trader protect/unprotect/remove {named area}\n"
			help[1] = " {#}trader add/trader del {named area}"
			help[2] = "After marking out a named area with the {#}mark command, you can add or remove trader protection on it.\n"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "trade,prot,botman"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "trade") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "botman") or string.find(chatvars.command, "prote"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "trader" and (chatvars.words[2] == "protect" or chatvars.words[2] == "unprotect" or chatvars.words[2] == "remove" or chatvars.words[2] == "add" or chatvars.words[2] == "del") then
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

				irc_chat(chatvars.ircAlias, "You can only use this command ingame.")
				botman.faultyChat = false
				return true
			end

			tmp.name = ""

			if chatvars.words[2] == "protect" or chatvars.words[2] == "unprotect" then
				tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "protect") + 8)
			else
				if chatvars.words[2] == "remove" then
					tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "remove") + 7)
				end
			end

			if chatvars.words[2] == "add" then
				tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "add ") + 4)
			end


			if chatvars.words[2] == "del" then
				tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "del ") + 4)
			end

			if tmp.name == "" then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Name of previously marked out or saved area required. (not a location name)[-]")

				botman.faultyChat = false
				return true
			else
				tmp.name = string.trim(tmp.name)
			end

			if not prefabCopies[chatvars.playerid .. tmp.name] then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You haven't marked an area called " .. tmp.name .. ". Please do that first.[-]")
			else
				if chatvars.words[2] == "protect" or chatvars.words[2] == "add" then
					sendCommand("bm-safe add " .. prefabCopies[chatvars.playerid .. tmp.name].x1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].x2 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z2)
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added trader protection on a marked area called " .. tmp.name .. ".[-]")
				else
					sendCommand("bm-safe del " .. prefabCopies[chatvars.playerid .. tmp.name].x1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].x2 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z2)
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed trader protection on a marked area called " .. tmp.name .. ".[-]")
				end

				igplayers[chatvars.playerid].undoPrefab = false
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetChatColours()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set new player/player/donor/prisoner/mod/admin/owner chat colour FFFFFF\n"
			help[1] = help[1] .. " {#}reset chat colour"
			help[2] = "Set the default chat colour for a class of player.  You can also set chat colour for a named player.\n"
			help[2] = help[2] .. "eg. {#}set player joe chat colour B0E0E6\n"
			help[2] = help[2] .. "To disable automatic chat colouring, set it to white which is FFFFFF\n"
			help[2] = help[2] .. "To reset everyone to white type {#}reset chat colour everyone"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,clear,chat,colo"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set" or chatvars.words[1] == "reset") and string.find(chatvars.command, "chat col") then
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

			tmp = {}
			tmp.target = chatvars.words[2]
			tmp.namedPlayer = false

			if string.find(chatvars.command, "reset chat colo") and chatvars.words[4] ~= nil then
				if chatvars.words[4] == "everyone" or chatvars.words[4] == "all" then
					for k,v in pairs(players) do
						v.chatColour = "FFFFFF"
					end

					for k,v in pairs(playersArchived) do
						v.chatColour = "FFFFFF"
					end

					for k,v in pairs(igplayers) do
						setPlayerColour(k, "FFFFFF")
					end

					if botman.dbConnected then conn:execute("UPDATE players SET chatColour = 'FFFFFF'") end
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET chatColour = 'FFFFFF'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Everyone's stored chat colour is white, but players will still be coloured if any player classes are coloured (eg. donors).[-]")
					else
						irc_chat(chatvars.ircAlias, "Everyone's stored chat colour is white, but players will still be coloured if any player classes are coloured (eg. donors).")
					end
				else
					tmp.name = chatvars.words[4]
					tmp.pid = LookupPlayer(tmp.name)

					if tmp.pid == 0 then
						tmp.pid = LookupArchivedPlayer(tmp.name)

						if tmp.pid ~= 0 then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
							else
								irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.")
							end
						else
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. tmp.name .. "[-]")
							else
								irc_chat(chatvars.ircAlias, "No player found called " .. tmp.name)
							end
						end

						botman.faultyChat = false
						return true
					else
						tmp.name = players[tmp.pid].name
					end

					if tmp.pid ~= 0 then
						setPlayerColour(tmp.pid, "FFFFFF")
						players[tmp.pid].chatColour = tmp.colour
						if botman.dbConnected then conn:execute("UPDATE players SET chatColour = 'FFFFFF' WHERE steam = " .. tmp.pid) end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. tmp.name ..  "'s name is now coloured coloured [FFFFFF]white[-][-]")
						else
							irc_chat(chatvars.ircAlias, tmp.name ..  "'s name is now coloured white")
						end

						botman.faultyChat = false
						return true
					end
				end

				botman.faultyChat = false
				return true
			end

			for i=4,chatvars.wordCount,1 do
				if chatvars.words[i] == "colour" or chatvars.words[i] == "color" then
					tmp.colour = chatvars.words[i+1]
				end
			end

			-- special case setting chat colour for a named player
			if chatvars.words[2] == "player" and chatvars.words[3] ~= "chat" then
				tmp.namedPlayer = true
			end

			if tmp.target ~= "new" and tmp.target ~= "player" and tmp.target ~= "donor" and tmp.target ~= "prisoner" and tmp.target ~= "mod" and tmp.target ~= "admin" and tmp.target ~= "owner" and not tmp.namedPlayer then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Missing target for chat colour.  Expected new player or player or donor or prisoner or mod or admin or owner.[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing target for chat colour.  Expected new player or player or donor or prisoner or mod or admin or owner.")
				end

				botman.faultyChat = false
				return true
			end

			if tmp.colour == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]6 character hex colour code required eg. FFFFFF for white.[-]")
				else
					irc_chat(chatvars.ircAlias, "6 character hex colour code required eg. FFFFFF for white.")
				end

				botman.faultyChat = false
				return true
			end

			-- strip out any # characters
			tmp.colour = tmp.colour:gsub("#", "")
			tmp.colour = string.upper(string.sub(tmp.colour, 1, 6))

			if tmp.target == "new" then
				server.chatColourNewPlayer = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourNewPlayer = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New player names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
				else
					irc_chat(chatvars.ircAlias, "New player names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
				end

				for k,v in pairs(igplayers) do
					if accessLevel(k) == 99 and string.sub(players[k].chatColour, 1, 6) == "FFFFFF" then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			if tmp.target == "player" then
				if tmp.namedPlayer then
					tmp.name = string.sub(chatvars.command, string.find(chatvars.command, " player ") + 8, string.find(chatvars.command, " chat ") - 1)
					tmp.pid = LookupPlayer(tmp.name)

					if tmp.pid == 0 then
						tmp.pid = LookupArchivedPlayer(tmp.name)

						if tmp.pid ~= 0 then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
							else
								irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.")
							end
						else
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. tmp.name .. "[-]")
							else
								irc_chat(chatvars.ircAlias, "No player found called " .. tmp.name)
							end
						end

						botman.faultyChat = false
						return true
					else
						tmp.name = players[tmp.pid].name
					end

					if tmp.pid ~= 0 then
						setPlayerColour(tmp.pid, tmp.colour)
						players[tmp.pid].chatColour = tmp.colour
						if botman.dbConnected then conn:execute("UPDATE players SET chatColour = '" .. escape(tmp.colour) .. "' WHERE steam = " .. tmp.pid) end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. tmp.name ..  "'s name is now coloured coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-][-]")
						else
							irc_chat(chatvars.ircAlias, tmp.name ..  "'s name is now coloured " .. tmp.colour)
						end

						botman.faultyChat = false
						return true
					end
				else
					server.chatColourPlayer = tmp.colour
					if botman.dbConnected then conn:execute("UPDATE server SET chatColourPlayer = '" .. escape(tmp.colour) .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Non-new player names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
					else
						irc_chat(chatvars.ircAlias, "Non-new player names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
					end

					for k,v in pairs(igplayers) do
						if accessLevel(k) == 90 and string.sub(players[k].chatColour, 1, 6) == "FFFFFF" then
							setPlayerColour(k, tmp.colour)
						end
					end
				end
			end

			if tmp.target == "donor" then
				server.chatColourDonor = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourDonor = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Donor's names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
				else
					irc_chat(chatvars.ircAlias, "Donor's names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
				end

				for k,v in pairs(igplayers) do
					if (accessLevel(k) > 3 and accessLevel(k) < 11) and string.sub(v.chatColour, 1, 6) == "FFFFFF" then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			if tmp.target == "prisoner" then
				server.chatColourPrisoner = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourPrisoner = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Prisoner's names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-][-]")
				else
					irc_chat(chatvars.ircAlias, "Prisoner's names will be coloured " .. tmp.colour)
				end

				for k,v in pairs(igplayers) do
					if players[k].prisoner then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			if tmp.target == "mod" then
				server.chatColourMod = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourMod = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Mod names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
				else
					irc_chat(chatvars.ircAlias, "Mod names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
				end

				for k,v in pairs(igplayers) do
					if accessLevel(k) == 2 and string.sub(players[k].chatColour, 1, 6) == "FFFFFF" then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			if tmp.target == "admin" then
				server.chatColourAdmin = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourAdmin = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admin names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
				else
					irc_chat(chatvars.ircAlias, "Admin names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
				end

				for k,v in pairs(igplayers) do
					if accessLevel(k) == 1 and string.sub(players[k].chatColour, 1, 6) == "FFFFFF" then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			if tmp.target == "owner" then
				server.chatColourOwner = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourOwner = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Owner names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
				else
					irc_chat(chatvars.ircAlias, "Owner names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
				end

				for k,v in pairs(igplayers) do
					if accessLevel(k) == 0 and string.sub(players[k].chatColour, 1, 6) == "FFFFFF" then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleShowHideCommands()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}show/hide commands"
			help[2] = "Hide commands from ingame chat which makes them all PM's or show them which makes them public.  They will still appear in the web client."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "show,hide,comm"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "comm")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "hide" or chatvars.words[1] == "show") and chatvars.words[2] == "commands" and chatvars.words[3] == nil  then
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

			if chatvars.words[1] == "hide" then
				hidePlayerChat(server.commandPrefix)
				if botman.dbConnected then conn:execute("UPDATE server SET hideCommands = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bot commands are now hidden from global chat.[-]")
				else
					irc_chat(server.ircMain, "Bot commands are now hidden from global chat.")
				end
			else
				hidePlayerChat()
				if botman.dbConnected then conn:execute("UPDATE server SET hideCommands = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bot commands are now visible in global chat.[-]")
				else
					irc_chat(server.ircMain, "Bot commands are now visible in global chat.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return false
		end
	end
	-- ##################################################################

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "botman" then
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
		irc_chat(chatvars.ircAlias, "Botman Mod Commands:")
		irc_chat(chatvars.ircAlias, "====================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "botman")
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetChatColours()

	if result then
		if debug then dbug("debug cmd_SetChatColours triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleShowHideCommands()

	if result then
		if debug then dbug("debug cmd_ToggleShowHideCommands triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == nil) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	result = cmd_AddRemoveTraderProtection()

	if result then
		if debug then dbug("debug cmd_AddRemoveTraderProtection triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end



	if debug then dbug("debug botman end") end
	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Botman commands help registered ****")
		dbug("Botman commands help registered")
		topicID = topicID + 1
	end

	-- can't touch dis
	if true then
		-- HAMMER TIME!
		return result
	end
end
