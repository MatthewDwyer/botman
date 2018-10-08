--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function llp(line)
	local x, y, z, expired, archived, removeClaims, testing, keystoneCount, steam, noPlayer

	if string.find(line, "Player ") and string.find(line, "owns ") then
		steam = string.sub(line, string.find(line, "7656"), string.find(line, "7656") + 16)
		keystoneCount = string.sub(line, string.find(line, "owns ") + 5, string.find(line, " keystones") - 1)
		noPlayer = true
		archived = false
		expired = false

		if string.find(line, "protected: False", nil, true) then
			expired = true
		end

		if not players[steam] then
			noPlayer = false
			archived = true
			playersArchived[steam].keystones = keystoneCount
			playersArchived[steam].claimsExpired = expired

			if playersArchived[steam].removedClaims == nil then
				playersArchived[steam].removedClaims = 0
			end

			if botman.dbConnected then conn:execute("UPDATE players SET keystones = " .. playersArchived[steam].keystones .. ", claimsExpired = " .. dbBool(expired) .. " WHERE steam = " .. steam) end
		end

		if players[steam] then
			noPlayer = false
			players[steam].keystones = keystoneCount
			players[steam].claimsExpired = expired

			if players[steam].removedClaims == nil then
				players[steam].removedClaims = 0
			end

			if botman.dbConnected then conn:execute("UPDATE players SET keystones = " .. players[steam].keystones .. ", claimsExpired = " .. dbBool(expired) .. " WHERE steam = " .. steam) end
		end
	end

	-- Output of parseable
	if string.find(line, "LandProtectionOf:") then
		steam = string.sub(line, string.find(line, "7656"), string.find(line, "7656") + 16)

		coords = string.sub(line, string.find(line, "location") + 9)
		coords = string.split(coords, ",")
		x = tonumber(coords[1])
		y = tonumber(coords[2])
		z = tonumber(coords[3])

		if not noPlayer then
			if archived then
				expired = playersArchived[steam].claimsExpired
				testing = playersArchived[steam].testAsPlayer
				removeClaims = playersArchived[steam].removeClaims
			else
				expired = players[steam].claimsExpired
				testing = players[steam].testAsPlayer
				removeClaims = players[steam].removeClaims
			end
		else
			-- found a claim with no owner
			expired = true
			removeClaims = server.removeExpiredClaims
			testing = false
		end

		if tonumber(y) > 0 then
			if botman.dbConnected then
				conn:execute("UPDATE keystones SET expired = " .. dbBool(expired) .. ", removed = 0, remove = " .. dbBool(removeClaims) .. " WHERE steam = " .. steam .. " AND x = " .. x .. " AND y = " .. y .. " AND z = " .. z)
			end

			if not keystones[x .. y .. z] then
				keystones[x .. y .. z] = {}
				keystones[x .. y .. z].x = x
				keystones[x .. y .. z].y = y
				keystones[x .. y .. z].z = z
				keystones[x .. y .. z].steam = steam
			end

			keystones[x .. y .. z].expired = expired
			keystones[x .. y .. z].removed = 0

			if removeClaims then
				keystones[x .. y .. z].remove = true
			else
				keystones[x .. y .. z].remove = false
			end

			if accessLevel(steam) > 3 then
				region = getRegion(x, z)
				loc, reset = inLocation(x, z)

				if (resetRegions[region] or reset or removeClaims) and not testing then
					if botman.dbConnected then conn:execute("INSERT INTO keystones (steam, x, y, z, expired, remove, removed) VALUES (" .. steam .. "," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ",1,0) ON DUPLICATE KEY UPDATE expired = " .. dbBool(expired) .. ", remove = 1, removed = 0") end
				else
					if botman.dbConnected then conn:execute("INSERT INTO keystones (steam, x, y, z, expired, remove, removed) VALUES (" .. steam .. "," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ",0,0) ON DUPLICATE KEY UPDATE expired = " .. dbBool(expired) .. ", remove = 0, removed = 0") end
				end
			else
				if botman.dbConnected then conn:execute("INSERT INTO keystones (steam, x, y, z, expired, remove, removed) VALUES (" .. steam .. "," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ",0,0) ON DUPLICATE KEY UPDATE expired = " .. dbBool(expired) .. ", remove = 0, removed = 0") end
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
