--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

local debug, result, x, z, id, pname, noWaypoint, temp, chatStringStart, cmd, msg, test, ircMsg, chatFlag

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false -- should be false unless testing


function day7ForPanel()
	if (server.gameDay % server.hordeNight == 0) then
		return 0
	end

	if ((server.gameDay + 1) % server.hordeNight == 0) then
		return 1
	end

	if ((server.gameDay + 2) % server.hordeNight == 0) then
		return 2
	end

	if ((server.gameDay + 3) % server.hordeNight == 0) then
		return 3
	end

	if ((server.gameDay + 4) % server.hordeNight == 0) then
		return 4
	end

	if ((server.gameDay + 5) % server.hordeNight == 0) then
		return 5
	end

	if ((server.gameDay + 6) % server.hordeNight == 0) then
		return 6
	end

	if ((server.gameDay + 7) % server.hordeNight == 0) then
		return 7
	end

	if ((server.gameDay + 8) % server.hordeNight == 0) then
		return 8
	end

	if ((server.gameDay + 9) % server.hordeNight == 0) then
		return 9
	end

	if ((server.gameDay + 10) % server.hordeNight == 0) then
		return 10
	end

	if ((server.gameDay + 11) % server.hordeNight == 0) then
		return 11
	end

	if ((server.gameDay + 12) % server.hordeNight == 0) then
		return 12
	end

	if ((server.gameDay + 13) % server.hordeNight == 0) then
		return 13
	end

	if ((server.gameDay + 14) % server.hordeNight == 0) then
		return 14
	end

	if ((server.gameDay + 15) % server.hordeNight == 0) then
		return 15
	end

	if ((server.gameDay + 16) % server.hordeNight == 0) then
		return 16
	end

	if ((server.gameDay + 17) % server.hordeNight == 0) then
		return 17
	end

	if ((server.gameDay + 18) % server.hordeNight == 0) then
		return 18
	end

	if ((server.gameDay + 19) % server.hordeNight == 0) then
		return 19
	end

	if ((server.gameDay + 20) % server.hordeNight == 0) then
		return 20
	end

	if ((server.gameDay + 21) % server.hordeNight == 0) then
		return 21
	end

	return 99
end


function day7(userID)
	local warning

	warning = " "

	if server.BloodMoonRange then
		if tonumber(server.BloodMoonRange) > 0 then
			warning = " about "
		end
	end

	if (server.gameDay % server.hordeNight == 0) then
		if steam ~= nil then
			if warning == " " then
				message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes will run tonight![-]")
			else
				message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes may run tonight![-]")
			end
		else
			if warning == " " then
				message("say [" .. server.chatColour .. "]Feral hordes will run tonight![-]")
			else
				message("say [" .. server.chatColour .. "]Feral hordes may run tonight![-]")
			end
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 1) % server.hordeNight == 0) then
		if steam ~= nil then
			if warning == " " then
				message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected tomorrow![-]")
			else
				message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes could arrive tomorrow![-]")
			end
		else
			if warning == " " then
				message("say [" .. server.chatColour .. "]Feral hordes are expected tomorrow![-]")
			else
				message("say [" .. server.chatColour .. "]Feral hordes could arrive tomorrow![-]")
			end
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 2) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "2 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "2 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 3) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "3 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "3 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 4) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "4 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "4 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 5) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "5 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "5 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 6) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "6 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "6 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 7) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "7 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "7 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 8) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "8 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "8 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 9) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "9 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "9 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 10) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "10 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "10 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 11) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "11 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "11 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 12) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "12 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "12 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 13) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "13 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "13 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 14) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "14 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "14 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 15) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "15 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "15 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 16) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "16 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "16 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 17) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "17 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "17 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 18) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "18 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "18 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 19) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "19 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "19 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 20) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "20 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "20 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 21) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. userID .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "21 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "21 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if steam ~= nil then
		message("pm " .. userID .. " [" .. server.chatColour .. "]Relax. The next feral horde is ages away.[-]")
	else
		message("say [" .. server.chatColour .. "]Relax. The next feral horde is ages away.[-]")
	end

	botman.faultyChat = false
	return true
end


function nextReboot(steam)
	local tmp

	tmp = {}
	tmp.dailyRebootTime = 0

	if igplayers[steam] then
		tmp.userID = igplayers[steam].userID
	else
		tmp.userID = "."
	end

	if not server.allowReboot then
		if steam == nil then
			message("say [" .. server.chatColour .. "]Server reboots are not managed by me at the moment.[-]")
		else
			if igplayers[steam] then
				message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]Server reboots are not managed by me at the moment.[-]")
			end

			irc_chat(players[steam].ircAlias, "Server reboots are not managed by me at the moment.")
		end

		return
	end

	if botman.restartTimeRemaining then
		tmp.timeRemaining = botman.restartTimeRemaining
	else
		-- if a daily reboot time is set, calc as seconds since midnight
		if tonumber(server.rebootHour) ~= 0 or tonumber(server.rebootMinute) ~= 0 then
			tmp.dailyRebootTime = (tonumber(server.rebootHour) * 60 * 60) + (tonumber(server.rebootMinute) * 60)
		end

		if botman.scheduledRestartTimestamp and botman.scheduledRestart then
			tmp.timeRemaining = botman.scheduledRestartTimestamp - os.time()
			tmp.dailyRebootTime = 0
		end

		if tmp.dailyRebootTime > 0 then
			tmp.midnightTimestamp = {year=os.date('%Y', botman.serverTimeStamp), month=os.date('%m', botman.serverTimeStamp), day=os.date('%d', botman.serverTimeStamp), hour=0, min=0, sec=0}
			tmp.secondsSinceMidnight = botman.serverTimeStamp - os.time(midnightTimestamp)
			tmp.timeRemaining = tmp.dailyRebootTime - tmp.secondsSinceMidnight

			if tmp.timeRemaining < 0 then
				if server.maxServerUptime < 25 then
					tmp.timeRemaining = (tonumber(server.maxServerUptime) * 3600) - server.uptime
				else
					tmp.timeRemaining = (tonumber(server.maxServerUptime) * 60) - server.uptime
				end
			end
		end

		if server.maxServerUptime < 25 then
			if not tmp.timeRemaining2 then
				tmp.timeRemaining2 = (tonumber(server.maxServerUptime) * 3600) - server.uptime
			end
		else
			if botman.scheduledRestartTimestamp and botman.scheduledRestart then
				if not tmp.timeRemaining2 then
					tmp.timeRemaining2 = botman.scheduledRestartTimestamp - os.time()
				end
			else
				if not tmp.timeRemaining2 then
					tmp.timeRemaining2 = (tonumber(server.maxServerUptime) * 60) - server.uptime
				end
			end
		end

	end

	-- find the shortest time to next reboot
	if not tmp.timeRemaining then
		if tmp.timeRemaining2 then
			tmp.timeRemaining = tmp.timeRemaining2
		end
	else
		if tmp.timeRemaining2 then
			if tmp.timeRemaining2 < tmp.timeRemaining then
				tmp.timeRemaining = tmp.timeRemaining2
			end
		end
	end

	tmp.diff = tmp.timeRemaining
	tmp.days = math.floor(tmp.diff / 86400)

	if (tmp.days > 0) then
		tmp.diff = tmp.diff - (tmp.days * 86400)
	end

	tmp.hours = math.floor(tmp.diff / 3600)

	if (tmp.hours > 0) then
		tmp.diff = tmp.diff - (tmp.hours * 3600)
	end

	tmp.minutes = math.floor(tmp.diff / 60)

	if (tmp.minutes > 0) then
		tmp.seconds = tmp.diff - (tmp.minutes * 60)
	end

	if botman.scheduledRestartPaused then
		if steam == nil then
			message("say [" .. server.chatColour .. "]The reboot is paused at the moment.[-]")
		else
			if igplayers[steam] then
				message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]The reboot is paused at the moment.[-]")
			end

			irc_chat(players[steam].ircAlias, "The reboot is paused at the moment.")
		end
	else
		if (server.gameDay % server.hordeNight == 0) then
			if steam == nil then
				message("say [" .. server.chatColour .. "]Feral hordes run today so the server will reboot tomorrow.[-]")
			else
				if igplayers[steam] then
					message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]Feral hordes run today so the server will reboot tomorrow.[-]")
				end

				irc_chat(players[steam].ircAlias, "Feral hordes run today so the server will reboot tomorrow.")
			end
		else
			tmp.strDays = "days"
			if tmp.days == 1 then tmp.strDays = "day" end

			tmp.strHours = "hours"
			if tmp.hours == 1 then tmp.strHours = "hour" end

			tmp.strMinutes = "minutes"
			if tmp.minutes == 1 then tmp.strMinutes = "minute" end

			if steam == nil then
				if tmp.days > 0 then
					message("say [" .. server.chatColour .. "]The next reboot is in " .. tmp.days .. " " .. tmp.strDays .. " " .. tmp.hours .. " " .. tmp.strHours .. " and " .. tmp.minutes .. " " .. tmp.strMinutes .. "[-]")
				else
					if tmp.hours > 0 then
						message("say [" .. server.chatColour .. "]The next reboot is in " .. tmp.hours .. " " .. tmp.strHours .. " and " .. tmp.minutes .. " " .. tmp.strMinutes .. "[-]")
					else
						message("say [" .. server.chatColour .. "]The next reboot is in " .. tmp.minutes .. " " .. tmp.strMinutes .. "[-]")
					end
				end
			else
				if igplayers[steam] then
					if tmp.days > 0 then
						message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]The next reboot is in " .. tmp.days .. " " .. tmp.strDays .. " " .. tmp.hours .. " " .. tmp.strHours .. " and " .. tmp.minutes .. " " .. tmp.strMinutes .. "[-]")
					else
						if tmp.hours > 0 then
							message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]The next reboot is in " .. tmp.hours .. " " .. tmp.strHours .. " and " .. tmp.minutes .. " " .. tmp.strMinutes .. "[-]")
						else
							message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]The next reboot is in " .. tmp.minutes .. " " .. tmp.strMinutes .. "[-]")
						end
					end
				end

				irc_chat(players[steam].ircAlias, "The next reboot is in " .. tmp.days .. " days " .. string.format("%02d", tmp.hours) .. " hours and " .. string.format("%02d", tmp.minutes) .." minutes")
			end
		end
	end
end


function baseStatus(command, steam, userID)
	local pname, id, protected, k, v, baseFound

	pname = nil
	if (isAdminHidden(steam, userID) and string.find(command, "status ")) then
		pname = string.sub(command, string.find(command, "status") + 7)
		if (pname ~= nil) then
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id== "0" then
				id = LookupArchivedPlayer(pname)

				if id== "0" then
					message("pm " .. userID .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
				else
					message("pm " .. userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived and their base(s) are not active.[-]")
				end

				return false
			end
		end
	end

	if (pname == nil) then
		id = steam
		pname = players[steam].name
	else
		pname = players[id].name
	end

	message("pm " .. userID .. " [" .. server.chatColour .. "]You have " .. string.format("%d", players[id].cash) .. " " .. server.moneyPlural .. " in the bank.[-]")

	for k,v in pairs(bases) do
		if id == v.steam then
			baseFound = true

			if v.protect then
				protected = " protected"
			else
				protected = ""
			end

			message("pm " .. userID .. " [" .. server.chatColour .. "]Base " .. string.trim(v.baseNumber .. " " .. v.title) .. " at " .. v.x .. " " .. v.y .. " " .. v.z .. protected .. "[-]")
		end
	end

	if not baseFound then
		if (id == steam) then
			base = "You do not have a base set yet"
		else
			base = pname .. " does not have a base set yet"
		end
	end

	if (players[id].protectPaused ~= nil) then
		message("pm " .. userID .. " [" .. server.chatColour .. "]Base protection is temporarily paused.[-]")
	end

	if isAdminHidden(steam, userID) then
		message("pm " .. userID .. " [" .. server.chatColour .. "]Current session is " .. players[id].sessionCount .. "[-]")
		message("pm " .. userID .. " [" .. server.chatColour .. "]Claims placed " .. players[id].keystones .. "[-]")
	end

	return false
end


function gmsg(line, ircid)
	local pos, file, tmp, temp

	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

	if not server.gameVersionNumber then
		sendCommand("version")
	end

	if botman.worldGenerating then
		-- wake the bot up
		botman.worldGenerating = nil
	end

	-- Hi there! ^^  Welcome to the function that parses player chat.  It builds a lua table called chatvars filled with lots of info
	-- about the current line of player chat.  This fuction essentially pre-processes the line so that later code that chatvars is passed to
	-- doesn't have to do much more to it other than try to match trigger words.  Player chat gets the bot triggered. xD

	-- here is an example of a chat line and the resulting chatvars table:

	-- 2022-07-17T21:05:08 13603.800 INF Chat handled by mod 'Botman': Chat (from 'Steam_76561197983251951', entity id '3281', to 'Global'): 'Smegz0r': /rules

	-- {
	  -- intY = 39,
	  -- userID = "EOS_000236e4866847daa11cf36e1b8b630a",
	  -- intZ = 1200,
	  -- restrictedCommand = false,
	  -- command = "/rules",
	  -- helpRead = false,
	  -- region = "r.-1.2.7rg",
	  -- wordCount = 1,
	  -- botCommand = true,
	  -- accessLevel = 0,
	  -- timestamp = 1658055908,
	  -- nonBotCommand = false,
	  -- numberCount = 0,
	  -- gameid = 3281,
	  -- isAdmin = true,
	  -- isAdminHidden = false,
	  -- settings = {
		-- maxGimmies = 11,
		-- teleportPublicCost = 0,
		-- reserveSlot = true,
		-- maxWaypoints = 10,
		-- maxBases = 3,
		-- allowTeleporting = false,
		-- allowGimme = true,
		-- lotteryTicketPrice = 25,
		-- packCost = 0,
		-- returnCooldown = 60,
		-- baseCooldown = 1800,
		-- packCooldown = 60,
		-- teleportCost = 0,
		-- allowLottery = false,
		-- p2pCooldown = 1800,
		-- waypointCreateCost = 5000,
		-- deathCost = 100,
		-- maxProtectedBases = 1,
		-- allowShop = true,
		-- gimmeZombies = true,
		-- allowPlayerToPlayerTeleporting = true,
		-- allowWaypoints = true,
		-- mapSize = 10000,
		-- allowHomeTeleport = true,
		-- zombieKillReward = 3,
		-- gimmeRaincheck = 3600,
		-- baseCost = 0,
		-- allowVisitInPVP = true,
		-- teleportPublicCooldown = 0,
		-- playerTeleportDelay = 30,
		-- waypointCost = 50,
		-- perMinutePayRate = 10,
		-- baseSize = 32,
		-- lotteryMultiplier = 2,
		-- hardcore = false,
		-- waypointCooldown = 120,
		-- pvpAllowProtect = false
	  -- },
	  -- wordsOld = {
		-- "rules"
	  -- },
	  -- playername = "Smegz0r",
	  -- oldLine = "2022-07-17T21:05:08 13603.800 INF Chat handled by mod 'Botman': Chat (from 'Steam_76561197983251951', entity id '3281', to 'Global'): 'Smegz0r': /rules",
	  -- platform = "Steam",
	  -- commandOld = "/rules",
	  -- steamOwner = "76561197983251951",
	  -- suppress = false,
	  -- numbers = {
	  -- },
	  -- words = {
		-- "rules"
	  -- },
	  -- chatPublic = true,
	  -- zombies = 52,
	  -- adminLevel = 0,
	  -- inLocation = "safetest",
	  -- intX = -272,
	  -- ircAlias = "",
	  -- ircid = "0",
	  -- playerid = "76561197983251951"
	-- }

	-- The table wordsOld contains the original words from the player, the table words are the same words but lowercase.
	-- It is the same with commandOld and command.
	-- If the player said any numbers (surrounded by a space and not part of a word), they are recorded in the table numbers.

	local function messageIRC()
		local playerName = chatvars.playername
		local cursor, errorString, row, k, v

		if chatvars.suppress then
			return true
		end

		if ircid then
			if players[ircid] then
				playerName = players[ircid].name
			end
		end

		if ircMsg ~= nil then
			-- ignore game messages

			-- replace Server: Botman: with just Botman:
			ircMsg = string.gsub(ircMsg, "Server: " .. server.botName .. ":", server.botName .. ":")

			if (chatvars.playername ~= "Server" and chatvars.playerid == nil) or string.find(ircMsg, " INF ") or string.find(ircMsg, "password") or string.find(ircMsg, "pass ") or string.find(string.lower(ircMsg), " api ") or string.find(ircMsg, "GMSG:", nil, true) then
				return true
			end

			-- replace Smegz0r: with Bot Master Smegz0r:  (just coz)
			ircMsg = string.gsub(ircMsg, "Smegz0r:", "Bot Master Smegz0r:")

			if string.find(ircMsg, "Server:") and playerName ~= "Server" then
				ircMsg = string.gsub(ircMsg, "Server:", playerName .. ":")
			end

			if string.find(ircMsg, server.botName .. ":", nil, true) and playerName ~= "Server" then
				ircMsg = string.gsub(ircMsg, server.botName .. ":", playerName .. ":")
			end

			-- replace Botman: Botman with just Botman
			ircMsg = string.gsub(ircMsg, server.botName .. ": " .. server.botName .. " ", server.botName .. " ")


			-- send the chat line to the IRC server (The Lounge)
			irc_chat(server.ircMain, ircMsg)

			if displayChatInMudlet then
				windowMessage(server.windowGMSG, playerName .. ": " .. chatvars.command .. "\n", true)
			end

			-- botman.webdavFolderWriteable is set to true every hour. We skip it if false the rest of the time as it causes some code to stop early if it doesn't have write permissions.
			if botman.webdavFolderWriteable then
				logChat(botman.serverTime, ircMsg)

				if (string.sub(chatvars.command, 1, 1) == server.commandPrefix) then
					logCommand(botman.serverTime, ircMsg)
				end
			end
		end
	end
	-- END OF local function messageIRC()

	-- Code of function gmsg(line, ircid) starts here
	if debug then
		dbug("line " .. line)

		if ircid ~= nil then
			if debug then dbug("ircid " .. ircid) end
		end
	end

	noWaypoint = false
	chatStringStart = ""
	chatvars = {}
	chatvars.restrictedCommand = false
	chatvars.timestamp = os.time()
	botman.ExceptionCount = 0
	chatvars.oldLine = line
	chatvars.playerid = "0"
	chatvars.gameid = 0
	chatvars.command = line
	chatvars.nonBotCommand = false
	chatvars.ircAlias = ""
	chatvars.helpRead = false
	chatvars.chatPublic = true
	chatvars.inLocation = ""
	chatvars.suppress = false
	chatvars.isAdmin = false
	chatvars.isAdminHidden = false -- used by /test as player, and /play as player
	chatvars.adminLevel = 100000
	chatvars.accessLevel = 99
	chatvars.ircid = "0"
	chatvars.userID = ""
	chatvars.platform = ""
	chatvars.commandOld = ""
	chatFlag = ""

	if not botman.chatHandler then
		botman.chatHandler = "Server"
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not server.gameVersionNumber and server.gameVersion then
		temp = string.split(server.gameVersion, " ")
		server.gameVersionNumber = tonumber(temp[2])
	end

	if not server.gameDate then
		server.gameDate	= ""
	end

	if server.gameVersionNumber and not ircid then -- skip if the chat is from irc
		tmp.line = line

		if string.find(line, "INF Chat ", nil, true) then
			pos = string.find(line, "INF Chat ", nil, true)
			tmp.line = string.sub(line, pos)
			tmp.chat = string.sub(tmp.line, string.find(tmp.line, "Chat (from ", nil, true) + 11)
		end

		if string.find(tmp.line, "INF Chatting colored", nil, true) then
			-- don't process this chat line
			return true
		end

		if string.find(tmp.line, "INF Chat handled by mod 'Botman':", nil, true) then
			botman.chatHandler = "Botman" -- Yay!
			tmp.temp = string.split(tmp.chat, ", ")
			tmp.playerID = stripAllQuotes(tmp.temp[1])
			tmp.temp = string.split(tmp.chat, ": ")
			tmp.command = tmp.temp[2]

			if not string.find(tmp.line, "Chat (from '-non-player-'", nil, true) then
				chatvars.playerid, chatvars.steamOwner, chatvars.userID, chatvars.platform = LookupPlayer(tmp.playerID, "all")
				chatvars.playername = players[chatvars.playerid].name
			else
				chatvars.playername = "Server"
			end
		end

		if string.find(tmp.line, "INF Chat (from ", nil, true) and (botman.chatHandler == "Server" or not tmp.playerID) then
			if server.gameVersion == "V 1.0 (b316)" then
				tmp.temp = string.split(tmp.chat, ", ")
				tmp.playerID = stripAllQuotes(tmp.temp[1])
			else
				tmp.temp = string.split(tmp.chat, ":")
				tmp.temp = string.split(tmp.temp[1], ",")
				tmp.playerID = stripAllQuotes(tmp.temp[1])
			end

			if not string.find(tmp.line, "Chat (from '-non-player-'", nil, true) then
				chatvars.playerid, chatvars.steamOwner, chatvars.userID, chatvars.platform = LookupPlayer(tmp.playerID, "all")
				chatvars.playername = players[chatvars.playerid].name
			else
				chatvars.playername = "Server"
			end
		end

		if string.find(tmp.line, "'Global'): ", nil, true) then
			-- this chat is just chat
			msg = string.sub(tmp.line, string.find(tmp.line, "'Global'): ", nil, true) + 11)
			chatvars.command = msg

			if chatvars.playername == server.botName then
				chatvars.playername = "Server"
			end

			if string.find(tmp.line, "Chat (from '-non-player-'", nil, true) then
				chatvars.playername = "Server"
			end
		end

		if string.find(line, "'Global'): '", nil, true) then
			-- this chat is a command
			tmp.temp = string.sub(tmp.line, string.find(tmp.line, "'Global'): '", nil, true) + 11)
			tmp.split = string.split(tmp.temp, "':")
			chatvars.command = tmp.split[2]

			if chatvars.playername == server.botName then
				chatvars.playername = "Server"
			end

			if string.find(tmp.line, "Chat (from '-non-player-'", nil, true) then
				chatvars.playername = "Server"
			end

		end

		if string.find(tmp.line, "'Party'): ", nil, true) then
			chatvars.chatPublic = false
			chatFlag = "(P) "

			msg = string.sub(tmp.line, string.find(tmp.line, "'Party'): ", nil, true) + 10)
			chatvars.command = msg
		end

		if string.find(line, "'Friends'): ", nil, true) then
			chatvars.chatPublic = false
			chatFlag = "(F) "

			msg = string.sub(tmp.line, string.find(tmp.line, "'Friends'): ", nil, true) + 12)
			chatvars.command = msg
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if ircid then
		chatvars.playername = "Server"
		chatvars.ircid = ircid

		if ircid ~= "0" then
			chatvars.playerid = ircid
			chatvars.ircAlias = players[ircid].ircAlias
			chatvars.userID = players[ircid].userID
			chatvars.accessLevel = tonumber(accessLevel(chatvars.playerid, chatvars.userID))
		else
			chatvars.accessLevel = 0
			chatvars.isAdmin = true
			chatvars.adminLevel = 0
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "-irc:") then
		if string.find(line, "'Server': ") then
			msg = string.sub(line, string.find(line, "'Server': ") + 10)
		end

		if string.find(line, server.botName .. "': ", nil, true) then
			msg = string.sub(line, string.find(line, "'" .. server.botName .. "': ", nil, true) + 10)
		end

		temp = string.split(msg, ":")

		if temp[3] then
			chatvars.command = temp[2] .. ":" .. string.sub(msg, string.find(msg, temp[3], nil, true))
		else
			chatvars.command = temp[2]
		end

		temp[1] = string.gsub(temp[1], "Bot Master ", "")
		chatvars.playername = string.sub(temp[1], 1, string.len(temp[1]) - 4)
		chatvars.playerid, chatvars.steamOwner, chatvars.userID, chatvars.platform = LookupPlayer(chatvars.playername, "all")
		chatvars.playername = stripAllQuotes(chatvars.playername)

		if chatvars.playername == server.botName then
			chatvars.playername = "Server"
		end
	else
		if chatvars.playername ~= nil and chatvars.playerid == "0" then
			chatvars.playerid, chatvars.steamOwner, chatvars.userID, chatvars.platform = LookupPlayer(chatvars.playername, "all")
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	chatvars.command = string.trim(chatvars.command)

	if chatvars.playername == "" then
		chatvars.command = line
		chatvars.playername = "Server"
		line = "Server: " .. line
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (botman.faultyChat == nil) then botman.faultyChat = false end
	if (botman.faultyChat2 == nil) then botman.faultyChat2 = false end
	if botman.faultyChat2 then fixMissingStuff() end
	botman.faultyChat2 = true

	if (botman.faultyChat == true) then
		windowMessage(server.windowDebug, "!! Fault detected in Chat\n")
		windowMessage(server.windowDebug, faultyLine .. "\n")
		if (botman.faultyChatCommand ~= nil) then windowMessage(server.windowDebug, "!! Fault occurred in command: " .. botman.faultyChatCommand .. "\n") end
		botman.faultyChat = false
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	faultyLine = line
	botman.faultyChat = true

	if string.find(line, " command 'pm") and not string.find(line, "' from client") then
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	-- remove curly brackets
	chatvars.command = string.gsub(chatvars.command, "{", "")
	chatvars.command = string.gsub(chatvars.command, "}", "")

	chatvars.numbers = {}
	chatvars.words = {}
	chatvars.wordsOld = {}

	-- break the chat line into words
	for word in chatvars.command:gmatch("%S+") do
		table.insert(chatvars.words, string.lower(word))
		table.insert(chatvars.wordsOld, word)
	end

	-- break the chat line into numbers
	for word in string.gmatch (chatvars.command, " (-?\%d+)") do
		table.insert(chatvars.numbers, tonumber(word))
	end

	for word in string.gmatch (chatvars.command, "#(-?\%d+)") do
		table.insert(chatvars.numbers, tonumber(word))
	end

	chatvars.wordCount = tablelength(chatvars.words)
	chatvars.numberCount = tablelength(chatvars.numbers)
	chatvars.commandOld = chatvars.command
	chatvars.command = string.lower(string.trim(chatvars.command))

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (string.sub(chatvars.words[1], 1, 1) == server.commandPrefix) then
		chatvars.words[1] = string.sub(chatvars.words[1], 2, string.len(chatvars.words[1]))
		chatvars.wordsOld[1] = string.sub(chatvars.wordsOld[1], 2, string.len(chatvars.wordsOld[1]))
		chatvars.botCommand = true
	else
		chatvars.botCommand = false

		if not string.match(string.sub(chatvars.words[1], 1, 1), "(%w)") then
			chatvars.words[1] = string.sub(chatvars.words[1], 2, string.len(chatvars.words[1]))
			chatvars.wordsOld[1] = string.sub(chatvars.wordsOld[1], 2, string.len(chatvars.wordsOld[1]))
			chatvars.nonBotCommand = true

			if chatvars.playerid ~= "0" then
				igplayers[chatvars.playerid].tp = 1
				igplayers[chatvars.playerid].hackerTPScore = 0
				igplayers[chatvars.playerid].spawnPending = true
				igplayers[chatvars.playerid].lastTPTimestamp = os.time()
			end
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if string.find(line, " command 'pm") and string.find(line, "' from client") then
		msg = string.sub(line, string.find(line, "command 'pm") + 12, string.find(line, "' from client") - 1)
		id = string.sub(line, string.find(line, "from client ") + 12)

		chatvars.playerid, chatvars.steamOwner , chatvars.userID, chatvars.platform = LookupPlayer(id, "all")
		chatvars.playername = players[chatvars.playerid].name
		chatvars.gameid = players[chatvars.playerid].id
		chatvars.command = string.trim(msg)
		chatvars.accessLevel = tonumber(accessLevel(chatvars.playerid, chatvars.userID))

		ircMsg = server.gameDate .. " " .. chatFlag .. " " ..  chatvars.commandOld
	else
		if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if string.find(line, "from '-non-player-'", nil, true) and string.find(line, "entity id '-1'", nil, true) then
			chatvars.playername = "Server"
			botman.faultyChat = false
		end

		if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if not string.find(chatvars.command , "register help") then
			if string.len(chatvars.command) > 200 then
				temp = string.gsub(chatvars.playername, "%[[%/%!]-[^%[%]]-]", "") .. ": " .. string.sub(chatvars.commandOld, 1, 200)
				--temp = string.sub(chatvars.commandOld, 1, 200)
				temp = string.gsub(temp, "%[[%/%!]-[^%[%]]-]", "")
				ircMsg = server.gameDate .. " " .. chatFlag .. " " ..  temp

				if not players[chatvars.playerid].lastChatLine then
					messageIRC()
				else
					if chatvars.commandOld ~= players[chatvars.playerid].lastChatLine then
						messageIRC()
					end
				end

				temp = string.sub(chatvars.commandOld, 201)
				temp = string.gsub(temp, "%[[%/%!]-[^%[%]]-]", "")
				ircMsg = server.gameDate .. " " .. chatFlag .. " " ..  temp
			else
				if not string.find(chatvars.command, server.commandPrefix .. "accept") and not string.find(chatvars.command, server.commandPrefix .. "poke") then
					temp = string.gsub(chatvars.playername, "%[[%/%!]-[^%[%]]-]", "") .. ": " .. string.gsub(chatvars.commandOld, "%[[%/%!]-[^%[%]]-]", "")
					ircMsg = server.gameDate .. " " .. chatFlag .. " " ..  temp
				end
			end
		else
			chatvars.playername = "Server"
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	botman.faultyChatCommand = chatvars.command

	if debug then
		windowMessage(server.windowDebug, "chatvars.playername " .. chatvars.playername .. "\n")
		windowMessage(server.windowDebug, "command " .. chatvars.command .. "\n")
	end

	-- ignore game messages
	if (chatvars.playername ~= "Server") and chatvars.playerid == nil then
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if chatvars.playerid == "0" and chatvars.ircid == "0" then
			-- usually this is a message from the server such as player left the game.  Ignore it and stop processing the line here.
			botman.faultyChat = false
			result = true
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.playerid~= "0" then
			chatvars.inLocation = players[chatvars.playerid].inLocation

			if (players[chatvars.playerid].lastCommand) then
				-- don't allow identical commands being spammed too quickly
				if (os.time() - players[chatvars.playerid].lastCommandTimestamp) < 2 then
					botman.faultyChat = false
					result = true
					return true
				end
			end
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if igplayers[chatvars.playerid] then
			igplayers[chatvars.playerid].afk = os.time() + tonumber(server.idleKickTimer)
			chatvars.intX = igplayers[chatvars.playerid].xPos
			chatvars.intY = igplayers[chatvars.playerid].yPos
			chatvars.intZ = igplayers[chatvars.playerid].zPos
			chatvars.accessLevel = tonumber(accessLevel(chatvars.playerid, chatvars.userID))
			x = math.floor(chatvars.intX / 512)
			z = math.floor(chatvars.intZ / 512)
			chatvars.region = "r." .. x .. "." .. z .. ".7rg"
			zombies = tonumber(igplayers[chatvars.playerid].zombies)
			chatvars.zombies = zombies
		end

		if chatvars.playerid ~= "0" then
			if players[chatvars.playerid].block then
				botman.faultyChat = false
				result = true
				return true
			end
		end
	else
		-- Don't let naughty players pretend to be Server. There can be only one ^.^
		if chatvars.playerid == "0" then
			chatvars.accessLevel = 0
			chatvars.isAdmin = true
			chatvars.adminLevel = 0
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	chatvars.isAdmin, chatvars.adminLevel = isAdmin(chatvars.playerid, chatvars.userID)
	chatvars.isAdminHidden, chatvars.adminLevel = isAdminHidden(chatvars.playerid, chatvars.userID)

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	-- is player a donor?
	if isDonor(chatvars.ircid) then
		chatvars.isDonor = true
	else
		if isDonor(chatvars.playerid) then
			chatvars.isDonor = true
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	chatvars.settings = getSettings(chatvars.playerid)

	if chatvars.settings.accessLevel then
		if tonumber(chatvars.settings.accessLevel) < tonumber(chatvars.accessLevel) then
			chatvars.accessLevel = chatvars.settings.accessLevel
		end
	end

	if chatvars.userID == "" and chatvars.playername ~= "Server" then
		chatvars.userID = LookupJoiningPlayer(chatvars.playerid)

		if chatvars.userID then
			if chatvars.userID ~= "" then
				players[chatvars.playerid].userID = chatvars.userID
				igplayers[chatvars.playerid].userID = chatvars.userID
			end
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	chatvars.number = tonumber(string.match(chatvars.command, " (-?%d+)"))

	if chatvars.number == nil then
		chatvars.number = tonumber(string.match(chatvars.command, "#(-?%d+)"))
	end

	if ircid ~= nil then
		if ((chatvars.words[1] == "command" or chatvars.words[1] == "list") and chatvars.words[2] == "help" or chatvars.words[1] == "help") then
			chatvars.showHelp = true
		end

		if chatvars.words[1] == "help" and chatvars.words[2] == "sections" then
			chatvars.showHelpSections = true
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if ircMsg ~= nil then
		if not igplayers[chatvars.playerid] then
			messageIRC()
		else
			if not players[chatvars.playerid].lastChatLine then
				messageIRC()
			else
				if chatvars.commandOld ~= players[chatvars.playerid].lastChatLine then
					messageIRC()
				end
			end
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	-- don't process any chat coming from irc or death messages
	if string.find(chatvars.oldLine, "-irc:", nil, true) or (chatvars.playername == "Server" and (string.find(chatvars.oldLine, "died") or string.find(chatvars.oldLine, "eliminated"))) then
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not result and (chatvars.playername ~= "Server") then
		if players[chatvars.playerid].lastCommand ~= nil then
			if chatvars.command == server.commandPrefix then
				players[chatvars.playerid].lastCommandTimestamp = os.time() - 10
				gmsg(players[chatvars.playerid].lastChatLine)
				return true
			end

			if (string.find(chatvars.command, server.commandPrefix .. "again") and chatvars.words[3] == nil) or (chatvars.command == server.commandPrefix .. " north") or (chatvars.command == server.commandPrefix .. " south") or (chatvars.command == server.commandPrefix .. " east") or (chatvars.command == server.commandPrefix .. " west") or (chatvars.command == server.commandPrefix .. " up") or (chatvars.command == server.commandPrefix .. " down") then
				if string.find(chatvars.command, "north") then
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("south", "north")
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("east", "north")
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("west", "north")
				end

				if string.find(chatvars.command, "south") then
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("north", "south")
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("east", "south")
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("west", "south")
				end

				if string.find(chatvars.command, "east") then
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("north", "east")
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("south", "east")
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("west", "east")
				end

				if string.find(chatvars.command, "west") then
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("north", "west")
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("east", "west")
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("south", "west")
				end

				if string.find(chatvars.command, "up") then
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("down", "up")
				end

				if string.find(chatvars.command, "down") then
					players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine:gsub("up", "down") -- and shake it all about
				end

				players[chatvars.playerid].lastChatLineTimestamp = os.time() - 10
				gmsg(players[chatvars.playerid].lastChatLine)
				return true
			else
				players[chatvars.playerid].lastChatLine = chatvars.commandOld
			end
		else
			players[chatvars.playerid].lastChatLine = chatvars.commandOld
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if chatvars.playername ~= "Server" then
		players[chatvars.playerid].lastCommandTimestamp = os.time()

		if (string.sub(chatvars.command, 1, 1) == server.commandPrefix) or chatvars.nonBotCommand then
			if chatvars.command ~= server.commandPrefix .. "undo" then -- don't record undo so we can repeat the previous command if we want to.
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
			end

			if not chatvars.nonBotCommand then
				if players[chatvars.playerid].commandCooldown == 0 or (os.time() - players[chatvars.playerid].commandCooldown >= server.commandCooldown) then
					players[chatvars.playerid].commandCooldown = os.time()
				else
					if not chatvars.isAdminHidden then
						-- warn the player once about the command cooldown after that silently ignore the command if its spammed too soon.
						if not igplayers[chatvars.playerid].commandSpamAlert then
							igplayers[chatvars.playerid].commandSpamAlert = true
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You can do 1 command every " .. server.commandCooldown .. " seconds. To repeat your last command just type " .. server.commandPrefix .."[-]")
						end

						return true
					end
				end
			end
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not result then
		if chatvars.showHelp and not skipHelp then
			if (string.find(chatvars.command, "reload")) or chatvars.words[1] ~= "help" and chatvars.words[3] == nil then
				irc_chat(players[chatvars.ircid].ircAlias, " " .. server.commandPrefix .. "reload code")

				if not shortHelp then
					irc_chat(players[chatvars.ircid].ircAlias, "Tell the bot to reload all external Lua scripts.  This also happens shortly after restarting the bot and it can automatically detect if the scripts are not loaded and reload them.")
					irc_chat(players[chatvars.ircid].ircAlias, "Once the script have loaded, if you make any changes to them you need to run this command or restart the bot for your changes to take effect.")
					irc_chat(players[chatvars.ircid].ircAlias, ".")
				end
			end

			if (string.find(chatvars.command, "pause") or string.find(chatvars.command, "bot")) or chatvars.words[1] ~= "help" and chatvars.words[3] == nil then
				irc_chat(players[chatvars.ircid].ircAlias, " " .. server.commandPrefix .. "pause bot")

				if not shortHelp then
					irc_chat(players[chatvars.ircid].ircAlias, "Temporarily disable the bot.  It will still read the chat and can be enabled again.")
					irc_chat(players[chatvars.ircid].ircAlias, ".")
				end
			end
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if (chatvars.words[1] == "unpause" or chatvars.words[1] == "unpaws" or chatvars.words[1] == "enable") and chatvars.words[2] == "bot" and chatvars.words[3] == nil and chatvars.accessLevel == 0 then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot is no longer paused.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The bot is no longer paused.")
			end

			message("say [" .. server.warnColour .. "]The bot is now accepting commands again! :D[-]")
			botman.botDisabled = false
			server.botPaused = false
			conn:execute("UPDATE server SET botPaused = 0")

			if chatvars.playerid ~= "0" then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if (chatvars.words[1] == "pause" or chatvars.words[1] == "paws" or chatvars.words[1] == "disable") and chatvars.words[2] == "bot" and chatvars.words[3] == nil and chatvars.accessLevel == 0 then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.botName .. " is now paused.  Most commands are disabled. To unpause it type " .. server.commandPrefix .. "unpause bot.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, server.botName .. " is now paused.  Most commands are disabled. To unpause it type cmd " .. server.commandPrefix .. "unpause bot.")
			end

			message("say [" .. server.warnColour .. "] " .. server.botName .. " is now paused.  Most commands are disabled.[-]")
			irc_chat(server.ircMain, "The bot is now paused.  To unpause it type cmd " .. server.commandPrefix .. "unpause bot.")
			botman.botDisabled = true
			server.botPaused = true
			conn:execute("UPDATE server SET botPaused = 1")

			if chatvars.playerid ~= "0" then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.words[1] == "reload" and (string.find(chatvars.command, "cod") or string.find(chatvars.command, "script")) then
			if chatvars.playerid ~= "0" then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			if not string.find(chatvars.command, "code") then
				r = randSQL(4)

				if r == 1 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Something smells fishy.[-]") end
				if r == 2 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I smell something stinky! :D[-]") end
				if r == 3 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Cod again sir?[-]") end
				if r == 4 then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]FISH![-]") end
			end

			botman.faultyChat = false
			reloadCode()
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.words[1] == "reload" and chatvars.words[2] == "lua" and chatvars.words[3] ~= nil then
			-- command the bot to reload 1 specified lua script from disk.  Limited to the scripts folder.
			temp = string.sub(line, string.find(line, chatvars.wordsOld[2]) + 4, nil, true)
			temp = homedir .. "/scripts/" .. temp

			if not isFile(temp) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]That script does not exist or you have a typo.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "That script does not exist or you have a typo.")
				end

				botman.faultyChat = false
				return true
			end

			if string.find(temp, ".lua") then
				checkScript(temp)
			end

			botman.faultyChat = false
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.words[1] == "reload" and chatvars.words[2] == "custom" and chatvars.words[3] == "lua" and chatvars.words[4] ~= nil then
			-- command the bot to reload 1 specified lua script from disk.  Limited to the custom scripts folder.
			temp = string.sub(line, string.find(line, chatvars.wordsOld[3], nil, true) + 4)
			temp = homedir .. "/custom/" .. temp

			if not isFile(temp) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]That script does not exist or you have a typo.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "That script does not exist or you have a typo.")
				end

				botman.faultyChat = false
				return true
			end

			if string.find(temp, ".lua") then
				checkScript(temp)
			end

			botman.faultyChat = false
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if string.find(chatvars.command, "asmfreakz") then
			banPlayer(chatvars.platform, chatvars.userID, chatvars.playerid, "10 year", "advertising hacks", "")

			message("say [" .. server.chatColour .. "]Banning player " .. igplayers[chatvars.playerid].name .. " 10 years for advertising hacks.[-]")
			irc_chat(server.ircMain, "[BANNED] Player " .. chatvars.playerid .. " " .. igplayers[chatvars.playerid].name .. " has has been banned for advertising hacks.")
			irc_chat(server.ircAlerts, "[BANNED] Player " .. chatvars.playerid .. " " .. igplayers[chatvars.playerid].name .. " has has been banned for 10 years for advertising hacks.")
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','ban','Player " .. chatvars.playerid .. " " .. escape(igplayers[chatvars.playerid].name) .. " has has been banned for 10 years for advertising hacks.','" .. chatvars.playerid .. "')")

			-- if botman.botsConnected then
				-- -- copy in bots db
				-- connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','ban','Player " .. chatvars.playerid .. " " .. escape(igplayers[chatvars.playerid].name) .. " has has been banned for 10 years for advertising hacks.'," .. chatvars.playerid .. ")")
			-- end

			botman.faultyChat = false
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.words[1] == "reload" and chatvars.words[2] == "debug" then
			dofile(homedir .. "/scripts/debug.lua")

			if chatvars.playerid ~= "0" then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.words[1] == "register" and chatvars.words[2] == "help" then
			if botman.webdavFolderWriteable then
				file = io.open(botman.chatlogPath .. "/help/help.txt", "w")
				writeToFile(file, "Generated " .. os.date("%d %B, %Y at %H:%M",  os.time()))
				writeToFile(file, "")
				writeToFile(file, "This command help is taken directly from the bot. It is not a manual but you will learn a lot just exploring this text.")
				writeToFile(file, "Found a broken command? Need a command/function or feature added? Let me know. I fix stuff :D")
				writeToFile(file, "")
				file:close()
			end

			botman.registerHelp = true
			chatvars.showHelp = true
			chatvars.ircAlias = server.ircBotName

			if chatvars.playerid ~= "0" then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
		end
	end

	if chatvars.playerid ~= "0" then
		if players[chatvars.playerid] then
			chatvars.gameid = players[chatvars.playerid].id
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (debug) then
		display(chatvars)
	end

	if (chatvars.playername ~= "Server") then
		if not chatvars.botCommand then
			-- if the player chat contains bad words, deal with them and STOP RIGHT THERE CRIMINAL SCUM!
			if checkForBadWords() then
				botman.faultyChat = false
				return true
			end
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not string.find(line, "register help") then
		if debug then dbug("debug entering gmsg_custom") end
		result = gmsg_custom()

		if result then
			if debug then dbug("debug ran command in gmsg_custom") end
			return true
		end
	end

	-- If you want to override any commands in the sections below, create commands in gmsg_custom.lua or call them from within it making sure to match the commands keywords.

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if debug then dbug("debug entering gmsg_info") end
	result, func = gmsg_info()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_info") end
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if chatvars.words[1] == "hardcore" and chatvars.words[2] == "mode" and (chatvars.words[3] == "off" or chatvars.words[3] == "disable" or string.sub(chatvars.words[3], 1, 2) == "de") then
			players[chatvars.playerid].silentBob = false
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will help you.[-]")

			if chatvars.playerid ~= "0" then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			return true
		end

		if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.words[1] == "hardcore" and chatvars.words[2] == "mode" and (chatvars.words[3] == "on" or chatvars.words[3] == "enable" or chatvars.words[3] == "activate") then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will not help you.[-]")
			players[chatvars.playerid].silentBob = true

			if chatvars.playerid ~= "0" then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			return true
		end

		if players[chatvars.playerid].silentBob == true and not chatvars.isAdminHidden then
			result = true
			botman.faultyChat = false
			return true
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "restore" and chatvars.words[2] == "admin" then
		if chatvars.ircid ~= "0" then
			if botman.dbConnected then connSQL:execute("UPDATE persistentQueue SET timerDelay = " .. os.time() .. " WHERE steam = '" .. chatvars.ircid .. "'") end
		else
			if botman.dbConnected then connSQL:execute("UPDATE persistentQueue SET timerDelay = " .. os.time() .. " WHERE steam = '" .. chatvars.playerid .. "'") end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "fix" and chatvars.words[2] == "bot" and chatvars.words[3] == nil) or string.find(chatvars.command, "fix all the things") then
		if (chatvars.accessLevel > 1) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
			else
				if not chatvars.showHelp then
					irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				end
			end

			botman.faultyChat = false
			return true
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Fixing bot.  Please wait.. If this doesn't fix it, doing this again probably won't either.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Fixing bot.  Please wait.. If this doesn't fix it, doing this again probably won't either.")
		end

		if not botman.fixingBot then
			botman.fixingBot = true
			fixBot()
		end

		if chatvars.playerid ~= "0" then
			players[chatvars.playerid].lastCommand = chatvars.command
			players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
			players[chatvars.playerid].lastCommandTimestamp = os.time()
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if botman.botDisabled then
		if (chatvars.playername ~= "Server") then
			for i=1,chatvars.wordCount,1 do
				word = chatvars.words[i]
				if word == "bot" or word == "bot?" or word == "bot!" then
					if (chatvars.accessLevel > 0) then
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]The bot is currently disabled and not accepting most commands.[-]")
					else
						message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]The bot is currently disabled.  To enable it again type " .. server.commandPrefix .. "unpause bot[-]")
					end

					botman.faultyChat = false
					return true
				end
			end
		else
			if not chatvars.isAdminHidden then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot is currently disabled.  To enable it again type cmd " .. server.commandPrefix .. "unpause bot")
				botman.faultyChat = false
				return true
			end
		end

		botman.faultyChat = false
		return true
	end

	if debug then
		dbug("debug command " .. chatvars.commandOld)
		dbug("debug from " .. chatvars.playerid .. " " .. chatvars.playername)
	end

	if debug then dbug("debug entering gmsg_unslashed") end
	result, func = gmsg_unslashed()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_unslashed") end
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if debug then dbug("debug entering gmsg_base") end
	result, func = gmsg_base()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_base") end
		return true
	end

	if debug then dbug("debug entering gmsg_locations") end
	result, func = gmsg_locations()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_locations") end
		return true
	end

	if debug then dbug("debug entering gmsg_teleports") end
	result, func = gmsg_teleports()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_teleports") end
		return true
	end

	if debug then dbug("debug entering gmsg_waypoints") end
	result, func = gmsg_waypoints()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_waypoints") end
		return true
	end

	if debug then dbug("debug entering gmsg_shop") end
	result, func = gmsg_shop()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_shop") end
		return true
	end

	if debug then dbug("debug entering gmsg_misc") end
	result, func = gmsg_misc()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_misc") end
		return true
	end

	if debug then dbug("debug entering gmsg_mail") end
	result, func = gmsg_mail()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_mail") end
		return true
	end

	if debug then dbug("debug entering gmsg_hotspots") end
	result, func = gmsg_hotspots()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_hotspots") end
		return true
	end

	if debug then dbug("debug entering gmsg_friends") end
	result, func = gmsg_friends()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_friends") end
		return true
	end

	if debug then dbug("debug entering gmsg_villages") end
	result, func = gmsg_villages()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_villages") end
		return true
	end

	if debug then dbug("debug entering gmsg_bot") end
	result, func = gmsg_bot()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_bot") end
		return true
	end

	if debug then dbug("debug entering gmsg_fun") end
	result, func = gmsg_fun()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_fun") end
		return true
	end

	if debug then dbug("debug entering gmsg_admin") end
	result, func = gmsg_admin()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_admin") end
		return true
	end

	if debug then dbug("debug entering gmsg_resets") end
	result, func = gmsg_resets()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_resets") end
		return true
	end

	if debug then dbug("debug entering gmsg_tracker") end
	result, func = gmsg_tracker()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_tracker") end
		return true
	end

	if debug then dbug("debug entering gmsg_server") end
	result, func = gmsg_server()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_server") end
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	--if server.botman then
		if debug then dbug("debug entering gmsg_botman") end
		result, func = gmsg_botman()

		if result then
			if debug then dbug("debug ran command " .. func .. " in gmsg_botman") end
			return true
		end
	--end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if debug then dbug("debug entering gmsg_groups") end
	result, func = gmsg_groups()

	if result then
		if debug then dbug("debug ran command " .. func .. " in gmsg_groups") end
		return true
	end

	if debug then dbug("debug entering gmsg_trial_code") end
	result = gmsg_trial_code()

	if result then
		if debug then dbug("debug ran command in gmsg_trial_code") end
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not chatvars.restrictedCommand then
		if igplayers[chatvars.playerid] then
			igplayers[chatvars.playerid].restrictedCommand = false
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if result then
		-- a command matched and was executed so stop processing it
		botman.faultyChat = false
		botman.faultyChat2 = false
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if botman.registerHelp then
		irc_params = {}
		irc_params.name = server.ircBotName .. generatePassword(10)
		IRCMessage("sysIrcMessage", irc_params.name, irc_params.name, "help")
		irc_HelpAccess()
		irc_HelpServer()
		irc_HelpCSI()
		irc_HelpAnnouncements()
		irc_HelpCustomCommands()
		irc_HelpBadItems()
		irc_HelpCommands()
		irc_HelpMOTD()
		irc_HelpWatchlist()
		irc_HelpShop()
		irc_HelpTopics()
		irc_chat(irc_params.name, "== END OF COMMAND HELP ==")
		botman.registerHelp = nil
		tempTimer( 1, [[loadHelpCommands()]] )

		botman.faultyChat = false
		return true
	end

	if chatvars.words[1] == "register" and chatvars.words[2] == "help" then
		result = true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	-- these commands are defined here just so the bot won't say unknown command when it sees them
	-- ignore these commands.  don't process them.  these are not the commands you are looking for. move along. move along.
	if string.find(chatvars.command, "clan") then
		botman.faultyChat = false
		return true
	end

	if (chatvars.words[1] == "bag" and chatvars.words[2] == nil) then
		botman.faultyChat = false
		return true
	end

	if (chatvars.words[1] == "helpme") then -- O-B-1
		-- you're my only hope
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not result then
		if (string.sub(chatvars.command, 1, 1) == server.commandPrefix) and not server.hideUnknownCommand then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Unknown command: " .. chatvars.command .. " Type " .. server.commandPrefix .. "help or " .. server.commandPrefix .. "commands for commands.[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]To teleport to a friend use {#}visit eg. {#}visit joe[-]")
			else
				if not chatvars.showHelp then
					irc_chat(players[chatvars.ircid].ircAlias, "Unknown command")
				end
			end
		else
			Translate(chatvars.playerid, chatvars.command, "")
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	botman.faultyChat = false
	botman.faultyChat2 = false

	if chatvars.playerid ~= "0" then
		if chatvars.ircid == "0" and players[chatvars.playerid].botQuestion then
			-- make the bot forget questions so we don't have it randomly react later on unexpectedly >.<
			if players[chatvars.playerid].botQuestion ~= "" then
				if string.find(players[chatvars.playerid].botQuestion, "reset") and not string.find(chatvars.command, "reset") then
					players[chatvars.playerid].botQuestion = ""
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Reset cancelled.[-]")
				end
			end
		end
	end

	if debug then dbug("debug gmsg end") end

	if chatvars.helpRead then
		return true
	else
		return false
	end
end
