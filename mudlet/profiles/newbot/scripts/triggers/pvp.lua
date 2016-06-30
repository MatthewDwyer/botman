--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function pvpPolice(line)
	local killerScore = 0
	local victimScore = 0
	local killerid
	local victimid
	local arenaID
	local score
	local eventID
	
	if botDisabled then
		return
	end

	if (not string.find(line, "INF GMSG")) then
		-- prevent players from tricking the bot into banning players
		return
	end 

	r = rand(15)
	score = string.format("%.1f", math.random() * 10)

	nameStart = string.find(line, "INF GMSG") + 10
	nameEnd = string.find(line, " eliminated") - 1

	killerName = string.sub(line, nameStart, nameEnd)
	killerid = LookupPlayer(killerName)

	nameStart = string.find(line, "eliminated") + 11

	victimName = string.sub(line, nameStart)
	victimid = LookupPlayer(victimName)

	message("say [" .. server.chatColour .. "]" .. killerName .. " killed " .. victimName .. "[-]")
	irc_QueueMsg(server.ircMain, killerName .. " eliminated " .. victimName .. " at " .. igplayers[killerid].xPosOld .. " " .. igplayers[killerid].yPosOld .. " " .. igplayers[killerid].zPosOld)	
	irc_QueueMsg(server.ircAlerts, killerName .. " eliminated " .. victimName .. " at " .. igplayers[killerid].xPosOld .. " " .. igplayers[killerid].yPosOld .. " " .. igplayers[killerid].zPosOld)

	igplayers[victimid].deadX = igplayers[victimid].xPos
	igplayers[victimid].deadY = igplayers[victimid].yPos
	igplayers[victimid].deadZ = igplayers[victimid].zPos

	if (killerName == victimName) then
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
		if (pvpZone(igplayers[killerid].xPos, igplayers[killerid].zPos) ~= false) or (server.gameType == "pvp") then
			if tonumber(players[killerid].playerKills) == 0 then
				r = rand(4)
				if r == 1 then message("say [" .. server.chatColour .. "]" .. killerName .. " makes their first kill and is now a hit.. sorry has a hit on themselves.[-]") end
				if r == 2 then message("say [" .. server.chatColour .. "]" .. killerName .. " finally scores their first kill! Woo Hoo![-]") end
				if r == 3 then message("say [" .. server.chatColour .. "]" .. killerName .. " finally scores their first kill! About time you showed up kid.[-]") end
				if r == 4 then message("say [" .. server.chatColour .. "]" .. killerName .. " makes their first kill!  It was just a prank bro![-]") end

				players[killerid].pvpBounty = 200
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
				if r == 13 then message("say [" .. server.chatColour .. "]Sadly " .. victimName .. " lost that fight.  Well I'm sad, I had " .. t .. " zennies riding on him. :([-]") end
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

				if server.allowBank and tonumber(players[victimid].pvpBounty) > 0 then
					message("pm " .. killerid .. " [" .. server.chatColour .. "]You won the bounty on " .. victimName .. "![-]")
				end
			end

			if server.allowBank then
				if tonumber(players[victimid].pvpBounty) > 0 then
					players[killerid].cash = players[killerid].cash + players[victimid].pvpBounty
					players[victimid].pvpBounty = 0
					message("pm " .. killerid .. " [" .. server.chatColour .. "]You got the bounty on " .. victimName .. "![-]")
				else
					if tonumber(players[killerid].pvpBounty) > 0 then
						message("say [" .. server.chatColour .. "]A bounty of " .. players[killerid].pvpBounty .. " is on " .. killerName .. "'s head. Bring it home![-]")
					end
				end
			end

			-- record the pvp in the events table
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[killerid].xPos) .. "," .. math.ceil(igplayers[killerid].yPos) .. "," .. math.floor(igplayers[killerid].zPos) .. ",'" .. serverTime .. "','pvp','Player " .. escape(killerName) .. " killed " .. escape(victimName) .. " in a pvp zone'," .. killerid .. ")")

			if db2Connected then
				-- copy in bots db
				connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.ServerName) .. "','" .. serverTime .. "','pvp','Player " .. escape(killerName) .. " killed " .. escape(victimName) .. " in a pvp zone'," .. killerid .. ")")
			end

			return
		end

		-- arena pvp zone
		if locations["arena"] ~= nil then
			if distancexz(igplayers[killerid].xPos, igplayers[killerid].zPos, locations["arena"].x, locations["arena"].z ) < 31 then
				return
			end
		end

		-- don't react if player is inside the prison
		if locations["prison"] ~= nil then
			if ((math.abs(math.abs(igplayers[killerid].xPos) - math.abs(locations["prison"].x)) < server.prisonSize) or (math.abs(math.abs(igplayers[killerid].zPos) - math.abs(locations["prison"].z)) < server.prisonSize)) then
				return
			end
		end

		if (accessLevel(killerid) < 3 and server.ignoreAdmins == true) then 
			cecho(server.windowAlerts, "admin pvp: " .. line .. "\n")
			message("say [" .. server.chatColour .. "]PvP is not allowed outside of PVP zones! However " .. killerName .. " is authorised to PVP[-]")	
			message("pm " .. killerid .. " [" .. server.chatColour .. "]You are allowed to pvp to defend yourself and others. Don't abuse this privilege.[-]")
			table.save(homedir .. "/server.lua", server)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[victimid].xPos) .. "," .. math.ceil(igplayers[victimid].yPos) .. "," .. math.floor(igplayers[victimid].zPos) .. ",'" .. serverTime .. "','pvp','Admin " .. escape(killerName) .. " killed " .. escape(victimName) .. " at " .. igplayers[killerid].xPos .. " " .. igplayers[killerid].yPos .. " " .. igplayers[killerid].zPos .. "'," .. killerid .. ")")

			if db2Connected then
				-- copy in bots db
				connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.ServerName) .. "','" .. serverTime .. "','pvp','Admin " .. escape(killerName) .. " killed " .. escape(victimName) .. " at " .. igplayers[killerid].xPos .. " " .. igplayers[killerid].yPos .. " " .. igplayers[killerid].zPos .. "'," .. killerid .. ")")
			end

			return
		end

		cecho(server.windowAlerts, line .. "\n")
		message("say [" .. server.chatColour .. "]PvP is not allowed outside of PVP zones!  Read /help pvp[-]")

		if (isNewPlayer(victimid) and not isNewPlayer(killerid)) then
			message("say [" .. server.chatColour .. "]Killing in self-defense is allowed.  No arrest made. Admins will review this killing and may decide to punish for it later.[-]")	
			irc_QueueMsg(server.ircAlerts, killerName .. " killed new player " .. victimName .. ".  No arrest made. Killer's location was " .. math.floor(igplayers[killerid].xPos) .. " " .. math.floor(igplayers[killerid].yPos) .. " " .. math.floor(igplayers[killerid].zPos))
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[victimid].xPos) .. "," .. math.ceil(igplayers[victimid].yPos) .. "," .. math.floor(igplayers[victimid].zPos) .. ",'" .. serverTime .. "','pvp','" .. escape(killerName) .. " killed new player " .. escape(victimName) .. ".  No arrest made. Killer's location was " .. math.floor(igplayers[victimid].xPos) .. " " .. math.floor(igplayers[victimid].yPos) .. " " .. math.floor(igplayers[victimid].zPos) .. "'," .. killerid .. ")")

			if db2Connected then
				-- copy in bots db
				connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.ServerName) .. "','" .. serverTime .. "','pvp','" .. escape(killerName) .. " killed new player " .. escape(victimName) .. ".  No arrest made. Killer's location was " .. math.floor(igplayers[victimid].xPos) .. " " .. math.floor(igplayers[victimid].yPos) .. " " .. math.floor(igplayers[victimid].zPos) .. "'," .. killerid .. ")")
			end

			return
		end

		if locations["prison"] ~= nil then
			igplayers[killerid].xPosOld = math.floor(igplayers[killerid].xPos)
			igplayers[killerid].yPosOld = math.floor(igplayers[killerid].yPos)
			igplayers[killerid].zPosOld = math.floor(igplayers[killerid].zPos)
			
			message("say [" .. server.chatColour .. "]" .. killerName .. " has been sent to prison, charged with PVP in a restricted zone.[-]")
			message("say [" .. server.chatColour .. "]Admins or the victim can release them by typing /release " .. killerName .. "[-]")
			message("pm " .. killerid .. " [" .. server.chatColour .. "]You can not return until released from prison.[-]")
			irc_QueueMsg(server.ircAlerts, killerName .. " has been sent to prison, charged with PVP at " .. igplayers[killerid].xPosOld .. " " .. igplayers[killerid].yPosOld .. " " .. igplayers[killerid].zPosOld)
			cmd = "tele " .. killerid .. " " .. locations["prison"].x .. " " .. locations["prison"].y .. " " .. locations["prison"].z
	
			if players[killerid].watchPlayer then
				irc_QueueMsg(server.ircTracker, gameDate .. " " .. killerid .. " " .. igplayers[killerid].name .. " arrested for PVP by bot")
			end

			prepareTeleport(killerid, cmd)
			teleport(cmd, true)
				
			players[killerid].prisoner = true
			players[killerid].pvpVictim = victimid
			players[killerid].prisonReason = "PVP against " .. players[victimid].name
			players[killerid].prisonxPosOld = igplayers[killerid].xPosOld
			players[killerid].prisonyPosOld = igplayers[killerid].yPosOld
			players[killerid].prisonzPosOld = igplayers[killerid].zPosOld		

			igplayers[killerid].xPosLastOK = locations["prison"].x
			igplayers[killerid].yPosLastOK = locations["prison"].y
			igplayers[killerid].zPosLastOK = locations["prison"].z
				
			message("pm " .. victimid  .. " [" .. server.chatColour .. "]You may release " .. killerName .. ". Do so at your own risk by typing[-]")
			message("pm " .. victimid  .. " /release " .. players[killerid].id .. " or /release " .. killerName .. "[-]")
						
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[killerid].xPos) .. "," .. math.ceil(igplayers[killerid].yPos) .. "," .. math.floor(igplayers[killerid].zPos) .. ",'" .. serverTime .. "','pvp','Player " .. escape(killerName) .. " sent to prison for killing " .. escape(victimName) .. " at " .. igplayers[killerid].xPos .. " " .. igplayers[killerid].yPos .. " " .. igplayers[killerid].zPos .. "'," .. killerid .. ")")

			if db2Connected then
				-- copy in bots db
				connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.ServerName) .. "','" .. serverTime .. "','pvp','Player " .. escape(killerName) .. " sent to prison for killing " .. escape(victimName) .. " at " .. igplayers[killerid].xPos .. " " .. igplayers[killerid].yPos .. " " .. igplayers[killerid].zPos .. "'," .. killerid .. ")")
			end
		else
			message("say [" .. server.chatColour .. "]" .. killerName .. " has been banned for 1 day, charged with PVP.  Contact an admin to get them unbanned any sooner.[-]")
			irc_QueueMsg(server.ircAlerts, killerName .. " has been banned for 1 day, charged with PVP at " .. igplayers[killerid].xPos .. " " .. igplayers[killerid].yPos .. " " .. igplayers[killerid].zPos)
			kick(killerid, "This is a PVE server.  PVP somewhere else.  An admin may unban you pending the circumstances of the pvp.")
			banPlayer(killerID, "1 day", "PVP", "")
			
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(igplayers[killerid].xPos) .. "," .. math.ceil(igplayers[killerid].yPos) .. "," .. math.floor(igplayers[killerid].zPos) .. ",'" .. serverTime .. "','pvp','Player " .. escape(killerName) .. " banned 1 day for killing " .. escape(victimName) .. " at " .. igplayers[killerid].xPos .. " " .. igplayers[killerid].yPos .. " " .. igplayers[killerid].zPos .. "'," .. killerid .. ")")

			if db2Connected then
				-- copy in bots db
				connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.ServerName) .. "','" .. serverTime .. "','pvp','Player " .. escape(killerName) .. " banned 1 day for killing " .. escape(victimName) .. " at " .. igplayers[killerid].xPos .. " " .. igplayers[killerid].yPos .. " " .. igplayers[killerid].zPos .. "'," .. killerid .. ")")
			end
		end
	end
end
