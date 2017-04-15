--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function irc_commands()
	calledFunction = "irc_commands"

	local id
	id = LookupOfflinePlayer(irc_params.name, "all")

	irc_chat(irc_params.name, "Commands that output to IRC:")
	irc_chat(irc_params.name, "============================")

	if (accessLevel(id) > 2) then
		irc_chat(irc_params.name, "help (display this list)")
		irc_chat(irc_params.name, "staff (see who your admins are.  You can also type owners, admins, or mods to just see a partial list)")
		irc_chat(irc_params.name, "day or date or time (show the game date and time)")
		irc_chat(irc_params.name, "say <something> to talk to players ingame")
		irc_chat(irc_params.name, "date, time, day (display the current game date and time)")
		irc_chat(irc_params.name, "locations")
		irc_chat(irc_params.name, "new players (list new players in the last 2 days)")
		irc_chat(irc_params.name, "stop (stop the bot spamming you. If the command you ran has a lot of output, this stops it)")
		irc_chat(irc_params.name, "resetzones")
		irc_chat(irc_params.name, "uptime (server and bot running times)")
		irc_chat(irc_params.name, "who (list in-game players)")
		irc_chat(irc_params.name, "server status (some daily stats)")
		irc_chat(irc_params.name, "shop categories  (list categories)")
		irc_chat(irc_params.name, "shop <category>  (list items in a category)")
		irc_chat(irc_params.name, "shop <item>  (list all items that partially match what you type)")
		irc_chat(irc_params.name, "villages (list)")
		irc_chat(irc_params.name, "villagers (list villages and villagers)")
		irc_chat(name, "")
		return
	end

	irc_chat(irc_params.name, "If your login is not working properly try typing rescue me, hit return then login again.")
	irc_chat(irc_params.name, "")
	irc_chat(irc_params.name, "help (display this list)")
	irc_chat(irc_params.name, "help topics (display help topics only)")
	irc_chat(irc_params.name, "help commands (for ingame commands that you can also do in irc)")
	irc_chat(irc_params.name, "")
	irc_chat(irc_params.name, "invite <player name> (Send the player a code and instructions to join irc and give themselves a password)")
	irc_chat(irc_params.name, "add player <playername> login <password> (create a password for an irc player to authenticate on irc).")
	irc_chat(irc_params.name, "bases (list all bases and their regions)")
	irc_chat(irc_params.name, "check dns player <player> ip <ip> (tell bot to do a dns check on a player)")
	irc_chat(irc_params.name, "claims (list all players more than 1 placed claim and their total)")
	irc_chat(irc_params.name, "claims <player> (list each placed claim for a player with coords)")
	irc_chat(irc_params.name, "date, time, day (display the current game date and time)")
	irc_chat(irc_params.name, "donors (list donors known to the bot)")
	irc_chat(irc_params.name, "friends <player name>")
	irc_chat(irc_params.name, "info <player name> (lots of quick info about a player)")
	irc_chat(irc_params.name, "inv <player name> (current inventory of player)")
	irc_chat(irc_params.name, "view alerts (lists the last 20) add a number for more")
	irc_chat(irc_params.name, "list bad items")
	irc_chat(irc_params.name, "locations (list)")
	irc_chat(irc_params.name, "new players")
	irc_chat(irc_params.name, "pay <player> <amount> (gift " .. server.moneyPlural .. " to a player or admin)")
	irc_chat(irc_params.name, "permaban <playername>")
	irc_chat(irc_params.name, "player <player name> friend <player to be friended>")
	irc_chat(irc_params.name, "player <player name> unfriend <player to be unfriended>")
	irc_chat(irc_params.name, "player <player name> (info on a specific player)")
	irc_chat(irc_params.name, "players (master list of all players)")
	irc_chat(irc_params.name, "prisoners (list)")
	irc_chat(irc_params.name, "remove permaban <playername>")
	irc_chat(irc_params.name, "resetzones (list)")
	irc_chat(irc_params.name, "server stats")
	irc_chat(irc_params.name, "status <player name>")
	irc_chat(irc_params.name, "stealth translate <player> (ingame chat from the player will not be translated to irc only)")
	irc_chat(irc_params.name, "stop translating <player> (ingame chat from the player will not be translated)")
	irc_chat(irc_params.name, "teleports (list)")
	irc_chat(irc_params.name, "translate <player> (ingame chat from the player will be translated ingame)")
	irc_chat(irc_params.name, "watch player <player>")
	irc_chat(irc_params.name, "stop watching <player>")
	irc_chat(irc_params.name, "who (list in-game players)")
	irc_chat(irc_params.name, "uptime")
	irc_chat(irc_params.name, "")
	irc_chat(irc_params.name, "type say <something> to talk to players ingame")
	irc_chat(irc_params.name, "type pm <playername or id> PM a player ingame")
	irc_chat(irc_params.name, "type con <server command> (send a command to the server in console")
	irc_chat(irc_params.name, "")
	irc_chat(irc_params.name, "help <keyword> (adding a new help system.  As it grows, more keywords will be known to it.)")
	irc_chat(irc_params.name, "list help <optional section> (eg. admin, server). Short help, just a list.")
	irc_chat(irc_params.name, "command help <optional section> (eg. admin, server). Longer help with info.")
	irc_chat(irc_params.name, "Commands are divided into sections eg. admin, server, locations etc.")
	irc_chat(irc_params.name, "You can view section specific help using list help or command help for any of the following sections:")
	irc_chat(irc_params.name, "")

	return
end


function irc_HelpTopics()
	local id
	id = LookupOfflinePlayer(irc_params.name, "all")
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Commands by topic:")
	irc_chat(irc_params.name, "==================")
	irc_chat(irc_params.name, "help announcements")
	irc_chat(irc_params.name, "help bad items")
	irc_chat(irc_params.name, "help commands")
	irc_chat(irc_params.name, "help custom commands")
	irc_chat(irc_params.name, "help CSI")
	irc_chat(irc_params.name, "help donors")
	irc_chat(irc_params.name, "help motd")
	irc_chat(irc_params.name, "help prefab (or coppi)")	
	irc_chat(irc_params.name, "help server")
	irc_chat(irc_params.name, "help shop")
	irc_chat(irc_params.name, "help watchlist")
	irc_chat(irc_params.name, "")
end


function irc_HelpServer()
	local id
	id = LookupOfflinePlayer(irc_params.name, "all")
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Customising the bot and server")
	irc_chat(irc_params.name, "==============================")
	irc_chat(irc_params.name, "reset bot (Do after a wipe. BE CAREFUL. This will make the bot forgot things like bases.)")
	irc_chat(irc_params.name, "server ip <internet address of server> (to view just type server)")
	irc_chat(irc_params.name, "server ip:port pass <telnet password> (point the bot to a new 7 Days server)")
	irc_chat(irc_params.name, "set irc server ip:port (point the bot to a new irc server).")	
	irc_chat(irc_params.name, "set rules <new rules> (to view just type rules)")
	irc_chat(irc_params.name, "See help motd for setting the message of the day")
	irc_chat(irc_params.name, "")
end


function irc_HelpCSI()
	local id
	id = LookupOfflinePlayer(irc_params.name, "all")
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Forensic Investigative Tools")
	irc_chat(irc_params.name, "============================")
	irc_chat(irc_params.name, "claims <player> (list each placed claim for a player with coords)")
	irc_chat(irc_params.name, "info <player name> (lots of quick info about a player)")
	irc_chat(irc_params.name, "inv <player name> (current inventory of player)")
	irc_chat(irc_params.name, "near <player> range <number> (list bases and players near a player.  Range is optional and defaults to 200 metres.")
	irc_chat(irc_params.name, "show inventory (See built in help. Just type show inventory)")
	irc_chat(irc_params.name, "who visited (See built in help. Just type who visited)")
	irc_chat(irc_params.name, "view alerts (lists the last 20) add a number for more")
	irc_chat(irc_params.name, "")
end


function irc_HelpAnnouncements()
	local id
	id = LookupOfflinePlayer(irc_params.name, "all")
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Announcements Management")
	irc_chat(irc_params.name, "========================")
	irc_chat(irc_params.name, "announcements (view a numbered list of the server announcements).")
	irc_chat(irc_params.name, "add announcement <your message here>")
	irc_chat(irc_params.name, "delete announcement <number> (from the numbered list given with announcements)")
	irc_chat(irc_params.name, "")
end


function irc_HelpCustomCommands()
	local id
	id = LookupOfflinePlayer(irc_params.name, "all")
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Custom Commands")
	irc_chat(irc_params.name, "===============")
	irc_chat(irc_params.name, "You can create commands that send a private message.")
	irc_chat(irc_params.name, "Type custom commands (list them)[-]")
	irc_chat(irc_params.name, "Type add command <command> level <access level> message <message>.[-]")
	irc_chat(irc_params.name, "Type remove command <command>.[-]")
	irc_chat(irc_params.name, "Access level is optional and defaults to 99.[-]")
	irc_chat(irc_params.name, "See help access for the list of access levels.[-]")
	irc_chat(irc_params.name, "")
end


function irc_HelpBadItems()
	local id
	id = LookupOfflinePlayer(irc_params.name, "all")
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Bad Item (uncraftable) Management")
	irc_chat(irc_params.name, "=================================")
	irc_chat(irc_params.name, "list bad items")
	irc_chat(irc_params.name, "add bad item <name of item as given by server>")
	irc_chat(irc_params.name, "remove bad item <name of item as given by server>")
	irc_chat(irc_params.name, "")
	irc_chat(irc_params.name, "Any player caught with an item on this list will be sent to timeout or banned.")
	irc_chat(irc_params.name, "You can allow a player to have these items (except bedrock and smokestorm) with..")
	irc_chat(irc_params.name, "exclude <player> (They can have bad items in inventory)")
	irc_chat(irc_params.name, "include <player> (They may not have bad items on them)")
	irc_chat(irc_params.name, "")
end


function irc_HelpCommands()
	local id
	id = LookupOfflinePlayer(irc_params.name, "all")
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Remote server commands:")
	irc_chat(irc_params.name, "=======================")
	irc_chat(irc_params.name, "Most ingame commands can be done from IRC by putting cmd infront.  These commands do require a slash.")
	irc_chat(irc_params.name, "If an ingame command does not support running from IRC you will get 'Unknown command'.")
	irc_chat(irc_params.name, "For the full list type list help or for detailed help type command help. If you know the section you want add that eg list help server.")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "arrest <playername>")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "release <playername>")	
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "gimme gimme")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "gimme off")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "gimme on")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "gimme peace")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "gimme reset")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "reset gimmehell")	
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "exclude admins")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "include admins")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "tele <teleport> enable")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "tele <teleport> disable")	
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "tele <teleport> delete")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "tele <teleport> owner <playername>")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "tele <teleport> private")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "tele <teleport> public")	
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "set base size <size> <playername>")	
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "protect <playername>")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "unprotect <playername>")	
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "resettimers <playername>")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "sendhome <playername>")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "timeout <playername>")
	irc_chat(irc_params.name, "cmd " .. server.commandPrefix .. "return <playername>")	
	irc_chat(irc_params.name, "")
end


function irc_HelpMOTD()
	local id
	id = LookupOfflinePlayer(irc_params.name, "all")
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Message Of The Day Management")
	irc_chat(irc_params.name, "=============================")
	irc_chat(irc_params.name, "motd (view the current message of the day if set).")
	irc_chat(irc_params.name, "motd clear (or motd delete).")
	irc_chat(irc_params.name, "set motd followed by anything else sets the message of the day.")
	irc_chat(irc_params.name, "")
end


function irc_HelpWatchlist()
	local id
	id = LookupOfflinePlayer(irc_params.name, "all")
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Watchlist Management")
	irc_chat(irc_params.name, "====================")
	irc_chat(irc_params.name, "Changes to player inventories can be sent to a channel called #watch")
	irc_chat(irc_params.name, "New players and watched players are automatically included.")
	irc_chat(irc_params.name, "To add a player type watch <player>")
	irc_chat(irc_params.name, "To remove them type stop watching <player>")
	irc_chat(irc_params.name, "The bot will automatically add players that are detected with certain items in unusual quantities.")
	irc_chat(irc_params.name, "")
end


function irc_HelpDonors()
	local id
	id = LookupOfflinePlayer(irc_params.name, "all")
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Donor Management")
	irc_chat(irc_params.name, "================")
	irc_chat(irc_params.name, "donors (list donors known to the bot)")
	irc_chat(irc_params.name, "add donor <player>")
	irc_chat(irc_params.name, "remove donor <player>")
	irc_chat(irc_params.name, "")
end


function irc_HelpShop()
	local id
	id = LookupOfflinePlayer(irc_params.name, "all")
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Shop Management")
	irc_chat(irc_params.name, "===============")
	irc_chat(irc_params.name, "shop categories (list categories)")
	irc_chat(irc_params.name, "shop <category> (list items in a category)")
	irc_chat(irc_params.name, "shop <item> (list all items that partially match what you type)")
	irc_chat(irc_params.name, "shop add category <food> code=<code> (1 or more letters only)")
	irc_chat(irc_params.name, "shop remove category <food>")
	irc_chat(irc_params.name, "shop change category <old category> <new category>")
	irc_chat(irc_params.name, "shop add item <item> category=food price=100 stock=50")
	irc_chat(irc_params.name, "shop remove item <item>")
	irc_chat(irc_params.name, "shop price <item> <number>")
	irc_chat(irc_params.name, "shop restock <item> +-<number>")
	irc_chat(irc_params.name, "shop special <item> <number>")
	irc_chat(irc_params.name, "shop variation <item> <number>")
	irc_chat(irc_params.name, "open shop")
	irc_chat(irc_params.name, "close shop (staff can still access)")
	irc_chat(irc_params.name, "")
end
