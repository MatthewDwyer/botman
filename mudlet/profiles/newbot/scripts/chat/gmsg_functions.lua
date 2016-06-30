--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug


function nextReboot(steam)
	local timeRemaining, diff, days, hours, minutes, seconds

	if not server.allowReboot then
		if steam == nil then
			message("say [" .. server.chatColour .. "]Server reboots are not managed by me at the moment.[-]")
		else
			if igplayers[steam] then
				message("pm " .. steam .. " [" .. server.chatColour .. "]Server reboots are not managed by me at the moment.[-]")
			end
			
			irc_QueueMsg(players[steam].ircAlias, "Server reboots are not managed by me at the moment.")
		end
			
		return
	end
	
	if server.scheduledRestartTimestamp == nil then
		server.scheduledRestartTimestamp = os.time()
	end
	
	if tonumber(gameTick) < 0 then
		if steam == nil then
			message("say [" .. server.chatColour .. "]The server needs a reboot now to fix a fault.[-]")
		else
			if igplayers[steam] then
				message("pm " .. steam .. " [" .. server.chatColour .. "]The server needs a reboot now to fix a fault.[-]")
			end
			
			irc_QueueMsg(players[steam].ircAlias, "The server needs a reboot now to fix a fault.")
		end	
	else
		if server.scheduledRestartTimestamp > os.time() or scheduledRestartPaused then
			if scheduledRestartPaused then
				timeRemaining = restartTimeRemaining
			else
				timeRemaining = server.scheduledRestartTimestamp - os.time()
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

		if scheduledRestartPaused then
			if steam == nil then
				message("say [" .. server.chatColour .. "]The reboot is paused at the moment. When it is resumed, the reboot will happen in " .. string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) ..":" .. string.format("%02d", seconds) .. "[-]")
			else
				if igplayers[steam] then
					message("pm " .. steam .. " [" .. server.chatColour .. "]The reboot is paused at the moment. When it is resumed, the reboot will happen in " .. string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) ..":" .. string.format("%02d", seconds) .. "[-]")
				end
				
				irc_QueueMsg(players[steam].ircAlias, "The reboot is paused at the moment. When it is resumed, the reboot will happen in " .. string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) ..":" .. string.format("%02d", seconds))
			end
		else		
			if steam == nil then
				message("say [" .. server.chatColour .. "]The next reboot is in " .. days .. " days " .. string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) ..":" .. string.format("%02d", seconds) .. "[-]")
			else
				if igplayers[steam] then
					message("pm " .. steam .. " [" .. server.chatColour .. "]The next reboot is in " .. days .. " days " .. string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) ..":" .. string.format("%02d", seconds) .. "[-]")
				end
				
				irc_QueueMsg(players[steam].ircAlias, "The next reboot is in " .. days .. " days " .. string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) ..":" .. string.format("%02d", seconds))
			end
		end
	end
end


function baseStatus(command, playerid)
	local pname
	local id
	local protected
	local base

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

	message("pm " .. playerid .. " [" .. server.chatColour .. "]You have " .. players[id].cash .. " zennies in the bank.[-]")

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
	message("pm " .. playerid .. " [" .. server.chatColour .. "]Protection size is " .. players[id].protectSize .. " meters from the /base teleport[-]")

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
		message("pm " .. playerid .. " [" .. server.chatColour .. "]Protection size is " .. players[id].protect2Size .. " meters from the /base2 teleport[-]")

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

	if (pvpZone(igplayers[playerid].xPos, igplayers[playerid].zPos) ~= false) then
		return
	end

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
	message("pm " .. playerid .. " [" .. server.chatColour .. "]You are in region r." .. x .. "." .. z .. ".7rg[-]")

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

						message("pm " .. playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%d", dist) .. " region r." .. x .. "." .. z .. ".7rg[-]")
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


function logChat(chatTime, chatOwner, chatLine)
	if botDisabled or server.webdavFolderWriteable == false then
		return
	end

	-- flag the webdav folder as not writeable.  If the code below succeeds, we'll flag it as writeable so we can skip writing the chat log next time around.
	-- If we can't write the log and we keep trying to, the bot won't be able to respond to any commands since we're writing to the log before processing the chat much.
	server.webdavFolderWriteable = false
	
	if not (string.find(line, " command 'pm") and string.find(line, "' from client")) then
		-- log the chat
		file = io.open("/var/www/webdav/chatlogs/" .. webdavFolder .. "/" .. os.date("%Y%m%d") .. "_chatlog.txt", "a")
		file:write(chatTime .. " " .. chatOwner .. ": " .. string.trim(chatLine) .. "\n")
		file:close()
	end
	
	server.webdavFolderWriteable = true
end


function gmsg(line, ircid)
	local result, x, z, id, pname, debug, noWaypoint, temp, chatStringStart
	
	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false
	
	if debug then 
		dbug("gmsg " .. line) 

		if ircid ~= nil then
			dbug("ircid " .. ircid)
		end
	end
	
	noWaypoint = false
	chatStringStart = ""
	chatvars = {}
	chatvars.timestamp = os.time()
	
	ExceptionCount = 0
	chatvars.gmsg = line
	chatvars.oldLine = line
	chatvars.playerid = 0
	chatvars.accessLevel = 99
	chatvars.command = line
	
	if ircid ~= nil then
		chatvars.ircid = ircid
		
		if tonumber(ircid) > 0 then
			chatvars.accessLevel = accessLevel(ircid)
		else
			chatvars.accessLevel = 0
		end
	end
	
	if debug then dbug("gmsg chatvars.accessLevel " .. chatvars.accessLevel) end
	
	-- suppress INF Chat if using Ubex
	 if string.find(line, "INF Chat: ") and server.ubex then
		 if debug then dbug("gmsg INF Chat ignored") end
		 faultyChat = false
		 return
	 end
	
	if string.find(line, "INF Chat: ") or string.find(line, "INF GMSG: ") or string.find(line, "INF Chat command") then
		chatvars.chatline = string.split(chatvars.gmsg, ":")
	end
	
	 if string.find(line, "HOOK SUCCESS") then
		 chatvars.chatline = string.split(chatvars.gmsg, ";")
	 end

	if string.find(line, "INF Chat: ") then
		chatStringStart = "Chat"
		temp = string.split(chatvars.command, ":")
		display(temp)
		chatvars.command = string.trim(temp[5])
		chatvars.playername = stripQuotes(string.trim(temp[4]))
		chatvars.playerid = LookupPlayer(chatvars.playername)
		
		dbug("chatvars.command " .. chatvars.command)
		
		if string.find(line, "-irc: ") then	
			chatvars.command = stripQuotes(temp[2] .. ":" .. string.trim(temp[3]))
		else
			if string.sub(temp[2], 1, 1) == "/" then
				chatvars.command = stripQuotes(string.trim(temp[5]))
			end
		end
	end
	
	if string.find(line, "INF Chat command") then
		chatStringStart = "Chat"
		temp = string.split(chatvars.command, ":")
		display(temp)
		chatvars.command = string.trim(temp[4])
		chatvars.playername = string.sub(temp[3], string.find(temp[3], " from ") + 7)
		chatvars.playername = stripQuotes(string.trim(chatvars.playername))
		chatvars.playerid = LookupPlayer(chatvars.playername)
		
		dbug("chatvars.playername " .. chatvars.playername)
		dbug("chatvars.command " .. chatvars.command)
		dbug("chatvars.playerid " .. chatvars.playerid)
		
		if string.find(line, "-irc: ") then	
			chatvars.command = stripQuotes(temp[2] .. ":" .. string.trim(temp[3]))
		else
			if string.sub(temp[2], 1, 1) == "/" then
				chatvars.command = stripQuotes(string.trim(temp[4]))
			end
		end
	end
	
	if string.find(line, "INF GMSG: ") then
		chatStringStart = "GMSG"
	end

	 if server.ubex and string.find(line, "HOOK SUCCESS") then
		 chatStringStart = "msg"
		 chatvars.command = stripQuotes(string.match(line,  "msg=(.*)$"))
		 chatvars.playername = stripQuotes(string.match(chatvars.chatline[1],  "name=(.*)$"))
		 chatvars.playerid = stripQuotes(string.match(chatvars.chatline[2],  "id=(.*)$"))
	 end
	
	if chatStringStart == "" then
		chatvars.command = line
		chatvars.playername = "Server"
		line = "Server: " .. line
	end

	if (faultyChat == nil) then faultyChat = false end
	if (faultyChat2 == nil) then faultyChat2 = false end
	if faultyChat2 then fixMissingStuff() end
	faultyChat2 = true

	if (faultyChat == true) then
		cecho(server.windowDebug, "!! Fault detected in Chat\n")
		cecho(server.windowDebug, faultyLine .. "\n")
		if (faultyChatCommand ~= nil) then cecho(server.windowDebug, "!! Fault occurred in command: " .. faultyChatCommand .. "\n") end
		faultyChat = false
	end

	if debug then dbug("gmsg 1") end

	faultyLine = line
	faultyChat = true

	if debug then dbug("gmsg 2") end

	if string.find(line, " command 'pm") and not string.find(line, "' from client") then
		faultyChat = false
		return
	end

	if string.find(line, " command 'pm") and string.find(line, "' from client") then
		msg = string.sub(line, string.find(line, "command 'pm") + 12, string.find(line, "' from client") - 1)
		id = string.sub(line, string.find(line, "from client ") + 12) 
		chatvars.playerid = LookupPlayer(id, "all")
		
		chatvars.playername = players[id].name
		chatvars.command = msg
		chatvars.accessLevel = accessLevel(id)

		cecho(server.windowGMSG, chatvars.playername .. ": " .. msg .. "\n")
		irc_QueueMsg(server.ircWatch, gameDate .. " " .. chatvars.playername .. ": " .. msg)
	else
		cecho(server.windowGMSG, chatvars.playername .. ": " .. chatvars.command .. "\n")
		lastIRC = gameDate .. " " .. chatvars.command
	
		if string.len(chatvars.command) > 200 then
			temp = chatvars.playername .. ": " .. string.sub(chatvars.command, 1, 200)
			temp = string.gsub(temp, "%[[%/%!]-[^%[%]]-]", "")
		
			irc_QueueMsg(server.ircMain, gameDate .. " " .. temp)
			
			temp = string.sub(chatvars.command, 201)
			temp = string.gsub(temp, "%[[%/%!]-[^%[%]]-]", "")
			
			irc_QueueMsg(server.ircMain, gameDate .. " " .. temp)
		else
			irc_QueueMsg(server.ircMain, gameDate .. " " .. chatvars.playername .. ": " .. string.gsub(chatvars.command, "%[[%/%!]-[^%[%]]-]", ""))
		end
		
		if (string.find(chatvars.gmsg, "'Server':")) then
			chatvars.playername = "Server"
			faultyChat = false
		end
	end
	
	logChat(serverTime, chatvars.playername, chatvars.command)

	if debug then dbug("gmsg 3") end

	-- don't process any chat coming from irc or death messages
	if string.find(chatvars.gmsg, "-irc:", nil, true) or (chatvars.playername == "Server" and string.find(chatvars.gmsg, "died")) then
		faultyChat = false
		return
	end

	--deleteLine()

	faultyChatCommand = chatvars.command

	if debug then
		cecho(server.windowDebug, "chatvars.playername " .. chatvars.playername .. "\n")
		cecho(server.windowDebug, "command " .. chatvars.command .. "\n")
	end

	-- ignore game messages
	if (chatvars.playername ~= "Server") and chatvars.playerid == nil then
		faultyChat = false
		return
	end

	if debug then dbug("gmsg 4") end

	if (chatvars.playername ~= "Server") then

		if not igplayers[chatvars.playerid] then
			faultyChat = false
			return
		end

		chatvars.intX = math.floor(igplayers[chatvars.playerid].xPos)
		chatvars.intY = math.ceil(igplayers[chatvars.playerid].yPos)
		chatvars.intZ = math.floor(igplayers[chatvars.playerid].zPos)
		chatvars.accessLevel = accessLevel(chatvars.playerid)

		x = math.floor(chatvars.intX / 512)
		z = math.floor(chatvars.intZ / 512)
		chatvars.region = "r." .. x .. "." .. z .. ".7rg"
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

	if debug then dbug("gmsg 5") end

	chatvars.words = {}
	chatvars.wordsOld = {}

	for word in chatvars.command:gmatch("%S+") do 
		table.insert(chatvars.words, string.lower(word))
		table.insert(chatvars.wordsOld, word) 
	end

	chatvars.wordCount = table.maxn(chatvars.words)
	chatvars.command = string.lower(chatvars.command)

	if (string.sub(chatvars.words[1], 1, 1) == "/") then
		chatvars.words[1] = string.sub(chatvars.words[1], 2, string.len(chatvars.words[1]))
	end

	chatvars.number = tonumber(string.match(chatvars.command, " (-?%d+)")) -- (-?\%d+)
	result = false
	
	if ircid ~= nil and ((chatvars.words[1] == "command" or chatvars.words[1] == "list") and chatvars.words[2] == "help" or chatvars.words[1] == "help") then
		chatvars.showHelp = true
	end

	if debug then dbug("gmsg 6") end

	if not result and (chatvars.playername ~= "Server") then
		if players[chatvars.playerid].lastCommand ~= nil then
			-- don't allow /stuck being spammed
			if players[chatvars.playerid].lastCommand == chatvars.command then
				if (string.sub(chatvars.command, 1, 1) == "/") then
					if math.abs(players[chatvars.playerid].lastCommandTimestamp - os.time()) < 3 then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Please don't spam commands.[-]")
						faultyChat = false
						result = true			
						return
					end
				end
			end
		end
	end

	if debug then dbug("gmsg 7") end

	if not result then	
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reload"))) or chatvars.words[1] ~= "help" then
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "/reload code")	
				
				if not shortHelp then
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "Tell the bot to reload all external Lua scripts.  This also happens shortly after restarting the bot and it can automatically detect if the scripts are not loaded and reload them.")
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "Once the script have loaded, if you make any changes to them you need to run this command or restart the bot for your changes to take effect.")
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "")
				end
			end
		end

		if chatvars.words[1] == "reload" and string.find(chatvars.command, "code") or string.find(chatvars.command, "script") then
			if (chatvars.playername ~= "Server") then 
				if (accessLevel(chatvars.playerid) > 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")		
					faultyChat = false
					result = true
				end
			else
				if (accessLevel(chatvars.ircid) > 1) then
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "This command is restricted.")
					faultyChat = false
					result = true
				end
			end

			enableTimer("ReloadScripts")

			faultyChat = false
			result = true
		end
	end
	
	if not result then
		if debug then dbug("debug entering gmsg_unslashed") end
		result = gmsg_unslashed()
		if result and debug then dbug("debug ran command in gmsg_unslashed") end
	end
	
	if not result then
		if debug then dbug("debug entering gmsg_info") end
		result = gmsg_info()
		if result and debug then dbug("debug ran command in gmsg_info") end
	end
	
	if debug then dbug("gmsg 8") end
	
	if (chatvars.playername ~= "Server") then
		if accessLevel(chatvars.playerid) > 2 then	
			test = string.sub(line, string.find(line, chatStringStart) + 6)
			temp = test:match("(%d+.%d+.%d+.%d+)")

			if test:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%:(%d+)") and not whitelistedServers[temp] then
				message("say [" .. server.chatColour .. "]Do not advertise other servers! The offender has been given a temporary ban and this offense has been reported.[-]")		

				banPlayer(chatvars.playerid, "1 hour", "Advertising another server in public chat.", "")
				messageAdmins("Banned player " .. players[chatvars.playerid].name .. " 1 hour for advertising another server in chat.")

				irc_QueueMsg(server.ircAlerts, gameDate .. " Banned player " .. chatvars.playerid .. " " .. players[chatvars.playerid].name .. " 1 hour for advertising another server in chat.")

				faultyChat = false
				result = true
			end
		end


		if chatvars.words[1] == "hardcore" and chatvars.words[2] == "mode" and (chatvars.words[3] == "off" or chatvars.words[3] == "disable" or string.sub(chatvars.words[3], 1, 2) == "de") then
			players[chatvars.playerid].silentBob = false
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will help you.[-]")		
			faultyChat = false
			result = true
		end


		if chatvars.words[1] == "hardcore" and chatvars.words[2] == "mode" and (chatvars.words[3] == "on" or chatvars.words[3] == "enable" or chatvars.words[3] == "activate") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will not help you.[-]")		
			players[chatvars.playerid].silentBob = true
			faultyChat = false
			result = true
		end


		if players[chatvars.playerid].silentBob == true or (server.hardcore == true and tonumber(chatvars.accessLevel) > 2) then
			result = true
			faultyChat = false
			return
		end
	end
	
	if debug then dbug("gmsg 9") end
	
	if not result then
		if not result and debug then dbug("debug entering gmsg_custom") end
		result = gmsg_custom()
		if result and debug then dbug("debug ran command in gmsg_custom") end
	end
	
	-- If you want to override any commands in the sections below, create commands in gmsg_custom.lua or call them from within it making sure to match the commands keywords.

	if not result then
		if debug then dbug("debug entering gmsg_fun") end
		result = gmsg_fun()
		if result and debug then dbug("debug ran command in gmsg_fun") end
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

	if not result and server.allowShop then
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
		if debug then dbug("debug enterinfg gmsg_villages") end
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
	
	if not result and (server.coppi or server.ubex) then
		if debug then dbug("debug entering gmsg_coppi_ubex") end
		result = gmsg_coppi_ubex()
		if result and debug then dbug("debug ran command in gmsg_coppi_ubex") end
	end

	if (string.sub(chatvars.command, 1, 1) == "/") and (chatvars.playername ~= "Server") then
		players[chatvars.playerid].lastCommand = chatvars.command
		players[chatvars.playerid].lastCommandTimestamp = os.time()
	end

	if debug then dbug("gmsg 10") end

	if (string.sub(chatvars.command, 1, 1) == "/") and (chatvars.playername ~= "Server") and not result then  -- THIS COMMAND MUST BE LAST OR IT STOPS SLASH COMMANDS BELOW IT WORKING.
		pname = nil
		pname = string.sub(chatvars.command, 2)
		pname = string.trim(pname)

		id = LookupPlayer(pname)

		if (players[chatvars.playerid].prisoner or not players[chatvars.playerid].canTeleport) then
			faultyChat = false
			result = true
			return
		end

		if (id ~= nil) then 
			-- reject if not an admin or a friend
			if (not isFriend(id,  chatvars.playerid)) and (accessLevel(chatvars.playerid) > 2) and (id ~= chatvars.playerid) then --  and (id ~= chatvars.playerid)
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only friends of " .. players[id].name .. " and staff can do this.[-]")

				faultyChat = false
				result = true
				return
			end

			if (tonumber(players[id].waypointX) ~= 0 and tonumber(players[id].waypointY) ~= 0 and tonumber(players[id].waypointZ) ~= 0) and (players[id].shareWaypoint == true or accessLevel(chatvars.playerid) < 3) then
				-- first record the current x y z
				players[chatvars.playerid].xPosOld = chatvars.intX
				players[chatvars.playerid].yPosOld = chatvars.intY
				players[chatvars.playerid].zPosOld = chatvars.intZ
				igplayers[chatvars.playerid].lastLocation = ""

				-- then teleport to the shared waypoint
				cmd = "tele " .. chatvars.playerid .. " " .. players[id].waypointX .. " " .. players[id].waypointY .. " " .. players[id].waypointZ

				if players[chatvars.playerid].watchPlayer then
					irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
				end

				prepareTeleport(chatvars.playerid, cmd)
				teleport(cmd)
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have teleported to " .. players[id].name .. "'s waypoint.[-]")

				faultyChat = false
				result = true
				return
			else
				noWaypoint = true
			end

			-- teleport to a friend if sufficient zennies
			if tonumber(players[chatvars.playerid].tokens) > 0 or accessLevel(chatvars.playerid) < 3 then
				-- first record the current x y z
				players[chatvars.playerid].xPosOld = chatvars.intX
				players[chatvars.playerid].yPosOld = chatvars.intY
				players[chatvars.playerid].zPosOld = chatvars.intZ
				igplayers[chatvars.playerid].lastLocation = ""

				-- then teleport to the friend
				cmd = "tele " .. chatvars.playerid .. " " .. math.floor(players[id].xPos-1) .. " " .. math.ceil(players[id].yPos) .. " " .. math.floor(players[id].zPos)

				if players[chatvars.playerid].watchPlayer then
					irc_QueueMsg(server.ircTracker, gameDate .. " " .. chatvars.playerid .. " " .. chatvars.playername .. " command " .. chatvars.command  )
				end

				prepareTeleport(chatvars.playerid, cmd)
				teleport(cmd)

				if accessLevel(chatvars.playerid) > 2 then
					players[chatvars.playerid].tokens = players[chatvars.playerid].tokens - 1
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have teleported to " .. players[id].name .. "'s location at a cost of 1 P2P token.[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have teleported to " .. players[id].name .. "'s location.[-]")
				end

				faultyChat = false
				result = true
				return
			end

			if noWaypoint then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " does not have an open waypoint. They need to type /open waypoint.[-]")
				faultyChat = false
				result = true
				return
			end
		end
	end

	if debug then dbug("gmsg 11") end

	if not result then
		if (string.sub(chatvars.command, 1, 1) == "/") then
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Unknown command: " .. chatvars.command .. " Type /help or /commands for commands.[-]")
			else
				if not chatvars.showHelp then
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "Unknown command")
				end
			end
		else
			Translate(chatvars.playerid, chatvars.command, "")
		end
	end

	faultyChat = false
	faultyChat2 = false

	if debug then dbug("gmsg end") end
end
