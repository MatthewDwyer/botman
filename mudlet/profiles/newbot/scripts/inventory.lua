--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
local debug = false -- should be false unless testing


function processPlayerInventory(steam)
	local temp, table1, table2, items, d1, changes, tmp, max, search, k, v, i, a, b, c, d, player

	player = igplayers[steam]

	if debug then dbug(steam .. " " .. player.name) end

	tmp = {}
	tmp.playerAccessLevel = accessLevel(steam, player.userID)
	tmp.ban = false
	tmp.banReason = ""
	tmp.timeout = false
	tmp.timeoutReason = ""
	tmp.move = false
	tmp.moveTo = ""
	tmp.moveReason = ""
	tmp.newPlayer = false
	tmp.badItemFound = false
	tmp.itemsFound = ""
	tmp.badItem = ""
	tmp.badItemAction = ""
	tmp.watchPlayer = players[steam].watchPlayer
	tmp.newItems = ""
	tmp.delta = 0
	tmp.inventoryChanged = false
	tmp.flags = ""
	tmp.dbFlag = ""
	tmp.stopProcessing = false
	tmp.admin = isAdminHidden(steam, player.userID)

	if debug then display(tmp) end

	if player.inLocation ~= "" then
		if locations[player.inLocation].watchPlayers and not tmp.admin then
			tmp.watchPlayer = true
		end
	end

	temp = {}
	items = {}
	changes = {}
	players[steam].overstack = false
	players[steam].overstackItems = ""
	igplayers[steam].illegalInventory = false

	if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end

	if (tonumber(players[steam].timeOnServer) + tonumber(player.sessionPlaytime) < (tonumber(server.newPlayerTimer) * 60) ) then
		tmp.newPlayer = true
	else
		tmp.newPlayer = false
	end

	if tmp.newPlayer == true then
		tmp.flags = "|NEW|"
	else
		if (tmp.watchPlayer == true) then
			tmp.flags = "|WAT|" -- watched
		end
	end

	if player.raiding == true then
		tmp.flags = tmp.flags .. " at base of " .. player.raidingBase .. " " .. players[player.raidingBase].name .. " "
		tmp.dbFlag = "R"
	end

	if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end

	if (player.inventory ~= "") then
		if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end
		table1 = string.split(player.inventory, "|")

		max = tablelength(table1)
		for i = 1, max do
			if table1[i] ~= "" then
				table2 = string.split(table1[i], ",")
				tmp.badItemFound = false
				tmp.badItem = ""

				-- check for wildcard items in badItems and search for those
				for a,b in pairs(badItems) do
					if string.find(a, "*", nil, true) then
						search = a:gsub('%W','')

						if string.find(table2[2], search) then
							tmp.badItemFound = true
							tmp.badItem = table2[2]
							tmp.badItemAction = b.action
							break
						end
					end
				end

				if (badItems[table2[2]] or tmp.badItemFound) and (not tmp.admin or botman.ignoreAdmins == false) and (not players[steam].ignorePlayer) and (server.gameType ~= "cre") then
					tmp.dbFlag = tmp.dbFlag .. "B"
					igplayers[steam].illegalInventory = true

					if badItems[table2[2]] then
						tmp.badItemFound = true
						tmp.badItemAction = badItems[table2[2]].action
						tmp.badItem = table2[2]

						if tmp.itemsFound == "" then
							tmp.itemsFound = table2[2] .. "(" .. table2[1] .. ")"
						else
							tmp.itemsFound = tmp.itemsFound .. ", " .. table2[2] .. "(" .. table2[1] .. ")"
						end
					else
						if tmp.badItemFound then
							if tmp.itemsFound == "" then
								tmp.itemsFound = tmp.badItem
							else
								tmp.itemsFound = tmp.itemsFound .. ", " .. tmp.badItem
							end
						end
					end

					if tmp.badItemAction == "ban" then
						tmp.ban = true
						tmp.banReason = "Bad item found in inventory"

						if player.raiding then
							tmp.banReason = "Bad item found in inventory while base raiding"
						end
					end

					if tmp.badItemAction == "exile" then
						tmp.move = true
						tmp.moveTo = "exile"

						if tmp.moveReason == nil then
							tmp.moveReason = "Bad items found " .. tmp.badItem .. "(" .. table2[1] .. ")"

							if player.raiding then
								tmp.moveReason = "Bad items found while raiding "
							end
						else
							tmp.moveReason = tmp.moveReason .. ", " .. tmp.badItem .. "(" .. table2[1] .. ")"
						end
					end

					if tmp.badItemAction == "timeout" then
						tmp.timeout = true
						tmp.timeoutReason = "Bad item found in inventory"
					end
				end

				if items[table2[2]] == nil then
					items[table2[2]] = {}
					items[table2[2]].item = table2[2]
					items[table2[2]].quantity = tonumber(table2[1])
					items[table2[2]].quality = tonumber(table2[3])
					items[table2[2]].dupe = 0

					if tonumber(table2[1]) == 1 then
						items[table2[2]].dupe = 1
					end
				else
					items[table2[2]].quantity = items[table2[2]].quantity + tonumber(table2[1])

					if tonumber(table2[1]) == 1 then
						items[table2[2]].dupe = items[table2[2]].dupe + 1
					end
				end

				-- stack monitoring
				if (stackLimits[table2[2]] ~= nil) and (not tmp.admin or botman.ignoreAdmins == false) and (server.gameType ~= "cre") and (not players[steam].ignorePlayer) and not server.allowOverstacking then
					if tonumber(table2[1]) > tonumber(stackLimits[table2[2]].limit) * 2 and tonumber(table2[1]) > 1000 then
						if (players[steam].overstackScore < 0) then
							players[steam].overstackScore = 0
						end

						if not server.allowOverstacking then
							players[steam].overstack = true
							players[steam].overstackItems = players[steam].overstackItems .. " " .. table2[2] .. " (" .. table2[1] .. ")"
							players[steam].overstackScore = players[steam].overstackScore + 1
						end
					end

					-- instant ban for a full stack of any of these if a new player
					if tonumber(table2[1]) >= tonumber(stackLimits[table2[2]].limit) and tmp.newPlayer == true then
						if (table2[2] == "tnt" or table2[2] == "mineAirFilter" or table2[2] == "mineHubcap" or table2[2] == "rScrapIronPlateMine") then
							tmp.ban = true
							tmp.banReason = "Banned for excessive amounts of " .. table2[2] .. "(" .. table2[1] .. ")."
						end
					end
				end
			end
		end

		if player.raiding and tmp.timeout then
			players[steam].exiled = true
			if not tmp.admin then players[steam].silentBob = true end
			players[steam].canTeleport = false

			irc_chat(server.ircMain, "Exiling " .. player.name .. " detected with bad inventory while raiding.")
			irc_chat(server.ircAlerts, server.gameDate .. " exiling " .. player.name .. " detected with bad inventory while raiding.")
			irc_chat(server.ircAlerts, server.gameDate .. " Items detected: " .. tmp.itemsFound)
		end

		if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end

		for a, b in pairs(items) do
			if tmp.newPlayer and b.dupe > 15 then
				if not player.dupeItem then
					player.dupeItem = b.item
					irc_chat(server.ircWatch, "New player " .. players[steam].name .. " has " .. b.dupe .. " x 1 of " .. b.item)
				end

				if b.item ~= player.dupeItem then
					player.dupeItem = b.item
					irc_chat(server.ircWatch, "New player " .. players[steam].name .. " has " .. b.dupe .. " x 1 of " .. b.item)
				end
			end

			if (player.skipExcessInventory ~= true) and (server.gameType ~= "cre") then
				if restrictedItems[a] then

		if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end

				if tonumber(b.quantity) > tonumber(restrictedItems[a].qty) and tonumber(tmp.playerAccessLevel) >= tonumber(restrictedItems[a].accessLevel) and (not players[steam].ignorePlayer) then
if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end
						if restrictedItems[a].action == "timeout" and server.gameType ~= "pvp" then
if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end
							tmp.timeout = true

							if tmp.timeoutReason == nil then
								tmp.timeoutReason = "excessive inventory for a new player " .. a .. "(" .. b.quantity .. ")"
							else
								tmp.timeoutReason = tmp.timeoutReason .. ", " .. a .. "(" .. b.quantity .. ")"
							end
						end
if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end
						if restrictedItems[a].action == "exile" then
							tmp.move = true
							tmp.moveTo = "exile"

							if tmp.moveReason == nil then
								tmp.moveReason = "Restricted items found " .. a .. "(" .. b.quantity .. ")"

								if player.raiding then
									tmp.moveReason = "Restricted items found while raiding "
								end
							else
								tmp.moveReason = tmp.moveReason .. ", " .. a .. "(" .. b.quantity .. ")"
							end
						end
if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end
						if restrictedItems[a].action == "ban" then
							tmp.ban = true

							if tmp.banReason == nil then
								tmp.banReason = "bad inventory " .. a .. "(" .. b.quantity .. ")"
							else
								tmp.banReason = tmp.banReason .. ", " .. a .. "(" .. b.quantity .. ")"
							end
						end
if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end
						if locations[restrictedItems[a].action] then
							tmp.move = true
							tmp.moveTo = row.action

							if moveReason == nil then
								tmp.moveReason = "excessive inventory for a new player " .. a .. "(" .. b.quantity .. ")"
							else
								tmp.moveReason = tmp.moveReason .. ", " .. a .. "(" .. b.quantity .. ")"
							end
						end
if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end
						if restrictedItems[a].action == "watch" then
							if player.inLocation ~= "" then
								irc_chat(server.ircWatch, "Player " .. player.name .. " in " .. player.inLocation .. " " .. " has " .. b.quantity .. " of " .. a .. " @ " .. player.xPos .. " " .. player.yPos .. " " .. player.zPos)
							else
								irc_chat(server.ircWatch, "Player " .. player.name .. " " .. " has " .. b.quantity .. " of " .. a .. " @ " .. player.xPos .. " " .. player.yPos .. " " .. player.zPos)
							end
						end
					end
				end
			end
		end

		if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end

		if tablelength(invTemp[steam]) == 0 then
			invTemp[steam] = items
		end

		if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end

		tmp.flag = ""

		for a, b in pairs(invTemp[steam]) do
			if items[b.item] == nil then
				items[b.item] = {}
				items[b.item].item = b.item
				items[b.item].quantity = 0

				if badItems[b.item] then
					tmp.flag = "B"
				end

				if player.raiding then
					tmp.flag = tmp.flag .. "R"
				end
			end

			if tonumber(b.quantity) ~= tonumber(items[a].quantity) then
				tmp.inventoryChanged = true
				table.insert(changes, { b.item, tonumber(items[a].quantity) - tonumber(b.quantity) } )
				connINVDELTA:execute("INSERT INTO inventoryChanges (steam, timestamp, item, delta, x, y, z, session, flag) VALUES ('" .. steam .. "'," .. botman.serverTimeStamp .. ",'" .. connMEM:escape(b.item) .. "'," .. tonumber(items[a].quantity) - tonumber(b.quantity) .. "," .. player.xPos .. "," .. player.yPos .. "," .. player.zPos .. "," .. players[steam].sessionCount .. ",'" .. tmp.flag .. "')")

				if server.logInventory then
					logInventoryChanges(steam, b.item, tonumber(items[a].quantity) - tonumber(b.quantity), player.xPos, player.yPos, player.zPos,players[steam].sessionCount, tmp.flag)
				end

				igplayers[steam].afk = os.time() + tonumber(server.idleKickTimer)

				if (items[a] == nil) then
					d1 = 0
				else
					d1 = tonumber(items[a].quantity)
				end

				tmp.delta = d1 - tonumber(b.quantity)
				if tonumber(tmp.delta) > 0 then
					tmp.delta = "+" .. tmp.delta
				else
					tmp.delta = tmp.delta
				end

				if (players[steam].watchPlayer or tmp.watchPlayer) then
					if restrictedItems[b.item] then
						if restrictedItems[b.item].action == "watch" then
							if not string.find(newItems, b.item, nil, true) then
								tmp.newItems = tmp.newItems .. b.item .. " (" .. tmp.delta .. "), "
							end
						end
					end

					if tonumber(tmp.delta) > 0 and tmp.newPlayer == true and not string.find(tmp.newItems, b.item, nil, true) then
						tmp.newItems = tmp.newItems .. b.item .. " (" .. tmp.delta .. "), "
					end

					if (b.item == "keystoneBlock") and not string.find(tmp.newItems, b.item, nil, true) then
						tmp.newItems = tmp.newItems .. "keystoneBlock (" .. tmp.delta .. "), "
					end
				end
			end
		end

		if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end

		if (players[steam].watchPlayer) and not server.disableWatchAlerts then
			if tmp.newItems ~= "" then
				alertAdmins("Watched player " .. player.id .. " " .. player.name .. " " .. tmp.newItems)
			end
		end

		if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end

		if tmp.inventoryChanged == true or (player.oldBelt ~= player.belt) or (player.oldPack ~= player.pack) or (player.oldEquipment ~= player.equipment) then
		if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end
			cursor,errorString = connINVTRAK:execute("INSERT INTO inventoryTracker (steam, timestamp, x, y, z, session, belt, pack, equipment) VALUES ('" .. steam .. "'," .. botman.serverTimeStamp .. "," .. player.xPos .. "," .. player.yPos .. "," .. player.zPos .. "," .. players[steam].sessionCount .. ",'" .. escape(player.belt) .. "','" .. escape(player.pack) .. "','" .. escape(player.equipment) .. "')")

		if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end
			invTemp[steam] = items
		if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end
			if tmp.inventoryChanged == true then
		if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end
				if players[steam].timeOnServer == nil or player.watchPlayer or player.raiding or tmp.watchPlayer then
					for q, w in pairs(changes) do
						if player.inLocation ~= "" then
							irc_chat(server.ircWatch, string.trim(botman.serverTime .. " " .. server.gameDate .. " " .. player.name .. " " .. tmp.flags .. " in " .. player.inLocation .. " " .. w[1] .. "  " .. w[2] .. " @ " .. player.xPos .. " " .. player.yPos .. " " .. player.zPos))
						else
							irc_chat(server.ircWatch, string.trim(botman.serverTime .. " " .. server.gameDate .. " " .. player.name .. " " .. tmp.flags .. " " .. w[1] .. "  " .. w[2] .. " @ " .. player.xPos .. " " .. player.yPos .. " " .. player.zPos))
						end
					end
				else
					if not tmp.admin and tonumber(players[steam].timeOnServer) < tonumber(server.newPlayerTimer)  then
						for q, w in pairs(changes) do
							if player.inLocation ~= "" then
								irc_chat(server.ircWatch, string.trim(botman.serverTime .. " " .. server.gameDate .. " " .. player.name .. " " .. tmp.flags .. " in " .. player.inLocation .. " " .. w[1] .. "   " .. w[2] .. "  @ " .. player.xPos .. " " .. player.yPos .. " " .. player.zPos))
							else
								irc_chat(server.ircWatch, string.trim(botman.serverTime .. " " .. server.gameDate .. " " .. player.name .. " " .. tmp.flags .. " " .. w[1] .. "   " .. w[2] .. " @ " .. player.xPos .. " " .. player.yPos .. " " .. player.zPos))
							end
						end
					end
				end
			end
		end
	end

--display(tmp)

	igplayers[steam].oldBelt = player.belt

	if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end

	tmp.changes = nil

	if (players[steam].overstack == false) then
		players[steam].overstackScore = 0
	end

	if not server.allowOverstacking and (server.gameType ~= "cre") then
		if (players[steam].overstack == true) and (not tmp.admin or botman.ignoreAdmins == false) then
			message("pm " .. player.userID .. " [" .. server.chatColour .. "]You are overstacking items in your inventory - " .. players[steam].overstackItems .. "[-]")
			if player.inLocation ~= "" then
				irc_chat(server.ircWatch, botman.serverTime .. " " .. server.gameDate .. " " .. player.name .. " is overstacking " .. players[steam].overstackItems .. " in " .. player.inLocation .. " @ " .. player.xPos .. " " .. player.yPos .. " " .. player.zPos)
			else
				irc_chat(server.ircWatch, botman.serverTime .. " " .. server.gameDate .. " " .. player.name .. " is overstacking " .. players[steam].overstackItems .. "  at " .. player.xPos .. " " .. player.yPos .. " " .. player.zPos)
			end
		end

		if (tonumber(players[steam].overstackScore) == 2) and (players[steam].botTimeout == false) then
			message("pm " .. player.userID .. " [" .. server.chatColour .. "]If you do not stop overstacking, you will be sent to timeout.  Fix your inventory now.[-]")
		end

		if tonumber(players[steam].overstackScore) > 4 and (players[steam].botTimeout == false) then
			players[steam].botTimeout = true
			players[steam].xPosTimeout = players[steam].xPos
			players[steam].yPosTimeout = players[steam].yPos
			players[steam].zPosTimeout = players[steam].zPos

			message("say [" .. server.chatColour .. "]" .. player.name .. " is in timeout for ignoring overstack warnings.[-]")
			message("pm " .. player.userID .. " [" .. server.chatColour .. "]You are still overstacking items. You will stay in timeout until you are not overstacking.[-]")
			irc_chat(server.ircWatch, botman.serverTime .. " " .. server.gameDate .. " [TIMEOUT] " .. steam .. " " .. player.name .. " is in timeout for overstacking the following " .. players[steam].overstackItems)
			irc_chat(server.ircAlerts, botman.serverTime .. " " .. server.gameDate .. " [TIMEOUT] " .. steam .. " " .. player.name .. " is in timeout for overstacking the following " .. players[steam].overstackItems)

			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. player.xPos .. "," .. player.yPos .. "," .. player.zPos .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(player.name) .. " is in timeout for overstacking the following " .. escape(players[steam].overstackItems) .. "'," .. steam .. ")")
		end
	end

	if (tmp.ban) and (server.gameType ~= "cre") then
		if not tmp.admin then
			tmp.stopProcessing = true
			banPlayer(player.platform, player.userID, steam, "1 year", tmp.banReason, "")

			message("say [" .. server.chatColour .. "]Banning player " .. player.name .. " 1 year for suspected inventory cheating.[-]")
			irc_chat(server.ircMain, "[BANNED] Player " .. steam .. " " .. player.name .. " has has been banned for " .. tmp.banReason .. ".")
			irc_chat(server.ircAlerts, botman.serverTime .. " " .. server.gameDate .. " [BANNED] Player " .. steam .. " " .. player.name .. " has has been banned for 1 year for " .. tmp.banReason .. ".")
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. player.xPos .. "," .. player.yPos .. "," .. player.zPos .. ",'" .. botman.serverTime .. "','ban','Player " .. steam .. " " .. escape(player.name) .. " has has been banned for 1 year for " .. escape(tmp.banReason) .. ".'," .. steam .. ")")

			if botman.botsConnected then
				-- copy in bots db
				connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','ban','Player " .. steam .. " " .. escape(player.name) .. " has has been banned for 1 year for " .. escape(tmp.banReason) .. ".'," .. steam .. ")")
			end

			irc_chat(server.ircAlerts, server.gameDate .. " Items detected: " .. tmp.itemsFound)
		end
	end

	if tmp.move == true and (server.gameType ~= "cre") and not tmp.stopProcessing then
		if not players[steam].exiled then
			players[steam].exiled = true
			if not tmp.admin then players[steam].silentBob = true end
			players[steam].canTeleport = false
			irc_chat(server.ircMain, "Moving player " .. steam .. " " .. player.name .. " to " .. tmp.moveTo .. " for " .. tmp.moveReason .. ".")
			irc_chat(server.ircAlerts, server.gameDate .. " moving player " .. steam .. " " .. player.name .. " to " .. tmp.moveTo .. " for " .. tmp.moveReason .. ".")
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. player.xPos .. "," .. player.yPos .. "," .. player.zPos .. ",'" .. botman.serverTime .. "','exile','Player " .. steam .. " " .. escape(player.name) .. " has has been exiled to " .. escape(tmp.moveTo) .. " for " .. escape(tmp.moveReason) .. ".'," .. steam .. ")")
			irc_chat(server.ircAlerts, server.gameDate .. " Items detected: " .. tmp.itemsFound)
			teleport("tele " .. player.userID .. " " .. locations[tmp.moveTo].x .. " " .. locations[tmp.moveTo].y + 1 .. " " .. locations[tmp.moveTo].z, steam)
			message("say [" .. server.chatColour .. "]Sending player " .. player.name .. " to " .. tmp.moveTo .. " for " .. tmp.moveReason .. ".[-]")
		end

		tmp.stopProcessing = true
	end

	if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end

	if (not players[steam].ignorePlayer) and (server.gameType ~= "cre") and not players[steam].botTimeout then
		if tmp.itemsFound ~= "" then
			igplayers[steam].illegalInventory = true

			if (players[steam].timeout == false) and (not tmp.admin or botman.ignoreAdmins == false) and not tmp.stopProcessing then
				players[steam].botTimeout = true
				players[steam].xPosTimeout = players[steam].xPos
				players[steam].yPosTimeout = players[steam].yPos
				players[steam].zPosTimeout = players[steam].zPos

				if not tmp.admin then players[steam].silentBob = true end
				message("say [" .. server.chatColour .. "]" .. player.name .. " is in timeout for uncraftable items " .. tmp.itemsFound .. ".[-]")
				message("pm " .. player.userID .. " [" .. server.chatColour .. "]You have items in your inventory that are not permitted.[-]")
				message("pm " .. player.userID .. " [" .. server.chatColour .. "]You must drop them if you wish to return to the game.[-]")

				irc_chat(server.ircMain, player.name .. " detected with uncraftable " .. tmp.itemsFound)
				irc_chat(server.ircAlerts, botman.serverTime .. " " .. server.gameDate .. " " .. player.name .. " detected with uncraftable " .. tmp.itemsFound)
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event) VALUES (" .. igplayers[steam].xPos .. "," .. igplayers[steam].yPos .. "," .. igplayers[steam].zPos .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(player.name) .. " detected with uncraftable inventory " .. escape(tmp.itemsFound) .. "')")

				if botman.botsConnected then
					-- copy in bots db
					connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','timeout','Player " .. escape(player.name) .. " detected with uncraftable inventory " .. escape(tmp.itemsFound) .. "')")
				end
			end
		end
	end

	if debug then dbug("debug processPlayerInventory line " .. debugger.getinfo(1).currentline, true) end

	if players[steam].botTimeout == true and igplayers[steam].illegalInventory == false and players[steam].overstack == false then
		players[steam].silentBob = false
		players[steam].overstackScore = 0
		message("pm " .. player.userID .. " [" .. server.chatColour .. "]You are free to play again.[-]")
		players[steam].xPosOld = 0
		players[steam].yPosOld = 0
		players[steam].zPosOld = 0
		igplayers[steam].lastLocation = ""
		gmsg(server.commandPrefix .. "return " .. player.userID)
	end

	igplayers[steam] = player
end



function CheckInventory()
	local k, v

	if debug then dbug("check inventory start") end

	-- do a quick sanity check to prevent a rare fault causing this to get stuck
	for k, v in pairs(igplayers) do
		if players[k] == nil then
			igplayers[k] = nil
		end
	end

	for k, v in pairs(igplayers) do
		if debug then dbug("CheckInventory steam = " .. k) end
		pcall(processPlayerInventory, k)
	end

	if debug then dbug("check inventory end") end
end


function readInventorySlot()
	local timestamp, slot, item, quantity, quality, pos, words, dupeTest

	if server.useAllocsWebAPI then
		return
	end

	if not (string.find(line, "Slot") and string.find(line, ": ")) then
		-- abort if the line isn't actually a player's inventory
		return
	end

	timestamp = os.time()
	item = ""
	slot = ""
	quantity = 0
	quality = 0
	words = {}
	dupeTest = {}

	for word in line:gmatch("%w+") do table.insert(words, word) end

	slot = string.sub(line, string.find(line, "Slot") + 5, string.find(line, ": ") - 1)

	if string.find(line, "*") then
		slot = tonumber(slot)
		quantity = tonumber(string.sub(line, string.find(line, ":") + 2, string.find(line, "*") - 2))
		item = string.trim(string.sub(line, string.find(line, "* ") + 2))
	else
		quantity = 1
	end

	if string.find(line, "quality:") then
		quality = string.trim(string.sub(line, string.find(line, "quality: ") + 9))

		if string.find(line, "* ") then
			item = string.trim(string.sub(line, string.find(line, "* ") + 2, string.find(line, "quality:") - 4))
		else
			item = string.trim(string.sub(line, string.find(line, ": ") + 2, string.find(line, "quality:") - 4))
		end
	else
		if item == "" then
			item = string.trim(string.sub(line, string.find(line, ": ") + 2))
		end
	end

	if (invScan == "belt") then
		igplayers[invCheckID].inventory = igplayers[invCheckID].inventory .. quantity .. "," .. item .. "," .. quality .. "|"
		igplayers[invCheckID].belt = igplayers[invCheckID].belt .. slot .. "," .. quantity .. "," .. item .. "," .. quality .. "|"
	end

	if (invScan == "bagpack") then
		igplayers[invCheckID].inventory = igplayers[invCheckID].inventory .. quantity .. "," .. item .. "," .. quality .. "|"
		igplayers[invCheckID].pack = igplayers[invCheckID].pack .. slot .. "," .. quantity .. "," .. item .. "," .. quality .. "|"
	end

	if (invScan == "equipment") then
		igplayers[invCheckID].equipment = igplayers[invCheckID].equipment .. slot .. "," .. item .. "," .. quality .. "|"
	end
end
