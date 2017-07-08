--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug = false

function arenaPicknMix(wave, counter, playerLevel)
	local r

	r = tostring(math.random(1,botman.maxGimmeZombies))

	if gimmeZombies[r] == nil then
		r = arenaPicknMix(wave, counter, playerLevel)
	else
		if gimmeZombies[r].doNotSpawn or tonumber(gimmeZombies[r].minArenaLevel) > tonumber(playerLevel) then
			r = arenaPicknMix(wave, counter, playerLevel)
		end
	end

	if (tonumber(wave) < 4 and gimmeZombies[r].bossZombie) or string.find(gimmeZombies[r].zombie, "eral") then
		r = arenaPicknMix(wave, counter, playerLevel) -- don't allow feral zombies or boss zombies before round 4
	else
		if not gimmeZombies[r].bossZombie and tonumber(counter) < 10 then
			counter = counter + 1
			r = arenaPicknMix(wave, counter, playerLevel) -- only pick boss zombies
		else
			-- give up trying to pick a boss zombie.  Maybe none are flagged yet?
		end
	end

	return r
end


function PicknMix(level)
	local r

	if level == nil then
		level = 9001
	end

	r = tostring(gimmeZombiesIndex[math.random(1,table.getn(gimmeZombiesIndex))])

	if(not gimmeZombies[r]) then
		pruneZIndex(r)
		dbugFull("E", "", debugger.getinfo(1,"nSl"), "Zombie id: " .. r .. " needed to be pruned from the index.")
		PicknMix(level)
		return
	end
--[[
	r = tostring(math.random(1,botman.maxGimmeZombies))

	if gimmeZombies[r] == nil then
		r = PicknMix(level)
	else
--]]
		if gimmeZombies[r].doNotSpawn or tonumber(gimmeZombies[r].minPlayerLevel) > tonumber(level) then
			r = PicknMix(level)
		end
	--end

	return r
end


function setupArenaPlayers(pid)
	local dist, pointyStick, r, t, i, cmd, k, v

	t = os.time()
	arenaPlayers = {}
	botman.arenaCount = 0

	for k, v in pairs(igplayers) do
		if (distancexyz(v.xPos, v.yPos, v.zPos, locations["arena"].x, locations["arena"].y, locations["arena"].z) < tonumber(locations["arena"].size)) and math.abs(v.yPos - locations["arena"].y) < 4 then
			botman.arenaCount = botman.arenaCount + 1
			arenaPlayers[tostring(botman.arenaCount)] = {}
			arenaPlayers[tostring(botman.arenaCount)].id = k

			-- give arena players stuff
			send("give " .. v.id .. " firstAidBandage 2")
  			send("give " .. v.id .. " meatStew 1")

			r = math.random(1,3)
			if (r == 1) then pointyStick = "boneShiv" end
			if (r == 2) then pointyStick = "huntingKnife" end
			if (r == 3) then pointyStick = "clubSpiked"	 end

			send("give " .. v.id .. " " .. pointyStick .. " 1")
			message("pm " .. k .. " [" .. server.chatColour .. "]Supplies for the battle have been dropped at your feet. You have 10 seconds to prepare! (4 rounds)[-]")
		end
	end

	if (botman.arenaCount == 0) then
		message("pm " .. pid .. " [" .. server.chatColour .. "]Nobody is in the arena.  You can't play from the spectator area.  Get in the arena coward.[-]")
		botman.gimmeHell = 0
	end
end


function announceGimmeHell(wave)
	local k, v

	for k, v in pairs(arenaPlayers) do
		if (wave == 1) then
			message("pm " .. v.id .. " [" .. server.chatColour .. "]Here they come![-]")
		else
			message("pm " .. v.id .. " [" .. server.chatColour .. "]Here comes round " .. wave .. "![-]")
		end
	end
end


function resetGimmeHell()
	local k, v

	if (arenaTimer1 ~= nil) then
		killTimer(arenaTimer1)
		arenaTimer1 = nil
	end

	if (arenaTimer2 ~= nil) then
		killTimer(arenaTimer2)
		arenaTimer2 = nil
	end

	if (arenaTimer3 ~= nil) then
		killTimer(arenaTimer3)
		arenaTimer3 = nil
	end

	if (arenaTimer4 ~= nil) then
		killTimer(arenaTimer4)
		arenaTimer4 = nil
	end

	if (arenaTimer5 ~= nil) then
		killTimer(arenaTimer5)
		arenaTimer5 = nil
	end

	if (arenaTimer6 ~= nil) then
		killTimer(arenaTimer6)
		arenaTimer6 = nil
	end

	if (arenaTimer7 ~= nil) then
		killTimer(arenaTimer7)
		arenaTimer7 = nil
	end

	if (arenaTimer8 ~= nil) then
		killTimer(arenaTimer8)
		arenaTimer8 = nil
	end

	botman.gimmeHell = 0
	arenaPlayers = {}
	conn:execute("DELETE FROM playerQueue")

	for k, v in pairs(igplayers) do
		if (distancexyz(v.xPos, v.yPos, v.zPos, locations["arena"].x, locations["arena"].y, locations["arena"].z) < tonumber(locations["arena"].size) + 20) then
			message("pm " .. k .. " [" .. server.chatColour .. "]GimmeHell is ready to play![-]")
		end
	end

	botman.faultyChat = false
	return true
end


function queueGimmeHell(wave)
	local multiplier, i, r, p, k, v, cmd

	multiplier = math.random(7, 15)

	if (wave == 4) then
		multiplier = 2
	end

	for i = 1, botman.arenaCount * multiplier do
		if tonumber(botman.arenaCount) > 1 then
			p = math.random(1,botman.arenaCount)
		else
			p = 1
		end

		-- the level of the player that started gimmehell is used to control which zombies can be picked
		r = arenaPicknMix(wave, 0, players[arenaPlayers["1"].id].level)
		cmd = "se " .. players[arenaPlayers[tostring(p)].id].id .. " " .. r
		conn:execute("INSERT into playerQueue (command, arena, steam) VALUES ('" .. cmd .. "', true, " .. arenaPlayers[tostring(p)].id .. ")")
	end

	if (wave == 4) then
		for k, v in pairs(arenaPlayers) do
			cmd = "pm " .. v.id .. " [" .. server.chatColour .. "]Congratulations!  You have survived to the end of the fight!  Rest now. Tend to your wounded and mourn the fallen.[-]"
			conn:execute("INSERT into playerQueue (command, arena, steam) VALUES ('" .. cmd .. "', true, " .. v.id .. ")")
		end

		conn:execute("INSERT into playerQueue (command, arena, steam) VALUES ('reset', true, 0)")
	end
end


function gimmeReset()
	local k, v

	-- reset gimmeCount for everyone
	for k, v in pairs(players) do
		players[k].gimmeCount = 0
	end

	if (botman.playersOnline > 0) and server.allowGimme == true then
		message("say [" .. server.chatColour .. "]Gimme has been reset!  Type gimme to play (10 gimmies per player, 15 for donors) " .. server.commandPrefix .. "help gimme for info.")
	end
end


function gimme(pid)
	if (debug) then
		dbug("debug gimme line " .. debugger.getinfo(1).currentline)
		dbug("gimme pid " .. pid)
	end

	local cmd, maxGimmies, dist, r, rows, row, prize, category, entity, description, quality
	local pname = players[pid].name
	local specialDay = ""
	local playerid = igplayers[pid].id
	local zombies = tonumber(igplayers[pid].zombies)

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if botman.maxGimmeZombies == nil then
		-- the gimmeZombies table is empty so run se to fill it.
		send("se")
		botman.faultyGimme = false
		return
	end

	removeZombies() -- make sure there are no zeds left that we have flagged for removal
	removeEntities() -- make sure there are no entities left that we have flagged for removal

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if locations[players[pid].inLocation] then
		if not locations[players[pid].inLocation].pvp then
			message("pm " .. pid .. " [" .. server.chatColour .. "]Gimme cannot be played within a location unless it is pvp enabled.[-]")
			botman.faultyGimme = false
			return
		end
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (string.find(botman.serverTime, "02-14", 5, 10)) then specialDay = "valentine" end

	if (botman.faultyGimme == true) then
		dbugi("Fault occurred in Gimme #: " .. botman.faultyGimmeNumber)
	end

	botman.faultyGimme = true

	if players[pid].donor == true then
		maxGimmies = 16
	else
		maxGimmies = 11
	end

	if players[pid].gimmeCount == nil then
		players[pid].gimmeCount = 0
	end

	if tonumber(players[pid].gimmeCount) < tonumber(maxGimmies) then
		players[pid].gimmeCount = players[pid].gimmeCount + 1
	else
		message("pm " .. pid .. " [" .. server.chatColour .. "]You are out of gimmies.  You have to wait until the next gimme reset.[-]")
		botman.faultyGimme = false
		return
	end

	if server.gimmeZombies then
		r = math.random(1, botman.maxGimmeZombies + 30)
	else
		r = math.random(1,5)

		if r==1 then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " almost won a prize![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You almost won a prize![-]")
			end

			botman.faultyGimme = false
			return
		end

		if r == 2 or r == 3 then
			r = botman.maxGimmeZombies + 1
		end

		if r==4 then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " nearly won a cool prize![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You nearly won a cool prize![-]")
			end

			botman.faultyGimme = false
			return
		end

		if r==5 then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]Surprise! " .. pname .. " didn't win anything.[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]Surprise! You didn't win anything.[-]")
			end

			botman.faultyGimme = false
			return
		end
	end

	botman.faultyGimmeNumber = r

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end
	if debug then dbug("gimme random  " .. r .. " player = " .. pname) end
	if debug then dbug("max zombie id " .. botman.maxGimmeZombies) end

	if r <= botman.maxGimmeZombies then
		if gimmeZombies[tostring(r)] == nil then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " almost won a prize![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You almost won a prize![-]")
			end

			botman.faultyGimme = false
			return
		else
			if (gimmeZombies[tostring(r)].doNotSpawn) then
				if (not server.gimmePeace) then
					message("say [" .. server.chatColour .. "]" .. pname .. " almost won a prize![-]")
				else
					message("pm " .. pid .. " [" .. server.chatColour .. "]You almost won a prize![-]")
				end

				botman.faultyGimme = false
				return
			end
		end
	end

	-- get name of entity
	if gimmeZombies[tostring(r)] then
		entity = gimmeZombies[tostring(r)].zombie
	end

	spawnCount = 1

	if r <= botman.maxGimmeZombies then
		-- nasty zombies
		descriptor = math.random(1,6)
		chanceOfMultiples = math.random(1,50)

		if (chanceOfMultiples > 25) then
			if (zombies > 99) and (zombies < 300) then spawnCount = math.random(1,3) end
			if (zombies > 299) and (zombies < 500) then spawnCount = math.random(1,4) end
			if (zombies > 499) and (zombies < 1000) then spawnCount = math.random(1,5) end
			if (zombies > 999) and (zombies < 5000) then spawnCount = math.random(1,6) end
			if (zombies > 4999) then spawnCount = math.random(1,8) end
		end

if entity == "zombieferal" then
	spawnCount = 1
end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

		coffee = ""
--		if (tonumber(server.gameHour) > 21 or tonumber(server.gameHour) < 5) then coffee = "caffeinated " end

		-- set up critter description
		if (spawnCount == 1) then
			if (descriptor == 1) then
				description = "a surprised " .. coffee
			end

			if (descriptor == 2) then
				description = "an angry " .. coffee
			end

			if (descriptor == 3) then
				description = "a very dangerous " .. coffee
			end

			if (descriptor == 4) then
				description = "a murderous " .. coffee
			end

			if (descriptor == 5) then
				description = "a pissed off " .. coffee
			end

			if (descriptor == 6) then
				description = "an adorable " .. coffee
			end
		else
			if (descriptor == 1) then
				description = "surprised " .. coffee
			end

			if (descriptor == 2) then
				description = "angry " .. coffee
			end

			if (descriptor == 3) then
				description = "very dangerous " .. coffee
			end

			if (descriptor == 4) then
				description = "murderous " .. coffee
			end

			if (descriptor == 5) then
				description = "pissed off " .. coffee
			end

			if (descriptor == 6) then
				description = "adorable " .. coffee
			end
		end

		if (specialDay == "valentine") then
			if (spawnCount == 1) then
				if (descriptor == 1) then
					description = "a romantic " .. coffee
				end

				if (descriptor == 2) then
					description = "an attractive " .. coffee
				end

				if (descriptor == 3) then
					description = "a very special " .. coffee
				end

				if (descriptor == 4) then
					description = "a besotted " .. coffee
				end

				if (descriptor == 5) then
					description = "a single and looking " .. coffee
				end

				if (descriptor == 6) then
					description = "an eligible " .. coffee
				end
			else
				if (descriptor == 1) then
					description = "eligible " .. coffee
				end

				if (descriptor == 2) then
					description = "super sexy " .. coffee
				end

				if (descriptor == 3) then
					description = "lusty " .. coffee
				end

				if (descriptor == 4) then
					description = "infatuated " .. coffee
				end

				if (descriptor == 5) then
					description = "approachable " .. coffee
				end

				if (descriptor == 6) then
					description = "gorgeous " .. coffee
				end
			end
		end
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 1) then
		cursor,errorString = conn:execute("select * from gimmePrizes")
		rows = tonumber(cursor:numrows())
		r = math.random(1,rows)

		cursor,errorString = conn:execute("select * from gimmePrizes limit " .. r - 1 .. ",1")
		row = cursor:fetch({}, "a")

		qty = math.random(1,tonumber(row.prizeLimit))
		category = row.category
		prize = row.name
		qual = row.quality
		quality = (10 * players[pid].level) + math.random(-50, 50)
		if quality < 50 then quality = 50 end
		if quality > 600 then quality = 600 end

		description = ""
		if (qty == 1) then description = "a " end

		if (category == "weapon") then
			descr = math.random(1,12)

			if (descr==1) then
				description = description .. "shiny new "
				quality = 600
			end

			if (descr==2) then description = description .. "dangerous " end

			if (descr==3) then
				description = description .. "sharp "
				quality = 450
			end

			if (descr==4) then
				description = description .. "well crafted "
				quality = 500
			end

			if (descr==5) then
				description = description .. "knock-off "
			end

			if (descr==6) then
				description = description .. "banged up "
				quality = 200
			end

			if (descr==7) then
				description = description .. "basic "
			end

			if (descr==8) then
				description = description .. "barely used "
				quality = 560
			end

			if (descr==9) then
				description = description .. "blood stained "
				quality = 250
			end

			if (descr==10) then
				description = description .. "common "
			end

			if (descr==11) then
				description = description .. "dull "
				quality = 100
			end

			if (descr==12) then
				description = description .. "rusty "
				quality = 50
			end
		end

		if (category == "book") then
			descr = math.random(1,12)

			if (descr==1) then description = description .. "rare " end
			if (descr==2) then description = description .. "wordy " end
			if (descr==3) then description = description .. "well written " end
			if (descr==4) then description = description .. "useful " end
			if (descr==5) then description = description .. "tatty old " end
			if (descr==6) then description = description .. "scruffy " end
			if (descr==7) then description = description .. "faded " end
			if (descr==8) then description = description .. "torn " end
			if (descr==9) then description = description .. "soggy " end
			if (descr==10) then description = description .. "dirty " end
			if (descr==11) then description = description .. "chewed " end
			if (descr==12) then description = description .. "ratty " end
		end

		if (category == "misc") then
			descr = math.random(1,12)

			if (descr==1) then description = description .. "common " end
			if (descr==2) then description = description .. "boring " end
			if (descr==3) then description = description .. "interesting " end
			if (descr==4) then description = description .. "damaged " end
			if (descr==5) then description = description .. "rare " end
			if (descr==6) then description = description .. "stupid " end
			if (descr==7) then description = description .. "stinky " end
			if (descr==8) then description = description .. "useless " end
			if (descr==9) then description = description .. "amazing " end
			if (descr==10) then description = description .. "collectable " end
			if (descr==11) then description = description .. "dull " end
			if (descr==12) then description = description .. "uninteresting " end
		end

		if (category == "health") then
			descr = math.random(1,10)

			if (descr==1) then description = description .. "dodgy " end
			if (descr==2) then description = description .. "sterile " end
			if (descr==3) then description = description .. "generic " end
			if (descr==4) then description = description .. "expensive " end
			if (descr==5) then description = description .. "highly saught after " end
			if (descr==6) then description = description .. "common " end
			if (descr==7) then description = description .. "knock-off " end
			if (descr==8) then description = description .. "yucky " end
			if (descr==9) then description = description .. "gross " end
			if (descr==10) then description = description .. "spare " end
		end

		if (category == "food") then
			descr = math.random(1,12)

			if (descr==1) then description = description .. "delicious " end
			if (descr==2) then description = description .. "yummy " end
			if (descr==3) then description = description .. "yucky " end
			if (descr==4) then description = description .. "tasty " end
			if (descr==5) then description = description .. "bland " end
			if (descr==6) then description = description .. "boring " end
			if (descr==7) then description = description .. "expired " end
			if (descr==8) then description = description .. "chewy " end
			if (descr==9) then description = description .. "crunchy " end
			if (descr==10) then description = description .. "tainted " end
			if (descr==11) then description = description .. "stinky " end
			if (descr==12) then description = description .. "funky " end
		end

		if (category == "tools") then
			descr = math.random(1,10)

			if (descr==1) then description = description .. "handy " end
			if (descr==2) then description = description .. "utilitarian " end
			if (descr==3) then description = description .. "dirty " end
			if (descr==4) then description = description .. "rusty " end
			if (descr==5) then description = description .. "sturdy " end
			if (descr==6) then description = description .. "ACME " end
			if (descr==7) then description = description .. "knock-off " end
			if (descr==8) then description = description .. "genuine " end
			if (descr==9) then description = description .. "basic " end
			if (descr==10) then description = description .. "designer " end
		end

		if (category == "clothes") then
			descr = math.random(1,10)

			if (descr==1) then
				description = description .. "shitty "
				quality = 200
			end

			if (descr==2) then
				description = description .. "sturdy "
				quality = 500
			end

			if (descr==3) then
				description = description .. "tatty "
				quality = 200
			end

			if (descr==4) then
				description = description .. "used "
				quality = 300
			end

			if (descr==5) then
				description = description .. "brand new "
				quality = 600
			end

			if (descr==6) then
				description = description .. "soiled "
				quality = 400
			end

			if (descr==7) then
				description = description .. "boring "
				quality = 300
			end

			if (descr==8) then
				description = description .. "fabulous "
				quality = 550
			end

			if (descr==9) then
				description = description .. "natty "
				quality = 550
			end

			if (descr==10) then
				description = description .. "stylish "
				quality = 550
			end
		end

		description = description .. prize

		if (qty > 1) then
			description = qty .. " " .. description .. "s"
		end

		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won " .. description .. "[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You won " .. description .. "[-]")
		end

		if qual ~= 0 then
			send("give " .. pid .. " " .. prize .. " " .. qty .. " " .. quality)
		else
			send("give " .. pid .. " " .. prize .. " " .. qty)
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 2) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " almost won a prize![-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You almost won a prize![-]")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 3) then
		tmp = {}
		for k,v in pairs(otherEntities) do
			if string.find(string.lower(v.entity), "abbit") then
				tmp.entityid = k
			end
		end

		if tmp.entityid ~= nil then
			spawnCount = math.random(2,7)
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " won " .. spawnCount .. " BUNNIES![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You won " .. spawnCount .. " BUNNIES![-]")
			end

			for i = 1, spawnCount do
				cmd = "se " .. playerid .. " " .. tmp.entityid
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
			end
		else
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			end
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 4) then
		r = math.random(1,100)
		if (r < 70) then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " almost won an epic prize![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You almost won an epic prize![-]")
			end

			botman.faultyGimme = false
			return
		end

		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won epic litter![-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You won epic litter![-]")
		end

		t = os.time()
		for i = 1, 100 do
			r = math.random(1,7)

			if (r == 1) then litter = "canEmpty" end
			if (r == 2) then litter = "candyTin" end
			if (r == 3) then litter = "paper" end
			if (r == 4) then litter = "cloth" end
			if (r == 5) then litter = "yuccaFibers" end
			if (r == 6) then litter = "dirt" end
			if (r == 6) then litter = "bulletCasing" end
			if (r == 7) then litter = "emptyJar" end

			cmd = "give " .. playerid .. " " .. litter .. " 1"
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 5) then
		item = math.random(1,12)
		if (item == 1) then prize = "canBeef" end
		if (item == 2) then prize = "canChili" end
		if (item == 3) then prize = "canPasta" end
		if (item == 4) then prize = "gasCan" end
		if (item == 5) then prize = "firstAidBandage" end
		if (item == 6) then prize = "beer" end
		if (item == 7) then prize = "shades" end
		if (item == 8) then prize = "bottledWater" end
		if (item == 9) then prize = "baconAndEggs" end
		if (item == 10) then prize = "vegetableStew" end
		if (item == 11) then prize = "goldenRodTea" end
		if (item == 12) then prize = "coffee" end

		for k, v in pairs(igplayers) do
			if (k ~= pid) then send("give " .. k .. " " .. prize .. " 1") end
		end

		message("say [" .. server.chatColour .. "]" .. pname .. " won a " .. prize .. " for everyone! One for you, one for you, and you and.. oh sorry " .. pname .. " none left.[-]")
		message("say [" .. server.chatColour .. "]Everyone else collect your prize![-]")
		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 6) then
		descr = math.random(1,9)

		if (descr == 1) then cmd = "Nothing!" end
		if (descr == 2) then cmd = "Nothing!" end
		if (descr == 3) then cmd = "Nothing!" end

		if (descr == 4) then
			cmd = "*BZZT*  Oh no!  It's eaten another gimmie![-]"
			players[pid].gimmeCount = players[pid].gimmeCount + 1
		end

		if (descr == 5) then
			i = math.random(1,4)

			cmd = i .. " extra gimmies! =D"
			players[pid].gimmeCount = players[pid].gimmeCount - i
		end

		if (descr > 5 and descr < 10) then
			r = math.random(1,10)
			 if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " Ruh Roh! Gimmies short circuited!  You win..[-]")
				cmd = "say Every panels lit up! They're coming out of the walls! RUN !![-]"
			else
				message("pm [" .. server.chatColour .. "]" .. playerid .. " Ruh Roh! Gimmies short circuited!  You win..[-]")
				cmd = "pm " .. playerid .. " [" .. server.chatColour .. "]Every panels lit up! They're coming out of the walls! RUN !![-]"
			end

			tempTimer( 1, [[message("]].. cmd .. [[")]] )

			for i = 1, r do
				z = PicknMix(players[pid].level)
				cmd = "se " .. playerid .. " " .. z
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
			end

			botman.faultyGimme = false
			return
		end

		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " Ruh Roh! Gimmies short circuited!  You win..[-]")
			cmd = "say [" .. server.chatColour .. "]" .. cmd .. "[-]"
			tempTimer( 2, [[message("]].. cmd .. [[")]] )
		else
			cmd = "pm " .. pid .. " [" .. server.chatColour .. "]" .. cmd .. "[-]"
			tempTimer( 2, [[message("]].. cmd .. [[")]] )
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 7) then
		tmp = {}
		for k,v in pairs(gimmeZombies) do
			if string.find(string.lower(v.zombie), "zombiedog") then
				tmp.entityid = k
			end
		end

		if tmp.entityid ~= nil then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]HAPPY BIRTHDAY " .. pname .. "!  We got you a puppy![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]HAPPY BIRTHDAY " .. pname .. "! We got you a puppy![-]")
			end

			cmd = "se " .. playerid .. " " .. tmp.entityid
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
		else
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			end
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 8) then
		tmp = {}
		for k,v in pairs(gimmeZombies) do
			if string.find(string.lower(v.zombie), "snow") then
				tmp.entityid = k
			end
		end

		if tmp.entityid ~= nil then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]You won a HUGE STEAK!!! " .. pname .. "!  But this guy ate it :(  Deal with him![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You won a HUGE STEAK!!! " .. pname .. "!  But this guy ate it :(  Deal with him![-]")
			end

			cmd = "se " .. playerid .. " " .. tmp.entityid
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
		else
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			end
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 9) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won invisiblity!  Press Alt-F4 to claim your prize!!![-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You won invisiblity!  Press Alt-F4 to claim your prize!!![-]")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 10) then
		spawnCount = math.random(10,30)
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " ate a bad potato and is shitting potatoes everywhere![-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]" .. pname .. " ate a bad potato and is shitting potatoes everywhere![-]")
		end

		for i = 1, spawnCount do
			cmd = "give " .. playerid .. " potato 1"
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 11) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " voted first place WINNER! Here's your trophy.[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]" .. pname .. " voted first place WINNER! Here's your trophy.[-]")
		end

		cmd = "give " .. playerid .. " trophy 1"
		conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 12) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won a care package via air drop.  Gee I hope the pilot knows where the drop zone is![-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]" .. pname .. " won a care package via air drop.  Gee I hope the pilot knows where the drop zone is![-]")
		end

		send("spawnairdrop")

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 13) then
		players[pid].baseCooldown = 0
		conn:execute("UPDATE players SET baseCooldown = 0 WHERE steam = " .. pid)

		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won a get out of Dodge free card!  Their base cooldown has been reset.[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]" .. pname .. " won a get out of Dodge free card!  Your base cooldown has been reset.[-]")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 14) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won an air drop, but it is guarded by a boss zombie!  Show him who's boss.[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You won an air drop, but it is guarded by a boss zombie!  Show him who's boss.[-]")
		end

		tmp = {}
		for k,v in pairs(otherEntities) do
			if string.find(string.lower(v.entity), "eneral") then
				tmp.entityid = k
			end
		end

		cmd = "se " .. playerid .. " " .. tmp.entityid
		conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")

		tmp = {}
		for k,v in pairs(gimmeZombies) do
			if string.find(string.lower(v.zombie), "zombiedog") then
				tmp.entityid = k
			end
		end

		cmd = "se " .. playerid .. " " .. tmp.entityid
		conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if tonumber(r) > botman.maxGimmeZombies + 14 and tonumber(r) < botman.maxGimmeZombies + 21 then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 21) then
		spawnCount = math.random(10, 30)
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won some shit.[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]Here is your prize. It's a bit shitty but congrats! [-]")
		end

		for i = 1, spawnCount do
			cmd = "give " .. playerid .. " turd 1"
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if r > botman.maxGimmeZombies + 21 then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " did not win a prize.[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You did not win a prize.[-]")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (spawnCount == 1) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won " .. description .. entity .. "[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You've won " .. description .. entity .. "[-]")
		end
	else
		if (zombies > 2499) then
			descr = " won " .. spawnCount .. " Pick 'N Mix Zombies!"

			if spawnCount == 6 then
				descr = " won a 6 pack of Ready-To-Die zombies!"
			end

			if spawnCount == 12 then
				descr = " won a 12 pack of zombies!"
			end

			if spawnCount == 13 then
				descr = " won a bakers dozen of zombies!"
			end

			if spawnCount == 24 then
				descr = " won a hearty 24 pack of zombies!"
			end

			if spawnCount == 50 then
				descr = " won ALL THE ZOMBIES!"
			end

			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. descr .. "[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]" .. pname .. descr .. "[-]")
			end
		else
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " won " .. spawnCount .. " " .. description .. entity .."s![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]" .. pname .. " won " .. spawnCount .. " " .. description .. entity .."s![-]")
			end
		end
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (spawnCount == 1) then
		cmd = "se " .. playerid .. " " .. r
		conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")

		if (specialDay == "valentine") then
			z = math.random(1,4)
			if z == 1 then send("give " .. playerid .. " yellowflower 1") end
			if z == 2 then send("give " .. playerid .. " plantChrysanthemum 1") end
			if z == 3 then send("give " .. playerid .. " goldenrod 1") end
			if z == 4 then send("give " .. playerid .. " cotton 1") end
		end
	else
		if (zombies > 2499) then
			for i = 1, spawnCount do
				cmd = "se " .. playerid .. " " .. PicknMix()
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
			end
		else
			for i = 1, spawnCount do
				cmd = "se " .. playerid .. " " .. r
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")

				if (specialDay == "valentine") then
					z = math.random(1,4)
					if z == 1 then cmd = "give " .. playerid .. " yellowflower 1" end
					if z == 2 then cmd = "give " .. playerid .. " plantChrysanthemum 1" end
					if z == 3 then cmd = "give " .. playerid .. " goldenrod 1" end
					if z == 4 then cmd = "give " .. playerid .. " cotton 1" end

					conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
				end
			end
		end
	end

if debug then dbug("debug gimme end") end

	botman.faultyGimme = false
	return
end
