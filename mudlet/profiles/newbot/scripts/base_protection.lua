--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]


function baseProtection(steam, posX, posY, posZ)
	-- steam is the steam id of the player we are testing against base protection.

	local k, v
	local tmp = {}

	calledFunction = "baseProtection"

	if server.disableBaseProtection then
		return
	end

	tmp.testMode = false
	players[steam].inABase = false
	tmp.userID = players[steam].userID
	tmp.isAdmin = isAdmin(steam, tmp.userID)
	tmp.inVehicle = igplayers[steam].inVehicle

	if igplayers[steam].protectTest then
		tmp.testMode = true
	end

	-- check for and record any non-friend who gets within protectSize meters of a players /setbase coord
	for k, v in pairs(bases) do
		tmp.dist = distancexz(posX, posZ, v.x, v.z)
		tmp.size = tonumber(v.size)

		-- is the player inside the base protection area?
		if (tmp.dist < tmp.size) then
			tmp.inBaseProtection = true
			players[steam].inABase = true
		else
			tmp.inBaseProtection = false
		end

		if (v.steam == steam and players[v.steam].protectPaused) then
			if (tmp.dist > 100) then
				players[v.steam].protectPaused = nil
				message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]Your base protection has re-activated.[-]")
			end
		end

		-- ignore the player if they are in a vehicle
		if not tmp.inVehicle then
			tmp.baseNumber = v.baseNumber
			tmp.baseName = v.title
			tmp.isFriend = isFriend(v.steam, steam)
			tmp.isBaseMember = isBaseMember(steam, v.steam, v.baseNumber)
			tmp.baseMemberCount = countBaseMembers(v.steam, v.baseNumber)
			tmp.baseOwner = v.steam
			tmp.protectBase = false
			tmp.alertBaseRaid = true

			if v.steam == steam then
				tmp.isBaseOwner = true
			else
				tmp.isBaseOwner = false
			end

			-- flag to activate base protection if base protected and protection is not paused
			if v.protect and not players[v.steam].protectPaused then
				tmp.protectBase = true
			end

			-- don't protect if player is an admin and the bot is ignoring admins
			if tmp.protectBase and tmp.isAdmin and botman.ignoreAdmins then
				tmp.protectBase = false
			end

			-- don't alert for base raiding if player is an admin and the bot is ignoring admins
			if tmp.isAdmin and botman.ignoreAdmins then
				tmp.alertBaseRaid = false
			end

			-- don't boot friends unless testmode is active
			if (tmp.isFriend or tmp.isBaseMember) and not v.keepOut and not tmp.testMode then
				tmp.protectBase = false
			end

			-- don't activate protection if player is a member of the base
			if v.keepOut and tmp.protectBase and not tmp.isBaseOwner then
				if tmp.baseMemberCount > 0 then
					if tmp.isBaseMember then
						tmp.protectBase = false
					end
				end
			end

			-- catch-all so we don't boot out the base owner unless testMode is true
			if (tmp.isBaseOwner and not tmp.testMode) and tmp.protectBase then
				tmp.protectBase = false
			end

			if tmp.inBaseProtection and tmp.alertBaseRaid then
				if (players[steam].watchPlayer == true) then
					tmp.alert = false

					if (players[steam].lastBaseRaid == nil) then
						players[steam].lastBaseRaid = os.time()
						tmp.alert = true
						-- spam prevention
						igplayers[steam].xPosLastAlert = 0
						igplayers[steam].yPosLastAlert = 0
						igplayers[steam].zPosLastAlert = 0
					end

					if (os.time() - tonumber(players[steam].lastBaseRaid) > 15) and ((posX ~= igplayers[steam].xPosLastAlert) or (posY ~= igplayers[steam].yPosLastAlert) or (posZ ~= igplayers[steam].zPosLastAlert)) then
						tmp.alert = true
					end

					if tmp.alert then
						-- spam prevention
						igplayers[steam].xPosLastAlert = posX
						igplayers[steam].yPosLastAlert = posY
						igplayers[steam].zPosLastAlert = posZ

						if (tmp.dist < 20) then
							if v.title ~= "" then
								tmp.msg = "Watched player " .. players[steam].id .. " " .. players[steam].name .. " is " .. string.format("%-8.2d", tmp.dist) .. " meters from " .. players[v.steam].name .. "'s base " .. v.baseNumber .. " called " .. v.title
							else
								tmp.msg = "Watched player " .. players[steam].id .. " " .. players[steam].name .. " is " .. string.format("%-8.2d", tmp.dist) .. " meters from " .. players[v.steam].name .. "'s base " .. v.baseNumber
							end

							if not server.disableWatchAlerts then
								alertAdmins(tmp.msg)
							end

							irc_chat(server.ircAlerts, server.gameDate .. " " .. tmp.msg)
						end

						players[steam].lastBaseRaid = os.time()
					end
				end

				igplayers[steam].raiding = true
				igplayers[steam].raidingBase = k

				-- do the base protection magic
				if tmp.protectBase then
					irc_chat(server.ircAlerts, "base protection triggered for base " .. v.baseNumber .. " of " .. players[v.steam].name .. " against " .. players[steam].name .. " " .. steam)

					if (igplayers[v.steam]) and not igplayers[v.steam].currentLocationPVP then
						message("pm " .. players[v.steam].userID .. " [" .. server.chatColour .. "]" .. igplayers[steam].name .. " has been bounced away from your base.[-]")
					end

					if not server.disableWatchAlerts then
						alertAdmins(igplayers[steam].name .. " has been ejected from " .. players[v.steam].name  .."'s base # " .. v.baseNumber)
					end

					tmp.dist = distancexz(igplayers[steam].xPosLastOK, igplayers[steam].zPosLastOK, v.x, v.z)

					if math.floor(tmp.dist) > tmp.size then
						message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]You are too close to a protected player base. The base owner needs to add you to their friends list.[-]")
						tmp.cmd = "tele " .. tmp.userID .. " " .. igplayers[steam].xPosLastOK .. " " .. igplayers[steam].yPosLastOK .. " " .. igplayers[steam].zPosLastOK

						teleport(tmp.cmd, steam, tmp.userID)
					else
						tmp.cmd = "tele " .. tmp.userID .. " " .. v.exitX .. " -1 " .. v.exitZ

						teleport(tmp.cmd, steam, tmp.userID)
						message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]You are too close to a protected player base.  The base owner needs to add you to their friends list.[-]")
					end

					return true
				end
			end
		end
	end


	-- location/village protection
	if (not tmp.isAdmin or not botman.ignoreAdmins or tmp.testMode) and not tmp.inVehicle then
		for k, v in pairs(locations) do
			if v.protected then
				if not LookupVillager(steam, k) and steam ~= v.owner then
					tmp.dist = distancexz(posX, posZ, v.x, v.z)
					tmp.size = tonumber(v.size)

					if tonumber(tmp.dist) < tonumber(tmp.size) then
						igplayers[steam].raiding = true
						tmp.dist = distancexz(igplayers[steam].xPosLastOK, igplayers[steam].zPosLastOK, v.x, v.z)

						-- do the village protection magic
						if tmp.dist > tmp.size then
							if v.village then
								message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]You are too close to the protected village called " .. k .. ".[-]")
							else
								message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]You are too close to the protected location called " .. k .. ".[-]")
							end

							tmp.cmd = "tele " .. tmp.userID .. " " .. igplayers[steam].xPosLastOK .. " " .. igplayers[steam].yPosLastOK .. " " .. igplayers[steam].zPosLastOK
							igplayers[steam].lastTP = tmp.cmd
							teleport(tmp.cmd, steam, tmp.userID)
						else
							tmp.cmd = "tele " .. tmp.userID .. " " .. v.exitX .. " -1 " .. v.exitZ
							igplayers[steam].lastTP = tmp.cmd
							teleport(tmp.cmd, steam, tmp.userID)

							if v.village then
								message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]You are too close to the protected village called " .. k .. ".[-]")
							else
								message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]You are too close to the protected location called " .. k .. ".[-]")
							end
						end

						return true
					end
				end
			end
		end
	end
end
