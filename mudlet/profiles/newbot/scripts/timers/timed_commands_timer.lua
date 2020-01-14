--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function WebPanelQueue()
	local row, cursor, errorString, steam, action, actionTable, actionQuery, actionArgs, sessionID, temp, command

	-- delete any expired records in webInterfaceJSON
	conn:execute("DELETE FROM webInterfaceJSON WHERE expire < NOW() and expire <> '0000-00-00 00:00:00'")

	-- check webInterfaceQueue for records and process them
	cursor,errorString = conn:execute("SELECT * FROM webInterfaceQueue ORDER BY id")

	if cursor then
		row = cursor:fetch({}, "a")

		while row do
			steam = tostring(row.steam)
			action = string.trim(string.lower(row.action))
			actionTable = string.trim(string.lower(row.actionTable))
			actionQuery = string.trim(row.actionQuery)
			actionArgs = string.trim(row.actionArgs)

			command = {}
			command.action = action
			command.actionTable = actionTable
			command.actionQuery = actionQuery
			command.actionArgs = actionArgs

			logPanelCommand(botman.serverTime, command)

			sessionID = row.sessionID
			temp = string.split(actionArgs, "||")
			conn:execute("DELETE FROM webInterfaceQueue WHERE id = " .. row.id)

			if action == "encode" and actionTable == "botman" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				irc_chat(server.ircAlerts, "actionTable = " .. actionTable)
				if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, expires, json, sessionID) VALUES ('botman','panel','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + 60) .. "','" .. escape(yajl.to_string(botman)) .. "','" .. escape(sessionID) .. "')") end
			end

			if action == "fix bot" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				fixBot()
			end

			if action == "fix shop" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				fixShop()
			end

			if action == "forget players" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				forgetPlayers()
			end

			if action == "kick" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				kick(temp[1], temp[2])
			end

			if action == "new profile" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				tempTimer(4, [[newBotProfile()]])
			end

			if action == "pause bot" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				irc_chat(server.ircMain, "The bot is paused.")
				message("say [" .. server.warnColour .. "]The bot is paused.  Most commands are disabled. D:[-]")
				botman.botDisabled = true
			end

			if action == "quick reset bot" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				quickBotReset()
			end

			if action == "reindex shop" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)

				loadShopCategories()

				if actionArgs == "" then
					reindexShop()
				else
					reindexShop(actionArgs)
				end
			end

			if action == "reload bot" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				reloadBot()
			end

			if action == "reload scripts" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				reloadCode()
			end

			if action == "reload staff" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				sendCommand("admin list")
			end

			if action == "reload table" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				irc_chat(server.ircAlerts, "actionTable = " .. actionTable)

				if actionTable == "" then
					loadTables(true)
				end

				if actionTable == "baditems" then
					loadBadItems()
				end

				if actionTable == "bans" then
					loadBans()
				end

				if actionTable == "bases" then
					loadBases()
				end

				if actionTable == "custommessages" then
					loadCustomMessages()
				end

				if actionTable == "donors" then
					loadDonors()
				end

				if actionTable == "friends" then
					loadFriends()
				end

				if actionTable == "gimmezombies" then
					loadGimmeZombies()
				end

				if actionTable == "hotspots" then
					loadHotspots()
				end

				if actionTable == "locations" then
					loadLocations()
				end

				if actionTable == "locationcategories" then
					loadLocationCategories()
				end

				if actionTable == "modbotman" then
					loadModBotman()
				end

				if actionTable == "otherentities" then
					loadOtherEntities()
				end

				if actionTable == "players" then
					if steam ~= "0" then
						loadPlayers(steam)
					else
						loadPlayers()
					end
				end

				if actionTable == "resetzones" then
					loadResetZones()
				end

				if actionTable == "restricteditems" then
					loadRestrictedItems()
				end

				if actionTable == "server" then
					loadServer()
				end

				if actionTable == "shopcategories" then
					loadShopCategories()
				end

				if actionTable == "teleports" then
					loadTeleports()
				end

				if actionTable == "villagers" then
					loadVillagers()
				end

				if actionTable == "waypoints" then
					if steam ~= "0" then
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
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				ResetBot()
			end

			if action == "reset bot keep cash" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				ResetBot(true)
			end

			if action == "reset server" or action == "fresh bot" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				ResetServer()
			end

			if action == "restart bot" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				tempTimer(6, [[restartBot()]])
			end

			if action == "restart server" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)

				server.allowReboot = true
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
				botman.scheduledRestartTimestamp = os.time() + 60
				message("say [" .. server.chatColour .. "]The server is restarting in 1 minute.[-]")
			end

			if action == "say" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				irc_chat(server.ircAlerts, "action args = " .. actionArgs)
				message(temp[1], temp[2])
			end

			if action == "send command" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				sendCommand(actionArgs)
			end

			if action == "update bot" or action == "update code" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				updateBot(true)
			end

			if action == "unpause bot" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
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

	-- piggyback on this timer and process the web panel queue
	WebPanelQueue()

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
end
