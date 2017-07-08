--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


local id, page, count, shopState, debug

debug = false

function fixShop()
	-- automatically fix missing categories and check each category and shop item for bad data
	local cursor, cursor2, errorString, row, k, v

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

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
end


function payPlayer()
	if (string.find(chatvars.command, "yes")) then
		if (players[chatvars.playerid].cash >= igplayers[chatvars.playerid].botQuestionValue) or chatvars.accessLevel == 0 then
			players[igplayers[chatvars.playerid].botQuestionID].cash = players[igplayers[chatvars.playerid].botQuestionID].cash + igplayers[chatvars.playerid].botQuestionValue

			if chatvars.accessLevel > 0 then
				players[chatvars.playerid].cash = players[chatvars.playerid].cash - igplayers[chatvars.playerid].botQuestionValue
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[chatvars.playerid].botQuestionValue .. " has been paid to " .. players[igplayers[chatvars.playerid].botQuestionID].name .. "[-]")

			if (igplayers[igplayers[chatvars.playerid].botQuestionID]) then
				message("pm " .. igplayers[chatvars.playerid].botQuestionID .. " [" .. server.chatColour .. "]Payday! " .. players[chatvars.playerid].name .. " has paid you " .. igplayers[chatvars.playerid].botQuestionValue .. " " .. server.moneyPlural .. "![-]")
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I regret to inform you that you do not have sufficient funds to pay " .. players[igplayers[chatvars.playerid].botQuestionID].name .. "[-]")
		end
	end

	igplayers[chatvars.playerid].botQuestion = ""
	igplayers[chatvars.playerid].botQuestionID = nil
	igplayers[chatvars.playerid].botQuestionValue = nil
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

	conn:execute("DELETE FROM memShop")

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
		shopPrice = (row.price + row.variation) * ((100 - row.special) / 100)
		conn:execute("INSERT INTO memShop (item, idx, category, price, stock, code) VALUES ('" .. escape(row.item) .. "'," .. row.idx .. ",'" .. escape(row.category) .. "'," .. (row.price + row.variation) * ((100 - row.special) / 100) .. "," .. row.stock .. ",'" .. escape(shopCode) .. "')")

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
				shopPrice = (row.price + row.variation) * ((100 - row.special) / 100)
				conn:execute("INSERT INTO memShop (item, idx, category, price, stock, code) VALUES ('" .. escape(row.item) .. "'," .. row.idx .. ",'" .. escape(row.category) .. "'," .. (row.price + row.variation) * ((100 - row.special) / 100) .. "," .. row.stock .. ",'" .. escape(shopCode) .. "')")
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


function drawLottery(steam)
	local winners, winnersCount, prizeDraw, x, rows, thing

	if tonumber(server.lottery) == 0 then
		return
	end

	winners = {}
	winnersCount = 0

	if steam ~= nil then
		-- test lottery
		prizeDraw = 500

		conn:execute("INSERT INTO memLottery (steam, ticket) VALUES (" .. steam .. ",500)")
		conn:execute("INSERT INTO lottery (steam, ticket) VALUES (" .. steam .. ",500)")
		winnersCount = 1

		cursor,errorString = conn:execute("SELECT * FROM memLottery WHERE ticket = " .. prizeDraw)
		rows = cursor:numrows()
	else
		local prizePick

		if(debug) then 
			dbugFull("D", "", debugger.getinfo(1,"nSl"), "Start random ticket pick")
		end

		cursor,errorString = conn:execute("SELECT DISTINCT ticket FROM memLottery")
                rows = cursor:numrows()

		if(not rows or rows == 0) then
			winnersCount = 0

			if(debug) then 
				dbugFull("D", "", debugger.getinfo(1,"nSl"), "No tickets to pick from")
			end
		else
			if(debug) then
				dbugFull("D", "", debugger.getinfo(1,"nSl"), "We have " .. rows .. " tickets to pick from")
			end

			if(rows == 1) then
				prizePick = 0
			else
				prizePick = math.random(0, rows - 1)
			end

			if(debug) then 
				dbugFull("D", "", debugger.getinfo(1,"nSl"), "Selected row: " .. prizePick)
			end

			cursor,errorString = conn:execute("SELECT DISTINCT ticket FROM memLottery LIMIT " .. prizePick .. ",1")

			if(not cursor:numrows()) then
				dbugFull("E", "", debugger.getinfo(1,"nSl"), "Failed to select a ticket")
				return
			end

			tmpTble = cursor:fetch({}, "a")

			if(not tmpTble) then
				dbugFull("E", "", debugger.getinfo(1,"nSl"), "Failed to fetch table of winning ticket")
				return
			end

			prizeDraw = tmpTble.ticket

			if(debug) then
				dbugFull("D", "", debugger.getinfo(1,"nSl"), "Winning ticket #: " .. prizeDraw)
			end

			cursor:close()

			cursor,errorString = conn:execute("SELECT * FROM memLottery WHERE ticket = " .. prizeDraw)

                	winnersCount = cursor:numrows()

			if(debug) then
				dbugFull("D", "", debugger.getinfo(1,"nSl"), "Total winners: " .. winnersCount)
			end

		end
--[[
		for x=1,100,1 do
			prizeDraw = math.random(1,100)

			cursor,errorString = conn:execute("SELECT * FROM memLottery WHERE ticket = " .. prizeDraw)
			rows = cursor:numrows()

			if rows > 0 then
				winnersCount = rows
				break
			end
		end
--]]
	end

	message("say [" .. server.chatColour .. "]It's time for the daily lottery draw for " .. server.lottery .. " " .. server.moneyPlural .. "![-]")

	if winnersCount > 0 then
		prizeDraw = math.floor(server.lottery / winnersCount)

		row = cursor:fetch({}, "a")

		if(debug) then
			for k, v in pairs(row) do
				dbug("D", "", debugger.getinfo(1,"nSl"), "k: " .. (k or "nil") .. ", v: " .. (v or "nil"))
			end
		end

		while row do
			if(not players[row.steam]) then
				dbugFull("E", "", debugger.getinfo(1,"nSl"), "Winning player: " .. (row.steam or "nil") .. " was not found in the players table!")
				return
			end

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

			row = cursor:fetch({}, "a")
		end

		message("say [" .. server.chatColour .. "]$$$ Congratulation$ $$$   xD[-]")

		if steam == nil then
			conn:execute("DELETE FROM memLottery")
			conn:execute("DELETE FROM lottery")
			server.lottery = 0
			conn:execute("UPDATE server SET lottery = 0")
		else
			conn:execute("DELETE FROM memLottery where steam = '" .. steam .. "'")
			conn:execute("DELETE FROM lottery where steam = '" .. steam .. "'")
		end
	else
		r = math.random(1,7)
		if (r == 1) then message("say [" .. server.chatColour .. "]Nobody wins again![-]") end
		if (r == 2) then
			thing = PicknMix()
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
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]*CRASH*    BLUUUUEERGH!      AAAAH!  ZOMBIES!   *SCREAM!*[-]") .. "')")
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]CUT!  Go to commercials![-]") .. "')")
		end

		if (r == 6) then
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Tonight's winner is..[-]") .. "')")
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Nobody!  But he's won enough so we're doing a redraw![-]") .. "')")
			tempTimer( 15, [[drawLottery()]] )
		end

		if (r == 7) then
			r = math.random(1,6)
			if r == 1 then thing = "severed head" end
			if r == 2 then thing = "severed hand" end
			if r == 3 then thing = "severed foot" end
			if r == 4 then thing = "mouldy eyeball" end
			if r == 5 then thing = "used nappy" end
			if r == 6 then thing = "rotten cheese" end
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]Tonight's winner is..[-]") .. "')")
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape("[" .. server.chatColour .. "]EWW!  Who put a " .. thing .. " in the bag?  That's gross![-]") .. "')")
		end
	end
end


function resetShop(forced)
	local specialCount, r, i, discCount

	server.shopCountdown = server.shopCountdown - 1

	if tonumber(server.shopCountdown) < 0 or forced ~= nil then
		conn:execute("UPDATE shop SET stock = maxStock")
		server.shopCountdown = 1
	end
end


function doShop(command, playerid, words)
	local k, v, i, number, cmd, list, cursor, errorString

	if (debug) then
		local name = ""

		if(players[playerid]) then
			name = players[playerid].name
		end

		dbugFull("D", "", debugger.getinfo(1,"nSl"), command .. ", " .. playerid .. ", " .. name .. ", " .. accessLevel(playerid) .. ", " .. (words[1] or "") .. ", " .. (words[2] or "") .. ", " .. (words[3] or ""))
	end

	-- check for missing money :O
	if server.moneyName == nil then server.moneyName = "Zenny" end
	if server.moneyPlural == nil then server.moneyPlural = "Zennies" end

	list = ""
	for k, v in pairs(shopCategories) do
		if k ~= "misc" then
			list = list .. k .. ",  "
		end
	end
	list = string.sub(list, 1, string.len(list) - 3)

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	shopState = "[OPEN]"

	if server.shopOpenHour ~= server.shopCloseHour then
		if (tonumber(server.gameHour) < tonumber(server.shopOpenHour) or tonumber(server.gameHour) > tonumber(server.shopCloseHour)) then
			shopState = "[CLOSED]"
		end
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	number = tonumber(string.match(command, " (-?\%d+)"))

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if words[1] == "shop" and words[2] == nil then
		message("pm " .. playerid .. " [" .. server.chatColour .. "]You have " .. players[playerid].cash .. " " .. server.moneyPlural .. " in the bank. Shop is " .. shopState .. "[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Shop categories are " .. list .. ".[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Type shop food (to browse our fine collection of food).[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Stock arrives every 3 days from other zones.[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Type help shop for more info.[-]")
		if (accessLevel(playerid) < 3) then message("pm " .. playerid .. " [" .. server.chatColour .. "]shop admin (for admin commands)[-]") end
		return false
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (words[1] == "shop" and words[2] == "admin") and (accessLevel(playerid) < 3) then
		message("pm " .. playerid .. " [" .. server.chatColour .. "]shop price <code or item name> <whole number without $>[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]shop restock <code or item name> <quantity> or -1 (add quantity to stock)[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]shop special <code or item name> <number from 0 to 100>[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]shop variation <code or item name> <number> (can be negative)[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]You can manage categories and items for sale via IRC.[-]")
		return false
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (shopCategories[words[2]]) then
		LookupShop(words[2],all)

		message("pm " .. playerid .. " [" .. server.chatColour .. "]To buy type buy <code> <quantity>[-]")

		cursor,errorString = conn:execute("SELECT * FROM memShop ORDER BY category, item")
		row = cursor:fetch({}, "a")

		while row do
			if tonumber(row.stock) == -1 then
				message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price:  " .. row.price .. " UNLIMITED STOCK![-]")
			else
				if row.stock == 0 then
					message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. "[-]  [FF0000]SOLD OUT[-]")
				else
					message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price.. "  (" .. row.stock .. " left)[-]")
				end
			end

			row = cursor:fetch(row, "a")
		end

		return false
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (words[2] == "list") then
		list = ""

		for k, v in pairs(shopCategories) do
			list = list .. k .. ",  "
		end
		list = string.sub(list, 1, string.len(list) - 3)

		message("pm " .. playerid .. " [" .. server.chatColour .. "]To browse my wares type shop <category>.  The categories are " .. list .. ".[-]")

		return false
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (words[2] == "variation" and words[3] ~= nil) then
		if (accessLevel(playerid) > 2) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			return false
		end

		LookupShop(words[3])

		message("pm " .. playerid .. " [" .. server.chatColour .. "]You have changed the price variation for " .. shopItem .. " to " .. number .. "[-]")
		conn:execute("UPDATE shop SET variation = " .. number .. " WHERE item = '" .. escape(shopItem) .. "'")

		return false
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (words[2] == "special" and words[3] ~= nil) then
		if (accessLevel(playerid) > 2) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			return false
		end

		LookupShop(words[3])
		number = tonumber(words[4])

		message("pm " .. playerid .. " [" .. server.chatColour .. "]You have changed the shop special for " .. shopItem .. " to " .. number .. "[-]")

		conn:execute("UPDATE shop SET special = " .. number .. " WHERE item = '" .. escape(shopItem) .. "'")
		return false
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (words[2] == "price" and words[3] ~= nil) then
		if (accessLevel(playerid) > 2) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			return false
		end

		LookupShop(words[3])
		number = tonumber(words[4])

		message("pm " .. playerid .. " [" .. server.chatColour .. "]You have changed the shop price for " .. shopItem .. " to " .. number .. "[-]")

		conn:execute("UPDATE shop SET price = " .. number .. " WHERE item = '" .. escape(shopItem) .. "'")
		return false
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (words[2] == "restock" and words[3] ~= nil) then
		if (accessLevel(playerid) > 2) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			return false
		end

		LookupShop(words[3])

		if (tonumber(shopStock) > -1) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]You have added " .. number .. " " .. shopItem .. " to the shop[-]")

			conn:execute("UPDATE shop SET stock = stock + " .. number .. " WHERE item = '" .. escape(shopItem) .. "'")
			conn:execute("UPDATE shop SET stock = -1 WHERE stock < 0")
		end

		return false
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (words[1] == "buy" and words[2] ~= nil) then
		if server.shopOpenHour ~= server.shopCloseHour then
			if (tonumber(server.gameHour) < tonumber(server.shopOpenHour) or tonumber(server.gameHour) > tonumber(server.shopCloseHour)) and (accessLevel(playerid) > 2) then
				message("pm " .. playerid .. " [" .. server.chatColour .. "]The shop is closed! Go play with zombies or something![-]")
				return false
			end
		end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if server.shopLocation ~= nil then
			if not locations[server.shopLocation] then
				server.shopLocation = nil
				conn:execute("UPDATE server SET shopLocation = null")
			else
				dist = distancexz(igplayers[playerid].xPos, igplayers[playerid].zPos, locations[server.shopLocation].x, locations[server.shopLocation].z)

				if (dist > 20) and (accessLevel(playerid) > 2) then
					message("pm " .. playerid .. " [" .. server.chatColour .. "]The shop is only available in the " .. server.shopLocation .. " location.[-]")
					message("pm " .. playerid .. " [" .. server.chatColour .. "]Type " .. server.commandPrefix .. server.shopLocation .. " to go there now and " .. server.commandPrefix .. "return when finished.[-]")
					return false
				end
			end
		end

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		LookupShop(words[2], true)

		if words[3] ~= nil then
			number = tonumber(words[3])

			if(number == nil) then
				number = 1
			elseif(number < 1) then
				number = 1
			end
		else
			number = 1
		end

		if not cursor == 0 then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]I sell several items called " .. words[2] .. ".  Try again using with one of the following fine wares.")

			cursor,errorString = conn:execute("SELECT * FROM memShop ORDER BY category, item")
			row = cursor:fetch({}, "a")

			while row do
				if tonumber(row.stock) == -1 then
					message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price:  " .. row.price .. " UNLIMITED STOCK![-]")
				else
					if v.remaining == 0 then
						message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. "[-]  [FF0000]SOLD OUT[-]")
					else
						message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price.. "  (" .. row.stock .. " left)[-]")
					end
				end

				row = cursor:fetch(row, "a")
			end

			return false
		end

		if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		if (tonumber(players[playerid].cash) > (tonumber(shopPrice) * number)) and ((number <= tonumber(shopStock) or (tonumber(shopStock) == -1))) then
			players[playerid].cash = tonumber(players[playerid].cash) - (tonumber(shopPrice) * number)

			message("pm " .. playerid .. " [" .. server.chatColour .. "]You have purchased " .. number .. " " .. shopItem .. ". You have " .. players[playerid].cash .. " " .. server.moneyPlural .. " remaining.[-]")
			send("give " .. playerid .. " " .. shopItem .. " " .. number)
			message("pm " .. playerid .. " [" .. server.chatColour .. "]Press e now to pick up your purchase.[-]")

			conn:execute("UPDATE players SET cash = " .. players[playerid].cash .. " WHERE steam = " .. playerid)
			conn:execute("UPDATE shop SET stock = " .. shopStock - tonumber(number) .. " WHERE item = '" .. escape(shopItem) .. "'")

			return false
		else
			if (number > tonumber(shopStock)) and (tonumber(shopStock) > 0)  then
				message("pm " .. playerid .. " [" .. server.chatColour .. "]I do not have that many " .. shopItem .. " in stock.[-]")
			else
				message("pm " .. playerid .. " [" .. server.chatColour .. "]I am sorry but you have insufficient " .. server.moneyPlural .. ".[-]")
			end
		end

		return false
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (words[1] == "shop" and words[2] ~= nil and words[3] == nil) then
		cursor,errorString = conn:execute("SELECT * FROM shop")

		if cursor == 0 then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]CALL THE POLICE!  The shop is empty![-]")
			return false
		end
	end

	if (debug) then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (words[1] == "shop" and words[2] ~= nil and words[3] == nil) then
		LookupShop(words[2], true)

		cursor,errorString = conn:execute("SELECT * FROM memShop ORDER BY category, item")
		row = cursor:fetch({}, "a")

		while row do
			if tonumber(row.stock) == -1 then
				message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price:  " .. row.price .. " UNLIMITED STOCK![-]")
			else
				if v.remaining == 0 then
					message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price .. "[-]  [FF0000]SOLD OUT[-]")
				else
					message("pm " .. playerid .. " [" .. server.chatColour .. "]code:  " .. row.code .. "    item:  " .. row.item .. " price: " .. row.price.. "  (" .. row.stock .. " left)[-]")
				end
			end

			row = cursor:fetch(row, "a")
		end

		return false
	end

	if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "Shop end") end
end
