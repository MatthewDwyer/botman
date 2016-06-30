--[[ 
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function playerInfo()
	-- EDIT THIS FUNCTION WITH CARE.  This function is central to player management.  Some lines need to be run before others.
	-- Lua will stop execution wherever it strikes a fault (usually trying to use a non-existing variable)
	-- enable debugging to see roughly where the bot gets to.  It should reach 'end playerinfo'.
	-- Good luck :)

	faultyPlayerinfo = true
	faultyPlayerinfoID = 0
	faultyPlayerinfoLine = line

	local debugSteam, debug, id, name, posX, posY, posZ, lastX, lastY, lastZ, lastDist, mapCenterDistance
	local deaths, zombies, kills, score, level, steam, steamtest, admin, lastGimme, lastLogin
	local xPosOld, yPosOld, zPosOld, rawPosition, outsideMap, outsideMapDonor, fields, values
	local isAdmin = "No"
	local isPrisoner = "No"
	local timestamp = os.time()
	local region = ""
	local resetZone = false
	local ping, dist, IP, hotspot, currentLocation
	local skipTPtest = false
	local badData = false

	-- Set debugSteam to the steam id or player name that you want to monitor.  The player must be on the server.
	debugSteam = 0
	--debugSteam = "76561198078282214"

	if (debugSteam ~= 0) then 
		dbug("debug playerinfo") 
	end	

	-- sanity check debugSteam
	if tonumber(debugSteam) == nil then
		debugSteam = LookupPlayer(debugSteam)
		if debugSteam == nil then debugSteam = 0 end
	end

	name_table = string.split(line, ", ")

	if string.find(name_table[3], "pos") then 
		name = string.trim(name_table[2])
	else
		temp = name_table[1] .. ", name" .. string.sub(line, string.find(line, ", pos="), string.len(line))
		name_table = string.split(temp, ", ")
		name = string.trim(string.sub(line, string.find(line, ",") + 2, string.find(line, ", pos=") - 1))
	end

	-- stop processing this player if we don't have 18 parts to the line after splitting on comma
	-- it is probably a read error
	if (table.maxn(name_table) < 18) then
		faultyPlayerinfoID = 0
		return
	end

	temp = string.split(name_table[1], "=")
	id = temp[2]

	num = tonumber(string.sub(name_table[3], 6))
	if (num == nil) then badData = true end
	posX = num

	num = tonumber(name_table[4])
	if (num == nil) then badData = true end
	posY = num

	temp = string.split(name_table[5], ")")
	num = tonumber(temp[1])
	if (num == nil) then badData = true end
	posZ = num

	temp = string.split(name_table[11], "=")
	num = tonumber(temp[2])
	if (num == nil) then badData = true end
	deaths = num

	temp = string.split(name_table[12], "=")
	num = tonumber(temp[2])
	if (num == nil) then badData = true end
	zombies = num

	temp = string.split(name_table[13], "=")
	num = tonumber(temp[2])
	if (num == nil) then badData = true end
	kills = num

	temp = string.split(name_table[14], "=")
	num = tonumber(temp[2])
	if (num == nil) then badData = true end
	score = num

	temp = string.split(name_table[15], "=")
	num = tonumber(temp[2])
	if (num == nil) then badData = true end
	level = num

	temp = string.split(name_table[16], "=")
	if (num == nil) then badData = true end
	steam = temp[2]

	faultyPlayerinfoID = steam

	temp = string.split(name_table[17], "=")
	IP = temp[2]

	temp = string.split(name_table[18], "=")
	ping = temp[2]

	if badData then
		cecho(server.windowDebug, "Bad lp line: " .. line .. "\n")
		return
	end

	rawPosition = posX .. posY .. posZ

	intX = math.floor(posX)
	intY = math.ceil(posY)
	intZ = math.floor(posZ)

	region = getRegion(intX, intZ)
	if (resetRegions[region]) then 
		resetZone = true 
	else
		resetZone = false
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 1") 
	end	

	-- check for crazy server crash
	if (string.find(line, "type=EntityZombie")) then
		if nextRebootTest == nil or (nextRebootTest ~= nil and os.time() > nextRebootTest) then
			if (server.scheduledRestart == true) and scheduledRestartForced == false then
				gmsg("/cancel reboot")
			end

			if scheduledRestartForced == false then
				message("say [" .. server.chatColour .. "]Zombies have been detected in the player data and an urgent reboot has been initiated to fix it.[-]")
				message("say [" .. server.chatColour .. "]You have 2 minutes to stop what you are doing and clear your crafting, forges and campfires.[-]")
				gmsg("/reboot server 2 minutes forced")
			end
		end

		return
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 2") 
	end	

	--display ("temp[2] = -" .. temp[2] .. "-\n")

	-- check for invalid or missing steamid.  kick if not passed
	steamtest = 0
	steamtest = tonumber(steam)
	if (steamtest == nil) and (steam ~= "") then --  or (string.len(steam) < 17)
		cecho (server.windowAlerts, "Kicking player " .. name .. " for invalid Steam ID " .. steam .. "\n")
		cecho (server.windowAlerts,  line .. "\n")
		message("say [" .. server.chatColour .. "]Kicking player " .. name .. " for bad steam ID: " .. steam .. "[-]")
		send ("kick " .. id)

		faultyPlayerinfo = false
		return
	end

	-- add to in-game players table
	if (igplayers[steam] == nil) then
		igplayers[steam] = {}
		igplayers[steam].id = id
		igplayers[steam].name = name
		igplayers[steam].steam = steam
		igplayers[steam].steamOwner = steam

		fixMissingIGPlayer(steam)
	end

	-- add to players table
	if (players[steam] == nil) then
		players[steam] = {}
		players[steam].id = id
		players[steam].name = name
		players[steam].steam = steam

		if tonumber(score) == 0 and tonumber(zombies) == 0 and tonumber(deaths) == 0 then
			players[steam].newPlayer = true
		else
			players[steam].newPlayer = false
		end

		players[steam].watchPlayer = true
		players[steam].IP = IP
		players[steam].exiled = 0

		irc_QueueMsg(server.ircMain, "###  New player joined " .. player .. " steam: " .. steam.. " id: " .. id .. " ###")
		irc_QueueMsg(server.ircAlerts, "New player joined")
		irc_QueueMsg(server.ircAlerts, line)

		conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(posX) .. "," .. math.floor(posY) .. "," .. math.floor(posZ) .. ",'" .. serverTime .. "','new player','New player joined " .. name .. " steam: " .. steam.. " id: " .. id .. "'," .. steam .. ")")
		conn:execute("INSERT INTO players (steam, name, id, IP, newPlayer, watchPlayer) VALUES (" .. steam .. ",'" .. escape(name) .. "'," .. id .. "," .. IP .. ",1,1)")

		fixMissingPlayer(steam)
		CheckBlacklist(steam, IP)
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 4") 
	end	

	if (players[steam].prisoner == true) then
		isPrisoner = "Yes"
	end

	if accessLevel(steam) < 3 then
		isAdmin = "Yes"
	end

	if IP ~= "" and players[steam].IP == "" then
		players[steam].IP = IP
		CheckBlacklist(steam, IP)
	end

	-- ping kick
	if players[steam].whitelisted == false and players[steam].newPlayer then
		if tonumber(ping) < tonumber(server.pingKick) and tonumber(server.pingKick) > 0 then
			igplayers[steam].highPingCount = tonumber(igplayers[steam].highPingCount) - 1
			if tonumber(igplayers[steam].highPingCount) < 0 then igplayers[steam].highPingCount = 0 end
		end 

		if tonumber(ping) > tonumber(server.pingKick) and tonumber(server.pingKick) > 0 then
			igplayers[steam].highPingCount = tonumber(igplayers[steam].highPingCount) + 1

			if tonumber(igplayers[steam].highPingCount) > 5 then
				irc_QueueMsg(server.ircMain, "Kicked " .. name .. " steam: " .. steam.. " for high ping " .. ping)
				kick(steam, "High ping. Contact an admin and ask to be whitelisted.")
				return
			end
		end
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 9") 
	end	

	if tonumber(intY) > 0 and tonumber(intY) < 500 then
		igplayers[steam].lastTP = nil
		forgetLastTP(steam)
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 10") 
	end	

	if (players[steam].location ~= "") then
		-- spawn the player at location
		if (locations[players[steam].location]) then
			cursor,errorString = conn:execute("select * from locationSpawns where location='" .. players[steam].location .. "'")
			if cursor:numrows() > 0 then
				randomPVPTP(steam, players[steam].location, true)
			else
				cmd = "tele " .. steam .. " " .. locations[players[steam].location].x .. " " .. locations[players[steam].location].y .. " " .. locations[players[steam].location].z
				igplayers[steam].lastTP = cmd
				teleport(cmd, true)
			end

			players[steam].location = ""
			conn:execute("UPDATE players SET location = '' WHERE steam = " .. steam)
		end

		if (players[steam].location == "return player") then		

			if players[steam].xPosTimeout ~= 0 and players[steam].zPosTimeout ~= 0 then
				cmd = "tele " .. steam .. " " .. players[steam].xPosTimeout .. " " .. players[steam].yPosTimeout .. " " .. players[steam].zPosTimeout
				players[steam].xPosTimeout = 0
				players[steam].yPosTimeout = 0
				players[steam].zPosTimeout = 0
			else
				cmd = "tele " .. steam .. " " .. players[steam].xPosOld .. " " .. players[steam].yPosOld .. " " .. players[steam].zPosOld
			end

			igplayers[steam].lastTP = cmd
			teleport(cmd, true)
			players[steam].location = ""
			conn:execute("UPDATE players SET location = '' WHERE steam = " .. steam)
		end
	end

	-- test for hackers teleporting
	if not server.playersCanFly and not (players[steam].timeout or players[steam].botTimeout) and not players[steam].ignorePlayer then
		if tonumber(intY) > -5000 and tonumber(intX) ~= 0 and tonumber(intZ) ~= 0 and tonumber(igplayers[steam].xPos) ~= 0 and tonumber(igplayers[steam].zPos) ~= 0 and tonumber(os.time() - igplayers[steam].lastLP) < 4 then
			dist = 0

			if igplayers[steam].deadX == nil then
				dist = distancexz(posX, posZ, igplayers[steam].xPos, igplayers[steam].zPos)
			end

			if (dist >= 300) then
				if tonumber(players[steam].tp) < 1 then
					if players[steam].newPlayer == true then
						new = " [FF8C40]NEW player "
					else
						new = " [FF8C40]Player "
					end

					if accessLevel(steam) > 2 then
						irc_QueueMsg(server.ircMain, serverTime .. " Player " .. id .. " name: " .. name .. " detected teleporting to " .. intX .. " " .. intY .. " " .. intZ .. " distance " .. dist)
						irc_QueueMsg(server.ircAlerts, serverTime .. " Player " .. id .. " name: " .. name .. " detected teleporting to " .. intX .. " " .. intY .. " " .. intZ .. " distance " .. dist)
						irc_QueueMsg(server.ircTracker, serverTime .. " Player " .. id .. " name: " .. name .. " detected teleporting from " .. math.floor(igplayers[steam].xPos) .. " " .. math.ceil(igplayers[steam].yPos) .. " " .. math.floor(igplayers[steam].zPos) .. " to " .. intX .. " " .. intY .. " " .. intZ .. " distance " .. dist)

						players[steam].hackerScore = tonumber(players[steam].hackerScore) + 1
						players[steam].watchPlayer = true
						conn:execute("UPDATE players SET watchPlayer = 1 WHERE steam = " .. steam)
						
						if tonumber(players[steam].exiled) == 1 then
							players[steam].hackerScore = tonumber(players[steam].hackerScore) + 1
						end
						
						if players[steam].hackerScore > 0 and players[steam].newPlayer and tonumber(players[steam].ping) > 180 then
							if locations["exile"] and not players[steam].prisoner then
								players[steam].exiled = 1
							else
								players[steam].hackerScore = tonumber(players[steam].hackerScore) + 1
							end
						end

						if tonumber(players[steam].hackerScore) > 1 then
							players[steam].hackerScore = 0
							players[steam].tp = 0
							message("say [" .. server.chatColour .. "]Temp-banning " .. players[steam].name .. " 1 day for unexplained teleporting. An admin will investigate the circumstances.[-]")
							banPlayer(steam, "1 day", "We detected unusual teleporting from you and are investigating the circumstances.", "")
						end

						for k, v in pairs(igplayers) do
							if (accessLevel(k) < 3) then
								message("pm " .. k .. new .. id .. " name: " .. name .. " detected teleporting (possible hacker). The detection is real but I could be wrong.  Investigate the player.[-]")
							end
						end
					end
				end

				players[steam].tp = 0

				-- just in case this is an admin we don't know about, run admin list
				send("admin list")
			end
		end
	end

	igplayers[steam].lastLP = os.time()

	if (steam == debugSteam) then 
		dbug("debug playerinfo 11") 
	end	

	players[steam].name = name
	players[steam].steamOwner = igplayers[steam].steamOwner
	igplayers[steam].name = name
	igplayers[steam].steam = steam
	
	igplayers[steam].xPosLast = igplayers[steam].xPos
	igplayers[steam].yPosLast = igplayers[steam].yPos
	igplayers[steam].zPosLast = igplayers[steam].zPos	
	
	igplayers[steam].xPos = posX
	igplayers[steam].yPos = posY
	igplayers[steam].zPos = posZ
	igplayers[steam].playerKills = kills
	igplayers[steam].deaths = deaths
	igplayers[steam].zombies = zombies
	igplayers[steam].score = score
	igplayers[steam].level = level
	players[steam].level = level
	igplayers[steam].killTimer = 0 -- to help us detect a player that has disconnected unnoticed
	igplayers[steam].raiding = false

	if tonumber(ping) > 0 then
		igplayers[steam].ping = ping
		players[steam].ping = ping
	end

	if igplayers[steam].rawPosition == nil then
		igplayers[steam].rawPosition = rawPosition
	end

	if (igplayers[steam].xPosLast == nil) then
		igplayers[steam].xPosLast = posX
		igplayers[steam].yPosLast = posY
		igplayers[steam].zPosLast = posZ
		igplayers[steam].xPosLastOK = intX
		igplayers[steam].yPosLastOK = intY
		igplayers[steam].zPosLastOK = intZ
	end

	atHome(steam)

	currentLocation = inLocation(intX, intZ)

	if currentLocation ~= false then
		resetZone = locations[currentLocation].resetZone

		if locations[currentLocation].killZombies then 
			scanZombies = true
		end
	end

	if players[steam].showLocationMessages then
		if igplayers[steam].alertLocation ~= currentLocation and currentLocation ~= false then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Welcome to " .. currentLocation .. "[-]")
		end
	end

	if currentLocation == false then --  or igplayers[steam].alertLocation ~= currentLocation
		if players[steam].showLocationMessages then
			if igplayers[steam].alertLocation ~= "" then
				message("pm " .. steam .. " [" .. server.chatColour .. "]You have left " .. igplayers[steam].alertLocation .. "[-]")
			end
		end

		igplayers[steam].alertLocation = ""
		players[steam].inLocation = ""
	else
		igplayers[steam].alertLocation = currentLocation
		players[steam].inLocation = currentLocation
	end

	if igplayers[steam].checkNewPlayer == true then
		igplayers[steam].checkNewPlayer = false

		if tonumber(level) > 1 then
			players[steam].newPlayer = false
			conn:execute("UPDATE players SET newPlayer = 0 WHERE steam = " .. steam)
			irc_QueueMsg(server.ircMain, "Player " .. player .. "'s new player status has been removed because their level is " .. level)
		end
	end

	-- convert zombie kills to cash
	if (tonumber(igplayers[steam].zombies) > tonumber(players[steam].zombies)) and (math.abs(igplayers[steam].zombies - players[steam].zombies) < 20) then
		if server.allowBank then
			players[steam].cash = tonumber(players[steam].cash) + math.abs(igplayers[steam].zombies - players[steam].zombies) * server.zombieKillReward

			if (players[steam].watchCash == true) then
				message("pm " .. steam .. " [" .. server.chatColour .. "]+" .. math.abs(igplayers[steam].zombies - players[steam].zombies) * server.zombieKillReward .. " Zennies. $" .. players[steam].cash .. " in the bank[-]")
			end
		end

		if igplayers[steam].doge then
			r = rand(70)
			if r == 1 then message("pm " .. steam .. " [" .. server.chatColour .. "]MUCH KILL[-]")	end
			if r == 2 then message("pm " .. steam .. " [" .. server.chatColour .. "]GREAT PAIN[-]")	end
			if r == 3 then message("pm " .. steam .. " [" .. server.chatColour .. "]WOW[-]")	end
			if r == 4 then message("pm " .. steam .. " [" .. server.chatColour .. "]VERY DEATH[-]")	end
			if r == 5 then message("pm " .. steam .. " [" .. server.chatColour .. "]AMAZING[-]")	end
			if r == 6 then message("pm " .. steam .. " [" .. server.chatColour .. "]CALL 911[-]")	end
			if r == 7 then message("pm " .. steam .. " [" .. server.chatColour .. "]BIG HIT[-]")	end
			if r == 8 then message("pm " .. steam .. " [" .. server.chatColour .. "]EXTREME GORE[-]")	end
			if r == 9 then message("pm " .. steam .. " [" .. server.chatColour .. "]EXTREME POWER SHOT[-]")	end
			if r == 10 then message("pm " .. steam .. " [" .. server.chatColour .. "]EPIC BLOOD LOSS[-]")	end
			if r == 11 then message("pm " .. steam .. " [" .. server.chatColour .. "]OMG[-]")	end
			if r == 12 then message("pm " .. steam .. " [" .. server.chatColour .. "]OVERKILL[-]")	end
			if r == 13 then message("pm " .. steam .. " [" .. server.chatColour .. "]EXTREME OVERKILL[-]")	end
			if r == 14 then message("pm " .. steam .. " [" .. server.chatColour .. "]VERY OP[-]")	end
			if r == 15 then message("pm " .. steam .. " [" .. server.chatColour .. "]DISMEMBERMENT[-]")	end
			if r == 16 then message("pm " .. steam .. " [" .. server.chatColour .. "]HEAD SHOT[-]")	end
			if r == 17 then message("pm " .. steam .. " [" .. server.chatColour .. "]PSYCHO[-]")	end
			if r == 18 then message("pm " .. steam .. " [" .. server.chatColour .. "]HAX[-]")	end
			if r == 19 then message("pm " .. steam .. " [" .. server.chatColour .. "]GAME OVER[-]")	end
			if r == 20 then message("pm " .. steam .. " [" .. server.chatColour .. "]OWNED[-]")	end
			if r == 21 then message("pm " .. steam .. " [" .. server.chatColour .. "]DUDE[-]")	end
			if r == 22 then message("pm " .. steam .. " [" .. server.chatColour .. "]SICK[-]")	end
			if r == 23 then message("pm " .. steam .. " [" .. server.chatColour .. "]INCREDIBLE[-]")	end
			if r == 24 then message("pm " .. steam .. " [" .. server.chatColour .. "]BODY PARTS[-]")	end
			if r == 25 then message("pm " .. steam .. " [" .. server.chatColour .. "]WTF[-]")	end
			if r == 26 then message("pm " .. steam .. " [" .. server.chatColour .. "]EPIC[-]")	end
			if r == 27 then message("pm " .. steam .. " [" .. server.chatColour .. "]AIMBOT[-]")	end
			if r == 28 then message("pm " .. steam .. " [" .. server.chatColour .. "]EXPLOSIVE[-]")	end
			if r == 29 then message("pm " .. steam .. " [" .. server.chatColour .. "]IMPOSSIBLE[-]")	end
			if r == 30 then message("pm " .. steam .. " [" .. server.chatColour .. "]MASSIVE HURT[-]")	end
			if r == 31 then message("pm " .. steam .. " [" .. server.chatColour .. "]C-C-C-COMBO BREAKER[-]")	end
			if r == 32 then message("pm " .. steam .. " [" .. server.chatColour .. "]ULTRA KILL[-]")	end
			if r == 33 then message("pm " .. steam .. " [" .. server.chatColour .. "]SUPPRESSED[-]")	end
			if r == 34 then message("pm " .. steam .. " [" .. server.chatColour .. "]IMPRESSIVE[-]")	end
			if r == 35 then message("pm " .. steam .. " [" .. server.chatColour .. "]ONE UP[-]")	end
			if r == 36 then message("pm " .. steam .. " [" .. server.chatColour .. "]MEGA KILL[-]")	end
			if r == 37 then message("pm " .. steam .. " [" .. server.chatColour .. "]SUPER KILL[-]")	end
			if r == 38 then message("pm " .. steam .. " [" .. server.chatColour .. "]SKILL SHOT[-]")	end
			if r == 39 then message("pm " .. steam .. " [" .. server.chatColour .. "]VERY AMAZING[-]")	end
			if r == 40 then message("pm " .. steam .. " [" .. server.chatColour .. "]EPIC OWNAGE[-]")	end
			if r == 41 then message("pm " .. steam .. " [" .. server.chatColour .. "]OMG WTF HAX[-]")	end
			if r == 42 then message("pm " .. steam .. " [" .. server.chatColour .. "]HOW[-]")	end
			if r == 43 then message("pm " .. steam .. " [" .. server.chatColour .. "]IMPOSSIBLE[-]")	end
			if r == 44 then message("pm " .. steam .. " [" .. server.chatColour .. "]CRAZY KILL[-]")	end
			if r == 45 then message("pm " .. steam .. " [" .. server.chatColour .. "]LEGENDARY KILL[-]")	end
			if r == 46 then message("pm " .. steam .. " [" .. server.chatColour .. "]GUTSY[-]")	end
			if r == 47 then message("pm " .. steam .. " [" .. server.chatColour .. "]SMOOTH[-]")	end
			if r == 48 then message("pm " .. steam .. " [" .. server.chatColour .. "]PRO[-]")	end
			if r == 49 then message("pm " .. steam .. " [" .. server.chatColour .. "]NUKED[-]")	end
			if r == 50 then message("pm " .. steam .. " [" .. server.chatColour .. "]STOLEN KILL[-]")	end
			if r == 51 then message("pm " .. steam .. " [" .. server.chatColour .. "]LEEEEEEEEEEEEEROY JENKINS!!!!!![-]")	end
			if r == 52 then message("pm " .. steam .. " [" .. server.chatColour .. "]THANKS OBAMA[-]")	end
			if r == 53 then message("pm " .. steam .. " [" .. server.chatColour .. "]WE GOT A BADDASS OVER HERE[-]")	end
			if r == 54 then message("pm " .. steam .. " [" .. server.chatColour .. "]WTF BBQ[-]")	end
			if r == 55 then message("pm " .. steam .. " [" .. server.chatColour .. "]JUST A FLESH WOUND[-]")	end
			if r == 56 then message("pm " .. steam .. " [" .. server.chatColour .. "]WALK IT OFF[-]")	end
			if r == 57 then message("pm " .. steam .. " [" .. server.chatColour .. "]THAT'S GOTTA HURT[-]")	end
			if r == 58 then message("pm " .. steam .. " [" .. server.chatColour .. "]OOPS[-]")	end
			if r == 59 then message("pm " .. steam .. " [" .. server.chatColour .. "]DAMN[-]")	end
			if r == 60 then message("pm " .. steam .. " [" .. server.chatColour .. "]THUD[-]")	end
			if r == 61 then message("pm " .. steam .. " [" .. server.chatColour .. "]FLUKE[-]")	end
			if r == 62 then message("pm " .. steam .. " [" .. server.chatColour .. "]SORRY![-]")	end
			if r == 63 then message("pm " .. steam .. " [" .. server.chatColour .. "]CHEAP[-]")	end
			if r == 64 then message("pm " .. steam .. " [" .. server.chatColour .. "]BEGINNERS LUCK[-]")	end
			if r == 65 then message("pm " .. steam .. " [" .. server.chatColour .. "]I'LL BE BACK[-]")	end
			if r == 66 then message("pm " .. steam .. " [" .. server.chatColour .. "]HASTA LA VISTA BABY[-]")	end
			if r == 67 then message("pm " .. steam .. " [" .. server.chatColour .. "]NOT THE KNEE![-]")	end
			if r == 68 then message("pm " .. steam .. " [" .. server.chatColour .. "]KILLED DEAD[-]")	end
			if r == 69 then message("pm " .. steam .. " [" .. server.chatColour .. "]LUCKY SHOT[-]")	end
			if r == 70 then message("pm " .. steam .. " [" .. server.chatColour .. "]HE'S DEAD JIM[-]")	end
		end

		if server.allowBank then
			-- update the lottery prize pool
			server.lottery = server.lottery + (math.abs(igplayers[steam].zombies - players[steam].zombies) * server.lotteryMultiplier)
		end
	end

	-- update player record of zombies
	players[steam].zombies = igplayers[steam].zombies

	if tonumber(players[steam].playerKills) < tonumber(kills) then
		players[steam].playerKills = kills
	end

	if tonumber(players[steam].deaths) < tonumber(deaths) then
		players[steam].deaths = deaths
	end

	if tonumber(players[steam].score) < tonumber(score) then
		players[steam].score = score
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 12") 
	end	

	--players[steam].level = level
	players[steam].xPos = posX
	players[steam].yPos = posY
	players[steam].zPos = posZ

	mapCenterDistance = distancexz(intX,intZ,0,0)
	outsideMap = squareDistance(intX, intZ, server.mapSize)
	outsideMapDonor = squareDistance(intX, intZ, server.mapSize + 5000)

	if (players[steam].alertReset == nil) then
		players[steam].alertReset = true
	end

	if (igplayers[steam].greet == true) and (igplayers[steam].greetdelay == 0) then
		igplayers[steam].greet = false

		if server.welcome ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]" .. server.welcome .. "[-]")
		else
			message("pm " .. steam .. " [" .. server.chatColour .. "]Welcome to " .. server.ServerName .. "!  Type /info, /rules or /help for answers to common questions.[-]")
		end

		if (tonumber(igplayers[steam].zombies) ~= 0) then
			if (players[steam].donor == true) then
				welcome = "pm " .. steam .. " [" .. server.chatColour .. "]Welcome back " .. name .. "! Thanks for supporting us. =D[-]"
			else
				welcome = "pm " .. steam .. " [" .. server.chatColour .. "]Welcome back " .. name .. "![-]"
			end

			if (string.find(serverTime, "02-14", 5, 10)) then welcome = "pm " .. steam .. " [" .. server.chatColour .. "]Happy Valentines Day " .. name .. "![-]" end

			message(welcome)
		else
			message("pm " .. steam .. " [" .. server.chatColour .. "]Welcome " .. name .. "![-]")
		end

		if (players[steam].timeout == true) then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You are in timeout, not glitched or lagged.  You will stay here until released by an admin.[-]")
		end

		if (server.scheduledRestart == true or rebootTimerID ~= nil) then
			message("pm " .. steam .. " [" .. server.chatColour .. "]<!> SERVER WILL REBOOT SHORTLY <!>[-]")
		end

		if server.MOTD ~= "" then
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]" .. server.MOTD .. "[-]") .. "')")
		end

		if tonumber(players[steam].removedClaims) > 0 then
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]I am holding " .. players[steam].removedClaims .. " land claim blocks for you. Type /give claims to receive them.[-]") .. "')")
		end

		cursor,errorString = conn:execute("SELECT * FROM mail WHERE recipient = " .. steam .. " and status = 0")
		if cursor:numrows() > 0 then
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]You have unread mail.  Type /read mail to read it now or /help mail for more options.[-]") .. "')")
		end

		if players[steam].newPlayer == true and server.rules ~= "" then
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]" .. server.rules .."[-]") .. "')")
		end

		if server.warnBotReset == true and accessLevel(steam) == 0 then
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]ALERT!  It appears that the server has been reset.[-]") .. "')")
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]To reset me type /reset bot.[-]") .. "')")
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]To dismiss this alert type /no reset.[-]") .. "')")
		end

		if (not players[steam].santa) and specialDay == "christmas" then
			conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]HO HO HO! Merry Christmas!  Type /santa to open your Christmas stocking![-]") .. "')")
		end
	end


	if igplayers[steam].alertLocation == "" and currentLocation ~= false then
		conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. steam .. ",'" .. escape("[" .. server.chatColour .. "]Welcome to " .. currentLocation .. "[-]") .. "')")
		igplayers[steam].alertLocation = currentLocation
	end


	if (igplayers[steam].greetdelay > 0) then
		igplayers[steam].greetdelay = igplayers[steam].greetdelay - 1
	end


	if (igplayers[steam].teleCooldown > 0) then
		igplayers[steam].teleCooldown = igplayers[steam].teleCooldown - 1
	end

	igplayers[steam].sessionPlaytime = os.time() - igplayers[steam].sessionStart

	if (steam == debugSteam) then 
		dbug("debug playerinfo 13") 
	end	

	if (players[steam].newPlayer == true and (igplayers[steam].sessionPlaytime + players[steam].timeOnServer > (server.newPlayerTimer * 60))) then
		players[steam].newPlayer = false
		players[steam].watchPlayer = false
		message("pm " .. steam .. " [" .. server.chatColour .. "]Your new player status has been lifted.  You may now use the base command to teleport home.[-]")
		conn:execute("UPDATE players SET newPlayer = 0, watchPlayer = 0 WHERE steam = " .. steam)
	end

	if tonumber(players[steam].donorExpiry) < os.time() and players[steam].donor == true then
--		players[steam].donor = false
--		players[steam].donorLevel = 0
--		conn:execute("UPDATE players SET donor = 0, donorLevel = 0 WHERE steam = " .. steam)

--		message("pm " .. steam .. " [" .. server.chatColour .. "]Your donor status has expired :(  Contact an admin if you need help accessing your second base. Your 2nd base's protection will be disabled one week from when your donor status expired.[-]")

		if os.time() - tonumber(players[steam].donorExpiry) > (60 * 60 * 24 * 7) then
--			players[steam].protect2 = fase
--			conn:execute("UPDATE players SET protect2 = 0 WHERE steam = " .. steam)
--			message("pm " .. steam .. " [" .. server.chatColour .. "]ALERT! Your second base is no longer bot protected![-]")
		end
	end

	if (showPlayers == true) then
		if players[steam].prisoner then 
			isPrisoner = "yes"
		else
			isPrisoner = "no"
		end

		if accessLevel(steam) < 3 then 
			isAdmin = "yes"
		else
			isAdmin = "no"
		end

		cecho(server.windowLists, "id:" .. id .. " name:" .. igplayers[steam].name .. " steam:" .. steam .. " admin:" .. isAdmin .. " xyz:" .. math.floor(igplayers[steam].xPos) .. " " .. math.ceil(igplayers[steam].yPos) .. " " .. math.floor(igplayers[steam].zPos) .. " prisoner:" .. isPrisoner .. " score:" .. igplayers[steam].score .. "\n")
		
		cecho(server.windowPlayers, "id: " .. id .. "\n")
		cecho(server.windowPlayers, "playerName: " .. igplayers[steam].name .. "\n")
		cecho(server.windowPlayers, "current X Y Z: " .. math.floor(igplayers[steam].xPos) .. " " .. math.ceil(igplayers[steam].yPos) .. " " .. math.floor(igplayers[steam].zPos) .. "\n")	
		cecho(server.windowPlayers, "steamID: " .. steam .. "\n")
		cecho(server.windowPlayers, "playerKills: " .. igplayers[steam].playerKills .. "\n")
		cecho(server.windowPlayers, "zombies: " .. igplayers[steam].zombies .. "\n")
		cecho(server.windowPlayers, "score: " .. igplayers[steam].score .. "\n")
		cecho(server.windowPlayers, "admin: " .. isAdmin .. "\n")
		cecho(server.windowPlayers, "prisoner: " .. isPrisoner .. "\n")	
		cecho(server.windowPlayers, "home XYZ: " .. players[steam].homeX .. " " .. players[steam].homeY .. " " .. players[steam].homeZ .. "\n")	
		cecho(server.windowPlayers, "home2 XYZ: " .. players[steam].homeX .. " " .. players[steam].home2Y .. " " .. players[steam].home2Z .. "\n")	
		cecho(server.windowPlayers, "session time: " .. os.date("!%X",igplayers[steam].sessionPlaytime) .. " seconds\n")	
		cecho(server.windowPlayers, " \n")
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 14") 
	end	

	-- if we are following a player and they move more than 50 meters away, teleport us close to them.
	if igplayers[steam].following ~= nil then
		if igplayers[igplayers[steam].following] and players[igplayers[steam].following].timeout == false and players[igplayers[steam].following].botTimeout == false then
			followDistance = 50
			if igplayers[steam].followDistance ~= nil then followDistance = tonumber(igplayers[steam].followDistance) end

			dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, igplayers[igplayers[steam].following].xPos, igplayers[igplayers[steam].following].zPos)	
			if dist > followDistance and igplayers[igplayers[steam].following].yPos > 0 then
				-- teleport close to the player
				players[steam].tp = 1
				players[steam].hackerScore = 0
				send("tele " .. steam .. " " .. math.floor(igplayers[igplayers[steam].following].xPos) .. " " .. math.ceil(igplayers[igplayers[steam].following].yPos - 30) .. " " .. math.floor(igplayers[igplayers[steam].following].zPos))
			end
		end
	end


	if (igplayers[steam].alertLocationExit ~= nil) then
		dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, locations[igplayers[steam].alertLocationExit].x, locations[igplayers[steam].alertLocationExit].z)
		size = tonumber(locations[igplayers[steam].alertLocationExit].size)

		if (dist > tonumber(locations[igplayers[steam].alertLocationExit].size) + 100) then
			igplayers[steam].alertLocationExit = nil

			message("pm " .. steam .. " [" .. server.chatColour .. "]Your have moved too far away from the location. If you still wish to do /protect location, please start again.[-]")
			faultyPlayerinfo = false
			return
		end

		if (dist > tonumber(locations[igplayers[steam].alertLocationExit].size) + 10) and (dist <  tonumber(locations[igplayers[steam].alertLocationExit].size) + 30) then
			locations[igplayers[steam].alertLocationExit].exitX = intX
			locations[igplayers[steam].alertLocationExit].exitY = intY
			locations[igplayers[steam].alertLocationExit].exitZ = intZ
			locations[igplayers[steam].alertLocationExit].protected = true

			conn:execute("UPDATE locations SET exitX = " .. intX .. ", exitY = " .. intY .. ", exitZ = " .. intZ .. ", protected = 1 WHERE name = '" .. igplayers[steam].alertLocationExit .. "'")
			message("pm " .. steam .. " [" .. server.chatColour .. "]You have enabled protection for " .. igplayers[steam].alertLocationExit .. ".[-]")

			igplayers[steam].alertLocationExit = nil

			faultyPlayerinfo = false
			return
		end
	end


	if (igplayers[steam].alertVillageExit ~= nil) then
		dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, locations[igplayers[steam].alertVillageExit].x, locations[igplayers[steam].alertVillageExit].z)
		size = tonumber(locations[igplayers[steam].alertVillageExit].size)

		if (dist > tonumber(locations[igplayers[steam].alertVillageExit].size) + 100) then
			igplayers[steam].alertVillageExit = nil

			message("pm " .. steam .. " [" .. server.chatColour .. "]Your have moved too far away from " .. igplayers[steam].alertVillageExit .. ". Return to " .. igplayers[steam].alertVillageExit .. " and type /protect village " .. igplayers[steam].alertVillageExit .. " again.[-]")
			faultyPlayerinfo = false
			return
		end

		if (dist >  tonumber(locations[igplayers[steam].alertVillageExit].size) + 20) and (dist <  tonumber(locations[igplayers[steam].alertVillageExit].size) + 100) then
			locations[igplayers[steam].alertVillageExit].exitX = intX
			locations[igplayers[steam].alertVillageExit].exitY = intY
			locations[igplayers[steam].alertVillageExit].exitZ = intZ
			locations[igplayers[steam].alertVillageExit].protect = true

			message("pm " .. steam .. " [" .. server.chatColour .. "]You have enabled protection for " .. igplayers[steam].alertVillageExit .. "[-]")

			igplayers[steam].alertVillageExit = nil

			faultyPlayerinfo = false
			return
		end
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 15") 
	end	

	if (igplayers[steam].alertBaseExit == true) then
		if igplayers[steam].alertBase == 1 then
			dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, players[igplayers[steam].alertBaseID].homeX, players[igplayers[steam].alertBaseID].homeZ)
			size = tonumber(players[igplayers[steam].alertBaseID].protectSize)
		else
			dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, players[igplayers[steam].alertBaseID].home2X, players[igplayers[steam].alertBaseID].home2Z)
			size = tonumber(players[igplayers[steam].alertBaseID].protect2Size)
		end

		if (dist > 200) then
			igplayers[steam].alertBaseExit = nil
			igplayers[steam].alertBaseID = nil
			igplayers[steam].alertBase = nil

			message("pm " .. steam .. " [" .. server.chatColour .. "]Your have moved too far away from the base. If you still wish to do setexitbase, please start again.[-]")
			faultyPlayerinfo = false
			return
		end

		if igplayers[steam].alertBase == 1 then
			if (dist >  tonumber(players[igplayers[steam].alertBaseID].protectSize) + 15) and (dist <  tonumber(players[igplayers[steam].alertBaseID].protectSize) + 50) then
				players[igplayers[steam].alertBaseID].exitX = intX
				players[igplayers[steam].alertBaseID].exitY = intY
				players[igplayers[steam].alertBaseID].exitZ = intZ

				if (accessLevel(steam) < 3) then
					message("pm " .. steam .. " [" .. server.chatColour .. "]You have set an exit teleport for " .. players[igplayers[steam].alertBaseID].name .. "'s base.[-]")
				else
					message("pm " .. steam .. " [" .. server.chatColour .. "]You have set an exit teleport for your base.  You can test it with /test base.[-]")
				end

				-- check for nearby bases
				failProtect = false
				for k, v in pairs(players) do
					if (v.homeX ~= 0) and k ~= igplayers[steam].alertBaseID then
							if (v.homeX ~= 0 and v.homeZ ~= 0) then
							dist = distancexz(players[igplayers[steam].alertBaseID].homeX, players[igplayers[steam].alertBaseID].homeZ, v.homeX, v.homeZ)

							if (tonumber(dist) < tonumber(players[igplayers[steam].alertBaseID].protectSize)) then
								if friends[k] == nil or not string.find(friends[k].friends, igplayers[steam].alertBaseID) then
									failProtect = true
								end
							end
						end
					end			

					if (v.home2X ~= 0) and k ~= igplayers[steam].alertBaseID then
						if (v.home2X ~= 0 and v.home2Z ~= 0) then
							dist = distancexz(players[igplayers[steam].alertBaseID].homeX, players[igplayers[steam].alertBaseID].homeZ, v.home2X, v.home2Z)

							if (dist < players[igplayers[steam].alertBaseID].protectSize + 10) then
								if not string.find(friends[k].friends, igplayers[steam].alertBaseID) then
									failProtect = true
								end
							end
						end
					end						
				end
			
				if failProtect == false then
					players[igplayers[steam].alertBaseID].protect = true
					message("pm " .. igplayers[steam].alertBaseID .. " [" .. server.chatColour .. "]Base protection for your base is active.[-]")
				else
					message("pm " .. igplayers[steam].alertBaseID .. " [" .. server.chatColour .. "]Your base is too close to another player base who is not on your friends list.  Protection cannot be enabled.[-]")
				end			

				igplayers[steam].alertBaseExit = nil
				igplayers[steam].alertBaseID = nil
				igplayers[steam].alertBase = nil

				faultyPlayerinfo = false
				return
			end
		else
			if (dist >  tonumber(players[igplayers[steam].alertBaseID].protect2Size) + 15) and (dist <  tonumber(players[igplayers[steam].alertBaseID].protect2Size) + 50) then
				players[igplayers[steam].alertBaseID].exit2X = intX
				players[igplayers[steam].alertBaseID].exit2Y = intY
				players[igplayers[steam].alertBaseID].exit2Z = intZ

				if (accessLevel(steam) < 3) then
					message("pm " .. steam .. " [" .. server.chatColour .. "]You have set an exit teleport for " .. players[igplayers[steam].alertBaseID].name .. "'s 2nd base.[-]")
				else
					message("pm " .. steam .. " [" .. server.chatColour .. "]You have set an exit teleport for your 2nd base.  You can test it with /test base.[-]")
				end

				-- check for nearby bases
				failProtect = false
				for k, v in pairs(players) do
					if (v.homeX ~= 0) and k ~= igplayers[steam].alertBaseID then
							if (v.homeX ~= 0 and v.homeZ ~= 0) then
							dist = distancexz(players[igplayers[steam].alertBaseID].home2X, players[igplayers[steam].alertBaseID].home2Z, v.homeX, v.homeZ)

							if (tonumber(dist) < tonumber(players[igplayers[steam].alertBaseID].protect2Size)) then
								if friends[k] == nil or not string.find(friends[k].friends, igplayers[steam].alertBaseID) then
									failProtect = true
								end
							end
						end
					end			

					if (v.home2X ~= 0) and k ~= igplayers[steam].alertBaseID then
						if (v.home2X ~= 0 and v.home2Z ~= 0) then
							dist = distancexz(players[igplayers[steam].alertBaseID].home2X, players[igplayers[steam].alertBaseID].home2Z, v.home2X, v.home2Z)

							if (dist < players[igplayers[steam].alertBaseID].protect2Size + 10) then
								if not string.find(friends[k].friends, igplayers[steam].alertBaseID) then
									failProtect = true
								end
							end
						end
					end						
				end
			
				if failProtect == false then
					players[igplayers[steam].alertBaseID].protect2 = true
					message("pm " .. igplayers[steam].alertBaseID .. " [" .. server.chatColour .. "]Base protection for your second base is active.[-]")
				else
					message("pm " .. igplayers[steam].alertBaseID .. " [" .. server.chatColour .. "]Your second base is too close to another player base who is not on your friends list.  Protection cannot be enabled.[-]")
				end			

				igplayers[steam].alertBaseExit = nil
				igplayers[steam].alertBaseID = nil
				igplayers[steam].alertBase = nil

				faultyPlayerinfo = false
				return
			end
		end
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 16") 
	end	

	x = math.floor(igplayers[steam].xPos / 512)
	z = math.floor(igplayers[steam].zPos / 512)

	if (accessLevel(steam) < 4) and server.enableRegionPM then
		if (igplayers[steam].region ~= "r." .. x .. "." .. z .. ".7rg") then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Region r." .. x .. "." .. z .. ".7rg[-]")
		end	
	end

	igplayers[steam].region = "r." .. x .. "." .. z .. ".7rg"
	igplayers[steam].regionX = x
	igplayers[steam].regionZ = z

	-- timeout
	if (players[steam].timeout == true or players[steam].botTimeout == true) then
		if (intY < 20000) then
			players[steam].tp = 1
			players[steam].hackerScore = 0
			send("tele " .. steam .. " " .. intX .. " " .. 50000 .. " " .. intZ)
		end	

		faultyPlayerinfo = false
		return
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 17") 
	end	

	-- world fall catcher
	fallCatcher(steam, intX, intY, intZ)

	-- prevent player exceeding the map limit unless an admin and ignoreadmins is false
	if outsideMap and players[steam].donor == false and (accessLevel(steam) > 3) then
		if not inLocation(intX, intZ) then
			message("pm " .. steam .. " [" .. server.chatColour .. "]This map is restricted to " .. (server.mapSize / 1000) .. " km from the center.[-]")
			players[steam].tp = 1
			players[steam].hackerScore = 0

			if players[steam].watchPlayer then
				irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. name .. " teleported by bot for exceeding map limit")
			end

			send ("tele " .. steam .. " " .. igplayers[steam].xPosLastOK .. " " .. igplayers[steam].yPosLastOK .. " " .. igplayers[steam].zPosLastOK)	
			faultyPlayerinfo = false
			return
		end
	end

	if outsideMapDonor and players[steam].donor == true and (accessLevel(steam) > 3 or server.ignoreAdmins == false) then
		if not inLocation(intX, intZ) then
			message("pm " .. steam .. " [" .. server.chatColour .. "]This map is restricted to " .. ((server.mapSize + 5000) / 1000) .. " km from the center.[-]")
			players[steam].tp = 1
			players[steam].hackerScore = 0

			if players[steam].watchPlayer then
				irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. name .. " teleported by bot for exceeding map limit")
			end

			send ("tele " .. steam .. " " .. igplayers[steam].xPosLastOK .. " " .. igplayers[steam].yPosLastOK .. " " .. igplayers[steam].zPosLastOK)	
			faultyPlayerinfo = false
			return
		end
	end

	if tonumber(players[steam].exiled) == 1 and locations["exile"] and not players[steam].prisoner then
		if (distancexz( intX, intZ, locations["exile"].x, locations["exile"].z ) > tonumber(locations["exile"].size)) then

			if players[steam].watchPlayer then
				irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. name .. " teleported by bot to exile")
			end

			randomPVPTP(steam, "exile", true)
			faultyPlayerinfo = false
			return
		end

		if players[steam].inLocation ~= "exile" then
			-- fix an occasional issue with unset coords
			if tonumber(igplayers[steam].xPosLastOK) == 0 and tonumber(igplayers[steam].yPosLastOK) == 0 and tonumber(igplayers[steam].zPosLastOK) == 0 then
				cmd = "tele " .. steam .. " " .. locations["exile"].x .. " " .. locations["exile"].y .. " " .. locations["exile"].z
			else
				cmd = "tele " .. steam .. " " .. igplayers[steam].xPosLastOK .. " " .. igplayers[steam].yPosLastOK .. " " .. igplayers[steam].zPosLastOK
			end

			igplayers[steam].lastTP = cmd

			if players[steam].watchPlayer then
				irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. name .. " teleported by bot to exile")
			end

			teleport(cmd, true)	
			faultyPlayerinfo = false
			return
		end
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 18") 
	end	

	-- left prison zone warning 
	if (locations["prison"]) then
		if (distancexz( intX, intZ, locations["prison"].x, locations["prison"].z ) > tonumber(locations["prison"].size)) then
			if (players[steam].alertPrison == false) then
				if (not players[steam].prisoner) and 	players[steam].showLocationMessages then
					message("pm " .. steam .. " [" .. server.chatColour .. "]You have left the prison.[-]")
				end

				players[steam].alertPrison = true
			end
		end

		if (players[steam].prisoner) then
			if (locations["prison"]) then
				if (squareDistanceXZXZ(locations["prison"].x, locations["prison"].z, intX, intZ, locations["prison"].size)) then
					players[steam].alertPrison = false

					if (squareDistanceXZXZ(locations["prison"].x, locations["prison"].z, igplayers[steam].xPosLastOK, igplayers[steam].zPosLastOK, locations["prison"].size)) then
						cmd = "tele " .. steam .. " " .. locations["prison"].x .. " " .. locations["prison"].y .. " " .. locations["prison"].z
					else
						cmd = "tele " .. steam .. " " .. igplayers[steam].xPosLastOK .. " " .. igplayers[steam].yPosLastOK .. " " .. igplayers[steam].zPosLastOK
					end

					if players[steam].watchPlayer then
						irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. name .. " teleported by bot to prison")
					end

					prepareTeleport(steam, cmd)
					teleport(cmd, true)
				end
			end

			faultyPlayerinfo = false
			return
		end

		-- entered prison zone warning 
		if (distancexz( intX, intZ, locations["prison"].x, locations["prison"].z ) < tonumber(locations["prison"].size)) then
			if (players[steam].alertPrison == true) then
				if (not players[steam].prisoner) and players[steam].showLocationMessages then
					message("pm " .. steam .. " [" .. server.chatColour .. "]You have entered the prison.  Continue at your own risk.[-]")
				end
				players[steam].alertPrison = false
			end
		end
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 19") 
	end	

	-- freeze!
	if (players[steam].freeze == true) then
		players[steam].tp = 1
		players[steam].hackerScore = 0
		send("tele " .. steam .. " " .. igplayers[steam].xPosLastOK .. " " .. igplayers[steam].yPosLastOK .. " " .. igplayers[steam].zPosLastOK)	
		faultyPlayerinfo = false
		return
	end


	-- teleport lookup
	if (igplayers[steam].teleCooldown < 1) and (players[steam].prisoner == false) then
		tp = ""
		tp = LookupTeleport(posX, posY, posZ)
		if (tp ~= nil and teleports[tp].active == true) then
			ownerid = LookupOfflinePlayer(teleports[tp].owner)
			if (players[steam].walkies ~= true) then
				if (accessLevel(steam) < 3) or (teleports[tp].owner == igplayers[steam].steam or teleports[tp].public == true or isFriend(ownerid, steam)) then
					if match == 1 then
						igplayers[steam].teleCooldown = 1
						cmd = "tele " .. steam .. " " .. math.floor(teleports[tp].dx) .. " " .. math.ceil(teleports[tp].dy) + 1 .. " " .. math.floor(teleports[tp].dz)
						igplayers[steam].lastTP = cmd

						if players[steam].watchPlayer then
							irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. name .. " teleported by bot (triggered " .. tp .. " teleport)")
						end

						teleport(cmd, true)

						faultyPlayerinfo = false
						return
					end

					if match == 2 and teleports[tp].oneway == false then
						igplayers[steam].teleCooldown = 1
						cmd = "tele " .. steam .. " " .. math.floor(teleports[tp].x) .. " " .. math.ceil(teleports[tp].y) + 1 .. " " .. math.floor(teleports[tp].z)
						igplayers[steam].lastTP = cmd

						if players[steam].watchPlayer then
							irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. name .. " teleported by bot (triggered " .. tp .. " teleport)")
						end

						teleport(cmd, true)

						faultyPlayerinfo = false
						return
					end
				end
			end
		end
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 20") 
	end	


	-- left reset zone warning
	if (not resetZone) then
		if (players[steam].alertReset == false) and players[steam].showLocationMessages then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You are out of the reset zone.[-]")
			players[steam].alertReset = true
			faultyPlayerinfo = false
		end
	end


	-- entered reset zone warning 
	if (resetZone) then
		if (players[steam].alertReset == true) and players[steam].showLocationMessages then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You are in a reset zone. Don't build here.[-]")
			players[steam].alertReset = false
			faultyPlayerinfo = false

			-- check for claims in the reset zone not owned by staff and remove them
			checkRegionClaims(x, z)
		end
	end


	if (steam == debugSteam) then 
		dbug("debug playerinfo 21") 
	end	

	if	baseProtection(steam, posX, posY, posZ) and not resetZone then
		faultyPlayerinfo = false
		return
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 21a") 
	end	

	-- add to tracker table
	dist = distancexyz(intX, intY, intZ, igplayers[steam].xPosLast, igplayers[steam].yPosLast, igplayers[steam].zPosLast)

	if (dist > 2) and tonumber(intY) > 0 and tonumber(intY) < 255 then
		-- record the players position
		conn:execute("INSERT INTO tracker (steam, x, y, z, session) VALUES (" .. steam .. "," .. intX .. "," .. intY .. "," .. intZ .. "," .. players[steam].sessionCount .. ")")

		if igplayers[steam].location ~= nil then
			conn:execute("INSERT INTO locationSpawns (location, x, y, z) VALUES ('" .. igplayers[steam].location .. "'," .. intX .. "," .. intY .. "," .. intZ .. ")")
		end
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 22") 
	end	

	if (igplayers[steam].deadX ~= nil) then
		dist = math.abs(distancexz(igplayers[steam].deadX, igplayers[steam].deadZ, posX, posZ))
		if (dist > 2) then
			igplayers[steam].deadX = nil
			igplayers[steam].deadY = nil
			igplayers[steam].deadZ = nil
			
			if players[steam].bed ~= "" then
				if players[steam].bed == "base1" then
					cmd = "tele " .. steam .. " " .. players[steam].homeX .. " " .. players[steam].homeY .. " " .. players[steam].homeZ
					igplayers[steam].lastTP = cmd

					if players[steam].watchPlayer then
						irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. name .. " teleported by bot")
					end

					teleport(cmd, true)	
				end	
				
				if players[steam].bed == "base2" then
					cmd = "tele " .. steam .. " " .. players[steam].home2X .. " " .. players[steam].home2Y .. " " .. players[steam].home2Z
					igplayers[steam].lastTP = cmd

					if players[steam].watchPlayer then
						irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. name .. " teleported by bot")
					end

					teleport(cmd, true)	
				end				
			end
		end
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 23") 
	end	

	-- hotspot lookup
	hotspot = LookupHotspot(posX, posY, posZ)

	if (hotspot ~= nil) then
		if (igplayers[steam].lastHotspot ~= hotspot) then
			for k, v in pairs(lastHotspots[steam]) do
				-- todo finish this off.  look for presence of hotspot
				if v == hotspot then -- don't add or display this hotspot yet.  we've seen it recently
					faultyPlayerinfo = false
					return
				end
			end

			igplayers[steam].lastHotspot = hotspot
			message("pm " .. steam .. " [" .. server.chatColour .. "]" .. hotspots[hotspot].hotspot .. "[-]")

			if (lastHotspots[steam] == nil) then lastHotspots[steam] = {} end
			if (table.maxn(lastHotspots[steam]) > 10) then
				table.remove(lastHotspots[steam], 1)
			end	

			table.insert(lastHotspots[steam],  hotspot)
			faultyPlayerinfo = false
		end
	end


	if (steam == debugSteam) then 
		dbug("debug playerinfo 24") 
	end	

	if igplayers[steam].rawPosition ~= rawPosition then
		igplayers[steam].afk = os.time() + 900
		igplayers[steam].rawPosition = rawPosition
	end

	--if (playersOnline >= server.ServerMaxPlayerCount) and (accessLevel(steam) > 3) then
	--	if (igplayers[steam].afk - os.time() < 0) then
	--		send ("kick " .. steam .. " Server is full.  You were kicked because you were idle too long.  You can rejoin any time.")
	--	end
	--end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 25") 
	end	


	if (pvpZone(posX, posZ) ~= false) then
		if players[steam].alertPVP == true then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You have entered a PVP zone!  Proceed with caution.[-]")
			players[steam].alertPVP = false
			faultyPlayerinfo = false
		end
	else
		if players[steam].alertPVP == false then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You have left a PVP zone.  Do not kill other players here![-]")
			players[steam].alertPVP = true
			faultyPlayerinfo = false
		end
	end

	if (steam == debugSteam) then 
		dbug("debug playerinfo 26") 
	end	

	-- report players movement to irc in _tracker channel
	if players[steam].watchPlayer then
		if math.abs(igplayers[steam].xPosLastOK) > 0 and math.abs(igplayers[steam].yPosLastOK) > 0 and math.abs(igplayers[steam].zPosLastOK) > 0 then
			dist = math.abs(distancexyz(igplayers[steam].xPosLastOK, igplayers[steam].yPosLastOK, igplayers[steam].zPosLastOK, posX, posY, posZ))

			if dist > 40 then
--				irc_QueueMsg(server.ircTracker, gameDate .. " " .. steam .. " " .. name .. " old [ " .. igplayers[steam].xPosLastOK .. " " .. igplayers[steam].yPosLastOK .. " " .. igplayers[steam].zPosLastOK .. " ] new [ " .. intX .. " " .. intY .. " " .. intZ .. " ] dist " .. string.format("%.1f", dist) )
			end
		end
	end

	-- stuff to do after everything else
--	igplayers[steam].xPosLast = posX
--	igplayers[steam].yPosLast = posY
--	igplayers[steam].zPosLast = posZ

	-- record this coord as the last one that the player was allowed to be at.  if their next step is not allowed, they get returned to this one.
	igplayers[steam].xPosLastOK = intX
	igplayers[steam].yPosLastOK = intY
	igplayers[steam].zPosLastOK = intZ

	faultyPlayerinfo = false

	if (steam == debugSteam) then 
		dbug("end playerinfo") 
	end	
end


function playerInfoTrigger(line)
	if botDisabled then
		return
	end

	if string.find(line, ", health=") then
		if faultyPlayerinfo == true and tonumber(faultyPlayerinfoID) > -1 then
			cecho(server.windowDebug, "!! Fault detected in playerinfo trigger\n")
			cecho(server.windowDebug, faultyPlayerinfoLine .. "\n")

			cecho(server.windowAlerts, "!! Fault detected in playerinfo trigger\n")
			cecho(server.windowAlerts, faultyPlayerinfoLine .. "\n")

			if tonumber(	faultyPlayerinfoID) > 0 and players[faultyPlayerinfoID] then
				fixMissingPlayer(faultyPlayerinfoID)

				if igplayers[faultyPlayerinfoID] then
					fixMissingIGPlayer(faultyPlayerinfoID)	
				end
			end
		end

		playerInfo()
		deleteLine()
	end
end
