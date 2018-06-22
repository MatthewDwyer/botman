--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug, result, tmp, r, cursor ,errorString, help
local shortHelp = false
local skipHelp = false
local filter = ""

debug = false -- should be false unless testing

function gmsg_tracker()
	calledFunction = "gmsg_tracker"
	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## tracker command functions ##################

	local function cmd_CheckBases()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}check bases"
			help[2] = "Load base coordinates into the tracker so you can tp directly to each base in sequence.  Used for visiting every single base ingame."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,base,visit,check"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or string.find(chatvars.command, "base") or string.find(chatvars.command, "visit") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if ((chatvars.words[1] == "check") and (chatvars.words[2] == "bases")) then
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
	end


	local function cmd_DeleteBase()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}killbase"
			help[2] = "Remove the current base and protection that the tracker has teleported you to.  Used with " .. server.commandPrefix .. "check base."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,base,kill,dele,remo"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or string.find(chatvars.command, "base") or string.find(chatvars.command, "remo") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "killbase" and chatvars.words[2] == nil) then
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
	end


	local function cmd_GoBack()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}go back"
			help[2] = "Remove the current base and protection that the tracker has teleported you to.  Used with " .. server.commandPrefix .. "check base."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,back,chang,dire"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or string.find(chatvars.command, "dire") or string.find(chatvars.command, "back") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "go" and chatvars.words[2] == "back") then
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
	end


	local function cmd_GotoEnd()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}goto end"
			help[2] = "Move to the end of the current track."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,end,jump,move"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or string.find(chatvars.command, "jump") or string.find(chatvars.command, "back") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "goto" and chatvars.words[2] == "end") then
			if (chatvars.accessLevel > 2) then
				botman.faultyChat = false
				return true
			end

			igplayers[chatvars.playerid].trackerReversed = true
			igplayers[chatvars.playerid].trackerCount = 1000000000

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GotoStart()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}goto start"
			help[2] = "Move to the start of the current track."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,start,jump,move"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or string.find(chatvars.command, "jump") or string.find(chatvars.command, "start") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "goto" and chatvars.words[2] == "start") then
			if (chatvars.accessLevel > 2) then
				botman.faultyChat = false
				return true
			end

			igplayers[chatvars.playerid].trackerReversed = false
			igplayers[chatvars.playerid].trackerCount = 0

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Jump()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}jump {number of steps}"
			help[2] = "Jump forward {number} steps or backwards if given a negative number."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,jump,move"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or string.find(chatvars.command, "jump") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "jump" and chatvars.number ~= nil) then
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
	end


	local function cmd_ResumeTracking()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}go"
			help[2] = "Resume tracking."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,go,cont"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "go" and chatvars.words[2] == nil) then
			if (chatvars.accessLevel > 2) then
				botman.faultyChat = false
				return true
			end

			igplayers[chatvars.playerid].trackerStopped = false
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetSpeed()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}speed {number}"
			help[2] = "The default pause between each tracked step is 3 seconds. Change it to any number of seconds from 1 to whatever."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,step,speed"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "speed" and chatvars.number ~= nil) then
			if (chatvars.accessLevel > 2) then
				botman.faultyChat = false
				return true
			end

			igplayers[chatvars.playerid].trackerSpeed = chatvars.number

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SkipSteps()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}skip {number of steps}"
			help[2] = "Skip {number} of steps.  Instead of tracking each recorded step, you will skip {number} steps for faster but less precise tracking."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,step,speed,skip"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "skip" and chatvars.number ~= nil) then
			if (chatvars.accessLevel > 2) then
				botman.faultyChat = false
				return true
			end

			igplayers[chatvars.playerid].trackerSkip = chatvars.number

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Stop()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}stop"
			help[2] = "Stop tracking.  Resume it with " .. server.commandPrefix .. "go"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,stop"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "stop" or chatvars.words[1] == "sotp" or chatvars.words[1] == "s") and chatvars.words[2] == nil and chatvars.playerid ~= 0 then
			if (chatvars.accessLevel > 2) then
				botman.faultyChat = false
				return true
			end

			r = rand(50)
			if r == 49 then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]HAMMER TIME![-]")
			end

			if igplayers[chatvars.playerid].trackerStopped ~= nil then
				if not igplayers[chatvars.playerid].trackerStopped then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Tracking stopped.[-]")
				end
			end

			if igplayers[chatvars.playerid].following ~= nil then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have stopped following " .. players[igplayers[chatvars.playerid].following].name .. ".[-]")
			end

			if igplayers[chatvars.playerid].location ~= nil then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have stopped recording random spawn points.[-]")
			end

			igplayers[chatvars.playerid].trackerStopped = true
			igplayers[chatvars.playerid].following = nil
			igplayers[chatvars.playerid].location = nil
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_StopTracking()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}stop tracking"
			help[2] = "Stops tracking and clears the tracking data from memory.  This happens when you exit the server anyway so you don't have to do this."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,stop"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "stop" and chatvars.words[2] == "tracking") then
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
	end


	local function cmd_TrackPlayer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}track {player name} session {number} (session is optional and defaults to the latest)\n"
			help[1] = " {#}track {player name} session {number} range {distance}\n"
			help[1] = help[1] .. " {#}next (track the next session)\n"
			help[1] = help[1] .. " {#}last (track the previous session)"
			help[2] = "Track the movements of a player.  If a session is given, you will track their movements from that session.\n"
			help[2] = help[2] .. "If you add the word hax, hacking or cheat the bot will only send you to coordinates that were flagged as flying or clipping."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,next,last"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if ((chatvars.words[1] == "track") or (chatvars.words[1] == "next") or (chatvars.words[1] == "last")) then
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

					if tmp.id == 0 then
						tmp.id = LookupArchivedPlayer(tmp.name)

						if not (tmp.id == 0) then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.id].name .. " was archived. There won't be any tracking data for them.[-]")
							else
								irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.id].name .. " was archived. There won't be any tracking data for them.")
							end

							botman.faultyChat = false
							return true
						end
					end

					if tmp.id ~= 0 then
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

			if tmp.id ~= 0 then
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
	end


	local function cmd_VisitNextBase()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}nb"
			help[2] = "Visit the next base in the tracker."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,next,base,visit"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "nb" and chatvars.words[2] == nil) then
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

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

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
	end


	local function cmd_VisitPreviousBase()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}pb"
			help[2] = "Visit the previous base in the tracker."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "track,prev,base,visit"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "track") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "pb" and chatvars.words[2] == nil) then
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

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

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
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - tracker commands ====")
		dbug("Registering help - tracker commands")

		tmp = {}
		tmp.topicDescription = "All player movement is recorded every 3 seconds.\n"
		tmp.topicDescription = tmp.topicDescription .. "The tracker allows admins to follow a player's movements now or in the past so long as there is tracking data recorded.\n"
		tmp.topicDescription = tmp.topicDescription .. "The tracker can also be used to visit every recorded player base using special commands.\n"
		tmp.topicDescription = tmp.topicDescription .. "The tracker runs slowly by default to give admins time to look around and time to command the tracker. Several controls are available to change speed, direction and more."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'tracker'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('tracker', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

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
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Tracker Commands:")
		irc_chat(chatvars.ircAlias, "=================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "tracker")
	end

	if debug then dbug("debug tracker end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == 0 and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

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

	result = cmd_TrackPlayer()

	if result then
		if debug then dbug("debug cmd_TrackPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_SkipSteps()

	if result then
		if debug then dbug("debug cmd_SkipSteps triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetSpeed()

	if result then
		if debug then dbug("debug cmd_SetSpeed triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_Jump()

	if result then
		if debug then dbug("debug cmd_Jump triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_GotoStart()

	if result then
		if debug then dbug("debug cmd_GotoStart triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_GotoEnd()

	if result then
		if debug then dbug("debug cmd_GotoEnd triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_GoBack()

	if result then
		if debug then dbug("debug cmd_GoBack triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_Stop()

	if result then
		if debug then dbug("debug cmd_Stop triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResumeTracking()

	if result then
		if debug then dbug("debug cmd_ResumeTracking triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_StopTracking()

	if result then
		if debug then dbug("debug cmd_StopTracking triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_CheckBases()

	if result then
		if debug then dbug("debug cmd_CheckBases triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_VisitNextBase()

	if result then
		if debug then dbug("debug cmd_VisitNextBase triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_VisitPreviousBase()

	if result then
		if debug then dbug("debug cmd_VisitPreviousBase triggered") end
		return result
	end

	if (debug) then dbug("debug tracker line " .. debugger.getinfo(1).currentline) end

	result = cmd_DeleteBase()

	if result then
		if debug then dbug("debug cmd_DeleteBase triggered") end
		return result
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Tracker commands help registered ****")
		dbug("Tracker commands help registered")
		topicID = topicID + 1
	end

	if debug then dbug("debug tracker end") end

	-- can't touch dis
	if true then
		return result
	end
end
