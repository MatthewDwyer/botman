--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function collectBan(line)
	if botDisabled then
		return
	end

	local temp, reason, yr, mth, dy, hr, min, sec, tdate, steam, expiryDate, bannedTo

	temp = string.split(line, " ")

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
	expiryDate = yr .. "-" .. mth .. "-" .. dy .. " " .. hr .. ":" .. min .. ":" .. sec
	steam = temp[1]
	reason = string.sub(line, string.find(line, "reason:") + 8)

	if reason ~= nil then
		conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. bannedTo .. "'," .. steam .. ",'" .. escape(reason) .. "','" .. expiryDate .. "'")
	else
		conn:execute("INSERT INTO bans (BannedTo, steam, expiryDate) VALUES ('" .. bannedTo .. "'," .. steam .. ",'" .. expiryDate .. "'")
	end

	if db2Connected then
		-- update the ban on bots db to fill in the missing bannedTo field since we didn't calculate it earlier
		connBots:execute("UPDATE bans set bannedTo = '" .. bannedTo .. "' WHERE bannedTo = 'MISSING' AND botID = '" .. server.botID .. "'")
	end
end
