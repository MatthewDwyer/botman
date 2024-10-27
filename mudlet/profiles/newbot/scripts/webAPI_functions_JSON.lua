--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

-- JASON!

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
local debug = false -- should be false unless testing
--if debug then dbug("debug webAPI_functions_JSON line " .. debugger.getinfo(1).currentline) end

-- These 4 functions are used when the bot is using the API for everything and not reading telnet at all

function getAPILogUpdates_JSON(data)
	local httpHeaders = {["X-SDTD-API-TOKENNAME"] = server.allocsWebAPIUser, ["X-SDTD-API-SECRET"] = server.allocsWebAPIPassword}

	url = "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/getwebuiupdates"
	postHTTP("", url, httpHeaders)
	-- the response from the server is processed in function onHttpPostDone(_, url, body) in functions.lua
end


function getAPILog_JSON()
	local httpHeaders = {["X-SDTD-API-TOKENNAME"] = server.allocsWebAPIUser, ["X-SDTD-API-SECRET"] = server.allocsWebAPIPassword}

	url = "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/getlog?firstline=" .. botman.lastLogLine
	postHTTP("", url, httpHeaders)
	-- the response from the server is processed in function onHttpPostDone(_, url, body) in functions.lua
end


function readAPI_webUIUpdates_JSON(data)
	if botman.botOffline or botman.APIOffline then
		irc_chat(server.ircMain, "The bot has connected to the server API.")
	end

	toggleTriggers("api online")

	botman.APIOffline = false
	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()
	botman.newlogs = tonumber(data.newlogs)

	if not botman.lastLogLine then
		botman.lastLogLine = data.newlogs
	end

	if tonumber(botman.lastLogLine) < botman.newlogs then
		getAPILog_JSON()
	end

	botman.lastLogLine = botman.newlogs + 1

	if tonumber(data.players) >= 0 then
		botman.playersOnline = tonumber(data.players)
	else
		botman.playersOnline = 0
	end
end


function readAPI_ReadLog_JSON(data)
	local k, v, handled, line

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	-- Log types
	-- INF = Log
	-- WRN = Warning
	-- ERR = Error

	for k,v in pairs(data.entries) do
		-- we only want to process log (INF) lines
		if v.type == "Log" then
			handled = false

			-- reconstruct the log line as it would look in telnet so the bot's code correctly parses it everywhere.
			line = v.date .. "T" .. v.time .. " " .. v.uptime .. " INF " .. v.msg

			-- do some wibbly-wobbly timey-wimey stuff
			botman.serverTime = v.date .. " " .. v.time
			botman.serverTimeStamp = dateToTimestamp(botman.serverTime)

			if not botman.serverTimeSync then
				botman.serverTimeSync = 0
			end

			if botman.serverTimeSync == 0 then
				botman.serverTimeSync = -(os.time() - botman.serverTimeStamp)
			end

			botman.serverHour = string.sub(v.time, 1, 2)
			botman.serverMinute = string.sub(v.time, 4, 5)
			specialDay = ""

			if (string.find(botman.serverTime, "02-14", 5, 10)) then specialDay = "valentine" end
			if (string.find(botman.serverTime, "12-25", 5, 10)) then specialDay = "christmas" end

			if server.dateTest == nil then
				server.dateTest = v.date
			end

			if not handled then
				-- stuff to ignore
				if string.find(v.msg, "WebCommandResult") then
					handled = true
				end

				if string.find(v.msg, "SleeperVolume") then
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "Chat:", nil, true) or string.find(v.msg, "Chat (from", nil, true) then
					gmsg(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "to 'Global'", nil, true) then
					gmsg(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "Executing command 'pm ", nil, true) or string.find(v.msg, "Denying command 'pm", nil, true) then
					gmsg(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "Chat handled", nil, true) then
					gmsg(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "denied: Too many players on the server!", nil, true) then
					playerDenied(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "Player connected") then
					playerConnected(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "Player disconnected") then
					playerDisconnected(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "Telnet executed 'tele ", nil, true) or string.find(v.msg, "Executing command 'tele ", nil, true) then
					teleTrigger(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "Heap:", nil, true) then
					memTrigger(line)
					handled = true
				end
			end

			if not handled then
				if string.sub(v.msg, 1, 4) == "Day " then
					gameTimeTrigger(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "Player with ID") then
					overstackTrigger(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "banned until") then
					collectBan(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "Executing command 'ban remove", nil, true) then
					unbanPlayer(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "eliminated") or string.find(v.msg, "killed by") then
					pvpPolice(line)
					handled = true
				end
			end

			if not handled then
				if string.find(v.msg, "FriendsOf") then
					getFriends(line)
					handled = true
				end
			end
			if not handled then
				if server.enableAirdropAlert then
					if string.find(v.msg, "AIAirDrop: Spawned supply crate") then
						airDropAlert(line)
						handled = true
					end
				end
			end

			-- if nothing else processed the log line send it to matchAll
			if not handled then
				matchAll(line)
			end
		end
	end

end

-- End of API log handling functions


function getBMFriends_JSON(steam, data) -- tested
	local k, v, temp, tmp

	tmp = {}
	tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(steam)

	if tmp.steam ~= "0" then
		-- delete auto-added friends from the MySQL table
		if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = '" .. tmp.steam .. "' AND autoAdded = 1") end
	end

	if data == "" then
		return
	end

	tmp.data = data
	tmp.start, tmp.stop = string.find(tmp.data, "EOS_")
	tmp.friends = {}
	tmp.i = 0

	while tmp.start do
		table.insert(tmp.friends, string.sub(tmp.data, tmp.start, tmp.stop + 32))
		tmp.data = string.sub(tmp.data, tmp.start + 36)
		tmp.start, tmp.stop = string.find(tmp.data, "EOS_")

		tmp.i = tmp.i + 1

		if tmp.i > 200 then
			return true
		end
	end

	for k,v in pairs(tmp.friends) do
		addFriend(tmp.steam, v, true, true)
	end

	tempTimer( 3, [[loadFriends()]] )
end


function readAPI_AdminList_JSON(data) -- done
	local result, temp, level, steam, k, v, con, q, tmp, status, errorString, readAdmin

	temp = splitCRLF(data.result)
	tmp = {}
	readAdmin = false

	staffListSteam = {}

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()
	botman.noAdminsDefined = true

	for k,v in pairs(temp) do
		for con, q in pairs(conQueue) do
			if q.command == "admin list" then
				irc_chat(q.ircUser, v)
			end
		end
	end

	for k,v in pairs(temp) do
		if string.find(v, "Defined Group Permissions", nil, true) then
			conn:execute("DELETE FROM staff WHERE adminLevel > ".. server.maxAdminLevel)
			tempTimer( 5, [[loadStaff()]] )

			for con, q in pairs(conQueue) do
				if q.command == "admin list" then
					conQueue[con] = nil
				end
			end

			if botman.noAdminsDefined and not botStatus.alertNoAdminsDefined then
				botStatus.alertNoAdminsDefined = true
				irc_chat(server.ircMain, "ALERT! The server admin list is empty.")
			end

			return
		end

		if string.find(v, "stored name:", nil, true) then
			botman.noAdminsDefined = false
			readAdmin = true
		end

		if readAdmin then
			tmp = {}
			tmp.temp = string.split(v, ":")
			tmp.accessLevel = tonumber(string.trim(tmp.temp[1]))
			tmp.temp[2] = string.trim(tmp.temp[2])
			tmp.name = string.sub(tmp.temp[3], 2, string.len(tmp.temp[3]) - 1)
			tmp.temp = string.split(tmp.temp[2], " ")
			tmp.temp = string.split(tmp.temp[1], "_")
			tmp.platform = tmp.temp[1]
			tmp.steam = tmp.temp[2]
			tmp.userID = ""
			tmp.steamLU, tmp.steamOwnerLU, tmp.userIDLU, tmp.platformLU = LookupPlayer(tmp.steam)

			if tmp.userIDLU ~= "0" then
				tmp.userID = tmp.userIDLU
			end

			if string.find(tmp.temp[1], "Steam", nil, true) then
				staffListSteam[tmp.steam] = {}
				staffListSteam[tmp.steam].accessLevel = tmp.accessLevel
			end

			if string.find(tmp.temp[1], "EOS", nil, true) then
				tmp.steam = tmp.userID
			end

			if tonumber(tmp.accessLevel) <= tonumber(server.maxAdminLevel) then
				if not staffList[tmp.steam] then
					staffList[tmp.steam] = {}
					staffList[tmp.steam].hidden = false
					staffList[tmp.steam].adminLevel = tmp.accessLevel

					if tmp.userID ~= "0" then
						staffList[tmp.steam].userID = tmp.userID
					end

					if tmp.name ~= "" then
						staffList[tmp.steam].name = tmp.name
					else
						if players[tmp.steamLU] then
							staffList[tmp.steam].name = players[tmp.steamLU].name
						end
					end
				end

				if botman.dbConnected then
					conn:execute("UPDATE players SET newPlayer = 0, silentBob = 0, walkies = 0, exiled = 0, canTeleport = 1, botHelp = 1, accessLevel = " .. tmp.accessLevel .. " WHERE steam = '" .. tmp.steam .. "'")
					status, errorString = conn:execute("INSERT INTO staff (steam, adminLevel, userID, platform, hidden, name) VALUES ('" .. tmp.steam .. "'," .. tmp.accessLevel .. ",'" .. tmp.userID .. "','" .. tmp.platform .. "'," .. dbBool(staffList[tmp.steam].hidden) .. ",'" .. escape(staffList[tmp.steam].name) .. "')")

					if not status then
						if string.find(errorString, "Duplicate entry") then
							conn:execute("UPDATE staff SET adminLevel = " .. tmp.accessLevel .. ", name = '" .. escape(staffList[tmp.steam].name) .. "' WHERE steam = '" .. tmp.steam .. "'")
						end
					end
				end

				if players[tmp.steam] then
					players[tmp.steam].accessLevel = tmp.accessLevel
					players[tmp.steam].newPlayer = false
					players[tmp.steam].silentBob = false
					players[tmp.steam].walkies = false
					players[tmp.steam].timeout = false
					players[tmp.steam].botTimeout = false
					players[tmp.steam].prisoner = false
					players[tmp.steam].exiled = false
					players[tmp.steam].canTeleport = true
					players[tmp.steam].botHelp = true
					players[tmp.steam].hackerScore = 0

					if staffList[tmp.steam].hidden then
						players[tmp.steam].testAsPlayer = true
					else
						players[tmp.steam].testAsPlayer = nil
					end

					if players[tmp.steam].botTimeout and igplayers[tmp.steam] then
						gmsg(server.commandPrefix .. "return " .. tmp.platform ..  "_" .. tmp.steam)
					end
				end
			end
		end
	end
end


function readAPI_BanList_JSON(data) -- done
	local result, k, v, con, q, tmp

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		tmp = {}

		if v ~= "" then
			matchAll(v) -- send the line to matchAll for processing
		end

		for con, q in pairs(conQueue) do
			if q.command == "ban list" then
				irc_chat(q.ircUser, result[k])
			end
		end
	end

	collectBans = false
	loadBans()

	for con, q in pairs(conQueue) do
		if q.command == "ban list" then
			conQueue[con] = nil
		end
	end
end


function readAPI_BMAnticheatReport_JSON(data) -- done todo test
	local result, tmp, temp, k, v

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		if v ~= "" and v ~= "End Report" then
			if string.find(v, "--NAME") and (not string.find(line, "unauthorized locked container")) then
				tmp = {}
				tmp.name = string.sub(v, string.find(v, "-NAME:") + 6, string.find(v, "--ID:") - 2)
				tmp.id = string.sub(v, string.find(v, "-ID:") + 4, string.find(v, "--LVL:") - 2)
				tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(tmp.id)
				tmp.reason = "hacking"
				tmp.hack = ""
				tmp.level = string.sub(v, string.find(v, "-LVL:") + 5)
				tmp.level = string.match(tmp.level, "(-?%d+)")
				tmp.alert = string.sub(v, string.find(v, "-LVL:") + 5)
				tmp.alert = string.sub(tmp.alert, string.find(tmp.alert, " ") + 1)

				if (not isStaff(tmp.steam, tmp.userID)) and (not players[tmp.steam].testAsPlayer) and (not bans[tmp.steam]) and (not anticheatBans[tmp.steam]) then
					if string.find(v, " spawned ") then
						temp = string.split(tmp.alert, " ")
						tmp.entity = stripQuotes(temp[3])
						tmp.x = string.match(temp[4], "(-?\%d+)")
						tmp.y = string.match(temp[5], "(-?\%d+)")
						tmp.z = string.match(temp[6], "(-?\%d+)")
						tmp.hack = "spawned " .. tmp.entity .. " at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z

						if tonumber(tmp.level) > 2 then
							irc_chat(server.ircMain, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
							irc_chat(server.ircAlerts, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
						end
					else
						tmp.x = players[tmp.steam].xPos
						tmp.y = players[tmp.steam].yPos
						tmp.z = players[tmp.steam].zPos
						tmp.hack = "using dm at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z

						if tonumber(tmp.level) > 2 then
							irc_chat(server.ircMain, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
							irc_chat(server.ircAlerts, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
						end
					end

					if tonumber(tmp.level) > 2 then
						anticheatBans[tmp.steam] = {}
						banPlayer(tmp.platform, tmp.userID, tmp.steam, "10 years", tmp.reason, "")
						logHacker(botman.serverTime, "Botman anticheat detected " .. tmp.userID .. " " .. tmp.name .. " " .. tmp.hack)
						message("say [" .. server.chatColour .. "]Banning player " .. tmp.name .. " 10 years for using hacks.[-]")
						irc_chat("#hackers", "[BANNED] Player " .. tmp.userID .. " " .. tmp.name .. " has been banned for hacking by anticheat.")
						irc_chat("#hackers", v)
					end
				end
			end
		end
	end
end


function readAPI_BMUptime_JSON(data) -- done tested
	local temp, tmp, k, v, result

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		if v ~= "" then
			temp = string.split(v, ":")

			-- hours
			tmp  = tonumber(string.match(temp[1], "(%d+)"))
			server.uptime = tmp * 60 * 60

			-- minutes
			tmp  = tonumber(string.match(temp[2], "(%d+)"))
			server.uptime = server.uptime + (tmp * 60)

			-- seconds
			tmp  = tonumber(string.match(temp[3], "(%d+)"))
			server.uptime = server.uptime + tmp
			server.serverStartTimestamp = os.time() - server.uptime
		end
	end
end


function readAPI_BMListPlayerBed_JSON(data) -- done tested
	local result, temp, tmp, k, v

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		if v ~= "" then
			if not string.find(v, "The player") then
				temp = string.split(v, ": ")
				tmp = {}
				tmp.pname = temp[1]

				temp = string.split(v, ", ")
				tmp.i = tablelength(temp)

				tmp.x = temp[tmp.i - 2]
				tmp.x = string.split(tmp.x, " ")
				tmp.x = tmp.x[tablelength(tmp.x)]

				tmp.y = temp[tmp.i - 1]
				tmp.z = temp[tmp.i]

				tmp.pid = LookupPlayer(tmp.pname, "all")
				players[tmp.pid].bedX = tmp.x
				players[tmp.pid].bedY = tmp.y
				players[tmp.pid].bedZ = tmp.z

				if botman.dbConnected then conn:execute("UPDATE players SET bedX = " .. tmp.x .. ", bedY = " .. tmp.y .. ", bedZ = " .. tmp.z .. " WHERE steam = '" .. tmp.pid .. "'") end
			else
				tmp = {}
				tmp.pid = string.sub(v, 11, string.find(v, " does ") - 1)
				players[tmp.pid].bedX = 0
				players[tmp.pid].bedY = 0
				players[tmp.pid].bedZ = 0
				if botman.dbConnected then conn:execute("UPDATE players SET bedX = 0, bedY = 0, bedZ = 0 WHERE steam = '" .. tmp.pid .. "'") end
			end
		end
	end
end


function readAPI_BMListPlayerFriends_JSON(data) -- done tested
	local result, temp, k, v, con, q, tmp

	tmp = {}

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		for con, q in pairs(conQueue) do
			if string.find(q.command, "bm-listplayerfriends") then
				irc_chat(q.ircUser, result[k])
			end
		end

		if string.find(v, "Friends of ") then
			tmp.split = string.split(v, "Friends=")
			tmp.friends = tmp.split[2]
			tmp.player = string.sub(v, string.find(v, "id=") + 7, string.find(v, "/") - 1)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.player)
		end

		getBMFriends_JSON(tmp.steam, tmp.friends)
	end

	for con, q in pairs(conQueue) do
		if (q.command == result.command) or (q.command == data.command .. " " .. data.parameters) then
			conQueue[con] = nil
		end
	end
end


function readAPI_BMReadConfig_JSON(data) -- done tested
	local k, v, con, q, result

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	botman.config = {}

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		for con, q in pairs(conQueue) do
			if q.command == "bm-readconfig" or q.command == "bm-readconfigv2" then
				irc_chat(q.ircUser, v)
			end
		end

		table.insert(botman.config, v)
	end

	processBotmanConfig()

	for con,q in pairs(conQueue) do
		if q.command == "bm-readconfig" or q.command == "bm-readconfigv2" then
			conQueue[con] = nil
		end
	end
end


function readAPI_BMResetRegionsList_JSON(data) -- done tested
	local result, temp, x, z, k, v

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	for k,v in pairs(resetRegions) do
		v.inConfig = false
	end

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		for con, q in pairs(conQueue) do
			if q.command == "bm-resetregions list" then
				irc_chat(q.ircUser, v)
			end
		end

		if string.find(v, "r.", nil, true) then
			temp = string.split(v, "%.")
			x = temp[2]
			z = temp[3]

			if not resetRegions[v .. ".7rg"] then
				resetRegions[v .. ".7rg"] = {}
			end

			resetRegions[v .. ".7rg"].x = x
			resetRegions[v .. ".7rg"].z = z
			resetRegions[v .. ".7rg"].inConfig = true
			conn:execute("INSERT INTO resetZones (region, x, z) VALUES ('" .. escape(v .. ".7rg") .. "'," .. x .. "," .. z .. ")")
		end
	end

	for con, q in pairs(conQueue) do
		if q.command == "bm-resetregions list" then
			conQueue[con] = nil
		end
	end

	-- for k,v in pairs(resetRegions) do
		-- if not v.inConfig then
			-- sendCommand("bm-resetregions add " .. v.x .. "." .. v.z)
		-- end
	-- end

	tempTimer(3, [[loadResetZones(true)]])
end


function readAPI_Command_JSON(data) -- done
	-- this is a catch-all for commands that don't need a dedicated function to process their output
	local result, temp, k, v, con, q

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)

	for con, q in pairs(conQueue) do
		if (q.command == data.command) or (q.command == data.command .. " " .. data.parameters) then
			for k,v in pairs(result) do
				irc_chat(q.ircUser, result[k])
			end
		end
	end

	for con, q in pairs(conQueue) do
		if (q.command == data.command) or (q.command == data.command .. " " .. data.parameters) then
			conQueue[con] = nil
		end

	end

	if string.sub(data.result, 1, 4) == "Day " then
		gameTimeTrigger(result)
		return
	end

	if string.sub(result.command, 1, 3) == "sg " then
		matchAll(result) -- send the line to matchAll for processing
		return
	end

	if data.parameters == "bot_RemoveInvalidItems" then
		removeInvalidItems()
		return
	end
end


function readAPI_GetServerInfo_JSON(data)  -- not finished.  May not need as gg already works fine.
	local result, k, v, con, q
end


function readAPI_GG_JSON(data) -- done tested
	local result, k, v, con, q

	GamePrefs = {}

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)
	botman.readGG = true

	for k,v in pairs(result) do
		for con, q in pairs(conQueue) do
			if q.command == "gg" then
				irc_chat(q.ircUser, result[k])
			end
		end

		if v ~= "" then
			matchAll(v) -- send the line to matchAll for processing
		end
	end

	botman.readGG = false

	for con, q in pairs(conQueue) do
		if q.command == "gg" then
			conQueue[con] = nil
		end
	end

	if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('GamePrefs','panel','" .. escape(yajl.to_string(GamePrefs)) .. "')") end

	if tonumber(server.reservedSlots) > 0 then
		initSlots()
	end
end


function readAPI_GT_JSON(data) -- done tested
	local result, k, v, con, q

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)

	for con, q in pairs(conQueue) do
		if q.command == "gt" then
			irc_chat(q.ircUser, result[1])
		end
	end

	if result[1] ~= "" then
		gameTimeTrigger(result[1])
	end

	for con, q in pairs(conQueue) do
		if q.command == "gt" then
			conQueue[con] = nil
		end
	end
end


function readAPI_Help_JSON(data) -- done tested
	local k, v, con, q, result

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		for con, q in pairs(conQueue) do
			if string.find(q.command, "help") then
				irc_chat(q.ircUser, v)
			end
		end
	end

	for k,v in pairs(conQueue) do
		if string.find(v.command, "help") then
			conQueue[k] = nil
		end
	end
end


function readAPI_Inventories_JSON(data) -- done tested
	local result, k, v, a, b, slot, tmp

	if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

	tmp = {}

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	-- loop through each online player's inventory
	for k,v in pairs(data) do
		-- grab some details but we only need the userid
		tmp.playerName = v.playername
		tmp.crossplatformid = v.crossplatformid
		tmp.entityid = v.entityid

		tmp.steam = v.userid
		tmp.steam = stripMatching(tmp.steam, "Steam_")
		tmp.steam = stripMatching(tmp.steam, "XBL_")

		-- save the last recorded inventory to inventoryLast so we can tell when there has been a change
		if (igplayers[tmp.steam].inventoryLast ~= igplayers[tmp.steam].inventory) then
			igplayers[tmp.steam].inventoryLast = igplayers[tmp.steam].inventory
		end

		-- same for belt, pack and equipment though we only need to monitor inventory to detect any changes
		igplayers[tmp.steam].inventory = ""
		igplayers[tmp.steam].oldBelt = igplayers[tmp.steam].belt
		igplayers[tmp.steam].belt = ""
		igplayers[tmp.steam].oldPack = igplayers[tmp.steam].pack
		igplayers[tmp.steam].pack = ""
		igplayers[tmp.steam].oldEquipment = igplayers[tmp.steam].equipment
		igplayers[tmp.steam].equipment = ""

		-- record the player's bag
		slot = 0
		for a,b in pairs(v.bag) do
			if type(b) ~= "userdata" then
				igplayers[tmp.steam].inventory = igplayers[tmp.steam].inventory .. b.count .. "," .. b.name .. "," .. b.quality .. "|"
				igplayers[tmp.steam].pack = igplayers[tmp.steam].pack .. slot .. "," .. b.count .. "," .. b.name .. "," .. b.quality .. "|"
			end

			slot = slot + 1
		end

		-- and their belt
		slot = 0
		for a,b in pairs(v.belt) do
			if type(b) ~= "userdata" then
				igplayers[tmp.steam].inventory = igplayers[tmp.steam].inventory .. b.count .. "," .. b.name .. "," .. b.quality .. "|"
				igplayers[tmp.steam].belt = igplayers[tmp.steam].belt .. slot .. "," .. b.count .. "," .. b.name .. "," .. b.quality .. "|"
			end

			slot = slot + 1
		end

		-- and equipment
		for a,b in pairs(v.equipment) do
			if type(b) ~= "userdata" then
				slot = a
				igplayers[tmp.steam].inventory = igplayers[tmp.steam].inventory .. "1," .. b.name .. "," .. b.quality .. "|"
     			igplayers[tmp.steam].equipment = igplayers[tmp.steam].equipment .. slot .. "," .. b.name .. "," .. b.quality .. "|"
			end
		end
	end

	if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

	-- now that we have all the inventories we can check them for bad item etc and save them to the database
	CheckInventory()

	if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end
end


function readAPI_Hostiles_JSON(data) -- done tested
	local loc, k, v

	botman.lastServerResponseTimestamp = os.time()

	for k,v in pairs(data) do
		if v ~= "" then
			if string.find(v.name, "emplate") then
				removeEntityCommand(v.id)
			end

			loc = inLocation(v.position.x, v.position.z)

			if loc ~= false then
				if locations[loc].killZombies then
					removeEntityCommand(v.id)
				end
			end
		end
	end
end


function readAPI_LE_JSON(data) -- done tested
	local result, temp, k, v, entityID, entity, cursor, errorString, con, q, tmp

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	if botman.dbConnected then
		connMEM:execute("DELETE FROM entities")
	end

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		if string.find(v, "id=") then
			listEntities(result[k])
		end
	end

	for con, q in pairs(conQueue) do
		if q.command == data.command then
			for k,v in pairs(result) do
				if result[k] ~= "" then
					irc_chat(q.ircUser, result[k])
				end
			end
		end
	end

	for con, q in pairs(conQueue) do
		if (q.command == data.command) or (q.command == data.command .. " " .. data.parameters) then
			conQueue[con] = nil
		end
	end
end


function readAPI_LKP_JSON(data) -- done tested
	local result, tmp, k, v, con, q

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	tmp = {}
	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		if not string.find(v, "Total of") and v ~= "" then
			tmp.temp = string.sub(v, string.find(v, "steamid=") + 8)
			tmp.temp = string.split(tmp.temp, ",")
			tmp.userID = tmp.temp[1]

			if data.parameters ~= "-online" and botman.archivePlayers then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.userID)

				if tmp.steam ~= "0" then
					players[tmp.steam].notInLKP = false
				end
			end
		end

		for con, q in pairs(conQueue) do
			if q.command == "lkp" then
				irc_chat(q.ircUser, result[k])
			end
		end
	end

	if data.parameters ~= "-online" and botman.archivePlayers then
		botman.archivePlayers = nil

		--	Everyone who is flagged notInLKP gets archived.
		for k,v in pairs(players) do
			if v.notInLKP then
				if botman.dbConnected then connSQL:execute("INSERT INTO miscQueue (steam, command) VALUES ('" .. k .. "', 'archive player')") end
				botman.miscQueueEmpty = false
			end
		end
	end

	for con, q in pairs(conQueue) do
		if q.command == "lkp" then
			conQueue[con] = nil
		end
	end
end


function readAPI_LI_JSON(data) -- done tested
	local result, temp, k, v, entityID, entity, cursor, errorString, con, q, exportFile, test

	initSpawnableItems()

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	if botman.exportItemsList then
		exportFile = io.open(botman.chatlogPath .. "/lists/items.txt", "w")
	else
		if data.parameters == "*" then
			botman.validateItems = true
		end
	end

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		if not string.find(v, " matching items.") then
			if botman.exportItemsList then
				exportFile:write(v .. "\n")
			else
				temp = string.trim(v)

				if temp ~= "" then
					test = temp:sub(1, 1)

					if tonumber(test) ~= nil then
						spawnableItems_numeric[temp] = {}
					end

					if test == "a" then
						spawnableItems_a[temp] = {}
					end

					if test == "b" then
						spawnableItems_b[temp] = {}
					end

					if test == "c" then
						spawnableItems_c[temp] = {}
					end

					if test == "d" then
						spawnableItems_d[temp] = {}
					end

					if test == "e" then
						spawnableItems_e[temp] = {}
					end

					if test == "f" then
						spawnableItems_f[temp] = {}
					end

					if test == "g" then
						spawnableItems_g[temp] = {}
					end

					if test == "h" then
						spawnableItems_h[temp] = {}
					end

					if test == "i" then
						spawnableItems_i[temp] = {}
					end

					if test == "j" then
						spawnableItems_j[temp] = {}
					end

					if test == "k" then
						spawnableItems_k[temp] = {}
					end

					if test == "l" then
						spawnableItems_l[temp] = {}
					end

					if test == "m" then
						spawnableItems_m[temp] = {}
					end

					if test == "n" then
						spawnableItems_n[temp] = {}
					end

					if test == "o" then
						spawnableItems_o[temp] = {}
					end

					if test == "p" then
						spawnableItems_p[temp] = {}
					end

					if test == "q" then
						spawnableItems_q[temp] = {}
					end

					if test == "r" then
						spawnableItems_r[temp] = {}
					end

					if test == "s" then
						spawnableItems_s[temp] = {}
					end

					if test == "t" then
						spawnableItems_t[temp] = {}
					end

					if test == "u" then
						spawnableItems_u[temp] = {}
					end

					if test == "v" then
						spawnableItems_v[temp] = {}
					end

					if test == "w" then
						spawnableItems_w[temp] = {}
					end

					if test == "x" then
						spawnableItems_x[temp] = {}
					end

					if test == "y" then
						spawnableItems_y[temp] = {}
					end

					-- and

					if test == "z" then
						spawnableItems_z[temp] = {}
					end

					-- now I know my ABC.. holy crap that was a lot of items!
				end
			end
		end
	end

	if not botman.exportItemsList then
		for con, q in pairs(conQueue) do
			if string.sub(q.command, 1, 3) == "li " then
				for k,v in pairs(result) do
					temp = string.trim(v)
					irc_chat(q.ircUser, temp)
				end
			end
		end
	end

	for con, q in pairs(conQueue) do
		if (q.command == data.command) or (q.command == data.command .. " " .. data.parameters) then
			conQueue[con] = nil
		end
	end

	if botman.validateItems and not botman.exportItemsList then
		if botman.dbConnected then
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_numeric')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_a')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_b')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_c')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_d')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_e')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_f')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_g')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_h')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_i')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_j')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_k')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_l')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_m')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_n')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_o')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_p')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_q')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_r')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_s')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_t')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_u')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_v')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_w')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_x')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_y')")
			connSQL:execute("INSERT into spawnableItemsQueue (tableName) VALUES ('spawnableItems_z')")
		end

		botman.spawnableItemsQueueEmpty = false
		botman.validateItems = nil
		-- the magic happens in the function called spawnableItemsQueue in queues.lua
	end

	if botman.exportItemsList then
		botman.exportItemsList = nil
		exportFile:close()
		initSpawnableItems()
	end
end


function readAPI_LLP_JSON(data) -- partially done until we are able to remove claims again
	local result, coords, k, v, a, b, cursor, errorString, con, q, tmp
	local x, y, z, keystoneCount, region, loc, reset, expired, noPlayer, archived
	local k, v

	tmp = {}

	connSQL:execute("DELETE FROM keystones WHERE x = 0 AND y = 0 AND z = 0")

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)

	for k, v in pairs(result) do
		--display(v)


		for con, q in pairs(conQueue) do
			if string.find(q.command, data.command) then
				irc_chat(q.ircUser, result[k])
			end
		end

		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- if v ~= "" then
				-- tmp.temp = splitCRLF(v)

				-- for a,b in pairs(tmp.temp) do
					-- if string.find(b, "Player ") then
						-- tmp.pos = string.find(b, "EOS")
						-- tmp.userID = string.sub(b, tmp.pos, tmp.pos + 35)
						-- tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.userID)

						-- noPlayer = true
						-- archived = false

						-- if string.find(b, "protected: True", nil, true) then
							-- expired = false
						-- end

						-- if string.find(b, "protected: False", nil, true) then
							-- expired = true
						-- end

						-- if players[tmp.steam] then
							-- noPlayer = false

							-- if players[tmp.steam].removedClaims == nil then
								-- players[tmp.steam].removedClaims = 0
							-- end
						-- end

						-- if playersArchived[tmp.steam] then
							-- noPlayer = false
							-- archived = true

							-- if playersArchived[tmp.steam].removedClaims == nil then
								-- playersArchived[tmp.steam].removedClaims = 0
							-- end
						-- end
					-- end

					-- if string.find(b, "owns ") and string.find(b, " keystones") then
						-- keystoneCount = string.sub(b, string.find(b, "owns ") + 5, string.find(b, " keystones") - 1)
						-- if not noPlayer then
							-- if not archived then
								-- players[tmp.steam].keystones = keystoneCount
							-- else
								-- playersArchived[tmp.steam].keystones = keystoneCount
							-- end
						-- end
					-- end

					-- if string.find(b, "location") then
						-- b = string.sub(b, string.find(b, "location") + 9)
						-- claimRemoved = false

						-- coords = string.split(b, ",")
						-- x = tonumber(coords[1])
						-- y = tonumber(coords[2])
						-- z = tonumber(coords[3])

						-- if tonumber(y) > 0 then
							-- if botman.dbConnected then
								-- connSQL:execute("UPDATE keystones SET removed = 0 WHERE steam = '" .. tmp.userID .. "' AND x = " .. x .. " AND y = " .. y .. " AND z = " .. z)
							-- end

							-- if not noPlayer then
								-- if not archived then
									-- if players[tmp.steam].removeClaims or (expired and server.removeExpiredClaims) then
										-- keystones[x .. y .. z].remove = true
									-- end
								-- else
									-- if playersArchived[tmp.steam].removeClaims or (expired and server.removeExpiredClaims) then
										-- keystones[x .. y .. z].remove = true
									-- end
								-- end
							-- else
								-- if expired and server.removeExpiredClaims then
									-- keystones[x .. y .. z].remove = true
								-- end
							-- end

							-- if not isAdminHidden(tmp.steam, tmp.userID) then
								-- region = getRegion(x, z)
								-- loc, reset = inLocation(x, z)

								-- if not noPlayer then
									-- if not archived then
										-- if (resetRegions[region] or reset or players[tmp.steam].removeClaims) and not players[tmp.steam].testAsPlayer then
											-- claimRemoved = true
											-- if botman.dbConnected then connSQL:execute("INSERT INTO persistentQueue (steam, command, timerDelay) VALUES ('" .. tmp.steam .. "','" .. connMEM:escape("rlp " .. x .. " " .. y .. " " .. z) .. "','" .. os.time() + 5 .. "')") end
											-- botman.persistentQueueEmpty = false
										-- else
											-- if botman.dbConnected then connSQL:execute("INSERT INTO keystones (steam, x, y, z, expired) VALUES ('" .. tmp.userID .. "'," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ")") end
										-- end
									-- else
										-- if (resetRegions[region] or reset or playersArchived[tmp.steam].removeClaims) and not playersArchived[tmp.steam].testAsPlayer then
											-- claimRemoved = true
											-- if botman.dbConnected then connSQL:execute("INSERT INTO persistentQueue (steam, command, timerDelay) VALUES ('" .. tmp.steam .. "','" .. connMEM:escape("rlp " .. x .. " " .. y .. " " .. z) .. "','" .. os.time() + 5 .. "')") end
											-- botman.persistentQueueEmpty = false
										-- else
											-- if botman.dbConnected then connSQL:execute("INSERT INTO keystones (steam, x, y, z, expired) VALUES ('" .. tmp.userID .. "'," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ")") end
										-- end
									-- end
								-- else
									-- if (resetRegions[region] or reset) and server.removeExpiredClaims then
										-- claimRemoved = true
										-- if botman.dbConnected then connSQL:execute("INSERT INTO persistentQueue (steam, command, timerDelay) VALUES ('" .. tmp.steam .. "','" .. connMEM:escape("rlp " .. x .. " " .. y .. " " .. z) .. "','" .. os.time() + 5 .. "')") end
										-- botman.persistentQueueEmpty = false
									-- else
										-- if botman.dbConnected then connSQL:execute("INSERT INTO keystones (steam, x, y, z, expired) VALUES ('" .. tmp.userID .. "'," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ")") end
									-- end
								-- end
							-- else
								-- if botman.dbConnected then connSQL:execute("INSERT INTO keystones (steam, x, y, z, expired) VALUES ('" .. tmp.userID .. "'," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ")") end
							-- end

							-- if not claimRemoved then
								-- if not keystones[x .. y .. z] then
									-- keystones[x .. y .. z] = {}
									-- keystones[x .. y .. z].x = x
									-- keystones[x .. y .. z].y = y
									-- keystones[x .. y .. z].z = z
									-- keystones[x .. y .. z].steam = tmp.steam
									-- keystones[x .. y .. z].userID = tmp.userID
								-- end

								-- keystones[x .. y .. z].removed = 0
								-- keystones[x .. y .. z].remove = false

								-- if archived then
									-- keystones[x .. y .. z].expired = playersArchived[tmp.steam].claimsExpired
								-- else
									-- if not noPlayer then
										-- keystones[x .. y .. z].expired = players[tmp.steam].claimsExpired
									-- else
										-- keystones[x .. y .. z].expired = true
									-- end
								-- end
							-- end
						-- end
					-- end
				-- end
			-- end
		-- end
	end

	for con, q in pairs(conQueue) do
		if (q.command == data.command) or (q.command == data.command .. " " .. data.parameters) then
			conQueue[con] = nil
		end
	end
end


function readAPI_LP_JSON(data) -- done
	local result, con, q
	local k, v, a, b, tmp

	tmp = {}

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		tmp.split = string.split(v, ", ")

		for a,b in pairs(tmp.split) do
			if string.find(b, "pltfmid=") then
				tmp.temp = string.split(b, "_")
				tmp.steam = tmp.temp[2]
			end

			if string.find(b, "crossid=") then
				tmp.temp = string.split(b, "=")
				tmp.userID = tmp.temp[2]
			end
		end

		if not joiningPlayers[tmp.steam] then
			joiningPlayers[tmp.steam] = {}
			joiningPlayers[tmp.steam].steam = tmp.steam
			joiningPlayers[tmp.steam].userID = tmp.userID

			connSQL:execute("INSERT INTO joiningPlayers (steam, userID, timestamp) VALUES ('" .. tmp.steam .. "','" .. tmp.userID .. "'," .. os.time() .. ")")
		else
			joiningPlayers[tmp.steam].steam = tmp.steam
			joiningPlayers[tmp.steam].userID = tmp.userID
		end

		if not players[tmp.steam].userID then
			players[tmp.steam].userID = tmp.userID
		else
			if players[tmp.steam].userID == "" then
				players[tmp.steam].userID = tmp.userID
			end
		end

		if igplayers[tmp.steam] then
			if not igplayers[tmp.steam].userID then
				igplayers[tmp.steam].userID = tmp.userID
			else
				if igplayers[tmp.steam].userID == "" then
					igplayers[tmp.steam].userID = tmp.userID
				end
			end
		end
	end

	for con, q in pairs(conQueue) do
		if q.command == "lp" then
			conQueue[con] = nil
		end
	end
end


function readAPI_PlayersOnline_JSON(data) -- done tested
	local index, totalPlayersOnline, con, q, result
	local k, v, lpdata, success, statusMessage

	botman.playersOnline = tablelength(data)

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	playersOnlineList = {}
	botStatus.players = {}

	if botman.trackingTicker == nil then
		botman.trackingTicker = 0
	end

	botman.trackingTicker = botman.trackingTicker + 1

	for k,v in pairs(data) do
		lpdata = {}

		temp = string.split(v.steamid, "_")
		lpdata.platform = temp[1]
		lpdata.steam = temp[2]
		lpdata.steam = tostring(lpdata.steam)

		if lpdata.platform ~= "Steam" then
			lpdata.steamOwner = lpdata.steam
		end

		lpdata.entityid = v.entityid
		lpdata.score = v.score
		lpdata.zombiekills = v.zombiekills
		lpdata.level = math.floor(v.level)
		lpdata.playerdeaths = v.playerdeaths
		lpdata.ping = v.ping
		lpdata.ip = v.ip
		lpdata.name = v.name
		lpdata.playerkills = v.playerkills
		lpdata.x = v.position.x
		lpdata.y = v.position.y
		lpdata.z = v.position.z
		lpdata.rawPosition = lpdata.x .. lpdata.y .. lpdata.z
		lpdata.userID = v.crossplatformid
		lpdata.ip = v.ip

		botStatus.players[lpdata.steam] = {}
		botStatus.players[lpdata.steam].steam = lpdata.steam
		botStatus.players[lpdata.steam].entityid = lpdata.entityid
		botStatus.players[lpdata.steam].userID = lpdata.userID
		botStatus.players[lpdata.steam].ip = lpdata.ip
		botStatus.players[lpdata.steam].name = lpdata.name
		botStatus.players[lpdata.steam].playerInfoRanOK = false

		if not igplayers[lpdata.steam] then
			fixMissingIGPlayer(lpdata.platform, lpdata.steam, lpdata.steam)
		end

		if lpdata.userID then
			if lpdata.userID == "" then
				lpdata.userID = LookupJoiningPlayer(lpdata.steam)
			end
		else
			lpdata.userID = LookupJoiningPlayer(lpdata.steam)
		end

		playersOnlineList[lpdata.steam] = {}
		playersOnlineList[lpdata.steam].faulty = false
		playersOnlineList[lpdata.steam].name = lpdata.name
		playersOnlineList[lpdata.steam].id = lpdata.entityid
		playersOnlineList[lpdata.steam].userID = lpdata.userID

		success, statusMessage = pcall(playerInfo, lpdata)
		botStatus.players[lpdata.steam].statusMessage = statusMessage

		if not success then
			windowMessage(server.windowDebug, "!! Fault detected in playerinfo\n")
			windowMessage(server.windowDebug, "Last debug line " .. playersOnlineList[lpdata.steam].debugLine .. "\n")
			windowMessage(server.windowDebug, "Faulty player " .. lpdata.platform .. "_" .. lpdata.steam .. " " .. lpdata.name ..  "\n")
			windowMessage(server.windowDebug, ln .. "\n")
			windowMessage(server.windowDebug, "----------\n")

			playersOnlineList[lpdata.steam].faulty = true
			fixMissingPlayer(lpdata.platform, lpdata.steam, lpdata.steam, lpdata.userID)
			fixMissingIGPlayer(lpdata.platform, lpdata.steam, lpdata.steam, lpdata.userID)
		else
			botStatus.players[lpdata.steam].playerInfoRanOK = true
		end
	end

	if tonumber(botman.trackingTicker) > 2 then
		botman.trackingTicker = 0
	end

	for con, q in pairs(conQueue) do
		if q.command == "lp" then
			conQueue[con] = nil
		end
	end

	for k,v in pairs(igplayers) do
		if not playersOnlineList[k] then
			v.killTimer = 2
		end
	end

	if tonumber(server.reservedSlots) > 0 then
		if botman.initReservedSlots then
			initSlots()
			botman.initReservedSlots = false
		end
	end
end


function readAPI_PGD_JSON(data) -- done tested
	local result, k, v

	botman.lastServerResponseTimestamp = os.time()
	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		if v ~= "" then
			matchAll(v) -- send the line to matchAll for processing
		end
	end
end


function readAPI_PUG_JSON(data) -- done tested
	local result, k, v

	botman.lastServerResponseTimestamp = os.time()
	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		if v ~= "" then
			matchAll(v) -- send the line to matchAll for processing
		end
	end
end


-- function writeAPILog_JSON(line)
	-- -- log the chat
	-- file = io.open(homedir .. "/telnet_logs/" .. os.date("%Y_%m_%d") .. "_API_log.txt", "a")
	-- file:write(botman.serverTime .. "; " .. string.trim(line) .. "\n")
	-- file:close()
-- end


function readAPI_SE_JSON(data) -- done tested
	local result, temp, k, v, con, q, getData, cursor, status, errorString

	botman.lastServerResponseTimestamp = os.time()
	getData = false
	result = splitCRLF(data.result)

	if botman.exportEntitiesList then
		exportFile = io.open(botman.chatlogPath .. "/lists/entities.txt", "w")
	end

	for k,v in pairs(result) do
		if not botman.exportEntitiesList then
			for con, q in pairs(conQueue) do
				if q.command == "se" then
					irc_chat(q.ircUser, result[k])
				end
			end

			if (string.find(v, "entity numbers:")) then
				-- flag all the zombies for removal so we can detect deleted zeds
				if botman.dbConnected then
					conn:execute("UPDATE gimmeZombies SET remove = 1")
					conn:execute("UPDATE otherEntities SET remove = 1")
				end

				getData = true
			else
				if getData then
					if v ~= "" then
						temp = string.split(v, "%-")
						temp.entityID = string.trim(temp[1])
						temp.entityID = tonumber(temp.entityID)
						temp.entity = string.trim(temp[2])

						if string.find(temp.entity, "emplate") or string.find(temp.entity, "Test") or string.find(temp.entity, "playerNewMale") then
							-- skip it
						else
							if string.find(v, "ombie") then
								if botman.dbConnected then
									status, errorString = conn:execute("INSERT INTO gimmeZombies (zombie, entityID) VALUES ('" .. temp.entity .. "'," .. temp.entityID .. ")")

									if not status then
										if string.find(errorString, "Duplicate entry") then
											conn:execute("UPDATE gimmeZombies SET remove = 0 WHERE entityID = " .. temp.entityID)
										end
									end
								end

								updateGimmeZombies(temp.entityID, temp.entity)
							else
								if botman.dbConnected then
									status, errorString = conn:execute("INSERT INTO otherEntities (entity, entityID) VALUES ('" .. temp.entity .. "','" .. escape(temp.entityID) .. "')")

									if not status then
										if string.find(errorString, "Duplicate entry") then
											conn:execute("UPDATE otherEntities SET remove = 0 WHERE entityID = '" .. escape(temp.entityID) .. "'")
										end
									end
								end

								updateOtherEntities(temp.entityID, temp.entity)
							end
						end
					end
				end
			end
		else
			if (string.find(v, "entity numbers:")) then
				getData = true
			else
				if getData and v ~= "" then
					exportFile:write(v .. "\n")
				end
			end
		end
	end

	if not botman.exportEntitiesList then
		if botman.dbConnected then conn:execute("DELETE FROM gimmeZombies WHERE remove = 1 OR zombie LIKE '%Template%'") end
		loadGimmeZombies()

		if botman.dbConnected then conn:execute("DELETE FROM otherEntities WHERE remove = 1 OR entity LIKE '%Template%' OR entity LIKE '%invisible%'") end
		loadOtherEntities()

		if botman.dbConnected then
			cursor,errorString = conn:execute("SELECT MAX(entityID) AS maxZeds FROM gimmeZombies")
			row = cursor:fetch({}, "a")
			botman.maxGimmeZombies = tonumber(row.maxZeds)
		end
	end

	for con, q in pairs(conQueue) do
		if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			conQueue[con] = nil
		end
	end

	if botman.exportEntitiesList then
		botman.exportEntitiesList = nil
		exportFile:close()
	end
end


function readAPI_MEM_JSON(data) -- done
	local result, k, v, con, q

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	result = splitCRLF(data.result)

	for con, q in pairs(conQueue) do
		if q.command == data.command then
			if result ~= "" then
				for k,v in pairs(result) do
					irc_chat(q.ircUser, result[k])
				end
			end
		end
	end

	memTrigger(result[1])

	for con, q in pairs(conQueue) do
		if q.command == data.command then
			conQueue[con] = nil
		end
	end
end


function readAPI_webpermission_JSON(data) -- done tested
	if string.find(data.result, "Usage") then
		-- the api is working so put the bot back into api mode
		server.useAllocsWebAPI = true
		botman.APIOffline = false
		botman.botOffline = false
		botman.botOfflineCount = 0
		botman.APIOfflineCount = 0
		botman.lastServerResponseTimestamp = os.time()

		toggleTriggers("api online")
		conn:execute("UPDATE server set useAllocsWebAPI = 1")
	end
end


function readAPI_Version_JSON(data) -- done tested
	local k, v, con, q, result

	if botman.APIOffline then
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	botman.botOffline = false
	botman.botOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()

	modVersions = {}
	server.allocs = false
	server.botman = false
	server.otherManager = false
	readVersion = true -- used in matchAll function

	result = splitCRLF(data.result)

	for k,v in pairs(result) do
		if v ~= "" then
			matchAll(v) -- send the line to matchAll for processing
		end

		for con, q in pairs(conQueue) do
			if q.command == "version" then
				irc_chat(q.ircUser, result[k])
			end
		end
	end

	for con, q in pairs(conQueue) do
		if q.command == "version" then
			conQueue[con] = nil
		end
	end

	if server.allocs and server.botman then
		botMaintenance.modsInstalled = true
	else
		botMaintenance.modsInstalled = false
	end

	saveBotMaintenance()

	if botman.dbConnected then
		conn:execute("DELETE FROM webInterfaceJSON WHERE ident = 'modVersions'")
		conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('modVersions','panel','" .. escape(yajl.to_string(modVersions)) .. "')")
	end

	table.save(homedir .. "/data_backup/modVersions.lua", modVersions)
end
