--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_friends()
	local pid, pname, debug, max, result, help, tmp
	local shortHelp = false

	debug = false -- should be false unless testing

	calledFunction = "gmsg_friends"
	result = false
	tmp = {}
	tmp.topic = "friends"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## Friend command functions ##################

	local function cmd_AddFriend()
		local playerName

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}friend {player}"
			help[2] = "Tell the bot that a player is your friend.  The bot can also read your friend list directly from the game.  If you only friend them using this command, they will not be friended on the server itself only in the bot."

			tmp.command = help[1]
			tmp.keywords = "add,friends"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "friend") and chatvars.showHelp or botman.registerHelp then
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

		-- Say hello to my little friend
		if (chatvars.words[1] == "friend") and (chatvars.playerid ~= "0") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "friend ") + 7)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == "0" then
				id = LookupArchivedPlayer(pname)

				if id ~= "0" then
					playerName = playersArchived[id].name
				end
			else
				playerName = players[id].name
			end

			if (id == "0") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Imaginary friends don't count.  Unless you work for the FCC, pick someone that exists.[-]")
				botman.faultyChat = false
				return true
			end

			if (id == chatvars.playerid) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I know you are lonely but you're supposed to make friends with OTHER people.[-]")
				botman.faultyChat = false
				return true
			end

			if addFriend(chatvars.playerid, id, false) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. " is now recognised as a friend[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are already friends with " .. playerName .. ".[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ForgetFriends()
		local PlayerName

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}clear friends {player} (only admins can specify a player)"
			help[2] = "Clear your friends list.  Note that this does not unfriend players that you friended via your game.  You will need to unfriend those players there yourself."

			tmp.command = help[1]
			tmp.keywords = "delete,remove,forget,friends"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "clear") or string.find(chatvars.command, "friend") and chatvars.showHelp or botman.registerHelp then
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

		-- FORGET FREEMAN!
		if (chatvars.words[1] == "clear" and chatvars.words[2] == "friends") and (chatvars.playerid ~= "0") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.isAdminHidden) and chatvars.words[3] ~= nil then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "friends") + 8)
				pname = string.trim(pname)
				id = LookupPlayer(pname)

				if id == "0" then
					id = LookupArchivedPlayer(pname)

					if id ~= "0" then
						playerName = playersArchived[id].name
					end
				else
					playerName = players[id].name
				end

				if id ~= "0" then
					-- reset the players friends list
					friends[id].friends = {}
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playerName .. " has no friends :([-]")

					if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = '" .. id .. "'") end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found called " .. pname)
					end
				end

				botman.faultyChat = false
				return true
			end

			-- reset the players friends list
			friends[chatvars.playerid].friends = {}
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have no friends :([-]")

			if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = '" .. chatvars.playerid .. "'") end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FriendMe()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}friendme {player}"
			help[2] = "Admins can force a player to be their friend with this command.  It only applies to the bot, not the game itself."

			tmp.command = help[1]
			tmp.keywords = "add,friends"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "friend") and chatvars.showHelp or botman.registerHelp then
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

		-- This is how admins make friends =D
		if (chatvars.words[1] == "friendme") and (chatvars.playerid ~= "0") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "friendme ") + 9)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == "0" then
				id = LookupArchivedPlayer(pname)

				if not (id == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			else
				if addFriend(id, chatvars.playerid, false) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[id].name .. " now lists you as a friend.[-]")
					if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend) VALUES ('" .. id .. "'," .. chatvars.playerid .. ")") end

					botman.faultyChat = false
					return true
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are already a friend of " .. players[id].name .. ".[-]")
				end
			end
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FriendPlayerToPlayer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}player {player} friend {other player}\n"
			help[1] = help[1] .. "eg. {#}player joe friend mary"
			help[2] = "Admins can force a player to friend another player with this command.  It only applies to the bot, not the game itself."

			tmp.command = help[1]
			tmp.keywords = "add,friends"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "friend") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "player") and string.find(chatvars.command, " friend ") and (chatvars.playerid ~= "0") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = {}

			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7, string.find(chatvars.command, " friend ") - 1)
			tmp.pname = string.trim(tmp.pname)
			tmp.pid = LookupPlayer(tmp.pname)

			if (tmp.pid == "0") then
				tmp.pid = LookupArchivedPlayer(tmp.pname)

				if not (tmp.pid == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No match for " .. tmp.pname .. "[-]")
				end

				botman.faultyChat = false
				return true
			end

			tmp.fname = string.sub(chatvars.command, string.find(chatvars.command, " friend ") + 8)
			tmp.fname = string.trim(tmp.fname)
			tmp.fid = LookupPlayer(tmp.fname)

			if (tmp.fid == "0") then
				tmp.fid = LookupArchivedPlayer(tmp.fname)

				if not (tmp.fid == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.fid].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.fid].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No match for " .. tmp.fname .. "[-]")
				end

				botman.faultyChat = false
				return true
			end

			-- add to friends table
			if addFriend(tmp.pid, tmp.fid, false) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. " is now friends with " .. players[tmp.fid].name .. "[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. " is already friends with " .. players[tmp.fid].name .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListFriends()
		local playerName, k, v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}friends {player} (only admins can specify a player)"
			help[2] = "List your friends."

			tmp.command = help[1]
			tmp.keywords = "list,friends"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "friend") and chatvars.showHelp or botman.registerHelp then
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

		-- List a player's trophies er.. I mean friends.
		if (chatvars.words[1] == "friends") and (chatvars.playerid ~= "0") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pid = chatvars.playerid

			if not chatvars.isAdminHidden and chatvars.words[2] ~= nil then
				botman.faultyChat = false
				return true
			end

			if chatvars.isAdminHidden and chatvars.words[2] ~= nil then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "friends") + 8, string.len(chatvars.command))
				pid = LookupPlayer(pname)

				if pid == "0" then
					pid = LookupArchivedPlayer(pname)

					if not (pid == "0") then
						playerName = playersArchived[pid].name
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")

						botman.faultyChat = false
						return true
					end
				else
					playerName = players[pid].name
				end
			end

			-- pm a list of all the players friends
			if (friends[pid] == "0") or countFriends(pid) == 0 then
				if (pid == chatvars.playerid) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have no friends :([-]")
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. "  has no friends.[-]")
				end

				botman.faultyChat = false
				return true
			end

			if (pid == chatvars.playerid) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are friends with..[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. " is friends with..[-]")
			end


			for k,v in pairs(friends[pid].friends) do
				id = LookupPlayer(k)

				if id ~= "0" then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[id].name .. "[-]")
				else
					id = LookupArchivedPlayer(k)

					if id ~= "0" then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playersArchived[id].name .. "[-]")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Unfriend()
		local playerName

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}unfriend {player}"
			help[2] = "Unfriend a player."

			tmp.command = help[1]
			tmp.keywords = "remove,delete,unfriends"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "remo") or string.find(chatvars.command, "friend") and chatvars.showHelp or botman.registerHelp then
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

		-- Say hello to the hand.
		if (chatvars.words[1] == "unfriend") and (chatvars.playerid ~= "0") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == nil then
				botman.faultyChat = commandHelp("help friends", chatvars.playerid)
				return true
			end

			if (friends[chatvars.playerid] == nil or friends[chatvars.playerid] == {}) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have no friends :([-]")
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "unfriend ") + 9)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == "0" then
				id = LookupArchivedPlayer(pname)

				if not (id == "0") then
					playerName = playersArchived[id].name
				else
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You don't have any friends called " .. pname .. ".[-]")

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
			end

			-- unfriend someone
			if (id ~= "0") then
				if botman.dbConnected then
					-- check to see if this friend was auto friended and warn the player that they must unfriend them via the game.
					cursor,errorString = conn:execute("select * from friends where steam = '" .. chatvars.playerid .. "' AND friend = '" .. id .. "' AND autoAdded = 1")
					row = cursor:fetch({}, "a")

					if row then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You need to unfriend " .. playerName .. " via the game since that is how you added them.[-]")
						botman.faultyChat = false
						return true
					end
				end

				-- BE GONE FOUL DEMON!
				friends[chatvars.playerid].friends[id] = nil

				if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = '" .. chatvars.playerid .. "' AND friend = '" .. id .. "'") end
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are no longer friends with " .. playerName .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnfriendMe()
		local playerName

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}unfriendme {player}\n"
			help[1] = help[1] .. " {#}unfriendme everyone"
			help[2] = "Unfriend a player or everyone.  This command is for admins only."

			tmp.command = help[1]
			tmp.keywords = "remove,delete,unfriends"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "remo") or string.find(chatvars.command, "friend") and chatvars.showHelp or botman.registerHelp then
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

		-- My friend doesn't like you.
		-- I don't like you either.
		if (chatvars.words[1] == "unfriendme") and (chatvars.playerid ~= "0") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] ~= "everyone" then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "unfriendme ") + 12)
				pname = string.trim(pname)
				id = LookupPlayer(pname)

				if id  == "0" then
					id = LookupArchivedPlayer(pname)

					if id  ~= "0" then
						playerName = playersArchived[id].name
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")

						botman.faultyChat = false
						return true
					end
				else
					playerName = players[id].name
				end
			end

			for k, v in pairs(friends) do
				if (k == id) or chatvars.words[2] == "everyone" then
					friends[k].friends[chatvars.playerid] = nil

					if (k == id) then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are off " .. playerName .. "'s friends list.[-]")
						if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = '" .. k .. "' AND friend = '" .. chatvars.playerid .. "'") end
					end
				end
			end

			if (chatvars.words[2] == "everyone") then
				if botman.dbConnected then conn:execute("DELETE FROM friends WHERE friend = '" .. chatvars.playerid .. "'") end
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are off everyones friends list.[-]")
			end

			tempTimer( 3, [[loadFriends()]] )
			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		if debug then dbug("Registering help - friend commands") end

		tmp.topicDescription = "These commands are adding/removing or viewing a player's friends."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Friend Commands:")
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

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.words[3], "friends") then
				botman.faultyChat = false
				return true, ""
			end
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and chatvars.words[1] ~= "help" and not botman.registerHelp then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Friend Commands:")
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "These commands are adding/removing or viewing a player's friends.")
		irc_chat(chatvars.ircAlias, ".")
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "friends")
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_FriendPlayerToPlayer()

	if result then
		if debug then dbug("debug cmd_FriendPlayerToPlayer triggered") end
		return result, "cmd_FriendPlayerToPlayer"
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddFriend()

	if result then
		if debug then dbug("debug cmd_AddFriend triggered") end
		return result, "cmd_AddFriend"
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_ForgetFriends()

	if result then
		if debug then dbug("debug cmd_ForgetFriends triggered") end
		return result, "cmd_ForgetFriends"
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_Unfriend()

	if result then
		if debug then dbug("debug cmd_Unfriend triggered") end
		return result, "cmd_Unfriend"
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_FriendMe()

	if result then
		if debug then dbug("debug cmd_FriendMe triggered") end
		return result, "cmd_FriendMe"
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListFriends()

	if result then
		if debug then dbug("debug cmd_ListFriends triggered") end
		return result, "cmd_ListFriends"
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnfriendMe()

	if result then
		if debug then dbug("debug cmd_UnfriendMe triggered") end
		return result, "cmd_UnfriendMe"
	end

	if botman.registerHelp then
		if debug then dbug("Friend commands help registered") end
	end

	if debug then dbug("debug friends end") end

	-- can't touch dis
	if true then
		return result, ""
	end
end
