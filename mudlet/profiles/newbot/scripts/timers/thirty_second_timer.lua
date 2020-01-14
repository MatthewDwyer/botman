--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function thirtySecondTimer()
	local k, v, cmd, url, data

	windowMessage(server.windowDebug, "30 second timer\n")

	if botman.botDisabled then
		return
	end

	if customThirtySecondTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customThirtySecondTimer() then
			return
		end
	end

	data = {}
	data.botOnline = botman.botOnline

	if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('botman','panel','" .. escape(yajl.to_string(botman)) .. "')") end
	if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('server','panel','" .. escape(yajl.to_string(server)) .. "')") end

	if botman.botOffline then
		return
	end


	if server.botsIP == "0.0.0.0" then
		send("pm BotStartupCheck \"test\"")
	end

	if (botman.announceBot == true) then
		fixMissingServer() -- test for missing values

		message("say [" .. server.chatColour .. "]" .. server.botName .. " is online. Command me. :3[-]")
		botman.announceBot = false
	end

	math.randomseed( os.time() )

	if (botman.initError == true) then
		gatherServerData()
		botman.initError = false
		botman.announceBot = true
	end

	if server.allowReboot then
		if botman.nextRebootTest ~= nil and os.time() < botman.nextRebootTest then
			return
		end

		if tonumber(server.rebootHour) == tonumber(botman.serverHour) and tonumber(server.rebootMinute) == tonumber(botman.serverMinute) and botman.scheduledRestart == false then
			message("say [" .. server.chatColour .. "]The server will reboot in 15 minutes.[-]")
			botman.scheduledRestartPaused = false
			botman.scheduledRestart = true
			botman.scheduledRestartTimestamp = os.time() + 900
		else
			if server.uptime then
				if server.uptime / 60 >= (server.maxServerUptime * 60) and botman.scheduledRestart == false then
					message("say [" .. server.chatColour .. "]The server will reboot in 15 minutes.[-]")
					botman.scheduledRestartPaused = false
					botman.scheduledRestart = true
					botman.scheduledRestartTimestamp = os.time() + 900
				end
			end
		end
	end

	if not server.lagged then
		newDay()

		-- scan player inventories
		if not server.useAllocsWebAPI then
			for k, v in pairs(igplayers) do
				if (v.killTimer == nil) then v.killTimer = 0 end

				if tonumber(v.killTimer) < 2 then
					cmd = "si " .. k
					if botman.dbConnected then conn:execute("INSERT into commandQueue (command, steam) VALUES ('" .. cmd .. "'," .. k .. ")") end
				end
			end

			cmd = "DoneInventory"
			if botman.dbConnected then conn:execute("INSERT into commandQueue (command) VALUES ('" .. cmd .. "')") end
		else
			if tonumber(botman.playersOnline) > 0 then
				sendCommand("getplayerinventories", "getplayerinventories?", "inventories.txt")
			end
		end

		-- test for telnet command lag as it can creep up on busy servers or when there are lots of telnet errors going on
		if not botman.botOffline and not botman.botDisabled then
			if server.enableLagCheck then
				botman.lagCheckTime = os.time()
				sendCommand("pm LagCheck " .. os.time())
			end
		else
			if server.enableLagCheck then
				botman.lagCheckTime = os.time()
			end
		end
	end

	-- update the shared database (bots) server table (mainly for players online and a timestamp so others can see we're still online
	updateBotsServerTable()

	if tonumber(server.uptime) == 0 then
		if server.botman and not server.stompy then
			sendCommand("bm-uptime")
		end

		if not server.botman and server.stompy then
			sendCommand("bc-time")
		end
	end
end
