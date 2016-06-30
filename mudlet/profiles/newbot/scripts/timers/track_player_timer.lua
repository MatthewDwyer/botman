--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function trackPlayerTimer()
	if botDisabled then
		return
	end

	local lastSession, rows

	for k, v in pairs(igplayers) do	
		lastSession = false

		if v.trackerCount ~= nil then
			if v.trackerStopped == false then
				v.trackerCountdown = tonumber(v.trackerCountdown) - 1

				if (v.trackerCountdown < 1) then
					v.trackerCountdown = v.trackerSpeed

					if v.trackerReversed then
						cursor,errorString = conn:execute("select * from memTracker where admin = " .. k .. " and trackerID < " .. v.trackerCount .. " order by trackerID desc limit 0," .. v.trackerSkip + 1)
					else
						cursor,errorString = conn:execute("select * from memTracker where admin = " .. k .. " and trackerID > " .. v.trackerCount .. " order by trackerID limit 0," .. v.trackerSkip + 1)
					end

					rows = cursor:numrows()

					if rows > 0 then
						row = cursor:fetch({}, "a")

						if tonumber(row.session) == tonumber(players[row.steam].sessionCount) then lastSession = true end

						send("tele " .. k .. " " .. row.x .. " " .. row.y .. " " .. row.z)

						if rows == 1 then
							v.trackerStopped = true

							if lastSession then
								message("pm " .. k .. " [" .. server.chatColour .. "]Tracking complete. You have reached the players current position.[-]")
							else
								message("pm " .. k .. " [" .. server.chatColour .. "]Tracking complete. Type /next track or /last track to continue from the next session.[-]")
							end
						end

						while row do
							row = cursor:fetch(row, "a")	

							if row.trackerID == nil then
								v.trackerStopped = true

								if lastSession then
									message("pm " .. k .. " [" .. server.chatColour .. "]Tracking complete. You have reached the players current position.[-]")
								else
									message("pm " .. k .. " [" .. server.chatColour .. "]Tracking complete. Type /next track or /last track to continue from the next session.[-]")
								end
							end

							v.trackerCount = row.trackerID
						end

						if v.trackerStop ~= nil then
							v.trackerStopped = true
							v.trackerStop = nil
						end
					else
						v.trackerStopped = true

						if lastSession then
							message("pm " .. k .. " [" .. server.chatColour .. "]Tracking complete. You have reached the players current position.[-]")
						else
							message("pm " .. k .. " [" .. server.chatColour .. "]Tracking complete. Type /next track or /last track to continue from the next session.[-]")
						end
					end
				end
			end
		end
	end
end
