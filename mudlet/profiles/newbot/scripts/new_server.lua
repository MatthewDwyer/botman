--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function gatherServerData()
	-- read a bunch of info from the server.  The bot will capture it elsewhere.
	sendCommand("lkp -online")
	sendCommand("version")
	sendCommand("gg")
	sendCommand("admin list")
	sendCommand("ban list")
end


function initServer()
	local cursor, errorString

	botman.ignoreAdmins = true
	botman.chatlogPath = homedir .. "/chatlogs"

	server.accessLevelOverride = 99
	server.alertColour = "DC143C"
	server.alertLevelHack = false
	server.allowBank = true
	server.allowGarbageNames = true
	server.allowGimme = false
	server.allowLottery = false
	server.allowNumericNames = true
	server.allowOverstacking = false
	server.allowPhysics = true
	server.allowPlayerVoteTopics = false
	server.allowRapidRelogging = true
	server.allowReboot = false
	server.allowShop = false
	server.allowTeleporting = true
	server.allowVoting = false
	server.allowWaypoints = false
	server.announceTeleports = false
	server.bailCost = 0
	server.baseCooldown = 2400
	server.baseCost = 0
	server.baseSize = 32
	server.blacklistResponse = "ban"
	server.blacklistCountries = "CN,HK"
	server.botID = 0
	server.botName = "Bot"
	server.botNameColour = "6495ED"
	server.chatColour = "D4FFD4"
	server.checkLevelHack = false
	server.commandPrefix = "/"
	server.disableBaseProtection = false
	server.disableFetch = true
	server.disableLinkedWaypoints = false
	server.enableRegionPM = false
	server.gameType = "pve"
	server.gimmePeace = false
	server.hackerTPDetection = false
	server.hardcore = false
	server.hideCommands = true
	server.idleKick = false

	if serverIP then
		server.IP = serverIP
	else
		server.IP = "0.0.0.0"
	end

	server.ircAlerts = "#bot_alerts"
	server.ircBotName = "Bot"
	server.ircMain = "#bot"
	server.ircPrivate = true
	server.ircServer = "127.0.0.1"
	server.ircPort = "6667"
	server.ircTracker = "#bot_tracker"
	server.ircWatch = "#bot_watch"
	server.lastDailyReboot = 0
	server.lottery = 0
	server.lotteryMultiplier = 1
	server.mapSize = 10000
	server.maxPlayers = 0
	server.maxPrisonTime = -1
	server.maxServerUptime = 12
	server.maxWaypoints = 2
	server.moneyName = "Zenny"
	server.moneyPlural = "Zennies"
	server.MOTD = ""
	server.newPlayerTimer = 120
	server.northeastZone = ""
	server.northwestZone = ""
	server.overstackThreshold = 2000
	server.packCooldown = 0
	server.packCost = 0
	server.pingKick = -1
	server.playersCanFly = false
	server.prisonSize = 100
	server.protectionMaxDays = 31
	server.readLogUsingTelnet = true
	server.rebootHour = -1
	server.rebootMinute = 0
	server.reservedSlots = 0
	server.returnCooldown = 0
	server.rules = ""
	server.serverName = "New Server"
	server.ServerPort = "0"
	server.shopCountdown = 3
	server.southeastZone = ""
	server.southwestZone = ""
	server.swearCash = 0
	server.swearFine = 5
	server.swearJar = false
	server.teleportCost = 0
	server.teleportPublicCooldown = 0
	server.teleportPublicCost = 0

	if telnetPort then
		server.telnetPort = tonumber(telnetPort)
	else
		server.telnetPort = 0
	end

	server.updateBot = true
	server.warnColour = "FFA500"
	server.waypointCooldown = 0
	server.waypointCost = 0
	server.waypointsPublic = false
	server.website = ""
	server.welcome = ""
	server.windowDebug = "Debug"
	server.windowGMSG = "Chat"
	server.windowLists = "Lists"
	server.zombieKillReward = 1

	if botman.dbConnected then
		conn:execute("TRUNCATE server")
		cursor,errorString = conn:execute("INSERT INTO server (botName, windowGMSG, windowAlerts, windowDebug, windowLists, windowPlayers) values ('Bot', 'Chat', 'Alerts', 'Debug', 'Lists', 'Players')")
		-- save all the settings above to the server table
		saveServer()
	end
end
