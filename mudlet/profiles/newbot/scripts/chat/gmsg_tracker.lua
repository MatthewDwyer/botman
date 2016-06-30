--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
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

	debug = false

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
		return false
	end
	
	if chatvars.showHelp then
		if chatvars.words[3] then		
			if chatvars.words[3] ~= "tracker" then
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
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "Tracker Commands:")	
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "=================")
		irc_QueueMsg(players[chatvars.ircid].ircAlias, "")	
	end


	-- ###################  do not allow remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then 
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return false
		end
	end
	-- ##################################################################

if debug then dbug("debug tracker 1") end

	if (chatvars.words[1] == "skip" and chatvars.number ~= nil) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerSkip = chatvars.number

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 2") end

	if (chatvars.words[1] == "speed" and chatvars.number ~= nil) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerSpeed = chatvars.number

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 3") end

	if (chatvars.words[1] == "forward" or chatvars.words[1] == "advance" and chatvars.number ~= nil) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerCount = igplayers[chatvars.playerid].trackerCount + chatvars.number
		igplayers[chatvars.playerid].trackerStopped = false
		igplayers[chatvars.playerid].trackerStop = true

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 4") end

	if (chatvars.words[1] == "back" and chatvars.number ~= nil) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerCount = igplayers[chatvars.playerid].trackerCount - chatvars.number
		igplayers[chatvars.playerid].trackerStopped = false
		igplayers[chatvars.playerid].trackerStop = true

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 5") end

	if (chatvars.words[1] == "goto" and chatvars.words[2] == "start") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerReversed = false
		igplayers[chatvars.playerid].trackerCount = 0

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 6") end

	if (chatvars.words[1] == "goto" and chatvars.words[2] == "end") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerReversed = true
		igplayers[chatvars.playerid].trackerCount = 1000000000

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 7") end

	if (chatvars.words[1] == "go" and chatvars.words[2] == "back") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return true
		end

		if 	igplayers[chatvars.playerid].trackerReversed == true then
			igplayers[chatvars.playerid].trackerReversed = false
		else
			igplayers[chatvars.playerid].trackerReversed = true
		end

		igplayers[chatvars.playerid].trackerStopped = false

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 8") end

	if (chatvars.words[1] == "stop" or chatvars.words[1] == "sotp" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return true
		end

		r = rand(100)
		if r == 99 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]HAMMER TIME![-]")
		end

		igplayers[chatvars.playerid].trackerStopped = true
		igplayers[chatvars.playerid].following = nil
		igplayers[chatvars.playerid].location = nil
		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 9") end

	if (chatvars.words[1] == "go" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerStopped = false
		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 10") end

	if (chatvars.words[1] == "stop" and chatvars.words[2] == "tracking") and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			faultyChat = false
			return true
		end

		igplayers[chatvars.playerid].trackerStopped = true
		conn:execute("DELETE FROM memTracker WHERE admin = " .. chatvars.playerid)
		igplayers[chatvars.playerid].trackerCount = nil

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 11") end

	if ((chatvars.words[1] == "track") or (chatvars.words[1] == "next") or (chatvars.words[1] == "last")) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		conn:execute("DELETE FROM memTracker WHERE admin = " .. chatvars.playerid)

		igplayers[chatvars.playerid].trackerStopped = false
		igplayers[chatvars.playerid].trackerReversed = false

		if igplayers[chatvars.playerid].trackerSpeed == nil then
			igplayers[chatvars.playerid].trackerSpeed = 3
		end

		if igplayers[chatvars.playerid].trackerSkip == nil then
			igplayers[chatvars.playerid].trackerSkip = 1
		end

		if (chatvars.words[1] ~= "next") and (chatvars.words[1] ~= "last") then
			igplayers[chatvars.playerid].trackerCountdown = igplayers[chatvars.playerid].trackerSpeed
			igplayers[chatvars.playerid].trackerCount = 0
			igplayers[chatvars.playerid].trackerSteam = 0
			igplayers[chatvars.playerid].trackerSession = 0
			id = nil
		
			if string.find(chatvars.command, "session") then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "track") + 6, string.find(chatvars.command, "session") - 1)
				pname = string.trim(pname)
				id = LookupPlayer(pname)
				igplayers[chatvars.playerid].trackerSession = string.sub(chatvars.command, string.find(chatvars.command, "session") + 8)

				if id ~= nil then
					igplayers[chatvars.playerid].trackerSteam = id
				end
			else
				pname = string.sub(chatvars.command, string.find(chatvars.command, "track ") + 6)
				pname = string.trim(pname)
				id = LookupPlayer(pname)

				if id ~= nil then
					igplayers[chatvars.playerid].trackerSession = players[id].sessionCount
					igplayers[chatvars.playerid].trackerSteam = id
				end
			end
		else
			id = igplayers[chatvars.playerid].trackerSteam

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
		end

		if id ~= nil then
			conn:execute("INSERT into memTracker (SELECT trackerID, " .. chatvars.playerid .. " AS admin, steam, timestamp, x, y, z, SESSION , flag from tracker where steam = " .. id .. " and session = " .. igplayers[chatvars.playerid].trackerSession .. ")")					
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player called " .. pname .. " found.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 12") end

	if ((chatvars.words[1] == "check") and (chatvars.words[2] == "bases")) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
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

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bases are loaded into the tracker. Use /nb to move forward, /pb to move back and /killbase to remove the current base.[-]")

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 13") end

	if (chatvars.words[1] == "nb" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
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

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 14") end

	if (chatvars.words[1] == "pb" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
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

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker 15") end

	if (chatvars.words[1] == "killbase" and chatvars.words[2] == nil) and (chatvars.playerid ~= 0) then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
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

		faultyChat = false
		return true
	end

if debug then dbug("debug tracker end") end

end
