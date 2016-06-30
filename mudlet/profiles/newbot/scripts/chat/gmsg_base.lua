--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_base()
	calledFunction = "gmsg_base"

	local id, pname, psize,  words, word, dist, debug, dist1, dist2, wait, loc, reset
	local shortHelp = false
	local skipHelp = false

	debug = false

if debug then dbug("debug base 0") end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
		return false
	end
	
	if chatvars.showHelp then
		if chatvars.words[3] then		
			if chatvars.words[3] ~= "base" then
				skipHelp = true
			end
		end
		if chatvars.words[1] == "help" then
			skipHelp = false
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Base Commands:")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "==============")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
	end
  
	if (chatvars.words[1] == "set" and (chatvars.words[2] == "base" or chatvars.words[2] == "base2") and chatvars.words[3] == "size") then
		if (chatvars.playername ~= "Server") then
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				chatvars.faultyChat = false
				return true
			end
		end

		pname = ""
		words = {}
		for word in chatvars.command:gmatch("%w+") do table.insert(words, word) end

		id = LookupPlayer(chatvars.words[5])
		if (players[id]) then
			pname = players[id].name
		end

		psize = string.match(chatvars.command, " (%d+)")
		psize = tonumber(psize)

		if (pname == "") then
			faultyChat = false
			return
		end

		if (chatvars.words[2] == "base") then
			if (players[id]) then players[id].protectSize = psize end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .."'s base is protected to " .. psize .. " metres from their base teleport[-]")
			conn:execute("UPDATE players SET protectSize = " .. psize .. " WHERE steam = " .. id)

			if db2Connected then
				-- update player in bots db
				connBots:execute("UPDATE players SET protectSize = " .. psize .. " WHERE steam = " .. id .. " AND botID = " .. server.botID)
			end
		else
			if (accessLevel(id) < 11) then
				if (players[id]) then players[id].protect2Size = psize end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .."'s 2nd base is protected to " .. psize .. " metres from their base teleport[-]")
				conn:execute("UPDATE players SET protect2Size = " .. psize .. " WHERE steam = " .. id)

				if db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET protect2Size = " .. psize .. " WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug base 1") end

	if (chatvars.words[1] == "setbed") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/setbed makes your nearest base your spawn point after you die.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Unlike a real bed, this can't be broken or stolen. Also it doesn't show up on the map or compass.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Use it within 50 metres of your base.[-]")

		dist = distancexz(chatvars.intX, chatvars.intZ, players[chatvars.playerid].homeX, players[chatvars.playerid].homeZ)
		if dist < 50 then
			players[chatvars.playerid].bed = "base1"
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will respawn at your first base after death.[-]")

			conn:execute("UPDATE players SET bed = 'base1' WHERE steam = " .. id)
		end

		if (players[chatvars.playerid].homeX ~= 0 and players[chatvars.playerid].homeZ ~= 0) then
			dist = distancexz(chatvars.intX, chatvars.intZ, players[chatvars.playerid].home2X, players[chatvars.playerid].home2Z)
			if dist < 50 then
				players[chatvars.playerid].bed = "base2"
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will respawn at your second base after death.[-]")

				conn:execute("UPDATE players SET bed = 'base2' WHERE steam = " .. id)
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug base 2") end

	if (chatvars.words[1] == "sethome" or chatvars.words[1] == "setbase" or chatvars.words[1] == "sethome2" or chatvars.words[1] == "setbase2") and chatvars.words[2] == nil then
		if (players[chatvars.playerid].timeout == true) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. Trust me, you don't want your base here.[-]")
			faultyChat = false
			return true
		end

		loc, reset = inLocation(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos)

		if resetRegions[chatvars.region] or reset then --  and (accessLevel(chatvars.playerid) > 2 or server.ignoreAdmins == false)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in a reset zone. Do not set your base here. It will be deleted when this zone is reset.[-]")
			faultyChat = false
			return true
		end

		if not validPosition(chatvars.playerid, true) then
			faultyChat = false
			return true
		end

		for k, v in pairs(locations) do
			if v.village == nil then
				dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, locations[k].x, locations[k].z)

				if locations[k].size ~= nil then
					psize = locations[k].size
				else
					psize = server.baseSize
				end

				if v.allowBase == true then
					psize = 0
				end

				if dist <= tonumber(psize) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are too close to a location.  You are not allowed to set your base here.[-]")
					faultyChat = false
					return true
				end
			end
		end

		-- set the players home coords
		if (chatvars.words[1] == "sethome" or chatvars.words[1] == "setbase") then
			players[chatvars.playerid].homeX = chatvars.intX
			players[chatvars.playerid].homeY = chatvars.intY
			players[chatvars.playerid].homeZ = chatvars.intZ
			players[chatvars.playerid].exitX = chatvars.intX
			players[chatvars.playerid].exitY = chatvars.intY
			players[chatvars.playerid].exitZ = chatvars.intZ
			players[chatvars.playerid].protect = false
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is your new home location.[-]")

			conn:execute("UPDATE players SET homeX = " .. chatvars.intX .. ", homeY = " .. chatvars.intY .. ", homeZ = " .. chatvars.intZ .. ", exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. ", protect = 0 WHERE steam = " .. chatvars.playerid)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. serverTime .. "','setbase','Player " .. escape(players[chatvars.playerid].name) .. " set a base'," .. chatvars.playerid .. ")")
			removeInvalidHotspots(chatvars.playerid)
			irc_QueueMsg(server.ircWatch, players[chatvars.playerid].name .. " has setbase at " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ)

			if db2Connected then
				-- update player in bots db
				connBots:execute("UPDATE players SET homeX = " .. chatvars.intX .. ", homeY = " .. chatvars.intY .. ", homeZ = " .. chatvars.intZ .. ", exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. ", protect = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
			end
		else
			if accessLevel(chatvars.playerid) < 11 then
				players[chatvars.playerid].home2X = chatvars.intX
				players[chatvars.playerid].home2Y = chatvars.intY
				players[chatvars.playerid].home2Z = chatvars.intZ
				players[chatvars.playerid].exit2X = chatvars.intX
				players[chatvars.playerid].exit2Y = chatvars.intY
				players[chatvars.playerid].exit2Z = chatvars.intZ
				players[chatvars.playerid].protect2 = false
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is the location of your 2nd base.[-]")

				conn:execute("UPDATE players SET home2X = " .. chatvars.intX .. ", home2Y = " .. chatvars.intY .. ", home2Z = " .. chatvars.intZ .. ", exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. ", protect2 = 0 WHERE steam = " .. chatvars.playerid)
				removeInvalidHotspots(chatvars.playerid)
				irc_QueueMsg(server.ircWatch, players[chatvars.playerid].name .. " has setbase 2 at " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ)

				if db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET home2X = " .. chatvars.intX .. ", home2Y = " .. chatvars.intY .. ", home2Z = " .. chatvars.intZ .. ", exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. ", protect2 = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have 2 bases. Consider donating. =D[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Please let us know if you are still seeing this message after donating.[-]")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug base 3") end

	if (chatvars.words[1] == "protect" or chatvars.words[1] == "protect2") and chatvars.words[2] ~= "village" then
if debug then dbug("debug base 3b") end
		if server.disableBaseProtection or server.gameType == "pvp" then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base protection is disabled on this server.  Use claim blocks instead.[-]")
			faultyChat = false
			return true
		end

		-- allow base protection after player has played 30 minutes
		if (players[chatvars.playerid].newPlayer == true) and (players[chatvars.playerid].timeOnServer + igplayers[chatvars.playerid].sessionPlaytime < 1800) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is not available to you yet.  It will be automatically unlocked soon.[-]")
			faultyChat = false
			return true
		end

		id = chatvars.playerid

		if (chatvars.words[2] ~= nil and accessLevel(chatvars.playerid) < 4) then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "protect") + 8)
			pname = string.trim(pname)
			id = LookupPlayer(pname)
		end

		if players[chatvars.playerid].inLocation ~= "" then
			if locations[players[chatvars.playerid].inLocation].pvp or server.gameType == "pvp" then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base protection is not allowed where PVP rules are in effect.[-]")
				faultyChat = false
				return true
			end
		end

		if not validPosition(chatvars.playerid, true) then
			faultyChat = false
			return true
		end

		if chatvars.words[1] == "protect" then
			dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, players[id].homeX, players[id].homeZ)
		else
			dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, players[id].home2X, players[id].home2Z)
		end

		if (chatvars.words[1] == "protect") then
			if (tonumber(dist) <  tonumber(players[id].protectSize) + 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are too close to the base, but just walk away and I will set it when you are far enough away.[-]")
				igplayers[chatvars.playerid].alertBaseExit = true
				igplayers[chatvars.playerid].alertBaseID = id
				igplayers[chatvars.playerid].alertBase = 1
				faultyChat = false
				return true
			end

			if (tonumber(dist) >  tonumber(players[id].protectSize) + 20) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are too far from the base, but just walk towards the base and I will set it when you are close enough.[-]")
				igplayers[chatvars.playerid].alertBaseExit = true
				igplayers[chatvars.playerid].alertBaseID = id
				igplayers[chatvars.playerid].alertBase = 1
				faultyChat = false
				return true
			end

			players[id].exitX = chatvars.intX
			players[id].exitY = chatvars.intY
			players[id].exitZ = chatvars.intZ

			conn:execute("UPDATE players SET exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. " WHERE steam = " .. id)

			igplayers[chatvars.playerid].alertBaseExit = nil
			igplayers[chatvars.playerid].alertBaseID = nil
			igplayers[chatvars.playerid].alertBase = nil

			if (accessLevel(chatvars.playerid) < 3) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have set an exit teleport for " .. players[id].name .. "'s base.[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have set an exit teleport for your base.[-]")
			end

			-- check for nearby bases
			failProtect = false
			for k, v in pairs(players) do
				if (v.homeX ~= nil) and k ~= id then
						if (v.homeX ~= 0 and v.homeZ ~= 0) then
						dist = distancexz(players[id].homeX, players[id].homeZ, v.homeX, v.homeZ)

						if (tonumber(dist) < tonumber(players[id].protectSize)) then
							if not isFriend(k, id) then
								failProtect = true
							end
						end
					end
				end

				if (v.home2X ~= nil) then
						if (v.home2X ~= 0 and v.home2Z ~= 0) then
						dist = distancexz(players[id].homeX, players[id].homeZ, v.home2X, v.home2Z)

						if (dist < players[id].protectSize + 10) then
							if not isFriend(k, id) then
								failProtect = true
							end
						end
					end
				end
			end

			if failProtect == false then
				players[id].protect = true
				message("pm " .. id .. " [" .. server.chatColour .. "]Base protection for your base is active.[-]")

				if db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. ", protect = 1 WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end
			else
				message("pm " .. id .. " [" .. server.chatColour .. "]Your base is too close to another player base who is not on your friends list.  Protection cannot be enabled.[-]")

				if db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. ", protect = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end
			end
		else
			if (tonumber(dist) <  tonumber(players[id].protect2Size) + 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are too close to the base, but just walk away and I will set it when you are far enough away.[-]")
				igplayers[chatvars.playerid].alertBaseExit = true
				igplayers[chatvars.playerid].alertBaseID = id
				igplayers[chatvars.playerid].alertBase = 2
				faultyChat = false
				return true
			end

			if (tonumber(dist) >  tonumber(players[id].protect2Size) + 20) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are too far from the base, but just walk towards the base and I will set it when you are close enough.[-]")
				igplayers[chatvars.playerid].alertBaseExit = true
				igplayers[chatvars.playerid].alertBaseID = id
				igplayers[chatvars.playerid].alertBase = 2
				faultyChat = false
				return true
			end

			players[id].exit2X = chatvars.intX
			players[id].exit2Y = chatvars.intY
			players[id].exit2Z = chatvars.intZ

			conn:execute("UPDATE players SET exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. " WHERE steam = " .. id)

			igplayers[chatvars.playerid].alertBaseExit = nil
			igplayers[chatvars.playerid].alertBaseID = nil
			igplayers[chatvars.playerid].alertBase = nil

			if (accessLevel(chatvars.playerid) < 3) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have set an exit teleport for " .. players[id].name .. "'s 2nd base.[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have set an exit teleport for your 2nd base.[-]")
			end

			-- check for nearby bases
			failProtect = false
			for k, v in pairs(players) do
				if (v.homeX) and (v.homeX ~= 0 and v.homeZ ~= 0) then
					dist = distancexz(players[id].home2X, players[id].home2Z, v.homeX, v.homeZ)

					if (dist < players[id].protectSize2 + 10) then
						if not isFriend(k, id) then
							failProtect = true
						end
					end
				end

				if (v.home2X) and (v.home2X ~= 0 and v.home2Z ~= 0) then
					dist = distancexz(players[id].home2X, players[id].home2Z, v.home2X, v.home2Z)

					if (dist < players[id].protectSize2 + 10) then
						if not isFriend(k, id) then
							failProtect = true
						end
					end
				end
			end

			if failProtect == false then
				players[id].protect2 = true
				message("pm " .. id .. " [" .. server.chatColour .. "]Base protection for your second base is active.[-]")

				if db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. ", protect2 = 1 WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end
			else
				message("pm " .. id .. " [" .. server.chatColour .. "]Your base is too close to another player base who is not on your friends list.  Protection cannot be enabled.[-]")

				if db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. ", protect2 = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug base 4") end

	if chatvars.words[1] == "homer" and chatvars.words[2] == nil then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Doh![-]")
		faultyChat = false
		return true
	end

	if (chatvars.words[1] == "base" or chatvars.words[1] == "home" or chatvars.words[1] == "base2" or chatvars.words[1] == "home2") and chatvars.words[2] == nil then
		if (accessLevel(chatvars.playerid) > 10) and (chatvars.words[1] == "base2" or chatvars.words[1] == "home2") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors can have 2 base teleports and base protections.  Consider donating =D[-]")
			faultyChat = false
			return true
		end

if debug then dbug("debug base 4a") end

		if (players[chatvars.playerid].timeout == true) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. Wait for an admin to /return you.[-]")
			faultyChat = false
			return true
		end

if debug then dbug("debug base 4b") end

		if (players[chatvars.playerid].prisoner or not players[chatvars.playerid].canTeleport) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not allowed to use teleports.[-]")
			faultyChat = false
			return true
		end

		if (chatvars.words[1] == "base" or chatvars.words[1] == "home") and (players[chatvars.playerid].homeY == 0) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not set a base yet. Type /setbase in your base first then /base will work.[-]")

			if server.coppi then
				igplayers[chatvars.playerid].sendHome = true
				send("lpb " .. chatvars.playerid)
			end

			faultyChat = false
			return true
		end

		if (accessLevel(chatvars.playerid) < 11) then
			if (chatvars.words[1] == "base2" or chatvars.words[1] == "home2") and (players[chatvars.playerid].home2Y == 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not set a 2nd base yet. Type /setbase2 in your base first then /base2 will work.[-]")
				faultyChat = false
				return true
			end
		end

if debug then dbug("debug base 4c") end

		wait = true

		if chatvars.intY > 0 then
			if (players[chatvars.playerid].walkies == true) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not opted in to using teleports. Type /enabletp to opt-in.[-]")
				faultyChat = false
				return true
			end

if debug then dbug("debug base 4d") end

			dist1 = distancexz(players[chatvars.playerid].xPos, players[chatvars.playerid].zPos, players[chatvars.playerid].homeX, players[chatvars.playerid].homeZ)
			dist2 = distancexz(players[chatvars.playerid].xPos, players[chatvars.playerid].zPos, players[chatvars.playerid].home2X, players[chatvars.playerid].home2Z)

			if (chatvars.words[1] == "base" or chatvars.words[1] == "home") and (tonumber(dist1) < 201) then
				wait = false
			end

			if (chatvars.words[1] == "base2" or chatvars.words[1] == "home2") and (tonumber(dist2) < 201) then
				wait = false
			end

			if (accessLevel(chatvars.playerid) > 3) then
				if (players[chatvars.playerid].baseCooldown - os.time() > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have to wait " .. os.date("%M minutes %S seconds",players[chatvars.playerid].baseCooldown - os.time()) .. " before you can use /base again.[-]")
					faultyChat = false
					return true
				end
			end
		end

if debug then dbug("debug base 4h") end

		-- first record the current x y z
		if accessLevel(chatvars.playerid) < 3 then
			igplayers[chatvars.playerid].lastLocation = ""
			savePosition(chatvars.playerid)
		else
			igplayers[chatvars.playerid].lastLocation = ""
			players[chatvars.playerid].xPosOld = 0
			players[chatvars.playerid].yPosOld = 0
			players[chatvars.playerid].zPosOld = 0
		end

if debug then dbug("debug base 4i") end

		if wait then
			if players[chatvars.playerid].donor then
				players[chatvars.playerid].baseCooldown = (os.time() + math.floor(tonumber(server.baseCooldown) / 2))
			else
				players[chatvars.playerid].baseCooldown = (os.time() + server.baseCooldown)
			end
		end

if debug then dbug("debug base 4j") end

		conn:execute("UPDATE players SET xPosOld = " .. players[chatvars.playerid].xPosOld .. ", yPosOld = " .. players[chatvars.playerid].yPosOld .. ", zPosOld = " .. players[chatvars.playerid].zPosOld .. ", baseCooldown = " .. players[chatvars.playerid].baseCooldown .. " WHERE steam = " .. chatvars.playerid)

if debug then dbug("debug base 4k") end

		if (chatvars.words[1] == "base" or chatvars.words[1] == "home") then
			cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].homeX .. " " .. players[chatvars.playerid].homeY + 1 .. " " .. players[chatvars.playerid].homeZ
		else
			cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].home2X .. " " .. players[chatvars.playerid].home2Y + 1 .. " " .. players[chatvars.playerid].home2Z
		end

		if wait then
			prepareTeleport(chatvars.playerid, cmd)
			teleport(cmd)
		else
			players[chatvars.playerid].tp = 1
			players[chatvars.playerid].hackerScore = 0
			send(cmd)
		end

if debug then dbug("debug base 4l") end

		faultyChat = false
		return true
	end

if debug then dbug("debug base 5") end

	if (chatvars.words[1] == "man" and chatvars.words[2] == "delbase") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/delbase will make me forget your base which also removes base protection.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If you are moving your base you can just type /setbase at the new location.[-]")

		faultyChat = false
		return true
	end

	if (chatvars.words[1] == "delbase") then
		id = chatvars.playerid

		if (chatvars.playername == "Server") or (accessLevel(chatvars.playerid) < 3) then
			if (chatvars.words[2] ~= nil) then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "delbase") + 8)
				pname = string.trim(pname)
				id = LookupPlayer(pname)
				if id == nil then
					if (chatvars.playername ~= "Server") then 
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
					else
						irc_QueueMsg(server.ircMain, "No player found called " .. pname)
					end

					faultyChat = false
					return true
				end
			end
		end

		players[id].homeX = 0
		players[id].homeY = 0
		players[id].homeZ = 0
		players[id].exitX = 0
		players[id].exitY = 0
		players[id].exitZ = 0
		players[id].protect = false

		conn:execute("UPDATE players SET homeX = 0, homeY = 0, homeZ = 0, exitX = 0, exitY = 0, exitZ = 0, protect = 0  WHERE steam = " .. id)

		if db2Connected then
			-- update player in bots db
			connBots:execute("UPDATE players SET homeX = 0, homeY = 0, homeZ = 0, exitX = 0, exitY = 0, exitZ = 0, protect = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
		end

		if id == chatvars.playerid then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your base and base protection has been removed.[-]")
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. "'s base and base protection has been removed.[-]")
			else
				irc_QueueMsg(server.ircMain, players[id].name .. "'s base and base protection has been removed.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug base 6") end

	if chatvars.words[1] == "delbase2" and (accessLevel(chatvars.playerid) < 4) then
		id = chatvars.playerid

		if (chatvars.playername == "Server") or (accessLevel(chatvars.playerid) < 3) then
			if (chatvars.words[2] ~= nil) then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "delbase2") + 9)
				pname = string.trim(pname)
				id = LookupPlayer(pname)
				if id == nil then
					if (chatvars.playername ~= "Server") then 
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
					else
						irc_QueueMsg(server.ircMain, "No player found called " .. pname)
					end

					faultyChat = false
					return true
				end
			end
		end

		players[id].home2X = 0
		players[id].home2Y = 0
		players[id].home2Z = 0
		players[id].exit2X = 0
		players[id].exit2Y = 0
		players[id].exit2Z = 0
		players[id].protect2 = false

		conn:execute("UPDATE players SET home2X = 0, home2Y = 0, home2Z = 0, exit2X = 0, exit2Y = 0, exit2Z = 0, protect2 = 0  WHERE steam = " .. id)

		if db2Connected then
			-- update player in bots db
			connBots:execute("UPDATE players SET home2X = 0, home2Y = 0, home2Z = 0, exit2X = 0, exit2Y = 0, exit2Z = 0, protect2 = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
		end

		if id == chatvars.playerid then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your 2nd base and base protection has been removed.[-]")
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. "'s 2nd base and base protection has been removed.[-]")
			else
				irc_QueueMsg(server.ircMain, players[id].name .. "'s 2nd base and base protection has been removed.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug base 7") end

	if (chatvars.words[1] == "unprotectbase" or chatvars.words[1] == "unprotectbase2") then
		if (chatvars.playername ~= "Server") then
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "unprotectbase") + 14)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (pname == nil or pname == "") then
			faultyChat = false
			return true
		end

		if (chatvars.words[1] == "unprotectbase") then
			if (players[id]) then players[id].protect = false end
			conn:execute("UPDATE players SET protect = 0 WHERE steam = " .. id)

			if db2Connected then
				-- update player in bots db
				connBots:execute("UPDATE players SET protect = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .."'s base is no longer protected[-]")
			else
				irc_QueueMsg(server.ircMain, players[id].name .."'s base is no longer protected.")
			end
		else
			if (players[id].donor == true or (accessLevel(id) < 4)) then
				if (players[id]) then players[id].protect2 = false end
				conn:execute("UPDATE players SET protect2 = 0 WHERE steam = " .. id)

				if db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET protect2 = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .."'s 2nd base is no longer protected[-]")
				else
					irc_QueueMsg(server.ircMain, players[id].name .."'s 2nd base is no longer protected.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins are allowed 2 base protections[-]")
				else
					irc_QueueMsg(server.ircMain, "Only donors and admins are allowed 2 base protections.")
				end
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug base 8") end

	-- ###################  do not allow remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

if debug then dbug("debug base 9") end

	if ((chatvars.words[1] == "setbase" and chatvars.words[2] ~= nil) and not players[chatvars.playerid].prisoner) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type setbase without anything after it.[-]")
			faultyChat = false
			return true
		end

		pname = chatvars.words[chatvars.wordCount]
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if not validPosition(chatvars.playerid, true) then
			faultyChat = false
			return true
		end

		if (id ~= nil) then
			players[id].homeX = chatvars.intX
			players[id].homeY = chatvars.intY
			players[id].homeZ = chatvars.intZ
			players[id].exitX = chatvars.intX
			players[id].exitY = chatvars.intY
			players[id].exitZ = chatvars.intZ
			players[id].protectSize = server.baseSize
			players[id].protect = false
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. "'s base has been set at where you are standing.[-]")

			conn:execute("UPDATE players SET protectSize = " .. server.baseSize .. ", homeX = " .. chatvars.intX .. ", homeY = " .. chatvars.intY .. ", homeZ = " .. chatvars.intZ .. ", protect = 0 WHERE steam = " .. id)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. serverTime .. "','setbase','Player " .. escape(players[id].name) .. " set a base'," .. id .. ")")
			irc_QueueMsg(server.ircWatch, players[id].name .. " has setbase at " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ)

			if db2Connected then
				-- update player in bots db
				connBots:execute("UPDATE players SET homeX = " .. chatvars.intX .. ", homeY = " .. chatvars.intY .. ", homeZ = " .. chatvars.intZ .. ", exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. " protect = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug base 10") end

	if ((chatvars.words[1] == "setbase2" and chatvars.words[2] ~= nil) and not players[chatvars.playerid].prisoner) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type setbase without anything after it.[-]")
			faultyChat = false
			return true
		end

		pname = chatvars.words[chatvars.wordCount]
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if not validPosition(chatvars.playerid, true) then
			faultyChat = false
			return true
		end

		if (id ~= nil) then
			players[id].home2X = chatvars.intX
			players[id].home2Y = chatvars.intY
			players[id].home2Z = chatvars.intZ
			players[id].exit2X = chatvars.intX
			players[id].exit2Y = chatvars.intY
			players[id].exit2Z = chatvars.intZ
			players[id].protect2Size = server.baseSize
			players[id].protect2 = false
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. "'s 2nd base has been set at where you are standing.[-]")

			conn:execute("UPDATE players SET protect2Size = " .. server.baseSize .. ", home2X = " .. chatvars.intX .. ", home2Y = " .. chatvars.intY .. ", home2Z = " .. chatvars.intZ .. ", protect2 = 0 WHERE steam = " .. id)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. serverTime .. "','setbase','Player " .. escape(players[id].name) .. " set a 2nd base'," .. id .. ")")
			irc_QueueMsg(server.ircWatch, players[id].name .. " has setbase2 at " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ)

			if db2Connected then
				-- update player in bots db
				connBots:execute("UPDATE players SET home2X = " .. chatvars.intX .. ", home2Y = " .. chatvars.intY .. ", home2Z = " .. chatvars.intZ .. ", exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. " protect2 = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug base 11") end

	if (chatvars.words[1] == "test" and chatvars.words[2] == "base") and (chatvars.playerid ~= 0) then
		if players[chatvars.playerid].protect == false and players[chatvars.playerid].protect2 == false then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't have base protection established now.  Type /protect at your base or /protect2 at your 2nd base to set it up first.[-]")
			faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].protectTest = true
		igplayers[chatvars.playerid].protectTestEnd = os.time() + 30

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your base protection is active and will keep you out for 30 seconds.[-]")

		faultyChat = false
		return true
	end

	if ((chatvars.words[1] == "pause" or chatvars.words[1] == "paws") and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		pname = igplayers[chatvars.playerid].name

		if (players[chatvars.playerid].protect == false) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't have base protection established now.  An admin is required to set it up or re-establish it.[-]")
			faultyChat = false
			return true
		end

		dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, players[chatvars.playerid].homeX, players[chatvars.playerid].homeZ)
		if (dist < tonumber(players[chatvars.playerid].protectSize) + 100) then
			players[chatvars.playerid].protectPaused = true
		else
			players[chatvars.playerid].protect2Paused = true
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your base protection is disabled while you are within 100 meters of your /base teleport.[-]")

		faultyChat = false
		return true
	end

if debug then dbug("debug base 12") end

	if (chatvars.words[1] == "resume") and (chatvars.playerid ~= 0) then
		pname = igplayers[chatvars.playerid].name
		players[chatvars.playerid].protectPaused = nil
		players[chatvars.playerid].protect2Paused = nil

		if tonumber(players[chatvars.playerid].homeX) ~= 0 and tonumber(players[chatvars.playerid].homeY) ~= 0 and tonumber(players[chatvars.playerid].homeZ) ~= 0 then
			dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, players[chatvars.playerid].homeX, players[chatvars.playerid].homeZ)
			if (dist < tonumber(players[chatvars.playerid].protectSize) + 100) then
				if (players[chatvars.playerid].protect == true) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your base protection is now active.[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't have base protection. An admin can set up or re-establish it for you.[-]")
				end
			end
		end

		if tonumber(players[chatvars.playerid].home2X) ~= 0 and tonumber(players[chatvars.playerid].home2Y) ~= 0 and tonumber(players[chatvars.playerid].home2Z) ~= 0 then
			dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, players[chatvars.playerid].home2X, players[chatvars.playerid].home2Z)
			if (dist < tonumber(players[chatvars.playerid].protectSize) + 100) then

			if (players[chatvars.playerid].protect2 == true) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your second base's protection is now active.[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't have base protection on your second base. An admin can set up or re-establish it for you.[-]")
				end
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug base end") end

end
