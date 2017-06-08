--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function removeInvalidHotspots(steam)
	local dist, size, delete

	-- abort if staff member
	if accessLevel(steam) < 3 then
		return
	end

	cursor,errorString = conn:execute("select * from hotspots where owner = " .. steam)
	row = cursor:fetch({}, "a")

	while row do
		delete = true
		dist = distancexz(row.x, row.z, players[steam].homeX, players[steam].homeZ)
		size = tonumber(players[steam].protectSize)

		if (dist < tonumber(size + 16)) then
			delete = false
		end

		if math.abs(players[steam].home2X) > 0 and math.abs(players[steam].home2Z) > 0 then
			dist = distancexz(row.x, row.z, players[steam].home2X, players[steam].home2Z)
			size = tonumber(players[steam].protect2Size)

			if (dist < tonumber(size + 16)) then
				delete = false
			end
		end

		if delete then
			-- remove this hotspot
			hotspots[row.idx] = nil
			conn:execute("DELETE FROM hotspots WHERE idx = " .. row.idx)
		end

		row = cursor:fetch(row, "a")
	end
end


function gmsg_hotspots()
	calledFunction = "gmsg_hotspots"

	local idx, size, hotspotmsg, nextidx, debug
	local shortHelp = false
	local skipHelp = false

	debug = false
	size = nil

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.command, "hots") then
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
		irc_chat(players[chatvars.ircid].ircAlias, "Hotspot Commands (in-game only):")
		irc_chat(players[chatvars.ircid].ircAlias, "================================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if chatvars.showHelpSections then
		irc_chat(players[chatvars.ircid].ircAlias, "hotspots")
	end

	-- ###################  do not run remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hots") or string.find(chatvars.command, "size"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "resize hotspot <hotspot number from list> size <size>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Change a hotspot's radius to a max of 10 (no max size for admins).")
				irc_chat(players[chatvars.ircid].ircAlias, "eg. " .. server.commandPrefix .. "resize hotspot 3 size 5.  See " .. server.commandPrefix .. "hotspots to get the list of hotspots.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "resize" and chatvars.words[2] == "hotspot" and chatvars.words[3] ~= nil) and (chatvars.playerid ~= 0) then
		if chatvars.accessLevel == 99 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots.[-]")
			botman.faultyChat = false
			return true
		end

		if (chatvars.words[3] == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Change a hotspot's radius to a max of 10 (unlimited for admins).[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "resize hotspot 3 size 5[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type " .. server.commandPrefix .. "hotspots for a list of your hotspots[-]")
			botman.faultyChat = false
			return true
		end

		idx = tonumber(chatvars.words[3])
		if idx == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number required for hotspot.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "resize hotspot 3 size 5[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Type " .. server.commandPrefix .. "hotspots for a list of your hotspots[-]")
			botman.faultyChat = false
			return true
		end


		if chatvars.words[5] ~= nil then
			size = math.abs(tonumber(chatvars.words[5])) + 1

			if chatvars.accessLevel < 3 then
				if size == nil or size == 1 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number required for size greater than 0.[-]")
					botman.faultyChat = false
					return true
				end
			else
				if size == nil or size > 11 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number required for size in the range 1 to 10.[-]")
					botman.faultyChat = false
					return true
				end

				size = math.floor(size) - 1
			end
		end

		hotspots[idx].size = size
		if botman.dbConnected then conn:execute("UPDATE hotspots SET size = " .. size .. " WHERE idx = " .. idx) end
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Hotspot: " .. hotspots[idx].hotspot .. " now covers " .. size * 2 .. " metres[-]")
		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hots") or string.find(chatvars.command, "move"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "move hotspot <hotspot number from list>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Move a hotspot to your current position.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "move" and chatvars.words[2] == "hotspot" and chatvars.words[3] ~= nil) and (chatvars.playerid ~= 0) then
		if chatvars.accessLevel == 99 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots.[-]")
			botman.faultyChat = false
			return true
		end

		if (chatvars.number == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Hotspot number required eg. " .. server.commandPrefix .. "move hotspot 25.[-]")
			botman.faultyChat = false
			return true
		end

		if chatvars.accessLevel > 2 then
			if not players[chatvars.playerid].atHome then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your hotspots may be no further than " .. tonumber(server.baseSize) .. " metres from your first or second bot protected base.[-]")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.accessLevel < 4 then
			if hotspots[chatvars.number] then
				if botman.dbConnected then conn:execute("UPDATE hotspots SET x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. " WHERE idx = " .. chatvars.number) end
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You moved the hotspot: " .. hotspots[chatvars.number].hotspot .. "[-]")
				hotspots[chatvars.number].x = chatvars.intX
				hotspots[chatvars.number].y = chatvars.intY
				hotspots[chatvars.number].z = chatvars.intZ

				botman.faultyChat = false
				return true
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no hotspot #" .. chatvars.number .. ".[-]")
				botman.faultyChat = false
				return true
			end
		else
			cursor,errorString = conn:execute("select * from hotspots where idx = " .. chatvars.number)
			rows = cursor:numrows()

			if rows > 0 then
				row = cursor:fetch({}, "a")
				if row.owner ~= chatvars.playerid then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't own this hotspot.[-]")
					botman.faultyChat = false
					return true
				else
					if hotspots[chatvars.number] then
						conn:execute("UPDATE hotspots SET x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. " WHERE idx = " .. chatvars.number)
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You moved the hotspot: " .. hotspots[chatvars.number].hotspot .. "[-]")
						hotspots[chatvars.number].x = chatvars.intX
						hotspots[chatvars.number].y = chatvars.intY
						hotspots[chatvars.number].z = chatvars.intZ

						botman.faultyChat = false
						return true
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no hotspot #" .. chatvars.number .. ".[-]")
						botman.faultyChat = false
						return true
					end
				end
			end
		end
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hots") or string.find(chatvars.command, "del"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "delete hotspots <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Players can only delete their own hotspots but admins can add a player name or id to delete their hotspots.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if ((chatvars.words[1] == "delete" or chatvars.words[1] == "remove") and chatvars.words[2] == "hotspots") and (chatvars.playerid ~= 0) then
		if chatvars.accessLevel == 99 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots.[-]")
			botman.faultyChat = false
			return true
		end

		if chatvars.accessLevel < 3 then
			pid = chatvars.playerid

			if chatvars.words[3] ~= nil then
				pid = string.sub(chatvars.command, string.find(chatvars.command, "hotspots ") + 10)
				pid = string.trim(pid)
				pid = LookupPlayer(pid)

				if (pid == nil) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found with that name.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if botman.dbConnected then conn:execute("DELETE FROM hotspots WHERE owner = " .. pid) end
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You deleted the hotspots belonging to " .. players[pid].name .. "[-]")
			-- reload the hotspots lua table
			loadHotspots()
		else
			if botman.dbConnected then conn:execute("DELETE FROM hotspots WHERE owner = " .. chatvars.playerid) end
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your hotspots have been deleted.[-]")
			-- reload the hotspots lua table
			loadHotspots()
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hots") or string.find(chatvars.command, "del"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "delete hotspot <hotspot number from list>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Delete a hotspot by its number.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "delete" and chatvars.words[2] == "hotspot") and (chatvars.playerid ~= 0) then
		if chatvars.accessLevel == 99 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots.[-]")
			botman.faultyChat = false
			return true
		end

		if chatvars.number == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Hotspot number required eg. " .. server.commandPrefix .. "hotspot delete 25.[-]")
			botman.faultyChat = false
			return true
		end

		if chatvars.accessLevel < 3 then
			if hotspots[chatvars.number] then
				if botman.dbConnected then conn:execute("DELETE FROM hotspots WHERE idx = " .. chatvars.number) end
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You deleted the hotspot: " .. hotspots[chatvars.number].hotspot .. "[-]")
				hotspots[chatvars.number] = nil
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no hotspot #" .. chatvars.number .. ".[-]")
				botman.faultyChat = false
				return true
			end
		else
			cursor,errorString = conn:execute("select * from hotspots where idx = " .. chatvars.number)
			rows = cursor:numrows()

			if rows > 0 then
				row = cursor:fetch({}, "a")
				if row.owner ~= chatvars.playerid then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't own this hotspot.[-]")
					botman.faultyChat = false
					return true
				else
					if hotspots[chatvars.number] then
						conn:execute("DELETE FROM hotspots WHERE idx = " .. chatvars.number)
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You deleted the hotspot: " .. hotspots[chatvars.number].hotspot .. "[-]")
						hotspots[chatvars.number] = nil
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no hotspot #" .. chatvars.number .. ".[-]")
						botman.faultyChat = false
						return true
					end
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hots"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "hotspot <message>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Create a hotspot at your current position with a message.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "hotspot") and (chatvars.playerid ~= 0) then
		if chatvars.accessLevel == 99 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots.[-]")
			botman.faultyChat = false
			return true
		end

		if chatvars.words[2] == nil then
			botman.faultyChat = help("hotspots")
			return true
		end

		if chatvars.words[3] == nil and chatvars.number ~= nil then
			if chatvars.accessLevel < 3 then
				-- teleport the admin to the coords of the numbered hotspot
				cursor,errorString = conn:execute("select * from hotspots where idx = " .. chatvars.number)
				rows = cursor:numrows()

				if rows > 0 then
					row = cursor:fetch({}, "a")

					-- first record the players current position
					savePosition(chatvars.playerid)

					cmd = "tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z
					teleport(cmd, chatvars.playerid)
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no hotspot #" .. chatvars.number .. ".[-]")
				end

				botman.faultyChat = false
				return true
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Only admins can teleport to a hotspot.[-]")
				botman.faultyChat = false
				return true
			end
		end


		if (chatvars.number == nil) then
			if chatvars.accessLevel > 2 and not players[chatvars.playerid].atHome then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can only create hotspots in and around your base.[-]")
				botman.faultyChat = false
				return true
			end

			hotspotmsg = string.sub(chatvars.commandOld, string.find(chatvars.commandOld, "hotspot ") + 8)
			hotspotmsg = string.trim(hotspotmsg)

			cursor,errorString = conn:execute("select max(idx) as max_idx from hotspots")
			row = cursor:fetch({}, "a")

			if row.max_idx ~= nil then
				nextidx = tonumber(row.max_idx) + 1
			else
				nextidx = 1
			end

			hotspots[nextidx] = {}
			hotspots[nextidx].hotspot = hotspotmsg
			hotspots[nextidx].owner = chatvars.playerid
			hotspots[nextidx].size = 2
			hotspots[nextidx].x = chatvars.intX
			hotspots[nextidx].y = chatvars.intY
			hotspots[nextidx].z = chatvars.intZ

			conn:execute("INSERT INTO hotspots (idx, hotspot, x, y, z, owner) VALUES (" .. nextidx .. ",'" .. escape(hotspotmsg) .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. "," .. chatvars.playerid .. ")")

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You made a hotspot with the message " .. hotspotmsg .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hots"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "hotspots <player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "List your own hotspots.  Admins can list another player's hotspots.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "hotspots") and (chatvars.playerid ~= 0) then
		if chatvars.accessLevel == 99 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots.[-]")
			botman.faultyChat = false
			return true
		end

		if (chatvars.number == nil) then
			if (chatvars.accessLevel < 3) then
				if chatvars.words[2] ~= nil then
					pid = string.sub(chatvars.command, string.find(chatvars.command, "hotspots ") + 10)
					pid = string.trim(pid)
					pid = LookupPlayer(pid)
				else
					chatvars.number = 20
				end
			else
				pid = chatvars.playerid
			end

			if (pid == nil and chatvars.number == nil) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found with that name.[-]")
				botman.faultyChat = false
				return true
			end

			if (pid ~= nil) then
				cursor,errorString = conn:execute("select * from hotspots where owner = " .. pid)
				row = cursor:fetch({}, "a")

				while row do
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]#" .. row.idx .. " " .. row.hotspot .. "[-]")
					row = cursor:fetch(row, "a")
				end

				botman.faultyChat = false
				return true
			end
		end

		if (chatvars.number ~= nil) then
			if (chatvars.accessLevel > 2) then
				chatvars.number = 20
				cursor,errorString = conn:execute("select * from hotspots where owner =  " .. chatvars.playerid .. " and abs(x - " .. chatvars.intX .. ") <= " .. chatvars.number .. " and abs(y - " .. chatvars.intY .. ") <= " .. chatvars.number .. " and abs(z - " .. chatvars.intZ .. ") <= " .. chatvars.number)
			else
				if (chatvars.number == nil) then chatvars.number = 20 end
				cursor,errorString = conn:execute("select * from hotspots where abs(x - " .. chatvars.intX .. ") <= " .. chatvars.number .. " and abs(y - " .. chatvars.intY .. ") <= " .. chatvars.number .. " and abs(z - " .. chatvars.intZ .. ") <= " .. chatvars.number)
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The following hotspots are within " .. chatvars.number .. " metres of you[-]")
			row = cursor:fetch({}, "a")

			while row do
				if chatvars.accessLevel < 3 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]#" .. row.idx .. " " .. players[row.owner].name .. " size " .. row.size * 2 .. "m " .. row.hotspot .. "[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]#" .. row.idx .. " size " .. row.size * 2 .. "m " .. row.hotspot .. "[-]")
				end

				row = cursor:fetch(row, "a")
			end

			botman.faultyChat = false
			return true
		end
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "hots") or string.find(chatvars.command, "action"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "resize hotspot <hotspot number from list> size <size>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Change a hotspot's action.  The deafault is to just pm the player but it can also teleport them somewhere, spawn something or buff/debuff the player.")
				irc_chat(players[chatvars.ircid].ircAlias, "eg. " .. server.commandPrefix .. "hotspot <number of hotspot> action <pm/tele/drop/spawn> <location name/spawn list>")
				irc_chat(players[chatvars.ircid].ircAlias, "If spawning items or entities use the format item name,quantity|item name,quantity|etc or entity id, entity id, entity id, etc")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "hotspot" and chatvars.words[3] == "action" and chatvars.words[4] ~= nil) and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 0) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is unfinished :([-]")

		botman.faultyChat = false
		return true
	end

if debug then dbug("debug hotspots end") end

end
