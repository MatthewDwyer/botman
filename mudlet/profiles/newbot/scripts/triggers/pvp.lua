--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function pvpPolice(line)
	local killerScore = 0
	local victimScore = 0
	local killerID, victimID, arenaID, score, eventID, debug

	debug = false

	if botman.botDisabled then
		return
	end

	if (not string.find(line, "INF GMSG")) then
		-- prevent players from tricking the bot into banning players
		return
	end

	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end

	r = rand(15)
	score = string.format("%.1f", math.random() * 10)

	nameStart = string.find(line, "INF GMSG") + 10

	if string.find(line, " eliminated") then
		nameEnd = string.find(line, " eliminated") - 1
	end

	if string.find(line, " killed by") then
		nameStart = string.find(line, "INF GMSG") + 17
		nameEnd = string.find(line, " killed by") - 1

		victimName = stripQuotes(string.sub(line, nameStart, nameEnd))
		victimID = LookupPlayer(victimName, "all")
	end

--dbug("victimName " .. victimName)
--dbug("victimID " .. victimID)

	if string.find(line, " eliminated") then
		nameStart = string.find(line, "eliminated") + 11
	end

	if string.find(line, " killed by") then
		nameStart = string.find(line, "killed by") + 10

		killerName = stripQuotes(string.sub(line, string.find(line, "killed by") + 10))
		killerID = LookupPlayer(killerName, "all")
	end

--dbug("killerName " .. killerName)
--dbug("killerID " .. killerID)

	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end

	irc_chat(server.ircMain, killerID .. " " .. killerName .. " eliminated " .. victimID .. " " .. victimName .. " at " .. math.floor(igplayers[killerID].xPos) .. " " .. math.floor(igplayers[killerID].yPos) .. " " .. math.floor(igplayers[killerID].zPos))
	irc_chat(server.ircAlerts, killerID .. " " .. killerName .. " eliminated " .. victimID .. " " .. victimName .. " at " .. math.floor(igplayers[killerID].xPos) .. " " .. math.floor(igplayers[killerID].yPos) .. " " .. math.floor(igplayers[killerID].zPos))

	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end

	igplayers[victimID].deadX = igplayers[victimID].xPos
	igplayers[victimID].deadY = igplayers[victimID].yPos
	igplayers[victimID].deadZ = igplayers[victimID].zPos

	if (killerName == victimName) then
		if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end

		if (r == 1) then message("say [" .. server.chatColour .. "]" .. killerName .. " removed themselves from the gene pool.[-]") end
		if (r == 2) then message("say [" .. server.chatColour .. "]LOL!  Didn't run far away enough did you " .. killerName .. "?[-]") end
		if (r == 3) then message("say [" .. server.chatColour .. "]And the prize for most creative way to end themselves goes to.. " .. killerName .. "[-]") end
		if (r == 4) then message("say [" .. server.chatColour .. "]" .. killerName .. " really shouldn't handle explosives.[-]") end
		if (r == 5) then message("say Oh no! " .. killerName .. " died.  What a shame.[-]") end
		if (r == 6) then message("say [" .. server.chatColour .. "]Great effort there " .. killerName .. ". I'm awarding " .. score .. " points.[-]") end
		if (r == 7) then message("say [" .. server.chatColour .. "]LOL! REKT[-]") end

		if (r == 8) then
			message("say [" .. server.chatColour .. "]We are gathered here today to remember with sadness the passing of " .. killerName .. ". Rest in pieces. Amen.[-]")
		end

		if (r == 9) then message("say [" .. server.chatColour .. "]" .. killerName .. " cut the wrong wire.[-]") end
		if (r == 10) then message("say [" .. server.chatColour .. "]" .. killerName .. " really showed that explosive who's boss![-]") end
		if (r == 11) then message("say [" .. server.chatColour .. "]" .. killerName .. " shouldn't play Russian Roulette with a fully loaded gun.[-]") end
		if (r == 12) then message("say [" .. server.chatColour .. "]" .. killerName .. " added a new stain to the floor.[-]") end
		if (r == 13) then message("say [" .. server.chatColour .. "]ISIS got nothing on " .. killerName .. "'s suicide bomber skillz.[-]") end
		if (r == 14) then message("say [" .. server.chatColour .. "]" .. killerName .. " reached a new low with that death. Six feet under.[-]") end
		if (r == 15) then message("say [" .. server.chatColour .. "]" .. killerName .. " needs clean undies after that one.[-]") end

		return
	else
		if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end

		if (igplayers[killerID].currentLocationPVP or igplayers[victimID].currentLocationPVP) then
			-- check for evidence of hacking
			if players[killerID].newPlayer and tonumber(players[killerID].hackerScore) > 50 then
				players[killerID].hackerScore = 0
				message("say [" .. server.chatColour .. "]Temp banning " .. players[killerID].name .. " for suspected hacking. Admins have been alerted.[-]")
				banPlayer(killerID, "1 week", "Auto-banned for suspected hacking. Admins have been alerted.", "")
				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[killerID].xPos) .. "," .. math.ceil(igplayers[killerID].yPos) .. "," .. math.floor(igplayers[killerID].zPos) .. ",'" .. botman.serverTime .. "','ban','Player " .. escape(killerName) .. " temp banned for pvp with a hackerScore > 50')") end
				return
			end

			if tonumber(players[killerID].playerKills) == 0 then
				r = rand(4)
				if r == 1 then message("say [" .. server.chatColour .. "]" .. killerName .. " makes their first kill and is now a hit.. sorry has a hit on themselves.[-]") end
				if r == 2 then message("say [" .. server.chatColour .. "]" .. killerName .. " finally scores their first kill! Woo Hoo![-]") end
				if r == 3 then message("say [" .. server.chatColour .. "]" .. killerName .. " finally scores their first kill! About time you showed up kid.[-]") end
				if r == 4 then message("say [" .. server.chatColour .. "]" .. killerName .. " makes their first kill!  It was just a prank bro![-]") end

				players[killerID].pvpBounty = 200
			else
				r = rand(29)
				if r == 1 then message("say [" .. server.chatColour .. "]" .. killerName .. " once again asserts their dominance in the world.[-]") end
				if r == 2 then message("say [" .. server.chatColour .. "]" .. killerName .. " strikes a mighty blow against " .. victimName .. "![-]") end
				if r == 3 then message("say [" .. server.chatColour .. "]" .. killerName .. " fluked that one! " .. victimName .. " will be pissed.[-]") end
				if r == 4 then message("say [" .. server.chatColour .. "]" .. killerName .. " dispatched " .. victimName .. " with a little too much enthusiasm. Medics have been called to consume the body.[-]") end
				if r == 5 then message("say [" .. server.chatColour .. "]" .. killerName .. " ripped " .. victimName .. " a new asshole.[-]") end
				if r == 6 then message("say [" .. server.chatColour .. "]Player " .. killerName .. " is on fire metaphorically speaking. " .. victimName .. " is too.. for real.[-]") end
				if r == 7 then message("say [" .. server.chatColour .. "]" .. killerName .. " is really asking for it with another spectacular kill.[-]") end
				if r == 8 then message("say [" .. server.chatColour .. "]" .. killerName .. " sent " .. victimName .. " a heart stopping, high velocity gift.  Right between the eyes.[-]") end
				if r == 9 then message("say [" .. server.chatColour .. "]" .. victimName .. " walked right into that one![-]") end
				if r == 10 then message("say [" .. server.chatColour .. "]" .. victimName .. " forgot their flame proof underwear, or infact any underwear.[-]") end
				if r == 11 then message("say [" .. server.chatColour .. "]" .. victimName .. " spread themselves too thin in that fight.  Anyone got a broom and shovel?[-]") end
				if r == 12 then message("say [" .. server.chatColour .. "]" .. victimName .. " impaled themselves on " .. killerName .. "'s mighty sword! .. I said mighty not erect![-]") end
				if r == 13 then message("say [" .. server.chatColour .. "]Sadly " .. victimName .. " lost that fight.  Well I'm sad, I had " .. t .. " " .. server.moneyPlural .. " riding on him. :([-]") end
				if r == 14 then message("say [" .. server.chatColour .. "]" .. victimName .. " enters the space program with a bang.. and a thud.. and another.  Oh and there's a leg.[-]") end
				if r == 15 then message("say [" .. server.chatColour .. "]" .. killerName .. " cut " .. victimName .. " a new asshole!  I guess that makes " .. victimName .. " their own twin?[-]") end
				if r == 16 then message("say [" .. server.chatColour .. "]" .. killerName .. " cut " .. victimName .. " a new asshole!  " .. victimName .. " is an even bigger asshole now! ^^[-]") end
				if r == 17 then message("say [" .. server.chatColour .. "]" .. killerName .. " is slicing and dicing up the competition![-]") end
				if r == 18 then message("say [" .. server.chatColour .. "]" .. killerName .. " makes mince meat of " .. victimName .. "! Gather round boys!  We're havin a BBQ with a side of WTF covered in OMG sauce![-]") end
				if r == 19 then message("say [" .. server.chatColour .. "]Gordon Bennet! " .. killerName .. " is racing towards the lead with another masterfull kill.[-]") end
				if r == 20 then message("say [" .. server.chatColour .. "]That was a feeble effort by " .. victimName .. ".[-]") end
				if r == 21 then message("say [" .. server.chatColour .. "]" .. victimName .. " will need to move faster next time.. because they just lost both legs below the knee![-]") end
				if r == 22 then message("say [" .. server.chatColour .. "]" .. killerName .. " made new garden furnature from " .. victimName .. "'s corpse.[-]") end
				if r == 23 then message("say [" .. server.chatColour .. "]" .. killerName .. " has a new trophy head! " .. victimName .. "'s head is pretty ugly but it'll do.[-]") end
				if r == 24 then message("say [" .. server.chatColour .. "]" .. killerName .. " has meat on the menu again with a slice of " .. victimName .. " and a few unrecognisable gibblets.[-]") end
				if r == 25 then message("say [" .. server.chatColour .. "]" .. victimName .. " should have taken up knitting, its safer.[-]") end
				if r == 26 then message("say [" .. server.chatColour .. "]" .. victimName .. " is in pieces over that one!  Caution: choking hazard.  Keep away from children under 3.[-]") end
				if r == 27 then message("say [" .. server.chatColour .. "]" .. victimName .. " proves once again that you shouldn't borrow sugar from " .. killerName .. ".[-]") end
				if r == 28 then message("say [" .. server.chatColour .. "]" .. victimName .. " needs a new hobby. " .. killerName .. " needs a dry clean.[-]") end
				if r == 29 then message("say [" .. server.chatColour .. "]Oops " .. killerName .. " did it again.[-]") end

				if server.allowBank and tonumber(players[victimID].pvpBounty) > 0 then
					message("pm " .. killerID .. " [" .. server.chatColour .. "]You won the bounty on " .. victimName .. "![-]")
				end
			end

	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end

			if server.allowBank then
				if tonumber(players[victimID].pvpBounty) > 0 then
					players[killerID].cash = players[killerID].cash + players[victimID].pvpBounty
					players[victimID].pvpBounty = 0
					message("pm " .. killerID .. " [" .. server.chatColour .. "]You got the bounty on " .. victimName .. "![-]")
				else
					if tonumber(players[killerID].pvpBounty) > 0 then
						message("say [" .. server.chatColour .. "]A bounty of " .. players[killerID].pvpBounty .. " is on " .. killerName .. "'s head. Bring it home![-]")
					end
				end
			end

	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end

			-- record the pvp in the events table
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[killerID].xPos) .. "," .. math.ceil(igplayers[killerID].yPos) .. "," .. math.floor(igplayers[killerID].zPos) .. ",'" .. botman.serverTime .. "','pvp','Player " .. escape(killerName) .. " killed " .. escape(victimName) .. " in a pvp zone'," .. killerID .. ")") end

			if botman.db2Connected then
				-- copy in bots db
				connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','pvp','Player " .. escape(killerName) .. " killed " .. escape(victimName) .. " in a pvp zone'," .. killerID .. ")")
			end

			if server.pvpTeleportCooldown > 0 then
				players[killerID].pvpTeleportCooldown = os.time() + server.pvpTeleportCooldown
			end

			return
		end

	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end

		-- arena pvp zone
		if locations["arena"] ~= nil then
			if distancexz(igplayers[killerID].xPos, igplayers[killerID].zPos, locations["arena"].x, locations["arena"].z ) < 31 then
				return
			end
		end

	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end

		-- don't react if player is inside the prison
		if locations["prison"] ~= nil then
			if ((math.abs(math.abs(igplayers[killerID].xPos) - math.abs(locations["prison"].x)) < locations["prison"].size) or (math.abs(math.abs(igplayers[killerID].zPos) - math.abs(locations["prison"].z)) < locations["prison"].size)) then
				return
			end
		end

	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end

		if (accessLevel(killerID) < 3 and botman.ignoreAdmins == true) then
			message("say [" .. server.chatColour .. "]PvP is not allowed outside of PVP zones! However " .. killerName .. " is authorised to PVP[-]")
			message("pm " .. killerID .. " [" .. server.chatColour .. "]You are allowed to pvp to defend yourself and others. Don't abuse this privilege.[-]")
			table.save(homedir .. "/server.lua", server)
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[victimID].xPos) .. "," .. math.ceil(igplayers[victimID].yPos) .. "," .. math.floor(igplayers[victimID].zPos) .. ",'" .. botman.serverTime .. "','pvp','Admin " .. escape(killerName) .. " killed " .. escape(victimName) .. " at " .. igplayers[killerID].xPos .. " " .. igplayers[killerID].yPos .. " " .. igplayers[killerID].zPos .. "'," .. killerID .. ")") end

			if botman.db2Connected then
				-- copy in bots db
				connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','pvp','Admin " .. escape(killerName) .. " killed " .. escape(victimName) .. " at " .. igplayers[killerID].xPos .. " " .. igplayers[killerID].yPos .. " " .. igplayers[killerID].zPos .. "'," .. killerID .. ")")
			end

			return
		end

	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end
		message("say [" .. server.chatColour .. "]PvP is not allowed outside of PVP zones!  Read " .. server.commandPrefix .. "help pvp[-]")

		if (not isNewPlayer(killerID) and players[killerID].atHome and players[victimID].newPlayer) then
			message("say [" .. server.chatColour .. "]Killing in self-defense is allowed.  No arrest made. Admins will review this killing and may decide to punish for it later.[-]")
			irc_chat(server.ircAlerts, killerID .. " " .. killerName .. " killed new player " .. victimID .. " " .. victimName .. ".  No arrest made. Killer's location was " .. math.floor(igplayers[killerID].xPos) .. " " .. math.floor(igplayers[killerID].yPos) .. " " .. math.floor(igplayers[killerID].zPos))
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[victimID].xPos) .. "," .. math.ceil(igplayers[victimID].yPos) .. "," .. math.floor(igplayers[victimID].zPos) .. ",'" .. botman.serverTime .. "','pvp','" .. escape(killerName) .. " killed new player " .. escape(victimName) .. ".  No arrest made. Killer's location was " .. math.floor(igplayers[victimID].xPos) .. " " .. math.floor(igplayers[victimID].yPos) .. " " .. math.floor(igplayers[victimID].zPos) .. "'," .. killerID .. ")") end

			if botman.db2Connected then
				-- copy in bots db
				connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','pvp','" .. escape(killerName) .. " killed new player " .. escape(victimName) .. ".  No arrest made. Killer's location was " .. math.floor(igplayers[victimID].xPos) .. " " .. math.floor(igplayers[victimID].yPos) .. " " .. math.floor(igplayers[victimID].zPos) .. "'," .. killerID .. ")")
			end

			return
		end

	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end

		if locations["prison"] ~= nil then
	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end
			players[killerID].xPosOld = math.floor(igplayers[killerID].xPos)
			players[killerID].yPosOld = math.ceil(igplayers[killerID].yPos)
			players[killerID].zPosOld = math.floor(igplayers[killerID].zPos)

			message("say [" .. server.chatColour .. "]" .. killerName .. " has been sent to prison, charged with PVP in a restricted zone.[-]")
			message("say [" .. server.chatColour .. "]Admins or the victim can release them by typing " .. server.commandPrefix .. "release " .. killerName .. "[-]")
			message("pm " .. killerID .. " [" .. server.chatColour .. "]You can not return until released from prison.[-]")
			irc_chat(server.ircAlerts, killerID .. " " .. killerName .. " has been sent to prison, charged with PVP at " .. players[killerID].xPosOld .. " " .. players[killerID].yPosOld .. " " .. players[killerID].zPosOld)

			randomTP(killerID, "prison", true)

			players[killerID].prisoner = true
			players[killerID].pvpVictim = victimID
			players[killerID].prisonReason = "PVP against " .. players[victimID].name
			players[killerID].prisonxPosOld = math.floor(igplayers[killerID].xPos)
			players[killerID].prisonyPosOld = math.ceil(igplayers[killerID].yPos)
			players[killerID].prisonzPosOld = math.floor(igplayers[killerID].zPos)
			players[killerID].prisonReleaseTime = os.time() + (server.maxPrisonTime * 60)
			players[steam].bail = server.bailCost

			message("pm " .. victimID  .. " [" .. server.chatColour .. "]You may release " .. killerName .. ". Do so at your own risk by typing[-]")
			message("pm " .. victimID  .. " " .. server.commandPrefix .. "release " .. players[killerID].id .. " or " .. server.commandPrefix .. "release " .. killerName .. "[-]")

			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[killerID].xPos) .. "," .. math.ceil(igplayers[killerID].yPos) .. "," .. math.floor(igplayers[killerID].zPos) .. ",'" .. botman.serverTime .. "','pvp','Player " .. escape(killerName) .. " sent to prison for killing " .. escape(victimName) .. " at " .. igplayers[killerID].xPos .. " " .. igplayers[killerID].yPos .. " " .. igplayers[killerID].zPos .. "'," .. killerID .. ")") end

			if botman.db2Connected then
				-- copy in bots db
				connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','pvp','Player " .. escape(killerName) .. " sent to prison for killing " .. escape(victimName) .. " at " .. igplayers[killerID].xPos .. " " .. igplayers[killerID].yPos .. " " .. igplayers[killerID].zPos .. "'," .. killerID .. ")")
			end

			fixMissingPlayer(killerID)
			updatePlayer(killerID)
		else
	if (debug) then dbug("debug pvp line " .. debugger.getinfo(1).currentline) end
			if server.gameType == "pve" then
				-- check for evidence of hacking
				if players[killerID].newPlayer and tonumber(players[killerID].hackerScore) > 50 then
					players[killerID].hackerScore = 0
					message("say [" .. server.chatColour .. "]Temp banning " .. players[killerID].name .. " for suspected hacking. Admins have been alerted.[-]")
					banPlayer(killerID, "1 week", "Auto-banned for suspected hacking. Admins have been alerted.", "")
					if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[killerID].xPos) .. "," .. math.ceil(igplayers[killerID].yPos) .. "," .. math.floor(igplayers[killerID].zPos) .. ",'" .. botman.serverTime .. "','ban','Player " .. escape(killerName) .. " temp banned for pvp with a hackerScore > 50')") end
					return
				end

				message("say [" .. server.chatColour .. "]" .. killerName .. " has been banned for 1 hour, charged with PVP.  Contact an admin to get them unbanned any sooner.[-]")
				irc_chat(server.ircAlerts, killerID .. " " .. killerName .. " has been banned for 1 hour, charged with PVP at " .. igplayers[killerID].xPos .. " " .. igplayers[killerID].yPos .. " " .. igplayers[killerID].zPos)
				kick(killerID, "This is a PVE server.  PVP somewhere else.  An admin may unban you pending the circumstances of the pvp.")
				banPlayer(killerID, "1 hour", "PVP", "")

				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[killerID].xPos) .. "," .. math.ceil(igplayers[killerID].yPos) .. "," .. math.floor(igplayers[killerID].zPos) .. ",'" .. botman.serverTime .. "','pvp','Player " .. escape(killerName) .. " banned 1 hour for killing " .. escape(victimName) .. " at " .. igplayers[killerID].xPos .. " " .. igplayers[killerID].yPos .. " " .. igplayers[killerID].zPos .. "'," .. killerID .. ")") end

				if botman.db2Connected then
					-- copy in bots db
					connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','pvp','Player " .. escape(killerName) .. " banned 1 hour for killing " .. escape(victimName) .. " at " .. igplayers[killerID].xPos .. " " .. igplayers[killerID].yPos .. " " .. igplayers[killerID].zPos .. "'," .. killerID .. ")")
				end
			end
		end
	end

if debug then dbug("debug pvp end") end
end
