--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function loginSuccessful(line)
	-- relogCount is used to detect excessive relogging which is indicative of a server crash.
	if relogCount == nil then relogCount = 0 end

	if string.find(line, "Logon successful.") then
		botman.botOfflineCount = 2
		relogCount = relogCount + 1

		botman.botOffline = false
		botman.botConnectedTimestamp = os.time() -- used to measure how long the bot has been offline so we can slow down how often it
		-- tries to reconnect.  Mudlet creates high cpu load if it is offline for too long.  Hopefully checking less frequently will reduce that.

		if not serverDataLoaded then
			-- The bot hasn't yet managed to get data from gg and other server info commands so run gg etc now.
			getServerData()
		end

		if relogCount > 6 then
			irc_chat(server.ircMain, "Server has crashed.  Please manually restart it.")
		else
			irc_chat(server.ircMain, "Successfully logged in and monitoring server traffic.")
		end
	end
end
