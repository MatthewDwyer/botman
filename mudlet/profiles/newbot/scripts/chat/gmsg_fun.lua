--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_fun()
	local result, debug, help, tmp
	local shortHelp = false

	calledFunction = "gmsg_fun"
	result = false
	tmp = {}
	tmp.topic = "fun"

	debug = false -- should be false unless testing
	--server.enableWindowMessages = true

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## Fun command functions ##################

	local function cmd_Beer()
		local cmd

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}beer"
			help[2] = "While in any location with beer in its name, players can grab a beer (or a lot)."

			tmp.command = help[1]
			tmp.keywords = "gimme,beer,gimmie"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		-- There's a beer command! :D
		if (chatvars.words[1] == "waiter" or chatvars.words[1] == "beer" and chatvars.words[2] == nil) then
			if string.find(inLocation(chatvars.intX, chatvars.intZ), "beer") then
				cmd = "give " .. chatvars.userID .. " drinkJarBeer 1"

				if server.botman then
					cmd = "bm-give " .. chatvars.userID .. " drinkJarBeer 1"
				end

				sendCommand(cmd)
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Enjoy your beer![-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FixGimme()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}fix gimme"
			help[2] = "Force the bot to rescan the list of zombies, animals and spawnable items."
			help[2] = help[2] .. "WARNING!  This command will send se and li * to the server which generates a massive list.  It may cause temporary lag on a full server."
			help[2] = help[2] .. "The bot will process the list slowly and will take a minute and a half to complete.  Be patient :P"

			tmp.command = help[1]
			tmp.keywords = "fix,gimme,repair,gimmie"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "fix" and chatvars.words[2] == "gimme") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if not server.useAllocsWebAPI then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command is not available in telnet mode.  Your bot must be in API mode.[-]")
				else
					irc_chat(chatvars.ircAlias, "This command is not available in telnet mode.  Your bot must be in API mode.")
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The zombies are being audited. Please ignore the paint, radio tags and collars.[-]")
			else
				irc_chat(chatvars.ircAlias, "The zombies are being audited. Please ignore the paint, radio tags and collars.")
			end

			gimmeZombies = {}
			if botman.dbConnected then conn:execute("TRUNCATE gimmeZombies") end
			sendCommand("se")

			-- also fix the shop
			if server.useAllocsWebAPI then
				fixShop()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PlaceBounty()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}place bounty {player name} {cash}"
			help[2] = "Place a bounty on a player's head. The money is removed from your cash."

			tmp.command = help[1]
			tmp.keywords = "gimme,pvp,bounty,gimmie"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		-- Help Wanted - dead
		if (chatvars.words[1] == "place" and chatvars.words[2] == "bounty") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = chatvars.words[3]
			id = LookupPlayer(pname)

			if id == "0" then
				id = LookupArchivedPlayer(pname)

				if not (id == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end
				end

				botman.faultyChat = false
				return true
			end

			bounty = math.abs(chatvars.words[4])

			if players[chatvars.playerid].cash >= bounty then
				oldBounty = players[id].pvpBounty
				players[id].pvpBounty = players[id].pvpBounty + bounty
				players[chatvars.playerid].cash = players[chatvars.playerid].cash - bounty
				message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " has placed a bounty of " .. bounty .. " on " .. players[id].name .. "'s head![-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You now have " .. string.format("%d", players[chatvars.playerid].cash) .. " " .. server.moneyPlural .. ".[-]")

				-- update the player's bounty
				if botman.dbConnected then conn:execute("UPDATE players SET pvpBounty = " .. players[id].pvpBounty .. " WHERE steam = '" .. id .. "'") end

				-- reduce the cash of the player who placed the bounty
				if botman.dbConnected then conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = '" .. chatvars.playerid .. "'") end

				if oldBounty > 0 then
					message("say [" .. server.chatColour .. "]" .. players[id].name .. "'s life is now worth " .. players[id].pvpBounty .. ".[-]")
				end
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. " to place that bounty.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PlayGimme()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme"
			help[2] = "Play one gimme - win a prize!\n"
			help[2] = help[2] .. "Gimme cannot be played within a location unless it is pvp enabled.\n"
			help[2] = help[2] .. "Gimme cannot be played inside a player base.\n"
			help[2] = help[2] .. "Prize may contain nuts. If a rash develops, see your doctor. Keep away from small children.  The bag is not a hat."

			tmp.command = help[1]
			tmp.keywords = "gimme,gimmie"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "gimmie" or chatvars.words[1] == "gimme") and (chatvars.words[2] == nil or chatvars.number ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.settings.allowGimme) then
				if tablelength(gimmeZombies) == 0 or gimmeZombies == nil then
					sendCommand("se")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Oopsie! Somebody fed the zombies. Wait a few seconds while we swap them out with fresh starving ones.[-]")
					botman.faultyChat = false
					return true
				end

				if tonumber(chatvars.settings.gimmeRaincheck) > 0 then
					tmp.gimmeCooldown = players[chatvars.playerid].gimmeCooldown - os.time()

					if (tmp.gimmeCooldown > 0) then
						r = randSQL(15)

						if r == 1 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You must wait " .. tmp.gimmeCooldown .. " seconds before you can do another gimme.[-]") end
						if r == 2 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Something is blocking your gimme. We should have it working again in " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 3 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Gimme gimme gimme but alas your gimme is delayed. Try again in " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 4 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Terribly sorry but gimme is out of stock thanks to panic playing during the pandemic. We should have more in " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 5 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Sorry gimme is on the fritz again. Please try again in " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 6 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Due to staffing shortages gimme is unavailable for at least " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 7 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]*BZZZT* *POP* Oh dear! Gimme blew another fuse. We should have it fixed in approximately " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 8 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "][OUT OF ORDER] Please try again in " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 9 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Sorry but gimme is being rationed due to shipping delays. Try again in " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 10 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Sorry it seems there has been a terrible mixup with your gimme. Please try again in " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 11 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your gimme is delayed due to budget cuts. Please try again in " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 12 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your gimme is delayed due to unforseen circumstances. Please try again in " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 13 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Gimme is recharging. Please try again in " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 14 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Sorry gimme is experiencing technical difficulties. Please try again in " .. tmp.gimmeCooldown .. " seconds.[-]") end
						if r == 15 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Try gimme in " .. tmp.gimmeCooldown .. " seconds. Everything is fine here *CRASH!* We're all fine. How are you?[-]") end

						botman.faultyChat = false
						return true
					end
				end

				if locations[players[chatvars.playerid].inLocation] then
					if not locations[players[chatvars.playerid].inLocation].pvp then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Gimme cannot be played within a location unless it is pvp enabled.[-]")

						botman.faultyChat = false
						return true
					end
				end

				if (players[chatvars.playerid].atHome or players[chatvars.playerid].inABase) and chatvars.settings.gimmeZombies then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Gimme cannot be played inside a player base. Go play with Zombie Steve outside.[-]")

					botman.faultyChat = false
					return true
				end

				if chatvars.number and chatvars.accessLevel == 0 then
					-- this is meant for testing gimme only.
					gimme(chatvars.playerid, chatvars.number)
				else
					gimme(chatvars.playerid)
					players[chatvars.playerid].gimmeCooldown = os.time() + chatvars.settings.gimmeRaincheck
					if botman.dbConnected then conn:execute("UPDATE players SET gimmeCooldown = " .. os.time() + chatvars.settings.gimmeRaincheck .. " WHERE steam = '" .. chatvars.playerid .. "'") end
				end
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command is disabled.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PlayGimmeHell()
		local k, v, r, level, loc

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}gimmezombies or {#}gimmehell or {#}gimmeinsane or {#}gimmedeath"
			help[2] = "Play a special gimme game in a location called arena.  You and anyone with you will get 4 waves of zombies to fight.\n"
			--help[2] = "Cannot be played during bloodmoon or in the 2 game hours prior.\n"   -- TODO code this
			help[2] = help[2] .. "Select one of 4 games of increasing difficulty (more zombies, faster spawns, harder zombies).\n"
			help[2] = help[2] .. "Admins or arena players can cancel the game with {#}reset gimmearena\n"
			help[2] = help[2] .. "Zombies are randomly distributed between arena players.  Any players more than 5 blocks above the arena floor (or under it) are specators and don't get zombies.\n"
			help[2] = help[2] .. "Some useless crap is supplied at the start."

			tmp.command = help[1]
			tmp.keywords = "gimme,gimmie"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "gimmezombies" or chatvars.words[1] == "gimmehell" or chatvars.words[1] == "gimmeinsane" or chatvars.words[1] == "gimmedeath") and chatvars.words[2] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			botman.gimmeDifficulty = 1
			level = igplayers[chatvars.playerid].level

			if chatvars.words[1] == "gimmehell" then
				botman.gimmeDifficulty = 2
			end

			if chatvars.words[1] == "gimmeinsane" then
				botman.gimmeDifficulty = 3
			end

			if chatvars.words[1] == "gimmedeath" then
				botman.gimmeDifficulty = 4
			end

			if tablelength(gimmeZombies) == 0 or gimmeZombies == nil then
				sendCommand("se")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Oopsie! Somebody fed the zombies. Wait a few seconds while we swap them out with fresh starving ones.[-]")
				botman.faultyChat = false
				return true
			end

			if not maxBossZombies then
				gimmeZombieBosses = {}
				maxBossZombies = 0

				for k,v in pairs(gimmeZombies) do
					if v.bossZombie then
						maxBossZombies = maxBossZombies + 1
						gimmeZombieBosses[maxBossZombies] = {}
						gimmeZombieBosses[maxBossZombies].zombie = v.zombie
						gimmeZombieBosses[maxBossZombies].entityID = k
					end
				end
			end

			-- abort if not in arena
			loc = LookupLocation("arena")

			if loc ~= nil then
				dist = distancexyz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].yPos, igplayers[chatvars.playerid].zPos, locations[loc].x, locations[loc].y, locations[loc].z)

				if (tonumber(dist) > tonumber(locations[loc].size)) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command can only be used in the arena[-]")
					botman.faultyChat = false
					return true
				end
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command can only be used in the arena[-]")
				botman.faultyChat = false
				return true
			end

			if (botman.gimmeHell == 0) then
				botman.gimmeHell = 1
				setupArenaPlayers(chatvars.playerid)

				if (botman.arenaCount == 0) then
					botman.gimmeHell = 0
					return true
				end

				if botman.gimmeDifficulty == 1 then
					announceGimmeHell(1, 15)
					queueGimmeHell(1, level)
					announceGimmeHell(2, 60)
					queueGimmeHell(2, level)
					announceGimmeHell(3, 120)
					queueGimmeHell(3, level)
					announceGimmeHell(4, 180)
					queueGimmeHell(4, level)
				end

				if botman.gimmeDifficulty == 2 then
					announceGimmeHell(1, 15)
					queueGimmeHell(1, level)
					announceGimmeHell(2, 50)
					queueGimmeHell(2, level)
					announceGimmeHell(3, 100)
					queueGimmeHell(3, level)
					announceGimmeHell(4, 150)
					queueGimmeHell(4, level)
					queueGimmeHell(4, level)
				end

				if botman.gimmeDifficulty == 3 then
					announceGimmeHell(1, 5)
					queueGimmeHell(1, level)
					announceGimmeHell(2, 40)
					queueGimmeHell(2, level)
					announceGimmeHell(3, 80)
					queueGimmeHell(3, level)
					announceGimmeHell(4, 120)
					queueGimmeHell(4, level)
					queueGimmeHell(4, level)
					queueGimmeHell(4, level)
				end

				if botman.gimmeDifficulty == 4 then
					announceGimmeHell(1, 5)
					queueGimmeHell(1, level)
					queueGimmeHell(1, level)
					announceGimmeHell(2, 30)
					queueGimmeHell(2, level)
					queueGimmeHell(2, level)
					announceGimmeHell(3, 60)
					queueGimmeHell(3, level)
					queueGimmeHell(3, level)
					announceGimmeHell(4, 90)
					queueGimmeHell(4, level)
					queueGimmeHell(4, level)
					queueGimmeHell(4, level)
					queueGimmeHell(4, level)
				end

				-- add the ending
				r = randSQL(5)
				if r == 1 then cmd = "Congratulations!  You have survived to the end of the fight!  Er.. once you've finished mopping up." end
				if r == 2 then cmd = "GG!!  The arena game has ended." end
				if r == 3 then cmd = "Curses!  You survived my arena OF DOOM!  It's so hard to find good help these days." end
				if r == 4 then cmd = "You survived!  What a mess.  Now clean it up!" end
				if r == 5 then cmd = "GAME OVER.  Press F to pay respects." end
				connSQL:execute("INSERT into playerQueue (command, arena, steam) VALUES ('" .. connMEM:escape(cmd) .. "', 1, '0')")
				connSQL:execute("INSERT into playerQueue (command, arena, steam) VALUES ('reset', 1, '0')")
				botman.playerQueueEmpty = false

				faultChat = false
				return true
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Wait until the current Gimme Arena game is concluded. You can reset it with " .. server.commandPrefix .. "reset gimmearena[-]")
				botman.faultyChat = false
				return true
			end
		end
	end


	local function cmd_Poke()
		-- Annoy the bot
		if string.find(chatvars.words[1], "poke") and chatvars.words[2] ==  nil then
			r = randSQL(45)
			if r == 1 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Hey![-]") end
			if r == 3 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Stop that![-]") end
			if r == 5 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Ouch![-]") end
			if r == 7 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]GRR GRR GRR[-]") end
			if r == 9 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Pest[-]") end
			if r == 11 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]:O[-]") end
			if r == 13 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]D:[-]") end
			if r == 17 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Really?[-]") end
			if r == 19 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]GROAN![-]") end
			if r == 21 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Ow![-]") end
			if r == 23 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Quit that![-]") end
			if r == 25 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]O.x[-]") end
			if r == 27 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]>:O[-]") end
			if r == 29 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]>.<[-]") end
			if r == 31 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]*sigh*[-]") end
			if r == 33 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]FML[-]") end
			if r == 35 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You![-]") end
			if r == 37 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Abuse![-]") end
			if r == 39 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]EEK![-]") end
			if r == 41 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Oi![-]") end
			if r == 45 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]:P[-]") end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_QuitWithMessage()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}quit {message}"
			help[2] = "Get kicked out of the server and have the bot say your message in game chat."

			tmp.command = help[1]
			tmp.keywords = "quit,message"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "quit") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "quit") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			msg = stripQuotes(string.sub(line, string.find(line, "quit") + 5))

			if msg ~= nil then
				message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " quit with this parting shot.. " .. msg .."[-]")
			end

			kick(chatvars.playerid, "That'll learn em! xD")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RageQuit()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}quit\n"
			help[1] = help[1] .. " {#}ragequit"
			help[2] = "Get kicked out of the server with a random message."

			tmp.command = help[1]
			tmp.keywords = "quit,rage"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "quit") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "quit" or chatvars.words[1] == "ragequit" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if string.find(chatvars.words[1], "rage") then
				kick(chatvars.playerid, "RAAAAGE! xD")
			else
				r = randSQL(4)
				if r == 1 then kick(chatvars.playerid, "You'll be back :P") end
				if r == 2 then kick(chatvars.playerid, "Quitter! :V") end
				if r == 3 then kick(chatvars.playerid, "Nice quit    *removes glasses*    YEEEEEEEEAH!") end
				if r == 4 then kick(chatvars.playerid, "You'll never quit xD") end
			end

			r = randSQL(10)

			if r == 1 then
				message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " has left the building.[-]")
			end

			if r == 2 then
				message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " has left *SLAM!*[-]")
			end

			if r == 3 then
				message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " " .. chatvars.words[1] .. "![-]")
			end

			if r == 4 then
				message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " quit like a BOSS![-]")
			end

			if r == 5 then
				message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " tripped on the power cord.[-]")
			end

			if r == 6 then
				message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " has stepped out to flip tables.[-]")
			end

			if r == 7 then
				message("say [" .. server.chatColour .. "][MISSING] " .. players[chatvars.playerid].name .. " last seen ragequitting.[-]")
			end

			if r == 8 then
				message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " chose the nuclear option.[-]")
			end

			if r == 9 then
				message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " +1 XP Ragequitter.[-]")
			end

			if r == 10 then
				message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " pressed the Any key.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetGimme()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme reset"
			help[2] = "Reset gimme counters for everyone so they can play gimme again.  The bot does this every " .. server.gimmeResetTime .. " minutes automatically."

			tmp.command = help[1]
			tmp.keywords = "gimme,reset,gimmie"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "gimme" and chatvars.words[2] == "reset" and chatvars.words[3] == nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			gimmeReset()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetGimmeHell()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reset arena"
			help[2] = "Cancel an arena game in progress."

			tmp.command = help[1]
			tmp.keywords = "fix,gimme,gimmie,arena,reset"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "reset" and (chatvars.words[2] == "gimmehell" or chatvars.words[2] == "gimmearena" or chatvars.words[2] == "arena") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername == "Server") then
				resetGimmeArena()
				irc_chat(server.ircMain, "The Gimme Arena game has been reset.")

				botman.faultyChat = false
				return true
			end

			if arenaPlayers[chatvars.playerid] or (chatvars.isAdminHidden) then
				resetGimmeArena()

				botman.faultyChat = false
				return true
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Only an arena participant or an admin can stop an active game.[-]")
				else
					irc_chat(chatvars.ircAlias, "Only an arena participant or an admin can stop an active game.")
				end

				botman.faultyChat = false
				return true
			end
		end
	end


	local function cmd_Santa()
		local cmd

		-- HO
		-- HO HO
		-- HO HO HO

		-- A special command for Ho's
		if chatvars.words[1] == "santa" and chatvars.words[2] == nil and specialDay == "christmas" then
			if (not players[chatvars.playerid].santa) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]HO HO HO  Merry Christmas![-]")
				if not server.botman then
					sendCommand("give " .. chatvars.userID .. " apparelShades 1")
					sendCommand("give " .. chatvars.userID .. " drinkJarBeer 1")
					sendCommand("give " .. chatvars.userID .. " resourceCoal 1")
					sendCommand("give " .. chatvars.userID .. " thrownAmmoPipeBomb 1")
					sendCommand("give " .. chatvars.userID .. " medicalSplint 1")
					sendCommand("give " .. chatvars.userID .. " armorSantaHat 1")
					sendCommand("give " .. chatvars.userID .. " woodChair1 1")
				end

				if server.botman then
					sendCommand("bm-give " .. chatvars.userID .. " apparelShades 1")
					sendCommand("bm-give " .. chatvars.userID .. " drinkJarBeer 1")
					sendCommand("bm-give " .. chatvars.userID .. " resourceCoal 1")
					sendCommand("bm-give " .. chatvars.userID .. " thrownAmmoPipeBomb 1")
					sendCommand("bm-give " .. chatvars.userID .. " medicalSplint 1")
					sendCommand("bm-give " .. chatvars.userID .. " armorSantaHat 1")
					sendCommand("bm-give " .. chatvars.userID .. " woodChair1 1")
				end

				r = randSQL(2)
				if r == 1 then
					cmd = "give " .. chatvars.userID .. " medicalFirstAidBandage 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " medicalFirstAidBandage 1"
					end

					sendCommand(cmd)
				end

				if r == 2 then
					cmd = "give " .. chatvars.userID .. " medicalFirstAidKit 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " medicalFirstAidKit 1"
					end

					sendCommand(cmd)
				end

				players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) + 200

				r = randSQL(26)
				if r == 1 then
					cmd = "give " .. chatvars.userID .. " foodCanBeef 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanBeef 1"
					end

					sendCommand(cmd)
				end

				if r == 2 then
					cmd = "give " .. chatvars.userID .. " drinkJarBoiledWater 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " drinkJarBoiledWater 1"
					end

					sendCommand(cmd)
				end

				if r == 3 then
					cmd = "give " .. chatvars.userID .. " foodCanCatfood 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanCatfood 1"
					end

					sendCommand(cmd)
				end

				if r == 4 then
					cmd = "give " .. chatvars.userID .. " foodCanChicken 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanChicken 1"
					end

					sendCommand(cmd)
				end

				if r == 5 then
					cmd = "give " .. chatvars.userID .. " foodCanChilli 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanChilli 1"
					end

					sendCommand(cmd)
				end

				if r == 6 then
					cmd = "give " .. chatvars.userID .. " candle 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " candle 1"
					end

					sendCommand(cmd)
				end

				if r == 7 then
					cmd = "give " .. chatvars.userID .. " resourceCandleStick 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " resourceCandleStick 1"
					end

					sendCommand(cmd)
				end

				if r == 8 then
					cmd = "give " .. chatvars.userID .. " candleTableLightPlayer 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " candleTableLightPlayer 1"
					end

					sendCommand(cmd)
				end

				if r == 9 then
					cmd = "give " .. chatvars.userID .. " candleWallLightPlayer 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " candleWallLightPlayer 1"
					end

					sendCommand(cmd)
				end

				if r == 10 then
					cmd = "give " .. chatvars.userID .. " foodCanDogfood 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanDogfood 1"
					end

					sendCommand(cmd)
				end

				if r == 11 then
					cmd = "give " .. chatvars.userID .. " resourceCandyTin 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " resourceCandyTin 1"
					end

					sendCommand(cmd)
				end

				if r == 12 then
					cmd = "give " .. chatvars.userID .. " drinkCanEmpty 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " drinkCanEmpty 1"
					end

					sendCommand(cmd)
				end

				if r == 13 then
					cmd = "give " .. chatvars.userID .. " foodCanSham 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanSham 1"
					end

					sendCommand(cmd)
				end

				if r == 14 then
					cmd = "give " .. chatvars.userID .. " foodCanLamb 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanLamb 1"
					end

					sendCommand(cmd)
				end

				if r == 15 then
					cmd = "give " .. chatvars.userID .. " foodCanMiso 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanMiso 1"
					end

					sendCommand(cmd)
				end

				if r == 16 then
					cmd = "give " .. chatvars.userID .. " drinkJarRiverWater 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " drinkJarRiverWater 1"
					end

					sendCommand(cmd)
				end

				if r == 17 then
					cmd = "give " .. chatvars.userID .. " foodCanPasta 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanPasta 1"
					end

					sendCommand(cmd)
				end

				if r == 18 then
					cmd = "give " .. chatvars.userID .. " foodCanPears 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanPears 1"
					end

					sendCommand(cmd)
				end

				if r == 19 then
					cmd = "give " .. chatvars.userID .. " foodCanPeas 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanPeas 1"
					end

					sendCommand(cmd)
				end

				if r == 20 then
					cmd = "give " .. chatvars.userID .. " foodCanSalmon 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanSalmon 1"
					end

					sendCommand(cmd)
				end

				if r == 21 then
					cmd = "give " .. chatvars.userID .. " foodCanSoup 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanSoup 1"
					end

					sendCommand(cmd)
				end

				if r == 22 then
					cmd = "give " .. chatvars.userID .. " foodCanStock 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanStock 1"
					end

					sendCommand(cmd)
				end

				if r == 23 then
					cmd = "give " .. chatvars.userID .. " foodCanTuna 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " foodCanTuna 1"
					end

					sendCommand(cmd)
				end

				if r == 24 then
					cmd = "give " .. chatvars.userID .. " ammoGasCan 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " ammoGasCan 1"
					end

					sendCommand(cmd)
				end

				if r == 25 then
					cmd = "give " .. chatvars.userID .. " ammoGasCanSchematic 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " ammoGasCanSchematic 1"
					end

					sendCommand(cmd)
				end

				if r == 26 then
					cmd = "give " .. chatvars.userID .. " mineCandyTin 1"

					if server.botman then
						cmd = "bm-give " .. chatvars.userID .. " mineCandyTin 1"
					end

					sendCommand(cmd)
				end

				players[chatvars.playerid].santa = "hohoho"
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]HO HO You have already received your stocking stuffer HO.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetGimmeCooldown()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme raincheck {seconds}"
			help[2] = "Set a time delay between gimmes.  The default is 0 seconds."

			tmp.command = help[1]
			tmp.keywords = "gimme,cool,time,delay,gimmie"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "gimme" and string.find(chatvars.command, " rain") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Missing number for seconds between gimmes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing number for  seconds between gimmes.")
				end

				botman.faultyChat = false
				return true
			else
				chatvars.number = math.abs(chatvars.number)
			end

			server.gimmeRaincheck = chatvars.number
			if botman.dbConnected then conn:execute("UPDATE server SET gimmeRaincheck = " .. chatvars.number) end

			if chatvars.number == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Gimmes can be played until there are none left.[-]")
				else
					irc_chat(chatvars.ircAlias, "Gimmes can be played until there are none left.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players must wait " .. chatvars.number .. " seconds between gimmes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players must wait " .. chatvars.number .. " seconds between gimmes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetGimmeResetTimer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme reset time {number} (In minutes. Default is 120)"
			help[2] = "Reset everyone's gimme counter after (n) minutes."

			tmp.command = help[1]
			tmp.keywords = "gimme,enable,disable,on,off,gimmie"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "gimme" and chatvars.words[2] == "reset" and chatvars.words[3] == "time") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]A number is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "A number is required.")
				end

				botman.faultyChat = false
				return true
			else
				chatvars.number = math.abs(chatvars.number)

				if chatvars.number == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Set a number higher than zero.[-]")
					else
						irc_chat(chatvars.ircAlias, "Set a number higher than zero.")
					end

					botman.faultyChat = false
					return true
				end

				server.gimmeResetTime = chatvars.number
				if botman.dbConnected then
					conn:execute("UPDATE server SET gimmeResetTime = " .. chatvars.number)
					conn:execute("UPDATE timedEvents SET delayMinutes = " .. chatvars.number .. ", nextTime = NOW() + INTERVAL " .. chatvars.number .. " MINUTE WHERE timer = 'gimmeReset'")
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Gimme will reset every " .. chatvars.number .. " minutes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Gimme will reset every " .. chatvars.number .. " minutes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxGimmies()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme max gimmies {number of gimmies}"
			help[2] = "Set the maximum number of gimmie games that can be played between gimmie resets."

			tmp.command = help[1]
			tmp.keywords = "gimme,max,gimmie"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "gimme" or chatvars.words[1] == "set") and chatvars.words[2] == "max" and chatvars.words[3] == "gimmies" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Missing number for maximum number of gimmes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing number for maximum number of gimmes.")
				end

				botman.faultyChat = false
				return true
			else
				chatvars.number = math.abs(chatvars.number)
			end

			server.maxGimmies = chatvars.number
			if botman.dbConnected then conn:execute("UPDATE server SET maxGimmies = " .. chatvars.number) end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Gimme can be played " .. server.maxGimmies .. " between gimme resets.[-]")
			else
				irc_chat(chatvars.ircAlias, "Gimme can be played " .. server.maxGimmies .. " between gimme resets.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Suicide()
		-- Suicide is painless
		-- It has a cooldown to stop players M.A.S.Hing it
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}suicide"
			help[2] = "Don't do it! :O"

			tmp.command = help[1]
			tmp.keywords = "gimme,suicide,death,kill,die,gimmie"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "suicide") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if not chatvars.settings.allowSuicide then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not allowed to commit suicide.[-]")

				botman.faultyChat = false
				return true
			end

			-- allow if sufficient zennies
			if tonumber(chatvars.settings.suicideCost) > 0 and (not chatvars.isAdmin) then
				if tonumber(players[chatvars.playerid].cash) < tonumber(chatvars.settings.suicideCost) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. ".  You require " .. chatvars.settings.suicideCost .. ".  Kill some zombies, gamble, trade or beg to earn more.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if players[chatvars.playerid].prisoner or players[chatvars.playerid].timeout == true or players[chatvars.playerid].botTimeout == true then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]BANG![-]")
			else
				if players[chatvars.playerid].lastSuicide ~= nil then
					if os.time() - players[chatvars.playerid].lastSuicide < 180 then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]>CLICK!<  Darn your gun jammed.  Try again in a few minutes.[-]")

						botman.faultyChat = false
						return true
					end
				end

				if not chatvars.isAdmin then
					players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - chatvars.settings.suicideCost
				end

				sendCommand("kill " .. chatvars.userID)
				players[chatvars.playerid].lastSuicide = os.time()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleDogeMode()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}doge mode or {#}doge on/off"
			help[2] = "But what does it do!? Play and find out xD"

			tmp.command = help[1]
			tmp.keywords = "doge,mode"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "doge") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		-- But what does it do!? Play and find out xD
		if chatvars.words[1] == "doge" and (chatvars.words[2] == "on" or chatvars.words[2] == "off" or chatvars.words[2] == "mode") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == "off" then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Doge mode de-activated.[-]")
				igplayers[chatvars.playerid].doge = false
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Doge mode activated.[-]")
				igplayers[chatvars.playerid].doge = true
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleGimmeGame()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme on (or off)"
			help[2] = "Enable/disable the gimme game."

			tmp.command = help[1]
			tmp.keywords = "gimme,enable,disable,on,off,gimmie"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "gimme" and (chatvars.words[2] == "on" or chatvars.words[2] == "off") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == "off" then
				message("say [" .. server.chatColour .. "]Gimme has been disabled[-]")
				server.allowGimme = false

				if botman.dbConnected then conn:execute("UPDATE server SET allowGimme = 0") end
			else
				message("say [" .. server.chatColour .. "]Gimme has been enabled[-]")
				server.allowGimme = true

				if botman.dbConnected then conn:execute("UPDATE server SET allowGimme = 1") end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleGimmeZombies()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme zombies\n"
			help[1] = help[1] .. " {#}gimme no zombies"
			help[2] = "Enable or disable zombies as gimme prizes."

			tmp.command = help[1]
			tmp.keywords = "gimme,enable,disable,on,off,gimmie"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "gimme" and (chatvars.words[2] == "zombies" or chatvars.words[2] == "no") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == "zombies" then
				message("say [" .. server.chatColour .. "]Gimme prizes proudly sponsored by Zombie Surplus![-]")
				server.gimmeZombies = true

				if botman.dbConnected then conn:execute("UPDATE server SET gimmeZombies = 1") end
			else
				message("say [" .. server.chatColour .. "]Gimme prizes now 100% certified zombie free! (May contain traces of nuts)[-]")
				server.gimmeZombies = false

				if botman.dbConnected then conn:execute("UPDATE server SET gimmeZombies = 0") end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleShowHideGimmeMessages()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme gimme\n"
			help[1] = help[1] .. "Or {#}gimme peace"
			help[2] = "Make gimme messages appear in public chat with {#}gimme gimme or as private messages with {#}gimme peace (with some exceptions)."

			tmp.command = help[1]
			tmp.keywords = "gimme,reset,gimmie"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "gimm") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if chatvars.words[1] == "gimme" and (chatvars.words[2] == "gimme" or chatvars.words[2] == "peace") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == "gimme" then
				message("say [" .. server.chatColour .. "]Gimme messages are now public[-]")
				server.gimmePeace = false

				if botman.dbConnected then conn:execute("UPDATE server SET gimmePeace = 0") end
			else
				message("say [" .. server.chatColour .. "]Gimme has been silenced[-]")
				server.gimmePeace = true

				if botman.dbConnected then conn:execute("UPDATE server SET gimmePeace = 1") end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ViewPlayerBounty()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}bounty {optional player name}\n"
			help[1] = help[1] .. "Or {#}view bounty {optional player name}\n"
			help[1] = help[1] .. "Or {#}view bounties"
			help[2] = "See the player kills and current bounty on a players head or on all players currently on the server."

			tmp.command = help[1]
			tmp.keywords = "pvp,bounty,player,view"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "bounty") or string.find(chatvars.command, "pvp") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "bounty" or chatvars.words[1] == "view" or chatvars.words[1] == "list") and (chatvars.words[2] == "bounty" or chatvars.words[2] == "bounties") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			local tmp = {}

			tmp.bountyFound = false

			if (chatvars.playername ~= "Server") then
				tmp.id = chatvars.playerid
			else
				tmp.id = chatvars.ircid
			end

			if (chatvars.words[2] ~= "bounties") then
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, " bounty ") + 8)

				if tmp.pname ~= "" and tmp.pnam ~= nil then
					tmp.pname = string.trim(tmp.pname)
					tmp.id = LookupPlayer(tmp.pname)
				end

				if tmp.id == "0" then
					tmp.id = LookupArchivedPlayer(tmp.pname)

					if not (tmp.id == "0") then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. tmp.pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. tmp.pname)
						end
					end

					botman.faultyChat = false
					return true
				end

				if tmp.id == chatvars.playerid or tmp.id == chatvars.ircid then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have " .. players[tmp.id].playerKills .. " kills and a bounty of " .. players[tmp.id].pvpBounty .. " " .. server.moneyPlural .. " on your head.[-]")
					else
						irc_chat(chatvars.ircAlias, "You have " .. players[tmp.id].playerKills .. " kills and a bounty of " .. players[tmp.id].pvpBounty .. " " .. server.moneyPlural .. " on your head.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.id].name .. " has " .. players[tmp.id].playerKills .. " kills. Kill them for " .. players[tmp.id].pvpBounty .. " " .. server.moneyPlural .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, players[tmp.id].name .. " has " .. players[tmp.id].playerKills .. " kills. Kill them for " .. players[tmp.id].pvpBounty .. " " .. server.moneyPlural .. ".")
					end
				end
			else
				if tonumber(botman.playersOnline) > 0 then
					for k, v in pairs(igplayers) do
						if tonumber(players[k].pvpBounty) > 0 then
							tmp.bountyFound = true

							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[k].name .. " has " .. players[k].playerKills .. " kills and a bounty of " .. players[k].pvpBounty .. "[-]")
							else
								irc_chat(chatvars.ircAlias, players[k].name .. " has " .. players[k].playerKills .. " kills and a bounty of " .. players[k].pvpBounty)
							end
						end
					end

					if not tmp.bountyFound then
						if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player on the server right now has a bounty on their head.[-]")
							else
								irc_chat(chatvars.ircAlias, "No player on the server right now has a bounty on their head.")
						end
					end
				else
					if (chatvars.playername == "Server") then
						for k, v in pairs(players) do
							if tonumber(v.pvpBounty) > 0 then
								tmp.bountyFound = true

								irc_chat(chatvars.ircAlias, v.name .. " has " .. v.playerKills .. " kills and a bounty of " .. v.pvpBounty)
							end
						end

						if not tmp.bountyFound then
							irc_chat(chatvars.ircAlias, "No player has a bounty on their head.")
						end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		if debug then dbug("Registering help - fun commands") end

		tmp.topicDescription = "Fun commands are miscellaneous commands that include gimme, bounties and a few silly commands."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Fun Commands:")
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, tmp.topicDescription)
			irc_chat(chatvars.ircAlias, ".")
		end

		cursor,errorString = connSQL:execute("SELECT count(*) FROM helpTopics WHERE topic = '" .. tmp.topic .. "'")
		row = cursor:fetch({}, "a")
		rows = row["count(*)"]

		if rows == 0 then
			connSQL:execute("INSERT INTO helpTopics (topic, description) VALUES ('" .. tmp.topic .. "', '" .. connMEM:escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false, ""
	end

if debug then dbug("debug fun") end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "fun" then
				botman.faultyChat = false
				return true, ""
			end
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and chatvars.words[1] ~= "help" and not botman.registerHelp then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Fun Commands:")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "fun")
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ViewPlayerBounty()

	if result then
		if debug then dbug("debug cmd_ViewPlayerBounty triggered") end
		return result, "cmd_ViewPlayerBounty"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleShowHideGimmeMessages()

	if result then
		if debug then dbug("debug cmd_ToggleShowHideGimmeMessages triggered") end
		return result, "cmd_ToggleShowHideGimmeMessages"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_FixGimme()

	if result then
		if debug then dbug("debug cmd_FixGimme triggered") end
		return result, "cmd_FixGimme"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetGimmeHell()

	if result then
		if debug then dbug("debug cmd_ResetGimmeHell triggered") end
		return result, "cmd_ResetGimmeHell"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetGimmeCooldown()

	if result then
		if debug then dbug("debug cmd_SetGimmeCooldown triggered") end
		return result, "cmd_SetGimmeCooldown"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetGimme()

	if result then
		if debug then dbug("debug cmd_ResetGimme triggered") end
		return result, "cmd_ResetGimme"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleGimmeGame()

	if result then
		if debug then dbug("debug cmd_ToggleGimmeGame triggered") end
		return result, "cmd_ToggleGimmeGame"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleGimmeZombies()

	if result then
		if debug then dbug("debug cmd_ToggleGimmeZombies triggered") end
		return result, "cmd_ToggleGimmeZombies"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetGimmeResetTimer()

	if result then
		if debug then dbug("debug cmd_SetGimmeResetTimer triggered") end
		return result, "cmd_SetGimmeResetTimer"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == "0" and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false, ""
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_Beer()

	if result then
		if debug then dbug("debug cmd_Beer triggered") end
		return result, "cmd_Beer"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxGimmies()

	if result then
		if debug then dbug("debug cmd_SetMaxGimmies triggered") end
		return result, "cmd_SetMaxGimmies"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_Suicide()

	if result then
		if debug then dbug("debug cmd_Suicide triggered") end
		return result, "cmd_Suicide"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_PlaceBounty()

	if result then
		if debug then dbug("debug cmd_PlaceBounty triggered") end
		return result, "cmd_PlaceBounty"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_Santa()

	if result then
		if debug then dbug("debug cmd_Santa triggered") end
		return result, "cmd_Santa"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_PlayGimme()

	if result then
		if debug then dbug("debug cmd_PlayGimme triggered") end
		return result, "cmd_PlayGimme"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if not server.beQuietBot then
		result = cmd_Poke()

		if result then
			if debug then dbug("debug cmd_Poke triggered") end
			return result, "cmd_Poke"
		end
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_RageQuit()

	if result then
		if debug then dbug("debug cmd_RageQuit triggered") end
		return result, "cmd_RageQuit"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_QuitWithMessage()

	if result then
		if debug then dbug("debug cmd_QuitWithMessage triggered") end
		return result, "cmd_QuitWithMessage"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_PlayGimmeHell()

	if result then
		if debug then dbug("debug cmd_PlayGimmeHell triggered") end
		return result, "cmd_PlayGimmeHell"
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleDogeMode()

	if result then
		if debug then dbug("debug cmd_ToggleDogeMode triggered") end
		return result, "cmd_ToggleDogeMode"
	end

	if botman.registerHelp then
		if debug then dbug("Fun commands help registered") end
	end

	if debug then dbug("debug fun end") end

	-- can't touch dis
	if true then
		return result, ""
	end
end
