--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


function help(command)
	local list

	if (command == "me") then
		r = rand(6)
		if (r==1) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Sorry you're beyond help I'm afraid.[-]") end
		if (r==2) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Today I did 6 impossible things, but that ain't one.[-]") end
		if (r==3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I can't fix that![-]") end
		if (r==4) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Ask your cat.[-]") end
		if (r==5) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You need a wash and a haircut.[-]") end
		if (r==6) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Get up and go outside.  Maybe you've heard of it?[-]") end
		return
	end


	if command == "reboot" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]By default /reboot will reboot 2 minutes later. More detailed help on irc.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/reboot in n minutes/hours (restricted to server owners)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/cancel reboot[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/pause reboot  /unpause reboot[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/enable (or /disable) reboot (toggle automated rebooting)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A timed reboot can be delayed if anyone says wait during the countdown. This can be blocked if you add 'forced' to the reboot command.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Several automatic reboots can happen that I manage.[-]")
		return
	end


	if command == "mail" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Send private messages to your friends. They have to have friended you with /friend " .. players[chatvars.playerid].name .. " before you can message them.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can only send mail from your console, which you access from the tild key which is above TAB and left of your 1 key.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To send a message to your friend Dave type pm @dave Hi Dave!  If he is on, he will get it now.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can message the admins with pm @admin <your message here>.  Every admin will see it.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Ignore the command denied message.[-]")
		message("pm " .. chatvars.playerid .. "")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/list mail (see a numbered list of all your messages)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/read mail <optional number> (reads all unread by default)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/save mail <number> (read mail is deleted unless saved)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/delete mail <number> (delete the numbered message)[-]")
		return
	end


	if (command == "bookmarks") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This feature is just to help admins locate places of interest or so we can screenshot your base before a wipe.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If you add too many or stupid bookmarks we will not use them.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]These are not teleports like waypoints.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "][-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/bookmark <short description> (add a bookmark where you are standing)[-]")

		if (accessLevel(chatvars.playerid) < 3) then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/list bookmarks <player> (view a players bookmarks)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/bk <bookmark number> (tp to the coords of a bookmark)[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/list bookmarks (view your own bookmarks)[-]")
		end

		return
	end


	if (command == "male") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]HELLOOOOO Nurse![-]")
		return
	end


	if (command == "special") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]P2Ptokens allow you to teleport to a friend and return (once per token).[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The friend has to have friended you via the bot.  Tokens are not items so there is nothing to pick up or lose.[-]")
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

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The game currency is the zenny. Each zombie killed earns you 5 zennies.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/cash (see what you have in the bank)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To browse type /shop followed by a category. Categories are..[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. list .. "[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]For a general search type /shop <item> eg. /shop shirt[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/buy <item number> <quantity>  Buy all the things![-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/pay <player> <amount>  You can't put a price on love so send money instead.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/gamble (gamble in our daily lottery) 25 zennies per ticket[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Buy multiple tickets at once with /gamble 5 (or any number). The winning number is picked from ticket number 1 to 100.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The shop sells special items. Read /help special for info.[-]")
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/open shop - allow players access to the shop.[-]") end
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/close shop - block player access to the shop.[-]") end
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set shop open - set a time (0 - 23) when the shop opens.[-]") end
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set shop close - set a time (0 - 23) when the shop closes.[-]") end
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set shop location <location> - tie the shop to a location.[-]") end
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/clear shop location - the shop can be used anywhere.[-]") end
		return
	end


	if command == "waypoints" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are available to donors and admins only.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set waypoint then /waypoint or /<your name> to tp to it.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/open waypoint - allow your friends to tp with /<your name>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/close waypoint - make it private again.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/clear waypoint - deletes the waypoint[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]An opened waypoint automatically closes when you clear it.[-]")
		return
	end


	if command == "irc" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Our irc server is located at " .. server.ircServer .. "[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Once there type /join #" .. server.ircMain .. "[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Hexchat is a good free irc client which works on Windows.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Or use this link https://kiwiirc.com/client/" .. server.ircServer .. "/" .. server.ircMain .. "[-]")
		return
	end


	if command == "friends" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can tell me who your friends are. This gives them access to private teleports etc.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/friend <friend's name> - add someone as a friend[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/unfriend <friend's name>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/friends - see who you have friended[-]")
		return
	end


	if command == "access" and (accessLevel(chatvars.playerid) < 3) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Access levels control who can do what.  Commands that are above a players level return unknown command.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 0 server owners[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 1 admins[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 2 mods[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 3 <reserved>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 4 Donors[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 90 Regular players[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level 99 New players[-]")
		return
	end


	if command == "custom commands" and (accessLevel(chatvars.playerid) < 3) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can create commands that send a private message.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/custom commands (list them)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/add command <command> level <access level> message <message>.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/remove command <command>.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Access level is optional and defaults to 99.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]See /help access for the list of access levels.[-]")
		return
	end


	if command == "pve" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]PVE means player versus environment.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The objective is to live off the land, gather resources, build shelter and survive.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can always ask others for help and if it gets too tough, you can take refuge in the library.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]On this server there are a few areas where PVP is allowed. Read /help pvp for info.[-]")
		return
	end


	if command == "pvp" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]We have a PVP zone called Deadzone where you may PVP other players.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type deadzone on chat to teleport to there. All other areas are PVE ONLY.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You start off in a large city with plenty of cover.  You will be alerted when you enter or exit the pvp zone.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If you manage to get arrested for pvp outside of a zone, your victim or an admin can release you.[-]")
		return
	end


	if (command == "deadzone") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]ALERT!  Teleporting to Deadzone is treated the same as using your base teleport. You will not be able to return to base immediately.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You start off in a large city or town in a random location.  You will be alerted when you enter or exit the pvp zone.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If you manage to get arrested for a PVP in PVE areas, your victim or an admin can release you.[-]")
		return
	end


	if (command == "gimme" or command == "gimmie") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Gimme is a fun game where you can win prizes![-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To play, place 64 casino coins in the last slot of your belt. Gimmies are played automatically once per minute until you remove the coins or run out fo gimmies to play.[-]")
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/gimme on - enables gimme[-]") end
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/gimme off - disables gimme[-]") end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/gimme peace - prizes are pm'ed[-]")
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/gimme gimme - prizes are announced publicly[-]") end
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/gimme reset - Reset everyone's gimme count to 0 and zero the reset timer (2 hours)[-]") end
		return
	end


	if (command == "hotspots") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Hotspots are pm's that are triggered by proximity to a hotspot. They are 3 dimensional spheres and can be stacked vertically.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/hotspots <optional number> Lists all hotspots within 20 meters of you or type a number for a different distance[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/delete hotspot <optional number>. Deletes the nearest or numbered hotspot.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/hotspot <private message>  Adds hotspot where you are with a default radius of 3 meters[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/move hotspot <numbr>. The numbered hotspot will move to you.[-]")

		if (accessLevel(chatvars.playerid) < 3) then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/resize hotspot <number> size 5. Change the radius of the numbered hotspot to 5 metres.[-]") 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/delete hotspots <optional player>. Deletes all of a players hotspots or your own if no player given.[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/resize hotspot <number> size 5 (max 10). Change the radius of the numbered hotspot to 5 metres.[-]") 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/delete hotspots. Deletes all of your hotspots.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If you move your base, any hotspots that are outside of your base are deleted. An admin may remove hotspots deemed to be offensive.[-]")
		end

		return
	end


	if (command == "setup") and (accessLevel(chatvars.playerid) < 3) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Please set the following for smooth operation of the bot..[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/reset bot (only do this after a wipe and as soon after as possible)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/name bot <short name for me>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set map size <number> (how far in meters players can explore away from 0,0)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set base cooldown <minutes> (how long to wait between /base teleporting. Donors wait half as long)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set chat color <bbcode color without the brackets>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location add prison[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location add exile[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/max animals <number>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/max players <number>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/max zombies <number>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set website <url or steam group>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set irc server <ip:port>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set (or clear) max ping <100+>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set (or clear) welcome message <your welcome message>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]For prison and exile also type /set location size <prison/exile> <distance in metres>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Also for each type /location <prison/exile> pvp[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/set server pvp/pve/creative (tells me what type of server this is)[-]")
		return
	end


	if 	(command == "manual") and (accessLevel(chatvars.playerid) < 3) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]More detailed help is available to admins on the IRC server.[-]")
		return
	end


	if (command == "tracker" and accessLevel(chatvars.playerid) < 3) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can walk the path taken by a player at any point in history.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/track <player> session <number> Defaults to the most recent or current.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Once the tracker is running:[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/goto start/end[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/go or /stop[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/go back (change direction)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/skip <number>.  Skips every (n) steps[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/speed <number>.  Default is 1. Add 1 for each second you want to wait between steps.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/forward (or /advance) <number> Jump forward n steps.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/back <number> Jump backwards n steps.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/next (track the next session)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/last (track the previous session)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/stop tracking[-]")
		return
	end


	if command == "donors" then
		if accessLevel(chatvars.playerid) < 3 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type player status <player> to check their donor status[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/add donor <player> level <level> expires <number> <week or month or year>[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/remove donor <player>[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Later you will be able to set a time limit like you do with bans.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Also I will add the ability to give a player a free trial for a settable time limit.[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]As a thank you for supporting us donors get extra features but donating is not required and is not pay to win.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Donors get a 2nd base teleport and base protection,[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The base cooldown timer is half the normal time,[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can set 1 waypoint and share it with friends,[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can explore an extra 5km of map,[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can own a location and even become mayor of your own village,[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You get access to anything we restrict to donors only,[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You may get experimental new features before non-donors.[-]")
		end

		return
	end


	if (command == "admin") and accessLevel(chatvars.playerid) < 3 then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/arrest <playername / player id>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/release <playername / player id>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/release here <playername / player id>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/prison takes you to the prison[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/closeto <playername / player id> Be in god mode before using this.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/goto <playername / player id>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/fetch <playername / player id>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/rescue <playername> - like fetch but just works[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/return <playername / player id>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/sendhome <playername / player id>[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help donors[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help tracker[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/return - to return to where you came from[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/reboot empty (or idle)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/who visited <optional player> range <number default is 10>[-]")
		return
	end


	if command == "locations" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Locations are POI's (Points of interest) that you may teleport to and from freely.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To travel to a location, just type the name of the location eg /library  To return type /return[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Locations are for everyone so please try not to trash them and don't claim them for yourself.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type /locations to list public locations.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/show (or hide) locations (show or hide when you enter or leave a location)[-]")

		if (accessLevel(chatvars.playerid) < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/prison takes you to the prison[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location add/remove <location>[-]")	
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location move <location> (move it to where you are standing)[-]")	
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location private/public <location> (default is private)[-]")	
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location <location> pvp/pve[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location set/clear reset <some name> (set as reset zone or clear)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location <some name> cost <number> (zennies or quantity of an item)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location <some name> currency <item name> (require an item in inventory)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location <location> owner <player>[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location allow/disallow base <location> (allow or block setbase)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location <location> access <level> (no tp for players below acccess level)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location <location> size <number>[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location <location> ends here (where you are standing)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location safe/unsafe <location> (set safe to auto-kill zombies)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/protect/unprotect location (like setting base protect. you must be in the location first).[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location <location> random (set random spawn points by simply walking around. type /stop when finished.)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location <location> (detailed info about the location)[-]")
		end

		return
	end


	if command == "villages" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Villages are special locations that act like a base but with many players as villagers and one mayor.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player can belong to many villages and each village can have only 1 mayor.  Villagers can vote for a new mayor once per 7 game days.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The village teleport works exactly like a base teleport including the 30 minute delay.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/villages (list of villages)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/villagers <optional village> (list of villagers)[-]")

		if (accessLevel(chatvars.playerid) < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/add village <name>[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/remove village <name>[-]")	
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/village <name> size <size> (of village protection)[-]")	
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/protect village <name>[-]")	
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/add member <player> village <village>[-]")	
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/remove member <player> village <village>[-]")	
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/elect <player> village <village> (assign the first mayor)[-]")	
		end
		
		return
	end


	if command == "base" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]We offer base protection which is a special teleport that ejects uninvited players from your base.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You must tell the bot where your base is. Pick a central spot or right beside your storage.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type [i]/setbase[/i].  If you have previously typed [i]enabletp[/i] you can teleport to here once every " .. (server.baseCooldown / 60) .. " minutes.[-]")	
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type [i]/base[/i] (or [i]home[/i]) to fast travel to your base.[-]")	
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can activate protection on your base to teleport out unwanted players by typing [i]/protect[/i].[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If your protection overlaps with an non-friended player, the bot will not allow you to activate your protection.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]By default only you and admins can enter your base. Read /help friends to give your friends access too.[-]")	
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can temporarily suspend base protection with [i]/pause[/i]. It will auto-resume when you are more than 100 meters from base or quit the game.[-]")	
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type [i]/resume[/i] to re-activate it.[-]")	
		return
	end


	if command == "teleport" then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/enabletp (you can use teleports)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/disabletp (walking is better)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Read /help base and /help locations for more info.[-]")

		if (accessLevel(chatvars.playerid) < 3) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/opentp tpname[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/closetp tpname (must match opentp name)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/killtp tpname (deletes a teleport)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/owntp tpname playername[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/privatetp tpname[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/publictp tpname[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/teleports (list them all)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/tp tpname (tp to a teleport)[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Teleports are private by default.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/lobby <player name> (send a player to the lobby if it exists)[-]")
		end

		return
	end


	if (command == "reset zones") or (command == "reset") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset zones areas which may be deleted and reset.  You will recieve a message whenever you enter or leave a reset zone.[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Do not build in a reset zone or you risk losing it all.[-]")

		if (accessLevel(chatvars.playerid) < 3) then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset zones can only be managed ingame as they reference your current position.[-]") 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To make the region you are in a reset zone type /add reset zone (regions are large)[-]") 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Remove it with /delete reset zone[-]") 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location set reset <location>[-]") 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/location clear reset <location>[-]") 
		end

		return
	end


	if (command == "commands") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This list is just a summary.[-]")	
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/alert <your message to admins> Bot adds your coords too.[-]")
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/enable gimme, /disable gimme, /gimme gimme[-]") end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/setbase, /base, /delbase, /pause, /resume, /status[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/enabletp, /disabletp[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/friend, /unfriend, /friends[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/gimme, /gimme peace[-]")	
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/info[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/locations[-]")
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/reboot empty (or idle)[-]") end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/return[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/rules[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/seen[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/suicide[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/uptime[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/who[-]")

		cursor,errorString = conn:execute("select * from customMessages order by command")
		row = cursor:fetch({}, "a")

		while row do
			if (accessLevel(chatvars.playerid) <= tonumber(row.accessLevel)) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/" .. row.command .. "[-]")
			end

			row = cursor:fetch(row, "a")
		end

		return
	end

	-- always have the main help last so it catches any unsupported help commands.
	if command == nil then
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help access[-]") end
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help admin[-]") end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help base[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help bookmarks[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help commands or /commands[-]")
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help custom commands[-]") end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help friends[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help gimme[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help hotspots[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help irc[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help locations[-]")
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help manual[-]") end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help pve[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help pvp[-]")
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help reboot[-]") end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help reset[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help shop[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/alert (pass a message to the admins with your current position)[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help teleport[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help villages[-]")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help waypoints[-]")		
		if (accessLevel(chatvars.playerid) < 3) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/help setup[-]") end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]/about bot[-]")
		return
	end
end
