--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_unslashed()
	calledFunction = "gmsg_unslashed"

	local debug

	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false

if debug then dbug("debug unslashed") end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		faultyChat = false
		return false
	end
	-- ####################################################################################

if debug then 
	dbug(chatvars.playername)
end

	-- ###################  do not allow the bot to respond to itself ################
	if string.sub(chatvars.command, 1, 1) ~= "/" and chatvars.playername == "Server" then
		faultyChat = false
		return true
	end
	-- ####################################################################################

	-- #################  do not proceed if the line starts with a slash  #################
	if (string.sub(chatvars.command, 1, 1) == "/") then
		-- line starts with a slash so stop processing it.
		faultyChat = false
		return false
	end
	-- ####################################################################################

if debug then dbug("debug unslashed 0") end

	if igplayers[chatvars.playerid].botQuestion == "pay player" then
		payPlayer()

		faultyChat = false
		return true
	end

if debug then dbug("debug unslashed 1") end

	if (chatvars.playername ~= "Server") then
		if igplayers[chatvars.playerid].botQuestion == "reset server" and chatvars.words[1] == "yes" and accessLevel(chatvars.playerid) == 0 then
			message("say [" .. server.chatColour .. "]Deleting all bot data and restarting it..[-]")
			ResetServer()

			igplayers[chatvars.playerid].botQuestion = ""
			igplayers[chatvars.playerid].botQuestionID = nil
			igplayers[chatvars.playerid].botQuestionValue = nil
			faultyChat = false
			return true
		end
	end


	if (chatvars.playername ~= "Server") then
		if igplayers[chatvars.playerid].botQuestion == "reset bot" and chatvars.words[1] == "yes" and accessLevel(chatvars.playerid) == 0 then
			ResetBot()
			message("say [" .. server.chatColour .. "]I have been reset.  All bases, inventories etc are forgotten, but not the players.[-]")

			igplayers[chatvars.playerid].botQuestion = ""
			igplayers[chatvars.playerid].botQuestionID = nil
			igplayers[chatvars.playerid].botQuestionValue = nil
			faultyChat = false
			return true
		end
	end

	if (string.find(chatvars.command, "build") and string.find(chatvars.command, "reset")) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset zones are deleted and regenerate with random POIs and prefabs.  Anything you build there will be lost.  Resets are done manually.[-]")
		faultyChat = false
		return true
	end

if debug then dbug("debug unslashed 2") end

	if (string.find(chatvars.command, "wait") and scheduledRestartForced == false and (server.scheduledRestartTimestamp - os.time() < 61)) then
		scheduledRestartForced = true

		if rebootTimerID ~= nil and rebootTimerDelayID == nil then
			disableTimer(rebootTimerID)
			rebootTimerDelayID = tempTimer( 60, [[enableTimer(]] .. rebootTimerID .. [[)]] )
			message("say [" .. server.chatColour .. "]The scheduled reboot has been delayed for 2 minutes.[-]")
			rebootTimer = rebootTimer + 120
		end

		if server.scheduledRestart == true then
			server.scheduledRestartTimestamp = server.scheduledRestartTimestamp + 120
			message("say [" .. server.chatColour .. "]The scheduled reboot has been delayed for 2 minutes.[-]")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug unslashed 3") end

	if (string.find(chatvars.command, "when") and string.find(chatvars.command, "feral")) then
		if (gameDay % 7 == 0) then
			message("say [" .. server.chatColour .. "]Feral hordes will run tonight![-]")
			faultyChat = false
			return true
		end

		if ((gameDay + 1) % 7 == 0) then
			message("say [" .. server.chatColour .. "]Feral hordes are expected tomorrow[-]")
			faultyChat = false
			return true
		end

		if ((gameDay + 2) % 7 == 0) then
			message("say [" .. server.chatColour .. "]Feral hordes are expected in 2 days[-]")
			faultyChat = false
			return true
		end

		if ((gameDay + 3) % 7 == 0) then
			message("say [" .. server.chatColour .. "]Feral hordes are expected in 3 days[-]")
			faultyChat = false
			return true
		end

		if ((gameDay + 4) % 7 == 0) then
			message("say [" .. server.chatColour .. "]Feral hordes are expected in 4 days[-]")
			faultyChat = false
			return true
		end

		if ((gameDay + 5) % 7 == 0) then
			message("say [" .. server.chatColour .. "]Feral hordes are expected in 5 days[-]")
			faultyChat = false
			return true
		end

		if ((gameDay + 6) % 7 == 0) then
			message("say [" .. server.chatColour .. "]Feral hordes are expected in 6 days[-]")
			faultyChat = false
			return true
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug unslashed 4") end

	if (chatvars.words[2] == "server" or chatvars.words[2] == "bot" or chatvars.words[2] == string.lower(server.botName)) and (chatvars.words[3] == nil) and (chatvars.playername ~= "Server") then
		if (chatvars.words[1] == "thanks" or chatvars.words[1] == "ty" or string.find(chatvars.words[1], "thx")) then
			message("say [" .. server.chatColour .. "]You're welcome " .. chatvars.playername .. " <3[-]")
		else
			r = rand(18)

			if r < 6 then
				message("say [" .. server.chatColour .. "]" .. chatvars.words[1]:gsub("^%l", string.upper)  .. " " .. chatvars.playername .. "[-]")
				faultyChat = false
				return true
			end

			if string.find(chatvars.words[1], "love") then
				l = rand(5)
				if l == 1 then message("say [" .. server.chatColour .. "]I know.[-]") end
				if l == 2 then message("say [" .. server.chatColour .. "]Thanks =D.[-]") end
				if l == 3 then message("say [" .. server.chatColour .. "]I love you too :3[-]") end
				if l == 4 then message("say [" .. server.chatColour .. "]PDA!  PDA![-]") end
				if l == 5 then message("say [" .. server.chatColour .. "]" .. chatvars.words[1]:gsub("^%l", string.upper)  .. " " .. chatvars.playername .. "[-]") end

				faultyChat = false
				return true
			end

			if string.find(chatvars.words[1], "pretty") then
				l = rand(4)
				if l == 1 then message("say [" .. server.chatColour .. "]" .. chatvars.words[1]:gsub("^%l", string.upper)  .. " " .. chatvars.playername .. "[-]") end
				if l == 2 then message("say [" .. server.chatColour .. "]I know.[-]") end
				if l == 3 then message("say [" .. server.chatColour .. "]Thanks :>[-]") end
				if l == 4 then message("say [" .. server.chatColour .. "]O.o[-]") end

				faultyChat = false
				return true
			end

			if string.find(chatvars.words[1], "cool") or string.find(chatvars.words[1], "great")then
				l = rand(3)
				if l == 1 then message("say [" .. server.chatColour .. "]Thanks " .. chatvars.playername .. "![-]") end
				if l == 2 then message("say [" .. server.chatColour .. "]Indeed.[-]") end
				if l == 3 then message("say [" .. server.chatColour .. "]I know.[-]") end

				faultyChat = false
				return true
			end

			if r == 6 then
				message("say [" .. server.chatColour .. "]Yo no hablo inglés[-]")
			end

			if r == 7 then
				message("say [" .. server.chatColour .. "]You again?[-]")
			end

			if r == 8 then
				message("say [" .. server.chatColour .. "]*sigh*  Next![-]")
			end

			if r == 9 then
				message("say [" .. server.chatColour .. "]I DIDN'T DO IT!  YOU CAN'T PROVE A THING![-]")
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
				message("say [" .. server.chatColour .. "]¿Hablas español?[-]")
			end

			if r == 17 then
				message("say [" .. server.chatColour .. "]o.O[-]")
			end

			if r == 18 then
				message("say [" .. server.chatColour .. "]O.o[-]")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug unslashed 5") end

	if players[chatvars.playerid].newPlayer == true and (string.find(chatvars.command, "where") or (string.find(chatvars.command, "any"))) and (string.find(chatvars.command, "zed") or string.find(chatvars.command, "zom")) then
		r = rand(7)
		if (r == 2) then r = 3 end
		if (r == 5) then r = 6 end

		send("se " .. igplayers[chatvars.playerid].id .. " " .. r)

		faultyChat = false
		return true
	end

if debug then dbug("debug unslashed 6") end

	if (string.find(chatvars.command, "server")) and (string.find(chatvars.command, "suck") or string.find(chatvars.command, "stupid") or string.find(chatvars.command, "gay")) then
		r = rand(4)
		if (r == 1) then message("say [" .. server.chatColour .. "]Look who's talking :P[-]") end
		if (r == 2) then message("say [" .. server.chatColour .. "]Just ragequit! :)[-]") end
		if (r == 3) then message("say [" .. server.chatColour .. "]This is not the server you are looking for.  Move along.  Move along.[-]") end
		if (r == 4) then message("say [" .. server.chatColour .. "]Let me guess, did someone steal your sweet roll?[-]") end
		faultyChat = false
		return true
	end

if debug then dbug("debug unslashed 7") end

	if (string.find(chatvars.command, "when") or string.find(chatvars.command, "next")) and string.find(chatvars.command, "reboot") then
		if server.delayReboot then
			message("say [" .. server.chatColour .. "]Feral hordes run today so the reboot is suspended until midnight.[-]")
		else
			nextReboot()
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug unslashed end") end

end
