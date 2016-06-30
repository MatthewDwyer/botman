--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function loginSuccessful(line)
	if botDisabled then
		return
	end

	-- relogCount is used to detect excessive relogging which is indicative of a server crash.
	if relogCount == nil then relogCount = 0 end

	if string.find(line, "Logon successful.") then
		botOffline = 2
		relogCount = relogCount + 1

		if not serverDataLoaded then
			-- The bot hasn't yet managed to get data from gg and other server info commands so run gg etc now.
			getServerData()
		end

		if relogCount > 6 then
			irc_QueueMsg(server.ircMain, "Server has crashed.  Please manually restart it.")
		else
			irc_QueueMsg(server.ircMain, "Successfully logged in and monitoring server traffic.")
		end

		if not server.allowPhysics then
		
			if server.coppi then
				send("py")
			end
			
			if server.ubex then	
				send("ubex_opt blah physics false")
			end
		end

		if server.tempMaxPlayers ~= nil then
			send("sg ServerMaxPlayerCount " .. server.tempMaxPlayers)
		end
	end
end
