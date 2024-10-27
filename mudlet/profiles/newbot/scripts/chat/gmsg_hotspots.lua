--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

-- public functions

function RemoveInvalidHotspots(steam, userID)
	local dist, size, delete, k, v, cursor, errorString, row

	-- abort if staff member
	if isAdminHidden(steam, userID) then
		return
	end

	cursor,errorString = conn:execute("select * from hotspots where owner = '" .. steam .. "'")
	row = cursor:fetch({}, "a")

	while row do
		delete = true

		for k,v in pairs(bases) do
			if v.steam == steam then
				dist = distancexz(row.x, row.z, v.x, v.z)
				size = tonumber(v.protectSize)

				if (dist < tonumber(size + 16)) then
					delete = false
				end
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
	local idx, size, hotspotmsg, nextidx, debug, result, pid, help, tmp
	local shortHelp = false

	debug = false -- should be false unless testing

	calledFunction = "gmsg_hotspots"

	size = nil
	result = false
	tmp = {}
	tmp.topic = "hotspots"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## hotspot command functions ##################

	local function cmd_ResizeHotspot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}resize hotspot {hotspot number from list} size {size}"
			help[2] = "Change a hotspot's radius to a max of 10 (no max size for admins).\n"
			help[2] = help[2] .. "eg. {#}resize hotspot 3 size 5.  See {#}hotspots to get the list of hotspots."

			tmp.command = help[1]
			tmp.keywords = "hotspots,resize"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "hots") or string.find(chatvars.command, "size") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "resize" and chatvars.words[2] == "hotspot" and chatvars.words[3] ~= nil) then
			if chatvars.accessLevel == 99 then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots.[-]")
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[3] == nil) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Change a hotspot's radius to a max of 10 (unlimited for admins).[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "resize hotspot 3 size 5[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Type " .. server.commandPrefix .. "hotspots for a list of your hotspots[-]")
				botman.faultyChat = false
				return true
			end

			idx = tonumber(chatvars.words[3])
			if idx == nil then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Number required for hotspot.[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "resize hotspot 3 size 5[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Type " .. server.commandPrefix .. "hotspots for a list of your hotspots[-]")
				botman.faultyChat = false
				return true
			end


			if chatvars.words[5] ~= nil then
				size = math.abs(tonumber(chatvars.words[5])) + 1

				if chatvars.isAdminHidden then
					if size == nil or size == 1 then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Number required for size greater than 0.[-]")
						botman.faultyChat = false
						return true
					end
				else
					if size == nil or size > 11 then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Number required for size in the range 1 to 10.[-]")
						botman.faultyChat = false
						return true
					end

					size = math.floor(size) - 1
				end
			end

			hotspots[idx].size = size
			if botman.dbConnected then conn:execute("UPDATE hotspots SET size = " .. size .. " WHERE idx = " .. idx) end
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Hotspot: " .. hotspots[idx].hotspot .. " now covers " .. size * 2 .. " metres[-]")
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MoveHotspot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}move hotspot {hotspot number from list}"
			help[2] = "Move a hotspot to your current position."

			tmp.command = help[1]
			tmp.keywords = "hotspots,move"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "hots") or string.find(chatvars.command, "move") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "move" and chatvars.words[2] == "hotspot" and chatvars.words[3] ~= nil) then
			if chatvars.accessLevel == 99 then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots. (risk of swallowing small parts)[-]")
				botman.faultyChat = false
				return true
			end

			if (chatvars.number == nil) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Hotspot number required eg. " .. server.commandPrefix .. "move hotspot 25.[-]")
				botman.faultyChat = false
				return true
			end

			if not chatvars.isAdminHidden then
				if not players[chatvars.playerid].atHome then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your hotspots may be no further than " .. tonumber(server.baseSize) .. " metres from your first or second bot protected base.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.isAdminHidden then
				if hotspots[chatvars.number] then
					if botman.dbConnected then conn:execute("UPDATE hotspots SET x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. " WHERE idx = " .. chatvars.number) end
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You moved the hotspot: " .. hotspots[chatvars.number].hotspot .. "[-]")
					hotspots[chatvars.number].x = chatvars.intX
					hotspots[chatvars.number].y = chatvars.intY
					hotspots[chatvars.number].z = chatvars.intZ

					botman.faultyChat = false
					return true
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There is no hotspot #" .. chatvars.number .. ".[-]")
					botman.faultyChat = false
					return true
				end
			else
				cursor,errorString = conn:execute("select * from hotspots where idx = " .. chatvars.number)
				rows = cursor:numrows()

				if rows > 0 then
					row = cursor:fetch({}, "a")
					if row.owner ~= chatvars.playerid then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You don't own this hotspot.[-]")
						botman.faultyChat = false
						return true
					else
						if hotspots[chatvars.number] then
							conn:execute("UPDATE hotspots SET x = " .. chatvars.intX .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. " WHERE idx = " .. chatvars.number)
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You moved the hotspot: " .. hotspots[chatvars.number].hotspot .. "[-]")
							hotspots[chatvars.number].x = chatvars.intX
							hotspots[chatvars.number].y = chatvars.intY
							hotspots[chatvars.number].z = chatvars.intZ

							botman.faultyChat = false
							return true
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There is no hotspot #" .. chatvars.number .. ".[-]")
							botman.faultyChat = false
							return true
						end
					end
				end
			end
		end
	end


	local function cmd_DeleteHotspots()
		local playerName

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}delete hotspots {player name}"
			help[2] = "Players can only delete their own hotspots but admins can add a player name or id to delete the player's hotspots."

			tmp.command = help[1]
			tmp.keywords = "hotspots,delete,remove"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "hots") or string.find(chatvars.command, "del") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if ((chatvars.words[1] == "delete" or chatvars.words[1] == "remove") and chatvars.words[2] == "hotspots") then
			if chatvars.accessLevel == 99 then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots. (cancer risk)[-]")
				botman.faultyChat = false
				return true
			end

			if chatvars.isAdminHidden then
				pid = chatvars.playerid

				if chatvars.words[3] ~= nil then
					pname = string.sub(chatvars.command, string.find(chatvars.command, "hotspots ") + 10)
					pname = string.trim(pname)
					pid = LookupPlayer(pname)

					if pid == "0" then
						pid = LookupArchivedPlayer(pname)

						if not (pid == "0") then
							playerName = playersArchived[pid].name
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. pname .. ".[-]")

							botman.faultyChat = false
							return true
						end
					else
						playerName = players[pid].name
					end
				end

				if botman.dbConnected then conn:execute("DELETE FROM hotspots WHERE owner = '" .. pid .. "'") end
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You deleted the hotspots belonging to " .. playerName .. "[-]")

				-- reload the hotspots lua table
				loadHotspots()
			else
				if botman.dbConnected then conn:execute("DELETE FROM hotspots WHERE owner = '" .. chatvars.playerid .. "'") end
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Your hotspots have been deleted.[-]")

				-- reload the hotspots lua table
				loadHotspots()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_DeleteHotspot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}delete hotspot {hotspot number from list}"
			help[2] = "Delete a hotspot by its number in a list."

			tmp.command = help[1]
			tmp.keywords = "hotspots,delete,remove"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "hots") or string.find(chatvars.command, "del") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "delete" and chatvars.words[2] == "hotspot") then
			if chatvars.accessLevel == 99 then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots. (This is why we can't have nice things!)[-]")
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Hotspot number required eg. " .. server.commandPrefix .. "delete hotspot 25.[-]")
				botman.faultyChat = false
				return true
			end

			if chatvars.isAdminHidden then
				if hotspots[chatvars.number] then
					if botman.dbConnected then conn:execute("DELETE FROM hotspots WHERE idx = " .. chatvars.number) end
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You deleted the hotspot: " .. hotspots[chatvars.number].hotspot .. "[-]")
					hotspots[chatvars.number] = nil
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There is no hotspot #" .. chatvars.number .. ".[-]")
					botman.faultyChat = false
					return true
				end
			else
				cursor,errorString = conn:execute("select * from hotspots where idx = " .. chatvars.number)
				rows = cursor:numrows()

				if rows > 0 then
					row = cursor:fetch({}, "a")
					if row.owner ~= chatvars.playerid then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You don't own this hotspot.[-]")
						botman.faultyChat = false
						return true
					else
						if hotspots[chatvars.number] then
							conn:execute("DELETE FROM hotspots WHERE idx = " .. chatvars.number)
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You deleted the hotspot: " .. hotspots[chatvars.number].hotspot .. "[-]")
							hotspots[chatvars.number] = nil
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There is no hotspot #" .. chatvars.number .. ".[-]")
							botman.faultyChat = false
							return true
						end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_CreateHotspot()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}hotspot {message}"
			help[2] = "Create a hotspot at your current position with a message."

			tmp.command = help[1]
			tmp.keywords = "hotspots,create,add,set,make,message"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "hots") or string.find(chatvars.command, "add") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "hotspot") then
			if chatvars.accessLevel == 99 then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots. (that's you)[-]")
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == nil then
				botman.faultyChat = commandHelp("hotspots")
				return true
			end

			if chatvars.words[3] == nil and chatvars.number ~= nil then
				if chatvars.isAdminHidden then
					-- teleport the admin to the coords of the numbered hotspot
					cursor,errorString = conn:execute("select * from hotspots where idx = " .. chatvars.number)
					rows = cursor:numrows()

					if rows > 0 then
						row = cursor:fetch({}, "a")

						-- first record the players current position
						savePosition(chatvars.playerid)

						cmd = "tele " .. chatvars.userID .. " " .. row.x .. " " .. row.y .. " " .. row.z
						teleport(cmd, chatvars.playerid, chatvars.userID)
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There is no hotspot #" .. chatvars.number .. ".[-]")
					end

					botman.faultyChat = false
					return true
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Only admins can teleport to a hotspot.[-]")
					botman.faultyChat = false
					return true
				end
			end


			if (chatvars.number == nil) then
				if not chatvars.isAdminHidden and not players[chatvars.playerid].atHome then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You can only create hotspots in and around your base.[-]")
					botman.faultyChat = false
					return true
				end

				hotspotmsg = string.sub(chatvars.commandOld, string.find(chatvars.command, "hotspot ") + 8)
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

				conn:execute("INSERT INTO hotspots (idx, hotspot, x, y, z, owner) VALUES (" .. nextidx .. ",'" .. escape(hotspotmsg) .. "'," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",'" .. chatvars.playerid .. "')")

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You made a hotspot with the message " .. hotspotmsg .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListHotspots()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}hotspots {player name}"
			help[2] = "List your own hotspots.  Admins can list another player's hotspots."

			tmp.command = help[1]
			tmp.keywords = "hotspots,view,list"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "hots") or string.find(chatvars.command, "list") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "hotspots") then
			pid = chatvars.playerid

			if chatvars.accessLevel == 99 then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players are not allowed to play with hotspots. (You have none, nil, zip, zero, nadda)[-]")
				botman.faultyChat = false
				return true
			end

			if (chatvars.number == nil) then
				if chatvars.isAdminHidden then
					if chatvars.words[2] ~= nil then
						pname = string.sub(chatvars.command, string.find(chatvars.command, "hotspots ") + 10)
						pname = string.trim(pname)
						pid = LookupPlayer(pname)

						if pid == "0" then
							pid = LookupArchivedPlayer(pname)
						end
					else
						chatvars.number = 20
					end
				else
					pid = chatvars.playerid
				end

				if (pid == "0" and chatvars.number == nil) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found with that name.[-]")
					botman.faultyChat = false
					return true
				end

				if (pid ~= "0") then
					cursor,errorString = conn:execute("select * from hotspots where owner = '" .. pid .. "'")
					row = cursor:fetch({}, "a")

					while row do
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]#" .. row.idx .. " " .. row.hotspot .. "[-]")
						row = cursor:fetch(row, "a")
					end

					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.number ~= nil) then
				if not chatvars.isAdminHidden then
					chatvars.number = 20
					cursor,errorString = conn:execute("select * from hotspots where owner = '" .. chatvars.playerid .. "' and abs(x - " .. chatvars.intX .. ") <= " .. chatvars.number .. " and abs(y - " .. chatvars.intY .. ") <= " .. chatvars.number .. " and abs(z - " .. chatvars.intZ .. ") <= " .. chatvars.number)
				else
					if (chatvars.number == nil) then chatvars.number = 20 end
					cursor,errorString = conn:execute("select * from hotspots where abs(x - " .. chatvars.intX .. ") <= " .. chatvars.number .. " and abs(y - " .. chatvars.intY .. ") <= " .. chatvars.number .. " and abs(z - " .. chatvars.intZ .. ") <= " .. chatvars.number)
				end

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The following hotspots are within " .. chatvars.number .. " metres of you[-]")
				row = cursor:fetch({}, "a")

				while row do
					if chatvars.isAdminHidden then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]#" .. row.idx .. " " .. players[row.owner].name .. " size " .. row.size * 2 .. "m " .. row.hotspot .. "[-]")
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]#" .. row.idx .. " size " .. row.size * 2 .. "m " .. row.hotspot .. "[-]")
					end

					row = cursor:fetch(row, "a")
				end

				botman.faultyChat = false
				return true
			end
		end
	end


	local function cmd_SetHotspotAction()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}hotspot {hotspot number from list} action {action from list: pm, tele, drop, spawn}"
			help[2] = "NOTE:  This command is not finished.  Setting it won't do anything yet.\n"
			help[2] = help[2] .. "Change a hotspot's action.  The deafault is to just pm the player but it can also teleport them somewhere, spawn something or buff/debuff the player.\n"
			help[2] = help[2] .. "eg. {#}hotspot {number of hotspot} action {pm/tele/drop/spawn} {location name/spawn list}\n"
			help[2] = help[2] .. "If spawning items or entities use the format item name,quantity|item name,quantity|etc or entity id, entity id, entity id, etc"

			tmp.command = help[1]
			tmp.keywords = "hotspots,set,action"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "hots") or string.find(chatvars.command, "action") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "hotspot" and chatvars.words[3] == "action" and chatvars.words[4] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command is unfinished :([-]")

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		if debug then dbug("Registering help - hotspot commands") end

		tmp.topicDescription = "Hotspots are proximity triggered PM's that say something to an individual player.  Additional functions are being added and admins will be able to queue multiple actions when a specific hotspot is triggered."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Hotspot Commands:")
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, tmp.topicDescription)
			irc_chat(chatvars.ircAlias, ".")
		end

		cursor,errorString = connSQL:execute("SELECT count(*) FROM helpTopics WHERE topic = '" .. tmp.topic .. "'")
		row = cursor:fetch({}, "a")
		rows = row["count(*)"]

		if rows == 0 then
			connSQL:execute("INSERT INTO helpTopics (topic, description) VALUES ('" .. tmp.topic .. "', '" .. connMEM:escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false, ""
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.words[3], "hots") then
				botman.faultyChat = false
				return true, ""
			end
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and chatvars.words[1] ~= "help" and not botman.registerHelp then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Hotspot Commands (in-game only):")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "hotspots")
	end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == "0" and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false, ""
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	result = cmd_CreateHotspot()

	if result then
		if debug then dbug("debug cmd_CreateHotspot triggered") end
		return result, "cmd_CreateHotspot"
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	result = cmd_DeleteHotspot()

	if result then
		if debug then dbug("debug cmd_DeleteHotspot triggered") end
		return result, "cmd_DeleteHotspot"
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	result = cmd_DeleteHotspots()

	if result then
		if debug then dbug("debug cmd_DeleteHotspots triggered") end
		return result, "cmd_DeleteHotspots"
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListHotspots()

	if result then
		if debug then dbug("debug cmd_ListHotspots triggered") end
		return result, "cmd_ListHotspots"
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	result = cmd_MoveHotspot()

	if result then
		if debug then dbug("debug cmd_MoveHotspot triggered") end
		return result, "cmd_MoveHotspot"
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResizeHotspot()

	if result then
		if debug then dbug("debug cmd_ResizeHotspot triggered") end
		return result, "cmd_ResizeHotspot"
	end

	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetHotspotAction()

	if result then
		if debug then dbug("debug cmd_SetHotspotAction triggered") end
		return result, "cmd_SetHotspotAction"
	end

	if botman.registerHelp then
		if debug then dbug("Hotspot commands help registered") end
	end

	if debug then dbug("debug hotspots end") end

	-- can't touch dis
	if true then
		return result, ""
	end
end
