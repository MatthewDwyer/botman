--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function llp(line)
	local x, y, z, expired, archived, removeClaims, testing, keystoneCount, noPlayer, pos, tmp, status, errorString

	tmp = {}

	if string.find(line, "Player ") and string.find(line, "owns ") then
		tmp.pos = string.find(line, "EOS")
		tmp.userID = string.sub(line, tmp.pos, tmp.pos + 35)
		keystoneCount = string.sub(line, string.find(line, "owns ") + 5, string.find(line, " keystones") - 1)
		noPlayer = true
		archived = false
		expired = false

		tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.userID)

		if string.find(line, "protected: False", nil, true) then
			expired = true
		end

		if not players[tmp.steam] then
			noPlayer = false
			archived = true
			playersArchived[tmp.steam].keystones = keystoneCount
			playersArchived[tmp.steam].claimsExpired = expired

			if playersArchived[tmp.steam].removedClaims == nil then
				playersArchived[tmp.steam].removedClaims = 0
			end

			if botman.dbConnected then conn:execute("UPDATE players SET keystones = " .. playersArchived[tmp.steam].keystones .. ", claimsExpired = " .. dbBool(expired) .. " WHERE steam = '" .. tmp.steam .. "'") end
		end

		if players[tmp.steam] then
			noPlayer = false
			players[tmp.steam].keystones = keystoneCount
			players[tmp.steam].claimsExpired = expired

			if players[tmp.steam].removedClaims == nil then
				players[tmp.steam].removedClaims = 0
			end

			if botman.dbConnected then conn:execute("UPDATE players SET keystones = " .. players[tmp.steam].keystones .. ", claimsExpired = " .. dbBool(expired) .. " WHERE steam = '" .. tmp.steam .. "'") end
		end
	end

	-- Output of parseable
	if string.find(line, "LandProtectionOf:") then
		tmp.pos = string.find(line, "EOS")
		tmp.userID = string.sub(line, tmp.pos, tmp.pos + 35)
		tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.userID)

		coords = string.sub(line, string.find(line, "location") + 9)
		coords = string.split(coords, ",")
		x = tonumber(coords[1])
		y = tonumber(coords[2])
		z = tonumber(coords[3])

		if not noPlayer then
			if archived then
				expired = playersArchived[tmp.steam].claimsExpired
				testing = playersArchived[tmp.steam].testAsPlayer
				removeClaims = playersArchived[tmp.steam].removeClaims
			else
				expired = players[tmp.steam].claimsExpired
				testing = players[tmp.steam].testAsPlayer
				removeClaims = players[tmp.steam].removeClaims
			end
		else
			-- found a claim with no owner
			expired = true
			removeClaims = server.removeExpiredClaims
			testing = false
		end

		if tonumber(y) > 0 then
			if botman.dbConnected then
				connSQL:execute("UPDATE keystones SET expired = " .. dbBool(expired) .. ", removed = 0, remove = " .. dbBool(removeClaims) .. " WHERE steam = '" .. tmp.userID .. "' AND x = " .. x .. " AND y = " .. y .. " AND z = " .. z)
			end

			if not keystones[x .. y .. z] then
				keystones[x .. y .. z] = {}
				keystones[x .. y .. z].x = x
				keystones[x .. y .. z].y = y
				keystones[x .. y .. z].z = z
				keystones[x .. y .. z].steam = tmp.steam
				keystones[x .. y .. z].userID = tmp.userID
			end

			keystones[x .. y .. z].expired = expired
			keystones[x .. y .. z].removed = 0

			if removeClaims then
				keystones[x .. y .. z].remove = true
			else
				keystones[x .. y .. z].remove = false
			end

			if not isAdminHidden(tmp.steam, tmp.userID) then
				region = getRegion(x, z)
				loc, reset = inLocation(x, z)

				if (resetRegions[region] or reset or removeClaims) and not testing then
					status, errorString = connSQL:execute("INSERT INTO keystones (steam, x, y, z, expired, remove, removed) VALUES ('" .. tmp.userID .. "'," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ",1,0)")

					if not status then
						connSQL:execute("UPDATE keystones SET expired = " .. dbBool(expired) .. ", remove = 1, removed = 0  WHERE steam = '" .. tmp.userID .. "' AND x = " .. x .. " AND y = " .. y .. " AND z = " .. z)
					end
				else
					status, errorString = connSQL:execute("INSERT INTO keystones (steam, x, y, z, expired, remove, removed) VALUES ('" .. tmp.userID .. "'," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ",0,0)")

					if not status then
						connSQL:execute("UPDATE keystones SET expired = " .. dbBool(expired) .. ", remove = 0, removed = 0  WHERE steam = '" .. tmp.userID .. "' AND x = " .. x .. " AND y = " .. y .. " AND z = " .. z)
					end
				end
			else
				status, errorString = connSQL:execute("INSERT INTO keystones (steam, x, y, z, expired, remove, removed) VALUES ('" .. tmp.userID .. "'," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ",0,0)")

				if not status then
					connSQL:execute("UPDATE keystones SET expired = " .. dbBool(expired) .. ", remove = 0, removed = 0  WHERE steam = '" .. tmp.userID .. "' AND x = " .. x .. " AND y = " .. y .. " AND z = " .. z)
				end
			end
		end
	end
end


function llpTrigger(line)
	if botman.botDisabled then
		return
	end

	if string.find(line, "LandProtectionOf") or string.find(line, "Executing command 'llp") or string.find(line, "keystones (protected", nil, true) then
		llp(line)
	end
end
