--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

 -- These are run every second

function trackPlayerTimer()
	if botman.botDisabled or botman.botOffline or not botman.dbConnected then
		return
	end

	local row, rows, k, v, cursor, errorString
	cursor,errorString = connMEM:execute("SELECT * FROM tracker")
	row = cursor:fetch({}, "a")

	if not row then
		disableTimer("TrackPlayer")
	end

	for k, v in pairs(igplayers) do
		if v.trackerCount ~= nil then
			if v.trackerStopped == false then
				v.trackerCountdown = tonumber(v.trackerCountdown) - 1

				if (v.trackerCountdown < 1) then
					v.trackerCountdown = v.trackerSpeed

					if v.trackerReversed then
						cursor,errorString = connMEM:execute("SELECT * FROM tracker WHERE admin = '" .. k .. "' AND trackerID < " .. v.trackerCount .. " ORDER BY trackerID DESC LIMIT " .. v.trackerSkip + 1)
					else
						cursor,errorString = connMEM:execute("SELECT * FROM tracker WHERE admin = '" .. k .. "' AND trackerID > " .. v.trackerCount .. " ORDER BY trackerID LIMIT " .. v.trackerSkip + 1)
					end

					if not cursor then
						return
					end
					row = cursor:fetch({}, "a")

					if row then
						sendCommand("tele " .. v.userID .. " " .. row.x .. " " .. row.y .. " " .. row.z)
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
						message("pm " .. v.userID .. " [" .. server.chatColour .. "]Tracking complete. You have reached the players current position.[-]")
					else
						message("pm " .. v.userID .. " [" .. server.chatColour .. "]Tracking complete. Type " .. server.commandPrefix .. "next track or " .. server.commandPrefix .. "last track to continue from the next session.[-]")
					end
				end
			end
		end
	end
end
