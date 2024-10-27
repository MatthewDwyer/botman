--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_groups()
	local debug, tmp
	local shortHelp = false

	debug = false -- should be false unless testing

	calledFunction = "gmsg_groups"
	result = false
	tmp = {}
	tmp.topic = "groups"

	if botman.debugAll then
		debug = true -- this should be true
	end

	local function YN(value)
		-- translate true into Yes and false into No for display
		if value then
			return "Yes"
		else
			return "No"
		end
	end

	local function createGroupFields()
		local idx = 1

		-- groupFields is used to validate values in the GroupSetting command.  Rather than having a new command for every setting in playerGroups we can set any value using just one command.
		if type(groupFields) ~= "table" then
			groupFields = {}

			groupFields[idx] = {}
			groupFields[idx].field = "allowGimme"
			groupFields[idx].type = "yn"
			groupFields[idx].caption = "Play Gimme"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "allowHomeTeleport"
			groupFields[idx].caption = "Home teleport"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "allowLottery"
			groupFields[idx].caption = "Play lottery"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "allowPlayerToPlayerTeleporting"
			groupFields[idx].caption = "P2P teleporting"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "allowShop"
			groupFields[idx].caption = "Shop open"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "allowTeleporting"
			groupFields[idx].caption = "Players can teleport"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "allowVisitInPVP"
			groupFields[idx].caption = "Visit pvp areas"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "allowWaypoints"
			groupFields[idx].caption = "Players can set waypoints"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "baseCooldown"
			groupFields[idx].caption = "Base cooldown"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "baseCost"
			groupFields[idx].caption = "Base cost"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 10
			groupFields[idx].field = "baseSize"
			groupFields[idx].caption = "Base size"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "text"
			groupFields[idx].maxLength = 6
			groupFields[idx].field = "chatColour"
			groupFields[idx].caption = "Player name colour"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "deathCost"
			groupFields[idx].caption = "Death cost"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "gimmeZombies"
			groupFields[idx].caption = "Gimme spawns zombies"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "hardcore"
			groupFields[idx].caption = "Hardcore mode"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 1
			groupFields[idx].field = "lotteryMultiplier"
			groupFields[idx].caption = "Lottery multiplier"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 1
			groupFields[idx].field = "lotteryTicketPrice"
			groupFields[idx].caption = "Lottery ticket price"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 512
			groupFields[idx].field = "mapSize"
			groupFields[idx].caption = "Map size"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "maxBases"
			groupFields[idx].caption = "Max bases"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "maxGimmies"
			groupFields[idx].caption = "Max gimmies"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "maxProtectedBases"
			groupFields[idx].caption = "Max active base protects"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "maxWaypoints"
			groupFields[idx].caption = "Max waypoints"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "text"
			groupFields[idx].maxLength = 50
			groupFields[idx].field = "name"
			groupFields[idx].caption = "Group Name"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "text"
			groupFields[idx].maxLength = 20
			groupFields[idx].field = "namePrefix"
			groupFields[idx].caption = "Player name prefix"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "p2pCooldown"
			groupFields[idx].caption = "P2P cooldown"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "packCooldown"
			groupFields[idx].caption = "Pack cooldown"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "packCost"
			groupFields[idx].caption = "Pack cost"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "perMinutePayRate"
			groupFields[idx].caption = "Per minute play payment"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "playerTeleportDelay"
			groupFields[idx].caption = "Player teleport delay"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "pvpAllowProtect"
			groupFields[idx].caption = "Allow protect in pvp areas"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "reserveSlot"
			groupFields[idx].caption = "Players can use reserved slots"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "returnCooldown"
			groupFields[idx].caption = "Return cooldown"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "teleportCost"
			groupFields[idx].caption = "Teleport cost"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "teleportPublicCooldown"
			groupFields[idx].caption = "Public teleport cooldown"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "teleportPublicCost"
			groupFields[idx].caption = "Public teleport cost"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "waypointCooldown"
			groupFields[idx].caption = "Waypoint cooldown"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "waypointCost"
			groupFields[idx].caption = "Waypoint cost"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "waypointCreateCost"
			groupFields[idx].caption = "Waypoint creation cost"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "zombieKillReward"
			groupFields[idx].caption = "Zombie kill payment"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "disableBaseProtection"
			groupFields[idx].caption = "Block setting of base protection"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "setBaseCooldown"
			groupFields[idx].caption = "Cooldown for set base command"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "setWPCooldown"
			groupFields[idx].caption = "Cooldown for set waypoint command"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].min = 0
			groupFields[idx].field = "accessLevel"
			groupFields[idx].caption = "To block access for non-members"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "yn"
			groupFields[idx].field = "donorGroup"
			groupFields[idx].caption = "Flag to identify group as donors"
			idx = idx + 1

			groupFields[idx] = {}
			groupFields[idx].type = "num"
			groupFields[idx].field = "gimmeRaincheck"
			groupFields[idx].caption = "Cooldown for the gimme game"
			idx = idx + 1
		end
	end

-- ################## player group command functions ##################

	local function cmd_AddRemoveGroup()
		local k, v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}add (or {#}remove) group {group name}"
			help[2] = "Add or remove a player group.\n"
			help[2] = help[2] .. "When removing a player group, all players that are members of it will be removed from it."

			tmp.command = help[1]
			tmp.keywords = "add,remove,playergroups"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "remove") or string.find(chatvars.command, "group") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and chatvars.words[2] == "group" and chatvars.words[3] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.group = string.sub(chatvars.commandOld, string.find(chatvars.command, " group ") + 7)

			if chatvars.words[1] == "add" then
				if botman.dbConnected then conn:execute("INSERT INTO playerGroups(name, maxBases, maxProtectedBases, baseSize, baseCooldown, baseCost, maxWaypoints, waypointCost, waypointCooldown, waypointCreateCost, chatColour, teleportCost, packCost, teleportPublicCost, teleportPublicCooldown, returnCooldown, p2pCooldown, playerTeleportDelay, maxGimmies, packCooldown, zombieKillReward, allowLottery, lotteryMultiplier, lotteryTicketPrice, deathCost, mapSize, perMinutePayRate, pvpAllowProtect, gimmeZombies, allowTeleporting, allowShop, allowGimme, hardcore, setBaseCooldown, setWPCooldown, accessLevel, donorGroup) VALUES ('" .. escape(tmp.group) .. "'," .. server.maxBases  .. "," .. server.maxBases  .. "," .. server.baseSize .. "," .. math.floor(server.baseCooldown / 2) .. "," .. server.baseCost .. "," .. server.maxWaypointsDonors .. "," .. server.waypointCost .. "," .. math.floor(server.waypointCooldown / 2) .. "," .. server.waypointCreateCost .. ",'" .. server.chatColourDonor .. "'," .. server.teleportCost .. "," .. server.packCost .. "," .. server.teleportPublicCost .. "," .. server.teleportPublicCooldown .. "," .. math.floor(server.returnCooldown / 2) .. "," .. server.p2pCooldown .. "," .. server.playerTeleportDelay .. ",16," .. math.floor(server.packCooldown / 2) .. ",3," .. dbBool(server.allowLottery) .. "," .. server.lotteryMultiplier .. "," .. server.lotteryTicketPrice .. "," .. server.deathCost .. "," .. server.mapSizePlayers .. "," ..  server.perMinutePayRate .. "," .. dbBool(server.pvpAllowProtect) .. "," .. dbBool(server.gimmeZombies) .. "," .. dbBool(server.allowTeleporting) .. "," .. dbBool(server.allowShop) .. "," .. dbBool(server.allowGimme) .. "," .. dbBool(server.hardcore) .. "," .. server.setBaseCooldown .. "," .. server.setWPCooldown .. ",90,0)") end
				-- reload playerGroups
				tempTimer( 1, [[loadPlayerGroups()]] )

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The group " .. tmp.group .. " has been created with current bot settings.[-]")
				else
					irc_chat(chatvars.ircAlias, "The group " .. tmp.group .. " has been created with current bot settings.")
				end
			else
				-- check that the group exists and grab the groupID
				tmp.groupID, tmp.groupName = LookupPlayerGroup(tmp.group)

				if tmp.groupID == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No group " .. tmp.group .. " found.[-]")
					else
						irc_chat(chatvars.ircAlias, "No group " .. tmp.group .. " found.")
					end

					botman.faultyChat = false
					return true
				else
					if botman.dbConnected then conn:execute("DELETE FROM playerGroups WHERE groupID = " .. tmp.groupID) end

					-- reload playerGroups
					tempTimer( 1, [[loadPlayerGroups()]] )

					for k,v in pairs(players) do
						if v.groupID == tmp.groupID then
							v.groupID = 0
						end
					end

					if botman.dbConnected then conn:execute("UPDATE players SET groupID = 0 WHERE groupID = " .. tmp.groupID) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The group " .. tmp.groupName .. " has been deleted and it's players un-assigned.[-]")
					else
						irc_chat(chatvars.ircAlias, "The group " .. tmp.groupName .. " has been deleted and it's players un-assigned.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_CopyGroup()
		local k, v, cursor, errorString, row

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}copy group {number or name} to {new group name}"
			help[2] = "Make a new group using the settings from an existing group.\n"
			help[2] = help[2] .. "If the new group already exists, it's settings will be replaced with the settings from the first group.\n"
			help[2] = help[2] .. "Player group assignments will not be changed."

			tmp.command = help[1]
			tmp.keywords = "copy,clone,playergroups,duplicate"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "copy") or string.find(chatvars.command, "clone") or string.find(chatvars.command, "group") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "copy" or chatvars.words[1] == "clone") and chatvars.words[2] == "group" and string.find(chatvars.command, " to ") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.oldGroup = string.sub(chatvars.command, string.find(chatvars.command, " group ") + 7, string.find(chatvars.command, " to ") - 1)
			tmp.newGroup = string.sub(chatvars.commandOld, string.find(chatvars.command, " to ") + 4)
			tmp.newGroup = string.trim(tmp.newGroup)

			if tmp.oldGroup then
				-- check that the old group exists and grab the groupID
				tmp.oldGroupID, tmp.groupName = LookupPlayerGroup(tmp.oldGroup)

				if tmp.oldGroupID == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No group " .. tmp.oldGroup .. " found.[-]")
					else
						irc_chat(chatvars.ircAlias, "No group " .. tmp.oldGroup .. " found.")
					end

					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Group to copy from required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Group to copy from required.")
				end

				botman.faultyChat = false
				return true
			end

			if tmp.newGroup then
				-- check that the new group exists and grab it's groupID
				tmp.newGroupID, tmp.groupName = LookupPlayerGroup(tmp.newGroup)

				if tmp.newGroupID == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No group " .. tmp.newGroup .. " found.[-]")
					else
						irc_chat(chatvars.ircAlias, "No group " .. tmp.newGroup .. " found.")
					end

					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New group to copy to is required.[-]")
				else
					irc_chat(chatvars.ircAlias, "New group to copy to is required.")
				end

				botman.faultyChat = false
				return true
			end



			if tmp.newGroupID ~= 0 then
				-- both groups exist already so copy the settings from oldGroup into newGroup
				cursor,errorString = conn:execute("SELECT * from playerGroups WHERE groupID = " .. tmp.oldGroupID)
				row = cursor:fetch({}, "a")

				if row then
					conn:execute("UPDATE playerGroups SET maxBases = " .. row.maxBases .. ", maxProtectedBases = " .. row.maxProtectedBases .. ", baseSize = " .. row.baseSize .. ", baseCooldown = " .. row.baseCooldown .. ", baseCost = " .. row.baseCost .. ", maxWaypoints = " .. row.maxWaypoints .. ", waypointCost = " .. row.waypointCost .. ", waypointCooldown = " .. row.waypointCooldown .. ", waypointCreateCost = " .. row.waypointCreateCost .. ", chatColour = '" .. escape(row.chatColour) .. "', teleportCost = " .. row.teleportCost .. ", packCost = " .. row.packCost .. ", teleportPublicCost = " .. row.teleportPublicCost .. ", teleportPublicCooldown = " .. row.teleportPublicCooldown .. ", returnCooldown = " .. row.returnCooldown .. ", p2pCooldown = " .. row.p2pCooldown .. ", namePrefix = '" .. escape(row.namePrefix) .. "', playerTeleportDelay = " .. row.playerTeleportDelay .. ", maxGimmies = " .. row.maxGimmies .. ", packCooldown = " .. row.packCooldown .. ", zombieKillReward = " .. row.zombieKillReward .. ", allowLottery = " .. row.allowLottery .. ", lotteryMultiplier = " .. row.lotteryMultiplier .. ", lotteryTicketPrice = " .. row.lotteryTicketPrice .. ", deathCost = " .. row.deathCost .. ", mapSize = " .. row.mapSize .. ", perMinutePayRate = " .. row.perMinutePayRate .. ", pvpAllowProtect = " .. row.pvpAllowProtect .. ", gimmeZombies = " .. row.gimmeZombies .. ", allowTeleporting = " .. row.allowTeleporting .. ", allowShop = " .. row.allowShop .. ", allowGimme = " .. row.allowGimme .. ", hardcore = " .. row.hardcore .. ", allowHomeTeleport = " .. row.allowHomeTeleport .. ", allowPlayerToPlayerTeleporting = " .. row.allowPlayerToPlayerTeleporting .. ", allowVisitInPVP = " .. row.allowVisitInPVP .. ", allowWaypoints = " .. row.allowWaypoints .. ", disableBaseProtection = " .. row.disableBaseProtection .. ", setBaseCooldown = " .. row.setBaseCooldown .. ", setWPCooldown = " .. row.setWPCooldown .. ", accessLevel = " .. row.accessLevel .. ", donorGroup = " .. row.donorGroup .. ", gimmeRaincheck = " .. row.gimmeRaincheck  .. " WHERE groupID = " .. tmp.newGroupID)

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The group " .. tmp.newGroup .. " has been updated with settings from group " .. tmp.oldGroup .. ".[-]")
					else
						irc_chat(chatvars.ircAlias, "The group " .. tmp.newGroup .. " has been updated with settings from group " .. tmp.oldGroup)
					end
				end

				-- reload playerGroups
				tempTimer( 1, [[loadPlayerGroups()]] )
			else
				-- make a new group using the settings from the old group
				if botman.dbConnected then conn:execute("INSERT INTO playerGroups (name, maxBases, maxProtectedBases, baseSize, baseCooldown, baseCost, maxWaypoints, waypointCost, waypointCooldown, waypointCreateCost, chatColour, teleportCost, packCost, teleportPublicCost, teleportPublicCooldown, returnCooldown, p2pCooldown, playerTeleportDelay, maxGimmies, packCooldown, zombieKillReward, allowLottery, lotteryMultiplier, lotteryTicketPrice, deathCost, mapSize, perMinutePayRate, pvpAllowProtect, gimmeZombies, allowTeleporting, allowShop, allowGimme, hardcore, allowHomeTeleport, allowPlayerToPlayerTeleporting, allowVisitInPVP, reserveSlot, allowWaypoints, disableBaseProtection, setBaseCooldown, setWPCooldown, accessLevel, donorGroup, gimmeRaincheck) SELECT '" .. escape(tmp.newGroup) .. "', maxBases, maxProtectedBases, baseSize, baseCooldown, baseCost, maxWaypoints, waypointCost, waypointCooldown, waypointCreateCost, chatColour, teleportCost, packCost, teleportPublicCost, teleportPublicCooldown, returnCooldown, p2pCooldown, playerTeleportDelay, maxGimmies, packCooldown, zombieKillReward, allowLottery, lotteryMultiplier, lotteryTicketPrice, deathCost, mapSize, perMinutePayRate, pvpAllowProtect, gimmeZombies, allowTeleporting, allowShop, allowGimme, hardcore, allowHomeTeleport, allowPlayerToPlayerTeleporting, allowVisitInPVP, reserveSlot, allowWaypoints, disableBaseProtection, setBaseCooldown, setWPCooldown, accessLevel, donorGroup, gimmeRaincheck FROM playerGroups WHERE groupID = " .. tmp.oldGroupID) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The new group " .. tmp.newGroup .. " has been created from group " .. tmp.oldGroup .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "The new group " .. tmp.newGroup .. " has been created from group " .. tmp.oldGroup)
				end

				-- reload playerGroups
				tempTimer( 1, [[loadPlayerGroups()]] )
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_EmptyGroup()
		local k, v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}empty group {group number or name}"
			help[2] = "Remove all members of the group."

			tmp.command = help[1]
			tmp.keywords = "empty,playergroups,clear"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "empty") or string.find(chatvars.command, "group") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "empty" and chatvars.words[2] == "group" and chatvars.words[3] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.group = string.sub(chatvars.command, string.find(chatvars.command, " group ") + 7)

			-- check that the group exists
			tmp.groupID, tmp.groupName = LookupPlayerGroup(tmp.group)

			if tmp.groupID == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Group number or name required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Group number or name required.")
				end
			else
				if botman.dbConnected then conn:execute("UPDATE players SET groupID = 0 WHERE groupID = " .. tmp.groupID) end

				for k,v in pairs(players) do
					if v.groupID == tmp.groupID then
						v.groupID = 0
					end
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The group " .. tmp.groupName .. " now has no members.[-]")
				else
					irc_chat(chatvars.ircAlias, "The group " .. tmp.groupName .. " now has no members.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListGroups()
		local group, sortedGroups, k, v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list groups"
			help[2] = "See a numbered list of the player groups."

			tmp.command = help[1]
			tmp.keywords = "list,playergroups"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "group") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "list" and chatvars.words[2] == "groups" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			sortedGroups = sortTable(playerGroups)

			for k,v in ipairs(sortedGroups) do
				group = playerGroups[v]
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Group " .. string.match(v, "%d+") .. " " .. group.name .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Group #" .. string.match(v, "%d+") .. " " .. group.name)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListGroup()
		local k, v, search

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list group {number or name}"
			help[2] = "View a group's current settings."

			tmp.command = help[1]
			tmp.keywords = "list,playergroups"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "group") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "list" and chatvars.words[2] == "group" and chatvars.words[3] ~= nil and chatvars.words[3] ~= "members" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			search = string.sub(chatvars.command, string.find(chatvars.command, " group ") + 7)

			for k,v in pairs(playerGroups) do
				if (tostring(v.groupID) == tostring(search)) or (string.lower(v.name) == search) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Group " .. v.groupID .. " " .. v.name .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]1  Play Gimme " .. " " .. YN(v.allowGimme) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]2  Home teleport " .. " " .. YN(v.allowHomeTeleport) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]3  Play lottery " .. " " .. YN(v.allowLottery) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]4  P2P teleporting " .. " " .. YN(v.allowPlayerToPlayerTeleporting) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]5  Shop open " .. " " .. YN(v.allowShop) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]6  Players can teleport " .. " " .. YN(v.allowTeleporting) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]7  Visit pvp areas " .. " " .. YN(v.allowVisitInPVP) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]8  Can use waypoints " .. " " .. YN(v.allowWaypoints) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]9  Base cooldown " .. " " .. v.baseCooldown .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]10 Base cost " .. " " .. v.baseCost .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]11 Base size " .. " " .. v.baseSize .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]12 Player name colour " .. " " .. v.chatColour .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]13 Death cost " .. " " .. v.deathCost .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]14 Gimme spawns zombies " .. " " .. YN(v.gimmeZombies) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]15 Hardcore mode " .. " " .. YN(v.hardcore) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]16 Lottery multiplier " .. " " .. v.lotteryMultiplier .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]17 Lottery ticket price " .. " " .. v.lotteryTicketPrice .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]18 Map size " .. " " .. v.mapSize .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]19 Max bases " .. " " .. v.maxBases .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]20 Max gimmies " .. " " .. v.maxGimmies .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]21 Max active base protects " .. " " .. v.maxProtectedBases .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]22 Max waypoints " .. " " .. v.maxWaypoints .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]23 Group name " .. " " .. v.name .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]24 Player name prefix " .. " " .. v.namePrefix .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]25 P2P cooldown " .. " " .. v.p2pCooldown .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]26 Pack cooldown " .. " " .. v.packCooldown .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]27 Pack cost " .. " " .. v.packCost .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]28 Per minute play payment " .. " " .. v.perMinutePayRate .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]29 Player teleport delay " .. " " .. v.playerTeleportDelay .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]30 Allow protect in pvp areas " .. " " .. YN(v.pvpAllowProtect) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]31 Can reserve a slot " .. " " .. YN(v.reserveSlot) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]32 Return cooldown " .. " " .. v.returnCooldown .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]33 Teleport cost " .. " " .. v.teleportCost .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]34 Public teleport cooldown " .. " " .. v.teleportPublicCooldown .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]35 Public teleport cost " .. " " .. v.teleportPublicCost .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]36 Waypoint cooldown " .. " " .. v.waypointCooldown .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]37 Waypoint cost " .. " " .. v.waypointCost .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]38 Waypoint creation cost " .. " " .. v.waypointCreateCost .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]39 Zombie kill payment " .. " " .. v.zombieKillReward .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]40 Block setting base protection " .. " " .. YN(v.disableBaseProtection) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]41 Cooldown for set base " .. " " .. v.setBaseCooldown .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]42 Cooldown for set waypoint " .. " " .. v.setWPCooldown .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]43 Access level " .. " " .. v.accessLevel .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]44 A donor group " .. " " .. YN(v.donorGroup) .. "[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]45 Cooldown for gimme " .. " " .. v.gimmeRaincheck .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "Group #" .. v.groupID .. " " .. v.name)
						irc_chat(chatvars.ircAlias, "1  Play Gimme " .. " " .. YN(v.allowGimme))
						irc_chat(chatvars.ircAlias, "2  Home teleport " .. " " .. YN(v.allowHomeTeleport))
						irc_chat(chatvars.ircAlias, "3  Play lottery " .. " " .. YN(v.allowLottery))
						irc_chat(chatvars.ircAlias, "4  P2P teleporting " .. " " .. YN(v.allowPlayerToPlayerTeleporting))
						irc_chat(chatvars.ircAlias, "5  Shop open " .. " " .. YN(v.allowShop))
						irc_chat(chatvars.ircAlias, "6  Players can teleport " .. " " .. YN(v.allowTeleporting))
						irc_chat(chatvars.ircAlias, "7  Visit pvp areas " .. " " .. YN(v.allowVisitInPVP))
						irc_chat(chatvars.ircAlias, "8  Can use waypoints " .. " " .. YN(v.allowWaypoints))
						irc_chat(chatvars.ircAlias, "9  Base cooldown " .. " " .. v.baseCooldown)
						irc_chat(chatvars.ircAlias, "10 Base cost " .. " " .. v.baseCost)
						irc_chat(chatvars.ircAlias, "11 Base size " .. " " .. v.baseSize)
						irc_chat(chatvars.ircAlias, "12 Player name colour " .. " " .. v.chatColour)
						irc_chat(chatvars.ircAlias, "13 Death cost " .. " " .. v.deathCost)
						irc_chat(chatvars.ircAlias, "14 Gimme spawns zombies " .. " " .. YN(v.gimmeZombies))
						irc_chat(chatvars.ircAlias, "15 Hardcore mode " .. " " .. YN(v.hardcore))
						irc_chat(chatvars.ircAlias, "16 Lottery multiplier " .. " " .. v.lotteryMultiplier)
						irc_chat(chatvars.ircAlias, "17 Lottery ticket price " .. " " .. v.lotteryTicketPrice)
						irc_chat(chatvars.ircAlias, "18 Map size " .. " " .. v.mapSize)
						irc_chat(chatvars.ircAlias, "19 Max bases " .. " " .. v.maxBases)
						irc_chat(chatvars.ircAlias, "20 Max gimmies " .. " " .. v.maxGimmies)
						irc_chat(chatvars.ircAlias, "21 Max active base protects " .. " " .. v.maxProtectedBases)
						irc_chat(chatvars.ircAlias, "22 Max waypoints " .. " " .. v.maxWaypoints)
						irc_chat(chatvars.ircAlias, "23 Group name " .. " " .. v.name)
						irc_chat(chatvars.ircAlias, "24 Player name prefix " .. " " .. v.namePrefix)
						irc_chat(chatvars.ircAlias, "25 P2P cooldown " .. " " .. v.p2pCooldown)
						irc_chat(chatvars.ircAlias, "26 Pack cooldown " .. " " .. v.packCooldown)
						irc_chat(chatvars.ircAlias, "27 Pack cost " .. " " .. v.packCost)
						irc_chat(chatvars.ircAlias, "28 Per minute play payment " .. " " .. v.perMinutePayRate)
						irc_chat(chatvars.ircAlias, "29 Player teleport delay " .. " " .. v.playerTeleportDelay)
						irc_chat(chatvars.ircAlias, "30 Allow protect in pvp areas " .. " " .. YN(v.pvpAllowProtect))
						irc_chat(chatvars.ircAlias, "31 Can reserve a slot " .. " " .. YN(v.reserveSlot))
						irc_chat(chatvars.ircAlias, "32 Return cooldown " .. " " .. v.returnCooldown)
						irc_chat(chatvars.ircAlias, "33 Teleport cost " .. " " .. v.teleportCost)
						irc_chat(chatvars.ircAlias, "34 Public teleport cooldown " .. " " .. v.teleportPublicCooldown)
						irc_chat(chatvars.ircAlias, "35 Public teleport cost " .. " " .. v.teleportPublicCost)
						irc_chat(chatvars.ircAlias, "36 Waypoint cooldown " .. " " .. v.waypointCooldown)
						irc_chat(chatvars.ircAlias, "37 Waypoint cost " .. " " .. v.waypointCost)
						irc_chat(chatvars.ircAlias, "38 Waypoint creation cost " .. " " .. v.waypointCreateCost)
						irc_chat(chatvars.ircAlias, "39 Zombie kill payment " .. " " .. v.zombieKillReward)
						irc_chat(chatvars.ircAlias, "40 Block setting base protection " .. " " .. YN(v.disableBaseProtection))
						irc_chat(chatvars.ircAlias, "41 Cooldown for set base " .. " " .. v.setBaseCooldown)
						irc_chat(chatvars.ircAlias, "42 Cooldown for set waypoint " .. " " .. v.setWPCooldown)
						irc_chat(chatvars.ircAlias, "43 Access level " .. " " .. v.accessLevel)
						irc_chat(chatvars.ircAlias, "44 Donor group " .. " " .. YN(v.donorGroup))
						irc_chat(chatvars.ircAlias, "45 Cooldown for gimme " .. " " .. v.gimmeRaincheck)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListGroupMembers()
		local k, v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list group members {group number or name}"
			help[2] = "See a list of players that belong to a group."

			tmp.command = help[1]
			tmp.keywords = "list,playergroups,members"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "group") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "list" and chatvars.words[2] == "group" and chatvars.words[3] == "members" then --  and chatvars.words[4] ~= nil
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[4] then
				tmp.group = string.sub(chatvars.command, string.find(chatvars.command, " members ") + 9)
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Group required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Group required.")
				end

				botman.faultyChat = false
				return true
			end

			tmp.members = 0

			-- check that the group exists
			tmp.groupID, tmp.groupName = LookupPlayerGroup(tmp.group)

			if tmp.groupID == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Group not found.[-]")
				else
					irc_chat(chatvars.ircAlias, "Group not found.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players in group " .. tmp.groupName .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Players in group " .. tmp.groupName)
				end

				for k,v in pairs(players) do
					if v.groupID == tmp.groupID then
						tmp.members = tmp.members + 1
						tmp.group2ID, tmp.group2Name = LookupPlayerGroup(v.groupExpiryFallbackGroup)

						if tonumber(v.groupExpiry) > 0 then
							tmp.days, tmp.hours, tmp.minutes = timestampToString(v.groupExpiry)
						end

						if (chatvars.playername ~= "Server") then
							if v.groupExpiry == 0 then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. v.name .. " - " .. v.platform .. " - " .. v.steam .. "[-]")
							else
								if tmp.group2Name == "" then
									message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. v.name .. " - " .. v.platform .. " - " .. v.steam .. " expires in " .. tmp.days .. " days " .. tmp.hours .. " hours " .. tmp.minutes .." minutes[-]")
								else
									message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. v.name .. " - " .. v.platform .. " - " .. v.steam .. " expires in " .. tmp.days .. " days " .. tmp.hours .. " hours " .. tmp.minutes .." minutes, then moves to " .. tmp.group2Name .. "[-]")
								end
							end
						else
							if v.groupExpiry == 0 then
								irc_chat(chatvars.ircAlias, v.name .. " - " .. v.platform .. " - " .. v.steam)
							else
								if tmp.group2Name == "" then
									irc_chat(chatvars.ircAlias, v.name .. " - " .. v.platform .. " - " .. v.steam .. " expires in " .. tmp.days .. " days " .. tmp.hours .. " hours " .. tmp.minutes .." minutes")
								else
									irc_chat(chatvars.ircAlias, v.name .. " - " .. v.platform .. " - " .. v.steam .. " expires in " .. tmp.days .. " days " .. tmp.hours .. " hours " .. tmp.minutes .." minutes, then moves to " .. tmp.group2Name)
								end
							end
						end
					end
				end

				if tmp.members == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No players in group.[-]")
					else
						irc_chat(chatvars.ircAlias, "No players in group.")
					end
				else
					if tmp.members == 1 then
						tmp.lineEnding = "member."
					else
						tmp.lineEnding = "members."
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.groupName .. " has "  .. tmp.members .. " " .. tmp.lineEnding .. "[-]")
					else
						irc_chat(chatvars.ircAlias, tmp.groupName .. " has "  .. tmp.members .. " " .. tmp.lineEnding)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListNoGroup()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list no group"
			help[2] = "View the settings for everyone not in a group."

			tmp.command = help[1]
			tmp.keywords = "list,playergroups"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "group") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "list" and chatvars.words[2] == "no" and chatvars.words[3] == "group" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Bot settings for everyone not in a player group.[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]1  Play Gimme " .. " " .. YN(server.allowGimme) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]2  Home teleport " .. " " .. YN(server.allowHomeTeleport) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]3  Play lottery " .. " " .. YN(server.allowLottery) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]4  P2P teleporting " .. " " .. YN(server.allowPlayerToPlayerTeleporting) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]5  Shop open " .. " " .. YN(server.allowShop) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]6  Players can teleport " .. " " .. YN(server.allowTeleporting) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]7  Visit pvp areas " .. " " .. YN(server.allowVisitInPVP) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]8  Can use waypoints " .. " " .. YN(server.allowWaypoints) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]9  Base cooldown " .. " " .. server.baseCooldown .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]10 Base cost " .. " " .. server.baseCost .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]11 Base size " .. " " .. server.baseSize .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]12 Player name colour " .. " " .. server.chatColour .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]13 Death cost " .. " " .. server.deathCost .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]14 Gimme spawns zombies " .. " " .. YN(server.gimmeZombies) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]15 Hardcore mode " .. " " .. YN(server.hardcore) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]16 Lottery multiplier " .. " " .. server.lotteryMultiplier .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]17 Lottery ticket price " .. " " .. server.lotteryTicketPrice .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]18 Map size " .. " " .. server.mapSize .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]19 Max bases " .. " " .. server.maxBases .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]20 Max gimmies " .. " " .. server.maxGimmies .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]21 Max active base protects " .. " " .. server.maxProtectedBases .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]22 Max waypoints " .. " " .. server.maxWaypoints .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]25 P2P cooldown " .. " " .. server.p2pCooldown .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]26 Pack cooldown " .. " " .. server.packCooldown .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]27 Pack cost " .. " " .. server.packCost .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]28 Per minute play payment " .. " " .. server.perMinutePayRate .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]29 Player teleport delay " .. " " .. server.playerTeleportDelay .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]30 Allow protect in pvp areas " .. " " .. YN(server.pvpAllowProtect) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]31 Can reserve a slot " .. " " .. YN(server.reserveSlot) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]32 Return cooldown " .. " " .. server.returnCooldown .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]33 Teleport cost " .. " " .. server.teleportCost .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]34 Public teleport cooldown " .. " " .. server.teleportPublicCooldown .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]35 Public teleport cost " .. " " .. server.teleportPublicCost .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]36 Waypoint cooldown " .. " " .. server.waypointCooldown .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]37 Waypoint cost " .. " " .. server.waypointCost .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]38 Waypoint creation cost " .. " " .. server.waypointCreateCost .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]39 Zombie kill payment " .. " " .. server.zombieKillReward .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]40 Block setting base protection " .. " " .. YN(server.disableBaseProtection) .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]41 Cooldown for set base " .. " " .. server.setBaseCooldown .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]42 Cooldown for set waypoint " .. " " .. server.setWPCooldown .. "[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]45 Cooldown for gimme game " .. " " .. server.gimmeRaincheck .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Bot settings for everyone not in a player group.")
				irc_chat(chatvars.ircAlias, "1  Play Gimme " .. " " .. YN(server.allowGimme))
				irc_chat(chatvars.ircAlias, "2  Home teleport " .. " " .. YN(server.allowHomeTeleport))
				irc_chat(chatvars.ircAlias, "3  Play lottery " .. " " .. YN(server.allowLottery))
				irc_chat(chatvars.ircAlias, "4  P2P teleporting " .. " " .. YN(server.allowPlayerToPlayerTeleporting))
				irc_chat(chatvars.ircAlias, "5  Shop open " .. " " .. YN(server.allowShop))
				irc_chat(chatvars.ircAlias, "6  Players can teleport " .. " " .. YN(server.allowTeleporting))
				irc_chat(chatvars.ircAlias, "7  Visit pvp areas " .. " " .. YN(server.allowVisitInPVP))
				irc_chat(chatvars.ircAlias, "8  Can use waypoints " .. " " .. YN(server.allowWaypoints))
				irc_chat(chatvars.ircAlias, "9  Base cooldown " .. " " .. server.baseCooldown)
				irc_chat(chatvars.ircAlias, "10 Base cost " .. " " .. server.baseCost)
				irc_chat(chatvars.ircAlias, "11 Base size " .. " " .. server.baseSize)
				irc_chat(chatvars.ircAlias, "12 Player name colour " .. " " .. server.chatColour)
				irc_chat(chatvars.ircAlias, "13 Death cost " .. " " .. server.deathCost)
				irc_chat(chatvars.ircAlias, "14 Gimme spawns zombies " .. " " .. YN(server.gimmeZombies))
				irc_chat(chatvars.ircAlias, "15 Hardcore mode " .. " " .. YN(server.hardcore))
				irc_chat(chatvars.ircAlias, "16 Lottery multiplier " .. " " .. server.lotteryMultiplier)
				irc_chat(chatvars.ircAlias, "17 Lottery ticket price " .. " " .. server.lotteryTicketPrice)
				irc_chat(chatvars.ircAlias, "18 Map size " .. " " .. server.mapSize)
				irc_chat(chatvars.ircAlias, "19 Max bases " .. " " .. server.maxBases)
				irc_chat(chatvars.ircAlias, "20 Max gimmies " .. " " .. server.maxGimmies)
				irc_chat(chatvars.ircAlias, "21 Max active base protects " .. " " .. server.maxProtectedBases)
				irc_chat(chatvars.ircAlias, "22 Max waypoints " .. " " .. server.maxWaypoints)
				irc_chat(chatvars.ircAlias, "25 P2P cooldown " .. " " .. server.p2pCooldown)
				irc_chat(chatvars.ircAlias, "26 Pack cooldown " .. " " .. server.packCooldown)
				irc_chat(chatvars.ircAlias, "27 Pack cost " .. " " .. server.packCost)
				irc_chat(chatvars.ircAlias, "28 Per minute play payment " .. " " .. server.perMinutePayRate)
				irc_chat(chatvars.ircAlias, "29 Player teleport delay " .. " " .. server.playerTeleportDelay)
				irc_chat(chatvars.ircAlias, "30 Allow protect in pvp areas " .. " " .. YN(server.pvpAllowProtect))
				irc_chat(chatvars.ircAlias, "31 Can reserve a slot " .. " " .. YN(server.reserveSlot))
				irc_chat(chatvars.ircAlias, "32 Return cooldown " .. " " .. server.returnCooldown)
				irc_chat(chatvars.ircAlias, "33 Teleport cost " .. " " .. server.teleportCost)
				irc_chat(chatvars.ircAlias, "34 Public teleport cooldown " .. " " .. server.teleportPublicCooldown)
				irc_chat(chatvars.ircAlias, "35 Public teleport cost " .. " " .. server.teleportPublicCost)
				irc_chat(chatvars.ircAlias, "36 Waypoint cooldown " .. " " .. server.waypointCooldown)
				irc_chat(chatvars.ircAlias, "37 Waypoint cost " .. " " .. server.waypointCost)
				irc_chat(chatvars.ircAlias, "38 Waypoint creation cost " .. " " .. server.waypointCreateCost)
				irc_chat(chatvars.ircAlias, "39 Zombie kill payment " .. " " .. server.zombieKillReward)
				irc_chat(chatvars.ircAlias, "40 Block setting base protection " .. " " .. YN(server.disableBaseProtection))
				irc_chat(chatvars.ircAlias, "41 Cooldown for set base " .. " " .. server.setBaseCooldown)
				irc_chat(chatvars.ircAlias, "42 Cooldown for set waypoint " .. " " .. server.setWPCooldown)
				irc_chat(chatvars.ircAlias, "45 Cooldown for gimme game " .. " " .. server.gimmeRaincheck)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MoveGroupMembers()
		local k, v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}move group members {old group number or name} to {new group number or name}"
			help[2] = "Move all members of a group to another group."

			tmp.command = help[1]
			tmp.keywords = "move,playergroups,members"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "move") or string.find(chatvars.command, "group") or string.find(chatvars.command, "member") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "move" and chatvars.words[2] == "group" and chatvars.words[3] == "members" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.members = 0
			tmp.oldGroup = string.sub(chatvars.commandOld, string.find(chatvars.command, " members ") + 9, string.find(chatvars.command, " to ") - 1)
			tmp.newGroup = string.sub(chatvars.commandOld, string.find(chatvars.command, " to ") + 4)
			tmp.newGroup = string.trim(tmp.newGroup)

			-- check that the groups exist
			tmp.oldGroupID, tmp.oldGroupName = LookupPlayerGroup(tmp.oldGroup)
			tmp.newGroupID, tmp.newGroupName = LookupPlayerGroup(tmp.newGroup)

			if tmp.oldGroupID == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Could not find group " .. tmp.oldGroup .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Could not find group " .. tmp.oldGroup)
				end

				botman.faultyChat = false
				return true
			end

			if tmp.newGroupID == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Could not find group " .. tmp.newGroup .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Could not find group " .. tmp.newGroup)
				end

				botman.faultyChat = false
				return true
			end

			-- move the players to the other group
			for k,v in pairs(players) do
				if v.groupID == tmp.oldGroupID then
					tmp.members = tmp.members + 1
					v.groupID = tmp.newGroupID
				end
			end

			if botman.dbConnected then conn:execute("UPDATE players SET groupID = " .. tmp.newGroupID .. " WHERE groupID = " .. tmp.oldGroupID) end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.members .. " players were moved from group " .. tmp.oldGroupName .. " to group " .. tmp.newGroupName .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, tmp.members .. " players were moved from group " .. tmp.oldGroupName .. " to group " .. tmp.newGroupName .. ".")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GroupAddRemovePlayer()
		local k, v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}group {number or name} add {name}\n"
			help[1] = help[1] .. "Or {#}group {number or name} add {name} expires {interval} to group {number or name}\n"
			help[1] = help[1] .. " {#}group {number or name} remove {name}"
			help[2] = "Add or remove a player from a group.\n"
			help[2] = help[2] .. "Players can only belong to one group at a time so adding them to a group automatically removes them from another.\n"
			help[2] = help[2] .. "You can also set an expiry after which the player is automatically removed from the group. If you specify a second group, they are automatically joined to it after the expiry or to no group."

			tmp.command = help[1]
			tmp.keywords = "add,remove,playergroups,members,expiry,expires,cooldown"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "remove") or string.find(chatvars.command, "group") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "group" and (string.find(chatvars.command, " add ") or string.find(chatvars.command, " remove ")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.addingPlayer = true
			tmp.groupID = 0
			tmp.group2ID = 0
			tmp.playerID = "0"
			tmp.expiryString = ""
			tmp.expiry = 0
			tmp.toGroup = ""

			-- get the group
			if string.find(chatvars.command, " add ")  then
				tmp.group = string.sub(chatvars.command, 8, string.find(chatvars.command, " add ") - 1)
			else
				tmp.group = string.sub(chatvars.command, 8, string.find(chatvars.command, " remove ") - 1)
				tmp.addingPlayer = false
			end

			tmp.group = string.trim(tmp.group)
			tmp.groupName = tmp.group

			-- no group?  no party!
			if tmp.group == "" and tmp.addingPlayer then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Group number or name required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Group number or name required.")
				end

				botman.faultyChat = false
				return true
			end

			-- get the player
			if not string.find(chatvars.command, " expir") then
				if string.find(chatvars.command, " add ") then
					tmp.player = string.sub(chatvars.command, string.find(chatvars.command, " add ") + 5)
				else
					tmp.player = string.sub(chatvars.command, string.find(chatvars.command, " remove ") + 8)
				end
			else
				if string.find(chatvars.command, " add ") then
					tmp.player = string.sub(chatvars.command, string.find(chatvars.command, " add ") + 5, string.find(chatvars.command, " expir") -1)
				else
					tmp.player = string.sub(chatvars.command, string.find(chatvars.command, " remove ") + 8, string.find(chatvars.command, " expir") -1)
				end

				--expires {interval} to group
				if not string.find(chatvars.command, " to group ") then
					tmp.expiryString = string.sub(chatvars.command, string.find(chatvars.command, " expires ") + 9)
				else
					tmp.expiryString = string.sub(chatvars.command, string.find(chatvars.command, " expires ") + 9, string.find(chatvars.command, " to group") -1)
					tmp.toGroup = string.sub(chatvars.command, string.find(chatvars.command, " to group ") + 10)
				end
			end

			tmp.player = string.trim(tmp.player)

			-- no player? no Gwent!
			if tmp.player == "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player required.")
				end

				botman.faultyChat = false
				return true
			end

			-- lookup the player
			tmp.playerID = LookupPlayer(tmp.player)

			if tmp.playerID == "0" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. tmp.player .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "No player found called " .. tmp.player)
				end

				botman.faultyChat = false
				return true
			end

			-- check that the group exists
			tmp.groupID, tmp.groupName = LookupPlayerGroup(tmp.group)

			-- group doesn't exist
			if tmp.groupID == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Group " .. tmp.group .. " does not match any known groups.[-]")
				else
					irc_chat(chatvars.ircAlias, "Group " .. tmp.group .. " does not match any known groups.")
				end

				botman.faultyChat = false
				return true
			end

			if tmp.toGroup ~= "" then
				-- check that the second group exists
				tmp.group2ID, tmp.group2Name = LookupPlayerGroup(tmp.toGroup)

				-- group doesn't exist
				if tmp.group2ID == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Group " .. tmp.toGroup .. " does not match any known groups.[-]")
					else
						irc_chat(chatvars.ircAlias, "Group " .. tmp.toGroup .. " does not match any known groups.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if tmp.expiryString ~= "" then
				-- convert expiry into a timestamp
				tmp.expiry = calcTimestamp(tmp.expiryString)
			end

			if tmp.addingPlayer then
				players[tmp.playerID].groupID = tmp.groupID
				players[tmp.playerID].groupExpiry = tmp.expiry
				players[tmp.playerID].groupExpiryFallbackGroup = tmp.group2ID

				if botman.dbConnected then conn:execute("UPDATE players SET groupID = " .. tmp.groupID .. ", groupExpiry = " .. tmp.expiry .. ", groupExpiryFallbackGroup = " .. tmp.group2ID .. " WHERE steam = '" .. tmp.playerID .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. players[tmp.playerID].name .. " was added to the group " .. tmp.groupName .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[tmp.playerID].name .. " was added to group " .. tmp.groupName)
				end

				if tmp.expiryString ~= "" then
					if tmp.toGroup == "" then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]After " .. tmp.expiryString .. " they will be removed from " .. tmp.groupName .. ".[-]")
						else
							irc_chat(chatvars.ircAlias, "After " .. tmp.expiryString .. " they will be removed from " .. tmp.groupName .. ".")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]After " .. tmp.expiryString .. " they will be removed from " .. tmp.groupName .. " and join " .. tmp.group2Name .. ".[-]")
						else
							irc_chat(chatvars.ircAlias, "After " .. tmp.expiryString .. " they will be removed from " .. tmp.groupName .. " and join " .. tmp.group2Name .. ".")
						end
					end
				end

				setChatColour(tmp.playerID)
				setOverrideChatName(tmp.playerID, playerGroups["G" .. tmp.groupID].namePrefix .. players[tmp.playerID].name)
			else
				players[tmp.playerID].groupID = 0
				if botman.dbConnected then conn:execute("UPDATE players SET groupID = 0 WHERE steam = '" .. tmp.playerID .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. players[tmp.playerID].name .. " was removed from the group " .. tmp.groupName .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[tmp.playerID].name .. " was removed from group " .. tmp.groupName)
				end

				setChatColour(tmp.playerID)
				setOverrideChatName(tmp.playerID, players[tmp.playerID].name)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetGroupSetting()
		local k, v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}group {number or name} set {setting number from list} value {a value}"
			help[2] = "Change the value of one of the group's settings.\n"
			help[2] = help[2] .. "To see the numbered list of settings type {#}group settings and note the number of the setting you wish to change.\n"
			help[2] = help[2] .. "Depending on the setting, {a value} will be a number, or Y or N, or some text\n"
			help[2] = help[2] .. "For Y/N settings the bot will also accept yes/no, true/false, on/off or enabled/disabled."

			tmp.command = help[1]
			tmp.keywords = "playergroups,settings,value,permissions"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "group") or string.find(chatvars.command, "set") or string.find(chatvars.command, "setting") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "group" and string.find(chatvars.command, " set ") and string.find(chatvars.command, " value ") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			-- we only need the Lua table groupFields for this command.  To save resources we only create it once when needed.
			createGroupFields()

			-- get the group and verify it exists
			tmp.group = string.sub(chatvars.command, 8, string.find(chatvars.command, " set ") - 1)
			tmp.groupID, tmp.groupName = LookupPlayerGroup(tmp.group)

			tmp.yes = {}
			tmp.no = {}
			tmp.yes["y"] = {}
			tmp.no["n"] = {}
			tmp.yes["yes"] = {}
			tmp.no["no"] = {}
			tmp.yes["on"] = {}
			tmp.no["off"] = {}
			tmp.yes["true"] = {}
			tmp.no["false"] = {}
			tmp.yes["t"] = {}
			tmp.no["f"] = {}
			tmp.yes["1"] = {}
			tmp.no["0"] = {}
			tmp.yes["enable"] = {}
			tmp.no["disable"] = {}
			tmp.yes["enabled"] = {}
			tmp.no["disabled"] = {}
			tmp.yes["allow"] = {}
			tmp.no["disallow"] = {}
			tmp.yes["allowed"] = {}
			tmp.no["disallowed"] = {}

			if tmp.groupID == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No group found called " .. tmp.group .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "No group found called " .. tmp.group)
				end

				botman.faultyChat = false
				return true
			end

			-- get the setting number
			tmp.settingNumber = string.sub(chatvars.command, string.find(chatvars.command, " set ") + 5, string.find(chatvars.command, " value ") - 1)
			tmp.settingNumber = math.abs(tmp.settingNumber)

			if tmp.settingNumber == nil or tmp.settingNumber > 45 or tmp.settingNumber == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Bad setting number. Expected 1 to 45.[-]")
				else
					irc_chat(chatvars.ircAlias, "Bad setting number. Expected 1 to 45.")
				end

				botman.faultyChat = false
				return true
			end

			-- get the field name
			tmp.field = groupFields[tmp.settingNumber].field

			-- get the setting value
			tmp.settingValue = string.sub(chatvars.commandOld, string.find(chatvars.command, " value ") + 7)
			tmp.settingValue = string.trim(tmp.settingValue)

			if tmp.settingValue == "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You forgot to give me the value to set.[-]")
				else
					irc_chat(chatvars.ircAlias, "You forgot to give me the value to set.")
				end

				botman.faultyChat = false
				return true
			end

			-- validate tmp.settingValue according to the rules in the groupFields table
			if groupFields[tmp.settingNumber].type == "yn" then
				if not tmp.yes[string.lower(tmp.settingValue)] and not tmp.no[string.lower(tmp.settingValue)] then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Valid values are y/n, yes/no, on/off, true/false, enabled/disabled.[-]")
					else
						irc_chat(chatvars.ircAlias, "Valid values are y/n, yes/no, on/off, true/false, enabled/disabled.")
					end

					botman.faultyChat = false
					return true
				else
					if tmp.yes[string.lower(tmp.settingValue)] then
						tmp.storeValue = 1

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.field .. " enabled for " .. tmp.groupName .. "[-]")
						else
							irc_chat(chatvars.ircAlias, tmp.field .. " enabled for " .. tmp.groupName)
						end
					else
						tmp.storeValue = 0

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.field .. " disabled for " .. tmp.groupName .. "[-]")
						else
							irc_chat(chatvars.ircAlias, tmp.field .. " disabled for " .. tmp.groupName)
						end
					end
				end
			end

			if groupFields[tmp.settingNumber].type == "num" then
				tmp.number = tonumber(tmp.settingValue)

				if tmp.number == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Value must be a number[-]")
					else
						irc_chat(chatvars.ircAlias, "Value must be a number")
					end

					botman.faultyChat = false
					return true
				else
					if tmp.number < tonumber(groupFields[tmp.settingNumber].min) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Value must be " .. tonumber(groupFields[tmp.settingNumber].min) .. " or greater.[-]")
						else
							irc_chat(chatvars.ircAlias, "Value must be " .. tonumber(groupFields[tmp.settingNumber].min) .. " or greater.")
						end

						botman.faultyChat = false
						return true
					end

					tmp.storeValue = tmp.number

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.field .. " set to " .. tmp.storeValue .. " for " .. tmp.groupName .. "[-]")
					else
						irc_chat(chatvars.ircAlias, tmp.field .. " set to " .. tmp.storeValue .. " for " .. tmp.groupName)
					end
				end
			end

			if groupFields[tmp.settingNumber].type == "text" then
				if string.len(tmp.settingValue) > tonumber(groupFields[tmp.settingNumber].maxLength) then

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.field .. " value too long. Max length is " .. groupFields[tmp.settingNumber].maxLength .. "[-]")
					else
						irc_chat(chatvars.ircAlias, tmp.field .. " text too long. Max length is " .. groupFields[tmp.settingNumber].maxLength)
					end

					botman.faultyChat = false
					return true
				else
					tmp.storeValue = tmp.settingValue

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.field .. " set to " .. tmp.storeValue .. " for " .. tmp.groupName .. "[-]")
					else
						irc_chat(chatvars.ircAlias, tmp.field .. " set to " .. tmp.storeValue .. " for " .. tmp.groupName)
					end
				end
			end

			-- YAY! We can save the new value! :D
			if botman.dbConnected then conn:execute("UPDATE playerGroups SET " .. tmp.field .. " = " .. tmp.storeValue .. " WHERE groupID = " .. tmp.groupID) end

			tempTimer( 3, [[loadPlayerGroups()]] )

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetNoGroupSetting()
		local k, v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}no group set {setting number from list} value {a value}"
			help[2] = "Change the value of one of the bot's settings for players who are not in a group.\n"
			help[2] = help[2] .. "To see the numbered list of settings type {#}group settings and note the number of the setting you wish to change.\n"
			help[2] = help[2] .. "Depending on the setting, {a value} will be a number, or Y or N, or some text\n"
			help[2] = help[2] .. "For Y/N settings the bot will also accept yes/no, true/false, on/off or enabled/disabled."

			tmp.command = help[1]
			tmp.keywords = "playergroups,settings,value,permissions"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "group") or string.find(chatvars.command, "set") or string.find(chatvars.command, "setting") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "no" and chatvars.words[2] == "group" and string.find(chatvars.command, " set ") and string.find(chatvars.command, " value ") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			-- we only need the Lua table groupFields for this command.  To save resources we only create it once when needed.
			createGroupFields()

			tmp.yes = {}
			tmp.no = {}
			tmp.yes["y"] = {}
			tmp.no["n"] = {}
			tmp.yes["yes"] = {}
			tmp.no["no"] = {}
			tmp.yes["on"] = {}
			tmp.no["off"] = {}
			tmp.yes["true"] = {}
			tmp.no["false"] = {}
			tmp.yes["t"] = {}
			tmp.no["f"] = {}
			tmp.yes["1"] = {}
			tmp.no["0"] = {}
			tmp.yes["enable"] = {}
			tmp.no["disable"] = {}
			tmp.yes["enabled"] = {}
			tmp.no["disabled"] = {}
			tmp.yes["allow"] = {}
			tmp.no["disallow"] = {}
			tmp.yes["allowed"] = {}
			tmp.no["disallowed"] = {}

			-- get the setting number
			tmp.settingNumber = string.sub(chatvars.command, string.find(chatvars.command, " set ") + 5, string.find(chatvars.command, " value ") - 1)
			tmp.settingNumber = math.abs(tmp.settingNumber)

			-- get the field name and type
			tmp.field = groupFields[tmp.settingNumber].field
			tmp.type = groupFields[tmp.settingNumber].type
			tmp.caption = groupFields[tmp.settingNumber].caption

			-- get the setting value
			tmp.settingValue = string.sub(chatvars.commandOld, string.find(chatvars.command, " value ") + 7)
			tmp.settingValue = string.trim(tmp.settingValue)

			if tmp.settingNumber == 23 or tmp.settingNumber == 24 or tmp.settingNumber == 43 or tmp.settingNumber == 44 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The setting, '" .. tmp.field .. "' (" .. tmp.caption .. ") is only valid for player groups.[-]")
				else
					irc_chat(chatvars.ircAlias, "The setting, '" .. tmp.field .. "' (" .. tmp.caption .. ") is only valid for player groups.")
				end

				botman.faultyChat = false
				return true
			end

			if tmp.settingNumber == nil or tmp.settingNumber > 45 or tmp.settingNumber == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Bad setting number. Expected 1 to 45.[-]")
				else
					irc_chat(chatvars.ircAlias, "Bad setting number. Expected 1 to 45.")
				end

				botman.faultyChat = false
				return true
			end

			if tmp.settingValue == "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You forgot to give me the value to set.[-]")
				else
					irc_chat(chatvars.ircAlias, "You forgot to give me the value to set.")
				end

				botman.faultyChat = false
				return true
			end

			-- validate tmp.settingValue according to the rules in the groupFields table
			if tmp.type == "yn" then
				if not tmp.yes[string.lower(tmp.settingValue)] and not tmp.no[string.lower(tmp.settingValue)] then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Valid values are y/n, yes/no, on/off, true/false, enabled/disabled.[-]")
					else
						irc_chat(chatvars.ircAlias, "Valid values are y/n, yes/no, on/off, true/false, enabled/disabled.")
					end

					botman.faultyChat = false
					return true
				else
					if tmp.yes[string.lower(tmp.settingValue)] then
						tmp.storeValue = 1

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.field .. " enabled for players not in a group.[-]")
						else
							irc_chat(chatvars.ircAlias, tmp.field .. " enabled for players not in a group.")
						end
					else
						tmp.storeValue = 0

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.field .. " disabled for players not in a group.[-]")
						else
							irc_chat(chatvars.ircAlias, tmp.field .. " disabled for players not in a group.")
						end
					end
				end
			end

			if tmp.type == "num" then
				tmp.number = tonumber(tmp.settingValue)

				if tmp.number == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Value must be a number[-]")
					else
						irc_chat(chatvars.ircAlias, "Value must be a number")
					end

					botman.faultyChat = false
					return true
				else
					if tmp.number < tonumber(groupFields[tmp.settingNumber].min) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Value must be " .. tonumber(groupFields[tmp.settingNumber].min) .. " or greater.[-]")
						else
							irc_chat(chatvars.ircAlias, "Value must be " .. tonumber(groupFields[tmp.settingNumber].min) .. " or greater.")
						end

						botman.faultyChat = false
						return true
					end

					tmp.storeValue = tmp.number

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.field .. " set to " .. tmp.storeValue .. " for players not in a group.[-]")
					else
						irc_chat(chatvars.ircAlias, tmp.field .. " set to " .. tmp.storeValue .. " for players not in a group.")
					end
				end
			end

			if tmp.type == "text" then
				if string.len(tmp.settingValue) > tonumber(groupFields[tmp.settingNumber].maxLength) then

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.field .. " value too long. Max length is " .. groupFields[tmp.settingNumber].maxLength .. "[-]")
					else
						irc_chat(chatvars.ircAlias, tmp.field .. " text too long. Max length is " .. groupFields[tmp.settingNumber].maxLength)
					end

					botman.faultyChat = false
					return true
				else
					tmp.storeValue = tmp.settingValue

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.field .. " set to " .. tmp.storeValue .. " for players who are not in a group.[-]")
					else
						irc_chat(chatvars.ircAlias, tmp.field .. " set to " .. tmp.storeValue .. " for players who are not in a group.")
					end
				end
			end

			-- YAY! We can save the new value! :D
			if botman.dbConnected then conn:execute("UPDATE server SET " .. tmp.field .. " = " .. tmp.storeValue) end

			tempTimer( 1, [[loadServer()]] )

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GroupSettings()
		local sortedSettings, expectedInput

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}group settings"
			help[2] = "View info about group settings for use in {#}group {group} set {setting number} value {value}."

			tmp.command = help[1]
			tmp.keywords = "list,view,playergroups,settings"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "setting") or string.find(chatvars.command, "group") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "group" and chatvars.words[2] == "settings" and chatvars.words[3] == nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			-- we only need the Lua table groupFields for this command.  To save resources we only create it once when needed.
			createGroupFields()
			sortedSettings = sortTable(groupFields)

			for k,v in ipairs(sortedSettings) do
				expectedInput = ""

				if groupFields[v].type == "yn" then
					expectedInput = "(y/n)"
				end

				if groupFields[v].type == "num" then
					expectedInput = "(min " .. groupFields[v].min .. ")"
				end

				if groupFields[v].type == "text" then
					expectedInput = "(text " .. groupFields[v].maxLength .. ")"
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. k .. " " .. groupFields[v].caption .. "  " .. expectedInput .. "[-]")
				else
					irc_chat(chatvars.ircAlias, k .. " " .. groupFields[v].caption .. "  " .. expectedInput)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


-- ################## End of command functions ##################

if debug then dbug("debug groups") end

	if botman.registerHelp then
		if debug then dbug("Registering help - group commands") end

		tmp.topicDescription = "Player group commands include commands for admins to create and manage player groups and the many settings that each group contains, plus commands to manage group membership.\n"
		tmp.topicDescription = tmp.topicDescription .. "Each group has its own copy of the bot's settings. These can be customised for the group and are the settings that are applied to all members in the group.\n"
		tmp.topicDescription = tmp.topicDescription .. "See also https://botman.nz/docs/guides/player-groups-noobie-guide for more detailed info with examples."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Player Group Commands:")
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, tmp.topicDescription)
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "You can find more information about player groups in the following guide.")
			irc_chat(chatvars.ircAlias, "https://files.botman.nz/guides/Player_Groups_Noobie_Guide.pdf")
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
			if chatvars.words[3] ~= "groups" then
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
		irc_chat(chatvars.ircAlias, "Player Group Commands:")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "groups")
	end

	result = cmd_AddRemoveGroup()

	if result then
		if debug then dbug("debug cmd_AddRemoveGroup triggered") end
		return result, "cmd_AddRemoveGroup"
	end

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	result = cmd_GroupAddRemovePlayer()

	if result then
		if debug then dbug("debug cmd_GroupAddRemovePlayer triggered") end
		return result, "cmd_GroupAddRemovePlayer"
	end

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	result = cmd_CopyGroup()

	if result then
		if debug then dbug("debug cmd_CopyGroup triggered") end
		return result, "cmd_CopyGroup"
	end

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	result = cmd_EmptyGroup()

	if result then
		if debug then dbug("debug cmd_EmptyGroup triggered") end
		return result, "cmd_EmptyGroup"
	end

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListGroup()

	if result then
		if debug then dbug("debug cmd_ListGroup triggered") end
		return result, "cmd_ListGroup"
	end

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListGroupMembers()

	if result then
		if debug then dbug("debug cmd_ListGroupMembers triggered") end
		return result, "cmd_ListGroupMembers"
	end

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListGroups()

	if result then
		if debug then dbug("debug cmd_ListGroups triggered") end
		return result, "cmd_ListGroups"
	end

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListNoGroup()

	if result then
		if debug then dbug("debug cmd_ListNoGroup triggered") end
		return result, "cmd_ListNoGroup"
	end

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	result = cmd_MoveGroupMembers()

	if result then
		if debug then dbug("debug cmd_MoveGroupMembers triggered") end
		return result, "cmd_MoveGroupMembers"
	end

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	result = cmd_GroupSettings()

	if result then
		if debug then dbug("debug cmd_GroupSettings triggered") end
		return result, "cmd_GroupSettings"
	end

	if debug then dbug("debug groups end of remote commands") end

	result = cmd_SetGroupSetting()

	if result then
		if debug then dbug("debug cmd_GroupSetting triggered") end
		return result, "cmd_SetGroupSetting"
	end

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetNoGroupSetting()

	if result then
		if debug then dbug("debug cmd_SetNoGroupSetting triggered") end
		return result, "cmd_SetNoGroupSetting"
	end

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == "0" and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false, ""
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if (debug) then dbug("debug groups line " .. debugger.getinfo(1).currentline) end

	if botman.registerHelp then
		if debug then dbug("Player Group commands help registered") end
	end

	if debug then dbug("debug groups end") end

	-- can't touch dis
	if true then
		return result, ""
	end
end
