--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function updatePlayer(steam)
	fixMissingPlayer(steam)

	-- update the db
	fields = {}
	values = {}
--dbug("update player " .. steam)

	if players[steam].steamOwner ~= nil then
		table.insert(fields, "steamOwner")
		table.insert(values, players[steam].steamOwner)
	end

	if players[steam].xPos ~= nil then
		table.insert(fields, "xpos")
		table.insert(values, players[steam].xPos)
	end

	if players[steam].yPos ~= nil then
		table.insert(fields, "ypos")
		table.insert(values, players[steam].yPos)
	end

	if players[steam].zPos ~= nil then
		table.insert(fields, "zpos")
		table.insert(values, players[steam].zPos)
	end

	if players[steam].homeX ~= nil then
		table.insert(fields, "homex")
		table.insert(values, players[steam].homeX)
	end

	if players[steam].homeY ~= nil then
		table.insert(fields, "homey")
		table.insert(values, players[steam].homeY)
	end

	if players[steam].homeZ ~= nil then
		table.insert(fields, "homez")
		table.insert(values, players[steam].homeZ)
	end

	if players[steam].home2X ~= nil then
		table.insert(fields, "home2x")
		table.insert(values, players[steam].home2X)
	end

	if players[steam].home2Y ~= nil then
		table.insert(fields, "home2y")
		table.insert(values, players[steam].home2Y)
	end
	
	if players[steam].home2Z ~= nil then
		table.insert(fields, "home2z")
		table.insert(values, players[steam].home2Z)
	end

	if players[steam].exitX ~= nil then
		table.insert(fields, "exitx")
		table.insert(values, players[steam].exitX)
	end

	if players[steam].exitY ~= nil then
		table.insert(fields, "exity")
		table.insert(values, players[steam].exitY)
	end

	if players[steam].exitZ ~= nil then
		table.insert(fields, "exitz")
		table.insert(values, players[steam].exitZ)
	end

	if players[steam].exit2X ~= nil then
		table.insert(fields, "exit2x")
		table.insert(values, players[steam].exit2X)
	end

	if players[steam].exit2Y ~= nil then
		table.insert(fields, "exit2y")
		table.insert(values, players[steam].exit2Y)
	end

	if players[steam].exit2Z ~= nil then
		table.insert(fields, "exit2z")
		table.insert(values, players[steam].exit2Z)
	end

	if players[steam].xPosOld ~= nil then
		table.insert(fields, "xposold")
		table.insert(values, players[steam].xPosOld)
	end

	if players[steam].yPosOld ~= nil then
		table.insert(fields, "yposold")
		table.insert(values, players[steam].yPosOld)
	end

	if players[steam].zPosOld ~= nil then
		table.insert(fields, "zposold")
		table.insert(values, players[steam].zPosOld)
	end

	if players[steam].timeOnServer ~= nil then
		table.insert(fields, "timeonserver")
		table.insert(values, players[steam].timeOnServer)
	end

	if players[steam].seen ~= nil then
		table.insert(fields, "seen")
		table.insert(values, players[steam].seen)
	end

	if players[steam].playerKills ~= nil then
		table.insert(fields, "playerkills")
		table.insert(values, players[steam].playerKills)
	end

	if players[steam].deaths ~= nil then
		table.insert(fields, "deaths")
		table.insert(values, players[steam].deaths)
	end

	if players[steam].zombies ~= nil then
		table.insert(fields, "zombies")
		table.insert(values, players[steam].zombies)
	end

	if players[steam].level ~= nil then
		table.insert(fields, "level")
		table.insert(values, players[steam].level)
	end

	if players[steam].ping ~= nil then
		table.insert(fields, "ping")
		table.insert(values, players[steam].ping)
	end

	if players[steam].score ~= nil then
		table.insert(fields, "score")
		table.insert(values, players[steam].score)
	end

	if players[steam].tokens ~= nil then
		table.insert(fields, "tokens")
		table.insert(values, players[steam].tokens)
	end

	if players[steam].baseCooldown ~= nil then
		table.insert(fields, "basecooldown")
		table.insert(values, players[steam].baseCooldown)
	end

	if players[steam].cash ~= nil then
		table.insert(fields, "cash")
		table.insert(values, players[steam].cash)
	end

	if players[steam].sessionCount ~= nil then
		table.insert(fields, "sessionCount")
		table.insert(values, players[steam].sessionCount)
	end

	if players[steam].waypointX ~= nil then
		table.insert(fields, "waypointx")
		table.insert(values, players[steam].waypointX)
	end

	if players[steam].waypointY ~= nil then
		table.insert(fields, "waypointy")
		table.insert(values, players[steam].waypointY)
	end

	if players[steam].waypointZ ~= nil then
		table.insert(fields, "waypointz")
		table.insert(values, players[steam].waypointZ)
	end

	table.insert(fields, "accesslevel")
	table.insert(values, accessLevel(steam))

	if players[steam].protectSize ~= nil then
		table.insert(fields, "protectsize")
		table.insert(values, players[steam].protectSize)
	end

	if players[steam].protect2Size ~= nil then
		table.insert(fields, "protect2size")
		table.insert(values, players[steam].protect2Size)
	end

	if players[steam].keystones ~= nil then
		table.insert(fields, "keystones")
		table.insert(values, players[steam].keystones)
	end

	if players[steam].donor ~= nil then
		table.insert(fields, "donor")
		table.insert(values, players[steam].donor)
	end

	if players[steam].walkies ~= nil then
		table.insert(fields, "walkies")
		table.insert(values, players[steam].walkies)
	end

	if players[steam].protect ~= nil then
		table.insert(fields, "protect")
		table.insert(values, players[steam].protect)
	end

	if players[steam].protect2 ~= nil then
		table.insert(fields, "protect2")
		table.insert(values, players[steam].protect2)
	end

	if players[steam].timeout ~= nil then
		table.insert(fields, "timeout")
		table.insert(values, players[steam].timeout)
	end

	if players[steam].botTimeout ~= nil then
		table.insert(fields, "bottimeout")
		table.insert(values, players[steam].botTimeout)
	end	

	if players[steam].newPlayer ~= nil then
		table.insert(fields, "newplayer")
		table.insert(values, players[steam].newPlayer)
	end

	if players[steam].prisoner ~= nil then
		table.insert(fields, "prisoner")
		table.insert(values, players[steam].prisoner)
	end

	if players[steam].shareWaypoint ~= nil then
		table.insert(fields, "sharewaypoint")
		table.insert(values, players[steam].shareWaypoint)
	end

	if players[steam].canTeleport ~= nil then
		table.insert(fields, "canteleport")
		table.insert(values, players[steam].canTeleport)
	end

	if players[steam].country ~= nil then
		table.insert(fields, "country")
		table.insert(values, players[steam].country)
	end

	if players[steam].donorLevel ~= nil then
		table.insert(fields, "donorlevel")
		table.insert(values, players[steam].donorLevel)
	end

	if players[steam].donorExpiry ~= nil then
		table.insert(fields, "donorexpiry")
		table.insert(values, players[steam].donorExpiry)
	end

	if players[steam].autoFriend ~= nil then
		table.insert(fields, "autofriend")
		table.insert(values, players[steam].autoFriend)
	end

	if players[steam].IP ~= nil then
		table.insert(fields, "ip")
		table.insert(values, players[steam].IP)
	end

	if players[steam].bedX ~= nil then
		table.insert(fields, "bedx")
		table.insert(values, players[steam].bedX)
	end

	if players[steam].bedY ~= nil then
		table.insert(fields, "bedy")
		table.insert(values, players[steam].bedY)
	end

	if players[steam].bedZ ~= nil then
		table.insert(fields, "bedz")
		table.insert(values, players[steam].bedZ)
	end

	if players[steam].silentBob ~= nil then
		table.insert(fields, "silentbob")
		table.insert(values, players[steam].silentBob)
	end
	
	if players[steam].ISP ~= nil then
		table.insert(fields, "isp")
		table.insert(values, players[steam].ISP)
	end
	
	if players[steam].ignorePlayer ~= nil then
		table.insert(fields, "ignoreplayer")
		table.insert(values, players[steam].ignorePlayer)
	end

--debugdb = true
	savePlayer(steam, fields, values)
debugdb = false
end


function getServerFields()
	local field

	--function inspect the server table and store field names and types
	serverFields = {}

	cursor,errorString = conn:execute("SHOW FIELDS FROM server")
	row = cursor:fetch({}, "a")
	while row do
		field = string.lower(row.Field)

		serverFields[field] = {}
		serverFields[field].type = string.sub(row.Type, 1,3)
		row = cursor:fetch(row, "a")	
	end
end

--[[
	-- typical use
	fields = {}
	values = {}
	table.insert(fields, "LootRespawnDays")
	table.insert(values, number)
	saveServer(fields, values)
--]]

function saveServer(fields, values)
	local i, sql

	if debugdb then
		dbug("saving to server table")
	end

	if serverFields == nil then
		getServerFields()
	end

	sql = "UPDATE server SET"

	for i=1,table.maxn(fields),1 do
		fields[i] = string.lower(fields[i])

		if serverFields[fields[i]].type == "var" then
			values[i] = "'" .. escape(values[i]) .. "'"
		end

		if serverFields[fields[i]].type == "tin" then
			if values[i] == true then values[i] = 1 end
			if values[i] == false then values[i] = 0 end
		end

		sql = sql .. " " .. fields[i] .. "=" .. values[i] .. ","
	end

	sql = string.sub(sql, 1, string.len(sql) - 1)

	if debugdb then
		dbug("save server " .. sql)
	end

	status, errorString = conn:execute(sql)
	
	print(status,errorString )

	if status == 0 then
		if debugdb then
			dbug("save server failed")
		end

		getServerFields()
		return false -- update failed
	else
		if debugdb then
			dbug("save server success")
		end

		return true -- update success
	end
end


function getPlayerFields()
	local field

	--function inspect the player table and store field names and types
	playerFields = {}

	cursor,errorString = conn:execute("SHOW FIELDS FROM players")
	row = cursor:fetch({}, "a")
	while row do
		field = string.lower(row.Field)

		playerFields[field] = {}
		playerFields[field].type = string.sub(row.Type, 1,3)
		row = cursor:fetch(row, "a")	
	end
end


function savePlayer(steam, fields, values, action)
--[[
	-- typical use
	fields = {}
	values = {}
	table.insert(fields, "LootRespawnDays")
	table.insert(values, number)
	savePlayer("1234", fields, values)
--]]

	if debugdb then
		dbug("saving player " .. steam)
		display(fields)
		display(values)
	end

	local i, sql, sqlValues, status, errorString

	if playerFields == nil then
		getPlayerFields()
	end

	if action == nil then
		sql = "UPDATE players SET"

		for i=1,table.maxn(fields),1 do
			fields[i] = string.lower(fields[i])

			if playerFields[fields[i]].type == "var" then
				values[i] = "'" .. escape(values[i]) .. "'"
			end

			if playerFields[fields[i]].type == "tin" then
				if values[i] == true then values[i] = 1 end
				if values[i] == false then values[i] = 0 end
			end

			if playerFields[fields[i]].type == "tim" then
				values[i] = "'" .. os.date("%Y-%m-%d %H:%M:%S", values[i]) .. "'"
			end

			sql = sql .. " " .. fields[i] .. "=" .. values[i] .. ","
		end

		sql = string.sub(sql, 1, string.len(sql) - 1)
		sql = sql .. " WHERE steam = '" .. steam .. "'"
	else
		sql = "INSERT INTO players ("
		sqlValues = " VALUES ("

		for i=1,table.maxn(fields),1 do
			fields[i] = string.lower(fields[i])

			if playerFields[fields[i]].type == "var" then
				values[i] = "'" .. escape(values[i]) .. "'"
			end

			if playerFields[fields[i]].type == "tin" then
				if values[i] == true then values[i] = 1 end
				if values[i] == false then values[i] = 0 end
			end
			if playerFields[fields[i]].type == "tim" then
				values[i] = "'" .. os.date("%Y-%m-%d %H:%M:%S", values[i]) .. "'"
			end

			sql = sql .. " " .. fields[i] .. ","
			sqlValues = sqlValues .. values[i] .. ","
		end

		sql = string.sub(sql, 1, string.len(sql) - 1) .. ")"
		sqlValues = string.sub(sqlValues, 1, string.len(sqlValues) - 1) .. ")"
		sql = sql .. sqlValues
	end

	if debugdb then
		dbug("save player sql " .. sql)
	end

	status, errorString = conn:execute(sql)
	
	print(status,errorString )

	if status == 0 then
		if debugdb then
			dbug("save player failed")
		end

		getPlayerFields()
		return false -- no record changed
	else
		if debugdb then
			dbug("save player success")
			dbug("save player sql " .. sql)
		end

		return true -- record inserted/updated
	end
end


function getTableFields(table)
	--function inspect the table and store field names and types
	if type(tableFields) ~= "table" then
		tableFields = {}
	end

	tableFields[table] = {}
	tableFields[table].fields = {}
	tableFields[table].types = {}

	cursor,errorString = conn:execute("SHOW FIELDS FROM " .. table)
	row = cursor:fetch({}, "a")
	while row do
		tableFields[table].fields[#tableFields[table].fields+1] = {string.lower(row.Field)}
		tableFields[table].types[#tableFields[table].types+1] = {string.lower(string.sub(row.Type, 1,3))}
		row = cursor:fetch(row, "a")	
	end
end


function saveTable(table, fields, values, condition)
-- This function does updates only, no inserts
	local i, sql

--[[
	-- typical use
	fields = {}
	values = {}
	table.insert(fields, "LootRespawnDays")
	table.insert(values, number)
	saveTable("server", fields, values, "test = true")
--]]

	if debugdb then
		dbug("saving to table " .. table)
	end

	if tableFields[table] == nil then
		getTableFields(table)
	end

	sql = "UPDATE " .. table .. " SET"

	for i=1,table.maxn(fields),1 do
		fields[i] = string.lower(fields[i])

		if tableFields[table].fields[i].type == "var" then
			values[i] = "'" .. escape(values[i]) .. "'"
		end

		if tableFields[fields[i]].type == "tin" then
			if values[i] == true then values[i] = 1 end
			if values[i] == false then values[i] = 0 end
		end

		if 	sql == "UPDATE " .. table .. " SET" then
			sql = sql .. " " .. fields[i] .. "=" .. values[i]
		else
			sql = sql .. ", " .. fields[i] .. "=" .. values[i]
		end
	end

	if condition ~= nil then
		sql = sql .. " where " .. condition
	end

	if debugdb then
		dbug("save " .. table .. " " .. sql)
	end

	status, errorString = conn:execute(sql)

	if status == 0 then
		if debugdb then
			dbug("save " .. table .. " failed")
		end

		getTableFields(table)
		return false -- update failed
	else
		if debugdb then
			dbug("save " .. table .. " success")
		end

		return true -- update success
	end
end
