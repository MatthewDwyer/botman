--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


--[[
mail commands
=============


--]]

function gmsg_mail()
	calledFunction = "gmsg_mail"

	local counter, status, debug, n

	debug = false

if debug then dbug("debug mail") end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		faultyChat = false
		return false
	end
	-- ####################################################################################

	if (chatvars.words[1] == "pm" and chatvars.words[2] ~= nil) then
		msg = string.sub(chatvars.command, 4, string.len(chatvars.command))		

		irc_QueueMsg(server.ircMain, gameDate .. " " .. chatvars.playername .. " said " .. msg)
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your hidden message has been sent to IRC.[-]")

		faultyChat = false
		return true
	end


	-- ####################################################################################
	-- don't proceed if there is no leading slash or pm
	if (string.sub(chatvars.command, 1, 1) ~= "/") and not (string.find(chatvars.oldLine, " command 'pm") or string.find(chatvars.oldLine, " command '@")) then
		faultyChat = false
		return false
	end
	-- ####################################################################################

if debug then dbug("debug mail 1") end

	if (chatvars.words[1] == "read" and chatvars.words[2] == "mail") then
		counter = 1

		if chatvars.number ~= nil then
			cursor,errorString = conn:execute("SELECT * FROM mail WHERE recipient = " .. chatvars.playerid)
		else
			cursor,errorString = conn:execute("SELECT * FROM mail WHERE recipient = " .. chatvars.playerid .. " and status = 0")
		end

		row = cursor:fetch({}, "a")
		while row do
			if chatvars.number ~= nil then
				if tonumber(chatvars.number) == counter then
					conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (" .. row.sender .. "," .. row.recipient .. ",'" .. escape(row.message) .. "')")
					conn:execute("UPDATE mail set status = 1 WHERE id = " .. row.id)
				end
			else
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (" .. row.sender .. "," .. row.recipient .. ",'" .. escape(row.message) .. "')")
				conn:execute("UPDATE mail set status = 1 WHERE id = " .. row.id)
			end

			counter = counter + 1
			row = cursor:fetch(row, "a")	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug mail 2") end

	if (chatvars.words[1] == "list" and chatvars.words[2] == "mail") then
		counter = 1

		cursor,errorString = conn:execute("SELECT * FROM mail WHERE recipient = " .. chatvars.playerid)
		row = cursor:fetch({}, "a")
		while row do
			if row.status == "0" then status = " [NEW]" end
			if row.status == "1" then status = " [READ]" end
			if row.status == "2" then status = " [SAVED]" end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "](" .. counter .. ")  Message from " .. players[row.sender].name .. status .. " " .. string.sub(row.message, 1, 12) .. "..[-]")

			counter = counter + 1
			row = cursor:fetch(row, "a")	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug mail 3") end

	if (chatvars.words[1] == "save" and chatvars.words[2] == "mail" and chatvars.number ~= nil) then
		counter = 1

		cursor,errorString = conn:execute("SELECT * FROM mail WHERE recipient = " .. chatvars.playerid)
		row = cursor:fetch({}, "a")
		while row do
			if tonumber(chatvars.number) == counter then
				conn:execute("UPDATE mail SET status = 2 WHERE id = " .. row.id)
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Message (" .. counter .. ") saved.[-]")

				faultyChat = false
				return true
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug mail 4") end

	if (chatvars.words[1] == "delete" and chatvars.words[2] == "mail" and chatvars.number ~= nil) then
		counter = 1

		cursor,errorString = conn:execute("SELECT * FROM mail WHERE recipient = " .. chatvars.playerid)
		row = cursor:fetch({}, "a")
		while row do
			if tonumber(chatvars.number) == counter then
				conn:execute("DELETE FROM mail WHERE id = " .. row.id)
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Message (" .. counter .. ") deleted.[-]")

				faultyChat = false
				return true
			end

			counter = counter + 1
			row = cursor:fetch(row, "a")	
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug mail 5") end

	-- ####################################################################################
	-- don't proceed if not using the console
	if not string.find(chatvars.oldLine, " command 'pm") and not server.coppi then
		faultyChat = false
		return false
	end
	-- ####################################################################################

if debug then dbug("debug mail 6") end

	if (string.find(chatvars.words[1], "@") and chatvars.words[2] ~= nil) then
		pname = string.sub(chatvars.words[1], 2, string.len(chatvars.words[1]))
		pname = string.trim(pname)

		id = LookupPlayer(pname)
		n = string.len(chatvars.wordsOld[1]) + 1
		msg = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, chatvars.wordsOld[1], nil, true) + n), string.len(chatvars.oldLine)

if debug then dbug("debug mail msg" .. msg) end

		if string.lower(pname) == "admin" or  string.lower(pname) == "admins" then
			for k,v in pairs(players) do
				if accessLevel(k) < 3 then
					if igplayers[k] then
						message("pm " .. k .. " [" .. server.chatColour .. "]Message from " .. players[chatvars.playerid].name .. ": " .. msg .. "[-]")
					else
						conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (" .. chatvars.playerid .. "," .. k .. ", '" .. escape(msg) .. "')")
					end
				end
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Thank you. An admin will receive your message soon.[-]")

			faultyChat = false
			return true
		end

		if id ~= nil then
			if isFriend(id, chatvars.playerid) or accessLevel(chatvars.playerid) < 3 then
				if igplayers[id] then
					message("pm " .. id .. " [" .. server.chatColour .. "]Message from " .. players[chatvars.playerid].name .. ": " .. msg .. "[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has received your message.[-]")
				else
					conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (" .. chatvars.playerid .. "," .. id .. ", '" .. escape(msg) .. "')")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " will receive your message when they return.[-]")
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has not friended you so you are not allowed to send them private messages yet.[-]")
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I do not know a player called " .. pname .. "[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug mail end") end

end
