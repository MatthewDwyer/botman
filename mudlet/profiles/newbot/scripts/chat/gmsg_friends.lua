--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_friends()
	calledFunction = "gmsg_friends"

	local pid, pname, debug, max

	debug = false

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

if debug then dbug("debug friends") end

	if (chatvars.words[1] == "player") and string.find(chatvars.command, " friend ") and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		tmp = {}

		tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7, string.find(chatvars.command, " friend ") - 1)
		tmp.pname = string.trim(tmp.pname)
		tmp.pid = LookupPlayer(tmp.pname)

		tmp.fname = string.sub(chatvars.command, string.find(chatvars.command, " friend ") + 8)
		tmp.fname = string.trim(tmp.fname)
		tmp.fid = LookupPlayer(tmp.fname)

		if (tmp.pid == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No match for " .. tmp.pname .. "[-]")
			botman.faultyChat = false
			return true
		end

		if (tmp.fid == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No match for " .. tmp.fname .. "[-]")
			botman.faultyChat = false
			return true
		end

		-- add to friends table
		if (friends[tmp.pid].friends == nil) then
			friends[tmp.pid] = {}
			friends[tmp.pid].friends = ""
		end

		if addFriend(tmp.pid, tmp.fid, false) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. " is now friends with " .. players[tmp.fid].name .. "[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. " is already friends with " .. players[tmp.fid].name .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "friend") and (chatvars.playerid ~= 0) then
		pname = string.sub(chatvars.command, string.find(chatvars.command, "friend ") + 7)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Imaginary friends don't count.  Pick someone that exists.[-]")
			botman.faultyChat = false
			return true
		end

		if (id == chatvars.playerid) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I know you are lonely but you're supposed to make friends with OTHER people.[-]")
			botman.faultyChat = false
			return true
		end

		-- add to friends table
		if (friends[chatvars.playerid].friends == nil) then
			friends[chatvars.playerid] = {}
			friends[chatvars.playerid].friends = ""
		end

		if addFriend(chatvars.playerid, id, false) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is now recognised as a friend[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are already friends with " .. players[id].name .. ".[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "clear" and chatvars.words[2] == "friends") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel < 3) then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "friends") + 8)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id ~= nil then
				-- reset the players friends list
				friends[id] = {}
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " have no friends :([-]")

				conn:execute("DELETE FROM friends WHERE steam = " .. id)

				botman.faultyChat = false
				return true
			end
		end

		-- reset the players friends list
		friends[chatvars.playerid] = {}
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no friends :([-]")

		conn:execute("DELETE FROM friends WHERE steam = " .. chatvars.playerid)

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "unfriend") and (chatvars.playerid ~= 0) then
		if chatvars.words[2] == nil then
			botman.faultyChat = help("help friends", chatvars.playerid)
			return true
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "unfriend ") + 9)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		-- unfriend someone
		if (friends[chatvars.playerid] == nil or friends[chatvars.playerid] == {}) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no friends :([-]")
			botman.faultyChat = false
			return true
		end

		if (id ~= nil) then
			-- check to see if this friend was auto friended and warn the player that they must unfriend them via the game.
			dbugi("select * from friends where steam = " .. chatvars.playerid .. " AND friend = " .. id .. " AND autoAdded = 1")
			cursor,errorString = conn:execute("select * from friends where steam = " .. chatvars.playerid .. " AND friend = " .. id .. " AND autoAdded = 1")
			row = cursor:fetch({}, "a")

			if row then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You need to unfriend " .. players[id].name .. " via the game since the bot can't unfriend them from there for you.[-]")
				botman.faultyChat = false
				return true
			end		
		
		
			friendlist = string.split(friends[chatvars.playerid].friends, ",")

			-- now simply rebuild friend skipping over the one we are removing
			friends[chatvars.playerid].friends = ""
			max = table.maxn(friendlist)
			for i=1,max,1 do
				if (friendlist[i] ~= id) and friendlist[i] ~= "" then
					if friends[chatvars.playerid].friends == "" then
						friends[chatvars.playerid].friends = friendlist[i]
					else
						friends[chatvars.playerid].friends = friends[chatvars.playerid].friends .. "," .. friendlist[i]
					end
				end
			end

			conn:execute("DELETE FROM friends WHERE steam = " .. chatvars.playerid .. " AND friend = " .. id)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are no longer friends with " .. players[id].name .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "friendme") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "friendme ") + 9)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id ~= nil) then
			if (not isFriend(id, chatvars.playerid)) then
				if friends[id].friends == "" then
					friends[id].friends = chatvars.playerid
				else
					friends[id].friends = friends[id].friends .. "," .. chatvars.playerid
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " now lists you as a friend.[-]")
				conn:execute("INSERT INTO friends (steam, friend) VALUES (" .. id .. "," .. chatvars.playerid .. ")")

				botman.faultyChat = false
				return true
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are already a friend of " .. players[id].name .. ".[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "friends") and (chatvars.playerid ~= 0) then
		pid = chatvars.playerid

		if chatvars.accessLevel > 2  and chatvars.words[2] ~= nil then
			botman.faultyChat = false
			return true
		end

		if chatvars.accessLevel < 3  and chatvars.words[2] ~= nil then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "friends") + 8, string.len(chatvars.command))
			pid = LookupPlayer(pname)
		end

		-- pm a list of all the players friends
		if (friends[pid] == nil) or friends[pid].friends == "" then
			if (pid == chatvars.playerid) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no friends :([-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[pid].name .. "  has no friends.[-]")
			end

			botman.faultyChat = false
			return true
		end

		friendlist = string.split(friends[pid].friends, ",")

		if (pid == chatvars.playerid) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are friends with..[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[pid].name .. " is friends with..[-]")
		end

		max = table.maxn(friendlist)
		for i=1,max,1 do
			if (friendlist[i] ~= "") then
				id = LookupPlayer(friendlist[i])
				if id ~= nil then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. "[-]")
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	if (chatvars.words[1] == "unfriendme") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. restrictedCommandMessage() .. "[-]")
			botman.faultyChat = false
			return true
		end

		id = 0

		if chatvars.words[2] ~= "everyone" then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "unfriendme ") + 12)
			pname = string.trim(pname)
			id = LookupPlayer(pname)
		end

		for k, v in pairs(friends) do
			if (k == id) or chatvars.words[2] == "everyone" then
				friendlist = string.split(friends[k].friends, ",")

				-- now simply rebuild friend skipping over the one we are removing
				friends[k].friends = ""
				max = table.maxn(friendlist)
				for i=1,max,1 do
					if (friendlist[i] ~= chatvars.playerid) then
						if friends[k].friends == "" then
							friends[k].friends = friendlist[i]
						else
							friends[k].friends = friends[k].friends .. "," .. friendlist[i]
						end
					end
				end

				if (k == id) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are off " .. players[id].name .. "'s friends list.[-]")
					conn:execute("DELETE FROM friends WHERE steam = " .. k .. " AND friend = " .. chatvars.playerid)
					botman.faultyChat = false
					return true
				end
			end
		end

		if (chatvars.words[2] == "everyone") then
			conn:execute("DELETE FROM friends WHERE friend = " .. chatvars.playerid)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are off everyones friends list.[-]")
			botman.faultyChat = false
			return true
		end
	end

if debug then dbug("debug friends end") end

end
