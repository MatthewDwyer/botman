--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- EDIT ME!
-- This script contains the telnet password, database connection info and the optional webdav folder where your server's daily chatlogs will be saved.

require "lfs"

function initBot()
	homedir = getMudletHomeDir()
	lfs.mkdir(homedir .. "/daily")
	lfs.mkdir(homedir .. "/dns")
	lfs.mkdir(homedir .. "/proxies")
	lfs.mkdir(homedir .. "/temp")
	lfs.mkdir(homedir .. "/scripts")
	lfs.mkdir(homedir .. "/chatlogs")

-- EDIT ME!
	telnetPassword = ""
	webdavFolder = "/var/www/chatlogs/bot"
	ircServer = "127.0.0.1"
	ircPort = 6667
	ircChannel = "bot"

-- EDIT ME!
	botDB = "bot"
	botDBUser = "bot"
	botDBPass = ""

-- EDIT ME!
	botsDB = "bots"
	botsDBUser = "bots"
	botsDBPass = ""
end


function openDB()
	lastAction = "Open Database"
	local sqliteDriver = require "luasql.sqlite3"
	env = luasql.sqlite3()

	conn = env:connect(getMudletHomeDir() .. "/Database_" .. botDB .. ".db")

	conn:execute("INSERT INTO memRestrictedItems (select * from restrictedItems)")
	conn:execute("INSERT INTO memLottery (select * from lottery)")
end


function openBotsDB()
	connBots = env:connect(getMudletHomeDir() .. "/Database_" .. botsDB .. ".db")
end
