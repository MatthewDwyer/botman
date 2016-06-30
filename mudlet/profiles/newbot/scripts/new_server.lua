--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function gatherServerData()
	-- read a bunch of info from the server.  The bot will capture it elsewhere.

	send("lkp")
	tempTimer( 4, [[send("pm IPCHECK")]] )
	tempTimer( 5, [[send("admin list")]] )
	tempTimer( 7, [[send("ban list")]] )
	tempTimer( 9, [[send("gg")]] )
	tempTimer( 11, [[send("llp")]] )
end


function initServer()
	server.windowGMSG = "Chat"
	server.windowDebug = "Debug"
	server.windowAlerts = "Alerts"
	server.windowLists = "Lists"
	server.windowPlayers = "Players"
	server.botName = "Bot"
	server.prisonSize = 30
	server.mapSize = 30000
	server.chatColour = "D4FFD4"
	server.baseSize = 32
	server.ServerPort = "0"
	server.MOTD = "We have a new server bot!"
	server.IP = "0.0.0.0"
	server.ircAlerts = "#bot_alerts"
	server.ircMain = "#bot"
	server.ircWatch = "#bot_watch"
	server.allowGimme = false
	server.lottery = 0
	server.allowShop = false
	server.allowWaypoints = false
	server.maxPlayers = 24
	server.maxServerUptime = 6
	server.baseSize = 32
	server.baseCooldown = 2400
	server.protectionMaxDays = 31
	server.ircBotName = "Bot"
	server.ServerName = "New Server"
	server.rules = "No rules yet!"
	server.shopCountdown = 3
	server.gimmePeace = false

	conn:execute("DELETE FROM server")
	cursor,errorString = conn:execute("INSERT INTO server (botName, windowGMSG, windowAlerts, windowDebug, windowLists, windowPlayers) values ('Bot', 'Chat', 'Alerts', 'Debug', 'Lists', 'Players')")
end
