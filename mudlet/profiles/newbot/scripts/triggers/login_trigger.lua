--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function loginTrigger()
	local file

	if type(botman) ~= "table" then
		botman = {}
		botman.playersOnline = 0
	end

	if server.IP then
		if not exists(homedir .. "/server_address.lua") then
			file = io.open(homedir .. "/server_address.lua", "a")
			file:write("server.IP = \"" .. server.IP .. "\"\n")
			file:write("server.telnetPort = " .. server.telnetPort .. "\n")
			file:close()
		end
	end

	lastAction = "Login"
	botman.botOfflineCount = 0
	botman.botConnectedTimestamp = os.time()
	botman.lastServerResponseTimestamp = os.time()
	send(telnetPassword)
end
