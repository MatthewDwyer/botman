--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_shop()
	local debug, result, tmp, help
	local shortHelp = false

	debug = false -- should be false unless testing

	calledFunction = "gmsg_shop"
	result = false
	tmp = {}
	tmp.topic = "shop"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## shop command functions ##################

	local function cmd_Cash()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}cash or {#}wallet or {#}bank"
			help[2] = "Tells you how many " .. server.moneyPlural .. " you have."

			tmp.command = help[1]
			tmp.keywords = "bank,money,cash,wallet"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "cash") or string.find(chatvars.command, "bank") or string.find(chatvars.command, "wallet") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "cash" or chatvars.words[1] == server.moneyName or chatvars.words[1] == server.moneyPlural or chatvars.words[1] == "bank" or chatvars.words[1] == "wallet") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have " .. string.format("%d", players[chatvars.playerid].cash) .. " " .. server.moneyPlural .. " in the bank.[-]")
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FixShop()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}fix shop"
			help[2] = "Attempt to automatically fix the shop.  It reloads the shop categories, checks for any missing categories in shop items and assigns them to misc then reindexes the shop.\n"
			help[2] = help[2] .. "This fix might not actually fix whatever is wrong with your shop.\n"
			help[2] = help[2] .. "WARNING!  This command will send li * to the server which generates a massive list.  It may cause a lag spike on a full server.\n"
			help[2] = help[2] .. "Due to the size of the data returned by the server, this command is not available in telnet mode.  To use it the bot must be in API mode."

			tmp.command = help[1]
			tmp.keywords = "shop,fix,repair"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "shop") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "fix" and chatvars.words[2] == "shop" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if not server.useAllocsWebAPI then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command is not available in telnet mode.  Your bot must be in API mode.[-]")
				else
					irc_chat(chatvars.ircAlias, "This command is not available in telnet mode.  Your bot must be in API mode.")
				end

				botman.faultyChat = false
				return true
			end

			fixShop()

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Try using the shop and see if it is fixed.  If not repeating the command is not going to fix it this time.[-]")
			else
				irc_chat(chatvars.ircAlias, "Try using the shop and see if it is fixed.  If not repeating the command is not going to fix it this time.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FixShopQuick()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}quick fix shop"
			help[2] = "Like {#}fix shop but doesn't re-read all the item names known to the server so it completes much faster."

			tmp.command = help[1]
			tmp.keywords = "shop,fix,repair"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "shop") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "quick" and chatvars.words[2] == "fix" and chatvars.words[3] == "shop" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			removeInvalidItems()

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Try using the shop and see if it is fixed.  If not repeating the command is not going to fix it this time.[-]")
			else
				irc_chat(chatvars.ircAlias, "Try using the shop and see if it is fixed.  If not repeating the command is not going to fix it this time.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Gamble()
		local r, a, b, cursor, errorString, row, tickets, tempTickets, ticketCount, k, v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}gamble {optional quantity} or {#}buy ticket {optional quantity}"
			help[2] = "Buy a ticket in the next daily lottery."

			tmp.command = help[1]
			tmp.keywords = "buy,lotto,ticket,daily,gamble,lottery,draw,prize"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "lott") or string.find(chatvars.command, "tick") or string.find(chatvars.command, "buy") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "buy" and chatvars.words[2] == "ticket") or chatvars.words[1] == "gamble" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then chatvars.number = 1 end

			if not chatvars.settings.allowLottery then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Sorry but the lottery is closed :([-]")
				botman.faultyChat = false
				return true
			end

			if players[chatvars.playerid].cash < (chatvars.settings.lotteryTicketPrice * math.abs(chatvars.number)) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Sorry " .. players[chatvars.playerid].name .. " but you don't have enough " .. server.moneyPlural .. ".[-]")
				botman.faultyChat = false
				return true
			end

			tickets = {}

			-- start by building a table with all 100 tickets in it
			for a=1,100,1 do
				tickets[a] = {}
				tickets[a].ticket = a
			end

			cursor,errorString = connSQL:execute("SELECT * FROM lottery WHERE steam = '" .. chatvars.playerid .. "'")
			rowSQL = cursor:fetch({}, "a")

			-- now remove each ticket that the player already has
			while rowSQL do
				tickets[rowSQL.ticket] = nil
				rowSQL = cursor:fetch(rowSQL, "a")
			end

			-- copy the remaining tickets into a temp table so we can remove the gaps in the ticket numbering for later
			tempTickets = {}
			b = 1

			for k,v in pairs(tickets) do
				tempTickets[b] = {}
				tempTickets[b].ticket = v.ticket
				b = b + 1
			end

			tickets = tempTickets

			-- get the remaining ticket count
			ticketCount = tablelength(tickets)

			-- no tickets left? Call social services!
			if ticketCount == 0 then
				r = randSQL(5)

				if r == 1 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have every ticket. You should see someone about that.[-]") end
				if r == 2 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have every ticket. You know that isn't chocolate in the golden ticket right? I guess it is brown though.[-]") end
				if r == 3 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There are no tickets left to give! None, nil, zip, zero, nadda. Not even an electronic sausage.[-]") end
				if r == 4 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You can't have any more tickets! Go away! The ticket office is now closed. OUT![-]") end
				if r == 5 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No more tickets sorry. Some maniac has purchased the lot![-]") end

				botman.faultyChat = false
				return true
			end

			-- loop for the number of tickets that the player wants to buy
			for a=1,math.abs(chatvars.number),1 do
				-- pick a random ticket from the remaining tickets
				r = randSQL(ticketCount)
				connSQL:execute("INSERT INTO lottery (steam, ticket) VALUES ('" .. chatvars.playerid .. "'," .. tickets[r].ticket .. ")")
				players[chatvars.playerid].cash = players[chatvars.playerid].cash - chatvars.settings.lotteryTicketPrice

				-- remove the chosen ticket from the remaining tickets
				tickets[r] = nil
				ticketCount = ticketCount - 1

				-- copy the remaining tickets into a temp table so we can remove the gaps in the ticket numbering for later
				-- if we don't do this we might pick a number that was already picked and we'd have to muck around with extra loops and checks
				tempTickets = {}
				b = 1

				for k,v in pairs(tickets) do
					tempTickets[b] = {}
					tempTickets[b].ticket = v.ticket
					b = b + 1
				end

				tickets = tempTickets
			end

			-- shake the player down for the cash they just spent
			conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = '" .. chatvars.playerid .. "'")
			cursor,errorString = connSQL:execute("SELECT count(ticket) as tickets FROM lottery WHERE steam = '" .. chatvars.playerid .. "'")
			row = cursor:fetch({}, "a")

			-- tell the player they're a sucker er I mean how many tickets they have.
			if tonumber(row.tickets) > 0 then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Good Luck!  You have " .. row.tickets .. " tickets in the next draw![-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Lottery()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}lotto or {#}lottery or {#}tickets"
			help[2] = "See how big the lottery is and how many tickets you have in the draw."

			tmp.command = help[1]
			tmp.keywords = "lotto,lottery,ticket,daily,draw,prize"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "lott") or string.find(chatvars.command, "tick") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "lottery" or chatvars.words[1] == "lotto" or chatvars.words[1] == "tickets") then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The lottery prize pool has reached " .. server.lottery .. " " .. server.moneyPlural .. "![-]")
			cursor,errorString = connSQL:execute("SELECT count(ticket) as tickets FROM lottery WHERE steam = '" .. chatvars.playerid .. "'")
			row = cursor:fetch({}, "a")

			if tonumber(row.tickets) > 0 then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have " .. row.tickets .. " tickets in the next draw![-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PayPlayer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}pay {player name} {amount}"
			help[2] = "Pay a player some amount of " .. server.moneyPlural .. ". Admins don't need to have the cash in their balance first."

			tmp.command = help[1]
			tmp.keywords = "pay,cash,money,player"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "pay") or string.find(chatvars.command, "cash") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "pay" and chatvars.words[2] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.cash = tonumber(chatvars.words[chatvars.wordCount])

			if tmp.cash == nil then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You forgot to tell me how much you want to pay.[-]")

				botman.faultyChat = false
				return true
			end

			tmp.cash = math.abs(tmp.cash)
			id = LookupPlayer(chatvars.words[2])

			if id == "0" then
				id = LookupArchivedPlayer(chatvars.words[2])

				if not (id == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if (id ~= "0") then
				players[chatvars.playerid].botQuestion = "pay player"
				players[chatvars.playerid].botQuestionID = id
				players[chatvars.playerid].botQuestionValue = tmp.cash
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You want to pay " .. tmp.cash .. " " .. server.moneyPlural .. " to " .. players[id].name .. "? Type " .. server.commandPrefix .. "yes to complete the transaction or start over.[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Nobody here by that name.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetShop()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reset shop"
			help[2] = "Restock the shop to the max quantity of each item."

			tmp.command = help[1]
			tmp.keywords = "shop,reset,restock"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "shop") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "reset" and chatvars.words[2] == "shop") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			message("say [" .. server.chatColour .. "]Hurrah! >NEW< stock![-]")
			resetShop(true)
			loadShopCategories()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetClearShopLocation()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set shop location {location name}\n"
			help[1] = help[1] .."Or {#}clear shop location"
			help[2] = "Restrict the shop to a specific location.  Buying from the shop will only be possible while in that location (excluding admins).\n"
			help[2] = help[2] .. "Or clear the location so that the shop can be accessed server wide. (the default)"

			tmp.command = help[1]
			tmp.keywords = "shop,set,clear,location"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "shop") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "set" or chatvars.words[1] == "clear") and chatvars.words[2] == "shop" and chatvars.words[3] == "location" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "set" then
				str = string.sub(chatvars.command, string.find(chatvars.command, "location ") + 9)
				str = string.trim(str)
				str = LookupLocation(str)

				if str == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A location is required for this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "A location is required for this command.")
					end

					botman.faultyChat = false
					return true
				end

				server.shopLocation = str
				if botman.dbConnected then conn:execute("UPDATE server SET shopLocation = '" .. str .. "'") end

				if (chatvars.playername ~= "Server") then
					message("say [" .. server.chatColour .. "]The shop is now located at ".. str .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "The shop is now located at ".. str)
				end
			else
				server.shopLocation = ""
				if botman.dbConnected then conn:execute("UPDATE server SET shopLocation = ''") end

				if (chatvars.playername ~= "Server") then
					message("say [" .. server.chatColour .. "]The shop is now available server wide.[-]")
				else
					irc_chat(chatvars.ircAlias, "The shop is now available server wide.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLotteryMultiplier()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set lottery multiplier {number}"
			help[2] = "Every zombie killed adds 1 x the lottery multiplier to the lottery total.  The higher the number, the faster the lottery rises.  The default is 2."

			tmp.command = help[1]
			tmp.keywords = "shop,set,lotto,lottery,daily,prize"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "lott") or string.find(chatvars.command, "gamb") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "lottery" and chatvars.words[3] == "multiplier" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(chatvars.number)

				server.lotteryMultiplier = chatvars.number
				conn:execute("UPDATE server SET lotteryMultiplier = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The lottery will grow by zombie kills multiplied by " .. chatvars.number .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "The lottery will grow by zombie kills multiplied by " .. chatvars.number)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLotteryPrize()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set lottery prize {number}"
			help[2] = "You can set or reset the lottery prize to any number.  Useful if it gets too large."

			tmp.command = help[1]
			tmp.keywords = "shop,set,prize,lotto,lottery,daily"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "lott") or string.find(chatvars.command, "gamb") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "lottery" and (chatvars.words[3] == "prize" or chatvars.words[3] == "value" or chatvars.words[3] == "cash") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.lottery = chatvars.number
				conn:execute("UPDATE server SET lottery = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You reset the daily lottery cash to " .. chatvars.number .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "You reset the daily lottery cash to " .. chatvars.number)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetLotteryTicketPrice()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set lottery ticket price {number}"
			help[2] = "The default cost of a lottery ticket is 25 " .. server.moneyPlural .. ". You can change it to anything above 0."

			tmp.command = help[1]
			tmp.keywords = "shop,set,ticket,price,lotto,lottery"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "shop") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "lottery" and chatvars.words[3] == "ticket" and chatvars.words[4] == "price" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Missing number for ticket price.[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing number for ticket price.")
				end

				botman.faultyChat = false
				return true
			else
				if chatvars.number == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Set a price higher than 0.[-]")
					else
						irc_chat(chatvars.ircAlias, "Set a price higher than 0.")
					end

					botman.faultyChat = false
					return true
				end

				chatvars.number = math.abs(chatvars.number)

				server.lotteryTicketPrice = chatvars.number
				if botman.dbConnected then conn:execute("UPDATE server SET lotteryTicketPrice = " .. chatvars.number) end

				message("say [" .. server.chatColour .. "]Tickets in the daily lottery now cost " .. server.lotteryTicketPrice .. " " .. server.moneyPlural .. ".[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMoneyName()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set money name {singular} {plural}"
			help[2] = "The default money name is the Zenny and the plural is Zennies. Both names must be one word each.\n"
			help[2] = help[2] .. "eg {#}set money name Chip Chips."

			tmp.command = help[1]
			tmp.keywords = "shop,bank,money,cash"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "money") or string.find(chatvars.command, "name") or string.find(chatvars.command, "cash") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "money" and chatvars.words[3] == "name" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.money = chatvars.wordsOld[4]
			tmp.moneyPlural = chatvars.wordsOld[5]

			if tmp.money ~= nil and tmp.moneyPlural ~= nil then
				-- first update the currency name in the locations table
				conn:execute("UPDATE locations SET currency = '" .. escape(tmp.money) .. "' where currency = '" .. escape(server.moneyName) .. "'")

				for k,v in pairs(locations) do
					if v.currency then
						if string.lower(v.currency) == string.lower(server.moneyName) then
							v.currency = tmp.money
						end
					end
				end

				server.moneyName = tmp.money
				server.moneyPlural = tmp.moneyPlural
				conn:execute("UPDATE server SET moneyName = '" .. escape(tmp.money .. "|" .. tmp.moneyPlural) .. "'")

				message("say [" .. server.chatColour .. "]This server now uses money called the " .. server.moneyName ..".  All your old currency is now worthless!  Just kidding xD[-]")
				message("say [" .. server.chatColour .. "]The shop is now accepting your hard won " .. server.moneyPlural ..".[-]")
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]I know your money is worthless, but it still needs a name.[-]")
				else
					irc_chat(chatvars.ircAlias, "I know your money is worthless, but it still needs a name.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetPlaytimeReward()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set playtime reward {" .. server.moneyPlural .. "}"
			help[2] = "Set how many " .. server.moneyPlural .. " a player earns for each minute played. (excludes new players and does not count total time played)"

			tmp.command = help[1]
			tmp.keywords = "shop,set,player,reward,playtime"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "pay") or string.find(chatvars.command, "rate") or string.find(chatvars.command, "cash") or string.find(chatvars.command, "reward") or string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "playtime" and chatvars.words[3] == "reward" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(chatvars.number)

				server.perMinutePayRate = chatvars.number
				conn:execute("UPDATE server SET perMinutePayRate = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will be rewarded " .. chatvars.number .. " " .. server.moneyPlural .. " for every minute played. (exludes new players and isn't retrospective)[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will be rewarded " .. chatvars.number .. " " .. server.moneyPlural .. " for every minute played. (exludes new players and isn't retrospective)")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetShopResetDays()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set shop reset days {number}"
			help[2] = "Restock the shop to the max quantity of each item every {number} of real days.\n"
			help[2] = help[2] .. "A setting of 0 disables the automatic restock.  To manually restock it use {#}reset shop."

			tmp.command = help[1]
			tmp.keywords = "shop,set,reset,days"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "shop") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "shop" and chatvars.words[3] == "reset" and chatvars.words[4] == "days" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Missing number for days.[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing number for days.")
				end

				botman.faultyChat = false
				return true
			else
				chatvars.number = math.abs(chatvars.number)

				server.shopResetDays = chatvars.number
				if botman.dbConnected then conn:execute("UPDATE server SET shopResetDays = " .. chatvars.number) end

				if chatvars.number == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The shop must be manually restocked. You can do that with " .. server.commandPrefix .. "reset shop.[-]")
					else
						irc_chat(chatvars.ircAlias, "The shop must be manually restocked. You can do that with " .. server.commandPrefix .. "reset shop.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The shop will restock after " .. chatvars.number .. " days.[-]")
					else
						irc_chat(chatvars.ircAlias, "The shop will restock after " .. chatvars.number .. " days.")
					end
				end
			end


			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetShopTradingHours()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set shop open (or close) {0 - 23}"
			help[2] = "Enter a number from 0 to 23 which will be the game hour that the shop opens or closes."

			tmp.command = help[1]
			tmp.keywords = "shop,set,hours,time,trade,open,closed"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "shop") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "shop" and (chatvars.words[3] == "open" or string.find(chatvars.words[3], "close")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A number from 0 to 23 is expected (military time)[-]")
				botman.faultyChat = false
				return true
			else
				chatvars.number = math.floor(chatvars.number)

				if tonumber(chatvars.number) < 0 or tonumber(chatvars.number) > 23 then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A number from 0 to 23 is expected (military time)[-]")
					botman.faultyChat = false
					return true
				end

				if chatvars.words[3] == "open" then
					server.shopOpenHour = chatvars.number
					if botman.dbConnected then conn:execute("UPDATE server SET shopOpenHour = " .. chatvars.number) end
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The shop opens at " .. chatvars.number .. ":00 hours[-]")
				else
					server.shopCloseHour = chatvars.number
					if botman.dbConnected then conn:execute("UPDATE server SET shopCloseHour = " .. chatvars.number) end
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The shop closes at " .. chatvars.number .. ":00 hours[-]")
				end

				botman.faultyChat = false
				return true
			end
		end
	end


	local function cmd_SetZombieReward()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set zombie reward {" .. server.moneyPlural .. "}"
			help[2] = "Set how many " .. server.moneyPlural .. " a player earns for each zombie killed."

			tmp.command = help[1]
			tmp.keywords = "shop,set,zeds,zombies,kill,reward"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "zom") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "zombie" and chatvars.words[3] == "reward" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(chatvars.number)

				server.zombieKillReward = chatvars.number
				conn:execute("UPDATE server SET zombieKillReward = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will be awarded " .. chatvars.number .. " " .. server.moneyPlural .. " for every zombie killed.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will be awarded " .. chatvars.number .. " " .. server.moneyPlural .. " for every zombie killed.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBank()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) bank"
			help[2] = "Players can earn " .. server.moneyPlural .. " if the bank is enabled."

			tmp.command = help[1]
			tmp.keywords = "shop,enable,disable,bank,money"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "bank") or string.find(chatvars.command, "cash") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "bank" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.allowBank = true
				conn:execute("UPDATE server SET allowBank = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bank is enabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "This bank is enabled.")
				end
			else
				server.allowBank = false
				conn:execute("UPDATE server SET allowBank = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bank is disabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bank is disabled.")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLottery()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}open (or {#}close) lottery\n"
			help[1] = help[1] .. "Or {#}enable (or {#}disable) lottery"
			help[2] = "Turn on or off the daily lottery.  It is on be default."

			tmp.command = help[1]
			tmp.keywords = "shop,enable,disable,open,closed,daily,lotto,lottery"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "lott") or string.find(chatvars.command, "gamb") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "open" or chatvars.words[1] == "enable" or chatvars.words[1] == "close" or chatvars.words[1] == "disable") and chatvars.words[2] == "lottery" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "open" or chatvars.words[1] == "enable" then
				server.allowLottery = true
				conn:execute("UPDATE server SET allowLottery = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The daily lottery will run at midnight.[-]")
				else
					irc_chat(server.ircMain, "The daily lottery will run at midnight.")
				end
			else
				server.allowLottery = false
				conn:execute("UPDATE server SET allowLottery = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The daily lottery is disabled.[-]")
				else
					irc_chat(server.ircMain, "The daily lottery is disabled.")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleShop()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}open (or {#}close) shop\n"
			help[1] = help[1] .. "Or {#}enable (or {#}disable) shop"
			help[2] = "Enable or disable the shop feature."

			tmp.command = help[1]
			tmp.keywords = "shop,open,closed,enable,disable"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "shop") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "open" or chatvars.words[1] == "close" or string.find(chatvars.command, "able")) and chatvars.words[2] == "shop" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "close" or chatvars.words[1] == "disable" then
				message("say [" .. server.chatColour .. "]The shop is closed.[-]")
				server.allowShop = false

				if botman.dbConnected then conn:execute("UPDATE server SET allowShop = 0") end
			else
				message("say [" .. server.chatColour .. "]The shop is open for business![-]")
				server.allowShop = true

				if botman.dbConnected then conn:execute("UPDATE server SET allowShop = 1") end
				loadShopCategories()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleShowCash()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}show (or {#}hide) cash"
			help[2] = "See an in-game PM every time your cash balance changes."

			tmp.command = help[1]
			tmp.keywords = "show,hide,cash,player,balance,money"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if chatvars.playername == "Server" and (string.find(chatvars.command, "show") or string.find(chatvars.command, "hide") or string.find(chatvars.command, "cash")) and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "show" or chatvars.words[1] == "hide") and chatvars.words[2] == "cash" then
			if chatvars.words[1] == "show" then
				players[chatvars.playerid].watchCash = true
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You will see your " .. server.moneyPlural .. " increase with each zombie kill.[-]")
				conn:execute("UPDATE players SET watchCash = 1 WHERE steam = '" .. chatvars.playerid .. "'")
			else
				players[chatvars.playerid].watchCash = nil
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your " .. server.moneyPlural .. " will not be reported with each zombie kill.[-]")
				conn:execute("UPDATE players SET watchCash = 0 WHERE steam = '" .. chatvars.playerid .. "'")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleSpendingAlert()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) spending alert (default disabled)"
			help[2] = "PM the player every time an a command costs them money.  Tell them how much they spent and what they have left."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,cash,money,alert,spending,cost"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "cash") or string.find(chatvars.command, "able") or string.find(chatvars.command, "alert") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if string.find(chatvars.command, "able") and chatvars.words[2] == "spending" and chatvars.words[3] == "alert" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "disable" then
				server.alertSpending = false

				if botman.dbConnected then conn:execute("UPDATE server SET alertSpending = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will not be PM'ed every time they spend money.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will not be PM'ed every time they spend money.")
				end
			else
				server.alertSpending = true

				if botman.dbConnected then conn:execute("UPDATE server SET alertSpending = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will receive a PM every time they spend money telling them how much they spent and how much they have left.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will receive a PM every time they spend money telling them how much they spent and how much they have left.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		if debug then dbug("Registering help - shop commands") end

		tmp.topicDescription = "The bot's shop allows players to buy items for " .. server.moneyPlural .. ".\n"
		tmp.topicDescription = tmp.topicDescription .. "The shop can be available all the time or within certain hours of the day or from a specific location.\n"
		tmp.topicDescription = tmp.topicDescription .. "While you can manage the shop ingame, it is much easier to do so from the bot's web client."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Shop Commands:")
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, tmp.topicDescription)
			irc_chat(chatvars.ircAlias, ".")
		end

		cursor,errorString = connSQL:execute("SELECT count(*) FROM helpTopics WHERE topic = '" .. tmp.topic .. "'")
		row = cursor:fetch({}, "a")
		rows = row["count(*)"]

		if rows == 0 then
			connSQL:execute("INSERT INTO helpTopics (topic, description) VALUES ('" .. tmp.topic .. "', '" .. connMEM:escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false, ""
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.command, "shop") then
				botman.faultyChat = false
				return true, ""
			end
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and chatvars.words[1] ~= "help" and not botman.registerHelp then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Shop Commands:")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "shop")
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_FixShop()

	if result then
		if debug then dbug("debug cmd_FixShop triggered") end
		return result, "cmd_FixShop"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_FixShopQuick()

	if result then
		if debug then dbug("debug cmd_FixShopQuick triggered") end
		return result, "cmd_FixShopQuick"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetShop()

	if result then
		if debug then dbug("debug cmd_ResetShop triggered") end
		return result, "cmd_ResetShop"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetClearShopLocation()

	if result then
		if debug then dbug("debug cmd_SetClearShopLocation triggered") end
		return result, "cmd_SetClearShopLocation"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLotteryMultiplier()

	if result then
		if debug then dbug("debug cmd_SetLotteryMultiplier triggered") end
		return result, "cmd_SetLotteryMultiplier"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLotteryPrize()

	if result then
		if debug then dbug("debug cmd_SetLotteryPrize triggered") end
		return result, "cmd_SetLotteryPrize"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetLotteryTicketPrice()

	if result then
		if debug then dbug("debug cmd_SetLotteryTicketPrice triggered") end
		return result, "cmd_SetLotteryTicketPrice"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetShopResetDays()

	if result then
		if debug then dbug("debug cmd_SetShopResetDays triggered") end
		return result, "cmd_SetShopResetDays"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetShopTradingHours()

	if result then
		if debug then dbug("debug cmd_SetShopTradingHours triggered") end
		return result, "cmd_SetShopTradingHours"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLottery()

	if result then
		if debug then dbug("debug cmd_ToggleLottery triggered") end
		return result, "cmd_ToggleLottery"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetPlaytimeReward()

	if result then
		if debug then dbug("debug cmd_SetPlaytimeReward triggered") end
		return result, "cmd_SetPlaytimeReward"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetZombieReward()

	if result then
		if debug then dbug("debug cmd_SetZombieReward triggered") end
		return result, "cmd_SetZombieReward"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBank()

	if result then
		if debug then dbug("debug cmd_ToggleBank triggered") end
		return result, "cmd_ToggleBank"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleShop()

	if result then
		if debug then dbug("debug cmd_ToggleBank triggered") end
		return result, "cmd_ToggleShop"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMoneyName()

	if result then
		if debug then dbug("debug cmd_SetMoneyName triggered") end
		return result, "cmd_SetMoneyName"
	end

	if debug then dbug("debug shop end of remote commands") end

	result = cmd_ToggleSpendingAlert()

	if result then
		if debug then dbug("debug cmd_ToggleSpendingAlert triggered") end
		return result, "cmd_ToggleSpendingAlert"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == "0" and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false, ""
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if (chatvars.words[1] == "shop"or chatvars.words[1] == "buy") and chatvars.words[2] ~= "ticket" then
		if (not chatvars.isAdminHidden) and (not chatvars.settings.allowShop) then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The shop is closed.[-]")
			botman.faultyChat = false
			return true, ""
		end

		botman.faultyChat = doShop(chatvars.command, chatvars.playerid, chatvars.gameid, chatvars.words)
		return true, ""
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_Cash()

	if result then
		if debug then dbug("debug cmd_Cash triggered") end
		return result, "cmd_Cash"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_PayPlayer()

	if result then
		if debug then dbug("debug cmd_PayPlayer triggered") end
		return result, "cmd_PayPlayer"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_Lottery()

	if result then
		if debug then dbug("debug cmd_Lottery triggered") end
		return result, "cmd_Lottery"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_Gamble()

	if result then
		if debug then dbug("debug cmd_Gamble triggered") end
		return result, "cmd_Gamble"
	end

if debug then dbug("debug gmsg_shop line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleShowCash()

	if result then
		if debug then dbug("debug cmd_ToggleShowCash triggered") end
		return result, "cmd_ToggleShowCash"
	end

	if botman.registerHelp then
		if debug then dbug("Shop commands help registered") end
	end

	if debug then dbug("end debug gmsg_shop") end

	-- can't touch dis
	if true then
		return result, ""
	end
end
