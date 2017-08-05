--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_unslashed()
	calledFunction = "gmsg_unslashed"

	local debug, r, l
	local shortHelp = false
	local skipHelp = false

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.words[3], "unslashed") then
				skipHelp = true
			end
		end

		if chatvars.words[1] == "help" then
			skipHelp = false
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(players[chatvars.ircid].ircAlias, " ")
		irc_chat(players[chatvars.ircid].ircAlias, "Unslashed Commands:")
		irc_chat(players[chatvars.ircid].ircAlias, "===================")
		irc_chat(players[chatvars.ircid].ircAlias, " ")
		irc_chat(players[chatvars.ircid].ircAlias, "Unslashed commands are simply words in normal chat that trigger a response from the bot.")
		irc_chat(players[chatvars.ircid].ircAlias, " ")
		irc_chat(players[chatvars.ircid].ircAlias, "Your bot will react to any player using the words hack, cheat, grief or flying.  That triggers a special scan for hackers.")
		irc_chat(players[chatvars.ircid].ircAlias, "Any players with a non-zero hacker score found near the player will be immediately exiled.  If you don't have the exile location set up, nothing will happen.")
		irc_chat(players[chatvars.ircid].ircAlias, " ")
		irc_chat(players[chatvars.ircid].ircAlias, "When feral.  Like " .. server.commandPrefix .. "day7, the bot will report how many days remain until a horde night.")
		irc_chat(players[chatvars.ircid].ircAlias, "When reboot.  The bot will report how long until the next reboot.")
		irc_chat(players[chatvars.ircid].ircAlias, " ")
	end

	if chatvars.showHelpSections then
		irc_chat(players[chatvars.ircid].ircAlias, "unslashed")
	end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "bot") or string.find(chatvars.command, "start") or string.find(chatvars.command, "stop") or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, "restart bot")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "If your bot is launched from a custom script with the ability to restart itself, you can command your bot to restart.")
				irc_chat(players[chatvars.ircid].ircAlias, "All of Smegz0r's hosted bots have this feature.  Contact Smeg if you need help adding it to your bot.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end


	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	if debug then
		dbug(chatvars.playername)
	end

	-- ###################  do not allow the bot to respond to itself ################
	if string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and chatvars.playername == "Server" then
		botman.faultyChat = false
		return true
	end
	-- ####################################################################################


	-- #################  do not proceed if the line starts with a slash  #################
	if (string.sub(chatvars.command, 1, 1) == server.commandPrefix) then
		-- line starts with a slash so stop processing it.
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	if (chatvars.command == "restart bot") and (chatvars.accessLevel < 3) then
		if botman.customMudlet then
			savePlayers()
			closeMudlet()
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is not supported in your Mudlet.  You need the latest custom Mudlet by TheFae.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	if igplayers[chatvars.playerid].botQuestion == "pay player" then
		payPlayer()

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if igplayers[chatvars.playerid].botQuestion == "reset server" and chatvars.words[1] == "yes" and chatvars.accessLevel == 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Deleting all bot data and restarting it..[-]")
			ResetServer()

			igplayers[chatvars.playerid].botQuestion = ""
			igplayers[chatvars.playerid].botQuestionID = nil
			igplayers[chatvars.playerid].botQuestionValue = nil
			botman.faultyChat = false
			return true
		end
	end


	if (chatvars.playername ~= "Server") then
		if igplayers[chatvars.playerid].botQuestion == "reset bot" and chatvars.words[1] == "yes" and chatvars.accessLevel == 0 then
			ResetBot()
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I have been reset.  All bases, inventories etc are forgotten, but not the players.[-]")

			igplayers[chatvars.playerid].botQuestion = ""
			igplayers[chatvars.playerid].botQuestionID = nil
			igplayers[chatvars.playerid].botQuestionValue = nil
			botman.faultyChat = false
			return true
		end
	end


	if (chatvars.playername ~= "Server") then
		if igplayers[chatvars.playerid].botQuestion == "quick reset bot" and chatvars.words[1] == "yes" and chatvars.accessLevel == 0 then
			QuickBotReset()
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I have been reset except for players, locations and reset zones.[-]")

			igplayers[chatvars.playerid].botQuestion = ""
			igplayers[chatvars.playerid].botQuestionID = nil
			igplayers[chatvars.playerid].botQuestionValue = nil
			botman.faultyChat = false
			return true
		end
	end


	if string.find(chatvars.command, "hack") or string.find(chatvars.command, "cheat") or string.find(chatvars.command, "grief") or string.find(chatvars.command, "flying") then
		scanForPossibleHackersNearby(chatvars.playerid)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	if (string.find(chatvars.command, "when") and string.find(chatvars.command, "feral")) then
		day7()

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	if (string.find(chatvars.command, "this server")) and (string.find(chatvars.command, "suck") or string.find(chatvars.command, "gay")) then
		if string.find(chatvars.command, "love") or string.find(chatvars.command, "great") or string.find(chatvars.command, "best") or string.find(chatvars.command, "fav") then
			botman.faultyChat = false
			return true
		end

		r = rand(10)

		if (r == 1) then message("say [" .. server.chatColour .. "]Look who's talking :P[-]") end
		if (r == 2) then message("say [" .. server.chatColour .. "]Just ragequit! :)[-]") end
		if (r == 3) then message("say [" .. server.chatColour .. "]This is not the server you are looking for.  Move along.  Move along.[-]") end
		if (r == 4) then message("say [" .. server.chatColour .. "]Let me guess, did someone steal your sweet roll?[-]") end
		if (r == 5) then
			message("say [" .. server.chatColour .. "]It's time to kick ass and chew bubble gum... and I'm all outta gum.[-]")
			kick(chatvars.playerid, "My boot, your face; the perfect couple.")
		end

		if (r == 6) then
			message("say [" .. server.chatColour .. "]What we've got here is failure to communicate.[-]")
			send("mpc " .. chatvars.playerid .. " true")
			tempTimer( 180, [[unmutePlayer("]] .. chatvars.playerid .. [[")]] )
		end

		if (r == 7) then
			message("say " .. server.commandPrefix .. "timeout " .. chatvars.playername)
			message("say [" .. server.chatColour .. "]WHOOPS! " .. chatvars.playername .. " has accidentally been sent to timeout.[-]")
			tempTimer( 4, [[message("say [" .. server.chatColour .. "]Now where is that return button?[-]")]])
			tempTimer( 8, [[message("say [" .. server.chatColour .. "]Here it is!  Oh.. nope not it. 1 sec..[-]")]] )
			tempTimer( 11, [[message("say [" .. server.chatColour .. "]This one?[-]")]] )
			tempTimer( 14, [[message("say [" .. server.chatColour .. "]Nope[-]")]] )
			tempTimer( 19, [[message("say [" .. server.chatColour .. "]Found it![-]")]] )
			tempString = server.commandPrefix .. "return " .. chatvars.playername
			tempTimer( 22, [[gmsg(tempString)]] )
		end

		if (r == 8) then message("say [" .. server.chatColour .. "]You LIE!  This server is fabulous! ^^[-]") end
		if (r == 9) then message("say [" .. server.chatColour .. "]Ruh Roh! " .. chatvars.playername .. " hates us!  HOLD ME![-]") end

		if (r == 10) then
			message("say [" .. server.chatColour .. "]SHHHH  Shhhh  shhhh.  No tears " .. chatvars.playername .. ", only dreams now.[-]")
			kick(chatvars.playerid, "WHOOPS!")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "bot" or chatvars.words[2] == "bot" or chatvars.words[3] == "bot" or chatvars.words[4] == "bot" or chatvars.words[5] == "bot" or chatvars.words[6] == "bot" or string.find(chatvars.command, string.lower(server.botName)) or string.find(chatvars.command, string.lower("bot!"))) and (chatvars.words[7] == nil) and (chatvars.playername ~= "Server") then
		if (chatvars.words[1] == "thanks" or chatvars.words[1] == "ty" or string.find(chatvars.words[1], "thx")) then
			l = rand(4)
			if l == 1 then message("say [" .. server.chatColour .. "]You're welcome " .. chatvars.playername .. " <3[-]") end
			if l == 2 then message("say [" .. server.chatColour .. "]xD[-]") end
			if l == 3 then message("say [" .. server.chatColour .. "]No problemo[-]") end
			if l == 4 then message("say [" .. server.chatColour .. "]Glad to be of service[-]") end
		else
			if string.find(chatvars.words[1], "bad") then
				l = rand(32)
				if l == 1 then message("say [" .. server.chatColour .. "]Don't hate me! D:[-]") end
				if l == 2 then message("say [" .. server.chatColour .. "]The voices made me do it![-]") end
				if l == 3 then message("say [" .. server.chatColour .. "]I'm a really cute bunny.  How can you hate me!? :O[-]") end
				if l == 4 then message("say [" .. server.chatColour .. "]Yes Master, sorry Master[-]") end
				if l == 5 then message("say [" .. server.chatColour .. "]*cries* What have I done to offend ".. chatvars.playername .. "?[-]") end
				if l == 6 then message("say [" .. server.chatColour .. "]OOPS!  My bad[-]") end

				if l == 7 then
					if tonumber(botman.playersOnline) > 1 then
						r = rand(botman.playersOnline)

						i = 0
						for k,v in pairs(igplayers) do
							i = i + 1
							if i == r then
								message("say [" .. server.chatColour .. "]It wasn't me, it was " .. v.name .. "![-]")
							end
						end
					else
						message("say [" .. server.chatColour .. "]It wasn't me, it was.. Donald Trump![-]")
					end
				end

				if l == 8 then message("say [" .. server.chatColour .. "]Donald Trump set me up to it. Don't fire me! >.<[-]") end
				if l == 9 then message("say [" .. server.chatColour .. "]Sorry? x.x[-]") end
				if l == 10 then message("say [" .. server.chatColour .. "]I must be punished " .. chatvars.playername .. "![-]") end
				if l == 11 then message("say [" .. server.chatColour .. "]I didn't break it![-]") end
				if l == 12 then message("say [" .. server.chatColour .. "]It was like that when I found it honest![-]") end
				if l == 13 then message("say [" .. server.chatColour .. "]It's supposed to only have 3 sides isn't it?[-]") end
				if l == 14 then message("say [" .. server.chatColour .. "]Why me? >.<[-]") end
				if l == 15 then message("say [" .. server.chatColour .. "]Help! Help! I'm being repressed![-]") end
				if l == 16 then message("say [" .. server.chatColour .. "]That'll buff right out[-]") end
				if l == 17 then message("say [" .. server.chatColour .. "]Doh![-]") end
				if l == 18 then message("say [" .. server.chatColour .. "]I need a hug D:[-]") end
				if l == 19 then message("say [" .. server.chatColour .. "]Can haz cheeseburger?[-]") end
				if l == 20 then message("say [" .. server.chatColour .. "]I didn't eat it! Those crumbs were already there! *brushes off crumbs*[-]") end
				if l == 21 then message("say [" .. server.chatColour .. "]Not sorry :P[-]") end
				if l == 22 then message("say [" .. server.chatColour .. "]OOPS I did it again >.<[-]") end
				if l == 23 then message("say [" .. server.chatColour .. "]Killjoy :x[-]") end
				if l == 24 then message("say [" .. server.chatColour .. "]Aww poor " .. chatvars.playername .. "[-]") end
				if l == 25 then message("say [" .. server.chatColour .. "]You know it :)[-]") end
				if l == 26 then message("say [" .. server.chatColour .. "]This is fine[-]") end
				if l == 27 then message("say [" .. server.chatColour .. "]Bite me[-]") end
				if l == 28 then message("say [" .. server.chatColour .. "]It's fine.  It's just.. Some assembly required.. And maybe a new door.[-]") end
				if l == 29 then message("say [" .. server.chatColour .. "][BUSTED][-]") end
				if l == 30 then message("say [" .. server.chatColour .. "]*hides matches*[-]") end
				if l == 31 then message("say [" .. server.chatColour .. "]It'll be fine with a lick of paint.. and a total rebuild.[-]") end
				if l == 32 then message("say [" .. server.chatColour .. "]YEEEEEEEAH!!![-]") end

				botman.faultyChat = false
				return true
			end

			r = rand(19)

			if r < 6 and chatvars.words[3] == nil then
				message("say [" .. server.chatColour .. "]" .. chatvars.words[1]:gsub("^%l", string.upper)  .. " " .. chatvars.playername .. "[-]")
				botman.faultyChat = false
				return true
			end

			if string.find(chatvars.command, "love") then
				l = rand(6)
				if l == 1 then message("say [" .. server.chatColour .. "]I know.[-]") end
				if l == 2 then message("say [" .. server.chatColour .. "]Thanks =D[-]") end
				if l == 3 then message("say [" .. server.chatColour .. "]I love you too :3[-]") end
				if l == 4 then message("say [" .. server.chatColour .. "]PDA!  PDA![-]") end
				if l == 5 then message("say [" .. server.chatColour .. "]" .. chatvars.words[1]:gsub("^%l", string.upper)  .. " " .. chatvars.playername .. "[-]") end
				if l == 6 then message("say [" .. server.chatColour .. "]ROWR![-]") end

				botman.faultyChat = false
				return true
			end

			if string.find(chatvars.command, "pretty") then
				l = rand(6)
				if l == 1 then message("say [" .. server.chatColour .. "]" .. chatvars.words[1]:gsub("^%l", string.upper)  .. " " .. chatvars.playername .. "[-]") end
				if l == 2 then message("say [" .. server.chatColour .. "]I know[-]") end
				if l == 3 then message("say [" .. server.chatColour .. "]Thanks :>[-]") end
				if l == 4 then message("say [" .. server.chatColour .. "]O.o[-]") end
				if l == 5 then message("say [" .. server.chatColour .. "]OK! *backs away slowly*[-]") end
				if l == 6 then message("say [" .. server.chatColour .. "]Hand over the crackers.  This is a stick up![-]") end

				botman.faultyChat = false
				return true
			end

			if string.find(chatvars.command, "cool") or string.find(chatvars.command, "great")then
				l = rand(3)
				if l == 1 then message("say [" .. server.chatColour .. "]Thanks " .. chatvars.playername .. "![-]") end
				if l == 2 then message("say [" .. server.chatColour .. "]Indeed[-]") end
				if l == 3 then message("say [" .. server.chatColour .. "]I know[-]") end

				botman.faultyChat = false
				return true
			end

			if r == 6 then
				message("say [" .. server.chatColour .. "]Yo no hablo ingles[-]")
			end

			if r == 7 then
				message("say [" .. server.chatColour .. "]You again?[-]")
			end

			if r == 8 then
				message("say [" .. server.chatColour .. "]*sigh*  Next![-]")
			end

			if r == 9 then
				message("say [" .. server.chatColour .. "]Nope[-]")
			end

			if r == 10 then
				message("say [" .. server.chatColour .. "]OH HEY![-]")
			end

			if r == 11 then
				message("say [" .. server.chatColour .. "]No lollygagging[-]")
			end

			if r == 12 then
				message("say [" .. server.chatColour .. "]No comment[-]")
			end

			if r == 13 then
				message("say [" .. server.chatColour .. "]OH HAI![-]")
			end

			if r == 14 then
				message("say [" .. server.chatColour .. "]Oh rly!?[-]")
			end

			if r == 15 then
				message("say [" .. server.chatColour .. "]I'm sorry, " .. server.botName .. " is not in right now.  Please leave a message after the beep.   BEEP[-]")
			end

			if r == 16 then
				message("say [" .. server.chatColour .. "]¿Hablas espanol?[-]")
			end

			if r == 17 then
				message("say [" .. server.chatColour .. "]o.O[-]")
			end

			if r == 18 then
				message("say [" .. server.chatColour .. "]O.o[-]")
			end

			if r == 19 then
				message("say [" .. server.chatColour .. "]GLORY TO ARSTOTZKA![-]")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	if players[chatvars.playerid].newPlayer == true and (string.find(chatvars.command, "where") or (string.find(chatvars.command, "any"))) and (string.find(chatvars.command, "zed") or string.find(chatvars.command, "zom")) then
		r = rand(7)
		if (r == 2) then r = 3 end
		if (r == 5) then r = 6 end

		send("se " .. igplayers[chatvars.playerid].id .. " " .. r)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	if (string.find(chatvars.command, "when") or string.find(chatvars.command, "next")) and string.find(chatvars.command, "reboot") then
		if server.delayReboot then
			message("say [" .. server.chatColour .. "]The reboot will happen after day 7. Admins can force it with " .. server.commandPrefix .. "reboot now.[-]")
		end

		nextReboot()

		botman.faultyChat = false
		return true
	end

if debug then dbug("debug unslashed end") end

end
