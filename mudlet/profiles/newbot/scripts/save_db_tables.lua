--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
			  http://botman.nz/latest_bot.zip
--]]

local sql

function updateTable(table, key, condition)
	local k,v,value,temp, tbl

	-- update the db
	sql = {}
	tbl = table .. "Fields"

	for k,v in pairs(_G[tbl]) do
		if _G[table][key][v.field] then
			value = _G[table][key][v.field]

			sql[v.field] = {}
			sql[v.field].field = v.field
			sql[v.field].value = value
		end
	end

--debugdb = true
	saveTable(table, condition)
debugdb = false
end


function updatePlayer(steam)
	local k,v,value,temp

	if tonumber(steam) == nil or (string.len(steam) < 17) then
		dbug("skipping player " .. v.name .. " for invalid steam id")

		-- don't process if steam is invalid
		return
	end

	-- update the db
	sql = {}
--dbug("update player " .. steam)

	for k,v in pairs(playerFields) do
		if players[steam][v.field] then
			value = players[steam][v.field]

			sql[v.field] = {}
			sql[v.field].field = v.field

			if v.type == "var" then
				sql[v.field].value = stripCommas(value)
			else
				sql[v.field].value = value
			end

			if v.type == "tim" and value ~= nil then
				sql[v.field].value = "'" .. os.date("%Y-%m-%d %H:%M:%S", value) .. "'"
			end
		end
	end

--debugdb = true
	savePlayer(steam)
debugdb = false
end


function getServerFields()
	local field

	--function inspect the server table and store field names and types
	serverFields = {}

	cursor,errorString = conn:execute("SHOW FIELDS FROM server")
	row = cursor:fetch({}, "a")
	while row do
		field = row.Field
		serverFields[field] = {}
		serverFields[field].field = field
		serverFields[field].type = string.sub(row.Type, 1,3)
		serverFields[field].key = "nil"
		serverFields[field].default = "nil"

		if row.Key then
			serverFields[field].key = string.sub(row.Key, 1,3)
		end

		if row.Default then
			serverFields[field].default = row.Default
		end

		row = cursor:fetch(row, "a")
	end
end


function saveServer(fields, values)
	local i, sqlString, max

	if debugdb then
		dbug("saving to server table")
	end

	if serverFields == nil then
		getServerFields()
	end

	sqlString = "UPDATE server SET"

	max = table.maxn(fields)
	for i=1,max,1 do
		if serverFields[fields[i]].type == "var" then
			values[i] = "'" .. escape(values[i]) .. "'"
		end

		if serverFields[fields[i]].type == "tin" then
			if values[i] == true then values[i] = 1 end
			if values[i] == false then values[i] = 0 end
		end

		if serverFields[fields[i]].type == "tim" and values[i] ~= nil then
			values[i] = "'" .. os.date("%Y-%m-%d %H:%M:%S", values[i]) .. "'"
		end

		sqlString = sqlString .. " " .. fields[i] .. "=" .. values[i] .. ","
	end

	sqlString = string.sub(sqlString, 1, string.len(sqlString) - 1)

	if debugdb then
		dbug("save server " .. sqlString)
	end

	status, errorString = conn:execute(sqlString)

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
		field = row.Field

		playerFields[field] = {}
		playerFields[field].field = field
		playerFields[field].type = string.sub(row.Type, 1,3)
		playerFields[field].key = "nil"
		playerFields[field].default = "nil"

		if row.Key then
			playerFields[field].key = string.sub(row.Key, 1,3)
		end

		if row.Default then
			playerFields[field].default = row.Default
		end

		row = cursor:fetch(row, "a")
	end
end


function savePlayer(steam, action)
	local k, v, i, sqlString, sqlValues, status, errorString, max

	if debugdb then
		dbug("saving player " .. steam .. " " .. players[steam].name)
	end

	if playerFields == nil then
		getPlayerFields()
	end

	if action == nil then
		sqlString = "update players set"

		for k,v in pairs(playerFields) do
			if sql[k] and sql[k].value and v.type ~= "tim" then
--dbug("k " .. k)
--if v.type == "tin" then dbug("tim") end
--dbug("sql[k].value " .. sql[k].value)

				if v.type == "var" then
--dbug("var")
					sql[k].value = "'" .. escape(sql[k].value) .. "'"
				end

				if v.type == "tin" then
--dbug("tim")
					if sql[k].value == true then sql[k].value = 1 end
					if sql[k].value == false then sql[k].value = 0 end
				end

				if v.type == "tim" and sql[k].value ~= nil then
--dbug("tim")
				--dbug("tim " .. sql[k].value)
					sql[k].value = "'" .. os.date("%Y-%m-%d %H:%M:%S", sql[k].value) .. "'"
				end

--dbug("num")
				sqlString = sqlString .. " " .. string.lower(sql[k].field) .. "=" .. sql[k].value .. ","
			end
		end

		sqlString = string.sub(sqlString, 1, string.len(sqlString) - 1)
		sqlString = sqlString .. " where steam = '" .. steam .. "'"
	else
		sqlString = "insert into players ("
		sqlValues = " values ("

		for k,v in pairs(playerFields) do
			if sql[k] and v.type ~= "tim" then
				if v.type == "var" then
					sql[k].value = "'" .. escape(sql[k].value) .. "'"
				end

				if v.type == "tin" then
					if sql[k].value == true then sql[k].value = 1 end
					if sql[k].value == false then sql[k].value = 0 end
				end

				if v.type == "tim" then
					sql[k].value = "'" .. os.date("%Y-%m-%d %H:%M:%S", sql[k].value) .. "'"
				end

				sqlString = sqlString .. " " .. string.lower(sql[k].field) .. ","
				sqlValues = sqlValues .. sql[k].value .. ","
			end
		end

		sqlString = string.sub(sqlString, 1, string.len(sqlString) - 1) .. ")"
		sqlValues = string.sub(sqlValues, 1, string.len(sqlValues) - 1) .. ")"
		sqlString = sqlString .. sqlValues
	end

	if debugdb then
		dbug("save player sqlString " .. sqlString)
	end

	status, errorString = conn:execute(sqlString)

	if status == 0 then
		if debugdb then
			dbug("save player failed")
			dbug(status .. " " .. errorString )
		end

		getPlayerFields()
		return false -- no record changed
	else
		if debugdb then
			dbug("save player success")
			dbug("save player sqlString " .. sqlString)
		end

		return true -- record inserted/updated
	end
end


function getTableFields(table)
	local field, tbl

	--function inspect the table and store field names, types and default values
	tbl = table .. "Fields"

	_G[tbl] = {}

	cursor,errorString = conn:execute("SHOW FIELDS FROM " .. table)
	row = cursor:fetch({}, "a")

	while row do
		field = row.Field

		_G[tbl][field] = {}
		_G[tbl][field].field = field
		_G[tbl][field].type = string.sub(row.Type, 1,3)
		_G[tbl][field].key = "nil"
		_G[tbl][field].default = "nil"

		if row.Key then
			_G[tbl][field].key = string.sub(row.Key, 1,3)
		end

		if row.Default then
			_G[tbl][field].default = row.Default
		end

		row = cursor:fetch(row, "a")
	end
end


function saveTable(table, condition)
--This function does updates only, no inserts
	-- local i, sqlString, max

	-- if debugdb then
		-- dbug("saving to table " .. table)
	-- end

	-- if tableFields[table] == nil then
		-- getTableFields(table)
	-- end

	-- sqlString = "UPDATE " .. table .. " SET"

	-- max = table.maxn(fields)
	-- for i=1,max,1 do
		-- fields[i] = string.lower(fields[i])

		-- if tableFields[table].fields[i].type == "var" then
			-- values[i] = "'" .. escape(values[i]) .. "'"
		-- end

		-- if tableFields[fields[i]].type == "tin" then
			-- if values[i] == true then values[i] = 1 end
			-- if values[i] == false then values[i] = 0 end
		-- end

		-- if 	sqlString == "UPDATE " .. table .. " SET" then
			-- sqlString = sqlString .. " " .. fields[i] .. "=" .. values[i]
		-- else
			-- sqlString = sqlString .. ", " .. fields[i] .. "=" .. values[i]
		-- end
	-- end

	-- if condition ~= nil then
		-- sqlString = sqlString .. " where " .. condition
	-- end

	-- if debugdb then
		-- dbug("save " .. table .. " " .. sqlString)
	-- end

	-- status, errorString = conn:execute(sqlString)

	-- if status == 0 then
		-- if debugdb then
			-- dbug("save " .. table .. " failed")
		-- end

		-- getTableFields(table)
		-- return false -- update failed
	-- else
		-- if debugdb then
			-- dbug("save " .. table .. " success")
		-- end

		-- return true -- update success
	-- end
end
