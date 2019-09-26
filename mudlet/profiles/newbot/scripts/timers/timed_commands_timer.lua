--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function WebPanelQueue()
	local row, cursor, errorString, steam, action, actionTable, actionQuery, actionArgs, sessionID, temp

	-- delete any expired records in webInterfaceJSON
	conn:execute("DELETE FROM webInterfaceJSON WHERE expire < NOW() and expire <> '0000-00-00 00:00:00'")

	-- check webInterfaceQueue for records and process them
	cursor,errorString = conn:execute("SELECT * FROM webInterfaceQueue ORDER BY id")

	if cursor then
		row = cursor:fetch({}, "a")

		while row do
			steam = row.steam
			action = row.action
			actionTable = row.actionTable
			actionQuery = row.actionQuery
			actionArgs = row.actionArgs
			sessionID = row.sessionID
			temp = string.split(actionArgs, "||")
			conn:execute("DELETE FROM webInterfaceQueue WHERE id = " .. row.id)

			if action == "encode" and actionTable == "botman" then
				if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, expires, json, sessionID) VALUES ('botman','panel','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + 60) .. "','" .. escape(yajl.to_string(botman)) .. "','" .. escape(sessionID) .. "')") end
			end

			if action == "fix bot" then
				fixBot()
			end

			if action == "fix shop" then
				fixShop()
			end

			if action == "forget players" then
				ForgetPlayers()
			end

			if action == "kick" then
				kick(temp[1], temp[2])
			end

			if action == "new profile" then
				newBotProfile()
			end

			if action == "pause bot" then
				irc_chat(server.ircMain, "The bot is paused.")
				message("say [" .. server.warnColour .. "]The bot is paused.  Most commands are disabled. D:[-]")
				botman.botDisabled = false
			end

			if action == "quick reset bot" then
				QuickResetBot()
			end

			if action == "reload bot" then
				reloadBot()
			end

			if action == "reload scripts" then
				reloadCode()
			end

			if action == "reload table" then
				if actionTable == "" then
					loadTables(true)
				end

				if actionTable == "locations" then
					loadLocations()
				end

				if actionTable == "badItems" then
					loadBadItems()
				end

				if actionTable == "bans" then
					loadBans()
				end

				if actionTable == "bases" then
					loadBases()
				end

				if actionTable == "customMessages" then
					loadCustomMessages()
				end

				if actionTable == "friends" then
					loadFriends()
				end

				if actionTable == "gimmeZombies" then
					loadGimmeZombies()
				end

				if actionTable == "hotspots" then
					loadHotspots()
				end

				if actionTable == "locationCategories" then
					loadLocationCategories()
				end

				if actionTable == "otherEntities" then
					loadOtherEntities()
				end

				if actionTable == "players" then
					if steam ~= 0 then
						loadPlayers(steam)
					else
						loadPlayers()
					end
				end

				if actionTable == "resetZones" then
					loadResetZones()
				end

				if actionTable == "restrictedItems" then
					loadRestrictedItems()
				end

				if actionTable == "server" then
					loadServer()
				end

				if actionTable == "shopCategories" then
					loadShopCategories()
				end

				if actionTable == "teleports" then
					loadTeleports()
				end

				if actionTable == "villagers" then
					loadVillagers()
				end

				if actionTable == "waypoints" then
					if steam ~= 0 then
						loadWaypoints(steam)
					else
						loadWaypoints()
					end
				end

				if actionTable == "whitelist" then
					loadWhitelist()
				end
			end

			if action == "reset bot" then
				ResetBot()
			end

			if action == "reset bot keep cash" then
				ResetBot(true)
			end

			if action == "restart bot" then
				if server.allowBotRestarts then
					restartBot()
				end
			end

			if action == "restart server" then
				if server.allowReboot then
					botman.scheduledRestart = false
					botman.scheduledRestartTimestamp = os.time()
					botman.scheduledRestartPaused = false
					botman.scheduledRestartForced = true

					if (botman.rebootTimerID ~= nil) then killTimer(botman.rebootTimerID) end
					if (rebootTimerDelayID ~= nil) then killTimer(rebootTimerDelayID) end

					botman.rebootTimerID = nil
					rebootTimerDelayID = nil
					botman.scheduledRestartPaused = false
					botman.scheduledRestart = true
					botman.scheduledRestartTimestamp = os.time() + 120
				end
			end

			if action == "say" then
				message(temp[1], temp[2])
			end

			if action == "update bot" then
				updateBot(true)
			end

			if action == "unpause bot" then
				irc_chat(server.ircMain, "The bot is no longer paused.")
				message("say [" .. server.warnColour .. "]The bot is now accepting commands again! :D[-]")
				botman.botDisabled = false
			end

			row = cursor:fetch(row, "a")
		end
	end
end


function timedCommandsTimer()
	local cursor, errorString, row, steam, command

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	cursor,errorString = conn:execute("select * from commandQueue order by id limit 0,1")
	row = cursor:fetch({}, "a")

	if row then
		steam = row.steam
		command = row.command

		windowMessage(server.windowDebug, "running timed command (" .. row.id .. ") " .. command .. "\n")

		if (row.command ~= "DoneInventory") then

			if igplayers[steam] == nil then
				conn:execute("delete from commandQueue where steam = " .. steam)
			else
				conn:execute("delete from commandQueue where id = " .. row.id)
				sendCommand(command)
			end
		else
			conn:execute("delete from commandQueue where id = " .. row.id)
			CheckInventory()
		end
	end

	-- piggyback on this timer and process the web panel queue
	WebPanelQueue()
end
