--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug = false

function gmsg_shop()
	calledFunction = "gmsg_shop"
	local tmp

	if(server.allowShop) then
		tmp = "Open"
	else
		tmp = "Closed"
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	-- ###################  do not allow remote commands beyond this point ################
	if (tonumber(chatvars.playerid) < 1) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), chatvars.command .. ", " .. (chatvars.words[1] or "") .. ", " .. (chatvars.words[2] or "") .. ", " .. (chatvars.words[3] or "") .. ", " .. (chatvars.accessLevel or "Undefined") .. ", " .. tmp) end

	if (chatvars.words[1] == "shop" or chatvars.words[1] == "buy") and chatvars.words[2] ~= "ticket" then
		if (chatvars.accessLevel > 2) and (server.allowShop == false) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The shop is closed until further notice.[-]")
			botman.faultyChat = false
			return true
		end

		if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

		botman.faultyChat = doShop(chatvars.command, chatvars.playerid, chatvars.words)
		return true
	end

	if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (chatvars.words[1] == "cash" or chatvars.words[1] == server.moneyName or chatvars.words[1] == server.moneyPlural or chatvars.words[1] == "bank" or chatvars.words[1] == "wallet") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have " .. players[chatvars.playerid].cash .. " " .. server.moneyPlural .. " in the bank.[-]")
		botman.faultyChat = false
		return true
	end

	if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (chatvars.words[1] == "pay" and chatvars.words[2] ~= nil) then
		id = LookupPlayer(chatvars.words[2])
		if (id ~= nil) then
			igplayers[chatvars.playerid].botQuestion = "pay player"
			igplayers[chatvars.playerid].botQuestionID = id
			igplayers[chatvars.playerid].botQuestionValue = math.abs(chatvars.number)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You want to pay " .. math.abs(chatvars.number) .. " " .. server.moneyPlural .. " to " .. players[id].name .. "? Type " .. server.commandPrefix .. "yes to complete the transaction or start over.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (chatvars.words[1] == "lottery" or chatvars.words[1] == "lotto" or chatvars.words[1] == "tickets") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The lottery prize pool has reached " .. server.lottery .. " " .. server.moneyPlural .. "![-]")
		cursor,errorString = conn:execute("SELECT count(ticket) as tickets FROM lottery WHERE steam = " .. chatvars.playerid)
		row = cursor:fetch({}, "a")

		if tonumber(row.tickets) > 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have " .. row.tickets .. " tickets in the next draw![-]")
		end

		botman.faultyChat = false
		return true
	end

	if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (chatvars.words[1] == "buy" and chatvars.words[2] == "ticket") or chatvars.words[1] == "gamble" then
		if chatvars.number == nil then chatvars.number = 1 end

		if players[chatvars.playerid].cash < (25 * math.abs(chatvars.number)) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry " .. players[chatvars.playerid].name .. " but you don't have enough " .. server.moneyPlural .. ".[-]")
			botman.faultyChat = false
			return true
		end


		for i=1,math.abs(chatvars.number),1 do
			found = false
			tries = 0
			gotTicket = false

			while not gotTicket do
				r = math.random(1,100)

				cursor,errorString = conn:execute("SELECT * FROM memLottery WHERE steam = " .. chatvars.playerid .. " AND ticket = " .. r)
				rows = cursor:numrows()

				if rows > 0 then
					found = true
					break
				end

				if not found then
					conn:execute("INSERT INTO memLottery (steam, ticket) VALUES (" .. chatvars.playerid .. "," .. r .. ")")
					conn:execute("INSERT INTO lottery (steam, ticket) VALUES (" .. chatvars.playerid .. "," .. r .. ")")

					players[chatvars.playerid].cash = players[chatvars.playerid].cash - 25
					break
				end

				tries = tries + 1
				if (tries > 100) then
					break
				end
			end
		end

		conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = " .. chatvars.playerid)

		cursor,errorString = conn:execute("SELECT count(ticket) as tickets FROM lottery WHERE steam = " .. chatvars.playerid)
		-- row = cursor:fetch(row, "a")
		row = cursor:fetch({}, "a")

		if(row) then
			if(row.tickets == nil) then
				row = nil
			end
		else
			dbugFull("E", "", debugger.getinfo(1,"nSl"), "No row returned from SELECT count(ticket) as tickets FROM lottery WHERE steam = " .. chatvars.playerid)
		end

		if(not row) then
			dbugFull("E", "" , debugger.getinfo(1,"nSl"), "Unable to read lottory tickets for: " .. chatvars.playerid .. "(" .. (errorString or "") .. ")")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] Unable to verify ticket purchase, please contact an admin!")
		else
			if(row.tickets ~= nil) then
				if(tonumber(row.tickets)) > 0 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Good Luck!  You have " .. row.tickets .. " tickets in the next draw![-]")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (chatvars.words[1] == "show" and chatvars.words[2] == "cash") then
		players[chatvars.playerid].watchCash = true
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will see your " .. server.moneyPlural .. " increase with each zombie kill.[-]")
		conn:execute("UPDATE players SET watchCash = 1 WHERE steam = " .. chatvars.playerid)

		botman.faultyChat = false
		return true
	end

	if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (chatvars.words[1] == "hide" and chatvars.words[2] == "cash") then
		players[chatvars.playerid].watchCash = nil
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your " .. server.moneyPlural .. " will not be reported with each zombie kill.[-]")
		conn:execute("UPDATE players SET watchCash = 0 WHERE steam = " .. chatvars.playerid)

		botman.faultyChat = false
		return true
	end

	if debug then dbugFull("D", "", debugger.getinfo(1,"nSl")) end

	if (chatvars.words[1] == "yes" and chatvars.words[2] == nil) then
		if igplayers[chatvars.playerid].botQuestion == "pay player" then
			payPlayer()

			botman.faultyChat = false
			return true
		end
	end

	if debug then dbugFull("D", "", debugger.getinfo(1,"nSl"), "End gmsg_shop") end

end
