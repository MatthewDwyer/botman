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

require "lfs"

function initBot()
	homedir = getMudletHomeDir()
	lfs.mkdir(homedir .. "/daily")
	lfs.mkdir(homedir .. "/dns")	
	lfs.mkdir(homedir .. "/proxies")
	lfs.mkdir(homedir .. "/temp")
	lfs.mkdir(homedir .. "/scripts")
	lfs.mkdir(homedir .. "/chatlogs")		

	dofile(homedir .. "/scripts/compat.lua")
	
-- EDIT ME!	
	telnetPassword = "01337days"
	-- webdavFolder = 
	ircServer = "127.0.0.1"
	ircPort = 6667
	ircChannel = "bot"
	
-- EDIT ME!	
	botDB = "botman"
	botDBUser = "botman"
	botDBPass = "botman01337"	
	
-- EDIT ME!		
	botsDB = "bots"
	botsDBUser = "botman"	
	botsDBPass = "botman01337"		
end


function openDB()
	lastAction = "Open Database"
	env = mysql.mysql()
-- EDIT ME!
	conn = env:connect(botDB, botDBUser, botDBPass, "192.168.2.59")

	conn:execute("INSERT INTO memRestrictedItems (select * from restrictedItems)")
	conn:execute("INSERT INTO memLottery (select * from lottery)")
end


function openBotsDB()
-- EDIT ME!
	connBots = env:connect(botsDB, botsDBUser, botsDBPass, "192.168.2.59")
end
