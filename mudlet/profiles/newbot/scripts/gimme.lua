--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function arenaPicknMix(wave)
	local r

	r = rand(17)
	if wave < 4 then
		if (r == 2) or (r == 7) then r = areanPicknMix() end -- don't allow feral zombie before round 4
	end

	return r
end

function PicknMix(mode)
	local r

	r = rand(30)
	if (r == 19) or (r == 7) then r = PicknMix() end
	if (r > 19 and r < 24) then r = PicknMix() end
	return r
end

function getEntity(r)
	entity = ""

	if (r == 1) then entity = "zombie01" end
	if (r == 2) then entity = "zombieferal" end
	if (r == 3) then entity = "zombieBoe" end 
	if (r == 4) then entity = "zombieJoe" end	 
	if (r == 5) then entity = "zombieMoe" end
	if (r == 6) then entity = "zombieArlene" end	 
	if (r == 7) then entity = "zombieScreamer" end	 
	if (r == 8) then entity = "zombieDarlene" end	 
	if (r == 9) then entity = "zombieMarlene" end	 
	if (r == 10) then entity = "zombieYo" end	 
	if (r == 11) then entity = "zombieSteve" end	 
	if (r == 12) then entity = "zombieSteveCrawler" end	 
	if (r == 13) then entity = "snowzombie" end	 
	if (r == 14) then entity = "spiderzombie" end	 
	if (r == 15) then entity = "burntzombie" end	 
	if (r == 16) then entity = "zombieNurse" end	 
	if (r == 17) then entity = "fatzombiecop" end	 
	if (r == 18) then r = rand(10) + 2 end
	if (r == 19) then entity = "zombiedog" end	 
	if (r == 20) then r = rand(10) + 2 end
	if (r == 21) then r = rand(10) + 2 end
	if (r == 22) then r = rand(10) + 2 end
	if (r == 23) then r = rand(10) + 2 end
	if (r == 24) then entity = "startled stag" end	 
	if (r == 25) then entity = "bear" end	 
	if (r == 26) then entity = "undead bear" end	 
	if (r == 27) then entity = "rabbit" end	 
	if (r == 28) then entity = "dumb chicken" end	
	if (r == 29) then entity = "delicious bacon" end	
	return entity
end


function setupArenaPlayers(pid)
	local dist
	local pointyStick
	local r
	local t
	local i
	local cmd

	t = os.time()
	arenaPlayers = {}
	arenaCount = 0

	for k, v in pairs(igplayers) do
		if (distancexyz(v.xPos, v.yPos, v.zPos, locations["arena"].x, locations["arena"].y, locations["arena"].z) < tonumber(locations["arena"].size)) then

			arenaCount = arenaCount + 1
			arenaPlayers[tostring(arenaCount)] = {}
			arenaPlayers[tostring(arenaCount)].id = k

			-- give arena players stuff
			send("give " .. v.id .. " firstAidBandage 2")
  			send("give " .. v.id .. " meatStew 1")

			r = rand(4)
			if (r == 1) then pointyStick = "boneShiv" end
			if (r == 2) then pointyStick = "huntingKnife" end
			if (r == 3) then pointyStick = "clubSpiked"	 end

			send("give " .. v.id .. " " .. pointyStick .. " 1")
			message("pm " .. k .. " [" .. server.chatColour .. "]Supplies for the battle have been dropped at your feet. You have 10 seconds to prepare! (4 rounds)[-]")
		end
	end

	if (arenaCount == 0) then
		message("pm " .. pid .. " [" .. server.chatColour .. "]Nobody is in the arena.  You can't play from the spectator area.  Get in the arena coward.[-]")
		gimmeHell = 0
	end
end


function announceGimmeHell(wave)
	for k, v in pairs(arenaPlayers) do
		if (wave == 1) then
			message("pm " .. v.id .. " [" .. server.chatColour .. "]Here they come![-]")
		else
			message("pm " .. v.id .. " [" .. server.chatColour .. "]Here comes round " .. wave .. "![-]")
		end
	end
end


function resetGimmeHell()
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

	gimmeHell = 0
	arenaPlayers = {}
	conn:execute("DELETE FROM playerQueue")					

	for k, v in pairs(igplayers) do
		if (distancexyz(v.xPos, v.yPos, v.zPos, locations["arena"].x, locations["arena"].y, locations["arena"].z) < tonumber(locations["arena"].size) + 20) then
			message("pm " .. k .. " [" .. server.chatColour .. "]gimmeHell is ready to play![-]")
		end
	end

	faultyChat = false
	return true
end


function queueGimmeHell(wave)
	local multiplier
	local r
	local p
	local cmd
	local zedBoss = 0

	multiplier = rand(13, 7)

	if (wave == 4) then
		multiplier = 2
	end

	for i = 1, arenaCount * multiplier do
		if tonumber(arenaCount) > 1 then
			p = rand(arenaCount + 1)
		else
			p = 1
		end

		r = arenaPicknMix(wave)

		if wave < 4 then
			while (r == 2) do
				r = arenaPicknMix(wave)
			end
		end

		if (wave == 4) then
			r = rand(3)
			if (r == 1) then r = 2 end
			if (r == 2) then r = 19 end

			cmd = "se " .. players[arenaPlayers["1"].id].id .. " " .. r
			conn:execute("INSERT into playerQueue (command, arena, boss, steam) VALUES ('" .. cmd .. "', true, true, " .. arenaPlayers["1"].id .. ")")					
		else	
			cmd = "se " .. players[arenaPlayers[tostring(p)].id].id .. " " .. r
			conn:execute("INSERT into playerQueue (command, arena, steam) VALUES ('" .. cmd .. "', true, " .. arenaPlayers[tostring(p)].id .. ")")					
		end
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
	-- reset gimmeCount for everyone
	for k, v in pairs(players) do
		players[k].gimmeCount = 0
	end

	if (playersOnline > 0) and server.allowGimme == true then
		message("say [" .. server.chatColour .. "]Gimme has been reset!  Type gimme to play (10 gimmies per player, 15 for donors) /help gimme for info.")
	end
end


function gimme(pid)

--display(pid)

local cmd, debug
local pname = players[pid].name
local specialDay = ""
local maxGimmies
local dist
local r, rows, row, prize, category

debug = false

if debug then dbug("debug gimme") end

if locations[players[pid].inLocation] then
	if not locations[players[pid].inLocation].pvp then
		message("pm " .. pid .. " [" .. server.chatColour .. "]Gimme cannot be played within a location unless it is pvp enabled.[-]")
		faultyGimme = false
		return
	end
end

if debug then dbug("debug gimme 1") end

if (string.find(serverTime, "02-14", 5, 10)) then specialDay = "valentine" end

if (faultyGimme == true) then
	cecho("Debug", "!! Fault detected in Gimme\n")
	cecho("Debug", "!! Fault occurred in Gimme #: " .. faultyGimmeNumber .. "\n")
end

faultyGimme = true

local steamid = pid
local playerid = igplayers[pid].id
local zombies = tonumber(igplayers[pid].zombies)

--		maxGimmies = 11

--display("gimme here")

--if (pid ~= Smegz0r) then
	if players[steamid].donor == true then
		maxGimmies = 16
	else
		maxGimmies = 11
	end

	if players[steamid].gimmeCount == nil then
		players[steamid].gimmeCount = 0
	end

	if (players[steamid].gimmeCount < tonumber(maxGimmies)) then
		players[steamid].gimmeCount = players[steamid].gimmeCount + 1
	else
		message("pm " .. steamid .. " [" .. server.chatColour .. "]You are out of gimmies.  You have to wait until the next gimme reset.[-]")
		faultyGimme = false
		return
	end
--end

	r = math.random(1, 60)
	faultyGimmeNumber = r

if debug then dbug("debug gimme 2") end
if debug then dbug("gimme random  " .. r .. " player = " .. pname) end

--[[
  1 - zombie01
  2 - zombie04
  3 - zombieferal
  4 - zombieBoe
  5 - zombieJoe
  6 - zombieMoe
  7 - zombieArlene
  8 - zombieScreamer
  9 - zombieDarlene
  10 - zombieMarlene
  11 - zombieYo
  12 - zombieSteve
  13 - zombieSteveCrawler
  14 - snowzombie
  15 - spiderzombie
  16 - burntzombie
  17 - zombieNurse
  18 - fatzombiecop
  19 - hornet
  20 - zombiedog
  21 - car_Blue
  22 - car_Orange
  23 - car_Red
  24 - car_White
  25 - animalStag
  26 - animalBear
  27 - zombieBear
  28 - animalRabbit
  29 - animalChicken
  30 - animalPig
  33 - zombieUMAfemale
  34 - zombieUMAmale
  35 - zombieMaleHazmat
  36 - zombieFemaleHazmat
  37 - minibike
--]]

	-- get name of entity
	if (r == 1) then entity = "zombie01" end
	if (r == 2) then entity = "zombie04" end
	if (r == 3) then entity = "zombieferal" end
	if (r == 4) then entity = "zombieBoe" end 
	if (r == 5) then entity = "zombieJoe" end	 
	if (r == 6) then entity = "zombieMoe" end
	if (r == 7) then entity = "zombieArlene" end	 
	if (r == 8) then entity = "zombieScreamer" end	 
	if (r == 9) then entity = "zombieDarlene" end	 
	if (r == 10) then entity = "zombieMarlene" end	 
	if (r == 11) then entity = "zombieYo" end	 
	if (r == 12) then entity = "zombieSteve" end	 
	if (r == 13) then entity = "zombieSteveCrawler" end	 
	if (r == 14) then entity = "snowzombie" end	 
	if (r == 15) then entity = "spiderzombie" end	 
	if (r == 16) then entity = "burntzombie" end	 
	if (r == 17) then entity = "zombieNurse" end	 
	if (r == 18) then entity = "fatzombiecop" end	 
	if (r == 19) then r = 31 end
	if (r == 20) then entity = "zombiedog" end	 
	if (r == 21) then r = 31 end
	if (r == 22) then r = 31 end
	if (r == 23) then r = 31 end
	if (r == 24) then r = 31 end
	if (r == 25) then entity = "startled stag" end	 
	if (r == 26) then entity = "bear" end	 
	if (r == 27) then entity = "undead bear" end	 
	if (r == 28) then entity = "rabbit" end	 
	if (r == 29) then entity = "dumb chicken" end	 

	spawnCount = 1

	if (r < 30) then
		-- nasty zombies
		descriptor = rand(6)	
		chanceOfMultiples = rand(50)
		
		if (chanceOfMultiples > 25) then
			if (zombies > 99) and (zombies < 300) then spawnCount = rand(3) end	
			if (zombies > 299) and (zombies < 500) then spawnCount = rand(4) end	
			if (zombies > 499) and (zombies < 800) then spawnCount = rand(5) end
			if (zombies > 799) and (zombies < 1000) then spawnCount = rand(6) end
			if (zombies > 999) and (zombies < 1500) then spawnCount = rand(7) end
			if (zombies > 1499) and (zombies < 2000) then spawnCount = rand(8) end
			if (zombies > 1999) and (zombies < 2500) then spawnCount = rand(9) end
			if (zombies > 2499) and (zombies < 3000) then spawnCount = rand(10) end
			if (zombies > 2999) and (zombies < 3500) then spawnCount = rand(11) end
			if (zombies > 3499) and (zombies < 4000) then spawnCount = rand(12) end
			if (zombies > 3999) and (zombies < 4500) then spawnCount = rand(13) end

			if (zombies > 4499) and (zombies < 5000) then spawnCount = rand(14) end
			if (zombies > 4999) and (zombies < 5500) then spawnCount = rand(15) end
			if (zombies > 5499) and (zombies < 6000) then spawnCount = rand(16) end
			if (zombies > 5999) and (zombies < 6500) then spawnCount = rand(17) end
			if (zombies > 6499) and (zombies < 7000) then spawnCount = rand(18) end
			if (zombies > 6999) and (zombies < 7500) then spawnCount = rand(19) end
			if (zombies > 7499) then spawnCount = rand(50) end
		end

if entity == "zombieferal" then
	spawnCount = rand(3)
end

if debug then dbug("debug gimme 3") end

--cecho("Debug", "spawnCount = " .. spawnCount .. "\n")

		coffee = ""
		if (tonumber(gameHour) > 21 or tonumber(gameHour) < 7) then coffee = "caffeinated " end

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

if debug then dbug("debug gimme 4") end

	if (r == 30) then 
		cursor,errorString = conn:execute("select * from gimmePrizes")
		rows = tonumber(cursor:numrows())
		r = rand(rows + 1)

		cursor,errorString = conn:execute("select * from gimmePrizes limit " .. r - 1 .. ",1")
		row = cursor:fetch({}, "a")

		qty = rand(tonumber(row.prizeLimit))
		category = row.category
		prize = row.name
		
		description = ""
		if (qty == 1) then description = "a " end
		
		if (category == "weapon") then
			descr = rand(13)
		
			if (descr==1) then description = description .. "shiny new " end
			if (descr==2) then description = description .. "dangerous " end			
			if (descr==3) then description = description .. "sharp " end						
			if (descr==4) then description = description .. "well crafted " end						
			if (descr==5) then description = description .. "knock-off " end									
			if (descr==6) then description = description .. "banged up " end									
			if (descr==7) then description = description .. "basic " end									
			if (descr==8) then description = description .. "barely used " end									
			if (descr==9) then description = description .. "blood stained " end												
			if (descr==10) then description = description .. "common " end												
			if (descr==11) then description = description .. "dull " end															
			if (descr==12) then description = description .. "rusty " end															
		end			
		
		if (category == "book") then
			descr = rand(13)
		
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
			descr = rand(13)
		
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
			descr = rand(11)
		
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
			descr = rand(13)
		
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
			descr = rand(11)
		
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
			descr = rand(11)
		
			if (descr==1) then description = description .. "shitty " end
			if (descr==2) then description = description .. "sturdy " end			
			if (descr==3) then description = description .. "tatty " end						
			if (descr==4) then description = description .. "used " end						
			if (descr==5) then description = description .. "brand new " end									
			if (descr==6) then description = description .. "soiled " end									
			if (descr==7) then description = description .. "boring " end									
			if (descr==8) then description = description .. "fabulous " end									
			if (descr==9) then description = description .. "natty " end												
			if (descr==10) then description = description .. "stylish " end												
		end
		
		description = description .. prize
		
		if (qty > 1) then
			description = qty .. " " .. description .. "s"
		end
				
		if (not server.gimmePeace) then			
			message("say [" .. server.chatColour .. "]" .. pname .. " won " .. description .. "[-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " won " .. description .. "[-]")
		end	
		
		send("give " .. steamid .. " " .. prize .. " " .. qty)

		faultyGimme = false
		return 
	end

	if (r == 31) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " almost won a prize![-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " almost won a prize![-]")
		end

		faultyGimme = false
		return 
	end

	if (r == 32) then
		spawnCount = rand(7,2)
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won " .. spawnCount .. " BUNNIES![-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " won " .. spawnCount .. " BUNNIES![-]")
		end

		for i = 1, spawnCount do
			cmd = "se " .. playerid .. " 28"
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. steamid .. ")")
		end

		faultyGimme = false
		return
	end

	if (r == 33) then
		r = rand(100)
		if (r < 70) then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " almost won an epic prize![-]")
			else
				message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " almost won an epic prize![-]")
			end

			faultyGimme = false
			return
		end

		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won epic litter![-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " won epic litter![-]")
		end

		t = os.time()
		for i = 1, 100 do
			r = rand(8)
		
			if (r == 1) then litter = "canEmpty" end
			if (r == 2) then litter = "candyTin" end
			if (r == 3) then litter = "paper" end
			if (r == 4) then litter = "cloth" end
			if (r == 5) then litter = "yuccaFibers" end
			if (r == 6) then litter = "dirt" end
			if (r == 6) then litter = "bulletCasing" end
			if (r == 7) then litter = "emptyJar" end

			cmd = "give " .. playerid .. " " .. litter .. " 1"
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. steamid .. ")")
		end

		faultyGimme = false
		return
	end

	if (r == 34) then
		item = rand(13)
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
			if (k ~= steamid) then send("give " .. k .. " " .. prize .. " 1") end
		end

		message("say [" .. server.chatColour .. "]" .. pname .. " won a " .. prize .. " for everyone! One for you, one for you, and you and.. oh sorry " .. pname .. " none left.[-]")
		message("say [" .. server.chatColour .. "]Everyone else collect your prize![-]")
		faultyGimme = false
		return
	end


	if (r == 35) then
		descr = rand(9)

		if (descr == 1) then cmd = "Nothing!" end
		if (descr == 2) then cmd = "Nothing!" end
		if (descr == 3) then cmd = "Nothing!" end

		if (descr == 4) then 
			cmd = "*BZZT*  Oh no!  It's eaten another gimmie![-]" 
			players[steamid].gimmeCount = players[steamid].gimmeCount + 1
		end

		if (descr == 5) then
			i = rand(4)
 
			cmd = i .. " extra gimmies! =D" 
			players[steamid].gimmeCount = players[steamid].gimmeCount - i
		end

		if (descr > 5 and descr < 9) then
			r = rand(10)
			 if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " Ruh Roh! Gimmies short circuited!  You win..[-]")
				cmd = "say Every panels lit up! OMG! Zombies are coming out of the walls! RUN !![-]" 
			else
				message("pm [" .. server.chatColour .. "]" .. playerid .. " Ruh Roh! Gimmies short circuited!  You win..[-]")
				cmd = "pm " .. playerid .. " [" .. server.chatColour .. "]Every panels lit up! OMG! Zombies are coming out of the walls! RUN !![-]" 
			end

			tempTimer( 1, [[message("]].. cmd .. [[")]] )

			for i = 1, r do
				z = PicknMix()
				cmd = "se " .. playerid .. " " .. z
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. steamid .. ")")
			end

			faultyGimme = false
			return
		end

		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " Ruh Roh! Gimmies short circuited!  You win..[-]")
			cmd = "say [" .. server.chatColour .. "]" .. cmd .. "[-]"
			tempTimer( 2, [[message("]].. cmd .. [[")]] )
		else
			cmd = "pm " .. steamid .. " [" .. server.chatColour .. "]" .. cmd .. "[-]"
			tempTimer( 2, [[message("]].. cmd .. [[")]] )
		end	

		faultyGimme = false
		return	
	end


	if (r == 36) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]HAPPY BIRTHDAY " .. pname .. "!  We got you a puppy![-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]HAPPY BIRTHDAY " .. pname .. "! We got you a puppy![-]")
		end

		cmd = "se " .. playerid .. " 20"
		conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. steamid .. ")")

		faultyGimme = false
		return
	end


	if (r == 37) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]You won a HUGE STEAK!!! " .. pname .. "!  But this guy ate it :(  Deal with him![-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]You won a HUGE STEAK!!! " .. pname .. "!  But this guy ate it :(  Deal with him![-]")
		end

		cmd = "se " .. playerid .. " 4"
		conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. steamid .. ")")

		faultyGimme = false
		return
	end


	if (r == 38) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won invisiblity!  Press Alt-F4 to claim your prize!!![-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]You won invisiblity!  Press Alt-F4 to claim your prize!!![-]")
		end

		faultyGimme = false
		return
	end


	if (r == 39) then
		spawnCount = rand(15,5)
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " ate a bad potato and is shitting potatoes everywhere![-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " ate a bad potato and is shitting potatoes everywhere![-]")
		end

		for i = 1, spawnCount do
			cmd = "give " .. playerid .. " potato 1"
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. steamid .. ")")
		end

		faultyGimme = false
		return
	end

	if (r == 40) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " voted first place WINNER! Here's your trophy.[-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " voted first place WINNER! Here's your trophy.[-]")
		end

		cmd = "give " .. playerid .. " trophy3 1"
		conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. steamid .. ")")

		faultyGimme = false
		return
	end


	if (r == 41) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won a care package via air drop.  Gee I hope the pilot knows where the drop zone is![-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " won a care package via air drop.  Gee I hope the pilot knows where the drop zone is![-]")
		end

		send("spawnairdrop")

		faultyGimme = false
		return
	end


	if (r == 42) then
		players[steamid].baseCooldown = 0
		conn:execute("UPDATE players SET baseCooldown = 0 WHERE steam = " .. steamid)

		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won a get out of Dodge free card!  Their base cooldown has been reset.[-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " won a get out of Dodge free card!  Your base cooldown has been reset.[-]")
		end

		faultyGimme = false
		return
	end	


	if (r > 42) and (r < 50) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
		end

		faultyGimme = false
		return
	end


	if (r > 49) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " did not win a prize.[-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " did not win a prize.[-]")
		end

		faultyGimme = false
		return
	end


	if (spawnCount == 1) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won " .. description .. entity .. "[-]")
		else
			message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " won " .. description .. entity .. "[-]")
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
				message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. descr .. "[-]")
			end
		else
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " won " .. spawnCount .. " " .. description .. entity .."s![-]")
			else
				message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. pname .. " won " .. spawnCount .. " " .. description .. entity .."s![-]")
			end
		end
	end

	if r > 30 then
		-- abort if r > 30 so we don't spawn the broken zeds
		faultyGimme = false
		return
	end

	if (spawnCount == 1) then
		cmd = "se " .. playerid .. " " .. r
		conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. steamid .. ")")

		if (specialDay == "valentine") then 
			z = rand(5)
			if z == 1 then send("give " .. playerid .. " yellowflower 1") end
			if z == 2 then send("give " .. playerid .. " plantChrysanthemum 1") end
			if z == 3 then send("give " .. playerid .. " goldenrod 1") end
			if z == 4 then send("give " .. playerid .. " cotton 1") end
		end
	else
		if (zombies > 2499) then
			for i = 1, spawnCount do
				cmd = "se " .. playerid .. " " .. PicknMix()
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. steamid .. ")")
			end
		else
			for i = 1, spawnCount do
				cmd = "se " .. playerid .. " " .. r
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. steamid .. ")")

				if (specialDay == "valentine") then 
					z = rand(5)
					if z == 1 then cmd = "give " .. playerid .. " yellowflower 1" end
					if z == 2 then cmd = "give " .. playerid .. " plantChrysanthemum 1" end
					if z == 3 then cmd = "give " .. playerid .. " goldenrod 1" end
					if z == 4 then cmd = "give " .. playerid .. " cotton 1" end

					conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. steamid .. ")")
				end
			end
		end
	end

if debug then dbug("debug gimme end") end

	faultyGimme = false
	return
end
