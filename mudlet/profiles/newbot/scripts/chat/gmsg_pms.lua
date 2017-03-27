--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


--[[
private message messages
=============
These are stored in the table customMessages.  Currently they are limited to simple private text responses.
add command
remove command
custom commands
--]]

function gmsg_pms()
	calledFunction = "gmsg_pms"

	local access, msg, cmd

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	cmd = string.sub(chatvars.command, 2)

	if (chatvars.words[1] == "add" and chatvars.words[2] == "command") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted.[-]")
				botman.faultyChat = false
				return true
			end
		end

		access = 99
		cmd = nil

		if string.find(chatvars.command, "message") then
			msg = string.sub(chatvars.command, string.find(chatvars.command, "message") + 8)

			if string.find(chatvars.command, "level") then
				cmd = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "command") + 8, string.find(chatvars.oldLine, "level") - 2)
				access = string.sub(chatvars.command, string.find(chatvars.command, "level") + 6, string.find(chatvars.command, "message") - 2)
			else
				cmd = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "command") + 8, string.find(chatvars.oldLine, "message") - 2)
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Message required.[-]")
			else
				irc_chat(server.ircMain, "Message required.")
			end

			botman.faultyChat = false
			return true
		end

		if cmd == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command required.[-]")
			else
				irc_chat(server.ircMain, "Command required.")
			end

			botman.faultyChat = false
			return true
		end

		-- strip leading /
		if (string.sub(cmd, 1, 1) == server.commandPrefix and server.commandPrefix ~= "") then
			cmd = string.sub(cmd, 2)
		end

		conn:execute("INSERT INTO customMessages (command, message, accessLevel) Values ('" .. escape(cmd) .. "','" .. escape(msg) .. "'," .. access .. ") ON DUPLICATE KEY UPDATE accessLevel = " .. access.. ", message = '" .. escape(msg) .. "'")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added the command: " .. server.commandPrefix .. cmd .. ".[-]")
		else
			irc_chat(server.ircMain, "You added the command: " .. server.commandPrefix .. cmd)
		end

		-- reload from the database
		loadCustomMessages()

		botman.faultyChat = false
		return true
	end


	if (chatvars.words[1] == "remove" and chatvars.words[2] == "command") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted.[-]")
				botman.faultyChat = false
				return true
			end
		end

		cmd = string.sub(chatvars.command, string.find(chatvars.command, "command") + 9)

		if cmd ~= nil then
			conn:execute("DELETE FROM customMessages WHERE command = '" .. escape(cmd) .. "'")
			customMessages[cmd] = nil

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed the command " .. server.commandPrefix .. cmd .. ".[-]")
			else
				irc_chat(server.ircMain, "You removed the command: " .. server.commandPrefix .. cmd)
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command required.[-]")
			else
				irc_chat(server.ircMain, "Command required.")
			end
		end

		botman.faultyChat = false
		return true
	end


	if (chatvars.words[1] == "custom" and chatvars.words[2] == "commands") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted.[-]")
				botman.faultyChat = false
				return true
			end
		end

		cursor,errorString = conn:execute("SELECT * FROM customMessages")
		row = cursor:fetch({}, "a")

		if not row then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There are no custom commands.[-]")
			else
				irc_chat(server.ircMain, "There are no custom commands.")
			end
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Custom commands:[-]")
			else
				irc_chat(server.ircMain, "Custom commands:")
			end
		end

		while row do
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. row.command .. "[-]")
			else
				irc_chat(server.ircMain, server.commandPrefix .. row.command)
			end

			row = cursor:fetch(row, "a")
		end

		botman.faultyChat = false
		return true
	end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	if customMessages[cmd] then
		cursor,errorString = conn:execute("select * from customMessages where command = '" .. escape(cmd) .. "'")
		row = cursor:fetch({}, "a")

		if row then
			if (chatvars.accessLevel <= tonumber(row.accessLevel)) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.message .. "[-]")
				botman.faultyChat = false
				return true
			end

			botman.faultyChat = false
			return true
		end
	end

end
