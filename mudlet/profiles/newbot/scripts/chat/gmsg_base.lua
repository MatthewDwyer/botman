--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local id, pname, psize,  words, word, dist, debug, loc, reset, result, help, tmp
local shortHelp = false
local skipHelp = false

debug = false -- should be false unless testing

function gmsg_base()
	calledFunction = "gmsg_base"
	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## base command functions ##################

	local function cmd_SetBaseCost()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set base cost {number}"
			help[2] = "By default players can type {#}base to return to their base.  You can set a delay and/or a cost before the command is available."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "base,set,cost"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "cost") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "base" and chatvars.words[3] == "cost" then
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

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.baseCost = chatvars.number
				conn:execute("UPDATE server SET baseCost = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					if server.baseCost == 0 then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can teleport back to their base for free.[-]")
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players must have at least " .. server.baseCost .. " " .. server.moneyPlural .. " before they can use " .. server.commandPrefix .. "base.[-]")
					end
				else
					if server.baseCost == 0 then
						irc_chat(chatvars.ircAlias, "Players can teleport back to their base for free.")
					else
						irc_chat(chatvars.ircAlias, "Players must have at least " .. server.baseCost .. " " .. server.moneyPlural .. " before they can use " .. server.commandPrefix .. "base.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBaseSize()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set base size {number} {player name}\n"
			help[1] = help[1] .. " {#}set base2 size {number} {player name}"
			help[2] = "Set the base protection size for a player's first or second base."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "base,set,cost"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "base") or string.find(chatvars.command, "set")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set" and (chatvars.words[2] == "base" or chatvars.words[2] == "base2") and chatvars.words[3] == "size") then
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

			pname = ""
			words = {}
			for word in chatvars.command:gmatch("%w+") do table.insert(words, word) end

			id = LookupPlayer(chatvars.words[5])

			if id == 0 then
				id = LookupArchivedPlayer(chatvars.words[5])

				if id == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. chatvars.words[5] .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found called " .. chatvars.words[5])
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if (players[id]) then
				pname = players[id].name
			end

			psize = string.match(chatvars.command, " (%d+)")
			psize = tonumber(psize)

			if (pname == "") then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[2] == "base") then
				if (players[id]) then players[id].protectSize = psize end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .."'s base is protected to " .. psize .. " metres from their base teleport[-]")
				else
					irc_chat(chatvars.ircAlias, players[id].name .."'s base is protected to " .. psize .. " metres from their base teleport")
				end

				if botman.dbConnected then conn:execute("UPDATE players SET protectSize = " .. psize .. " WHERE steam = " .. id) end

				if botman.db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET protectSize = " .. psize .. " WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end
			else
				if (accessLevel(id) < 11) then
					if (players[id]) then players[id].protect2Size = psize end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .."'s 2nd base is protected to " .. psize .. " metres from their base teleport[-]")
					else
						irc_chat(chatvars.ircAlias, players[id].name .."'s 2nd base is protected to " .. psize .. " metres from their base teleport")
					end

					if botman.dbConnected then conn:execute("UPDATE players SET protect2Size = " .. psize .. " WHERE steam = " .. id) end

					if botman.db2Connected then
						-- update player in bots db
						connBots:execute("UPDATE players SET protect2Size = " .. psize .. " WHERE steam = " .. id .. " AND botID = " .. server.botID)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetClearBed()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}setbed/clearbed"
			help[2] = "When you die, the bot can automatically return you to your first or second base after respawn.\n"
			help[2] = help[2] .. "Set within 50 metres of your base.  The closest base will become your new spawn point after death."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "base,set,clear,bed"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "bed") or string.find(chatvars.command, "set") or string.find(chatvars.command, "clear")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "clearbed") then
			players[chatvars.playerid].bed = ""
			message(string.format("pm %s [%s]You will no longer spawn at your base after you die.[-]", chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		if (chatvars.words[1] == "setbed") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "setbed makes your nearest base your spawn point after you die.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "clearbed stops this and you will spawn randomly after you die.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Unlike a real bed, this can't be broken or stolen. Also it doesn't show up on the map or compass.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Use it within 50 metres of your base.[-]")

			dist = distancexz(chatvars.intX, chatvars.intZ, players[chatvars.playerid].homeX, players[chatvars.playerid].homeZ)
			if dist < 50 then
				players[chatvars.playerid].bed = "base1"
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have set your bed at your first base. When you respawn after a death, you will be moved to here.[-]")

				if botman.dbConnected then conn:execute("UPDATE players SET bed = 'base1' WHERE steam = " .. id) end
			end

			if (players[chatvars.playerid].homeX ~= 0 and players[chatvars.playerid].homeZ ~= 0) then
				dist = distancexz(chatvars.intX, chatvars.intZ, players[chatvars.playerid].home2X, players[chatvars.playerid].home2Z)
				if dist < 50 then
					players[chatvars.playerid].bed = "base2"
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will respawn at your second base after death.[-]")

					if botman.dbConnected then conn:execute("UPDATE players SET bed = 'base2' WHERE steam = " .. id) end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetDefaultBaseSize()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set default base size {number in metres or blocks}"
			help[2] = "The default base protection size is 32 blocks (64 diameter).  This default only applies to new players joining the server for the first time.\n"
			help[2] = help[2] .. "Existing base sizes are not changed with this command."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "base,set,clear,size"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "size") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "default" and chatvars.words[3] == "base" and chatvars.words[4] == "size" then
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

			if chatvars.number ~= nil then
				server.baseSize = chatvars.number
				conn:execute("UPDATE server SET baseSize = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]The default base protection size is now " .. chatvars.number .. " metres.[-]")
				else
					irc_chat(chatvars.ircAlias, "The default base protection size is now " .. chatvars.number .. " metres.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You didn't give the new base size.[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]eg " .. server.commandPrefix .. "set default base size 25.[-]")
				else
					irc_chat(chatvars.ircAlias, "You didn't give the new base size.")
					irc_chat(chatvars.ircAlias, "eg " .. server.commandPrefix .. "set default base size 25.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBase()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}sethome (or sethome2)\n"
			help[1] = help[1] .. " {#}setbase (or setbase2)"
			help[2] = "Tell the bot where your first or second base is for base protection, raid alerting and the ability to teleport home."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "base,home,set"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "set")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if ((chatvars.words[1] == "sethome" or chatvars.words[1] == "setbase" or chatvars.words[1] == "sethome2" or chatvars.words[1] == "setbase2") or (chatvars.words[1] == "set" and (chatvars.words[2] == "base" or chatvars.words[2] == "base2" or chatvars.words[2] == "home" or chatvars.words[2] == "home2"))) and chatvars.words[3] == nil then
			if (players[chatvars.playerid].timeout == true) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. Trust me, you don't want your base here.[-]")
				botman.faultyChat = false
				return true
			end

			loc, reset = inLocation(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos)

			if resetRegions[chatvars.region] or reset then --  and (chatvars.accessLevel > 2 or botman.ignoreAdmins == false)
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in a reset zone. Do not set your base here. It will be deleted when this zone is reset.[-]")
				botman.faultyChat = false
				return true
			end

			if not validPosition(chatvars.playerid, true) then
				botman.faultyChat = false
				return true
			end

			for k, v in pairs(locations) do
				if not v.village then
					dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, v.x, v.z)

					if v.size ~= nil then
						psize = v.size
					else
						psize = server.baseSize
					end

					if v.allowBase == true then
						psize = 0
					end

					if dist <= tonumber(psize) then
						if not v.allowBase then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not allowed to set your base here.[-]")
						else
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are too close to a location.  You are not allowed to set your base here.[-]")
						end

						botman.faultyChat = false
						return true
					end
				end
			end

		if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

			-- set the players home coords
			if (chatvars.words[1] == "sethome" or chatvars.words[1] == "setbase" or chatvars.words[2] == "home" or chatvars.words[2] == "base") then
				players[chatvars.playerid].homeX = chatvars.intX
				players[chatvars.playerid].homeY = chatvars.intY
				players[chatvars.playerid].homeZ = chatvars.intZ
				players[chatvars.playerid].exitX = chatvars.intX
				players[chatvars.playerid].exitY = chatvars.intY
				players[chatvars.playerid].exitZ = chatvars.intZ
				players[chatvars.playerid].protect = false
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is your new home location.[-]")

				if botman.dbConnected then
					conn:execute("UPDATE players SET homeX = " .. chatvars.intX .. ", homeY = " .. chatvars.intY .. ", homeZ = " .. chatvars.intZ .. ", exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. ", protect = 0 WHERE steam = " .. chatvars.playerid)
					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','setbase','Player " .. escape(players[chatvars.playerid].name) .. " set a base'," .. chatvars.playerid .. ")")
				end

				removeInvalidHotspots(chatvars.playerid)
				irc_chat(server.ircAlerts, players[chatvars.playerid].name .. " has setbase at " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ)

				if botman.db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET homeX = " .. chatvars.intX .. ", homeY = " .. chatvars.intY .. ", homeZ = " .. chatvars.intZ .. ", exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. ", protect = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end
			else
				if chatvars.accessLevel < 11 then
					players[chatvars.playerid].home2X = chatvars.intX
					players[chatvars.playerid].home2Y = chatvars.intY
					players[chatvars.playerid].home2Z = chatvars.intZ
					players[chatvars.playerid].exit2X = chatvars.intX
					players[chatvars.playerid].exit2Y = chatvars.intY
					players[chatvars.playerid].exit2Z = chatvars.intZ
					players[chatvars.playerid].protect2 = false
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is the location of your 2nd base.[-]")

					if botman.dbConnected then conn:execute("UPDATE players SET home2X = " .. chatvars.intX .. ", home2Y = " .. chatvars.intY .. ", home2Z = " .. chatvars.intZ .. ", exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. ", protect2 = 0 WHERE steam = " .. chatvars.playerid) end
					removeInvalidHotspots(chatvars.playerid)
					irc_chat(server.ircAlerts, players[chatvars.playerid].name .. " has setbase 2 at " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ)

					if botman.db2Connected then
						-- update player in bots db
						connBots:execute("UPDATE players SET home2X = " .. chatvars.intX .. ", home2Y = " .. chatvars.intY .. ", home2Z = " .. chatvars.intZ .. ", exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. ", protect2 = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
					end
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins can have 2 bases. Consider donating. =D[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Please let us know if you are still seeing this message after donating.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ProtectBase()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}protect (or protect2)"
			help[2] = "Set up the bot's base protection.  The bot will tell the player to move towards or away from their base and will\n"
			help[2] = help[2] .. "automatically set protection outside of their base protected area.  Players should not set traps in this area."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "base,home,prot"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "protect") or string.find(chatvars.command, "base")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "protect" or chatvars.words[1] == "protect2") and chatvars.words[2] ~= "village" then
			if server.disableBaseProtection or pvpZone(chatvars.intX, chatvars.intZ) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base protection is disabled on this server.  Use claim blocks instead.[-]")
				botman.faultyChat = false
				return true
			end

			-- allow base protection after player has played 30 minutes
			if (players[chatvars.playerid].newPlayer == true) and (players[chatvars.playerid].timeOnServer + igplayers[chatvars.playerid].sessionPlaytime < 1800) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is not available to you yet.  It will be automatically unlocked soon.[-]")
				botman.faultyChat = false
				return true
			end

			id = chatvars.playerid

			if (chatvars.words[2] ~= nil and chatvars.accessLevel < 3) then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "protect") + 8)
				pname = string.trim(pname)
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if id == 0 then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found called " .. pname)
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
						end
					end

					botman.faultyChat = false
					return true
				end
			end

			if players[chatvars.playerid].inLocation ~= "" then
				if locations[players[chatvars.playerid].inLocation].pvp and not server.pvpAllowProtect then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base protection is not allowed where PVP rules are in effect.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if igplayers[chatvars.playerid].currentLocationPVP and not server.pvpAllowProtect then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base protection is not allowed where PVP rules are in effect.[-]")
				botman.faultyChat = false
				return true
			end

			if not validPosition(chatvars.playerid, true) then
				botman.faultyChat = false
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
					botman.faultyChat = false
					return true
				end

				if (tonumber(dist) >  tonumber(players[id].protectSize) + 20) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are too far from the base, but just walk towards the base and I will set it when you are close enough.[-]")
					igplayers[chatvars.playerid].alertBaseExit = true
					igplayers[chatvars.playerid].alertBaseID = id
					igplayers[chatvars.playerid].alertBase = 1
					botman.faultyChat = false
					return true
				end

				players[id].exitX = chatvars.intX
				players[id].exitY = chatvars.intY
				players[id].exitZ = chatvars.intZ

				if botman.dbConnected then conn:execute("UPDATE players SET exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. " WHERE steam = " .. id) end

				igplayers[chatvars.playerid].alertBaseExit = nil
				igplayers[chatvars.playerid].alertBaseID = nil
				igplayers[chatvars.playerid].alertBase = nil

				if (chatvars.accessLevel < 3) then
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

					if botman.db2Connected then
						-- update player in bots db
						connBots:execute("UPDATE players SET exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. ", protect = 1 WHERE steam = " .. id .. " AND botID = " .. server.botID)
					end
				else
					message("pm " .. id .. " [" .. server.chatColour .. "]Your base is too close to another player base who is not on your friends list.  Protection cannot be enabled.[-]")

					if botman.db2Connected then
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
					botman.faultyChat = false
					return true
				end

				if (tonumber(dist) >  tonumber(players[id].protect2Size) + 20) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are too far from the base, but just walk towards the base and I will set it when you are close enough.[-]")
					igplayers[chatvars.playerid].alertBaseExit = true
					igplayers[chatvars.playerid].alertBaseID = id
					igplayers[chatvars.playerid].alertBase = 2
					botman.faultyChat = false
					return true
				end

				players[id].exit2X = chatvars.intX
				players[id].exit2Y = chatvars.intY
				players[id].exit2Z = chatvars.intZ

				if botman.dbConnected then conn:execute("UPDATE players SET exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. " WHERE steam = " .. id) end

				igplayers[chatvars.playerid].alertBaseExit = nil
				igplayers[chatvars.playerid].alertBaseID = nil
				igplayers[chatvars.playerid].alertBase = nil

				if (chatvars.accessLevel < 3) then
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

					if botman.db2Connected then
						-- update player in bots db
						connBots:execute("UPDATE players SET exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. ", protect2 = 1 WHERE steam = " .. id .. " AND botID = " .. server.botID)
					end
				else
					message("pm " .. id .. " [" .. server.chatColour .. "]Your base is too close to another player base who is not on your friends list.  Protection cannot be enabled.[-]")

					if botman.db2Connected then
						-- update player in bots db
						connBots:execute("UPDATE players SET exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. ", protect2 = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnprotectBase()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}unprotectbase {player name}\n"
			help[1] = help[1] .. " {#}unprotectbase2 {player name}"
			help[2] = "Disable base protection for a player."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "base,home,prot"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "home") or string.find(chatvars.command, "base")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "unprotectbase" or chatvars.words[1] == "unprotectbase2") then
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

			pname = string.sub(chatvars.command, string.find(chatvars.command, "unprotectbase") + 14)
			pname = string.trim(pname)

			if (pname == nil or pname == "") then
				botman.faultyChat = false
				return true
			end

			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if id == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found called " .. pname)
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "unprotectbase") then
				if (players[id]) then players[id].protect = false end
				if botman.dbConnected then conn:execute("UPDATE players SET protect = 0 WHERE steam = " .. id) end

				if botman.db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET protect = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .."'s base is no longer protected[-]")
				else
					irc_chat(server.ircMain, players[id].name .."'s base is no longer protected.")
				end
			else
				if (players[id].donor == true or (accessLevel(id) < 3)) then
					if (players[id]) then players[id].protect2 = false end
					if botman.dbConnected then conn:execute("UPDATE players SET protect2 = 0 WHERE steam = " .. id) end

					if botman.db2Connected then
						-- update player in bots db
						connBots:execute("UPDATE players SET protect2 = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .."'s 2nd base is no longer protected[-]")
					else
						irc_chat(server.ircMain, players[id].name .."'s 2nd base is no longer protected.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors and admins are allowed 2 base protections[-]")
					else
						irc_chat(server.ircMain, "Only donors and admins are allowed 2 base protections.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_DeleteBase()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}delbase/delbase2\n"
			help[1] = help[1] .. " {#}delbase/delbase2 {player name} (for admins only)"
			help[2] = "Delete a player's base and base protection (in the bot only).  It does not physically delete the base in the game world.\n"
			help[2] = help[2] .. "Players can only delete their own bases."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "base,home,del,remo,clear"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "home") or string.find(chatvars.command, "base")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "delbase") then
			id = chatvars.playerid

			if (chatvars.accessLevel < 3) then
				if (chatvars.words[2] ~= nil) then
					pname = string.sub(chatvars.command, string.find(chatvars.command, "delbase") + 8)
					pname = string.trim(pname)
					id = LookupPlayer(pname)

					if id == 0 then
						id = LookupArchivedPlayer(pname)

						if id == 0 then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
							else
								irc_chat(chatvars.ircAlias, "No player found called " .. pname)
							end
						else
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
							else
								irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
							end
						end

						botman.faultyChat = false
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

			if botman.dbConnected then conn:execute("UPDATE players SET homeX = 0, homeY = 0, homeZ = 0, exitX = 0, exitY = 0, exitZ = 0, protect = 0  WHERE steam = " .. id) end

			if botman.db2Connected then
				-- update player in bots db
				connBots:execute("UPDATE players SET homeX = 0, homeY = 0, homeZ = 0, exitX = 0, exitY = 0, exitZ = 0, protect = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
			end

			if id == chatvars.playerid then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your base and base protection has been removed.[-]")
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. "'s base and base protection has been removed.[-]")
				else
					irc_chat(server.ircMain, players[id].name .. "'s base and base protection has been removed.")
				end
			end

			botman.faultyChat = false
			return true
		end

		if chatvars.words[1] == "delbase2" then
			id = chatvars.playerid

			if (chatvars.accessLevel < 3) then
				if (chatvars.words[2] ~= nil) then
					pname = string.sub(chatvars.command, string.find(chatvars.command, "delbase2") + 9)
					pname = string.trim(pname)
					id = LookupPlayer(pname)

					if id == 0 then
						id = LookupArchivedPlayer(pname)

						if id == 0 then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
							else
								irc_chat(chatvars.ircAlias, "No player found called " .. pname)
							end
						else
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
							else
								irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
							end
						end

						botman.faultyChat = false
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

			if botman.dbConnected then conn:execute("UPDATE players SET home2X = 0, home2Y = 0, home2Z = 0, exit2X = 0, exit2Y = 0, exit2Z = 0, protect2 = 0  WHERE steam = " .. id) end

			if botman.db2Connected then
				-- update player in bots db
				connBots:execute("UPDATE players SET home2X = 0, home2Y = 0, home2Z = 0, exit2X = 0, exit2Y = 0, exit2Z = 0, protect2 = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
			end

			if id == chatvars.playerid then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your 2nd base and base protection has been removed.[-]")
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. "'s 2nd base and base protection has been removed.[-]")
				else
					irc_chat(server.ircMain, players[id].name .. "'s 2nd base and base protection has been removed.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBaseTeleport()
		if chatvars.showHelp and not skipHelp then
			if chatvars.words[1] == "help" and (string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "able")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "enable base (or home) teleport")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "disable base (or home) teleport")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Enable or disable the home or base teleport command (except for staff).")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and (chatvars.words[2] == "base" or chatvars.words[2] == "home") and chatvars.words[3] == "teleport" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end


			if (chatvars.words[1] == "enable") then
				server.allowHomeTeleport = true
				conn:execute("UPDATE server SET allowHomeTeleport = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Players can teleport home.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can teleport home.")
				end
			else
				server.allowHomeTeleport = false
				conn:execute("UPDATE server SET allowHomeTeleport = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Players are not allowed to teleport home.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players are not allowed to teleport home.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Base()
		local dist1, dist2, wait

		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and string.find(chatvars.command, "home") or string.find(chatvars.command, "base")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "home (or base)")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "home2 (or base2)")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Teleport back to your first or second base. A timer and/or a cost may apply.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "base" or chatvars.words[1] == "home" or chatvars.words[1] == "base2" or chatvars.words[1] == "home2") and chatvars.words[2] == nil and (chatvars.playerid ~= 0) then
			if isServerHardcore(chatvars.playerid) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is disabled.[-]")
				botman.faultyChat = false
				return true
			end

			if server.coppi then
				-- update the coordinates of the players bedroll
				send("lpb " .. chatvars.playerid)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end

			if (chatvars.accessLevel > 2) and (not server.allowHomeTeleport or not server.allowTeleporting) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting home is disabled on this server.  Walking is good for you!  Running even more so :D[-]")
				botman.faultyChat = false
				return true
			end

			if (chatvars.accessLevel > 10) and (chatvars.words[1] == "base2" or chatvars.words[1] == "home2") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only donors can have 2 base teleports and base protections.  Consider donating =D[-]")
				botman.faultyChat = false
				return true
			end

			if (players[chatvars.playerid].timeout == true) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. Wait for an admin to " .. server.commandPrefix .. "return you.[-]")
				botman.faultyChat = false
				return true
			end

			if (players[chatvars.playerid].prisoner or not players[chatvars.playerid].canTeleport) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not allowed to use teleports.[-]")
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "base" or chatvars.words[1] == "home") and (players[chatvars.playerid].homeY == 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not set a base yet. Type " .. server.commandPrefix .. "setbase in your base first then " .. server.commandPrefix .. "base will work.[-]")

				botman.faultyChat = false
				return true
			end

			if (chatvars.accessLevel < 11) then
				if (chatvars.words[1] == "base2" or chatvars.words[1] == "home2") and (players[chatvars.playerid].home2Y == 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not set a 2nd base yet. Type " .. server.commandPrefix .. "setbase2 in your base first then " .. server.commandPrefix .. "base2 will work.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.words[1] == "base" or chatvars.words[1] == "home") then
				if not isDestinationAllowed(chatvars.playerid, players[chatvars.playerid].homeX, players[chatvars.playerid].homeZ) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your base is in a restricted area.  Please talk to an admin to assist you.[-]")
					botman.faultyChat = false
					return true
				end
			else
				if not isDestinationAllowed(chatvars.playerid, players[chatvars.playerid].home2X, players[chatvars.playerid].home2Z) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your second base is in a restricted area.  Please talk to an admin to assist you.[-]")
					botman.faultyChat = false
					return true
				end
			end

			wait = true

			if chatvars.intY > 0 then
				if (players[chatvars.playerid].walkies == true) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have not opted in to using teleports. Type " .. server.commandPrefix .. "enabletp to opt-in.[-]")
					botman.faultyChat = false
					return true
				end

				dist1 = distancexz(players[chatvars.playerid].xPos, players[chatvars.playerid].zPos, players[chatvars.playerid].homeX, players[chatvars.playerid].homeZ)
				dist2 = distancexz(players[chatvars.playerid].xPos, players[chatvars.playerid].zPos, players[chatvars.playerid].home2X, players[chatvars.playerid].home2Z)

				if (chatvars.words[1] == "base" or chatvars.words[1] == "home") and (tonumber(dist1) < 201) then
					wait = false
				end

				if (chatvars.words[1] == "base2" or chatvars.words[1] == "home2") and (tonumber(dist2) < 201) then
					wait = false
				end

				if (chatvars.accessLevel > 3) then
					if (players[chatvars.playerid].baseCooldown - os.time() > 0) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have to wait " .. os.date("%M minutes %S seconds",players[chatvars.playerid].baseCooldown - os.time()) .. " before you can use " .. server.commandPrefix .. "base again.[-]")
						botman.faultyChat = false
						return true
					end
				end

				-- reject if not an admin and pvpTeleportCooldown is > zero
				if tonumber(chatvars.accessLevel) > 2 and (players[chatvars.playerid].pvpTeleportCooldown - os.time() > 0) then
					message(string.format("pm %s [%s]You must wait %s before you are allowed to teleport again.", chatvars.playerid, server.chatColour, os.date("%M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())))
					botman.faultyChat = false
					return true
				end
			end

			if wait then -- if the player is within 200 metres of the base, there is no charge.
				if tonumber(server.baseCost) > 0 and (chatvars.accessLevel > 3) then
					if players[chatvars.playerid].cash < tonumber(server.baseCost) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. ".  You need " .. server.baseCost .. ".[-]")
						botman.faultyChat = false
						return true
					else
						players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - server.baseCost
						if botman.dbConnected then conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = " .. chatvars.playerid) end
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. server.baseCost .. " " .. server.moneyPlural .. " has been removed from your cash.[-]")
					end
				end
			end

			-- first record the current x y z
			if chatvars.accessLevel < 3 then
				igplayers[chatvars.playerid].lastLocation = ""
				savePosition(chatvars.playerid)
			else
				igplayers[chatvars.playerid].lastLocation = ""
				players[chatvars.playerid].xPosOld = 0
				players[chatvars.playerid].yPosOld = 0
				players[chatvars.playerid].zPosOld = 0
			end

			if wait then
				if players[chatvars.playerid].donor then
					players[chatvars.playerid].baseCooldown = (os.time() + math.floor(tonumber(server.baseCooldown) / 2))
				else
					players[chatvars.playerid].baseCooldown = (os.time() + server.baseCooldown)
				end
			end

			if botman.dbConnected then conn:execute("UPDATE players SET xPosOld = " .. players[chatvars.playerid].xPosOld .. ", yPosOld = " .. players[chatvars.playerid].yPosOld .. ", zPosOld = " .. players[chatvars.playerid].zPosOld .. ", baseCooldown = " .. players[chatvars.playerid].baseCooldown .. " WHERE steam = " .. chatvars.playerid) end

			if (chatvars.words[1] == "base" or chatvars.words[1] == "home") then
				cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].homeX .. " " .. players[chatvars.playerid].homeY .. " " .. players[chatvars.playerid].homeZ
			else
				cmd = "tele " .. chatvars.playerid .. " " .. players[chatvars.playerid].home2X .. " " .. players[chatvars.playerid].home2Y .. " " .. players[chatvars.playerid].home2Z
			end

			-- teleport the player back to their base
			igplayers[chatvars.playerid].tp = 1
			igplayers[chatvars.playerid].hackerTPScore = 0

			if tonumber(server.playerTeleportDelay) == 0 or tonumber(players[chatvars.playerid].accessLevel) < 3 then
				teleport(cmd, chatvars.playerid)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will be teleported to your base in " .. server.playerTeleportDelay .. " seconds.[-]")
				if botman.dbConnected then conn:execute("insert into miscQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBaseForPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and string.find(chatvars.command, "home") or string.find(chatvars.command, "base")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "setbase {player name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "sethome {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Set a player's first base for them where you are standing.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if ((chatvars.words[1] == "setbase" or chatvars.words[1] == "sethome" and chatvars.words[2] ~= nil) and not players[chatvars.playerid].prisoner) and (chatvars.playerid ~= 0) then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type setbase without anything after it.[-]")
				botman.faultyChat = false
				return true
			end

			pname = chatvars.words[chatvars.wordCount]
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if id == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found called " .. pname)
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if not validPosition(chatvars.playerid, true) then
				botman.faultyChat = false
				return true
			end

			if (id ~= 0) then
				players[id].homeX = chatvars.intX
				players[id].homeY = chatvars.intY
				players[id].homeZ = chatvars.intZ
				players[id].exitX = chatvars.intX
				players[id].exitY = chatvars.intY
				players[id].exitZ = chatvars.intZ
				players[id].protectSize = server.baseSize
				players[id].protect = false
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. "'s base has been set at where you are standing.[-]")

				if botman.dbConnected then
					conn:execute("UPDATE players SET protectSize = " .. server.baseSize .. ", homeX = " .. chatvars.intX .. ", homeY = " .. chatvars.intY .. ", homeZ = " .. chatvars.intZ .. ", protect = 0 WHERE steam = " .. id)
					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','setbase','Player " .. escape(players[id].name) .. " set a base'," .. id .. ")")
				end

				irc_chat(server.ircAlerts, players[id].name .. " has setbase at " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ)

				if botman.db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET homeX = " .. chatvars.intX .. ", homeY = " .. chatvars.intY .. ", homeZ = " .. chatvars.intZ .. ", exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. " protect = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end
			end

			botman.faultyChat = false
			return true
		end

		if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and string.find(chatvars.command, "home") or string.find(chatvars.command, "base")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "setbase2 {player name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "sethome2 {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Set a player's second base for them where you are standing.")
					irc_chat(chatvars.ircAlias, ".")
				end
			end
		end

		if ((chatvars.words[1] == "setbase2" or chatvars.words[1] == "sethome2" and chatvars.words[2] ~= nil) and not players[chatvars.playerid].prisoner) and (chatvars.playerid ~= 0) then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type setbase2 without anything after it.[-]")
				botman.faultyChat = false
				return true
			end

			pname = chatvars.words[chatvars.wordCount]
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if id == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found called " .. pname)
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if not validPosition(chatvars.playerid, true) then
				botman.faultyChat = false
				return true
			end

			if (id ~= 0) then
				players[id].home2X = chatvars.intX
				players[id].home2Y = chatvars.intY
				players[id].home2Z = chatvars.intZ
				players[id].exit2X = chatvars.intX
				players[id].exit2Y = chatvars.intY
				players[id].exit2Z = chatvars.intZ
				players[id].protect2Size = server.baseSize
				players[id].protect2 = false
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. "'s 2nd base has been set at where you are standing.[-]")

				if botman.dbConnected then
					conn:execute("UPDATE players SET protect2Size = " .. server.baseSize .. ", home2X = " .. chatvars.intX .. ", home2Y = " .. chatvars.intY .. ", home2Z = " .. chatvars.intZ .. ", protect2 = 0 WHERE steam = " .. id)
					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','setbase','Player " .. escape(players[id].name) .. " set a 2nd base'," .. id .. ")")
				end

				irc_chat(server.ircAlerts, players[id].name .. " has setbase2 at " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ)

				if botman.db2Connected then
					-- update player in bots db
					connBots:execute("UPDATE players SET home2X = " .. chatvars.intX .. ", home2Y = " .. chatvars.intY .. ", home2Z = " .. chatvars.intZ .. ", exit2X = " .. chatvars.intX .. ", exit2Y = " .. chatvars.intY .. ", exit2Z = " .. chatvars.intZ .. " protect2 = 0 WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TestBase()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and string.find(chatvars.command, "home") or string.find(chatvars.command, "base")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "test base")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Turn your own base protection against you for 30 seconds to test that it works.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "test" and chatvars.words[2] == "base") and (chatvars.playerid ~= 0) then
			if players[chatvars.playerid].protect == false and players[chatvars.playerid].protect2 == false then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't have base protection established now.  Type " .. server.commandPrefix .. "protect at your base or " .. server.commandPrefix .. "protect2 at your 2nd base to set it up first.[-]")
				botman.faultyChat = false
				return true
			end

			igplayers[chatvars.playerid].protectTest = true
			igplayers[chatvars.playerid].protectTestEnd = os.time() + 30

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your base protection is active and will keep you out for 30 seconds.[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PauseBaseProtection()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and string.find(chatvars.command, "home") or string.find(chatvars.command, "base")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "pause")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Pause your base protection.")
					irc_chat(chatvars.ircAlias, "Only works on your base(s) if you are within 100 metres of them and automatically resumes if you move away or leave the server.")
					irc_chat(chatvars.ircAlias, "This allows players who you haven't friended access to your base with you present.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if ((chatvars.words[1] == "pause" or chatvars.words[1] == "paws") and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
			pname = igplayers[chatvars.playerid].name

			if (players[chatvars.playerid].protect == false) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't have base protection established now.  An admin is required to set it up or re-establish it.[-]")
				botman.faultyChat = false
				return true
			end

			dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, players[chatvars.playerid].homeX, players[chatvars.playerid].homeZ)
			if (dist < tonumber(players[chatvars.playerid].protectSize) + 100) then
				players[chatvars.playerid].protectPaused = true
			else
				players[chatvars.playerid].protect2Paused = true
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your base protection is disabled while you are within 100 meters of your " .. server.commandPrefix .. "base teleport.[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnpauseBaseProtection()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and string.find(chatvars.command, "home") or string.find(chatvars.command, "base")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "resume or unpause")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Re-activate your base protection.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "resume" or chatvars.words[1] == "unpaws" or chatvars.words[1] == "unpause") and chatvars.words[2] == nil and (chatvars.playerid ~= 0) then
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

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TogglePVPProtection()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "prot") or string.find(chatvars.command, "able"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "enable/disable pvp protect")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "By default base protection is disabled where pvp rules apply. You can change that by enabling it.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.command, "able") and chatvars.words[2] == "pvp" and string.find(chatvars.command, "prot") then
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

			if chatvars.words[1] == "enable" then
				server.pvpAllowProtect = true
				conn:execute("UPDATE server SET pvpAllowProtect = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can set base protection where PVP rules apply.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can set base protection where PVP rules apply.")
				end
			else
				server.pvpAllowProtect = false
				conn:execute("UPDATE server SET pvpAllowProtect = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base protection cannot be set where PVP rules apply.[-]")
				else
					irc_chat(chatvars.ircAlias, "Base protection cannot be set where PVP rules apply.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBaseProtection()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "prot"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "disable base protection")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Base protection can be turned off server wide.  Players can still use claim blocks for protection.")
					irc_chat(chatvars.ircAlias, "Not the same as " .. server.commandPrefix .. "enable/disable pvp protect which is specifically for allowing the bot's base protection in PVP rules.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "base" and chatvars.words[3] == "protection" then
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

			if chatvars.words[1] == "disable" then
				server.disableBaseProtection = true
				conn:execute("UPDATE server SET disableBaseProtection = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Base protection is disabled server wide!  Only claim blocks will protect from player damage now.[-]")
				else
					irc_chat(chatvars.ircAlias, "Base protection is disabled server wide!  Only claim blocks will protect from player damage now.")
				end
			else
				server.disableBaseProtection = false
				conn:execute("UPDATE server SET disableBaseProtection = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Base protection is enabled server wide!  The bot will keep un-friended players out of bases.[-]")
				else
					irc_chat(chatvars.ircAlias, "Base protection is enabled server wide!  The bot will keep un-friended players out of bases.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBaseCooldownTimer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "cool") or string.find(chatvars.command, "timer"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set base cooldown {number in seconds} (default is 2400 or 40 minutes)")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "The " .. server.commandPrefix .. "base or " .. server.commandPrefix .. "home command can have a time delay between uses.  Donors wait half as long.  If you set it to 0 there is no wait time.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set" and chatvars.words[2] == "base" and chatvars.words[3] == "cooldown") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number ~= nil then
				server.baseCooldown = chatvars.number
				conn:execute("UPDATE server SET baseCooldown = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes after using " .. server.commandPrefix .. "base before it becomes available again.[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Donors must wait " .. math.floor((tonumber(chatvars.number) / 60) / 2) .. " minutes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes after using " .. server.commandPrefix .. "base before it becomes available again.")
					irc_chat(chatvars.ircAlias, "Donors must wait " .. math.floor((tonumber(chatvars.number) / 60) / 2) .. " minutes.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

if debug then dbug("debug base") end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - base commands ====")
		dbug("Registering help - base commands")

		tmp = {}
		tmp.topicDescription = "Base commands includes commands for admins to set various restrictions on players using base commands and commands for players to set and protect their base(s)."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'base'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('base', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
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
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Base Commands:")
		irc_chat(chatvars.ircAlias, "==============")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "base")
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_DeleteBase()

	if result then
		if debug then dbug("debug cmd_DeleteBase triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBase()

	if result then
		if debug then dbug("debug cmd_SetBase triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBaseCooldownTimer()

	if result then
		if debug then dbug("debug cmd_SetBaseCooldownTimer triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBaseCost()

	if result then
		if debug then dbug("debug cmd_SetBaseCost triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBaseSize()

	if result then
		if debug then dbug("debug cmd_SetBaseSize triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetClearBed()

	if result then
		if debug then dbug("debug cmd_SetClearBed triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetDefaultBaseSize()

	if result then
		if debug then dbug("debug cmd_SetDefaultBaseSize triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_ProtectBase()

	if result then
		if debug then dbug("debug cmd_ProtectBase triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBaseProtection()

	if result then
		if debug then dbug("debug cmd_ToggleBaseProtection triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_TogglePVPProtection()

	if result then
		if debug then dbug("debug cmd_TogglePVPProtection triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBaseTeleport()

	if result then
		if debug then dbug("debug cmd_ToggleBaseTeleport triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnprotectBase()

	if result then
		if debug then dbug("debug cmd_UnprotectBase triggered") end
		return result
	end

	if debug then dbug("debug base end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == 0 and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Base In-Game Only:")
		irc_chat(chatvars.ircAlias, "===================")
		irc_chat(chatvars.ircAlias, ".")
	end

	result = cmd_Base()

	if result then
		if debug then dbug("debug cmd_Base triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_PauseBaseProtection()

	if result then
		if debug then dbug("debug cmd_PauseBaseProtection triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBaseForPlayer()

	if result then
		if debug then dbug("debug cmd_SetBaseForPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_TestBase()

	if result then
		if debug then dbug("debug cmd_TestBase triggered") end
		return result
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnpauseBaseProtection()

	if result then
		if debug then dbug("debug cmd_UnpauseBaseProtection triggered") end
		return result
	end

	if chatvars.words[1] == "homer" and chatvars.words[2] == nil then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Doh![-]")
		botman.faultyChat = false
		return true
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Base commands help registered ****")
		dbug("Base commands help registered")
		topicID = topicID + 1
	end

	if debug then dbug("debug base end") end

	-- can't touch dis
	if true then
		return result
	end
end
