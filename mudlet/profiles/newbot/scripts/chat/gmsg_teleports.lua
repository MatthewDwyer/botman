--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_teleports()
	calledFunction = "gmsg_teleports"

	local debug
	local shortHelp = false
	local skipHelp = false

	debug = false

if debug then dbug("teleports 0") end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
		return false
	end
	
	if chatvars.showHelp then
		if chatvars.words[3] then		
			if chatvars.words[3] ~= "teleports" then
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
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Teleport Commands:")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "==================")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
	end

if debug then dbug("teleports 1") end

	if (chatvars.words[1] == "killtp") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, "killtp ") + 7)
		tpname = string.trim(tpname)

		if (tpname == "") then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "A name is required for the teleport")
			end

			faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(tpname)

			teleports[tp] = nil
		end

		conn:execute("DELETE FROM teleports WHERE name = '" .. escape(tp) .. "'")
		
		if (chatvars.playername ~= "Server") then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have deleted a teleport called " .. tpname .. "[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "You have deleted a teleport called " .. tpname)
		end		
		
		faultyChat = false
		return true
	end

if debug then dbug("teleports 2") end

	if (chatvars.words[1] == "privatetp") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, "privatetp ") + 10)
		tpname = string.trim(tpname)

		if (tpname == "") then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "A name is required for the teleport")
			end
			
			faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(tpname)

			teleports[tp].public = false
		end
	
		conn:execute("UPDATE teleports SET public = 0 WHERE name = '" .. escape(tp) .. "'")
		
		if (chatvars.playername ~= "Server") then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You changed a teleport called " .. tpname .. " to private[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "You changed a teleport called " .. tpname .. " to private")
		end				

		faultyChat = false
		return true
	end

if debug then dbug("teleports 3") end

	if (chatvars.words[1] == "publictp") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, "publictp ") + 9)
		tpname = string.trim(tpname)

		if (tpname == "") then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "A name is required for the teleport")
			end		
		
			faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(tpname)

			teleports[tp].public = true
		end
		
		conn:execute("UPDATE teleports SET public = 1 WHERE name = '" .. escape(tp) .. "'")
		
		if (chatvars.playername ~= "Server") then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You changed a teleport called " .. tpname .. " to public[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "You changed a teleport called " .. tpname .. " to public")
		end				

		faultyChat = false
		return true
	end

if debug then dbug("teleports 4") end

	if (chatvars.words[1] == "activatetp") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, "activatetp ") + 11)
		tpname = string.trim(tpname)

		if (tpname == "") then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "A name is required for the teleport")
			end

			faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(tpname)

			teleports[tp].active = true
		end
		
		conn:execute("UPDATE teleports SET active = 1 WHERE name = '" .. escape(tp) .. "'")
		
		if (chatvars.playername ~= "Server") then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You enabled a teleport called " .. tpname .. "[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "You enabled a teleport called " .. tpname)
		end

		faultyChat = false
		return true
	end

if debug then dbug("teleports 5") end

	if (chatvars.words[1] == "deactivatetp") then
		if (chatvars.playername ~= "Server") then 
			if (not admins[chatvars.playerid]) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is for admins only[-]")
				faultyChat = false
				return true
			end
		end

		tpname = ""
		tpname = string.sub(chatvars.command, string.find(chatvars.command, "deactivatetp ") + 13)
		tpname = string.trim(tpname)

		if (tpname == "") then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "A name is required for the teleport")
			end

			faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(tpname)

			teleports[tp].active = false
		end
		
		conn:execute("UPDATE teleports SET active = 0 WHERE name = '" .. escape(tp) .. "'")
		
		if (chatvars.playername ~= "Server") then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You disabled a teleport called " .. tpname .. "[-]")
		else
			irc_QueueMsg(players[chatvars.ircid].ircAlias, "You disabled a teleport called " .. tpname)
		end		

		faultyChat = false
		return true
	end

if debug then dbug("teleports 6") end

	if (chatvars.words[1] == "onetp") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		tpname = string.trim(chatvars.words[2])

		tp = ""
		tp = LookupTeleportByName(tpname)

		if (tp ~= "") then
			teleports[tp].oneway = true
			conn:execute("UPDATE teleports SET oneway = 1 WHERE name = '" .. escape(tp) .. "'")			

			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. teleports[tp].name .. " is a one way teleport.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, teleports[tp].name .. " is a one way teleport.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("teleports 7") end

	if (chatvars.words[1] == "twotp") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end

		tpname = string.trim(chatvars.words[2])

		tp = ""
		tp = LookupTeleportByName(tpname)

		if (tp ~= "") then
			teleports[tp].oneway = false
			conn:execute("UPDATE teleports SET oneway = 0 WHERE name = '" .. escape(tp) .. "'")			
			
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. teleports[tp].name .. " is a two way teleport.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, teleports[tp].name .. " is a two way teleport.")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("teleports 8") end

	if (chatvars.words[1] == "owntp") then
		if (chatvars.playername ~= "Server") then 
			if (accessLevel(chatvars.playerid) > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
				faultyChat = false
				return true
			end
		end
		
		id = LookupPlayer(chatvars.words[3]) 
		if (players[id]) then
			pname = players[id].name
		end

		tp = ""
		tp = LookupTeleportByName(chatvars.words[2])

		if (tp ~= "") then
			teleports[tp].owner = id
			conn:execute("UPDATE teleports SET owner = " .. id .. " WHERE name = '" .. escape(tp) .. "'")			
			message("say [" .. server.chatColour .. "]" .. players[id].name .. " is the proud new owner of a teleport called " .. teleports[tp].name .. "[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("teleports 9") end

	-- ###################  do not allow remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

	if (chatvars.words[1] == "enabletp") and (chatvars.playerid ~= 0) then
		id = chatvars.playerid	
		pname = igplayers[chatvars.playerid].name
		
		if (admins[chatvars.playerid] and chatvars.words[2] ~= nil) then
			id = LookupPlayer(string.sub(chatvars.command, string.find(chatvars.command, "enabletp") + 9))
			if (id == nil) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No matching player found.[-]")
				faultyChat = false
				return true		
			else
				players[id].walkies = false
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " can now use teleports[-]")

				conn:execute("UPDATE players SET walkies = 0 WHERE steam = " .. id)

				faultyChat = false
				return true
			end
		end

		players[id].walkies = false
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]you can use teleports and admins can teleport you[-]")
		conn:execute("UPDATE players SET walkies = 0 WHERE steam = " .. id)

		faultyChat = false
		return true
	end

if debug then dbug("teleports 10") end

	if (chatvars.words[1] == "disabletp") and (chatvars.playerid ~= 0) then
		id = chatvars.playerid	
		pname = igplayers[chatvars.playerid].name

		players[id].walkies = true

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]you cannot use teleports and admins can't teleport you (some exceptions)[-]")
		conn:execute("UPDATE players SET walkies = 1 WHERE steam = " .. id)

		faultyChat = false
		return true
	end

if debug then dbug("teleports 11") end

	if (chatvars.words[1] == "fetch") and (chatvars.playerid ~= 0) then
		if (chatvars.words[1] == "fetch") then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "fetch ") + 6)
		end
		
		if (accessLevel(chatvars.playerid) > 2) and players[chatvars.playerid].tokens <= 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A P2P Token is required. Purchase one from the shop in soyspecials.[-]")
			faultyChat = false
			return true					
		end

		pname = string.trim(pname)
		id = LookupPlayer(pname)
		
		if id == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
			faultyChat = false
			return true		
		end

		if not igplayers[id] then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " is not playing right now.[-]")
			faultyChat = false
			return true		
		end

		if (accessLevel(id) < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Staff cannot be fetched.[-]")
			faultyChat = false
			return true
		end
		
		if (accessLevel(chatvars.playerid) > 2) then
			-- reject if not a friend
			if (not isFriend(id,  chatvars.playerid)) and (accessLevel(chatvars.playerid) > 2) and (id ~= chatvars.playerid) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only friends of " .. players[id].name .. " and staff can do this.")

				faultyChat = false
				result = true
				return
			end
		end

		if players[id].xPosOld == nil then
			-- first record their current x y z
			savePosition(id)
		end
		
		-- then teleport the player to you
		cmd = "tele " .. id .. " " .. chatvars.intX + 1 .. " " .. chatvars.intY .. " " .. chatvars.intZ

		if players[id].watchPlayer then
			irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
		end

		prepareTeleport(chatvars.playerid, cmd)
		teleport(cmd, true)

		if (accessLevel(chatvars.playerid) > 2) then
			players[chatvars.playerid].tokens = players[chatvars.playerid].tokens - 1		
		end
		
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is being teleported to your location now.")			
		message("pm " .. id .. " [" .. server.chatColour .. "]You are being teleported to " .. players[chatvars.playerid].name .. "'s location.")					
		
		faultyChat = false
		return true
	end

if debug then dbug("teleports 12") end

	if (chatvars.words[1] == "pack" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then 
		if players[chatvars.playerid].deathX ~= 0 then
			if players[chatvars.playerid].packCooldown > os.time() then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can /pack in " .. os.date("%M minutes %S seconds", players[chatvars.playerid].packCooldown - os.time()) .. " seconds.[-]")
				faultyChat = false
				return true
			end

			cursor,errorString = conn:execute("SELECT x, y, z FROM tracker WHERE steam = " .. chatvars.playerid .. " and ((abs(x - " .. players[chatvars.playerid].deathX .. ") > 0 and abs(x - " .. players[chatvars.playerid].deathX .. ") < 50) and (abs(z - " .. players[chatvars.playerid].deathZ .. ") > 5 and abs(z - " .. players[chatvars.playerid].deathZ .. ") < 50))  ORDER BY trackerid DESC Limit 0, 1")
			if cursor:numrows() > 0 then
				row = cursor:fetch({}, "a")	
				cmd = ("tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z)

				-- first record their current x y z
				savePosition(chatvars.playerid)

				prepareTeleport(chatvars.playerid, cmd)
				teleport(cmd, true)
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry I am unable to find a spot close to your pack to send you there.[-]")
			end

		end

		faultyChat = false
		return true
	end

if debug then dbug("teleports 13") end

	if (chatvars.words[1] == "stuck" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then 
		if (tonumber(chatvars.intY) > 0 and tonumber(chatvars.intY) < 256) and (players[chatvars.playerid].lastCommand ~= chatvars.command)  then
			-- bump the players position up 1 meter y + 1
			send("tele " .. chatvars.playerid .. " " .. math.floor(igplayers[chatvars.playerid].xPos) .. " " .. math.ceil(igplayers[chatvars.playerid].yPos) + 1 .. " " .. math.floor(igplayers[chatvars.playerid].zPos))
		else
			cursor,errorString = conn:execute("SELECT x, y, z FROM tracker WHERE steam = " .. chatvars.playerid .. " AND ((abs(x - " .. chatvars.intX .. ") > 2 and abs(x - " .. chatvars.intX .. ") < 30) and (abs(z - " .. chatvars.intZ .. ") > 2 and abs(z - " .. chatvars.intZ .. ") < 30))  ORDER BY trackerid DESC Limit 0, 1")
			if cursor:numrows() > 0 then
				row = cursor:fetch({}, "a")	
				send("tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y + 1 .. " " .. row.z)
			else
				-- bump the players position up 1 meter y + 1
				send("tele " .. chatvars.playerid .. " " .. math.floor(igplayers[chatvars.playerid].xPos) .. " " .. math.ceil(igplayers[chatvars.playerid].yPos) + 1 .. " " .. math.floor(igplayers[chatvars.playerid].zPos))
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("teleports 14") end

	if ((chatvars.words[1] == "return") and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then 
		-- return to previously recorded x y z
		if tonumber(players[chatvars.playerid].yPosOld) ~= 0 or tonumber(players[chatvars.playerid].yPosOld2) ~= 0 then
			if tonumber(players[chatvars.playerid].yPosOld2) ~= 0 then
				-- the player has teleported within the same location so they are returning to somewhere in that location
				cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].xPosOld2 .. " " .. players[chatvars.playerid].yPosOld2 .. " " .. players[chatvars.playerid].zPosOld2

				if players[chatvars.playerid].watchPlayer then
					irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
				end

				prepareTeleport(chatvars.playerid, cmd)
				teleport(cmd)

				if players[chatvars.playerid].yPos < 1000 then
					players[chatvars.playerid].xPosOld2 = 0
					players[chatvars.playerid].yPosOld2 = 0
					players[chatvars.playerid].zPosOld2 = 0

					conn:execute("UPDATE players SET xPosOld2 = 0, yPosOld2 = 0, zPosOld2 = 0 WHERE steam = " .. chatvars.playerid)
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have another /return available.[-]")
			else
				-- the player has teleported from outside their current location so they are returning to there.
				cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].xPosOld .. " " .. players[chatvars.playerid].yPosOld .. " " .. players[chatvars.playerid].zPosOld

				if players[chatvars.playerid].watchPlayer then
					irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
				end

				prepareTeleport(chatvars.playerid, cmd)
				teleport(cmd)

				if players[chatvars.playerid].yPos < 1000 then
					players[chatvars.playerid].xPosOld = 0
					players[chatvars.playerid].yPosOld = 0
					players[chatvars.playerid].zPosOld = 0
					igplayers[chatvars.playerid].lastLocation = ""

					conn:execute("UPDATE players SET xPosOld = 0, yPosOld = 0, zPosOld = 0 WHERE steam = " .. chatvars.playerid)
				end
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have used all your returns.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("teleports 15") end

	if (chatvars.words[1] == "teleports" and chatvars.words[3] == nil) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		id = nil
		if (chatvars.words[2]) then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "teleports ") + 10)
			pname = string.trim(pname)
			if (pname ~= nil) then id = LookupPlayer(pname) end
		end

		for k, v in pairs(teleports) do
			if (v.public == true) then
				public = "public"
			else
				public = "private"
			end

			if (id == nil) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " " .. public .. "[-]")
			else
				if (v.owner == id) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " " .. public .. "[-]")
				end
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("teleports 16") end

	if (chatvars.words[1] == "tp") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		teleName = ""
		teleName = string.sub(chatvars.command, string.find(chatvars.command, "tp ") + 3)
		teleName = string.trim(teleName)

		if (teleName == "") then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the /tp command[-]")
			faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(teleName)

			-- first record their current x y z
			savePosition(chatvars.playerid)

			cmd = "tele " .. chatvars.playerid .. " " .. math.floor(teleports[tp].x) .. " " .. math.ceil(teleports[tp].y) .. " " .. math.floor(teleports[tp].z)
			prepareTeleport(chatvars.playerid, cmd)
			teleport(cmd, true)
		end

		faultyChat = false
		return true
	end

if debug then dbug("teleports 17") end

	if (chatvars.words[1] == "opentp") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		teleName = ""
		teleName = string.sub(chatvars.command, string.find(chatvars.command, "opentp ") + 7)
		teleName = string.trim(teleName)

		if (teleName == "") then 
			message("pm " .. chatvars.playername .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			faultyChat = false
			return true
		else	
			tp = ""
			tp = LookupTeleportByName(teleName)
			action = "moved"

			if (tp == nil) then
				teleports[teleName] = {}
				action = "created"
				teleports[teleName].public = false
				teleports[teleName].active = false
				teleports[teleName].friends = false
				teleports[teleName].name = teleName
				teleports[teleName].owner = igplayers[chatvars.playerid].steam
				teleports[teleName].oneway = false
		   end

			teleports[teleName].x = chatvars.intX
			teleports[teleName].y = chatvars.intY
			teleports[teleName].z = chatvars.intZ
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have " .. action .. " a teleport called " .. teleName .. "[-]")
		conn:execute("INSERT INTO teleports (name, owner, x, y, z) VALUES ('" .. teleName .. "'," .. chatvars.playerid .. "," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ") ON DUPLICATE KEY UPDATE x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " ..chatvars.intZ)

		faultyChat = false
		return true
	end

if debug then dbug("teleports 18") end

	if (chatvars.words[1] == "closetp") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true								
		end

		teleName = ""
		teleName = string.sub(chatvars.command, string.find(chatvars.command, "closetp ") + 8)
		teleName = string.trim(teleName)

		if (teleName == "") then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A name is required for the teleport[-]")
			faultyChat = false
			return true
		else
			tp = ""
			tp = LookupTeleportByName(teleName)

			if (teleports[tp].owner == igplayers[chatvars.playerid].steam) and (teleports[tp].name == teleName) then
				teleports[tp].dx = chatvars.intX
				teleports[tp].dy = chatvars.intY
				teleports[tp].dz = chatvars.intZ

				if (teleports[tp].x ~= nil) then teleports[tp].active = true end
			end
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have activated a teleport called " .. teleName .. "[-]")
		conn:execute("UPDATE teleports SET dx = " .. teleports[tp].dx .. ", dy = " .. teleports[tp].dy .. ", dz = " .. teleports[tp].dz .. " WHERE name = '" .. escape(tp) .. "'")

		faultyChat = false
		return true
	end

if debug then dbug("teleports end") end

end
