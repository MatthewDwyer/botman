--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

-- magic characters in Lua  ( ) . % + - * ? [ ^ $
-- these must be escaped with a %  eg string.split(line, "%.")

-- stuff for the future
-- https://terralang.org
-- https://labix.org/lunatic-python
-- https://github.com/bastibe/lunatic-python

local debug

if botman.debugAll then
	debug = true -- this should be true
end


function serverShutdown()
	irc_chat(server.ircMain, "The server has shut down.")
	botman.gameStarted = false
	botman.telnetOffline = true
	botman.APIOffline = true
	toggleTriggers("api offline")
	botman.botOffline = true
	botman.playersOnline = 0
	server.uptime = 0
	server.serverStartTimestamp = os.time()
	anticheatBans = {}
	saveLuaTables()
end


function generatePassword(length)
	local i, a, b, pass

	pass = ""

	for i=1,length,1 do
		a = randSQL(3)

		if a == 1 then
			b = randSQL(10) + 47
		end

		if a == 2 then
			b = randSQL(26) + 64
		end

		if a == 3 then
			b = randSQL(26) + 96
		end

		pass = pass .. string.char(b)
	end

	return pass
end


function processBotmanConfig()
	local k, v, bmconfig, tmp, numbers
	local Configs, CustomMessages, ResetRegions, ZombieAnnouncer, Zones, ExemptPrefabs, ResetAreas, Milestones
	local readConfigs, readCustomMessages, readResetRegions, readZombieAnnouncer, readZones, readExemptPrefabs, readResetAreas, readMilestones
	local cursor, errorString

	readConfigs = false
	readCustomMessages = false
	readResetRegions = false
	readResetAreas = false
	readZombieAnnouncer = false
	readZones = false
	readExemptPrefabs = false
	readMilestones = false

	bmconfig = {}
	Configs = {}
	CustomMessages = {}
	ResetRegions = {}
	ResetAreas = {}
	ZombieAnnouncer = {}
	Zones = {}
	ExemptPrefabs = {}
	Milestones = {}

	for k,v in pairs(botman.config) do
		if readConfigs then
			if string.find(v, "config name=\"allocs_web_file") then
				Configs.mapJS = string.sub(v, string.find(v, "location=") + 10, string.find(v, "map.js\"/>", nil, true) - 3)
			end

			if string.find(v, "config name=\"anticheat") then
				-- <config name="anticheat" enabled="True" />
				Configs.anticheat = {}

				if string.find(v, "True") then
					Configs.anticheat.enabled = true
				else
					Configs.anticheat.enabled = false
				end

				modBotman.anticheat = Configs.anticheat
			end

			if string.find(v, "config name=\"botname") then
				 -- <config name="botname" text="[7FFF00]Devbot" color-public="ffffff" color-private="EA3257" />
				tmp = {}
				tmp.name = string.sub(v, string.find(v, "text") + 6, string.find(v, "color-public", nil, true) - 3)
				tmp.colorpublic = string.sub(v, string.find(v, "color-public", nil, true) + 14, string.find(v, "color-private", nil, true) - 3)
				tmp.colorprivate = string.sub(v, string.find(v, "color-private", nil, true) + 16, string.find(v, "/>") - 3)

				Configs.botname = {}
				Configs.botname.name = tmp.name
				Configs.botname.colorpublic = tmp.colorpublic
				Configs.botname.colorprivate = tmp.colorprivate

				modBotman.botName = Configs.botname.name
				server.botName = stripBBCodes(Configs.botname.name)
			end

			if string.find(v, "config name=\"chatcommands") then
				-- <config name="chatcommands" prefix="/" hide="False" />
				tmp = {}
				tmp.pos = string.find(v, "prefix") + 8
				tmp.prefix = string.sub(v, tmp.pos, tmp.pos)

				if string.find(v, "True") then
					tmp.hide = true
				else
					tmp.hide =  false
				end

				Configs.chatcommands = {}
				Configs.chatcommands.prefix = tmp.prefix
				Configs.chatcommands.hide = tmp.hide

				server.commandPrefix = Configs.chatcommands.prefix
				server.hideCommands = Configs.chatcommands.hide
			end

			if string.find(v, "config name=\"clans") then
				-- <config name="clans" enabled="False" max_clans="10" max_players="5" required_level_to_create="25" />
				Configs.clans = {}

				if string.find(v, "True") then
					Configs.clans.enabled = true
				else
					Configs.clans.enabled = false
				end

				tmp = {}
				tmp.numbers = getNumbers(v)
				Configs.clans.max_clans = tmp.numbers[1]
				Configs.clans.max_players = tmp.numbers[2]
				Configs.clans.required_level_to_create = tmp.numbers[3]
			end

			if string.find(v, "config name=\"custommessages") then
				-- <config name="custommessages" enabled="False" />
				if string.find(v, "True") then
					Configs.custommessages = true
				else
					Configs.custommessages = false
				end
			end

			if string.find(v, "config name=\"chat_level_prefix") then
				-- <config name="chat_level_prefix" enabled="True" color="ff0000"/>
				Configs.chat_level_prefix = {}

				if string.find(v, "True") then
					Configs.chat_level_prefix.enabled = true
				else
					Configs.chat_level_prefix.enabled = false
				end

				Configs.chat_level_prefix.color = string.sub(v, string.find(v, "color") + 7, string.find(v, "/>") - 3)
			end

			if string.find(v, "config name=\"level_achievement_reward") then
				-- <config name="level_achievement_reward" enabled="True" dukes="1000" max_level="10" />
				Configs.level_achievement_reward = {}

				if string.find(v, "True") then
					Configs.level_achievement_reward.enabled = true
				else
					Configs.level_achievement_reward.enabled = false
				end

				Configs.level_achievement_reward.dukes = string.sub(v, string.find(v, "dukes") + 7, string.find(v, "max_level") - 3)
				Configs.level_achievement_reward.max_level = string.sub(v, string.find(v, "max_level") + 11, string.find(v, "/>") - 3)
			end

			if string.find(v, "config name=\"milestones") then
				-- <config name="milestones" enabled="True" />
				Configs.milestones = {}

				if string.find(v, "True") then
					Configs.milestones.enabled = true
				else
					Configs.milestones.enabled = false
				end
			end

			if string.find(v, "config name=\"dropminer") then
				-- <config name="dropminer" enabled="False" />
				Configs.dropminer = {}

				if string.find(v, "True") then
					Configs.dropminer.enabled = true
				else
					Configs.dropminer.enabled = false
				end
			end

			if string.find(v, "config name=\"lcbprefabrule") then
				-- <config name="lcbprefabrule" enabled="True" distance="25" />
				Configs.lcbprefabrule = {}

				if string.find(v, "True") then
					Configs.lcbprefabrule.enabled = true
				else
					Configs.lcbprefabrule.enabled = false
				end

				Configs.lcbprefabrule.distance = tonumber(string.match(v, "(-?%d+)"))
			end

			if string.find(v, "config name=\"resetallprefabs") then
				-- <config name="resetallprefabs" enabled="False" days_between_resets="0"  />
				Configs.resetallprefabs = {}

				if string.find(v, "enabled=\"True") then
					Configs.resetallprefabs.enabled = true
				else
					Configs.resetallprefabs.enabled = false
				end

				Configs.resetallprefabs.days_between_resets = tonumber(string.match(v, "(-?%d+)"))
			end

			if string.find(v, "config name=\"resetareas") then
				-- <config name="resetareas" enabled="False" days_between_resets="3"  />
				Configs.resetareas = {}

				if string.find(v, "enabled=\"True") then
					Configs.resetareas.enabled = true
				else
					Configs.resetareas.enabled = false
				end

				Configs.resetareas.days_between_resets = tonumber(string.match(v, "(-?%d+)"))
			end

			if string.find(v, "config name=\"resetregions") then
				-- <config name="resetregions" enabled="True" prefabsonly="False" days_between_resets="0" remove_lcbs="True" />
				Configs.resetregions = {}

				if string.find(v, "enabled=\"True") then
					Configs.resetregions.enabled = true
				else
					Configs.resetregions.enabled = false
				end

				if string.find(v, "prefabsonly=\"True") then
					Configs.resetregions.prefabsonly = true
				else
					Configs.resetregions.prefabsonly = false
				end

				if string.find(v, "lcbs=\"True") then
					Configs.resetregions.remove_lcbs = true
				else
					Configs.resetregions.remove_lcbs = false
				end

				Configs.resetregions.days_between_resets = tonumber(string.match(v, "(-?%d+)"))
			end

			if string.find(v, "config name=\"vehiclefiledelete") then
				-- <config name="vehiclefiledelete" enabled="False" />
				Configs.vehiclefiledelete = {}

				if string.find(v, "True") then
					Configs.vehiclefiledelete.enabled = true
				else
					Configs.vehiclefiledelete.enabled = false
				end
			end

			if string.find(v, "config name=\"webmaptraceprefabs") then
				-- <config name="webmaptraceprefabs" enabled="False" color="00ff00" />
				Configs.webmaptraceprefabs = {}

				if string.find(v, "True") then
					Configs.webmaptraceprefabs.enabled = true
				else
					Configs.webmaptraceprefabs.enabled = false
				end

				Configs.webmaptraceprefabs.colour = string.sub(v, string.find(v, "color") + 7, string.find(v, "/>") - 4)
			end

			if string.find(v, "config name=\"webmaptracetraders") then
				-- <config name="webmaptracetraders" enabled="True" color="FF0000" />
				Configs.webmaptracetraders = {}

				if string.find(v, "True") then
					Configs.webmaptracetraders.enabled = true
				else
					Configs.webmaptracetraders.enabled = false
				end

				Configs.webmaptracetraders.colour = string.sub(v, string.find(v, "color") + 7, string.find(v, "/>") - 4)
			end

			if string.find(v, "config name=\"webmaptraceresetareas") then
				-- <config name="webmaptraceresetareas" enabled="False" color="FF4500"/>
				Configs.webmaptraceresetareas = {}

				if string.find(v, "True") then
					Configs.webmaptraceresetareas.enabled = true
				else
					Configs.webmaptraceresetareas.enabled = false
				end

				Configs.webmaptraceresetareas.colour = string.sub(v, string.find(v, "color") + 7, string.find(v, "/>") - 4)
			end

			if string.find(v, "config name=\"webmaptraceresetregions") then
				-- <config name="webmaptraceresetregions" enabled="True" color="FF4500"/>
				Configs.webmaptraceresetregions = {}

				if string.find(v, "True") then
					Configs.webmaptraceresetregions.enabled = true
				else
					Configs.webmaptraceresetregions.enabled = false
				end

				Configs.webmaptraceresetregions.colour = string.sub(v, string.find(v, "color") + 7, string.find(v, "/>") - 4)
			end

			if string.find(v, "config name=\"zombieannouncer") then
				-- <config name="zombieannouncer" enabled="False" />
				if string.find(v, "True") then
					Configs.zombieannouncer = true
				else
					Configs.zombieannouncer = false
				end
			end

			if string.find(v, "config name=\"zombiefreetime") then
				-- <config name="zombiefreetime" enabled="False" start="17" end="18" />
				Configs.zombiefreetime = {}

				if string.find(v, "True") then
					Configs.zombiefreetime.enabled = true
				else
					Configs.zombiefreetime.enabled = false
				end

				tmp = {}
				tmp.numbers = getNumbers(v)
				Configs.zombiefreetime.startTime = tmp.numbers[1]
				Configs.zombiefreetime.endTime = tmp.numbers[2]
			end

			if string.find(v, "config name=\"zones") then
				-- <config name="zones" enabled="False" />
				Configs.zones = {}

				if string.find(v, "True") then
					Configs.zones.enabled = true
				else
					Configs.zones.enabled = false
				end
			end
		end

		if readCustomMessages then
			-- <message name="login" name_color="[00FF00]" message_color="[FFFFFF]" message="[name] has joined the game." />
			if string.find(v, "message name=\"login") then
				tmp = {}
				tmp.name_color = string.sub(v, string.find(v, "name_color", nil, true) + 12, string.find(v, "message_color", nil, true) - 3)
				tmp.message_color = string.sub(v, string.find(v, "message_color", nil, true) + 15, string.find(v, "message=\"", nil, true) - 3)
				tmp.message = string.sub(v, string.find(v, "message=\"", nil, true) + 9, string.len(v) - 4)

				CustomMessages.login = {}
				CustomMessages.login.name_color = tmp.name_color
				CustomMessages.login.message_color = tmp.message_color
				CustomMessages.login.message = tmp.message
			end

			-- <message name="logout" name_color="[00FF00]" message_color="[FFFFFF]" message="[name] has logged out." />
			if string.find(v, "message name=\"logout") then
				tmp = {}
				tmp.name_color = string.sub(v, string.find(v, "name_color", nil, true) + 12, string.find(v, "message_color", nil, true) - 3)
				tmp.message_color = string.sub(v, string.find(v, "message_color", nil, true) + 15, string.find(v, "message=\"", nil, true) - 3)
				tmp.message = string.sub(v, string.find(v, "message=\"", nil, true) + 9, string.len(v) - 4)

				CustomMessages.logout = {}
				CustomMessages.logout.name_color = tmp.name_color
				CustomMessages.logout.message_color = tmp.message_color
				CustomMessages.logout.message = tmp.message
			end

			-- <message name="died" name_color="[00FF00]" message_color="[FFFFFF]" message="[name] has died." />
			if string.find(v, "message name=\"died") then
				tmp = {}
				tmp.name_color = string.sub(v, string.find(v, "name_color", nil, true) + 12, string.find(v, "message_color", nil, true) - 3)
				tmp.message_color = string.sub(v, string.find(v, "message_color", nil, true) + 15, string.find(v, "message=\"", nil, true) - 3)
				tmp.message = string.sub(v, string.find(v, "message=\"", nil, true) + 9, string.len(v) - 4)

				CustomMessages.died = {}
				CustomMessages.died.name_color = tmp.name_color
				CustomMessages.died.message_color = tmp.message_color
				CustomMessages.died.message = tmp.message
			end

			-- <message name="killed" killer_name_color="[FF0000]" victim_name_color="[0000FF]" message_color="[FFFFFF]" message="[killer] has killed [victim]." />
			if string.find(v, "message name=\"killed") then
				tmp = {}
				tmp.name_color = string.sub(v, string.find(v, "name_color", nil, true) + 12, string.find(v, "message_color", nil, true) - 3)
				tmp.message_color = string.sub(v, string.find(v, "message_color", nil, true) + 15, string.find(v, "message=\"", nil, true) - 3)
				tmp.message = string.sub(v, string.find(v, "message=\"", nil, true) + 9, string.len(v) - 4)

				CustomMessages.killed = {}
				CustomMessages.killed.name_color = tmp.name_color
				CustomMessages.killed.message_color = tmp.message_color
				CustomMessages.killed.message = tmp.message
			end
		end

		if readResetRegions then
			-- <Region type="manual" region="r.-4.-1" />
			if string.find(v, "Region type=\"", nil, true) then
				tmp = {}
				tmp.region_type = string.sub(v, string.find(v, "Region type=", nil, true) + 13, string.find(v, "region=", nil, true) - 3)
				tmp.region = string.sub(v, string.find(v, "region=", nil, true) + 8, string.len(v) - 4)
				tmp.temp = string.split(tmp.region, "%.")


				if resetRegions then
					if not resetRegions[tmp.region .. ".7rg"] then
						resetRegions[tmp.region .. ".7rg"] = {}
						resetRegions[tmp.region .. ".7rg"].x = tmp.temp[2]
						resetRegions[tmp.region .. ".7rg"].z = tmp.temp[3]
						resetRegions[tmp.region .. ".7rg"].inConfig = true

						if botman.dbConnected then conn:execute("INSERT INTO resetZones (region, x, z) VALUES ('" .. tmp.region .. ".7rg'," .. tmp.temp[2] .. "," .. tmp.temp[3] .. ")") end
					end
				end

				table.insert(ResetRegions, tmp)
			end
		end

		if readZombieAnnouncer then
			-- <entity name="zombiename" message="A Boss zombie has spawned at COORDS"/>
			if string.find(v, "entity name=", nil, true) then
				tmp = {}
				tmp.entity = string.sub(v, string.find(v, "name=", nil, true) + 6, string.find(v, "message=", nil, true) - 3)
				tmp.message = string.sub(v, string.find(v, "message=", nil, true) + 9, string.len(v) - 3)

				table.insert(ZombieAnnouncer, tmp)
			end
		end

		if readZones then
			-- <zone name="killzone" corner1="0,0,0" corner2="0,0,0" />
			if string.find(v, "zone name=\"", nil, true) then
				tmp = {}
				tmp.name = string.sub(v, string.find(v, "zone name=", nil, true) + 11, string.find(v, "corner1=", nil, true) - 3)
				tmp.corner1 = string.sub(v, string.find(v, "corner1=", nil, true) + 9, string.find(v, "corner2=", nil, true) - 3)
				tmp.corner2 = string.sub(v, string.find(v, "corner2=", nil, true) + 9, string.len(v) - 4)

				table.insert(Zones, tmp)
			end
		end

		if readExemptPrefabs then
			-- <prefab name="Prefab_Name_Here_01"/>
			if string.find(v, "prefab name=\"", nil, true) then
				tmp = {}
				tmp.prefab = string.sub(v, string.find(v, "prefab name=", nil, true) + 13, string.len(v) - 3)

				table.insert(ExemptPrefabs, tmp)
			end
		end

		if readResetAreas then
			-- <resetarea name="namehere" x1="0" z1="0" x2="10" z2="10" /> -->
			if string.find(v, "resetarea name=\"", nil, true) then
				tmp = {}
				tmp.name = string.sub(v, string.find(v, "resetarea name=", nil, true) + 16, string.find(v, "x1=", nil, true) - 5)
				tmp.numbers = getNumbers(v)
				tmp.x1 = tmp.numbers[1]
				tmp.z1 = tmp.numbers[2]
				tmp.x2 = tmp.numbers[3]
				tmp.z2 = tmp.numbers[4]
				tmp.numbers = nil

				table.insert(ResetAreas, tmp)
			end
		end

		if readMilestones then
			-- <milestone lvl="#" message="[playername] has reached [lvl]!!" />
			if string.find(v, "milestone lvl=\"", nil, true) then
				tmp = {}
				tmp.numbers = getNumbers(v)
				tmp.level = tmp.numbers[1]
				tmp.numbers = nil
				tmp.message = string.sub(v, string.find(v, "message=", nil, true) + 9, string.len(v) - 3)

				table.insert(Milestones, tmp)
			end
		end

		-- set read flags when we detect a new XML child
		if string.find(v, "<Configs>") then
			readConfigs = true
		end

		if string.find(v, "<CustomMessages>") then
			readCustomMessages = true
			readConfigs = false
		end

		if string.find(v, "<Milestones>") then
			readMilestones = true
			readCustomMessages = false
		end

		if string.find(v, "<ResetRegions>") then
			readResetRegions = true
			readCustomMessages = false
		end

		if string.find(v, "<ZombieAnnouncer>") then
			readZombieAnnouncer = true
			readResetRegions = false
		end

		if string.find(v, "<Zones>") then
			readZones = true
			readZombieAnnouncer = false
		end

		if string.find(v, "<ExemptPrefabs>") then
			readExemptPrefabs = true
			readZones = false
		end

		if string.find(v, "<ResetAreas>") then
			readResetAreas = true
			readExemptPrefabs = false
		end
	end

	botman.config = nil

	bmconfig = {}
	bmconfig.Configs = Configs
	bmconfig.CustomMessages = CustomMessages
	bmconfig.Milestones = Milestones
	bmconfig.ResetRegions = ResetRegions
	bmconfig.ResetAreas = ResetAreas
	bmconfig.ZombieAnnouncer = ZombieAnnouncer
	bmconfig.Zones = Zones
	bmconfig.ExemptPrefabs = ExemptPrefabs

	if botman.dbConnected then
		cursor, errorString = conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('config','panel','" .. escape(yajl.to_string(bmconfig)) .. "')")

		if errorString then
			if string.find(errorString, "Duplicate entry") then
				conn:execute("UPDATE webInterfaceJSON SET json = '" .. escape(yajl.to_string(bmconfig)) .. "' WHERE ident = 'config'")
			end
		end
	end
end


function disableTimers()
	disableTimer("EveryHalfMinute")
	disableTimer("OneMinuteTimer")
	disableTimer("listPlayers")
	disableTimer("OneHourTimer")
	disableTimer("Reconnect")
	disableTimer("GimmeReset")
	disableTimer("TimedCommands")
	disableTimer("ThirtyMinuteTimer")
	disableTimer("PlayerQueuedCommands")
	disableTimer("GimmeQueuedCommands")
	disableTimer("ircQueue")
	disableTimer("Every45Seconds")
	disableTimer("TrackPlayer")
	disableTimer("messageQueue")
	disableTimer("TwoMinuteTimer")
	disableTimer("Every15Seconds")
	disableTimer("Every10Seconds")
	disableTimer("five_minute_timer")
	disableTimer("ten_minute_timer")
	disableTimer("APITimer")
	disableTimer("EverySecond")
	disableTimer("Every5Seconds")
end


function enableTimers()
	enableTimer("EveryHalfMinute")
	enableTimer("OneMinuteTimer")
	enableTimer("listPlayers")
	enableTimer("OneHourTimer")
	enableTimer("Reconnect")
	-- don't enable GimmeReset
	enableTimer("TimedCommands")
	enableTimer("ThirtyMinuteTimer")
	enableTimer("PlayerQueuedCommands")
	enableTimer("GimmeQueuedCommands")
	enableTimer("Every45Seconds")
	-- don't enable TrackPlayer
	enableTimer("messageQueue")
	enableTimer("TwoMinuteTimer")
	enableTimer("Every15Seconds")
	enableTimer("Every10Seconds")
	enableTimer("five_minute_timer")
	enableTimer("ten_minute_timer")
	enableTimer("APITimer")
	enableTimer("EverySecond")
	enableTimer("Every5Seconds")
end


function testLogFolderWriteable()
	local file

	botman.webdavFolderWriteable = false

	-- log the chat
	file = io.open(botman.chatlogPath .. "/test.txt", "a")
	file:write("logging test\n")
	file:close()
	botman.webdavFolderWriteable = true
	os.remove(botman.chatlogPath .. "/test.txt")
end


function logDebug(line)
	local file

	-- log the debug
	file = io.open(homedir .. "/chatlogs/debug.txt", "a")
	file:write(line .. "\n")
	file:close()
end


function logHacker(incidentTime, hack)
	local file

	-- don't log if folder not writeable
	if not botman.webdavFolderWriteable then
		return
	end

	botman.webdavFolderWriteable = false

	-- log the chat
	file = io.open(botman.chatlogPath .. "/" .. os.date("%Y%m%d") .. "_hackers.txt", "a")
	file:write(incidentTime .. "; " .. string.trim(hack) .. "\n")
	file:close()

	botman.webdavFolderWriteable = true
end


function logAlerts(alertTime, alertLine)
	local file

	-- don't log base protection alerts
	if not botman.webdavFolderWriteable or string.find(alertLine, "base protection") then
		return
	end

	botman.webdavFolderWriteable = false

	-- log the chat
	file = io.open(botman.chatlogPath .. "/" .. os.date("%Y%m%d") .. "_alertlog.txt", "a")
	file:write(alertTime .. "; " .. string.trim(alertLine) .. "\n")
	file:close()

	botman.webdavFolderWriteable = true
end


function logBotCommand(commandTime, commandLine)
	local file

	if not commandLine then
		return
	end

	if (not botman.webdavFolderWriteable) or string.find(commandLine, "password") or string.find(commandLine, "invite code") or string.find(commandLine, "webtokens") or string.find(string.lower(commandLine), " api ") then
		return
	end

	if string.find(commandLine, "adminuser") then
		commandLine = string.sub(commandLine, 1, string.find(commandLine, "adminuser") - 2)
	end

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

	if server.botLoggingLevel == 3 or server.botLoggingLevel == 5 then
		return
	end

	commandPosition = "0 0 0"

	if chatvars.ircid ~= "0" then
		playerName = players[chatvars.ircid].name
	else
		if chatvars.intX then
			commandPosition = chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ
		end
	end

	if (not botman.webdavFolderWriteable) or string.find(commandLine, " INF ") or string.find(commandLine, "' from client") or string.find(commandLine, "password") or string.find(string.lower(commandLine), " api ") then
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

	if (not botman.webdavFolderWriteable) or string.find(chatLine, " INF ") or string.find(chatLine, "' from client") or string.find(chatLine, "password") or string.find(string.lower(chatLine), " api ") or chatvars == nil or string.trim(chatLine) == "Server" then
		return
	end

	chatPosition = "0 0 0"

	if chatvars.ircid ~= "0" then
		playerName = players[chatvars.ircid].name
	else
		if chatvars.intX then
			chatPosition = chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ
		end
	end

	-- flag the webdav folder as not writeable.  If the code below succeeds, we'll flag it as writeable so we can skip writing the chat log next time around.
	-- If we can't write the log and we keep trying to, the bot won't be able to respond to any commands since we're writing to the log before processing the chat much.
	botman.webdavFolderWriteable = false

	-- log the chat
	file = io.open(botman.chatlogPath .. "/" .. os.date("%Y%m%d") .. "_chatlog.txt", "a")
	file:write(chatTime .. "; " .. chatvars.playerid .. "; " .. playerName .. "; " .. chatPosition .. "; " .. string.trim(chatLine) .. "\n")
	file:close()

	botman.webdavFolderWriteable = true
end


function logInventoryChanges(steam, item, delta, x, y, z, session, flag)
	local file, location

	-- don't log if folder not writeable
	if not botman.webdavFolderWriteable then
		return
	end

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


function logPanelCommand(commandTime, command)
	local action, actionTable, actionQuery, actionArgs
	local file

	-- don't log if folder not writeable
	if not botman.webdavFolderWriteable then
		return
	end

	action = command.action

	if command.actionTable then
		actionTable = command.actionTable
	else
		actionTable = ""
	end

	if command.actionQuery then
		actionQuery = command.actionQuery
	else
		actionQuery = ""
	end

	if command.actionArgs then
		actionArgs = command.actionArgs
	else
		actionArgs = ""
	end

	botman.webdavFolderWriteable = false

	-- log the chat
	file = io.open(botman.chatlogPath .. "/" .. os.date("%Y%m%d") .. "_panel.txt", "a")
	file:write(commandTime .. "; " .. action .. "; " .. actionTable .. "; " .. actionArgs .. "; " .. actionQuery .. "\n")
	file:close()

	botman.webdavFolderWriteable = true
end


function logTelnet(line)
	if server.botLoggingLevel == 1 or tonumber(server.botLoggingLevel) > 3 then
		return
	end

	-- log telnet traffic to disk.  Mudlet can do this too but we need to roll our own since Mudlet no longer logs any lines we hide from the main Mudlet window.
	if not line then
		return
	end

	if string.find(line, "PUG:", nil, true) or string.find(line, "PGD:", nil, true) then
		return
	end

	if string.find(line, "WebCommandResult") or string.find(line, "Reloading Chunks") then
		return
	end

	if telnetLogFileName then
		telnetLogFile:write(line .. "\n")
	end
end


function writeToFile(file, output)
	if output == "." then
		output = ""
	else
		output = string.trim(output)
	end

	file:write(output .. "\n")
end


function setBlockTelnetSpam(state)
	botman.blockTelnetSpam = state
end


function blockTelnetSpam()
	if botman.blockTelnetSpam then
		deleteLine()
	end
end


function toggleTelnetSpam()
	botman.blockTelnetSpam = not botman.blockTelnetSpam
end


function helpCommandRestrictions(tmp)
	local temp = ""
	local command

	if helpCommands[tmp] then
		command = helpCommands[tmp]

		if command.accessLevel then
			temp = "ACL: " ..  command.accessLevel .. " restricted to "
		else
			temp = "Restricted to "
		end

		if command.accessLevel == 0 then
			temp = temp .. "server owners,"
		end

		if command.accessLevel == 1 then
			temp = temp .. "owners and admins,"
		end

		if command.accessLevel == 2 then
			temp = temp .. "owners, admins and mods,"
		end

		if tonumber(command.accessLevel) > 2 and tonumber(command.accessLevel) < 90 then
			temp = temp .. "custom admin level and above,"
		end

		if command.accessLevel == 90 then
			temp = temp .. "players and all admins,"
		end

		if command.accessLevel == 99 then
			temp = "Unrestricted command,"
		end

		if command.ingameOnly then
			temp = temp .. " in-game only"
		else
			temp = temp .. " in-game and IRC"
		end
	else
		return ""
	end

	return temp
end


function connectToAPI()
	server.useAllocsWebAPI = true
	botman.APIOffline = false
	toggleTriggers("api online")

	if not server.tempToken then
		server.tempToken = generatePassword(20)
	end

	server.allocsWebAPIPassword = server.tempToken
	conn:execute("UPDATE server set allocsWebAPIUser = 'bot', allocsWebAPIPassword = '" .. escape(server.allocsWebAPIPassword) .. "', useAllocsWebAPI = 1")
	send("webtokens add bot " .. server.allocsWebAPIPassword .. " 0")
end


function panelWho() --who? who?
	local whoIsOnline = {}

	for k, v in pairs(igplayers) do
		x = math.floor(v.xPos / 512)
		z = math.floor(v.zPos / 512)

		flags = ""
		line = ""
		sort = 999

		if isAdmin(k, v.userID) then
			flags = flags .. "admin"
			if sort == 999 then sort = 1 end
		end

		if players[k].newPlayer then
			if flags == "" then
				flags = "new player"
			else
				flags = flags .. ",new player"
			end

			if sort == 999 then sort = 3 end
		end

		if isDonor(k) then
			if flags == "" then
				flags = "donor"
			else
				flags = flags .. ",donor"
			end

			if sort == 999 then sort = 2 end
		end

		if players[k].prisoner then
			if flags == "" then
				flags = "prisoner"
			else
				flags = flags .. ",prisoner"
			end
		end

		if players[k].timeout then
			if flags == "" then
				flags = "timeout"
			else
				flags = flags .. ",timeout"
			end
		end

		if tonumber(players[k].hackerScore) > 0 then
			if flags == "" then
				flags = "hacking"
			else
				flags = flags .. ",hacking"
			end

			if v.flying then
				if flags == "" then
					flags = "flying"
				else
					flags = flags .. ",flying"
				end
			end

			if v.noclip then
				if flags == "" then
					flags = "clipping"
				else
					flags = flags .. ",clipping"
				end
			end

			if sort == 999 then sort = 0 end
		end

		whoIsOnline[k] = {}
		whoIsOnline[k].panelSortID = sort
		whoIsOnline[k].steam = k
		whoIsOnline[k].name = v.name
		whoIsOnline[k].country = players[k].country
		whoIsOnline[k].ping = v.ping
		whoIsOnline[k].gameID = v.id
		whoIsOnline[k].score = v.score
		whoIsOnline[k].pvpKills = v.playerKills
		whoIsOnline[k].zombies = v.zombies
		whoIsOnline[k].level = v.level
		whoIsOnline[k].inRegion = "r." .. x .. "." .. z .. ".7rg"
		whoIsOnline[k].inLocation = v.inLocation
		whoIsOnline[k].rank = flags
		whoIsOnline[k].coordX = v.xPos
		whoIsOnline[k].coordY = v.yPos
		whoIsOnline[k].coordZ = v.zPos
		whoIsOnline[k].hackerScore = players[k].hackerScore
	end

	--conn:execute("DELETE FROM webInterfaceJSON WHERE ident = 'playersOnline'")
	--conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('playersOnline','panel','" .. escape(yajl.to_string(whoIsOnline)) .. "')")
end


function newBotProfile()
	local file

	loadServer()

	if botman.botsConnected then
		connBots:execute("UPDATE servers SET IP = '" .. escape(server.IP) .. "' WHERE botID = " .. server.botID)
	end

	-- delete some Mudlet files that store IP and other info forcing Mudlet to regenerate them.
	os.remove(homedir .. "/ip")
	os.remove(homedir .. "/port")
	os.remove(homedir .. "/password")
	os.remove(homedir .. "/url")

	if getMudletVersion then
		os.execute("rm " .. homedir .. "/current/*")
		saveProfile() -- make a new profile using the old info incase the next save fails to happen.
		connectToServer(server.IP, server.telnetPort, true)
		saveProfile() -- make a new profile using the new info.  Mudlet uses the most recent file.
	else
		connectToServer(server.IP, server.telnetPort)
	end

	os.remove(homedir .. "/server_address.lua")
	file = io.open(homedir .. "/server_address.lua", "a")
	file:write("server.IP = \"" .. server.IP .. "\"\n")
	file:write("server.telnetPort = " .. server.telnetPort .. "\n")
	file:close()

	irc_chat(server.ircMain, "Connecting to new 7 Days to Die server " .. server.IP .. " port " .. server.telnetPort)
end


function forgetPlayers()
	local k, v

	connMEM:execute("DELETE FROM list")

	for k,v in pairs(staffList) do
		connMEM:execute("INSERT INTO list(steam) VALUES ('" .. k .. "')")
	end

	-- now that we have all of the steam id's of the admins in the list table we can use it to nuke other tables except for those id's
	conn:execute("DELETE FROM alerts WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM bases WHERE steam NOT IN (SELECT steam FROM list)")
	connSQL:execute("DELETE FROM bookmarks WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM friends WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM hotspots WHERE owner NOT IN (SELECT steam FROM list)")
	connSQL:execute("DELETE FROM keystones WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM players WHERE steam NOT IN (SELECT steam FROM list)")
	connSQL:execute("DELETE FROM players WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM villagers WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM waypoints WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("TRUNCATE events")
	conn:execute("TRUNCATE TABLE playersArchived")

	os.remove(homedir .. "/data_backup/players.lua")
	players = {}

	-- refresh the bot's Lua tables from the database tables
	loadTables()
end


function getMaxGimmePrizes()
	local cursor,errorString,row

	cursor,errorString = conn:execute("SELECT COUNT(name) AS totalPrizes FROM gimmePrizes")
	row = cursor:fetch({}, "a")
	return tonumber(row.totalPrizes)
end


function rewardServerVote(gameID)
-- todo: unfinished
	local i, r, quantity, quality

	if serverVoteReward == "entity" then
		sendCommand("se " .. gameID .. " " .. serverVoteRewardItem)
		return true
	end

	if serverVoteReward == "crate" then
		sendCommand("se " .. gameID .. " sc_General")

		return true
	end

	if serverVoteReward == "item" then
		if string.find(serverVoteRewardItem, "sc_") then
			sendCommand("se " .. gameID .. " " .. serverVoteRewardItem)
		else
			if server.botman then
				sendCommand("bm-give " .. gameID .. " " .. serverVoteRewardItem .. " 1 1")
			else
				sendCommand("give " .. gameID .. " " .. serverVoteRewardItem .. " 1 1")
			end
		end

		return true
	end

	if serverVoteReward == "random" then
		if serverVoteRewardQuantity == 0 then
			quantity = randSQL(3,5)
		else
			quantity = serverVoteRewardQuantity
		end

		for i=1,quantity,1 do
			if serverVoteRewardQuality == 0 then
				quality = randSQL(6)
			else
				quality = serverVoteRewardQuality
			end


		end

		return true
	end

	if serverVoteReward == "list" then

		return true
	end

	return false
end


function getBlockName(block)
	-- -- find the block in table spawnableItems and return the block name with correct case so we don't need to worry about case.
	-- local cursor, errorString, row, rows

	-- cursor,errorString = conn:execute("SELECT * FROM spawnableItems WHERE itemName LIKE '%" .. block .. "'")
	-- rows = cursor:numrows()

	-- if rows == 1 then
		-- row = cursor:fetch({}, "a")
		-- return row.itemName
	-- else
		-- -- found multiple matches so give up and return the block name unchanged
		-- return block
	-- end
end


function toggleTriggers(event)
	if event == "stop" then
		-- disable all triggers
		-- don't disable the Login trigger
		disableTrigger("End list players")
		disableTrigger("PVP Police")
		disableTrigger("MatchAll")
		disableTrigger("InventorySlot")
		disableTrigger("Player connected")
		disableTrigger("playerinfo")
		disableTrigger("Player disconnected")
		disableTrigger("Inventory")
		disableTrigger("lkp")
		disableTrigger("Zombie Scouts")
		disableTrigger("InventoryOwner")
		disableTrigger("AirDrop alert")
		disableTrigger("Spam")
		disableTrigger("Game Time")
		disableTrigger("gameTickCount")
		-- don't disable the Logon Successful trigger
		disableTrigger("Collect Ban")
		disableTrigger("Unban player")
		disableTrigger("Overstack")
		disableTrigger("mem")
		disableTrigger("lp")
		disableTrigger("Tele")
		disableTrigger("llp")
		disableTrigger("Chat")
		disableTrigger("le")
		disableTrigger("Reload admins")
		disableTrigger("Auto Friend")

		-- disable all timers
		disableTimers()

		-- Answering all stop Captain
	end

	if event == "start" then
		-- set initial state of triggers
		disableTrigger("lkp")
		disableTrigger("Zombie Scouts")
		disableTrigger("Spam")
		disableTrigger("GameTickCount")
		disableTrigger("lp")
		disableTrigger("llp")
		disableTrigger("le")
		disableTrigger("Reload admins")

		enableTrigger("Login")
		enableTrigger("End list players")
		enableTrigger("PVP Police")
		enableTrigger("MatchAll")
		enableTrigger("InventorySlot")
		enableTrigger("Player connected")
		enableTrigger("playerinfo")
		enableTrigger("Player disconnected")
		enableTrigger("Inventory")
		enableTrigger("InventoryOwner")
		enableTrigger("AirDrop alert")
		enableTrigger("Game Time")
		enableTrigger("Logon Successful")
		enableTrigger("Collect Ban")
		enableTrigger("Unban player")
		enableTrigger("Overstack")
		enableTrigger("mem")
		enableTrigger("Tele")
		enableTrigger("Chat")
		enableTrigger("Auto Friend")

		-- enable all timers
		enableTimers()
	end

	if event == "api offline" or server.readLogUsingTelnet then
		enableTrigger("Login")
		enableTrigger("End list players")
		enableTrigger("PVP Police")
		enableTrigger("MatchAll")
		enableTrigger("InventorySlot")
		enableTrigger("Player connected")
		enableTrigger("playerinfo")
		enableTrigger("Player disconnected")
		enableTrigger("Inventory")
		enableTrigger("lkp")
		disableTrigger("Zombie Scouts")
		enableTrigger("InventoryOwner")
		enableTrigger("AirDrop alert")
		disableTrigger("Spam")
		enableTrigger("Game Time")
		disableTrigger("gameTickCount")
		enableTrigger("Logon Successful")
		enableTrigger("Collect Ban")
		enableTrigger("Unban player")
		enableTrigger("Overstack")
		enableTrigger("mem")
		enableTrigger("lp")
		enableTrigger("Tele")
		enableTrigger("llp")
		enableTrigger("Chat")
		disableTrigger("le")
		disableTrigger("Reload admins")
		enableTrigger("Auto Friend")
	end

	if event == "api online" and not server.readLogUsingTelnet then
		enableTrigger("Login")
		disableTrigger("End list players")
		disableTrigger("PVP Police")
		disableTrigger("MatchAll")
		disableTrigger("InventorySlot")
		disableTrigger("Player connected")
		disableTrigger("playerinfo")
		disableTrigger("Player disconnected")
		disableTrigger("Inventory")
		disableTrigger("lkp")
		disableTrigger("Zombie Scouts")
		disableTrigger("InventoryOwner")
		disableTrigger("AirDrop alert")
		disableTrigger("Spam")
		disableTrigger("Game Time")
		disableTrigger("GameTickCount")
		enableTrigger("Logon Successful")
		disableTrigger("Collect Ban")
		disableTrigger("Unban player")
		disableTrigger("Overstack")
		disableTrigger("mem")
		disableTrigger("lp")
		disableTrigger("Tele")
		disableTrigger("llp")
		disableTrigger("Chat")
		disableTrigger("le")
		disableTrigger("Reload admins")
		disableTrigger("Auto Friend")
	end

	if event == "api online" and server.readLogUsingTelnet then
		enableTrigger("Login")
		disableTrigger("lkp")
		disableTrigger("Zombie Scouts")
		disableTrigger("Spam")
		disableTrigger("GameTickCount")
		disableTrigger("lp")
		disableTrigger("llp")
		disableTrigger("le")
		disableTrigger("Reload admins")
	end
end

-- The slots system - management of players that are online, staff and donors + other players that are allowed to reserve a slot
-- ############################################

function getFreeSlots()
	local cursor, errorString, row

	-- are any slots free?
	cursor,errorString = conn:execute("SELECT COUNT(free) AS freeSlotCount FROM slots WHERE free=1")
	row = cursor:fetch({}, "a")
	server.freeSlots = tonumber(row.freeSlotCount)

	return tonumber(row.freeSlotCount)
end


function getReservedSlotsUsed()
	local cursor, errorString, row

	-- get the number of reserved slots in use right now
	cursor,errorString = conn:execute("SELECT COUNT(reserved) AS reservedSlotsInUse FROM slots WHERE reserved=1 AND free=0")
	row = cursor:fetch({}, "a")
	server.reservedSlotsUsed = tonumber(row.reservedSlotsInUse)

	return tonumber(row.reservedSlotsInUse)
end


function initSlots()
	local cursor, errorString, row, counter, k, v

	cursor,errorString = conn:execute("SELECT count(slot) as numberOfSlots FROM slots ORDER BY slot")
	row = cursor:fetch({}, "a")

	if tonumber(row.numberOfSlots) == 0 then
		-- initialise slots table
		for counter=1,server.maxPlayers,1 do
			conn:execute("INSERT INTO slots (slot) VALUES (" .. counter .. ")")
		end

		cursor,errorString = conn:execute("SELECT * FROM slots ORDER BY slot")
		row = cursor:fetch({}, "a")
	else
		if tonumber(row.numberOfSlots) > tonumber(server.maxPlayers) then
			conn:execute("DELETE FROM slots WHERE slot > " .. server.maxPlayers)
		end

		if tonumber(row.numberOfSlots) < tonumber(server.maxPlayers) then
			for counter=row.numberOfSlots+1,server.maxPlayers,1 do
				conn:execute("INSERT INTO slots (slot) VALUES (" .. counter .. ")")
			end
		end
	end

	if tonumber(server.reservedSlots) > 0 then
		conn:execute("UPDATE slots SET reserved = 0 WHERE reserved = 1 and slot <= " .. server.maxPlayers - server.reservedSlots)
		conn:execute("UPDATE slots SET reserved = 1 WHERE slot > " .. server.maxPlayers - server.reservedSlots)
	else
		conn:execute("UPDATE slots SET reserved = 0")
	end

	-- flag all slots as offline
	conn:execute("UPDATE slots SET online = 0")

	-- assign each player that is online to a slot
	if tonumber(botman.playersOnline) > 0 then
		for k,v in pairs(igplayers) do
			assignSlot(k)
		end
	end

	-- free unused slots
	conn:execute("UPDATE slots SET steam = '0', reserved = 0, joinedTime = 0, joinedSession = 0, expires = 0, staff = 0, free = 1, canBeKicked = 1, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE online = 0 AND disconnectedTimestamp < " .. os.time() - 300)

	-- get the number of reserved slots in use right now
	getReservedSlotsUsed()

	-- get the number of free slots available
	getFreeSlots()

	botman.slotsInitialised = true
end


function addOrRemoveSlots()
	-- called after reading gg which can change maxPlayers
	local cursor, errorString, row, counter, k, v

	cursor,errorString = conn:execute("SELECT count(slot) as numberOfSlots FROM slots ORDER BY slot")
	row = cursor:fetch({}, "a")

	if tonumber(row.numberOfSlots) == 0 then
		-- initialise slots table
		for counter=1,server.maxPlayers,1 do
			conn:execute("INSERT INTO slots (slot) VALUES (" .. counter .. ")")
		end
	else
		conn:execute("DELETE FROM slots WHERE slot > " .. server.maxPlayers)

		for counter=row.numberOfSlots+1,server.maxPlayers,1 do
			conn:execute("INSERT INTO slots (slot) VALUES (" .. counter .. ")")
		end
	end

	if tonumber(server.reservedSlots) > 0 then
		conn:execute("UPDATE slots SET reserved = 0") --  WHERE reserved = 1 and slot <= " .. server.maxPlayers - server.reservedSlots
		conn:execute("UPDATE slots SET reserved = 1 WHERE slot > " .. tonumber(server.maxPlayers) - tonumber(server.reservedSlots))
	else
		conn:execute("UPDATE slots SET reserved = 0")
	end

	-- free unused slots
	conn:execute("UPDATE slots SET steam = '0', joinedTime = 0, joinedSession = 0, expires = 0, staff = 0, free = 1, canBeKicked = 1, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE online = 0 AND disconnectedTimestamp < " .. os.time() - 300)

	-- get the number of reserved slots in use right now
	getReservedSlotsUsed()

	-- get the number of free slots available
	getFreeSlots()
end


function kickASlot(steam)
	local cursor, errorString, row

	if (debug) then dbug("debug freeASlot line " .. debugger.getinfo(1).currentline) end

	-- the player who has occupied a reserved slot the longest and isn't a reserved slotter will be kicked
	cursor,errorString = conn:execute("SELECT slot, steam FROM slots WHERE canBeKicked = 1 AND reserved = 1 AND free = 0 ORDER BY joinedTime DESC")
	row = cursor:fetch({}, "a")

	if row then
		if igplayers[steam] then
			kick(steam, "Sorry, you have been kicked from a reserved slot to allow another player to join :(")
			irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name ..  " was kicked to let " .. players[steam].name .. " join.")
		end

		conn:execute("UPDATE slots SET steam = '0', online = 0, staff = 0, canBeKicked = 1, free = 1, joinedSession = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
		getFreeSlots()
		getReservedSlotsUsed()
		return true
	end

	if (debug) then dbug("debug freeASlot line " .. debugger.getinfo(1).currentline) end

	-- if nobody got kicked from a reserved slot and the joining player is an admin, kick the player who has played the longest, isn't using a reserved slot and isn't also an admin
	if staffList[steam] then
		-- make way for the admin people!  Make Room!  Make Room!
		cursor,errorString = conn:execute("SELECT slot, steam FROM slots WHERE canBeKicked = 1 AND reserved = 0 AND staff = 0 ORDER BY joinedTime DESC")
		row = cursor:fetch({}, "a")

		if row then
			if igplayers[steam] then
				kick(steam, "Sorry, you have been kicked to allow an admin to join :(")
				irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name ..  " was kicked to let " .. players[steam].name .. " join.")
			end

			conn:execute("UPDATE slots SET steam = '0', online = 0, joinedTime = 0, joinedSession = 0, expires = 0, staff = 0, free = 1, canBeKicked = 1, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
			getFreeSlots()
			return true
		end
	end

	if (debug) then dbug("debug freeASlot end") end

	getFreeSlots()

	return false
end


function freeASlot(steam)
	local cursor, errorString, row
	if (debug) then dbug("debug freeASlot line " .. debugger.getinfo(1).currentline) end

	-- free the slot that was occupied by the player.  If they are a donor and their expires timer hasn't expired, retain some info in case they rejoin within 5 minutes
	cursor,errorString = conn:execute("SELECT slot, expires FROM slots WHERE steam = '" .. steam .. "'")
	row = cursor:fetch({}, "a")

	if row then
		if isDonor(steam) and (not staffList[steam]) and (row.expires - os.time() > 0) then -- back to the future!
			conn:execute("UPDATE slots SET online = 0, staff = 0, canBeKicked = 1, free = 1, joinedSession = 0, disconnectedTimestamp = " .. os.time() .. " WHERE slot = " .. row.slot)
		else
			conn:execute("UPDATE slots SET steam = '0', online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
		end

		server.freeSlots = server.freeSlots + 1

		-- get the number of reserved slots in use right now
		getReservedSlotsUsed()
	end

	if (debug) then dbug("debug freeASlot end") end
end


function assignSlot(steam)
	local tmp, cursor, errorString, row

	tmp = {}

 	if (debug) then dbug("debug assignSlot line " .. debugger.getinfo(1).currentline) end

	-- I think I can slot you in here.  *shuffles papers*
	if botman.dbConnected then
		tmp.steam = steam
		tmp.canReserve = false
		tmp.isStaff = false
		tmp.canBeKicked = true
		tmp.assigned = false
		tmp.reserveSlot = LookupSettingValue(steam, "reserveSlot")

		-- flag if this player allowed to reserve a slot
		if isDonor(steam) or players[steam].reserveSlot then
			tmp.canReserve = true
			tmp.canBeKicked = false
		end

		-- is this player an admin?
		if staffList[tmp.steam] then
			tmp.canReserve = true
			tmp.isStaff = true
			tmp.canBeKicked = false
		end

		if not tmp.isStaff then
			-- if the player has used a timed reserved slot that expired less than 30 minutes ago, don't let them reserve another slot this time.
			if players[tmp.steam].slotCooldown then
				if os.time() - players[tmp.steam].slotCooldown > 0 then
					tmp.canReserve = false
				end
			end
		end

		-- see if this steam ID is already assigned a slot from earlier
		cursor,errorString = conn:execute("SELECT slot, expires FROM slots WHERE steam = '" .. tmp.steam .. "'")
		row = cursor:fetch({}, "a")

		if row then
			-- Welcome back Sir! :D   Er.. Where is young Master Sean?
			if tonumber(server.reservedSlotTimelimit) > 0 then
				-- check that the slot is still reserved for them
				if (row.expires - os.time()) < 0 then -- time's up Mr Freeman
					if not tmp.isStaff then
						tmp.canBeKicked = true
						players[tmp.steam].slotCooldown = os.time() + 1800 -- make them wait 30 minutes before they can reserve a slot again.
						conn:execute("UPDATE slots SET canBeKicked = " .. dbBool(tmp.canBeKicked) .. ", online = 1, joinedTime = " .. os.time() .. ", expires = 0, joinedSession = " .. players[tmp.steam].sessionCount .. ", staff = " .. dbBool(tmp.isStaff) .. ", free = 0, disconnectedTimestamp = 0 WHERE slot = " .. row.slot)
					end
				else
					conn:execute("UPDATE slots SET canBeKicked = " .. dbBool(tmp.canBeKicked) .. ", online = 1, joinedTime = " .. os.time() .. ", joinedSession = " .. players[tmp.steam].sessionCount .. ", staff = " .. dbBool(tmp.isStaff) .. ", free = 0, disconnectedTimestamp = 0 WHERE slot = " .. row.slot)
				end
			end

			tmp.assigned = true
		else
			if tmp.isStaff or tmp.canReserve then
				-- try to assign to a free reserved slot
				cursor,errorString = conn:execute("SELECT * FROM slots WHERE reserved = 1 AND free = 1")
				row = cursor:fetch({}, "a")

				if row then
					tmp.assigned = true
					conn:execute("UPDATE slots SET steam = '" .. tmp.steam .. "', canBeKicked = " .. dbBool(tmp.canBeKicked) .. ", online = 1, joinedTime = " .. os.time() .. ", expires = " .. os.time() + (server.reservedSlotTimelimit * 60) .. ", joinedSession = " .. players[tmp.steam].sessionCount .. ", staff = " .. dbBool(tmp.isStaff) .. ", free = 0, disconnectedTimestamp = 0, name = '" .. escape(players[tmp.steam].name) .. "', gameID = " .. players[tmp.steam].id .. ", IP = '" .. players[tmp.steam].ip .. "', country = '" .. players[tmp.steam].country .. "', ping = " .. players[tmp.steam].ping .. ", level = " .. players[tmp.steam].level .. ", score = " .. players[tmp.steam].score .. ", zombieKills = " .. players[tmp.steam].zombies .. ", playerKills = " .. players[tmp.steam].playerKills .. ", deaths = " .. players[tmp.steam].deaths .. " WHERE slot = " .. row.slot)
					getFreeSlots()
					getReservedSlotsUsed()
				end
			end

			-- all non-staff joining regular slots can be kicked however it is the player that has been online the longest who is first in line for a kickin
			if not staffList[tmp.steam] then
				tmp.canBeKicked = true
			end

			-- try to assign to a free non-reserved slot
			if tonumber(server.freeSlots) > 0 and not tmp.assigned then
				-- assign the player to the first free slot
				cursor,errorString = conn:execute("SELECT * FROM slots WHERE free = 1 ORDER BY slot")
				row = cursor:fetch({}, "a")

				if row then
					tmp.assigned = true
					conn:execute("UPDATE slots SET steam = '" .. tmp.steam .. "', canBeKicked = " .. dbBool(tmp.canBeKicked) .. ", online = 1, joinedTime = " .. os.time() .. ", expires = 0, joinedSession = " .. players[tmp.steam].sessionCount .. ", staff = " .. dbBool(tmp.isStaff) .. ", free = 0, disconnectedTimestamp = 0, name = '" .. escape(players[tmp.steam].name) .. "', gameID = " .. players[tmp.steam].id .. ", IP = '" .. players[tmp.steam].ip .. "', country = '" .. players[tmp.steam].country .. "', ping = " .. players[tmp.steam].ping .. ", level = " .. players[tmp.steam].level .. ", score = " .. players[tmp.steam].score .. ", zombieKills = " .. players[tmp.steam].zombies .. ", playerKills = " .. players[tmp.steam].playerKills .. ", deaths = " .. players[tmp.steam].deaths .. "  WHERE slot = " .. row.slot)
					getFreeSlots()
				end
			end
		end
	end

	if (debug) then dbug("debug assignSlot end") end
end


function updateSlots(steam)
	-- update the status of slots and free any reserved slots who's player is not online and it has been more than 5 minutes since they left

	local cursor, errorString, row
	local cursor2, errorString2, row2, rows2

	if (debug) then dbug("debug updateSlots line " .. debugger.getinfo(1).currentline) end

	if steam then
		cursor,errorString = conn:execute("SELECT * FROM slots WHERE steam = '" .. steam .. "'")
	else
		cursor,errorString = conn:execute("SELECT * FROM slots WHERE steam <> '0' ORDER BY slot")
	end

	row = cursor:fetch({}, "a")

	while row do
		if igplayers[row.steam] then
			if (tonumber(server.reservedSlotTimelimit) > 0) and (not staffList[row.steam]) then
				-- flag the slot as kickable if its reserved time has expired
				if (os.time() - row.expires) < 0 and row.canBeKicked == 0 then
					-- mark the player can be kicked
					conn:execute("UPDATE slots SET canBeKicked = 1 WHERE slot = " .. row.slot)
				end
			end
			if tonumber(row.reserved) == 1 then
				-- look for a free non-reserved slot and move the player to it
				cursor2,errorString2 = conn:execute("SELECT slot FROM slots WHERE steam = '0' AND free = 1 AND reserved = 0 ORDER BY slot LIMIT 0,1")
				row2 = cursor2:fetch({}, "a")

				if row2 then
					-- copy the reserved slot into the free non-reserved slot
					if tonumber(row.staff) == 1 then

						conn:execute("UPDATE slots SET steam = '" .. row.steam .. "', online = 1, staff = 1, canBeKicked = 0, free = 0, joinedTime = " .. row.joinedTime .. ", joinedSession = " .. row.joinedSession .. ", expires = 0, disconnectedTimestamp = 0, name = '" .. escape(players[row.steam].name) .. "', gameID = " .. players[row.steam].id .. ", IP = '" .. players[row.steam].ip .. "', country = '" .. players[row.steam].country .. "', ping = " .. players[row.steam].ping .. ", level = " .. players[row.steam].level .. ", score = " .. players[row.steam].score .. ", zombieKills = " .. players[row.steam].zombies .. ", playerKills = " .. players[row.steam].playerKills .. ", deaths = " .. players[row.steam].deaths .. " WHERE slot = " .. row2.slot)
					else

						conn:execute("UPDATE slots SET steam = '" .. row.steam .. "', online = 1, staff = 0, canBeKicked = 1, free = 0, joinedTime = " .. row.joinedTime .. ", joinedSession = " .. row.joinedSession .. ", expires = 0, disconnectedTimestamp = 0, name = '" .. escape(players[row.steam].name) .. "', gameID = " .. players[row.steam].id .. ", IP = '" .. players[row.steam].ip .. "', country = '" .. players[row.steam].country .. "', ping = " .. players[row.steam].ping .. ", level = " .. players[row.steam].level .. ", score = " .. players[row.steam].score .. ", zombieKills = " .. players[row.steam].zombies .. ", playerKills = " .. players[row.steam].playerKills .. ", deaths = " .. players[row.steam].deaths .. " WHERE slot = " .. row2.slot)
					end

					-- free the reserved slot
					conn:execute("UPDATE slots SET steam = '0', online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
				end
			end
		else
			if tonumber(row.reserved) == 1 then
				if tonumber(server.reservedSlotTimelimit) > 0 then
					-- check that the slot is being held for a player
					if (row.expires - os.time()) < 0 then
						-- free the slot
						conn:execute("UPDATE slots SET steam = '0', online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
					end

					if tonumber(row.disconnectedTimestamp) > 0 then
						if (os.time() - row.disconnectedTimestamp) > 300 then -- reserved slot player disconnected more than 5 minutes ago.
							-- if you snooze you lose.. your reserved slot
							conn:execute("UPDATE slots SET steam = '0', online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
						end
					else
						conn:execute("UPDATE slots SET steam = '0', online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
					end
				else
					-- mark the slot as free
					conn:execute("UPDATE slots SET steam = '0', online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
				end

				-- get the number of reserved slots in use right now
				server.reservedSlotsUsed = getReservedSlotsUsed()
			else
				-- mark the slot as free
				conn:execute("UPDATE slots SET steam = 0, online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
			end
		end

		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug updateSlots end") end
end

-- End of slots functions
-- ############################################

function dogeWOW()
	-- So words. Many doge. WOW!
	local r, doge

	r = randSQL(5)
	if r == 1 then doge = "So " end
	if r == 2 then doge = "Such " end
	if r == 3 then doge = "Many " end
	if r == 4 then doge = "Much " end
	if r == 5 then doge = "Very " end

	r = randSQL(16)
	if r == 1 then doge = doge .. "Kill." end
	if r == 2 then doge = doge .. "Death." end
	if r == 3 then doge = doge .. "Bullet." end
	if r == 4 then doge = doge .. "Owned." end
	if r == 5 then doge = doge .. "Hax." end
	if r == 6 then doge = doge .. "Pain." end
	if r == 7 then doge = doge .. "Gore." end
	if r == 8 then doge = doge .. "Loot." end
	if r == 9 then doge = doge .. "Epic." end
	if r == 10 then doge = doge .. "Damage." end
	if r == 11 then doge = doge .. "Fluke." end
	if r == 12 then doge = doge .. "Luck." end
	if r == 13 then doge = doge .. "Died." end
	if r == 14 then doge = doge .. "Dismemberment." end
	if r == 15 then doge = doge .. "Blood." end
	if r == 16 then doge = doge .. "Rage." end

	return doge
end


function startUsingAllocsWebAPI()
	local httpHeaders = {["X-SDTD-API-TOKENNAME"] = server.allocsWebAPIUser, ["X-SDTD-API-SECRET"] = server.allocsWebAPIPassword}

	if tonumber(server.webPanelPort) > 0 then
		-- verify that the web API is working for us
		postHTTP("", "http://" .. server.IP .. ":" .. server.webPanelPort .. "/api/executeconsolecommand?command=pm apitest", httpHeaders)
		-- the response from the server is processed in function onHttpPostDone(_, url, body) in functions.lua
	end
end

function removeEntityCommand(entityID)
	if server.botman then
		sendCommand("bm-remove " .. entityID)
		return
	end
end


function hidePlayerChat(prefix)
	if prefix then
		-- hide commands
		if server.botman then
			-- then enable it in the botman mod
			sendCommand("bm-chatcommands prefix " .. prefix)
			sendCommand("bm-chatcommands hide true")
			return
		end
	else
		-- don't hide commands
		if server.botman then
			sendCommand("bm-chatcommands hide false")
		end
	end
end


function mutePlayerChat(steam, toggle)
	if server.botman then
		sendCommand("bm-muteplayer " .. players[steam].userID .. " " .. toggle)
		return
	end
end


function mutePlayer(steam)
	mutePlayerChat(steam, "true")
	players[steam].mute = true
	irc_chat(server.ircMain, players[steam].name .. "'s chat has been muted :D")
	message("pm " .. players[steam].userID .. " [" .. server.warnColour .. "]Your chat has been muted.[-]")
	if botman.dbConnected then conn:execute("UPDATE players SET mute = 1 WHERE steam = '" .. steam .. "'") end
end


function unmutePlayer(steam)
	mutePlayerChat(steam, "false")
	players[steam].mute = false
	irc_chat(server.ircMain, players[steam].name .. "'s chat is no longer muted D:")
	message("pm " .. players[steam].userID .. " [" .. server.chatColour .. "]Your chat is no longer muted.[-]")
	if botman.dbConnected then conn:execute("UPDATE players SET mute = 0 WHERE steam = '" .. steam .. "'") end
end


function unlockAll(steam)
	if server.botman then
-- TODO:  Add bot support once the console command accepts a steam id.
	end
end


function setPlayerChatLimit(steam, length)
	if server.botman then
		sendCommand("bm-playerchatmaxlength " .. players[steam].userID .. " " .. length)
		return
	end
end


function setPlayerColour(steam, colour)
	if modBotman.disableChatColours then
		-- abort if the bot is not allowed to change chat colours
		return
	end

	colour = string.upper(colour)

	if server.botman then
		sendCommand("bm-chatplayercolor " .. players[steam].userID .. " " .. colour .. " 1")

		return
	end
end


function setOverrideChatName(steam, newName, clear)
	if server.botman then
		if clear then
			sendCommand("bm-overridechatname " .. players[steam].userID .. " \"" .. players[steam].name .. "\"")
		else
			sendCommand("bm-overridechatname " .. players[steam].userID .. " \"" .. newName .. "\"")
		end

		return
	end
end


function getBackupFiles(path)
	local file, str, backups, count, lastUnderscore

	connMEM:execute("DELETE FROM list WHERE steam = '-10'")
	backups = {}
	count = 2

	for file in lfs.dir(path) do
	  if file ~= "." and file ~= ".." and file ~= "" then
		if string.find(file, "_") then
			lastUnderscore = file:match('^.*()_')
			str = string.sub(file, 1, lastUnderscore - 1)

			if not backups[str] then
				backups[str] = {}
				connMEM:execute("INSERT INTO list (id, thing, class, steam) VALUES (" .. count .. ",'" .. connMEM:escape(str) .. "','backup', '-10')")
				count = count + 1
			end
		end
	  end
	end
end


function encodeChar(chr)
	return string.format("%%%X",string.byte(chr))
end


function encodeString(str)
	local output, t = string.gsub(str,"[^%w]",encodeChar)
	return output
end


function urlDecode(str)
   str = str:gsub("+", " ")
   str = str:gsub("%%(%x%x)", function(h)
      return string.char(tonumber(h,16))
   end)
   str = str:gsub("\r\n", "\n")
   return str
end


function processLKPLine(line)
	local tmp

	-- had to disable this code as since A21 the output of lkp is no longer usable

	-- tmp = {}
	-- tmp.data = string.split(line, ",")
	-- tmp.name = string.sub(tmp.data[1], string.find(tmp.data[1], ". ") + 2)
	-- tmp.id = string.sub(tmp.data[2], string.find(tmp.data[2], "id=") + 3)
	-- tmp.temp = string.sub(tmp.data[3], string.find(tmp.data[3], "steamid=") + 8)
	-- tmp.temp = string.split(tmp.temp, "_")
	-- tmp.platform = tmp.temp[1]
	-- tmp.steam = tmp.temp[2]
	-- tmp.playtime = string.sub(tmp.data[6], string.find(tmp.data[6], "playtime=") + 9, string.len(tmp.data[6]) - 2)
	-- tmp.playtime = tonumber(tmp.playtime)
	-- tmp.seen = string.sub(tmp.data[7], string.find(tmp.data[7], "seen=") + 5)

	-- if tmp.steam == "" then
		-- return
	-- end

	-- if playersArchived[tmp.steam] then
		-- -- don't process if this player has been archived
		-- return
	-- end

	-- if tmp.playtime ~= "0" then
		-- if not players[tmp.steam] then
			-- players[tmp.steam] = {}

			-- if tmp.id ~= "-1" then
				-- players[tmp.steam].id = tmp.id
			-- end

			-- players[tmp.steam].name = tmp.name
			-- players[tmp.steam].steam = tmp.steam
			-- players[tmp.steam].playtime = tmp.playtime
			-- players[tmp.steam].seen = tmp.seen
			-- players[tmp.steam].platform = tmp.platform

			-- if botman.dbConnected then conn:execute("INSERT INTO players (steam, id, name, playtime, seen, platform) VALUES ('" .. tmp.steam .. "'," .. tmp.id .. ",'" .. escape(tmp.name) .. "'," .. tmp.playtime .. ",'" .. tmp.seen .. "','" .. tmp.platform .. "'") end
		-- else
			-- if tmp.id ~= "-1" then
				-- players[tmp.steam].id = tmp.id
			-- end

			-- players[tmp.steam].name = tmp.name
			-- players[tmp.steam].playtime = tmp.playtime
			-- players[tmp.steam].seen = tmp.seen
			-- players[tmp.steam].platform = tmp.platform

			-- if botman.dbConnected then conn:execute("UPDATE players SET steam = '" .. tmp.steam .. "', id = " .. tmp.id .. ", name = '" .. escape(tmp.name) .. "', playtime = " .. tmp.playtime .. ", seen = '" .. tmp.seen .. "', platform = '" .. tmp.platform .. "' WHERE steam = '" .. tmp.steam .. "'") end
		-- end
	-- end

	-- -- add missing fields and give them default values
	-- fixMissingPlayer(players[tmp.steam].platform, tmp.steam, players[tmp.steam].steamOwner, players[tmp.steam].userID)
end


onCloseMudlet = function()
	-- stuff to do before Mudlet stops running
	telnetLogFile:close()
end


onSysDisconnection = function ()
	botman.telnetOffline = true
	botman.botOffline = true
	botman.APIOffline = true
	botman.botOfflineCount = 0
	botman.telnetOfflineCount = 0
	botman.lastServerResponseTimestamp = os.time()
	botman.lastTelnetResponseTimestamp = os.time()
	botman.botOfflineTimestamp = os.time()

	if tonumber(botman.playersOnline) < 0 then
		botman.playersOnline = 0
	end
end


function updateBotOnlineStatus()
	botman.botOfflineCount = 0
	botman.botOffline = false
	botman.lastTelnetResponseTimestamp = os.time()
end


function getBotsIP()
	local file, fileSize, ln, temp

	if true then
		return
	end

	-- this will break the bot if it only returns the local LAN IP!  So far it seems to always return the internet IP.
	os.remove(homedir .. "/temp/botsIP.txt")
	os.execute("hostname -i > " .. homedir .. "/temp/botsIP.txt")

	file = io.open(homedir .. "/temp/botsIP.txt", "r")

	for ln in file:lines() do
		if string.find(ln, " ") then
			temp = string.split(ln, " ")

			if temp[2] then
				server.botsIP = temp[2]
			else
				server.botsIP = ln
			end
		else
			server.botsIP = ln
		end
	end

	conn:execute("UPDATE server SET botsIP = '" .. server.botsIP .. "")

	file:close()
end


function sleep(s)
	local ntime = os.time() + s
	repeat until os.time() >= ntime
end


function processConnectQueue(steam)
	local cursor, errorString, row

	cursor,errorString = connSQL:execute("SELECT * FROM connectQueue WHERE steam = '" .. steam .. "' ORDER BY id")

	if cursor then
		row = cursor:fetch({}, "a")

		while row do
			if string.sub(row.command, 1, 3) == "pm " or string.sub(row.command, 1, 3) == "say" then
				message(row.command)
			else
				sendCommand(row.command)
			end

			connSQL:execute("UPDATE connectQueue SET processed = 1 WHERE id = " .. row.id)
			row = cursor:fetch(row, "a")
		end

		connSQL:execute("DELETE FROM connectQueue WHERE processed = 1")
	end
end


function readSteamRep(steam)
	-- while there is a more efficient way to do this using the Steam API, this way works without all the extra stuff required to use the API.
	local file, ln, fileStr
	local tmp

	fileStr = homedir .. "/temp/steamrep_" .. steam .. ".txt"

	fileSize = lfs.attributes (fileStr, "size")

	-- abort if the file is empty
	if fileSize == nil or tonumber(fileSize) == 0 then
		return
	end

	tmp = {}

	file = io.open(fileStr, "r")
	for ln in file:lines() do
		if string.find(ln, "vacbanned") then
			if string.find(ln, "<span id=\"vacbanned\"><span class=\"a02\">Banned</span></span>") then
				tmp.VACBanned = true

				if players[steam] then
					players[steam].VACBanned = true
					if botman.dbConnected then conn:execute("UPDATE players SET VACBanned=1 WHERE steam = '" .. steam .. "'") end

					if not isAdmin(steam) and not whitelist[steam] then
						alertAdmins("Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
						irc_chat(server.ircAlerts, "Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
						irc_chat(server.ircMain, "Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
					end
				else
					alertAdmins("Player " .. steam .. " has one or more VAC bans on record.")
					irc_chat(server.ircAlerts, "Player " .. steam .. " has one or more VAC bans on record.")
					irc_chat(server.ircMain, "Player " .. steam .. " has one or more VAC bans on record.")
				end

				if server.banVACBannedPlayers and not whitelist[steam] and not isAdmin(steam) then
					banPlayer("Steam", "", steam, "10 years", "You have a VAC ban")
				end
			else
				tmp.VACBanned = false
				players[steam].VACBanned = false
			end
		end

		if string.find(ln, "<span id=\"membersince") then
			tmp.joinedSteam = 1
dbugi(ln)
		end

		if string.find(ln, "<span id=\"privacystate") then
			tmp.profilePrivacy = 1
dbugi(ln)
		end

		if string.find(ln, "Steam Level") then
			tmp.steamLevel = 1
dbugi(ln)
		end

		if string.find(ln, "Community Ban") then
			tmp.communityBan = 1
dbugi(ln)
		end

		if string.find(ln, "Trade Ban") then
			tmp.tradeBan = 1
dbugi(ln)
		end

		if tmp.VACBanned and tmp.joinedSteam and tmp.profilePrivacy and tmp.steamLevel and tmp.communityBan and tmp.tradeBan then
			display(tmp)
			io.close(file)
			--tempTimer( 2, [[ os.remove("]] .. fileStr .. [[")]])
			return true
		end
	end

	io.close(file)
	--tempTimer( 2, [[ os.remove("]] .. fileStr .. [[")]])
end


function checkVACBan(steam)
	-- while there is a more efficient way to do this using the Steam API, this way works without all the extra stuff required to use the API.
	local file, ln, fileStr

	fileStr = homedir .. "/temp/steamrep_" .. steam .. ".txt"

	fileSize = lfs.attributes (fileStr, "size")

	-- abort if the file is empty
	if fileSize == nil or tonumber(fileSize) == 0 then
		return
	end

	file = io.open(fileStr, "r")
	for ln in file:lines() do
		if string.find(ln, "vacbanned") then
			if string.find(ln, "<span id=\"vacbanned\"><span class=\"a02\">Banned</span></span>") then
				io.close(file)
				tempTimer( 2, [[ os.remove("]] .. fileStr .. [[")]])

				if players[steam] then
					players[steam].VACBanned = true
					if botman.dbConnected then conn:execute("UPDATE players SET VACBanned=1 WHERE steam = '" .. steam .. "'") end

					if not isAdmin(steam) and not whitelist[steam] then
						alertAdmins("Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
						irc_chat(server.ircAlerts, "Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
						irc_chat(server.ircMain, "Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
					end
				else
					alertAdmins("Player " .. steam .. " has one or more VAC bans on record.")
					irc_chat(server.ircAlerts, "Player " .. steam .. " has one or more VAC bans on record.")
					irc_chat(server.ircMain, "Player " .. steam .. " has one or more VAC bans on record.")
				end

				if server.banVACBannedPlayers and not whitelist[steam] and not isAdmin(steam) then
					banPlayer("Steam", "", steam, "10 years", "You have a VAC ban")
				end

				return true
			else
				io.close(file)
				tempTimer( 2, [[ os.remove("]] .. fileStr .. [[")]])

				players[steam].VACBanned = false
				return false
			end
		end
	end
end


function reloadBot(getAllPlayers)
	-- send several commands to the server to gather info.  Each command is sent 5 seconds apart to slow down the telnet spam.
	if server.allocs then
		send("pm BotStartupCheck \"test\"")
	end

	-- if server.useAllocsWebAPI and tonumber(server.webPanelPort) > 0 and botman.APIOffline and server.allocs and server.readLogUsingTelnet then
		-- server.allocsWebAPIPassword = generatePassword(20)
		-- send("webtokens add bot " .. server.allocsWebAPIPassword .. " 0")
		-- botman.lastBotCommand = "webtokens add bot"
		-- conn:execute("UPDATE server set allocsWebAPIUser = 'bot', allocsWebAPIPassword = '" .. escape(server.allocsWebAPIPassword) .. "', useAllocsWebAPI = 1")
		-- botman.APIOffline = false
		-- toggleTriggers("api online")
	-- end

	-- got the time?  Hey that's a nice watch.  Can I have it?
	if server.botman then
		tempTimer( 3, [[sendCommand("bm-uptime")]] )
	end

	tempTimer( 5, [[sendCommand("version")]] )
	tempTimer( 10, [[sendCommand("gg")]] )
	tempTimer( 15, [[sendCommand("admin list")]] )
	tempTimer( 20, [[sendCommand("ban list")]] )

	if getAllPlayers then
		tempTimer( 25, [[sendCommand("lkp")]] )
	else
		tempTimer( 25, [[sendCommand("lkp -online")]] )
	end

	tempTimer( 35, [[registerBot()]] )
end


function reloadCode()
	dofile(homedir .. "/scripts/reload_bot_scripts.lua")
	-- reload the bot's code. Skip reloading the players table and don't announce that the code has been reloaded.
	reloadBotScripts(true, true)
	dofile(homedir .. "/scripts/startup_bot.lua")
end


function onSysExit()
	saveWindowLayout()
end


function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end


function url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end


function readAPI()
	if isFile(homedir .. "/api.ini") then
		dofile(homedir .. "/api.ini")
	end

	if serverVoteReward == nil then
		serverVoteReward = "crate"
		serverVoteRewardItem = "sc_General"
	end

	if serverVoteRewardList ~= nil then
		if serverVoteRewardList == "" then
			return
		end

		serverVoteRewardList = yajl.to_value(serverVoteRewardList)
	end
end


function writeAPI()
	local file

	-- first delete the file
	os.remove(homedir .. "/api.ini")

	-- now build a new one
	file = io.open(homedir .. "/api.ini", "a")

	if serverAPI ~= nil then
		file:write("serverAPI=\"" .. serverAPI .. "\"\n")
	end

	if serverVoteReward ~= nil then
		file:write("serverVoteReward=\"" .. serverVoteReward .. "\"\n")
	else
		file:write("serverVoteReward=\"sc_General\"\n")
		serverVoteReward="sc_General"
	end

	if serverVoteRewardQuantity ~= nil then
		file:write("serverVoteRewardQuantity=" .. tonumber(serverVoteRewardQuantity) .. "\n")
	else
		file:write("serverVoteRewardQuantity=0\n")
		serverVoteRewardQuantity=0
	end

	if serverVoteRewardQuality ~= nil then
		file:write("serverVoteRewardQuality=" .. tonumber(serverVoteRewardQuality) .. "\n")
	else
		file:write("serverVoteRewardQuality=0\n")
		serverVoteRewardQuality=0
	end

	if type(serverVoteRewardList) ~= "table" then
		serverVoteRewardList = {}
	end

	file:write("serverVoteRewardList=\"" .. yajl.to_string(serverVoteRewardList) .. "\"\n")

	if serverVoteRewardItem ~= nil then
		file:write("serverVoteRewardItem=\"" .. serverVoteRewardItem .. "\"\n")
	else
		file:write("serverVoteRewardItem=\"\"\n")
	end

	if botmanAPI ~= nil then
		file:write("botmanAPI=\"" .. botmanAPI .. "\"\n")
	end

	file:close()
end


function readServerVote(steam)
	local file, fileSize, ln, url, result
	local tmp = {}

	fileSize = lfs.attributes (homedir .. "/temp/voteCheck_" .. steam .. ".txt", "size")

	-- abort if the file is empty
	if fileSize == nil or tonumber(fileSize) == 0 then
		return
	end

	file = io.open(homedir .. "/temp/voteCheck_" .. steam .. ".txt", "r")
	tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(steam)

	for ln in file:lines() do
		if ln == "0" then
			message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]Reward?  For what?  You haven't voted today!  You can claim your reward after voting.[-]")
			file:close()

			return
		end

		if ln == "1" then
			-- claim the vote
			url = "https://7daystodie-servers.com/api/?action=post&object=votes&element=claim&key=" .. serverAPI .. "&steamid=" .. steam
			os.remove(homedir .. "/temp/voteClaim_" .. steam .. ".txt")
			downloadFile(homedir .. "/temp/voteClaim_" .. steam .. ".txt", url)

			-- reward the player.  Good Player!  Have a biscuit.
			message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]Thanks for voting for us!  Your reward should be in your inventory or spawn beside you.[-]")
			rewardServerVote(players[steam].id)
			igplayers[steam].voteRewarded = os.time()
			igplayers[steam].voteRewardOwing = 0
			file:close()

			return
		end

		if ln == "2" then
			message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]Thanks for voting today.  You have already claimed your reward.  Vote for us tomorrow and you can claim another reward then.[-]")
			file:close()
			os.remove(homedir .. "/temp/voteCheck_" .. steam .. ".txt")

			return
		end
	end

	file:close()
end


function checkServerVote(steam)
	local url

	if serverAPI ~= nil then
		url = "https://7daystodie-servers.com/api/?object=votes&element=claim&key=" .. serverAPI .. "&steamid=" .. steam
		os.remove(homedir .. "/temp/voteCheck_" .. steam .. ".txt")
		downloadFile(homedir .. "/temp/voteCheck_" .. steam .. ".txt", url)
	end
end


function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end


function restartBot()
	savePlayers()
	closeMudlet()
end


function readBotmanINI()
	if isFile(homedir .. "/botman.ini") then
		dofile(homedir .. "/botman.ini")
	end
end


function writeBotmanINI()
	local file

	-- first delete the file
	os.remove(homedir .. "/botman.ini")

	-- then build it
	file = io.open(homedir .. "/botman.ini", "a")

	-- server data
	if server.botOwner then file:write("botOwner=\"" .. server.botOwner .. "\"\n") end
	if server.serverName then file:write("botOwner=\"" .. server.serverName .. "\"\n") end
	if server.accessLevelOverride then file:write("server.accessLevelOverride=" .. server.accessLevelOverride .. "\n") end
	if server.alertColour then file:write("server.alertColour=\"" .. server.alertColour .. "\"\n") end
	if server.alertSpending ~= nil then file:write("server.alertSpending=\"" .. trueFalse(server.alertSpending) .. "\"\n") end
	if server.allowBank ~= nil then file:write("server.allowBank=\"" .. trueFalse(server.allowBank) .. "\"\n") end
	if server.allowBotRestarts ~= nil then file:write("server.allowBotRestarts=\"" .. trueFalse(server.allowBotRestarts) .. "\"\n") end
	if server.allowGarbageNames ~= nil then file:write("server.allowGarbageNames=\"" .. trueFalse(server.allowGarbageNames) .. "\"\n") end
	if server.allowGimme ~= nil then file:write("server.allowGimme=\"" .. trueFalse(server.allowGimme) .. "\"\n") end
	if server.allowHomeTeleport ~= nil then file:write("server.allowHomeTeleport=\"" .. trueFalse(server.allowHomeTeleport) .. "\"\n") end
	if server.allowLottery ~= nil then file:write("server.allowLottery=\"" .. trueFalse(server.allowLottery) .. "\"\n") end
	if server.allowNumericNames ~= nil then file:write("server.allowNumericNames=\"" .. trueFalse(server.allowNumericNames) .. "\"\n") end
	if server.allowOverstacking ~= nil then file:write("server.allowOverstacking=\"" .. trueFalse(server.allowOverstacking) .. "\"\n") end
	if server.allowPackTeleport ~= nil then file:write("server.allowPackTeleport=\"" .. trueFalse(server.allowPackTeleport) .. "\"\n") end
	if server.allowPlayerToPlayerTeleporting ~= nil then file:write("server.allowPlayerToPlayerTeleporting=\"" .. trueFalse(server.allowPlayerToPlayerTeleporting) .. "\"\n") end
	if server.allowPlayerVoteTopics ~= nil then file:write("server.allowPlayerVoteTopics=\"" .. trueFalse(server.allowPlayerVoteTopics) .. "\"\n") end
	if server.allowProxies ~= nil then file:write("server.allowProxies=\"" .. trueFalse(server.allowProxies) .. "\"\n") end
	if server.allowRapidRelogging ~= nil then file:write("server.allowRapidRelogging=\"" .. trueFalse(server.allowRapidRelogging) .. "\"\n") end
	if server.allowReboot ~= nil then file:write("server.allowReboot=\"" .. trueFalse(server.allowReboot) .. "\"\n") end
	if server.allowReturns ~= nil then file:write("server.allowReturns=\"" .. trueFalse(server.allowReturns) .. "\"\n") end
	if server.allowShop ~= nil then file:write("server.allowShop=\"" .. trueFalse(server.allowShop) .. "\"\n") end
	if server.allowStuckTeleport ~= nil then file:write("server.allowStuckTeleport=\"" .. trueFalse(server.allowStuckTeleport) .. "\"\n") end
	if server.allowTeleporting ~= nil then file:write("server.allowTeleporting=\"" .. trueFalse(server.allowTeleporting) .. "\"\n") end
	if server.allowVoting ~= nil then file:write("server.allowVoting=\"" .. trueFalse(server.allowVoting) .. "\"\n") end
	if server.allowWaypoints ~= nil then file:write("server.allowWaypoints=\"" .. trueFalse(server.allowWaypoints) .. "\"\n") end
	if server.announceTeleports ~= nil then file:write("server.announceTeleports=\"" .. trueFalse(server.announceTeleports) .. "\"\n") end
	if server.bailCost then file:write("server.bailCost=" .. server.bailCost .. "\n") end
	if server.baseCooldown then file:write("server.baseCooldown=" .. server.baseCooldown .. "\n") end
	if server.baseCost then file:write("server.baseCost=" .. server.baseCost .. "\n") end
	if server.baseSize then file:write("server.baseSize=" .. server.baseSize .. "\n") end
	if server.blacklistResponse then file:write("server.blacklistResponse=\"" .. server.blacklistResponse .. "\"\n") end
	if server.blacklistCountries then file:write("server.blacklistCountries=\"" .. server.blacklistCountries .. "\"\n") end
	if server.botName then file:write("server.botName=\"" .. server.botName .. "\"\n") end
	if server.botRestartHour then file:write("server.botRestartHour=" .. server.botRestartHour .. "\n") end
	if server.botsIP then file:write("server.botsIP=\"" .. server.botsIP .. "\"\n") end
	if server.chatColour then file:write("server.chatColour=\"" .. server.chatColour .. "\"\n") end
	if server.chatColourAdmin then file:write("server.chatColourAdmin=\"" .. server.chatColourAdmin .. "\"\n") end
	if server.chatColourDonor then file:write("server.chatColourDonor=\"" .. server.chatColourDonor .. "\"\n") end
	if server.chatColourMod then file:write("server.chatColourMod=\"" .. server.chatColourMod .. "\"\n") end
	if server.chatColourNewPlayer then file:write("server.chatColourNewPlayer=\"" .. server.chatColourNewPlayer .. "\"\n") end
	if server.chatColourOwner then file:write("server.chatColourOwner=\"" .. server.chatColourOwner .. "\"\n") end
	if server.chatColourPlayer then file:write("server.chatColourPlayer=\"" .. server.chatColourPlayer .. "\"\n") end
	if server.chatColourPrisoner then file:write("server.chatColourPrisoner=\"" .. server.chatColourPrisoner .. "\"\n") end
	if server.chatlogPath then file:write("server.chatlogPath=\"" .. server.chatlogPath .. "\"\n") end
	if server.commandPrefix then file:write("server.commandPrefix=\"" .. server.commandPrefix .. "\"\n") end
	if server.disableBaseProtection ~= nil then file:write("server.disableBaseProtection=\"" .. trueFalse(server.disableBaseProtection) .. "\"\n") end
	if server.disableTPinPVP ~= nil then file:write("server.disableTPinPVP=\"" .. trueFalse(server.disableTPinPVP) .. "\"\n") end
	if server.disableWatchAlerts ~= nil then file:write("server.disableWatchAlerts=\"" .. trueFalse(server.disableWatchAlerts) .. "\"\n") end
	if server.enableRegionPM then file:write("server.enableRegionPM=\"" .. trueFalse(server.enableRegionPM) .. "\"\n") end
	if server.feralRebootDelay then file:write("server.feralRebootDelay=" .. server.feralRebootDelay .. "\n") end
	if server.gameType then file:write("server.gameType=\"" .. server.gameType .. "\"\n") end
	if server.GBLBanThreshold then file:write("server.GBLBanThreshold=" .. server.GBLBanThreshold .. "\n") end
	if server.gimmePeace ~= nil then file:write("server.gimmePeace=\"" .. trueFalse(server.gimmePeace) .. "\"\n") end
	if server.gimmeZombies ~= nil then file:write("server.gimmeZombies=\"" .. trueFalse(server.gimmeZombies) .. "\"\n") end
	if server.hackerTPDetection ~= nil then file:write("server.hackerTPDetection=\"" .. trueFalse(server.hackerTPDetection) .. "\"\n") end
	if server.hardcore ~= nil then file:write("server.hardcore=\"" .. trueFalse(server.hardcore) .. "\"\n") end
	if server.hideCommands ~= nil then file:write("server.hideCommands=\"" .. trueFalse(server.hideCommands) .. "\"\n") end
	if server.idleKick ~= nil then file:write("server.idleKick=\"" .. trueFalse(server.idleKick) .. "\"\n") end
	if server.IP then file:write("server.IP=\"" .. server.IP .. "\"\n") end
	if server.ircAlerts then file:write("server.ircAlerts=\"" .. server.ircAlerts .. "\"\n") end
	if server.ircBotName then file:write("server.ircBotName=\"" .. server.ircBotName .. "\"\n") end
	if server.ircMain then file:write("server.ircChannel=\"" .. server.ircMain .. "\"\n") end
	if server.ircPort then file:write("server.ircPort=" .. server.ircPort .. "\n") end
	if server.ircPrivate ~= nil then file:write("server.ircPrivate=\"" .. trueFalse(server.ircPrivate) .. "\"\n") end
	if server.ircServer then file:write("server.ircServer=\"" .. server.ircServer .. "\"\n") end
	if server.ircWatch then file:write("server.ircWatch=\"" .. server.ircWatch .. "\"\n") end
	if server.lottery then file:write("server.lottery=" .. server.lottery .. "\n") end
	if server.lotteryMultiplier then file:write("server.lotteryMultiplier=" .. server.lotteryMultiplier .. "\n") end
	if server.mapSize then file:write("server.mapSize=" .. server.mapSize .. "\n") end
	if server.maxPrisonTime then file:write("server.maxPrisonTime=" .. server.maxPrisonTime .. "\n") end
	if server.maxServerUptime then file:write("server.maxServerUptime=" .. server.maxServerUptime .. "\n") end
	if server.maxWaypoints then file:write("server.maxWaypoints=" .. server.maxWaypoints .. "\n") end
	if server.moneyName then file:write("server.moneyName=\"" .. server.moneyName .. "\"\n") end
	if server.moneyPlural then file:write("server.moneyPlural=\"" .. server.moneyPlural .. "\"\n") end
	if server.MOTD then file:write("server.MOTD=\"" .. server.MOTD .. "\"\n") end
	if server.newPlayerTimer then file:write("server.newPlayerTimer=" .. server.newPlayerTimer .. "\n") end
	if server.northeastZone then file:write("server.northeastZone=\"" .. server.northeastZone .. "\"\n") end
	if server.northwestZone then file:write("server.northwestZone=\"" .. server.northwestZone .. "\"\n") end
	if server.overstackThreshold then file:write("server.overstackThreshold=" .. server.overstackThreshold .. "\n") end
	if server.packCooldown then file:write("server.packCooldown=" .. server.packCooldown .. "\n") end
	if server.packCost then file:write("server.packCost=" .. server.packCost .. "\n") end
	if server.perMinutePayRate then file:write("server.perMinutePayRate=" .. server.perMinutePayRate .. "\n") end
	if server.pingKick then file:write("server.pingKick=" .. server.pingKick .. "\n") end
	if server.playersCanFly ~= nil then file:write("server.playersCanFly=\"" .. trueFalse(server.playersCanFly) .. "\"\n") end
	if server.playerTeleportDelay then file:write("server.playerTeleportDelay=" .. server.playerTeleportDelay .. "\n") end
	if server.protectionMaxDays then file:write("server.protectionMaxDays=" .. server.protectionMaxDays .. "\n") end
	if server.pvpAllowProtect ~= nil then file:write("server.pvpAllowProtect=\"" .. trueFalse(server.pvpAllowProtect) .. "\"\n") end
	if server.pvpIgnoreFriendlyKills ~= nil then file:write("server.pvpIgnoreFriendlyKills=\"" .. trueFalse(server.pvpIgnoreFriendlyKills) .. "\"\n") end
	if server.pvpTeleportCooldown then file:write("server.pvpTeleportCooldown=" .. server.pvpTeleportCooldown .. "\n") end
	if server.rebootHour then file:write("server.rebootHour=" .. server.rebootHour .. "\n") end
	if server.rebootMinute then file:write("server.rebootMinute=" .. server.rebootMinute .. "\n") end
	if server.reservedSlots then file:write("server.reservedSlots=" .. server.reservedSlots .. "\n") end
	if server.restrictIRC ~= nil then file:write("server.restrictIRC=\"" .. trueFalse(server.restrictIRC) .. "\"\n") end
	if server.rules then file:write("server.rules=\"" .. server.rules .. "\"\n") end
	if server.scanEntities ~= nil then file:write("server.scanEntities=\"" .. trueFalse(server.scanEntities) .. "\"\n") end
	if server.scanErrors ~= nil then file:write("server.scanErrors=\"" .. trueFalse(server.scanErrors) .. "\"\n") end
	if server.scanNoclip ~= nil then file:write("server.scanNoclip=\"" .. trueFalse(server.scanNoclip) .. "\"\n") end
	if server.scanZombies ~= nil then file:write("server.scanZombies=\"" .. trueFalse(server.scanZombies) .. "\"\n") end
	if server.serverGroup then file:write("server.serverGroup=\"" .. server.serverGroup .. "\"\n") end
	if server.shopCloseHour then file:write("server.shopCloseHour=" .. server.shopCloseHour .. "\n") end
	if server.shopCountdown then file:write("server.shopCountdown=" .. server.shopCountdown .. "\n") end
	if server.shopOpenHour then file:write("server.shopOpenHour=" .. server.shopOpenHour .. "\n") end
	if server.southeastZone then file:write("server.southeastZone=\"" .. server.southeastZone .. "\"\n") end
	if server.southwestZone then file:write("server.southwestZone=\"" .. server.southwestZone .. "\"\n") end
	if server.swearCash then file:write("server.swearCash=" .. server.swearCash .. "\n") end
	if server.swearFine then file:write("server.swearFine=" .. server.swearFine .. "\n") end
	if server.swearJar ~= nil then file:write("server.swearJar=\"" .. trueFalse(server.swearJar) .. "\"\n") end
	if server.teleportCost then file:write("server.teleportCost=" .. server.teleportCost .. "\n") end
	if server.teleportPublicCooldown then file:write("server.teleportPublicCooldown=" .. server.teleportPublicCooldown .. "\n") end
	if server.teleportPublicCost then file:write("server.teleportPublicCost=" .. server.teleportPublicCost .. "\n") end
	if server.telnetPort then file:write("server.telnetPort=" .. server.telnetPort .. "\n") end
	if server.trackingKeepDays then file:write("server.trackingKeepDays=" .. server.trackingKeepDays .. "\n") end
	if server.updateBot ~= nil then file:write("server.updateBot=\"" .. trueFalse(server.updateBot) .. "\"\n") end
	if server.updateBranch then file:write("server.updateBranch=\"" .. server.updateBranch .. "\"\n") end
	if server.warnColour then file:write("server.warnColour=\"" .. server.warnColour .. "\"\n") end
	if server.waypointCooldown then file:write("server.waypointCooldown=" .. server.waypointCooldown .. "\n") end
	if server.waypointCost then file:write("server.waypointCost=" .. server.waypointCost .. "\n") end
	if server.waypointCreateCost then file:write("server.waypointCreateCost=" .. server.waypointCreateCost .. "\n") end
	if server.whitelistCountries then file:write("server.whitelistCountries=\"" .. server.whitelistCountries .. "\"\n") end
	if server.zombieKillReward then file:write("server.zombieKillReward=" .. server.zombieKillReward .. "\n") end

	file:close()
end


function runTimedEvents()
	local cursor, errorString, rows, row

	if botman.dbConnected then
		-- make sure the announcements event exists
		cursor,errorString = conn:execute("SELECT * FROM timedEvents WHERE timer = 'announcements'")
		rows = cursor:numrows()

		if rows == 0 then
			conn:execute("INSERT INTO `timedEvents` (`timer`, `delayMinutes`, `nextTime`, `disabled`) VALUES ('announcements', 60, CURRENT_TIMESTAMP, 0)")
		end

		-- make sure the gimmeReset event exists
		cursor,errorString = conn:execute("SELECT * FROM timedEvents WHERE timer = 'gimmeReset'")
		rows = cursor:numrows()

		if rows == 0 then
			conn:execute("INSERT INTO `timedEvents` (`timer`, `delayMinutes`, `nextTime`, `disabled`) VALUES ('gimmeReset', 120, CURRENT_TIMESTAMP, 0)")
		end


		-- look for any events due to be triggered
		cursor,errorString = conn:execute("SELECT * FROM timedEvents WHERE nextTime <= NOW() AND disabled = 0")
		row = cursor:fetch({}, "a")

		while row do
			if row.timer == "announcements" then
				conn:execute("UPDATE timedEvents SET nextTime = NOW() + INTERVAL " .. row.delayMinutes .. " MINUTE WHERE timer = 'announcements'")
				sendNextAnnouncement()
			end

			if row.timer == "gimmeReset" then
				conn:execute("UPDATE timedEvents SET nextTime = NOW() + INTERVAL " .. row.delayMinutes .. " MINUTE WHERE timer = 'gimmeReset'")
				gimmeReset()
			end

			row = cursor:fetch(row, "a")
		end
	end
end


function sendNextAnnouncement(notRolling)
	local counter, cursor, errorString, rows, row, serverTime, triggerTime, dt
	local queued = false

	if (tonumber(botman.playersOnline) == 0) then -- don't bother if nobody is there to see it
		return
	end

	counter = 1

	if botman.dbConnected then
		if notRolling then
			-- do announcements that have a server trigger time set but skip any that are more than 1 minute late to prevent uncessary spammage
			cursor,errorString = conn:execute("SELECT * FROM announcements WHERE triggerServerTime <> '00:00:00'")
			row = cursor:fetch({}, "a")

			while row do
				serverTime = os.date("*t",  botman.serverTimeStamp) -- serverTime is now a Lua table with the current date and time split into parts

				dt = dateToTimestamp("2022-01-01 " .. row.triggerServerTime)
				triggerTime = os.date("*t",  dt) -- working with dates makes me triggered >:O

				if (serverTime.hour == triggerTime.hour) and (serverTime.min == triggerTime.min) then
					if row.lastTriggered == 0 or (os.time() - row.lastTriggered > 300) then
						connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','0','" .. connMEM:escape(row.message) .. "')")
						queued = true
					end

					conn:execute("UPDATE announcements SET lastTriggered = " .. os.time() .. " WHERE id = " .. row.id)
				end

				row = cursor:fetch(row, "a")
			end
		else
			-- do the rolling announcements
			cursor,errorString = conn:execute("SELECT * FROM announcements WHERE triggerServerTime = 0")
			rows = cursor:numrows()
			row = cursor:fetch({}, "a")

			while row do
				if tonumber(server.nextAnnouncement) == counter then
					connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','0','" .. connMEM:escape(row.message) .. "')")
					queued = true
				end

				counter = counter + 1
				row = cursor:fetch(row, "a")
			end

			server.nextAnnouncement = tonumber(server.nextAnnouncement) + 1
			if server.nextAnnouncement > tonumber(rows) then server.nextAnnouncement = 1 end
			conn:execute("UPDATE server SET nextAnnouncement = " .. server.nextAnnouncement)
		end
	end

	if queued then
		tempTimer(1, [[ botman.messageQueueEmpty = false  ]])
	end
end


function canSetWaypointHere(steam, x, z)
	local k, v, dist

	-- check for nearby bases that are not friendly
	for k, v in pairs(bases) do
		if (v.x ~= nil) and v.steam ~= steam then
				if (v.x ~= 0 and v.z ~= 0) then
				dist = distancexz(x, z, v.x, v.z)

				if (tonumber(dist) < tonumber(v.protectSize) + 10) then
					if not isFriend(v.steam, steam) then
						return false, v.steam
					end
				end
			end
		end
	end

	-- also check locations
	for k, v in pairs(locations) do
		if players[steam].inLocation == v.name then
			if not v.allowWaypoints then
				return false, k
			end
		end
	end

	return true
end


function initSpawnableItems()
	-- these could all be in one table but there are too many items and it couldn't hold them all
	-- Also to avoid lagging the bot we will process the items on a timer in a queue

	spawnableItems_numeric = {}
	spawnableItems_a = {}
	spawnableItems_b = {}
	spawnableItems_c = {}
	spawnableItems_d = {}
	spawnableItems_e = {}
	spawnableItems_f = {}
	spawnableItems_g = {}
	spawnableItems_h = {}
	spawnableItems_i = {}
	spawnableItems_j = {}
	spawnableItems_k = {}
	spawnableItems_l = {}
	spawnableItems_m = {}
	spawnableItems_n = {}
	spawnableItems_o = {}
	spawnableItems_p = {}
	spawnableItems_q = {}
	spawnableItems_r = {}
	spawnableItems_s = {}
	spawnableItems_t = {}
	spawnableItems_u = {}
	spawnableItems_v = {}
	spawnableItems_w = {}
	spawnableItems_x = {}
	spawnableItems_y = {}
	spawnableItems_z = {}
end


function updateGimme()
	local rowGimme, rowSpawnable, cursorGimme, cursorSpawnable, errorString, rows

	if type(spawnableItems) ~= "table" then
		return
	end

	if botman.dbConnected then
		-- walk the gimmePrizes table and check that each item exists in the table spawnableItems
		-- If they don't match, update the gimme prize so it matches spawnableItems
		cursorGimme,errorString = conn:execute("SELECT * FROM gimmePrizes")
		rowGimme = cursorGimme:fetch({}, "a")

		while rowGimme do
			if not spawnableItems[rowGimme.name] then
				conn:execute("DELETE FROM gimmePrizes WHERE name = '" .. escape(rowGimme.name) .. "'")
			else
				conn:execute("UPDATE gimmePrizes SET validated = 1 WHERE name = '" .. escape(rowGimme.name) .. "'")
			end

			rowGimme = cursorGimme:fetch(rowGimme, "a")
		end
	end
end


function updateShopItems()
	-- walk the shop table and check that each item exists in the table spawnableItems
	-- If they don't match, update the shop item so it matches spawnableItems
	-- If the item doesn't exist in A17 delete it from the shop

	local rowShop, rowSpawnable, cursorShop, cursorSpawnable, errorString, rows

	if type(spawnableItems) ~= "table" then
		return
	end

	if botman.dbConnected then

		cursorShop,errorString = conn:execute("SELECT * FROM shop")
		rowShop = cursorShop:fetch({}, "a")

		while rowShop do
			if not spawnableItems[rowShop.item] then
				conn:execute("DELETE FROM shop WHERE item = '" .. escape(rowShop.item) .. "'")
			else
				conn:execute("UPDATE shop SET validated = 1 WHERE item = '" .. escape(rowShop.item) .. "'")
			end

			rowShop = cursorShop:fetch(rowShop, "a")
		end
	end

	reindexShop()
end


function removeInvalidItems()
	-- do some manual fixes
	conn:execute("UPDATE shop SET item = 'resourceOil' WHERE item = 'oil'")
	conn:execute("UPDATE shop SET item = 'drugAntibiotics' WHERE item = 'antibiotics'")
	conn:execute("UPDATE shop SET item = 'drinkJarBeer' WHERE item = 'beer'")
	conn:execute("UPDATE shop SET item = 'drinkJarCoffee' WHERE item = 'coffee'")

	updateShopItems()
	updateGimme()

	-- don't remove anything from the tables, badItems or restrictedItems as those can contain wildcards

	-- refresh the restrictedItems table
	loadRestrictedItems()

	-- refresh the badItems table
	loadBadItems()
end


function collectSpawnableItemsList()
	-- flag items in various tables so we can remove invalid items later
	if botman.dbConnected then
		conn:execute("UPDATE badItems SET validated = 0")
		conn:execute("UPDATE gimmePrizes SET validated = 0")
		conn:execute("UPDATE restrictedItems SET validated = 0")
		conn:execute("UPDATE shop SET validated = 0")

		-- we have to give the database a second to finish updating or we might load in old data
		tempTimer( 1, [[loadShop()]] )
		tempTimer( 2, [[loadGimmePrizes()]] )
		tempTimer( 3, [[loadRestrictedItems()]] )
		tempTimer( 4, [[loadBadItems()]] )
	end

	if server.useAllocsWebAPI then
		botman.validateItems = true
	end

	tempTimer( 5, [[sendCommand("li *")]] )
end


function reloadItemLists()
	-- reload the shop and other items lists from the database
	loadShop()
	loadBadItems()
	loadRestrictedItems()
	loadGimmePrizes()
end


function isDestinationAllowed(steam, x, z)
	local outsideMap, loc, mapSize

	mapSize = LookupSettingValue(steam, "mapSize")

	outsideMap = squareDistance(x, z, mapSize)
	loc = inLocation(x, z)

	-- prevent player exceeding the map limit unless an admin and ignoreadmins is false
	if outsideMap and not isAdmin(steam) then
		if not loc then
			return false
		else
			-- check the locations access level restrictions
			if tonumber(locations[loc].accessLevel) < accessLevel(steam) then
				return false
			end
		end
	end

	return true
end


function searchBlacklist(IP, name)
	local IPInt

	IPInt = IPToInt(IP)
	cursor,errorString = connBots:execute("SELECT * FROM IPBlacklist WHERE StartIP <=  " .. IPInt .. " AND EndIP >= " .. IPInt)
	row = cursor:fetch({}, "a")

	if row then
		if igplayers[name] then
			message("pm " .. igplayers[name].userID .. " [" .. server.chatColour .. "]Found in blacklist.  startIP = " .. row.StartIP .. ", endIP = " .. row.EndIP .. "[-]")
		else
			irc_chat(name, "Found in blacklist.  startIP = " .. row.StartIP .. ", endIP = " .. row.EndIP)
		end
	else
		if igplayers[name] then
			message("pm " .. igplayers[name].userID .. " [" .. server.chatColour .. "]" .. IP .. " is not in the blacklist.[-]")
		else
			irc_chat(name, IP .. " is not in the blacklist.")
		end
	end
end


function savePlayers()
	local k,v

	for k,v in pairs(igplayers) do
		savePlayerData(k)
	end
end


function setChatColour(steam, level, groupID)
	local access

	if modBotman.disableChatColours then
		-- abort if the bot is not allowed to change chat colours
		return
	end

	if players[steam].prisoner then
		if string.upper(server.chatColourPrisoner) ~= "FFFFFF" then

			setPlayerColour(steam, server.chatColourPrisoner)
			return -- force prison colour
		end
	end

	if groupID then
		setPlayerColour(steam, playerGroups["G" .. groupID].chatColour)
		return
	end

	access = accessLevel(steam)

	if level ~= nil then
		access = tonumber(level)
	end

	-- change the colour of the player's name
	if players[steam].chatColour ~= "" then
		if string.upper(string.sub(players[steam].chatColour, 1, 6)) ~= "FFFFFF" then
			setPlayerColour(steam, stripAllQuotes(players[steam].chatColour))
			return
		end
	end

	if tonumber(access) == 0 then
		setPlayerColour(steam, server.chatColourOwner)
		return
	end

	if tonumber(access) == 1 then
		setPlayerColour(steam, server.chatColourAdmin)
		return
	end

	if tonumber(access) == 2 then
		setPlayerColour(steam, server.chatColourMod)
		return
	end

	if isDonor(steam) then
		setPlayerColour(steam, server.chatColourDonor)
		return
	end

	if tonumber(access) == 90 then
		setPlayerColour(steam, server.chatColourPlayer)
		return
	end

	if tonumber(access) == 99 then
		setPlayerColour(steam, server.chatColourNewPlayer)
		return
	end
end


function isLocationOpen(loc)
	local timeOpen, timeClosed, isOpen, closingSoon, gameHour

	gameHour = tonumber(server.gameHour)
	timeOpen = tonumber(locations[loc].timeOpen)
	timeClosed = tonumber(locations[loc].timeClosed)
	isOpen = true
	closingSoon = false

	-- check the location for opening and closing times
	if tonumber(locations[loc].dayClosed) > 0 then
		if ((server.gameDay + server.hordeNight - locations[loc].dayClosed) % server.hordeNight == 0) then
			return false, false
		end
	end

	if timeOpen == timeClosed then
		isOpen = true
	else
		if timeOpen < timeClosed then
			if gameHour >= timeClosed then
				isOpen = false
			end

			if gameHour < timeOpen then
				isOpen = false
			end
		else
			if gameHour >= timeClosed then
				isOpen = false
			end

			if gameHour >= timeOpen then
				isOpen = true
			end
		 end

		if timeClosed == 0 and gameHour == 23 then
			closingSoon = true
		end

		if timeClosed - gameHour == 1 then
			closingSoon = true
		end
	end

	return isOpen, closingSoon
end


function countGBLBans(steam)
	players[steam].GBLBans = 0

	cursor,errorString = connBots:execute("SELECT COUNT(GBLBan) AS totalBans FROM bans WHERE steam = '" .. steam .. "'")
	row = cursor:fetch({}, "a")
	players[steam].GBLBans = tonumber(row.totalBans)
end


function windowMessage(window, message, override)
	if server.enableWindowMessages or override then
		cecho(window, message)
	end
end


function scanForPossibleHackersNearby(steam, world)
	local k,v,dist,msg

	dist = 0

	for k,v in pairs(igplayers) do
		if (tonumber(players[k].hackerScore) > 20) and players[k].newPlayer then
			if world == nil then
				dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, v.xPos, v.zPos)
			end

			if dist < 301 then
				if LookupLocation("exile") then
					players[k].exiled = true
					players[k].silentBob = true
					players[k].canTeleport = false
					if botman.dbConnected then conn:execute("UPDATE players SET exiled = 1, silentBob = 1, canTeleport = 0 WHERE steam = '" .. k .. "'") end

					if world ~= nil then
						msg = v.name .. " has been sent to exile, detected with a non-zero hacker score."
					else
						msg = v.name .. " has been sent to exile, detected near " .. players[steam].name .. " with a non-zero hacker score."
					end

					message("say [" .. server.alertColour .. "]" .. msg .. "[-]")
					irc_chat(server.ircAlerts, server.gameDate .. " " .. msg)
				else
					timeoutPlayer(k, "reported by player and found with a non-zero hacker score", false)
				end
			end
		end
	end
end


function registerHelp(tmp)
	-- add the help command.  This will fail if the command already exists and the update command below will handle those.
	connSQL:execute("INSERT INTO helpCommands (command, description, notes, keywords, accessLevel, ingameOnly, functionName, topic) VALUES ('" .. connMEM:escape(tmp.command) .. "','" .. connMEM:escape(tmp.description) .. "','" .. connMEM:escape(tmp.notes) .. "','" .. connMEM:escape(tmp.keywords) .. "'," .. tmp.accessLevel .. "," .. tmp.ingameOnly .. ",'" .. connMEM:escape(tmp.functionName) .. "','" .. connMEM:escape(tmp.topic) .. "')")

	-- update the command, description, notes, keywords, and ingameOnly if the help already exists.
	-- don't touch access level as server owners can customise that.
	connSQL:execute("UPDATE helpCommands SET command = '" .. connMEM:escape(tmp.command) .. "', description = '" .. connMEM:escape(tmp.description) .. "', notes = '" .. connMEM:escape(tmp.notes) .. "', keywords = '" .. connMEM:escape(tmp.keywords) .. "', ingameOnly = " .. tmp.ingameOnly .. " WHERE functionName = '" .. connMEM:escape(tmp.functionName) .. "' AND topic = '" .. connMEM:escape(tmp.topic) .. "'")
end


function runRegisterHelp()
	gmsg(server.commandPrefix .. "register help")
end


function resetHelp(command)
	if botman.dbConnected then
		if command then
			connSQL:execute("DELETE FROM helpCommands WHERE functionName = '" .. connMEM:escape(command) .. "'")
		else
			connSQL:execute("DELETE FROM helpTopics")
			connSQL:execute("DELETE FROM helpCommands")
		end
	end
end


function isValidSteamID(steam)
	-- here we're testing 2 things.  that the id is numeric and that it contains 17 digits
	-- I'm also testing that it begins with 7656.  As far as I know all Steam keys begin with this.

	if string.len(steam) ~= 17 then
		return false
	end

	if string.sub(steam, 1, 4) ~= "7656" then
		return false
	end

	if ToInt(steam) == nil then
		return false
	end

	return true
end


function removeBadPlayerRecords()
	local k,v

	for k,v in pairs(players) do
		if (tonumber(v.id) < 1) then
			igplayers[k] = nil
			players[k] = nil
		end
	end

	if botman.dbConnected then conn:execute("DELETE FROM players WHERE id < 1") end
end


function timeRemaining(finishTime)
	local diff, days, hours, minutes

	diff = os.difftime(finishTime, os.time())
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (hours > 0) then
		diff = diff - (hours * 3600)
	end

	minutes = math.floor(diff / 60)

	return days, hours, minutes
end


function alertSpentMoney(steam, amount)
	if server.alertSpending then
		message("pm " .. igplayers[steam].userID .. " [" .. server.warnColour .. "]You spent " .. amount .. " " .. server.moneyPlural .. "[-]")
	end
end


function fixBot()
	local k, v

	botman.fixingBot = false

	fixMissingStuff()

	if server.useAllocsWebAPI then
		fixShop()
	end

	enableTimer("ReloadScripts")
	getServerData(true)

	-- join the irc server
	joinIRCServer()

	if botman.dbConnected then
		connSQL:execute("DELETE FROM altertables")
		alertAdmins("The bot may become unresponsive for a while doing database maintenance. A bot restart after the bot starts talking again may also help.", "alert")
		irc_chat(server.ircMain, "The bot may become unresponsive for a while doing database maintenance. A bot restart after the bot starts talking again may also help.")
		tempTimer( 5, [[alterTables()]] )
	end
end


function addFriend(player, friend, auto, noload)
	local tmp

	if auto == nil then auto = false end

	tmp = {}
	tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(friend)

	-- give a player a friend (yay!)
	-- returns true if a friend was added or false if already friends with them

	if not friends[player] then
		friends[player] = {}
		friends[player].friends = {}
	end

	if tmp.steam ~= "0" then
		if (not friends[player].friends[friend]) then
			if auto then
				if botman.dbConnected then
					conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES ('" .. player .. "','" .. tmp.steam .. "', 1)")
				end
			else
				if botman.dbConnected then
					conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES ('" .. player .. "','" .. tmp.steam .. "', 0)")
				end
			end

			if not noload then
				-- for reasons unknown the insert above fails if we immediately add the new friend to the friends lua table
				-- but it always works if we instead reload friends from the database a few seconds later.
				tempTimer( 3, [[loadFriends()]] )
			end

			return true
		else
			return false
		end
	else
		return false
	end
end


function getFriends(line)
	local pid, fpid, i, temp, max

	temp = string.split(line, ",")
	pid = string.trim(string.sub(temp[1], 14, 30))
	fpid = string.trim(string.sub(temp[2], 10, 26))

	-- delete auto-added friends from the MySQL table
	if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = " .. pid .. " AND autoAdded = 1") end

	if not friends[pid] then
		friends[pid] = {}
		friends[pid].friends = {}
	end

	-- add friends read from Coppi's lpf command
	-- grab the first one
	if not friends[pid].friends[fpid] then
		addFriend(pid, fpid, true)
	else
		if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. pid .. "," .. fpid .. ", 1)") end
	end

	-- grab the rest
	max = tablelength(temp)
	for i=3,max,1 do
		fpid = string.trim(temp[i])
		if not friends[pid].friends[fpid] then
			addFriend(pid, fpid, true)
		else
			if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. pid .. "," .. fpid .. ", 1)") end
		end
	end
end


function trimLogs()
	-- redundant code removed
	return true
end


function removeEntities()
	-- remove any entities that are flagged for removal after updating the list
	local k, v
	local maxCount = 0

	for k,v in pairs(otherEntities) do
		if v.remove ~= nil then
			otherEntities[k] = nil
		else
			maxCount = maxCount + 1
		end
	end

	botman.maxOtherEntities = maxCount
end


function updateOtherEntities(entityID, entity)
	local k, v, entityLower

	entityLower = string.lower(entity)

	if otherEntities == nil then
		otherEntities = {}
	end

	if otherEntities[entityID] == nil then
		-- new entity so add it to otherEntities
		otherEntities[entityID] = {}
		otherEntities[entityID].entity = entity
		otherEntities[entityID].doNotSpawn = false
		otherEntities[entityID].doNotDespawn = false

		-- don't despawn if it's cute, delicious or a dirty trader
		if string.find(entityLower, "pig") or string.find(entityLower, "boar") or string.find(entityLower, "stag") or string.find(entityLower, "chicken") or string.find(entityLower, "rabbit") or string.find(entityLower, "trader") then
			otherEntities[entityID].doNotDespawn = true
		end

		if string.find(entityLower, "template") or string.find(entityLower, "invisible") or string.find(entityLower, "container") or string.find(entityLower, "npc") or string.find(entityLower, "sc_") or string.find(entityLower, "crate") then
			otherEntities[entityID] = nil
		end
	else
		-- not new entity but entityID for this entity has changed so look for and remove the old entity and add it with the new entityID
		if otherEntities[entityID].entity ~= entity then
			for k,v in pairs(otherEntities) do
				if v.entity == entity then
					otherEntities[k] = nil
				end
			end

			-- now add the entity again with the new entityID
			otherEntities[entityID] = {}
			otherEntities[entityID].entity = entity
			otherEntities[entityID].doNotSpawn = false
			otherEntities[entityID].doNotDespawn = false
			otherEntities[entityID].remove = nil

			if string.find(entityLower, "template") or string.find(entityLower, "invisible") or string.find(entityLower, "container") or string.find(entityLower, "npc") or string.find(entityLower, "sc_") or string.find(entityLower, "crate") then
				otherEntities[entityID] = nil
			end

			-- don't despawn if it's cute, delicious or a dirty trader
			if string.find(entityLower, "pig") or string.find(entityLower, "boar") or string.find(entityLower, "stag") or string.find(entityLower, "chicken") or string.find(entityLower, "rabbit") or string.find(entityLower, "trader") then
				otherEntities[entityID].doNotDespawn = true
			end
		end
	end
end


function removeZombies()
	-- remove any zombies that are flagged for removal after updating the list
	local k, v
	local maxCount = 0

	for k,v in pairs(gimmeZombies) do
		if v.remove then
			gimmeZombies[k] = nil
		else
			maxCount = maxCount + 1
		end
	end

	botman.maxGimmeZombies = maxCount
end


function updateGimmeZombies(entityID, zombie)
	local k, v, a, b, zombieLower, found

	zombieLower = string.lower(zombie)
	found = false

	for k,v in pairs(gimmeZombies) do
		if v.entityID == entityID then
			found = true

			if v.zombie ~= zombie then
				-- the zombie for this entityid has changed so look for and remove the old zombie
				for a,b in pairs(gimmeZombies) do
					if b.zombie == zombie then
						gimmeZombies[a] = nil
					end
				end

				-- coz I am lazy we'll set found to false so that the code below adds this zombie.
				found = false
			end
		end
	end

	if not found then
		-- new zombie so add it to gimmeZombies
		gimmeZombies[entityID] = {}
		gimmeZombies[entityID].entityID = entityID
		gimmeZombies[entityID].zombie = zombie
		gimmeZombies[entityID].minPlayerLevel = 1
		gimmeZombies[entityID].minArenaLevel = 1
		gimmeZombies[entityID].bossZombie = false
		gimmeZombies[entityID].doNotSpawn = false
		gimmeZombies[entityID].maxHealth = 0
	end

	-- set up the boss zombies and prevent them and a few others spawning until we want them to.
	if string.find(zombieLower, "cop") or string.find(zombieLower, "dog") or string.find(zombieLower, "bear") or string.find(zombieLower, "feral") or string.find(zombieLower, "radiated") then
		gimmeZombies[entityID].doNotSpawn = true

		if string.find(zombieLower, "radiated") or string.find(zombieLower, "feral") then
			if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET bossZombie = 1, doNotSpawn = 1 WHERE entityID = " .. entityID) end
		else
			if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET bossZombie = 0, doNotSpawn = 1 WHERE entityID = " .. entityID) end
		end
	else
		if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET bossZombie = 0, doNotSpawn = 0 WHERE entityID = " .. entityID) end
	end

	if string.find(zombieLower, "template") or string.find(zombieLower, "invisible") then
		gimmeZombies[entityID] = nil
	end
end

function restrictedCommandMessage()
	local r

	chatvars.restrictedCommand = true

	if not igplayers[chatvars.playerid].restrictedCommand then
		igplayers[chatvars.playerid].restrictedCommand = true
		return("This command is restricted")
	else
		r = randSQL(16)
		if r == 1 then return("It's still restricted") end
		if r == 2 then return("This command is not happening") end
		if r == 3 then return("Which part of NO are you having trouble with?") end
		if r == 4 then return("You again?") end
		if r == 5 then return("We've been over this. N. O.") end
		if r == 6 then return("no No NO!") end
		if r == 7 then return("Have this command, you shall not.") end
		if r == 8 then return("Seriously?") end
		if r == 9 then return("This command is not for you.") end
		if r == 10 then return("Denied!") end
		if r == 11 then return("Give up.  You aren't using this command.") end
		if r == 12 then	return("I don't give a shit. That was a lie, but you're still not using this command.")	end
		if r == 13 then return("Bored now.") end
		if r == 14 then return("[DENIED]  [DENI[DEN[DENIED]ENIED]NIED]  [DENIED]") end
		if r == 15 then return("A bit slow are we? Noooooooooooooooo.") end
		if r == 16 then return("Yyyyyyeeee No.") end
	end
end


function read_Commands_JSON()
	local file, ln, fileSize, tmp, temp

	fileSize = lfs.attributes (homedir .. "/temp/commands.json", "size")

	-- abort if the file is empty
	if fileSize == nil or tonumber(fileSize) == 0 then
		return
	end

	file = io.open(homedir .. "/temp/commands.json", "r")

	for ln in file:lines() do
		if string.find(ln, "_") then
			tmp = {}
		end

		temp = string.match(ln, [[%s+"([^"]+)]])

		if temp and tmp then
			tmp.line = ln
			if string.find(ln, "_") then
				tmp.command = temp
				tmp.topic = string.sub(temp, 1, string.find(temp, "_") - 1)
				tmp.functionName = string.sub(temp, string.find(temp, "_") + 1)
			end

			if string.find(ln, "accessLevel") then
				tmp.accessLevel = tonumber(string.match(ln, "%d+"))
			end

			if string.find(ln, "ingameOnly") then
				if string.find(ln, "true") then
					tmp.ingameOnly = true
				else
					tmp.ingameOnly = false
				end

				helpCommands[tmp.command].accessLevel = tmp.accessLevel
				helpCommands[tmp.command].ingameOnly = tmp.ingameOnly

				connSQL:execute("UPDATE helpCommands SET accessLevel = " .. tmp.accessLevel .. ", ingameOnly = " .. dbBool(tmp.ingameOnly) .. " WHERE functionName = '" .. connMEM:escape(tmp.functionName) .. "' and topic = '" .. connMEM:escape(tmp.topic) .. "'")
			end
		end
	end

	irc_chat(server.ircMain, "The help command permissions have been updated from the imported commands.json file.")
	alertAdmins("The help command permissions have been updated from the imported commands.json file.")

	file:close()
	os.remove(homedir .. "/temp/commands.json")
end


function onHttpPostDone(_, url, body)
	local temp

	temp = yajl.to_value(body)
	botman.lastAPIResponseTimestamp = os.time()

	if temp.animals then
		readAPI_webUIUpdates_JSON(temp)
		return
	end

	if temp.firstLine then
		readAPI_ReadLog_JSON(temp)
		return
	end

	if temp.command == "pm" and temp.parameters == "apitest" then
		-- this is just a quick and dirty check to see if the API is accessible
		readAPI_webpermission_JSON(temp)
		return
	end

	if temp.command == "admin" and temp.parameters == "list" then
		readAPI_AdminList_JSON(temp)
		return
	end

	if temp.command == "ban" and temp.parameters == "list" then
		readAPI_BanList_JSON(temp)
		return
	end

	if temp.command == "bm-anticheat" and temp.parameters == "report" then
		readAPI_BMAnticheatReport_JSON(temp)
		return
	end

	if temp.command == "bm-listplayerbed" then
		readAPI_BMListPlayerBed_JSON(temp)
		return
	end

	if temp.command == "bm-listplayerfriends" then
		readAPI_BMListPlayerFriends_JSON(temp)
		return
	end

	if temp.command == "bm-playergrounddistance" then
		readAPI_PGD_JSON(temp)
		return
	end

	if temp.command == "bm-playerunderground" then
		readAPI_PUG_JSON(temp)
		return
	end

	if temp.command == "bm-readconfig" then
		readAPI_BMReadConfig_JSON(temp)
		return
	end

	if temp.command == "bm-resetregions" and temp.parameters == "list" then
		readAPI_BMResetRegionsList_JSON(temp)
		return
	end

	if temp.command == "bm-uptime" then
		readAPI_BMUptime_JSON(temp)
		return
	end

	if temp.command == "gg" then
		readAPI_GG_JSON(temp)
		return
	end

	if temp.command == "gt" then
		readAPI_GT_JSON(temp)
		return
	end

	if temp.command == "help" then
		readAPI_Help_JSON(temp)
		return
	end

	if temp.command == "le" then
		readAPI_LE_JSON(temp)
		return
	end

	if temp.command == "li" then
		readAPI_LI_JSON(temp)
		return
	end

	if temp.command == "lkp" then
		readAPI_LKP_JSON(temp)
		return
	end

	if temp.command == "llp" then
		readAPI_LLP_JSON(temp)
		return
	end

	if temp.command == "lp" then
		readAPI_LP_JSON(temp)
		return
	end

	if temp.command == "mem" then
		readAPI_MEM_JSON(temp)
		return
	end

	if temp.command == "se" then
		readAPI_SE_JSON(temp)
		return
	end

	if string.find(url, "gethostilelocation", nil, true) then
		readAPI_Hostiles_JSON(temp)
		return
	end

	if string.find(url, "getplayerinventories", nil, true) then
		readAPI_Inventories_JSON(temp)
		return
	end

	if string.find(url, "getplayersonline", nil, true) then
		readAPI_PlayersOnline_JSON(temp)
		return
	end

	if string.find(url, "getserverinfo", nil, true) then
		readAPI_GetServerInfo_JSON(temp)
		return
	end

	if temp.command == "version" then
		readAPI_Version_JSON(temp)
		return
	end

	-- this is a catchall for any command results not matched above and must be last
	readAPI_Command_JSON(temp)
end


function downloadHandler(event, ...)
	local steam

   if event == "sysDownloadDone" then
		botman.fileDownloadTimestamp = nil
		botman.APIOffline = false
		botman.botOfflineCount = 0

		if customAPIHandler ~= nil then
			-- read the note on overriding bot code in custom/custom_functions.lua
			if customAPIHandler(...) then
				return
			end
		end

		if string.find(..., "commands.json", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()

			-- read commands.json and update the command permissions using it
			read_Commands_JSON()
			return
		end

		if string.find(..., "voteCheck_", nil, true) then
			-- check vote response from 7daystodie-servers.com
			steam = string.sub(..., string.find(..., "voteCheck_") + 10, string.find(..., ".txt") - 1)
			readServerVote(steam)
			return
		end

		if string.find(..., "voteClaim_", nil, true) then
			-- we don't need to process or keep this file.  Just delete it.
			os.remove(...)
			return
		end

   elseif event == "sysDownloadError" then
	   failDownload(event, ...) -- Oh no!  Critical failure!
	end
end


function failDownload(event, filePath)
	botman.lastAPIResponseTimestamp = os.time()

	if botman.APIOfflineCount == nil then
		botman.APIOfflineCount = 0
	end

	 if string.find(filePath, "Forbidden") and string.find(filePath, "api/", nil, true) then
		botman.APIOffline = true
		botman.APIOfflineCount = tonumber(botman.APIOfflineCount) + 1

		if botman.telnetOffline and botman.APIOffline then
			botman.botOffline = true
			return
		end

		if not botman.telnetOffline then
			if not server.readLogUsingTelnet then
				server.readLogUsingTelnet = true
				toggleTriggers("api offline")
			end
		end
	 end

	 if string.find(filePath, "Socket operation timed out") then
		botman.APIOffline = true
		botman.APIOfflineCount = tonumber(botman.APIOfflineCount) + 1

		if server.readLogUsingTelnet then
			toggleTriggers("api offline")
		end

		if botman.telnetOffline and botman.APIOffline then
			botman.botOffline = true
			return
		end
	 end

	if string.find(filePath, "Connection refused") then
		if not botman.APIOffline then
			irc_chat(server.ircMain, "The API is refusing connections and the server may be offline. The bot will keep trying to reach the server.")
		end

		botman.APIOffline = true
		botman.APIOfflineCount = tonumber(botman.APIOfflineCount) + 1

		if server.readLogUsingTelnet then
			toggleTriggers("api offline")
		end

		if botman.telnetOffline and botman.APIOffline then
			botman.botOffline = true
			return
		end
	end
end


function isReservedName(player, steam)
	local k, v, pos

	-- strip any trailing (1) or other numbers in brackets
	if string.find(player, "%(%d+%)$") then
		player = string.sub(player, 1, string.find(player, "%(%d+%)$") - 1)
	end

	for k,v in pairs(players) do
		if (v.name == player) and (k ~= steam) then
			if tonumber(v.accessLevel) < 3 then
				return true
			end

			if tonumber(v.accessLevel) ~= tonumber(accessLevel(steam)) and igplayers[k] then
				return true
			end
		end
	end

	return false
end


function inWhitelist(steam)
	local cursor, errorString, row

	-- is the player in the whitelist?
	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM whitelist WHERE steam = '" .. steam .. "'")
		row = cursor:fetch({}, "a")

		if row then
			return true
		else
			return false
		end
	else
		return false
	end
end


function atHome(steam)
	local dist, size, greet, home, time, k, v

	greet = false
	home = false

	if players[steam].lastAtHome == nil then
		players[steam].lastAtHome = os.time()
	end

	for k,v in pairs(bases) do
		if v.steam == steam then
			-- is player in this base?
			if math.abs(v.x) > 0 and math.abs(v.z) > 0 then
				dist = distancexz(players[steam].xPos, players[steam].zPos, v.x, v.z)
				size = tonumber(v.protectSize)

				if (dist <= size + 30) then
					home = true

					if not players[steam].atHome then
						greet = true
					end
				end
			end
		end
	end

	if greet then
		time = os.time() - players[steam].lastAtHome
	end

	if home then
		players[steam].atHome = true
		players[steam].lastAtHome = os.time()
	else
		players[steam].atHome = false
	end
end


function calcTimestamp(str)
	-- takes input like 1 week, 1 month, 1 year and outputs a timestamp that much in the future
	local number, period

	str = string.lower(str)
	number = math.abs(math.floor(tonumber(string.match(str, "(-?%d+)"))))

	if string.find(str, "minute") then
		period = 60
	end

	if string.find(str, "hour") then
		period = 60 * 60
	end

	if string.find(str, "day") then
		period = 60 * 60 * 24
	end

	if string.find(str, "week") then
		period = 60 * 60 * 24 * 7
	end

	if string.find(str, "month") then
		period = 60 * 60 * 24 * 30
	end

	if string.find(str, "year") then
		period = 60 * 60 * 24 * 365
	end

	if number and period then
		return os.time() + period * number
	else
		return 0
	end
end


function timestampToString(timestamp, inThePast)
	local diff, days, hours, minutes, seconds

	-- calc days, hours, minutes, and seconds to or from a timestamp against the current system time.

	if inThePast then
		-- timestamp is in the past
		diff = os.difftime(os.time(), timestamp)
	else
		-- timestamp is in The Future(tm)
		diff = os.difftime(timestamp, os.time())
	end

	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (hours > 0) then
		diff = diff - (hours * 3600)
	end

	minutes = math.floor(diff / 60)
	seconds = diff - (minutes * 60)

	return days, hours, minutes, seconds
end


function countAlphaNumeric(test)
	local count
	-- return the number of alphanumeric characters in test

	local _, count = string.gsub(test, "%w", "")
	return count
end


function pmsg(msg, all)
	local k,v

	-- queue msg for output by a timer
	for k,v in pairs(igplayers) do
		if all ~= nil or players[k].noSpam == false then
			if botman.dbConnected then connSQL:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES ('0','" .. k .. "','" .. connMEM:escape(msg) .. ")") end
			--botman.messageQueueEmpty = false
		end
	end

	tempTimer(1, [[ botman.messageQueueEmpty = false  ]])
end


function strDateToTimestamp(strdate)
	-- Unix timestamps end in 2038.  To prevent invalid dates, we will force year to 2030 if it is later.
	local sday, smonth, syear, shour, sminute, sseconds = strdate:match("(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)")

	-- don't allow dates over 2030.  timestamps stop at 2038
	if tonumber(syear) > 2030 then syear = 2030 end

	return os.time({year = syear, month = smonth, day = sday, hour = shour, min = sminute, sec = sseconds})
end


function getEquipment(equipment, item)
	-- search the most recent inventory recording for an item and if found return how much there is and best quality if applicable
	local tbl, test, i, found, quantity, quality, max

	found = false
	quality = 0
	quantity = 0
	tbl = string.split(equipment, "|")

	max = tablelength(tbl)
	for i=1, max, 1 do
		test = string.split(tbl[i], ",")

		if test[2] == item then
			found = true

			if tonumber(test[3]) > tonumber(quality) then
				quality = tonumber(test[3])
			end
		end
	end

	if found then
		return true, quality
	else
		return false, 0
	end
end


function getInventory(inventory, item)
	-- search the most recent inventory recording for an item and if found return how much there is and best quality if applicable
	local tbl, test, i, found, quantity, quality, max

	found = false
	quality = 0
	quantity = 0
	tbl = string.split(inventory, "|")

	max = tablelength(tbl)
	for i=1, max, 1 do
		test = string.split(tbl[i], ",")
		if test[3] == item then
			found = true
			quantity = quantity + tonumber(test[2])

			if tonumber(test[4]) > tonumber(quality) then
				quality = tonumber(test[4])
			end
		end
	end

	if found then
		return true, quantity, quality
	else
		return false, 0 , 0
	end
end


function inInventory(steam, item, quantity, slot)
	-- search the most recent inventory recording for an item
	local tbl, test, i, max

	if botman.dbConnected then
		cursor,errorString = connINVTRAK:execute("SELECT * FROM inventoryTracker WHERE steam = '" .. steam .. "'  ORDER BY timestamp DESC LIMIT 1")
		row = cursor:fetch({}, "a")

		tbl = string.split(row.belt .. row.pack .. row.equipment, "|")

		max = tablelength(tbl)
		for i=1, max, 1 do
			test = string.split(tbl[i], ",")
			if slot ~= nil then
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item and tonumber(test[1]) == slot then
					return true
				end
			else
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item then
					return true
				end
			end
		end
	end

	return false
end


function inBelt(steam, item, quantity, slot)
	-- search the most recent inventory recording for an item in the belt
	local tbl, test, i, max

	if botman.dbConnected then
		cursor,errorString = connINVTRAK:execute("SELECT * FROM inventoryTracker WHERE steam = '" .. steam .. "'  ORDER BY timestamp DESC LIMIT 1")
		row = cursor:fetch({}, "a")

		tbl = string.split(row.belt, "|")

		max = tablelength(tbl)
		for i=1, max, 1 do
			test = string.split(tbl[i], ",")
			if slot ~= nil then
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item and tonumber(test[1]) == slot then
					return true
				end
			else
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item then
					return true
				end
			end
		end
	end

	return false
end


function mapPosition(steam)
	-- express the player's coordinates as a compass bearing
	local ns, ew

	if tonumber(players[steam].xPos) < 0 then
		ew = math.abs(players[steam].xPos).. " W"
	else
		ew = players[steam].xPos .. " E"
	end

	if tonumber(players[steam].zPos) < 0 then
		ns = math.abs(players[steam].zPos) .. " S"
	else
		ns = players[steam].zPos .. " N"
	end

	return ns .. " " .. ew
end


function validBasePosition(steam)
	local k, v, isValid, dist, minimumDist

	isValid = true -- yay!

	if tonumber(server.baseDeadzone) > tonumber(server.baseSize) * 2 then
		minimumDist = tonumber(server.baseDeadzone)
	else
		minimumDist = tonumber(server.baseSize) * 2
	end

	-- check that y position is between bedrock and the max build height
	if tonumber(players[steam].yPos) < 1 or tonumber(players[steam].yPos) > 255 then
		isValid = false -- drat!
	end

	-- check for nearby unfriendly bases
	for k, v in pairs(bases) do
		if v.steam ~= steam then
			dist = distancexz(players[steam].xPos, players[steam].zPos, v.x, v.z)

			if tonumber(dist) < tonumber(minimumDist) then
				if not isFriend(v.steam, steam) then
					isValid = false -- curses!
				end
			end
		end
	end

	return isValid
end


function savePosition(steam, temp)
	-- helper function to save the players position
	if tonumber(players[steam].yPos) > -1 and tonumber(players[steam].yPos) < 256 then
		-- store the player's current x y z
		if temp == nil then
			players[steam].xPosOld = players[steam].xPos
			players[steam].yPosOld = players[steam].yPos + 1
			players[steam].zPosOld = players[steam].zPos

			if botman.dbConnected then conn:execute("UPDATE players SET xPosOld = " .. players[steam].xPosOld .. ", yPosOld = " .. players[steam].yPosOld .. ", zPosOld = " .. players[steam].zPosOld .. " WHERE steam = '" .. steam .. "'") end
		else
			players[steam].xPosOld2 = players[steam].xPos
			players[steam].yPosOld2 = players[steam].yPos + 1
			players[steam].zPosOld2 = players[steam].zPos

			if botman.dbConnected then conn:execute("UPDATE players SET xPosOld2 = " .. players[steam].xPosOld2 .. ", yPosOld2 = " .. players[steam].yPosOld2 .. ", zPosOld2 = " .. players[steam].zPosOld2 .. " WHERE steam = '" .. steam .. "'") end
		end
	end
end


function seen(steam)
	-- when was a player last in-game?
	local words, word, diff, tmp

	if players[steam].seen == "" then
		return "A new player on for the first time now."
	end

	if igplayers[steam] then
		return players[steam].name .. " is on the server now."
	end

	tmp = {}
	words = {}
	for word in botman.serverTime:gmatch("%w+") do table.insert(words, word) end

	tmp.ryear = words[1]
	tmp.rmonth = words[2]
	tmp.rday = string.sub(words[3], 1, 2)
	tmp.rhour = string.sub(words[3], 4, 5)
	tmp.rmin = words[4]
	tmp.rsec = words[5]

	tmp.dateNow = {year=tmp.ryear, month=tmp.rmonth, day=tmp.rday, hour=tmp.rhour, min=tmp.rmin, sec=tmp.rsec}
	tmp.now = os.time(tmp.dateNow)

	words = {}
	if players[steam] then
		tmp.name = players[steam].name
		for word in players[steam].seen:gmatch("%w+") do table.insert(words, word) end
	else
		tmp.name = playersArchived[steam].name
		for word in playersArchived[steam].seen:gmatch("%w+") do table.insert(words, word) end
	end

	tmp.ryear = words[1]
	tmp.rmonth = words[2]
	tmp.rday = string.sub(words[3], 1, 2)
	tmp.rhour = string.sub(words[3], 4, 5)
	tmp.rmin = words[4]
	tmp.rsec = words[5]
	tmp.dateSeen = {year=tmp.ryear, month=tmp.rmonth, day=tmp.rday, hour=tmp.rhour, min=tmp.rmin, sec=tmp.rsec}
	tmp.seen = os.time(tmp.dateSeen)

	diff = os.difftime(tmp.now, tmp.seen)
	tmp.days = math.floor(diff / 86400)

	if (tmp.days > 0) then
		diff = diff - (tmp.days * 86400)
	end

	tmp.hours = math.floor(diff / 3600)

	if (tmp.hours > 0) then
		diff = diff - (tmp.hours * 3600)
	end

	tmp.minutes = math.floor(diff / 60)

	return tmp.name .. " was last seen " .. tmp.days .. " days " .. tmp.hours .. " hours " .. tmp.minutes .." minutes ago"
end


function messageAdmins(message)
	-- helper function to send a message to all staff
	local k,v

	for k, v in pairs(players) do
		if (isAdmin(k, v.userID)) then
			if igplayers[k] then
				message("pm " .. v.userID .. " [" .. server.chatColour .. "]" .. message .. "[-]")
			else
				if botman.dbConnected then connSQL:execute("INSERT INTO mail (sender, recipient, message) VALUES ('0','" .. k .. "', '" .. connMEM:escape(message) .. "')") end
			end
		end
	end
end


function kick(id, reason)
	local tmp

	tmp = {}

	if reason ~= nil then
		stripAngleBrackets(reason)
	end

	tmp.id = id
	tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(tmp.id)

	if tmp.steam == "0" then
		tmp.userID = tmp.id
	end

	if tmp.steam ~= "0" then
		if igplayers[tmp.steam] and reason ~= "Server restarting." then
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[tmp.steam].xPos .. "," .. players[tmp.steam].yPos .. "," .. players[tmp.steam].zPos .. ",'" .. botman.serverTime .. "','kick','Player " .. tmp.steam .. " " .. escape(players[tmp.steam].name) .. " kicked for " .. escape(reason) .. "','" .. tmp.steam .. "')") end
		end

		sendCommand("kick " .. tmp.userID .. " " .. " \"" .. reason .. "\"")
		botman.playersOnline = tonumber(botman.playersOnline) - 1
		irc_chat(server.ircMain, "Player " .. tmp.userID .. " kicked. Reason: " .. reason)

		return
	end

	if tmp.userID ~= "" then
		sendCommand("kick " .. tmp.userID .. " " .. " \"" .. reason .. "\"")
		irc_chat(server.ircMain, "Player " .. tmp.userID .. " kicked. Reason: " .. reason)

		return
	end
end


function banPlayer(platform, userID, steam, duration, reason, issuer, localOnly)
	local tmp, LU_ID, LU_Owner, LU_UserID, player
	local tmp, belt, pack, equipment, country, isArchived, playerName

	tmp = {}
	tmp.platform = platform
	tmp.userID = userID
	tmp.steam = steam
	tmp.duration = duration
	tmp.reason = reason
	tmp.issuer = issuer
	tmp.localOnly = false
	tmp.admin = 0
	tmp.belt = ""
	tmp.pack = ""
	tmp.equipment = ""
	tmp.country = ""
	tmp.isArchived = false
	tmp.name = "Unknown player name" -- placeholder in case we're banning someone that hasn't played here yet.

	if localOnly then
		tmp.localOnly = localOnly
	end

	if string.find(tmp.steam, "_") then
		tmp.split = string.split(tmp.steam, "_")
		tmp.steam = tmp.split[2]
	end

	if not players[tmp.steam] then
		LU_ID, LU_Owner, LU_UserID = LookupArchivedPlayer(tmp.steam)

		if not (LU_ID == "0") then
			player = playersArchived[LU_ID]
			tmp.name = player.name
			tmp.isArchived = true
		end
	else
		player = players[tmp.steam]
		tmp.name = player.name
		tmp.isArchived = false
	end

	if isAdminHidden(tmp.steam, tmp.userID) then
		irc_chat(server.ircAlerts, "Request to ban admin " .. tmp.name .. "  [DENIED]")

		if tmp.issuer ~= "" then
			message("pm " .. tmp.issuer .. " [" .. server.chatColour .. "]Request to ban admin " .. tmp.name .. "  [DENIED][-]")
		end

		return
	end

	if reason == nil then
		tmp.reason = "banned"
	else
		tmp.reason = stripAngleBrackets(reason)
	end

	if tmp.issuer then
		tmp.admin = tmp.issuer
	end

	tmp.OldSteam = tmp.steam
	-- if there is no player with steamid steam, try looking it up incase we got their name instead of their steam
	if not players[tmp.steam] then
		LU_ID, LU_Owner, LU_UserID = LookupPlayer(string.trim(tmp.steam))

		if LU_ID == "0" then
			LU_ID, LU_Owner, LU_UserID = LookupArchivedPlayer(string.trim(tmp.steam))
		end

		if players[LU_ID] then
			player = players[LU_ID]
			tmp.platform = player.platform
			tmp.steam = LU_ID
			tmp.userID = LU_UserID
		end

		-- restore the original steam value if nothing matched as we may be banning someone who's never played here.
		if LU_ID == "0" then tmp.steam = tmp.OldSteam end
	else
		player = players[tmp.steam]
		tmp.userID = player.userID
	end

	if tmp.userID == "" and LU_UserID then
		tmp.userID = LU_UserID
	end

	if tmp.userID == "" and tmp.steam ~= "" then
		if tmp.platform == "" then
			if string.len(tmp.steam) == 17 then
				tmp.platform = "Steam_"
			else
				tmp.platform = "XBL_"
			end
		end

		tmp.userID = tmp.platform .. tmp.steam
	end

	sendCommand("ban add " .. tmp.userID .. " " .. tmp.duration .. " \"" .. tmp.reason .. "\"")

	-- grab their belt, pack and equipment
	if players[tmp.steam] or playersArchived[tmp.steam] then
		if not tmp.isArchived then
			tmp.country = players[tmp.steam].country
		else
			tmp.country = playersArchived[tmp.steam].country
		end

		if botman.dbConnected then
			cursor,errorString = connINVTRAK:execute("SELECT * FROM inventoryTracker WHERE steam = '" .. tmp.steam .."' ORDER BY timestamp DESC LIMIT 1")
			row = cursor:fetch({}, "a")

			if row then
				tmp.belt = row.belt
				tmp.pack = row.pack
				tmp.equipment = row.equipment
			end

			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. player.xPos .. "," .. player.yPos .. "," .. player.zPos .. ",'" .. botman.serverTime .. "','ban','Player " .. tmp.steam .. " " .. escape(player.name) .. " has has been banned for " .. tmp.duration .. " for " .. escape(tmp.reason) .. "','" .. tmp.steam .. "')")
		end

		tmp.banMessage = "Player " .. tmp.steam .. " " .. player.name .. " has been banned for " .. tmp.duration .. " " .. tmp.reason

		irc_chat(server.ircMain, "[BANNED] " .. tmp.banMessage)
		irc_chat(server.ircAlerts, server.gameDate .. " [BANNED] " .. tmp.banMessage)
		alertAdmins(tmp.banMessage)

		-- add to bots db
		if botman.botsConnected and not tmp.localOnly then
			if player then
				if tonumber(player.pendingBans) > 0 then
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin, GBLBan, GBLBanActive, level) VALUES ('" .. escape("MISSING") .. "','" .. tmp.steam .. "','" .. escape(tmp.reason) .. "'," .. tonumber(player.timeOnServer) + tonumber(player.playtime) .. "," .. player.score .. "," .. player.playerKills .. "," .. player.zombies .. ",'" .. tmp.country .. "','" .. escape(tmp.belt) .. "','" .. escape(tmp.pack) .. "','" .. escape(tmp.equipment) .. "','" .. server.botID .. "','" .. tmp.admin .. "',1,1," .. player.level .. ")")
					irc_chat(server.ircMain, "Player " .. tmp.steam .. " " .. player.name .. " has been globally banned.")
					message("say [" .. server.alertColourColour .. "]" .. player.name .. " has been globally banned.[-]")
				else
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin, level) VALUES ('" .. escape("MISSING") .. "','" .. tmp.steam .. "','" .. escape(tmp.reason) .. "'," .. tonumber(player.timeOnServer) + tonumber(player.playtime) .. "," .. player.score .. "," .. player.playerKills .. "," .. player.zombies .. ",'" .. tmp.country .. "','" .. escape(tmp.belt) .. "','" .. escape(tmp.pack) .. "','" .. escape(tmp.equipment) .. "','" .. server.botID .. "','" .. tmp.admin .. "'," .. player.level .. ")")
				end
			end
		end

		-- Look for and also ban ingame players with the same IP
		if player then
			for k,v in pairs(igplayers) do
				if v.ip == player.ip and k ~= tmp.steam and v.ip ~= "" then
					sendCommand("ban add " .. v.userID .. " " .. tmp.duration .. " \"same IP as banned player\"")

					if botman.dbConnected then
						cursor,errorString = connINVTRAK:execute("SELECT * FROM inventoryTracker WHERE steam = '" .. k .. "' ORDER BY timestamp DESC LIMIT 1")
						row = cursor:fetch({}, "a")
						if row then
							tmp.belt = row.belt
							tmp.pack = row.pack
							tmp.equipment = row.equipment
						end

						conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[k].xPos .. "," .. players[k].yPos .. "," .. players[k].zPos .. ",'" .. botman.serverTime .. "','ban','Player " .. k .. " " .. escape(players[k].name) .. " has has been banned for " .. tmp.duration .. " for " .. escape("same IP as banned player") .. "','" .. k .. "')")
					end

					irc_chat(server.ircMain, "[BANNED] Player " .. k .. " " .. players[k].name .. " has been banned for " .. tmp.duration .. " same IP as banned player")
					irc_chat(server.ircAlerts, server.gameDate .. " [BANNED] Player " .. k .. " " .. players[k].name .. " has been banned for " .. tmp.duration .. " same IP as banned player")
					alertAdmins("Player " .. players[k].name .. " has been banned for " .. tmp.duration .. " same IP as banned player")

					-- add to bots db
					if botman.botsConnected then
						connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin, level) VALUES ('" .. escape("MISSING") .. "','" .. k .. "','" .. escape("same IP as banned player") .. "'," .. tonumber(players[k].timeOnServer) + tonumber(players[k].playtime) .. "," .. players[k].score .. "," .. players[k].playerKills .. "," .. players[k].zombies .. ",'" .. players[k].country .. "','" .. escape(tmp.belt) .. "','" .. escape(tmp.pack) .. "','" .. escape(tmp.equipment) .. "','" .. server.botID .. "','" .. tmp.admin .. "'," .. players[k].level .. ")")
					end
				end
			end
		end
	else
		-- handle unknown steam id
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','ban','Player " .. tmp.steam .. " " .. tmp.steam .. " has has been banned for " .. tmp.duration .. " for " .. escape(tmp.reason) .. "','" .. tmp.steam .. "')") end
		irc_chat(server.ircMain, "[BANNED] Unknown player " .. tmp.steam .. " has been banned for " .. tmp.duration .. " " .. tmp.reason)
		irc_chat(server.ircAlerts, server.gameDate .. " [BANNED] Unknown player " .. tmp.steam .. " has been banned for " .. tmp.duration .. " " .. tmp.reason)

		-- add to bots db
		if botman.botsConnected then
			connBots:execute("INSERT INTO bans (bannedTo, steam, reason, permanent, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin) VALUES ('" .. escape("MISSING") .. "','" .. tmp.steam .. "','" .. escape(tmp.reason) .. "',1,0,0,0,0,'','','','','" .. server.botID .. "','" .. tmp.admin .. "')")
		end
	end
end


function arrest(id, reason, bail, releaseTime)
	local banTime = 60
	local cmd, prison
	local steam, steamOwner, userID, platform

	steam, steamOwner, userID, platform = LookupPlayer(id)

	prison = LookupLocation("prison")

	if not prison then
		if tonumber(server.maxPrisonTime) > 0 then
			banTime = server.maxPrisonTime
		end

		message("say [" .. server.alertColour .. "]" .. players[steam].name .. " has been banned for " .. banTime .. " minutes for " .. reason .. ".[-]")
		banPlayer(platform, userID, steam, banTime .. " minutes", reason, "")
		return
	end

	players[steam].prisoner = true
	players[steam].prisonReason = reason

	if releaseTime ~= nil then
		players[steam].prisonReleaseTime = os.time() + (releaseTime * 60)
	else
		players[steam].prisonReleaseTime = os.time() + (server.maxPrisonTime * 60)
	end

	if igplayers[steam] then
		players[steam].prisonxPosOld = igplayers[steam].xPos
		players[steam].prisonyPosOld = igplayers[steam].yPos
		players[steam].prisonzPosOld = igplayers[steam].zPos
		igplayers[steam].xPosOld = igplayers[steam].xPos
		igplayers[steam].yPosOld = igplayers[steam].yPos
		igplayers[steam].zPosOld = igplayers[steam].zPos
		irc_chat(server.ircAlerts, server.gameDate .. " " .. players[steam].name .. " has been sent to prison for " .. reason .. " at " .. igplayers[steam].xPosOld .. " " .. igplayers[steam].yPosOld .. " " .. igplayers[steam].zPosOld)
		setChatColour(steam, players[steam].accessLevel)
	else
		players[steam].prisonxPosOld = players[steam].xPos
		players[steam].prisonyPosOld = players[steam].yPos
		players[steam].prisonzPosOld = players[steam].zPos
		players[steam].xPosOld = players[steam].xPos
		players[steam].yPosOld = players[steam].yPos
		players[steam].zPosOld = players[steam].zPos
		irc_chat(server.ircAlerts, server.gameDate .. " " .. players[steam].name .. " has been sent to prison for " .. reason .. " at " .. players[steam].xPosOld .. " " .. players[steam].yPosOld .. " " .. players[steam].zPosOld)
	end

	players[steam].bail = bail

	if not isAdmin(steam, userID) and (tonumber(bail) == 0) then
		players[steam].silentBob = true
		if botman.dbConnected then conn:execute("UPDATE players SET prisoner = 1, silentBob = 1, bail = 0, prisonReleaseTime = " .. players[steam].prisonReleaseTime .. ", prisonxPosOld = " .. players[steam].prisonxPosOld .. ", prisonyPosOld = " .. players[steam].prisonyPosOld .. ", prisonzPosOld = " .. players[steam].prisonzPosOld .. " WHERE steam = '" .. steam .. "'") end
	else
		if botman.dbConnected then conn:execute("UPDATE players SET prisoner = 1, bail = " .. bail .. ", prisonReleaseTime = " .. players[steam].prisonReleaseTime .. ", prisonxPosOld = " .. players[steam].prisonxPosOld .. ", prisonyPosOld = " .. players[steam].prisonyPosOld .. ", prisonzPosOld = " .. players[steam].prisonzPosOld .. " WHERE steam = '" .. steam .. "'") end
	end

	if botman.dbConnected then
		cursor,errorString = connSQL:execute("SELECT count(*) FROM locationSpawns WHERE location='prison'")
		rowSQL = cursor:fetch({}, "a")
		rowCount = rowSQL["count(*)"]

		if rowCount > 0 then
			randomTP(steam, userID, "prison", true)
		else
			cmd = "tele " .. steam .. " " .. locations[prison].x .. " " .. locations[prison].y .. " " .. locations[prison].z
			teleport(cmd, steam, userID, true)
		end
	else
		cmd = "tele " .. steam .. " " .. locations[prison].x .. " " .. locations[prison].y .. " " .. locations[prison].z
		teleport(cmd, steam, userID, true)
	end

	message("say [" .. server.warnColour .. "]" .. players[steam].name .. " has been sent to prison.  Reason: " .. reason .. ".[-]")
	message("pm " .. userID .. " [" .. server.chatColour .. "]You are confined to prison until released.[-]")

	if tonumber(bail) > 0 then
		message("pm " .. userID .. " [" .. server.chatColour .. "]You can release yourself for " .. bail .. " " .. server.moneyPlural .. ".[-]")
		message("pm " .. userID .. " [" .. server.chatColour .. "]Type " .. server.commandPrefix .. "bail to release yourself if you have the " .. server.moneyPlural .. ".[-]")
	end

	if tonumber(releaseTime) > 0 then
		days, hours, minutes = timeRemaining(os.time() + (releaseTime * 60))
		message("pm " .. userID .. " [" .. server.chatColour .. "]You will be released in " .. days .. " days " .. hours .. " hours and " .. minutes .. " minutes.[-]")
	end

	if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[steam].xPos .. "," .. players[steam].yPos .. "," .. players[steam].zPos .. ",'" .. botman.serverTime .. "','prison','Player " .. steam .. " " .. escape(players[steam].name) .. " has has been sent to prison for " .. escape(reason) .. "','" .. steam .. "')") end
end


function timeoutPlayer(steam, reason, bot)
	local userID, steamOwner

	steam, steamOwner, userID = LookupPlayer(steam)

	-- if the player is not already in timeout, send them there.
	if players[steam].timeout == false and players[steam].botTimeout == false then
		players[steam].timeout = true
		if not isAdmin(steam) then players[steam].silentBob = true end
		if bot then players[steam].botTimeout = true end -- the bot initiated this timeout
		-- record their position for return
		players[steam].xPosTimeout = players[steam].xPos
		players[steam].yPosTimeout = players[steam].yPos
		players[steam].zPosTimeout = players[steam].zPos

		if botman.dbConnected then
			conn:execute("UPDATE players SET timeout = 1, botTimeout = " .. dbBool(bot) .. ", xPosTimeout = " .. players[steam].xPosTimeout .. ", yPosTimeout = " .. players[steam].yPosTimeout .. ", zPosTimeout = " .. players[steam].zPosTimeout .. " WHERE steam = '" .. steam .. "'")
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[steam].xPos .. "," .. players[steam].yPos .. "," .. players[steam].zPos .. ",'" .. botman.serverTime .. "','timeout','Player " .. steam .. " " .. escape(players[steam].name) .. " has has been sent to timeout for " .. escape(reason) .. "','" .. steam .. "')")
		end

		-- then teleport the player to timeout
		igplayers[steam].tp = 1
		igplayers[steam].hackerTPScore = 0
		sendCommand("tele " .. userID .. " " .. players[steam].xPosTimeout .. " 60000 " .. players[steam].zPosTimeout)
		message("say [" .. server.chatColour .. "]Sending player " .. players[steam].name .. " to timeout for " .. reason .. "[-]")
		irc_chat(server.ircAlerts, server.gameDate .. " [TIMEOUT] Player " .. steam .. " " .. players[steam].name .. " has been sent to timeout for " .. reason)
	end
end


function removeClaims()
	local k, v, a, b, dist, testing

	if botman.dbConnected then
		for k, v in pairs(keystones) do
			testing = false

			if players[v.steam] then
				if players[v.steam].testAsPlayer then
					testing = true
				end
			end

			if (v.remove and not isAdmin(v.steam)) and not testing then
				for a, b in pairs(igplayers) do
					dist = distancexz(v.x, v.z, b.xPos, b.zPos)

					if dist < 100 and v.removed == 0 then
						v.removed = 1
						connSQL:execute("UPDATE keystones SET removed = 1 WHERE steam = '" .. v.steam .. "' AND x = " .. v.x .. " AND y = " .. v.y .. " AND z = " .. v.z)
						sendCommand("rlp " .. v.x .. " " .. v.y .. " " .. v.z) -- BAM! and the claim is gone :D
					end
				end
			end
		end
	end
end


function dbWho(name, x, y, z, dist, days, hours, height, steamid, ingame, useShadowCopy)
	local cursor, errorString, row, counter, isStaff, sql
	local steam, steamOwner, userID

	steam, steamOwner, userID = LookupPlayer(steamid)

	isStaff = false

	if days == nil then days = 1 end
	if height == nil then height = 5 end

	if not botman.dbConnected then
		return
	end

	if isAdmin(steam, userID) then
		isStaff = true
	end

	if not useShadowCopy then
		if tonumber(hours) > 0 then
			sql = "SELECT DISTINCT steam, session FROM tracker WHERE abs(x - " .. x .. ") <= " .. dist .. " AND ABS(z - " .. z .. ") <= " .. dist .. " AND ABS(y - " .. y .. ") <= " .. height .. " AND timestamp >= '" .. os.time() - (tonumber(hours) * 3600) .. "'"
			cursor,errorString = connTRAK:execute(sql)
		else
			sql = "SELECT DISTINCT steam, session FROM tracker WHERE abs(x - " .. x .. ") <= " .. dist .. " AND ABS(z - " .. z .. ") <= " .. dist .. " AND ABS(y - " .. y .. ") <= " .. height .. " AND timestamp >= '" .. os.time() - (tonumber(days) * 86400) .. "'"
			cursor,errorString = connTRAK:execute(sql)
		end
	else
		if tonumber(hours) > 0 then
			sql = "SELECT DISTINCT steam, session FROM tracker WHERE abs(x - " .. x .. ") <= " .. dist .. " AND ABS(z - " .. z .. ") <= " .. dist .. " AND ABS(y - " .. y .. ") <= " .. height .. " AND timestamp >= '" .. os.time() - (tonumber(hours) * 3600) .. "'"
			cursor,errorString = connTRAKSHADOW:execute(sql)
		else
			sql = "SELECT DISTINCT steam, session FROM tracker WHERE abs(x - " .. x .. ") <= " .. dist .. " AND ABS(z - " .. z .. ") <= " .. dist .. " AND ABS(y - " .. y .. ") <= " .. height .. " AND timestamp >= '" .. os.time() - (tonumber(days) * 86400) .. "'"
			cursor,errorString = connTRAKSHADOW:execute(sql)
		end
	end

	row = cursor:fetch({}, "a")
	counter = 1

	while row do
		if ingame then
			if isStaff then
				if players[row.steam] then
					message("pm " .. userID .. " [" .. server.chatColour .. "]" .. row.steam .. " " .. players[row.steam].id .. " " .. players[row.steam].name .. " sess: " .. row.session .. "[-]")
				else
					message("pm " .. userID .. " [" .. server.chatColour .. "]" .. row.steam .. " " .. playersArchived[row.steam].id .. " " .. playersArchived[row.steam].name .. " (archived) sess: " .. row.session .. "[-]")
				end
			else
				if players[row.steam] then
					message("pm " .. userID .. " [" .. server.chatColour .. "]" .. players[row.steam].name .. " session: " .. row.session .. "[-]")
				else
					message("pm " .. userID .. " [" .. server.chatColour .. "]" .. playersArchived[row.steam].name .. " session: " .. row.session .. "[-]")
				end
			end
		else
			if isStaff then
				if players[row.steam] then
					irc_chat(name, "#" .. counter .." " .. row.steam .. " " .. players[row.steam].name .. " sess: " .. row.session)
				else
					irc_chat(name, "#" .. counter .." " .. row.steam .. " " .. playersArchived[row.steam].name .. " (archived) sess: " .. row.session)
				end
			else
				if players[row.steam] then
					irc_chat(name, players[row.steam].name .. " session: " .. row.session)
				else
					irc_chat(name, playersArchived[row.steam].name .. " session: " .. row.session)
				end
			end
		end

		counter = counter + 1
		row = cursor:fetch(row, "a")
	end
end


function getGuides() -- grab latest versions of various guides
	-- grab the group commands guide
	if botman.webdavFolderWriteable then
		-- get player groups noobie guide
		os.execute("wget https://files.botman.nz/guides/Player_Groups_Noobie_Guide.pdf -O " .. botman.chatlogPath .. "/guides/Player_Groups_Noobie_Guide.pdf")

		-- get locations noobie guide
		os.execute("wget https://files.botman.nz/guides/Locations_Noobie_Guide.pdf -O " .. botman.chatlogPath .. "/guides/Locations_Noobie_Guide.pdf")

		-- get waypoints noobie guide
		os.execute("wget https://files.botman.nz/guides/Waypoints_Noobie_Guide.pdf -O " .. botman.chatlogPath .. "/guides/Waypoints_Noobie_Guide.pdf")

		-- get the bot commands for players guide
		os.execute("wget https://files.botman.nz/guides/Bot_Commands_For_Players.pdf -O " .. botman.chatlogPath .. "/guides/Bot_Commands_For_Players.pdf")
	end
end


function dailyMaintenance()
	local cursor, errorString, row

	-- put something here to be run when the server date hits midnight
	getGuides()
	updateBot()

	-- purge old tracking data and set a flag so we can tell when the database maintenance is complete.
	if tonumber(server.trackingKeepDays) > 0 then
		deleteTrackingDataSQLite(server.trackingKeepDays)
		deleteTrackingData(server.trackingKeepDays)
	end

	-- Bring out yer dead!

	-- delete telnet logs older than server.telnetLogKeepDays
	os.execute("find " .. homedir .. "/telnet_logs/* -mtime +" .. server.telnetLogKeepDays .. " -exec rm {} \\;")

	-- delete other old logs
	os.execute("find " .. botman.chatlogPath .. "/*inventory.txt -mtime +" .. server.telnetLogKeepDays .. " -exec rm {} \\;")
	os.execute("find " .. botman.chatlogPath .. "/*botcommandlog.txt -mtime +7 -exec rm {} \\;")
	os.execute("find " .. botman.chatlogPath .. "/*commandlog.txt -mtime +90 -exec rm {} \\;")
	os.execute("find " .. botman.chatlogPath .. "/*alertlog.txt -mtime +90 -exec rm {} \\;")
	os.execute("find " .. botman.chatlogPath .. "/*panel.txt -mtime +30 -exec rm {} \\;")

	return true
end


function expireDonors()
	local cursor, errorString, row, tmp

	tmp = {}

	-- expire donors who's expiry is in the past
	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM donors WHERE expired = 0")
		row = cursor:fetch({}, "a")

		if row then
			while row do
				if tonumber(row.expiry) < os.time() then
					tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(row.steam)
					removeDonor(tmp.steam)
					irc_chat(server.ircAlerts, "Player " .. players[tmp.steam].name ..  " " .. tmp.steam .. " donor status has expired.")
					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','donor','" .. escape(players[tmp.steam].name) .. " " .. tmp.steam .. " donor status expired.','" .. tmp.steam .."')")
				end

				row = cursor:fetch(row, "a")
			end
		end

		-- delete expired donor records older than 1 day
		conn:execute("DELETE FROM donors WHERE expiry < " .. os.time() - 86400)

		-- make sure we have the current player names in the donors table
		conn:execute("UPDATE donors SET name = (SELECT name FROM players WHERE donors.steam = players.steam)")

		-- reload bases from the database
		tempTimer( 1, [[loadBases()]] )

		-- reload donors from the database
		tempTimer( 1, [[loadDonors()]] )
	end
end


function startReboot()
	botman.serverRebooting = true

	sendCommand("kickall \"Server restarting\"")
	botman.rebootTimerID = tempTimer( 5, [[finishReboot()]] )
	sendCommand("sa")
end


function finishReboot()
	local k, v

	if (botman.rebootTimerID) then
		killTimer(botman.rebootTimerID)
		botman.rebootTimerID = nil
	end

	if (rebootTimerDelayID) then
		killTimer(rebootTimerDelayID)
		rebootTimerDelayID = nil
	end

	botman.ignoreAdmins = true
	-- server.uptime = 0
	-- server.serverStartTimestamp = os.time()

	-- flag all players as offline
	--connBots:execute("UPDATE players SET online = 0 WHERE botID = " .. server.botID)

	if botman.allowReboot then
		server.allowReboot = botman.allowReboot
	end

	clearRebootFlags()
	connMEM:execute("DELETE FROM TABLE tracker")
	connSQL:execute("DELETE FROM commandQueue")
	connMEM:execute("DELETE FROM TABLE gimmeQueue")
	tempTimer( 5, [[sendCommand("shutdown")]] )

	-- do some housekeeping
	for k, v in pairs(players) do
		v.botQuestion = ""
	end

	-- check for bot updates
	updateBot()
end


function clearRebootFlags()
	botman.nextRebootTest = os.time() + 300
	botman.scheduledRestart = false
	botman.scheduledRestartTimestamp = os.time()
	botman.scheduledRestartPaused = false
	botman.scheduledRestartForced = false
	botman.serverRebooting = false

	rebootCountDown1 = nil
	rebootCountDown2 = nil
	rebootCountDown3 = nil
	rebootCountDown4 = nil
	rebootCountDown5 = nil
	rebootCountDown6 = nil
	rebootCountDown7 = nil
	rebootCountDown8 = nil
	rebootCountDown9 = nil
	rebootCountDown10 = nil
	rebootCountDown11 = nil
end


function newDay()
	local diff, days, restarting, status

	restarting = false

	if server.dateTest == nil then
		server.dateTest = string.sub(botman.serverTime, 1, 10)
	end

	if (string.sub(botman.serverTime, 1, 10) ~= server.dateTest) then
		server.dateTest = string.sub(botman.serverTime, 1, 10)

		if telnetLogFileName then
			if os.time() - botman.botStarted > 20 then
				logTelnet("=== END OF TELNET LOG ===")

				-- force logging to start a new file
				telnetLogFile:close()
				telnetLogFileName = homedir .. "/telnet_logs/" .. os.date("%Y-%m-%d#%H-%M-%S") .. ".txt"
				telnetLogFile = io.open(telnetLogFileName, "a")
			end
		end

		dailyMaintenance()
		resetShop()

		if tonumber(botman.playersOnline) < 16 then
			saveLuaTables()
		end

		-- if bot can restart itself and botRestartDay isn't zero, check how many days the bot has been running.
		-- if bot uptime is greater than botRestartDay, restart the bot.
		if server.allowBotRestarts and server.botRestartDay > 0 then
			diff = os.difftime(os.time(), botman.botStarted)
			days = math.floor(diff / 86400)

			if days >= server.botRestartDay then
				restarting = true
				tempTimer( 30, [[restartBot()]] )
			end
		end

		if not restarting then
			-- reload the bot's code.  This may help fix a few issues with slow performance but its more likely due to other stuff the reload does.
			dofile(homedir .. "/scripts/reload_bot_scripts.lua")
			reloadBotScripts(true, false, true)
		end

		status = "Server is UP"

		if botman.botOffline then
			status "Server is OFFLINE"
		end

		if relogCount > 6 then
			status "Telnet has crashed."
		end

		if botman.botOffline == false then
			irc_chat("#status", "Bot " .. server.botName .. " on server " .. server.serverName .. " " .. server.IP .. ":" .. server.ServerPort .. " Game version: " .. server.gameVersion)
			irc_chat("#status", "Status: " .. status .. ", bot version: " .. server.botVersion .. " on branch " .. server.updateBranch)
		end
	end
end


function newBotDay()
	-- do stuff when the date changes where the bot is running (usually different to the 7 Days server's date)
	connSQL:execute("DELETE FROM joiningPlayers WHERE timestamp < " .. os.time() - 86400)
end


function IPToInt(ip)
	local o1,o2,o3,o4

	o1,o2,o3,o4 = ip:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
	return 2^24*o1 + 2^16*o2 + 2^8*o3 + o4
end


function readIPBlacklist()
	-- very slow.  don't run with a full server
	local ln
	local iprange

	local o1,o2,o3,o4
	local num1,num2

	for ln in io.lines(homedir .. "/cn.csv") do
		iprange = string.split(ln, ",")

		o1,o2,o3,o4 = iprange[1]:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
		num1 = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4

		o1,o2,o3,o4 = iprange[2]:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
		num2 = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4

		connBots:execute("INSERT INTO IPBlacklist (StartIP, EndIP) VALUES (" .. num1 .. "," .. num2 .. ")")
	end
end


function Translate(playerid, command, lang, override)
	local words, word, oldCount, matches

	os.remove(botman.userHome .. "/" .. server.botID .. "trans.txt")
	os.execute(botman.userHome .. "/" .. server.botID .. "trans.txt")

	-- disabled for now.
	if true then
		return
	end

	words = {}
	for word in command:gmatch("%S+") do table.insert(words, word) end
	oldCount = tablelength(words)

	if lang == "" then
		os.execute("trans -b -no-ansi \"" .. command .. "\" > " .. botman.userHome .. "/" .. server.botID .. "trans.txt")
	else
		os.execute("trans -b -no-ansi {en=" .. lang .."}  \"" .. command .. "\" > " .. botman.userHome .. "/" .. server.botID .. "trans.txt")
	end

	for ln in io.lines(botman.userHome .. "/" .. server.botID .. "trans.txt") do
		matches = 0
		for word in ln:gmatch("%S+") do
			if string.find(command, word, nil, true) then
				matches = matches + 1
			end
		end

		if matches < 2 then
			if ln ~= command and string.trim(ln) ~= "" then
				if players[playerid].translate == true or override ~= nil then
					message("say [BDFFFF]" .. players[playerid].name .. " [-]" .. ln)
				end

				if players[playerid].translate == false then
					irc_chat(server.ircMain, players[playerid].name .. " " .. ln)
				end
			end
		end
	end

	io.close()
end


function CheckClaimsRemoved(steam)
	local row, cursor, errorString

	cursor,errorString = connSQL:execute("SELECT count(remove) as deleted FROM keystones WHERE steam = '" .. steam .. "' AND removed = 1")
	row = cursor:fetch({}, "a")

	if row then
		if tonumber(row.deleted) > 0 then
			players[steam].removedClaims = players[steam].removedClaims + tonumber(row.deleted)
			if botman.dbConnected then conn:execute("UPDATE players SET removedClaims = " .. players[steam].removedClaims .. " WHERE steam = '" .. steam .. "'") end

			cursor,errorString = connSQL:execute("SELECT * FROM keystones WHERE steam = '" .. steam .. "' AND removed = 1")
			row = cursor:fetch({}, "a")

			while row do
				keystones[row.x .. row.y .. row.z] = nil
				row = cursor:fetch(row, "a")
			end

			connSQL:execute("DELETE FROM keystones WHERE steam = '" .. steam .. "' AND removed = 1")

			if not string.find(players[steam].lastCommand, "give") then
				message("pm " .. players[steam].userID .. " [" .. server.chatColour .. "]Some of your claims have been removed.  You can get them back by typing " .. server.commandPrefix .. "give claims.[-]")
			end
		end
	end
end


function CheckBlacklist(steam, ip)
	-- if blacklist action is not exile or ban, nothing happens to the player.
	ip = ip:gsub("::ffff:", "")

	local o1,o2,o3,o4 = ip:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
	local ipint = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4
	local k, v, cursor, errorString

	if not botman.botsConnected then
		return
	end

	-- test for China IP
	ipint = tonumber(ipint)

	cursor,errorString = connBots:execute("SELECT * FROM IPBlacklist WHERE StartIP <=  " .. ipint .. " AND EndIP >= " .. ipint)
	if cursor:numrows() > 0 then
		if (not (whitelist[steam] or isDonor(steam))) and not isAdmin(steam) then
			irc_chat(server.ircMain, "Blacklisted IP detected. " .. players[steam].name)
			irc_chat(server.ircAlerts, server.gameDate .. " blacklisted IP detected. " .. players[steam].name)
		end

		players[steam].china = true
		players[steam].country = "CN"
		players[steam].ircTranslate = true

		if server.blacklistResponse == 'exile' and (not (whitelist[steam] or isDonor(steam))) and not isAdmin(steam) then
			if not players[steam].exiled then
				players[steam].exiled = true
				if botman.dbConnected then conn:execute("UPDATE players SET country = 'CN', exiled = 1, ircTranslate = 1 WHERE steam = '" .. steam .. "'") end
			end
		end

		if server.blacklistResponse == 'ban' and (not (whitelist[steam] or isDonor(steam))) and not isAdmin(steam) then
			irc_chat(server.ircMain, "Blacklisted player " .. players[steam].name .. " banned.")
			irc_chat(server.ircAlerts, server.gameDate .. " blacklisted player " .. players[steam].name .. " banned.")
			banPlayer("Steam", "", steam, "10 years", "blacklisted", "")
			--connBots:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (" .. players[steam].xPos .. "," .. players[steam].yPos .. "," .. players[steam].zPos .. ",'" .. botman.serverTime .. "','info','Blacklisted player joined and banned. Name: " .. escape(player) .. " SteamID: " .. steam .. " IP: " .. ip  .. "'," .. steam .. ")")
		end
	else
		-- do a reverse dns lookup if we haven't already got an IP range for this IP
		-- This isn't perfect since IP range ownership can change but its accuracy should be good enough.  We can always nuke the list periodically.
		cursor,errorString = connBots:execute("SELECT * FROM IPTable WHERE StartIP <=  " .. ipint .. " AND EndIP >= " .. ipint)
		if cursor:numrows() == 0 then
			reverseDNS(steam, ip)
		end
	end
end


function getDNSLookupCounter()
	local cursor, errorString, row, rows

	-- make sure the settings table isn't empty :O
	cursor,errorString = connBots:execute("SELECT * FROM settings")
	if cursor:numrows() == 0 then
		connBots:execute("INSERT INTO settings (`DNSLookupCounter`) VALUES (0)")
	end

	-- make sure DNSResetCounterDate is not older than today
	connBots:execute("UPDATE settings SET DNSResetCounterDate = CURDATE() + 0 WHERE DNSResetCounterDate < CURDATE() + 0")

	-- now select the DNS lookup server
	cursor,errorString = connBots:execute("SELECT * FROM settings WHERE DNSResetCounterDate = CURDATE() + 0")
	rows = cursor:numrows()

	if rows > 0 then
		row = cursor:fetch({}, "a")

		if row.DNSLookupCounter then
			if tonumber(row.DNSLookupCounter) < 500 then
				-- pick this DNS lookup server and add to the lookupCounter
				connBots:execute("UPDATE settings SET DNSLookupCounter = DNSLookupCounter + 1")
				return tonumber(row.DNSLookupCounter)
			else
				-- reset the counter and set the resetDate to tomorrow
				connBots:execute("UPDATE settings SET DNSLookupCounter = 0, DNSResetCounterDate = CURDATE() + 1")
			end
		end
	end

	-- select -1 which will tell us not to do a DNS lookup
	return -1
end


function reverseDNS(steam, ip)
	local lookupLimit

	if players[steam].newPlayer then
		lookupLimit = 3
	else
		lookupLimit = 1
	end

	if players[steam].DNSLookupCount == nil then
		players[steam].DNSLookupCount = 0
	end

	if players[steam].lastDNSLookup == nil then
		players[steam].lastDNSLookup = "1000-01-01"
	end

	if players[steam].lastDNSLookup ~= os.date("%Y-%m-%d") then
		players[steam].DNSLookupCount = 0
	end

	if tonumber(players[steam].DNSLookupCount) < lookupLimit then
		-- to avoid being blacklisted for doing too many dns lookups in 24 hours we will stop doing them until tomorrow once we reach 500 lookups
		DNSLookupCounter = getDNSLookupCounter()

		if DNSLookupCounter == -1 then
			return
		end

		players[steam].DNSLookupCount = players[steam].DNSLookupCount + 1
		players[steam].lastDNSLookup = os.date("%Y-%m-%d")
		-- launch the utility called whois
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
		os.execute("whois " .. ip:gsub("::ffff:", "") .. " > \"" .. homedir .. "/dns/" .. steam .. ".txt\"")
		tempTimer( 30, [[readDNS("]] .. steam .. [[")]] )
	end
end


function readDNS(steam)
	-- if blacklist action is not exile or ban, nothing happens to the player.
	-- NOTE: If blacklist action is nothing, proxies won't trigger a ban or exile response either.

	local file, fileSize, ln, split, ip1, ip2, exiled, banned, country, onBlacklist, proxy, ISP, iprange, IP

	fileSize = lfs.attributes (homedir .. "/dns/" .. steam .. ".txt", "size")

	-- abort if the file is empty
	if fileSize == nil or tonumber(fileSize) == 0 then
		return
	end

	file = io.open(homedir .. "/dns/" .. steam .. ".txt", "r")
	exiled = false
	banned = false
	proxy = false
	onBlacklist = false
	country = ""
	ISP = ""
	iprange = ""

	for ln in file:lines() do
		ln = string.upper(ln)

		if string.find(ln, "ERROR:201: ACCESS DENIED") then -- oh noes!  We got blacklisted :(
			return
		end

		if string.find(ln, "NON-RIPE-NCC-MANAGED-ADDRESS-BLOCK") then -- No point reading this DNS.
			return
		end

		if string.find(ln, "%s(%d+)%.(%d+)%.(%d+)%.(%d+)%s") then
			a,b = string.find(ln, "%s(%d+)%.(%d+)%.(%d+)%.(%d+)%s")
			iprange = string.sub(ln, a, a+b)

			-- convert the start IP, end IP and player's IP to integers
			split = string.split(iprange, "%-")
			ip1 = IPToInt(string.trim(split[1]))
			ip2 = IPToInt(string.trim(split[2]))

			-- player's IP
			IP = IPToInt(players[steam].ip)
		end

		if (not (whitelist[steam] or isDonor(steam))) and (not server.allowProxies) and not isAdmin(steam) then
			for k,v in pairs(proxies) do
				if string.find(ln, string.upper(v.scanString), nil, true) then
					v.hits = tonumber(v.hits) + 1
					proxy = true

					if botman.botsConnected then
						connBots:execute("UPDATE proxies SET hits = hits + 1 WHERE scanString = '" .. escape(k) .. "'")
					end

					if botman.dbConnected then
						connSQL:execute("UPDATE proxies SET hits = hits + 1 WHERE scanString = '" .. connMEM:escape(k) .. "'")
					end

					if server.blacklistResponse ~= 'nothing' and not isAdmin(steam) then
						if v.action == "ban" or v.action == "" then
							irc_chat(server.ircMain, "Player " .. players[steam].name .. " banned. Detected proxy " .. v.scanString)
							irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " banned. Detected proxy " .. v.scanString)
							banPlayer("Steam", "", steam, "10 years", "Banned proxy. Contact us to get unbanned and whitelisted.", "")
							banned = true
						else
							if not players[steam].exiled then
								players[steam].exiled = true
								irc_chat(server.ircMain, "Player " .. players[steam].name .. " exiled. Detected proxy " .. v.scanString)
								irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " exiled. Detected proxy " .. v.scanString)
								exiled = true
							end
						end
					end
				end
			end
		end

		if string.find(ln, "ABUSE") and string.find(ln, "@") then
			-- record the domain after the @ and store as the player's ISP
			ISP = string.sub(ln, string.find(ln, "@") + 1)
			players[steam].ISP = ISP
		end

		if string.find(ln, "CHINA") then
			country = "CN"
			players[steam].country = "CN"
			onBlacklist = true
		end

		if string.find(ln, "OUNTRY:") or (ln == "ADDRESS:        CN") or (ln == "ADDRESS:        HK") then
			-- only report country change if CN or HK are involved. For once, don't blame Canada.
			a,b = string.find(ln, "%s(%w+)")
			country = string.sub(ln, a + 1)
			if players[steam].country ~= "" and players[steam].country ~= country and (players[steam].country == "CN" or players[steam].country == "HK" or country == "CN" or country == "HK") and (not (whitelist[steam] or isDonor(steam))) and not isAdmin(steam) then
				irc_chat(server.ircAlerts, server.gameDate .. " possible proxy detected! Country changed! " .. steam .. " " .. players[steam].name .. " " .. players[steam].ip .. " old country " .. players[steam].country .. " new " .. country)
				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0'" .. botman.serverTime .. "','proxy','Suspected proxy used by " .. escape(players[steam].name) .. " " .. players[steam].ip .. " old country " .. players[steam].country .. " new " .. country .. ",'" .. steam .. "')") end
				proxy = true
			else
				 players[steam].country = country
			end

			if country == "CN" or country == "HK" then
				onBlacklist = true
			end
		end

		-- We consider HongKong to be China since Chinese players connect from there too.
		if (country == "CN" or country == "HK") and (not (whitelist[steam] or isDonor(steam))) and not isAdmin(steam) then
			-- China detected. Add ip range to IPBlacklist table
			irc_chat(server.ircMain, "Chinese IP detected. " .. players[steam].name .. " " .. players[steam].ip)
			irc_chat(server.ircAlerts, server.gameDate .. " Chinese IP detected. " .. players[steam].name .. " " .. players[steam].ip)
			players[steam].china = true
			players[steam].ircTranslate = true

			if server.blacklistResponse == 'exile' and not exiled and not isAdmin(steam) then
				if not players[steam].exiled then
					players[steam].exiled = true
					irc_chat(server.ircMain, "Chinese player " .. players[steam].name .. " exiled.")
					irc_chat(server.ircAlerts, server.gameDate .. " Chinese player " .. players[steam].name .. " exiled.")
					exiled = true
				end
			end

			if server.blacklistResponse == 'ban' and not banned and not isAdmin(steam) then
				irc_chat(server.ircMain, "Chinese player " .. players[steam].name .. " banned.")
				irc_chat(server.ircAlerts, server.gameDate .. " Chinese player " .. players[steam].name .. " banned.")
				banPlayer("Steam", "", steam, "10 years", "blacklisted", "")
				banned = true
			end

			if botman.botsConnected then
				if iprange ~= "" then
					-- check that player's IP is actually within the discovered IP range
					if IP >= ip1 and IP <= ip2 then
						irc_chat(server.ircMain, "Added new Chinese IP range " .. iprange .. " to blacklist")
						connBots:execute("INSERT INTO IPBlacklist (StartIP, EndIP, Country, OrgName) VALUES (" .. ip1 .. "," .. ip2 .. ",'" .. country .. "','" .. escape(ISP) .. "')")
					end
				end
			end

			file:close()

			-- got country so stop processing the dns record
			break
		end
	end

	if not onBlacklist and not proxy and iprange ~= "" then
		-- check that player's IP is actually within the discovered IP range
		if IP >= ip1 and IP <= ip2 then
			-- Attempt to insert the IP range and info into IPTable.  It will fail if it is already there which if fine and more efficient than checking first.
			connBots:execute("INSERT INTO IPTable (StartIP, EndIP, Country, OrgName, IP, steam, botID) VALUES (" .. ip1 .. "," .. ip2 .. ",'" .. country .. "','" .. escape(ISP) .. "','" .. players[steam].ip .. "','" .. steam .. "'," .. server.botID .. ")")
		end
	end

	-- alert players
	if blacklistedCountries[country] and server.blacklistResponse ~= 'ban' and (not (whitelist[steam] or isDonor(steam))) and not isAdmin(steam) then
		for k, v in pairs(igplayers) do
			if players[k].exiled~=1 and not players[k].prisoner then
				message("pm " .. v.userID .. " Player " .. players[steam].name .. " from blacklisted country " .. country .. " has joined.[-]")
			end
		end
	end

	if blacklistedCountries[country] and (not (whitelist[steam] or isDonor(steam))) and not isAdmin(steam) then
		if server.blacklistResponse == 'ban' and not banned then
			irc_chat(server.ircMain, "Player " .. players[steam].name .. " banned. Blacklisted country " .. country)
			irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " banned. Blacklisted country " .. country)
			banPlayer("Steam", "", steam, "10 years", "Sorry, your country has been blacklisted :(", "")
			banned = true
		end

		if server.blacklistResponse == 'exile' and not exiled then
			if not players[steam].exiled then
				players[steam].exiled = true
				irc_chat(server.ircMain, "Player " .. players[steam].name .. " exiled. Blacklisted country " .. country)
				irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " exiled. Blacklisted country " .. country)
				exiled = true
			end
		end
	end

	if server.whitelistCountries ~= '' and not whitelistedCountries[country] and (not (whitelist[steam] or isDonor(steam))) and not banned and not isAdmin(steam) then
		irc_chat(server.ircMain, "Player " .. players[steam].name .. " temp banned 1 month. Country not on whitelist " .. country)
		irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " temp banned 1 month. Country not on whitelist " .. country)
		banPlayer("Steam", "", steam, "1 month", "Sorry, this server uses a whitelist.", "")
		banned = true
	end

	if botman.dbConnected then
		if server.blacklistResponse ~= 'nothing' and exiled and (not (whitelist[steam] or isDonor(steam))) and not isAdmin(steam) then
			conn:execute("UPDATE players SET country = '" .. escape(country) .. "', exiled = 1, ircTranslate = 1 WHERE steam = '" .. steam .. "'")
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[steam].xPos .. "," .. players[steam].yPos .. "," .. players[steam].zPos .. ",'" .. botman.serverTime .. "','info','Blacklisted player joined. Name: " .. escape(player) .. " SteamID: " .. steam .. " IP: " .. players[steam].ip  .. "','" .. steam .. "')")
		end
	end

	if proxy then
		os.rename(homedir .. "/dns/" .. steam .. "_old.txt", homedir .. "/proxies/" .. steam .. "_" .. country .. ".txt")
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/proxies/" .. steam .. "_" .. country .. ".txt")
	else
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	end

	if botman.dbConnected then conn:execute("UPDATE players SET country = '" .. country .. "' WHERE steam = '" .. steam .. "'") end

	file:close()

	if not proxy then
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	end
end


function resetPlayer(steam)
	-- reset many values in the player table for a specific player but leave others alone such as donor status.

	players[steam].alertMapLimit = false
	players[steam].alertPrison = true
	players[steam].alertPVP = true

	if server.gameType == "pvp" then
		players[steam].alertPVP = false
	end
	players[steam].alertReset = true
	players[steam].atHome = false
	players[steam].baseCooldown = 0
	players[steam].bedX = 0
	players[steam].bedY = 0
	players[steam].bedZ = 0
	players[steam].block = false
	players[steam].botTimeout = false
	players[steam].botQuestion = "" -- used for storing the last question the bot asked the player.
	players[steam].bountyReason = ""
	players[steam].cash = 0
	players[steam].chatColour = "FFFFFF"
	players[steam].commandCooldown = 0
	players[steam].country = ""
	players[steam].denyRights = false
	players[steam].exiled = false
	players[steam].GBLCount = 0
	players[steam].gimmeCooldown = 0
	players[steam].gimmeCount = 0
	players[steam].hackerScore = 0
	players[steam].ignorePlayer = false -- exclude player from checks like inventory, flying, teleporting etc.
	players[steam].maxWaypoints = server.maxWaypoints
	players[steam].mute = false
	players[steam].overstack = false
	players[steam].overstackItems = ""
	players[steam].overstackScore = 0
	players[steam].overstackTimeout = false
	players[steam].packCooldown = 0
	players[steam].pendingBans = 0
	players[steam].permanentBan = false
	players[steam].prisoner = false
	players[steam].prisonReason = ""
	players[steam].prisonReleaseTime = 0
	players[steam].prisonxPosOld = 0
	players[steam].prisonyPosOld = 0
	players[steam].prisonzPosOld = 0
	players[steam].pvpTeleportCooldown = 0
	players[steam].raiding = false
	players[steam].relogCount = 0
	players[steam].removeClaims = false
	players[steam].reserveSlot = false
	players[steam].returnCooldown = 0
	players[steam].silentBob = false
	players[steam].teleCooldown = 0
	players[steam].timeout = false
	players[steam].tokens = 0
	players[steam].VACBanned = false
	players[steam].walkies = false
	players[steam].watchPlayer = false
	players[steam].waypointCooldown = server.waypointCooldown
	players[steam].xPos = 0
	players[steam].xPosOld = 0
	players[steam].xPosOld2 = 0
	players[steam].yPos = 0
	players[steam].yPosOld = 0
	players[steam].yPosOld2 = 0
	players[steam].zPos = 0
	players[steam].zPosOld = 0
	players[steam].zPosOld2 = 0

	conn:execute("DELETE FROM waypoints WHERE steam = '" .. steam .. "'")
	conn:execute("DELETE FROM hotspots WHERE owner = '" .. steam .. "'")

	updatePlayer(steam)
	saveSQLitePlayer(steam)

	return true
end


function initNewPlayer(platform, userID, steam, player, entityid, steamOwner, line)
	local cursor, errorString, rows, k, v

	cursor,errorString = conn:execute("SELECT steam FROM players WHERE steam = '" .. steam .. "'")
	rows = cursor:numrows()

	if tonumber(rows) > 0 then
		irc_chat(server.ircAlerts, "Init new player record aborted because record already exists!")
		-- abort! abort! The player record exists!
		return
	end

	cursor,errorString = conn:execute("SELECT distinct steam FROM events WHERE steam = '" .. steam .. "'")
	rows = cursor:numrows()

	if tonumber(rows) > 2 then
		irc_chat(server.ircAlerts, "Init new player record aborted because record already exists!")
		-- abort! abort! The player record exists!
		return
	end

	if players[steam] then -- this extra test should be redundant but the guys at the Department of Redundancy Department insisted we add it.
		irc_chat(server.ircAlerts, "Init new player record aborted because record already exists!")
		-- abort! abort! The player record exists!
		return
	end

	irc_chat(server.ircAlerts, "Initialising new player record for " .. steam .. " from " .. line)

	if botman.dbConnected then conn:execute("INSERT INTO players (userID, steam, id, name, steamOwner) VALUES ('" .. escape(userID) .. "','" .. steam .. "'," .. entityid .. ",'" .. escape(player) .. "','" .. steamOwner .. "')") end

	players[steam] = {}
	players[steam].alertMapLimit = false
	players[steam].alertPrison = true
	players[steam].alertPVP = true

	if server.gameType == "pvp" then
		players[steam].alertPVP = false
	end

	players[steam].alertReset = true
	players[steam].aliases = player .. ","
	players[steam].atHome = false
	players[steam].autoFriend = ""
	players[steam].baseCooldown = 0
	players[steam].bedX = 0
	players[steam].bedY = 0
	players[steam].bedZ = 0
	players[steam].block = false
	players[steam].botTimeout = false
	players[steam].botQuestion = "" -- used for storing the last question the bot asked the player.
	players[steam].bountyReason = ""
	players[steam].cash = 0
	players[steam].chatColour = "FFFFFF"
	players[steam].commandCooldown = 0
	players[steam].country = ""
	players[steam].denyRights = false
	players[steam].deaths = 0
	players[steam].donor = false
	players[steam].donorExpiry = os.time()
	players[steam].DNSLookupCount = 0
	players[steam].exiled = false
	players[steam].firstSeen = os.time()
	players[steam].GBLCount = 0
	players[steam].gimmeCooldown = 0
	players[steam].gimmeCount = 0
	players[steam].hackerScore = 0
	players[steam].id = entityid
	players[steam].ignorePlayer = false -- exclude player from checks like inventory, flying, teleporting etc.
	players[steam].ip = ""
	players[steam].ircPass = ""
	players[steam].ISP = ""
	players[steam].lastBaseRaid = 0
	players[steam].lastChatLine = ""
	players[steam].lastCommand = ""
	players[steam].lastCommandTimestamp = os.time()
	players[steam].lastDNSLookup = "1000-01-01"
	players[steam].lastLogout = os.time()
	players[steam].location = ""
	players[steam].maxWaypoints = server.maxWaypoints
	players[steam].mute = false
	players[steam].name = player
	players[steam].newPlayer = true
	players[steam].notInLKP = false
	players[steam].overstack = false
	players[steam].overstackItems = ""
	players[steam].overstackScore = 0
	players[steam].overstackTimeout = false
	players[steam].p2pCooldown = 0
	players[steam].packCooldown = 0
	players[steam].pendingBans = 0
	players[steam].permanentBan = false
	players[steam].ping = 0
	players[steam].platform = platform
	players[steam].playtime = 0
	players[steam].prisoner = false
	players[steam].prisonReason = ""
	players[steam].prisonReleaseTime = 0
	players[steam].prisonxPosOld = 0
	players[steam].prisonyPosOld = 0
	players[steam].prisonzPosOld = 0
	players[steam].pvpTeleportCooldown = 0
	players[steam].pvpVictim = "0"
	players[steam].raiding = false
	players[steam].relogCount = 0
	players[steam].removeClaims = false
	players[steam].reserveSlot = false
	players[steam].sessionCount = 1
	players[steam].returnCooldown = 0
	players[steam].silentBob = false
	players[steam].steam = steam
	players[steam].steamOwner = steamOwner
	players[steam].teleCooldown = 0
	players[steam].timeOnServer = 0
	players[steam].timeout = false
	players[steam].tokens = 0
	players[steam].userID = userID
	players[steam].VACBanned = false
	players[steam].walkies = false
	players[steam].watchPlayer = true
	players[steam].watchPlayerTimer = os.time() + server.defaultWatchTimer
	players[steam].waypointsLinked = false
	players[steam].waypointCooldown = server.waypointCooldown
	players[steam].xPos = 0
	players[steam].xPosOld = 0
	players[steam].xPosOld2 = 0
	players[steam].yPos = 0
	players[steam].yPosOld = 0
	players[steam].yPosOld2 = 0
	players[steam].zPos = 0
	players[steam].zPosOld = 0
	players[steam].zPosOld2 = 0

	-- if a player group called New Players exists, assign the player to it
	for k, v in pairs(playerGroups) do
		if string.lower(v.name) == "new players" then
			players[steam].groupID = tonumber(v.groupID)
		end
	end

	sendPlayerToLobby(steam)
	return true
end


function sendPlayerToLobby(steam)
	local loc

	loc = LookupLocation("lobby")

	if loc then
		-- we just set a flag.  The actual teleport is handled later when we inspect location.
		players[steam].location = loc
		return
	end
end


function initNewIGPlayer(platform, userID, steam, player, entityid, steamOwner)
	igplayers[steam] = {}
	igplayers[steam].afk = os.time() + tonumber(server.idleKickTimer)
	igplayers[steam].alertLocation = ""
	igplayers[steam].alertRemovedClaims = false
	igplayers[steam].belt = ""
	igplayers[steam].checkNewPlayer = true
	igplayers[steam].connected = true
	igplayers[steam].equipment = ""
	igplayers[steam].fetch = false
	igplayers[steam].firstSeen = os.time()
	igplayers[steam].flyCount = 0
	igplayers[steam].flying = false
	igplayers[steam].flyingHeight = 0
	igplayers[steam].flyingX = 0
	igplayers[steam].flyingY = 0
	igplayers[steam].flyingZ = 0
	igplayers[steam].greet = true
	igplayers[steam].greetdelay = 1000
	igplayers[steam].hackerTPScore = 0
	igplayers[steam].highPingCount = 0
	igplayers[steam].id = entityid
	igplayers[steam].illegalInventory = false
	igplayers[steam].inLocation = ""
	igplayers[steam].inventory = ""
	igplayers[steam].inventoryLast = ""
	igplayers[steam].killTimer = 0
	igplayers[steam].lastHotspot = 0
	igplayers[steam].lastLogin = ""
	igplayers[steam].lastLP = os.time()
	igplayers[steam].lastTPTimestamp = os.time()
	igplayers[steam].name = player
	igplayers[steam].noclipCount = 0
	igplayers[steam].noclipX = 0
	igplayers[steam].noclipY = 0
	igplayers[steam].noclipZ = 0
	igplayers[steam].pack = ""
	igplayers[steam].ping = 0
	igplayers[steam].platform = platform
	igplayers[steam].playGimme = false
	igplayers[steam].readCounter = 0
	igplayers[steam].region = ""
	igplayers[steam].sessionPlaytime = 0
	igplayers[steam].sessionStart = os.time()
	igplayers[steam].spawnedInWorld = false
	igplayers[steam].spawnedReason = "fake reason"
	igplayers[steam].spawnChecked = true
	igplayers[steam].spawnedCoordsOld = "0 0 0"
	igplayers[steam].spawnedCoords = "0 0 0"
	igplayers[steam].spawnPending = false
	igplayers[steam].steam = steam
	igplayers[steam].steamOwner = steamOwner
	igplayers[steam].teleCooldown = 200
	igplayers[steam].timeOnServer = 0
	igplayers[steam].tp = 1
	igplayers[steam].userID = userID
	igplayers[steam].xPos = 0
	igplayers[steam].xPosLast = 0
	igplayers[steam].xPosLastAlert = 0
	igplayers[steam].xPosLastOK = 0
	igplayers[steam].yPos = 0
	igplayers[steam].yPosLast = 0
	igplayers[steam].yPosLastAlert = 0
	igplayers[steam].yPosLastOK = 0
	igplayers[steam].zPos = 0
	igplayers[steam].zPosLast = 0
	igplayers[steam].zPosLastAlert = 0
	igplayers[steam].zPosLastOK = 0

	return true
end


function fixMissingStuff()
	lfs.mkdir(homedir .. "/telnet_logs")
	lfs.mkdir(homedir .. "/custom")
	lfs.mkdir(homedir .. "/dns")
	lfs.mkdir(homedir .. "/proxies")
	lfs.mkdir(homedir .. "/temp")
	lfs.mkdir(homedir .. "/scripts")
	lfs.mkdir(homedir .. "/data_backup")
	lfs.mkdir(homedir .. "/chatlogs")

	if botman.chatlogPath then
		lfs.mkdir(botman.chatlogPath .. "/temp")
		lfs.mkdir(botman.chatlogPath .. "/guides")
		lfs.mkdir(botman.chatlogPath .. "/help")
		lfs.mkdir(botman.chatlogPath .. "/lists")
	end

	if not isFile(homedir .. "/custom/gmsg_custom.lua") then
		os.execute("wget https://www.botman.nz/gmsg_custom.lua -P \"" .. homedir .. "\"/custom/")
	end

	if not isFile(homedir .. "/custom/customIRC.lua") then
		os.execute("wget https://www.botman.nz/customIRC.lua -P \"" .. homedir .. "\"/custom/")
	end

	if not isFile(homedir .. "/custom/custom_functions.lua") then
		os.execute("wget https://www.botman.nz/custom_functions.lua -P \"" .. homedir .. "\"/custom/")
	end

	if type(gimmeZombies) ~= "table" then
		gimmeZombies = {}
		sendCommand("se")
	end

	if benchmarkBot == nil then
		benchmarkBot = false
	end

	if botman.gameStarted == nil then
		botman.gameStarted = true
	end
end


function saveDisconnectedPlayer(steam)
	if not players[steam] then
		return
	end

	if not players[steam].steamOwner then
		players[steam].steamOwner = steam
	end

	-- this function has been moved from the player disconnected trigger so we can call it in other places if necessary to ensure all online player data is saved to the database.
	fixMissingPlayer(players[steam].platform, steam, players[steam].steamOwner, players[steam].userID)

	-- update players table with x y z
	players[steam].lastAtHome = nil
	players[steam].protectPaused = nil
	players[steam].protect2Paused = nil

	if igplayers[steam] then
		-- only process the igplayer record if the player is actually online otherwise assume these are already done
		players[steam].xPos = igplayers[steam].xPos
		players[steam].yPos = igplayers[steam].yPos
		players[steam].zPos = igplayers[steam].zPos
		players[steam].playerKills = igplayers[steam].playerKills
		players[steam].deaths = igplayers[steam].deaths
		players[steam].zombies = igplayers[steam].zombies
		players[steam].score = igplayers[steam].score
		players[steam].ping = igplayers[steam].ping
		players[steam].timeOnServer = players[steam].timeOnServer + igplayers[steam].sessionPlaytime

		if (igplayers[steam].sessionPlaytime) > 300 then
			players[steam].relogCount = 0
		end

		if (igplayers[steam].sessionPlaytime) < 60 then
			if not players[steam].timeout and not players[steam].botTimeout and not players[steam].prisoner then
				players[steam].relogCount = tonumber(players[steam].relogCount) + 1
			end
		else
			players[steam].relogCount = tonumber(players[steam].relogCount) - 1
			if tonumber(players[steam].relogCount) < 0 then players[steam].relogCount = 0 end
		end

		players[steam].lastLogout = os.time()
		players[steam].seen = botman.serverTime
	end

	if isAdmin(steam) then
		connMEM:execute("DELETE FROM tracker WHERE admin = '" .. steam .. "'")
	end

	if botman.dbConnected then
		connSQL:execute("DELETE FROM messageQueue WHERE recipient = '" .. steam .. "'")
		connMEM:execute("DELETE FROM gimmeQueue WHERE steam = '" .. steam .. "'")
		connSQL:execute("DELETE FROM commandQueue WHERE steam = '" .. steam .. "'")
		connSQL:execute("DELETE FROM playerQueue WHERE steam = '" .. steam .. "'")
	end

	-- delete player from igplayers table
	igplayers[steam] = nil
	lastHotspots[steam] = nil
	invTemp[steam] = nil
	playersOnlineList[steam] = nil

	-- update the player record in the database
	updatePlayer(steam)
	saveSQLitePlayer(steam)

	-- if	botman.botsConnected then
		-- -- insert or update player in bots db
		-- connBots:execute("INSERT INTO players (server, steam, ip, name, online, botid) VALUES ('" .. escape(server.serverName) .. "','" .. steam .. "','" .. players[steam].ip .. "','" .. escape(players[steam].name) .. "',0," .. server.botID .. ") ON DUPLICATE KEY UPDATE ip = '" .. players[steam].ip .. "', name = '" .. escape(players[steam].name) .. "', online = 0")
	-- end
end


function shutdownBot(steam)
	local k, v

	for k,v in pairs(igplayers) do
		savePlayerData(k)
	end

	saveLuaTables(os.date("%Y%m%d_%H%M%S"))

	if igplayers[steam] then
		message("pm " .. igplayers[steam].userID .. " [" .. server.chatColour .. "]" .. server.botName .. " is ready to shutdown.  Player data is saved.[-]")
	end

	sendIrc(server.ircMain, server.botName .. " is ready to shutdown.  Player data is saved.")
end


function verifyCommandAccess(topic, command)
	local key = topic .. "_" .. command
	local status = false

	if debug then
		display("topic " .. topic)
		display("command " .. command)
		display(helpCommands[key])
	end

	if not helpCommands[key] then
		tempTimer( 1, [[runRegisterHelp()]] )

		if (chatvars.playername ~= "Server") then
			if not server.hideUnknownCommand then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Command missing - Rebuilding command help. Repeat your command by just typing " .. server.commandPrefix .. "[-]")
			end
		else
			irc_chat(chatvars.ircAlias, "Command missing - Rebuilding command help. Repeat your command by just typing " .. server.commandPrefix)
		end

		return false
	else
		if (chatvars.playername == "Server") then
			if helpCommands[key].ingameOnly then
				irc_chat(chatvars.ircAlias, "This command is in-game only.")
				return false
			end
		end

		if tonumber(helpCommands[key].accessLevel) >= tonumber(chatvars.accessLevel) then
			status = true
		else
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You cannot use this command.[-]")
			else
				irc_chat(chatvars.ircAlias, "You cannot use this command.")
			end

			return false
		end
	end

	if status == false then
		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You cannot use this command.[-]")
		else
			irc_chat(chatvars.ircAlias, "You cannot use this command.")
		end
	end

	return status
end


function setGroupMembership(steam, groupName, addToGroup)
	local k,v, playersGroupID

	-- add a player to a group or remove them from it unless they are already a member of another group.
	-- this will only change their groupID if they are already in this group or not in any group.

	groupName = string.lower(groupName)
	playersGroupID = players[steam].groupID

	for k,v in pairs(playerGroups) do
		if string.lower(v.name) == groupName then
			if playersGroupID ~= v.groupID and playersGroupID ~= 0 then
				-- abort because player is already a member of another group
				return false
			end

			if addToGroup then
				players[steam].groupID = v.groupID
				if botman.dbConnected then conn:execute("UPDATE players SET groupID = " .. v.groupID .. " WHERE steam = '" .. steam .. "'") end
			else
				-- nothing to do if their groupID is already 0
				if playersGroupID ~= 0 then
					players[steam].groupID = 0
					if botman.dbConnected then conn:execute("UPDATE players SET groupID = 0 WHERE steam = '" .. steam .. "'") end
				end
			end

			return true
		end
	end
end


function checkForBadWords() --todo finish this
	-- this function inspects the global table chatvars
	local k, v, word, badWordsFound, badWord, fine

	if chatvars.isAdmin then
		-- do not react to an admin using bad words.  They are just having a bad day, leave them alone man! :}
		-- qualified immunitay!
		--return false
	end

	badWordsFound = false
	fine = 0

	for k,v in pairs(chatvars.wordsOld) do
		word = string.lower(v)

		if badWords[word] then
			badWord = badWords[word]
			badWordsFound = true
			badWords[word].counter = badWords[word].counter + 1

			if botman.dbConnected then conn:execute("UPDATE badWords SET counter  = " .. badWords[word].counter .. " WHERE badWord = '" .. escape(word) .. "'") end

			if tonumber(badWord.cost) > 0 then
				fine = fine + badWord.cost
			end

			if tonumber(badWord.cooldown) > 0 then

			else

			end
		end
	end

	if badWordsFound then
		if fine > 0 then
			-- allow cash to go negative xD
			 -- It's a fine
			players[chatvars.playerid].cash = players[chatvars.playerid].cash - fine -- It's a not :(

			if botman.dbConnected then conn:execute("UPDATE players SET cash  = " .. players[chatvars.playerid].cash .. " WHERE steam = '" .. chatvars.playerid .. "'") end

			if fine == 1 then
				message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]" .. chatvars.playername .. " you are fined " .. fine .. " {money} for a violation of the verbal morality statute.[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.warnColour .. "]" .. chatvars.playername .. " you are fined " .. fine .. " {monies} for a violation of the verbal morality statute.[-]")
			end
		end
	end

	-- help[1] = help[1] .. " {#}add/remove bad word {word or phrase} cost {amount of money} response {nothing or mute or ban or timeout} cooldown {number of seconds before un-muting etc}"
end


function checkOverride(settingName, defaultValue, steam) -- TODO code dis
	-- this will allow custom setting overrides that are not part of the players table, server table or playerGroups table.  These will come from the table overrides.

	-- initially just return the value without doing any work till this function is complete
	return defaultValue
end


function addDonorsToPlayerGroup()
	-- this is only called when the Donors player group has only just been created.
	local cursor, errorString, row, idx

	cursor,errorString = conn:execute("SELECT * FROM playerGroups WHERE name = 'Donors'")
	row = cursor:fetch({}, "a")

	if row then
		idx = "G" .. row.groupID

		-- also set up the default group permissions for the Donors group.
		playerGroups[idx] = {}
		playerGroups[idx].groupID = tonumber(row.groupID)
		playerGroups[idx].name = row.name
		playerGroups[idx].maxBases = tonumber(row.maxBases)
		playerGroups[idx].maxProtectedBases = tonumber(row.maxProtectedBases)
		playerGroups[idx].baseSize = tonumber(row.baseSize)
		playerGroups[idx].baseCooldown = tonumber(row.baseCooldown)
		playerGroups[idx].baseCost = tonumber(row.baseCost)
		playerGroups[idx].maxWaypoints = tonumber(row.maxWaypoints)
		playerGroups[idx].waypointCost = tonumber(row.waypointCost)
		playerGroups[idx].waypointCooldown = tonumber(row.waypointCooldown)
		playerGroups[idx].waypointCreateCost = tonumber(row.waypointCreateCost)
		playerGroups[idx].chatColour = row.chatColour
		playerGroups[idx].teleportCost = tonumber(row.teleportCost)
		playerGroups[idx].packCost = tonumber(row.packCost)
		playerGroups[idx].teleportPublicCost = tonumber(row.teleportPublicCost)
		playerGroups[idx].teleportPublicCooldown = tonumber(row.teleportPublicCooldown)
		playerGroups[idx].returnCooldown = tonumber(row.returnCooldown)
		playerGroups[idx].p2pCooldown = tonumber(row.p2pCooldown)
		playerGroups[idx].namePrefix = row.namePrefix
		playerGroups[idx].playerTeleportDelay = tonumber(row.playerTeleportDelay)
		playerGroups[idx].maxGimmies = tonumber(row.maxGimmies)
		playerGroups[idx].packCooldown = tonumber(row.packCooldown)
		playerGroups[idx].zombieKillReward = tonumber(row.zombieKillReward)
		playerGroups[idx].allowLottery = dbTrue(row.allowLottery)
		playerGroups[idx].lotteryMultiplier = tonumber(row.lotteryMultiplier)
		playerGroups[idx].lotteryTicketPrice = tonumber(row.lotteryTicketPrice)
		playerGroups[idx].deathCost = tonumber(row.deathCost)
		playerGroups[idx].mapSize = tonumber(row.mapSize)
		playerGroups[idx].perMinutePayRate = tonumber(row.perMinutePayRate)
		playerGroups[idx].pvpAllowProtect = dbTrue(row.pvpAllowProtect)
		playerGroups[idx].gimmeZombies = dbTrue(row.gimmeZombies)
		playerGroups[idx].allowTeleporting = dbTrue(row.allowTeleporting)
		playerGroups[idx].allowShop = dbTrue(row.allowShop)
		playerGroups[idx].allowGimme = dbTrue(row.allowGimme)
		playerGroups[idx].hardcore = dbTrue(row.hardcore)
		playerGroups[idx].allowHomeTeleport = dbTrue(row.allowHomeTeleport)
		playerGroups[idx].allowPlayerToPlayerTeleporting = dbTrue(row.allowPlayerToPlayerTeleporting)
		playerGroups[idx].allowVisitInPVP = dbTrue(row.allowVisitInPVP)
		playerGroups[idx].reserveSlot = dbTrue(row.reserveSlot)
		playerGroups[idx].allowWaypoints = dbTrue(row.allowWaypoints)
		playerGroups[idx].gimmeRaincheck = tonumber(row.gimmeRaincheck)
	end

	-- add all the donors to the donors player group
	cursor,errorString = conn:execute("SELECT * FROM donors WHERE expired = 0")
	row = cursor:fetch({}, "a")

	while row do
		conn:execute("UPDATE players SET groupID = " .. row.groupID .. " WHERE steam = '" .. row.steam .. "'")
		row = cursor:fetch(row, "a")
	end

	-- reload the players table
	tempTimer( 1, [[loadPlayers()]] )
end


function removeDonor(steam)
	local cursor, errorString, row, count, tmp

	tmp = {}
	tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(steam)

	-- remove a donor
	if players[tmp.steam] then
		players[tmp.steam].maxWaypoints = server.maxWaypoints
		if botman.dbConnected then conn:execute("UPDATE players SET maxWaypoints = " .. server.maxWaypoints .. ", maxBases = " .. server.maxBases .. " WHERE steam = '" .. tmp.steam .. "'") end
	else
		playersArchived[steam].maxWaypoints = server.maxWaypoints
		if botman.dbConnected then conn:execute("UPDATE playersArchived SET maxWaypoints = " .. server.maxWaypoints .. ", maxBases = " .. server.maxBases .. " WHERE steam = '" .. tmp.steam .. "'") end
	end

	-- remove them from the donors player group
	conn:execute("UPDATE players SET groupID = 0 WHERE steam = '" .. tmp.steam .. "'")
	players[tmp.steam].groupID = 0

	conn:execute("DELETE FROM donors WHERE steam = '" .. tmp.steam .. "'")
	conn:execute("DELETE FROM donors WHERE steam = '" .. tmp.userID .. "'")
	donors[tmp.steam] = nil

	-- remove all bases over maxBases
	cursor,errorString = conn:execute("SELECT * FROM bases WHERE steam = '" .. tmp.steam .. "' ORDER BY baseNumber" )
	row = cursor:fetch({}, "a")

	count = 1
	while row do
		if count > server.maxBases then
			conn:execute("DELETE FROM bases WHERE steam = '" .. tmp.steam .. "' AND baseNumber = " .. row.baseNumber)
		end

		count = count + 1
		row = cursor:fetch(row, "a")
	end

	-- remove all waypoints over maxWaypoints
	cursor,errorString = conn:execute("SELECT * FROM waypoints WHERE steam = '" .. tmp.steam .. "' ORDER BY id" )
	row = cursor:fetch({}, "a")

	count = 1
	while row do
		if count > server.maxWaypoints then
			conn:execute("DELETE FROM waypoints WHERE steam = '" .. tmp.steam .. "' AND id = " .. row.id)
		end

		count = count + 1
		row = cursor:fetch(row, "a")
	end

	-- reload the player's waypoints
	loadWaypoints(tmp.steam)

	if igplayers[tmp.steam] then
		setChatColour(tmp.steam)
		setOverrideChatName(tmp.steam, players[tmp.steam].name)
		message("pm " .. igplayers[tmp.steam].userID .. " [" .. server.chatColour .. "]Your donor status has expired. You are now limited to " .. server.maxBases .. " bases and " .. server.maxWaypoints .. " waypoints. Any extras you had have been forgotten. You physical bases still exist.[-]")
	else
		connSQL:execute("INSERT INTO mail (sender, recipient, message) VALUES ('0','" .. tmp.steam .. "', '" .. connMEM:escape("Your donor status has expired. You are now limited to " .. server.maxBases .. " bases and " .. server.maxWaypoints .. " waypoints. Any extras you had have been forgotten. You physical bases still exist.") .. "')")
	end

	if server.serverGroup ~= "" then
		connBots:execute("UPDATE donors SET donor = 0, donorExpiry = " .. os.time() - 1 .. " WHERE steam = '" .. tmp.steam .. "' AND serverGroup = '" .. escape(server.serverGroup) .. "'")
	end
end


function updateCommandHelp()
	gmsg(server.commandPrefix .. "register help") -- , "0"
end


function announceTelnetLogin()
	irc_chat(server.ircMain, "Successfully logged in to telnet.")
end


function invalidAdminTokenTrigger(line)
	if string.find(line, server.botsIP) then
		if not botman.lastAPIConnect then
			connectToAPI()
			botman.lastAPIConnect = os.time()
		else
			if os.time() - botman.lastAPIConnect > 10 then
				connectToAPI()
				botman.lastAPIConnect = os.time()
			end
		end
	end
end
