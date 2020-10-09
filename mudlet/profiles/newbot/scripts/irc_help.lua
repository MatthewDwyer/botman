--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function irc_HelpAccess()
	irc_chat(irc_params.name, "Access Levels:")
	irc_chat(irc_params.name, "==============")
	irc_chat(irc_params.name, "Access levels control who can do what.  Commands that are above a players level return unknown command.")
	irc_chat(irc_params.name, "Level 0 server owners")
	irc_chat(irc_params.name, "Level 1 admins")
	irc_chat(irc_params.name, "Level 2 mods")
	irc_chat(irc_params.name, "Level 10 Donors")
	irc_chat(irc_params.name, "Level 90 Regular players")
	irc_chat(irc_params.name, "Level 99 New players")
	irc_chat(irc_params.name, ".")

	return
end


function irc_commands()
	calledFunction = "irc_commands"

	local id
	id = LookupIRCAlias(irc_params.name)

	-- help visible to all
	irc_chat(irc_params.name, "Commands that output to IRC:")
	irc_chat(irc_params.name, "============================")

	irc_chat(irc_params.name, "help (display this list)")
	irc_chat(irc_params.name, "help manual (New to the bot and IRC?  Read this.)")
	irc_chat(irc_params.name, "help setup (Stuff to do when the bot is new.)")
	irc_chat(irc_params.name, "help irc (View a different list of IRC command help including ingame commands that refer to IRC.)")

	irc_chat(irc_params.name, "fps (display current server performance metrics)")
	irc_chat(irc_params.name, "say {something} to talk to players ingame")
	irc_chat(irc_params.name, "staff (see who your admins are.  You can also type owners, admins, or mods to just see a partial list)")
	irc_chat(irc_params.name, "server (server ip and port and number of players)")
	irc_chat(irc_params.name, "stop (stop the bot spamming you. If the command you ran has a lot of output, this stops it)")
	irc_chat(irc_params.name, "uptime (server and bot running times)")
	irc_chat(irc_params.name, "who (list in-game players)")
	irc_chat(irc_params.name, ".")
	irc_chat(irc_params.name, "Misc commands:")
	irc_chat(irc_params.name, "day, date or time (show the game date and time)")
	irc_chat(irc_params.name, "locations")
	irc_chat(irc_params.name, "new players (list new players in the last 2 days)")
	irc_chat(irc_params.name, "server status (some daily stats)")
	irc_chat(irc_params.name, "shop categories  (list categories)")
	irc_chat(irc_params.name, "shop {category}  (list items in a category)")
	irc_chat(irc_params.name, "shop {item}  (list all items that partially match what you type)")
	irc_chat(irc_params.name, "villages (list)")
	irc_chat(irc_params.name, ".")

	if (accessLevel(id) > 2) then
		return
	end

	-- admin restricted help
	irc_chat(irc_params.name, "If your login is not working properly try typing rescue me, hit return then login again.")
	irc_chat(irc_params.name, ".")
	irc_chat(irc_params.name, "help topics (display help topics only)")
	irc_chat(irc_params.name, "help commands (for ingame commands that you can also do in irc)")
	irc_chat(irc_params.name, ".")
	irc_chat(irc_params.name, "invite {player name} (Send the player a code and instructions to join irc and give themselves a password)")
	irc_chat(irc_params.name, "add player {playername} login {password} (create a password for an irc player to authenticate on irc).")
	irc_chat(irc_params.name, "bases (list all bases and their regions)")
	irc_chat(irc_params.name, "check dns player {player name} ip {ip} (tell bot to do a dns check on a player)")
	irc_chat(irc_params.name, "claims (list all players more than 1 placed claim and their total)")
	irc_chat(irc_params.name, "claims {player name} (list each placed claim for a player with coords)")
	irc_chat(irc_params.name, "date, time, day (display the current game date and time)")
	irc_chat(irc_params.name, "donors (list donors known to the bot)")
	irc_chat(irc_params.name, "friends {player name}")
	irc_chat(irc_params.name, "info {player name} (lots of quick info about a player)")
	irc_chat(irc_params.name, "inv {player name} (current inventory of player)")
	irc_chat(irc_params.name, "mute irc {player name} (prevent someone from using say and most other irc bot commands)")
	irc_chat(irc_params.name, "unmute irc {player name} (prevent someone from using say and most other irc bot commands)")
	irc_chat(irc_params.name, "list bad items")
	irc_chat(irc_params.name, "locations (list)")
	irc_chat(irc_params.name, "new players")
	irc_chat(irc_params.name, "pay {player name} {amount} (gift " .. server.moneyPlural .. " to a player or admin)")
	irc_chat(irc_params.name, "permaban {playername}")
	irc_chat(irc_params.name, "player {player name} friend {player to be friended}")
	irc_chat(irc_params.name, "player {player name} unfriend {player to be unfriended}")
	irc_chat(irc_params.name, "player {player name} (info on a specific player)")
	irc_chat(irc_params.name, "players (master list of all players)")
	irc_chat(irc_params.name, "prisoners (list)")
	irc_chat(irc_params.name, "remove permaban {playername}")
	irc_chat(irc_params.name, "resetzones (list)")
	irc_chat(irc_params.name, "server stats")
	irc_chat(irc_params.name, "status {player name}")
	irc_chat(irc_params.name, "stealth translate {player name} (ingame chat from the player will not be translated to irc only)")
	irc_chat(irc_params.name, "stop translating {player name} (ingame chat from the player will not be translated)")
	irc_chat(irc_params.name, "stop watching {player name}")
	irc_chat(irc_params.name, "teleports (list)")
	irc_chat(irc_params.name, "translate {player name} (ingame chat from the player will be translated ingame)")
	irc_chat(irc_params.name, "view alerts (lists the last 20) add a number for more")
	irc_chat(irc_params.name, "villagers (list villages and villagers)")
	irc_chat(irc_params.name, "watch player {player name}")
	irc_chat(irc_params.name, "who (list in-game players)")
	irc_chat(irc_params.name, "uptime")
	irc_chat(irc_params.name, ".")
	irc_chat(irc_params.name, "type say {something} to talk to players ingame")
	irc_chat(irc_params.name, "type pm {playername or id} PM a player ingame")
	irc_chat(irc_params.name, "type con {server command} (send a command to the server in console")
	irc_chat(irc_params.name, ".")
	irc_chat(irc_params.name, "help {keyword} (adding a new help system.  As it grows, more keywords will be known to it.)")
	irc_chat(irc_params.name, "list help {optional section} (eg. admin, server). Short help, just a list.")
	irc_chat(irc_params.name, "command help {optional section} (eg. admin, server). Longer help with info.")
	irc_chat(irc_params.name, "Commands are divided into sections eg. admin, server, locations etc.")
	irc_chat(irc_params.name, ".")

	return
end


function irc_Manual()
	local id
	id = LookupIRCAlias(irc_params.name)

	irc_chat(irc_params.name, string.format("Hi %s! Here is a quick guide on getting started with your bot on IRC.", irc_params.name))
	irc_chat(irc_params.name, ".")
	irc_chat(irc_params.name, "If you have just arrived and you are using the web clients, Shout or The Lounge, you will love them :)")
	irc_chat(irc_params.name, "The web client connects to the IRC server 24/7 and caches the channels.  You can connect from any number of devices with internet access and a browser.")
	irc_chat(irc_params.name, "Anything you do is instantly available on all of your connected devices since they're all the same login.")
	irc_chat(irc_params.name, "To read stuff that happened while you were offline, simply scroll up and click a button that will appear if you need to go further back.")
	irc_chat(irc_params.name, string.format("You will see some channels listed down the left side %s, %s and %s and %s which has no #", server.ircMain, server.ircAlerts, server.ircWatch, server.ircBotName))
	irc_chat(irc_params.name, string.format("%s is the main channel where you will see game chat and various events and bot messages.", server.ircMain))
	irc_chat(irc_params.name, string.format("The %s channel lists events such as new players, deaths, pvp's, hackers and more.", server.ircAlerts))
	irc_chat(irc_params.name, string.format("The %s channel lists live inventory for new and watched players.  Players aren't watched forever.", server.ircWatch))
	irc_chat(irc_params.name, string.format("The %s channel (this one) is a private chat between you and the bot *waves*", server.ircBotName))
	irc_chat(irc_params.name, "Below the channels you will see 3 icons.  If you are hearing funny pop noises, you may need to turn off sound notifications.")
	irc_chat(irc_params.name, "Click on the icon that looks like a cog.  This is the preferences screen.  Look for and untick Enable notification sound.")
	irc_chat(irc_params.name, string.format("To return to these instructions click on %s)", server.ircBotName))
	irc_chat(irc_params.name, ".")
	irc_chat(irc_params.name, "There are many commands and you can explore the help to read about them. Depending on your level (admin or player), you usually only see help for stuff you can do.  If you aren't supposed to use a command, it simply won't work for you.")
	irc_chat(irc_params.name, "At any time if you need to stop the bot spamming you on IRC just type stop")
	irc_chat(irc_params.name, "On IRC, bot commands are just typed.  There is no leading character like there is in-game.")
	irc_chat(irc_params.name, "Here are some commonly used commands that everyone can do:")
	irc_chat(irc_params.name, "help, server, who, fps, uptime, staff, say (requires login)")
	irc_chat(irc_params.name, ".")

	-- staff only
	if (accessLevel(id) > 2) then
		irc_chat(irc_params.name, "For further assistance, please read help or talk to your admins.")
		irc_chat(irc_params.name, ".")
		return
	end

	if not players[id].ircAuthenticated then
		irc_chat(irc_params.name, "You are currently not logged in to the bot and you won't have access to admin commands until you login.")
		irc_chat(irc_params.name, "If you don't yet have a login or you've lost it >.< Type bow before me.  This will only work if your IRC nick matches your steam name or you've been logged in before.")
		irc_chat(irc_params.name, "If you typed bow before me, you should have been told by the bot that you have logged in.  You can do admin commands, but if you want, you can also set yourself a bot login using a user and pass.")
		irc_chat(irc_params.name, string.format("To do that type new login %s pass somepassword", id))
		irc_chat(irc_params.name, ".")
	else
		irc_chat(irc_params.name, "As an admin, you have a lot more help available to you with the help command.  The best thing to do is explore.")
		irc_chat(irc_params.name, "To talk to players in your server type say followed by what you want said in-game.  You can also pm players eg. pm joe You're on fire!")

		if (accessLevel(id) == 0) then
			irc_chat(irc_params.name, "As server owner, you have access to server console commands from IRC.")
			irc_chat(irc_params.name, "To do a console command type con followed by the console command.  eg. con help ban.")
			irc_chat(irc_params.name, "Your bot requires the latest version of Allocs mod, though it may work with older versions.")
			irc_chat(irc_params.name, "It also supports the BC mod and the Botman mod, which it uses for many great features such as digging, spawning prefabs and detecting flying/clipping players.")
			irc_chat(irc_params.name, "If you don't have the mods, you can find them online or grab them from here https://botman.nz/download")
			irc_chat(irc_params.name, "Many game hosts block uploading dll files.  If yours does that, send them a support ticket with the url above and request that they install the Mods folder in the zip.")
		end

		irc_chat(irc_params.name, ".")
		irc_chat(irc_params.name, string.format("You can do many ingame commands from IRC. eg. cmd %suptime.  Note that you need cmd and the bot command needs the normal command prefix.", server.commandPrefix))
		irc_chat(irc_params.name, "There are several help topics available.  Type help topics.")
		irc_chat(irc_params.name, "The bot also knows many keywords and you can do more specific help commands eg. help ban.  For a list of the help sections just type help.  They list at the end as single words.  To view one type help followed by the word eg. help botman")
		irc_chat(irc_params.name, "You can also view the complete help in two ways (warning its LONG).  Type list help, or type command help (it includes short descriptions).. then go watch a movie or something.")

		irc_chat(irc_params.name, ".")
		irc_chat(irc_params.name, "You can make a bot login for another player by typing add player Joe login Joe pass password")
		irc_chat(irc_params.name, "You can send players IRC invites by typing invite joe.  You will need to have previously told the bot your IRC server's IP and port or Joe will see 0.0.0.0 instead.")
		irc_chat(irc_params.name, ".")
		irc_chat(irc_params.name, "I hope this guide is useful to you.  There are over 1,000 commands but you'll only use around 20 routinely.  If you get stuck, you can send me a message on Steam, Discord or an email to smegzor@gmail.com")
		irc_chat(irc_params.name, "My Steam friends list is always full and Discord is better because it doesn't forget chat histories.  On Discord I am smegzor#9806.  On Steam I am Smegz0r.")
		irc_chat(irc_params.name, ".")
		irc_chat(irc_params.name, "Enjoy your new bot and have lots of fun making your server #1! xD")
		irc_chat(irc_params.name, ".")
		irc_chat(irc_params.name, "           Smegz0r")
		irc_chat(irc_params.name, ".")
	end
end


function irc_Setup()
	-- TODO:  Finish this
	local id
	id = LookupIRCAlias(irc_params.name)

	irc_chat(irc_params.name, "When running the bot for the first time, there are several setup tasks to do and some mod requirements.")
	irc_chat(irc_params.name, "The bot requires Alloc's mod to function. Many very nice extra features require either the BC mod or the Botman mod.")
	irc_chat(irc_params.name, "You can grab them directly from their authors or from here https://botman.nz/download")
	irc_chat(irc_params.name, "If updating an installed mod, you will need to stop your server first.  If it is a new mod, you only need to restart afterwards.")
	irc_chat(irc_params.name, "You may need to create the Mods folder first.  It lives in the main folder that contains all of your server files and folders.  If you can see 7daystodie_data you are in the right folder.")
	irc_chat(irc_params.name, "Copy each mod directly into the Mods folder.  You should not end up with a folder called Mods inside your Mods folder.")
	irc_chat(irc_params.name, ".")
	irc_chat(irc_params.name, "With the mods sorted, it is time to command your bot.  You can do most commands right here.  If it is necessary to join your server to issue a command there, I will say so.")
	irc_chat(irc_params.name, "Note that when I ask you to type something, I expect you to type everything that follows from the word type. I will write comments in ().  Do not type those.")
	irc_chat(irc_params.name, "Type cmd /blacklist action ban   (the bot will ban players coming from countries in your country blacklist.)")
	irc_chat(irc_params.name, "To view the country blacklist type cmd /list blacklist")
	irc_chat(irc_params.name, ".")
end


function irc_HelpTopics()
	local id
	id = LookupIRCAlias(irc_params.name)
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
	irc_chat(irc_params.name, "help prefab (or botman)")
	irc_chat(irc_params.name, "help server")
	irc_chat(irc_params.name, "help shop")
	irc_chat(irc_params.name, "help watchlist")
	irc_chat(irc_params.name, ".")
end


function irc_HelpServer()
	local id
	id = LookupIRCAlias(irc_params.name)
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Customising the bot and server")
	irc_chat(irc_params.name, "==============================")
	irc_chat(irc_params.name, "reset bot (Do after a wipe. BE CAREFUL. This will make the bot forget map specific things like locations and bases.)")
	irc_chat(irc_params.name, "server ip {internet address of server} (to view just type server)")
	irc_chat(irc_params.name, "server ip:port pass {telnet password} (point the bot to a new 7 Days server)")
	irc_chat(irc_params.name, "set irc server ip:port (point the bot to a new irc server).")
	irc_chat(irc_params.name, "set rules {new rules} (to view just type rules)")
	irc_chat(irc_params.name, "See help motd for setting the message of the day")
	irc_chat(irc_params.name, ".")
end


function irc_HelpCSI()
	local id
	id = LookupIRCAlias(irc_params.name)
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Forensic Investigative Tools")
	irc_chat(irc_params.name, "============================")
	irc_chat(irc_params.name, "claims {player name} (list each placed claim for a player with coords)")
	irc_chat(irc_params.name, "info {player name} (lots of quick info about a player)")
	irc_chat(irc_params.name, "inv {player name} (current inventory of player)")
	irc_chat(irc_params.name, "near {player name} range {number} (list bases and players near a player.  Range is optional and defaults to 200 metres.")
	irc_chat(irc_params.name, "show inventory (See built in help. Just type show inventory)")
	irc_chat(irc_params.name, "who visited (See built in help. Just type who visited)")
	irc_chat(irc_params.name, "view alerts (lists the last 20) add a number for more")
	irc_chat(irc_params.name, ".")
end


function irc_HelpAnnouncements()
	local id
	id = LookupIRCAlias(irc_params.name)
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Announcements Management")
	irc_chat(irc_params.name, "========================")
	irc_chat(irc_params.name, "announcements (view a numbered list of the server announcements).")
	irc_chat(irc_params.name, "add announcement {your message here}")
	irc_chat(irc_params.name, "delete announcement {number} (from the numbered list given with announcements)")
	irc_chat(irc_params.name, "set rolling delay 10 (The next rolling announcement will happen every 10 minutes)")
	irc_chat(irc_params.name, ".")
end


function irc_HelpCustomCommands()
	local id
	id = LookupIRCAlias(irc_params.name)
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Custom Commands")
	irc_chat(irc_params.name, "===============")
	irc_chat(irc_params.name, "You can create commands that send a private message.")
	irc_chat(irc_params.name, "Type custom commands (list them)")
	irc_chat(irc_params.name, "Type add command {command} level {access level} message {message}.")
	irc_chat(irc_params.name, "Type remove command {command}.")
	irc_chat(irc_params.name, "Access level is optional and defaults to 99.")
	irc_chat(irc_params.name, "See help access for the list of access levels.")
	irc_chat(irc_params.name, ".")
end


function irc_HelpBadItems()
	local id
	id = LookupIRCAlias(irc_params.name)
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Bad Item (uncraftable) Management")
	irc_chat(irc_params.name, "=================================")
	irc_chat(irc_params.name, "list bad items")
	irc_chat(irc_params.name, "add bad item {name of item as given by server}")
	irc_chat(irc_params.name, "remove bad item {name of item as given by server}")
	irc_chat(irc_params.name, ".")
	irc_chat(irc_params.name, "Any player caught with an item on this list will be sent to timeout or banned.")
	irc_chat(irc_params.name, "You can allow a player to have these items (except bedrock and smokestorm) with..")
	irc_chat(irc_params.name, "exclude {player name} (They can have bad items in inventory)")
	irc_chat(irc_params.name, "include {player name} (They may not have bad items on them)")
	irc_chat(irc_params.name, ".")
end


function irc_HelpCommands()
	local id
	id = LookupIRCAlias(irc_params.name)
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Remote server commands:")
	irc_chat(irc_params.name, "=======================")
	irc_chat(irc_params.name, "Most ingame commands can be done from IRC by putting cmd infront.  These commands do require a slash.")
	irc_chat(irc_params.name, "If an ingame command does not support running from IRC you will get 'Unknown command'.")
	irc_chat(irc_params.name, "For the full list type list help or for detailed help type command help. If you know the section you want add that eg list help server.")
	irc_chat(irc_params.name, "cmd {#}arrest {playername}")
	irc_chat(irc_params.name, "cmd {#}release {playername}")
	irc_chat(irc_params.name, "cmd {#}gimme gimme")
	irc_chat(irc_params.name, "cmd {#}gimme off")
	irc_chat(irc_params.name, "cmd {#}gimme on")
	irc_chat(irc_params.name, "cmd {#}gimme peace")
	irc_chat(irc_params.name, "cmd {#}gimme reset")
	irc_chat(irc_params.name, "cmd {#}reset gimmearena")
	irc_chat(irc_params.name, "cmd {#}exclude admins")
	irc_chat(irc_params.name, "cmd {#}include admins")
	irc_chat(irc_params.name, "cmd {#}tele {teleport} enable")
	irc_chat(irc_params.name, "cmd {#}tele {teleport} disable")
	irc_chat(irc_params.name, "cmd {#}tele {teleport} delete")
	irc_chat(irc_params.name, "cmd {#}tele {teleport} owner {playername}")
	irc_chat(irc_params.name, "cmd {#}tele {teleport} private")
	irc_chat(irc_params.name, "cmd {#}tele {teleport} public")
	irc_chat(irc_params.name, "cmd {#}set base size {size} {playername}")
	irc_chat(irc_params.name, "cmd {#}protect {playername}")
	irc_chat(irc_params.name, "cmd {#}unprotect {playername}")
	irc_chat(irc_params.name, "cmd {#}resettimers {playername}")
	irc_chat(irc_params.name, "cmd {#}sendhome {playername}")
	irc_chat(irc_params.name, "cmd {#}timeout {playername}")
	irc_chat(irc_params.name, "cmd {#}return {playername}")
	irc_chat(irc_params.name, ".")
end


function irc_HelpMOTD()
	local id
	id = LookupIRCAlias(irc_params.name)
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Message Of The Day Management")
	irc_chat(irc_params.name, "=============================")
	irc_chat(irc_params.name, "motd (view the current message of the day if set).")
	irc_chat(irc_params.name, "motd clear (or motd delete).")
	irc_chat(irc_params.name, "set motd followed by anything else sets the message of the day.")
	irc_chat(irc_params.name, ".")
end


function irc_HelpWatchlist()
	local id
	id = LookupIRCAlias(irc_params.name)
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Watchlist Management")
	irc_chat(irc_params.name, "====================")
	irc_chat(irc_params.name, "Changes to player inventories can be sent to a channel called #watch")
	irc_chat(irc_params.name, "New players and watched players are automatically included.")
	irc_chat(irc_params.name, "To add a player type watch {player name}")
	irc_chat(irc_params.name, "To remove them type stop watching {player name}")
	irc_chat(irc_params.name, "The bot will automatically add players that are detected with certain items in unusual quantities.")
	irc_chat(irc_params.name, ".")
end


function irc_HelpDonors()
	local id
	id = LookupIRCAlias(irc_params.name)
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Donor Management")
	irc_chat(irc_params.name, "================")
	irc_chat(irc_params.name, "donors (list donors known to the bot)")
	irc_chat(irc_params.name, "add donor {player name}")
	irc_chat(irc_params.name, "remove donor {player name}")
	irc_chat(irc_params.name, ".")
end


function irc_HelpShop()
	local id
	id = LookupIRCAlias(irc_params.name)
	if (accessLevel(id) > 2) then return end

	irc_chat(irc_params.name, "Shop Manglement")
	irc_chat(irc_params.name, "===============")
	irc_chat(irc_params.name, "empty shop (Everything must go! Deletes everything except the misc category which is a catchall)")
	irc_chat(irc_params.name, "shop categories (list categories)")
	irc_chat(irc_params.name, "shop {category} (list items in a category)")
	irc_chat(irc_params.name, "shop {item} (list all items that partially match what you type)")
	irc_chat(irc_params.name, "shop add category {food} code {code} (1 or more letters only)")
	irc_chat(irc_params.name, "shop remove category {food}")
	irc_chat(irc_params.name, "shop change category {old category} {new category}")
	irc_chat(irc_params.name, "shop add item {item} category {a category} price {number} stock {number} units {number} quality {0-6 or custom quality number}")
	irc_chat(irc_params.name, "shop remove item {item}")
	irc_chat(irc_params.name, "shop price {item} {number}")
	irc_chat(irc_params.name, "shop quality {item} {number}")
	irc_chat(irc_params.name, "shop units {item} {number}")
	irc_chat(irc_params.name, "shop restock {item} +-{number}")
	irc_chat(irc_params.name, "shop special {item} {number}")
	irc_chat(irc_params.name, "shop variation {item} {number}")
	irc_chat(irc_params.name, "open shop")
	irc_chat(irc_params.name, "close shop (staff can still access)")
	irc_chat(irc_params.name, ".")
end
