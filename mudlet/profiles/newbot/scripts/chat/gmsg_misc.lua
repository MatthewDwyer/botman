--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


--[[
bookmark commands
=============
list bookmarks
bookmark
bk
--]]


function gmsg_misc()
	calledFunction = "gmsg_misc"

	local note, pid, debug, result

	debug = false

if debug then dbug("debug misc 1") end

	if chatvars.words[1] == "list" and chatvars.words[2] == "bookmarks" then
		pid = string.sub(chatvars.command, string.find(chatvars.command, "bookmarks ") + 10)
		pid = string.trim(pid)
		pid = LookupPlayer(pid)

		if (accessLevel(chatvars.playerid) > 2) then
			pid = chatvars.playerid
		end

		if (pid == nil) then 
			if (chatvars.playername ~= "Server") then 
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found with that name.[-]")
			else
				irc_QueueMsg(players[chatvars.ircid].ircAlias, "No player found with that name.")
			end	

			faultyChat = false
			return true
		else
			cursor,errorString = conn:execute("select * from bookmarks where steam = " .. pid)
			row = cursor:fetch({}, "a")

			while row do
				if (chatvars.playername ~= "Server") then 
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]#" .. row.id .. " " .. row.x .. " " .. row.y .. " " .. row.z .. " " .. row.note .. "[-]")
				else
					irc_QueueMsg(players[chatvars.ircid].ircAlias, "#" .. row.id .. " " .. row.x .. " " .. row.y .. " " .. row.z .. " " .. row.note)
				end	

				row = cursor:fetch(row, "a")
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug misc 2") end

	if chatvars.words[1] == "get" and chatvars.words[2] == "region" and chatvars.words[3] ~=  nil then
		if ToInt(chatvars.words[3]) == nil or ToInt(chatvars.words[4]) == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Integer coordinates expected for x and z eg. /get region 123 456[-]")		
			else
				irc_QueueMsg(server.ircMain, "Integer coordinates expected for x and z eg. /get region 123 456")
			end
		else
			result = getRegion(chatvars.words[3], chatvars.words[4])

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The region at xPos " .. chatvars.words[3] .. " zPos " .. chatvars.words[4] .. " is " .. result .. "[-]")		
			else
				irc_QueueMsg(server.ircMain, "The region at xPos " .. chatvars.words[3] .. " zPos " .. chatvars.words[4] .. " is " .. result)
			end
		end

		faultyChat = false
		return true
	end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		faultyChat = false
		return false
	end
	-- ####################################################################################

if debug then dbug("debug misc 3") end

	if (chatvars.words[1] == "bookmark" and chatvars.words[2] ~= nil) then

		note = string.sub(chatvars.command, string.find(chatvars.command, "bookmark ") + 9)
		
		if note == nil then note = "" end

		conn:execute("INSERT INTO bookmarks (steam, x, y, z, note) VALUES (" .. chatvars.playerid .. "," .. math.floor(igplayers[chatvars.playerid].xPos) .. "," .. math.ceil(igplayers[chatvars.playerid].yPos) .. "," .. math.floor(igplayers[chatvars.playerid].zPos) .. ",'" .. escape(note) .. "')")
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Position added to bookmarks.[-]")	

		faultyChat = false
		return true
	end

if debug then dbug("debug misc 4") end

	if chatvars.words[1] == "bk" then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		if (chatvars.number == nil) then 
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bookmark number is required eg. /goto bookmark 5[-]")
			faultyChat = false
			return true
		else
			cursor,errorString = conn:execute("select * from bookmarks where id = " .. chatvars.number)
			rows = cursor:numrows()

			if rows > 0 then
				row = cursor:fetch({}, "a")

				-- first record their current x y z
				savePosition(chatvars.playerid)

				cmd = "tele " .. chatvars.playerid .. " " .. row.x .. " " .. row.y .. " " .. row.z
				prepareTeleport(chatvars.playerid, cmd)
				teleport(cmd, true)
			end
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug misc end") end

end
