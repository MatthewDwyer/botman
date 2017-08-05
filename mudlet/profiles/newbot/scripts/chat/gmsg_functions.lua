--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false

function day7(steam)
	if (server.gameDay % 7 == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes will run tonight![-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes will run tonight![-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 1) % 7 == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected tomorrow[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected tomorrow[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 2) % 7 == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in 2 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in 2 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 3) % 7 == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in 3 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in 3 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 4) % 7 == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in 4 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in 4 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 5) % 7 == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in 5 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in 5 days[-]")
		end

		botman.faultyChat = false
		return true
	end

	if ((server.gameDay + 6) % 7 == 0) then
		if steam ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Feral hordes are expected in 6 days[-]")
		else
			message("say [" .. server.chatColour .. "]Feral hordes are expected in 6 days[-]")
		end

		botman.faultyChat = false
		return true
	end
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

	if tonumber(gameTick) < 0 then
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
			timeRemaining = (tonumber(server.maxServerUptime) * 3600) - gameTick + 900
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
			if (server.gameDay % 7 == 0) then
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
						message("say [" .. server.chatColour .. "]The next reboot is in " .. days .. " " .. strDays .. " " .. hours .. " " .. strHours .. " and " .. minutes .." " .. strMinutes .. "[-]")
					else
						if hours > 0 then
							message("say [" .. server.chatColour .. "]The next reboot is in " .. hours .. " " .. strHours .. " and " .. minutes .." " .. strMinutes .. "[-]")
						else
							message("say [" .. server.chatColour .. "]The next reboot is in " .. minutes .." " .. strMinutes .. "[-]")
						end
					end
				else
					if igplayers[steam] then
						if days > 0 then
							message("pm " .. steam .. " [" .. server.chatColour .. "]The next reboot is in " .. days .. " " .. strDays .. " " .. hours .. " " .. strHours .. " and " .. minutes .." " .. strMinutes .. "[-]")
						else
							if hours > 0 then
								message("pm " .. steam .. " [" .. server.chatColour .. "]The next reboot is in " .. hours .. " " .. strHours .. " and " .. minutes .." " .. strMinutes .. "[-]")
							else
								message("pm " .. steam .. " [" .. server.chatColour .. "]The next reboot is in " .. minutes .." " .. strMinutes .. "[-]")
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
		end
	end

	if (pname == nil) then
		id = playerid
		pname = players[playerid].name
	else
		pname = players[id].name
	end

	message("pm " .. playerid .. " [" .. server.chatColour .. "]You have " .. players[id].cash .. " " .. server.moneyPlural .. " in the bank.[-]")

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

	intX = math.floor(igplayers[playerid].xPos)
	intY = math.ceil(igplayers[playerid].yPos)
	intZ = math.floor(igplayers[playerid].zPos)

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
	message("pm " .. playerid .. " [" .. server.chatColour .. "]You are in region r." .. x .. "." .. z .. ".7[-]")

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

						message("pm " .. playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%d", dist) .. " region r." .. x .. "." .. z .. ".7 Hacker score: " .. players[k].hackerScore .. "[-]")
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


function logCommand(commandTime, commandOwner, commandLine)
	if botman.webdavFolderWriteable == false or string.find(commandLine, " INF ") or string.find(commandLine, "' from client") then
		return
	end

	-- flag the webdav folder as not writeable.  If the code below succeeds, we'll flag it as writeable so we can skip writing the chat log next time around.
	-- If we can't write the log and we keep trying to, the bot won't be able to respond to any commands since we're writing to the log before processing the chat much.
	botman.webdavFolderWriteable = false

	-- log the chat
	file = io.open(botman.chatlogPath .. "/" .. os.date("%Y%m%d") .. "_commandlog.txt", "a")
	file:write(commandTime .. "; " .. commandOwner .. "; " .. string.trim(commandLine) .. "\n")
	file:close()

	botman.webdavFolderWriteable = true
end


function logChat(chatTime, chatOwner, chatLine)
	if botman.webdavFolderWriteable == false or string.find(chatLine, " INF ") or string.find(chatLine, "' from client") then
		return
	end

	-- flag the webdav folder as not writeable.  If the code below succeeds, we'll flag it as writeable so we can skip writing the chat log next time around.
	-- If we can't write the log and we keep trying to, the bot won't be able to respond to any commands since we're writing to the log before processing the chat much.
	botman.webdavFolderWriteable = false

	-- log the chat
	file = io.open(botman.chatlogPath .. "/" .. os.date("%Y%m%d") .. "_chatlog.txt", "a")
	file:write(chatTime .. "; " .. chatOwner .. "; " .. string.trim(chatLine) .. "\n")
	file:close()

	botman.webdavFolderWriteable = true
end


function gmsg(line, ircid)
	local result, x, z, id, pname, noWaypoint, temp, chatStringStart, cmd, msg, test, ircMsg

	function messageIRC()
		if ircMsg ~= nil then
			-- ignore game messages
			if (chatvars.playername ~= "Server" and chatvars.playerid == nil) or string.find(ircMsg, " INF ") then
				return
			end

			irc_chat(server.ircMain, ircMsg)

--			if players[chatvars.playerid] or chatvars.playername == "Server" then
				windowMessage(server.windowGMSG, chatvars.playername .. ": " .. chatvars.command .. "\n", true)
				logChat(botman.serverTime, chatvars.playername, ircMsg)

				if (string.sub(chatvars.command, 1, 1) == server.commandPrefix) then
					logCommand(botman.serverTime, chatvars.playername, ircMsg)
				end
--			end
		end
	end

	if debug then
		display("line " .. line)
		dbug("gmsg " .. line)

		if ircid ~= nil then
			dbug("ircid " .. ircid)
		end
	end

	noWaypoint = false
	chatStringStart = ""
	chatvars = {}
	chatvars.restrictedCommand = false
	chatvars.timestamp = os.time()
	botman.ExceptionCount = 0
	chatvars.gmsg = line
	chatvars.oldLine = line
	chatvars.playerid = 0
	chatvars.accessLevel = 99
	chatvars.command = line
	chatvars.time = string.sub(line, 1, 20)

	if debug then dbug("gmsg chatvars.accessLevel " .. chatvars.accessLevel) end

	if string.find(line, "Chat: ", nil, true) then
		msg = string.sub(line, string.find(line, "Chat: ") + 6)
		temp = string.split(msg, ":")
		chatvars.playername = stripQuotes(temp[1])

		if temp[3] then
			chatvars.command = temp[2] .. ":" .. string.sub(msg, string.find(msg, temp[3], nil, true))
		else
			chatvars.command = temp[2]
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "INF GMSG: ", nil, true) then
		msg = string.sub(line, string.find(line, "INF GMSG: ") + 10)
		temp = string.split(msg, ":")
		chatvars.playername = stripQuotes(temp[1])

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
		chatvars.playername = stripQuotes(temp[1])

		if temp[3] then
			chatvars.command = temp[2] .. ":" .. string.sub(msg, string.find(msg, temp[3], nil, true))
		else
			chatvars.command = temp[2]
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if ircid ~= nil then
		chatvars.ircid = ircid

		if tonumber(ircid) > 0 then
			chatvars.accessLevel = accessLevel(ircid)
		else
			chatvars.accessLevel = 0
		end
	end

	if string.find(line, "-irc:") then
		msg = string.sub(line, string.find(line, "'Server': ") + 10)
		temp = string.split(msg, ":")

		if temp[3] then
			chatvars.command = temp[2] .. ":" .. string.sub(msg, string.find(msg, temp[3], nil, true))
		else
			chatvars.command = temp[2]
		end

		chatvars.playername = string.sub(temp[1], 1, string.len(temp[1]) - 4)
		chatvars.playerid = LookupPlayer(chatvars.playername, "all")
	else
		if chatvars.playername ~= nil then
			chatvars.playerid = LookupPlayer(chatvars.playername, "all")
		end
	end

	chatvars.command = string.trim(chatvars.command)

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if chatvars.playername == nil then
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
		return
	end

	if string.find(line, " command 'pm") and string.find(line, "' from client") then
		msg = string.sub(line, string.find(line, "command 'pm") + 12, string.find(line, "' from client") - 1)
		id = string.sub(line, string.find(line, "from client ") + 12)

		chatvars.playerid = LookupPlayer(id, "all")
		chatvars.playername = players[chatvars.playerid].name
		chatvars.gameid = players[chatvars.playerid].id
		chatvars.command = string.trim(msg)
		chatvars.accessLevel = accessLevel(chatvars.playerid)

if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
		ircMsg = server.gameDate .. " " .. chatvars.command
	else
		if string.find(chatvars.gmsg, "'Server':", nil, true) and not string.find(line, "-irc:") then
			chatvars.playername = "Server"
			botman.faultyChat = false
		end

		if string.len(chatvars.command) > 200 then
			temp = string.gsub(chatvars.playername, "%[[%/%!]-[^%[%]]-]", "") .. ": " .. string.sub(chatvars.command, 1, 200)
			temp = string.gsub(temp, "%[[%/%!]-[^%[%]]-]", "")

if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
			ircMsg = server.gameDate .. " " .. temp
			messageIRC()

			temp = string.sub(chatvars.command, 201)
			temp = string.gsub(temp, "%[[%/%!]-[^%[%]]-]", "")

if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
			ircMsg = server.gameDate .. " " .. temp
		else
			if not string.find(chatvars.command, server.commandPrefix .. "accept") and not string.find(chatvars.command, server.commandPrefix .. "poke") then
if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
				ircMsg = server.gameDate .. " " .. string.gsub(chatvars.playername, "%[[%/%!]-[^%[%]]-]", "") .. ": " .. string.gsub(chatvars.command, "%[[%/%!]-[^%[%]]-]", "")
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
		botman.faultyChat = false
if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
		return
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if (players[chatvars.playerid].lastCommand ~= nil) then
			-- don't allow commands or chat being spammed too quickly
			if (os.time() - players[chatvars.playerid].lastCommandTimestamp) < 2 then
				botman.faultyChat = false
				result = true
				return
			end
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if igplayers[chatvars.playerid] then
			igplayers[chatvars.playerid].afk = os.time() + 900
			chatvars.intX = math.floor(igplayers[chatvars.playerid].xPos)
			chatvars.intY = math.ceil(igplayers[chatvars.playerid].yPos)
			chatvars.intZ = math.floor(igplayers[chatvars.playerid].zPos)
			chatvars.accessLevel = accessLevel(chatvars.playerid)
			x = math.floor(chatvars.intX / 512)
			z = math.floor(chatvars.intZ / 512)
			chatvars.region = "r." .. x .. "." .. z .. ".7"
			zombies = tonumber(igplayers[chatvars.playerid].zombies)
			chatvars.zombies = zombies

			if string.len(chatvars.command) > 150 and server.coppi then
				if igplayers[chatvars.playerid].longLineCount == nil then
					igplayers[chatvars.playerid].longLineCount = 0
					igplayers[chatvars.playerid].longLineTimer = os.time()
				end

				if tonumber(igplayers[chatvars.playerid].longLineCount) > 3 then
					igplayers[chatvars.playerid].longLineTimer = os.time() + 10
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have been muted for 1 minute for too many excessively long chat lines.[-]")
					send("mpc " .. chatvars.playerid .. " true")
					tempTimer( 60, [[unmutePlayer("]] .. chatvars.playerid .. [[")]] )
				end
			end
		end

		if players[chatvars.playerid].lockout then
			botman.faultyChat = false
			result = true

			return
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	chatvars.words = {}
	chatvars.wordsOld = {}

	for word in chatvars.command:gmatch("%S+") do
		table.insert(chatvars.words, string.lower(word))
		table.insert(chatvars.wordsOld, word)
	end

	chatvars.wordCount = table.maxn(chatvars.words)
	chatvars.commandOld = chatvars.command
	chatvars.command = string.lower(string.trim(chatvars.command))

	if (string.sub(chatvars.words[1], 1, 1) == server.commandPrefix) then
		chatvars.words[1] = string.sub(chatvars.words[1], 2, string.len(chatvars.words[1]))
	end

	chatvars.number = tonumber(string.match(chatvars.command, " (-?%d+)")) -- (-?\%d+)
	result = false

	if ircid ~= nil and ((chatvars.words[1] == "command" or chatvars.words[1] == "list") and chatvars.words[2] == "help" or chatvars.words[1] == "help") then
		chatvars.showHelp = true
	end

	if ircid ~= nil and chatvars.words[1] == "help" and chatvars.words[2] == "sections" then
		chatvars.showHelpSections = true
	end

	if (debug) then
		display(chatvars)
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if ircMsg ~= nil then
		messageIRC()
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	-- don't process any chat coming from irc or death messages
	if string.find(chatvars.gmsg, "-irc:", nil, true) or (chatvars.playername == "Server" and (string.find(chatvars.gmsg, "died") or string.find(chatvars.gmsg, "eliminated"))) then
		botman.faultyChat = false
		return
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not result then
		if not result and debug then dbug("debug entering gmsg_custom") end
		result = gmsg_custom()
		if result and debug then dbug("debug ran command in gmsg_custom") end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not result and (chatvars.playername ~= "Server") then
		if players[chatvars.playerid].lastCommand ~= nil then
			if chatvars.command == server.commandPrefix then
				players[chatvars.playerid].lastCommandTimestamp = os.time() - 10
				gmsg(players[chatvars.playerid].lastChatLine)
				return
			end

			if (string.find(chatvars.command, server.commandPrefix .. "again") and chatvars.words[3] == nil) or (chatvars.command == server.commandPrefix .. " north") or (chatvars.command == server.commandPrefix .. " south") or (chatvars.command == server.commandPrefix .. " east") or (chatvars.command == server.commandPrefix .. " west") then
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

				players[chatvars.playerid].lastChatLineTimestamp = os.time() - 10
				gmsg(players[chatvars.playerid].lastChatLine)
				return
			end
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if chatvars.playername ~= "Server" then
		players[chatvars.playerid].lastCommandTimestamp = os.time()

		if (string.sub(chatvars.command, 1, 1) == server.commandPrefix) then
			players[chatvars.playerid].lastCommand = chatvars.command
			players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not result then
		if chatvars.showHelp and not skipHelp then
			if (string.find(chatvars.command, "reload")) or chatvars.words[1] ~= "help" and chatvars.words[3] == nil then
				irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reload code")

				if not shortHelp then
					irc_chat(players[chatvars.ircid].ircAlias, "Tell the bot to reload all external Lua scripts.  This also happens shortly after restarting the bot and it can automatically detect if the scripts are not loaded and reload them.")
					irc_chat(players[chatvars.ircid].ircAlias, "Once the script have loaded, if you make any changes to them you need to run this command or restart the bot for your changes to take effect.")
					irc_chat(players[chatvars.ircid].ircAlias, " ")
				end
			end

			if (string.find(chatvars.command, "pause") or string.find(chatvars.command, "bot")) or chatvars.words[1] ~= "help" and chatvars.words[3] == nil then
				irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "pause (or disable or stop) bot")

				if not shortHelp then
					irc_chat(players[chatvars.ircid].ircAlias, "Temporarily disable the bot.  It will still read the chat and can be enabled again.")
					irc_chat(players[chatvars.ircid].ircAlias, " ")
				end
			end
		end

		if (chatvars.words[1] == "pause" or chatvars.words[1] == "stop" or chatvars.words[1] == "disable") and chatvars.words[2] == "bot" and chatvars.accessLevel == 0 then
			message("say [" .. server.warnColour .. "] " .. server.botName .. " is now running in safe mode.  Most commands are disabled.[-]")
			irc_chat(server.ircMain, "The bot is running in safe mode.  To exit safe mode type " .. server.commandPrefix .. "start bot")
			botman.botDisabled = true

			if tonumber(chatvars.playerid) > 0 then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			result = true
		end

		if (chatvars.words[1] == "unpause" or chatvars.words[1] == "resume" or chatvars.words[1] == "start" or chatvars.words[1] == "enable") and chatvars.words[2] == "bot" and chatvars.accessLevel == 0 then
			message("say [" .. server.warnColour .. "]The bot has exited safe mode.[-]")
			botman.botDisabled = false

			if tonumber(chatvars.playerid) > 0 then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			result = true
		end

		if chatvars.words[1] == "reload" and (string.find(chatvars.command, "code") or string.find(chatvars.command, "script")) then
			dofile(homedir .. "/scripts/reload_bot_scripts.lua")
			reloadBotScripts(true)

			if tonumber(chatvars.playerid) > 0 then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			result = true
		end

		if chatvars.words[1] == "reload" and chatvars.words[2] == "debug" then
			dofile(homedir .. "/scripts/debug.lua")

			if tonumber(chatvars.playerid) > 0 then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
			result = true
		end

		if chatvars.words[1] == "register" and chatvars.words[2] == "help" then
			botman.registerHelp	= true

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

		if chatvars.words[1] == "register" and chatvars.words[2] == "commands" then
			botman.registerCommands	= true

			if tonumber(chatvars.playerid) > 0 then
				players[chatvars.playerid].lastCommand = chatvars.command
				players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
				players[chatvars.playerid].lastCommandTimestamp = os.time()
			end

			botman.faultyChat = false
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not result then
		if debug then dbug("debug entering gmsg_unslashed") end
		result = gmsg_unslashed()
		if result and debug then dbug("debug ran command in gmsg_unslashed") end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if not result then
		if debug then dbug("debug entering gmsg_info") end
		result = gmsg_info()
		if result and debug then dbug("debug ran command in gmsg_info") end
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
			result = true
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
			result = true
		end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

		if players[chatvars.playerid].silentBob == true then
			result = true
			botman.faultyChat = false
			return
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "fix" and chatvars.words[2] == "bot" and chatvars.words[3] == nil then
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Fixing bot.  Please wait.. If this doesn't fix it, doing this again probably won't either.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Fixing bot.  Please wait.. If this doesn't fix it, doing this again probably won't either.")
		end

		fixBot()

		if tonumber(chatvars.playerid) > 0 then
			players[chatvars.playerid].lastCommand = chatvars.command
			players[chatvars.playerid].lastChatLine = chatvars.oldLine -- used for storing the telnet line from the last command
			players[chatvars.playerid].lastCommandTimestamp = os.time()
		end

		botman.faultyChat = false
		result = true
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	-- if not result then
		-- if not result and debug then dbug("debug entering gmsg_custom") end
		-- result = gmsg_custom()
		-- if result and debug then dbug("debug ran command in gmsg_custom") end
	-- end

	-- If you want to override any commands in the sections below, create commands in gmsg_custom.lua or call them from within it making sure to match the commands keywords.

	if not result then
		if debug then dbug("debug entering gmsg_fun") end
		result = gmsg_fun()
		if result and debug then dbug("debug ran command in gmsg_fun") end
	end

	if botman.botDisabled then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]The bot is currently running in safe mode and not accepting most commands.[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]The bot is running in safe mode.  To exit safe mode type " .. server.commandPrefix .. "start bot[-]")
			end

			botman.faultyChat = false
if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
			return true
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot is running in safe mode.  To exit safe mode type " .. server.commandPrefix .. "start bot")
				botman.faultyChat = false
if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
				return true
			end
		end

if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
		return
	end

	if not result then
		if debug then dbug("debug entering gmsg_mail") end
		result = gmsg_mail()
		if result and debug then dbug("debug ran command in gmsg_mail") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_base") end
		result = gmsg_base()
		if result and debug then dbug("debug ran command in gmsg_base") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_admin") end
		result = gmsg_admin()
		if result and debug then dbug("debug ran command in gmsg_admin") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_friends") end
		result = gmsg_friends()
		if result and debug then dbug("debug ran command in gmsg_friends") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_hotspots") end
		result = gmsg_hotspots()
		if result and debug then dbug("debug ran command in gmsg_hotspots") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_trial_code") end
		result = gmsg_trial_code()
		if result and debug then dbug("debug ran command in gmsg_trial_code") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_resets") end
		result = gmsg_resets()
		if result and debug then dbug("debug ran command in gmsg_resets") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_shop") end
		result = gmsg_shop()
		if result and debug then dbug("debug ran command in gmsg_shop") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_tracker") end
		result = gmsg_tracker()
		if result and debug then dbug("debug ran command in gmsg_tracker") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_teleports") end
		result = gmsg_teleports()
		if result and debug then dbug("debug ran command in gmsg_teleports") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_villages") end
		result = gmsg_villages()
		if result and debug then dbug("debug ran command in gmsg_villages") end
	end

	if not result and server.allowWaypoints then
		if debug then dbug("debug entering gmsg_waypoints") end
		result = gmsg_waypoints()
		if result and debug then dbug("debug ran command in gmsg_waypoints") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_locations") end
		result = gmsg_locations()
		if result and debug then dbug("debug ran command in gmsg_locations") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_server") end
		result = gmsg_server()
		if result and debug then dbug("debug ran command in gmsg_server") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_misc") end
		result = gmsg_misc()
		if result and debug then dbug("debug ran command in gmsg_misc") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_pms") end
		result = gmsg_pms()
		if result and debug then dbug("debug ran command in gmsg_pms") end
	end

	if not result then
		if debug then dbug("debug entering gmsg_coppi") end
		result = gmsg_coppi()
		if result and debug then dbug("debug ran command in gmsg_coppi") end
	end

	if not chatvars.restrictedCommand then
		igplayers[chatvars.playerid].restrictedCommand = false
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if result then
		-- a command matched and was executed so stop processing it
		botman.faultyChat = false
		botman.faultyChat2 = false
		return
	end

	if (string.sub(chatvars.command, 1, 1) == server.commandPrefix) and (chatvars.playername ~= "Server") and not result then  -- THIS COMMAND MUST BE LAST OR IT STOPS SLASH COMMANDS BELOW IT WORKING.
		pname = nil
		pname = string.sub(chatvars.command, 2)
		pname = string.trim(pname)

		id = LookupPlayer(pname)

		if (players[chatvars.playerid].prisoner or not players[chatvars.playerid].canTeleport) then
			botman.faultyChat = false
			result = true
			return
		end

		if (id ~= nil) then
	if (debug) then dbug("id = " .. id) end

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
				result = true
				return
			end

			-- reject if not an admin and player to player teleporting has been disabled
			if tonumber(chatvars.accessLevel) > 2 and not server.allowPlayerToPlayerTeleporting then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleporting to friends has been disabled on this server.[-]")
				botman.faultyChat = false
				result = true
				return
			end

			-- reject if not an admin or a friend
			if (not isFriend(id,  chatvars.playerid)) and (chatvars.accessLevel > 2) and (id ~= chatvars.playerid) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only friends of " .. players[id].name .. " and staff can do this.[-]")
				botman.faultyChat = false
				result = true
				return
			end

			-- if pvpZone(players[id].xPos, players[id].zPos) and chatvars.accessLevel > 2 then
				-- message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not allowed to teleport to players in PVP zones.[-]")
				-- botman.faultyChat = false
				-- result = true
				-- return
			-- end

			if not igplayers[id] and chatvars.accessLevel > 2 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is offline at the moment.  You will have to wait till they return or start walking.[-]")
				botman.faultyChat = false
				result = true
if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
				return
			end

			if math.floor(players[id].xPos) == 0 and math.floor(players[id].yPos) == 0 and math.floor(players[id].zPos) == 0 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has not played here since the last map wipe.[-]")
				botman.faultyChat = false
				return
			end

			-- teleport to a friend if sufficient zennies
			if tonumber(server.teleportCost) > 0 and (chatvars.accessLevel > 2) then
				if tonumber(players[chatvars.playerid].cash) < tonumber(server.teleportCost) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You do not have enough " .. server.moneyPlural .. ".  Kill some zombies, gamble, trade or beg to earn more.[-]")
					botman.faultyChat = false
					result = true
if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
					return
				end
			end

			-- first record the current x y z
			players[chatvars.playerid].xPosOld = chatvars.intX
			players[chatvars.playerid].yPosOld = chatvars.intY
			players[chatvars.playerid].zPosOld = chatvars.intZ
			igplayers[chatvars.playerid].lastLocation = ""

			-- then teleport to the friend
			cmd = "tele " .. chatvars.playerid .. " " .. math.floor(players[id].xPos) .. " " .. math.ceil(players[id].yPos) .. " " .. math.floor(players[id].zPos)

			players[chatvars.playerid].cash = tonumber(players[chatvars.playerid].cash) - server.teleportCost

			if tonumber(server.playerTeleportDelay) == 0 or not igplayers[chatvars.playerid].currentLocationPVP or tonumber(players[chatvars.playerid].accessLevel) < 2 then
				if teleport(cmd, chatvars.playerid) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have teleported to " .. players[id].name .. "'s location.[-]")
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You will be teleported to " .. players[id].name .. "'s location in " .. server.playerTeleportDelay .. " seconds.[-]")
				if botman.dbConnected then conn:execute("insert into miscQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + server.playerTeleportDelay) .. "')") end
			end

			botman.faultyChat = false
			result = true
if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end
			return
		end
	end

	if (debug) then dbug("debug chat line " .. debugger.getinfo(1).currentline) end

	if chatvars.words[1] == "register" and chatvars.words[2] == "help" then
		botman.registerHelp	= false
		result = true
	end

	if chatvars.words[1] == "register" and chatvars.words[2] == "commands" then
		botman.registerCommands	= false
		result = true
	end

	if not result then
		if (string.sub(chatvars.command, 1, 1) == server.commandPrefix) then
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

	botman.faultyChat = false
	botman.faultyChat2 = false

	if debug then dbug("gmsg end") end
end
