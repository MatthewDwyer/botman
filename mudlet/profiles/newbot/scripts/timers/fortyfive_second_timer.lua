--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function fortyfiveSecondTimer()
	local k, v, x, z, row, cursor, errorString

	if botman.botDisabled or botman.botOffline or server.lagged or not botman.dbConnected then
		return
	end

	if customFortyfiveSecondTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customFortyfiveSecondTimer() then
			return
		end
	end

	-- conn:execute("UPDATE keystones SET removed = 1")

	-- for k, v in pairs(igplayers) do
		-- if v.claimPass == nil then v.claimPass = 1 end

		-- if accessLevel(k) > 2 then
			-- cursor,errorString = conn:execute("SELECT count(remove) as deleted FROM keystones WHERE steam = " .. k .. " AND remove = 2")

			-- if cursor then
				-- row = cursor:fetch({}, "a")

				-- if tonumber(row.deleted) > 0 then
					-- players[k].removedClaims = players[k].removedClaims + tonumber(row.deleted)
					-- players[k].alertRemovedClaims = true
					-- conn:execute("DELETE FROM keystones WHERE steam = " .. k .. " AND remove = 2")
				-- end

				-- if v.claimPass == 1 then
					-- x = math.floor(v.xPos / 512)
					-- z = math.floor(v.zPos / 512)
					-- checkRegionClaims(x, z)

					-- v.claimPass = 2
				-- else
					-- if server.enableTimedClaimScan then
						-- sendCommand("llp " .. k)
					-- end

					-- v.claimPass = 1
				-- end
			-- end
		-- else
			-- x = math.floor(v.xPos / 512)
			-- z = math.floor(v.zPos / 512)
		-- end
	-- end
end
