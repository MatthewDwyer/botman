--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

local sql

function updateTable(table, key, condition)
	local k, v, value, temp, tbl

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
	local k, v, value, temp

	-- update the db
	sql = {}

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

			 if v.type == "dat" and value ~= nil then
				if string.sub(value, 1, 1) ~= "'" then
					sql[v.field].value = "'" .. value .. "'"
				end
			 end
		end
	end

--debugdb = true
	savePlayer(steam)
debugdb = false
end


function updateArchivedPlayer(steam)
	local k, v, value, temp

	-- update the db
	sql = {}

	for k,v in pairs(playerFields) do
		if playersArchived[steam][v.field] then
			value = playersArchived[steam][v.field]

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

			if v.type == "dat" and value ~= nil then
				if string.sub(value, 1, 1) ~= "'" then
					sql[v.field].value = "'" .. value .. "'"
				end
			 end
		end
	end

--debugdb = true
	saveArchivedPlayer(steam)
debugdb = false
end


function getServerFields()
	local field, cursor, errorString, row

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


function saveServer()
	local sqlString, k, v, field, value

	if debugdb then
		dbug("saving to server table")
	end

	if serverFields == nil then
		getServerFields()
	end

	sqlString = "UPDATE server SET"

	for k,v in pairs(server) do
		field = nil
		value = nil

		if serverFields[k] then
			if serverFields[k].type == "var" then
				value = "'" .. escape(v) .. "'"
			end

			if serverFields[k].type == "tin" then
				if v == true then value = 1 end
				if v == false then value = 0 end
			end

			if serverFields[k].type == "tim" and v ~= nil then
				value = "'" .. os.date("%Y-%m-%d %H:%M:%S", v) .. "'"
			end

			 if serverFields[k].type == "dat" and v ~= nil then
				if string.sub(v, 1, 1) ~= "'" then
					value = "'" .. v .. "'"
				end
			 end

			if value ~= nil then
				field = k
				sqlString = sqlString .. " " .. field .. "=" .. value .. ","
			end
		end
	end

	sqlString = string.sub(sqlString, 1, string.len(sqlString) - 1)

	if debugdb then
		dbug("save server " .. sqlString)
	end


	status, errorString = conn:execute(sqlString)

	--print(status,errorString )

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
	local field, cursor, errorString, row

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


function savePlayer(steam)
	-- DO NOT call this function directly.  Call updatePlayer instead.
	local k, v, i, sqlString, sqlValues, status, errorString, max, cursor


	if debugdb then
		dbug("saving player " .. steam .. " " .. players[steam].name)
	end

	if playerFields == nil then
		getPlayerFields()
	end

	cursor,errorString = conn:execute("SELECT steam FROM players WHERE steam = '" .. steam .. "'")
	rows = cursor:numrows()

	if rows == 0 then
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

				 if v.type == "dat" and sql[k].value ~= nil then
					if string.sub(sql[k].value, 1, 1) ~= "'" then
						sql[k].value = "'" .. sql[k].value .. "'"
					end
				 end

				sqlString = sqlString .. " " .. string.lower(sql[k].field) .. ","
				sqlValues = sqlValues .. sql[k].value .. ","
			end
		end

		sqlString = string.sub(sqlString, 1, string.len(sqlString) - 1) .. ")"
		sqlValues = string.sub(sqlValues, 1, string.len(sqlValues) - 1) .. ")"
		sqlString = sqlString .. sqlValues
	else
		sqlString = "update players set"

		for k,v in pairs(playerFields) do
			if sql[k] and sql[k].value and v.type ~= "tim" then
				if v.type == "var" then
					sql[k].value = "'" .. escape(sql[k].value) .. "'"
				end

				if v.type == "tin" then
					if sql[k].value == true then sql[k].value = 1 end
					if sql[k].value == false then sql[k].value = 0 end
				end

				if v.type == "tim" and sql[k].value ~= nil then
					sql[k].value = "'" .. os.date("%Y-%m-%d %H:%M:%S", sql[k].value) .. "'"
				end

				 if v.type == "dat" and sql[k].value ~= nil then
					if string.sub(sql[k].value, 1, 1) ~= "'" then
						sql[k].value = "'" .. sql[k].value .. "'"
					end
				 end

				sqlString = sqlString .. " " .. string.lower(sql[k].field) .. "=" .. sql[k].value .. ","
			end
		end

		sqlString = string.sub(sqlString, 1, string.len(sqlString) - 1)
		sqlString = sqlString .. " where steam = '" .. steam .. "'"
	end

	if debugdb then
		dbug("save player sqlString " .. sqlString)
	end

	status, errorString = conn:execute(sqlString)

	if status == 0 then
		if debugdb then
			dbug("save player failed")
			dbug(status .. " " .. errorString)
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


function saveArchivedPlayer(steam, action)
	-- DO NOT call this function directly.  Call updatePlayer instead.
	local k, v, i, sqlString, sqlValues, status, errorString, max

	if debugdb then
		dbug("saving archived player " .. steam .. " " .. playersArchived[steam].name)
	end

	if playerFields == nil then
		getPlayerFields()
	end

	if action == nil then
		sqlString = "update playersArchived set"

		for k,v in pairs(playerFields) do
			if sql[k] and sql[k].value and v.type ~= "tim" then
				if v.type == "var" then
					sql[k].value = "'" .. escape(sql[k].value) .. "'"
				end

				if v.type == "tin" then
					if sql[k].value == true then sql[k].value = 1 end
					if sql[k].value == false then sql[k].value = 0 end
				end

				if v.type == "tim" and sql[k].value ~= nil then
					sql[k].value = "'" .. os.date("%Y-%m-%d %H:%M:%S", sql[k].value) .. "'"
				end

				 if v.type == "dat" and sql[k].value ~= nil then
					if string.sub(sql[k].value, 1, 1) ~= "'" then
						sql[k].value = "'" .. sql[k].value .. "'"
					end
				 end

				sqlString = sqlString .. " " .. string.lower(sql[k].field) .. "=" .. sql[k].value .. ","
			end
		end

		sqlString = string.sub(sqlString, 1, string.len(sqlString) - 1)
		sqlString = sqlString .. " where steam = '" .. steam .. "'"
	else
		sqlString = "insert into playersArchived ("
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

				 if v.type == "dat" and sql[k].value ~= nil then
					if string.sub(sql[k].value, 1, 1) ~= "'" then
						sql[k].value = "'" .. sql[k].value .. "'"
					end
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
		dbug("save playerArchived sqlString " .. sqlString)
	end

	status, errorString = conn:execute(sqlString)

	if status == 0 then
		if debugdb then
			dbug("save playerArchived failed")
			dbug(status .. " " .. errorString )
		end

		getPlayerFields()
		return false -- no record changed
	else
		if debugdb then
			dbug("save playerArchived success")
			dbug("save playerArchived sqlString " .. sqlString)
		end

		return true -- record inserted/updated
	end
end


function getTableFields(table)
	local field, tbl, cursor, errorString, row

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

	-- max = tablelength(fields)
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
