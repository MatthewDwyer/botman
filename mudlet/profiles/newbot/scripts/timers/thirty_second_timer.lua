--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function thirtySecondTimer()
	cecho(server.windowDebug, "30 second timer\n")

	if dbConnected ~= true then
		openDB()
		dbConnected = isDBConnected()
	end

	-- are we still connected to botsDB?
	db2Connected = isDBBotsConnected()

	if botDisabled then
		return
	end

	if (AnnounceBot == true) then
		message("say [" .. server.chatColour .. "]" .. server.botName .. " is online. Command me. :3[-]")
		AnnounceBot = false
	end

	math.randomseed( os.time() )

	if (initError == true) then
		message("say [" .. server.chatColour .. "]" .. server.botName .. " encountered a problem starting up.  Attempting automatic fix..[-]")
		gatherServerData()
		initError = false
		AnnounceBot = true
	end

	send("gt")

	newDay()

	-- scan player inventories
	for k, v in pairs(igplayers) do
		if (igplayers[k].killTimer == nil) then igplayers[k].killTimer = 9 end

		if tonumber(igplayers[k].killTimer) < 2 then
			cmd = "si " .. k
			conn:execute("INSERT into commandQueue (command, steam) VALUES ('" .. cmd .. "'," .. k .. ")")					
		end

		-- kick player if currently banned or permabanned
	--	if players[k].permanentBan == true then
	--		send("kick " .. k)
	--	end

	--	cursor,errorString = conn:execute("SELECT * FROM bans WHERE steam = " .. k .. " and expirydate > " .. os.date("%Y-%m-%d %H:%M:%S"))
	--	if cursor:numrows() > 0 then
	--		send("kick " .. k)
	--	end
	end

	cmd = "DoneInventory"
	conn:execute("INSERT into commandQueue (command) VALUES ('" .. cmd .. "')")					

	-- logout anyone on irc who hasn't typed anything and their session has expired
	for k,v in pairs(players) do
		if v.ircAuthenticated == true then
			if v.ircSessionExpiry == nil then 
				v.ircAuthenticated = false
			else
				if (v.ircSessionExpiry - os.time()) < 0 then
					v.ircAuthenticated = false
				end	
			end
		end
	end

	-- update the shared database (bots) server table (mainly for players online and a timestamp so others can see we're still online
	updateBotsServerTable()

	if tonumber(playersOnline) > 0 and tonumber(playersOnline) < 10 then
		if scanZombies then send("le") end
	end
end
