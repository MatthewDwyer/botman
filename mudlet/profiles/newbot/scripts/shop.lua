--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- 	if not server.beQuietBot then


local id, page, count, shopState, debug

debug = false

function fixShop()
	-- automatically fix missing categories and check each category and shop item for bad data
	local cursor, cursor2, errorString, row, k, v

	-- refresh the categories from the database
	loadShopCategories()

	cursor,errorString = conn:execute("SELECT * FROM shop ORDER BY category")
	row = cursor:fetch({}, "a")

	while row do
		if row.category == "" or shopCategories[row.category] == nil then
			cursor2,errorString = conn:execute("UPDATE shop SET category = 'misc' WHERE item = '" .. escape(row.item) .. "'")
		end

		row = cursor:fetch(row, "a")
	end

	-- reindex each category
	for k, v in pairs(shopCategories) do
		reindexShop(k)
	end

	irc_chat(server.ircMain, "Validating shop and gimme prize items.")
	collectSpawnableItemsList()
end


function payPlayer()
	if (string.find(chatvars.command, "yes")) then
		if (players[chatvars.playerid].cash >= players[chatvars.playerid].botQuestionValue) or chatvars.accessLevel == 0 then
			players[players[chatvars.playerid].botQuestionID].cash = players[players[chatvars.playerid].botQuestionID].cash + players[chatvars.playerid].botQuestionValue

			if chatvars.accessLevel > 0 then
				players[chatvars.playerid].cash = players[chatvars.playerid].cash - players[chatvars.playerid].botQuestionValue
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[chatvars.playerid].botQuestionValue .. " has been paid to " .. players[players[chatvars.playerid].botQuestionID].name .. "[-]")

			if (igplayers[players[chatvars.playerid].botQuestionID]) then
				message("pm " .. players[chatvars.playerid].botQuestionID .. " [" .. server.chatColour .. "]Payday! " .. players[chatvars.playerid].name .. " has paid you " .. players[chatvars.playerid].botQuestionValue .. " " .. server.moneyPlural .. "![-]")
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I regret to inform you that you do not have sufficient funds to pay " .. players[players[chatvars.playerid].botQuestionID].name .. "[-]")
		end
	end

	players[chatvars.playerid].botQuestion = ""
	players[chatvars.playerid].botQuestionID = nil
	players[chatvars.playerid].botQuestionValue = nil
end


function LookupShop(search,all)
	-- build a sorted list of the search result and store in stock table
	local cursor, errorString, row, temp

	shopCode = ""
	shopCategory = ""
	shopItem = ""
	shopStock = 0
	shopPrice = 0
	shopIndex = 0
	shopUnits = 0
	shopQuality = 0

	conn:execute("TRUNCATE memShop")

	if all ~= nil then
		cursor,errorString = conn:execute("SELECT * FROM shop WHERE item = '" .. escape(search) .. "' or category = '" .. escape(search) .. "' ORDER BY idx")
	else
		cursor,errorString = conn:execute("SELECT * FROM shop WHERE item like '%" .. escape(search) .. "%' or category like '%" .. escape(search) .. "%' ORDER BY idx")
	end

	row = cursor:fetch({}, "a")

	while row do
		shopCode = shopCategories[row.category].code .. string.format("%02d", row.idx)
		shopItem = row.item
		shopIndex = row.idx
		shopCategory = row.category
		shopStock = row.stock
		shopUnits = row.units
		shopQuality = row.quality
		shopPrice = (row.price + row.variation) * ((100 - row.special) / 100)
		conn:execute("INSERT INTO memShop (item, idx, category, price, stock, code, units) VALUES ('" .. escape(row.item) .. "'," .. row.idx .. ",'" .. escape(row.category) .. "'," .. (row.price + row.variation) * ((100 - row.special) / 100) .. "," .. row.stock .. ",'" .. escape(shopCode) .. "'," .. row.units .. ")")

		row = cursor:fetch(row, "a")
	end

	-- search for the shop code
	if shopCode == "" then
		cursor,errorString = conn:execute("SELECT * FROM shop")
		row = cursor:fetch({}, "a")

		while row do
			temp = shopCategories[row.category].code .. string.format("%02d", row.idx)

			if temp == search then
				shopRows = 1
				shopCode = temp
				shopItem = row.item
				shopIndex = row.idx
				shopCategory = row.category
				shopStock = row.stock
				shopUnits = row.units
				shopQuality = row.quality
				shopPrice = (row.price + row.variation) * ((100 - row.special) / 100)
				conn:execute("INSERT INTO memShop (item, idx, category, price, stock, code, units, quality) VALUES ('" .. escape(row.item) .. "'," .. row.idx .. ",'" .. escape(row.category) .. "'," .. (row.price + row.variation) * ((100 - row.special) / 100) .. "," .. row.stock .. ",'" .. escape(shopCode) .. "'," .. row.units .. "," .. row.quality .. ")")
				return
			end

			row = cursor:fetch(row, "a")
		end
	end

	return shopItem
end


function reindexShop(category)
	local nextidx, cursor, errorString, row

	cursor,errorString = conn:execute("UPDATE shop SET idx = 0 WHERE category = '" .. escape(category) .. "'")
	cursor,errorString = conn:execute("SELECT * FROM shop WHERE category = '" .. escape(category) .. "' ORDER BY item")
	row = cursor:fetch({}, "a")

	nextidx = 1
	while row do
		conn:execute("UPDATE shop SET idx = " .. nextidx .. " WHERE item = '" .. escape(row.item) .. "'")
		nextidx = nextidx + 1

		row = cursor:fetch(row, "a")
	end
end


function drawLottery(draw)
	local winners, winnersCount, prizeDraw, x, rows, thing

	if tonumber(server.lottery) == 0 then
		return
	end

	if not draw then
		draw = 0
	end

	winners = {}
	winnersCount = 0

	for x=1,100,1 do
		prizeDraw = rand(100)

		cursor,errorString = conn:execute("SELECT * FROM memLottery WHERE ticket = " .. prizeDraw)
		rows = cursor:numrows()

		if rows > 0 then
			winnersCount = rows
			break
		end
	end

	message("say [" .. server.chatColour .. "]It's time for the daily lottery draw for " .. server.lottery .. " " .. server.moneyPlural .. "![-]")

	if tonumber(winnersCount) > 0 then
		prizeDraw = math.floor(server.lottery / winnersCount)

		row = cursor:fetch({}, "a")
		while row do
			players[row.steam].cash = players[row.steam].cash + prizeDraw
			conn:execute("UPDATE players SET cash = " .. players[row.steam].cash .. " WHERE steam = " .. row.steam)
			message("say [" .. server.chatColour .. "]" .. players[row.steam].name .. " won " .. prizeDraw .. " " .. server.moneyPlural .. "![-]")

			if not igplayers[row.steam] then
				if winnersCount > 1 then
					conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. row.steam .. ", 'Congratulations!  You won " .. prizeDraw .. " " .. server.moneyPlural .. " in the daily lottery along with " .. winnersCount - 1 .. " others. :)')")
				else
					conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. row.steam .. ", 'Congratulations!  You won " .. prizeDraw .. " " .. server.moneyPlural .. " in the daily lottery! =D')")
				end
			end

			row = cursor:fetch(row, "a")
		end

		if not server.beQuietBot then
			message("say [" .. server.chatColour .. "]$$$ Congratulation$ $$$   xD[-]")
		end

		if steam == nil then
			conn:execute("TRUNCATE memLottery")
			conn:execute("TRUNCATE lottery")
			server.lottery = 0
			conn:execute("UPDATE server SET lottery = 0")
		else
			conn:execute("DELETE FROM memLottery where steam = '" .. steam .. "'")
			conn:execute("DELETE FROM lottery where steam = '" .. steam .. "'")
		end
	else
		if not server.beQuietBot then
			r = rand(7)

			if (r == 1) then message("say [" .. server.chatColour .. "]Nobody wins again![-]") end
			if (r == 2) then
				thing = PicknMix()
				message("say [" .. server.chatColour .. "]Tonight's winner is.. " .. gimmeZombies[thing].zombie .. "! Who gave that a ticket? O.o[-]")
			end

			if (r == 3) then
				message("say [" .. server.chatColour .. "]OH NO! A zombie ate the winning number![-]")
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]BAD ZOMBIE!  No biscuit![-]") .. "')")
			end

			if (r == 4) then
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Tonight's winner is..[-]") .. "')")
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Nobody again!  That guy has all the luck.[-]") .. "')")
			end

			if (r == 5) then
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Tonight's winner is..[-]") .. "')")
				r = rand(6)
				if (r == 1) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]ME! I win! IT'S MINE! :P[-]") .. "')") end
				if (r == 2) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Dead! Congratulations.. oh.. nevermind.[-]") .. "')") end
				if (r == 3) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]TAX! Oh no! They've found my little illegal gambling scam er.. establishment. D:[-]") .. "')") end
				if (r == 4) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Being eaten by zombies! Poor guy :([-]") .. "')") end
				if (r == 5) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]No one! HA! Suck it Nobody.[-]") .. "')") end
				if (r == 6) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Sorry folks. Tonight's draw is cancelled.[-]") .. "')") end
				r = 0
			end

			if (r == 6) then
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Tonight's winner is..[-]") .. "')")

				-- don't redraw more than once
				if draw ~= 6 then
					conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Nobody!  But he's won enough so we're doing a redraw![-]") .. "')")
					tempTimer( 15, [[drawLottery(]] .. r .. [[)]] )
				else
					r = rand(6)
					if (r == 1) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Nobody! Stop buying all of the tickets you dirty cheat![-]") .. "')") end
					if (r == 2) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Nobody! Oh hell no, not on my watch. *burns Nobody's ticket*[-]") .. "')") end
					if (r == 3) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]God dammit! Nobody again.[-]") .. "')") end
					if (r == 4) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Nobody. Right! That's it you've had it. *BANG* Nobody died.[-]") .. "')") end
					if (r == 5) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Nobody! Stop gambling you lunatic![-]") .. "')") end
					if (r == 6) then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Not Nobody, please don't draw Nobody.. Ah crap![-]") .. "')") end
					r = 0
				end
			end

			if (r == 7) then
				r = rand(6)
				if r == 1 then thing = "severed head" end
				if r == 2 then thing = "severed hand" end
				if r == 3 then thing = "severed foot" end
				if r == 4 then thing = "mouldy eyeball" end
				if r == 5 then thing = "used nappy" end
				if r == 6 then thing = "rotten cheese" end
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Tonight's winner is..[-]") .. "')")
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]EWW!  Who put a " .. thing .. " in the bag?  That's gross![-]") .. "')")
				r = 0
			end
		else
			message("say [" .. server.chatColour .. "]Nobody won this time.[-]")
		end
	end
end


function resetShop(forced)
	local specialCount, r, i, discCount

	-- don't reset the shop if shopResetDays is 0 and not forced
	if not forced and server.shopResetDays == 0 then
		return
	end

	server.shopCountdown = server.shopCountdown - 1

	if tonumber(server.shopCountdown) < 1 or forced ~= nil then
		conn:execute("UPDATE shop SET stock = maxStock")
		server.shopCountdown = server.shopResetDays
	end

	if botman.dbConnected then conn:execute("UPDATE server SET shopCountdown = " .. server.shopCountdown) end
end


function doShop(command, playerid, words)
	local k, v, i, number, cmd, list, cursor, errorString, example, units, cmd

if (debug) then
dbug("debug shop line " .. debugger.getinfo(1).currentline)
dbug(command)
dbug(playerid)
end

	-- check for missing money :O
	if server.moneyName == nil then server.moneyName = "Zenny" end
	if server.moneyPlural == nil then server.moneyPlural = "Zennies" end

	cmd = ""
	list = ""
	for k, v in pairs(shopCategories) do
		if k ~= "misc" then
			example = k
			list = list .. k .. ",  "
		end
	end
	list = string.sub(list, 1, string.len(list) - 3)

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	shopState = "[OPEN]"

	if server.shopOpenHour ~= server.shopCloseHour then
		if (tonumber(server.gameHour) < tonumber(server.shopOpenHour) or tonumber(server.gameHour) > tonumber(server.shopCloseHour)) then
			shopState = "[CLOSED]"
		end
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	number = tonumber(string.match(command, " (-?\%d+)"))

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if words[1] == "shop" and words[2] == nil then
		message("pm " .. playerid .. " [" .. server.chatColour .. "]You have " .. string.format("%d", players[playerid].cash) .. " " .. server.moneyPlural .. " in the bank. Shop is " .. shopState .. "[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Shop categories are " .. list .. ".[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Type shop " .. example .. " (to browse our fine collection).[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]New stock arrives every 3 days.[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Type help shop for more info.[-]")
		if (accessLevel(playerid) < 3) then message("pm " .. playerid .. " [" .. server.chatColour .. "]shop admin (for admin commands)[-]") end
		return false
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "shop" and words[2] == "admin") and (accessLevel(playerid) < 3) then
		message("pm " .. playerid .. " [" .. server.chatColour .. "]shop price {code or item name} {whole number without $}[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]shop restock {code or item name} {quantity} or -1 (add quantity to stock)[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]shop special {code or item name} {number from 0 to 100}[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]shop variation {code or item name} {number} (can be negative)[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]You can manage categories and items for sale via IRC.[-]")
		return false
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if (shopCategories[words[2]]) then
		LookupShop(words[2],all)

		message("pm " .. playerid .. " [" .. server.chatColour .. "]To buy type buy {code} {quantity}[-]")

		cursor,errorString = conn:execute("SELECT * FROM memShop ORDER BY category, item")
		row = cursor:fetch({}, "a")

		while row do
			if tonumber(row.units) == 0 then
				units = 1
			else
				units = row.units
			end

			if tonumber(row.stock) == -1 then
				message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price:  " .. row.price .. " units:  " .. units .. " UNLIMITED STOCK![-]")
			else
				if row.stock == 0 then
					message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. " units:  " .. units .. "[-]  [FF0000]SOLD OUT[-]")
				else
					message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. " units:  " .. units .. "  (" .. row.stock .. " left)[-]")
				end
			end

			row = cursor:fetch(row, "a")
		end

		return false
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if (words[2] == "list") then
		list = ""

		for k, v in pairs(shopCategories) do
			list = list .. k .. ",  "
		end
		list = string.sub(list, 1, string.len(list) - 3)

		message("pm " .. playerid .. " [" .. server.chatColour .. "]To browse my wares type shop {category}.  The categories are " .. list .. ".[-]")

		return false
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if (words[2] == "variation" and words[3] ~= nil) then
		if (accessLevel(playerid) > 2) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			return false
		end

		LookupShop(words[3])

		message("pm " .. playerid .. " [" .. server.chatColour .. "]You have changed the price variation for " .. shopItem .. " to " .. number .. "[-]")
		conn:execute("UPDATE shop SET variation = " .. escape(number) .. " WHERE item = '" .. escape(shopItem) .. "'")

		return false
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if (words[2] == "special" and words[3] ~= nil) then
		if (accessLevel(playerid) > 2) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			return false
		end

		LookupShop(words[3])
		number = tonumber(words[4])

		message("pm " .. playerid .. " [" .. server.chatColour .. "]You have changed the shop special for " .. shopItem .. " to " .. number .. "[-]")

		conn:execute("UPDATE shop SET special = " .. escape(number) .. " WHERE item = '" .. escape(shopItem) .. "'")
		return false
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if (words[2] == "price" and words[3] ~= nil) then
		if (accessLevel(playerid) > 2) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			return false
		end

		LookupShop(words[3])
		number = tonumber(words[4])

		message("pm " .. playerid .. " [" .. server.chatColour .. "]You have changed the shop price for " .. shopItem .. " to " .. number .. "[-]")

		conn:execute("UPDATE shop SET price = " .. escape(number) .. " WHERE item = '" .. escape(shopItem) .. "'")
		return false
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if (words[2] == "units" and words[3] ~= nil) then
		if (accessLevel(playerid) > 2) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			return false
		end

		LookupShop(words[3])
		number = tonumber(words[4])

		message("pm " .. playerid .. " [" .. server.chatColour .. "]You have changed the units per sale for " .. shopItem .. " to " .. number .. "[-]")

		conn:execute("UPDATE shop SET units = " .. escape(number) .. " WHERE item = '" .. escape(shopItem) .. "'")
		return false
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if (words[2] == "restock" and words[3] ~= nil) then
		if (accessLevel(playerid) > 2) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			return false
		end

		LookupShop(words[3])

		if (tonumber(shopStock) > -1) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]You have added " .. number .. " " .. shopItem .. " to the shop[-]")

			conn:execute("UPDATE shop SET stock = stock + " .. escape(number) .. " WHERE item = '" .. escape(shopItem) .. "'")
			conn:execute("UPDATE shop SET stock = -1 WHERE stock < 0")
		end

		return false
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "buy" and words[2] ~= nil) then
		if server.shopOpenHour ~= server.shopCloseHour then
			if (tonumber(server.gameHour) < tonumber(server.shopOpenHour) or tonumber(server.gameHour) > tonumber(server.shopCloseHour)) and (accessLevel(playerid) > 2) then
				message("pm " .. playerid .. " [" .. server.chatColour .. "]The shop is closed! Go play with zombies or something![-]")
				return false
			end
		end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

		if server.shopLocation ~= "" then
			if not locations[server.shopLocation] then
				-- forget the shop location if the location no longer exists
				server.shopLocation = ""
				conn:execute("UPDATE server SET shopLocation = ''")
			else
				dist = distancexz(igplayers[playerid].xPos, igplayers[playerid].zPos, locations[server.shopLocation].x, locations[server.shopLocation].z)

				if (dist > 20) and (accessLevel(playerid) > 2) then
					message("pm " .. playerid .. " [" .. server.chatColour .. "]The shop is only available at " .. server.shopLocation .. ".[-]")
					message("pm " .. playerid .. " [" .. server.chatColour .. "]Type " .. server.commandPrefix .. server.shopLocation .. " to go there now and " .. server.commandPrefix .. "return when finished.[-]")
					return false
				end
			end
		end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

		LookupShop(words[2], true)

		if words[3] ~= nil then
			number = math.abs(tonumber(words[3]))
		else
			number = 1
		end

		if not cursor == 0 then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]I sell several items called " .. words[2] .. ".  Try again using with one of the following fine wares.")

			cursor,errorString = conn:execute("SELECT * FROM memShop ORDER BY category, item")
			row = cursor:fetch({}, "a")

			while row do
				if tonumber(row.units) == 0 then
					units = 1
				else
					units = row.units
				end

				if tonumber(row.stock) == -1 then
					message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price:  " .. row.price .. " units:  " .. units .. " UNLIMITED STOCK![-]")
				else
					if v.remaining == 0 then
						message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. " units:  " .. units .. "[-]  [FF0000]SOLD OUT[-]")
					else
						message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. " units:  " .. units .. "  (" .. row.stock .. " left)[-]")
					end
				end

				row = cursor:fetch(row, "a")
			end

			return false
		end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

		if (tonumber(players[playerid].cash) > (tonumber(shopPrice) * number)) and ((number <= tonumber(shopStock) or (tonumber(shopStock) == -1))) then
			players[playerid].cash = tonumber(players[playerid].cash) - (tonumber(shopPrice) * number)
			message("pm " .. playerid .. " [" .. server.chatColour .. "]You have purchased " .. number .. " " .. shopItem .. ". You have " .. string.format("%d", players[playerid].cash) .. " " .. server.moneyPlural .. " remaining.[-]")
			unitsPurchased = number

			if tonumber(shopUnits) > 0 then
				number = number * shopUnits
			end

			if tonumber(shopQuality) == 0 then
				cmd = "give " .. playerid .. " " .. shopItem .. " " .. number
			else
				cmd = "give " .. playerid .. " " .. shopItem .. " " .. number .. " " .. shopQuality
			end

			if server.stompy then
				if tonumber(shopQuality) == 0 then
					cmd = "bc-give " .. playerid .. " " .. shopItem .. " /c=" .. number  .. " /silent"
				else
					cmd = "bc-give " .. playerid .. " " .. shopItem .. " /c=" .. number  .. " /silent /q=" .. shopQuality
				end
			end

			if server.botman then
				if tonumber(shopQuality) == 0 then
					cmd = "bm-give " .. playerid .. " " .. shopItem .. " " .. number
				else
					cmd = "bm-give " .. playerid .. " " .. shopItem .. " " .. number  .. " " .. shopQuality
				end
			end

			sendCommand(cmd)

			if server.stompy then
				message("pm " .. playerid .. " [" .. server.chatColour .. "]Your purchase should be in your inventory but may be at your feet.  Check the ground.[-]")
			else
				message("pm " .. playerid .. " [" .. server.chatColour .. "]Your purchase is at your feet.  Grab it before a zombie eats it.[-]")
			end

			conn:execute("UPDATE players SET cash = " .. players[playerid].cash .. " WHERE steam = " .. playerid)
			conn:execute("UPDATE shop SET stock = " .. shopStock - tonumber(unitsPurchased) .. " WHERE item = '" .. escape(shopItem) .. "'")

			return false
		else
			if (number > tonumber(shopStock)) and (tonumber(shopStock) >= 0)  then
				message("pm " .. playerid .. " [" .. server.chatColour .. "]I do not have that many " .. shopItem .. " in stock.[-]")
			else
				message("pm " .. playerid .. " [" .. server.chatColour .. "]I am sorry but you have insufficient " .. server.moneyPlural .. ".[-]")
			end
		end

		return false
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "shop" and words[2] ~= nil and words[3] == nil) then
		cursor,errorString = conn:execute("SELECT * FROM shop")

		if cursor:numrows() == 0 then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]CALL THE POLICE!  The shop is empty![-]")
			return false
		end
	end

if (debug) then dbug("debug shop line " .. debugger.getinfo(1).currentline) end

	if (words[1] == "shop" and words[2] ~= nil and words[3] == nil) then
		LookupShop(words[2])

		cursor,errorString = conn:execute("SELECT * FROM memShop ORDER BY category, item")
		row = cursor:fetch({}, "a")

		while row do
			if tonumber(row.units) == 0 then
				units = 1
			else
				units = row.units
			end

			if tonumber(row.stock) == -1 then
				message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price:  " .. row.price .. " units:  " .. units .. " UNLIMITED STOCK![-]")
			else
				if v.remaining == 0 then
					message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. " units:  " .. units .. "[-]  [FF0000]SOLD OUT[-]")
				else
					message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. " units:  " .. units .. "  (" .. row.stock .. " left)[-]")
				end
			end

			row = cursor:fetch(row, "a")
		end

		return false
	end

if debug then dbug("debug shop end") end
end
