--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


--[[
friend commands
=============


--]]

function gmsg_friends()
	calledFunction = "gmsg_friends"

	local pid, pname, debug

	debug = false

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= "/") then
		faultyChat = false
		return false
	end


	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		faultyChat = false
		return false
	end
	-- ####################################################################################

if debug then dbug("debug friends 1") end

	if (chatvars.words[1] == "friend") then
		pname = string.sub(chatvars.command, string.find(chatvars.command, "friend ") + 7)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id == chatvars.playerid) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I know you are lonely but you're supposed to make friends with OTHER people.[-]")
			faultyChat = false
			return true
		end

		-- add to friends table
		if (friends[chatvars.playerid].friends == nil) then
			friends[chatvars.playerid] = {}
			friends[chatvars.playerid].friends = ""
		end

		if (id ~= nil) then
			if (not string.find(friends[chatvars.playerid].friends, players[id].steam)) then
				friends[chatvars.playerid].friends = friends[chatvars.playerid].friends .. players[id].steam .. ","
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is now recognised as a friend[-]")	
				conn:execute("INSERT INTO friends (steam, friend) VALUES (" .. chatvars.playerid .. "," .. id .. ")")
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are already friends with " .. players[id].name .. ".[-]")		
		end
		
		faultyChat = false
		return true
	end

if debug then dbug("debug friends 2") end

	if (chatvars.words[1] == "clear" and chatvars.words[2] == "friends") then
		if (accessLevel(chatvars.playerid) < 3) then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "friends") + 8)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id ~= nil then
				-- reset the players friends list
				friends[id] = {}
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " have no friends :([-]")	

				conn:execute("DELETE FROM friends WHERE steam = " .. id .. ")")

				faultyChat = false
				return true
			end
		end

		-- reset the players friends list
		friends[chatvars.playerid] = {}
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no friends :([-]")	

		conn:execute("DELETE FROM friends WHERE steam = " .. chatvars.playerid .. ")")

		faultyChat = false
		return true
	end

if debug then dbug("debug friends 3") end

	if (chatvars.words[1] == "unfriend") then
		if chatvars.words[2] == nil then
			faultyChat = help("help friends", chatvars.playerid)
			return true
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "unfriend ") + 9)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		-- unfriend someone
		if (friends[chatvars.playerid] == nil or friends[chatvars.playerid] == {}) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no friends :([-]")	
			faultyChat = false
			return true
		end

		if (id ~= nil) then
			friendlist = string.split(friends[chatvars.playerid].friends, ",")

			-- now simply rebuild friend skipping over the one we are removing
			friends[chatvars.playerid].friends = ""
			for i=1,table.maxn(friendlist),1 do
				if (friendlist[i] ~= players[id].steam) and friendlist[i] ~= "" then
					friends[chatvars.playerid].friends = friends[chatvars.playerid].friends .. friendlist[i] .. ","
				end
			end
		
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are not friends with " .. players[id].name .. "[-]")	
			conn:execute("DELETE FROM friends WHERE steam = " .. chatvars.playerid .. " AND friend = " .. id .. ")")
		end

		faultyChat = false
		return true
	end

if debug then dbug("debug friends 4") end

	if (chatvars.words[1] == "friendme") then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
			return true
		end

		pname = string.sub(chatvars.command, string.find(chatvars.command, "friendme ") + 9)
		pname = string.trim(pname)
		id = LookupPlayer(pname)

		if (id ~= nil) then
			if (not isFriend(id, chatvars.playerid)) then
				friends[id].friends = friends[id].friends .. "," .. chatvars.playerid
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " now lists you as a friend.[-]")	
				conn:execute("INSERT INTO friends (steam, friend) VALUES (" .. id .. "," .. chatvars.playerid .. ")")

				faultyChat = false
				return true
			end
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are already a friend of " .. players[id].name .. ".[-]")		
		end	
	end

if debug then dbug("debug friends 5") end

	if (chatvars.words[1] == "unfriendme") then
		if (accessLevel(chatvars.playerid) > 2) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted[-]")
			faultyChat = false
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
				for i=1,table.maxn(friendlist),1 do
					if (friendlist[i] ~= chatvars.playerid) then
						friends[k].friends = friends[k].friends .. friendlist[i] .. ","
					end
				end
				
				if (k == id) then			
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are off " .. players[id].name .. "'s friends list.[-]")	
					conn:execute("DELETE FROM friends WHERE steam = " .. k .. " AND friend = " .. chatvars.playerid .. ")")
					faultyChat = false		
					return true
				end
			end
		end
		
		if (chatvars.words[2] == "everyone") then			
			conn:execute("DELETE FROM friends WHERE friend = " .. chatvars.playerid .. ")")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are off everyones friends list.[-]")	
			faultyChat = false		
			return true
		end	
	end

if debug then dbug("debug friends 6") end

	if (chatvars.words[1] == "friends") then	
		pid = chatvars.playerid

		if accessLevel(chatvars.playerid) > 2  and chatvars.words[2] ~= nil then
			faultyChat = false
			return true
		end

		if accessLevel(chatvars.playerid) < 3  and chatvars.words[2] ~= nil then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "friends") + 8, string.len(chatvars.command))
			pid = LookupPlayer(pname)
		end

		-- pm a list of all the players friends
		if (friends[pid] == nil) then
			if (pid == chatvars.playerid) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no friends :([-]")	
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[pid].name .. "  has no friends.[-]")	
			end

			faultyChat = false
			return true
		end

		friendlist = string.split(friends[pid].friends, ",")

		if (pid == chatvars.playerid) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are friends with..[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[pid].name .. " is friends with..[-]")
		end

		for i=1,table.maxn(friendlist),1 do
			if (friendlist[i] ~= "") then
				id = LookupPlayer(friendlist[i])
				if id ~= nil then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. "[-]")	
				end
			end
		end		
		
		faultyChat = false
		return true
	end

if debug then dbug("debug friends end") end

end
