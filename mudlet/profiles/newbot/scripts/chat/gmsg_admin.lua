--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2024  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Sources   https://github.com/MatthewDwyer
--]]

function gmsg_admin()
	local debug, tmp, str, counter, r, id, pname, result, help, row, rows, cursor, errorString
	local shortHelp = false

	local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+)"
	local runyear, runmonth, runday, runhour, runminute, runseconds, seenTimestamp

	-- enable debug to see where the code is stopping. Any error will be after the last debug line.
	debug = false -- should be false unless testing

	calledFunction = "gmsg_admin"
	result = false
	tmp = {}
	tmp.topic = "admin"

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## Admin command functions ##################

	local function cmd_AddRemoveAdmin() --tested
		local playerName, isArchived, status, errorString

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}admin add {player or steam or game ID} level {0-2}\n"
			help[1] = help[1] .. "Or {#}admin remove {player or steam or game ID}"
			help[2] = "Give a player admin status and a level, or take it away.\n"
			help[2] = help[2] .. "The default admins levels are server owners: level 0, admins: level 1 and moderators: level 2. The bot supports admin levels from 0 to 89.\n"
			help[2] = help[2] .. "Or remove an admin so they become a regular player.\n"
			help[2] = help[2] .. "This does not stop them using god mode etc if they are ingame and already have dm enabled.  They must leave the server or disable dm themselves."

			tmp.command = help[1]
			tmp.keywords = "add,remove,admin,staff,owner,mod"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = "eg. {#}admin add joe level 0 (make joe an owner level admin)\n"
			tmp.notes = tmp.notes .. "eg. {#}admin remove 76561197983251951\n"
			tmp.notes = tmp.notes .. "Note: When removing an admin, the player should not be on the server at the time or it may fail to remove them from the server admin list."
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "remove") or string.find(chatvars.command, "admin") and chatvars.showHelp or botman.registerHelp then
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

		if (string.find(chatvars.command, "admin add ") or string.find(chatvars.command, "admin remove ")) then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.userID, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 0) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if string.find(chatvars.command, "admin add ") then
				if string.find(chatvars.command, "level") then
					pname = string.sub(chatvars.command, string.find(chatvars.command, "admin add ") + 10, string.find(chatvars.command, "level") - 1)
				else
					pname = string.sub(chatvars.command, string.find(chatvars.command, "admin add ") + 10)
				end
			else
				pname = string.sub(chatvars.command, string.find(chatvars.command, "admin remove ") + 13)
			end

			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(pname)
			number = -1

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if tonumber(pname) ~= nil and tmp.steam == "0" then
						-- unknown player but it is a number so attempt to remove it anyway
						staffList[pname] = nil
						if botman.dbConnected then conn:execute("DELETE FROM staff WHERE steam = '" .. pname .. "'") end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. pname .. " has been removed from the admin list.[-]")
						else
							irc_chat(chatvars.ircAlias, pname .. " has been removed from the admin list.")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if tmp.platform == "" then
				tmp.platform = "Steam"
			end

			if string.find(chatvars.command, "admin add ") then
				for i=3,chatvars.wordCount,1 do
					if chatvars.words[i] == "level" then
						number = math.abs(chatvars.words[i+1])
					end
				end

				if number == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Level number required.[-]")
					else
						irc_chat(chatvars.ircAlias, "Level number required.")
					end

					botman.faultyChat = false
					return true
				end

				if number == -1 then
					number = 1
				end

				if number > 89 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Admin level must be between 0 and 89.[-]")
					else
						irc_chat(chatvars.ircAlias, "Admin level must be between 0 and 89.")
					end

					botman.faultyChat = false
					return true
				end

				if number < tonumber(chatvars.adminLevel) then

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You cannot add admins lower than your own admin level.[-]")
					else
						irc_chat(chatvars.ircAlias, "You cannot add admins lower than your own admin level.")
					end

					botman.faultyChat = false
					return true
				end

				if tmp.steam ~= nil then
					-- add the steamid to the staffList table
					staffList[tmp.steam] = {}
					staffList[tmp.steam].adminLevel = tonumber(number)
					staffList[tmp.steam].userID = tmp.userID
					staffList[tmp.steam].platform = tmp.platform

					if not isArchived then
						players[tmp.steam].newPlayer = false
						players[tmp.steam].silentBob = false
						players[tmp.steam].walkies = false
						players[tmp.steam].block = false
						players[tmp.steam].exiled = false
						players[tmp.steam].canTeleport = true
						players[tmp.steam].botHelp = true
						players[tmp.steam].accessLevel = number

						if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, silentBob = 0, walkies = 0, block = 0, exiled = 0, canTeleport = 1, botHelp = 1, accessLevel = " .. number .. " WHERE steam = '" .. tmp.steam .. "'") end
						setGroupMembership(tmp.steam, "New Players", false)
					else
						if botman.dbConnected then conn:execute("UPDATE playersArchived SET newPlayer = 0, silentBob = 0, walkies = 0, block = 0, exiled = 0, canTeleport = 1, botHelp = 1, accessLevel = " .. number .. " WHERE steam = '" .. tmp.steam .. "'") end

						conn:execute("INSERT INTO players SELECT * from playersArchived WHERE steam = '" .. tmp.steam .. "'")
						conn:execute("DELETE FROM playersArchived WHERE steam = '" .. tmp.steam .. "'")
						playersArchived[tmp.steam] = nil
						loadPlayers(tmp.steam)
					end

					if botman.dbConnected then
						status, errorString = conn:execute("INSERT INTO staff (steam, adminLevel, userID, platform) VALUES ('" .. tmp.steam .. "'," .. number .. ",'" .. escape(tmp.userID) .. "','" .. escape(tmp.platform) .. "')")

						if not status then
							if string.find(errorString, "Duplicate entry") then
								conn:execute("UPDATE staff SET adminLevel = " .. number .. ", platform = '" .. escape(tmp.platform) .. "' WHERE steam = '" .. tmp.steam .. "'")
							end
						end
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. " has been given admin powers.[-]")
					else
						irc_chat(chatvars.ircAlias, playerName .. " has been given admin powers.")
					end

					sendCommand("ban remove " .. tmp.platform .. "_" .. tmp.steam)
					sendCommand("admin add " .. tmp.platform .. "_" .. tmp.steam .. " " .. number)
				end
			else
				-- remove the steamid and userID from the admins table
				staffList[tmp.steam] = nil
				staffList[tmp.userID] = nil
				if botman.dbConnected then
					conn:execute("DELETE FROM staff WHERE steam = '" .. tmp.steam .. "'")
					conn:execute("DELETE FROM staff WHERE steam = '" .. tmp.userID .. "'")
				end

				if not isArchived then
					players[tmp.steam].accessLevel = 90
				else
					playersArchived[tmp.steam].accessLevel = 90
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. "'s admin powers have been revoked.[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. "'s admin powers have been revoked.")
				end

				sendCommand("admin remove " .. tmp.platform .. "_" .. tmp.steam)
				sendCommand("admin remove " .. tmp.userID)
			end

			setChatColour(tmp.steam, players[tmp.steam].accessLevel, players[tmp.steam].groupID)

			-- save the player record to the database
			if not isArchived then
				updatePlayer(tmp.steam)
				saveSQLitePlayer(tmp.steam)
			else
				updateArchivedPlayer(tmp.steam)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveBadItem() --tested
		local bad, action

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}add (or {#}remove) bad item {item} action {timeout or ban} (default action is timeout)"
			help[2] = "Add or remove an item to/from the list of bad items.  The default action is to timeout the player.\n"
			help[2] = help[2] .. "See also {#}ignore player {name} and {#}include player {name}"

			tmp.command = help[1]
			tmp.keywords = "add,remove,bad,items,inventory"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "item") or string.find(chatvars.command, "bad") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and chatvars.words[2] == "bad" and chatvars.words[3] == "item" and chatvars.words[4] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			action = "timeout"

			if string.find(chatvars.command, " action ") then
				bad = string.sub(chatvars.commandOld, string.find(chatvars.command, "bad item") + 9, string.find(chatvars.command, " action") - 1)
				action = string.sub(chatvars.commandOld, string.find(chatvars.command, " action ") + 8)
			else
				bad = string.sub(chatvars.commandOld, string.find(chatvars.command, "bad item") + 9)
			end

			if action ~= "timeout" and action ~= "ban" then
				action = "timeout"
			end

			if chatvars.words[1] == "add" then
				if botman.dbConnected then conn:execute("DELETE FROM badItems WHERE item = '" .. escape(bad) .. "'") end
				if botman.dbConnected then conn:execute("INSERT INTO badItems (item, action) VALUES ('" .. escape(bad) .. "','" .. escape(action) .. "')") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You added " .. bad .. " to the list of bad items. The bot will " .. action .. " players found with it unless permitted.[-]")
				else
					irc_chat(chatvars.ircAlias, "You added " .. bad .. " to the list of bad items. The bot will " .. action .. " players found with it unless permitted")
				end
			else
				bad = string.sub(chatvars.commandOld, string.find(chatvars.command, "bad item") + 9)

				badItems[bad] = nil
				if botman.dbConnected then conn:execute("DELETE FROM badItems WHERE item = '" .. escape(bad) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You removed " .. bad .. " from the list of bad items.[-]")
				else
					irc_chat(chatvars.ircAlias, "You removed " .. bad .. " from the list of bad items.")
				end
			end

			-- reload the badItems table
			loadBadItems()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveBadWord() -- todo finish this
		local i

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}add (or {#}remove) bad word {word or phrase} (max 100 characters)\n"
			help[1] = help[1] .. "Or {#}add (or {#}remove) bad word {word or phrase} cost {amount of money} response {nothing or mute or ban or timeout} cooldown {number of seconds before un-muting etc}"
			help[2] = "Add or remove a word or phrase to/from the list of bad words.\n"
			help[2] = help[2] .. "Cost, response and cooldown are optional. The default is a cost of 10 {monies}, and no other response or cooldown.\n"
			help[2] = help[2] .. "If you set the response to mute, ban or timeout and do not set a cooldown, it is permanent unless undone by an admin or something else."


			tmp.command = help[1]
			tmp.keywords = "add,remove,bad,word"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "word") or string.find(chatvars.command, "bad") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and chatvars.words[2] == "bad" and chatvars.words[3] == "word" and chatvars.words[4] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.response = "nothing"
			tmp.cooldown = 0
			tmp.cost = 10

			if string.find(chatvars.command, "add bad") then
				tmp.addWord = true
			else
				tmp.addWord = false
			end

			for i=6,chatvars.wordCount,1 do
				if chatvars.words[i] == "cost" then
					tmp.cost = chatvars.words[i+1]

					if not tmp.badWord then
						tmp.badWord = string.sub(chatvars.commandOld, string.find(chatvars.command, " bad word ") + 10, string.find(chatvars.command, " cost ") - 1)
					end
				end

				if chatvars.words[i] == "response" then
					tmp.response = chatvars.words[i+1]

					if not tmp.badWord then
						tmp.badWord = string.sub(chatvars.commandOld, string.find(chatvars.command, " bad word ") + 10, string.find(chatvars.command, " response ") - 1)
					end
				end

				if chatvars.words[i] == "cooldown" then
					tmp.cooldown = chatvars.words[i+1]

					if not tmp.badWord then
						tmp.badWord = string.sub(chatvars.commandOld, string.find(chatvars.command, " bad word ") + 10, string.find(chatvars.command, " cooldown ") - 1)
					end
				end
			end

			if not tmp.badWord then
				tmp.badWord = string.sub(chatvars.commandOld, string.find(chatvars.command, " bad word ") + 10)
			end

			if tmp.addWord then
				if botman.dbConnected then conn:execute("INSERT INTO badWords (badWord, cost, counter, response, cooldown) VALUES ('" .. escape(tmp.badWord) .. "'," .. tmp.cost .. ", 0,'" .. escape(tmp.response) .."'," .. tmp.cooldown .. ")") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You added " .. tmp.badWord .. " to the list of bad words with a cost of " .. tmp.cost .. " {monies}, the response " .. tmp.response .. ", and a cooldown of " .. tmp.cooldown .. " seconds.[-]")
				else
					irc_chat(chatvars.ircAlias, "You added " .. tmp.badWord .. " to the list of bad words with a cost of " .. tmp.cost .. " {monies}, the response " .. tmp.response .. ", and a cooldown of " .. tmp.cooldown .. " seconds.")
				end
			else
				badWords[tmp.badWord] = nil
				if botman.dbConnected then conn:execute("DELETE FROM badWords WHERE word = '" .. escape(tmp.badWord) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You removed " .. tmp.badWord .. " from the list of bad words.[-]")
				else
					irc_chat(chatvars.ircAlias, "You removed " .. tmp.badWord .. " from the list of bad words.")
				end
			end

			-- reload the badWords table
			loadBadWords()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveBlacklistCountry() --tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}add (or {#}remove) blacklist country {US}"
			help[2] = "Add or remove a country to/from the blacklist. Note: Use 2 letter country codes only."

			tmp.command = help[1]
			tmp.keywords = "add,remove,blacklist,country,countries"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and string.find(chatvars.command, "blacklist") and chatvars.words[3] == "country" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			-- country missing
			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Country code required eg. US[-]")
				else
					irc_chat(chatvars.ircAlias, "Country code required eg. US")
				end

				botman.faultyChat = false
				return true
			end

			-- country code not 2 characters long
			if string.len(chatvars.words[4]) ~= 2 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Country code must be 2 characters long.[-]")
				else
					irc_chat(chatvars.ircAlias, "Country code must be 2 characters long.")
				end

				botman.faultyChat = false
				return true
			end

			-- force country code to upper case.
			chatvars.words[4] = string.upper(chatvars.words[4])

			if chatvars.words[1] == "add" then
				-- country already in blacklist
				if blacklistedCountries[chatvars.words[4]] then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. chatvars.words[4] .. " is already blacklisted.[-]")
					else
						irc_chat(chatvars.ircAlias, chatvars.words[4] .. " is already blacklisted.")
					end

					botman.faultyChat = false
					return true
				end

				-- add the country to the blacklist
				blacklistedCountries[chatvars.words[4]] = {}

				if server.blacklistCountries == "" then
					server.blacklistCountries = chatvars.words[4]
				else
					server.blacklistCountries = server.blacklistCountries .. "," .. chatvars.words[4]
				end

				conn:execute("UPDATE server SET blacklistCountries = '" .. escape(server.blacklistCountries) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Country " .. chatvars.words[4] .. " has been blacklisted.[-]")
				else
					irc_chat(chatvars.ircAlias, "Country " .. chatvars.words[4] .. " has been blacklisted.")
				end
			else
				-- country already in blacklist
				if not blacklistedCountries[chatvars.words[4]] then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. chatvars.words[4] .. " is not blacklisted. Nothing to do.[-]")
					else
						irc_chat(chatvars.ircAlias, chatvars.words[4] .. " is not blacklisted. Nothing to do.")
					end

					botman.faultyChat = false
					return true
				end

				-- remove the country from the blacklist
				blacklistedCountries[chatvars.words[4]] = nil
				server.blacklistCountries = ""

				for k,v in pairs(blacklistedCountries) do
					if server.blacklistCountries == "" then
						server.blacklistCountries = k
					else
						server.blacklistCountries = server.blacklistCountries .. "," .. k
					end
				end

				conn:execute("UPDATE server SET blacklistCountries = '" .. escape(server.blacklistCountries) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Country " .. chatvars.words[4] .. " has been removed from the blacklist.[-]")
				else
					irc_chat(chatvars.ircAlias, "Country " .. chatvars.words[4] .. " has been removed from the blacklist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveDonor()
		local playerName, isArchived, cursor, errorString, groupID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}add donor {player name} expires {number} week or month or year\n"
			help[1] = help[1] .. "Or {#}remove donor {player name}"
			help[2] = "Give a player donor status.  This doesn't have to involve money.  Donors get a few perks above other players but no items or " .. server.moneyPlural .. ".\n"
			help[2] = help[2] .. "Expiry is optional.  The default is 1 year.\n"
			help[2] = help[2] .. "You can also temporarily raise everyone to donor level with {#}override access."

			tmp.command = help[1]
			tmp.keywords = "add,remove,donor"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "donor") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and chatvars.words[2] == "donor" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = {}

			-- parameter collection and validation
			if string.find(chatvars.command, "expires") then
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, " donor ") + 7, string.find(chatvars.command, " expires ") - 1)
			else
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, " donor ") + 7)
			end

			tmp.pname = string.trim(tmp.pname)

			-- no player name given
			if tmp.pname == "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player name required after donor.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player name required after donor.")
				end

				botman.faultyChat = false
				return true
			end

			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(tmp.pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. tmp.pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. tmp.pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if string.find(chatvars.command, "expires") then
				tmp.expiry = string.sub(chatvars.command, string.find(chatvars.command, "expires") + 8)
				tmp.expiry = calcTimestamp(tmp.expiry)

				-- expiry missing
				if not tmp.expiry then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Expiry missing. Expected {number} {week or month or year} eg. 1 month.[-]")
					else
						irc_chat(chatvars.ircAlias, "Expiry missing. Expected {number} {week or month or year} eg. 1 month.")
					end

					botman.faultyChat = false
					return true
				end
			else
				tmp.expiry = calcTimestamp("1 year")
			end

			-- add or update a donor
			if chatvars.words[1] == "add" then
				if (chatvars.words[3] == nil) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Add donors with optional expiry. Default expiry is 1 year.[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add donor bob expires 1 week (or month or year)[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Expires automatically.[-]")
					else
						irc_chat(chatvars.ircAlias, "Add donors with optional expiry. Default expiry is 1 year.")
						irc_chat(chatvars.ircAlias, "eg. " .. server.commandPrefix .. "add donor bob expires 1 week (or month or year)")
						irc_chat(chatvars.ircAlias, "Expires automatically.")
					end

					botman.faultyChat = false
					return true
				end

				if not isArchived then
					tmp.sql = "UPDATE players SET maxWaypoints = " .. server.maxWaypointsDonors
					players[tmp.steam].maxWaypoints = server.maxWaypointsDonors
				else
					tmp.sql = "UPDATE playersArchived SET maxWaypoints = " .. server.maxWaypointsDonors
					playersArchived[tmp.steam].maxWaypoints = server.maxWaypointsDonors
				end

				conn:execute(tmp.sql .. " WHERE steam = '" .. tmp.steam .. "'")
				cursor,errorString = conn:execute("INSERT INTO donors (steam, expiry, name, expired) VALUES ('" .. tmp.steam .. "'," .. tmp.expiry .. ",'" .. escape(players[tmp.steam].name) .. "',0)")

				if errorString then
					if string.find(errorString, "Duplicate entry") then
						conn:execute("UPDATE donors SET expiry = " .. tmp.expiry .. ", expired=0, name = '" .. escape(players[tmp.steam].name) .. "' WHERE steam = '" .. tmp.steam .. "'")
					end
				end

				-- add them to the donors player group
				groupID = LookupPlayerGroup("donors")

				if groupID ~= 0 then
					conn:execute("UPDATE players SET groupID = " .. groupID .. " WHERE steam = '" .. tmp.steam .. "'")
					players[tmp.steam].groupID = groupID
				end

				loadDonors()
				setOverrideChatName(tmp.steam, playerGroups["G" .. groupID].namePrefix .. players[tmp.steam].name)

				-- also add them to the bot's whitelist
				whitelist[tmp.steam] = {}
				if botman.dbConnected then conn:execute("INSERT INTO whitelist (steam) VALUES ('" .. tmp.steam .. "')") end

				-- create or update the donor record on the shared database
				cursor,errorString = connBots:execute("INSERT INTO donors (donor, donorExpiry, steam, botID, serverGroup) VALUES (1, " .. tmp.expiry .. ", '" .. tmp.steam .. "'," .. server.botID .. ",'" .. escape(server.serverGroup) .. "')")

				if string.find(errorString, "Duplicate entry") then
					connBots:execute("UPDATE donors SET donor = 1, donorExpiry = " .. tmp.expiry .. ", serverGroup = '" .. escape(server.serverGroup) ..  "' WHERE steam = '" .. tmp.steam .. "' AND botID = " .. server.botID)
				end

				if igplayers[tmp.steam] then
					message("pm " .. tmp.userID .. " [" .. server.chatColour .. "]You have been given donor privileges until " .. os.date("%d-%b-%Y",  tmp.expiry) .. ". Thank you for being awesome! =D[-]")
				end

				irc_chat(server.ircMain, playerName .. " donor status expires on " .. os.date("%d-%b-%Y",  tmp.expiry))

				if chatvars.ircid ~= "0" then
					irc_chat(chatvars.ircAlias, playerName .. " donor status expires on " .. os.date("%d-%b-%Y",  tmp.expiry))
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. " is now a donor until " .. os.date("%d-%b-%Y",  tmp.expiry) .. ".[-]")
				end
			else
				removeDonor(tmp.steam)

				-- reload bases from the database
				tempTimer( 3, [[loadBases()]] )

				-- reload donors from the database
				tempTimer( 3, [[loadDonors()]] )

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. " no longer has donor status.[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. " no longer has donor status.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveRestrictedItem() --tested
		local bad, item, qty, access, action, status, errorString

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}add restricted item {item name} qty {count} action {action} access {level}\n"
			help[1] = help[1] .. "Or {#}remove restricted item {item name}"
			help[2] = "Add an item to the list of restricted items.\n"
			help[2] = help[2] .. "Valid actions are timeout, ban, exile and watch\n"
			help[2] = help[2] .. "eg. {#}add restricted item tnt qty 5 action timeout access 90\n"
			help[2] = help[2] .. "Players with access > 90 will be sent to timeout for more than 5 tnt."

			tmp.command = help[1]
			tmp.keywords = "add,remove,restricted,item,inventory"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or (string.find(chatvars.command, "remove")) or string.find(chatvars.command, "item") or string.find(chatvars.command, "rest") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and chatvars.words[2] == "restricted" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "add" and chatvars.words[3] == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Add an item to the inventory scanner for special attention.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add restricted item tnt qty 5 action timeout access 90[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players with access > 90 will be sent to timeout for more than 5 tnt.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, exile, and watch[-]")
				else
					irc_chat(chatvars.ircAlias, "Add an item to the inventory scanner for special attention.")
					irc_chat(chatvars.ircAlias, "eg. " .. server.commandPrefix .. "add restricted item tnt qty 5 action timeout access 90.")
					irc_chat(chatvars.ircAlias, "Players with access > 90 will be sent to timeout for more than 5 tnt.")
					irc_chat(chatvars.ircAlias, "Valid actions are timeout, ban, exile, and watch")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "add" then
				item = ""
				qty = 0
				access = 100
				action = "timeout"

				for i=3,chatvars.wordCount,1 do
					if chatvars.words[i] == "item" then
						item = chatvars.wordsOld[i+1]
					end

					if chatvars.words[i] == "qty" then
						qty = chatvars.words[i+1]
					end

					if chatvars.words[i] == "access" then
						access = chatvars.words[i+1]
					end

					if chatvars.words[i] == "action" then
						action = chatvars.wordsOld[i+1]
					end
				end

				if action ~= "timeout" and action ~= "ban" and action ~= "exile" and action ~= "watch" then
					action = "timeout"
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Invalid action entered, using timeout instead.[-]")
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, exile, and watch.[-]")
					else
						irc_chat(chatvars.ircAlias, "Invalid action entered, using timeout instead.")
						irc_chat(chatvars.ircAlias, "Valid actions are timeout, ban, exile, and watch.")
					end
				end

				if item == "" or access == 100 then
					if (chatvars.playername ~= "Server") then
						if item == "" and access < 100 then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Item name required.[-]")
						end

						if item ~= "" and access == 100 then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Access level required.[-]")
						end

						if item == "" and access == 100 then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Item name and access level required.[-]")
						end

						if item == "" then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add restricted item mineCandyTin qty 20 access 99 action timeout[-]")
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add restricted item " .. item .. " qty 20 access 99 action timeout[-]")
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, exile. Bans last 1 day.[-]")
					else
						if item == "" and access < 100 then
							irc_chat(chatvars.ircAlias, "Item name required.")
						end

						if item ~= "" and access == 100 then
							irc_chat(chatvars.ircAlias, "Access level required.")
						end

						if item == "" and access == 100 then
							irc_chat(chatvars.ircAlias, "Item name and access level required.")
						end

						if item == "" then
							irc_chat(chatvars.ircAlias, "eg. cmd " .. server.commandPrefix .. "add restricted item mineCandyTin qty 20 access 99 action timeout")
						else
							irc_chat(chatvars.ircAlias, "eg. cmd " .. server.commandPrefix .. "add restricted item " .. item .. " qty 20 access 99 action timeout")
						end

						irc_chat(chatvars.ircAlias, "Valid actions are timeout, ban, exile. Bans last 1 day.")
					end
				else
					if botman.dbConnected then
						conn:execute("DELETE FROM restrictedItems WHERE item = '" .. escape(bad) .. "'")

						status, errorString = conn:execute("INSERT INTO restrictedItems (item, qty, accessLevel, action) VALUES ('" .. escape(item) .. "'," .. qty .. "," .. access .. ",'" .. action .. "')")

						if not status then
							if string.find(errorString, "Duplicate entry") then
								conn:execute("UPDATE restrictedItems SET qty = " .. qty .. ", accessLevel = " .. access .. ", action = '" .. action .. "' WHERE item = '" .. escape(item) .. "'")
							end
						end
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You added " .. item .. " quantity " .. qty .. " with minimum access level " .. access .. " and action " .. action .. " to restricted items.[-]")
					else
						irc_chat(chatvars.ircAlias, "You added " .. item .. " quantity " .. qty .. " with minimum access level " .. access .. " and action " .. action .. " to restricted items.")
					end
				end
			else
				-- remove restricted item
				bad = string.sub(chatvars.commandOld, string.find(chatvars.command, "restricted item") + 16)

				if botman.dbConnected then conn:execute("DELETE FROM restrictedItems WHERE item = '" .. escape(bad) .. "'")	end
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You removed " .. bad .. " from the list of restricted items[-]")
			end

			loadRestrictedItems()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveWhitelistCountry() --tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}add (or {#}remove) whitelist country {US}"
			help[2] = "Add or remove a country to/from the whitelist. Note: Use 2 letter country codes."

			tmp.command = help[1]
			tmp.keywords = "add,remove,whitelist,country,countries"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "whitelist") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and string.find(chatvars.command, "whitelist") and chatvars.words[3] == "country" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			-- country missing
			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Country code required eg. US[-]")
				else
					irc_chat(chatvars.ircAlias, "Country code required eg. US")
				end

				botman.faultyChat = false
				return true
			end

			-- country code not 2 characters long
			if string.len(chatvars.words[4]) ~= 2 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Country code must be 2 characters long.[-]")
				else
					irc_chat(chatvars.ircAlias, "Country code must be 2 characters long.")
				end

				botman.faultyChat = false
				return true
			end

			-- force country code to upper case.
			chatvars.words[4] = string.upper(chatvars.words[4])

			if chatvars.words[1] == "add" then
				-- country already in whitelist
				if whitelistedCountries[chatvars.words[4]] then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. chatvars.words[4] .. " is already whitelisted.[-]")
					else
						irc_chat(chatvars.ircAlias, chatvars.words[4] .. " is already whitelisted.")
					end

					if server.whitelistCountries ~= "" then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]These countries are whitelisted: " .. server.whitelistCountries .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "These countries are whitelisted: " .. server.whitelistCountries)
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No countries are whitelisted.[-]")
						else
							irc_chat(chatvars.ircAlias, "No countries are whitelisted.")
						end
					end

					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "add" then
				-- add the country to the whitelist
				whitelistedCountries[chatvars.words[4]] = {}

				if server.whitelistCountries == "" then
					server.whitelistCountries = chatvars.words[4]
				else
					server.whitelistCountries = server.whitelistCountries .. "," .. chatvars.words[4]
				end

				conn:execute("UPDATE server SET whitelistCountries = '" .. escape(server.whitelistCountries) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Country " .. chatvars.words[4] .. " has been whitelisted.[-]")
				else
					irc_chat(chatvars.ircAlias, "Country " .. chatvars.words[4] .. " has been whitelisted.")
				end
			else
				-- country already in whitelist
				if not whitelistedCountries[chatvars.words[4]] then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. chatvars.words[4] .. " is not whitelisted. Nothing to do.[-]")
					else
						irc_chat(chatvars.ircAlias, chatvars.words[4] .. " is not whitelisted. Nothing to do.")
					end

					botman.faultyChat = false
					return true
				end

				-- remove the country from the whitelist
				whitelistedCountries[chatvars.words[4]] = nil
				server.whitelistCountries = ""

				for k,v in pairs(whitelistedCountries) do
					if server.whitelistCountries == "" then
						server.whitelistCountries = k
					else
						server.whitelistCountries = server.whitelistCountries .. "," .. k
					end
				end

				conn:execute("UPDATE server SET whitelistCountries = '" .. escape(server.whitelistCountries) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Country " .. chatvars.words[4] .. " has been removed from the whitelist.[-]")
				else
					irc_chat(chatvars.ircAlias, "Country " .. chatvars.words[4] .. " has been removed from the whitelist.")
				end
			end

			if server.whitelistCountries ~= "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]These countries are whitelisted: " .. server.whitelistCountries .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "These countries are whitelisted: " .. server.whitelistCountries)
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No countries are whitelisted.[-]")
				else
					irc_chat(chatvars.ircAlias, "No countries are whitelisted.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ArrestPlayer() --tested
		local reason, prisoner, prisonerSteam, prisonerSteamOwner, prisonerUserID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}arrest {player name}\n"
			help[1] = help[1] .. "Or {#}arrest {player name} reason {why arrested}"
			help[2] = "Send a player to prison.  If the location prison does not exist they are sent to timeout instead."

			tmp.command = help[1]
			tmp.keywords = "arrest,jail,prison,player,pvp"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "arrest") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "jail") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "arrest") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			reason = "Arrested by admin"

			if string.find(chatvars.command, " reason ") then
				prisoner = string.sub(chatvars.command, string.find(chatvars.command, "arrest ") + 7, string.find(chatvars.command, " reason "))
				reason = string.sub(chatvars.commandOld, string.find(chatvars.command, " reason ") + 8)
			else
				prisoner = string.sub(chatvars.command, string.find(chatvars.command, "arrest ") + 7)
			end

			reason = string.trim(reason)
			prisoner = string.trim(prisoner)
			prisonerSteam, prisonerSteamOwner, prisonerUserID = LookupPlayer(prisoner) -- done

			if prisonerSteam == "0" then
				prisonerSteam, prisonerSteamOwner, prisonerUserID = LookupArchivedPlayer(prisoner)

				if not (prisonerSteam == "0") then
					prisoner = playersArchived[prisonerSteam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. prisoner)
					end

					botman.faultyChat = false
					return true
				end
			else
				prisoner = players[prisonerSteam].name
				isArchived = false
			end

			prisoner = players[prisonerSteam].name

			if (players[prisonerSteam]) then
				if (players[prisonerSteam].timeout or players[prisonerSteam].botTimeout) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. prisoner .. " is in timeout. " .. server.commandPrefix .. "return them first[-]")
					else
						irc_chat(chatvars.ircAlias, prisoner .. " is in timeout. Return them first")
					end

					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.playername ~= "Server") then
				if (isAdminHidden(prisonerSteam, prisonerUserID) and botman.ignoreAdmins and prisonerSteam ~= chatvars.playerid) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Staff can not be arrested.[-]")
					else
						irc_chat(chatvars.ircAlias, "Staff can not be arrested.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if not LookupLocation("prison") then

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Create a location called prison first. Sending them to timeout instead..[-]")
				else
					irc_chat(chatvars.ircAlias, "Create a location called prison first. Sending them to timeout instead.")
				end

				gmsg(server.commandPrefix .. "timeout " .. prisoner)
				botman.faultyChat = false
				return true
			end

			arrest(prisonerSteam, reason, 100000, 44640) -- bail 100,000  prison time 1 month

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_BanUnbanPlayer()
		local rows, cursor, errorString

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}ban {player name} (ban for 10 years with the reason 'banned')\n"
			help[1] = help[1] .. "Or {#}ban {player name} reason {reason for ban} (ban for 10 years with the reason you provided)\n"
			help[1] = help[1] .. "Or {#}ban {player name} time {number} hour or day or month or year reason {reason for ban}\n"
			help[1] = help[1] .. "Or {#}unban {player name} (This will also remove global bans issued by this bot against this player.  It will not remove global bans issued elsewhere.\n"
			help[1] = help[1] .. "Or {#}gblban {player name} reason {reason for ban}"
			help[2] = "Ban a player from the server.  You can optionally give a reason and a duration. The default is a 10 year ban with the reason 'banned'.\n"
			help[2] = help[2] .. "Global bans are vetted before they become active.  If the player is later caught hacking by a bot and they have pending global bans, a new active global ban is added automatically."

			tmp.command = help[1]
			tmp.keywords = "gbl,globalban,player,banlist"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "ban") or string.find(chatvars.command, "black") or string.find(chatvars.command, "gbl") or string.find(chatvars.command, "glob") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "ban" or chatvars.words[1] == "unban" or chatvars.words[1] == "gblban") and chatvars.words[2] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			-- gather info for the ban
			tmp.reason = "banned"
			tmp.duration = "10 years"
			tmp.unknownPlayer = false
			tmp.playerName = "(unknown player)"
			tmp.platform = "Steam"

			-- someone did ban remove instead of unban so we'll fix their command for them.
			if string.find(chatvars.command, "ban remove") then
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "remove ") + 7)
				chatvars.words[1] = "unban"
				chatvars.command = "unban " .. tmp.pname
			end

			if string.find(chatvars.command, "reason") then
				tmp.reason = string.sub(chatvars.commandOld, string.find(chatvars.command, "reason ") + 7)
			end

			if not string.find(chatvars.command, " reason ") and not string.find(chatvars.command, " time ") then
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4)
			end

			if string.find(chatvars.command, "reason") then
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, " reason ") - 1)

				if chatvars.words[1] ~= "gblban" then
					if string.find(chatvars.command, " time ") then
						tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, " time ") - 1)
					end
				else
					if string.find(chatvars.command, "gblban add") then
						tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "ban add ") + 8, string.find(chatvars.command, " reason ") - 1)
					else
						tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, " reason ") - 1)
					end
				end
			end

			if string.find(chatvars.command, "time") then
				if string.find(chatvars.command, "reason") then
					tmp.duration = string.sub(chatvars.command, string.find(chatvars.command, "time ") + 5, string.find(chatvars.command, " reason ") - 1)
				else
					tmp.duration = string.sub(chatvars.command, string.find(chatvars.command, "time ") + 5)
				end

				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, " time ") - 1)
			end

			if chatvars.words[1] == "unban" then
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "unban ") + 6)
			end

			tmp.pname = string.trim(tmp.pname)
			tmp.steam, tmp.owner, tmp.userID, tmp.platform = LookupPlayer(tmp.pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.owner, tmp.userID, tmp.platform = LookupArchivedPlayer(tmp.pname)
				if not (tmp.steam == "0") then
					tmp.playerName = playersArchived[tmp.steam].name
				else
					tmp.unknownPlayer = true

					if isValidSteamID(tmp.pname) then
						tmp.steam = tmp.pname
						tmp.owner = tmp.pname
					end
				end
			else
				tmp.playerName = players[tmp.steam].name
			end

			if chatvars.words[1] == "unban" then
				sendCommand("ban remove " .. tmp.platform .. "_" .. tmp.steam)
				sendCommand("ban remove " .. tmp.userID)

				if tmp.steam ~= tmp.owner then
					-- also unban the owner id
					sendCommand("ban remove " .. tmp.platform .. "_" .. tmp.owner)
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.playerName .. " has been unbanned.[-]")
				else
					irc_chat(chatvars.ircAlias, tmp.playerName .. " has been unbanned.")
				end

				-- also delete the ban record in the shared bots database.  If the player was global banned from here, this will remove that ban as well.
				connBots:execute("DELETE FROM bans where steam = '" .. tmp.steam .. "' OR steam = '" .. tmp.owner .. "' AND botID = " .. server.botID)

				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "ban" then
				-- don't ban if player is an admin :O
				if isAdminHidden(tmp.steam, tmp.userID) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You what?  You want to ban one of your own admins?   [DENIED][-]")
					else
						irc_chat(chatvars.ircAlias, "You what?  You want to ban one of your own admins?   [DENIED]")
					end

					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] ~= "gblban" then
				-- issue a local ban
				banPlayer(tmp.platform, tmp.userID, tmp.steam, tmp.duration, tmp.reason, chatvars.playerid)
			else
				-- issue a global ban
				if tmp.steam ~= "0" then
					-- don't ban if player is an admin :O
					if isAdminHidden(tmp.steam, tmp.userID) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You what?  You want to global ban one of your own admins?   [DENIED][-]")
						else
							irc_chat(chatvars.ircAlias, "You what?  You want to global ban one of your own admins?   [DENIED]")
						end

						botman.faultyChat = false
						return true
					end
				end

				cursor,errorString = connBots:execute("SELECT * FROM bans where steam = '" .. tmp.steam .. "' or steam = '" .. tmp.owner .. "' AND botID = " .. server.botID)
				rows = cursor:numrows()

				if rows == 0 then
					connBots:execute("INSERT INTO bans (steam, reason, GBLBan, GBLBanReason, botID) VALUES ('" .. tmp.steam .. "','" .. escape(tmp.reason) .. "',1,'" .. escape(tmp.reason) .. "'," .. server.botID .. ")")
					-- issue a local ban as well
					banPlayer(tmp.platform, tmp.userID, tmp.steam, tmp.duration, tmp.reason, chatvars.playerid)
				else
					connBots:execute("UPDATE bans set GBLBan = 1, GBLBanReason = '" .. escape(tmp.reason) .. "' WHERE steam = '" .. tmp.steam .. "' or steam = " .. tmp.owner .. " AND botID = " .. server.botID)
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.playerName .. " with steam id " .. tmp.steam .. " has been submitted to the global ban list for approval.[-]")
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Until approved, it will only raise an alert when the player joins another server.[-]")
				else
					irc_chat(chatvars.ircAlias, tmp.playerName .. " with steam id " .. tmp.steam .. " has been submitted to the global ban list for approval.")
					irc_chat(chatvars.ircAlias, "Until approved, it will only raise an alert when the player joins another server.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_BlockChatCommandsForPlayer() --tested
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}block (or {#}unblock) {name}"
			help[2] = "Block/Unblock a player from using any bot commands or command the bot from IRC."

			tmp.command = help[1]
			tmp.keywords = "block,player,commands,irc,bot"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "block") or string.find(chatvars.command, "play") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "block" or chatvars.words[1] == "unblock") and chatvars.words[2] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1], nil, true) + string.len(chatvars.words[1]))
			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform  = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if (chatvars.words[1] == "block") then
				if isAdminHidden(tmp.steam, tmp.userID) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Action not permitted against admins.[-]")
					else
						irc_chat(chatvars.ircAlias, "Action not permitted against admins.")
					end

					botman.faultyChat = false
					return true
				end

				if not isArchived then
					players[tmp.steam].block = true
				else
					playersArchived[tmp.steam].block = true
				end

				if botman.dbConnected then conn:execute("UPDATE playersArchived SET block=1 WHERE steam = '" .. tmp.steam .. "'") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Player " .. playerName .. " is blocked from talking to the bot.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Player " .. playerName .. " is blocked from talking to the bot.")
				end
			else
				if not isArchived then
					players[tmp.steam].block = false
				else
					playersArchived[tmp.steam].block = false
				end

				if botman.dbConnected then conn:execute("UPDATE players SET block=0 WHERE steam = '" .. tmp.steam .. "'") end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Player " .. playerName .. " can talk to the bot.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Player " .. playerName .. " can talk to the bot.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_BurnPlayer() --tested (ouch)
		local steam, steamOwner, userID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}burn {player name}"
			help[2] = "Set a player on fire.  It usually kills them."

			tmp.command = help[1]
			tmp.keywords = "burn,player,buff,fun"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "burn") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "burn") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			steam = chatvars.playerid -- you look hot

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				steam, steamOwner, userID = LookupPlayer(pname)

				if steam == "0" then
					steam, steamOwner, userID = LookupArchivedPlayer(pname)

					if not (steam == "0") then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[steam] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. igplayers[steam].name .. " is not playing right now and can't feel the burn.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[steam].name .. " is not playing right now and can't feel the burn.")
				end

				botman.faultyChat = false
				return true
			end

			sendCommand("buffplayer " .. userID .. " buffBurningMolotov") -- yeah baby!

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You set " .. players[steam].name .. " on fire![-]")

				if isAdminHidden(steam, userID) then
					if chatvars.playerid == steam then
						message("pm " .. userID .. " [" .. server.alertColour .. "]You set yourself on fire!  Should'a listened to the Surgeon General.[-]")
					else
						message("pm " .. userID .. " [" .. server.alertColour .. "]" .. players[chatvars.playerid].name .. " set you on fire![-]")
					end
				end
			else
				irc_chat(chatvars.ircAlias, "You set " .. players[steam].name .. " on fire!")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ArchivePlayers() --tested
		local k,v

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}archive players"
			help[2] = "Archive players that haven't played in 60 days, aren't staff, banned, or a donor.\n"
			help[2] = help[2] .. "This should speed the bot up on servers that have seen thousands of players over time as the bot won't need to search so many player records.\n"
			help[2] = help[2] .. "Archived players are still accessible and searchable but are removed from the main players table.  If a player comes back they are automatically restored from the archive."

			tmp.command = help[1]
			tmp.keywords = "archive,players"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "arch") or string.find(chatvars.command, "remove") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "archive" and chatvars.words[2] == "players" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if not server.useAllocsWebAPI then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command is only available in API mode.[-]")
				else
					irc_chat(chatvars.ircAlias, "This command is only available in API mode.")
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players (except staff and donors) who is not known to the server will be archived.[-]")
			else
				irc_chat(chatvars.ircAlias, "Players (except staff and donors) who is not known to the server will be archived.")
			end

			botman.archivePlayers = true

			--	first flag everyone except staff and donors as notInLKP.  We will remove that flag as we find them in LKP.
			for k,v in pairs(players) do
				v.notInLKP = true

				if isAdminHidden(k, v.userID) or isDonor(k) then
					v.notInLKP = false
				end
			end

			saveLuaTables(os.date("%Y%m%d_%H%M%S"), "restore_archived_players")
			sendCommand("lkp")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ClearBlacklist() --tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}clear country blacklist"
			help[2] = "Remove all countries from the blacklist. (yay?)"

			tmp.command = help[1]
			tmp.keywords = "clear,blacklist,country"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "blacklist") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "clear" and chatvars.words[2] == "country" and chatvars.words[3] == "blacklist") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			blacklistedCountries = {}
			server.blacklistCountries = ""

			conn:execute("UPDATE server SET blacklistCountries = ''")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The country blacklist has been cleared.[-]")
			else
				irc_chat(chatvars.ircAlias, "The country blacklist has been cleared.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ClearWhitelist() --tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}clear country whitelist"
			help[2] = "Remove all countries from the whitelist."

			tmp.command = help[1]
			tmp.keywords = "clear,whitelist,country"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "whitelist") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "clear" and chatvars.words[2] == "country" and chatvars.words[3] == "whitelist") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			whitelistedCountries = {}
			server.whitelistCountries = ""

			conn:execute("UPDATE server SET whitelistCountries = ''")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The country whitelist has been cleared.[-]")
			else
				irc_chat(chatvars.ircAlias, "The country whitelist has been cleared.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_CoolPlayer() --tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}cool {player name}"
			help[2] = "Cool a player or yourself if no name given."

			tmp.command = help[1]
			tmp.keywords = "cool,player,buff,fun"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "cool") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "cool") then
			if LookupLocation("cool") ~= nil then
				botman.faultyChat = false
				return false
			end

			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.steam = chatvars.playerid

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

				if tmp.steam == "0" then
					tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

					if not (tmp.steam == "0") then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[tmp.steam] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. igplayers[tmp.steam].name .. " is not playing right now.  They aren't cool enough.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[tmp.steam].name .. " is not playing right now. They aren't cool enough.")
				end

				botman.faultyChat = false
				return true
			end

			sendCommand("buffplayer " .. tmp.userID .. " buffYuccaJuiceCooling")  -- stay frosty

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. " is cooling down.[-]")
			else
				irc_chat(chatvars.ircAlias, players[tmp.steam].name .. " is cooling down.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_CurePlayer() --tested
		local steam, steamOwner, userID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}cure {player name}"
			help[2] = "Cure a player or yourself if no name given."

			tmp.command = help[1]
			tmp.keywords = "cure,player,buff,fun,medical"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "cure") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "cure") then
			if LookupLocation("cure") ~= nil then
				botman.faultyChat = false
				return false
			end

			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			steam = chatvars.playerid

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				steam, steamOwner, userID = LookupPlayer(pname)

				if steam == "0" then
					steam, steamOwner, userID = LookupArchivedPlayer(pname)

					if not (steam == "0") then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[steam] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. igplayers[steam].name .. " is not playing right now. Next patient please![-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[steam].name .. " is not playing right now. Next patient please!")
				end

				botman.faultyChat = false
				return true
			end

			sendCommand("debuffplayer " .. userID .. " buffIllDysentery1")  -- It's Debuffy The Zombie Slayer! :D
			sendCommand("debuffplayer " .. userID .. " buffIllDysentery2")
			sendCommand("debuffplayer " .. userID .. " buffIllFoodPoisoning1")
			sendCommand("debuffplayer " .. userID .. " buffIllFoodPoisoning2")
			sendCommand("debuffplayer " .. userID .. " buffIllPneumonia1")
			sendCommand("debuffplayer " .. userID .. " buffIllInfection1")
			sendCommand("debuffplayer " .. userID .. " buffIllInfection1")
			sendCommand("debuffplayer " .. userID .. " buffIllInfection1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You cured " .. players[steam].name .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "You cured " .. players[steam].name)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_DownloadHelp()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}download help"
			help[2] = "This saves a JSON encoded text file of the bot's in-game help so you can edit it to change permissions.\n"
			help[2] = help[2] .. "To upload it back to the bot use {#}upload help {url where your modified help file can be downloaded by the bot}"

			tmp.command = help[1]
			tmp.keywords = "help,download,permissions,edit,customise,customize,json"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "download")) and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "download" and chatvars.words[2] == "help" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			loadHelpCommands(true)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The command help can be downloaded where your bot saves daily logs in temp/commands.json[-]")
			else
				irc_chat(chatvars.ircAlias, "The command help can be downloaded where your bot saves daily logs in temp/commands.json")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_EquipAdmin()

		local function giveItem(item, ignoreQuality, quantity)
			if ignoreQuality == nil then
				ignoreQuality = false
			end

			if quantity == nil then
				quantity = 1
			end

			if not ignoreQuality then
				tmp.cmd = "give " .. chatvars.userID .. " " .. item .. " " .. quantity .. " 6"

				if server.botman then
					tmp.cmd = "bm-give " .. chatvars.userID .. " " .. item .. " " .. quantity .. " 6"
				end

			else
				if tmp.quantity < quantity then
					tmp.cmd = "give " .. chatvars.userID .. " " .. item .. " " .. quantity - tonumber(tmp.quantity)

					if server.botman then
						tmp.cmd = "bm-give " .. chatvars.userID .. " " .. item .. " " .. quantity - tonumber(tmp.quantity)
					end

					if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
					botman.gimmeQueueEmpty = false
					tmp.gaveStuff = true
				end
			end

			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, item)

			if not tmp.found then
				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
				botman.gimmeQueueEmpty = false
				tmp.gaveStuff = true
			else
				if not ignoreQuality then
					if tmp.quality < 100 then
						if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
						botman.gimmeQueueEmpty = false
						tmp.gaveStuff = true
					end
				end
			end
		end
		-- end of local function giveItem

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}equip admin"
			help[2] = "Spawn various items on you.  The bot checks your inventory and will top you up instead of doubling up if you repeat this command later."

			tmp.command = help[1]
			tmp.keywords = "equipment,admin,items,inventory"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "equip") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "inv") and chatvars.showHelp or botman.registerHelp then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end

			return false
		end

		if (chatvars.words[1] == "equip" and chatvars.words[2] == "admin") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.gaveStuff = false
			tmp.inventory = igplayers[chatvars.playerid].pack .. igplayers[chatvars.playerid].belt
			tmp.equipment = igplayers[chatvars.playerid].equipment

			giveItem("meleeToolHammerOfGodAdmin")
			giveItem("meleeToolPaintToolAdmin")
			giveItem("meleeToolWrenchAdmin")
			giveItem("coolLootShadesAdmin")
			giveItem("rocketBootsAdmin")
			giveItem("gunHandgunPistolAdmin")
			giveItem("gunToolDiggerAdmin")
			giveItem("toughGuyShirtAdmin")
			giveItem("pimpMiningHelmetAdmin")

			if tmp.gaveStuff then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]We deliver :)[-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You have enough stuff and its not shitty enough to replace yet :P[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ExilePlayer()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}exile {player name}"
			help[2] = "Bannish a player to a special location called {#}exile which must exist first.  While exiled, the player will not be able to command the bot."

			tmp.command = help[1]
			tmp.keywords = "exile,player,bannish,timeout"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "exile")) and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "exile" and chatvars.words[2] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = chatvars.words[2]
			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if tmp.steam ~= "0" then
				-- flag the player as exiled
				if not isArchived then
					players[tmp.steam].exiled = true
					players[tmp.steam].silentBob = true
					players[tmp.steam].canTeleport = false
				else
					playersArchived[tmp.steam].exiled = true
					playersArchived[tmp.steam].silentBob = true
					playersArchived[tmp.steam].canTeleport = false
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. " has been exiled.[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. " has been exiled.")
				end

				if botman.dbConnected then conn:execute("UPDATE players SET exiled = 1, silentBob = 1, canTeleport = 0 WHERE steam = '" .. tmp.steam .. "'") end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FreePlayer()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}free {player name}"
			help[2] = "Release the player from exile, however it does not return them.  They can type {#}return or you can return them."

			tmp.command = help[1]
			tmp.keywords = "exile,player,free,release,return"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "exile") or string.find(chatvars.command, "free") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "free") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = chatvars.words[2]
			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if tmp.steam ~= "0" then
				-- flag the player as no longer exiled
				if not isArchived then
					players[tmp.steam].exiled = false
					players[tmp.steam].silentBob = false
					players[tmp.steam].canTeleport = true
				else
					playersArchived[tmp.steam].exiled = false
					playersArchived[tmp.steam].silentBob = false
					playersArchived[tmp.steam].canTeleport = true
				end

				message("say [" .. server.chatColour .. "]" .. playerName .. " has been released from exile! :D[-]")

				if
					botman.dbConnected then conn:execute("UPDATE players SET exiled = 0, silentBob = 0, canTeleport = 1 WHERE steam = '" .. tmp.steam .. "'")
					connSQL:execute("UPDATE players SET exiled = 0, silentBob = 0, canTeleport = 1 WHERE steam = '" .. tmp.steam .. "'")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GiveAdminSupplies() --tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}supplies"
			help[2] = "Spawn various items on you like equip admin does but no armour or guns.  The bot checks your inventory and will top you up instead of doubling up if you repeat this command later."

			tmp.command = help[1]
			tmp.keywords = "supplies,items,give,admins,equipment"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "give") or string.find(chatvars.command, "item") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "supplies") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.gaveStuff = false
			tmp.inventory = igplayers[chatvars.playerid].pack .. igplayers[chatvars.playerid].belt
			tmp.equipment = igplayers[chatvars.playerid].equipment

			if not string.find(tmp.inventory, "edTea") then
				tmp.cmd = "give " .. chatvars.userID .. " drinkJarRedTea 10"

				if server.botman then
					tmp.cmd = "bm-give " .. chatvars.userID .. " drinkJarRedTea 10"
				end

				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
				botman.gimmeQueueEmpty = false
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "drinkJarRedTea")

				if tonumber(tmp.quantity) < 10 then
					tmp.cmd = "give " .. chatvars.userID .. " drinkJarRedTea " .. 10 - tonumber(tmp.quantity)

					if server.botman then
						tmp.cmd = "bm-give " .. chatvars.userID .. " drinkJarRedTea " .. 10 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
					botman.gimmeQueueEmpty = false
					tmp.gaveStuff = true
				end
			end


			if not string.find(string.lower(tmp.inventory), "ascan") then
				tmp.cmd = "give " .. chatvars.userID .. " ammoGasCan 400"

				if server.botman then
					tmp.cmd = "bm-give " .. chatvars.userID .. " ammoGasCan 400"
				end

				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
				botman.gimmeQueueEmpty = false
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "ammoGasCan")

				if tonumber(tmp.quantity) < 400 then
					tmp.cmd = "give " .. chatvars.userID .. " ammoGasCan " .. 400 - tonumber(tmp.quantity)

					if server.botman then
						tmp.cmd = "bm-give " .. chatvars.userID .. " ammoGasCan /" .. 400 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
					botman.gimmeQueueEmpty = false
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "eatStew") then
				tmp.cmd = "give " .. chatvars.userID .. " foodMeatStew 20"

				if server.botman then
					tmp.cmd = "bm-give " .. chatvars.userID .. " foodMeatStew 20"
				end

				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
				botman.gimmeQueueEmpty = false
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "foodMeatStew")

				if tonumber(tmp.quantity) < 20 then
					tmp.cmd = "give " .. chatvars.userID .. " foodMeatStew " .. 20 - tonumber(tmp.quantity)

					if server.botman then
						tmp.cmd = "bm-give " .. chatvars.userID .. " foodMeatStew " .. 20 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
					botman.gimmeQueueEmpty = false
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "irstAidKit") then
				tmp.cmd = "give " .. chatvars.userID .. " medicalFirstAidKit 10"

				if server.botman then
					tmp.cmd = "bm-give " .. chatvars.userID .. " medicalFirstAidKit 10"
				end

				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
				botman.gimmeQueueEmpty = false
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "medicalFirstAidKit")

				if tonumber(tmp.quantity) < 10 then
					tmp.cmd = "give " .. chatvars.userID .. " medicalFirstAidKit " .. 10 - tonumber(tmp.quantity)

					if server.botman then
						tmp.cmd = "bm-give " .. chatvars.userID .. " medicalFirstAidKit " .. 10 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
					botman.gimmeQueueEmpty = false
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "ntibiotics") then
				tmp.cmd = "give " .. chatvars.userID .. " drugAntibiotics 10"

				if server.botman then
					tmp.cmd = "bm-give " .. chatvars.userID .. " drugAntibiotics 10"
				end

				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
				botman.gimmeQueueEmpty = false
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "drugAntibiotics")

				if tonumber(tmp.quantity) < 10 then
					tmp.cmd = "give " .. chatvars.userID .. " drugAntibiotics " .. 10 - tonumber(tmp.quantity)

					if server.botman then
						tmp.cmd = "bm-give " .. chatvars.userID .. " drugAntibiotics " .. 10 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
					botman.gimmeQueueEmpty = false
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "ShotgunShell") then
				tmp.cmd = "give " .. chatvars.userID .. " ammoShotgunShell 500"

				if server.botman then
					tmp.cmd = "bm-give " .. chatvars.userID .. " ammoShotgunShell 500"
				end

				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
				botman.gimmeQueueEmpty = false
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "ShotgunShell")

				if tonumber(tmp.quantity) < 500 then
					tmp.cmd = "give " .. chatvars.userID .. " ammoShotgunShell " .. 500 - tonumber(tmp.quantity)

					if server.botman then
						tmp.cmd = "bm-give " .. chatvars.userID .. " ammoShotgunShell " .. 500 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
					botman.gimmeQueueEmpty = false
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory .. tmp.equipment, "pimpMiningHelmetAdmin") then
				tmp.cmd = "give " .. chatvars.userID .. " pimpMiningHelmetAdmin 1 6"

				if server.botman then
					tmp.cmd = "bm-give " .. chatvars.userID .. " pimpMiningHelmetAdmin 1 6"
				end

				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
				botman.gimmeQueueEmpty = false
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quality = getEquipment(tmp.equipment, "pimpMiningHelmetAdmin")

				if not tmp.found then
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "pimpMiningHelmetAdmin")
				end

				if not tmp.found then
					tmp.cmd = "give " .. chatvars.userID .. " pimpMiningHelmetAdmin 1 6"

					if server.botman then
						tmp.cmd = "bm-give " .. chatvars.userID .. " pimpMiningHelmetAdmin 1 6"
					end

					if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
					botman.gimmeQueueEmpty = false
					tmp.gaveStuff = true
				end
			end

			if tmp.gaveStuff then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]SUPPLIES![-]")
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You don't need any more supplies :P[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GiveBackClaims()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}give (claim or key or lcb)"
			help[2] = "The bot can despawn player placed claims in reset zones.  This command is for them to request them back from the bot.\n"
			help[2] = help[2] .. "It will only return the number that it took away.  If it isn't holding any, it won't give any back."

			tmp.command = help[1]
			tmp.keywords = "give,claimblocks,lcb,keystone,landclaims"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "give") or string.find(chatvars.command, "claim") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "give" and (string.find(chatvars.words[2], "claim") or string.find(chatvars.words[2], "key") or string.find(chatvars.words[2], "lcb")) then
			CheckClaimsRemoved(chatvars.playerid)

			if players[chatvars.playerid].removedClaims > 0 then
				tmp.cmd = "give " .. chatvars.userID .. " keystoneBlock " .. players[chatvars.playerid].removedClaims

				if server.botman then
					tmp.cmd = "bm-give " .. chatvars.userID .. " keystoneBlock " .. players[chatvars.playerid].removedClaims
				end

				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. chatvars.playerid .. "')") end
				botman.gimmeQueueEmpty = false

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I was holding " .. players[chatvars.playerid].removedClaims .. " keystones for you. Check the ground for them if they didn't go directly into your inventory.[-]")
				players[chatvars.playerid].removedClaims = 0
				if botman.dbConnected then conn:execute("UPDATE players SET removedClaims = 0 WHERE steam = '" .. chatvars.playerid .. "'") end
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I have no keystones to give you at this time.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GiveEveryoneItem()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}give everyone {item} {amount} {quality}"
			help[2] = "Give everyone that is playing on the server right now an amount of an item. The default is to give 1 item.\n"
			help[2] = help[2] .. "If quality is not given, it will have a random quality for each player.\n"
			help[2] = help[2] .. "Anyone not currently playing will not receive the item."

			tmp.command = help[1]
			tmp.keywords = "give,items,all,everyone,equipment"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "give") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "give" and chatvars.words[2] == "everyone") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.quantity = 1

			if chatvars.numbers then
				if chatvars.numbers[1] then
					tmp.quantity = chatvars.numbers[1]
				end

				if chatvars.numbers[2] then
					tmp.quality = chatvars.numbers[2]
				end
			end

			for k, v in pairs(igplayers) do
				message(string.format("pm %s [%s]>FREE< STUFF!  Press e to pick up some %s now. =D[-]", v.userID, server.chatColour, chatvars.wordsOld[3]))

				if tmp.quality then
					tmp.cmd = "give " .. v.userID .. " " .. chatvars.wordsOld[3] .. " " .. tmp.quantity .. " " .. tmp.quality

					if server.botman then
						tmp.cmd = "bm-give " .. v.userID .. " " .. chatvars.wordsOld[3] .. " " .. tmp.quantity .. " " .. tmp.quality
					end
				else
					tmp.cmd = "give " .. v.userID .. " " .. chatvars.wordsOld[3] .. " " .. tmp.quantity

					if server.botman then
						tmp.cmd = "bm-give " .. v.userID .. " " .. chatvars.wordsOld[3] .. " " .. tmp.quantity
					end
				end

				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. k .. "')") end
				botman.gimmeQueueEmpty = false
			end

			if (chatvars.playername ~= "Server") then
				message(string.format("pm %s [%s]You gave everyone playing right now %s %s[-]", chatvars.userID, server.chatColour, tmp.quantity, chatvars.wordsOld[3]))
			else
				irc_chat(chatvars.ircAlias, string.format("You gave everyone playing right now %s %s", tmp.quantity, chatvars.wordsOld[3]))
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GivePlayerItem()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}give player {joe} item {item} {amount} {quality}\n"
			help[1] = help[1] .. " {#}give player {joe} item {item} {amount} {quality} message {say something here}"
			help[2] = "Give a specific player amount of an item. The default is to give 1 item.\n"
			help[2] = help[2] .. "The player does not need to be on the server.  They will receive the item and optional message when they next join.\n"
			help[2] = help[2] .. "You can give more items but only 1 item type per command.  Items are given in the same order so you could include a message with the first item and they will read that first."

			tmp.command = help[1]
			tmp.keywords = "give,items,player,equipment"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "give") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "give" and chatvars.words[2] == "player" and string.find(chatvars.command, "item") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.quantity = 1

			for i=3,chatvars.wordCount,1 do
				if chatvars.words[i] == "item" then
					tmp.item = chatvars.wordsOld[i+1]
					tmp.quantity = chatvars.words[i+2]
					tmp.quality = chatvars.words[i+3]
				end
			end

			if string.find(chatvars.command, "message") then
				tmp.message = string.sub(chatvars.commandOld, string.find(chatvars.command, "message ") + 8)
			end

			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7, string.find(chatvars.command, " item ") - 1)
			tmp.pname = string.trim(tmp.pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(tmp.pname)

				if not (tmp.steam == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if igplayers[tmp.steam] then
				message(string.format("pm %s [%s]>FREE< STUFF!  Press e to pick up some %s now. =D[-]", tmp.userID, server.chatColour, tmp.item))

				if tmp.quality then
					tmp.cmd = "give " .. tmp.userID .. " " .. tmp.item .. " " .. tmp.quantity .. " " .. tmp.quality

					if server.botman then
						sendCommand("bm-give " .. tmp.userID .. " " .. tmp.item .. " " .. tmp.quantity .. " " .. tmp.quality)
					end
				else
					tmp.cmd = "give " .. tmp.userID .. " " .. tmp.item .. " " .. tmp.quantity

					if server.botman then
						tmp.cmd = "bm-give " .. tmp.userID .. " " .. tmp.item .. " " .. tmp.quantity
					end
				end

				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. connMEM:escape(tmp.cmd) .. "', '" .. tmp.steam .. "')") end
				botman.gimmeQueueEmpty = false

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]You gave %s %s %s[-]", chatvars.userID, server.chatColour, players[tmp.steam].name, tmp.quantity, tmp.item))
				else
					irc_chat(chatvars.ircAlias, string.format("You gave %s %s %s", players[tmp.steam].name, tmp.quantity, tmp.item))
				end
			else
				-- queue the give and optional message for later when the player joins the server
				if tmp.quality then
					tmp.cmd = "give " .. tmp.userID .. " " .. tmp.item .. " " .. tmp.quantity .. " " .. tmp.quality

					if server.botman then
						tmp.cmd = "bm-give " .. tmp.userID .. " " .. tmp.item .. " " .. tmp.quantity .. " " .. tmp.quality
					end
				else
					tmp.cmd = "give " .. tmp.userID .. " " .. tmp.item .. " " .. tmp.quantity

					if server.botman then
						tmp.cmd = "bm-give " .. tmp.userID .. " " .. tmp.item .. " " .. tmp.quantity
					end
				end

				if botman.dbConnected then connSQL:execute("INSERT into connectQueue (steam, command) VALUES ('" .. tmp.steam .. "', '" .. connMEM:escape(tmp.cmd) .. "')") end

				if tmp.message then
					tmp.cmd = "pm " .. tmp.userID .. " [" .. server.chatColour .. "]" .. tmp.message .. "[-]"
					if botman.dbConnected then connSQL:execute("INSERT into connectQueue (steam, command) VALUES ('" .. tmp.steam .. "', '" .. connMEM:escape(tmp.cmd) .. "')") end

					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]When %s next joins the server they will get %s %s with the message %s[-]", chatvars.userID, server.chatColour, players[tmp.steam].name, tmp.quantity, tmp.item, tmp.message))
					else
						irc_chat(chatvars.ircAlias, string.format("When %s next joins the server they will get %s %s with the message %s", players[tmp.steam].name, tmp.quantity, tmp.item, tmp.message))
					end
				else
					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]When %s next joins the server they will get %s %s[-]", chatvars.userID, server.chatColour, players[tmp.steam].name, tmp.quantity, tmp.item))
					else
						irc_chat(chatvars.ircAlias, string.format("When %s next joins the server they will get %s %s", players[tmp.steam].name, tmp.quantity, tmp.item))
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GotoPlayer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}goto {player or steam or game ID}"
			help[2] = "Teleport to the current position of a player.  This works with offline players too."

			tmp.command = help[1]
			tmp.keywords = "teleport,goto,player,visit"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "goto") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "goto" and chatvars.words[2] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (players[chatvars.playerid].timeout or players[chatvars.playerid].botTimeout) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are in timeout. You cannot " .. server.commandPrefix .. "goto anywhere until you are released.[-]")
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "goto ") + 5)

			-- first record the current x y z
			players[chatvars.playerid].xPosOld = chatvars.intX
			players[chatvars.playerid].yPosOld = chatvars.intY
			players[chatvars.playerid].zPosOld = chatvars.intZ

			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupArchivedPlayer(pname)

				if (tmp.steam == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			end

			-- then teleport to the player
			if not isArchived then
				cmd = "tele " .. chatvars.userID.. " " .. players[tmp.steam].xPos + 1 .. " " .. players[tmp.steam].yPos .. " " .. players[tmp.steam].zPos
			else
				cmd = "tele " .. chatvars.userID.. " " .. playersArchived[tmp.steam].xPos + 1 .. " " .. playersArchived[tmp.steam].yPos .. " " .. playersArchived[tmp.steam].zPos
			end

			teleport(cmd, chatvars.playerid, chatvars.userID)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_HordeMe() --tested
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}hordeme"
			help[2] = "Spawn a horde of 50 random zombies on yourself.  Only admins can do this (but not mods)"

			tmp.command = help[1]
			tmp.keywords = "spawn,horde,self,admin,fun"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "horde") or string.find(chatvars.command, "spawn") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "hordeme") or (chatvars.words[1] == "hordme") or (string.find(chatvars.command, "this is sparta")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			for i=1,50,1 do
				cmd = "se " .. players[chatvars.playerid].id .. " " .. PicknMix()
				if botman.dbConnected then connMEM:execute("INSERT into gimmeQueue (steam, command) VALUES ('" .. chatvars.playerid .. "','" .. cmd .. "')") end
				botman.gimmeQueueEmpty = false
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_KickPlayer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}kick {player name or Steam ID or Game ID} reason {optional reason}"
			help[2] = "Is Joe annoying you?  Kick his ass right out of the server! >:D"

			tmp.command = help[1]
			tmp.keywords = "kick,player,admin"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "kick") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "kick" and chatvars.words[2] ~= nil) then
			local playerName

			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			reason = "An admin kicked you."

			if string.find(chatvars.command, " reason ") then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "kick ") + 5, string.find(chatvars.command, " reason") - 1)
				reason = string.sub(chatvars.commandOld, string.find(chatvars.command, "reason ") + 7)
			else
				pname = string.sub(chatvars.command, string.find(chatvars.command, "kick ") + 5)
			end

			tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupArchivedPlayer(pname)

				if tmp.steam  ~= "0" then
					playerName = playersArchived[tmp.steam].name
				end
			else
				playerName = players[tmp.steam].name
			end

			if tmp.steam == "0" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
				end

				botman.faultyChat = false
				return true
			end

			if not igplayers[tmp.steam] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playerName .. " is not on the server right now.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. playerName .. " is not on the server right now.")
				end

				botman.faultyChat = false
				return true
			end

			if not isAdminHidden(tmp.steam, tmp.userID) then
				kick(tmp.steam, reason)
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I won't kick staff.  :O[-]")
				else
					irc_chat(chatvars.ircAlias, "I won't kick staff.  :O")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LeavePlayerClaims()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}leave claims {player name}"
			help[2] = "Stop the bot automatically removing a player's claims.  They will still be removed if they are in a location that doesn't allow player claims."

			tmp.command = help[1]
			tmp.keywords = "landclaims,keystones,lcb"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "claim") or string.find(chatvars.command, "keys") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "leave" and chatvars.words[2] == "claims" and chatvars.words[3] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = chatvars.words[3]
			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if tmp.steam ~= "0" then
				-- this player's claims will not be removed unless in a reset zone and not staff
				if not isArchived then
					players[tmp.steam].removeClaims = false
					if botman.dbConnected then conn:execute("UPDATE players SET removeClaims = 0 WHERE steam = '" .. tmp.steam .. "'") end
				else
					playersArchived[tmp.steam].removeClaims = false
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET removeClaims = 0 WHERE steam = '" .. tmp.steam .. "'") end
				end

				if botman.dbConnected then connSQL:execute("UPDATE keystones SET remove = 0 WHERE steam = '" .. tmp.steam .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playerName .. "'s claims will not be removed unless found in reset zones (if not staff).[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. "'s claims will not be removed unless found in reset zones (if not staff)")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBadItems()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}bad items"
			help[2] = "List the items that are not allowed in player inventories and what action is taken."

			tmp.command = help[1]
			tmp.keywords = "list,bad,items,inventory"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "item") or string.find(chatvars.command, "bad") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "bad" and chatvars.words[2] == "items") or (chatvars.words[1] == "list" and chatvars.words[2] == "bad" and chatvars.words[3] == "items") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I scan for these bad items in inventory:[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Item -> Action[-]")
			else
				irc_chat(chatvars.ircAlias, "I scan for these bad items in inventory:")
				irc_chat(chatvars.ircAlias, "Item -> Action")
			end

			for k, v in pairs(badItems) do
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. k .. " -> " .. v.action  .. "[-]")
				else
					irc_chat(chatvars.ircAlias, k .. " -> " .. v.action)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBadWords()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}bad words"
			help[2] = "List the bad words and what the bot will do about them. Also has a counter of how often they have been seen."

			tmp.command = help[1]
			tmp.keywords = "list,bad,words"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "words") or string.find(chatvars.command, "bad") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "bad" and chatvars.words[2] == "words") or (chatvars.words[1] == "list" and chatvars.words[2] == "bad" and chatvars.words[3] == "words") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I scan for these bad words in chat:[-]")
			else
				irc_chat(chatvars.ircAlias, "I scan for these bad words in chat:")
			end

			for k, v in pairs(badWords) do
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. k .. " count: " .. v.counter  .. " cost: " .. v.cost .. " response: " .. v.response .. " cooldown: " .. v.cooldown .. "[-]")
				else
					irc_chat(chatvars.ircAlias, k .. " count: " .. v.counter  .. " cost: " .. v.cost .. " response: " .. v.response .. " cooldown: " .. v.cooldown)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBasesNearby()
		local playerName, isArchived, protected

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}bases (or {#}homes)\n"
			help[1] = help[1] .. "Or {#}bases (or {#}homes) range {number}\n"
			help[1] = help[1] .. "Or {#}bases (or {#}homes) near {player name} range {number}"
			help[2] = "See what player bases are nearby.  You can use it on yourself or on a player.  Range and player are optional.  The default range is 200 metres."

			tmp.command = help[1]
			tmp.keywords = "bases,homes,range,near,player,list"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "base") or string.find(chatvars.command, "home") or string.find(chatvars.command, "admin") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "bases" or chatvars.words[1] == "homes") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			alone = true
			if (chatvars.number == nil) then chatvars.number = 201 end

			if (not string.find(chatvars.command, "range")) and (not string.find(chatvars.command, "near")) then
				for k, v in pairs(bases) do
					dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, v.x, v.z)

					if dist < tonumber(chatvars.number) then
						if (alone == true) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of you are:[-]") end

						if v.protect then
							protected = " protected"
						else
							protected = ""
						end

						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[v.steam].name .. "   base " .. string.trim(v.baseNumber .. " " .. v.title) .. "   distance  " .. string.format("%-8.2d", dist) .. protected .. "[-]")
						alone = false
					end
				end

				if (alone == true) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There are none within " .. chatvars.number .. " meters of you.")
				end
			else
				if string.find(chatvars.command, "range") then
					name1 = string.sub(chatvars.command, string.find(chatvars.command, "near") + 5, string.find(chatvars.command, "range") - 1)
					chatvars.number = string.sub(chatvars.command, string.find(chatvars.command, "range") + 6)
				else
					name1 = string.sub(chatvars.command, string.find(chatvars.command, "near") + 5)
				end

				if string.find(chatvars.command, "nearby") then
					tmp.steam = chatvars.playerid
				else
					name1 = string.trim(name1)
					tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(name1)
				end

				if tmp.steam == "0" then
					tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(name1)

					if not (tmp.steam == "0") then
						playerName = playersArchived[tmp.steam].name
						isArchived = true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. name1 .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. name1)
						end

						botman.faultyChat = false
						return true
					end
				else
					playerName = players[tmp.steam].name
					isArchived = false
				end

				if (tmp.steam ~= "0") then
					for k, v in pairs(bases) do
							if not isArchived then
								dist = distancexz(players[tmp.steam].xPos, players[tmp.steam].zPos, v.x, v.z)
							else
								dist = distancexz(playersArchived[tmp.steam].xPos, playersArchived[tmp.steam].zPos, v.x, v.z)
							end

							if dist < tonumber(chatvars.number) then
								if (alone == true) then message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of " .. playerName .. " are:[-]") end

								if v.protect then
									protected = " protected"
								else
									protected = ""
								end

								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[v.steam].name .. "   base " .. string.trim(v.baseNumber .. " " .. v.title) .. "   distance  " .. string.format("%-8.2d", dist) .. protected .. "[-]")
								alone = false
							end
					end

					if (alone == true) then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]There are none within " .. chatvars.number .. " meters of " .. playerName .. "[-]")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBlacklist()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list blacklist"
			help[2] = "List the countries that are not allowed to play on the server."

			tmp.command = help[1]
			tmp.keywords = "view,list,blacklist,country,countries"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "blacklist") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "list" and chatvars.words[2] == "blacklist") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if server.blacklistCountries ~= "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]These countries are blacklisted: " .. server.blacklistCountries .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "These countries are blacklisted: " .. server.blacklistCountries)
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No countries are blacklisted.[-]")
				else
					irc_chat(chatvars.ircAlias, "No countries are blacklisted.")
				end
			end

			irc_chat(chatvars.ircAlias, ".")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListClaims()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}claims {range} (range is optional and defaults to 50)"
			help[2] = "List all of the claims within range with who owns them"

			tmp.command = help[1]
			tmp.keywords = "view,list,claimblocks,lcb,keystones"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "claim") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "claims") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				chatvars.number = 50
			end

			if botman.dbConnected then
				cursor,errorString = connSQL:execute("SELECT * FROM keystones WHERE abs(x - " .. chatvars.intX .. ") <= " .. chatvars.number .. " AND abs(z - " .. chatvars.intZ .. ") <= " .. chatvars.number)
				row = cursor:fetch({}, "a")

				while row do
					if (chatvars.playername ~= "Server") then
						if players[row.steam] then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[row.steam].name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. "[-]")
						else
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.steam .. " " .. row.x .. " " .. row.y .. " " .. row.z .. "[-]")
						end
					else
						irc_chat(chatvars.ircAlias, players[row.steam].name .. " " .. row.x .. " " .. row.y .. " " .. row.z)
					end

					row = cursor:fetch(row, "a")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListOfflinePlayersNearby()
		local count

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}offline players nearby\n"
			help[1] = help[1] .. " {#}offline players nearby range {number}"
			help[2] = "List all offline players near your position. The default range is 200 metres."

			tmp.command = help[1]
			tmp.keywords = "list,offline,players,nearby"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "offline") or string.find(chatvars.command, "player") or string.find(chatvars.command, "near") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "offline" and chatvars.words[2] == "players" and chatvars.words[3] == "nearby") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			chatvars.number = 201

			if string.find(chatvars.command, "range") then
				chatvars.number = string.sub(chatvars.command, string.find(chatvars.command, "range") + 6)
			end

			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]offline players within " .. chatvars.number .. " meters of you are:[-]")

			alone = true
			count = 0

			for k, v in pairs(players) do
				if igplayers[k] == nil and v.xPos ~= nil then
					dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, v.xPos, v.zPos)
					dist = math.abs(dist)

					if tonumber(dist) <= tonumber(chatvars.number) then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%d", dist) .. "[-]")
						alone = false
						count = count + 1
					end
				end

				if count > 30 then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Too many results. Command aborted.[-]")

					botman.faultyChat = false
					return true
				end
			end

			if (alone == true) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No offline players within range.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListPrisoners()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}prisoners"
			help[2] = "List all the players who are prisoners."

			tmp.command = help[1]
			tmp.keywords = "list,view,prisoners"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "prisoners" and chatvars.words[2] == nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]List of prisoners:[-]")
			else
				irc_chat(chatvars.ircAlias, "List of prisoners:")
			end

			for k, v in pairs(players) do
				if v.prisoner then
					tmp = {}

					if v.prisonReason then
						tmp.reason = v.prisonReason
					else
						tmp.reason = ""
					end

					if v.pvpVictim == "0" then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. v.name .. " " .. tmp.reason .. "[-]")
						else
							irc_chat(chatvars.ircAlias, v.name .. " " .. tmp.reason)
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. v.name .. " PVP " .. players[v.pvpVictim].name .. "[-]")
						else
							irc_chat(chatvars.ircAlias, v.name .. " PVP " .. players[v.pvpVictim].name)
						end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListRestrictedItems()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}restricted items"
			help[2] = "List the items that new players are not allowed to have in inventory and what action is taken."

			tmp.command = help[1]
			tmp.keywords = "list,view,restricted,items,inventory"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "item") or string.find(chatvars.command, "rest") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "restricted" and chatvars.words[2] == "items") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]I scan for these restricted items in inventory:[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Item | Quantity | Access Level | Action[-]")
			else
				irc_chat(chatvars.ircAlias, "I scan for these restricted items in inventory:")
				irc_chat(chatvars.ircAlias, "Item | Quantity | Access Level | Action")
			end

			for k, v in pairs(restrictedItems) do
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. k .. " max qty " .. v.qty .. " min access " .. v.accessLevel .. " action " .. v.action .. "[-]")
				else
					irc_chat(chatvars.ircAlias, k .. " max qty " .. v.qty .. " min access " .. v.accessLevel .. " action " .. v.action)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListStaff()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list staff/admins"
			help[2] = "Lists the server staff and shows who if any are playing."

			tmp.command = help[1]
			tmp.keywords = "list,view,staff,admins"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "staff") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "list" and (chatvars.words[2] == "staff" or chatvars.words[2] == "admins") or (chatvars.words[1] == "admins" or chatvars.words[1] == "staff") and chatvars.words[3] == nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			listStaff(chatvars.playerid, true)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListWhitelist()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}list whitelist"
			help[2] = "List the countries that are allowed to play on the server."

			tmp.command = help[1]
			tmp.keywords = "view,whitelist,countries,country"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "list") or string.find(chatvars.command, "whitelist") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "list" and chatvars.words[2] == "whitelist") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if server.whitelistCountries ~= "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]These countries are whitelisted: " .. server.whitelistCountries .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "These countries are whitelisted: " .. server.whitelistCountries)
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No countries are whitelisted.[-]")
				else
					irc_chat(chatvars.ircAlias, "No countries are whitelisted.")
				end
			end

			counter = 0
			for k,v in pairs(whitelist) do
				if counter == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The following players are whitelisted:[-]")
					else
						irc_chat(chatvars.ircAlias, ".")
						irc_chat(chatvars.ircAlias, "The following players are whitelisted:")
					end

					counter = counter + 1
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[k].name .. " - " .. players[k].country .. "[-]")
				else
					irc_chat(chatvars.ircAlias, players[k].name .. " - " .. players[k].country)
				end
			end

			irc_chat(chatvars.ircAlias, ".")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MendPlayer() --tested
		local steam, steamOwner, userID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}mend {player name}"
			help[2] = "Remove the brokenLeg buff from a player or yourself if no name given."

			tmp.command = help[1]
			tmp.keywords = "mend,fix,leg,player,fun,medical,firstaid"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "mend") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "mend") then
			if LookupLocation("mend") ~= nil then
				botman.faultyChat = false
				return false
			end

			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			steam = chatvars.playerid

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				steam, steamOwner, userID = LookupPlayer(pname)

				if steam == "0" then
					steam, steamOwner, userID = LookupArchivedPlayer(pname)

					if not (steam == "0") then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[steam] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. igplayers[steam].name .. " is not playing right now and can't catch a break.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[steam].name .. " is not playing right now and can't catch a break.")
				end

				botman.faultyChat = false
				return true
			end

			sendCommand("debuffplayer " .. userID .. " buffLegSprained")
			sendCommand("debuffplayer " .. userID .. " buffLegBroken")
			sendCommand("debuffplayer " .. userID .. " buffLegSplinted")
			sendCommand("debuffplayer " .. userID .. " buffLegCast")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You fixed " .. players[steam].name .. "'s legs[-]")
			else
				irc_chat(chatvars.ircAlias, "You fixed " .. players[steam].name .. "'s legs")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MovePlayer()
		local playerName, isArchived
		local steam, steamOwner, userID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}move {player name} to {location}"
			help[2] = "Teleport a player to a location. To teleport them to another player use the send command.  If the player is offline, they will be moved to the location when they next join."

			tmp.command = help[1]
			tmp.keywords = "move,player,locations,teleport"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "move") or string.find(chatvars.command, "player") or string.find(chatvars.command, "tele") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "move") and chatvars.words[2] ~= nil and string.find(chatvars.command, " to ") and not string.find(chatvars.command, " group ") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "move") + 5, string.find(chatvars.command, " to ") - 1)
			pname = string.trim(pname)

			location = string.sub(chatvars.command, string.find(chatvars.command, " to ") + 4)
			location = string.trim(location)

			loc = LookupLocation(location)
			steam, steamOwner, userID = LookupPlayer(pname)

			if steam == "0" then
				steam, steamOwner, userID = LookupArchivedPlayer(pname)

				if not (steam == "0") then
					playerName = playersArchived[steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[steam].name
				isArchived = false
			end

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No location matched.[-]")
				else
					irc_chat(chatvars.ircAlias, "No location matched.")
				end

				botman.faultyChat = false
				return true
			end

			-- if the player is ingame, send them to the lobby otherwise flag it to happen when they rejoin
			if (igplayers[steam]) then
				cmd = "tele " .. userID .. " " .. locations[loc].x .. " " .. locations[loc].y .. " " .. locations[loc].z
				igplayers[steam].lastTP = cmd
				teleport(cmd, steam, userID)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. players[steam].name .. " has been sent to " .. locations[loc].name .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[steam].name .. " has been sent to " .. locations[loc].name)
				end
			else
				if not isArchived then
					players[steam].location = loc
					if botman.dbConnected then conn:execute("UPDATE players SET location = '" .. loc .. "' WHERE steam = '" .. steam .. "'") end

					players[steam].xPosOld = locations[loc].x
					players[steam].yPosOld = locations[loc].y
					players[steam].zPosOld = locations[loc].z
				else
					playersArchived[steam].location = loc
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET location = '" .. loc .. "' WHERE steam = '" .. steam .. "'") end

					playersArchived[steam].xPosOld = locations[loc].x
					playersArchived[steam].yPosOld = locations[loc].y
					playersArchived[steam].zPosOld = locations[loc].z
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playerName .. " will be moved to " .. locations[loc].name .. " next time they join.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. playerName .. " will be moved to " .. locations[loc].name .. " next time they join.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_NearPlayer()
		local isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}near {player name} {optional number (distance away from player)}"
			help[2] = "Teleport below and a short distance away from a player.  You must be flying for this or you will just fall all the time.\n"
			help[2] = help[2] .. "You arrive 20 metres below the player and 30 metres to the south.  If you give a number after the player name you will be that number metres south of them.\n"
			help[2] = help[2] .. "The bot will keep you near the player, teleporting you close to them if they get away from you.\n"
			help[2] = help[2] .. "To stop following them type {#}stop or use any teleport command or relog."

			tmp.command = help[1]
			tmp.keywords = "goto,player,near,spy"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "goto") or string.find(chatvars.command, "near") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "closeto" or chatvars.words[1] == "near") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (players[chatvars.playerid].timeout or players[chatvars.playerid].botTimeout) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are in timeout. You cannot go anywhere until you are released for safety reasons.[-]")
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "closeto" then
				pname = chatvars.words[2]
			end

			if chatvars.words[1] == "near" then
				pname = chatvars.words[2]
			end

			igplayers[chatvars.playerid].followDistance = 30

			if chatvars.words[3] ~= nil then
				igplayers[chatvars.playerid].followDistance = tonumber(chatvars.words[3])
			end

			-- first record the current x y z
			players[chatvars.playerid].xPosOld = chatvars.intX
			players[chatvars.playerid].yPosOld = chatvars.intY
			players[chatvars.playerid].zPosOld = chatvars.intZ

			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				isArchived = false
			end

			igplayers[chatvars.playerid].following = tmp.steam

			-- then teleport close to the player
			if not isArchived then
				if igplayers[tmp.steam] then
					cmd = "tele " .. chatvars.userID.. " " .. igplayers[tmp.steam].xPos .. " " .. igplayers[tmp.steam].yPos - 20 .. " " .. igplayers[tmp.steam].zPos - igplayers[chatvars.playerid].followDistance
				else
					cmd = "tele " .. chatvars.userID.. " " .. players[tmp.steam].xPos .. " " .. players[tmp.steam].yPos - 20 .. " " .. players[tmp.steam].zPos - igplayers[chatvars.playerid].followDistance
				end
			else
				cmd = "tele " .. chatvars.userID.. " " .. playersArchived[tmp.steam].xPos .. " " .. playersArchived[tmp.steam].yPos - 20 .. " " .. playersArchived[tmp.steam].zPos - igplayers[chatvars.playerid].followDistance
			end

			sendCommand(cmd)
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PlayerIsNotNew()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}player {player name} is not new"
			help[2] = "Upgrade a new player to a regular without making them wait for the bot to upgrade them. They will no longer be as restricted as a new player."

			tmp.command = help[1]
			tmp.keywords = "player,new,status,upgrade,promote"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "new") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "player" and string.find(chatvars.command, "is not new")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = chatvars.words[2]
			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if tmp.steam ~= "0" then
				-- set the newPlayer flag to false
				if not isArchived then
					players[tmp.steam].newPlayer = false
					players[tmp.steam].watchPlayer = false
					players[tmp.steam].watchPlayerTimer = 0

					if botman.dbConnected then
						conn:execute("UPDATE players SET newPlayer = 0, watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = '" .. tmp.steam .. "'")
					end

					setGroupMembership(tmp.steam, "New Players", false)
				else
					playersArchived[tmp.steam].newPlayer = false
					playersArchived[tmp.steam].watchPlayer = false
					playersArchived[tmp.steam].watchPlayerTimer = 0
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET newPlayer = 0, watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = '" .. tmp.steam .. "'") end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PootaterPlayer() --tested
		local steam, steamOwner, userID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}poop {player name}"
			help[2] = "Make a player shit potatoes everywhere coz potatoes."

			tmp.command = help[1]
			tmp.keywords = "poop,player,buff,shit,fun,potatoes"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "poo") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "poop") then
			if LookupLocation("poop") ~= nil then -- There's a location called poop?  AWESOME!
				botman.faultyChat = false
				return false
			end

			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				steam, steamOwner, userID = LookupPlayer(pname)

				if steam == "0" then
					steam, steamOwner, userID = LookupArchivedPlayer(pname)

					if not (steam == "0") then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[steam] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. igplayers[steam].name .. " is not playing right now and can't catch shit.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[steam].name .. " is not playing right now and can't catch shit.")
				end

				botman.faultyChat = false
				return true
			end

			if isAdminHidden(steam, userID) then
				message("pm " .. userID .. " [" .. server.alertColour .. "]" .. players[chatvars.playerid].name .. " cast poop on you.  It is super effective.[-]")
			end

			r = randSQL(10,30)

			message("say [" .. server.chatColour .. "]" .. players[steam].name .. " ate a bad potato and is shitting potatoes everywhere![-]")
			cmd = "give " .. userID .. " foodBakedPotato 1"

			for i = 1, r do
				connMEM:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', '" .. steam .. "')")
				botman.gimmeQueueEmpty = false
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Boil em, mash em, stick em in " .. players[steam].name .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, "Boil em, mash em, stick em in " .. players[steam].name)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReadClaims()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}read claims"
			help[2] = "Make the bot run llp so it knows where all the claims are and who owns them."

			tmp.command = help[1]
			tmp.keywords = "read,claimblocks,lcb,keystones"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "read claims")) and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "read" and chatvars.words[2] == "claims" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			-- run llp
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Reading claims[-]")
			sendCommand("llp parseable")
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReleasePlayer()
		local playerName, isArchived
		local prisonerSteam, prisonerSteamOwner, prisonerUserID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}release {player name}\n"
			help[1] = help[1] .. "Or {#}just release {player name}"
			help[2] = "Release a player from prison.  They are teleported back to where they were arrested.\n"
			help[2] = help[2] .. "Alternatively just release them so they do not teleport and have to walk back or use bot commands.\n"
			help[2] = help[2] .. "See also {#}release here (admin only)"

			tmp.command = help[1]
			tmp.keywords = "release,free,prisoners,player,jail,gaol"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "prison") or string.find(chatvars.command, "releas") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "release" or (chatvars.words[1] == "just" and chatvars.words[2] == "release")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			prisoner = string.sub(chatvars.command, string.find(chatvars.command, "release ") + 8)
			prisoner = string.trim(prisoner)
			prisonerSteam, prisonerSteamOwner, prisonerUserID = LookupPlayer(prisoner)
			prisoner = players[prisonerSteam].name

			if prisonerSteam == "0" then
				prisonerSteam, prisonerSteamOwner, prisonerUserID = LookupArchivedPlayer(prisoner)

				if not (prisonerSteam == "0") then
					playerName = playersArchived[prisonerSteam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. prisoner)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[prisonerSteam].name
				isArchived = false
			end

			if (chatvars.playername ~= "Server") then
				if not chatvars.isAdminHidden then
					if (prisonerSteam == chatvars.playerid) then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You can't release yourself.  This isn't Idiocracy (except in Florida and Texas).[-]")
						botman.faultyChat = false
						return true
					end

					if not isArchived then
						if (players[prisonerSteam].pvpVictim ~= chatvars.playerid) then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. prisoner .. " is not in prison for your death and cannot be released by you.[-]")
							botman.faultyChat = false
							return true
						end
					else
						if (playersArchived[prisonerSteam].pvpVictim ~= chatvars.playerid) then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. prisoner .. " is not in prison for your death and cannot be released by you.[-]")
							botman.faultyChat = false
							return true
						end
					end
				end
			end

			if (players[prisonerSteam].timeout or players[prisonerSteam].botTimeout) then
				if not isArchived then
					players[prisonerSteam].timeout = false
					players[prisonerSteam].botTimeout = false
					players[prisonerSteam].freeze = false
					players[prisonerSteam].silentBob = false
					players[prisonerSteam].bail = 0
					gmsg(server.commandPrefix .. "return " .. prisonerSteam)
					setChatColour(prisonerSteam, players[prisonerSteam].accessLevel)

					if botman.dbConnected then
						conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0, bail = 0 WHERE steam = '" .. prisonerSteam .. "'")
						connSQL:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0, bail = 0 WHERE steam = '" .. prisonerSteam .. "'")
					end
				else
					playersArchived[prisonerSteam].timeout = false
					playersArchived[prisonerSteam].botTimeout = false
					playersArchived[prisonerSteam].freeze = false
					playersArchived[prisonerSteam].silentBob = false
					playersArchived[prisonerSteam].bail = 0

					if botman.dbConnected then
						conn:execute("UPDATE playersArchived SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0, bail = 0 WHERE steam = '" .. prisonerSteam .. "'")
						connSQL:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0, bail = 0 WHERE steam = '" .. prisonerSteam .. "'")
					end
				end
			end

			if (not players[prisonerSteam].prisoner and players[prisonerSteam].timeout == false) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Citizen " .. prisoner .. " is not a prisoner[-]")
				else
					irc_chat(chatvars.ircAlias, "Citizen " .. prisoner .. " is not a prisoner")
				end

				botman.faultyChat = false
				return true
			end

			if (igplayers[prisonerSteam]) then
				message("say [" .. server.warnColour .. "]Prisoner " .. prisoner .. " has been pardoned.[-]")
				message("pm " .. prisonerUserID .. " [" .. server.chatColour .. "]You are released from prison.  Be a good citizen if you wish to remain free.[-]")

				if (chatvars.words[1] ~= "just") then
					if (players[prisonerSteam].prisonxPosOld) then
						cmd = "tele " .. prisonerUserID .. " " .. players[prisonerSteam].prisonxPosOld .. " " .. players[prisonerSteam].prisonyPosOld .. " " .. players[prisonerSteam].prisonzPosOld
						igplayers[prisonerSteam].lastTP = cmd
						teleport(cmd, prisonerSteam, prisonerUserID)
					end
				else
					message("pm " .. prisonerUserID .. " [" .. server.chatColour .. "]You are a free citizen, but you must find your own way back.[-]")
				end

				if botman.dbConnected then
					conn:execute("UPDATE players SET bail = 0, prisoner = 0, silentBob = 0, xPosOld = " .. players[prisonerSteam].prisonxPosOld .. ", yPosOld = " .. players[prisonerSteam].prisonyPosOld .. ", zPosOld = " .. players[prisonerSteam].prisonzPosOld .. " WHERE steam = '" .. prisonerSteam .. "'")
					connSQL:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0, bail = 0 WHERE steam = '" .. prisonerSteam .. "'")
				end
			else
				if not isArchived then
					if (players[prisonerSteam]) then
						players[prisonerSteam].location = "return player"

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[prisonerSteam].name .. " will be released when they next join the server.[-]")
						else
							irc_chat(chatvars.ircAlias, players[prisonerSteam].name .. " will be released when they next join the server.")
						end

						players[prisonerSteam].xPosOld = players[prisonerSteam].prisonxPosOld
						players[prisonerSteam].yPosOld = players[prisonerSteam].prisonyPosOld
						players[prisonerSteam].zPosOld = players[prisonerSteam].prisonzPosOld

						if botman.dbConnected then
							conn:execute("UPDATE players SET bail = 0, prisoner = 0, silentBob = 0, location = 'return player', xPosOld = " .. players[prisonerSteam].prisonxPosOld .. ", yPosOld = " .. players[prisonerSteam].prisonyPosOld .. ", zPosOld = " .. players[prisonerSteam].prisonzPosOld .. " WHERE steam = '" .. prisonerSteam .. "'")
							connSQL:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0, bail = 0 WHERE steam = '" .. prisonerSteam .. "'")
						end
					end
				else
					if (playersArchived[prisonerSteam]) then
						playersArchived[prisonerSteam].location = "return player"

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playersArchived[prisonerSteam].name .. " will be released when they next join the server.[-]")
						else
							irc_chat(chatvars.ircAlias, playersArchived[prisonerSteam].name .. " will be released when they next join the server.")
						end

						playersArchived[prisonerSteam].xPosOld = playersArchived[prisonerSteam].prisonxPosOld
						playersArchived[prisonerSteam].yPosOld = playersArchived[prisonerSteam].prisonyPosOld
						playersArchived[prisonerSteam].zPosOld = playersArchived[prisonerSteam].prisonzPosOld

						if botman.dbConnected then
							conn:execute("UPDATE playersArchived SET bail = 0, prisoner = 0, silentBob = 0, location = 'return player', xPosOld = " .. playersArchived[prisonerSteam].prisonxPosOld .. ", yPosOld = " .. playersArchived[prisonerSteam].prisonyPosOld .. ", zPosOld = " .. playersArchived[prisonerSteam].prisonzPosOld .. " WHERE steam = '" .. prisonerSteam .. "'")
							connSQL:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0, bail = 0 WHERE steam = '" .. prisonerSteam .. "'")
						end
					end
				end
			end

			if not isArchived then
				players[prisonerSteam].xPosOld = 0
				players[prisonerSteam].yPosOld = 0
				players[prisonerSteam].zPosOld = 0
				players[prisonerSteam].bail = 0
				players[prisonerSteam].prisoner = false
				players[prisonerSteam].prisonReason = ""
				players[prisonerSteam].silentBob = false
				players[prisonerSteam].prisonReleaseTime = os.time()
				setChatColour(prisonerSteam, players[prisonerSteam].accessLevel)
			else
				playersArchived[prisonerSteam].xPosOld = 0
				playersArchived[prisonerSteam].yPosOld = 0
				playersArchived[prisonerSteam].zPosOld = 0
				playersArchived[prisonerSteam].bail = 0
				playersArchived[prisonerSteam].prisoner = false
				playersArchived[prisonerSteam].prisonReason = ""
				playersArchived[prisonerSteam].silentBob = false
				playersArchived[prisonerSteam].prisonReleaseTime = os.time()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReleasePlayerHere()
		local prisonerSteam, prisonerSteamOwner, prisonerUserID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}release here {prisoner}"
			help[2] = "Release a player from prison and move them to your location."

			tmp.command = help[1]
			tmp.keywords = "release,free,prisoners,player,here,jail,gaol"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "rele") or string.find(chatvars.command, "free") or string.find(chatvars.command, "pris") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "release" and chatvars.words[2] == "here" and chatvars.words[3] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			prisoner = string.sub(chatvars.command, string.find(chatvars.command, ": " .. server.commandPrefix .. "release here ") + 16)
			prisoner = string.trim(prisoner)
			prisonerSteam, prisonerSteamOwner, prisonerUserID = LookupPlayer(prisoner)

			if prisonerSteam == "0" then
				prisonerSteam, prisonerSteamOwner, prisonerUserID = LookupArchivedPlayer(prisoner)

				if not (prisonerSteam == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[prisonerSteam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[prisonerSteam].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. prisoner)
					end

					botman.faultyChat = false
					return true
				end
			end

			if (players[prisonerSteam].prisoner == false) then
				message("say [" .. server.chatColour .. "]Citizen " .. players[prisonerSteam].name .. " is not a prisoner[-]")
				botman.faultyChat = false
				return true
			end

			if igplayers[prisonerSteam] then
				if players[prisonerSteam].chatColour ~= "" then
					setPlayerColour(prisonerSteam, players[prisonerSteam].chatColour)
				else
					setChatColour(prisonerSteam, players[prisonerSteam].accessLevel)
				end

				if botman.dbConnected then
					conn:execute("UPDATE players SET bail=0,prisoner=0,timeout=0,botTimeout=0,silentBob=0 WHERE steam = '" .. prisonerSteam .. "'")
					connSQL:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0, bail = 0 WHERE steam = '" .. prisonerSteam .. "'")
				end

				players[prisonerSteam].prisoner = false
				players[prisonerSteam].timeout = false
				players[prisonerSteam].botTimeout = false
				players[prisonerSteam].freeze = false
				players[prisonerSteam].silentBob = false
				players[prisonerSteam].prisonReason = ""
				players[prisonerSteam].prisonReleaseTime = os.time()

				message("say [" .. server.chatColour .. "]Releasing prisoner " .. playerName .. "[-]")
				message("pm " .. prisonerUserID .. " [" .. server.chatColour .. "]You are released from prison.  Be a good citizen if you wish to remain free.[-]")

				cmd = "tele " .. prisonerUserID .. " " .. chatvars.userID
				teleport(cmd, prisonerSteam, prisonerUserID)
				players[prisonerSteam].xPosOld = 0
				players[prisonerSteam].yPosOld = 0
				players[prisonerSteam].zPosOld = 0
				players[prisonerSteam].bail = 0
				players[prisonerSteam].prisonxPosOld = 0
				players[prisonerSteam].prisonyPosOld = 0
				players[prisonerSteam].prisonzPosOld = 0
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. players[prisonerSteam].name .. " is not on the server right now. Get them to rejoin the server and repeat this command.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[prisonerSteam].name .. " is not on the server right now. Get them to rejoin the server and repeat this command.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReloadAdmins()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reload admins"
			help[2] = "Make the bot run admin list to reload the admins from the server's list."

			tmp.command = help[1]
			tmp.keywords = "reload,admins,refresh,read,list"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "reload admins")) and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "reload" or chatvars.words[1] == "refresh" or chatvars.words[1] == "update") and chatvars.words[2] == "admins" then
			-- run admin list
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Reading admin list[-]")
			sendCommand("admin list")
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RemoveEntity()
		local cursor, errorString, row, dist, sql, entityRemoved

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}remove entity/trader/npc {optional id}"
			help[2] = "The bot will despawn any trader within 2 blocks of you in-game or by entity id if given."

			tmp.command = help[1]
			tmp.keywords = "remove,entity,trader,despawn,npc"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "remov") or string.find(chatvars.command, "trader") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "remove" and (chatvars.words[2] == "trader" or chatvars.words[2] == "entity" or chatvars.words[2] == "npc") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				if not server.botman then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This command requires that the Botman mod is installed on the server.[-]")
					botman.faultyChat = false
					return true
				end
			else
				if not server.botman then
					irc_chat(chatvars.ircAlias, "This command requires that the Botman mod is installed on the server.")
					botman.faultyChat = false
					return true
				end

				if not chatvars.number and (chatvars.playername ~= "Server") then
					irc_chat(chatvars.ircAlias, "An entity ID is required because you didn't issue this command in-game.")
					botman.faultyChat = false
					return true
				end
			end

			entityRemoved = false

			if chatvars.number ~= nil then
				sql = "SELECT * FROM entities WHERE type <> 'EntityPlayer' and entityID = " .. chatvars.number
				cursor,errorString = connMEM:execute(sql)
			else
				sql = "SELECT * FROM entities WHERE type <> 'EntityPlayer'"
				cursor,errorString = connMEM:execute(sql)
			end

			row = cursor:fetch({}, "a")
			while row do
				if chatvars.number ~= nil then
					dist = 0
				else
					dist = distancexz(chatvars.intX, chatvars.intZ, row.x, row.z)
				end

				if dist <= 2 then
					if server.botman then
						sendCommand("bm-remove " .. row.entityID)
					end

					entityRemoved = true

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. row.name .. " type: " .. row.type .. " removed.[-]")
					else
						irc_chat(chatvars.ircAlias, row.name .. " type: " .. row.type .. " removed.")
					end
				end

				row = cursor:fetch(row, "a")
			end

			sendCommand("le")

			if not entityRemoved then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Nothing was removed but entities have been re-scanned. Try again now.[-]")
				else
					irc_chat(chatvars.ircAlias, "Nothing was removed but entities have been re-scanned. Try again now.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RemovePlayerClaims()
		local playerName, isArchived
		local steam, steamOwner, userID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}remove claims {player name}"
			help[2] = "The bot will automatically remove the player's claims whenever possible. The chunk has to be loaded and the bot takes several minutes to remove them but it will remove them."

			tmp.command = help[1]
			tmp.keywords = "remove,claimblocks,keystones,lcb"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "claim") or string.find(chatvars.command, "keys") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "remove" and chatvars.words[2] == "claims" and chatvars.words[3] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = chatvars.words[3]
			pname = string.trim(pname)
			steam, steamOwner, userID = LookupPlayer(pname)

			if steam == "0" then
				steam, steamOwner, userID = LookupArchivedPlayer(pname)

				if not (steam == "0") then
					playerName = playersArchived[steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[steam].name
				isArchived = false
			end

			if steam ~= "0" then
				-- flag the player's claims for removal
				if not isArchived then
					players[steam].removeClaims = true
					if botman.dbConnected then conn:execute("UPDATE players SET removeClaims = 1 WHERE steam = '" .. steam .. "'") end
				else
					playersArchived[steam].removeClaims = true
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET removeClaims = 1 WHERE steam = '" .. steam .. "'") end
				end

				if botman.dbConnected then connSQL:execute("UPDATE keystones SET remove = 1 WHERE steam = '" .. steam .. "'") end

				if not isAdminHidden(steam, userID) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playerName .. "'s claims will be removed when players are nearby.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playerName .. "'s claims will be removed when players are nearby.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Admin " .. playerName .. "'s claims will be marked for removal but will only be removed when they are no longer an admin (and not using {#}test as player).[-]")
					else
						irc_chat(chatvars.ircAlias, "Admin " .. playerName .. "'s claims will be marked for removal but will only be removed when they are no longer an admin (and not using {#}test as player).")
					end
				end

				-- do a scan now so all of their claims are recorded
				sendCommand("llp " .. userID .. " parseable")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetHelp()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reset help"
			help[2] = "This command makes the bot delete and rebuild the command help from the bot's code so you can restore command permissions back to defaults should you need to."

			tmp.command = help[1]
			tmp.keywords = "commands,help,reset,refresh,replace"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "reset")) and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "reset" and chatvars.words[2] == "help" then
			if not chatvars.isAdminHidden then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Command denied.[-]")
				else
					irc_chat(chatvars.ircAlias, "Command denied.")
				end

				botman.faultyChat = false
				return true
			end

			resetHelp()

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The command help and permissions have been reset to defaults.[-]")
			else
				irc_chat(chatvars.ircAlias, "The command help and permissions have been reset to defaults.")
			end

			botman.registerHelp	= true
			gmsg(server.commandPrefix)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetPlayer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reset player record {player name}"
			help[2] = "Make the bot forget a player's cash, waypoints, bases etc but leave their donor status alone."

			tmp.command = help[1]
			tmp.keywords = "reset,player,record,wipe"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reset") or string.find(chatvars.command, "play") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "reset" and chatvars.words[2] == "player" and chatvars.words[3] == "record" and chatvars.words[4] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = nil
			pname = string.sub(chatvars.command, string.find(chatvars.command, " record ") + 9)

			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			resetPlayer(tmp.steam)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. players[tmp.steam].name .. " has been reset (in the bot's records).[-]")
			else
				irc_chat(chatvars.ircAlias, "Player " .. players[tmp.steam].name .. " has been reset (in the bot's records)")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetPlayerTimers()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}resettimers {player name}"
			help[2] = "Normally a player needs to wait a set time after {#}base before they can use it again. This zeroes that timer and also resets their gimmies."

			tmp.command = help[1]
			tmp.keywords = "reset,timers,cooldowns,player"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reset") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "timer") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "resettimers") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = nil
			pname = string.sub(chatvars.command, string.find(chatvars.command, "resettimers ") + 12)

			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if (players[tmp.steam]) then
				players[tmp.steam].baseCooldown = 0
				players[tmp.steam].gimmeCount = 0
				players[tmp.steam].waypointCooldown = 0
				players[tmp.steam].teleCooldown = 0
				players[tmp.steam].pvpTeleportCooldown = 0
				players[tmp.steam].returnCooldown = 0
				players[tmp.steam].commandCooldown = 0
				players[tmp.steam].p2pCooldown = 0
				players[tmp.steam].packCooldown = 0

				if botman.dbConnected then conn:execute("UPDATE players SET baseCooldown = 0, gimmeCount = 0, waypointCooldown = 0, teleCooldown = 0, pvpTeleportCooldown = 0, returnCooldown = 0, commandCooldown = 0, p2pCooldown = 0 WHERE steam = '" .. tmp.steam .. "'") end
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Cooldown timers have been reset for " .. players[tmp.steam].name .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "Cooldown timers have been reset for " .. players[tmp.steam].name)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetStackSizes()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reset stack"
			help[2] = "If you have changed stack sizes and the bot is mistakenly abusing players for overstacking, you can make the bot forget the stack sizes.\n"
			help[2] = help[2] .. "It will re-learn them from the server as players overstack beyond the new stack limits."

			tmp.command = help[1]
			tmp.keywords = "reset,clear,stacksize"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "reset") or string.find(chatvars.command, "clear") or string.find(chatvars.command, "stack") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "clear" or chatvars.words[1] == "reset") and chatvars.words[2] == "stack" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			stackLimits = {}

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot's record of stack limits has been wiped.  It will re-learn them from the server as players overstack items.[-]")
			else
				irc_chat(chatvars.ircAlias, "The bot's record of stack limits has been wiped.  It will re-learn them from the server as players overstack items.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RestoreAdmin()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}restore admin"
			help[2] = "Use this command if you have used {#}test as player, and you want to get your admin status back now."

			tmp.command = help[1]
			tmp.keywords = "admin,restore"
			tmp.accessLevel = 99
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "rest") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "remo") and chatvars.showHelp or botman.registerHelp then
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

		-- this is a dummy command.  The real command lives in gmsg_functions.lua you dummy :P
	end


	local function cmd_ReturnPlayer()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}return {player name}\n"
			help[1] = help[1] .. "Or {#}return {player name} to {location or other player}"
			help[2] = "Return a player from timeout.  You can use their steam or game id and part or all of their name.\n"
			help[2] = help[2] .. "You can return them to any player even offline ones or to any location. If you just return them, they will return to wherever they were when they were sent to timeout.\n"
			help[2] = help[2] .. "Your regular players can also return new players from timeout but only if a player sent them there."

			tmp.command = help[1]
			tmp.keywords = "return,player,timeout,offline,prison"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "return")) and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "return" and chatvars.words[2] ~= nil) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp = {}

			if string.find(chatvars.command, " to ") then
				tmp.loc = string.sub(chatvars.command, string.find(chatvars.command, " to ") + 4)
				tmp.loc = string.trim(tmp.loc)
				tmp.loc = LookupLocation(tmp.loc)

				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "return ") + 7, string.find(chatvars.command, " to ") - 1)
				tmp.pname = string.trim(tmp.pname)
				tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.pname)
			else
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "return ") + 7)
				tmp.pname = string.trim(tmp.pname)
				tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.pname)
			end

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(tmp.pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.pname .. " did not match any players.[-]")
					else
						irc_chat(chatvars.ircAlias, tmp.pname .. " did not match any players.")
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if (chatvars.playername ~= "Server") then
				-- don't allow players to return anyone to a different location.
				if not chatvars.isAdminHidden then
					tmp.loc = nil
				end
			end

			if tmp.steam == chatvars.playerid then
				if (players[tmp.steam].timeout or players[tmp.steam].botTimeout) and not chatvars.isAdminHidden then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are in timeout. You cannot release yourself.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if not isArchived then
				if (not players[tmp.steam].timeout and not players[tmp.steam].botTimeout) and players[tmp.steam].prisoner and ((tmp.steam ~= chatvars.playerid and not chatvars.isAdminHidden) or chatvars.playerid == players[tmp.steam].pvpVictim) then
					gmsg(server.commandPrefix .. "release " .. tmp.steam)
					botman.faultyChat = false
					return true
				end
			else
				if (not players[tmp.steam].timeout and not players[tmp.steam].botTimeout) and playersArchived[tmp.steam].prisoner and ((tmp.steam ~= chatvars.playerid and not chatvars.isAdminHidden) or chatvars.playerid == playersArchived[tmp.steam].pvpVictim) then
					gmsg(server.commandPrefix .. "release " .. tmp.steam)
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.playername ~= "Server") then
				if not chatvars.isAdminHidden then
					if players[tmp.steam] then
						if players[tmp.steam].newPlayer == false or players[tmp.steam].botTimeout == true then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You can only use this command on new players and only when the bot didn't put them there.[-]")
							botman.faultyChat = false
							return true
						end
					else
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]That player has been archived. Ask them to join then repeat this command.[-]")
						botman.faultyChat = false
						return true
					end
				end
			end

			-- return player to previously recorded x y z
			if (igplayers[tmp.steam]) then
				if players[tmp.steam].timeout or players[tmp.steam].botTimeout then
					players[tmp.steam].timeout = false
					players[tmp.steam].botTimeout = false
					players[tmp.steam].freeze = false
					players[tmp.steam].silentBob = false
					igplayers[tmp.steam].skipExcessInventory = true

					if tmp.loc ~= nil then
						tmp.cmd = "tele " .. tmp.userID .. " " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Returning " .. players[tmp.steam].name .. " to " .. tmp.loc .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "Returning " .. players[tmp.steam].name .. " to " .. tmp.loc)
						end
					else
						tmp.cmd = "tele " .. tmp.userID .. " " .. players[tmp.steam].xPosTimeout .. " " .. players[tmp.steam].yPosTimeout .. " " .. players[tmp.steam].zPosTimeout

						if botman.dbConnected then conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, xPosTimeout = 0, yPosTimeout = 0, zPosTimeout = 0 WHERE steam = '" .. tmp.steam .. "'") end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Returning " .. players[tmp.steam].name .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "Returning " .. players[tmp.steam].name)
						end
					end

					players[tmp.steam].xPosTimeout = 0
					players[tmp.steam].yPosTimeout = 0
					players[tmp.steam].zPosTimeout = 0
					teleport(tmp.cmd, tmp.steam, tmp.userID)
				else
					if tmp.loc ~= nil then
						tmp.cmd = "tele " .. tmp.userID .. " " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z
						players[tmp.steam].xPosOld = 0
						players[tmp.steam].yPosOld = 0
						players[tmp.steam].zPosOld = 0
						players[tmp.steam].xPosOld2 = 0
						players[tmp.steam].yPosOld2 = 0
						players[tmp.steam].zPosOld2 = 0

						teleport(tmp.cmd, tmp.steam, tmp.userID)

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Returning " .. players[tmp.steam].name .. " to " .. tmp.loc .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "Returning " .. players[tmp.steam].name .. " to " .. tmp.loc)
						end
					else
						if tonumber(players[tmp.steam].yPosOld) == 0 and tonumber(players[tmp.steam].yPosOld2) == 0 then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. " has no returns.[-]")
							else
								irc_chat(chatvars.ircAlias, players[tmp.steam].name .. " has no returns.")
							end

							botman.faultyChat = false
							return true
						end

						if tonumber(players[tmp.steam].yPosOld2) ~= 0 then
							-- the player has teleported within the same location so they are returning to somewhere in that location
							cmd = "tele " .. tmp.userID .. " " .. players[tmp.steam].xPosOld2 .. " " .. players[tmp.steam].yPosOld2 .. " " .. players[tmp.steam].zPosOld2
							teleport(cmd, tmp.steam, tmp.userID)

							players[tmp.steam].xPosOld2 = 0
							players[tmp.steam].yPosOld2 = 0
							players[tmp.steam].zPosOld2 = 0

							conn:execute("UPDATE players SET xPosOld2 = 0, yPosOld2 = 0, zPosOld2 = 0 WHERE steam = '" .. tmp.steam .. "'")
						else
							-- the player has teleported from outside their current location so they are returning to there.
							cmd = "tele " .. tmp.userID .. " " .. players[tmp.steam].xPosOld .. " " .. players[tmp.steam].yPosOld .. " " .. players[tmp.steam].zPosOld
							teleport(cmd, tmp.steam, tmp.userID)

							players[tmp.steam].xPosOld = 0
							players[tmp.steam].yPosOld = 0
							players[tmp.steam].zPosOld = 0
							igplayers[tmp.steam].lastLocation = ""

							conn:execute("UPDATE players SET xPosOld = 0, yPosOld = 0, zPosOld = 0 WHERE steam = '" .. tmp.steam .. "'")
						end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Returning " .. players[tmp.steam].name .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "Returning " .. players[tmp.steam].name)
						end
					end
				end

				botman.faultyChat = false
				return true
			else
				if not isArchived then
					if (players[tmp.steam].yPosTimeout) then
						players[tmp.steam].timeout = false
						players[tmp.steam].botTimeout = false
						players[tmp.steam].silentBob = false

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. " will be returned when they next join the server.[-]")
						else
							irc_chat(chatvars.ircAlias, playerName .. " will be returned when they next join the server.")
						end

						if botman.dbConnected then conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0 WHERE steam = '" .. tmp.steam .. "'") end
					end
				else
					if (playersArchived[tmp.steam].yPosTimeout) then
						playersArchived[tmp.steam].timeout = false
						playersArchived[tmp.steam].botTimeout = false
						playersArchived[tmp.steam].silentBob = false

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. " will be returned when they next join the server.[-]")
						else
							irc_chat(chatvars.ircAlias, playerName .. " will be returned when they next join the server.")
						end

						if botman.dbConnected then conn:execute("UPDATE playersArchived SET timeout = 0, silentBob = 0, botTimeout = 0 WHERE steam = '" .. tmp.steam .. "'") end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SendPlayerHome()
		local baseFound, base
		local steam, steamOwner, userID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}sendhome {player name}"
			help[2] = "Teleport a player to their first base or their bedroll if they have no base set."

			tmp.command = help[1]
			tmp.keywords = "send,move,player,home,base,teleport,bedroll"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "home") or string.find(chatvars.command, "player") or string.find(chatvars.command, "send") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "sendhome") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "sendhome") + 9)
			pname = string.trim(pname)

			if (pname == "") then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A player name is required or could not be found for this command[-]")
				else
					irc_chat(chatvars.ircAlias, "A player name is required or could not be found for this command")
				end

				botman.faultyChat = false
				return true
			else
				steam = "0"
				steam, steamOwner, userID = LookupPlayer(pname)

				if steam == "0" then
					steam, steamOwner, userID = LookupArchivedPlayer(pname)

					if not (steam == "0") then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No players found with that name.[-]")
						else
							irc_chat(chatvars.ircAlias, "No players found called " .. pname)
						end
					end

					botman.faultyChat = false
					return true
				end

				if (isAdmin(steam, userID) or isAdminHidden(steam, userID)) and steam ~= chatvars.playerid then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Staff cannot be teleported by other staff.[-]")
					else
						irc_chat(chatvars.ircAlias, "Staff cannot be teleported by other staff.")
					end

					botman.faultyChat = false
					return true
				end

				if (players[steam].timeout == true) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[steam].name .. " is in timeout. " .. server.commandPrefix .. "return them first[-]")
					else
						irc_chat(chatvars.ircAlias, players[steam].name .. " is in timeout. Return them first.")
					end

					botman.faultyChat = false
					return true
				end

				-- first record the current x y z
				if (igplayers[steam]) then
					players[steam].xPosOld = igplayers[steam].xPos
					players[steam].yPosOld = igplayers[steam].yPos
					players[steam].zPosOld = igplayers[steam].zPos
				end

				if (chatvars.words[1] == "sendhome") then
					baseFound, base = LookupBase(steam)

					if not baseFound then
						if server.botman then
							prepareTeleport(steam, userID, "")

							if server.botman then
								sendCommand("bm-teleportplayerhome " .. userID)
							else
								if players[steam].bedX ~= 0 or players[steam].bedY ~= 0 or players[steam].bedZ ~= 0 then
									cmd = "tele " .. userID .. " " .. players[steam].bedX .. " " .. players[steam].bedY + 1 .. " " .. players[steam].bedZ
									teleport(cmd, steam, userID)
								end
							end

							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. players[steam].name .. " has been sent to their bed if they placed it.[-]")
							else
								irc_chat(chatvars.ircAlias, players[steam].name .. " has been sent to their bed if they placed it.")
							end
						end

						botman.faultyChat = false
						return true
					else
						if (igplayers[steam]) then
							cmd = "tele " .. userID .. " " .. base.x .. " " .. base.y + 1 .. " " .. base.z
							teleport(cmd, steam, userID)
						end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. players[steam].name .. " has been sent home")
						else
							irc_chat(chatvars.ircAlias, players[steam].name .. " has been sent home.")
						end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SendPlayerToPlayer()
		local steam1, steamOwner1, userID1
		local steam2, steamOwner2, userID2

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}send {player} to {other player}"
			help[2] = "Teleport a player to another player even if the other player is offline."

			tmp.command = help[1]
			tmp.keywords = "send,move,player,teleport,visit"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "send") or string.find(chatvars.command, "player") or string.find(chatvars.command, "tele") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "send") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname1 = string.sub(chatvars.command, 7, string.find(chatvars.command, " to ") - 1)
			pname2 = string.sub(chatvars.command, string.find(chatvars.command, " to ") + 4)

			steam1, steamOwner1, userID1 = LookupPlayer(pname1)
			steam2, steamOwner2, userID2 = LookupPlayer(pname2)

			if steam1 == "0" then
				steam1, steamOwner1, userID1 = LookupArchivedPlayer(pname1)

				if not (steam1 == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[steam1].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[steam1].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. pname1 .. " did not match any players.[-]")
					else
						irc_chat(chatvars.ircAlias, pname1 .. " did not match any players.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if steam2 == "0" then
				steam2, steamOwner2, userID2 = LookupArchivedPlayer(pname2)

				if not (steam2 == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[steam2].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[steam2].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. pname2 .. " did not match any players.[-]")
					else
						irc_chat(chatvars.ircAlias, pname2 .. " did not match any players.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if isAdmin(steam1, userID1) or isAdminHidden(steam1, userID1) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Staff cannot be teleported by other staff.[-]")
				else
					irc_chat(chatvars.ircAlias, "Staff cannot be teleported by other staff.")
				end

				botman.faultyChat = false
				return true
			end

			if not igplayers[steam1] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[steam1].name .. " is not on the server right now.[-]")
				else
					irc_chat(chatvars.ircAlias, players[steam1].name .. " is not on the server right now.")
				end

				botman.faultyChat = false
				return true
			end

			if (steam1 ~= "0" and steam2 ~= "0") then
				if (players[steam1].timeout == true) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[steam1].name .. " is in timeout. Return them first[-]")
					else
						irc_chat(chatvars.ircAlias, players[steam1].name .. " is in timeout. Return them first.")
					end

					botman.faultyChat = false
					return true
				end

				-- first record the current x y z
				players[steam1].xPosOld = players[steam1].xPos
				players[steam1].yPosOld = players[steam1].yPos
				players[steam1].zPosOld = players[steam1].zPos

				if (igplayers[steam2]) then
					cmd = "tele " .. userID1 .. " " .. userID2
					teleport(cmd, steam1, userID1)
				else
					cmd = "tele " .. userID1 .. " " .. players[steam2].xPos .. " " .. players[steam2].yPos .. " " .. players[steam2].zPos
					teleport(cmd, steam1, userID1)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetDeathCost()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set death cost {cash} (default is 0)"
			help[2] = "Set a cost penalty for dying.  The player's cash balance won't drop below zero."

			tmp.command = help[1]
			tmp.keywords = "set,death,cost"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "death") or string.find(chatvars.command, "cost") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "set death cost") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			server.deathCost = math.abs(math.floor(chatvars.number))
			if botman.dbConnected then conn:execute("UPDATE server SET deathCost = " .. server.deathCost) end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Dying will cost a player " .. server.deathCost .. " " .. server.moneyPlural .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, "Dying will cost a player " .. server.deathCost .. " " .. server.moneyPlural)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetSuicideCost()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set suicide cost {cash} (default is 0)"
			help[2] = "Set a cost to use the {#}suicide command."

			tmp.command = help[1]
			tmp.keywords = "set,suicide,cost"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "suicide") or string.find(chatvars.command, "cost") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "set suicide cost") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			server.suicideCost = math.abs(math.floor(chatvars.number))
			if botman.dbConnected then conn:execute("UPDATE server SET suicideCost = " .. server.suicideCost) end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Committing suicide will cost a player " .. server.suicideCost .. " " .. server.moneyPlural .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, "Committing suicide will cost a player " .. server.suicideCost .. " " .. server.moneyPlural)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleAllowSuicide()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}allow (or {#}disallow) suicide"
			help[2] = "Let players {#}suicide or don't let them commit the unthinkable :O"

			tmp.command = help[1]
			tmp.keywords = "allow,suicide"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "suicide") or string.find(chatvars.command, "allow") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow") and chatvars.words[2] == "suicide" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "allow" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can commit {#}suicide.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can commit {#}suicide.")
				end

				server.allowSuicide = true
				conn:execute("UPDATE server SET allowSuicide = 1")
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players cannot use the {#}suicide command.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players cannot use the {#}suicide command.")
				end

				server.allowSuicide = false
				conn:execute("UPDATE server SET allowSuicide = 0")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetDropMiningWarningThreshold()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set drop mining warning {number of blocks} (default is 99)"
			help[2] = "Set how many blocks can fall off the world every minute before the bot alerts admins to it.\n"
			help[2] = help[2] .. "Disable by setting it to 0"

			tmp.command = help[1]
			tmp.keywords = "set,dropmining,alert,warning,blocks,level"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "drop") or string.find(chatvars.command, "mining") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "set drop mining warning") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			server.dropMiningWarningThreshold = math.abs(math.floor(chatvars.number))
			if botman.dbConnected then conn:execute("UPDATE server SET dropMiningWarningThreshold = " .. server.dropMiningWarningThreshold) end

			if server.dropMiningWarningThreshold > 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will alert admins to drop mining over " .. server.dropMiningWarningThreshold .. " blocks dropped per minute.[-]")
				else
					message("say [" .. server.chatColour .. "]The bot will alert admins to drop mining over " .. server.dropMiningWarningThreshold .. " blocks dropped per minute.[-]")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will not alert on drop mining.[-]")
				else
					message("say [" .. server.chatColour .. "]The bot will not alert on drop mining.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetCommandCooldown()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set command cooldown {seconds} (default 0)"
			help[2] = "You can add a delay between player commands to the bot.  Does not apply to staff.  This helps to slow down command abuse."

			tmp.command = help[1]
			tmp.keywords = "set,commands,cooldown,delay,timer"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "command") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "delay") or string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "command" and (chatvars.words[3] == "cooldown" or chatvars.words[3] == "delay" or chatvars.words[3] == "timer") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Number required eg. " .. server.commandPrefix .. "set return cooldown 10[-]")
				else
					irc_chat(chatvars.ircAlias, "Number required  eg. " .. server.commandPrefix .. "set return cooldown 10")
				end
			else
				chatvars.number = math.abs(chatvars.number)

				server.commandCooldown = chatvars.number
				if botman.dbConnected then conn:execute("UPDATE server SET commandCooldown = " .. server.commandCooldown) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players must wait " .. server.commandCooldown .. " seconds between commands to the bot.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players must wait " .. server.commandCooldown .. " seconds between commands to the bot.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetFeralHordeNight()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set feral horde night {day number} (default is 7)"
			help[2] = "Set which day is horde night.  This is needed if your horde nights are not every 7 days."

			tmp.command = help[1]
			tmp.keywords = "set,feral,horde,night"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "feral") or string.find(chatvars.command, "horde") or string.find(chatvars.command, "night") or string.find(chatvars.command, "day") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.command == "feral horde night") then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Horde nights happen every " .. server.hordeNight .. " days.[-]")
			else
				message("say [" .. server.chatColour .. "]Horde nights happen every " .. server.hordeNight .. " days.[-]")
			end

			botman.faultyChat = false
			return true
		end

		if string.find(chatvars.command, "set feral horde night") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			server.hordeNight = math.abs(math.floor(chatvars.number))
			if botman.dbConnected then conn:execute("UPDATE server SET hordeNight = " .. server.hordeNight) end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot now calculates horde nights as happening every " .. server.hordeNight .. " days.[-]")
			else
				message("say [" .. server.chatColour .. "]The bot now calculates horde nights as happening every " .. server.hordeNight .. " days.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetFeralRebootDelay()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}feral reboot delay {minutes}"
			help[2] = "Set how many minutes after day 7 that the bot will wait before rebooting if a reboot is scheduled for day 7.\n"
			help[2] = help[2] .. "To disable this feature, set it to 0.  The bot will wait a full game day instead."

			tmp.command = help[1]
			tmp.keywords = "set,feral,reboot,timer,delay"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "feral") or string.find(chatvars.command, "rebo") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "feral" and chatvars.words[2] == "reboot" and chatvars.words[3] == "delay") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			server.feralRebootDelay = math.abs(math.floor(chatvars.number))
			if botman.dbConnected then conn:execute("UPDATE server SET feralRebootDelay = " .. server.feralRebootDelay) end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Reboots that fall on a feral day will happen " .. server.feralRebootDelay .. " minutes into the next day.[-]")
			else
				message("say [" .. server.chatColour .. "]Reboots that fall on a feral day will happen " .. server.feralRebootDelay .. " minutes into the next day.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxAdminLevel()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set max admin level {number from 2 to 89}"
			help[2] = "Set the max access level for admins.  The default is 2.\n"
			help[2] = help[2] .. "Note that levels 0, 1 and 2 are reserved and what you can is a number greater or equal to 2 but less than 90 eg. 10.\n"
			help[2] = help[2] .. "To avoid potential issues, do not allow max admin level to be a higher number than your lowest donor level."

			tmp.command = help[1]
			tmp.keywords = "set,max,admin,level,access"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "admin") or string.find(chatvars.command, "level") or string.find(chatvars.command, "access") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "max admin level") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number then
				chatvars.number = math.abs(chatvars.number)

				if chatvars.number > 1 and chatvars.number < 90 then
					server.maxAdminLevel = math.floor(chatvars.number)
					conn:execute("UPDATE server SET maxAdminLevel = ".. server.maxAdminLevel)

					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]Admin access levels now range from 0 to " .. server.maxAdminLevel, chatvars.userID, server.chatColour))
					else
						irc_chat(chatvars.ircAlias, "Admin access levels now range from 0 to " .. server.maxAdminLevel)
					end

					-- also remove players from the staff list with an admin level above maxAdminLevel
					conn:execute("DELETE FROM staff WHERE adminLevel > ".. server.maxAdminLevel)
					tempTimer( 5, [[loadStaff()]] )

				else
					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]Max admin level must be a number in the range 2 to 89.", chatvars.userID, server.chatColour))
					else
						irc_chat(chatvars.ircAlias, "Max admin level must be a number in the range 2 to 89.")
					end
				end
			else
				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]A number is required. Valid values are 2 to 89.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "A number is required. Valid values are 2 to 89.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxTrackingDays()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}max tracking days {days}"
			help[2] = "Set how many days to keep tracking data before deleting it.  The default it 28."

			tmp.command = help[1]
			tmp.keywords = "set,max,day,tracking,log"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "log") or string.find(chatvars.command, "track") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "max tracking days") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number then
				if chatvars.number == 0 then
					server.trackingKeepDays = 0
					conn:execute("UPDATE server SET trackingKeepDays = 0")

					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]Automatic database maintenance is disabled.  Good luck.", chatvars.userID, server.chatColour))
					else
						irc_chat(chatvars.ircAlias, "Automatic database maintenance is disabled.  Good luck.")
					end
				else
					chatvars.number = math.abs(chatvars.number)
					server.trackingKeepDays = chatvars.number
					conn:execute("UPDATE server SET trackingKeepDays = " .. chatvars.number)

					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]Tracking data older than " .. chatvars.number .. " days will be deleted daily at midnight server time.", chatvars.userID, server.chatColour))
					else
						irc_chat(chatvars.ircAlias, "Tracking data older than " .. chatvars.number .. " days will be deleted daily at midnight server time.")
					end
				end
			else
				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]A number is required. Setting it beyond 28 days is not recommended.", chatvars.userID, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "A number is required. Setting it beyond 28 days is not recommended.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetReservedSlotTimelimit()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set reserved slot timelimit {minutes} (default 0)"
			help[2] = "If this is 0, reserved slots are released when the player leaves the server.\n"
			help[2] = help[2] .. "Otherwise minutes after the player reserves a slot, they will become eligible to be kicked to make room for another reserved slotter."

			tmp.command = help[1]
			tmp.keywords = "set,reserved,slots,timelimit"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, " set") or string.find(chatvars.command, "slot") or string.find(chatvars.command, "reser") or string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
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

		if string.find(chatvars.command, "set reserved slot time") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Number required eg. " .. server.commandPrefix .. "set reserved slot time 10[-]")
				else
					irc_chat(chatvars.ircAlias, "Number required  eg. " .. server.commandPrefix .. "set reserved slot time 10")
				end
			else
				chatvars.number = math.abs(chatvars.number)

				server.reservedSlotTimelimit = chatvars.number
				if botman.dbConnected then conn:execute("UPDATE server SET reservedSlotTimelimit = " .. server.reservedSlotTimelimit) end

				if reservedSlotTimelimit == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players who are authorised to reserve slots will hold them until they leave the server.[-]")
					else
						irc_chat(chatvars.ircAlias, "Players who are authorised to reserve slots will hold them until they leave the server.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.reservedSlotTimelimit .. " minutes after an authorised player starts using a reserved slot, they can be kicked if another authorised player joins and the server is full.[-]")
					else
						irc_chat(chatvars.ircAlias, server.reservedSlotTimelimit .. " minutes after an authorised player starts using a reserved slot, they can be kicked if another authorised player joins and the server is full.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetReturnCooldown()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set return cooldown {seconds} (default 0)"
			help[2] = "You can add a delay to the return command.  Does not affect staff."

			tmp.command = help[1]
			tmp.keywords = "set,return,timer,cooldown,delay"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "return") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "delay") or string.find(chatvars.command, "time") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "return" and (chatvars.words[3] == "cooldown" or chatvars.words[3] == "delay" or chatvars.words[3] == "timer") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Number required eg. " .. server.commandPrefix .. "set return cooldown 10[-]")
				else
					irc_chat(chatvars.ircAlias, "Number required  eg. " .. server.commandPrefix .. "set return cooldown 10")
				end
			else
				chatvars.number = math.abs(chatvars.number)

				server.returnCooldown = chatvars.number
				if botman.dbConnected then conn:execute("UPDATE server SET returnCooldown = " .. server.returnCooldown) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players must wait " .. server.returnCooldown .. " seconds after teleporting before they can use the " .. server.commandPrefix .. "return command.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players must wait " .. server.returnCooldown .. " seconds after teleporting before they can use the " .. server.commandPrefix .. "return command.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetViewArrestReason() -- tested
		local reason, prisoner, prisonerSteam, prisonerSteamOwner, prisonerUserID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}prisoner {player name} arrested {reason for arrest}\n"
			help[1] = help[1] .. "Or {#}prisoner {player name} (read the reason if one is recorded)"
			help[2] = "You can record or view the reason for a player being arrested.  If they are released, this record is destroyed."

			tmp.command = help[1]
			tmp.keywords = "view,arrest,prisoner,jail,gaol"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "prisoner") or string.find(chatvars.command, "arrest") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "prisoner") then
			reason = ""

			if string.find(chatvars.command, "arrested") then
				prisoner = string.sub(chatvars.command, string.find(chatvars.command, "prisoner ") + 9, string.find(chatvars.command, "arrested") -1)

				if chatvars.isAdminHidden then
					reason = string.sub(chatvars.commandOld, string.find(chatvars.command, "arrested ") + 9)
				end
			else
				prisoner = string.sub(chatvars.command, string.find(chatvars.command, "prisoner ") + 9)
			end

			prisoner = stripQuotes(string.trim(prisoner))
			prisonerSteam, prisonerSteamOwner, prisonerUserID = LookupPlayer(prisoner)

			if prisonerSteam == "0" then
				prisonerSteam, prisonerSteamOwner, prisonerUserID = LookupArchivedPlayer(prisoner)

				if not (prisonerSteam == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Command not available.  Player " .. playersArchived[prisonerSteam].name .. " is archived.[-]")
					else
						irc_chat(chatvars.ircAlias, "Command not available.  Player " .. playersArchived[prisonerSteam].name .. " is archived.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. prisoner)
					end
				end

				botman.faultyChat = false
				return true
			end

			prisoner = players[prisonerSteam].name

			if (prisonerSteam == "0" or not players[prisonerSteam].prisoner) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. prisoner .. " is not a prisoner[-]")
				else
					irc_chat(chatvars.ircAlias, prisoner .. " is not a prisoner.")
				end

				botman.faultyChat = false
				return true
			end

			if players[prisonerSteam].prisoner then
				if reason ~= "" and chatvars.isAdminHidden then
					players[prisonerSteam].prisonReason = reason
					if botman.dbConnected then conn:execute("UPDATE players SET prisonReason = '" .. escape(reason) .. "' WHERE steam = '" .. prisonerSteam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You added a reason for prisoner " .. prisoner .. "'s arrest[-]")
					else
						irc_chat(chatvars.ircAlias, "Reason for prisoner " .. prisoner .. "'s arrest noted.")
					end
				else
					if players[prisonerSteam].prisonReason ~= nil then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. prisoner .. " was arrested for " .. players[prisonerSteam].prisonReason .. "[-]")

							if players[prisonerSteam].bail > 0 then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Bail is set at " .. players[prisonerSteam].bail .. " " .. server.moneyPlural .. "[-]")
							end
						else
							irc_chat(chatvars.ircAlias, prisoner .. " was arrested for " .. players[prisonerSteam].prisonReason)

							if players[prisonerSteam].bail > 0 then
								irc_chat(chatvars.ircAlias, "Bail is set at " .. players[prisonerSteam].bail .. " " .. server.moneyPlural)
							end
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] No reason is recorded for " .. prisoner .. "'s arrest.[-]")

							if players[prisonerSteam].bail > 0 then
								message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Bail is set at " .. players[prisonerSteam].bail .. " " .. server.moneyPlural .. "[-]")
							end
						else
							irc_chat(chatvars.ircAlias, "No reason is recorded for " .. prisoner .. "'s arrest.")

							if players[prisonerSteam].bail > 0 then
								irc_chat(chatvars.ircAlias, "Bail is set at " .. players[prisonerSteam].bail .. " " .. server.moneyPlural)
							end
						end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetWatchPlayerTimer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set watch timer {number in seconds}\n"
			help[1] = help[1] .. "Or {#}set watch player {name} timer {number in seconds}"
			help[2] = "When a new player joins, in-game admins will be messaged when the player adds or removes inventory.  They will automatically stop being watched after a delay.  The default is 3 days.\n"
			help[2] = help[2] .. "You can also set a different watch duration for an individual player.\n"
			help[2] = help[2] .. "1 hour = 3,600  1 day = 86,400  1 week = 604,800  4 weeks = 2,419,200\n"
			help[2] = help[2] .. "This timer is in real time not game time or time played."

			tmp.command = help[1]
			tmp.keywords = "set,watch,player,timer,inventory"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "set") or string.find(chatvars.command, "watch") or string.find(chatvars.command, "inven") and chatvars.showHelp or botman.registerHelp then
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

		-- Rest in peace KenJustKen.  Thanks for your input over the years, you will be missed buddy.

		if chatvars.words[1] == "set" and chatvars.words[2] == "watch" and (chatvars.words[3] == "player" or chatvars.words[3] == "timer") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(chatvars.number)
			else
				chatvars.number = 259200 -- 3 days in seconds.  Time flies!
			end

			if chatvars.words[3] == "player" then
				if not string.find(chatvars.command, " timer ") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Missing timer.  Please use {#}set watch player {name} timer {number in seconds}[-]")
					else
						irc_chat(chatvars.ircAlias, "Missing timer.  Please use {#}set watch player {name} timer {number in seconds}")
					end

					botman.faultyChat = false
					return true
				end

				pname = string.sub(chatvars.command, string.find(chatvars.command, " player ") + 8, string.find(chatvars.command, " timer ") - 1)
				tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)
				isArchived = false

				if tmp.steam == "0" then
					tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

					if not (tmp.steam == "0") then
						isArchived = true
						pname = playersArchived[tmp.steam].name
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				end

				if isArchived then
					playersArchived[tmp.steam].watchPlayerTimer = chatvars.number
					conn:execute("UPDATE playersArchived SET watchPlayerTimer = " .. chatvars.number .. " WHERE steam = '" .. tmp.steam .. "'")
				else
					pname = players[tmp.steam].name
					players[tmp.steam].watchPlayerTimer = chatvars.number
					conn:execute("UPDATE players SET watchPlayerTimer = " .. chatvars.number .. " WHERE steam = '" .. tmp.steam .. "'")
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. pname .. " will be watched for " .. (chatvars.number / 60) .. " minutes.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. pname .. " will be watched for " .. (chatvars.number / 60) .. " minutes.")
				end
			else
				server.defaultWatchTimer = chatvars.number
				conn:execute("UPDATE server SET defaultWatchTimer = " .. chatvars.number)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A player's inventory will be reported live for " .. chatvars.number .. " seconds from when inventory watching starts for them.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShitPlayer() --tested
		local steam, steamOwner, userID

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}shit {player name}"
			help[2] = "Give a player the shits for shits and giggles."

			tmp.command = help[1]
			tmp.keywords = "shits,player,debuff,fun,medical"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "shit") or string.find(chatvars.command, "player") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "shit") then
			if LookupLocation("shit") ~= nil then
				botman.faultyChat = false
				return false
			end

			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				steam, steamOwner, userID = LookupPlayer(pname)

				if steam == "0" then
					steam, steamOwner, userID = LookupArchivedPlayer(pname)

					if not (steam == "0") then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[steam] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. igplayers[steam].name .. " is not playing right now and can't catch shit.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[steam].name .. " is not playing right now and can't catch shit.")
				end

				botman.faultyChat = false
				return true
			end

			if isAdmin(steam, userID) or isAdminHidden(steam, userID) then
				message("pm " .. userID .. " [" .. server.alertColour .. "]" .. players[chatvars.playerid].name .. " cast shit on you.  It is super effective.[-]")
			end

			sendCommand("buffplayer " .. userID .. " buffIllDysentery1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You showed " .. players[steam].name .. " that you give a shit.[-]")
			else
				irc_chat(chatvars.ircAlias, "You showed " .. players[steam].name .. " that you give a shit.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TestAsPlayer()
		local cmd, restoreDelay

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}test as player {optional number in seconds}"
			help[2] = "Remove your admin status for 5 minutes.  After 5 minutes your admin status will be restored and any bans against you removed.\n"
			help[2] = help[2] .. "If you provide a number, your admin will instead be restored after that many seconds incase you need longer or shorter than the default 5 minutes.\n"
			help[2] = help[2] .. "You can get your admin status back with the command {#}restore admin"

			tmp.command = help[1]
			tmp.keywords = "test,player,admin"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "test") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "remo") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "test" and chatvars.words[2] == "as" and chatvars.words[3] == "player" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.ircid ~= "0" then
				tmp.steam = chatvars.ircid
			else
				tmp.steam = chatvars.playerid
			end

			tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(tmp.steam)

			restoreDelay = 300

			if chatvars.number ~= nil then
				restoreDelay = math.abs(chatvars.number)
			end

			if staffList[tmp.userID] then
				staffList[tmp.userID].hidden = true
			end

			cmd = string.format("ban remove %s", tmp.userID)
			if botman.dbConnected then connSQL:execute("INSERT INTO persistentQueue (steam, command, timerDelay) VALUES ('" .. tmp.steam .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + restoreDelay .. "')") end

			if staffList[tmp.steam] then
				staffList[tmp.steam].hidden = true
			end

			cmd = string.format("admin add %s %s", tmp.userID, chatvars.accessLevel)
			if botman.dbConnected then connSQL:execute("INSERT INTO persistentQueue (steam, command, timerDelay) VALUES ('" .. tmp.steam .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + restoreDelay .. "')") end

			cmd = string.format("admin add %s %s", tmp.platform .. "_" .. tmp.steam, chatvars.accessLevel)
			if botman.dbConnected then connSQL:execute("INSERT INTO persistentQueue (steam, command, timerDelay) VALUES ('" .. tmp.steam .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + restoreDelay .. "')") end

			cmd = string.format("pm %s [%s]Your admin status is restored.[-]", tmp.userID, server.chatColour)
			if botman.dbConnected then connSQL:execute("INSERT INTO persistentQueue (steam, command, timerDelay) VALUES ('" .. tmp.steam .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + restoreDelay .. "')") end

			botman.persistentQueueEmpty = false
			players[tmp.steam].testAsPlayer = true

			if botman.dbConnected then conn:execute("UPDATE staff SET hidden = 1 WHERE steam = '" .. tmp.steam .. "'") end
			if botman.dbConnected then conn:execute("UPDATE staff SET hidden = 1 WHERE steam = '" .. tmp.userID .. "'") end

			sendCommand("admin remove " .. tmp.userID)
			sendCommand("admin remove " .. tmp.platform .. "_" .. tmp.steam)

			if (chatvars.playername ~= "Server") then
				message(string.format("pm %s [%s]Your admin status has been temporarily removed.  You are now a player.  You will regain admin in " .. restoreDelay .. " seconds.  Good luck![-]", tmp.userID, server.chatColour))
			else
				irc_chat(chatvars.ircAlias, "Your admin status has been temporarily removed.  You are now a player.  You will regain admin in " .. restoreDelay .. " seconds.  Good luck!")

				if igplayers[tmp.steam] then
					message(string.format("pm %s [%s]Your admin status has been temporarily removed.  You are now a player.  You will regain admin in " .. restoreDelay .. " seconds.  Good luck![-]", tmp.userID, server.chatColour))
				end
			end

			-- force an early retirement
			players[tmp.steam].accessLevel = 90
			setChatColour(tmp.steam, 90)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PlayAsPlayer()
		local cmd, restoreDelay

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}play as player"
			help[2] = "Remove your admin status in game only until restored with {#}restore admin."

			tmp.command = help[1]
			tmp.keywords = "player,admin"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "play") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "remo") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "play" and chatvars.words[2] == "as" and chatvars.words[3] == "player" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.ircid ~= "0" then
				tmp.steam = chatvars.ircid
			else
				tmp.steam = chatvars.playerid
			end

			tmp.steam, tmp.steamOwner, tmp.userID, tmp.platform = LookupPlayer(tmp.steam)

			restoreDelay = 31536000 -- approximately 1 year later

			cmd = string.format("ban remove %s", tmp.userID)
			if botman.dbConnected then connSQL:execute("INSERT INTO persistentQueue (steam, command, timerDelay) VALUES ('" .. tmp.steam .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + restoreDelay .. "')") end

			cmd = string.format("admin add %s %s", tmp.userID, chatvars.accessLevel)
			if botman.dbConnected then connSQL:execute("INSERT INTO persistentQueue (steam, command, timerDelay) VALUES ('" .. tmp.steam .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + restoreDelay .. "')") end

				cmd = string.format("admin add %s %s", tmp.platform .. "_" .. tmp.steam, chatvars.accessLevel)
				if botman.dbConnected then connSQL:execute("INSERT INTO persistentQueue (steam, command, timerDelay) VALUES ('" .. tmp.steam .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + restoreDelay .. "')") end

			cmd = string.format("pm %s [%s]Your admin status is restored.[-]", tmp.userID, server.chatColour)
			if botman.dbConnected then connSQL:execute("INSERT INTO persistentQueue (steam, command, timerDelay) VALUES ('" .. tmp.steam .. "','" .. connMEM:escape(cmd) .. "','" .. os.time() + restoreDelay .. "')") end

			botman.persistentQueueEmpty = false
			players[tmp.steam].testAsPlayer = true

			if staffList[tmp.userID] then
				staffList[tmp.userID].hidden = true
			end

			if staffList[tmp.steam] then
				staffList[tmp.steam].hidden = true
			end

			if botman.dbConnected then conn:execute("UPDATE staff SET hidden = 1 WHERE steam = '" .. tmp.steam .. "'") end
			if botman.dbConnected then conn:execute("UPDATE staff SET hidden = 1 WHERE steam = '" .. tmp.userID .. "'") end

			sendCommand("admin remove " .. tmp.userID)
			sendCommand("admin remove " .. tmp.platform .. "_" .. tmp.steam)

			if (chatvars.playername ~= "Server") then
				message(string.format("pm %s [%s]Your admin status has been removed. You will regain admin in 1 year or until you use the command {#}restore admin. You are still in the staff list and can use admin commands in The Lounge (IRC).[-]", tmp.userID, server.chatColour))
			else
				irc_chat(chatvars.ircAlias, "Your admin status has been removed. You will regain admin in 1 year or until you use the command {#}restore admin. You are still in the staff list and can use admin commands in The Lounge (IRC).")

				if igplayers[tmp.steam] then
					message(string.format("pm %s [%s]Your admin status has been removed. You will regain admin in 1 year or until you use the command {#}restore admin. You are still in the staff list and can use admin commands in The Lounge (IRC).[-]", tmp.userID, server.chatColour))
				end
			end

			-- force an early retirement
			players[tmp.steam].accessLevel = 90
			setChatColour(tmp.steam, 90)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TimeoutPlayer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}timeout {player name}"
			help[2] = "Send a player to timeout.  You can use their steam or game id and part or all of their name.  If you send the wrong player to timeout {#}return {player name} to fix that.\n"
			help[2] = help[2] .. "While in timeout, the player will not be able to use any bot commands but they can chat."

			tmp.command = help[1]
			tmp.keywords = "timeout,player,send,remove,punish,bad,hacker,griefer"
			tmp.accessLevel = 90
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "timeout")) and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "timeout") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[2] == nil) then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Send a player to timeout where they can only talk.[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You can also send yourself to timeout but not staff.[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "timeout {player name}[-]")
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]See also: " .. server.commandPrefix .. "return {player name}[-]")
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "timeout ") + 8)
			tmp.pname = string.trim(tmp.pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(tmp.pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(tmp.pname)

				if not (tmp.steam == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. tmp.pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. tmp.pname)
					end
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				if (not players[tmp.steam].newPlayer and not chatvars.isAdminHidden) then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]You are limited to sending new players to timeout. " .. players[tmp.steam].name .. " is not new.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if tmp.steam == "0" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. tmp.pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, tmp.pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if (players[tmp.steam].timeout == true) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]This player is already in timeout.  Did you mean " .. server.commandPrefix .. "return ?[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. tmp.steam .. " " .. players[tmp.steam].name .. " is already in timeout.")
				end

				botman.faultyChat = false
				return true
			end

			if (isAdmin(tmp.steam, tmp.userID) and botman.ignoreAdmins) and tmp.steam ~= chatvars.playerid then -- TODO fix this edge case
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Staff cannot be sent to timeout.[-]")
				else
					irc_chat(chatvars.ircAlias, "Staff cannot be sent to timeout.")
				end

				botman.faultyChat = false
				return true
			end

			if not isAdmin(tmp.steam, tmp.userID)	then  -- TODO fix this edge case
				players[tmp.steam].silentBob = true
			end

			-- first record their current x y z
			players[tmp.steam].timeout = true
			players[tmp.steam].xPosTimeout = players[tmp.steam].xPos
			players[tmp.steam].yPosTimeout = players[tmp.steam].yPos
			players[tmp.steam].zPosTimeout = players[tmp.steam].zPos

			if (chatvars.playername ~= "Server") then
				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[tmp.steam].xPosTimeout .. "," .. players[tmp.steam].yPosTimeout .. "," .. players[tmp.steam].zPosTimeout .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(players[tmp.steam].name) .. " SteamID: " .. tmp.steam .. " sent to timeout by " .. escape(players[chatvars.playerid].name) .. "','" .. tmp.steam .. "')") end
			else
				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[tmp.steam].xPosTimeout .. "," .. players[tmp.steam].yPosTimeout .. "," .. players[tmp.steam].zPosTimeout .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(players[tmp.steam].name) .. " SteamID: " .. tmp.steam .. " sent to timeout by " .. escape(players[chatvars.ircid].name) .. "','" .. tmp.steam .. "')") end
			end

			-- then teleport the player to timeout
			sendCommand("tele " .. tmp.userID .. " " .. players[tmp.steam].xPosTimeout .. " 60000 " .. players[tmp.steam].zPosTimeout)
			message("say [" .. server.chatColour .. "]" .. players[tmp.steam].name .. " has been sent to timeout.[-]")

			if botman.dbConnected then conn:execute("UPDATE players SET timeout = 1, silentBob = 1, xPosTimeout = " .. players[tmp.steam].xPosTimeout .. ", yPosTimeout = " .. players[tmp.steam].yPosTimeout .. ", zPosTimeout = " .. players[tmp.steam].zPosTimeout .. " WHERE steam = '" .. tmp.steam .. "'") end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLevelHackAlert()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) level hack alert"
			help[2] = "By default the bot will inform admins when a player's level increases massively in a very short time.  You can disable the message."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,player,level,hacker,alert"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "level") or string.find(chatvars.command, "hack") or string.find(chatvars.command, "alert") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "level" and chatvars.words[3] == "hack" and chatvars.words[4] == "alert" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "disable" then
				server.alertLevelHack = false
				conn:execute("UPDATE server SET alertLevelHack = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will not alert admins when a player's level increases by a large amount.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will not alert admins when a player's level increases by a large amount.")
				end
			else
				server.alertLevelHack = true
				conn:execute("UPDATE server SET alertLevelHack = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot alerts admins when a player's level increases by a large amount.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot alerts admins when a player's level increases by a large amount.")
				end
			end

			irc_chat(chatvars.ircAlias, ".")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleAirdropAlert()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) airdrop alert"
			help[2] = "By default the bot will inform players when an airdrop occurs near them.  You can disable the message."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,airdrop,alert,plane,support"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "air") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "airdrop" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "disable" then
				disableTrigger("AirDrop alert")
				server.enableAirdropAlert = 0
				conn:execute("UPDATE server SET enableAirdropAlert = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The bot will say nothing when airdrops occur.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will say nothing when airdrops occur.")
				end
			else
				enableTrigger("AirDrop alert")
				server.enableAirdropAlert = 1
				conn:execute("UPDATE server SET enableAirdropAlert = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will be alerted to airdrops near their location.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will be alerted to airdrops near their location.")
				end
			end

			irc_chat(chatvars.ircAlias, ".")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBlockPlayer()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}block (or {#}unblock) player {player name}"
			help[2] = "Prevent a player from using IRC.  Other stuff may be blocked in the future."

			tmp.command = help[1]
			tmp.keywords = "unblock,player,irc,lounge"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "player") or string.find(chatvars.command, "block") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "block" or chatvars.words[1] == "unblock") and chatvars.words[2] == "player" and chatvars.words[3] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = nil
			pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7)

			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if not isArchived then
				if chatvars.words[1] == "block" then
					players[tmp.steam].denyRights = true
					if botman.dbConnected then conn:execute("UPDATE players SET denyRights = 1 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. playerName .. " will be ignored on IRC.[-]")
					else
						irc_chat(chatvars.ircAlias,players[tmp.steam].name .. " will be ignored on IRC.")
					end
				else
					players[tmp.steam].denyRights = false
					if botman.dbConnected then conn:execute("UPDATE players SET denyRights = 0 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. playerName .. " can talk to the bot on IRC.[-]")
					else
						irc_chat(chatvars.ircAlias,players[tmp.steam].name .. " can talk to the bot on IRC.")
					end
				end
			else
				if chatvars.words[1] == "block" then
					playersArchived[tmp.steam].denyRights = true
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET denyRights = 1 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. playerName .. " will be ignored on IRC.[-]")
					else
						irc_chat(chatvars.ircAlias,playerName .. " will be ignored on IRC.")
					end
				else
					playersArchived[tmp.steam].denyRights = false
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET denyRights = 0 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. playerName .. " can talk to the bot on IRC.[-]")
					else
						irc_chat(chatvars.ircAlias,playerName .. " can talk to the bot on IRC.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBounties()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) bounty"
			help[2] = "Normally a small bounty is awarded for a player's first pvp kill in pvp rules.  You can disable the automatic bounty.\n"
			help[2] = help[2] .. "Players will still be able to manually place bounties, but those come out of their " .. server.moneyPlural .. "."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,pvp,bounty"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "bounty") or string.find(chatvars.command, "pvp") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "bounty" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "disable" then
				server.enableBounty = 0
				conn:execute("UPDATE server SET enableBounty = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The automatic bounty for first kills is disabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The automatic bounty for first kills is disabled.")
				end
			else
				server.enableBounty = 1
				conn:execute("UPDATE server SET enableBounty = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]A small automatic bounty will be awarded for a player's first kill.[-]")
				else
					irc_chat(chatvars.ircAlias, "A small automatic bounty will be awarded for a player's first kill.")
				end
			end

			irc_chat(chatvars.ircAlias, ".")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleFreezeThawPlayer()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}freeze (or {#}unfreeze) {player name}"
			help[2] = "Bind a player to their current position.  They get teleported back if they move."

			tmp.command = help[1]
			tmp.keywords = "freeze,player,punish,hacker,griefer,cheater,fun"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "freeze") or string.find(chatvars.command, "player") or string.find(chatvars.command, "stop") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "freeze" or chatvars.words[1] == "unfreeze" or chatvars.words[1] == "thaw") and chatvars.words[2] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "freeze" or chatvars.words[1] == "unfreeze" then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "freeze") + 7)
			else
				if chatvars.words[1] == "thaw" then
					pname = string.sub(chatvars.command, string.find(chatvars.command, "thaw") + 5)
				end
			end

			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.steam].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "freeze" then
				if players[tmp.steam].freeze then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. " is already frozen.[-]")
					else
						irc_chat(chatvars.ircAlias, players[tmp.steam].name .. " is already frozen.")
					end

					botman.faultyChat = false
					return true
				end

				if isAdmin(tmp.steam, tmp.userID) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The staff are cold enough as it is.[-]")
					else
						irc_chat(chatvars.ircAlias, "This command is restricted.")
					end

					botman.faultyChat = false
					return true
				end

				players[tmp.steam].freeze = true
				players[tmp.steam].prisonxPosOld = players[tmp.steam].xPos
				players[tmp.steam].prisonyPosOld = players[tmp.steam].yPos
				players[tmp.steam].prisonzPosOld = players[tmp.steam].zPos
				message("say [" .. server.chatColour .. "]STOP RIGHT THERE CRIMINAL SCUM![-]")
			else
				if not players[tmp.steam].freeze then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. players[tmp.steam].name .. " is not currently frozen.[-]")
					else
						irc_chat(chatvars.ircAlias, players[tmp.steam].name .. " is not currently frozen.")
					end

					botman.faultyChat = false
					return true
				end

				players[tmp.steam].freeze = false
				players[tmp.steam].prisonxPosOld = 0
				players[tmp.steam].prisonyPosOld = 0
				players[tmp.steam].prisonzPosOld = 0
				message("say [" .. server.chatColour .. "]Citizen " .. players[tmp.steam].name .. " you are free to go.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleFriendlyPVPResponse()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}ignore (or {#}punish) friendly pvp"
			help[2] = "By default if a player PVPs where the rules don't permit it, they can get jailed.\n"
			help[2] = help[2] .. "You can tell the bot to ignore friendly kills.  Players must have friended the victim before the PVP occurs."

			tmp.command = help[1]
			tmp.keywords = "pvp,kill,friendlyfire,rules,world"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "pvp") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "ignore" or chatvars.words[1] == "punish") and chatvars.words[2] == "friendly" and chatvars.words[3] == "pvp" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "ignore") then
				server.pvpIgnoreFriendlyKills = true
				if botman.dbConnected then conn:execute("UPDATE server SET pvpIgnoreFriendlyKills = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Friendly PVPs are ignored.[-]")
				else
					irc_chat(chatvars.ircAlias, "Friendly PVPs are ignored.")
				end
			else
				server.pvpIgnoreFriendlyKills = false
				if botman.dbConnected then conn:execute("UPDATE server SET pvpIgnoreFriendlyKills = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Friendly PVP will get the killer jailed.[-]")
				else
					irc_chat(chatvars.ircAlias, "Friendly PVP will get the killer jailed.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIgnorePlayer()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}ignore (or {#}include) player {player name}"
			help[2] = "An ignored player can have uncraftable inventory and do hacker like activity such as teleporting.\n"
			help[2] = help[2] .. "An included player is checked for these things and can be punished or temp banned for them."

			tmp.command = help[1]
			tmp.keywords = "player,ignore,include,inventory,items,uncraftable,restricted,bad"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "player") or string.find(chatvars.command, "incl") or string.find(chatvars.command, "igno") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "ignore" or chatvars.words[1] == "include") and chatvars.words[2] == "player" and chatvars.words[3] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = nil
			pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7)

			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if chatvars.words[1] == "ignore" then
				if not isArchived then
					players[tmp.steam].ignorePlayer = true
					if botman.dbConnected then conn:execute("UPDATE players SET ignorePlayer = 1 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. playerName .. " is allowed to carry uncraftable items, fly, teleport and other fun stuff.[-]")
					else
						irc_chat(chatvars.ircAlias,playerName .. " is allowed to carry uncraftable items, teleport and other fun stuff.")
					end
				else
					playersArchived[tmp.steam].ignorePlayer = true
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET ignorePlayer = 1 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. playerName .. " is allowed to carry uncraftable items, fly, teleport and other fun stuff.[-]")
					else
						irc_chat(chatvars.ircAlias,playerName .. " is allowed to carry uncraftable items, teleport and other fun stuff.")
					end
				end
			else
				if not isArchived then
					players[tmp.steam].ignorePlayer = false
					if botman.dbConnected then conn:execute("UPDATE players SET ignorePlayer = 0 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. playerName .. " is not allowed to carry uncraftable items, fly or teleport and can be temp banned or made fun of.[-]")
					else
						irc_chat(chatvars.ircAlias,playerName .. " is not allowed to carry uncraftable items, teleport and can be temp banned or made fun of.")
					end
				else
					playersArchived[tmp.steam].ignorePlayer = false
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET ignorePlayer = 0 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. playerName .. " is not allowed to carry uncraftable items, fly or teleport and can be temp banned or made fun of.[-]")
					else
						irc_chat(chatvars.ircAlias,playerName .. " is not allowed to carry uncraftable items, teleport and can be temp banned or made fun of.")
					end

				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIncludeExcludeAdmins()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}include (or {#}exclude) admins"
			help[2] = "Normally the bot ignores admins when checking inventory and other stuff.  If admins are included, all of the rules that apply to players will also apply to admins.\n"
			help[2] = help[2] .. "This is useful for testing the bot.  You can also use {#}test as player (for 5 minutes)\n"
			help[2] = help[2] .. "This setting is not stored and will revert to excluding admins the next time the bot runs."

			tmp.command = help[1]
			tmp.keywords = "admin,include,exclude,rules,inventory,items,bad,restricted"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "clude") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "rule") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "include" or chatvars.words[1] == "exclude") and chatvars.words[2] == "admins" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "exclude" then
				botman.ignoreAdmins = true

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Admins can ignore the server rules.[-]")
				else
					irc_chat(chatvars.ircAlias, "Admins can ignore the server rules.")
				end
			else
				botman.ignoreAdmins = false

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Admins must obey the server rules.  OBEY!  OBEY![-]")
				else
					irc_chat(chatvars.ircAlias, "Admins must obey the server rules.  OBEY!  OBEY!")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIRCNickUsedBySayCommand()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}set say uses name (the default)\n"
			help[1] = help[1] .. "Or {#}set say uses nick"
			help[2] = "The IRC command 'say' uses your player name by default.\n"
			help[2] = help[2] .. "You can set it to use the IRC nickname instead.  Note:  It will do that for all IRC users."

			tmp.command = help[1]
			tmp.keywords = "set,irc,say,nickname,lounge,chat,pm,privatemessage"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "irc") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "set") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "set" and chatvars.words[2] == "say" and string.find(chatvars.words[3], "use") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[4] == "nick" then
				server.sayUsesIRCNick = true
				if botman.dbConnected then conn:execute("UPDATE server SET sayUsesIRCNick = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The IRC command 'say' will use the IRC nickname ingame.[-]")
				else
					irc_chat(chatvars.ircAlias, "The IRC command 'say' will use the IRC nickname ingame.")
				end
			else
				server.sayUsesIRCNick = false
				if botman.dbConnected then conn:execute("UPDATE server SET sayUsesIRCNick = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The IRC command 'say' will use the player name ingame.[-]")
				else
					irc_chat(chatvars.ircAlias, "The IRC command 'say' will use the player name ingame.")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_toggleXBox()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}allow (or {#}disallow) xbox"
			help[2] = "Allow or block XBox (Gamepass) players joining your server.  Default is allow."

			tmp.command = help[1]
			tmp.keywords = "allow,disallow,block,xbox,gamepass"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "allow") or string.find(chatvars.command, "xbox") or string.find(chatvars.command, "game") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow") and chatvars.words[2] == "xbox" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "allow") then
				server.kickXBox = false
				if botman.dbConnected then conn:execute("UPDATE server SET kickXBox = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]XBox (gamepass) players are allowed to join your server.[-]")
				else
					irc_chat(chatvars.ircAlias, "XBox (gamepass) players are allowed to join your server.")
				end
			else
				server.kickXBox = true
				if botman.dbConnected then conn:execute("UPDATE server SET kickXBox = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]XBox (gamepass) players will be kicked from your server.[-]")
				else
					irc_chat(chatvars.ircAlias, "XBox (gamepass) players will be kicked from your server.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TogglePack()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) (pack or revive)"
			help[2] = "Players can teleport close to where they last died to retrieve their pack.\n"
			help[2] = help[2] .. "You can disable the pack and revive commands.  They are enabled by default."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,pack,revive,spawn,death"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "able") or string.find(chatvars.command, "pack") or string.find(chatvars.command, "tele") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and (chatvars.words[2] == "pack" or chatvars.words[2] == "revive") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "enable") then
				server.allowPackTeleport = true
				if botman.dbConnected then conn:execute("UPDATE server SET allowPackTeleport = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players can teleport to their pack when they die.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can teleport to their pack when they die.")
				end
			else
				server.allowPackTeleport = false
				if botman.dbConnected then conn:execute("UPDATE server SET allowPackTeleport = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The pack and revive commands are disabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The pack and revive commands are disabled.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleRemoveExpiredClaims()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}remove (or {#}leave) expired claims"
			help[2] = "By default the bot will not remove expired claims.  It will always ignore admin claims."

			tmp.command = help[1]
			tmp.keywords = "remove,leave,toggle,landclaims,expired,despawn,lcb,claimblocks"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "remove") or string.find(chatvars.command, "leave") or string.find(chatvars.command, "exp") or string.find(chatvars.command, "claim") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "remove" or chatvars.words[1] == "leave") and chatvars.words[2] == "expired" and string.find(chatvars.words[3], "claim") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "remove" then
				server.removeExpiredClaims = true
				conn:execute("UPDATE server SET removeExpiredClaims = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Expired claims will be removed when players are nearby.[-]")
				else
					irc_chat(chatvars.ircAlias, "Expired claims will be removed when players are nearby.")
				end
			else
				server.removeExpiredClaims = false
				conn:execute("UPDATE server SET removeExpiredClaims = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Expired claims will not be removed.[-]")
				else
					irc_chat(chatvars.ircAlias, "Expired claims will not be removed.")
				end
			end

			irc_chat(chatvars.ircAlias, ".")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleReservedSlotPlayer()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}reserve (or {#}unreserve) slot {player name}"
			help[2] = "Give a player the right to take a reserved slot when the server is full.\n"
			help[2] = help[2] .. "Reserved slots are auto assigned for donors and staff."

			tmp.command = help[1]
			tmp.keywords = "slots,reserved,player,join"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "slot") or string.find(chatvars.command, "player") or string.find(chatvars.command, "rese") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "reserve" or chatvars.words[1] == "unreserve") and chatvars.words[2] == "slot" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, " slot ") + 6)
			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if chatvars.words[1] == "reserve" then
				if not isArchived then
					players[tmp.steam].reserveSlot = true
					if botman.dbConnected then conn:execute("UPDATE players SET reserveSlot = 1 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playerName ..  " can take a reserved slot when the server is full.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playerName ..  " can take a reserved slot when the server is full.")
					end
				else
					playersArchived[tmp.steam].reserveSlot = true
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET reserveSlot = 1 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playerName ..  " can take a reserved slot when the server is full.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playerName ..  " can take a reserved slot when the server is full.")
					end
				end
			else
				if not isArchived then
					players[tmp.steam].reserveSlot = false
					if botman.dbConnected then conn:execute("UPDATE players SET reserveSlot = 0 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playerName ..  " can only reserve a slot if they are a donor or staff.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playerName ..  " can only reserve a slot if they are a donor or staff.")
					end
				else
					playersArchived[tmp.steam].reserveSlot = false
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET reserveSlot = 0 WHERE steam = '" .. tmp.steam .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playerName ..  " can only reserve a slot if they are a donor or staff.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playerName ..  " can only reserve a slot if they are a donor or staff.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleScreamerAlert()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}enable (or {#}disable) screamer alert"
			help[2] = "By default the bot will warn players when screamers are approaching.  You can disable that warning."

			tmp.command = help[1]
			tmp.keywords = "enable,disable,screamer,scouts,alert,warning"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "scream") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "screamer" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "disable" then
				--disableTrigger("Zombie Scouts")
				server.enableScreamerAlert = false
				conn:execute("UPDATE server SET enableScreamerAlert = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]The screamer alert message is disabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The screamer alert message is disabled.")
				end
			else
				--enableTrigger("Zombie Scouts")
				server.enableScreamerAlert = true
				conn:execute("UPDATE server SET enableScreamerAlert = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Players will be warned when screamers are heading towards their location.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players will be warned when screamers are heading towards their location.")
				end
			end

			irc_chat(chatvars.ircAlias, ".")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleTeleportPlayer()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}allow (or {#}disallow) teleport {player name}"
			help[2] = "Allow or prevent a player from using any teleports.  When disabled, they won't be able to teleport themselves, but they can still be teleported.  Also physical teleports won't work for them."

			tmp.command = help[1]
			tmp.keywords = "disallow,teleport,player"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "tele") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow") and chatvars.words[2] == "teleport" and chatvars.words[3] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "teleport") + 9)
			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if chatvars.words[1] == "disallow" then
				if not isArchived then
					players[tmp.steam].canTeleport = false
					message("say [" .. server.chatColour .. "] " .. players[tmp.steam].name ..  " is not allowed to use teleports.[-]")
					if botman.dbConnected then conn:execute("UPDATE players SET canTeleport = 0 WHERE steam = '" .. tmp.steam .. "'") end
				else
					playersArchived[tmp.steam].canTeleport = false
					message("say [" .. server.chatColour .. "] " .. playerName ..  " is not allowed to use teleports.[-]")
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET canTeleport = 0 WHERE steam = '" .. tmp.steam .. "'") end
				end
			else
				if not isArchived then
					players[tmp.steam].canTeleport = true
					message("say [" .. server.chatColour .. "] " .. players[tmp.steam].name ..  " is allowed to use teleports.[-]")
					if botman.dbConnected then conn:execute("UPDATE players SET canTeleport = 1 WHERE steam = '" .. tmp.steam .. "'") end
				else
					playersArchived[tmp.steam].canTeleport = true
					message("say [" .. server.chatColour .. "] " .. playerName ..  " is allowed to use teleports.[-]")
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET canTeleport = 1 WHERE steam = '" .. tmp.steam .. "'") end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleWatchPlayer()
		local playerName, isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}watch {player name}\n"
			help[1] = help[1] .. "Or {#}watch new players\n"
			help[1] = help[1] .. "Or {#}stop watching {player name}\n"
			help[1] = help[1] .. "Or {#}stop watching everyone"
			help[2] = "Flag a player or all current new players for extra attention and logging.  New players are watched by default."

			tmp.command = help[1]
			tmp.keywords = "watch,new,player,every,all,stop"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "watch") or string.find(chatvars.command, "player") or string.find(chatvars.command, "new") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "watch") or (chatvars.words[1] == "stop" and (chatvars.words[2] == "watching")) then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[2] == "new" and chatvars.words[3] == "players") then
				for k,v in pairs(players) do
					if v.newPlayer == true then
						v.watchPlayer = true
						v.watchPlayerTimer = os.time() + server.defaultWatchTimer
						if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + server.defaultWatchTimer .. " WHERE steam = '" .. k .. "'") end
					end
				end

				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]New players will be watched.[-]")

				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "watch") then
				if chatvars.words[2] == "everyone" then -- including staff! :O
					if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + server.defaultWatchTimer) end
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + server.defaultWatchTimer) end

					for k,v in pairs(igplayers) do
						if not isAdminHidden(k, v.userID) then
							players[k].watchPlayer = true
							players[k].watchPlayerTimer = os.time() + server.defaultWatchTimer
						end
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Everyone is being watched right now.  The tinfoil hat does nothing![-]")
					else
						irc_chat(chatvars.ircAlias, "Everyone is being watched right now.  The tinfoil hat does nothing!")
					end

					botman.faultyChat = false
					return true
				else
					pname = string.sub(chatvars.command, string.find(chatvars.command, "watch ") + 6)
					pname = string.trim(pname)
					tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)
				end

				if tmp.steam == "0" then
					tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

					if not (tmp.steam == "0") then
						playerName = playersArchived[tmp.steam].name
						isArchived = true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				else
					playerName = players[tmp.steam].name
					isArchived = false
				end

				if not isArchived then
					players[tmp.steam].watchPlayer = true
					players[tmp.steam].watchPlayerTimer = os.time() + server.defaultWatchTimer

					if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + server.defaultWatchTimer .. " WHERE steam = '" .. tmp.steam .. "'") end
				else
					playersArchived[tmp.steam].watchPlayer = true
					playersArchived[tmp.steam].watchPlayerTimer = os.time() + server.defaultWatchTimer

					if botman.dbConnected then conn:execute("UPDATE playersArchived SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + server.defaultWatchTimer .. " WHERE steam = '" .. tmp.steam .. "'") end
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Admins will be alerted whenever " .. playerName ..  " enters a base.[-]")
				else
					irc_chat(chatvars.ircAlias, "Admins will be alerted whenever " .. playerName ..  " enters a base.")
				end
			end

			if (chatvars.words[1] == "stop" and chatvars.words[2] == "watching") then
				if (chatvars.words[3] == "everyone") then
					for k,v in pairs(players) do
						v.watchPlayer = false
						v.watchPlayerTimer = 0
					end

					if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 0, watchPlayerTimer = 0") end

					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Nobody is being watched right now.[-]")

					botman.faultyChat = false
					return true
				end

				pname = string.sub(chatvars.command, string.find(chatvars.command, "watching ") + 9)
				pname = string.trim(pname)
				tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

				if tmp.steam == "0" then
					tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

					if not (tmp.steam == "0") then
						playerName = playersArchived[tmp.steam].name
						isArchived = true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				else
					playerName = players[tmp.steam].name
					isArchived = false
				end

				if not isArchived then
					players[tmp.steam].watchPlayer = false
					if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = '" .. tmp.steam .. "'") end
				else
					playersArchived[tmp.steam].watchPlayer = false
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = '" .. tmp.steam .. "'") end
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Player " .. playerName ..  " will not be watched.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. playerName ..  " will not be watched.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnlockAll()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}unlockall"
			help[2] = "Unlocks all locked containers etc in your immediate area (the current chunk)"

			tmp.command = help[1]
			tmp.keywords = "unlock,storage,safe,container,secure,chest,lockable,locked"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "lock") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "unlockall" or (chatvars.words[1] == "unlock" and chatvars.words[2] == "all") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			unlockAll(chatvars.playerid)
			message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Locked containers have been unlocked in the current chunk.[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UploadHelp()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}upload help {url where commands.json file can be downloaded by the bot}"
			help[2] = "Use this command to upload your edited commands.json file to the bot.\n"
			help[2] = help[2] .. "IMPORTANT: Every time you upload the json file you need to change the name of the file to prevent it being cached by the host server or you will not see your changes.\n"
			help[2] = help[2] .. "The url must link to the raw json file so you will not be able to use text sharing sites such as pastebin etc.  If you own a website, upload it there."

			tmp.command = help[1]
			tmp.keywords = "help,download,upload,permissions,custom,commands,accesslevels"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "upload") or string.find(chatvars.command, "download") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "upload" and chatvars.words[2] == "help" then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			tmp.url = string.sub(chatvars.command, string.find(chatvars.command, " help ") + 6)

			downloadFile(homedir .. "/temp/commands.json", tmp.url)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]If the url links directly to the commands.json file, the bot will read it and update the command permissions from it. To test that it worked, try a command that you have adjusted.[-]")
			else
				irc_chat(chatvars.ircAlias, "If the url links directly to the commands.json file, the bot will read it and update the command permissions from it. To test that it worked, try a command that you have adjusted.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_VisitCrimescene()
		local isArchived

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}crimescene {prisoner}"
			help[2] = "Teleport to the coords where a player was when they got arrested."

			tmp.command = help[1]
			tmp.keywords = "pvp,visit,teleport,crime,death,scene,prisoner,investigate"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "pvp") or string.find(chatvars.command, "death") or string.find(chatvars.command, "crime") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "crimescene") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			prisoner = string.sub(chatvars.command, string.find(chatvars.command, "scene ") + 6)
			prisoner = string.trim(prisoner)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(prisoner)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(prisoner)

				if not (tmp.steam == "0") then
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. prisoner)
					end

					botman.faultyChat = false
					return true
				end
			else
				isArchived = false
			end

			if not isArchived then
				if (players[tmp.steam].prisoner) then
					-- first record the current x y z
					players[chatvars.playerid].xPosOld = chatvars.intX
					players[chatvars.playerid].yPosOld = chatvars.intY
					players[chatvars.playerid].zPosOld = chatvars.intZ

					-- then teleport to the prisoners old coords
					cmd = "tele " .. chatvars.userID.. " " .. players[tmp.steam].prisonxPosOld .. " " .. players[tmp.steam].prisonyPosOld .. " " .. players[tmp.steam].prisonzPosOld
					teleport(cmd, chatvars.playerid, chatvars.userID)
				else
					-- tp to their return coords if they are set
					if tonumber(players[tmp.steam].yPosTimeout) ~= 0 then
						-- first record the current x y z
						players[chatvars.playerid].xPosOld = chatvars.intX
						players[chatvars.playerid].yPosOld = chatvars.intY
						players[chatvars.playerid].zPosOld = chatvars.intZ

						-- then teleport to the prisoners old coords
						cmd = "tele " .. chatvars.userID.. " " .. players[tmp.steam].xPosTimeout .. " " .. players[tmp.steam].yPosTimeout .. " " .. players[tmp.steam].zPosTimeout
						teleport(cmd, chatvars.playerid, chatvars.userID)
					end
				end
			else
				if (playersArchived[tmp.steam].prisoner) then
					-- first record the current x y z
					players[chatvars.playerid].xPosOld = chatvars.intX
					players[chatvars.playerid].yPosOld = chatvars.intY
					players[chatvars.playerid].zPosOld = chatvars.intZ

					-- then teleport to the prisoners old coords
					cmd = "tele " .. chatvars.userID.. " " .. playersArchived[tmp.steam].prisonxPosOld .. " " .. playersArchived[tmp.steam].prisonyPosOld .. " " .. playersArchived[tmp.steam].prisonzPosOld
					teleport(cmd, chatvars.playerid, chatvars.userID)
				else
					-- tp to their return coords if they are set
					if tonumber(players[tmp.steam].yPosTimeout) ~= 0 then
						-- first record the current x y z
						players[chatvars.playerid].xPosOld = chatvars.intX
						players[chatvars.playerid].yPosOld = chatvars.intY
						players[chatvars.playerid].zPosOld = chatvars.intZ

						-- then teleport to the prisoners old coords
						cmd = "tele " .. chatvars.userID.. " " .. playersArchived[tmp.steam].xPosTimeout .. " " .. playersArchived[tmp.steam].yPosTimeout .. " " .. playersArchived[tmp.steam].zPosTimeout
						teleport(cmd, chatvars.playerid, chatvars.userID)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_VisitPlayerBase()  -- tested 8/7/21
		local playerName, isArchived
		local baseFound, base, baseSearch

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}playerbase (or {#}playerhome) {player name}\n"
			help[1] = help[1] .. "Or {#}playerbase (or {#}playerhome) {player name} base {number or name}"
			help[2] = "Teleport yourself to a player's base."

			tmp.command = help[1]
			tmp.keywords = "base,home,teleport,player,send,return"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "tele") or string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "play") and chatvars.showHelp or botman.registerHelp then
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

		if (chatvars.words[1] == "playerhome" or chatvars.words[1] == "playerbase") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			if string.find(chatvars.command, " base ") then
				pname = string.sub(chatvars.command, 13, string.find(chatvars.command, " base ") - 1)
				baseSearch = string.sub(chatvars.command, string.find(chatvars.command, " base ") + 6)
			else
				pname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1], nil, true) + string.len(chatvars.words[1]))
			end

			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
				isArchived = false
			end

			if not isArchived then
				if baseSearch then
					baseFound, base = LookupBase(tmp.steam, baseSearch)
				else
					baseFound, base = LookupBase(tmp.steam)
				end

				if not baseFound then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. pname .. " Has not set a base yet or they have no base " .. baseSearch .. "[-]")
					botman.faultyChat = false
					return true
				else
					-- first record the current x y z
					players[chatvars.playerid].xPosOld = igplayers[chatvars.playerid].xPos
					players[chatvars.playerid].yPosOld = igplayers[chatvars.playerid].yPos
					players[chatvars.playerid].zPosOld = igplayers[chatvars.playerid].zPos

					cmd = "tele " .. chatvars.userID.. " " .. base.x .. " " .. base.y .. " " .. base.z
					teleport(cmd, chatvars.playerid, chatvars.userID)
				end
			else
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]" .. playerName .. " has no base set because they are archived.[-]")
				botman.faultyChat = false
				return true
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WhitelistAddRemovePlayer()
		local playerName

		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}whitelist add (or {#}remove) {player name}"
			help[2] = "Add (or remove) a player to the bot's whitelist. This is not the server's whitelist and it works differently.\n"
			help[2] = help[2] .. "It exempts the player from bot restrictions such as ping kicks and the country blacklist."

			tmp.command = help[1]
			tmp.keywords = "add,remove,whitelist,player,security"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "white") or string.find(chatvars.command, "list") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "whitelist" and (chatvars.words[2] == "add" or chatvars.words[2] == "remove") and chatvars.words[3] ~= nil then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			pname = nil

			if chatvars.words[2] == "add" then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "add ") + 4)
			else
				pname = string.sub(chatvars.command, string.find(chatvars.command, "remove ") + 7)
			end

			pname = string.trim(pname)
			tmp.steam, tmp.steamOwner, tmp.userID = LookupPlayer(pname)

			if tmp.steam == "0" then
				tmp.steam, tmp.steamOwner, tmp.userID = LookupArchivedPlayer(pname)

				if not (tmp.steam == "0") then
					playerName = playersArchived[tmp.steam].name
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.steam].name
			end

			if chatvars.words[2] == "add" then
				whitelist[tmp.steam] = {}
				if botman.dbConnected then conn:execute("INSERT INTO whitelist (steam) VALUES ('" .. tmp.steam .. "')") end
				sendCommand("ban remove Steam_" .. tmp.steam)
				sendCommand("ban remove EOS_" .. tmp.userID)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. playerName .. " has been added to the whitelist.[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. " has been added to the whitelist.")
				end
			else
				whitelist[tmp.steam] = nil
				if botman.dbConnected then conn:execute("DELETE FROM whitelist WHERE steam = '" .. tmp.steam .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "] " .. playerName .. " is no longer whitelisted.[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. " is no longer whitelisted.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WhitelistEveryone()
		if chatvars.showHelp or botman.registerHelp then
			help = {}
			help[1] = " {#}whitelist everyone (or all)"
			help[2] = "You can add everyone except blacklisted players to the bot's whitelist."

			tmp.command = help[1]
			tmp.keywords = "bot,whitelist,players,all,everyone,security"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0
			tmp.functionName = debugger.getinfo(1, "n").name

			help[3] = helpCommandRestrictions(tmp.topic .. "_" .. tmp.functionName)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "white") and chatvars.showHelp or botman.registerHelp then
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

		if chatvars.words[1] == "whitelist" and (chatvars.words[2] == "everyone" or chatvars.words[2] == "all") then
			if not verifyCommandAccess(tmp.topic, debugger.getinfo(1, "n").name) then
				botman.faultyChat = false
				return true
			end

			for k,v in pairs(players) do
				if not string.find(server.blacklistCountries, v.country) then
					conn:execute("INSERT INTO whitelist (steam) VALUES ('" .. k .. "')")
				end
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.userID .. " [" .. server.chatColour .. "]Everyone except blacklisted players has been whitelisted.[-]")
			else
				irc_chat(chatvars.ircAlias, "Everyone except blacklisted players has been whitelisted.")
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

if debug then dbug("debug admin") end

	if botman.registerHelp then
		if debug then dbug("Registering help - admin commands") end

		tmp.topicDescription = "Admin commands are mainly about doing things to or for players but is also a catchall for commands that don't really fit elsewhere but are for admins."

		if chatvars.ircAlias ~= "" then
			irc_chat(chatvars.ircAlias, ".")
			irc_chat(chatvars.ircAlias, "Admin Commands:")
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
			if chatvars.words[3] ~= "admin" then
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
		irc_chat(chatvars.ircAlias, "Admin Commands:")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "admin")
	end

	result = cmd_AddRemoveAdmin()

	if result then
		if debug then dbug("debug cmd_AddRemoveAdmin triggered") end
		return result, "cmd_AddRemoveAdmin"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveBadItem()

	if result then
		if debug then dbug("debug cmd_AddRemoveBadItem triggered") end
		return result, "cmd_AddRemoveBadItem"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveBadWord()

	if result then
		if debug then dbug("debug cmd_AddRemoveBadWord triggered") end
		return result, "cmd_AddRemoveBadWord"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveBlacklistCountry()

	if result then
		if debug then dbug("debug cmd_AddRemoveBlacklistCountry triggered") end
		return result, "cmd_AddRemoveBlacklistCountry"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveDonor()

	if result then
		if debug then dbug("debug cmd_AddRemoveDonor triggered") end
		return result, "cmd_AddRemoveDonor"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveRestrictedItem()

	if result then
		if debug then dbug("debug cmd_AddRemoveRestrictedItem triggered") end
		return result, "cmd_AddRemoveRestrictedItem"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveWhitelistCountry()

	if result then
		if debug then dbug("debug cmd_AddRemoveWhitelistCountry triggered") end
		return result, "cmd_AddRemoveWhitelistCountry"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ArchivePlayers()

	if result then
		if debug then dbug("debug cmd_ArchivePlayers triggered") end
		return result, "cmd_ArchivePlayers"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ArrestPlayer()

	if result then
		if debug then dbug("debug cmd_ArrestPlayer triggered") end
		return result, "cmd_ArrestPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_BanUnbanPlayer()

	if result then
		if debug then dbug("debug cmd_BanUnbanPlayer triggered") end
		return result, "cmd_BanUnbanPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_BlockChatCommandsForPlayer()

	if result then
		if debug then dbug("debug cmd_BlockChatCommandsForPlayer triggered") end
		return result, "cmd_BlockChatCommandsForPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_BurnPlayer()

	if result then
		if debug then dbug("debug cmd_BurnPlayer triggered") end
		return result, "cmd_BurnPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClearBlacklist()

	if result then
		if debug then dbug("debug cmd_ClearBlacklist triggered") end
		return result, "cmd_ClearBlacklist"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClearWhitelist()

	if result then
		if debug then dbug("debug cmd_ClearWhitelist triggered") end
		return result, "cmd_ClearWhitelist"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_CoolPlayer()

	if result then
		if debug then dbug("debug cmd_CoolPlayer triggered") end
		return result, "cmd_CoolPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_CurePlayer()

	if result then
		if debug then dbug("debug cmd_CurePlayer triggered") end
		return result, "cmd_CurePlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_DownloadHelp()

	if result then
		if debug then dbug("debug cmd_DownloadHelp triggered") end
		return result, "cmd_DownloadHelp"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_EquipAdmin()

	if result then
		if debug then dbug("debug cmd_EquipAdmin triggered") end
		return result, "cmd_EquipAdmin"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ExilePlayer()

	if result then
		if debug then dbug("debug cmd_ExilePlayer triggered") end
		return result, "cmd_ExilePlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_FreePlayer()

	if result then
		if debug then dbug("debug cmd_FreePlayer triggered") end
		return result, "cmd_FreePlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_GiveBackClaims()

	if result then
		if debug then dbug("debug cmd_GiveBackClaims triggered") end
		return result, "cmd_GiveBackClaims"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_GiveEveryoneItem()

	if result then
		if debug then dbug("debug cmd_GiveEveryoneItem triggered") end
		return result, "cmd_GiveEveryoneItem"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_GivePlayerItem()

	if result then
		if debug then dbug("debug cmd_GivePlayerItem triggered") end
		return result, "cmd_GivePlayerItem"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_GiveAdminSupplies()

	if result then
		if debug then dbug("debug cmd_GiveAdminSupplies triggered") end
		return result, "cmd_GiveAdminSupplies"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_GotoPlayer()

	if result then
		if debug then dbug("debug cmd_GotoPlayer triggered") end
		return result, "cmd_GotoPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_HordeMe()

	if result then
		if debug then dbug("debug cmd_HordeMe triggered") end
		return result, "cmd_HordeMe"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_KickPlayer()

	if result then
		if debug then dbug("debug cmd_KickPlayer triggered") end
		return result, "cmd_KickPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_LeavePlayerClaims()

	if result then
		if debug then dbug("debug cmd_LeavePlayerClaims triggered") end
		return result, "cmd_LeavePlayerClaims"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBadItems()

	if result then
		if debug then dbug("debug cmd_ListBadItems triggered") end
		return result, "cmd_ListBadItems"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBadWords()

	if result then
		if debug then dbug("debug cmd_ListBadWords triggered") end
		return result, "cmd_ListBadWords"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBasesNearby()

	if result then
		if debug then dbug("debug cmd_ListBasesNearby triggered") end
		return result, "cmd_ListBasesNearby"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBlacklist()

	if result then
		if debug then dbug("debug cmd_ListBlacklist triggered") end
		return result, "cmd_ListBlacklist"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListClaims()

	if result then
		if debug then dbug("debug cmd_ListClaims triggered") end
		return result, "cmd_ListClaims"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListOfflinePlayersNearby()

	if result then
		if debug then dbug("debug cmd_ListOfflinePlayersNearby triggered") end
		return result, "cmd_ListOfflinePlayersNearby"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListPrisoners()

	if result then
		if debug then dbug("debug cmd_ListPrisoners triggered") end
		return result, "cmd_ListPrisoners"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListStaff()

	if result then
		if debug then dbug("debug cmd_ListStaff triggered") end
		return result, "cmd_ListStaff"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListRestrictedItems()

	if result then
		if debug then dbug("debug cmd_ListRestrictedItems triggered") end
		return result, "cmd_ListRestrictedItems"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListWhitelist()

	if result then
		if debug then dbug("debug cmd_ListWhitelist triggered") end
		return result, "cmd_ListWhitelist"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_MendPlayer()

	if result then
		if debug then dbug("debug cmd_MendPlayer triggered") end
		return result, "cmd_MendPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_MovePlayer()

	if result then
		if debug then dbug("debug cmd_MovePlayer triggered") end
		return result, "cmd_MovePlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_NearPlayer()

	if result then
		if debug then dbug("debug cmd_NearPlayer triggered") end
		return result, "cmd_NearPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_PlayerIsNotNew()

	if result then
		if debug then dbug("debug cmd_PlayerIsNotNew triggered") end
		return result, "cmd_PlayerIsNotNew"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_PootaterPlayer()

	if result then
		if debug then dbug("debug cmd_PootaterPlayer triggered") end
		return result, "cmd_PootaterPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReadClaims()

	if result then
		if debug then dbug("debug cmd_ReadClaims triggered") end
		return result, "cmd_ReadClaims"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReleasePlayer()

	if result then
		if debug then dbug("debug cmd_ReleasePlayer triggered") end
		return result, "cmd_ReleasePlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReleasePlayerHere()

	if result then
		if debug then dbug("debug cmd_ReleasePlayerHere triggered") end
		return result, "cmd_ReleasePlayerHere"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReloadAdmins()

	if result then
		if debug then dbug("debug cmd_ReloadAdmins triggered") end
		return result, "cmd_ReloadAdmins"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_RemoveEntity()

	if result then
		if debug then dbug("debug cmd_RemoveEntity triggered") end
		return result, "cmd_RemoveEntity"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_RemovePlayerClaims()

	if result then
		if debug then dbug("debug cmd_RemovePlayerClaims triggered") end
		return result, "cmd_RemovePlayerClaims"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetHelp()

	if result then
		if debug then dbug("debug cmd_ResetHelp triggered") end
		return result, "cmd_ResetHelp"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetPlayer()

	if result then
		if debug then dbug("debug cmd_ResetPlayer triggered") end
		return result, "cmd_ResetPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetPlayerTimers()

	if result then
		if debug then dbug("debug cmd_ResetPlayerTimers triggered") end
		return result, "cmd_ResetPlayerTimers"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetStackSizes()

	if result then
		if debug then dbug("debug cmd_ResetStackSizes triggered") end
		return result, "cmd_ResetStackSizes"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_RestoreAdmin()

	if result then
		if debug then dbug("debug cmd_RestoreAdmin triggered") end
		return result, "cmd_RestoreAdmin"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReturnPlayer()

	if result then
		if debug then dbug("debug cmd_ReturnPlayer triggered") end
		return result, "cmd_ReturnPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SendPlayerHome()

	if result then
		if debug then dbug("debug cmd_SendPlayerHome triggered") end
		return result, "cmd_SendPlayerHome"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SendPlayerToPlayer()

	if result then
		if debug then dbug("debug cmd_SendPlayerToPlayer triggered") end
		return result, "cmd_SendPlayerToPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetDeathCost()

	if result then
		if debug then dbug("debug cmd_SetDeathCost triggered") end
		return result, "cmd_SetDeathCost"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetSuicideCost()

	if result then
		if debug then dbug("debug cmd_SetSuicideCost triggered") end
		return result, "cmd_SetSuicideCost"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleAllowSuicide()

	if result then
		if debug then dbug("debug cmd_ToggleAllowSuicide triggered") end
		return result, "cmd_ToggleAllowSuicide"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetDropMiningWarningThreshold()

	if result then
		if debug then dbug("debug cmd_SetDropMiningWarningThreshold triggered") end
		return result, "cmd_SetDropMiningWarningThreshold"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetCommandCooldown()

	if result then
		if debug then dbug("debug cmd_SetCommandCooldown triggered") end
		return result, "cmd_SetCommandCooldown"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetFeralHordeNight()

	if result then
		if debug then dbug("debug cmd_SetFeralHordeNight triggered") end
		return result, "cmd_SetFeralHordeNight"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetFeralRebootDelay()

	if result then
		if debug then dbug("debug cmd_SetFeralRebootDelay triggered") end
		return result, "cmd_SetFeralRebootDelay"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxAdminLevel()

	if result then
		if debug then dbug("debug cmd_SetMaxAdminLevel triggered") end
		return result, "cmd_SetMaxAdminLevel"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxTrackingDays()

	if result then
		if debug then dbug("debug cmd_SetMaxTrackingDays triggered") end
		return result, "cmd_SetMaxTrackingDays"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetReservedSlotTimelimit()

	if result then
		if debug then dbug("debug cmd_SetReservedSlotTimelimit triggered") end
		return result, "cmd_SetReservedSlotTimelimit"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetReturnCooldown()

	if result then
		if debug then dbug("debug cmd_SetReturnCooldown triggered") end
		return result, "cmd_SetReturnCooldown"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetViewArrestReason()

	if result then
		if debug then dbug("debug cmd_SetViewArrestReason triggered") end
		return result, "cmd_SetViewArrestReason"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWatchPlayerTimer()

	if result then
		if debug then dbug("debug cmd_SetWatchPlayerTimer triggered") end
		return result, "cmd_SetWatchPlayerTimer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShitPlayer()

	if result then
		if debug then dbug("debug cmd_ShitPlayer triggered") end
		return result, "cmd_ShitPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_TestAsPlayer()

	if result then
		if debug then dbug("debug cmd_TestAsPlayer triggered") end
		return result, "cmd_TestAsPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_PlayAsPlayer()

	if result then
		if debug then dbug("debug cmd_PlayAsPlayer triggered") end
		return result, "cmd_PlayAsPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_TimeoutPlayer()

	if result then
		if debug then dbug("debug cmd_TimeoutPlayer triggered") end
		return result, "cmd_TimeoutPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLevelHackAlert()

	if result then
		if debug then dbug("debug cmd_ToggleLevelHackAlert triggered") end
		return result, "cmd_ToggleLevelHackAlert"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleAirdropAlert()

	if result then
		if debug then dbug("debug cmd_ToggleAirdropAlert triggered") end
		return result, "cmd_ToggleAirdropAlert"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBounties()

	if result then
		if debug then dbug("debug cmd_ToggleBounties triggered") end
		return result, "cmd_ToggleBounties"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleFriendlyPVPResponse()

	if result then
		if debug then dbug("debug cmd_ToggleFriendlyPVPResponse triggered") end
		return result, "cmd_ToggleFriendlyPVPResponse"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBlockPlayer()

	if result then
		if debug then dbug("debug cmd_ToggleBlockPlayer triggered") end
		return result, "cmd_ToggleBlockPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleFreezeThawPlayer()

	if result then
		if debug then dbug("debug cmd_ToggleFreezeThawPlayer triggered") end
		return result, "cmd_ToggleFreezeThawPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIncludeExcludeAdmins()

	if result then
		if debug then dbug("debug cmd_ToggleIncludeExcludeAdmins triggered") end
		return result, "cmd_ToggleIncludeExcludeAdmins"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIgnorePlayer()

	if result then
		if debug then dbug("debug cmd_ToggleIgnorePlayer triggered") end
		return result, "cmd_ToggleIgnorePlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIRCNickUsedBySayCommand()

	if result then
		if debug then dbug("debug cmd_ToggleIRCNickUsedBySayCommand triggered") end
		return result, "cmd_ToggleIRCNickUsedBySayCommand"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_toggleXBox()

	if result then
		if debug then dbug("debug cmd_toggleXBox triggered") end
		return result, "cmd_toggleXBox"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_TogglePack()

	if result then
		if debug then dbug("debug cmd_TogglePack triggered") end
		return result, "cmd_TogglePack"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleRemoveExpiredClaims()

	if result then
		if debug then dbug("debug cmd_ToggleRemoveExpiredClaims triggered") end
		return result, "cmd_ToggleRemoveExpiredClaims"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleReservedSlotPlayer()

	if result then
		if debug then dbug("debug cmd_ToggleReservedSlotPlayer triggered") end
		return result, "cmd_ToggleReservedSlotPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleScreamerAlert()

	if result then
		if debug then dbug("debug cmd_ToggleScreamerAlert triggered") end
		return result, "cmd_ToggleScreamerAlert"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleTeleportPlayer()

	if result then
		if debug then dbug("debug cmd_ToggleTeleportPlayer triggered") end
		return result, "cmd_ToggleTeleportPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleWatchPlayer()

	if result then
		if debug then dbug("debug cmd_ToggleWatchPlayer triggered") end
		return result, "cmd_ToggleWatchPlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_UploadHelp()

	if result then
		if debug then dbug("debug cmd_UploadHelp triggered") end
		return result, "cmd_UploadHelp"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnlockAll()

	if result then
		if debug then dbug("debug cmd_UnlockAll triggered") end
		return result, "cmd_UnlockAll"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_VisitCrimescene()

	if result then
		if debug then dbug("debug cmd_VisitCrimescene triggered") end
		return result, "cmd_VisitCrimescene"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_VisitPlayerBase()

	if result then
		if debug then dbug("debug cmd_VisitPlayerBase triggered") end
		return result, "cmd_VisitPlayerBase"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhitelistAddRemovePlayer()

	if result then
		if debug then dbug("debug cmd_WhitelistAddRemovePlayer triggered") end
		return result, "cmd_WhitelistAddRemovePlayer"
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhitelistEveryone()

	if result then
		if debug then dbug("debug cmd_WhitelistEveryone triggered") end
		return result, "cmd_WhitelistEveryone"
	end

	if botman.registerHelp then
		if debug then dbug("Admin commands help registered") end
	end

	if debug then dbug("debug admin end") end

	-- can't touch dis
	if true then
		return result, ""
	end
end
