--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_base()
	local id, pname, psize, dist, debug, loc, reset, result, help, tmp
	local shortHelp = false

	debug = false -- should be false unless testing

	calledFunction = "gmsg_base"
	result = false
	tmp = {}
	tmp.topic = "base"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## base command functions ##################

	local function cmd_Base() -- converted 8/7/21
		local baseID, delay, baseFound, base
		local teleportDelay, baseCooldown

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}home (or {#}base) {number or name}\n"
			help[2] = "Teleport back to your base. A timer and/or a cost may apply.\n"
			help[2] = help[2] .. "If you have more than one base use the base number or name otherwise you will go to your first base."

			tmp.command = help[1]
			tmp.keywords = "base,teleport,home,tp"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") and chatvars.showHelp or botman.registerHelp then
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

		if (string.sub(chatvars.words[1], 1, 4) == "base" or string.sub(chatvars.words[1], 1, 4) == "home") and (chatvars.words[1] ~= "bases") and (chatvars.words[1] ~= "homes") and chatvars.wordCount < 3 then
			tmp.baseID = tonumber(string.match(chatvars.words[1], "(-?%d+)"))

			if (not chatvars.isAdmin) and chatvars.settings.hardcore then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command is disabled.[-]")
				botman.faultyChat = false
				return true
			end

			if (not chatvars.isAdmin) and (not chatvars.settings.allowHomeTeleport or not chatvars.settings.allowTeleporting) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Teleporting home is disabled on this server.  Walking is good for you!  Running even more so :D[-]")
				botman.faultyChat = false
				return true
			end

			if (players[chatvars.playerid].timeout == true) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are in timeout. Wait for an admin to " .. server.commandPrefix .. "return you.[-]")
				botman.faultyChat = false
				return true
			end

			if (players[chatvars.playerid].prisoner or not players[chatvars.playerid].canTeleport) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not allowed to use teleports.[-]")
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] ~= nil then
				tmp.baseID = string.sub(chatvars.command, 7, string.len(chatvars.command))
				tmp.baseFound, tmp.base = LookupBase(chatvars.playerid, tmp.baseID)
			else
				if tmp.baseID then
					tmp.baseFound, tmp.base = LookupBase(chatvars.playerid, tmp.baseID)
				else
					tmp.baseFound, tmp.base = LookupBase(chatvars.playerid)
				end
			end

			if not tmp.baseFound then
				if tmp.baseID == "" then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have not set a base yet. Type " .. server.commandPrefix .. "setbase in your base first then " .. server.commandPrefix .. "base will work.[-]")
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I could not find that base or you have not set a base yet. Type " .. server.commandPrefix .. "setbase in your base first then " .. server.commandPrefix .. "base will work.[-]")
				end

				botman.faultyChat = false
				return true
			end

			if not isDestinationAllowed(chatvars.playerid, tmp.base.x, tmp.base.z) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your base is in a restricted area.  Please talk to an admin to assist you.[-]")
				botman.faultyChat = false
				return true
			end

			if chatvars.intY > 0 then
				if (players[chatvars.playerid].walkies == true) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not allowed to use teleports.[-]")
					botman.faultyChat = false
					return true
				end

				if (not chatvars.isAdmin) then
					if (players[chatvars.playerid].baseCooldown - os.time() > 0) then
						if players[chatvars.playerid].baseCooldown - os.time() < 3600 then
							delay = os.date("%M minutes %S seconds",players[chatvars.playerid].baseCooldown - os.time())
						else
							delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].baseCooldown - os.time())
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have to wait " .. delay .. " before you can use " .. server.commandPrefix .. "base again.[-]")
						botman.faultyChat = false
						return true
					end
				end

				-- reject if not an admin and pvpTeleportCooldown is > zero
				if not chatvars.isAdmin and (players[chatvars.playerid].pvpTeleportCooldown - os.time() > 0) then
					if players[chatvars.playerid].pvpTeleportCooldown - os.time() < 3600 then
						delay = os.date("%M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())
					else
						delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].pvpTeleportCooldown - os.time())
					end

					message(string.format("pm %s [%s]You must wait %s before you are allowed to teleport again.", chatvars.userID, server.chatColour, delay))
					botman.faultyChat = false
					return true
				end
			end

			if tonumber(chatvars.settings.baseCost) > 0 and not chatvars.isAdmin then
				if players[chatvars.playerid].cash < tonumber(chatvars.settings.baseCost) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. ".  You need " .. chatvars.settings.baseCost .. ".[-]")
					botman.faultyChat = false
					return true
				else
					players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - chatvars.settings.baseCost
					if botman.dbConnected then conn:execute("UPDATE players SET cash = " .. players[chatvars.playerid].cash .. " WHERE steam = '" .. chatvars.playerid .. "'") end
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]" .. chatvars.settings.baseCost .. " " .. server.moneyPlural .. " has been removed from your cash.[-]")
				end
			end

			-- first record the current x y z
			if (chatvars.isAdminHidden) then
				igplayers[chatvars.playerid].lastLocation = ""
				savePosition(chatvars.playerid)
			else
				igplayers[chatvars.playerid].lastLocation = ""
				players[chatvars.playerid].xPosOld = 0
				players[chatvars.playerid].yPosOld = 0
				players[chatvars.playerid].zPosOld = 0
			end

			players[chatvars.playerid].baseCooldown = (os.time() + chatvars.settings.baseCooldown)

			if botman.dbConnected then conn:execute("UPDATE players SET xPosOld = " .. players[chatvars.playerid].xPosOld .. ", yPosOld = " .. players[chatvars.playerid].yPosOld .. ", zPosOld = " .. players[chatvars.playerid].zPosOld .. ", baseCooldown = " .. players[chatvars.playerid].baseCooldown .. " WHERE steam = '" .. chatvars.playerid .. "'") end

			cmd = "tele " .. chatvars.userID .. " " .. tmp.base.x .. " " .. tmp.base.y .. " " .. tmp.base.z

			-- teleport the player back to their base
			igplayers[chatvars.playerid].tp = 1
			igplayers[chatvars.playerid].hackerTPScore = 0

			if tonumber(chatvars.settings.playerTeleportDelay) == 0 or chatvars.isAdmin then
				teleport(cmd, chatvars.playerid, chatvars.userID)
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You will be teleported to your base in " .. chatvars.settings.playerTeleportDelay .. " seconds.[-]")
				if botman.dbConnected then connSQL:execute("insert into persistentQueue (steam, command, timerDelay) values ('" .. chatvars.playerid .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + chatvars.settings.playerTeleportDelay .. "')") end
				botman.persistentQueueEmpty = false
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_DeleteBase() -- converted 8/7/21
		local baseFound, base, baseOwner, baseID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}delbase {number or name of base}\n"
			help[1] = help[1] .. "Or {#}delbase player {player name} base {number or name of base} (for admins only) or\n"
			help[1] = help[1] .. "Or {#}delbase player {player name} (for admins only)\n"
			help[2] = "Delete a player's base and base protection (in the bot only).  It does not physically delete the base in the game world.\n"
			help[2] = help[2] .. "Players can only delete their own bases.\n"
			help[2] = help[2] .. "If admins specify a player but do not specify a base, the nearest base owned by that player is deleted."

			tmp.command = help[1]
			tmp.keywords = "base,home,delete,remove,clear"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.words[1], "delbase") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.baseOwner = chatvars.playerid

			if (chatvars.isAdminHidden) and chatvars.words[2] then
				if (chatvars.words[2] == "player") then
					if string.find(chatvars.command, " base ") then
						tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, " player ") + 8, string.find(chatvars.command, " base ") - 1)
						tmp.baseID = string.sub(chatvars.command, string.find(chatvars.command, " base ") + 6)
					else
						tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, " player ") + 9)
					end

					tmp.pname = string.trim(tmp.pname)
					tmp.baseOwner = LookupPlayer(tmp.pname)

					if tmp.baseOwner == "0" then
						tmp.baseOwner = LookupArchivedPlayer(tmp.pname)

						if tmp.baseOwner == "0" then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. tmp.pname .. "[-]")
							else
								irc_chat(chatvars.ircAlias, "No player found called " .. tmp.pname)
							end
						else
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.baseOwner].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
							else
								irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.baseOwner].name .. " was archived. Get them to rejoin the server, then repeat this command.")
							end
						end

						botman.faultyChat = false
						return true
					end

					tmp.baseFound, tmp.base = LookupBase(tmp.baseOwner, tmp.baseID)

					if tmp.baseFound then
						tmp.baseNumber = tmp.base.baseNumber
						tmp.baseTitle = tmp.base.title
						conn:execute("DELETE FROM bases WHERE steam = '" .. tmp.base.steam .. "' AND baseNumber = " .. tmp.base.baseNumber)
						bases[tmp.base.steam .. "_" .. tmp.base.baseNumber] = nil
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No base found matching that.[-]")
						else
							irc_chat(chatvars.ircAlias, "No base found matching that.")
						end

						botman.faultyChat = false
						return true
					end
				else
					if (chatvars.words[2]) then
						tmp.baseTitle = string.sub(chatvars.command, string.find(chatvars.command, "delbase ") + 8)
						tmp.temp = tonumber(tmp.baseTitle)

						if tmp.temp ~= nil then
							tmp.baseNumber = tmp.temp
							tmp.baseTitle = nil
							tmp.baseFound, tmp.base = LookupBase(tmp.baseOwner, tmp.baseNumber)
						else
							tmp.baseFound, tmp.base = LookupBase(tmp.baseOwner, tmp.baseTitle)
						end

						if tmp.baseFound then
							tmp.baseNumber = tmp.base.baseNumber
							tmp.baseTitle = tmp.base.title
							conn:execute("DELETE FROM bases WHERE steam = '" .. tmp.base.steam .. "' AND baseNumber = " .. tmp.base.baseNumber)
							bases[tmp.base.steam .. "_" .. tmp.base.baseNumber] = nil
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I could not find that base. Use {#}list bases to view your bases.  You can delete them by number or name or just type {#}delbase to delete your nearest base (use with care).[-]")
							botman.faultyChat = false
							return true
						end
					else
						-- find nearest base owned by player
						tmp.baseFound, tmp.base = getNearestBase(igplayers[tmp.baseOwner].xPos, igplayers[tmp.baseOwner].zPos, tmp.baseOwner)

						if tmp.baseFound then
							conn:execute("DELETE FROM bases WHERE steam = '" .. tmp.base.steam .. "' AND baseNumber = " .. tmp.base.baseNumber)
							bases[tmp.base.steam .. "_" .. tmp.base.baseNumber] = nil
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are homeless! :O[-]")
							botman.faultyChat = false
							return true
						end
					end
				end
			else
				if (chatvars.words[2]) then
					tmp.baseTitle = string.sub(chatvars.command, string.find(chatvars.command, "delbase ") + 8)
					tmp.temp = tonumber(tmp.baseTitle)

					if tmp.temp ~= nil then
						tmp.baseNumber = tmp.temp
						tmp.baseTitle = nil
						tmp.baseFound, tmp.base = LookupBase(tmp.baseOwner, tmp.baseNumber)
					else
						tmp.baseFound, tmp.base = LookupBase(tmp.baseOwner, tmp.baseTitle)
					end

					if tmp.baseFound then
						tmp.baseNumber = tmp.base.baseNumber
						tmp.baseTitle = tmp.base.title
						conn:execute("DELETE FROM bases WHERE steam = '" .. tmp.base.steam .. "' AND baseNumber = " .. tmp.base.baseNumber)
						bases[tmp.base.steam .. "_" .. tmp.base.baseNumber] = nil
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I could not find that base. Use {#}list bases to view your bases.  You can delete them by number or name or just type {#}delbase to delete your nearest base (use with care).[-]")
						botman.faultyChat = false
						return true
					end
				else
					tmp.baseNumber = tonumber(string.match(chatvars.words[1], "(-?%d+)"))

					if tmp.baseNumber then
						tmp.baseFound, tmp.base = LookupBase(tmp.baseOwner, tmp.baseNumber)
					else
						-- find nearest base owned by player
						tmp.baseFound, tmp.base = getNearestBase(igplayers[tmp.baseOwner].xPos, igplayers[tmp.baseOwner].zPos, tmp.baseOwner)
					end

					if tmp.baseFound then
						conn:execute("DELETE FROM bases WHERE steam = '" .. tmp.base.steam .. "' AND baseNumber = " .. tmp.base.baseNumber)
						bases[tmp.base.steam .. "_" .. tmp.base.baseNumber] = nil

						if tmp.base.title ~= "" then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your base number " .. tmp.base.baseNumber .. " called " .. tmp.base.title .. " has been forgotten.[-]")
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your base number " .. tmp.base.baseNumber .. " has been forgotten.[-]")
						end

						botman.faultyChat = false
						return true
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are homeless! :O[-]")
						botman.faultyChat = false
						return true
					end
				end
			end

			if tmp.baseOwner == chatvars.playerid then
				if tmp.base.title ~= "" then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your base number " .. tmp.baseNumber .. " called " .. tmp.base.title .. " has been forgotten.[-]")
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your base number " .. tmp.baseNumber .. " has been forgotten.[-]")
				end
			else
				if tmp.baseTitle ~= "" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.baseOwner].name .. "'s base number " .. tmp.baseNumber .. " called " .. tmp.baseTitle .. " has been removed.[-]")
					else
						irc_chat(server.ircMain, players[tmp.baseOwner].name .. "'s base number " .. tmp.baseNumber .. " called " .. tmp.baseTitle .. " has been removed.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.baseOwner].name .. "'s base number " .. tmp.baseNumber .. " has been removed.[-]")
					else
						irc_chat(server.ircMain, players[tmp.baseOwner].name .. "'s base number " .. tmp.baseNumber .. " has been removed.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBases()
		local baseFound, baseOwner, base, sortedBases
		local k, v, dist, protected, privacy

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list bases\n"
			help[1] = help[1] .. "Or {#}list bases {player name} (admins only)"
			help[2] = "See a numbered list of all of your bases.\n"
			help[2] = help[2] .. "Admins can list any player's bases by including a game id, steam id, or name."

			tmp.command = help[1]
			tmp.keywords = "list,bases"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "base") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "list" and chatvars.words[2] == "bases") or (chatvars.words[1] == "bases" and not chatvars.isAdminHidden) then
			if (chatvars.playername ~= "Server") then
				baseOwner = chatvars.playerid
			else
				baseOwner = chatvars.ircid
			end

			if (chatvars.isAdminHidden) then
				if chatvars.words[3] then
					pname = string.sub(chatvars.command, string.find(chatvars.command, " bases ") + 7)
					pname = string.trim(pname)
					baseOwner = LookupPlayer(pname)

					if baseOwner == "0" then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found called " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if (chatvars.playername ~= "Server") then
				if baseOwner == chatvars.playerid then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your bases..[-]")
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. players[baseOwner].steam .. " " .. players[baseOwner].name .. "'s bases..[-]")
				end
			else
				if baseOwner == chatvars.ircid then
					irc_chat(chatvars.ircAlias, "Your bases..")
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[baseOwner].steam .. " " .. players[baseOwner].name .. "'s bases..")
				end
			end

			sortedBases = sortTable(bases)

			for k,v in ipairs(sortedBases) do
				base = bases[v]

				if base.steam == baseOwner then
					baseFound = true

					if base.protect then
						protected = " protected"
					else
						protected = ""
					end

					if base.keepOut then
						privacy = " [PRIVATE]"
					else
						privacy = " [OPEN]"
					end

					if (chatvars.playername ~= "Server") then
						dist = distancexz(igplayers[baseOwner].xPos, igplayers[baseOwner].zPos, base.x, base.z)
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base " .. string.trim(base.baseNumber .. " " .. base.title) .. protected .. privacy .. " at " .. getMapCoords(tonumber(base.x), tonumber(base.z)) .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "Base #" .. string.trim(base.baseNumber .. " " .. base.title) .. " at " .. base.x .. " " .. base.y .. " " .. base.z .. protected .. privacy)
					end
				end
			end

			if not baseFound then
				if (chatvars.playername ~= "Server") then
					if baseOwner == chatvars.ircid then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your are homeless! :O[-]")
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No bases found.[-]")
					end
				else
					if baseOwner == chatvars.ircid then
						irc_chat(chatvars.ircAlias, "Your are homeless! :O")
					else
						irc_chat(chatvars.ircAlias, "No bases found.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveBaseMember()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}add (or {#}remove) base {number or name of base} member {player name}"
			help[2] = "Add or remove a player as a member of one of your bases.\n"
			help[2] = help[2] .. "You do not need to {#}friend them.\n"
			help[2] = help[2] .. "Only you and the base members are allowed in the base when base protection is set.\n"
			help[2] = help[2] .. "Your friends can't enter the base unless they are members or no members are assigned.\n"
			help[2] = help[2] .. "To remove all base members use {#}clear base members {number or name of base}\n"

			tmp.command = help[1]
			tmp.keywords = "add,remove,base,home,members"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "memb") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and chatvars.words[2] == "base" and chatvars.words[4] == "member" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.wordCount < 5 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]OOPS! You missed a bit.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Expected {#}add (or {#}remove) base {base name or number} member {player name}[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]eg. {#}remove base 2 member joe[-]")
				else
					irc_chat(chatvars.ircAlias, "OOPS! You missed a bit.")
					irc_chat(chatvars.ircAlias, "Expected cmd {#}add (or {#}remove) base {base name or number} member {player name}")
					irc_chat(chatvars.ircAlias, "eg. cmd {#}remove base 2 member joe")
				end

				botman.faultyChat = false
				return true
			end

			tmp.baseNumber = chatvars.words[3]
			tmp.member = string.trim(string.sub(chatvars.command, string.find(chatvars.command, " member ") + 8))

			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.member)

			if tmp.steam == "0" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. tmp.member .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No player found called " .. tmp.member)
				end

				botman.faultyChat = false
				return true
			end

			tmp.baseFound, tmp.base = LookupBase(chatvars.playerid, tmp.baseNumber)

			if not tmp.baseFound then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base " .. tmp.baseNumber .. " did not match any of your bases.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]To list them use {#}list bases[-]")
				else
					irc_chat(chatvars.ircAlias, "Base " .. tmp.baseNumber .. " did not match any of your bases.")
					irc_chat(chatvars.ircAlias, "To list them use {#}list bases")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "add" then
				conn:execute("INSERT INTO baseMembers (baseOwner, baseNumber, baseMember) VALUES ('" .. chatvars.playerid .. "'," .. tmp.base.baseNumber .. ",'" .. tmp.steam .. "')")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. "'s membership of base #" .. tmp.base.baseNumber .. " " .. tmp.base.title  .. " has been [GRANTED][-]")
				else
					irc_chat(chatvars.ircAlias, players[tmp.steam].name .. "'s membership of base #" .. tmp.base.baseNumber .. " " .. tmp.base.title  .. " has been [GRANTED]")
				end

				tempTimer( 2, [[loadBaseMembers()]] )
			else
				conn:execute("DELETE FROM baseMembers WHERE baseOwner = '" .. chatvars.playerid .. "' AND baseNumber = " .. tmp.base.baseNumber .. " AND baseMember = '" .. tmp.steam .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. "'s membership of base #" .. tmp.base.baseNumber .. " " .. tmp.base.title  .. " has been [REVOKED][-]")
				else
					irc_chat(chatvars.ircAlias, players[tmp.steam].name .. "'s membership of base #" .. tmp.base.baseNumber .. " " .. tmp.base.title  .. " has been [REVOKED]")
				end

				tempTimer( 2, [[loadBaseMembers()]] )
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ClearBaseMembers()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}clear base members {number or name of base}"
			help[2] = "Remove all members from the specified base."

			tmp.command = help[1]
			tmp.keywords = "clear,base,home,members"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "memb") or string.find(chatvars.command, "clear") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "clear" and chatvars.words[2] == "base" and chatvars.words[3] == "members" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.wordCount < 4 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]OOPS! You missed a bit.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Expected {#}clear base members {base name or number}[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]eg. {#}clear base members bunker[-]")
				else
					irc_chat(chatvars.ircAlias, "OOPS! You missed a bit.")
					irc_chat(chatvars.ircAlias, "Expected cmd {#}clear base members {base name or number}")
					irc_chat(chatvars.ircAlias, "eg. cmd {#}clear base members bunker")
				end

				botman.faultyChat = false
				return true
			end

			tmp.baseNumber = chatvars.words[4]
			tmp.baseFound, tmp.base = LookupBase(chatvars.playerid, tmp.baseNumber)

			if not tmp.baseFound then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base " .. tmp.baseNumber .. " did not match any of your bases.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]To list them use {#}list bases[-]")
				else
					irc_chat(chatvars.ircAlias, "Base " .. tmp.baseNumber .. " did not match any of your bases.")
					irc_chat(chatvars.ircAlias, "To list them use {#}list bases")
				end

				botman.faultyChat = false
				return true
			end

			conn:execute("DELETE FROM baseMembers WHERE baseOwner = '" .. chatvars.playerid .. "' AND baseNumber = " .. tmp.base.baseNumber)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]All members of base #" .. tmp.base.baseNumber .. " " .. tmp.base.title  .. " have been [EVICTED][-]")
			else
				irc_chat(chatvars.ircAlias, "All members of base #" .. tmp.base.baseNumber .. " " .. tmp.base.title  .. " have been [EVICTED]")
			end

			tempTimer( 2, [[loadBaseMembers()]] )

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBaseMembers()
		local k, v, memberCount

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list base members {number or name of base}"
			help[2] = "List all members of the specified base."

			tmp.command = help[1]
			tmp.keywords = "list,base,home,members"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "memb") or string.find(chatvars.command, "list") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "list" and chatvars.words[2] == "base" and chatvars.words[3] == "members" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.wordCount < 4 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]OOPS! You missed a bit.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Expected {#}list base members {base name or number}[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]eg. {#}list base members bunker[-]")
				else
					irc_chat(chatvars.ircAlias, "OOPS! You missed a bit.")
					irc_chat(chatvars.ircAlias, "Expected cmd {#}list base members {base name or number}")
					irc_chat(chatvars.ircAlias, "eg. cmd {#}list base members bunker")
				end

				botman.faultyChat = false
				return true
			end

			tmp.baseNumber = chatvars.words[4]
			tmp.baseFound, tmp.base = LookupBase(chatvars.playerid, tmp.baseNumber)

			if not tmp.baseFound then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base " .. tmp.baseNumber .. " did not match any of your bases.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]To list them use {#}list bases[-]")
				else
					irc_chat(chatvars.ircAlias, "Base " .. tmp.baseNumber .. " did not match any of your bases.")
					irc_chat(chatvars.ircAlias, "To list them use {#}list bases")
				end

				botman.faultyChat = false
				return true
			end

			memberCount = 0

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base #" .. tmp.baseNumber .. " " .. tmp.base.title .. ":[-]")
			else
				irc_chat(chatvars.ircAlias, "Base #" .. tmp.baseNumber .. " " .. tmp.base.title .. ":")
			end

			for k,v in pairs(baseMembers) do
				if v.baseNumber == tmp.base.baseNumber then
					memberCount = memberCount + 1

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[v.baseMember].name .. "[-]")
					else
						irc_chat(chatvars.ircAlias, players[v.baseMember].name)
					end
				end
			end

			if memberCount == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This base has no members[-]")
				else
					irc_chat(chatvars.ircAlias, "This base has no members")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PauseBaseProtection() -- converted 8/7/21
		local k, v, basePaused, baseNumber, baseTitle, baseUnprotected, temp
		local baseFound, base

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}pause (pause your nearest base)\n"
			help[1] = help[1] .. "Or {#}pause {number or name of base} (pause a specific base)"
			help[2] = "Pause your base protection.\n"
			help[2] = help[2] .. "Only works on your base(s) if you are within 100 metres of them and automatically resumes if you move away or leave the server.\n"
			help[2] = help[2] .. "This allows players who you haven't friended access to your base with you present."

			tmp.command = help[1]
			tmp.keywords = "pause,base,home,protection"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "pause" or chatvars.words[1] == "paws") and chatvars.words[2] ~= "reboot" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = igplayers[chatvars.playerid].name

			if chatvars.words[2] then
				baseTitle = string.sub(chatvars.command, string.len(chatvars.words[1]) + 3)
				temp = tonumber(baseTitle)

				if temp ~= nil then
					baseNumber = temp
					baseTitle = nil
				end

				if baseNumber then
					baseFound, base = LookupBase(chatvars.playerid, baseNumber)
				end

				if baseTitle then
					baseFound, base = LookupBase(chatvars.playerid, baseTitle)
				end

				if baseFound then
					-- attempt to pause a specified base
					dist = distancexz(chatvars.intX, chatvars.intZ, base.x, base.z)

					if (dist < tonumber(base.protectSize) + 100) then
						if base.protect then
							bases[base.steam .. "_" .. base.baseNumber].protectPaused = true
							basePaused = true
							baseNumber = base.baseNumber
							baseTitle = base.title
						else
							baseUnprotected = true
						end
					end
				end
			else
				-- no base specified so find the nearest owned by the player
				for k,v in pairs(bases) do
					if chatvars.playerid == v.steam then
						dist = distancexz(chatvars.intX, chatvars.intZ, v.x, v.z)

						if (dist < tonumber(v.protectSize) + 100) then
							if v.protect then
								v.protectPaused = true
								basePaused = true
								baseNumber = v.baseNumber
								baseTitle = v.title
							else
								baseUnprotected = true
							end
						end
					end
				end
			end

			if basePaused then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your base protection is paused while you are within 100 meters of base " .. string.trim(baseNumber .. " " .. baseTitle) .. "[-]")
			else
				if baseUnprotected then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have not set protection on base " .. string.trim(baseNumber .. " " .. baseTitle) .. " so there is no protection to pause at the moment.[-]")
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are more than 100 blocks away from your base.  Move closer and repeat this command to pause the base protection.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ProtectBase() -- converted 18/7/21
		local k, v, failProtect, failProtectBase, dist, protectCount
		local baseFound, base, baseOwner, baseID, baseKey

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}protect\n"
			help[1] = help[1] .. "Or {#}protect {number or name of base}\n"
			help[1] = help[1] .. "Or {#}protect player {player id or name} (admins only)\n"
			help[1] = help[1] .. "Or {#}protect player {player id or name} base {number or name of base} (admins only)"
			help[2] = "Set up the bot base protection.  The bot will tell you to move towards or away from the base and will\n"
			help[2] = help[2] .. "automatically set protection outside of the base protected area.  Do not set traps for players at the exit point.\n"
			help[2] = help[2] .. "If no base is given, the bot will look for your nearest base.\n"
			help[2] = help[2] .. "You should be inside or very close to the base when using this command."

			tmp.command = help[1]
			tmp.keywords = "base,home,protection"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "protect") or string.find(chatvars.command, "base") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "protect" and chatvars.words[2] ~= "village" and chatvars.words[2] ~= "location" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			baseOwner = chatvars.playerid

			if not chatvars.isAdmin then -- admins can protect bases all day long :D
				protectCount = 0

				for k,v in pairs(bases) do
					if v.steam == chatvars.playerid and v.protect then
						protectCount = protectCount + 1
					end
				end

				if protectCount >= chatvars.settings.maxProtectedBases then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have reached your limit of " .. protectCount .. " active base protects. To protect this base you must remove protection from another one.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.settings.disableBaseProtection then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base protection is disabled on this server.  Use claim blocks instead.[-]")
				botman.faultyChat = false
				return true
			end

			if igplayers[chatvars.playerid].currentLocationPVP and not chatvars.settings.pvpAllowProtect then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base protection is not allowed where PVP rules are in effect.[-]")
				botman.faultyChat = false
				return true
			end

			-- allow base protection after player has played 30 minutes
			if (players[chatvars.playerid].newPlayer == true) and (players[chatvars.playerid].timeOnServer + igplayers[chatvars.playerid].sessionPlaytime < 1800) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command is not available to you yet.  It will be automatically unlocked soon.[-]")
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[2]) then
				if chatvars.words[2] == "player" then
					if chatvars.isAdminHidden then
						-- admin protecting a player's base

						-- get the player name, and base if given
						if string.find(chatvars.command, " base ") then
							pname = string.sub(chatvars.command, 10, string.find(chatvars.command, " base") - 1)
							baseID = string.sub(chatvars.command, string.find(chatvars.command, " base ") + 7)
						else
							-- just get the player name
							pname = string.sub(chatvars.command, 17)
						end

						pname = string.trim(pname)
						baseOwner = LookupPlayer(pname)

						if baseOwner == "0" then
							baseOwner = LookupArchivedPlayer(pname)

							if baseOwner == "0" then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
							else
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[baseOwner].name .. " is archived and not active.[-]")
							end

							botman.faultyChat = false
							return true
						end

						if baseID then
							-- find the specified base owned by a player
							baseFound, base = LookupBase(baseOwner, baseID)
						else
							-- find the nearest base owned by a player
							baseFound, base = getNearestBase(chatvars.intX, chatvars.intZ, baseOwner)
						end

						if baseFound then
							dist = distancexz(chatvars.intX, chatvars.intZ, base.x, base.z)

							if dist > base.protectSize + 300 then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Their base is more than 300 blocks away at " .. base.x " " .. base.y .. " " .. base.z  .. ". Please move closer and try again.[-]")

								botman.faultyChat = false
								return true
							end
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No base found for " .. pname .. ".[-]")

							botman.faultyChat = false
							return true
						end
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This version of the protect command is for admins only.[-]")

						botman.faultyChat = false
						return true
					end
				else
					-- find the specified base
					baseID = string.sub(chatvars.command, 10)
					baseFound, base = LookupBase(baseOwner, baseID)
				end
			else
				-- try to protect the nearest base owned by the player
				baseFound, base = getNearestBase(chatvars.intX, chatvars.intZ, baseOwner)
			end

			if not baseFound then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No base found to protect.[-]")

				botman.faultyChat = false
				return true
			else
				-- check for nearby bases
				failProtect = false

				for k, v in pairs(bases) do
					if v.steam ~= baseOwner then
						dist = distancexz(base.x, base.z, v.x, v.z)

						if (tonumber(dist) < tonumber(v.protectSize)) then
							if not isFriend(v.steam, baseOwner) then
								failProtect = true

								if chatvars.isAdminHidden then
									failProtectBase = k
								end
							end
						end
					end
				end

				if failProtect then
					if chatvars.isAdminHidden then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The base is too close to another base who is not a friend. The other base is " .. string.trim(failProtectBase.baseNumber .. " " .. failProtectBase.title) .. " owned by " .. players[failProtectBase.steam].name .. ".[-]")
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The base is too close to another base who is not a friend.  Protection cannot be enabled at this time.[-]")
					end

					botman.faultyChat = false
					return true
				end

				-- base ok to protect
				dist = distancexz(chatvars.intX, chatvars.intZ, base.x, base.z)

				if (dist < base.protectSize + 1) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are too close to the base, but just walk away and I will set it when you are far enough away.[-]")
					igplayers[chatvars.playerid].alertBaseExit = true
					igplayers[chatvars.playerid].alertBaseKey = base.steam .. "_" .. base.baseNumber
					botman.faultyChat = false
					return true
				end

				if (dist > base.protectSize + 20) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are too far from the base, but just walk towards the base and I will set it when you are close enough.[-]")
					igplayers[chatvars.playerid].alertBaseExit = true
					igplayers[chatvars.playerid].alertBaseKey = base.steam .. "_" .. base.baseNumber
					botman.faultyChat = false
					return true
				end

				-- finally if we got this far, we can set the protection
				baseKey = base.steam .. "_" .. base.baseNumber
				bases[baseKey].exitX = chatvars.intX
				bases[baseKey].exitY = chatvars.intY
				bases[baseKey].exitZ = chatvars.intZ
				bases[baseKey].protect = True

				if botman.dbConnected then conn:execute("UPDATE bases SET exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. " WHERE steam = '" .. base.steam .. "' AND baseNumber = " .. base.baseNumber) end
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base protection has been enabled for base " .. string.trim(base.baseNumber .. " " .. base.title) .. ".[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_NameBase()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}name base {number} {name}"
			help[2] = "Give one of your bases a name or change its name."

			tmp.command = help[1]
			tmp.keywords = "base,home,name"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "name") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "name" and chatvars.words[2] == "base" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[3] == nil or chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Base number required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Base number required.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Base name required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Base name required.")
				end

				botman.faultyChat = false
				return true
			end

			tmp.baseNumber = tonumber(chatvars.words[3])
			tmp.baseName = string.sub(chatvars.commandOld, string.find(chatvars.command, chatvars.words[4]))
			tmp.baseFound, tmp.base = LookupBase(chatvars.playerid, tmp.baseNumber)

			if tmp.baseFound then
				baseKey = chatvars.playerid .. "_" .. tmp.baseNumber
				bases[baseKey].title = tmp.baseName

				if botman.dbConnected then
					conn:execute("UPDATE bases SET title = '" .. escape(tmp.baseName) .. "' WHERE steam = '" .. chatvars.playerid .. "' AND baseNumber = " .. tmp.baseNumber)
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base " .. tmp.baseNumber .. " is now called " .. tmp.baseName .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "Base " .. tmp.baseNumber .. " is now called " .. tmp.baseName)
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]No base " .. tmp.baseNumber .. " found. Use {#}list bases to see your bases.[-]")
				else
					irc_chat(chatvars.ircAlias, "No base " .. tmp.baseNumber .. " found. Use {#}list bases to see your bases.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBase() -- converted 8/7/21
		local baseID, baseFound, base, baseTitle, baseNumber, baseKey, k, v, baseCount, dist

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}sethome (or {#}setbase) {optional number or name}"
			help[2] = "Tell the bot where your base is for base protection, raid alerting and the ability to teleport home."

			tmp.command = help[1]
			tmp.keywords = "base,home,set"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.words[1],"sethome") or string.find(chatvars.words[1],"setbase") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.baseTitle = ""
			tmp.baseCount = 0
			tmp.baseID = tonumber(string.match(chatvars.words[1], "(-?%d+)"))

			for k,v in pairs(bases) do
				if v.steam == chatvars.playerid then
					tmp.baseCount = tmp.baseCount + 1
				end
			end

			if tonumber(tmp.baseCount) >= chatvars.settings.maxBases then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have reached your limit of " .. tmp.baseCount .. " base locations. To set a new base you must delete and old one.[-]")
				botman.faultyChat = false
				return true
			end

			if (players[chatvars.playerid].timeout == true) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are in timeout. Trust me, you don't want your base here.[-]")
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] ~= nil then
				if chatvars.words[2] ~= "base" and chatvars.words[2] ~= "home" then
					tmp.baseID = string.sub(chatvars.commandOld, 10, string.len(chatvars.command))
				else
					tmp.baseID = string.sub(chatvars.commandOld, 11, string.len(chatvars.command))
				end
			end

			if tmp.baseID then
				tmp.baseNumber = tonumber(tmp.baseID)

				if tmp.baseNumber == nil then
					tmp.baseTitle = tmp.baseID
					tmp.baseNumber = getNextBaseNumber(chatvars.playerid)
				end

				tmp.baseFound, tmp.base = LookupBase(chatvars.playerid, tmp.baseID)
			else
				tmp.baseFound, tmp.base = getNearestBase(chatvars.intX, chatvars.intZ, chatvars.playerid)
			end

			loc, reset = inLocation(chatvars.intX, chatvars.intZ)

			if resetRegions[chatvars.region] or reset then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are in a reset zone. Do not set your base here. It will be deleted when this zone is reset.[-]")
				botman.faultyChat = false
				return true
			end

			if (not chatvars.isAdmin) then
				if (players[chatvars.playerid].setBaseCooldown - os.time() > 0) then
					if players[chatvars.playerid].setBaseCooldown - os.time() < 3600 then
						delay = os.date("%M minutes %S seconds",players[chatvars.playerid].setBaseCooldown - os.time())
					else
						delay = os.date("%H hours %M minutes %S seconds",players[chatvars.playerid].setBaseCooldown - os.time())
					end

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have to wait " .. delay .. " before you can set a base again.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if not validBasePosition(chatvars.playerid) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You cannot set the base here.  It is too close to a non-friendly base.[-]")
				botman.faultyChat = false
				return true
			end

			for k, v in pairs(locations) do
				if not v.village then
					dist = distancexz(chatvars.intX, chatvars.intZ, v.x, v.z)

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
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are not allowed to set your base here.[-]")
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are too close to a location.  You are not allowed to set your base here.[-]")
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			-- set the players home coords
			if tmp.baseFound then
				dist = distancexz(chatvars.intX, chatvars.intZ, tmp.base.x, tmp.base.z)
				tmp.protectSize = tmp.base.protectSize
				tmp.baseNumber = tmp.base.baseNumber
			else
				dist = 100000
				tmp.protectSize = chatvars.settings.baseSize
				tmp.baseNumber = getNextBaseNumber(chatvars.playerid)
			end

			if dist <= tonumber(tmp.protectSize) then
				baseKey = tmp.base.steam .. "_" .. tmp.baseNumber
				bases[baseKey].x = chatvars.intX
				bases[baseKey].y = chatvars.intY
				bases[baseKey].z = chatvars.intZ
				bases[baseKey].exitX = chatvars.intX
				bases[baseKey].exitY = chatvars.intY
				bases[baseKey].exitZ = chatvars.intZ
				bases[baseKey].protect = false
				bases[baseKey].keepOut = false

				if botman.dbConnected then
					conn:execute("UPDATE bases SET x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. ", exitX = " .. chatvars.intX .. ", exitY = " .. chatvars.intY .. ", exitZ = " .. chatvars.intZ .. ", protect = 0, keepOut = 0 WHERE steam = '" .. chatvars.playerid .. "' AND baseNumber = " .. tmp.baseNumber)
				end

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your base location has been updated.[-]")
			else
				if not tmp.baseID then
					tmp.baseNumber = getNextBaseNumber(chatvars.playerid)
				else
					--tmp.baseNumber = tmp.baseID
				end

				baseKey = chatvars.playerid .. "_" .. tmp.baseNumber
				bases[baseKey] = {}
				bases[baseKey].steam = chatvars.playerid
				bases[baseKey].baseNumber = tmp.baseNumber
				bases[baseKey].title = tmp.baseTitle
				bases[baseKey].x = chatvars.intX
				bases[baseKey].y = chatvars.intY
				bases[baseKey].z = chatvars.intZ
				bases[baseKey].exitX = chatvars.intX
				bases[baseKey].exitY = chatvars.intY
				bases[baseKey].exitZ = chatvars.intZ
				bases[baseKey].protect = false
				bases[baseKey].keepOut = false
				bases[baseKey].creationTimestamp = os.time()
				bases[baseKey].creationGameDay =  server.gameDay
				bases[baseKey].protectSize = server.baseSize
				bases[baseKey].size = server.baseSize

				if botman.dbConnected then
					conn:execute("INSERT INTO bases (steam, baseNumber, title, x, y, z, exitX, exitY, exitZ, size, creationTimestamp, creationGameDay, protectSize) VALUES ('" .. chatvars.playerid .. "', " .. tmp.baseNumber .. ", '" .. escape(tmp.baseTitle) .."'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. "," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. "," .. server.baseSize .. "," .. os.time() .. "," .. server.gameDay .. "," .. server.baseSize .. ")")
				end

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This is your new base location.[-]")
			end

			if botman.dbConnected then
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','setbase','Player " .. escape(players[chatvars.playerid].name) .. " set a base','" .. chatvars.playerid .. "')")
			end

			removeInvalidHotspots(chatvars.playerid, chatvars.userID)
			irc_chat(server.ircAlerts, players[chatvars.playerid].name .. " has setbase at " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ)
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBaseCooldownTimer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set base cooldown {number in seconds} (default is 2400 or 40 minutes)"
			help[2] = "The {#}base and {#}home command can have a time delay between uses. If you set it to 0 there is no wait time."

			tmp.command = help[1]
			tmp.keywords = "set,base,home,cooldown,timer,delay"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "cool") or string.find(chatvars.command, "timer") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "set" and chatvars.words[2] == "base" and chatvars.words[3] == "cooldown") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				server.baseCooldown = chatvars.number
				conn:execute("UPDATE server SET baseCooldown = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes (" .. chatvars.number .. " seconds) after using " .. server.commandPrefix .. "base before it becomes available again.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes (" .. chatvars.number .. " seconds) after using " .. server.commandPrefix .. "base before it becomes available again.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetSetBaseCooldownTimer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set setbase cooldown {number in seconds} (default is 0)"
			help[2] = "The {#}setbase and {#}sethome command can have a time delay between uses. This hampers abuse of the command to locate hidden bases.\n"
			help[2] = help[2] .. "Note this cooldown is not the base cooldown timer."

			tmp.command = help[1]
			tmp.keywords = "set,base,home,cooldown,timer,delay"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "cool") or string.find(chatvars.command, "timer") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "set" and chatvars.words[2] == "setbase" and chatvars.words[3] == "cooldown") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				server.setBaseCooldown = chatvars.number
				conn:execute("UPDATE server SET setBaseCooldown = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes (" .. chatvars.number .. " seconds) after using " .. server.commandPrefix .. "setbase before it becomes available again.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players must wait " .. math.floor(tonumber(chatvars.number) / 60) .. " minutes (" .. chatvars.number .. " seconds) after using " .. server.commandPrefix .. "setbase before it becomes available again.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBaseCost()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set base cost {number}"
			help[2] = "By default players can type {#}base to return to their base.  You can set a delay and/or a cost before the command is available."

			tmp.command = help[1]
			tmp.keywords = "base,set,cost"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "base") or string.find(chatvars.command, "cost") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "base" and chatvars.words[3] == "cost" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.baseCost = chatvars.number
				conn:execute("UPDATE server SET baseCost = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					if server.baseCost == 0 then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can teleport back to their base for free.[-]")
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players must have at least " .. server.baseCost .. " " .. server.moneyPlural .. " before they can use " .. server.commandPrefix .. "base.[-]")
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


	local function cmd_SetBaseDeadzone()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set base deadzone {distance}"
			help[2] = "Block players setting their base too close to the base of another player who has not friended them.\n"
			help[2] = help[2] .. "The default is 0 which disables this feature.  It does not remove existing bases that are closer than the distance you set here, but they will not be able to redo {#}setbase unless they move further away."

			tmp.command = help[1]
			tmp.keywords = "set,base,deadzone,distance,gap"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "set") or string.find(chatvars.command, "base") or string.find(chatvars.command, "dist") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "set base deadzone") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number then
				chatvars.number = math.abs(chatvars.number)
				if chatvars.number < (server.baseSize * 2) then
					chatvars.number = 0
				end

				if chatvars.number == 0 then
					server.baseDeadzone = 0
					conn:execute("UPDATE server SET baseDeadzone = 0")

					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]The default base separation of 2x base size will be used.", chatvars.userID, server.chatColour))
					else
						irc_chat(chatvars.ircAlias, "The default base separation of 2x base size will be used.")
					end
				else
					server.baseDeadzone = chatvars.number
					conn:execute("UPDATE server SET baseDeadzone = " .. chatvars.number)

					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]Players can {#}setbase no closer than " .. server.baseDeadzone .. " metres from non-friended player bases.", chatvars.userID, server.chatColour))
					else
						irc_chat(chatvars.ircAlias, "Players can {#}setbase no closer than " .. server.baseDeadzone .. " metres from non-friended player bases.")
					end
				end
			else
				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]A number is required.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "A number is required.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBaseForPlayer() -- converted 8/7/21
		local baseKey, baseNumber

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}setplayerbase (or {#}setplayerhome) {player name}"
			help[2] = "Set a player's first base for them where you are standing."

			tmp.command = help[1]
			tmp.keywords = "set,base,home,teleport,home,tp"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "setplayerbase" or chatvars.words[1] == "setplayerhome") and chatvars.words[2] ~= nil and (chatvars.isAdminHidden) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.commandOld, 15)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == "0" then
				id = LookupArchivedPlayer(pname)

				if id == "0" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found called " .. pname)
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if not validBasePosition(chatvars.playerid) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You cannot set the base here.[-]")
				botman.faultyChat = false
				return true
			end

			if (id ~= "0") then
				baseNumber = getNextBaseNumber(id)
				baseKey = id .. "_" .. baseNumber
				bases[baseKey] = {}
				bases[baseKey].steam = id
				bases[baseKey].number = baseNumber
				bases[baseKey].title = ""
				bases[baseKey].x = chatvars.intX
				bases[baseKey].y = chatvars.intY
				bases[baseKey].z = chatvars.intZ
				bases[baseKey].exitX = chatvars.intX
				bases[baseKey].exitY = chatvars.intY
				bases[baseKey].exitZ = chatvars.intZ
				bases[baseKey].protect = false
				bases[baseKey].keepOut = false
				bases[baseKey].creationTimestamp = os.time()
				bases[baseKey].creationGameDay =  server.gameDay
				bases[baseKey].protectSize = server.baseSize

				if botman.dbConnected then
					conn:execute("INSERT INTO bases (steam, baseNumber, title, x, y, z, exitX, exitY, exitZ, size, creationTimestamp, creationGameDay, protectSize) VALUES ('" .. id .. "', " .. baseNumber .. ", ''," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. "," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. "," .. server.baseSize .. "," .. os.time() .. "," .. server.gameDay .. "," .. server.baseSize .. ")")
				end

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[id].name .. "'s base has been set where you are standing.[-]")

				if botman.dbConnected then
					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','setbase','Player " .. escape(players[id].name) .. " set a base','" .. id .. "')")
				end

				irc_chat(server.ircAlerts, players[id].name .. " has setbase at " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetBaseSize() -- converted 18/7/21
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set base {base number} size {number} player {player name}"
			help[2] = "Set the base protection size for a player's base."

			tmp.command = help[1]
			tmp.keywords = "base,home,set,size"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "base") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "set" and chatvars.words[2] == "base" and chatvars.words[4] == "size") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if not string.find(chatvars.command, " player ") then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Missing player keyword.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Expected {#}set base {base number} size {number} player {player name}[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing player keyword.")
					irc_chat(chatvars.ircAlias, "Expected {#}set base {base number} size {number} player {player name}")
				end

				botman.faultyChat = false
				return true
			end

			tmp.baseNumber = math.abs(chatvars.words[3])
			tmp.baseSize = math.abs(chatvars.words[5])
			tmp.player = string.sub(chatvars.command, string.find(chatvars.command, " player ") + 9)
			tmp.playerid = LookupPlayer(tmp.player)

			if tmp.playerid == "0" then
				tmp.playerid = LookupArchivedPlayer(tmp.player)

				if tmp.playerid == "0" then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. tmp.player .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found called " .. tmp.player)
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.playerid].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.playerid].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				end

				botman.faultyChat = false
				return true
			end

			tmp.playerName = players[tmp.playerid].name
			tmp.baseFound, tmp.base = LookupBase(tmp.playerid, tmp.baseNumber)

			if tmp.baseFound then
				bases[tmp.base.steam .. " " .. tmp.base.baseNumber].size = tmp.baseSize
				if botman.dbConnected then conn:execute("UPDATE bases SET size = " .. tmp.baseSize .. " WHERE steam = '" .. tmp.playerid .. "' AND baseNumber = " .. tmp.base.baseNumber) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. tmp.playerName .. "'s base " .. string.trim(tmp.base.baseNumber .. " " .. tmp.base.title) .. " size is now " .. tmp.baseSize .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. tmp.playerName .. "'s base " .. string.trim(tmp.base.baseNumber .. " " .. tmp.base.title) .. " size is now " .. tmp.baseSize)
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base not found.[-]")
				else
					irc_chat(chatvars.ircAlias, "Base not found.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetClearBed() -- converted 18/7/21
		local baseFound, base

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}setbed (or {#}clearbed)"
			help[2] = "When you die, the bot can automatically return you to your first or second base after respawn.\n"
			help[2] = help[2] .. "Set within 50 metres of your base.  The closest base will become your new spawn point after death."

			tmp.command = help[1]
			tmp.keywords = "base,set,clear,bedroll"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "bed") or string.find(chatvars.command, "set") or string.find(chatvars.command, "clear") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "clearbed") then
			players[chatvars.playerid].bed = ""
			if botman.dbConnected then conn:execute("UPDATE players SET bed='', bedX = 0, bedY = 0, bedZ = 0 WHERE steam = '" .. chatvars.playerid .. "'") end
			message(string.format("pm %s [%s]You will no longer spawn at your base after you die.[-]", chatvars.userID, server.chatColour))
			botman.faultyChat = false
			return true
		end

		if (chatvars.words[1] == "setbed") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "setbed makes your nearest base your spawn point after you die.[-]")
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "clearbed stops this and you will spawn randomly after you die.[-]")
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Unlike a real bed, this can't be broken or stolen. Also it doesn't show up on the map or compass.[-]")

			-- find nearest base owned by player
			baseFound, base = getNearestBase(chatvars.intX, chatvars.intZ, chatvars.playerid)

			if baseFound then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You will respawn at base " .. string.trim(base.baseNumber .. " " .. base.title) .. " after a death.[-]")

				if botman.dbConnected then conn:execute("UPDATE players SET bed = 'set', bedX = " .. base.x .. ", bedY = " .. base.y .. ", bedZ = " .. base.z .. " WHERE steam = '" .. chatvars.playerid .. "'") end
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You need to have used {#}setbase before you can use {#}setbed.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetDefaultBaseSize()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set default base size {number in metres or blocks}"
			help[2] = "The default base protection size is 32 blocks (64 diameter).  This default only applies to new players joining the server for the first time.\n"
			help[2] = help[2] .. "Existing base sizes are not changed with this command."

			tmp.command = help[1]
			tmp.keywords = "base,set,clear,size,default"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "base") or string.find(chatvars.command, "size") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "default" and chatvars.words[3] == "base" and chatvars.words[4] == "size" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				server.baseSize = chatvars.number
				conn:execute("UPDATE server SET baseSize = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]The default base protection size is now " .. chatvars.number .. " metres.[-]")
				else
					irc_chat(chatvars.ircAlias, "The default base protection size is now " .. chatvars.number .. " metres.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]You didn't give the new base size.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]eg " .. server.commandPrefix .. "set default base size 25.[-]")
				else
					irc_chat(chatvars.ircAlias, "You didn't give the new base size.")
					irc_chat(chatvars.ircAlias, "eg " .. server.commandPrefix .. "set default base size 25.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxBases()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set max bases {number}"
			help[2] = "By default players can set one base with the bot. This setting applies to every player that is not a member of a group."

			tmp.command = help[1]
			tmp.keywords = "bases,homes,set,max"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "base") or string.find(chatvars.command, "max") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "bases" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.maxBases = chatvars.number
				conn:execute("UPDATE server SET maxBases = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can now have up to " .. server.maxBases .. " if they are not a member of a group.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can now have up to " .. server.maxBases .. " if they are not a member of a group.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxProtectedBases()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set max protected bases {number}"
			help[2] = "By default players can protect one base. This setting applies to every player that is not a member of a group."

			tmp.command = help[1]
			tmp.keywords = "bases,homes,set,max,protection"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "base") or string.find(chatvars.command, "max") or string.find(chatvars.command, "set") or string.find(chatvars.command, "protec") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "protected" and chatvars.words[4] == "bases" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(math.floor(chatvars.number))

				server.maxProtectedBases = chatvars.number
				conn:execute("UPDATE server SET maxProtectedBases = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can now protect up to " .. server.maxProtectedBases .. " if they are not a member of a group.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can now protect up to " .. server.maxProtectedBases .. " if they are not a member of a group.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TestBase() -- converted 9/7/21
		local k, v, protected

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}test base (test your nearest base)\n"
			help[1] = help[1] .. "Or {#}test base {number or name} (test a specific base)"
			help[2] = "Turn your own base protection against you for 30 seconds to test that it works."

			tmp.command = help[1]
			tmp.keywords = "test,base,home,protection"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "test" and chatvars.words[2] == "base") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			for k,v in pairs(bases) do
				if v.steam == chatvars.playerid then
					if v.protect then
						protected = true
					end
				end
			end

			if not protected then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your base(s) have not yet had bot protection yet.[-]")
				botman.faultyChat = false
				return true
			end

			igplayers[chatvars.playerid].protectTest = true
			igplayers[chatvars.playerid].protectTestEnd = os.time() + 30

			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]For the next 30 seconds any protected bases you own will keep you out.[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBaseKeepout()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}base {number or name of base} private (or public)"
			help[2] = "Your friends can visit your bases unless you make them private.\n"
			help[2] = help[2] .. "Private bases can only be visited by you and its base members.\n"
			help[2] = help[2] .. "To keep everyone out; protect the base, make it private and don't add any members."

			tmp.command = help[1]
			tmp.keywords = "base,home,friends,public,private"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "memb") or string.find(chatvars.command, "pub") or string.find(chatvars.command, "priv") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "base" or chatvars.words[1] == "home") and (string.find(chatvars.command, " public") or string.find(chatvars.command, " private")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[3] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Base number required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Base number required.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == "public" or chatvars.words[2] == "private" then
				tmp.baseNumber = chatvars.words[3]
			else
				tmp.baseNumber = chatvars.words[2]
			end

			tmp.baseFound, tmp.base = LookupBase(chatvars.playerid, tmp.baseNumber)

			if tmp.baseFound then
				tmp.baseKey = chatvars.playerid .. "_" .. tmp.base.baseNumber

				if chatvars.words[3] == "public" then
					bases[tmp.baseKey].keepOut = false

					if botman.dbConnected then
						conn:execute("UPDATE bases SET keepOut = 0 WHERE steam = '" .. chatvars.playerid .. "' AND baseNumber = " .. tmp.base.baseNumber)
					end

					if (chatvars.playername ~= "Server") then
						if tmp.base.title ~= "" then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your friends can visit your base # " .. string.trim(tmp.base.baseNumber .. " called " .. tmp.base.title) .. "[-]")
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your friends can visit your base # " .. string.trim(tmp.base.baseNumber .. " " .. tmp.base.title) .. "[-]")
						end
					else
						if tmp.base.title ~= "" then
							irc_chat(chatvars.ircAlias, "Your friends can visit your base # " .. string.trim(tmp.base.baseNumber .. " called " .. tmp.base.title))
						else
							irc_chat(chatvars.ircAlias, "Your friends can visit your base # " .. string.trim(tmp.base.baseNumber .. " " .. tmp.base.title))
						end
					end
				else
					bases[tmp.baseKey].keepOut = true

					if botman.dbConnected then
						conn:execute("UPDATE bases SET keepOut = 1 WHERE steam = '" .. chatvars.playerid .. "' AND baseNumber = " .. tmp.base.baseNumber)
					end

					if (chatvars.playername ~= "Server") then
						if tmp.base.title ~= "" then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base # " .. string.trim(tmp.base.baseNumber .. " called " .. tmp.base.title) .. " is now private.[-]")
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base # " .. string.trim(tmp.base.baseNumber .. " " .. tmp.base.title) .. " is now private.[-]")
						end
					else
						if tmp.base.title ~= "" then
							irc_chat(chatvars.ircAlias, "Base # " .. string.trim(tmp.base.baseNumber .. " called " .. tmp.base.title) .. "  is now private.")
						else
							irc_chat(chatvars.ircAlias, "Base # " .. string.trim(tmp.base.baseNumber .. " " .. tmp.base.title) .. "  is now private.")
						end
					end
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]No base " .. tmp.baseNumber .. " found. Use {#}list bases to see your bases.[-]")
				else
					irc_chat(chatvars.ircAlias, "No base " .. tmp.baseNumber .. " found. Use {#}list bases to see your bases.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBaseProtection()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) base protection"
			help[2] = "Base protection can be turned off server wide.  Players can still use claim blocks for protection.\n"
			help[2] = help[2] .. "Not the same as {#}enable/disable pvp protect which is specifically for allowing the bot's base protection in PVP rules."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,base,home,protection"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "base") or string.find(chatvars.command, "prot") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "base" and chatvars.words[3] == "protection" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "disable" then
				server.disableBaseProtection = true
				conn:execute("UPDATE server SET disableBaseProtection = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Base protection is disabled server wide!  Only claim blocks will protect from player damage now.[-]")
				else
					irc_chat(chatvars.ircAlias, "Base protection is disabled server wide!  Only claim blocks will protect from player damage now.")
				end
			else
				server.disableBaseProtection = false
				conn:execute("UPDATE server SET disableBaseProtection = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Base protection is enabled server wide!  The bot will keep un-friended players out of bases.[-]")
				else
					irc_chat(chatvars.ircAlias, "Base protection is enabled server wide!  The bot will keep un-friended players out of bases.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBaseTeleport()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) base (or home) teleport"
			help[2] = "Enable or disable the home or base teleport command (except for staff)."

			tmp.command = help[1]
			tmp.keywords = "base,enable,disable,home,teleport"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "able") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and (chatvars.words[2] == "base" or chatvars.words[2] == "home") and chatvars.words[3] == "teleport" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "enable") then
				server.allowHomeTeleport = true
				conn:execute("UPDATE server SET allowHomeTeleport = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Players can teleport home.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can teleport home.")
				end
			else
				server.allowHomeTeleport = false
				conn:execute("UPDATE server SET allowHomeTeleport = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]Players are not allowed to teleport home.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players are not allowed to teleport home.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TogglePVPProtection()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) pvp protect"
			help[2] = "By default base protection is disabled where pvp rules apply. You can change that by enabling it."

			tmp.command = help[1]
			tmp.keywords = "pvp,pve,base,home,protection,game,world,rules"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "pvp") or string.find(chatvars.command, "prot") or string.find(chatvars.command, "able") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "able") and chatvars.words[2] == "pvp" and string.find(chatvars.command, "prot") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "enable" then
				server.pvpAllowProtect = true
				conn:execute("UPDATE server SET pvpAllowProtect = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can set base protection where PVP rules apply.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can set base protection where PVP rules apply.")
				end
			else
				server.pvpAllowProtect = false
				conn:execute("UPDATE server SET pvpAllowProtect = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base protection cannot be set where PVP rules apply.[-]")
				else
					irc_chat(chatvars.ircAlias, "Base protection cannot be set where PVP rules apply.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnpauseBaseProtection() -- converted 8/7/21
		local baseFound, base, baseNumber, baseTitle, temp

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}resume (or {#}unpause) (resume your nearest base protection)\n"
		    help[1] = help[1] .. "Or {#}resume (or {#}unpause) {number or name of base} (resume a specific base)"
			help[2] = "Re-activate your base protection."

			tmp.command = help[1]
			tmp.keywords = "pause,base,home,protection"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "resume" or chatvars.words[1] == "unpaws" or chatvars.words[1] == "unpause") and chatvars.words[2] ~= "reboot" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] then
				baseTitle = string.sub(chatvars.command, string.len(chatvars.words[1]) + 3)
				temp = tonumber(baseTitle)

				if temp ~= nil then
					baseNumber = temp
					baseTitle = nil

					baseFound, base = LookupBase(chatvars.playerid, baseNumber)
				else
					baseFound, base = LookupBase(chatvars.playerid, baseTitle)
				end
			else
				baseFound, base = getNearestBase(chatvars.intX, chatvars.intZ, chatvars.playerid)
			end

			if baseFound then
				if not base.basePaused or not base.protect then
					if not base.protect then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base protection for base " .. string.trim(base.baseNumber .. " " .. base.title) .. " is not enabled.[-]")
					else
						if not base.basePaused then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base protection for base " .. string.trim(base.baseNumber .. " " .. base.title) .. " is already active.[-]")
						end
					end
				else
					bases[base.baseNumber .. "_" .. base.title].basePaused = nil
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base protection has resumed for base " .. string.trim(base.baseNumber .. " " .. base.title) .. "[-]")
				end
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I could not find your base.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnprotectBase() -- converted 12/7/21
		local baseFound, base, baseOwner, baseID, allBases, playerName
		local k, v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}unprotectbase {number or base name} (optional)\n"
			help[1] = "Or {#}unprotectbase player {player name} (admins only - unprotect nearest base owned by a specific player)\n"
			help[1] = "Or {#}unprotectbase player {player name} bases (admins only - unprotect all bases owned by a specific player)\n"
			help[1] = "Or {#}unprotectbase player {player name} base {number or name} (admins only - unprotect a specific player's base)"
			help[2] = "Disable base protection.\n"
			help[2] = help[2] .. "The nearest owned base will be unprotected unless you specify a base number or name."

			tmp.command = help[1]
			tmp.keywords = "base,home,protection"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "base") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "unprotectbase") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.isAdminHidden) then
				if string.find(chatvars.command, " player ") then
					if string.find(chatvars.command, " bases ") then
						allBases = true
						playerName = string.sub(chatvars.command, string.find(chatvars.command, " player ") + 9, string.find(chatvars.command, " bases ") - 1)
					end

					if string.find(chatvars.command, " base ") then
						playerName = string.sub(chatvars.command, string.find(chatvars.command, " player ") + 9, string.find(chatvars.command, " base ") - 1)
						baseID = string.sub(chatvars.command, string.find(chatvars.command, " base ") + 7)
					end
				end

				if not playerName then
					baseOwner = chatvars.playerid
				else
					baseOwner = LookupPlayer(playerName)
				end

				if baseOwner == "0" then
					baseOwner = LookupArchivedPlayer(playerName)

					if baseOwner == "0" then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. playerName .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found called " .. playerName)
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[baseOwner].name .. " is archived.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[baseOwner].name .. " is archived.")
						end
					end

					botman.faultyChat = false
					return true
				end

				if baseID then
					baseFound, base = LookupBase(baseOwner, baseID)

					if not baseFound then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No base " .. baseID .. " found for player " .. players[baseOwner].name .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No base " .. baseID .. " found for player " .. players[baseOwner].name)
						end

						botman.faultyChat = false
						return true
					end
				end

				if not allBases and not baseFound then
					-- find nearest base owned by baseOwner
					baseFound, base = getNearestBase(igplayers[baseOwner].xPos, igplayers[baseOwner].zPos, baseOwner)

					if not baseFound then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No base found for player " .. players[baseOwner].name .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No base found for player " .. players[baseOwner].name)
						end

						botman.faultyChat = false
						return true
					end
				end

				if allBases then
					for k,v in pairs(bases) do
						if v.steam == baseOwner then
							v.protect = false
							conn:execute("UPDATE bases SET protect = 0 WHERE steam = '" .. v.steam .. "' AND baseNumber = " .. v.baseNumber)
						end
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]All bases belonging to player " .. players[baseOwner].name .. " have been unprotected.[-]")
					else
						irc_chat(chatvars.ircAlias, "All bases belonging to player " .. players[baseOwner].name .. " have been unprotected.")
					end

					botman.faultyChat = false
					return true
				else
					if baseFound then
						bases[base.steam .. "_" .. base.baseNumber].protect = false
						conn:execute("UPDATE bases SET protect = 0 WHERE steam = '" .. base.steam .. "' AND baseNumber = " .. base.baseNumber)

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Base " .. string.trim(base.baseNumber .. " " .. base.title) .. " belonging to player " .. players[baseOwner].name .. " has been unprotected.[-]")
						else
							irc_chat(chatvars.ircAlias, "Base " .. string.trim(base.baseNumber .. " " .. base.title) .. " belonging to player " .. players[baseOwner].name .. " has been unprotected.")
						end

						botman.faultyChat = false
						return true
					end
				end
			else
				baseOwner = chatvars.playerid

				if chatvars.words[2] then
					baseID = string.sub(chatvars.command, 16)
				else
					-- find nearest base owned by baseOwner
					baseFound, base = getNearestBase(igplayers[baseOwner].xPos, igplayers[baseOwner].zPos, baseOwner)
				end

				if baseFound then
					bases[base.steam .. "_" .. base.baseNumber].protect = false
					conn:execute("UPDATE bases SET protect = 0 WHERE steam = '" .. base.steam .. "' AND baseNumber = " .. base.baseNumber)

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot protection for your base " .. string.trim(base.baseNumber .. " " .. base.title) .. " has been removed.[-]")
					else
						irc_chat(chatvars.ircAlias, "The bot protection for your base " .. string.trim(base.baseNumber .. " " .. base.title) .. " has been removed.")
					end

					botman.faultyChat = false
					return true
				else
					if baseID then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No base " .. baseID .. " found.[-]")
						else
							irc_chat(chatvars.ircAlias, "No base " .. baseID .. " found.")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No base found.[-]")
						else
							irc_chat(chatvars.ircAlias, "No base found.")
						end
					end

					botman.faultyChat = false
					return true
				end
			end
		end
	end

-- ################## End of command functions ##################

if debug then dbug("debug base") end

	if botman.registerHelp then
		if debug then dbug("Registering help - base commands") end

		tmp.topicDescription = "Base commands includes commands for admins to set various restrictions on players using base commands and commands for players to set and protect their base(s)."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Base Commands:")
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

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "base" then
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
		irc_chat(chatvars.ircAlias, "Base Commands:")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "base")
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_DeleteBase()

	if result then
		if debug then dbug("debug cmd_DeleteBase triggered") end
		return result, "cmd_DeleteBase"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBases()

	if result then
		if debug then dbug("debug cmd_ListBases triggered") end
		return result, "cmd_ListBases"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveBaseMember()

	if result then
		if debug then dbug("debug cmd_AddRemoveBaseMember triggered") end
		return result, "cmd_AddRemoveBaseMember"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClearBaseMembers()

	if result then
		if debug then dbug("debug cmd_ClearBaseMembers triggered") end
		return result, "cmd_ClearBaseMembers"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBaseMembers()

	if result then
		if debug then dbug("debug cmd_ListBaseMembers triggered") end
		return result, "cmd_ListBaseMembers"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_NameBase()

	if result then
		if debug then dbug("debug cmd_NameBase triggered") end
		return result, "cmd_NameBase"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBaseCooldownTimer()

	if result then
		if debug then dbug("debug cmd_SetBaseCooldownTimer triggered") end
		return result, "cmd_SetBaseCooldownTimer"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetSetBaseCooldownTimer()

	if result then
		if debug then dbug("debug cmd_SetSetBaseCooldownTimer triggered") end
		return result, "cmd_SetSetBaseCooldownTimer"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBaseCost()

	if result then
		if debug then dbug("debug cmd_SetBaseCost triggered") end
		return result, "cmd_SetBaseCost"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBaseDeadzone()

	if result then
		if debug then dbug("debug cmd_SetBaseDeadzone triggered") end
		return result, "cmd_SetBaseDeadzone"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBaseSize()

	if result then
		if debug then dbug("debug cmd_SetBaseSize triggered") end
		return result, "cmd_SetBaseSize"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetClearBed()

	if result then
		if debug then dbug("debug cmd_SetClearBed triggered") end
		return result, "cmd_SetClearBed"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetDefaultBaseSize()

	if result then
		if debug then dbug("debug cmd_SetDefaultBaseSize triggered") end
		return result, "cmd_SetDefaultBaseSize"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxBases()

	if result then
		if debug then dbug("debug cmd_SetMaxBases triggered") end
		return result, "cmd_SetMaxBases"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxProtectedBases()

	if result then
		if debug then dbug("debug cmd_SetMaxProtectedBases triggered") end
		return result, "cmd_SetMaxProtectedBases"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBaseKeepout()

	if result then
		if debug then dbug("debug cmd_ToggleBaseKeepout triggered") end
		return result, "cmd_ToggleBaseKeepout"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBaseProtection()

	if result then
		if debug then dbug("debug cmd_ToggleBaseProtection triggered") end
		return result, "cmd_ToggleBaseProtection"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_TogglePVPProtection()

	if result then
		if debug then dbug("debug cmd_TogglePVPProtection triggered") end
		return result, "cmd_TogglePVPProtection"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBaseTeleport()

	if result then
		if debug then dbug("debug cmd_ToggleBaseTeleport triggered") end
		return result, "cmd_ToggleBaseTeleport"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnprotectBase()

	if result then
		if debug then dbug("debug cmd_UnprotectBase triggered") end
		return result, "cmd_UnprotectBase"
	end

	if debug then dbug("debug base end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == "0" and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false, ""
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if chatvars.showHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Base Commands (In-Game Only):")
		irc_chat(chatvars.ircAlias, ".")
	end

	result = cmd_Base()

	if result then
		if debug then dbug("debug cmd_Base triggered") end
		return result, "cmd_Base"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_PauseBaseProtection()

	if result then
		if debug then dbug("debug cmd_PauseBaseProtection triggered") end
		return result, "cmd_PauseBaseProtection"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_TestBase()

	if result then
		if debug then dbug("debug cmd_TestBase triggered") end
		return result, "cmd_TestBase"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_ProtectBase()

	if result then
		if debug then dbug("debug cmd_ProtectBase triggered") end
		return result, "cmd_ProtectBase"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnpauseBaseProtection()

	if result then
		if debug then dbug("debug cmd_UnpauseBaseProtection triggered") end
		return result, "cmd_UnpauseBaseProtection"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "homer" and chatvars.words[2] == nil then
		message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Doh![-]")
		botman.faultyChat = false
		return true, "homer"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBase()

	if result then
		if debug then dbug("debug cmd_SetBase triggered") end
		return result, "cmd_SetBase"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetBaseForPlayer()

	if result then
		if debug then dbug("debug cmd_SetBaseForPlayer triggered") end
		return result, "cmd_SetBaseForPlayer"
	end

	if (debug) then dbug("debug base line " .. debugger.getinfo(1).currentline) end

	if botman.registerHelp then
		if debug then dbug("Base commands help registered") end
	end

	if debug then dbug("debug base end") end

	-- can't touch dis
	if true then
		return result, ""
	end
end
