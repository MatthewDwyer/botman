--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


local debug = false


function resetEquipmentSlots()
	equipmentSlots = { ["head"] = false, ["eyes"] = false, ["face"] = false, ["armor"] = false, ["jacket"] = false, ["shirt"] = false, ["legarmor"] = false, ["pants"] = false, ["boots"] = false, ["gloves"] = false }
end

if(not equipmentSlots) then
	resetEquipmentSlots()
end

function resetBeltSlots()
	beltSlots = {}

	for i=0, 7, 1 do
		beltSlots[i] = false
	end
end

if(not beltSlots) then
        resetBeltSlots()
end

function resetPackSlots()
	packSlots = {}

	for i=0, 31, 1 do
                packSlots[i] = false
        end
end

if(not packSlots) then
        resetPackSlots()
end


function CheckInventory()
	local temp, newPlayer, ban, timeout, move, newItems, table1, table2, items, reason, moveTo, moveReason, banReason, timeoutReason
	local d1, delta, inventoryChanged, changes, flags, badItemsFound, badItemAction, count500, dbFlag, tmp, flag, max, search
	local k, v

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	-- do a quick sanity check to prevent a rare fault causing this to get stuck
	for k, v in pairs(igplayers) do
		if players[k] == nil then
			igplayers[k] = nil
		end
	end

	for k, v in pairs(igplayers) do

		if debug then dbug(k .. " " .. v.name) end

		players[k].overstack = false
		players[k].overstackItems = ""
		ban = false
		timeout = false
		move = false
		newPlayer = false
		v.illegalInventory = false
		badItemsFound = ""
		count500 = 0


		if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	     if(igplayers[k] ~= nil) then
			if (tonumber(players[k].timeOnServer) + tonumber(igplayers[k].sessionPlaytime) < (tonumber(server.newPlayerTimer) * 60) ) then
				newPlayer = true
			else
				newPlayer = false
			end

		temp = {}
		items = {}
		changes = {}
		newItems = ""
		delta = 0
		inventoryChanged = false
		flags = ""
		dbFlag = ""

		if players[k].newPlayer == true then
			flags = "|NEW|"
		end

		if players[k].watchPlayer == true and players[k].newPlayer == false then
			flags = "|WAT|"
		end

		if v.raiding == true then
			flags = flags .. "RAID " .. v.raidingBase .. "|"
			dbFlag = "R"
		end

		if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if (igplayers[k].inventory ~= "") then

			if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Split inventory stirng: " .. igplayers[k].inventory) end

			table1 = string.split(igplayers[k].inventory, "|")

			max = table.maxn(table1)
			for i = 1, max do
				if table1[i] ~= "" then
					 if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Convert item entry to array: " .. table1[i]) end

					table2 = string.split(table1[i], ",")

					if (badItems[table2[2]]) and (accessLevel(k) > 2 or botman.ignoreAdmins == false) and (not players[k].ignorePlayer) then
						if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Bad item! (" .. table2[2] .. ")") end
						dbFlag = dbFlag .. "B"

						igplayers[k].illegalInventory = true
						if badItems[table2[2]].action == "ban" then
							if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Baning for bad item!") end
							ban = true
							banReason = "Bad items found in inventory"

							if v.raiding then
								banReason = "Bad items found in inventory while base raiding"
							end
						end

						if badItems[table2[2]].action == "exile" then
							if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Exiling due to bad item!") end
							move = true
							moveTo = "exile"

							if moveReason == nil then
								moveReason = "Bad items found " .. b.item .. "(" .. b.quantity .. ")"

								if v.raiding then
									moveReason = "Bad items found while raiding "
								end
							else
								moveReason = moveReason .. ", " .. b.item .. "(" .. b.quantity .. ")"
							end
						end

						if badItemsFound == "" then
							badItemsFound = table2[2] .. "(" .. table2[1] .. ")"
						else
							badItemsFound = badItemsFound .. ", " .. table2[2] .. "(" .. table2[1] .. ")"
						end

						-- check for wildcard items in badItems and search for those
						for a,b in pairs(badItems) do
							if string.find(a, "*", nil, true) then
								search = a:gsub('%W','')
								if string.find(igplayers[k].inventory, search) then
									timeout = true
									timeoutReason = "Restricted items found in inventory"

									if badItemsFound == "" then
										badItemsFound = a
									else
										badItemsFound = badItemsFound .. ", " .. a
									end
								end
							end
						end

					end

					if items[table2[2]] == nil then
						if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "add item(Slot: " .. (table2[4] or "nil") .. ", Qauntity: " .. (table2[1] or "nil") .. ", Item: " .. (table2[2] or "nil") .. ", Qaulity: " .. (table2[3] or "nil") .. ") to items table.") end
						items[table2[2]] = {}
						items[table2[2]].item = table2[2]
						items[table2[2]].quantity = (tonumber(table2[1]) or 0)
						items[table2[2]].quality = (tonumber(table2[3]) or 0)
						if(items[table2[2]].quality == nil and items[table2[2]].quantity > 0) then
							dbugFull("E", "", debugger.getinfo(1,"nSl"), "bad item quality (nil): " .. (items[table2[2]].item or "nil") .. ", " .. (items[table2[2]].quantity or "nil") .. ", " .. (items[table2[2]].quality or "nil"))
						elseif(items[table2[2]].qaulity == 0 and items[table2[2]].quantity > 0) then
							dbugFull("D", "", debugger.getinfo(1,"nSl"), "item quality is 0: " .. table2[2])
						end

						items[table2[2]].dupe = 0

						if tonumber(table2[1]) == 1 then
							items[table2[2]].dupe = 1
						end
					else
						if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Check existing item: " .. table2[2] .. ", Quantity: " .. table2[1]) end

						items[table2[2]].quantity = items[table2[2]].quantity + tonumber(table2[1])

						if tonumber(table2[1]) == 1 then
							items[table2[2]].dupe = items[table2[2]].dupe + 1
						end
					end

					-- stack monitoring
					if (stackLimits[table2[2]] ~= nil) and (accessLevel(k) > 2 or botman.ignoreAdmins == false) and (server.gameType ~= "cre") and (not players[k].ignorePlayer) and not server.allowOverstacking then
						if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Stack Monitoring") end
						if tonumber(table2[1]) > tonumber(stackLimits[table2[2]].limit) * 2 and tonumber(table2[1]) > 1000 then
							if (players[k].overstackScore < 0) then
								players[k].overstackScore = 0
							end

							if not server.allowOverstacking then
								if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Flagging player for overstacks: " .. players[k].name .. ", " .. k) end
								players[k].overstack = true
								players[k].overstackItems = players[k].overstackItems .. " " .. table2[2] .. " (" .. table2[1] .. ")"
								players[k].overstackScore = players[k].overstackScore + 1
							end
						end

						-- instant ban for a full stack of any of these if a new player
						if tonumber(table2[1]) >= tonumber(stackLimits[table2[2]].limit) and newPlayer == true then
							if (table2[2] == "tnt" or table2[2] == "keystoneBlock" or table2[2] == "mineAirFilter" or table2[2] == "mineHubcap" or table2[2] == "rScrapIronPlateMine") then
								if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Ban player(" .. players[k].name .. ") for overstack of: " .. table2[2]) end
								ban = true
								banReason = "Banned for excessive amounts of " .. table2[2] .. "(" .. table2[1] .. ")."
							end
						end
					end
				end
			end

			if v.raiding and timeout then
				local msg

				players[k].exiled = 1
				if accessLevel(k) > 2 then players[k].silentBob = true end
				players[k].canTeleport = false

				msg = "Exiling " .. igplayers[k].name .. " detected with bad inventory while raiding."
				irc_chat(server.ircMain, msg)
				irc_chat(server.ircAlerts, msg)
				alertAdmins(msg)
			end

		         if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
			for a, b in pairs(items) do
				if newPlayer and b.dupe > 15 then
					if not igplayers[k].dupeItem then
						local msg

						igplayers[k].dupeItem = b.item
						msg = "New player " .. players[k].name .. " has " .. b.dupe .. " x 1 of " .. b.item
						irc_chat(server.ircAlerts, msg)
						alertAdmins(msg)
					end

					if b.item ~= igplayers[k].dupeItem then
						local msg

						igplayers[k].dupeItem = b.item
						msg = "New player " .. players[k].name .. " has " .. b.dupe .. " x 1 of " .. b.item
						irc_chat(server.ircAlerts, msg)
						alertAdmins(msg)
					end
				end

				if (players[k].newPlayer == true and igplayers[k].skipExcessInventory ~= true) then

					cursor,errorString = conn:execute("SELECT * FROM memRestrictedItems where item = '" .. escape(b.item) .. "' and accessLevel < " .. players[k].accessLevel)
					rows = cursor:numrows()

					if tonumber(rows) > 0 then
						row = cursor:fetch({}, "a")

						if tonumber(b.quantity) > tonumber(row.qty) and (not players[k].ignorePlayer) then
							if row.action == "timeout" and server.gameType ~= "pvp" then
								timeout = true

								if timeoutReason == nil then
									timeoutReason = "excessive inventory for a new player " .. b.item .. "(" .. b.quantity .. ")"
								else
									timeoutReason = timeoutReason .. ", " .. b.item .. "(" .. b.quantity .. ")"
								end
							end

							if row.action == "exile" then
								move = true
								moveTo = "exile"

								if moveReason == nil then
									moveReason = "Restricted items found " .. b.item .. "(" .. b.quantity .. ")"

									if v.raiding then
										moveReason = "Restricted items found while raiding "
									end
								else
									moveReason = moveReason .. ", " .. b.item .. "(" .. b.quantity .. ")"
								end
							end

							if row.action == "ban" then
								ban = true

								if banReason == nil then
									banReason = "bad inventory " .. b.item .. "(" .. b.quantity .. ")"
								else
									banReason = banReason .. ", " .. b.item .. "(" .. b.quantity .. ")"
								end
							end

							if locations[row.action] then
								move = true
								moveTo = row.action

								if moveReason == nil then
									moveReason = "excessive inventory for a new player " .. b.item .. "(" .. b.quantity .. ")"
								else
									moveReason = moveReason .. ", " .. b.item .. "(" .. b.quantity .. ")"
								end
							end

							if row.action == "watch" then
								local msg = "Player " .. players[k].name .. " has " .. b.quantity .. " of " .. b.item
								irc_chat(server.ircWatch, msg)
								alertAdmins(msg)
							end

						end
					end
				end
			end

			if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

			if(not invTemp[k] or tablelength(invTemp[k]) == 0) then
				invTemp[k] = items
			end

			flag = ""

			for a, b in pairs(invTemp[k]) do
				if items[b.item] == nil then
					if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
					items[b.item] = {}
					items[b.item].item = b.item
					items[b.item].quantity = tonumber(b.qauntity) or 0
					items[b.item].quality = tonumber(b.quality) or 0
					items[b.item].dupe = tonumber(b.dupe) or 0

					if badItems[b.item] then
						flag = "B"
					end

					if v.raiding then
						flag = flag .. "R"
					end
				end

				if tonumber(b.quantity) ~= tonumber(items[a].quantity) then
					if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Inventory changed!(" .. b.item .. ", " .. items[a].quantity .. ", " .. b.quantity ..")") end

                                        if (items[a] == nil) then
                                                d1 = 0
                                        else
                                                d1 = tonumber(items[a].quantity)
                                        end

                                        delta = d1 - tonumber(b.quantity)
                                        if tonumber(delta) > 0 then
                                                delta = "+" .. delta
                                        else
                                                delta = delta

                                                -- list beds for this player if they drop 1 bed
                                                if b.item == "bedroll" and delta == -1 and server.coppi then
                                                        send("lpb " .. k)
                                                end
                                        end

					inventoryChanged = true
					table.insert(changes, { b.item, delta } )
					newItems = newItems .. b.item .. " (" .. delta .. "), "
					conn:execute("INSERT INTO inventoryChanges (steam, item, delta, x, y, z, session, flag, quality) VALUES (" .. k .. ",'" .. escape(b.item) .. "'," .. delta .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. flag .. "', " .. (tonumber(items[a].quality) or 0) .. ")")

					if igplayers[k] then igplayers[k].afk = os.time() + 900 end
					if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

					if (players[k].watchPlayer == true) then
						if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Extra Checking for watched Player: " .. players[k].name) end
						cursor,errorString = conn:execute("SELECT * FROM memRestrictedItems where item = '" .. escape(b.item) .. "' and action = 'watch'")
						row = cursor:fetch({}, "a")
						if row then
							if (b.item == row.item) and not string.find(newItems, b.item, nil, true) then
								newItems = newItems .. row.item .. " (" .. delta .. "), "
							end
						end

						if tonumber(delta) ~= 30 and players[k].newPlayer == true and not string.find(newItems, b.item, nil, true) then
							if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "New Item: " .. b.item) end
							newItems = newItems .. b.item .. " (" .. delta .. "), "
						end

						if (b.item == "keystoneBlock") and not string.find(newItems, b.item, nil, true) then
							if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "New Keystone for player(" .. players[k].name .. ")!") end
							newItems = newItems .. "keystoneBlock (" .. delta .. "), "

							if tonumber(delta) < 0 then
								players[k].keystones = 0

								if not server.lagged then
									if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "send(llp " .. k .. ")") end
									send("llp " .. k)
								end
							end
						end
					end
				end
			end

			if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

			if (players[k].watchPlayer == true) then
				if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "More checking of watched player: " .. players[k].name) end

				if newItems ~= "" then

					if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
					local Amsg = "Watched player " .. players[k].id .. " " .. players[k].name .. " " .. newItems

					if(not players[k].id) then
						players[k].id = 0
					end

					if(not players[k].name) then
						players[k].name = ""
					end
 
					if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), Amsg) end

					alertAdmins(Amsg)
				end
			end

			if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
			-- if inventoryChanged == true or (v.oldBelt ~= v.belt) then
			if inventoryChanged == true or (v.inventoryLast ~= v.inventory) then
				if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Inventory changed, write to db") end

				conn:execute("INSERT INTO inventoryTracker (steam, x, y, z, session, belt, pack, equipment) VALUES (" .. k .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. escape(v.belt) .. "','" .. escape(v.pack) .. "','" .. escape(v.equipment) .. "')")
				invTemp[k] = items

				if inventoryChanged == true then
					if players[k].timeOnServer == nil or players[k].watchPlayer == true or v.raiding == true then
						if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"),"Send item details to irc for watch player: " .. players[k].name) end
						for q, w in pairs(changes) do
							local msg = string.trim(flags .. " " .. players[k].name .. "  " .. w[1] .. "  " .. w[2] .. "  [ " .. math.floor(v.xPos) .. " " .. math.ceil(v.yPos) .. " " .. math.floor(v.zPos)) .. " ]"
							irc_chat(server.ircWatch, msg)
							alertAdmins(msg)
						end
					else
						if accessLevel(k) > 2 and tonumber(players[k].timeOnServer) < tonumber(server.newPlayerTimer)  then
							if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Writing item changes to irc for player:" .. players[k].name) end
							for q, w in pairs(changes) do
								local msg = string.trim(flags .. " " .. players[k].name .. "  " .. w[1] .. "   " .. w[2] .. "  [ " .. math.floor(v.xPos) .. " " .. math.ceil(v.yPos) .. " " .. math.floor(v.zPos)) .. " ]"
								irc_chat(server.ircWatch, msg)
								alertAdmins(msg)
							end
						end
					end
				end
			end

			if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
			if (items["keystoneBlock"] and players[k].newPlayer == true and tonumber(items["keystoneBlock"].quantity) > 4 and accessLevel(k) > 2) and (server.gameType ~= "cre") and (players[k].ignorePlayer ~= true) then
				local msg

				if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "New player with more than 4 keystones on player: " .. players[k].name) end
				conn:execute("INSERT INTO inventoryTracker (steam, x, y, z, session, belt, pack, equipment) VALUES (" .. k .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. escape(v.belt) .. "','" .. escape(v.pack) .. "','" .. escape(v.equipment) .. "')")
				banPlayer(k, "1 week", "Too many keystones (" .. items["keystoneBlock"].quantity .. ")", "")
				message("say [" .. server.chatColour .. "]Banning new player " .. igplayers[k].name .. " 1 week for too many keystones (" .. items["keystoneBlock"].quantity .. ") in inventory.  Cheating suspected.[-]")

				msg = "[BANNED] New player " .. k .. " " .. igplayers[k].name .. " has " .. items["keystoneBlock"].quantity .. " keystones and has been banned for 1 week"
				irc_chat(server.ircMain, msg)
				irc_chat(server.ircAlerts, msg)
				alertAdmins(msg)

				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. ",'" .. botman.serverTime .. "','ban','[BANNED] New player " .. k .. " " .. escape(igplayers[k].name) .. " has " .. items["keystoneBlock"].quantity .. " keystones and has been banned for 1 week'," .. k .. ")")

				if botman.db2Connected then
					-- copy in bots db
					connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','ban','[BANNED] New player " .. k .. " " .. escape(igplayers[k].name) .. " has " .. items["keystoneBlock"].quantity .. " keystones and has been banned for 1 week'," .. k .. ")")
				end
			end

		end

		if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Transition current inventory to old inventory for player: " .. players[k].name) end

		v.oldBelt = v.belt
		v.belt = ""
		v.oldPack = v.pack
		v.pack = ""
		v.oldEquipment = v.equipment
		v.equipment = ""
		v.inventoryLast = v.inventory
		v.inventory = ""

		changes = nil

		if (players[k].overstack == false) then
			players[k].overstackScore = 0
		end

		if not server.allowOverstacking then
			if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end
			if (players[k].overstack == true) and (accessLevel(k) > 2 or botman.ignoreAdmins == false) then
				local msg

				if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Notify player(" .. players[k].name .. ") that they are overstacking.") end
				message("pm " .. k .. " [" .. server.chatColour .. "]You are overstacking items in your inventory - " .. players[k].overstackItems .. "[-]")
				msg = igplayers[k].name .. " is overstacking " .. players[k].overstackItems
				irc_chat(server.ircWatch, msg)
				alertAdmins(msg)
			end

			if (tonumber(players[k].overstackScore) == 2) and (players[k].botTimeout == false) then
				if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Send player(" .. players[k].name .. ") a warning to stop over stacking") end
				message("pm " .. k .. " [" .. server.chatColour .. "]If you do not stop overstacking, you will be sent to timeout.  Fix your inventory now.[-]")
			end

			if tonumber(players[k].overstackScore) > 4 and (players[k].botTimeout == false) then
				local msg

				if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Player (" .. players[k].name .. ") has been put into timeout for overstacking") end
				players[k].botTimeout = true
				players[k].xPosTimeout = math.floor(players[k].xPos)
				players[k].yPosTimeout = math.ceil(players[k].yPos)
				players[k].zPosTimeout = math.floor(players[k].zPos)

				message("say [" .. server.chatColour .. "]" .. igplayers[k].name .. " is in timeout for ignoring overstack warnings.[-]")
				message("pm " .. k .. " [" .. server.chatColour .. "]You are still overstacking items. You will stay in timeout until you are not overstacking.[-]")
				msg = "[TIMEOUT] " .. k .. " " .. igplayers[k].name .. " is in timeout for overstacking the following " .. players[k].overstackItems
				irc_chat(server.ircWatch, msg)
				irc_chat(server.ircAlerts, msg)
				alertAdmins(msg)

				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(igplayers[k].name) .. " is in timeout for overstacking the following " .. escape(players[k].overstackItems) .. "'," .. k .. ")")
			end
		end

		if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if (ban == true) then
			if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"),"Starting the banning procress for player: " .. players[k].name) end

			if accessLevel(k) > 2 then
				local msg

				banPlayer(k, "1 year", banReason, "")

				message("say [" .. server.chatColour .. "]Banning player " .. igplayers[k].name .. " 1 year for suspected inventory cheating.[-]")
				msg = "[BANNED] Player " .. k .. " " .. igplayers[k].name .. " has has been banned for " .. banReason .. "."
				irc_chat(server.ircMain, msg)
				irc_chat(server.ircAlerts, msg)
				alertAdmins(msg)

				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. ",'" .. botman.serverTime .. "','ban','Player " .. k .. " " .. escape(igplayers[k].name) .. " has has been banned for 1 year for " .. escape(banReason) .. ".'," .. k .. ")")

				if botman.db2Connected then
					-- copy in bots db
					connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','ban','Player " .. k .. " " .. escape(igplayers[k].name) .. " has has been banned for 1 year for " .. escape(banReason) .. ".'," .. k .. ")")
				end
			end
		end

		if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if (timeout == true) then
			v.illegalInventory = true
			conn:execute("INSERT INTO inventoryTracker (steam, x, y, z, session, belt, pack, equipment) VALUES (" .. k .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. escape(v.belt) .. "','" .. escape(v.pack) .. "','" .. escape(v.equipment) .. "')")
			timeoutPlayer(k, timeoutReason, true)
		end

		if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if (move == true and players[k].exiled ~= 1) then
			local msg

			message("say [" .. server.chatColour .. "]Sending player " .. igplayers[k].name .. " to " .. moveTo .. " for " .. moveReason .. ".[-]")

			teleport("tele " .. k .. " " .. locations[moveTo].x .. " " .. locations[moveTo].y + 1 .. " " .. locations[moveTo].z)
			players[k].exiled = 1
			if accessLevel(k) > 2 then players[k].silentBob = true end
			players[k].canTeleport = false
			msg = "Moving player " .. k .. " " .. igplayers[k].name .. " to " .. moveTo .. " for " .. moveReason .. "."
			irc_chat(server.ircMain, msg)
			irc_chat(server.ircAlerts, msg)
			alertAdmins(msg)

			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. ",'" .. botman.serverTime .. "','exile','Player " .. k .. " " .. escape(igplayers[k].name) .. " has has been exiled to " .. escape(moveTo) .. " for " .. escape(moveReason) .. ".'," .. k .. ")")
		end

		if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if (not players[k].ignorePlayer) then
			if badItemsFound ~= "" then
				if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Start processing Illigal Items on player: " .. players[k].name) end

				igplayers[k].illegalInventory = true

				if (players[k].timeout == false) and (accessLevel(k) > 2 or botman.ignoreAdmins == false) then
					local msg

					if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Put player (" .. players[k].name .. ") on timeout!") end

					players[k].timeout = true
					players[k].botTimeout = true
					players[k].xPosTimeout = math.floor(players[k].xPos)
					players[k].yPosTimeout = math.ceil(players[k].yPos)
					players[k].zPosTimeout = math.floor(players[k].zPos)

					if accessLevel(k) > 2 then players[k].silentBob = true end
					message("say [" .. server.chatColour .. "]" .. igplayers[k].name .. " is in timeout for uncraftable items " .. badItemsFound .. ".[-]")
					message("pm " .. k .. " [" .. server.chatColour .. "]You have items in your inventory that are not permitted.[-]")
					message("pm " .. k .. " [" .. server.chatColour .. "]You must drop them if you wish to return to the game.[-]")

					msg = igplayers[k].name .. " detected with uncraftable " .. badItemsFound
					irc_chat(server.ircMain, msg)
					irc_chat(server.ircAlerts, msg)
					alertAdmins(msg)

					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event) VALUES (" .. math.floor(igplayers[k].xPos) .. "," .. math.ceil(igplayers[k].yPos) .. "," .. math.floor(igplayers[k].zPos) .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(igplayers[k].name) .. " detected with uncraftable inventory " .. escape(badItemsFound) .. "')")

					if botman.db2Connected then
						-- copy in bots db
						connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','timeout','Player " .. escape(igplayers[k].name) .. " detected with uncraftable inventory " .. escape(badItemsFound) .. "')")
					end

					break
				end
			end
		end

		if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if players[k].botTimeout == true and v.illegalInventory == false and players[k].overstack == false then
			if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "End timout for player: " .. players[k].name) end

			players[k].botTimeout = false
			players[k].timeout = false
			players[k].silentBob = false
			players[k].overstackScore = 0
			gmsg(server.commandPrefix .. "return " .. igplayers[k].name)
			message("pm " .. k .. " [" .. server.chatColour .. "]You are free to play again.[-]")
			players[k].xPosOld = 0
			players[k].yPosOld = 0
			players[k].zPosOld = 0
			igplayers[k].lastLocation = ""
		end

          end
	end

	if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "End") end
end


function readInventorySlot()
	local timestamp, slot, item, quantity, quality, pos, words, dupeTest
	local tmpslotStart, tmpslotEnd

	timestamp = os.time()
	item = ""
	slot = ""
	quantity = 0
	quality = 0
	words = {}
	dupeTest = {}

	for word in line:gmatch("%w+") do table.insert(words, word) end

	tmpslotStart=string.find(line, "Slot")
	tmpslotEnd= string.find(line, ": ")
	
	if(not tmpslotStart or not tmpslotEnd) then return end

	slot = string.sub(line, tmpslotStart + 5, tmpslotEnd - 1)

	-- slot = string.sub(line, string.find(line, "Slot") + 5, string.find(line, ": ") - 1)

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


	if(not igplayers[invCheckID]) then return end

	if (invScan == "belt") then
		beltSlots[slot] = true

		igplayers[invCheckID].inventory = igplayers[invCheckID].inventory .. quantity .. "," .. item .. "," .. quality .. ", B-" .. slot .. "|"
		igplayers[invCheckID].belt = igplayers[invCheckID].belt .. slot .. "," .. quantity .. "," .. item .. "," .. quality .. "|"
	end

	if (invScan == "bagpack") then
		packSlots[slot] = true

		igplayers[invCheckID].inventory = igplayers[invCheckID].inventory .. quantity .. "," .. item .. "," .. quality .. ", P-" .. slot .. "|"
		igplayers[invCheckID].pack = igplayers[invCheckID].pack .. slot .. "," .. quantity .. "," .. item .. "," .. quality .. "|"
	end

	if (invScan == "equipment") then
		equipmentSlots[slot] = true

		igplayers[invCheckID].inventory = igplayers[invCheckID].inventory .. quantity .. "," .. item .. "," .. quality .. ", E-" .. slot .. "|"
		igplayers[invCheckID].equipment = igplayers[invCheckID].equipment .. slot .. "," .. item .. "," .. quality .. "|"
	end
end
