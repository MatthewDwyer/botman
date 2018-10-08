--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local counter, status, debug, n, help

debug = false -- should be false unless testing

function gmsg_mail()
	local playerName, isArchived

	if botman.debugAll then
		debug = true -- this should be true
	end

	calledFunction = "gmsg_mail"

	if (debug) then dbug("debug mail line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == 0 and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if (chatvars.words[1] == "pm" and chatvars.words[2] ~= nil) then
		if string.find(chatvars.words[2], "admin") then
			msg = string.sub(chatvars.commandOld, string.find(chatvars.commandOld, chatvars.wordsOld[2]) + string.len(chatvars.wordsOld[2]), string.len(chatvars.commandOld))
			msg = "PM from " .. chatvars.playername .. ", " .. msg
			alertAdmins(msg, "chat")

			if chatvars.accessLevel > 2 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Thank you. An admin may respond to your PM.[-]")
			end

			botman.faultyChat = false
			return true
		end

		if string.find(chatvars.words[2], "tag") then
			msg = string.sub(chatvars.commandOld, string.find(chatvars.commandOld, chatvars.wordsOld[3]) + string.len(chatvars.wordsOld[3]), string.len(chatvars.commandOld))
			msg = "PM from " .. chatvars.playername .. ", " .. msg

			for k,v in pairs(igplayers) do
				if string.find(v.name, chatvars.wordsOld[3]) then
					message("pm " .. k .. " [" .. server.chatColour .. "]" .. msg .. "[-]")
				end
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Message sent to all " .. chatvars.wordsOld[3] .. " players that are ingame right now.[-]")

			botman.faultyChat = false
			return true
		end

		msg = string.sub(chatvars.commandOld, 4, string.len(chatvars.commandOld))

		irc_chat(server.ircMain, server.gameDate .. " " .. chatvars.playername .. " said " .. msg)
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your hidden message has been sent to IRC.[-]")

		botman.faultyChat = false
		return true
	end


	-- ####################################################################################
	-- don't proceed if there is no leading slash or pm
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") and not (string.find(chatvars.oldLine, " command 'pm") or string.find(chatvars.oldLine, " command '@")) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	if (debug) then dbug("debug mail line " .. debugger.getinfo(1).currentline) end

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
					conn:execute("UPDATE mail set status = 1 WHERE id = " .. row.id)
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Message " .. counter .. "[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.message .. "[-]")
				end
			else
				conn:execute("UPDATE mail set status = 1 WHERE id = " .. row.id)
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.message .. "[-]")
			end

			counter = counter + 1
			row = cursor:fetch(row, "a")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug mail line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "list" and chatvars.words[2] == "mail") then
		counter = 1

		cursor,errorString = conn:execute("SELECT * FROM mail WHERE recipient = " .. chatvars.playerid)
		row = cursor:fetch({}, "a")
		while row do
			if row.status == "0" then status = " [NEW]" end
			if row.status == "1" then status = " [READ]" end
			if row.status == "2" then status = " [SAVED]" end

			if tonumber(row.sender) == 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "](" .. counter .. ")  Message from server" .. status .. " " .. string.sub(row.message, 1, 100) .. "..[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "](" .. counter .. ")  Message from " .. players[row.sender].name .. status .. " " .. string.sub(row.message, 1, 100) .. "..[-]")
			end

			counter = counter + 1
			row = cursor:fetch(row, "a")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug mail line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "save" and chatvars.words[2] == "mail" and chatvars.number ~= nil) then
		counter = 1

		cursor,errorString = conn:execute("SELECT * FROM mail WHERE recipient = " .. chatvars.playerid)
		row = cursor:fetch({}, "a")
		while row do
			if tonumber(chatvars.number) == counter then
				conn:execute("UPDATE mail SET status = 2 WHERE id = " .. row.id)
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Message (" .. counter .. ") saved.[-]")

				botman.faultyChat = false
				return true
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug mail line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "delete" and chatvars.words[2] == "mail" and chatvars.number ~= nil) then
		counter = 1

		cursor,errorString = conn:execute("SELECT * FROM mail WHERE recipient = " .. chatvars.playerid)
		row = cursor:fetch({}, "a")
		while row do
			if tonumber(chatvars.number) == counter then
				conn:execute("DELETE FROM mail WHERE id = " .. row.id)
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Message (" .. counter .. ") deleted.[-]")

				botman.faultyChat = false
				return true
			end

			counter = counter + 1
			row = cursor:fetch(row, "a")
		end

		botman.faultyChat = false
		return true
	end

	if debug then dbug("debug mail end of remote commands") end

	-- ####################################################################################
	-- don't proceed if commands not hidden
	if not server.hideCommands then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	if (debug) then dbug("debug mail line " .. debugger.getinfo(1).currentline) end

	if (string.find(chatvars.words[1], "@", nil, true) and chatvars.words[2] ~= nil) then
		pname = string.sub(chatvars.words[1], string.find(chatvars.words[1], "@", nil, true) + 1, string.len(chatvars.words[1]))
		pname = string.trim(pname)

		id = LookupPlayer(pname)

		if id == 0 then
			id = LookupArchivedPlayer(pname)

			if not (id == 0) then
				playerName = playersArchived[id].name
				isArchived = true
			end
		end

		n = string.len(chatvars.wordsOld[1]) + 1
		msg = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, chatvars.wordsOld[1], nil, true) + n), string.len(chatvars.oldLine)
		msg = stripQuotes(msg)

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

			botman.faultyChat = false
			return true
		end

		if id ~= 0 then
			if isFriend(id, chatvars.playerid) or chatvars.accessLevel < 3 then
				if igplayers[id] then
					message("pm " .. id .. " [" .. server.chatColour .. "]Message from " .. players[chatvars.playerid].name .. ": " .. msg .. "[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has received your message.[-]")
				else
					if not isArchived then
						conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (" .. chatvars.playerid .. "," .. id .. ", '" .. escape(msg) .. "')")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " will receive your message when they return.[-]")
					else
						conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (" .. chatvars.playerid .. "," .. id .. ", '" .. escape(msg) .. "')")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " will receive your message when they return.[-]")
					end
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has not friended you so you are not allowed to send them private messages yet.[-]")
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I do not know a player called " .. pname .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

if debug then dbug("debug mail end") end

end
