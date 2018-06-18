--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function CheckInventory()
	local temp, table1, table2, items, d1, changes, debug, tmp, max, search, k, v

	-- newPlayer, ban, timeout, move, newItems, reason, moveTo, moveReason, banReason, timeoutReason, flag, dbFlag, badItemsFound
	-- flags, delta, playerAccessLevel, inventoryChanged

	debug = false

	if  debug then dbug("debug check inventory line " .. debugger.getinfo(1).currentline, true) end

	-- do a quick sanity check to prevent a rare fault causing this to get stuck
	for k, v in pairs(igplayers) do
		if players[k] == nil then
			igplayers[k] = nil
		end
	end

	for k, v in pairs(igplayers) do
		if debug then dbug(k .. " " .. v.name) end

		tmp = {}
		tmp.playerAccessLevel = accessLevel(k)
		tmp.ban = false
		tmp.banReason = ""
		tmp.timeout = false
		tmp.timeoutReason = ""
		tmp.move = false
		tmp.moveTo = ""
		tmp.moveReason = ""
		tmp.newPlayer = false
		tmp.badItemsFound = ""
		tmp.watchPlayer = players[k].watchPlayer
		tmp.newItems = ""
		tmp.delta = 0
		tmp.inventoryChanged = false
		tmp.flags = ""
		tmp.dbFlag = ""

		if v.inLocation ~= "" then
			if locations[v.inLocation].watchPlayers and tmp.playerAccessLevel > 2 then
				tmp.watchPlayer = true
			end
		end

		temp = {}
		items = {}
		changes = {}
		players[k].overstack = false
		players[k].overstackItems = ""
		v.illegalInventory = false

		if  debug then dbug("debug check inventory line " .. debugger.getinfo(1).currentline, true) end

		if (tonumber(players[k].timeOnServer) + tonumber(v.sessionPlaytime) < (tonumber(server.newPlayerTimer) * 60) ) then
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

		if v.raiding == true then
			tmp.flags = tmp.flags .. "RAID " .. v.raidingBase .. "|"
			tmp.dbFlag = "R"
		end

		if  debug then dbug("debug check inventory line " .. debugger.getinfo(1).currentline, true) end

		if (v.inventory ~= "") then
			table1 = string.split(v.inventory, "|")

			max = table.maxn(table1)
			for i = 1, max do
				if table1[i] ~= "" then
					table2 = string.split(table1[i], ",")

					if (badItems[table2[2]]) and (tmp.playerAccessLevel > 2 or botman.ignoreAdmins == false) and (not players[k].ignorePlayer) and (server.gameType ~= "cre") then
						tmp.dbFlag = tmp.dbFlag .. "B"

						v.illegalInventory = true
						if badItems[table2[2]].action == "ban" then
							tmp.ban = true
							tmp.banReason = "Bad items found in inventory"

							if v.raiding then
								tmp.banReason = "Bad items found in inventory while base raiding"
							end
						end

						if badItems[table2[2]].action == "exile" then
							tmp.move = true
							tmp.moveTo = "exile"

							if tmp.moveReason == nil then
								tmp.moveReason = "Bad items found " .. b.item .. "(" .. b.quantity .. ")"

								if v.raiding then
									tmp.moveReason = "Bad items found while raiding "
								end
							else
								tmp.moveReason = tmp.moveReason .. ", " .. b.item .. "(" .. b.quantity .. ")"
							end
						end

						if tmp.badItemsFound == "" then
							tmp.badItemsFound = table2[2] .. "(" .. table2[1] .. ")"
						else
							tmp.badItemsFound = badItemsFound .. ", " .. table2[2] .. "(" .. table2[1] .. ")"
						end

						-- check for wildcard items in badItems and search for those
						for a,b in pairs(badItems) do
							if string.find(a, "*", nil, true) then
								search = a:gsub('%W','')
								if string.find(v.inventory, search) then
									tmp.timeout = true
									tmp.timeoutReason = "Restricted items found in inventory"

									if tmp.badItemsFound == "" then
										tmp.badItemsFound = a
									else
										tmp.badItemsFound = tmp.badItemsFound .. ", " .. a
									end
								end
							end
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
					if (stackLimits[table2[2]] ~= nil) and (tmp.playerAccessLevel > 2 or botman.ignoreAdmins == false) and (server.gameType ~= "cre") and (not players[k].ignorePlayer) and not server.allowOverstacking then
						if tonumber(table2[1]) > tonumber(stackLimits[table2[2]].limit) * 2 and tonumber(table2[1]) > 1000 then
							if (players[k].overstackScore < 0) then
								players[k].overstackScore = 0
							end

							if not server.allowOverstacking then
								players[k].overstack = true
								players[k].overstackItems = players[k].overstackItems .. " " .. table2[2] .. " (" .. table2[1] .. ")"
								players[k].overstackScore = players[k].overstackScore + 1
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

			if v.raiding and tmp.timeout then
				players[k].exiled = 1
				if tmp.playerAccessLevel > 2 then players[k].silentBob = true end
				players[k].canTeleport = false

				irc_chat(server.ircMain, "Exiling " .. v.name .. " detected with bad inventory while raiding.")
				irc_chat(server.ircAlerts, "Exiling " .. v.name .. " detected with bad inventory while raiding.")
			end

			if  debug then dbug("debug check inventory line " .. debugger.getinfo(1).currentline, true) end

			for a, b in pairs(items) do
				if tmp.newPlayer and b.dupe > 15 then
					if not v.dupeItem then
						v.dupeItem = b.item
						irc_chat(server.ircAlerts, "New player " .. players[k].name .. " has " .. b.dupe .. " x 1 of " .. b.item)
					end

					if b.item ~= v.dupeItem then
						v.dupeItem = b.item
						irc_chat(server.ircAlerts, "New player " .. players[k].name .. " has " .. b.dupe .. " x 1 of " .. b.item)
					end
				end

				if (tmp.newPlayer == true and v.skipExcessInventory ~= true) and (server.gameType ~= "cre") then
					cursor,errorString = conn:execute("SELECT * FROM memRestrictedItems where item = '" .. escape(b.item) .. "' and accessLevel < " .. tmp.playerAccessLevel)
					rows = cursor:numrows()

					if tonumber(rows) > 0 then
						row = cursor:fetch({}, "a")

						if tonumber(b.quantity) > tonumber(row.qty) and (not players[k].ignorePlayer) then
							if row.action == "timeout" and server.gameType ~= "pvp" then
								tmp.timeout = true

								if tmp.timeoutReason == nil then
									tmp.timeoutReason = "excessive inventory for a new player " .. b.item .. "(" .. b.quantity .. ")"
								else
									tmp.timeoutReason = tmp.timeoutReason .. ", " .. b.item .. "(" .. b.quantity .. ")"
								end
							end

							if row.action == "exile" then
								tmp.move = true
								tmp.moveTo = "exile"

								if tmp.moveReason == nil then
									tmp.moveReason = "Restricted items found " .. b.item .. "(" .. b.quantity .. ")"

									if v.raiding then
										tmp.moveReason = "Restricted items found while raiding "
									end
								else
									tmp.moveReason = tmp.moveReason .. ", " .. b.item .. "(" .. b.quantity .. ")"
								end
							end

							if row.action == "ban" then
								tmp.ban = true

								if tmp.banReason == nil then
									tmp.banReason = "bad inventory " .. b.item .. "(" .. b.quantity .. ")"
								else
									tmp.banReason = tmp.banReason .. ", " .. b.item .. "(" .. b.quantity .. ")"
								end
							end

							if locations[row.action] then
								tmp.move = true
								tmp.moveTo = row.action

								if moveReason == nil then
									tmp.moveReason = "excessive inventory for a new player " .. b.item .. "(" .. b.quantity .. ")"
								else
									tmp.moveReason = tmp.moveReason .. ", " .. b.item .. "(" .. b.quantity .. ")"
								end
							end

							if row.action == "watch" then
								irc_chat(server.ircWatch, "Player " .. v.name .. " has " .. b.quantity .. " of " .. b.item)
							end
						end
					end
				end
			end

			if  debug then dbug("debug check inventory line " .. debugger.getinfo(1).currentline, true) end

			if tablelength(invTemp[k]) == 0 then
				invTemp[k] = items
			end

			if  debug then dbug("debug check inventory line " .. debugger.getinfo(1).currentline, true) end

			tmp.flag = ""

			for a, b in pairs(invTemp[k]) do
				if items[b.item] == nil then
					items[b.item] = {}
					items[b.item].item = b.item
					items[b.item].quantity = 0

					if badItems[b.item] then
						tmp.flag = "B"
					end

					if v.raiding then
						tmp.flag = tmp.flag .. "R"
					end
				end

				if tonumber(b.quantity) ~= tonumber(items[a].quantity) then
					tmp.inventoryChanged = true
					table.insert(changes, { b.item, tonumber(items[a].quantity) - tonumber(b.quantity) } )
					conn:execute("INSERT INTO inventoryChanges (steam, item, delta, x, y, z, session, flag) VALUES (" .. k .. ",'" .. escape(b.item) .. "'," .. tonumber(items[a].quantity) - tonumber(b.quantity) .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. tmp.flag .. "')")

					v.afk = os.time() + 900

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

						-- list beds for this player if they drop 1 bed
						if b.item == "bedroll" and tmp.delta == -1 and server.coppi then
							send("lpb " .. k)

							if botman.getMetrics then
								metrics.telnetCommands = metrics.telnetCommands + 1
							end
						end
					end

					if (players[k].watchPlayer or tmp.watchPlayer) then
						cursor,errorString = conn:execute("SELECT * FROM memRestrictedItems where item = '" .. escape(b.item) .. "' and action = 'watch'")
						row = cursor:fetch({}, "a")
						if row then
							if (b.item == row.item) and not string.find(newItems, b.item, nil, true) then
								tmp.newItems = tmp.newItems .. row.item .. " (" .. tmp.delta .. "), "
							end
						end

						if tonumber(tmp.delta) > 0 and tmp.newPlayer == true and not string.find(tmp.newItems, b.item, nil, true) then
							tmp.newItems = tmp.newItems .. b.item .. " (" .. tmp.delta .. "), "
						end

						if (b.item == "keystoneBlock") and not string.find(tmp.newItems, b.item, nil, true) then
							tmp.newItems = tmp.newItems .. "keystoneBlock (" .. tmp.delta .. "), "

							if tonumber(tmp.delta) < 0 then
								players[k].keystones = 0

								if not server.lagged then
									send("llp " .. k)

									if botman.getMetrics then
										metrics.telnetCommands = metrics.telnetCommands + 1
									end
								end
							end
						end
					end
				end
			end

			if  debug then dbug("debug check inventory line " .. debugger.getinfo(1).currentline, true) end

			if (players[k].watchPlayer) and not server.disableWatchAlerts then
				if tmp.newItems ~= "" then
					alertAdmins("Watched player " .. v.id .. " " .. v.name .. " " .. tmp.newItems)
				end
			end

			if  debug then dbug("debug check inventory line " .. debugger.getinfo(1).currentline, true) end

			if tmp.inventoryChanged == true or (v.oldBelt ~= v.belt) then
				conn:execute("INSERT INTO inventoryTracker (steam, x, y, z, session, belt, pack, equipment) VALUES (" .. k .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. escape(v.belt) .. "','" .. escape(v.pack) .. "','" .. escape(v.equipment) .. "')")
				invTemp[k] = items

				if tmp.inventoryChanged == true then
					if players[k].timeOnServer == nil or v.watchPlayer or v.raiding or tmp.watchPlayer then
						for q, w in pairs(changes) do
							irc_chat(server.ircWatch, string.trim(tmp.flags .. " " .. v.name .. "  " .. w[1] .. "  " .. w[2] .. "  [ " .. math.floor(v.xPos) .. " " .. math.ceil(v.yPos) .. " " .. math.floor(v.zPos)) .. " ]")
						end
					else
						if tmp.playerAccessLevel > 2 and tonumber(players[k].timeOnServer) < tonumber(server.newPlayerTimer)  then
							for q, w in pairs(changes) do
								irc_chat(server.ircWatch, string.trim(tmp.flags .. " " .. v.name .. "  " .. w[1] .. "   " .. w[2] .. "  [ " .. math.floor(v.xPos) .. " " .. math.ceil(v.yPos) .. " " .. math.floor(v.zPos)) .. " ]")
							end
						end
					end
				end
			end
		end

		v.oldBelt = v.belt

		if  debug then dbug("debug check inventory line " .. debugger.getinfo(1).currentline, true) end

		tmp.changes = nil

		if (players[k].overstack == false) then
			players[k].overstackScore = 0
		end

		if not server.allowOverstacking and (server.gameType ~= "cre") then
			if (players[k].overstack == true) and (tmp.playerAccessLevel > 2 or botman.ignoreAdmins == false) then
				message("pm " .. k .. " [" .. server.chatColour .. "]You are overstacking items in your inventory - " .. players[k].overstackItems .. "[-]")
				irc_chat(server.ircWatch, v.name .. " is overstacking " .. players[k].overstackItems)
			end

			if (tonumber(players[k].overstackScore) == 2) and (players[k].botTimeout == false) then
				message("pm " .. k .. " [" .. server.chatColour .. "]If you do not stop overstacking, you will be sent to timeout.  Fix your inventory now.[-]")
			end

			if tonumber(players[k].overstackScore) > 4 and (players[k].botTimeout == false) then
				players[k].botTimeout = true
				players[k].xPosTimeout = math.floor(players[k].xPos)
				players[k].yPosTimeout = math.ceil(players[k].yPos)
				players[k].zPosTimeout = math.floor(players[k].zPos)

				message("say [" .. server.chatColour .. "]" .. v.name .. " is in timeout for ignoring overstack warnings.[-]")
				message("pm " .. k .. " [" .. server.chatColour .. "]You are still overstacking items. You will stay in timeout until you are not overstacking.[-]")
				irc_chat(server.ircWatch, "[TIMEOUT] " .. k .. " " .. v.name .. " is in timeout for overstacking the following " .. players[k].overstackItems)
				irc_chat(server.ircAlerts, "[TIMEOUT] " .. k .. " " .. v.name .. " is in timeout for overstacking the following " .. players[k].overstackItems)

				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(v.name) .. " is in timeout for overstacking the following " .. escape(players[k].overstackItems) .. "'," .. k .. ")")
			end
		end

		if (ban == true) and (server.gameType ~= "cre") then
			if tmp.playerAccessLevel > 2 then
				banPlayer(k, "1 year", tmp.banReason, "")

				message("say [" .. server.chatColour .. "]Banning player " .. v.name .. " 1 year for suspected inventory cheating.[-]")
				irc_chat(server.ircMain, "[BANNED] Player " .. k .. " " .. v.name .. " has has been banned for " .. tmp.banReason .. ".")
				irc_chat(server.ircAlerts, "[BANNED] Player " .. k .. " " .. v.name .. " has has been banned for 1 year for " .. tmp.banReason .. ".")
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. ",'" .. botman.serverTime .. "','ban','Player " .. k .. " " .. escape(v.name) .. " has has been banned for 1 year for " .. escape(tmp.banReason) .. ".'," .. k .. ")")

				if botman.db2Connected then
					-- copy in bots db
					connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','ban','Player " .. k .. " " .. escape(v.name) .. " has has been banned for 1 year for " .. escape(tmp.banReason) .. ".'," .. k .. ")")
				end
			end
		end

		if (tmp.timeout == true) and (server.gameType ~= "cre") then
			v.illegalInventory = true
			conn:execute("INSERT INTO inventoryTracker (steam, x, y, z, session, belt, pack, equipment) VALUES (" .. k .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. escape(v.belt) .. "','" .. escape(v.pack) .. "','" .. escape(v.equipment) .. "')")
			timeoutPlayer(k, tmp.timeoutReason, true)
		end

		if (tmp.move == true and players[k].exiled ~= 1) and (server.gameType ~= "cre") then
			message("say [" .. server.chatColour .. "]Sending player " .. v.name .. " to " .. tmp.moveTo .. " for " .. tmp.moveReason .. ".[-]")

			teleport("tele " .. k .. " " .. locations[tmp.moveTo].x .. " " .. locations[tmp.moveTo].y + 1 .. " " .. locations[tmp.moveTo].z, k)

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			players[k].exiled = 1
			if tmp.playerAccessLevel > 2 then players[k].silentBob = true end
			players[k].canTeleport = false
			irc_chat(server.ircMain, "Moving player " .. k .. " " .. v.name .. " to " .. tmp.moveTo .. " for " .. tmp.moveReason .. ".")
			irc_chat(server.ircAlerts, "Moving player " .. k .. " " .. v.name .. " to " .. tmp.moveTo .. " for " .. tmp.moveReason .. ".")
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. ",'" .. botman.serverTime .. "','exile','Player " .. k .. " " .. escape(v.name) .. " has has been exiled to " .. escape(tmp.moveTo) .. " for " .. escape(tmp.moveReason) .. ".'," .. k .. ")")
		end

		if  debug then dbug("debug check inventory line " .. debugger.getinfo(1).currentline, true) end

		if (not players[k].ignorePlayer) and (server.gameType ~= "cre") then
			if tmp.badItemsFound ~= "" then
				v.illegalInventory = true

				if (players[k].timeout == false) and (tmp.playerAccessLevel > 2 or botman.ignoreAdmins == false) then
					players[k].timeout = true
					players[k].botTimeout = true
					players[k].xPosTimeout = math.floor(players[k].xPos)
					players[k].yPosTimeout = math.ceil(players[k].yPos)
					players[k].zPosTimeout = math.floor(players[k].zPos)

					if tmp.playerAccessLevel > 2 then players[k].silentBob = true end
					message("say [" .. server.chatColour .. "]" .. v.name .. " is in timeout for uncraftable items " .. tmp.badItemsFound .. ".[-]")
					message("pm " .. k .. " [" .. server.chatColour .. "]You have items in your inventory that are not permitted.[-]")
					message("pm " .. k .. " [" .. server.chatColour .. "]You must drop them if you wish to return to the game.[-]")

					irc_chat(server.ircMain, v.name .. " detected with uncraftable " .. tmp.badItemsFound)
					irc_chat(server.ircAlerts, v.name .. " detected with uncraftable " .. tmp.badItemsFound)
					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event) VALUES (" .. math.floor(igplayers[k].xPos) .. "," .. math.ceil(igplayers[k].yPos) .. "," .. math.floor(igplayers[k].zPos) .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(v.name) .. " detected with uncraftable inventory " .. escape(tmp.badItemsFound) .. "')")

					if botman.db2Connected then
						-- copy in bots db
						connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','timeout','Player " .. escape(v.name) .. " detected with uncraftable inventory " .. escape(tmp.badItemsFound) .. "')")
					end

					break
				end
			end
		end

		if players[k].botTimeout == true and v.illegalInventory == false and players[k].overstack == false then
			players[k].silentBob = false
			players[k].overstackScore = 0
			message("pm " .. k .. " [" .. server.chatColour .. "]You are free to play again.[-]")
			players[k].xPosOld = 0
			players[k].yPosOld = 0
			players[k].zPosOld = 0
			v.lastLocation = ""
			gmsg(server.commandPrefix .. "return " .. v.name)
		end
	end

	if debug then dbug("check inventory end") end
end


function readInventorySlot()
	local timestamp, slot, item, quantity, quality, pos, words, dupeTest

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

	deleteLine()
end
