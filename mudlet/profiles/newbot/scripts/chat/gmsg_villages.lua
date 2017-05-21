--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_villages()
	calledFunction = "gmsg_villages"

	local debug
	local shortHelp = false
	local skipHelp = false

	debug = false

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.words[3], "vill") then
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
		irc_chat(players[chatvars.ircid].ircAlias, "Village Commands:")
		irc_chat(players[chatvars.ircid].ircAlias, "=================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if chatvars.showHelpSections then
		irc_chat(players[chatvars.ircid].ircAlias, "villages")
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "elect" and chatvars.words[2] ~= nil) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false				return true
			end
		end

		if (string.find(chatvars.command, "village")) then
			name1 = string.sub(chatvars.command, string.find(chatvars.command, "elect") + 6, string.find(chatvars.command, "village") - 1)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			villageName = string.sub(chatvars.command, string.find(chatvars.command, "village") + 8)
			villageName = string.trim(villageName)

			vid = LookupLocation(villageName)
			if vid == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no village called " .. villageName .. "[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "There is no village called " .. villageName)
				end

				botman.faultyChat = false
				return true
			end

			if (pid ~= nil) then
				if locations[villageName] ~= nil then
					locations[villageName].mayor = pid
					locations[villageName].owner = pid
					locations[villageName].village = true
					message("say [" .. server.chatColour .. "]Congratulations " .. players[pid].name .. " on becoming the new mayor of " .. villageName .. "[-]")

					r = rand(5)

					if r == 1 then message("say [" .. server.chatColour .. "]The best village in all the land.[-]") end
					if r == 2 then message("say [" .. server.chatColour .. "]Now you can show those home owner associations how it's really done![-]") end
					if r == 3 then message("say [" .. server.chatColour .. "]GLORY TO " .. string.upper(villageName) .. "![-]") end
					if r == 4 then message("say [" .. server.chatColour .. "]Have fun sorting out all the spats, petty squabbles, and other fun social misadventures xD[-]") end
					if r == 5 then message("say [" .. server.chatColour .. "]Now add surfs, slaves, wenches and someone to put the bottles out.[-]") end

					conn:execute("UPDATE locations SET village = true, mayor = " .. pid .. ", owner = " .. pid .. " WHERE name = '" .. escape(villageName) .. "'")
					conn:execute("INSERT INTO villagers SET steam = " .. pid .. ", village = '" .. escape(villageName) .. "'")

					villagers[pid .. vid] = {}
					villagers[pid .. vid].village = villageName
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "add" and chatvars.words[2] == "member") then
		if (string.find(chatvars.command, "village")) then
			name1 = string.sub(chatvars.command, string.find(chatvars.command, "member") + 7, string.find(chatvars.command, "village") - 1)
			name1 = string.trim(name1)

			pid = LookupPlayer(name1)

			villageName = string.sub(chatvars.command, string.find(chatvars.command, "village") + 8)
			villageName = string.trim(villageName)

			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) and (locations[villageName].mayor ~= chatvars.playerid) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			end

			vid = LookupLocation(villageName)
			if vid == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no village called " .. villageName .. "[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, "There is no village called " .. villageName)
				end

				botman.faultyChat = false
				return true
			end

			if locations[vid].village ~= true then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. villageName .. " is not a village.[-]")
				else
					irc_chat(players[chatvars.ircid].ircAlias, villageName .. " is not a village.")
				end

				botman.faultyChat = false
				return true
			end

			if (pid ~= nil) then
				conn:execute("INSERT INTO villagers SET steam = " .. pid .. ", village = '" .. escape(villageName) .. "'")

				villagers[pid .. vid] = {}
				villagers[pid .. vid].village = villageName

				message("say [" .. server.chatColour .. "]" .. players[pid].name .. " is now a member of " .. villageName .. " village.[-]")

				if (chatvars.playername ~= "Server") then
					irc_chat(players[chatvars.ircid].ircAlias, players[pid].name .. " is now a member of " .. villageName .. " village.")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "remove" and chatvars.words[2] == "village") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		end

		villageName = string.trim(string.sub(chatvars.command, string.find(chatvars.command, "village ") + 8))

		vid = LookupLocation(villageName)
		if vid == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no village called " .. villageName .. "[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "There is no village called " .. villageName)
			end

			botman.faultyChat = false
			return true
		end

		locations[vid] = nil

		conn:execute("DELETE FROM villagers WHERE village = '" .. escape(vid) .. "'")
		conn:execute("DELETE FROM locations WHERE name = '" .. escape(vid) .. "'")

		for k, v in pairs(villagers) do
			if (v.villageName == vid) then
				k = nil
			end
		end

		if (chatvars.playername ~= "Server") then
			message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " has removed a village portal called " .. vid .. "[-]")
		else
			message("say [" .. server.chatColour .. "]A village called " .. vid .. " has been removed.[-]")
			irc_chat(players[chatvars.ircid].ircAlias, "A village called " .. vid .. " has been removed.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "village") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		end

		villageName = string.trim(string.sub(chatvars.command, string.find(chatvars.command, "village ") + 8, string.find(chatvars.command, "size") - 1))

		vid = LookupLocation(villageName)
		if vid == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no village called " .. villageName .. "[-]")
			botman.faultyChat = false
			return true
		end

		baseprotection = tonumber(string.sub(chatvars.command, string.find(chatvars.command, "size ") + 5))
		if (baseprotection == nil) then
			baseprotection = 50
		end

		if (locations[vid]) then
			locations[vid].size = baseprotection
			locations[vid].protect = false
			message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " has set village protection to " .. baseprotection .. " meters for village " .. vid .. "[-]")
			conn:execute("UPDATE locations SET size = " .. baseprotection .. ", protect=0 WHERE name = '" .. escape(vid) .. "'")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "remove" and chatvars.words[2] == "member") then
		if (string.find(chatvars.command, "village")) then
			name1 = string.sub(chatvars.command, string.find(chatvars.command, "member") + 7, string.find(chatvars.command, "village") - 1)
			name1 = string.trim(name1)
			pid = LookupPlayer(name1)

			villageName = string.sub(chatvars.command, string.find(chatvars.command, "village") + 8)
			villageName = string.trim(villageName)

			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) and (locations[villageName].mayor ~= chatvars.playerid) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			end

			vid = LookupLocation(villageName)
			if vid == nil then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no village called " .. villageName .. "[-]")
				botman.faultyChat = false
				return true
			end

			if (pid ~= nil) then
				conn:execute("DELETE FROM villagers WHERE village = '" .. escape(vid) .. "' and steam = " .. pid)
				villagers[pid .. vid] = nil
				message("say [" .. server.chatColour .. "]" .. players[pid].name .. " has been cast out of village " .. vid .. "[-]")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "villages" and chatvars.words[2] == nil) then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]List of villages:[-]")

		for k, v in pairs(locations) do
			if (v.village == true) then
				pid = nil

				if v.mayor ~= nil then
					pid = LookupOfflinePlayer(v.mayor)
				end

				if pid ~= nil then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " the Mayor is " .. players[pid].name .. "[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. "[-]")
				end
			end
		end

		botman.faultyChat = false
		return true
	end


	if (chatvars.words[1] == "villagers") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]List of villagers:[-]")

		villageName = nil
		if (chatvars.words[2] ~= nil) then
			villageName = string.sub(chatvars.command, string.find(chatvars.command, "villagers ") + 10)
		end

		if villageName ~= nil then
			villageName = string.trim(villageName)
			cursor1,errorString = conn:execute("SELECT * FROM locations WHERE name = '" .. escape(villageName) .."' and village = 1")
		else
			cursor1,errorString = conn:execute("SELECT * FROM locations WHERE village = 1")
		end

		row1 = cursor1:fetch({}, "a")
		while row1 do
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The village of " .. row1.name .. "[-]")

			cursor2,errorString = conn:execute("SELECT * FROM villagers WHERE village = '" .. escape(row1.name) .."'")
			row2 = cursor2:fetch({}, "a")
			while row2 do
				if row1.mayor == row2.steam then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[row2.steam].name .. "  (The Mayor)[-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[row2.steam].name .. "[-]")
				end
				row2 = cursor2:fetch(row2, "a")
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "][-]")

			row1 = cursor1:fetch(row1, "a")
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "][-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not allow remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

	if (chatvars.words[1] == "add" and chatvars.words[2] == "village") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		villageName = string.trim(string.sub(chatvars.command, string.find(chatvars.command, "village ") + 8))

		if not locations[villageName] then
			locations[villageName] = {}
			locations[villageName].name = villageName
			locations[villageName].owner = chatvars.playerid
			locations[villageName].x = chatvars.intX
			locations[villageName].y = chatvars.intY
			locations[villageName].z = chatvars.intZ
			locations[villageName].size = server.baseSize
			locations[villageName].active = true
			locations[villageName].public = false
			locations[villageName].village = true
			locations[villageName].mayor = 0
			message("say [" .. server.chatColour .. "]" .. chatvars.playername .. " has created a village portal called " .. villageName .. "[-]")
			message("say [" .. server.chatColour .. "]" .. villageName .. " needs villagers and a mayor.[-]")

			conn:execute("INSERT INTO locations (name, owner, x, y, z, village, size) VALUES ('" .. escape(villageName) .. "'," .. chatvars.playerid .. "," .. chatvars.intX .. "," .. chatvars.intY .. "," .. chatvars.intZ .. ",1," .. server.baseSize .. ") ON DUPLICATE KEY UPDATE x = " .. chatvars.intZ .. ", y = " .. chatvars.intY .. ", z = " .. chatvars.intZ .. ", village=1, size=" .. server.baseSize)
			-- refresh the locations lua table.  also makes it fill in missing properties.
			loadLocations(villageName)
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. villageName .. " already exists.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "protect" and chatvars.words[2] == "village" and chatvars.words[3] ~= nil) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		if (chatvars.words[2] ~= nil) then
			pname = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "village") + 8)
			pname = stripQuotes(string.trim(pname))
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You need to tell me the name of the village you are protecting.[-]")
		end

		dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, locations[pname].x, locations[pname].z)

		if (dist <  tonumber(locations[pname].size) + 1) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are too close to the village, but just walk away and I will set it when you are far enough.[-]")
			igplayers[chatvars.playerid].alertLocationExit = pname
			botman.faultyChat = false
			return true
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "unprotect" and (chatvars.words[2] == "village") and chatvars.words[3] ~= nil) and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		end

		if (chatvars.words[2] ~= nil) then
			pname = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "village") + 8)
			pname = string.trim(pname)

			if locations[pname] then
				locations[pname].protect = false
				conn:execute("UPDATE locations SET protect = 0 WHERE name = '" .. escape(pname) .. "'")
				message("say [" .. server.chatColour .. "]Protection has been removed from " .. pname .. ".[-]")
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You need to tell me the name of the village you are removing protection from.[-]")
		end

		botman.faultyChat = false
		return true
	end

if debug then dbug("debug villages end") end

end
