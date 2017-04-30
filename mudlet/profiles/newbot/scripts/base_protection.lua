--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function baseProtection(steam, posX, posY, posZ)
	calledFunction = "baseProtection"

	if server.disableBaseProtection then
		return
	end

	local k, v, testMode, dist, size, alert, cmd

	testMode = false

	-- check for and record any non-friend who gets within protectSize meters of a players /setbase coord
	for k, v in pairs(players) do

		if (math.abs(tonumber(v.homeX)) > 100 or math.abs(tonumber(v.homeZ)) > 100) then
			dist = distancexz(posX, posZ, v.homeX, v.homeZ)
			size = tonumber(v.protectSize)


			if (v.steam == steam and v.protectPaused) then
				if (dist > 100) then
					v.protectPaused = nil
					message("pm " .. steam .. " [" .. server.chatColour .. "]Your base protection has re-activated.[-]")
				end
			end

			if igplayers[steam].protectTest ~= nil and v.steam == steam then
				if igplayers[steam].protectTestEnd - os.time() < 0 then
					igplayers[steam].protectTest = nil
				else
					testMode = true
				end
			end

			if (v.steam ~= steam or testMode) and (v.protectSize ~= nil)  then
				if isFriend(v.steam, steam) == false or testMode then
					if (dist < size) then
						if (accessLevel(steam) > 2) or botman.ignoreAdmins == false or testMode then

							if (players[steam].watchPlayer == true) then
								alert = false

								if (players[steam].lastBaseRaid == nil) then
									players[steam].lastBaseRaid = os.time()
									alert = true
									-- spam prevention
									igplayers[steam].xPosLastAlert = 0
									igplayers[steam].yPosLastAlert = 0
									igplayers[steam].zPosLastAlert = 0
								end

								if (os.time() - tonumber(players[steam].lastBaseRaid) > 15) and ((posX ~= igplayers[steam].xPosLastAlert) or (posY ~= igplayers[steam].yPosLastAlert) or (posZ ~= igplayers[steam].zPosLastAlert)) then
									alert = true
								end

								if (alert == true) then
									-- spam prevention
									igplayers[steam].xPosLastAlert = posX
									igplayers[steam].yPosLastAlert = posY
									igplayers[steam].zPosLastAlert = posZ

									if (dist < 20) then
										alertAdmins("Watched player " .. players[steam].id .. " " .. players[steam].name .. " is " .. string.format("%-8.2d", dist) .. " meters from " .. v.name .. "'s base")
										irc_chat(server.ircMain, server.gameDate .. " Watched player " .. players[steam].id .. " " .. players[steam].name .. " is " .. string.format("%-8.2d", dist) .. " meters from " .. v.name .. "'s base")
									end

									players[steam].lastBaseRaid = os.time()
								end
							end

							igplayers[steam].raiding = true
							igplayers[steam].raidingBase = k

							-- do the base protection magic
							if (v.protect and v.protectSize and v.protect == true and not v.protectPaused) and v.homeX ~= 0 and v.homeY ~= 0 and v.homeZ ~= 0 then
								irc_chat(server.ircAlerts, "base protection triggered for base1 of " .. players[k].name .. " " .. k .. " against " .. players[steam].name .. " " .. steam)

								if (igplayers[k] ~= nil) and not igplayers[k].currentLocationPVP then
									message("pm " .. k .. " [" .. server.chatColour .. "]" .. igplayers[steam].name .. " has been bounced away from your base.[-]")
								end

								alertAdmins(igplayers[steam].name .. " has been ejected from " .. v.name  .."'s 1st base.")

								if distancexz(igplayers[steam].xPosLastOK, igplayers[steam].zPosLastOK, v.homeX, v.homeZ) > v.protectSize then
									message("pm " .. steam .. " [" .. server.chatColour .. "]You are too close to a protected player base. The base owner needs to add you to their friends list by typing " .. server.commandPrefix .. "friend " .. igplayers[steam].name .. "[-]")
									cmd = "tele " .. steam .. " " .. igplayers[steam].xPosLastOK .. " -1 " .. igplayers[steam].zPosLastOK

--									dbug("base_protection line " .. debugger.getinfo(1).currentline)	
									prepareTeleport(steam, cmd)
									teleport(cmd, true)
								else
									cmd = "tele " .. steam .. " " .. v.exitX .. " -1 " .. v.exitZ

									prepareTeleport(steam, cmd)
--									dbug("base_protection line " .. debugger.getinfo(1).currentline)	
									teleport(cmd, true)
									message("pm " .. steam .. " [" .. server.chatColour .. "]You are too close to a protected player base.  The base owner needs to add you to their friends list by typing " .. server.commandPrefix .. "friend " .. igplayers[steam].name .. "[-]")
								end

								return true
							end
						end
					end
				end
			end
		end


		-- 2nd base for donors and admins
		if (math.abs(tonumber(v.home2X)) > 100 or math.abs(tonumber(v.home2Z)) > 100) then
			dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, v.home2X, v.home2Z)
			size = tonumber(v.protect2Size)

			if (v.steam == steam and v.protect2Paused) then
				if (dist > 100) then
					v.protect2Paused = nil
					message("pm " .. steam .. " [" .. server.chatColour .. "]Protection on your 2nd base has re-activated.[-]")
				end
			end

			if igplayers[steam].protectTest ~= nil and v.steam == steam then
				if igplayers[steam].protectTestEnd - os.time() < 0 then
					igplayers[steam].protectTest = nil
				else
					testMode = true
				end
			end

			if (v.steam ~= steam or testMode) and (v.protect2Size ~= nil)  then
				if isFriend(v.steam, steam) == false or testMode then
					if (dist < size) then
						if (accessLevel(steam) > 2) or botman.ignoreAdmins == false or testMode then

							if (players[steam].watchPlayer == true) then
								alert = false

								if (players[steam].lastBaseRaid == nil) then
									players[steam].lastBaseRaid = os.time()
									alert = true
									-- spam prevention
									igplayers[steam].xPosLastAlert = 0
									igplayers[steam].yPosLastAlert = 0
									igplayers[steam].zPosLastAlert = 0
								end

								if (os.time() - tonumber(players[steam].lastBaseRaid) > 15) and ((posX ~= igplayers[steam].xPosLastAlert) or (posY ~= igplayers[steam].yPosLastAlert) or (posZ ~= igplayers[steam].zPosLastAlert)) then
									alert = true
								end

								if (alert == true) then
									-- spam prevention
									igplayers[steam].xPosLastAlert = posX
									igplayers[steam].yPosLastAlert = posY
									igplayers[steam].zPosLastAlert = posZ

									if (dist < 20) then
										alertAdmins("Watched player " .. players[steam].id .. " " .. players[steam].name .. " is " .. string.format("%-8.2d", dist) .. " meters from " .. v.name .. "'s 2nd base teleport.")
										irc_chat(server.ircMain, server.gameDate .. " Watched player " .. players[steam].id .. " " .. players[steam].name .. " is " .. string.format("%-8.2d", dist) .. " meters from " .. v.name .. "'s 2nd base teleport")
									end

									players[steam].lastBaseRaid = os.time()
								end
							end

							igplayers[steam].raiding = true
							igplayers[steam].raidingBase = k

							-- do the base protection magic

							-- if base owner's donor status expired a week or more ago, disable protection
							if (v.protect2 and v.protect2 == true) and v.home2X ~= 0 and v.home2Y ~= 0 and v.home2Z ~= 0 then
								if os.time() - tonumber(players[k].donorExpiry) > (60 * 60 * 24 * 7) then
									players[k].protect2 = false
									if botman.dbConnected then conn:execute("UPDATE players SET protect2 = 0 WHERE steam = " .. k) end
								end
							end

							if (v.protect2 and v.protect2Size and v.protect2 == true and not v.protect2Paused) and v.home2X ~= 0 and v.home2Y ~= 0 and v.home2Z ~= 0 then
								irc_chat(server.ircAlerts, "base protection triggered for base2 of " .. players[k].name .. " " .. k .. " against " .. players[steam].name .. " " .. steam)

								if (igplayers[k] ~= nil) and not igplayers[k].currentLocationPVP then
									message("pm " .. k .. " [" .. server.chatColour .. "]" .. igplayers[steam].name .. " has been ejected from your 2nd base.[-]")
								end

								alertAdmins(igplayers[steam].name .. " has been ejected from " .. v.name  .."'s 2nd base.")

								if distancexz(igplayers[steam].xPosLastOK, igplayers[steam].zPosLastOK, v.home2X, v.home2Z) > v.protect2Size then
									message("pm " .. steam .. " [" .. server.chatColour .. "]You are too close to a protected player base.  The base owner needs to add you to their friends list by typing " .. server.commandPrefix .. "friend " .. igplayers[steam].name .. "[-]")
									cmd = "tele " .. steam .. " " .. igplayers[steam].xPosLastOK .. " -1 " .. igplayers[steam].zPosLastOK

									prepareTeleport(steam, cmd)
--									dbug("base_protection line " .. debugger.getinfo(1).currentline)	
									teleport(cmd, true)
								else
									cmd = "tele " .. steam .. " " .. v.exit2X .. " -1 " .. v.exit2Z
									prepareTeleport(steam, cmd)

--									dbug("base_protection line " .. debugger.getinfo(1).currentline)	
									teleport(cmd, true)
									message("pm " .. steam .. " [" .. server.chatColour .. "]You are too close to a protected player base.  The base owner needs to add you to their friends list by typing " .. server.commandPrefix .. "friend " .. igplayers[steam].name .. "[-]")
								end

								return true
							end
						end
					end
				end
			end
		end

	end


	-- location/village protection
	if (accessLevel(steam) > 2) or botman.ignoreAdmins == false then --  or testMode
		for k, v in pairs(locations) do
			if (v.protected and tonumber(v.x) ~= 0 and tonumber(v.y) ~= 0 and tonumber(v.z) ~= 0) then
				if (not LookupVillager(steam, k) ) and steam ~= v.owner then
					dist = distancexz(posX, posZ, v.x, v.z)

					if v.size == nil then
						size = tonumber(server.baseSize)
					else
						size = tonumber(v.size)
					end

					if tonumber(dist) < tonumber(size) then
						igplayers[steam].raiding = true

						-- do the base protection magic
						if distancexz(igplayers[steam].xPosLastOK, igplayers[steam].zPosLastOK, v.x, v.z) > tonumber(size) then
							message("pm " .. steam .. " [" .. server.chatColour .. "]You are too close to " .. k .. ".[-]")
							cmd = "tele " .. steam .. " " .. igplayers[steam].xPosLastOK .. " -1 " .. igplayers[steam].zPosLastOK
							igplayers[steam].lastTP = cmd

--							dbug("base_protection for village line " .. debugger.getinfo(1).currentline)	
							teleport(cmd, true)
						else
							cmd = "tele " .. steam .. " " .. v.exitX .. " -1 " .. v.exitZ
							igplayers[steam].lastTP = cmd

--							dbug("base_protection for village line " .. debugger.getinfo(1).currentline)	
							teleport(cmd, true)
							message("pm " .. steam .. " [" .. server.chatColour .. "]You are too close to " .. k .. ".[-]")
						end

						return true
					end
				end
			end
		end
	end

end
