--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


--[[
shop commands
=============
shop
buy
cash
pay
zennies
bank
gamble
wallet
lottery
show cash
hide cash
--]]

function gmsg_shop()
	calledFunction = "gmsg_shop"

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
		return false
	end


	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		faultyChat = false
		return false
	end
	-- ####################################################################################


	if (chatvars.words[1] == "shop"or chatvars.words[1] == "buy") then
		if (accessLevel(chatvars.playerid) > 2) and (server.allowShop == false) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The shop is closed until further notice.[-]")
			faultyChat = false
			return true
		end

		faultyChat = doShop(chatvars.command, chatvars.playerid, chatvars.words)
		return true
	end


	if (chatvars.words[1] == "cash" or chatvars.words[1] == "pay" or chatvars.words[1] == "zennies" or chatvars.words[1] == "bank" or chatvars.words[1] == "gamble" or chatvars.words[1] == "wallet") then
		faultyChat = doShop(chatvars.command, chatvars.playerid, chatvars.words)
		return true
	end


	if (chatvars.words[1] == "zcoins" or chatvars.words[1] == "zgate") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No zgates or zcoins here. We are using our own server bot :3[-]")
		faultyChat = false
		return true
	end


	if (chatvars.words[1] == "lottery" or chatvars.words[1] == "lotto" or chatvars.words[1] == "tickets") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The lottery prize pool has reached " .. server.lottery .. " zennies![-]")
		cursor,errorString = conn:execute("SELECT count(ticket) as tickets FROM lottery WHERE steam = " .. chatvars.playerid)
		row = cursor:fetch({}, "a")

		if tonumber(row.tickets) > 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have " .. row.tickets .. " tickets in the next draw![-]")
		end

		faultyChat = false
		return true
	end


	if (chatvars.words[1] == "show" and chatvars.words[2] == "cash") then
		players[chatvars.playerid].watchCash = true
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will see your zennies increase with each zombie kill.[-]")
		conn:execute("UPDATE players SET watchCash = 1 WHERE steam = " .. chatvars.playerid)

		faultyChat = false
		return true
	end


	if (chatvars.words[1] == "hide" and chatvars.words[2] == "cash") then
		players[chatvars.playerid].watchCash = nil
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your zennies will not be reported with each zombie kill.[-]")
		conn:execute("UPDATE players SET watchCash = 0 WHERE steam = " .. chatvars.playerid)

		faultyChat = false
		return true
	end


	if (chatvars.words[1] == "yes" and chatvars.words[2] == nil) then
		if igplayers[chatvars.playerid].botQuestion == "pay player" then
			payPlayer()

			faultyChat = false
			return true
		end
	end

end
