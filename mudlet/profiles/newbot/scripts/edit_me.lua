--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- EDIT ME!
-- This script contains the telnet password, database connection info and the optional webdav folder where your server's daily chatlogs will be saved.

function initBot()
	telnetPassword = "telnet password"
	webdavFolder = "a folder in www/webdav/chatlogs owned by www-data with read/write permissions"
end


function openDB()
	lastAction = "Open Database"
	env = mysql.mysql()
	conn = env:connect("database name", "database user", "database password")

	-- copy restrictedItems and the lottery table into in memory tables to reduce disk IO.
	conn:execute("INSERT INTO memRestrictedItems (select * from restrictedItems)")
	conn:execute("INSERT INTO memLottery (select * from lottery)")
end


function openBotsDB()
	-- This is the 2nd database, bots which can be shared by more than one bot and can be cloud hosted.  This is not this bot's main database.
	connBots = env:connect("bots", "bots", "")
end