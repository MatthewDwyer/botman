--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local pid, pname, debug, max, result, help, tmp
local shortHelp = false
local skipHelp = false

debug = false -- should be false unless testing

function gmsg_friends()
	calledFunction = "gmsg_friends"
	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## Friend command functions ##################

	local function cmd_AddFriend()
		local playerName

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}friend {player}"
			help[2] = "Tell the bot that a player is your friend.  The bot can also read your friend list directly from the game.  If you only friend them using this command, they will not be friended on the server itself only in the bot."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,friend"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "friend") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		-- Say hello to my little friend
		if (chatvars.words[1] == "friend") and (chatvars.playerid ~= 0) then
			pname = string.sub(chatvars.command, string.find(chatvars.command, "friend ") + 7)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if id ~= 0 then
					playerName = playersArchived[id].name
				end
			else
				playerName = players[id].name
			end

			if (id == 0) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Imaginary friends don't count.  Unless you work for the FCC, pick someone that exists.[-]")
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " is now recognised as a friend[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are already friends with " .. playerName .. ".[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ForgetFriends()
		local PlayerName

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}clear friends {player} (only admins can specify a player)"
			help[2] = "Clear your friends list.  Note that this does not unfriend players that you friended via your game.  You will need to unfriend those players there yourself."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "del,remo,forget,friend"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "clear") or string.find(chatvars.command, "friend") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		-- FORGET FREEMAN!
		if (chatvars.words[1] == "clear" and chatvars.words[2] == "friends") and (chatvars.playerid ~= 0) then
			if (chatvars.accessLevel < 3) and chatvars.words[3] ~= nil then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "friends") + 8)
				pname = string.trim(pname)
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if id ~= 0 then
						playerName = playersArchived[id].name
					end
				else
					playerName = players[id].name
				end

				if id ~= 0 then
					-- reset the players friends list
					friends[id] = {}
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playerName .. " has no friends :([-]")

					if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = " .. id) end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found called " .. pname)
					end
				end

				botman.faultyChat = false
				return true
			end

			-- reset the players friends list
			friends[chatvars.playerid] = {}
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no friends :([-]")

			if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = " .. chatvars.playerid) end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FriendMe()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}friendme {player}"
			help[2] = "Admins can force a player to be their friend with this command.  It only applies to the bot, not the game itself."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,friend"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "friend") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		-- This is how admins make friends =D
		if (chatvars.words[1] == "friendme") and (chatvars.playerid ~= 0) then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "friendme ") + 9)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			else
				if (not isFriend(id, chatvars.playerid)) then
					if friends[id].friends == "" then
						friends[id].friends = chatvars.playerid
					else
						friends[id].friends = friends[id].friends .. "," .. chatvars.playerid
					end

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " now lists you as a friend.[-]")
					if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend) VALUES (" .. id .. "," .. chatvars.playerid .. ")") end

					botman.faultyChat = false
					return true
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are already a friend of " .. players[id].name .. ".[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FriendPlayerToPlayer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}player {player} friend {other player}\n"
			help[1] = help[1] .. "eg. {#}player joe friend mary"
			help[2] = "Admins can force a player to friend another player with this command.  It only applies to the bot, not the game itself."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,friend"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "friend") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "player") and string.find(chatvars.command, " friend ") and (chatvars.playerid ~= 0) then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 2) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			tmp = {}

			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7, string.find(chatvars.command, " friend ") - 1)
			tmp.pname = string.trim(tmp.pname)
			tmp.pid = LookupPlayer(tmp.pname)

			if (tmp.pid == 0) then
				tmp.pid = LookupArchivedPlayer(tmp.pname)

				if not (tmp.pid == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No match for " .. tmp.pname .. "[-]")
				end

				botman.faultyChat = false
				return true
			end

			tmp.fname = string.sub(chatvars.command, string.find(chatvars.command, " friend ") + 8)
			tmp.fname = string.trim(tmp.fname)
			tmp.fid = LookupPlayer(tmp.fname)

			if (tmp.fid == 0) then
				tmp.fid = LookupArchivedPlayer(tmp.fname)

				if not (tmp.fid == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.fid].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.fid].name .. " was archived. Get them to rejoin the server, then repeat this command.")
					end
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No match for " .. tmp.fname .. "[-]")
				end

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
	end


	local function cmd_ListFriends()
		local playerName

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}friends {player} (only admins can specify a player)"
			help[2] = "List your friends."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "list,friend"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "friend") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		-- List a player's trophies er.. I mean friends.
		if (chatvars.words[1] == "friends") and (chatvars.playerid ~= 0) then
			pid = chatvars.playerid

			if chatvars.accessLevel > 2  and chatvars.words[2] ~= nil then
				botman.faultyChat = false
				return true
			end

			if chatvars.accessLevel < 3  and chatvars.words[2] ~= nil then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "friends") + 8, string.len(chatvars.command))
				pid = LookupPlayer(pname)

				if pid == 0 then
					pid = LookupArchivedPlayer(pname)

					if not (pid == 0) then
						playerName = playersArchived[pid].name
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")

						botman.faultyChat = false
						return true
					end
				else
					playerName = players[pid].name
				end
			end

			-- pm a list of all the players friends
			if (friends[pid] == 0) or friends[pid].friends == "" then
				if (pid == chatvars.playerid) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no friends :([-]")
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. "  has no friends.[-]")
				end

				botman.faultyChat = false
				return true
			end

			friendlist = string.split(friends[pid].friends, ",")

			if (pid == chatvars.playerid) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are friends with..[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " is friends with..[-]")
			end

			max = table.maxn(friendlist)
			for i=1,max,1 do
				if (friendlist[i] ~= "") then
					id = LookupPlayer(friendlist[i])

					if id ~= 0 then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. "[-]")
					else
						id = LookupArchivedPlayer(friendlist[i])

						if id ~= 0 then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playersArchived[id].name .. "[-]")
						end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Unfriend()
		local playerName

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}unfriend {player}"
			help[2] = "Unfriend a player."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "remo,del,friend"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "remo") or string.find(chatvars.command, "friend") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		-- Say hello to the hand.
		if (chatvars.words[1] == "unfriend") and (chatvars.playerid ~= 0) then
			if chatvars.words[2] == nil then
				botman.faultyChat = commandHelp("help friends", chatvars.playerid)
				return true
			end

			if (friends[chatvars.playerid] == nil or friends[chatvars.playerid] == {}) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have no friends :([-]")
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "unfriend ") + 9)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't have any friends called " .. pname .. ".[-]")

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
			end

			-- unfriend someone
			if (id ~= 0) then
				if botman.dbConnected then
					-- check to see if this friend was auto friended and warn the player that they must unfriend them via the game.
					cursor,errorString = conn:execute("select * from friends where steam = " .. chatvars.playerid .. " AND friend = " .. id .. " AND autoAdded = 1")
					row = cursor:fetch({}, "a")

					if row then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You need to unfriend " .. playerName .. " via the game since that is how you added them.[-]")
						botman.faultyChat = false
						return true
					end
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

				if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = " .. chatvars.playerid .. " AND friend = " .. id) end
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are no longer friends with " .. playerName .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnfriendMe()
		local playerName

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}unfriendme {player}\n"
			help[1] = help[1] .. " {#}unfriendme everyone"
			help[2] = "Unfriend a player or everyone.  This command is for admins only."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "remo,del,friend"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "remo") or string.find(chatvars.command, "friend") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		-- My friend doesn't like you.
		-- I don't like you either.
		if (chatvars.words[1] == "unfriendme") and (chatvars.playerid ~= 0) then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] ~= "everyone" then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "unfriendme ") + 12)
				pname = string.trim(pname)
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if id ~= 0 then
						playerName = playersArchived[id].name
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. "[-]")

						botman.faultyChat = false
						return true
					end
				else
					playerName = players[id].name
				end
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
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are off " .. playerName .. "'s friends list.[-]")
						if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = " .. k .. " AND friend = " .. chatvars.playerid) end
						botman.faultyChat = false
						return true
					end
				end
			end

			if (chatvars.words[2] == "everyone") then
				if botman.dbConnected then conn:execute("DELETE FROM friends WHERE friend = " .. chatvars.playerid) end
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are off everyones friends list.[-]")
				botman.faultyChat = false
				return true
			end
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - friend commands ====")
		dbug("Registering help - friend commands")

		tmp = {}
		tmp.topicDescription = "These commands are adding/removing or viewing a player's friends."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'friends'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('friends', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if not string.find(chatvars.words[3], "friends") then
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

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Friend Commands:")
		irc_chat(chatvars.ircAlias, "================")
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
		return result
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddFriend()

	if result then
		if debug then dbug("debug cmd_AddFriend triggered") end
		return result
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_ForgetFriends()

	if result then
		if debug then dbug("debug cmd_ForgetFriends triggered") end
		return result
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_Unfriend()

	if result then
		if debug then dbug("debug cmd_Unfriend triggered") end
		return result
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_FriendMe()

	if result then
		if debug then dbug("debug cmd_FriendMe triggered") end
		return result
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListFriends()

	if result then
		if debug then dbug("debug cmd_ListFriends triggered") end
		return result
	end

	if (debug) then dbug("debug friends line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnfriendMe()

	if result then
		if debug then dbug("debug cmd_UnfriendMe triggered") end
		return result
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Friend commands help registered ****")
		dbug("Friend commands help registered")
		topicID = topicID + 1
	end

	if debug then dbug("debug friends end") end

	-- can't touch dis
	if true then
		return result
	end
end
