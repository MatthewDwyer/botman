--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
--local debug = false -- should be false unless testing
--if debug then dbug("debug webAPI_functions line " .. debugger.getinfo(1).currentline) end


-- function getAPILogUpdates()
	-- if tonumber(server.allocsMap) < 45 then
		-- url = "http://" .. server.IP .. ":" .. server.webPanelPort + 2 .. "/api/getwebuiupdates?adminuser=" .. server.allocsWebAPIUser .. "&admintoken=" .. server.allocsWebAPIPassword
	-- else
		-- url = "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/getwebuiupdates?adminuser=" .. server.allocsWebAPIUser .. "&admintoken=" .. server.allocsWebAPIPassword
	-- end

	-- os.remove(homedir .. "/temp/webUIUpdates.txt")
	-- downloadFile(homedir .. "/temp/webUIUpdates.txt", url)
-- end


-- function getAPILog()
	-- if tonumber(server.allocsMap) < 45 then
		-- url = "http://" .. server.IP .. ":" .. server.webPanelPort + 2 .. "/api/getlog?firstline=" .. botman.lastLogLine .. "&adminuser=" .. server.allocsWebAPIUser .. "&admintoken=" .. server.allocsWebAPIPassword
	-- else
		-- url = "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/getlog?firstline=" .. botman.lastLogLine .. "&adminuser=" .. server.allocsWebAPIUser .. "&admintoken=" .. server.allocsWebAPIPassword
	-- end

	-- os.remove(homedir .. "/temp/log.txt")
	-- downloadFile(homedir .. "/temp/log.txt", url)
-- end


-- function getBMFriends(steam, data)
	-- local k, v, pid

	-- -- delete auto-added friends from the MySQL table
	-- if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = '" .. steam .. "' AND autoAdded = 1") end

	-- if data == "" then
		-- return
	-- end

	-- for k,v in pairs(data) do
		-- pid = string.sub(v, 1, 17)

		-- -- add friends read from bm-listplayerfriends
		-- if not string.find(friends[steam].friends, pid) then
			-- addFriend(steam, pid, true)
		-- end
	-- end
-- end


-- function readAPI_AdminList()
	-- local file, ln, result, data, index, count, temp, level, steam, con, q, fileSize, tmp, status, errorString

	-- fileSize = lfs.attributes (homedir .. "/temp/adminList.txt", "size")
	-- tmp = {}

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/adminList.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)
		-- count = tablelength(data)

		-- for con, q in pairs(conQueue) do
			-- if q.command == "admin list" then
				-- irc_chat(q.ircUser, data[1])
				-- irc_chat(q.ircUser, data[2])
			-- end
		-- end

		-- if data[3] == "" then
			-- botman.noAdminsDefined = true
		-- else
			-- botman.noAdminsDefined = false

			-- for index=3, count-1, 1 do
				-- for con, q in pairs(conQueue) do
					-- if q.command == "admin list" then
						-- irc_chat(q.ircUser, data[index])
					-- end
				-- end

				-- tmp = {}

				-- tmp.temp = string.split(data[index], ":")
				-- tmp.accessLevel = tonumber(string.trim(tmp.temp[1]))
				-- tmp.temp[2] = string.trim(tmp.temp[2])
				-- tmp.name = string.sub(tmp.temp[3], 2, string.len(tmp.temp[3]) - 1)
				-- tmp.platform = ""

				-- if string.find(tmp.temp[2], "EOS", nil, true) then
					-- tmp.userID = string.split(tmp.temp[2], " ")
					-- tmp.userID = tmp.userID[1]
					-- tmp.steamLU, tmp.steamOwnerLU, tmp.userIDLU, tmp.platformLU = LookupPlayer(tmp.userID)

					-- if tmp.steamLU ~= "0" and tmp.steamLU ~= "" then
						-- tmp.steam = tmp.steamLU
						-- tmp.userID = tmp.userIDLU
						-- tmp.platform = tmp.platformLU
					-- end

					-- if not tmp.steam then
						-- tmp.steam = tmp.userID
					-- end
				-- else
					-- tmp.temp = string.split(tmp.temp[2], " ")
					-- tmp.temp = string.split(tmp.temp[1], "_")
					-- tmp.steam = tmp.temp[2]
					-- tmp.steamLU, tmp.steamOwnerLU, tmp.userIDLU, tmp.platformLU = LookupPlayer(tmp.steam)

					-- if tmp.steamLU ~= "0" and tmp.steamLU ~= "" then
						-- tmp.userID = tmp.userIDLU
						-- tmp.platform = tmp.platformLU
					-- end

					-- if not tmp.steam then
						-- tmp.steam = tmp.userID
					-- end
				-- end

				-- if tonumber(tmp.accessLevel) <= tonumber(server.maxAdminLevel) then
					-- if tmp.steam ~= "0" and tmp.steam ~= "" then
						-- -- add the steamid to the staffList table
						-- if tmp.userID ~= "0" and tmp.userID ~= "" then
							-- if not staffList[tmp.userID] then
								-- staffList[tmp.userID] = {}
								-- staffList[tmp.userID].hidden = false
							-- end

							-- staffList[tmp.userID].adminLevel = tmp.accessLevel
							-- staffList[tmp.userID].userID = tmp.userID

							-- if tmp.name then
								-- if tmp.name ~= "" then
									-- staffList[tmp.userID].name = tmp.name
								-- else
									-- if players[tmp.steamLU] then
										-- staffList[tmp.userID].name = players[tmp.steamLU].name
									-- end
								-- end
							-- end

							-- if botman.dbConnected then
								-- conn:execute("UPDATE players SET newPlayer = 0, silentBob = 0, walkies = 0, exiled = 0, canTeleport = 1, botHelp = 1, accessLevel = " .. tmp.accessLevel .. " WHERE steam = '" .. tmp.steam .. "'")

								-- status, errorString = conn:execute("INSERT INTO staff (steam, adminLevel, userID, platform, hidden, name) VALUES ('" .. tmp.userID .. "'," .. tmp.accessLevel .. ",'" .. tmp.userID .. "','" .. tmp.platform .. "'," .. dbBool(staffList[tmp.userID].hidden) .. ",'" .. escape(staffList[tmp.userID].name) .. "')")

								-- if not status then
									-- if string.find(errorString, "Duplicate entry") then
										-- conn:execute("UPDATE staff SET adminLevel = " .. tmp.accessLevel .. ", name = '" .. escape(staffList[tmp.userID].name) .. "' WHERE steam = '" .. tmp.userID .. "'")
									-- end
								-- end
							-- end

							-- if players[tmp.steam] then
								-- players[tmp.steam].accessLevel = tmp.accessLevel
								-- players[tmp.steam].newPlayer = false
								-- players[tmp.steam].silentBob = false
								-- players[tmp.steam].walkies = false
								-- players[tmp.steam].timeout = false
								-- players[tmp.steam].botTimeout = false
								-- players[tmp.steam].prisoner = false
								-- players[tmp.steam].exiled = false
								-- players[tmp.steam].canTeleport = true
								-- players[tmp.steam].botHelp = true
								-- players[tmp.steam].hackerScore = 0

								-- if staffList[tmp.userID].hidden then
									-- players[tmp.steam].testAsPlayer = true
								-- else
									-- players[tmp.steam].testAsPlayer = nil
								-- end

								-- staffList[tmp.userID].name = players[tmp.steam].name

								-- if players[tmp.steam].botTimeout and igplayers[tmp.steam] then
									-- gmsg(server.commandPrefix .. "return " .. tmp.platform ..  "_" .. tmp.steam)
								-- end
							-- end
						-- end
					-- else
						-- if tmp.userID ~= "0" and tmp.userID ~= "" then
							-- -- add the userID to the staffList table
							-- if not staffList[tmp.userID] then
								-- staffList[tmp.userID] = {}
								-- staffList[tmp.userID].hidden = false
							-- end

							-- staffList[tmp.userID].adminLevel = tmp.accessLevel
							-- staffList[tmp.userID].userID = tmp.userID

							-- if tmp.name then
								-- staffList[tmp.userID].name = tmp.name
							-- end

							-- if botman.dbConnected then
								-- status, errorString = conn:execute("INSERT INTO staff (steam, adminLevel, userID, platform, hidden, name) VALUES ('" .. tmp.userID .. "'," .. tmp.accessLevel .. ",'" .. tmp.userID .. "','" .. tmp.platform .. "'," .. dbBool(staffList[tmp.userID].hidden) .. ",'" .. escape(staffList[tmp.userID].name) .. "')")

								-- if not status then
									-- if string.find(errorString, "Duplicate entry") then
										-- conn:execute("UPDATE staff SET adminLevel = " .. tmp.accessLevel .. ", name = '" .. escape(staffList[tmp.userID].name) .. "' WHERE steam = '" .. tmp.userID .. "'")
									-- end
								-- end
							-- end
						-- end
					-- end
				-- end
			-- end
		-- end
	-- end

	-- file:close()

	-- conn:execute("DELETE FROM staff WHERE adminLevel > ".. server.maxAdminLevel)
	-- tempTimer( 5, [[loadStaff()]] )

	-- for con, q in pairs(conQueue) do
		-- if q.command == "admin list" then
			-- conQueue[con] = nil
		-- end
	-- end

	-- os.remove(homedir .. "/temp/adminList.txt")

	-- if botman.noAdminsDefined then
		-- irc_chat(server.ircMain, "ALERT!  There are no admins defined in the admin list!")
	-- end
-- end


-- function readAPI_BanList()
	-- local file, ln, result, data, k, v, temp, con, q, tmp
	-- local bannedTo, steam, reason
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/banList.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/banList.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- tmp = {}

			-- if k > 2 and v ~= "" then
				-- if v ~= "" then
					-- temp = string.split(v, " %- ")
					-- tmp.bannedTo = string.trim(temp[1])
					-- tmp.steam = string.match(temp[2], "(-?\%d+)")
					-- tmp.reason = ""

					-- if temp[3] then
						-- tmp.reason = temp[3]
					-- end

					-- if string.find(temp[2], "Steam_") then
						-- if botman.dbConnected then
							-- conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. tmp.bannedTo .. "','" .. tmp.steam .. "','" .. escape(tmp.reason) .. "',STR_TO_DATE('" .. tmp.bannedTo .. "', '%Y-%m-%d %H:%i:%s'))")
						-- end
					-- end

					-- for con, q in pairs(conQueue) do
						-- if q.command == "ban list" then
							-- irc_chat(q.ircUser, data[k])
						-- end
					-- end
				-- end
			-- else
				-- for con, q in pairs(conQueue) do
					-- if q.command == "ban list" then
						-- irc_chat(q.ircUser, data[k])
					-- end
				-- end
			-- end
		-- end

	-- end

	-- file:close()
	-- loadBans()

	-- for con, q in pairs(conQueue) do
		-- if q.command == "ban list" then
			-- conQueue[con] = nil
		-- end
	-- end

	-- os.remove(homedir .. "/temp/banList.txt")
-- end


-- function readAPI_BMAnticheatReport()
	-- local file, ln, result, data, tmp, temp, k, v
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/bm-anticheat-report.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/bm-anticheat-report.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- if v ~= "" and v ~= "End Report" then
				-- if string.find(v, "--NAME") and (not string.find(line, "unauthorized locked container")) then
					-- tmp = {}
					-- tmp.name = string.sub(v, string.find(v, "-NAME:") + 6, string.find(v, "--ID:") - 2)
					-- tmp.id = string.sub(v, string.find(v, "-ID:") + 4, string.find(v, "--LVL:") - 2)
					-- tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(tmp.id)
					-- tmp.reason = "hacking"
					-- tmp.hack = ""
					-- tmp.level = string.sub(v, string.find(v, "-LVL:") + 5)
					-- tmp.level = string.match(tmp.level, "(-?%d+)")
					-- tmp.alert = string.sub(v, string.find(v, "-LVL:") + 5)
					-- tmp.alert = string.sub(tmp.alert, string.find(tmp.alert, " ") + 1)

					-- if (not isStaff(tmp.steam, tmp.userID)) and (not players[tmp.steam].testAsPlayer) and (not bans[tmp.steam]) and (not anticheatBans[tmp.steam]) then
						-- if string.find(v, " spawned ") then
							-- temp = string.split(tmp.alert, " ")
							-- tmp.entity = stripQuotes(temp[3])
							-- tmp.x = string.match(temp[4], "(-?\%d+)")
							-- tmp.y = string.match(temp[5], "(-?\%d+)")
							-- tmp.z = string.match(temp[6], "(-?\%d+)")
							-- tmp.hack = "spawned " .. tmp.entity .. " at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z

							-- if tonumber(tmp.level) > 2 then
								-- irc_chat(server.ircMain, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
								-- irc_chat(server.ircAlerts, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
							-- end
						-- else
							-- tmp.x = players[tmp.steam].xPos
							-- tmp.y = players[tmp.steam].yPos
							-- tmp.z = players[tmp.steam].zPos
							-- tmp.hack = "using dm at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z

							-- if tonumber(tmp.level) > 2 then
								-- irc_chat(server.ircMain, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
								-- irc_chat(server.ircAlerts, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " UserID: " .. tmp.userID .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
							-- end
						-- end

						-- if tonumber(tmp.level) > 2 then
							-- anticheatBans[tmp.steam] = {}
							-- banPlayer(tmp.platform, tmp.userID, tmp.steam, "10 years", tmp.reason, "")
							-- logHacker(botman.serverTime, "Botman anticheat detected " .. tmp.userID .. " " .. tmp.name .. " " .. tmp.hack)
							-- message("say [" .. server.chatColour .. "]Banning player " .. tmp.name .. " 10 years for using hacks.[-]")
							-- irc_chat("#hackers", "[BANNED] Player " .. tmp.userID .. " " .. tmp.name .. " has been banned for hacking by anticheat.")
							-- irc_chat("#hackers", v)
						-- end
					-- end
				-- end
			-- end
		-- end
	-- end

	-- file:close()
	-- os.remove(homedir .. "/temp/bm-anticheat-report.txt")
-- end


-- function readAPI_BMUptime()
	-- local file, ln, result, data, temp, tmp
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/bm-uptime.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/bm-uptime.txt", "r")

	-- for ln in file:lines() do
		-- temp = string.split(ln, ":")

		-- -- hours
		-- tmp  = tonumber(string.match(temp[4], "(%d+)"))
		-- server.uptime = tmp * 60 * 60

		-- -- minutes
		-- tmp  = tonumber(string.match(temp[5], "(%d+)"))
		-- server.uptime = server.uptime + (tmp * 60)

		-- -- seconds
		-- tmp  = tonumber(string.match(temp[6], "(%d+)"))
		-- server.uptime = server.uptime + tmp
		-- server.serverStartTimestamp = os.time() - server.uptime
	-- end

	-- file:close()
	-- os.remove(homedir .. "/temp/bm-uptime.txt")
-- end


-- function readAPI_BMListPlayerBed()
	-- local file, ln, result, data, temp, pname, pid, x, y, z, i
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/bm-listplayerbed.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/bm-listplayerbed.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- if v ~= "" then
				-- if not string.find(v, "The player") then
					-- temp = string.split(v, ": ")
					-- pname = temp[1]

					-- temp = string.split(v, ", ")
					-- i = tablelength(temp)

					-- x = temp[i - 2]
					-- x = string.split(x, " ")
					-- x = x[tablelength(x)]

					-- y = temp[i - 1]
					-- z = temp[i]

					-- pid = LookupPlayer(pname, "all")
					-- players[pid].bedX = x
					-- players[pid].bedY = y
					-- players[pid].bedZ = z

					-- if botman.dbConnected then conn:execute("UPDATE players SET bedX = " .. x .. ", bedY = " .. y .. ", bedZ = " .. z.. " WHERE steam = '" .. pid .. "'") end
				-- else
					-- pid = string.sub(v, 11, string.find(v, " does ") - 1)
					-- players[pid].bedX = 0
					-- players[pid].bedY = 0
					-- players[pid].bedZ = 0
					-- if botman.dbConnected then conn:execute("UPDATE players SET bedX = 0, bedY = 0, bedZ = 0 WHERE steam = '" .. pid .. "'") end
				-- end
			-- end
		-- end
	-- end

	-- file:close()
	-- os.remove(homedir .. "/temp/bm-listplayerbed.txt")
-- end


-- function readAPI_BMListPlayerFriends()
	-- local file, ln, result, data, temp, pname, pid, k, v
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/bm-listplayerfriends.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/bm-listplayerfriends.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- pid = string.sub(v, 15,31)
			-- temp=string.sub(v, string.find(v, "Friends=") + 8)

			-- if temp ~= "" then
				-- temp = string.split(temp, ",")
			-- end

			-- getBMFriends(pid, temp)
		-- end
	-- end

	-- file:close()
	-- os.remove(homedir .. "/temp/bm-listplayerfriends.txt")
-- end


-- function readAPI_BMReadConfig()

	-- local file, ln, result, data, fileSize, k, v

	-- fileSize = lfs.attributes (homedir .. "/temp/bm-config.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- botman.config = {}
	-- file = io.open(homedir .. "/temp/bm-config.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- for con, q in pairs(conQueue) do
				-- if q.command == "bm-readconfig" then
					-- irc_chat(q.ircUser, v)
				-- end
			-- end

			-- table.insert(botman.config, v)
		-- end

		-- processBotmanConfig()
	-- end

	-- file:close()
	-- os.remove(homedir .. "/temp/bm-config.txt")

	-- for con, q in pairs(conQueue) do
		-- if q.command == "bm-readconfig" then
			-- conQueue[con] = nil
		-- end
	-- end
-- end


-- function readAPI_BMResetRegionsList()
	-- local file, ln, result, data, temp, x, z, fileSize, k, v

	-- fileSize = lfs.attributes (homedir .. "/temp/bm-resetregions-list.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- for k,v in pairs(resetRegions) do
		-- v.inConfig = false
	-- end

	-- file = io.open(homedir .. "/temp/bm-resetregions-list.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- for con, q in pairs(conQueue) do
				-- if q.command == "bm-resetregions list" then
					-- irc_chat(q.ircUser, v)
				-- end
			-- end

			-- if string.find(v, "r.", nil, true) then
				-- temp = string.split(v, "%.")
				-- x = temp[2]
				-- z = temp[3]

				-- if not resetRegions[v .. ".7rg"] then
					-- resetRegions[v .. ".7rg"] = {}
				-- end

				-- resetRegions[v .. ".7rg"].x = x
				-- resetRegions[v .. ".7rg"].z = z
				-- resetRegions[v .. ".7rg"].inConfig = true
				-- conn:execute("INSERT INTO resetZones (region, x, z) VALUES ('" .. escape(v .. ".7rg") .. "'," .. x .. "," .. z .. ")")
			-- end
		-- end
	-- end

	-- file:close()
	-- os.remove(homedir .. "/temp/bm-resetregions-list.txt")

	-- for con, q in pairs(conQueue) do
		-- if q.command == "bm-resetregions list" then
			-- conQueue[con] = nil
		-- end
	-- end

	-- -- for k,v in pairs(resetRegions) do
		-- -- if not v.inConfig then
			-- -- sendCommand("bm-resetregions add " .. v.x .. "." .. v.z)
		-- -- end
	-- -- end

	-- tempTimer(3, [[loadResetZones(true)]])
-- end


-- function readAPI_Command()
	-- local file, ln, result, curr, totalPlayersOnline, temp, data, k, v, getData
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/command.txt", "size")

	-- -- abort if the file is empty and switch back to using telnet
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/command.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)

		-- for con, q in pairs(conQueue) do
			-- if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
				-- if string.find(result.result, "\n") then
					-- data = splitCRLF(result.result)

					-- for k,v in pairs(data) do
						-- irc_chat(q.ircUser, data[k])
					-- end
				-- else
					-- irc_chat(q.ircUser, result.result)
				-- end
			-- end
		-- end

		-- if string.find(result.command, "admin") and not string.find(result.command, "list") then
			-- tempTimer( 2, [[sendCommand("admin list")]] )
		-- end

		-- if string.sub(result.result, 1, 4) == "Day " then
			-- gameTimeTrigger(stripMatching(result.result, "\\r\\n"))
			-- gameTimeTrigger(stripMatching(result.result, "\\n"))
			-- file:close()
			-- return
		-- end

		-- if string.sub(result.command, 1, 3) == "sg " then
			-- result.result = stripMatching(result.result, "\\r\\n")
			-- result.result = stripMatching(result.result, "\\n")
			-- matchAll(result.result)
			-- file:close()
			-- return
		-- end

		-- if result.parameters == "bot_RemoveInvalidItems" then
			-- removeInvalidItems()
			-- file:close()
			-- return
		-- end
	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			-- conQueue[con] = nil
		-- end
	-- end

	-- os.remove(homedir .. "/temp/command.txt")
-- end


-- function readAPI_GetServerInfo()  -- not finished.  May not need as gg already works fine.
	-- local file, ln, result, data, k, v, con, q, gg
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/getserverinfo.txt", "size")

-- end


-- function readAPI_GG()
	-- local file, ln, result, data, k, v, con, q, gg
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/gg.txt", "size")
	-- GamePrefs = {}

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- --botman.resendGG = true
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/gg.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- botman.readGG = true

		-- for k,v in pairs(data) do
			-- for con, q in pairs(conQueue) do
				-- if q.command == "gg" then
					-- irc_chat(q.ircUser, data[k])
				-- end
			-- end

			-- if v ~= "" then
				-- matchAll(v)
			-- end
		-- end

		-- botman.readGG = false
	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if q.command == "gg" then
			-- conQueue[con] = nil
		-- end
	-- end

	-- if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('GamePrefs','panel','" .. escape(yajl.to_string(GamePrefs)) .. "')") end

	-- os.remove(homedir .. "/temp/gg.txt")

	-- if tonumber(server.reservedSlots) > 0 then
		-- initSlots()
	-- end
-- end


-- function readAPI_GT()
	-- local file, ln, result, data, k, v, con, q
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/gametime.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/gametime.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- for con, q in pairs(conQueue) do
				-- if q.command == "gt" then
					-- irc_chat(q.ircUser, data[k])
				-- end
			-- end

			-- if v ~= "" then
				-- gameTimeTrigger(v)
			-- end
		-- end
	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if q.command == "gt" then
			-- conQueue[con] = nil
		-- end
	-- end

	-- os.remove(homedir .. "/temp/gametime.txt")
-- end


-- function readAPI_Help()
	-- local file, ln, result, data, k, v, con, q
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/help.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/help.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- for con, q in pairs(conQueue) do
				-- if string.find(q.command, "help") then
					-- irc_chat(q.ircUser, v)
				-- end
			-- end
		-- end
	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if string.find(q.command, "help") then
			-- conQueue[con] = nil
		-- end
	-- end

	-- os.remove(homedir .. "/temp/help.txt")
-- end


-- function readAPI_Inventories()
	-- if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

	-- local file, ln, result, data, k, v, index, count, steam, playerName
	-- local slot, quantity, quality, itemName
	-- local fileSize, tmp

	-- fileSize = lfs.attributes (homedir .. "/temp/inventories.txt", "size")
	-- tmp = {}

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

	-- file = io.open(homedir .. "/temp/inventories.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- count = tablelength(result)

		-- --if debug then display(result) end

		-- for index=1, count, 1 do
			-- if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

			-- tmp.steam = string.match (result[index].userid, "(-?\%d+)")
			-- tmp.playerName = result[index].playername

			-- if (debug) then
				-- dbug("steam = " .. tmp.steam)
				-- dbug("playerName = " .. tmp.playerName)
			-- end

			-- if (igplayers[tmp.steam].inventoryLast ~= igplayers[tmp.steam].inventory) then
				-- igplayers[tmp.steam].inventoryLast = igplayers[tmp.steam].inventory
			-- end

			-- igplayers[tmp.steam].inventory = ""
			-- igplayers[tmp.steam].oldBelt = igplayers[tmp.steam].belt
			-- igplayers[tmp.steam].belt = ""
			-- igplayers[tmp.steam].oldPack = igplayers[tmp.steam].pack
			-- igplayers[tmp.steam].pack = ""
			-- igplayers[tmp.steam].oldEquipment = igplayers[tmp.steam].equipment
			-- igplayers[tmp.steam].equipment = ""

			-- for k,v in pairs(result[index].belt) do
				-- if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

				-- if v ~= "" then
					-- slot = k

					-- if type(v) == "table" then
						-- tmp.quantity = v.count
						-- tmp.quality = v.quality
						-- tmp.itemName = v.name

						-- igplayers[tmp.steam].inventory = igplayers[tmp.steam].inventory .. tmp.quantity .. "," .. tmp.itemName .. "," .. tmp.quality .. "|"
						-- igplayers[tmp.steam].belt = igplayers[tmp.steam].belt .. slot .. "," .. tmp.quantity .. "," .. tmp.itemName .. "," .. tmp.quality .. "|"
					-- end
				-- end
			-- end

			-- for k,v in pairs(result[index].bag) do
				-- if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

				-- if v ~= "" then
					-- slot = k

					-- if type(v) == "table" then
						-- tmp.quantity = v.count
						-- tmp.quality = v.quality
						-- tmp.itemName = v.name

						-- igplayers[tmp.steam].inventory = igplayers[tmp.steam].inventory .. tmp.quantity .. "," .. tmp.itemName .. "," .. tmp.quality .. "|"
						-- igplayers[tmp.steam].pack = igplayers[tmp.steam].pack .. slot .. "," .. tmp.quantity .. "," .. tmp.itemName .. "," .. tmp.quality .. "|"
					-- end
				-- end
			-- end

			-- for k,v in pairs(result[index].equipment) do
				-- if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

				-- if v ~= "" then
					-- slot = k

					-- if type(v) == "table" then
						-- tmp.quality = v.quality
						-- tmp.itemName = v.name
						-- igplayers[tmp.steam].equipment = igplayers[tmp.steam].equipment .. slot .. "," .. tmp.itemName .. "," .. tmp.quality .. "|"
					-- end
				-- end
			-- end

			-- if debug then
				-- dbug("belt = " .. igplayers[tmp.steam].belt)
				-- dbug("bag = " .. igplayers[tmp.steam].pack)
				-- dbug("inventory = " .. igplayers[tmp.steam].equipment)
			-- end
		-- end
	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			-- conQueue[con] = nil
		-- end
	-- end

	-- if (debug) then dbug("debug readAPI_Inventories line " .. debugger.getinfo(1).currentline) end

	-- os.remove(homedir .. "/temp/inventories.txt")

	-- CheckInventory()
-- end


-- function readAPI_Hostiles()
	-- local file, ln, result, temp, data, k, v, cursor, errorString
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/hostiles.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- end

	-- botman.lastServerResponseTimestamp = os.time()
	-- file = io.open(homedir .. "/temp/hostiles.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)

		-- for k,v in pairs(result) do
			-- if v ~= "" then
				-- if string.find(v.name, "emplate") then
					-- removeEntityCommand(v.id)
				-- end

				-- loc = inLocation(v.position.x, v.position.z)

				-- if loc ~= false then
					-- if locations[loc].killZombies then
						-- removeEntityCommand(v.id)
					-- end
				-- end
			-- end
		-- end
	-- end

	-- file:close()
	-- os.remove(homedir .. "/temp/hostiles.txt")
-- end


-- function readAPI_LE()
	-- local file, ln, result, temp, data, k, v, entityID, entity, cursor, errorString,  con, q, tmp
	-- local fileSize, i

	-- fileSize = lfs.attributes (homedir .. "/temp/le.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- if botman.dbConnected then
		-- connMEM:execute("DELETE FROM entities")
	-- end

	-- file = io.open(homedir .. "/temp/le.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)

		-- if string.find(result.result, "\n") then
			-- data = splitCRLF(result.result)

			-- for k,v in pairs(data) do
				-- if string.find(data[k], "id=") then
					-- listEntities(data[k])
				-- end
			-- end
		-- end

	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if q.command == result.command then
			-- if string.find(result.result, "\n") then
				-- for k,v in pairs(data) do
					-- irc_chat(q.ircUser, data[k])
				-- end
			-- else
				-- irc_chat(q.ircUser, result.result)
			-- end
		-- end
	-- end

	-- for con, q in pairs(conQueue) do
		-- if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			-- conQueue[con] = nil
		-- end
	-- end

	-- os.remove(homedir .. "/temp/le.txt")
-- end


-- function readAPI_LKP()
	-- -- local file, ln, result, temp, data, k, v, cursor, errorString
	-- -- local name, gameID, steamID, IP, playtime, seen, p1, p2
	-- -- local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+)"
	-- -- local runyear, runmonth, runday, runhour, runminute, seenTimestamp, tmp
	-- -- local fileSize

	-- -- fileSize = lfs.attributes (homedir .. "/temp/lkp.txt", "size")

	-- -- -- abort if the file is empty
	-- -- if fileSize == nil or tonumber(fileSize) == 0 then
		-- -- return
	-- -- else
		-- -- if botman.APIOffline then
			-- -- botman.APIOffline = false
			-- -- toggleTriggers("api online")
		-- -- end

		-- -- botman.botOffline = false
		-- -- botman.botOfflineCount = 0
		-- -- botman.lastServerResponseTimestamp = os.time()
	-- -- end

	-- -- file = io.open(homedir .. "/temp/lkp.txt", "r")

	-- -- for ln in file:lines() do
		-- -- result = yajl.to_value(ln)
		-- -- data = splitCRLF(result.result)

		-- -- for k,v in pairs(data) do
			-- -- if v ~= "" then
				-- -- if string.sub(v, 1, 5) ~= "Total" then
					-- -- if botman.dbConnected then
						-- -- connSQL:execute("INSERT INTO LKPQueue (line) VALUES ('" .. escape(v) .. "')")
						-- -- botman.lkpQueueEmpty = false
					-- -- end

					-- -- -- gather the data for the current player
					-- -- temp = string.split(v, ", ")

					-- -- if temp[3] ~= nil then
						-- -- steamID = string.match(temp[3], "(-?%d+)")

						-- -- if players[steamID] then
							-- -- players[steamID].notInLKP = false
						-- -- end
					-- -- end
				-- -- end

				-- -- for con, q in pairs(conQueue) do
					-- -- if q.command == "lkp" then
						-- -- irc_chat(q.ircUser, data[k])
					-- -- end
				-- -- end
			-- -- end
		-- -- end

		-- -- if result.parameters ~= "-online" and botman.archivePlayers then
			-- -- botman.archivePlayers = nil

			-- -- --	Everyone who is flagged notInLKP gets archived.
			-- -- for k,v in pairs(players) do
				-- -- if v.notInLKP then
					-- -- if botman.dbConnected then connSQL:execute("INSERT INTO miscQueue (steam, command) VALUES ('" .. k .. "', 'archive player')") end
					-- -- botman.miscQueueEmpty = false
				-- -- end
			-- -- end
		-- -- end
	-- -- end

	-- -- file:close()

	-- -- for con, q in pairs(conQueue) do
		-- -- if q.command == "lkp" then
			-- -- conQueue[con] = nil
		-- -- end
	-- -- end

	-- os.remove(homedir .. "/temp/lkp.txt")
-- end


-- function readAPI_LI()
	-- local file, ln, result, temp, data, k, v, entityID, entity, cursor, errorString, con, q, exportFile
	-- local fileSize, updateItemsList

	-- fileSize = lfs.attributes (homedir .. "/temp/li.txt", "size")

	-- if not botman.exportItemsList then
		-- updateItemsList = false
		-- spawnableItems = {}
	-- end

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/li.txt", "r")

	-- if botman.exportItemsList then
		-- exportFile = io.open(botman.chatlogPath .. "/temp/items.txt", "w")
	-- end

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)

		-- if result.parameters == "*" then
			-- updateItemsList = true
		-- end

		-- if string.find(result.result, "\n") then
			-- data = splitCRLF(result.result)

			-- for k,v in pairs(data) do
				-- if not string.find(data[k], " matching items.") then
					-- if botman.exportItemsList then
						-- exportFile:write(v .. "\n")
					-- else
						-- if botman.dbConnected then
							-- temp = string.trim(data[k])
							-- if temp ~= "" and updateItemsList then
								-- --conn:execute("INSERT INTO spawnableItems (itemName) VALUES ('" .. escape(temp) .. "')")
								-- spawnableItems[temp] = {}
							-- end
						-- end
					-- end
				-- end
			-- end
		-- end

		-- if not botman.exportItemsList then
			-- for con, q in pairs(conQueue) do
				-- if string.sub(q.command, 1, 3) == "li " then
					-- if string.find(result.result, "\n") then
						-- for k,v in pairs(data) do
							-- temp = string.trim(data[k])
							-- irc_chat(q.ircUser, temp)
						-- end
					-- else
						-- irc_chat(q.ircUser, result.result)
					-- end
				-- end
			-- end
		-- end
	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			-- conQueue[con] = nil
		-- end
	-- end

	-- if not botman.exportItemsList then
		-- if updateItemsList then
			-- removeInvalidItems()
			-- spawnableItems = {}
			-- tempTimer(3, [[loadShop()]])
		-- end
	-- end

	-- if botman.exportItemsList then
		-- botman.exportItemsList = nil
		-- exportFile:close()
	-- end

	-- os.remove(homedir .. "/temp/li.txt")
-- end


-- function readAPI_LLP()
	-- local file, ln, result, temp, coords, data, k, v, a, b, cursor, errorString, con, q, tmp
	-- local x, y, z, keystoneCount, region, loc, reset, expired, noPlayer, archived
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/llp.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- end

	-- tmp = {}

	-- botman.lastServerResponseTimestamp = os.time()
	-- connSQL:execute("DELETE FROM keystones WHERE x = 0 AND y = 0 AND z = 0")

	-- file = io.open(homedir .. "/temp/llp.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)

		-- for con, q in pairs(conQueue) do
			-- if string.find(q.command, result.command) then
				-- if string.find(result.result, "\n") then
					-- data = splitCRLF(result.result)

					-- for k,v in pairs(data) do
						-- irc_chat(q.ircUser, data[k])
					-- end
				-- else
					-- irc_chat(q.ircUser, result.result)
				-- end
			-- end
		-- end

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
	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			-- conQueue[con] = nil
		-- end
	-- end

	-- os.remove(homedir .. "/temp/llp.txt")
-- end


-- function readAPI_LPF()
	-- local file, ln, result, data, k, v, con, q
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/lpf.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- end

	-- botman.lastServerResponseTimestamp = os.time()
	-- file = io.open(homedir .. "/temp/lpf.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- for con, q in pairs(conQueue) do
				-- if string.sub(q.command, 1, 3) == "lpf" then
					-- irc_chat(q.ircUser, data[k])
				-- end
			-- end

			-- if not string.find(v, "Player") and v ~= "" then
				-- getFriends(v)
			-- end
		-- end
	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			-- conQueue[con] = nil
		-- end
	-- end

	-- os.remove(homedir .. "/temp/lpf.txt")
-- end


-- function readAPI_LP()
	-- local file, ln, result, index, con, q
	-- local fileSize, k, v, a, b, errorMessage, tmp

	-- fileSize = lfs.attributes (homedir .. "/temp/lp.txt", "size")

	-- tmp = {}

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/lp.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- tmp.split = string.split(v, ", ")

			-- for a,b in pairs(tmp.split) do
				-- if string.find(b, "pltfmid=") then
					-- tmp.temp = string.split(b, "_")
					-- tmp.steam = tmp.temp[2]
				-- end

				-- if string.find(b, "crossid=") then
					-- tmp.temp = string.split(b, "=")
					-- tmp.userID = tmp.temp[2]
				-- end
			-- end

			-- if not joiningPlayers[tmp.steam] then
				-- joiningPlayers[tmp.steam] = {}
				-- joiningPlayers[tmp.steam].steam = tmp.steam
				-- joiningPlayers[tmp.steam].userID = tmp.userID

				-- connSQL:execute("INSERT INTO joiningPlayers (steam, userID, timestamp) VALUES ('" .. tmp.steam .. "','" .. tmp.userID .. "'," .. os.time() .. ")")
			-- else
				-- joiningPlayers[tmp.steam].steam = tmp.steam
				-- joiningPlayers[tmp.steam].userID = tmp.userID
			-- end

			-- if not players[tmp.steam].userID then
				-- players[tmp.steam].userID = tmp.userID
			-- else
				-- if players[tmp.steam].userID == "" then
					-- players[tmp.steam].userID = tmp.userID
				-- end
			-- end

			-- if igplayers[tmp.steam] then
				-- if not igplayers[tmp.steam].userID then
					-- igplayers[tmp.steam].userID = tmp.userID
				-- else
					-- if igplayers[tmp.steam].userID == "" then
						-- igplayers[tmp.steam].userID = tmp.userID
					-- end
				-- end
			-- end
		-- end
	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if q.command == "lp" then
			-- conQueue[con] = nil
		-- end
	-- end

	-- os.remove(homedir .. "/temp/lp.txt")
-- end


-- function readAPI_PlayersOnline()
	-- local file, ln, result, index, totalPlayersOnline, con, q
	-- local fileSize, k, v, lpdata, success, errorMessage

	-- fileSize = lfs.attributes (homedir .. "/temp/playersOnline.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/playersOnline.txt", "r")
	-- playersOnlineList = {}

	-- if botman.trackingTicker == nil then
		-- botman.trackingTicker = 0
	-- end

	-- botman.trackingTicker = botman.trackingTicker + 1

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)

		-- if result == "[]" then
			-- botman.playersOnline =	0
		-- else
			-- botman.playersOnline = tablelength(result)
		-- end

		-- for index=1, tonumber(botman.playersOnline), 1 do
			-- lpdata = {}

			-- temp = string.split(result[index].steamid, "_")
			-- lpdata.platform = temp[1]
			-- lpdata.steam = temp[2]
			-- lpdata.steam = tostring(lpdata.steam)

			-- if lpdata.platform ~= "Steam" then
				-- lpdata.steamOwner = lpdata.steam
			-- end

			-- --lpdata.steam = string.sub(result[index].steamid, 7)
			-- lpdata.entityid = result[index].entityid
			-- lpdata.score = result[index].score
			-- lpdata.zombiekills = result[index].zombiekills
			-- lpdata.level = math.floor(result[index].level)
			-- lpdata.playerdeaths = result[index].playerdeaths
			-- lpdata.ping = result[index].ping
			-- lpdata.ip = result[index].ip
			-- lpdata.name = result[index].name
			-- lpdata.playerkills = result[index].playerkills
			-- lpdata.x = result[index].position.x
			-- lpdata.y = result[index].position.y
			-- lpdata.z = result[index].position.z
			-- lpdata.rawPosition = lpdata.x .. lpdata.y .. lpdata.z

			-- if not igplayers[lpdata.steam] then
				-- fixMissingIGPlayer(lpdata.platform, lpdata.steam, lpdata.steam)
			-- end

			-- if lpdata.userID then
				-- if lpdata.userID == "" then
					-- lpdata.userID = LookupJoiningPlayer(lpdata.steam)
				-- end
			-- else
				-- lpdata.userID = LookupJoiningPlayer(lpdata.steam)
			-- end

			-- playersOnlineList[lpdata.steam] = {}
			-- playersOnlineList[lpdata.steam].faulty = false

			-- success, errorMessage = pcall(playerInfo, lpdata)

			-- if not success then
				-- windowMessage(server.windowDebug, "!! Fault detected in playerinfo\n")
				-- windowMessage(server.windowDebug, "Last debug line " .. playersOnlineList[lpdata.steam].debugLine .. "\n")
				-- windowMessage(server.windowDebug, "Faulty player " .. lpdata.platform .. "_" .. lpdata.steam .. " " .. lpdata.name ..  "\n")
				-- windowMessage(server.windowDebug, ln .. "\n")
				-- windowMessage(server.windowDebug, "----------\n")

				-- playersOnlineList[lpdata.steam].faulty = true
				-- fixMissingPlayer(lpdata.platform, lpdata.steam, lpdata.steam, lpdata.userID)
				-- fixMissingIGPlayer(lpdata.platform, lpdata.steam, lpdata.steam, lpdata.userID)
			-- end
		-- end
	-- end

	-- if tonumber(botman.trackingTicker) > 2 then
		-- botman.trackingTicker = 0
	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if q.command == "lp" then
			-- conQueue[con] = nil
		-- end
	-- end

	-- for k,v in pairs(igplayers) do
		-- if not playersOnlineList[k] then
			-- v.killTimer = 2
		-- end
	-- end

	-- if tonumber(server.reservedSlots) > 0 then
		-- if botman.initReservedSlots then
			-- initSlots()
			-- botman.initReservedSlots = false
		-- end
	-- end

	-- os.remove(homedir .. "/temp/playersOnline.txt")
-- end


-- function readAPI_PGD()
	-- local file, ln, result, data, k, v
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/pgd.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- end

	-- botman.lastServerResponseTimestamp = os.time()
	-- file = io.open(homedir .. "/temp/pgd.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- if v ~= "" then
				-- matchAll(v)
			-- end
		-- end

	-- end

	-- file:close()
	-- os.remove(homedir .. "/temp/pgd.txt")
-- end


-- function readAPI_PUG()
	-- local file, ln, result, data, k, v
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/pug.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- end

	-- botman.lastServerResponseTimestamp = os.time()
	-- file = io.open(homedir .. "/temp/pug.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- if v ~= "" then
				-- matchAll(v)
			-- end
		-- end

	-- end

	-- file:close()
	-- os.remove(homedir .. "/temp/pug.txt")
-- end


-- function writeAPILog(line)
	-- -- log the chat
	-- file = io.open(homedir .. "/telnet_logs/" .. os.date("%Y_%m_%d") .. "_API_log.txt", "a")
	-- file:write(botman.serverTime .. "; " .. string.trim(line) .. "\n")
	-- file:close()
-- end


-- function readAPI_ReadLog()
	-- local file, fileSize, ln, result, temp, data, k, v
	-- local uptime, date, time, msg, handled, skipLog

	-- fileSize = lfs.attributes (homedir .. "/temp/log.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/log.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)

		-- for k,v in pairs(result.entries) do
			-- msg = v.msg

			-- uptime = v.uptime
			-- date = v.date
			-- time = v.time

			-- skipLog = false
			-- handled = false

			-- -- do some wibbly-wobbly timey-wimey stuff
			-- botman.serverTime = date .. " " .. time
			-- botman.serverTimeStamp = dateToTimestamp(botman.serverTime)

			-- if not botman.serverTimeSync then
				-- botman.serverTimeSync = 0
			-- end

			-- if botman.serverTimeSync == 0 then
				-- botman.serverTimeSync = -(os.time() - botman.serverTimeStamp)
			-- end

			-- botman.serverHour = string.sub(time, 1, 2)
			-- botman.serverMinute = string.sub(time, 4, 5)
			-- specialDay = ""

			-- if (string.find(botman.serverTime, "02-14", 5, 10)) then specialDay = "valentine" end
			-- if (string.find(botman.serverTime, "12-25", 5, 10)) then specialDay = "christmas" end

			-- if server.dateTest == nil then
				-- server.dateTest = date
			-- end

			-- if not handled then
				-- -- stuff to ignore
				-- if string.find(msg, "WebCommandResult") then
					-- handled = true
					-- --skipLog = true
				-- end

				-- if string.find(msg, "SleeperVolume") then
					-- handled = true
					-- skipLog = true
				-- end
			-- end

			-- -- handle errors in the log by passing them to matchAll where they are collated
			-- if not handled then
				-- if string.find(msg, "NaN") then
					-- handled = true
					-- skipLog = true
					-- matchAll(msg, date, time)
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "INF Delta out") then
					-- handled = true
					-- skipLog = true
					-- matchAll(msg, date, time)
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "INF Missing ") then
					-- handled = true
					-- skipLog = true
					-- matchAll(msg, date, time)
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "INF Error ") then
					-- handled = true
					-- skipLog = true
					-- matchAll(msg, date, time)
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "IndexOutOfRangeException") then
					-- handled = true
					-- skipLog = true
					-- matchAll(msg, date, time)
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "Unbalanced") then
					-- handled = true
					-- skipLog = true
					-- matchAll(msg, date, time)
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "NullReferenceException") then
					-- handled = true
					-- skipLog = true
					-- matchAll(msg, date, time)
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "WRN ") then
					-- handled = true
					-- skipLog = true
					-- matchAll(msg, date, time)
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "NullReferenceException") then
					-- handled = true
					-- skipLog = true
					-- matchAll(msg, date, time)
				-- end
			-- end

			-- -- everything else
			-- if not handled then
				-- if string.find(msg, "Chat:", nil, true) or string.find(msg, "Chat (from", nil, true) then --  and not string.find(msg, " to 'Party')", nil, true) and not string.find(msg, " to 'Friend')", nil, true)
					-- gmsg(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "to 'Global'", nil, true) then --  and not string.find(msg, " to 'Party')", nil, true) and not string.find(msg, " to 'Friend')", nil, true)
					-- gmsg(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "Executing command 'pm ", nil, true) or string.find(msg, "Denying command 'pm", nil, true) then
					-- gmsg(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "Chat command from", nil, true) then --  or string.find(msg, "GMSG:", nil, true)
					-- gmsg(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "denied: Too many players on the server!", nil, true) then
					-- playerDenied(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "Player connected") then
					-- playerConnected(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "Player disconnected") then
					-- playerDisconnected(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if server.enableScreamerAlert then
					-- if string.find(msg, "AIDirector: Spawning Scouts", nil, true) then
						-- scoutsWarning(msg)
						-- handled = true
					-- end
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "Telnet executed 'tele ", nil, true) or string.find(msg, "Executing command 'tele ", nil, true) then
					-- teleTrigger(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "Heap:", nil, true) then
					-- memTrigger(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.sub(msg, 1, 4) == "Day " then
					-- gameTimeTrigger(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "INF Player with ID") then
					-- overstackTrigger(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "banned until") then
					-- collectBan(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "Executing command 'ban remove", nil, true) then
					-- unbanPlayer(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if string.find(msg, "eliminated") or string.find(msg, "killed by") then
					-- pvpPolice(msg)
					-- handled = true
				-- end
			-- end

			-- if not handled then
				-- if server.enableAirdropAlert then
					-- if string.find(msg, "AIAirDrop: Spawned supply crate") then
						-- airDropAlert(msg)
						-- handled = true
					-- end
				-- end
			-- end

			-- -- if nothing else processed the log line send it to matchAll
			-- if not handled then
				-- matchAll(msg, date, time)
			-- end

			-- -- if not skipLog then
				-- -- writeAPILog(msg)
			-- -- end
		-- end
	-- end

	-- file:close()
-- end


-- function readAPI_SE()
	-- local file, ln, result, temp, data, k, v, getData, entityID, entity, cursor, status, errorString, fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/se.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- end

	-- botman.lastServerResponseTimestamp = os.time()
	-- file = io.open(homedir .. "/temp/se.txt", "r")
	-- getData = false

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- for con, q in pairs(conQueue) do
				-- if q.command == "se" then
					-- irc_chat(q.ircUser, data[k])
				-- end
			-- end

			-- if (string.find(v, "entity numbers:")) then
				-- -- flag all the zombies for removal so we can detect deleted zeds
				-- if botman.dbConnected then
					-- conn:execute("UPDATE gimmeZombies SET remove = 1")
					-- conn:execute("UPDATE otherEntities SET remove = 1")
				-- end

				-- getData = true
			-- else
				-- if getData then
					-- if v ~= "" then
						-- temp = string.split(v, "%-")

						-- entityID = string.trim(temp[1])
						-- entity = string.trim(temp[2])

						-- if string.find(entity, "emplate") or string.find(entity, "Test") or string.find(entity, "playerNewMale") then
							-- -- skip it
						-- else
							-- if string.find(v, "ombie") then
								-- if botman.dbConnected then
									-- status, errorString = conn:execute("INSERT INTO gimmeZombies (zombie, entityID) VALUES ('" .. entity .. "'," .. entityID .. ")")

									-- if not status then
										-- if string.find(errorString, "Duplicate entry") then
											-- conn:execute("UPDATE gimmeZombies SET remove = 0 WHERE entityID = " .. entityID)
										-- end
									-- end
								-- end

								-- updateGimmeZombies(entityID, entity)
							-- else
								-- if botman.dbConnected then
									-- status, errorString = conn:execute("INSERT INTO otherEntities (entity, entityID) VALUES ('" .. entity .. "','" .. escape(entityID) .. "')")

									-- if not status then
										-- if string.find(errorString, "Duplicate entry") then
											-- conn:execute("UPDATE otherEntities SET remove = 0 WHERE entityID = '" .. escape(entityID) .. "'")
										-- end
									-- end
								-- end

								-- updateOtherEntities(entityID, entity)
							-- end
						-- end
					-- end
				-- end
			-- end
		-- end
	-- end

	-- file:close()

	-- if botman.dbConnected then conn:execute("DELETE FROM gimmeZombies WHERE remove = 1 OR zombie LIKE '%Template%'") end
	-- loadGimmeZombies()

	-- if botman.dbConnected then conn:execute("DELETE FROM otherEntities WHERE remove = 1 OR entity LIKE '%Template%' OR entity LIKE '%invisible%'") end
	-- loadOtherEntities()

	-- if botman.dbConnected then
		-- cursor,errorString = conn:execute("SELECT MAX(entityID) AS maxZeds FROM gimmeZombies")
		-- row = cursor:fetch({}, "a")
		-- botman.maxGimmeZombies = tonumber(row.maxZeds)
	-- end

	-- for con, q in pairs(conQueue) do
		-- if (q.command == result.command) or (q.command == result.command .. " " .. result.parameters) then
			-- conQueue[con] = nil
		-- end
	-- end

	-- os.remove(homedir .. "/temp/se.txt")
-- end


-- function readAPI_MEM()
	-- local file, ln, result, data, con, q
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/mem.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/mem.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)

		-- for con, q in pairs(conQueue) do
			-- if q.command == result.command then
				-- if string.find(result.result, "\n") then
					-- data = splitCRLF(result.result)

					-- for k,v in pairs(data) do
						-- irc_chat(q.ircUser, data[k])
					-- end
				-- else
					-- irc_chat(q.ircUser, result.result)
				-- end
			-- end
		-- end

		-- data = stripMatching(result.result, "\\r\\n")
		-- data = stripMatching(result.result, "\\n")
		-- memTrigger(data)
	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if q.command == result.command then
			-- conQueue[con] = nil
		-- end
	-- end

	-- os.remove(homedir .. "/temp/mem.txt")
-- end


-- function readAPI_webpermission()
	-- local file, ln, result, data, con, q
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/apitest.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- end

	-- file = io.open(homedir .. "/temp/apitest.txt", "r")

	-- for ln in file:lines() do
		-- if string.find(ln, "No sub command given") then
			-- -- the api is working so put the bot back into api mode
			-- server.useAllocsWebAPI = true
			-- botman.APIOffline = false
			-- botman.botOffline = false
			-- botman.botOfflineCount = 0
			-- botman.APIOfflineCount = 0
			-- botman.lastServerResponseTimestamp = os.time()

			-- toggleTriggers("api online")
			-- conn:execute("UPDATE server set useAllocsWebAPI = 1")
		-- end
	-- end

	-- file:close()
-- end


-- function readAPI_webUIUpdates()
	-- local file, ln, result, data, con, q
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/webUIUpdates.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.botOffline or botman.APIOffline then
			-- irc_chat(server.ircMain, "The bot has connected to the server API.")
		-- end

		-- toggleTriggers("api online")

		-- botman.APIOffline = false
		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- file = io.open(homedir .. "/temp/webUIUpdates.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- result.newlogs = tonumber(result.newlogs)
		-- botman.newlogs = result.newlogs

		-- if not botman.lastLogLine then
			-- botman.lastLogLine = result.newlogs
		-- end

		-- if tonumber(botman.lastLogLine) < botman.newlogs then
			-- getAPILog()
		-- end

		-- botman.lastLogLine = botman.newlogs + 1

		-- if tonumber(result.players) >= 0 then
			-- botman.playersOnline = tonumber(result.players)
		-- else
			-- botman.playersOnline = 0
		-- end
	-- end

	-- file:close()
-- end


-- function readAPI_Version()
	-- local file, ln, result, data, k, v, con, q
	-- local fileSize

	-- fileSize = lfs.attributes (homedir .. "/temp/installedMods.txt", "size")

	-- -- abort if the file is empty
	-- if fileSize == nil or tonumber(fileSize) == 0 then
		-- return
	-- else
		-- if botman.APIOffline then
			-- botman.APIOffline = false
			-- toggleTriggers("api online")
		-- end

		-- botman.botOffline = false
		-- botman.botOfflineCount = 0
		-- botman.lastServerResponseTimestamp = os.time()
	-- end

	-- modVersions = {}
	-- server.allocs = false
	-- server.botman = false
	-- server.otherManager = false

	-- file = io.open(homedir .. "/temp/installedMods.txt", "r")

	-- for ln in file:lines() do
		-- result = yajl.to_value(ln)
		-- data = splitCRLF(result.result)

		-- for k,v in pairs(data) do
			-- if v ~= "" then
				-- matchAll(v)
			-- end

			-- for con, q in pairs(conQueue) do
				-- if q.command == "version" then
					-- irc_chat(q.ircUser, data[k])
				-- end
			-- end
		-- end

	-- end

	-- file:close()

	-- for con, q in pairs(conQueue) do
		-- if q.command == "version" then
			-- conQueue[con] = nil
		-- end
	-- end

	-- if server.allocs and server.botman then
		-- botMaintenance.modsInstalled = true
	-- else
		-- botMaintenance.modsInstalled = false
	-- end

	-- saveBotMaintenance()

	-- if botman.dbConnected then
		-- conn:execute("DELETE FROM webInterfaceJSON WHERE ident = 'modVersions'")
		-- conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('modVersions','panel','" .. escape(yajl.to_string(modVersions)) .. "')")
	-- end

	-- os.remove(homedir .. "/temp/installedMods.txt")
	-- table.save(homedir .. "/data_backup/modVersions.lua", modVersions)
-- end
