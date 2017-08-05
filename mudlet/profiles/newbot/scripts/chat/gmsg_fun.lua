--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_fun()
	calledFunction = "gmsg_fun"

	local shortHelp = false
	local skipHelp = false
	local debug = false

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
		irc_chat(players[chatvars.ircid].ircAlias, " ")
		irc_chat(players[chatvars.ircid].ircAlias, "Fun Commands:")
		irc_chat(players[chatvars.ircid].ircAlias, "================")
		irc_chat(players[chatvars.ircid].ircAlias, " ")
	end

	if chatvars.showHelpSections then
		irc_chat(players[chatvars.ircid].ircAlias, "fun")
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bounty") or string.find(chatvars.command, "pvp"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "bounty <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "See the player kills and current bounty on a player's head.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "bounty") then
		id = chatvars.playerid

		if (chatvars.words[2] ~= nil) then
			pname = string.sub(chatvars.command, 9)
			id = LookupPlayer(pname)
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has " .. players[id].playerKills .. " kills. Kill them for " .. players[id].pvpBounty .. " " .. server.moneyPlural .. ".[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, players[id].name .. " has " .. players[id].playerKills .. " kills. Kill them for " .. players[id].pvpBounty .. " " .. server.moneyPlural .. ".")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "haven" and chatvars.words[2] ~= nil) then
		if type(brchat) ~= "table" then
		  brchat = {}
		end

		table.insert(brchat, { os.time(), "BR-" .. players[chatvars.playerid].name .. ":" .. string.sub(chatvars.command, string.find(chatvars.command, "haven") + 6) } )

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "gimme peace")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "All gimme messages will be private messages.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (chatvars.words[1] == "gimme" and chatvars.words[2] == "peace") then
		message("say [" .. server.chatColour .. "]Gimme has been silenced[-]")
		server.gimmePeace = true

		if botman.dbConnected then conn:execute("UPDATE server SET gimmePeace = 1") end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "fix gimme")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Force the bot to rescan the list of zombies and animals.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (chatvars.words[1] == "fix" and chatvars.words[2] == "gimme") then
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The zombies have been reloaded.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "The zombies have been reloaded.")
		end

		gimmeZombies = {}
		if botman.dbConnected then conn:execute("DELETE FROM gimmeZombies") end		
		send("se")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reset gimmehell")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Cancel a gimmehell game in progress.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (chatvars.words[1] == "reset" and chatvars.words[2] == "gimmehell") then
		if (chatvars.playername == "Server") then
			resetGimmeHell()
			irc_chat(server.ircMain, "gimmehell has been reset.")

			botman.faultyChat = false
			return true
		end

		dist = distancexyz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].yPos, igplayers[chatvars.playerid].zPos, locations["arena"].x, locations["arena"].y, locations["arena"].z)
		if (dist < locations["arena"].size + 5) or (chatvars.playername == "Server") or (chatvars.accessLevel < 3) then
			resetGimmeHell()

			botman.faultyChat = false
			return true
		end
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "gimme reset")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Reset gimme counters for everyone so they can play gimme again.  The bot does this every 2 hours automatically.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (chatvars.words[1] == "gimme" and chatvars.words[2] == "reset") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is for admins only[-]")
				botman.faultyChat = false
				return true
			end
		end

		gimmeReset()

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "gimme gimme")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "All gimme messages will be in public chat.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (chatvars.words[1] == "gimme" and chatvars.words[2] == "gimme") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		end

		message("say [" .. server.chatColour .. "]Gimme messages are now public[-]")
		server.gimmePeace = false

		if botman.dbConnected then conn:execute("UPDATE server SET gimmePeace = 0") end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "gimme off")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Disable the gimme game.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (chatvars.words[1] == "gimme" and chatvars.words[2] == "off") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		end

		message("say [" .. server.chatColour .. "]Gimme has been disabled[-]")
		server.allowGimme = false

		if botman.dbConnected then conn:execute("UPDATE server SET allowGimme = 0") end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "gimme on")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Enable the gimme game.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (chatvars.words[1] == "gimme" and chatvars.words[2] == "on") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		end

		message("say [" .. server.chatColour .. "]Gimme has been enabled[-]")
		server.allowGimme = true

		if botman.dbConnected then conn:execute("UPDATE server SET allowGimme = 1") end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "gimme zombies")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Players can win zombies.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (chatvars.words[1] == "gimme" and chatvars.words[2] == "zombies") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		end

		message("say [" .. server.chatColour .. "]Gimme prizes proudly sponsored by Zombie Surplus![-]")
		server.gimmeZombies = true

		if botman.dbConnected then conn:execute("UPDATE server SET gimmeZombies = 1") end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "gimm"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "gimme no zombies")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Gimme prizes will not include zombies.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (chatvars.words[1] == "gimme" and chatvars.words[2] == "no" and chatvars.words[3] == "zombies") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		end

		message("say [" .. server.chatColour .. "]Gimme prizes now 100% certified zombie free![-]")
		server.gimmeZombies = false

		if botman.dbConnected then conn:execute("UPDATE server SET gimmeZombies = 0") end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "waiter" or chatvars.words[1] == "beer" and chatvars.words[2] == nil) then
		if string.find(inLocation(chatvars.intX, chatvars.intZ), "beer") then
			send("give " .. chatvars.playerid .. " beer 1")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Enjoy your beer![-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

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

			send("kill " .. chatvars.playerid)
			players[chatvars.playerid].lastSuicide = os.time()
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "place" and chatvars.words[2] == "bounty") then
		pname = chatvars.words[3]
		id = LookupPlayer(pname)

		bounty = math.abs(chatvars.words[4])

		if players[chatvars.playerid].cash >= bounty then
			oldBounty = players[id].pvpBounty
			players[id].pvpBounty = players[id].pvpBounty + bounty
			players[chatvars.playerid].cash = players[chatvars.playerid].cash - bounty
			message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " has placed a bounty of " .. bounty .. " on " .. players[id].name .. "'s head![-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You now have " .. players[chatvars.playerid].cash .. " " .. server.moneyPlural .. ".[-]")

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

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "santa" and specialDay == "christmas" and chatvars.words[2] == nil) then
		if (not players[chatvars.playerid].santa) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]HO HO HO  Merry Christmas!  Press e now, don't let the Grinch steal Christmas.[-]")
			send ("give " .. chatvars.playerid .. " shades 1")
			send ("give " .. chatvars.playerid .. " turd 1")
			send ("give " .. chatvars.playerid .. " beer 2")
			send ("give " .. chatvars.playerid .. " coalOre 1")
			send ("give " .. chatvars.playerid .. " pipeBomb 1")
			send ("give " .. chatvars.playerid .. " splint 1")

			r = rand(2)
			if r == 1 then send ("give " .. chatvars.playerid .. " firstAidBandage 1") end
			if r == 2 then send ("give " .. chatvars.playerid .. " firstAidKit 1") end

			players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) + 200

			r = rand(26)
			if r == 1 then send ("give " .. chatvars.playerid .. " canBeef 1") end
			if r == 2 then send ("give " .. chatvars.playerid .. " canBoiledWater 1") end
			if r == 3 then send ("give " .. chatvars.playerid .. " canCatfood 1") end
			if r == 4 then send ("give " .. chatvars.playerid .. " canChicken 1") end
			if r == 5 then send ("give " .. chatvars.playerid .. " canChili 1") end
			if r == 6 then send ("give " .. chatvars.playerid .. " candle 1") end
			if r == 7 then send ("give " .. chatvars.playerid .. " candleStick 1") end
			if r == 8 then send ("give " .. chatvars.playerid .. " candleTable 1") end
			if r == 9 then send ("give " .. chatvars.playerid .. " candleWall 1") end
			if r == 10 then send ("give " .. chatvars.playerid .. " canDogfood 1") end
			if r == 11 then send ("give " .. chatvars.playerid .. " candyTin 1") end
			if r == 12 then send ("give " .. chatvars.playerid .. " canEmpty 1") end
			if r == 13 then send ("give " .. chatvars.playerid .. " canHam 1") end
			if r == 14 then send ("give " .. chatvars.playerid .. " canLamb 1") end
			if r == 15 then send ("give " .. chatvars.playerid .. " canMiso 1") end
			if r == 16 then send ("give " .. chatvars.playerid .. " canMurkyWater 1") end
			if r == 17 then send ("give " .. chatvars.playerid .. " canPasta 1") end
			if r == 18 then send ("give " .. chatvars.playerid .. " canPears 1") end
			if r == 19 then send ("give " .. chatvars.playerid .. " canPeas 1") end
			if r == 20 then send ("give " .. chatvars.playerid .. " canSalmon 1") end
			if r == 21 then send ("give " .. chatvars.playerid .. " canSoup 1") end
			if r == 22 then send ("give " .. chatvars.playerid .. " canStock 1") end
			if r == 23 then send ("give " .. chatvars.playerid .. " canTuna 1") end
			if r == 24 then send ("give " .. chatvars.playerid .. " gasCan 1") end
			if r == 25 then send ("give " .. chatvars.playerid .. " gasCanSchematic 1") end
			if r == 26 then send ("give " .. chatvars.playerid .. " mineCandyTin 1") end

			players[chatvars.playerid].santa = "hohoho"
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]HO HO You have already received your stocking stuffer Ho.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "gimmie" or chatvars.words[1] == "gimme") and chatvars.words[2] == nil then
		if (server.allowGimme) then
			if tablelength(gimmeZombies) == 0 or gimmeZombies == nil then
				send("se")
			end

			dist1 = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, players[chatvars.playerid].homeX, players[chatvars.playerid].homeZ)
			dist2 = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, players[chatvars.playerid].home2X, players[chatvars.playerid].home2Z)

			if (dist1 < players[chatvars.playerid].protectSize) or (dist2 < players[chatvars.playerid].protect2Size) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Gimme will not spawn any zeds while you are inside your base protection.[-]")
			end

			gimme(chatvars.playerid)
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry, an admin has disabled gimme =([-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if string.find(chatvars.words[1], "poke") and chatvars.words[2] ==  nil then
		r = rand(45)
		if r == 1 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Hey![-]") end
		if r == 3 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Stop that![-]") end
		if r == 5 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Ouch![-]") end
		if r == 7 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]GRR GRR GRR[-]") end
		if r == 9 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Pest[-]") end
		if r == 11 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]:O[-]") end
		if r == 13 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]D:[-]") end
		if r == 15 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]merde[-]") end
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
		if r == 43 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Dammit![-]") end
		if r == 45 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]:P[-]") end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if string.find(chatvars.words[1], "quit") and chatvars.words[2] ==  nil then
		if string.find(chatvars.words[1], "rage") and chatvars.words[2] ==  nil then
			send("kick " .. chatvars.playerid .. " RAAAAGE! xD")
		else
			r = rand(3)
			if r == 1 then send("kick " .. chatvars.playerid .. " High Five! xD") end
			if r == 2 then send("kick " .. chatvars.playerid .. " O.o  The Quit is strong in this one.") end
			if r == 3 then send("kick " .. chatvars.playerid .. " Nice quit    *removes glasses*    YEEEEEEEEAH!") end
		end

		r = rand(4)

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

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "quit") then
		msg = stripQuotes(string.sub(line, string.find(line, "quit") + 5))

		if msg ~= nil then
			message("say [" .. server.chatColour .. "]" .. players[chatvars.playerid].name .. " quit with this parting shot.. " .. msg .."[-]")
		end

		send("kick " .. chatvars.playerid .. "\"That'll learn em! xD\"")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "gimmehell" and chatvars.words[2] == nil) then
		-- abort if not in arena

		if tablelength(gimmeZombies) == 0 or gimmeZombies == nil then
			send("se")
		end

		dist = distancexyz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].yPos, igplayers[chatvars.playerid].zPos, locations["arena"].x, locations["arena"].y, locations["arena"].z)

		if (tonumber(dist) > tonumber(locations["arena"].size)) and (tonumber(dist) < tonumber(locations["arena"].size) + 5) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Nobody is in the arena.  You can't play from the spectator area.  Get in the arena coward.[-]")
			botman.faultyChat = false
			return true
		end

		if (tonumber(dist) > tonumber(locations["arena"].size)) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command can only be issued in the arena[-]")
			botman.faultyChat = false
			return true
		end

		if (botman.gimmeHell == 0) then
			removeZombies() -- make sure there are no zeds left that we have flagged for removal
			removeEntities() -- make sure there are no entities left that we have flagged for removal
			botman.gimmeHell = 1

			setupArenaPlayers(chatvars.playerid)
			areaTimer1 = tempTimer( 5, [[ announceGimmeHell(1) ]] )
			areaTimer2 = tempTimer( 10, [[ queueGimmeHell(1) ]] )
			areaTimer3 = tempTimer( 60, [[ announceGimmeHell(2) ]] )
			areaTimer4 = tempTimer( 65, [[ queueGimmeHell(2) ]] )
			areaTimer5 = tempTimer( 120, [[ announceGimmeHell(3) ]] )
			areaTimer6 = tempTimer( 125, [[ queueGimmeHell(3) ]] )
			areaTimer7 = tempTimer( 180, [[ announceGimmeHell(4) ]] )
			areaTimer8 = tempTimer( 185, [[ queueGimmeHell(4) ]] )
			faultChat = false
			return true
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Wait until the current gimmehell is concluded. You can reset it with " .. server.commandPrefix .. "reset gimmehell[-]")
			botman.faultyChat = false
			return true
		end
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "doge" and (chatvars.words[2] == "on" or chatvars.words[2] == "mode") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have activated doge mode.[-]")
		igplayers[chatvars.playerid].doge = true

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug fun line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "doge" and chatvars.words[2] == "off") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have de-activated doge mode.[-]")
		igplayers[chatvars.playerid].doge = false

		botman.faultyChat = false
		return true
	end

if debug then dbug("debug fun end") end

end
