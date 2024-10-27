--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

-- this is a collection of queue processing functions that used to live in specific timers but have been moved out for convenience and because
-- they might be triggered by different timers or other triggers in the future to improve bot performance (eg. reducing io load).

function WebPanelQueue()
	-- this queue can't be disabled as it is loaded from the Botman panel website.
	local row, cursor, errorString, steam, action, actionTable, actionQuery, actionArgs, sessionID, temp, command, tmp, web

	web = "webpermission"

	-- delete any expired records in webInterfaceJSON
	--conn:execute("DELETE FROM webInterfaceJSON WHERE expire < NOW() AND expire <> '0000-00-00 00:00:00'")

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

			-- if action == "encode" and actionTable == "botman" then
				-- irc_chat(server.ircAlerts, "Panel triggered " .. action)
				-- irc_chat(server.ircAlerts, "actionTable = " .. actionTable)
				-- if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, expires, json, sessionID) VALUES ('botman','panel','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + 60) .. "','" .. escape(yajl.to_string(botman)) .. "','" .. escape(sessionID) .. "')") end
			-- end

			if action == "fix bot" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				fixBot()
			end

			if action == "fix map permissions" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)

				sendCommand(web .. " add web.map 2000")
				sendCommand(web .. " add webapi.getplayersOnline 1000")
				sendCommand(web .. " add webapi.getstats 1000")
				sendCommand(web .. " add webapi.getlandclaims 1000")

				if string.find(actionArgs, "no hostiles") then
					sendCommand(web .. " add webapi.gethostilelocation 2")
				else
					sendCommand(web .. " add webapi.gethostilelocation 2000")
				end

				if string.find(actionArgs, "no animals") then
					sendCommand(web .. " add webapi.getanimalslocation 2")
				else
					sendCommand(web .. " add webapi.getanimalslocation 2000")
				end

				if string.find(actionArgs, "show players") then
					sendCommand(web .. " add webapi.viewallplayers 2000")
					sendCommand(web .. " add webapi.GetPlayersLocation 2000")
				else
					sendCommand(web .. " add webapi.viewallplayers 2")
					sendCommand(web .. " add webapi.GetPlayersLocation 0")
				end

				if string.find(actionArgs, "show claims") then
					sendCommand(web .. " add webapi.viewallclaims 2000")
					sendCommand(web .. " add webapi.getlandclaims 2000")
				else
					sendCommand(web .. " add webapi.viewallclaims 2")
					sendCommand(web .. " add webapi.getlandclaims 1000")
				end

				if string.find(actionArgs, "show inventory") then
					sendCommand(web .. " add webapi.getplayerinventory 2000")
				else
					sendCommand(web .. " add webapi.getplayerinventory 2")
				end
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
				tempTimer(5, [[newBotProfile()]])
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

			if action == "rejoin irc" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)
				joinIRCServer()
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
					tempTimer(3, [[loadTables(true)]])
				end

				if actionTable == "baditems" then
					tempTimer(3, [[loadBadItems()]])
				end

				if actionTable == "bans" then
					tempTimer(3, [[loadBans()]])
				end

				if actionTable == "bases" then
					tempTimer(3, [[loadBases()]])
				end

				if actionTable == "custommessages" then
					tempTimer(3, [[loadCustomMessages()]])
				end

				if actionTable == "donors" then
					if steam ~= "0" then
						tempTimer(3, [[loadDonors(']] .. steam .. [[')]])
					else
						tempTimer(3, [[loadDonors()]])
					end
				end

				if actionTable == "friends" then
					if steam ~= "0" then
						tempTimer(3, [[loadFriends(']] .. steam .. [[')]])
					else
						tempTimer(3, [[loadFriends()]])
					end
				end

				if actionTable == "gimmeprizes" then
					tempTimer(3, [[loadGimmePrizes()]])
				end

				if actionTable == "gimmezombies" then
					tempTimer(3, [[loadGimmeZombies()]])
				end

				if actionTable == "hotspots" then
					tempTimer(3, [[loadHotspots()]])
				end

				if actionTable == "locations" then
					if actionArgs == "" then
						tempTimer(3, [[loadLocations()]])
					else
						tempTimer(3, [[loadLocations(']] .. actionArgs .. [[')]])
					end
				end

				if actionTable == "locationcategories" then
					if actionArgs == "" then
						tempTimer(3, [[loadLocationCategories()]])
					else
						tempTimer(3, [[loadLocationCategories(']] .. actionArgs .. [[')]])
					end
				end

				if actionTable == "modbotman" then
					tempTimer(3, [[loadModBotman()]])
				end

				if actionTable == "otherentities" then
					tempTimer(3, [[loadOtherEntities()]])
				end

				if actionTable == "players" then
					if steam ~= "0" then
						tempTimer(3, [[loadPlayers(']] .. steam .. [[')]])
					else
						tempTimer(3, [[loadPlayers()]])
					end
				end

				if actionTable == "resetzones" then
					tempTimer(3, [[loadResetZones(true)]])
				end

				if actionTable == "restricteditems" then
					tempTimer(3, [[loadRestrictedItems()]])
				end

				if actionTable == "server" then
					tempTimer(3, [[loadServer()]])
				end

				if actionTable == "shop" then
					tempTimer(3, [[loadShop()]])
				end

				if actionTable == "shopcategories" then
					tempTimer(3, [[loadShopCategories()]])
				end

				if actionTable == "teleports" then
					if actionArgs == "" then
						tempTimer(3, [[loadTeleports()]])
					else
						tempTimer(3, [[loadTeleports(']] .. actionArgs .. [[')]])
					end
				end

				if actionTable == "villagers" then
					tempTimer(3, [[loadVillagers()]])
				end

				if actionTable == "waypoints" then
					if steam ~= "0" then
						tempTimer(3, [[loadWaypoints(']] .. steam .. [[')]])
					else
						tempTimer(3, [[loadWaypoints()]])
					end
				end

				if actionTable == "whitelist" then
					tempTimer(3, [[loadWhitelist()]])
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

				botman.allowReboot = server.allowReboot -- preserve the current state of allowReboot

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

			if action == "visit map" then
				irc_chat(server.ircAlerts, "Panel triggered " .. action)

				tmp = {}

				-- Lockdown you say?  Screw that!  I'm visiting the whole world!  *cough* :P
				tmp.mapSize = math.floor(GamePrefs.WorldGenSize / 2)
				tmp.x1 = -tmp.mapSize
				tmp.z1 = tmp.mapSize
				tmp.x2 = tmp.mapSize
				tmp.z2 = -tmp.mapSize

				sendCommand(string.trim("visitmap " .. tmp.x1 .. " " .. tmp.z1 .. " " .. tmp.x2  .. " " .. tmp.z2))
				irc_chat(server.ircMain, "The entire map is being visited. This will take a while and is perfectly safe.  The bot used hand sanitizer, is wearing a mask, and swallowed some bleach.")
			end

			row = cursor:fetch(row, "a")
		end
	end
end


function persistentQueueTimer()
	local cursor, errorString, row, temp, command, ranCommand
	local steam, steamOwner, userID

	if botman.persistentQueueEmpty == nil then
		botman.persistentQueueEmpty = false
	end

	if botman.persistentQueueEmpty then
		return
	end

	if botman.botDisabled or botman.botOffline or not botman.dbConnected then
		return
	end

	cursor,errorString = connSQL:execute("SELECT * FROM persistentQueue LIMIT 1")

	if cursor then
		row = cursor:fetch({}, "a")

		if not row then
			botman.persistentQueueEmpty = true
		end
	end

	ranCommand = false
	cursor,errorString = connSQL:execute("SELECT * FROM persistentQueue WHERE timerDelay = 0 ORDER BY id limit 1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			steam, steamOwner, userID = LookupPlayer(row.steam)
			command = row.command

			if command == "update player" then
				ranCommand = true
				fixMissingPlayer(players[steam].platform, steam, players[steam].steamOwner, players[steam].userID)
				updatePlayer(steam)
				saveSQLitePlayer(steam)
				connSQL:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
			end

			if command == "update archived player" then
				ranCommand = true
				fixMissingArchivedPlayer(steam)
				updateArchivedPlayer(steam)
				connSQL:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
			end

			if string.find(command, "admin add") then
				ranCommand = true
				irc_chat(server.ircMain, "Player " .. players[steam].name .. " has been given admin.")
				temp = string.split(command, " ")
				setChatColour(steam, temp[4])
				connSQL:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
				sendCommand(command)
			end

			if string.find(command, "ban remove") then
				ranCommand = true
				irc_chat(server.ircMain, "Player " .. players[steam].name .. " has been unbanned.")
				connSQL:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
				sendCommand(command)
			end

			if string.find(command, "tele ") then
				ranCommand = true
				connSQL:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)

				if igplayers[steam] then
					teleport(command, steam, userID, true)
				end
			end

			if not ranCommand then
				connSQL:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
				sendCommand(command)
			end
		end
	end

	-- check all the delayed commands.  send any that are not in the future
	cursor,errorString = connSQL:execute("SELECT * FROM persistentQueue WHERE timerDelay <> 0 ORDER BY timerDelay, id LIMIT 1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			steam, steamOwner, userID = LookupPlayer(row.steam)
			command = row.command

			if row.timerDelay - os.time() <= 0 then
				if string.sub(command, 1, 3) == "pm " or string.sub(command, 1, 3) == "say" then
					ranCommand = true
					connSQL:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
					if botman.dbConnected then conn:execute("UPDATE staff SET hidden = 0 WHERE steam = '" .. userID .. "'") end
					if botman.dbConnected then conn:execute("UPDATE staff SET hidden = 0 WHERE steam = '" .. steam .. "'") end

					if staffList[userID] then
						staffList[userID].hidden = false
					end

					if staffList[steam] then
						staffList[steam].hidden = false
					end

					message(command)

					if string.find(row.command, "admin status") then
						irc_chat(server.ircMain, "OH GOD NOOOO! " .. players[steam].name .. "'s admin status has been restored.")
					end
				else
					if string.find(command, "tele ") then
						ranCommand = true
						connSQL:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)

						if igplayers[steam] then
							teleport(command, steam, userID, true)
						end
					else
						ranCommand = true
						connSQL:execute("DELETE FROM persistentQueue WHERE id = " .. row.id)
						sendCommand(command)

						if string.find(command, "admin add") then
							temp = string.split(command, " ")
							setChatColour(steam, temp[4])
							players[steam].testAsPlayer = nil
						end
					end
				end
			end
		end
	end
end


function spawnableItemsQueue()
	local row, cursor, errorString, tbl, k, v, count

	if botman.spawnableItemsQueueEmpty == nil then
		botman.spawnableItemsQueueEmpty = true
	end

	if botman.spawnableItemsQueueEmpty then
		-- nothing to do, nothing to see here
		return
	end

	cursor,errorString = connSQL:execute("SELECT * FROM spawnableItemsQueue ORDER BY id LIMIT 1")

	if cursor then
		row = cursor:fetch({}, "a")

		if not row then
			irc_chat(server.ircMain, "Item validation has completed.  The following items (if any) did not validate and have been deleted.")
			botman.spawnableItemsQueueEmpty = true
			botman.validateItems = nil
			initSpawnableItems()

			-- special case for item names with an asterisk (not an Obelix)
			conn:execute("UPDATE badItems SET validated = 1 WHERE item LIKE '%*%'")
			conn:execute("UPDATE restrictedItems SET validated = 1 WHERE item LIKE '%*%'")

			irc_chat(server.ircMain, "Report:  Invalid Shop Items Removed")
			count = 0

			for k, v in pairs(shop) do
				if not v.validated then
					count = count + 1
					irc_chat(server.ircMain, "Item " .. v.item .. " cat " .. v.category .. " maxStock - " .. v.maxStock .. " $" .. v.price .. " qty " .. v.stock .. " qual " .. v.quality .. " units " .. v.units)
				end
			end

			if count == 0 then
				irc_chat(server.ircMain, count .. " items removed")
			end

			irc_chat(server.ircMain, ".")
			irc_chat(server.ircMain, "Report:  Invalid Gimme Prizes Removed")
			count = 0

			for k, v in pairs(gimmePrizes) do
				if not v.validated then
					count = count + 1
					irc_chat(server.ircMain, "Item " .. v.name .. " cat " .. v.category .. " prize limit " .. v.prizeLimit .. " quality " .. v.quality)
				end
			end

			if count == 0 then
				irc_chat(server.ircMain, count .. " items removed")
			end

			irc_chat(server.ircMain, ".")
			irc_chat(server.ircMain, "Report:  Invalid Bad Items Removed")
			count = 0

			for k, v in pairs(badItems) do
				if not v.validated then
					if not string.find(v.item, "*") then
						count = count + 1
						irc_chat(server.ircMain, "Item " .. v.item .. " action " .. v.action)
					end
				end
			end

			if count == 0 then
				irc_chat(server.ircMain, count .. " items removed")
			end

			irc_chat(server.ircMain, ".")
			irc_chat(server.ircMain, "Report:  Invalid Restricted Items Removed")
			count = 0

			for k, v in pairs(restrictedItems) do
				if not v.validated then
					if not string.find(v.item, "*") then
						count = count + 1
						irc_chat(server.ircMain, "Item " .. v.item .. " qty " .. v.qty ..  " access level " .. v.accessLevel .. " action " .. v.action)
					end
				end
			end

			if count == 0 then
				irc_chat(server.ircMain, count .. " items removed")
			end

			irc_chat(server.ircMain, ".")
			irc_chat(server.ircMain, "End of item validation report.")

			conn:execute("DELETE FROM shop WHERE validated = 0")
			conn:execute("DELETE FROM restrictedItems WHERE validated = 0")
			conn:execute("DELETE FROM badItems WHERE validated = 0")
			conn:execute("DELETE FROM gimmePrizes WHERE validated = 0")

			-- reload the shop, bad items and restricted items after a short delay
			tempTimer(3, [[reloadItemLists()]])
		end

		if row then
			tbl = row.tableName

			for k, v in pairs(_G[tostring(tbl)]) do
				if shop[k] then
					shop[k].validated = true
					conn:execute("UPDATE shop SET validated = 1 WHERE item = '" .. k .. "'")
				end

				if badItems[k] then
					badItems[k].validated = true
					conn:execute("UPDATE badItems SET validated = 1 WHERE item = '" .. k .. "'")
				end

				if restrictedItems[k] then
					restrictedItems[k].validated = true
					conn:execute("UPDATE restrictedItems SET validated = 1 WHERE item = '" .. k .. "'")
				end

				if gimmePrizes[k] then
					gimmePrizes[k].validated = true
					conn:execute("UPDATE gimmePrizes SET validated = 1 WHERE name = '" .. k .. "'")
				end
			end

			connSQL:execute("DELETE FROM spawnableItemsQueue WHERE id = " .. row.id)
		end
	end
end


function LKPQueue()
	-- local row, cursor, errorString, LKPLine

	-- if botman.lkpQueueEmpty == nil then
		-- botman.lkpQueueEmpty = false
	-- end

	-- if botman.lkpQueueEmpty then
		-- return
	-- end

	-- cursor,errorString = connSQL:execute("SELECT * FROM LKPQueue ORDER BY id LIMIT 1")

	-- if cursor then
		-- row = cursor:fetch({}, "a")

		-- if not row then
			-- botman.lkpQueueEmpty = true
		-- end

		-- if row then
			-- LKPLine = row.line
			-- connSQL:execute("DELETE FROM LKPQueue WHERE id = " .. row.id)
			-- processLKPLine(LKPLine)
		-- end
	-- end
end


function miscCommandsTimer()
	local cursor, errorString, row, temp, steam, action, value, command

	if botman.miscQueueEmpty == nil then
		botman.miscQueueEmpty = false
	end

	if botman.miscQueueEmpty then
		return
	end

	cursor,errorString = connSQL:execute("SELECT * FROM miscQueue LIMIT 1")

	if cursor then
		row = cursor:fetch({}, "a")

		if not row then
			botman.miscQueueEmpty = true
		end
	end

	cursor,errorString = connSQL:execute("SELECT * FROM miscQueue WHERE timerDelay = 0  ORDER BY id LIMIT 1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			steam = row.steam
			action = row.action
			value = row.value
			command = row.command
			connSQL:execute("DELETE FROM miscQueue WHERE id = " .. row.id)

			if command == "archive player" then
				conn:execute("INSERT INTO playersArchived SELECT * FROM players WHERE steam = '" .. steam .. "'")
				conn:execute("DELETE FROM players WHERE steam = '" .. steam .. "'")
				players[steam] = nil
				loadPlayersArchived(steam)
			else
				sendCommand(command)
			end
		end
	end

	-- check all the delayed commands.  send any that are not in the future
	cursor,errorString = connSQL:execute("SELECT id, steam, command, action, value, timerDelay FROM miscQueue WHERE timerDelay <> 0 ORDER BY id LIMIT 1")

	if cursor then
		row = cursor:fetch({}, "a")

		if row then
			steam = row.steam
			action = row.action
			value = row.value
			command = row.command

			if row.timerDelay - os.time() <= 0 then
				command = row.command
				connSQL:execute("DELETE FROM miscQueue WHERE id = " .. row.id)
				sendCommand(command)
			end
		end
	end
end
