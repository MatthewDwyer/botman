--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function trackPlayerTimer()
	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	local row, rows, k, v, cursor, errorString

	for k, v in pairs(igplayers) do
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

					if not cursor then
						return
					end

					row = cursor:fetch({}, "a")

					if row then
						sendCommand("tele " .. k .. " " .. row.x .. " " .. row.y .. " " .. row.z)

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end
					end

					while row do
						row = cursor:fetch(row, "a")
						v.trackerCount = row.trackerID
					end

					v.trackerStopped = true

					if v.trackerStop ~= nil then
						v.trackerStopped = true
						v.trackerStop = nil
					end

					if igplayers[chatvars.playerid].trackerLastSession then
						message("pm " .. k .. " [" .. server.chatColour .. "]Tracking complete. You have reached the players current position.[-]")
					else
						message("pm " .. k .. " [" .. server.chatColour .. "]Tracking complete. Type " .. server.commandPrefix .. "next track or " .. server.commandPrefix .. "last track to continue from the next session.[-]")
					end
				end
			end
		end
	end
end
