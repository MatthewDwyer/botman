--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function CheckInventory()
	local temp, newPlayer, ban, timeout, move, newItems, table1, table2, items, reason, moveTo, moveReason, banReason, timeoutReason
	local d1, delta, inventoryChanged, changes, flags, debug, badItemsFound, badItemAction, count500, dbFlag, tmp, flag, max

	debug = false

if debug then dbug("check inventory 1") end

	tmp = {}

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

if debug then dbug("check inventory 2") end
	
		if igplayers[k] then
			if (tonumber(players[k].timeOnServer) + tonumber(igplayers[k].sessionPlaytime) < (tonumber(server.newPlayerTimer) * 60) ) then
				newPlayer = true
			else
				newPlayer = false	
			end
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

if debug then dbug("check inventory 3") end

		if (igplayers[k].inventory ~= "") then
			table1 = string.split(igplayers[k].inventory, "|")

			max = table.maxn(table1)
			for i = 1, max do
				if table1[i] ~= "" then
					table2 = string.split(table1[i], ",")

					if (badItems[table2[2]]) and (accessLevel(k) > 2 or botman.ignoreAdmins == false) then
						dbFlag = dbFlag .. "B"
					
						igplayers[k].illegalInventory = true
						if badItems[table2[2]].action == "ban" then
							ban = true
							banReason = "Bad items found in inventory"
							
							if v.raiding then
								banReason = "Bad items found in inventory while base raiding"
							end
						end
						
						if badItems[table2[2]].action == "exile" then
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
								tmp.search = a:gsub('%W','')
								if string.find(igplayers[k].inventory, tmp.search) then
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
						items[table2[2]] = {}
						items[table2[2]].item = table2[2]
						items[table2[2]].quantity = tonumber(table2[1])
						items[table2[2]].quality = tonumber(table2[3])
					else
						items[table2[2]].quantity = items[table2[2]].quantity + tonumber(table2[1])
					end

					-- stack monitoring
					if (stackLimits[table2[2]] ~= nil) and (accessLevel(k) > 2 or botman.ignoreAdmins == false) and (server.gameType ~= "cre") then
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

						-- instant ban for overstacking any of these if a new player
						if tonumber(table2[1]) > tonumber(stackLimits[table2[2]].limit) and newPlayer == true then
							if (table2[2] == "tnt" or table2[2] == "keystoneBlock" or table2[2] == "mineAirFilter" or table2[2] == "mineHubcap" or table2[2] == "rScrapIronPlateMine") then
								ban = true
								banReason = "Banned for overstacking " .. table2[2] .. "(" .. table2[1] .. ")."
							end
						end
					end					
				end
			end

			if v.raiding and timeout then
				players[k].exiled = 1
				if accessLevel(k) > 2 then players[k].silentBob = true end
				players[k].canTeleport = false	

				irc_chat(server.ircMain, "Exiling " .. igplayers[k].name .. " detected with bad inventory while raiding.")
				irc_chat(server.ircAlerts, "Exiling " .. igplayers[k].name .. " detected with bad inventory while raiding.")				
			end

if debug then dbug("check inventory 4") end

			for a, b in pairs(items) do
				if (players[k].newPlayer == true and igplayers[k].skipExcessInventory ~= true) then

					cursor,errorString = conn:execute("SELECT * FROM memRestrictedItems where item = '" .. escape(b.item) .. "' and accessLevel < " .. players[k].accessLevel)				
					rows = cursor:numrows()

					if tonumber(rows) > 0 then
						row = cursor:fetch({}, "a")

						if tonumber(b.quantity) > tonumber(row.qty) then
							if row.action == "timeout" then
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
--								if players[k].watchPlayer == false then
--									players[k].watchPlayer = true
									irc_chat(server.ircWatch, "Player " .. players[k].name .. " has " .. b.quantity .. " of " .. b.item)
--								end
							end

						end
					end				
				end 
			end

if debug then dbug("check inventory 5") end

			if tablelength(invTemp[k]) == 0 then 
				invTemp[k] = items 
			end

if debug then dbug("check inventory 6") end

			flag = ""

			for a, b in pairs(invTemp[k]) do
				if items[b.item] == nil then
					items[b.item] = {}
					items[b.item].item = b.item
					items[b.item].quantity = 0
					
					if badItems[b.item] then
						flag = "B"
					end
					
					if v.raiding then
						flag = flag .. "R"
					end
				end

				if tonumber(b.quantity) ~= tonumber(items[a].quantity) then
					inventoryChanged = true
					table.insert(changes, { b.item, tonumber(items[a].quantity) - tonumber(b.quantity) } )	
					conn:execute("INSERT INTO inventoryChanges (steam, item, delta, x, y, z, session, flag) VALUES (" .. k .. ",'" .. escape(b.item) .. "'," .. tonumber(items[a].quantity) - tonumber(b.quantity) .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. flag .. "')")
					
					if igplayers[k] then igplayers[k].afk = os.time() + 900 end

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
					end

					if (players[k].watchPlayer == true) then
						cursor,errorString = conn:execute("SELECT * FROM memRestrictedItems where item = '" .. escape(b.item) .. "' and action = 'watch'")
						row = cursor:fetch({}, "a")
						if row then
							if (b.item == row.item) and not string.find(newItems, b.item, nil, true) then
								newItems = newItems .. row.item .. " (" .. delta .. "), "	
							end
						end

						if tonumber(delta) > 30 and players[k].newPlayer == true and not string.find(newItems, b.item, nil, true) then
							newItems = newItems .. b.item .. " (" .. delta .. "), "	
						end

						if (b.item == "keystoneBlock") and not string.find(newItems, b.item, nil, true) then
							newItems = newItems .. "keystoneBlock (" .. delta .. "), "	
								
							if tonumber(delta) < 0 then
								players[k].keystones = 0
								
								if not server.lagged then
									send("llp " .. k)
								end
							end
						end
					end
				end
			end

if debug then dbug("check inventory 7") end

			if (players[k].watchPlayer == true) then
				if newItems ~= "" then
					alertAdmins("Watched player " .. players[k].id .. " " .. players[k].name .. " " .. newItems)
--					irc_chat(server.ircWatch, "Watched player " .. players[k].id .. " " .. players[k].name .. " inventory " .. newItems .. " near " .. math.floor(igplayers[k].xPos) .. " " .. math.ceil(igplayers[k].yPos) .. " " .. math.floor(igplayers[k].zPos))
				end
			end

if debug then dbug("check inventory 8") end

			if inventoryChanged == true or (v.oldBelt ~= v.belt) then --  or (belt ~= v.belt)
				conn:execute("INSERT INTO inventoryTracker (steam, x, y, z, session, belt, pack, equipment) VALUES (" .. k .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. escape(v.belt) .. "','" .. escape(v.pack) .. "','" .. escape(v.equipment) .. "')")
				invTemp[k] = items

				if inventoryChanged == true then
					if players[k].timeOnServer == nil or players[k].watchPlayer == true or v.raiding == true then
						for q, w in pairs(changes) do
							irc_chat(server.ircWatch, string.trim(flags .. " " .. players[k].name .. "  " .. w[1] .. "  " .. w[2] .. "  [ " .. math.floor(v.xPos) .. " " .. math.ceil(v.yPos) .. " " .. math.floor(v.zPos)) .. " ]")
						end
					else
						if accessLevel(k) > 2 and tonumber(players[k].timeOnServer) < tonumber(server.newPlayerTimer)  then
							for q, w in pairs(changes) do
								irc_chat(server.ircWatch, string.trim(flags .. " " .. players[k].name .. "  " .. w[1] .. "   " .. w[2] .. "  [ " .. math.floor(v.xPos) .. " " .. math.ceil(v.yPos) .. " " .. math.floor(v.zPos)) .. " ]")
							end
						end
					end
				end
			end

if debug then dbug("check inventory 9") end

			if (items["keystoneBlock"] and players[k].newPlayer == true and tonumber(items["keystoneBlock"].quantity) > 4 and accessLevel(k) > 2) and (server.gameType ~= "cre") then
				conn:execute("INSERT INTO inventoryTracker (steam, x, y, z, session, belt, pack, equipment) VALUES (" .. k .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. escape(v.belt) .. "','" .. escape(v.pack) .. "','" .. escape(v.equipment) .. "')")
				banPlayer(k, "1 week", "Too many keystones (" .. items["keystoneBlock"].quantity .. ")", "")
				message("say [" .. server.chatColour .. "]Banning new player " .. igplayers[k].name .. " 1 week for too many keystones (" .. items["keystoneBlock"].quantity .. ") in inventory.  Cheating suspected.[-]")
				irc_chat(server.ircMain, "[BANNED] New player " .. k .. " " .. igplayers[k].name .. " has " .. items["keystoneBlock"].quantity .. " keystones and has been banned for 1 week")
				irc_chat(server.ircAlerts, "[BANNED] New player " .. k .. " " .. igplayers[k].name .. " has " .. items["keystoneBlock"].quantity .. " keystones and has been banned for 1 week")

				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. ",'" .. botman.serverTime .. "','ban','[BANNED] New player " .. k .. " " .. escape(igplayers[k].name) .. " has " .. items["keystoneBlock"].quantity .. " keystones and has been banned for 1 week'," .. k .. ")")

				if botman.db2Connected then
					-- copy in bots db
					connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','ban','[BANNED] New player " .. k .. " " .. escape(igplayers[k].name) .. " has " .. items["keystoneBlock"].quantity .. " keystones and has been banned for 1 week'," .. k .. ")")
				end
			end

		end

		v.oldBelt = v.belt

if debug then dbug("check inventory 10") end

		changes = nil
		
		if (players[k].overstack == false) then
			players[k].overstackScore = 0
		end

		if not server.allowOverstacking then
			if (players[k].overstack == true) and (accessLevel(k) > 2 or botman.ignoreAdmins == false) then
				message("pm " .. k .. " [" .. server.chatColour .. "]You are overstacking items in your inventory - " .. players[k].overstackItems .. "[-]")
				irc_chat(server.ircWatch, igplayers[k].name .. " is overstacking " .. players[k].overstackItems)
			end

			if (tonumber(players[k].overstackScore) == 2) and (players[k].botTimeout == false) then
				message("pm " .. k .. " [" .. server.chatColour .. "]If you do not stop overstacking, you will be sent to timeout.  Fix your inventory now.[-]")
			end

			if tonumber(players[k].overstackScore) > 4 and (players[k].botTimeout == false) then
				-- if players[k].watchPlayer then
					-- irc_chat(server.ircTracker, server.gameDate .. " " .. k .. " " .. players[k].name .. " sent to timeout by bot")
				-- end

				players[k].botTimeout = true
				players[k].xPosTimeout = math.floor(players[k].xPos)
				players[k].yPosTimeout = math.ceil(players[k].yPos)
				players[k].zPosTimeout = math.floor(players[k].zPos)

				message("say [" .. server.chatColour .. "]" .. igplayers[k].name .. " is in timeout for ignoring overstack warnings.[-]")
				message("pm " .. k .. " [" .. server.chatColour .. "]You are still overstacking items. You will stay in timeout until you are not overstacking.[-]")
				irc_chat(server.ircWatch, "[TIMEOUT] " .. k .. " " .. igplayers[k].name .. " is in timeout for overstacking the following " .. players[k].overstackItems)
				irc_chat(server.ircAlerts, "[TIMEOUT] " .. k .. " " .. igplayers[k].name .. " is in timeout for overstacking the following " .. players[k].overstackItems)

				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(igplayers[k].name) .. " is in timeout for overstacking the following " .. escape(players[k].overstackItems) .. "'," .. k .. ")")
			end
		end

		if (ban == true) then			
--			dbug("INSERT INTO inventoryTracker (steam, x, y, z, session, belt, pack, equipment) VALUES (" .. k .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. escape(v.belt) .. "','" .. escape(v.pack) .. "','" .. escape(v.equipment) .. "')")
--			conn:execute("INSERT INTO inventoryTracker (steam, x, y, z, session, belt, pack, equipment) VALUES (" .. k .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. escape(v.belt) .. "','" .. escape(v.pack) .. "','" .. escape(v.equipment) .. "')")
			
			if accessLevel(k) > 2 then
				banPlayer(k, "1 year", banReason, "")			
			
				message("say [" .. server.chatColour .. "]Banning player " .. igplayers[k].name .. " 1 year for suspected inventory cheating.[-]")
				irc_chat(server.ircMain, "[BANNED] Player " .. k .. " " .. igplayers[k].name .. " has has been banned for " .. banReason .. ".")
				irc_chat(server.ircAlerts, "[BANNED] Player " .. k .. " " .. igplayers[k].name .. " has has been banned for 1 year for " .. banReason .. ".")
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. ",'" .. botman.serverTime .. "','ban','Player " .. k .. " " .. escape(igplayers[k].name) .. " has has been banned for 1 year for " .. escape(banReason) .. ".'," .. k .. ")")				
				
				if botman.db2Connected then
					-- copy in bots db
					connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','ban','Player " .. k .. " " .. escape(igplayers[k].name) .. " has has been banned for 1 year for " .. escape(banReason) .. ".'," .. k .. ")")
				end				
			end			
		end

		if (timeout == true) then
			v.illegalInventory = true
			conn:execute("INSERT INTO inventoryTracker (steam, x, y, z, session, belt, pack, equipment) VALUES (" .. k .. "," .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. "," .. players[k].sessionCount .. ",'" .. escape(v.belt) .. "','" .. escape(v.pack) .. "','" .. escape(v.equipment) .. "')")
			timeoutPlayer(k, timeoutReason, true)
		end

		if (move == true and players[k].exiled ~= 1) then
			message("say [" .. server.chatColour .. "]Sending player " .. igplayers[k].name .. " to " .. moveTo .. " for " .. moveReason .. ".[-]")

			-- if players[k].watchPlayer then
				-- irc_chat(server.ircTracker, server.gameDate .. " " .. k .. " " .. players[k].name .. " exiled by bot")
			-- end

			dbug("inventory line " .. debugger.getinfo(1).currentline)	
			teleport("tele " .. k .. " " .. locations[moveTo].x .. " " .. locations[moveTo].y + 1 .. " " .. locations[moveTo].z)
			players[k].exiled = 1
			if accessLevel(k) > 2 then players[k].silentBob = true end
			players[k].canTeleport = false
			irc_chat(server.ircMain, "Moving player " .. k .. " " .. igplayers[k].name .. " to " .. moveTo .. " for " .. moveReason .. ".")
			irc_chat(server.ircAlerts, "Moving player " .. k .. " " .. igplayers[k].name .. " to " .. moveTo .. " for " .. moveReason .. ".")
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(v.xPos) .. "," .. math.ceil(v.yPos) .. "," .. math.floor(v.zPos) .. ",'" .. botman.serverTime .. "','exile','Player " .. k .. " " .. escape(igplayers[k].name) .. " has has been exiled to " .. escape(moveTo) .. " for " .. escape(moveReason) .. ".'," .. k .. ")")
		end

if debug then dbug("check inventory 11") end

		if (players[k].ignorePlayer ~= true) then
			if badItemsFound ~= "" then
				igplayers[k].illegalInventory = true

				if (players[k].timeout == false) and (accessLevel(k) > 2 or botman.ignoreAdmins == false) then
					-- if players[k].watchPlayer then
						-- irc_chat(server.ircTracker, server.gameDate .. " " .. k .. " " .. players[k].name .. " sent to timeout by bot")
					-- end

					players[k].timeout = true
					players[k].botTimeout = true
					players[k].xPosTimeout = math.floor(players[k].xPos)
					players[k].yPosTimeout = math.ceil(players[k].yPos)
					players[k].zPosTimeout = math.floor(players[k].zPos)

					if accessLevel(k) > 2 then players[k].silentBob = true end
					message("say [" .. server.chatColour .. "]" .. igplayers[k].name .. " is in timeout for uncraftable items " .. badItemsFound .. ".[-]")
					message("pm " .. k .. " [" .. server.chatColour .. "]You have items in your inventory that are not permitted.[-]")
					message("pm " .. k .. " [" .. server.chatColour .. "]You must drop them if you wish to return to the game.[-]")

					irc_chat(server.ircMain, igplayers[k].name .. " detected with uncraftable " .. badItemsFound)
					irc_chat(server.ircAlerts, igplayers[k].name .. " detected with uncraftable " .. badItemsFound)
					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event) VALUES (" .. math.floor(igplayers[k].xPos) .. "," .. math.ceil(igplayers[k].yPos) .. "," .. math.floor(igplayers[k].zPos) .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(igplayers[k].name) .. " detected with uncraftable inventory " .. escape(badItemsFound) .. "')")

					if botman.db2Connected then
						-- copy in bots db
						connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','timeout','Player " .. escape(igplayers[k].name) .. " detected with uncraftable inventory " .. escape(badItemsFound) .. "')")
					end

					break
				end
			end
		end

		if players[k].botTimeout == true and v.illegalInventory == false and players[k].overstack == false then
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

if debug then dbug("check inventory end") end
end


function readInventorySlot()
	local timestamp, slot, item, quantity, quality, pos, words

	timestamp = os.time()
	item = ""
	slot = ""
	quantity = 0
	quality = 0
	words = {}

	for word in line:gmatch("%w+") do table.insert(words, word) end

	--    Slot face: bandanaBlue - quality: 33
	--    Slot armor: leatherJacket - quality: 13
	--    Slot jacket: denimJacket - quality: 25
	--    Slot shirt: plaidShirt - quality: 235
	--    Slot pants: blackDenimPants - quality: 121
	--    Slot boots: wornBoots - quality: 120
	--    Slot gloves: clothGloves - quality: 58
	--    Slot eyes: aviatorGoggles - quality: 24
	--    Slot head: miningHelmet
	--    Slot 31: 003 * emptyJar

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

		-- if tonumber(slot) == 7 and tonumber(quantity) > 0 and item == "casinoCoin" then
			-- -- do a gimme
			-- if (server.allowGimme) then
				-- igplayers[invCheckID].playGimme = true
				-- gimme(invCheckID)
				-- message("pm " .. invCheckID .. " [" .. server.chatColour .. "]To stop playing gimme, remove the casino coins from the last slot in your belt.[-]")
			-- end
		-- end
		

		-- if tonumber(slot) == 7 and tonumber(quantity) > 0 and item == "yuccaFibers" then
			-- --run the who command
			-- message("pm " .. invCheckID .. " [" .. server.chatColour .. "]Remove grass from last slot of belt stop the spam.[-]")
			-- gmsg_who(invCheckID)
		-- end
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
