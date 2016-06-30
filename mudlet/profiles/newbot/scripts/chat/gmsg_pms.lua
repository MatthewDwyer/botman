--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
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
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
		return false
	end

	cmd = string.sub(chatvars.command, 2)

	if (chatvars.words[1] == "add" and chatvars.words[2] == "command") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted.[-]")
				faultyChat = false
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
				irc_QueueMsg(server.ircMain, "Message required.")
			end

			faultyChat = false
			return true
		end

		if cmd == nil then
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command required.[-]")
			else
				irc_QueueMsg(server.ircMain, "Command required.")
			end

			faultyChat = false
			return true
		end

		-- strip leading /
		if (string.sub(cmd, 1, 1) == "/") then
			cmd = string.sub(cmd, 2)
		end
	
		conn:execute("INSERT INTO customMessages (command, message, accessLevel) Values ('" .. escape(cmd) .. "','" .. escape(msg) .. "'," .. access .. ") ON DUPLICATE KEY UPDATE accessLevel = " .. access.. ", message = '" .. escape(msg) .. "'")

		if (chatvars.playername ~= "Server") then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added the command: /" .. cmd .. ".[-]")
		else
			irc_QueueMsg(server.ircMain, "You added the command: /" .. cmd)
		end

		-- reload from the database
		loadCustomMessages()

		faultyChat = false
		return true
	end


	if (chatvars.words[1] == "remove" and chatvars.words[2] == "command") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted.[-]")
				faultyChat = false
				return true
			end
		end

		cmd = string.sub(chatvars.command, string.find(chatvars.command, "command") + 9)

		if cmd ~= nil then
			conn:execute("DELETE FROM customMessages WHERE command = '" .. escape(cmd) .. "'")
			customMessages[cmd] = nil

			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed the command /" .. cmd .. ".[-]")
			else
				irc_QueueMsg(server.ircMain, "You removed the command: /" .. cmd)
			end
		else
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command required.[-]")
			else
				irc_QueueMsg(server.ircMain, "Command required.")
			end
		end

		faultyChat = false
		return true
	end


	if (chatvars.words[1] == "custom" and chatvars.words[2] == "commands") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted.[-]")
				faultyChat = false
				return true
			end
		end

		cursor,errorString = conn:execute("SELECT * FROM customMessages")
		row = cursor:fetch({}, "a")

		if not row then
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There are no custom commands.[-]")
			else
				irc_QueueMsg(server.ircMain, "There are no custom commands.")
			end
		else
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Custom commands:[-]")
			else
				irc_QueueMsg(server.ircMain, "Custom commands:")
			end
		end

		while row do
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/" .. row.command .. "[-]")
			else
				irc_QueueMsg(server.ircMain, "/" .. row.command)
			end

			row = cursor:fetch(row, "a")	
		end

		faultyChat = false
		return true
	end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		faultyChat = false
		return false
	end
	-- ####################################################################################

	if customMessages[cmd] then
		cursor,errorString = conn:execute("select * from customMessages where command = '" .. escape(cmd) .. "'")
		row = cursor:fetch({}, "a")

		if row then
			if (accessLevel(chatvars.playerid) <= tonumber(row.accessLevel)) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.message .. "[-]")
				faultyChat = false
				return true
			end

			faultyChat = false
			return true
		end
	end

end
