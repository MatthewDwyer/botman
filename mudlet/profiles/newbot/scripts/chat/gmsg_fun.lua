--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- a17 items done

local result, debug, help, tmp
local shortHelp = false
local skipHelp = false

function gmsg_fun()
	calledFunction = "gmsg_fun"
	result = false
	tmp = {}

	debug = false -- should be false unless testing
	--server.enableWindowMessages = true

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## Fun command functions ##################

	local function cmd_Beer()
		local cmd

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}beer"
			help[2] = "While in any location with beer in its name, players can grab a beer (or a lot)."

			tmp.command = help[1]
			tmp.keywords = "gimm,beer"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		-- There's a beer command! :D
		if (chatvars.words[1] == "waiter" or chatvars.words[1] == "beer" and chatvars.words[2] == nil) then
			if string.find(inLocation(chatvars.intX, chatvars.intZ), "beer") then
				cmd = "give " .. chatvars.playerid .. " drinkJarBeer 1"

				if server.stompy then
					cmd = "bc-give " .. chatvars.playerid .. " drinkJarBeer /c=1 /silent"
				end

				if server.botman then
					cmd = "bm-give " .. chatvars.playerid .. " drinkJarBeer 1"
				end

				sendCommand(cmd)
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Enjoy your beer![-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FixGimme()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}fix gimme"
			help[2] = "Force the bot to rescan the list of zombies and animals."

			tmp.command = help[1]
			tmp.keywords = "fix,gimm,init"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "fix" and chatvars.words[2] == "gimme") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The zombies have been reloaded.[-]")
			else
				irc_chat(chatvars.ircAlias, "The zombies have been reloaded.")
			end

			--gimmeZombies = {}
			--if botman.dbConnected then conn:execute("TRUNCATE gimmeZombies") end
			sendCommand("se")

			irc_chat(server.ircMain, "Validating shop and gimme prize items.")
			collectSpawnableItemsList()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PlaceBounty()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}place bounty {player name} {cash}"
			help[2] = "Place a bounty on a player's head. The money is removed from your cash."

			tmp.command = help[1]
			tmp.keywords = "gimm,pvp,bounty"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		-- Help Wanted - dead
		if (chatvars.words[1] == "place" and chatvars.words[2] == "bounty") then
			pname = chatvars.words[3]
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You now have " .. string.format("%d", players[chatvars.playerid].cash) .. " " .. server.moneyPlural .. ".[-]")

				-- update the player's bounty
				if botman.dbConnected then conn:execute("UPDATE players SET pvpBounty = " .. players[id].pvpBounty .. " WHERE steam = " .. id) end

				-- reduce the cash of the player who placed the bounty
				if botman.dbConnected then conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = " .. chatvars.playerid) end

				if oldBounty > 0 then
					message("say [" .. server.chatColour .. "]" .. players[id].name .. "'s life is now worth " .. players[id].pvpBounty .. ".[-]")
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. " to place that bounty.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PlayGimme()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme"
			help[2] = "Play one gimme - win a prize!\n"
			help[2] = help[2] .. "Gimme cannot be played within a location unless it is pvp enabled.\n"
			help[2] = help[2] .. "Gimme cannot be played inside a player base.\n"
			help[2] = help[2] .. "Prize may contain nuts. If a rash develops, see your doctor. Keep away from small children.  The bag is not a hat."

			tmp.command = help[1]
			tmp.keywords = "gimm"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "gimmie" or chatvars.words[1] == "gimme") and (chatvars.words[2] == nil or chatvars.number ~= nil) then
			if (server.allowGimme) then
				if tablelength(gimmeZombies) == 0 or gimmeZombies == nil then
					sendCommand("se")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Oopsie! Somebody fed the zombies. Wait a few seconds while we swap them out with fresh starving ones.[-]")
					botman.faultyChat = false
					return true
				end

				if tonumber(server.gimmeRaincheck) > 0 then
					if (players[chatvars.playerid].gimmeCooldown - os.time() > 0) then
						r = randSQL(5)
						if r == 1 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]WOAH WOAH WOAH there fella. Don't do gimme so fast![-]") end
						if r == 2 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Ya cannay gimme wi that thing.  Git a real gun Jimmy.[-]") end
						if r == 3 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Hold it! You need to wait a bit before you can gimme some more.[-]") end
						if r == 4 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Don't eat all your gimmes at once. Where are your manners?[-]") end
						if r == 5 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Gimme gimme gimme.[-]") end

						r = randSQL(5)
						if r == 1 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Wait till you see the reds of their eyes.[-]") end
						if r == 2 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Ya gotta sneak up on them real careful like.[-]") end
						if r == 3 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You'll reach your daily bag limit too soon.[-]") end
						if r == 4 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Gimme that![-]") end
						r1 = randSQL(10)
						r2 = randSQL(10)
						if r == 5 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Article " .. r1 .. ", section " .. r2 .. " states, You must wait " .. server.gimmeRaincheck .. " seconds between gimmes.[-]") end

						botman.faultyChat = false
						return true
					end
				end

				if locations[players[chatvars.playerid].inLocation] then
					if not locations[players[chatvars.playerid].inLocation].pvp then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Gimme cannot be played within a location unless it is pvp enabled.[-]")

						botman.faultyChat = false
						return true
					end
				end

				if (players[chatvars.playerid].atHome or players[chatvars.playerid].inABase) and server.gimmeZombies then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Gimme cannot be played inside a player base. Go play with Zombie Steve outside.[-]")

					botman.faultyChat = false
					return true
				end

				if chatvars.number and chatvars.accessLevel == 0 then
					-- this is meant for testing gimme only.
					gimme(chatvars.playerid, chatvars.number)
				else
					gimme(chatvars.playerid)
					players[chatvars.playerid].gimmeCooldown = os.time() + server.gimmeRaincheck
					if botman.dbConnected then conn:execute("UPDATE players SET gimmeCooldown = " .. os.time() + server.gimmeRaincheck .. " WHERE steam = " .. chatvars.playerid) end
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry, an admin has disabled gimme =([-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PlayGimmeHell()
		local k, v, r, level, loc

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}gimmezombies or {#}gimmehell or {#}gimmeinsane or {#}gimmedeath"
			help[2] = "Play a special gimme game in a location called arena.  You and anyone with you will get 4 waves of zombies to fight.\n"
			--help[2] = "Cannot be played during bloodmoon or in the 2 game hours prior.\n"   -- TODO code this
			help[2] = help[2] .. "Select one of 4 games of increasing difficulty (more zombies, faster spawns, harder zombies).\n"
			help[2] = help[2] .. "Admins or arena players can cancel the game with {#}reset gimmearena\n"
			help[2] = help[2] .. "Zombies are randomly distributed between arena players.  Any players more than 5 blocks above the arena floor (or under it) are specators and don't get zombies.\n"
			help[2] = help[2] .. "Some useless crap is supplied at the start."

			tmp.command = help[1]
			tmp.keywords = "gimm"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "gimmezombies" or chatvars.words[1] == "gimmehell" or chatvars.words[1] == "gimmeinsane" or chatvars.words[1] == "gimmedeath") and chatvars.words[2] == nil then
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Oopsie! Somebody fed the zombies. Wait a few seconds while we swap them out with fresh starving ones.[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command can only be used in the arena[-]")
					botman.faultyChat = false
					return true
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command can only be used in the arena[-]")
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

				conn:execute("INSERT into playerQueue (command, arena, steam) VALUES ('" .. escape(cmd) .. "', true, 0)")
				conn:execute("INSERT into playerQueue (command, arena, steam) VALUES ('reset', true, 0)")

				faultChat = false
				return true
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Wait until the current Gimme Arena game is concluded. You can reset it with " .. server.commandPrefix .. "reset gimmearena[-]")
				botman.faultyChat = false
				return true
			end
		end
	end


	local function cmd_Poke()
		-- Annoy the bot
		if string.find(chatvars.words[1], "poke") and chatvars.words[2] ==  nil then
			r = randSQL(45)
			if r == 1 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Hey![-]") end
			if r == 3 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Stop that![-]") end
			if r == 5 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Ouch![-]") end
			if r == 7 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]GRR GRR GRR[-]") end
			if r == 9 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Pest[-]") end
			if r == 11 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]:O[-]") end
			if r == 13 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]D:[-]") end
			if r == 17 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Really?[-]") end
			if r == 19 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]GROAN![-]") end
			if r == 21 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Ow![-]") end
			if r == 23 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Quit that![-]") end
			if r == 25 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]O.x[-]") end
			if r == 27 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]>:O[-]") end
			if r == 29 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]>.<[-]") end
			if r == 31 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]*sigh*[-]") end
			if r == 33 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]FML[-]") end
			if r == 35 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You![-]") end
			if r == 37 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Abuse![-]") end
			if r == 39 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]EEK![-]") end
			if r == 41 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Oi![-]") end
			if r == 45 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]:P[-]") end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_QuitWithMessage()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}quit {message}"
			help[2] = "Get kicked out of the server and have the bot say your message in game chat."

			tmp.command = help[1]
			tmp.keywords = "quit"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "quit"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "quit") then
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}quit\n"
			help[1] = help[1] .. " {#}ragequit"
			help[2] = "Get kicked out of the server with a random message."

			tmp.command = help[1]
			tmp.keywords = "quit"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "quit"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "quit" or chatvars.words[1] == "ragequit" then
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme reset"
			help[2] = "Reset gimme counters for everyone so they can play gimme again.  The bot does this every " .. server.gimmeResetTimer .. " minutes automatically."

			tmp.command = help[1]
			tmp.keywords = "gimm,reset"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "gimme" and chatvars.words[2] == "reset" and chatvars.words[3] == nil) then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			gimmeReset()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetGimmeHell()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reset arena"
			help[2] = "Cancel an arena game in progress."

			tmp.command = help[1]
			tmp.keywords = "fix,gimm,init"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "reset" and (chatvars.words[2] == "gimmehell" or chatvars.words[2] == "gimmearena" or chatvars.words[2] == "arena") then
			if (chatvars.playername == "Server") then
				resetGimmeArena()
				irc_chat(server.ircMain, "The Gimme Arena game has been reset.")

				botman.faultyChat = false
				return true
			end

			if arenaPlayers[chatvars.playerid] or (chatvars.accessLevel < 3) then
				resetGimmeArena()

				botman.faultyChat = false
				return true
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only an arena participant or an admin can stop an active game.[-]")
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
		if (chatvars.words[1] == "santa" and chatvars.words[2] == nil and specialDay == "christmas") then
			if (not players[chatvars.playerid].santa) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]HO HO HO  Merry Christmas![-]")
				if not server.botman and not server.stompy then
					sendCommand("give " .. chatvars.playerid .. " apparelShades 1")
					sendCommand("give " .. chatvars.playerid .. " drinkJarBeer 1")
					sendCommand("give " .. chatvars.playerid .. " resourceCoal 1")
					sendCommand("give " .. chatvars.playerid .. " thrownAmmoPipeBomb 1")
					sendCommand("give " .. chatvars.playerid .. " medicalSplint 1")
				end

				if server.stompy and not server.botman then
					sendCommand("bc-give " .. chatvars.playerid .. " apparelShades /c=1 /silent")
					sendCommand("bc-give " .. chatvars.playerid .. " drinkJarBeer /c=1 /silent")
					sendCommand("bc-give " .. chatvars.playerid .. " resourceCoal /c=1 /silent")
					sendCommand("bc-give " .. chatvars.playerid .. " thrownAmmoPipeBomb /c=1 /silent")
					sendCommand("bc-give " .. chatvars.playerid .. " medicalSplint /c=1 /silent")
				end

				if server.botman then
					sendCommand("bm-give " .. chatvars.playerid .. " apparelShades 1")
					sendCommand("bm-give " .. chatvars.playerid .. " drinkJarBeer 1")
					sendCommand("bm-give " .. chatvars.playerid .. " resourceCoal 1")
					sendCommand("bm-give " .. chatvars.playerid .. " thrownAmmoPipeBomb 1")
					sendCommand("bm-give " .. chatvars.playerid .. " medicalSplint 1")
				end

				r = randSQL(2)
				if r == 1 then
					cmd = "give " .. chatvars.playerid .. " medicalFirstAidBandage 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " medicalFirstAidBandage /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " medicalFirstAidBandage 1"
					end

					sendCommand(cmd)
				end

				if r == 2 then
					cmd = "give " .. chatvars.playerid .. " medicalFirstAidKit 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " medicalFirstAidKit /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " medicalFirstAidKit 1"
					end

					sendCommand(cmd)
				end

				players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) + 200

				r = randSQL(26)
				if r == 1 then
					cmd = "give " .. chatvars.playerid .. " foodCanBeef 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanBeef /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanBeef 1"
					end

					sendCommand(cmd)
				end

				if r == 2 then
					cmd = "give " .. chatvars.playerid .. " drinkJarBoiledWater 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " drinkJarBoiledWater /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " drinkJarBoiledWater 1"
					end

					sendCommand(cmd)
				end

				if r == 3 then
					cmd = "give " .. chatvars.playerid .. " foodCanCatfood 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanCatfood /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanCatfood 1"
					end

					sendCommand(cmd)
				end

				if r == 4 then
					cmd = "give " .. chatvars.playerid .. " foodCanChicken 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanChicken /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanChicken 1"
					end

					sendCommand(cmd)
				end

				if r == 5 then
					cmd = "give " .. chatvars.playerid .. " foodCanChilli 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanChilli /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanChilli 1"
					end

					sendCommand(cmd)
				end

				if r == 6 then
					cmd = "give " .. chatvars.playerid .. " candle 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " candle /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " candle 1"
					end

					sendCommand(cmd)
				end

				if r == 7 then
					cmd = "give " .. chatvars.playerid .. " resourceCandleStick 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " resourceCandleStick /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " resourceCandleStick 1"
					end

					sendCommand(cmd)
				end

				if r == 8 then
					cmd = "give " .. chatvars.playerid .. " candleTableLightPlayer 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " candleTableLightPlayer /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " candleTableLightPlayer 1"
					end

					sendCommand(cmd)
				end

				if r == 9 then
					cmd = "give " .. chatvars.playerid .. " candleWallLightPlayer 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " candleWallLightPlayer /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " candleWallLightPlayer 1"
					end

					sendCommand(cmd)
				end

				if r == 10 then
					cmd = "give " .. chatvars.playerid .. " foodCanDogfood 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanDogfood /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanDogfood 1"
					end

					sendCommand(cmd)
				end

				if r == 11 then
					cmd = "give " .. chatvars.playerid .. " resourceCandyTin 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " resourceCandyTin /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " resourceCandyTin 1"
					end

					sendCommand(cmd)
				end

				if r == 12 then
					cmd = "give " .. chatvars.playerid .. " drinkCanEmpty 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " drinkCanEmpty /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " drinkCanEmpty 1"
					end

					sendCommand(cmd)
				end

				if r == 13 then
					cmd = "give " .. chatvars.playerid .. " foodCanSham 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanSham /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanSham 1"
					end

					sendCommand(cmd)
				end

				if r == 14 then
					cmd = "give " .. chatvars.playerid .. " foodCanLamb 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanLamb /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanLamb 1"
					end

					sendCommand(cmd)
				end

				if r == 15 then
					cmd = "give " .. chatvars.playerid .. " foodCanMiso 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanMiso /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanMiso 1"
					end

					sendCommand(cmd)
				end

				if r == 16 then
					cmd = "give " .. chatvars.playerid .. " drinkJarRiverWater 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " drinkJarRiverWater /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " drinkJarRiverWater 1"
					end

					sendCommand(cmd)
				end

				if r == 17 then
					cmd = "give " .. chatvars.playerid .. " foodCanPasta 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanPasta /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanPasta 1"
					end

					sendCommand(cmd)
				end

				if r == 18 then
					cmd = "give " .. chatvars.playerid .. " foodCanPears 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanPears /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanPears 1"
					end

					sendCommand(cmd)
				end

				if r == 19 then
					cmd = "give " .. chatvars.playerid .. " foodCanPeas 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanPeas /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanPeas 1"
					end

					sendCommand(cmd)
				end

				if r == 20 then
					cmd = "give " .. chatvars.playerid .. " foodCanSalmon 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanSalmon /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanSalmon 1"
					end

					sendCommand(cmd)
				end

				if r == 21 then
					cmd = "give " .. chatvars.playerid .. " foodCanSoup 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanSoup /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanSoup 1"
					end

					sendCommand(cmd)
				end

				if r == 22 then
					cmd = "give " .. chatvars.playerid .. " foodCanStock 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanStock /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanStock 1"
					end

					sendCommand(cmd)
				end

				if r == 23 then
					cmd = "give " .. chatvars.playerid .. " foodCanTuna 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " foodCanTuna /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " foodCanTuna 1"
					end

					sendCommand(cmd)
				end

				if r == 24 then
					cmd = "give " .. chatvars.playerid .. " ammoGasCan 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " ammoGasCan /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " ammoGasCan 1"
					end

					sendCommand(cmd)
				end

				if r == 25 then
					cmd = "give " .. chatvars.playerid .. " ammoGasCanSchematic 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " ammoGasCanSchematic /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " ammoGasCanSchematic 1"
					end

					sendCommand(cmd)
				end

				if r == 26 then
					cmd = "give " .. chatvars.playerid .. " mineCandyTin 1"

					if server.stompy then
						cmd = "bc-give " .. chatvars.playerid .. " mineCandyTin /c=1 /silent"
					end

					if server.botman then
						cmd = "bm-give " .. chatvars.playerid .. " mineCandyTin 1"
					end

					sendCommand(cmd)
				end

				players[chatvars.playerid].santa = "hohoho"
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]HO HO You have already received your stocking stuffer HO.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetGimmeCooldown()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme raincheck {seconds}"
			help[2] = "Set a time delay between gimmes.  The default is 0 seconds."

			tmp.command = help[1]
			tmp.keywords = "gimm,cool,time,delay"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "gimme" and string.find(chatvars.command, " rain") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Missing number for seconds between gimmes.[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Gimmes can be played until there are none left.[-]")
				else
					irc_chat(chatvars.ircAlias, "Gimmes can be played until there are none left.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players must wait " .. chatvars.number .. " seconds between gimmes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players must wait " .. chatvars.number .. " seconds between gimmes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetGimmeResetTimer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme reset time {number} (In minutes. Default is 120)"
			help[2] = "Reset everyone's gimme counter after (n) minutes."

			tmp.command = help[1]
			tmp.keywords = "gimm,able,on,off"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "gimme" and chatvars.words[2] == "reset" and chatvars.words[3] == "time") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]A number is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "A number is required.")
				end

				botman.faultyChat = false
				return true
			else
				chatvars.number = math.abs(chatvars.number)

				if chatvars.number == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Set a number higher than zero.[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Gimme will reset every " .. chatvars.number .. " minutes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Gimme will reset every " .. chatvars.number .. " minutes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Suicide()
		-- Suicide is painless
		-- It has a cooldown to stop players M.A.S.Hing it
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}suicide"
			help[2] = "Don't do it! :O"

			tmp.command = help[1]
			tmp.keywords = "gimm,sui,death,kill,die"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "suicide") then
			if players[chatvars.playerid].prisoner or players[chatvars.playerid].timeout == true or players[chatvars.playerid].botTimeout == true then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]BANG![-]")
			else
				if players[chatvars.playerid].lastSuicide ~= nil then
					if os.time() - players[chatvars.playerid].lastSuicide < 180 then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]>CLICK!<  Darn your gun jammed.  Try again in a few minutes.[-]")

						botman.faultyChat = false
						return true
					end
				end

				sendCommand("kill " .. chatvars.playerid)
				players[chatvars.playerid].lastSuicide = os.time()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleDogeMode()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}doge mode or {#}doge on/off"
			help[2] = "But what does it do!? Play and find out xD"

			tmp.command = help[1]
			tmp.keywords = "doge,mode"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "doge"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		-- But what does it do!? Play and find out xD
		if chatvars.words[1] == "doge" and (chatvars.words[2] == "on" or chatvars.words[2] == "off" or chatvars.words[2] == "mode") then
			if chatvars.words[2] == "off" then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Doge mode de-activated.[-]")
				igplayers[chatvars.playerid].doge = false
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Doge mode activated.[-]")
				igplayers[chatvars.playerid].doge = true
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleGimmeGame()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme on/off"
			help[2] = "Enable/disable the gimme game."

			tmp.command = help[1]
			tmp.keywords = "gimm,able,on,off"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "gimme" and (chatvars.words[2] == "on" or chatvars.words[2] == "off") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme zombies\n"
			help[1] = help[1] .. " {#}gimme no zombies"
			help[2] = "Enable or disable zombies as gimme prizes."

			tmp.command = help[1]
			tmp.keywords = "gimm,able,on,off"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "gimme" and (chatvars.words[2] == "zombies" or chatvars.words[2] == "no") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}gimme gimme\n"
			help[1] = help[1] .. " {#}gimme peace"
			help[2] = "Make gimme messages appear in public chat with {#}gimme gimme or as private messages with {#}gimme peace (with some exceptions)."

			tmp.command = help[1]
			tmp.keywords = "gimm,reset"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "gimme" and (chatvars.words[2] == "gimme" or chatvars.words[2] == "peace") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}bounty {optional player name}\n"
			help[1] = help[1] .. " {#}view bounty {optional player name}\n"
			help[1] = help[1] .. " {#}view bounties"
			help[2] = "See the player kills and current bounty on a players head or on all players currently on the server."

			tmp.command = help[1]
			tmp.keywords = "pvp,bounty,play,view"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bounty") or string.find(chatvars.command, "pvp"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "bounty" or chatvars.words[1] == "view" or chatvars.words[1] == "list") and (chatvars.words[2] == "bounty" or chatvars.words[2] == "bounties") then
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

				if tmp.id == 0 then
					tmp.id = LookupArchivedPlayer(tmp.pname)

					if not (tmp.id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. tmp.pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. tmp.pname)
						end
					end

					botman.faultyChat = false
					return true
				end

				if tmp.id == chatvars.playerid or tmp.id == chatvars.ircid then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have " .. players[tmp.id].playerKills .. " kills and a bounty of " .. players[tmp.id].pvpBounty .. " " .. server.moneyPlural .. " on your head.[-]")
					else
						irc_chat(chatvars.ircAlias, "You have " .. players[tmp.id].playerKills .. " kills and a bounty of " .. players[tmp.id].pvpBounty .. " " .. server.moneyPlural .. " on your head.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.id].name .. " has " .. players[tmp.id].playerKills .. " kills. Kill them for " .. players[tmp.id].pvpBounty .. " " .. server.moneyPlural .. ".[-]")
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
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[k].name .. " has " .. players[k].playerKills .. " kills and a bounty of " .. players[k].pvpBounty .. "[-]")
							else
								irc_chat(chatvars.ircAlias, players[k].name .. " has " .. players[k].playerKills .. " kills and a bounty of " .. players[k].pvpBounty)
							end
						end
					end

					if not tmp.bountyFound then
						if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player on the server right now has a bounty on their head.[-]")
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
		irc_chat(chatvars.ircAlias, "==== Registering help - fun commands ====")
		if debug then dbug("Registering help - fun commands") end

		tmp.topicDescription = "Fun commands are miscellaneous commands that include gimme, bounties and a few silly commands."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'fun'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch({}, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('fun', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

if debug then dbug("debug fun") end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "fun" then
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
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Fun Commands:")
		irc_chat(chatvars.ircAlias, "=============")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "fun")
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ViewPlayerBounty()

	if result then
		if debug then dbug("debug cmd_ViewPlayerBounty triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleShowHideGimmeMessages()

	if result then
		if debug then dbug("debug cmd_ToggleShowHideGimmeMessages triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_FixGimme()

	if result then
		if debug then dbug("debug cmd_FixGimme triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetGimmeHell()

	if result then
		if debug then dbug("debug cmd_ResetGimmeHell triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetGimmeCooldown()

	if result then
		if debug then dbug("debug cmd_SetGimmeCooldown triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetGimme()

	if result then
		if debug then dbug("debug cmd_ResetGimme triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleGimmeGame()

	if result then
		if debug then dbug("debug cmd_ToggleGimmeGame triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleGimmeZombies()

	if result then
		if debug then dbug("debug cmd_ToggleGimmeZombies triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetGimmeResetTimer()

	if result then
		if debug then dbug("debug cmd_SetGimmeResetTimer triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == 0 and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_Beer()

	if result then
		if debug then dbug("debug cmd_Beer triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_Suicide()

	if result then
		if debug then dbug("debug cmd_Suicide triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_PlaceBounty()

	if result then
		if debug then dbug("debug cmd_PlaceBounty triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_Santa()

	if result then
		if debug then dbug("debug cmd_Santa triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_PlayGimme()

	if result then
		if debug then dbug("debug cmd_PlayGimme triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if not server.beQuietBot then
		result = cmd_Poke()

		if result then
			if debug then dbug("debug cmd_Poke triggered") end
			return result
		end
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_RageQuit()

	if result then
		if debug then dbug("debug cmd_RageQuit triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_QuitWithMessage()

	if result then
		if debug then dbug("debug cmd_QuitWithMessage triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_PlayGimmeHell()

	if result then
		if debug then dbug("debug cmd_PlayGimmeHell triggered") end
		return result
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleDogeMode()

	if result then
		if debug then dbug("debug cmd_ToggleDogeMode triggered") end
		return result
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Fun commands help registered ****")
		if debug then dbug("Fun commands help registered") end
		topicID = topicID + 1
	end

	if debug then dbug("debug fun end") end

	-- can't touch dis
	if true then
		return result
	end
end
