--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function collectBan(line)
	if botman.botDisabled then
		return
	end

	local temp, reason, yr, mth, dy, hr, min, sec, tdate, steam, expiryDate, bannedTo

	temp = string.split(line, " ")
	temp[5] = string.sub(temp[5], 1, string.len(temp[5]) - 2)

	tdate = string.split(temp[4], "/")
	yr = tdate[3]
	mth = tdate[1]
	dy = tdate[2]

	tdate = string.split(temp[5], ":")
	hr = tonumber(tdate[1])
	min = tdate[2]
	sec = tdate[3]

	if temp[6] == "PM," then
		hr = hr + 12
	end

	bannedTo = temp[4] .. " " .. escape(temp[5]) .. " " .. escape(string.sub(temp[6], 1, 2))
	expiryDate = yr .. mth .. dy .. " " .. hr .. ":" .. min .. ":" .. sec
	steam = temp[1]
	reason = string.sub(line, string.find(line, "reason:") + 8)

	if reason ~= nil then
		if botman.dbConnected then conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. bannedTo .. "'," .. steam .. ",'" .. escape(reason) .. "',STR_TO_DATE('" .. expiryDate .. "', '%Y%m%d %H:%i:%s')") end
	else
		if botman.dbConnected then conn:execute("INSERT INTO bans (BannedTo, steam, expiryDate) VALUES ('" .. bannedTo .. "'," .. steam .. ",STR_TO_DATE('" .. expiryDate .. "', '%Y%m%d %H:%i:%s')") end
	end

	if botman.botsConnected then
		-- update the ban on bots db to fill in the missing bannedTo field since we didn't calculate it earlier
		connBots:execute("UPDATE bans set bannedTo = '" .. bannedTo .. "' WHERE bannedTo = 'MISSING' AND botID = '" .. server.botID .. "'")
	end
end
