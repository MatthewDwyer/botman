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



	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == nil) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################



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
