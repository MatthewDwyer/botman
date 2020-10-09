--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- magic characters in Lua  ( ) . % + - * ? [ ^ $
-- these must be escaped with a %  eg string.split(line, "%.")

-- stuff for the future
-- http://terralang.org
-- https://labix.org/lunatic-python
-- https://github.com/bastibe/lunatic-python

local debug

if botman.debugAll then
	debug = true -- this should be true
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
				server.botName = Configs.botname.name
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
	disableTimer("APITimer")
	disableTimer("Every10Seconds")
	disableTimer("Every15Seconds")
	disableTimer("Every45Seconds")
	disableTimer("Every5Seconds")
	disableTimer("EveryHalfMinute")
	disableTimer("EverySecond")
	disableTimer("five_minute_timer")
	disableTimer("GimmeQueuedCommands")
	disableTimer("GimmeReset")
	disableTimer("listPlayers")
	disableTimer("messageQueue")
	disableTimer("OneHourTimer")
	disableTimer("OneMinuteTimer")
	disableTimer("PlayerQueuedCommands")
	disableTimer("Reconnect")
	disableTimer("ten_minute_timer")
	disableTimer("ThirtyMinuteTimer")
	disableTimer("TimedCommands")
	disableTimer("TrackPlayer")
	disableTimer("TwoMinuteTimer")
end


function enableTimers()
	enableTimer("APITimer")
	enableTimer("Every10Seconds")
	enableTimer("Every15Seconds")
	enableTimer("Every45Seconds")
	enableTimer("Every5Seconds")
	enableTimer("EveryHalfMinute")
	enableTimer("EverySecond")
	enableTimer("five_minute_timer")
	enableTimer("GimmeQueuedCommands")
	enableTimer("GimmeReset")
	enableTimer("listPlayers")
	enableTimer("messageQueue")
	enableTimer("OneHourTimer")
	enableTimer("OneMinuteTimer")
	enableTimer("PlayerQueuedCommands")
	enableTimer("Reconnect")
	enableTimer("ten_minute_timer")
	enableTimer("ThirtyMinuteTimer")
	enableTimer("TimedCommands")
	enableTimer("TrackPlayer")
	enableTimer("TwoMinuteTimer")
end


function flagAdminsForRemoval()
	local k,v

	for k,v in pairs(owners) do
		v.remove = true
	end

	for k,v in pairs(admins) do
		v.remove = true
	end

	for k,v in pairs(mods) do
		v.remove = true
	end

	for k,v in pairs(staffList) do
		v.remove = true
	end
end


function removeOldStaff()
	local k,v

	if getAdminList then
		-- abort if getAdminList is true as that means there's been a fault in the telnet data
		return
	end

	for k,v in pairs(owners) do
		if v.remove then
			owners[k] = nil
		else
			v.remove = nil
		end
	end

	for k,v in pairs(admins) do
		if v.remove then
			admins[k] = nil
		else
			v.remove = nil
		end
	end

	for k,v in pairs(mods) do
		if v.remove then
			mods[k] = nil
		else
			v.remove = nil
		end
	end

	for k,v in pairs(staffList) do
		if v.remove then
			staffList[k] = nil
		else
			v.remove = nil
		end
	end

	-- nuke the staff table and rebuild it
	if botman.dbConnected then conn:execute("TRUNCATE staff") end

	for k,v in pairs(owners) do
		if botman.dbConnected then conn:execute("INSERT INTO staff (steam, adminLevel) VALUES (" .. k .. ", 0)") end
	end

	for k,v in pairs(admins) do
		if botman.dbConnected then conn:execute("INSERT INTO staff (steam, adminLevel) VALUES (" .. k .. ", 1)") end
	end

	for k,v in pairs(mods) do
		if botman.dbConnected then conn:execute("INSERT INTO staff (steam, adminLevel) VALUES (" .. k .. ", 2)") end
	end
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

	commandPosition = "0 0 0"

	if tonumber(chatvars.ircid) > 0 then
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

	if tonumber(chatvars.ircid) > 0 then
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


function setBlockTelnetSpam(state)
	botman.blockTelnetSpam = state
end


function blockTelnetSpam()
	if botman.blockTelnetSpam then
		deleteLine()
	end
end


function helpCommandRestrictions(tmp)
	local temp = ""

	temp = "Restricted to "

	if tmp.accessLevel == 0 then
		temp = temp .. "server owners"
	end

	if tmp.accessLevel == 1 then
		temp = temp .. "owners and admins"
	end

	if tmp.accessLevel == 2 then
		temp = temp .. "owners, admins and mods"
	end

	if tmp.accessLevel == 10 then
		temp = temp .. "donors and admins"
	end

	if tmp.accessLevel == 90 then
		temp = temp .. "players and admins"
	end

	if tmp.accessLevel == 99 then
		temp = "Unrestricted command"
	end

	if tmp.ingameOnly == 0 then
		temp = temp .. " in-game and IRC"
	else
		temp = temp .. " in-game only"
	end

	return temp
end


function connectToAPI()
	send("webtokens list")
	botman.webTokensListSent = os.time()
end


function panelWho() --who? who?
	local whoIsOnline = {}

	for k, v in pairs(igplayers) do
		x = math.floor(v.xPos / 512)
		z = math.floor(v.zPos / 512)

		flags = ""
		line = ""
		sort = 999

		if tonumber(players[k].accessLevel) < 3 then
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

	conn:execute("DELETE FROM webInterfaceJSON WHERE ident = 'playersOnline'")
	conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('playersOnline','panel','" .. escape(yajl.to_string(whoIsOnline)) .. "')")
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
		connMEM:execute("INSERT INTO list(steam) VALUES (" .. k ..")")
	end

	-- now that we have all of the steam id's of the admins in the list table we can use it to nuke other tables except for those id's
	conn:execute("DELETE FROM alerts WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM bases WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM bookmarks WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM friends WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM hotspots WHERE owner NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM keystones WHERE steam NOT IN (SELECT steam FROM list)")
	conn:execute("DELETE FROM players WHERE steam NOT IN (SELECT steam FROM list)")
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


function rewardServerVote(playerID)
	local i, r, quantity, quality

	if serverVoteReward == "entity" then
		sendCommand("se " .. playerID .. " " .. serverVoteRewardItem)
		return true
	end

	if serverVoteReward == "crate" then
		sendCommand("se " .. playerID .. " sc_General")
		return true
	end

	if serverVoteReward == "item" then
		if string.find(serverVoteRewardItem, "sc_") then
			sendCommand("se " .. playerID .. " " .. serverVoteRewardItem)
		else
			if server.stompy then
				sendCommand("bc-give " .. playerID .. " " .. serverVoteRewardItem .. " /c=1 /silent")
			else
				sendCommand("give " .. playerID .. " " .. serverVoteRewardItem .. " 1")
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
	if event == "api offline" or server.readLogUsingTelnet then
		enableTrigger("AirDrop alert")
		enableTrigger("Auto Friend")
		enableTrigger("Chat")
		enableTrigger("Collect Ban")
		enableTrigger("End list players")
		enableTrigger("Game Time")
		enableTrigger("Inventory")
		enableTrigger("InventoryOwner")
		enableTrigger("InventorySlot")
		enableTrigger("lkp")
		enableTrigger("llp")
		enableTrigger("lp")
		enableTrigger("MatchAll")
		enableTrigger("mem")
		enableTrigger("Overstack")
		enableTrigger("playerinfo")
		enableTrigger("Player connected")
		enableTrigger("Player disconnected")
		enableTrigger("PVP Police")
		enableTrigger("Unban player")
		enableTrigger("Zombie Scouts")
		enableTrigger("Tele")
	end

	if event == "api online" and not server.readLogUsingTelnet then
		disableTrigger("AirDrop alert")
		disableTrigger("Auto Friend")
		disableTrigger("Chat")
		disableTrigger("Collect Ban")
		disableTrigger("End list players")
		disableTrigger("Game Time")
		disableTrigger("Inventory")
		disableTrigger("InventoryOwner")
		disableTrigger("InventorySlot")
		disableTrigger("lkp")
		disableTrigger("llp")
		disableTrigger("lp")
		disableTrigger("MatchAll")
		disableTrigger("mem")
		disableTrigger("Overstack")
		disableTrigger("playerinfo")
		disableTrigger("Player connected")
		disableTrigger("Player disconnected")
		disableTrigger("PVP Police")
		disableTrigger("Unban player")
		disableTrigger("Zombie Scouts")
		disableTrigger("Tele")
	end

	if event == "api online" and server.readLogUsingTelnet then
		disableTrigger("lkp")
		disableTrigger("llp")
		disableTrigger("lp")
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
	conn:execute("UPDATE slots SET steam = 0, reserved = 0, joinedTime = 0, joinedSession = 0, expires = 0, staff = 0, free = 1, canBeKicked = 1, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE online = 0 AND disconnectedTimestamp < " .. os.time() - 300)

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
	conn:execute("UPDATE slots SET steam = 0, joinedTime = 0, joinedSession = 0, expires = 0, staff = 0, free = 1, canBeKicked = 1, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE online = 0 AND disconnectedTimestamp < " .. os.time() - 300)

	-- get the number of reserved slots in use right now
	getReservedSlotsUsed()

	-- get the number of free slots available
	getFreeSlots()
end


function kickASlot(steam)
	local cursor, errorString, row

	-- if (debug) then dbug("debug freeASlot line " .. debugger.getinfo(1).currentline) end

	-- the player who has occupied a reserved slot the longest and isn't a reserved slotter will be kicked
	cursor,errorString = conn:execute("SELECT slot, steam FROM slots WHERE canBeKicked = 1 AND reserved = 1 AND free = 0 ORDER BY joinedTime DESC")
	row = cursor:fetch({}, "a")

	if row then
		if igplayers[steam] then
			kick(steam, "Sorry, you have been kicked from a reserved slot to allow another player to join :(")
			irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name ..  " was kicked to let " .. players[steam].name .. " join.")
		end

		conn:execute("UPDATE slots SET steam = 0, online = 0, staff = 0, canBeKicked = 1, free = 1, joinedSession = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
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

			conn:execute("UPDATE slots SET steam = 0, online = 0, joinedTime = 0, joinedSession = 0, expires = 0, staff = 0, free = 1, canBeKicked = 1, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
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
	cursor,errorString = conn:execute("SELECT slot, expires FROM slots WHERE steam = " .. steam)
	row = cursor:fetch({}, "a")

	if row then
		if isDonor(steam) and (not staffList[steam]) and (row.expires - os.time() > 0) then -- back to the future!
			conn:execute("UPDATE slots SET online = 0, staff = 0, canBeKicked = 1, free = 1, joinedSession = 0, disconnectedTimestamp = " .. os.time() .. " WHERE slot = " .. row.slot)
		else
			conn:execute("UPDATE slots SET steam = 0, online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
		end

		server.freeSlots = server.freeSlots + 1

		-- get the number of reserved slots in use right now
		getReservedSlotsUsed()
	end

	if (debug) then dbug("debug freeASlot end") end
end


function assignASlot(steam)
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
		cursor,errorString = conn:execute("SELECT slot, expires FROM slots WHERE steam = " .. tmp.steam)
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
					conn:execute("UPDATE slots SET steam = " .. tmp.steam .. ", canBeKicked = " .. dbBool(tmp.canBeKicked) .. ", online = 1, joinedTime = " .. os.time() .. ", expires = " .. os.time() + (server.reservedSlotTimelimit * 60) .. ", joinedSession = " .. players[tmp.steam].sessionCount .. ", staff = " .. dbBool(tmp.isStaff) .. ", free = 0, disconnectedTimestamp = 0, name = '" .. escape(players[tmp.steam].name) .. "', gameID = " .. players[tmp.steam].id .. ", IP = '" .. players[tmp.steam].ip .. "', country = '" .. players[tmp.steam].country .. "', ping = " .. players[tmp.steam].ping .. ", level = " .. players[tmp.steam].level .. ", score = " .. players[tmp.steam].score .. ", zombieKills = " .. players[tmp.steam].zombies .. ", playerKills = " .. players[tmp.steam].playerKills .. ", deaths = " .. players[tmp.steam].deaths .. " WHERE slot = " .. row.slot)
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
					conn:execute("UPDATE slots SET steam = " .. tmp.steam .. ", canBeKicked = " .. dbBool(tmp.canBeKicked) .. ", online = 1, joinedTime = " .. os.time() .. ", expires = 0, joinedSession = " .. players[tmp.steam].sessionCount .. ", staff = " .. dbBool(tmp.isStaff) .. ", free = 0, disconnectedTimestamp = 0, name = '" .. escape(players[tmp.steam].name) .. "', gameID = " .. players[tmp.steam].id .. ", IP = '" .. players[tmp.steam].ip .. "', country = '" .. players[tmp.steam].country .. "', ping = " .. players[tmp.steam].ping .. ", level = " .. players[tmp.steam].level .. ", score = " .. players[tmp.steam].score .. ", zombieKills = " .. players[tmp.steam].zombies .. ", playerKills = " .. players[tmp.steam].playerKills .. ", deaths = " .. players[tmp.steam].deaths .. "  WHERE slot = " .. row.slot)
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
		cursor,errorString = conn:execute("SELECT * FROM slots WHERE steam = " .. steam)
	else
		cursor,errorString = conn:execute("SELECT * FROM slots WHERE steam > 0 ORDER BY slot")
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
				cursor2,errorString2 = conn:execute("SELECT slot FROM slots WHERE steam = 0 AND free = 1 AND reserved = 0 ORDER BY slot LIMIT 0,1")
				row2 = cursor2:fetch({}, "a")

				if row2 then
					-- copy the reserved slot into the free non-reserved slot
					if tonumber(row.staff) == 1 then

						conn:execute("UPDATE slots SET steam = " .. row.steam .. ", online = 1, staff = 1, canBeKicked = 0, free = 0, joinedTime = " .. row.joinedTime .. ", joinedSession = " .. row.joinedSession .. ", expires = 0, disconnectedTimestamp = 0, name = '" .. escape(players[row.steam].name) .. "', gameID = " .. players[row.steam].id .. ", IP = '" .. players[row.steam].ip .. "', country = '" .. players[row.steam].country .. "', ping = " .. players[row.steam].ping .. ", level = " .. players[row.steam].level .. ", score = " .. players[row.steam].score .. ", zombieKills = " .. players[row.steam].zombies .. ", playerKills = " .. players[row.steam].playerKills .. ", deaths = " .. players[row.steam].deaths .. " WHERE slot = " .. row2.slot)
					else

						conn:execute("UPDATE slots SET steam = " .. row.steam .. ", online = 1, staff = 0, canBeKicked = 1, free = 0, joinedTime = " .. row.joinedTime .. ", joinedSession = " .. row.joinedSession .. ", expires = 0, disconnectedTimestamp = 0, name = '" .. escape(players[row.steam].name) .. "', gameID = " .. players[row.steam].id .. ", IP = '" .. players[row.steam].ip .. "', country = '" .. players[row.steam].country .. "', ping = " .. players[row.steam].ping .. ", level = " .. players[row.steam].level .. ", score = " .. players[row.steam].score .. ", zombieKills = " .. players[row.steam].zombies .. ", playerKills = " .. players[row.steam].playerKills .. ", deaths = " .. players[row.steam].deaths .. " WHERE slot = " .. row2.slot)
					end

					-- free the reserved slot
					conn:execute("UPDATE slots SET steam = 0, online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
				end
			end
		else
			if tonumber(row.reserved) == 1 then
				if tonumber(server.reservedSlotTimelimit) > 0 then
					-- check that the slot is being held for a player
					if (row.expires - os.time()) < 0 then
						-- free the slot
						conn:execute("UPDATE slots SET steam = 0, online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
					end

					if tonumber(row.disconnectedTimestamp) > 0 then
						if (os.time() - row.disconnectedTimestamp) > 300 then -- reserved slot player disconnected more than 5 minutes ago.
							-- if you snooze you lose.. your reserved slot
							conn:execute("UPDATE slots SET steam = 0, online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
						end
					else
						conn:execute("UPDATE slots SET steam = 0, online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
					end
				else
					-- mark the slot as free
					conn:execute("UPDATE slots SET steam = 0, online = 0, staff = 0, canBeKicked = 1, free = 1, joinedTime = 0, joinedSession = 0, expires = 0, disconnectedTimestamp = 0, name = '', gameID = 0, IP = '0.0.0.0', country = '', ping = 0, level = 0, score = 0, zombieKills = 0, playerKills = 0, deaths = 0 WHERE slot = " .. row.slot)
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
	if tonumber(server.webPanelPort) > 0 then
		-- verify that the web API is working for us
		message("pm APItest")
	end
end

function removeEntityCommand(entityID)
	if server.botman then
		sendCommand("bm-remove " .. entityID)
		return
	end

	if server.stompy then
		sendCommand("bc-remove " .. entityID)
		return
	end
end


function hidePlayerChat(prefix)
	if prefix then
		-- hide commands
		if server.botman then
			if server.stompy then
				-- disable this feature in the BC mod
				sendCommand("bc-chatprefix \"\"")
			end

			-- then enable it in the botman mod
			sendCommand("bm-chatcommands prefix " .. prefix)
			sendCommand("bm-chatcommands hide true")
			return
		end

		if server.stompy then
			sendCommand("bc-chatprefix " .. prefix)
			return
		end
	else
		-- don't hide commands
		if server.stompy then
			sendCommand("bc-chatprefix \"\"")
		end

		if server.botman then
			sendCommand("bm-chatcommands hide false")
		end
	end
end


function mutePlayerChat(steam, toggle)
	if server.botman then
		if server.stompy then
			sendCommand("bc-mute " .. steam .. " false")
		end

		sendCommand("bm-muteplayer " .. steam .. " " .. toggle)
		return
	end

	if server.stompy then
		sendCommand("bc-mute " .. steam .. " " .. toggle)
		return
	end
end


function mutePlayer(steam)
	mutePlayerChat(steam, "true")
	players[steam].mute = true
	irc_chat(server.ircMain, players[steam].name .. "'s chat has been muted :D")
	message("pm " .. steam .. " [" .. server.warnColour .. "]Your chat has been muted.[-]")
	if botman.dbConnected then conn:execute("UPDATE players SET mute = 1 WHERE steam = " .. steam) end
end


function unmutePlayer(steam)
	mutePlayerChat(steam, "false")
	players[steam].mute = false
	irc_chat(server.ircMain, players[steam].name .. "'s chat is no longer muted D:")
	message("pm " .. steam .. " [" .. server.chatColour .. "]Your chat is no longer muted.[-]")
	if botman.dbConnected then conn:execute("UPDATE players SET mute = 0 WHERE steam = " .. steam) end
end


function unlockAll(steam)
	if server.botman then
-- TODO:  Add bot support once the console command accepts a steam id.
	end

	if server.stompy then
		sendCommand("bc-unlockall /id=" .. steam)
		return
	end
end


function setPlayerChatLimit(steam, length)
	if server.botman then
		if server.stompy then
			sendCommand("bc-chatmax 0")
		end

		sendCommand("bm-playerchatmaxlength " .. steam .. " " .. length)
		return
	end

	if server.stompy then
		sendCommand("bc-chatmax " .. length)
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
		if server.stompy then
			if colour == "FFFFFF" then
				sendCommand("bc-chatcolor " .. steam .. " clear")
			end
		end

		sendCommand("bm-chatplayercolor " .. steam .. " " .. colour .. " 1")

		return
	end

	if server.stompy then
		if colour == "FFFFFF" then
			sendCommand("bc-chatcolor " .. steam .. " clear")
		else
			sendCommand("bc-chatcolor " .. steam .. " " .. colour .. " false")
		end

		return
	end
end


function setOverrideChatName(steam, newName, clear)
	if server.botman then
		if server.stompy then
			sendCommand("bc-playername override " .. steam)
		end

		if clear then
			sendCommand("bm-overridechatname " .. steam .. " \"" .. players[steam].name .. "\"")
		else
			sendCommand("bm-overridechatname " .. steam .. " \"" .. newName .. "\"")
		end

		return
	end

	if server.stompy then
		if clear then
			sendCommand("bc-playername override " .. steam)
		else
			sendCommand("bc-playername override " .. steam .. " " .. newName)
		end

		return
	end
end


function getBackupFiles(path)
	local file, str, backups, count, lastUnderscore

	connMEM:execute("DELETE FROM list WHERE steam = -10")
	backups = {}
	count = 2

	for file in lfs.dir(path) do
	  if file ~= "." and file ~= ".." and file ~= "" then
		if string.find(file, "_") then
			lastUnderscore = file:match('^.*()_')
			str = string.sub(file, 1, lastUnderscore - 1)

			if not backups[str] then
				backups[str] = {}
				connMEM:execute("INSERT INTO list (id, thing, class, steam) VALUES (" .. count .. ",'" .. connMEM:escape(str) .. "','backup',-10)")
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

	tmp = {}
	tmp.data = string.split(line, ",")
	tmp.name = string.sub(tmp.data[1], string.find(tmp.data[1], ". ") + 2)
	tmp.id = string.sub(tmp.data[2], string.find(tmp.data[2], "id=") + 3)
	tmp.steam = string.sub(tmp.data[3], string.find(tmp.data[3], "steamid=") + 8)
	tmp.playtime = string.sub(tmp.data[6], string.find(tmp.data[6], "playtime=") + 9, string.len(tmp.data[6]) - 2)
	tmp.playtime = tonumber(tmp.playtime)
	tmp.seen = string.sub(tmp.data[7], string.find(tmp.data[7], "seen=") + 5)

	if tmp.steam == "" then
		return
	end

	if playersArchived[tmp.steam] then
		-- don't process if this player has been archived
		return
	end

	if (not players[tmp.steam] and (tmp.playtime ~= "0")) then
		players[tmp.steam] = {}

		if tmp.id ~= "-1" then
			players[tmp.steam].id = tmp.id
		end

		players[tmp.steam].name = tmp.name
		players[tmp.steam].steam = tmp.steam
		players[tmp.steam].playtime = tmp.playtime
		players[tmp.steam].seen = tmp.seen

		if botman.dbConnected then conn:execute("INSERT INTO players (steam, id, name, playtime, seen) VALUES (" .. tmp.steam .. "," .. tmp.id .. ",'" .. escape(tmp.name) .. "'," .. tmp.playtime .. ",'" .. tmp.seen .. "') ON DUPLICATE KEY UPDATE playtime = " .. tmp.playtime .. ", seen = '" .. tmp.seen .. "'") end
	else
		if tmp.id ~= "-1" then
			players[tmp.steam].id = tmp.id
		end

		players[tmp.steam].name = tmp.name
		players[tmp.steam].playtime = tmp.playtime
		players[tmp.steam].seen = tmp.seen

		if botman.dbConnected then conn:execute("INSERT INTO players (steam, id, name, playtime, seen) VALUES (" .. tmp.steam .. "," .. tmp.id .. ",'" .. escape(tmp.name) .. "'," .. tmp.playtime .. ",'" .. tmp.seen .. "') ON DUPLICATE KEY UPDATE playtime = " .. tmp.playtime .. ", seen = '" .. tmp.seen .. "', name = '" .. escape(tmp.name) .. "', id = " .. tmp.id) end
	end

	-- add missing fields and give them default values
	fixMissingPlayer(tmp.steam)
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
	if debug then dbug("sleeping " .. s) end

	local ntime = os.time() + s
	repeat until os.time() >= ntime
end


function processConnectQueue(steam)
	local cursor, errorString, row

	cursor,errorString = conn:execute("SELECT * FROM connectQueue WHERE steam = " .. steam .. "  ORDER BY id")

	if cursor then
		row = cursor:fetch({}, "a")

		while row do
			if string.sub(row.command, 1, 3) == "pm " or string.sub(row.command, 1, 3) == "say" then
				message(row.command)
			else
				sendCommand(row.command)
			end

			conn:execute("UPDATE connectQueue SET processed = 1 WHERE id = " .. row.id)
			row = cursor:fetch(row, "a")
		end

		conn:execute("DELETE FROM connectQueue WHERE processed = 1")
	end
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
					if botman.dbConnected then conn:execute("UPDATE players SET VACBanned=1 WHERE steam = " .. steam) end

					if accessLevel(steam) > 2 and not whitelist[steam] then
						alertAdmins("Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
						irc_chat(server.ircAlerts, "Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
						irc_chat(server.ircMain, "Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
					end
				else
					alertAdmins("Player " .. steam .. " has one or more VAC bans on record.")
					irc_chat(server.ircAlerts, "Player " .. steam .. " has one or more VAC bans on record.")
					irc_chat(server.ircMain, "Player " .. steam .. " has one or more VAC bans on record.")
				end

				if server.banVACBannedPlayers and not whitelist[steam] and accessLevel(steam) > 2 then
					banPlayer(steam, "10 years", "You have a VAC ban")
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

	if server.useAllocsWebAPI and tonumber(server.webPanelPort) > 0 and botman.APIOffline and server.allocs then
		server.allocsWebAPIPassword = generatePassword(20)
		send("webtokens add bot " .. server.allocsWebAPIPassword .. " 0")
		botman.lastBotCommand = "webtokens add bot"
		conn:execute("UPDATE server set allocsWebAPIUser = 'bot', allocsWebAPIPassword = '" .. escape(server.allocsWebAPIPassword) .. "', useAllocsWebAPI = 1")
		botman.APIOffline = false
		toggleTriggers("api online")
	end

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

	fileSize = lfs.attributes (homedir .. "/temp/voteCheck_" .. steam .. ".txt", "size")

	-- abort if the file is empty
	if fileSize == nil or tonumber(fileSize) == 0 then
		return
	end

	file = io.open(homedir .. "/temp/voteCheck_" .. steam .. ".txt", "r")

	for ln in file:lines() do
		if ln == "0" then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Reward?  For what?  You haven't voted today!  You can claim your reward after voting.[-]")
			file:close()

			return
		end

		if ln == "1" then
			-- claim the vote
			url = "https://7daystodie-servers.com/api/?action=post&object=votes&element=claim&key=" .. serverAPI .. "&steamid=" .. steam
			os.remove(homedir .. "/temp/voteClaim_" .. steam .. ".txt")
			downloadFile(homedir .. "/temp/voteClaim_" .. steam .. ".txt", url)

			-- reward the player.  Good Player!  Have a biscuit.
			message("pm " .. steam .. " [" .. server.chatColour .. "]Thanks for voting for us!  Your reward should spawn beside you.[-]")
			rewardServerVote(players[steam].id)
			igplayers[steam].voteRewarded = os.time()
			igplayers[steam].voteRewardOwing = 0
			file:close()

			return
		end

		if ln == "2" then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Thanks for voting today.  You have already claimed your reward.  Vote for us tomorrow and you can claim another reward then.[-]")
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


function isServerHardcore(playerid)
	if server.hardcore and accessLevel(playerid) > 2 then
		return true
	else
		return false
	end
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
	if server.allowPhysics ~= nil then file:write("server.allowPhysics=\"" .. trueFalse(server.allowPhysics) .. "\"\n") end
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
	if server.CBSMFriendly ~= nil then file:write("server.CBSMFriendly=\"" .. trueFalse(server.CBSMFriendly) .. "\"\n") end
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
	if server.ircTracker then file:write("server.ircTracker=\"" .. server.ircTracker .. "\"\n") end
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
	if server.waypointsPublic ~= nil then file:write("server.waypointsPublic=\"" .. trueFalse(server.waypointsPublic) .. "\"\n") end
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


function sendNextAnnouncement()
	local counter, cursor, errorString, rows, row

	if (tonumber(botman.playersOnline) == 0) then -- don't bother if nobody is there to see it
		return
	end

	counter = 1

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM announcements")
		rows = cursor:numrows()
		row = cursor:fetch({}, "a")
		while row do
			if tonumber(server.nextAnnouncement) == counter then
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape(row.message) .. "')")
			end

			counter = counter + 1
			row = cursor:fetch(row, "a")
		end
	end

	server.nextAnnouncement = tonumber(server.nextAnnouncement) + 1
	if server.nextAnnouncement > tonumber(rows) then server.nextAnnouncement = 1 end
	conn:execute("UPDATE server SET nextAnnouncement = " .. server.nextAnnouncement)
end


function getLastCommandIndex(code)
	local cursor, errorString, row

	cursor,errorString = conn:execute("SELECT MAX(cmdIndex) AS lastIndex FROM botCommands WHERE cmdCode = '" .. escape(code) .. "'")
	row = cursor:fetch({}, "a")

	return tonumber(row.lastIndex) + 1
end


function canSetWaypointHere(steam, x, z)
	local k, v, dist

	-- check for nearby bases that are not friendly
	for k, v in pairs(players) do
		if (v.homeX ~= nil) and k ~= steam then
				if (v.homeX ~= 0 and v.homeZ ~= 0) then
				dist = distancexz(x, z, v.homeX, v.homeZ)

				if (tonumber(dist) < tonumber(v.protectSize) + 10) then
					if not isFriend(k, steam) then
						return false, k
					end
				end
			end
		end

		if (v.home2X ~= nil) and k ~= steam then
				if (v.home2X ~= 0 and v.home2Z ~= 0) then
				dist = distancexz(x, z, v.home2X, v.home2Z)

				if (dist < tonumber(v.protectSize) + 10) then
					if not isFriend(k, steam) then
						return false, k
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
	-- update shop item names to match case of itemName in spawnableItems
	conn:execute("UPDATE shop INNER JOIN spawnableItems ON spawnableItems.itemName = shop.item SET shop.item = spawnableItems.itemName")

	-- update gimmePrizes prize names to match case of itemName in spawnableItems
	conn:execute("UPDATE gimmePrizes INNER JOIN spawnableItems ON spawnableItems.itemName = gimmePrizes.name SET gimmePrizes.name = spawnableItems.itemName")

	-- update item names in badItems to match case of itemName in spawnableItems
	conn:execute("UPDATE badItems INNER JOIN spawnableItems ON spawnableItems.itemName = badItems.item SET badItems.item = spawnableItems.itemName")

	-- update restrictedItems item name to match case of itemName in spawnableItems
	conn:execute("UPDATE restrictedItems INNER JOIN spawnableItems ON spawnableItems.itemName = restrictedItems.item SET restrictedItems.item = spawnableItems.itemName")

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
		conn:execute("TRUNCATE TABLE spawnableItems")
		conn:execute("UPDATE badItems SET validated = 0")
		conn:execute("UPDATE gimmePrizes SET validated = 0")
		conn:execute("UPDATE restrictedItems SET validated = 0")
		conn:execute("UPDATE shop SET validated = 0")

		loadShop()
	end

	sendCommand("li *")
end


function isAdminOnline()
	-- this function helps us choose different actions depending on if an admin is playing or not.
	local k, v

	for k,v in pairs(igplayers) do
		if v.accessLevel < 3 then
			return true
		end
	end

	return false
end


function isDestinationAllowed(steam, x, z)
	local outsideMap, outsideMapDonor, loc

	outsideMap = squareDistance(x, z, server.mapSize)
	outsideMapDonor = squareDistance(x, z, server.mapSize + 5000)
	loc = inLocation(x, z)

	-- prevent player exceeding the map limit unless an admin and ignoreadmins is false
	if outsideMap and not isDonor(steam) and (accessLevel(steam) > 3) then
		if not loc then
			return false
		else
			-- check the locations access level restrictions
			if tonumber(locations[loc].accessLevel) < accessLevel(steam) then
				return false
			end
		end
	end

	if outsideMapDonor and (accessLevel(steam) > 3 or not botman.ignoreAdmins) then
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
			message("pm " .. steam .. " [" .. server.chatColour .. "]Found in blacklist.  startIP = " .. row.StartIP .. ", endIP = " .. row.EndIP .. "[-]")
		else
			irc_chat(name, "Found in blacklist.  startIP = " .. row.StartIP .. ", endIP = " .. row.EndIP)
		end
	else
		if igplayers[name] then
			message("pm " .. steam .. " [" .. server.chatColour .. "]" .. IP .. " is not in the blacklist.[-]")
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


function setChatColour(steam, level)
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
					if botman.dbConnected then conn:execute("UPDATE players SET exiled = 1, silentBob = 1, canTeleport = 0 WHERE steam = " .. k) end

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
	if botman.dbConnected then conn:execute("INSERT INTO helpCommands (command, description, notes, keywords, accessLevel, ingameOnly) VALUES ('" .. escape(tmp.command) .. "','" .. escape(tmp.description) .. "','" .. escape(tmp.notes) .. "','" .. escape(tmp.keywords) .. "'," .. tmp.accessLevel .. "," .. tmp.ingameOnly .. ")") end
	if botman.dbConnected then conn:execute("INSERT INTO helpTopicCommands (topicID, commandID) VALUES (" .. topicID .. "," .. commandID .. ")") end
	commandID = commandID + 1
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
		message("pm " .. steam .. " [" .. server.warnColour .. "]You spent " .. amount .. " " .. server.moneyPlural .. "[-]")
	end
end


function fixBot()
	local k, v

	botman.fixingBot = false

	fixMissingStuff()
	fixShop()
	enableTimer("ReloadScripts")
	getServerData(true)

	-- join the irc server
	if botman.customMudlet then
		joinIRCServer()
	end

	if botman.dbConnected then
		conn:execute("TRUNCATE altertables")
		alertAdmins("The bot may become unresponsive for a while doing database maintenance. A bot restart after the bot starts talking again may also help.", "alert")
		irc_chat(server.ircMain, "The bot may become unresponsive for a while doing database maintenance. A bot restart after the bot starts talking again may also help.")
		tempTimer( 5, [[alterTables()]] )
	end
end


function addFriend(player, friend, auto)
	if auto == nil then auto = false end

	-- give a player a friend (yay!)
	-- returns true if a friend was added or false if already friends with them

	if (not string.find(friends[player].friends, friend)) then
		if auto then
			if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. player .. "," .. friend .. ", 1)") end
		else
			if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. player .. "," .. friend .. ", 0)") end
		end

		if friends[player].friends == "" then
			friends[player].friends = friend
		else
			friends[player].friends = friends[player].friends .. "," .. friend
		end

		return true
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

	-- add friends read from Coppi's lpf command
	-- grab the first one
	if not string.find(friends[pid].friends, fpid) then
		addFriend(pid, fpid, true)
	else
		if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. pid .. "," .. fpid .. ", 1)") end
	end

	-- grab the rest
	max = table.maxn(temp)
	for i=3,max,1 do
		fpid = string.trim(temp[i])
		if not string.find(friends[pid].friends, fpid) then
			addFriend(pid, fpid, true)
		else
			if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. pid .. "," .. fpid .. ", 1)") end
		end
	end
end


function trimLogs()
	local files, file, temp, k, v
	local yearPart, monthPart, dayPart

	files = {}

	for file in lfs.dir(homedir .. "/log") do
		if lfs.attributes(file,"mode") == nil then
			temp = string.split(file, "#")

			if temp[2] ~= nil then
				files[file] = {}
				files[file].delete = false
				files[file].date = temp[1]
				files[file].dateSplit = string.split(temp[1], "-")
			end
		end
	end

	for k,v in pairs(files) do
		if yearPart == nil then
			if v.dateSplit[1] == os.date('%Y') then
				yearPart = 1
			end

			if v.dateSplit[2] == os.date('%Y') then
				yearPart = 2
			end

			if v.dateSplit[3] == os.date('%Y') then
				yearPart = 3
			end
		end

		if dayPart == nil then
			if tonumber(v.dateSplit[1]) > 12 and yearPart ~= 1 then
				dayPart = 1
			end

			if tonumber(v.dateSplit[2]) > 12 and yearPart ~= 2 then
				dayPart = 2
			end

			if tonumber(v.dateSplit[3]) > 12 and yearPart ~= 3 then
				dayPart = 3
			end
		end

		if yearPart ~= nil and dayPart ~= nil then
			monthPart = 1

			if yearPart == 1 or dayPart == 1 then
				monthPart = 2
			end

			if yearPart == 2 or dayPart == 2 then
				monthPart = 3
			end
		end
	end

	for k,v in pairs(files) do
		fileDate = os.time({year = v.dateSplit[yearPart], month = v.dateSplit[monthPart], day = v.dateSplit[dayPart], hour = 0, min = 0, sec = 0})
		if os.time() - fileDate > 604800 then -- older than 7 days
			os.remove(homedir .. "/log/" .. k)
		end
	end
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
	if string.find(zombieLower, "cop") or string.find(zombieLower, "dog") or string.find(zombieLower, "bear") or string.find(zombieLower, "feral") or string.find(zombieLower, "radiated") or string.find(zombieLower, "behemoth") or string.find(zombieLower, "template") then
		gimmeZombies[entityID].doNotSpawn = true

		if string.find(zombieLower, "radiated") or string.find(zombieLower, "feral") then
			if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET bossZombie = 1, doNotSpawn = 1 WHERE entityID = " .. entityID) end
		else
			if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET bossZombie = 0, doNotSpawn = 1 WHERE entityID = " .. entityID) end
		end
	else
		if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET bossZombie = 0, doNotSpawn = 0 WHERE entityID = " .. entityID) end
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

		if r == 12 then
			if tonumber(server.gameVersionNumber) < 17 then
				sendCommand("give " .. igplayers[chatvars.playerid].id .. " turd 1")
			end

			return("I don't give a shit. That was a lie, but you're still not using this command.")
		end

		if r == 13 then return("Bored now.") end
		if r == 14 then return("[DENIED]  [DENI[DEN[DENIED]ENIED]NIED]  [DENIED]") end
		if r == 15 then return("A bit slow are we? Noooooooooooooooo.") end
		if r == 16 then return("Yyyyyyeeee No.") end
	end
end


function downloadHandler(event, ...)
	local steam

   if event == "sysDownloadDone" then
		botman.fileDownloadTimestamp = nil

		if customAPIHandler ~= nil then
			-- read the note on overriding bot code in custom/custom_functions.lua
			if customAPIHandler(...) then
				return
			end
		end

		if string.find(..., "adminList.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read admin list
			readAPI_AdminList()
			return
		end

		if string.find(..., "apicheck.txt", nil, true) then
			-- [massive feedback]  yep this thing's on
			botman.APICheckPassed = true
			return
		end

		if string.find(..., "banList.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read ban list
			readAPI_BanList()
			return
		end

		if string.find(..., "bc-go.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read bc-go from Stompy's BC mod to get a list of game objects
			readAPI_BCGo()
			return
		end

		if string.find(..., "bc-lp.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read bc-lp from Stompy's BC mod
			readAPI_BCLP()
			return
		end

		if string.find(..., "bc-time.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read bc-time from Stompy's BC mod to get current server real time
			readAPI_BCTime()
			return
		end

		if string.find(..., "bm-anticheat-report.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- who's on the naughty list?
			readAPI_BMAnticheatReport()
			return
		end

		if string.find(..., "bm-listplayerbed.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- you sleep where?
			readAPI_BMListPlayerBed()
			return
		end

		if string.find(..., "bm-listplayerfriends.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- who's your friend?
			readAPI_BMListPlayerFriends()
			return
		end

		if string.find(..., "bm-config.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read the Botman mod's config file
			readAPI_BMReadConfig()
			return
		end

		if string.find(..., "bm-resetregions-list.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read the reset regions from the Botman mod
			readAPI_BMResetRegionsList()
			return
		end

		if string.find(..., "bm-uptime.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read bm-uptime
			readAPI_BMUptime()
			return
		end

		if string.find(..., "command.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read output of API command
			readAPI_Command()
			return
		end

		if string.find(..., "gg.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read gg
			readAPI_GG()
			return
		end

		if string.find(..., "gametime.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read gt
			readAPI_GT()
			return
		end

		if string.find(..., "help.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read help
			readAPI_Help() -- help! help!
			return
		end

		if string.find(..., "hostiles.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read hostiles
			readAPI_Hostiles() -- GRR!  ARGH!
			return
		end

		if string.find(..., "installedMods.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read version
			readAPI_Version()
			return
		end

		if string.find(..., "inventories.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read inventories
			readAPI_Inventories()
			return
		end

		if string.find(..., "le.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read le
			readAPI_LE()
			return
		end

		if string.find(..., "li.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read li
			readAPI_LI()
			return
		end

		if string.find(..., "lkp.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read lkp
			readAPI_LKP()
			return
		end

		if string.find(..., "llp.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read llp
			readAPI_LLP()
			return
		end

		if string.find(..., "log.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read log
			readAPI_ReadLog()
			return
		end

		if string.find(..., "lpf.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read lpf
			readAPI_LPF()
			return
		end

		if string.find(..., "mem.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read mem
			readAPI_MEM()
			return
		end

		if string.find(..., "pgd.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read pgd
			readAPI_PGD()
			return
		end

		if string.find(..., "playersOnline.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read players online
			readAPI_PlayersOnline()
			return
		end

		if string.find(..., "pug.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read pug
			readAPI_PUG()
			return
		end

		if string.find(..., "se.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read se
			readAPI_SE()
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

		if string.find(..., "webUIUpdates.txt", nil, true) then
			botman.lastAPIResponseTimestamp = os.time()
			botman.APIOfflineCount = 0

			-- read webUIUpdates
			readAPI_webUIUpdates()
			return
		end

   elseif event == "sysDownloadError" then
	   failDownload(event, ...) -- Oh no!  Critical failure!
	end
end


function failDownload(event, filePath)
	 if string.find(filePath, "Forbidden") and string.find(filePath, "api/", nil, true) then
		botman.APIOffline = true
		toggleTriggers("api offline")

		if botman.telnetOffline and botman.APIOffline then
			botman.botOffline = true
			return
		end
	 end

	 if string.find(filePath, "Socket operation timed out") then
		botman.APIOffline = true
		toggleTriggers("api offline")

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
		if (v.name == player) and (k ~= steam) and (tonumber(k) ~= 0) then
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
		cursor,errorString = conn:execute("SELECT * FROM whitelist WHERE steam = " .. steam)
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
	local dist, size, greet, home, time, r

	greet = false
	home = false

	if players[steam].lastAtHome == nil then
		players[steam].lastAtHome = os.time()
	end

	-- base 1
	if math.abs(players[steam].homeX) > 0 and math.abs(players[steam].homeZ) > 0 then
		dist = distancexz(players[steam].xPos, players[steam].zPos, players[steam].homeX, players[steam].homeZ)
		size = tonumber(players[steam].protectSize)

		if (dist <= size + 30) then
			home = true

			if not players[steam].atHome then
				greet = true
			end
		end
	end

	-- base 2
	if math.abs(players[steam].home2X) > 0 and math.abs(players[steam].home2Z) > 0 then
		dist = distancexz(players[steam].xPos, players[steam].zPos, players[steam].home2X, players[steam].home2Z)
		size = tonumber(players[steam].protect2Size)

		if (dist <= size + 30) then
			home = true

			if not players[steam].atHome then
				greet = true
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
	end
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
			if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. k .. ",'" .. escape(msg) .. ")") end
		end
	end
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

	max = table.maxn(tbl)
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

	max = table.maxn(tbl)
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
		cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .."  ORDER BY inventoryTrackerID DESC LIMIT 0, 1")
		row = cursor:fetch({}, "a")

		tbl = string.split(row.belt .. row.pack .. row.equipment, "|")

		max = table.maxn(tbl)
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
		cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .."  ORDER BY inventoryTrackerID DESC LIMIT 0, 1")
		row = cursor:fetch({}, "a")

		tbl = string.split(row.belt, "|")

		max = table.maxn(tbl)
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
	for k, v in pairs(players) do
		if (v.homeX ~= nil) and k ~= steam then
				if (v.homeX ~= 0 and v.homeZ ~= 0) then
				dist = distancexz(players[steam].xPos, players[steam].zPos, v.homeX, v.homeZ)

				if tonumber(dist) < tonumber(minimumDist) then
					if not isFriend(k, steam) then
						isValid = false -- curses!
					end
				end
			end
		end

		if (v.home2X ~= nil) and k ~= steam then
				if (v.home2X ~= 0 and v.home2Z ~= 0) then
				dist = distancexz(players[steam].xPos, players[steam].zPos, v.home2X, v.home2Z)

				if tonumber(dist) < tonumber(minimumDist) then
					if not isFriend(k, steam) then
						isValid = false -- oh noes!
					end
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

			if botman.dbConnected then conn:execute("UPDATE players SET xPosOld = " .. players[steam].xPosOld .. ", yPosOld = " .. players[steam].yPosOld .. ", zPosOld = " .. players[steam].zPosOld .. " WHERE steam = " .. steam) end
		else
			players[steam].xPosOld2 = players[steam].xPos
			players[steam].yPosOld2 = players[steam].yPos + 1
			players[steam].zPosOld2 = players[steam].zPos

			if botman.dbConnected then conn:execute("UPDATE players SET xPosOld2 = " .. players[steam].xPosOld2 .. ", yPosOld2 = " .. players[steam].yPosOld2 .. ", zPosOld2 = " .. players[steam].zPosOld2 .. " WHERE steam = " .. steam) end
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
		if (accessLevel(k) < 3) then
			if igplayers[k] then
				message("pm " .. k .. " [" .. server.chatColour .. "]" .. message .. "[-]")
			else
				if botman.dbConnected then conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. k .. ", '" .. escape(message) .. "')") end
			end
		end
	end
end


function kick(steam, reason)
	local tmp

	if reason ~= nil then
		stripAngleBrackets(reason)
	end

	tmp = steam
	-- if there is no player with steamid steam, try looking it up incase we got their name instead of their steam
	if not players[steam] then
		steam = LookupPlayer(string.trim(steam))
		-- restore the original steam value if nothing matched as we may be banning someone who's never played here.
		if steam == 0 then steam = tmp end
	end

	if igplayers[steam] and reason ~= "Server restarting." then
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[steam].xPos .. "," .. players[steam].yPos .. "," .. players[steam].zPos .. ",'" .. botman.serverTime .. "','kick','Player " .. steam .. " " .. escape(players[steam].name) .. " kicked for " .. escape(reason) .. "'," .. steam .. ")") end
	end

	sendCommand("kick " .. steam .. " " .. " \"" .. reason .. "\"")
	botman.playersOnline = tonumber(botman.playersOnline) - 1
	irc_chat(server.ircMain, "Player " .. players[steam].name .. " kicked. Reason: " .. reason)
end


function banPlayer(steam, duration, reason, issuer, localOnly)
	local id, tmp, admin, belt, pack, equipment, country, isArchived, playerName, owner

	admin = 0
	playerName = "Not Sure" -- placeholder in case we're banning a steam ID that hasn't played here yet.
	isArchived = false

	if not players[steam] then
		id, owner = LookupArchivedPlayer(steam)

		if not (id == 0) then
			playerName = playersArchived[id].name
			isArchived = true
		end
	else
		isArchived = false
		playerName = players[steam].name
	end

	if accessLevel(steam) < 3 then
		irc_chat(server.ircAlerts, "Request to ban admin " .. playerName .. "  [DENIED]")
		message("pm " .. issuer .. " [" .. server.chatColour .. "]Request to ban admin " .. playerName .. "  [DENIED][-]")
		return
	end

	belt = ""
	pack = ""
	equipment = ""
	country = ""

	if reason == nil then
		reason = "banned"
	else
		stripAngleBrackets(reason)
	end

	if issuer then
		admin = issuer
	end

	tmp = steam
	-- if there is no player with steamid steam, try looking it up incase we got their name instead of their steam
	if not players[steam] then
		steam, owner = LookupPlayer(string.trim(steam))

		if steam == 0 then
			steam,owner = LookupArchivedPlayer(string.trim(steam))
		end

		-- restore the original steam value if nothing matched as we may be banning someone who's never played here.
		if steam == 0 then steam = tmp end
	end

	sendCommand("ban add " .. steam .. " " .. duration .. " \"" .. reason .. "\"")

	-- grab their belt, pack and equipment
	if players[steam] or playersArchived[steam] then
		if not isArchived then
			country = players[steam].country
		else
			country = playersArchived[steam].country
		end

		if botman.dbConnected then
			cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .." ORDER BY inventoryTrackerid DESC LIMIT 1")
			row = cursor:fetch({}, "a")
			if row then
				belt = row.belt
				pack = row.pack
				equipment = row.equipment
			end

			if not isArchived then
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[steam].xPos .. "," .. players[steam].yPos .. "," .. players[steam].zPos .. ",'" .. botman.serverTime .. "','ban','Player " .. steam .. " " .. escape(playerName) .. " has has been banned for " .. duration .. " for " .. escape(reason) .. "'," .. steam .. ")")
			else
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. playersArchived[steam].xPos .. "," .. playersArchived[steam].yPos .. "," .. playersArchived[steam].zPos .. ",'" .. botman.serverTime .. "','ban','Player " .. steam .. " " .. escape(playerName) .. " has has been banned for " .. duration .. " for " .. escape(reason) .. "'," .. steam .. ")")
			end
		end

		irc_chat(server.ircMain, "[BANNED] Player " .. steam .. " " .. playerName .. " has been banned for " .. duration .. " " .. reason)
		irc_chat(server.ircAlerts, server.gameDate .. " [BANNED] Player " .. steam .. " " .. playerName .. " has been banned for " .. duration .. " " .. reason)
		alertAdmins("Player " .. playerName .. " has been banned for " .. duration .. " " .. reason)

		-- add to bots db
		if botman.botsConnected and not localOnly then
			if players[steam] then
				if tonumber(players[steam].pendingBans) > 0 then
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin, GBLBan, GBLBanActive, level) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "'," .. tonumber(players[steam].timeOnServer) + tonumber(players[steam].playtime) .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].zombies .. ",'" .. players[steam].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "',1,1," .. players[steam].level .. ")")
					irc_chat(server.ircMain, "Player " .. steam .. " " .. players[steam].name .. " has been globally banned.")
					message("say [" .. server.alertColourColour .. "]" .. players[id].name .. " has been globally banned.[-]")
				else
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin, level) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "'," .. tonumber(players[steam].timeOnServer) + tonumber(players[steam].playtime) .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].zombies .. ",'" .. players[steam].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "'," .. players[steam].country .. ")")
				end
			end

			if playersArchived[steam] then
				if tonumber(playersArchived[steam].pendingBans) > 0 then
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin, GBLBan, GBLBanActive, level) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "'," .. tonumber(playersArchived[steam].timeOnServer) + tonumber(playersArchived[steam].playtime) .. "," .. playersArchived[steam].score .. "," .. playersArchived[steam].playerKills .. "," .. playersArchived[steam].zombies .. ",'" .. playersArchived[steam].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "',1,1," .. playersArchived[steam].level .. ")")
					irc_chat(server.ircMain, "Player " .. steam .. " " .. playerName .. " has been globally banned.")
					message("say [" .. server.alertColourColour .. "]" .. playerName .. " has been globally banned.[-]")
				else
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin, level) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "'," .. tonumber(playersArchived[steam].timeOnServer) + tonumber(playersArchived[steam].playtime) .. "," .. playersArchived[steam].score .. "," .. playersArchived[steam].playerKills .. "," .. playersArchived[steam].zombies .. ",'" .. playersArchived[steam].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "'," .. playersArchived[steam].level .. ")")
				end
			end
		end

		-- Look for and also ban ingame players with the same IP
		for k,v in pairs(igplayers) do
			if v.ip == players[steam].ip and k ~= steam and v.ip ~= "" then
				sendCommand("ban add " .. k .. " " .. duration .. " \"same IP as banned player\"")

				if botman.dbConnected then
					cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. k .." ORDER BY inventoryTrackerid DESC LIMIT 1")
					row = cursor:fetch({}, "a")
					if row then
						belt = row.belt
						pack = row.pack
						equipment = row.equipment
					end

					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[k].xPos .. "," .. players[k].yPos .. "," .. players[k].zPos .. ",'" .. botman.serverTime .. "','ban','Player " .. k .. " " .. escape(players[k].name) .. " has has been banned for " .. duration .. " for " .. escape("same IP as banned player") .. "'," .. k .. ")")
				end

				irc_chat(server.ircMain, "[BANNED] Player " .. k .. " " .. players[k].name .. " has been banned for " .. duration .. " same IP as banned player")
				irc_chat(server.ircAlerts, server.gameDate .. " [BANNED] Player " .. k .. " " .. players[k].name .. " has been banned for " .. duration .. " same IP as banned player")
				alertAdmins("Player " .. players[k].name .. " has been banned for " .. duration .. " same IP as banned player")

				-- add to bots db
				if botman.botsConnected then
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin, level) VALUES ('" .. escape("MISSING") .. "'," .. k .. ",'" .. escape("same IP as banned player") .. "'," .. tonumber(players[k].timeOnServer) + tonumber(players[k].playtime) .. "," .. players[k].score .. "," .. players[k].playerKills .. "," .. players[k].zombies .. ",'" .. players[k].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "'," .. players[k].level .. ")")
				end
			end
		end
	else
		-- handle unknown steam id
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','ban','Player " .. steam .. " " .. steam .. " has has been banned for " .. duration .. " for " .. escape(reason) .. "'," .. steam .. ")") end
		irc_chat(server.ircMain, "[BANNED] Unknown player " .. steam .. " has been banned for " .. duration .. " " .. reason)
		irc_chat(server.ircAlerts, server.gameDate .. " [BANNED] Unknown player " .. steam .. " has been banned for " .. duration .. " " .. reason)

		-- add to bots db
		if botman.botsConnected then
			connBots:execute("INSERT INTO bans (bannedTo, steam, reason, permanent, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "',1,0,0,0,0,'','','','','" .. server.botID .. "','" .. admin .. "')")
		end
	end
end


function arrest(steam, reason, bail, releaseTime)
	local banTime = 60
	local cmd, prison

	prison = LookupLocation("prison")

	if not prison then
		if tonumber(server.maxPrisonTime) > 0 then
			banTime = server.maxPrisonTime
		end

		message("say [" .. server.alertColour .. "]" .. players[steam].name .. " has been banned for " .. banTime .. " minutes for " .. reason .. ".[-]")
		banPlayer(steam, banTime .. " minutes", reason, "")
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

	if accessLevel(steam) > 2 and (tonumber(bail) == 0) then
		players[steam].silentBob = true
		if botman.dbConnected then conn:execute("UPDATE players SET prisoner = 1, silentBob = 1, bail = 0, prisonReleaseTime = " .. players[steam].prisonReleaseTime .. ", prisonxPosOld = " .. players[steam].prisonxPosOld .. ", prisonyPosOld = " .. players[steam].prisonyPosOld .. ", prisonzPosOld = " .. players[steam].prisonzPosOld .. " WHERE steam = " .. steam) end
	else
		if botman.dbConnected then conn:execute("UPDATE players SET prisoner = 1, bail = " .. bail .. ", prisonReleaseTime = " .. players[steam].prisonReleaseTime .. ", prisonxPosOld = " .. players[steam].prisonxPosOld .. ", prisonyPosOld = " .. players[steam].prisonyPosOld .. ", prisonzPosOld = " .. players[steam].prisonzPosOld .. " WHERE steam = " .. steam) end
	end

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM locationSpawns WHERE location='prison'")
		rows = cursor:numrows()

		if rows > 0 then
			randomTP(steam, "prison")
		else
			cmd = "tele " .. steam .. " " .. locations[prison].x .. " " .. locations[prison].y .. " " .. locations[prison].z
			teleport(cmd, steam)
		end
	else
		cmd = "tele " .. steam .. " " .. locations[prison].x .. " " .. locations[prison].y .. " " .. locations[prison].z
		teleport(cmd, steam)
	end

	message("say [" .. server.warnColour .. "]" .. players[steam].name .. " has been sent to prison.  Reason: " .. reason .. ".[-]")
	message("pm " .. steam .. " [" .. server.chatColour .. "]You are confined to prison until released.[-]")

	if tonumber(bail) > 0 then
		message("pm " .. steam .. " [" .. server.chatColour .. "]You can release yourself for " .. bail .. " " .. server.moneyPlural .. ".[-]")
		message("pm " .. steam .. " [" .. server.chatColour .. "]Type " .. server.commandPrefix .. "bail to release yourself if you have the " .. server.moneyPlural .. ".[-]")
	end

	if tonumber(releaseTime) > 0 then
		days, hours, minutes = timeRemaining(os.time() + (releaseTime * 60))
		message("pm " .. steam .. " [" .. server.chatColour .. "]You will be released in " .. days .. " days " .. hours .. " hours and " .. minutes .. " minutes.[-]")
	end

	if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[steam].xPos .. "," .. players[steam].yPos .. "," .. players[steam].zPos .. ",'" .. botman.serverTime .. "','prison','Player " .. steam .. " " .. escape(players[steam].name) .. " has has been sent to prison for " .. escape(reason) .. "'," .. steam .. ")") end
end


function timeoutPlayer(steam, reason, bot)
	-- if the player is not already in timeout, send them there.
	if players[steam].timeout == false and players[steam].botTimeout == false then
		players[steam].timeout = true
		if accessLevel(steam) > 2 then players[steam].silentBob = true end
		if bot then players[steam].botTimeout = true end -- the bot initiated this timeout
		-- record their position for return
		players[steam].xPosTimeout = players[steam].xPos
		players[steam].yPosTimeout = players[steam].yPos
		players[steam].zPosTimeout = players[steam].zPos

		if botman.dbConnected then
			conn:execute("UPDATE players SET timeout = 1, botTimeout = " .. dbBool(bot) .. ", xPosTimeout = " .. players[steam].xPosTimeout .. ", yPosTimeout = " .. players[steam].yPosTimeout .. ", zPosTimeout = " .. players[steam].zPosTimeout .. " WHERE steam = " .. steam)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[steam].xPos .. "," .. players[steam].yPos .. "," .. players[steam].zPos .. ",'" .. botman.serverTime .. "','timeout','Player " .. steam .. " " .. escape(players[steam].name) .. " has has been sent to timeout for " .. escape(reason) .. "'," .. steam .. ")")
		end

		-- then teleport the player to timeout
		igplayers[steam].tp = 1
		igplayers[steam].hackerTPScore = 0
		sendCommand("tele " .. steam .. " " .. players[steam].xPosTimeout .. " 60000 " .. players[steam].zPosTimeout)
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

			if (v.remove and accessLevel(v.steam) > 2) and not testing then
				for a, b in pairs(igplayers) do
					dist = distancexz(v.x, v.z, b.xPos, b.zPos)

					if dist < 100 and v.removed == 0 then
						v.removed = 1
						conn:execute("UPDATE keystones SET removed = 1 WHERE steam = " .. v.steam .. " AND x = " .. v.x .. " AND y = " .. v.y .. " AND z = " .. v.z)
						sendCommand("rlp " .. v.x .. " " .. v.y .. " " .. v.z) -- BAM! and the claim is gone :D
					end
				end
			end
		end
	end
end


function dbWho(name, x, y, z, dist, days, hours, height, steamid, ingame)
	local cursor, errorString, row, counter, isStaff, sql

	isStaff = false

	if days == nil then days = 1 end
	if height == nil then height = 5 end

	if not botman.dbConnected then
		return
	end

	if players[steamid] then
		if tonumber(players[steamid].accessLevel) < 3 then
			isStaff = true
		end
	end

	connMEM:execute("DELETE FROM searchResults WHERE owner = " .. steamid)

	if tonumber(hours) > 0 then
		sql = "SELECT DISTINCT steam, session FROM tracker WHERE abs(x - " .. x .. ") <= " .. dist .. " AND ABS(z - " .. z .. ") <= " .. dist .. " AND ABS(y - " .. y .. ") <= " .. height .. " AND timestamp >= '" .. os.date("%Y-%m-%d %H:%M:%S", os.time() - (tonumber(hours) * 3600)) .. "'"

		cursor,errorString = conn:execute(sql)
	else
		sql = "SELECT DISTINCT steam, session FROM tracker WHERE abs(x - " .. x .. ") <= " .. dist .. " AND ABS(z - " .. z .. ") <= " .. dist .. " AND ABS(y - " .. y .. ") <= " .. height .. " AND timestamp >= '" .. os.date("%Y-%m-%d %H:%M:%S", os.time() - (tonumber(days) * 86400)) .. "'"

		cursor,errorString = conn:execute(sql)
	end

	row = cursor:fetch({}, "a")
	counter = 1
	rows = cursor:numrows()

	if not ingame then
		if tonumber(rows) > 50 then
			irc_chat(name, "****** Report length " .. rows .. " rows.  Cancel it by typing nuke irc")
		end
	end

	while row do
		-- we will use the searchResults table later.  For now we're not doing anything with it.  It will become a lookup table with record numbers.
		--conn:execute("INSERT INTO searchResults (owner, steam, session, counter) VALUES (" .. ownerid .. "," .. row.steam .. "," .. row.session .. "," .. counter .. ")")
		if ingame then
			if isStaff then
				if players[row.steam] then
					message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. row.steam .. " " .. players[row.steam].id .. " " .. players[row.steam].name .. " sess: " .. row.session .. "[-]")
				else
					message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. row.steam .. " " .. playersArchived[row.steam].id .. " " .. playersArchived[row.steam].name .. " (archived) sess: " .. row.session .. "[-]")
				end
			else
				if players[row.steam] then
					message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. players[row.steam].name .. " session: " .. row.session .. "[-]")
				else
					message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. playersArchived[row.steam].name .. " session: " .. row.session .. "[-]")
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


function dailyMaintenance()
	local cursor, errorString, row

	-- put something here to be run when the server date hits midnight
	updateBot()

	-- purge old tracking data and set a flag so we can tell when the database maintenance is complete.
	if tonumber(server.trackingKeepDays) > 0 then
		conn:execute("UPDATE server SET databaseMaintenanceFinished = 0")
		deleteTrackingData(server.trackingKeepDays)
	end

	-- Bring out yer dead!

	-- delete telnet logs older than server.telnetLogKeepDays
	os.execute("find " .. homedir .. "/log* -mtime +" .. server.telnetLogKeepDays .. " -exec rm {} \\;")

	-- delete other old logs
	os.execute("find " .. botman.chatlogPath .. "/*inventory.txt -mtime +" .. server.telnetLogKeepDays .. " -exec rm {} \\;")

	-- expire donors who's expiry is in the past
	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM donors WHERE expired = 0")
		row = cursor:fetch({}, "a")

		if row then
			while row do
				if row.expiry < os.time() then
					conn:execute("UPDATE donors SET expired = 1 WHERE steam = " .. row.steam)

					irc_chat(server.ircAlerts, "Player " .. players[row.steam].name ..  " " .. row.steam .. " donor status has expired.")
					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','donor','" .. escape(players[row.steam].name) .. " " .. row.steam .. " donor status expired.'," .. row.steam ..")")

					players[row.steam].protect2 = false
					players[row.steam].maxWaypoints = server.maxWaypoints
					conn:execute("UPDATE players SET protect2 = 0, donor = 0, donorLevel = 0, maxWaypoints = " .. server.maxWaypoints .. " WHERE steam = " .. row.steam)

					-- reload the player's waypoints
					loadWaypoints(row.steam)

					conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. row.steam .. ", '" .. escape("Your donor status has expired.  If you have more waypoints now than your new maximum, you won't be able to set new ones unless you delete your excess waypoints. Also any extra bases have lost bot protection.") .. "')")
				end

				row = cursor:fetch(row, "a")
			end

			-- reload donors from the database
			loadDonors()
		end

		-- delete expired donor records older than 60 days
		conn:execute("DELETE FROM donors WHERE expired = 1 AND expiry < " .. os.time() - 5184000)

		-- make sure we have the current player names in the donors table
		conn:execute("UPDATE donors SET name = (SELECT name FROM players WHERE donors.steam = players.steam)")
	end

	return true
end


function startReboot()
	botman.serverRebooting = true

	-- add a random delay to mess with dupers
	local rnd = randSQL(10)

	sendCommand("sa")
	botman.rebootTimerID = tempTimer( 10 + rnd, [[finishReboot()]] )
end


function clearRebootFlags()
	botman.nextRebootTest = os.time() + 1800
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

	for k, v in pairs(igplayers) do
		kick(k, "Server restarting.")
	end

	botman.ignoreAdmins = true
	server.uptime = 0

	-- flag all players as offline
	connBots:execute("UPDATE players SET online = 0 WHERE botID = " .. server.botID)

	-- do some housekeeping
	for k, v in pairs(players) do
		v.botQuestion = ""
	end

	clearRebootFlags()
	conn:execute("DELETE FROM TABLE memTracker")
	conn:execute("TRUNCATE TABLE commandQueue")
	connMEM:execute("DELETE FROM TABLE gimmeQueue")
	tempTimer( 10, [[sendCommand("shutdown")]] )

	-- check for bot updates
	updateBot()
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
			-- force logging to start a new file
			telnetLogFile:close()
			telnetLogFileName = homedir .. "/telnet_logs/" .. os.date("%Y-%m-%d#%H-%M") .. ".txt"
			telnetLogFile = io.open(telnetLogFileName, "a")
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
	oldCount = table.maxn(words)

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

	cursor,errorString = conn:execute("SELECT count(remove) as deleted FROM keystones WHERE steam = " .. steam .. " AND removed = 1")
	row = cursor:fetch({}, "a")

	if row then
		if tonumber(row.deleted) > 0 then
			players[steam].removedClaims = players[steam].removedClaims + tonumber(row.deleted)
			if botman.dbConnected then conn:execute("UPDATE players SET removedClaims = " .. players[steam].removedClaims .. " WHERE steam = " .. steam) end

			cursor,errorString = conn:execute("SELECT * FROM keystones WHERE steam = " .. steam .. " AND removed = 1")
			row = cursor:fetch({}, "a")

			while row do
				keystones[row.x .. row.y .. row.z] = nil
				row = cursor:fetch(row, "a")
			end

			conn:execute("DELETE FROM keystones WHERE steam = " .. steam .. " AND removed = 1")

			if not string.find(players[steam].lastCommand, "give") then
				message("pm " .. steam .. " [" .. server.chatColour .. "]Some of your claims have been removed.  You can get them back by typing " .. server.commandPrefix .. "give claims.[-]")
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

		if (not (whitelist[steam] or isDonor(steam))) and accessLevel(steam) > 2 then
			irc_chat(server.ircMain, "Blacklisted IP detected. " .. players[steam].name)
			irc_chat(server.ircAlerts, server.gameDate .. " blacklisted IP detected. " .. players[steam].name)
		end

		players[steam].china = true
		players[steam].country = "CN"
		players[steam].ircTranslate = true

		if server.blacklistResponse == 'exile' and (not (whitelist[steam] or isDonor(steam))) and accessLevel(steam) > 2 then
			if not players[steam].exiled then
				players[steam].exiled = true
				if botman.dbConnected then conn:execute("UPDATE players SET country = 'CN', exiled = 1, ircTranslate = 1 WHERE steam = " .. steam) end
			end
		end

		if server.blacklistResponse == 'ban' and (not (whitelist[steam] or isDonor(steam))) and accessLevel(steam) > 2 then
			irc_chat(server.ircMain, "Blacklisted player " .. players[steam].name .. " banned.")
			irc_chat(server.ircAlerts, server.gameDate .. " blacklisted player " .. players[steam].name .. " banned.")
			banPlayer(steam, "10 years", "blacklisted", "")
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
			split = string.split(iprange, "-")
			ip1 = IPToInt(string.trim(split[1]))
			ip2 = IPToInt(string.trim(split[2]))

			-- player's IP
			IP = IPToInt(players[steam].ip)
		end

		if (not (whitelist[steam] or isDonor(steam))) and (not server.allowProxies) and accessLevel(steam) > 2 then
			for k,v in pairs(proxies) do
				if string.find(ln, string.upper(v.scanString), nil, true) then
					v.hits = tonumber(v.hits) + 1
					proxy = true

					if botman.botsConnected then
						connBots:execute("UPDATE proxies SET hits = hits + 1 WHERE scanString = '" .. escape(k) .. "'")
					end

					if server.blacklistResponse ~= 'nothing' and accessLevel(steam) > 2 then
						if v.action == "ban" or v.action == "" then
							irc_chat(server.ircMain, "Player " .. players[steam].name .. " banned. Detected proxy " .. v.scanString)
							irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " banned. Detected proxy " .. v.scanString)
							banPlayer(steam, "10 years", "Banned proxy. Contact us to get unbanned and whitelisted.", "")
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
			if players[steam].country ~= "" and players[steam].country ~= country and (players[steam].country == "CN" or players[steam].country == "HK" or country == "CN" or country == "HK") and (not (whitelist[steam] or isDonor(steam))) and accessLevel(steam) > 2 then
				irc_chat(server.ircAlerts, server.gameDate .. " possible proxy detected! Country changed! " .. steam .. " " .. players[steam].name .. " " .. players[steam].ip .. " old country " .. players[steam].country .. " new " .. country)
				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (0,0,0'" .. botman.serverTime .. "','proxy','Suspected proxy used by " .. escape(players[steam].name) .. " " .. players[steam].ip .. " old country " .. players[steam].country .. " new " .. country .. "," .. steam .. ")") end
				proxy = true
			else
				 players[steam].country = country
			end

			if country == "CN" or country == "HK" then
				onBlacklist = true
			end
		end

		-- We consider HongKong to be China since Chinese players connect from there too.
		if (country == "CN" or country == "HK") and (not (whitelist[steam] or isDonor(steam))) and accessLevel(steam) > 2 then
			-- China detected. Add ip range to IPBlacklist table
			irc_chat(server.ircMain, "Chinese IP detected. " .. players[steam].name .. " " .. players[steam].ip)
			irc_chat(server.ircAlerts, server.gameDate .. " Chinese IP detected. " .. players[steam].name .. " " .. players[steam].ip)
			players[steam].china = true
			players[steam].ircTranslate = true

			if server.blacklistResponse == 'exile' and not exiled and accessLevel(steam) > 2 then
				if not players[steam].exiled then
					players[steam].exiled = true
					irc_chat(server.ircMain, "Chinese player " .. players[steam].name .. " exiled.")
					irc_chat(server.ircAlerts, server.gameDate .. " Chinese player " .. players[steam].name .. " exiled.")
					exiled = true
				end
			end

			if server.blacklistResponse == 'ban' and not banned and accessLevel(steam) > 2 then
				irc_chat(server.ircMain, "Chinese player " .. players[steam].name .. " banned.")
				irc_chat(server.ircAlerts, server.gameDate .. " Chinese player " .. players[steam].name .. " banned.")
				banPlayer(steam, "10 years", "blacklisted", "")
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
			connBots:execute("INSERT INTO IPTable (StartIP, EndIP, Country, OrgName, IP, steam, botID) VALUES (" .. ip1 .. "," .. ip2 .. ",'" .. country .. "','" .. escape(ISP) .. "','" .. players[steam].ip .. "'," .. steam .. "," .. server.botID .. ")")
		end
	end

	-- alert players
	if blacklistedCountries[country] and server.blacklistResponse ~= 'ban' and (not (whitelist[steam] or isDonor(steam))) and accessLevel(steam) > 2 then
		for k, v in pairs(igplayers) do
			if players[k].exiled~=1 and not players[k].prisoner then
				message("pm " .. k .. " Player " .. players[steam].name .. " from blacklisted country " .. country .. " has joined.[-]")
			end
		end
	end

	if blacklistedCountries[country] and (not (whitelist[steam] or isDonor(steam))) and accessLevel(steam) > 2 then
		if server.blacklistResponse == 'ban' and not banned then
			irc_chat(server.ircMain, "Player " .. players[steam].name .. " banned. Blacklisted country " .. country)
			irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " banned. Blacklisted country " .. country)
			banPlayer(steam, "10 years", "Sorry, your country has been blacklisted :(", "")
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

	if server.whitelistCountries ~= '' and not whitelistedCountries[country] and (not (whitelist[steam] or isDonor(steam))) and not banned and accessLevel(steam) > 2 then
		irc_chat(server.ircMain, "Player " .. players[steam].name .. " temp banned 1 month. Country not on whitelist " .. country)
		irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " temp banned 1 month. Country not on whitelist " .. country)
		banPlayer(steam, "1 month", "Sorry, this server uses a whitelist.", "")
		banned = true
	end

	if botman.dbConnected then
		if server.blacklistResponse ~= 'nothing' and exiled and (not (whitelist[steam] or isDonor(steam))) and accessLevel(steam) > 2 then
			conn:execute("UPDATE players SET country = '" .. escape(country) .. "', exiled = 1, ircTranslate = 1 WHERE steam = " .. steam)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (" .. players[steam].xPos .. "," .. players[steam].yPos .. "," .. players[steam].zPos .. ",'" .. botman.serverTime .. "','info','Blacklisted player joined. Name: " .. escape(player) .. " SteamID: " .. steam .. " IP: " .. players[steam].ip  .. "'," .. steam .. ")")
		end
	end

	if proxy then
		os.rename(homedir .. "/dns/" .. steam .. "_old.txt", homedir .. "/proxies/" .. steam .. "_" .. country .. ".txt")
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/proxies/" .. steam .. "_" .. country .. ".txt")
	else
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	end

	if botman.dbConnected then conn:execute("UPDATE players SET country = '" .. country .. "' WHERE steam = " .. steam) end

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
	players[steam].exit2X = 0
	players[steam].exit2Y = 0
	players[steam].exit2Z = 0
	players[steam].exitX = 0
	players[steam].exitY = 0
	players[steam].exitZ = 0
	players[steam].GBLCount = 0
	players[steam].gimmeCooldown = 0
	players[steam].gimmeCount = 0
	players[steam].hackerScore = 0
	players[steam].home2X = 0
	players[steam].home2Y = 0
	players[steam].home2Z = 0
	players[steam].homeX = 0
	players[steam].homeY = 0
	players[steam].homeZ = 0
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
	players[steam].protect = false
	players[steam].protect2 = false
	players[steam].protect2Size = server.baseSize
	players[steam].protectSize = server.baseSize
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
	players[steam].waypoint2X = 0
	players[steam].waypoint2Y = 0
	players[steam].waypoint2Z = 0
	players[steam].waypointsLinked = false
	players[steam].waypointX = 0
	players[steam].waypointY = 0
	players[steam].waypointZ = 0
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

	conn:execute("DELETE FROM waypoints WHERE steam = " .. steam)
	conn:execute("DELETE FROM hotspots WHERE owner = " .. steam)

	updatePlayer(steam)

	return true
end


function initNewPlayer(steam, player, entityid, steamOwner, line)
	local cursor, errorString, rows

	cursor,errorString = conn:execute("SELECT steam FROM players WHERE steam = " .. steam)
	rows = cursor:numrows()

	if tonumber(rows) > 0 then
		irc_chat(server.ircAlerts, "Init new player record aborted because record already exists!")
		-- abort! abort! The player record exists!
		return
	end

	cursor,errorString = conn:execute("SELECT distinct steam FROM events WHERE steam = " .. steam)
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

	if botman.dbConnected then conn:execute("INSERT INTO players (steam, id, name, steamOwner) VALUES (" .. steam .. "," .. entityid .. ",'" .. escape(player) .. "'," .. steamOwner .. ")") end

	players[steam] = {}
	players[steam].alertMapLimit = false
	players[steam].alertPrison = true
	players[steam].alertPVP = true
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
	players[steam].donorLevel = 0
	players[steam].DNSLookupCount = 0
	players[steam].exiled = false
	players[steam].firstSeen = os.time()
	players[steam].GBLCount = 0
	players[steam].gimmeCooldown = 0
	players[steam].gimmeCount = 0
	players[steam].hackerScore = 0
	players[steam].home2X = 0
	players[steam].home2Y = 0
	players[steam].home2Z = 0
	players[steam].homeX = 0
	players[steam].homeY = 0
	players[steam].homeZ = 0
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
	players[steam].playtime = 0
	players[steam].prisoner = false
	players[steam].prisonReason = ""
	players[steam].prisonReleaseTime = 0
	players[steam].prisonxPosOld = 0
	players[steam].prisonyPosOld = 0
	players[steam].prisonzPosOld = 0
	players[steam].protect = false
	players[steam].protect2 = false
	players[steam].protect2Size = server.baseSize
	players[steam].protectSize = server.baseSize
	players[steam].pvpTeleportCooldown = 0
	players[steam].pvpVictim = 0
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
	players[steam].VACBanned = false
	players[steam].walkies = false
	players[steam].watchPlayer = true
	players[steam].watchPlayerTimer = os.time() + server.defaultWatchTimer
	players[steam].waypoint2X = 0
	players[steam].waypoint2Y = 0
	players[steam].waypoint2Z = 0
	players[steam].waypointsLinked = false
	players[steam].waypointX = 0
	players[steam].waypointY = 0
	players[steam].waypointZ = 0
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


function initNewIGPlayer(steam, player, entityid, steamOwner)
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
	lfs.mkdir(homedir .. "/daily")
	lfs.mkdir(homedir .. "/dns")
	lfs.mkdir(homedir .. "/proxies")
	lfs.mkdir(homedir .. "/temp")
	lfs.mkdir(homedir .. "/scripts")
	lfs.mkdir(homedir .. "/data_backup")
	lfs.mkdir(homedir .. "/data_backup/players")
	lfs.mkdir(homedir .. "/chatlogs")

	if botman.chatlogPath then
		lfs.mkdir(botman.chatlogPath .. "/temp")
	end

	if not isFile(homedir .. "/custom/gmsg_custom.lua") then
		os.execute("wget http://www.botman.nz/gmsg_custom.lua -P \"" .. homedir .. "\"/custom/")
	end

	if not isFile(homedir .. "/custom/customIRC.lua") then
		os.execute("wget http://www.botman.nz/customIRC.lua -P \"" .. homedir .. "\"/custom/")
	end

	if not isFile(homedir .. "/custom/custom_functions.lua") then
		os.execute("wget http://www.botman.nz/custom_functions.lua -P \"" .. homedir .. "\"/custom/")
	end

	if type(gimmeZombies) ~= "table" then
		gimmeZombies = {}
		sendCommand("se")
	end

	if benchmarkBot == nil then
		benchmarkBot = false
	end
end


function saveDisconnectedPlayer(steam)
	-- this function has been moved from the player disconnected trigger so we can call it in other places if necessary to ensure all online player data is saved to the database.
	fixMissingPlayer(steam)

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

	if accessLevel(steam) < 3 then
		if botman.dbConnected then conn:execute("DELETE FROM memTracker WHERE admin = " .. steam) end
	end

	if botman.dbConnected then
		conn:execute("DELETE FROM messageQueue WHERE recipient = " .. steam)
		connMEM:execute("DELETE FROM gimmeQueue WHERE steam = '" .. steam .. "'")
		conn:execute("DELETE FROM commandQueue WHERE steam = " .. steam)
		conn:execute("DELETE FROM playerQueue WHERE steam = " .. steam)
	end

	-- delete player from igplayers table
	igplayers[steam] = nil
	lastHotspots[steam] = nil
	invTemp[steam] = nil

	-- update the player record in the database
	updatePlayer(steam)

	if	botman.botsConnected then
		-- insert or update player in bots db
		connBots:execute("INSERT INTO players (server, steam, ip, name, online, botid) VALUES ('" .. escape(server.serverName) .. "'," .. steam .. ",'" .. players[steam].ip .. "','" .. escape(players[steam].name) .. "',0," .. server.botID .. ") ON DUPLICATE KEY UPDATE ip = '" .. players[steam].ip .. "', name = '" .. escape(players[steam].name) .. "', online = 0")
	end
end


function shutdownBot(steam)
	local k, v

	for k,v in pairs(igplayers) do
		savePlayerData(k)
	end

	saveLuaTables(os.date("%Y%m%d_%H%M%S"))

	if igplayers[steam] then
		message("pm " .. steam .. " [" .. server.chatColour .. "]" .. server.botName .. " is ready to shutdown.  Player data is saved.[-]")
	end

	sendIrc(server.ircMain, server.botName .. " is ready to shutdown.  Player data is saved.")
end
