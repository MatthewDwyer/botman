--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug, result, x, z, id, pname, noWaypoint, temp, chatStringStart, cmd, msg, test, ircMsg, chatFlag

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false -- should be false unless testing

function day7(steam)
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
				message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes will run tonight![-]")
			else
				message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes may run tonight![-]")
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
				message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected tomorrow![-]")
			else
				message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes could arrive tomorrow![-]")
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
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "2 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "2 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 3) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "3 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "3 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 4) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "4 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "4 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 5) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "5 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "5 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 6) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "6 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "6 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 7) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "7 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "7 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 8) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "8 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "8 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 9) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "9 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "9 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 10) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "10 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "10 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 11) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "11 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "11 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 12) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "12 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "12 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 13) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "13 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "13 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 14) % server.hordeNight == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "14 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in" .. warning .. "14 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if steam ~= nil then
		message("pm " .. steam .. " [" .. server.chatColour .. "]Relax. The next feral horde is ages away.[-]")
	else
		message("say [" .. server.chatColour .. "]Relax. The next feral horde is ages away.[-]")
	end

	botman.faultyChat = false
	return true
end


function nextReboot(steam)
	local timeRemaining, diff, days, hours, minutes, seconds, strDays, strHours, strMinutes

	if not server.allowReboot then
		if steam == nil then
			message("say [" .. server.chatColour .. "]Server reboots are not managed by me at the moment.[-]")
		else
			if igplayers[steam] then
				message("pm " .. steam .. " [" .. server.chatColour .. "]Server reboots are not managed by me at the moment.[-]")
			end

			irc_chat(players[steam].ircAlias, "Server reboots are not managed by me at the moment.")
		end

		return
	end

	if botman.scheduledRestartTimestamp == nil then
		botman.scheduledRestartTimestamp = os.time()
	end

	if tonumber(server.uptime) < 0 then
		if steam == nil then
			message("say [" .. server.chatColour .. "]The server needs a reboot now to fix a fault.[-]")
		else
			if igplayers[steam] then
				message("pm " .. steam .. " [" .. server.chatColour .. "]The server needs a reboot now to fix a fault.[-]")
			end

			irc_chat(players[steam].ircAlias, "The server needs a reboot now to fix a fault.")
		end
	else
		if botman.scheduledRestartTimestamp > os.time() or botman.scheduledRestartPaused then
			if botman.scheduledRestartPaused then
				timeRemaining = restartTimeRemaining
			else
				timeRemaining = botman.scheduledRestartTimestamp - os.time()
			end
		else
			timeRemaining = (tonumber(server.maxServerUptime) * 3600) - server.uptime + 900
		end

		diff = timeRemaining
		days = math.floor(diff / 86400)

		if (days > 0) then
			diff = diff - (days * 86400)
		end

		hours = math.floor(diff / 3600)

		if (hours > 0) then
			diff = diff - (hours * 3600)
		end

		minutes = math.floor(diff / 60)

		if (minutes > 0) then
			seconds = diff - (minutes * 60)
		end

		if botman.scheduledRestartPaused then
			if steam == nil then
				message("say [" .. server.chatColour .. "]The reboot is paused at the moment. When it is resumed, the reboot will happen in " .. string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) ..":" .. string.format("%02d", seconds) .. "[-]")
			else
				if igplayers[steam] then
					message("pm " .. steam .. " [" .. server.chatColour .. "]The reboot is paused at the moment. When it is resumed, the reboot will happen in " .. string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) ..":" .. string.format("%02d", seconds) .. "[-]")
				end

				irc_chat(players[steam].ircAlias, "The reboot is paused at the moment. When it is resumed, the reboot will happen in " .. string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) ..":" .. string.format("%02d", seconds))
			end
		else
			if (server.gameDay % server.hordeNight == 0) then
				if steam == nil then
					message("say [" .. server.chatColour .. "]Feral hordes run today so the server will reboot tomorrow.[-]")
				else
					if igplayers[steam] then
						message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes run today so the server will reboot tomorrow.[-]")
					end

					irc_chat(players[steam].ircAlias, "Feral hordes run today so the server will reboot tomorrow.")
				end
			else
				strDays = "days"
				if days == 1 then strDays = "day" end

				strHours = "hours"
				if hours == 1 then strHours = "hour" end

				strMinutes = "minutes"
				if minutes == 1 then strMinutes = "minute" end

				if steam == nil then
					if days > 0 then
						message("say [" .. server.chatColour .. "]The next reboot is in " .. days .. " " .. strDays .. " " .. hours .. " " .. strHours .. " and " .. minutes .. " " .. strMinutes .. "[-]")
					else
						if hours > 0 then
							message("say [" .. server.chatColour .. "]The next reboot is in " .. hours .. " " .. strHours .. " and " .. minutes .. " " .. strMinutes .. "[-]")
						else
							message("say [" .. server.chatColour .. "]The next reboot is in " .. minutes .. " " .. strMinutes .. "[-]")
						end
					end
				else
					if igplayers[steam] then
						if days > 0 then
							message("pm " .. steam .. " [" .. server.chatColour .. "]The next reboot is in " .. days .. " " .. strDays .. " " .. hours .. " " .. strHours .. " and " .. minutes .. " " .. strMinutes .. "[-]")
						else
							if hours > 0 then
								message("pm " .. steam .. " [" .. server.chatColour .. "]The next reboot is in " .. hours .. " " .. strHours .. " and " .. minutes .. " " .. strMinutes .. "[-]")
							else
								message("pm " .. steam .. " [" .. server.chatColour .. "]The next reboot is in " .. minutes .. " " .. strMinutes .. "[-]")
							end
						end
					end

					irc_chat(players[steam].ircAlias, "The next reboot is in " .. days .. " days " .. string.format("%02d", hours) .. " hours and " .. string.format("%02d", minutes) .." minutes")
				end
			end
		end
	end
end


function baseStatus(command, playerid)
	local pname, id, protected, base

	pname = nil
	if (accessLevel(playerid) < 3 and string.find(command, "status ")) then
		pname = string.sub(command, string.find(command, "status") + 7)
		if (pname ~= nil) then
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if id == 0 then
					message("pm " .. playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
				else
					message("pm " .. playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived and their base(s) are not active.[-]")
				end

				return false
			end
		end
	end

	if (pname == nil) then
		id = playerid
		pname = players[playerid].name
	else
		pname = players[id].name
	end

	message("pm " .. playerid .. " [" .. server.chatColour .. "]You have " .. string.format("%d", players[id].cash) .. " " .. server.moneyPlural .. " in the bank.[-]")

	if (players[id].protect == true) then
		protected = "protected"
	else
		protected = "not protected (unless you have LCB's down)"
	end

	if (players[id].homeX == 0 and players[id].homeY == 0 and players[id].homeZ == 0) then
		if (id == playerid) then
			base = "You do not have a base set yet"
		else
			base = pname .. " does not have a base set yet"
		end
	else
		if (id == playerid) then
			base = "You have set a base"
		else
			base = pname .. " has set a base"
		end
	end

	message("pm " .. playerid .. " [" .. server.chatColour .. "]" .. base .. "[-]")
	message("pm " .. playerid .. " [" .. server.chatColour .. "]The base is " .. protected .. "[-]")
	message("pm " .. playerid .. " [" .. server.chatColour .. "]Protection size is " .. players[id].protectSize .. " meters from the " .. server.commandPrefix .. "base teleport[-]")

	if (players[id].protectPaused ~= nil) then
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Base protection is temporarily paused.[-]")
	end

	if not (players[id].home2X == 0 and players[id].home2Y == 0 and players[id].home2Z == 0) then
		if (players[id].protect2 == true) then
			protected = "protected"
		else
			protected = "not protected (unless LCB's are placed)"
		end

		if (id == playerid) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]Your 2nd base status is..[-]")
		else
			message("pm " .. playerid .. " [" .. server.chatColour .. "]Base status for " .. pname .. "'s 2nd base is..[-]")
		end

		message("pm " .. playerid .. " [" .. server.chatColour .. "]The base is " .. protected .. "[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Protection size is " .. players[id].protect2Size .. " meters from the " .. server.commandPrefix .. "base2 teleport[-]")

		if (players[id].protect2Paused ~= nil) then
			message("pm " .. playerid .. " [" .. server.chatColour .. "]Base protection is temporarily paused.[-]")
		end
	end

	if accessLevel(playerid) < 3 then
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Current session is " .. players[id].sessionCount .. "[-]")
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Claims placed " .. players[id].keystones .. "[-]")
	end

	return false
end


function gmsg_who(playerid, number)
	local xdir, zdir, k, v, dist, alone, intX, intY, intZ, x, z

	intX = igplayers[playerid].xPos
	intY = igplayers[playerid].yPos
	intZ = igplayers[playerid].zPos

	x = math.floor(intX / 512)
	z = math.floor(intZ / 512)

	alone = true

	if (number == nil) then number = 501 end

	if (accessLevel(playerid) > 3) then
		number = 401
	end

	if (accessLevel(playerid) > 10) then
		number = 201
	end

	if (tonumber(intX) < 0) then xdir = " west " else xdir = " east " end
	if (tonumber(intZ) < 0) then zdir = " south" else zdir = " north" end

	message("pm " .. playerid .. " [" .. server.chatColour .. "]You are at " .. intX .. xdir .. intZ .. zdir .. " at a height of " .. intY .. "[-]")
	message("pm " .. playerid .. " [" .. server.chatColour .. "]You are in region r." .. x .. " " .. z .. ".7rg[-]")

	if (pvpZone(igplayers[playerid].xPos, igplayers[playerid].zPos) ~= false) and chatvars.accessLevel > 2 then
		return
	end

	for k, v in pairs(igplayers) do
		if (k ~= playerid) then
			dist = distancexz(intX, intZ, v.xPos, v.zPos)

			if dist < tonumber(number) then
				if (v.steam ~= playerid) then
					if (alone == true) then
						message("pm " .. playerid .. " [" .. server.chatColour .. "]players within " .. number .. " meters:[-]")
						alone = false
					end

					if (accessLevel(playerid) < 11) then
						x = math.floor(v.xPos / 512)
						z = math.floor(v.zPos / 512)

						message("pm " .. playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%d", dist) .. " region r." .. x .. "." .. z .. ".7rg Hacker score: " .. players[k].hackerScore .. "[-]")
					else
						if (players[playerid].watchPlayer == true) and accessLevel(v.steam) > 3 then
							message("pm " .. playerid .. " [" .. server.chatColour .. "]" .. v.name .. "[-]")
						end

						if (players[playerid].watchPlayer == false) then
							message("pm " .. playerid .. " [" .. server.chatColour .. "]" .. v.name .. "[-]")
						end
					end
				end
			end
		end
	end
end


function logAlerts(alertTime, alertLine)
	local file

	-- don't log base protection alerts
	if botman.webdavFolderWriteable == false or string.find(alertLine, "base protection") then
		return
	end

	-- flag the webdav folder as not writeable.  If the code below succeeds, we'll flag it as writeable so we can skip writing the chat log next time around.
	-- If we can't write the log and we keep trying to, the bot won't be able to respond to any commands since we're writing to the log before processing the chat much.
	botman.webdavFolderWriteable = false

	-- log the chat
	file = io.open(botman.chatlogPath .. "/" .. os.date("%Y%m%d") .. "_alertlog.txt", "a")
	file:write(alertTime .. "; " .. string.trim(alertLine) .. "\n")
	file:close()

	botman.webdavFolderWriteable = true
end


function logBotCommand(commandTime, commandLine)
	local file

	if botman.webdavFolderWriteable == false or string.find(commandLine, "password") or string.find(commandLine, "invite code") or string.find(commandLine, "webtokens") or string.find(string.lower(commandLine), " api ") then
		return
	end

	if string.find(commandLine, "adminuser") then
		commandLine = string.sub(commandLine, 1, string.find(commandLine, "adminuser") - 2)
	end

	-- flag the webdav folder as not writeable.  If the code below succeeds, we'll flag it as writeable so we can skip writing the chat log next time around.
	-- If we can't write the log and we keep trying to, the bot won't be able to respond to any commands since we're writing to the log before processing the chat much.
	botman.webdavFolderWriteable = false

	-- log the chat
	file = io.open(botman.chatlogPath .. "/" .. os.date("%Y%m%d") .. "_botcommandlog.txt", "a")
	file:write(commandTime .. "; " .. string.trim(commandLine) .. "\n")
	file:close()

	botman.webdavFolderWriteable = true
end


function logCommand(commandTime, commandLine)
	local commandPosition, file
	local playerName = chatvars.playername

	commandPosition = "0 0 0"

	if tonumber(chatvars.ircid) > 0 then
		playerName = players[chatvars.ircid].name
	else
		if chatvars.intX then
			commandPosition = chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ
		end
	end

	if botman.webdavFolderWriteable == false or string.find(commandLine, " INF ") or string.find(commandLine, "' from client") or string.find(commandLine, "password") or string.find(string.lower(commandLine), " api ") then
		return
	end

	-- flag the webdav folder as not writeable.  If the code below succeeds, we'll flag it as writeable so we can skip writing the chat log next time around.
	-- If we can't write the log and we keep trying to, the bot won't be able to respond to any commands since we're writing to the log before processing the chat much.
	botman.webdavFolderWriteable = false

	-- log the chat
	file = io.open(botman.chatlogPath .. "/" .. os.date("%Y%m%d") .. "_commandlog.txt", "a")
	file:write(commandTime .. "; " .. playerName .. "; " .. commandPosition .. "; " .. string.trim(commandLine) .. "\n")
	file:close()

	botman.webdavFolderWriteable = true
end


function logChat(chatTime, chatLine)
	local chatPosition, file
	local playerName = chatvars.playername

	if chatvars == nil or string.trim(chatLine) == "Server" then
		return
	end

	chatPosition = "0 0 0"

	if tonumber(chatvars.ircid) > 0 then
		playerName = players[chatvars.ircid].name
	else
		if chatvars.intX then
			chatPosition = chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ
		end
	end

	if (not botman.webdavFolderWriteable) or string.find(chatLine, " INF ") or string.find(chatLine, "' from client") or string.find(chatLine, "password") or string.find(string.lower(chatLine), " api ") then
		return
	end

	-- flag the webdav folder as not writeable.  If the code below succeeds, we'll flag it as writeable so we can skip writing the chat log next time around.
	-- If we can't write the log and we keep trying to, the bot won't be able to respond to any commands since we're writing to the log before processing the chat much.
	botman.webdavFolderWriteable = false

	-- log the chat
	file = io.open(botman.chatlogPath .. "/" .. os.date("%Y%m%d") .. "_chatlog.txt", "a")
	file:write(chatTime .. "; " .. playerName .. "; " .. chatPosition .. "; " .. string.trim(chatLine) .. "\n")
	file:close()

	botman.webdavFolderWriteable = true
end


function logInventoryChanges(steam, item, delta, x, y, z, session, flag)
	local file, location

	-- flag the webdav folder as not writeable.  If the code below succeeds, we'll flag it as writeable so we can skip writing the chat log next time around.
	-- If we can't write the log and we keep trying to, the bot won't be able to respond to any commands since we're writing to the log before processing the chat much.
	botman.webdavFolderWriteable = false
	location = ""

	if igplayers[steam] then
		location = igplayers[steam].inLocation
	end

	-- log the chat
	file = io.open(botman.chatlogPath .. "/" .. os.date("%Y%m%d") .. "_inventory.txt", "a")
	if delta > 0 then
		file:write("server date " .. botman.serverTime .. "; game " .. server.gameDate .. "; " .. steam .. "; " .. players[steam].name .. "; " .. item .. "; qty +" .. delta .. "; xyz " .. x .. " " .. y .. " " .. z .. " ; loc " .. location .. " ; sess " .. session .. "; " .. flag .. "\n")
	else
		file:write("server date " .. botman.serverTime .. "; game " .. server.gameDate .. "; " .. steam .. "; " .. players[steam].name .. "; " .. item .. "; qty " .. delta .. "; xyz " .. x .. " " .. y .. " " .. z .. " ; loc " .. location .. " ; sess " .. session .. "; " .. flag .. "\n")
	end

	file:close()

	botman.webdavFolderWriteable = true
end


function gmsg(line, ircid)
	local pos

	result = false

	if botman.debugAll then
		debug = true -- this should be true
	end

	if not server.gameVersionNumber then
		sendCommand("version")
	end

	-- Hi there! ^^  Welcome to the function that parses player chat.  It builds a lua table called chatvars filled with lots of info
	-- about the current line of player chat.  This fuction essentially pre-processes the line so that later code that chatvars is passed to
	-- doesn't have to do much more to it other than try to match trigger words.  Player chat gets the bot triggered. xD

	-- here is an example of a chat line and the resulting chatvars table:

	-- 2017-10-26T06:14:38 5760.786 INF Chat: 'Smegz0r': /tp 5000 -1 5000"line 2017-10-26T06:14:38 5760.786 INF Chat: 'Smegz0r': /tp 5000 -1 5000"

	-- {
	  -- number = 5000,
	  -- intY = 17,
	  -- commandOld = "/tp 5000 -1 5000",
	  -- numberCount = 3,
	  -- intZ = 1988,
	  -- restrictedCommand = false,
	  -- wordsOld = {
		-- "/tp",
		-- "5000",
		-- "-1",
		-- "5000"
	  -- },
	  -- command = "/tp 5000 -1 5000",
	  -- playername = "Smegz0r",
	  -- oldLine = "2017-10-26T06:14:38 5760.786 INF Chat: 'Smegz0r': /tp 5000 -1 5000",
	  -- words = {
		-- "tp",
		-- "5000",
		-- "-1",
		-- "5000"
	  -- },
	  -- region = "r.0.3.7",
	  -- wordCount = 4,
	  -- accessLevel = 0,
	  -- intX = 197,
	  -- numbers = {
		-- "5000",
		-- "-1",
		-- "5000"
	  -- },
	  -- timestamp = 1509016769,
	  -- zombies = 0,
	  -- playerid = "76561197983251951"
	-- }

	-- The table wordsOld contains the original words from the player, the table words are the same words but lowercase.
	-- It is the same with commandOld and command.
	-- If the player said any numbers (surrounded by a space and not part of a word), they are recorded in the table numbers.


	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	local function messageIRC()
		local playerName = chatvars.playername

		if ircid then
			playerName = players[ircid].name
		end

		if ircMsg ~= nil then
			-- ignore game messages
			if (chatvars.playername ~= "Server" and chatvars.playerid == nil) or string.find(ircMsg, " INF ") or string.find(ircMsg, "password") or string.find(ircMsg, "pass ") or string.find(string.lower(ircMsg), " api ") or string.find(ircMsg, "GMSG:", nil, true) then
				return true
			end

			ircMsg = string.gsub(ircMsg, "Smegz0r:", "Bot Master Smegz0r:")

			if string.find(ircMsg, "Server:") and playerName ~= "Server" then
				ircMsg = string.gsub(ircMsg, "Server:", playerName .. ":")
			end

			if string.find(ircMsg, server.botName .. ":") and playerName ~= "Server" then
				ircMsg = string.gsub(ircMsg, server.botName .. ":", playerName .. ":")
			end

			irc_chat(server.ircMain, ircMsg)
			windowMessage(server.windowGMSG, playerName .. ": " .. chatvars.command .. "\n", true)

			-- botman.webdavFolderWriteable is set to true every hour. We skip it if false the rest of the time as it causes some code to stop early if it doesn't have write permissions.
			if botman.webdavFolderWriteable then
				logChat(botman.serverTime, ircMsg)

				if (string.sub(chatvars.command, 1, 1) == server.commandPrefix) then
					logCommand(botman.serverTime, ircMsg)
				end
			end
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if debug then
		display("line " .. line)

		if ircid ~= nil then
			dbug("ircid " .. ircid)
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	noWaypoint = false
	chatStringStart = ""
	chatvars = {}
	chatvars.restrictedCommand = false
	chatvars.timestamp = os.time()
	botman.ExceptionCount = 0
	chatvars.oldLine = line
	chatvars.playerid = 0
	chatvars.gameid = 0
	chatvars.accessLevel = 99
	chatvars.command = line
	chatvars.nonBotCommand = false
	chatvars.ircid = 0
	chatvars.ircAlias = ""
	chatvars.helpRead = false
	chatvars.playername = ""
	chatFlag = ""

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not server.gameVersionNumber and server.gameVersion then
		temp = string.split(server.gameVersion, " ")
		server.gameVersionNumber = tonumber(temp[2])
	end

	if not server.gameDate then
		server.gameDate	= ""
	end

	if server.gameVersionNumber then
		--if tonumber(server.gameVersionNumber) < 17 then
			if string.find(line, "Chat: ", nil, true) then
				msg = string.sub(line, string.find(line, "Chat: ") + 6)
				temp = string.split(msg, ":")
				chatvars.playername = stripAllQuotes(temp[1])
				chatvars.playername = stripBBCodes(chatvars.playername)

				if temp[3] then
					chatvars.command = temp[2] .. ":" .. string.sub(msg, string.find(msg, temp[3], nil, true))
				else
					chatvars.command = temp[2]
				end
			end
		--else
			if string.find(line, "'Global'): ", nil, true) then
				msg = string.sub(line, string.find(line, "'Global'): ") + 11)

				if not string.find(line, "from '-non-player-'", nil, true) then
					pos = string.find(line, "7656")
					chatvars.playerid = string.sub(line, pos, pos + 16)
				end

				temp = string.split(msg, ":")
				chatvars.playername = stripAllQuotes(temp[1])
				chatvars.playername = stripBBCodes(chatvars.playername)

				if chatvars.playername == server.botName then
					chatvars.playername = "Server"
				end

				if temp[3] then
					chatvars.command = temp[2] .. ":" .. string.sub(msg, string.find(msg, temp[3], nil, true))
				else
					chatvars.command = temp[2]
				end
			end

			if string.find(line, "'Party'): ", nil, true) then
				chatFlag = "(P) "
				msg = string.sub(line, string.find(line, "'Party'): ") + 10)
				pos = string.find(line, "7656")
				chatvars.playerid = string.sub(line, pos, pos + 16)
				temp = string.split(msg, ":")
				chatvars.playername = stripAllQuotes(temp[1])
				chatvars.playername = stripBBCodes(chatvars.playername)

				if temp[3] then
					chatvars.command = temp[2] .. ":" .. string.sub(msg, string.find(msg, temp[3], nil, true))
				else
					chatvars.command = temp[2]
				end
			end

			if string.find(line, "'Friends'): ", nil, true) then
				chatFlag = "(F) "
				msg = string.sub(line, string.find(line, "'Friends'): ") + 12)
				pos = string.find(line, "7656")
				chatvars.playerid = string.sub(line, pos, pos + 16)
				temp = string.split(msg, ":")
				chatvars.playername = stripAllQuotes(temp[1])
				chatvars.playername = stripBBCodes(chatvars.playername)

				if temp[3] then
					chatvars.command = temp[2] .. ":" .. string.sub(msg, string.find(msg, temp[3], nil, true))
				else
					chatvars.command = temp[2]
				end
			end
		--end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "INF GMSG: ", nil, true) then
		msg = string.sub(line, string.find(line, "INF GMSG: ") + 10)
		temp = string.split(msg, ":")
		chatvars.playername = stripAllQuotes(temp[1])
		chatvars.playername = stripBBCodes(chatvars.playername)

		if temp[3] then
			chatvars.command = temp[2] .. ":" .. string.sub(msg, string.find(msg, temp[3], nil, true))
		else
			chatvars.command = temp[2]
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "INF Chatting colored: ", nil, true) then
		msg = string.sub(line, string.find(line, "INF Chatting colored: ") + 22)
		temp = string.split(msg, ":")
		chatvars.playername = stripAllQuotes(temp[1])
		chatvars.playername = stripBBCodes(chatvars.playername)

		if chatvars.playername == server.botName then
			chatvars.playername = "Server"
		end

		if temp[3] then
			chatvars.command = temp[2] .. ":" .. string.sub(msg, string.find(msg, temp[3], nil, true))
		else
			chatvars.command = temp[2]
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if ircid ~= nil then
		chatvars.playername = "Server"
		chatvars.ircid = ircid
		chatvars.ircAlias = players[ircid].ircAlias

		if tonumber(ircid) > 0 then
			chatvars.accessLevel = tonumber(accessLevel(ircid))
		else
			chatvars.accessLevel = 0
		end
	end

	if string.find(line, "-irc:") then
		if string.find(line, "'Server': ") then
			msg = string.sub(line, string.find(line, "'Server': ") + 10)
		end

		if string.find(line, server.botName .. "': ") then
			msg = string.sub(line, string.find(line, "'" .. server.botName .. "': ") + 10)
		end

		temp = string.split(msg, ":")

		if temp[3] then
			chatvars.command = temp[2] .. ":" .. string.sub(msg, string.find(msg, temp[3], nil, true))
		else
			chatvars.command = temp[2]
		end

		temp[1] = string.gsub(temp[1], "Bot Master ", "")

		chatvars.playername = string.sub(temp[1], 1, string.len(temp[1]) - 4)
		chatvars.playerid = LookupPlayer(chatvars.playername, "all")
		chatvars.playername = stripAllQuotes(chatvars.playername)
		chatvars.playername = stripBBCodes(chatvars.playername)

		if chatvars.playername == server.botName then
			chatvars.playername = "Server"
		end
	else
		if chatvars.playername ~= nil and chatvars.playerid == 0 then
			chatvars.playerid = LookupPlayer(chatvars.playername, "all")
		end
	end

	chatvars.command = string.trim(chatvars.command)

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

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
	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if string.find(line, " command 'pm") and string.find(line, "' from client") then
		msg = string.sub(line, string.find(line, "command 'pm") + 12, string.find(line, "' from client") - 1)
		id = string.sub(line, string.find(line, "from client ") + 12)

		chatvars.playerid = LookupPlayer(id, "all")
		chatvars.playername = players[chatvars.playerid].name
		chatvars.gameid = players[chatvars.playerid].id
		chatvars.command = string.trim(msg)
		chatvars.accessLevel = tonumber(accessLevel(chatvars.playerid))

		ircMsg = server.gameDate .. " " .. chatFlag .. " " ..  chatvars.command
	else
		if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if string.find(chatvars.oldLine, "'Server':", nil, true) and not string.find(line, "-irc:") then
			chatvars.playername = "Server"
			botman.faultyChat = false
		end

		if string.find(chatvars.oldLine, server.botName .. "':", nil, true) and not string.find(line, "-irc:") then
			chatvars.playername = "Server"
			botman.faultyChat = false
		end

		if chatvars.command then
			if string.len(chatvars.command) > 200 then
				temp = string.gsub(chatvars.playername, "%[[%/%!]-[^%[%]]-]", "") .. ": " .. string.sub(chatvars.command, 1, 200)
				temp = string.gsub(temp, "%[[%/%!]-[^%[%]]-]", "")

				ircMsg = server.gameDate .. " " .. chatFlag .. " " ..  temp
				messageIRC()

				temp = string.sub(chatvars.command, 201)
				temp = string.gsub(temp, "%[[%/%!]-[^%[%]]-]", "")

				ircMsg = server.gameDate .. " " .. chatFlag .. " " ..  temp
			else
				if not string.find(chatvars.command, server.commandPrefix .. "accept") and not string.find(chatvars.command, server.commandPrefix .. "poke") then
					ircMsg = server.gameDate .. " " .. chatFlag .. " " ..  string.gsub(chatvars.playername, "%[[%/%!]-[^%[%]]-]", "") .. ": " .. string.gsub(chatvars.command, "%[[%/%!]-[^%[%]]-]", "")
				end
			end
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
		if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if chatvars.playerid == 0 and chatvars.ircid == 0 then
			-- usually this is a message from the server such as player left the game.  Ignore it and stop processing the line here.
			botman.faultyChat = false
			result = true
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.playerid ~= 0 then
			if (players[chatvars.playerid].lastCommand) then
				-- don't allow identical commands being spammed too quickly
	--			if ((os.time() - players[chatvars.playerid].lastCommandTimestamp) < 4) and players[chatvars.playerid].lastCommand == chatvars.command then
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
			igplayers[chatvars.playerid].afk = os.time() + 900
			chatvars.intX = igplayers[chatvars.playerid].xPos
			chatvars.intY = igplayers[chatvars.playerid].yPos
			chatvars.intZ = igplayers[chatvars.playerid].zPos
			chatvars.accessLevel = tonumber(accessLevel(chatvars.playerid))
			x = math.floor(chatvars.intX / 512)
			z = math.floor(chatvars.intZ / 512)
			chatvars.region = "r." .. x .. "." .. z .. ".7rg"
			zombies = tonumber(igplayers[chatvars.playerid].zombies)
			chatvars.zombies = zombies
		end

		if chatvars.playerid ~= 0 then
			if players[chatvars.playerid].block then
				botman.faultyChat = false
				result = true
				return true
			end
		end
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

	chatvars.wordCount = table.maxn(chatvars.words)
	chatvars.numberCount = table.maxn(chatvars.numbers)
	chatvars.commandOld = chatvars.command
	chatvars.command = string.lower(string.trim(chatvars.command))

	if (string.sub(chatvars.words[1], 1, 1) == server.commandPrefix) then
		chatvars.words[1] = string.sub(chatvars.words[1], 2, string.len(chatvars.words[1]))
		chatvars.wordsOld[1] = string.sub(chatvars.wordsOld[1], 2, string.len(chatvars.wordsOld[1]))
	end

	if not string.match(string.sub(chatvars.words[1], 1, 1), "(%w)") then
		chatvars.words[1] = string.sub(chatvars.words[1], 2, string.len(chatvars.words[1]))
		chatvars.wordsOld[1] = string.sub(chatvars.wordsOld[1], 2, string.len(chatvars.wordsOld[1]))
		chatvars.nonBotCommand = true
	end

	-- todo: stop using chatvars.number and use the new chatvars.numbers table
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

	-- if (debug) then
		-- display(chatvars)
	-- end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if ircMsg ~= nil then
		messageIRC()
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
			end
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
					if chatvars.accessLevel > 2 then
						-- warn the player once about the command cooldown after that silently ignore the command if its spammed too soon.
						if not igplayers[chatvars.playerid].commandSpamAlert then
							igplayers[chatvars.playerid].commandSpamAlert = true
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can do 1 command every " .. server.commandCooldown .. " seconds. To repeat your last command just type " .. server.commandPrefix .."[-]")
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot is no longer paused.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "The bot is no longer paused.")
			end

			message("say [" .. server.warnColour .. "]The bot is now accepting commands again! :D[-]")
			botman.botDisabled = false

			if tonumber(chatvars.playerid) > 0 then
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.botName .. " is now paused.  Most commands are disabled. To unpause it type " .. server.commandPrefix .. "unpause bot.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, server.botName .. " is now paused.  Most commands are disabled. To unpause it type cmd " .. server.commandPrefix .. "unpause bot.")
			end

			message("say [" .. server.warnColour .. "] " .. server.botName .. " is now paused.  Most commands are disabled.[-]")
			irc_chat(server.ircMain, "The bot is now paused.  To unpause it type cmd " .. server.commandPrefix .. "unpause bot.")
			botman.botDisabled = true

			if tonumber(chatvars.playerid) > 0 then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.words[1] == "reload" and (string.find(chatvars.command, "cod") or string.find(chatvars.command, "script")) then
			if tonumber(chatvars.playerid) > 0 then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			if not string.find(chatvars.command, "code") then
				r = rand(4)

				if r == 1 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Something smells fishy.[-]") end
				if r == 2 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I smell something stinky! :D[-]") end
				if r == 3 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Cod again sir?[-]") end
				if r == 4 then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]FISH![-]") end
			end

			botman.faultyChat = false
			reloadCode()
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.words[1] == "reload" and chatvars.words[2] == "lua" and chatvars.words[3] ~= nil then
			-- command the bot to reload 1 specified lua script from disk.  Limited to the scripts folder.
			temp = string.sub(line, string.find(line, chatvars.wordsOld[2]) + 4)
			temp = homedir .. "/scripts/" .. temp

			if not isFile(temp) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]That script does not exist or you have a typo.[-]")
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
			temp = string.sub(line, string.find(line, chatvars.wordsOld[3]) + 4)
			temp = homedir .. "/custom/" .. temp

			if not isFile(temp) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]That script does not exist or you have a typo.[-]")
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
			banPlayer(chatvars.playerid, "10 year", "advertising hacks", "")

			message("say [" .. server.chatColour .. "]Banning player " .. igplayers[chatvars.playerid].name .. " 10 years for advertising hacks.[-]")
			irc_chat(server.ircMain, "[BANNED] Player " .. chatvars.playerid .. " " .. igplayers[chatvars.playerid].name .. " has has been banned for advertising hacks.")
			irc_chat(server.ircAlerts, "[BANNED] Player " .. chatvars.playerid .. " " .. igplayers[chatvars.playerid].name .. " has has been banned for 10 years for advertising hacks.")
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. botman.serverTime .. "','ban','Player " .. chatvars.playerid .. " " .. escape(igplayers[chatvars.playerid].name) .. " has has been banned for 10 years for advertising hacks.'," .. chatvars.playerid .. ")")

			if botman.db2Connected then
				-- copy in bots db
				connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','ban','Player " .. chatvars.playerid .. " " .. escape(igplayers[chatvars.playerid].name) .. " has has been banned for 10 years for advertising hacks.'," .. chatvars.playerid .. ")")
			end

			botman.faultyChat = false
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.words[1] == "reload" and chatvars.words[2] == "debug" then
			dofile(homedir .. "/scripts/debug.lua")

			if tonumber(chatvars.playerid) > 0 then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.words[1] == "register" and chatvars.words[2] == "help" then
			if (chatvars.accessLevel > 0) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
				else
					if not chatvars.showHelp then
						irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.playername == "Server") then
				if not chatvars.showHelp then
					irc_chat(players[chatvars.ircid].ircAlias, "Registering command help.")
				end
			end

			botman.registerHelp	= true
			topicID = 1
			commandID = 1

			if botman.dbConnected then
				conn:execute("TRUNCATE TABLE helpTopicCommands")
				conn:execute("TRUNCATE TABLE helpCommands")
				conn:execute("TRUNCATE TABLE helpTopics")
			end

			if tonumber(chatvars.playerid) > 0 then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
		end
	end

	if tonumber(chatvars.playerid) > 0 then
		if players[chatvars.playerid] then
			chatvars.gameid = players[chatvars.playerid].id
		end
	end

	if (debug) then
		display(chatvars)
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if debug then dbug("debug entering gmsg_custom") end
	result = gmsg_custom()

	if result then
		if debug then dbug("debug ran command in gmsg_custom") end
		return true
	end

	-- If you want to override any commands in the sections below, create commands in gmsg_custom.lua or call them from within it making sure to match the commands keywords.

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if debug then dbug("debug entering gmsg_info") end
	result = gmsg_info()

	if result then
		if debug then dbug("debug ran command in gmsg_info") end
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if chatvars.words[1] == "hardcore" and chatvars.words[2] == "mode" and (chatvars.words[3] == "off" or chatvars.words[3] == "disable" or string.sub(chatvars.words[3], 1, 2) == "de") then
			players[chatvars.playerid].silentBob = false
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will help you.[-]")

			if tonumber(chatvars.playerid) > 0 then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if chatvars.words[1] == "hardcore" and chatvars.words[2] == "mode" and (chatvars.words[3] == "on" or chatvars.words[3] == "enable" or chatvars.words[3] == "activate") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will not help you.[-]")
			players[chatvars.playerid].silentBob = true

			if tonumber(chatvars.playerid) > 0 then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			return true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "restore" and chatvars.words[2] == "admin" then
		if chatvars.ircid ~= 0 then
			if botman.dbConnected then conn:execute("UPDATE persistentQueue SET timerDelay = now() WHERE steam = " .. chatvars.ircid) end
		else
			if botman.dbConnected then conn:execute("UPDATE persistentQueue SET timerDelay = now() WHERE steam = " .. chatvars.playerid) end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if players[chatvars.playerid].silentBob == true and chatvars.accessLevel > 2 then
			result = true
			botman.faultyChat = false
			return true
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "fix" and chatvars.words[2] == "bot" and chatvars.words[3] == nil) or string.find(chatvars.command, "fix all the things") then
		if (chatvars.accessLevel > 1) then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
			else
				if not chatvars.showHelp then
					irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				end
			end

			botman.faultyChat = false
			return true
		end

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Fixing bot.  Please wait.. If this doesn't fix it, doing this again probably won't either.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Fixing bot.  Please wait.. If this doesn't fix it, doing this again probably won't either.")
		end

		if not botman.fixingBot then
			botman.fixingBot = true
			fixBot()
		end

		if tonumber(chatvars.playerid) > 0 then
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
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]The bot is currently disabled and not accepting most commands.[-]")
					else
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]The bot is currently disabled.  To enable it again type " .. server.commandPrefix .. "unpause bot[-]")
					end

					botman.faultyChat = false
					return true
				end
			end
		else
			if (chatvars.accessLevel > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot is currently disabled.  To enable it again type cmd " .. server.commandPrefix .. "unpause bot")
				botman.faultyChat = false
				return true
			end
		end

		botman.faultyChat = false
		return true
	end

	if debug then dbug("debug entering gmsg_unslashed") end
	result = gmsg_unslashed()

	if result then
		if debug then dbug("debug ran command in gmsg_unslashed") end
		return true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if debug then dbug("debug entering gmsg_base") end
	result = gmsg_base()

	if result then
		if debug then dbug("debug ran command in gmsg_base") end
		return true
	end

	if debug then dbug("debug entering gmsg_locations") end
	result = gmsg_locations()

	if result then
		if debug then dbug("debug ran command in gmsg_locations") end
		return true
	end

	if debug then dbug("debug entering gmsg_teleports") end
	result = gmsg_teleports()

	if result then
		if debug then dbug("debug ran command in gmsg_teleports") end
		return true
	end

	if debug then dbug("debug entering gmsg_waypoints") end
	result = gmsg_waypoints()

	if result then
		if debug then dbug("debug ran command in gmsg_waypoints") end
		return true
	end

	if debug then dbug("debug entering gmsg_shop") end
	result = gmsg_shop()

	if result then
		if debug then dbug("debug ran command in gmsg_shop") end
		return true
	end

	if debug then dbug("debug entering gmsg_misc") end
	result = gmsg_misc()

	if result then
		if debug then dbug("debug ran command in gmsg_misc") end
		return true
	end

	if debug then dbug("debug entering gmsg_mail") end
	result = gmsg_mail()

	if result then
		if debug then dbug("debug ran command in gmsg_mail") end
		return true
	end

	if debug then dbug("debug entering gmsg_hotspots") end
	result = gmsg_hotspots()

	if result then
		if debug then dbug("debug ran command in gmsg_hotspots") end
		return true
	end

	if debug then dbug("debug entering gmsg_friends") end
	result = gmsg_friends()

	if result then
		if debug then dbug("debug ran command in gmsg_friends") end
		return true
	end

	if debug then dbug("debug entering gmsg_villages") end
	result = gmsg_villages()

	if result then
		if debug then dbug("debug ran command in gmsg_villages") end
		return true
	end

	if debug then dbug("debug entering gmsg_bot") end
	result = gmsg_bot()

	if result then
		if debug then dbug("debug ran command in gmsg_bot") end
		return true
	end

	if debug then dbug("debug entering gmsg_fun") end
	result = gmsg_fun()

	if result then
		if debug then dbug("debug ran command in gmsg_fun") end
		return true
	end

	if debug then dbug("debug entering gmsg_admin") end
	result = gmsg_admin()

	if result then
		if debug then dbug("debug ran command in gmsg_admin") end
		return true
	end

	if debug then dbug("debug entering gmsg_resets") end
	result = gmsg_resets()

	if result then
		if debug then dbug("debug ran command in gmsg_resets") end
		return true
	end

	if debug then dbug("debug entering gmsg_tracker") end
	result = gmsg_tracker()

	if result then
		if debug then dbug("debug ran command in gmsg_tracker") end
		return true
	end

	if debug then dbug("debug entering gmsg_server") end
	result = gmsg_server()

	if result then
		if debug then dbug("debug ran command in gmsg_server") end
		return true
	end

	if server.botman then
		if debug then dbug("debug entering gmsg_botman") end
		result = gmsg_botman()

		if result then
			if debug then dbug("debug ran command in gmsg_botman") end
			return true
		end
	end

	if server.stompy then
		if debug then dbug("debug entering gmsg_stompy") end
		result = gmsg_stompy()

		if result then
			if debug then dbug("debug ran command in gmsg_stompy") end
			return true
		end
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

	if (string.sub(chatvars.command, 1, 1) == server.commandPrefix) and (chatvars.playername ~= "Server") and not result then  -- THIS COMMAND MUST BE LAST OR IT STOPS SLASH COMMANDS BELOW IT WORKING.
		pname = nil
		pname = string.sub(chatvars.command, 2)
		pname = string.trim(pname)

		id = LookupPlayer(pname)

		if (players[chatvars.playerid].prisoner or not players[chatvars.playerid].canTeleport) then
			botman.faultyChat = false
			return true
		end

		if (id ~= 0) then
			-- reject if not an admin and server is in hardcore mode
			if isServerHardcore(chatvars.playerid) then
				message("pm " .. playerid .. " [" .. server.chatColour .. "]This command is disabled.[-]")
				botman.faultyChat = false
				return true
			end

			-- reject if not an admin and player teleporting has been disabled
			if tonumber(chatvars.accessLevel) > 2 and not server.allowTeleporting then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting has been disabled on this server.[-]")
				botman.faultyChat = false
				return true
			end

			-- reject if not an admin and player to player teleporting has been disabled
			if tonumber(chatvars.accessLevel) > 2 and not server.allowPlayerToPlayerTeleporting then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting to friends has been disabled on this server.[-]")
				botman.faultyChat = false
				return true
			end

			-- reject if not an admin or a friend
			if (not isFriend(id,  chatvars.playerid)) and (chatvars.accessLevel > 2) and (id ~= chatvars.playerid) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only friends of " .. players[id].name .. " and staff can do this.[-]")
				botman.faultyChat = false
				return true
			end

			-- if pvpZone(players[id].xPos, players[id].zPos) and chatvars.accessLevel > 2 then
				-- message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not allowed to teleport to players in PVP zones.[-]")
				-- botman.faultyChat = false
				-- result = true
				-- return true
			-- end

			if not igplayers[id] and chatvars.accessLevel > 2 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is offline at the moment.  You will have to wait till they return or start walking.[-]")
				botman.faultyChat = false
				return true
			end

			if players[id].xPos == 0 and players[id].yPos == 0 and players[id].zPos == 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has not played here since the last map wipe.[-]")
				botman.faultyChat = false
				return true
			end

			-- teleport to a friend if sufficient zennies
			if tonumber(server.teleportCost) > 0 and (chatvars.accessLevel > 2) then
				if tonumber(players[chatvars.playerid].cash) < tonumber(server.teleportCost) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. ".  Kill some zombies, gamble, trade or beg to earn more.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if (os.time() - igplayers[chatvars.playerid].lastTPTimestamp < 5) and (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleport is recharging.  Wait a few seconds.  You can repeat your last command by typing " .. server.commandPrefix .."[-]")
				botman.faultyChat = false
				return true
			end

			-- first record the current x y z
			players[chatvars.playerid].xPosOld = chatvars.intX
			players[chatvars.playerid].yPosOld = chatvars.intY
			players[chatvars.playerid].zPosOld = chatvars.intZ
			igplayers[chatvars.playerid].lastLocation = ""

			-- then teleport to the friend
			cmd = "tele " .. chatvars.playerid .. " " .. players[id].xPos .. " " .. players[id].yPos .. " " .. players[id].zPos

			players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - server.teleportCost

			if tonumber(server.playerTeleportDelay) == 0 or not igplayers[chatvars.playerid].currentLocationPVP or tonumber(players[chatvars.playerid].accessLevel) < 2 then
				if teleport(cmd, chatvars.playerid) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have teleported to " .. players[id].name .. "'s location.[-]")
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will be teleported to " .. players[id].name .. "'s location in " .. server.playerTeleportDelay .. " seconds.[-]")
				if botman.dbConnected then conn:execute("insert into persistentQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
				igplayers[chatvars.playerid].lastTPTimestamp = os.time() -- this won't really stop additional tp commands stacking but it will slow the player down a little.
			end

			botman.faultyChat = false
			return true
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if botman.registerHelp then
		botman.registerHelp	= false

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The command help has been registered.[-]")
		else
			if not chatvars.showHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Command help registration complete.")
			end
		end
	end

	if chatvars.words[1] == "register" and chatvars.words[2] == "help" then
		result = true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not result then
		if (string.sub(chatvars.command, 1, 1) == server.commandPrefix) and not server.hideUnknownCommand then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Unknown command: " .. chatvars.command .. " Type " .. server.commandPrefix .. "help or " .. server.commandPrefix .. "commands for commands.[-]")
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

	if chatvars.playerid ~= 0 then
		if chatvars.ircid == 0 and players[chatvars.playerid].botQuestion then
			-- make the bot forget questions so we don't have it randomly react later on unexpectedly >.<
			if players[chatvars.playerid].botQuestion ~= "" then
				if string.find(players[chatvars.playerid].botQuestion, "reset") and not string.find(chatvars.command, "reset") then
					players[chatvars.playerid].botQuestion = ""
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset cancelled.[-]")
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
