--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function loginSuccessful(line)
	-- relogCount is used to detect excessive relogging which is indicative of a server crash.
	if relogCount == nil then relogCount = 0 end

	tempTimer( 1, [[ setBlockTelnetSpam(true) ]] )

	botman.botOfflineCount = 0
	relogCount = relogCount + 1
	botman.botOffline = false
	botman.telnetOffline = false
	botman.wrongTelnetPass = nil
	botman.noLoginCooldown = nil
	botman.botConnectedTimestamp = os.time() -- used to measure how long the bot has been offline so we can slow down how often it tries to reconnect.
	send("pm BotStartupCheck \"test\"")
	tempTimer( 5, [[ announceTelnetLogin() ]] )
	botman.getMetrics = false

	if not botStatus.safeMode then
		if botman.APIOffline then
			toggleTriggers("api offline")

			if server.useAllocsWebAPI then
				connectToAPI()
			end
		else
			toggleTriggers("api online")
		end
	end
end
