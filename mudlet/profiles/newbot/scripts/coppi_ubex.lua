--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_coppi_ubex()
	calledFunction = "gmsg_coppi_ubex"

	local debug

	debug = false

if debug then dbug("debug coppi ubex start") end
	
	if (chatvars.words[1] == "hide" and chatvars.words[2] == "commands" and chatvars.words[3] == nil)  then
		server.hideCommands = true
		
		if server.coppi then
			send("tcch /")
		end
		
		if server.ubex then
			send("ubex_opt blah hidecmds true")
		end
			
		conn:execute("UPDATE server SET hideCommands = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bot commands are now hidden from global chat.[-]")	
		else
			irc_QueueMsg(server.ircMain, "Bot commands are now hidden from global chat.")
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("debug coppi ubex 1") end

	if (chatvars.words[1] == "show" and chatvars.words[2] == "commands" and chatvars.words[3] == nil) then
		server.hideCommands = true

		if server.coppi then
			send("tcch")
		end
		
		if server.ubex then
			send("ubex_opt blah hidecmds false")
		end

		conn:execute("UPDATE server SET hideCommands = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bot commands are now visible in global chat.[-]")	
		else
			irc_QueueMsg(server.ircMain, "Bot commands are now visible in global chat.")
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("debug coppi ubex 2") end

	if (chatvars.words[1] == "physics" and chatvars.words[2] == "off") then
		server.allowPhysics = false
		
		if server.coppi then
			send("py")
		end
		
		if server.ubex then
			send("ubex_opt blah physics false")
		end
		
		conn:execute("UPDATE server SET allowPhysics = 0")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Physics is disabled.[-]")	
		else
			irc_QueueMsg(server.ircMain, "Physics is disabled.")
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("debug coppi ubex 3") end

	if (chatvars.words[1] == "physics" and chatvars.words[2] == "on") then
		server.allowPhysics = true
		
		if server.coppi then
			send("py")
		end
		
		if server.ubex then
			send("ubex_opt blah physics true")
		end
		
		conn:execute("UPDATE server SET allowPhysics = 1")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Physics is enabled.[-]")	
		else
			irc_QueueMsg(server.ircMain, "Physics is enabled.")
		end
		
		faultyChat = false
		return true
	end
	
if debug then dbug("debug coppi ubex end") end

end
