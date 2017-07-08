--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug = false

function collectBan(line)
	if botman.botDisabled then
		return
	end

	local temp, reason, yr, mth, dy, hr, min, sec, tdate, steam, expiryDate, bannedTo, listParse


	if(debug) then dbugFull("D", "" , debugger.getinfo(1,"nSl"), line) end

	temp = string.split(string.trim(line), " ")

	tdate = string.split(temp[4], "-")
	if(type(tdate) ~= "table" or table.getn(tdate) < 3) then
		tdate = string.split(temp[1],"-")
		if(type(tdate) ~= "table" or table.getn(tdate) < 3) then
			dbugFull("E", "", debugger.getinfo(1,"nSl"), "Invalid date parse from: " .. (temp[4] or "nil") .. "(" .. line ..")")
			return
		end

		listParse = true
	end

	if(not listParse) then
		yr = tonumber(tdate[1])
		mth = tonumber(tdate[3])
		dy = tonumber(tdate[2])
	else
		yr = tonumber(tdate[1])
		mth = tonumber(tdate[2])
		dy = tonumber(tdate[3])
	end

	if(not listParse) then
		tdate = string.split(temp[5], ":")
	else	
		tdate = string.split(temp[2], ":")
	end

	hr = tonumber(tdate[1])
	min = tonumber(tdate[2])
	tdate[3] = string.gsub(tdate[3], "," , "")
	sec = tonumber(tdate[3])

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), (table.getn(tdate) or "nil") .. ", " .. tostring(ListParse) .. ", " .. (hr or "nil") .. ", " .. (min or "nil") .. ", " .. (sec or "nil") .. " from: " .. line) end

	if(not listParse and temp[6] == "PM,") then
		hr = hr + 12
	end

	expiryDate = string.format("%4d-%02d-%02d %02d:%02d:%02d", yr, mth, dy, hr, min, sec)

	if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), expiryDate) end

	if(not listParse) then
		bannedTo = temp[4] .. " " .. escape(temp[5]) .. " " .. escape(string.sub(temp[6], 1, 2))
		steam = temp[1]
		reason = string.sub(line, string.find(line, "reason:") + 8)
	else
		bannedTo = temp[1] .. " " .. escape(temp[2])
		steam = temp[4]
		reason = temp[6]
	end

	reason = string.gsub(reason, "%%22", "")
	reason = string.gsub(reason, "%%2", " ")

	if(players[steam]) then
        	name = escape(players[steam].name)

		if(name == nil) then
			name = ""
		end
        else
        	name = ""
        end

	if(debug) then dbugFull("D", "" , debugger.getinfo(1,"nSl")) end

	if(banList == nil) then
		banList = {}
	end

	if(banList[steam] == nil) then
		banList[steam] = {}
	end

	banList[steam].bannedTo = bannedTo
	banList[steam].expireDate = expiryDate
	banList[steam].reason = reason
	banList[steam].name = name

	name = "'" .. name .. "'"

	if(not listParse) then
		local dateTble = os.date("*t", os.time()) 
		banList[steam].bannedOn =  string.format("%04d-%02d-%02d %02d:%0d2:%02d", dateTble.year, dateTble.month, dateTble.day, dateTble.hour, dateTble.min, dateTble.sec)
	end

	if(debug) then dbugFull("D", "" , debugger.getinfo(1,"nSl")) end

	if botman.dbConnected then 
		local cursor, errMsg, MysqlCMD, name

		if(players[steam]) then
			name = "'" .. escape(players[steam].name) .. "'"
		else
			name = "''"
		end

		if(debug) then dbugFull("D", "" , debugger.getinfo(1,"nSl")) end

		MysqlCMD = "INSERT IGNORE INTO bans " .. 
			   "(BannedTo, Steam, Reason, expiryDate, bannedOn, name) " ..
			   "VALUES ('" .. escape(bannedTo) .. "'," .. steam .. ",'" .. (escape(reason) or "") .. "','" .. expiryDate .. "', '" .. (banList[steam].bannedOn or "0000-00-00 00:00:00") .. "', " .. name  .. ")"

		if(debug) then dbugFull("D", "", debugger.getinfo(1,"nSl"), "MysqlCMD = " .. MysqlCMD) end

		cursor, errMsg = conn:execute(MysqlCMD)

		if(cursor ~= nil and type(cursor) ~= "number") then cursor:close() end

		if(errMsg ~= nil) then
			dbugFull("E", "", debugger.getinfo(1,"nSl"), "MSQL error: " .. errMsg)
			return
		end
	end

	if botman.db2Connected then
		-- update the ban on bots db to fill in the missing bannedTo field since we didn't calculate it earlier
		connBots:execute("UPDATE bans set bannedTo = '" .. bannedTo .. "' WHERE bannedTo = 'MISSING' AND botID = '" .. server.botID .. "'")
	end
end
