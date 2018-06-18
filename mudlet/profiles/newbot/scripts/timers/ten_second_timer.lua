--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function TenSecondTimer()
	if botman.botDisabled then
		return
	end

	if botman.botOffline then
		return
	end

	if customTenSecondTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customTenSecondTimer() then
			return
		end
	end

	if server.lagged then
		-- test for telnet command lag as it can creep up on busy servers or when there are lots of telnet errors going on
		if not botman.botOffline and not botman.botDisabled then
			if server.enableLagCheck then
				botman.lagCheckTime = os.time()
				send("pm LagCheck " .. os.time())
			end

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end
		else
			if server.enableLagCheck then
				botman.lagCheckTime = os.time()
			end

			server.lagged = false
		end
	end

	if botman.botOffline or botman.botDisabled or server.lagged then
		return
	end

	if server.coppi then
		-- here we only test new players for flying/clipping
		-- we'll test everyone else on either the 15 second or 30 second timer depending on how many are playing now
		for k,v in pairs(igplayers) do
			if players[k].newPlayer then
				if server.scanNoclip then
					-- check for noclipped players
					send("pug " .. k)

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
				end

				if not server.playersCanFly then
					-- check for flying players
					send("pgd " .. k)

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
				end
			end
		end
	end
end