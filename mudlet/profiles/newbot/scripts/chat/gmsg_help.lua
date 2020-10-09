--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function dbHelp(search)
	local cursor, errorString, row

	if search == nil or search == "" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Search word or phrase required.[-]")
		return
	end

	-- experimental command help using the database
	cursor,errorString = conn:execute("SELECT * FROM helpCommands WHERE keywords like '%" .. search .."%'")
	rows = cursor:numrows()
	row = cursor:fetch({}, "a")

	while row do
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.command .. "[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.description .. "[-]")

		row = cursor:fetch(row, "a")
	end
end


function commandHelp(command)
	local list

	if (command == "me") then
		r = randSQL(6)
		if (r==1) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry you're beyond help I'm afraid.[-]") end
		if (r==2) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Today I did 6 impossible things, but that ain't one.[-]") end
		if (r==3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I can't fix that![-]") end
		if (r==4) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Ask your cat.[-]") end
		if (r==5) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You need a wash and a haircut.[-]") end
		if (r==6) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Get up and go Outside.  Maybe you've heard of it?[-]") end
		return
	end


	if command == "reboot" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]By default " .. server.commandPrefix .. "reboot will reboot 2 minutes later. More detailed help on irc.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "reboot in n minutes/hours (restricted to server owners)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "cancel reboot[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "pause reboot  " .. server.commandPrefix .. "unpause reboot[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "enable (or " .. server.commandPrefix .. "disable) reboot (toggle automated rebooting)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A timed reboot can be delayed if anyone says wait during the countdown. This can be blocked if you add 'forced' to the reboot command.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Several automatic reboots can happen that I manage.[-]")
		return
	end


	if command == "mail" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Send private messages to your friends. They have to have friended you with " .. server.commandPrefix .. "friend " .. players[chatvars.playerid].name .. " before you can message them.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can only send mail from your console, which you access from the tild key which is above TAB and left of your 1 key.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To send a message to your friend Dave type pm @dave Hi Dave!  If he is on, he will get it now.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can message the admins with pm @admin {your message here}.  Every admin will see it.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Ignore the command denied response from the server.[-]")
		message("pm " .. chatvars.playerid .. "")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "list mail (see a numbered list of all your messages)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "read mail {optional number} (reads all unread by default)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "save mail {number} (read mail is deleted unless saved)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "delete mail {number} (delete the numbered message)[-]")
		return
	end


	if (command == "bookmarks") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This feature is just to help admins locate places of interest or so we can screenshot your base before a wipe.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If you add too many or stupid bookmarks we will not use them.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]These are not teleports like waypoints.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "][-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "bookmark {short description} (add a bookmark where you are standing)[-]")

		if (chatvars.accessLevel < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "list bookmarks {player name} (view a players bookmarks)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "bk {bookmark number} (tp to the coords of a bookmark)[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "list bookmarks (view your own bookmarks)[-]")
		end

		return
	end


	if (command == "male") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]HELLOOOOO nurse![-]")
		return
	end


	if command == "shop" then
		list = ""
		for k, v in pairs(shopCategories) do
			if k ~= "misc" then
				list = list .. k .. ",  "
			end
		end
		list = string.sub(list, 1, string.len(list) - 3)

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The game currency is the " .. server.moneyName .. ". Each zombie killed earns you 5 " .. server.moneyPlural .. ".[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "cash (see what you have in the bank)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To browse type " .. server.commandPrefix .. "shop followed by a category. Categories are..[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. list .. "[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]For a general search type " .. server.commandPrefix .. "shop {item} eg. " .. server.commandPrefix .. "shop shirt[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "buy {item number} {quantity}  Buy all the things![-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "pay {player name} {amount}  You can't put a price on love so send money instead.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "gamble (gamble in our daily lottery) " .. server.lotteryTicketPrice .. " " .. server.moneyPlural .. " per ticket[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Buy multiple tickets at once with " .. server.commandPrefix .. "gamble 5 (or any number). The winning number is picked from ticket number 1 to 100.[-]")
		if (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "open shop - allow players access to the shop.[-]") end
		if (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "close shop - block player access to the shop.[-]") end
		if (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set shop open - set a time (0 - 23) when the shop opens.[-]") end
		if (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set shop close - set a time (0 - 23) when the shop closes.[-]") end
		if (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set shop location {location} - tie the shop to a location.[-]") end
		if (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "clear shop location - the shop can be used anywhere.[-]") end
		return
	end


	if command == "waypoints" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are personal teleports that you can set and share with friends.[-]")

		if server.waypointsPublic then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can set up to " .. players[chatvars.playerid].maxWaypoints .. " waypoints.[-]")
		else
			if chatvars.accessLevel > 10 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are available to donors and admins only.[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can set up to " .. players[chatvars.playerid].maxWaypoints .. " waypoints.[-]")
			end
		end

		if chatvars.accessLevel < 3 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set max waypoints {number} (default 2).[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set max waypoints donors {number}.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set max waypoints {player name} number {number}.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set waypoint create cost {number} (default 0).[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set waypoint cost {number}. (Cost to use, default 0)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set waypoint cooldown {number}. (Timer in seconds between uses, default 0)[-]")
		end


		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set wp {name of waypoint} to set or re-set them.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "wp {name of waypoint}.  Teleport to the named waypoint. eg. " .. server.commandPrefix .. "wp wp1[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "share wp {name of waypoint}.  Allow your friends to tele to it with " .. server.commandPrefix .. "wp {your name} {name of waypoint}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "close (or unshare) wp {name of waypoint}.  Make it private again.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "clear wp {name of waypoint}.  Deletes the waypoint.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "link {wp1} to {wp2}. Convert two waypoints to a portal. In this mode nobody can tp to them, instead you step into them.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "unlink {wp1} (or {wp2}).  Unlinking either end of a portal unlinks both.  They revert to waypoints again.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "waypoints {optional name of friend}.  List your waypoints or the shared ones of a friend.[-]")
		return
	end


	if command == "irc" then
		if not server.ircPrivate or (chatvars.accessLevel < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Our irc server is located at " .. server.ircServer .. ":" .. server.ircPort .. "[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Send an irc invite to anyone with " .. server.commandPrefix .. "invite {player name}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Once there type /join " .. server.ircMain .. "[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Hexchat is a good free irc client which works on Windows.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Or visit https://kiwiirc.com/client/" .. server.ircServer .. ":" .. server.ircPort .. "/" .. server.ircMain .. "[-]")
		end

		return
	end


	if command == "friends" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can tell me who your friends are. This gives them access to private teleports etc.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "friend {friend's name} - add someone as a friend[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "unfriend {friend's name}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "friends - see who you have friended[-]")
		return
	end


	if command == "access" and (chatvars.accessLevel < 3) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Access levels control who can do what.  Commands that are above a players level return unknown command.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 0 server owners[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 1 admins[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 2 mods[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 10 Donors[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 90 Regular players[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 99 New players[-]")
		return
	end


	if command == "custom commands" and (chatvars.accessLevel < 3) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can create commands that send a private message.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "custom commands (list them)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "add command {command} level {access level} message {message}.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "remove command {command}.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Access level is optional and defaults to 99.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]See " .. server.commandPrefix .. "help access for the list of access levels.[-]")
		return
	end


	if (command == "gimme" or command == "gimmie") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Gimme is a fun game where you can win prizes![-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To play type " .. server.commandPrefix .. "gimme[-]")
		if (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "gimme on - enables gimme[-]") end
		if (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "gimme off - disables gimme[-]") end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "gimme peace - gimme messages stay out of public chat[-]")
		if (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "gimme gimme - prizes are announced publicly[-]") end
		if (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "gimme reset - Reset everyone's gimme count to 0 and zero the reset timer (2 hours)[-]") end
		return
	end


	if (command == "hotspots") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Hotspots are pm's that are triggered by proximity to a hotspot. They are 3 dimensional spheres and can be stacked vertically.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "hotspots {optional number} Lists all hotspots within 20 meters of you or type a number for a different distance[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "delete hotspot {optional number}. Deletes the nearest or numbered hotspot.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "hotspot {private message}  Adds hotspot where you are with a default radius of 3 meters[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "move hotspot {numbr}. The numbered hotspot will move to you.[-]")

		if (chatvars.accessLevel < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "resize hotspot {number} size 5. Change the radius of the numbered hotspot to 5 metres.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "delete hotspots {optional player}. Deletes all of a players hotspots or your own if no player given.[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "resize hotspot {number} size 5 (max 10). Change the radius of the numbered hotspot to 5 metres.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "delete hotspots. Deletes all of your hotspots.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If you move your base, any hotspots that are outside of your base are deleted. An admin may remove hotspots deemed to be offensive.[-]")
		end

		return
	end


	if (command == "setup") and (chatvars.accessLevel < 3) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Please set the following for smooth operation of the bot..[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "reset bot (only do this after a wipe and as soon after as possible)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "name bot {short name for me}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set map size {number} (how far in meters players can explore away from 0,0 Donors can go 5000 further out).[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set base cooldown {seconds} (how long to wait between " .. server.commandPrefix .. "base teleporting. Donors wait half as long)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set chat color {bbcode color without the brackets}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location add prison[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location add exile[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "max animals {number}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "max players {number}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "max zombies {number}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set website {url or steam group}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set irc server {ip:port}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set (or clear) max ping {100+}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set (or clear) welcome message {your welcome message}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]For prison and exile also type " .. server.commandPrefix .. "set location size {prison/exile} {distance in metres}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Also for each type " .. server.commandPrefix .. "location {prison/exile} pvp[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "set server pvp/pve/creative (tells me what type of server this is)[-]")
		return
	end


	if 	(command == "manual") and (chatvars.accessLevel < 3) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]More detailed help is available to admins on the IRC server.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is also botman.nz/docs/commands/all-bot-commands-new-version[-]")
		return
	end


	if (command == "tracker" and chatvars.accessLevel < 3) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can walk the path taken by a player at any point in their history.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "track {player name} session {number} Defaults to the most recent or current session.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Once the tracker is running:[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "goto start/end[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "go or " .. server.commandPrefix .. "stop[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "go back (change direction)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "skip {number}.  Skips every (n) steps[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "speed {number}.  Default is 3. Add 1 for each second you want to wait between steps.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "forward (or " .. server.commandPrefix .. "advance) {number} Jump forward n steps.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "back {number} Jump backwards n steps.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "next (track the next session)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "last (track the previous session)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "stop tracking[-]")
		return
	end


	if command == "donors" then
		if chatvars.accessLevel < 3 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type player status {player name} to check their donor status[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "add donor {player name} level {level} expires {number} {week or month or year}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "remove donor {player name}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Later you will be able to set a time limit like you do with bans.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Also I will add the ability to give a player a free trial for a settable time limit.[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]As a thank you for supporting us donors get extra features but donating is not required and is not pay to win.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Donors get a 2nd base teleport and base protection.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The base cooldown timer is half the normal time.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can set 2 waypoints and share it with friends. " .. server.commandPrefix .. "help waypoints (for info)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can explore an extra 5km of map.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can own a location and even become mayor of your own village.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You get access to anything we restrict to donors only.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You may get experimental new features before non-donors.[-]")
		end

		return
	end


	if (command == "admin") and chatvars.accessLevel < 3 then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This help is limited.  For better help visit the IRC server and type help in your bot's channel.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "arrest {playername / player id}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "release {playername / player id}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "release here {playername / player id}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "prison takes you to the prison[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "near {playername / player id} Be in god mode before using this.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "goto {playername / player id}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "fetch {playername / player id}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "rescue {playername} - like fetch but just works[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "return {playername / player id}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "sendhome {playername / player id}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "return - to return to where you came from[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who visited {optional player} range {number default is 10}[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]See also:[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help donors[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help tracker[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help reboot[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help locations[-]")
		return
	end


	if command == "locations" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Locations are POI's (Points of interest) that you may teleport to and from freely.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To travel to a location, just type the name of the location eg " .. server.commandPrefix .. "library  To return type " .. server.commandPrefix .. "return[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Locations are for everyone so please try not to trash them and don't claim them for yourself.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type " .. server.commandPrefix .. "locations to list public locations.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "show (or hide) locations (show or hide when you enter or leave a location)[-]")

		if (chatvars.accessLevel < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "prison takes you to the prison[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location add/remove {location}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location move {location} (move it to where you are standing)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location private/public {location} (default is private)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location {location} pvp/pve[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location set/clear reset {some name} (set as reset zone or clear)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location {some name} cost {number} (" .. server.moneyPlural .. " or quantity of an item)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location {some name} currency {item name} (require an item in inventory)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location {location} owner {player name}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location allow/disallow base {location} (allow or block setbase)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location {location} access {level} (no tp for players below acccess level)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location {location} size {number}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location {location} ends here (where you are standing)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location safe/unsafe {location} (set safe to auto-kill zombies)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "protect/unprotect location (like setting base protect. you must be in the location first).[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location {location} random (set random spawn points by simply walking around. type " .. server.commandPrefix .. "stop when finished.)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location {location} (detailed info about the location)[-]")
		end

		return
	end


	if command == "villages" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Villages are special locations that act like a base but with many players as villagers and one mayor.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player can belong to many villages and each village can have only 1 mayor.  Villagers can vote for a new mayor once per 7 game days.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The village teleport works exactly like a base teleport including the 30 minute delay.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "villages (list of villages)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "villagers {optional village} (list of villagers)[-]")

		if (chatvars.accessLevel < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "add village {name}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "remove village {name}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "village {name} size {size} (of village protection)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "protect village {name}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "add member {player name} village {village}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "remove member {player name} village {village}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "elect {player name} village {village} (assign the first mayor)[-]")
		end

		return
	end


	if command == "base" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]We offer base protection which is a special teleport that ejects uninvited players from your base.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You must tell the bot where your base is. Pick a central spot or right beside your storage.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type [i]" .. server.commandPrefix .. "setbase[/i].  If you have previously typed [i]" .. server.commandPrefix .. "enabletp[/i] you can teleport to here once every " .. (server.baseCooldown / 60) .. " minutes.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type [i]" .. server.commandPrefix .. "base[/i] (or [i]" .. server.commandPrefix .. "home[/i]) to fast travel to your base.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can activate protection on your base to teleport out unwanted players by typing [i]" .. server.commandPrefix .. "protect[/i].[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If your protection overlaps with an non-friended player, the bot will not allow you to activate your protection.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]By default only you and admins can enter your base. Read " .. server.commandPrefix .. "help friends to give your friends access too.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can temporarily suspend base protection with [i]" .. server.commandPrefix .. "pause[/i]. It will auto-resume when you are more than 100 meters from base or quit the game.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type [i]" .. server.commandPrefix .. "resume[/i] to re-activate it.[-]")
		return
	end


	if command == "teleport" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "enabletp (you can use teleports)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "disabletp (walking is better)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Read " .. server.commandPrefix .. "help base and " .. server.commandPrefix .. "help locations for more info.[-]")

		if (chatvars.accessLevel < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "opentp tpname[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "closetp tpname (must match opentp name)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "tele {tpname} delete[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "tele {tpname} owner {player name}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "tele {tpname} private[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "tele {tpname} public[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "teleports (list them all)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "tp {tpname} (tp to a teleport)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "lobby {player name} (send a player to the lobby if it exists)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleports are private by default.[-]")
		end

		return
	end


	if (command == "reset zones") or (command == "reset") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset zones areas which may be deleted and reset.  You will recieve a message whenever you enter or leave a reset zone.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Do not build in a reset zone or you risk losing it all.[-]")

		if (chatvars.accessLevel < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset zones can only be managed ingame as they reference your current position.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To make the region you are in a reset zone type " .. server.commandPrefix .. "add reset zone (regions are large)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Remove it with " .. server.commandPrefix .. "delete reset zone[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location set reset {location}[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "location clear reset {location}[-]")
		end

		return
	end


	if (command == "commands") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This list is just a summary.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "alert {your message to admins} Bot adds your coords too.[-]")
		if (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "enable gimme, " .. server.commandPrefix .. "disable gimme, " .. server.commandPrefix .. "gimme gimme[-]") end
		if not (server.hardcore) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "setbase, " .. server.commandPrefix .. "base, " .. server.commandPrefix .. "delbase, " .. server.commandPrefix .. "pause, " .. server.commandPrefix .. "resume, " .. server.commandPrefix .. "status[-]") end
		if not (server.hardcore) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "enabletp, " .. server.commandPrefix .. "disabletp (for teleporting)[-]") end
		if not (server.hardcore) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "friend, " .. server.commandPrefix .. "unfriend, " .. server.commandPrefix .. "friends[-]") end
		if not (server.hardcore) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "gimme, " .. server.commandPrefix .. "gimme peace[-]") end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "info[-]")
		if not (server.hardcore) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "locations[-]") end
		if not (server.hardcore) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "return[-]") end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "rules[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "seen[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "suicide[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "uptime[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "who[-]")

		if botman.dbConnected then
			cursor,errorString = conn:execute("select * from customMessages order by command")
			row = cursor:fetch({}, "a")

			while row do
				if (chatvars.accessLevel <= tonumber(row.accessLevel)) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. row.command .. "[-]")
				end

				row = cursor:fetch(row, "a")
			end
		end

		return
	end

	if command ~= nil then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No help topic for " .. command .. "[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The following topics are available: [-]")
		command = nil
	end

	-- always have the main help last so it catches any unsupported help commands.
	if command == nil then
		if (chatvars.accessLevel < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help access[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help admin[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help custom commands[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help setup[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help manual[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help reboot[-]")
		end

		if not (server.hardcore) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help base[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help bookmarks[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help commands or " .. server.commandPrefix .. "commands[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help friends[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help gimme[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help hotspots[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help locations[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help reset[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help shop[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help teleport[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help villages[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help waypoints[-]")
		end

		if not server.ircPrivate or (chatvars.accessLevel < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "help irc[-]") end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "alert (pass a message to the admins with your current position)[-]")

		return
	end
end
