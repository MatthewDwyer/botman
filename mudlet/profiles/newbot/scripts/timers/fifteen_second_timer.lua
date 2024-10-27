--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function FifteenSecondTimer()
	if customFifteenSecondTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customFifteenSecondTimer() then
			return
		end
	end

	-- run a quick test to prove or disprove that we are still connected to the database incase we've fallen off :O
	if not botman.dbConnected then
		openDB()
		openSQLiteDB()
	end

	-- force a re-test of the connection to the bot's database
	botman.dbConnected = isDBConnected()

	if not botman.botsConnected then
		openBotsDB()
	end

	-- force a re-test of the connection to the shared database called bots
	botman.botsConnected = isDBBotsConnected()
end