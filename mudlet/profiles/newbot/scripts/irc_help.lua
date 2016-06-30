--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function irc_commands()
	calledFunction = "irc_commands"

	local id
	id = LookupOfflinePlayer(irc_params[1], "all")

	irc_QueueMsg(irc_params[1], "Commands that output to IRC:")
	irc_QueueMsg(irc_params[1], "============================")

	if (accessLevel(id) > 2) then
		irc_QueueMsg(irc_params[1], "help (display this list)")
		irc_QueueMsg(irc_params[1], "admins (list admins)")
		irc_QueueMsg(irc_params[1], "day or date or time (show the game date and time)")		
		irc_QueueMsg(irc_params[1], "type say <something> to talk to players ingame")
		irc_QueueMsg(irc_params[1], "date, time, day (display the current game date and time)")
		irc_QueueMsg(irc_params[1], "locations")
		irc_QueueMsg(irc_params[1], "mods (list mods)")
		irc_QueueMsg(irc_params[1], "new players (list new players in the last 2 days)")		
		irc_QueueMsg(irc_params[1], "nuke irc (clear all queued irc bot spam directed to you)")		
		irc_QueueMsg(irc_params[1], "owners (list owners)")		
		irc_QueueMsg(irc_params[1], "resetzones")
		irc_QueueMsg(irc_params[1], "uptime (server and bot running times)")
		irc_QueueMsg(irc_params[1], "who (list in-game players)")
		irc_QueueMsg(irc_params[1], "server status (some daily stats)")		
		irc_QueueMsg(irc_params[1], "shop categories  (list categories)")
		irc_QueueMsg(irc_params[1], "shop <category>  (list items in a category)")
		irc_QueueMsg(irc_params[1], "shop <item>  (list all items that partially match what you type)")
		irc_QueueMsg(irc_params[1], "villages (list)")
		irc_QueueMsg(irc_params[1], "villagers (list villages and villagers)")
		irc_QueueMsg(name, "")
		return
	end

	irc_QueueMsg(irc_params[1], "If your login is not working properly try typing rescue me, hit return then login again.")
	irc_QueueMsg(irc_params[1], "")
	irc_QueueMsg(irc_params[1], "help (display this list)")
	irc_QueueMsg(irc_params[1], "help <keyword> (adding a new help system.  As it grows, more keywords will be known to it.)")
	irc_QueueMsg(irc_params[1], "list help <optional section> (eg. admin, server). Short help, just a list.")
	irc_QueueMsg(irc_params[1], "command help <optional section> (eg. admin, server). Longer help with info.")
	irc_QueueMsg(irc_params[1], "help topics (display help topics only)")
	irc_QueueMsg(irc_params[1], "help commands (for ingame commands that you can also do in irc)")
	irc_QueueMsg(irc_params[1], "")
	irc_QueueMsg(irc_params[1], "add player <playername> login <password> (create a password for an irc player to authenticate on irc).")
	irc_QueueMsg(irc_params[1], "bases (list all bases and their regions)")
	irc_QueueMsg(irc_params[1], "check dns player <player> ip <ip> (tell bot to do a dns check on a player)")
	irc_QueueMsg(irc_params[1], "claims (list all players more than 1 placed claim and their total)")
	irc_QueueMsg(irc_params[1], "claims <player> (list each placed claim for a player with coords)")
	irc_QueueMsg(irc_params[1], "date, time, day (display the current game date and time)")
	irc_QueueMsg(irc_params[1], "donors (list donors known to the bot)")
	irc_QueueMsg(irc_params[1], "friends <player name>")
	irc_QueueMsg(irc_params[1], "info <player name> (lots of quick info about a player)")
	irc_QueueMsg(irc_params[1], "inv <player name> (current inventory of player)")
	irc_QueueMsg(irc_params[1], "view alerts (lists the last 20) add a number for more")
	irc_QueueMsg(irc_params[1], "list bad items")
	irc_QueueMsg(irc_params[1], "locations (list)")
	irc_QueueMsg(irc_params[1], "new players")
	irc_QueueMsg(irc_params[1], "pay <amount> to <player> (gift zennies to a player or admin)")	
	irc_QueueMsg(irc_params[1], "permaban <playername>")
	irc_QueueMsg(irc_params[1], "player <player name> friend <player to be friended>")
	irc_QueueMsg(irc_params[1], "player <player name> unfriend <player to be unfriended>")
	irc_QueueMsg(irc_params[1], "player <player name> (info on a specific player)")
	irc_QueueMsg(irc_params[1], "players (master list of all players)")
	irc_QueueMsg(irc_params[1], "prisoners (list)")
	irc_QueueMsg(irc_params[1], "remove permaban <playername>")
	irc_QueueMsg(irc_params[1], "resetzones (list)")
	irc_QueueMsg(irc_params[1], "server stats")
	irc_QueueMsg(irc_params[1], "status <player name>")
	irc_QueueMsg(irc_params[1], "stealth translate <player> (ingame chat from the player will not be translated to irc only)")			
	irc_QueueMsg(irc_params[1], "stop translating <player> (ingame chat from the player will not be translated)")
	irc_QueueMsg(irc_params[1], "teleports (list)")
	irc_QueueMsg(irc_params[1], "translate <player> (ingame chat from the player will be translated ingame)")	
	irc_QueueMsg(irc_params[1], "visits")
	irc_QueueMsg(irc_params[1], "watch player <player>")
	irc_QueueMsg(irc_params[1], "stop watching <player>")
	irc_QueueMsg(irc_params[1], "who (list in-game players)")
	irc_QueueMsg(irc_params[1], "uptime")
	irc_QueueMsg(irc_params[1], "")
	irc_QueueMsg(irc_params[1], "type say <something> to talk to players ingame")
	irc_QueueMsg(irc_params[1], "type pm <playername or id> PM a player ingame")
	irc_QueueMsg(irc_params[1], "type con <server command> (send a command to the server in console")
	irc_QueueMsg(irc_params[1], "")
	return
end


function irc_HelpTopics()
	local id
	id = LookupOfflinePlayer(irc_params[1], "all")
	if (accessLevel(id) > 2) then return end

	irc_QueueMsg(irc_params[1], "Commands by topic:")
	irc_QueueMsg(irc_params[1], "==================")
	irc_QueueMsg(irc_params[1], "help announcements")
	irc_QueueMsg(irc_params[1], "help bad items")
	irc_QueueMsg(irc_params[1], "help commands")
	irc_QueueMsg(irc_params[1], "help custom commands")
	irc_QueueMsg(irc_params[1], "help CSI")
	irc_QueueMsg(irc_params[1], "help donors")
	irc_QueueMsg(irc_params[1], "help motd")
	irc_QueueMsg(irc_params[1], "help server")	
	irc_QueueMsg(irc_params[1], "help shop")
	irc_QueueMsg(irc_params[1], "help watchlist")
	irc_QueueMsg(irc_params[1], "")
end


function irc_HelpServer()
	local id
	id = LookupOfflinePlayer(irc_params[1], "all")
	if (accessLevel(id) > 2) then return end

	irc_QueueMsg(irc_params[1], "Customising the bot and server")
	irc_QueueMsg(irc_params[1], "==============================")
	irc_QueueMsg(irc_params[1], "reset bot (Do after a wipe. BE CAREFUL. This will make the bot forgot things like bases.)")	
	irc_QueueMsg(irc_params[1], "server ip <internet address of server> (to view just type server)")
	irc_QueueMsg(irc_params[1], "set rules <new rules> (to view just type rules)")
	irc_QueueMsg(irc_params[1], "See help motd for setting the message of the day")
	irc_QueueMsg(irc_params[1], "")
end


function irc_HelpCSI()
	local id
	id = LookupOfflinePlayer(irc_params[1], "all")
	if (accessLevel(id) > 2) then return end

	irc_QueueMsg(irc_params[1], "Forensic Investigative Tools")
	irc_QueueMsg(irc_params[1], "============================")
	irc_QueueMsg(irc_params[1], "claims <player> (list each placed claim for a player with coords)")	
	irc_QueueMsg(irc_params[1], "info <player name> (lots of quick info about a player)")
	irc_QueueMsg(irc_params[1], "inv <player name> (current inventory of player)")	
	irc_QueueMsg(irc_params[1], "near <player> range <number> (list bases and players near a player.  Range is optional and defaults to 200 metres.")	
	irc_QueueMsg(irc_params[1], "show inventory (See built in help. Just type show inventory)")
	irc_QueueMsg(irc_params[1], "who visited (See built in help. Just type who visited)")
	irc_QueueMsg(irc_params[1], "view alerts (lists the last 20) add a number for more")
	irc_QueueMsg(irc_params[1], "")
end


function irc_HelpAnnouncements()
	local id
	id = LookupOfflinePlayer(irc_params[1], "all")
	if (accessLevel(id) > 2) then return end

	irc_QueueMsg(irc_params[1], "Announcements Management")
	irc_QueueMsg(irc_params[1], "========================")
	irc_QueueMsg(irc_params[1], "announcements (view a numbered list of the server announcements).")
	irc_QueueMsg(irc_params[1], "add announcement <your message here>")
	irc_QueueMsg(irc_params[1], "delete announcement <number> (from the numbered list given with announcements)")
	irc_QueueMsg(irc_params[1], "")
end


function irc_HelpCustomCommands()
	local id
	id = LookupOfflinePlayer(irc_params[1], "all")
	if (accessLevel(id) > 2) then return end

	irc_QueueMsg(irc_params[1], "Custom Commands")
	irc_QueueMsg(irc_params[1], "===============")
	irc_QueueMsg(irc_params[1], "You can create commands that send a private message.")
	irc_QueueMsg(irc_params[1], "Type custom commands (list them)[-]")
	irc_QueueMsg(irc_params[1], "Type add command <command> level <access level> message <message>.[-]")
	irc_QueueMsg(irc_params[1], "Type remove command <command>.[-]")
	irc_QueueMsg(irc_params[1], "Access level is optional and defaults to 99.[-]")
	irc_QueueMsg(irc_params[1], "See help access for the list of access levels.[-]")
	irc_QueueMsg(irc_params[1], "")
end


function irc_HelpBadItems()
	local id
	id = LookupOfflinePlayer(irc_params[1], "all")
	if (accessLevel(id) > 2) then return end

	irc_QueueMsg(irc_params[1], "Bad Item (uncraftable) Management")
	irc_QueueMsg(irc_params[1], "=================================")
	irc_QueueMsg(irc_params[1], "list bad items")
	irc_QueueMsg(irc_params[1], "add bad item <name of item as given by server>")
	irc_QueueMsg(irc_params[1], "remove bad item <name of item as given by server>")
	irc_QueueMsg(irc_params[1], "")
	irc_QueueMsg(irc_params[1], "Any player caught with an item on this list will be sent to timeout or banned.")
	irc_QueueMsg(irc_params[1], "You can allow a player to have these items (except bedrock and smokestorm) with..")
	irc_QueueMsg(irc_params[1], "exclude <player> (They can have bad items in inventory)")
	irc_QueueMsg(irc_params[1], "include <player> (They may not have bad items on them)")
	irc_QueueMsg(irc_params[1], "")
end


function irc_HelpCommands()
	local id
	id = LookupOfflinePlayer(irc_params[1], "all")
	if (accessLevel(id) > 2) then return end

	irc_QueueMsg(irc_params[1], "Remote server commands:")
	irc_QueueMsg(irc_params[1], "=======================")
	irc_QueueMsg(irc_params[1], "Most ingame commands can be done from IRC by putting cmd infront.  These commands do require a slash.")
	irc_QueueMsg(irc_params[1], "If an ingame command does not support running from IRC you will get 'Unknown command'. For the full list refer to ingame command help.")
	irc_QueueMsg(irc_params[1], "cmd /arrest <playername>")
	irc_QueueMsg(irc_params[1], "cmd /deactivatetp <teleport>")
	irc_QueueMsg(irc_params[1], "cmd /activatetp <teleport>")
	irc_QueueMsg(irc_params[1], "cmd /gimme gimme")
	irc_QueueMsg(irc_params[1], "cmd /gimme off")
	irc_QueueMsg(irc_params[1], "cmd /gimme on")
	irc_QueueMsg(irc_params[1], "cmd /gimme peace")
	irc_QueueMsg(irc_params[1], "cmd /gimme reset")
	irc_QueueMsg(irc_params[1], "cmd /ignoreadmins")
	irc_QueueMsg(irc_params[1], "cmd /includeadmins")
	irc_QueueMsg(irc_params[1], "cmd /killtp <teleport>")
	irc_QueueMsg(irc_params[1], "cmd /owntp <teleport> <playername>")
	irc_QueueMsg(irc_params[1], "cmd /privatetp <teleport>")
	irc_QueueMsg(irc_params[1], "cmd /protect <playername>")
	irc_QueueMsg(irc_params[1], "cmd /publictp <teleport>")
	irc_QueueMsg(irc_params[1], "cmd /release <playername>")
	irc_QueueMsg(irc_params[1], "cmd /reset gimmehell")
	irc_QueueMsg(irc_params[1], "cmd /resettimers <playername>")
	irc_QueueMsg(irc_params[1], "cmd /return <playername>")
	irc_QueueMsg(irc_params[1], "cmd /sendhome <playername>")
	irc_QueueMsg(irc_params[1], "cmd /set base size <size> <playername>")
	irc_QueueMsg(irc_params[1], "cmd /timeout <playername>")
	irc_QueueMsg(irc_params[1], "cmd /unprotect <playername>")
	irc_QueueMsg(irc_params[1], "")
end


function irc_HelpMOTD()
	local id
	id = LookupOfflinePlayer(irc_params[1], "all")
	if (accessLevel(id) > 2) then return end

	irc_QueueMsg(irc_params[1], "Message Of The Day Management")
	irc_QueueMsg(irc_params[1], "=============================")
	irc_QueueMsg(irc_params[1], "motd (view the current message of the day if set).")
	irc_QueueMsg(irc_params[1], "motd clear (or motd delete).")
	irc_QueueMsg(irc_params[1], "set motd followed by anything else sets the message of the day.")
	irc_QueueMsg(irc_params[1], "")
end


function irc_HelpWatchlist()
	local id
	id = LookupOfflinePlayer(irc_params[1], "all")
	if (accessLevel(id) > 2) then return end

	irc_QueueMsg(irc_params[1], "Watchlist Management")
	irc_QueueMsg(irc_params[1], "====================")
	irc_QueueMsg(irc_params[1], "Changes to player inventories can be sent to a channel called #watch")
	irc_QueueMsg(irc_params[1], "New players and watched players are automatically included.")
	irc_QueueMsg(irc_params[1], "To add a player type watch <player>")
	irc_QueueMsg(irc_params[1], "To remove them type stop watching <player>")
	irc_QueueMsg(irc_params[1], "The bot will automatically add players that are detected with certain items in unusual quantities.")
	irc_QueueMsg(irc_params[1], "")
end


function irc_HelpDonors()
	local id
	id = LookupOfflinePlayer(irc_params[1], "all")
	if (accessLevel(id) > 2) then return end

	irc_QueueMsg(irc_params[1], "Donor Management")
	irc_QueueMsg(irc_params[1], "================")
	irc_QueueMsg(irc_params[1], "donors (list donors known to the bot)")
	irc_QueueMsg(irc_params[1], "add donor <player>")
	irc_QueueMsg(irc_params[1], "remove donor <player>")
	irc_QueueMsg(irc_params[1], "")
end


function irc_HelpShop()
	local id
	id = LookupOfflinePlayer(irc_params[1], "all")
	if (accessLevel(id) > 2) then return end

	irc_QueueMsg(irc_params[1], "Shop Management")
	irc_QueueMsg(irc_params[1], "===============")
	irc_QueueMsg(irc_params[1], "shop categories (list categories)")
	irc_QueueMsg(irc_params[1], "shop <category> (list items in a category)")
	irc_QueueMsg(irc_params[1], "shop <item> (list all items that partially match what you type)")
	irc_QueueMsg(irc_params[1], "shop add category <food> code=<code> (1 or more letters only)")
	irc_QueueMsg(irc_params[1], "shop remove category <food>")
	irc_QueueMsg(irc_params[1], "shop change category <old category> <new category>")
	irc_QueueMsg(irc_params[1], "shop add item <item> category=food price=100 stock=50")
	irc_QueueMsg(irc_params[1], "shop remove item <item>")
	irc_QueueMsg(irc_params[1], "shop price <item> <number>")
	irc_QueueMsg(irc_params[1], "shop restock <item> +-<number>")
	irc_QueueMsg(irc_params[1], "shop special <item> <number>")
	irc_QueueMsg(irc_params[1], "shop variation <item> <number>")
	irc_QueueMsg(irc_params[1], "open shop")
	irc_QueueMsg(irc_params[1], "close shop (staff can still access)")
	irc_QueueMsg(irc_params[1], "")
end
