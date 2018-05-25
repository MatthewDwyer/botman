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

if botman.debugAll then
	debug = true -- this should be true
end

function gmsg_stompy()
	calledFunction = "gmsg_stompy"
	result = false

	-- NEW STUFF!   SQUEEEEEEEE!

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

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
			if chatvars.words[3] ~= "stompy" then
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
		irc_chat(chatvars.ircAlias, "Stompy's BC Mod Commands:")
		irc_chat(chatvars.ircAlias, "=========================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "stompy")
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	-- if chatvars.showHelp and not skipHelp then
		-- if (chatvars.words[1] == "help" and string.find(chatvars.command, "stompy") or string.find(chatvars.command, "mute")) or chatvars.words[1] ~= "help" then
			-- irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "mute {player name}")
			-- irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "unmute {player name}")

			-- if not shortHelp then
				-- irc_chat(chatvars.ircAlias, "Prevent a player using text chat or allow them to chat.")
				-- irc_chat(chatvars.ircAlias, ".")
			-- end
		-- end
	-- end

	 -- if (chatvars.words[1] == "mute" or chatvars.words[1] == "unmute") and chatvars.words[2] ~= nil then
		-- tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "mute ") + 5)
		-- tmp.pname = string.trim(tmp.pname)
		-- tmp.pid = LookupPlayer(tmp.pname)

		-- if tmp.pid == 0 then
			-- if (chatvars.playername ~= "Server") then
				-- message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]No player found called " .. tmp.pname .. "[-]")
			-- else
				-- irc_chat(server.ircMain, "No player found called " .. tmp.pname)
			-- end

			-- botman.faultyChat = false
			-- return true
		-- end

		-- if chatvars.words[1] == "unmute" then
			-- unmutePlayer(tmp.pid)

			-- if (chatvars.playername ~= "Server") then
				-- message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. " can chat again D:[-]")
			-- end
		-- else
			-- mutePlayer(tmp.pid)

			-- if (chatvars.playername ~= "Server") then
				-- message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Chat from player " .. players[tmp.pid].name .. " is blocked :D[-]")
			-- end
		-- end

		-- botman.faultyChat = false
		-- return true
	-- end



	if debug then dbug("debug stompy end") end

	-- can't touch dis
	if true then
		return result
	end
end
