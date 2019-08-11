--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- Coded something awesome?  Consider sharing it :D

-- The functions in here are called from several places throughout the bot.  If you need a new call added let me know and I will add it for you.
-- These calls to custom_functions allows you to add new code to the bot that is executed in some timer, trigger, or script or override the existing bot code if your custom
-- function returns true..

-- Note on overriding bot code;
-- If your custom function prevents the bot running existing code that the bot relies on, your bot may not work as expected.  Examine the code below the call to your
-- custom function (ie in scripts/timers/thirty_second_timer.lua) and include the existing code from there into your custom function (ie. copy it into customThirtySecondTimer).
-- If your custom function does not return true, the rest of the code (ie. in thirty_second_timer.lua) will be executed after your custom code.
-- In some places, the call to the custom function is intentionally called last or not called early.  Let me know if you need the call moved higher up the code.

-- If your custom function returns true, the bot will stop processing after the call to your custom function returns.  If you want the bot to continue processing after the call, return false


function customAPIHandler(...)
	-- called by scripts/webAPI_functions.lua

	return false
end


function customAPIPlayerInfo(data)
	-- called by scripts/webAPI_functions.lua

	return false
end


function customPVP(line, killerID, victimID)
	-- called by scripts/triggers/pvp.lua

	return false
end


function customPlayerInfo(line)
	-- called by scripts/triggers/player_info.lua

	return false
end


function custom_startup()
	-- called by scripts/startup_bot.lua

	return false
end


function customPlayerConnected(line, entityid, player, steam, steamOwner, IP)
	-- called by scripts/triggers/player_connected.lua

	return false
end


function customPlayerDisconnected(line, entityID, steam, name)
	-- called by scripts/triggers/player_disconnected.lua

	return false
end


function customMatchAll(line)
	-- called by scripts/triggers/match_all.lua

	return false
end


function customHourlyTimer()
	-- called by scripts/timers/one_hour_timer.lua

	-- if the server has been offline for 7 days, run the Desktop script botstop.sh
	-- Most self-hosted bots won't have this script so it will only shut down bots with the script present.
	-- The reason for stopping the bot after a long server downtime is to free up resources and reduce load on the server hosting the bot.
	-- The bot can be restarted when someone notices that its AWOL anyway.  Mudlet's launcher script can be rigged to auto-restart by copying 1 line.
    -- In the file run-mudlet.sh copy WaitRestart="true" to just after line 66

	if botman.botOfflineTimestamp then
		if os.time() - botman.botOfflineTimestamp > 604800 then
			os.execute("~/Desktop/botstop.sh")
		end
	end

	return false
end


function customDaily()
	-- called by scripts/functions.lua in function newBotDay

	return false
end


function customTenSecondTimer()
	-- called by scripts/timers/ten_second_timer.lua

	return false
end


function customFifteenSecondTimer()
	-- called by scripts/timers/fifteen_second_timer.lua

	return false
end


function customThirtySecondTimer()
	-- called by scripts/timers/thirty_second_timer.lua

	return false
end


function customFortyfiveSecondTimer()
	-- called by scripts/timers/fortyfive_second_timer.lua

	return false
end


function customOneMinuteTimer()
	-- called by scripts/timers/one_minute_timer.lua

	return false
end


function customTwoMinuteTimer()
	-- called by scripts/timers/two_minute_timer.lua

	return false
end


function customTenMinuteTimer()
	-- called by scripts/timers/ten_minute_timer.lua

	return false
end