--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug, r, l
local shortHelp = false
local skipHelp = false

debug = false -- should be false unless testing

function gmsg_unslashed()
	calledFunction = "gmsg_unslashed"

	if botman.debugAll then
		debug = true -- this should be true
	end

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
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Unslashed Commands:")
		irc_chat(chatvars.ircAlias, "===================")
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Unslashed commands are simply words in normal chat that trigger a response from the bot.")
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Your bot will react to any player using the words hack, cheat, grief or flying.  That triggers a special scan for hackers.")
		irc_chat(chatvars.ircAlias, "Any players with a non-zero hacker score found near the player will be immediately exiled.  If you don't have the exile location set up, nothing will happen.")
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "When feral.  Like " .. server.commandPrefix .. "day7, the bot will report how many days remain until a horde night.")
		irc_chat(chatvars.ircAlias, "When reboot.  The bot will report how long until the next reboot.")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "unslashed")
	end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "bot") or string.find(chatvars.command, "start") or string.find(chatvars.command, "stop") or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, "restart bot")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "If your bot is launched from a custom script with the ability to restart itself, you can command your bot to restart.")
				irc_chat(chatvars.ircAlias, "All of Smegz0r's hosted bots have this feature.  Contact Smeg if you need help adding it to your bot.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

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
	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end
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
		if not server.allowBotRestarts then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is disabled.  Enable it with /enable bot restart[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]If you do not have a script or other process monitoring the bot, it will not restart automatically.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Scripts can be downloaded at http://botman.nz/shellscripts.zip and may require some editing for paths.[-]")

			botman.faultyChat = false
			return true
		end

		if botman.customMudlet then
			if server.masterPassword ~= "" then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command requires a password to complete. Don't use this command unless you know what it does and why you need to do it.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Type " .. server.commandPrefix .. "password {the password} (Do not type the {}).[-]")
				players[chatvars.playerid].botQuestion = "restart bot"
			else
				restartBot()
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is not supported in your Mudlet.  You need the latest custom Mudlet by TheFae or Mudlet 3.4[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	if players[chatvars.playerid].botQuestion == "pay player" then
		payPlayer()

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	if (chatvars.playername ~= "Server") then
		if players[chatvars.playerid].botQuestion == "reset server" and chatvars.words[1] == "yes" and chatvars.accessLevel == 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Deleting all bot data and restarting it..[-]")
			ResetServer()

			players[chatvars.playerid].botQuestion = ""
			players[chatvars.playerid].botQuestionID = nil
			players[chatvars.playerid].botQuestionValue = nil
			botman.faultyChat = false
			return true
		end
	end


	if (chatvars.playername ~= "Server") then
		if players[chatvars.playerid].botQuestion == "reset bot keep money" and chatvars.words[1] == "yes" and chatvars.accessLevel == 0 then
			ResetBot(true)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I have been reset.  All bases, inventories etc are forgotten, but not the players or their money.[-]")

			players[chatvars.playerid].botQuestion = ""
			players[chatvars.playerid].botQuestionID = nil
			players[chatvars.playerid].botQuestionValue = nil
			botman.faultyChat = false
			return true
		end

		if players[chatvars.playerid].botQuestion == "reset bot" and chatvars.words[1] == "yes" and chatvars.accessLevel == 0 then
			ResetBot()
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I have been reset.  All bases, inventories etc are forgotten, but not the players.[-]")

			players[chatvars.playerid].botQuestion = ""
			players[chatvars.playerid].botQuestionID = nil
			players[chatvars.playerid].botQuestionValue = nil
			botman.faultyChat = false
			return true
		end
	end


	if (chatvars.playername ~= "Server") then
		if players[chatvars.playerid].botQuestion == "quick reset bot" and chatvars.words[1] == "yes" and chatvars.accessLevel == 0 then
			QuickBotReset()
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I have been reset except for players, locations and reset zones.[-]")

			players[chatvars.playerid].botQuestion = ""
			players[chatvars.playerid].botQuestionID = nil
			players[chatvars.playerid].botQuestionValue = nil
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

	if not server.beQuietBot then
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
				sendCommand("mpc " .. chatvars.playerid .. " true")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

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

		if (chatvars.playername ~= "Server") then
		if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end
			for i=1,chatvars.wordCount,1 do
				word = chatvars.words[i]

				if word == "bot" or word == "bot?" or word == "bot!" or word == string.lower(server.botName) then
					if (chatvars.words[1] == "thanks" or chatvars.words[1] == "ty" or string.find(chatvars.words[1], "thx")) then
						l = rand(4)
						if l == 1 then message("say [" .. server.chatColour .. "]You're welcome " .. chatvars.playername .. " <3[-]") end
						if l == 2 then message("say [" .. server.chatColour .. "]xD[-]") end
						if l == 3 then message("say [" .. server.chatColour .. "]No problemo[-]") end
						if l == 4 then message("say [" .. server.chatColour .. "]Glad to be of service[-]") end
					else
						if string.find(chatvars.words[1], "bad") then
							l = rand(46)

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
							if l == 13 then message("say [" .. server.chatColour .. "]Well.. it still has a door! *THUD*  ..or not.[-]") end
							if l == 14 then message("say [" .. server.chatColour .. "]Why me? >.<[-]") end
							if l == 15 then message("say [" .. server.chatColour .. "]Help! Help! I'm being repressed![-]") end
							if l == 16 then message("say [" .. server.chatColour .. "]That'll buff right out.[-]") end
							if l == 17 then message("say [" .. server.chatColour .. "]Doh![-]") end
							if l == 18 then message("say [" .. server.chatColour .. "]I need a hug D:[-]") end
							if l == 19 then message("say [" .. server.chatColour .. "]Relax, it'll stop burning any minute now.[-]") end
							if l == 20 then message("say [" .. server.chatColour .. "]I didn't eat it! Those crumbs were already there! *brushes off crumbs*[-]") end
							if l == 21 then message("say [" .. server.chatColour .. "]Not sorry :P[-]") end
							if l == 22 then message("say [" .. server.chatColour .. "]OOPS I did it again >.<[-]") end
							if l == 23 then message("say [" .. server.chatColour .. "]Killjoy :x[-]") end
							if l == 24 then message("say [" .. server.chatColour .. "]Aww poor " .. chatvars.playername .. "[-]") end
							if l == 25 then message("say [" .. server.chatColour .. "]You know it :)[-]") end
							if l == 26 then message("say [" .. server.chatColour .. "]^flames^  This is fine  ^more flames^[-]") end
							if l == 27 then message("say [" .. server.chatColour .. "]Bite me[-]") end
							if l == 28 then message("say [" .. server.chatColour .. "]It's fine.  It's just.. Some assembly required.. And maybe a new door.[-]") end
							if l == 29 then message("say [" .. server.chatColour .. "][BUSTED][-]") end
							if l == 30 then message("say [" .. server.chatColour .. "]*hides matches*[-]") end
							if l == 31 then message("say [" .. server.chatColour .. "]It'll be fine with a lick of paint.. and a total rebuild.[-]") end
							if l == 32 then message("say [" .. server.chatColour .. "]YEEEEEEEAH!!![-]") end
							if l == 33 then message("say [" .. server.chatColour .. "]Oh.. it wasn't a flatpack?  Well now it is! :D[-]") end
							if l == 34 then message("say [" .. server.chatColour .. "]Curses!  If it hadn't been for that meddling " .. chatvars.playername .. " I'd have gotten away with it![-]") end
							if l == 35 then message("say [" .. server.chatColour .. "]I didn't touch it! *edges away from it*[-]") end
							if l == 36 then message("say [" .. server.chatColour .. "]It was just a prank bro[-]") end
							if l == 37 then message("say [" .. server.chatColour .. "]Oh.. that was yours?[-]") end
							if l == 38 then message("say [" .. server.chatColour .. "]The front fell off.[-]") end
							if l == 39 then message("say [" .. server.chatColour .. "]GRR GRR GRR[-]") end
							if l == 40 then message("say [" .. server.chatColour .. "]Mine.[-]") end
							if l == 41 then message("say [" .. server.chatColour .. "]Uh..  SQUIRREL![-]") end
							if l == 42 then message("say [" .. server.chatColour .. "]The floor is lava.[-]") end
							if l == 43 then message("say [" .. server.chatColour .. "]Tis but a scratch.[-]") end
							if l == 44 then message("say [" .. server.chatColour .. "]I know nothing. Nothing![-]") end
							if l == 45 then message("say [" .. server.chatColour .. "]Wasn't me! Wasn't me!  Nope - Nuh-uh.  *hides evidence*[-]") end
							if l == 46 then message("say [" .. server.chatColour .. "]I like trains.[-]") end

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

						if string.find(chatvars.command, "cool") or string.find(chatvars.command, "great") or string.find(chatvars.command, "good") then
							l = rand(4)
							if l == 1 then message("say [" .. server.chatColour .. "]Thanks " .. chatvars.playername .. "![-]") end
							if l == 2 then message("say [" .. server.chatColour .. "]Indeed[-]") end
							if l == 3 then message("say [" .. server.chatColour .. "]I know[-]") end
							if l == 4 then message("say [" .. server.chatColour .. "]^.^[-]") end

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
			end
		end
	end

	if (debug) then dbug("debug unslashed line " .. debugger.getinfo(1).currentline) end

	if not server.beQuietBot then
		if players[chatvars.playerid].newPlayer == true and (string.find(chatvars.command, "where") or (string.find(chatvars.command, "any"))) and (string.find(chatvars.command, "zed") or string.find(chatvars.command, "zom")) then
			r = rand(7)
			if (r == 2) then r = 3 end
			if (r == 5) then r = 6 end

			sendCommand("se " .. igplayers[chatvars.playerid].id .. " " .. r)

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			botman.faultyChat = false
			return true
		end
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
