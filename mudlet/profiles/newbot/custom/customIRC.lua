--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- Coded something awesome?  Consider sharing it :D

--


function customIRC(name, words, wordsOld, msgLower, ircID)
	local status, row, cursor, errorString

	if (words[1] == "debug" and words[2] == "on") then
		server.enableWindowMessages = true
		irc_chat(name, "Debugging ON")

		return true
	end

	if (words[1] == "debug" and words[2] == "all") then
		server.enableWindowMessages = true
		botman.debugAll = true
		irc_chat(name, "Debugging ON")

		return true
	end

	if (words[1] == "debug" and words[2] == "off") then
		server.enableWindowMessages = false
		botman.debugAll = false
		irc_chat(name, "Debugging OFF")

		return true
	end

	if words[1] == "test" and words[2] == "command" then
		irc_chat(name, "Test Start")

		irc_chat(name, "Test End")

		return true
	end

	return false
end