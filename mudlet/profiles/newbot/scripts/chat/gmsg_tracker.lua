--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_tracker()
	calledFunction = "gmsg_tracker"

	local debug
	local shortHelp = false
	local skipHelp = false
	local filter = ""

	debug = false

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.words[3], "track") then
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
		irc_chat(players[chatvars.ircid].ircAlias, "")
		irc_chat(players[chatvars.ircid].ircAlias, "Tracker Commands:")
		irc_chat(players[chatvars.ircid].ircAlias, "=================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if chatvars.showHelpSections then
		irc_chat(players[chatvars.ircid].ircAlias, "tracker")
	end


	-- ###################  do not allow remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return false
		end
	end
	-- ##################################################################

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "track"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "track <player> session <number> (session is optional and defaults to the latest)")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "next (track the next session)")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "last (track the previous session)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Track the movements of a player.  If a session is given, you will track their movements from that session.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if ((chatvars.words[1] == "track") or (chatvars.words[1] == "next") or (chatvars.words[1] == "last")) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		tmp = {}
		conn:execute("DELETE FROM memTracker WHERE admin = " .. chatvars.playerid)
		igplayers[chatvars.playerid].trackerStopped = false
		igplayers[chatvars.playerid].trackerReversed = false

		if igplayers[chatvars.playerid].trackerSpeed == nil then
			igplayers[chatvars.playerid].trackerSpeed = 4
		end

		if igplayers[chatvars.playerid].trackerSkip == nil then
			igplayers[chatvars.playerid].trackerSkip = 1
		end

		if (chatvars.words[1] ~= "next") and (chatvars.words[1] ~= "last") then
			igplayers[chatvars.playerid].trackerCountdown = igplayers[chatvars.playerid].trackerSpeed
			igplayers[chatvars.playerid].trackerCount = 0
			igplayers[chatvars.playerid].trackerSteam = 0
			igplayers[chatvars.playerid].trackerSession = 0
		else
			if (chatvars.words[1] == "next") then
				igplayers[chatvars.playerid].trackerSession = igplayers[chatvars.playerid].trackerSession + 1
				igplayers[chatvars.playerid].trackerCount = 0
				igplayers[chatvars.playerid].trackerReversed = false
			end

			if (chatvars.words[1] == "last") then
				igplayers[chatvars.playerid].trackerSession = igplayers[chatvars.playerid].trackerSession - 1
				igplayers[chatvars.playerid].trackerCount = 1000000000
				igplayers[chatvars.playerid].trackerReversed = true
			end

			tmp.id = igplayers[chatvars.playerid].trackerSteam
			tmp.session = igplayers[chatvars.playerid].trackerSession
		end

		for i=1,chatvars.wordCount,1 do
			if chatvars.words[i] == "track" then
				tmp.name = chatvars.words[i+1]
				tmp.id = LookupPlayer(tmp.name)

				if tmp.id ~= nil then
					tmp.session = players[tmp.id].sessionCount
					igplayers[chatvars.playerid].trackerSession = players[tmp.id].sessionCount
					igplayers[chatvars.playerid].trackerSteam = tmp.id
					igplayers[chatvars.playerid].trackerLastSession = true
				end
			end

			if chatvars.words[i] == "session" then
				tmp.session = chatvars.words[i+1]
				igplayers[chatvars.playerid].trackerSession = tmp.session

				if tonumber(tmp.session) == players[tmp.id].sessionCount then
					igplayers[chatvars.playerid].trackerLastSession = true
				else
					igplayers[chatvars.playerid].trackerLastSession = false
				end
			end

			if chatvars.words[i] == "here" then
				tmp.x = chatvars.intX
				tmp.z = chatvars.intZ
				tmp.dist = 200
			end

			if chatvars.words[i] == "range" or chatvars.words[i] == "dist" or chatvars.words[i] == "distance" then
				tmp.x = chatvars.intX
				tmp.z = chatvars.intZ
				tmp.dist = chatvars.words[i+1]
			end

			if chatvars.words[i] == "hax" or chatvars.words[i] == "hack" or chatvars.words[i] == "hacking" or chatvars.words[i] == "cheat" then
				filter = " and flag like '%F%'"
			end
		end

		if tmp.id ~= nil then
			if tmp.dist ~= nil then
				conn:execute("INSERT into memTracker (SELECT trackerID, " .. chatvars.playerid .. " AS admin, steam, timestamp, x, y, z, SESSION , flag from tracker where steam = " .. tmp.id .. " and session = " .. tmp.session .. " and abs(x - " .. tmp.x .. ") <= " .. tmp.dist .. " AND abs(z - " .. tmp.z .. ") <= " .. tmp.dist .. " " .. filter .. ")")
			else
				conn:execute("INSERT into memTracker (SELECT trackerID, " .. chatvars.playerid .. " AS admin, steam, timestamp, x, y, z, SESSION , flag from tracker where steam = " .. tmp.id .. " and session = " .. tmp.session .. " " .. filter .. ")")
			end
		else
			if tmp.name == nil then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player name, game id, or steam id required.[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player or steam id matched " .. tmp.name .. "[-]")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "track"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "skip <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Skip <number> of steps.  Instead of tracking each recorded step, you will skip <number> steps for faster but less precise tracking.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "skip" and chatvars.number ~= nil) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerSkip = chatvars.number

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "track"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "speed <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The default pause between each tracked step is 3 seconds. Change it to any number of seconds from 1 to whatever.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "speed" and chatvars.number ~= nil) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerSpeed = chatvars.number

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "track"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "jump <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Jump forward <number> steps or backwards if given a negative number.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "jump" and chatvars.number ~= nil) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerCount = igplayers[chatvars.playerid].trackerCount + chatvars.number
		igplayers[chatvars.playerid].trackerStopped = false
		igplayers[chatvars.playerid].trackerStop = true

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "track"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "goto start")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Move to the start of the current track.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "goto" and chatvars.words[2] == "start") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerReversed = false
		igplayers[chatvars.playerid].trackerCount = 0

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "track"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "goto end")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Move to the end of the current track.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "goto" and chatvars.words[2] == "end") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerReversed = true
		igplayers[chatvars.playerid].trackerCount = 1000000000

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "go" and chatvars.words[2] == "back") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return true
		end

		if 	igplayers[chatvars.playerid].trackerReversed == true then
			igplayers[chatvars.playerid].trackerReversed = false
		else
			igplayers[chatvars.playerid].trackerReversed = true
		end

		igplayers[chatvars.playerid].trackerStopped = false

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "track"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "stop")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Stop tracking.  Resume it with " .. server.commandPrefix .. "go")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "stop" or chatvars.words[1] == "sotp" or chatvars.words[1] == "s") and chatvars.words[2] == nil and chatvars.playerid ~= 0 then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return true
		end

		r = math.random(1,50)
		if r == 49 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]HAMMER TIME![-]")
		end

		igplayers[chatvars.playerid].trackerStopped = true
		igplayers[chatvars.playerid].following = nil
		igplayers[chatvars.playerid].location = nil
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "track"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "go")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Resume tracking.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "go" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerStopped = false
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "track"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "stop tracking")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Stops tracking and clears the tracking data from memory.  This happens when you exit the server anyway so you don't have to do this.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "stop" and chatvars.words[2] == "tracking") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerStopped = true
		conn:execute("DELETE FROM memTracker WHERE admin = " .. chatvars.playerid)
		igplayers[chatvars.playerid].trackerCount = nil

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if ((chatvars.words[1] == "check") and (chatvars.words[2] == "bases")) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerID = 0
		conn:execute("DELETE FROM memTracker WHERE admin = " .. chatvars.playerid)
		cursor,errorString = conn:execute("SELECT steam, homeX, homeY, homeZ, home2X, home2Y, home2Z from players")

		row = cursor:fetch({}, "a")
		while row do
			if tonumber(row.homeX) ~= 0 and tonumber(row.homeY) ~= 0 and tonumber(row.homeZ) ~= 0 then
				conn:execute("INSERT into memTracker (admin, steam, x, y, z, flag) VALUES (" .. chatvars.playerid .. "," .. row.steam .. "," .. row.homeX .. "," .. row.homeY .. "," .. row.homeZ .. ",'base1')")
			end

			if tonumber(row.home2X) ~= 0 and tonumber(row.home2Y) ~= 0 and tonumber(row.home2Z) ~= 0 then
				conn:execute("INSERT into memTracker (admin, steam, x, y, z, flag) VALUES (" .. chatvars.playerid .. "," .. row.steam .. "," .. row.home2X .. "," .. row.home2Y .. "," .. row.home2Z .. ",'base2')")
			end

			row = cursor:fetch(row, "a")
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bases are loaded into the tracker. Use " .. server.commandPrefix .. "nb to move forward, " .. server.commandPrefix .. "pb to move back and " .. server.commandPrefix .. "killbase to remove the current base.[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "nb" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerID = igplayers[chatvars.playerid].trackerID + 1

		cursor,errorString = conn:execute("select * from memTracker where admin = " .. chatvars.playerid .. " and trackerID > " .. igplayers[chatvars.playerid].trackerID .. " order by trackerID limit 1")
		row = cursor:fetch({}, "a")

		if row then
			send("tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z)
			igplayers[chatvars.playerid].atBase = row.steam
			igplayers[chatvars.playerid].trackerID = row.trackerID

			if row.flag == "base1" then
				igplayers[chatvars.playerid].whichBase = 1
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is base one of " .. players[igplayers[chatvars.playerid].atBase].name .. ".[-]")
			else
				igplayers[chatvars.playerid].whichBase = 2
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is base two of " .. players[igplayers[chatvars.playerid].atBase].name .. ".[-]")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "pb" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerID = igplayers[chatvars.playerid].trackerID - 1

		cursor,errorString = conn:execute("select * from memTracker where admin = " .. chatvars.playerid .. " and trackerID < " .. igplayers[chatvars.playerid].trackerID .. " order by trackerID desc limit 1")
		row = cursor:fetch({}, "a")

		if row then
			send("tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z)
			igplayers[chatvars.playerid].atBase = row.steam
			igplayers[chatvars.playerid].trackerID = row.trackerID

			if row.flag == "base1" then
				igplayers[chatvars.playerid].whichBase = 1
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is base one of " .. players[igplayers[chatvars.playerid].atBase].name .. ".[-]")
			else
				igplayers[chatvars.playerid].whichBase = 2
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is base two of " .. players[igplayers[chatvars.playerid].atBase].name .. ".[-]")
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have reached the first base.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "killbase" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		if igplayers[chatvars.playerid].atBase ~= nil then
			if tonumber(igplayers[chatvars.playerid].whichBase) == 1 then
				players[igplayers[chatvars.playerid].atBase].homeX = 0
				players[igplayers[chatvars.playerid].atBase].homeY = 0
				players[igplayers[chatvars.playerid].atBase].homeZ = 0
				players[igplayers[chatvars.playerid].atBase].protect = false

				conn:execute("UPDATE players SET homeX = 0, homeY = 0, homeZ = 0, protect = 0  WHERE steam = " .. igplayers[chatvars.playerid].atBase)

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base one of " .. players[igplayers[chatvars.playerid].atBase].name .. " has been deleted.[-]")
			else
				players[igplayers[chatvars.playerid].atBase].home2X = 0
				players[igplayers[chatvars.playerid].atBase].home2Y = 0
				players[igplayers[chatvars.playerid].atBase].home2Z = 0
				players[igplayers[chatvars.playerid].atBase].protect2 = false

				conn:execute("UPDATE players SET home2X = 0, home2Y = 0, home2Z = 0, protect2 = 0  WHERE steam = " .. igplayers[chatvars.playerid].atBase)

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Base two of " .. players[igplayers[chatvars.playerid].atBase].name .. " has been deleted.[-]")
			end
		end

		botman.faultyChat = false
		return true
	end

if debug then dbug("debug tracker end") end

end
